
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
    80000066:	ebe78793          	addi	a5,a5,-322 # 80005f20 <timervec>
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
    800000b0:	1e278793          	addi	a5,a5,482 # 8000128e <main>
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
    80000116:	bee080e7          	jalr	-1042(ra) # 80000d00 <acquire>
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
    80000130:	6e2080e7          	jalr	1762(ra) # 8000280e <either_copyin>
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
    8000015a:	c7a080e7          	jalr	-902(ra) # 80000dd0 <release>

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
    800001a8:	b5c080e7          	jalr	-1188(ra) # 80000d00 <acquire>
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
    800001d6:	b74080e7          	jalr	-1164(ra) # 80001d46 <myproc>
    800001da:	5d1c                	lw	a5,56(a0)
    800001dc:	e7b5                	bnez	a5,80000248 <consoleread+0xd2>
      sleep(&cons.r, &cons.lock);
    800001de:	85a6                	mv	a1,s1
    800001e0:	854a                	mv	a0,s2
    800001e2:	00002097          	auipc	ra,0x2
    800001e6:	37c080e7          	jalr	892(ra) # 8000255e <sleep>
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
    80000222:	59a080e7          	jalr	1434(ra) # 800027b8 <either_copyout>
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
    8000023e:	b96080e7          	jalr	-1130(ra) # 80000dd0 <release>

  return target - n;
    80000242:	413b053b          	subw	a0,s6,s3
    80000246:	a811                	j	8000025a <consoleread+0xe4>
        release(&cons.lock);
    80000248:	00011517          	auipc	a0,0x11
    8000024c:	f2850513          	addi	a0,a0,-216 # 80011170 <cons>
    80000250:	00001097          	auipc	ra,0x1
    80000254:	b80080e7          	jalr	-1152(ra) # 80000dd0 <release>
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
    800002e4:	a20080e7          	jalr	-1504(ra) # 80000d00 <acquire>

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
    80000302:	566080e7          	jalr	1382(ra) # 80002864 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    80000306:	00011517          	auipc	a0,0x11
    8000030a:	e6a50513          	addi	a0,a0,-406 # 80011170 <cons>
    8000030e:	00001097          	auipc	ra,0x1
    80000312:	ac2080e7          	jalr	-1342(ra) # 80000dd0 <release>
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
    80000456:	28c080e7          	jalr	652(ra) # 800026de <wakeup>
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
    80000478:	a08080e7          	jalr	-1528(ra) # 80000e7c <initlock>

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
    80000612:	6f2080e7          	jalr	1778(ra) # 80000d00 <acquire>
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
    80000770:	664080e7          	jalr	1636(ra) # 80000dd0 <release>
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
    80000796:	6ea080e7          	jalr	1770(ra) # 80000e7c <initlock>
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
    800007ec:	694080e7          	jalr	1684(ra) # 80000e7c <initlock>
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
    80000808:	4b0080e7          	jalr	1200(ra) # 80000cb4 <push_off>

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
    80000836:	53e080e7          	jalr	1342(ra) # 80000d70 <pop_off>
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
    800008b0:	e32080e7          	jalr	-462(ra) # 800026de <wakeup>
    
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
    800008f4:	410080e7          	jalr	1040(ra) # 80000d00 <acquire>
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
    8000094a:	c18080e7          	jalr	-1000(ra) # 8000255e <sleep>
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
    80000990:	444080e7          	jalr	1092(ra) # 80000dd0 <release>
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
    800009f8:	30c080e7          	jalr	780(ra) # 80000d00 <acquire>
  uartstart();
    800009fc:	00000097          	auipc	ra,0x0
    80000a00:	e48080e7          	jalr	-440(ra) # 80000844 <uartstart>
  release(&uart_tx_lock);
    80000a04:	8526                	mv	a0,s1
    80000a06:	00000097          	auipc	ra,0x0
    80000a0a:	3ca080e7          	jalr	970(ra) # 80000dd0 <release>
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
    80000a2a:	84aa                	mv	s1,a0
  struct run *r;
  push_off();
    80000a2c:	00000097          	auipc	ra,0x0
    80000a30:	288080e7          	jalr	648(ra) # 80000cb4 <push_off>
  int id = cpuid();
    80000a34:	00001097          	auipc	ra,0x1
    80000a38:	2e6080e7          	jalr	742(ra) # 80001d1a <cpuid>
    80000a3c:	8a2a                	mv	s4,a0
  pop_off();
    80000a3e:	00000097          	auipc	ra,0x0
    80000a42:	332080e7          	jalr	818(ra) # 80000d70 <pop_off>
  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    80000a46:	03449793          	slli	a5,s1,0x34
    80000a4a:	e7a5                	bnez	a5,80000ab2 <kfree+0x9a>
    80000a4c:	00027797          	auipc	a5,0x27
    80000a50:	5dc78793          	addi	a5,a5,1500 # 80028028 <end>
    80000a54:	04f4ef63          	bltu	s1,a5,80000ab2 <kfree+0x9a>
    80000a58:	47c5                	li	a5,17
    80000a5a:	07ee                	slli	a5,a5,0x1b
    80000a5c:	04f4fb63          	bgeu	s1,a5,80000ab2 <kfree+0x9a>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a60:	6605                	lui	a2,0x1
    80000a62:	4585                	li	a1,1
    80000a64:	8526                	mv	a0,s1
    80000a66:	00000097          	auipc	ra,0x0
    80000a6a:	67a080e7          	jalr	1658(ra) # 800010e0 <memset>

  r = (struct run*)pa;

  acquire(&(kmem[id]).lock);
    80000a6e:	00011a97          	auipc	s5,0x11
    80000a72:	81aa8a93          	addi	s5,s5,-2022 # 80011288 <kmem>
    80000a76:	002a1993          	slli	s3,s4,0x2
    80000a7a:	01498933          	add	s2,s3,s4
    80000a7e:	090e                	slli	s2,s2,0x3
    80000a80:	9956                	add	s2,s2,s5
    80000a82:	854a                	mv	a0,s2
    80000a84:	00000097          	auipc	ra,0x0
    80000a88:	27c080e7          	jalr	636(ra) # 80000d00 <acquire>
  r->next = kmem[id].freelist;
    80000a8c:	02093783          	ld	a5,32(s2)
    80000a90:	e09c                	sd	a5,0(s1)
  kmem[id].freelist = r;
    80000a92:	02993023          	sd	s1,32(s2)
  release(&(kmem[id]).lock);
    80000a96:	854a                	mv	a0,s2
    80000a98:	00000097          	auipc	ra,0x0
    80000a9c:	338080e7          	jalr	824(ra) # 80000dd0 <release>
}
    80000aa0:	70e2                	ld	ra,56(sp)
    80000aa2:	7442                	ld	s0,48(sp)
    80000aa4:	74a2                	ld	s1,40(sp)
    80000aa6:	7902                	ld	s2,32(sp)
    80000aa8:	69e2                	ld	s3,24(sp)
    80000aaa:	6a42                	ld	s4,16(sp)
    80000aac:	6aa2                	ld	s5,8(sp)
    80000aae:	6121                	addi	sp,sp,64
    80000ab0:	8082                	ret
    panic("kfree");
    80000ab2:	00007517          	auipc	a0,0x7
    80000ab6:	5ae50513          	addi	a0,a0,1454 # 80008060 <digits+0x20>
    80000aba:	00000097          	auipc	ra,0x0
    80000abe:	a92080e7          	jalr	-1390(ra) # 8000054c <panic>

0000000080000ac2 <freerange>:
{
    80000ac2:	7179                	addi	sp,sp,-48
    80000ac4:	f406                	sd	ra,40(sp)
    80000ac6:	f022                	sd	s0,32(sp)
    80000ac8:	ec26                	sd	s1,24(sp)
    80000aca:	e84a                	sd	s2,16(sp)
    80000acc:	e44e                	sd	s3,8(sp)
    80000ace:	e052                	sd	s4,0(sp)
    80000ad0:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000ad2:	6785                	lui	a5,0x1
    80000ad4:	fff78713          	addi	a4,a5,-1 # fff <_entry-0x7ffff001>
    80000ad8:	00e504b3          	add	s1,a0,a4
    80000adc:	777d                	lui	a4,0xfffff
    80000ade:	8cf9                	and	s1,s1,a4
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000ae0:	94be                	add	s1,s1,a5
    80000ae2:	0095ee63          	bltu	a1,s1,80000afe <freerange+0x3c>
    80000ae6:	892e                	mv	s2,a1
    kfree(p);
    80000ae8:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000aea:	6985                	lui	s3,0x1
    kfree(p);
    80000aec:	01448533          	add	a0,s1,s4
    80000af0:	00000097          	auipc	ra,0x0
    80000af4:	f28080e7          	jalr	-216(ra) # 80000a18 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000af8:	94ce                	add	s1,s1,s3
    80000afa:	fe9979e3          	bgeu	s2,s1,80000aec <freerange+0x2a>
}
    80000afe:	70a2                	ld	ra,40(sp)
    80000b00:	7402                	ld	s0,32(sp)
    80000b02:	64e2                	ld	s1,24(sp)
    80000b04:	6942                	ld	s2,16(sp)
    80000b06:	69a2                	ld	s3,8(sp)
    80000b08:	6a02                	ld	s4,0(sp)
    80000b0a:	6145                	addi	sp,sp,48
    80000b0c:	8082                	ret

0000000080000b0e <kinit>:
{ 
    80000b0e:	715d                	addi	sp,sp,-80
    80000b10:	e486                	sd	ra,72(sp)
    80000b12:	e0a2                	sd	s0,64(sp)
    80000b14:	fc26                	sd	s1,56(sp)
    80000b16:	f84a                	sd	s2,48(sp)
    80000b18:	f44e                	sd	s3,40(sp)
    80000b1a:	f052                	sd	s4,32(sp)
    80000b1c:	ec56                	sd	s5,24(sp)
    80000b1e:	e85a                	sd	s6,16(sp)
    80000b20:	0880                	addi	s0,sp,80
  for(int id=0;id<NCPU;id++){
    80000b22:	00010917          	auipc	s2,0x10
    80000b26:	76690913          	addi	s2,s2,1894 # 80011288 <kmem>
{ 
    80000b2a:	03000493          	li	s1,48
  char kmemName[5] = "kmem";
    80000b2e:	6d657a37          	lui	s4,0x6d657
    80000b32:	d6ba0a13          	addi	s4,s4,-661 # 6d656d6b <_entry-0x129a9295>
  freerange(end, (void*)PHYSTOP);
    80000b36:	49c5                	li	s3,17
    80000b38:	09ee                	slli	s3,s3,0x1b
    80000b3a:	00027b17          	auipc	s6,0x27
    80000b3e:	4eeb0b13          	addi	s6,s6,1262 # 80028028 <end>
  for(int id=0;id<NCPU;id++){
    80000b42:	03800a93          	li	s5,56
  char kmemName[5] = "kmem";
    80000b46:	fb442c23          	sw	s4,-72(s0)
  kmemName[4] = (char)(id+'0');
    80000b4a:	fa940e23          	sb	s1,-68(s0)
  initlock(&(kmem[id]).lock, kmemName);
    80000b4e:	fb840593          	addi	a1,s0,-72
    80000b52:	854a                	mv	a0,s2
    80000b54:	00000097          	auipc	ra,0x0
    80000b58:	328080e7          	jalr	808(ra) # 80000e7c <initlock>
  freerange(end, (void*)PHYSTOP);
    80000b5c:	85ce                	mv	a1,s3
    80000b5e:	855a                	mv	a0,s6
    80000b60:	00000097          	auipc	ra,0x0
    80000b64:	f62080e7          	jalr	-158(ra) # 80000ac2 <freerange>
  for(int id=0;id<NCPU;id++){
    80000b68:	2485                	addiw	s1,s1,1
    80000b6a:	0ff4f493          	zext.b	s1,s1
    80000b6e:	02890913          	addi	s2,s2,40
    80000b72:	fd549ae3          	bne	s1,s5,80000b46 <kinit+0x38>
}
    80000b76:	60a6                	ld	ra,72(sp)
    80000b78:	6406                	ld	s0,64(sp)
    80000b7a:	74e2                	ld	s1,56(sp)
    80000b7c:	7942                	ld	s2,48(sp)
    80000b7e:	79a2                	ld	s3,40(sp)
    80000b80:	7a02                	ld	s4,32(sp)
    80000b82:	6ae2                	ld	s5,24(sp)
    80000b84:	6b42                	ld	s6,16(sp)
    80000b86:	6161                	addi	sp,sp,80
    80000b88:	8082                	ret

0000000080000b8a <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000b8a:	715d                	addi	sp,sp,-80
    80000b8c:	e486                	sd	ra,72(sp)
    80000b8e:	e0a2                	sd	s0,64(sp)
    80000b90:	fc26                	sd	s1,56(sp)
    80000b92:	f84a                	sd	s2,48(sp)
    80000b94:	f44e                	sd	s3,40(sp)
    80000b96:	f052                	sd	s4,32(sp)
    80000b98:	ec56                	sd	s5,24(sp)
    80000b9a:	e85a                	sd	s6,16(sp)
    80000b9c:	e45e                	sd	s7,8(sp)
    80000b9e:	e062                	sd	s8,0(sp)
    80000ba0:	0880                	addi	s0,sp,80
  struct run *r;
  push_off();
    80000ba2:	00000097          	auipc	ra,0x0
    80000ba6:	112080e7          	jalr	274(ra) # 80000cb4 <push_off>
  int id = cpuid();
    80000baa:	00001097          	auipc	ra,0x1
    80000bae:	170080e7          	jalr	368(ra) # 80001d1a <cpuid>
    80000bb2:	892a                	mv	s2,a0
  pop_off();
    80000bb4:	00000097          	auipc	ra,0x0
    80000bb8:	1bc080e7          	jalr	444(ra) # 80000d70 <pop_off>
  acquire(&(kmem[id]).lock);
    80000bbc:	00291793          	slli	a5,s2,0x2
    80000bc0:	97ca                	add	a5,a5,s2
    80000bc2:	078e                	slli	a5,a5,0x3
    80000bc4:	00010a17          	auipc	s4,0x10
    80000bc8:	6c4a0a13          	addi	s4,s4,1732 # 80011288 <kmem>
    80000bcc:	9a3e                	add	s4,s4,a5
    80000bce:	8552                	mv	a0,s4
    80000bd0:	00000097          	auipc	ra,0x0
    80000bd4:	130080e7          	jalr	304(ra) # 80000d00 <acquire>
  r = kmem[id].freelist;
    80000bd8:	020a3a83          	ld	s5,32(s4)
  if(r)
    80000bdc:	020a8f63          	beqz	s5,80000c1a <kalloc+0x90>
    kmem[id].freelist = r->next;
    80000be0:	000ab683          	ld	a3,0(s5)
    80000be4:	02da3023          	sd	a3,32(s4)
        release(&(kmem[idx]).lock);
        break;
      }
      release(&(kmem[idx]).lock);
    }
  release(&(kmem[id]).lock);
    80000be8:	8552                	mv	a0,s4
    80000bea:	00000097          	auipc	ra,0x0
    80000bee:	1e6080e7          	jalr	486(ra) # 80000dd0 <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000bf2:	6605                	lui	a2,0x1
    80000bf4:	4595                	li	a1,5
    80000bf6:	8556                	mv	a0,s5
    80000bf8:	00000097          	auipc	ra,0x0
    80000bfc:	4e8080e7          	jalr	1256(ra) # 800010e0 <memset>
  return (void*)r;
}
    80000c00:	8556                	mv	a0,s5
    80000c02:	60a6                	ld	ra,72(sp)
    80000c04:	6406                	ld	s0,64(sp)
    80000c06:	74e2                	ld	s1,56(sp)
    80000c08:	7942                	ld	s2,48(sp)
    80000c0a:	79a2                	ld	s3,40(sp)
    80000c0c:	7a02                	ld	s4,32(sp)
    80000c0e:	6ae2                	ld	s5,24(sp)
    80000c10:	6b42                	ld	s6,16(sp)
    80000c12:	6ba2                	ld	s7,8(sp)
    80000c14:	6c02                	ld	s8,0(sp)
    80000c16:	6161                	addi	sp,sp,80
    80000c18:	8082                	ret
    80000c1a:	00010497          	auipc	s1,0x10
    80000c1e:	66e48493          	addi	s1,s1,1646 # 80011288 <kmem>
    for(int idx=0;idx<NCPU;idx++){
    80000c22:	4981                	li	s3,0
    80000c24:	4ba1                	li	s7,8
    80000c26:	a80d                	j	80000c58 <kalloc+0xce>
        kmem[id].freelist=r->next;
    80000c28:	000b3683          	ld	a3,0(s6)
    80000c2c:	00291793          	slli	a5,s2,0x2
    80000c30:	97ca                	add	a5,a5,s2
    80000c32:	078e                	slli	a5,a5,0x3
    80000c34:	00010717          	auipc	a4,0x10
    80000c38:	65470713          	addi	a4,a4,1620 # 80011288 <kmem>
    80000c3c:	97ba                	add	a5,a5,a4
    80000c3e:	f394                	sd	a3,32(a5)
        release(&(kmem[idx]).lock);
    80000c40:	8526                	mv	a0,s1
    80000c42:	00000097          	auipc	ra,0x0
    80000c46:	18e080e7          	jalr	398(ra) # 80000dd0 <release>
      if(kmem[idx].freelist){
    80000c4a:	8ada                	mv	s5,s6
        break;
    80000c4c:	bf71                	j	80000be8 <kalloc+0x5e>
    for(int idx=0;idx<NCPU;idx++){
    80000c4e:	2985                	addiw	s3,s3,1 # 1001 <_entry-0x7fffefff>
    80000c50:	02848493          	addi	s1,s1,40
    80000c54:	03798363          	beq	s3,s7,80000c7a <kalloc+0xf0>
      if(idx==id) continue;
    80000c58:	ff390be3          	beq	s2,s3,80000c4e <kalloc+0xc4>
      acquire(&(kmem[idx]).lock);
    80000c5c:	8526                	mv	a0,s1
    80000c5e:	00000097          	auipc	ra,0x0
    80000c62:	0a2080e7          	jalr	162(ra) # 80000d00 <acquire>
      if(kmem[idx].freelist){
    80000c66:	0204bb03          	ld	s6,32(s1)
    80000c6a:	fa0b1fe3          	bnez	s6,80000c28 <kalloc+0x9e>
      release(&(kmem[idx]).lock);
    80000c6e:	8526                	mv	a0,s1
    80000c70:	00000097          	auipc	ra,0x0
    80000c74:	160080e7          	jalr	352(ra) # 80000dd0 <release>
    80000c78:	bfd9                	j	80000c4e <kalloc+0xc4>
  release(&(kmem[id]).lock);
    80000c7a:	8552                	mv	a0,s4
    80000c7c:	00000097          	auipc	ra,0x0
    80000c80:	154080e7          	jalr	340(ra) # 80000dd0 <release>
  if(r)
    80000c84:	bfb5                	j	80000c00 <kalloc+0x76>

0000000080000c86 <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000c86:	411c                	lw	a5,0(a0)
    80000c88:	e399                	bnez	a5,80000c8e <holding+0x8>
    80000c8a:	4501                	li	a0,0
  return r;
}
    80000c8c:	8082                	ret
{
    80000c8e:	1101                	addi	sp,sp,-32
    80000c90:	ec06                	sd	ra,24(sp)
    80000c92:	e822                	sd	s0,16(sp)
    80000c94:	e426                	sd	s1,8(sp)
    80000c96:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000c98:	6904                	ld	s1,16(a0)
    80000c9a:	00001097          	auipc	ra,0x1
    80000c9e:	090080e7          	jalr	144(ra) # 80001d2a <mycpu>
    80000ca2:	40a48533          	sub	a0,s1,a0
    80000ca6:	00153513          	seqz	a0,a0
}
    80000caa:	60e2                	ld	ra,24(sp)
    80000cac:	6442                	ld	s0,16(sp)
    80000cae:	64a2                	ld	s1,8(sp)
    80000cb0:	6105                	addi	sp,sp,32
    80000cb2:	8082                	ret

0000000080000cb4 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000cb4:	1101                	addi	sp,sp,-32
    80000cb6:	ec06                	sd	ra,24(sp)
    80000cb8:	e822                	sd	s0,16(sp)
    80000cba:	e426                	sd	s1,8(sp)
    80000cbc:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000cbe:	100024f3          	csrr	s1,sstatus
    80000cc2:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000cc6:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000cc8:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000ccc:	00001097          	auipc	ra,0x1
    80000cd0:	05e080e7          	jalr	94(ra) # 80001d2a <mycpu>
    80000cd4:	5d3c                	lw	a5,120(a0)
    80000cd6:	cf89                	beqz	a5,80000cf0 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000cd8:	00001097          	auipc	ra,0x1
    80000cdc:	052080e7          	jalr	82(ra) # 80001d2a <mycpu>
    80000ce0:	5d3c                	lw	a5,120(a0)
    80000ce2:	2785                	addiw	a5,a5,1
    80000ce4:	dd3c                	sw	a5,120(a0)
}
    80000ce6:	60e2                	ld	ra,24(sp)
    80000ce8:	6442                	ld	s0,16(sp)
    80000cea:	64a2                	ld	s1,8(sp)
    80000cec:	6105                	addi	sp,sp,32
    80000cee:	8082                	ret
    mycpu()->intena = old;
    80000cf0:	00001097          	auipc	ra,0x1
    80000cf4:	03a080e7          	jalr	58(ra) # 80001d2a <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000cf8:	8085                	srli	s1,s1,0x1
    80000cfa:	8885                	andi	s1,s1,1
    80000cfc:	dd64                	sw	s1,124(a0)
    80000cfe:	bfe9                	j	80000cd8 <push_off+0x24>

0000000080000d00 <acquire>:
{
    80000d00:	1101                	addi	sp,sp,-32
    80000d02:	ec06                	sd	ra,24(sp)
    80000d04:	e822                	sd	s0,16(sp)
    80000d06:	e426                	sd	s1,8(sp)
    80000d08:	1000                	addi	s0,sp,32
    80000d0a:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000d0c:	00000097          	auipc	ra,0x0
    80000d10:	fa8080e7          	jalr	-88(ra) # 80000cb4 <push_off>
  if(holding(lk))
    80000d14:	8526                	mv	a0,s1
    80000d16:	00000097          	auipc	ra,0x0
    80000d1a:	f70080e7          	jalr	-144(ra) # 80000c86 <holding>
    80000d1e:	e911                	bnez	a0,80000d32 <acquire+0x32>
    __sync_fetch_and_add(&(lk->n), 1);
    80000d20:	4785                	li	a5,1
    80000d22:	01c48713          	addi	a4,s1,28
    80000d26:	0f50000f          	fence	iorw,ow
    80000d2a:	04f7202f          	amoadd.w.aq	zero,a5,(a4)
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0) {
    80000d2e:	4705                	li	a4,1
    80000d30:	a839                	j	80000d4e <acquire+0x4e>
    panic("acquire");
    80000d32:	00007517          	auipc	a0,0x7
    80000d36:	33650513          	addi	a0,a0,822 # 80008068 <digits+0x28>
    80000d3a:	00000097          	auipc	ra,0x0
    80000d3e:	812080e7          	jalr	-2030(ra) # 8000054c <panic>
    __sync_fetch_and_add(&(lk->nts), 1);
    80000d42:	01848793          	addi	a5,s1,24
    80000d46:	0f50000f          	fence	iorw,ow
    80000d4a:	04e7a02f          	amoadd.w.aq	zero,a4,(a5)
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0) {
    80000d4e:	87ba                	mv	a5,a4
    80000d50:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000d54:	2781                	sext.w	a5,a5
    80000d56:	f7f5                	bnez	a5,80000d42 <acquire+0x42>
  __sync_synchronize();
    80000d58:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000d5c:	00001097          	auipc	ra,0x1
    80000d60:	fce080e7          	jalr	-50(ra) # 80001d2a <mycpu>
    80000d64:	e888                	sd	a0,16(s1)
}
    80000d66:	60e2                	ld	ra,24(sp)
    80000d68:	6442                	ld	s0,16(sp)
    80000d6a:	64a2                	ld	s1,8(sp)
    80000d6c:	6105                	addi	sp,sp,32
    80000d6e:	8082                	ret

0000000080000d70 <pop_off>:

void
pop_off(void)
{
    80000d70:	1141                	addi	sp,sp,-16
    80000d72:	e406                	sd	ra,8(sp)
    80000d74:	e022                	sd	s0,0(sp)
    80000d76:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000d78:	00001097          	auipc	ra,0x1
    80000d7c:	fb2080e7          	jalr	-78(ra) # 80001d2a <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000d80:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000d84:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000d86:	e78d                	bnez	a5,80000db0 <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000d88:	5d3c                	lw	a5,120(a0)
    80000d8a:	02f05b63          	blez	a5,80000dc0 <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000d8e:	37fd                	addiw	a5,a5,-1
    80000d90:	0007871b          	sext.w	a4,a5
    80000d94:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000d96:	eb09                	bnez	a4,80000da8 <pop_off+0x38>
    80000d98:	5d7c                	lw	a5,124(a0)
    80000d9a:	c799                	beqz	a5,80000da8 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000d9c:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000da0:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000da4:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000da8:	60a2                	ld	ra,8(sp)
    80000daa:	6402                	ld	s0,0(sp)
    80000dac:	0141                	addi	sp,sp,16
    80000dae:	8082                	ret
    panic("pop_off - interruptible");
    80000db0:	00007517          	auipc	a0,0x7
    80000db4:	2c050513          	addi	a0,a0,704 # 80008070 <digits+0x30>
    80000db8:	fffff097          	auipc	ra,0xfffff
    80000dbc:	794080e7          	jalr	1940(ra) # 8000054c <panic>
    panic("pop_off");
    80000dc0:	00007517          	auipc	a0,0x7
    80000dc4:	2c850513          	addi	a0,a0,712 # 80008088 <digits+0x48>
    80000dc8:	fffff097          	auipc	ra,0xfffff
    80000dcc:	784080e7          	jalr	1924(ra) # 8000054c <panic>

0000000080000dd0 <release>:
{
    80000dd0:	1101                	addi	sp,sp,-32
    80000dd2:	ec06                	sd	ra,24(sp)
    80000dd4:	e822                	sd	s0,16(sp)
    80000dd6:	e426                	sd	s1,8(sp)
    80000dd8:	1000                	addi	s0,sp,32
    80000dda:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000ddc:	00000097          	auipc	ra,0x0
    80000de0:	eaa080e7          	jalr	-342(ra) # 80000c86 <holding>
    80000de4:	c115                	beqz	a0,80000e08 <release+0x38>
  lk->cpu = 0;
    80000de6:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000dea:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000dee:	0f50000f          	fence	iorw,ow
    80000df2:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000df6:	00000097          	auipc	ra,0x0
    80000dfa:	f7a080e7          	jalr	-134(ra) # 80000d70 <pop_off>
}
    80000dfe:	60e2                	ld	ra,24(sp)
    80000e00:	6442                	ld	s0,16(sp)
    80000e02:	64a2                	ld	s1,8(sp)
    80000e04:	6105                	addi	sp,sp,32
    80000e06:	8082                	ret
    panic("release");
    80000e08:	00007517          	auipc	a0,0x7
    80000e0c:	28850513          	addi	a0,a0,648 # 80008090 <digits+0x50>
    80000e10:	fffff097          	auipc	ra,0xfffff
    80000e14:	73c080e7          	jalr	1852(ra) # 8000054c <panic>

0000000080000e18 <freelock>:
{
    80000e18:	1101                	addi	sp,sp,-32
    80000e1a:	ec06                	sd	ra,24(sp)
    80000e1c:	e822                	sd	s0,16(sp)
    80000e1e:	e426                	sd	s1,8(sp)
    80000e20:	1000                	addi	s0,sp,32
    80000e22:	84aa                	mv	s1,a0
  acquire(&lock_locks);
    80000e24:	00010517          	auipc	a0,0x10
    80000e28:	5a450513          	addi	a0,a0,1444 # 800113c8 <lock_locks>
    80000e2c:	00000097          	auipc	ra,0x0
    80000e30:	ed4080e7          	jalr	-300(ra) # 80000d00 <acquire>
  for (i = 0; i < NLOCK; i++) {
    80000e34:	00010717          	auipc	a4,0x10
    80000e38:	5b470713          	addi	a4,a4,1460 # 800113e8 <locks>
    80000e3c:	4781                	li	a5,0
    80000e3e:	1f400613          	li	a2,500
    if(locks[i] == lk) {
    80000e42:	6314                	ld	a3,0(a4)
    80000e44:	00968763          	beq	a3,s1,80000e52 <freelock+0x3a>
  for (i = 0; i < NLOCK; i++) {
    80000e48:	2785                	addiw	a5,a5,1
    80000e4a:	0721                	addi	a4,a4,8
    80000e4c:	fec79be3          	bne	a5,a2,80000e42 <freelock+0x2a>
    80000e50:	a809                	j	80000e62 <freelock+0x4a>
      locks[i] = 0;
    80000e52:	078e                	slli	a5,a5,0x3
    80000e54:	00010717          	auipc	a4,0x10
    80000e58:	59470713          	addi	a4,a4,1428 # 800113e8 <locks>
    80000e5c:	97ba                	add	a5,a5,a4
    80000e5e:	0007b023          	sd	zero,0(a5)
  release(&lock_locks);
    80000e62:	00010517          	auipc	a0,0x10
    80000e66:	56650513          	addi	a0,a0,1382 # 800113c8 <lock_locks>
    80000e6a:	00000097          	auipc	ra,0x0
    80000e6e:	f66080e7          	jalr	-154(ra) # 80000dd0 <release>
}
    80000e72:	60e2                	ld	ra,24(sp)
    80000e74:	6442                	ld	s0,16(sp)
    80000e76:	64a2                	ld	s1,8(sp)
    80000e78:	6105                	addi	sp,sp,32
    80000e7a:	8082                	ret

0000000080000e7c <initlock>:
{
    80000e7c:	1101                	addi	sp,sp,-32
    80000e7e:	ec06                	sd	ra,24(sp)
    80000e80:	e822                	sd	s0,16(sp)
    80000e82:	e426                	sd	s1,8(sp)
    80000e84:	1000                	addi	s0,sp,32
    80000e86:	84aa                	mv	s1,a0
  lk->name = name;
    80000e88:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000e8a:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000e8e:	00053823          	sd	zero,16(a0)
  lk->nts = 0;
    80000e92:	00052c23          	sw	zero,24(a0)
  lk->n = 0;
    80000e96:	00052e23          	sw	zero,28(a0)
  acquire(&lock_locks);
    80000e9a:	00010517          	auipc	a0,0x10
    80000e9e:	52e50513          	addi	a0,a0,1326 # 800113c8 <lock_locks>
    80000ea2:	00000097          	auipc	ra,0x0
    80000ea6:	e5e080e7          	jalr	-418(ra) # 80000d00 <acquire>
  for (i = 0; i < NLOCK; i++) {
    80000eaa:	00010717          	auipc	a4,0x10
    80000eae:	53e70713          	addi	a4,a4,1342 # 800113e8 <locks>
    80000eb2:	4781                	li	a5,0
    80000eb4:	1f400613          	li	a2,500
    if(locks[i] == 0) {
    80000eb8:	6314                	ld	a3,0(a4)
    80000eba:	ce89                	beqz	a3,80000ed4 <initlock+0x58>
  for (i = 0; i < NLOCK; i++) {
    80000ebc:	2785                	addiw	a5,a5,1
    80000ebe:	0721                	addi	a4,a4,8
    80000ec0:	fec79ce3          	bne	a5,a2,80000eb8 <initlock+0x3c>
  panic("findslot");
    80000ec4:	00007517          	auipc	a0,0x7
    80000ec8:	1d450513          	addi	a0,a0,468 # 80008098 <digits+0x58>
    80000ecc:	fffff097          	auipc	ra,0xfffff
    80000ed0:	680080e7          	jalr	1664(ra) # 8000054c <panic>
      locks[i] = lk;
    80000ed4:	078e                	slli	a5,a5,0x3
    80000ed6:	00010717          	auipc	a4,0x10
    80000eda:	51270713          	addi	a4,a4,1298 # 800113e8 <locks>
    80000ede:	97ba                	add	a5,a5,a4
    80000ee0:	e384                	sd	s1,0(a5)
      release(&lock_locks);
    80000ee2:	00010517          	auipc	a0,0x10
    80000ee6:	4e650513          	addi	a0,a0,1254 # 800113c8 <lock_locks>
    80000eea:	00000097          	auipc	ra,0x0
    80000eee:	ee6080e7          	jalr	-282(ra) # 80000dd0 <release>
}
    80000ef2:	60e2                	ld	ra,24(sp)
    80000ef4:	6442                	ld	s0,16(sp)
    80000ef6:	64a2                	ld	s1,8(sp)
    80000ef8:	6105                	addi	sp,sp,32
    80000efa:	8082                	ret

0000000080000efc <snprint_lock>:
#ifdef LAB_LOCK
int
snprint_lock(char *buf, int sz, struct spinlock *lk)
{
  int n = 0;
  if(lk->n > 0) {
    80000efc:	4e5c                	lw	a5,28(a2)
    80000efe:	00f04463          	bgtz	a5,80000f06 <snprint_lock+0xa>
  int n = 0;
    80000f02:	4501                	li	a0,0
    n = snprintf(buf, sz, "lock: %s: #fetch-and-add %d #acquire() %d\n",
                 lk->name, lk->nts, lk->n);
  }
  return n;
}
    80000f04:	8082                	ret
{
    80000f06:	1141                	addi	sp,sp,-16
    80000f08:	e406                	sd	ra,8(sp)
    80000f0a:	e022                	sd	s0,0(sp)
    80000f0c:	0800                	addi	s0,sp,16
    n = snprintf(buf, sz, "lock: %s: #fetch-and-add %d #acquire() %d\n",
    80000f0e:	4e18                	lw	a4,24(a2)
    80000f10:	6614                	ld	a3,8(a2)
    80000f12:	00007617          	auipc	a2,0x7
    80000f16:	19660613          	addi	a2,a2,406 # 800080a8 <digits+0x68>
    80000f1a:	00005097          	auipc	ra,0x5
    80000f1e:	7b6080e7          	jalr	1974(ra) # 800066d0 <snprintf>
}
    80000f22:	60a2                	ld	ra,8(sp)
    80000f24:	6402                	ld	s0,0(sp)
    80000f26:	0141                	addi	sp,sp,16
    80000f28:	8082                	ret

0000000080000f2a <statslock>:

int
statslock(char *buf, int sz) {
    80000f2a:	7159                	addi	sp,sp,-112
    80000f2c:	f486                	sd	ra,104(sp)
    80000f2e:	f0a2                	sd	s0,96(sp)
    80000f30:	eca6                	sd	s1,88(sp)
    80000f32:	e8ca                	sd	s2,80(sp)
    80000f34:	e4ce                	sd	s3,72(sp)
    80000f36:	e0d2                	sd	s4,64(sp)
    80000f38:	fc56                	sd	s5,56(sp)
    80000f3a:	f85a                	sd	s6,48(sp)
    80000f3c:	f45e                	sd	s7,40(sp)
    80000f3e:	f062                	sd	s8,32(sp)
    80000f40:	ec66                	sd	s9,24(sp)
    80000f42:	e86a                	sd	s10,16(sp)
    80000f44:	e46e                	sd	s11,8(sp)
    80000f46:	1880                	addi	s0,sp,112
    80000f48:	8aaa                	mv	s5,a0
    80000f4a:	8b2e                	mv	s6,a1
  int n;
  int tot = 0;

  acquire(&lock_locks);
    80000f4c:	00010517          	auipc	a0,0x10
    80000f50:	47c50513          	addi	a0,a0,1148 # 800113c8 <lock_locks>
    80000f54:	00000097          	auipc	ra,0x0
    80000f58:	dac080e7          	jalr	-596(ra) # 80000d00 <acquire>
  n = snprintf(buf, sz, "--- lock kmem/bcache stats\n");
    80000f5c:	00007617          	auipc	a2,0x7
    80000f60:	17c60613          	addi	a2,a2,380 # 800080d8 <digits+0x98>
    80000f64:	85da                	mv	a1,s6
    80000f66:	8556                	mv	a0,s5
    80000f68:	00005097          	auipc	ra,0x5
    80000f6c:	768080e7          	jalr	1896(ra) # 800066d0 <snprintf>
    80000f70:	892a                	mv	s2,a0
  for(int i = 0; i < NLOCK; i++) {
    80000f72:	00010c97          	auipc	s9,0x10
    80000f76:	476c8c93          	addi	s9,s9,1142 # 800113e8 <locks>
    80000f7a:	00011c17          	auipc	s8,0x11
    80000f7e:	40ec0c13          	addi	s8,s8,1038 # 80012388 <pid_lock>
  n = snprintf(buf, sz, "--- lock kmem/bcache stats\n");
    80000f82:	84e6                	mv	s1,s9
  int tot = 0;
    80000f84:	4a01                	li	s4,0
    if(locks[i] == 0)
      break;
    if(strncmp(locks[i]->name, "bcache", strlen("bcache")) == 0 ||
    80000f86:	00007b97          	auipc	s7,0x7
    80000f8a:	172b8b93          	addi	s7,s7,370 # 800080f8 <digits+0xb8>
       strncmp(locks[i]->name, "kmem", strlen("kmem")) == 0) {
    80000f8e:	00007d17          	auipc	s10,0x7
    80000f92:	172d0d13          	addi	s10,s10,370 # 80008100 <digits+0xc0>
    80000f96:	a01d                	j	80000fbc <statslock+0x92>
      tot += locks[i]->nts;
    80000f98:	0009b603          	ld	a2,0(s3)
    80000f9c:	4e1c                	lw	a5,24(a2)
    80000f9e:	01478a3b          	addw	s4,a5,s4
      n += snprint_lock(buf +n, sz-n, locks[i]);
    80000fa2:	412b05bb          	subw	a1,s6,s2
    80000fa6:	012a8533          	add	a0,s5,s2
    80000faa:	00000097          	auipc	ra,0x0
    80000fae:	f52080e7          	jalr	-174(ra) # 80000efc <snprint_lock>
    80000fb2:	0125093b          	addw	s2,a0,s2
  for(int i = 0; i < NLOCK; i++) {
    80000fb6:	04a1                	addi	s1,s1,8
    80000fb8:	05848763          	beq	s1,s8,80001006 <statslock+0xdc>
    if(locks[i] == 0)
    80000fbc:	89a6                	mv	s3,s1
    80000fbe:	609c                	ld	a5,0(s1)
    80000fc0:	c3b9                	beqz	a5,80001006 <statslock+0xdc>
    if(strncmp(locks[i]->name, "bcache", strlen("bcache")) == 0 ||
    80000fc2:	0087bd83          	ld	s11,8(a5)
    80000fc6:	855e                	mv	a0,s7
    80000fc8:	00000097          	auipc	ra,0x0
    80000fcc:	29c080e7          	jalr	668(ra) # 80001264 <strlen>
    80000fd0:	0005061b          	sext.w	a2,a0
    80000fd4:	85de                	mv	a1,s7
    80000fd6:	856e                	mv	a0,s11
    80000fd8:	00000097          	auipc	ra,0x0
    80000fdc:	1e0080e7          	jalr	480(ra) # 800011b8 <strncmp>
    80000fe0:	dd45                	beqz	a0,80000f98 <statslock+0x6e>
       strncmp(locks[i]->name, "kmem", strlen("kmem")) == 0) {
    80000fe2:	609c                	ld	a5,0(s1)
    80000fe4:	0087bd83          	ld	s11,8(a5)
    80000fe8:	856a                	mv	a0,s10
    80000fea:	00000097          	auipc	ra,0x0
    80000fee:	27a080e7          	jalr	634(ra) # 80001264 <strlen>
    80000ff2:	0005061b          	sext.w	a2,a0
    80000ff6:	85ea                	mv	a1,s10
    80000ff8:	856e                	mv	a0,s11
    80000ffa:	00000097          	auipc	ra,0x0
    80000ffe:	1be080e7          	jalr	446(ra) # 800011b8 <strncmp>
    if(strncmp(locks[i]->name, "bcache", strlen("bcache")) == 0 ||
    80001002:	f955                	bnez	a0,80000fb6 <statslock+0x8c>
    80001004:	bf51                	j	80000f98 <statslock+0x6e>
    }
  }
  
  n += snprintf(buf+n, sz-n, "--- top 5 contended locks:\n");
    80001006:	00007617          	auipc	a2,0x7
    8000100a:	10260613          	addi	a2,a2,258 # 80008108 <digits+0xc8>
    8000100e:	412b05bb          	subw	a1,s6,s2
    80001012:	012a8533          	add	a0,s5,s2
    80001016:	00005097          	auipc	ra,0x5
    8000101a:	6ba080e7          	jalr	1722(ra) # 800066d0 <snprintf>
    8000101e:	012509bb          	addw	s3,a0,s2
    80001022:	4b95                	li	s7,5
  int last = 100000000;
    80001024:	05f5e537          	lui	a0,0x5f5e
    80001028:	10050513          	addi	a0,a0,256 # 5f5e100 <_entry-0x7a0a1f00>
  // stupid way to compute top 5 contended locks
  for(int t = 0; t < 5; t++) {
    int top = 0;
    for(int i = 0; i < NLOCK; i++) {
    8000102c:	4c01                	li	s8,0
      if(locks[i] == 0)
        break;
      if(locks[i]->nts > locks[top]->nts && locks[i]->nts < last) {
    8000102e:	00010497          	auipc	s1,0x10
    80001032:	3ba48493          	addi	s1,s1,954 # 800113e8 <locks>
    for(int i = 0; i < NLOCK; i++) {
    80001036:	1f400913          	li	s2,500
    8000103a:	a881                	j	8000108a <statslock+0x160>
    8000103c:	2705                	addiw	a4,a4,1
    8000103e:	06a1                	addi	a3,a3,8
    80001040:	03270063          	beq	a4,s2,80001060 <statslock+0x136>
      if(locks[i] == 0)
    80001044:	629c                	ld	a5,0(a3)
    80001046:	cf89                	beqz	a5,80001060 <statslock+0x136>
      if(locks[i]->nts > locks[top]->nts && locks[i]->nts < last) {
    80001048:	4f90                	lw	a2,24(a5)
    8000104a:	00359793          	slli	a5,a1,0x3
    8000104e:	97a6                	add	a5,a5,s1
    80001050:	639c                	ld	a5,0(a5)
    80001052:	4f9c                	lw	a5,24(a5)
    80001054:	fec7d4e3          	bge	a5,a2,8000103c <statslock+0x112>
    80001058:	fea652e3          	bge	a2,a0,8000103c <statslock+0x112>
    8000105c:	85ba                	mv	a1,a4
    8000105e:	bff9                	j	8000103c <statslock+0x112>
        top = i;
      }
    }
    n += snprint_lock(buf+n, sz-n, locks[top]);
    80001060:	058e                	slli	a1,a1,0x3
    80001062:	00b48d33          	add	s10,s1,a1
    80001066:	000d3603          	ld	a2,0(s10)
    8000106a:	413b05bb          	subw	a1,s6,s3
    8000106e:	013a8533          	add	a0,s5,s3
    80001072:	00000097          	auipc	ra,0x0
    80001076:	e8a080e7          	jalr	-374(ra) # 80000efc <snprint_lock>
    8000107a:	013509bb          	addw	s3,a0,s3
    last = locks[top]->nts;
    8000107e:	000d3783          	ld	a5,0(s10)
    80001082:	4f88                	lw	a0,24(a5)
  for(int t = 0; t < 5; t++) {
    80001084:	3bfd                	addiw	s7,s7,-1
    80001086:	000b8663          	beqz	s7,80001092 <statslock+0x168>
  int tot = 0;
    8000108a:	86e6                	mv	a3,s9
    for(int i = 0; i < NLOCK; i++) {
    8000108c:	8762                	mv	a4,s8
    int top = 0;
    8000108e:	85e2                	mv	a1,s8
    80001090:	bf55                	j	80001044 <statslock+0x11a>
  }
  n += snprintf(buf+n, sz-n, "tot= %d\n", tot);
    80001092:	86d2                	mv	a3,s4
    80001094:	00007617          	auipc	a2,0x7
    80001098:	09460613          	addi	a2,a2,148 # 80008128 <digits+0xe8>
    8000109c:	413b05bb          	subw	a1,s6,s3
    800010a0:	013a8533          	add	a0,s5,s3
    800010a4:	00005097          	auipc	ra,0x5
    800010a8:	62c080e7          	jalr	1580(ra) # 800066d0 <snprintf>
    800010ac:	013509bb          	addw	s3,a0,s3
  release(&lock_locks);  
    800010b0:	00010517          	auipc	a0,0x10
    800010b4:	31850513          	addi	a0,a0,792 # 800113c8 <lock_locks>
    800010b8:	00000097          	auipc	ra,0x0
    800010bc:	d18080e7          	jalr	-744(ra) # 80000dd0 <release>
  return n;
}
    800010c0:	854e                	mv	a0,s3
    800010c2:	70a6                	ld	ra,104(sp)
    800010c4:	7406                	ld	s0,96(sp)
    800010c6:	64e6                	ld	s1,88(sp)
    800010c8:	6946                	ld	s2,80(sp)
    800010ca:	69a6                	ld	s3,72(sp)
    800010cc:	6a06                	ld	s4,64(sp)
    800010ce:	7ae2                	ld	s5,56(sp)
    800010d0:	7b42                	ld	s6,48(sp)
    800010d2:	7ba2                	ld	s7,40(sp)
    800010d4:	7c02                	ld	s8,32(sp)
    800010d6:	6ce2                	ld	s9,24(sp)
    800010d8:	6d42                	ld	s10,16(sp)
    800010da:	6da2                	ld	s11,8(sp)
    800010dc:	6165                	addi	sp,sp,112
    800010de:	8082                	ret

00000000800010e0 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    800010e0:	1141                	addi	sp,sp,-16
    800010e2:	e422                	sd	s0,8(sp)
    800010e4:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    800010e6:	ca19                	beqz	a2,800010fc <memset+0x1c>
    800010e8:	87aa                	mv	a5,a0
    800010ea:	1602                	slli	a2,a2,0x20
    800010ec:	9201                	srli	a2,a2,0x20
    800010ee:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    800010f2:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    800010f6:	0785                	addi	a5,a5,1
    800010f8:	fee79de3          	bne	a5,a4,800010f2 <memset+0x12>
  }
  return dst;
}
    800010fc:	6422                	ld	s0,8(sp)
    800010fe:	0141                	addi	sp,sp,16
    80001100:	8082                	ret

0000000080001102 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80001102:	1141                	addi	sp,sp,-16
    80001104:	e422                	sd	s0,8(sp)
    80001106:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80001108:	ca05                	beqz	a2,80001138 <memcmp+0x36>
    8000110a:	fff6069b          	addiw	a3,a2,-1
    8000110e:	1682                	slli	a3,a3,0x20
    80001110:	9281                	srli	a3,a3,0x20
    80001112:	0685                	addi	a3,a3,1
    80001114:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80001116:	00054783          	lbu	a5,0(a0)
    8000111a:	0005c703          	lbu	a4,0(a1)
    8000111e:	00e79863          	bne	a5,a4,8000112e <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80001122:	0505                	addi	a0,a0,1
    80001124:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80001126:	fed518e3          	bne	a0,a3,80001116 <memcmp+0x14>
  }

  return 0;
    8000112a:	4501                	li	a0,0
    8000112c:	a019                	j	80001132 <memcmp+0x30>
      return *s1 - *s2;
    8000112e:	40e7853b          	subw	a0,a5,a4
}
    80001132:	6422                	ld	s0,8(sp)
    80001134:	0141                	addi	sp,sp,16
    80001136:	8082                	ret
  return 0;
    80001138:	4501                	li	a0,0
    8000113a:	bfe5                	j	80001132 <memcmp+0x30>

000000008000113c <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    8000113c:	1141                	addi	sp,sp,-16
    8000113e:	e422                	sd	s0,8(sp)
    80001140:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
    80001142:	02a5e563          	bltu	a1,a0,8000116c <memmove+0x30>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80001146:	fff6069b          	addiw	a3,a2,-1
    8000114a:	ce11                	beqz	a2,80001166 <memmove+0x2a>
    8000114c:	1682                	slli	a3,a3,0x20
    8000114e:	9281                	srli	a3,a3,0x20
    80001150:	0685                	addi	a3,a3,1
    80001152:	96ae                	add	a3,a3,a1
    80001154:	87aa                	mv	a5,a0
      *d++ = *s++;
    80001156:	0585                	addi	a1,a1,1
    80001158:	0785                	addi	a5,a5,1
    8000115a:	fff5c703          	lbu	a4,-1(a1)
    8000115e:	fee78fa3          	sb	a4,-1(a5)
    while(n-- > 0)
    80001162:	fed59ae3          	bne	a1,a3,80001156 <memmove+0x1a>

  return dst;
}
    80001166:	6422                	ld	s0,8(sp)
    80001168:	0141                	addi	sp,sp,16
    8000116a:	8082                	ret
  if(s < d && s + n > d){
    8000116c:	02061713          	slli	a4,a2,0x20
    80001170:	9301                	srli	a4,a4,0x20
    80001172:	00e587b3          	add	a5,a1,a4
    80001176:	fcf578e3          	bgeu	a0,a5,80001146 <memmove+0xa>
    d += n;
    8000117a:	972a                	add	a4,a4,a0
    while(n-- > 0)
    8000117c:	fff6069b          	addiw	a3,a2,-1
    80001180:	d27d                	beqz	a2,80001166 <memmove+0x2a>
    80001182:	02069613          	slli	a2,a3,0x20
    80001186:	9201                	srli	a2,a2,0x20
    80001188:	fff64613          	not	a2,a2
    8000118c:	963e                	add	a2,a2,a5
      *--d = *--s;
    8000118e:	17fd                	addi	a5,a5,-1
    80001190:	177d                	addi	a4,a4,-1
    80001192:	0007c683          	lbu	a3,0(a5)
    80001196:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
    8000119a:	fef61ae3          	bne	a2,a5,8000118e <memmove+0x52>
    8000119e:	b7e1                	j	80001166 <memmove+0x2a>

00000000800011a0 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    800011a0:	1141                	addi	sp,sp,-16
    800011a2:	e406                	sd	ra,8(sp)
    800011a4:	e022                	sd	s0,0(sp)
    800011a6:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    800011a8:	00000097          	auipc	ra,0x0
    800011ac:	f94080e7          	jalr	-108(ra) # 8000113c <memmove>
}
    800011b0:	60a2                	ld	ra,8(sp)
    800011b2:	6402                	ld	s0,0(sp)
    800011b4:	0141                	addi	sp,sp,16
    800011b6:	8082                	ret

00000000800011b8 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    800011b8:	1141                	addi	sp,sp,-16
    800011ba:	e422                	sd	s0,8(sp)
    800011bc:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    800011be:	ce11                	beqz	a2,800011da <strncmp+0x22>
    800011c0:	00054783          	lbu	a5,0(a0)
    800011c4:	cf89                	beqz	a5,800011de <strncmp+0x26>
    800011c6:	0005c703          	lbu	a4,0(a1)
    800011ca:	00f71a63          	bne	a4,a5,800011de <strncmp+0x26>
    n--, p++, q++;
    800011ce:	367d                	addiw	a2,a2,-1
    800011d0:	0505                	addi	a0,a0,1
    800011d2:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    800011d4:	f675                	bnez	a2,800011c0 <strncmp+0x8>
  if(n == 0)
    return 0;
    800011d6:	4501                	li	a0,0
    800011d8:	a809                	j	800011ea <strncmp+0x32>
    800011da:	4501                	li	a0,0
    800011dc:	a039                	j	800011ea <strncmp+0x32>
  if(n == 0)
    800011de:	ca09                	beqz	a2,800011f0 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    800011e0:	00054503          	lbu	a0,0(a0)
    800011e4:	0005c783          	lbu	a5,0(a1)
    800011e8:	9d1d                	subw	a0,a0,a5
}
    800011ea:	6422                	ld	s0,8(sp)
    800011ec:	0141                	addi	sp,sp,16
    800011ee:	8082                	ret
    return 0;
    800011f0:	4501                	li	a0,0
    800011f2:	bfe5                	j	800011ea <strncmp+0x32>

00000000800011f4 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    800011f4:	1141                	addi	sp,sp,-16
    800011f6:	e422                	sd	s0,8(sp)
    800011f8:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    800011fa:	872a                	mv	a4,a0
    800011fc:	8832                	mv	a6,a2
    800011fe:	367d                	addiw	a2,a2,-1
    80001200:	01005963          	blez	a6,80001212 <strncpy+0x1e>
    80001204:	0705                	addi	a4,a4,1
    80001206:	0005c783          	lbu	a5,0(a1)
    8000120a:	fef70fa3          	sb	a5,-1(a4)
    8000120e:	0585                	addi	a1,a1,1
    80001210:	f7f5                	bnez	a5,800011fc <strncpy+0x8>
    ;
  while(n-- > 0)
    80001212:	86ba                	mv	a3,a4
    80001214:	00c05c63          	blez	a2,8000122c <strncpy+0x38>
    *s++ = 0;
    80001218:	0685                	addi	a3,a3,1
    8000121a:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    8000121e:	40d707bb          	subw	a5,a4,a3
    80001222:	37fd                	addiw	a5,a5,-1
    80001224:	010787bb          	addw	a5,a5,a6
    80001228:	fef048e3          	bgtz	a5,80001218 <strncpy+0x24>
  return os;
}
    8000122c:	6422                	ld	s0,8(sp)
    8000122e:	0141                	addi	sp,sp,16
    80001230:	8082                	ret

0000000080001232 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80001232:	1141                	addi	sp,sp,-16
    80001234:	e422                	sd	s0,8(sp)
    80001236:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80001238:	02c05363          	blez	a2,8000125e <safestrcpy+0x2c>
    8000123c:	fff6069b          	addiw	a3,a2,-1
    80001240:	1682                	slli	a3,a3,0x20
    80001242:	9281                	srli	a3,a3,0x20
    80001244:	96ae                	add	a3,a3,a1
    80001246:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80001248:	00d58963          	beq	a1,a3,8000125a <safestrcpy+0x28>
    8000124c:	0585                	addi	a1,a1,1
    8000124e:	0785                	addi	a5,a5,1
    80001250:	fff5c703          	lbu	a4,-1(a1)
    80001254:	fee78fa3          	sb	a4,-1(a5)
    80001258:	fb65                	bnez	a4,80001248 <safestrcpy+0x16>
    ;
  *s = 0;
    8000125a:	00078023          	sb	zero,0(a5)
  return os;
}
    8000125e:	6422                	ld	s0,8(sp)
    80001260:	0141                	addi	sp,sp,16
    80001262:	8082                	ret

0000000080001264 <strlen>:

int
strlen(const char *s)
{
    80001264:	1141                	addi	sp,sp,-16
    80001266:	e422                	sd	s0,8(sp)
    80001268:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    8000126a:	00054783          	lbu	a5,0(a0)
    8000126e:	cf91                	beqz	a5,8000128a <strlen+0x26>
    80001270:	0505                	addi	a0,a0,1
    80001272:	87aa                	mv	a5,a0
    80001274:	4685                	li	a3,1
    80001276:	9e89                	subw	a3,a3,a0
    80001278:	00f6853b          	addw	a0,a3,a5
    8000127c:	0785                	addi	a5,a5,1
    8000127e:	fff7c703          	lbu	a4,-1(a5)
    80001282:	fb7d                	bnez	a4,80001278 <strlen+0x14>
    ;
  return n;
}
    80001284:	6422                	ld	s0,8(sp)
    80001286:	0141                	addi	sp,sp,16
    80001288:	8082                	ret
  for(n = 0; s[n]; n++)
    8000128a:	4501                	li	a0,0
    8000128c:	bfe5                	j	80001284 <strlen+0x20>

000000008000128e <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    8000128e:	1141                	addi	sp,sp,-16
    80001290:	e406                	sd	ra,8(sp)
    80001292:	e022                	sd	s0,0(sp)
    80001294:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80001296:	00001097          	auipc	ra,0x1
    8000129a:	a84080e7          	jalr	-1404(ra) # 80001d1a <cpuid>
#endif    
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    8000129e:	00008717          	auipc	a4,0x8
    800012a2:	d6e70713          	addi	a4,a4,-658 # 8000900c <started>
  if(cpuid() == 0){
    800012a6:	c139                	beqz	a0,800012ec <main+0x5e>
    while(started == 0)
    800012a8:	431c                	lw	a5,0(a4)
    800012aa:	2781                	sext.w	a5,a5
    800012ac:	dff5                	beqz	a5,800012a8 <main+0x1a>
      ;
    __sync_synchronize();
    800012ae:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    800012b2:	00001097          	auipc	ra,0x1
    800012b6:	a68080e7          	jalr	-1432(ra) # 80001d1a <cpuid>
    800012ba:	85aa                	mv	a1,a0
    800012bc:	00007517          	auipc	a0,0x7
    800012c0:	e9450513          	addi	a0,a0,-364 # 80008150 <digits+0x110>
    800012c4:	fffff097          	auipc	ra,0xfffff
    800012c8:	2d2080e7          	jalr	722(ra) # 80000596 <printf>
    kvminithart();    // turn on paging
    800012cc:	00000097          	auipc	ra,0x0
    800012d0:	186080e7          	jalr	390(ra) # 80001452 <kvminithart>
    trapinithart();   // install kernel trap vector
    800012d4:	00001097          	auipc	ra,0x1
    800012d8:	6d2080e7          	jalr	1746(ra) # 800029a6 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    800012dc:	00005097          	auipc	ra,0x5
    800012e0:	c84080e7          	jalr	-892(ra) # 80005f60 <plicinithart>
  }

  scheduler();        
    800012e4:	00001097          	auipc	ra,0x1
    800012e8:	f9a080e7          	jalr	-102(ra) # 8000227e <scheduler>
    consoleinit();
    800012ec:	fffff097          	auipc	ra,0xfffff
    800012f0:	170080e7          	jalr	368(ra) # 8000045c <consoleinit>
    statsinit();
    800012f4:	00005097          	auipc	ra,0x5
    800012f8:	2fe080e7          	jalr	766(ra) # 800065f2 <statsinit>
    printfinit();
    800012fc:	fffff097          	auipc	ra,0xfffff
    80001300:	47a080e7          	jalr	1146(ra) # 80000776 <printfinit>
    printf("\n");
    80001304:	00007517          	auipc	a0,0x7
    80001308:	e5c50513          	addi	a0,a0,-420 # 80008160 <digits+0x120>
    8000130c:	fffff097          	auipc	ra,0xfffff
    80001310:	28a080e7          	jalr	650(ra) # 80000596 <printf>
    printf("xv6 kernel is booting\n");
    80001314:	00007517          	auipc	a0,0x7
    80001318:	e2450513          	addi	a0,a0,-476 # 80008138 <digits+0xf8>
    8000131c:	fffff097          	auipc	ra,0xfffff
    80001320:	27a080e7          	jalr	634(ra) # 80000596 <printf>
    printf("\n");
    80001324:	00007517          	auipc	a0,0x7
    80001328:	e3c50513          	addi	a0,a0,-452 # 80008160 <digits+0x120>
    8000132c:	fffff097          	auipc	ra,0xfffff
    80001330:	26a080e7          	jalr	618(ra) # 80000596 <printf>
    kinit();         // physical page allocator
    80001334:	fffff097          	auipc	ra,0xfffff
    80001338:	7da080e7          	jalr	2010(ra) # 80000b0e <kinit>
    kvminit();       // create kernel page table
    8000133c:	00000097          	auipc	ra,0x0
    80001340:	242080e7          	jalr	578(ra) # 8000157e <kvminit>
    kvminithart();   // turn on paging
    80001344:	00000097          	auipc	ra,0x0
    80001348:	10e080e7          	jalr	270(ra) # 80001452 <kvminithart>
    procinit();      // process table
    8000134c:	00001097          	auipc	ra,0x1
    80001350:	8fe080e7          	jalr	-1794(ra) # 80001c4a <procinit>
    trapinit();      // trap vectors
    80001354:	00001097          	auipc	ra,0x1
    80001358:	62a080e7          	jalr	1578(ra) # 8000297e <trapinit>
    trapinithart();  // install kernel trap vector
    8000135c:	00001097          	auipc	ra,0x1
    80001360:	64a080e7          	jalr	1610(ra) # 800029a6 <trapinithart>
    plicinit();      // set up interrupt controller
    80001364:	00005097          	auipc	ra,0x5
    80001368:	be6080e7          	jalr	-1050(ra) # 80005f4a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    8000136c:	00005097          	auipc	ra,0x5
    80001370:	bf4080e7          	jalr	-1036(ra) # 80005f60 <plicinithart>
    binit();         // buffer cache
    80001374:	00002097          	auipc	ra,0x2
    80001378:	d74080e7          	jalr	-652(ra) # 800030e8 <binit>
    iinit();         // inode cache
    8000137c:	00002097          	auipc	ra,0x2
    80001380:	402080e7          	jalr	1026(ra) # 8000377e <iinit>
    fileinit();      // file table
    80001384:	00003097          	auipc	ra,0x3
    80001388:	3ba080e7          	jalr	954(ra) # 8000473e <fileinit>
    virtio_disk_init(); // emulated hard disk
    8000138c:	00005097          	auipc	ra,0x5
    80001390:	cf4080e7          	jalr	-780(ra) # 80006080 <virtio_disk_init>
    userinit();      // first user process
    80001394:	00001097          	auipc	ra,0x1
    80001398:	c7c080e7          	jalr	-900(ra) # 80002010 <userinit>
    __sync_synchronize();
    8000139c:	0ff0000f          	fence
    started = 1;
    800013a0:	4785                	li	a5,1
    800013a2:	00008717          	auipc	a4,0x8
    800013a6:	c6f72523          	sw	a5,-918(a4) # 8000900c <started>
    800013aa:	bf2d                	j	800012e4 <main+0x56>

00000000800013ac <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
static pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    800013ac:	7139                	addi	sp,sp,-64
    800013ae:	fc06                	sd	ra,56(sp)
    800013b0:	f822                	sd	s0,48(sp)
    800013b2:	f426                	sd	s1,40(sp)
    800013b4:	f04a                	sd	s2,32(sp)
    800013b6:	ec4e                	sd	s3,24(sp)
    800013b8:	e852                	sd	s4,16(sp)
    800013ba:	e456                	sd	s5,8(sp)
    800013bc:	e05a                	sd	s6,0(sp)
    800013be:	0080                	addi	s0,sp,64
    800013c0:	84aa                	mv	s1,a0
    800013c2:	89ae                	mv	s3,a1
    800013c4:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    800013c6:	57fd                	li	a5,-1
    800013c8:	83e9                	srli	a5,a5,0x1a
    800013ca:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    800013cc:	4b31                	li	s6,12
  if(va >= MAXVA)
    800013ce:	04b7f263          	bgeu	a5,a1,80001412 <walk+0x66>
    panic("walk");
    800013d2:	00007517          	auipc	a0,0x7
    800013d6:	d9650513          	addi	a0,a0,-618 # 80008168 <digits+0x128>
    800013da:	fffff097          	auipc	ra,0xfffff
    800013de:	172080e7          	jalr	370(ra) # 8000054c <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    800013e2:	060a8663          	beqz	s5,8000144e <walk+0xa2>
    800013e6:	fffff097          	auipc	ra,0xfffff
    800013ea:	7a4080e7          	jalr	1956(ra) # 80000b8a <kalloc>
    800013ee:	84aa                	mv	s1,a0
    800013f0:	c529                	beqz	a0,8000143a <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    800013f2:	6605                	lui	a2,0x1
    800013f4:	4581                	li	a1,0
    800013f6:	00000097          	auipc	ra,0x0
    800013fa:	cea080e7          	jalr	-790(ra) # 800010e0 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    800013fe:	00c4d793          	srli	a5,s1,0xc
    80001402:	07aa                	slli	a5,a5,0xa
    80001404:	0017e793          	ori	a5,a5,1
    80001408:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    8000140c:	3a5d                	addiw	s4,s4,-9
    8000140e:	036a0063          	beq	s4,s6,8000142e <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    80001412:	0149d933          	srl	s2,s3,s4
    80001416:	1ff97913          	andi	s2,s2,511
    8000141a:	090e                	slli	s2,s2,0x3
    8000141c:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    8000141e:	00093483          	ld	s1,0(s2)
    80001422:	0014f793          	andi	a5,s1,1
    80001426:	dfd5                	beqz	a5,800013e2 <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001428:	80a9                	srli	s1,s1,0xa
    8000142a:	04b2                	slli	s1,s1,0xc
    8000142c:	b7c5                	j	8000140c <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    8000142e:	00c9d513          	srli	a0,s3,0xc
    80001432:	1ff57513          	andi	a0,a0,511
    80001436:	050e                	slli	a0,a0,0x3
    80001438:	9526                	add	a0,a0,s1
}
    8000143a:	70e2                	ld	ra,56(sp)
    8000143c:	7442                	ld	s0,48(sp)
    8000143e:	74a2                	ld	s1,40(sp)
    80001440:	7902                	ld	s2,32(sp)
    80001442:	69e2                	ld	s3,24(sp)
    80001444:	6a42                	ld	s4,16(sp)
    80001446:	6aa2                	ld	s5,8(sp)
    80001448:	6b02                	ld	s6,0(sp)
    8000144a:	6121                	addi	sp,sp,64
    8000144c:	8082                	ret
        return 0;
    8000144e:	4501                	li	a0,0
    80001450:	b7ed                	j	8000143a <walk+0x8e>

0000000080001452 <kvminithart>:
{
    80001452:	1141                	addi	sp,sp,-16
    80001454:	e422                	sd	s0,8(sp)
    80001456:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    80001458:	00008797          	auipc	a5,0x8
    8000145c:	bb87b783          	ld	a5,-1096(a5) # 80009010 <kernel_pagetable>
    80001460:	83b1                	srli	a5,a5,0xc
    80001462:	577d                	li	a4,-1
    80001464:	177e                	slli	a4,a4,0x3f
    80001466:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80001468:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    8000146c:	12000073          	sfence.vma
}
    80001470:	6422                	ld	s0,8(sp)
    80001472:	0141                	addi	sp,sp,16
    80001474:	8082                	ret

0000000080001476 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    80001476:	57fd                	li	a5,-1
    80001478:	83e9                	srli	a5,a5,0x1a
    8000147a:	00b7f463          	bgeu	a5,a1,80001482 <walkaddr+0xc>
    return 0;
    8000147e:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001480:	8082                	ret
{
    80001482:	1141                	addi	sp,sp,-16
    80001484:	e406                	sd	ra,8(sp)
    80001486:	e022                	sd	s0,0(sp)
    80001488:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    8000148a:	4601                	li	a2,0
    8000148c:	00000097          	auipc	ra,0x0
    80001490:	f20080e7          	jalr	-224(ra) # 800013ac <walk>
  if(pte == 0)
    80001494:	c105                	beqz	a0,800014b4 <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    80001496:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    80001498:	0117f693          	andi	a3,a5,17
    8000149c:	4745                	li	a4,17
    return 0;
    8000149e:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    800014a0:	00e68663          	beq	a3,a4,800014ac <walkaddr+0x36>
}
    800014a4:	60a2                	ld	ra,8(sp)
    800014a6:	6402                	ld	s0,0(sp)
    800014a8:	0141                	addi	sp,sp,16
    800014aa:	8082                	ret
  pa = PTE2PA(*pte);
    800014ac:	83a9                	srli	a5,a5,0xa
    800014ae:	00c79513          	slli	a0,a5,0xc
  return pa;
    800014b2:	bfcd                	j	800014a4 <walkaddr+0x2e>
    return 0;
    800014b4:	4501                	li	a0,0
    800014b6:	b7fd                	j	800014a4 <walkaddr+0x2e>

00000000800014b8 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    800014b8:	715d                	addi	sp,sp,-80
    800014ba:	e486                	sd	ra,72(sp)
    800014bc:	e0a2                	sd	s0,64(sp)
    800014be:	fc26                	sd	s1,56(sp)
    800014c0:	f84a                	sd	s2,48(sp)
    800014c2:	f44e                	sd	s3,40(sp)
    800014c4:	f052                	sd	s4,32(sp)
    800014c6:	ec56                	sd	s5,24(sp)
    800014c8:	e85a                	sd	s6,16(sp)
    800014ca:	e45e                	sd	s7,8(sp)
    800014cc:	0880                	addi	s0,sp,80
    800014ce:	8aaa                	mv	s5,a0
    800014d0:	8b3a                	mv	s6,a4
  uint64 a, last;
  pte_t *pte;

  a = PGROUNDDOWN(va);
    800014d2:	777d                	lui	a4,0xfffff
    800014d4:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    800014d8:	fff60993          	addi	s3,a2,-1 # fff <_entry-0x7ffff001>
    800014dc:	99ae                	add	s3,s3,a1
    800014de:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    800014e2:	893e                	mv	s2,a5
    800014e4:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800014e8:	6b85                	lui	s7,0x1
    800014ea:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    800014ee:	4605                	li	a2,1
    800014f0:	85ca                	mv	a1,s2
    800014f2:	8556                	mv	a0,s5
    800014f4:	00000097          	auipc	ra,0x0
    800014f8:	eb8080e7          	jalr	-328(ra) # 800013ac <walk>
    800014fc:	c51d                	beqz	a0,8000152a <mappages+0x72>
    if(*pte & PTE_V)
    800014fe:	611c                	ld	a5,0(a0)
    80001500:	8b85                	andi	a5,a5,1
    80001502:	ef81                	bnez	a5,8000151a <mappages+0x62>
    *pte = PA2PTE(pa) | perm | PTE_V;
    80001504:	80b1                	srli	s1,s1,0xc
    80001506:	04aa                	slli	s1,s1,0xa
    80001508:	0164e4b3          	or	s1,s1,s6
    8000150c:	0014e493          	ori	s1,s1,1
    80001510:	e104                	sd	s1,0(a0)
    if(a == last)
    80001512:	03390863          	beq	s2,s3,80001542 <mappages+0x8a>
    a += PGSIZE;
    80001516:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    80001518:	bfc9                	j	800014ea <mappages+0x32>
      panic("remap");
    8000151a:	00007517          	auipc	a0,0x7
    8000151e:	c5650513          	addi	a0,a0,-938 # 80008170 <digits+0x130>
    80001522:	fffff097          	auipc	ra,0xfffff
    80001526:	02a080e7          	jalr	42(ra) # 8000054c <panic>
      return -1;
    8000152a:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    8000152c:	60a6                	ld	ra,72(sp)
    8000152e:	6406                	ld	s0,64(sp)
    80001530:	74e2                	ld	s1,56(sp)
    80001532:	7942                	ld	s2,48(sp)
    80001534:	79a2                	ld	s3,40(sp)
    80001536:	7a02                	ld	s4,32(sp)
    80001538:	6ae2                	ld	s5,24(sp)
    8000153a:	6b42                	ld	s6,16(sp)
    8000153c:	6ba2                	ld	s7,8(sp)
    8000153e:	6161                	addi	sp,sp,80
    80001540:	8082                	ret
  return 0;
    80001542:	4501                	li	a0,0
    80001544:	b7e5                	j	8000152c <mappages+0x74>

0000000080001546 <kvmmap>:
{
    80001546:	1141                	addi	sp,sp,-16
    80001548:	e406                	sd	ra,8(sp)
    8000154a:	e022                	sd	s0,0(sp)
    8000154c:	0800                	addi	s0,sp,16
    8000154e:	8736                	mv	a4,a3
  if(mappages(kernel_pagetable, va, sz, pa, perm) != 0)
    80001550:	86ae                	mv	a3,a1
    80001552:	85aa                	mv	a1,a0
    80001554:	00008517          	auipc	a0,0x8
    80001558:	abc53503          	ld	a0,-1348(a0) # 80009010 <kernel_pagetable>
    8000155c:	00000097          	auipc	ra,0x0
    80001560:	f5c080e7          	jalr	-164(ra) # 800014b8 <mappages>
    80001564:	e509                	bnez	a0,8000156e <kvmmap+0x28>
}
    80001566:	60a2                	ld	ra,8(sp)
    80001568:	6402                	ld	s0,0(sp)
    8000156a:	0141                	addi	sp,sp,16
    8000156c:	8082                	ret
    panic("kvmmap");
    8000156e:	00007517          	auipc	a0,0x7
    80001572:	c0a50513          	addi	a0,a0,-1014 # 80008178 <digits+0x138>
    80001576:	fffff097          	auipc	ra,0xfffff
    8000157a:	fd6080e7          	jalr	-42(ra) # 8000054c <panic>

000000008000157e <kvminit>:
{
    8000157e:	1101                	addi	sp,sp,-32
    80001580:	ec06                	sd	ra,24(sp)
    80001582:	e822                	sd	s0,16(sp)
    80001584:	e426                	sd	s1,8(sp)
    80001586:	1000                	addi	s0,sp,32
  kernel_pagetable = (pagetable_t) kalloc();
    80001588:	fffff097          	auipc	ra,0xfffff
    8000158c:	602080e7          	jalr	1538(ra) # 80000b8a <kalloc>
    80001590:	00008717          	auipc	a4,0x8
    80001594:	a8a73023          	sd	a0,-1408(a4) # 80009010 <kernel_pagetable>
  memset(kernel_pagetable, 0, PGSIZE);
    80001598:	6605                	lui	a2,0x1
    8000159a:	4581                	li	a1,0
    8000159c:	00000097          	auipc	ra,0x0
    800015a0:	b44080e7          	jalr	-1212(ra) # 800010e0 <memset>
  kvmmap(UART0, UART0, PGSIZE, PTE_R | PTE_W);
    800015a4:	4699                	li	a3,6
    800015a6:	6605                	lui	a2,0x1
    800015a8:	100005b7          	lui	a1,0x10000
    800015ac:	10000537          	lui	a0,0x10000
    800015b0:	00000097          	auipc	ra,0x0
    800015b4:	f96080e7          	jalr	-106(ra) # 80001546 <kvmmap>
  kvmmap(VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800015b8:	4699                	li	a3,6
    800015ba:	6605                	lui	a2,0x1
    800015bc:	100015b7          	lui	a1,0x10001
    800015c0:	10001537          	lui	a0,0x10001
    800015c4:	00000097          	auipc	ra,0x0
    800015c8:	f82080e7          	jalr	-126(ra) # 80001546 <kvmmap>
  kvmmap(PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800015cc:	4699                	li	a3,6
    800015ce:	00400637          	lui	a2,0x400
    800015d2:	0c0005b7          	lui	a1,0xc000
    800015d6:	0c000537          	lui	a0,0xc000
    800015da:	00000097          	auipc	ra,0x0
    800015de:	f6c080e7          	jalr	-148(ra) # 80001546 <kvmmap>
  kvmmap(KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800015e2:	00007497          	auipc	s1,0x7
    800015e6:	a1e48493          	addi	s1,s1,-1506 # 80008000 <etext>
    800015ea:	46a9                	li	a3,10
    800015ec:	80007617          	auipc	a2,0x80007
    800015f0:	a1460613          	addi	a2,a2,-1516 # 8000 <_entry-0x7fff8000>
    800015f4:	4585                	li	a1,1
    800015f6:	05fe                	slli	a1,a1,0x1f
    800015f8:	852e                	mv	a0,a1
    800015fa:	00000097          	auipc	ra,0x0
    800015fe:	f4c080e7          	jalr	-180(ra) # 80001546 <kvmmap>
  kvmmap((uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    80001602:	4699                	li	a3,6
    80001604:	4645                	li	a2,17
    80001606:	066e                	slli	a2,a2,0x1b
    80001608:	8e05                	sub	a2,a2,s1
    8000160a:	85a6                	mv	a1,s1
    8000160c:	8526                	mv	a0,s1
    8000160e:	00000097          	auipc	ra,0x0
    80001612:	f38080e7          	jalr	-200(ra) # 80001546 <kvmmap>
  kvmmap(TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80001616:	46a9                	li	a3,10
    80001618:	6605                	lui	a2,0x1
    8000161a:	00006597          	auipc	a1,0x6
    8000161e:	9e658593          	addi	a1,a1,-1562 # 80007000 <_trampoline>
    80001622:	04000537          	lui	a0,0x4000
    80001626:	157d                	addi	a0,a0,-1 # 3ffffff <_entry-0x7c000001>
    80001628:	0532                	slli	a0,a0,0xc
    8000162a:	00000097          	auipc	ra,0x0
    8000162e:	f1c080e7          	jalr	-228(ra) # 80001546 <kvmmap>
}
    80001632:	60e2                	ld	ra,24(sp)
    80001634:	6442                	ld	s0,16(sp)
    80001636:	64a2                	ld	s1,8(sp)
    80001638:	6105                	addi	sp,sp,32
    8000163a:	8082                	ret

000000008000163c <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    8000163c:	715d                	addi	sp,sp,-80
    8000163e:	e486                	sd	ra,72(sp)
    80001640:	e0a2                	sd	s0,64(sp)
    80001642:	fc26                	sd	s1,56(sp)
    80001644:	f84a                	sd	s2,48(sp)
    80001646:	f44e                	sd	s3,40(sp)
    80001648:	f052                	sd	s4,32(sp)
    8000164a:	ec56                	sd	s5,24(sp)
    8000164c:	e85a                	sd	s6,16(sp)
    8000164e:	e45e                	sd	s7,8(sp)
    80001650:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    80001652:	03459793          	slli	a5,a1,0x34
    80001656:	e795                	bnez	a5,80001682 <uvmunmap+0x46>
    80001658:	8a2a                	mv	s4,a0
    8000165a:	892e                	mv	s2,a1
    8000165c:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000165e:	0632                	slli	a2,a2,0xc
    80001660:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    80001664:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001666:	6b05                	lui	s6,0x1
    80001668:	0735e263          	bltu	a1,s3,800016cc <uvmunmap+0x90>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    8000166c:	60a6                	ld	ra,72(sp)
    8000166e:	6406                	ld	s0,64(sp)
    80001670:	74e2                	ld	s1,56(sp)
    80001672:	7942                	ld	s2,48(sp)
    80001674:	79a2                	ld	s3,40(sp)
    80001676:	7a02                	ld	s4,32(sp)
    80001678:	6ae2                	ld	s5,24(sp)
    8000167a:	6b42                	ld	s6,16(sp)
    8000167c:	6ba2                	ld	s7,8(sp)
    8000167e:	6161                	addi	sp,sp,80
    80001680:	8082                	ret
    panic("uvmunmap: not aligned");
    80001682:	00007517          	auipc	a0,0x7
    80001686:	afe50513          	addi	a0,a0,-1282 # 80008180 <digits+0x140>
    8000168a:	fffff097          	auipc	ra,0xfffff
    8000168e:	ec2080e7          	jalr	-318(ra) # 8000054c <panic>
      panic("uvmunmap: walk");
    80001692:	00007517          	auipc	a0,0x7
    80001696:	b0650513          	addi	a0,a0,-1274 # 80008198 <digits+0x158>
    8000169a:	fffff097          	auipc	ra,0xfffff
    8000169e:	eb2080e7          	jalr	-334(ra) # 8000054c <panic>
      panic("uvmunmap: not mapped");
    800016a2:	00007517          	auipc	a0,0x7
    800016a6:	b0650513          	addi	a0,a0,-1274 # 800081a8 <digits+0x168>
    800016aa:	fffff097          	auipc	ra,0xfffff
    800016ae:	ea2080e7          	jalr	-350(ra) # 8000054c <panic>
      panic("uvmunmap: not a leaf");
    800016b2:	00007517          	auipc	a0,0x7
    800016b6:	b0e50513          	addi	a0,a0,-1266 # 800081c0 <digits+0x180>
    800016ba:	fffff097          	auipc	ra,0xfffff
    800016be:	e92080e7          	jalr	-366(ra) # 8000054c <panic>
    *pte = 0;
    800016c2:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800016c6:	995a                	add	s2,s2,s6
    800016c8:	fb3972e3          	bgeu	s2,s3,8000166c <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    800016cc:	4601                	li	a2,0
    800016ce:	85ca                	mv	a1,s2
    800016d0:	8552                	mv	a0,s4
    800016d2:	00000097          	auipc	ra,0x0
    800016d6:	cda080e7          	jalr	-806(ra) # 800013ac <walk>
    800016da:	84aa                	mv	s1,a0
    800016dc:	d95d                	beqz	a0,80001692 <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    800016de:	6108                	ld	a0,0(a0)
    800016e0:	00157793          	andi	a5,a0,1
    800016e4:	dfdd                	beqz	a5,800016a2 <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    800016e6:	3ff57793          	andi	a5,a0,1023
    800016ea:	fd7784e3          	beq	a5,s7,800016b2 <uvmunmap+0x76>
    if(do_free){
    800016ee:	fc0a8ae3          	beqz	s5,800016c2 <uvmunmap+0x86>
      uint64 pa = PTE2PA(*pte);
    800016f2:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    800016f4:	0532                	slli	a0,a0,0xc
    800016f6:	fffff097          	auipc	ra,0xfffff
    800016fa:	322080e7          	jalr	802(ra) # 80000a18 <kfree>
    800016fe:	b7d1                	j	800016c2 <uvmunmap+0x86>

0000000080001700 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    80001700:	1101                	addi	sp,sp,-32
    80001702:	ec06                	sd	ra,24(sp)
    80001704:	e822                	sd	s0,16(sp)
    80001706:	e426                	sd	s1,8(sp)
    80001708:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    8000170a:	fffff097          	auipc	ra,0xfffff
    8000170e:	480080e7          	jalr	1152(ra) # 80000b8a <kalloc>
    80001712:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001714:	c519                	beqz	a0,80001722 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    80001716:	6605                	lui	a2,0x1
    80001718:	4581                	li	a1,0
    8000171a:	00000097          	auipc	ra,0x0
    8000171e:	9c6080e7          	jalr	-1594(ra) # 800010e0 <memset>
  return pagetable;
}
    80001722:	8526                	mv	a0,s1
    80001724:	60e2                	ld	ra,24(sp)
    80001726:	6442                	ld	s0,16(sp)
    80001728:	64a2                	ld	s1,8(sp)
    8000172a:	6105                	addi	sp,sp,32
    8000172c:	8082                	ret

000000008000172e <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    8000172e:	7179                	addi	sp,sp,-48
    80001730:	f406                	sd	ra,40(sp)
    80001732:	f022                	sd	s0,32(sp)
    80001734:	ec26                	sd	s1,24(sp)
    80001736:	e84a                	sd	s2,16(sp)
    80001738:	e44e                	sd	s3,8(sp)
    8000173a:	e052                	sd	s4,0(sp)
    8000173c:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    8000173e:	6785                	lui	a5,0x1
    80001740:	04f67863          	bgeu	a2,a5,80001790 <uvminit+0x62>
    80001744:	8a2a                	mv	s4,a0
    80001746:	89ae                	mv	s3,a1
    80001748:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    8000174a:	fffff097          	auipc	ra,0xfffff
    8000174e:	440080e7          	jalr	1088(ra) # 80000b8a <kalloc>
    80001752:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    80001754:	6605                	lui	a2,0x1
    80001756:	4581                	li	a1,0
    80001758:	00000097          	auipc	ra,0x0
    8000175c:	988080e7          	jalr	-1656(ra) # 800010e0 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    80001760:	4779                	li	a4,30
    80001762:	86ca                	mv	a3,s2
    80001764:	6605                	lui	a2,0x1
    80001766:	4581                	li	a1,0
    80001768:	8552                	mv	a0,s4
    8000176a:	00000097          	auipc	ra,0x0
    8000176e:	d4e080e7          	jalr	-690(ra) # 800014b8 <mappages>
  memmove(mem, src, sz);
    80001772:	8626                	mv	a2,s1
    80001774:	85ce                	mv	a1,s3
    80001776:	854a                	mv	a0,s2
    80001778:	00000097          	auipc	ra,0x0
    8000177c:	9c4080e7          	jalr	-1596(ra) # 8000113c <memmove>
}
    80001780:	70a2                	ld	ra,40(sp)
    80001782:	7402                	ld	s0,32(sp)
    80001784:	64e2                	ld	s1,24(sp)
    80001786:	6942                	ld	s2,16(sp)
    80001788:	69a2                	ld	s3,8(sp)
    8000178a:	6a02                	ld	s4,0(sp)
    8000178c:	6145                	addi	sp,sp,48
    8000178e:	8082                	ret
    panic("inituvm: more than a page");
    80001790:	00007517          	auipc	a0,0x7
    80001794:	a4850513          	addi	a0,a0,-1464 # 800081d8 <digits+0x198>
    80001798:	fffff097          	auipc	ra,0xfffff
    8000179c:	db4080e7          	jalr	-588(ra) # 8000054c <panic>

00000000800017a0 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800017a0:	1101                	addi	sp,sp,-32
    800017a2:	ec06                	sd	ra,24(sp)
    800017a4:	e822                	sd	s0,16(sp)
    800017a6:	e426                	sd	s1,8(sp)
    800017a8:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800017aa:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800017ac:	00b67d63          	bgeu	a2,a1,800017c6 <uvmdealloc+0x26>
    800017b0:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800017b2:	6785                	lui	a5,0x1
    800017b4:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    800017b6:	00f60733          	add	a4,a2,a5
    800017ba:	76fd                	lui	a3,0xfffff
    800017bc:	8f75                	and	a4,a4,a3
    800017be:	97ae                	add	a5,a5,a1
    800017c0:	8ff5                	and	a5,a5,a3
    800017c2:	00f76863          	bltu	a4,a5,800017d2 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    800017c6:	8526                	mv	a0,s1
    800017c8:	60e2                	ld	ra,24(sp)
    800017ca:	6442                	ld	s0,16(sp)
    800017cc:	64a2                	ld	s1,8(sp)
    800017ce:	6105                	addi	sp,sp,32
    800017d0:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    800017d2:	8f99                	sub	a5,a5,a4
    800017d4:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    800017d6:	4685                	li	a3,1
    800017d8:	0007861b          	sext.w	a2,a5
    800017dc:	85ba                	mv	a1,a4
    800017de:	00000097          	auipc	ra,0x0
    800017e2:	e5e080e7          	jalr	-418(ra) # 8000163c <uvmunmap>
    800017e6:	b7c5                	j	800017c6 <uvmdealloc+0x26>

00000000800017e8 <uvmalloc>:
  if(newsz < oldsz)
    800017e8:	0ab66163          	bltu	a2,a1,8000188a <uvmalloc+0xa2>
{
    800017ec:	7139                	addi	sp,sp,-64
    800017ee:	fc06                	sd	ra,56(sp)
    800017f0:	f822                	sd	s0,48(sp)
    800017f2:	f426                	sd	s1,40(sp)
    800017f4:	f04a                	sd	s2,32(sp)
    800017f6:	ec4e                	sd	s3,24(sp)
    800017f8:	e852                	sd	s4,16(sp)
    800017fa:	e456                	sd	s5,8(sp)
    800017fc:	0080                	addi	s0,sp,64
    800017fe:	8aaa                	mv	s5,a0
    80001800:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    80001802:	6785                	lui	a5,0x1
    80001804:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80001806:	95be                	add	a1,a1,a5
    80001808:	77fd                	lui	a5,0xfffff
    8000180a:	00f5f9b3          	and	s3,a1,a5
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000180e:	08c9f063          	bgeu	s3,a2,8000188e <uvmalloc+0xa6>
    80001812:	894e                	mv	s2,s3
    mem = kalloc();
    80001814:	fffff097          	auipc	ra,0xfffff
    80001818:	376080e7          	jalr	886(ra) # 80000b8a <kalloc>
    8000181c:	84aa                	mv	s1,a0
    if(mem == 0){
    8000181e:	c51d                	beqz	a0,8000184c <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    80001820:	6605                	lui	a2,0x1
    80001822:	4581                	li	a1,0
    80001824:	00000097          	auipc	ra,0x0
    80001828:	8bc080e7          	jalr	-1860(ra) # 800010e0 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    8000182c:	4779                	li	a4,30
    8000182e:	86a6                	mv	a3,s1
    80001830:	6605                	lui	a2,0x1
    80001832:	85ca                	mv	a1,s2
    80001834:	8556                	mv	a0,s5
    80001836:	00000097          	auipc	ra,0x0
    8000183a:	c82080e7          	jalr	-894(ra) # 800014b8 <mappages>
    8000183e:	e905                	bnez	a0,8000186e <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001840:	6785                	lui	a5,0x1
    80001842:	993e                	add	s2,s2,a5
    80001844:	fd4968e3          	bltu	s2,s4,80001814 <uvmalloc+0x2c>
  return newsz;
    80001848:	8552                	mv	a0,s4
    8000184a:	a809                	j	8000185c <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    8000184c:	864e                	mv	a2,s3
    8000184e:	85ca                	mv	a1,s2
    80001850:	8556                	mv	a0,s5
    80001852:	00000097          	auipc	ra,0x0
    80001856:	f4e080e7          	jalr	-178(ra) # 800017a0 <uvmdealloc>
      return 0;
    8000185a:	4501                	li	a0,0
}
    8000185c:	70e2                	ld	ra,56(sp)
    8000185e:	7442                	ld	s0,48(sp)
    80001860:	74a2                	ld	s1,40(sp)
    80001862:	7902                	ld	s2,32(sp)
    80001864:	69e2                	ld	s3,24(sp)
    80001866:	6a42                	ld	s4,16(sp)
    80001868:	6aa2                	ld	s5,8(sp)
    8000186a:	6121                	addi	sp,sp,64
    8000186c:	8082                	ret
      kfree(mem);
    8000186e:	8526                	mv	a0,s1
    80001870:	fffff097          	auipc	ra,0xfffff
    80001874:	1a8080e7          	jalr	424(ra) # 80000a18 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    80001878:	864e                	mv	a2,s3
    8000187a:	85ca                	mv	a1,s2
    8000187c:	8556                	mv	a0,s5
    8000187e:	00000097          	auipc	ra,0x0
    80001882:	f22080e7          	jalr	-222(ra) # 800017a0 <uvmdealloc>
      return 0;
    80001886:	4501                	li	a0,0
    80001888:	bfd1                	j	8000185c <uvmalloc+0x74>
    return oldsz;
    8000188a:	852e                	mv	a0,a1
}
    8000188c:	8082                	ret
  return newsz;
    8000188e:	8532                	mv	a0,a2
    80001890:	b7f1                	j	8000185c <uvmalloc+0x74>

0000000080001892 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    80001892:	7179                	addi	sp,sp,-48
    80001894:	f406                	sd	ra,40(sp)
    80001896:	f022                	sd	s0,32(sp)
    80001898:	ec26                	sd	s1,24(sp)
    8000189a:	e84a                	sd	s2,16(sp)
    8000189c:	e44e                	sd	s3,8(sp)
    8000189e:	e052                	sd	s4,0(sp)
    800018a0:	1800                	addi	s0,sp,48
    800018a2:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800018a4:	84aa                	mv	s1,a0
    800018a6:	6905                	lui	s2,0x1
    800018a8:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800018aa:	4985                	li	s3,1
    800018ac:	a829                	j	800018c6 <freewalk+0x34>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800018ae:	83a9                	srli	a5,a5,0xa
      freewalk((pagetable_t)child);
    800018b0:	00c79513          	slli	a0,a5,0xc
    800018b4:	00000097          	auipc	ra,0x0
    800018b8:	fde080e7          	jalr	-34(ra) # 80001892 <freewalk>
      pagetable[i] = 0;
    800018bc:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800018c0:	04a1                	addi	s1,s1,8
    800018c2:	03248163          	beq	s1,s2,800018e4 <freewalk+0x52>
    pte_t pte = pagetable[i];
    800018c6:	609c                	ld	a5,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800018c8:	00f7f713          	andi	a4,a5,15
    800018cc:	ff3701e3          	beq	a4,s3,800018ae <freewalk+0x1c>
    } else if(pte & PTE_V){
    800018d0:	8b85                	andi	a5,a5,1
    800018d2:	d7fd                	beqz	a5,800018c0 <freewalk+0x2e>
      panic("freewalk: leaf");
    800018d4:	00007517          	auipc	a0,0x7
    800018d8:	92450513          	addi	a0,a0,-1756 # 800081f8 <digits+0x1b8>
    800018dc:	fffff097          	auipc	ra,0xfffff
    800018e0:	c70080e7          	jalr	-912(ra) # 8000054c <panic>
    }
  }
  kfree((void*)pagetable);
    800018e4:	8552                	mv	a0,s4
    800018e6:	fffff097          	auipc	ra,0xfffff
    800018ea:	132080e7          	jalr	306(ra) # 80000a18 <kfree>
}
    800018ee:	70a2                	ld	ra,40(sp)
    800018f0:	7402                	ld	s0,32(sp)
    800018f2:	64e2                	ld	s1,24(sp)
    800018f4:	6942                	ld	s2,16(sp)
    800018f6:	69a2                	ld	s3,8(sp)
    800018f8:	6a02                	ld	s4,0(sp)
    800018fa:	6145                	addi	sp,sp,48
    800018fc:	8082                	ret

00000000800018fe <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    800018fe:	1101                	addi	sp,sp,-32
    80001900:	ec06                	sd	ra,24(sp)
    80001902:	e822                	sd	s0,16(sp)
    80001904:	e426                	sd	s1,8(sp)
    80001906:	1000                	addi	s0,sp,32
    80001908:	84aa                	mv	s1,a0
  if(sz > 0)
    8000190a:	e999                	bnez	a1,80001920 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    8000190c:	8526                	mv	a0,s1
    8000190e:	00000097          	auipc	ra,0x0
    80001912:	f84080e7          	jalr	-124(ra) # 80001892 <freewalk>
}
    80001916:	60e2                	ld	ra,24(sp)
    80001918:	6442                	ld	s0,16(sp)
    8000191a:	64a2                	ld	s1,8(sp)
    8000191c:	6105                	addi	sp,sp,32
    8000191e:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001920:	6785                	lui	a5,0x1
    80001922:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80001924:	95be                	add	a1,a1,a5
    80001926:	4685                	li	a3,1
    80001928:	00c5d613          	srli	a2,a1,0xc
    8000192c:	4581                	li	a1,0
    8000192e:	00000097          	auipc	ra,0x0
    80001932:	d0e080e7          	jalr	-754(ra) # 8000163c <uvmunmap>
    80001936:	bfd9                	j	8000190c <uvmfree+0xe>

0000000080001938 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    80001938:	c679                	beqz	a2,80001a06 <uvmcopy+0xce>
{
    8000193a:	715d                	addi	sp,sp,-80
    8000193c:	e486                	sd	ra,72(sp)
    8000193e:	e0a2                	sd	s0,64(sp)
    80001940:	fc26                	sd	s1,56(sp)
    80001942:	f84a                	sd	s2,48(sp)
    80001944:	f44e                	sd	s3,40(sp)
    80001946:	f052                	sd	s4,32(sp)
    80001948:	ec56                	sd	s5,24(sp)
    8000194a:	e85a                	sd	s6,16(sp)
    8000194c:	e45e                	sd	s7,8(sp)
    8000194e:	0880                	addi	s0,sp,80
    80001950:	8b2a                	mv	s6,a0
    80001952:	8aae                	mv	s5,a1
    80001954:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    80001956:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    80001958:	4601                	li	a2,0
    8000195a:	85ce                	mv	a1,s3
    8000195c:	855a                	mv	a0,s6
    8000195e:	00000097          	auipc	ra,0x0
    80001962:	a4e080e7          	jalr	-1458(ra) # 800013ac <walk>
    80001966:	c531                	beqz	a0,800019b2 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    80001968:	6118                	ld	a4,0(a0)
    8000196a:	00177793          	andi	a5,a4,1
    8000196e:	cbb1                	beqz	a5,800019c2 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    80001970:	00a75593          	srli	a1,a4,0xa
    80001974:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    80001978:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    8000197c:	fffff097          	auipc	ra,0xfffff
    80001980:	20e080e7          	jalr	526(ra) # 80000b8a <kalloc>
    80001984:	892a                	mv	s2,a0
    80001986:	c939                	beqz	a0,800019dc <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    80001988:	6605                	lui	a2,0x1
    8000198a:	85de                	mv	a1,s7
    8000198c:	fffff097          	auipc	ra,0xfffff
    80001990:	7b0080e7          	jalr	1968(ra) # 8000113c <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    80001994:	8726                	mv	a4,s1
    80001996:	86ca                	mv	a3,s2
    80001998:	6605                	lui	a2,0x1
    8000199a:	85ce                	mv	a1,s3
    8000199c:	8556                	mv	a0,s5
    8000199e:	00000097          	auipc	ra,0x0
    800019a2:	b1a080e7          	jalr	-1254(ra) # 800014b8 <mappages>
    800019a6:	e515                	bnez	a0,800019d2 <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800019a8:	6785                	lui	a5,0x1
    800019aa:	99be                	add	s3,s3,a5
    800019ac:	fb49e6e3          	bltu	s3,s4,80001958 <uvmcopy+0x20>
    800019b0:	a081                	j	800019f0 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800019b2:	00007517          	auipc	a0,0x7
    800019b6:	85650513          	addi	a0,a0,-1962 # 80008208 <digits+0x1c8>
    800019ba:	fffff097          	auipc	ra,0xfffff
    800019be:	b92080e7          	jalr	-1134(ra) # 8000054c <panic>
      panic("uvmcopy: page not present");
    800019c2:	00007517          	auipc	a0,0x7
    800019c6:	86650513          	addi	a0,a0,-1946 # 80008228 <digits+0x1e8>
    800019ca:	fffff097          	auipc	ra,0xfffff
    800019ce:	b82080e7          	jalr	-1150(ra) # 8000054c <panic>
      kfree(mem);
    800019d2:	854a                	mv	a0,s2
    800019d4:	fffff097          	auipc	ra,0xfffff
    800019d8:	044080e7          	jalr	68(ra) # 80000a18 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    800019dc:	4685                	li	a3,1
    800019de:	00c9d613          	srli	a2,s3,0xc
    800019e2:	4581                	li	a1,0
    800019e4:	8556                	mv	a0,s5
    800019e6:	00000097          	auipc	ra,0x0
    800019ea:	c56080e7          	jalr	-938(ra) # 8000163c <uvmunmap>
  return -1;
    800019ee:	557d                	li	a0,-1
}
    800019f0:	60a6                	ld	ra,72(sp)
    800019f2:	6406                	ld	s0,64(sp)
    800019f4:	74e2                	ld	s1,56(sp)
    800019f6:	7942                	ld	s2,48(sp)
    800019f8:	79a2                	ld	s3,40(sp)
    800019fa:	7a02                	ld	s4,32(sp)
    800019fc:	6ae2                	ld	s5,24(sp)
    800019fe:	6b42                	ld	s6,16(sp)
    80001a00:	6ba2                	ld	s7,8(sp)
    80001a02:	6161                	addi	sp,sp,80
    80001a04:	8082                	ret
  return 0;
    80001a06:	4501                	li	a0,0
}
    80001a08:	8082                	ret

0000000080001a0a <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001a0a:	1141                	addi	sp,sp,-16
    80001a0c:	e406                	sd	ra,8(sp)
    80001a0e:	e022                	sd	s0,0(sp)
    80001a10:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001a12:	4601                	li	a2,0
    80001a14:	00000097          	auipc	ra,0x0
    80001a18:	998080e7          	jalr	-1640(ra) # 800013ac <walk>
  if(pte == 0)
    80001a1c:	c901                	beqz	a0,80001a2c <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    80001a1e:	611c                	ld	a5,0(a0)
    80001a20:	9bbd                	andi	a5,a5,-17
    80001a22:	e11c                	sd	a5,0(a0)
}
    80001a24:	60a2                	ld	ra,8(sp)
    80001a26:	6402                	ld	s0,0(sp)
    80001a28:	0141                	addi	sp,sp,16
    80001a2a:	8082                	ret
    panic("uvmclear");
    80001a2c:	00007517          	auipc	a0,0x7
    80001a30:	81c50513          	addi	a0,a0,-2020 # 80008248 <digits+0x208>
    80001a34:	fffff097          	auipc	ra,0xfffff
    80001a38:	b18080e7          	jalr	-1256(ra) # 8000054c <panic>

0000000080001a3c <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001a3c:	c6bd                	beqz	a3,80001aaa <copyout+0x6e>
{
    80001a3e:	715d                	addi	sp,sp,-80
    80001a40:	e486                	sd	ra,72(sp)
    80001a42:	e0a2                	sd	s0,64(sp)
    80001a44:	fc26                	sd	s1,56(sp)
    80001a46:	f84a                	sd	s2,48(sp)
    80001a48:	f44e                	sd	s3,40(sp)
    80001a4a:	f052                	sd	s4,32(sp)
    80001a4c:	ec56                	sd	s5,24(sp)
    80001a4e:	e85a                	sd	s6,16(sp)
    80001a50:	e45e                	sd	s7,8(sp)
    80001a52:	e062                	sd	s8,0(sp)
    80001a54:	0880                	addi	s0,sp,80
    80001a56:	8b2a                	mv	s6,a0
    80001a58:	8c2e                	mv	s8,a1
    80001a5a:	8a32                	mv	s4,a2
    80001a5c:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    80001a5e:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    80001a60:	6a85                	lui	s5,0x1
    80001a62:	a015                	j	80001a86 <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    80001a64:	9562                	add	a0,a0,s8
    80001a66:	0004861b          	sext.w	a2,s1
    80001a6a:	85d2                	mv	a1,s4
    80001a6c:	41250533          	sub	a0,a0,s2
    80001a70:	fffff097          	auipc	ra,0xfffff
    80001a74:	6cc080e7          	jalr	1740(ra) # 8000113c <memmove>

    len -= n;
    80001a78:	409989b3          	sub	s3,s3,s1
    src += n;
    80001a7c:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    80001a7e:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001a82:	02098263          	beqz	s3,80001aa6 <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    80001a86:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001a8a:	85ca                	mv	a1,s2
    80001a8c:	855a                	mv	a0,s6
    80001a8e:	00000097          	auipc	ra,0x0
    80001a92:	9e8080e7          	jalr	-1560(ra) # 80001476 <walkaddr>
    if(pa0 == 0)
    80001a96:	cd01                	beqz	a0,80001aae <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    80001a98:	418904b3          	sub	s1,s2,s8
    80001a9c:	94d6                	add	s1,s1,s5
    80001a9e:	fc99f3e3          	bgeu	s3,s1,80001a64 <copyout+0x28>
    80001aa2:	84ce                	mv	s1,s3
    80001aa4:	b7c1                	j	80001a64 <copyout+0x28>
  }
  return 0;
    80001aa6:	4501                	li	a0,0
    80001aa8:	a021                	j	80001ab0 <copyout+0x74>
    80001aaa:	4501                	li	a0,0
}
    80001aac:	8082                	ret
      return -1;
    80001aae:	557d                	li	a0,-1
}
    80001ab0:	60a6                	ld	ra,72(sp)
    80001ab2:	6406                	ld	s0,64(sp)
    80001ab4:	74e2                	ld	s1,56(sp)
    80001ab6:	7942                	ld	s2,48(sp)
    80001ab8:	79a2                	ld	s3,40(sp)
    80001aba:	7a02                	ld	s4,32(sp)
    80001abc:	6ae2                	ld	s5,24(sp)
    80001abe:	6b42                	ld	s6,16(sp)
    80001ac0:	6ba2                	ld	s7,8(sp)
    80001ac2:	6c02                	ld	s8,0(sp)
    80001ac4:	6161                	addi	sp,sp,80
    80001ac6:	8082                	ret

0000000080001ac8 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001ac8:	caa5                	beqz	a3,80001b38 <copyin+0x70>
{
    80001aca:	715d                	addi	sp,sp,-80
    80001acc:	e486                	sd	ra,72(sp)
    80001ace:	e0a2                	sd	s0,64(sp)
    80001ad0:	fc26                	sd	s1,56(sp)
    80001ad2:	f84a                	sd	s2,48(sp)
    80001ad4:	f44e                	sd	s3,40(sp)
    80001ad6:	f052                	sd	s4,32(sp)
    80001ad8:	ec56                	sd	s5,24(sp)
    80001ada:	e85a                	sd	s6,16(sp)
    80001adc:	e45e                	sd	s7,8(sp)
    80001ade:	e062                	sd	s8,0(sp)
    80001ae0:	0880                	addi	s0,sp,80
    80001ae2:	8b2a                	mv	s6,a0
    80001ae4:	8a2e                	mv	s4,a1
    80001ae6:	8c32                	mv	s8,a2
    80001ae8:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001aea:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001aec:	6a85                	lui	s5,0x1
    80001aee:	a01d                	j	80001b14 <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001af0:	018505b3          	add	a1,a0,s8
    80001af4:	0004861b          	sext.w	a2,s1
    80001af8:	412585b3          	sub	a1,a1,s2
    80001afc:	8552                	mv	a0,s4
    80001afe:	fffff097          	auipc	ra,0xfffff
    80001b02:	63e080e7          	jalr	1598(ra) # 8000113c <memmove>

    len -= n;
    80001b06:	409989b3          	sub	s3,s3,s1
    dst += n;
    80001b0a:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001b0c:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001b10:	02098263          	beqz	s3,80001b34 <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    80001b14:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001b18:	85ca                	mv	a1,s2
    80001b1a:	855a                	mv	a0,s6
    80001b1c:	00000097          	auipc	ra,0x0
    80001b20:	95a080e7          	jalr	-1702(ra) # 80001476 <walkaddr>
    if(pa0 == 0)
    80001b24:	cd01                	beqz	a0,80001b3c <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    80001b26:	418904b3          	sub	s1,s2,s8
    80001b2a:	94d6                	add	s1,s1,s5
    80001b2c:	fc99f2e3          	bgeu	s3,s1,80001af0 <copyin+0x28>
    80001b30:	84ce                	mv	s1,s3
    80001b32:	bf7d                	j	80001af0 <copyin+0x28>
  }
  return 0;
    80001b34:	4501                	li	a0,0
    80001b36:	a021                	j	80001b3e <copyin+0x76>
    80001b38:	4501                	li	a0,0
}
    80001b3a:	8082                	ret
      return -1;
    80001b3c:	557d                	li	a0,-1
}
    80001b3e:	60a6                	ld	ra,72(sp)
    80001b40:	6406                	ld	s0,64(sp)
    80001b42:	74e2                	ld	s1,56(sp)
    80001b44:	7942                	ld	s2,48(sp)
    80001b46:	79a2                	ld	s3,40(sp)
    80001b48:	7a02                	ld	s4,32(sp)
    80001b4a:	6ae2                	ld	s5,24(sp)
    80001b4c:	6b42                	ld	s6,16(sp)
    80001b4e:	6ba2                	ld	s7,8(sp)
    80001b50:	6c02                	ld	s8,0(sp)
    80001b52:	6161                	addi	sp,sp,80
    80001b54:	8082                	ret

0000000080001b56 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    80001b56:	c2dd                	beqz	a3,80001bfc <copyinstr+0xa6>
{
    80001b58:	715d                	addi	sp,sp,-80
    80001b5a:	e486                	sd	ra,72(sp)
    80001b5c:	e0a2                	sd	s0,64(sp)
    80001b5e:	fc26                	sd	s1,56(sp)
    80001b60:	f84a                	sd	s2,48(sp)
    80001b62:	f44e                	sd	s3,40(sp)
    80001b64:	f052                	sd	s4,32(sp)
    80001b66:	ec56                	sd	s5,24(sp)
    80001b68:	e85a                	sd	s6,16(sp)
    80001b6a:	e45e                	sd	s7,8(sp)
    80001b6c:	0880                	addi	s0,sp,80
    80001b6e:	8a2a                	mv	s4,a0
    80001b70:	8b2e                	mv	s6,a1
    80001b72:	8bb2                	mv	s7,a2
    80001b74:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    80001b76:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001b78:	6985                	lui	s3,0x1
    80001b7a:	a02d                	j	80001ba4 <copyinstr+0x4e>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    80001b7c:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    80001b80:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    80001b82:	37fd                	addiw	a5,a5,-1
    80001b84:	0007851b          	sext.w	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    80001b88:	60a6                	ld	ra,72(sp)
    80001b8a:	6406                	ld	s0,64(sp)
    80001b8c:	74e2                	ld	s1,56(sp)
    80001b8e:	7942                	ld	s2,48(sp)
    80001b90:	79a2                	ld	s3,40(sp)
    80001b92:	7a02                	ld	s4,32(sp)
    80001b94:	6ae2                	ld	s5,24(sp)
    80001b96:	6b42                	ld	s6,16(sp)
    80001b98:	6ba2                	ld	s7,8(sp)
    80001b9a:	6161                	addi	sp,sp,80
    80001b9c:	8082                	ret
    srcva = va0 + PGSIZE;
    80001b9e:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    80001ba2:	c8a9                	beqz	s1,80001bf4 <copyinstr+0x9e>
    va0 = PGROUNDDOWN(srcva);
    80001ba4:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    80001ba8:	85ca                	mv	a1,s2
    80001baa:	8552                	mv	a0,s4
    80001bac:	00000097          	auipc	ra,0x0
    80001bb0:	8ca080e7          	jalr	-1846(ra) # 80001476 <walkaddr>
    if(pa0 == 0)
    80001bb4:	c131                	beqz	a0,80001bf8 <copyinstr+0xa2>
    n = PGSIZE - (srcva - va0);
    80001bb6:	417906b3          	sub	a3,s2,s7
    80001bba:	96ce                	add	a3,a3,s3
    80001bbc:	00d4f363          	bgeu	s1,a3,80001bc2 <copyinstr+0x6c>
    80001bc0:	86a6                	mv	a3,s1
    char *p = (char *) (pa0 + (srcva - va0));
    80001bc2:	955e                	add	a0,a0,s7
    80001bc4:	41250533          	sub	a0,a0,s2
    while(n > 0){
    80001bc8:	daf9                	beqz	a3,80001b9e <copyinstr+0x48>
    80001bca:	87da                	mv	a5,s6
      if(*p == '\0'){
    80001bcc:	41650633          	sub	a2,a0,s6
    80001bd0:	fff48593          	addi	a1,s1,-1
    80001bd4:	95da                	add	a1,a1,s6
    while(n > 0){
    80001bd6:	96da                	add	a3,a3,s6
      if(*p == '\0'){
    80001bd8:	00f60733          	add	a4,a2,a5
    80001bdc:	00074703          	lbu	a4,0(a4)
    80001be0:	df51                	beqz	a4,80001b7c <copyinstr+0x26>
        *dst = *p;
    80001be2:	00e78023          	sb	a4,0(a5)
      --max;
    80001be6:	40f584b3          	sub	s1,a1,a5
      dst++;
    80001bea:	0785                	addi	a5,a5,1
    while(n > 0){
    80001bec:	fed796e3          	bne	a5,a3,80001bd8 <copyinstr+0x82>
      dst++;
    80001bf0:	8b3e                	mv	s6,a5
    80001bf2:	b775                	j	80001b9e <copyinstr+0x48>
    80001bf4:	4781                	li	a5,0
    80001bf6:	b771                	j	80001b82 <copyinstr+0x2c>
      return -1;
    80001bf8:	557d                	li	a0,-1
    80001bfa:	b779                	j	80001b88 <copyinstr+0x32>
  int got_null = 0;
    80001bfc:	4781                	li	a5,0
  if(got_null){
    80001bfe:	37fd                	addiw	a5,a5,-1
    80001c00:	0007851b          	sext.w	a0,a5
}
    80001c04:	8082                	ret

0000000080001c06 <wakeup1>:

// Wake up p if it is sleeping in wait(); used by exit().
// Caller must hold p->lock.
static void
wakeup1(struct proc *p)
{
    80001c06:	1101                	addi	sp,sp,-32
    80001c08:	ec06                	sd	ra,24(sp)
    80001c0a:	e822                	sd	s0,16(sp)
    80001c0c:	e426                	sd	s1,8(sp)
    80001c0e:	1000                	addi	s0,sp,32
    80001c10:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001c12:	fffff097          	auipc	ra,0xfffff
    80001c16:	074080e7          	jalr	116(ra) # 80000c86 <holding>
    80001c1a:	c909                	beqz	a0,80001c2c <wakeup1+0x26>
    panic("wakeup1");
  if(p->chan == p && p->state == SLEEPING) {
    80001c1c:	789c                	ld	a5,48(s1)
    80001c1e:	00978f63          	beq	a5,s1,80001c3c <wakeup1+0x36>
    p->state = RUNNABLE;
  }
}
    80001c22:	60e2                	ld	ra,24(sp)
    80001c24:	6442                	ld	s0,16(sp)
    80001c26:	64a2                	ld	s1,8(sp)
    80001c28:	6105                	addi	sp,sp,32
    80001c2a:	8082                	ret
    panic("wakeup1");
    80001c2c:	00006517          	auipc	a0,0x6
    80001c30:	62c50513          	addi	a0,a0,1580 # 80008258 <digits+0x218>
    80001c34:	fffff097          	auipc	ra,0xfffff
    80001c38:	918080e7          	jalr	-1768(ra) # 8000054c <panic>
  if(p->chan == p && p->state == SLEEPING) {
    80001c3c:	5098                	lw	a4,32(s1)
    80001c3e:	4785                	li	a5,1
    80001c40:	fef711e3          	bne	a4,a5,80001c22 <wakeup1+0x1c>
    p->state = RUNNABLE;
    80001c44:	4789                	li	a5,2
    80001c46:	d09c                	sw	a5,32(s1)
}
    80001c48:	bfe9                	j	80001c22 <wakeup1+0x1c>

0000000080001c4a <procinit>:
{
    80001c4a:	715d                	addi	sp,sp,-80
    80001c4c:	e486                	sd	ra,72(sp)
    80001c4e:	e0a2                	sd	s0,64(sp)
    80001c50:	fc26                	sd	s1,56(sp)
    80001c52:	f84a                	sd	s2,48(sp)
    80001c54:	f44e                	sd	s3,40(sp)
    80001c56:	f052                	sd	s4,32(sp)
    80001c58:	ec56                	sd	s5,24(sp)
    80001c5a:	e85a                	sd	s6,16(sp)
    80001c5c:	e45e                	sd	s7,8(sp)
    80001c5e:	0880                	addi	s0,sp,80
  initlock(&pid_lock, "nextpid");
    80001c60:	00006597          	auipc	a1,0x6
    80001c64:	60058593          	addi	a1,a1,1536 # 80008260 <digits+0x220>
    80001c68:	00010517          	auipc	a0,0x10
    80001c6c:	72050513          	addi	a0,a0,1824 # 80012388 <pid_lock>
    80001c70:	fffff097          	auipc	ra,0xfffff
    80001c74:	20c080e7          	jalr	524(ra) # 80000e7c <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c78:	00011917          	auipc	s2,0x11
    80001c7c:	b3090913          	addi	s2,s2,-1232 # 800127a8 <proc>
      initlock(&p->lock, "proc");
    80001c80:	00006b97          	auipc	s7,0x6
    80001c84:	5e8b8b93          	addi	s7,s7,1512 # 80008268 <digits+0x228>
      uint64 va = KSTACK((int) (p - proc));
    80001c88:	8b4a                	mv	s6,s2
    80001c8a:	00006a97          	auipc	s5,0x6
    80001c8e:	376a8a93          	addi	s5,s5,886 # 80008000 <etext>
    80001c92:	040009b7          	lui	s3,0x4000
    80001c96:	19fd                	addi	s3,s3,-1 # 3ffffff <_entry-0x7c000001>
    80001c98:	09b2                	slli	s3,s3,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c9a:	00016a17          	auipc	s4,0x16
    80001c9e:	70ea0a13          	addi	s4,s4,1806 # 800183a8 <tickslock>
      initlock(&p->lock, "proc");
    80001ca2:	85de                	mv	a1,s7
    80001ca4:	854a                	mv	a0,s2
    80001ca6:	fffff097          	auipc	ra,0xfffff
    80001caa:	1d6080e7          	jalr	470(ra) # 80000e7c <initlock>
      char *pa = kalloc();
    80001cae:	fffff097          	auipc	ra,0xfffff
    80001cb2:	edc080e7          	jalr	-292(ra) # 80000b8a <kalloc>
    80001cb6:	85aa                	mv	a1,a0
      if(pa == 0)
    80001cb8:	c929                	beqz	a0,80001d0a <procinit+0xc0>
      uint64 va = KSTACK((int) (p - proc));
    80001cba:	416904b3          	sub	s1,s2,s6
    80001cbe:	8491                	srai	s1,s1,0x4
    80001cc0:	000ab783          	ld	a5,0(s5)
    80001cc4:	02f484b3          	mul	s1,s1,a5
    80001cc8:	2485                	addiw	s1,s1,1
    80001cca:	00d4949b          	slliw	s1,s1,0xd
    80001cce:	409984b3          	sub	s1,s3,s1
      kvmmap(va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001cd2:	4699                	li	a3,6
    80001cd4:	6605                	lui	a2,0x1
    80001cd6:	8526                	mv	a0,s1
    80001cd8:	00000097          	auipc	ra,0x0
    80001cdc:	86e080e7          	jalr	-1938(ra) # 80001546 <kvmmap>
      p->kstack = va;
    80001ce0:	04993423          	sd	s1,72(s2)
  for(p = proc; p < &proc[NPROC]; p++) {
    80001ce4:	17090913          	addi	s2,s2,368
    80001ce8:	fb491de3          	bne	s2,s4,80001ca2 <procinit+0x58>
  kvminithart();
    80001cec:	fffff097          	auipc	ra,0xfffff
    80001cf0:	766080e7          	jalr	1894(ra) # 80001452 <kvminithart>
}
    80001cf4:	60a6                	ld	ra,72(sp)
    80001cf6:	6406                	ld	s0,64(sp)
    80001cf8:	74e2                	ld	s1,56(sp)
    80001cfa:	7942                	ld	s2,48(sp)
    80001cfc:	79a2                	ld	s3,40(sp)
    80001cfe:	7a02                	ld	s4,32(sp)
    80001d00:	6ae2                	ld	s5,24(sp)
    80001d02:	6b42                	ld	s6,16(sp)
    80001d04:	6ba2                	ld	s7,8(sp)
    80001d06:	6161                	addi	sp,sp,80
    80001d08:	8082                	ret
        panic("kalloc");
    80001d0a:	00006517          	auipc	a0,0x6
    80001d0e:	56650513          	addi	a0,a0,1382 # 80008270 <digits+0x230>
    80001d12:	fffff097          	auipc	ra,0xfffff
    80001d16:	83a080e7          	jalr	-1990(ra) # 8000054c <panic>

0000000080001d1a <cpuid>:
{
    80001d1a:	1141                	addi	sp,sp,-16
    80001d1c:	e422                	sd	s0,8(sp)
    80001d1e:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001d20:	8512                	mv	a0,tp
}
    80001d22:	2501                	sext.w	a0,a0
    80001d24:	6422                	ld	s0,8(sp)
    80001d26:	0141                	addi	sp,sp,16
    80001d28:	8082                	ret

0000000080001d2a <mycpu>:
mycpu(void) {
    80001d2a:	1141                	addi	sp,sp,-16
    80001d2c:	e422                	sd	s0,8(sp)
    80001d2e:	0800                	addi	s0,sp,16
    80001d30:	8792                	mv	a5,tp
  struct cpu *c = &cpus[id];
    80001d32:	2781                	sext.w	a5,a5
    80001d34:	079e                	slli	a5,a5,0x7
}
    80001d36:	00010517          	auipc	a0,0x10
    80001d3a:	67250513          	addi	a0,a0,1650 # 800123a8 <cpus>
    80001d3e:	953e                	add	a0,a0,a5
    80001d40:	6422                	ld	s0,8(sp)
    80001d42:	0141                	addi	sp,sp,16
    80001d44:	8082                	ret

0000000080001d46 <myproc>:
myproc(void) {
    80001d46:	1101                	addi	sp,sp,-32
    80001d48:	ec06                	sd	ra,24(sp)
    80001d4a:	e822                	sd	s0,16(sp)
    80001d4c:	e426                	sd	s1,8(sp)
    80001d4e:	1000                	addi	s0,sp,32
  push_off();
    80001d50:	fffff097          	auipc	ra,0xfffff
    80001d54:	f64080e7          	jalr	-156(ra) # 80000cb4 <push_off>
    80001d58:	8792                	mv	a5,tp
  struct proc *p = c->proc;
    80001d5a:	2781                	sext.w	a5,a5
    80001d5c:	079e                	slli	a5,a5,0x7
    80001d5e:	00010717          	auipc	a4,0x10
    80001d62:	62a70713          	addi	a4,a4,1578 # 80012388 <pid_lock>
    80001d66:	97ba                	add	a5,a5,a4
    80001d68:	7384                	ld	s1,32(a5)
  pop_off();
    80001d6a:	fffff097          	auipc	ra,0xfffff
    80001d6e:	006080e7          	jalr	6(ra) # 80000d70 <pop_off>
}
    80001d72:	8526                	mv	a0,s1
    80001d74:	60e2                	ld	ra,24(sp)
    80001d76:	6442                	ld	s0,16(sp)
    80001d78:	64a2                	ld	s1,8(sp)
    80001d7a:	6105                	addi	sp,sp,32
    80001d7c:	8082                	ret

0000000080001d7e <forkret>:
{
    80001d7e:	1141                	addi	sp,sp,-16
    80001d80:	e406                	sd	ra,8(sp)
    80001d82:	e022                	sd	s0,0(sp)
    80001d84:	0800                	addi	s0,sp,16
  release(&myproc()->lock);
    80001d86:	00000097          	auipc	ra,0x0
    80001d8a:	fc0080e7          	jalr	-64(ra) # 80001d46 <myproc>
    80001d8e:	fffff097          	auipc	ra,0xfffff
    80001d92:	042080e7          	jalr	66(ra) # 80000dd0 <release>
  if (first) {
    80001d96:	00007797          	auipc	a5,0x7
    80001d9a:	b1a7a783          	lw	a5,-1254(a5) # 800088b0 <first.1>
    80001d9e:	eb89                	bnez	a5,80001db0 <forkret+0x32>
  usertrapret();
    80001da0:	00001097          	auipc	ra,0x1
    80001da4:	c1e080e7          	jalr	-994(ra) # 800029be <usertrapret>
}
    80001da8:	60a2                	ld	ra,8(sp)
    80001daa:	6402                	ld	s0,0(sp)
    80001dac:	0141                	addi	sp,sp,16
    80001dae:	8082                	ret
    first = 0;
    80001db0:	00007797          	auipc	a5,0x7
    80001db4:	b007a023          	sw	zero,-1280(a5) # 800088b0 <first.1>
    fsinit(ROOTDEV);
    80001db8:	4505                	li	a0,1
    80001dba:	00002097          	auipc	ra,0x2
    80001dbe:	944080e7          	jalr	-1724(ra) # 800036fe <fsinit>
    80001dc2:	bff9                	j	80001da0 <forkret+0x22>

0000000080001dc4 <allocpid>:
allocpid() {
    80001dc4:	1101                	addi	sp,sp,-32
    80001dc6:	ec06                	sd	ra,24(sp)
    80001dc8:	e822                	sd	s0,16(sp)
    80001dca:	e426                	sd	s1,8(sp)
    80001dcc:	e04a                	sd	s2,0(sp)
    80001dce:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001dd0:	00010917          	auipc	s2,0x10
    80001dd4:	5b890913          	addi	s2,s2,1464 # 80012388 <pid_lock>
    80001dd8:	854a                	mv	a0,s2
    80001dda:	fffff097          	auipc	ra,0xfffff
    80001dde:	f26080e7          	jalr	-218(ra) # 80000d00 <acquire>
  pid = nextpid;
    80001de2:	00007797          	auipc	a5,0x7
    80001de6:	ad278793          	addi	a5,a5,-1326 # 800088b4 <nextpid>
    80001dea:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001dec:	0014871b          	addiw	a4,s1,1
    80001df0:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001df2:	854a                	mv	a0,s2
    80001df4:	fffff097          	auipc	ra,0xfffff
    80001df8:	fdc080e7          	jalr	-36(ra) # 80000dd0 <release>
}
    80001dfc:	8526                	mv	a0,s1
    80001dfe:	60e2                	ld	ra,24(sp)
    80001e00:	6442                	ld	s0,16(sp)
    80001e02:	64a2                	ld	s1,8(sp)
    80001e04:	6902                	ld	s2,0(sp)
    80001e06:	6105                	addi	sp,sp,32
    80001e08:	8082                	ret

0000000080001e0a <proc_pagetable>:
{
    80001e0a:	1101                	addi	sp,sp,-32
    80001e0c:	ec06                	sd	ra,24(sp)
    80001e0e:	e822                	sd	s0,16(sp)
    80001e10:	e426                	sd	s1,8(sp)
    80001e12:	e04a                	sd	s2,0(sp)
    80001e14:	1000                	addi	s0,sp,32
    80001e16:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001e18:	00000097          	auipc	ra,0x0
    80001e1c:	8e8080e7          	jalr	-1816(ra) # 80001700 <uvmcreate>
    80001e20:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001e22:	c121                	beqz	a0,80001e62 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001e24:	4729                	li	a4,10
    80001e26:	00005697          	auipc	a3,0x5
    80001e2a:	1da68693          	addi	a3,a3,474 # 80007000 <_trampoline>
    80001e2e:	6605                	lui	a2,0x1
    80001e30:	040005b7          	lui	a1,0x4000
    80001e34:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001e36:	05b2                	slli	a1,a1,0xc
    80001e38:	fffff097          	auipc	ra,0xfffff
    80001e3c:	680080e7          	jalr	1664(ra) # 800014b8 <mappages>
    80001e40:	02054863          	bltz	a0,80001e70 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001e44:	4719                	li	a4,6
    80001e46:	06093683          	ld	a3,96(s2)
    80001e4a:	6605                	lui	a2,0x1
    80001e4c:	020005b7          	lui	a1,0x2000
    80001e50:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001e52:	05b6                	slli	a1,a1,0xd
    80001e54:	8526                	mv	a0,s1
    80001e56:	fffff097          	auipc	ra,0xfffff
    80001e5a:	662080e7          	jalr	1634(ra) # 800014b8 <mappages>
    80001e5e:	02054163          	bltz	a0,80001e80 <proc_pagetable+0x76>
}
    80001e62:	8526                	mv	a0,s1
    80001e64:	60e2                	ld	ra,24(sp)
    80001e66:	6442                	ld	s0,16(sp)
    80001e68:	64a2                	ld	s1,8(sp)
    80001e6a:	6902                	ld	s2,0(sp)
    80001e6c:	6105                	addi	sp,sp,32
    80001e6e:	8082                	ret
    uvmfree(pagetable, 0);
    80001e70:	4581                	li	a1,0
    80001e72:	8526                	mv	a0,s1
    80001e74:	00000097          	auipc	ra,0x0
    80001e78:	a8a080e7          	jalr	-1398(ra) # 800018fe <uvmfree>
    return 0;
    80001e7c:	4481                	li	s1,0
    80001e7e:	b7d5                	j	80001e62 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001e80:	4681                	li	a3,0
    80001e82:	4605                	li	a2,1
    80001e84:	040005b7          	lui	a1,0x4000
    80001e88:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001e8a:	05b2                	slli	a1,a1,0xc
    80001e8c:	8526                	mv	a0,s1
    80001e8e:	fffff097          	auipc	ra,0xfffff
    80001e92:	7ae080e7          	jalr	1966(ra) # 8000163c <uvmunmap>
    uvmfree(pagetable, 0);
    80001e96:	4581                	li	a1,0
    80001e98:	8526                	mv	a0,s1
    80001e9a:	00000097          	auipc	ra,0x0
    80001e9e:	a64080e7          	jalr	-1436(ra) # 800018fe <uvmfree>
    return 0;
    80001ea2:	4481                	li	s1,0
    80001ea4:	bf7d                	j	80001e62 <proc_pagetable+0x58>

0000000080001ea6 <proc_freepagetable>:
{
    80001ea6:	1101                	addi	sp,sp,-32
    80001ea8:	ec06                	sd	ra,24(sp)
    80001eaa:	e822                	sd	s0,16(sp)
    80001eac:	e426                	sd	s1,8(sp)
    80001eae:	e04a                	sd	s2,0(sp)
    80001eb0:	1000                	addi	s0,sp,32
    80001eb2:	84aa                	mv	s1,a0
    80001eb4:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001eb6:	4681                	li	a3,0
    80001eb8:	4605                	li	a2,1
    80001eba:	040005b7          	lui	a1,0x4000
    80001ebe:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001ec0:	05b2                	slli	a1,a1,0xc
    80001ec2:	fffff097          	auipc	ra,0xfffff
    80001ec6:	77a080e7          	jalr	1914(ra) # 8000163c <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001eca:	4681                	li	a3,0
    80001ecc:	4605                	li	a2,1
    80001ece:	020005b7          	lui	a1,0x2000
    80001ed2:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001ed4:	05b6                	slli	a1,a1,0xd
    80001ed6:	8526                	mv	a0,s1
    80001ed8:	fffff097          	auipc	ra,0xfffff
    80001edc:	764080e7          	jalr	1892(ra) # 8000163c <uvmunmap>
  uvmfree(pagetable, sz);
    80001ee0:	85ca                	mv	a1,s2
    80001ee2:	8526                	mv	a0,s1
    80001ee4:	00000097          	auipc	ra,0x0
    80001ee8:	a1a080e7          	jalr	-1510(ra) # 800018fe <uvmfree>
}
    80001eec:	60e2                	ld	ra,24(sp)
    80001eee:	6442                	ld	s0,16(sp)
    80001ef0:	64a2                	ld	s1,8(sp)
    80001ef2:	6902                	ld	s2,0(sp)
    80001ef4:	6105                	addi	sp,sp,32
    80001ef6:	8082                	ret

0000000080001ef8 <freeproc>:
{
    80001ef8:	1101                	addi	sp,sp,-32
    80001efa:	ec06                	sd	ra,24(sp)
    80001efc:	e822                	sd	s0,16(sp)
    80001efe:	e426                	sd	s1,8(sp)
    80001f00:	1000                	addi	s0,sp,32
    80001f02:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001f04:	7128                	ld	a0,96(a0)
    80001f06:	c509                	beqz	a0,80001f10 <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001f08:	fffff097          	auipc	ra,0xfffff
    80001f0c:	b10080e7          	jalr	-1264(ra) # 80000a18 <kfree>
  p->trapframe = 0;
    80001f10:	0604b023          	sd	zero,96(s1)
  if(p->pagetable)
    80001f14:	6ca8                	ld	a0,88(s1)
    80001f16:	c511                	beqz	a0,80001f22 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001f18:	68ac                	ld	a1,80(s1)
    80001f1a:	00000097          	auipc	ra,0x0
    80001f1e:	f8c080e7          	jalr	-116(ra) # 80001ea6 <proc_freepagetable>
  p->pagetable = 0;
    80001f22:	0404bc23          	sd	zero,88(s1)
  p->sz = 0;
    80001f26:	0404b823          	sd	zero,80(s1)
  p->pid = 0;
    80001f2a:	0404a023          	sw	zero,64(s1)
  p->parent = 0;
    80001f2e:	0204b423          	sd	zero,40(s1)
  p->name[0] = 0;
    80001f32:	16048023          	sb	zero,352(s1)
  p->chan = 0;
    80001f36:	0204b823          	sd	zero,48(s1)
  p->killed = 0;
    80001f3a:	0204ac23          	sw	zero,56(s1)
  p->xstate = 0;
    80001f3e:	0204ae23          	sw	zero,60(s1)
  p->state = UNUSED;
    80001f42:	0204a023          	sw	zero,32(s1)
}
    80001f46:	60e2                	ld	ra,24(sp)
    80001f48:	6442                	ld	s0,16(sp)
    80001f4a:	64a2                	ld	s1,8(sp)
    80001f4c:	6105                	addi	sp,sp,32
    80001f4e:	8082                	ret

0000000080001f50 <allocproc>:
{
    80001f50:	1101                	addi	sp,sp,-32
    80001f52:	ec06                	sd	ra,24(sp)
    80001f54:	e822                	sd	s0,16(sp)
    80001f56:	e426                	sd	s1,8(sp)
    80001f58:	e04a                	sd	s2,0(sp)
    80001f5a:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001f5c:	00011497          	auipc	s1,0x11
    80001f60:	84c48493          	addi	s1,s1,-1972 # 800127a8 <proc>
    80001f64:	00016917          	auipc	s2,0x16
    80001f68:	44490913          	addi	s2,s2,1092 # 800183a8 <tickslock>
    acquire(&p->lock);
    80001f6c:	8526                	mv	a0,s1
    80001f6e:	fffff097          	auipc	ra,0xfffff
    80001f72:	d92080e7          	jalr	-622(ra) # 80000d00 <acquire>
    if(p->state == UNUSED) {
    80001f76:	509c                	lw	a5,32(s1)
    80001f78:	cf81                	beqz	a5,80001f90 <allocproc+0x40>
      release(&p->lock);
    80001f7a:	8526                	mv	a0,s1
    80001f7c:	fffff097          	auipc	ra,0xfffff
    80001f80:	e54080e7          	jalr	-428(ra) # 80000dd0 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001f84:	17048493          	addi	s1,s1,368
    80001f88:	ff2492e3          	bne	s1,s2,80001f6c <allocproc+0x1c>
  return 0;
    80001f8c:	4481                	li	s1,0
    80001f8e:	a0b9                	j	80001fdc <allocproc+0x8c>
  p->pid = allocpid();
    80001f90:	00000097          	auipc	ra,0x0
    80001f94:	e34080e7          	jalr	-460(ra) # 80001dc4 <allocpid>
    80001f98:	c0a8                	sw	a0,64(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001f9a:	fffff097          	auipc	ra,0xfffff
    80001f9e:	bf0080e7          	jalr	-1040(ra) # 80000b8a <kalloc>
    80001fa2:	892a                	mv	s2,a0
    80001fa4:	f0a8                	sd	a0,96(s1)
    80001fa6:	c131                	beqz	a0,80001fea <allocproc+0x9a>
  p->pagetable = proc_pagetable(p);
    80001fa8:	8526                	mv	a0,s1
    80001faa:	00000097          	auipc	ra,0x0
    80001fae:	e60080e7          	jalr	-416(ra) # 80001e0a <proc_pagetable>
    80001fb2:	892a                	mv	s2,a0
    80001fb4:	eca8                	sd	a0,88(s1)
  if(p->pagetable == 0){
    80001fb6:	c129                	beqz	a0,80001ff8 <allocproc+0xa8>
  memset(&p->context, 0, sizeof(p->context));
    80001fb8:	07000613          	li	a2,112
    80001fbc:	4581                	li	a1,0
    80001fbe:	06848513          	addi	a0,s1,104
    80001fc2:	fffff097          	auipc	ra,0xfffff
    80001fc6:	11e080e7          	jalr	286(ra) # 800010e0 <memset>
  p->context.ra = (uint64)forkret;
    80001fca:	00000797          	auipc	a5,0x0
    80001fce:	db478793          	addi	a5,a5,-588 # 80001d7e <forkret>
    80001fd2:	f4bc                	sd	a5,104(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001fd4:	64bc                	ld	a5,72(s1)
    80001fd6:	6705                	lui	a4,0x1
    80001fd8:	97ba                	add	a5,a5,a4
    80001fda:	f8bc                	sd	a5,112(s1)
}
    80001fdc:	8526                	mv	a0,s1
    80001fde:	60e2                	ld	ra,24(sp)
    80001fe0:	6442                	ld	s0,16(sp)
    80001fe2:	64a2                	ld	s1,8(sp)
    80001fe4:	6902                	ld	s2,0(sp)
    80001fe6:	6105                	addi	sp,sp,32
    80001fe8:	8082                	ret
    release(&p->lock);
    80001fea:	8526                	mv	a0,s1
    80001fec:	fffff097          	auipc	ra,0xfffff
    80001ff0:	de4080e7          	jalr	-540(ra) # 80000dd0 <release>
    return 0;
    80001ff4:	84ca                	mv	s1,s2
    80001ff6:	b7dd                	j	80001fdc <allocproc+0x8c>
    freeproc(p);
    80001ff8:	8526                	mv	a0,s1
    80001ffa:	00000097          	auipc	ra,0x0
    80001ffe:	efe080e7          	jalr	-258(ra) # 80001ef8 <freeproc>
    release(&p->lock);
    80002002:	8526                	mv	a0,s1
    80002004:	fffff097          	auipc	ra,0xfffff
    80002008:	dcc080e7          	jalr	-564(ra) # 80000dd0 <release>
    return 0;
    8000200c:	84ca                	mv	s1,s2
    8000200e:	b7f9                	j	80001fdc <allocproc+0x8c>

0000000080002010 <userinit>:
{
    80002010:	1101                	addi	sp,sp,-32
    80002012:	ec06                	sd	ra,24(sp)
    80002014:	e822                	sd	s0,16(sp)
    80002016:	e426                	sd	s1,8(sp)
    80002018:	1000                	addi	s0,sp,32
  p = allocproc();
    8000201a:	00000097          	auipc	ra,0x0
    8000201e:	f36080e7          	jalr	-202(ra) # 80001f50 <allocproc>
    80002022:	84aa                	mv	s1,a0
  initproc = p;
    80002024:	00007797          	auipc	a5,0x7
    80002028:	fea7ba23          	sd	a0,-12(a5) # 80009018 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    8000202c:	03400613          	li	a2,52
    80002030:	00007597          	auipc	a1,0x7
    80002034:	89058593          	addi	a1,a1,-1904 # 800088c0 <initcode>
    80002038:	6d28                	ld	a0,88(a0)
    8000203a:	fffff097          	auipc	ra,0xfffff
    8000203e:	6f4080e7          	jalr	1780(ra) # 8000172e <uvminit>
  p->sz = PGSIZE;
    80002042:	6785                	lui	a5,0x1
    80002044:	e8bc                	sd	a5,80(s1)
  p->trapframe->epc = 0;      // user program counter
    80002046:	70b8                	ld	a4,96(s1)
    80002048:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    8000204c:	70b8                	ld	a4,96(s1)
    8000204e:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80002050:	4641                	li	a2,16
    80002052:	00006597          	auipc	a1,0x6
    80002056:	22658593          	addi	a1,a1,550 # 80008278 <digits+0x238>
    8000205a:	16048513          	addi	a0,s1,352
    8000205e:	fffff097          	auipc	ra,0xfffff
    80002062:	1d4080e7          	jalr	468(ra) # 80001232 <safestrcpy>
  p->cwd = namei("/");
    80002066:	00006517          	auipc	a0,0x6
    8000206a:	22250513          	addi	a0,a0,546 # 80008288 <digits+0x248>
    8000206e:	00002097          	auipc	ra,0x2
    80002072:	0c4080e7          	jalr	196(ra) # 80004132 <namei>
    80002076:	14a4bc23          	sd	a0,344(s1)
  p->state = RUNNABLE;
    8000207a:	4789                	li	a5,2
    8000207c:	d09c                	sw	a5,32(s1)
  release(&p->lock);
    8000207e:	8526                	mv	a0,s1
    80002080:	fffff097          	auipc	ra,0xfffff
    80002084:	d50080e7          	jalr	-688(ra) # 80000dd0 <release>
}
    80002088:	60e2                	ld	ra,24(sp)
    8000208a:	6442                	ld	s0,16(sp)
    8000208c:	64a2                	ld	s1,8(sp)
    8000208e:	6105                	addi	sp,sp,32
    80002090:	8082                	ret

0000000080002092 <growproc>:
{
    80002092:	1101                	addi	sp,sp,-32
    80002094:	ec06                	sd	ra,24(sp)
    80002096:	e822                	sd	s0,16(sp)
    80002098:	e426                	sd	s1,8(sp)
    8000209a:	e04a                	sd	s2,0(sp)
    8000209c:	1000                	addi	s0,sp,32
    8000209e:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    800020a0:	00000097          	auipc	ra,0x0
    800020a4:	ca6080e7          	jalr	-858(ra) # 80001d46 <myproc>
    800020a8:	892a                	mv	s2,a0
  sz = p->sz;
    800020aa:	692c                	ld	a1,80(a0)
    800020ac:	0005879b          	sext.w	a5,a1
  if(n > 0){
    800020b0:	00904f63          	bgtz	s1,800020ce <growproc+0x3c>
  } else if(n < 0){
    800020b4:	0204cd63          	bltz	s1,800020ee <growproc+0x5c>
  p->sz = sz;
    800020b8:	1782                	slli	a5,a5,0x20
    800020ba:	9381                	srli	a5,a5,0x20
    800020bc:	04f93823          	sd	a5,80(s2)
  return 0;
    800020c0:	4501                	li	a0,0
}
    800020c2:	60e2                	ld	ra,24(sp)
    800020c4:	6442                	ld	s0,16(sp)
    800020c6:	64a2                	ld	s1,8(sp)
    800020c8:	6902                	ld	s2,0(sp)
    800020ca:	6105                	addi	sp,sp,32
    800020cc:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    800020ce:	00f4863b          	addw	a2,s1,a5
    800020d2:	1602                	slli	a2,a2,0x20
    800020d4:	9201                	srli	a2,a2,0x20
    800020d6:	1582                	slli	a1,a1,0x20
    800020d8:	9181                	srli	a1,a1,0x20
    800020da:	6d28                	ld	a0,88(a0)
    800020dc:	fffff097          	auipc	ra,0xfffff
    800020e0:	70c080e7          	jalr	1804(ra) # 800017e8 <uvmalloc>
    800020e4:	0005079b          	sext.w	a5,a0
    800020e8:	fbe1                	bnez	a5,800020b8 <growproc+0x26>
      return -1;
    800020ea:	557d                	li	a0,-1
    800020ec:	bfd9                	j	800020c2 <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    800020ee:	00f4863b          	addw	a2,s1,a5
    800020f2:	1602                	slli	a2,a2,0x20
    800020f4:	9201                	srli	a2,a2,0x20
    800020f6:	1582                	slli	a1,a1,0x20
    800020f8:	9181                	srli	a1,a1,0x20
    800020fa:	6d28                	ld	a0,88(a0)
    800020fc:	fffff097          	auipc	ra,0xfffff
    80002100:	6a4080e7          	jalr	1700(ra) # 800017a0 <uvmdealloc>
    80002104:	0005079b          	sext.w	a5,a0
    80002108:	bf45                	j	800020b8 <growproc+0x26>

000000008000210a <fork>:
{
    8000210a:	7139                	addi	sp,sp,-64
    8000210c:	fc06                	sd	ra,56(sp)
    8000210e:	f822                	sd	s0,48(sp)
    80002110:	f426                	sd	s1,40(sp)
    80002112:	f04a                	sd	s2,32(sp)
    80002114:	ec4e                	sd	s3,24(sp)
    80002116:	e852                	sd	s4,16(sp)
    80002118:	e456                	sd	s5,8(sp)
    8000211a:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    8000211c:	00000097          	auipc	ra,0x0
    80002120:	c2a080e7          	jalr	-982(ra) # 80001d46 <myproc>
    80002124:	8aaa                	mv	s5,a0
  if((np = allocproc()) == 0){
    80002126:	00000097          	auipc	ra,0x0
    8000212a:	e2a080e7          	jalr	-470(ra) # 80001f50 <allocproc>
    8000212e:	c17d                	beqz	a0,80002214 <fork+0x10a>
    80002130:	8a2a                	mv	s4,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80002132:	050ab603          	ld	a2,80(s5)
    80002136:	6d2c                	ld	a1,88(a0)
    80002138:	058ab503          	ld	a0,88(s5)
    8000213c:	fffff097          	auipc	ra,0xfffff
    80002140:	7fc080e7          	jalr	2044(ra) # 80001938 <uvmcopy>
    80002144:	04054a63          	bltz	a0,80002198 <fork+0x8e>
  np->sz = p->sz;
    80002148:	050ab783          	ld	a5,80(s5)
    8000214c:	04fa3823          	sd	a5,80(s4)
  np->parent = p;
    80002150:	035a3423          	sd	s5,40(s4)
  *(np->trapframe) = *(p->trapframe);
    80002154:	060ab683          	ld	a3,96(s5)
    80002158:	87b6                	mv	a5,a3
    8000215a:	060a3703          	ld	a4,96(s4)
    8000215e:	12068693          	addi	a3,a3,288
    80002162:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80002166:	6788                	ld	a0,8(a5)
    80002168:	6b8c                	ld	a1,16(a5)
    8000216a:	6f90                	ld	a2,24(a5)
    8000216c:	01073023          	sd	a6,0(a4)
    80002170:	e708                	sd	a0,8(a4)
    80002172:	eb0c                	sd	a1,16(a4)
    80002174:	ef10                	sd	a2,24(a4)
    80002176:	02078793          	addi	a5,a5,32
    8000217a:	02070713          	addi	a4,a4,32
    8000217e:	fed792e3          	bne	a5,a3,80002162 <fork+0x58>
  np->trapframe->a0 = 0;
    80002182:	060a3783          	ld	a5,96(s4)
    80002186:	0607b823          	sd	zero,112(a5)
  for(i = 0; i < NOFILE; i++)
    8000218a:	0d8a8493          	addi	s1,s5,216
    8000218e:	0d8a0913          	addi	s2,s4,216
    80002192:	158a8993          	addi	s3,s5,344
    80002196:	a00d                	j	800021b8 <fork+0xae>
    freeproc(np);
    80002198:	8552                	mv	a0,s4
    8000219a:	00000097          	auipc	ra,0x0
    8000219e:	d5e080e7          	jalr	-674(ra) # 80001ef8 <freeproc>
    release(&np->lock);
    800021a2:	8552                	mv	a0,s4
    800021a4:	fffff097          	auipc	ra,0xfffff
    800021a8:	c2c080e7          	jalr	-980(ra) # 80000dd0 <release>
    return -1;
    800021ac:	54fd                	li	s1,-1
    800021ae:	a889                	j	80002200 <fork+0xf6>
  for(i = 0; i < NOFILE; i++)
    800021b0:	04a1                	addi	s1,s1,8
    800021b2:	0921                	addi	s2,s2,8
    800021b4:	01348b63          	beq	s1,s3,800021ca <fork+0xc0>
    if(p->ofile[i])
    800021b8:	6088                	ld	a0,0(s1)
    800021ba:	d97d                	beqz	a0,800021b0 <fork+0xa6>
      np->ofile[i] = filedup(p->ofile[i]);
    800021bc:	00002097          	auipc	ra,0x2
    800021c0:	614080e7          	jalr	1556(ra) # 800047d0 <filedup>
    800021c4:	00a93023          	sd	a0,0(s2)
    800021c8:	b7e5                	j	800021b0 <fork+0xa6>
  np->cwd = idup(p->cwd);
    800021ca:	158ab503          	ld	a0,344(s5)
    800021ce:	00001097          	auipc	ra,0x1
    800021d2:	76c080e7          	jalr	1900(ra) # 8000393a <idup>
    800021d6:	14aa3c23          	sd	a0,344(s4)
  safestrcpy(np->name, p->name, sizeof(p->name));
    800021da:	4641                	li	a2,16
    800021dc:	160a8593          	addi	a1,s5,352
    800021e0:	160a0513          	addi	a0,s4,352
    800021e4:	fffff097          	auipc	ra,0xfffff
    800021e8:	04e080e7          	jalr	78(ra) # 80001232 <safestrcpy>
  pid = np->pid;
    800021ec:	040a2483          	lw	s1,64(s4)
  np->state = RUNNABLE;
    800021f0:	4789                	li	a5,2
    800021f2:	02fa2023          	sw	a5,32(s4)
  release(&np->lock);
    800021f6:	8552                	mv	a0,s4
    800021f8:	fffff097          	auipc	ra,0xfffff
    800021fc:	bd8080e7          	jalr	-1064(ra) # 80000dd0 <release>
}
    80002200:	8526                	mv	a0,s1
    80002202:	70e2                	ld	ra,56(sp)
    80002204:	7442                	ld	s0,48(sp)
    80002206:	74a2                	ld	s1,40(sp)
    80002208:	7902                	ld	s2,32(sp)
    8000220a:	69e2                	ld	s3,24(sp)
    8000220c:	6a42                	ld	s4,16(sp)
    8000220e:	6aa2                	ld	s5,8(sp)
    80002210:	6121                	addi	sp,sp,64
    80002212:	8082                	ret
    return -1;
    80002214:	54fd                	li	s1,-1
    80002216:	b7ed                	j	80002200 <fork+0xf6>

0000000080002218 <reparent>:
{
    80002218:	7179                	addi	sp,sp,-48
    8000221a:	f406                	sd	ra,40(sp)
    8000221c:	f022                	sd	s0,32(sp)
    8000221e:	ec26                	sd	s1,24(sp)
    80002220:	e84a                	sd	s2,16(sp)
    80002222:	e44e                	sd	s3,8(sp)
    80002224:	e052                	sd	s4,0(sp)
    80002226:	1800                	addi	s0,sp,48
    80002228:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    8000222a:	00010497          	auipc	s1,0x10
    8000222e:	57e48493          	addi	s1,s1,1406 # 800127a8 <proc>
      pp->parent = initproc;
    80002232:	00007a17          	auipc	s4,0x7
    80002236:	de6a0a13          	addi	s4,s4,-538 # 80009018 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    8000223a:	00016997          	auipc	s3,0x16
    8000223e:	16e98993          	addi	s3,s3,366 # 800183a8 <tickslock>
    80002242:	a029                	j	8000224c <reparent+0x34>
    80002244:	17048493          	addi	s1,s1,368
    80002248:	03348363          	beq	s1,s3,8000226e <reparent+0x56>
    if(pp->parent == p){
    8000224c:	749c                	ld	a5,40(s1)
    8000224e:	ff279be3          	bne	a5,s2,80002244 <reparent+0x2c>
      acquire(&pp->lock);
    80002252:	8526                	mv	a0,s1
    80002254:	fffff097          	auipc	ra,0xfffff
    80002258:	aac080e7          	jalr	-1364(ra) # 80000d00 <acquire>
      pp->parent = initproc;
    8000225c:	000a3783          	ld	a5,0(s4)
    80002260:	f49c                	sd	a5,40(s1)
      release(&pp->lock);
    80002262:	8526                	mv	a0,s1
    80002264:	fffff097          	auipc	ra,0xfffff
    80002268:	b6c080e7          	jalr	-1172(ra) # 80000dd0 <release>
    8000226c:	bfe1                	j	80002244 <reparent+0x2c>
}
    8000226e:	70a2                	ld	ra,40(sp)
    80002270:	7402                	ld	s0,32(sp)
    80002272:	64e2                	ld	s1,24(sp)
    80002274:	6942                	ld	s2,16(sp)
    80002276:	69a2                	ld	s3,8(sp)
    80002278:	6a02                	ld	s4,0(sp)
    8000227a:	6145                	addi	sp,sp,48
    8000227c:	8082                	ret

000000008000227e <scheduler>:
{
    8000227e:	711d                	addi	sp,sp,-96
    80002280:	ec86                	sd	ra,88(sp)
    80002282:	e8a2                	sd	s0,80(sp)
    80002284:	e4a6                	sd	s1,72(sp)
    80002286:	e0ca                	sd	s2,64(sp)
    80002288:	fc4e                	sd	s3,56(sp)
    8000228a:	f852                	sd	s4,48(sp)
    8000228c:	f456                	sd	s5,40(sp)
    8000228e:	f05a                	sd	s6,32(sp)
    80002290:	ec5e                	sd	s7,24(sp)
    80002292:	e862                	sd	s8,16(sp)
    80002294:	e466                	sd	s9,8(sp)
    80002296:	1080                	addi	s0,sp,96
    80002298:	8792                	mv	a5,tp
  int id = r_tp();
    8000229a:	2781                	sext.w	a5,a5
  c->proc = 0;
    8000229c:	00779c13          	slli	s8,a5,0x7
    800022a0:	00010717          	auipc	a4,0x10
    800022a4:	0e870713          	addi	a4,a4,232 # 80012388 <pid_lock>
    800022a8:	9762                	add	a4,a4,s8
    800022aa:	02073023          	sd	zero,32(a4)
        swtch(&c->context, &p->context);
    800022ae:	00010717          	auipc	a4,0x10
    800022b2:	10270713          	addi	a4,a4,258 # 800123b0 <cpus+0x8>
    800022b6:	9c3a                	add	s8,s8,a4
    int nproc = 0;
    800022b8:	4c81                	li	s9,0
      if(p->state == RUNNABLE) {
    800022ba:	4a89                	li	s5,2
        c->proc = p;
    800022bc:	079e                	slli	a5,a5,0x7
    800022be:	00010b17          	auipc	s6,0x10
    800022c2:	0cab0b13          	addi	s6,s6,202 # 80012388 <pid_lock>
    800022c6:	9b3e                	add	s6,s6,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    800022c8:	00016a17          	auipc	s4,0x16
    800022cc:	0e0a0a13          	addi	s4,s4,224 # 800183a8 <tickslock>
    800022d0:	a8a1                	j	80002328 <scheduler+0xaa>
      release(&p->lock);
    800022d2:	8526                	mv	a0,s1
    800022d4:	fffff097          	auipc	ra,0xfffff
    800022d8:	afc080e7          	jalr	-1284(ra) # 80000dd0 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    800022dc:	17048493          	addi	s1,s1,368
    800022e0:	03448a63          	beq	s1,s4,80002314 <scheduler+0x96>
      acquire(&p->lock);
    800022e4:	8526                	mv	a0,s1
    800022e6:	fffff097          	auipc	ra,0xfffff
    800022ea:	a1a080e7          	jalr	-1510(ra) # 80000d00 <acquire>
      if(p->state != UNUSED) {
    800022ee:	509c                	lw	a5,32(s1)
    800022f0:	d3ed                	beqz	a5,800022d2 <scheduler+0x54>
        nproc++;
    800022f2:	2985                	addiw	s3,s3,1
      if(p->state == RUNNABLE) {
    800022f4:	fd579fe3          	bne	a5,s5,800022d2 <scheduler+0x54>
        p->state = RUNNING;
    800022f8:	0374a023          	sw	s7,32(s1)
        c->proc = p;
    800022fc:	029b3023          	sd	s1,32(s6)
        swtch(&c->context, &p->context);
    80002300:	06848593          	addi	a1,s1,104
    80002304:	8562                	mv	a0,s8
    80002306:	00000097          	auipc	ra,0x0
    8000230a:	60e080e7          	jalr	1550(ra) # 80002914 <swtch>
        c->proc = 0;
    8000230e:	020b3023          	sd	zero,32(s6)
    80002312:	b7c1                	j	800022d2 <scheduler+0x54>
    if(nproc <= 2) {   // only init and sh exist
    80002314:	013aca63          	blt	s5,s3,80002328 <scheduler+0xaa>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002318:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000231c:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002320:	10079073          	csrw	sstatus,a5
      asm volatile("wfi");
    80002324:	10500073          	wfi
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002328:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000232c:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002330:	10079073          	csrw	sstatus,a5
    int nproc = 0;
    80002334:	89e6                	mv	s3,s9
    for(p = proc; p < &proc[NPROC]; p++) {
    80002336:	00010497          	auipc	s1,0x10
    8000233a:	47248493          	addi	s1,s1,1138 # 800127a8 <proc>
        p->state = RUNNING;
    8000233e:	4b8d                	li	s7,3
    80002340:	b755                	j	800022e4 <scheduler+0x66>

0000000080002342 <sched>:
{
    80002342:	7179                	addi	sp,sp,-48
    80002344:	f406                	sd	ra,40(sp)
    80002346:	f022                	sd	s0,32(sp)
    80002348:	ec26                	sd	s1,24(sp)
    8000234a:	e84a                	sd	s2,16(sp)
    8000234c:	e44e                	sd	s3,8(sp)
    8000234e:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80002350:	00000097          	auipc	ra,0x0
    80002354:	9f6080e7          	jalr	-1546(ra) # 80001d46 <myproc>
    80002358:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    8000235a:	fffff097          	auipc	ra,0xfffff
    8000235e:	92c080e7          	jalr	-1748(ra) # 80000c86 <holding>
    80002362:	c93d                	beqz	a0,800023d8 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002364:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80002366:	2781                	sext.w	a5,a5
    80002368:	079e                	slli	a5,a5,0x7
    8000236a:	00010717          	auipc	a4,0x10
    8000236e:	01e70713          	addi	a4,a4,30 # 80012388 <pid_lock>
    80002372:	97ba                	add	a5,a5,a4
    80002374:	0987a703          	lw	a4,152(a5)
    80002378:	4785                	li	a5,1
    8000237a:	06f71763          	bne	a4,a5,800023e8 <sched+0xa6>
  if(p->state == RUNNING)
    8000237e:	5098                	lw	a4,32(s1)
    80002380:	478d                	li	a5,3
    80002382:	06f70b63          	beq	a4,a5,800023f8 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002386:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    8000238a:	8b89                	andi	a5,a5,2
  if(intr_get())
    8000238c:	efb5                	bnez	a5,80002408 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    8000238e:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80002390:	00010917          	auipc	s2,0x10
    80002394:	ff890913          	addi	s2,s2,-8 # 80012388 <pid_lock>
    80002398:	2781                	sext.w	a5,a5
    8000239a:	079e                	slli	a5,a5,0x7
    8000239c:	97ca                	add	a5,a5,s2
    8000239e:	09c7a983          	lw	s3,156(a5)
    800023a2:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    800023a4:	2781                	sext.w	a5,a5
    800023a6:	079e                	slli	a5,a5,0x7
    800023a8:	00010597          	auipc	a1,0x10
    800023ac:	00858593          	addi	a1,a1,8 # 800123b0 <cpus+0x8>
    800023b0:	95be                	add	a1,a1,a5
    800023b2:	06848513          	addi	a0,s1,104
    800023b6:	00000097          	auipc	ra,0x0
    800023ba:	55e080e7          	jalr	1374(ra) # 80002914 <swtch>
    800023be:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    800023c0:	2781                	sext.w	a5,a5
    800023c2:	079e                	slli	a5,a5,0x7
    800023c4:	993e                	add	s2,s2,a5
    800023c6:	09392e23          	sw	s3,156(s2)
}
    800023ca:	70a2                	ld	ra,40(sp)
    800023cc:	7402                	ld	s0,32(sp)
    800023ce:	64e2                	ld	s1,24(sp)
    800023d0:	6942                	ld	s2,16(sp)
    800023d2:	69a2                	ld	s3,8(sp)
    800023d4:	6145                	addi	sp,sp,48
    800023d6:	8082                	ret
    panic("sched p->lock");
    800023d8:	00006517          	auipc	a0,0x6
    800023dc:	eb850513          	addi	a0,a0,-328 # 80008290 <digits+0x250>
    800023e0:	ffffe097          	auipc	ra,0xffffe
    800023e4:	16c080e7          	jalr	364(ra) # 8000054c <panic>
    panic("sched locks");
    800023e8:	00006517          	auipc	a0,0x6
    800023ec:	eb850513          	addi	a0,a0,-328 # 800082a0 <digits+0x260>
    800023f0:	ffffe097          	auipc	ra,0xffffe
    800023f4:	15c080e7          	jalr	348(ra) # 8000054c <panic>
    panic("sched running");
    800023f8:	00006517          	auipc	a0,0x6
    800023fc:	eb850513          	addi	a0,a0,-328 # 800082b0 <digits+0x270>
    80002400:	ffffe097          	auipc	ra,0xffffe
    80002404:	14c080e7          	jalr	332(ra) # 8000054c <panic>
    panic("sched interruptible");
    80002408:	00006517          	auipc	a0,0x6
    8000240c:	eb850513          	addi	a0,a0,-328 # 800082c0 <digits+0x280>
    80002410:	ffffe097          	auipc	ra,0xffffe
    80002414:	13c080e7          	jalr	316(ra) # 8000054c <panic>

0000000080002418 <exit>:
{
    80002418:	7179                	addi	sp,sp,-48
    8000241a:	f406                	sd	ra,40(sp)
    8000241c:	f022                	sd	s0,32(sp)
    8000241e:	ec26                	sd	s1,24(sp)
    80002420:	e84a                	sd	s2,16(sp)
    80002422:	e44e                	sd	s3,8(sp)
    80002424:	e052                	sd	s4,0(sp)
    80002426:	1800                	addi	s0,sp,48
    80002428:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    8000242a:	00000097          	auipc	ra,0x0
    8000242e:	91c080e7          	jalr	-1764(ra) # 80001d46 <myproc>
    80002432:	89aa                	mv	s3,a0
  if(p == initproc)
    80002434:	00007797          	auipc	a5,0x7
    80002438:	be47b783          	ld	a5,-1052(a5) # 80009018 <initproc>
    8000243c:	0d850493          	addi	s1,a0,216
    80002440:	15850913          	addi	s2,a0,344
    80002444:	02a79363          	bne	a5,a0,8000246a <exit+0x52>
    panic("init exiting");
    80002448:	00006517          	auipc	a0,0x6
    8000244c:	e9050513          	addi	a0,a0,-368 # 800082d8 <digits+0x298>
    80002450:	ffffe097          	auipc	ra,0xffffe
    80002454:	0fc080e7          	jalr	252(ra) # 8000054c <panic>
      fileclose(f);
    80002458:	00002097          	auipc	ra,0x2
    8000245c:	3ca080e7          	jalr	970(ra) # 80004822 <fileclose>
      p->ofile[fd] = 0;
    80002460:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    80002464:	04a1                	addi	s1,s1,8
    80002466:	01248563          	beq	s1,s2,80002470 <exit+0x58>
    if(p->ofile[fd]){
    8000246a:	6088                	ld	a0,0(s1)
    8000246c:	f575                	bnez	a0,80002458 <exit+0x40>
    8000246e:	bfdd                	j	80002464 <exit+0x4c>
  begin_op();
    80002470:	00002097          	auipc	ra,0x2
    80002474:	ee2080e7          	jalr	-286(ra) # 80004352 <begin_op>
  iput(p->cwd);
    80002478:	1589b503          	ld	a0,344(s3)
    8000247c:	00001097          	auipc	ra,0x1
    80002480:	6b6080e7          	jalr	1718(ra) # 80003b32 <iput>
  end_op();
    80002484:	00002097          	auipc	ra,0x2
    80002488:	f4c080e7          	jalr	-180(ra) # 800043d0 <end_op>
  p->cwd = 0;
    8000248c:	1409bc23          	sd	zero,344(s3)
  acquire(&initproc->lock);
    80002490:	00007497          	auipc	s1,0x7
    80002494:	b8848493          	addi	s1,s1,-1144 # 80009018 <initproc>
    80002498:	6088                	ld	a0,0(s1)
    8000249a:	fffff097          	auipc	ra,0xfffff
    8000249e:	866080e7          	jalr	-1946(ra) # 80000d00 <acquire>
  wakeup1(initproc);
    800024a2:	6088                	ld	a0,0(s1)
    800024a4:	fffff097          	auipc	ra,0xfffff
    800024a8:	762080e7          	jalr	1890(ra) # 80001c06 <wakeup1>
  release(&initproc->lock);
    800024ac:	6088                	ld	a0,0(s1)
    800024ae:	fffff097          	auipc	ra,0xfffff
    800024b2:	922080e7          	jalr	-1758(ra) # 80000dd0 <release>
  acquire(&p->lock);
    800024b6:	854e                	mv	a0,s3
    800024b8:	fffff097          	auipc	ra,0xfffff
    800024bc:	848080e7          	jalr	-1976(ra) # 80000d00 <acquire>
  struct proc *original_parent = p->parent;
    800024c0:	0289b483          	ld	s1,40(s3)
  release(&p->lock);
    800024c4:	854e                	mv	a0,s3
    800024c6:	fffff097          	auipc	ra,0xfffff
    800024ca:	90a080e7          	jalr	-1782(ra) # 80000dd0 <release>
  acquire(&original_parent->lock);
    800024ce:	8526                	mv	a0,s1
    800024d0:	fffff097          	auipc	ra,0xfffff
    800024d4:	830080e7          	jalr	-2000(ra) # 80000d00 <acquire>
  acquire(&p->lock);
    800024d8:	854e                	mv	a0,s3
    800024da:	fffff097          	auipc	ra,0xfffff
    800024de:	826080e7          	jalr	-2010(ra) # 80000d00 <acquire>
  reparent(p);
    800024e2:	854e                	mv	a0,s3
    800024e4:	00000097          	auipc	ra,0x0
    800024e8:	d34080e7          	jalr	-716(ra) # 80002218 <reparent>
  wakeup1(original_parent);
    800024ec:	8526                	mv	a0,s1
    800024ee:	fffff097          	auipc	ra,0xfffff
    800024f2:	718080e7          	jalr	1816(ra) # 80001c06 <wakeup1>
  p->xstate = status;
    800024f6:	0349ae23          	sw	s4,60(s3)
  p->state = ZOMBIE;
    800024fa:	4791                	li	a5,4
    800024fc:	02f9a023          	sw	a5,32(s3)
  release(&original_parent->lock);
    80002500:	8526                	mv	a0,s1
    80002502:	fffff097          	auipc	ra,0xfffff
    80002506:	8ce080e7          	jalr	-1842(ra) # 80000dd0 <release>
  sched();
    8000250a:	00000097          	auipc	ra,0x0
    8000250e:	e38080e7          	jalr	-456(ra) # 80002342 <sched>
  panic("zombie exit");
    80002512:	00006517          	auipc	a0,0x6
    80002516:	dd650513          	addi	a0,a0,-554 # 800082e8 <digits+0x2a8>
    8000251a:	ffffe097          	auipc	ra,0xffffe
    8000251e:	032080e7          	jalr	50(ra) # 8000054c <panic>

0000000080002522 <yield>:
{
    80002522:	1101                	addi	sp,sp,-32
    80002524:	ec06                	sd	ra,24(sp)
    80002526:	e822                	sd	s0,16(sp)
    80002528:	e426                	sd	s1,8(sp)
    8000252a:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    8000252c:	00000097          	auipc	ra,0x0
    80002530:	81a080e7          	jalr	-2022(ra) # 80001d46 <myproc>
    80002534:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002536:	ffffe097          	auipc	ra,0xffffe
    8000253a:	7ca080e7          	jalr	1994(ra) # 80000d00 <acquire>
  p->state = RUNNABLE;
    8000253e:	4789                	li	a5,2
    80002540:	d09c                	sw	a5,32(s1)
  sched();
    80002542:	00000097          	auipc	ra,0x0
    80002546:	e00080e7          	jalr	-512(ra) # 80002342 <sched>
  release(&p->lock);
    8000254a:	8526                	mv	a0,s1
    8000254c:	fffff097          	auipc	ra,0xfffff
    80002550:	884080e7          	jalr	-1916(ra) # 80000dd0 <release>
}
    80002554:	60e2                	ld	ra,24(sp)
    80002556:	6442                	ld	s0,16(sp)
    80002558:	64a2                	ld	s1,8(sp)
    8000255a:	6105                	addi	sp,sp,32
    8000255c:	8082                	ret

000000008000255e <sleep>:
{
    8000255e:	7179                	addi	sp,sp,-48
    80002560:	f406                	sd	ra,40(sp)
    80002562:	f022                	sd	s0,32(sp)
    80002564:	ec26                	sd	s1,24(sp)
    80002566:	e84a                	sd	s2,16(sp)
    80002568:	e44e                	sd	s3,8(sp)
    8000256a:	1800                	addi	s0,sp,48
    8000256c:	89aa                	mv	s3,a0
    8000256e:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002570:	fffff097          	auipc	ra,0xfffff
    80002574:	7d6080e7          	jalr	2006(ra) # 80001d46 <myproc>
    80002578:	84aa                	mv	s1,a0
  if(lk != &p->lock){  //DOC: sleeplock0
    8000257a:	05250663          	beq	a0,s2,800025c6 <sleep+0x68>
    acquire(&p->lock);  //DOC: sleeplock1
    8000257e:	ffffe097          	auipc	ra,0xffffe
    80002582:	782080e7          	jalr	1922(ra) # 80000d00 <acquire>
    release(lk);
    80002586:	854a                	mv	a0,s2
    80002588:	fffff097          	auipc	ra,0xfffff
    8000258c:	848080e7          	jalr	-1976(ra) # 80000dd0 <release>
  p->chan = chan;
    80002590:	0334b823          	sd	s3,48(s1)
  p->state = SLEEPING;
    80002594:	4785                	li	a5,1
    80002596:	d09c                	sw	a5,32(s1)
  sched();
    80002598:	00000097          	auipc	ra,0x0
    8000259c:	daa080e7          	jalr	-598(ra) # 80002342 <sched>
  p->chan = 0;
    800025a0:	0204b823          	sd	zero,48(s1)
    release(&p->lock);
    800025a4:	8526                	mv	a0,s1
    800025a6:	fffff097          	auipc	ra,0xfffff
    800025aa:	82a080e7          	jalr	-2006(ra) # 80000dd0 <release>
    acquire(lk);
    800025ae:	854a                	mv	a0,s2
    800025b0:	ffffe097          	auipc	ra,0xffffe
    800025b4:	750080e7          	jalr	1872(ra) # 80000d00 <acquire>
}
    800025b8:	70a2                	ld	ra,40(sp)
    800025ba:	7402                	ld	s0,32(sp)
    800025bc:	64e2                	ld	s1,24(sp)
    800025be:	6942                	ld	s2,16(sp)
    800025c0:	69a2                	ld	s3,8(sp)
    800025c2:	6145                	addi	sp,sp,48
    800025c4:	8082                	ret
  p->chan = chan;
    800025c6:	03353823          	sd	s3,48(a0)
  p->state = SLEEPING;
    800025ca:	4785                	li	a5,1
    800025cc:	d11c                	sw	a5,32(a0)
  sched();
    800025ce:	00000097          	auipc	ra,0x0
    800025d2:	d74080e7          	jalr	-652(ra) # 80002342 <sched>
  p->chan = 0;
    800025d6:	0204b823          	sd	zero,48(s1)
  if(lk != &p->lock){
    800025da:	bff9                	j	800025b8 <sleep+0x5a>

00000000800025dc <wait>:
{
    800025dc:	715d                	addi	sp,sp,-80
    800025de:	e486                	sd	ra,72(sp)
    800025e0:	e0a2                	sd	s0,64(sp)
    800025e2:	fc26                	sd	s1,56(sp)
    800025e4:	f84a                	sd	s2,48(sp)
    800025e6:	f44e                	sd	s3,40(sp)
    800025e8:	f052                	sd	s4,32(sp)
    800025ea:	ec56                	sd	s5,24(sp)
    800025ec:	e85a                	sd	s6,16(sp)
    800025ee:	e45e                	sd	s7,8(sp)
    800025f0:	0880                	addi	s0,sp,80
    800025f2:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800025f4:	fffff097          	auipc	ra,0xfffff
    800025f8:	752080e7          	jalr	1874(ra) # 80001d46 <myproc>
    800025fc:	892a                	mv	s2,a0
  acquire(&p->lock);
    800025fe:	ffffe097          	auipc	ra,0xffffe
    80002602:	702080e7          	jalr	1794(ra) # 80000d00 <acquire>
    havekids = 0;
    80002606:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    80002608:	4a11                	li	s4,4
        havekids = 1;
    8000260a:	4a85                	li	s5,1
    for(np = proc; np < &proc[NPROC]; np++){
    8000260c:	00016997          	auipc	s3,0x16
    80002610:	d9c98993          	addi	s3,s3,-612 # 800183a8 <tickslock>
    havekids = 0;
    80002614:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    80002616:	00010497          	auipc	s1,0x10
    8000261a:	19248493          	addi	s1,s1,402 # 800127a8 <proc>
    8000261e:	a08d                	j	80002680 <wait+0xa4>
          pid = np->pid;
    80002620:	0404a983          	lw	s3,64(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002624:	000b0e63          	beqz	s6,80002640 <wait+0x64>
    80002628:	4691                	li	a3,4
    8000262a:	03c48613          	addi	a2,s1,60
    8000262e:	85da                	mv	a1,s6
    80002630:	05893503          	ld	a0,88(s2)
    80002634:	fffff097          	auipc	ra,0xfffff
    80002638:	408080e7          	jalr	1032(ra) # 80001a3c <copyout>
    8000263c:	02054263          	bltz	a0,80002660 <wait+0x84>
          freeproc(np);
    80002640:	8526                	mv	a0,s1
    80002642:	00000097          	auipc	ra,0x0
    80002646:	8b6080e7          	jalr	-1866(ra) # 80001ef8 <freeproc>
          release(&np->lock);
    8000264a:	8526                	mv	a0,s1
    8000264c:	ffffe097          	auipc	ra,0xffffe
    80002650:	784080e7          	jalr	1924(ra) # 80000dd0 <release>
          release(&p->lock);
    80002654:	854a                	mv	a0,s2
    80002656:	ffffe097          	auipc	ra,0xffffe
    8000265a:	77a080e7          	jalr	1914(ra) # 80000dd0 <release>
          return pid;
    8000265e:	a8a9                	j	800026b8 <wait+0xdc>
            release(&np->lock);
    80002660:	8526                	mv	a0,s1
    80002662:	ffffe097          	auipc	ra,0xffffe
    80002666:	76e080e7          	jalr	1902(ra) # 80000dd0 <release>
            release(&p->lock);
    8000266a:	854a                	mv	a0,s2
    8000266c:	ffffe097          	auipc	ra,0xffffe
    80002670:	764080e7          	jalr	1892(ra) # 80000dd0 <release>
            return -1;
    80002674:	59fd                	li	s3,-1
    80002676:	a089                	j	800026b8 <wait+0xdc>
    for(np = proc; np < &proc[NPROC]; np++){
    80002678:	17048493          	addi	s1,s1,368
    8000267c:	03348463          	beq	s1,s3,800026a4 <wait+0xc8>
      if(np->parent == p){
    80002680:	749c                	ld	a5,40(s1)
    80002682:	ff279be3          	bne	a5,s2,80002678 <wait+0x9c>
        acquire(&np->lock);
    80002686:	8526                	mv	a0,s1
    80002688:	ffffe097          	auipc	ra,0xffffe
    8000268c:	678080e7          	jalr	1656(ra) # 80000d00 <acquire>
        if(np->state == ZOMBIE){
    80002690:	509c                	lw	a5,32(s1)
    80002692:	f94787e3          	beq	a5,s4,80002620 <wait+0x44>
        release(&np->lock);
    80002696:	8526                	mv	a0,s1
    80002698:	ffffe097          	auipc	ra,0xffffe
    8000269c:	738080e7          	jalr	1848(ra) # 80000dd0 <release>
        havekids = 1;
    800026a0:	8756                	mv	a4,s5
    800026a2:	bfd9                	j	80002678 <wait+0x9c>
    if(!havekids || p->killed){
    800026a4:	c701                	beqz	a4,800026ac <wait+0xd0>
    800026a6:	03892783          	lw	a5,56(s2)
    800026aa:	c39d                	beqz	a5,800026d0 <wait+0xf4>
      release(&p->lock);
    800026ac:	854a                	mv	a0,s2
    800026ae:	ffffe097          	auipc	ra,0xffffe
    800026b2:	722080e7          	jalr	1826(ra) # 80000dd0 <release>
      return -1;
    800026b6:	59fd                	li	s3,-1
}
    800026b8:	854e                	mv	a0,s3
    800026ba:	60a6                	ld	ra,72(sp)
    800026bc:	6406                	ld	s0,64(sp)
    800026be:	74e2                	ld	s1,56(sp)
    800026c0:	7942                	ld	s2,48(sp)
    800026c2:	79a2                	ld	s3,40(sp)
    800026c4:	7a02                	ld	s4,32(sp)
    800026c6:	6ae2                	ld	s5,24(sp)
    800026c8:	6b42                	ld	s6,16(sp)
    800026ca:	6ba2                	ld	s7,8(sp)
    800026cc:	6161                	addi	sp,sp,80
    800026ce:	8082                	ret
    sleep(p, &p->lock);  //DOC: wait-sleep
    800026d0:	85ca                	mv	a1,s2
    800026d2:	854a                	mv	a0,s2
    800026d4:	00000097          	auipc	ra,0x0
    800026d8:	e8a080e7          	jalr	-374(ra) # 8000255e <sleep>
    havekids = 0;
    800026dc:	bf25                	j	80002614 <wait+0x38>

00000000800026de <wakeup>:
{
    800026de:	7139                	addi	sp,sp,-64
    800026e0:	fc06                	sd	ra,56(sp)
    800026e2:	f822                	sd	s0,48(sp)
    800026e4:	f426                	sd	s1,40(sp)
    800026e6:	f04a                	sd	s2,32(sp)
    800026e8:	ec4e                	sd	s3,24(sp)
    800026ea:	e852                	sd	s4,16(sp)
    800026ec:	e456                	sd	s5,8(sp)
    800026ee:	0080                	addi	s0,sp,64
    800026f0:	8a2a                	mv	s4,a0
  for(p = proc; p < &proc[NPROC]; p++) {
    800026f2:	00010497          	auipc	s1,0x10
    800026f6:	0b648493          	addi	s1,s1,182 # 800127a8 <proc>
    if(p->state == SLEEPING && p->chan == chan) {
    800026fa:	4985                	li	s3,1
      p->state = RUNNABLE;
    800026fc:	4a89                	li	s5,2
  for(p = proc; p < &proc[NPROC]; p++) {
    800026fe:	00016917          	auipc	s2,0x16
    80002702:	caa90913          	addi	s2,s2,-854 # 800183a8 <tickslock>
    80002706:	a811                	j	8000271a <wakeup+0x3c>
    release(&p->lock);
    80002708:	8526                	mv	a0,s1
    8000270a:	ffffe097          	auipc	ra,0xffffe
    8000270e:	6c6080e7          	jalr	1734(ra) # 80000dd0 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80002712:	17048493          	addi	s1,s1,368
    80002716:	03248063          	beq	s1,s2,80002736 <wakeup+0x58>
    acquire(&p->lock);
    8000271a:	8526                	mv	a0,s1
    8000271c:	ffffe097          	auipc	ra,0xffffe
    80002720:	5e4080e7          	jalr	1508(ra) # 80000d00 <acquire>
    if(p->state == SLEEPING && p->chan == chan) {
    80002724:	509c                	lw	a5,32(s1)
    80002726:	ff3791e3          	bne	a5,s3,80002708 <wakeup+0x2a>
    8000272a:	789c                	ld	a5,48(s1)
    8000272c:	fd479ee3          	bne	a5,s4,80002708 <wakeup+0x2a>
      p->state = RUNNABLE;
    80002730:	0354a023          	sw	s5,32(s1)
    80002734:	bfd1                	j	80002708 <wakeup+0x2a>
}
    80002736:	70e2                	ld	ra,56(sp)
    80002738:	7442                	ld	s0,48(sp)
    8000273a:	74a2                	ld	s1,40(sp)
    8000273c:	7902                	ld	s2,32(sp)
    8000273e:	69e2                	ld	s3,24(sp)
    80002740:	6a42                	ld	s4,16(sp)
    80002742:	6aa2                	ld	s5,8(sp)
    80002744:	6121                	addi	sp,sp,64
    80002746:	8082                	ret

0000000080002748 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    80002748:	7179                	addi	sp,sp,-48
    8000274a:	f406                	sd	ra,40(sp)
    8000274c:	f022                	sd	s0,32(sp)
    8000274e:	ec26                	sd	s1,24(sp)
    80002750:	e84a                	sd	s2,16(sp)
    80002752:	e44e                	sd	s3,8(sp)
    80002754:	1800                	addi	s0,sp,48
    80002756:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    80002758:	00010497          	auipc	s1,0x10
    8000275c:	05048493          	addi	s1,s1,80 # 800127a8 <proc>
    80002760:	00016997          	auipc	s3,0x16
    80002764:	c4898993          	addi	s3,s3,-952 # 800183a8 <tickslock>
    acquire(&p->lock);
    80002768:	8526                	mv	a0,s1
    8000276a:	ffffe097          	auipc	ra,0xffffe
    8000276e:	596080e7          	jalr	1430(ra) # 80000d00 <acquire>
    if(p->pid == pid){
    80002772:	40bc                	lw	a5,64(s1)
    80002774:	01278d63          	beq	a5,s2,8000278e <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002778:	8526                	mv	a0,s1
    8000277a:	ffffe097          	auipc	ra,0xffffe
    8000277e:	656080e7          	jalr	1622(ra) # 80000dd0 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80002782:	17048493          	addi	s1,s1,368
    80002786:	ff3491e3          	bne	s1,s3,80002768 <kill+0x20>
  }
  return -1;
    8000278a:	557d                	li	a0,-1
    8000278c:	a821                	j	800027a4 <kill+0x5c>
      p->killed = 1;
    8000278e:	4785                	li	a5,1
    80002790:	dc9c                	sw	a5,56(s1)
      if(p->state == SLEEPING){
    80002792:	5098                	lw	a4,32(s1)
    80002794:	00f70f63          	beq	a4,a5,800027b2 <kill+0x6a>
      release(&p->lock);
    80002798:	8526                	mv	a0,s1
    8000279a:	ffffe097          	auipc	ra,0xffffe
    8000279e:	636080e7          	jalr	1590(ra) # 80000dd0 <release>
      return 0;
    800027a2:	4501                	li	a0,0
}
    800027a4:	70a2                	ld	ra,40(sp)
    800027a6:	7402                	ld	s0,32(sp)
    800027a8:	64e2                	ld	s1,24(sp)
    800027aa:	6942                	ld	s2,16(sp)
    800027ac:	69a2                	ld	s3,8(sp)
    800027ae:	6145                	addi	sp,sp,48
    800027b0:	8082                	ret
        p->state = RUNNABLE;
    800027b2:	4789                	li	a5,2
    800027b4:	d09c                	sw	a5,32(s1)
    800027b6:	b7cd                	j	80002798 <kill+0x50>

00000000800027b8 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800027b8:	7179                	addi	sp,sp,-48
    800027ba:	f406                	sd	ra,40(sp)
    800027bc:	f022                	sd	s0,32(sp)
    800027be:	ec26                	sd	s1,24(sp)
    800027c0:	e84a                	sd	s2,16(sp)
    800027c2:	e44e                	sd	s3,8(sp)
    800027c4:	e052                	sd	s4,0(sp)
    800027c6:	1800                	addi	s0,sp,48
    800027c8:	84aa                	mv	s1,a0
    800027ca:	892e                	mv	s2,a1
    800027cc:	89b2                	mv	s3,a2
    800027ce:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800027d0:	fffff097          	auipc	ra,0xfffff
    800027d4:	576080e7          	jalr	1398(ra) # 80001d46 <myproc>
  if(user_dst){
    800027d8:	c08d                	beqz	s1,800027fa <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    800027da:	86d2                	mv	a3,s4
    800027dc:	864e                	mv	a2,s3
    800027de:	85ca                	mv	a1,s2
    800027e0:	6d28                	ld	a0,88(a0)
    800027e2:	fffff097          	auipc	ra,0xfffff
    800027e6:	25a080e7          	jalr	602(ra) # 80001a3c <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    800027ea:	70a2                	ld	ra,40(sp)
    800027ec:	7402                	ld	s0,32(sp)
    800027ee:	64e2                	ld	s1,24(sp)
    800027f0:	6942                	ld	s2,16(sp)
    800027f2:	69a2                	ld	s3,8(sp)
    800027f4:	6a02                	ld	s4,0(sp)
    800027f6:	6145                	addi	sp,sp,48
    800027f8:	8082                	ret
    memmove((char *)dst, src, len);
    800027fa:	000a061b          	sext.w	a2,s4
    800027fe:	85ce                	mv	a1,s3
    80002800:	854a                	mv	a0,s2
    80002802:	fffff097          	auipc	ra,0xfffff
    80002806:	93a080e7          	jalr	-1734(ra) # 8000113c <memmove>
    return 0;
    8000280a:	8526                	mv	a0,s1
    8000280c:	bff9                	j	800027ea <either_copyout+0x32>

000000008000280e <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    8000280e:	7179                	addi	sp,sp,-48
    80002810:	f406                	sd	ra,40(sp)
    80002812:	f022                	sd	s0,32(sp)
    80002814:	ec26                	sd	s1,24(sp)
    80002816:	e84a                	sd	s2,16(sp)
    80002818:	e44e                	sd	s3,8(sp)
    8000281a:	e052                	sd	s4,0(sp)
    8000281c:	1800                	addi	s0,sp,48
    8000281e:	892a                	mv	s2,a0
    80002820:	84ae                	mv	s1,a1
    80002822:	89b2                	mv	s3,a2
    80002824:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002826:	fffff097          	auipc	ra,0xfffff
    8000282a:	520080e7          	jalr	1312(ra) # 80001d46 <myproc>
  if(user_src){
    8000282e:	c08d                	beqz	s1,80002850 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    80002830:	86d2                	mv	a3,s4
    80002832:	864e                	mv	a2,s3
    80002834:	85ca                	mv	a1,s2
    80002836:	6d28                	ld	a0,88(a0)
    80002838:	fffff097          	auipc	ra,0xfffff
    8000283c:	290080e7          	jalr	656(ra) # 80001ac8 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80002840:	70a2                	ld	ra,40(sp)
    80002842:	7402                	ld	s0,32(sp)
    80002844:	64e2                	ld	s1,24(sp)
    80002846:	6942                	ld	s2,16(sp)
    80002848:	69a2                	ld	s3,8(sp)
    8000284a:	6a02                	ld	s4,0(sp)
    8000284c:	6145                	addi	sp,sp,48
    8000284e:	8082                	ret
    memmove(dst, (char*)src, len);
    80002850:	000a061b          	sext.w	a2,s4
    80002854:	85ce                	mv	a1,s3
    80002856:	854a                	mv	a0,s2
    80002858:	fffff097          	auipc	ra,0xfffff
    8000285c:	8e4080e7          	jalr	-1820(ra) # 8000113c <memmove>
    return 0;
    80002860:	8526                	mv	a0,s1
    80002862:	bff9                	j	80002840 <either_copyin+0x32>

0000000080002864 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    80002864:	715d                	addi	sp,sp,-80
    80002866:	e486                	sd	ra,72(sp)
    80002868:	e0a2                	sd	s0,64(sp)
    8000286a:	fc26                	sd	s1,56(sp)
    8000286c:	f84a                	sd	s2,48(sp)
    8000286e:	f44e                	sd	s3,40(sp)
    80002870:	f052                	sd	s4,32(sp)
    80002872:	ec56                	sd	s5,24(sp)
    80002874:	e85a                	sd	s6,16(sp)
    80002876:	e45e                	sd	s7,8(sp)
    80002878:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    8000287a:	00006517          	auipc	a0,0x6
    8000287e:	8e650513          	addi	a0,a0,-1818 # 80008160 <digits+0x120>
    80002882:	ffffe097          	auipc	ra,0xffffe
    80002886:	d14080e7          	jalr	-748(ra) # 80000596 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    8000288a:	00010497          	auipc	s1,0x10
    8000288e:	07e48493          	addi	s1,s1,126 # 80012908 <proc+0x160>
    80002892:	00016917          	auipc	s2,0x16
    80002896:	c7690913          	addi	s2,s2,-906 # 80018508 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000289a:	4b11                	li	s6,4
      state = states[p->state];
    else
      state = "???";
    8000289c:	00006997          	auipc	s3,0x6
    800028a0:	a5c98993          	addi	s3,s3,-1444 # 800082f8 <digits+0x2b8>
    printf("%d %s %s", p->pid, state, p->name);
    800028a4:	00006a97          	auipc	s5,0x6
    800028a8:	a5ca8a93          	addi	s5,s5,-1444 # 80008300 <digits+0x2c0>
    printf("\n");
    800028ac:	00006a17          	auipc	s4,0x6
    800028b0:	8b4a0a13          	addi	s4,s4,-1868 # 80008160 <digits+0x120>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800028b4:	00006b97          	auipc	s7,0x6
    800028b8:	a84b8b93          	addi	s7,s7,-1404 # 80008338 <states.0>
    800028bc:	a00d                	j	800028de <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    800028be:	ee06a583          	lw	a1,-288(a3)
    800028c2:	8556                	mv	a0,s5
    800028c4:	ffffe097          	auipc	ra,0xffffe
    800028c8:	cd2080e7          	jalr	-814(ra) # 80000596 <printf>
    printf("\n");
    800028cc:	8552                	mv	a0,s4
    800028ce:	ffffe097          	auipc	ra,0xffffe
    800028d2:	cc8080e7          	jalr	-824(ra) # 80000596 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800028d6:	17048493          	addi	s1,s1,368
    800028da:	03248263          	beq	s1,s2,800028fe <procdump+0x9a>
    if(p->state == UNUSED)
    800028de:	86a6                	mv	a3,s1
    800028e0:	ec04a783          	lw	a5,-320(s1)
    800028e4:	dbed                	beqz	a5,800028d6 <procdump+0x72>
      state = "???";
    800028e6:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800028e8:	fcfb6be3          	bltu	s6,a5,800028be <procdump+0x5a>
    800028ec:	02079713          	slli	a4,a5,0x20
    800028f0:	01d75793          	srli	a5,a4,0x1d
    800028f4:	97de                	add	a5,a5,s7
    800028f6:	6390                	ld	a2,0(a5)
    800028f8:	f279                	bnez	a2,800028be <procdump+0x5a>
      state = "???";
    800028fa:	864e                	mv	a2,s3
    800028fc:	b7c9                	j	800028be <procdump+0x5a>
  }
}
    800028fe:	60a6                	ld	ra,72(sp)
    80002900:	6406                	ld	s0,64(sp)
    80002902:	74e2                	ld	s1,56(sp)
    80002904:	7942                	ld	s2,48(sp)
    80002906:	79a2                	ld	s3,40(sp)
    80002908:	7a02                	ld	s4,32(sp)
    8000290a:	6ae2                	ld	s5,24(sp)
    8000290c:	6b42                	ld	s6,16(sp)
    8000290e:	6ba2                	ld	s7,8(sp)
    80002910:	6161                	addi	sp,sp,80
    80002912:	8082                	ret

0000000080002914 <swtch>:
    80002914:	00153023          	sd	ra,0(a0)
    80002918:	00253423          	sd	sp,8(a0)
    8000291c:	e900                	sd	s0,16(a0)
    8000291e:	ed04                	sd	s1,24(a0)
    80002920:	03253023          	sd	s2,32(a0)
    80002924:	03353423          	sd	s3,40(a0)
    80002928:	03453823          	sd	s4,48(a0)
    8000292c:	03553c23          	sd	s5,56(a0)
    80002930:	05653023          	sd	s6,64(a0)
    80002934:	05753423          	sd	s7,72(a0)
    80002938:	05853823          	sd	s8,80(a0)
    8000293c:	05953c23          	sd	s9,88(a0)
    80002940:	07a53023          	sd	s10,96(a0)
    80002944:	07b53423          	sd	s11,104(a0)
    80002948:	0005b083          	ld	ra,0(a1)
    8000294c:	0085b103          	ld	sp,8(a1)
    80002950:	6980                	ld	s0,16(a1)
    80002952:	6d84                	ld	s1,24(a1)
    80002954:	0205b903          	ld	s2,32(a1)
    80002958:	0285b983          	ld	s3,40(a1)
    8000295c:	0305ba03          	ld	s4,48(a1)
    80002960:	0385ba83          	ld	s5,56(a1)
    80002964:	0405bb03          	ld	s6,64(a1)
    80002968:	0485bb83          	ld	s7,72(a1)
    8000296c:	0505bc03          	ld	s8,80(a1)
    80002970:	0585bc83          	ld	s9,88(a1)
    80002974:	0605bd03          	ld	s10,96(a1)
    80002978:	0685bd83          	ld	s11,104(a1)
    8000297c:	8082                	ret

000000008000297e <trapinit>:

extern int devintr();

void
trapinit(void)
{
    8000297e:	1141                	addi	sp,sp,-16
    80002980:	e406                	sd	ra,8(sp)
    80002982:	e022                	sd	s0,0(sp)
    80002984:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002986:	00006597          	auipc	a1,0x6
    8000298a:	9da58593          	addi	a1,a1,-1574 # 80008360 <states.0+0x28>
    8000298e:	00016517          	auipc	a0,0x16
    80002992:	a1a50513          	addi	a0,a0,-1510 # 800183a8 <tickslock>
    80002996:	ffffe097          	auipc	ra,0xffffe
    8000299a:	4e6080e7          	jalr	1254(ra) # 80000e7c <initlock>
}
    8000299e:	60a2                	ld	ra,8(sp)
    800029a0:	6402                	ld	s0,0(sp)
    800029a2:	0141                	addi	sp,sp,16
    800029a4:	8082                	ret

00000000800029a6 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    800029a6:	1141                	addi	sp,sp,-16
    800029a8:	e422                	sd	s0,8(sp)
    800029aa:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    800029ac:	00003797          	auipc	a5,0x3
    800029b0:	4e478793          	addi	a5,a5,1252 # 80005e90 <kernelvec>
    800029b4:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    800029b8:	6422                	ld	s0,8(sp)
    800029ba:	0141                	addi	sp,sp,16
    800029bc:	8082                	ret

00000000800029be <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    800029be:	1141                	addi	sp,sp,-16
    800029c0:	e406                	sd	ra,8(sp)
    800029c2:	e022                	sd	s0,0(sp)
    800029c4:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    800029c6:	fffff097          	auipc	ra,0xfffff
    800029ca:	380080e7          	jalr	896(ra) # 80001d46 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029ce:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    800029d2:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800029d4:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    800029d8:	00004697          	auipc	a3,0x4
    800029dc:	62868693          	addi	a3,a3,1576 # 80007000 <_trampoline>
    800029e0:	00004717          	auipc	a4,0x4
    800029e4:	62070713          	addi	a4,a4,1568 # 80007000 <_trampoline>
    800029e8:	8f15                	sub	a4,a4,a3
    800029ea:	040007b7          	lui	a5,0x4000
    800029ee:	17fd                	addi	a5,a5,-1 # 3ffffff <_entry-0x7c000001>
    800029f0:	07b2                	slli	a5,a5,0xc
    800029f2:	973e                	add	a4,a4,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    800029f4:	10571073          	csrw	stvec,a4

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    800029f8:	7138                	ld	a4,96(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    800029fa:	18002673          	csrr	a2,satp
    800029fe:	e310                	sd	a2,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002a00:	7130                	ld	a2,96(a0)
    80002a02:	6538                	ld	a4,72(a0)
    80002a04:	6585                	lui	a1,0x1
    80002a06:	972e                	add	a4,a4,a1
    80002a08:	e618                	sd	a4,8(a2)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002a0a:	7138                	ld	a4,96(a0)
    80002a0c:	00000617          	auipc	a2,0x0
    80002a10:	13860613          	addi	a2,a2,312 # 80002b44 <usertrap>
    80002a14:	eb10                	sd	a2,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002a16:	7138                	ld	a4,96(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002a18:	8612                	mv	a2,tp
    80002a1a:	f310                	sd	a2,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a1c:	10002773          	csrr	a4,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002a20:	eff77713          	andi	a4,a4,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002a24:	02076713          	ori	a4,a4,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002a28:	10071073          	csrw	sstatus,a4
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002a2c:	7138                	ld	a4,96(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002a2e:	6f18                	ld	a4,24(a4)
    80002a30:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002a34:	6d2c                	ld	a1,88(a0)
    80002a36:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002a38:	00004717          	auipc	a4,0x4
    80002a3c:	65870713          	addi	a4,a4,1624 # 80007090 <userret>
    80002a40:	8f15                	sub	a4,a4,a3
    80002a42:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80002a44:	577d                	li	a4,-1
    80002a46:	177e                	slli	a4,a4,0x3f
    80002a48:	8dd9                	or	a1,a1,a4
    80002a4a:	02000537          	lui	a0,0x2000
    80002a4e:	157d                	addi	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    80002a50:	0536                	slli	a0,a0,0xd
    80002a52:	9782                	jalr	a5
}
    80002a54:	60a2                	ld	ra,8(sp)
    80002a56:	6402                	ld	s0,0(sp)
    80002a58:	0141                	addi	sp,sp,16
    80002a5a:	8082                	ret

0000000080002a5c <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002a5c:	1101                	addi	sp,sp,-32
    80002a5e:	ec06                	sd	ra,24(sp)
    80002a60:	e822                	sd	s0,16(sp)
    80002a62:	e426                	sd	s1,8(sp)
    80002a64:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002a66:	00016497          	auipc	s1,0x16
    80002a6a:	94248493          	addi	s1,s1,-1726 # 800183a8 <tickslock>
    80002a6e:	8526                	mv	a0,s1
    80002a70:	ffffe097          	auipc	ra,0xffffe
    80002a74:	290080e7          	jalr	656(ra) # 80000d00 <acquire>
  ticks++;
    80002a78:	00006517          	auipc	a0,0x6
    80002a7c:	5a850513          	addi	a0,a0,1448 # 80009020 <ticks>
    80002a80:	411c                	lw	a5,0(a0)
    80002a82:	2785                	addiw	a5,a5,1
    80002a84:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002a86:	00000097          	auipc	ra,0x0
    80002a8a:	c58080e7          	jalr	-936(ra) # 800026de <wakeup>
  release(&tickslock);
    80002a8e:	8526                	mv	a0,s1
    80002a90:	ffffe097          	auipc	ra,0xffffe
    80002a94:	340080e7          	jalr	832(ra) # 80000dd0 <release>
}
    80002a98:	60e2                	ld	ra,24(sp)
    80002a9a:	6442                	ld	s0,16(sp)
    80002a9c:	64a2                	ld	s1,8(sp)
    80002a9e:	6105                	addi	sp,sp,32
    80002aa0:	8082                	ret

0000000080002aa2 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002aa2:	1101                	addi	sp,sp,-32
    80002aa4:	ec06                	sd	ra,24(sp)
    80002aa6:	e822                	sd	s0,16(sp)
    80002aa8:	e426                	sd	s1,8(sp)
    80002aaa:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002aac:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002ab0:	00074d63          	bltz	a4,80002aca <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002ab4:	57fd                	li	a5,-1
    80002ab6:	17fe                	slli	a5,a5,0x3f
    80002ab8:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002aba:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002abc:	06f70363          	beq	a4,a5,80002b22 <devintr+0x80>
  }
}
    80002ac0:	60e2                	ld	ra,24(sp)
    80002ac2:	6442                	ld	s0,16(sp)
    80002ac4:	64a2                	ld	s1,8(sp)
    80002ac6:	6105                	addi	sp,sp,32
    80002ac8:	8082                	ret
     (scause & 0xff) == 9){
    80002aca:	0ff77793          	zext.b	a5,a4
  if((scause & 0x8000000000000000L) &&
    80002ace:	46a5                	li	a3,9
    80002ad0:	fed792e3          	bne	a5,a3,80002ab4 <devintr+0x12>
    int irq = plic_claim();
    80002ad4:	00003097          	auipc	ra,0x3
    80002ad8:	4c4080e7          	jalr	1220(ra) # 80005f98 <plic_claim>
    80002adc:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002ade:	47a9                	li	a5,10
    80002ae0:	02f50763          	beq	a0,a5,80002b0e <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002ae4:	4785                	li	a5,1
    80002ae6:	02f50963          	beq	a0,a5,80002b18 <devintr+0x76>
    return 1;
    80002aea:	4505                	li	a0,1
    } else if(irq){
    80002aec:	d8f1                	beqz	s1,80002ac0 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002aee:	85a6                	mv	a1,s1
    80002af0:	00006517          	auipc	a0,0x6
    80002af4:	87850513          	addi	a0,a0,-1928 # 80008368 <states.0+0x30>
    80002af8:	ffffe097          	auipc	ra,0xffffe
    80002afc:	a9e080e7          	jalr	-1378(ra) # 80000596 <printf>
      plic_complete(irq);
    80002b00:	8526                	mv	a0,s1
    80002b02:	00003097          	auipc	ra,0x3
    80002b06:	4ba080e7          	jalr	1210(ra) # 80005fbc <plic_complete>
    return 1;
    80002b0a:	4505                	li	a0,1
    80002b0c:	bf55                	j	80002ac0 <devintr+0x1e>
      uartintr();
    80002b0e:	ffffe097          	auipc	ra,0xffffe
    80002b12:	eba080e7          	jalr	-326(ra) # 800009c8 <uartintr>
    80002b16:	b7ed                	j	80002b00 <devintr+0x5e>
      virtio_disk_intr();
    80002b18:	00004097          	auipc	ra,0x4
    80002b1c:	930080e7          	jalr	-1744(ra) # 80006448 <virtio_disk_intr>
    80002b20:	b7c5                	j	80002b00 <devintr+0x5e>
    if(cpuid() == 0){
    80002b22:	fffff097          	auipc	ra,0xfffff
    80002b26:	1f8080e7          	jalr	504(ra) # 80001d1a <cpuid>
    80002b2a:	c901                	beqz	a0,80002b3a <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002b2c:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002b30:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002b32:	14479073          	csrw	sip,a5
    return 2;
    80002b36:	4509                	li	a0,2
    80002b38:	b761                	j	80002ac0 <devintr+0x1e>
      clockintr();
    80002b3a:	00000097          	auipc	ra,0x0
    80002b3e:	f22080e7          	jalr	-222(ra) # 80002a5c <clockintr>
    80002b42:	b7ed                	j	80002b2c <devintr+0x8a>

0000000080002b44 <usertrap>:
{
    80002b44:	1101                	addi	sp,sp,-32
    80002b46:	ec06                	sd	ra,24(sp)
    80002b48:	e822                	sd	s0,16(sp)
    80002b4a:	e426                	sd	s1,8(sp)
    80002b4c:	e04a                	sd	s2,0(sp)
    80002b4e:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b50:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002b54:	1007f793          	andi	a5,a5,256
    80002b58:	e3ad                	bnez	a5,80002bba <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002b5a:	00003797          	auipc	a5,0x3
    80002b5e:	33678793          	addi	a5,a5,822 # 80005e90 <kernelvec>
    80002b62:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002b66:	fffff097          	auipc	ra,0xfffff
    80002b6a:	1e0080e7          	jalr	480(ra) # 80001d46 <myproc>
    80002b6e:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002b70:	713c                	ld	a5,96(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b72:	14102773          	csrr	a4,sepc
    80002b76:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002b78:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002b7c:	47a1                	li	a5,8
    80002b7e:	04f71c63          	bne	a4,a5,80002bd6 <usertrap+0x92>
    if(p->killed)
    80002b82:	5d1c                	lw	a5,56(a0)
    80002b84:	e3b9                	bnez	a5,80002bca <usertrap+0x86>
    p->trapframe->epc += 4;
    80002b86:	70b8                	ld	a4,96(s1)
    80002b88:	6f1c                	ld	a5,24(a4)
    80002b8a:	0791                	addi	a5,a5,4
    80002b8c:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b8e:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002b92:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002b96:	10079073          	csrw	sstatus,a5
    syscall();
    80002b9a:	00000097          	auipc	ra,0x0
    80002b9e:	2e0080e7          	jalr	736(ra) # 80002e7a <syscall>
  if(p->killed)
    80002ba2:	5c9c                	lw	a5,56(s1)
    80002ba4:	ebc1                	bnez	a5,80002c34 <usertrap+0xf0>
  usertrapret();
    80002ba6:	00000097          	auipc	ra,0x0
    80002baa:	e18080e7          	jalr	-488(ra) # 800029be <usertrapret>
}
    80002bae:	60e2                	ld	ra,24(sp)
    80002bb0:	6442                	ld	s0,16(sp)
    80002bb2:	64a2                	ld	s1,8(sp)
    80002bb4:	6902                	ld	s2,0(sp)
    80002bb6:	6105                	addi	sp,sp,32
    80002bb8:	8082                	ret
    panic("usertrap: not from user mode");
    80002bba:	00005517          	auipc	a0,0x5
    80002bbe:	7ce50513          	addi	a0,a0,1998 # 80008388 <states.0+0x50>
    80002bc2:	ffffe097          	auipc	ra,0xffffe
    80002bc6:	98a080e7          	jalr	-1654(ra) # 8000054c <panic>
      exit(-1);
    80002bca:	557d                	li	a0,-1
    80002bcc:	00000097          	auipc	ra,0x0
    80002bd0:	84c080e7          	jalr	-1972(ra) # 80002418 <exit>
    80002bd4:	bf4d                	j	80002b86 <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80002bd6:	00000097          	auipc	ra,0x0
    80002bda:	ecc080e7          	jalr	-308(ra) # 80002aa2 <devintr>
    80002bde:	892a                	mv	s2,a0
    80002be0:	c501                	beqz	a0,80002be8 <usertrap+0xa4>
  if(p->killed)
    80002be2:	5c9c                	lw	a5,56(s1)
    80002be4:	c3a1                	beqz	a5,80002c24 <usertrap+0xe0>
    80002be6:	a815                	j	80002c1a <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002be8:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002bec:	40b0                	lw	a2,64(s1)
    80002bee:	00005517          	auipc	a0,0x5
    80002bf2:	7ba50513          	addi	a0,a0,1978 # 800083a8 <states.0+0x70>
    80002bf6:	ffffe097          	auipc	ra,0xffffe
    80002bfa:	9a0080e7          	jalr	-1632(ra) # 80000596 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002bfe:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002c02:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002c06:	00005517          	auipc	a0,0x5
    80002c0a:	7d250513          	addi	a0,a0,2002 # 800083d8 <states.0+0xa0>
    80002c0e:	ffffe097          	auipc	ra,0xffffe
    80002c12:	988080e7          	jalr	-1656(ra) # 80000596 <printf>
    p->killed = 1;
    80002c16:	4785                	li	a5,1
    80002c18:	dc9c                	sw	a5,56(s1)
    exit(-1);
    80002c1a:	557d                	li	a0,-1
    80002c1c:	fffff097          	auipc	ra,0xfffff
    80002c20:	7fc080e7          	jalr	2044(ra) # 80002418 <exit>
  if(which_dev == 2)
    80002c24:	4789                	li	a5,2
    80002c26:	f8f910e3          	bne	s2,a5,80002ba6 <usertrap+0x62>
    yield();
    80002c2a:	00000097          	auipc	ra,0x0
    80002c2e:	8f8080e7          	jalr	-1800(ra) # 80002522 <yield>
    80002c32:	bf95                	j	80002ba6 <usertrap+0x62>
  int which_dev = 0;
    80002c34:	4901                	li	s2,0
    80002c36:	b7d5                	j	80002c1a <usertrap+0xd6>

0000000080002c38 <kerneltrap>:
{
    80002c38:	7179                	addi	sp,sp,-48
    80002c3a:	f406                	sd	ra,40(sp)
    80002c3c:	f022                	sd	s0,32(sp)
    80002c3e:	ec26                	sd	s1,24(sp)
    80002c40:	e84a                	sd	s2,16(sp)
    80002c42:	e44e                	sd	s3,8(sp)
    80002c44:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002c46:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c4a:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002c4e:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002c52:	1004f793          	andi	a5,s1,256
    80002c56:	cb85                	beqz	a5,80002c86 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c58:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002c5c:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002c5e:	ef85                	bnez	a5,80002c96 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002c60:	00000097          	auipc	ra,0x0
    80002c64:	e42080e7          	jalr	-446(ra) # 80002aa2 <devintr>
    80002c68:	cd1d                	beqz	a0,80002ca6 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002c6a:	4789                	li	a5,2
    80002c6c:	06f50a63          	beq	a0,a5,80002ce0 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002c70:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002c74:	10049073          	csrw	sstatus,s1
}
    80002c78:	70a2                	ld	ra,40(sp)
    80002c7a:	7402                	ld	s0,32(sp)
    80002c7c:	64e2                	ld	s1,24(sp)
    80002c7e:	6942                	ld	s2,16(sp)
    80002c80:	69a2                	ld	s3,8(sp)
    80002c82:	6145                	addi	sp,sp,48
    80002c84:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002c86:	00005517          	auipc	a0,0x5
    80002c8a:	77250513          	addi	a0,a0,1906 # 800083f8 <states.0+0xc0>
    80002c8e:	ffffe097          	auipc	ra,0xffffe
    80002c92:	8be080e7          	jalr	-1858(ra) # 8000054c <panic>
    panic("kerneltrap: interrupts enabled");
    80002c96:	00005517          	auipc	a0,0x5
    80002c9a:	78a50513          	addi	a0,a0,1930 # 80008420 <states.0+0xe8>
    80002c9e:	ffffe097          	auipc	ra,0xffffe
    80002ca2:	8ae080e7          	jalr	-1874(ra) # 8000054c <panic>
    printf("scause %p\n", scause);
    80002ca6:	85ce                	mv	a1,s3
    80002ca8:	00005517          	auipc	a0,0x5
    80002cac:	79850513          	addi	a0,a0,1944 # 80008440 <states.0+0x108>
    80002cb0:	ffffe097          	auipc	ra,0xffffe
    80002cb4:	8e6080e7          	jalr	-1818(ra) # 80000596 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002cb8:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002cbc:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002cc0:	00005517          	auipc	a0,0x5
    80002cc4:	79050513          	addi	a0,a0,1936 # 80008450 <states.0+0x118>
    80002cc8:	ffffe097          	auipc	ra,0xffffe
    80002ccc:	8ce080e7          	jalr	-1842(ra) # 80000596 <printf>
    panic("kerneltrap");
    80002cd0:	00005517          	auipc	a0,0x5
    80002cd4:	79850513          	addi	a0,a0,1944 # 80008468 <states.0+0x130>
    80002cd8:	ffffe097          	auipc	ra,0xffffe
    80002cdc:	874080e7          	jalr	-1932(ra) # 8000054c <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002ce0:	fffff097          	auipc	ra,0xfffff
    80002ce4:	066080e7          	jalr	102(ra) # 80001d46 <myproc>
    80002ce8:	d541                	beqz	a0,80002c70 <kerneltrap+0x38>
    80002cea:	fffff097          	auipc	ra,0xfffff
    80002cee:	05c080e7          	jalr	92(ra) # 80001d46 <myproc>
    80002cf2:	5118                	lw	a4,32(a0)
    80002cf4:	478d                	li	a5,3
    80002cf6:	f6f71de3          	bne	a4,a5,80002c70 <kerneltrap+0x38>
    yield();
    80002cfa:	00000097          	auipc	ra,0x0
    80002cfe:	828080e7          	jalr	-2008(ra) # 80002522 <yield>
    80002d02:	b7bd                	j	80002c70 <kerneltrap+0x38>

0000000080002d04 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002d04:	1101                	addi	sp,sp,-32
    80002d06:	ec06                	sd	ra,24(sp)
    80002d08:	e822                	sd	s0,16(sp)
    80002d0a:	e426                	sd	s1,8(sp)
    80002d0c:	1000                	addi	s0,sp,32
    80002d0e:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002d10:	fffff097          	auipc	ra,0xfffff
    80002d14:	036080e7          	jalr	54(ra) # 80001d46 <myproc>
  switch (n) {
    80002d18:	4795                	li	a5,5
    80002d1a:	0497e163          	bltu	a5,s1,80002d5c <argraw+0x58>
    80002d1e:	048a                	slli	s1,s1,0x2
    80002d20:	00005717          	auipc	a4,0x5
    80002d24:	78070713          	addi	a4,a4,1920 # 800084a0 <states.0+0x168>
    80002d28:	94ba                	add	s1,s1,a4
    80002d2a:	409c                	lw	a5,0(s1)
    80002d2c:	97ba                	add	a5,a5,a4
    80002d2e:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002d30:	713c                	ld	a5,96(a0)
    80002d32:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002d34:	60e2                	ld	ra,24(sp)
    80002d36:	6442                	ld	s0,16(sp)
    80002d38:	64a2                	ld	s1,8(sp)
    80002d3a:	6105                	addi	sp,sp,32
    80002d3c:	8082                	ret
    return p->trapframe->a1;
    80002d3e:	713c                	ld	a5,96(a0)
    80002d40:	7fa8                	ld	a0,120(a5)
    80002d42:	bfcd                	j	80002d34 <argraw+0x30>
    return p->trapframe->a2;
    80002d44:	713c                	ld	a5,96(a0)
    80002d46:	63c8                	ld	a0,128(a5)
    80002d48:	b7f5                	j	80002d34 <argraw+0x30>
    return p->trapframe->a3;
    80002d4a:	713c                	ld	a5,96(a0)
    80002d4c:	67c8                	ld	a0,136(a5)
    80002d4e:	b7dd                	j	80002d34 <argraw+0x30>
    return p->trapframe->a4;
    80002d50:	713c                	ld	a5,96(a0)
    80002d52:	6bc8                	ld	a0,144(a5)
    80002d54:	b7c5                	j	80002d34 <argraw+0x30>
    return p->trapframe->a5;
    80002d56:	713c                	ld	a5,96(a0)
    80002d58:	6fc8                	ld	a0,152(a5)
    80002d5a:	bfe9                	j	80002d34 <argraw+0x30>
  panic("argraw");
    80002d5c:	00005517          	auipc	a0,0x5
    80002d60:	71c50513          	addi	a0,a0,1820 # 80008478 <states.0+0x140>
    80002d64:	ffffd097          	auipc	ra,0xffffd
    80002d68:	7e8080e7          	jalr	2024(ra) # 8000054c <panic>

0000000080002d6c <fetchaddr>:
{
    80002d6c:	1101                	addi	sp,sp,-32
    80002d6e:	ec06                	sd	ra,24(sp)
    80002d70:	e822                	sd	s0,16(sp)
    80002d72:	e426                	sd	s1,8(sp)
    80002d74:	e04a                	sd	s2,0(sp)
    80002d76:	1000                	addi	s0,sp,32
    80002d78:	84aa                	mv	s1,a0
    80002d7a:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002d7c:	fffff097          	auipc	ra,0xfffff
    80002d80:	fca080e7          	jalr	-54(ra) # 80001d46 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002d84:	693c                	ld	a5,80(a0)
    80002d86:	02f4f863          	bgeu	s1,a5,80002db6 <fetchaddr+0x4a>
    80002d8a:	00848713          	addi	a4,s1,8
    80002d8e:	02e7e663          	bltu	a5,a4,80002dba <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002d92:	46a1                	li	a3,8
    80002d94:	8626                	mv	a2,s1
    80002d96:	85ca                	mv	a1,s2
    80002d98:	6d28                	ld	a0,88(a0)
    80002d9a:	fffff097          	auipc	ra,0xfffff
    80002d9e:	d2e080e7          	jalr	-722(ra) # 80001ac8 <copyin>
    80002da2:	00a03533          	snez	a0,a0
    80002da6:	40a00533          	neg	a0,a0
}
    80002daa:	60e2                	ld	ra,24(sp)
    80002dac:	6442                	ld	s0,16(sp)
    80002dae:	64a2                	ld	s1,8(sp)
    80002db0:	6902                	ld	s2,0(sp)
    80002db2:	6105                	addi	sp,sp,32
    80002db4:	8082                	ret
    return -1;
    80002db6:	557d                	li	a0,-1
    80002db8:	bfcd                	j	80002daa <fetchaddr+0x3e>
    80002dba:	557d                	li	a0,-1
    80002dbc:	b7fd                	j	80002daa <fetchaddr+0x3e>

0000000080002dbe <fetchstr>:
{
    80002dbe:	7179                	addi	sp,sp,-48
    80002dc0:	f406                	sd	ra,40(sp)
    80002dc2:	f022                	sd	s0,32(sp)
    80002dc4:	ec26                	sd	s1,24(sp)
    80002dc6:	e84a                	sd	s2,16(sp)
    80002dc8:	e44e                	sd	s3,8(sp)
    80002dca:	1800                	addi	s0,sp,48
    80002dcc:	892a                	mv	s2,a0
    80002dce:	84ae                	mv	s1,a1
    80002dd0:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002dd2:	fffff097          	auipc	ra,0xfffff
    80002dd6:	f74080e7          	jalr	-140(ra) # 80001d46 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002dda:	86ce                	mv	a3,s3
    80002ddc:	864a                	mv	a2,s2
    80002dde:	85a6                	mv	a1,s1
    80002de0:	6d28                	ld	a0,88(a0)
    80002de2:	fffff097          	auipc	ra,0xfffff
    80002de6:	d74080e7          	jalr	-652(ra) # 80001b56 <copyinstr>
  if(err < 0)
    80002dea:	00054763          	bltz	a0,80002df8 <fetchstr+0x3a>
  return strlen(buf);
    80002dee:	8526                	mv	a0,s1
    80002df0:	ffffe097          	auipc	ra,0xffffe
    80002df4:	474080e7          	jalr	1140(ra) # 80001264 <strlen>
}
    80002df8:	70a2                	ld	ra,40(sp)
    80002dfa:	7402                	ld	s0,32(sp)
    80002dfc:	64e2                	ld	s1,24(sp)
    80002dfe:	6942                	ld	s2,16(sp)
    80002e00:	69a2                	ld	s3,8(sp)
    80002e02:	6145                	addi	sp,sp,48
    80002e04:	8082                	ret

0000000080002e06 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002e06:	1101                	addi	sp,sp,-32
    80002e08:	ec06                	sd	ra,24(sp)
    80002e0a:	e822                	sd	s0,16(sp)
    80002e0c:	e426                	sd	s1,8(sp)
    80002e0e:	1000                	addi	s0,sp,32
    80002e10:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002e12:	00000097          	auipc	ra,0x0
    80002e16:	ef2080e7          	jalr	-270(ra) # 80002d04 <argraw>
    80002e1a:	c088                	sw	a0,0(s1)
  return 0;
}
    80002e1c:	4501                	li	a0,0
    80002e1e:	60e2                	ld	ra,24(sp)
    80002e20:	6442                	ld	s0,16(sp)
    80002e22:	64a2                	ld	s1,8(sp)
    80002e24:	6105                	addi	sp,sp,32
    80002e26:	8082                	ret

0000000080002e28 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002e28:	1101                	addi	sp,sp,-32
    80002e2a:	ec06                	sd	ra,24(sp)
    80002e2c:	e822                	sd	s0,16(sp)
    80002e2e:	e426                	sd	s1,8(sp)
    80002e30:	1000                	addi	s0,sp,32
    80002e32:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002e34:	00000097          	auipc	ra,0x0
    80002e38:	ed0080e7          	jalr	-304(ra) # 80002d04 <argraw>
    80002e3c:	e088                	sd	a0,0(s1)
  return 0;
}
    80002e3e:	4501                	li	a0,0
    80002e40:	60e2                	ld	ra,24(sp)
    80002e42:	6442                	ld	s0,16(sp)
    80002e44:	64a2                	ld	s1,8(sp)
    80002e46:	6105                	addi	sp,sp,32
    80002e48:	8082                	ret

0000000080002e4a <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002e4a:	1101                	addi	sp,sp,-32
    80002e4c:	ec06                	sd	ra,24(sp)
    80002e4e:	e822                	sd	s0,16(sp)
    80002e50:	e426                	sd	s1,8(sp)
    80002e52:	e04a                	sd	s2,0(sp)
    80002e54:	1000                	addi	s0,sp,32
    80002e56:	84ae                	mv	s1,a1
    80002e58:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002e5a:	00000097          	auipc	ra,0x0
    80002e5e:	eaa080e7          	jalr	-342(ra) # 80002d04 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002e62:	864a                	mv	a2,s2
    80002e64:	85a6                	mv	a1,s1
    80002e66:	00000097          	auipc	ra,0x0
    80002e6a:	f58080e7          	jalr	-168(ra) # 80002dbe <fetchstr>
}
    80002e6e:	60e2                	ld	ra,24(sp)
    80002e70:	6442                	ld	s0,16(sp)
    80002e72:	64a2                	ld	s1,8(sp)
    80002e74:	6902                	ld	s2,0(sp)
    80002e76:	6105                	addi	sp,sp,32
    80002e78:	8082                	ret

0000000080002e7a <syscall>:
[SYS_close]   sys_close,
};

void
syscall(void)
{
    80002e7a:	1101                	addi	sp,sp,-32
    80002e7c:	ec06                	sd	ra,24(sp)
    80002e7e:	e822                	sd	s0,16(sp)
    80002e80:	e426                	sd	s1,8(sp)
    80002e82:	e04a                	sd	s2,0(sp)
    80002e84:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002e86:	fffff097          	auipc	ra,0xfffff
    80002e8a:	ec0080e7          	jalr	-320(ra) # 80001d46 <myproc>
    80002e8e:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002e90:	06053903          	ld	s2,96(a0)
    80002e94:	0a893783          	ld	a5,168(s2)
    80002e98:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002e9c:	37fd                	addiw	a5,a5,-1
    80002e9e:	4751                	li	a4,20
    80002ea0:	00f76f63          	bltu	a4,a5,80002ebe <syscall+0x44>
    80002ea4:	00369713          	slli	a4,a3,0x3
    80002ea8:	00005797          	auipc	a5,0x5
    80002eac:	61078793          	addi	a5,a5,1552 # 800084b8 <syscalls>
    80002eb0:	97ba                	add	a5,a5,a4
    80002eb2:	639c                	ld	a5,0(a5)
    80002eb4:	c789                	beqz	a5,80002ebe <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80002eb6:	9782                	jalr	a5
    80002eb8:	06a93823          	sd	a0,112(s2)
    80002ebc:	a839                	j	80002eda <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002ebe:	16048613          	addi	a2,s1,352
    80002ec2:	40ac                	lw	a1,64(s1)
    80002ec4:	00005517          	auipc	a0,0x5
    80002ec8:	5bc50513          	addi	a0,a0,1468 # 80008480 <states.0+0x148>
    80002ecc:	ffffd097          	auipc	ra,0xffffd
    80002ed0:	6ca080e7          	jalr	1738(ra) # 80000596 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002ed4:	70bc                	ld	a5,96(s1)
    80002ed6:	577d                	li	a4,-1
    80002ed8:	fbb8                	sd	a4,112(a5)
  }
}
    80002eda:	60e2                	ld	ra,24(sp)
    80002edc:	6442                	ld	s0,16(sp)
    80002ede:	64a2                	ld	s1,8(sp)
    80002ee0:	6902                	ld	s2,0(sp)
    80002ee2:	6105                	addi	sp,sp,32
    80002ee4:	8082                	ret

0000000080002ee6 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002ee6:	1101                	addi	sp,sp,-32
    80002ee8:	ec06                	sd	ra,24(sp)
    80002eea:	e822                	sd	s0,16(sp)
    80002eec:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002eee:	fec40593          	addi	a1,s0,-20
    80002ef2:	4501                	li	a0,0
    80002ef4:	00000097          	auipc	ra,0x0
    80002ef8:	f12080e7          	jalr	-238(ra) # 80002e06 <argint>
    return -1;
    80002efc:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002efe:	00054963          	bltz	a0,80002f10 <sys_exit+0x2a>
  exit(n);
    80002f02:	fec42503          	lw	a0,-20(s0)
    80002f06:	fffff097          	auipc	ra,0xfffff
    80002f0a:	512080e7          	jalr	1298(ra) # 80002418 <exit>
  return 0;  // not reached
    80002f0e:	4781                	li	a5,0
}
    80002f10:	853e                	mv	a0,a5
    80002f12:	60e2                	ld	ra,24(sp)
    80002f14:	6442                	ld	s0,16(sp)
    80002f16:	6105                	addi	sp,sp,32
    80002f18:	8082                	ret

0000000080002f1a <sys_getpid>:

uint64
sys_getpid(void)
{
    80002f1a:	1141                	addi	sp,sp,-16
    80002f1c:	e406                	sd	ra,8(sp)
    80002f1e:	e022                	sd	s0,0(sp)
    80002f20:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002f22:	fffff097          	auipc	ra,0xfffff
    80002f26:	e24080e7          	jalr	-476(ra) # 80001d46 <myproc>
}
    80002f2a:	4128                	lw	a0,64(a0)
    80002f2c:	60a2                	ld	ra,8(sp)
    80002f2e:	6402                	ld	s0,0(sp)
    80002f30:	0141                	addi	sp,sp,16
    80002f32:	8082                	ret

0000000080002f34 <sys_fork>:

uint64
sys_fork(void)
{
    80002f34:	1141                	addi	sp,sp,-16
    80002f36:	e406                	sd	ra,8(sp)
    80002f38:	e022                	sd	s0,0(sp)
    80002f3a:	0800                	addi	s0,sp,16
  return fork();
    80002f3c:	fffff097          	auipc	ra,0xfffff
    80002f40:	1ce080e7          	jalr	462(ra) # 8000210a <fork>
}
    80002f44:	60a2                	ld	ra,8(sp)
    80002f46:	6402                	ld	s0,0(sp)
    80002f48:	0141                	addi	sp,sp,16
    80002f4a:	8082                	ret

0000000080002f4c <sys_wait>:

uint64
sys_wait(void)
{
    80002f4c:	1101                	addi	sp,sp,-32
    80002f4e:	ec06                	sd	ra,24(sp)
    80002f50:	e822                	sd	s0,16(sp)
    80002f52:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002f54:	fe840593          	addi	a1,s0,-24
    80002f58:	4501                	li	a0,0
    80002f5a:	00000097          	auipc	ra,0x0
    80002f5e:	ece080e7          	jalr	-306(ra) # 80002e28 <argaddr>
    80002f62:	87aa                	mv	a5,a0
    return -1;
    80002f64:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002f66:	0007c863          	bltz	a5,80002f76 <sys_wait+0x2a>
  return wait(p);
    80002f6a:	fe843503          	ld	a0,-24(s0)
    80002f6e:	fffff097          	auipc	ra,0xfffff
    80002f72:	66e080e7          	jalr	1646(ra) # 800025dc <wait>
}
    80002f76:	60e2                	ld	ra,24(sp)
    80002f78:	6442                	ld	s0,16(sp)
    80002f7a:	6105                	addi	sp,sp,32
    80002f7c:	8082                	ret

0000000080002f7e <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002f7e:	7179                	addi	sp,sp,-48
    80002f80:	f406                	sd	ra,40(sp)
    80002f82:	f022                	sd	s0,32(sp)
    80002f84:	ec26                	sd	s1,24(sp)
    80002f86:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002f88:	fdc40593          	addi	a1,s0,-36
    80002f8c:	4501                	li	a0,0
    80002f8e:	00000097          	auipc	ra,0x0
    80002f92:	e78080e7          	jalr	-392(ra) # 80002e06 <argint>
    80002f96:	87aa                	mv	a5,a0
    return -1;
    80002f98:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80002f9a:	0207c063          	bltz	a5,80002fba <sys_sbrk+0x3c>
  addr = myproc()->sz;
    80002f9e:	fffff097          	auipc	ra,0xfffff
    80002fa2:	da8080e7          	jalr	-600(ra) # 80001d46 <myproc>
    80002fa6:	4924                	lw	s1,80(a0)
  if(growproc(n) < 0)
    80002fa8:	fdc42503          	lw	a0,-36(s0)
    80002fac:	fffff097          	auipc	ra,0xfffff
    80002fb0:	0e6080e7          	jalr	230(ra) # 80002092 <growproc>
    80002fb4:	00054863          	bltz	a0,80002fc4 <sys_sbrk+0x46>
    return -1;
  return addr;
    80002fb8:	8526                	mv	a0,s1
}
    80002fba:	70a2                	ld	ra,40(sp)
    80002fbc:	7402                	ld	s0,32(sp)
    80002fbe:	64e2                	ld	s1,24(sp)
    80002fc0:	6145                	addi	sp,sp,48
    80002fc2:	8082                	ret
    return -1;
    80002fc4:	557d                	li	a0,-1
    80002fc6:	bfd5                	j	80002fba <sys_sbrk+0x3c>

0000000080002fc8 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002fc8:	7139                	addi	sp,sp,-64
    80002fca:	fc06                	sd	ra,56(sp)
    80002fcc:	f822                	sd	s0,48(sp)
    80002fce:	f426                	sd	s1,40(sp)
    80002fd0:	f04a                	sd	s2,32(sp)
    80002fd2:	ec4e                	sd	s3,24(sp)
    80002fd4:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002fd6:	fcc40593          	addi	a1,s0,-52
    80002fda:	4501                	li	a0,0
    80002fdc:	00000097          	auipc	ra,0x0
    80002fe0:	e2a080e7          	jalr	-470(ra) # 80002e06 <argint>
    return -1;
    80002fe4:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002fe6:	06054563          	bltz	a0,80003050 <sys_sleep+0x88>
  acquire(&tickslock);
    80002fea:	00015517          	auipc	a0,0x15
    80002fee:	3be50513          	addi	a0,a0,958 # 800183a8 <tickslock>
    80002ff2:	ffffe097          	auipc	ra,0xffffe
    80002ff6:	d0e080e7          	jalr	-754(ra) # 80000d00 <acquire>
  ticks0 = ticks;
    80002ffa:	00006917          	auipc	s2,0x6
    80002ffe:	02692903          	lw	s2,38(s2) # 80009020 <ticks>
  while(ticks - ticks0 < n){
    80003002:	fcc42783          	lw	a5,-52(s0)
    80003006:	cf85                	beqz	a5,8000303e <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80003008:	00015997          	auipc	s3,0x15
    8000300c:	3a098993          	addi	s3,s3,928 # 800183a8 <tickslock>
    80003010:	00006497          	auipc	s1,0x6
    80003014:	01048493          	addi	s1,s1,16 # 80009020 <ticks>
    if(myproc()->killed){
    80003018:	fffff097          	auipc	ra,0xfffff
    8000301c:	d2e080e7          	jalr	-722(ra) # 80001d46 <myproc>
    80003020:	5d1c                	lw	a5,56(a0)
    80003022:	ef9d                	bnez	a5,80003060 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80003024:	85ce                	mv	a1,s3
    80003026:	8526                	mv	a0,s1
    80003028:	fffff097          	auipc	ra,0xfffff
    8000302c:	536080e7          	jalr	1334(ra) # 8000255e <sleep>
  while(ticks - ticks0 < n){
    80003030:	409c                	lw	a5,0(s1)
    80003032:	412787bb          	subw	a5,a5,s2
    80003036:	fcc42703          	lw	a4,-52(s0)
    8000303a:	fce7efe3          	bltu	a5,a4,80003018 <sys_sleep+0x50>
  }
  release(&tickslock);
    8000303e:	00015517          	auipc	a0,0x15
    80003042:	36a50513          	addi	a0,a0,874 # 800183a8 <tickslock>
    80003046:	ffffe097          	auipc	ra,0xffffe
    8000304a:	d8a080e7          	jalr	-630(ra) # 80000dd0 <release>
  return 0;
    8000304e:	4781                	li	a5,0
}
    80003050:	853e                	mv	a0,a5
    80003052:	70e2                	ld	ra,56(sp)
    80003054:	7442                	ld	s0,48(sp)
    80003056:	74a2                	ld	s1,40(sp)
    80003058:	7902                	ld	s2,32(sp)
    8000305a:	69e2                	ld	s3,24(sp)
    8000305c:	6121                	addi	sp,sp,64
    8000305e:	8082                	ret
      release(&tickslock);
    80003060:	00015517          	auipc	a0,0x15
    80003064:	34850513          	addi	a0,a0,840 # 800183a8 <tickslock>
    80003068:	ffffe097          	auipc	ra,0xffffe
    8000306c:	d68080e7          	jalr	-664(ra) # 80000dd0 <release>
      return -1;
    80003070:	57fd                	li	a5,-1
    80003072:	bff9                	j	80003050 <sys_sleep+0x88>

0000000080003074 <sys_kill>:

uint64
sys_kill(void)
{
    80003074:	1101                	addi	sp,sp,-32
    80003076:	ec06                	sd	ra,24(sp)
    80003078:	e822                	sd	s0,16(sp)
    8000307a:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    8000307c:	fec40593          	addi	a1,s0,-20
    80003080:	4501                	li	a0,0
    80003082:	00000097          	auipc	ra,0x0
    80003086:	d84080e7          	jalr	-636(ra) # 80002e06 <argint>
    8000308a:	87aa                	mv	a5,a0
    return -1;
    8000308c:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    8000308e:	0007c863          	bltz	a5,8000309e <sys_kill+0x2a>
  return kill(pid);
    80003092:	fec42503          	lw	a0,-20(s0)
    80003096:	fffff097          	auipc	ra,0xfffff
    8000309a:	6b2080e7          	jalr	1714(ra) # 80002748 <kill>
}
    8000309e:	60e2                	ld	ra,24(sp)
    800030a0:	6442                	ld	s0,16(sp)
    800030a2:	6105                	addi	sp,sp,32
    800030a4:	8082                	ret

00000000800030a6 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    800030a6:	1101                	addi	sp,sp,-32
    800030a8:	ec06                	sd	ra,24(sp)
    800030aa:	e822                	sd	s0,16(sp)
    800030ac:	e426                	sd	s1,8(sp)
    800030ae:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    800030b0:	00015517          	auipc	a0,0x15
    800030b4:	2f850513          	addi	a0,a0,760 # 800183a8 <tickslock>
    800030b8:	ffffe097          	auipc	ra,0xffffe
    800030bc:	c48080e7          	jalr	-952(ra) # 80000d00 <acquire>
  xticks = ticks;
    800030c0:	00006497          	auipc	s1,0x6
    800030c4:	f604a483          	lw	s1,-160(s1) # 80009020 <ticks>
  release(&tickslock);
    800030c8:	00015517          	auipc	a0,0x15
    800030cc:	2e050513          	addi	a0,a0,736 # 800183a8 <tickslock>
    800030d0:	ffffe097          	auipc	ra,0xffffe
    800030d4:	d00080e7          	jalr	-768(ra) # 80000dd0 <release>
  return xticks;
}
    800030d8:	02049513          	slli	a0,s1,0x20
    800030dc:	9101                	srli	a0,a0,0x20
    800030de:	60e2                	ld	ra,24(sp)
    800030e0:	6442                	ld	s0,16(sp)
    800030e2:	64a2                	ld	s1,8(sp)
    800030e4:	6105                	addi	sp,sp,32
    800030e6:	8082                	ret

00000000800030e8 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    800030e8:	7179                	addi	sp,sp,-48
    800030ea:	f406                	sd	ra,40(sp)
    800030ec:	f022                	sd	s0,32(sp)
    800030ee:	ec26                	sd	s1,24(sp)
    800030f0:	e84a                	sd	s2,16(sp)
    800030f2:	e44e                	sd	s3,8(sp)
    800030f4:	e052                	sd	s4,0(sp)
    800030f6:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    800030f8:	00005597          	auipc	a1,0x5
    800030fc:	00058593          	mv	a1,a1
    80003100:	00015517          	auipc	a0,0x15
    80003104:	2c850513          	addi	a0,a0,712 # 800183c8 <bcache>
    80003108:	ffffe097          	auipc	ra,0xffffe
    8000310c:	d74080e7          	jalr	-652(ra) # 80000e7c <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80003110:	0001d797          	auipc	a5,0x1d
    80003114:	2b878793          	addi	a5,a5,696 # 800203c8 <bcache+0x8000>
    80003118:	0001d717          	auipc	a4,0x1d
    8000311c:	61070713          	addi	a4,a4,1552 # 80020728 <bcache+0x8360>
    80003120:	3ae7b823          	sd	a4,944(a5)
  bcache.head.next = &bcache.head;
    80003124:	3ae7bc23          	sd	a4,952(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003128:	00015497          	auipc	s1,0x15
    8000312c:	2c048493          	addi	s1,s1,704 # 800183e8 <bcache+0x20>
    b->next = bcache.head.next;
    80003130:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80003132:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80003134:	00005a17          	auipc	s4,0x5
    80003138:	434a0a13          	addi	s4,s4,1076 # 80008568 <syscalls+0xb0>
    b->next = bcache.head.next;
    8000313c:	3b893783          	ld	a5,952(s2)
    80003140:	ecbc                	sd	a5,88(s1)
    b->prev = &bcache.head;
    80003142:	0534b823          	sd	s3,80(s1)
    initsleeplock(&b->lock, "buffer");
    80003146:	85d2                	mv	a1,s4
    80003148:	01048513          	addi	a0,s1,16
    8000314c:	00001097          	auipc	ra,0x1
    80003150:	4c8080e7          	jalr	1224(ra) # 80004614 <initsleeplock>
    bcache.head.next->prev = b;
    80003154:	3b893783          	ld	a5,952(s2)
    80003158:	eba4                	sd	s1,80(a5)
    bcache.head.next = b;
    8000315a:	3a993c23          	sd	s1,952(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    8000315e:	46048493          	addi	s1,s1,1120
    80003162:	fd349de3          	bne	s1,s3,8000313c <binit+0x54>
  }
}
    80003166:	70a2                	ld	ra,40(sp)
    80003168:	7402                	ld	s0,32(sp)
    8000316a:	64e2                	ld	s1,24(sp)
    8000316c:	6942                	ld	s2,16(sp)
    8000316e:	69a2                	ld	s3,8(sp)
    80003170:	6a02                	ld	s4,0(sp)
    80003172:	6145                	addi	sp,sp,48
    80003174:	8082                	ret

0000000080003176 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80003176:	7179                	addi	sp,sp,-48
    80003178:	f406                	sd	ra,40(sp)
    8000317a:	f022                	sd	s0,32(sp)
    8000317c:	ec26                	sd	s1,24(sp)
    8000317e:	e84a                	sd	s2,16(sp)
    80003180:	e44e                	sd	s3,8(sp)
    80003182:	1800                	addi	s0,sp,48
    80003184:	892a                	mv	s2,a0
    80003186:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    80003188:	00015517          	auipc	a0,0x15
    8000318c:	24050513          	addi	a0,a0,576 # 800183c8 <bcache>
    80003190:	ffffe097          	auipc	ra,0xffffe
    80003194:	b70080e7          	jalr	-1168(ra) # 80000d00 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80003198:	0001d497          	auipc	s1,0x1d
    8000319c:	5e84b483          	ld	s1,1512(s1) # 80020780 <bcache+0x83b8>
    800031a0:	0001d797          	auipc	a5,0x1d
    800031a4:	58878793          	addi	a5,a5,1416 # 80020728 <bcache+0x8360>
    800031a8:	02f48f63          	beq	s1,a5,800031e6 <bread+0x70>
    800031ac:	873e                	mv	a4,a5
    800031ae:	a021                	j	800031b6 <bread+0x40>
    800031b0:	6ca4                	ld	s1,88(s1)
    800031b2:	02e48a63          	beq	s1,a4,800031e6 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    800031b6:	449c                	lw	a5,8(s1)
    800031b8:	ff279ce3          	bne	a5,s2,800031b0 <bread+0x3a>
    800031bc:	44dc                	lw	a5,12(s1)
    800031be:	ff3799e3          	bne	a5,s3,800031b0 <bread+0x3a>
      b->refcnt++;
    800031c2:	44bc                	lw	a5,72(s1)
    800031c4:	2785                	addiw	a5,a5,1
    800031c6:	c4bc                	sw	a5,72(s1)
      release(&bcache.lock);
    800031c8:	00015517          	auipc	a0,0x15
    800031cc:	20050513          	addi	a0,a0,512 # 800183c8 <bcache>
    800031d0:	ffffe097          	auipc	ra,0xffffe
    800031d4:	c00080e7          	jalr	-1024(ra) # 80000dd0 <release>
      acquiresleep(&b->lock);
    800031d8:	01048513          	addi	a0,s1,16
    800031dc:	00001097          	auipc	ra,0x1
    800031e0:	472080e7          	jalr	1138(ra) # 8000464e <acquiresleep>
      return b;
    800031e4:	a8b9                	j	80003242 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800031e6:	0001d497          	auipc	s1,0x1d
    800031ea:	5924b483          	ld	s1,1426(s1) # 80020778 <bcache+0x83b0>
    800031ee:	0001d797          	auipc	a5,0x1d
    800031f2:	53a78793          	addi	a5,a5,1338 # 80020728 <bcache+0x8360>
    800031f6:	00f48863          	beq	s1,a5,80003206 <bread+0x90>
    800031fa:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    800031fc:	44bc                	lw	a5,72(s1)
    800031fe:	cf81                	beqz	a5,80003216 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003200:	68a4                	ld	s1,80(s1)
    80003202:	fee49de3          	bne	s1,a4,800031fc <bread+0x86>
  panic("bget: no buffers");
    80003206:	00005517          	auipc	a0,0x5
    8000320a:	36a50513          	addi	a0,a0,874 # 80008570 <syscalls+0xb8>
    8000320e:	ffffd097          	auipc	ra,0xffffd
    80003212:	33e080e7          	jalr	830(ra) # 8000054c <panic>
      b->dev = dev;
    80003216:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    8000321a:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    8000321e:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003222:	4785                	li	a5,1
    80003224:	c4bc                	sw	a5,72(s1)
      release(&bcache.lock);
    80003226:	00015517          	auipc	a0,0x15
    8000322a:	1a250513          	addi	a0,a0,418 # 800183c8 <bcache>
    8000322e:	ffffe097          	auipc	ra,0xffffe
    80003232:	ba2080e7          	jalr	-1118(ra) # 80000dd0 <release>
      acquiresleep(&b->lock);
    80003236:	01048513          	addi	a0,s1,16
    8000323a:	00001097          	auipc	ra,0x1
    8000323e:	414080e7          	jalr	1044(ra) # 8000464e <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003242:	409c                	lw	a5,0(s1)
    80003244:	cb89                	beqz	a5,80003256 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003246:	8526                	mv	a0,s1
    80003248:	70a2                	ld	ra,40(sp)
    8000324a:	7402                	ld	s0,32(sp)
    8000324c:	64e2                	ld	s1,24(sp)
    8000324e:	6942                	ld	s2,16(sp)
    80003250:	69a2                	ld	s3,8(sp)
    80003252:	6145                	addi	sp,sp,48
    80003254:	8082                	ret
    virtio_disk_rw(b, 0);
    80003256:	4581                	li	a1,0
    80003258:	8526                	mv	a0,s1
    8000325a:	00003097          	auipc	ra,0x3
    8000325e:	f68080e7          	jalr	-152(ra) # 800061c2 <virtio_disk_rw>
    b->valid = 1;
    80003262:	4785                	li	a5,1
    80003264:	c09c                	sw	a5,0(s1)
  return b;
    80003266:	b7c5                	j	80003246 <bread+0xd0>

0000000080003268 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003268:	1101                	addi	sp,sp,-32
    8000326a:	ec06                	sd	ra,24(sp)
    8000326c:	e822                	sd	s0,16(sp)
    8000326e:	e426                	sd	s1,8(sp)
    80003270:	1000                	addi	s0,sp,32
    80003272:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003274:	0541                	addi	a0,a0,16
    80003276:	00001097          	auipc	ra,0x1
    8000327a:	472080e7          	jalr	1138(ra) # 800046e8 <holdingsleep>
    8000327e:	cd01                	beqz	a0,80003296 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003280:	4585                	li	a1,1
    80003282:	8526                	mv	a0,s1
    80003284:	00003097          	auipc	ra,0x3
    80003288:	f3e080e7          	jalr	-194(ra) # 800061c2 <virtio_disk_rw>
}
    8000328c:	60e2                	ld	ra,24(sp)
    8000328e:	6442                	ld	s0,16(sp)
    80003290:	64a2                	ld	s1,8(sp)
    80003292:	6105                	addi	sp,sp,32
    80003294:	8082                	ret
    panic("bwrite");
    80003296:	00005517          	auipc	a0,0x5
    8000329a:	2f250513          	addi	a0,a0,754 # 80008588 <syscalls+0xd0>
    8000329e:	ffffd097          	auipc	ra,0xffffd
    800032a2:	2ae080e7          	jalr	686(ra) # 8000054c <panic>

00000000800032a6 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    800032a6:	1101                	addi	sp,sp,-32
    800032a8:	ec06                	sd	ra,24(sp)
    800032aa:	e822                	sd	s0,16(sp)
    800032ac:	e426                	sd	s1,8(sp)
    800032ae:	e04a                	sd	s2,0(sp)
    800032b0:	1000                	addi	s0,sp,32
    800032b2:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800032b4:	01050913          	addi	s2,a0,16
    800032b8:	854a                	mv	a0,s2
    800032ba:	00001097          	auipc	ra,0x1
    800032be:	42e080e7          	jalr	1070(ra) # 800046e8 <holdingsleep>
    800032c2:	c92d                	beqz	a0,80003334 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    800032c4:	854a                	mv	a0,s2
    800032c6:	00001097          	auipc	ra,0x1
    800032ca:	3de080e7          	jalr	990(ra) # 800046a4 <releasesleep>

  acquire(&bcache.lock);
    800032ce:	00015517          	auipc	a0,0x15
    800032d2:	0fa50513          	addi	a0,a0,250 # 800183c8 <bcache>
    800032d6:	ffffe097          	auipc	ra,0xffffe
    800032da:	a2a080e7          	jalr	-1494(ra) # 80000d00 <acquire>
  b->refcnt--;
    800032de:	44bc                	lw	a5,72(s1)
    800032e0:	37fd                	addiw	a5,a5,-1
    800032e2:	0007871b          	sext.w	a4,a5
    800032e6:	c4bc                	sw	a5,72(s1)
  if (b->refcnt == 0) {
    800032e8:	eb05                	bnez	a4,80003318 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    800032ea:	6cbc                	ld	a5,88(s1)
    800032ec:	68b8                	ld	a4,80(s1)
    800032ee:	ebb8                	sd	a4,80(a5)
    b->prev->next = b->next;
    800032f0:	68bc                	ld	a5,80(s1)
    800032f2:	6cb8                	ld	a4,88(s1)
    800032f4:	efb8                	sd	a4,88(a5)
    b->next = bcache.head.next;
    800032f6:	0001d797          	auipc	a5,0x1d
    800032fa:	0d278793          	addi	a5,a5,210 # 800203c8 <bcache+0x8000>
    800032fe:	3b87b703          	ld	a4,952(a5)
    80003302:	ecb8                	sd	a4,88(s1)
    b->prev = &bcache.head;
    80003304:	0001d717          	auipc	a4,0x1d
    80003308:	42470713          	addi	a4,a4,1060 # 80020728 <bcache+0x8360>
    8000330c:	e8b8                	sd	a4,80(s1)
    bcache.head.next->prev = b;
    8000330e:	3b87b703          	ld	a4,952(a5)
    80003312:	eb24                	sd	s1,80(a4)
    bcache.head.next = b;
    80003314:	3a97bc23          	sd	s1,952(a5)
  }
  
  release(&bcache.lock);
    80003318:	00015517          	auipc	a0,0x15
    8000331c:	0b050513          	addi	a0,a0,176 # 800183c8 <bcache>
    80003320:	ffffe097          	auipc	ra,0xffffe
    80003324:	ab0080e7          	jalr	-1360(ra) # 80000dd0 <release>
}
    80003328:	60e2                	ld	ra,24(sp)
    8000332a:	6442                	ld	s0,16(sp)
    8000332c:	64a2                	ld	s1,8(sp)
    8000332e:	6902                	ld	s2,0(sp)
    80003330:	6105                	addi	sp,sp,32
    80003332:	8082                	ret
    panic("brelse");
    80003334:	00005517          	auipc	a0,0x5
    80003338:	25c50513          	addi	a0,a0,604 # 80008590 <syscalls+0xd8>
    8000333c:	ffffd097          	auipc	ra,0xffffd
    80003340:	210080e7          	jalr	528(ra) # 8000054c <panic>

0000000080003344 <bpin>:

void
bpin(struct buf *b) {
    80003344:	1101                	addi	sp,sp,-32
    80003346:	ec06                	sd	ra,24(sp)
    80003348:	e822                	sd	s0,16(sp)
    8000334a:	e426                	sd	s1,8(sp)
    8000334c:	1000                	addi	s0,sp,32
    8000334e:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003350:	00015517          	auipc	a0,0x15
    80003354:	07850513          	addi	a0,a0,120 # 800183c8 <bcache>
    80003358:	ffffe097          	auipc	ra,0xffffe
    8000335c:	9a8080e7          	jalr	-1624(ra) # 80000d00 <acquire>
  b->refcnt++;
    80003360:	44bc                	lw	a5,72(s1)
    80003362:	2785                	addiw	a5,a5,1
    80003364:	c4bc                	sw	a5,72(s1)
  release(&bcache.lock);
    80003366:	00015517          	auipc	a0,0x15
    8000336a:	06250513          	addi	a0,a0,98 # 800183c8 <bcache>
    8000336e:	ffffe097          	auipc	ra,0xffffe
    80003372:	a62080e7          	jalr	-1438(ra) # 80000dd0 <release>
}
    80003376:	60e2                	ld	ra,24(sp)
    80003378:	6442                	ld	s0,16(sp)
    8000337a:	64a2                	ld	s1,8(sp)
    8000337c:	6105                	addi	sp,sp,32
    8000337e:	8082                	ret

0000000080003380 <bunpin>:

void
bunpin(struct buf *b) {
    80003380:	1101                	addi	sp,sp,-32
    80003382:	ec06                	sd	ra,24(sp)
    80003384:	e822                	sd	s0,16(sp)
    80003386:	e426                	sd	s1,8(sp)
    80003388:	1000                	addi	s0,sp,32
    8000338a:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000338c:	00015517          	auipc	a0,0x15
    80003390:	03c50513          	addi	a0,a0,60 # 800183c8 <bcache>
    80003394:	ffffe097          	auipc	ra,0xffffe
    80003398:	96c080e7          	jalr	-1684(ra) # 80000d00 <acquire>
  b->refcnt--;
    8000339c:	44bc                	lw	a5,72(s1)
    8000339e:	37fd                	addiw	a5,a5,-1
    800033a0:	c4bc                	sw	a5,72(s1)
  release(&bcache.lock);
    800033a2:	00015517          	auipc	a0,0x15
    800033a6:	02650513          	addi	a0,a0,38 # 800183c8 <bcache>
    800033aa:	ffffe097          	auipc	ra,0xffffe
    800033ae:	a26080e7          	jalr	-1498(ra) # 80000dd0 <release>
}
    800033b2:	60e2                	ld	ra,24(sp)
    800033b4:	6442                	ld	s0,16(sp)
    800033b6:	64a2                	ld	s1,8(sp)
    800033b8:	6105                	addi	sp,sp,32
    800033ba:	8082                	ret

00000000800033bc <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800033bc:	1101                	addi	sp,sp,-32
    800033be:	ec06                	sd	ra,24(sp)
    800033c0:	e822                	sd	s0,16(sp)
    800033c2:	e426                	sd	s1,8(sp)
    800033c4:	e04a                	sd	s2,0(sp)
    800033c6:	1000                	addi	s0,sp,32
    800033c8:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800033ca:	00d5d59b          	srliw	a1,a1,0xd
    800033ce:	0001d797          	auipc	a5,0x1d
    800033d2:	7d67a783          	lw	a5,2006(a5) # 80020ba4 <sb+0x1c>
    800033d6:	9dbd                	addw	a1,a1,a5
    800033d8:	00000097          	auipc	ra,0x0
    800033dc:	d9e080e7          	jalr	-610(ra) # 80003176 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800033e0:	0074f713          	andi	a4,s1,7
    800033e4:	4785                	li	a5,1
    800033e6:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800033ea:	14ce                	slli	s1,s1,0x33
    800033ec:	90d9                	srli	s1,s1,0x36
    800033ee:	00950733          	add	a4,a0,s1
    800033f2:	06074703          	lbu	a4,96(a4)
    800033f6:	00e7f6b3          	and	a3,a5,a4
    800033fa:	c69d                	beqz	a3,80003428 <bfree+0x6c>
    800033fc:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800033fe:	94aa                	add	s1,s1,a0
    80003400:	fff7c793          	not	a5,a5
    80003404:	8f7d                	and	a4,a4,a5
    80003406:	06e48023          	sb	a4,96(s1)
  log_write(bp);
    8000340a:	00001097          	auipc	ra,0x1
    8000340e:	11e080e7          	jalr	286(ra) # 80004528 <log_write>
  brelse(bp);
    80003412:	854a                	mv	a0,s2
    80003414:	00000097          	auipc	ra,0x0
    80003418:	e92080e7          	jalr	-366(ra) # 800032a6 <brelse>
}
    8000341c:	60e2                	ld	ra,24(sp)
    8000341e:	6442                	ld	s0,16(sp)
    80003420:	64a2                	ld	s1,8(sp)
    80003422:	6902                	ld	s2,0(sp)
    80003424:	6105                	addi	sp,sp,32
    80003426:	8082                	ret
    panic("freeing free block");
    80003428:	00005517          	auipc	a0,0x5
    8000342c:	17050513          	addi	a0,a0,368 # 80008598 <syscalls+0xe0>
    80003430:	ffffd097          	auipc	ra,0xffffd
    80003434:	11c080e7          	jalr	284(ra) # 8000054c <panic>

0000000080003438 <balloc>:
{
    80003438:	711d                	addi	sp,sp,-96
    8000343a:	ec86                	sd	ra,88(sp)
    8000343c:	e8a2                	sd	s0,80(sp)
    8000343e:	e4a6                	sd	s1,72(sp)
    80003440:	e0ca                	sd	s2,64(sp)
    80003442:	fc4e                	sd	s3,56(sp)
    80003444:	f852                	sd	s4,48(sp)
    80003446:	f456                	sd	s5,40(sp)
    80003448:	f05a                	sd	s6,32(sp)
    8000344a:	ec5e                	sd	s7,24(sp)
    8000344c:	e862                	sd	s8,16(sp)
    8000344e:	e466                	sd	s9,8(sp)
    80003450:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003452:	0001d797          	auipc	a5,0x1d
    80003456:	73a7a783          	lw	a5,1850(a5) # 80020b8c <sb+0x4>
    8000345a:	cbc1                	beqz	a5,800034ea <balloc+0xb2>
    8000345c:	8baa                	mv	s7,a0
    8000345e:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003460:	0001db17          	auipc	s6,0x1d
    80003464:	728b0b13          	addi	s6,s6,1832 # 80020b88 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003468:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    8000346a:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000346c:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    8000346e:	6c89                	lui	s9,0x2
    80003470:	a831                	j	8000348c <balloc+0x54>
    brelse(bp);
    80003472:	854a                	mv	a0,s2
    80003474:	00000097          	auipc	ra,0x0
    80003478:	e32080e7          	jalr	-462(ra) # 800032a6 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    8000347c:	015c87bb          	addw	a5,s9,s5
    80003480:	00078a9b          	sext.w	s5,a5
    80003484:	004b2703          	lw	a4,4(s6)
    80003488:	06eaf163          	bgeu	s5,a4,800034ea <balloc+0xb2>
    bp = bread(dev, BBLOCK(b, sb));
    8000348c:	41fad79b          	sraiw	a5,s5,0x1f
    80003490:	0137d79b          	srliw	a5,a5,0x13
    80003494:	015787bb          	addw	a5,a5,s5
    80003498:	40d7d79b          	sraiw	a5,a5,0xd
    8000349c:	01cb2583          	lw	a1,28(s6)
    800034a0:	9dbd                	addw	a1,a1,a5
    800034a2:	855e                	mv	a0,s7
    800034a4:	00000097          	auipc	ra,0x0
    800034a8:	cd2080e7          	jalr	-814(ra) # 80003176 <bread>
    800034ac:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800034ae:	004b2503          	lw	a0,4(s6)
    800034b2:	000a849b          	sext.w	s1,s5
    800034b6:	8762                	mv	a4,s8
    800034b8:	faa4fde3          	bgeu	s1,a0,80003472 <balloc+0x3a>
      m = 1 << (bi % 8);
    800034bc:	00777693          	andi	a3,a4,7
    800034c0:	00d996bb          	sllw	a3,s3,a3
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800034c4:	41f7579b          	sraiw	a5,a4,0x1f
    800034c8:	01d7d79b          	srliw	a5,a5,0x1d
    800034cc:	9fb9                	addw	a5,a5,a4
    800034ce:	4037d79b          	sraiw	a5,a5,0x3
    800034d2:	00f90633          	add	a2,s2,a5
    800034d6:	06064603          	lbu	a2,96(a2)
    800034da:	00c6f5b3          	and	a1,a3,a2
    800034de:	cd91                	beqz	a1,800034fa <balloc+0xc2>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800034e0:	2705                	addiw	a4,a4,1
    800034e2:	2485                	addiw	s1,s1,1
    800034e4:	fd471ae3          	bne	a4,s4,800034b8 <balloc+0x80>
    800034e8:	b769                	j	80003472 <balloc+0x3a>
  panic("balloc: out of blocks");
    800034ea:	00005517          	auipc	a0,0x5
    800034ee:	0c650513          	addi	a0,a0,198 # 800085b0 <syscalls+0xf8>
    800034f2:	ffffd097          	auipc	ra,0xffffd
    800034f6:	05a080e7          	jalr	90(ra) # 8000054c <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    800034fa:	97ca                	add	a5,a5,s2
    800034fc:	8e55                	or	a2,a2,a3
    800034fe:	06c78023          	sb	a2,96(a5)
        log_write(bp);
    80003502:	854a                	mv	a0,s2
    80003504:	00001097          	auipc	ra,0x1
    80003508:	024080e7          	jalr	36(ra) # 80004528 <log_write>
        brelse(bp);
    8000350c:	854a                	mv	a0,s2
    8000350e:	00000097          	auipc	ra,0x0
    80003512:	d98080e7          	jalr	-616(ra) # 800032a6 <brelse>
  bp = bread(dev, bno);
    80003516:	85a6                	mv	a1,s1
    80003518:	855e                	mv	a0,s7
    8000351a:	00000097          	auipc	ra,0x0
    8000351e:	c5c080e7          	jalr	-932(ra) # 80003176 <bread>
    80003522:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003524:	40000613          	li	a2,1024
    80003528:	4581                	li	a1,0
    8000352a:	06050513          	addi	a0,a0,96
    8000352e:	ffffe097          	auipc	ra,0xffffe
    80003532:	bb2080e7          	jalr	-1102(ra) # 800010e0 <memset>
  log_write(bp);
    80003536:	854a                	mv	a0,s2
    80003538:	00001097          	auipc	ra,0x1
    8000353c:	ff0080e7          	jalr	-16(ra) # 80004528 <log_write>
  brelse(bp);
    80003540:	854a                	mv	a0,s2
    80003542:	00000097          	auipc	ra,0x0
    80003546:	d64080e7          	jalr	-668(ra) # 800032a6 <brelse>
}
    8000354a:	8526                	mv	a0,s1
    8000354c:	60e6                	ld	ra,88(sp)
    8000354e:	6446                	ld	s0,80(sp)
    80003550:	64a6                	ld	s1,72(sp)
    80003552:	6906                	ld	s2,64(sp)
    80003554:	79e2                	ld	s3,56(sp)
    80003556:	7a42                	ld	s4,48(sp)
    80003558:	7aa2                	ld	s5,40(sp)
    8000355a:	7b02                	ld	s6,32(sp)
    8000355c:	6be2                	ld	s7,24(sp)
    8000355e:	6c42                	ld	s8,16(sp)
    80003560:	6ca2                	ld	s9,8(sp)
    80003562:	6125                	addi	sp,sp,96
    80003564:	8082                	ret

0000000080003566 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    80003566:	7179                	addi	sp,sp,-48
    80003568:	f406                	sd	ra,40(sp)
    8000356a:	f022                	sd	s0,32(sp)
    8000356c:	ec26                	sd	s1,24(sp)
    8000356e:	e84a                	sd	s2,16(sp)
    80003570:	e44e                	sd	s3,8(sp)
    80003572:	e052                	sd	s4,0(sp)
    80003574:	1800                	addi	s0,sp,48
    80003576:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003578:	47ad                	li	a5,11
    8000357a:	04b7fe63          	bgeu	a5,a1,800035d6 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    8000357e:	ff45849b          	addiw	s1,a1,-12 # ffffffff800080ec <end+0xfffffffefffe00c4>
    80003582:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003586:	0ff00793          	li	a5,255
    8000358a:	0ae7e463          	bltu	a5,a4,80003632 <bmap+0xcc>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    8000358e:	08852583          	lw	a1,136(a0)
    80003592:	c5b5                	beqz	a1,800035fe <bmap+0x98>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    80003594:	00092503          	lw	a0,0(s2)
    80003598:	00000097          	auipc	ra,0x0
    8000359c:	bde080e7          	jalr	-1058(ra) # 80003176 <bread>
    800035a0:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    800035a2:	06050793          	addi	a5,a0,96
    if((addr = a[bn]) == 0){
    800035a6:	02049713          	slli	a4,s1,0x20
    800035aa:	01e75593          	srli	a1,a4,0x1e
    800035ae:	00b784b3          	add	s1,a5,a1
    800035b2:	0004a983          	lw	s3,0(s1)
    800035b6:	04098e63          	beqz	s3,80003612 <bmap+0xac>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    800035ba:	8552                	mv	a0,s4
    800035bc:	00000097          	auipc	ra,0x0
    800035c0:	cea080e7          	jalr	-790(ra) # 800032a6 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    800035c4:	854e                	mv	a0,s3
    800035c6:	70a2                	ld	ra,40(sp)
    800035c8:	7402                	ld	s0,32(sp)
    800035ca:	64e2                	ld	s1,24(sp)
    800035cc:	6942                	ld	s2,16(sp)
    800035ce:	69a2                	ld	s3,8(sp)
    800035d0:	6a02                	ld	s4,0(sp)
    800035d2:	6145                	addi	sp,sp,48
    800035d4:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    800035d6:	02059793          	slli	a5,a1,0x20
    800035da:	01e7d593          	srli	a1,a5,0x1e
    800035de:	00b504b3          	add	s1,a0,a1
    800035e2:	0584a983          	lw	s3,88(s1)
    800035e6:	fc099fe3          	bnez	s3,800035c4 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    800035ea:	4108                	lw	a0,0(a0)
    800035ec:	00000097          	auipc	ra,0x0
    800035f0:	e4c080e7          	jalr	-436(ra) # 80003438 <balloc>
    800035f4:	0005099b          	sext.w	s3,a0
    800035f8:	0534ac23          	sw	s3,88(s1)
    800035fc:	b7e1                	j	800035c4 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    800035fe:	4108                	lw	a0,0(a0)
    80003600:	00000097          	auipc	ra,0x0
    80003604:	e38080e7          	jalr	-456(ra) # 80003438 <balloc>
    80003608:	0005059b          	sext.w	a1,a0
    8000360c:	08b92423          	sw	a1,136(s2)
    80003610:	b751                	j	80003594 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    80003612:	00092503          	lw	a0,0(s2)
    80003616:	00000097          	auipc	ra,0x0
    8000361a:	e22080e7          	jalr	-478(ra) # 80003438 <balloc>
    8000361e:	0005099b          	sext.w	s3,a0
    80003622:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    80003626:	8552                	mv	a0,s4
    80003628:	00001097          	auipc	ra,0x1
    8000362c:	f00080e7          	jalr	-256(ra) # 80004528 <log_write>
    80003630:	b769                	j	800035ba <bmap+0x54>
  panic("bmap: out of range");
    80003632:	00005517          	auipc	a0,0x5
    80003636:	f9650513          	addi	a0,a0,-106 # 800085c8 <syscalls+0x110>
    8000363a:	ffffd097          	auipc	ra,0xffffd
    8000363e:	f12080e7          	jalr	-238(ra) # 8000054c <panic>

0000000080003642 <iget>:
{
    80003642:	7179                	addi	sp,sp,-48
    80003644:	f406                	sd	ra,40(sp)
    80003646:	f022                	sd	s0,32(sp)
    80003648:	ec26                	sd	s1,24(sp)
    8000364a:	e84a                	sd	s2,16(sp)
    8000364c:	e44e                	sd	s3,8(sp)
    8000364e:	e052                	sd	s4,0(sp)
    80003650:	1800                	addi	s0,sp,48
    80003652:	89aa                	mv	s3,a0
    80003654:	8a2e                	mv	s4,a1
  acquire(&icache.lock);
    80003656:	0001d517          	auipc	a0,0x1d
    8000365a:	55250513          	addi	a0,a0,1362 # 80020ba8 <icache>
    8000365e:	ffffd097          	auipc	ra,0xffffd
    80003662:	6a2080e7          	jalr	1698(ra) # 80000d00 <acquire>
  empty = 0;
    80003666:	4901                	li	s2,0
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    80003668:	0001d497          	auipc	s1,0x1d
    8000366c:	56048493          	addi	s1,s1,1376 # 80020bc8 <icache+0x20>
    80003670:	0001f697          	auipc	a3,0x1f
    80003674:	17868693          	addi	a3,a3,376 # 800227e8 <log>
    80003678:	a039                	j	80003686 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000367a:	02090b63          	beqz	s2,800036b0 <iget+0x6e>
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    8000367e:	09048493          	addi	s1,s1,144
    80003682:	02d48a63          	beq	s1,a3,800036b6 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003686:	449c                	lw	a5,8(s1)
    80003688:	fef059e3          	blez	a5,8000367a <iget+0x38>
    8000368c:	4098                	lw	a4,0(s1)
    8000368e:	ff3716e3          	bne	a4,s3,8000367a <iget+0x38>
    80003692:	40d8                	lw	a4,4(s1)
    80003694:	ff4713e3          	bne	a4,s4,8000367a <iget+0x38>
      ip->ref++;
    80003698:	2785                	addiw	a5,a5,1
    8000369a:	c49c                	sw	a5,8(s1)
      release(&icache.lock);
    8000369c:	0001d517          	auipc	a0,0x1d
    800036a0:	50c50513          	addi	a0,a0,1292 # 80020ba8 <icache>
    800036a4:	ffffd097          	auipc	ra,0xffffd
    800036a8:	72c080e7          	jalr	1836(ra) # 80000dd0 <release>
      return ip;
    800036ac:	8926                	mv	s2,s1
    800036ae:	a03d                	j	800036dc <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800036b0:	f7f9                	bnez	a5,8000367e <iget+0x3c>
    800036b2:	8926                	mv	s2,s1
    800036b4:	b7e9                	j	8000367e <iget+0x3c>
  if(empty == 0)
    800036b6:	02090c63          	beqz	s2,800036ee <iget+0xac>
  ip->dev = dev;
    800036ba:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    800036be:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    800036c2:	4785                	li	a5,1
    800036c4:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    800036c8:	04092423          	sw	zero,72(s2)
  release(&icache.lock);
    800036cc:	0001d517          	auipc	a0,0x1d
    800036d0:	4dc50513          	addi	a0,a0,1244 # 80020ba8 <icache>
    800036d4:	ffffd097          	auipc	ra,0xffffd
    800036d8:	6fc080e7          	jalr	1788(ra) # 80000dd0 <release>
}
    800036dc:	854a                	mv	a0,s2
    800036de:	70a2                	ld	ra,40(sp)
    800036e0:	7402                	ld	s0,32(sp)
    800036e2:	64e2                	ld	s1,24(sp)
    800036e4:	6942                	ld	s2,16(sp)
    800036e6:	69a2                	ld	s3,8(sp)
    800036e8:	6a02                	ld	s4,0(sp)
    800036ea:	6145                	addi	sp,sp,48
    800036ec:	8082                	ret
    panic("iget: no inodes");
    800036ee:	00005517          	auipc	a0,0x5
    800036f2:	ef250513          	addi	a0,a0,-270 # 800085e0 <syscalls+0x128>
    800036f6:	ffffd097          	auipc	ra,0xffffd
    800036fa:	e56080e7          	jalr	-426(ra) # 8000054c <panic>

00000000800036fe <fsinit>:
fsinit(int dev) {
    800036fe:	7179                	addi	sp,sp,-48
    80003700:	f406                	sd	ra,40(sp)
    80003702:	f022                	sd	s0,32(sp)
    80003704:	ec26                	sd	s1,24(sp)
    80003706:	e84a                	sd	s2,16(sp)
    80003708:	e44e                	sd	s3,8(sp)
    8000370a:	1800                	addi	s0,sp,48
    8000370c:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    8000370e:	4585                	li	a1,1
    80003710:	00000097          	auipc	ra,0x0
    80003714:	a66080e7          	jalr	-1434(ra) # 80003176 <bread>
    80003718:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    8000371a:	0001d997          	auipc	s3,0x1d
    8000371e:	46e98993          	addi	s3,s3,1134 # 80020b88 <sb>
    80003722:	02000613          	li	a2,32
    80003726:	06050593          	addi	a1,a0,96
    8000372a:	854e                	mv	a0,s3
    8000372c:	ffffe097          	auipc	ra,0xffffe
    80003730:	a10080e7          	jalr	-1520(ra) # 8000113c <memmove>
  brelse(bp);
    80003734:	8526                	mv	a0,s1
    80003736:	00000097          	auipc	ra,0x0
    8000373a:	b70080e7          	jalr	-1168(ra) # 800032a6 <brelse>
  if(sb.magic != FSMAGIC)
    8000373e:	0009a703          	lw	a4,0(s3)
    80003742:	102037b7          	lui	a5,0x10203
    80003746:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    8000374a:	02f71263          	bne	a4,a5,8000376e <fsinit+0x70>
  initlog(dev, &sb);
    8000374e:	0001d597          	auipc	a1,0x1d
    80003752:	43a58593          	addi	a1,a1,1082 # 80020b88 <sb>
    80003756:	854a                	mv	a0,s2
    80003758:	00001097          	auipc	ra,0x1
    8000375c:	b54080e7          	jalr	-1196(ra) # 800042ac <initlog>
}
    80003760:	70a2                	ld	ra,40(sp)
    80003762:	7402                	ld	s0,32(sp)
    80003764:	64e2                	ld	s1,24(sp)
    80003766:	6942                	ld	s2,16(sp)
    80003768:	69a2                	ld	s3,8(sp)
    8000376a:	6145                	addi	sp,sp,48
    8000376c:	8082                	ret
    panic("invalid file system");
    8000376e:	00005517          	auipc	a0,0x5
    80003772:	e8250513          	addi	a0,a0,-382 # 800085f0 <syscalls+0x138>
    80003776:	ffffd097          	auipc	ra,0xffffd
    8000377a:	dd6080e7          	jalr	-554(ra) # 8000054c <panic>

000000008000377e <iinit>:
{
    8000377e:	7179                	addi	sp,sp,-48
    80003780:	f406                	sd	ra,40(sp)
    80003782:	f022                	sd	s0,32(sp)
    80003784:	ec26                	sd	s1,24(sp)
    80003786:	e84a                	sd	s2,16(sp)
    80003788:	e44e                	sd	s3,8(sp)
    8000378a:	1800                	addi	s0,sp,48
  initlock(&icache.lock, "icache");
    8000378c:	00005597          	auipc	a1,0x5
    80003790:	e7c58593          	addi	a1,a1,-388 # 80008608 <syscalls+0x150>
    80003794:	0001d517          	auipc	a0,0x1d
    80003798:	41450513          	addi	a0,a0,1044 # 80020ba8 <icache>
    8000379c:	ffffd097          	auipc	ra,0xffffd
    800037a0:	6e0080e7          	jalr	1760(ra) # 80000e7c <initlock>
  for(i = 0; i < NINODE; i++) {
    800037a4:	0001d497          	auipc	s1,0x1d
    800037a8:	43448493          	addi	s1,s1,1076 # 80020bd8 <icache+0x30>
    800037ac:	0001f997          	auipc	s3,0x1f
    800037b0:	04c98993          	addi	s3,s3,76 # 800227f8 <log+0x10>
    initsleeplock(&icache.inode[i].lock, "inode");
    800037b4:	00005917          	auipc	s2,0x5
    800037b8:	e5c90913          	addi	s2,s2,-420 # 80008610 <syscalls+0x158>
    800037bc:	85ca                	mv	a1,s2
    800037be:	8526                	mv	a0,s1
    800037c0:	00001097          	auipc	ra,0x1
    800037c4:	e54080e7          	jalr	-428(ra) # 80004614 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    800037c8:	09048493          	addi	s1,s1,144
    800037cc:	ff3498e3          	bne	s1,s3,800037bc <iinit+0x3e>
}
    800037d0:	70a2                	ld	ra,40(sp)
    800037d2:	7402                	ld	s0,32(sp)
    800037d4:	64e2                	ld	s1,24(sp)
    800037d6:	6942                	ld	s2,16(sp)
    800037d8:	69a2                	ld	s3,8(sp)
    800037da:	6145                	addi	sp,sp,48
    800037dc:	8082                	ret

00000000800037de <ialloc>:
{
    800037de:	715d                	addi	sp,sp,-80
    800037e0:	e486                	sd	ra,72(sp)
    800037e2:	e0a2                	sd	s0,64(sp)
    800037e4:	fc26                	sd	s1,56(sp)
    800037e6:	f84a                	sd	s2,48(sp)
    800037e8:	f44e                	sd	s3,40(sp)
    800037ea:	f052                	sd	s4,32(sp)
    800037ec:	ec56                	sd	s5,24(sp)
    800037ee:	e85a                	sd	s6,16(sp)
    800037f0:	e45e                	sd	s7,8(sp)
    800037f2:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    800037f4:	0001d717          	auipc	a4,0x1d
    800037f8:	3a072703          	lw	a4,928(a4) # 80020b94 <sb+0xc>
    800037fc:	4785                	li	a5,1
    800037fe:	04e7fa63          	bgeu	a5,a4,80003852 <ialloc+0x74>
    80003802:	8aaa                	mv	s5,a0
    80003804:	8bae                	mv	s7,a1
    80003806:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003808:	0001da17          	auipc	s4,0x1d
    8000380c:	380a0a13          	addi	s4,s4,896 # 80020b88 <sb>
    80003810:	00048b1b          	sext.w	s6,s1
    80003814:	0044d593          	srli	a1,s1,0x4
    80003818:	018a2783          	lw	a5,24(s4)
    8000381c:	9dbd                	addw	a1,a1,a5
    8000381e:	8556                	mv	a0,s5
    80003820:	00000097          	auipc	ra,0x0
    80003824:	956080e7          	jalr	-1706(ra) # 80003176 <bread>
    80003828:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    8000382a:	06050993          	addi	s3,a0,96
    8000382e:	00f4f793          	andi	a5,s1,15
    80003832:	079a                	slli	a5,a5,0x6
    80003834:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003836:	00099783          	lh	a5,0(s3)
    8000383a:	c785                	beqz	a5,80003862 <ialloc+0x84>
    brelse(bp);
    8000383c:	00000097          	auipc	ra,0x0
    80003840:	a6a080e7          	jalr	-1430(ra) # 800032a6 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003844:	0485                	addi	s1,s1,1
    80003846:	00ca2703          	lw	a4,12(s4)
    8000384a:	0004879b          	sext.w	a5,s1
    8000384e:	fce7e1e3          	bltu	a5,a4,80003810 <ialloc+0x32>
  panic("ialloc: no inodes");
    80003852:	00005517          	auipc	a0,0x5
    80003856:	dc650513          	addi	a0,a0,-570 # 80008618 <syscalls+0x160>
    8000385a:	ffffd097          	auipc	ra,0xffffd
    8000385e:	cf2080e7          	jalr	-782(ra) # 8000054c <panic>
      memset(dip, 0, sizeof(*dip));
    80003862:	04000613          	li	a2,64
    80003866:	4581                	li	a1,0
    80003868:	854e                	mv	a0,s3
    8000386a:	ffffe097          	auipc	ra,0xffffe
    8000386e:	876080e7          	jalr	-1930(ra) # 800010e0 <memset>
      dip->type = type;
    80003872:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003876:	854a                	mv	a0,s2
    80003878:	00001097          	auipc	ra,0x1
    8000387c:	cb0080e7          	jalr	-848(ra) # 80004528 <log_write>
      brelse(bp);
    80003880:	854a                	mv	a0,s2
    80003882:	00000097          	auipc	ra,0x0
    80003886:	a24080e7          	jalr	-1500(ra) # 800032a6 <brelse>
      return iget(dev, inum);
    8000388a:	85da                	mv	a1,s6
    8000388c:	8556                	mv	a0,s5
    8000388e:	00000097          	auipc	ra,0x0
    80003892:	db4080e7          	jalr	-588(ra) # 80003642 <iget>
}
    80003896:	60a6                	ld	ra,72(sp)
    80003898:	6406                	ld	s0,64(sp)
    8000389a:	74e2                	ld	s1,56(sp)
    8000389c:	7942                	ld	s2,48(sp)
    8000389e:	79a2                	ld	s3,40(sp)
    800038a0:	7a02                	ld	s4,32(sp)
    800038a2:	6ae2                	ld	s5,24(sp)
    800038a4:	6b42                	ld	s6,16(sp)
    800038a6:	6ba2                	ld	s7,8(sp)
    800038a8:	6161                	addi	sp,sp,80
    800038aa:	8082                	ret

00000000800038ac <iupdate>:
{
    800038ac:	1101                	addi	sp,sp,-32
    800038ae:	ec06                	sd	ra,24(sp)
    800038b0:	e822                	sd	s0,16(sp)
    800038b2:	e426                	sd	s1,8(sp)
    800038b4:	e04a                	sd	s2,0(sp)
    800038b6:	1000                	addi	s0,sp,32
    800038b8:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800038ba:	415c                	lw	a5,4(a0)
    800038bc:	0047d79b          	srliw	a5,a5,0x4
    800038c0:	0001d597          	auipc	a1,0x1d
    800038c4:	2e05a583          	lw	a1,736(a1) # 80020ba0 <sb+0x18>
    800038c8:	9dbd                	addw	a1,a1,a5
    800038ca:	4108                	lw	a0,0(a0)
    800038cc:	00000097          	auipc	ra,0x0
    800038d0:	8aa080e7          	jalr	-1878(ra) # 80003176 <bread>
    800038d4:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    800038d6:	06050793          	addi	a5,a0,96
    800038da:	40d8                	lw	a4,4(s1)
    800038dc:	8b3d                	andi	a4,a4,15
    800038de:	071a                	slli	a4,a4,0x6
    800038e0:	97ba                	add	a5,a5,a4
  dip->type = ip->type;
    800038e2:	04c49703          	lh	a4,76(s1)
    800038e6:	00e79023          	sh	a4,0(a5)
  dip->major = ip->major;
    800038ea:	04e49703          	lh	a4,78(s1)
    800038ee:	00e79123          	sh	a4,2(a5)
  dip->minor = ip->minor;
    800038f2:	05049703          	lh	a4,80(s1)
    800038f6:	00e79223          	sh	a4,4(a5)
  dip->nlink = ip->nlink;
    800038fa:	05249703          	lh	a4,82(s1)
    800038fe:	00e79323          	sh	a4,6(a5)
  dip->size = ip->size;
    80003902:	48f8                	lw	a4,84(s1)
    80003904:	c798                	sw	a4,8(a5)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003906:	03400613          	li	a2,52
    8000390a:	05848593          	addi	a1,s1,88
    8000390e:	00c78513          	addi	a0,a5,12
    80003912:	ffffe097          	auipc	ra,0xffffe
    80003916:	82a080e7          	jalr	-2006(ra) # 8000113c <memmove>
  log_write(bp);
    8000391a:	854a                	mv	a0,s2
    8000391c:	00001097          	auipc	ra,0x1
    80003920:	c0c080e7          	jalr	-1012(ra) # 80004528 <log_write>
  brelse(bp);
    80003924:	854a                	mv	a0,s2
    80003926:	00000097          	auipc	ra,0x0
    8000392a:	980080e7          	jalr	-1664(ra) # 800032a6 <brelse>
}
    8000392e:	60e2                	ld	ra,24(sp)
    80003930:	6442                	ld	s0,16(sp)
    80003932:	64a2                	ld	s1,8(sp)
    80003934:	6902                	ld	s2,0(sp)
    80003936:	6105                	addi	sp,sp,32
    80003938:	8082                	ret

000000008000393a <idup>:
{
    8000393a:	1101                	addi	sp,sp,-32
    8000393c:	ec06                	sd	ra,24(sp)
    8000393e:	e822                	sd	s0,16(sp)
    80003940:	e426                	sd	s1,8(sp)
    80003942:	1000                	addi	s0,sp,32
    80003944:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    80003946:	0001d517          	auipc	a0,0x1d
    8000394a:	26250513          	addi	a0,a0,610 # 80020ba8 <icache>
    8000394e:	ffffd097          	auipc	ra,0xffffd
    80003952:	3b2080e7          	jalr	946(ra) # 80000d00 <acquire>
  ip->ref++;
    80003956:	449c                	lw	a5,8(s1)
    80003958:	2785                	addiw	a5,a5,1
    8000395a:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    8000395c:	0001d517          	auipc	a0,0x1d
    80003960:	24c50513          	addi	a0,a0,588 # 80020ba8 <icache>
    80003964:	ffffd097          	auipc	ra,0xffffd
    80003968:	46c080e7          	jalr	1132(ra) # 80000dd0 <release>
}
    8000396c:	8526                	mv	a0,s1
    8000396e:	60e2                	ld	ra,24(sp)
    80003970:	6442                	ld	s0,16(sp)
    80003972:	64a2                	ld	s1,8(sp)
    80003974:	6105                	addi	sp,sp,32
    80003976:	8082                	ret

0000000080003978 <ilock>:
{
    80003978:	1101                	addi	sp,sp,-32
    8000397a:	ec06                	sd	ra,24(sp)
    8000397c:	e822                	sd	s0,16(sp)
    8000397e:	e426                	sd	s1,8(sp)
    80003980:	e04a                	sd	s2,0(sp)
    80003982:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003984:	c115                	beqz	a0,800039a8 <ilock+0x30>
    80003986:	84aa                	mv	s1,a0
    80003988:	451c                	lw	a5,8(a0)
    8000398a:	00f05f63          	blez	a5,800039a8 <ilock+0x30>
  acquiresleep(&ip->lock);
    8000398e:	0541                	addi	a0,a0,16
    80003990:	00001097          	auipc	ra,0x1
    80003994:	cbe080e7          	jalr	-834(ra) # 8000464e <acquiresleep>
  if(ip->valid == 0){
    80003998:	44bc                	lw	a5,72(s1)
    8000399a:	cf99                	beqz	a5,800039b8 <ilock+0x40>
}
    8000399c:	60e2                	ld	ra,24(sp)
    8000399e:	6442                	ld	s0,16(sp)
    800039a0:	64a2                	ld	s1,8(sp)
    800039a2:	6902                	ld	s2,0(sp)
    800039a4:	6105                	addi	sp,sp,32
    800039a6:	8082                	ret
    panic("ilock");
    800039a8:	00005517          	auipc	a0,0x5
    800039ac:	c8850513          	addi	a0,a0,-888 # 80008630 <syscalls+0x178>
    800039b0:	ffffd097          	auipc	ra,0xffffd
    800039b4:	b9c080e7          	jalr	-1124(ra) # 8000054c <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800039b8:	40dc                	lw	a5,4(s1)
    800039ba:	0047d79b          	srliw	a5,a5,0x4
    800039be:	0001d597          	auipc	a1,0x1d
    800039c2:	1e25a583          	lw	a1,482(a1) # 80020ba0 <sb+0x18>
    800039c6:	9dbd                	addw	a1,a1,a5
    800039c8:	4088                	lw	a0,0(s1)
    800039ca:	fffff097          	auipc	ra,0xfffff
    800039ce:	7ac080e7          	jalr	1964(ra) # 80003176 <bread>
    800039d2:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    800039d4:	06050593          	addi	a1,a0,96
    800039d8:	40dc                	lw	a5,4(s1)
    800039da:	8bbd                	andi	a5,a5,15
    800039dc:	079a                	slli	a5,a5,0x6
    800039de:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    800039e0:	00059783          	lh	a5,0(a1)
    800039e4:	04f49623          	sh	a5,76(s1)
    ip->major = dip->major;
    800039e8:	00259783          	lh	a5,2(a1)
    800039ec:	04f49723          	sh	a5,78(s1)
    ip->minor = dip->minor;
    800039f0:	00459783          	lh	a5,4(a1)
    800039f4:	04f49823          	sh	a5,80(s1)
    ip->nlink = dip->nlink;
    800039f8:	00659783          	lh	a5,6(a1)
    800039fc:	04f49923          	sh	a5,82(s1)
    ip->size = dip->size;
    80003a00:	459c                	lw	a5,8(a1)
    80003a02:	c8fc                	sw	a5,84(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003a04:	03400613          	li	a2,52
    80003a08:	05b1                	addi	a1,a1,12
    80003a0a:	05848513          	addi	a0,s1,88
    80003a0e:	ffffd097          	auipc	ra,0xffffd
    80003a12:	72e080e7          	jalr	1838(ra) # 8000113c <memmove>
    brelse(bp);
    80003a16:	854a                	mv	a0,s2
    80003a18:	00000097          	auipc	ra,0x0
    80003a1c:	88e080e7          	jalr	-1906(ra) # 800032a6 <brelse>
    ip->valid = 1;
    80003a20:	4785                	li	a5,1
    80003a22:	c4bc                	sw	a5,72(s1)
    if(ip->type == 0)
    80003a24:	04c49783          	lh	a5,76(s1)
    80003a28:	fbb5                	bnez	a5,8000399c <ilock+0x24>
      panic("ilock: no type");
    80003a2a:	00005517          	auipc	a0,0x5
    80003a2e:	c0e50513          	addi	a0,a0,-1010 # 80008638 <syscalls+0x180>
    80003a32:	ffffd097          	auipc	ra,0xffffd
    80003a36:	b1a080e7          	jalr	-1254(ra) # 8000054c <panic>

0000000080003a3a <iunlock>:
{
    80003a3a:	1101                	addi	sp,sp,-32
    80003a3c:	ec06                	sd	ra,24(sp)
    80003a3e:	e822                	sd	s0,16(sp)
    80003a40:	e426                	sd	s1,8(sp)
    80003a42:	e04a                	sd	s2,0(sp)
    80003a44:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003a46:	c905                	beqz	a0,80003a76 <iunlock+0x3c>
    80003a48:	84aa                	mv	s1,a0
    80003a4a:	01050913          	addi	s2,a0,16
    80003a4e:	854a                	mv	a0,s2
    80003a50:	00001097          	auipc	ra,0x1
    80003a54:	c98080e7          	jalr	-872(ra) # 800046e8 <holdingsleep>
    80003a58:	cd19                	beqz	a0,80003a76 <iunlock+0x3c>
    80003a5a:	449c                	lw	a5,8(s1)
    80003a5c:	00f05d63          	blez	a5,80003a76 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003a60:	854a                	mv	a0,s2
    80003a62:	00001097          	auipc	ra,0x1
    80003a66:	c42080e7          	jalr	-958(ra) # 800046a4 <releasesleep>
}
    80003a6a:	60e2                	ld	ra,24(sp)
    80003a6c:	6442                	ld	s0,16(sp)
    80003a6e:	64a2                	ld	s1,8(sp)
    80003a70:	6902                	ld	s2,0(sp)
    80003a72:	6105                	addi	sp,sp,32
    80003a74:	8082                	ret
    panic("iunlock");
    80003a76:	00005517          	auipc	a0,0x5
    80003a7a:	bd250513          	addi	a0,a0,-1070 # 80008648 <syscalls+0x190>
    80003a7e:	ffffd097          	auipc	ra,0xffffd
    80003a82:	ace080e7          	jalr	-1330(ra) # 8000054c <panic>

0000000080003a86 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003a86:	7179                	addi	sp,sp,-48
    80003a88:	f406                	sd	ra,40(sp)
    80003a8a:	f022                	sd	s0,32(sp)
    80003a8c:	ec26                	sd	s1,24(sp)
    80003a8e:	e84a                	sd	s2,16(sp)
    80003a90:	e44e                	sd	s3,8(sp)
    80003a92:	e052                	sd	s4,0(sp)
    80003a94:	1800                	addi	s0,sp,48
    80003a96:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003a98:	05850493          	addi	s1,a0,88
    80003a9c:	08850913          	addi	s2,a0,136
    80003aa0:	a021                	j	80003aa8 <itrunc+0x22>
    80003aa2:	0491                	addi	s1,s1,4
    80003aa4:	01248d63          	beq	s1,s2,80003abe <itrunc+0x38>
    if(ip->addrs[i]){
    80003aa8:	408c                	lw	a1,0(s1)
    80003aaa:	dde5                	beqz	a1,80003aa2 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003aac:	0009a503          	lw	a0,0(s3)
    80003ab0:	00000097          	auipc	ra,0x0
    80003ab4:	90c080e7          	jalr	-1780(ra) # 800033bc <bfree>
      ip->addrs[i] = 0;
    80003ab8:	0004a023          	sw	zero,0(s1)
    80003abc:	b7dd                	j	80003aa2 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003abe:	0889a583          	lw	a1,136(s3)
    80003ac2:	e185                	bnez	a1,80003ae2 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003ac4:	0409aa23          	sw	zero,84(s3)
  iupdate(ip);
    80003ac8:	854e                	mv	a0,s3
    80003aca:	00000097          	auipc	ra,0x0
    80003ace:	de2080e7          	jalr	-542(ra) # 800038ac <iupdate>
}
    80003ad2:	70a2                	ld	ra,40(sp)
    80003ad4:	7402                	ld	s0,32(sp)
    80003ad6:	64e2                	ld	s1,24(sp)
    80003ad8:	6942                	ld	s2,16(sp)
    80003ada:	69a2                	ld	s3,8(sp)
    80003adc:	6a02                	ld	s4,0(sp)
    80003ade:	6145                	addi	sp,sp,48
    80003ae0:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003ae2:	0009a503          	lw	a0,0(s3)
    80003ae6:	fffff097          	auipc	ra,0xfffff
    80003aea:	690080e7          	jalr	1680(ra) # 80003176 <bread>
    80003aee:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003af0:	06050493          	addi	s1,a0,96
    80003af4:	46050913          	addi	s2,a0,1120
    80003af8:	a021                	j	80003b00 <itrunc+0x7a>
    80003afa:	0491                	addi	s1,s1,4
    80003afc:	01248b63          	beq	s1,s2,80003b12 <itrunc+0x8c>
      if(a[j])
    80003b00:	408c                	lw	a1,0(s1)
    80003b02:	dde5                	beqz	a1,80003afa <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003b04:	0009a503          	lw	a0,0(s3)
    80003b08:	00000097          	auipc	ra,0x0
    80003b0c:	8b4080e7          	jalr	-1868(ra) # 800033bc <bfree>
    80003b10:	b7ed                	j	80003afa <itrunc+0x74>
    brelse(bp);
    80003b12:	8552                	mv	a0,s4
    80003b14:	fffff097          	auipc	ra,0xfffff
    80003b18:	792080e7          	jalr	1938(ra) # 800032a6 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003b1c:	0889a583          	lw	a1,136(s3)
    80003b20:	0009a503          	lw	a0,0(s3)
    80003b24:	00000097          	auipc	ra,0x0
    80003b28:	898080e7          	jalr	-1896(ra) # 800033bc <bfree>
    ip->addrs[NDIRECT] = 0;
    80003b2c:	0809a423          	sw	zero,136(s3)
    80003b30:	bf51                	j	80003ac4 <itrunc+0x3e>

0000000080003b32 <iput>:
{
    80003b32:	1101                	addi	sp,sp,-32
    80003b34:	ec06                	sd	ra,24(sp)
    80003b36:	e822                	sd	s0,16(sp)
    80003b38:	e426                	sd	s1,8(sp)
    80003b3a:	e04a                	sd	s2,0(sp)
    80003b3c:	1000                	addi	s0,sp,32
    80003b3e:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    80003b40:	0001d517          	auipc	a0,0x1d
    80003b44:	06850513          	addi	a0,a0,104 # 80020ba8 <icache>
    80003b48:	ffffd097          	auipc	ra,0xffffd
    80003b4c:	1b8080e7          	jalr	440(ra) # 80000d00 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003b50:	4498                	lw	a4,8(s1)
    80003b52:	4785                	li	a5,1
    80003b54:	02f70363          	beq	a4,a5,80003b7a <iput+0x48>
  ip->ref--;
    80003b58:	449c                	lw	a5,8(s1)
    80003b5a:	37fd                	addiw	a5,a5,-1
    80003b5c:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    80003b5e:	0001d517          	auipc	a0,0x1d
    80003b62:	04a50513          	addi	a0,a0,74 # 80020ba8 <icache>
    80003b66:	ffffd097          	auipc	ra,0xffffd
    80003b6a:	26a080e7          	jalr	618(ra) # 80000dd0 <release>
}
    80003b6e:	60e2                	ld	ra,24(sp)
    80003b70:	6442                	ld	s0,16(sp)
    80003b72:	64a2                	ld	s1,8(sp)
    80003b74:	6902                	ld	s2,0(sp)
    80003b76:	6105                	addi	sp,sp,32
    80003b78:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003b7a:	44bc                	lw	a5,72(s1)
    80003b7c:	dff1                	beqz	a5,80003b58 <iput+0x26>
    80003b7e:	05249783          	lh	a5,82(s1)
    80003b82:	fbf9                	bnez	a5,80003b58 <iput+0x26>
    acquiresleep(&ip->lock);
    80003b84:	01048913          	addi	s2,s1,16
    80003b88:	854a                	mv	a0,s2
    80003b8a:	00001097          	auipc	ra,0x1
    80003b8e:	ac4080e7          	jalr	-1340(ra) # 8000464e <acquiresleep>
    release(&icache.lock);
    80003b92:	0001d517          	auipc	a0,0x1d
    80003b96:	01650513          	addi	a0,a0,22 # 80020ba8 <icache>
    80003b9a:	ffffd097          	auipc	ra,0xffffd
    80003b9e:	236080e7          	jalr	566(ra) # 80000dd0 <release>
    itrunc(ip);
    80003ba2:	8526                	mv	a0,s1
    80003ba4:	00000097          	auipc	ra,0x0
    80003ba8:	ee2080e7          	jalr	-286(ra) # 80003a86 <itrunc>
    ip->type = 0;
    80003bac:	04049623          	sh	zero,76(s1)
    iupdate(ip);
    80003bb0:	8526                	mv	a0,s1
    80003bb2:	00000097          	auipc	ra,0x0
    80003bb6:	cfa080e7          	jalr	-774(ra) # 800038ac <iupdate>
    ip->valid = 0;
    80003bba:	0404a423          	sw	zero,72(s1)
    releasesleep(&ip->lock);
    80003bbe:	854a                	mv	a0,s2
    80003bc0:	00001097          	auipc	ra,0x1
    80003bc4:	ae4080e7          	jalr	-1308(ra) # 800046a4 <releasesleep>
    acquire(&icache.lock);
    80003bc8:	0001d517          	auipc	a0,0x1d
    80003bcc:	fe050513          	addi	a0,a0,-32 # 80020ba8 <icache>
    80003bd0:	ffffd097          	auipc	ra,0xffffd
    80003bd4:	130080e7          	jalr	304(ra) # 80000d00 <acquire>
    80003bd8:	b741                	j	80003b58 <iput+0x26>

0000000080003bda <iunlockput>:
{
    80003bda:	1101                	addi	sp,sp,-32
    80003bdc:	ec06                	sd	ra,24(sp)
    80003bde:	e822                	sd	s0,16(sp)
    80003be0:	e426                	sd	s1,8(sp)
    80003be2:	1000                	addi	s0,sp,32
    80003be4:	84aa                	mv	s1,a0
  iunlock(ip);
    80003be6:	00000097          	auipc	ra,0x0
    80003bea:	e54080e7          	jalr	-428(ra) # 80003a3a <iunlock>
  iput(ip);
    80003bee:	8526                	mv	a0,s1
    80003bf0:	00000097          	auipc	ra,0x0
    80003bf4:	f42080e7          	jalr	-190(ra) # 80003b32 <iput>
}
    80003bf8:	60e2                	ld	ra,24(sp)
    80003bfa:	6442                	ld	s0,16(sp)
    80003bfc:	64a2                	ld	s1,8(sp)
    80003bfe:	6105                	addi	sp,sp,32
    80003c00:	8082                	ret

0000000080003c02 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003c02:	1141                	addi	sp,sp,-16
    80003c04:	e422                	sd	s0,8(sp)
    80003c06:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003c08:	411c                	lw	a5,0(a0)
    80003c0a:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003c0c:	415c                	lw	a5,4(a0)
    80003c0e:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003c10:	04c51783          	lh	a5,76(a0)
    80003c14:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003c18:	05251783          	lh	a5,82(a0)
    80003c1c:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003c20:	05456783          	lwu	a5,84(a0)
    80003c24:	e99c                	sd	a5,16(a1)
}
    80003c26:	6422                	ld	s0,8(sp)
    80003c28:	0141                	addi	sp,sp,16
    80003c2a:	8082                	ret

0000000080003c2c <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003c2c:	497c                	lw	a5,84(a0)
    80003c2e:	0ed7e963          	bltu	a5,a3,80003d20 <readi+0xf4>
{
    80003c32:	7159                	addi	sp,sp,-112
    80003c34:	f486                	sd	ra,104(sp)
    80003c36:	f0a2                	sd	s0,96(sp)
    80003c38:	eca6                	sd	s1,88(sp)
    80003c3a:	e8ca                	sd	s2,80(sp)
    80003c3c:	e4ce                	sd	s3,72(sp)
    80003c3e:	e0d2                	sd	s4,64(sp)
    80003c40:	fc56                	sd	s5,56(sp)
    80003c42:	f85a                	sd	s6,48(sp)
    80003c44:	f45e                	sd	s7,40(sp)
    80003c46:	f062                	sd	s8,32(sp)
    80003c48:	ec66                	sd	s9,24(sp)
    80003c4a:	e86a                	sd	s10,16(sp)
    80003c4c:	e46e                	sd	s11,8(sp)
    80003c4e:	1880                	addi	s0,sp,112
    80003c50:	8baa                	mv	s7,a0
    80003c52:	8c2e                	mv	s8,a1
    80003c54:	8ab2                	mv	s5,a2
    80003c56:	84b6                	mv	s1,a3
    80003c58:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003c5a:	9f35                	addw	a4,a4,a3
    return 0;
    80003c5c:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003c5e:	0ad76063          	bltu	a4,a3,80003cfe <readi+0xd2>
  if(off + n > ip->size)
    80003c62:	00e7f463          	bgeu	a5,a4,80003c6a <readi+0x3e>
    n = ip->size - off;
    80003c66:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003c6a:	0a0b0963          	beqz	s6,80003d1c <readi+0xf0>
    80003c6e:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c70:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003c74:	5cfd                	li	s9,-1
    80003c76:	a82d                	j	80003cb0 <readi+0x84>
    80003c78:	020a1d93          	slli	s11,s4,0x20
    80003c7c:	020ddd93          	srli	s11,s11,0x20
    80003c80:	06090613          	addi	a2,s2,96
    80003c84:	86ee                	mv	a3,s11
    80003c86:	963a                	add	a2,a2,a4
    80003c88:	85d6                	mv	a1,s5
    80003c8a:	8562                	mv	a0,s8
    80003c8c:	fffff097          	auipc	ra,0xfffff
    80003c90:	b2c080e7          	jalr	-1236(ra) # 800027b8 <either_copyout>
    80003c94:	05950d63          	beq	a0,s9,80003cee <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003c98:	854a                	mv	a0,s2
    80003c9a:	fffff097          	auipc	ra,0xfffff
    80003c9e:	60c080e7          	jalr	1548(ra) # 800032a6 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003ca2:	013a09bb          	addw	s3,s4,s3
    80003ca6:	009a04bb          	addw	s1,s4,s1
    80003caa:	9aee                	add	s5,s5,s11
    80003cac:	0569f763          	bgeu	s3,s6,80003cfa <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003cb0:	000ba903          	lw	s2,0(s7)
    80003cb4:	00a4d59b          	srliw	a1,s1,0xa
    80003cb8:	855e                	mv	a0,s7
    80003cba:	00000097          	auipc	ra,0x0
    80003cbe:	8ac080e7          	jalr	-1876(ra) # 80003566 <bmap>
    80003cc2:	0005059b          	sext.w	a1,a0
    80003cc6:	854a                	mv	a0,s2
    80003cc8:	fffff097          	auipc	ra,0xfffff
    80003ccc:	4ae080e7          	jalr	1198(ra) # 80003176 <bread>
    80003cd0:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003cd2:	3ff4f713          	andi	a4,s1,1023
    80003cd6:	40ed07bb          	subw	a5,s10,a4
    80003cda:	413b06bb          	subw	a3,s6,s3
    80003cde:	8a3e                	mv	s4,a5
    80003ce0:	2781                	sext.w	a5,a5
    80003ce2:	0006861b          	sext.w	a2,a3
    80003ce6:	f8f679e3          	bgeu	a2,a5,80003c78 <readi+0x4c>
    80003cea:	8a36                	mv	s4,a3
    80003cec:	b771                	j	80003c78 <readi+0x4c>
      brelse(bp);
    80003cee:	854a                	mv	a0,s2
    80003cf0:	fffff097          	auipc	ra,0xfffff
    80003cf4:	5b6080e7          	jalr	1462(ra) # 800032a6 <brelse>
      tot = -1;
    80003cf8:	59fd                	li	s3,-1
  }
  return tot;
    80003cfa:	0009851b          	sext.w	a0,s3
}
    80003cfe:	70a6                	ld	ra,104(sp)
    80003d00:	7406                	ld	s0,96(sp)
    80003d02:	64e6                	ld	s1,88(sp)
    80003d04:	6946                	ld	s2,80(sp)
    80003d06:	69a6                	ld	s3,72(sp)
    80003d08:	6a06                	ld	s4,64(sp)
    80003d0a:	7ae2                	ld	s5,56(sp)
    80003d0c:	7b42                	ld	s6,48(sp)
    80003d0e:	7ba2                	ld	s7,40(sp)
    80003d10:	7c02                	ld	s8,32(sp)
    80003d12:	6ce2                	ld	s9,24(sp)
    80003d14:	6d42                	ld	s10,16(sp)
    80003d16:	6da2                	ld	s11,8(sp)
    80003d18:	6165                	addi	sp,sp,112
    80003d1a:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003d1c:	89da                	mv	s3,s6
    80003d1e:	bff1                	j	80003cfa <readi+0xce>
    return 0;
    80003d20:	4501                	li	a0,0
}
    80003d22:	8082                	ret

0000000080003d24 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003d24:	497c                	lw	a5,84(a0)
    80003d26:	10d7e763          	bltu	a5,a3,80003e34 <writei+0x110>
{
    80003d2a:	7159                	addi	sp,sp,-112
    80003d2c:	f486                	sd	ra,104(sp)
    80003d2e:	f0a2                	sd	s0,96(sp)
    80003d30:	eca6                	sd	s1,88(sp)
    80003d32:	e8ca                	sd	s2,80(sp)
    80003d34:	e4ce                	sd	s3,72(sp)
    80003d36:	e0d2                	sd	s4,64(sp)
    80003d38:	fc56                	sd	s5,56(sp)
    80003d3a:	f85a                	sd	s6,48(sp)
    80003d3c:	f45e                	sd	s7,40(sp)
    80003d3e:	f062                	sd	s8,32(sp)
    80003d40:	ec66                	sd	s9,24(sp)
    80003d42:	e86a                	sd	s10,16(sp)
    80003d44:	e46e                	sd	s11,8(sp)
    80003d46:	1880                	addi	s0,sp,112
    80003d48:	8baa                	mv	s7,a0
    80003d4a:	8c2e                	mv	s8,a1
    80003d4c:	8ab2                	mv	s5,a2
    80003d4e:	8936                	mv	s2,a3
    80003d50:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003d52:	00e687bb          	addw	a5,a3,a4
    80003d56:	0ed7e163          	bltu	a5,a3,80003e38 <writei+0x114>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003d5a:	00043737          	lui	a4,0x43
    80003d5e:	0cf76f63          	bltu	a4,a5,80003e3c <writei+0x118>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003d62:	0a0b0863          	beqz	s6,80003e12 <writei+0xee>
    80003d66:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003d68:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003d6c:	5cfd                	li	s9,-1
    80003d6e:	a091                	j	80003db2 <writei+0x8e>
    80003d70:	02099d93          	slli	s11,s3,0x20
    80003d74:	020ddd93          	srli	s11,s11,0x20
    80003d78:	06048513          	addi	a0,s1,96
    80003d7c:	86ee                	mv	a3,s11
    80003d7e:	8656                	mv	a2,s5
    80003d80:	85e2                	mv	a1,s8
    80003d82:	953a                	add	a0,a0,a4
    80003d84:	fffff097          	auipc	ra,0xfffff
    80003d88:	a8a080e7          	jalr	-1398(ra) # 8000280e <either_copyin>
    80003d8c:	07950263          	beq	a0,s9,80003df0 <writei+0xcc>
      brelse(bp);
      n = -1;
      break;
    }
    log_write(bp);
    80003d90:	8526                	mv	a0,s1
    80003d92:	00000097          	auipc	ra,0x0
    80003d96:	796080e7          	jalr	1942(ra) # 80004528 <log_write>
    brelse(bp);
    80003d9a:	8526                	mv	a0,s1
    80003d9c:	fffff097          	auipc	ra,0xfffff
    80003da0:	50a080e7          	jalr	1290(ra) # 800032a6 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003da4:	01498a3b          	addw	s4,s3,s4
    80003da8:	0129893b          	addw	s2,s3,s2
    80003dac:	9aee                	add	s5,s5,s11
    80003dae:	056a7763          	bgeu	s4,s6,80003dfc <writei+0xd8>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003db2:	000ba483          	lw	s1,0(s7)
    80003db6:	00a9559b          	srliw	a1,s2,0xa
    80003dba:	855e                	mv	a0,s7
    80003dbc:	fffff097          	auipc	ra,0xfffff
    80003dc0:	7aa080e7          	jalr	1962(ra) # 80003566 <bmap>
    80003dc4:	0005059b          	sext.w	a1,a0
    80003dc8:	8526                	mv	a0,s1
    80003dca:	fffff097          	auipc	ra,0xfffff
    80003dce:	3ac080e7          	jalr	940(ra) # 80003176 <bread>
    80003dd2:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003dd4:	3ff97713          	andi	a4,s2,1023
    80003dd8:	40ed07bb          	subw	a5,s10,a4
    80003ddc:	414b06bb          	subw	a3,s6,s4
    80003de0:	89be                	mv	s3,a5
    80003de2:	2781                	sext.w	a5,a5
    80003de4:	0006861b          	sext.w	a2,a3
    80003de8:	f8f674e3          	bgeu	a2,a5,80003d70 <writei+0x4c>
    80003dec:	89b6                	mv	s3,a3
    80003dee:	b749                	j	80003d70 <writei+0x4c>
      brelse(bp);
    80003df0:	8526                	mv	a0,s1
    80003df2:	fffff097          	auipc	ra,0xfffff
    80003df6:	4b4080e7          	jalr	1204(ra) # 800032a6 <brelse>
      n = -1;
    80003dfa:	5b7d                	li	s6,-1
  }

  if(n > 0){
    if(off > ip->size)
    80003dfc:	054ba783          	lw	a5,84(s7)
    80003e00:	0127f463          	bgeu	a5,s2,80003e08 <writei+0xe4>
      ip->size = off;
    80003e04:	052baa23          	sw	s2,84(s7)
    // write the i-node back to disk even if the size didn't change
    // because the loop above might have called bmap() and added a new
    // block to ip->addrs[].
    iupdate(ip);
    80003e08:	855e                	mv	a0,s7
    80003e0a:	00000097          	auipc	ra,0x0
    80003e0e:	aa2080e7          	jalr	-1374(ra) # 800038ac <iupdate>
  }

  return n;
    80003e12:	000b051b          	sext.w	a0,s6
}
    80003e16:	70a6                	ld	ra,104(sp)
    80003e18:	7406                	ld	s0,96(sp)
    80003e1a:	64e6                	ld	s1,88(sp)
    80003e1c:	6946                	ld	s2,80(sp)
    80003e1e:	69a6                	ld	s3,72(sp)
    80003e20:	6a06                	ld	s4,64(sp)
    80003e22:	7ae2                	ld	s5,56(sp)
    80003e24:	7b42                	ld	s6,48(sp)
    80003e26:	7ba2                	ld	s7,40(sp)
    80003e28:	7c02                	ld	s8,32(sp)
    80003e2a:	6ce2                	ld	s9,24(sp)
    80003e2c:	6d42                	ld	s10,16(sp)
    80003e2e:	6da2                	ld	s11,8(sp)
    80003e30:	6165                	addi	sp,sp,112
    80003e32:	8082                	ret
    return -1;
    80003e34:	557d                	li	a0,-1
}
    80003e36:	8082                	ret
    return -1;
    80003e38:	557d                	li	a0,-1
    80003e3a:	bff1                	j	80003e16 <writei+0xf2>
    return -1;
    80003e3c:	557d                	li	a0,-1
    80003e3e:	bfe1                	j	80003e16 <writei+0xf2>

0000000080003e40 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003e40:	1141                	addi	sp,sp,-16
    80003e42:	e406                	sd	ra,8(sp)
    80003e44:	e022                	sd	s0,0(sp)
    80003e46:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003e48:	4639                	li	a2,14
    80003e4a:	ffffd097          	auipc	ra,0xffffd
    80003e4e:	36e080e7          	jalr	878(ra) # 800011b8 <strncmp>
}
    80003e52:	60a2                	ld	ra,8(sp)
    80003e54:	6402                	ld	s0,0(sp)
    80003e56:	0141                	addi	sp,sp,16
    80003e58:	8082                	ret

0000000080003e5a <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003e5a:	7139                	addi	sp,sp,-64
    80003e5c:	fc06                	sd	ra,56(sp)
    80003e5e:	f822                	sd	s0,48(sp)
    80003e60:	f426                	sd	s1,40(sp)
    80003e62:	f04a                	sd	s2,32(sp)
    80003e64:	ec4e                	sd	s3,24(sp)
    80003e66:	e852                	sd	s4,16(sp)
    80003e68:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003e6a:	04c51703          	lh	a4,76(a0)
    80003e6e:	4785                	li	a5,1
    80003e70:	00f71a63          	bne	a4,a5,80003e84 <dirlookup+0x2a>
    80003e74:	892a                	mv	s2,a0
    80003e76:	89ae                	mv	s3,a1
    80003e78:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e7a:	497c                	lw	a5,84(a0)
    80003e7c:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003e7e:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e80:	e79d                	bnez	a5,80003eae <dirlookup+0x54>
    80003e82:	a8a5                	j	80003efa <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003e84:	00004517          	auipc	a0,0x4
    80003e88:	7cc50513          	addi	a0,a0,1996 # 80008650 <syscalls+0x198>
    80003e8c:	ffffc097          	auipc	ra,0xffffc
    80003e90:	6c0080e7          	jalr	1728(ra) # 8000054c <panic>
      panic("dirlookup read");
    80003e94:	00004517          	auipc	a0,0x4
    80003e98:	7d450513          	addi	a0,a0,2004 # 80008668 <syscalls+0x1b0>
    80003e9c:	ffffc097          	auipc	ra,0xffffc
    80003ea0:	6b0080e7          	jalr	1712(ra) # 8000054c <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003ea4:	24c1                	addiw	s1,s1,16
    80003ea6:	05492783          	lw	a5,84(s2)
    80003eaa:	04f4f763          	bgeu	s1,a5,80003ef8 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003eae:	4741                	li	a4,16
    80003eb0:	86a6                	mv	a3,s1
    80003eb2:	fc040613          	addi	a2,s0,-64
    80003eb6:	4581                	li	a1,0
    80003eb8:	854a                	mv	a0,s2
    80003eba:	00000097          	auipc	ra,0x0
    80003ebe:	d72080e7          	jalr	-654(ra) # 80003c2c <readi>
    80003ec2:	47c1                	li	a5,16
    80003ec4:	fcf518e3          	bne	a0,a5,80003e94 <dirlookup+0x3a>
    if(de.inum == 0)
    80003ec8:	fc045783          	lhu	a5,-64(s0)
    80003ecc:	dfe1                	beqz	a5,80003ea4 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003ece:	fc240593          	addi	a1,s0,-62
    80003ed2:	854e                	mv	a0,s3
    80003ed4:	00000097          	auipc	ra,0x0
    80003ed8:	f6c080e7          	jalr	-148(ra) # 80003e40 <namecmp>
    80003edc:	f561                	bnez	a0,80003ea4 <dirlookup+0x4a>
      if(poff)
    80003ede:	000a0463          	beqz	s4,80003ee6 <dirlookup+0x8c>
        *poff = off;
    80003ee2:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003ee6:	fc045583          	lhu	a1,-64(s0)
    80003eea:	00092503          	lw	a0,0(s2)
    80003eee:	fffff097          	auipc	ra,0xfffff
    80003ef2:	754080e7          	jalr	1876(ra) # 80003642 <iget>
    80003ef6:	a011                	j	80003efa <dirlookup+0xa0>
  return 0;
    80003ef8:	4501                	li	a0,0
}
    80003efa:	70e2                	ld	ra,56(sp)
    80003efc:	7442                	ld	s0,48(sp)
    80003efe:	74a2                	ld	s1,40(sp)
    80003f00:	7902                	ld	s2,32(sp)
    80003f02:	69e2                	ld	s3,24(sp)
    80003f04:	6a42                	ld	s4,16(sp)
    80003f06:	6121                	addi	sp,sp,64
    80003f08:	8082                	ret

0000000080003f0a <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003f0a:	711d                	addi	sp,sp,-96
    80003f0c:	ec86                	sd	ra,88(sp)
    80003f0e:	e8a2                	sd	s0,80(sp)
    80003f10:	e4a6                	sd	s1,72(sp)
    80003f12:	e0ca                	sd	s2,64(sp)
    80003f14:	fc4e                	sd	s3,56(sp)
    80003f16:	f852                	sd	s4,48(sp)
    80003f18:	f456                	sd	s5,40(sp)
    80003f1a:	f05a                	sd	s6,32(sp)
    80003f1c:	ec5e                	sd	s7,24(sp)
    80003f1e:	e862                	sd	s8,16(sp)
    80003f20:	e466                	sd	s9,8(sp)
    80003f22:	e06a                	sd	s10,0(sp)
    80003f24:	1080                	addi	s0,sp,96
    80003f26:	84aa                	mv	s1,a0
    80003f28:	8b2e                	mv	s6,a1
    80003f2a:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003f2c:	00054703          	lbu	a4,0(a0)
    80003f30:	02f00793          	li	a5,47
    80003f34:	02f70363          	beq	a4,a5,80003f5a <namex+0x50>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003f38:	ffffe097          	auipc	ra,0xffffe
    80003f3c:	e0e080e7          	jalr	-498(ra) # 80001d46 <myproc>
    80003f40:	15853503          	ld	a0,344(a0)
    80003f44:	00000097          	auipc	ra,0x0
    80003f48:	9f6080e7          	jalr	-1546(ra) # 8000393a <idup>
    80003f4c:	8a2a                	mv	s4,a0
  while(*path == '/')
    80003f4e:	02f00913          	li	s2,47
  if(len >= DIRSIZ)
    80003f52:	4cb5                	li	s9,13
  len = path - s;
    80003f54:	4b81                	li	s7,0

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003f56:	4c05                	li	s8,1
    80003f58:	a87d                	j	80004016 <namex+0x10c>
    ip = iget(ROOTDEV, ROOTINO);
    80003f5a:	4585                	li	a1,1
    80003f5c:	4505                	li	a0,1
    80003f5e:	fffff097          	auipc	ra,0xfffff
    80003f62:	6e4080e7          	jalr	1764(ra) # 80003642 <iget>
    80003f66:	8a2a                	mv	s4,a0
    80003f68:	b7dd                	j	80003f4e <namex+0x44>
      iunlockput(ip);
    80003f6a:	8552                	mv	a0,s4
    80003f6c:	00000097          	auipc	ra,0x0
    80003f70:	c6e080e7          	jalr	-914(ra) # 80003bda <iunlockput>
      return 0;
    80003f74:	4a01                	li	s4,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003f76:	8552                	mv	a0,s4
    80003f78:	60e6                	ld	ra,88(sp)
    80003f7a:	6446                	ld	s0,80(sp)
    80003f7c:	64a6                	ld	s1,72(sp)
    80003f7e:	6906                	ld	s2,64(sp)
    80003f80:	79e2                	ld	s3,56(sp)
    80003f82:	7a42                	ld	s4,48(sp)
    80003f84:	7aa2                	ld	s5,40(sp)
    80003f86:	7b02                	ld	s6,32(sp)
    80003f88:	6be2                	ld	s7,24(sp)
    80003f8a:	6c42                	ld	s8,16(sp)
    80003f8c:	6ca2                	ld	s9,8(sp)
    80003f8e:	6d02                	ld	s10,0(sp)
    80003f90:	6125                	addi	sp,sp,96
    80003f92:	8082                	ret
      iunlock(ip);
    80003f94:	8552                	mv	a0,s4
    80003f96:	00000097          	auipc	ra,0x0
    80003f9a:	aa4080e7          	jalr	-1372(ra) # 80003a3a <iunlock>
      return ip;
    80003f9e:	bfe1                	j	80003f76 <namex+0x6c>
      iunlockput(ip);
    80003fa0:	8552                	mv	a0,s4
    80003fa2:	00000097          	auipc	ra,0x0
    80003fa6:	c38080e7          	jalr	-968(ra) # 80003bda <iunlockput>
      return 0;
    80003faa:	8a4e                	mv	s4,s3
    80003fac:	b7e9                	j	80003f76 <namex+0x6c>
  len = path - s;
    80003fae:	40998633          	sub	a2,s3,s1
    80003fb2:	00060d1b          	sext.w	s10,a2
  if(len >= DIRSIZ)
    80003fb6:	09acd863          	bge	s9,s10,80004046 <namex+0x13c>
    memmove(name, s, DIRSIZ);
    80003fba:	4639                	li	a2,14
    80003fbc:	85a6                	mv	a1,s1
    80003fbe:	8556                	mv	a0,s5
    80003fc0:	ffffd097          	auipc	ra,0xffffd
    80003fc4:	17c080e7          	jalr	380(ra) # 8000113c <memmove>
    80003fc8:	84ce                	mv	s1,s3
  while(*path == '/')
    80003fca:	0004c783          	lbu	a5,0(s1)
    80003fce:	01279763          	bne	a5,s2,80003fdc <namex+0xd2>
    path++;
    80003fd2:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003fd4:	0004c783          	lbu	a5,0(s1)
    80003fd8:	ff278de3          	beq	a5,s2,80003fd2 <namex+0xc8>
    ilock(ip);
    80003fdc:	8552                	mv	a0,s4
    80003fde:	00000097          	auipc	ra,0x0
    80003fe2:	99a080e7          	jalr	-1638(ra) # 80003978 <ilock>
    if(ip->type != T_DIR){
    80003fe6:	04ca1783          	lh	a5,76(s4)
    80003fea:	f98790e3          	bne	a5,s8,80003f6a <namex+0x60>
    if(nameiparent && *path == '\0'){
    80003fee:	000b0563          	beqz	s6,80003ff8 <namex+0xee>
    80003ff2:	0004c783          	lbu	a5,0(s1)
    80003ff6:	dfd9                	beqz	a5,80003f94 <namex+0x8a>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003ff8:	865e                	mv	a2,s7
    80003ffa:	85d6                	mv	a1,s5
    80003ffc:	8552                	mv	a0,s4
    80003ffe:	00000097          	auipc	ra,0x0
    80004002:	e5c080e7          	jalr	-420(ra) # 80003e5a <dirlookup>
    80004006:	89aa                	mv	s3,a0
    80004008:	dd41                	beqz	a0,80003fa0 <namex+0x96>
    iunlockput(ip);
    8000400a:	8552                	mv	a0,s4
    8000400c:	00000097          	auipc	ra,0x0
    80004010:	bce080e7          	jalr	-1074(ra) # 80003bda <iunlockput>
    ip = next;
    80004014:	8a4e                	mv	s4,s3
  while(*path == '/')
    80004016:	0004c783          	lbu	a5,0(s1)
    8000401a:	01279763          	bne	a5,s2,80004028 <namex+0x11e>
    path++;
    8000401e:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004020:	0004c783          	lbu	a5,0(s1)
    80004024:	ff278de3          	beq	a5,s2,8000401e <namex+0x114>
  if(*path == 0)
    80004028:	cb9d                	beqz	a5,8000405e <namex+0x154>
  while(*path != '/' && *path != 0)
    8000402a:	0004c783          	lbu	a5,0(s1)
    8000402e:	89a6                	mv	s3,s1
  len = path - s;
    80004030:	8d5e                	mv	s10,s7
    80004032:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80004034:	01278963          	beq	a5,s2,80004046 <namex+0x13c>
    80004038:	dbbd                	beqz	a5,80003fae <namex+0xa4>
    path++;
    8000403a:	0985                	addi	s3,s3,1
  while(*path != '/' && *path != 0)
    8000403c:	0009c783          	lbu	a5,0(s3)
    80004040:	ff279ce3          	bne	a5,s2,80004038 <namex+0x12e>
    80004044:	b7ad                	j	80003fae <namex+0xa4>
    memmove(name, s, len);
    80004046:	2601                	sext.w	a2,a2
    80004048:	85a6                	mv	a1,s1
    8000404a:	8556                	mv	a0,s5
    8000404c:	ffffd097          	auipc	ra,0xffffd
    80004050:	0f0080e7          	jalr	240(ra) # 8000113c <memmove>
    name[len] = 0;
    80004054:	9d56                	add	s10,s10,s5
    80004056:	000d0023          	sb	zero,0(s10)
    8000405a:	84ce                	mv	s1,s3
    8000405c:	b7bd                	j	80003fca <namex+0xc0>
  if(nameiparent){
    8000405e:	f00b0ce3          	beqz	s6,80003f76 <namex+0x6c>
    iput(ip);
    80004062:	8552                	mv	a0,s4
    80004064:	00000097          	auipc	ra,0x0
    80004068:	ace080e7          	jalr	-1330(ra) # 80003b32 <iput>
    return 0;
    8000406c:	4a01                	li	s4,0
    8000406e:	b721                	j	80003f76 <namex+0x6c>

0000000080004070 <dirlink>:
{
    80004070:	7139                	addi	sp,sp,-64
    80004072:	fc06                	sd	ra,56(sp)
    80004074:	f822                	sd	s0,48(sp)
    80004076:	f426                	sd	s1,40(sp)
    80004078:	f04a                	sd	s2,32(sp)
    8000407a:	ec4e                	sd	s3,24(sp)
    8000407c:	e852                	sd	s4,16(sp)
    8000407e:	0080                	addi	s0,sp,64
    80004080:	892a                	mv	s2,a0
    80004082:	8a2e                	mv	s4,a1
    80004084:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80004086:	4601                	li	a2,0
    80004088:	00000097          	auipc	ra,0x0
    8000408c:	dd2080e7          	jalr	-558(ra) # 80003e5a <dirlookup>
    80004090:	e93d                	bnez	a0,80004106 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004092:	05492483          	lw	s1,84(s2)
    80004096:	c49d                	beqz	s1,800040c4 <dirlink+0x54>
    80004098:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000409a:	4741                	li	a4,16
    8000409c:	86a6                	mv	a3,s1
    8000409e:	fc040613          	addi	a2,s0,-64
    800040a2:	4581                	li	a1,0
    800040a4:	854a                	mv	a0,s2
    800040a6:	00000097          	auipc	ra,0x0
    800040aa:	b86080e7          	jalr	-1146(ra) # 80003c2c <readi>
    800040ae:	47c1                	li	a5,16
    800040b0:	06f51163          	bne	a0,a5,80004112 <dirlink+0xa2>
    if(de.inum == 0)
    800040b4:	fc045783          	lhu	a5,-64(s0)
    800040b8:	c791                	beqz	a5,800040c4 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800040ba:	24c1                	addiw	s1,s1,16
    800040bc:	05492783          	lw	a5,84(s2)
    800040c0:	fcf4ede3          	bltu	s1,a5,8000409a <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    800040c4:	4639                	li	a2,14
    800040c6:	85d2                	mv	a1,s4
    800040c8:	fc240513          	addi	a0,s0,-62
    800040cc:	ffffd097          	auipc	ra,0xffffd
    800040d0:	128080e7          	jalr	296(ra) # 800011f4 <strncpy>
  de.inum = inum;
    800040d4:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800040d8:	4741                	li	a4,16
    800040da:	86a6                	mv	a3,s1
    800040dc:	fc040613          	addi	a2,s0,-64
    800040e0:	4581                	li	a1,0
    800040e2:	854a                	mv	a0,s2
    800040e4:	00000097          	auipc	ra,0x0
    800040e8:	c40080e7          	jalr	-960(ra) # 80003d24 <writei>
    800040ec:	872a                	mv	a4,a0
    800040ee:	47c1                	li	a5,16
  return 0;
    800040f0:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800040f2:	02f71863          	bne	a4,a5,80004122 <dirlink+0xb2>
}
    800040f6:	70e2                	ld	ra,56(sp)
    800040f8:	7442                	ld	s0,48(sp)
    800040fa:	74a2                	ld	s1,40(sp)
    800040fc:	7902                	ld	s2,32(sp)
    800040fe:	69e2                	ld	s3,24(sp)
    80004100:	6a42                	ld	s4,16(sp)
    80004102:	6121                	addi	sp,sp,64
    80004104:	8082                	ret
    iput(ip);
    80004106:	00000097          	auipc	ra,0x0
    8000410a:	a2c080e7          	jalr	-1492(ra) # 80003b32 <iput>
    return -1;
    8000410e:	557d                	li	a0,-1
    80004110:	b7dd                	j	800040f6 <dirlink+0x86>
      panic("dirlink read");
    80004112:	00004517          	auipc	a0,0x4
    80004116:	56650513          	addi	a0,a0,1382 # 80008678 <syscalls+0x1c0>
    8000411a:	ffffc097          	auipc	ra,0xffffc
    8000411e:	432080e7          	jalr	1074(ra) # 8000054c <panic>
    panic("dirlink");
    80004122:	00004517          	auipc	a0,0x4
    80004126:	67650513          	addi	a0,a0,1654 # 80008798 <syscalls+0x2e0>
    8000412a:	ffffc097          	auipc	ra,0xffffc
    8000412e:	422080e7          	jalr	1058(ra) # 8000054c <panic>

0000000080004132 <namei>:

struct inode*
namei(char *path)
{
    80004132:	1101                	addi	sp,sp,-32
    80004134:	ec06                	sd	ra,24(sp)
    80004136:	e822                	sd	s0,16(sp)
    80004138:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    8000413a:	fe040613          	addi	a2,s0,-32
    8000413e:	4581                	li	a1,0
    80004140:	00000097          	auipc	ra,0x0
    80004144:	dca080e7          	jalr	-566(ra) # 80003f0a <namex>
}
    80004148:	60e2                	ld	ra,24(sp)
    8000414a:	6442                	ld	s0,16(sp)
    8000414c:	6105                	addi	sp,sp,32
    8000414e:	8082                	ret

0000000080004150 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80004150:	1141                	addi	sp,sp,-16
    80004152:	e406                	sd	ra,8(sp)
    80004154:	e022                	sd	s0,0(sp)
    80004156:	0800                	addi	s0,sp,16
    80004158:	862e                	mv	a2,a1
  return namex(path, 1, name);
    8000415a:	4585                	li	a1,1
    8000415c:	00000097          	auipc	ra,0x0
    80004160:	dae080e7          	jalr	-594(ra) # 80003f0a <namex>
}
    80004164:	60a2                	ld	ra,8(sp)
    80004166:	6402                	ld	s0,0(sp)
    80004168:	0141                	addi	sp,sp,16
    8000416a:	8082                	ret

000000008000416c <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    8000416c:	1101                	addi	sp,sp,-32
    8000416e:	ec06                	sd	ra,24(sp)
    80004170:	e822                	sd	s0,16(sp)
    80004172:	e426                	sd	s1,8(sp)
    80004174:	e04a                	sd	s2,0(sp)
    80004176:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80004178:	0001e917          	auipc	s2,0x1e
    8000417c:	67090913          	addi	s2,s2,1648 # 800227e8 <log>
    80004180:	02092583          	lw	a1,32(s2)
    80004184:	03092503          	lw	a0,48(s2)
    80004188:	fffff097          	auipc	ra,0xfffff
    8000418c:	fee080e7          	jalr	-18(ra) # 80003176 <bread>
    80004190:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004192:	03492683          	lw	a3,52(s2)
    80004196:	d134                	sw	a3,96(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004198:	02d05863          	blez	a3,800041c8 <write_head+0x5c>
    8000419c:	0001e797          	auipc	a5,0x1e
    800041a0:	68478793          	addi	a5,a5,1668 # 80022820 <log+0x38>
    800041a4:	06450713          	addi	a4,a0,100
    800041a8:	36fd                	addiw	a3,a3,-1
    800041aa:	02069613          	slli	a2,a3,0x20
    800041ae:	01e65693          	srli	a3,a2,0x1e
    800041b2:	0001e617          	auipc	a2,0x1e
    800041b6:	67260613          	addi	a2,a2,1650 # 80022824 <log+0x3c>
    800041ba:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    800041bc:	4390                	lw	a2,0(a5)
    800041be:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800041c0:	0791                	addi	a5,a5,4
    800041c2:	0711                	addi	a4,a4,4 # 43004 <_entry-0x7ffbcffc>
    800041c4:	fed79ce3          	bne	a5,a3,800041bc <write_head+0x50>
  }
  bwrite(buf);
    800041c8:	8526                	mv	a0,s1
    800041ca:	fffff097          	auipc	ra,0xfffff
    800041ce:	09e080e7          	jalr	158(ra) # 80003268 <bwrite>
  brelse(buf);
    800041d2:	8526                	mv	a0,s1
    800041d4:	fffff097          	auipc	ra,0xfffff
    800041d8:	0d2080e7          	jalr	210(ra) # 800032a6 <brelse>
}
    800041dc:	60e2                	ld	ra,24(sp)
    800041de:	6442                	ld	s0,16(sp)
    800041e0:	64a2                	ld	s1,8(sp)
    800041e2:	6902                	ld	s2,0(sp)
    800041e4:	6105                	addi	sp,sp,32
    800041e6:	8082                	ret

00000000800041e8 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    800041e8:	0001e797          	auipc	a5,0x1e
    800041ec:	6347a783          	lw	a5,1588(a5) # 8002281c <log+0x34>
    800041f0:	0af05d63          	blez	a5,800042aa <install_trans+0xc2>
{
    800041f4:	7139                	addi	sp,sp,-64
    800041f6:	fc06                	sd	ra,56(sp)
    800041f8:	f822                	sd	s0,48(sp)
    800041fa:	f426                	sd	s1,40(sp)
    800041fc:	f04a                	sd	s2,32(sp)
    800041fe:	ec4e                	sd	s3,24(sp)
    80004200:	e852                	sd	s4,16(sp)
    80004202:	e456                	sd	s5,8(sp)
    80004204:	e05a                	sd	s6,0(sp)
    80004206:	0080                	addi	s0,sp,64
    80004208:	8b2a                	mv	s6,a0
    8000420a:	0001ea97          	auipc	s5,0x1e
    8000420e:	616a8a93          	addi	s5,s5,1558 # 80022820 <log+0x38>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004212:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004214:	0001e997          	auipc	s3,0x1e
    80004218:	5d498993          	addi	s3,s3,1492 # 800227e8 <log>
    8000421c:	a00d                	j	8000423e <install_trans+0x56>
    brelse(lbuf);
    8000421e:	854a                	mv	a0,s2
    80004220:	fffff097          	auipc	ra,0xfffff
    80004224:	086080e7          	jalr	134(ra) # 800032a6 <brelse>
    brelse(dbuf);
    80004228:	8526                	mv	a0,s1
    8000422a:	fffff097          	auipc	ra,0xfffff
    8000422e:	07c080e7          	jalr	124(ra) # 800032a6 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004232:	2a05                	addiw	s4,s4,1
    80004234:	0a91                	addi	s5,s5,4
    80004236:	0349a783          	lw	a5,52(s3)
    8000423a:	04fa5e63          	bge	s4,a5,80004296 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000423e:	0209a583          	lw	a1,32(s3)
    80004242:	014585bb          	addw	a1,a1,s4
    80004246:	2585                	addiw	a1,a1,1
    80004248:	0309a503          	lw	a0,48(s3)
    8000424c:	fffff097          	auipc	ra,0xfffff
    80004250:	f2a080e7          	jalr	-214(ra) # 80003176 <bread>
    80004254:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004256:	000aa583          	lw	a1,0(s5)
    8000425a:	0309a503          	lw	a0,48(s3)
    8000425e:	fffff097          	auipc	ra,0xfffff
    80004262:	f18080e7          	jalr	-232(ra) # 80003176 <bread>
    80004266:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004268:	40000613          	li	a2,1024
    8000426c:	06090593          	addi	a1,s2,96
    80004270:	06050513          	addi	a0,a0,96
    80004274:	ffffd097          	auipc	ra,0xffffd
    80004278:	ec8080e7          	jalr	-312(ra) # 8000113c <memmove>
    bwrite(dbuf);  // write dst to disk
    8000427c:	8526                	mv	a0,s1
    8000427e:	fffff097          	auipc	ra,0xfffff
    80004282:	fea080e7          	jalr	-22(ra) # 80003268 <bwrite>
    if(recovering == 0)
    80004286:	f80b1ce3          	bnez	s6,8000421e <install_trans+0x36>
      bunpin(dbuf);
    8000428a:	8526                	mv	a0,s1
    8000428c:	fffff097          	auipc	ra,0xfffff
    80004290:	0f4080e7          	jalr	244(ra) # 80003380 <bunpin>
    80004294:	b769                	j	8000421e <install_trans+0x36>
}
    80004296:	70e2                	ld	ra,56(sp)
    80004298:	7442                	ld	s0,48(sp)
    8000429a:	74a2                	ld	s1,40(sp)
    8000429c:	7902                	ld	s2,32(sp)
    8000429e:	69e2                	ld	s3,24(sp)
    800042a0:	6a42                	ld	s4,16(sp)
    800042a2:	6aa2                	ld	s5,8(sp)
    800042a4:	6b02                	ld	s6,0(sp)
    800042a6:	6121                	addi	sp,sp,64
    800042a8:	8082                	ret
    800042aa:	8082                	ret

00000000800042ac <initlog>:
{
    800042ac:	7179                	addi	sp,sp,-48
    800042ae:	f406                	sd	ra,40(sp)
    800042b0:	f022                	sd	s0,32(sp)
    800042b2:	ec26                	sd	s1,24(sp)
    800042b4:	e84a                	sd	s2,16(sp)
    800042b6:	e44e                	sd	s3,8(sp)
    800042b8:	1800                	addi	s0,sp,48
    800042ba:	892a                	mv	s2,a0
    800042bc:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    800042be:	0001e497          	auipc	s1,0x1e
    800042c2:	52a48493          	addi	s1,s1,1322 # 800227e8 <log>
    800042c6:	00004597          	auipc	a1,0x4
    800042ca:	3c258593          	addi	a1,a1,962 # 80008688 <syscalls+0x1d0>
    800042ce:	8526                	mv	a0,s1
    800042d0:	ffffd097          	auipc	ra,0xffffd
    800042d4:	bac080e7          	jalr	-1108(ra) # 80000e7c <initlock>
  log.start = sb->logstart;
    800042d8:	0149a583          	lw	a1,20(s3)
    800042dc:	d08c                	sw	a1,32(s1)
  log.size = sb->nlog;
    800042de:	0109a783          	lw	a5,16(s3)
    800042e2:	d0dc                	sw	a5,36(s1)
  log.dev = dev;
    800042e4:	0324a823          	sw	s2,48(s1)
  struct buf *buf = bread(log.dev, log.start);
    800042e8:	854a                	mv	a0,s2
    800042ea:	fffff097          	auipc	ra,0xfffff
    800042ee:	e8c080e7          	jalr	-372(ra) # 80003176 <bread>
  log.lh.n = lh->n;
    800042f2:	5134                	lw	a3,96(a0)
    800042f4:	d8d4                	sw	a3,52(s1)
  for (i = 0; i < log.lh.n; i++) {
    800042f6:	02d05663          	blez	a3,80004322 <initlog+0x76>
    800042fa:	06450793          	addi	a5,a0,100
    800042fe:	0001e717          	auipc	a4,0x1e
    80004302:	52270713          	addi	a4,a4,1314 # 80022820 <log+0x38>
    80004306:	36fd                	addiw	a3,a3,-1
    80004308:	02069613          	slli	a2,a3,0x20
    8000430c:	01e65693          	srli	a3,a2,0x1e
    80004310:	06850613          	addi	a2,a0,104
    80004314:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    80004316:	4390                	lw	a2,0(a5)
    80004318:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    8000431a:	0791                	addi	a5,a5,4
    8000431c:	0711                	addi	a4,a4,4
    8000431e:	fed79ce3          	bne	a5,a3,80004316 <initlog+0x6a>
  brelse(buf);
    80004322:	fffff097          	auipc	ra,0xfffff
    80004326:	f84080e7          	jalr	-124(ra) # 800032a6 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    8000432a:	4505                	li	a0,1
    8000432c:	00000097          	auipc	ra,0x0
    80004330:	ebc080e7          	jalr	-324(ra) # 800041e8 <install_trans>
  log.lh.n = 0;
    80004334:	0001e797          	auipc	a5,0x1e
    80004338:	4e07a423          	sw	zero,1256(a5) # 8002281c <log+0x34>
  write_head(); // clear the log
    8000433c:	00000097          	auipc	ra,0x0
    80004340:	e30080e7          	jalr	-464(ra) # 8000416c <write_head>
}
    80004344:	70a2                	ld	ra,40(sp)
    80004346:	7402                	ld	s0,32(sp)
    80004348:	64e2                	ld	s1,24(sp)
    8000434a:	6942                	ld	s2,16(sp)
    8000434c:	69a2                	ld	s3,8(sp)
    8000434e:	6145                	addi	sp,sp,48
    80004350:	8082                	ret

0000000080004352 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004352:	1101                	addi	sp,sp,-32
    80004354:	ec06                	sd	ra,24(sp)
    80004356:	e822                	sd	s0,16(sp)
    80004358:	e426                	sd	s1,8(sp)
    8000435a:	e04a                	sd	s2,0(sp)
    8000435c:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    8000435e:	0001e517          	auipc	a0,0x1e
    80004362:	48a50513          	addi	a0,a0,1162 # 800227e8 <log>
    80004366:	ffffd097          	auipc	ra,0xffffd
    8000436a:	99a080e7          	jalr	-1638(ra) # 80000d00 <acquire>
  while(1){
    if(log.committing){
    8000436e:	0001e497          	auipc	s1,0x1e
    80004372:	47a48493          	addi	s1,s1,1146 # 800227e8 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004376:	4979                	li	s2,30
    80004378:	a039                	j	80004386 <begin_op+0x34>
      sleep(&log, &log.lock);
    8000437a:	85a6                	mv	a1,s1
    8000437c:	8526                	mv	a0,s1
    8000437e:	ffffe097          	auipc	ra,0xffffe
    80004382:	1e0080e7          	jalr	480(ra) # 8000255e <sleep>
    if(log.committing){
    80004386:	54dc                	lw	a5,44(s1)
    80004388:	fbed                	bnez	a5,8000437a <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000438a:	5498                	lw	a4,40(s1)
    8000438c:	2705                	addiw	a4,a4,1
    8000438e:	0007069b          	sext.w	a3,a4
    80004392:	0027179b          	slliw	a5,a4,0x2
    80004396:	9fb9                	addw	a5,a5,a4
    80004398:	0017979b          	slliw	a5,a5,0x1
    8000439c:	58d8                	lw	a4,52(s1)
    8000439e:	9fb9                	addw	a5,a5,a4
    800043a0:	00f95963          	bge	s2,a5,800043b2 <begin_op+0x60>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    800043a4:	85a6                	mv	a1,s1
    800043a6:	8526                	mv	a0,s1
    800043a8:	ffffe097          	auipc	ra,0xffffe
    800043ac:	1b6080e7          	jalr	438(ra) # 8000255e <sleep>
    800043b0:	bfd9                	j	80004386 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    800043b2:	0001e517          	auipc	a0,0x1e
    800043b6:	43650513          	addi	a0,a0,1078 # 800227e8 <log>
    800043ba:	d514                	sw	a3,40(a0)
      release(&log.lock);
    800043bc:	ffffd097          	auipc	ra,0xffffd
    800043c0:	a14080e7          	jalr	-1516(ra) # 80000dd0 <release>
      break;
    }
  }
}
    800043c4:	60e2                	ld	ra,24(sp)
    800043c6:	6442                	ld	s0,16(sp)
    800043c8:	64a2                	ld	s1,8(sp)
    800043ca:	6902                	ld	s2,0(sp)
    800043cc:	6105                	addi	sp,sp,32
    800043ce:	8082                	ret

00000000800043d0 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    800043d0:	7139                	addi	sp,sp,-64
    800043d2:	fc06                	sd	ra,56(sp)
    800043d4:	f822                	sd	s0,48(sp)
    800043d6:	f426                	sd	s1,40(sp)
    800043d8:	f04a                	sd	s2,32(sp)
    800043da:	ec4e                	sd	s3,24(sp)
    800043dc:	e852                	sd	s4,16(sp)
    800043de:	e456                	sd	s5,8(sp)
    800043e0:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    800043e2:	0001e497          	auipc	s1,0x1e
    800043e6:	40648493          	addi	s1,s1,1030 # 800227e8 <log>
    800043ea:	8526                	mv	a0,s1
    800043ec:	ffffd097          	auipc	ra,0xffffd
    800043f0:	914080e7          	jalr	-1772(ra) # 80000d00 <acquire>
  log.outstanding -= 1;
    800043f4:	549c                	lw	a5,40(s1)
    800043f6:	37fd                	addiw	a5,a5,-1
    800043f8:	0007891b          	sext.w	s2,a5
    800043fc:	d49c                	sw	a5,40(s1)
  if(log.committing)
    800043fe:	54dc                	lw	a5,44(s1)
    80004400:	e7b9                	bnez	a5,8000444e <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004402:	04091e63          	bnez	s2,8000445e <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    80004406:	0001e497          	auipc	s1,0x1e
    8000440a:	3e248493          	addi	s1,s1,994 # 800227e8 <log>
    8000440e:	4785                	li	a5,1
    80004410:	d4dc                	sw	a5,44(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004412:	8526                	mv	a0,s1
    80004414:	ffffd097          	auipc	ra,0xffffd
    80004418:	9bc080e7          	jalr	-1604(ra) # 80000dd0 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    8000441c:	58dc                	lw	a5,52(s1)
    8000441e:	06f04763          	bgtz	a5,8000448c <end_op+0xbc>
    acquire(&log.lock);
    80004422:	0001e497          	auipc	s1,0x1e
    80004426:	3c648493          	addi	s1,s1,966 # 800227e8 <log>
    8000442a:	8526                	mv	a0,s1
    8000442c:	ffffd097          	auipc	ra,0xffffd
    80004430:	8d4080e7          	jalr	-1836(ra) # 80000d00 <acquire>
    log.committing = 0;
    80004434:	0204a623          	sw	zero,44(s1)
    wakeup(&log);
    80004438:	8526                	mv	a0,s1
    8000443a:	ffffe097          	auipc	ra,0xffffe
    8000443e:	2a4080e7          	jalr	676(ra) # 800026de <wakeup>
    release(&log.lock);
    80004442:	8526                	mv	a0,s1
    80004444:	ffffd097          	auipc	ra,0xffffd
    80004448:	98c080e7          	jalr	-1652(ra) # 80000dd0 <release>
}
    8000444c:	a03d                	j	8000447a <end_op+0xaa>
    panic("log.committing");
    8000444e:	00004517          	auipc	a0,0x4
    80004452:	24250513          	addi	a0,a0,578 # 80008690 <syscalls+0x1d8>
    80004456:	ffffc097          	auipc	ra,0xffffc
    8000445a:	0f6080e7          	jalr	246(ra) # 8000054c <panic>
    wakeup(&log);
    8000445e:	0001e497          	auipc	s1,0x1e
    80004462:	38a48493          	addi	s1,s1,906 # 800227e8 <log>
    80004466:	8526                	mv	a0,s1
    80004468:	ffffe097          	auipc	ra,0xffffe
    8000446c:	276080e7          	jalr	630(ra) # 800026de <wakeup>
  release(&log.lock);
    80004470:	8526                	mv	a0,s1
    80004472:	ffffd097          	auipc	ra,0xffffd
    80004476:	95e080e7          	jalr	-1698(ra) # 80000dd0 <release>
}
    8000447a:	70e2                	ld	ra,56(sp)
    8000447c:	7442                	ld	s0,48(sp)
    8000447e:	74a2                	ld	s1,40(sp)
    80004480:	7902                	ld	s2,32(sp)
    80004482:	69e2                	ld	s3,24(sp)
    80004484:	6a42                	ld	s4,16(sp)
    80004486:	6aa2                	ld	s5,8(sp)
    80004488:	6121                	addi	sp,sp,64
    8000448a:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    8000448c:	0001ea97          	auipc	s5,0x1e
    80004490:	394a8a93          	addi	s5,s5,916 # 80022820 <log+0x38>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004494:	0001ea17          	auipc	s4,0x1e
    80004498:	354a0a13          	addi	s4,s4,852 # 800227e8 <log>
    8000449c:	020a2583          	lw	a1,32(s4)
    800044a0:	012585bb          	addw	a1,a1,s2
    800044a4:	2585                	addiw	a1,a1,1
    800044a6:	030a2503          	lw	a0,48(s4)
    800044aa:	fffff097          	auipc	ra,0xfffff
    800044ae:	ccc080e7          	jalr	-820(ra) # 80003176 <bread>
    800044b2:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    800044b4:	000aa583          	lw	a1,0(s5)
    800044b8:	030a2503          	lw	a0,48(s4)
    800044bc:	fffff097          	auipc	ra,0xfffff
    800044c0:	cba080e7          	jalr	-838(ra) # 80003176 <bread>
    800044c4:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    800044c6:	40000613          	li	a2,1024
    800044ca:	06050593          	addi	a1,a0,96
    800044ce:	06048513          	addi	a0,s1,96
    800044d2:	ffffd097          	auipc	ra,0xffffd
    800044d6:	c6a080e7          	jalr	-918(ra) # 8000113c <memmove>
    bwrite(to);  // write the log
    800044da:	8526                	mv	a0,s1
    800044dc:	fffff097          	auipc	ra,0xfffff
    800044e0:	d8c080e7          	jalr	-628(ra) # 80003268 <bwrite>
    brelse(from);
    800044e4:	854e                	mv	a0,s3
    800044e6:	fffff097          	auipc	ra,0xfffff
    800044ea:	dc0080e7          	jalr	-576(ra) # 800032a6 <brelse>
    brelse(to);
    800044ee:	8526                	mv	a0,s1
    800044f0:	fffff097          	auipc	ra,0xfffff
    800044f4:	db6080e7          	jalr	-586(ra) # 800032a6 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800044f8:	2905                	addiw	s2,s2,1
    800044fa:	0a91                	addi	s5,s5,4
    800044fc:	034a2783          	lw	a5,52(s4)
    80004500:	f8f94ee3          	blt	s2,a5,8000449c <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004504:	00000097          	auipc	ra,0x0
    80004508:	c68080e7          	jalr	-920(ra) # 8000416c <write_head>
    install_trans(0); // Now install writes to home locations
    8000450c:	4501                	li	a0,0
    8000450e:	00000097          	auipc	ra,0x0
    80004512:	cda080e7          	jalr	-806(ra) # 800041e8 <install_trans>
    log.lh.n = 0;
    80004516:	0001e797          	auipc	a5,0x1e
    8000451a:	3007a323          	sw	zero,774(a5) # 8002281c <log+0x34>
    write_head();    // Erase the transaction from the log
    8000451e:	00000097          	auipc	ra,0x0
    80004522:	c4e080e7          	jalr	-946(ra) # 8000416c <write_head>
    80004526:	bdf5                	j	80004422 <end_op+0x52>

0000000080004528 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004528:	1101                	addi	sp,sp,-32
    8000452a:	ec06                	sd	ra,24(sp)
    8000452c:	e822                	sd	s0,16(sp)
    8000452e:	e426                	sd	s1,8(sp)
    80004530:	e04a                	sd	s2,0(sp)
    80004532:	1000                	addi	s0,sp,32
  int i;

  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004534:	0001e717          	auipc	a4,0x1e
    80004538:	2e872703          	lw	a4,744(a4) # 8002281c <log+0x34>
    8000453c:	47f5                	li	a5,29
    8000453e:	08e7c063          	blt	a5,a4,800045be <log_write+0x96>
    80004542:	84aa                	mv	s1,a0
    80004544:	0001e797          	auipc	a5,0x1e
    80004548:	2c87a783          	lw	a5,712(a5) # 8002280c <log+0x24>
    8000454c:	37fd                	addiw	a5,a5,-1
    8000454e:	06f75863          	bge	a4,a5,800045be <log_write+0x96>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004552:	0001e797          	auipc	a5,0x1e
    80004556:	2be7a783          	lw	a5,702(a5) # 80022810 <log+0x28>
    8000455a:	06f05a63          	blez	a5,800045ce <log_write+0xa6>
    panic("log_write outside of trans");

  acquire(&log.lock);
    8000455e:	0001e917          	auipc	s2,0x1e
    80004562:	28a90913          	addi	s2,s2,650 # 800227e8 <log>
    80004566:	854a                	mv	a0,s2
    80004568:	ffffc097          	auipc	ra,0xffffc
    8000456c:	798080e7          	jalr	1944(ra) # 80000d00 <acquire>
  for (i = 0; i < log.lh.n; i++) {
    80004570:	03492603          	lw	a2,52(s2)
    80004574:	06c05563          	blez	a2,800045de <log_write+0xb6>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    80004578:	44cc                	lw	a1,12(s1)
    8000457a:	0001e717          	auipc	a4,0x1e
    8000457e:	2a670713          	addi	a4,a4,678 # 80022820 <log+0x38>
  for (i = 0; i < log.lh.n; i++) {
    80004582:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    80004584:	4314                	lw	a3,0(a4)
    80004586:	04b68d63          	beq	a3,a1,800045e0 <log_write+0xb8>
  for (i = 0; i < log.lh.n; i++) {
    8000458a:	2785                	addiw	a5,a5,1
    8000458c:	0711                	addi	a4,a4,4
    8000458e:	fec79be3          	bne	a5,a2,80004584 <log_write+0x5c>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004592:	0631                	addi	a2,a2,12
    80004594:	060a                	slli	a2,a2,0x2
    80004596:	0001e797          	auipc	a5,0x1e
    8000459a:	25278793          	addi	a5,a5,594 # 800227e8 <log>
    8000459e:	97b2                	add	a5,a5,a2
    800045a0:	44d8                	lw	a4,12(s1)
    800045a2:	c798                	sw	a4,8(a5)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    800045a4:	8526                	mv	a0,s1
    800045a6:	fffff097          	auipc	ra,0xfffff
    800045aa:	d9e080e7          	jalr	-610(ra) # 80003344 <bpin>
    log.lh.n++;
    800045ae:	0001e717          	auipc	a4,0x1e
    800045b2:	23a70713          	addi	a4,a4,570 # 800227e8 <log>
    800045b6:	5b5c                	lw	a5,52(a4)
    800045b8:	2785                	addiw	a5,a5,1
    800045ba:	db5c                	sw	a5,52(a4)
    800045bc:	a835                	j	800045f8 <log_write+0xd0>
    panic("too big a transaction");
    800045be:	00004517          	auipc	a0,0x4
    800045c2:	0e250513          	addi	a0,a0,226 # 800086a0 <syscalls+0x1e8>
    800045c6:	ffffc097          	auipc	ra,0xffffc
    800045ca:	f86080e7          	jalr	-122(ra) # 8000054c <panic>
    panic("log_write outside of trans");
    800045ce:	00004517          	auipc	a0,0x4
    800045d2:	0ea50513          	addi	a0,a0,234 # 800086b8 <syscalls+0x200>
    800045d6:	ffffc097          	auipc	ra,0xffffc
    800045da:	f76080e7          	jalr	-138(ra) # 8000054c <panic>
  for (i = 0; i < log.lh.n; i++) {
    800045de:	4781                	li	a5,0
  log.lh.block[i] = b->blockno;
    800045e0:	00c78693          	addi	a3,a5,12
    800045e4:	068a                	slli	a3,a3,0x2
    800045e6:	0001e717          	auipc	a4,0x1e
    800045ea:	20270713          	addi	a4,a4,514 # 800227e8 <log>
    800045ee:	9736                	add	a4,a4,a3
    800045f0:	44d4                	lw	a3,12(s1)
    800045f2:	c714                	sw	a3,8(a4)
  if (i == log.lh.n) {  // Add new block to log?
    800045f4:	faf608e3          	beq	a2,a5,800045a4 <log_write+0x7c>
  }
  release(&log.lock);
    800045f8:	0001e517          	auipc	a0,0x1e
    800045fc:	1f050513          	addi	a0,a0,496 # 800227e8 <log>
    80004600:	ffffc097          	auipc	ra,0xffffc
    80004604:	7d0080e7          	jalr	2000(ra) # 80000dd0 <release>
}
    80004608:	60e2                	ld	ra,24(sp)
    8000460a:	6442                	ld	s0,16(sp)
    8000460c:	64a2                	ld	s1,8(sp)
    8000460e:	6902                	ld	s2,0(sp)
    80004610:	6105                	addi	sp,sp,32
    80004612:	8082                	ret

0000000080004614 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004614:	1101                	addi	sp,sp,-32
    80004616:	ec06                	sd	ra,24(sp)
    80004618:	e822                	sd	s0,16(sp)
    8000461a:	e426                	sd	s1,8(sp)
    8000461c:	e04a                	sd	s2,0(sp)
    8000461e:	1000                	addi	s0,sp,32
    80004620:	84aa                	mv	s1,a0
    80004622:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004624:	00004597          	auipc	a1,0x4
    80004628:	0b458593          	addi	a1,a1,180 # 800086d8 <syscalls+0x220>
    8000462c:	0521                	addi	a0,a0,8
    8000462e:	ffffd097          	auipc	ra,0xffffd
    80004632:	84e080e7          	jalr	-1970(ra) # 80000e7c <initlock>
  lk->name = name;
    80004636:	0324b423          	sd	s2,40(s1)
  lk->locked = 0;
    8000463a:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000463e:	0204a823          	sw	zero,48(s1)
}
    80004642:	60e2                	ld	ra,24(sp)
    80004644:	6442                	ld	s0,16(sp)
    80004646:	64a2                	ld	s1,8(sp)
    80004648:	6902                	ld	s2,0(sp)
    8000464a:	6105                	addi	sp,sp,32
    8000464c:	8082                	ret

000000008000464e <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    8000464e:	1101                	addi	sp,sp,-32
    80004650:	ec06                	sd	ra,24(sp)
    80004652:	e822                	sd	s0,16(sp)
    80004654:	e426                	sd	s1,8(sp)
    80004656:	e04a                	sd	s2,0(sp)
    80004658:	1000                	addi	s0,sp,32
    8000465a:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000465c:	00850913          	addi	s2,a0,8
    80004660:	854a                	mv	a0,s2
    80004662:	ffffc097          	auipc	ra,0xffffc
    80004666:	69e080e7          	jalr	1694(ra) # 80000d00 <acquire>
  while (lk->locked) {
    8000466a:	409c                	lw	a5,0(s1)
    8000466c:	cb89                	beqz	a5,8000467e <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    8000466e:	85ca                	mv	a1,s2
    80004670:	8526                	mv	a0,s1
    80004672:	ffffe097          	auipc	ra,0xffffe
    80004676:	eec080e7          	jalr	-276(ra) # 8000255e <sleep>
  while (lk->locked) {
    8000467a:	409c                	lw	a5,0(s1)
    8000467c:	fbed                	bnez	a5,8000466e <acquiresleep+0x20>
  }
  lk->locked = 1;
    8000467e:	4785                	li	a5,1
    80004680:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004682:	ffffd097          	auipc	ra,0xffffd
    80004686:	6c4080e7          	jalr	1732(ra) # 80001d46 <myproc>
    8000468a:	413c                	lw	a5,64(a0)
    8000468c:	d89c                	sw	a5,48(s1)
  release(&lk->lk);
    8000468e:	854a                	mv	a0,s2
    80004690:	ffffc097          	auipc	ra,0xffffc
    80004694:	740080e7          	jalr	1856(ra) # 80000dd0 <release>
}
    80004698:	60e2                	ld	ra,24(sp)
    8000469a:	6442                	ld	s0,16(sp)
    8000469c:	64a2                	ld	s1,8(sp)
    8000469e:	6902                	ld	s2,0(sp)
    800046a0:	6105                	addi	sp,sp,32
    800046a2:	8082                	ret

00000000800046a4 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    800046a4:	1101                	addi	sp,sp,-32
    800046a6:	ec06                	sd	ra,24(sp)
    800046a8:	e822                	sd	s0,16(sp)
    800046aa:	e426                	sd	s1,8(sp)
    800046ac:	e04a                	sd	s2,0(sp)
    800046ae:	1000                	addi	s0,sp,32
    800046b0:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800046b2:	00850913          	addi	s2,a0,8
    800046b6:	854a                	mv	a0,s2
    800046b8:	ffffc097          	auipc	ra,0xffffc
    800046bc:	648080e7          	jalr	1608(ra) # 80000d00 <acquire>
  lk->locked = 0;
    800046c0:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800046c4:	0204a823          	sw	zero,48(s1)
  wakeup(lk);
    800046c8:	8526                	mv	a0,s1
    800046ca:	ffffe097          	auipc	ra,0xffffe
    800046ce:	014080e7          	jalr	20(ra) # 800026de <wakeup>
  release(&lk->lk);
    800046d2:	854a                	mv	a0,s2
    800046d4:	ffffc097          	auipc	ra,0xffffc
    800046d8:	6fc080e7          	jalr	1788(ra) # 80000dd0 <release>
}
    800046dc:	60e2                	ld	ra,24(sp)
    800046de:	6442                	ld	s0,16(sp)
    800046e0:	64a2                	ld	s1,8(sp)
    800046e2:	6902                	ld	s2,0(sp)
    800046e4:	6105                	addi	sp,sp,32
    800046e6:	8082                	ret

00000000800046e8 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    800046e8:	7179                	addi	sp,sp,-48
    800046ea:	f406                	sd	ra,40(sp)
    800046ec:	f022                	sd	s0,32(sp)
    800046ee:	ec26                	sd	s1,24(sp)
    800046f0:	e84a                	sd	s2,16(sp)
    800046f2:	e44e                	sd	s3,8(sp)
    800046f4:	1800                	addi	s0,sp,48
    800046f6:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    800046f8:	00850913          	addi	s2,a0,8
    800046fc:	854a                	mv	a0,s2
    800046fe:	ffffc097          	auipc	ra,0xffffc
    80004702:	602080e7          	jalr	1538(ra) # 80000d00 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004706:	409c                	lw	a5,0(s1)
    80004708:	ef99                	bnez	a5,80004726 <holdingsleep+0x3e>
    8000470a:	4481                	li	s1,0
  release(&lk->lk);
    8000470c:	854a                	mv	a0,s2
    8000470e:	ffffc097          	auipc	ra,0xffffc
    80004712:	6c2080e7          	jalr	1730(ra) # 80000dd0 <release>
  return r;
}
    80004716:	8526                	mv	a0,s1
    80004718:	70a2                	ld	ra,40(sp)
    8000471a:	7402                	ld	s0,32(sp)
    8000471c:	64e2                	ld	s1,24(sp)
    8000471e:	6942                	ld	s2,16(sp)
    80004720:	69a2                	ld	s3,8(sp)
    80004722:	6145                	addi	sp,sp,48
    80004724:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004726:	0304a983          	lw	s3,48(s1)
    8000472a:	ffffd097          	auipc	ra,0xffffd
    8000472e:	61c080e7          	jalr	1564(ra) # 80001d46 <myproc>
    80004732:	4124                	lw	s1,64(a0)
    80004734:	413484b3          	sub	s1,s1,s3
    80004738:	0014b493          	seqz	s1,s1
    8000473c:	bfc1                	j	8000470c <holdingsleep+0x24>

000000008000473e <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    8000473e:	1141                	addi	sp,sp,-16
    80004740:	e406                	sd	ra,8(sp)
    80004742:	e022                	sd	s0,0(sp)
    80004744:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004746:	00004597          	auipc	a1,0x4
    8000474a:	fa258593          	addi	a1,a1,-94 # 800086e8 <syscalls+0x230>
    8000474e:	0001e517          	auipc	a0,0x1e
    80004752:	1ea50513          	addi	a0,a0,490 # 80022938 <ftable>
    80004756:	ffffc097          	auipc	ra,0xffffc
    8000475a:	726080e7          	jalr	1830(ra) # 80000e7c <initlock>
}
    8000475e:	60a2                	ld	ra,8(sp)
    80004760:	6402                	ld	s0,0(sp)
    80004762:	0141                	addi	sp,sp,16
    80004764:	8082                	ret

0000000080004766 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004766:	1101                	addi	sp,sp,-32
    80004768:	ec06                	sd	ra,24(sp)
    8000476a:	e822                	sd	s0,16(sp)
    8000476c:	e426                	sd	s1,8(sp)
    8000476e:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004770:	0001e517          	auipc	a0,0x1e
    80004774:	1c850513          	addi	a0,a0,456 # 80022938 <ftable>
    80004778:	ffffc097          	auipc	ra,0xffffc
    8000477c:	588080e7          	jalr	1416(ra) # 80000d00 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004780:	0001e497          	auipc	s1,0x1e
    80004784:	1d848493          	addi	s1,s1,472 # 80022958 <ftable+0x20>
    80004788:	0001f717          	auipc	a4,0x1f
    8000478c:	17070713          	addi	a4,a4,368 # 800238f8 <ftable+0xfc0>
    if(f->ref == 0){
    80004790:	40dc                	lw	a5,4(s1)
    80004792:	cf99                	beqz	a5,800047b0 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004794:	02848493          	addi	s1,s1,40
    80004798:	fee49ce3          	bne	s1,a4,80004790 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    8000479c:	0001e517          	auipc	a0,0x1e
    800047a0:	19c50513          	addi	a0,a0,412 # 80022938 <ftable>
    800047a4:	ffffc097          	auipc	ra,0xffffc
    800047a8:	62c080e7          	jalr	1580(ra) # 80000dd0 <release>
  return 0;
    800047ac:	4481                	li	s1,0
    800047ae:	a819                	j	800047c4 <filealloc+0x5e>
      f->ref = 1;
    800047b0:	4785                	li	a5,1
    800047b2:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    800047b4:	0001e517          	auipc	a0,0x1e
    800047b8:	18450513          	addi	a0,a0,388 # 80022938 <ftable>
    800047bc:	ffffc097          	auipc	ra,0xffffc
    800047c0:	614080e7          	jalr	1556(ra) # 80000dd0 <release>
}
    800047c4:	8526                	mv	a0,s1
    800047c6:	60e2                	ld	ra,24(sp)
    800047c8:	6442                	ld	s0,16(sp)
    800047ca:	64a2                	ld	s1,8(sp)
    800047cc:	6105                	addi	sp,sp,32
    800047ce:	8082                	ret

00000000800047d0 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    800047d0:	1101                	addi	sp,sp,-32
    800047d2:	ec06                	sd	ra,24(sp)
    800047d4:	e822                	sd	s0,16(sp)
    800047d6:	e426                	sd	s1,8(sp)
    800047d8:	1000                	addi	s0,sp,32
    800047da:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    800047dc:	0001e517          	auipc	a0,0x1e
    800047e0:	15c50513          	addi	a0,a0,348 # 80022938 <ftable>
    800047e4:	ffffc097          	auipc	ra,0xffffc
    800047e8:	51c080e7          	jalr	1308(ra) # 80000d00 <acquire>
  if(f->ref < 1)
    800047ec:	40dc                	lw	a5,4(s1)
    800047ee:	02f05263          	blez	a5,80004812 <filedup+0x42>
    panic("filedup");
  f->ref++;
    800047f2:	2785                	addiw	a5,a5,1
    800047f4:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    800047f6:	0001e517          	auipc	a0,0x1e
    800047fa:	14250513          	addi	a0,a0,322 # 80022938 <ftable>
    800047fe:	ffffc097          	auipc	ra,0xffffc
    80004802:	5d2080e7          	jalr	1490(ra) # 80000dd0 <release>
  return f;
}
    80004806:	8526                	mv	a0,s1
    80004808:	60e2                	ld	ra,24(sp)
    8000480a:	6442                	ld	s0,16(sp)
    8000480c:	64a2                	ld	s1,8(sp)
    8000480e:	6105                	addi	sp,sp,32
    80004810:	8082                	ret
    panic("filedup");
    80004812:	00004517          	auipc	a0,0x4
    80004816:	ede50513          	addi	a0,a0,-290 # 800086f0 <syscalls+0x238>
    8000481a:	ffffc097          	auipc	ra,0xffffc
    8000481e:	d32080e7          	jalr	-718(ra) # 8000054c <panic>

0000000080004822 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004822:	7139                	addi	sp,sp,-64
    80004824:	fc06                	sd	ra,56(sp)
    80004826:	f822                	sd	s0,48(sp)
    80004828:	f426                	sd	s1,40(sp)
    8000482a:	f04a                	sd	s2,32(sp)
    8000482c:	ec4e                	sd	s3,24(sp)
    8000482e:	e852                	sd	s4,16(sp)
    80004830:	e456                	sd	s5,8(sp)
    80004832:	0080                	addi	s0,sp,64
    80004834:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004836:	0001e517          	auipc	a0,0x1e
    8000483a:	10250513          	addi	a0,a0,258 # 80022938 <ftable>
    8000483e:	ffffc097          	auipc	ra,0xffffc
    80004842:	4c2080e7          	jalr	1218(ra) # 80000d00 <acquire>
  if(f->ref < 1)
    80004846:	40dc                	lw	a5,4(s1)
    80004848:	06f05163          	blez	a5,800048aa <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    8000484c:	37fd                	addiw	a5,a5,-1
    8000484e:	0007871b          	sext.w	a4,a5
    80004852:	c0dc                	sw	a5,4(s1)
    80004854:	06e04363          	bgtz	a4,800048ba <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004858:	0004a903          	lw	s2,0(s1)
    8000485c:	0094ca83          	lbu	s5,9(s1)
    80004860:	0104ba03          	ld	s4,16(s1)
    80004864:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004868:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    8000486c:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004870:	0001e517          	auipc	a0,0x1e
    80004874:	0c850513          	addi	a0,a0,200 # 80022938 <ftable>
    80004878:	ffffc097          	auipc	ra,0xffffc
    8000487c:	558080e7          	jalr	1368(ra) # 80000dd0 <release>

  if(ff.type == FD_PIPE){
    80004880:	4785                	li	a5,1
    80004882:	04f90d63          	beq	s2,a5,800048dc <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004886:	3979                	addiw	s2,s2,-2
    80004888:	4785                	li	a5,1
    8000488a:	0527e063          	bltu	a5,s2,800048ca <fileclose+0xa8>
    begin_op();
    8000488e:	00000097          	auipc	ra,0x0
    80004892:	ac4080e7          	jalr	-1340(ra) # 80004352 <begin_op>
    iput(ff.ip);
    80004896:	854e                	mv	a0,s3
    80004898:	fffff097          	auipc	ra,0xfffff
    8000489c:	29a080e7          	jalr	666(ra) # 80003b32 <iput>
    end_op();
    800048a0:	00000097          	auipc	ra,0x0
    800048a4:	b30080e7          	jalr	-1232(ra) # 800043d0 <end_op>
    800048a8:	a00d                	j	800048ca <fileclose+0xa8>
    panic("fileclose");
    800048aa:	00004517          	auipc	a0,0x4
    800048ae:	e4e50513          	addi	a0,a0,-434 # 800086f8 <syscalls+0x240>
    800048b2:	ffffc097          	auipc	ra,0xffffc
    800048b6:	c9a080e7          	jalr	-870(ra) # 8000054c <panic>
    release(&ftable.lock);
    800048ba:	0001e517          	auipc	a0,0x1e
    800048be:	07e50513          	addi	a0,a0,126 # 80022938 <ftable>
    800048c2:	ffffc097          	auipc	ra,0xffffc
    800048c6:	50e080e7          	jalr	1294(ra) # 80000dd0 <release>
  }
}
    800048ca:	70e2                	ld	ra,56(sp)
    800048cc:	7442                	ld	s0,48(sp)
    800048ce:	74a2                	ld	s1,40(sp)
    800048d0:	7902                	ld	s2,32(sp)
    800048d2:	69e2                	ld	s3,24(sp)
    800048d4:	6a42                	ld	s4,16(sp)
    800048d6:	6aa2                	ld	s5,8(sp)
    800048d8:	6121                	addi	sp,sp,64
    800048da:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    800048dc:	85d6                	mv	a1,s5
    800048de:	8552                	mv	a0,s4
    800048e0:	00000097          	auipc	ra,0x0
    800048e4:	372080e7          	jalr	882(ra) # 80004c52 <pipeclose>
    800048e8:	b7cd                	j	800048ca <fileclose+0xa8>

00000000800048ea <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    800048ea:	715d                	addi	sp,sp,-80
    800048ec:	e486                	sd	ra,72(sp)
    800048ee:	e0a2                	sd	s0,64(sp)
    800048f0:	fc26                	sd	s1,56(sp)
    800048f2:	f84a                	sd	s2,48(sp)
    800048f4:	f44e                	sd	s3,40(sp)
    800048f6:	0880                	addi	s0,sp,80
    800048f8:	84aa                	mv	s1,a0
    800048fa:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    800048fc:	ffffd097          	auipc	ra,0xffffd
    80004900:	44a080e7          	jalr	1098(ra) # 80001d46 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004904:	409c                	lw	a5,0(s1)
    80004906:	37f9                	addiw	a5,a5,-2
    80004908:	4705                	li	a4,1
    8000490a:	04f76763          	bltu	a4,a5,80004958 <filestat+0x6e>
    8000490e:	892a                	mv	s2,a0
    ilock(f->ip);
    80004910:	6c88                	ld	a0,24(s1)
    80004912:	fffff097          	auipc	ra,0xfffff
    80004916:	066080e7          	jalr	102(ra) # 80003978 <ilock>
    stati(f->ip, &st);
    8000491a:	fb840593          	addi	a1,s0,-72
    8000491e:	6c88                	ld	a0,24(s1)
    80004920:	fffff097          	auipc	ra,0xfffff
    80004924:	2e2080e7          	jalr	738(ra) # 80003c02 <stati>
    iunlock(f->ip);
    80004928:	6c88                	ld	a0,24(s1)
    8000492a:	fffff097          	auipc	ra,0xfffff
    8000492e:	110080e7          	jalr	272(ra) # 80003a3a <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004932:	46e1                	li	a3,24
    80004934:	fb840613          	addi	a2,s0,-72
    80004938:	85ce                	mv	a1,s3
    8000493a:	05893503          	ld	a0,88(s2)
    8000493e:	ffffd097          	auipc	ra,0xffffd
    80004942:	0fe080e7          	jalr	254(ra) # 80001a3c <copyout>
    80004946:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    8000494a:	60a6                	ld	ra,72(sp)
    8000494c:	6406                	ld	s0,64(sp)
    8000494e:	74e2                	ld	s1,56(sp)
    80004950:	7942                	ld	s2,48(sp)
    80004952:	79a2                	ld	s3,40(sp)
    80004954:	6161                	addi	sp,sp,80
    80004956:	8082                	ret
  return -1;
    80004958:	557d                	li	a0,-1
    8000495a:	bfc5                	j	8000494a <filestat+0x60>

000000008000495c <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    8000495c:	7179                	addi	sp,sp,-48
    8000495e:	f406                	sd	ra,40(sp)
    80004960:	f022                	sd	s0,32(sp)
    80004962:	ec26                	sd	s1,24(sp)
    80004964:	e84a                	sd	s2,16(sp)
    80004966:	e44e                	sd	s3,8(sp)
    80004968:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    8000496a:	00854783          	lbu	a5,8(a0)
    8000496e:	c3d5                	beqz	a5,80004a12 <fileread+0xb6>
    80004970:	84aa                	mv	s1,a0
    80004972:	89ae                	mv	s3,a1
    80004974:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004976:	411c                	lw	a5,0(a0)
    80004978:	4705                	li	a4,1
    8000497a:	04e78963          	beq	a5,a4,800049cc <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    8000497e:	470d                	li	a4,3
    80004980:	04e78d63          	beq	a5,a4,800049da <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004984:	4709                	li	a4,2
    80004986:	06e79e63          	bne	a5,a4,80004a02 <fileread+0xa6>
    ilock(f->ip);
    8000498a:	6d08                	ld	a0,24(a0)
    8000498c:	fffff097          	auipc	ra,0xfffff
    80004990:	fec080e7          	jalr	-20(ra) # 80003978 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004994:	874a                	mv	a4,s2
    80004996:	5094                	lw	a3,32(s1)
    80004998:	864e                	mv	a2,s3
    8000499a:	4585                	li	a1,1
    8000499c:	6c88                	ld	a0,24(s1)
    8000499e:	fffff097          	auipc	ra,0xfffff
    800049a2:	28e080e7          	jalr	654(ra) # 80003c2c <readi>
    800049a6:	892a                	mv	s2,a0
    800049a8:	00a05563          	blez	a0,800049b2 <fileread+0x56>
      f->off += r;
    800049ac:	509c                	lw	a5,32(s1)
    800049ae:	9fa9                	addw	a5,a5,a0
    800049b0:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    800049b2:	6c88                	ld	a0,24(s1)
    800049b4:	fffff097          	auipc	ra,0xfffff
    800049b8:	086080e7          	jalr	134(ra) # 80003a3a <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    800049bc:	854a                	mv	a0,s2
    800049be:	70a2                	ld	ra,40(sp)
    800049c0:	7402                	ld	s0,32(sp)
    800049c2:	64e2                	ld	s1,24(sp)
    800049c4:	6942                	ld	s2,16(sp)
    800049c6:	69a2                	ld	s3,8(sp)
    800049c8:	6145                	addi	sp,sp,48
    800049ca:	8082                	ret
    r = piperead(f->pipe, addr, n);
    800049cc:	6908                	ld	a0,16(a0)
    800049ce:	00000097          	auipc	ra,0x0
    800049d2:	400080e7          	jalr	1024(ra) # 80004dce <piperead>
    800049d6:	892a                	mv	s2,a0
    800049d8:	b7d5                	j	800049bc <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    800049da:	02451783          	lh	a5,36(a0)
    800049de:	03079693          	slli	a3,a5,0x30
    800049e2:	92c1                	srli	a3,a3,0x30
    800049e4:	4725                	li	a4,9
    800049e6:	02d76863          	bltu	a4,a3,80004a16 <fileread+0xba>
    800049ea:	0792                	slli	a5,a5,0x4
    800049ec:	0001e717          	auipc	a4,0x1e
    800049f0:	eac70713          	addi	a4,a4,-340 # 80022898 <devsw>
    800049f4:	97ba                	add	a5,a5,a4
    800049f6:	639c                	ld	a5,0(a5)
    800049f8:	c38d                	beqz	a5,80004a1a <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    800049fa:	4505                	li	a0,1
    800049fc:	9782                	jalr	a5
    800049fe:	892a                	mv	s2,a0
    80004a00:	bf75                	j	800049bc <fileread+0x60>
    panic("fileread");
    80004a02:	00004517          	auipc	a0,0x4
    80004a06:	d0650513          	addi	a0,a0,-762 # 80008708 <syscalls+0x250>
    80004a0a:	ffffc097          	auipc	ra,0xffffc
    80004a0e:	b42080e7          	jalr	-1214(ra) # 8000054c <panic>
    return -1;
    80004a12:	597d                	li	s2,-1
    80004a14:	b765                	j	800049bc <fileread+0x60>
      return -1;
    80004a16:	597d                	li	s2,-1
    80004a18:	b755                	j	800049bc <fileread+0x60>
    80004a1a:	597d                	li	s2,-1
    80004a1c:	b745                	j	800049bc <fileread+0x60>

0000000080004a1e <filewrite>:
int
filewrite(struct file *f, uint64 addr, int n)
{
  int r, ret = 0;

  if(f->writable == 0)
    80004a1e:	00954783          	lbu	a5,9(a0)
    80004a22:	14078563          	beqz	a5,80004b6c <filewrite+0x14e>
{
    80004a26:	715d                	addi	sp,sp,-80
    80004a28:	e486                	sd	ra,72(sp)
    80004a2a:	e0a2                	sd	s0,64(sp)
    80004a2c:	fc26                	sd	s1,56(sp)
    80004a2e:	f84a                	sd	s2,48(sp)
    80004a30:	f44e                	sd	s3,40(sp)
    80004a32:	f052                	sd	s4,32(sp)
    80004a34:	ec56                	sd	s5,24(sp)
    80004a36:	e85a                	sd	s6,16(sp)
    80004a38:	e45e                	sd	s7,8(sp)
    80004a3a:	e062                	sd	s8,0(sp)
    80004a3c:	0880                	addi	s0,sp,80
    80004a3e:	892a                	mv	s2,a0
    80004a40:	8b2e                	mv	s6,a1
    80004a42:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004a44:	411c                	lw	a5,0(a0)
    80004a46:	4705                	li	a4,1
    80004a48:	02e78263          	beq	a5,a4,80004a6c <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004a4c:	470d                	li	a4,3
    80004a4e:	02e78563          	beq	a5,a4,80004a78 <filewrite+0x5a>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004a52:	4709                	li	a4,2
    80004a54:	10e79463          	bne	a5,a4,80004b5c <filewrite+0x13e>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004a58:	0ec05e63          	blez	a2,80004b54 <filewrite+0x136>
    int i = 0;
    80004a5c:	4981                	li	s3,0
    80004a5e:	6b85                	lui	s7,0x1
    80004a60:	c00b8b93          	addi	s7,s7,-1024 # c00 <_entry-0x7ffff400>
    80004a64:	6c05                	lui	s8,0x1
    80004a66:	c00c0c1b          	addiw	s8,s8,-1024 # c00 <_entry-0x7ffff400>
    80004a6a:	a851                	j	80004afe <filewrite+0xe0>
    ret = pipewrite(f->pipe, addr, n);
    80004a6c:	6908                	ld	a0,16(a0)
    80004a6e:	00000097          	auipc	ra,0x0
    80004a72:	25e080e7          	jalr	606(ra) # 80004ccc <pipewrite>
    80004a76:	a85d                	j	80004b2c <filewrite+0x10e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004a78:	02451783          	lh	a5,36(a0)
    80004a7c:	03079693          	slli	a3,a5,0x30
    80004a80:	92c1                	srli	a3,a3,0x30
    80004a82:	4725                	li	a4,9
    80004a84:	0ed76663          	bltu	a4,a3,80004b70 <filewrite+0x152>
    80004a88:	0792                	slli	a5,a5,0x4
    80004a8a:	0001e717          	auipc	a4,0x1e
    80004a8e:	e0e70713          	addi	a4,a4,-498 # 80022898 <devsw>
    80004a92:	97ba                	add	a5,a5,a4
    80004a94:	679c                	ld	a5,8(a5)
    80004a96:	cff9                	beqz	a5,80004b74 <filewrite+0x156>
    ret = devsw[f->major].write(1, addr, n);
    80004a98:	4505                	li	a0,1
    80004a9a:	9782                	jalr	a5
    80004a9c:	a841                	j	80004b2c <filewrite+0x10e>
    80004a9e:	00048a9b          	sext.w	s5,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004aa2:	00000097          	auipc	ra,0x0
    80004aa6:	8b0080e7          	jalr	-1872(ra) # 80004352 <begin_op>
      ilock(f->ip);
    80004aaa:	01893503          	ld	a0,24(s2)
    80004aae:	fffff097          	auipc	ra,0xfffff
    80004ab2:	eca080e7          	jalr	-310(ra) # 80003978 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004ab6:	8756                	mv	a4,s5
    80004ab8:	02092683          	lw	a3,32(s2)
    80004abc:	01698633          	add	a2,s3,s6
    80004ac0:	4585                	li	a1,1
    80004ac2:	01893503          	ld	a0,24(s2)
    80004ac6:	fffff097          	auipc	ra,0xfffff
    80004aca:	25e080e7          	jalr	606(ra) # 80003d24 <writei>
    80004ace:	84aa                	mv	s1,a0
    80004ad0:	02a05f63          	blez	a0,80004b0e <filewrite+0xf0>
        f->off += r;
    80004ad4:	02092783          	lw	a5,32(s2)
    80004ad8:	9fa9                	addw	a5,a5,a0
    80004ada:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004ade:	01893503          	ld	a0,24(s2)
    80004ae2:	fffff097          	auipc	ra,0xfffff
    80004ae6:	f58080e7          	jalr	-168(ra) # 80003a3a <iunlock>
      end_op();
    80004aea:	00000097          	auipc	ra,0x0
    80004aee:	8e6080e7          	jalr	-1818(ra) # 800043d0 <end_op>

      if(r < 0)
        break;
      if(r != n1)
    80004af2:	049a9963          	bne	s5,s1,80004b44 <filewrite+0x126>
        panic("short filewrite");
      i += r;
    80004af6:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004afa:	0349d663          	bge	s3,s4,80004b26 <filewrite+0x108>
      int n1 = n - i;
    80004afe:	413a04bb          	subw	s1,s4,s3
    80004b02:	0004879b          	sext.w	a5,s1
    80004b06:	f8fbdce3          	bge	s7,a5,80004a9e <filewrite+0x80>
    80004b0a:	84e2                	mv	s1,s8
    80004b0c:	bf49                	j	80004a9e <filewrite+0x80>
      iunlock(f->ip);
    80004b0e:	01893503          	ld	a0,24(s2)
    80004b12:	fffff097          	auipc	ra,0xfffff
    80004b16:	f28080e7          	jalr	-216(ra) # 80003a3a <iunlock>
      end_op();
    80004b1a:	00000097          	auipc	ra,0x0
    80004b1e:	8b6080e7          	jalr	-1866(ra) # 800043d0 <end_op>
      if(r < 0)
    80004b22:	fc04d8e3          	bgez	s1,80004af2 <filewrite+0xd4>
    }
    ret = (i == n ? n : -1);
    80004b26:	8552                	mv	a0,s4
    80004b28:	033a1863          	bne	s4,s3,80004b58 <filewrite+0x13a>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004b2c:	60a6                	ld	ra,72(sp)
    80004b2e:	6406                	ld	s0,64(sp)
    80004b30:	74e2                	ld	s1,56(sp)
    80004b32:	7942                	ld	s2,48(sp)
    80004b34:	79a2                	ld	s3,40(sp)
    80004b36:	7a02                	ld	s4,32(sp)
    80004b38:	6ae2                	ld	s5,24(sp)
    80004b3a:	6b42                	ld	s6,16(sp)
    80004b3c:	6ba2                	ld	s7,8(sp)
    80004b3e:	6c02                	ld	s8,0(sp)
    80004b40:	6161                	addi	sp,sp,80
    80004b42:	8082                	ret
        panic("short filewrite");
    80004b44:	00004517          	auipc	a0,0x4
    80004b48:	bd450513          	addi	a0,a0,-1068 # 80008718 <syscalls+0x260>
    80004b4c:	ffffc097          	auipc	ra,0xffffc
    80004b50:	a00080e7          	jalr	-1536(ra) # 8000054c <panic>
    int i = 0;
    80004b54:	4981                	li	s3,0
    80004b56:	bfc1                	j	80004b26 <filewrite+0x108>
    ret = (i == n ? n : -1);
    80004b58:	557d                	li	a0,-1
    80004b5a:	bfc9                	j	80004b2c <filewrite+0x10e>
    panic("filewrite");
    80004b5c:	00004517          	auipc	a0,0x4
    80004b60:	bcc50513          	addi	a0,a0,-1076 # 80008728 <syscalls+0x270>
    80004b64:	ffffc097          	auipc	ra,0xffffc
    80004b68:	9e8080e7          	jalr	-1560(ra) # 8000054c <panic>
    return -1;
    80004b6c:	557d                	li	a0,-1
}
    80004b6e:	8082                	ret
      return -1;
    80004b70:	557d                	li	a0,-1
    80004b72:	bf6d                	j	80004b2c <filewrite+0x10e>
    80004b74:	557d                	li	a0,-1
    80004b76:	bf5d                	j	80004b2c <filewrite+0x10e>

0000000080004b78 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004b78:	7179                	addi	sp,sp,-48
    80004b7a:	f406                	sd	ra,40(sp)
    80004b7c:	f022                	sd	s0,32(sp)
    80004b7e:	ec26                	sd	s1,24(sp)
    80004b80:	e84a                	sd	s2,16(sp)
    80004b82:	e44e                	sd	s3,8(sp)
    80004b84:	e052                	sd	s4,0(sp)
    80004b86:	1800                	addi	s0,sp,48
    80004b88:	84aa                	mv	s1,a0
    80004b8a:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004b8c:	0005b023          	sd	zero,0(a1)
    80004b90:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004b94:	00000097          	auipc	ra,0x0
    80004b98:	bd2080e7          	jalr	-1070(ra) # 80004766 <filealloc>
    80004b9c:	e088                	sd	a0,0(s1)
    80004b9e:	c551                	beqz	a0,80004c2a <pipealloc+0xb2>
    80004ba0:	00000097          	auipc	ra,0x0
    80004ba4:	bc6080e7          	jalr	-1082(ra) # 80004766 <filealloc>
    80004ba8:	00aa3023          	sd	a0,0(s4)
    80004bac:	c92d                	beqz	a0,80004c1e <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004bae:	ffffc097          	auipc	ra,0xffffc
    80004bb2:	fdc080e7          	jalr	-36(ra) # 80000b8a <kalloc>
    80004bb6:	892a                	mv	s2,a0
    80004bb8:	c125                	beqz	a0,80004c18 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004bba:	4985                	li	s3,1
    80004bbc:	23352423          	sw	s3,552(a0)
  pi->writeopen = 1;
    80004bc0:	23352623          	sw	s3,556(a0)
  pi->nwrite = 0;
    80004bc4:	22052223          	sw	zero,548(a0)
  pi->nread = 0;
    80004bc8:	22052023          	sw	zero,544(a0)
  initlock(&pi->lock, "pipe");
    80004bcc:	00004597          	auipc	a1,0x4
    80004bd0:	b6c58593          	addi	a1,a1,-1172 # 80008738 <syscalls+0x280>
    80004bd4:	ffffc097          	auipc	ra,0xffffc
    80004bd8:	2a8080e7          	jalr	680(ra) # 80000e7c <initlock>
  (*f0)->type = FD_PIPE;
    80004bdc:	609c                	ld	a5,0(s1)
    80004bde:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004be2:	609c                	ld	a5,0(s1)
    80004be4:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004be8:	609c                	ld	a5,0(s1)
    80004bea:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004bee:	609c                	ld	a5,0(s1)
    80004bf0:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004bf4:	000a3783          	ld	a5,0(s4)
    80004bf8:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004bfc:	000a3783          	ld	a5,0(s4)
    80004c00:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004c04:	000a3783          	ld	a5,0(s4)
    80004c08:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004c0c:	000a3783          	ld	a5,0(s4)
    80004c10:	0127b823          	sd	s2,16(a5)
  return 0;
    80004c14:	4501                	li	a0,0
    80004c16:	a025                	j	80004c3e <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004c18:	6088                	ld	a0,0(s1)
    80004c1a:	e501                	bnez	a0,80004c22 <pipealloc+0xaa>
    80004c1c:	a039                	j	80004c2a <pipealloc+0xb2>
    80004c1e:	6088                	ld	a0,0(s1)
    80004c20:	c51d                	beqz	a0,80004c4e <pipealloc+0xd6>
    fileclose(*f0);
    80004c22:	00000097          	auipc	ra,0x0
    80004c26:	c00080e7          	jalr	-1024(ra) # 80004822 <fileclose>
  if(*f1)
    80004c2a:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004c2e:	557d                	li	a0,-1
  if(*f1)
    80004c30:	c799                	beqz	a5,80004c3e <pipealloc+0xc6>
    fileclose(*f1);
    80004c32:	853e                	mv	a0,a5
    80004c34:	00000097          	auipc	ra,0x0
    80004c38:	bee080e7          	jalr	-1042(ra) # 80004822 <fileclose>
  return -1;
    80004c3c:	557d                	li	a0,-1
}
    80004c3e:	70a2                	ld	ra,40(sp)
    80004c40:	7402                	ld	s0,32(sp)
    80004c42:	64e2                	ld	s1,24(sp)
    80004c44:	6942                	ld	s2,16(sp)
    80004c46:	69a2                	ld	s3,8(sp)
    80004c48:	6a02                	ld	s4,0(sp)
    80004c4a:	6145                	addi	sp,sp,48
    80004c4c:	8082                	ret
  return -1;
    80004c4e:	557d                	li	a0,-1
    80004c50:	b7fd                	j	80004c3e <pipealloc+0xc6>

0000000080004c52 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004c52:	1101                	addi	sp,sp,-32
    80004c54:	ec06                	sd	ra,24(sp)
    80004c56:	e822                	sd	s0,16(sp)
    80004c58:	e426                	sd	s1,8(sp)
    80004c5a:	e04a                	sd	s2,0(sp)
    80004c5c:	1000                	addi	s0,sp,32
    80004c5e:	84aa                	mv	s1,a0
    80004c60:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004c62:	ffffc097          	auipc	ra,0xffffc
    80004c66:	09e080e7          	jalr	158(ra) # 80000d00 <acquire>
  if(writable){
    80004c6a:	04090263          	beqz	s2,80004cae <pipeclose+0x5c>
    pi->writeopen = 0;
    80004c6e:	2204a623          	sw	zero,556(s1)
    wakeup(&pi->nread);
    80004c72:	22048513          	addi	a0,s1,544
    80004c76:	ffffe097          	auipc	ra,0xffffe
    80004c7a:	a68080e7          	jalr	-1432(ra) # 800026de <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004c7e:	2284b783          	ld	a5,552(s1)
    80004c82:	ef9d                	bnez	a5,80004cc0 <pipeclose+0x6e>
    release(&pi->lock);
    80004c84:	8526                	mv	a0,s1
    80004c86:	ffffc097          	auipc	ra,0xffffc
    80004c8a:	14a080e7          	jalr	330(ra) # 80000dd0 <release>
#ifdef LAB_LOCK
    freelock(&pi->lock);
    80004c8e:	8526                	mv	a0,s1
    80004c90:	ffffc097          	auipc	ra,0xffffc
    80004c94:	188080e7          	jalr	392(ra) # 80000e18 <freelock>
#endif    
    kfree((char*)pi);
    80004c98:	8526                	mv	a0,s1
    80004c9a:	ffffc097          	auipc	ra,0xffffc
    80004c9e:	d7e080e7          	jalr	-642(ra) # 80000a18 <kfree>
  } else
    release(&pi->lock);
}
    80004ca2:	60e2                	ld	ra,24(sp)
    80004ca4:	6442                	ld	s0,16(sp)
    80004ca6:	64a2                	ld	s1,8(sp)
    80004ca8:	6902                	ld	s2,0(sp)
    80004caa:	6105                	addi	sp,sp,32
    80004cac:	8082                	ret
    pi->readopen = 0;
    80004cae:	2204a423          	sw	zero,552(s1)
    wakeup(&pi->nwrite);
    80004cb2:	22448513          	addi	a0,s1,548
    80004cb6:	ffffe097          	auipc	ra,0xffffe
    80004cba:	a28080e7          	jalr	-1496(ra) # 800026de <wakeup>
    80004cbe:	b7c1                	j	80004c7e <pipeclose+0x2c>
    release(&pi->lock);
    80004cc0:	8526                	mv	a0,s1
    80004cc2:	ffffc097          	auipc	ra,0xffffc
    80004cc6:	10e080e7          	jalr	270(ra) # 80000dd0 <release>
}
    80004cca:	bfe1                	j	80004ca2 <pipeclose+0x50>

0000000080004ccc <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004ccc:	711d                	addi	sp,sp,-96
    80004cce:	ec86                	sd	ra,88(sp)
    80004cd0:	e8a2                	sd	s0,80(sp)
    80004cd2:	e4a6                	sd	s1,72(sp)
    80004cd4:	e0ca                	sd	s2,64(sp)
    80004cd6:	fc4e                	sd	s3,56(sp)
    80004cd8:	f852                	sd	s4,48(sp)
    80004cda:	f456                	sd	s5,40(sp)
    80004cdc:	f05a                	sd	s6,32(sp)
    80004cde:	ec5e                	sd	s7,24(sp)
    80004ce0:	e862                	sd	s8,16(sp)
    80004ce2:	1080                	addi	s0,sp,96
    80004ce4:	84aa                	mv	s1,a0
    80004ce6:	8b2e                	mv	s6,a1
    80004ce8:	8ab2                	mv	s5,a2
  int i;
  char ch;
  struct proc *pr = myproc();
    80004cea:	ffffd097          	auipc	ra,0xffffd
    80004cee:	05c080e7          	jalr	92(ra) # 80001d46 <myproc>
    80004cf2:	892a                	mv	s2,a0

  acquire(&pi->lock);
    80004cf4:	8526                	mv	a0,s1
    80004cf6:	ffffc097          	auipc	ra,0xffffc
    80004cfa:	00a080e7          	jalr	10(ra) # 80000d00 <acquire>
  for(i = 0; i < n; i++){
    80004cfe:	09505863          	blez	s5,80004d8e <pipewrite+0xc2>
    80004d02:	4b81                	li	s7,0
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
      if(pi->readopen == 0 || pr->killed){
        release(&pi->lock);
        return -1;
      }
      wakeup(&pi->nread);
    80004d04:	22048a13          	addi	s4,s1,544
      sleep(&pi->nwrite, &pi->lock);
    80004d08:	22448993          	addi	s3,s1,548
    }
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004d0c:	5c7d                	li	s8,-1
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004d0e:	2204a783          	lw	a5,544(s1)
    80004d12:	2244a703          	lw	a4,548(s1)
    80004d16:	2007879b          	addiw	a5,a5,512
    80004d1a:	02f71b63          	bne	a4,a5,80004d50 <pipewrite+0x84>
      if(pi->readopen == 0 || pr->killed){
    80004d1e:	2284a783          	lw	a5,552(s1)
    80004d22:	c3d9                	beqz	a5,80004da8 <pipewrite+0xdc>
    80004d24:	03892783          	lw	a5,56(s2)
    80004d28:	e3c1                	bnez	a5,80004da8 <pipewrite+0xdc>
      wakeup(&pi->nread);
    80004d2a:	8552                	mv	a0,s4
    80004d2c:	ffffe097          	auipc	ra,0xffffe
    80004d30:	9b2080e7          	jalr	-1614(ra) # 800026de <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004d34:	85a6                	mv	a1,s1
    80004d36:	854e                	mv	a0,s3
    80004d38:	ffffe097          	auipc	ra,0xffffe
    80004d3c:	826080e7          	jalr	-2010(ra) # 8000255e <sleep>
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004d40:	2204a783          	lw	a5,544(s1)
    80004d44:	2244a703          	lw	a4,548(s1)
    80004d48:	2007879b          	addiw	a5,a5,512
    80004d4c:	fcf709e3          	beq	a4,a5,80004d1e <pipewrite+0x52>
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004d50:	4685                	li	a3,1
    80004d52:	865a                	mv	a2,s6
    80004d54:	faf40593          	addi	a1,s0,-81
    80004d58:	05893503          	ld	a0,88(s2)
    80004d5c:	ffffd097          	auipc	ra,0xffffd
    80004d60:	d6c080e7          	jalr	-660(ra) # 80001ac8 <copyin>
    80004d64:	03850663          	beq	a0,s8,80004d90 <pipewrite+0xc4>
      break;
    pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004d68:	2244a783          	lw	a5,548(s1)
    80004d6c:	0017871b          	addiw	a4,a5,1
    80004d70:	22e4a223          	sw	a4,548(s1)
    80004d74:	1ff7f793          	andi	a5,a5,511
    80004d78:	97a6                	add	a5,a5,s1
    80004d7a:	faf44703          	lbu	a4,-81(s0)
    80004d7e:	02e78023          	sb	a4,32(a5)
  for(i = 0; i < n; i++){
    80004d82:	2b85                	addiw	s7,s7,1
    80004d84:	0b05                	addi	s6,s6,1
    80004d86:	f97a94e3          	bne	s5,s7,80004d0e <pipewrite+0x42>
    80004d8a:	8bd6                	mv	s7,s5
    80004d8c:	a011                	j	80004d90 <pipewrite+0xc4>
    80004d8e:	4b81                	li	s7,0
  }
  wakeup(&pi->nread);
    80004d90:	22048513          	addi	a0,s1,544
    80004d94:	ffffe097          	auipc	ra,0xffffe
    80004d98:	94a080e7          	jalr	-1718(ra) # 800026de <wakeup>
  release(&pi->lock);
    80004d9c:	8526                	mv	a0,s1
    80004d9e:	ffffc097          	auipc	ra,0xffffc
    80004da2:	032080e7          	jalr	50(ra) # 80000dd0 <release>
  return i;
    80004da6:	a039                	j	80004db4 <pipewrite+0xe8>
        release(&pi->lock);
    80004da8:	8526                	mv	a0,s1
    80004daa:	ffffc097          	auipc	ra,0xffffc
    80004dae:	026080e7          	jalr	38(ra) # 80000dd0 <release>
        return -1;
    80004db2:	5bfd                	li	s7,-1
}
    80004db4:	855e                	mv	a0,s7
    80004db6:	60e6                	ld	ra,88(sp)
    80004db8:	6446                	ld	s0,80(sp)
    80004dba:	64a6                	ld	s1,72(sp)
    80004dbc:	6906                	ld	s2,64(sp)
    80004dbe:	79e2                	ld	s3,56(sp)
    80004dc0:	7a42                	ld	s4,48(sp)
    80004dc2:	7aa2                	ld	s5,40(sp)
    80004dc4:	7b02                	ld	s6,32(sp)
    80004dc6:	6be2                	ld	s7,24(sp)
    80004dc8:	6c42                	ld	s8,16(sp)
    80004dca:	6125                	addi	sp,sp,96
    80004dcc:	8082                	ret

0000000080004dce <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004dce:	715d                	addi	sp,sp,-80
    80004dd0:	e486                	sd	ra,72(sp)
    80004dd2:	e0a2                	sd	s0,64(sp)
    80004dd4:	fc26                	sd	s1,56(sp)
    80004dd6:	f84a                	sd	s2,48(sp)
    80004dd8:	f44e                	sd	s3,40(sp)
    80004dda:	f052                	sd	s4,32(sp)
    80004ddc:	ec56                	sd	s5,24(sp)
    80004dde:	e85a                	sd	s6,16(sp)
    80004de0:	0880                	addi	s0,sp,80
    80004de2:	84aa                	mv	s1,a0
    80004de4:	892e                	mv	s2,a1
    80004de6:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004de8:	ffffd097          	auipc	ra,0xffffd
    80004dec:	f5e080e7          	jalr	-162(ra) # 80001d46 <myproc>
    80004df0:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004df2:	8526                	mv	a0,s1
    80004df4:	ffffc097          	auipc	ra,0xffffc
    80004df8:	f0c080e7          	jalr	-244(ra) # 80000d00 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004dfc:	2204a703          	lw	a4,544(s1)
    80004e00:	2244a783          	lw	a5,548(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004e04:	22048993          	addi	s3,s1,544
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004e08:	02f71463          	bne	a4,a5,80004e30 <piperead+0x62>
    80004e0c:	22c4a783          	lw	a5,556(s1)
    80004e10:	c385                	beqz	a5,80004e30 <piperead+0x62>
    if(pr->killed){
    80004e12:	038a2783          	lw	a5,56(s4)
    80004e16:	ebc9                	bnez	a5,80004ea8 <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004e18:	85a6                	mv	a1,s1
    80004e1a:	854e                	mv	a0,s3
    80004e1c:	ffffd097          	auipc	ra,0xffffd
    80004e20:	742080e7          	jalr	1858(ra) # 8000255e <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004e24:	2204a703          	lw	a4,544(s1)
    80004e28:	2244a783          	lw	a5,548(s1)
    80004e2c:	fef700e3          	beq	a4,a5,80004e0c <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004e30:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004e32:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004e34:	05505463          	blez	s5,80004e7c <piperead+0xae>
    if(pi->nread == pi->nwrite)
    80004e38:	2204a783          	lw	a5,544(s1)
    80004e3c:	2244a703          	lw	a4,548(s1)
    80004e40:	02f70e63          	beq	a4,a5,80004e7c <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004e44:	0017871b          	addiw	a4,a5,1
    80004e48:	22e4a023          	sw	a4,544(s1)
    80004e4c:	1ff7f793          	andi	a5,a5,511
    80004e50:	97a6                	add	a5,a5,s1
    80004e52:	0207c783          	lbu	a5,32(a5)
    80004e56:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004e5a:	4685                	li	a3,1
    80004e5c:	fbf40613          	addi	a2,s0,-65
    80004e60:	85ca                	mv	a1,s2
    80004e62:	058a3503          	ld	a0,88(s4)
    80004e66:	ffffd097          	auipc	ra,0xffffd
    80004e6a:	bd6080e7          	jalr	-1066(ra) # 80001a3c <copyout>
    80004e6e:	01650763          	beq	a0,s6,80004e7c <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004e72:	2985                	addiw	s3,s3,1
    80004e74:	0905                	addi	s2,s2,1
    80004e76:	fd3a91e3          	bne	s5,s3,80004e38 <piperead+0x6a>
    80004e7a:	89d6                	mv	s3,s5
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004e7c:	22448513          	addi	a0,s1,548
    80004e80:	ffffe097          	auipc	ra,0xffffe
    80004e84:	85e080e7          	jalr	-1954(ra) # 800026de <wakeup>
  release(&pi->lock);
    80004e88:	8526                	mv	a0,s1
    80004e8a:	ffffc097          	auipc	ra,0xffffc
    80004e8e:	f46080e7          	jalr	-186(ra) # 80000dd0 <release>
  return i;
}
    80004e92:	854e                	mv	a0,s3
    80004e94:	60a6                	ld	ra,72(sp)
    80004e96:	6406                	ld	s0,64(sp)
    80004e98:	74e2                	ld	s1,56(sp)
    80004e9a:	7942                	ld	s2,48(sp)
    80004e9c:	79a2                	ld	s3,40(sp)
    80004e9e:	7a02                	ld	s4,32(sp)
    80004ea0:	6ae2                	ld	s5,24(sp)
    80004ea2:	6b42                	ld	s6,16(sp)
    80004ea4:	6161                	addi	sp,sp,80
    80004ea6:	8082                	ret
      release(&pi->lock);
    80004ea8:	8526                	mv	a0,s1
    80004eaa:	ffffc097          	auipc	ra,0xffffc
    80004eae:	f26080e7          	jalr	-218(ra) # 80000dd0 <release>
      return -1;
    80004eb2:	59fd                	li	s3,-1
    80004eb4:	bff9                	j	80004e92 <piperead+0xc4>

0000000080004eb6 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004eb6:	de010113          	addi	sp,sp,-544
    80004eba:	20113c23          	sd	ra,536(sp)
    80004ebe:	20813823          	sd	s0,528(sp)
    80004ec2:	20913423          	sd	s1,520(sp)
    80004ec6:	21213023          	sd	s2,512(sp)
    80004eca:	ffce                	sd	s3,504(sp)
    80004ecc:	fbd2                	sd	s4,496(sp)
    80004ece:	f7d6                	sd	s5,488(sp)
    80004ed0:	f3da                	sd	s6,480(sp)
    80004ed2:	efde                	sd	s7,472(sp)
    80004ed4:	ebe2                	sd	s8,464(sp)
    80004ed6:	e7e6                	sd	s9,456(sp)
    80004ed8:	e3ea                	sd	s10,448(sp)
    80004eda:	ff6e                	sd	s11,440(sp)
    80004edc:	1400                	addi	s0,sp,544
    80004ede:	892a                	mv	s2,a0
    80004ee0:	dea43423          	sd	a0,-536(s0)
    80004ee4:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004ee8:	ffffd097          	auipc	ra,0xffffd
    80004eec:	e5e080e7          	jalr	-418(ra) # 80001d46 <myproc>
    80004ef0:	84aa                	mv	s1,a0

  begin_op();
    80004ef2:	fffff097          	auipc	ra,0xfffff
    80004ef6:	460080e7          	jalr	1120(ra) # 80004352 <begin_op>

  if((ip = namei(path)) == 0){
    80004efa:	854a                	mv	a0,s2
    80004efc:	fffff097          	auipc	ra,0xfffff
    80004f00:	236080e7          	jalr	566(ra) # 80004132 <namei>
    80004f04:	c93d                	beqz	a0,80004f7a <exec+0xc4>
    80004f06:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004f08:	fffff097          	auipc	ra,0xfffff
    80004f0c:	a70080e7          	jalr	-1424(ra) # 80003978 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004f10:	04000713          	li	a4,64
    80004f14:	4681                	li	a3,0
    80004f16:	e4840613          	addi	a2,s0,-440
    80004f1a:	4581                	li	a1,0
    80004f1c:	8556                	mv	a0,s5
    80004f1e:	fffff097          	auipc	ra,0xfffff
    80004f22:	d0e080e7          	jalr	-754(ra) # 80003c2c <readi>
    80004f26:	04000793          	li	a5,64
    80004f2a:	00f51a63          	bne	a0,a5,80004f3e <exec+0x88>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004f2e:	e4842703          	lw	a4,-440(s0)
    80004f32:	464c47b7          	lui	a5,0x464c4
    80004f36:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004f3a:	04f70663          	beq	a4,a5,80004f86 <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004f3e:	8556                	mv	a0,s5
    80004f40:	fffff097          	auipc	ra,0xfffff
    80004f44:	c9a080e7          	jalr	-870(ra) # 80003bda <iunlockput>
    end_op();
    80004f48:	fffff097          	auipc	ra,0xfffff
    80004f4c:	488080e7          	jalr	1160(ra) # 800043d0 <end_op>
  }
  return -1;
    80004f50:	557d                	li	a0,-1
}
    80004f52:	21813083          	ld	ra,536(sp)
    80004f56:	21013403          	ld	s0,528(sp)
    80004f5a:	20813483          	ld	s1,520(sp)
    80004f5e:	20013903          	ld	s2,512(sp)
    80004f62:	79fe                	ld	s3,504(sp)
    80004f64:	7a5e                	ld	s4,496(sp)
    80004f66:	7abe                	ld	s5,488(sp)
    80004f68:	7b1e                	ld	s6,480(sp)
    80004f6a:	6bfe                	ld	s7,472(sp)
    80004f6c:	6c5e                	ld	s8,464(sp)
    80004f6e:	6cbe                	ld	s9,456(sp)
    80004f70:	6d1e                	ld	s10,448(sp)
    80004f72:	7dfa                	ld	s11,440(sp)
    80004f74:	22010113          	addi	sp,sp,544
    80004f78:	8082                	ret
    end_op();
    80004f7a:	fffff097          	auipc	ra,0xfffff
    80004f7e:	456080e7          	jalr	1110(ra) # 800043d0 <end_op>
    return -1;
    80004f82:	557d                	li	a0,-1
    80004f84:	b7f9                	j	80004f52 <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    80004f86:	8526                	mv	a0,s1
    80004f88:	ffffd097          	auipc	ra,0xffffd
    80004f8c:	e82080e7          	jalr	-382(ra) # 80001e0a <proc_pagetable>
    80004f90:	8b2a                	mv	s6,a0
    80004f92:	d555                	beqz	a0,80004f3e <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004f94:	e6842783          	lw	a5,-408(s0)
    80004f98:	e8045703          	lhu	a4,-384(s0)
    80004f9c:	c735                	beqz	a4,80005008 <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004f9e:	4481                	li	s1,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004fa0:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    80004fa4:	6a05                	lui	s4,0x1
    80004fa6:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    80004faa:	dee43023          	sd	a4,-544(s0)
  uint64 pa;

  if((va % PGSIZE) != 0)
    panic("loadseg: va must be page aligned");

  for(i = 0; i < sz; i += PGSIZE){
    80004fae:	6d85                	lui	s11,0x1
    80004fb0:	7d7d                	lui	s10,0xfffff
    80004fb2:	ac1d                	j	800051e8 <exec+0x332>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004fb4:	00003517          	auipc	a0,0x3
    80004fb8:	78c50513          	addi	a0,a0,1932 # 80008740 <syscalls+0x288>
    80004fbc:	ffffb097          	auipc	ra,0xffffb
    80004fc0:	590080e7          	jalr	1424(ra) # 8000054c <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004fc4:	874a                	mv	a4,s2
    80004fc6:	009c86bb          	addw	a3,s9,s1
    80004fca:	4581                	li	a1,0
    80004fcc:	8556                	mv	a0,s5
    80004fce:	fffff097          	auipc	ra,0xfffff
    80004fd2:	c5e080e7          	jalr	-930(ra) # 80003c2c <readi>
    80004fd6:	2501                	sext.w	a0,a0
    80004fd8:	1aa91863          	bne	s2,a0,80005188 <exec+0x2d2>
  for(i = 0; i < sz; i += PGSIZE){
    80004fdc:	009d84bb          	addw	s1,s11,s1
    80004fe0:	013d09bb          	addw	s3,s10,s3
    80004fe4:	1f74f263          	bgeu	s1,s7,800051c8 <exec+0x312>
    pa = walkaddr(pagetable, va + i);
    80004fe8:	02049593          	slli	a1,s1,0x20
    80004fec:	9181                	srli	a1,a1,0x20
    80004fee:	95e2                	add	a1,a1,s8
    80004ff0:	855a                	mv	a0,s6
    80004ff2:	ffffc097          	auipc	ra,0xffffc
    80004ff6:	484080e7          	jalr	1156(ra) # 80001476 <walkaddr>
    80004ffa:	862a                	mv	a2,a0
    if(pa == 0)
    80004ffc:	dd45                	beqz	a0,80004fb4 <exec+0xfe>
      n = PGSIZE;
    80004ffe:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    80005000:	fd49f2e3          	bgeu	s3,s4,80004fc4 <exec+0x10e>
      n = sz - i;
    80005004:	894e                	mv	s2,s3
    80005006:	bf7d                	j	80004fc4 <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80005008:	4481                	li	s1,0
  iunlockput(ip);
    8000500a:	8556                	mv	a0,s5
    8000500c:	fffff097          	auipc	ra,0xfffff
    80005010:	bce080e7          	jalr	-1074(ra) # 80003bda <iunlockput>
  end_op();
    80005014:	fffff097          	auipc	ra,0xfffff
    80005018:	3bc080e7          	jalr	956(ra) # 800043d0 <end_op>
  p = myproc();
    8000501c:	ffffd097          	auipc	ra,0xffffd
    80005020:	d2a080e7          	jalr	-726(ra) # 80001d46 <myproc>
    80005024:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    80005026:	05053d03          	ld	s10,80(a0)
  sz = PGROUNDUP(sz);
    8000502a:	6785                	lui	a5,0x1
    8000502c:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    8000502e:	97a6                	add	a5,a5,s1
    80005030:	777d                	lui	a4,0xfffff
    80005032:	8ff9                	and	a5,a5,a4
    80005034:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80005038:	6609                	lui	a2,0x2
    8000503a:	963e                	add	a2,a2,a5
    8000503c:	85be                	mv	a1,a5
    8000503e:	855a                	mv	a0,s6
    80005040:	ffffc097          	auipc	ra,0xffffc
    80005044:	7a8080e7          	jalr	1960(ra) # 800017e8 <uvmalloc>
    80005048:	8c2a                	mv	s8,a0
  ip = 0;
    8000504a:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    8000504c:	12050e63          	beqz	a0,80005188 <exec+0x2d2>
  uvmclear(pagetable, sz-2*PGSIZE);
    80005050:	75f9                	lui	a1,0xffffe
    80005052:	95aa                	add	a1,a1,a0
    80005054:	855a                	mv	a0,s6
    80005056:	ffffd097          	auipc	ra,0xffffd
    8000505a:	9b4080e7          	jalr	-1612(ra) # 80001a0a <uvmclear>
  stackbase = sp - PGSIZE;
    8000505e:	7afd                	lui	s5,0xfffff
    80005060:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    80005062:	df043783          	ld	a5,-528(s0)
    80005066:	6388                	ld	a0,0(a5)
    80005068:	c925                	beqz	a0,800050d8 <exec+0x222>
    8000506a:	e8840993          	addi	s3,s0,-376
    8000506e:	f8840c93          	addi	s9,s0,-120
  sp = sz;
    80005072:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80005074:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80005076:	ffffc097          	auipc	ra,0xffffc
    8000507a:	1ee080e7          	jalr	494(ra) # 80001264 <strlen>
    8000507e:	0015079b          	addiw	a5,a0,1
    80005082:	40f907b3          	sub	a5,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80005086:	ff07f913          	andi	s2,a5,-16
    if(sp < stackbase)
    8000508a:	13596363          	bltu	s2,s5,800051b0 <exec+0x2fa>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    8000508e:	df043d83          	ld	s11,-528(s0)
    80005092:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    80005096:	8552                	mv	a0,s4
    80005098:	ffffc097          	auipc	ra,0xffffc
    8000509c:	1cc080e7          	jalr	460(ra) # 80001264 <strlen>
    800050a0:	0015069b          	addiw	a3,a0,1
    800050a4:	8652                	mv	a2,s4
    800050a6:	85ca                	mv	a1,s2
    800050a8:	855a                	mv	a0,s6
    800050aa:	ffffd097          	auipc	ra,0xffffd
    800050ae:	992080e7          	jalr	-1646(ra) # 80001a3c <copyout>
    800050b2:	10054363          	bltz	a0,800051b8 <exec+0x302>
    ustack[argc] = sp;
    800050b6:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    800050ba:	0485                	addi	s1,s1,1
    800050bc:	008d8793          	addi	a5,s11,8
    800050c0:	def43823          	sd	a5,-528(s0)
    800050c4:	008db503          	ld	a0,8(s11)
    800050c8:	c911                	beqz	a0,800050dc <exec+0x226>
    if(argc >= MAXARG)
    800050ca:	09a1                	addi	s3,s3,8
    800050cc:	fb3c95e3          	bne	s9,s3,80005076 <exec+0x1c0>
  sz = sz1;
    800050d0:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800050d4:	4a81                	li	s5,0
    800050d6:	a84d                	j	80005188 <exec+0x2d2>
  sp = sz;
    800050d8:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    800050da:	4481                	li	s1,0
  ustack[argc] = 0;
    800050dc:	00349793          	slli	a5,s1,0x3
    800050e0:	f9078793          	addi	a5,a5,-112
    800050e4:	97a2                	add	a5,a5,s0
    800050e6:	ee07bc23          	sd	zero,-264(a5)
  sp -= (argc+1) * sizeof(uint64);
    800050ea:	00148693          	addi	a3,s1,1
    800050ee:	068e                	slli	a3,a3,0x3
    800050f0:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    800050f4:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    800050f8:	01597663          	bgeu	s2,s5,80005104 <exec+0x24e>
  sz = sz1;
    800050fc:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005100:	4a81                	li	s5,0
    80005102:	a059                	j	80005188 <exec+0x2d2>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80005104:	e8840613          	addi	a2,s0,-376
    80005108:	85ca                	mv	a1,s2
    8000510a:	855a                	mv	a0,s6
    8000510c:	ffffd097          	auipc	ra,0xffffd
    80005110:	930080e7          	jalr	-1744(ra) # 80001a3c <copyout>
    80005114:	0a054663          	bltz	a0,800051c0 <exec+0x30a>
  p->trapframe->a1 = sp;
    80005118:	060bb783          	ld	a5,96(s7)
    8000511c:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80005120:	de843783          	ld	a5,-536(s0)
    80005124:	0007c703          	lbu	a4,0(a5)
    80005128:	cf11                	beqz	a4,80005144 <exec+0x28e>
    8000512a:	0785                	addi	a5,a5,1
    if(*s == '/')
    8000512c:	02f00693          	li	a3,47
    80005130:	a039                	j	8000513e <exec+0x288>
      last = s+1;
    80005132:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    80005136:	0785                	addi	a5,a5,1
    80005138:	fff7c703          	lbu	a4,-1(a5)
    8000513c:	c701                	beqz	a4,80005144 <exec+0x28e>
    if(*s == '/')
    8000513e:	fed71ce3          	bne	a4,a3,80005136 <exec+0x280>
    80005142:	bfc5                	j	80005132 <exec+0x27c>
  safestrcpy(p->name, last, sizeof(p->name));
    80005144:	4641                	li	a2,16
    80005146:	de843583          	ld	a1,-536(s0)
    8000514a:	160b8513          	addi	a0,s7,352
    8000514e:	ffffc097          	auipc	ra,0xffffc
    80005152:	0e4080e7          	jalr	228(ra) # 80001232 <safestrcpy>
  oldpagetable = p->pagetable;
    80005156:	058bb503          	ld	a0,88(s7)
  p->pagetable = pagetable;
    8000515a:	056bbc23          	sd	s6,88(s7)
  p->sz = sz;
    8000515e:	058bb823          	sd	s8,80(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80005162:	060bb783          	ld	a5,96(s7)
    80005166:	e6043703          	ld	a4,-416(s0)
    8000516a:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    8000516c:	060bb783          	ld	a5,96(s7)
    80005170:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80005174:	85ea                	mv	a1,s10
    80005176:	ffffd097          	auipc	ra,0xffffd
    8000517a:	d30080e7          	jalr	-720(ra) # 80001ea6 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    8000517e:	0004851b          	sext.w	a0,s1
    80005182:	bbc1                	j	80004f52 <exec+0x9c>
    80005184:	de943c23          	sd	s1,-520(s0)
    proc_freepagetable(pagetable, sz);
    80005188:	df843583          	ld	a1,-520(s0)
    8000518c:	855a                	mv	a0,s6
    8000518e:	ffffd097          	auipc	ra,0xffffd
    80005192:	d18080e7          	jalr	-744(ra) # 80001ea6 <proc_freepagetable>
  if(ip){
    80005196:	da0a94e3          	bnez	s5,80004f3e <exec+0x88>
  return -1;
    8000519a:	557d                	li	a0,-1
    8000519c:	bb5d                	j	80004f52 <exec+0x9c>
    8000519e:	de943c23          	sd	s1,-520(s0)
    800051a2:	b7dd                	j	80005188 <exec+0x2d2>
    800051a4:	de943c23          	sd	s1,-520(s0)
    800051a8:	b7c5                	j	80005188 <exec+0x2d2>
    800051aa:	de943c23          	sd	s1,-520(s0)
    800051ae:	bfe9                	j	80005188 <exec+0x2d2>
  sz = sz1;
    800051b0:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800051b4:	4a81                	li	s5,0
    800051b6:	bfc9                	j	80005188 <exec+0x2d2>
  sz = sz1;
    800051b8:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800051bc:	4a81                	li	s5,0
    800051be:	b7e9                	j	80005188 <exec+0x2d2>
  sz = sz1;
    800051c0:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800051c4:	4a81                	li	s5,0
    800051c6:	b7c9                	j	80005188 <exec+0x2d2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    800051c8:	df843483          	ld	s1,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800051cc:	e0843783          	ld	a5,-504(s0)
    800051d0:	0017869b          	addiw	a3,a5,1
    800051d4:	e0d43423          	sd	a3,-504(s0)
    800051d8:	e0043783          	ld	a5,-512(s0)
    800051dc:	0387879b          	addiw	a5,a5,56
    800051e0:	e8045703          	lhu	a4,-384(s0)
    800051e4:	e2e6d3e3          	bge	a3,a4,8000500a <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    800051e8:	2781                	sext.w	a5,a5
    800051ea:	e0f43023          	sd	a5,-512(s0)
    800051ee:	03800713          	li	a4,56
    800051f2:	86be                	mv	a3,a5
    800051f4:	e1040613          	addi	a2,s0,-496
    800051f8:	4581                	li	a1,0
    800051fa:	8556                	mv	a0,s5
    800051fc:	fffff097          	auipc	ra,0xfffff
    80005200:	a30080e7          	jalr	-1488(ra) # 80003c2c <readi>
    80005204:	03800793          	li	a5,56
    80005208:	f6f51ee3          	bne	a0,a5,80005184 <exec+0x2ce>
    if(ph.type != ELF_PROG_LOAD)
    8000520c:	e1042783          	lw	a5,-496(s0)
    80005210:	4705                	li	a4,1
    80005212:	fae79de3          	bne	a5,a4,800051cc <exec+0x316>
    if(ph.memsz < ph.filesz)
    80005216:	e3843603          	ld	a2,-456(s0)
    8000521a:	e3043783          	ld	a5,-464(s0)
    8000521e:	f8f660e3          	bltu	a2,a5,8000519e <exec+0x2e8>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005222:	e2043783          	ld	a5,-480(s0)
    80005226:	963e                	add	a2,a2,a5
    80005228:	f6f66ee3          	bltu	a2,a5,800051a4 <exec+0x2ee>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    8000522c:	85a6                	mv	a1,s1
    8000522e:	855a                	mv	a0,s6
    80005230:	ffffc097          	auipc	ra,0xffffc
    80005234:	5b8080e7          	jalr	1464(ra) # 800017e8 <uvmalloc>
    80005238:	dea43c23          	sd	a0,-520(s0)
    8000523c:	d53d                	beqz	a0,800051aa <exec+0x2f4>
    if(ph.vaddr % PGSIZE != 0)
    8000523e:	e2043c03          	ld	s8,-480(s0)
    80005242:	de043783          	ld	a5,-544(s0)
    80005246:	00fc77b3          	and	a5,s8,a5
    8000524a:	ff9d                	bnez	a5,80005188 <exec+0x2d2>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    8000524c:	e1842c83          	lw	s9,-488(s0)
    80005250:	e3042b83          	lw	s7,-464(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005254:	f60b8ae3          	beqz	s7,800051c8 <exec+0x312>
    80005258:	89de                	mv	s3,s7
    8000525a:	4481                	li	s1,0
    8000525c:	b371                	j	80004fe8 <exec+0x132>

000000008000525e <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    8000525e:	7179                	addi	sp,sp,-48
    80005260:	f406                	sd	ra,40(sp)
    80005262:	f022                	sd	s0,32(sp)
    80005264:	ec26                	sd	s1,24(sp)
    80005266:	e84a                	sd	s2,16(sp)
    80005268:	1800                	addi	s0,sp,48
    8000526a:	892e                	mv	s2,a1
    8000526c:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    8000526e:	fdc40593          	addi	a1,s0,-36
    80005272:	ffffe097          	auipc	ra,0xffffe
    80005276:	b94080e7          	jalr	-1132(ra) # 80002e06 <argint>
    8000527a:	04054063          	bltz	a0,800052ba <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    8000527e:	fdc42703          	lw	a4,-36(s0)
    80005282:	47bd                	li	a5,15
    80005284:	02e7ed63          	bltu	a5,a4,800052be <argfd+0x60>
    80005288:	ffffd097          	auipc	ra,0xffffd
    8000528c:	abe080e7          	jalr	-1346(ra) # 80001d46 <myproc>
    80005290:	fdc42703          	lw	a4,-36(s0)
    80005294:	01a70793          	addi	a5,a4,26 # fffffffffffff01a <end+0xffffffff7ffd6ff2>
    80005298:	078e                	slli	a5,a5,0x3
    8000529a:	953e                	add	a0,a0,a5
    8000529c:	651c                	ld	a5,8(a0)
    8000529e:	c395                	beqz	a5,800052c2 <argfd+0x64>
    return -1;
  if(pfd)
    800052a0:	00090463          	beqz	s2,800052a8 <argfd+0x4a>
    *pfd = fd;
    800052a4:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    800052a8:	4501                	li	a0,0
  if(pf)
    800052aa:	c091                	beqz	s1,800052ae <argfd+0x50>
    *pf = f;
    800052ac:	e09c                	sd	a5,0(s1)
}
    800052ae:	70a2                	ld	ra,40(sp)
    800052b0:	7402                	ld	s0,32(sp)
    800052b2:	64e2                	ld	s1,24(sp)
    800052b4:	6942                	ld	s2,16(sp)
    800052b6:	6145                	addi	sp,sp,48
    800052b8:	8082                	ret
    return -1;
    800052ba:	557d                	li	a0,-1
    800052bc:	bfcd                	j	800052ae <argfd+0x50>
    return -1;
    800052be:	557d                	li	a0,-1
    800052c0:	b7fd                	j	800052ae <argfd+0x50>
    800052c2:	557d                	li	a0,-1
    800052c4:	b7ed                	j	800052ae <argfd+0x50>

00000000800052c6 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    800052c6:	1101                	addi	sp,sp,-32
    800052c8:	ec06                	sd	ra,24(sp)
    800052ca:	e822                	sd	s0,16(sp)
    800052cc:	e426                	sd	s1,8(sp)
    800052ce:	1000                	addi	s0,sp,32
    800052d0:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    800052d2:	ffffd097          	auipc	ra,0xffffd
    800052d6:	a74080e7          	jalr	-1420(ra) # 80001d46 <myproc>
    800052da:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    800052dc:	0d850793          	addi	a5,a0,216
    800052e0:	4501                	li	a0,0
    800052e2:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    800052e4:	6398                	ld	a4,0(a5)
    800052e6:	cb19                	beqz	a4,800052fc <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    800052e8:	2505                	addiw	a0,a0,1
    800052ea:	07a1                	addi	a5,a5,8
    800052ec:	fed51ce3          	bne	a0,a3,800052e4 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    800052f0:	557d                	li	a0,-1
}
    800052f2:	60e2                	ld	ra,24(sp)
    800052f4:	6442                	ld	s0,16(sp)
    800052f6:	64a2                	ld	s1,8(sp)
    800052f8:	6105                	addi	sp,sp,32
    800052fa:	8082                	ret
      p->ofile[fd] = f;
    800052fc:	01a50793          	addi	a5,a0,26
    80005300:	078e                	slli	a5,a5,0x3
    80005302:	963e                	add	a2,a2,a5
    80005304:	e604                	sd	s1,8(a2)
      return fd;
    80005306:	b7f5                	j	800052f2 <fdalloc+0x2c>

0000000080005308 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005308:	715d                	addi	sp,sp,-80
    8000530a:	e486                	sd	ra,72(sp)
    8000530c:	e0a2                	sd	s0,64(sp)
    8000530e:	fc26                	sd	s1,56(sp)
    80005310:	f84a                	sd	s2,48(sp)
    80005312:	f44e                	sd	s3,40(sp)
    80005314:	f052                	sd	s4,32(sp)
    80005316:	ec56                	sd	s5,24(sp)
    80005318:	0880                	addi	s0,sp,80
    8000531a:	89ae                	mv	s3,a1
    8000531c:	8ab2                	mv	s5,a2
    8000531e:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005320:	fb040593          	addi	a1,s0,-80
    80005324:	fffff097          	auipc	ra,0xfffff
    80005328:	e2c080e7          	jalr	-468(ra) # 80004150 <nameiparent>
    8000532c:	892a                	mv	s2,a0
    8000532e:	12050e63          	beqz	a0,8000546a <create+0x162>
    return 0;

  ilock(dp);
    80005332:	ffffe097          	auipc	ra,0xffffe
    80005336:	646080e7          	jalr	1606(ra) # 80003978 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    8000533a:	4601                	li	a2,0
    8000533c:	fb040593          	addi	a1,s0,-80
    80005340:	854a                	mv	a0,s2
    80005342:	fffff097          	auipc	ra,0xfffff
    80005346:	b18080e7          	jalr	-1256(ra) # 80003e5a <dirlookup>
    8000534a:	84aa                	mv	s1,a0
    8000534c:	c921                	beqz	a0,8000539c <create+0x94>
    iunlockput(dp);
    8000534e:	854a                	mv	a0,s2
    80005350:	fffff097          	auipc	ra,0xfffff
    80005354:	88a080e7          	jalr	-1910(ra) # 80003bda <iunlockput>
    ilock(ip);
    80005358:	8526                	mv	a0,s1
    8000535a:	ffffe097          	auipc	ra,0xffffe
    8000535e:	61e080e7          	jalr	1566(ra) # 80003978 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005362:	2981                	sext.w	s3,s3
    80005364:	4789                	li	a5,2
    80005366:	02f99463          	bne	s3,a5,8000538e <create+0x86>
    8000536a:	04c4d783          	lhu	a5,76(s1)
    8000536e:	37f9                	addiw	a5,a5,-2
    80005370:	17c2                	slli	a5,a5,0x30
    80005372:	93c1                	srli	a5,a5,0x30
    80005374:	4705                	li	a4,1
    80005376:	00f76c63          	bltu	a4,a5,8000538e <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    8000537a:	8526                	mv	a0,s1
    8000537c:	60a6                	ld	ra,72(sp)
    8000537e:	6406                	ld	s0,64(sp)
    80005380:	74e2                	ld	s1,56(sp)
    80005382:	7942                	ld	s2,48(sp)
    80005384:	79a2                	ld	s3,40(sp)
    80005386:	7a02                	ld	s4,32(sp)
    80005388:	6ae2                	ld	s5,24(sp)
    8000538a:	6161                	addi	sp,sp,80
    8000538c:	8082                	ret
    iunlockput(ip);
    8000538e:	8526                	mv	a0,s1
    80005390:	fffff097          	auipc	ra,0xfffff
    80005394:	84a080e7          	jalr	-1974(ra) # 80003bda <iunlockput>
    return 0;
    80005398:	4481                	li	s1,0
    8000539a:	b7c5                	j	8000537a <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    8000539c:	85ce                	mv	a1,s3
    8000539e:	00092503          	lw	a0,0(s2)
    800053a2:	ffffe097          	auipc	ra,0xffffe
    800053a6:	43c080e7          	jalr	1084(ra) # 800037de <ialloc>
    800053aa:	84aa                	mv	s1,a0
    800053ac:	c521                	beqz	a0,800053f4 <create+0xec>
  ilock(ip);
    800053ae:	ffffe097          	auipc	ra,0xffffe
    800053b2:	5ca080e7          	jalr	1482(ra) # 80003978 <ilock>
  ip->major = major;
    800053b6:	05549723          	sh	s5,78(s1)
  ip->minor = minor;
    800053ba:	05449823          	sh	s4,80(s1)
  ip->nlink = 1;
    800053be:	4a05                	li	s4,1
    800053c0:	05449923          	sh	s4,82(s1)
  iupdate(ip);
    800053c4:	8526                	mv	a0,s1
    800053c6:	ffffe097          	auipc	ra,0xffffe
    800053ca:	4e6080e7          	jalr	1254(ra) # 800038ac <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800053ce:	2981                	sext.w	s3,s3
    800053d0:	03498a63          	beq	s3,s4,80005404 <create+0xfc>
  if(dirlink(dp, name, ip->inum) < 0)
    800053d4:	40d0                	lw	a2,4(s1)
    800053d6:	fb040593          	addi	a1,s0,-80
    800053da:	854a                	mv	a0,s2
    800053dc:	fffff097          	auipc	ra,0xfffff
    800053e0:	c94080e7          	jalr	-876(ra) # 80004070 <dirlink>
    800053e4:	06054b63          	bltz	a0,8000545a <create+0x152>
  iunlockput(dp);
    800053e8:	854a                	mv	a0,s2
    800053ea:	ffffe097          	auipc	ra,0xffffe
    800053ee:	7f0080e7          	jalr	2032(ra) # 80003bda <iunlockput>
  return ip;
    800053f2:	b761                	j	8000537a <create+0x72>
    panic("create: ialloc");
    800053f4:	00003517          	auipc	a0,0x3
    800053f8:	36c50513          	addi	a0,a0,876 # 80008760 <syscalls+0x2a8>
    800053fc:	ffffb097          	auipc	ra,0xffffb
    80005400:	150080e7          	jalr	336(ra) # 8000054c <panic>
    dp->nlink++;  // for ".."
    80005404:	05295783          	lhu	a5,82(s2)
    80005408:	2785                	addiw	a5,a5,1
    8000540a:	04f91923          	sh	a5,82(s2)
    iupdate(dp);
    8000540e:	854a                	mv	a0,s2
    80005410:	ffffe097          	auipc	ra,0xffffe
    80005414:	49c080e7          	jalr	1180(ra) # 800038ac <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005418:	40d0                	lw	a2,4(s1)
    8000541a:	00003597          	auipc	a1,0x3
    8000541e:	35658593          	addi	a1,a1,854 # 80008770 <syscalls+0x2b8>
    80005422:	8526                	mv	a0,s1
    80005424:	fffff097          	auipc	ra,0xfffff
    80005428:	c4c080e7          	jalr	-948(ra) # 80004070 <dirlink>
    8000542c:	00054f63          	bltz	a0,8000544a <create+0x142>
    80005430:	00492603          	lw	a2,4(s2)
    80005434:	00003597          	auipc	a1,0x3
    80005438:	34458593          	addi	a1,a1,836 # 80008778 <syscalls+0x2c0>
    8000543c:	8526                	mv	a0,s1
    8000543e:	fffff097          	auipc	ra,0xfffff
    80005442:	c32080e7          	jalr	-974(ra) # 80004070 <dirlink>
    80005446:	f80557e3          	bgez	a0,800053d4 <create+0xcc>
      panic("create dots");
    8000544a:	00003517          	auipc	a0,0x3
    8000544e:	33650513          	addi	a0,a0,822 # 80008780 <syscalls+0x2c8>
    80005452:	ffffb097          	auipc	ra,0xffffb
    80005456:	0fa080e7          	jalr	250(ra) # 8000054c <panic>
    panic("create: dirlink");
    8000545a:	00003517          	auipc	a0,0x3
    8000545e:	33650513          	addi	a0,a0,822 # 80008790 <syscalls+0x2d8>
    80005462:	ffffb097          	auipc	ra,0xffffb
    80005466:	0ea080e7          	jalr	234(ra) # 8000054c <panic>
    return 0;
    8000546a:	84aa                	mv	s1,a0
    8000546c:	b739                	j	8000537a <create+0x72>

000000008000546e <sys_dup>:
{
    8000546e:	7179                	addi	sp,sp,-48
    80005470:	f406                	sd	ra,40(sp)
    80005472:	f022                	sd	s0,32(sp)
    80005474:	ec26                	sd	s1,24(sp)
    80005476:	e84a                	sd	s2,16(sp)
    80005478:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    8000547a:	fd840613          	addi	a2,s0,-40
    8000547e:	4581                	li	a1,0
    80005480:	4501                	li	a0,0
    80005482:	00000097          	auipc	ra,0x0
    80005486:	ddc080e7          	jalr	-548(ra) # 8000525e <argfd>
    return -1;
    8000548a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    8000548c:	02054363          	bltz	a0,800054b2 <sys_dup+0x44>
  if((fd=fdalloc(f)) < 0)
    80005490:	fd843903          	ld	s2,-40(s0)
    80005494:	854a                	mv	a0,s2
    80005496:	00000097          	auipc	ra,0x0
    8000549a:	e30080e7          	jalr	-464(ra) # 800052c6 <fdalloc>
    8000549e:	84aa                	mv	s1,a0
    return -1;
    800054a0:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800054a2:	00054863          	bltz	a0,800054b2 <sys_dup+0x44>
  filedup(f);
    800054a6:	854a                	mv	a0,s2
    800054a8:	fffff097          	auipc	ra,0xfffff
    800054ac:	328080e7          	jalr	808(ra) # 800047d0 <filedup>
  return fd;
    800054b0:	87a6                	mv	a5,s1
}
    800054b2:	853e                	mv	a0,a5
    800054b4:	70a2                	ld	ra,40(sp)
    800054b6:	7402                	ld	s0,32(sp)
    800054b8:	64e2                	ld	s1,24(sp)
    800054ba:	6942                	ld	s2,16(sp)
    800054bc:	6145                	addi	sp,sp,48
    800054be:	8082                	ret

00000000800054c0 <sys_read>:
{
    800054c0:	7179                	addi	sp,sp,-48
    800054c2:	f406                	sd	ra,40(sp)
    800054c4:	f022                	sd	s0,32(sp)
    800054c6:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800054c8:	fe840613          	addi	a2,s0,-24
    800054cc:	4581                	li	a1,0
    800054ce:	4501                	li	a0,0
    800054d0:	00000097          	auipc	ra,0x0
    800054d4:	d8e080e7          	jalr	-626(ra) # 8000525e <argfd>
    return -1;
    800054d8:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800054da:	04054163          	bltz	a0,8000551c <sys_read+0x5c>
    800054de:	fe440593          	addi	a1,s0,-28
    800054e2:	4509                	li	a0,2
    800054e4:	ffffe097          	auipc	ra,0xffffe
    800054e8:	922080e7          	jalr	-1758(ra) # 80002e06 <argint>
    return -1;
    800054ec:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800054ee:	02054763          	bltz	a0,8000551c <sys_read+0x5c>
    800054f2:	fd840593          	addi	a1,s0,-40
    800054f6:	4505                	li	a0,1
    800054f8:	ffffe097          	auipc	ra,0xffffe
    800054fc:	930080e7          	jalr	-1744(ra) # 80002e28 <argaddr>
    return -1;
    80005500:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005502:	00054d63          	bltz	a0,8000551c <sys_read+0x5c>
  return fileread(f, p, n);
    80005506:	fe442603          	lw	a2,-28(s0)
    8000550a:	fd843583          	ld	a1,-40(s0)
    8000550e:	fe843503          	ld	a0,-24(s0)
    80005512:	fffff097          	auipc	ra,0xfffff
    80005516:	44a080e7          	jalr	1098(ra) # 8000495c <fileread>
    8000551a:	87aa                	mv	a5,a0
}
    8000551c:	853e                	mv	a0,a5
    8000551e:	70a2                	ld	ra,40(sp)
    80005520:	7402                	ld	s0,32(sp)
    80005522:	6145                	addi	sp,sp,48
    80005524:	8082                	ret

0000000080005526 <sys_write>:
{
    80005526:	7179                	addi	sp,sp,-48
    80005528:	f406                	sd	ra,40(sp)
    8000552a:	f022                	sd	s0,32(sp)
    8000552c:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000552e:	fe840613          	addi	a2,s0,-24
    80005532:	4581                	li	a1,0
    80005534:	4501                	li	a0,0
    80005536:	00000097          	auipc	ra,0x0
    8000553a:	d28080e7          	jalr	-728(ra) # 8000525e <argfd>
    return -1;
    8000553e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005540:	04054163          	bltz	a0,80005582 <sys_write+0x5c>
    80005544:	fe440593          	addi	a1,s0,-28
    80005548:	4509                	li	a0,2
    8000554a:	ffffe097          	auipc	ra,0xffffe
    8000554e:	8bc080e7          	jalr	-1860(ra) # 80002e06 <argint>
    return -1;
    80005552:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005554:	02054763          	bltz	a0,80005582 <sys_write+0x5c>
    80005558:	fd840593          	addi	a1,s0,-40
    8000555c:	4505                	li	a0,1
    8000555e:	ffffe097          	auipc	ra,0xffffe
    80005562:	8ca080e7          	jalr	-1846(ra) # 80002e28 <argaddr>
    return -1;
    80005566:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005568:	00054d63          	bltz	a0,80005582 <sys_write+0x5c>
  return filewrite(f, p, n);
    8000556c:	fe442603          	lw	a2,-28(s0)
    80005570:	fd843583          	ld	a1,-40(s0)
    80005574:	fe843503          	ld	a0,-24(s0)
    80005578:	fffff097          	auipc	ra,0xfffff
    8000557c:	4a6080e7          	jalr	1190(ra) # 80004a1e <filewrite>
    80005580:	87aa                	mv	a5,a0
}
    80005582:	853e                	mv	a0,a5
    80005584:	70a2                	ld	ra,40(sp)
    80005586:	7402                	ld	s0,32(sp)
    80005588:	6145                	addi	sp,sp,48
    8000558a:	8082                	ret

000000008000558c <sys_close>:
{
    8000558c:	1101                	addi	sp,sp,-32
    8000558e:	ec06                	sd	ra,24(sp)
    80005590:	e822                	sd	s0,16(sp)
    80005592:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005594:	fe040613          	addi	a2,s0,-32
    80005598:	fec40593          	addi	a1,s0,-20
    8000559c:	4501                	li	a0,0
    8000559e:	00000097          	auipc	ra,0x0
    800055a2:	cc0080e7          	jalr	-832(ra) # 8000525e <argfd>
    return -1;
    800055a6:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800055a8:	02054463          	bltz	a0,800055d0 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    800055ac:	ffffc097          	auipc	ra,0xffffc
    800055b0:	79a080e7          	jalr	1946(ra) # 80001d46 <myproc>
    800055b4:	fec42783          	lw	a5,-20(s0)
    800055b8:	07e9                	addi	a5,a5,26
    800055ba:	078e                	slli	a5,a5,0x3
    800055bc:	953e                	add	a0,a0,a5
    800055be:	00053423          	sd	zero,8(a0)
  fileclose(f);
    800055c2:	fe043503          	ld	a0,-32(s0)
    800055c6:	fffff097          	auipc	ra,0xfffff
    800055ca:	25c080e7          	jalr	604(ra) # 80004822 <fileclose>
  return 0;
    800055ce:	4781                	li	a5,0
}
    800055d0:	853e                	mv	a0,a5
    800055d2:	60e2                	ld	ra,24(sp)
    800055d4:	6442                	ld	s0,16(sp)
    800055d6:	6105                	addi	sp,sp,32
    800055d8:	8082                	ret

00000000800055da <sys_fstat>:
{
    800055da:	1101                	addi	sp,sp,-32
    800055dc:	ec06                	sd	ra,24(sp)
    800055de:	e822                	sd	s0,16(sp)
    800055e0:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800055e2:	fe840613          	addi	a2,s0,-24
    800055e6:	4581                	li	a1,0
    800055e8:	4501                	li	a0,0
    800055ea:	00000097          	auipc	ra,0x0
    800055ee:	c74080e7          	jalr	-908(ra) # 8000525e <argfd>
    return -1;
    800055f2:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800055f4:	02054563          	bltz	a0,8000561e <sys_fstat+0x44>
    800055f8:	fe040593          	addi	a1,s0,-32
    800055fc:	4505                	li	a0,1
    800055fe:	ffffe097          	auipc	ra,0xffffe
    80005602:	82a080e7          	jalr	-2006(ra) # 80002e28 <argaddr>
    return -1;
    80005606:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005608:	00054b63          	bltz	a0,8000561e <sys_fstat+0x44>
  return filestat(f, st);
    8000560c:	fe043583          	ld	a1,-32(s0)
    80005610:	fe843503          	ld	a0,-24(s0)
    80005614:	fffff097          	auipc	ra,0xfffff
    80005618:	2d6080e7          	jalr	726(ra) # 800048ea <filestat>
    8000561c:	87aa                	mv	a5,a0
}
    8000561e:	853e                	mv	a0,a5
    80005620:	60e2                	ld	ra,24(sp)
    80005622:	6442                	ld	s0,16(sp)
    80005624:	6105                	addi	sp,sp,32
    80005626:	8082                	ret

0000000080005628 <sys_link>:
{
    80005628:	7169                	addi	sp,sp,-304
    8000562a:	f606                	sd	ra,296(sp)
    8000562c:	f222                	sd	s0,288(sp)
    8000562e:	ee26                	sd	s1,280(sp)
    80005630:	ea4a                	sd	s2,272(sp)
    80005632:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005634:	08000613          	li	a2,128
    80005638:	ed040593          	addi	a1,s0,-304
    8000563c:	4501                	li	a0,0
    8000563e:	ffffe097          	auipc	ra,0xffffe
    80005642:	80c080e7          	jalr	-2036(ra) # 80002e4a <argstr>
    return -1;
    80005646:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005648:	10054e63          	bltz	a0,80005764 <sys_link+0x13c>
    8000564c:	08000613          	li	a2,128
    80005650:	f5040593          	addi	a1,s0,-176
    80005654:	4505                	li	a0,1
    80005656:	ffffd097          	auipc	ra,0xffffd
    8000565a:	7f4080e7          	jalr	2036(ra) # 80002e4a <argstr>
    return -1;
    8000565e:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005660:	10054263          	bltz	a0,80005764 <sys_link+0x13c>
  begin_op();
    80005664:	fffff097          	auipc	ra,0xfffff
    80005668:	cee080e7          	jalr	-786(ra) # 80004352 <begin_op>
  if((ip = namei(old)) == 0){
    8000566c:	ed040513          	addi	a0,s0,-304
    80005670:	fffff097          	auipc	ra,0xfffff
    80005674:	ac2080e7          	jalr	-1342(ra) # 80004132 <namei>
    80005678:	84aa                	mv	s1,a0
    8000567a:	c551                	beqz	a0,80005706 <sys_link+0xde>
  ilock(ip);
    8000567c:	ffffe097          	auipc	ra,0xffffe
    80005680:	2fc080e7          	jalr	764(ra) # 80003978 <ilock>
  if(ip->type == T_DIR){
    80005684:	04c49703          	lh	a4,76(s1)
    80005688:	4785                	li	a5,1
    8000568a:	08f70463          	beq	a4,a5,80005712 <sys_link+0xea>
  ip->nlink++;
    8000568e:	0524d783          	lhu	a5,82(s1)
    80005692:	2785                	addiw	a5,a5,1
    80005694:	04f49923          	sh	a5,82(s1)
  iupdate(ip);
    80005698:	8526                	mv	a0,s1
    8000569a:	ffffe097          	auipc	ra,0xffffe
    8000569e:	212080e7          	jalr	530(ra) # 800038ac <iupdate>
  iunlock(ip);
    800056a2:	8526                	mv	a0,s1
    800056a4:	ffffe097          	auipc	ra,0xffffe
    800056a8:	396080e7          	jalr	918(ra) # 80003a3a <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    800056ac:	fd040593          	addi	a1,s0,-48
    800056b0:	f5040513          	addi	a0,s0,-176
    800056b4:	fffff097          	auipc	ra,0xfffff
    800056b8:	a9c080e7          	jalr	-1380(ra) # 80004150 <nameiparent>
    800056bc:	892a                	mv	s2,a0
    800056be:	c935                	beqz	a0,80005732 <sys_link+0x10a>
  ilock(dp);
    800056c0:	ffffe097          	auipc	ra,0xffffe
    800056c4:	2b8080e7          	jalr	696(ra) # 80003978 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    800056c8:	00092703          	lw	a4,0(s2)
    800056cc:	409c                	lw	a5,0(s1)
    800056ce:	04f71d63          	bne	a4,a5,80005728 <sys_link+0x100>
    800056d2:	40d0                	lw	a2,4(s1)
    800056d4:	fd040593          	addi	a1,s0,-48
    800056d8:	854a                	mv	a0,s2
    800056da:	fffff097          	auipc	ra,0xfffff
    800056de:	996080e7          	jalr	-1642(ra) # 80004070 <dirlink>
    800056e2:	04054363          	bltz	a0,80005728 <sys_link+0x100>
  iunlockput(dp);
    800056e6:	854a                	mv	a0,s2
    800056e8:	ffffe097          	auipc	ra,0xffffe
    800056ec:	4f2080e7          	jalr	1266(ra) # 80003bda <iunlockput>
  iput(ip);
    800056f0:	8526                	mv	a0,s1
    800056f2:	ffffe097          	auipc	ra,0xffffe
    800056f6:	440080e7          	jalr	1088(ra) # 80003b32 <iput>
  end_op();
    800056fa:	fffff097          	auipc	ra,0xfffff
    800056fe:	cd6080e7          	jalr	-810(ra) # 800043d0 <end_op>
  return 0;
    80005702:	4781                	li	a5,0
    80005704:	a085                	j	80005764 <sys_link+0x13c>
    end_op();
    80005706:	fffff097          	auipc	ra,0xfffff
    8000570a:	cca080e7          	jalr	-822(ra) # 800043d0 <end_op>
    return -1;
    8000570e:	57fd                	li	a5,-1
    80005710:	a891                	j	80005764 <sys_link+0x13c>
    iunlockput(ip);
    80005712:	8526                	mv	a0,s1
    80005714:	ffffe097          	auipc	ra,0xffffe
    80005718:	4c6080e7          	jalr	1222(ra) # 80003bda <iunlockput>
    end_op();
    8000571c:	fffff097          	auipc	ra,0xfffff
    80005720:	cb4080e7          	jalr	-844(ra) # 800043d0 <end_op>
    return -1;
    80005724:	57fd                	li	a5,-1
    80005726:	a83d                	j	80005764 <sys_link+0x13c>
    iunlockput(dp);
    80005728:	854a                	mv	a0,s2
    8000572a:	ffffe097          	auipc	ra,0xffffe
    8000572e:	4b0080e7          	jalr	1200(ra) # 80003bda <iunlockput>
  ilock(ip);
    80005732:	8526                	mv	a0,s1
    80005734:	ffffe097          	auipc	ra,0xffffe
    80005738:	244080e7          	jalr	580(ra) # 80003978 <ilock>
  ip->nlink--;
    8000573c:	0524d783          	lhu	a5,82(s1)
    80005740:	37fd                	addiw	a5,a5,-1
    80005742:	04f49923          	sh	a5,82(s1)
  iupdate(ip);
    80005746:	8526                	mv	a0,s1
    80005748:	ffffe097          	auipc	ra,0xffffe
    8000574c:	164080e7          	jalr	356(ra) # 800038ac <iupdate>
  iunlockput(ip);
    80005750:	8526                	mv	a0,s1
    80005752:	ffffe097          	auipc	ra,0xffffe
    80005756:	488080e7          	jalr	1160(ra) # 80003bda <iunlockput>
  end_op();
    8000575a:	fffff097          	auipc	ra,0xfffff
    8000575e:	c76080e7          	jalr	-906(ra) # 800043d0 <end_op>
  return -1;
    80005762:	57fd                	li	a5,-1
}
    80005764:	853e                	mv	a0,a5
    80005766:	70b2                	ld	ra,296(sp)
    80005768:	7412                	ld	s0,288(sp)
    8000576a:	64f2                	ld	s1,280(sp)
    8000576c:	6952                	ld	s2,272(sp)
    8000576e:	6155                	addi	sp,sp,304
    80005770:	8082                	ret

0000000080005772 <sys_unlink>:
{
    80005772:	7151                	addi	sp,sp,-240
    80005774:	f586                	sd	ra,232(sp)
    80005776:	f1a2                	sd	s0,224(sp)
    80005778:	eda6                	sd	s1,216(sp)
    8000577a:	e9ca                	sd	s2,208(sp)
    8000577c:	e5ce                	sd	s3,200(sp)
    8000577e:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005780:	08000613          	li	a2,128
    80005784:	f3040593          	addi	a1,s0,-208
    80005788:	4501                	li	a0,0
    8000578a:	ffffd097          	auipc	ra,0xffffd
    8000578e:	6c0080e7          	jalr	1728(ra) # 80002e4a <argstr>
    80005792:	18054163          	bltz	a0,80005914 <sys_unlink+0x1a2>
  begin_op();
    80005796:	fffff097          	auipc	ra,0xfffff
    8000579a:	bbc080e7          	jalr	-1092(ra) # 80004352 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    8000579e:	fb040593          	addi	a1,s0,-80
    800057a2:	f3040513          	addi	a0,s0,-208
    800057a6:	fffff097          	auipc	ra,0xfffff
    800057aa:	9aa080e7          	jalr	-1622(ra) # 80004150 <nameiparent>
    800057ae:	84aa                	mv	s1,a0
    800057b0:	c979                	beqz	a0,80005886 <sys_unlink+0x114>
  ilock(dp);
    800057b2:	ffffe097          	auipc	ra,0xffffe
    800057b6:	1c6080e7          	jalr	454(ra) # 80003978 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    800057ba:	00003597          	auipc	a1,0x3
    800057be:	fb658593          	addi	a1,a1,-74 # 80008770 <syscalls+0x2b8>
    800057c2:	fb040513          	addi	a0,s0,-80
    800057c6:	ffffe097          	auipc	ra,0xffffe
    800057ca:	67a080e7          	jalr	1658(ra) # 80003e40 <namecmp>
    800057ce:	14050a63          	beqz	a0,80005922 <sys_unlink+0x1b0>
    800057d2:	00003597          	auipc	a1,0x3
    800057d6:	fa658593          	addi	a1,a1,-90 # 80008778 <syscalls+0x2c0>
    800057da:	fb040513          	addi	a0,s0,-80
    800057de:	ffffe097          	auipc	ra,0xffffe
    800057e2:	662080e7          	jalr	1634(ra) # 80003e40 <namecmp>
    800057e6:	12050e63          	beqz	a0,80005922 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    800057ea:	f2c40613          	addi	a2,s0,-212
    800057ee:	fb040593          	addi	a1,s0,-80
    800057f2:	8526                	mv	a0,s1
    800057f4:	ffffe097          	auipc	ra,0xffffe
    800057f8:	666080e7          	jalr	1638(ra) # 80003e5a <dirlookup>
    800057fc:	892a                	mv	s2,a0
    800057fe:	12050263          	beqz	a0,80005922 <sys_unlink+0x1b0>
  ilock(ip);
    80005802:	ffffe097          	auipc	ra,0xffffe
    80005806:	176080e7          	jalr	374(ra) # 80003978 <ilock>
  if(ip->nlink < 1)
    8000580a:	05291783          	lh	a5,82(s2)
    8000580e:	08f05263          	blez	a5,80005892 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005812:	04c91703          	lh	a4,76(s2)
    80005816:	4785                	li	a5,1
    80005818:	08f70563          	beq	a4,a5,800058a2 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    8000581c:	4641                	li	a2,16
    8000581e:	4581                	li	a1,0
    80005820:	fc040513          	addi	a0,s0,-64
    80005824:	ffffc097          	auipc	ra,0xffffc
    80005828:	8bc080e7          	jalr	-1860(ra) # 800010e0 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000582c:	4741                	li	a4,16
    8000582e:	f2c42683          	lw	a3,-212(s0)
    80005832:	fc040613          	addi	a2,s0,-64
    80005836:	4581                	li	a1,0
    80005838:	8526                	mv	a0,s1
    8000583a:	ffffe097          	auipc	ra,0xffffe
    8000583e:	4ea080e7          	jalr	1258(ra) # 80003d24 <writei>
    80005842:	47c1                	li	a5,16
    80005844:	0af51563          	bne	a0,a5,800058ee <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005848:	04c91703          	lh	a4,76(s2)
    8000584c:	4785                	li	a5,1
    8000584e:	0af70863          	beq	a4,a5,800058fe <sys_unlink+0x18c>
  iunlockput(dp);
    80005852:	8526                	mv	a0,s1
    80005854:	ffffe097          	auipc	ra,0xffffe
    80005858:	386080e7          	jalr	902(ra) # 80003bda <iunlockput>
  ip->nlink--;
    8000585c:	05295783          	lhu	a5,82(s2)
    80005860:	37fd                	addiw	a5,a5,-1
    80005862:	04f91923          	sh	a5,82(s2)
  iupdate(ip);
    80005866:	854a                	mv	a0,s2
    80005868:	ffffe097          	auipc	ra,0xffffe
    8000586c:	044080e7          	jalr	68(ra) # 800038ac <iupdate>
  iunlockput(ip);
    80005870:	854a                	mv	a0,s2
    80005872:	ffffe097          	auipc	ra,0xffffe
    80005876:	368080e7          	jalr	872(ra) # 80003bda <iunlockput>
  end_op();
    8000587a:	fffff097          	auipc	ra,0xfffff
    8000587e:	b56080e7          	jalr	-1194(ra) # 800043d0 <end_op>
  return 0;
    80005882:	4501                	li	a0,0
    80005884:	a84d                	j	80005936 <sys_unlink+0x1c4>
    end_op();
    80005886:	fffff097          	auipc	ra,0xfffff
    8000588a:	b4a080e7          	jalr	-1206(ra) # 800043d0 <end_op>
    return -1;
    8000588e:	557d                	li	a0,-1
    80005890:	a05d                	j	80005936 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005892:	00003517          	auipc	a0,0x3
    80005896:	f0e50513          	addi	a0,a0,-242 # 800087a0 <syscalls+0x2e8>
    8000589a:	ffffb097          	auipc	ra,0xffffb
    8000589e:	cb2080e7          	jalr	-846(ra) # 8000054c <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800058a2:	05492703          	lw	a4,84(s2)
    800058a6:	02000793          	li	a5,32
    800058aa:	f6e7f9e3          	bgeu	a5,a4,8000581c <sys_unlink+0xaa>
    800058ae:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800058b2:	4741                	li	a4,16
    800058b4:	86ce                	mv	a3,s3
    800058b6:	f1840613          	addi	a2,s0,-232
    800058ba:	4581                	li	a1,0
    800058bc:	854a                	mv	a0,s2
    800058be:	ffffe097          	auipc	ra,0xffffe
    800058c2:	36e080e7          	jalr	878(ra) # 80003c2c <readi>
    800058c6:	47c1                	li	a5,16
    800058c8:	00f51b63          	bne	a0,a5,800058de <sys_unlink+0x16c>
    if(de.inum != 0)
    800058cc:	f1845783          	lhu	a5,-232(s0)
    800058d0:	e7a1                	bnez	a5,80005918 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800058d2:	29c1                	addiw	s3,s3,16
    800058d4:	05492783          	lw	a5,84(s2)
    800058d8:	fcf9ede3          	bltu	s3,a5,800058b2 <sys_unlink+0x140>
    800058dc:	b781                	j	8000581c <sys_unlink+0xaa>
      panic("isdirempty: readi");
    800058de:	00003517          	auipc	a0,0x3
    800058e2:	eda50513          	addi	a0,a0,-294 # 800087b8 <syscalls+0x300>
    800058e6:	ffffb097          	auipc	ra,0xffffb
    800058ea:	c66080e7          	jalr	-922(ra) # 8000054c <panic>
    panic("unlink: writei");
    800058ee:	00003517          	auipc	a0,0x3
    800058f2:	ee250513          	addi	a0,a0,-286 # 800087d0 <syscalls+0x318>
    800058f6:	ffffb097          	auipc	ra,0xffffb
    800058fa:	c56080e7          	jalr	-938(ra) # 8000054c <panic>
    dp->nlink--;
    800058fe:	0524d783          	lhu	a5,82(s1)
    80005902:	37fd                	addiw	a5,a5,-1
    80005904:	04f49923          	sh	a5,82(s1)
    iupdate(dp);
    80005908:	8526                	mv	a0,s1
    8000590a:	ffffe097          	auipc	ra,0xffffe
    8000590e:	fa2080e7          	jalr	-94(ra) # 800038ac <iupdate>
    80005912:	b781                	j	80005852 <sys_unlink+0xe0>
    return -1;
    80005914:	557d                	li	a0,-1
    80005916:	a005                	j	80005936 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005918:	854a                	mv	a0,s2
    8000591a:	ffffe097          	auipc	ra,0xffffe
    8000591e:	2c0080e7          	jalr	704(ra) # 80003bda <iunlockput>
  iunlockput(dp);
    80005922:	8526                	mv	a0,s1
    80005924:	ffffe097          	auipc	ra,0xffffe
    80005928:	2b6080e7          	jalr	694(ra) # 80003bda <iunlockput>
  end_op();
    8000592c:	fffff097          	auipc	ra,0xfffff
    80005930:	aa4080e7          	jalr	-1372(ra) # 800043d0 <end_op>
  return -1;
    80005934:	557d                	li	a0,-1
}
    80005936:	70ae                	ld	ra,232(sp)
    80005938:	740e                	ld	s0,224(sp)
    8000593a:	64ee                	ld	s1,216(sp)
    8000593c:	694e                	ld	s2,208(sp)
    8000593e:	69ae                	ld	s3,200(sp)
    80005940:	616d                	addi	sp,sp,240
    80005942:	8082                	ret

0000000080005944 <sys_open>:

uint64
sys_open(void)
{
    80005944:	7131                	addi	sp,sp,-192
    80005946:	fd06                	sd	ra,184(sp)
    80005948:	f922                	sd	s0,176(sp)
    8000594a:	f526                	sd	s1,168(sp)
    8000594c:	f14a                	sd	s2,160(sp)
    8000594e:	ed4e                	sd	s3,152(sp)
    80005950:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005952:	08000613          	li	a2,128
    80005956:	f5040593          	addi	a1,s0,-176
    8000595a:	4501                	li	a0,0
    8000595c:	ffffd097          	auipc	ra,0xffffd
    80005960:	4ee080e7          	jalr	1262(ra) # 80002e4a <argstr>
    return -1;
    80005964:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005966:	0c054163          	bltz	a0,80005a28 <sys_open+0xe4>
    8000596a:	f4c40593          	addi	a1,s0,-180
    8000596e:	4505                	li	a0,1
    80005970:	ffffd097          	auipc	ra,0xffffd
    80005974:	496080e7          	jalr	1174(ra) # 80002e06 <argint>
    80005978:	0a054863          	bltz	a0,80005a28 <sys_open+0xe4>

  begin_op();
    8000597c:	fffff097          	auipc	ra,0xfffff
    80005980:	9d6080e7          	jalr	-1578(ra) # 80004352 <begin_op>

  if(omode & O_CREATE){
    80005984:	f4c42783          	lw	a5,-180(s0)
    80005988:	2007f793          	andi	a5,a5,512
    8000598c:	cbdd                	beqz	a5,80005a42 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    8000598e:	4681                	li	a3,0
    80005990:	4601                	li	a2,0
    80005992:	4589                	li	a1,2
    80005994:	f5040513          	addi	a0,s0,-176
    80005998:	00000097          	auipc	ra,0x0
    8000599c:	970080e7          	jalr	-1680(ra) # 80005308 <create>
    800059a0:	892a                	mv	s2,a0
    if(ip == 0){
    800059a2:	c959                	beqz	a0,80005a38 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    800059a4:	04c91703          	lh	a4,76(s2)
    800059a8:	478d                	li	a5,3
    800059aa:	00f71763          	bne	a4,a5,800059b8 <sys_open+0x74>
    800059ae:	04e95703          	lhu	a4,78(s2)
    800059b2:	47a5                	li	a5,9
    800059b4:	0ce7ec63          	bltu	a5,a4,80005a8c <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    800059b8:	fffff097          	auipc	ra,0xfffff
    800059bc:	dae080e7          	jalr	-594(ra) # 80004766 <filealloc>
    800059c0:	89aa                	mv	s3,a0
    800059c2:	10050263          	beqz	a0,80005ac6 <sys_open+0x182>
    800059c6:	00000097          	auipc	ra,0x0
    800059ca:	900080e7          	jalr	-1792(ra) # 800052c6 <fdalloc>
    800059ce:	84aa                	mv	s1,a0
    800059d0:	0e054663          	bltz	a0,80005abc <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    800059d4:	04c91703          	lh	a4,76(s2)
    800059d8:	478d                	li	a5,3
    800059da:	0cf70463          	beq	a4,a5,80005aa2 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    800059de:	4789                	li	a5,2
    800059e0:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    800059e4:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    800059e8:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    800059ec:	f4c42783          	lw	a5,-180(s0)
    800059f0:	0017c713          	xori	a4,a5,1
    800059f4:	8b05                	andi	a4,a4,1
    800059f6:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    800059fa:	0037f713          	andi	a4,a5,3
    800059fe:	00e03733          	snez	a4,a4
    80005a02:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005a06:	4007f793          	andi	a5,a5,1024
    80005a0a:	c791                	beqz	a5,80005a16 <sys_open+0xd2>
    80005a0c:	04c91703          	lh	a4,76(s2)
    80005a10:	4789                	li	a5,2
    80005a12:	08f70f63          	beq	a4,a5,80005ab0 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005a16:	854a                	mv	a0,s2
    80005a18:	ffffe097          	auipc	ra,0xffffe
    80005a1c:	022080e7          	jalr	34(ra) # 80003a3a <iunlock>
  end_op();
    80005a20:	fffff097          	auipc	ra,0xfffff
    80005a24:	9b0080e7          	jalr	-1616(ra) # 800043d0 <end_op>

  return fd;
}
    80005a28:	8526                	mv	a0,s1
    80005a2a:	70ea                	ld	ra,184(sp)
    80005a2c:	744a                	ld	s0,176(sp)
    80005a2e:	74aa                	ld	s1,168(sp)
    80005a30:	790a                	ld	s2,160(sp)
    80005a32:	69ea                	ld	s3,152(sp)
    80005a34:	6129                	addi	sp,sp,192
    80005a36:	8082                	ret
      end_op();
    80005a38:	fffff097          	auipc	ra,0xfffff
    80005a3c:	998080e7          	jalr	-1640(ra) # 800043d0 <end_op>
      return -1;
    80005a40:	b7e5                	j	80005a28 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005a42:	f5040513          	addi	a0,s0,-176
    80005a46:	ffffe097          	auipc	ra,0xffffe
    80005a4a:	6ec080e7          	jalr	1772(ra) # 80004132 <namei>
    80005a4e:	892a                	mv	s2,a0
    80005a50:	c905                	beqz	a0,80005a80 <sys_open+0x13c>
    ilock(ip);
    80005a52:	ffffe097          	auipc	ra,0xffffe
    80005a56:	f26080e7          	jalr	-218(ra) # 80003978 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005a5a:	04c91703          	lh	a4,76(s2)
    80005a5e:	4785                	li	a5,1
    80005a60:	f4f712e3          	bne	a4,a5,800059a4 <sys_open+0x60>
    80005a64:	f4c42783          	lw	a5,-180(s0)
    80005a68:	dba1                	beqz	a5,800059b8 <sys_open+0x74>
      iunlockput(ip);
    80005a6a:	854a                	mv	a0,s2
    80005a6c:	ffffe097          	auipc	ra,0xffffe
    80005a70:	16e080e7          	jalr	366(ra) # 80003bda <iunlockput>
      end_op();
    80005a74:	fffff097          	auipc	ra,0xfffff
    80005a78:	95c080e7          	jalr	-1700(ra) # 800043d0 <end_op>
      return -1;
    80005a7c:	54fd                	li	s1,-1
    80005a7e:	b76d                	j	80005a28 <sys_open+0xe4>
      end_op();
    80005a80:	fffff097          	auipc	ra,0xfffff
    80005a84:	950080e7          	jalr	-1712(ra) # 800043d0 <end_op>
      return -1;
    80005a88:	54fd                	li	s1,-1
    80005a8a:	bf79                	j	80005a28 <sys_open+0xe4>
    iunlockput(ip);
    80005a8c:	854a                	mv	a0,s2
    80005a8e:	ffffe097          	auipc	ra,0xffffe
    80005a92:	14c080e7          	jalr	332(ra) # 80003bda <iunlockput>
    end_op();
    80005a96:	fffff097          	auipc	ra,0xfffff
    80005a9a:	93a080e7          	jalr	-1734(ra) # 800043d0 <end_op>
    return -1;
    80005a9e:	54fd                	li	s1,-1
    80005aa0:	b761                	j	80005a28 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005aa2:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005aa6:	04e91783          	lh	a5,78(s2)
    80005aaa:	02f99223          	sh	a5,36(s3)
    80005aae:	bf2d                	j	800059e8 <sys_open+0xa4>
    itrunc(ip);
    80005ab0:	854a                	mv	a0,s2
    80005ab2:	ffffe097          	auipc	ra,0xffffe
    80005ab6:	fd4080e7          	jalr	-44(ra) # 80003a86 <itrunc>
    80005aba:	bfb1                	j	80005a16 <sys_open+0xd2>
      fileclose(f);
    80005abc:	854e                	mv	a0,s3
    80005abe:	fffff097          	auipc	ra,0xfffff
    80005ac2:	d64080e7          	jalr	-668(ra) # 80004822 <fileclose>
    iunlockput(ip);
    80005ac6:	854a                	mv	a0,s2
    80005ac8:	ffffe097          	auipc	ra,0xffffe
    80005acc:	112080e7          	jalr	274(ra) # 80003bda <iunlockput>
    end_op();
    80005ad0:	fffff097          	auipc	ra,0xfffff
    80005ad4:	900080e7          	jalr	-1792(ra) # 800043d0 <end_op>
    return -1;
    80005ad8:	54fd                	li	s1,-1
    80005ada:	b7b9                	j	80005a28 <sys_open+0xe4>

0000000080005adc <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005adc:	7175                	addi	sp,sp,-144
    80005ade:	e506                	sd	ra,136(sp)
    80005ae0:	e122                	sd	s0,128(sp)
    80005ae2:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005ae4:	fffff097          	auipc	ra,0xfffff
    80005ae8:	86e080e7          	jalr	-1938(ra) # 80004352 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005aec:	08000613          	li	a2,128
    80005af0:	f7040593          	addi	a1,s0,-144
    80005af4:	4501                	li	a0,0
    80005af6:	ffffd097          	auipc	ra,0xffffd
    80005afa:	354080e7          	jalr	852(ra) # 80002e4a <argstr>
    80005afe:	02054963          	bltz	a0,80005b30 <sys_mkdir+0x54>
    80005b02:	4681                	li	a3,0
    80005b04:	4601                	li	a2,0
    80005b06:	4585                	li	a1,1
    80005b08:	f7040513          	addi	a0,s0,-144
    80005b0c:	fffff097          	auipc	ra,0xfffff
    80005b10:	7fc080e7          	jalr	2044(ra) # 80005308 <create>
    80005b14:	cd11                	beqz	a0,80005b30 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005b16:	ffffe097          	auipc	ra,0xffffe
    80005b1a:	0c4080e7          	jalr	196(ra) # 80003bda <iunlockput>
  end_op();
    80005b1e:	fffff097          	auipc	ra,0xfffff
    80005b22:	8b2080e7          	jalr	-1870(ra) # 800043d0 <end_op>
  return 0;
    80005b26:	4501                	li	a0,0
}
    80005b28:	60aa                	ld	ra,136(sp)
    80005b2a:	640a                	ld	s0,128(sp)
    80005b2c:	6149                	addi	sp,sp,144
    80005b2e:	8082                	ret
    end_op();
    80005b30:	fffff097          	auipc	ra,0xfffff
    80005b34:	8a0080e7          	jalr	-1888(ra) # 800043d0 <end_op>
    return -1;
    80005b38:	557d                	li	a0,-1
    80005b3a:	b7fd                	j	80005b28 <sys_mkdir+0x4c>

0000000080005b3c <sys_mknod>:

uint64
sys_mknod(void)
{
    80005b3c:	7135                	addi	sp,sp,-160
    80005b3e:	ed06                	sd	ra,152(sp)
    80005b40:	e922                	sd	s0,144(sp)
    80005b42:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005b44:	fffff097          	auipc	ra,0xfffff
    80005b48:	80e080e7          	jalr	-2034(ra) # 80004352 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005b4c:	08000613          	li	a2,128
    80005b50:	f7040593          	addi	a1,s0,-144
    80005b54:	4501                	li	a0,0
    80005b56:	ffffd097          	auipc	ra,0xffffd
    80005b5a:	2f4080e7          	jalr	756(ra) # 80002e4a <argstr>
    80005b5e:	04054a63          	bltz	a0,80005bb2 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005b62:	f6c40593          	addi	a1,s0,-148
    80005b66:	4505                	li	a0,1
    80005b68:	ffffd097          	auipc	ra,0xffffd
    80005b6c:	29e080e7          	jalr	670(ra) # 80002e06 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005b70:	04054163          	bltz	a0,80005bb2 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005b74:	f6840593          	addi	a1,s0,-152
    80005b78:	4509                	li	a0,2
    80005b7a:	ffffd097          	auipc	ra,0xffffd
    80005b7e:	28c080e7          	jalr	652(ra) # 80002e06 <argint>
     argint(1, &major) < 0 ||
    80005b82:	02054863          	bltz	a0,80005bb2 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005b86:	f6841683          	lh	a3,-152(s0)
    80005b8a:	f6c41603          	lh	a2,-148(s0)
    80005b8e:	458d                	li	a1,3
    80005b90:	f7040513          	addi	a0,s0,-144
    80005b94:	fffff097          	auipc	ra,0xfffff
    80005b98:	774080e7          	jalr	1908(ra) # 80005308 <create>
     argint(2, &minor) < 0 ||
    80005b9c:	c919                	beqz	a0,80005bb2 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005b9e:	ffffe097          	auipc	ra,0xffffe
    80005ba2:	03c080e7          	jalr	60(ra) # 80003bda <iunlockput>
  end_op();
    80005ba6:	fffff097          	auipc	ra,0xfffff
    80005baa:	82a080e7          	jalr	-2006(ra) # 800043d0 <end_op>
  return 0;
    80005bae:	4501                	li	a0,0
    80005bb0:	a031                	j	80005bbc <sys_mknod+0x80>
    end_op();
    80005bb2:	fffff097          	auipc	ra,0xfffff
    80005bb6:	81e080e7          	jalr	-2018(ra) # 800043d0 <end_op>
    return -1;
    80005bba:	557d                	li	a0,-1
}
    80005bbc:	60ea                	ld	ra,152(sp)
    80005bbe:	644a                	ld	s0,144(sp)
    80005bc0:	610d                	addi	sp,sp,160
    80005bc2:	8082                	ret

0000000080005bc4 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005bc4:	7135                	addi	sp,sp,-160
    80005bc6:	ed06                	sd	ra,152(sp)
    80005bc8:	e922                	sd	s0,144(sp)
    80005bca:	e526                	sd	s1,136(sp)
    80005bcc:	e14a                	sd	s2,128(sp)
    80005bce:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005bd0:	ffffc097          	auipc	ra,0xffffc
    80005bd4:	176080e7          	jalr	374(ra) # 80001d46 <myproc>
    80005bd8:	892a                	mv	s2,a0
  
  begin_op();
    80005bda:	ffffe097          	auipc	ra,0xffffe
    80005bde:	778080e7          	jalr	1912(ra) # 80004352 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005be2:	08000613          	li	a2,128
    80005be6:	f6040593          	addi	a1,s0,-160
    80005bea:	4501                	li	a0,0
    80005bec:	ffffd097          	auipc	ra,0xffffd
    80005bf0:	25e080e7          	jalr	606(ra) # 80002e4a <argstr>
    80005bf4:	04054b63          	bltz	a0,80005c4a <sys_chdir+0x86>
    80005bf8:	f6040513          	addi	a0,s0,-160
    80005bfc:	ffffe097          	auipc	ra,0xffffe
    80005c00:	536080e7          	jalr	1334(ra) # 80004132 <namei>
    80005c04:	84aa                	mv	s1,a0
    80005c06:	c131                	beqz	a0,80005c4a <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005c08:	ffffe097          	auipc	ra,0xffffe
    80005c0c:	d70080e7          	jalr	-656(ra) # 80003978 <ilock>
  if(ip->type != T_DIR){
    80005c10:	04c49703          	lh	a4,76(s1)
    80005c14:	4785                	li	a5,1
    80005c16:	04f71063          	bne	a4,a5,80005c56 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005c1a:	8526                	mv	a0,s1
    80005c1c:	ffffe097          	auipc	ra,0xffffe
    80005c20:	e1e080e7          	jalr	-482(ra) # 80003a3a <iunlock>
  iput(p->cwd);
    80005c24:	15893503          	ld	a0,344(s2)
    80005c28:	ffffe097          	auipc	ra,0xffffe
    80005c2c:	f0a080e7          	jalr	-246(ra) # 80003b32 <iput>
  end_op();
    80005c30:	ffffe097          	auipc	ra,0xffffe
    80005c34:	7a0080e7          	jalr	1952(ra) # 800043d0 <end_op>
  p->cwd = ip;
    80005c38:	14993c23          	sd	s1,344(s2)
  return 0;
    80005c3c:	4501                	li	a0,0
}
    80005c3e:	60ea                	ld	ra,152(sp)
    80005c40:	644a                	ld	s0,144(sp)
    80005c42:	64aa                	ld	s1,136(sp)
    80005c44:	690a                	ld	s2,128(sp)
    80005c46:	610d                	addi	sp,sp,160
    80005c48:	8082                	ret
    end_op();
    80005c4a:	ffffe097          	auipc	ra,0xffffe
    80005c4e:	786080e7          	jalr	1926(ra) # 800043d0 <end_op>
    return -1;
    80005c52:	557d                	li	a0,-1
    80005c54:	b7ed                	j	80005c3e <sys_chdir+0x7a>
    iunlockput(ip);
    80005c56:	8526                	mv	a0,s1
    80005c58:	ffffe097          	auipc	ra,0xffffe
    80005c5c:	f82080e7          	jalr	-126(ra) # 80003bda <iunlockput>
    end_op();
    80005c60:	ffffe097          	auipc	ra,0xffffe
    80005c64:	770080e7          	jalr	1904(ra) # 800043d0 <end_op>
    return -1;
    80005c68:	557d                	li	a0,-1
    80005c6a:	bfd1                	j	80005c3e <sys_chdir+0x7a>

0000000080005c6c <sys_exec>:

uint64
sys_exec(void)
{
    80005c6c:	7145                	addi	sp,sp,-464
    80005c6e:	e786                	sd	ra,456(sp)
    80005c70:	e3a2                	sd	s0,448(sp)
    80005c72:	ff26                	sd	s1,440(sp)
    80005c74:	fb4a                	sd	s2,432(sp)
    80005c76:	f74e                	sd	s3,424(sp)
    80005c78:	f352                	sd	s4,416(sp)
    80005c7a:	ef56                	sd	s5,408(sp)
    80005c7c:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005c7e:	08000613          	li	a2,128
    80005c82:	f4040593          	addi	a1,s0,-192
    80005c86:	4501                	li	a0,0
    80005c88:	ffffd097          	auipc	ra,0xffffd
    80005c8c:	1c2080e7          	jalr	450(ra) # 80002e4a <argstr>
    return -1;
    80005c90:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005c92:	0c054b63          	bltz	a0,80005d68 <sys_exec+0xfc>
    80005c96:	e3840593          	addi	a1,s0,-456
    80005c9a:	4505                	li	a0,1
    80005c9c:	ffffd097          	auipc	ra,0xffffd
    80005ca0:	18c080e7          	jalr	396(ra) # 80002e28 <argaddr>
    80005ca4:	0c054263          	bltz	a0,80005d68 <sys_exec+0xfc>
  }
  memset(argv, 0, sizeof(argv));
    80005ca8:	10000613          	li	a2,256
    80005cac:	4581                	li	a1,0
    80005cae:	e4040513          	addi	a0,s0,-448
    80005cb2:	ffffb097          	auipc	ra,0xffffb
    80005cb6:	42e080e7          	jalr	1070(ra) # 800010e0 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005cba:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005cbe:	89a6                	mv	s3,s1
    80005cc0:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005cc2:	02000a13          	li	s4,32
    80005cc6:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005cca:	00391513          	slli	a0,s2,0x3
    80005cce:	e3040593          	addi	a1,s0,-464
    80005cd2:	e3843783          	ld	a5,-456(s0)
    80005cd6:	953e                	add	a0,a0,a5
    80005cd8:	ffffd097          	auipc	ra,0xffffd
    80005cdc:	094080e7          	jalr	148(ra) # 80002d6c <fetchaddr>
    80005ce0:	02054a63          	bltz	a0,80005d14 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005ce4:	e3043783          	ld	a5,-464(s0)
    80005ce8:	c3b9                	beqz	a5,80005d2e <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005cea:	ffffb097          	auipc	ra,0xffffb
    80005cee:	ea0080e7          	jalr	-352(ra) # 80000b8a <kalloc>
    80005cf2:	85aa                	mv	a1,a0
    80005cf4:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005cf8:	cd11                	beqz	a0,80005d14 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005cfa:	6605                	lui	a2,0x1
    80005cfc:	e3043503          	ld	a0,-464(s0)
    80005d00:	ffffd097          	auipc	ra,0xffffd
    80005d04:	0be080e7          	jalr	190(ra) # 80002dbe <fetchstr>
    80005d08:	00054663          	bltz	a0,80005d14 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005d0c:	0905                	addi	s2,s2,1
    80005d0e:	09a1                	addi	s3,s3,8
    80005d10:	fb491be3          	bne	s2,s4,80005cc6 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005d14:	f4040913          	addi	s2,s0,-192
    80005d18:	6088                	ld	a0,0(s1)
    80005d1a:	c531                	beqz	a0,80005d66 <sys_exec+0xfa>
    kfree(argv[i]);
    80005d1c:	ffffb097          	auipc	ra,0xffffb
    80005d20:	cfc080e7          	jalr	-772(ra) # 80000a18 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005d24:	04a1                	addi	s1,s1,8
    80005d26:	ff2499e3          	bne	s1,s2,80005d18 <sys_exec+0xac>
  return -1;
    80005d2a:	597d                	li	s2,-1
    80005d2c:	a835                	j	80005d68 <sys_exec+0xfc>
      argv[i] = 0;
    80005d2e:	0a8e                	slli	s5,s5,0x3
    80005d30:	fc0a8793          	addi	a5,s5,-64 # ffffffffffffefc0 <end+0xffffffff7ffd6f98>
    80005d34:	00878ab3          	add	s5,a5,s0
    80005d38:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005d3c:	e4040593          	addi	a1,s0,-448
    80005d40:	f4040513          	addi	a0,s0,-192
    80005d44:	fffff097          	auipc	ra,0xfffff
    80005d48:	172080e7          	jalr	370(ra) # 80004eb6 <exec>
    80005d4c:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005d4e:	f4040993          	addi	s3,s0,-192
    80005d52:	6088                	ld	a0,0(s1)
    80005d54:	c911                	beqz	a0,80005d68 <sys_exec+0xfc>
    kfree(argv[i]);
    80005d56:	ffffb097          	auipc	ra,0xffffb
    80005d5a:	cc2080e7          	jalr	-830(ra) # 80000a18 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005d5e:	04a1                	addi	s1,s1,8
    80005d60:	ff3499e3          	bne	s1,s3,80005d52 <sys_exec+0xe6>
    80005d64:	a011                	j	80005d68 <sys_exec+0xfc>
  return -1;
    80005d66:	597d                	li	s2,-1
}
    80005d68:	854a                	mv	a0,s2
    80005d6a:	60be                	ld	ra,456(sp)
    80005d6c:	641e                	ld	s0,448(sp)
    80005d6e:	74fa                	ld	s1,440(sp)
    80005d70:	795a                	ld	s2,432(sp)
    80005d72:	79ba                	ld	s3,424(sp)
    80005d74:	7a1a                	ld	s4,416(sp)
    80005d76:	6afa                	ld	s5,408(sp)
    80005d78:	6179                	addi	sp,sp,464
    80005d7a:	8082                	ret

0000000080005d7c <sys_pipe>:

uint64
sys_pipe(void)
{
    80005d7c:	7139                	addi	sp,sp,-64
    80005d7e:	fc06                	sd	ra,56(sp)
    80005d80:	f822                	sd	s0,48(sp)
    80005d82:	f426                	sd	s1,40(sp)
    80005d84:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005d86:	ffffc097          	auipc	ra,0xffffc
    80005d8a:	fc0080e7          	jalr	-64(ra) # 80001d46 <myproc>
    80005d8e:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005d90:	fd840593          	addi	a1,s0,-40
    80005d94:	4501                	li	a0,0
    80005d96:	ffffd097          	auipc	ra,0xffffd
    80005d9a:	092080e7          	jalr	146(ra) # 80002e28 <argaddr>
    return -1;
    80005d9e:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005da0:	0e054063          	bltz	a0,80005e80 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005da4:	fc840593          	addi	a1,s0,-56
    80005da8:	fd040513          	addi	a0,s0,-48
    80005dac:	fffff097          	auipc	ra,0xfffff
    80005db0:	dcc080e7          	jalr	-564(ra) # 80004b78 <pipealloc>
    return -1;
    80005db4:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005db6:	0c054563          	bltz	a0,80005e80 <sys_pipe+0x104>
  fd0 = -1;
    80005dba:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005dbe:	fd043503          	ld	a0,-48(s0)
    80005dc2:	fffff097          	auipc	ra,0xfffff
    80005dc6:	504080e7          	jalr	1284(ra) # 800052c6 <fdalloc>
    80005dca:	fca42223          	sw	a0,-60(s0)
    80005dce:	08054c63          	bltz	a0,80005e66 <sys_pipe+0xea>
    80005dd2:	fc843503          	ld	a0,-56(s0)
    80005dd6:	fffff097          	auipc	ra,0xfffff
    80005dda:	4f0080e7          	jalr	1264(ra) # 800052c6 <fdalloc>
    80005dde:	fca42023          	sw	a0,-64(s0)
    80005de2:	06054963          	bltz	a0,80005e54 <sys_pipe+0xd8>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005de6:	4691                	li	a3,4
    80005de8:	fc440613          	addi	a2,s0,-60
    80005dec:	fd843583          	ld	a1,-40(s0)
    80005df0:	6ca8                	ld	a0,88(s1)
    80005df2:	ffffc097          	auipc	ra,0xffffc
    80005df6:	c4a080e7          	jalr	-950(ra) # 80001a3c <copyout>
    80005dfa:	02054063          	bltz	a0,80005e1a <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005dfe:	4691                	li	a3,4
    80005e00:	fc040613          	addi	a2,s0,-64
    80005e04:	fd843583          	ld	a1,-40(s0)
    80005e08:	0591                	addi	a1,a1,4
    80005e0a:	6ca8                	ld	a0,88(s1)
    80005e0c:	ffffc097          	auipc	ra,0xffffc
    80005e10:	c30080e7          	jalr	-976(ra) # 80001a3c <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005e14:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005e16:	06055563          	bgez	a0,80005e80 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005e1a:	fc442783          	lw	a5,-60(s0)
    80005e1e:	07e9                	addi	a5,a5,26
    80005e20:	078e                	slli	a5,a5,0x3
    80005e22:	97a6                	add	a5,a5,s1
    80005e24:	0007b423          	sd	zero,8(a5)
    p->ofile[fd1] = 0;
    80005e28:	fc042783          	lw	a5,-64(s0)
    80005e2c:	07e9                	addi	a5,a5,26
    80005e2e:	078e                	slli	a5,a5,0x3
    80005e30:	00f48533          	add	a0,s1,a5
    80005e34:	00053423          	sd	zero,8(a0)
    fileclose(rf);
    80005e38:	fd043503          	ld	a0,-48(s0)
    80005e3c:	fffff097          	auipc	ra,0xfffff
    80005e40:	9e6080e7          	jalr	-1562(ra) # 80004822 <fileclose>
    fileclose(wf);
    80005e44:	fc843503          	ld	a0,-56(s0)
    80005e48:	fffff097          	auipc	ra,0xfffff
    80005e4c:	9da080e7          	jalr	-1574(ra) # 80004822 <fileclose>
    return -1;
    80005e50:	57fd                	li	a5,-1
    80005e52:	a03d                	j	80005e80 <sys_pipe+0x104>
    if(fd0 >= 0)
    80005e54:	fc442783          	lw	a5,-60(s0)
    80005e58:	0007c763          	bltz	a5,80005e66 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005e5c:	07e9                	addi	a5,a5,26
    80005e5e:	078e                	slli	a5,a5,0x3
    80005e60:	97a6                	add	a5,a5,s1
    80005e62:	0007b423          	sd	zero,8(a5)
    fileclose(rf);
    80005e66:	fd043503          	ld	a0,-48(s0)
    80005e6a:	fffff097          	auipc	ra,0xfffff
    80005e6e:	9b8080e7          	jalr	-1608(ra) # 80004822 <fileclose>
    fileclose(wf);
    80005e72:	fc843503          	ld	a0,-56(s0)
    80005e76:	fffff097          	auipc	ra,0xfffff
    80005e7a:	9ac080e7          	jalr	-1620(ra) # 80004822 <fileclose>
    return -1;
    80005e7e:	57fd                	li	a5,-1
}
    80005e80:	853e                	mv	a0,a5
    80005e82:	70e2                	ld	ra,56(sp)
    80005e84:	7442                	ld	s0,48(sp)
    80005e86:	74a2                	ld	s1,40(sp)
    80005e88:	6121                	addi	sp,sp,64
    80005e8a:	8082                	ret
    80005e8c:	0000                	unimp
	...

0000000080005e90 <kernelvec>:
    80005e90:	7111                	addi	sp,sp,-256
    80005e92:	e006                	sd	ra,0(sp)
    80005e94:	e40a                	sd	sp,8(sp)
    80005e96:	e80e                	sd	gp,16(sp)
    80005e98:	ec12                	sd	tp,24(sp)
    80005e9a:	f016                	sd	t0,32(sp)
    80005e9c:	f41a                	sd	t1,40(sp)
    80005e9e:	f81e                	sd	t2,48(sp)
    80005ea0:	fc22                	sd	s0,56(sp)
    80005ea2:	e0a6                	sd	s1,64(sp)
    80005ea4:	e4aa                	sd	a0,72(sp)
    80005ea6:	e8ae                	sd	a1,80(sp)
    80005ea8:	ecb2                	sd	a2,88(sp)
    80005eaa:	f0b6                	sd	a3,96(sp)
    80005eac:	f4ba                	sd	a4,104(sp)
    80005eae:	f8be                	sd	a5,112(sp)
    80005eb0:	fcc2                	sd	a6,120(sp)
    80005eb2:	e146                	sd	a7,128(sp)
    80005eb4:	e54a                	sd	s2,136(sp)
    80005eb6:	e94e                	sd	s3,144(sp)
    80005eb8:	ed52                	sd	s4,152(sp)
    80005eba:	f156                	sd	s5,160(sp)
    80005ebc:	f55a                	sd	s6,168(sp)
    80005ebe:	f95e                	sd	s7,176(sp)
    80005ec0:	fd62                	sd	s8,184(sp)
    80005ec2:	e1e6                	sd	s9,192(sp)
    80005ec4:	e5ea                	sd	s10,200(sp)
    80005ec6:	e9ee                	sd	s11,208(sp)
    80005ec8:	edf2                	sd	t3,216(sp)
    80005eca:	f1f6                	sd	t4,224(sp)
    80005ecc:	f5fa                	sd	t5,232(sp)
    80005ece:	f9fe                	sd	t6,240(sp)
    80005ed0:	d69fc0ef          	jal	ra,80002c38 <kerneltrap>
    80005ed4:	6082                	ld	ra,0(sp)
    80005ed6:	6122                	ld	sp,8(sp)
    80005ed8:	61c2                	ld	gp,16(sp)
    80005eda:	7282                	ld	t0,32(sp)
    80005edc:	7322                	ld	t1,40(sp)
    80005ede:	73c2                	ld	t2,48(sp)
    80005ee0:	7462                	ld	s0,56(sp)
    80005ee2:	6486                	ld	s1,64(sp)
    80005ee4:	6526                	ld	a0,72(sp)
    80005ee6:	65c6                	ld	a1,80(sp)
    80005ee8:	6666                	ld	a2,88(sp)
    80005eea:	7686                	ld	a3,96(sp)
    80005eec:	7726                	ld	a4,104(sp)
    80005eee:	77c6                	ld	a5,112(sp)
    80005ef0:	7866                	ld	a6,120(sp)
    80005ef2:	688a                	ld	a7,128(sp)
    80005ef4:	692a                	ld	s2,136(sp)
    80005ef6:	69ca                	ld	s3,144(sp)
    80005ef8:	6a6a                	ld	s4,152(sp)
    80005efa:	7a8a                	ld	s5,160(sp)
    80005efc:	7b2a                	ld	s6,168(sp)
    80005efe:	7bca                	ld	s7,176(sp)
    80005f00:	7c6a                	ld	s8,184(sp)
    80005f02:	6c8e                	ld	s9,192(sp)
    80005f04:	6d2e                	ld	s10,200(sp)
    80005f06:	6dce                	ld	s11,208(sp)
    80005f08:	6e6e                	ld	t3,216(sp)
    80005f0a:	7e8e                	ld	t4,224(sp)
    80005f0c:	7f2e                	ld	t5,232(sp)
    80005f0e:	7fce                	ld	t6,240(sp)
    80005f10:	6111                	addi	sp,sp,256
    80005f12:	10200073          	sret
    80005f16:	00000013          	nop
    80005f1a:	00000013          	nop
    80005f1e:	0001                	nop

0000000080005f20 <timervec>:
    80005f20:	34051573          	csrrw	a0,mscratch,a0
    80005f24:	e10c                	sd	a1,0(a0)
    80005f26:	e510                	sd	a2,8(a0)
    80005f28:	e914                	sd	a3,16(a0)
    80005f2a:	6d0c                	ld	a1,24(a0)
    80005f2c:	7110                	ld	a2,32(a0)
    80005f2e:	6194                	ld	a3,0(a1)
    80005f30:	96b2                	add	a3,a3,a2
    80005f32:	e194                	sd	a3,0(a1)
    80005f34:	4589                	li	a1,2
    80005f36:	14459073          	csrw	sip,a1
    80005f3a:	6914                	ld	a3,16(a0)
    80005f3c:	6510                	ld	a2,8(a0)
    80005f3e:	610c                	ld	a1,0(a0)
    80005f40:	34051573          	csrrw	a0,mscratch,a0
    80005f44:	30200073          	mret
	...

0000000080005f4a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005f4a:	1141                	addi	sp,sp,-16
    80005f4c:	e422                	sd	s0,8(sp)
    80005f4e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005f50:	0c0007b7          	lui	a5,0xc000
    80005f54:	4705                	li	a4,1
    80005f56:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005f58:	c3d8                	sw	a4,4(a5)
}
    80005f5a:	6422                	ld	s0,8(sp)
    80005f5c:	0141                	addi	sp,sp,16
    80005f5e:	8082                	ret

0000000080005f60 <plicinithart>:

void
plicinithart(void)
{
    80005f60:	1141                	addi	sp,sp,-16
    80005f62:	e406                	sd	ra,8(sp)
    80005f64:	e022                	sd	s0,0(sp)
    80005f66:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005f68:	ffffc097          	auipc	ra,0xffffc
    80005f6c:	db2080e7          	jalr	-590(ra) # 80001d1a <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005f70:	0085171b          	slliw	a4,a0,0x8
    80005f74:	0c0027b7          	lui	a5,0xc002
    80005f78:	97ba                	add	a5,a5,a4
    80005f7a:	40200713          	li	a4,1026
    80005f7e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005f82:	00d5151b          	slliw	a0,a0,0xd
    80005f86:	0c2017b7          	lui	a5,0xc201
    80005f8a:	97aa                	add	a5,a5,a0
    80005f8c:	0007a023          	sw	zero,0(a5) # c201000 <_entry-0x73dff000>
}
    80005f90:	60a2                	ld	ra,8(sp)
    80005f92:	6402                	ld	s0,0(sp)
    80005f94:	0141                	addi	sp,sp,16
    80005f96:	8082                	ret

0000000080005f98 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005f98:	1141                	addi	sp,sp,-16
    80005f9a:	e406                	sd	ra,8(sp)
    80005f9c:	e022                	sd	s0,0(sp)
    80005f9e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005fa0:	ffffc097          	auipc	ra,0xffffc
    80005fa4:	d7a080e7          	jalr	-646(ra) # 80001d1a <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005fa8:	00d5151b          	slliw	a0,a0,0xd
    80005fac:	0c2017b7          	lui	a5,0xc201
    80005fb0:	97aa                	add	a5,a5,a0
  return irq;
}
    80005fb2:	43c8                	lw	a0,4(a5)
    80005fb4:	60a2                	ld	ra,8(sp)
    80005fb6:	6402                	ld	s0,0(sp)
    80005fb8:	0141                	addi	sp,sp,16
    80005fba:	8082                	ret

0000000080005fbc <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005fbc:	1101                	addi	sp,sp,-32
    80005fbe:	ec06                	sd	ra,24(sp)
    80005fc0:	e822                	sd	s0,16(sp)
    80005fc2:	e426                	sd	s1,8(sp)
    80005fc4:	1000                	addi	s0,sp,32
    80005fc6:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005fc8:	ffffc097          	auipc	ra,0xffffc
    80005fcc:	d52080e7          	jalr	-686(ra) # 80001d1a <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005fd0:	00d5151b          	slliw	a0,a0,0xd
    80005fd4:	0c2017b7          	lui	a5,0xc201
    80005fd8:	97aa                	add	a5,a5,a0
    80005fda:	c3c4                	sw	s1,4(a5)
}
    80005fdc:	60e2                	ld	ra,24(sp)
    80005fde:	6442                	ld	s0,16(sp)
    80005fe0:	64a2                	ld	s1,8(sp)
    80005fe2:	6105                	addi	sp,sp,32
    80005fe4:	8082                	ret

0000000080005fe6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005fe6:	1141                	addi	sp,sp,-16
    80005fe8:	e406                	sd	ra,8(sp)
    80005fea:	e022                	sd	s0,0(sp)
    80005fec:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005fee:	479d                	li	a5,7
    80005ff0:	06a7c863          	blt	a5,a0,80006060 <free_desc+0x7a>
    panic("free_desc 1");
  if(disk.free[i])
    80005ff4:	0001e717          	auipc	a4,0x1e
    80005ff8:	00c70713          	addi	a4,a4,12 # 80024000 <disk>
    80005ffc:	972a                	add	a4,a4,a0
    80005ffe:	6789                	lui	a5,0x2
    80006000:	97ba                	add	a5,a5,a4
    80006002:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80006006:	e7ad                	bnez	a5,80006070 <free_desc+0x8a>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80006008:	00451793          	slli	a5,a0,0x4
    8000600c:	00020717          	auipc	a4,0x20
    80006010:	ff470713          	addi	a4,a4,-12 # 80026000 <disk+0x2000>
    80006014:	6314                	ld	a3,0(a4)
    80006016:	96be                	add	a3,a3,a5
    80006018:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    8000601c:	6314                	ld	a3,0(a4)
    8000601e:	96be                	add	a3,a3,a5
    80006020:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80006024:	6314                	ld	a3,0(a4)
    80006026:	96be                	add	a3,a3,a5
    80006028:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    8000602c:	6318                	ld	a4,0(a4)
    8000602e:	97ba                	add	a5,a5,a4
    80006030:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80006034:	0001e717          	auipc	a4,0x1e
    80006038:	fcc70713          	addi	a4,a4,-52 # 80024000 <disk>
    8000603c:	972a                	add	a4,a4,a0
    8000603e:	6789                	lui	a5,0x2
    80006040:	97ba                	add	a5,a5,a4
    80006042:	4705                	li	a4,1
    80006044:	00e78c23          	sb	a4,24(a5) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80006048:	00020517          	auipc	a0,0x20
    8000604c:	fd050513          	addi	a0,a0,-48 # 80026018 <disk+0x2018>
    80006050:	ffffc097          	auipc	ra,0xffffc
    80006054:	68e080e7          	jalr	1678(ra) # 800026de <wakeup>
}
    80006058:	60a2                	ld	ra,8(sp)
    8000605a:	6402                	ld	s0,0(sp)
    8000605c:	0141                	addi	sp,sp,16
    8000605e:	8082                	ret
    panic("free_desc 1");
    80006060:	00002517          	auipc	a0,0x2
    80006064:	78050513          	addi	a0,a0,1920 # 800087e0 <syscalls+0x328>
    80006068:	ffffa097          	auipc	ra,0xffffa
    8000606c:	4e4080e7          	jalr	1252(ra) # 8000054c <panic>
    panic("free_desc 2");
    80006070:	00002517          	auipc	a0,0x2
    80006074:	78050513          	addi	a0,a0,1920 # 800087f0 <syscalls+0x338>
    80006078:	ffffa097          	auipc	ra,0xffffa
    8000607c:	4d4080e7          	jalr	1236(ra) # 8000054c <panic>

0000000080006080 <virtio_disk_init>:
{
    80006080:	1101                	addi	sp,sp,-32
    80006082:	ec06                	sd	ra,24(sp)
    80006084:	e822                	sd	s0,16(sp)
    80006086:	e426                	sd	s1,8(sp)
    80006088:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    8000608a:	00002597          	auipc	a1,0x2
    8000608e:	77658593          	addi	a1,a1,1910 # 80008800 <syscalls+0x348>
    80006092:	00020517          	auipc	a0,0x20
    80006096:	09650513          	addi	a0,a0,150 # 80026128 <disk+0x2128>
    8000609a:	ffffb097          	auipc	ra,0xffffb
    8000609e:	de2080e7          	jalr	-542(ra) # 80000e7c <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800060a2:	100017b7          	lui	a5,0x10001
    800060a6:	4398                	lw	a4,0(a5)
    800060a8:	2701                	sext.w	a4,a4
    800060aa:	747277b7          	lui	a5,0x74727
    800060ae:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    800060b2:	0ef71063          	bne	a4,a5,80006192 <virtio_disk_init+0x112>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    800060b6:	100017b7          	lui	a5,0x10001
    800060ba:	43dc                	lw	a5,4(a5)
    800060bc:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800060be:	4705                	li	a4,1
    800060c0:	0ce79963          	bne	a5,a4,80006192 <virtio_disk_init+0x112>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800060c4:	100017b7          	lui	a5,0x10001
    800060c8:	479c                	lw	a5,8(a5)
    800060ca:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    800060cc:	4709                	li	a4,2
    800060ce:	0ce79263          	bne	a5,a4,80006192 <virtio_disk_init+0x112>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    800060d2:	100017b7          	lui	a5,0x10001
    800060d6:	47d8                	lw	a4,12(a5)
    800060d8:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800060da:	554d47b7          	lui	a5,0x554d4
    800060de:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    800060e2:	0af71863          	bne	a4,a5,80006192 <virtio_disk_init+0x112>
  *R(VIRTIO_MMIO_STATUS) = status;
    800060e6:	100017b7          	lui	a5,0x10001
    800060ea:	4705                	li	a4,1
    800060ec:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800060ee:	470d                	li	a4,3
    800060f0:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    800060f2:	4b98                	lw	a4,16(a5)
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    800060f4:	c7ffe6b7          	lui	a3,0xc7ffe
    800060f8:	75f68693          	addi	a3,a3,1887 # ffffffffc7ffe75f <end+0xffffffff47fd6737>
    800060fc:	8f75                	and	a4,a4,a3
    800060fe:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006100:	472d                	li	a4,11
    80006102:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006104:	473d                	li	a4,15
    80006106:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    80006108:	6705                	lui	a4,0x1
    8000610a:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    8000610c:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80006110:	5bdc                	lw	a5,52(a5)
    80006112:	2781                	sext.w	a5,a5
  if(max == 0)
    80006114:	c7d9                	beqz	a5,800061a2 <virtio_disk_init+0x122>
  if(max < NUM)
    80006116:	471d                	li	a4,7
    80006118:	08f77d63          	bgeu	a4,a5,800061b2 <virtio_disk_init+0x132>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    8000611c:	100014b7          	lui	s1,0x10001
    80006120:	47a1                	li	a5,8
    80006122:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80006124:	6609                	lui	a2,0x2
    80006126:	4581                	li	a1,0
    80006128:	0001e517          	auipc	a0,0x1e
    8000612c:	ed850513          	addi	a0,a0,-296 # 80024000 <disk>
    80006130:	ffffb097          	auipc	ra,0xffffb
    80006134:	fb0080e7          	jalr	-80(ra) # 800010e0 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    80006138:	0001e717          	auipc	a4,0x1e
    8000613c:	ec870713          	addi	a4,a4,-312 # 80024000 <disk>
    80006140:	00c75793          	srli	a5,a4,0xc
    80006144:	2781                	sext.w	a5,a5
    80006146:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    80006148:	00020797          	auipc	a5,0x20
    8000614c:	eb878793          	addi	a5,a5,-328 # 80026000 <disk+0x2000>
    80006150:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80006152:	0001e717          	auipc	a4,0x1e
    80006156:	f2e70713          	addi	a4,a4,-210 # 80024080 <disk+0x80>
    8000615a:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    8000615c:	0001f717          	auipc	a4,0x1f
    80006160:	ea470713          	addi	a4,a4,-348 # 80025000 <disk+0x1000>
    80006164:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    80006166:	4705                	li	a4,1
    80006168:	00e78c23          	sb	a4,24(a5)
    8000616c:	00e78ca3          	sb	a4,25(a5)
    80006170:	00e78d23          	sb	a4,26(a5)
    80006174:	00e78da3          	sb	a4,27(a5)
    80006178:	00e78e23          	sb	a4,28(a5)
    8000617c:	00e78ea3          	sb	a4,29(a5)
    80006180:	00e78f23          	sb	a4,30(a5)
    80006184:	00e78fa3          	sb	a4,31(a5)
}
    80006188:	60e2                	ld	ra,24(sp)
    8000618a:	6442                	ld	s0,16(sp)
    8000618c:	64a2                	ld	s1,8(sp)
    8000618e:	6105                	addi	sp,sp,32
    80006190:	8082                	ret
    panic("could not find virtio disk");
    80006192:	00002517          	auipc	a0,0x2
    80006196:	67e50513          	addi	a0,a0,1662 # 80008810 <syscalls+0x358>
    8000619a:	ffffa097          	auipc	ra,0xffffa
    8000619e:	3b2080e7          	jalr	946(ra) # 8000054c <panic>
    panic("virtio disk has no queue 0");
    800061a2:	00002517          	auipc	a0,0x2
    800061a6:	68e50513          	addi	a0,a0,1678 # 80008830 <syscalls+0x378>
    800061aa:	ffffa097          	auipc	ra,0xffffa
    800061ae:	3a2080e7          	jalr	930(ra) # 8000054c <panic>
    panic("virtio disk max queue too short");
    800061b2:	00002517          	auipc	a0,0x2
    800061b6:	69e50513          	addi	a0,a0,1694 # 80008850 <syscalls+0x398>
    800061ba:	ffffa097          	auipc	ra,0xffffa
    800061be:	392080e7          	jalr	914(ra) # 8000054c <panic>

00000000800061c2 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    800061c2:	7119                	addi	sp,sp,-128
    800061c4:	fc86                	sd	ra,120(sp)
    800061c6:	f8a2                	sd	s0,112(sp)
    800061c8:	f4a6                	sd	s1,104(sp)
    800061ca:	f0ca                	sd	s2,96(sp)
    800061cc:	ecce                	sd	s3,88(sp)
    800061ce:	e8d2                	sd	s4,80(sp)
    800061d0:	e4d6                	sd	s5,72(sp)
    800061d2:	e0da                	sd	s6,64(sp)
    800061d4:	fc5e                	sd	s7,56(sp)
    800061d6:	f862                	sd	s8,48(sp)
    800061d8:	f466                	sd	s9,40(sp)
    800061da:	f06a                	sd	s10,32(sp)
    800061dc:	ec6e                	sd	s11,24(sp)
    800061de:	0100                	addi	s0,sp,128
    800061e0:	8aaa                	mv	s5,a0
    800061e2:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    800061e4:	00c52c83          	lw	s9,12(a0)
    800061e8:	001c9c9b          	slliw	s9,s9,0x1
    800061ec:	1c82                	slli	s9,s9,0x20
    800061ee:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    800061f2:	00020517          	auipc	a0,0x20
    800061f6:	f3650513          	addi	a0,a0,-202 # 80026128 <disk+0x2128>
    800061fa:	ffffb097          	auipc	ra,0xffffb
    800061fe:	b06080e7          	jalr	-1274(ra) # 80000d00 <acquire>
  for(int i = 0; i < 3; i++){
    80006202:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006204:	44a1                	li	s1,8
      disk.free[i] = 0;
    80006206:	0001ec17          	auipc	s8,0x1e
    8000620a:	dfac0c13          	addi	s8,s8,-518 # 80024000 <disk>
    8000620e:	6b89                	lui	s7,0x2
  for(int i = 0; i < 3; i++){
    80006210:	4b0d                	li	s6,3
    80006212:	a0ad                	j	8000627c <virtio_disk_rw+0xba>
      disk.free[i] = 0;
    80006214:	00fc0733          	add	a4,s8,a5
    80006218:	975e                	add	a4,a4,s7
    8000621a:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    8000621e:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    80006220:	0207c563          	bltz	a5,8000624a <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80006224:	2905                	addiw	s2,s2,1
    80006226:	0611                	addi	a2,a2,4 # 2004 <_entry-0x7fffdffc>
    80006228:	19690c63          	beq	s2,s6,800063c0 <virtio_disk_rw+0x1fe>
    idx[i] = alloc_desc();
    8000622c:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    8000622e:	00020717          	auipc	a4,0x20
    80006232:	dea70713          	addi	a4,a4,-534 # 80026018 <disk+0x2018>
    80006236:	87ce                	mv	a5,s3
    if(disk.free[i]){
    80006238:	00074683          	lbu	a3,0(a4)
    8000623c:	fee1                	bnez	a3,80006214 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    8000623e:	2785                	addiw	a5,a5,1
    80006240:	0705                	addi	a4,a4,1
    80006242:	fe979be3          	bne	a5,s1,80006238 <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    80006246:	57fd                	li	a5,-1
    80006248:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    8000624a:	01205d63          	blez	s2,80006264 <virtio_disk_rw+0xa2>
    8000624e:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    80006250:	000a2503          	lw	a0,0(s4)
    80006254:	00000097          	auipc	ra,0x0
    80006258:	d92080e7          	jalr	-622(ra) # 80005fe6 <free_desc>
      for(int j = 0; j < i; j++)
    8000625c:	2d85                	addiw	s11,s11,1
    8000625e:	0a11                	addi	s4,s4,4
    80006260:	ff2d98e3          	bne	s11,s2,80006250 <virtio_disk_rw+0x8e>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006264:	00020597          	auipc	a1,0x20
    80006268:	ec458593          	addi	a1,a1,-316 # 80026128 <disk+0x2128>
    8000626c:	00020517          	auipc	a0,0x20
    80006270:	dac50513          	addi	a0,a0,-596 # 80026018 <disk+0x2018>
    80006274:	ffffc097          	auipc	ra,0xffffc
    80006278:	2ea080e7          	jalr	746(ra) # 8000255e <sleep>
  for(int i = 0; i < 3; i++){
    8000627c:	f8040a13          	addi	s4,s0,-128
{
    80006280:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    80006282:	894e                	mv	s2,s3
    80006284:	b765                	j	8000622c <virtio_disk_rw+0x6a>
  disk.desc[idx[0]].next = idx[1];

  disk.desc[idx[1]].addr = (uint64) b->data;
  disk.desc[idx[1]].len = BSIZE;
  if(write)
    disk.desc[idx[1]].flags = 0; // device reads b->data
    80006286:	00020697          	auipc	a3,0x20
    8000628a:	d7a6b683          	ld	a3,-646(a3) # 80026000 <disk+0x2000>
    8000628e:	96ba                	add	a3,a3,a4
    80006290:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80006294:	0001e817          	auipc	a6,0x1e
    80006298:	d6c80813          	addi	a6,a6,-660 # 80024000 <disk>
    8000629c:	00020697          	auipc	a3,0x20
    800062a0:	d6468693          	addi	a3,a3,-668 # 80026000 <disk+0x2000>
    800062a4:	6290                	ld	a2,0(a3)
    800062a6:	963a                	add	a2,a2,a4
    800062a8:	00c65583          	lhu	a1,12(a2)
    800062ac:	0015e593          	ori	a1,a1,1
    800062b0:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[1]].next = idx[2];
    800062b4:	f8842603          	lw	a2,-120(s0)
    800062b8:	628c                	ld	a1,0(a3)
    800062ba:	972e                	add	a4,a4,a1
    800062bc:	00c71723          	sh	a2,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    800062c0:	20050593          	addi	a1,a0,512
    800062c4:	0592                	slli	a1,a1,0x4
    800062c6:	95c2                	add	a1,a1,a6
    800062c8:	577d                	li	a4,-1
    800062ca:	02e58823          	sb	a4,48(a1)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    800062ce:	00461713          	slli	a4,a2,0x4
    800062d2:	6290                	ld	a2,0(a3)
    800062d4:	963a                	add	a2,a2,a4
    800062d6:	03078793          	addi	a5,a5,48
    800062da:	97c2                	add	a5,a5,a6
    800062dc:	e21c                	sd	a5,0(a2)
  disk.desc[idx[2]].len = 1;
    800062de:	629c                	ld	a5,0(a3)
    800062e0:	97ba                	add	a5,a5,a4
    800062e2:	4605                	li	a2,1
    800062e4:	c790                	sw	a2,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800062e6:	629c                	ld	a5,0(a3)
    800062e8:	97ba                	add	a5,a5,a4
    800062ea:	4809                	li	a6,2
    800062ec:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    800062f0:	629c                	ld	a5,0(a3)
    800062f2:	97ba                	add	a5,a5,a4
    800062f4:	00079723          	sh	zero,14(a5)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    800062f8:	00caa223          	sw	a2,4(s5)
  disk.info[idx[0]].b = b;
    800062fc:	0355b423          	sd	s5,40(a1)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006300:	6698                	ld	a4,8(a3)
    80006302:	00275783          	lhu	a5,2(a4)
    80006306:	8b9d                	andi	a5,a5,7
    80006308:	0786                	slli	a5,a5,0x1
    8000630a:	973e                	add	a4,a4,a5
    8000630c:	00a71223          	sh	a0,4(a4)

  __sync_synchronize();
    80006310:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006314:	6698                	ld	a4,8(a3)
    80006316:	00275783          	lhu	a5,2(a4)
    8000631a:	2785                	addiw	a5,a5,1
    8000631c:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006320:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006324:	100017b7          	lui	a5,0x10001
    80006328:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    8000632c:	004aa783          	lw	a5,4(s5)
    80006330:	02c79163          	bne	a5,a2,80006352 <virtio_disk_rw+0x190>
    sleep(b, &disk.vdisk_lock);
    80006334:	00020917          	auipc	s2,0x20
    80006338:	df490913          	addi	s2,s2,-524 # 80026128 <disk+0x2128>
  while(b->disk == 1) {
    8000633c:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    8000633e:	85ca                	mv	a1,s2
    80006340:	8556                	mv	a0,s5
    80006342:	ffffc097          	auipc	ra,0xffffc
    80006346:	21c080e7          	jalr	540(ra) # 8000255e <sleep>
  while(b->disk == 1) {
    8000634a:	004aa783          	lw	a5,4(s5)
    8000634e:	fe9788e3          	beq	a5,s1,8000633e <virtio_disk_rw+0x17c>
  }

  disk.info[idx[0]].b = 0;
    80006352:	f8042903          	lw	s2,-128(s0)
    80006356:	20090713          	addi	a4,s2,512
    8000635a:	0712                	slli	a4,a4,0x4
    8000635c:	0001e797          	auipc	a5,0x1e
    80006360:	ca478793          	addi	a5,a5,-860 # 80024000 <disk>
    80006364:	97ba                	add	a5,a5,a4
    80006366:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    8000636a:	00020997          	auipc	s3,0x20
    8000636e:	c9698993          	addi	s3,s3,-874 # 80026000 <disk+0x2000>
    80006372:	00491713          	slli	a4,s2,0x4
    80006376:	0009b783          	ld	a5,0(s3)
    8000637a:	97ba                	add	a5,a5,a4
    8000637c:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006380:	854a                	mv	a0,s2
    80006382:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006386:	00000097          	auipc	ra,0x0
    8000638a:	c60080e7          	jalr	-928(ra) # 80005fe6 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    8000638e:	8885                	andi	s1,s1,1
    80006390:	f0ed                	bnez	s1,80006372 <virtio_disk_rw+0x1b0>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006392:	00020517          	auipc	a0,0x20
    80006396:	d9650513          	addi	a0,a0,-618 # 80026128 <disk+0x2128>
    8000639a:	ffffb097          	auipc	ra,0xffffb
    8000639e:	a36080e7          	jalr	-1482(ra) # 80000dd0 <release>
}
    800063a2:	70e6                	ld	ra,120(sp)
    800063a4:	7446                	ld	s0,112(sp)
    800063a6:	74a6                	ld	s1,104(sp)
    800063a8:	7906                	ld	s2,96(sp)
    800063aa:	69e6                	ld	s3,88(sp)
    800063ac:	6a46                	ld	s4,80(sp)
    800063ae:	6aa6                	ld	s5,72(sp)
    800063b0:	6b06                	ld	s6,64(sp)
    800063b2:	7be2                	ld	s7,56(sp)
    800063b4:	7c42                	ld	s8,48(sp)
    800063b6:	7ca2                	ld	s9,40(sp)
    800063b8:	7d02                	ld	s10,32(sp)
    800063ba:	6de2                	ld	s11,24(sp)
    800063bc:	6109                	addi	sp,sp,128
    800063be:	8082                	ret
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800063c0:	f8042503          	lw	a0,-128(s0)
    800063c4:	20050793          	addi	a5,a0,512
    800063c8:	0792                	slli	a5,a5,0x4
  if(write)
    800063ca:	0001e817          	auipc	a6,0x1e
    800063ce:	c3680813          	addi	a6,a6,-970 # 80024000 <disk>
    800063d2:	00f80733          	add	a4,a6,a5
    800063d6:	01a036b3          	snez	a3,s10
    800063da:	0ad72423          	sw	a3,168(a4)
  buf0->reserved = 0;
    800063de:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    800063e2:	0b973823          	sd	s9,176(a4)
  disk.desc[idx[0]].addr = (uint64) buf0;
    800063e6:	7679                	lui	a2,0xffffe
    800063e8:	963e                	add	a2,a2,a5
    800063ea:	00020697          	auipc	a3,0x20
    800063ee:	c1668693          	addi	a3,a3,-1002 # 80026000 <disk+0x2000>
    800063f2:	6298                	ld	a4,0(a3)
    800063f4:	9732                	add	a4,a4,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800063f6:	0a878593          	addi	a1,a5,168
    800063fa:	95c2                	add	a1,a1,a6
  disk.desc[idx[0]].addr = (uint64) buf0;
    800063fc:	e30c                	sd	a1,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    800063fe:	6298                	ld	a4,0(a3)
    80006400:	9732                	add	a4,a4,a2
    80006402:	45c1                	li	a1,16
    80006404:	c70c                	sw	a1,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006406:	6298                	ld	a4,0(a3)
    80006408:	9732                	add	a4,a4,a2
    8000640a:	4585                	li	a1,1
    8000640c:	00b71623          	sh	a1,12(a4)
  disk.desc[idx[0]].next = idx[1];
    80006410:	f8442703          	lw	a4,-124(s0)
    80006414:	628c                	ld	a1,0(a3)
    80006416:	962e                	add	a2,a2,a1
    80006418:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd5fe6>
  disk.desc[idx[1]].addr = (uint64) b->data;
    8000641c:	0712                	slli	a4,a4,0x4
    8000641e:	6290                	ld	a2,0(a3)
    80006420:	963a                	add	a2,a2,a4
    80006422:	060a8593          	addi	a1,s5,96
    80006426:	e20c                	sd	a1,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    80006428:	6294                	ld	a3,0(a3)
    8000642a:	96ba                	add	a3,a3,a4
    8000642c:	40000613          	li	a2,1024
    80006430:	c690                	sw	a2,8(a3)
  if(write)
    80006432:	e40d1ae3          	bnez	s10,80006286 <virtio_disk_rw+0xc4>
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    80006436:	00020697          	auipc	a3,0x20
    8000643a:	bca6b683          	ld	a3,-1078(a3) # 80026000 <disk+0x2000>
    8000643e:	96ba                	add	a3,a3,a4
    80006440:	4609                	li	a2,2
    80006442:	00c69623          	sh	a2,12(a3)
    80006446:	b5b9                	j	80006294 <virtio_disk_rw+0xd2>

0000000080006448 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006448:	1101                	addi	sp,sp,-32
    8000644a:	ec06                	sd	ra,24(sp)
    8000644c:	e822                	sd	s0,16(sp)
    8000644e:	e426                	sd	s1,8(sp)
    80006450:	e04a                	sd	s2,0(sp)
    80006452:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006454:	00020517          	auipc	a0,0x20
    80006458:	cd450513          	addi	a0,a0,-812 # 80026128 <disk+0x2128>
    8000645c:	ffffb097          	auipc	ra,0xffffb
    80006460:	8a4080e7          	jalr	-1884(ra) # 80000d00 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006464:	10001737          	lui	a4,0x10001
    80006468:	533c                	lw	a5,96(a4)
    8000646a:	8b8d                	andi	a5,a5,3
    8000646c:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    8000646e:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006472:	00020797          	auipc	a5,0x20
    80006476:	b8e78793          	addi	a5,a5,-1138 # 80026000 <disk+0x2000>
    8000647a:	6b94                	ld	a3,16(a5)
    8000647c:	0207d703          	lhu	a4,32(a5)
    80006480:	0026d783          	lhu	a5,2(a3)
    80006484:	06f70163          	beq	a4,a5,800064e6 <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006488:	0001e917          	auipc	s2,0x1e
    8000648c:	b7890913          	addi	s2,s2,-1160 # 80024000 <disk>
    80006490:	00020497          	auipc	s1,0x20
    80006494:	b7048493          	addi	s1,s1,-1168 # 80026000 <disk+0x2000>
    __sync_synchronize();
    80006498:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    8000649c:	6898                	ld	a4,16(s1)
    8000649e:	0204d783          	lhu	a5,32(s1)
    800064a2:	8b9d                	andi	a5,a5,7
    800064a4:	078e                	slli	a5,a5,0x3
    800064a6:	97ba                	add	a5,a5,a4
    800064a8:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    800064aa:	20078713          	addi	a4,a5,512
    800064ae:	0712                	slli	a4,a4,0x4
    800064b0:	974a                	add	a4,a4,s2
    800064b2:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    800064b6:	e731                	bnez	a4,80006502 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    800064b8:	20078793          	addi	a5,a5,512
    800064bc:	0792                	slli	a5,a5,0x4
    800064be:	97ca                	add	a5,a5,s2
    800064c0:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    800064c2:	00052223          	sw	zero,4(a0)
    wakeup(b);
    800064c6:	ffffc097          	auipc	ra,0xffffc
    800064ca:	218080e7          	jalr	536(ra) # 800026de <wakeup>

    disk.used_idx += 1;
    800064ce:	0204d783          	lhu	a5,32(s1)
    800064d2:	2785                	addiw	a5,a5,1
    800064d4:	17c2                	slli	a5,a5,0x30
    800064d6:	93c1                	srli	a5,a5,0x30
    800064d8:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    800064dc:	6898                	ld	a4,16(s1)
    800064de:	00275703          	lhu	a4,2(a4)
    800064e2:	faf71be3          	bne	a4,a5,80006498 <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    800064e6:	00020517          	auipc	a0,0x20
    800064ea:	c4250513          	addi	a0,a0,-958 # 80026128 <disk+0x2128>
    800064ee:	ffffb097          	auipc	ra,0xffffb
    800064f2:	8e2080e7          	jalr	-1822(ra) # 80000dd0 <release>
}
    800064f6:	60e2                	ld	ra,24(sp)
    800064f8:	6442                	ld	s0,16(sp)
    800064fa:	64a2                	ld	s1,8(sp)
    800064fc:	6902                	ld	s2,0(sp)
    800064fe:	6105                	addi	sp,sp,32
    80006500:	8082                	ret
      panic("virtio_disk_intr status");
    80006502:	00002517          	auipc	a0,0x2
    80006506:	36e50513          	addi	a0,a0,878 # 80008870 <syscalls+0x3b8>
    8000650a:	ffffa097          	auipc	ra,0xffffa
    8000650e:	042080e7          	jalr	66(ra) # 8000054c <panic>

0000000080006512 <statswrite>:
int statscopyin(char*, int);
int statslock(char*, int);
  
int
statswrite(int user_src, uint64 src, int n)
{
    80006512:	1141                	addi	sp,sp,-16
    80006514:	e422                	sd	s0,8(sp)
    80006516:	0800                	addi	s0,sp,16
  return -1;
}
    80006518:	557d                	li	a0,-1
    8000651a:	6422                	ld	s0,8(sp)
    8000651c:	0141                	addi	sp,sp,16
    8000651e:	8082                	ret

0000000080006520 <statsread>:

int
statsread(int user_dst, uint64 dst, int n)
{
    80006520:	7179                	addi	sp,sp,-48
    80006522:	f406                	sd	ra,40(sp)
    80006524:	f022                	sd	s0,32(sp)
    80006526:	ec26                	sd	s1,24(sp)
    80006528:	e84a                	sd	s2,16(sp)
    8000652a:	e44e                	sd	s3,8(sp)
    8000652c:	e052                	sd	s4,0(sp)
    8000652e:	1800                	addi	s0,sp,48
    80006530:	892a                	mv	s2,a0
    80006532:	89ae                	mv	s3,a1
    80006534:	84b2                	mv	s1,a2
  int m;

  acquire(&stats.lock);
    80006536:	00021517          	auipc	a0,0x21
    8000653a:	aca50513          	addi	a0,a0,-1334 # 80027000 <stats>
    8000653e:	ffffa097          	auipc	ra,0xffffa
    80006542:	7c2080e7          	jalr	1986(ra) # 80000d00 <acquire>

  if(stats.sz == 0) {
    80006546:	00022797          	auipc	a5,0x22
    8000654a:	ada7a783          	lw	a5,-1318(a5) # 80028020 <stats+0x1020>
    8000654e:	cbb5                	beqz	a5,800065c2 <statsread+0xa2>
#endif
#ifdef LAB_LOCK
    stats.sz = statslock(stats.buf, BUFSZ);
#endif
  }
  m = stats.sz - stats.off;
    80006550:	00022797          	auipc	a5,0x22
    80006554:	ab078793          	addi	a5,a5,-1360 # 80028000 <stats+0x1000>
    80006558:	53d8                	lw	a4,36(a5)
    8000655a:	539c                	lw	a5,32(a5)
    8000655c:	9f99                	subw	a5,a5,a4
    8000655e:	0007869b          	sext.w	a3,a5

  if (m > 0) {
    80006562:	06d05e63          	blez	a3,800065de <statsread+0xbe>
    if(m > n)
    80006566:	8a3e                	mv	s4,a5
    80006568:	00d4d363          	bge	s1,a3,8000656e <statsread+0x4e>
    8000656c:	8a26                	mv	s4,s1
    8000656e:	000a049b          	sext.w	s1,s4
      m  = n;
    if(either_copyout(user_dst, dst, stats.buf+stats.off, m) != -1) {
    80006572:	86a6                	mv	a3,s1
    80006574:	00021617          	auipc	a2,0x21
    80006578:	aac60613          	addi	a2,a2,-1364 # 80027020 <stats+0x20>
    8000657c:	963a                	add	a2,a2,a4
    8000657e:	85ce                	mv	a1,s3
    80006580:	854a                	mv	a0,s2
    80006582:	ffffc097          	auipc	ra,0xffffc
    80006586:	236080e7          	jalr	566(ra) # 800027b8 <either_copyout>
    8000658a:	57fd                	li	a5,-1
    8000658c:	00f50a63          	beq	a0,a5,800065a0 <statsread+0x80>
      stats.off += m;
    80006590:	00022717          	auipc	a4,0x22
    80006594:	a7070713          	addi	a4,a4,-1424 # 80028000 <stats+0x1000>
    80006598:	535c                	lw	a5,36(a4)
    8000659a:	00fa07bb          	addw	a5,s4,a5
    8000659e:	d35c                	sw	a5,36(a4)
  } else {
    m = -1;
    stats.sz = 0;
    stats.off = 0;
  }
  release(&stats.lock);
    800065a0:	00021517          	auipc	a0,0x21
    800065a4:	a6050513          	addi	a0,a0,-1440 # 80027000 <stats>
    800065a8:	ffffb097          	auipc	ra,0xffffb
    800065ac:	828080e7          	jalr	-2008(ra) # 80000dd0 <release>
  return m;
}
    800065b0:	8526                	mv	a0,s1
    800065b2:	70a2                	ld	ra,40(sp)
    800065b4:	7402                	ld	s0,32(sp)
    800065b6:	64e2                	ld	s1,24(sp)
    800065b8:	6942                	ld	s2,16(sp)
    800065ba:	69a2                	ld	s3,8(sp)
    800065bc:	6a02                	ld	s4,0(sp)
    800065be:	6145                	addi	sp,sp,48
    800065c0:	8082                	ret
    stats.sz = statslock(stats.buf, BUFSZ);
    800065c2:	6585                	lui	a1,0x1
    800065c4:	00021517          	auipc	a0,0x21
    800065c8:	a5c50513          	addi	a0,a0,-1444 # 80027020 <stats+0x20>
    800065cc:	ffffb097          	auipc	ra,0xffffb
    800065d0:	95e080e7          	jalr	-1698(ra) # 80000f2a <statslock>
    800065d4:	00022797          	auipc	a5,0x22
    800065d8:	a4a7a623          	sw	a0,-1460(a5) # 80028020 <stats+0x1020>
    800065dc:	bf95                	j	80006550 <statsread+0x30>
    stats.sz = 0;
    800065de:	00022797          	auipc	a5,0x22
    800065e2:	a2278793          	addi	a5,a5,-1502 # 80028000 <stats+0x1000>
    800065e6:	0207a023          	sw	zero,32(a5)
    stats.off = 0;
    800065ea:	0207a223          	sw	zero,36(a5)
    m = -1;
    800065ee:	54fd                	li	s1,-1
    800065f0:	bf45                	j	800065a0 <statsread+0x80>

00000000800065f2 <statsinit>:

void
statsinit(void)
{
    800065f2:	1141                	addi	sp,sp,-16
    800065f4:	e406                	sd	ra,8(sp)
    800065f6:	e022                	sd	s0,0(sp)
    800065f8:	0800                	addi	s0,sp,16
  initlock(&stats.lock, "stats");
    800065fa:	00002597          	auipc	a1,0x2
    800065fe:	28e58593          	addi	a1,a1,654 # 80008888 <syscalls+0x3d0>
    80006602:	00021517          	auipc	a0,0x21
    80006606:	9fe50513          	addi	a0,a0,-1538 # 80027000 <stats>
    8000660a:	ffffb097          	auipc	ra,0xffffb
    8000660e:	872080e7          	jalr	-1934(ra) # 80000e7c <initlock>

  devsw[STATS].read = statsread;
    80006612:	0001c797          	auipc	a5,0x1c
    80006616:	28678793          	addi	a5,a5,646 # 80022898 <devsw>
    8000661a:	00000717          	auipc	a4,0x0
    8000661e:	f0670713          	addi	a4,a4,-250 # 80006520 <statsread>
    80006622:	f398                	sd	a4,32(a5)
  devsw[STATS].write = statswrite;
    80006624:	00000717          	auipc	a4,0x0
    80006628:	eee70713          	addi	a4,a4,-274 # 80006512 <statswrite>
    8000662c:	f798                	sd	a4,40(a5)
}
    8000662e:	60a2                	ld	ra,8(sp)
    80006630:	6402                	ld	s0,0(sp)
    80006632:	0141                	addi	sp,sp,16
    80006634:	8082                	ret

0000000080006636 <sprintint>:
  return 1;
}

static int
sprintint(char *s, int xx, int base, int sign)
{
    80006636:	1101                	addi	sp,sp,-32
    80006638:	ec22                	sd	s0,24(sp)
    8000663a:	1000                	addi	s0,sp,32
    8000663c:	882a                	mv	a6,a0
  char buf[16];
  int i, n;
  uint x;

  if(sign && (sign = xx < 0))
    8000663e:	c299                	beqz	a3,80006644 <sprintint+0xe>
    80006640:	0805c263          	bltz	a1,800066c4 <sprintint+0x8e>
    x = -xx;
  else
    x = xx;
    80006644:	2581                	sext.w	a1,a1
    80006646:	4301                	li	t1,0

  i = 0;
    80006648:	fe040713          	addi	a4,s0,-32
    8000664c:	4501                	li	a0,0
  do {
    buf[i++] = digits[x % base];
    8000664e:	2601                	sext.w	a2,a2
    80006650:	00002697          	auipc	a3,0x2
    80006654:	24068693          	addi	a3,a3,576 # 80008890 <digits>
    80006658:	88aa                	mv	a7,a0
    8000665a:	2505                	addiw	a0,a0,1
    8000665c:	02c5f7bb          	remuw	a5,a1,a2
    80006660:	1782                	slli	a5,a5,0x20
    80006662:	9381                	srli	a5,a5,0x20
    80006664:	97b6                	add	a5,a5,a3
    80006666:	0007c783          	lbu	a5,0(a5)
    8000666a:	00f70023          	sb	a5,0(a4)
  } while((x /= base) != 0);
    8000666e:	0005879b          	sext.w	a5,a1
    80006672:	02c5d5bb          	divuw	a1,a1,a2
    80006676:	0705                	addi	a4,a4,1
    80006678:	fec7f0e3          	bgeu	a5,a2,80006658 <sprintint+0x22>

  if(sign)
    8000667c:	00030b63          	beqz	t1,80006692 <sprintint+0x5c>
    buf[i++] = '-';
    80006680:	ff050793          	addi	a5,a0,-16
    80006684:	97a2                	add	a5,a5,s0
    80006686:	02d00713          	li	a4,45
    8000668a:	fee78823          	sb	a4,-16(a5)
    8000668e:	0028851b          	addiw	a0,a7,2

  n = 0;
  while(--i >= 0)
    80006692:	02a05d63          	blez	a0,800066cc <sprintint+0x96>
    80006696:	fe040793          	addi	a5,s0,-32
    8000669a:	00a78733          	add	a4,a5,a0
    8000669e:	87c2                	mv	a5,a6
    800066a0:	00180613          	addi	a2,a6,1
    800066a4:	fff5069b          	addiw	a3,a0,-1
    800066a8:	1682                	slli	a3,a3,0x20
    800066aa:	9281                	srli	a3,a3,0x20
    800066ac:	9636                	add	a2,a2,a3
  *s = c;
    800066ae:	fff74683          	lbu	a3,-1(a4)
    800066b2:	00d78023          	sb	a3,0(a5)
  while(--i >= 0)
    800066b6:	177d                	addi	a4,a4,-1
    800066b8:	0785                	addi	a5,a5,1
    800066ba:	fec79ae3          	bne	a5,a2,800066ae <sprintint+0x78>
    n += sputc(s+n, buf[i]);
  return n;
}
    800066be:	6462                	ld	s0,24(sp)
    800066c0:	6105                	addi	sp,sp,32
    800066c2:	8082                	ret
    x = -xx;
    800066c4:	40b005bb          	negw	a1,a1
  if(sign && (sign = xx < 0))
    800066c8:	4305                	li	t1,1
    x = -xx;
    800066ca:	bfbd                	j	80006648 <sprintint+0x12>
  while(--i >= 0)
    800066cc:	4501                	li	a0,0
    800066ce:	bfc5                	j	800066be <sprintint+0x88>

00000000800066d0 <snprintf>:

int
snprintf(char *buf, int sz, char *fmt, ...)
{
    800066d0:	7135                	addi	sp,sp,-160
    800066d2:	f486                	sd	ra,104(sp)
    800066d4:	f0a2                	sd	s0,96(sp)
    800066d6:	eca6                	sd	s1,88(sp)
    800066d8:	e8ca                	sd	s2,80(sp)
    800066da:	e4ce                	sd	s3,72(sp)
    800066dc:	e0d2                	sd	s4,64(sp)
    800066de:	fc56                	sd	s5,56(sp)
    800066e0:	f85a                	sd	s6,48(sp)
    800066e2:	f45e                	sd	s7,40(sp)
    800066e4:	f062                	sd	s8,32(sp)
    800066e6:	ec66                	sd	s9,24(sp)
    800066e8:	e86a                	sd	s10,16(sp)
    800066ea:	1880                	addi	s0,sp,112
    800066ec:	e414                	sd	a3,8(s0)
    800066ee:	e818                	sd	a4,16(s0)
    800066f0:	ec1c                	sd	a5,24(s0)
    800066f2:	03043023          	sd	a6,32(s0)
    800066f6:	03143423          	sd	a7,40(s0)
  va_list ap;
  int i, c;
  int off = 0;
  char *s;

  if (fmt == 0)
    800066fa:	c61d                	beqz	a2,80006728 <snprintf+0x58>
    800066fc:	8baa                	mv	s7,a0
    800066fe:	89ae                	mv	s3,a1
    80006700:	8a32                	mv	s4,a2
    panic("null fmt");

  va_start(ap, fmt);
    80006702:	00840793          	addi	a5,s0,8
    80006706:	f8f43c23          	sd	a5,-104(s0)
  int off = 0;
    8000670a:	4481                	li	s1,0
  for(i = 0; off < sz && (c = fmt[i] & 0xff) != 0; i++){
    8000670c:	4901                	li	s2,0
    8000670e:	02b05563          	blez	a1,80006738 <snprintf+0x68>
    if(c != '%'){
    80006712:	02500a93          	li	s5,37
      continue;
    }
    c = fmt[++i] & 0xff;
    if(c == 0)
      break;
    switch(c){
    80006716:	07300b13          	li	s6,115
      off += sprintint(buf+off, va_arg(ap, int), 16, 1);
      break;
    case 's':
      if((s = va_arg(ap, char*)) == 0)
        s = "(null)";
      for(; *s && off < sz; s++)
    8000671a:	02800d13          	li	s10,40
    switch(c){
    8000671e:	07800c93          	li	s9,120
    80006722:	06400c13          	li	s8,100
    80006726:	a01d                	j	8000674c <snprintf+0x7c>
    panic("null fmt");
    80006728:	00002517          	auipc	a0,0x2
    8000672c:	90050513          	addi	a0,a0,-1792 # 80008028 <etext+0x28>
    80006730:	ffffa097          	auipc	ra,0xffffa
    80006734:	e1c080e7          	jalr	-484(ra) # 8000054c <panic>
  int off = 0;
    80006738:	4481                	li	s1,0
    8000673a:	a875                	j	800067f6 <snprintf+0x126>
  *s = c;
    8000673c:	009b8733          	add	a4,s7,s1
    80006740:	00f70023          	sb	a5,0(a4)
      off += sputc(buf+off, c);
    80006744:	2485                	addiw	s1,s1,1
  for(i = 0; off < sz && (c = fmt[i] & 0xff) != 0; i++){
    80006746:	2905                	addiw	s2,s2,1
    80006748:	0b34d763          	bge	s1,s3,800067f6 <snprintf+0x126>
    8000674c:	012a07b3          	add	a5,s4,s2
    80006750:	0007c783          	lbu	a5,0(a5)
    80006754:	0007871b          	sext.w	a4,a5
    80006758:	cfd9                	beqz	a5,800067f6 <snprintf+0x126>
    if(c != '%'){
    8000675a:	ff5711e3          	bne	a4,s5,8000673c <snprintf+0x6c>
    c = fmt[++i] & 0xff;
    8000675e:	2905                	addiw	s2,s2,1
    80006760:	012a07b3          	add	a5,s4,s2
    80006764:	0007c783          	lbu	a5,0(a5)
    if(c == 0)
    80006768:	c7d9                	beqz	a5,800067f6 <snprintf+0x126>
    switch(c){
    8000676a:	05678c63          	beq	a5,s6,800067c2 <snprintf+0xf2>
    8000676e:	02fb6763          	bltu	s6,a5,8000679c <snprintf+0xcc>
    80006772:	0b578763          	beq	a5,s5,80006820 <snprintf+0x150>
    80006776:	0b879b63          	bne	a5,s8,8000682c <snprintf+0x15c>
      off += sprintint(buf+off, va_arg(ap, int), 10, 1);
    8000677a:	f9843783          	ld	a5,-104(s0)
    8000677e:	00878713          	addi	a4,a5,8
    80006782:	f8e43c23          	sd	a4,-104(s0)
    80006786:	4685                	li	a3,1
    80006788:	4629                	li	a2,10
    8000678a:	438c                	lw	a1,0(a5)
    8000678c:	009b8533          	add	a0,s7,s1
    80006790:	00000097          	auipc	ra,0x0
    80006794:	ea6080e7          	jalr	-346(ra) # 80006636 <sprintint>
    80006798:	9ca9                	addw	s1,s1,a0
      break;
    8000679a:	b775                	j	80006746 <snprintf+0x76>
    switch(c){
    8000679c:	09979863          	bne	a5,s9,8000682c <snprintf+0x15c>
      off += sprintint(buf+off, va_arg(ap, int), 16, 1);
    800067a0:	f9843783          	ld	a5,-104(s0)
    800067a4:	00878713          	addi	a4,a5,8
    800067a8:	f8e43c23          	sd	a4,-104(s0)
    800067ac:	4685                	li	a3,1
    800067ae:	4641                	li	a2,16
    800067b0:	438c                	lw	a1,0(a5)
    800067b2:	009b8533          	add	a0,s7,s1
    800067b6:	00000097          	auipc	ra,0x0
    800067ba:	e80080e7          	jalr	-384(ra) # 80006636 <sprintint>
    800067be:	9ca9                	addw	s1,s1,a0
      break;
    800067c0:	b759                	j	80006746 <snprintf+0x76>
      if((s = va_arg(ap, char*)) == 0)
    800067c2:	f9843783          	ld	a5,-104(s0)
    800067c6:	00878713          	addi	a4,a5,8
    800067ca:	f8e43c23          	sd	a4,-104(s0)
    800067ce:	639c                	ld	a5,0(a5)
    800067d0:	c3b1                	beqz	a5,80006814 <snprintf+0x144>
      for(; *s && off < sz; s++)
    800067d2:	0007c703          	lbu	a4,0(a5)
    800067d6:	db25                	beqz	a4,80006746 <snprintf+0x76>
    800067d8:	0734d563          	bge	s1,s3,80006842 <snprintf+0x172>
    800067dc:	009b86b3          	add	a3,s7,s1
  *s = c;
    800067e0:	00e68023          	sb	a4,0(a3)
        off += sputc(buf+off, *s);
    800067e4:	2485                	addiw	s1,s1,1
      for(; *s && off < sz; s++)
    800067e6:	0785                	addi	a5,a5,1
    800067e8:	0007c703          	lbu	a4,0(a5)
    800067ec:	df29                	beqz	a4,80006746 <snprintf+0x76>
    800067ee:	0685                	addi	a3,a3,1
    800067f0:	fe9998e3          	bne	s3,s1,800067e0 <snprintf+0x110>
  int off = 0;
    800067f4:	84ce                	mv	s1,s3
      off += sputc(buf+off, c);
      break;
    }
  }
  return off;
}
    800067f6:	8526                	mv	a0,s1
    800067f8:	70a6                	ld	ra,104(sp)
    800067fa:	7406                	ld	s0,96(sp)
    800067fc:	64e6                	ld	s1,88(sp)
    800067fe:	6946                	ld	s2,80(sp)
    80006800:	69a6                	ld	s3,72(sp)
    80006802:	6a06                	ld	s4,64(sp)
    80006804:	7ae2                	ld	s5,56(sp)
    80006806:	7b42                	ld	s6,48(sp)
    80006808:	7ba2                	ld	s7,40(sp)
    8000680a:	7c02                	ld	s8,32(sp)
    8000680c:	6ce2                	ld	s9,24(sp)
    8000680e:	6d42                	ld	s10,16(sp)
    80006810:	610d                	addi	sp,sp,160
    80006812:	8082                	ret
        s = "(null)";
    80006814:	00002797          	auipc	a5,0x2
    80006818:	80c78793          	addi	a5,a5,-2036 # 80008020 <etext+0x20>
      for(; *s && off < sz; s++)
    8000681c:	876a                	mv	a4,s10
    8000681e:	bf6d                	j	800067d8 <snprintf+0x108>
  *s = c;
    80006820:	009b87b3          	add	a5,s7,s1
    80006824:	01578023          	sb	s5,0(a5)
      off += sputc(buf+off, '%');
    80006828:	2485                	addiw	s1,s1,1
      break;
    8000682a:	bf31                	j	80006746 <snprintf+0x76>
  *s = c;
    8000682c:	009b8733          	add	a4,s7,s1
    80006830:	01570023          	sb	s5,0(a4)
      off += sputc(buf+off, c);
    80006834:	0014871b          	addiw	a4,s1,1
  *s = c;
    80006838:	975e                	add	a4,a4,s7
    8000683a:	00f70023          	sb	a5,0(a4)
      off += sputc(buf+off, c);
    8000683e:	2489                	addiw	s1,s1,2
      break;
    80006840:	b719                	j	80006746 <snprintf+0x76>
      for(; *s && off < sz; s++)
    80006842:	89a6                	mv	s3,s1
    80006844:	bf45                	j	800067f4 <snprintf+0x124>
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
