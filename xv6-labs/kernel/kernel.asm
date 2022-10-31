
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
    80000066:	05e78793          	addi	a5,a5,94 # 800060c0 <timervec>
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
    800000b0:	1ce78793          	addi	a5,a5,462 # 8000127a <main>
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
    80000116:	bda080e7          	jalr	-1062(ra) # 80000cec <acquire>
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
    80000130:	6ce080e7          	jalr	1742(ra) # 800027fa <either_copyin>
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
    8000015a:	c66080e7          	jalr	-922(ra) # 80000dbc <release>

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
    800001a8:	b48080e7          	jalr	-1208(ra) # 80000cec <acquire>
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
    800001d6:	b60080e7          	jalr	-1184(ra) # 80001d32 <myproc>
    800001da:	5d1c                	lw	a5,56(a0)
    800001dc:	e7b5                	bnez	a5,80000248 <consoleread+0xd2>
      sleep(&cons.r, &cons.lock);
    800001de:	85a6                	mv	a1,s1
    800001e0:	854a                	mv	a0,s2
    800001e2:	00002097          	auipc	ra,0x2
    800001e6:	368080e7          	jalr	872(ra) # 8000254a <sleep>
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
    80000222:	586080e7          	jalr	1414(ra) # 800027a4 <either_copyout>
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
    8000023e:	b82080e7          	jalr	-1150(ra) # 80000dbc <release>

  return target - n;
    80000242:	413b053b          	subw	a0,s6,s3
    80000246:	a811                	j	8000025a <consoleread+0xe4>
        release(&cons.lock);
    80000248:	00011517          	auipc	a0,0x11
    8000024c:	f2850513          	addi	a0,a0,-216 # 80011170 <cons>
    80000250:	00001097          	auipc	ra,0x1
    80000254:	b6c080e7          	jalr	-1172(ra) # 80000dbc <release>
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
    800002e4:	a0c080e7          	jalr	-1524(ra) # 80000cec <acquire>

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
    80000302:	552080e7          	jalr	1362(ra) # 80002850 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    80000306:	00011517          	auipc	a0,0x11
    8000030a:	e6a50513          	addi	a0,a0,-406 # 80011170 <cons>
    8000030e:	00001097          	auipc	ra,0x1
    80000312:	aae080e7          	jalr	-1362(ra) # 80000dbc <release>
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
    80000456:	278080e7          	jalr	632(ra) # 800026ca <wakeup>
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
    80000478:	9f4080e7          	jalr	-1548(ra) # 80000e68 <initlock>

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
    80000612:	6de080e7          	jalr	1758(ra) # 80000cec <acquire>
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
    80000770:	650080e7          	jalr	1616(ra) # 80000dbc <release>
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
    80000796:	6d6080e7          	jalr	1750(ra) # 80000e68 <initlock>
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
    800007ec:	680080e7          	jalr	1664(ra) # 80000e68 <initlock>
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
    80000808:	49c080e7          	jalr	1180(ra) # 80000ca0 <push_off>

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
    80000836:	52a080e7          	jalr	1322(ra) # 80000d5c <pop_off>
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
    800008b0:	e1e080e7          	jalr	-482(ra) # 800026ca <wakeup>
    
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
    800008f4:	3fc080e7          	jalr	1020(ra) # 80000cec <acquire>
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
    8000094a:	c04080e7          	jalr	-1020(ra) # 8000254a <sleep>
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
    80000990:	430080e7          	jalr	1072(ra) # 80000dbc <release>
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
    800009f8:	2f8080e7          	jalr	760(ra) # 80000cec <acquire>
  uartstart();
    800009fc:	00000097          	auipc	ra,0x0
    80000a00:	e48080e7          	jalr	-440(ra) # 80000844 <uartstart>
  release(&uart_tx_lock);
    80000a04:	8526                	mv	a0,s1
    80000a06:	00000097          	auipc	ra,0x0
    80000a0a:	3b6080e7          	jalr	950(ra) # 80000dbc <release>
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
    80000a4e:	682080e7          	jalr	1666(ra) # 800010cc <memset>

  r = (struct run*)pa;
  push_off();
    80000a52:	00000097          	auipc	ra,0x0
    80000a56:	24e080e7          	jalr	590(ra) # 80000ca0 <push_off>
  int id = cpuid();
    80000a5a:	00001097          	auipc	ra,0x1
    80000a5e:	2ac080e7          	jalr	684(ra) # 80001d06 <cpuid>
    80000a62:	8a2a                	mv	s4,a0
  pop_off();
    80000a64:	00000097          	auipc	ra,0x0
    80000a68:	2f8080e7          	jalr	760(ra) # 80000d5c <pop_off>
  acquire(&(kmem[id]).lock);
    80000a6c:	00011a97          	auipc	s5,0x11
    80000a70:	81ca8a93          	addi	s5,s5,-2020 # 80011288 <kmem>
    80000a74:	002a1993          	slli	s3,s4,0x2
    80000a78:	01498933          	add	s2,s3,s4
    80000a7c:	090e                	slli	s2,s2,0x3
    80000a7e:	9956                	add	s2,s2,s5
    80000a80:	854a                	mv	a0,s2
    80000a82:	00000097          	auipc	ra,0x0
    80000a86:	26a080e7          	jalr	618(ra) # 80000cec <acquire>
  r->next = kmem[id].freelist;
    80000a8a:	02093783          	ld	a5,32(s2)
    80000a8e:	e09c                	sd	a5,0(s1)
  kmem[id].freelist = r;
    80000a90:	02993023          	sd	s1,32(s2)
  release(&(kmem[id]).lock);
    80000a94:	854a                	mv	a0,s2
    80000a96:	00000097          	auipc	ra,0x0
    80000a9a:	326080e7          	jalr	806(ra) # 80000dbc <release>
  
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
    80000b3a:	332080e7          	jalr	818(ra) # 80000e68 <initlock>
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
    80000b68:	7139                	addi	sp,sp,-64
    80000b6a:	fc06                	sd	ra,56(sp)
    80000b6c:	f822                	sd	s0,48(sp)
    80000b6e:	f426                	sd	s1,40(sp)
    80000b70:	f04a                	sd	s2,32(sp)
    80000b72:	ec4e                	sd	s3,24(sp)
    80000b74:	e852                	sd	s4,16(sp)
    80000b76:	e456                	sd	s5,8(sp)
    80000b78:	e05a                	sd	s6,0(sp)
    80000b7a:	0080                	addi	s0,sp,64
  struct run *r;
  push_off();
    80000b7c:	00000097          	auipc	ra,0x0
    80000b80:	124080e7          	jalr	292(ra) # 80000ca0 <push_off>
  int id = cpuid();
    80000b84:	00001097          	auipc	ra,0x1
    80000b88:	182080e7          	jalr	386(ra) # 80001d06 <cpuid>
    80000b8c:	89aa                	mv	s3,a0
  pop_off();
    80000b8e:	00000097          	auipc	ra,0x0
    80000b92:	1ce080e7          	jalr	462(ra) # 80000d5c <pop_off>
  acquire(&(kmem[id]).lock);
    80000b96:	00299793          	slli	a5,s3,0x2
    80000b9a:	97ce                	add	a5,a5,s3
    80000b9c:	078e                	slli	a5,a5,0x3
    80000b9e:	00010497          	auipc	s1,0x10
    80000ba2:	6ea48493          	addi	s1,s1,1770 # 80011288 <kmem>
    80000ba6:	94be                	add	s1,s1,a5
    80000ba8:	8526                	mv	a0,s1
    80000baa:	00000097          	auipc	ra,0x0
    80000bae:	142080e7          	jalr	322(ra) # 80000cec <acquire>
  r = kmem[id].freelist;
    80000bb2:	0204ba83          	ld	s5,32(s1)
  if(r){
    80000bb6:	0a0a8263          	beqz	s5,80000c5a <kalloc+0xf2>
    
    kmem[id].freelist = r->next;
    80000bba:	000ab683          	ld	a3,0(s5)
    80000bbe:	f094                	sd	a3,32(s1)
    
    }
    release(&(kmem[id]).lock);
    80000bc0:	8526                	mv	a0,s1
    80000bc2:	00000097          	auipc	ra,0x0
    80000bc6:	1fa080e7          	jalr	506(ra) # 80000dbc <release>
      release(&(kmem[idx]).lock);
    }
  
  
  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000bca:	6605                	lui	a2,0x1
    80000bcc:	4595                	li	a1,5
    80000bce:	8556                	mv	a0,s5
    80000bd0:	00000097          	auipc	ra,0x0
    80000bd4:	4fc080e7          	jalr	1276(ra) # 800010cc <memset>
  
  return (void*)r;
    80000bd8:	8556                	mv	a0,s5
    80000bda:	70e2                	ld	ra,56(sp)
    80000bdc:	7442                	ld	s0,48(sp)
    80000bde:	74a2                	ld	s1,40(sp)
    80000be0:	7902                	ld	s2,32(sp)
    80000be2:	69e2                	ld	s3,24(sp)
    80000be4:	6a42                	ld	s4,16(sp)
    80000be6:	6aa2                	ld	s5,8(sp)
    80000be8:	6b02                	ld	s6,0(sp)
    80000bea:	6121                	addi	sp,sp,64
    80000bec:	8082                	ret
      release(&(kmem[idx]).lock);
    80000bee:	854a                	mv	a0,s2
    80000bf0:	00000097          	auipc	ra,0x0
    80000bf4:	1cc080e7          	jalr	460(ra) # 80000dbc <release>
    for(int idx=id+1;idx!=id;idx=(idx+1)%NCPU){
    80000bf8:	2485                	addiw	s1,s1,1
    80000bfa:	41f4d79b          	sraiw	a5,s1,0x1f
    80000bfe:	01d7d79b          	srliw	a5,a5,0x1d
    80000c02:	9cbd                	addw	s1,s1,a5
    80000c04:	889d                	andi	s1,s1,7
    80000c06:	9c9d                	subw	s1,s1,a5
    80000c08:	fc9988e3          	beq	s3,s1,80000bd8 <kalloc+0x70>
      if(holding(&(kmem[idx]).lock)) continue;// if the lock was hold by other cpu, skip
    80000c0c:	00249913          	slli	s2,s1,0x2
    80000c10:	9926                	add	s2,s2,s1
    80000c12:	090e                	slli	s2,s2,0x3
    80000c14:	9952                	add	s2,s2,s4
    80000c16:	854a                	mv	a0,s2
    80000c18:	00000097          	auipc	ra,0x0
    80000c1c:	05a080e7          	jalr	90(ra) # 80000c72 <holding>
    80000c20:	fd61                	bnez	a0,80000bf8 <kalloc+0x90>
      acquire(&(kmem[idx]).lock);
    80000c22:	854a                	mv	a0,s2
    80000c24:	00000097          	auipc	ra,0x0
    80000c28:	0c8080e7          	jalr	200(ra) # 80000cec <acquire>
      if(kmem[idx].freelist){
    80000c2c:	02093b03          	ld	s6,32(s2)
    80000c30:	fa0b0fe3          	beqz	s6,80000bee <kalloc+0x86>
        kmem[idx].freelist=r->next;
    80000c34:	000b3683          	ld	a3,0(s6)
    80000c38:	00249793          	slli	a5,s1,0x2
    80000c3c:	97a6                	add	a5,a5,s1
    80000c3e:	078e                	slli	a5,a5,0x3
    80000c40:	00010717          	auipc	a4,0x10
    80000c44:	64870713          	addi	a4,a4,1608 # 80011288 <kmem>
    80000c48:	97ba                	add	a5,a5,a4
    80000c4a:	f394                	sd	a3,32(a5)
        release(&(kmem[idx]).lock);
    80000c4c:	854a                	mv	a0,s2
    80000c4e:	00000097          	auipc	ra,0x0
    80000c52:	16e080e7          	jalr	366(ra) # 80000dbc <release>
      if(kmem[idx].freelist){
    80000c56:	8ada                	mv	s5,s6
        break;
    80000c58:	bf8d                	j	80000bca <kalloc+0x62>
    release(&(kmem[id]).lock);
    80000c5a:	8526                	mv	a0,s1
    80000c5c:	00000097          	auipc	ra,0x0
    80000c60:	160080e7          	jalr	352(ra) # 80000dbc <release>
    for(int idx=id+1;idx!=id;idx=(idx+1)%NCPU){
    80000c64:	0019849b          	addiw	s1,s3,1
      if(holding(&(kmem[idx]).lock)) continue;// if the lock was hold by other cpu, skip
    80000c68:	00010a17          	auipc	s4,0x10
    80000c6c:	620a0a13          	addi	s4,s4,1568 # 80011288 <kmem>
    80000c70:	bf71                	j	80000c0c <kalloc+0xa4>

0000000080000c72 <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000c72:	411c                	lw	a5,0(a0)
    80000c74:	e399                	bnez	a5,80000c7a <holding+0x8>
    80000c76:	4501                	li	a0,0
  return r;
}
    80000c78:	8082                	ret
{
    80000c7a:	1101                	addi	sp,sp,-32
    80000c7c:	ec06                	sd	ra,24(sp)
    80000c7e:	e822                	sd	s0,16(sp)
    80000c80:	e426                	sd	s1,8(sp)
    80000c82:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000c84:	6904                	ld	s1,16(a0)
    80000c86:	00001097          	auipc	ra,0x1
    80000c8a:	090080e7          	jalr	144(ra) # 80001d16 <mycpu>
    80000c8e:	40a48533          	sub	a0,s1,a0
    80000c92:	00153513          	seqz	a0,a0
}
    80000c96:	60e2                	ld	ra,24(sp)
    80000c98:	6442                	ld	s0,16(sp)
    80000c9a:	64a2                	ld	s1,8(sp)
    80000c9c:	6105                	addi	sp,sp,32
    80000c9e:	8082                	ret

0000000080000ca0 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000ca0:	1101                	addi	sp,sp,-32
    80000ca2:	ec06                	sd	ra,24(sp)
    80000ca4:	e822                	sd	s0,16(sp)
    80000ca6:	e426                	sd	s1,8(sp)
    80000ca8:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000caa:	100024f3          	csrr	s1,sstatus
    80000cae:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000cb2:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000cb4:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000cb8:	00001097          	auipc	ra,0x1
    80000cbc:	05e080e7          	jalr	94(ra) # 80001d16 <mycpu>
    80000cc0:	5d3c                	lw	a5,120(a0)
    80000cc2:	cf89                	beqz	a5,80000cdc <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000cc4:	00001097          	auipc	ra,0x1
    80000cc8:	052080e7          	jalr	82(ra) # 80001d16 <mycpu>
    80000ccc:	5d3c                	lw	a5,120(a0)
    80000cce:	2785                	addiw	a5,a5,1
    80000cd0:	dd3c                	sw	a5,120(a0)
}
    80000cd2:	60e2                	ld	ra,24(sp)
    80000cd4:	6442                	ld	s0,16(sp)
    80000cd6:	64a2                	ld	s1,8(sp)
    80000cd8:	6105                	addi	sp,sp,32
    80000cda:	8082                	ret
    mycpu()->intena = old;
    80000cdc:	00001097          	auipc	ra,0x1
    80000ce0:	03a080e7          	jalr	58(ra) # 80001d16 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000ce4:	8085                	srli	s1,s1,0x1
    80000ce6:	8885                	andi	s1,s1,1
    80000ce8:	dd64                	sw	s1,124(a0)
    80000cea:	bfe9                	j	80000cc4 <push_off+0x24>

0000000080000cec <acquire>:
{
    80000cec:	1101                	addi	sp,sp,-32
    80000cee:	ec06                	sd	ra,24(sp)
    80000cf0:	e822                	sd	s0,16(sp)
    80000cf2:	e426                	sd	s1,8(sp)
    80000cf4:	1000                	addi	s0,sp,32
    80000cf6:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000cf8:	00000097          	auipc	ra,0x0
    80000cfc:	fa8080e7          	jalr	-88(ra) # 80000ca0 <push_off>
  if(holding(lk))
    80000d00:	8526                	mv	a0,s1
    80000d02:	00000097          	auipc	ra,0x0
    80000d06:	f70080e7          	jalr	-144(ra) # 80000c72 <holding>
    80000d0a:	e911                	bnez	a0,80000d1e <acquire+0x32>
    __sync_fetch_and_add(&(lk->n), 1);
    80000d0c:	4785                	li	a5,1
    80000d0e:	01c48713          	addi	a4,s1,28
    80000d12:	0f50000f          	fence	iorw,ow
    80000d16:	04f7202f          	amoadd.w.aq	zero,a5,(a4)
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0) {
    80000d1a:	4705                	li	a4,1
    80000d1c:	a839                	j	80000d3a <acquire+0x4e>
    panic("acquire");
    80000d1e:	00007517          	auipc	a0,0x7
    80000d22:	35250513          	addi	a0,a0,850 # 80008070 <digits+0x30>
    80000d26:	00000097          	auipc	ra,0x0
    80000d2a:	826080e7          	jalr	-2010(ra) # 8000054c <panic>
    __sync_fetch_and_add(&(lk->nts), 1);
    80000d2e:	01848793          	addi	a5,s1,24
    80000d32:	0f50000f          	fence	iorw,ow
    80000d36:	04e7a02f          	amoadd.w.aq	zero,a4,(a5)
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0) {
    80000d3a:	87ba                	mv	a5,a4
    80000d3c:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000d40:	2781                	sext.w	a5,a5
    80000d42:	f7f5                	bnez	a5,80000d2e <acquire+0x42>
  __sync_synchronize();
    80000d44:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000d48:	00001097          	auipc	ra,0x1
    80000d4c:	fce080e7          	jalr	-50(ra) # 80001d16 <mycpu>
    80000d50:	e888                	sd	a0,16(s1)
}
    80000d52:	60e2                	ld	ra,24(sp)
    80000d54:	6442                	ld	s0,16(sp)
    80000d56:	64a2                	ld	s1,8(sp)
    80000d58:	6105                	addi	sp,sp,32
    80000d5a:	8082                	ret

0000000080000d5c <pop_off>:

void
pop_off(void)
{
    80000d5c:	1141                	addi	sp,sp,-16
    80000d5e:	e406                	sd	ra,8(sp)
    80000d60:	e022                	sd	s0,0(sp)
    80000d62:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000d64:	00001097          	auipc	ra,0x1
    80000d68:	fb2080e7          	jalr	-78(ra) # 80001d16 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000d6c:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000d70:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000d72:	e78d                	bnez	a5,80000d9c <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000d74:	5d3c                	lw	a5,120(a0)
    80000d76:	02f05b63          	blez	a5,80000dac <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000d7a:	37fd                	addiw	a5,a5,-1
    80000d7c:	0007871b          	sext.w	a4,a5
    80000d80:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000d82:	eb09                	bnez	a4,80000d94 <pop_off+0x38>
    80000d84:	5d7c                	lw	a5,124(a0)
    80000d86:	c799                	beqz	a5,80000d94 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000d88:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000d8c:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000d90:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000d94:	60a2                	ld	ra,8(sp)
    80000d96:	6402                	ld	s0,0(sp)
    80000d98:	0141                	addi	sp,sp,16
    80000d9a:	8082                	ret
    panic("pop_off - interruptible");
    80000d9c:	00007517          	auipc	a0,0x7
    80000da0:	2dc50513          	addi	a0,a0,732 # 80008078 <digits+0x38>
    80000da4:	fffff097          	auipc	ra,0xfffff
    80000da8:	7a8080e7          	jalr	1960(ra) # 8000054c <panic>
    panic("pop_off");
    80000dac:	00007517          	auipc	a0,0x7
    80000db0:	2e450513          	addi	a0,a0,740 # 80008090 <digits+0x50>
    80000db4:	fffff097          	auipc	ra,0xfffff
    80000db8:	798080e7          	jalr	1944(ra) # 8000054c <panic>

0000000080000dbc <release>:
{
    80000dbc:	1101                	addi	sp,sp,-32
    80000dbe:	ec06                	sd	ra,24(sp)
    80000dc0:	e822                	sd	s0,16(sp)
    80000dc2:	e426                	sd	s1,8(sp)
    80000dc4:	1000                	addi	s0,sp,32
    80000dc6:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000dc8:	00000097          	auipc	ra,0x0
    80000dcc:	eaa080e7          	jalr	-342(ra) # 80000c72 <holding>
    80000dd0:	c115                	beqz	a0,80000df4 <release+0x38>
  lk->cpu = 0;
    80000dd2:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000dd6:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000dda:	0f50000f          	fence	iorw,ow
    80000dde:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000de2:	00000097          	auipc	ra,0x0
    80000de6:	f7a080e7          	jalr	-134(ra) # 80000d5c <pop_off>
}
    80000dea:	60e2                	ld	ra,24(sp)
    80000dec:	6442                	ld	s0,16(sp)
    80000dee:	64a2                	ld	s1,8(sp)
    80000df0:	6105                	addi	sp,sp,32
    80000df2:	8082                	ret
    panic("release");
    80000df4:	00007517          	auipc	a0,0x7
    80000df8:	2a450513          	addi	a0,a0,676 # 80008098 <digits+0x58>
    80000dfc:	fffff097          	auipc	ra,0xfffff
    80000e00:	750080e7          	jalr	1872(ra) # 8000054c <panic>

0000000080000e04 <freelock>:
{
    80000e04:	1101                	addi	sp,sp,-32
    80000e06:	ec06                	sd	ra,24(sp)
    80000e08:	e822                	sd	s0,16(sp)
    80000e0a:	e426                	sd	s1,8(sp)
    80000e0c:	1000                	addi	s0,sp,32
    80000e0e:	84aa                	mv	s1,a0
  acquire(&lock_locks);
    80000e10:	00010517          	auipc	a0,0x10
    80000e14:	5b850513          	addi	a0,a0,1464 # 800113c8 <lock_locks>
    80000e18:	00000097          	auipc	ra,0x0
    80000e1c:	ed4080e7          	jalr	-300(ra) # 80000cec <acquire>
  for (i = 0; i < NLOCK; i++) {
    80000e20:	00010717          	auipc	a4,0x10
    80000e24:	5c870713          	addi	a4,a4,1480 # 800113e8 <locks>
    80000e28:	4781                	li	a5,0
    80000e2a:	1f400613          	li	a2,500
    if(locks[i] == lk) {
    80000e2e:	6314                	ld	a3,0(a4)
    80000e30:	00968763          	beq	a3,s1,80000e3e <freelock+0x3a>
  for (i = 0; i < NLOCK; i++) {
    80000e34:	2785                	addiw	a5,a5,1
    80000e36:	0721                	addi	a4,a4,8
    80000e38:	fec79be3          	bne	a5,a2,80000e2e <freelock+0x2a>
    80000e3c:	a809                	j	80000e4e <freelock+0x4a>
      locks[i] = 0;
    80000e3e:	078e                	slli	a5,a5,0x3
    80000e40:	00010717          	auipc	a4,0x10
    80000e44:	5a870713          	addi	a4,a4,1448 # 800113e8 <locks>
    80000e48:	97ba                	add	a5,a5,a4
    80000e4a:	0007b023          	sd	zero,0(a5)
  release(&lock_locks);
    80000e4e:	00010517          	auipc	a0,0x10
    80000e52:	57a50513          	addi	a0,a0,1402 # 800113c8 <lock_locks>
    80000e56:	00000097          	auipc	ra,0x0
    80000e5a:	f66080e7          	jalr	-154(ra) # 80000dbc <release>
}
    80000e5e:	60e2                	ld	ra,24(sp)
    80000e60:	6442                	ld	s0,16(sp)
    80000e62:	64a2                	ld	s1,8(sp)
    80000e64:	6105                	addi	sp,sp,32
    80000e66:	8082                	ret

0000000080000e68 <initlock>:
{
    80000e68:	1101                	addi	sp,sp,-32
    80000e6a:	ec06                	sd	ra,24(sp)
    80000e6c:	e822                	sd	s0,16(sp)
    80000e6e:	e426                	sd	s1,8(sp)
    80000e70:	1000                	addi	s0,sp,32
    80000e72:	84aa                	mv	s1,a0
  lk->name = name;
    80000e74:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000e76:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000e7a:	00053823          	sd	zero,16(a0)
  lk->nts = 0;
    80000e7e:	00052c23          	sw	zero,24(a0)
  lk->n = 0;
    80000e82:	00052e23          	sw	zero,28(a0)
  acquire(&lock_locks);
    80000e86:	00010517          	auipc	a0,0x10
    80000e8a:	54250513          	addi	a0,a0,1346 # 800113c8 <lock_locks>
    80000e8e:	00000097          	auipc	ra,0x0
    80000e92:	e5e080e7          	jalr	-418(ra) # 80000cec <acquire>
  for (i = 0; i < NLOCK; i++) {
    80000e96:	00010717          	auipc	a4,0x10
    80000e9a:	55270713          	addi	a4,a4,1362 # 800113e8 <locks>
    80000e9e:	4781                	li	a5,0
    80000ea0:	1f400613          	li	a2,500
    if(locks[i] == 0) {
    80000ea4:	6314                	ld	a3,0(a4)
    80000ea6:	ce89                	beqz	a3,80000ec0 <initlock+0x58>
  for (i = 0; i < NLOCK; i++) {
    80000ea8:	2785                	addiw	a5,a5,1
    80000eaa:	0721                	addi	a4,a4,8
    80000eac:	fec79ce3          	bne	a5,a2,80000ea4 <initlock+0x3c>
  panic("findslot");
    80000eb0:	00007517          	auipc	a0,0x7
    80000eb4:	1f050513          	addi	a0,a0,496 # 800080a0 <digits+0x60>
    80000eb8:	fffff097          	auipc	ra,0xfffff
    80000ebc:	694080e7          	jalr	1684(ra) # 8000054c <panic>
      locks[i] = lk;
    80000ec0:	078e                	slli	a5,a5,0x3
    80000ec2:	00010717          	auipc	a4,0x10
    80000ec6:	52670713          	addi	a4,a4,1318 # 800113e8 <locks>
    80000eca:	97ba                	add	a5,a5,a4
    80000ecc:	e384                	sd	s1,0(a5)
      release(&lock_locks);
    80000ece:	00010517          	auipc	a0,0x10
    80000ed2:	4fa50513          	addi	a0,a0,1274 # 800113c8 <lock_locks>
    80000ed6:	00000097          	auipc	ra,0x0
    80000eda:	ee6080e7          	jalr	-282(ra) # 80000dbc <release>
}
    80000ede:	60e2                	ld	ra,24(sp)
    80000ee0:	6442                	ld	s0,16(sp)
    80000ee2:	64a2                	ld	s1,8(sp)
    80000ee4:	6105                	addi	sp,sp,32
    80000ee6:	8082                	ret

0000000080000ee8 <snprint_lock>:
#ifdef LAB_LOCK
int
snprint_lock(char *buf, int sz, struct spinlock *lk)
{
  int n = 0;
  if(lk->n > 0) {
    80000ee8:	4e5c                	lw	a5,28(a2)
    80000eea:	00f04463          	bgtz	a5,80000ef2 <snprint_lock+0xa>
  int n = 0;
    80000eee:	4501                	li	a0,0
    n = snprintf(buf, sz, "lock: %s: #fetch-and-add %d #acquire() %d\n",
                 lk->name, lk->nts, lk->n);
  }
  return n;
}
    80000ef0:	8082                	ret
{
    80000ef2:	1141                	addi	sp,sp,-16
    80000ef4:	e406                	sd	ra,8(sp)
    80000ef6:	e022                	sd	s0,0(sp)
    80000ef8:	0800                	addi	s0,sp,16
    n = snprintf(buf, sz, "lock: %s: #fetch-and-add %d #acquire() %d\n",
    80000efa:	4e18                	lw	a4,24(a2)
    80000efc:	6614                	ld	a3,8(a2)
    80000efe:	00007617          	auipc	a2,0x7
    80000f02:	1b260613          	addi	a2,a2,434 # 800080b0 <digits+0x70>
    80000f06:	00006097          	auipc	ra,0x6
    80000f0a:	96a080e7          	jalr	-1686(ra) # 80006870 <snprintf>
}
    80000f0e:	60a2                	ld	ra,8(sp)
    80000f10:	6402                	ld	s0,0(sp)
    80000f12:	0141                	addi	sp,sp,16
    80000f14:	8082                	ret

0000000080000f16 <statslock>:

int
statslock(char *buf, int sz) {
    80000f16:	7159                	addi	sp,sp,-112
    80000f18:	f486                	sd	ra,104(sp)
    80000f1a:	f0a2                	sd	s0,96(sp)
    80000f1c:	eca6                	sd	s1,88(sp)
    80000f1e:	e8ca                	sd	s2,80(sp)
    80000f20:	e4ce                	sd	s3,72(sp)
    80000f22:	e0d2                	sd	s4,64(sp)
    80000f24:	fc56                	sd	s5,56(sp)
    80000f26:	f85a                	sd	s6,48(sp)
    80000f28:	f45e                	sd	s7,40(sp)
    80000f2a:	f062                	sd	s8,32(sp)
    80000f2c:	ec66                	sd	s9,24(sp)
    80000f2e:	e86a                	sd	s10,16(sp)
    80000f30:	e46e                	sd	s11,8(sp)
    80000f32:	1880                	addi	s0,sp,112
    80000f34:	8aaa                	mv	s5,a0
    80000f36:	8b2e                	mv	s6,a1
  int n;
  int tot = 0;

  acquire(&lock_locks);
    80000f38:	00010517          	auipc	a0,0x10
    80000f3c:	49050513          	addi	a0,a0,1168 # 800113c8 <lock_locks>
    80000f40:	00000097          	auipc	ra,0x0
    80000f44:	dac080e7          	jalr	-596(ra) # 80000cec <acquire>
  n = snprintf(buf, sz, "--- lock kmem/bcache stats\n");
    80000f48:	00007617          	auipc	a2,0x7
    80000f4c:	19860613          	addi	a2,a2,408 # 800080e0 <digits+0xa0>
    80000f50:	85da                	mv	a1,s6
    80000f52:	8556                	mv	a0,s5
    80000f54:	00006097          	auipc	ra,0x6
    80000f58:	91c080e7          	jalr	-1764(ra) # 80006870 <snprintf>
    80000f5c:	892a                	mv	s2,a0
  for(int i = 0; i < NLOCK; i++) {
    80000f5e:	00010c97          	auipc	s9,0x10
    80000f62:	48ac8c93          	addi	s9,s9,1162 # 800113e8 <locks>
    80000f66:	00011c17          	auipc	s8,0x11
    80000f6a:	422c0c13          	addi	s8,s8,1058 # 80012388 <pid_lock>
  n = snprintf(buf, sz, "--- lock kmem/bcache stats\n");
    80000f6e:	84e6                	mv	s1,s9
  int tot = 0;
    80000f70:	4a01                	li	s4,0
    if(locks[i] == 0)
      break;
    if(strncmp(locks[i]->name, "bcache", strlen("bcache")) == 0 ||
    80000f72:	00007b97          	auipc	s7,0x7
    80000f76:	18eb8b93          	addi	s7,s7,398 # 80008100 <digits+0xc0>
       strncmp(locks[i]->name, "kmem", strlen("kmem")) == 0) {
    80000f7a:	00007d17          	auipc	s10,0x7
    80000f7e:	0eed0d13          	addi	s10,s10,238 # 80008068 <digits+0x28>
    80000f82:	a01d                	j	80000fa8 <statslock+0x92>
      tot += locks[i]->nts;
    80000f84:	0009b603          	ld	a2,0(s3)
    80000f88:	4e1c                	lw	a5,24(a2)
    80000f8a:	01478a3b          	addw	s4,a5,s4
      n += snprint_lock(buf +n, sz-n, locks[i]);
    80000f8e:	412b05bb          	subw	a1,s6,s2
    80000f92:	012a8533          	add	a0,s5,s2
    80000f96:	00000097          	auipc	ra,0x0
    80000f9a:	f52080e7          	jalr	-174(ra) # 80000ee8 <snprint_lock>
    80000f9e:	0125093b          	addw	s2,a0,s2
  for(int i = 0; i < NLOCK; i++) {
    80000fa2:	04a1                	addi	s1,s1,8
    80000fa4:	05848763          	beq	s1,s8,80000ff2 <statslock+0xdc>
    if(locks[i] == 0)
    80000fa8:	89a6                	mv	s3,s1
    80000faa:	609c                	ld	a5,0(s1)
    80000fac:	c3b9                	beqz	a5,80000ff2 <statslock+0xdc>
    if(strncmp(locks[i]->name, "bcache", strlen("bcache")) == 0 ||
    80000fae:	0087bd83          	ld	s11,8(a5)
    80000fb2:	855e                	mv	a0,s7
    80000fb4:	00000097          	auipc	ra,0x0
    80000fb8:	29c080e7          	jalr	668(ra) # 80001250 <strlen>
    80000fbc:	0005061b          	sext.w	a2,a0
    80000fc0:	85de                	mv	a1,s7
    80000fc2:	856e                	mv	a0,s11
    80000fc4:	00000097          	auipc	ra,0x0
    80000fc8:	1e0080e7          	jalr	480(ra) # 800011a4 <strncmp>
    80000fcc:	dd45                	beqz	a0,80000f84 <statslock+0x6e>
       strncmp(locks[i]->name, "kmem", strlen("kmem")) == 0) {
    80000fce:	609c                	ld	a5,0(s1)
    80000fd0:	0087bd83          	ld	s11,8(a5)
    80000fd4:	856a                	mv	a0,s10
    80000fd6:	00000097          	auipc	ra,0x0
    80000fda:	27a080e7          	jalr	634(ra) # 80001250 <strlen>
    80000fde:	0005061b          	sext.w	a2,a0
    80000fe2:	85ea                	mv	a1,s10
    80000fe4:	856e                	mv	a0,s11
    80000fe6:	00000097          	auipc	ra,0x0
    80000fea:	1be080e7          	jalr	446(ra) # 800011a4 <strncmp>
    if(strncmp(locks[i]->name, "bcache", strlen("bcache")) == 0 ||
    80000fee:	f955                	bnez	a0,80000fa2 <statslock+0x8c>
    80000ff0:	bf51                	j	80000f84 <statslock+0x6e>
    }
  }
  
  n += snprintf(buf+n, sz-n, "--- top 5 contended locks:\n");
    80000ff2:	00007617          	auipc	a2,0x7
    80000ff6:	11660613          	addi	a2,a2,278 # 80008108 <digits+0xc8>
    80000ffa:	412b05bb          	subw	a1,s6,s2
    80000ffe:	012a8533          	add	a0,s5,s2
    80001002:	00006097          	auipc	ra,0x6
    80001006:	86e080e7          	jalr	-1938(ra) # 80006870 <snprintf>
    8000100a:	012509bb          	addw	s3,a0,s2
    8000100e:	4b95                	li	s7,5
  int last = 100000000;
    80001010:	05f5e537          	lui	a0,0x5f5e
    80001014:	10050513          	addi	a0,a0,256 # 5f5e100 <_entry-0x7a0a1f00>
  // stupid way to compute top 5 contended locks
  for(int t = 0; t < 5; t++) {
    int top = 0;
    for(int i = 0; i < NLOCK; i++) {
    80001018:	4c01                	li	s8,0
      if(locks[i] == 0)
        break;
      if(locks[i]->nts > locks[top]->nts && locks[i]->nts < last) {
    8000101a:	00010497          	auipc	s1,0x10
    8000101e:	3ce48493          	addi	s1,s1,974 # 800113e8 <locks>
    for(int i = 0; i < NLOCK; i++) {
    80001022:	1f400913          	li	s2,500
    80001026:	a881                	j	80001076 <statslock+0x160>
    80001028:	2705                	addiw	a4,a4,1
    8000102a:	06a1                	addi	a3,a3,8
    8000102c:	03270063          	beq	a4,s2,8000104c <statslock+0x136>
      if(locks[i] == 0)
    80001030:	629c                	ld	a5,0(a3)
    80001032:	cf89                	beqz	a5,8000104c <statslock+0x136>
      if(locks[i]->nts > locks[top]->nts && locks[i]->nts < last) {
    80001034:	4f90                	lw	a2,24(a5)
    80001036:	00359793          	slli	a5,a1,0x3
    8000103a:	97a6                	add	a5,a5,s1
    8000103c:	639c                	ld	a5,0(a5)
    8000103e:	4f9c                	lw	a5,24(a5)
    80001040:	fec7d4e3          	bge	a5,a2,80001028 <statslock+0x112>
    80001044:	fea652e3          	bge	a2,a0,80001028 <statslock+0x112>
    80001048:	85ba                	mv	a1,a4
    8000104a:	bff9                	j	80001028 <statslock+0x112>
        top = i;
      }
    }
    n += snprint_lock(buf+n, sz-n, locks[top]);
    8000104c:	058e                	slli	a1,a1,0x3
    8000104e:	00b48d33          	add	s10,s1,a1
    80001052:	000d3603          	ld	a2,0(s10)
    80001056:	413b05bb          	subw	a1,s6,s3
    8000105a:	013a8533          	add	a0,s5,s3
    8000105e:	00000097          	auipc	ra,0x0
    80001062:	e8a080e7          	jalr	-374(ra) # 80000ee8 <snprint_lock>
    80001066:	013509bb          	addw	s3,a0,s3
    last = locks[top]->nts;
    8000106a:	000d3783          	ld	a5,0(s10)
    8000106e:	4f88                	lw	a0,24(a5)
  for(int t = 0; t < 5; t++) {
    80001070:	3bfd                	addiw	s7,s7,-1
    80001072:	000b8663          	beqz	s7,8000107e <statslock+0x168>
  int tot = 0;
    80001076:	86e6                	mv	a3,s9
    for(int i = 0; i < NLOCK; i++) {
    80001078:	8762                	mv	a4,s8
    int top = 0;
    8000107a:	85e2                	mv	a1,s8
    8000107c:	bf55                	j	80001030 <statslock+0x11a>
  }
  n += snprintf(buf+n, sz-n, "tot= %d\n", tot);
    8000107e:	86d2                	mv	a3,s4
    80001080:	00007617          	auipc	a2,0x7
    80001084:	0a860613          	addi	a2,a2,168 # 80008128 <digits+0xe8>
    80001088:	413b05bb          	subw	a1,s6,s3
    8000108c:	013a8533          	add	a0,s5,s3
    80001090:	00005097          	auipc	ra,0x5
    80001094:	7e0080e7          	jalr	2016(ra) # 80006870 <snprintf>
    80001098:	013509bb          	addw	s3,a0,s3
  release(&lock_locks);  
    8000109c:	00010517          	auipc	a0,0x10
    800010a0:	32c50513          	addi	a0,a0,812 # 800113c8 <lock_locks>
    800010a4:	00000097          	auipc	ra,0x0
    800010a8:	d18080e7          	jalr	-744(ra) # 80000dbc <release>
  return n;
}
    800010ac:	854e                	mv	a0,s3
    800010ae:	70a6                	ld	ra,104(sp)
    800010b0:	7406                	ld	s0,96(sp)
    800010b2:	64e6                	ld	s1,88(sp)
    800010b4:	6946                	ld	s2,80(sp)
    800010b6:	69a6                	ld	s3,72(sp)
    800010b8:	6a06                	ld	s4,64(sp)
    800010ba:	7ae2                	ld	s5,56(sp)
    800010bc:	7b42                	ld	s6,48(sp)
    800010be:	7ba2                	ld	s7,40(sp)
    800010c0:	7c02                	ld	s8,32(sp)
    800010c2:	6ce2                	ld	s9,24(sp)
    800010c4:	6d42                	ld	s10,16(sp)
    800010c6:	6da2                	ld	s11,8(sp)
    800010c8:	6165                	addi	sp,sp,112
    800010ca:	8082                	ret

00000000800010cc <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    800010cc:	1141                	addi	sp,sp,-16
    800010ce:	e422                	sd	s0,8(sp)
    800010d0:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    800010d2:	ca19                	beqz	a2,800010e8 <memset+0x1c>
    800010d4:	87aa                	mv	a5,a0
    800010d6:	1602                	slli	a2,a2,0x20
    800010d8:	9201                	srli	a2,a2,0x20
    800010da:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    800010de:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    800010e2:	0785                	addi	a5,a5,1
    800010e4:	fee79de3          	bne	a5,a4,800010de <memset+0x12>
  }
  return dst;
}
    800010e8:	6422                	ld	s0,8(sp)
    800010ea:	0141                	addi	sp,sp,16
    800010ec:	8082                	ret

00000000800010ee <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    800010ee:	1141                	addi	sp,sp,-16
    800010f0:	e422                	sd	s0,8(sp)
    800010f2:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    800010f4:	ca05                	beqz	a2,80001124 <memcmp+0x36>
    800010f6:	fff6069b          	addiw	a3,a2,-1
    800010fa:	1682                	slli	a3,a3,0x20
    800010fc:	9281                	srli	a3,a3,0x20
    800010fe:	0685                	addi	a3,a3,1
    80001100:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80001102:	00054783          	lbu	a5,0(a0)
    80001106:	0005c703          	lbu	a4,0(a1)
    8000110a:	00e79863          	bne	a5,a4,8000111a <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    8000110e:	0505                	addi	a0,a0,1
    80001110:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80001112:	fed518e3          	bne	a0,a3,80001102 <memcmp+0x14>
  }

  return 0;
    80001116:	4501                	li	a0,0
    80001118:	a019                	j	8000111e <memcmp+0x30>
      return *s1 - *s2;
    8000111a:	40e7853b          	subw	a0,a5,a4
}
    8000111e:	6422                	ld	s0,8(sp)
    80001120:	0141                	addi	sp,sp,16
    80001122:	8082                	ret
  return 0;
    80001124:	4501                	li	a0,0
    80001126:	bfe5                	j	8000111e <memcmp+0x30>

0000000080001128 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80001128:	1141                	addi	sp,sp,-16
    8000112a:	e422                	sd	s0,8(sp)
    8000112c:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
    8000112e:	02a5e563          	bltu	a1,a0,80001158 <memmove+0x30>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80001132:	fff6069b          	addiw	a3,a2,-1
    80001136:	ce11                	beqz	a2,80001152 <memmove+0x2a>
    80001138:	1682                	slli	a3,a3,0x20
    8000113a:	9281                	srli	a3,a3,0x20
    8000113c:	0685                	addi	a3,a3,1
    8000113e:	96ae                	add	a3,a3,a1
    80001140:	87aa                	mv	a5,a0
      *d++ = *s++;
    80001142:	0585                	addi	a1,a1,1
    80001144:	0785                	addi	a5,a5,1
    80001146:	fff5c703          	lbu	a4,-1(a1)
    8000114a:	fee78fa3          	sb	a4,-1(a5)
    while(n-- > 0)
    8000114e:	fed59ae3          	bne	a1,a3,80001142 <memmove+0x1a>

  return dst;
}
    80001152:	6422                	ld	s0,8(sp)
    80001154:	0141                	addi	sp,sp,16
    80001156:	8082                	ret
  if(s < d && s + n > d){
    80001158:	02061713          	slli	a4,a2,0x20
    8000115c:	9301                	srli	a4,a4,0x20
    8000115e:	00e587b3          	add	a5,a1,a4
    80001162:	fcf578e3          	bgeu	a0,a5,80001132 <memmove+0xa>
    d += n;
    80001166:	972a                	add	a4,a4,a0
    while(n-- > 0)
    80001168:	fff6069b          	addiw	a3,a2,-1
    8000116c:	d27d                	beqz	a2,80001152 <memmove+0x2a>
    8000116e:	02069613          	slli	a2,a3,0x20
    80001172:	9201                	srli	a2,a2,0x20
    80001174:	fff64613          	not	a2,a2
    80001178:	963e                	add	a2,a2,a5
      *--d = *--s;
    8000117a:	17fd                	addi	a5,a5,-1
    8000117c:	177d                	addi	a4,a4,-1
    8000117e:	0007c683          	lbu	a3,0(a5)
    80001182:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
    80001186:	fef61ae3          	bne	a2,a5,8000117a <memmove+0x52>
    8000118a:	b7e1                	j	80001152 <memmove+0x2a>

000000008000118c <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    8000118c:	1141                	addi	sp,sp,-16
    8000118e:	e406                	sd	ra,8(sp)
    80001190:	e022                	sd	s0,0(sp)
    80001192:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80001194:	00000097          	auipc	ra,0x0
    80001198:	f94080e7          	jalr	-108(ra) # 80001128 <memmove>
}
    8000119c:	60a2                	ld	ra,8(sp)
    8000119e:	6402                	ld	s0,0(sp)
    800011a0:	0141                	addi	sp,sp,16
    800011a2:	8082                	ret

00000000800011a4 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    800011a4:	1141                	addi	sp,sp,-16
    800011a6:	e422                	sd	s0,8(sp)
    800011a8:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    800011aa:	ce11                	beqz	a2,800011c6 <strncmp+0x22>
    800011ac:	00054783          	lbu	a5,0(a0)
    800011b0:	cf89                	beqz	a5,800011ca <strncmp+0x26>
    800011b2:	0005c703          	lbu	a4,0(a1)
    800011b6:	00f71a63          	bne	a4,a5,800011ca <strncmp+0x26>
    n--, p++, q++;
    800011ba:	367d                	addiw	a2,a2,-1
    800011bc:	0505                	addi	a0,a0,1
    800011be:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    800011c0:	f675                	bnez	a2,800011ac <strncmp+0x8>
  if(n == 0)
    return 0;
    800011c2:	4501                	li	a0,0
    800011c4:	a809                	j	800011d6 <strncmp+0x32>
    800011c6:	4501                	li	a0,0
    800011c8:	a039                	j	800011d6 <strncmp+0x32>
  if(n == 0)
    800011ca:	ca09                	beqz	a2,800011dc <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    800011cc:	00054503          	lbu	a0,0(a0)
    800011d0:	0005c783          	lbu	a5,0(a1)
    800011d4:	9d1d                	subw	a0,a0,a5
}
    800011d6:	6422                	ld	s0,8(sp)
    800011d8:	0141                	addi	sp,sp,16
    800011da:	8082                	ret
    return 0;
    800011dc:	4501                	li	a0,0
    800011de:	bfe5                	j	800011d6 <strncmp+0x32>

00000000800011e0 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    800011e0:	1141                	addi	sp,sp,-16
    800011e2:	e422                	sd	s0,8(sp)
    800011e4:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    800011e6:	872a                	mv	a4,a0
    800011e8:	8832                	mv	a6,a2
    800011ea:	367d                	addiw	a2,a2,-1
    800011ec:	01005963          	blez	a6,800011fe <strncpy+0x1e>
    800011f0:	0705                	addi	a4,a4,1
    800011f2:	0005c783          	lbu	a5,0(a1)
    800011f6:	fef70fa3          	sb	a5,-1(a4)
    800011fa:	0585                	addi	a1,a1,1
    800011fc:	f7f5                	bnez	a5,800011e8 <strncpy+0x8>
    ;
  while(n-- > 0)
    800011fe:	86ba                	mv	a3,a4
    80001200:	00c05c63          	blez	a2,80001218 <strncpy+0x38>
    *s++ = 0;
    80001204:	0685                	addi	a3,a3,1
    80001206:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    8000120a:	40d707bb          	subw	a5,a4,a3
    8000120e:	37fd                	addiw	a5,a5,-1
    80001210:	010787bb          	addw	a5,a5,a6
    80001214:	fef048e3          	bgtz	a5,80001204 <strncpy+0x24>
  return os;
}
    80001218:	6422                	ld	s0,8(sp)
    8000121a:	0141                	addi	sp,sp,16
    8000121c:	8082                	ret

000000008000121e <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    8000121e:	1141                	addi	sp,sp,-16
    80001220:	e422                	sd	s0,8(sp)
    80001222:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80001224:	02c05363          	blez	a2,8000124a <safestrcpy+0x2c>
    80001228:	fff6069b          	addiw	a3,a2,-1
    8000122c:	1682                	slli	a3,a3,0x20
    8000122e:	9281                	srli	a3,a3,0x20
    80001230:	96ae                	add	a3,a3,a1
    80001232:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80001234:	00d58963          	beq	a1,a3,80001246 <safestrcpy+0x28>
    80001238:	0585                	addi	a1,a1,1
    8000123a:	0785                	addi	a5,a5,1
    8000123c:	fff5c703          	lbu	a4,-1(a1)
    80001240:	fee78fa3          	sb	a4,-1(a5)
    80001244:	fb65                	bnez	a4,80001234 <safestrcpy+0x16>
    ;
  *s = 0;
    80001246:	00078023          	sb	zero,0(a5)
  return os;
}
    8000124a:	6422                	ld	s0,8(sp)
    8000124c:	0141                	addi	sp,sp,16
    8000124e:	8082                	ret

0000000080001250 <strlen>:

int
strlen(const char *s)
{
    80001250:	1141                	addi	sp,sp,-16
    80001252:	e422                	sd	s0,8(sp)
    80001254:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80001256:	00054783          	lbu	a5,0(a0)
    8000125a:	cf91                	beqz	a5,80001276 <strlen+0x26>
    8000125c:	0505                	addi	a0,a0,1
    8000125e:	87aa                	mv	a5,a0
    80001260:	4685                	li	a3,1
    80001262:	9e89                	subw	a3,a3,a0
    80001264:	00f6853b          	addw	a0,a3,a5
    80001268:	0785                	addi	a5,a5,1
    8000126a:	fff7c703          	lbu	a4,-1(a5)
    8000126e:	fb7d                	bnez	a4,80001264 <strlen+0x14>
    ;
  return n;
}
    80001270:	6422                	ld	s0,8(sp)
    80001272:	0141                	addi	sp,sp,16
    80001274:	8082                	ret
  for(n = 0; s[n]; n++)
    80001276:	4501                	li	a0,0
    80001278:	bfe5                	j	80001270 <strlen+0x20>

000000008000127a <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    8000127a:	1141                	addi	sp,sp,-16
    8000127c:	e406                	sd	ra,8(sp)
    8000127e:	e022                	sd	s0,0(sp)
    80001280:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80001282:	00001097          	auipc	ra,0x1
    80001286:	a84080e7          	jalr	-1404(ra) # 80001d06 <cpuid>
#endif    
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    8000128a:	00008717          	auipc	a4,0x8
    8000128e:	d8270713          	addi	a4,a4,-638 # 8000900c <started>
  if(cpuid() == 0){
    80001292:	c139                	beqz	a0,800012d8 <main+0x5e>
    while(started == 0)
    80001294:	431c                	lw	a5,0(a4)
    80001296:	2781                	sext.w	a5,a5
    80001298:	dff5                	beqz	a5,80001294 <main+0x1a>
      ;
    __sync_synchronize();
    8000129a:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    8000129e:	00001097          	auipc	ra,0x1
    800012a2:	a68080e7          	jalr	-1432(ra) # 80001d06 <cpuid>
    800012a6:	85aa                	mv	a1,a0
    800012a8:	00007517          	auipc	a0,0x7
    800012ac:	ea850513          	addi	a0,a0,-344 # 80008150 <digits+0x110>
    800012b0:	fffff097          	auipc	ra,0xfffff
    800012b4:	2e6080e7          	jalr	742(ra) # 80000596 <printf>
    kvminithart();    // turn on paging
    800012b8:	00000097          	auipc	ra,0x0
    800012bc:	186080e7          	jalr	390(ra) # 8000143e <kvminithart>
    trapinithart();   // install kernel trap vector
    800012c0:	00001097          	auipc	ra,0x1
    800012c4:	6d2080e7          	jalr	1746(ra) # 80002992 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    800012c8:	00005097          	auipc	ra,0x5
    800012cc:	e38080e7          	jalr	-456(ra) # 80006100 <plicinithart>
  }

  scheduler();        
    800012d0:	00001097          	auipc	ra,0x1
    800012d4:	f9a080e7          	jalr	-102(ra) # 8000226a <scheduler>
    consoleinit();
    800012d8:	fffff097          	auipc	ra,0xfffff
    800012dc:	184080e7          	jalr	388(ra) # 8000045c <consoleinit>
    statsinit();
    800012e0:	00005097          	auipc	ra,0x5
    800012e4:	4b2080e7          	jalr	1202(ra) # 80006792 <statsinit>
    printfinit();
    800012e8:	fffff097          	auipc	ra,0xfffff
    800012ec:	48e080e7          	jalr	1166(ra) # 80000776 <printfinit>
    printf("\n");
    800012f0:	00007517          	auipc	a0,0x7
    800012f4:	e7050513          	addi	a0,a0,-400 # 80008160 <digits+0x120>
    800012f8:	fffff097          	auipc	ra,0xfffff
    800012fc:	29e080e7          	jalr	670(ra) # 80000596 <printf>
    printf("xv6 kernel is booting\n");
    80001300:	00007517          	auipc	a0,0x7
    80001304:	e3850513          	addi	a0,a0,-456 # 80008138 <digits+0xf8>
    80001308:	fffff097          	auipc	ra,0xfffff
    8000130c:	28e080e7          	jalr	654(ra) # 80000596 <printf>
    printf("\n");
    80001310:	00007517          	auipc	a0,0x7
    80001314:	e5050513          	addi	a0,a0,-432 # 80008160 <digits+0x120>
    80001318:	fffff097          	auipc	ra,0xfffff
    8000131c:	27e080e7          	jalr	638(ra) # 80000596 <printf>
    kinit();         // physical page allocator
    80001320:	fffff097          	auipc	ra,0xfffff
    80001324:	7ec080e7          	jalr	2028(ra) # 80000b0c <kinit>
    kvminit();       // create kernel page table
    80001328:	00000097          	auipc	ra,0x0
    8000132c:	242080e7          	jalr	578(ra) # 8000156a <kvminit>
    kvminithart();   // turn on paging
    80001330:	00000097          	auipc	ra,0x0
    80001334:	10e080e7          	jalr	270(ra) # 8000143e <kvminithart>
    procinit();      // process table
    80001338:	00001097          	auipc	ra,0x1
    8000133c:	8fe080e7          	jalr	-1794(ra) # 80001c36 <procinit>
    trapinit();      // trap vectors
    80001340:	00001097          	auipc	ra,0x1
    80001344:	62a080e7          	jalr	1578(ra) # 8000296a <trapinit>
    trapinithart();  // install kernel trap vector
    80001348:	00001097          	auipc	ra,0x1
    8000134c:	64a080e7          	jalr	1610(ra) # 80002992 <trapinithart>
    plicinit();      // set up interrupt controller
    80001350:	00005097          	auipc	ra,0x5
    80001354:	d9a080e7          	jalr	-614(ra) # 800060ea <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80001358:	00005097          	auipc	ra,0x5
    8000135c:	da8080e7          	jalr	-600(ra) # 80006100 <plicinithart>
    binit();         // buffer cache
    80001360:	00002097          	auipc	ra,0x2
    80001364:	d86080e7          	jalr	-634(ra) # 800030e6 <binit>
    iinit();         // inode cache
    80001368:	00002097          	auipc	ra,0x2
    8000136c:	5ae080e7          	jalr	1454(ra) # 80003916 <iinit>
    fileinit();      // file table
    80001370:	00003097          	auipc	ra,0x3
    80001374:	566080e7          	jalr	1382(ra) # 800048d6 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80001378:	00005097          	auipc	ra,0x5
    8000137c:	ea8080e7          	jalr	-344(ra) # 80006220 <virtio_disk_init>
    userinit();      // first user process
    80001380:	00001097          	auipc	ra,0x1
    80001384:	c7c080e7          	jalr	-900(ra) # 80001ffc <userinit>
    __sync_synchronize();
    80001388:	0ff0000f          	fence
    started = 1;
    8000138c:	4785                	li	a5,1
    8000138e:	00008717          	auipc	a4,0x8
    80001392:	c6f72f23          	sw	a5,-898(a4) # 8000900c <started>
    80001396:	bf2d                	j	800012d0 <main+0x56>

0000000080001398 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
static pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80001398:	7139                	addi	sp,sp,-64
    8000139a:	fc06                	sd	ra,56(sp)
    8000139c:	f822                	sd	s0,48(sp)
    8000139e:	f426                	sd	s1,40(sp)
    800013a0:	f04a                	sd	s2,32(sp)
    800013a2:	ec4e                	sd	s3,24(sp)
    800013a4:	e852                	sd	s4,16(sp)
    800013a6:	e456                	sd	s5,8(sp)
    800013a8:	e05a                	sd	s6,0(sp)
    800013aa:	0080                	addi	s0,sp,64
    800013ac:	84aa                	mv	s1,a0
    800013ae:	89ae                	mv	s3,a1
    800013b0:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    800013b2:	57fd                	li	a5,-1
    800013b4:	83e9                	srli	a5,a5,0x1a
    800013b6:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    800013b8:	4b31                	li	s6,12
  if(va >= MAXVA)
    800013ba:	04b7f263          	bgeu	a5,a1,800013fe <walk+0x66>
    panic("walk");
    800013be:	00007517          	auipc	a0,0x7
    800013c2:	daa50513          	addi	a0,a0,-598 # 80008168 <digits+0x128>
    800013c6:	fffff097          	auipc	ra,0xfffff
    800013ca:	186080e7          	jalr	390(ra) # 8000054c <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    800013ce:	060a8663          	beqz	s5,8000143a <walk+0xa2>
    800013d2:	fffff097          	auipc	ra,0xfffff
    800013d6:	796080e7          	jalr	1942(ra) # 80000b68 <kalloc>
    800013da:	84aa                	mv	s1,a0
    800013dc:	c529                	beqz	a0,80001426 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    800013de:	6605                	lui	a2,0x1
    800013e0:	4581                	li	a1,0
    800013e2:	00000097          	auipc	ra,0x0
    800013e6:	cea080e7          	jalr	-790(ra) # 800010cc <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    800013ea:	00c4d793          	srli	a5,s1,0xc
    800013ee:	07aa                	slli	a5,a5,0xa
    800013f0:	0017e793          	ori	a5,a5,1
    800013f4:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    800013f8:	3a5d                	addiw	s4,s4,-9
    800013fa:	036a0063          	beq	s4,s6,8000141a <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    800013fe:	0149d933          	srl	s2,s3,s4
    80001402:	1ff97913          	andi	s2,s2,511
    80001406:	090e                	slli	s2,s2,0x3
    80001408:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    8000140a:	00093483          	ld	s1,0(s2)
    8000140e:	0014f793          	andi	a5,s1,1
    80001412:	dfd5                	beqz	a5,800013ce <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001414:	80a9                	srli	s1,s1,0xa
    80001416:	04b2                	slli	s1,s1,0xc
    80001418:	b7c5                	j	800013f8 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    8000141a:	00c9d513          	srli	a0,s3,0xc
    8000141e:	1ff57513          	andi	a0,a0,511
    80001422:	050e                	slli	a0,a0,0x3
    80001424:	9526                	add	a0,a0,s1
}
    80001426:	70e2                	ld	ra,56(sp)
    80001428:	7442                	ld	s0,48(sp)
    8000142a:	74a2                	ld	s1,40(sp)
    8000142c:	7902                	ld	s2,32(sp)
    8000142e:	69e2                	ld	s3,24(sp)
    80001430:	6a42                	ld	s4,16(sp)
    80001432:	6aa2                	ld	s5,8(sp)
    80001434:	6b02                	ld	s6,0(sp)
    80001436:	6121                	addi	sp,sp,64
    80001438:	8082                	ret
        return 0;
    8000143a:	4501                	li	a0,0
    8000143c:	b7ed                	j	80001426 <walk+0x8e>

000000008000143e <kvminithart>:
{
    8000143e:	1141                	addi	sp,sp,-16
    80001440:	e422                	sd	s0,8(sp)
    80001442:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    80001444:	00008797          	auipc	a5,0x8
    80001448:	bcc7b783          	ld	a5,-1076(a5) # 80009010 <kernel_pagetable>
    8000144c:	83b1                	srli	a5,a5,0xc
    8000144e:	577d                	li	a4,-1
    80001450:	177e                	slli	a4,a4,0x3f
    80001452:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80001454:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80001458:	12000073          	sfence.vma
}
    8000145c:	6422                	ld	s0,8(sp)
    8000145e:	0141                	addi	sp,sp,16
    80001460:	8082                	ret

0000000080001462 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    80001462:	57fd                	li	a5,-1
    80001464:	83e9                	srli	a5,a5,0x1a
    80001466:	00b7f463          	bgeu	a5,a1,8000146e <walkaddr+0xc>
    return 0;
    8000146a:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    8000146c:	8082                	ret
{
    8000146e:	1141                	addi	sp,sp,-16
    80001470:	e406                	sd	ra,8(sp)
    80001472:	e022                	sd	s0,0(sp)
    80001474:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80001476:	4601                	li	a2,0
    80001478:	00000097          	auipc	ra,0x0
    8000147c:	f20080e7          	jalr	-224(ra) # 80001398 <walk>
  if(pte == 0)
    80001480:	c105                	beqz	a0,800014a0 <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    80001482:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    80001484:	0117f693          	andi	a3,a5,17
    80001488:	4745                	li	a4,17
    return 0;
    8000148a:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    8000148c:	00e68663          	beq	a3,a4,80001498 <walkaddr+0x36>
}
    80001490:	60a2                	ld	ra,8(sp)
    80001492:	6402                	ld	s0,0(sp)
    80001494:	0141                	addi	sp,sp,16
    80001496:	8082                	ret
  pa = PTE2PA(*pte);
    80001498:	83a9                	srli	a5,a5,0xa
    8000149a:	00c79513          	slli	a0,a5,0xc
  return pa;
    8000149e:	bfcd                	j	80001490 <walkaddr+0x2e>
    return 0;
    800014a0:	4501                	li	a0,0
    800014a2:	b7fd                	j	80001490 <walkaddr+0x2e>

00000000800014a4 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    800014a4:	715d                	addi	sp,sp,-80
    800014a6:	e486                	sd	ra,72(sp)
    800014a8:	e0a2                	sd	s0,64(sp)
    800014aa:	fc26                	sd	s1,56(sp)
    800014ac:	f84a                	sd	s2,48(sp)
    800014ae:	f44e                	sd	s3,40(sp)
    800014b0:	f052                	sd	s4,32(sp)
    800014b2:	ec56                	sd	s5,24(sp)
    800014b4:	e85a                	sd	s6,16(sp)
    800014b6:	e45e                	sd	s7,8(sp)
    800014b8:	0880                	addi	s0,sp,80
    800014ba:	8aaa                	mv	s5,a0
    800014bc:	8b3a                	mv	s6,a4
  uint64 a, last;
  pte_t *pte;

  a = PGROUNDDOWN(va);
    800014be:	777d                	lui	a4,0xfffff
    800014c0:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    800014c4:	fff60993          	addi	s3,a2,-1 # fff <_entry-0x7ffff001>
    800014c8:	99ae                	add	s3,s3,a1
    800014ca:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    800014ce:	893e                	mv	s2,a5
    800014d0:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800014d4:	6b85                	lui	s7,0x1
    800014d6:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    800014da:	4605                	li	a2,1
    800014dc:	85ca                	mv	a1,s2
    800014de:	8556                	mv	a0,s5
    800014e0:	00000097          	auipc	ra,0x0
    800014e4:	eb8080e7          	jalr	-328(ra) # 80001398 <walk>
    800014e8:	c51d                	beqz	a0,80001516 <mappages+0x72>
    if(*pte & PTE_V)
    800014ea:	611c                	ld	a5,0(a0)
    800014ec:	8b85                	andi	a5,a5,1
    800014ee:	ef81                	bnez	a5,80001506 <mappages+0x62>
    *pte = PA2PTE(pa) | perm | PTE_V;
    800014f0:	80b1                	srli	s1,s1,0xc
    800014f2:	04aa                	slli	s1,s1,0xa
    800014f4:	0164e4b3          	or	s1,s1,s6
    800014f8:	0014e493          	ori	s1,s1,1
    800014fc:	e104                	sd	s1,0(a0)
    if(a == last)
    800014fe:	03390863          	beq	s2,s3,8000152e <mappages+0x8a>
    a += PGSIZE;
    80001502:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    80001504:	bfc9                	j	800014d6 <mappages+0x32>
      panic("remap");
    80001506:	00007517          	auipc	a0,0x7
    8000150a:	c6a50513          	addi	a0,a0,-918 # 80008170 <digits+0x130>
    8000150e:	fffff097          	auipc	ra,0xfffff
    80001512:	03e080e7          	jalr	62(ra) # 8000054c <panic>
      return -1;
    80001516:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    80001518:	60a6                	ld	ra,72(sp)
    8000151a:	6406                	ld	s0,64(sp)
    8000151c:	74e2                	ld	s1,56(sp)
    8000151e:	7942                	ld	s2,48(sp)
    80001520:	79a2                	ld	s3,40(sp)
    80001522:	7a02                	ld	s4,32(sp)
    80001524:	6ae2                	ld	s5,24(sp)
    80001526:	6b42                	ld	s6,16(sp)
    80001528:	6ba2                	ld	s7,8(sp)
    8000152a:	6161                	addi	sp,sp,80
    8000152c:	8082                	ret
  return 0;
    8000152e:	4501                	li	a0,0
    80001530:	b7e5                	j	80001518 <mappages+0x74>

0000000080001532 <kvmmap>:
{
    80001532:	1141                	addi	sp,sp,-16
    80001534:	e406                	sd	ra,8(sp)
    80001536:	e022                	sd	s0,0(sp)
    80001538:	0800                	addi	s0,sp,16
    8000153a:	8736                	mv	a4,a3
  if(mappages(kernel_pagetable, va, sz, pa, perm) != 0)
    8000153c:	86ae                	mv	a3,a1
    8000153e:	85aa                	mv	a1,a0
    80001540:	00008517          	auipc	a0,0x8
    80001544:	ad053503          	ld	a0,-1328(a0) # 80009010 <kernel_pagetable>
    80001548:	00000097          	auipc	ra,0x0
    8000154c:	f5c080e7          	jalr	-164(ra) # 800014a4 <mappages>
    80001550:	e509                	bnez	a0,8000155a <kvmmap+0x28>
}
    80001552:	60a2                	ld	ra,8(sp)
    80001554:	6402                	ld	s0,0(sp)
    80001556:	0141                	addi	sp,sp,16
    80001558:	8082                	ret
    panic("kvmmap");
    8000155a:	00007517          	auipc	a0,0x7
    8000155e:	c1e50513          	addi	a0,a0,-994 # 80008178 <digits+0x138>
    80001562:	fffff097          	auipc	ra,0xfffff
    80001566:	fea080e7          	jalr	-22(ra) # 8000054c <panic>

000000008000156a <kvminit>:
{
    8000156a:	1101                	addi	sp,sp,-32
    8000156c:	ec06                	sd	ra,24(sp)
    8000156e:	e822                	sd	s0,16(sp)
    80001570:	e426                	sd	s1,8(sp)
    80001572:	1000                	addi	s0,sp,32
  kernel_pagetable = (pagetable_t) kalloc();
    80001574:	fffff097          	auipc	ra,0xfffff
    80001578:	5f4080e7          	jalr	1524(ra) # 80000b68 <kalloc>
    8000157c:	00008717          	auipc	a4,0x8
    80001580:	a8a73a23          	sd	a0,-1388(a4) # 80009010 <kernel_pagetable>
  memset(kernel_pagetable, 0, PGSIZE);
    80001584:	6605                	lui	a2,0x1
    80001586:	4581                	li	a1,0
    80001588:	00000097          	auipc	ra,0x0
    8000158c:	b44080e7          	jalr	-1212(ra) # 800010cc <memset>
  kvmmap(UART0, UART0, PGSIZE, PTE_R | PTE_W);
    80001590:	4699                	li	a3,6
    80001592:	6605                	lui	a2,0x1
    80001594:	100005b7          	lui	a1,0x10000
    80001598:	10000537          	lui	a0,0x10000
    8000159c:	00000097          	auipc	ra,0x0
    800015a0:	f96080e7          	jalr	-106(ra) # 80001532 <kvmmap>
  kvmmap(VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800015a4:	4699                	li	a3,6
    800015a6:	6605                	lui	a2,0x1
    800015a8:	100015b7          	lui	a1,0x10001
    800015ac:	10001537          	lui	a0,0x10001
    800015b0:	00000097          	auipc	ra,0x0
    800015b4:	f82080e7          	jalr	-126(ra) # 80001532 <kvmmap>
  kvmmap(PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800015b8:	4699                	li	a3,6
    800015ba:	00400637          	lui	a2,0x400
    800015be:	0c0005b7          	lui	a1,0xc000
    800015c2:	0c000537          	lui	a0,0xc000
    800015c6:	00000097          	auipc	ra,0x0
    800015ca:	f6c080e7          	jalr	-148(ra) # 80001532 <kvmmap>
  kvmmap(KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800015ce:	00007497          	auipc	s1,0x7
    800015d2:	a3248493          	addi	s1,s1,-1486 # 80008000 <etext>
    800015d6:	46a9                	li	a3,10
    800015d8:	80007617          	auipc	a2,0x80007
    800015dc:	a2860613          	addi	a2,a2,-1496 # 8000 <_entry-0x7fff8000>
    800015e0:	4585                	li	a1,1
    800015e2:	05fe                	slli	a1,a1,0x1f
    800015e4:	852e                	mv	a0,a1
    800015e6:	00000097          	auipc	ra,0x0
    800015ea:	f4c080e7          	jalr	-180(ra) # 80001532 <kvmmap>
  kvmmap((uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    800015ee:	4699                	li	a3,6
    800015f0:	4645                	li	a2,17
    800015f2:	066e                	slli	a2,a2,0x1b
    800015f4:	8e05                	sub	a2,a2,s1
    800015f6:	85a6                	mv	a1,s1
    800015f8:	8526                	mv	a0,s1
    800015fa:	00000097          	auipc	ra,0x0
    800015fe:	f38080e7          	jalr	-200(ra) # 80001532 <kvmmap>
  kvmmap(TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80001602:	46a9                	li	a3,10
    80001604:	6605                	lui	a2,0x1
    80001606:	00006597          	auipc	a1,0x6
    8000160a:	9fa58593          	addi	a1,a1,-1542 # 80007000 <_trampoline>
    8000160e:	04000537          	lui	a0,0x4000
    80001612:	157d                	addi	a0,a0,-1 # 3ffffff <_entry-0x7c000001>
    80001614:	0532                	slli	a0,a0,0xc
    80001616:	00000097          	auipc	ra,0x0
    8000161a:	f1c080e7          	jalr	-228(ra) # 80001532 <kvmmap>
}
    8000161e:	60e2                	ld	ra,24(sp)
    80001620:	6442                	ld	s0,16(sp)
    80001622:	64a2                	ld	s1,8(sp)
    80001624:	6105                	addi	sp,sp,32
    80001626:	8082                	ret

0000000080001628 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001628:	715d                	addi	sp,sp,-80
    8000162a:	e486                	sd	ra,72(sp)
    8000162c:	e0a2                	sd	s0,64(sp)
    8000162e:	fc26                	sd	s1,56(sp)
    80001630:	f84a                	sd	s2,48(sp)
    80001632:	f44e                	sd	s3,40(sp)
    80001634:	f052                	sd	s4,32(sp)
    80001636:	ec56                	sd	s5,24(sp)
    80001638:	e85a                	sd	s6,16(sp)
    8000163a:	e45e                	sd	s7,8(sp)
    8000163c:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    8000163e:	03459793          	slli	a5,a1,0x34
    80001642:	e795                	bnez	a5,8000166e <uvmunmap+0x46>
    80001644:	8a2a                	mv	s4,a0
    80001646:	892e                	mv	s2,a1
    80001648:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000164a:	0632                	slli	a2,a2,0xc
    8000164c:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    80001650:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001652:	6b05                	lui	s6,0x1
    80001654:	0735e263          	bltu	a1,s3,800016b8 <uvmunmap+0x90>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    80001658:	60a6                	ld	ra,72(sp)
    8000165a:	6406                	ld	s0,64(sp)
    8000165c:	74e2                	ld	s1,56(sp)
    8000165e:	7942                	ld	s2,48(sp)
    80001660:	79a2                	ld	s3,40(sp)
    80001662:	7a02                	ld	s4,32(sp)
    80001664:	6ae2                	ld	s5,24(sp)
    80001666:	6b42                	ld	s6,16(sp)
    80001668:	6ba2                	ld	s7,8(sp)
    8000166a:	6161                	addi	sp,sp,80
    8000166c:	8082                	ret
    panic("uvmunmap: not aligned");
    8000166e:	00007517          	auipc	a0,0x7
    80001672:	b1250513          	addi	a0,a0,-1262 # 80008180 <digits+0x140>
    80001676:	fffff097          	auipc	ra,0xfffff
    8000167a:	ed6080e7          	jalr	-298(ra) # 8000054c <panic>
      panic("uvmunmap: walk");
    8000167e:	00007517          	auipc	a0,0x7
    80001682:	b1a50513          	addi	a0,a0,-1254 # 80008198 <digits+0x158>
    80001686:	fffff097          	auipc	ra,0xfffff
    8000168a:	ec6080e7          	jalr	-314(ra) # 8000054c <panic>
      panic("uvmunmap: not mapped");
    8000168e:	00007517          	auipc	a0,0x7
    80001692:	b1a50513          	addi	a0,a0,-1254 # 800081a8 <digits+0x168>
    80001696:	fffff097          	auipc	ra,0xfffff
    8000169a:	eb6080e7          	jalr	-330(ra) # 8000054c <panic>
      panic("uvmunmap: not a leaf");
    8000169e:	00007517          	auipc	a0,0x7
    800016a2:	b2250513          	addi	a0,a0,-1246 # 800081c0 <digits+0x180>
    800016a6:	fffff097          	auipc	ra,0xfffff
    800016aa:	ea6080e7          	jalr	-346(ra) # 8000054c <panic>
    *pte = 0;
    800016ae:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800016b2:	995a                	add	s2,s2,s6
    800016b4:	fb3972e3          	bgeu	s2,s3,80001658 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    800016b8:	4601                	li	a2,0
    800016ba:	85ca                	mv	a1,s2
    800016bc:	8552                	mv	a0,s4
    800016be:	00000097          	auipc	ra,0x0
    800016c2:	cda080e7          	jalr	-806(ra) # 80001398 <walk>
    800016c6:	84aa                	mv	s1,a0
    800016c8:	d95d                	beqz	a0,8000167e <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    800016ca:	6108                	ld	a0,0(a0)
    800016cc:	00157793          	andi	a5,a0,1
    800016d0:	dfdd                	beqz	a5,8000168e <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    800016d2:	3ff57793          	andi	a5,a0,1023
    800016d6:	fd7784e3          	beq	a5,s7,8000169e <uvmunmap+0x76>
    if(do_free){
    800016da:	fc0a8ae3          	beqz	s5,800016ae <uvmunmap+0x86>
      uint64 pa = PTE2PA(*pte);
    800016de:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    800016e0:	0532                	slli	a0,a0,0xc
    800016e2:	fffff097          	auipc	ra,0xfffff
    800016e6:	336080e7          	jalr	822(ra) # 80000a18 <kfree>
    800016ea:	b7d1                	j	800016ae <uvmunmap+0x86>

00000000800016ec <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    800016ec:	1101                	addi	sp,sp,-32
    800016ee:	ec06                	sd	ra,24(sp)
    800016f0:	e822                	sd	s0,16(sp)
    800016f2:	e426                	sd	s1,8(sp)
    800016f4:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    800016f6:	fffff097          	auipc	ra,0xfffff
    800016fa:	472080e7          	jalr	1138(ra) # 80000b68 <kalloc>
    800016fe:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001700:	c519                	beqz	a0,8000170e <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    80001702:	6605                	lui	a2,0x1
    80001704:	4581                	li	a1,0
    80001706:	00000097          	auipc	ra,0x0
    8000170a:	9c6080e7          	jalr	-1594(ra) # 800010cc <memset>
  return pagetable;
}
    8000170e:	8526                	mv	a0,s1
    80001710:	60e2                	ld	ra,24(sp)
    80001712:	6442                	ld	s0,16(sp)
    80001714:	64a2                	ld	s1,8(sp)
    80001716:	6105                	addi	sp,sp,32
    80001718:	8082                	ret

000000008000171a <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    8000171a:	7179                	addi	sp,sp,-48
    8000171c:	f406                	sd	ra,40(sp)
    8000171e:	f022                	sd	s0,32(sp)
    80001720:	ec26                	sd	s1,24(sp)
    80001722:	e84a                	sd	s2,16(sp)
    80001724:	e44e                	sd	s3,8(sp)
    80001726:	e052                	sd	s4,0(sp)
    80001728:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    8000172a:	6785                	lui	a5,0x1
    8000172c:	04f67863          	bgeu	a2,a5,8000177c <uvminit+0x62>
    80001730:	8a2a                	mv	s4,a0
    80001732:	89ae                	mv	s3,a1
    80001734:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    80001736:	fffff097          	auipc	ra,0xfffff
    8000173a:	432080e7          	jalr	1074(ra) # 80000b68 <kalloc>
    8000173e:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    80001740:	6605                	lui	a2,0x1
    80001742:	4581                	li	a1,0
    80001744:	00000097          	auipc	ra,0x0
    80001748:	988080e7          	jalr	-1656(ra) # 800010cc <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    8000174c:	4779                	li	a4,30
    8000174e:	86ca                	mv	a3,s2
    80001750:	6605                	lui	a2,0x1
    80001752:	4581                	li	a1,0
    80001754:	8552                	mv	a0,s4
    80001756:	00000097          	auipc	ra,0x0
    8000175a:	d4e080e7          	jalr	-690(ra) # 800014a4 <mappages>
  memmove(mem, src, sz);
    8000175e:	8626                	mv	a2,s1
    80001760:	85ce                	mv	a1,s3
    80001762:	854a                	mv	a0,s2
    80001764:	00000097          	auipc	ra,0x0
    80001768:	9c4080e7          	jalr	-1596(ra) # 80001128 <memmove>
}
    8000176c:	70a2                	ld	ra,40(sp)
    8000176e:	7402                	ld	s0,32(sp)
    80001770:	64e2                	ld	s1,24(sp)
    80001772:	6942                	ld	s2,16(sp)
    80001774:	69a2                	ld	s3,8(sp)
    80001776:	6a02                	ld	s4,0(sp)
    80001778:	6145                	addi	sp,sp,48
    8000177a:	8082                	ret
    panic("inituvm: more than a page");
    8000177c:	00007517          	auipc	a0,0x7
    80001780:	a5c50513          	addi	a0,a0,-1444 # 800081d8 <digits+0x198>
    80001784:	fffff097          	auipc	ra,0xfffff
    80001788:	dc8080e7          	jalr	-568(ra) # 8000054c <panic>

000000008000178c <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    8000178c:	1101                	addi	sp,sp,-32
    8000178e:	ec06                	sd	ra,24(sp)
    80001790:	e822                	sd	s0,16(sp)
    80001792:	e426                	sd	s1,8(sp)
    80001794:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    80001796:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    80001798:	00b67d63          	bgeu	a2,a1,800017b2 <uvmdealloc+0x26>
    8000179c:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    8000179e:	6785                	lui	a5,0x1
    800017a0:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    800017a2:	00f60733          	add	a4,a2,a5
    800017a6:	76fd                	lui	a3,0xfffff
    800017a8:	8f75                	and	a4,a4,a3
    800017aa:	97ae                	add	a5,a5,a1
    800017ac:	8ff5                	and	a5,a5,a3
    800017ae:	00f76863          	bltu	a4,a5,800017be <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    800017b2:	8526                	mv	a0,s1
    800017b4:	60e2                	ld	ra,24(sp)
    800017b6:	6442                	ld	s0,16(sp)
    800017b8:	64a2                	ld	s1,8(sp)
    800017ba:	6105                	addi	sp,sp,32
    800017bc:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    800017be:	8f99                	sub	a5,a5,a4
    800017c0:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    800017c2:	4685                	li	a3,1
    800017c4:	0007861b          	sext.w	a2,a5
    800017c8:	85ba                	mv	a1,a4
    800017ca:	00000097          	auipc	ra,0x0
    800017ce:	e5e080e7          	jalr	-418(ra) # 80001628 <uvmunmap>
    800017d2:	b7c5                	j	800017b2 <uvmdealloc+0x26>

00000000800017d4 <uvmalloc>:
  if(newsz < oldsz)
    800017d4:	0ab66163          	bltu	a2,a1,80001876 <uvmalloc+0xa2>
{
    800017d8:	7139                	addi	sp,sp,-64
    800017da:	fc06                	sd	ra,56(sp)
    800017dc:	f822                	sd	s0,48(sp)
    800017de:	f426                	sd	s1,40(sp)
    800017e0:	f04a                	sd	s2,32(sp)
    800017e2:	ec4e                	sd	s3,24(sp)
    800017e4:	e852                	sd	s4,16(sp)
    800017e6:	e456                	sd	s5,8(sp)
    800017e8:	0080                	addi	s0,sp,64
    800017ea:	8aaa                	mv	s5,a0
    800017ec:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    800017ee:	6785                	lui	a5,0x1
    800017f0:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    800017f2:	95be                	add	a1,a1,a5
    800017f4:	77fd                	lui	a5,0xfffff
    800017f6:	00f5f9b3          	and	s3,a1,a5
  for(a = oldsz; a < newsz; a += PGSIZE){
    800017fa:	08c9f063          	bgeu	s3,a2,8000187a <uvmalloc+0xa6>
    800017fe:	894e                	mv	s2,s3
    mem = kalloc();
    80001800:	fffff097          	auipc	ra,0xfffff
    80001804:	368080e7          	jalr	872(ra) # 80000b68 <kalloc>
    80001808:	84aa                	mv	s1,a0
    if(mem == 0){
    8000180a:	c51d                	beqz	a0,80001838 <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    8000180c:	6605                	lui	a2,0x1
    8000180e:	4581                	li	a1,0
    80001810:	00000097          	auipc	ra,0x0
    80001814:	8bc080e7          	jalr	-1860(ra) # 800010cc <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    80001818:	4779                	li	a4,30
    8000181a:	86a6                	mv	a3,s1
    8000181c:	6605                	lui	a2,0x1
    8000181e:	85ca                	mv	a1,s2
    80001820:	8556                	mv	a0,s5
    80001822:	00000097          	auipc	ra,0x0
    80001826:	c82080e7          	jalr	-894(ra) # 800014a4 <mappages>
    8000182a:	e905                	bnez	a0,8000185a <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000182c:	6785                	lui	a5,0x1
    8000182e:	993e                	add	s2,s2,a5
    80001830:	fd4968e3          	bltu	s2,s4,80001800 <uvmalloc+0x2c>
  return newsz;
    80001834:	8552                	mv	a0,s4
    80001836:	a809                	j	80001848 <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    80001838:	864e                	mv	a2,s3
    8000183a:	85ca                	mv	a1,s2
    8000183c:	8556                	mv	a0,s5
    8000183e:	00000097          	auipc	ra,0x0
    80001842:	f4e080e7          	jalr	-178(ra) # 8000178c <uvmdealloc>
      return 0;
    80001846:	4501                	li	a0,0
}
    80001848:	70e2                	ld	ra,56(sp)
    8000184a:	7442                	ld	s0,48(sp)
    8000184c:	74a2                	ld	s1,40(sp)
    8000184e:	7902                	ld	s2,32(sp)
    80001850:	69e2                	ld	s3,24(sp)
    80001852:	6a42                	ld	s4,16(sp)
    80001854:	6aa2                	ld	s5,8(sp)
    80001856:	6121                	addi	sp,sp,64
    80001858:	8082                	ret
      kfree(mem);
    8000185a:	8526                	mv	a0,s1
    8000185c:	fffff097          	auipc	ra,0xfffff
    80001860:	1bc080e7          	jalr	444(ra) # 80000a18 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    80001864:	864e                	mv	a2,s3
    80001866:	85ca                	mv	a1,s2
    80001868:	8556                	mv	a0,s5
    8000186a:	00000097          	auipc	ra,0x0
    8000186e:	f22080e7          	jalr	-222(ra) # 8000178c <uvmdealloc>
      return 0;
    80001872:	4501                	li	a0,0
    80001874:	bfd1                	j	80001848 <uvmalloc+0x74>
    return oldsz;
    80001876:	852e                	mv	a0,a1
}
    80001878:	8082                	ret
  return newsz;
    8000187a:	8532                	mv	a0,a2
    8000187c:	b7f1                	j	80001848 <uvmalloc+0x74>

000000008000187e <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    8000187e:	7179                	addi	sp,sp,-48
    80001880:	f406                	sd	ra,40(sp)
    80001882:	f022                	sd	s0,32(sp)
    80001884:	ec26                	sd	s1,24(sp)
    80001886:	e84a                	sd	s2,16(sp)
    80001888:	e44e                	sd	s3,8(sp)
    8000188a:	e052                	sd	s4,0(sp)
    8000188c:	1800                	addi	s0,sp,48
    8000188e:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    80001890:	84aa                	mv	s1,a0
    80001892:	6905                	lui	s2,0x1
    80001894:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001896:	4985                	li	s3,1
    80001898:	a829                	j	800018b2 <freewalk+0x34>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    8000189a:	83a9                	srli	a5,a5,0xa
      freewalk((pagetable_t)child);
    8000189c:	00c79513          	slli	a0,a5,0xc
    800018a0:	00000097          	auipc	ra,0x0
    800018a4:	fde080e7          	jalr	-34(ra) # 8000187e <freewalk>
      pagetable[i] = 0;
    800018a8:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800018ac:	04a1                	addi	s1,s1,8
    800018ae:	03248163          	beq	s1,s2,800018d0 <freewalk+0x52>
    pte_t pte = pagetable[i];
    800018b2:	609c                	ld	a5,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800018b4:	00f7f713          	andi	a4,a5,15
    800018b8:	ff3701e3          	beq	a4,s3,8000189a <freewalk+0x1c>
    } else if(pte & PTE_V){
    800018bc:	8b85                	andi	a5,a5,1
    800018be:	d7fd                	beqz	a5,800018ac <freewalk+0x2e>
      panic("freewalk: leaf");
    800018c0:	00007517          	auipc	a0,0x7
    800018c4:	93850513          	addi	a0,a0,-1736 # 800081f8 <digits+0x1b8>
    800018c8:	fffff097          	auipc	ra,0xfffff
    800018cc:	c84080e7          	jalr	-892(ra) # 8000054c <panic>
    }
  }
  kfree((void*)pagetable);
    800018d0:	8552                	mv	a0,s4
    800018d2:	fffff097          	auipc	ra,0xfffff
    800018d6:	146080e7          	jalr	326(ra) # 80000a18 <kfree>
}
    800018da:	70a2                	ld	ra,40(sp)
    800018dc:	7402                	ld	s0,32(sp)
    800018de:	64e2                	ld	s1,24(sp)
    800018e0:	6942                	ld	s2,16(sp)
    800018e2:	69a2                	ld	s3,8(sp)
    800018e4:	6a02                	ld	s4,0(sp)
    800018e6:	6145                	addi	sp,sp,48
    800018e8:	8082                	ret

00000000800018ea <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    800018ea:	1101                	addi	sp,sp,-32
    800018ec:	ec06                	sd	ra,24(sp)
    800018ee:	e822                	sd	s0,16(sp)
    800018f0:	e426                	sd	s1,8(sp)
    800018f2:	1000                	addi	s0,sp,32
    800018f4:	84aa                	mv	s1,a0
  if(sz > 0)
    800018f6:	e999                	bnez	a1,8000190c <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    800018f8:	8526                	mv	a0,s1
    800018fa:	00000097          	auipc	ra,0x0
    800018fe:	f84080e7          	jalr	-124(ra) # 8000187e <freewalk>
}
    80001902:	60e2                	ld	ra,24(sp)
    80001904:	6442                	ld	s0,16(sp)
    80001906:	64a2                	ld	s1,8(sp)
    80001908:	6105                	addi	sp,sp,32
    8000190a:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    8000190c:	6785                	lui	a5,0x1
    8000190e:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80001910:	95be                	add	a1,a1,a5
    80001912:	4685                	li	a3,1
    80001914:	00c5d613          	srli	a2,a1,0xc
    80001918:	4581                	li	a1,0
    8000191a:	00000097          	auipc	ra,0x0
    8000191e:	d0e080e7          	jalr	-754(ra) # 80001628 <uvmunmap>
    80001922:	bfd9                	j	800018f8 <uvmfree+0xe>

0000000080001924 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    80001924:	c679                	beqz	a2,800019f2 <uvmcopy+0xce>
{
    80001926:	715d                	addi	sp,sp,-80
    80001928:	e486                	sd	ra,72(sp)
    8000192a:	e0a2                	sd	s0,64(sp)
    8000192c:	fc26                	sd	s1,56(sp)
    8000192e:	f84a                	sd	s2,48(sp)
    80001930:	f44e                	sd	s3,40(sp)
    80001932:	f052                	sd	s4,32(sp)
    80001934:	ec56                	sd	s5,24(sp)
    80001936:	e85a                	sd	s6,16(sp)
    80001938:	e45e                	sd	s7,8(sp)
    8000193a:	0880                	addi	s0,sp,80
    8000193c:	8b2a                	mv	s6,a0
    8000193e:	8aae                	mv	s5,a1
    80001940:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    80001942:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    80001944:	4601                	li	a2,0
    80001946:	85ce                	mv	a1,s3
    80001948:	855a                	mv	a0,s6
    8000194a:	00000097          	auipc	ra,0x0
    8000194e:	a4e080e7          	jalr	-1458(ra) # 80001398 <walk>
    80001952:	c531                	beqz	a0,8000199e <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    80001954:	6118                	ld	a4,0(a0)
    80001956:	00177793          	andi	a5,a4,1
    8000195a:	cbb1                	beqz	a5,800019ae <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    8000195c:	00a75593          	srli	a1,a4,0xa
    80001960:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    80001964:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    80001968:	fffff097          	auipc	ra,0xfffff
    8000196c:	200080e7          	jalr	512(ra) # 80000b68 <kalloc>
    80001970:	892a                	mv	s2,a0
    80001972:	c939                	beqz	a0,800019c8 <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    80001974:	6605                	lui	a2,0x1
    80001976:	85de                	mv	a1,s7
    80001978:	fffff097          	auipc	ra,0xfffff
    8000197c:	7b0080e7          	jalr	1968(ra) # 80001128 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    80001980:	8726                	mv	a4,s1
    80001982:	86ca                	mv	a3,s2
    80001984:	6605                	lui	a2,0x1
    80001986:	85ce                	mv	a1,s3
    80001988:	8556                	mv	a0,s5
    8000198a:	00000097          	auipc	ra,0x0
    8000198e:	b1a080e7          	jalr	-1254(ra) # 800014a4 <mappages>
    80001992:	e515                	bnez	a0,800019be <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    80001994:	6785                	lui	a5,0x1
    80001996:	99be                	add	s3,s3,a5
    80001998:	fb49e6e3          	bltu	s3,s4,80001944 <uvmcopy+0x20>
    8000199c:	a081                	j	800019dc <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    8000199e:	00007517          	auipc	a0,0x7
    800019a2:	86a50513          	addi	a0,a0,-1942 # 80008208 <digits+0x1c8>
    800019a6:	fffff097          	auipc	ra,0xfffff
    800019aa:	ba6080e7          	jalr	-1114(ra) # 8000054c <panic>
      panic("uvmcopy: page not present");
    800019ae:	00007517          	auipc	a0,0x7
    800019b2:	87a50513          	addi	a0,a0,-1926 # 80008228 <digits+0x1e8>
    800019b6:	fffff097          	auipc	ra,0xfffff
    800019ba:	b96080e7          	jalr	-1130(ra) # 8000054c <panic>
      kfree(mem);
    800019be:	854a                	mv	a0,s2
    800019c0:	fffff097          	auipc	ra,0xfffff
    800019c4:	058080e7          	jalr	88(ra) # 80000a18 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    800019c8:	4685                	li	a3,1
    800019ca:	00c9d613          	srli	a2,s3,0xc
    800019ce:	4581                	li	a1,0
    800019d0:	8556                	mv	a0,s5
    800019d2:	00000097          	auipc	ra,0x0
    800019d6:	c56080e7          	jalr	-938(ra) # 80001628 <uvmunmap>
  return -1;
    800019da:	557d                	li	a0,-1
}
    800019dc:	60a6                	ld	ra,72(sp)
    800019de:	6406                	ld	s0,64(sp)
    800019e0:	74e2                	ld	s1,56(sp)
    800019e2:	7942                	ld	s2,48(sp)
    800019e4:	79a2                	ld	s3,40(sp)
    800019e6:	7a02                	ld	s4,32(sp)
    800019e8:	6ae2                	ld	s5,24(sp)
    800019ea:	6b42                	ld	s6,16(sp)
    800019ec:	6ba2                	ld	s7,8(sp)
    800019ee:	6161                	addi	sp,sp,80
    800019f0:	8082                	ret
  return 0;
    800019f2:	4501                	li	a0,0
}
    800019f4:	8082                	ret

00000000800019f6 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    800019f6:	1141                	addi	sp,sp,-16
    800019f8:	e406                	sd	ra,8(sp)
    800019fa:	e022                	sd	s0,0(sp)
    800019fc:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    800019fe:	4601                	li	a2,0
    80001a00:	00000097          	auipc	ra,0x0
    80001a04:	998080e7          	jalr	-1640(ra) # 80001398 <walk>
  if(pte == 0)
    80001a08:	c901                	beqz	a0,80001a18 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    80001a0a:	611c                	ld	a5,0(a0)
    80001a0c:	9bbd                	andi	a5,a5,-17
    80001a0e:	e11c                	sd	a5,0(a0)
}
    80001a10:	60a2                	ld	ra,8(sp)
    80001a12:	6402                	ld	s0,0(sp)
    80001a14:	0141                	addi	sp,sp,16
    80001a16:	8082                	ret
    panic("uvmclear");
    80001a18:	00007517          	auipc	a0,0x7
    80001a1c:	83050513          	addi	a0,a0,-2000 # 80008248 <digits+0x208>
    80001a20:	fffff097          	auipc	ra,0xfffff
    80001a24:	b2c080e7          	jalr	-1236(ra) # 8000054c <panic>

0000000080001a28 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001a28:	c6bd                	beqz	a3,80001a96 <copyout+0x6e>
{
    80001a2a:	715d                	addi	sp,sp,-80
    80001a2c:	e486                	sd	ra,72(sp)
    80001a2e:	e0a2                	sd	s0,64(sp)
    80001a30:	fc26                	sd	s1,56(sp)
    80001a32:	f84a                	sd	s2,48(sp)
    80001a34:	f44e                	sd	s3,40(sp)
    80001a36:	f052                	sd	s4,32(sp)
    80001a38:	ec56                	sd	s5,24(sp)
    80001a3a:	e85a                	sd	s6,16(sp)
    80001a3c:	e45e                	sd	s7,8(sp)
    80001a3e:	e062                	sd	s8,0(sp)
    80001a40:	0880                	addi	s0,sp,80
    80001a42:	8b2a                	mv	s6,a0
    80001a44:	8c2e                	mv	s8,a1
    80001a46:	8a32                	mv	s4,a2
    80001a48:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    80001a4a:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    80001a4c:	6a85                	lui	s5,0x1
    80001a4e:	a015                	j	80001a72 <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    80001a50:	9562                	add	a0,a0,s8
    80001a52:	0004861b          	sext.w	a2,s1
    80001a56:	85d2                	mv	a1,s4
    80001a58:	41250533          	sub	a0,a0,s2
    80001a5c:	fffff097          	auipc	ra,0xfffff
    80001a60:	6cc080e7          	jalr	1740(ra) # 80001128 <memmove>

    len -= n;
    80001a64:	409989b3          	sub	s3,s3,s1
    src += n;
    80001a68:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    80001a6a:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001a6e:	02098263          	beqz	s3,80001a92 <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    80001a72:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001a76:	85ca                	mv	a1,s2
    80001a78:	855a                	mv	a0,s6
    80001a7a:	00000097          	auipc	ra,0x0
    80001a7e:	9e8080e7          	jalr	-1560(ra) # 80001462 <walkaddr>
    if(pa0 == 0)
    80001a82:	cd01                	beqz	a0,80001a9a <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    80001a84:	418904b3          	sub	s1,s2,s8
    80001a88:	94d6                	add	s1,s1,s5
    80001a8a:	fc99f3e3          	bgeu	s3,s1,80001a50 <copyout+0x28>
    80001a8e:	84ce                	mv	s1,s3
    80001a90:	b7c1                	j	80001a50 <copyout+0x28>
  }
  return 0;
    80001a92:	4501                	li	a0,0
    80001a94:	a021                	j	80001a9c <copyout+0x74>
    80001a96:	4501                	li	a0,0
}
    80001a98:	8082                	ret
      return -1;
    80001a9a:	557d                	li	a0,-1
}
    80001a9c:	60a6                	ld	ra,72(sp)
    80001a9e:	6406                	ld	s0,64(sp)
    80001aa0:	74e2                	ld	s1,56(sp)
    80001aa2:	7942                	ld	s2,48(sp)
    80001aa4:	79a2                	ld	s3,40(sp)
    80001aa6:	7a02                	ld	s4,32(sp)
    80001aa8:	6ae2                	ld	s5,24(sp)
    80001aaa:	6b42                	ld	s6,16(sp)
    80001aac:	6ba2                	ld	s7,8(sp)
    80001aae:	6c02                	ld	s8,0(sp)
    80001ab0:	6161                	addi	sp,sp,80
    80001ab2:	8082                	ret

0000000080001ab4 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001ab4:	caa5                	beqz	a3,80001b24 <copyin+0x70>
{
    80001ab6:	715d                	addi	sp,sp,-80
    80001ab8:	e486                	sd	ra,72(sp)
    80001aba:	e0a2                	sd	s0,64(sp)
    80001abc:	fc26                	sd	s1,56(sp)
    80001abe:	f84a                	sd	s2,48(sp)
    80001ac0:	f44e                	sd	s3,40(sp)
    80001ac2:	f052                	sd	s4,32(sp)
    80001ac4:	ec56                	sd	s5,24(sp)
    80001ac6:	e85a                	sd	s6,16(sp)
    80001ac8:	e45e                	sd	s7,8(sp)
    80001aca:	e062                	sd	s8,0(sp)
    80001acc:	0880                	addi	s0,sp,80
    80001ace:	8b2a                	mv	s6,a0
    80001ad0:	8a2e                	mv	s4,a1
    80001ad2:	8c32                	mv	s8,a2
    80001ad4:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001ad6:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001ad8:	6a85                	lui	s5,0x1
    80001ada:	a01d                	j	80001b00 <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001adc:	018505b3          	add	a1,a0,s8
    80001ae0:	0004861b          	sext.w	a2,s1
    80001ae4:	412585b3          	sub	a1,a1,s2
    80001ae8:	8552                	mv	a0,s4
    80001aea:	fffff097          	auipc	ra,0xfffff
    80001aee:	63e080e7          	jalr	1598(ra) # 80001128 <memmove>

    len -= n;
    80001af2:	409989b3          	sub	s3,s3,s1
    dst += n;
    80001af6:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001af8:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001afc:	02098263          	beqz	s3,80001b20 <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    80001b00:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001b04:	85ca                	mv	a1,s2
    80001b06:	855a                	mv	a0,s6
    80001b08:	00000097          	auipc	ra,0x0
    80001b0c:	95a080e7          	jalr	-1702(ra) # 80001462 <walkaddr>
    if(pa0 == 0)
    80001b10:	cd01                	beqz	a0,80001b28 <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    80001b12:	418904b3          	sub	s1,s2,s8
    80001b16:	94d6                	add	s1,s1,s5
    80001b18:	fc99f2e3          	bgeu	s3,s1,80001adc <copyin+0x28>
    80001b1c:	84ce                	mv	s1,s3
    80001b1e:	bf7d                	j	80001adc <copyin+0x28>
  }
  return 0;
    80001b20:	4501                	li	a0,0
    80001b22:	a021                	j	80001b2a <copyin+0x76>
    80001b24:	4501                	li	a0,0
}
    80001b26:	8082                	ret
      return -1;
    80001b28:	557d                	li	a0,-1
}
    80001b2a:	60a6                	ld	ra,72(sp)
    80001b2c:	6406                	ld	s0,64(sp)
    80001b2e:	74e2                	ld	s1,56(sp)
    80001b30:	7942                	ld	s2,48(sp)
    80001b32:	79a2                	ld	s3,40(sp)
    80001b34:	7a02                	ld	s4,32(sp)
    80001b36:	6ae2                	ld	s5,24(sp)
    80001b38:	6b42                	ld	s6,16(sp)
    80001b3a:	6ba2                	ld	s7,8(sp)
    80001b3c:	6c02                	ld	s8,0(sp)
    80001b3e:	6161                	addi	sp,sp,80
    80001b40:	8082                	ret

0000000080001b42 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    80001b42:	c2dd                	beqz	a3,80001be8 <copyinstr+0xa6>
{
    80001b44:	715d                	addi	sp,sp,-80
    80001b46:	e486                	sd	ra,72(sp)
    80001b48:	e0a2                	sd	s0,64(sp)
    80001b4a:	fc26                	sd	s1,56(sp)
    80001b4c:	f84a                	sd	s2,48(sp)
    80001b4e:	f44e                	sd	s3,40(sp)
    80001b50:	f052                	sd	s4,32(sp)
    80001b52:	ec56                	sd	s5,24(sp)
    80001b54:	e85a                	sd	s6,16(sp)
    80001b56:	e45e                	sd	s7,8(sp)
    80001b58:	0880                	addi	s0,sp,80
    80001b5a:	8a2a                	mv	s4,a0
    80001b5c:	8b2e                	mv	s6,a1
    80001b5e:	8bb2                	mv	s7,a2
    80001b60:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    80001b62:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001b64:	6985                	lui	s3,0x1
    80001b66:	a02d                	j	80001b90 <copyinstr+0x4e>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    80001b68:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    80001b6c:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    80001b6e:	37fd                	addiw	a5,a5,-1
    80001b70:	0007851b          	sext.w	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    80001b74:	60a6                	ld	ra,72(sp)
    80001b76:	6406                	ld	s0,64(sp)
    80001b78:	74e2                	ld	s1,56(sp)
    80001b7a:	7942                	ld	s2,48(sp)
    80001b7c:	79a2                	ld	s3,40(sp)
    80001b7e:	7a02                	ld	s4,32(sp)
    80001b80:	6ae2                	ld	s5,24(sp)
    80001b82:	6b42                	ld	s6,16(sp)
    80001b84:	6ba2                	ld	s7,8(sp)
    80001b86:	6161                	addi	sp,sp,80
    80001b88:	8082                	ret
    srcva = va0 + PGSIZE;
    80001b8a:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    80001b8e:	c8a9                	beqz	s1,80001be0 <copyinstr+0x9e>
    va0 = PGROUNDDOWN(srcva);
    80001b90:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    80001b94:	85ca                	mv	a1,s2
    80001b96:	8552                	mv	a0,s4
    80001b98:	00000097          	auipc	ra,0x0
    80001b9c:	8ca080e7          	jalr	-1846(ra) # 80001462 <walkaddr>
    if(pa0 == 0)
    80001ba0:	c131                	beqz	a0,80001be4 <copyinstr+0xa2>
    n = PGSIZE - (srcva - va0);
    80001ba2:	417906b3          	sub	a3,s2,s7
    80001ba6:	96ce                	add	a3,a3,s3
    80001ba8:	00d4f363          	bgeu	s1,a3,80001bae <copyinstr+0x6c>
    80001bac:	86a6                	mv	a3,s1
    char *p = (char *) (pa0 + (srcva - va0));
    80001bae:	955e                	add	a0,a0,s7
    80001bb0:	41250533          	sub	a0,a0,s2
    while(n > 0){
    80001bb4:	daf9                	beqz	a3,80001b8a <copyinstr+0x48>
    80001bb6:	87da                	mv	a5,s6
      if(*p == '\0'){
    80001bb8:	41650633          	sub	a2,a0,s6
    80001bbc:	fff48593          	addi	a1,s1,-1
    80001bc0:	95da                	add	a1,a1,s6
    while(n > 0){
    80001bc2:	96da                	add	a3,a3,s6
      if(*p == '\0'){
    80001bc4:	00f60733          	add	a4,a2,a5
    80001bc8:	00074703          	lbu	a4,0(a4)
    80001bcc:	df51                	beqz	a4,80001b68 <copyinstr+0x26>
        *dst = *p;
    80001bce:	00e78023          	sb	a4,0(a5)
      --max;
    80001bd2:	40f584b3          	sub	s1,a1,a5
      dst++;
    80001bd6:	0785                	addi	a5,a5,1
    while(n > 0){
    80001bd8:	fed796e3          	bne	a5,a3,80001bc4 <copyinstr+0x82>
      dst++;
    80001bdc:	8b3e                	mv	s6,a5
    80001bde:	b775                	j	80001b8a <copyinstr+0x48>
    80001be0:	4781                	li	a5,0
    80001be2:	b771                	j	80001b6e <copyinstr+0x2c>
      return -1;
    80001be4:	557d                	li	a0,-1
    80001be6:	b779                	j	80001b74 <copyinstr+0x32>
  int got_null = 0;
    80001be8:	4781                	li	a5,0
  if(got_null){
    80001bea:	37fd                	addiw	a5,a5,-1
    80001bec:	0007851b          	sext.w	a0,a5
}
    80001bf0:	8082                	ret

0000000080001bf2 <wakeup1>:

// Wake up p if it is sleeping in wait(); used by exit().
// Caller must hold p->lock.
static void
wakeup1(struct proc *p)
{
    80001bf2:	1101                	addi	sp,sp,-32
    80001bf4:	ec06                	sd	ra,24(sp)
    80001bf6:	e822                	sd	s0,16(sp)
    80001bf8:	e426                	sd	s1,8(sp)
    80001bfa:	1000                	addi	s0,sp,32
    80001bfc:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001bfe:	fffff097          	auipc	ra,0xfffff
    80001c02:	074080e7          	jalr	116(ra) # 80000c72 <holding>
    80001c06:	c909                	beqz	a0,80001c18 <wakeup1+0x26>
    panic("wakeup1");
  if(p->chan == p && p->state == SLEEPING) {
    80001c08:	789c                	ld	a5,48(s1)
    80001c0a:	00978f63          	beq	a5,s1,80001c28 <wakeup1+0x36>
    p->state = RUNNABLE;
  }
}
    80001c0e:	60e2                	ld	ra,24(sp)
    80001c10:	6442                	ld	s0,16(sp)
    80001c12:	64a2                	ld	s1,8(sp)
    80001c14:	6105                	addi	sp,sp,32
    80001c16:	8082                	ret
    panic("wakeup1");
    80001c18:	00006517          	auipc	a0,0x6
    80001c1c:	64050513          	addi	a0,a0,1600 # 80008258 <digits+0x218>
    80001c20:	fffff097          	auipc	ra,0xfffff
    80001c24:	92c080e7          	jalr	-1748(ra) # 8000054c <panic>
  if(p->chan == p && p->state == SLEEPING) {
    80001c28:	5098                	lw	a4,32(s1)
    80001c2a:	4785                	li	a5,1
    80001c2c:	fef711e3          	bne	a4,a5,80001c0e <wakeup1+0x1c>
    p->state = RUNNABLE;
    80001c30:	4789                	li	a5,2
    80001c32:	d09c                	sw	a5,32(s1)
}
    80001c34:	bfe9                	j	80001c0e <wakeup1+0x1c>

0000000080001c36 <procinit>:
{
    80001c36:	715d                	addi	sp,sp,-80
    80001c38:	e486                	sd	ra,72(sp)
    80001c3a:	e0a2                	sd	s0,64(sp)
    80001c3c:	fc26                	sd	s1,56(sp)
    80001c3e:	f84a                	sd	s2,48(sp)
    80001c40:	f44e                	sd	s3,40(sp)
    80001c42:	f052                	sd	s4,32(sp)
    80001c44:	ec56                	sd	s5,24(sp)
    80001c46:	e85a                	sd	s6,16(sp)
    80001c48:	e45e                	sd	s7,8(sp)
    80001c4a:	0880                	addi	s0,sp,80
  initlock(&pid_lock, "nextpid");
    80001c4c:	00006597          	auipc	a1,0x6
    80001c50:	61458593          	addi	a1,a1,1556 # 80008260 <digits+0x220>
    80001c54:	00010517          	auipc	a0,0x10
    80001c58:	73450513          	addi	a0,a0,1844 # 80012388 <pid_lock>
    80001c5c:	fffff097          	auipc	ra,0xfffff
    80001c60:	20c080e7          	jalr	524(ra) # 80000e68 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c64:	00011917          	auipc	s2,0x11
    80001c68:	b4490913          	addi	s2,s2,-1212 # 800127a8 <proc>
      initlock(&p->lock, "proc");
    80001c6c:	00006b97          	auipc	s7,0x6
    80001c70:	5fcb8b93          	addi	s7,s7,1532 # 80008268 <digits+0x228>
      uint64 va = KSTACK((int) (p - proc));
    80001c74:	8b4a                	mv	s6,s2
    80001c76:	00006a97          	auipc	s5,0x6
    80001c7a:	38aa8a93          	addi	s5,s5,906 # 80008000 <etext>
    80001c7e:	040009b7          	lui	s3,0x4000
    80001c82:	19fd                	addi	s3,s3,-1 # 3ffffff <_entry-0x7c000001>
    80001c84:	09b2                	slli	s3,s3,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c86:	00016a17          	auipc	s4,0x16
    80001c8a:	722a0a13          	addi	s4,s4,1826 # 800183a8 <tickslock>
      initlock(&p->lock, "proc");
    80001c8e:	85de                	mv	a1,s7
    80001c90:	854a                	mv	a0,s2
    80001c92:	fffff097          	auipc	ra,0xfffff
    80001c96:	1d6080e7          	jalr	470(ra) # 80000e68 <initlock>
      char *pa = kalloc();
    80001c9a:	fffff097          	auipc	ra,0xfffff
    80001c9e:	ece080e7          	jalr	-306(ra) # 80000b68 <kalloc>
    80001ca2:	85aa                	mv	a1,a0
      if(pa == 0)
    80001ca4:	c929                	beqz	a0,80001cf6 <procinit+0xc0>
      uint64 va = KSTACK((int) (p - proc));
    80001ca6:	416904b3          	sub	s1,s2,s6
    80001caa:	8491                	srai	s1,s1,0x4
    80001cac:	000ab783          	ld	a5,0(s5)
    80001cb0:	02f484b3          	mul	s1,s1,a5
    80001cb4:	2485                	addiw	s1,s1,1
    80001cb6:	00d4949b          	slliw	s1,s1,0xd
    80001cba:	409984b3          	sub	s1,s3,s1
      kvmmap(va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001cbe:	4699                	li	a3,6
    80001cc0:	6605                	lui	a2,0x1
    80001cc2:	8526                	mv	a0,s1
    80001cc4:	00000097          	auipc	ra,0x0
    80001cc8:	86e080e7          	jalr	-1938(ra) # 80001532 <kvmmap>
      p->kstack = va;
    80001ccc:	04993423          	sd	s1,72(s2)
  for(p = proc; p < &proc[NPROC]; p++) {
    80001cd0:	17090913          	addi	s2,s2,368
    80001cd4:	fb491de3          	bne	s2,s4,80001c8e <procinit+0x58>
  kvminithart();
    80001cd8:	fffff097          	auipc	ra,0xfffff
    80001cdc:	766080e7          	jalr	1894(ra) # 8000143e <kvminithart>
}
    80001ce0:	60a6                	ld	ra,72(sp)
    80001ce2:	6406                	ld	s0,64(sp)
    80001ce4:	74e2                	ld	s1,56(sp)
    80001ce6:	7942                	ld	s2,48(sp)
    80001ce8:	79a2                	ld	s3,40(sp)
    80001cea:	7a02                	ld	s4,32(sp)
    80001cec:	6ae2                	ld	s5,24(sp)
    80001cee:	6b42                	ld	s6,16(sp)
    80001cf0:	6ba2                	ld	s7,8(sp)
    80001cf2:	6161                	addi	sp,sp,80
    80001cf4:	8082                	ret
        panic("kalloc");
    80001cf6:	00006517          	auipc	a0,0x6
    80001cfa:	57a50513          	addi	a0,a0,1402 # 80008270 <digits+0x230>
    80001cfe:	fffff097          	auipc	ra,0xfffff
    80001d02:	84e080e7          	jalr	-1970(ra) # 8000054c <panic>

0000000080001d06 <cpuid>:
{
    80001d06:	1141                	addi	sp,sp,-16
    80001d08:	e422                	sd	s0,8(sp)
    80001d0a:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001d0c:	8512                	mv	a0,tp
}
    80001d0e:	2501                	sext.w	a0,a0
    80001d10:	6422                	ld	s0,8(sp)
    80001d12:	0141                	addi	sp,sp,16
    80001d14:	8082                	ret

0000000080001d16 <mycpu>:
mycpu(void) {
    80001d16:	1141                	addi	sp,sp,-16
    80001d18:	e422                	sd	s0,8(sp)
    80001d1a:	0800                	addi	s0,sp,16
    80001d1c:	8792                	mv	a5,tp
  struct cpu *c = &cpus[id];
    80001d1e:	2781                	sext.w	a5,a5
    80001d20:	079e                	slli	a5,a5,0x7
}
    80001d22:	00010517          	auipc	a0,0x10
    80001d26:	68650513          	addi	a0,a0,1670 # 800123a8 <cpus>
    80001d2a:	953e                	add	a0,a0,a5
    80001d2c:	6422                	ld	s0,8(sp)
    80001d2e:	0141                	addi	sp,sp,16
    80001d30:	8082                	ret

0000000080001d32 <myproc>:
myproc(void) {
    80001d32:	1101                	addi	sp,sp,-32
    80001d34:	ec06                	sd	ra,24(sp)
    80001d36:	e822                	sd	s0,16(sp)
    80001d38:	e426                	sd	s1,8(sp)
    80001d3a:	1000                	addi	s0,sp,32
  push_off();
    80001d3c:	fffff097          	auipc	ra,0xfffff
    80001d40:	f64080e7          	jalr	-156(ra) # 80000ca0 <push_off>
    80001d44:	8792                	mv	a5,tp
  struct proc *p = c->proc;
    80001d46:	2781                	sext.w	a5,a5
    80001d48:	079e                	slli	a5,a5,0x7
    80001d4a:	00010717          	auipc	a4,0x10
    80001d4e:	63e70713          	addi	a4,a4,1598 # 80012388 <pid_lock>
    80001d52:	97ba                	add	a5,a5,a4
    80001d54:	7384                	ld	s1,32(a5)
  pop_off();
    80001d56:	fffff097          	auipc	ra,0xfffff
    80001d5a:	006080e7          	jalr	6(ra) # 80000d5c <pop_off>
}
    80001d5e:	8526                	mv	a0,s1
    80001d60:	60e2                	ld	ra,24(sp)
    80001d62:	6442                	ld	s0,16(sp)
    80001d64:	64a2                	ld	s1,8(sp)
    80001d66:	6105                	addi	sp,sp,32
    80001d68:	8082                	ret

0000000080001d6a <forkret>:
{
    80001d6a:	1141                	addi	sp,sp,-16
    80001d6c:	e406                	sd	ra,8(sp)
    80001d6e:	e022                	sd	s0,0(sp)
    80001d70:	0800                	addi	s0,sp,16
  release(&myproc()->lock);
    80001d72:	00000097          	auipc	ra,0x0
    80001d76:	fc0080e7          	jalr	-64(ra) # 80001d32 <myproc>
    80001d7a:	fffff097          	auipc	ra,0xfffff
    80001d7e:	042080e7          	jalr	66(ra) # 80000dbc <release>
  if (first) {
    80001d82:	00007797          	auipc	a5,0x7
    80001d86:	b2e7a783          	lw	a5,-1234(a5) # 800088b0 <first.1>
    80001d8a:	eb89                	bnez	a5,80001d9c <forkret+0x32>
  usertrapret();
    80001d8c:	00001097          	auipc	ra,0x1
    80001d90:	c1e080e7          	jalr	-994(ra) # 800029aa <usertrapret>
}
    80001d94:	60a2                	ld	ra,8(sp)
    80001d96:	6402                	ld	s0,0(sp)
    80001d98:	0141                	addi	sp,sp,16
    80001d9a:	8082                	ret
    first = 0;
    80001d9c:	00007797          	auipc	a5,0x7
    80001da0:	b007aa23          	sw	zero,-1260(a5) # 800088b0 <first.1>
    fsinit(ROOTDEV);
    80001da4:	4505                	li	a0,1
    80001da6:	00002097          	auipc	ra,0x2
    80001daa:	af0080e7          	jalr	-1296(ra) # 80003896 <fsinit>
    80001dae:	bff9                	j	80001d8c <forkret+0x22>

0000000080001db0 <allocpid>:
allocpid() {
    80001db0:	1101                	addi	sp,sp,-32
    80001db2:	ec06                	sd	ra,24(sp)
    80001db4:	e822                	sd	s0,16(sp)
    80001db6:	e426                	sd	s1,8(sp)
    80001db8:	e04a                	sd	s2,0(sp)
    80001dba:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001dbc:	00010917          	auipc	s2,0x10
    80001dc0:	5cc90913          	addi	s2,s2,1484 # 80012388 <pid_lock>
    80001dc4:	854a                	mv	a0,s2
    80001dc6:	fffff097          	auipc	ra,0xfffff
    80001dca:	f26080e7          	jalr	-218(ra) # 80000cec <acquire>
  pid = nextpid;
    80001dce:	00007797          	auipc	a5,0x7
    80001dd2:	ae678793          	addi	a5,a5,-1306 # 800088b4 <nextpid>
    80001dd6:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001dd8:	0014871b          	addiw	a4,s1,1
    80001ddc:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001dde:	854a                	mv	a0,s2
    80001de0:	fffff097          	auipc	ra,0xfffff
    80001de4:	fdc080e7          	jalr	-36(ra) # 80000dbc <release>
}
    80001de8:	8526                	mv	a0,s1
    80001dea:	60e2                	ld	ra,24(sp)
    80001dec:	6442                	ld	s0,16(sp)
    80001dee:	64a2                	ld	s1,8(sp)
    80001df0:	6902                	ld	s2,0(sp)
    80001df2:	6105                	addi	sp,sp,32
    80001df4:	8082                	ret

0000000080001df6 <proc_pagetable>:
{
    80001df6:	1101                	addi	sp,sp,-32
    80001df8:	ec06                	sd	ra,24(sp)
    80001dfa:	e822                	sd	s0,16(sp)
    80001dfc:	e426                	sd	s1,8(sp)
    80001dfe:	e04a                	sd	s2,0(sp)
    80001e00:	1000                	addi	s0,sp,32
    80001e02:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001e04:	00000097          	auipc	ra,0x0
    80001e08:	8e8080e7          	jalr	-1816(ra) # 800016ec <uvmcreate>
    80001e0c:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001e0e:	c121                	beqz	a0,80001e4e <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001e10:	4729                	li	a4,10
    80001e12:	00005697          	auipc	a3,0x5
    80001e16:	1ee68693          	addi	a3,a3,494 # 80007000 <_trampoline>
    80001e1a:	6605                	lui	a2,0x1
    80001e1c:	040005b7          	lui	a1,0x4000
    80001e20:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001e22:	05b2                	slli	a1,a1,0xc
    80001e24:	fffff097          	auipc	ra,0xfffff
    80001e28:	680080e7          	jalr	1664(ra) # 800014a4 <mappages>
    80001e2c:	02054863          	bltz	a0,80001e5c <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001e30:	4719                	li	a4,6
    80001e32:	06093683          	ld	a3,96(s2)
    80001e36:	6605                	lui	a2,0x1
    80001e38:	020005b7          	lui	a1,0x2000
    80001e3c:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001e3e:	05b6                	slli	a1,a1,0xd
    80001e40:	8526                	mv	a0,s1
    80001e42:	fffff097          	auipc	ra,0xfffff
    80001e46:	662080e7          	jalr	1634(ra) # 800014a4 <mappages>
    80001e4a:	02054163          	bltz	a0,80001e6c <proc_pagetable+0x76>
}
    80001e4e:	8526                	mv	a0,s1
    80001e50:	60e2                	ld	ra,24(sp)
    80001e52:	6442                	ld	s0,16(sp)
    80001e54:	64a2                	ld	s1,8(sp)
    80001e56:	6902                	ld	s2,0(sp)
    80001e58:	6105                	addi	sp,sp,32
    80001e5a:	8082                	ret
    uvmfree(pagetable, 0);
    80001e5c:	4581                	li	a1,0
    80001e5e:	8526                	mv	a0,s1
    80001e60:	00000097          	auipc	ra,0x0
    80001e64:	a8a080e7          	jalr	-1398(ra) # 800018ea <uvmfree>
    return 0;
    80001e68:	4481                	li	s1,0
    80001e6a:	b7d5                	j	80001e4e <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001e6c:	4681                	li	a3,0
    80001e6e:	4605                	li	a2,1
    80001e70:	040005b7          	lui	a1,0x4000
    80001e74:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001e76:	05b2                	slli	a1,a1,0xc
    80001e78:	8526                	mv	a0,s1
    80001e7a:	fffff097          	auipc	ra,0xfffff
    80001e7e:	7ae080e7          	jalr	1966(ra) # 80001628 <uvmunmap>
    uvmfree(pagetable, 0);
    80001e82:	4581                	li	a1,0
    80001e84:	8526                	mv	a0,s1
    80001e86:	00000097          	auipc	ra,0x0
    80001e8a:	a64080e7          	jalr	-1436(ra) # 800018ea <uvmfree>
    return 0;
    80001e8e:	4481                	li	s1,0
    80001e90:	bf7d                	j	80001e4e <proc_pagetable+0x58>

0000000080001e92 <proc_freepagetable>:
{
    80001e92:	1101                	addi	sp,sp,-32
    80001e94:	ec06                	sd	ra,24(sp)
    80001e96:	e822                	sd	s0,16(sp)
    80001e98:	e426                	sd	s1,8(sp)
    80001e9a:	e04a                	sd	s2,0(sp)
    80001e9c:	1000                	addi	s0,sp,32
    80001e9e:	84aa                	mv	s1,a0
    80001ea0:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001ea2:	4681                	li	a3,0
    80001ea4:	4605                	li	a2,1
    80001ea6:	040005b7          	lui	a1,0x4000
    80001eaa:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001eac:	05b2                	slli	a1,a1,0xc
    80001eae:	fffff097          	auipc	ra,0xfffff
    80001eb2:	77a080e7          	jalr	1914(ra) # 80001628 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001eb6:	4681                	li	a3,0
    80001eb8:	4605                	li	a2,1
    80001eba:	020005b7          	lui	a1,0x2000
    80001ebe:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001ec0:	05b6                	slli	a1,a1,0xd
    80001ec2:	8526                	mv	a0,s1
    80001ec4:	fffff097          	auipc	ra,0xfffff
    80001ec8:	764080e7          	jalr	1892(ra) # 80001628 <uvmunmap>
  uvmfree(pagetable, sz);
    80001ecc:	85ca                	mv	a1,s2
    80001ece:	8526                	mv	a0,s1
    80001ed0:	00000097          	auipc	ra,0x0
    80001ed4:	a1a080e7          	jalr	-1510(ra) # 800018ea <uvmfree>
}
    80001ed8:	60e2                	ld	ra,24(sp)
    80001eda:	6442                	ld	s0,16(sp)
    80001edc:	64a2                	ld	s1,8(sp)
    80001ede:	6902                	ld	s2,0(sp)
    80001ee0:	6105                	addi	sp,sp,32
    80001ee2:	8082                	ret

0000000080001ee4 <freeproc>:
{
    80001ee4:	1101                	addi	sp,sp,-32
    80001ee6:	ec06                	sd	ra,24(sp)
    80001ee8:	e822                	sd	s0,16(sp)
    80001eea:	e426                	sd	s1,8(sp)
    80001eec:	1000                	addi	s0,sp,32
    80001eee:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001ef0:	7128                	ld	a0,96(a0)
    80001ef2:	c509                	beqz	a0,80001efc <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001ef4:	fffff097          	auipc	ra,0xfffff
    80001ef8:	b24080e7          	jalr	-1244(ra) # 80000a18 <kfree>
  p->trapframe = 0;
    80001efc:	0604b023          	sd	zero,96(s1)
  if(p->pagetable)
    80001f00:	6ca8                	ld	a0,88(s1)
    80001f02:	c511                	beqz	a0,80001f0e <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001f04:	68ac                	ld	a1,80(s1)
    80001f06:	00000097          	auipc	ra,0x0
    80001f0a:	f8c080e7          	jalr	-116(ra) # 80001e92 <proc_freepagetable>
  p->pagetable = 0;
    80001f0e:	0404bc23          	sd	zero,88(s1)
  p->sz = 0;
    80001f12:	0404b823          	sd	zero,80(s1)
  p->pid = 0;
    80001f16:	0404a023          	sw	zero,64(s1)
  p->parent = 0;
    80001f1a:	0204b423          	sd	zero,40(s1)
  p->name[0] = 0;
    80001f1e:	16048023          	sb	zero,352(s1)
  p->chan = 0;
    80001f22:	0204b823          	sd	zero,48(s1)
  p->killed = 0;
    80001f26:	0204ac23          	sw	zero,56(s1)
  p->xstate = 0;
    80001f2a:	0204ae23          	sw	zero,60(s1)
  p->state = UNUSED;
    80001f2e:	0204a023          	sw	zero,32(s1)
}
    80001f32:	60e2                	ld	ra,24(sp)
    80001f34:	6442                	ld	s0,16(sp)
    80001f36:	64a2                	ld	s1,8(sp)
    80001f38:	6105                	addi	sp,sp,32
    80001f3a:	8082                	ret

0000000080001f3c <allocproc>:
{
    80001f3c:	1101                	addi	sp,sp,-32
    80001f3e:	ec06                	sd	ra,24(sp)
    80001f40:	e822                	sd	s0,16(sp)
    80001f42:	e426                	sd	s1,8(sp)
    80001f44:	e04a                	sd	s2,0(sp)
    80001f46:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001f48:	00011497          	auipc	s1,0x11
    80001f4c:	86048493          	addi	s1,s1,-1952 # 800127a8 <proc>
    80001f50:	00016917          	auipc	s2,0x16
    80001f54:	45890913          	addi	s2,s2,1112 # 800183a8 <tickslock>
    acquire(&p->lock);
    80001f58:	8526                	mv	a0,s1
    80001f5a:	fffff097          	auipc	ra,0xfffff
    80001f5e:	d92080e7          	jalr	-622(ra) # 80000cec <acquire>
    if(p->state == UNUSED) {
    80001f62:	509c                	lw	a5,32(s1)
    80001f64:	cf81                	beqz	a5,80001f7c <allocproc+0x40>
      release(&p->lock);
    80001f66:	8526                	mv	a0,s1
    80001f68:	fffff097          	auipc	ra,0xfffff
    80001f6c:	e54080e7          	jalr	-428(ra) # 80000dbc <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001f70:	17048493          	addi	s1,s1,368
    80001f74:	ff2492e3          	bne	s1,s2,80001f58 <allocproc+0x1c>
  return 0;
    80001f78:	4481                	li	s1,0
    80001f7a:	a0b9                	j	80001fc8 <allocproc+0x8c>
  p->pid = allocpid();
    80001f7c:	00000097          	auipc	ra,0x0
    80001f80:	e34080e7          	jalr	-460(ra) # 80001db0 <allocpid>
    80001f84:	c0a8                	sw	a0,64(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001f86:	fffff097          	auipc	ra,0xfffff
    80001f8a:	be2080e7          	jalr	-1054(ra) # 80000b68 <kalloc>
    80001f8e:	892a                	mv	s2,a0
    80001f90:	f0a8                	sd	a0,96(s1)
    80001f92:	c131                	beqz	a0,80001fd6 <allocproc+0x9a>
  p->pagetable = proc_pagetable(p);
    80001f94:	8526                	mv	a0,s1
    80001f96:	00000097          	auipc	ra,0x0
    80001f9a:	e60080e7          	jalr	-416(ra) # 80001df6 <proc_pagetable>
    80001f9e:	892a                	mv	s2,a0
    80001fa0:	eca8                	sd	a0,88(s1)
  if(p->pagetable == 0){
    80001fa2:	c129                	beqz	a0,80001fe4 <allocproc+0xa8>
  memset(&p->context, 0, sizeof(p->context));
    80001fa4:	07000613          	li	a2,112
    80001fa8:	4581                	li	a1,0
    80001faa:	06848513          	addi	a0,s1,104
    80001fae:	fffff097          	auipc	ra,0xfffff
    80001fb2:	11e080e7          	jalr	286(ra) # 800010cc <memset>
  p->context.ra = (uint64)forkret;
    80001fb6:	00000797          	auipc	a5,0x0
    80001fba:	db478793          	addi	a5,a5,-588 # 80001d6a <forkret>
    80001fbe:	f4bc                	sd	a5,104(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001fc0:	64bc                	ld	a5,72(s1)
    80001fc2:	6705                	lui	a4,0x1
    80001fc4:	97ba                	add	a5,a5,a4
    80001fc6:	f8bc                	sd	a5,112(s1)
}
    80001fc8:	8526                	mv	a0,s1
    80001fca:	60e2                	ld	ra,24(sp)
    80001fcc:	6442                	ld	s0,16(sp)
    80001fce:	64a2                	ld	s1,8(sp)
    80001fd0:	6902                	ld	s2,0(sp)
    80001fd2:	6105                	addi	sp,sp,32
    80001fd4:	8082                	ret
    release(&p->lock);
    80001fd6:	8526                	mv	a0,s1
    80001fd8:	fffff097          	auipc	ra,0xfffff
    80001fdc:	de4080e7          	jalr	-540(ra) # 80000dbc <release>
    return 0;
    80001fe0:	84ca                	mv	s1,s2
    80001fe2:	b7dd                	j	80001fc8 <allocproc+0x8c>
    freeproc(p);
    80001fe4:	8526                	mv	a0,s1
    80001fe6:	00000097          	auipc	ra,0x0
    80001fea:	efe080e7          	jalr	-258(ra) # 80001ee4 <freeproc>
    release(&p->lock);
    80001fee:	8526                	mv	a0,s1
    80001ff0:	fffff097          	auipc	ra,0xfffff
    80001ff4:	dcc080e7          	jalr	-564(ra) # 80000dbc <release>
    return 0;
    80001ff8:	84ca                	mv	s1,s2
    80001ffa:	b7f9                	j	80001fc8 <allocproc+0x8c>

0000000080001ffc <userinit>:
{
    80001ffc:	1101                	addi	sp,sp,-32
    80001ffe:	ec06                	sd	ra,24(sp)
    80002000:	e822                	sd	s0,16(sp)
    80002002:	e426                	sd	s1,8(sp)
    80002004:	1000                	addi	s0,sp,32
  p = allocproc();
    80002006:	00000097          	auipc	ra,0x0
    8000200a:	f36080e7          	jalr	-202(ra) # 80001f3c <allocproc>
    8000200e:	84aa                	mv	s1,a0
  initproc = p;
    80002010:	00007797          	auipc	a5,0x7
    80002014:	00a7b423          	sd	a0,8(a5) # 80009018 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80002018:	03400613          	li	a2,52
    8000201c:	00007597          	auipc	a1,0x7
    80002020:	8a458593          	addi	a1,a1,-1884 # 800088c0 <initcode>
    80002024:	6d28                	ld	a0,88(a0)
    80002026:	fffff097          	auipc	ra,0xfffff
    8000202a:	6f4080e7          	jalr	1780(ra) # 8000171a <uvminit>
  p->sz = PGSIZE;
    8000202e:	6785                	lui	a5,0x1
    80002030:	e8bc                	sd	a5,80(s1)
  p->trapframe->epc = 0;      // user program counter
    80002032:	70b8                	ld	a4,96(s1)
    80002034:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80002038:	70b8                	ld	a4,96(s1)
    8000203a:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    8000203c:	4641                	li	a2,16
    8000203e:	00006597          	auipc	a1,0x6
    80002042:	23a58593          	addi	a1,a1,570 # 80008278 <digits+0x238>
    80002046:	16048513          	addi	a0,s1,352
    8000204a:	fffff097          	auipc	ra,0xfffff
    8000204e:	1d4080e7          	jalr	468(ra) # 8000121e <safestrcpy>
  p->cwd = namei("/");
    80002052:	00006517          	auipc	a0,0x6
    80002056:	23650513          	addi	a0,a0,566 # 80008288 <digits+0x248>
    8000205a:	00002097          	auipc	ra,0x2
    8000205e:	270080e7          	jalr	624(ra) # 800042ca <namei>
    80002062:	14a4bc23          	sd	a0,344(s1)
  p->state = RUNNABLE;
    80002066:	4789                	li	a5,2
    80002068:	d09c                	sw	a5,32(s1)
  release(&p->lock);
    8000206a:	8526                	mv	a0,s1
    8000206c:	fffff097          	auipc	ra,0xfffff
    80002070:	d50080e7          	jalr	-688(ra) # 80000dbc <release>
}
    80002074:	60e2                	ld	ra,24(sp)
    80002076:	6442                	ld	s0,16(sp)
    80002078:	64a2                	ld	s1,8(sp)
    8000207a:	6105                	addi	sp,sp,32
    8000207c:	8082                	ret

000000008000207e <growproc>:
{
    8000207e:	1101                	addi	sp,sp,-32
    80002080:	ec06                	sd	ra,24(sp)
    80002082:	e822                	sd	s0,16(sp)
    80002084:	e426                	sd	s1,8(sp)
    80002086:	e04a                	sd	s2,0(sp)
    80002088:	1000                	addi	s0,sp,32
    8000208a:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    8000208c:	00000097          	auipc	ra,0x0
    80002090:	ca6080e7          	jalr	-858(ra) # 80001d32 <myproc>
    80002094:	892a                	mv	s2,a0
  sz = p->sz;
    80002096:	692c                	ld	a1,80(a0)
    80002098:	0005879b          	sext.w	a5,a1
  if(n > 0){
    8000209c:	00904f63          	bgtz	s1,800020ba <growproc+0x3c>
  } else if(n < 0){
    800020a0:	0204cd63          	bltz	s1,800020da <growproc+0x5c>
  p->sz = sz;
    800020a4:	1782                	slli	a5,a5,0x20
    800020a6:	9381                	srli	a5,a5,0x20
    800020a8:	04f93823          	sd	a5,80(s2)
  return 0;
    800020ac:	4501                	li	a0,0
}
    800020ae:	60e2                	ld	ra,24(sp)
    800020b0:	6442                	ld	s0,16(sp)
    800020b2:	64a2                	ld	s1,8(sp)
    800020b4:	6902                	ld	s2,0(sp)
    800020b6:	6105                	addi	sp,sp,32
    800020b8:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    800020ba:	00f4863b          	addw	a2,s1,a5
    800020be:	1602                	slli	a2,a2,0x20
    800020c0:	9201                	srli	a2,a2,0x20
    800020c2:	1582                	slli	a1,a1,0x20
    800020c4:	9181                	srli	a1,a1,0x20
    800020c6:	6d28                	ld	a0,88(a0)
    800020c8:	fffff097          	auipc	ra,0xfffff
    800020cc:	70c080e7          	jalr	1804(ra) # 800017d4 <uvmalloc>
    800020d0:	0005079b          	sext.w	a5,a0
    800020d4:	fbe1                	bnez	a5,800020a4 <growproc+0x26>
      return -1;
    800020d6:	557d                	li	a0,-1
    800020d8:	bfd9                	j	800020ae <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    800020da:	00f4863b          	addw	a2,s1,a5
    800020de:	1602                	slli	a2,a2,0x20
    800020e0:	9201                	srli	a2,a2,0x20
    800020e2:	1582                	slli	a1,a1,0x20
    800020e4:	9181                	srli	a1,a1,0x20
    800020e6:	6d28                	ld	a0,88(a0)
    800020e8:	fffff097          	auipc	ra,0xfffff
    800020ec:	6a4080e7          	jalr	1700(ra) # 8000178c <uvmdealloc>
    800020f0:	0005079b          	sext.w	a5,a0
    800020f4:	bf45                	j	800020a4 <growproc+0x26>

00000000800020f6 <fork>:
{
    800020f6:	7139                	addi	sp,sp,-64
    800020f8:	fc06                	sd	ra,56(sp)
    800020fa:	f822                	sd	s0,48(sp)
    800020fc:	f426                	sd	s1,40(sp)
    800020fe:	f04a                	sd	s2,32(sp)
    80002100:	ec4e                	sd	s3,24(sp)
    80002102:	e852                	sd	s4,16(sp)
    80002104:	e456                	sd	s5,8(sp)
    80002106:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80002108:	00000097          	auipc	ra,0x0
    8000210c:	c2a080e7          	jalr	-982(ra) # 80001d32 <myproc>
    80002110:	8aaa                	mv	s5,a0
  if((np = allocproc()) == 0){
    80002112:	00000097          	auipc	ra,0x0
    80002116:	e2a080e7          	jalr	-470(ra) # 80001f3c <allocproc>
    8000211a:	c17d                	beqz	a0,80002200 <fork+0x10a>
    8000211c:	8a2a                	mv	s4,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    8000211e:	050ab603          	ld	a2,80(s5)
    80002122:	6d2c                	ld	a1,88(a0)
    80002124:	058ab503          	ld	a0,88(s5)
    80002128:	fffff097          	auipc	ra,0xfffff
    8000212c:	7fc080e7          	jalr	2044(ra) # 80001924 <uvmcopy>
    80002130:	04054a63          	bltz	a0,80002184 <fork+0x8e>
  np->sz = p->sz;
    80002134:	050ab783          	ld	a5,80(s5)
    80002138:	04fa3823          	sd	a5,80(s4)
  np->parent = p;
    8000213c:	035a3423          	sd	s5,40(s4)
  *(np->trapframe) = *(p->trapframe);
    80002140:	060ab683          	ld	a3,96(s5)
    80002144:	87b6                	mv	a5,a3
    80002146:	060a3703          	ld	a4,96(s4)
    8000214a:	12068693          	addi	a3,a3,288
    8000214e:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80002152:	6788                	ld	a0,8(a5)
    80002154:	6b8c                	ld	a1,16(a5)
    80002156:	6f90                	ld	a2,24(a5)
    80002158:	01073023          	sd	a6,0(a4)
    8000215c:	e708                	sd	a0,8(a4)
    8000215e:	eb0c                	sd	a1,16(a4)
    80002160:	ef10                	sd	a2,24(a4)
    80002162:	02078793          	addi	a5,a5,32
    80002166:	02070713          	addi	a4,a4,32
    8000216a:	fed792e3          	bne	a5,a3,8000214e <fork+0x58>
  np->trapframe->a0 = 0;
    8000216e:	060a3783          	ld	a5,96(s4)
    80002172:	0607b823          	sd	zero,112(a5)
  for(i = 0; i < NOFILE; i++)
    80002176:	0d8a8493          	addi	s1,s5,216
    8000217a:	0d8a0913          	addi	s2,s4,216
    8000217e:	158a8993          	addi	s3,s5,344
    80002182:	a00d                	j	800021a4 <fork+0xae>
    freeproc(np);
    80002184:	8552                	mv	a0,s4
    80002186:	00000097          	auipc	ra,0x0
    8000218a:	d5e080e7          	jalr	-674(ra) # 80001ee4 <freeproc>
    release(&np->lock);
    8000218e:	8552                	mv	a0,s4
    80002190:	fffff097          	auipc	ra,0xfffff
    80002194:	c2c080e7          	jalr	-980(ra) # 80000dbc <release>
    return -1;
    80002198:	54fd                	li	s1,-1
    8000219a:	a889                	j	800021ec <fork+0xf6>
  for(i = 0; i < NOFILE; i++)
    8000219c:	04a1                	addi	s1,s1,8
    8000219e:	0921                	addi	s2,s2,8
    800021a0:	01348b63          	beq	s1,s3,800021b6 <fork+0xc0>
    if(p->ofile[i])
    800021a4:	6088                	ld	a0,0(s1)
    800021a6:	d97d                	beqz	a0,8000219c <fork+0xa6>
      np->ofile[i] = filedup(p->ofile[i]);
    800021a8:	00002097          	auipc	ra,0x2
    800021ac:	7c0080e7          	jalr	1984(ra) # 80004968 <filedup>
    800021b0:	00a93023          	sd	a0,0(s2)
    800021b4:	b7e5                	j	8000219c <fork+0xa6>
  np->cwd = idup(p->cwd);
    800021b6:	158ab503          	ld	a0,344(s5)
    800021ba:	00002097          	auipc	ra,0x2
    800021be:	918080e7          	jalr	-1768(ra) # 80003ad2 <idup>
    800021c2:	14aa3c23          	sd	a0,344(s4)
  safestrcpy(np->name, p->name, sizeof(p->name));
    800021c6:	4641                	li	a2,16
    800021c8:	160a8593          	addi	a1,s5,352
    800021cc:	160a0513          	addi	a0,s4,352
    800021d0:	fffff097          	auipc	ra,0xfffff
    800021d4:	04e080e7          	jalr	78(ra) # 8000121e <safestrcpy>
  pid = np->pid;
    800021d8:	040a2483          	lw	s1,64(s4)
  np->state = RUNNABLE;
    800021dc:	4789                	li	a5,2
    800021de:	02fa2023          	sw	a5,32(s4)
  release(&np->lock);
    800021e2:	8552                	mv	a0,s4
    800021e4:	fffff097          	auipc	ra,0xfffff
    800021e8:	bd8080e7          	jalr	-1064(ra) # 80000dbc <release>
}
    800021ec:	8526                	mv	a0,s1
    800021ee:	70e2                	ld	ra,56(sp)
    800021f0:	7442                	ld	s0,48(sp)
    800021f2:	74a2                	ld	s1,40(sp)
    800021f4:	7902                	ld	s2,32(sp)
    800021f6:	69e2                	ld	s3,24(sp)
    800021f8:	6a42                	ld	s4,16(sp)
    800021fa:	6aa2                	ld	s5,8(sp)
    800021fc:	6121                	addi	sp,sp,64
    800021fe:	8082                	ret
    return -1;
    80002200:	54fd                	li	s1,-1
    80002202:	b7ed                	j	800021ec <fork+0xf6>

0000000080002204 <reparent>:
{
    80002204:	7179                	addi	sp,sp,-48
    80002206:	f406                	sd	ra,40(sp)
    80002208:	f022                	sd	s0,32(sp)
    8000220a:	ec26                	sd	s1,24(sp)
    8000220c:	e84a                	sd	s2,16(sp)
    8000220e:	e44e                	sd	s3,8(sp)
    80002210:	e052                	sd	s4,0(sp)
    80002212:	1800                	addi	s0,sp,48
    80002214:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002216:	00010497          	auipc	s1,0x10
    8000221a:	59248493          	addi	s1,s1,1426 # 800127a8 <proc>
      pp->parent = initproc;
    8000221e:	00007a17          	auipc	s4,0x7
    80002222:	dfaa0a13          	addi	s4,s4,-518 # 80009018 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002226:	00016997          	auipc	s3,0x16
    8000222a:	18298993          	addi	s3,s3,386 # 800183a8 <tickslock>
    8000222e:	a029                	j	80002238 <reparent+0x34>
    80002230:	17048493          	addi	s1,s1,368
    80002234:	03348363          	beq	s1,s3,8000225a <reparent+0x56>
    if(pp->parent == p){
    80002238:	749c                	ld	a5,40(s1)
    8000223a:	ff279be3          	bne	a5,s2,80002230 <reparent+0x2c>
      acquire(&pp->lock);
    8000223e:	8526                	mv	a0,s1
    80002240:	fffff097          	auipc	ra,0xfffff
    80002244:	aac080e7          	jalr	-1364(ra) # 80000cec <acquire>
      pp->parent = initproc;
    80002248:	000a3783          	ld	a5,0(s4)
    8000224c:	f49c                	sd	a5,40(s1)
      release(&pp->lock);
    8000224e:	8526                	mv	a0,s1
    80002250:	fffff097          	auipc	ra,0xfffff
    80002254:	b6c080e7          	jalr	-1172(ra) # 80000dbc <release>
    80002258:	bfe1                	j	80002230 <reparent+0x2c>
}
    8000225a:	70a2                	ld	ra,40(sp)
    8000225c:	7402                	ld	s0,32(sp)
    8000225e:	64e2                	ld	s1,24(sp)
    80002260:	6942                	ld	s2,16(sp)
    80002262:	69a2                	ld	s3,8(sp)
    80002264:	6a02                	ld	s4,0(sp)
    80002266:	6145                	addi	sp,sp,48
    80002268:	8082                	ret

000000008000226a <scheduler>:
{
    8000226a:	711d                	addi	sp,sp,-96
    8000226c:	ec86                	sd	ra,88(sp)
    8000226e:	e8a2                	sd	s0,80(sp)
    80002270:	e4a6                	sd	s1,72(sp)
    80002272:	e0ca                	sd	s2,64(sp)
    80002274:	fc4e                	sd	s3,56(sp)
    80002276:	f852                	sd	s4,48(sp)
    80002278:	f456                	sd	s5,40(sp)
    8000227a:	f05a                	sd	s6,32(sp)
    8000227c:	ec5e                	sd	s7,24(sp)
    8000227e:	e862                	sd	s8,16(sp)
    80002280:	e466                	sd	s9,8(sp)
    80002282:	1080                	addi	s0,sp,96
    80002284:	8792                	mv	a5,tp
  int id = r_tp();
    80002286:	2781                	sext.w	a5,a5
  c->proc = 0;
    80002288:	00779c13          	slli	s8,a5,0x7
    8000228c:	00010717          	auipc	a4,0x10
    80002290:	0fc70713          	addi	a4,a4,252 # 80012388 <pid_lock>
    80002294:	9762                	add	a4,a4,s8
    80002296:	02073023          	sd	zero,32(a4)
        swtch(&c->context, &p->context);
    8000229a:	00010717          	auipc	a4,0x10
    8000229e:	11670713          	addi	a4,a4,278 # 800123b0 <cpus+0x8>
    800022a2:	9c3a                	add	s8,s8,a4
    int nproc = 0;
    800022a4:	4c81                	li	s9,0
      if(p->state == RUNNABLE) {
    800022a6:	4a89                	li	s5,2
        c->proc = p;
    800022a8:	079e                	slli	a5,a5,0x7
    800022aa:	00010b17          	auipc	s6,0x10
    800022ae:	0deb0b13          	addi	s6,s6,222 # 80012388 <pid_lock>
    800022b2:	9b3e                	add	s6,s6,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    800022b4:	00016a17          	auipc	s4,0x16
    800022b8:	0f4a0a13          	addi	s4,s4,244 # 800183a8 <tickslock>
    800022bc:	a8a1                	j	80002314 <scheduler+0xaa>
      release(&p->lock);
    800022be:	8526                	mv	a0,s1
    800022c0:	fffff097          	auipc	ra,0xfffff
    800022c4:	afc080e7          	jalr	-1284(ra) # 80000dbc <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    800022c8:	17048493          	addi	s1,s1,368
    800022cc:	03448a63          	beq	s1,s4,80002300 <scheduler+0x96>
      acquire(&p->lock);
    800022d0:	8526                	mv	a0,s1
    800022d2:	fffff097          	auipc	ra,0xfffff
    800022d6:	a1a080e7          	jalr	-1510(ra) # 80000cec <acquire>
      if(p->state != UNUSED) {
    800022da:	509c                	lw	a5,32(s1)
    800022dc:	d3ed                	beqz	a5,800022be <scheduler+0x54>
        nproc++;
    800022de:	2985                	addiw	s3,s3,1
      if(p->state == RUNNABLE) {
    800022e0:	fd579fe3          	bne	a5,s5,800022be <scheduler+0x54>
        p->state = RUNNING;
    800022e4:	0374a023          	sw	s7,32(s1)
        c->proc = p;
    800022e8:	029b3023          	sd	s1,32(s6)
        swtch(&c->context, &p->context);
    800022ec:	06848593          	addi	a1,s1,104
    800022f0:	8562                	mv	a0,s8
    800022f2:	00000097          	auipc	ra,0x0
    800022f6:	60e080e7          	jalr	1550(ra) # 80002900 <swtch>
        c->proc = 0;
    800022fa:	020b3023          	sd	zero,32(s6)
    800022fe:	b7c1                	j	800022be <scheduler+0x54>
    if(nproc <= 2) {   // only init and sh exist
    80002300:	013aca63          	blt	s5,s3,80002314 <scheduler+0xaa>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002304:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002308:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000230c:	10079073          	csrw	sstatus,a5
      asm volatile("wfi");
    80002310:	10500073          	wfi
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002314:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002318:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000231c:	10079073          	csrw	sstatus,a5
    int nproc = 0;
    80002320:	89e6                	mv	s3,s9
    for(p = proc; p < &proc[NPROC]; p++) {
    80002322:	00010497          	auipc	s1,0x10
    80002326:	48648493          	addi	s1,s1,1158 # 800127a8 <proc>
        p->state = RUNNING;
    8000232a:	4b8d                	li	s7,3
    8000232c:	b755                	j	800022d0 <scheduler+0x66>

000000008000232e <sched>:
{
    8000232e:	7179                	addi	sp,sp,-48
    80002330:	f406                	sd	ra,40(sp)
    80002332:	f022                	sd	s0,32(sp)
    80002334:	ec26                	sd	s1,24(sp)
    80002336:	e84a                	sd	s2,16(sp)
    80002338:	e44e                	sd	s3,8(sp)
    8000233a:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    8000233c:	00000097          	auipc	ra,0x0
    80002340:	9f6080e7          	jalr	-1546(ra) # 80001d32 <myproc>
    80002344:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80002346:	fffff097          	auipc	ra,0xfffff
    8000234a:	92c080e7          	jalr	-1748(ra) # 80000c72 <holding>
    8000234e:	c93d                	beqz	a0,800023c4 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002350:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80002352:	2781                	sext.w	a5,a5
    80002354:	079e                	slli	a5,a5,0x7
    80002356:	00010717          	auipc	a4,0x10
    8000235a:	03270713          	addi	a4,a4,50 # 80012388 <pid_lock>
    8000235e:	97ba                	add	a5,a5,a4
    80002360:	0987a703          	lw	a4,152(a5)
    80002364:	4785                	li	a5,1
    80002366:	06f71763          	bne	a4,a5,800023d4 <sched+0xa6>
  if(p->state == RUNNING)
    8000236a:	5098                	lw	a4,32(s1)
    8000236c:	478d                	li	a5,3
    8000236e:	06f70b63          	beq	a4,a5,800023e4 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002372:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002376:	8b89                	andi	a5,a5,2
  if(intr_get())
    80002378:	efb5                	bnez	a5,800023f4 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    8000237a:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    8000237c:	00010917          	auipc	s2,0x10
    80002380:	00c90913          	addi	s2,s2,12 # 80012388 <pid_lock>
    80002384:	2781                	sext.w	a5,a5
    80002386:	079e                	slli	a5,a5,0x7
    80002388:	97ca                	add	a5,a5,s2
    8000238a:	09c7a983          	lw	s3,156(a5)
    8000238e:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80002390:	2781                	sext.w	a5,a5
    80002392:	079e                	slli	a5,a5,0x7
    80002394:	00010597          	auipc	a1,0x10
    80002398:	01c58593          	addi	a1,a1,28 # 800123b0 <cpus+0x8>
    8000239c:	95be                	add	a1,a1,a5
    8000239e:	06848513          	addi	a0,s1,104
    800023a2:	00000097          	auipc	ra,0x0
    800023a6:	55e080e7          	jalr	1374(ra) # 80002900 <swtch>
    800023aa:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    800023ac:	2781                	sext.w	a5,a5
    800023ae:	079e                	slli	a5,a5,0x7
    800023b0:	993e                	add	s2,s2,a5
    800023b2:	09392e23          	sw	s3,156(s2)
}
    800023b6:	70a2                	ld	ra,40(sp)
    800023b8:	7402                	ld	s0,32(sp)
    800023ba:	64e2                	ld	s1,24(sp)
    800023bc:	6942                	ld	s2,16(sp)
    800023be:	69a2                	ld	s3,8(sp)
    800023c0:	6145                	addi	sp,sp,48
    800023c2:	8082                	ret
    panic("sched p->lock");
    800023c4:	00006517          	auipc	a0,0x6
    800023c8:	ecc50513          	addi	a0,a0,-308 # 80008290 <digits+0x250>
    800023cc:	ffffe097          	auipc	ra,0xffffe
    800023d0:	180080e7          	jalr	384(ra) # 8000054c <panic>
    panic("sched locks");
    800023d4:	00006517          	auipc	a0,0x6
    800023d8:	ecc50513          	addi	a0,a0,-308 # 800082a0 <digits+0x260>
    800023dc:	ffffe097          	auipc	ra,0xffffe
    800023e0:	170080e7          	jalr	368(ra) # 8000054c <panic>
    panic("sched running");
    800023e4:	00006517          	auipc	a0,0x6
    800023e8:	ecc50513          	addi	a0,a0,-308 # 800082b0 <digits+0x270>
    800023ec:	ffffe097          	auipc	ra,0xffffe
    800023f0:	160080e7          	jalr	352(ra) # 8000054c <panic>
    panic("sched interruptible");
    800023f4:	00006517          	auipc	a0,0x6
    800023f8:	ecc50513          	addi	a0,a0,-308 # 800082c0 <digits+0x280>
    800023fc:	ffffe097          	auipc	ra,0xffffe
    80002400:	150080e7          	jalr	336(ra) # 8000054c <panic>

0000000080002404 <exit>:
{
    80002404:	7179                	addi	sp,sp,-48
    80002406:	f406                	sd	ra,40(sp)
    80002408:	f022                	sd	s0,32(sp)
    8000240a:	ec26                	sd	s1,24(sp)
    8000240c:	e84a                	sd	s2,16(sp)
    8000240e:	e44e                	sd	s3,8(sp)
    80002410:	e052                	sd	s4,0(sp)
    80002412:	1800                	addi	s0,sp,48
    80002414:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002416:	00000097          	auipc	ra,0x0
    8000241a:	91c080e7          	jalr	-1764(ra) # 80001d32 <myproc>
    8000241e:	89aa                	mv	s3,a0
  if(p == initproc)
    80002420:	00007797          	auipc	a5,0x7
    80002424:	bf87b783          	ld	a5,-1032(a5) # 80009018 <initproc>
    80002428:	0d850493          	addi	s1,a0,216
    8000242c:	15850913          	addi	s2,a0,344
    80002430:	02a79363          	bne	a5,a0,80002456 <exit+0x52>
    panic("init exiting");
    80002434:	00006517          	auipc	a0,0x6
    80002438:	ea450513          	addi	a0,a0,-348 # 800082d8 <digits+0x298>
    8000243c:	ffffe097          	auipc	ra,0xffffe
    80002440:	110080e7          	jalr	272(ra) # 8000054c <panic>
      fileclose(f);
    80002444:	00002097          	auipc	ra,0x2
    80002448:	576080e7          	jalr	1398(ra) # 800049ba <fileclose>
      p->ofile[fd] = 0;
    8000244c:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    80002450:	04a1                	addi	s1,s1,8
    80002452:	01248563          	beq	s1,s2,8000245c <exit+0x58>
    if(p->ofile[fd]){
    80002456:	6088                	ld	a0,0(s1)
    80002458:	f575                	bnez	a0,80002444 <exit+0x40>
    8000245a:	bfdd                	j	80002450 <exit+0x4c>
  begin_op();
    8000245c:	00002097          	auipc	ra,0x2
    80002460:	08e080e7          	jalr	142(ra) # 800044ea <begin_op>
  iput(p->cwd);
    80002464:	1589b503          	ld	a0,344(s3)
    80002468:	00002097          	auipc	ra,0x2
    8000246c:	862080e7          	jalr	-1950(ra) # 80003cca <iput>
  end_op();
    80002470:	00002097          	auipc	ra,0x2
    80002474:	0f8080e7          	jalr	248(ra) # 80004568 <end_op>
  p->cwd = 0;
    80002478:	1409bc23          	sd	zero,344(s3)
  acquire(&initproc->lock);
    8000247c:	00007497          	auipc	s1,0x7
    80002480:	b9c48493          	addi	s1,s1,-1124 # 80009018 <initproc>
    80002484:	6088                	ld	a0,0(s1)
    80002486:	fffff097          	auipc	ra,0xfffff
    8000248a:	866080e7          	jalr	-1946(ra) # 80000cec <acquire>
  wakeup1(initproc);
    8000248e:	6088                	ld	a0,0(s1)
    80002490:	fffff097          	auipc	ra,0xfffff
    80002494:	762080e7          	jalr	1890(ra) # 80001bf2 <wakeup1>
  release(&initproc->lock);
    80002498:	6088                	ld	a0,0(s1)
    8000249a:	fffff097          	auipc	ra,0xfffff
    8000249e:	922080e7          	jalr	-1758(ra) # 80000dbc <release>
  acquire(&p->lock);
    800024a2:	854e                	mv	a0,s3
    800024a4:	fffff097          	auipc	ra,0xfffff
    800024a8:	848080e7          	jalr	-1976(ra) # 80000cec <acquire>
  struct proc *original_parent = p->parent;
    800024ac:	0289b483          	ld	s1,40(s3)
  release(&p->lock);
    800024b0:	854e                	mv	a0,s3
    800024b2:	fffff097          	auipc	ra,0xfffff
    800024b6:	90a080e7          	jalr	-1782(ra) # 80000dbc <release>
  acquire(&original_parent->lock);
    800024ba:	8526                	mv	a0,s1
    800024bc:	fffff097          	auipc	ra,0xfffff
    800024c0:	830080e7          	jalr	-2000(ra) # 80000cec <acquire>
  acquire(&p->lock);
    800024c4:	854e                	mv	a0,s3
    800024c6:	fffff097          	auipc	ra,0xfffff
    800024ca:	826080e7          	jalr	-2010(ra) # 80000cec <acquire>
  reparent(p);
    800024ce:	854e                	mv	a0,s3
    800024d0:	00000097          	auipc	ra,0x0
    800024d4:	d34080e7          	jalr	-716(ra) # 80002204 <reparent>
  wakeup1(original_parent);
    800024d8:	8526                	mv	a0,s1
    800024da:	fffff097          	auipc	ra,0xfffff
    800024de:	718080e7          	jalr	1816(ra) # 80001bf2 <wakeup1>
  p->xstate = status;
    800024e2:	0349ae23          	sw	s4,60(s3)
  p->state = ZOMBIE;
    800024e6:	4791                	li	a5,4
    800024e8:	02f9a023          	sw	a5,32(s3)
  release(&original_parent->lock);
    800024ec:	8526                	mv	a0,s1
    800024ee:	fffff097          	auipc	ra,0xfffff
    800024f2:	8ce080e7          	jalr	-1842(ra) # 80000dbc <release>
  sched();
    800024f6:	00000097          	auipc	ra,0x0
    800024fa:	e38080e7          	jalr	-456(ra) # 8000232e <sched>
  panic("zombie exit");
    800024fe:	00006517          	auipc	a0,0x6
    80002502:	dea50513          	addi	a0,a0,-534 # 800082e8 <digits+0x2a8>
    80002506:	ffffe097          	auipc	ra,0xffffe
    8000250a:	046080e7          	jalr	70(ra) # 8000054c <panic>

000000008000250e <yield>:
{
    8000250e:	1101                	addi	sp,sp,-32
    80002510:	ec06                	sd	ra,24(sp)
    80002512:	e822                	sd	s0,16(sp)
    80002514:	e426                	sd	s1,8(sp)
    80002516:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002518:	00000097          	auipc	ra,0x0
    8000251c:	81a080e7          	jalr	-2022(ra) # 80001d32 <myproc>
    80002520:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002522:	ffffe097          	auipc	ra,0xffffe
    80002526:	7ca080e7          	jalr	1994(ra) # 80000cec <acquire>
  p->state = RUNNABLE;
    8000252a:	4789                	li	a5,2
    8000252c:	d09c                	sw	a5,32(s1)
  sched();
    8000252e:	00000097          	auipc	ra,0x0
    80002532:	e00080e7          	jalr	-512(ra) # 8000232e <sched>
  release(&p->lock);
    80002536:	8526                	mv	a0,s1
    80002538:	fffff097          	auipc	ra,0xfffff
    8000253c:	884080e7          	jalr	-1916(ra) # 80000dbc <release>
}
    80002540:	60e2                	ld	ra,24(sp)
    80002542:	6442                	ld	s0,16(sp)
    80002544:	64a2                	ld	s1,8(sp)
    80002546:	6105                	addi	sp,sp,32
    80002548:	8082                	ret

000000008000254a <sleep>:
{
    8000254a:	7179                	addi	sp,sp,-48
    8000254c:	f406                	sd	ra,40(sp)
    8000254e:	f022                	sd	s0,32(sp)
    80002550:	ec26                	sd	s1,24(sp)
    80002552:	e84a                	sd	s2,16(sp)
    80002554:	e44e                	sd	s3,8(sp)
    80002556:	1800                	addi	s0,sp,48
    80002558:	89aa                	mv	s3,a0
    8000255a:	892e                	mv	s2,a1
  struct proc *p = myproc();
    8000255c:	fffff097          	auipc	ra,0xfffff
    80002560:	7d6080e7          	jalr	2006(ra) # 80001d32 <myproc>
    80002564:	84aa                	mv	s1,a0
  if(lk != &p->lock){  //DOC: sleeplock0
    80002566:	05250663          	beq	a0,s2,800025b2 <sleep+0x68>
    acquire(&p->lock);  //DOC: sleeplock1
    8000256a:	ffffe097          	auipc	ra,0xffffe
    8000256e:	782080e7          	jalr	1922(ra) # 80000cec <acquire>
    release(lk);
    80002572:	854a                	mv	a0,s2
    80002574:	fffff097          	auipc	ra,0xfffff
    80002578:	848080e7          	jalr	-1976(ra) # 80000dbc <release>
  p->chan = chan;
    8000257c:	0334b823          	sd	s3,48(s1)
  p->state = SLEEPING;
    80002580:	4785                	li	a5,1
    80002582:	d09c                	sw	a5,32(s1)
  sched();
    80002584:	00000097          	auipc	ra,0x0
    80002588:	daa080e7          	jalr	-598(ra) # 8000232e <sched>
  p->chan = 0;
    8000258c:	0204b823          	sd	zero,48(s1)
    release(&p->lock);
    80002590:	8526                	mv	a0,s1
    80002592:	fffff097          	auipc	ra,0xfffff
    80002596:	82a080e7          	jalr	-2006(ra) # 80000dbc <release>
    acquire(lk);
    8000259a:	854a                	mv	a0,s2
    8000259c:	ffffe097          	auipc	ra,0xffffe
    800025a0:	750080e7          	jalr	1872(ra) # 80000cec <acquire>
}
    800025a4:	70a2                	ld	ra,40(sp)
    800025a6:	7402                	ld	s0,32(sp)
    800025a8:	64e2                	ld	s1,24(sp)
    800025aa:	6942                	ld	s2,16(sp)
    800025ac:	69a2                	ld	s3,8(sp)
    800025ae:	6145                	addi	sp,sp,48
    800025b0:	8082                	ret
  p->chan = chan;
    800025b2:	03353823          	sd	s3,48(a0)
  p->state = SLEEPING;
    800025b6:	4785                	li	a5,1
    800025b8:	d11c                	sw	a5,32(a0)
  sched();
    800025ba:	00000097          	auipc	ra,0x0
    800025be:	d74080e7          	jalr	-652(ra) # 8000232e <sched>
  p->chan = 0;
    800025c2:	0204b823          	sd	zero,48(s1)
  if(lk != &p->lock){
    800025c6:	bff9                	j	800025a4 <sleep+0x5a>

00000000800025c8 <wait>:
{
    800025c8:	715d                	addi	sp,sp,-80
    800025ca:	e486                	sd	ra,72(sp)
    800025cc:	e0a2                	sd	s0,64(sp)
    800025ce:	fc26                	sd	s1,56(sp)
    800025d0:	f84a                	sd	s2,48(sp)
    800025d2:	f44e                	sd	s3,40(sp)
    800025d4:	f052                	sd	s4,32(sp)
    800025d6:	ec56                	sd	s5,24(sp)
    800025d8:	e85a                	sd	s6,16(sp)
    800025da:	e45e                	sd	s7,8(sp)
    800025dc:	0880                	addi	s0,sp,80
    800025de:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800025e0:	fffff097          	auipc	ra,0xfffff
    800025e4:	752080e7          	jalr	1874(ra) # 80001d32 <myproc>
    800025e8:	892a                	mv	s2,a0
  acquire(&p->lock);
    800025ea:	ffffe097          	auipc	ra,0xffffe
    800025ee:	702080e7          	jalr	1794(ra) # 80000cec <acquire>
    havekids = 0;
    800025f2:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    800025f4:	4a11                	li	s4,4
        havekids = 1;
    800025f6:	4a85                	li	s5,1
    for(np = proc; np < &proc[NPROC]; np++){
    800025f8:	00016997          	auipc	s3,0x16
    800025fc:	db098993          	addi	s3,s3,-592 # 800183a8 <tickslock>
    havekids = 0;
    80002600:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    80002602:	00010497          	auipc	s1,0x10
    80002606:	1a648493          	addi	s1,s1,422 # 800127a8 <proc>
    8000260a:	a08d                	j	8000266c <wait+0xa4>
          pid = np->pid;
    8000260c:	0404a983          	lw	s3,64(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002610:	000b0e63          	beqz	s6,8000262c <wait+0x64>
    80002614:	4691                	li	a3,4
    80002616:	03c48613          	addi	a2,s1,60
    8000261a:	85da                	mv	a1,s6
    8000261c:	05893503          	ld	a0,88(s2)
    80002620:	fffff097          	auipc	ra,0xfffff
    80002624:	408080e7          	jalr	1032(ra) # 80001a28 <copyout>
    80002628:	02054263          	bltz	a0,8000264c <wait+0x84>
          freeproc(np);
    8000262c:	8526                	mv	a0,s1
    8000262e:	00000097          	auipc	ra,0x0
    80002632:	8b6080e7          	jalr	-1866(ra) # 80001ee4 <freeproc>
          release(&np->lock);
    80002636:	8526                	mv	a0,s1
    80002638:	ffffe097          	auipc	ra,0xffffe
    8000263c:	784080e7          	jalr	1924(ra) # 80000dbc <release>
          release(&p->lock);
    80002640:	854a                	mv	a0,s2
    80002642:	ffffe097          	auipc	ra,0xffffe
    80002646:	77a080e7          	jalr	1914(ra) # 80000dbc <release>
          return pid;
    8000264a:	a8a9                	j	800026a4 <wait+0xdc>
            release(&np->lock);
    8000264c:	8526                	mv	a0,s1
    8000264e:	ffffe097          	auipc	ra,0xffffe
    80002652:	76e080e7          	jalr	1902(ra) # 80000dbc <release>
            release(&p->lock);
    80002656:	854a                	mv	a0,s2
    80002658:	ffffe097          	auipc	ra,0xffffe
    8000265c:	764080e7          	jalr	1892(ra) # 80000dbc <release>
            return -1;
    80002660:	59fd                	li	s3,-1
    80002662:	a089                	j	800026a4 <wait+0xdc>
    for(np = proc; np < &proc[NPROC]; np++){
    80002664:	17048493          	addi	s1,s1,368
    80002668:	03348463          	beq	s1,s3,80002690 <wait+0xc8>
      if(np->parent == p){
    8000266c:	749c                	ld	a5,40(s1)
    8000266e:	ff279be3          	bne	a5,s2,80002664 <wait+0x9c>
        acquire(&np->lock);
    80002672:	8526                	mv	a0,s1
    80002674:	ffffe097          	auipc	ra,0xffffe
    80002678:	678080e7          	jalr	1656(ra) # 80000cec <acquire>
        if(np->state == ZOMBIE){
    8000267c:	509c                	lw	a5,32(s1)
    8000267e:	f94787e3          	beq	a5,s4,8000260c <wait+0x44>
        release(&np->lock);
    80002682:	8526                	mv	a0,s1
    80002684:	ffffe097          	auipc	ra,0xffffe
    80002688:	738080e7          	jalr	1848(ra) # 80000dbc <release>
        havekids = 1;
    8000268c:	8756                	mv	a4,s5
    8000268e:	bfd9                	j	80002664 <wait+0x9c>
    if(!havekids || p->killed){
    80002690:	c701                	beqz	a4,80002698 <wait+0xd0>
    80002692:	03892783          	lw	a5,56(s2)
    80002696:	c39d                	beqz	a5,800026bc <wait+0xf4>
      release(&p->lock);
    80002698:	854a                	mv	a0,s2
    8000269a:	ffffe097          	auipc	ra,0xffffe
    8000269e:	722080e7          	jalr	1826(ra) # 80000dbc <release>
      return -1;
    800026a2:	59fd                	li	s3,-1
}
    800026a4:	854e                	mv	a0,s3
    800026a6:	60a6                	ld	ra,72(sp)
    800026a8:	6406                	ld	s0,64(sp)
    800026aa:	74e2                	ld	s1,56(sp)
    800026ac:	7942                	ld	s2,48(sp)
    800026ae:	79a2                	ld	s3,40(sp)
    800026b0:	7a02                	ld	s4,32(sp)
    800026b2:	6ae2                	ld	s5,24(sp)
    800026b4:	6b42                	ld	s6,16(sp)
    800026b6:	6ba2                	ld	s7,8(sp)
    800026b8:	6161                	addi	sp,sp,80
    800026ba:	8082                	ret
    sleep(p, &p->lock);  //DOC: wait-sleep
    800026bc:	85ca                	mv	a1,s2
    800026be:	854a                	mv	a0,s2
    800026c0:	00000097          	auipc	ra,0x0
    800026c4:	e8a080e7          	jalr	-374(ra) # 8000254a <sleep>
    havekids = 0;
    800026c8:	bf25                	j	80002600 <wait+0x38>

00000000800026ca <wakeup>:
{
    800026ca:	7139                	addi	sp,sp,-64
    800026cc:	fc06                	sd	ra,56(sp)
    800026ce:	f822                	sd	s0,48(sp)
    800026d0:	f426                	sd	s1,40(sp)
    800026d2:	f04a                	sd	s2,32(sp)
    800026d4:	ec4e                	sd	s3,24(sp)
    800026d6:	e852                	sd	s4,16(sp)
    800026d8:	e456                	sd	s5,8(sp)
    800026da:	0080                	addi	s0,sp,64
    800026dc:	8a2a                	mv	s4,a0
  for(p = proc; p < &proc[NPROC]; p++) {
    800026de:	00010497          	auipc	s1,0x10
    800026e2:	0ca48493          	addi	s1,s1,202 # 800127a8 <proc>
    if(p->state == SLEEPING && p->chan == chan) {
    800026e6:	4985                	li	s3,1
      p->state = RUNNABLE;
    800026e8:	4a89                	li	s5,2
  for(p = proc; p < &proc[NPROC]; p++) {
    800026ea:	00016917          	auipc	s2,0x16
    800026ee:	cbe90913          	addi	s2,s2,-834 # 800183a8 <tickslock>
    800026f2:	a811                	j	80002706 <wakeup+0x3c>
    release(&p->lock);
    800026f4:	8526                	mv	a0,s1
    800026f6:	ffffe097          	auipc	ra,0xffffe
    800026fa:	6c6080e7          	jalr	1734(ra) # 80000dbc <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    800026fe:	17048493          	addi	s1,s1,368
    80002702:	03248063          	beq	s1,s2,80002722 <wakeup+0x58>
    acquire(&p->lock);
    80002706:	8526                	mv	a0,s1
    80002708:	ffffe097          	auipc	ra,0xffffe
    8000270c:	5e4080e7          	jalr	1508(ra) # 80000cec <acquire>
    if(p->state == SLEEPING && p->chan == chan) {
    80002710:	509c                	lw	a5,32(s1)
    80002712:	ff3791e3          	bne	a5,s3,800026f4 <wakeup+0x2a>
    80002716:	789c                	ld	a5,48(s1)
    80002718:	fd479ee3          	bne	a5,s4,800026f4 <wakeup+0x2a>
      p->state = RUNNABLE;
    8000271c:	0354a023          	sw	s5,32(s1)
    80002720:	bfd1                	j	800026f4 <wakeup+0x2a>
}
    80002722:	70e2                	ld	ra,56(sp)
    80002724:	7442                	ld	s0,48(sp)
    80002726:	74a2                	ld	s1,40(sp)
    80002728:	7902                	ld	s2,32(sp)
    8000272a:	69e2                	ld	s3,24(sp)
    8000272c:	6a42                	ld	s4,16(sp)
    8000272e:	6aa2                	ld	s5,8(sp)
    80002730:	6121                	addi	sp,sp,64
    80002732:	8082                	ret

0000000080002734 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    80002734:	7179                	addi	sp,sp,-48
    80002736:	f406                	sd	ra,40(sp)
    80002738:	f022                	sd	s0,32(sp)
    8000273a:	ec26                	sd	s1,24(sp)
    8000273c:	e84a                	sd	s2,16(sp)
    8000273e:	e44e                	sd	s3,8(sp)
    80002740:	1800                	addi	s0,sp,48
    80002742:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    80002744:	00010497          	auipc	s1,0x10
    80002748:	06448493          	addi	s1,s1,100 # 800127a8 <proc>
    8000274c:	00016997          	auipc	s3,0x16
    80002750:	c5c98993          	addi	s3,s3,-932 # 800183a8 <tickslock>
    acquire(&p->lock);
    80002754:	8526                	mv	a0,s1
    80002756:	ffffe097          	auipc	ra,0xffffe
    8000275a:	596080e7          	jalr	1430(ra) # 80000cec <acquire>
    if(p->pid == pid){
    8000275e:	40bc                	lw	a5,64(s1)
    80002760:	01278d63          	beq	a5,s2,8000277a <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002764:	8526                	mv	a0,s1
    80002766:	ffffe097          	auipc	ra,0xffffe
    8000276a:	656080e7          	jalr	1622(ra) # 80000dbc <release>
  for(p = proc; p < &proc[NPROC]; p++){
    8000276e:	17048493          	addi	s1,s1,368
    80002772:	ff3491e3          	bne	s1,s3,80002754 <kill+0x20>
  }
  return -1;
    80002776:	557d                	li	a0,-1
    80002778:	a821                	j	80002790 <kill+0x5c>
      p->killed = 1;
    8000277a:	4785                	li	a5,1
    8000277c:	dc9c                	sw	a5,56(s1)
      if(p->state == SLEEPING){
    8000277e:	5098                	lw	a4,32(s1)
    80002780:	00f70f63          	beq	a4,a5,8000279e <kill+0x6a>
      release(&p->lock);
    80002784:	8526                	mv	a0,s1
    80002786:	ffffe097          	auipc	ra,0xffffe
    8000278a:	636080e7          	jalr	1590(ra) # 80000dbc <release>
      return 0;
    8000278e:	4501                	li	a0,0
}
    80002790:	70a2                	ld	ra,40(sp)
    80002792:	7402                	ld	s0,32(sp)
    80002794:	64e2                	ld	s1,24(sp)
    80002796:	6942                	ld	s2,16(sp)
    80002798:	69a2                	ld	s3,8(sp)
    8000279a:	6145                	addi	sp,sp,48
    8000279c:	8082                	ret
        p->state = RUNNABLE;
    8000279e:	4789                	li	a5,2
    800027a0:	d09c                	sw	a5,32(s1)
    800027a2:	b7cd                	j	80002784 <kill+0x50>

00000000800027a4 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800027a4:	7179                	addi	sp,sp,-48
    800027a6:	f406                	sd	ra,40(sp)
    800027a8:	f022                	sd	s0,32(sp)
    800027aa:	ec26                	sd	s1,24(sp)
    800027ac:	e84a                	sd	s2,16(sp)
    800027ae:	e44e                	sd	s3,8(sp)
    800027b0:	e052                	sd	s4,0(sp)
    800027b2:	1800                	addi	s0,sp,48
    800027b4:	84aa                	mv	s1,a0
    800027b6:	892e                	mv	s2,a1
    800027b8:	89b2                	mv	s3,a2
    800027ba:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800027bc:	fffff097          	auipc	ra,0xfffff
    800027c0:	576080e7          	jalr	1398(ra) # 80001d32 <myproc>
  if(user_dst){
    800027c4:	c08d                	beqz	s1,800027e6 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    800027c6:	86d2                	mv	a3,s4
    800027c8:	864e                	mv	a2,s3
    800027ca:	85ca                	mv	a1,s2
    800027cc:	6d28                	ld	a0,88(a0)
    800027ce:	fffff097          	auipc	ra,0xfffff
    800027d2:	25a080e7          	jalr	602(ra) # 80001a28 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    800027d6:	70a2                	ld	ra,40(sp)
    800027d8:	7402                	ld	s0,32(sp)
    800027da:	64e2                	ld	s1,24(sp)
    800027dc:	6942                	ld	s2,16(sp)
    800027de:	69a2                	ld	s3,8(sp)
    800027e0:	6a02                	ld	s4,0(sp)
    800027e2:	6145                	addi	sp,sp,48
    800027e4:	8082                	ret
    memmove((char *)dst, src, len);
    800027e6:	000a061b          	sext.w	a2,s4
    800027ea:	85ce                	mv	a1,s3
    800027ec:	854a                	mv	a0,s2
    800027ee:	fffff097          	auipc	ra,0xfffff
    800027f2:	93a080e7          	jalr	-1734(ra) # 80001128 <memmove>
    return 0;
    800027f6:	8526                	mv	a0,s1
    800027f8:	bff9                	j	800027d6 <either_copyout+0x32>

00000000800027fa <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800027fa:	7179                	addi	sp,sp,-48
    800027fc:	f406                	sd	ra,40(sp)
    800027fe:	f022                	sd	s0,32(sp)
    80002800:	ec26                	sd	s1,24(sp)
    80002802:	e84a                	sd	s2,16(sp)
    80002804:	e44e                	sd	s3,8(sp)
    80002806:	e052                	sd	s4,0(sp)
    80002808:	1800                	addi	s0,sp,48
    8000280a:	892a                	mv	s2,a0
    8000280c:	84ae                	mv	s1,a1
    8000280e:	89b2                	mv	s3,a2
    80002810:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002812:	fffff097          	auipc	ra,0xfffff
    80002816:	520080e7          	jalr	1312(ra) # 80001d32 <myproc>
  if(user_src){
    8000281a:	c08d                	beqz	s1,8000283c <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    8000281c:	86d2                	mv	a3,s4
    8000281e:	864e                	mv	a2,s3
    80002820:	85ca                	mv	a1,s2
    80002822:	6d28                	ld	a0,88(a0)
    80002824:	fffff097          	auipc	ra,0xfffff
    80002828:	290080e7          	jalr	656(ra) # 80001ab4 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    8000282c:	70a2                	ld	ra,40(sp)
    8000282e:	7402                	ld	s0,32(sp)
    80002830:	64e2                	ld	s1,24(sp)
    80002832:	6942                	ld	s2,16(sp)
    80002834:	69a2                	ld	s3,8(sp)
    80002836:	6a02                	ld	s4,0(sp)
    80002838:	6145                	addi	sp,sp,48
    8000283a:	8082                	ret
    memmove(dst, (char*)src, len);
    8000283c:	000a061b          	sext.w	a2,s4
    80002840:	85ce                	mv	a1,s3
    80002842:	854a                	mv	a0,s2
    80002844:	fffff097          	auipc	ra,0xfffff
    80002848:	8e4080e7          	jalr	-1820(ra) # 80001128 <memmove>
    return 0;
    8000284c:	8526                	mv	a0,s1
    8000284e:	bff9                	j	8000282c <either_copyin+0x32>

0000000080002850 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    80002850:	715d                	addi	sp,sp,-80
    80002852:	e486                	sd	ra,72(sp)
    80002854:	e0a2                	sd	s0,64(sp)
    80002856:	fc26                	sd	s1,56(sp)
    80002858:	f84a                	sd	s2,48(sp)
    8000285a:	f44e                	sd	s3,40(sp)
    8000285c:	f052                	sd	s4,32(sp)
    8000285e:	ec56                	sd	s5,24(sp)
    80002860:	e85a                	sd	s6,16(sp)
    80002862:	e45e                	sd	s7,8(sp)
    80002864:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    80002866:	00006517          	auipc	a0,0x6
    8000286a:	8fa50513          	addi	a0,a0,-1798 # 80008160 <digits+0x120>
    8000286e:	ffffe097          	auipc	ra,0xffffe
    80002872:	d28080e7          	jalr	-728(ra) # 80000596 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002876:	00010497          	auipc	s1,0x10
    8000287a:	09248493          	addi	s1,s1,146 # 80012908 <proc+0x160>
    8000287e:	00016917          	auipc	s2,0x16
    80002882:	c8a90913          	addi	s2,s2,-886 # 80018508 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002886:	4b11                	li	s6,4
      state = states[p->state];
    else
      state = "???";
    80002888:	00006997          	auipc	s3,0x6
    8000288c:	a7098993          	addi	s3,s3,-1424 # 800082f8 <digits+0x2b8>
    printf("%d %s %s", p->pid, state, p->name);
    80002890:	00006a97          	auipc	s5,0x6
    80002894:	a70a8a93          	addi	s5,s5,-1424 # 80008300 <digits+0x2c0>
    printf("\n");
    80002898:	00006a17          	auipc	s4,0x6
    8000289c:	8c8a0a13          	addi	s4,s4,-1848 # 80008160 <digits+0x120>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800028a0:	00006b97          	auipc	s7,0x6
    800028a4:	a98b8b93          	addi	s7,s7,-1384 # 80008338 <states.0>
    800028a8:	a00d                	j	800028ca <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    800028aa:	ee06a583          	lw	a1,-288(a3)
    800028ae:	8556                	mv	a0,s5
    800028b0:	ffffe097          	auipc	ra,0xffffe
    800028b4:	ce6080e7          	jalr	-794(ra) # 80000596 <printf>
    printf("\n");
    800028b8:	8552                	mv	a0,s4
    800028ba:	ffffe097          	auipc	ra,0xffffe
    800028be:	cdc080e7          	jalr	-804(ra) # 80000596 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800028c2:	17048493          	addi	s1,s1,368
    800028c6:	03248263          	beq	s1,s2,800028ea <procdump+0x9a>
    if(p->state == UNUSED)
    800028ca:	86a6                	mv	a3,s1
    800028cc:	ec04a783          	lw	a5,-320(s1)
    800028d0:	dbed                	beqz	a5,800028c2 <procdump+0x72>
      state = "???";
    800028d2:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800028d4:	fcfb6be3          	bltu	s6,a5,800028aa <procdump+0x5a>
    800028d8:	02079713          	slli	a4,a5,0x20
    800028dc:	01d75793          	srli	a5,a4,0x1d
    800028e0:	97de                	add	a5,a5,s7
    800028e2:	6390                	ld	a2,0(a5)
    800028e4:	f279                	bnez	a2,800028aa <procdump+0x5a>
      state = "???";
    800028e6:	864e                	mv	a2,s3
    800028e8:	b7c9                	j	800028aa <procdump+0x5a>
  }
}
    800028ea:	60a6                	ld	ra,72(sp)
    800028ec:	6406                	ld	s0,64(sp)
    800028ee:	74e2                	ld	s1,56(sp)
    800028f0:	7942                	ld	s2,48(sp)
    800028f2:	79a2                	ld	s3,40(sp)
    800028f4:	7a02                	ld	s4,32(sp)
    800028f6:	6ae2                	ld	s5,24(sp)
    800028f8:	6b42                	ld	s6,16(sp)
    800028fa:	6ba2                	ld	s7,8(sp)
    800028fc:	6161                	addi	sp,sp,80
    800028fe:	8082                	ret

0000000080002900 <swtch>:
    80002900:	00153023          	sd	ra,0(a0)
    80002904:	00253423          	sd	sp,8(a0)
    80002908:	e900                	sd	s0,16(a0)
    8000290a:	ed04                	sd	s1,24(a0)
    8000290c:	03253023          	sd	s2,32(a0)
    80002910:	03353423          	sd	s3,40(a0)
    80002914:	03453823          	sd	s4,48(a0)
    80002918:	03553c23          	sd	s5,56(a0)
    8000291c:	05653023          	sd	s6,64(a0)
    80002920:	05753423          	sd	s7,72(a0)
    80002924:	05853823          	sd	s8,80(a0)
    80002928:	05953c23          	sd	s9,88(a0)
    8000292c:	07a53023          	sd	s10,96(a0)
    80002930:	07b53423          	sd	s11,104(a0)
    80002934:	0005b083          	ld	ra,0(a1)
    80002938:	0085b103          	ld	sp,8(a1)
    8000293c:	6980                	ld	s0,16(a1)
    8000293e:	6d84                	ld	s1,24(a1)
    80002940:	0205b903          	ld	s2,32(a1)
    80002944:	0285b983          	ld	s3,40(a1)
    80002948:	0305ba03          	ld	s4,48(a1)
    8000294c:	0385ba83          	ld	s5,56(a1)
    80002950:	0405bb03          	ld	s6,64(a1)
    80002954:	0485bb83          	ld	s7,72(a1)
    80002958:	0505bc03          	ld	s8,80(a1)
    8000295c:	0585bc83          	ld	s9,88(a1)
    80002960:	0605bd03          	ld	s10,96(a1)
    80002964:	0685bd83          	ld	s11,104(a1)
    80002968:	8082                	ret

000000008000296a <trapinit>:

extern int devintr();

void
trapinit(void)
{
    8000296a:	1141                	addi	sp,sp,-16
    8000296c:	e406                	sd	ra,8(sp)
    8000296e:	e022                	sd	s0,0(sp)
    80002970:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002972:	00006597          	auipc	a1,0x6
    80002976:	9ee58593          	addi	a1,a1,-1554 # 80008360 <states.0+0x28>
    8000297a:	00016517          	auipc	a0,0x16
    8000297e:	a2e50513          	addi	a0,a0,-1490 # 800183a8 <tickslock>
    80002982:	ffffe097          	auipc	ra,0xffffe
    80002986:	4e6080e7          	jalr	1254(ra) # 80000e68 <initlock>
}
    8000298a:	60a2                	ld	ra,8(sp)
    8000298c:	6402                	ld	s0,0(sp)
    8000298e:	0141                	addi	sp,sp,16
    80002990:	8082                	ret

0000000080002992 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002992:	1141                	addi	sp,sp,-16
    80002994:	e422                	sd	s0,8(sp)
    80002996:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002998:	00003797          	auipc	a5,0x3
    8000299c:	69878793          	addi	a5,a5,1688 # 80006030 <kernelvec>
    800029a0:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    800029a4:	6422                	ld	s0,8(sp)
    800029a6:	0141                	addi	sp,sp,16
    800029a8:	8082                	ret

00000000800029aa <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    800029aa:	1141                	addi	sp,sp,-16
    800029ac:	e406                	sd	ra,8(sp)
    800029ae:	e022                	sd	s0,0(sp)
    800029b0:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    800029b2:	fffff097          	auipc	ra,0xfffff
    800029b6:	380080e7          	jalr	896(ra) # 80001d32 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029ba:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    800029be:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800029c0:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    800029c4:	00004697          	auipc	a3,0x4
    800029c8:	63c68693          	addi	a3,a3,1596 # 80007000 <_trampoline>
    800029cc:	00004717          	auipc	a4,0x4
    800029d0:	63470713          	addi	a4,a4,1588 # 80007000 <_trampoline>
    800029d4:	8f15                	sub	a4,a4,a3
    800029d6:	040007b7          	lui	a5,0x4000
    800029da:	17fd                	addi	a5,a5,-1 # 3ffffff <_entry-0x7c000001>
    800029dc:	07b2                	slli	a5,a5,0xc
    800029de:	973e                	add	a4,a4,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    800029e0:	10571073          	csrw	stvec,a4

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    800029e4:	7138                	ld	a4,96(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    800029e6:	18002673          	csrr	a2,satp
    800029ea:	e310                	sd	a2,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    800029ec:	7130                	ld	a2,96(a0)
    800029ee:	6538                	ld	a4,72(a0)
    800029f0:	6585                	lui	a1,0x1
    800029f2:	972e                	add	a4,a4,a1
    800029f4:	e618                	sd	a4,8(a2)
  p->trapframe->kernel_trap = (uint64)usertrap;
    800029f6:	7138                	ld	a4,96(a0)
    800029f8:	00000617          	auipc	a2,0x0
    800029fc:	13860613          	addi	a2,a2,312 # 80002b30 <usertrap>
    80002a00:	eb10                	sd	a2,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002a02:	7138                	ld	a4,96(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002a04:	8612                	mv	a2,tp
    80002a06:	f310                	sd	a2,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a08:	10002773          	csrr	a4,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002a0c:	eff77713          	andi	a4,a4,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002a10:	02076713          	ori	a4,a4,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002a14:	10071073          	csrw	sstatus,a4
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002a18:	7138                	ld	a4,96(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002a1a:	6f18                	ld	a4,24(a4)
    80002a1c:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002a20:	6d2c                	ld	a1,88(a0)
    80002a22:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002a24:	00004717          	auipc	a4,0x4
    80002a28:	66c70713          	addi	a4,a4,1644 # 80007090 <userret>
    80002a2c:	8f15                	sub	a4,a4,a3
    80002a2e:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80002a30:	577d                	li	a4,-1
    80002a32:	177e                	slli	a4,a4,0x3f
    80002a34:	8dd9                	or	a1,a1,a4
    80002a36:	02000537          	lui	a0,0x2000
    80002a3a:	157d                	addi	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    80002a3c:	0536                	slli	a0,a0,0xd
    80002a3e:	9782                	jalr	a5
}
    80002a40:	60a2                	ld	ra,8(sp)
    80002a42:	6402                	ld	s0,0(sp)
    80002a44:	0141                	addi	sp,sp,16
    80002a46:	8082                	ret

0000000080002a48 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002a48:	1101                	addi	sp,sp,-32
    80002a4a:	ec06                	sd	ra,24(sp)
    80002a4c:	e822                	sd	s0,16(sp)
    80002a4e:	e426                	sd	s1,8(sp)
    80002a50:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002a52:	00016497          	auipc	s1,0x16
    80002a56:	95648493          	addi	s1,s1,-1706 # 800183a8 <tickslock>
    80002a5a:	8526                	mv	a0,s1
    80002a5c:	ffffe097          	auipc	ra,0xffffe
    80002a60:	290080e7          	jalr	656(ra) # 80000cec <acquire>
  ticks++;
    80002a64:	00006517          	auipc	a0,0x6
    80002a68:	5bc50513          	addi	a0,a0,1468 # 80009020 <ticks>
    80002a6c:	411c                	lw	a5,0(a0)
    80002a6e:	2785                	addiw	a5,a5,1
    80002a70:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002a72:	00000097          	auipc	ra,0x0
    80002a76:	c58080e7          	jalr	-936(ra) # 800026ca <wakeup>
  release(&tickslock);
    80002a7a:	8526                	mv	a0,s1
    80002a7c:	ffffe097          	auipc	ra,0xffffe
    80002a80:	340080e7          	jalr	832(ra) # 80000dbc <release>
}
    80002a84:	60e2                	ld	ra,24(sp)
    80002a86:	6442                	ld	s0,16(sp)
    80002a88:	64a2                	ld	s1,8(sp)
    80002a8a:	6105                	addi	sp,sp,32
    80002a8c:	8082                	ret

0000000080002a8e <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002a8e:	1101                	addi	sp,sp,-32
    80002a90:	ec06                	sd	ra,24(sp)
    80002a92:	e822                	sd	s0,16(sp)
    80002a94:	e426                	sd	s1,8(sp)
    80002a96:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a98:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002a9c:	00074d63          	bltz	a4,80002ab6 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002aa0:	57fd                	li	a5,-1
    80002aa2:	17fe                	slli	a5,a5,0x3f
    80002aa4:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002aa6:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002aa8:	06f70363          	beq	a4,a5,80002b0e <devintr+0x80>
  }
}
    80002aac:	60e2                	ld	ra,24(sp)
    80002aae:	6442                	ld	s0,16(sp)
    80002ab0:	64a2                	ld	s1,8(sp)
    80002ab2:	6105                	addi	sp,sp,32
    80002ab4:	8082                	ret
     (scause & 0xff) == 9){
    80002ab6:	0ff77793          	zext.b	a5,a4
  if((scause & 0x8000000000000000L) &&
    80002aba:	46a5                	li	a3,9
    80002abc:	fed792e3          	bne	a5,a3,80002aa0 <devintr+0x12>
    int irq = plic_claim();
    80002ac0:	00003097          	auipc	ra,0x3
    80002ac4:	678080e7          	jalr	1656(ra) # 80006138 <plic_claim>
    80002ac8:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002aca:	47a9                	li	a5,10
    80002acc:	02f50763          	beq	a0,a5,80002afa <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002ad0:	4785                	li	a5,1
    80002ad2:	02f50963          	beq	a0,a5,80002b04 <devintr+0x76>
    return 1;
    80002ad6:	4505                	li	a0,1
    } else if(irq){
    80002ad8:	d8f1                	beqz	s1,80002aac <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002ada:	85a6                	mv	a1,s1
    80002adc:	00006517          	auipc	a0,0x6
    80002ae0:	88c50513          	addi	a0,a0,-1908 # 80008368 <states.0+0x30>
    80002ae4:	ffffe097          	auipc	ra,0xffffe
    80002ae8:	ab2080e7          	jalr	-1358(ra) # 80000596 <printf>
      plic_complete(irq);
    80002aec:	8526                	mv	a0,s1
    80002aee:	00003097          	auipc	ra,0x3
    80002af2:	66e080e7          	jalr	1646(ra) # 8000615c <plic_complete>
    return 1;
    80002af6:	4505                	li	a0,1
    80002af8:	bf55                	j	80002aac <devintr+0x1e>
      uartintr();
    80002afa:	ffffe097          	auipc	ra,0xffffe
    80002afe:	ece080e7          	jalr	-306(ra) # 800009c8 <uartintr>
    80002b02:	b7ed                	j	80002aec <devintr+0x5e>
      virtio_disk_intr();
    80002b04:	00004097          	auipc	ra,0x4
    80002b08:	ae4080e7          	jalr	-1308(ra) # 800065e8 <virtio_disk_intr>
    80002b0c:	b7c5                	j	80002aec <devintr+0x5e>
    if(cpuid() == 0){
    80002b0e:	fffff097          	auipc	ra,0xfffff
    80002b12:	1f8080e7          	jalr	504(ra) # 80001d06 <cpuid>
    80002b16:	c901                	beqz	a0,80002b26 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002b18:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002b1c:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002b1e:	14479073          	csrw	sip,a5
    return 2;
    80002b22:	4509                	li	a0,2
    80002b24:	b761                	j	80002aac <devintr+0x1e>
      clockintr();
    80002b26:	00000097          	auipc	ra,0x0
    80002b2a:	f22080e7          	jalr	-222(ra) # 80002a48 <clockintr>
    80002b2e:	b7ed                	j	80002b18 <devintr+0x8a>

0000000080002b30 <usertrap>:
{
    80002b30:	1101                	addi	sp,sp,-32
    80002b32:	ec06                	sd	ra,24(sp)
    80002b34:	e822                	sd	s0,16(sp)
    80002b36:	e426                	sd	s1,8(sp)
    80002b38:	e04a                	sd	s2,0(sp)
    80002b3a:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b3c:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002b40:	1007f793          	andi	a5,a5,256
    80002b44:	e3ad                	bnez	a5,80002ba6 <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002b46:	00003797          	auipc	a5,0x3
    80002b4a:	4ea78793          	addi	a5,a5,1258 # 80006030 <kernelvec>
    80002b4e:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002b52:	fffff097          	auipc	ra,0xfffff
    80002b56:	1e0080e7          	jalr	480(ra) # 80001d32 <myproc>
    80002b5a:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002b5c:	713c                	ld	a5,96(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b5e:	14102773          	csrr	a4,sepc
    80002b62:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002b64:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002b68:	47a1                	li	a5,8
    80002b6a:	04f71c63          	bne	a4,a5,80002bc2 <usertrap+0x92>
    if(p->killed)
    80002b6e:	5d1c                	lw	a5,56(a0)
    80002b70:	e3b9                	bnez	a5,80002bb6 <usertrap+0x86>
    p->trapframe->epc += 4;
    80002b72:	70b8                	ld	a4,96(s1)
    80002b74:	6f1c                	ld	a5,24(a4)
    80002b76:	0791                	addi	a5,a5,4
    80002b78:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b7a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002b7e:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002b82:	10079073          	csrw	sstatus,a5
    syscall();
    80002b86:	00000097          	auipc	ra,0x0
    80002b8a:	2e0080e7          	jalr	736(ra) # 80002e66 <syscall>
  if(p->killed)
    80002b8e:	5c9c                	lw	a5,56(s1)
    80002b90:	ebc1                	bnez	a5,80002c20 <usertrap+0xf0>
  usertrapret();
    80002b92:	00000097          	auipc	ra,0x0
    80002b96:	e18080e7          	jalr	-488(ra) # 800029aa <usertrapret>
}
    80002b9a:	60e2                	ld	ra,24(sp)
    80002b9c:	6442                	ld	s0,16(sp)
    80002b9e:	64a2                	ld	s1,8(sp)
    80002ba0:	6902                	ld	s2,0(sp)
    80002ba2:	6105                	addi	sp,sp,32
    80002ba4:	8082                	ret
    panic("usertrap: not from user mode");
    80002ba6:	00005517          	auipc	a0,0x5
    80002baa:	7e250513          	addi	a0,a0,2018 # 80008388 <states.0+0x50>
    80002bae:	ffffe097          	auipc	ra,0xffffe
    80002bb2:	99e080e7          	jalr	-1634(ra) # 8000054c <panic>
      exit(-1);
    80002bb6:	557d                	li	a0,-1
    80002bb8:	00000097          	auipc	ra,0x0
    80002bbc:	84c080e7          	jalr	-1972(ra) # 80002404 <exit>
    80002bc0:	bf4d                	j	80002b72 <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80002bc2:	00000097          	auipc	ra,0x0
    80002bc6:	ecc080e7          	jalr	-308(ra) # 80002a8e <devintr>
    80002bca:	892a                	mv	s2,a0
    80002bcc:	c501                	beqz	a0,80002bd4 <usertrap+0xa4>
  if(p->killed)
    80002bce:	5c9c                	lw	a5,56(s1)
    80002bd0:	c3a1                	beqz	a5,80002c10 <usertrap+0xe0>
    80002bd2:	a815                	j	80002c06 <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002bd4:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002bd8:	40b0                	lw	a2,64(s1)
    80002bda:	00005517          	auipc	a0,0x5
    80002bde:	7ce50513          	addi	a0,a0,1998 # 800083a8 <states.0+0x70>
    80002be2:	ffffe097          	auipc	ra,0xffffe
    80002be6:	9b4080e7          	jalr	-1612(ra) # 80000596 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002bea:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002bee:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002bf2:	00005517          	auipc	a0,0x5
    80002bf6:	7e650513          	addi	a0,a0,2022 # 800083d8 <states.0+0xa0>
    80002bfa:	ffffe097          	auipc	ra,0xffffe
    80002bfe:	99c080e7          	jalr	-1636(ra) # 80000596 <printf>
    p->killed = 1;
    80002c02:	4785                	li	a5,1
    80002c04:	dc9c                	sw	a5,56(s1)
    exit(-1);
    80002c06:	557d                	li	a0,-1
    80002c08:	fffff097          	auipc	ra,0xfffff
    80002c0c:	7fc080e7          	jalr	2044(ra) # 80002404 <exit>
  if(which_dev == 2)
    80002c10:	4789                	li	a5,2
    80002c12:	f8f910e3          	bne	s2,a5,80002b92 <usertrap+0x62>
    yield();
    80002c16:	00000097          	auipc	ra,0x0
    80002c1a:	8f8080e7          	jalr	-1800(ra) # 8000250e <yield>
    80002c1e:	bf95                	j	80002b92 <usertrap+0x62>
  int which_dev = 0;
    80002c20:	4901                	li	s2,0
    80002c22:	b7d5                	j	80002c06 <usertrap+0xd6>

0000000080002c24 <kerneltrap>:
{
    80002c24:	7179                	addi	sp,sp,-48
    80002c26:	f406                	sd	ra,40(sp)
    80002c28:	f022                	sd	s0,32(sp)
    80002c2a:	ec26                	sd	s1,24(sp)
    80002c2c:	e84a                	sd	s2,16(sp)
    80002c2e:	e44e                	sd	s3,8(sp)
    80002c30:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002c32:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c36:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002c3a:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002c3e:	1004f793          	andi	a5,s1,256
    80002c42:	cb85                	beqz	a5,80002c72 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c44:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002c48:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002c4a:	ef85                	bnez	a5,80002c82 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002c4c:	00000097          	auipc	ra,0x0
    80002c50:	e42080e7          	jalr	-446(ra) # 80002a8e <devintr>
    80002c54:	cd1d                	beqz	a0,80002c92 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002c56:	4789                	li	a5,2
    80002c58:	06f50a63          	beq	a0,a5,80002ccc <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002c5c:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002c60:	10049073          	csrw	sstatus,s1
}
    80002c64:	70a2                	ld	ra,40(sp)
    80002c66:	7402                	ld	s0,32(sp)
    80002c68:	64e2                	ld	s1,24(sp)
    80002c6a:	6942                	ld	s2,16(sp)
    80002c6c:	69a2                	ld	s3,8(sp)
    80002c6e:	6145                	addi	sp,sp,48
    80002c70:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002c72:	00005517          	auipc	a0,0x5
    80002c76:	78650513          	addi	a0,a0,1926 # 800083f8 <states.0+0xc0>
    80002c7a:	ffffe097          	auipc	ra,0xffffe
    80002c7e:	8d2080e7          	jalr	-1838(ra) # 8000054c <panic>
    panic("kerneltrap: interrupts enabled");
    80002c82:	00005517          	auipc	a0,0x5
    80002c86:	79e50513          	addi	a0,a0,1950 # 80008420 <states.0+0xe8>
    80002c8a:	ffffe097          	auipc	ra,0xffffe
    80002c8e:	8c2080e7          	jalr	-1854(ra) # 8000054c <panic>
    printf("scause %p\n", scause);
    80002c92:	85ce                	mv	a1,s3
    80002c94:	00005517          	auipc	a0,0x5
    80002c98:	7ac50513          	addi	a0,a0,1964 # 80008440 <states.0+0x108>
    80002c9c:	ffffe097          	auipc	ra,0xffffe
    80002ca0:	8fa080e7          	jalr	-1798(ra) # 80000596 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002ca4:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002ca8:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002cac:	00005517          	auipc	a0,0x5
    80002cb0:	7a450513          	addi	a0,a0,1956 # 80008450 <states.0+0x118>
    80002cb4:	ffffe097          	auipc	ra,0xffffe
    80002cb8:	8e2080e7          	jalr	-1822(ra) # 80000596 <printf>
    panic("kerneltrap");
    80002cbc:	00005517          	auipc	a0,0x5
    80002cc0:	7ac50513          	addi	a0,a0,1964 # 80008468 <states.0+0x130>
    80002cc4:	ffffe097          	auipc	ra,0xffffe
    80002cc8:	888080e7          	jalr	-1912(ra) # 8000054c <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002ccc:	fffff097          	auipc	ra,0xfffff
    80002cd0:	066080e7          	jalr	102(ra) # 80001d32 <myproc>
    80002cd4:	d541                	beqz	a0,80002c5c <kerneltrap+0x38>
    80002cd6:	fffff097          	auipc	ra,0xfffff
    80002cda:	05c080e7          	jalr	92(ra) # 80001d32 <myproc>
    80002cde:	5118                	lw	a4,32(a0)
    80002ce0:	478d                	li	a5,3
    80002ce2:	f6f71de3          	bne	a4,a5,80002c5c <kerneltrap+0x38>
    yield();
    80002ce6:	00000097          	auipc	ra,0x0
    80002cea:	828080e7          	jalr	-2008(ra) # 8000250e <yield>
    80002cee:	b7bd                	j	80002c5c <kerneltrap+0x38>

0000000080002cf0 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002cf0:	1101                	addi	sp,sp,-32
    80002cf2:	ec06                	sd	ra,24(sp)
    80002cf4:	e822                	sd	s0,16(sp)
    80002cf6:	e426                	sd	s1,8(sp)
    80002cf8:	1000                	addi	s0,sp,32
    80002cfa:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002cfc:	fffff097          	auipc	ra,0xfffff
    80002d00:	036080e7          	jalr	54(ra) # 80001d32 <myproc>
  switch (n) {
    80002d04:	4795                	li	a5,5
    80002d06:	0497e163          	bltu	a5,s1,80002d48 <argraw+0x58>
    80002d0a:	048a                	slli	s1,s1,0x2
    80002d0c:	00005717          	auipc	a4,0x5
    80002d10:	79470713          	addi	a4,a4,1940 # 800084a0 <states.0+0x168>
    80002d14:	94ba                	add	s1,s1,a4
    80002d16:	409c                	lw	a5,0(s1)
    80002d18:	97ba                	add	a5,a5,a4
    80002d1a:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002d1c:	713c                	ld	a5,96(a0)
    80002d1e:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002d20:	60e2                	ld	ra,24(sp)
    80002d22:	6442                	ld	s0,16(sp)
    80002d24:	64a2                	ld	s1,8(sp)
    80002d26:	6105                	addi	sp,sp,32
    80002d28:	8082                	ret
    return p->trapframe->a1;
    80002d2a:	713c                	ld	a5,96(a0)
    80002d2c:	7fa8                	ld	a0,120(a5)
    80002d2e:	bfcd                	j	80002d20 <argraw+0x30>
    return p->trapframe->a2;
    80002d30:	713c                	ld	a5,96(a0)
    80002d32:	63c8                	ld	a0,128(a5)
    80002d34:	b7f5                	j	80002d20 <argraw+0x30>
    return p->trapframe->a3;
    80002d36:	713c                	ld	a5,96(a0)
    80002d38:	67c8                	ld	a0,136(a5)
    80002d3a:	b7dd                	j	80002d20 <argraw+0x30>
    return p->trapframe->a4;
    80002d3c:	713c                	ld	a5,96(a0)
    80002d3e:	6bc8                	ld	a0,144(a5)
    80002d40:	b7c5                	j	80002d20 <argraw+0x30>
    return p->trapframe->a5;
    80002d42:	713c                	ld	a5,96(a0)
    80002d44:	6fc8                	ld	a0,152(a5)
    80002d46:	bfe9                	j	80002d20 <argraw+0x30>
  panic("argraw");
    80002d48:	00005517          	auipc	a0,0x5
    80002d4c:	73050513          	addi	a0,a0,1840 # 80008478 <states.0+0x140>
    80002d50:	ffffd097          	auipc	ra,0xffffd
    80002d54:	7fc080e7          	jalr	2044(ra) # 8000054c <panic>

0000000080002d58 <fetchaddr>:
{
    80002d58:	1101                	addi	sp,sp,-32
    80002d5a:	ec06                	sd	ra,24(sp)
    80002d5c:	e822                	sd	s0,16(sp)
    80002d5e:	e426                	sd	s1,8(sp)
    80002d60:	e04a                	sd	s2,0(sp)
    80002d62:	1000                	addi	s0,sp,32
    80002d64:	84aa                	mv	s1,a0
    80002d66:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002d68:	fffff097          	auipc	ra,0xfffff
    80002d6c:	fca080e7          	jalr	-54(ra) # 80001d32 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002d70:	693c                	ld	a5,80(a0)
    80002d72:	02f4f863          	bgeu	s1,a5,80002da2 <fetchaddr+0x4a>
    80002d76:	00848713          	addi	a4,s1,8
    80002d7a:	02e7e663          	bltu	a5,a4,80002da6 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002d7e:	46a1                	li	a3,8
    80002d80:	8626                	mv	a2,s1
    80002d82:	85ca                	mv	a1,s2
    80002d84:	6d28                	ld	a0,88(a0)
    80002d86:	fffff097          	auipc	ra,0xfffff
    80002d8a:	d2e080e7          	jalr	-722(ra) # 80001ab4 <copyin>
    80002d8e:	00a03533          	snez	a0,a0
    80002d92:	40a00533          	neg	a0,a0
}
    80002d96:	60e2                	ld	ra,24(sp)
    80002d98:	6442                	ld	s0,16(sp)
    80002d9a:	64a2                	ld	s1,8(sp)
    80002d9c:	6902                	ld	s2,0(sp)
    80002d9e:	6105                	addi	sp,sp,32
    80002da0:	8082                	ret
    return -1;
    80002da2:	557d                	li	a0,-1
    80002da4:	bfcd                	j	80002d96 <fetchaddr+0x3e>
    80002da6:	557d                	li	a0,-1
    80002da8:	b7fd                	j	80002d96 <fetchaddr+0x3e>

0000000080002daa <fetchstr>:
{
    80002daa:	7179                	addi	sp,sp,-48
    80002dac:	f406                	sd	ra,40(sp)
    80002dae:	f022                	sd	s0,32(sp)
    80002db0:	ec26                	sd	s1,24(sp)
    80002db2:	e84a                	sd	s2,16(sp)
    80002db4:	e44e                	sd	s3,8(sp)
    80002db6:	1800                	addi	s0,sp,48
    80002db8:	892a                	mv	s2,a0
    80002dba:	84ae                	mv	s1,a1
    80002dbc:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002dbe:	fffff097          	auipc	ra,0xfffff
    80002dc2:	f74080e7          	jalr	-140(ra) # 80001d32 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002dc6:	86ce                	mv	a3,s3
    80002dc8:	864a                	mv	a2,s2
    80002dca:	85a6                	mv	a1,s1
    80002dcc:	6d28                	ld	a0,88(a0)
    80002dce:	fffff097          	auipc	ra,0xfffff
    80002dd2:	d74080e7          	jalr	-652(ra) # 80001b42 <copyinstr>
  if(err < 0)
    80002dd6:	00054763          	bltz	a0,80002de4 <fetchstr+0x3a>
  return strlen(buf);
    80002dda:	8526                	mv	a0,s1
    80002ddc:	ffffe097          	auipc	ra,0xffffe
    80002de0:	474080e7          	jalr	1140(ra) # 80001250 <strlen>
}
    80002de4:	70a2                	ld	ra,40(sp)
    80002de6:	7402                	ld	s0,32(sp)
    80002de8:	64e2                	ld	s1,24(sp)
    80002dea:	6942                	ld	s2,16(sp)
    80002dec:	69a2                	ld	s3,8(sp)
    80002dee:	6145                	addi	sp,sp,48
    80002df0:	8082                	ret

0000000080002df2 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002df2:	1101                	addi	sp,sp,-32
    80002df4:	ec06                	sd	ra,24(sp)
    80002df6:	e822                	sd	s0,16(sp)
    80002df8:	e426                	sd	s1,8(sp)
    80002dfa:	1000                	addi	s0,sp,32
    80002dfc:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002dfe:	00000097          	auipc	ra,0x0
    80002e02:	ef2080e7          	jalr	-270(ra) # 80002cf0 <argraw>
    80002e06:	c088                	sw	a0,0(s1)
  return 0;
}
    80002e08:	4501                	li	a0,0
    80002e0a:	60e2                	ld	ra,24(sp)
    80002e0c:	6442                	ld	s0,16(sp)
    80002e0e:	64a2                	ld	s1,8(sp)
    80002e10:	6105                	addi	sp,sp,32
    80002e12:	8082                	ret

0000000080002e14 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002e14:	1101                	addi	sp,sp,-32
    80002e16:	ec06                	sd	ra,24(sp)
    80002e18:	e822                	sd	s0,16(sp)
    80002e1a:	e426                	sd	s1,8(sp)
    80002e1c:	1000                	addi	s0,sp,32
    80002e1e:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002e20:	00000097          	auipc	ra,0x0
    80002e24:	ed0080e7          	jalr	-304(ra) # 80002cf0 <argraw>
    80002e28:	e088                	sd	a0,0(s1)
  return 0;
}
    80002e2a:	4501                	li	a0,0
    80002e2c:	60e2                	ld	ra,24(sp)
    80002e2e:	6442                	ld	s0,16(sp)
    80002e30:	64a2                	ld	s1,8(sp)
    80002e32:	6105                	addi	sp,sp,32
    80002e34:	8082                	ret

0000000080002e36 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002e36:	1101                	addi	sp,sp,-32
    80002e38:	ec06                	sd	ra,24(sp)
    80002e3a:	e822                	sd	s0,16(sp)
    80002e3c:	e426                	sd	s1,8(sp)
    80002e3e:	e04a                	sd	s2,0(sp)
    80002e40:	1000                	addi	s0,sp,32
    80002e42:	84ae                	mv	s1,a1
    80002e44:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002e46:	00000097          	auipc	ra,0x0
    80002e4a:	eaa080e7          	jalr	-342(ra) # 80002cf0 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002e4e:	864a                	mv	a2,s2
    80002e50:	85a6                	mv	a1,s1
    80002e52:	00000097          	auipc	ra,0x0
    80002e56:	f58080e7          	jalr	-168(ra) # 80002daa <fetchstr>
}
    80002e5a:	60e2                	ld	ra,24(sp)
    80002e5c:	6442                	ld	s0,16(sp)
    80002e5e:	64a2                	ld	s1,8(sp)
    80002e60:	6902                	ld	s2,0(sp)
    80002e62:	6105                	addi	sp,sp,32
    80002e64:	8082                	ret

0000000080002e66 <syscall>:
[SYS_close]   sys_close,
};

void
syscall(void)
{
    80002e66:	1101                	addi	sp,sp,-32
    80002e68:	ec06                	sd	ra,24(sp)
    80002e6a:	e822                	sd	s0,16(sp)
    80002e6c:	e426                	sd	s1,8(sp)
    80002e6e:	e04a                	sd	s2,0(sp)
    80002e70:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002e72:	fffff097          	auipc	ra,0xfffff
    80002e76:	ec0080e7          	jalr	-320(ra) # 80001d32 <myproc>
    80002e7a:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002e7c:	06053903          	ld	s2,96(a0)
    80002e80:	0a893783          	ld	a5,168(s2)
    80002e84:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002e88:	37fd                	addiw	a5,a5,-1
    80002e8a:	4751                	li	a4,20
    80002e8c:	00f76f63          	bltu	a4,a5,80002eaa <syscall+0x44>
    80002e90:	00369713          	slli	a4,a3,0x3
    80002e94:	00005797          	auipc	a5,0x5
    80002e98:	62478793          	addi	a5,a5,1572 # 800084b8 <syscalls>
    80002e9c:	97ba                	add	a5,a5,a4
    80002e9e:	639c                	ld	a5,0(a5)
    80002ea0:	c789                	beqz	a5,80002eaa <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80002ea2:	9782                	jalr	a5
    80002ea4:	06a93823          	sd	a0,112(s2)
    80002ea8:	a839                	j	80002ec6 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002eaa:	16048613          	addi	a2,s1,352
    80002eae:	40ac                	lw	a1,64(s1)
    80002eb0:	00005517          	auipc	a0,0x5
    80002eb4:	5d050513          	addi	a0,a0,1488 # 80008480 <states.0+0x148>
    80002eb8:	ffffd097          	auipc	ra,0xffffd
    80002ebc:	6de080e7          	jalr	1758(ra) # 80000596 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002ec0:	70bc                	ld	a5,96(s1)
    80002ec2:	577d                	li	a4,-1
    80002ec4:	fbb8                	sd	a4,112(a5)
  }
}
    80002ec6:	60e2                	ld	ra,24(sp)
    80002ec8:	6442                	ld	s0,16(sp)
    80002eca:	64a2                	ld	s1,8(sp)
    80002ecc:	6902                	ld	s2,0(sp)
    80002ece:	6105                	addi	sp,sp,32
    80002ed0:	8082                	ret

0000000080002ed2 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002ed2:	1101                	addi	sp,sp,-32
    80002ed4:	ec06                	sd	ra,24(sp)
    80002ed6:	e822                	sd	s0,16(sp)
    80002ed8:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002eda:	fec40593          	addi	a1,s0,-20
    80002ede:	4501                	li	a0,0
    80002ee0:	00000097          	auipc	ra,0x0
    80002ee4:	f12080e7          	jalr	-238(ra) # 80002df2 <argint>
    return -1;
    80002ee8:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002eea:	00054963          	bltz	a0,80002efc <sys_exit+0x2a>
  exit(n);
    80002eee:	fec42503          	lw	a0,-20(s0)
    80002ef2:	fffff097          	auipc	ra,0xfffff
    80002ef6:	512080e7          	jalr	1298(ra) # 80002404 <exit>
  return 0;  // not reached
    80002efa:	4781                	li	a5,0
}
    80002efc:	853e                	mv	a0,a5
    80002efe:	60e2                	ld	ra,24(sp)
    80002f00:	6442                	ld	s0,16(sp)
    80002f02:	6105                	addi	sp,sp,32
    80002f04:	8082                	ret

0000000080002f06 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002f06:	1141                	addi	sp,sp,-16
    80002f08:	e406                	sd	ra,8(sp)
    80002f0a:	e022                	sd	s0,0(sp)
    80002f0c:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002f0e:	fffff097          	auipc	ra,0xfffff
    80002f12:	e24080e7          	jalr	-476(ra) # 80001d32 <myproc>
}
    80002f16:	4128                	lw	a0,64(a0)
    80002f18:	60a2                	ld	ra,8(sp)
    80002f1a:	6402                	ld	s0,0(sp)
    80002f1c:	0141                	addi	sp,sp,16
    80002f1e:	8082                	ret

0000000080002f20 <sys_fork>:

uint64
sys_fork(void)
{
    80002f20:	1141                	addi	sp,sp,-16
    80002f22:	e406                	sd	ra,8(sp)
    80002f24:	e022                	sd	s0,0(sp)
    80002f26:	0800                	addi	s0,sp,16
  return fork();
    80002f28:	fffff097          	auipc	ra,0xfffff
    80002f2c:	1ce080e7          	jalr	462(ra) # 800020f6 <fork>
}
    80002f30:	60a2                	ld	ra,8(sp)
    80002f32:	6402                	ld	s0,0(sp)
    80002f34:	0141                	addi	sp,sp,16
    80002f36:	8082                	ret

0000000080002f38 <sys_wait>:

uint64
sys_wait(void)
{
    80002f38:	1101                	addi	sp,sp,-32
    80002f3a:	ec06                	sd	ra,24(sp)
    80002f3c:	e822                	sd	s0,16(sp)
    80002f3e:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002f40:	fe840593          	addi	a1,s0,-24
    80002f44:	4501                	li	a0,0
    80002f46:	00000097          	auipc	ra,0x0
    80002f4a:	ece080e7          	jalr	-306(ra) # 80002e14 <argaddr>
    80002f4e:	87aa                	mv	a5,a0
    return -1;
    80002f50:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002f52:	0007c863          	bltz	a5,80002f62 <sys_wait+0x2a>
  return wait(p);
    80002f56:	fe843503          	ld	a0,-24(s0)
    80002f5a:	fffff097          	auipc	ra,0xfffff
    80002f5e:	66e080e7          	jalr	1646(ra) # 800025c8 <wait>
}
    80002f62:	60e2                	ld	ra,24(sp)
    80002f64:	6442                	ld	s0,16(sp)
    80002f66:	6105                	addi	sp,sp,32
    80002f68:	8082                	ret

0000000080002f6a <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002f6a:	7179                	addi	sp,sp,-48
    80002f6c:	f406                	sd	ra,40(sp)
    80002f6e:	f022                	sd	s0,32(sp)
    80002f70:	ec26                	sd	s1,24(sp)
    80002f72:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002f74:	fdc40593          	addi	a1,s0,-36
    80002f78:	4501                	li	a0,0
    80002f7a:	00000097          	auipc	ra,0x0
    80002f7e:	e78080e7          	jalr	-392(ra) # 80002df2 <argint>
    80002f82:	87aa                	mv	a5,a0
    return -1;
    80002f84:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80002f86:	0207c063          	bltz	a5,80002fa6 <sys_sbrk+0x3c>
  addr = myproc()->sz;
    80002f8a:	fffff097          	auipc	ra,0xfffff
    80002f8e:	da8080e7          	jalr	-600(ra) # 80001d32 <myproc>
    80002f92:	4924                	lw	s1,80(a0)
  if(growproc(n) < 0)
    80002f94:	fdc42503          	lw	a0,-36(s0)
    80002f98:	fffff097          	auipc	ra,0xfffff
    80002f9c:	0e6080e7          	jalr	230(ra) # 8000207e <growproc>
    80002fa0:	00054863          	bltz	a0,80002fb0 <sys_sbrk+0x46>
    return -1;
  // printf("addr:%d\n", addr);
  return addr;
    80002fa4:	8526                	mv	a0,s1
}
    80002fa6:	70a2                	ld	ra,40(sp)
    80002fa8:	7402                	ld	s0,32(sp)
    80002faa:	64e2                	ld	s1,24(sp)
    80002fac:	6145                	addi	sp,sp,48
    80002fae:	8082                	ret
    return -1;
    80002fb0:	557d                	li	a0,-1
    80002fb2:	bfd5                	j	80002fa6 <sys_sbrk+0x3c>

0000000080002fb4 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002fb4:	7139                	addi	sp,sp,-64
    80002fb6:	fc06                	sd	ra,56(sp)
    80002fb8:	f822                	sd	s0,48(sp)
    80002fba:	f426                	sd	s1,40(sp)
    80002fbc:	f04a                	sd	s2,32(sp)
    80002fbe:	ec4e                	sd	s3,24(sp)
    80002fc0:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002fc2:	fcc40593          	addi	a1,s0,-52
    80002fc6:	4501                	li	a0,0
    80002fc8:	00000097          	auipc	ra,0x0
    80002fcc:	e2a080e7          	jalr	-470(ra) # 80002df2 <argint>
    return -1;
    80002fd0:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002fd2:	06054563          	bltz	a0,8000303c <sys_sleep+0x88>
  acquire(&tickslock);
    80002fd6:	00015517          	auipc	a0,0x15
    80002fda:	3d250513          	addi	a0,a0,978 # 800183a8 <tickslock>
    80002fde:	ffffe097          	auipc	ra,0xffffe
    80002fe2:	d0e080e7          	jalr	-754(ra) # 80000cec <acquire>
  ticks0 = ticks;
    80002fe6:	00006917          	auipc	s2,0x6
    80002fea:	03a92903          	lw	s2,58(s2) # 80009020 <ticks>
  while(ticks - ticks0 < n){
    80002fee:	fcc42783          	lw	a5,-52(s0)
    80002ff2:	cf85                	beqz	a5,8000302a <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002ff4:	00015997          	auipc	s3,0x15
    80002ff8:	3b498993          	addi	s3,s3,948 # 800183a8 <tickslock>
    80002ffc:	00006497          	auipc	s1,0x6
    80003000:	02448493          	addi	s1,s1,36 # 80009020 <ticks>
    if(myproc()->killed){
    80003004:	fffff097          	auipc	ra,0xfffff
    80003008:	d2e080e7          	jalr	-722(ra) # 80001d32 <myproc>
    8000300c:	5d1c                	lw	a5,56(a0)
    8000300e:	ef9d                	bnez	a5,8000304c <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80003010:	85ce                	mv	a1,s3
    80003012:	8526                	mv	a0,s1
    80003014:	fffff097          	auipc	ra,0xfffff
    80003018:	536080e7          	jalr	1334(ra) # 8000254a <sleep>
  while(ticks - ticks0 < n){
    8000301c:	409c                	lw	a5,0(s1)
    8000301e:	412787bb          	subw	a5,a5,s2
    80003022:	fcc42703          	lw	a4,-52(s0)
    80003026:	fce7efe3          	bltu	a5,a4,80003004 <sys_sleep+0x50>
  }
  release(&tickslock);
    8000302a:	00015517          	auipc	a0,0x15
    8000302e:	37e50513          	addi	a0,a0,894 # 800183a8 <tickslock>
    80003032:	ffffe097          	auipc	ra,0xffffe
    80003036:	d8a080e7          	jalr	-630(ra) # 80000dbc <release>
  return 0;
    8000303a:	4781                	li	a5,0
}
    8000303c:	853e                	mv	a0,a5
    8000303e:	70e2                	ld	ra,56(sp)
    80003040:	7442                	ld	s0,48(sp)
    80003042:	74a2                	ld	s1,40(sp)
    80003044:	7902                	ld	s2,32(sp)
    80003046:	69e2                	ld	s3,24(sp)
    80003048:	6121                	addi	sp,sp,64
    8000304a:	8082                	ret
      release(&tickslock);
    8000304c:	00015517          	auipc	a0,0x15
    80003050:	35c50513          	addi	a0,a0,860 # 800183a8 <tickslock>
    80003054:	ffffe097          	auipc	ra,0xffffe
    80003058:	d68080e7          	jalr	-664(ra) # 80000dbc <release>
      return -1;
    8000305c:	57fd                	li	a5,-1
    8000305e:	bff9                	j	8000303c <sys_sleep+0x88>

0000000080003060 <sys_kill>:

uint64
sys_kill(void)
{
    80003060:	1101                	addi	sp,sp,-32
    80003062:	ec06                	sd	ra,24(sp)
    80003064:	e822                	sd	s0,16(sp)
    80003066:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80003068:	fec40593          	addi	a1,s0,-20
    8000306c:	4501                	li	a0,0
    8000306e:	00000097          	auipc	ra,0x0
    80003072:	d84080e7          	jalr	-636(ra) # 80002df2 <argint>
    80003076:	87aa                	mv	a5,a0
    return -1;
    80003078:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    8000307a:	0007c863          	bltz	a5,8000308a <sys_kill+0x2a>
  return kill(pid);
    8000307e:	fec42503          	lw	a0,-20(s0)
    80003082:	fffff097          	auipc	ra,0xfffff
    80003086:	6b2080e7          	jalr	1714(ra) # 80002734 <kill>
}
    8000308a:	60e2                	ld	ra,24(sp)
    8000308c:	6442                	ld	s0,16(sp)
    8000308e:	6105                	addi	sp,sp,32
    80003090:	8082                	ret

0000000080003092 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80003092:	1101                	addi	sp,sp,-32
    80003094:	ec06                	sd	ra,24(sp)
    80003096:	e822                	sd	s0,16(sp)
    80003098:	e426                	sd	s1,8(sp)
    8000309a:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    8000309c:	00015517          	auipc	a0,0x15
    800030a0:	30c50513          	addi	a0,a0,780 # 800183a8 <tickslock>
    800030a4:	ffffe097          	auipc	ra,0xffffe
    800030a8:	c48080e7          	jalr	-952(ra) # 80000cec <acquire>
  xticks = ticks;
    800030ac:	00006497          	auipc	s1,0x6
    800030b0:	f744a483          	lw	s1,-140(s1) # 80009020 <ticks>
  release(&tickslock);
    800030b4:	00015517          	auipc	a0,0x15
    800030b8:	2f450513          	addi	a0,a0,756 # 800183a8 <tickslock>
    800030bc:	ffffe097          	auipc	ra,0xffffe
    800030c0:	d00080e7          	jalr	-768(ra) # 80000dbc <release>
  return xticks;
}
    800030c4:	02049513          	slli	a0,s1,0x20
    800030c8:	9101                	srli	a0,a0,0x20
    800030ca:	60e2                	ld	ra,24(sp)
    800030cc:	6442                	ld	s0,16(sp)
    800030ce:	64a2                	ld	s1,8(sp)
    800030d0:	6105                	addi	sp,sp,32
    800030d2:	8082                	ret

00000000800030d4 <map>:
  // Sorted by how recently the buffer was used.
  // head.next is most recent, head.prev is least.
  struct buf heads[NBUCKETS];
} bcache;

int map(int blockno){
    800030d4:	1141                	addi	sp,sp,-16
    800030d6:	e422                	sd	s0,8(sp)
    800030d8:	0800                	addi	s0,sp,16
  // random one to one cycle mapping
  return blockno%NBUCKETS;
}
    800030da:	47c5                	li	a5,17
    800030dc:	02f5653b          	remw	a0,a0,a5
    800030e0:	6422                	ld	s0,8(sp)
    800030e2:	0141                	addi	sp,sp,16
    800030e4:	8082                	ret

00000000800030e6 <binit>:

void binit(void)
{
    800030e6:	711d                	addi	sp,sp,-96
    800030e8:	ec86                	sd	ra,88(sp)
    800030ea:	e8a2                	sd	s0,80(sp)
    800030ec:	e4a6                	sd	s1,72(sp)
    800030ee:	e0ca                	sd	s2,64(sp)
    800030f0:	fc4e                	sd	s3,56(sp)
    800030f2:	f852                	sd	s4,48(sp)
    800030f4:	f456                	sd	s5,40(sp)
    800030f6:	f05a                	sd	s6,32(sp)
    800030f8:	ec5e                	sd	s7,24(sp)
    800030fa:	e862                	sd	s8,16(sp)
    800030fc:	e466                	sd	s9,8(sp)
    800030fe:	e06a                	sd	s10,0(sp)
    80003100:	1080                	addi	s0,sp,96
  struct buf *b;
  int bid = 0;

  // Create linked list of buffers
  for (bid = 0; bid < NBUCKETS; bid++)
    80003102:	00015917          	auipc	s2,0x15
    80003106:	2c690913          	addi	s2,s2,710 # 800183c8 <bcache>
    8000310a:	0001e497          	auipc	s1,0x1e
    8000310e:	81e48493          	addi	s1,s1,-2018 # 80020928 <bcache+0x8560>
    80003112:	00022a17          	auipc	s4,0x22
    80003116:	276a0a13          	addi	s4,s4,630 # 80025388 <sb>
  {
    initlock(&bcache.lock[bid], "bcache");
    8000311a:	00005997          	auipc	s3,0x5
    8000311e:	fe698993          	addi	s3,s3,-26 # 80008100 <digits+0xc0>
    80003122:	85ce                	mv	a1,s3
    80003124:	854a                	mv	a0,s2
    80003126:	ffffe097          	auipc	ra,0xffffe
    8000312a:	d42080e7          	jalr	-702(ra) # 80000e68 <initlock>
    bcache.heads[bid].prev = &bcache.heads[bid];
    8000312e:	e8a4                	sd	s1,80(s1)
    bcache.heads[bid].next = &bcache.heads[bid];
    80003130:	eca4                	sd	s1,88(s1)
  for (bid = 0; bid < NBUCKETS; bid++)
    80003132:	02090913          	addi	s2,s2,32
    80003136:	46048493          	addi	s1,s1,1120
    8000313a:	ff4494e3          	bne	s1,s4,80003122 <binit+0x3c>
  }
  int bno = 0;
    8000313e:	4981                	li	s3,0
  for (b = bcache.buf; b < bcache.buf + NBUF; b++)
    80003140:	00015497          	auipc	s1,0x15
    80003144:	4a848493          	addi	s1,s1,1192 # 800185e8 <bcache+0x220>
  return blockno%NBUCKETS;
    80003148:	4d45                	li	s10,17
  {
    // printf("blockno:%d\n", bno);
    int m_no = map(bno);
    b->next = bcache.heads[m_no].next;
    8000314a:	00015a17          	auipc	s4,0x15
    8000314e:	27ea0a13          	addi	s4,s4,638 # 800183c8 <bcache>
    80003152:	46000c93          	li	s9,1120
    80003156:	6aa1                	lui	s5,0x8
    b->prev = &bcache.heads[m_no];
    80003158:	560a8c13          	addi	s8,s5,1376 # 8560 <_entry-0x7fff7aa0>
    // b->top = bno;
    initsleeplock(&b->lock, "buffer");
    8000315c:	00005b97          	auipc	s7,0x5
    80003160:	40cb8b93          	addi	s7,s7,1036 # 80008568 <syscalls+0xb0>
  for (b = bcache.buf; b < bcache.buf + NBUF; b++)
    80003164:	0001db17          	auipc	s6,0x1d
    80003168:	7c4b0b13          	addi	s6,s6,1988 # 80020928 <bcache+0x8560>
  return blockno%NBUCKETS;
    8000316c:	03a9e7bb          	remw	a5,s3,s10
    b->next = bcache.heads[m_no].next;
    80003170:	039787b3          	mul	a5,a5,s9
    80003174:	00fa0933          	add	s2,s4,a5
    80003178:	9956                	add	s2,s2,s5
    8000317a:	5b893703          	ld	a4,1464(s2)
    8000317e:	ecb8                	sd	a4,88(s1)
    b->prev = &bcache.heads[m_no];
    80003180:	97e2                	add	a5,a5,s8
    80003182:	97d2                	add	a5,a5,s4
    80003184:	e8bc                	sd	a5,80(s1)
    initsleeplock(&b->lock, "buffer");
    80003186:	85de                	mv	a1,s7
    80003188:	01048513          	addi	a0,s1,16
    8000318c:	00001097          	auipc	ra,0x1
    80003190:	620080e7          	jalr	1568(ra) # 800047ac <initsleeplock>
    bcache.heads[m_no].next->prev = b;
    80003194:	5b893783          	ld	a5,1464(s2)
    80003198:	eba4                	sd	s1,80(a5)
    bcache.heads[m_no].next = b;
    8000319a:	5a993c23          	sd	s1,1464(s2)
    bno++;
    8000319e:	2985                	addiw	s3,s3,1
  for (b = bcache.buf; b < bcache.buf + NBUF; b++)
    800031a0:	46048493          	addi	s1,s1,1120
    800031a4:	fd6494e3          	bne	s1,s6,8000316c <binit+0x86>
  }
}
    800031a8:	60e6                	ld	ra,88(sp)
    800031aa:	6446                	ld	s0,80(sp)
    800031ac:	64a6                	ld	s1,72(sp)
    800031ae:	6906                	ld	s2,64(sp)
    800031b0:	79e2                	ld	s3,56(sp)
    800031b2:	7a42                	ld	s4,48(sp)
    800031b4:	7aa2                	ld	s5,40(sp)
    800031b6:	7b02                	ld	s6,32(sp)
    800031b8:	6be2                	ld	s7,24(sp)
    800031ba:	6c42                	ld	s8,16(sp)
    800031bc:	6ca2                	ld	s9,8(sp)
    800031be:	6d02                	ld	s10,0(sp)
    800031c0:	6125                	addi	sp,sp,96
    800031c2:	8082                	ret

00000000800031c4 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf *
bread(uint dev, uint blockno)
{
    800031c4:	7159                	addi	sp,sp,-112
    800031c6:	f486                	sd	ra,104(sp)
    800031c8:	f0a2                	sd	s0,96(sp)
    800031ca:	eca6                	sd	s1,88(sp)
    800031cc:	e8ca                	sd	s2,80(sp)
    800031ce:	e4ce                	sd	s3,72(sp)
    800031d0:	e0d2                	sd	s4,64(sp)
    800031d2:	fc56                	sd	s5,56(sp)
    800031d4:	f85a                	sd	s6,48(sp)
    800031d6:	f45e                	sd	s7,40(sp)
    800031d8:	f062                	sd	s8,32(sp)
    800031da:	ec66                	sd	s9,24(sp)
    800031dc:	e86a                	sd	s10,16(sp)
    800031de:	e46e                	sd	s11,8(sp)
    800031e0:	1880                	addi	s0,sp,112
    800031e2:	89aa                	mv	s3,a0
    800031e4:	8a2e                	mv	s4,a1
  return blockno%NBUCKETS;
    800031e6:	4ac5                	li	s5,17
    800031e8:	0355eabb          	remw	s5,a1,s5
  acquire(&bcache.lock[bid]);
    800031ec:	005a9b93          	slli	s7,s5,0x5
    800031f0:	00015b17          	auipc	s6,0x15
    800031f4:	1d8b0b13          	addi	s6,s6,472 # 800183c8 <bcache>
    800031f8:	9bda                	add	s7,s7,s6
    800031fa:	855e                	mv	a0,s7
    800031fc:	ffffe097          	auipc	ra,0xffffe
    80003200:	af0080e7          	jalr	-1296(ra) # 80000cec <acquire>
  for (b = bcache.heads[bid].next; b != &bcache.heads[bid]; b = b->next)
    80003204:	46000913          	li	s2,1120
    80003208:	032a8933          	mul	s2,s5,s2
    8000320c:	012b0733          	add	a4,s6,s2
    80003210:	67a1                	lui	a5,0x8
    80003212:	973e                	add	a4,a4,a5
    80003214:	5b873483          	ld	s1,1464(a4)
    80003218:	56078793          	addi	a5,a5,1376 # 8560 <_entry-0x7fff7aa0>
    8000321c:	993e                	add	s2,s2,a5
    8000321e:	995a                	add	s2,s2,s6
    80003220:	05249863          	bne	s1,s2,80003270 <bread+0xac>
  for (b = bcache.heads[bid].prev; b != &bcache.heads[bid]; b = b->prev)
    80003224:	46000793          	li	a5,1120
    80003228:	02fa87b3          	mul	a5,s5,a5
    8000322c:	00015717          	auipc	a4,0x15
    80003230:	19c70713          	addi	a4,a4,412 # 800183c8 <bcache>
    80003234:	973e                	add	a4,a4,a5
    80003236:	67a1                	lui	a5,0x8
    80003238:	97ba                	add	a5,a5,a4
    8000323a:	5b07b483          	ld	s1,1456(a5) # 85b0 <_entry-0x7fff7a50>
    8000323e:	01248763          	beq	s1,s2,8000324c <bread+0x88>
    if (b->refcnt == 0)
    80003242:	44bc                	lw	a5,72(s1)
    80003244:	cbb9                	beqz	a5,8000329a <bread+0xd6>
  for (b = bcache.heads[bid].prev; b != &bcache.heads[bid]; b = b->prev)
    80003246:	68a4                	ld	s1,80(s1)
    80003248:	ff249de3          	bne	s1,s2,80003242 <bread+0x7e>
  for (int bkid = map(blockno+1); bkid != bid; bkid=map(bkid+1))
    8000324c:	001a0b1b          	addiw	s6,s4,1
  return blockno%NBUCKETS;
    80003250:	47c5                	li	a5,17
    80003252:	02fb6b3b          	remw	s6,s6,a5
  for (int bkid = map(blockno+1); bkid != bid; bkid=map(bkid+1))
    80003256:	156a8263          	beq	s5,s6,8000339a <bread+0x1d6>
    acquire(&bcache.lock[bkid]);
    8000325a:	00015c97          	auipc	s9,0x15
    8000325e:	16ec8c93          	addi	s9,s9,366 # 800183c8 <bcache>
    for (b = bcache.heads[bkid].next; b != &bcache.heads[bkid]; b = b->next)
    80003262:	46000d93          	li	s11,1120
    80003266:	6d21                	lui	s10,0x8
    80003268:	a8ed                	j	80003362 <bread+0x19e>
  for (b = bcache.heads[bid].next; b != &bcache.heads[bid]; b = b->next)
    8000326a:	6ca4                	ld	s1,88(s1)
    8000326c:	fb248ce3          	beq	s1,s2,80003224 <bread+0x60>
    if (b->dev == dev && b->blockno == blockno)
    80003270:	449c                	lw	a5,8(s1)
    80003272:	ff379ce3          	bne	a5,s3,8000326a <bread+0xa6>
    80003276:	44dc                	lw	a5,12(s1)
    80003278:	ff4799e3          	bne	a5,s4,8000326a <bread+0xa6>
      b->refcnt++;
    8000327c:	44bc                	lw	a5,72(s1)
    8000327e:	2785                	addiw	a5,a5,1
    80003280:	c4bc                	sw	a5,72(s1)
      release(&bcache.lock[bid]);
    80003282:	855e                	mv	a0,s7
    80003284:	ffffe097          	auipc	ra,0xffffe
    80003288:	b38080e7          	jalr	-1224(ra) # 80000dbc <release>
      acquiresleep(&b->lock);
    8000328c:	01048513          	addi	a0,s1,16
    80003290:	00001097          	auipc	ra,0x1
    80003294:	556080e7          	jalr	1366(ra) # 800047e6 <acquiresleep>
      return b;
    80003298:	a841                	j	80003328 <bread+0x164>
      b->dev = dev;
    8000329a:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    8000329e:	0144a623          	sw	s4,12(s1)
      b->valid = 0;
    800032a2:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    800032a6:	4785                	li	a5,1
    800032a8:	c4bc                	sw	a5,72(s1)
      release(&bcache.lock[bid]);
    800032aa:	855e                	mv	a0,s7
    800032ac:	ffffe097          	auipc	ra,0xffffe
    800032b0:	b10080e7          	jalr	-1264(ra) # 80000dbc <release>
      acquiresleep(&b->lock);
    800032b4:	01048513          	addi	a0,s1,16
    800032b8:	00001097          	auipc	ra,0x1
    800032bc:	52e080e7          	jalr	1326(ra) # 800047e6 <acquiresleep>
      return b;
    800032c0:	a0a5                	j	80003328 <bread+0x164>
        b->valid = 0;
    800032c2:	0004a023          	sw	zero,0(s1)
        b->refcnt = 1;
    800032c6:	4785                	li	a5,1
    800032c8:	c4bc                	sw	a5,72(s1)
        b->blockno = blockno;
    800032ca:	0144a623          	sw	s4,12(s1)
        b->dev = dev;
    800032ce:	0134a423          	sw	s3,8(s1)
        b->prev->next = b->next;
    800032d2:	68bc                	ld	a5,80(s1)
    800032d4:	6cb8                	ld	a4,88(s1)
    800032d6:	efb8                	sd	a4,88(a5)
        b->next->prev = b->prev; // fetch from ori list
    800032d8:	6cbc                	ld	a5,88(s1)
    800032da:	68b8                	ld	a4,80(s1)
    800032dc:	ebb8                	sd	a4,80(a5)
        release(&bcache.lock[bkid]);
    800032de:	8562                	mv	a0,s8
    800032e0:	ffffe097          	auipc	ra,0xffffe
    800032e4:	adc080e7          	jalr	-1316(ra) # 80000dbc <release>
        b->next = bcache.heads[bid].next;
    800032e8:	46000793          	li	a5,1120
    800032ec:	02fa8ab3          	mul	s5,s5,a5
    800032f0:	00015717          	auipc	a4,0x15
    800032f4:	0d870713          	addi	a4,a4,216 # 800183c8 <bcache>
    800032f8:	9756                	add	a4,a4,s5
    800032fa:	67a1                	lui	a5,0x8
    800032fc:	97ba                	add	a5,a5,a4
    800032fe:	5b87b703          	ld	a4,1464(a5) # 85b8 <_entry-0x7fff7a48>
    80003302:	ecb8                	sd	a4,88(s1)
        b->prev = &bcache.heads[bid];
    80003304:	0524b823          	sd	s2,80(s1)
        bcache.heads[bid].next->prev = b;
    80003308:	5b87b703          	ld	a4,1464(a5)
    8000330c:	eb24                	sd	s1,80(a4)
        bcache.heads[bid].next = b;
    8000330e:	5a97bc23          	sd	s1,1464(a5)
        release(&bcache.lock[bid]);
    80003312:	855e                	mv	a0,s7
    80003314:	ffffe097          	auipc	ra,0xffffe
    80003318:	aa8080e7          	jalr	-1368(ra) # 80000dbc <release>
        acquiresleep(&b->lock);
    8000331c:	01048513          	addi	a0,s1,16
    80003320:	00001097          	auipc	ra,0x1
    80003324:	4c6080e7          	jalr	1222(ra) # 800047e6 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if (!b->valid)
    80003328:	409c                	lw	a5,0(s1)
    8000332a:	c3c1                	beqz	a5,800033aa <bread+0x1e6>
  {
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    8000332c:	8526                	mv	a0,s1
    8000332e:	70a6                	ld	ra,104(sp)
    80003330:	7406                	ld	s0,96(sp)
    80003332:	64e6                	ld	s1,88(sp)
    80003334:	6946                	ld	s2,80(sp)
    80003336:	69a6                	ld	s3,72(sp)
    80003338:	6a06                	ld	s4,64(sp)
    8000333a:	7ae2                	ld	s5,56(sp)
    8000333c:	7b42                	ld	s6,48(sp)
    8000333e:	7ba2                	ld	s7,40(sp)
    80003340:	7c02                	ld	s8,32(sp)
    80003342:	6ce2                	ld	s9,24(sp)
    80003344:	6d42                	ld	s10,16(sp)
    80003346:	6da2                	ld	s11,8(sp)
    80003348:	6165                	addi	sp,sp,112
    8000334a:	8082                	ret
    release(&bcache.lock[bkid]);
    8000334c:	8562                	mv	a0,s8
    8000334e:	ffffe097          	auipc	ra,0xffffe
    80003352:	a6e080e7          	jalr	-1426(ra) # 80000dbc <release>
  for (int bkid = map(blockno+1); bkid != bid; bkid=map(bkid+1))
    80003356:	2b05                	addiw	s6,s6,1
  return blockno%NBUCKETS;
    80003358:	47c5                	li	a5,17
    8000335a:	02fb6b3b          	remw	s6,s6,a5
  for (int bkid = map(blockno+1); bkid != bid; bkid=map(bkid+1))
    8000335e:	036a8e63          	beq	s5,s6,8000339a <bread+0x1d6>
    acquire(&bcache.lock[bkid]);
    80003362:	005b1c13          	slli	s8,s6,0x5
    80003366:	9c66                	add	s8,s8,s9
    80003368:	8562                	mv	a0,s8
    8000336a:	ffffe097          	auipc	ra,0xffffe
    8000336e:	982080e7          	jalr	-1662(ra) # 80000cec <acquire>
    for (b = bcache.heads[bkid].next; b != &bcache.heads[bkid]; b = b->next)
    80003372:	03bb0733          	mul	a4,s6,s11
    80003376:	00ec87b3          	add	a5,s9,a4
    8000337a:	97ea                	add	a5,a5,s10
    8000337c:	5b87b483          	ld	s1,1464(a5)
    80003380:	67a1                	lui	a5,0x8
    80003382:	56078793          	addi	a5,a5,1376 # 8560 <_entry-0x7fff7aa0>
    80003386:	973e                	add	a4,a4,a5
    80003388:	9766                	add	a4,a4,s9
    8000338a:	fc9701e3          	beq	a4,s1,8000334c <bread+0x188>
      if (b->refcnt == 0)
    8000338e:	44bc                	lw	a5,72(s1)
    80003390:	db8d                	beqz	a5,800032c2 <bread+0xfe>
    for (b = bcache.heads[bkid].next; b != &bcache.heads[bkid]; b = b->next)
    80003392:	6ca4                	ld	s1,88(s1)
    80003394:	fe971de3          	bne	a4,s1,8000338e <bread+0x1ca>
    80003398:	bf55                	j	8000334c <bread+0x188>
  panic("bget: no buffers");
    8000339a:	00005517          	auipc	a0,0x5
    8000339e:	1d650513          	addi	a0,a0,470 # 80008570 <syscalls+0xb8>
    800033a2:	ffffd097          	auipc	ra,0xffffd
    800033a6:	1aa080e7          	jalr	426(ra) # 8000054c <panic>
    virtio_disk_rw(b, 0);
    800033aa:	4581                	li	a1,0
    800033ac:	8526                	mv	a0,s1
    800033ae:	00003097          	auipc	ra,0x3
    800033b2:	fb4080e7          	jalr	-76(ra) # 80006362 <virtio_disk_rw>
    b->valid = 1;
    800033b6:	4785                	li	a5,1
    800033b8:	c09c                	sw	a5,0(s1)
  return b;
    800033ba:	bf8d                	j	8000332c <bread+0x168>

00000000800033bc <bwrite>:

// Write b's contents to disk.  Must be locked.
void bwrite(struct buf *b)
{
    800033bc:	1101                	addi	sp,sp,-32
    800033be:	ec06                	sd	ra,24(sp)
    800033c0:	e822                	sd	s0,16(sp)
    800033c2:	e426                	sd	s1,8(sp)
    800033c4:	1000                	addi	s0,sp,32
    800033c6:	84aa                	mv	s1,a0
  if (!holdingsleep(&b->lock))
    800033c8:	0541                	addi	a0,a0,16
    800033ca:	00001097          	auipc	ra,0x1
    800033ce:	4b6080e7          	jalr	1206(ra) # 80004880 <holdingsleep>
    800033d2:	cd01                	beqz	a0,800033ea <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    800033d4:	4585                	li	a1,1
    800033d6:	8526                	mv	a0,s1
    800033d8:	00003097          	auipc	ra,0x3
    800033dc:	f8a080e7          	jalr	-118(ra) # 80006362 <virtio_disk_rw>
}
    800033e0:	60e2                	ld	ra,24(sp)
    800033e2:	6442                	ld	s0,16(sp)
    800033e4:	64a2                	ld	s1,8(sp)
    800033e6:	6105                	addi	sp,sp,32
    800033e8:	8082                	ret
    panic("bwrite");
    800033ea:	00005517          	auipc	a0,0x5
    800033ee:	19e50513          	addi	a0,a0,414 # 80008588 <syscalls+0xd0>
    800033f2:	ffffd097          	auipc	ra,0xffffd
    800033f6:	15a080e7          	jalr	346(ra) # 8000054c <panic>

00000000800033fa <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void brelse(struct buf *b)
{
    800033fa:	7179                	addi	sp,sp,-48
    800033fc:	f406                	sd	ra,40(sp)
    800033fe:	f022                	sd	s0,32(sp)
    80003400:	ec26                	sd	s1,24(sp)
    80003402:	e84a                	sd	s2,16(sp)
    80003404:	e44e                	sd	s3,8(sp)
    80003406:	1800                	addi	s0,sp,48
    80003408:	84aa                	mv	s1,a0
  if (!holdingsleep(&b->lock))
    8000340a:	01050913          	addi	s2,a0,16
    8000340e:	854a                	mv	a0,s2
    80003410:	00001097          	auipc	ra,0x1
    80003414:	470080e7          	jalr	1136(ra) # 80004880 <holdingsleep>
    80003418:	c951                	beqz	a0,800034ac <brelse+0xb2>
  {
    panic("brelse");
  }

  releasesleep(&b->lock);//lock?
    8000341a:	854a                	mv	a0,s2
    8000341c:	00001097          	auipc	ra,0x1
    80003420:	420080e7          	jalr	1056(ra) # 8000483c <releasesleep>
  return blockno%NBUCKETS;
    80003424:	00c4a903          	lw	s2,12(s1)
    80003428:	47c5                	li	a5,17
    8000342a:	02f9693b          	remw	s2,s2,a5

  // acquire(&bcache.lock);
  int bid = map(b->blockno);
  acquire(&bcache.lock[bid]);
    8000342e:	00591993          	slli	s3,s2,0x5
    80003432:	00015797          	auipc	a5,0x15
    80003436:	f9678793          	addi	a5,a5,-106 # 800183c8 <bcache>
    8000343a:	99be                	add	s3,s3,a5
    8000343c:	854e                	mv	a0,s3
    8000343e:	ffffe097          	auipc	ra,0xffffe
    80003442:	8ae080e7          	jalr	-1874(ra) # 80000cec <acquire>
  b->refcnt--;
    80003446:	44bc                	lw	a5,72(s1)
    80003448:	37fd                	addiw	a5,a5,-1
    8000344a:	0007871b          	sext.w	a4,a5
    8000344e:	c4bc                	sw	a5,72(s1)

  if (b->refcnt == 0)
    80003450:	e331                	bnez	a4,80003494 <brelse+0x9a>
  {
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003452:	6cbc                	ld	a5,88(s1)
    80003454:	68b8                	ld	a4,80(s1)
    80003456:	ebb8                	sd	a4,80(a5)
    b->prev->next = b->next;
    80003458:	68bc                	ld	a5,80(s1)
    8000345a:	6cb8                	ld	a4,88(s1)
    8000345c:	efb8                	sd	a4,88(a5)
    b->next = bcache.heads[bid].next;
    8000345e:	00015697          	auipc	a3,0x15
    80003462:	f6a68693          	addi	a3,a3,-150 # 800183c8 <bcache>
    80003466:	46000613          	li	a2,1120
    8000346a:	02c907b3          	mul	a5,s2,a2
    8000346e:	97b6                	add	a5,a5,a3
    80003470:	6721                	lui	a4,0x8
    80003472:	97ba                	add	a5,a5,a4
    80003474:	5b87b583          	ld	a1,1464(a5)
    80003478:	ecac                	sd	a1,88(s1)
    b->prev = &bcache.heads[bid];
    8000347a:	02c90933          	mul	s2,s2,a2
    8000347e:	56070713          	addi	a4,a4,1376 # 8560 <_entry-0x7fff7aa0>
    80003482:	993a                	add	s2,s2,a4
    80003484:	9936                	add	s2,s2,a3
    80003486:	0524b823          	sd	s2,80(s1)
    bcache.heads[bid].next->prev = b;
    8000348a:	5b87b703          	ld	a4,1464(a5)
    8000348e:	eb24                	sd	s1,80(a4)
    bcache.heads[bid].next = b;
    80003490:	5a97bc23          	sd	s1,1464(a5)
    // break;
  }
  release(&bcache.lock[bid]);
    80003494:	854e                	mv	a0,s3
    80003496:	ffffe097          	auipc	ra,0xffffe
    8000349a:	926080e7          	jalr	-1754(ra) # 80000dbc <release>
  // }
}
    8000349e:	70a2                	ld	ra,40(sp)
    800034a0:	7402                	ld	s0,32(sp)
    800034a2:	64e2                	ld	s1,24(sp)
    800034a4:	6942                	ld	s2,16(sp)
    800034a6:	69a2                	ld	s3,8(sp)
    800034a8:	6145                	addi	sp,sp,48
    800034aa:	8082                	ret
    panic("brelse");
    800034ac:	00005517          	auipc	a0,0x5
    800034b0:	0e450513          	addi	a0,a0,228 # 80008590 <syscalls+0xd8>
    800034b4:	ffffd097          	auipc	ra,0xffffd
    800034b8:	098080e7          	jalr	152(ra) # 8000054c <panic>

00000000800034bc <bpin>:

void bpin(struct buf *b)
{
    800034bc:	1101                	addi	sp,sp,-32
    800034be:	ec06                	sd	ra,24(sp)
    800034c0:	e822                	sd	s0,16(sp)
    800034c2:	e426                	sd	s1,8(sp)
    800034c4:	e04a                	sd	s2,0(sp)
    800034c6:	1000                	addi	s0,sp,32
    800034c8:	892a                	mv	s2,a0
  return blockno%NBUCKETS;
    800034ca:	4544                	lw	s1,12(a0)
  int bid = map(b->blockno);
  acquire(&bcache.lock[bid]);
    800034cc:	47c5                	li	a5,17
    800034ce:	02f4e4bb          	remw	s1,s1,a5
    800034d2:	0496                	slli	s1,s1,0x5
    800034d4:	00015797          	auipc	a5,0x15
    800034d8:	ef478793          	addi	a5,a5,-268 # 800183c8 <bcache>
    800034dc:	94be                	add	s1,s1,a5
    800034de:	8526                	mv	a0,s1
    800034e0:	ffffe097          	auipc	ra,0xffffe
    800034e4:	80c080e7          	jalr	-2036(ra) # 80000cec <acquire>
  b->refcnt++;
    800034e8:	04892783          	lw	a5,72(s2)
    800034ec:	2785                	addiw	a5,a5,1
    800034ee:	04f92423          	sw	a5,72(s2)
  release(&bcache.lock[bid]);
    800034f2:	8526                	mv	a0,s1
    800034f4:	ffffe097          	auipc	ra,0xffffe
    800034f8:	8c8080e7          	jalr	-1848(ra) # 80000dbc <release>
}
    800034fc:	60e2                	ld	ra,24(sp)
    800034fe:	6442                	ld	s0,16(sp)
    80003500:	64a2                	ld	s1,8(sp)
    80003502:	6902                	ld	s2,0(sp)
    80003504:	6105                	addi	sp,sp,32
    80003506:	8082                	ret

0000000080003508 <bunpin>:

void bunpin(struct buf *b)
{
    80003508:	1101                	addi	sp,sp,-32
    8000350a:	ec06                	sd	ra,24(sp)
    8000350c:	e822                	sd	s0,16(sp)
    8000350e:	e426                	sd	s1,8(sp)
    80003510:	e04a                	sd	s2,0(sp)
    80003512:	1000                	addi	s0,sp,32
    80003514:	892a                	mv	s2,a0
  return blockno%NBUCKETS;
    80003516:	4544                	lw	s1,12(a0)
  int bid = map(b->blockno);
  acquire(&bcache.lock[bid]);
    80003518:	47c5                	li	a5,17
    8000351a:	02f4e4bb          	remw	s1,s1,a5
    8000351e:	0496                	slli	s1,s1,0x5
    80003520:	00015797          	auipc	a5,0x15
    80003524:	ea878793          	addi	a5,a5,-344 # 800183c8 <bcache>
    80003528:	94be                	add	s1,s1,a5
    8000352a:	8526                	mv	a0,s1
    8000352c:	ffffd097          	auipc	ra,0xffffd
    80003530:	7c0080e7          	jalr	1984(ra) # 80000cec <acquire>
  b->refcnt--;
    80003534:	04892783          	lw	a5,72(s2)
    80003538:	37fd                	addiw	a5,a5,-1
    8000353a:	04f92423          	sw	a5,72(s2)
  release(&bcache.lock[bid]);
    8000353e:	8526                	mv	a0,s1
    80003540:	ffffe097          	auipc	ra,0xffffe
    80003544:	87c080e7          	jalr	-1924(ra) # 80000dbc <release>
}
    80003548:	60e2                	ld	ra,24(sp)
    8000354a:	6442                	ld	s0,16(sp)
    8000354c:	64a2                	ld	s1,8(sp)
    8000354e:	6902                	ld	s2,0(sp)
    80003550:	6105                	addi	sp,sp,32
    80003552:	8082                	ret

0000000080003554 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003554:	1101                	addi	sp,sp,-32
    80003556:	ec06                	sd	ra,24(sp)
    80003558:	e822                	sd	s0,16(sp)
    8000355a:	e426                	sd	s1,8(sp)
    8000355c:	e04a                	sd	s2,0(sp)
    8000355e:	1000                	addi	s0,sp,32
    80003560:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003562:	00d5d59b          	srliw	a1,a1,0xd
    80003566:	00022797          	auipc	a5,0x22
    8000356a:	e3e7a783          	lw	a5,-450(a5) # 800253a4 <sb+0x1c>
    8000356e:	9dbd                	addw	a1,a1,a5
    80003570:	00000097          	auipc	ra,0x0
    80003574:	c54080e7          	jalr	-940(ra) # 800031c4 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003578:	0074f713          	andi	a4,s1,7
    8000357c:	4785                	li	a5,1
    8000357e:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003582:	14ce                	slli	s1,s1,0x33
    80003584:	90d9                	srli	s1,s1,0x36
    80003586:	00950733          	add	a4,a0,s1
    8000358a:	06074703          	lbu	a4,96(a4)
    8000358e:	00e7f6b3          	and	a3,a5,a4
    80003592:	c69d                	beqz	a3,800035c0 <bfree+0x6c>
    80003594:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003596:	94aa                	add	s1,s1,a0
    80003598:	fff7c793          	not	a5,a5
    8000359c:	8f7d                	and	a4,a4,a5
    8000359e:	06e48023          	sb	a4,96(s1)
  log_write(bp);
    800035a2:	00001097          	auipc	ra,0x1
    800035a6:	11e080e7          	jalr	286(ra) # 800046c0 <log_write>
  brelse(bp);
    800035aa:	854a                	mv	a0,s2
    800035ac:	00000097          	auipc	ra,0x0
    800035b0:	e4e080e7          	jalr	-434(ra) # 800033fa <brelse>
}
    800035b4:	60e2                	ld	ra,24(sp)
    800035b6:	6442                	ld	s0,16(sp)
    800035b8:	64a2                	ld	s1,8(sp)
    800035ba:	6902                	ld	s2,0(sp)
    800035bc:	6105                	addi	sp,sp,32
    800035be:	8082                	ret
    panic("freeing free block");
    800035c0:	00005517          	auipc	a0,0x5
    800035c4:	fd850513          	addi	a0,a0,-40 # 80008598 <syscalls+0xe0>
    800035c8:	ffffd097          	auipc	ra,0xffffd
    800035cc:	f84080e7          	jalr	-124(ra) # 8000054c <panic>

00000000800035d0 <balloc>:
{
    800035d0:	711d                	addi	sp,sp,-96
    800035d2:	ec86                	sd	ra,88(sp)
    800035d4:	e8a2                	sd	s0,80(sp)
    800035d6:	e4a6                	sd	s1,72(sp)
    800035d8:	e0ca                	sd	s2,64(sp)
    800035da:	fc4e                	sd	s3,56(sp)
    800035dc:	f852                	sd	s4,48(sp)
    800035de:	f456                	sd	s5,40(sp)
    800035e0:	f05a                	sd	s6,32(sp)
    800035e2:	ec5e                	sd	s7,24(sp)
    800035e4:	e862                	sd	s8,16(sp)
    800035e6:	e466                	sd	s9,8(sp)
    800035e8:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800035ea:	00022797          	auipc	a5,0x22
    800035ee:	da27a783          	lw	a5,-606(a5) # 8002538c <sb+0x4>
    800035f2:	cbc1                	beqz	a5,80003682 <balloc+0xb2>
    800035f4:	8baa                	mv	s7,a0
    800035f6:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800035f8:	00022b17          	auipc	s6,0x22
    800035fc:	d90b0b13          	addi	s6,s6,-624 # 80025388 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003600:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003602:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003604:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003606:	6c89                	lui	s9,0x2
    80003608:	a831                	j	80003624 <balloc+0x54>
    brelse(bp);
    8000360a:	854a                	mv	a0,s2
    8000360c:	00000097          	auipc	ra,0x0
    80003610:	dee080e7          	jalr	-530(ra) # 800033fa <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003614:	015c87bb          	addw	a5,s9,s5
    80003618:	00078a9b          	sext.w	s5,a5
    8000361c:	004b2703          	lw	a4,4(s6)
    80003620:	06eaf163          	bgeu	s5,a4,80003682 <balloc+0xb2>
    bp = bread(dev, BBLOCK(b, sb));
    80003624:	41fad79b          	sraiw	a5,s5,0x1f
    80003628:	0137d79b          	srliw	a5,a5,0x13
    8000362c:	015787bb          	addw	a5,a5,s5
    80003630:	40d7d79b          	sraiw	a5,a5,0xd
    80003634:	01cb2583          	lw	a1,28(s6)
    80003638:	9dbd                	addw	a1,a1,a5
    8000363a:	855e                	mv	a0,s7
    8000363c:	00000097          	auipc	ra,0x0
    80003640:	b88080e7          	jalr	-1144(ra) # 800031c4 <bread>
    80003644:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003646:	004b2503          	lw	a0,4(s6)
    8000364a:	000a849b          	sext.w	s1,s5
    8000364e:	8762                	mv	a4,s8
    80003650:	faa4fde3          	bgeu	s1,a0,8000360a <balloc+0x3a>
      m = 1 << (bi % 8);
    80003654:	00777693          	andi	a3,a4,7
    80003658:	00d996bb          	sllw	a3,s3,a3
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    8000365c:	41f7579b          	sraiw	a5,a4,0x1f
    80003660:	01d7d79b          	srliw	a5,a5,0x1d
    80003664:	9fb9                	addw	a5,a5,a4
    80003666:	4037d79b          	sraiw	a5,a5,0x3
    8000366a:	00f90633          	add	a2,s2,a5
    8000366e:	06064603          	lbu	a2,96(a2)
    80003672:	00c6f5b3          	and	a1,a3,a2
    80003676:	cd91                	beqz	a1,80003692 <balloc+0xc2>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003678:	2705                	addiw	a4,a4,1
    8000367a:	2485                	addiw	s1,s1,1
    8000367c:	fd471ae3          	bne	a4,s4,80003650 <balloc+0x80>
    80003680:	b769                	j	8000360a <balloc+0x3a>
  panic("balloc: out of blocks");
    80003682:	00005517          	auipc	a0,0x5
    80003686:	f2e50513          	addi	a0,a0,-210 # 800085b0 <syscalls+0xf8>
    8000368a:	ffffd097          	auipc	ra,0xffffd
    8000368e:	ec2080e7          	jalr	-318(ra) # 8000054c <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003692:	97ca                	add	a5,a5,s2
    80003694:	8e55                	or	a2,a2,a3
    80003696:	06c78023          	sb	a2,96(a5)
        log_write(bp);
    8000369a:	854a                	mv	a0,s2
    8000369c:	00001097          	auipc	ra,0x1
    800036a0:	024080e7          	jalr	36(ra) # 800046c0 <log_write>
        brelse(bp);
    800036a4:	854a                	mv	a0,s2
    800036a6:	00000097          	auipc	ra,0x0
    800036aa:	d54080e7          	jalr	-684(ra) # 800033fa <brelse>
  bp = bread(dev, bno);
    800036ae:	85a6                	mv	a1,s1
    800036b0:	855e                	mv	a0,s7
    800036b2:	00000097          	auipc	ra,0x0
    800036b6:	b12080e7          	jalr	-1262(ra) # 800031c4 <bread>
    800036ba:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800036bc:	40000613          	li	a2,1024
    800036c0:	4581                	li	a1,0
    800036c2:	06050513          	addi	a0,a0,96
    800036c6:	ffffe097          	auipc	ra,0xffffe
    800036ca:	a06080e7          	jalr	-1530(ra) # 800010cc <memset>
  log_write(bp);
    800036ce:	854a                	mv	a0,s2
    800036d0:	00001097          	auipc	ra,0x1
    800036d4:	ff0080e7          	jalr	-16(ra) # 800046c0 <log_write>
  brelse(bp);
    800036d8:	854a                	mv	a0,s2
    800036da:	00000097          	auipc	ra,0x0
    800036de:	d20080e7          	jalr	-736(ra) # 800033fa <brelse>
}
    800036e2:	8526                	mv	a0,s1
    800036e4:	60e6                	ld	ra,88(sp)
    800036e6:	6446                	ld	s0,80(sp)
    800036e8:	64a6                	ld	s1,72(sp)
    800036ea:	6906                	ld	s2,64(sp)
    800036ec:	79e2                	ld	s3,56(sp)
    800036ee:	7a42                	ld	s4,48(sp)
    800036f0:	7aa2                	ld	s5,40(sp)
    800036f2:	7b02                	ld	s6,32(sp)
    800036f4:	6be2                	ld	s7,24(sp)
    800036f6:	6c42                	ld	s8,16(sp)
    800036f8:	6ca2                	ld	s9,8(sp)
    800036fa:	6125                	addi	sp,sp,96
    800036fc:	8082                	ret

00000000800036fe <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    800036fe:	7179                	addi	sp,sp,-48
    80003700:	f406                	sd	ra,40(sp)
    80003702:	f022                	sd	s0,32(sp)
    80003704:	ec26                	sd	s1,24(sp)
    80003706:	e84a                	sd	s2,16(sp)
    80003708:	e44e                	sd	s3,8(sp)
    8000370a:	e052                	sd	s4,0(sp)
    8000370c:	1800                	addi	s0,sp,48
    8000370e:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003710:	47ad                	li	a5,11
    80003712:	04b7fe63          	bgeu	a5,a1,8000376e <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    80003716:	ff45849b          	addiw	s1,a1,-12 # ff4 <_entry-0x7ffff00c>
    8000371a:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    8000371e:	0ff00793          	li	a5,255
    80003722:	0ae7e463          	bltu	a5,a4,800037ca <bmap+0xcc>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    80003726:	08852583          	lw	a1,136(a0)
    8000372a:	c5b5                	beqz	a1,80003796 <bmap+0x98>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    8000372c:	00092503          	lw	a0,0(s2)
    80003730:	00000097          	auipc	ra,0x0
    80003734:	a94080e7          	jalr	-1388(ra) # 800031c4 <bread>
    80003738:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    8000373a:	06050793          	addi	a5,a0,96
    if((addr = a[bn]) == 0){
    8000373e:	02049713          	slli	a4,s1,0x20
    80003742:	01e75593          	srli	a1,a4,0x1e
    80003746:	00b784b3          	add	s1,a5,a1
    8000374a:	0004a983          	lw	s3,0(s1)
    8000374e:	04098e63          	beqz	s3,800037aa <bmap+0xac>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80003752:	8552                	mv	a0,s4
    80003754:	00000097          	auipc	ra,0x0
    80003758:	ca6080e7          	jalr	-858(ra) # 800033fa <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    8000375c:	854e                	mv	a0,s3
    8000375e:	70a2                	ld	ra,40(sp)
    80003760:	7402                	ld	s0,32(sp)
    80003762:	64e2                	ld	s1,24(sp)
    80003764:	6942                	ld	s2,16(sp)
    80003766:	69a2                	ld	s3,8(sp)
    80003768:	6a02                	ld	s4,0(sp)
    8000376a:	6145                	addi	sp,sp,48
    8000376c:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    8000376e:	02059793          	slli	a5,a1,0x20
    80003772:	01e7d593          	srli	a1,a5,0x1e
    80003776:	00b504b3          	add	s1,a0,a1
    8000377a:	0584a983          	lw	s3,88(s1)
    8000377e:	fc099fe3          	bnez	s3,8000375c <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    80003782:	4108                	lw	a0,0(a0)
    80003784:	00000097          	auipc	ra,0x0
    80003788:	e4c080e7          	jalr	-436(ra) # 800035d0 <balloc>
    8000378c:	0005099b          	sext.w	s3,a0
    80003790:	0534ac23          	sw	s3,88(s1)
    80003794:	b7e1                	j	8000375c <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80003796:	4108                	lw	a0,0(a0)
    80003798:	00000097          	auipc	ra,0x0
    8000379c:	e38080e7          	jalr	-456(ra) # 800035d0 <balloc>
    800037a0:	0005059b          	sext.w	a1,a0
    800037a4:	08b92423          	sw	a1,136(s2)
    800037a8:	b751                	j	8000372c <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    800037aa:	00092503          	lw	a0,0(s2)
    800037ae:	00000097          	auipc	ra,0x0
    800037b2:	e22080e7          	jalr	-478(ra) # 800035d0 <balloc>
    800037b6:	0005099b          	sext.w	s3,a0
    800037ba:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    800037be:	8552                	mv	a0,s4
    800037c0:	00001097          	auipc	ra,0x1
    800037c4:	f00080e7          	jalr	-256(ra) # 800046c0 <log_write>
    800037c8:	b769                	j	80003752 <bmap+0x54>
  panic("bmap: out of range");
    800037ca:	00005517          	auipc	a0,0x5
    800037ce:	dfe50513          	addi	a0,a0,-514 # 800085c8 <syscalls+0x110>
    800037d2:	ffffd097          	auipc	ra,0xffffd
    800037d6:	d7a080e7          	jalr	-646(ra) # 8000054c <panic>

00000000800037da <iget>:
{
    800037da:	7179                	addi	sp,sp,-48
    800037dc:	f406                	sd	ra,40(sp)
    800037de:	f022                	sd	s0,32(sp)
    800037e0:	ec26                	sd	s1,24(sp)
    800037e2:	e84a                	sd	s2,16(sp)
    800037e4:	e44e                	sd	s3,8(sp)
    800037e6:	e052                	sd	s4,0(sp)
    800037e8:	1800                	addi	s0,sp,48
    800037ea:	89aa                	mv	s3,a0
    800037ec:	8a2e                	mv	s4,a1
  acquire(&icache.lock);
    800037ee:	00022517          	auipc	a0,0x22
    800037f2:	bba50513          	addi	a0,a0,-1094 # 800253a8 <icache>
    800037f6:	ffffd097          	auipc	ra,0xffffd
    800037fa:	4f6080e7          	jalr	1270(ra) # 80000cec <acquire>
  empty = 0;
    800037fe:	4901                	li	s2,0
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    80003800:	00022497          	auipc	s1,0x22
    80003804:	bc848493          	addi	s1,s1,-1080 # 800253c8 <icache+0x20>
    80003808:	00023697          	auipc	a3,0x23
    8000380c:	7e068693          	addi	a3,a3,2016 # 80026fe8 <log>
    80003810:	a039                	j	8000381e <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003812:	02090b63          	beqz	s2,80003848 <iget+0x6e>
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    80003816:	09048493          	addi	s1,s1,144
    8000381a:	02d48a63          	beq	s1,a3,8000384e <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    8000381e:	449c                	lw	a5,8(s1)
    80003820:	fef059e3          	blez	a5,80003812 <iget+0x38>
    80003824:	4098                	lw	a4,0(s1)
    80003826:	ff3716e3          	bne	a4,s3,80003812 <iget+0x38>
    8000382a:	40d8                	lw	a4,4(s1)
    8000382c:	ff4713e3          	bne	a4,s4,80003812 <iget+0x38>
      ip->ref++;
    80003830:	2785                	addiw	a5,a5,1
    80003832:	c49c                	sw	a5,8(s1)
      release(&icache.lock);
    80003834:	00022517          	auipc	a0,0x22
    80003838:	b7450513          	addi	a0,a0,-1164 # 800253a8 <icache>
    8000383c:	ffffd097          	auipc	ra,0xffffd
    80003840:	580080e7          	jalr	1408(ra) # 80000dbc <release>
      return ip;
    80003844:	8926                	mv	s2,s1
    80003846:	a03d                	j	80003874 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003848:	f7f9                	bnez	a5,80003816 <iget+0x3c>
    8000384a:	8926                	mv	s2,s1
    8000384c:	b7e9                	j	80003816 <iget+0x3c>
  if(empty == 0)
    8000384e:	02090c63          	beqz	s2,80003886 <iget+0xac>
  ip->dev = dev;
    80003852:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003856:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    8000385a:	4785                	li	a5,1
    8000385c:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003860:	04092423          	sw	zero,72(s2)
  release(&icache.lock);
    80003864:	00022517          	auipc	a0,0x22
    80003868:	b4450513          	addi	a0,a0,-1212 # 800253a8 <icache>
    8000386c:	ffffd097          	auipc	ra,0xffffd
    80003870:	550080e7          	jalr	1360(ra) # 80000dbc <release>
}
    80003874:	854a                	mv	a0,s2
    80003876:	70a2                	ld	ra,40(sp)
    80003878:	7402                	ld	s0,32(sp)
    8000387a:	64e2                	ld	s1,24(sp)
    8000387c:	6942                	ld	s2,16(sp)
    8000387e:	69a2                	ld	s3,8(sp)
    80003880:	6a02                	ld	s4,0(sp)
    80003882:	6145                	addi	sp,sp,48
    80003884:	8082                	ret
    panic("iget: no inodes");
    80003886:	00005517          	auipc	a0,0x5
    8000388a:	d5a50513          	addi	a0,a0,-678 # 800085e0 <syscalls+0x128>
    8000388e:	ffffd097          	auipc	ra,0xffffd
    80003892:	cbe080e7          	jalr	-834(ra) # 8000054c <panic>

0000000080003896 <fsinit>:
fsinit(int dev) {
    80003896:	7179                	addi	sp,sp,-48
    80003898:	f406                	sd	ra,40(sp)
    8000389a:	f022                	sd	s0,32(sp)
    8000389c:	ec26                	sd	s1,24(sp)
    8000389e:	e84a                	sd	s2,16(sp)
    800038a0:	e44e                	sd	s3,8(sp)
    800038a2:	1800                	addi	s0,sp,48
    800038a4:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    800038a6:	4585                	li	a1,1
    800038a8:	00000097          	auipc	ra,0x0
    800038ac:	91c080e7          	jalr	-1764(ra) # 800031c4 <bread>
    800038b0:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    800038b2:	00022997          	auipc	s3,0x22
    800038b6:	ad698993          	addi	s3,s3,-1322 # 80025388 <sb>
    800038ba:	02000613          	li	a2,32
    800038be:	06050593          	addi	a1,a0,96
    800038c2:	854e                	mv	a0,s3
    800038c4:	ffffe097          	auipc	ra,0xffffe
    800038c8:	864080e7          	jalr	-1948(ra) # 80001128 <memmove>
  brelse(bp);
    800038cc:	8526                	mv	a0,s1
    800038ce:	00000097          	auipc	ra,0x0
    800038d2:	b2c080e7          	jalr	-1236(ra) # 800033fa <brelse>
  if(sb.magic != FSMAGIC)
    800038d6:	0009a703          	lw	a4,0(s3)
    800038da:	102037b7          	lui	a5,0x10203
    800038de:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    800038e2:	02f71263          	bne	a4,a5,80003906 <fsinit+0x70>
  initlog(dev, &sb);
    800038e6:	00022597          	auipc	a1,0x22
    800038ea:	aa258593          	addi	a1,a1,-1374 # 80025388 <sb>
    800038ee:	854a                	mv	a0,s2
    800038f0:	00001097          	auipc	ra,0x1
    800038f4:	b54080e7          	jalr	-1196(ra) # 80004444 <initlog>
}
    800038f8:	70a2                	ld	ra,40(sp)
    800038fa:	7402                	ld	s0,32(sp)
    800038fc:	64e2                	ld	s1,24(sp)
    800038fe:	6942                	ld	s2,16(sp)
    80003900:	69a2                	ld	s3,8(sp)
    80003902:	6145                	addi	sp,sp,48
    80003904:	8082                	ret
    panic("invalid file system");
    80003906:	00005517          	auipc	a0,0x5
    8000390a:	cea50513          	addi	a0,a0,-790 # 800085f0 <syscalls+0x138>
    8000390e:	ffffd097          	auipc	ra,0xffffd
    80003912:	c3e080e7          	jalr	-962(ra) # 8000054c <panic>

0000000080003916 <iinit>:
{
    80003916:	7179                	addi	sp,sp,-48
    80003918:	f406                	sd	ra,40(sp)
    8000391a:	f022                	sd	s0,32(sp)
    8000391c:	ec26                	sd	s1,24(sp)
    8000391e:	e84a                	sd	s2,16(sp)
    80003920:	e44e                	sd	s3,8(sp)
    80003922:	1800                	addi	s0,sp,48
  initlock(&icache.lock, "icache");
    80003924:	00005597          	auipc	a1,0x5
    80003928:	ce458593          	addi	a1,a1,-796 # 80008608 <syscalls+0x150>
    8000392c:	00022517          	auipc	a0,0x22
    80003930:	a7c50513          	addi	a0,a0,-1412 # 800253a8 <icache>
    80003934:	ffffd097          	auipc	ra,0xffffd
    80003938:	534080e7          	jalr	1332(ra) # 80000e68 <initlock>
  for(i = 0; i < NINODE; i++) {
    8000393c:	00022497          	auipc	s1,0x22
    80003940:	a9c48493          	addi	s1,s1,-1380 # 800253d8 <icache+0x30>
    80003944:	00023997          	auipc	s3,0x23
    80003948:	6b498993          	addi	s3,s3,1716 # 80026ff8 <log+0x10>
    initsleeplock(&icache.inode[i].lock, "inode");
    8000394c:	00005917          	auipc	s2,0x5
    80003950:	cc490913          	addi	s2,s2,-828 # 80008610 <syscalls+0x158>
    80003954:	85ca                	mv	a1,s2
    80003956:	8526                	mv	a0,s1
    80003958:	00001097          	auipc	ra,0x1
    8000395c:	e54080e7          	jalr	-428(ra) # 800047ac <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003960:	09048493          	addi	s1,s1,144
    80003964:	ff3498e3          	bne	s1,s3,80003954 <iinit+0x3e>
}
    80003968:	70a2                	ld	ra,40(sp)
    8000396a:	7402                	ld	s0,32(sp)
    8000396c:	64e2                	ld	s1,24(sp)
    8000396e:	6942                	ld	s2,16(sp)
    80003970:	69a2                	ld	s3,8(sp)
    80003972:	6145                	addi	sp,sp,48
    80003974:	8082                	ret

0000000080003976 <ialloc>:
{
    80003976:	715d                	addi	sp,sp,-80
    80003978:	e486                	sd	ra,72(sp)
    8000397a:	e0a2                	sd	s0,64(sp)
    8000397c:	fc26                	sd	s1,56(sp)
    8000397e:	f84a                	sd	s2,48(sp)
    80003980:	f44e                	sd	s3,40(sp)
    80003982:	f052                	sd	s4,32(sp)
    80003984:	ec56                	sd	s5,24(sp)
    80003986:	e85a                	sd	s6,16(sp)
    80003988:	e45e                	sd	s7,8(sp)
    8000398a:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    8000398c:	00022717          	auipc	a4,0x22
    80003990:	a0872703          	lw	a4,-1528(a4) # 80025394 <sb+0xc>
    80003994:	4785                	li	a5,1
    80003996:	04e7fa63          	bgeu	a5,a4,800039ea <ialloc+0x74>
    8000399a:	8aaa                	mv	s5,a0
    8000399c:	8bae                	mv	s7,a1
    8000399e:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    800039a0:	00022a17          	auipc	s4,0x22
    800039a4:	9e8a0a13          	addi	s4,s4,-1560 # 80025388 <sb>
    800039a8:	00048b1b          	sext.w	s6,s1
    800039ac:	0044d593          	srli	a1,s1,0x4
    800039b0:	018a2783          	lw	a5,24(s4)
    800039b4:	9dbd                	addw	a1,a1,a5
    800039b6:	8556                	mv	a0,s5
    800039b8:	00000097          	auipc	ra,0x0
    800039bc:	80c080e7          	jalr	-2036(ra) # 800031c4 <bread>
    800039c0:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    800039c2:	06050993          	addi	s3,a0,96
    800039c6:	00f4f793          	andi	a5,s1,15
    800039ca:	079a                	slli	a5,a5,0x6
    800039cc:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    800039ce:	00099783          	lh	a5,0(s3)
    800039d2:	c785                	beqz	a5,800039fa <ialloc+0x84>
    brelse(bp);
    800039d4:	00000097          	auipc	ra,0x0
    800039d8:	a26080e7          	jalr	-1498(ra) # 800033fa <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    800039dc:	0485                	addi	s1,s1,1
    800039de:	00ca2703          	lw	a4,12(s4)
    800039e2:	0004879b          	sext.w	a5,s1
    800039e6:	fce7e1e3          	bltu	a5,a4,800039a8 <ialloc+0x32>
  panic("ialloc: no inodes");
    800039ea:	00005517          	auipc	a0,0x5
    800039ee:	c2e50513          	addi	a0,a0,-978 # 80008618 <syscalls+0x160>
    800039f2:	ffffd097          	auipc	ra,0xffffd
    800039f6:	b5a080e7          	jalr	-1190(ra) # 8000054c <panic>
      memset(dip, 0, sizeof(*dip));
    800039fa:	04000613          	li	a2,64
    800039fe:	4581                	li	a1,0
    80003a00:	854e                	mv	a0,s3
    80003a02:	ffffd097          	auipc	ra,0xffffd
    80003a06:	6ca080e7          	jalr	1738(ra) # 800010cc <memset>
      dip->type = type;
    80003a0a:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003a0e:	854a                	mv	a0,s2
    80003a10:	00001097          	auipc	ra,0x1
    80003a14:	cb0080e7          	jalr	-848(ra) # 800046c0 <log_write>
      brelse(bp);
    80003a18:	854a                	mv	a0,s2
    80003a1a:	00000097          	auipc	ra,0x0
    80003a1e:	9e0080e7          	jalr	-1568(ra) # 800033fa <brelse>
      return iget(dev, inum);
    80003a22:	85da                	mv	a1,s6
    80003a24:	8556                	mv	a0,s5
    80003a26:	00000097          	auipc	ra,0x0
    80003a2a:	db4080e7          	jalr	-588(ra) # 800037da <iget>
}
    80003a2e:	60a6                	ld	ra,72(sp)
    80003a30:	6406                	ld	s0,64(sp)
    80003a32:	74e2                	ld	s1,56(sp)
    80003a34:	7942                	ld	s2,48(sp)
    80003a36:	79a2                	ld	s3,40(sp)
    80003a38:	7a02                	ld	s4,32(sp)
    80003a3a:	6ae2                	ld	s5,24(sp)
    80003a3c:	6b42                	ld	s6,16(sp)
    80003a3e:	6ba2                	ld	s7,8(sp)
    80003a40:	6161                	addi	sp,sp,80
    80003a42:	8082                	ret

0000000080003a44 <iupdate>:
{
    80003a44:	1101                	addi	sp,sp,-32
    80003a46:	ec06                	sd	ra,24(sp)
    80003a48:	e822                	sd	s0,16(sp)
    80003a4a:	e426                	sd	s1,8(sp)
    80003a4c:	e04a                	sd	s2,0(sp)
    80003a4e:	1000                	addi	s0,sp,32
    80003a50:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003a52:	415c                	lw	a5,4(a0)
    80003a54:	0047d79b          	srliw	a5,a5,0x4
    80003a58:	00022597          	auipc	a1,0x22
    80003a5c:	9485a583          	lw	a1,-1720(a1) # 800253a0 <sb+0x18>
    80003a60:	9dbd                	addw	a1,a1,a5
    80003a62:	4108                	lw	a0,0(a0)
    80003a64:	fffff097          	auipc	ra,0xfffff
    80003a68:	760080e7          	jalr	1888(ra) # 800031c4 <bread>
    80003a6c:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003a6e:	06050793          	addi	a5,a0,96
    80003a72:	40d8                	lw	a4,4(s1)
    80003a74:	8b3d                	andi	a4,a4,15
    80003a76:	071a                	slli	a4,a4,0x6
    80003a78:	97ba                	add	a5,a5,a4
  dip->type = ip->type;
    80003a7a:	04c49703          	lh	a4,76(s1)
    80003a7e:	00e79023          	sh	a4,0(a5)
  dip->major = ip->major;
    80003a82:	04e49703          	lh	a4,78(s1)
    80003a86:	00e79123          	sh	a4,2(a5)
  dip->minor = ip->minor;
    80003a8a:	05049703          	lh	a4,80(s1)
    80003a8e:	00e79223          	sh	a4,4(a5)
  dip->nlink = ip->nlink;
    80003a92:	05249703          	lh	a4,82(s1)
    80003a96:	00e79323          	sh	a4,6(a5)
  dip->size = ip->size;
    80003a9a:	48f8                	lw	a4,84(s1)
    80003a9c:	c798                	sw	a4,8(a5)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003a9e:	03400613          	li	a2,52
    80003aa2:	05848593          	addi	a1,s1,88
    80003aa6:	00c78513          	addi	a0,a5,12
    80003aaa:	ffffd097          	auipc	ra,0xffffd
    80003aae:	67e080e7          	jalr	1662(ra) # 80001128 <memmove>
  log_write(bp);
    80003ab2:	854a                	mv	a0,s2
    80003ab4:	00001097          	auipc	ra,0x1
    80003ab8:	c0c080e7          	jalr	-1012(ra) # 800046c0 <log_write>
  brelse(bp);
    80003abc:	854a                	mv	a0,s2
    80003abe:	00000097          	auipc	ra,0x0
    80003ac2:	93c080e7          	jalr	-1732(ra) # 800033fa <brelse>
}
    80003ac6:	60e2                	ld	ra,24(sp)
    80003ac8:	6442                	ld	s0,16(sp)
    80003aca:	64a2                	ld	s1,8(sp)
    80003acc:	6902                	ld	s2,0(sp)
    80003ace:	6105                	addi	sp,sp,32
    80003ad0:	8082                	ret

0000000080003ad2 <idup>:
{
    80003ad2:	1101                	addi	sp,sp,-32
    80003ad4:	ec06                	sd	ra,24(sp)
    80003ad6:	e822                	sd	s0,16(sp)
    80003ad8:	e426                	sd	s1,8(sp)
    80003ada:	1000                	addi	s0,sp,32
    80003adc:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    80003ade:	00022517          	auipc	a0,0x22
    80003ae2:	8ca50513          	addi	a0,a0,-1846 # 800253a8 <icache>
    80003ae6:	ffffd097          	auipc	ra,0xffffd
    80003aea:	206080e7          	jalr	518(ra) # 80000cec <acquire>
  ip->ref++;
    80003aee:	449c                	lw	a5,8(s1)
    80003af0:	2785                	addiw	a5,a5,1
    80003af2:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    80003af4:	00022517          	auipc	a0,0x22
    80003af8:	8b450513          	addi	a0,a0,-1868 # 800253a8 <icache>
    80003afc:	ffffd097          	auipc	ra,0xffffd
    80003b00:	2c0080e7          	jalr	704(ra) # 80000dbc <release>
}
    80003b04:	8526                	mv	a0,s1
    80003b06:	60e2                	ld	ra,24(sp)
    80003b08:	6442                	ld	s0,16(sp)
    80003b0a:	64a2                	ld	s1,8(sp)
    80003b0c:	6105                	addi	sp,sp,32
    80003b0e:	8082                	ret

0000000080003b10 <ilock>:
{
    80003b10:	1101                	addi	sp,sp,-32
    80003b12:	ec06                	sd	ra,24(sp)
    80003b14:	e822                	sd	s0,16(sp)
    80003b16:	e426                	sd	s1,8(sp)
    80003b18:	e04a                	sd	s2,0(sp)
    80003b1a:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003b1c:	c115                	beqz	a0,80003b40 <ilock+0x30>
    80003b1e:	84aa                	mv	s1,a0
    80003b20:	451c                	lw	a5,8(a0)
    80003b22:	00f05f63          	blez	a5,80003b40 <ilock+0x30>
  acquiresleep(&ip->lock);
    80003b26:	0541                	addi	a0,a0,16
    80003b28:	00001097          	auipc	ra,0x1
    80003b2c:	cbe080e7          	jalr	-834(ra) # 800047e6 <acquiresleep>
  if(ip->valid == 0){
    80003b30:	44bc                	lw	a5,72(s1)
    80003b32:	cf99                	beqz	a5,80003b50 <ilock+0x40>
}
    80003b34:	60e2                	ld	ra,24(sp)
    80003b36:	6442                	ld	s0,16(sp)
    80003b38:	64a2                	ld	s1,8(sp)
    80003b3a:	6902                	ld	s2,0(sp)
    80003b3c:	6105                	addi	sp,sp,32
    80003b3e:	8082                	ret
    panic("ilock");
    80003b40:	00005517          	auipc	a0,0x5
    80003b44:	af050513          	addi	a0,a0,-1296 # 80008630 <syscalls+0x178>
    80003b48:	ffffd097          	auipc	ra,0xffffd
    80003b4c:	a04080e7          	jalr	-1532(ra) # 8000054c <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003b50:	40dc                	lw	a5,4(s1)
    80003b52:	0047d79b          	srliw	a5,a5,0x4
    80003b56:	00022597          	auipc	a1,0x22
    80003b5a:	84a5a583          	lw	a1,-1974(a1) # 800253a0 <sb+0x18>
    80003b5e:	9dbd                	addw	a1,a1,a5
    80003b60:	4088                	lw	a0,0(s1)
    80003b62:	fffff097          	auipc	ra,0xfffff
    80003b66:	662080e7          	jalr	1634(ra) # 800031c4 <bread>
    80003b6a:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003b6c:	06050593          	addi	a1,a0,96
    80003b70:	40dc                	lw	a5,4(s1)
    80003b72:	8bbd                	andi	a5,a5,15
    80003b74:	079a                	slli	a5,a5,0x6
    80003b76:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003b78:	00059783          	lh	a5,0(a1)
    80003b7c:	04f49623          	sh	a5,76(s1)
    ip->major = dip->major;
    80003b80:	00259783          	lh	a5,2(a1)
    80003b84:	04f49723          	sh	a5,78(s1)
    ip->minor = dip->minor;
    80003b88:	00459783          	lh	a5,4(a1)
    80003b8c:	04f49823          	sh	a5,80(s1)
    ip->nlink = dip->nlink;
    80003b90:	00659783          	lh	a5,6(a1)
    80003b94:	04f49923          	sh	a5,82(s1)
    ip->size = dip->size;
    80003b98:	459c                	lw	a5,8(a1)
    80003b9a:	c8fc                	sw	a5,84(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003b9c:	03400613          	li	a2,52
    80003ba0:	05b1                	addi	a1,a1,12
    80003ba2:	05848513          	addi	a0,s1,88
    80003ba6:	ffffd097          	auipc	ra,0xffffd
    80003baa:	582080e7          	jalr	1410(ra) # 80001128 <memmove>
    brelse(bp);
    80003bae:	854a                	mv	a0,s2
    80003bb0:	00000097          	auipc	ra,0x0
    80003bb4:	84a080e7          	jalr	-1974(ra) # 800033fa <brelse>
    ip->valid = 1;
    80003bb8:	4785                	li	a5,1
    80003bba:	c4bc                	sw	a5,72(s1)
    if(ip->type == 0)
    80003bbc:	04c49783          	lh	a5,76(s1)
    80003bc0:	fbb5                	bnez	a5,80003b34 <ilock+0x24>
      panic("ilock: no type");
    80003bc2:	00005517          	auipc	a0,0x5
    80003bc6:	a7650513          	addi	a0,a0,-1418 # 80008638 <syscalls+0x180>
    80003bca:	ffffd097          	auipc	ra,0xffffd
    80003bce:	982080e7          	jalr	-1662(ra) # 8000054c <panic>

0000000080003bd2 <iunlock>:
{
    80003bd2:	1101                	addi	sp,sp,-32
    80003bd4:	ec06                	sd	ra,24(sp)
    80003bd6:	e822                	sd	s0,16(sp)
    80003bd8:	e426                	sd	s1,8(sp)
    80003bda:	e04a                	sd	s2,0(sp)
    80003bdc:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003bde:	c905                	beqz	a0,80003c0e <iunlock+0x3c>
    80003be0:	84aa                	mv	s1,a0
    80003be2:	01050913          	addi	s2,a0,16
    80003be6:	854a                	mv	a0,s2
    80003be8:	00001097          	auipc	ra,0x1
    80003bec:	c98080e7          	jalr	-872(ra) # 80004880 <holdingsleep>
    80003bf0:	cd19                	beqz	a0,80003c0e <iunlock+0x3c>
    80003bf2:	449c                	lw	a5,8(s1)
    80003bf4:	00f05d63          	blez	a5,80003c0e <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003bf8:	854a                	mv	a0,s2
    80003bfa:	00001097          	auipc	ra,0x1
    80003bfe:	c42080e7          	jalr	-958(ra) # 8000483c <releasesleep>
}
    80003c02:	60e2                	ld	ra,24(sp)
    80003c04:	6442                	ld	s0,16(sp)
    80003c06:	64a2                	ld	s1,8(sp)
    80003c08:	6902                	ld	s2,0(sp)
    80003c0a:	6105                	addi	sp,sp,32
    80003c0c:	8082                	ret
    panic("iunlock");
    80003c0e:	00005517          	auipc	a0,0x5
    80003c12:	a3a50513          	addi	a0,a0,-1478 # 80008648 <syscalls+0x190>
    80003c16:	ffffd097          	auipc	ra,0xffffd
    80003c1a:	936080e7          	jalr	-1738(ra) # 8000054c <panic>

0000000080003c1e <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003c1e:	7179                	addi	sp,sp,-48
    80003c20:	f406                	sd	ra,40(sp)
    80003c22:	f022                	sd	s0,32(sp)
    80003c24:	ec26                	sd	s1,24(sp)
    80003c26:	e84a                	sd	s2,16(sp)
    80003c28:	e44e                	sd	s3,8(sp)
    80003c2a:	e052                	sd	s4,0(sp)
    80003c2c:	1800                	addi	s0,sp,48
    80003c2e:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003c30:	05850493          	addi	s1,a0,88
    80003c34:	08850913          	addi	s2,a0,136
    80003c38:	a021                	j	80003c40 <itrunc+0x22>
    80003c3a:	0491                	addi	s1,s1,4
    80003c3c:	01248d63          	beq	s1,s2,80003c56 <itrunc+0x38>
    if(ip->addrs[i]){
    80003c40:	408c                	lw	a1,0(s1)
    80003c42:	dde5                	beqz	a1,80003c3a <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003c44:	0009a503          	lw	a0,0(s3)
    80003c48:	00000097          	auipc	ra,0x0
    80003c4c:	90c080e7          	jalr	-1780(ra) # 80003554 <bfree>
      ip->addrs[i] = 0;
    80003c50:	0004a023          	sw	zero,0(s1)
    80003c54:	b7dd                	j	80003c3a <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003c56:	0889a583          	lw	a1,136(s3)
    80003c5a:	e185                	bnez	a1,80003c7a <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003c5c:	0409aa23          	sw	zero,84(s3)
  iupdate(ip);
    80003c60:	854e                	mv	a0,s3
    80003c62:	00000097          	auipc	ra,0x0
    80003c66:	de2080e7          	jalr	-542(ra) # 80003a44 <iupdate>
}
    80003c6a:	70a2                	ld	ra,40(sp)
    80003c6c:	7402                	ld	s0,32(sp)
    80003c6e:	64e2                	ld	s1,24(sp)
    80003c70:	6942                	ld	s2,16(sp)
    80003c72:	69a2                	ld	s3,8(sp)
    80003c74:	6a02                	ld	s4,0(sp)
    80003c76:	6145                	addi	sp,sp,48
    80003c78:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003c7a:	0009a503          	lw	a0,0(s3)
    80003c7e:	fffff097          	auipc	ra,0xfffff
    80003c82:	546080e7          	jalr	1350(ra) # 800031c4 <bread>
    80003c86:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003c88:	06050493          	addi	s1,a0,96
    80003c8c:	46050913          	addi	s2,a0,1120
    80003c90:	a021                	j	80003c98 <itrunc+0x7a>
    80003c92:	0491                	addi	s1,s1,4
    80003c94:	01248b63          	beq	s1,s2,80003caa <itrunc+0x8c>
      if(a[j])
    80003c98:	408c                	lw	a1,0(s1)
    80003c9a:	dde5                	beqz	a1,80003c92 <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003c9c:	0009a503          	lw	a0,0(s3)
    80003ca0:	00000097          	auipc	ra,0x0
    80003ca4:	8b4080e7          	jalr	-1868(ra) # 80003554 <bfree>
    80003ca8:	b7ed                	j	80003c92 <itrunc+0x74>
    brelse(bp);
    80003caa:	8552                	mv	a0,s4
    80003cac:	fffff097          	auipc	ra,0xfffff
    80003cb0:	74e080e7          	jalr	1870(ra) # 800033fa <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003cb4:	0889a583          	lw	a1,136(s3)
    80003cb8:	0009a503          	lw	a0,0(s3)
    80003cbc:	00000097          	auipc	ra,0x0
    80003cc0:	898080e7          	jalr	-1896(ra) # 80003554 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003cc4:	0809a423          	sw	zero,136(s3)
    80003cc8:	bf51                	j	80003c5c <itrunc+0x3e>

0000000080003cca <iput>:
{
    80003cca:	1101                	addi	sp,sp,-32
    80003ccc:	ec06                	sd	ra,24(sp)
    80003cce:	e822                	sd	s0,16(sp)
    80003cd0:	e426                	sd	s1,8(sp)
    80003cd2:	e04a                	sd	s2,0(sp)
    80003cd4:	1000                	addi	s0,sp,32
    80003cd6:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    80003cd8:	00021517          	auipc	a0,0x21
    80003cdc:	6d050513          	addi	a0,a0,1744 # 800253a8 <icache>
    80003ce0:	ffffd097          	auipc	ra,0xffffd
    80003ce4:	00c080e7          	jalr	12(ra) # 80000cec <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003ce8:	4498                	lw	a4,8(s1)
    80003cea:	4785                	li	a5,1
    80003cec:	02f70363          	beq	a4,a5,80003d12 <iput+0x48>
  ip->ref--;
    80003cf0:	449c                	lw	a5,8(s1)
    80003cf2:	37fd                	addiw	a5,a5,-1
    80003cf4:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    80003cf6:	00021517          	auipc	a0,0x21
    80003cfa:	6b250513          	addi	a0,a0,1714 # 800253a8 <icache>
    80003cfe:	ffffd097          	auipc	ra,0xffffd
    80003d02:	0be080e7          	jalr	190(ra) # 80000dbc <release>
}
    80003d06:	60e2                	ld	ra,24(sp)
    80003d08:	6442                	ld	s0,16(sp)
    80003d0a:	64a2                	ld	s1,8(sp)
    80003d0c:	6902                	ld	s2,0(sp)
    80003d0e:	6105                	addi	sp,sp,32
    80003d10:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003d12:	44bc                	lw	a5,72(s1)
    80003d14:	dff1                	beqz	a5,80003cf0 <iput+0x26>
    80003d16:	05249783          	lh	a5,82(s1)
    80003d1a:	fbf9                	bnez	a5,80003cf0 <iput+0x26>
    acquiresleep(&ip->lock);
    80003d1c:	01048913          	addi	s2,s1,16
    80003d20:	854a                	mv	a0,s2
    80003d22:	00001097          	auipc	ra,0x1
    80003d26:	ac4080e7          	jalr	-1340(ra) # 800047e6 <acquiresleep>
    release(&icache.lock);
    80003d2a:	00021517          	auipc	a0,0x21
    80003d2e:	67e50513          	addi	a0,a0,1662 # 800253a8 <icache>
    80003d32:	ffffd097          	auipc	ra,0xffffd
    80003d36:	08a080e7          	jalr	138(ra) # 80000dbc <release>
    itrunc(ip);
    80003d3a:	8526                	mv	a0,s1
    80003d3c:	00000097          	auipc	ra,0x0
    80003d40:	ee2080e7          	jalr	-286(ra) # 80003c1e <itrunc>
    ip->type = 0;
    80003d44:	04049623          	sh	zero,76(s1)
    iupdate(ip);
    80003d48:	8526                	mv	a0,s1
    80003d4a:	00000097          	auipc	ra,0x0
    80003d4e:	cfa080e7          	jalr	-774(ra) # 80003a44 <iupdate>
    ip->valid = 0;
    80003d52:	0404a423          	sw	zero,72(s1)
    releasesleep(&ip->lock);
    80003d56:	854a                	mv	a0,s2
    80003d58:	00001097          	auipc	ra,0x1
    80003d5c:	ae4080e7          	jalr	-1308(ra) # 8000483c <releasesleep>
    acquire(&icache.lock);
    80003d60:	00021517          	auipc	a0,0x21
    80003d64:	64850513          	addi	a0,a0,1608 # 800253a8 <icache>
    80003d68:	ffffd097          	auipc	ra,0xffffd
    80003d6c:	f84080e7          	jalr	-124(ra) # 80000cec <acquire>
    80003d70:	b741                	j	80003cf0 <iput+0x26>

0000000080003d72 <iunlockput>:
{
    80003d72:	1101                	addi	sp,sp,-32
    80003d74:	ec06                	sd	ra,24(sp)
    80003d76:	e822                	sd	s0,16(sp)
    80003d78:	e426                	sd	s1,8(sp)
    80003d7a:	1000                	addi	s0,sp,32
    80003d7c:	84aa                	mv	s1,a0
  iunlock(ip);
    80003d7e:	00000097          	auipc	ra,0x0
    80003d82:	e54080e7          	jalr	-428(ra) # 80003bd2 <iunlock>
  iput(ip);
    80003d86:	8526                	mv	a0,s1
    80003d88:	00000097          	auipc	ra,0x0
    80003d8c:	f42080e7          	jalr	-190(ra) # 80003cca <iput>
}
    80003d90:	60e2                	ld	ra,24(sp)
    80003d92:	6442                	ld	s0,16(sp)
    80003d94:	64a2                	ld	s1,8(sp)
    80003d96:	6105                	addi	sp,sp,32
    80003d98:	8082                	ret

0000000080003d9a <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003d9a:	1141                	addi	sp,sp,-16
    80003d9c:	e422                	sd	s0,8(sp)
    80003d9e:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003da0:	411c                	lw	a5,0(a0)
    80003da2:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003da4:	415c                	lw	a5,4(a0)
    80003da6:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003da8:	04c51783          	lh	a5,76(a0)
    80003dac:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003db0:	05251783          	lh	a5,82(a0)
    80003db4:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003db8:	05456783          	lwu	a5,84(a0)
    80003dbc:	e99c                	sd	a5,16(a1)
}
    80003dbe:	6422                	ld	s0,8(sp)
    80003dc0:	0141                	addi	sp,sp,16
    80003dc2:	8082                	ret

0000000080003dc4 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003dc4:	497c                	lw	a5,84(a0)
    80003dc6:	0ed7e963          	bltu	a5,a3,80003eb8 <readi+0xf4>
{
    80003dca:	7159                	addi	sp,sp,-112
    80003dcc:	f486                	sd	ra,104(sp)
    80003dce:	f0a2                	sd	s0,96(sp)
    80003dd0:	eca6                	sd	s1,88(sp)
    80003dd2:	e8ca                	sd	s2,80(sp)
    80003dd4:	e4ce                	sd	s3,72(sp)
    80003dd6:	e0d2                	sd	s4,64(sp)
    80003dd8:	fc56                	sd	s5,56(sp)
    80003dda:	f85a                	sd	s6,48(sp)
    80003ddc:	f45e                	sd	s7,40(sp)
    80003dde:	f062                	sd	s8,32(sp)
    80003de0:	ec66                	sd	s9,24(sp)
    80003de2:	e86a                	sd	s10,16(sp)
    80003de4:	e46e                	sd	s11,8(sp)
    80003de6:	1880                	addi	s0,sp,112
    80003de8:	8baa                	mv	s7,a0
    80003dea:	8c2e                	mv	s8,a1
    80003dec:	8ab2                	mv	s5,a2
    80003dee:	84b6                	mv	s1,a3
    80003df0:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003df2:	9f35                	addw	a4,a4,a3
    return 0;
    80003df4:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003df6:	0ad76063          	bltu	a4,a3,80003e96 <readi+0xd2>
  if(off + n > ip->size)
    80003dfa:	00e7f463          	bgeu	a5,a4,80003e02 <readi+0x3e>
    n = ip->size - off;
    80003dfe:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003e02:	0a0b0963          	beqz	s6,80003eb4 <readi+0xf0>
    80003e06:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003e08:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003e0c:	5cfd                	li	s9,-1
    80003e0e:	a82d                	j	80003e48 <readi+0x84>
    80003e10:	020a1d93          	slli	s11,s4,0x20
    80003e14:	020ddd93          	srli	s11,s11,0x20
    80003e18:	06090613          	addi	a2,s2,96
    80003e1c:	86ee                	mv	a3,s11
    80003e1e:	963a                	add	a2,a2,a4
    80003e20:	85d6                	mv	a1,s5
    80003e22:	8562                	mv	a0,s8
    80003e24:	fffff097          	auipc	ra,0xfffff
    80003e28:	980080e7          	jalr	-1664(ra) # 800027a4 <either_copyout>
    80003e2c:	05950d63          	beq	a0,s9,80003e86 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003e30:	854a                	mv	a0,s2
    80003e32:	fffff097          	auipc	ra,0xfffff
    80003e36:	5c8080e7          	jalr	1480(ra) # 800033fa <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003e3a:	013a09bb          	addw	s3,s4,s3
    80003e3e:	009a04bb          	addw	s1,s4,s1
    80003e42:	9aee                	add	s5,s5,s11
    80003e44:	0569f763          	bgeu	s3,s6,80003e92 <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003e48:	000ba903          	lw	s2,0(s7)
    80003e4c:	00a4d59b          	srliw	a1,s1,0xa
    80003e50:	855e                	mv	a0,s7
    80003e52:	00000097          	auipc	ra,0x0
    80003e56:	8ac080e7          	jalr	-1876(ra) # 800036fe <bmap>
    80003e5a:	0005059b          	sext.w	a1,a0
    80003e5e:	854a                	mv	a0,s2
    80003e60:	fffff097          	auipc	ra,0xfffff
    80003e64:	364080e7          	jalr	868(ra) # 800031c4 <bread>
    80003e68:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003e6a:	3ff4f713          	andi	a4,s1,1023
    80003e6e:	40ed07bb          	subw	a5,s10,a4
    80003e72:	413b06bb          	subw	a3,s6,s3
    80003e76:	8a3e                	mv	s4,a5
    80003e78:	2781                	sext.w	a5,a5
    80003e7a:	0006861b          	sext.w	a2,a3
    80003e7e:	f8f679e3          	bgeu	a2,a5,80003e10 <readi+0x4c>
    80003e82:	8a36                	mv	s4,a3
    80003e84:	b771                	j	80003e10 <readi+0x4c>
      brelse(bp);
    80003e86:	854a                	mv	a0,s2
    80003e88:	fffff097          	auipc	ra,0xfffff
    80003e8c:	572080e7          	jalr	1394(ra) # 800033fa <brelse>
      tot = -1;
    80003e90:	59fd                	li	s3,-1
  }
  return tot;
    80003e92:	0009851b          	sext.w	a0,s3
}
    80003e96:	70a6                	ld	ra,104(sp)
    80003e98:	7406                	ld	s0,96(sp)
    80003e9a:	64e6                	ld	s1,88(sp)
    80003e9c:	6946                	ld	s2,80(sp)
    80003e9e:	69a6                	ld	s3,72(sp)
    80003ea0:	6a06                	ld	s4,64(sp)
    80003ea2:	7ae2                	ld	s5,56(sp)
    80003ea4:	7b42                	ld	s6,48(sp)
    80003ea6:	7ba2                	ld	s7,40(sp)
    80003ea8:	7c02                	ld	s8,32(sp)
    80003eaa:	6ce2                	ld	s9,24(sp)
    80003eac:	6d42                	ld	s10,16(sp)
    80003eae:	6da2                	ld	s11,8(sp)
    80003eb0:	6165                	addi	sp,sp,112
    80003eb2:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003eb4:	89da                	mv	s3,s6
    80003eb6:	bff1                	j	80003e92 <readi+0xce>
    return 0;
    80003eb8:	4501                	li	a0,0
}
    80003eba:	8082                	ret

0000000080003ebc <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003ebc:	497c                	lw	a5,84(a0)
    80003ebe:	10d7e763          	bltu	a5,a3,80003fcc <writei+0x110>
{
    80003ec2:	7159                	addi	sp,sp,-112
    80003ec4:	f486                	sd	ra,104(sp)
    80003ec6:	f0a2                	sd	s0,96(sp)
    80003ec8:	eca6                	sd	s1,88(sp)
    80003eca:	e8ca                	sd	s2,80(sp)
    80003ecc:	e4ce                	sd	s3,72(sp)
    80003ece:	e0d2                	sd	s4,64(sp)
    80003ed0:	fc56                	sd	s5,56(sp)
    80003ed2:	f85a                	sd	s6,48(sp)
    80003ed4:	f45e                	sd	s7,40(sp)
    80003ed6:	f062                	sd	s8,32(sp)
    80003ed8:	ec66                	sd	s9,24(sp)
    80003eda:	e86a                	sd	s10,16(sp)
    80003edc:	e46e                	sd	s11,8(sp)
    80003ede:	1880                	addi	s0,sp,112
    80003ee0:	8baa                	mv	s7,a0
    80003ee2:	8c2e                	mv	s8,a1
    80003ee4:	8ab2                	mv	s5,a2
    80003ee6:	8936                	mv	s2,a3
    80003ee8:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003eea:	00e687bb          	addw	a5,a3,a4
    80003eee:	0ed7e163          	bltu	a5,a3,80003fd0 <writei+0x114>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003ef2:	00043737          	lui	a4,0x43
    80003ef6:	0cf76f63          	bltu	a4,a5,80003fd4 <writei+0x118>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003efa:	0a0b0863          	beqz	s6,80003faa <writei+0xee>
    80003efe:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003f00:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003f04:	5cfd                	li	s9,-1
    80003f06:	a091                	j	80003f4a <writei+0x8e>
    80003f08:	02099d93          	slli	s11,s3,0x20
    80003f0c:	020ddd93          	srli	s11,s11,0x20
    80003f10:	06048513          	addi	a0,s1,96
    80003f14:	86ee                	mv	a3,s11
    80003f16:	8656                	mv	a2,s5
    80003f18:	85e2                	mv	a1,s8
    80003f1a:	953a                	add	a0,a0,a4
    80003f1c:	fffff097          	auipc	ra,0xfffff
    80003f20:	8de080e7          	jalr	-1826(ra) # 800027fa <either_copyin>
    80003f24:	07950263          	beq	a0,s9,80003f88 <writei+0xcc>
      brelse(bp);
      n = -1;
      break;
    }
    log_write(bp);
    80003f28:	8526                	mv	a0,s1
    80003f2a:	00000097          	auipc	ra,0x0
    80003f2e:	796080e7          	jalr	1942(ra) # 800046c0 <log_write>
    brelse(bp);
    80003f32:	8526                	mv	a0,s1
    80003f34:	fffff097          	auipc	ra,0xfffff
    80003f38:	4c6080e7          	jalr	1222(ra) # 800033fa <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003f3c:	01498a3b          	addw	s4,s3,s4
    80003f40:	0129893b          	addw	s2,s3,s2
    80003f44:	9aee                	add	s5,s5,s11
    80003f46:	056a7763          	bgeu	s4,s6,80003f94 <writei+0xd8>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003f4a:	000ba483          	lw	s1,0(s7)
    80003f4e:	00a9559b          	srliw	a1,s2,0xa
    80003f52:	855e                	mv	a0,s7
    80003f54:	fffff097          	auipc	ra,0xfffff
    80003f58:	7aa080e7          	jalr	1962(ra) # 800036fe <bmap>
    80003f5c:	0005059b          	sext.w	a1,a0
    80003f60:	8526                	mv	a0,s1
    80003f62:	fffff097          	auipc	ra,0xfffff
    80003f66:	262080e7          	jalr	610(ra) # 800031c4 <bread>
    80003f6a:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003f6c:	3ff97713          	andi	a4,s2,1023
    80003f70:	40ed07bb          	subw	a5,s10,a4
    80003f74:	414b06bb          	subw	a3,s6,s4
    80003f78:	89be                	mv	s3,a5
    80003f7a:	2781                	sext.w	a5,a5
    80003f7c:	0006861b          	sext.w	a2,a3
    80003f80:	f8f674e3          	bgeu	a2,a5,80003f08 <writei+0x4c>
    80003f84:	89b6                	mv	s3,a3
    80003f86:	b749                	j	80003f08 <writei+0x4c>
      brelse(bp);
    80003f88:	8526                	mv	a0,s1
    80003f8a:	fffff097          	auipc	ra,0xfffff
    80003f8e:	470080e7          	jalr	1136(ra) # 800033fa <brelse>
      n = -1;
    80003f92:	5b7d                	li	s6,-1
  }

  if(n > 0){
    if(off > ip->size)
    80003f94:	054ba783          	lw	a5,84(s7)
    80003f98:	0127f463          	bgeu	a5,s2,80003fa0 <writei+0xe4>
      ip->size = off;
    80003f9c:	052baa23          	sw	s2,84(s7)
    // write the i-node back to disk even if the size didn't change
    // because the loop above might have called bmap() and added a new
    // block to ip->addrs[].
    iupdate(ip);
    80003fa0:	855e                	mv	a0,s7
    80003fa2:	00000097          	auipc	ra,0x0
    80003fa6:	aa2080e7          	jalr	-1374(ra) # 80003a44 <iupdate>
  }

  return n;
    80003faa:	000b051b          	sext.w	a0,s6
}
    80003fae:	70a6                	ld	ra,104(sp)
    80003fb0:	7406                	ld	s0,96(sp)
    80003fb2:	64e6                	ld	s1,88(sp)
    80003fb4:	6946                	ld	s2,80(sp)
    80003fb6:	69a6                	ld	s3,72(sp)
    80003fb8:	6a06                	ld	s4,64(sp)
    80003fba:	7ae2                	ld	s5,56(sp)
    80003fbc:	7b42                	ld	s6,48(sp)
    80003fbe:	7ba2                	ld	s7,40(sp)
    80003fc0:	7c02                	ld	s8,32(sp)
    80003fc2:	6ce2                	ld	s9,24(sp)
    80003fc4:	6d42                	ld	s10,16(sp)
    80003fc6:	6da2                	ld	s11,8(sp)
    80003fc8:	6165                	addi	sp,sp,112
    80003fca:	8082                	ret
    return -1;
    80003fcc:	557d                	li	a0,-1
}
    80003fce:	8082                	ret
    return -1;
    80003fd0:	557d                	li	a0,-1
    80003fd2:	bff1                	j	80003fae <writei+0xf2>
    return -1;
    80003fd4:	557d                	li	a0,-1
    80003fd6:	bfe1                	j	80003fae <writei+0xf2>

0000000080003fd8 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003fd8:	1141                	addi	sp,sp,-16
    80003fda:	e406                	sd	ra,8(sp)
    80003fdc:	e022                	sd	s0,0(sp)
    80003fde:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003fe0:	4639                	li	a2,14
    80003fe2:	ffffd097          	auipc	ra,0xffffd
    80003fe6:	1c2080e7          	jalr	450(ra) # 800011a4 <strncmp>
}
    80003fea:	60a2                	ld	ra,8(sp)
    80003fec:	6402                	ld	s0,0(sp)
    80003fee:	0141                	addi	sp,sp,16
    80003ff0:	8082                	ret

0000000080003ff2 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003ff2:	7139                	addi	sp,sp,-64
    80003ff4:	fc06                	sd	ra,56(sp)
    80003ff6:	f822                	sd	s0,48(sp)
    80003ff8:	f426                	sd	s1,40(sp)
    80003ffa:	f04a                	sd	s2,32(sp)
    80003ffc:	ec4e                	sd	s3,24(sp)
    80003ffe:	e852                	sd	s4,16(sp)
    80004000:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80004002:	04c51703          	lh	a4,76(a0)
    80004006:	4785                	li	a5,1
    80004008:	00f71a63          	bne	a4,a5,8000401c <dirlookup+0x2a>
    8000400c:	892a                	mv	s2,a0
    8000400e:	89ae                	mv	s3,a1
    80004010:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80004012:	497c                	lw	a5,84(a0)
    80004014:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80004016:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004018:	e79d                	bnez	a5,80004046 <dirlookup+0x54>
    8000401a:	a8a5                	j	80004092 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    8000401c:	00004517          	auipc	a0,0x4
    80004020:	63450513          	addi	a0,a0,1588 # 80008650 <syscalls+0x198>
    80004024:	ffffc097          	auipc	ra,0xffffc
    80004028:	528080e7          	jalr	1320(ra) # 8000054c <panic>
      panic("dirlookup read");
    8000402c:	00004517          	auipc	a0,0x4
    80004030:	63c50513          	addi	a0,a0,1596 # 80008668 <syscalls+0x1b0>
    80004034:	ffffc097          	auipc	ra,0xffffc
    80004038:	518080e7          	jalr	1304(ra) # 8000054c <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000403c:	24c1                	addiw	s1,s1,16
    8000403e:	05492783          	lw	a5,84(s2)
    80004042:	04f4f763          	bgeu	s1,a5,80004090 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004046:	4741                	li	a4,16
    80004048:	86a6                	mv	a3,s1
    8000404a:	fc040613          	addi	a2,s0,-64
    8000404e:	4581                	li	a1,0
    80004050:	854a                	mv	a0,s2
    80004052:	00000097          	auipc	ra,0x0
    80004056:	d72080e7          	jalr	-654(ra) # 80003dc4 <readi>
    8000405a:	47c1                	li	a5,16
    8000405c:	fcf518e3          	bne	a0,a5,8000402c <dirlookup+0x3a>
    if(de.inum == 0)
    80004060:	fc045783          	lhu	a5,-64(s0)
    80004064:	dfe1                	beqz	a5,8000403c <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80004066:	fc240593          	addi	a1,s0,-62
    8000406a:	854e                	mv	a0,s3
    8000406c:	00000097          	auipc	ra,0x0
    80004070:	f6c080e7          	jalr	-148(ra) # 80003fd8 <namecmp>
    80004074:	f561                	bnez	a0,8000403c <dirlookup+0x4a>
      if(poff)
    80004076:	000a0463          	beqz	s4,8000407e <dirlookup+0x8c>
        *poff = off;
    8000407a:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    8000407e:	fc045583          	lhu	a1,-64(s0)
    80004082:	00092503          	lw	a0,0(s2)
    80004086:	fffff097          	auipc	ra,0xfffff
    8000408a:	754080e7          	jalr	1876(ra) # 800037da <iget>
    8000408e:	a011                	j	80004092 <dirlookup+0xa0>
  return 0;
    80004090:	4501                	li	a0,0
}
    80004092:	70e2                	ld	ra,56(sp)
    80004094:	7442                	ld	s0,48(sp)
    80004096:	74a2                	ld	s1,40(sp)
    80004098:	7902                	ld	s2,32(sp)
    8000409a:	69e2                	ld	s3,24(sp)
    8000409c:	6a42                	ld	s4,16(sp)
    8000409e:	6121                	addi	sp,sp,64
    800040a0:	8082                	ret

00000000800040a2 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    800040a2:	711d                	addi	sp,sp,-96
    800040a4:	ec86                	sd	ra,88(sp)
    800040a6:	e8a2                	sd	s0,80(sp)
    800040a8:	e4a6                	sd	s1,72(sp)
    800040aa:	e0ca                	sd	s2,64(sp)
    800040ac:	fc4e                	sd	s3,56(sp)
    800040ae:	f852                	sd	s4,48(sp)
    800040b0:	f456                	sd	s5,40(sp)
    800040b2:	f05a                	sd	s6,32(sp)
    800040b4:	ec5e                	sd	s7,24(sp)
    800040b6:	e862                	sd	s8,16(sp)
    800040b8:	e466                	sd	s9,8(sp)
    800040ba:	e06a                	sd	s10,0(sp)
    800040bc:	1080                	addi	s0,sp,96
    800040be:	84aa                	mv	s1,a0
    800040c0:	8b2e                	mv	s6,a1
    800040c2:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    800040c4:	00054703          	lbu	a4,0(a0)
    800040c8:	02f00793          	li	a5,47
    800040cc:	02f70363          	beq	a4,a5,800040f2 <namex+0x50>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    800040d0:	ffffe097          	auipc	ra,0xffffe
    800040d4:	c62080e7          	jalr	-926(ra) # 80001d32 <myproc>
    800040d8:	15853503          	ld	a0,344(a0)
    800040dc:	00000097          	auipc	ra,0x0
    800040e0:	9f6080e7          	jalr	-1546(ra) # 80003ad2 <idup>
    800040e4:	8a2a                	mv	s4,a0
  while(*path == '/')
    800040e6:	02f00913          	li	s2,47
  if(len >= DIRSIZ)
    800040ea:	4cb5                	li	s9,13
  len = path - s;
    800040ec:	4b81                	li	s7,0

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    800040ee:	4c05                	li	s8,1
    800040f0:	a87d                	j	800041ae <namex+0x10c>
    ip = iget(ROOTDEV, ROOTINO);
    800040f2:	4585                	li	a1,1
    800040f4:	4505                	li	a0,1
    800040f6:	fffff097          	auipc	ra,0xfffff
    800040fa:	6e4080e7          	jalr	1764(ra) # 800037da <iget>
    800040fe:	8a2a                	mv	s4,a0
    80004100:	b7dd                	j	800040e6 <namex+0x44>
      iunlockput(ip);
    80004102:	8552                	mv	a0,s4
    80004104:	00000097          	auipc	ra,0x0
    80004108:	c6e080e7          	jalr	-914(ra) # 80003d72 <iunlockput>
      return 0;
    8000410c:	4a01                	li	s4,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    8000410e:	8552                	mv	a0,s4
    80004110:	60e6                	ld	ra,88(sp)
    80004112:	6446                	ld	s0,80(sp)
    80004114:	64a6                	ld	s1,72(sp)
    80004116:	6906                	ld	s2,64(sp)
    80004118:	79e2                	ld	s3,56(sp)
    8000411a:	7a42                	ld	s4,48(sp)
    8000411c:	7aa2                	ld	s5,40(sp)
    8000411e:	7b02                	ld	s6,32(sp)
    80004120:	6be2                	ld	s7,24(sp)
    80004122:	6c42                	ld	s8,16(sp)
    80004124:	6ca2                	ld	s9,8(sp)
    80004126:	6d02                	ld	s10,0(sp)
    80004128:	6125                	addi	sp,sp,96
    8000412a:	8082                	ret
      iunlock(ip);
    8000412c:	8552                	mv	a0,s4
    8000412e:	00000097          	auipc	ra,0x0
    80004132:	aa4080e7          	jalr	-1372(ra) # 80003bd2 <iunlock>
      return ip;
    80004136:	bfe1                	j	8000410e <namex+0x6c>
      iunlockput(ip);
    80004138:	8552                	mv	a0,s4
    8000413a:	00000097          	auipc	ra,0x0
    8000413e:	c38080e7          	jalr	-968(ra) # 80003d72 <iunlockput>
      return 0;
    80004142:	8a4e                	mv	s4,s3
    80004144:	b7e9                	j	8000410e <namex+0x6c>
  len = path - s;
    80004146:	40998633          	sub	a2,s3,s1
    8000414a:	00060d1b          	sext.w	s10,a2
  if(len >= DIRSIZ)
    8000414e:	09acd863          	bge	s9,s10,800041de <namex+0x13c>
    memmove(name, s, DIRSIZ);
    80004152:	4639                	li	a2,14
    80004154:	85a6                	mv	a1,s1
    80004156:	8556                	mv	a0,s5
    80004158:	ffffd097          	auipc	ra,0xffffd
    8000415c:	fd0080e7          	jalr	-48(ra) # 80001128 <memmove>
    80004160:	84ce                	mv	s1,s3
  while(*path == '/')
    80004162:	0004c783          	lbu	a5,0(s1)
    80004166:	01279763          	bne	a5,s2,80004174 <namex+0xd2>
    path++;
    8000416a:	0485                	addi	s1,s1,1
  while(*path == '/')
    8000416c:	0004c783          	lbu	a5,0(s1)
    80004170:	ff278de3          	beq	a5,s2,8000416a <namex+0xc8>
    ilock(ip);
    80004174:	8552                	mv	a0,s4
    80004176:	00000097          	auipc	ra,0x0
    8000417a:	99a080e7          	jalr	-1638(ra) # 80003b10 <ilock>
    if(ip->type != T_DIR){
    8000417e:	04ca1783          	lh	a5,76(s4)
    80004182:	f98790e3          	bne	a5,s8,80004102 <namex+0x60>
    if(nameiparent && *path == '\0'){
    80004186:	000b0563          	beqz	s6,80004190 <namex+0xee>
    8000418a:	0004c783          	lbu	a5,0(s1)
    8000418e:	dfd9                	beqz	a5,8000412c <namex+0x8a>
    if((next = dirlookup(ip, name, 0)) == 0){
    80004190:	865e                	mv	a2,s7
    80004192:	85d6                	mv	a1,s5
    80004194:	8552                	mv	a0,s4
    80004196:	00000097          	auipc	ra,0x0
    8000419a:	e5c080e7          	jalr	-420(ra) # 80003ff2 <dirlookup>
    8000419e:	89aa                	mv	s3,a0
    800041a0:	dd41                	beqz	a0,80004138 <namex+0x96>
    iunlockput(ip);
    800041a2:	8552                	mv	a0,s4
    800041a4:	00000097          	auipc	ra,0x0
    800041a8:	bce080e7          	jalr	-1074(ra) # 80003d72 <iunlockput>
    ip = next;
    800041ac:	8a4e                	mv	s4,s3
  while(*path == '/')
    800041ae:	0004c783          	lbu	a5,0(s1)
    800041b2:	01279763          	bne	a5,s2,800041c0 <namex+0x11e>
    path++;
    800041b6:	0485                	addi	s1,s1,1
  while(*path == '/')
    800041b8:	0004c783          	lbu	a5,0(s1)
    800041bc:	ff278de3          	beq	a5,s2,800041b6 <namex+0x114>
  if(*path == 0)
    800041c0:	cb9d                	beqz	a5,800041f6 <namex+0x154>
  while(*path != '/' && *path != 0)
    800041c2:	0004c783          	lbu	a5,0(s1)
    800041c6:	89a6                	mv	s3,s1
  len = path - s;
    800041c8:	8d5e                	mv	s10,s7
    800041ca:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    800041cc:	01278963          	beq	a5,s2,800041de <namex+0x13c>
    800041d0:	dbbd                	beqz	a5,80004146 <namex+0xa4>
    path++;
    800041d2:	0985                	addi	s3,s3,1
  while(*path != '/' && *path != 0)
    800041d4:	0009c783          	lbu	a5,0(s3)
    800041d8:	ff279ce3          	bne	a5,s2,800041d0 <namex+0x12e>
    800041dc:	b7ad                	j	80004146 <namex+0xa4>
    memmove(name, s, len);
    800041de:	2601                	sext.w	a2,a2
    800041e0:	85a6                	mv	a1,s1
    800041e2:	8556                	mv	a0,s5
    800041e4:	ffffd097          	auipc	ra,0xffffd
    800041e8:	f44080e7          	jalr	-188(ra) # 80001128 <memmove>
    name[len] = 0;
    800041ec:	9d56                	add	s10,s10,s5
    800041ee:	000d0023          	sb	zero,0(s10) # 8000 <_entry-0x7fff8000>
    800041f2:	84ce                	mv	s1,s3
    800041f4:	b7bd                	j	80004162 <namex+0xc0>
  if(nameiparent){
    800041f6:	f00b0ce3          	beqz	s6,8000410e <namex+0x6c>
    iput(ip);
    800041fa:	8552                	mv	a0,s4
    800041fc:	00000097          	auipc	ra,0x0
    80004200:	ace080e7          	jalr	-1330(ra) # 80003cca <iput>
    return 0;
    80004204:	4a01                	li	s4,0
    80004206:	b721                	j	8000410e <namex+0x6c>

0000000080004208 <dirlink>:
{
    80004208:	7139                	addi	sp,sp,-64
    8000420a:	fc06                	sd	ra,56(sp)
    8000420c:	f822                	sd	s0,48(sp)
    8000420e:	f426                	sd	s1,40(sp)
    80004210:	f04a                	sd	s2,32(sp)
    80004212:	ec4e                	sd	s3,24(sp)
    80004214:	e852                	sd	s4,16(sp)
    80004216:	0080                	addi	s0,sp,64
    80004218:	892a                	mv	s2,a0
    8000421a:	8a2e                	mv	s4,a1
    8000421c:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    8000421e:	4601                	li	a2,0
    80004220:	00000097          	auipc	ra,0x0
    80004224:	dd2080e7          	jalr	-558(ra) # 80003ff2 <dirlookup>
    80004228:	e93d                	bnez	a0,8000429e <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000422a:	05492483          	lw	s1,84(s2)
    8000422e:	c49d                	beqz	s1,8000425c <dirlink+0x54>
    80004230:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004232:	4741                	li	a4,16
    80004234:	86a6                	mv	a3,s1
    80004236:	fc040613          	addi	a2,s0,-64
    8000423a:	4581                	li	a1,0
    8000423c:	854a                	mv	a0,s2
    8000423e:	00000097          	auipc	ra,0x0
    80004242:	b86080e7          	jalr	-1146(ra) # 80003dc4 <readi>
    80004246:	47c1                	li	a5,16
    80004248:	06f51163          	bne	a0,a5,800042aa <dirlink+0xa2>
    if(de.inum == 0)
    8000424c:	fc045783          	lhu	a5,-64(s0)
    80004250:	c791                	beqz	a5,8000425c <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004252:	24c1                	addiw	s1,s1,16
    80004254:	05492783          	lw	a5,84(s2)
    80004258:	fcf4ede3          	bltu	s1,a5,80004232 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    8000425c:	4639                	li	a2,14
    8000425e:	85d2                	mv	a1,s4
    80004260:	fc240513          	addi	a0,s0,-62
    80004264:	ffffd097          	auipc	ra,0xffffd
    80004268:	f7c080e7          	jalr	-132(ra) # 800011e0 <strncpy>
  de.inum = inum;
    8000426c:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004270:	4741                	li	a4,16
    80004272:	86a6                	mv	a3,s1
    80004274:	fc040613          	addi	a2,s0,-64
    80004278:	4581                	li	a1,0
    8000427a:	854a                	mv	a0,s2
    8000427c:	00000097          	auipc	ra,0x0
    80004280:	c40080e7          	jalr	-960(ra) # 80003ebc <writei>
    80004284:	872a                	mv	a4,a0
    80004286:	47c1                	li	a5,16
  return 0;
    80004288:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000428a:	02f71863          	bne	a4,a5,800042ba <dirlink+0xb2>
}
    8000428e:	70e2                	ld	ra,56(sp)
    80004290:	7442                	ld	s0,48(sp)
    80004292:	74a2                	ld	s1,40(sp)
    80004294:	7902                	ld	s2,32(sp)
    80004296:	69e2                	ld	s3,24(sp)
    80004298:	6a42                	ld	s4,16(sp)
    8000429a:	6121                	addi	sp,sp,64
    8000429c:	8082                	ret
    iput(ip);
    8000429e:	00000097          	auipc	ra,0x0
    800042a2:	a2c080e7          	jalr	-1492(ra) # 80003cca <iput>
    return -1;
    800042a6:	557d                	li	a0,-1
    800042a8:	b7dd                	j	8000428e <dirlink+0x86>
      panic("dirlink read");
    800042aa:	00004517          	auipc	a0,0x4
    800042ae:	3ce50513          	addi	a0,a0,974 # 80008678 <syscalls+0x1c0>
    800042b2:	ffffc097          	auipc	ra,0xffffc
    800042b6:	29a080e7          	jalr	666(ra) # 8000054c <panic>
    panic("dirlink");
    800042ba:	00004517          	auipc	a0,0x4
    800042be:	4de50513          	addi	a0,a0,1246 # 80008798 <syscalls+0x2e0>
    800042c2:	ffffc097          	auipc	ra,0xffffc
    800042c6:	28a080e7          	jalr	650(ra) # 8000054c <panic>

00000000800042ca <namei>:

struct inode*
namei(char *path)
{
    800042ca:	1101                	addi	sp,sp,-32
    800042cc:	ec06                	sd	ra,24(sp)
    800042ce:	e822                	sd	s0,16(sp)
    800042d0:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    800042d2:	fe040613          	addi	a2,s0,-32
    800042d6:	4581                	li	a1,0
    800042d8:	00000097          	auipc	ra,0x0
    800042dc:	dca080e7          	jalr	-566(ra) # 800040a2 <namex>
}
    800042e0:	60e2                	ld	ra,24(sp)
    800042e2:	6442                	ld	s0,16(sp)
    800042e4:	6105                	addi	sp,sp,32
    800042e6:	8082                	ret

00000000800042e8 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    800042e8:	1141                	addi	sp,sp,-16
    800042ea:	e406                	sd	ra,8(sp)
    800042ec:	e022                	sd	s0,0(sp)
    800042ee:	0800                	addi	s0,sp,16
    800042f0:	862e                	mv	a2,a1
  return namex(path, 1, name);
    800042f2:	4585                	li	a1,1
    800042f4:	00000097          	auipc	ra,0x0
    800042f8:	dae080e7          	jalr	-594(ra) # 800040a2 <namex>
}
    800042fc:	60a2                	ld	ra,8(sp)
    800042fe:	6402                	ld	s0,0(sp)
    80004300:	0141                	addi	sp,sp,16
    80004302:	8082                	ret

0000000080004304 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004304:	1101                	addi	sp,sp,-32
    80004306:	ec06                	sd	ra,24(sp)
    80004308:	e822                	sd	s0,16(sp)
    8000430a:	e426                	sd	s1,8(sp)
    8000430c:	e04a                	sd	s2,0(sp)
    8000430e:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80004310:	00023917          	auipc	s2,0x23
    80004314:	cd890913          	addi	s2,s2,-808 # 80026fe8 <log>
    80004318:	02092583          	lw	a1,32(s2)
    8000431c:	03092503          	lw	a0,48(s2)
    80004320:	fffff097          	auipc	ra,0xfffff
    80004324:	ea4080e7          	jalr	-348(ra) # 800031c4 <bread>
    80004328:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    8000432a:	03492683          	lw	a3,52(s2)
    8000432e:	d134                	sw	a3,96(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004330:	02d05863          	blez	a3,80004360 <write_head+0x5c>
    80004334:	00023797          	auipc	a5,0x23
    80004338:	cec78793          	addi	a5,a5,-788 # 80027020 <log+0x38>
    8000433c:	06450713          	addi	a4,a0,100
    80004340:	36fd                	addiw	a3,a3,-1
    80004342:	02069613          	slli	a2,a3,0x20
    80004346:	01e65693          	srli	a3,a2,0x1e
    8000434a:	00023617          	auipc	a2,0x23
    8000434e:	cda60613          	addi	a2,a2,-806 # 80027024 <log+0x3c>
    80004352:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80004354:	4390                	lw	a2,0(a5)
    80004356:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004358:	0791                	addi	a5,a5,4
    8000435a:	0711                	addi	a4,a4,4 # 43004 <_entry-0x7ffbcffc>
    8000435c:	fed79ce3          	bne	a5,a3,80004354 <write_head+0x50>
  }
  bwrite(buf);
    80004360:	8526                	mv	a0,s1
    80004362:	fffff097          	auipc	ra,0xfffff
    80004366:	05a080e7          	jalr	90(ra) # 800033bc <bwrite>
  brelse(buf);
    8000436a:	8526                	mv	a0,s1
    8000436c:	fffff097          	auipc	ra,0xfffff
    80004370:	08e080e7          	jalr	142(ra) # 800033fa <brelse>
}
    80004374:	60e2                	ld	ra,24(sp)
    80004376:	6442                	ld	s0,16(sp)
    80004378:	64a2                	ld	s1,8(sp)
    8000437a:	6902                	ld	s2,0(sp)
    8000437c:	6105                	addi	sp,sp,32
    8000437e:	8082                	ret

0000000080004380 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004380:	00023797          	auipc	a5,0x23
    80004384:	c9c7a783          	lw	a5,-868(a5) # 8002701c <log+0x34>
    80004388:	0af05d63          	blez	a5,80004442 <install_trans+0xc2>
{
    8000438c:	7139                	addi	sp,sp,-64
    8000438e:	fc06                	sd	ra,56(sp)
    80004390:	f822                	sd	s0,48(sp)
    80004392:	f426                	sd	s1,40(sp)
    80004394:	f04a                	sd	s2,32(sp)
    80004396:	ec4e                	sd	s3,24(sp)
    80004398:	e852                	sd	s4,16(sp)
    8000439a:	e456                	sd	s5,8(sp)
    8000439c:	e05a                	sd	s6,0(sp)
    8000439e:	0080                	addi	s0,sp,64
    800043a0:	8b2a                	mv	s6,a0
    800043a2:	00023a97          	auipc	s5,0x23
    800043a6:	c7ea8a93          	addi	s5,s5,-898 # 80027020 <log+0x38>
  for (tail = 0; tail < log.lh.n; tail++) {
    800043aa:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800043ac:	00023997          	auipc	s3,0x23
    800043b0:	c3c98993          	addi	s3,s3,-964 # 80026fe8 <log>
    800043b4:	a00d                	j	800043d6 <install_trans+0x56>
    brelse(lbuf);
    800043b6:	854a                	mv	a0,s2
    800043b8:	fffff097          	auipc	ra,0xfffff
    800043bc:	042080e7          	jalr	66(ra) # 800033fa <brelse>
    brelse(dbuf);
    800043c0:	8526                	mv	a0,s1
    800043c2:	fffff097          	auipc	ra,0xfffff
    800043c6:	038080e7          	jalr	56(ra) # 800033fa <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800043ca:	2a05                	addiw	s4,s4,1
    800043cc:	0a91                	addi	s5,s5,4
    800043ce:	0349a783          	lw	a5,52(s3)
    800043d2:	04fa5e63          	bge	s4,a5,8000442e <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800043d6:	0209a583          	lw	a1,32(s3)
    800043da:	014585bb          	addw	a1,a1,s4
    800043de:	2585                	addiw	a1,a1,1
    800043e0:	0309a503          	lw	a0,48(s3)
    800043e4:	fffff097          	auipc	ra,0xfffff
    800043e8:	de0080e7          	jalr	-544(ra) # 800031c4 <bread>
    800043ec:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    800043ee:	000aa583          	lw	a1,0(s5)
    800043f2:	0309a503          	lw	a0,48(s3)
    800043f6:	fffff097          	auipc	ra,0xfffff
    800043fa:	dce080e7          	jalr	-562(ra) # 800031c4 <bread>
    800043fe:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004400:	40000613          	li	a2,1024
    80004404:	06090593          	addi	a1,s2,96
    80004408:	06050513          	addi	a0,a0,96
    8000440c:	ffffd097          	auipc	ra,0xffffd
    80004410:	d1c080e7          	jalr	-740(ra) # 80001128 <memmove>
    bwrite(dbuf);  // write dst to disk
    80004414:	8526                	mv	a0,s1
    80004416:	fffff097          	auipc	ra,0xfffff
    8000441a:	fa6080e7          	jalr	-90(ra) # 800033bc <bwrite>
    if(recovering == 0)
    8000441e:	f80b1ce3          	bnez	s6,800043b6 <install_trans+0x36>
      bunpin(dbuf);
    80004422:	8526                	mv	a0,s1
    80004424:	fffff097          	auipc	ra,0xfffff
    80004428:	0e4080e7          	jalr	228(ra) # 80003508 <bunpin>
    8000442c:	b769                	j	800043b6 <install_trans+0x36>
}
    8000442e:	70e2                	ld	ra,56(sp)
    80004430:	7442                	ld	s0,48(sp)
    80004432:	74a2                	ld	s1,40(sp)
    80004434:	7902                	ld	s2,32(sp)
    80004436:	69e2                	ld	s3,24(sp)
    80004438:	6a42                	ld	s4,16(sp)
    8000443a:	6aa2                	ld	s5,8(sp)
    8000443c:	6b02                	ld	s6,0(sp)
    8000443e:	6121                	addi	sp,sp,64
    80004440:	8082                	ret
    80004442:	8082                	ret

0000000080004444 <initlog>:
{
    80004444:	7179                	addi	sp,sp,-48
    80004446:	f406                	sd	ra,40(sp)
    80004448:	f022                	sd	s0,32(sp)
    8000444a:	ec26                	sd	s1,24(sp)
    8000444c:	e84a                	sd	s2,16(sp)
    8000444e:	e44e                	sd	s3,8(sp)
    80004450:	1800                	addi	s0,sp,48
    80004452:	892a                	mv	s2,a0
    80004454:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004456:	00023497          	auipc	s1,0x23
    8000445a:	b9248493          	addi	s1,s1,-1134 # 80026fe8 <log>
    8000445e:	00004597          	auipc	a1,0x4
    80004462:	22a58593          	addi	a1,a1,554 # 80008688 <syscalls+0x1d0>
    80004466:	8526                	mv	a0,s1
    80004468:	ffffd097          	auipc	ra,0xffffd
    8000446c:	a00080e7          	jalr	-1536(ra) # 80000e68 <initlock>
  log.start = sb->logstart;
    80004470:	0149a583          	lw	a1,20(s3)
    80004474:	d08c                	sw	a1,32(s1)
  log.size = sb->nlog;
    80004476:	0109a783          	lw	a5,16(s3)
    8000447a:	d0dc                	sw	a5,36(s1)
  log.dev = dev;
    8000447c:	0324a823          	sw	s2,48(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004480:	854a                	mv	a0,s2
    80004482:	fffff097          	auipc	ra,0xfffff
    80004486:	d42080e7          	jalr	-702(ra) # 800031c4 <bread>
  log.lh.n = lh->n;
    8000448a:	5134                	lw	a3,96(a0)
    8000448c:	d8d4                	sw	a3,52(s1)
  for (i = 0; i < log.lh.n; i++) {
    8000448e:	02d05663          	blez	a3,800044ba <initlog+0x76>
    80004492:	06450793          	addi	a5,a0,100
    80004496:	00023717          	auipc	a4,0x23
    8000449a:	b8a70713          	addi	a4,a4,-1142 # 80027020 <log+0x38>
    8000449e:	36fd                	addiw	a3,a3,-1
    800044a0:	02069613          	slli	a2,a3,0x20
    800044a4:	01e65693          	srli	a3,a2,0x1e
    800044a8:	06850613          	addi	a2,a0,104
    800044ac:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    800044ae:	4390                	lw	a2,0(a5)
    800044b0:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800044b2:	0791                	addi	a5,a5,4
    800044b4:	0711                	addi	a4,a4,4
    800044b6:	fed79ce3          	bne	a5,a3,800044ae <initlog+0x6a>
  brelse(buf);
    800044ba:	fffff097          	auipc	ra,0xfffff
    800044be:	f40080e7          	jalr	-192(ra) # 800033fa <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    800044c2:	4505                	li	a0,1
    800044c4:	00000097          	auipc	ra,0x0
    800044c8:	ebc080e7          	jalr	-324(ra) # 80004380 <install_trans>
  log.lh.n = 0;
    800044cc:	00023797          	auipc	a5,0x23
    800044d0:	b407a823          	sw	zero,-1200(a5) # 8002701c <log+0x34>
  write_head(); // clear the log
    800044d4:	00000097          	auipc	ra,0x0
    800044d8:	e30080e7          	jalr	-464(ra) # 80004304 <write_head>
}
    800044dc:	70a2                	ld	ra,40(sp)
    800044de:	7402                	ld	s0,32(sp)
    800044e0:	64e2                	ld	s1,24(sp)
    800044e2:	6942                	ld	s2,16(sp)
    800044e4:	69a2                	ld	s3,8(sp)
    800044e6:	6145                	addi	sp,sp,48
    800044e8:	8082                	ret

00000000800044ea <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    800044ea:	1101                	addi	sp,sp,-32
    800044ec:	ec06                	sd	ra,24(sp)
    800044ee:	e822                	sd	s0,16(sp)
    800044f0:	e426                	sd	s1,8(sp)
    800044f2:	e04a                	sd	s2,0(sp)
    800044f4:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    800044f6:	00023517          	auipc	a0,0x23
    800044fa:	af250513          	addi	a0,a0,-1294 # 80026fe8 <log>
    800044fe:	ffffc097          	auipc	ra,0xffffc
    80004502:	7ee080e7          	jalr	2030(ra) # 80000cec <acquire>
  while(1){
    if(log.committing){
    80004506:	00023497          	auipc	s1,0x23
    8000450a:	ae248493          	addi	s1,s1,-1310 # 80026fe8 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000450e:	4979                	li	s2,30
    80004510:	a039                	j	8000451e <begin_op+0x34>
      sleep(&log, &log.lock);
    80004512:	85a6                	mv	a1,s1
    80004514:	8526                	mv	a0,s1
    80004516:	ffffe097          	auipc	ra,0xffffe
    8000451a:	034080e7          	jalr	52(ra) # 8000254a <sleep>
    if(log.committing){
    8000451e:	54dc                	lw	a5,44(s1)
    80004520:	fbed                	bnez	a5,80004512 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004522:	5498                	lw	a4,40(s1)
    80004524:	2705                	addiw	a4,a4,1
    80004526:	0007069b          	sext.w	a3,a4
    8000452a:	0027179b          	slliw	a5,a4,0x2
    8000452e:	9fb9                	addw	a5,a5,a4
    80004530:	0017979b          	slliw	a5,a5,0x1
    80004534:	58d8                	lw	a4,52(s1)
    80004536:	9fb9                	addw	a5,a5,a4
    80004538:	00f95963          	bge	s2,a5,8000454a <begin_op+0x60>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    8000453c:	85a6                	mv	a1,s1
    8000453e:	8526                	mv	a0,s1
    80004540:	ffffe097          	auipc	ra,0xffffe
    80004544:	00a080e7          	jalr	10(ra) # 8000254a <sleep>
    80004548:	bfd9                	j	8000451e <begin_op+0x34>
    } else {
      log.outstanding += 1;
    8000454a:	00023517          	auipc	a0,0x23
    8000454e:	a9e50513          	addi	a0,a0,-1378 # 80026fe8 <log>
    80004552:	d514                	sw	a3,40(a0)
      release(&log.lock);
    80004554:	ffffd097          	auipc	ra,0xffffd
    80004558:	868080e7          	jalr	-1944(ra) # 80000dbc <release>
      break;
    }
  }
}
    8000455c:	60e2                	ld	ra,24(sp)
    8000455e:	6442                	ld	s0,16(sp)
    80004560:	64a2                	ld	s1,8(sp)
    80004562:	6902                	ld	s2,0(sp)
    80004564:	6105                	addi	sp,sp,32
    80004566:	8082                	ret

0000000080004568 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004568:	7139                	addi	sp,sp,-64
    8000456a:	fc06                	sd	ra,56(sp)
    8000456c:	f822                	sd	s0,48(sp)
    8000456e:	f426                	sd	s1,40(sp)
    80004570:	f04a                	sd	s2,32(sp)
    80004572:	ec4e                	sd	s3,24(sp)
    80004574:	e852                	sd	s4,16(sp)
    80004576:	e456                	sd	s5,8(sp)
    80004578:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    8000457a:	00023497          	auipc	s1,0x23
    8000457e:	a6e48493          	addi	s1,s1,-1426 # 80026fe8 <log>
    80004582:	8526                	mv	a0,s1
    80004584:	ffffc097          	auipc	ra,0xffffc
    80004588:	768080e7          	jalr	1896(ra) # 80000cec <acquire>
  log.outstanding -= 1;
    8000458c:	549c                	lw	a5,40(s1)
    8000458e:	37fd                	addiw	a5,a5,-1
    80004590:	0007891b          	sext.w	s2,a5
    80004594:	d49c                	sw	a5,40(s1)
  if(log.committing)
    80004596:	54dc                	lw	a5,44(s1)
    80004598:	e7b9                	bnez	a5,800045e6 <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    8000459a:	04091e63          	bnez	s2,800045f6 <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    8000459e:	00023497          	auipc	s1,0x23
    800045a2:	a4a48493          	addi	s1,s1,-1462 # 80026fe8 <log>
    800045a6:	4785                	li	a5,1
    800045a8:	d4dc                	sw	a5,44(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800045aa:	8526                	mv	a0,s1
    800045ac:	ffffd097          	auipc	ra,0xffffd
    800045b0:	810080e7          	jalr	-2032(ra) # 80000dbc <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800045b4:	58dc                	lw	a5,52(s1)
    800045b6:	06f04763          	bgtz	a5,80004624 <end_op+0xbc>
    acquire(&log.lock);
    800045ba:	00023497          	auipc	s1,0x23
    800045be:	a2e48493          	addi	s1,s1,-1490 # 80026fe8 <log>
    800045c2:	8526                	mv	a0,s1
    800045c4:	ffffc097          	auipc	ra,0xffffc
    800045c8:	728080e7          	jalr	1832(ra) # 80000cec <acquire>
    log.committing = 0;
    800045cc:	0204a623          	sw	zero,44(s1)
    wakeup(&log);
    800045d0:	8526                	mv	a0,s1
    800045d2:	ffffe097          	auipc	ra,0xffffe
    800045d6:	0f8080e7          	jalr	248(ra) # 800026ca <wakeup>
    release(&log.lock);
    800045da:	8526                	mv	a0,s1
    800045dc:	ffffc097          	auipc	ra,0xffffc
    800045e0:	7e0080e7          	jalr	2016(ra) # 80000dbc <release>
}
    800045e4:	a03d                	j	80004612 <end_op+0xaa>
    panic("log.committing");
    800045e6:	00004517          	auipc	a0,0x4
    800045ea:	0aa50513          	addi	a0,a0,170 # 80008690 <syscalls+0x1d8>
    800045ee:	ffffc097          	auipc	ra,0xffffc
    800045f2:	f5e080e7          	jalr	-162(ra) # 8000054c <panic>
    wakeup(&log);
    800045f6:	00023497          	auipc	s1,0x23
    800045fa:	9f248493          	addi	s1,s1,-1550 # 80026fe8 <log>
    800045fe:	8526                	mv	a0,s1
    80004600:	ffffe097          	auipc	ra,0xffffe
    80004604:	0ca080e7          	jalr	202(ra) # 800026ca <wakeup>
  release(&log.lock);
    80004608:	8526                	mv	a0,s1
    8000460a:	ffffc097          	auipc	ra,0xffffc
    8000460e:	7b2080e7          	jalr	1970(ra) # 80000dbc <release>
}
    80004612:	70e2                	ld	ra,56(sp)
    80004614:	7442                	ld	s0,48(sp)
    80004616:	74a2                	ld	s1,40(sp)
    80004618:	7902                	ld	s2,32(sp)
    8000461a:	69e2                	ld	s3,24(sp)
    8000461c:	6a42                	ld	s4,16(sp)
    8000461e:	6aa2                	ld	s5,8(sp)
    80004620:	6121                	addi	sp,sp,64
    80004622:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    80004624:	00023a97          	auipc	s5,0x23
    80004628:	9fca8a93          	addi	s5,s5,-1540 # 80027020 <log+0x38>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    8000462c:	00023a17          	auipc	s4,0x23
    80004630:	9bca0a13          	addi	s4,s4,-1604 # 80026fe8 <log>
    80004634:	020a2583          	lw	a1,32(s4)
    80004638:	012585bb          	addw	a1,a1,s2
    8000463c:	2585                	addiw	a1,a1,1
    8000463e:	030a2503          	lw	a0,48(s4)
    80004642:	fffff097          	auipc	ra,0xfffff
    80004646:	b82080e7          	jalr	-1150(ra) # 800031c4 <bread>
    8000464a:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    8000464c:	000aa583          	lw	a1,0(s5)
    80004650:	030a2503          	lw	a0,48(s4)
    80004654:	fffff097          	auipc	ra,0xfffff
    80004658:	b70080e7          	jalr	-1168(ra) # 800031c4 <bread>
    8000465c:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    8000465e:	40000613          	li	a2,1024
    80004662:	06050593          	addi	a1,a0,96
    80004666:	06048513          	addi	a0,s1,96
    8000466a:	ffffd097          	auipc	ra,0xffffd
    8000466e:	abe080e7          	jalr	-1346(ra) # 80001128 <memmove>
    bwrite(to);  // write the log
    80004672:	8526                	mv	a0,s1
    80004674:	fffff097          	auipc	ra,0xfffff
    80004678:	d48080e7          	jalr	-696(ra) # 800033bc <bwrite>
    brelse(from);
    8000467c:	854e                	mv	a0,s3
    8000467e:	fffff097          	auipc	ra,0xfffff
    80004682:	d7c080e7          	jalr	-644(ra) # 800033fa <brelse>
    brelse(to);
    80004686:	8526                	mv	a0,s1
    80004688:	fffff097          	auipc	ra,0xfffff
    8000468c:	d72080e7          	jalr	-654(ra) # 800033fa <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004690:	2905                	addiw	s2,s2,1
    80004692:	0a91                	addi	s5,s5,4
    80004694:	034a2783          	lw	a5,52(s4)
    80004698:	f8f94ee3          	blt	s2,a5,80004634 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    8000469c:	00000097          	auipc	ra,0x0
    800046a0:	c68080e7          	jalr	-920(ra) # 80004304 <write_head>
    install_trans(0); // Now install writes to home locations
    800046a4:	4501                	li	a0,0
    800046a6:	00000097          	auipc	ra,0x0
    800046aa:	cda080e7          	jalr	-806(ra) # 80004380 <install_trans>
    log.lh.n = 0;
    800046ae:	00023797          	auipc	a5,0x23
    800046b2:	9607a723          	sw	zero,-1682(a5) # 8002701c <log+0x34>
    write_head();    // Erase the transaction from the log
    800046b6:	00000097          	auipc	ra,0x0
    800046ba:	c4e080e7          	jalr	-946(ra) # 80004304 <write_head>
    800046be:	bdf5                	j	800045ba <end_op+0x52>

00000000800046c0 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800046c0:	1101                	addi	sp,sp,-32
    800046c2:	ec06                	sd	ra,24(sp)
    800046c4:	e822                	sd	s0,16(sp)
    800046c6:	e426                	sd	s1,8(sp)
    800046c8:	e04a                	sd	s2,0(sp)
    800046ca:	1000                	addi	s0,sp,32
  int i;

  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800046cc:	00023717          	auipc	a4,0x23
    800046d0:	95072703          	lw	a4,-1712(a4) # 8002701c <log+0x34>
    800046d4:	47f5                	li	a5,29
    800046d6:	08e7c063          	blt	a5,a4,80004756 <log_write+0x96>
    800046da:	84aa                	mv	s1,a0
    800046dc:	00023797          	auipc	a5,0x23
    800046e0:	9307a783          	lw	a5,-1744(a5) # 8002700c <log+0x24>
    800046e4:	37fd                	addiw	a5,a5,-1
    800046e6:	06f75863          	bge	a4,a5,80004756 <log_write+0x96>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800046ea:	00023797          	auipc	a5,0x23
    800046ee:	9267a783          	lw	a5,-1754(a5) # 80027010 <log+0x28>
    800046f2:	06f05a63          	blez	a5,80004766 <log_write+0xa6>
    panic("log_write outside of trans");

  acquire(&log.lock);
    800046f6:	00023917          	auipc	s2,0x23
    800046fa:	8f290913          	addi	s2,s2,-1806 # 80026fe8 <log>
    800046fe:	854a                	mv	a0,s2
    80004700:	ffffc097          	auipc	ra,0xffffc
    80004704:	5ec080e7          	jalr	1516(ra) # 80000cec <acquire>
  for (i = 0; i < log.lh.n; i++) {
    80004708:	03492603          	lw	a2,52(s2)
    8000470c:	06c05563          	blez	a2,80004776 <log_write+0xb6>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    80004710:	44cc                	lw	a1,12(s1)
    80004712:	00023717          	auipc	a4,0x23
    80004716:	90e70713          	addi	a4,a4,-1778 # 80027020 <log+0x38>
  for (i = 0; i < log.lh.n; i++) {
    8000471a:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    8000471c:	4314                	lw	a3,0(a4)
    8000471e:	04b68d63          	beq	a3,a1,80004778 <log_write+0xb8>
  for (i = 0; i < log.lh.n; i++) {
    80004722:	2785                	addiw	a5,a5,1
    80004724:	0711                	addi	a4,a4,4
    80004726:	fec79be3          	bne	a5,a2,8000471c <log_write+0x5c>
      break;
  }
  log.lh.block[i] = b->blockno;
    8000472a:	0631                	addi	a2,a2,12
    8000472c:	060a                	slli	a2,a2,0x2
    8000472e:	00023797          	auipc	a5,0x23
    80004732:	8ba78793          	addi	a5,a5,-1862 # 80026fe8 <log>
    80004736:	97b2                	add	a5,a5,a2
    80004738:	44d8                	lw	a4,12(s1)
    8000473a:	c798                	sw	a4,8(a5)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    8000473c:	8526                	mv	a0,s1
    8000473e:	fffff097          	auipc	ra,0xfffff
    80004742:	d7e080e7          	jalr	-642(ra) # 800034bc <bpin>
    log.lh.n++;
    80004746:	00023717          	auipc	a4,0x23
    8000474a:	8a270713          	addi	a4,a4,-1886 # 80026fe8 <log>
    8000474e:	5b5c                	lw	a5,52(a4)
    80004750:	2785                	addiw	a5,a5,1
    80004752:	db5c                	sw	a5,52(a4)
    80004754:	a835                	j	80004790 <log_write+0xd0>
    panic("too big a transaction");
    80004756:	00004517          	auipc	a0,0x4
    8000475a:	f4a50513          	addi	a0,a0,-182 # 800086a0 <syscalls+0x1e8>
    8000475e:	ffffc097          	auipc	ra,0xffffc
    80004762:	dee080e7          	jalr	-530(ra) # 8000054c <panic>
    panic("log_write outside of trans");
    80004766:	00004517          	auipc	a0,0x4
    8000476a:	f5250513          	addi	a0,a0,-174 # 800086b8 <syscalls+0x200>
    8000476e:	ffffc097          	auipc	ra,0xffffc
    80004772:	dde080e7          	jalr	-546(ra) # 8000054c <panic>
  for (i = 0; i < log.lh.n; i++) {
    80004776:	4781                	li	a5,0
  log.lh.block[i] = b->blockno;
    80004778:	00c78693          	addi	a3,a5,12
    8000477c:	068a                	slli	a3,a3,0x2
    8000477e:	00023717          	auipc	a4,0x23
    80004782:	86a70713          	addi	a4,a4,-1942 # 80026fe8 <log>
    80004786:	9736                	add	a4,a4,a3
    80004788:	44d4                	lw	a3,12(s1)
    8000478a:	c714                	sw	a3,8(a4)
  if (i == log.lh.n) {  // Add new block to log?
    8000478c:	faf608e3          	beq	a2,a5,8000473c <log_write+0x7c>
  }
  release(&log.lock);
    80004790:	00023517          	auipc	a0,0x23
    80004794:	85850513          	addi	a0,a0,-1960 # 80026fe8 <log>
    80004798:	ffffc097          	auipc	ra,0xffffc
    8000479c:	624080e7          	jalr	1572(ra) # 80000dbc <release>
}
    800047a0:	60e2                	ld	ra,24(sp)
    800047a2:	6442                	ld	s0,16(sp)
    800047a4:	64a2                	ld	s1,8(sp)
    800047a6:	6902                	ld	s2,0(sp)
    800047a8:	6105                	addi	sp,sp,32
    800047aa:	8082                	ret

00000000800047ac <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    800047ac:	1101                	addi	sp,sp,-32
    800047ae:	ec06                	sd	ra,24(sp)
    800047b0:	e822                	sd	s0,16(sp)
    800047b2:	e426                	sd	s1,8(sp)
    800047b4:	e04a                	sd	s2,0(sp)
    800047b6:	1000                	addi	s0,sp,32
    800047b8:	84aa                	mv	s1,a0
    800047ba:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    800047bc:	00004597          	auipc	a1,0x4
    800047c0:	f1c58593          	addi	a1,a1,-228 # 800086d8 <syscalls+0x220>
    800047c4:	0521                	addi	a0,a0,8
    800047c6:	ffffc097          	auipc	ra,0xffffc
    800047ca:	6a2080e7          	jalr	1698(ra) # 80000e68 <initlock>
  lk->name = name;
    800047ce:	0324b423          	sd	s2,40(s1)
  lk->locked = 0;
    800047d2:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800047d6:	0204a823          	sw	zero,48(s1)
}
    800047da:	60e2                	ld	ra,24(sp)
    800047dc:	6442                	ld	s0,16(sp)
    800047de:	64a2                	ld	s1,8(sp)
    800047e0:	6902                	ld	s2,0(sp)
    800047e2:	6105                	addi	sp,sp,32
    800047e4:	8082                	ret

00000000800047e6 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    800047e6:	1101                	addi	sp,sp,-32
    800047e8:	ec06                	sd	ra,24(sp)
    800047ea:	e822                	sd	s0,16(sp)
    800047ec:	e426                	sd	s1,8(sp)
    800047ee:	e04a                	sd	s2,0(sp)
    800047f0:	1000                	addi	s0,sp,32
    800047f2:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800047f4:	00850913          	addi	s2,a0,8
    800047f8:	854a                	mv	a0,s2
    800047fa:	ffffc097          	auipc	ra,0xffffc
    800047fe:	4f2080e7          	jalr	1266(ra) # 80000cec <acquire>
  while (lk->locked) {
    80004802:	409c                	lw	a5,0(s1)
    80004804:	cb89                	beqz	a5,80004816 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004806:	85ca                	mv	a1,s2
    80004808:	8526                	mv	a0,s1
    8000480a:	ffffe097          	auipc	ra,0xffffe
    8000480e:	d40080e7          	jalr	-704(ra) # 8000254a <sleep>
  while (lk->locked) {
    80004812:	409c                	lw	a5,0(s1)
    80004814:	fbed                	bnez	a5,80004806 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004816:	4785                	li	a5,1
    80004818:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    8000481a:	ffffd097          	auipc	ra,0xffffd
    8000481e:	518080e7          	jalr	1304(ra) # 80001d32 <myproc>
    80004822:	413c                	lw	a5,64(a0)
    80004824:	d89c                	sw	a5,48(s1)
  release(&lk->lk);
    80004826:	854a                	mv	a0,s2
    80004828:	ffffc097          	auipc	ra,0xffffc
    8000482c:	594080e7          	jalr	1428(ra) # 80000dbc <release>
}
    80004830:	60e2                	ld	ra,24(sp)
    80004832:	6442                	ld	s0,16(sp)
    80004834:	64a2                	ld	s1,8(sp)
    80004836:	6902                	ld	s2,0(sp)
    80004838:	6105                	addi	sp,sp,32
    8000483a:	8082                	ret

000000008000483c <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    8000483c:	1101                	addi	sp,sp,-32
    8000483e:	ec06                	sd	ra,24(sp)
    80004840:	e822                	sd	s0,16(sp)
    80004842:	e426                	sd	s1,8(sp)
    80004844:	e04a                	sd	s2,0(sp)
    80004846:	1000                	addi	s0,sp,32
    80004848:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000484a:	00850913          	addi	s2,a0,8
    8000484e:	854a                	mv	a0,s2
    80004850:	ffffc097          	auipc	ra,0xffffc
    80004854:	49c080e7          	jalr	1180(ra) # 80000cec <acquire>
  lk->locked = 0;
    80004858:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000485c:	0204a823          	sw	zero,48(s1)
  wakeup(lk);
    80004860:	8526                	mv	a0,s1
    80004862:	ffffe097          	auipc	ra,0xffffe
    80004866:	e68080e7          	jalr	-408(ra) # 800026ca <wakeup>
  release(&lk->lk);
    8000486a:	854a                	mv	a0,s2
    8000486c:	ffffc097          	auipc	ra,0xffffc
    80004870:	550080e7          	jalr	1360(ra) # 80000dbc <release>
}
    80004874:	60e2                	ld	ra,24(sp)
    80004876:	6442                	ld	s0,16(sp)
    80004878:	64a2                	ld	s1,8(sp)
    8000487a:	6902                	ld	s2,0(sp)
    8000487c:	6105                	addi	sp,sp,32
    8000487e:	8082                	ret

0000000080004880 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004880:	7179                	addi	sp,sp,-48
    80004882:	f406                	sd	ra,40(sp)
    80004884:	f022                	sd	s0,32(sp)
    80004886:	ec26                	sd	s1,24(sp)
    80004888:	e84a                	sd	s2,16(sp)
    8000488a:	e44e                	sd	s3,8(sp)
    8000488c:	1800                	addi	s0,sp,48
    8000488e:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004890:	00850913          	addi	s2,a0,8
    80004894:	854a                	mv	a0,s2
    80004896:	ffffc097          	auipc	ra,0xffffc
    8000489a:	456080e7          	jalr	1110(ra) # 80000cec <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    8000489e:	409c                	lw	a5,0(s1)
    800048a0:	ef99                	bnez	a5,800048be <holdingsleep+0x3e>
    800048a2:	4481                	li	s1,0
  release(&lk->lk);
    800048a4:	854a                	mv	a0,s2
    800048a6:	ffffc097          	auipc	ra,0xffffc
    800048aa:	516080e7          	jalr	1302(ra) # 80000dbc <release>
  return r;
}
    800048ae:	8526                	mv	a0,s1
    800048b0:	70a2                	ld	ra,40(sp)
    800048b2:	7402                	ld	s0,32(sp)
    800048b4:	64e2                	ld	s1,24(sp)
    800048b6:	6942                	ld	s2,16(sp)
    800048b8:	69a2                	ld	s3,8(sp)
    800048ba:	6145                	addi	sp,sp,48
    800048bc:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    800048be:	0304a983          	lw	s3,48(s1)
    800048c2:	ffffd097          	auipc	ra,0xffffd
    800048c6:	470080e7          	jalr	1136(ra) # 80001d32 <myproc>
    800048ca:	4124                	lw	s1,64(a0)
    800048cc:	413484b3          	sub	s1,s1,s3
    800048d0:	0014b493          	seqz	s1,s1
    800048d4:	bfc1                	j	800048a4 <holdingsleep+0x24>

00000000800048d6 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    800048d6:	1141                	addi	sp,sp,-16
    800048d8:	e406                	sd	ra,8(sp)
    800048da:	e022                	sd	s0,0(sp)
    800048dc:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    800048de:	00004597          	auipc	a1,0x4
    800048e2:	e0a58593          	addi	a1,a1,-502 # 800086e8 <syscalls+0x230>
    800048e6:	00023517          	auipc	a0,0x23
    800048ea:	85250513          	addi	a0,a0,-1966 # 80027138 <ftable>
    800048ee:	ffffc097          	auipc	ra,0xffffc
    800048f2:	57a080e7          	jalr	1402(ra) # 80000e68 <initlock>
}
    800048f6:	60a2                	ld	ra,8(sp)
    800048f8:	6402                	ld	s0,0(sp)
    800048fa:	0141                	addi	sp,sp,16
    800048fc:	8082                	ret

00000000800048fe <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    800048fe:	1101                	addi	sp,sp,-32
    80004900:	ec06                	sd	ra,24(sp)
    80004902:	e822                	sd	s0,16(sp)
    80004904:	e426                	sd	s1,8(sp)
    80004906:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004908:	00023517          	auipc	a0,0x23
    8000490c:	83050513          	addi	a0,a0,-2000 # 80027138 <ftable>
    80004910:	ffffc097          	auipc	ra,0xffffc
    80004914:	3dc080e7          	jalr	988(ra) # 80000cec <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004918:	00023497          	auipc	s1,0x23
    8000491c:	84048493          	addi	s1,s1,-1984 # 80027158 <ftable+0x20>
    80004920:	00023717          	auipc	a4,0x23
    80004924:	7d870713          	addi	a4,a4,2008 # 800280f8 <ftable+0xfc0>
    if(f->ref == 0){
    80004928:	40dc                	lw	a5,4(s1)
    8000492a:	cf99                	beqz	a5,80004948 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000492c:	02848493          	addi	s1,s1,40
    80004930:	fee49ce3          	bne	s1,a4,80004928 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004934:	00023517          	auipc	a0,0x23
    80004938:	80450513          	addi	a0,a0,-2044 # 80027138 <ftable>
    8000493c:	ffffc097          	auipc	ra,0xffffc
    80004940:	480080e7          	jalr	1152(ra) # 80000dbc <release>
  return 0;
    80004944:	4481                	li	s1,0
    80004946:	a819                	j	8000495c <filealloc+0x5e>
      f->ref = 1;
    80004948:	4785                	li	a5,1
    8000494a:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    8000494c:	00022517          	auipc	a0,0x22
    80004950:	7ec50513          	addi	a0,a0,2028 # 80027138 <ftable>
    80004954:	ffffc097          	auipc	ra,0xffffc
    80004958:	468080e7          	jalr	1128(ra) # 80000dbc <release>
}
    8000495c:	8526                	mv	a0,s1
    8000495e:	60e2                	ld	ra,24(sp)
    80004960:	6442                	ld	s0,16(sp)
    80004962:	64a2                	ld	s1,8(sp)
    80004964:	6105                	addi	sp,sp,32
    80004966:	8082                	ret

0000000080004968 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004968:	1101                	addi	sp,sp,-32
    8000496a:	ec06                	sd	ra,24(sp)
    8000496c:	e822                	sd	s0,16(sp)
    8000496e:	e426                	sd	s1,8(sp)
    80004970:	1000                	addi	s0,sp,32
    80004972:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004974:	00022517          	auipc	a0,0x22
    80004978:	7c450513          	addi	a0,a0,1988 # 80027138 <ftable>
    8000497c:	ffffc097          	auipc	ra,0xffffc
    80004980:	370080e7          	jalr	880(ra) # 80000cec <acquire>
  if(f->ref < 1)
    80004984:	40dc                	lw	a5,4(s1)
    80004986:	02f05263          	blez	a5,800049aa <filedup+0x42>
    panic("filedup");
  f->ref++;
    8000498a:	2785                	addiw	a5,a5,1
    8000498c:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    8000498e:	00022517          	auipc	a0,0x22
    80004992:	7aa50513          	addi	a0,a0,1962 # 80027138 <ftable>
    80004996:	ffffc097          	auipc	ra,0xffffc
    8000499a:	426080e7          	jalr	1062(ra) # 80000dbc <release>
  return f;
}
    8000499e:	8526                	mv	a0,s1
    800049a0:	60e2                	ld	ra,24(sp)
    800049a2:	6442                	ld	s0,16(sp)
    800049a4:	64a2                	ld	s1,8(sp)
    800049a6:	6105                	addi	sp,sp,32
    800049a8:	8082                	ret
    panic("filedup");
    800049aa:	00004517          	auipc	a0,0x4
    800049ae:	d4650513          	addi	a0,a0,-698 # 800086f0 <syscalls+0x238>
    800049b2:	ffffc097          	auipc	ra,0xffffc
    800049b6:	b9a080e7          	jalr	-1126(ra) # 8000054c <panic>

00000000800049ba <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    800049ba:	7139                	addi	sp,sp,-64
    800049bc:	fc06                	sd	ra,56(sp)
    800049be:	f822                	sd	s0,48(sp)
    800049c0:	f426                	sd	s1,40(sp)
    800049c2:	f04a                	sd	s2,32(sp)
    800049c4:	ec4e                	sd	s3,24(sp)
    800049c6:	e852                	sd	s4,16(sp)
    800049c8:	e456                	sd	s5,8(sp)
    800049ca:	0080                	addi	s0,sp,64
    800049cc:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    800049ce:	00022517          	auipc	a0,0x22
    800049d2:	76a50513          	addi	a0,a0,1898 # 80027138 <ftable>
    800049d6:	ffffc097          	auipc	ra,0xffffc
    800049da:	316080e7          	jalr	790(ra) # 80000cec <acquire>
  if(f->ref < 1)
    800049de:	40dc                	lw	a5,4(s1)
    800049e0:	06f05163          	blez	a5,80004a42 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    800049e4:	37fd                	addiw	a5,a5,-1
    800049e6:	0007871b          	sext.w	a4,a5
    800049ea:	c0dc                	sw	a5,4(s1)
    800049ec:	06e04363          	bgtz	a4,80004a52 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    800049f0:	0004a903          	lw	s2,0(s1)
    800049f4:	0094ca83          	lbu	s5,9(s1)
    800049f8:	0104ba03          	ld	s4,16(s1)
    800049fc:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004a00:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004a04:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004a08:	00022517          	auipc	a0,0x22
    80004a0c:	73050513          	addi	a0,a0,1840 # 80027138 <ftable>
    80004a10:	ffffc097          	auipc	ra,0xffffc
    80004a14:	3ac080e7          	jalr	940(ra) # 80000dbc <release>

  if(ff.type == FD_PIPE){
    80004a18:	4785                	li	a5,1
    80004a1a:	04f90d63          	beq	s2,a5,80004a74 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004a1e:	3979                	addiw	s2,s2,-2
    80004a20:	4785                	li	a5,1
    80004a22:	0527e063          	bltu	a5,s2,80004a62 <fileclose+0xa8>
    begin_op();
    80004a26:	00000097          	auipc	ra,0x0
    80004a2a:	ac4080e7          	jalr	-1340(ra) # 800044ea <begin_op>
    iput(ff.ip);
    80004a2e:	854e                	mv	a0,s3
    80004a30:	fffff097          	auipc	ra,0xfffff
    80004a34:	29a080e7          	jalr	666(ra) # 80003cca <iput>
    end_op();
    80004a38:	00000097          	auipc	ra,0x0
    80004a3c:	b30080e7          	jalr	-1232(ra) # 80004568 <end_op>
    80004a40:	a00d                	j	80004a62 <fileclose+0xa8>
    panic("fileclose");
    80004a42:	00004517          	auipc	a0,0x4
    80004a46:	cb650513          	addi	a0,a0,-842 # 800086f8 <syscalls+0x240>
    80004a4a:	ffffc097          	auipc	ra,0xffffc
    80004a4e:	b02080e7          	jalr	-1278(ra) # 8000054c <panic>
    release(&ftable.lock);
    80004a52:	00022517          	auipc	a0,0x22
    80004a56:	6e650513          	addi	a0,a0,1766 # 80027138 <ftable>
    80004a5a:	ffffc097          	auipc	ra,0xffffc
    80004a5e:	362080e7          	jalr	866(ra) # 80000dbc <release>
  }
}
    80004a62:	70e2                	ld	ra,56(sp)
    80004a64:	7442                	ld	s0,48(sp)
    80004a66:	74a2                	ld	s1,40(sp)
    80004a68:	7902                	ld	s2,32(sp)
    80004a6a:	69e2                	ld	s3,24(sp)
    80004a6c:	6a42                	ld	s4,16(sp)
    80004a6e:	6aa2                	ld	s5,8(sp)
    80004a70:	6121                	addi	sp,sp,64
    80004a72:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004a74:	85d6                	mv	a1,s5
    80004a76:	8552                	mv	a0,s4
    80004a78:	00000097          	auipc	ra,0x0
    80004a7c:	372080e7          	jalr	882(ra) # 80004dea <pipeclose>
    80004a80:	b7cd                	j	80004a62 <fileclose+0xa8>

0000000080004a82 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004a82:	715d                	addi	sp,sp,-80
    80004a84:	e486                	sd	ra,72(sp)
    80004a86:	e0a2                	sd	s0,64(sp)
    80004a88:	fc26                	sd	s1,56(sp)
    80004a8a:	f84a                	sd	s2,48(sp)
    80004a8c:	f44e                	sd	s3,40(sp)
    80004a8e:	0880                	addi	s0,sp,80
    80004a90:	84aa                	mv	s1,a0
    80004a92:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004a94:	ffffd097          	auipc	ra,0xffffd
    80004a98:	29e080e7          	jalr	670(ra) # 80001d32 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004a9c:	409c                	lw	a5,0(s1)
    80004a9e:	37f9                	addiw	a5,a5,-2
    80004aa0:	4705                	li	a4,1
    80004aa2:	04f76763          	bltu	a4,a5,80004af0 <filestat+0x6e>
    80004aa6:	892a                	mv	s2,a0
    ilock(f->ip);
    80004aa8:	6c88                	ld	a0,24(s1)
    80004aaa:	fffff097          	auipc	ra,0xfffff
    80004aae:	066080e7          	jalr	102(ra) # 80003b10 <ilock>
    stati(f->ip, &st);
    80004ab2:	fb840593          	addi	a1,s0,-72
    80004ab6:	6c88                	ld	a0,24(s1)
    80004ab8:	fffff097          	auipc	ra,0xfffff
    80004abc:	2e2080e7          	jalr	738(ra) # 80003d9a <stati>
    iunlock(f->ip);
    80004ac0:	6c88                	ld	a0,24(s1)
    80004ac2:	fffff097          	auipc	ra,0xfffff
    80004ac6:	110080e7          	jalr	272(ra) # 80003bd2 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004aca:	46e1                	li	a3,24
    80004acc:	fb840613          	addi	a2,s0,-72
    80004ad0:	85ce                	mv	a1,s3
    80004ad2:	05893503          	ld	a0,88(s2)
    80004ad6:	ffffd097          	auipc	ra,0xffffd
    80004ada:	f52080e7          	jalr	-174(ra) # 80001a28 <copyout>
    80004ade:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004ae2:	60a6                	ld	ra,72(sp)
    80004ae4:	6406                	ld	s0,64(sp)
    80004ae6:	74e2                	ld	s1,56(sp)
    80004ae8:	7942                	ld	s2,48(sp)
    80004aea:	79a2                	ld	s3,40(sp)
    80004aec:	6161                	addi	sp,sp,80
    80004aee:	8082                	ret
  return -1;
    80004af0:	557d                	li	a0,-1
    80004af2:	bfc5                	j	80004ae2 <filestat+0x60>

0000000080004af4 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004af4:	7179                	addi	sp,sp,-48
    80004af6:	f406                	sd	ra,40(sp)
    80004af8:	f022                	sd	s0,32(sp)
    80004afa:	ec26                	sd	s1,24(sp)
    80004afc:	e84a                	sd	s2,16(sp)
    80004afe:	e44e                	sd	s3,8(sp)
    80004b00:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004b02:	00854783          	lbu	a5,8(a0)
    80004b06:	c3d5                	beqz	a5,80004baa <fileread+0xb6>
    80004b08:	84aa                	mv	s1,a0
    80004b0a:	89ae                	mv	s3,a1
    80004b0c:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004b0e:	411c                	lw	a5,0(a0)
    80004b10:	4705                	li	a4,1
    80004b12:	04e78963          	beq	a5,a4,80004b64 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004b16:	470d                	li	a4,3
    80004b18:	04e78d63          	beq	a5,a4,80004b72 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004b1c:	4709                	li	a4,2
    80004b1e:	06e79e63          	bne	a5,a4,80004b9a <fileread+0xa6>
    ilock(f->ip);
    80004b22:	6d08                	ld	a0,24(a0)
    80004b24:	fffff097          	auipc	ra,0xfffff
    80004b28:	fec080e7          	jalr	-20(ra) # 80003b10 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004b2c:	874a                	mv	a4,s2
    80004b2e:	5094                	lw	a3,32(s1)
    80004b30:	864e                	mv	a2,s3
    80004b32:	4585                	li	a1,1
    80004b34:	6c88                	ld	a0,24(s1)
    80004b36:	fffff097          	auipc	ra,0xfffff
    80004b3a:	28e080e7          	jalr	654(ra) # 80003dc4 <readi>
    80004b3e:	892a                	mv	s2,a0
    80004b40:	00a05563          	blez	a0,80004b4a <fileread+0x56>
      f->off += r;
    80004b44:	509c                	lw	a5,32(s1)
    80004b46:	9fa9                	addw	a5,a5,a0
    80004b48:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004b4a:	6c88                	ld	a0,24(s1)
    80004b4c:	fffff097          	auipc	ra,0xfffff
    80004b50:	086080e7          	jalr	134(ra) # 80003bd2 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004b54:	854a                	mv	a0,s2
    80004b56:	70a2                	ld	ra,40(sp)
    80004b58:	7402                	ld	s0,32(sp)
    80004b5a:	64e2                	ld	s1,24(sp)
    80004b5c:	6942                	ld	s2,16(sp)
    80004b5e:	69a2                	ld	s3,8(sp)
    80004b60:	6145                	addi	sp,sp,48
    80004b62:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004b64:	6908                	ld	a0,16(a0)
    80004b66:	00000097          	auipc	ra,0x0
    80004b6a:	400080e7          	jalr	1024(ra) # 80004f66 <piperead>
    80004b6e:	892a                	mv	s2,a0
    80004b70:	b7d5                	j	80004b54 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004b72:	02451783          	lh	a5,36(a0)
    80004b76:	03079693          	slli	a3,a5,0x30
    80004b7a:	92c1                	srli	a3,a3,0x30
    80004b7c:	4725                	li	a4,9
    80004b7e:	02d76863          	bltu	a4,a3,80004bae <fileread+0xba>
    80004b82:	0792                	slli	a5,a5,0x4
    80004b84:	00022717          	auipc	a4,0x22
    80004b88:	51470713          	addi	a4,a4,1300 # 80027098 <devsw>
    80004b8c:	97ba                	add	a5,a5,a4
    80004b8e:	639c                	ld	a5,0(a5)
    80004b90:	c38d                	beqz	a5,80004bb2 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004b92:	4505                	li	a0,1
    80004b94:	9782                	jalr	a5
    80004b96:	892a                	mv	s2,a0
    80004b98:	bf75                	j	80004b54 <fileread+0x60>
    panic("fileread");
    80004b9a:	00004517          	auipc	a0,0x4
    80004b9e:	b6e50513          	addi	a0,a0,-1170 # 80008708 <syscalls+0x250>
    80004ba2:	ffffc097          	auipc	ra,0xffffc
    80004ba6:	9aa080e7          	jalr	-1622(ra) # 8000054c <panic>
    return -1;
    80004baa:	597d                	li	s2,-1
    80004bac:	b765                	j	80004b54 <fileread+0x60>
      return -1;
    80004bae:	597d                	li	s2,-1
    80004bb0:	b755                	j	80004b54 <fileread+0x60>
    80004bb2:	597d                	li	s2,-1
    80004bb4:	b745                	j	80004b54 <fileread+0x60>

0000000080004bb6 <filewrite>:
int
filewrite(struct file *f, uint64 addr, int n)
{
  int r, ret = 0;

  if(f->writable == 0)
    80004bb6:	00954783          	lbu	a5,9(a0)
    80004bba:	14078563          	beqz	a5,80004d04 <filewrite+0x14e>
{
    80004bbe:	715d                	addi	sp,sp,-80
    80004bc0:	e486                	sd	ra,72(sp)
    80004bc2:	e0a2                	sd	s0,64(sp)
    80004bc4:	fc26                	sd	s1,56(sp)
    80004bc6:	f84a                	sd	s2,48(sp)
    80004bc8:	f44e                	sd	s3,40(sp)
    80004bca:	f052                	sd	s4,32(sp)
    80004bcc:	ec56                	sd	s5,24(sp)
    80004bce:	e85a                	sd	s6,16(sp)
    80004bd0:	e45e                	sd	s7,8(sp)
    80004bd2:	e062                	sd	s8,0(sp)
    80004bd4:	0880                	addi	s0,sp,80
    80004bd6:	892a                	mv	s2,a0
    80004bd8:	8b2e                	mv	s6,a1
    80004bda:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004bdc:	411c                	lw	a5,0(a0)
    80004bde:	4705                	li	a4,1
    80004be0:	02e78263          	beq	a5,a4,80004c04 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004be4:	470d                	li	a4,3
    80004be6:	02e78563          	beq	a5,a4,80004c10 <filewrite+0x5a>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004bea:	4709                	li	a4,2
    80004bec:	10e79463          	bne	a5,a4,80004cf4 <filewrite+0x13e>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004bf0:	0ec05e63          	blez	a2,80004cec <filewrite+0x136>
    int i = 0;
    80004bf4:	4981                	li	s3,0
    80004bf6:	6b85                	lui	s7,0x1
    80004bf8:	c00b8b93          	addi	s7,s7,-1024 # c00 <_entry-0x7ffff400>
    80004bfc:	6c05                	lui	s8,0x1
    80004bfe:	c00c0c1b          	addiw	s8,s8,-1024 # c00 <_entry-0x7ffff400>
    80004c02:	a851                	j	80004c96 <filewrite+0xe0>
    ret = pipewrite(f->pipe, addr, n);
    80004c04:	6908                	ld	a0,16(a0)
    80004c06:	00000097          	auipc	ra,0x0
    80004c0a:	25e080e7          	jalr	606(ra) # 80004e64 <pipewrite>
    80004c0e:	a85d                	j	80004cc4 <filewrite+0x10e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004c10:	02451783          	lh	a5,36(a0)
    80004c14:	03079693          	slli	a3,a5,0x30
    80004c18:	92c1                	srli	a3,a3,0x30
    80004c1a:	4725                	li	a4,9
    80004c1c:	0ed76663          	bltu	a4,a3,80004d08 <filewrite+0x152>
    80004c20:	0792                	slli	a5,a5,0x4
    80004c22:	00022717          	auipc	a4,0x22
    80004c26:	47670713          	addi	a4,a4,1142 # 80027098 <devsw>
    80004c2a:	97ba                	add	a5,a5,a4
    80004c2c:	679c                	ld	a5,8(a5)
    80004c2e:	cff9                	beqz	a5,80004d0c <filewrite+0x156>
    ret = devsw[f->major].write(1, addr, n);
    80004c30:	4505                	li	a0,1
    80004c32:	9782                	jalr	a5
    80004c34:	a841                	j	80004cc4 <filewrite+0x10e>
    80004c36:	00048a9b          	sext.w	s5,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004c3a:	00000097          	auipc	ra,0x0
    80004c3e:	8b0080e7          	jalr	-1872(ra) # 800044ea <begin_op>
      ilock(f->ip);
    80004c42:	01893503          	ld	a0,24(s2)
    80004c46:	fffff097          	auipc	ra,0xfffff
    80004c4a:	eca080e7          	jalr	-310(ra) # 80003b10 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004c4e:	8756                	mv	a4,s5
    80004c50:	02092683          	lw	a3,32(s2)
    80004c54:	01698633          	add	a2,s3,s6
    80004c58:	4585                	li	a1,1
    80004c5a:	01893503          	ld	a0,24(s2)
    80004c5e:	fffff097          	auipc	ra,0xfffff
    80004c62:	25e080e7          	jalr	606(ra) # 80003ebc <writei>
    80004c66:	84aa                	mv	s1,a0
    80004c68:	02a05f63          	blez	a0,80004ca6 <filewrite+0xf0>
        f->off += r;
    80004c6c:	02092783          	lw	a5,32(s2)
    80004c70:	9fa9                	addw	a5,a5,a0
    80004c72:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004c76:	01893503          	ld	a0,24(s2)
    80004c7a:	fffff097          	auipc	ra,0xfffff
    80004c7e:	f58080e7          	jalr	-168(ra) # 80003bd2 <iunlock>
      end_op();
    80004c82:	00000097          	auipc	ra,0x0
    80004c86:	8e6080e7          	jalr	-1818(ra) # 80004568 <end_op>

      if(r < 0)
        break;
      if(r != n1)
    80004c8a:	049a9963          	bne	s5,s1,80004cdc <filewrite+0x126>
        panic("short filewrite");
      i += r;
    80004c8e:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004c92:	0349d663          	bge	s3,s4,80004cbe <filewrite+0x108>
      int n1 = n - i;
    80004c96:	413a04bb          	subw	s1,s4,s3
    80004c9a:	0004879b          	sext.w	a5,s1
    80004c9e:	f8fbdce3          	bge	s7,a5,80004c36 <filewrite+0x80>
    80004ca2:	84e2                	mv	s1,s8
    80004ca4:	bf49                	j	80004c36 <filewrite+0x80>
      iunlock(f->ip);
    80004ca6:	01893503          	ld	a0,24(s2)
    80004caa:	fffff097          	auipc	ra,0xfffff
    80004cae:	f28080e7          	jalr	-216(ra) # 80003bd2 <iunlock>
      end_op();
    80004cb2:	00000097          	auipc	ra,0x0
    80004cb6:	8b6080e7          	jalr	-1866(ra) # 80004568 <end_op>
      if(r < 0)
    80004cba:	fc04d8e3          	bgez	s1,80004c8a <filewrite+0xd4>
    }
    ret = (i == n ? n : -1);
    80004cbe:	8552                	mv	a0,s4
    80004cc0:	033a1863          	bne	s4,s3,80004cf0 <filewrite+0x13a>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004cc4:	60a6                	ld	ra,72(sp)
    80004cc6:	6406                	ld	s0,64(sp)
    80004cc8:	74e2                	ld	s1,56(sp)
    80004cca:	7942                	ld	s2,48(sp)
    80004ccc:	79a2                	ld	s3,40(sp)
    80004cce:	7a02                	ld	s4,32(sp)
    80004cd0:	6ae2                	ld	s5,24(sp)
    80004cd2:	6b42                	ld	s6,16(sp)
    80004cd4:	6ba2                	ld	s7,8(sp)
    80004cd6:	6c02                	ld	s8,0(sp)
    80004cd8:	6161                	addi	sp,sp,80
    80004cda:	8082                	ret
        panic("short filewrite");
    80004cdc:	00004517          	auipc	a0,0x4
    80004ce0:	a3c50513          	addi	a0,a0,-1476 # 80008718 <syscalls+0x260>
    80004ce4:	ffffc097          	auipc	ra,0xffffc
    80004ce8:	868080e7          	jalr	-1944(ra) # 8000054c <panic>
    int i = 0;
    80004cec:	4981                	li	s3,0
    80004cee:	bfc1                	j	80004cbe <filewrite+0x108>
    ret = (i == n ? n : -1);
    80004cf0:	557d                	li	a0,-1
    80004cf2:	bfc9                	j	80004cc4 <filewrite+0x10e>
    panic("filewrite");
    80004cf4:	00004517          	auipc	a0,0x4
    80004cf8:	a3450513          	addi	a0,a0,-1484 # 80008728 <syscalls+0x270>
    80004cfc:	ffffc097          	auipc	ra,0xffffc
    80004d00:	850080e7          	jalr	-1968(ra) # 8000054c <panic>
    return -1;
    80004d04:	557d                	li	a0,-1
}
    80004d06:	8082                	ret
      return -1;
    80004d08:	557d                	li	a0,-1
    80004d0a:	bf6d                	j	80004cc4 <filewrite+0x10e>
    80004d0c:	557d                	li	a0,-1
    80004d0e:	bf5d                	j	80004cc4 <filewrite+0x10e>

0000000080004d10 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004d10:	7179                	addi	sp,sp,-48
    80004d12:	f406                	sd	ra,40(sp)
    80004d14:	f022                	sd	s0,32(sp)
    80004d16:	ec26                	sd	s1,24(sp)
    80004d18:	e84a                	sd	s2,16(sp)
    80004d1a:	e44e                	sd	s3,8(sp)
    80004d1c:	e052                	sd	s4,0(sp)
    80004d1e:	1800                	addi	s0,sp,48
    80004d20:	84aa                	mv	s1,a0
    80004d22:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004d24:	0005b023          	sd	zero,0(a1)
    80004d28:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004d2c:	00000097          	auipc	ra,0x0
    80004d30:	bd2080e7          	jalr	-1070(ra) # 800048fe <filealloc>
    80004d34:	e088                	sd	a0,0(s1)
    80004d36:	c551                	beqz	a0,80004dc2 <pipealloc+0xb2>
    80004d38:	00000097          	auipc	ra,0x0
    80004d3c:	bc6080e7          	jalr	-1082(ra) # 800048fe <filealloc>
    80004d40:	00aa3023          	sd	a0,0(s4)
    80004d44:	c92d                	beqz	a0,80004db6 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004d46:	ffffc097          	auipc	ra,0xffffc
    80004d4a:	e22080e7          	jalr	-478(ra) # 80000b68 <kalloc>
    80004d4e:	892a                	mv	s2,a0
    80004d50:	c125                	beqz	a0,80004db0 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004d52:	4985                	li	s3,1
    80004d54:	23352423          	sw	s3,552(a0)
  pi->writeopen = 1;
    80004d58:	23352623          	sw	s3,556(a0)
  pi->nwrite = 0;
    80004d5c:	22052223          	sw	zero,548(a0)
  pi->nread = 0;
    80004d60:	22052023          	sw	zero,544(a0)
  initlock(&pi->lock, "pipe");
    80004d64:	00004597          	auipc	a1,0x4
    80004d68:	9d458593          	addi	a1,a1,-1580 # 80008738 <syscalls+0x280>
    80004d6c:	ffffc097          	auipc	ra,0xffffc
    80004d70:	0fc080e7          	jalr	252(ra) # 80000e68 <initlock>
  (*f0)->type = FD_PIPE;
    80004d74:	609c                	ld	a5,0(s1)
    80004d76:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004d7a:	609c                	ld	a5,0(s1)
    80004d7c:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004d80:	609c                	ld	a5,0(s1)
    80004d82:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004d86:	609c                	ld	a5,0(s1)
    80004d88:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004d8c:	000a3783          	ld	a5,0(s4)
    80004d90:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004d94:	000a3783          	ld	a5,0(s4)
    80004d98:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004d9c:	000a3783          	ld	a5,0(s4)
    80004da0:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004da4:	000a3783          	ld	a5,0(s4)
    80004da8:	0127b823          	sd	s2,16(a5)
  return 0;
    80004dac:	4501                	li	a0,0
    80004dae:	a025                	j	80004dd6 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004db0:	6088                	ld	a0,0(s1)
    80004db2:	e501                	bnez	a0,80004dba <pipealloc+0xaa>
    80004db4:	a039                	j	80004dc2 <pipealloc+0xb2>
    80004db6:	6088                	ld	a0,0(s1)
    80004db8:	c51d                	beqz	a0,80004de6 <pipealloc+0xd6>
    fileclose(*f0);
    80004dba:	00000097          	auipc	ra,0x0
    80004dbe:	c00080e7          	jalr	-1024(ra) # 800049ba <fileclose>
  if(*f1)
    80004dc2:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004dc6:	557d                	li	a0,-1
  if(*f1)
    80004dc8:	c799                	beqz	a5,80004dd6 <pipealloc+0xc6>
    fileclose(*f1);
    80004dca:	853e                	mv	a0,a5
    80004dcc:	00000097          	auipc	ra,0x0
    80004dd0:	bee080e7          	jalr	-1042(ra) # 800049ba <fileclose>
  return -1;
    80004dd4:	557d                	li	a0,-1
}
    80004dd6:	70a2                	ld	ra,40(sp)
    80004dd8:	7402                	ld	s0,32(sp)
    80004dda:	64e2                	ld	s1,24(sp)
    80004ddc:	6942                	ld	s2,16(sp)
    80004dde:	69a2                	ld	s3,8(sp)
    80004de0:	6a02                	ld	s4,0(sp)
    80004de2:	6145                	addi	sp,sp,48
    80004de4:	8082                	ret
  return -1;
    80004de6:	557d                	li	a0,-1
    80004de8:	b7fd                	j	80004dd6 <pipealloc+0xc6>

0000000080004dea <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004dea:	1101                	addi	sp,sp,-32
    80004dec:	ec06                	sd	ra,24(sp)
    80004dee:	e822                	sd	s0,16(sp)
    80004df0:	e426                	sd	s1,8(sp)
    80004df2:	e04a                	sd	s2,0(sp)
    80004df4:	1000                	addi	s0,sp,32
    80004df6:	84aa                	mv	s1,a0
    80004df8:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004dfa:	ffffc097          	auipc	ra,0xffffc
    80004dfe:	ef2080e7          	jalr	-270(ra) # 80000cec <acquire>
  if(writable){
    80004e02:	04090263          	beqz	s2,80004e46 <pipeclose+0x5c>
    pi->writeopen = 0;
    80004e06:	2204a623          	sw	zero,556(s1)
    wakeup(&pi->nread);
    80004e0a:	22048513          	addi	a0,s1,544
    80004e0e:	ffffe097          	auipc	ra,0xffffe
    80004e12:	8bc080e7          	jalr	-1860(ra) # 800026ca <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004e16:	2284b783          	ld	a5,552(s1)
    80004e1a:	ef9d                	bnez	a5,80004e58 <pipeclose+0x6e>
    release(&pi->lock);
    80004e1c:	8526                	mv	a0,s1
    80004e1e:	ffffc097          	auipc	ra,0xffffc
    80004e22:	f9e080e7          	jalr	-98(ra) # 80000dbc <release>
#ifdef LAB_LOCK
    freelock(&pi->lock);
    80004e26:	8526                	mv	a0,s1
    80004e28:	ffffc097          	auipc	ra,0xffffc
    80004e2c:	fdc080e7          	jalr	-36(ra) # 80000e04 <freelock>
#endif    
    kfree((char*)pi);
    80004e30:	8526                	mv	a0,s1
    80004e32:	ffffc097          	auipc	ra,0xffffc
    80004e36:	be6080e7          	jalr	-1050(ra) # 80000a18 <kfree>
  } else
    release(&pi->lock);
}
    80004e3a:	60e2                	ld	ra,24(sp)
    80004e3c:	6442                	ld	s0,16(sp)
    80004e3e:	64a2                	ld	s1,8(sp)
    80004e40:	6902                	ld	s2,0(sp)
    80004e42:	6105                	addi	sp,sp,32
    80004e44:	8082                	ret
    pi->readopen = 0;
    80004e46:	2204a423          	sw	zero,552(s1)
    wakeup(&pi->nwrite);
    80004e4a:	22448513          	addi	a0,s1,548
    80004e4e:	ffffe097          	auipc	ra,0xffffe
    80004e52:	87c080e7          	jalr	-1924(ra) # 800026ca <wakeup>
    80004e56:	b7c1                	j	80004e16 <pipeclose+0x2c>
    release(&pi->lock);
    80004e58:	8526                	mv	a0,s1
    80004e5a:	ffffc097          	auipc	ra,0xffffc
    80004e5e:	f62080e7          	jalr	-158(ra) # 80000dbc <release>
}
    80004e62:	bfe1                	j	80004e3a <pipeclose+0x50>

0000000080004e64 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004e64:	711d                	addi	sp,sp,-96
    80004e66:	ec86                	sd	ra,88(sp)
    80004e68:	e8a2                	sd	s0,80(sp)
    80004e6a:	e4a6                	sd	s1,72(sp)
    80004e6c:	e0ca                	sd	s2,64(sp)
    80004e6e:	fc4e                	sd	s3,56(sp)
    80004e70:	f852                	sd	s4,48(sp)
    80004e72:	f456                	sd	s5,40(sp)
    80004e74:	f05a                	sd	s6,32(sp)
    80004e76:	ec5e                	sd	s7,24(sp)
    80004e78:	e862                	sd	s8,16(sp)
    80004e7a:	1080                	addi	s0,sp,96
    80004e7c:	84aa                	mv	s1,a0
    80004e7e:	8b2e                	mv	s6,a1
    80004e80:	8ab2                	mv	s5,a2
  int i;
  char ch;
  struct proc *pr = myproc();
    80004e82:	ffffd097          	auipc	ra,0xffffd
    80004e86:	eb0080e7          	jalr	-336(ra) # 80001d32 <myproc>
    80004e8a:	892a                	mv	s2,a0

  acquire(&pi->lock);
    80004e8c:	8526                	mv	a0,s1
    80004e8e:	ffffc097          	auipc	ra,0xffffc
    80004e92:	e5e080e7          	jalr	-418(ra) # 80000cec <acquire>
  for(i = 0; i < n; i++){
    80004e96:	09505863          	blez	s5,80004f26 <pipewrite+0xc2>
    80004e9a:	4b81                	li	s7,0
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
      if(pi->readopen == 0 || pr->killed){
        release(&pi->lock);
        return -1;
      }
      wakeup(&pi->nread);
    80004e9c:	22048a13          	addi	s4,s1,544
      sleep(&pi->nwrite, &pi->lock);
    80004ea0:	22448993          	addi	s3,s1,548
    }
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004ea4:	5c7d                	li	s8,-1
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004ea6:	2204a783          	lw	a5,544(s1)
    80004eaa:	2244a703          	lw	a4,548(s1)
    80004eae:	2007879b          	addiw	a5,a5,512
    80004eb2:	02f71b63          	bne	a4,a5,80004ee8 <pipewrite+0x84>
      if(pi->readopen == 0 || pr->killed){
    80004eb6:	2284a783          	lw	a5,552(s1)
    80004eba:	c3d9                	beqz	a5,80004f40 <pipewrite+0xdc>
    80004ebc:	03892783          	lw	a5,56(s2)
    80004ec0:	e3c1                	bnez	a5,80004f40 <pipewrite+0xdc>
      wakeup(&pi->nread);
    80004ec2:	8552                	mv	a0,s4
    80004ec4:	ffffe097          	auipc	ra,0xffffe
    80004ec8:	806080e7          	jalr	-2042(ra) # 800026ca <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004ecc:	85a6                	mv	a1,s1
    80004ece:	854e                	mv	a0,s3
    80004ed0:	ffffd097          	auipc	ra,0xffffd
    80004ed4:	67a080e7          	jalr	1658(ra) # 8000254a <sleep>
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004ed8:	2204a783          	lw	a5,544(s1)
    80004edc:	2244a703          	lw	a4,548(s1)
    80004ee0:	2007879b          	addiw	a5,a5,512
    80004ee4:	fcf709e3          	beq	a4,a5,80004eb6 <pipewrite+0x52>
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004ee8:	4685                	li	a3,1
    80004eea:	865a                	mv	a2,s6
    80004eec:	faf40593          	addi	a1,s0,-81
    80004ef0:	05893503          	ld	a0,88(s2)
    80004ef4:	ffffd097          	auipc	ra,0xffffd
    80004ef8:	bc0080e7          	jalr	-1088(ra) # 80001ab4 <copyin>
    80004efc:	03850663          	beq	a0,s8,80004f28 <pipewrite+0xc4>
      break;
    pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004f00:	2244a783          	lw	a5,548(s1)
    80004f04:	0017871b          	addiw	a4,a5,1
    80004f08:	22e4a223          	sw	a4,548(s1)
    80004f0c:	1ff7f793          	andi	a5,a5,511
    80004f10:	97a6                	add	a5,a5,s1
    80004f12:	faf44703          	lbu	a4,-81(s0)
    80004f16:	02e78023          	sb	a4,32(a5)
  for(i = 0; i < n; i++){
    80004f1a:	2b85                	addiw	s7,s7,1
    80004f1c:	0b05                	addi	s6,s6,1
    80004f1e:	f97a94e3          	bne	s5,s7,80004ea6 <pipewrite+0x42>
    80004f22:	8bd6                	mv	s7,s5
    80004f24:	a011                	j	80004f28 <pipewrite+0xc4>
    80004f26:	4b81                	li	s7,0
  }
  wakeup(&pi->nread);
    80004f28:	22048513          	addi	a0,s1,544
    80004f2c:	ffffd097          	auipc	ra,0xffffd
    80004f30:	79e080e7          	jalr	1950(ra) # 800026ca <wakeup>
  release(&pi->lock);
    80004f34:	8526                	mv	a0,s1
    80004f36:	ffffc097          	auipc	ra,0xffffc
    80004f3a:	e86080e7          	jalr	-378(ra) # 80000dbc <release>
  return i;
    80004f3e:	a039                	j	80004f4c <pipewrite+0xe8>
        release(&pi->lock);
    80004f40:	8526                	mv	a0,s1
    80004f42:	ffffc097          	auipc	ra,0xffffc
    80004f46:	e7a080e7          	jalr	-390(ra) # 80000dbc <release>
        return -1;
    80004f4a:	5bfd                	li	s7,-1
}
    80004f4c:	855e                	mv	a0,s7
    80004f4e:	60e6                	ld	ra,88(sp)
    80004f50:	6446                	ld	s0,80(sp)
    80004f52:	64a6                	ld	s1,72(sp)
    80004f54:	6906                	ld	s2,64(sp)
    80004f56:	79e2                	ld	s3,56(sp)
    80004f58:	7a42                	ld	s4,48(sp)
    80004f5a:	7aa2                	ld	s5,40(sp)
    80004f5c:	7b02                	ld	s6,32(sp)
    80004f5e:	6be2                	ld	s7,24(sp)
    80004f60:	6c42                	ld	s8,16(sp)
    80004f62:	6125                	addi	sp,sp,96
    80004f64:	8082                	ret

0000000080004f66 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004f66:	715d                	addi	sp,sp,-80
    80004f68:	e486                	sd	ra,72(sp)
    80004f6a:	e0a2                	sd	s0,64(sp)
    80004f6c:	fc26                	sd	s1,56(sp)
    80004f6e:	f84a                	sd	s2,48(sp)
    80004f70:	f44e                	sd	s3,40(sp)
    80004f72:	f052                	sd	s4,32(sp)
    80004f74:	ec56                	sd	s5,24(sp)
    80004f76:	e85a                	sd	s6,16(sp)
    80004f78:	0880                	addi	s0,sp,80
    80004f7a:	84aa                	mv	s1,a0
    80004f7c:	892e                	mv	s2,a1
    80004f7e:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004f80:	ffffd097          	auipc	ra,0xffffd
    80004f84:	db2080e7          	jalr	-590(ra) # 80001d32 <myproc>
    80004f88:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004f8a:	8526                	mv	a0,s1
    80004f8c:	ffffc097          	auipc	ra,0xffffc
    80004f90:	d60080e7          	jalr	-672(ra) # 80000cec <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004f94:	2204a703          	lw	a4,544(s1)
    80004f98:	2244a783          	lw	a5,548(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004f9c:	22048993          	addi	s3,s1,544
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004fa0:	02f71463          	bne	a4,a5,80004fc8 <piperead+0x62>
    80004fa4:	22c4a783          	lw	a5,556(s1)
    80004fa8:	c385                	beqz	a5,80004fc8 <piperead+0x62>
    if(pr->killed){
    80004faa:	038a2783          	lw	a5,56(s4)
    80004fae:	ebc9                	bnez	a5,80005040 <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004fb0:	85a6                	mv	a1,s1
    80004fb2:	854e                	mv	a0,s3
    80004fb4:	ffffd097          	auipc	ra,0xffffd
    80004fb8:	596080e7          	jalr	1430(ra) # 8000254a <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004fbc:	2204a703          	lw	a4,544(s1)
    80004fc0:	2244a783          	lw	a5,548(s1)
    80004fc4:	fef700e3          	beq	a4,a5,80004fa4 <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004fc8:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004fca:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004fcc:	05505463          	blez	s5,80005014 <piperead+0xae>
    if(pi->nread == pi->nwrite)
    80004fd0:	2204a783          	lw	a5,544(s1)
    80004fd4:	2244a703          	lw	a4,548(s1)
    80004fd8:	02f70e63          	beq	a4,a5,80005014 <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004fdc:	0017871b          	addiw	a4,a5,1
    80004fe0:	22e4a023          	sw	a4,544(s1)
    80004fe4:	1ff7f793          	andi	a5,a5,511
    80004fe8:	97a6                	add	a5,a5,s1
    80004fea:	0207c783          	lbu	a5,32(a5)
    80004fee:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004ff2:	4685                	li	a3,1
    80004ff4:	fbf40613          	addi	a2,s0,-65
    80004ff8:	85ca                	mv	a1,s2
    80004ffa:	058a3503          	ld	a0,88(s4)
    80004ffe:	ffffd097          	auipc	ra,0xffffd
    80005002:	a2a080e7          	jalr	-1494(ra) # 80001a28 <copyout>
    80005006:	01650763          	beq	a0,s6,80005014 <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    8000500a:	2985                	addiw	s3,s3,1
    8000500c:	0905                	addi	s2,s2,1
    8000500e:	fd3a91e3          	bne	s5,s3,80004fd0 <piperead+0x6a>
    80005012:	89d6                	mv	s3,s5
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80005014:	22448513          	addi	a0,s1,548
    80005018:	ffffd097          	auipc	ra,0xffffd
    8000501c:	6b2080e7          	jalr	1714(ra) # 800026ca <wakeup>
  release(&pi->lock);
    80005020:	8526                	mv	a0,s1
    80005022:	ffffc097          	auipc	ra,0xffffc
    80005026:	d9a080e7          	jalr	-614(ra) # 80000dbc <release>
  return i;
}
    8000502a:	854e                	mv	a0,s3
    8000502c:	60a6                	ld	ra,72(sp)
    8000502e:	6406                	ld	s0,64(sp)
    80005030:	74e2                	ld	s1,56(sp)
    80005032:	7942                	ld	s2,48(sp)
    80005034:	79a2                	ld	s3,40(sp)
    80005036:	7a02                	ld	s4,32(sp)
    80005038:	6ae2                	ld	s5,24(sp)
    8000503a:	6b42                	ld	s6,16(sp)
    8000503c:	6161                	addi	sp,sp,80
    8000503e:	8082                	ret
      release(&pi->lock);
    80005040:	8526                	mv	a0,s1
    80005042:	ffffc097          	auipc	ra,0xffffc
    80005046:	d7a080e7          	jalr	-646(ra) # 80000dbc <release>
      return -1;
    8000504a:	59fd                	li	s3,-1
    8000504c:	bff9                	j	8000502a <piperead+0xc4>

000000008000504e <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    8000504e:	de010113          	addi	sp,sp,-544
    80005052:	20113c23          	sd	ra,536(sp)
    80005056:	20813823          	sd	s0,528(sp)
    8000505a:	20913423          	sd	s1,520(sp)
    8000505e:	21213023          	sd	s2,512(sp)
    80005062:	ffce                	sd	s3,504(sp)
    80005064:	fbd2                	sd	s4,496(sp)
    80005066:	f7d6                	sd	s5,488(sp)
    80005068:	f3da                	sd	s6,480(sp)
    8000506a:	efde                	sd	s7,472(sp)
    8000506c:	ebe2                	sd	s8,464(sp)
    8000506e:	e7e6                	sd	s9,456(sp)
    80005070:	e3ea                	sd	s10,448(sp)
    80005072:	ff6e                	sd	s11,440(sp)
    80005074:	1400                	addi	s0,sp,544
    80005076:	892a                	mv	s2,a0
    80005078:	dea43423          	sd	a0,-536(s0)
    8000507c:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80005080:	ffffd097          	auipc	ra,0xffffd
    80005084:	cb2080e7          	jalr	-846(ra) # 80001d32 <myproc>
    80005088:	84aa                	mv	s1,a0

  begin_op();
    8000508a:	fffff097          	auipc	ra,0xfffff
    8000508e:	460080e7          	jalr	1120(ra) # 800044ea <begin_op>

  if((ip = namei(path)) == 0){
    80005092:	854a                	mv	a0,s2
    80005094:	fffff097          	auipc	ra,0xfffff
    80005098:	236080e7          	jalr	566(ra) # 800042ca <namei>
    8000509c:	c93d                	beqz	a0,80005112 <exec+0xc4>
    8000509e:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    800050a0:	fffff097          	auipc	ra,0xfffff
    800050a4:	a70080e7          	jalr	-1424(ra) # 80003b10 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    800050a8:	04000713          	li	a4,64
    800050ac:	4681                	li	a3,0
    800050ae:	e4840613          	addi	a2,s0,-440
    800050b2:	4581                	li	a1,0
    800050b4:	8556                	mv	a0,s5
    800050b6:	fffff097          	auipc	ra,0xfffff
    800050ba:	d0e080e7          	jalr	-754(ra) # 80003dc4 <readi>
    800050be:	04000793          	li	a5,64
    800050c2:	00f51a63          	bne	a0,a5,800050d6 <exec+0x88>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    800050c6:	e4842703          	lw	a4,-440(s0)
    800050ca:	464c47b7          	lui	a5,0x464c4
    800050ce:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    800050d2:	04f70663          	beq	a4,a5,8000511e <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    800050d6:	8556                	mv	a0,s5
    800050d8:	fffff097          	auipc	ra,0xfffff
    800050dc:	c9a080e7          	jalr	-870(ra) # 80003d72 <iunlockput>
    end_op();
    800050e0:	fffff097          	auipc	ra,0xfffff
    800050e4:	488080e7          	jalr	1160(ra) # 80004568 <end_op>
  }
  return -1;
    800050e8:	557d                	li	a0,-1
}
    800050ea:	21813083          	ld	ra,536(sp)
    800050ee:	21013403          	ld	s0,528(sp)
    800050f2:	20813483          	ld	s1,520(sp)
    800050f6:	20013903          	ld	s2,512(sp)
    800050fa:	79fe                	ld	s3,504(sp)
    800050fc:	7a5e                	ld	s4,496(sp)
    800050fe:	7abe                	ld	s5,488(sp)
    80005100:	7b1e                	ld	s6,480(sp)
    80005102:	6bfe                	ld	s7,472(sp)
    80005104:	6c5e                	ld	s8,464(sp)
    80005106:	6cbe                	ld	s9,456(sp)
    80005108:	6d1e                	ld	s10,448(sp)
    8000510a:	7dfa                	ld	s11,440(sp)
    8000510c:	22010113          	addi	sp,sp,544
    80005110:	8082                	ret
    end_op();
    80005112:	fffff097          	auipc	ra,0xfffff
    80005116:	456080e7          	jalr	1110(ra) # 80004568 <end_op>
    return -1;
    8000511a:	557d                	li	a0,-1
    8000511c:	b7f9                	j	800050ea <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    8000511e:	8526                	mv	a0,s1
    80005120:	ffffd097          	auipc	ra,0xffffd
    80005124:	cd6080e7          	jalr	-810(ra) # 80001df6 <proc_pagetable>
    80005128:	8b2a                	mv	s6,a0
    8000512a:	d555                	beqz	a0,800050d6 <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000512c:	e6842783          	lw	a5,-408(s0)
    80005130:	e8045703          	lhu	a4,-384(s0)
    80005134:	c735                	beqz	a4,800051a0 <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80005136:	4481                	li	s1,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005138:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    8000513c:	6a05                	lui	s4,0x1
    8000513e:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    80005142:	dee43023          	sd	a4,-544(s0)
  uint64 pa;

  if((va % PGSIZE) != 0)
    panic("loadseg: va must be page aligned");

  for(i = 0; i < sz; i += PGSIZE){
    80005146:	6d85                	lui	s11,0x1
    80005148:	7d7d                	lui	s10,0xfffff
    8000514a:	ac1d                	j	80005380 <exec+0x332>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    8000514c:	00003517          	auipc	a0,0x3
    80005150:	5f450513          	addi	a0,a0,1524 # 80008740 <syscalls+0x288>
    80005154:	ffffb097          	auipc	ra,0xffffb
    80005158:	3f8080e7          	jalr	1016(ra) # 8000054c <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    8000515c:	874a                	mv	a4,s2
    8000515e:	009c86bb          	addw	a3,s9,s1
    80005162:	4581                	li	a1,0
    80005164:	8556                	mv	a0,s5
    80005166:	fffff097          	auipc	ra,0xfffff
    8000516a:	c5e080e7          	jalr	-930(ra) # 80003dc4 <readi>
    8000516e:	2501                	sext.w	a0,a0
    80005170:	1aa91863          	bne	s2,a0,80005320 <exec+0x2d2>
  for(i = 0; i < sz; i += PGSIZE){
    80005174:	009d84bb          	addw	s1,s11,s1
    80005178:	013d09bb          	addw	s3,s10,s3
    8000517c:	1f74f263          	bgeu	s1,s7,80005360 <exec+0x312>
    pa = walkaddr(pagetable, va + i);
    80005180:	02049593          	slli	a1,s1,0x20
    80005184:	9181                	srli	a1,a1,0x20
    80005186:	95e2                	add	a1,a1,s8
    80005188:	855a                	mv	a0,s6
    8000518a:	ffffc097          	auipc	ra,0xffffc
    8000518e:	2d8080e7          	jalr	728(ra) # 80001462 <walkaddr>
    80005192:	862a                	mv	a2,a0
    if(pa == 0)
    80005194:	dd45                	beqz	a0,8000514c <exec+0xfe>
      n = PGSIZE;
    80005196:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    80005198:	fd49f2e3          	bgeu	s3,s4,8000515c <exec+0x10e>
      n = sz - i;
    8000519c:	894e                	mv	s2,s3
    8000519e:	bf7d                	j	8000515c <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    800051a0:	4481                	li	s1,0
  iunlockput(ip);
    800051a2:	8556                	mv	a0,s5
    800051a4:	fffff097          	auipc	ra,0xfffff
    800051a8:	bce080e7          	jalr	-1074(ra) # 80003d72 <iunlockput>
  end_op();
    800051ac:	fffff097          	auipc	ra,0xfffff
    800051b0:	3bc080e7          	jalr	956(ra) # 80004568 <end_op>
  p = myproc();
    800051b4:	ffffd097          	auipc	ra,0xffffd
    800051b8:	b7e080e7          	jalr	-1154(ra) # 80001d32 <myproc>
    800051bc:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    800051be:	05053d03          	ld	s10,80(a0)
  sz = PGROUNDUP(sz);
    800051c2:	6785                	lui	a5,0x1
    800051c4:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    800051c6:	97a6                	add	a5,a5,s1
    800051c8:	777d                	lui	a4,0xfffff
    800051ca:	8ff9                	and	a5,a5,a4
    800051cc:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    800051d0:	6609                	lui	a2,0x2
    800051d2:	963e                	add	a2,a2,a5
    800051d4:	85be                	mv	a1,a5
    800051d6:	855a                	mv	a0,s6
    800051d8:	ffffc097          	auipc	ra,0xffffc
    800051dc:	5fc080e7          	jalr	1532(ra) # 800017d4 <uvmalloc>
    800051e0:	8c2a                	mv	s8,a0
  ip = 0;
    800051e2:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    800051e4:	12050e63          	beqz	a0,80005320 <exec+0x2d2>
  uvmclear(pagetable, sz-2*PGSIZE);
    800051e8:	75f9                	lui	a1,0xffffe
    800051ea:	95aa                	add	a1,a1,a0
    800051ec:	855a                	mv	a0,s6
    800051ee:	ffffd097          	auipc	ra,0xffffd
    800051f2:	808080e7          	jalr	-2040(ra) # 800019f6 <uvmclear>
  stackbase = sp - PGSIZE;
    800051f6:	7afd                	lui	s5,0xfffff
    800051f8:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    800051fa:	df043783          	ld	a5,-528(s0)
    800051fe:	6388                	ld	a0,0(a5)
    80005200:	c925                	beqz	a0,80005270 <exec+0x222>
    80005202:	e8840993          	addi	s3,s0,-376
    80005206:	f8840c93          	addi	s9,s0,-120
  sp = sz;
    8000520a:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    8000520c:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    8000520e:	ffffc097          	auipc	ra,0xffffc
    80005212:	042080e7          	jalr	66(ra) # 80001250 <strlen>
    80005216:	0015079b          	addiw	a5,a0,1
    8000521a:	40f907b3          	sub	a5,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    8000521e:	ff07f913          	andi	s2,a5,-16
    if(sp < stackbase)
    80005222:	13596363          	bltu	s2,s5,80005348 <exec+0x2fa>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80005226:	df043d83          	ld	s11,-528(s0)
    8000522a:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    8000522e:	8552                	mv	a0,s4
    80005230:	ffffc097          	auipc	ra,0xffffc
    80005234:	020080e7          	jalr	32(ra) # 80001250 <strlen>
    80005238:	0015069b          	addiw	a3,a0,1
    8000523c:	8652                	mv	a2,s4
    8000523e:	85ca                	mv	a1,s2
    80005240:	855a                	mv	a0,s6
    80005242:	ffffc097          	auipc	ra,0xffffc
    80005246:	7e6080e7          	jalr	2022(ra) # 80001a28 <copyout>
    8000524a:	10054363          	bltz	a0,80005350 <exec+0x302>
    ustack[argc] = sp;
    8000524e:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80005252:	0485                	addi	s1,s1,1
    80005254:	008d8793          	addi	a5,s11,8
    80005258:	def43823          	sd	a5,-528(s0)
    8000525c:	008db503          	ld	a0,8(s11)
    80005260:	c911                	beqz	a0,80005274 <exec+0x226>
    if(argc >= MAXARG)
    80005262:	09a1                	addi	s3,s3,8
    80005264:	fb3c95e3          	bne	s9,s3,8000520e <exec+0x1c0>
  sz = sz1;
    80005268:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    8000526c:	4a81                	li	s5,0
    8000526e:	a84d                	j	80005320 <exec+0x2d2>
  sp = sz;
    80005270:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80005272:	4481                	li	s1,0
  ustack[argc] = 0;
    80005274:	00349793          	slli	a5,s1,0x3
    80005278:	f9078793          	addi	a5,a5,-112
    8000527c:	97a2                	add	a5,a5,s0
    8000527e:	ee07bc23          	sd	zero,-264(a5)
  sp -= (argc+1) * sizeof(uint64);
    80005282:	00148693          	addi	a3,s1,1
    80005286:	068e                	slli	a3,a3,0x3
    80005288:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    8000528c:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80005290:	01597663          	bgeu	s2,s5,8000529c <exec+0x24e>
  sz = sz1;
    80005294:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005298:	4a81                	li	s5,0
    8000529a:	a059                	j	80005320 <exec+0x2d2>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    8000529c:	e8840613          	addi	a2,s0,-376
    800052a0:	85ca                	mv	a1,s2
    800052a2:	855a                	mv	a0,s6
    800052a4:	ffffc097          	auipc	ra,0xffffc
    800052a8:	784080e7          	jalr	1924(ra) # 80001a28 <copyout>
    800052ac:	0a054663          	bltz	a0,80005358 <exec+0x30a>
  p->trapframe->a1 = sp;
    800052b0:	060bb783          	ld	a5,96(s7)
    800052b4:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    800052b8:	de843783          	ld	a5,-536(s0)
    800052bc:	0007c703          	lbu	a4,0(a5)
    800052c0:	cf11                	beqz	a4,800052dc <exec+0x28e>
    800052c2:	0785                	addi	a5,a5,1
    if(*s == '/')
    800052c4:	02f00693          	li	a3,47
    800052c8:	a039                	j	800052d6 <exec+0x288>
      last = s+1;
    800052ca:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    800052ce:	0785                	addi	a5,a5,1
    800052d0:	fff7c703          	lbu	a4,-1(a5)
    800052d4:	c701                	beqz	a4,800052dc <exec+0x28e>
    if(*s == '/')
    800052d6:	fed71ce3          	bne	a4,a3,800052ce <exec+0x280>
    800052da:	bfc5                	j	800052ca <exec+0x27c>
  safestrcpy(p->name, last, sizeof(p->name));
    800052dc:	4641                	li	a2,16
    800052de:	de843583          	ld	a1,-536(s0)
    800052e2:	160b8513          	addi	a0,s7,352
    800052e6:	ffffc097          	auipc	ra,0xffffc
    800052ea:	f38080e7          	jalr	-200(ra) # 8000121e <safestrcpy>
  oldpagetable = p->pagetable;
    800052ee:	058bb503          	ld	a0,88(s7)
  p->pagetable = pagetable;
    800052f2:	056bbc23          	sd	s6,88(s7)
  p->sz = sz;
    800052f6:	058bb823          	sd	s8,80(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    800052fa:	060bb783          	ld	a5,96(s7)
    800052fe:	e6043703          	ld	a4,-416(s0)
    80005302:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80005304:	060bb783          	ld	a5,96(s7)
    80005308:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    8000530c:	85ea                	mv	a1,s10
    8000530e:	ffffd097          	auipc	ra,0xffffd
    80005312:	b84080e7          	jalr	-1148(ra) # 80001e92 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80005316:	0004851b          	sext.w	a0,s1
    8000531a:	bbc1                	j	800050ea <exec+0x9c>
    8000531c:	de943c23          	sd	s1,-520(s0)
    proc_freepagetable(pagetable, sz);
    80005320:	df843583          	ld	a1,-520(s0)
    80005324:	855a                	mv	a0,s6
    80005326:	ffffd097          	auipc	ra,0xffffd
    8000532a:	b6c080e7          	jalr	-1172(ra) # 80001e92 <proc_freepagetable>
  if(ip){
    8000532e:	da0a94e3          	bnez	s5,800050d6 <exec+0x88>
  return -1;
    80005332:	557d                	li	a0,-1
    80005334:	bb5d                	j	800050ea <exec+0x9c>
    80005336:	de943c23          	sd	s1,-520(s0)
    8000533a:	b7dd                	j	80005320 <exec+0x2d2>
    8000533c:	de943c23          	sd	s1,-520(s0)
    80005340:	b7c5                	j	80005320 <exec+0x2d2>
    80005342:	de943c23          	sd	s1,-520(s0)
    80005346:	bfe9                	j	80005320 <exec+0x2d2>
  sz = sz1;
    80005348:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    8000534c:	4a81                	li	s5,0
    8000534e:	bfc9                	j	80005320 <exec+0x2d2>
  sz = sz1;
    80005350:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005354:	4a81                	li	s5,0
    80005356:	b7e9                	j	80005320 <exec+0x2d2>
  sz = sz1;
    80005358:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    8000535c:	4a81                	li	s5,0
    8000535e:	b7c9                	j	80005320 <exec+0x2d2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005360:	df843483          	ld	s1,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005364:	e0843783          	ld	a5,-504(s0)
    80005368:	0017869b          	addiw	a3,a5,1
    8000536c:	e0d43423          	sd	a3,-504(s0)
    80005370:	e0043783          	ld	a5,-512(s0)
    80005374:	0387879b          	addiw	a5,a5,56
    80005378:	e8045703          	lhu	a4,-384(s0)
    8000537c:	e2e6d3e3          	bge	a3,a4,800051a2 <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005380:	2781                	sext.w	a5,a5
    80005382:	e0f43023          	sd	a5,-512(s0)
    80005386:	03800713          	li	a4,56
    8000538a:	86be                	mv	a3,a5
    8000538c:	e1040613          	addi	a2,s0,-496
    80005390:	4581                	li	a1,0
    80005392:	8556                	mv	a0,s5
    80005394:	fffff097          	auipc	ra,0xfffff
    80005398:	a30080e7          	jalr	-1488(ra) # 80003dc4 <readi>
    8000539c:	03800793          	li	a5,56
    800053a0:	f6f51ee3          	bne	a0,a5,8000531c <exec+0x2ce>
    if(ph.type != ELF_PROG_LOAD)
    800053a4:	e1042783          	lw	a5,-496(s0)
    800053a8:	4705                	li	a4,1
    800053aa:	fae79de3          	bne	a5,a4,80005364 <exec+0x316>
    if(ph.memsz < ph.filesz)
    800053ae:	e3843603          	ld	a2,-456(s0)
    800053b2:	e3043783          	ld	a5,-464(s0)
    800053b6:	f8f660e3          	bltu	a2,a5,80005336 <exec+0x2e8>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    800053ba:	e2043783          	ld	a5,-480(s0)
    800053be:	963e                	add	a2,a2,a5
    800053c0:	f6f66ee3          	bltu	a2,a5,8000533c <exec+0x2ee>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    800053c4:	85a6                	mv	a1,s1
    800053c6:	855a                	mv	a0,s6
    800053c8:	ffffc097          	auipc	ra,0xffffc
    800053cc:	40c080e7          	jalr	1036(ra) # 800017d4 <uvmalloc>
    800053d0:	dea43c23          	sd	a0,-520(s0)
    800053d4:	d53d                	beqz	a0,80005342 <exec+0x2f4>
    if(ph.vaddr % PGSIZE != 0)
    800053d6:	e2043c03          	ld	s8,-480(s0)
    800053da:	de043783          	ld	a5,-544(s0)
    800053de:	00fc77b3          	and	a5,s8,a5
    800053e2:	ff9d                	bnez	a5,80005320 <exec+0x2d2>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    800053e4:	e1842c83          	lw	s9,-488(s0)
    800053e8:	e3042b83          	lw	s7,-464(s0)
  for(i = 0; i < sz; i += PGSIZE){
    800053ec:	f60b8ae3          	beqz	s7,80005360 <exec+0x312>
    800053f0:	89de                	mv	s3,s7
    800053f2:	4481                	li	s1,0
    800053f4:	b371                	j	80005180 <exec+0x132>

00000000800053f6 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    800053f6:	7179                	addi	sp,sp,-48
    800053f8:	f406                	sd	ra,40(sp)
    800053fa:	f022                	sd	s0,32(sp)
    800053fc:	ec26                	sd	s1,24(sp)
    800053fe:	e84a                	sd	s2,16(sp)
    80005400:	1800                	addi	s0,sp,48
    80005402:	892e                	mv	s2,a1
    80005404:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80005406:	fdc40593          	addi	a1,s0,-36
    8000540a:	ffffe097          	auipc	ra,0xffffe
    8000540e:	9e8080e7          	jalr	-1560(ra) # 80002df2 <argint>
    80005412:	04054063          	bltz	a0,80005452 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005416:	fdc42703          	lw	a4,-36(s0)
    8000541a:	47bd                	li	a5,15
    8000541c:	02e7ed63          	bltu	a5,a4,80005456 <argfd+0x60>
    80005420:	ffffd097          	auipc	ra,0xffffd
    80005424:	912080e7          	jalr	-1774(ra) # 80001d32 <myproc>
    80005428:	fdc42703          	lw	a4,-36(s0)
    8000542c:	01a70793          	addi	a5,a4,26 # fffffffffffff01a <end+0xffffffff7ffd1ff2>
    80005430:	078e                	slli	a5,a5,0x3
    80005432:	953e                	add	a0,a0,a5
    80005434:	651c                	ld	a5,8(a0)
    80005436:	c395                	beqz	a5,8000545a <argfd+0x64>
    return -1;
  if(pfd)
    80005438:	00090463          	beqz	s2,80005440 <argfd+0x4a>
    *pfd = fd;
    8000543c:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005440:	4501                	li	a0,0
  if(pf)
    80005442:	c091                	beqz	s1,80005446 <argfd+0x50>
    *pf = f;
    80005444:	e09c                	sd	a5,0(s1)
}
    80005446:	70a2                	ld	ra,40(sp)
    80005448:	7402                	ld	s0,32(sp)
    8000544a:	64e2                	ld	s1,24(sp)
    8000544c:	6942                	ld	s2,16(sp)
    8000544e:	6145                	addi	sp,sp,48
    80005450:	8082                	ret
    return -1;
    80005452:	557d                	li	a0,-1
    80005454:	bfcd                	j	80005446 <argfd+0x50>
    return -1;
    80005456:	557d                	li	a0,-1
    80005458:	b7fd                	j	80005446 <argfd+0x50>
    8000545a:	557d                	li	a0,-1
    8000545c:	b7ed                	j	80005446 <argfd+0x50>

000000008000545e <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    8000545e:	1101                	addi	sp,sp,-32
    80005460:	ec06                	sd	ra,24(sp)
    80005462:	e822                	sd	s0,16(sp)
    80005464:	e426                	sd	s1,8(sp)
    80005466:	1000                	addi	s0,sp,32
    80005468:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    8000546a:	ffffd097          	auipc	ra,0xffffd
    8000546e:	8c8080e7          	jalr	-1848(ra) # 80001d32 <myproc>
    80005472:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005474:	0d850793          	addi	a5,a0,216
    80005478:	4501                	li	a0,0
    8000547a:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    8000547c:	6398                	ld	a4,0(a5)
    8000547e:	cb19                	beqz	a4,80005494 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005480:	2505                	addiw	a0,a0,1
    80005482:	07a1                	addi	a5,a5,8
    80005484:	fed51ce3          	bne	a0,a3,8000547c <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005488:	557d                	li	a0,-1
}
    8000548a:	60e2                	ld	ra,24(sp)
    8000548c:	6442                	ld	s0,16(sp)
    8000548e:	64a2                	ld	s1,8(sp)
    80005490:	6105                	addi	sp,sp,32
    80005492:	8082                	ret
      p->ofile[fd] = f;
    80005494:	01a50793          	addi	a5,a0,26
    80005498:	078e                	slli	a5,a5,0x3
    8000549a:	963e                	add	a2,a2,a5
    8000549c:	e604                	sd	s1,8(a2)
      return fd;
    8000549e:	b7f5                	j	8000548a <fdalloc+0x2c>

00000000800054a0 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    800054a0:	715d                	addi	sp,sp,-80
    800054a2:	e486                	sd	ra,72(sp)
    800054a4:	e0a2                	sd	s0,64(sp)
    800054a6:	fc26                	sd	s1,56(sp)
    800054a8:	f84a                	sd	s2,48(sp)
    800054aa:	f44e                	sd	s3,40(sp)
    800054ac:	f052                	sd	s4,32(sp)
    800054ae:	ec56                	sd	s5,24(sp)
    800054b0:	0880                	addi	s0,sp,80
    800054b2:	89ae                	mv	s3,a1
    800054b4:	8ab2                	mv	s5,a2
    800054b6:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    800054b8:	fb040593          	addi	a1,s0,-80
    800054bc:	fffff097          	auipc	ra,0xfffff
    800054c0:	e2c080e7          	jalr	-468(ra) # 800042e8 <nameiparent>
    800054c4:	892a                	mv	s2,a0
    800054c6:	12050e63          	beqz	a0,80005602 <create+0x162>
    return 0;

  ilock(dp);
    800054ca:	ffffe097          	auipc	ra,0xffffe
    800054ce:	646080e7          	jalr	1606(ra) # 80003b10 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    800054d2:	4601                	li	a2,0
    800054d4:	fb040593          	addi	a1,s0,-80
    800054d8:	854a                	mv	a0,s2
    800054da:	fffff097          	auipc	ra,0xfffff
    800054de:	b18080e7          	jalr	-1256(ra) # 80003ff2 <dirlookup>
    800054e2:	84aa                	mv	s1,a0
    800054e4:	c921                	beqz	a0,80005534 <create+0x94>
    iunlockput(dp);
    800054e6:	854a                	mv	a0,s2
    800054e8:	fffff097          	auipc	ra,0xfffff
    800054ec:	88a080e7          	jalr	-1910(ra) # 80003d72 <iunlockput>
    ilock(ip);
    800054f0:	8526                	mv	a0,s1
    800054f2:	ffffe097          	auipc	ra,0xffffe
    800054f6:	61e080e7          	jalr	1566(ra) # 80003b10 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800054fa:	2981                	sext.w	s3,s3
    800054fc:	4789                	li	a5,2
    800054fe:	02f99463          	bne	s3,a5,80005526 <create+0x86>
    80005502:	04c4d783          	lhu	a5,76(s1)
    80005506:	37f9                	addiw	a5,a5,-2
    80005508:	17c2                	slli	a5,a5,0x30
    8000550a:	93c1                	srli	a5,a5,0x30
    8000550c:	4705                	li	a4,1
    8000550e:	00f76c63          	bltu	a4,a5,80005526 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    80005512:	8526                	mv	a0,s1
    80005514:	60a6                	ld	ra,72(sp)
    80005516:	6406                	ld	s0,64(sp)
    80005518:	74e2                	ld	s1,56(sp)
    8000551a:	7942                	ld	s2,48(sp)
    8000551c:	79a2                	ld	s3,40(sp)
    8000551e:	7a02                	ld	s4,32(sp)
    80005520:	6ae2                	ld	s5,24(sp)
    80005522:	6161                	addi	sp,sp,80
    80005524:	8082                	ret
    iunlockput(ip);
    80005526:	8526                	mv	a0,s1
    80005528:	fffff097          	auipc	ra,0xfffff
    8000552c:	84a080e7          	jalr	-1974(ra) # 80003d72 <iunlockput>
    return 0;
    80005530:	4481                	li	s1,0
    80005532:	b7c5                	j	80005512 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    80005534:	85ce                	mv	a1,s3
    80005536:	00092503          	lw	a0,0(s2)
    8000553a:	ffffe097          	auipc	ra,0xffffe
    8000553e:	43c080e7          	jalr	1084(ra) # 80003976 <ialloc>
    80005542:	84aa                	mv	s1,a0
    80005544:	c521                	beqz	a0,8000558c <create+0xec>
  ilock(ip);
    80005546:	ffffe097          	auipc	ra,0xffffe
    8000554a:	5ca080e7          	jalr	1482(ra) # 80003b10 <ilock>
  ip->major = major;
    8000554e:	05549723          	sh	s5,78(s1)
  ip->minor = minor;
    80005552:	05449823          	sh	s4,80(s1)
  ip->nlink = 1;
    80005556:	4a05                	li	s4,1
    80005558:	05449923          	sh	s4,82(s1)
  iupdate(ip);
    8000555c:	8526                	mv	a0,s1
    8000555e:	ffffe097          	auipc	ra,0xffffe
    80005562:	4e6080e7          	jalr	1254(ra) # 80003a44 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005566:	2981                	sext.w	s3,s3
    80005568:	03498a63          	beq	s3,s4,8000559c <create+0xfc>
  if(dirlink(dp, name, ip->inum) < 0)
    8000556c:	40d0                	lw	a2,4(s1)
    8000556e:	fb040593          	addi	a1,s0,-80
    80005572:	854a                	mv	a0,s2
    80005574:	fffff097          	auipc	ra,0xfffff
    80005578:	c94080e7          	jalr	-876(ra) # 80004208 <dirlink>
    8000557c:	06054b63          	bltz	a0,800055f2 <create+0x152>
  iunlockput(dp);
    80005580:	854a                	mv	a0,s2
    80005582:	ffffe097          	auipc	ra,0xffffe
    80005586:	7f0080e7          	jalr	2032(ra) # 80003d72 <iunlockput>
  return ip;
    8000558a:	b761                	j	80005512 <create+0x72>
    panic("create: ialloc");
    8000558c:	00003517          	auipc	a0,0x3
    80005590:	1d450513          	addi	a0,a0,468 # 80008760 <syscalls+0x2a8>
    80005594:	ffffb097          	auipc	ra,0xffffb
    80005598:	fb8080e7          	jalr	-72(ra) # 8000054c <panic>
    dp->nlink++;  // for ".."
    8000559c:	05295783          	lhu	a5,82(s2)
    800055a0:	2785                	addiw	a5,a5,1
    800055a2:	04f91923          	sh	a5,82(s2)
    iupdate(dp);
    800055a6:	854a                	mv	a0,s2
    800055a8:	ffffe097          	auipc	ra,0xffffe
    800055ac:	49c080e7          	jalr	1180(ra) # 80003a44 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    800055b0:	40d0                	lw	a2,4(s1)
    800055b2:	00003597          	auipc	a1,0x3
    800055b6:	1be58593          	addi	a1,a1,446 # 80008770 <syscalls+0x2b8>
    800055ba:	8526                	mv	a0,s1
    800055bc:	fffff097          	auipc	ra,0xfffff
    800055c0:	c4c080e7          	jalr	-948(ra) # 80004208 <dirlink>
    800055c4:	00054f63          	bltz	a0,800055e2 <create+0x142>
    800055c8:	00492603          	lw	a2,4(s2)
    800055cc:	00003597          	auipc	a1,0x3
    800055d0:	1ac58593          	addi	a1,a1,428 # 80008778 <syscalls+0x2c0>
    800055d4:	8526                	mv	a0,s1
    800055d6:	fffff097          	auipc	ra,0xfffff
    800055da:	c32080e7          	jalr	-974(ra) # 80004208 <dirlink>
    800055de:	f80557e3          	bgez	a0,8000556c <create+0xcc>
      panic("create dots");
    800055e2:	00003517          	auipc	a0,0x3
    800055e6:	19e50513          	addi	a0,a0,414 # 80008780 <syscalls+0x2c8>
    800055ea:	ffffb097          	auipc	ra,0xffffb
    800055ee:	f62080e7          	jalr	-158(ra) # 8000054c <panic>
    panic("create: dirlink");
    800055f2:	00003517          	auipc	a0,0x3
    800055f6:	19e50513          	addi	a0,a0,414 # 80008790 <syscalls+0x2d8>
    800055fa:	ffffb097          	auipc	ra,0xffffb
    800055fe:	f52080e7          	jalr	-174(ra) # 8000054c <panic>
    return 0;
    80005602:	84aa                	mv	s1,a0
    80005604:	b739                	j	80005512 <create+0x72>

0000000080005606 <sys_dup>:
{
    80005606:	7179                	addi	sp,sp,-48
    80005608:	f406                	sd	ra,40(sp)
    8000560a:	f022                	sd	s0,32(sp)
    8000560c:	ec26                	sd	s1,24(sp)
    8000560e:	e84a                	sd	s2,16(sp)
    80005610:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005612:	fd840613          	addi	a2,s0,-40
    80005616:	4581                	li	a1,0
    80005618:	4501                	li	a0,0
    8000561a:	00000097          	auipc	ra,0x0
    8000561e:	ddc080e7          	jalr	-548(ra) # 800053f6 <argfd>
    return -1;
    80005622:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005624:	02054363          	bltz	a0,8000564a <sys_dup+0x44>
  if((fd=fdalloc(f)) < 0)
    80005628:	fd843903          	ld	s2,-40(s0)
    8000562c:	854a                	mv	a0,s2
    8000562e:	00000097          	auipc	ra,0x0
    80005632:	e30080e7          	jalr	-464(ra) # 8000545e <fdalloc>
    80005636:	84aa                	mv	s1,a0
    return -1;
    80005638:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    8000563a:	00054863          	bltz	a0,8000564a <sys_dup+0x44>
  filedup(f);
    8000563e:	854a                	mv	a0,s2
    80005640:	fffff097          	auipc	ra,0xfffff
    80005644:	328080e7          	jalr	808(ra) # 80004968 <filedup>
  return fd;
    80005648:	87a6                	mv	a5,s1
}
    8000564a:	853e                	mv	a0,a5
    8000564c:	70a2                	ld	ra,40(sp)
    8000564e:	7402                	ld	s0,32(sp)
    80005650:	64e2                	ld	s1,24(sp)
    80005652:	6942                	ld	s2,16(sp)
    80005654:	6145                	addi	sp,sp,48
    80005656:	8082                	ret

0000000080005658 <sys_read>:
{
    80005658:	7179                	addi	sp,sp,-48
    8000565a:	f406                	sd	ra,40(sp)
    8000565c:	f022                	sd	s0,32(sp)
    8000565e:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005660:	fe840613          	addi	a2,s0,-24
    80005664:	4581                	li	a1,0
    80005666:	4501                	li	a0,0
    80005668:	00000097          	auipc	ra,0x0
    8000566c:	d8e080e7          	jalr	-626(ra) # 800053f6 <argfd>
    return -1;
    80005670:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005672:	04054163          	bltz	a0,800056b4 <sys_read+0x5c>
    80005676:	fe440593          	addi	a1,s0,-28
    8000567a:	4509                	li	a0,2
    8000567c:	ffffd097          	auipc	ra,0xffffd
    80005680:	776080e7          	jalr	1910(ra) # 80002df2 <argint>
    return -1;
    80005684:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005686:	02054763          	bltz	a0,800056b4 <sys_read+0x5c>
    8000568a:	fd840593          	addi	a1,s0,-40
    8000568e:	4505                	li	a0,1
    80005690:	ffffd097          	auipc	ra,0xffffd
    80005694:	784080e7          	jalr	1924(ra) # 80002e14 <argaddr>
    return -1;
    80005698:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000569a:	00054d63          	bltz	a0,800056b4 <sys_read+0x5c>
  return fileread(f, p, n);
    8000569e:	fe442603          	lw	a2,-28(s0)
    800056a2:	fd843583          	ld	a1,-40(s0)
    800056a6:	fe843503          	ld	a0,-24(s0)
    800056aa:	fffff097          	auipc	ra,0xfffff
    800056ae:	44a080e7          	jalr	1098(ra) # 80004af4 <fileread>
    800056b2:	87aa                	mv	a5,a0
}
    800056b4:	853e                	mv	a0,a5
    800056b6:	70a2                	ld	ra,40(sp)
    800056b8:	7402                	ld	s0,32(sp)
    800056ba:	6145                	addi	sp,sp,48
    800056bc:	8082                	ret

00000000800056be <sys_write>:
{
    800056be:	7179                	addi	sp,sp,-48
    800056c0:	f406                	sd	ra,40(sp)
    800056c2:	f022                	sd	s0,32(sp)
    800056c4:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800056c6:	fe840613          	addi	a2,s0,-24
    800056ca:	4581                	li	a1,0
    800056cc:	4501                	li	a0,0
    800056ce:	00000097          	auipc	ra,0x0
    800056d2:	d28080e7          	jalr	-728(ra) # 800053f6 <argfd>
    return -1;
    800056d6:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800056d8:	04054163          	bltz	a0,8000571a <sys_write+0x5c>
    800056dc:	fe440593          	addi	a1,s0,-28
    800056e0:	4509                	li	a0,2
    800056e2:	ffffd097          	auipc	ra,0xffffd
    800056e6:	710080e7          	jalr	1808(ra) # 80002df2 <argint>
    return -1;
    800056ea:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800056ec:	02054763          	bltz	a0,8000571a <sys_write+0x5c>
    800056f0:	fd840593          	addi	a1,s0,-40
    800056f4:	4505                	li	a0,1
    800056f6:	ffffd097          	auipc	ra,0xffffd
    800056fa:	71e080e7          	jalr	1822(ra) # 80002e14 <argaddr>
    return -1;
    800056fe:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005700:	00054d63          	bltz	a0,8000571a <sys_write+0x5c>
  return filewrite(f, p, n);
    80005704:	fe442603          	lw	a2,-28(s0)
    80005708:	fd843583          	ld	a1,-40(s0)
    8000570c:	fe843503          	ld	a0,-24(s0)
    80005710:	fffff097          	auipc	ra,0xfffff
    80005714:	4a6080e7          	jalr	1190(ra) # 80004bb6 <filewrite>
    80005718:	87aa                	mv	a5,a0
}
    8000571a:	853e                	mv	a0,a5
    8000571c:	70a2                	ld	ra,40(sp)
    8000571e:	7402                	ld	s0,32(sp)
    80005720:	6145                	addi	sp,sp,48
    80005722:	8082                	ret

0000000080005724 <sys_close>:
{
    80005724:	1101                	addi	sp,sp,-32
    80005726:	ec06                	sd	ra,24(sp)
    80005728:	e822                	sd	s0,16(sp)
    8000572a:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    8000572c:	fe040613          	addi	a2,s0,-32
    80005730:	fec40593          	addi	a1,s0,-20
    80005734:	4501                	li	a0,0
    80005736:	00000097          	auipc	ra,0x0
    8000573a:	cc0080e7          	jalr	-832(ra) # 800053f6 <argfd>
    return -1;
    8000573e:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005740:	02054463          	bltz	a0,80005768 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005744:	ffffc097          	auipc	ra,0xffffc
    80005748:	5ee080e7          	jalr	1518(ra) # 80001d32 <myproc>
    8000574c:	fec42783          	lw	a5,-20(s0)
    80005750:	07e9                	addi	a5,a5,26
    80005752:	078e                	slli	a5,a5,0x3
    80005754:	953e                	add	a0,a0,a5
    80005756:	00053423          	sd	zero,8(a0)
  fileclose(f);
    8000575a:	fe043503          	ld	a0,-32(s0)
    8000575e:	fffff097          	auipc	ra,0xfffff
    80005762:	25c080e7          	jalr	604(ra) # 800049ba <fileclose>
  return 0;
    80005766:	4781                	li	a5,0
}
    80005768:	853e                	mv	a0,a5
    8000576a:	60e2                	ld	ra,24(sp)
    8000576c:	6442                	ld	s0,16(sp)
    8000576e:	6105                	addi	sp,sp,32
    80005770:	8082                	ret

0000000080005772 <sys_fstat>:
{
    80005772:	1101                	addi	sp,sp,-32
    80005774:	ec06                	sd	ra,24(sp)
    80005776:	e822                	sd	s0,16(sp)
    80005778:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000577a:	fe840613          	addi	a2,s0,-24
    8000577e:	4581                	li	a1,0
    80005780:	4501                	li	a0,0
    80005782:	00000097          	auipc	ra,0x0
    80005786:	c74080e7          	jalr	-908(ra) # 800053f6 <argfd>
    return -1;
    8000578a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000578c:	02054563          	bltz	a0,800057b6 <sys_fstat+0x44>
    80005790:	fe040593          	addi	a1,s0,-32
    80005794:	4505                	li	a0,1
    80005796:	ffffd097          	auipc	ra,0xffffd
    8000579a:	67e080e7          	jalr	1662(ra) # 80002e14 <argaddr>
    return -1;
    8000579e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800057a0:	00054b63          	bltz	a0,800057b6 <sys_fstat+0x44>
  return filestat(f, st);
    800057a4:	fe043583          	ld	a1,-32(s0)
    800057a8:	fe843503          	ld	a0,-24(s0)
    800057ac:	fffff097          	auipc	ra,0xfffff
    800057b0:	2d6080e7          	jalr	726(ra) # 80004a82 <filestat>
    800057b4:	87aa                	mv	a5,a0
}
    800057b6:	853e                	mv	a0,a5
    800057b8:	60e2                	ld	ra,24(sp)
    800057ba:	6442                	ld	s0,16(sp)
    800057bc:	6105                	addi	sp,sp,32
    800057be:	8082                	ret

00000000800057c0 <sys_link>:
{
    800057c0:	7169                	addi	sp,sp,-304
    800057c2:	f606                	sd	ra,296(sp)
    800057c4:	f222                	sd	s0,288(sp)
    800057c6:	ee26                	sd	s1,280(sp)
    800057c8:	ea4a                	sd	s2,272(sp)
    800057ca:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800057cc:	08000613          	li	a2,128
    800057d0:	ed040593          	addi	a1,s0,-304
    800057d4:	4501                	li	a0,0
    800057d6:	ffffd097          	auipc	ra,0xffffd
    800057da:	660080e7          	jalr	1632(ra) # 80002e36 <argstr>
    return -1;
    800057de:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800057e0:	10054e63          	bltz	a0,800058fc <sys_link+0x13c>
    800057e4:	08000613          	li	a2,128
    800057e8:	f5040593          	addi	a1,s0,-176
    800057ec:	4505                	li	a0,1
    800057ee:	ffffd097          	auipc	ra,0xffffd
    800057f2:	648080e7          	jalr	1608(ra) # 80002e36 <argstr>
    return -1;
    800057f6:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800057f8:	10054263          	bltz	a0,800058fc <sys_link+0x13c>
  begin_op();
    800057fc:	fffff097          	auipc	ra,0xfffff
    80005800:	cee080e7          	jalr	-786(ra) # 800044ea <begin_op>
  if((ip = namei(old)) == 0){
    80005804:	ed040513          	addi	a0,s0,-304
    80005808:	fffff097          	auipc	ra,0xfffff
    8000580c:	ac2080e7          	jalr	-1342(ra) # 800042ca <namei>
    80005810:	84aa                	mv	s1,a0
    80005812:	c551                	beqz	a0,8000589e <sys_link+0xde>
  ilock(ip);
    80005814:	ffffe097          	auipc	ra,0xffffe
    80005818:	2fc080e7          	jalr	764(ra) # 80003b10 <ilock>
  if(ip->type == T_DIR){
    8000581c:	04c49703          	lh	a4,76(s1)
    80005820:	4785                	li	a5,1
    80005822:	08f70463          	beq	a4,a5,800058aa <sys_link+0xea>
  ip->nlink++;
    80005826:	0524d783          	lhu	a5,82(s1)
    8000582a:	2785                	addiw	a5,a5,1
    8000582c:	04f49923          	sh	a5,82(s1)
  iupdate(ip);
    80005830:	8526                	mv	a0,s1
    80005832:	ffffe097          	auipc	ra,0xffffe
    80005836:	212080e7          	jalr	530(ra) # 80003a44 <iupdate>
  iunlock(ip);
    8000583a:	8526                	mv	a0,s1
    8000583c:	ffffe097          	auipc	ra,0xffffe
    80005840:	396080e7          	jalr	918(ra) # 80003bd2 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005844:	fd040593          	addi	a1,s0,-48
    80005848:	f5040513          	addi	a0,s0,-176
    8000584c:	fffff097          	auipc	ra,0xfffff
    80005850:	a9c080e7          	jalr	-1380(ra) # 800042e8 <nameiparent>
    80005854:	892a                	mv	s2,a0
    80005856:	c935                	beqz	a0,800058ca <sys_link+0x10a>
  ilock(dp);
    80005858:	ffffe097          	auipc	ra,0xffffe
    8000585c:	2b8080e7          	jalr	696(ra) # 80003b10 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005860:	00092703          	lw	a4,0(s2)
    80005864:	409c                	lw	a5,0(s1)
    80005866:	04f71d63          	bne	a4,a5,800058c0 <sys_link+0x100>
    8000586a:	40d0                	lw	a2,4(s1)
    8000586c:	fd040593          	addi	a1,s0,-48
    80005870:	854a                	mv	a0,s2
    80005872:	fffff097          	auipc	ra,0xfffff
    80005876:	996080e7          	jalr	-1642(ra) # 80004208 <dirlink>
    8000587a:	04054363          	bltz	a0,800058c0 <sys_link+0x100>
  iunlockput(dp);
    8000587e:	854a                	mv	a0,s2
    80005880:	ffffe097          	auipc	ra,0xffffe
    80005884:	4f2080e7          	jalr	1266(ra) # 80003d72 <iunlockput>
  iput(ip);
    80005888:	8526                	mv	a0,s1
    8000588a:	ffffe097          	auipc	ra,0xffffe
    8000588e:	440080e7          	jalr	1088(ra) # 80003cca <iput>
  end_op();
    80005892:	fffff097          	auipc	ra,0xfffff
    80005896:	cd6080e7          	jalr	-810(ra) # 80004568 <end_op>
  return 0;
    8000589a:	4781                	li	a5,0
    8000589c:	a085                	j	800058fc <sys_link+0x13c>
    end_op();
    8000589e:	fffff097          	auipc	ra,0xfffff
    800058a2:	cca080e7          	jalr	-822(ra) # 80004568 <end_op>
    return -1;
    800058a6:	57fd                	li	a5,-1
    800058a8:	a891                	j	800058fc <sys_link+0x13c>
    iunlockput(ip);
    800058aa:	8526                	mv	a0,s1
    800058ac:	ffffe097          	auipc	ra,0xffffe
    800058b0:	4c6080e7          	jalr	1222(ra) # 80003d72 <iunlockput>
    end_op();
    800058b4:	fffff097          	auipc	ra,0xfffff
    800058b8:	cb4080e7          	jalr	-844(ra) # 80004568 <end_op>
    return -1;
    800058bc:	57fd                	li	a5,-1
    800058be:	a83d                	j	800058fc <sys_link+0x13c>
    iunlockput(dp);
    800058c0:	854a                	mv	a0,s2
    800058c2:	ffffe097          	auipc	ra,0xffffe
    800058c6:	4b0080e7          	jalr	1200(ra) # 80003d72 <iunlockput>
  ilock(ip);
    800058ca:	8526                	mv	a0,s1
    800058cc:	ffffe097          	auipc	ra,0xffffe
    800058d0:	244080e7          	jalr	580(ra) # 80003b10 <ilock>
  ip->nlink--;
    800058d4:	0524d783          	lhu	a5,82(s1)
    800058d8:	37fd                	addiw	a5,a5,-1
    800058da:	04f49923          	sh	a5,82(s1)
  iupdate(ip);
    800058de:	8526                	mv	a0,s1
    800058e0:	ffffe097          	auipc	ra,0xffffe
    800058e4:	164080e7          	jalr	356(ra) # 80003a44 <iupdate>
  iunlockput(ip);
    800058e8:	8526                	mv	a0,s1
    800058ea:	ffffe097          	auipc	ra,0xffffe
    800058ee:	488080e7          	jalr	1160(ra) # 80003d72 <iunlockput>
  end_op();
    800058f2:	fffff097          	auipc	ra,0xfffff
    800058f6:	c76080e7          	jalr	-906(ra) # 80004568 <end_op>
  return -1;
    800058fa:	57fd                	li	a5,-1
}
    800058fc:	853e                	mv	a0,a5
    800058fe:	70b2                	ld	ra,296(sp)
    80005900:	7412                	ld	s0,288(sp)
    80005902:	64f2                	ld	s1,280(sp)
    80005904:	6952                	ld	s2,272(sp)
    80005906:	6155                	addi	sp,sp,304
    80005908:	8082                	ret

000000008000590a <sys_unlink>:
{
    8000590a:	7151                	addi	sp,sp,-240
    8000590c:	f586                	sd	ra,232(sp)
    8000590e:	f1a2                	sd	s0,224(sp)
    80005910:	eda6                	sd	s1,216(sp)
    80005912:	e9ca                	sd	s2,208(sp)
    80005914:	e5ce                	sd	s3,200(sp)
    80005916:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005918:	08000613          	li	a2,128
    8000591c:	f3040593          	addi	a1,s0,-208
    80005920:	4501                	li	a0,0
    80005922:	ffffd097          	auipc	ra,0xffffd
    80005926:	514080e7          	jalr	1300(ra) # 80002e36 <argstr>
    8000592a:	18054163          	bltz	a0,80005aac <sys_unlink+0x1a2>
  begin_op();
    8000592e:	fffff097          	auipc	ra,0xfffff
    80005932:	bbc080e7          	jalr	-1092(ra) # 800044ea <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005936:	fb040593          	addi	a1,s0,-80
    8000593a:	f3040513          	addi	a0,s0,-208
    8000593e:	fffff097          	auipc	ra,0xfffff
    80005942:	9aa080e7          	jalr	-1622(ra) # 800042e8 <nameiparent>
    80005946:	84aa                	mv	s1,a0
    80005948:	c979                	beqz	a0,80005a1e <sys_unlink+0x114>
  ilock(dp);
    8000594a:	ffffe097          	auipc	ra,0xffffe
    8000594e:	1c6080e7          	jalr	454(ra) # 80003b10 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005952:	00003597          	auipc	a1,0x3
    80005956:	e1e58593          	addi	a1,a1,-482 # 80008770 <syscalls+0x2b8>
    8000595a:	fb040513          	addi	a0,s0,-80
    8000595e:	ffffe097          	auipc	ra,0xffffe
    80005962:	67a080e7          	jalr	1658(ra) # 80003fd8 <namecmp>
    80005966:	14050a63          	beqz	a0,80005aba <sys_unlink+0x1b0>
    8000596a:	00003597          	auipc	a1,0x3
    8000596e:	e0e58593          	addi	a1,a1,-498 # 80008778 <syscalls+0x2c0>
    80005972:	fb040513          	addi	a0,s0,-80
    80005976:	ffffe097          	auipc	ra,0xffffe
    8000597a:	662080e7          	jalr	1634(ra) # 80003fd8 <namecmp>
    8000597e:	12050e63          	beqz	a0,80005aba <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005982:	f2c40613          	addi	a2,s0,-212
    80005986:	fb040593          	addi	a1,s0,-80
    8000598a:	8526                	mv	a0,s1
    8000598c:	ffffe097          	auipc	ra,0xffffe
    80005990:	666080e7          	jalr	1638(ra) # 80003ff2 <dirlookup>
    80005994:	892a                	mv	s2,a0
    80005996:	12050263          	beqz	a0,80005aba <sys_unlink+0x1b0>
  ilock(ip);
    8000599a:	ffffe097          	auipc	ra,0xffffe
    8000599e:	176080e7          	jalr	374(ra) # 80003b10 <ilock>
  if(ip->nlink < 1)
    800059a2:	05291783          	lh	a5,82(s2)
    800059a6:	08f05263          	blez	a5,80005a2a <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    800059aa:	04c91703          	lh	a4,76(s2)
    800059ae:	4785                	li	a5,1
    800059b0:	08f70563          	beq	a4,a5,80005a3a <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    800059b4:	4641                	li	a2,16
    800059b6:	4581                	li	a1,0
    800059b8:	fc040513          	addi	a0,s0,-64
    800059bc:	ffffb097          	auipc	ra,0xffffb
    800059c0:	710080e7          	jalr	1808(ra) # 800010cc <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800059c4:	4741                	li	a4,16
    800059c6:	f2c42683          	lw	a3,-212(s0)
    800059ca:	fc040613          	addi	a2,s0,-64
    800059ce:	4581                	li	a1,0
    800059d0:	8526                	mv	a0,s1
    800059d2:	ffffe097          	auipc	ra,0xffffe
    800059d6:	4ea080e7          	jalr	1258(ra) # 80003ebc <writei>
    800059da:	47c1                	li	a5,16
    800059dc:	0af51563          	bne	a0,a5,80005a86 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    800059e0:	04c91703          	lh	a4,76(s2)
    800059e4:	4785                	li	a5,1
    800059e6:	0af70863          	beq	a4,a5,80005a96 <sys_unlink+0x18c>
  iunlockput(dp);
    800059ea:	8526                	mv	a0,s1
    800059ec:	ffffe097          	auipc	ra,0xffffe
    800059f0:	386080e7          	jalr	902(ra) # 80003d72 <iunlockput>
  ip->nlink--;
    800059f4:	05295783          	lhu	a5,82(s2)
    800059f8:	37fd                	addiw	a5,a5,-1
    800059fa:	04f91923          	sh	a5,82(s2)
  iupdate(ip);
    800059fe:	854a                	mv	a0,s2
    80005a00:	ffffe097          	auipc	ra,0xffffe
    80005a04:	044080e7          	jalr	68(ra) # 80003a44 <iupdate>
  iunlockput(ip);
    80005a08:	854a                	mv	a0,s2
    80005a0a:	ffffe097          	auipc	ra,0xffffe
    80005a0e:	368080e7          	jalr	872(ra) # 80003d72 <iunlockput>
  end_op();
    80005a12:	fffff097          	auipc	ra,0xfffff
    80005a16:	b56080e7          	jalr	-1194(ra) # 80004568 <end_op>
  return 0;
    80005a1a:	4501                	li	a0,0
    80005a1c:	a84d                	j	80005ace <sys_unlink+0x1c4>
    end_op();
    80005a1e:	fffff097          	auipc	ra,0xfffff
    80005a22:	b4a080e7          	jalr	-1206(ra) # 80004568 <end_op>
    return -1;
    80005a26:	557d                	li	a0,-1
    80005a28:	a05d                	j	80005ace <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005a2a:	00003517          	auipc	a0,0x3
    80005a2e:	d7650513          	addi	a0,a0,-650 # 800087a0 <syscalls+0x2e8>
    80005a32:	ffffb097          	auipc	ra,0xffffb
    80005a36:	b1a080e7          	jalr	-1254(ra) # 8000054c <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005a3a:	05492703          	lw	a4,84(s2)
    80005a3e:	02000793          	li	a5,32
    80005a42:	f6e7f9e3          	bgeu	a5,a4,800059b4 <sys_unlink+0xaa>
    80005a46:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005a4a:	4741                	li	a4,16
    80005a4c:	86ce                	mv	a3,s3
    80005a4e:	f1840613          	addi	a2,s0,-232
    80005a52:	4581                	li	a1,0
    80005a54:	854a                	mv	a0,s2
    80005a56:	ffffe097          	auipc	ra,0xffffe
    80005a5a:	36e080e7          	jalr	878(ra) # 80003dc4 <readi>
    80005a5e:	47c1                	li	a5,16
    80005a60:	00f51b63          	bne	a0,a5,80005a76 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005a64:	f1845783          	lhu	a5,-232(s0)
    80005a68:	e7a1                	bnez	a5,80005ab0 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005a6a:	29c1                	addiw	s3,s3,16
    80005a6c:	05492783          	lw	a5,84(s2)
    80005a70:	fcf9ede3          	bltu	s3,a5,80005a4a <sys_unlink+0x140>
    80005a74:	b781                	j	800059b4 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005a76:	00003517          	auipc	a0,0x3
    80005a7a:	d4250513          	addi	a0,a0,-702 # 800087b8 <syscalls+0x300>
    80005a7e:	ffffb097          	auipc	ra,0xffffb
    80005a82:	ace080e7          	jalr	-1330(ra) # 8000054c <panic>
    panic("unlink: writei");
    80005a86:	00003517          	auipc	a0,0x3
    80005a8a:	d4a50513          	addi	a0,a0,-694 # 800087d0 <syscalls+0x318>
    80005a8e:	ffffb097          	auipc	ra,0xffffb
    80005a92:	abe080e7          	jalr	-1346(ra) # 8000054c <panic>
    dp->nlink--;
    80005a96:	0524d783          	lhu	a5,82(s1)
    80005a9a:	37fd                	addiw	a5,a5,-1
    80005a9c:	04f49923          	sh	a5,82(s1)
    iupdate(dp);
    80005aa0:	8526                	mv	a0,s1
    80005aa2:	ffffe097          	auipc	ra,0xffffe
    80005aa6:	fa2080e7          	jalr	-94(ra) # 80003a44 <iupdate>
    80005aaa:	b781                	j	800059ea <sys_unlink+0xe0>
    return -1;
    80005aac:	557d                	li	a0,-1
    80005aae:	a005                	j	80005ace <sys_unlink+0x1c4>
    iunlockput(ip);
    80005ab0:	854a                	mv	a0,s2
    80005ab2:	ffffe097          	auipc	ra,0xffffe
    80005ab6:	2c0080e7          	jalr	704(ra) # 80003d72 <iunlockput>
  iunlockput(dp);
    80005aba:	8526                	mv	a0,s1
    80005abc:	ffffe097          	auipc	ra,0xffffe
    80005ac0:	2b6080e7          	jalr	694(ra) # 80003d72 <iunlockput>
  end_op();
    80005ac4:	fffff097          	auipc	ra,0xfffff
    80005ac8:	aa4080e7          	jalr	-1372(ra) # 80004568 <end_op>
  return -1;
    80005acc:	557d                	li	a0,-1
}
    80005ace:	70ae                	ld	ra,232(sp)
    80005ad0:	740e                	ld	s0,224(sp)
    80005ad2:	64ee                	ld	s1,216(sp)
    80005ad4:	694e                	ld	s2,208(sp)
    80005ad6:	69ae                	ld	s3,200(sp)
    80005ad8:	616d                	addi	sp,sp,240
    80005ada:	8082                	ret

0000000080005adc <sys_open>:

uint64
sys_open(void)
{
    80005adc:	7131                	addi	sp,sp,-192
    80005ade:	fd06                	sd	ra,184(sp)
    80005ae0:	f922                	sd	s0,176(sp)
    80005ae2:	f526                	sd	s1,168(sp)
    80005ae4:	f14a                	sd	s2,160(sp)
    80005ae6:	ed4e                	sd	s3,152(sp)
    80005ae8:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005aea:	08000613          	li	a2,128
    80005aee:	f5040593          	addi	a1,s0,-176
    80005af2:	4501                	li	a0,0
    80005af4:	ffffd097          	auipc	ra,0xffffd
    80005af8:	342080e7          	jalr	834(ra) # 80002e36 <argstr>
    return -1;
    80005afc:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005afe:	0c054163          	bltz	a0,80005bc0 <sys_open+0xe4>
    80005b02:	f4c40593          	addi	a1,s0,-180
    80005b06:	4505                	li	a0,1
    80005b08:	ffffd097          	auipc	ra,0xffffd
    80005b0c:	2ea080e7          	jalr	746(ra) # 80002df2 <argint>
    80005b10:	0a054863          	bltz	a0,80005bc0 <sys_open+0xe4>

  begin_op();
    80005b14:	fffff097          	auipc	ra,0xfffff
    80005b18:	9d6080e7          	jalr	-1578(ra) # 800044ea <begin_op>

  if(omode & O_CREATE){
    80005b1c:	f4c42783          	lw	a5,-180(s0)
    80005b20:	2007f793          	andi	a5,a5,512
    80005b24:	cbdd                	beqz	a5,80005bda <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005b26:	4681                	li	a3,0
    80005b28:	4601                	li	a2,0
    80005b2a:	4589                	li	a1,2
    80005b2c:	f5040513          	addi	a0,s0,-176
    80005b30:	00000097          	auipc	ra,0x0
    80005b34:	970080e7          	jalr	-1680(ra) # 800054a0 <create>
    80005b38:	892a                	mv	s2,a0
    if(ip == 0){
    80005b3a:	c959                	beqz	a0,80005bd0 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005b3c:	04c91703          	lh	a4,76(s2)
    80005b40:	478d                	li	a5,3
    80005b42:	00f71763          	bne	a4,a5,80005b50 <sys_open+0x74>
    80005b46:	04e95703          	lhu	a4,78(s2)
    80005b4a:	47a5                	li	a5,9
    80005b4c:	0ce7ec63          	bltu	a5,a4,80005c24 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005b50:	fffff097          	auipc	ra,0xfffff
    80005b54:	dae080e7          	jalr	-594(ra) # 800048fe <filealloc>
    80005b58:	89aa                	mv	s3,a0
    80005b5a:	10050263          	beqz	a0,80005c5e <sys_open+0x182>
    80005b5e:	00000097          	auipc	ra,0x0
    80005b62:	900080e7          	jalr	-1792(ra) # 8000545e <fdalloc>
    80005b66:	84aa                	mv	s1,a0
    80005b68:	0e054663          	bltz	a0,80005c54 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005b6c:	04c91703          	lh	a4,76(s2)
    80005b70:	478d                	li	a5,3
    80005b72:	0cf70463          	beq	a4,a5,80005c3a <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005b76:	4789                	li	a5,2
    80005b78:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005b7c:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005b80:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005b84:	f4c42783          	lw	a5,-180(s0)
    80005b88:	0017c713          	xori	a4,a5,1
    80005b8c:	8b05                	andi	a4,a4,1
    80005b8e:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005b92:	0037f713          	andi	a4,a5,3
    80005b96:	00e03733          	snez	a4,a4
    80005b9a:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005b9e:	4007f793          	andi	a5,a5,1024
    80005ba2:	c791                	beqz	a5,80005bae <sys_open+0xd2>
    80005ba4:	04c91703          	lh	a4,76(s2)
    80005ba8:	4789                	li	a5,2
    80005baa:	08f70f63          	beq	a4,a5,80005c48 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005bae:	854a                	mv	a0,s2
    80005bb0:	ffffe097          	auipc	ra,0xffffe
    80005bb4:	022080e7          	jalr	34(ra) # 80003bd2 <iunlock>
  end_op();
    80005bb8:	fffff097          	auipc	ra,0xfffff
    80005bbc:	9b0080e7          	jalr	-1616(ra) # 80004568 <end_op>

  return fd;
}
    80005bc0:	8526                	mv	a0,s1
    80005bc2:	70ea                	ld	ra,184(sp)
    80005bc4:	744a                	ld	s0,176(sp)
    80005bc6:	74aa                	ld	s1,168(sp)
    80005bc8:	790a                	ld	s2,160(sp)
    80005bca:	69ea                	ld	s3,152(sp)
    80005bcc:	6129                	addi	sp,sp,192
    80005bce:	8082                	ret
      end_op();
    80005bd0:	fffff097          	auipc	ra,0xfffff
    80005bd4:	998080e7          	jalr	-1640(ra) # 80004568 <end_op>
      return -1;
    80005bd8:	b7e5                	j	80005bc0 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005bda:	f5040513          	addi	a0,s0,-176
    80005bde:	ffffe097          	auipc	ra,0xffffe
    80005be2:	6ec080e7          	jalr	1772(ra) # 800042ca <namei>
    80005be6:	892a                	mv	s2,a0
    80005be8:	c905                	beqz	a0,80005c18 <sys_open+0x13c>
    ilock(ip);
    80005bea:	ffffe097          	auipc	ra,0xffffe
    80005bee:	f26080e7          	jalr	-218(ra) # 80003b10 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005bf2:	04c91703          	lh	a4,76(s2)
    80005bf6:	4785                	li	a5,1
    80005bf8:	f4f712e3          	bne	a4,a5,80005b3c <sys_open+0x60>
    80005bfc:	f4c42783          	lw	a5,-180(s0)
    80005c00:	dba1                	beqz	a5,80005b50 <sys_open+0x74>
      iunlockput(ip);
    80005c02:	854a                	mv	a0,s2
    80005c04:	ffffe097          	auipc	ra,0xffffe
    80005c08:	16e080e7          	jalr	366(ra) # 80003d72 <iunlockput>
      end_op();
    80005c0c:	fffff097          	auipc	ra,0xfffff
    80005c10:	95c080e7          	jalr	-1700(ra) # 80004568 <end_op>
      return -1;
    80005c14:	54fd                	li	s1,-1
    80005c16:	b76d                	j	80005bc0 <sys_open+0xe4>
      end_op();
    80005c18:	fffff097          	auipc	ra,0xfffff
    80005c1c:	950080e7          	jalr	-1712(ra) # 80004568 <end_op>
      return -1;
    80005c20:	54fd                	li	s1,-1
    80005c22:	bf79                	j	80005bc0 <sys_open+0xe4>
    iunlockput(ip);
    80005c24:	854a                	mv	a0,s2
    80005c26:	ffffe097          	auipc	ra,0xffffe
    80005c2a:	14c080e7          	jalr	332(ra) # 80003d72 <iunlockput>
    end_op();
    80005c2e:	fffff097          	auipc	ra,0xfffff
    80005c32:	93a080e7          	jalr	-1734(ra) # 80004568 <end_op>
    return -1;
    80005c36:	54fd                	li	s1,-1
    80005c38:	b761                	j	80005bc0 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005c3a:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005c3e:	04e91783          	lh	a5,78(s2)
    80005c42:	02f99223          	sh	a5,36(s3)
    80005c46:	bf2d                	j	80005b80 <sys_open+0xa4>
    itrunc(ip);
    80005c48:	854a                	mv	a0,s2
    80005c4a:	ffffe097          	auipc	ra,0xffffe
    80005c4e:	fd4080e7          	jalr	-44(ra) # 80003c1e <itrunc>
    80005c52:	bfb1                	j	80005bae <sys_open+0xd2>
      fileclose(f);
    80005c54:	854e                	mv	a0,s3
    80005c56:	fffff097          	auipc	ra,0xfffff
    80005c5a:	d64080e7          	jalr	-668(ra) # 800049ba <fileclose>
    iunlockput(ip);
    80005c5e:	854a                	mv	a0,s2
    80005c60:	ffffe097          	auipc	ra,0xffffe
    80005c64:	112080e7          	jalr	274(ra) # 80003d72 <iunlockput>
    end_op();
    80005c68:	fffff097          	auipc	ra,0xfffff
    80005c6c:	900080e7          	jalr	-1792(ra) # 80004568 <end_op>
    return -1;
    80005c70:	54fd                	li	s1,-1
    80005c72:	b7b9                	j	80005bc0 <sys_open+0xe4>

0000000080005c74 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005c74:	7175                	addi	sp,sp,-144
    80005c76:	e506                	sd	ra,136(sp)
    80005c78:	e122                	sd	s0,128(sp)
    80005c7a:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005c7c:	fffff097          	auipc	ra,0xfffff
    80005c80:	86e080e7          	jalr	-1938(ra) # 800044ea <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005c84:	08000613          	li	a2,128
    80005c88:	f7040593          	addi	a1,s0,-144
    80005c8c:	4501                	li	a0,0
    80005c8e:	ffffd097          	auipc	ra,0xffffd
    80005c92:	1a8080e7          	jalr	424(ra) # 80002e36 <argstr>
    80005c96:	02054963          	bltz	a0,80005cc8 <sys_mkdir+0x54>
    80005c9a:	4681                	li	a3,0
    80005c9c:	4601                	li	a2,0
    80005c9e:	4585                	li	a1,1
    80005ca0:	f7040513          	addi	a0,s0,-144
    80005ca4:	fffff097          	auipc	ra,0xfffff
    80005ca8:	7fc080e7          	jalr	2044(ra) # 800054a0 <create>
    80005cac:	cd11                	beqz	a0,80005cc8 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005cae:	ffffe097          	auipc	ra,0xffffe
    80005cb2:	0c4080e7          	jalr	196(ra) # 80003d72 <iunlockput>
  end_op();
    80005cb6:	fffff097          	auipc	ra,0xfffff
    80005cba:	8b2080e7          	jalr	-1870(ra) # 80004568 <end_op>
  return 0;
    80005cbe:	4501                	li	a0,0
}
    80005cc0:	60aa                	ld	ra,136(sp)
    80005cc2:	640a                	ld	s0,128(sp)
    80005cc4:	6149                	addi	sp,sp,144
    80005cc6:	8082                	ret
    end_op();
    80005cc8:	fffff097          	auipc	ra,0xfffff
    80005ccc:	8a0080e7          	jalr	-1888(ra) # 80004568 <end_op>
    return -1;
    80005cd0:	557d                	li	a0,-1
    80005cd2:	b7fd                	j	80005cc0 <sys_mkdir+0x4c>

0000000080005cd4 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005cd4:	7135                	addi	sp,sp,-160
    80005cd6:	ed06                	sd	ra,152(sp)
    80005cd8:	e922                	sd	s0,144(sp)
    80005cda:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005cdc:	fffff097          	auipc	ra,0xfffff
    80005ce0:	80e080e7          	jalr	-2034(ra) # 800044ea <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005ce4:	08000613          	li	a2,128
    80005ce8:	f7040593          	addi	a1,s0,-144
    80005cec:	4501                	li	a0,0
    80005cee:	ffffd097          	auipc	ra,0xffffd
    80005cf2:	148080e7          	jalr	328(ra) # 80002e36 <argstr>
    80005cf6:	04054a63          	bltz	a0,80005d4a <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005cfa:	f6c40593          	addi	a1,s0,-148
    80005cfe:	4505                	li	a0,1
    80005d00:	ffffd097          	auipc	ra,0xffffd
    80005d04:	0f2080e7          	jalr	242(ra) # 80002df2 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005d08:	04054163          	bltz	a0,80005d4a <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005d0c:	f6840593          	addi	a1,s0,-152
    80005d10:	4509                	li	a0,2
    80005d12:	ffffd097          	auipc	ra,0xffffd
    80005d16:	0e0080e7          	jalr	224(ra) # 80002df2 <argint>
     argint(1, &major) < 0 ||
    80005d1a:	02054863          	bltz	a0,80005d4a <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005d1e:	f6841683          	lh	a3,-152(s0)
    80005d22:	f6c41603          	lh	a2,-148(s0)
    80005d26:	458d                	li	a1,3
    80005d28:	f7040513          	addi	a0,s0,-144
    80005d2c:	fffff097          	auipc	ra,0xfffff
    80005d30:	774080e7          	jalr	1908(ra) # 800054a0 <create>
     argint(2, &minor) < 0 ||
    80005d34:	c919                	beqz	a0,80005d4a <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005d36:	ffffe097          	auipc	ra,0xffffe
    80005d3a:	03c080e7          	jalr	60(ra) # 80003d72 <iunlockput>
  end_op();
    80005d3e:	fffff097          	auipc	ra,0xfffff
    80005d42:	82a080e7          	jalr	-2006(ra) # 80004568 <end_op>
  return 0;
    80005d46:	4501                	li	a0,0
    80005d48:	a031                	j	80005d54 <sys_mknod+0x80>
    end_op();
    80005d4a:	fffff097          	auipc	ra,0xfffff
    80005d4e:	81e080e7          	jalr	-2018(ra) # 80004568 <end_op>
    return -1;
    80005d52:	557d                	li	a0,-1
}
    80005d54:	60ea                	ld	ra,152(sp)
    80005d56:	644a                	ld	s0,144(sp)
    80005d58:	610d                	addi	sp,sp,160
    80005d5a:	8082                	ret

0000000080005d5c <sys_chdir>:

uint64
sys_chdir(void)
{
    80005d5c:	7135                	addi	sp,sp,-160
    80005d5e:	ed06                	sd	ra,152(sp)
    80005d60:	e922                	sd	s0,144(sp)
    80005d62:	e526                	sd	s1,136(sp)
    80005d64:	e14a                	sd	s2,128(sp)
    80005d66:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005d68:	ffffc097          	auipc	ra,0xffffc
    80005d6c:	fca080e7          	jalr	-54(ra) # 80001d32 <myproc>
    80005d70:	892a                	mv	s2,a0
  
  begin_op();
    80005d72:	ffffe097          	auipc	ra,0xffffe
    80005d76:	778080e7          	jalr	1912(ra) # 800044ea <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005d7a:	08000613          	li	a2,128
    80005d7e:	f6040593          	addi	a1,s0,-160
    80005d82:	4501                	li	a0,0
    80005d84:	ffffd097          	auipc	ra,0xffffd
    80005d88:	0b2080e7          	jalr	178(ra) # 80002e36 <argstr>
    80005d8c:	04054b63          	bltz	a0,80005de2 <sys_chdir+0x86>
    80005d90:	f6040513          	addi	a0,s0,-160
    80005d94:	ffffe097          	auipc	ra,0xffffe
    80005d98:	536080e7          	jalr	1334(ra) # 800042ca <namei>
    80005d9c:	84aa                	mv	s1,a0
    80005d9e:	c131                	beqz	a0,80005de2 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005da0:	ffffe097          	auipc	ra,0xffffe
    80005da4:	d70080e7          	jalr	-656(ra) # 80003b10 <ilock>
  if(ip->type != T_DIR){
    80005da8:	04c49703          	lh	a4,76(s1)
    80005dac:	4785                	li	a5,1
    80005dae:	04f71063          	bne	a4,a5,80005dee <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005db2:	8526                	mv	a0,s1
    80005db4:	ffffe097          	auipc	ra,0xffffe
    80005db8:	e1e080e7          	jalr	-482(ra) # 80003bd2 <iunlock>
  iput(p->cwd);
    80005dbc:	15893503          	ld	a0,344(s2)
    80005dc0:	ffffe097          	auipc	ra,0xffffe
    80005dc4:	f0a080e7          	jalr	-246(ra) # 80003cca <iput>
  end_op();
    80005dc8:	ffffe097          	auipc	ra,0xffffe
    80005dcc:	7a0080e7          	jalr	1952(ra) # 80004568 <end_op>
  p->cwd = ip;
    80005dd0:	14993c23          	sd	s1,344(s2)
  return 0;
    80005dd4:	4501                	li	a0,0
}
    80005dd6:	60ea                	ld	ra,152(sp)
    80005dd8:	644a                	ld	s0,144(sp)
    80005dda:	64aa                	ld	s1,136(sp)
    80005ddc:	690a                	ld	s2,128(sp)
    80005dde:	610d                	addi	sp,sp,160
    80005de0:	8082                	ret
    end_op();
    80005de2:	ffffe097          	auipc	ra,0xffffe
    80005de6:	786080e7          	jalr	1926(ra) # 80004568 <end_op>
    return -1;
    80005dea:	557d                	li	a0,-1
    80005dec:	b7ed                	j	80005dd6 <sys_chdir+0x7a>
    iunlockput(ip);
    80005dee:	8526                	mv	a0,s1
    80005df0:	ffffe097          	auipc	ra,0xffffe
    80005df4:	f82080e7          	jalr	-126(ra) # 80003d72 <iunlockput>
    end_op();
    80005df8:	ffffe097          	auipc	ra,0xffffe
    80005dfc:	770080e7          	jalr	1904(ra) # 80004568 <end_op>
    return -1;
    80005e00:	557d                	li	a0,-1
    80005e02:	bfd1                	j	80005dd6 <sys_chdir+0x7a>

0000000080005e04 <sys_exec>:

uint64
sys_exec(void)
{
    80005e04:	7145                	addi	sp,sp,-464
    80005e06:	e786                	sd	ra,456(sp)
    80005e08:	e3a2                	sd	s0,448(sp)
    80005e0a:	ff26                	sd	s1,440(sp)
    80005e0c:	fb4a                	sd	s2,432(sp)
    80005e0e:	f74e                	sd	s3,424(sp)
    80005e10:	f352                	sd	s4,416(sp)
    80005e12:	ef56                	sd	s5,408(sp)
    80005e14:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005e16:	08000613          	li	a2,128
    80005e1a:	f4040593          	addi	a1,s0,-192
    80005e1e:	4501                	li	a0,0
    80005e20:	ffffd097          	auipc	ra,0xffffd
    80005e24:	016080e7          	jalr	22(ra) # 80002e36 <argstr>
    return -1;
    80005e28:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005e2a:	0c054b63          	bltz	a0,80005f00 <sys_exec+0xfc>
    80005e2e:	e3840593          	addi	a1,s0,-456
    80005e32:	4505                	li	a0,1
    80005e34:	ffffd097          	auipc	ra,0xffffd
    80005e38:	fe0080e7          	jalr	-32(ra) # 80002e14 <argaddr>
    80005e3c:	0c054263          	bltz	a0,80005f00 <sys_exec+0xfc>
  }
  memset(argv, 0, sizeof(argv));
    80005e40:	10000613          	li	a2,256
    80005e44:	4581                	li	a1,0
    80005e46:	e4040513          	addi	a0,s0,-448
    80005e4a:	ffffb097          	auipc	ra,0xffffb
    80005e4e:	282080e7          	jalr	642(ra) # 800010cc <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005e52:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005e56:	89a6                	mv	s3,s1
    80005e58:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005e5a:	02000a13          	li	s4,32
    80005e5e:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005e62:	00391513          	slli	a0,s2,0x3
    80005e66:	e3040593          	addi	a1,s0,-464
    80005e6a:	e3843783          	ld	a5,-456(s0)
    80005e6e:	953e                	add	a0,a0,a5
    80005e70:	ffffd097          	auipc	ra,0xffffd
    80005e74:	ee8080e7          	jalr	-280(ra) # 80002d58 <fetchaddr>
    80005e78:	02054a63          	bltz	a0,80005eac <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005e7c:	e3043783          	ld	a5,-464(s0)
    80005e80:	c3b9                	beqz	a5,80005ec6 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005e82:	ffffb097          	auipc	ra,0xffffb
    80005e86:	ce6080e7          	jalr	-794(ra) # 80000b68 <kalloc>
    80005e8a:	85aa                	mv	a1,a0
    80005e8c:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005e90:	cd11                	beqz	a0,80005eac <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005e92:	6605                	lui	a2,0x1
    80005e94:	e3043503          	ld	a0,-464(s0)
    80005e98:	ffffd097          	auipc	ra,0xffffd
    80005e9c:	f12080e7          	jalr	-238(ra) # 80002daa <fetchstr>
    80005ea0:	00054663          	bltz	a0,80005eac <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005ea4:	0905                	addi	s2,s2,1
    80005ea6:	09a1                	addi	s3,s3,8
    80005ea8:	fb491be3          	bne	s2,s4,80005e5e <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005eac:	f4040913          	addi	s2,s0,-192
    80005eb0:	6088                	ld	a0,0(s1)
    80005eb2:	c531                	beqz	a0,80005efe <sys_exec+0xfa>
    kfree(argv[i]);
    80005eb4:	ffffb097          	auipc	ra,0xffffb
    80005eb8:	b64080e7          	jalr	-1180(ra) # 80000a18 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005ebc:	04a1                	addi	s1,s1,8
    80005ebe:	ff2499e3          	bne	s1,s2,80005eb0 <sys_exec+0xac>
  return -1;
    80005ec2:	597d                	li	s2,-1
    80005ec4:	a835                	j	80005f00 <sys_exec+0xfc>
      argv[i] = 0;
    80005ec6:	0a8e                	slli	s5,s5,0x3
    80005ec8:	fc0a8793          	addi	a5,s5,-64 # ffffffffffffefc0 <end+0xffffffff7ffd1f98>
    80005ecc:	00878ab3          	add	s5,a5,s0
    80005ed0:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005ed4:	e4040593          	addi	a1,s0,-448
    80005ed8:	f4040513          	addi	a0,s0,-192
    80005edc:	fffff097          	auipc	ra,0xfffff
    80005ee0:	172080e7          	jalr	370(ra) # 8000504e <exec>
    80005ee4:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005ee6:	f4040993          	addi	s3,s0,-192
    80005eea:	6088                	ld	a0,0(s1)
    80005eec:	c911                	beqz	a0,80005f00 <sys_exec+0xfc>
    kfree(argv[i]);
    80005eee:	ffffb097          	auipc	ra,0xffffb
    80005ef2:	b2a080e7          	jalr	-1238(ra) # 80000a18 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005ef6:	04a1                	addi	s1,s1,8
    80005ef8:	ff3499e3          	bne	s1,s3,80005eea <sys_exec+0xe6>
    80005efc:	a011                	j	80005f00 <sys_exec+0xfc>
  return -1;
    80005efe:	597d                	li	s2,-1
}
    80005f00:	854a                	mv	a0,s2
    80005f02:	60be                	ld	ra,456(sp)
    80005f04:	641e                	ld	s0,448(sp)
    80005f06:	74fa                	ld	s1,440(sp)
    80005f08:	795a                	ld	s2,432(sp)
    80005f0a:	79ba                	ld	s3,424(sp)
    80005f0c:	7a1a                	ld	s4,416(sp)
    80005f0e:	6afa                	ld	s5,408(sp)
    80005f10:	6179                	addi	sp,sp,464
    80005f12:	8082                	ret

0000000080005f14 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005f14:	7139                	addi	sp,sp,-64
    80005f16:	fc06                	sd	ra,56(sp)
    80005f18:	f822                	sd	s0,48(sp)
    80005f1a:	f426                	sd	s1,40(sp)
    80005f1c:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005f1e:	ffffc097          	auipc	ra,0xffffc
    80005f22:	e14080e7          	jalr	-492(ra) # 80001d32 <myproc>
    80005f26:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005f28:	fd840593          	addi	a1,s0,-40
    80005f2c:	4501                	li	a0,0
    80005f2e:	ffffd097          	auipc	ra,0xffffd
    80005f32:	ee6080e7          	jalr	-282(ra) # 80002e14 <argaddr>
    return -1;
    80005f36:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005f38:	0e054063          	bltz	a0,80006018 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005f3c:	fc840593          	addi	a1,s0,-56
    80005f40:	fd040513          	addi	a0,s0,-48
    80005f44:	fffff097          	auipc	ra,0xfffff
    80005f48:	dcc080e7          	jalr	-564(ra) # 80004d10 <pipealloc>
    return -1;
    80005f4c:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005f4e:	0c054563          	bltz	a0,80006018 <sys_pipe+0x104>
  fd0 = -1;
    80005f52:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005f56:	fd043503          	ld	a0,-48(s0)
    80005f5a:	fffff097          	auipc	ra,0xfffff
    80005f5e:	504080e7          	jalr	1284(ra) # 8000545e <fdalloc>
    80005f62:	fca42223          	sw	a0,-60(s0)
    80005f66:	08054c63          	bltz	a0,80005ffe <sys_pipe+0xea>
    80005f6a:	fc843503          	ld	a0,-56(s0)
    80005f6e:	fffff097          	auipc	ra,0xfffff
    80005f72:	4f0080e7          	jalr	1264(ra) # 8000545e <fdalloc>
    80005f76:	fca42023          	sw	a0,-64(s0)
    80005f7a:	06054963          	bltz	a0,80005fec <sys_pipe+0xd8>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005f7e:	4691                	li	a3,4
    80005f80:	fc440613          	addi	a2,s0,-60
    80005f84:	fd843583          	ld	a1,-40(s0)
    80005f88:	6ca8                	ld	a0,88(s1)
    80005f8a:	ffffc097          	auipc	ra,0xffffc
    80005f8e:	a9e080e7          	jalr	-1378(ra) # 80001a28 <copyout>
    80005f92:	02054063          	bltz	a0,80005fb2 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005f96:	4691                	li	a3,4
    80005f98:	fc040613          	addi	a2,s0,-64
    80005f9c:	fd843583          	ld	a1,-40(s0)
    80005fa0:	0591                	addi	a1,a1,4
    80005fa2:	6ca8                	ld	a0,88(s1)
    80005fa4:	ffffc097          	auipc	ra,0xffffc
    80005fa8:	a84080e7          	jalr	-1404(ra) # 80001a28 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005fac:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005fae:	06055563          	bgez	a0,80006018 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005fb2:	fc442783          	lw	a5,-60(s0)
    80005fb6:	07e9                	addi	a5,a5,26
    80005fb8:	078e                	slli	a5,a5,0x3
    80005fba:	97a6                	add	a5,a5,s1
    80005fbc:	0007b423          	sd	zero,8(a5)
    p->ofile[fd1] = 0;
    80005fc0:	fc042783          	lw	a5,-64(s0)
    80005fc4:	07e9                	addi	a5,a5,26
    80005fc6:	078e                	slli	a5,a5,0x3
    80005fc8:	00f48533          	add	a0,s1,a5
    80005fcc:	00053423          	sd	zero,8(a0)
    fileclose(rf);
    80005fd0:	fd043503          	ld	a0,-48(s0)
    80005fd4:	fffff097          	auipc	ra,0xfffff
    80005fd8:	9e6080e7          	jalr	-1562(ra) # 800049ba <fileclose>
    fileclose(wf);
    80005fdc:	fc843503          	ld	a0,-56(s0)
    80005fe0:	fffff097          	auipc	ra,0xfffff
    80005fe4:	9da080e7          	jalr	-1574(ra) # 800049ba <fileclose>
    return -1;
    80005fe8:	57fd                	li	a5,-1
    80005fea:	a03d                	j	80006018 <sys_pipe+0x104>
    if(fd0 >= 0)
    80005fec:	fc442783          	lw	a5,-60(s0)
    80005ff0:	0007c763          	bltz	a5,80005ffe <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005ff4:	07e9                	addi	a5,a5,26
    80005ff6:	078e                	slli	a5,a5,0x3
    80005ff8:	97a6                	add	a5,a5,s1
    80005ffa:	0007b423          	sd	zero,8(a5)
    fileclose(rf);
    80005ffe:	fd043503          	ld	a0,-48(s0)
    80006002:	fffff097          	auipc	ra,0xfffff
    80006006:	9b8080e7          	jalr	-1608(ra) # 800049ba <fileclose>
    fileclose(wf);
    8000600a:	fc843503          	ld	a0,-56(s0)
    8000600e:	fffff097          	auipc	ra,0xfffff
    80006012:	9ac080e7          	jalr	-1620(ra) # 800049ba <fileclose>
    return -1;
    80006016:	57fd                	li	a5,-1
}
    80006018:	853e                	mv	a0,a5
    8000601a:	70e2                	ld	ra,56(sp)
    8000601c:	7442                	ld	s0,48(sp)
    8000601e:	74a2                	ld	s1,40(sp)
    80006020:	6121                	addi	sp,sp,64
    80006022:	8082                	ret
	...

0000000080006030 <kernelvec>:
    80006030:	7111                	addi	sp,sp,-256
    80006032:	e006                	sd	ra,0(sp)
    80006034:	e40a                	sd	sp,8(sp)
    80006036:	e80e                	sd	gp,16(sp)
    80006038:	ec12                	sd	tp,24(sp)
    8000603a:	f016                	sd	t0,32(sp)
    8000603c:	f41a                	sd	t1,40(sp)
    8000603e:	f81e                	sd	t2,48(sp)
    80006040:	fc22                	sd	s0,56(sp)
    80006042:	e0a6                	sd	s1,64(sp)
    80006044:	e4aa                	sd	a0,72(sp)
    80006046:	e8ae                	sd	a1,80(sp)
    80006048:	ecb2                	sd	a2,88(sp)
    8000604a:	f0b6                	sd	a3,96(sp)
    8000604c:	f4ba                	sd	a4,104(sp)
    8000604e:	f8be                	sd	a5,112(sp)
    80006050:	fcc2                	sd	a6,120(sp)
    80006052:	e146                	sd	a7,128(sp)
    80006054:	e54a                	sd	s2,136(sp)
    80006056:	e94e                	sd	s3,144(sp)
    80006058:	ed52                	sd	s4,152(sp)
    8000605a:	f156                	sd	s5,160(sp)
    8000605c:	f55a                	sd	s6,168(sp)
    8000605e:	f95e                	sd	s7,176(sp)
    80006060:	fd62                	sd	s8,184(sp)
    80006062:	e1e6                	sd	s9,192(sp)
    80006064:	e5ea                	sd	s10,200(sp)
    80006066:	e9ee                	sd	s11,208(sp)
    80006068:	edf2                	sd	t3,216(sp)
    8000606a:	f1f6                	sd	t4,224(sp)
    8000606c:	f5fa                	sd	t5,232(sp)
    8000606e:	f9fe                	sd	t6,240(sp)
    80006070:	bb5fc0ef          	jal	ra,80002c24 <kerneltrap>
    80006074:	6082                	ld	ra,0(sp)
    80006076:	6122                	ld	sp,8(sp)
    80006078:	61c2                	ld	gp,16(sp)
    8000607a:	7282                	ld	t0,32(sp)
    8000607c:	7322                	ld	t1,40(sp)
    8000607e:	73c2                	ld	t2,48(sp)
    80006080:	7462                	ld	s0,56(sp)
    80006082:	6486                	ld	s1,64(sp)
    80006084:	6526                	ld	a0,72(sp)
    80006086:	65c6                	ld	a1,80(sp)
    80006088:	6666                	ld	a2,88(sp)
    8000608a:	7686                	ld	a3,96(sp)
    8000608c:	7726                	ld	a4,104(sp)
    8000608e:	77c6                	ld	a5,112(sp)
    80006090:	7866                	ld	a6,120(sp)
    80006092:	688a                	ld	a7,128(sp)
    80006094:	692a                	ld	s2,136(sp)
    80006096:	69ca                	ld	s3,144(sp)
    80006098:	6a6a                	ld	s4,152(sp)
    8000609a:	7a8a                	ld	s5,160(sp)
    8000609c:	7b2a                	ld	s6,168(sp)
    8000609e:	7bca                	ld	s7,176(sp)
    800060a0:	7c6a                	ld	s8,184(sp)
    800060a2:	6c8e                	ld	s9,192(sp)
    800060a4:	6d2e                	ld	s10,200(sp)
    800060a6:	6dce                	ld	s11,208(sp)
    800060a8:	6e6e                	ld	t3,216(sp)
    800060aa:	7e8e                	ld	t4,224(sp)
    800060ac:	7f2e                	ld	t5,232(sp)
    800060ae:	7fce                	ld	t6,240(sp)
    800060b0:	6111                	addi	sp,sp,256
    800060b2:	10200073          	sret
    800060b6:	00000013          	nop
    800060ba:	00000013          	nop
    800060be:	0001                	nop

00000000800060c0 <timervec>:
    800060c0:	34051573          	csrrw	a0,mscratch,a0
    800060c4:	e10c                	sd	a1,0(a0)
    800060c6:	e510                	sd	a2,8(a0)
    800060c8:	e914                	sd	a3,16(a0)
    800060ca:	6d0c                	ld	a1,24(a0)
    800060cc:	7110                	ld	a2,32(a0)
    800060ce:	6194                	ld	a3,0(a1)
    800060d0:	96b2                	add	a3,a3,a2
    800060d2:	e194                	sd	a3,0(a1)
    800060d4:	4589                	li	a1,2
    800060d6:	14459073          	csrw	sip,a1
    800060da:	6914                	ld	a3,16(a0)
    800060dc:	6510                	ld	a2,8(a0)
    800060de:	610c                	ld	a1,0(a0)
    800060e0:	34051573          	csrrw	a0,mscratch,a0
    800060e4:	30200073          	mret
	...

00000000800060ea <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    800060ea:	1141                	addi	sp,sp,-16
    800060ec:	e422                	sd	s0,8(sp)
    800060ee:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    800060f0:	0c0007b7          	lui	a5,0xc000
    800060f4:	4705                	li	a4,1
    800060f6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    800060f8:	c3d8                	sw	a4,4(a5)
}
    800060fa:	6422                	ld	s0,8(sp)
    800060fc:	0141                	addi	sp,sp,16
    800060fe:	8082                	ret

0000000080006100 <plicinithart>:

void
plicinithart(void)
{
    80006100:	1141                	addi	sp,sp,-16
    80006102:	e406                	sd	ra,8(sp)
    80006104:	e022                	sd	s0,0(sp)
    80006106:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006108:	ffffc097          	auipc	ra,0xffffc
    8000610c:	bfe080e7          	jalr	-1026(ra) # 80001d06 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80006110:	0085171b          	slliw	a4,a0,0x8
    80006114:	0c0027b7          	lui	a5,0xc002
    80006118:	97ba                	add	a5,a5,a4
    8000611a:	40200713          	li	a4,1026
    8000611e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80006122:	00d5151b          	slliw	a0,a0,0xd
    80006126:	0c2017b7          	lui	a5,0xc201
    8000612a:	97aa                	add	a5,a5,a0
    8000612c:	0007a023          	sw	zero,0(a5) # c201000 <_entry-0x73dff000>
}
    80006130:	60a2                	ld	ra,8(sp)
    80006132:	6402                	ld	s0,0(sp)
    80006134:	0141                	addi	sp,sp,16
    80006136:	8082                	ret

0000000080006138 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80006138:	1141                	addi	sp,sp,-16
    8000613a:	e406                	sd	ra,8(sp)
    8000613c:	e022                	sd	s0,0(sp)
    8000613e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006140:	ffffc097          	auipc	ra,0xffffc
    80006144:	bc6080e7          	jalr	-1082(ra) # 80001d06 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80006148:	00d5151b          	slliw	a0,a0,0xd
    8000614c:	0c2017b7          	lui	a5,0xc201
    80006150:	97aa                	add	a5,a5,a0
  return irq;
}
    80006152:	43c8                	lw	a0,4(a5)
    80006154:	60a2                	ld	ra,8(sp)
    80006156:	6402                	ld	s0,0(sp)
    80006158:	0141                	addi	sp,sp,16
    8000615a:	8082                	ret

000000008000615c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    8000615c:	1101                	addi	sp,sp,-32
    8000615e:	ec06                	sd	ra,24(sp)
    80006160:	e822                	sd	s0,16(sp)
    80006162:	e426                	sd	s1,8(sp)
    80006164:	1000                	addi	s0,sp,32
    80006166:	84aa                	mv	s1,a0
  int hart = cpuid();
    80006168:	ffffc097          	auipc	ra,0xffffc
    8000616c:	b9e080e7          	jalr	-1122(ra) # 80001d06 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006170:	00d5151b          	slliw	a0,a0,0xd
    80006174:	0c2017b7          	lui	a5,0xc201
    80006178:	97aa                	add	a5,a5,a0
    8000617a:	c3c4                	sw	s1,4(a5)
}
    8000617c:	60e2                	ld	ra,24(sp)
    8000617e:	6442                	ld	s0,16(sp)
    80006180:	64a2                	ld	s1,8(sp)
    80006182:	6105                	addi	sp,sp,32
    80006184:	8082                	ret

0000000080006186 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006186:	1141                	addi	sp,sp,-16
    80006188:	e406                	sd	ra,8(sp)
    8000618a:	e022                	sd	s0,0(sp)
    8000618c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    8000618e:	479d                	li	a5,7
    80006190:	06a7c863          	blt	a5,a0,80006200 <free_desc+0x7a>
    panic("free_desc 1");
  if(disk.free[i])
    80006194:	00023717          	auipc	a4,0x23
    80006198:	e6c70713          	addi	a4,a4,-404 # 80029000 <disk>
    8000619c:	972a                	add	a4,a4,a0
    8000619e:	6789                	lui	a5,0x2
    800061a0:	97ba                	add	a5,a5,a4
    800061a2:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    800061a6:	e7ad                	bnez	a5,80006210 <free_desc+0x8a>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    800061a8:	00451793          	slli	a5,a0,0x4
    800061ac:	00025717          	auipc	a4,0x25
    800061b0:	e5470713          	addi	a4,a4,-428 # 8002b000 <disk+0x2000>
    800061b4:	6314                	ld	a3,0(a4)
    800061b6:	96be                	add	a3,a3,a5
    800061b8:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    800061bc:	6314                	ld	a3,0(a4)
    800061be:	96be                	add	a3,a3,a5
    800061c0:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    800061c4:	6314                	ld	a3,0(a4)
    800061c6:	96be                	add	a3,a3,a5
    800061c8:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    800061cc:	6318                	ld	a4,0(a4)
    800061ce:	97ba                	add	a5,a5,a4
    800061d0:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    800061d4:	00023717          	auipc	a4,0x23
    800061d8:	e2c70713          	addi	a4,a4,-468 # 80029000 <disk>
    800061dc:	972a                	add	a4,a4,a0
    800061de:	6789                	lui	a5,0x2
    800061e0:	97ba                	add	a5,a5,a4
    800061e2:	4705                	li	a4,1
    800061e4:	00e78c23          	sb	a4,24(a5) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    800061e8:	00025517          	auipc	a0,0x25
    800061ec:	e3050513          	addi	a0,a0,-464 # 8002b018 <disk+0x2018>
    800061f0:	ffffc097          	auipc	ra,0xffffc
    800061f4:	4da080e7          	jalr	1242(ra) # 800026ca <wakeup>
}
    800061f8:	60a2                	ld	ra,8(sp)
    800061fa:	6402                	ld	s0,0(sp)
    800061fc:	0141                	addi	sp,sp,16
    800061fe:	8082                	ret
    panic("free_desc 1");
    80006200:	00002517          	auipc	a0,0x2
    80006204:	5e050513          	addi	a0,a0,1504 # 800087e0 <syscalls+0x328>
    80006208:	ffffa097          	auipc	ra,0xffffa
    8000620c:	344080e7          	jalr	836(ra) # 8000054c <panic>
    panic("free_desc 2");
    80006210:	00002517          	auipc	a0,0x2
    80006214:	5e050513          	addi	a0,a0,1504 # 800087f0 <syscalls+0x338>
    80006218:	ffffa097          	auipc	ra,0xffffa
    8000621c:	334080e7          	jalr	820(ra) # 8000054c <panic>

0000000080006220 <virtio_disk_init>:
{
    80006220:	1101                	addi	sp,sp,-32
    80006222:	ec06                	sd	ra,24(sp)
    80006224:	e822                	sd	s0,16(sp)
    80006226:	e426                	sd	s1,8(sp)
    80006228:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    8000622a:	00002597          	auipc	a1,0x2
    8000622e:	5d658593          	addi	a1,a1,1494 # 80008800 <syscalls+0x348>
    80006232:	00025517          	auipc	a0,0x25
    80006236:	ef650513          	addi	a0,a0,-266 # 8002b128 <disk+0x2128>
    8000623a:	ffffb097          	auipc	ra,0xffffb
    8000623e:	c2e080e7          	jalr	-978(ra) # 80000e68 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006242:	100017b7          	lui	a5,0x10001
    80006246:	4398                	lw	a4,0(a5)
    80006248:	2701                	sext.w	a4,a4
    8000624a:	747277b7          	lui	a5,0x74727
    8000624e:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80006252:	0ef71063          	bne	a4,a5,80006332 <virtio_disk_init+0x112>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80006256:	100017b7          	lui	a5,0x10001
    8000625a:	43dc                	lw	a5,4(a5)
    8000625c:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    8000625e:	4705                	li	a4,1
    80006260:	0ce79963          	bne	a5,a4,80006332 <virtio_disk_init+0x112>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006264:	100017b7          	lui	a5,0x10001
    80006268:	479c                	lw	a5,8(a5)
    8000626a:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    8000626c:	4709                	li	a4,2
    8000626e:	0ce79263          	bne	a5,a4,80006332 <virtio_disk_init+0x112>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80006272:	100017b7          	lui	a5,0x10001
    80006276:	47d8                	lw	a4,12(a5)
    80006278:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000627a:	554d47b7          	lui	a5,0x554d4
    8000627e:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80006282:	0af71863          	bne	a4,a5,80006332 <virtio_disk_init+0x112>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006286:	100017b7          	lui	a5,0x10001
    8000628a:	4705                	li	a4,1
    8000628c:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000628e:	470d                	li	a4,3
    80006290:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80006292:	4b98                	lw	a4,16(a5)
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006294:	c7ffe6b7          	lui	a3,0xc7ffe
    80006298:	75f68693          	addi	a3,a3,1887 # ffffffffc7ffe75f <end+0xffffffff47fd1737>
    8000629c:	8f75                	and	a4,a4,a3
    8000629e:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800062a0:	472d                	li	a4,11
    800062a2:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800062a4:	473d                	li	a4,15
    800062a6:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    800062a8:	6705                	lui	a4,0x1
    800062aa:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    800062ac:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    800062b0:	5bdc                	lw	a5,52(a5)
    800062b2:	2781                	sext.w	a5,a5
  if(max == 0)
    800062b4:	c7d9                	beqz	a5,80006342 <virtio_disk_init+0x122>
  if(max < NUM)
    800062b6:	471d                	li	a4,7
    800062b8:	08f77d63          	bgeu	a4,a5,80006352 <virtio_disk_init+0x132>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    800062bc:	100014b7          	lui	s1,0x10001
    800062c0:	47a1                	li	a5,8
    800062c2:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    800062c4:	6609                	lui	a2,0x2
    800062c6:	4581                	li	a1,0
    800062c8:	00023517          	auipc	a0,0x23
    800062cc:	d3850513          	addi	a0,a0,-712 # 80029000 <disk>
    800062d0:	ffffb097          	auipc	ra,0xffffb
    800062d4:	dfc080e7          	jalr	-516(ra) # 800010cc <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    800062d8:	00023717          	auipc	a4,0x23
    800062dc:	d2870713          	addi	a4,a4,-728 # 80029000 <disk>
    800062e0:	00c75793          	srli	a5,a4,0xc
    800062e4:	2781                	sext.w	a5,a5
    800062e6:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    800062e8:	00025797          	auipc	a5,0x25
    800062ec:	d1878793          	addi	a5,a5,-744 # 8002b000 <disk+0x2000>
    800062f0:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    800062f2:	00023717          	auipc	a4,0x23
    800062f6:	d8e70713          	addi	a4,a4,-626 # 80029080 <disk+0x80>
    800062fa:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    800062fc:	00024717          	auipc	a4,0x24
    80006300:	d0470713          	addi	a4,a4,-764 # 8002a000 <disk+0x1000>
    80006304:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    80006306:	4705                	li	a4,1
    80006308:	00e78c23          	sb	a4,24(a5)
    8000630c:	00e78ca3          	sb	a4,25(a5)
    80006310:	00e78d23          	sb	a4,26(a5)
    80006314:	00e78da3          	sb	a4,27(a5)
    80006318:	00e78e23          	sb	a4,28(a5)
    8000631c:	00e78ea3          	sb	a4,29(a5)
    80006320:	00e78f23          	sb	a4,30(a5)
    80006324:	00e78fa3          	sb	a4,31(a5)
}
    80006328:	60e2                	ld	ra,24(sp)
    8000632a:	6442                	ld	s0,16(sp)
    8000632c:	64a2                	ld	s1,8(sp)
    8000632e:	6105                	addi	sp,sp,32
    80006330:	8082                	ret
    panic("could not find virtio disk");
    80006332:	00002517          	auipc	a0,0x2
    80006336:	4de50513          	addi	a0,a0,1246 # 80008810 <syscalls+0x358>
    8000633a:	ffffa097          	auipc	ra,0xffffa
    8000633e:	212080e7          	jalr	530(ra) # 8000054c <panic>
    panic("virtio disk has no queue 0");
    80006342:	00002517          	auipc	a0,0x2
    80006346:	4ee50513          	addi	a0,a0,1262 # 80008830 <syscalls+0x378>
    8000634a:	ffffa097          	auipc	ra,0xffffa
    8000634e:	202080e7          	jalr	514(ra) # 8000054c <panic>
    panic("virtio disk max queue too short");
    80006352:	00002517          	auipc	a0,0x2
    80006356:	4fe50513          	addi	a0,a0,1278 # 80008850 <syscalls+0x398>
    8000635a:	ffffa097          	auipc	ra,0xffffa
    8000635e:	1f2080e7          	jalr	498(ra) # 8000054c <panic>

0000000080006362 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006362:	7119                	addi	sp,sp,-128
    80006364:	fc86                	sd	ra,120(sp)
    80006366:	f8a2                	sd	s0,112(sp)
    80006368:	f4a6                	sd	s1,104(sp)
    8000636a:	f0ca                	sd	s2,96(sp)
    8000636c:	ecce                	sd	s3,88(sp)
    8000636e:	e8d2                	sd	s4,80(sp)
    80006370:	e4d6                	sd	s5,72(sp)
    80006372:	e0da                	sd	s6,64(sp)
    80006374:	fc5e                	sd	s7,56(sp)
    80006376:	f862                	sd	s8,48(sp)
    80006378:	f466                	sd	s9,40(sp)
    8000637a:	f06a                	sd	s10,32(sp)
    8000637c:	ec6e                	sd	s11,24(sp)
    8000637e:	0100                	addi	s0,sp,128
    80006380:	8aaa                	mv	s5,a0
    80006382:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006384:	00c52c83          	lw	s9,12(a0)
    80006388:	001c9c9b          	slliw	s9,s9,0x1
    8000638c:	1c82                	slli	s9,s9,0x20
    8000638e:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006392:	00025517          	auipc	a0,0x25
    80006396:	d9650513          	addi	a0,a0,-618 # 8002b128 <disk+0x2128>
    8000639a:	ffffb097          	auipc	ra,0xffffb
    8000639e:	952080e7          	jalr	-1710(ra) # 80000cec <acquire>
  for(int i = 0; i < 3; i++){
    800063a2:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    800063a4:	44a1                	li	s1,8
      disk.free[i] = 0;
    800063a6:	00023c17          	auipc	s8,0x23
    800063aa:	c5ac0c13          	addi	s8,s8,-934 # 80029000 <disk>
    800063ae:	6b89                	lui	s7,0x2
  for(int i = 0; i < 3; i++){
    800063b0:	4b0d                	li	s6,3
    800063b2:	a0ad                	j	8000641c <virtio_disk_rw+0xba>
      disk.free[i] = 0;
    800063b4:	00fc0733          	add	a4,s8,a5
    800063b8:	975e                	add	a4,a4,s7
    800063ba:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    800063be:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    800063c0:	0207c563          	bltz	a5,800063ea <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    800063c4:	2905                	addiw	s2,s2,1
    800063c6:	0611                	addi	a2,a2,4 # 2004 <_entry-0x7fffdffc>
    800063c8:	19690c63          	beq	s2,s6,80006560 <virtio_disk_rw+0x1fe>
    idx[i] = alloc_desc();
    800063cc:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    800063ce:	00025717          	auipc	a4,0x25
    800063d2:	c4a70713          	addi	a4,a4,-950 # 8002b018 <disk+0x2018>
    800063d6:	87ce                	mv	a5,s3
    if(disk.free[i]){
    800063d8:	00074683          	lbu	a3,0(a4)
    800063dc:	fee1                	bnez	a3,800063b4 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    800063de:	2785                	addiw	a5,a5,1
    800063e0:	0705                	addi	a4,a4,1
    800063e2:	fe979be3          	bne	a5,s1,800063d8 <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    800063e6:	57fd                	li	a5,-1
    800063e8:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    800063ea:	01205d63          	blez	s2,80006404 <virtio_disk_rw+0xa2>
    800063ee:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    800063f0:	000a2503          	lw	a0,0(s4)
    800063f4:	00000097          	auipc	ra,0x0
    800063f8:	d92080e7          	jalr	-622(ra) # 80006186 <free_desc>
      for(int j = 0; j < i; j++)
    800063fc:	2d85                	addiw	s11,s11,1
    800063fe:	0a11                	addi	s4,s4,4
    80006400:	ff2d98e3          	bne	s11,s2,800063f0 <virtio_disk_rw+0x8e>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006404:	00025597          	auipc	a1,0x25
    80006408:	d2458593          	addi	a1,a1,-732 # 8002b128 <disk+0x2128>
    8000640c:	00025517          	auipc	a0,0x25
    80006410:	c0c50513          	addi	a0,a0,-1012 # 8002b018 <disk+0x2018>
    80006414:	ffffc097          	auipc	ra,0xffffc
    80006418:	136080e7          	jalr	310(ra) # 8000254a <sleep>
  for(int i = 0; i < 3; i++){
    8000641c:	f8040a13          	addi	s4,s0,-128
{
    80006420:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    80006422:	894e                	mv	s2,s3
    80006424:	b765                	j	800063cc <virtio_disk_rw+0x6a>
  disk.desc[idx[0]].next = idx[1];

  disk.desc[idx[1]].addr = (uint64) b->data;
  disk.desc[idx[1]].len = BSIZE;
  if(write)
    disk.desc[idx[1]].flags = 0; // device reads b->data
    80006426:	00025697          	auipc	a3,0x25
    8000642a:	bda6b683          	ld	a3,-1062(a3) # 8002b000 <disk+0x2000>
    8000642e:	96ba                	add	a3,a3,a4
    80006430:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80006434:	00023817          	auipc	a6,0x23
    80006438:	bcc80813          	addi	a6,a6,-1076 # 80029000 <disk>
    8000643c:	00025697          	auipc	a3,0x25
    80006440:	bc468693          	addi	a3,a3,-1084 # 8002b000 <disk+0x2000>
    80006444:	6290                	ld	a2,0(a3)
    80006446:	963a                	add	a2,a2,a4
    80006448:	00c65583          	lhu	a1,12(a2)
    8000644c:	0015e593          	ori	a1,a1,1
    80006450:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[1]].next = idx[2];
    80006454:	f8842603          	lw	a2,-120(s0)
    80006458:	628c                	ld	a1,0(a3)
    8000645a:	972e                	add	a4,a4,a1
    8000645c:	00c71723          	sh	a2,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006460:	20050593          	addi	a1,a0,512
    80006464:	0592                	slli	a1,a1,0x4
    80006466:	95c2                	add	a1,a1,a6
    80006468:	577d                	li	a4,-1
    8000646a:	02e58823          	sb	a4,48(a1)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    8000646e:	00461713          	slli	a4,a2,0x4
    80006472:	6290                	ld	a2,0(a3)
    80006474:	963a                	add	a2,a2,a4
    80006476:	03078793          	addi	a5,a5,48
    8000647a:	97c2                	add	a5,a5,a6
    8000647c:	e21c                	sd	a5,0(a2)
  disk.desc[idx[2]].len = 1;
    8000647e:	629c                	ld	a5,0(a3)
    80006480:	97ba                	add	a5,a5,a4
    80006482:	4605                	li	a2,1
    80006484:	c790                	sw	a2,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006486:	629c                	ld	a5,0(a3)
    80006488:	97ba                	add	a5,a5,a4
    8000648a:	4809                	li	a6,2
    8000648c:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80006490:	629c                	ld	a5,0(a3)
    80006492:	97ba                	add	a5,a5,a4
    80006494:	00079723          	sh	zero,14(a5)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006498:	00caa223          	sw	a2,4(s5)
  disk.info[idx[0]].b = b;
    8000649c:	0355b423          	sd	s5,40(a1)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    800064a0:	6698                	ld	a4,8(a3)
    800064a2:	00275783          	lhu	a5,2(a4)
    800064a6:	8b9d                	andi	a5,a5,7
    800064a8:	0786                	slli	a5,a5,0x1
    800064aa:	973e                	add	a4,a4,a5
    800064ac:	00a71223          	sh	a0,4(a4)

  __sync_synchronize();
    800064b0:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    800064b4:	6698                	ld	a4,8(a3)
    800064b6:	00275783          	lhu	a5,2(a4)
    800064ba:	2785                	addiw	a5,a5,1
    800064bc:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    800064c0:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    800064c4:	100017b7          	lui	a5,0x10001
    800064c8:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    800064cc:	004aa783          	lw	a5,4(s5)
    800064d0:	02c79163          	bne	a5,a2,800064f2 <virtio_disk_rw+0x190>
    sleep(b, &disk.vdisk_lock);
    800064d4:	00025917          	auipc	s2,0x25
    800064d8:	c5490913          	addi	s2,s2,-940 # 8002b128 <disk+0x2128>
  while(b->disk == 1) {
    800064dc:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    800064de:	85ca                	mv	a1,s2
    800064e0:	8556                	mv	a0,s5
    800064e2:	ffffc097          	auipc	ra,0xffffc
    800064e6:	068080e7          	jalr	104(ra) # 8000254a <sleep>
  while(b->disk == 1) {
    800064ea:	004aa783          	lw	a5,4(s5)
    800064ee:	fe9788e3          	beq	a5,s1,800064de <virtio_disk_rw+0x17c>
  }

  disk.info[idx[0]].b = 0;
    800064f2:	f8042903          	lw	s2,-128(s0)
    800064f6:	20090713          	addi	a4,s2,512
    800064fa:	0712                	slli	a4,a4,0x4
    800064fc:	00023797          	auipc	a5,0x23
    80006500:	b0478793          	addi	a5,a5,-1276 # 80029000 <disk>
    80006504:	97ba                	add	a5,a5,a4
    80006506:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    8000650a:	00025997          	auipc	s3,0x25
    8000650e:	af698993          	addi	s3,s3,-1290 # 8002b000 <disk+0x2000>
    80006512:	00491713          	slli	a4,s2,0x4
    80006516:	0009b783          	ld	a5,0(s3)
    8000651a:	97ba                	add	a5,a5,a4
    8000651c:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006520:	854a                	mv	a0,s2
    80006522:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006526:	00000097          	auipc	ra,0x0
    8000652a:	c60080e7          	jalr	-928(ra) # 80006186 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    8000652e:	8885                	andi	s1,s1,1
    80006530:	f0ed                	bnez	s1,80006512 <virtio_disk_rw+0x1b0>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006532:	00025517          	auipc	a0,0x25
    80006536:	bf650513          	addi	a0,a0,-1034 # 8002b128 <disk+0x2128>
    8000653a:	ffffb097          	auipc	ra,0xffffb
    8000653e:	882080e7          	jalr	-1918(ra) # 80000dbc <release>
}
    80006542:	70e6                	ld	ra,120(sp)
    80006544:	7446                	ld	s0,112(sp)
    80006546:	74a6                	ld	s1,104(sp)
    80006548:	7906                	ld	s2,96(sp)
    8000654a:	69e6                	ld	s3,88(sp)
    8000654c:	6a46                	ld	s4,80(sp)
    8000654e:	6aa6                	ld	s5,72(sp)
    80006550:	6b06                	ld	s6,64(sp)
    80006552:	7be2                	ld	s7,56(sp)
    80006554:	7c42                	ld	s8,48(sp)
    80006556:	7ca2                	ld	s9,40(sp)
    80006558:	7d02                	ld	s10,32(sp)
    8000655a:	6de2                	ld	s11,24(sp)
    8000655c:	6109                	addi	sp,sp,128
    8000655e:	8082                	ret
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006560:	f8042503          	lw	a0,-128(s0)
    80006564:	20050793          	addi	a5,a0,512
    80006568:	0792                	slli	a5,a5,0x4
  if(write)
    8000656a:	00023817          	auipc	a6,0x23
    8000656e:	a9680813          	addi	a6,a6,-1386 # 80029000 <disk>
    80006572:	00f80733          	add	a4,a6,a5
    80006576:	01a036b3          	snez	a3,s10
    8000657a:	0ad72423          	sw	a3,168(a4)
  buf0->reserved = 0;
    8000657e:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    80006582:	0b973823          	sd	s9,176(a4)
  disk.desc[idx[0]].addr = (uint64) buf0;
    80006586:	7679                	lui	a2,0xffffe
    80006588:	963e                	add	a2,a2,a5
    8000658a:	00025697          	auipc	a3,0x25
    8000658e:	a7668693          	addi	a3,a3,-1418 # 8002b000 <disk+0x2000>
    80006592:	6298                	ld	a4,0(a3)
    80006594:	9732                	add	a4,a4,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006596:	0a878593          	addi	a1,a5,168
    8000659a:	95c2                	add	a1,a1,a6
  disk.desc[idx[0]].addr = (uint64) buf0;
    8000659c:	e30c                	sd	a1,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    8000659e:	6298                	ld	a4,0(a3)
    800065a0:	9732                	add	a4,a4,a2
    800065a2:	45c1                	li	a1,16
    800065a4:	c70c                	sw	a1,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    800065a6:	6298                	ld	a4,0(a3)
    800065a8:	9732                	add	a4,a4,a2
    800065aa:	4585                	li	a1,1
    800065ac:	00b71623          	sh	a1,12(a4)
  disk.desc[idx[0]].next = idx[1];
    800065b0:	f8442703          	lw	a4,-124(s0)
    800065b4:	628c                	ld	a1,0(a3)
    800065b6:	962e                	add	a2,a2,a1
    800065b8:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd0fe6>
  disk.desc[idx[1]].addr = (uint64) b->data;
    800065bc:	0712                	slli	a4,a4,0x4
    800065be:	6290                	ld	a2,0(a3)
    800065c0:	963a                	add	a2,a2,a4
    800065c2:	060a8593          	addi	a1,s5,96
    800065c6:	e20c                	sd	a1,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    800065c8:	6294                	ld	a3,0(a3)
    800065ca:	96ba                	add	a3,a3,a4
    800065cc:	40000613          	li	a2,1024
    800065d0:	c690                	sw	a2,8(a3)
  if(write)
    800065d2:	e40d1ae3          	bnez	s10,80006426 <virtio_disk_rw+0xc4>
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    800065d6:	00025697          	auipc	a3,0x25
    800065da:	a2a6b683          	ld	a3,-1494(a3) # 8002b000 <disk+0x2000>
    800065de:	96ba                	add	a3,a3,a4
    800065e0:	4609                	li	a2,2
    800065e2:	00c69623          	sh	a2,12(a3)
    800065e6:	b5b9                	j	80006434 <virtio_disk_rw+0xd2>

00000000800065e8 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    800065e8:	1101                	addi	sp,sp,-32
    800065ea:	ec06                	sd	ra,24(sp)
    800065ec:	e822                	sd	s0,16(sp)
    800065ee:	e426                	sd	s1,8(sp)
    800065f0:	e04a                	sd	s2,0(sp)
    800065f2:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    800065f4:	00025517          	auipc	a0,0x25
    800065f8:	b3450513          	addi	a0,a0,-1228 # 8002b128 <disk+0x2128>
    800065fc:	ffffa097          	auipc	ra,0xffffa
    80006600:	6f0080e7          	jalr	1776(ra) # 80000cec <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006604:	10001737          	lui	a4,0x10001
    80006608:	533c                	lw	a5,96(a4)
    8000660a:	8b8d                	andi	a5,a5,3
    8000660c:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    8000660e:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006612:	00025797          	auipc	a5,0x25
    80006616:	9ee78793          	addi	a5,a5,-1554 # 8002b000 <disk+0x2000>
    8000661a:	6b94                	ld	a3,16(a5)
    8000661c:	0207d703          	lhu	a4,32(a5)
    80006620:	0026d783          	lhu	a5,2(a3)
    80006624:	06f70163          	beq	a4,a5,80006686 <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006628:	00023917          	auipc	s2,0x23
    8000662c:	9d890913          	addi	s2,s2,-1576 # 80029000 <disk>
    80006630:	00025497          	auipc	s1,0x25
    80006634:	9d048493          	addi	s1,s1,-1584 # 8002b000 <disk+0x2000>
    __sync_synchronize();
    80006638:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    8000663c:	6898                	ld	a4,16(s1)
    8000663e:	0204d783          	lhu	a5,32(s1)
    80006642:	8b9d                	andi	a5,a5,7
    80006644:	078e                	slli	a5,a5,0x3
    80006646:	97ba                	add	a5,a5,a4
    80006648:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    8000664a:	20078713          	addi	a4,a5,512
    8000664e:	0712                	slli	a4,a4,0x4
    80006650:	974a                	add	a4,a4,s2
    80006652:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    80006656:	e731                	bnez	a4,800066a2 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006658:	20078793          	addi	a5,a5,512
    8000665c:	0792                	slli	a5,a5,0x4
    8000665e:	97ca                	add	a5,a5,s2
    80006660:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    80006662:	00052223          	sw	zero,4(a0)
    wakeup(b);
    80006666:	ffffc097          	auipc	ra,0xffffc
    8000666a:	064080e7          	jalr	100(ra) # 800026ca <wakeup>

    disk.used_idx += 1;
    8000666e:	0204d783          	lhu	a5,32(s1)
    80006672:	2785                	addiw	a5,a5,1
    80006674:	17c2                	slli	a5,a5,0x30
    80006676:	93c1                	srli	a5,a5,0x30
    80006678:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    8000667c:	6898                	ld	a4,16(s1)
    8000667e:	00275703          	lhu	a4,2(a4)
    80006682:	faf71be3          	bne	a4,a5,80006638 <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    80006686:	00025517          	auipc	a0,0x25
    8000668a:	aa250513          	addi	a0,a0,-1374 # 8002b128 <disk+0x2128>
    8000668e:	ffffa097          	auipc	ra,0xffffa
    80006692:	72e080e7          	jalr	1838(ra) # 80000dbc <release>
}
    80006696:	60e2                	ld	ra,24(sp)
    80006698:	6442                	ld	s0,16(sp)
    8000669a:	64a2                	ld	s1,8(sp)
    8000669c:	6902                	ld	s2,0(sp)
    8000669e:	6105                	addi	sp,sp,32
    800066a0:	8082                	ret
      panic("virtio_disk_intr status");
    800066a2:	00002517          	auipc	a0,0x2
    800066a6:	1ce50513          	addi	a0,a0,462 # 80008870 <syscalls+0x3b8>
    800066aa:	ffffa097          	auipc	ra,0xffffa
    800066ae:	ea2080e7          	jalr	-350(ra) # 8000054c <panic>

00000000800066b2 <statswrite>:
int statscopyin(char*, int);
int statslock(char*, int);
  
int
statswrite(int user_src, uint64 src, int n)
{
    800066b2:	1141                	addi	sp,sp,-16
    800066b4:	e422                	sd	s0,8(sp)
    800066b6:	0800                	addi	s0,sp,16
  return -1;
}
    800066b8:	557d                	li	a0,-1
    800066ba:	6422                	ld	s0,8(sp)
    800066bc:	0141                	addi	sp,sp,16
    800066be:	8082                	ret

00000000800066c0 <statsread>:

int
statsread(int user_dst, uint64 dst, int n)
{
    800066c0:	7179                	addi	sp,sp,-48
    800066c2:	f406                	sd	ra,40(sp)
    800066c4:	f022                	sd	s0,32(sp)
    800066c6:	ec26                	sd	s1,24(sp)
    800066c8:	e84a                	sd	s2,16(sp)
    800066ca:	e44e                	sd	s3,8(sp)
    800066cc:	e052                	sd	s4,0(sp)
    800066ce:	1800                	addi	s0,sp,48
    800066d0:	892a                	mv	s2,a0
    800066d2:	89ae                	mv	s3,a1
    800066d4:	84b2                	mv	s1,a2
  int m;

  acquire(&stats.lock);
    800066d6:	00026517          	auipc	a0,0x26
    800066da:	92a50513          	addi	a0,a0,-1750 # 8002c000 <stats>
    800066de:	ffffa097          	auipc	ra,0xffffa
    800066e2:	60e080e7          	jalr	1550(ra) # 80000cec <acquire>

  if(stats.sz == 0) {
    800066e6:	00027797          	auipc	a5,0x27
    800066ea:	93a7a783          	lw	a5,-1734(a5) # 8002d020 <stats+0x1020>
    800066ee:	cbb5                	beqz	a5,80006762 <statsread+0xa2>
#endif
#ifdef LAB_LOCK
    stats.sz = statslock(stats.buf, BUFSZ);
#endif
  }
  m = stats.sz - stats.off;
    800066f0:	00027797          	auipc	a5,0x27
    800066f4:	91078793          	addi	a5,a5,-1776 # 8002d000 <stats+0x1000>
    800066f8:	53d8                	lw	a4,36(a5)
    800066fa:	539c                	lw	a5,32(a5)
    800066fc:	9f99                	subw	a5,a5,a4
    800066fe:	0007869b          	sext.w	a3,a5

  if (m > 0) {
    80006702:	06d05e63          	blez	a3,8000677e <statsread+0xbe>
    if(m > n)
    80006706:	8a3e                	mv	s4,a5
    80006708:	00d4d363          	bge	s1,a3,8000670e <statsread+0x4e>
    8000670c:	8a26                	mv	s4,s1
    8000670e:	000a049b          	sext.w	s1,s4
      m  = n;
    if(either_copyout(user_dst, dst, stats.buf+stats.off, m) != -1) {
    80006712:	86a6                	mv	a3,s1
    80006714:	00026617          	auipc	a2,0x26
    80006718:	90c60613          	addi	a2,a2,-1780 # 8002c020 <stats+0x20>
    8000671c:	963a                	add	a2,a2,a4
    8000671e:	85ce                	mv	a1,s3
    80006720:	854a                	mv	a0,s2
    80006722:	ffffc097          	auipc	ra,0xffffc
    80006726:	082080e7          	jalr	130(ra) # 800027a4 <either_copyout>
    8000672a:	57fd                	li	a5,-1
    8000672c:	00f50a63          	beq	a0,a5,80006740 <statsread+0x80>
      stats.off += m;
    80006730:	00027717          	auipc	a4,0x27
    80006734:	8d070713          	addi	a4,a4,-1840 # 8002d000 <stats+0x1000>
    80006738:	535c                	lw	a5,36(a4)
    8000673a:	00fa07bb          	addw	a5,s4,a5
    8000673e:	d35c                	sw	a5,36(a4)
  } else {
    m = -1;
    stats.sz = 0;
    stats.off = 0;
  }
  release(&stats.lock);
    80006740:	00026517          	auipc	a0,0x26
    80006744:	8c050513          	addi	a0,a0,-1856 # 8002c000 <stats>
    80006748:	ffffa097          	auipc	ra,0xffffa
    8000674c:	674080e7          	jalr	1652(ra) # 80000dbc <release>
  return m;
}
    80006750:	8526                	mv	a0,s1
    80006752:	70a2                	ld	ra,40(sp)
    80006754:	7402                	ld	s0,32(sp)
    80006756:	64e2                	ld	s1,24(sp)
    80006758:	6942                	ld	s2,16(sp)
    8000675a:	69a2                	ld	s3,8(sp)
    8000675c:	6a02                	ld	s4,0(sp)
    8000675e:	6145                	addi	sp,sp,48
    80006760:	8082                	ret
    stats.sz = statslock(stats.buf, BUFSZ);
    80006762:	6585                	lui	a1,0x1
    80006764:	00026517          	auipc	a0,0x26
    80006768:	8bc50513          	addi	a0,a0,-1860 # 8002c020 <stats+0x20>
    8000676c:	ffffa097          	auipc	ra,0xffffa
    80006770:	7aa080e7          	jalr	1962(ra) # 80000f16 <statslock>
    80006774:	00027797          	auipc	a5,0x27
    80006778:	8aa7a623          	sw	a0,-1876(a5) # 8002d020 <stats+0x1020>
    8000677c:	bf95                	j	800066f0 <statsread+0x30>
    stats.sz = 0;
    8000677e:	00027797          	auipc	a5,0x27
    80006782:	88278793          	addi	a5,a5,-1918 # 8002d000 <stats+0x1000>
    80006786:	0207a023          	sw	zero,32(a5)
    stats.off = 0;
    8000678a:	0207a223          	sw	zero,36(a5)
    m = -1;
    8000678e:	54fd                	li	s1,-1
    80006790:	bf45                	j	80006740 <statsread+0x80>

0000000080006792 <statsinit>:

void
statsinit(void)
{
    80006792:	1141                	addi	sp,sp,-16
    80006794:	e406                	sd	ra,8(sp)
    80006796:	e022                	sd	s0,0(sp)
    80006798:	0800                	addi	s0,sp,16
  initlock(&stats.lock, "stats");
    8000679a:	00002597          	auipc	a1,0x2
    8000679e:	0ee58593          	addi	a1,a1,238 # 80008888 <syscalls+0x3d0>
    800067a2:	00026517          	auipc	a0,0x26
    800067a6:	85e50513          	addi	a0,a0,-1954 # 8002c000 <stats>
    800067aa:	ffffa097          	auipc	ra,0xffffa
    800067ae:	6be080e7          	jalr	1726(ra) # 80000e68 <initlock>

  devsw[STATS].read = statsread;
    800067b2:	00021797          	auipc	a5,0x21
    800067b6:	8e678793          	addi	a5,a5,-1818 # 80027098 <devsw>
    800067ba:	00000717          	auipc	a4,0x0
    800067be:	f0670713          	addi	a4,a4,-250 # 800066c0 <statsread>
    800067c2:	f398                	sd	a4,32(a5)
  devsw[STATS].write = statswrite;
    800067c4:	00000717          	auipc	a4,0x0
    800067c8:	eee70713          	addi	a4,a4,-274 # 800066b2 <statswrite>
    800067cc:	f798                	sd	a4,40(a5)
}
    800067ce:	60a2                	ld	ra,8(sp)
    800067d0:	6402                	ld	s0,0(sp)
    800067d2:	0141                	addi	sp,sp,16
    800067d4:	8082                	ret

00000000800067d6 <sprintint>:
  return 1;
}

static int
sprintint(char *s, int xx, int base, int sign)
{
    800067d6:	1101                	addi	sp,sp,-32
    800067d8:	ec22                	sd	s0,24(sp)
    800067da:	1000                	addi	s0,sp,32
    800067dc:	882a                	mv	a6,a0
  char buf[16];
  int i, n;
  uint x;

  if(sign && (sign = xx < 0))
    800067de:	c299                	beqz	a3,800067e4 <sprintint+0xe>
    800067e0:	0805c263          	bltz	a1,80006864 <sprintint+0x8e>
    x = -xx;
  else
    x = xx;
    800067e4:	2581                	sext.w	a1,a1
    800067e6:	4301                	li	t1,0

  i = 0;
    800067e8:	fe040713          	addi	a4,s0,-32
    800067ec:	4501                	li	a0,0
  do {
    buf[i++] = digits[x % base];
    800067ee:	2601                	sext.w	a2,a2
    800067f0:	00002697          	auipc	a3,0x2
    800067f4:	0a068693          	addi	a3,a3,160 # 80008890 <digits>
    800067f8:	88aa                	mv	a7,a0
    800067fa:	2505                	addiw	a0,a0,1
    800067fc:	02c5f7bb          	remuw	a5,a1,a2
    80006800:	1782                	slli	a5,a5,0x20
    80006802:	9381                	srli	a5,a5,0x20
    80006804:	97b6                	add	a5,a5,a3
    80006806:	0007c783          	lbu	a5,0(a5)
    8000680a:	00f70023          	sb	a5,0(a4)
  } while((x /= base) != 0);
    8000680e:	0005879b          	sext.w	a5,a1
    80006812:	02c5d5bb          	divuw	a1,a1,a2
    80006816:	0705                	addi	a4,a4,1
    80006818:	fec7f0e3          	bgeu	a5,a2,800067f8 <sprintint+0x22>

  if(sign)
    8000681c:	00030b63          	beqz	t1,80006832 <sprintint+0x5c>
    buf[i++] = '-';
    80006820:	ff050793          	addi	a5,a0,-16
    80006824:	97a2                	add	a5,a5,s0
    80006826:	02d00713          	li	a4,45
    8000682a:	fee78823          	sb	a4,-16(a5)
    8000682e:	0028851b          	addiw	a0,a7,2

  n = 0;
  while(--i >= 0)
    80006832:	02a05d63          	blez	a0,8000686c <sprintint+0x96>
    80006836:	fe040793          	addi	a5,s0,-32
    8000683a:	00a78733          	add	a4,a5,a0
    8000683e:	87c2                	mv	a5,a6
    80006840:	00180613          	addi	a2,a6,1
    80006844:	fff5069b          	addiw	a3,a0,-1
    80006848:	1682                	slli	a3,a3,0x20
    8000684a:	9281                	srli	a3,a3,0x20
    8000684c:	9636                	add	a2,a2,a3
  *s = c;
    8000684e:	fff74683          	lbu	a3,-1(a4)
    80006852:	00d78023          	sb	a3,0(a5)
  while(--i >= 0)
    80006856:	177d                	addi	a4,a4,-1
    80006858:	0785                	addi	a5,a5,1
    8000685a:	fec79ae3          	bne	a5,a2,8000684e <sprintint+0x78>
    n += sputc(s+n, buf[i]);
  return n;
}
    8000685e:	6462                	ld	s0,24(sp)
    80006860:	6105                	addi	sp,sp,32
    80006862:	8082                	ret
    x = -xx;
    80006864:	40b005bb          	negw	a1,a1
  if(sign && (sign = xx < 0))
    80006868:	4305                	li	t1,1
    x = -xx;
    8000686a:	bfbd                	j	800067e8 <sprintint+0x12>
  while(--i >= 0)
    8000686c:	4501                	li	a0,0
    8000686e:	bfc5                	j	8000685e <sprintint+0x88>

0000000080006870 <snprintf>:

int
snprintf(char *buf, int sz, char *fmt, ...)
{
    80006870:	7135                	addi	sp,sp,-160
    80006872:	f486                	sd	ra,104(sp)
    80006874:	f0a2                	sd	s0,96(sp)
    80006876:	eca6                	sd	s1,88(sp)
    80006878:	e8ca                	sd	s2,80(sp)
    8000687a:	e4ce                	sd	s3,72(sp)
    8000687c:	e0d2                	sd	s4,64(sp)
    8000687e:	fc56                	sd	s5,56(sp)
    80006880:	f85a                	sd	s6,48(sp)
    80006882:	f45e                	sd	s7,40(sp)
    80006884:	f062                	sd	s8,32(sp)
    80006886:	ec66                	sd	s9,24(sp)
    80006888:	e86a                	sd	s10,16(sp)
    8000688a:	1880                	addi	s0,sp,112
    8000688c:	e414                	sd	a3,8(s0)
    8000688e:	e818                	sd	a4,16(s0)
    80006890:	ec1c                	sd	a5,24(s0)
    80006892:	03043023          	sd	a6,32(s0)
    80006896:	03143423          	sd	a7,40(s0)
  va_list ap;
  int i, c;
  int off = 0;
  char *s;

  if (fmt == 0)
    8000689a:	c61d                	beqz	a2,800068c8 <snprintf+0x58>
    8000689c:	8baa                	mv	s7,a0
    8000689e:	89ae                	mv	s3,a1
    800068a0:	8a32                	mv	s4,a2
    panic("null fmt");

  va_start(ap, fmt);
    800068a2:	00840793          	addi	a5,s0,8
    800068a6:	f8f43c23          	sd	a5,-104(s0)
  int off = 0;
    800068aa:	4481                	li	s1,0
  for(i = 0; off < sz && (c = fmt[i] & 0xff) != 0; i++){
    800068ac:	4901                	li	s2,0
    800068ae:	02b05563          	blez	a1,800068d8 <snprintf+0x68>
    if(c != '%'){
    800068b2:	02500a93          	li	s5,37
      continue;
    }
    c = fmt[++i] & 0xff;
    if(c == 0)
      break;
    switch(c){
    800068b6:	07300b13          	li	s6,115
      off += sprintint(buf+off, va_arg(ap, int), 16, 1);
      break;
    case 's':
      if((s = va_arg(ap, char*)) == 0)
        s = "(null)";
      for(; *s && off < sz; s++)
    800068ba:	02800d13          	li	s10,40
    switch(c){
    800068be:	07800c93          	li	s9,120
    800068c2:	06400c13          	li	s8,100
    800068c6:	a01d                	j	800068ec <snprintf+0x7c>
    panic("null fmt");
    800068c8:	00001517          	auipc	a0,0x1
    800068cc:	76050513          	addi	a0,a0,1888 # 80008028 <etext+0x28>
    800068d0:	ffffa097          	auipc	ra,0xffffa
    800068d4:	c7c080e7          	jalr	-900(ra) # 8000054c <panic>
  int off = 0;
    800068d8:	4481                	li	s1,0
    800068da:	a875                	j	80006996 <snprintf+0x126>
  *s = c;
    800068dc:	009b8733          	add	a4,s7,s1
    800068e0:	00f70023          	sb	a5,0(a4)
      off += sputc(buf+off, c);
    800068e4:	2485                	addiw	s1,s1,1
  for(i = 0; off < sz && (c = fmt[i] & 0xff) != 0; i++){
    800068e6:	2905                	addiw	s2,s2,1
    800068e8:	0b34d763          	bge	s1,s3,80006996 <snprintf+0x126>
    800068ec:	012a07b3          	add	a5,s4,s2
    800068f0:	0007c783          	lbu	a5,0(a5)
    800068f4:	0007871b          	sext.w	a4,a5
    800068f8:	cfd9                	beqz	a5,80006996 <snprintf+0x126>
    if(c != '%'){
    800068fa:	ff5711e3          	bne	a4,s5,800068dc <snprintf+0x6c>
    c = fmt[++i] & 0xff;
    800068fe:	2905                	addiw	s2,s2,1
    80006900:	012a07b3          	add	a5,s4,s2
    80006904:	0007c783          	lbu	a5,0(a5)
    if(c == 0)
    80006908:	c7d9                	beqz	a5,80006996 <snprintf+0x126>
    switch(c){
    8000690a:	05678c63          	beq	a5,s6,80006962 <snprintf+0xf2>
    8000690e:	02fb6763          	bltu	s6,a5,8000693c <snprintf+0xcc>
    80006912:	0b578763          	beq	a5,s5,800069c0 <snprintf+0x150>
    80006916:	0b879b63          	bne	a5,s8,800069cc <snprintf+0x15c>
      off += sprintint(buf+off, va_arg(ap, int), 10, 1);
    8000691a:	f9843783          	ld	a5,-104(s0)
    8000691e:	00878713          	addi	a4,a5,8
    80006922:	f8e43c23          	sd	a4,-104(s0)
    80006926:	4685                	li	a3,1
    80006928:	4629                	li	a2,10
    8000692a:	438c                	lw	a1,0(a5)
    8000692c:	009b8533          	add	a0,s7,s1
    80006930:	00000097          	auipc	ra,0x0
    80006934:	ea6080e7          	jalr	-346(ra) # 800067d6 <sprintint>
    80006938:	9ca9                	addw	s1,s1,a0
      break;
    8000693a:	b775                	j	800068e6 <snprintf+0x76>
    switch(c){
    8000693c:	09979863          	bne	a5,s9,800069cc <snprintf+0x15c>
      off += sprintint(buf+off, va_arg(ap, int), 16, 1);
    80006940:	f9843783          	ld	a5,-104(s0)
    80006944:	00878713          	addi	a4,a5,8
    80006948:	f8e43c23          	sd	a4,-104(s0)
    8000694c:	4685                	li	a3,1
    8000694e:	4641                	li	a2,16
    80006950:	438c                	lw	a1,0(a5)
    80006952:	009b8533          	add	a0,s7,s1
    80006956:	00000097          	auipc	ra,0x0
    8000695a:	e80080e7          	jalr	-384(ra) # 800067d6 <sprintint>
    8000695e:	9ca9                	addw	s1,s1,a0
      break;
    80006960:	b759                	j	800068e6 <snprintf+0x76>
      if((s = va_arg(ap, char*)) == 0)
    80006962:	f9843783          	ld	a5,-104(s0)
    80006966:	00878713          	addi	a4,a5,8
    8000696a:	f8e43c23          	sd	a4,-104(s0)
    8000696e:	639c                	ld	a5,0(a5)
    80006970:	c3b1                	beqz	a5,800069b4 <snprintf+0x144>
      for(; *s && off < sz; s++)
    80006972:	0007c703          	lbu	a4,0(a5)
    80006976:	db25                	beqz	a4,800068e6 <snprintf+0x76>
    80006978:	0734d563          	bge	s1,s3,800069e2 <snprintf+0x172>
    8000697c:	009b86b3          	add	a3,s7,s1
  *s = c;
    80006980:	00e68023          	sb	a4,0(a3)
        off += sputc(buf+off, *s);
    80006984:	2485                	addiw	s1,s1,1
      for(; *s && off < sz; s++)
    80006986:	0785                	addi	a5,a5,1
    80006988:	0007c703          	lbu	a4,0(a5)
    8000698c:	df29                	beqz	a4,800068e6 <snprintf+0x76>
    8000698e:	0685                	addi	a3,a3,1
    80006990:	fe9998e3          	bne	s3,s1,80006980 <snprintf+0x110>
  int off = 0;
    80006994:	84ce                	mv	s1,s3
      off += sputc(buf+off, c);
      break;
    }
  }
  return off;
}
    80006996:	8526                	mv	a0,s1
    80006998:	70a6                	ld	ra,104(sp)
    8000699a:	7406                	ld	s0,96(sp)
    8000699c:	64e6                	ld	s1,88(sp)
    8000699e:	6946                	ld	s2,80(sp)
    800069a0:	69a6                	ld	s3,72(sp)
    800069a2:	6a06                	ld	s4,64(sp)
    800069a4:	7ae2                	ld	s5,56(sp)
    800069a6:	7b42                	ld	s6,48(sp)
    800069a8:	7ba2                	ld	s7,40(sp)
    800069aa:	7c02                	ld	s8,32(sp)
    800069ac:	6ce2                	ld	s9,24(sp)
    800069ae:	6d42                	ld	s10,16(sp)
    800069b0:	610d                	addi	sp,sp,160
    800069b2:	8082                	ret
        s = "(null)";
    800069b4:	00001797          	auipc	a5,0x1
    800069b8:	66c78793          	addi	a5,a5,1644 # 80008020 <etext+0x20>
      for(; *s && off < sz; s++)
    800069bc:	876a                	mv	a4,s10
    800069be:	bf6d                	j	80006978 <snprintf+0x108>
  *s = c;
    800069c0:	009b87b3          	add	a5,s7,s1
    800069c4:	01578023          	sb	s5,0(a5)
      off += sputc(buf+off, '%');
    800069c8:	2485                	addiw	s1,s1,1
      break;
    800069ca:	bf31                	j	800068e6 <snprintf+0x76>
  *s = c;
    800069cc:	009b8733          	add	a4,s7,s1
    800069d0:	01570023          	sb	s5,0(a4)
      off += sputc(buf+off, c);
    800069d4:	0014871b          	addiw	a4,s1,1
  *s = c;
    800069d8:	975e                	add	a4,a4,s7
    800069da:	00f70023          	sb	a5,0(a4)
      off += sputc(buf+off, c);
    800069de:	2489                	addiw	s1,s1,2
      break;
    800069e0:	b719                	j	800068e6 <snprintf+0x76>
      for(; *s && off < sz; s++)
    800069e2:	89a6                	mv	s3,s1
    800069e4:	bf45                	j	80006994 <snprintf+0x124>
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
