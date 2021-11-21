
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	18010113          	addi	sp,sp,384 # 80009180 <stack0>
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
    80000054:	ff070713          	addi	a4,a4,-16 # 80009040 <timer_scratch>
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
    80000066:	20e78793          	addi	a5,a5,526 # 80006270 <timervec>
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
    8000009a:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd77ff>
    8000009e:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a0:	6705                	lui	a4,0x1
    800000a2:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a6:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000a8:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ac:	00001797          	auipc	a5,0x1
    800000b0:	dc678793          	addi	a5,a5,-570 # 80000e72 <main>
    800000b4:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000b8:	4781                	li	a5,0
    800000ba:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000be:	67c1                	lui	a5,0x10
    800000c0:	17fd                	addi	a5,a5,-1
    800000c2:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c6:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000ca:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000ce:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d2:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000d6:	57fd                	li	a5,-1
    800000d8:	83a9                	srli	a5,a5,0xa
    800000da:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000de:	47bd                	li	a5,15
    800000e0:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000e4:	00000097          	auipc	ra,0x0
    800000e8:	f38080e7          	jalr	-200(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000ec:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000f0:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000f2:	823e                	mv	tp,a5
  asm volatile("mret");
    800000f4:	30200073          	mret
}
    800000f8:	60a2                	ld	ra,8(sp)
    800000fa:	6402                	ld	s0,0(sp)
    800000fc:	0141                	addi	sp,sp,16
    800000fe:	8082                	ret

0000000080000100 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    80000100:	715d                	addi	sp,sp,-80
    80000102:	e486                	sd	ra,72(sp)
    80000104:	e0a2                	sd	s0,64(sp)
    80000106:	fc26                	sd	s1,56(sp)
    80000108:	f84a                	sd	s2,48(sp)
    8000010a:	f44e                	sd	s3,40(sp)
    8000010c:	f052                	sd	s4,32(sp)
    8000010e:	ec56                	sd	s5,24(sp)
    80000110:	0880                	addi	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    80000112:	04c05763          	blez	a2,80000160 <consolewrite+0x60>
    80000116:	8a2a                	mv	s4,a0
    80000118:	84ae                	mv	s1,a1
    8000011a:	89b2                	mv	s3,a2
    8000011c:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    8000011e:	5afd                	li	s5,-1
    80000120:	4685                	li	a3,1
    80000122:	8626                	mv	a2,s1
    80000124:	85d2                	mv	a1,s4
    80000126:	fbf40513          	addi	a0,s0,-65
    8000012a:	00002097          	auipc	ra,0x2
    8000012e:	734080e7          	jalr	1844(ra) # 8000285e <either_copyin>
    80000132:	01550d63          	beq	a0,s5,8000014c <consolewrite+0x4c>
      break;
    uartputc(c);
    80000136:	fbf44503          	lbu	a0,-65(s0)
    8000013a:	00000097          	auipc	ra,0x0
    8000013e:	77e080e7          	jalr	1918(ra) # 800008b8 <uartputc>
  for(i = 0; i < n; i++){
    80000142:	2905                	addiw	s2,s2,1
    80000144:	0485                	addi	s1,s1,1
    80000146:	fd299de3          	bne	s3,s2,80000120 <consolewrite+0x20>
    8000014a:	894e                	mv	s2,s3
  }

  return i;
}
    8000014c:	854a                	mv	a0,s2
    8000014e:	60a6                	ld	ra,72(sp)
    80000150:	6406                	ld	s0,64(sp)
    80000152:	74e2                	ld	s1,56(sp)
    80000154:	7942                	ld	s2,48(sp)
    80000156:	79a2                	ld	s3,40(sp)
    80000158:	7a02                	ld	s4,32(sp)
    8000015a:	6ae2                	ld	s5,24(sp)
    8000015c:	6161                	addi	sp,sp,80
    8000015e:	8082                	ret
  for(i = 0; i < n; i++){
    80000160:	4901                	li	s2,0
    80000162:	b7ed                	j	8000014c <consolewrite+0x4c>

0000000080000164 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000164:	7159                	addi	sp,sp,-112
    80000166:	f486                	sd	ra,104(sp)
    80000168:	f0a2                	sd	s0,96(sp)
    8000016a:	eca6                	sd	s1,88(sp)
    8000016c:	e8ca                	sd	s2,80(sp)
    8000016e:	e4ce                	sd	s3,72(sp)
    80000170:	e0d2                	sd	s4,64(sp)
    80000172:	fc56                	sd	s5,56(sp)
    80000174:	f85a                	sd	s6,48(sp)
    80000176:	f45e                	sd	s7,40(sp)
    80000178:	f062                	sd	s8,32(sp)
    8000017a:	ec66                	sd	s9,24(sp)
    8000017c:	e86a                	sd	s10,16(sp)
    8000017e:	1880                	addi	s0,sp,112
    80000180:	8aaa                	mv	s5,a0
    80000182:	8a2e                	mv	s4,a1
    80000184:	89b2                	mv	s3,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000186:	00060b1b          	sext.w	s6,a2
  acquire(&cons.lock);
    8000018a:	00011517          	auipc	a0,0x11
    8000018e:	ff650513          	addi	a0,a0,-10 # 80011180 <cons>
    80000192:	00001097          	auipc	ra,0x1
    80000196:	a3e080e7          	jalr	-1474(ra) # 80000bd0 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019a:	00011497          	auipc	s1,0x11
    8000019e:	fe648493          	addi	s1,s1,-26 # 80011180 <cons>
      if(myproc()->killed){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a2:	00011917          	auipc	s2,0x11
    800001a6:	07690913          	addi	s2,s2,118 # 80011218 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF];

    if(c == C('D')){  // end-of-file
    800001aa:	4b91                	li	s7,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001ac:	5c7d                	li	s8,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001ae:	4ca9                	li	s9,10
  while(n > 0){
    800001b0:	07305863          	blez	s3,80000220 <consoleread+0xbc>
    while(cons.r == cons.w){
    800001b4:	0984a783          	lw	a5,152(s1)
    800001b8:	09c4a703          	lw	a4,156(s1)
    800001bc:	02f71463          	bne	a4,a5,800001e4 <consoleread+0x80>
      if(myproc()->killed){
    800001c0:	00001097          	auipc	ra,0x1
    800001c4:	7d6080e7          	jalr	2006(ra) # 80001996 <myproc>
    800001c8:	551c                	lw	a5,40(a0)
    800001ca:	e7b5                	bnez	a5,80000236 <consoleread+0xd2>
      sleep(&cons.r, &cons.lock);
    800001cc:	85a6                	mv	a1,s1
    800001ce:	854a                	mv	a0,s2
    800001d0:	00002097          	auipc	ra,0x2
    800001d4:	10c080e7          	jalr	268(ra) # 800022dc <sleep>
    while(cons.r == cons.w){
    800001d8:	0984a783          	lw	a5,152(s1)
    800001dc:	09c4a703          	lw	a4,156(s1)
    800001e0:	fef700e3          	beq	a4,a5,800001c0 <consoleread+0x5c>
    c = cons.buf[cons.r++ % INPUT_BUF];
    800001e4:	0017871b          	addiw	a4,a5,1
    800001e8:	08e4ac23          	sw	a4,152(s1)
    800001ec:	07f7f713          	andi	a4,a5,127
    800001f0:	9726                	add	a4,a4,s1
    800001f2:	01874703          	lbu	a4,24(a4)
    800001f6:	00070d1b          	sext.w	s10,a4
    if(c == C('D')){  // end-of-file
    800001fa:	077d0563          	beq	s10,s7,80000264 <consoleread+0x100>
    cbuf = c;
    800001fe:	f8e40fa3          	sb	a4,-97(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000202:	4685                	li	a3,1
    80000204:	f9f40613          	addi	a2,s0,-97
    80000208:	85d2                	mv	a1,s4
    8000020a:	8556                	mv	a0,s5
    8000020c:	00002097          	auipc	ra,0x2
    80000210:	5fc080e7          	jalr	1532(ra) # 80002808 <either_copyout>
    80000214:	01850663          	beq	a0,s8,80000220 <consoleread+0xbc>
    dst++;
    80000218:	0a05                	addi	s4,s4,1
    --n;
    8000021a:	39fd                	addiw	s3,s3,-1
    if(c == '\n'){
    8000021c:	f99d1ae3          	bne	s10,s9,800001b0 <consoleread+0x4c>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    80000220:	00011517          	auipc	a0,0x11
    80000224:	f6050513          	addi	a0,a0,-160 # 80011180 <cons>
    80000228:	00001097          	auipc	ra,0x1
    8000022c:	a5c080e7          	jalr	-1444(ra) # 80000c84 <release>

  return target - n;
    80000230:	413b053b          	subw	a0,s6,s3
    80000234:	a811                	j	80000248 <consoleread+0xe4>
        release(&cons.lock);
    80000236:	00011517          	auipc	a0,0x11
    8000023a:	f4a50513          	addi	a0,a0,-182 # 80011180 <cons>
    8000023e:	00001097          	auipc	ra,0x1
    80000242:	a46080e7          	jalr	-1466(ra) # 80000c84 <release>
        return -1;
    80000246:	557d                	li	a0,-1
}
    80000248:	70a6                	ld	ra,104(sp)
    8000024a:	7406                	ld	s0,96(sp)
    8000024c:	64e6                	ld	s1,88(sp)
    8000024e:	6946                	ld	s2,80(sp)
    80000250:	69a6                	ld	s3,72(sp)
    80000252:	6a06                	ld	s4,64(sp)
    80000254:	7ae2                	ld	s5,56(sp)
    80000256:	7b42                	ld	s6,48(sp)
    80000258:	7ba2                	ld	s7,40(sp)
    8000025a:	7c02                	ld	s8,32(sp)
    8000025c:	6ce2                	ld	s9,24(sp)
    8000025e:	6d42                	ld	s10,16(sp)
    80000260:	6165                	addi	sp,sp,112
    80000262:	8082                	ret
      if(n < target){
    80000264:	0009871b          	sext.w	a4,s3
    80000268:	fb677ce3          	bgeu	a4,s6,80000220 <consoleread+0xbc>
        cons.r--;
    8000026c:	00011717          	auipc	a4,0x11
    80000270:	faf72623          	sw	a5,-84(a4) # 80011218 <cons+0x98>
    80000274:	b775                	j	80000220 <consoleread+0xbc>

0000000080000276 <consputc>:
{
    80000276:	1141                	addi	sp,sp,-16
    80000278:	e406                	sd	ra,8(sp)
    8000027a:	e022                	sd	s0,0(sp)
    8000027c:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    8000027e:	10000793          	li	a5,256
    80000282:	00f50a63          	beq	a0,a5,80000296 <consputc+0x20>
    uartputc_sync(c);
    80000286:	00000097          	auipc	ra,0x0
    8000028a:	560080e7          	jalr	1376(ra) # 800007e6 <uartputc_sync>
}
    8000028e:	60a2                	ld	ra,8(sp)
    80000290:	6402                	ld	s0,0(sp)
    80000292:	0141                	addi	sp,sp,16
    80000294:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    80000296:	4521                	li	a0,8
    80000298:	00000097          	auipc	ra,0x0
    8000029c:	54e080e7          	jalr	1358(ra) # 800007e6 <uartputc_sync>
    800002a0:	02000513          	li	a0,32
    800002a4:	00000097          	auipc	ra,0x0
    800002a8:	542080e7          	jalr	1346(ra) # 800007e6 <uartputc_sync>
    800002ac:	4521                	li	a0,8
    800002ae:	00000097          	auipc	ra,0x0
    800002b2:	538080e7          	jalr	1336(ra) # 800007e6 <uartputc_sync>
    800002b6:	bfe1                	j	8000028e <consputc+0x18>

00000000800002b8 <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002b8:	1101                	addi	sp,sp,-32
    800002ba:	ec06                	sd	ra,24(sp)
    800002bc:	e822                	sd	s0,16(sp)
    800002be:	e426                	sd	s1,8(sp)
    800002c0:	e04a                	sd	s2,0(sp)
    800002c2:	1000                	addi	s0,sp,32
    800002c4:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002c6:	00011517          	auipc	a0,0x11
    800002ca:	eba50513          	addi	a0,a0,-326 # 80011180 <cons>
    800002ce:	00001097          	auipc	ra,0x1
    800002d2:	902080e7          	jalr	-1790(ra) # 80000bd0 <acquire>

  switch(c){
    800002d6:	47d5                	li	a5,21
    800002d8:	0af48663          	beq	s1,a5,80000384 <consoleintr+0xcc>
    800002dc:	0297ca63          	blt	a5,s1,80000310 <consoleintr+0x58>
    800002e0:	47a1                	li	a5,8
    800002e2:	0ef48763          	beq	s1,a5,800003d0 <consoleintr+0x118>
    800002e6:	47c1                	li	a5,16
    800002e8:	10f49a63          	bne	s1,a5,800003fc <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002ec:	00002097          	auipc	ra,0x2
    800002f0:	5c8080e7          	jalr	1480(ra) # 800028b4 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002f4:	00011517          	auipc	a0,0x11
    800002f8:	e8c50513          	addi	a0,a0,-372 # 80011180 <cons>
    800002fc:	00001097          	auipc	ra,0x1
    80000300:	988080e7          	jalr	-1656(ra) # 80000c84 <release>
}
    80000304:	60e2                	ld	ra,24(sp)
    80000306:	6442                	ld	s0,16(sp)
    80000308:	64a2                	ld	s1,8(sp)
    8000030a:	6902                	ld	s2,0(sp)
    8000030c:	6105                	addi	sp,sp,32
    8000030e:	8082                	ret
  switch(c){
    80000310:	07f00793          	li	a5,127
    80000314:	0af48e63          	beq	s1,a5,800003d0 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    80000318:	00011717          	auipc	a4,0x11
    8000031c:	e6870713          	addi	a4,a4,-408 # 80011180 <cons>
    80000320:	0a072783          	lw	a5,160(a4)
    80000324:	09872703          	lw	a4,152(a4)
    80000328:	9f99                	subw	a5,a5,a4
    8000032a:	07f00713          	li	a4,127
    8000032e:	fcf763e3          	bltu	a4,a5,800002f4 <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    80000332:	47b5                	li	a5,13
    80000334:	0cf48763          	beq	s1,a5,80000402 <consoleintr+0x14a>
      consputc(c);
    80000338:	8526                	mv	a0,s1
    8000033a:	00000097          	auipc	ra,0x0
    8000033e:	f3c080e7          	jalr	-196(ra) # 80000276 <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000342:	00011797          	auipc	a5,0x11
    80000346:	e3e78793          	addi	a5,a5,-450 # 80011180 <cons>
    8000034a:	0a07a703          	lw	a4,160(a5)
    8000034e:	0017069b          	addiw	a3,a4,1
    80000352:	0006861b          	sext.w	a2,a3
    80000356:	0ad7a023          	sw	a3,160(a5)
    8000035a:	07f77713          	andi	a4,a4,127
    8000035e:	97ba                	add	a5,a5,a4
    80000360:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e == cons.r+INPUT_BUF){
    80000364:	47a9                	li	a5,10
    80000366:	0cf48563          	beq	s1,a5,80000430 <consoleintr+0x178>
    8000036a:	4791                	li	a5,4
    8000036c:	0cf48263          	beq	s1,a5,80000430 <consoleintr+0x178>
    80000370:	00011797          	auipc	a5,0x11
    80000374:	ea87a783          	lw	a5,-344(a5) # 80011218 <cons+0x98>
    80000378:	0807879b          	addiw	a5,a5,128
    8000037c:	f6f61ce3          	bne	a2,a5,800002f4 <consoleintr+0x3c>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000380:	863e                	mv	a2,a5
    80000382:	a07d                	j	80000430 <consoleintr+0x178>
    while(cons.e != cons.w &&
    80000384:	00011717          	auipc	a4,0x11
    80000388:	dfc70713          	addi	a4,a4,-516 # 80011180 <cons>
    8000038c:	0a072783          	lw	a5,160(a4)
    80000390:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    80000394:	00011497          	auipc	s1,0x11
    80000398:	dec48493          	addi	s1,s1,-532 # 80011180 <cons>
    while(cons.e != cons.w &&
    8000039c:	4929                	li	s2,10
    8000039e:	f4f70be3          	beq	a4,a5,800002f4 <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    800003a2:	37fd                	addiw	a5,a5,-1
    800003a4:	07f7f713          	andi	a4,a5,127
    800003a8:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003aa:	01874703          	lbu	a4,24(a4)
    800003ae:	f52703e3          	beq	a4,s2,800002f4 <consoleintr+0x3c>
      cons.e--;
    800003b2:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003b6:	10000513          	li	a0,256
    800003ba:	00000097          	auipc	ra,0x0
    800003be:	ebc080e7          	jalr	-324(ra) # 80000276 <consputc>
    while(cons.e != cons.w &&
    800003c2:	0a04a783          	lw	a5,160(s1)
    800003c6:	09c4a703          	lw	a4,156(s1)
    800003ca:	fcf71ce3          	bne	a4,a5,800003a2 <consoleintr+0xea>
    800003ce:	b71d                	j	800002f4 <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003d0:	00011717          	auipc	a4,0x11
    800003d4:	db070713          	addi	a4,a4,-592 # 80011180 <cons>
    800003d8:	0a072783          	lw	a5,160(a4)
    800003dc:	09c72703          	lw	a4,156(a4)
    800003e0:	f0f70ae3          	beq	a4,a5,800002f4 <consoleintr+0x3c>
      cons.e--;
    800003e4:	37fd                	addiw	a5,a5,-1
    800003e6:	00011717          	auipc	a4,0x11
    800003ea:	e2f72d23          	sw	a5,-454(a4) # 80011220 <cons+0xa0>
      consputc(BACKSPACE);
    800003ee:	10000513          	li	a0,256
    800003f2:	00000097          	auipc	ra,0x0
    800003f6:	e84080e7          	jalr	-380(ra) # 80000276 <consputc>
    800003fa:	bded                	j	800002f4 <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    800003fc:	ee048ce3          	beqz	s1,800002f4 <consoleintr+0x3c>
    80000400:	bf21                	j	80000318 <consoleintr+0x60>
      consputc(c);
    80000402:	4529                	li	a0,10
    80000404:	00000097          	auipc	ra,0x0
    80000408:	e72080e7          	jalr	-398(ra) # 80000276 <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    8000040c:	00011797          	auipc	a5,0x11
    80000410:	d7478793          	addi	a5,a5,-652 # 80011180 <cons>
    80000414:	0a07a703          	lw	a4,160(a5)
    80000418:	0017069b          	addiw	a3,a4,1
    8000041c:	0006861b          	sext.w	a2,a3
    80000420:	0ad7a023          	sw	a3,160(a5)
    80000424:	07f77713          	andi	a4,a4,127
    80000428:	97ba                	add	a5,a5,a4
    8000042a:	4729                	li	a4,10
    8000042c:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000430:	00011797          	auipc	a5,0x11
    80000434:	dec7a623          	sw	a2,-532(a5) # 8001121c <cons+0x9c>
        wakeup(&cons.r);
    80000438:	00011517          	auipc	a0,0x11
    8000043c:	de050513          	addi	a0,a0,-544 # 80011218 <cons+0x98>
    80000440:	00002097          	auipc	ra,0x2
    80000444:	184080e7          	jalr	388(ra) # 800025c4 <wakeup>
    80000448:	b575                	j	800002f4 <consoleintr+0x3c>

000000008000044a <consoleinit>:

void
consoleinit(void)
{
    8000044a:	1141                	addi	sp,sp,-16
    8000044c:	e406                	sd	ra,8(sp)
    8000044e:	e022                	sd	s0,0(sp)
    80000450:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    80000452:	00008597          	auipc	a1,0x8
    80000456:	bbe58593          	addi	a1,a1,-1090 # 80008010 <etext+0x10>
    8000045a:	00011517          	auipc	a0,0x11
    8000045e:	d2650513          	addi	a0,a0,-730 # 80011180 <cons>
    80000462:	00000097          	auipc	ra,0x0
    80000466:	6de080e7          	jalr	1758(ra) # 80000b40 <initlock>

  uartinit();
    8000046a:	00000097          	auipc	ra,0x0
    8000046e:	32c080e7          	jalr	812(ra) # 80000796 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000472:	00022797          	auipc	a5,0x22
    80000476:	4a678793          	addi	a5,a5,1190 # 80022918 <devsw>
    8000047a:	00000717          	auipc	a4,0x0
    8000047e:	cea70713          	addi	a4,a4,-790 # 80000164 <consoleread>
    80000482:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    80000484:	00000717          	auipc	a4,0x0
    80000488:	c7c70713          	addi	a4,a4,-900 # 80000100 <consolewrite>
    8000048c:	ef98                	sd	a4,24(a5)
}
    8000048e:	60a2                	ld	ra,8(sp)
    80000490:	6402                	ld	s0,0(sp)
    80000492:	0141                	addi	sp,sp,16
    80000494:	8082                	ret

0000000080000496 <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    80000496:	7179                	addi	sp,sp,-48
    80000498:	f406                	sd	ra,40(sp)
    8000049a:	f022                	sd	s0,32(sp)
    8000049c:	ec26                	sd	s1,24(sp)
    8000049e:	e84a                	sd	s2,16(sp)
    800004a0:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004a2:	c219                	beqz	a2,800004a8 <printint+0x12>
    800004a4:	08054763          	bltz	a0,80000532 <printint+0x9c>
    x = -xx;
  else
    x = xx;
    800004a8:	2501                	sext.w	a0,a0
    800004aa:	4881                	li	a7,0
    800004ac:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004b0:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004b2:	2581                	sext.w	a1,a1
    800004b4:	00008617          	auipc	a2,0x8
    800004b8:	b8c60613          	addi	a2,a2,-1140 # 80008040 <digits>
    800004bc:	883a                	mv	a6,a4
    800004be:	2705                	addiw	a4,a4,1
    800004c0:	02b577bb          	remuw	a5,a0,a1
    800004c4:	1782                	slli	a5,a5,0x20
    800004c6:	9381                	srli	a5,a5,0x20
    800004c8:	97b2                	add	a5,a5,a2
    800004ca:	0007c783          	lbu	a5,0(a5)
    800004ce:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004d2:	0005079b          	sext.w	a5,a0
    800004d6:	02b5553b          	divuw	a0,a0,a1
    800004da:	0685                	addi	a3,a3,1
    800004dc:	feb7f0e3          	bgeu	a5,a1,800004bc <printint+0x26>

  if(sign)
    800004e0:	00088c63          	beqz	a7,800004f8 <printint+0x62>
    buf[i++] = '-';
    800004e4:	fe070793          	addi	a5,a4,-32
    800004e8:	00878733          	add	a4,a5,s0
    800004ec:	02d00793          	li	a5,45
    800004f0:	fef70823          	sb	a5,-16(a4)
    800004f4:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    800004f8:	02e05763          	blez	a4,80000526 <printint+0x90>
    800004fc:	fd040793          	addi	a5,s0,-48
    80000500:	00e784b3          	add	s1,a5,a4
    80000504:	fff78913          	addi	s2,a5,-1
    80000508:	993a                	add	s2,s2,a4
    8000050a:	377d                	addiw	a4,a4,-1
    8000050c:	1702                	slli	a4,a4,0x20
    8000050e:	9301                	srli	a4,a4,0x20
    80000510:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    80000514:	fff4c503          	lbu	a0,-1(s1)
    80000518:	00000097          	auipc	ra,0x0
    8000051c:	d5e080e7          	jalr	-674(ra) # 80000276 <consputc>
  while(--i >= 0)
    80000520:	14fd                	addi	s1,s1,-1
    80000522:	ff2499e3          	bne	s1,s2,80000514 <printint+0x7e>
}
    80000526:	70a2                	ld	ra,40(sp)
    80000528:	7402                	ld	s0,32(sp)
    8000052a:	64e2                	ld	s1,24(sp)
    8000052c:	6942                	ld	s2,16(sp)
    8000052e:	6145                	addi	sp,sp,48
    80000530:	8082                	ret
    x = -xx;
    80000532:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    80000536:	4885                	li	a7,1
    x = -xx;
    80000538:	bf95                	j	800004ac <printint+0x16>

000000008000053a <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    8000053a:	1101                	addi	sp,sp,-32
    8000053c:	ec06                	sd	ra,24(sp)
    8000053e:	e822                	sd	s0,16(sp)
    80000540:	e426                	sd	s1,8(sp)
    80000542:	1000                	addi	s0,sp,32
    80000544:	84aa                	mv	s1,a0
  pr.locking = 0;
    80000546:	00011797          	auipc	a5,0x11
    8000054a:	ce07ad23          	sw	zero,-774(a5) # 80011240 <pr+0x18>
  printf("panic: ");
    8000054e:	00008517          	auipc	a0,0x8
    80000552:	aca50513          	addi	a0,a0,-1334 # 80008018 <etext+0x18>
    80000556:	00000097          	auipc	ra,0x0
    8000055a:	02e080e7          	jalr	46(ra) # 80000584 <printf>
  printf(s);
    8000055e:	8526                	mv	a0,s1
    80000560:	00000097          	auipc	ra,0x0
    80000564:	024080e7          	jalr	36(ra) # 80000584 <printf>
  printf("\n");
    80000568:	00008517          	auipc	a0,0x8
    8000056c:	b6050513          	addi	a0,a0,-1184 # 800080c8 <digits+0x88>
    80000570:	00000097          	auipc	ra,0x0
    80000574:	014080e7          	jalr	20(ra) # 80000584 <printf>
  panicked = 1; // freeze uart output from other CPUs
    80000578:	4785                	li	a5,1
    8000057a:	00009717          	auipc	a4,0x9
    8000057e:	a8f72323          	sw	a5,-1402(a4) # 80009000 <panicked>
  for(;;)
    80000582:	a001                	j	80000582 <panic+0x48>

0000000080000584 <printf>:
{
    80000584:	7131                	addi	sp,sp,-192
    80000586:	fc86                	sd	ra,120(sp)
    80000588:	f8a2                	sd	s0,112(sp)
    8000058a:	f4a6                	sd	s1,104(sp)
    8000058c:	f0ca                	sd	s2,96(sp)
    8000058e:	ecce                	sd	s3,88(sp)
    80000590:	e8d2                	sd	s4,80(sp)
    80000592:	e4d6                	sd	s5,72(sp)
    80000594:	e0da                	sd	s6,64(sp)
    80000596:	fc5e                	sd	s7,56(sp)
    80000598:	f862                	sd	s8,48(sp)
    8000059a:	f466                	sd	s9,40(sp)
    8000059c:	f06a                	sd	s10,32(sp)
    8000059e:	ec6e                	sd	s11,24(sp)
    800005a0:	0100                	addi	s0,sp,128
    800005a2:	8a2a                	mv	s4,a0
    800005a4:	e40c                	sd	a1,8(s0)
    800005a6:	e810                	sd	a2,16(s0)
    800005a8:	ec14                	sd	a3,24(s0)
    800005aa:	f018                	sd	a4,32(s0)
    800005ac:	f41c                	sd	a5,40(s0)
    800005ae:	03043823          	sd	a6,48(s0)
    800005b2:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005b6:	00011d97          	auipc	s11,0x11
    800005ba:	c8adad83          	lw	s11,-886(s11) # 80011240 <pr+0x18>
  if(locking)
    800005be:	020d9b63          	bnez	s11,800005f4 <printf+0x70>
  if (fmt == 0)
    800005c2:	040a0263          	beqz	s4,80000606 <printf+0x82>
  va_start(ap, fmt);
    800005c6:	00840793          	addi	a5,s0,8
    800005ca:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005ce:	000a4503          	lbu	a0,0(s4)
    800005d2:	14050f63          	beqz	a0,80000730 <printf+0x1ac>
    800005d6:	4981                	li	s3,0
    if(c != '%'){
    800005d8:	02500a93          	li	s5,37
    switch(c){
    800005dc:	07000b93          	li	s7,112
  consputc('x');
    800005e0:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005e2:	00008b17          	auipc	s6,0x8
    800005e6:	a5eb0b13          	addi	s6,s6,-1442 # 80008040 <digits>
    switch(c){
    800005ea:	07300c93          	li	s9,115
    800005ee:	06400c13          	li	s8,100
    800005f2:	a82d                	j	8000062c <printf+0xa8>
    acquire(&pr.lock);
    800005f4:	00011517          	auipc	a0,0x11
    800005f8:	c3450513          	addi	a0,a0,-972 # 80011228 <pr>
    800005fc:	00000097          	auipc	ra,0x0
    80000600:	5d4080e7          	jalr	1492(ra) # 80000bd0 <acquire>
    80000604:	bf7d                	j	800005c2 <printf+0x3e>
    panic("null fmt");
    80000606:	00008517          	auipc	a0,0x8
    8000060a:	a2250513          	addi	a0,a0,-1502 # 80008028 <etext+0x28>
    8000060e:	00000097          	auipc	ra,0x0
    80000612:	f2c080e7          	jalr	-212(ra) # 8000053a <panic>
      consputc(c);
    80000616:	00000097          	auipc	ra,0x0
    8000061a:	c60080e7          	jalr	-928(ra) # 80000276 <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    8000061e:	2985                	addiw	s3,s3,1
    80000620:	013a07b3          	add	a5,s4,s3
    80000624:	0007c503          	lbu	a0,0(a5)
    80000628:	10050463          	beqz	a0,80000730 <printf+0x1ac>
    if(c != '%'){
    8000062c:	ff5515e3          	bne	a0,s5,80000616 <printf+0x92>
    c = fmt[++i] & 0xff;
    80000630:	2985                	addiw	s3,s3,1
    80000632:	013a07b3          	add	a5,s4,s3
    80000636:	0007c783          	lbu	a5,0(a5)
    8000063a:	0007849b          	sext.w	s1,a5
    if(c == 0)
    8000063e:	cbed                	beqz	a5,80000730 <printf+0x1ac>
    switch(c){
    80000640:	05778a63          	beq	a5,s7,80000694 <printf+0x110>
    80000644:	02fbf663          	bgeu	s7,a5,80000670 <printf+0xec>
    80000648:	09978863          	beq	a5,s9,800006d8 <printf+0x154>
    8000064c:	07800713          	li	a4,120
    80000650:	0ce79563          	bne	a5,a4,8000071a <printf+0x196>
      printint(va_arg(ap, int), 16, 1);
    80000654:	f8843783          	ld	a5,-120(s0)
    80000658:	00878713          	addi	a4,a5,8
    8000065c:	f8e43423          	sd	a4,-120(s0)
    80000660:	4605                	li	a2,1
    80000662:	85ea                	mv	a1,s10
    80000664:	4388                	lw	a0,0(a5)
    80000666:	00000097          	auipc	ra,0x0
    8000066a:	e30080e7          	jalr	-464(ra) # 80000496 <printint>
      break;
    8000066e:	bf45                	j	8000061e <printf+0x9a>
    switch(c){
    80000670:	09578f63          	beq	a5,s5,8000070e <printf+0x18a>
    80000674:	0b879363          	bne	a5,s8,8000071a <printf+0x196>
      printint(va_arg(ap, int), 10, 1);
    80000678:	f8843783          	ld	a5,-120(s0)
    8000067c:	00878713          	addi	a4,a5,8
    80000680:	f8e43423          	sd	a4,-120(s0)
    80000684:	4605                	li	a2,1
    80000686:	45a9                	li	a1,10
    80000688:	4388                	lw	a0,0(a5)
    8000068a:	00000097          	auipc	ra,0x0
    8000068e:	e0c080e7          	jalr	-500(ra) # 80000496 <printint>
      break;
    80000692:	b771                	j	8000061e <printf+0x9a>
      printptr(va_arg(ap, uint64));
    80000694:	f8843783          	ld	a5,-120(s0)
    80000698:	00878713          	addi	a4,a5,8
    8000069c:	f8e43423          	sd	a4,-120(s0)
    800006a0:	0007b903          	ld	s2,0(a5)
  consputc('0');
    800006a4:	03000513          	li	a0,48
    800006a8:	00000097          	auipc	ra,0x0
    800006ac:	bce080e7          	jalr	-1074(ra) # 80000276 <consputc>
  consputc('x');
    800006b0:	07800513          	li	a0,120
    800006b4:	00000097          	auipc	ra,0x0
    800006b8:	bc2080e7          	jalr	-1086(ra) # 80000276 <consputc>
    800006bc:	84ea                	mv	s1,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006be:	03c95793          	srli	a5,s2,0x3c
    800006c2:	97da                	add	a5,a5,s6
    800006c4:	0007c503          	lbu	a0,0(a5)
    800006c8:	00000097          	auipc	ra,0x0
    800006cc:	bae080e7          	jalr	-1106(ra) # 80000276 <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006d0:	0912                	slli	s2,s2,0x4
    800006d2:	34fd                	addiw	s1,s1,-1
    800006d4:	f4ed                	bnez	s1,800006be <printf+0x13a>
    800006d6:	b7a1                	j	8000061e <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006d8:	f8843783          	ld	a5,-120(s0)
    800006dc:	00878713          	addi	a4,a5,8
    800006e0:	f8e43423          	sd	a4,-120(s0)
    800006e4:	6384                	ld	s1,0(a5)
    800006e6:	cc89                	beqz	s1,80000700 <printf+0x17c>
      for(; *s; s++)
    800006e8:	0004c503          	lbu	a0,0(s1)
    800006ec:	d90d                	beqz	a0,8000061e <printf+0x9a>
        consputc(*s);
    800006ee:	00000097          	auipc	ra,0x0
    800006f2:	b88080e7          	jalr	-1144(ra) # 80000276 <consputc>
      for(; *s; s++)
    800006f6:	0485                	addi	s1,s1,1
    800006f8:	0004c503          	lbu	a0,0(s1)
    800006fc:	f96d                	bnez	a0,800006ee <printf+0x16a>
    800006fe:	b705                	j	8000061e <printf+0x9a>
        s = "(null)";
    80000700:	00008497          	auipc	s1,0x8
    80000704:	92048493          	addi	s1,s1,-1760 # 80008020 <etext+0x20>
      for(; *s; s++)
    80000708:	02800513          	li	a0,40
    8000070c:	b7cd                	j	800006ee <printf+0x16a>
      consputc('%');
    8000070e:	8556                	mv	a0,s5
    80000710:	00000097          	auipc	ra,0x0
    80000714:	b66080e7          	jalr	-1178(ra) # 80000276 <consputc>
      break;
    80000718:	b719                	j	8000061e <printf+0x9a>
      consputc('%');
    8000071a:	8556                	mv	a0,s5
    8000071c:	00000097          	auipc	ra,0x0
    80000720:	b5a080e7          	jalr	-1190(ra) # 80000276 <consputc>
      consputc(c);
    80000724:	8526                	mv	a0,s1
    80000726:	00000097          	auipc	ra,0x0
    8000072a:	b50080e7          	jalr	-1200(ra) # 80000276 <consputc>
      break;
    8000072e:	bdc5                	j	8000061e <printf+0x9a>
  if(locking)
    80000730:	020d9163          	bnez	s11,80000752 <printf+0x1ce>
}
    80000734:	70e6                	ld	ra,120(sp)
    80000736:	7446                	ld	s0,112(sp)
    80000738:	74a6                	ld	s1,104(sp)
    8000073a:	7906                	ld	s2,96(sp)
    8000073c:	69e6                	ld	s3,88(sp)
    8000073e:	6a46                	ld	s4,80(sp)
    80000740:	6aa6                	ld	s5,72(sp)
    80000742:	6b06                	ld	s6,64(sp)
    80000744:	7be2                	ld	s7,56(sp)
    80000746:	7c42                	ld	s8,48(sp)
    80000748:	7ca2                	ld	s9,40(sp)
    8000074a:	7d02                	ld	s10,32(sp)
    8000074c:	6de2                	ld	s11,24(sp)
    8000074e:	6129                	addi	sp,sp,192
    80000750:	8082                	ret
    release(&pr.lock);
    80000752:	00011517          	auipc	a0,0x11
    80000756:	ad650513          	addi	a0,a0,-1322 # 80011228 <pr>
    8000075a:	00000097          	auipc	ra,0x0
    8000075e:	52a080e7          	jalr	1322(ra) # 80000c84 <release>
}
    80000762:	bfc9                	j	80000734 <printf+0x1b0>

0000000080000764 <printfinit>:
    ;
}

void
printfinit(void)
{
    80000764:	1101                	addi	sp,sp,-32
    80000766:	ec06                	sd	ra,24(sp)
    80000768:	e822                	sd	s0,16(sp)
    8000076a:	e426                	sd	s1,8(sp)
    8000076c:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    8000076e:	00011497          	auipc	s1,0x11
    80000772:	aba48493          	addi	s1,s1,-1350 # 80011228 <pr>
    80000776:	00008597          	auipc	a1,0x8
    8000077a:	8c258593          	addi	a1,a1,-1854 # 80008038 <etext+0x38>
    8000077e:	8526                	mv	a0,s1
    80000780:	00000097          	auipc	ra,0x0
    80000784:	3c0080e7          	jalr	960(ra) # 80000b40 <initlock>
  pr.locking = 1;
    80000788:	4785                	li	a5,1
    8000078a:	cc9c                	sw	a5,24(s1)
}
    8000078c:	60e2                	ld	ra,24(sp)
    8000078e:	6442                	ld	s0,16(sp)
    80000790:	64a2                	ld	s1,8(sp)
    80000792:	6105                	addi	sp,sp,32
    80000794:	8082                	ret

0000000080000796 <uartinit>:

void uartstart();

void
uartinit(void)
{
    80000796:	1141                	addi	sp,sp,-16
    80000798:	e406                	sd	ra,8(sp)
    8000079a:	e022                	sd	s0,0(sp)
    8000079c:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    8000079e:	100007b7          	lui	a5,0x10000
    800007a2:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007a6:	f8000713          	li	a4,-128
    800007aa:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007ae:	470d                	li	a4,3
    800007b0:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007b4:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007b8:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007bc:	469d                	li	a3,7
    800007be:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007c2:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007c6:	00008597          	auipc	a1,0x8
    800007ca:	89258593          	addi	a1,a1,-1902 # 80008058 <digits+0x18>
    800007ce:	00011517          	auipc	a0,0x11
    800007d2:	a7a50513          	addi	a0,a0,-1414 # 80011248 <uart_tx_lock>
    800007d6:	00000097          	auipc	ra,0x0
    800007da:	36a080e7          	jalr	874(ra) # 80000b40 <initlock>
}
    800007de:	60a2                	ld	ra,8(sp)
    800007e0:	6402                	ld	s0,0(sp)
    800007e2:	0141                	addi	sp,sp,16
    800007e4:	8082                	ret

00000000800007e6 <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007e6:	1101                	addi	sp,sp,-32
    800007e8:	ec06                	sd	ra,24(sp)
    800007ea:	e822                	sd	s0,16(sp)
    800007ec:	e426                	sd	s1,8(sp)
    800007ee:	1000                	addi	s0,sp,32
    800007f0:	84aa                	mv	s1,a0
  push_off();
    800007f2:	00000097          	auipc	ra,0x0
    800007f6:	392080e7          	jalr	914(ra) # 80000b84 <push_off>

  if(panicked){
    800007fa:	00009797          	auipc	a5,0x9
    800007fe:	8067a783          	lw	a5,-2042(a5) # 80009000 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000802:	10000737          	lui	a4,0x10000
  if(panicked){
    80000806:	c391                	beqz	a5,8000080a <uartputc_sync+0x24>
    for(;;)
    80000808:	a001                	j	80000808 <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000080a:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    8000080e:	0207f793          	andi	a5,a5,32
    80000812:	dfe5                	beqz	a5,8000080a <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    80000814:	0ff4f513          	zext.b	a0,s1
    80000818:	100007b7          	lui	a5,0x10000
    8000081c:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>

  pop_off();
    80000820:	00000097          	auipc	ra,0x0
    80000824:	404080e7          	jalr	1028(ra) # 80000c24 <pop_off>
}
    80000828:	60e2                	ld	ra,24(sp)
    8000082a:	6442                	ld	s0,16(sp)
    8000082c:	64a2                	ld	s1,8(sp)
    8000082e:	6105                	addi	sp,sp,32
    80000830:	8082                	ret

0000000080000832 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000832:	00008797          	auipc	a5,0x8
    80000836:	7d67b783          	ld	a5,2006(a5) # 80009008 <uart_tx_r>
    8000083a:	00008717          	auipc	a4,0x8
    8000083e:	7d673703          	ld	a4,2006(a4) # 80009010 <uart_tx_w>
    80000842:	06f70a63          	beq	a4,a5,800008b6 <uartstart+0x84>
{
    80000846:	7139                	addi	sp,sp,-64
    80000848:	fc06                	sd	ra,56(sp)
    8000084a:	f822                	sd	s0,48(sp)
    8000084c:	f426                	sd	s1,40(sp)
    8000084e:	f04a                	sd	s2,32(sp)
    80000850:	ec4e                	sd	s3,24(sp)
    80000852:	e852                	sd	s4,16(sp)
    80000854:	e456                	sd	s5,8(sp)
    80000856:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000858:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    8000085c:	00011a17          	auipc	s4,0x11
    80000860:	9eca0a13          	addi	s4,s4,-1556 # 80011248 <uart_tx_lock>
    uart_tx_r += 1;
    80000864:	00008497          	auipc	s1,0x8
    80000868:	7a448493          	addi	s1,s1,1956 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    8000086c:	00008997          	auipc	s3,0x8
    80000870:	7a498993          	addi	s3,s3,1956 # 80009010 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000874:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    80000878:	02077713          	andi	a4,a4,32
    8000087c:	c705                	beqz	a4,800008a4 <uartstart+0x72>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    8000087e:	01f7f713          	andi	a4,a5,31
    80000882:	9752                	add	a4,a4,s4
    80000884:	01874a83          	lbu	s5,24(a4)
    uart_tx_r += 1;
    80000888:	0785                	addi	a5,a5,1
    8000088a:	e09c                	sd	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    8000088c:	8526                	mv	a0,s1
    8000088e:	00002097          	auipc	ra,0x2
    80000892:	d36080e7          	jalr	-714(ra) # 800025c4 <wakeup>
    
    WriteReg(THR, c);
    80000896:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    8000089a:	609c                	ld	a5,0(s1)
    8000089c:	0009b703          	ld	a4,0(s3)
    800008a0:	fcf71ae3          	bne	a4,a5,80000874 <uartstart+0x42>
  }
}
    800008a4:	70e2                	ld	ra,56(sp)
    800008a6:	7442                	ld	s0,48(sp)
    800008a8:	74a2                	ld	s1,40(sp)
    800008aa:	7902                	ld	s2,32(sp)
    800008ac:	69e2                	ld	s3,24(sp)
    800008ae:	6a42                	ld	s4,16(sp)
    800008b0:	6aa2                	ld	s5,8(sp)
    800008b2:	6121                	addi	sp,sp,64
    800008b4:	8082                	ret
    800008b6:	8082                	ret

00000000800008b8 <uartputc>:
{
    800008b8:	7179                	addi	sp,sp,-48
    800008ba:	f406                	sd	ra,40(sp)
    800008bc:	f022                	sd	s0,32(sp)
    800008be:	ec26                	sd	s1,24(sp)
    800008c0:	e84a                	sd	s2,16(sp)
    800008c2:	e44e                	sd	s3,8(sp)
    800008c4:	e052                	sd	s4,0(sp)
    800008c6:	1800                	addi	s0,sp,48
    800008c8:	8a2a                	mv	s4,a0
  acquire(&uart_tx_lock);
    800008ca:	00011517          	auipc	a0,0x11
    800008ce:	97e50513          	addi	a0,a0,-1666 # 80011248 <uart_tx_lock>
    800008d2:	00000097          	auipc	ra,0x0
    800008d6:	2fe080e7          	jalr	766(ra) # 80000bd0 <acquire>
  if(panicked){
    800008da:	00008797          	auipc	a5,0x8
    800008de:	7267a783          	lw	a5,1830(a5) # 80009000 <panicked>
    800008e2:	c391                	beqz	a5,800008e6 <uartputc+0x2e>
    for(;;)
    800008e4:	a001                	j	800008e4 <uartputc+0x2c>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008e6:	00008717          	auipc	a4,0x8
    800008ea:	72a73703          	ld	a4,1834(a4) # 80009010 <uart_tx_w>
    800008ee:	00008797          	auipc	a5,0x8
    800008f2:	71a7b783          	ld	a5,1818(a5) # 80009008 <uart_tx_r>
    800008f6:	02078793          	addi	a5,a5,32
    800008fa:	02e79b63          	bne	a5,a4,80000930 <uartputc+0x78>
      sleep(&uart_tx_r, &uart_tx_lock);
    800008fe:	00011997          	auipc	s3,0x11
    80000902:	94a98993          	addi	s3,s3,-1718 # 80011248 <uart_tx_lock>
    80000906:	00008497          	auipc	s1,0x8
    8000090a:	70248493          	addi	s1,s1,1794 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    8000090e:	00008917          	auipc	s2,0x8
    80000912:	70290913          	addi	s2,s2,1794 # 80009010 <uart_tx_w>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000916:	85ce                	mv	a1,s3
    80000918:	8526                	mv	a0,s1
    8000091a:	00002097          	auipc	ra,0x2
    8000091e:	9c2080e7          	jalr	-1598(ra) # 800022dc <sleep>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000922:	00093703          	ld	a4,0(s2)
    80000926:	609c                	ld	a5,0(s1)
    80000928:	02078793          	addi	a5,a5,32
    8000092c:	fee785e3          	beq	a5,a4,80000916 <uartputc+0x5e>
      uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000930:	00011497          	auipc	s1,0x11
    80000934:	91848493          	addi	s1,s1,-1768 # 80011248 <uart_tx_lock>
    80000938:	01f77793          	andi	a5,a4,31
    8000093c:	97a6                	add	a5,a5,s1
    8000093e:	01478c23          	sb	s4,24(a5)
      uart_tx_w += 1;
    80000942:	0705                	addi	a4,a4,1
    80000944:	00008797          	auipc	a5,0x8
    80000948:	6ce7b623          	sd	a4,1740(a5) # 80009010 <uart_tx_w>
      uartstart();
    8000094c:	00000097          	auipc	ra,0x0
    80000950:	ee6080e7          	jalr	-282(ra) # 80000832 <uartstart>
      release(&uart_tx_lock);
    80000954:	8526                	mv	a0,s1
    80000956:	00000097          	auipc	ra,0x0
    8000095a:	32e080e7          	jalr	814(ra) # 80000c84 <release>
}
    8000095e:	70a2                	ld	ra,40(sp)
    80000960:	7402                	ld	s0,32(sp)
    80000962:	64e2                	ld	s1,24(sp)
    80000964:	6942                	ld	s2,16(sp)
    80000966:	69a2                	ld	s3,8(sp)
    80000968:	6a02                	ld	s4,0(sp)
    8000096a:	6145                	addi	sp,sp,48
    8000096c:	8082                	ret

000000008000096e <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    8000096e:	1141                	addi	sp,sp,-16
    80000970:	e422                	sd	s0,8(sp)
    80000972:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    80000974:	100007b7          	lui	a5,0x10000
    80000978:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    8000097c:	8b85                	andi	a5,a5,1
    8000097e:	cb81                	beqz	a5,8000098e <uartgetc+0x20>
    // input data is ready.
    return ReadReg(RHR);
    80000980:	100007b7          	lui	a5,0x10000
    80000984:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
  } else {
    return -1;
  }
}
    80000988:	6422                	ld	s0,8(sp)
    8000098a:	0141                	addi	sp,sp,16
    8000098c:	8082                	ret
    return -1;
    8000098e:	557d                	li	a0,-1
    80000990:	bfe5                	j	80000988 <uartgetc+0x1a>

0000000080000992 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from trap.c.
void
uartintr(void)
{
    80000992:	1101                	addi	sp,sp,-32
    80000994:	ec06                	sd	ra,24(sp)
    80000996:	e822                	sd	s0,16(sp)
    80000998:	e426                	sd	s1,8(sp)
    8000099a:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    8000099c:	54fd                	li	s1,-1
    8000099e:	a029                	j	800009a8 <uartintr+0x16>
      break;
    consoleintr(c);
    800009a0:	00000097          	auipc	ra,0x0
    800009a4:	918080e7          	jalr	-1768(ra) # 800002b8 <consoleintr>
    int c = uartgetc();
    800009a8:	00000097          	auipc	ra,0x0
    800009ac:	fc6080e7          	jalr	-58(ra) # 8000096e <uartgetc>
    if(c == -1)
    800009b0:	fe9518e3          	bne	a0,s1,800009a0 <uartintr+0xe>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009b4:	00011497          	auipc	s1,0x11
    800009b8:	89448493          	addi	s1,s1,-1900 # 80011248 <uart_tx_lock>
    800009bc:	8526                	mv	a0,s1
    800009be:	00000097          	auipc	ra,0x0
    800009c2:	212080e7          	jalr	530(ra) # 80000bd0 <acquire>
  uartstart();
    800009c6:	00000097          	auipc	ra,0x0
    800009ca:	e6c080e7          	jalr	-404(ra) # 80000832 <uartstart>
  release(&uart_tx_lock);
    800009ce:	8526                	mv	a0,s1
    800009d0:	00000097          	auipc	ra,0x0
    800009d4:	2b4080e7          	jalr	692(ra) # 80000c84 <release>
}
    800009d8:	60e2                	ld	ra,24(sp)
    800009da:	6442                	ld	s0,16(sp)
    800009dc:	64a2                	ld	s1,8(sp)
    800009de:	6105                	addi	sp,sp,32
    800009e0:	8082                	ret

00000000800009e2 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    800009e2:	1101                	addi	sp,sp,-32
    800009e4:	ec06                	sd	ra,24(sp)
    800009e6:	e822                	sd	s0,16(sp)
    800009e8:	e426                	sd	s1,8(sp)
    800009ea:	e04a                	sd	s2,0(sp)
    800009ec:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    800009ee:	03451793          	slli	a5,a0,0x34
    800009f2:	ebb9                	bnez	a5,80000a48 <kfree+0x66>
    800009f4:	84aa                	mv	s1,a0
    800009f6:	00026797          	auipc	a5,0x26
    800009fa:	60a78793          	addi	a5,a5,1546 # 80027000 <end>
    800009fe:	04f56563          	bltu	a0,a5,80000a48 <kfree+0x66>
    80000a02:	47c5                	li	a5,17
    80000a04:	07ee                	slli	a5,a5,0x1b
    80000a06:	04f57163          	bgeu	a0,a5,80000a48 <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a0a:	6605                	lui	a2,0x1
    80000a0c:	4585                	li	a1,1
    80000a0e:	00000097          	auipc	ra,0x0
    80000a12:	2be080e7          	jalr	702(ra) # 80000ccc <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a16:	00011917          	auipc	s2,0x11
    80000a1a:	86a90913          	addi	s2,s2,-1942 # 80011280 <kmem>
    80000a1e:	854a                	mv	a0,s2
    80000a20:	00000097          	auipc	ra,0x0
    80000a24:	1b0080e7          	jalr	432(ra) # 80000bd0 <acquire>
  r->next = kmem.freelist;
    80000a28:	01893783          	ld	a5,24(s2)
    80000a2c:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a2e:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a32:	854a                	mv	a0,s2
    80000a34:	00000097          	auipc	ra,0x0
    80000a38:	250080e7          	jalr	592(ra) # 80000c84 <release>
}
    80000a3c:	60e2                	ld	ra,24(sp)
    80000a3e:	6442                	ld	s0,16(sp)
    80000a40:	64a2                	ld	s1,8(sp)
    80000a42:	6902                	ld	s2,0(sp)
    80000a44:	6105                	addi	sp,sp,32
    80000a46:	8082                	ret
    panic("kfree");
    80000a48:	00007517          	auipc	a0,0x7
    80000a4c:	61850513          	addi	a0,a0,1560 # 80008060 <digits+0x20>
    80000a50:	00000097          	auipc	ra,0x0
    80000a54:	aea080e7          	jalr	-1302(ra) # 8000053a <panic>

0000000080000a58 <freerange>:
{
    80000a58:	7179                	addi	sp,sp,-48
    80000a5a:	f406                	sd	ra,40(sp)
    80000a5c:	f022                	sd	s0,32(sp)
    80000a5e:	ec26                	sd	s1,24(sp)
    80000a60:	e84a                	sd	s2,16(sp)
    80000a62:	e44e                	sd	s3,8(sp)
    80000a64:	e052                	sd	s4,0(sp)
    80000a66:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a68:	6785                	lui	a5,0x1
    80000a6a:	fff78713          	addi	a4,a5,-1 # fff <_entry-0x7ffff001>
    80000a6e:	00e504b3          	add	s1,a0,a4
    80000a72:	777d                	lui	a4,0xfffff
    80000a74:	8cf9                	and	s1,s1,a4
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a76:	94be                	add	s1,s1,a5
    80000a78:	0095ee63          	bltu	a1,s1,80000a94 <freerange+0x3c>
    80000a7c:	892e                	mv	s2,a1
    kfree(p);
    80000a7e:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a80:	6985                	lui	s3,0x1
    kfree(p);
    80000a82:	01448533          	add	a0,s1,s4
    80000a86:	00000097          	auipc	ra,0x0
    80000a8a:	f5c080e7          	jalr	-164(ra) # 800009e2 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a8e:	94ce                	add	s1,s1,s3
    80000a90:	fe9979e3          	bgeu	s2,s1,80000a82 <freerange+0x2a>
}
    80000a94:	70a2                	ld	ra,40(sp)
    80000a96:	7402                	ld	s0,32(sp)
    80000a98:	64e2                	ld	s1,24(sp)
    80000a9a:	6942                	ld	s2,16(sp)
    80000a9c:	69a2                	ld	s3,8(sp)
    80000a9e:	6a02                	ld	s4,0(sp)
    80000aa0:	6145                	addi	sp,sp,48
    80000aa2:	8082                	ret

0000000080000aa4 <kinit>:
{
    80000aa4:	1141                	addi	sp,sp,-16
    80000aa6:	e406                	sd	ra,8(sp)
    80000aa8:	e022                	sd	s0,0(sp)
    80000aaa:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000aac:	00007597          	auipc	a1,0x7
    80000ab0:	5bc58593          	addi	a1,a1,1468 # 80008068 <digits+0x28>
    80000ab4:	00010517          	auipc	a0,0x10
    80000ab8:	7cc50513          	addi	a0,a0,1996 # 80011280 <kmem>
    80000abc:	00000097          	auipc	ra,0x0
    80000ac0:	084080e7          	jalr	132(ra) # 80000b40 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000ac4:	45c5                	li	a1,17
    80000ac6:	05ee                	slli	a1,a1,0x1b
    80000ac8:	00026517          	auipc	a0,0x26
    80000acc:	53850513          	addi	a0,a0,1336 # 80027000 <end>
    80000ad0:	00000097          	auipc	ra,0x0
    80000ad4:	f88080e7          	jalr	-120(ra) # 80000a58 <freerange>
}
    80000ad8:	60a2                	ld	ra,8(sp)
    80000ada:	6402                	ld	s0,0(sp)
    80000adc:	0141                	addi	sp,sp,16
    80000ade:	8082                	ret

0000000080000ae0 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000ae0:	1101                	addi	sp,sp,-32
    80000ae2:	ec06                	sd	ra,24(sp)
    80000ae4:	e822                	sd	s0,16(sp)
    80000ae6:	e426                	sd	s1,8(sp)
    80000ae8:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000aea:	00010497          	auipc	s1,0x10
    80000aee:	79648493          	addi	s1,s1,1942 # 80011280 <kmem>
    80000af2:	8526                	mv	a0,s1
    80000af4:	00000097          	auipc	ra,0x0
    80000af8:	0dc080e7          	jalr	220(ra) # 80000bd0 <acquire>
  r = kmem.freelist;
    80000afc:	6c84                	ld	s1,24(s1)
  if(r)
    80000afe:	c885                	beqz	s1,80000b2e <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b00:	609c                	ld	a5,0(s1)
    80000b02:	00010517          	auipc	a0,0x10
    80000b06:	77e50513          	addi	a0,a0,1918 # 80011280 <kmem>
    80000b0a:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b0c:	00000097          	auipc	ra,0x0
    80000b10:	178080e7          	jalr	376(ra) # 80000c84 <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b14:	6605                	lui	a2,0x1
    80000b16:	4595                	li	a1,5
    80000b18:	8526                	mv	a0,s1
    80000b1a:	00000097          	auipc	ra,0x0
    80000b1e:	1b2080e7          	jalr	434(ra) # 80000ccc <memset>
  return (void*)r;
}
    80000b22:	8526                	mv	a0,s1
    80000b24:	60e2                	ld	ra,24(sp)
    80000b26:	6442                	ld	s0,16(sp)
    80000b28:	64a2                	ld	s1,8(sp)
    80000b2a:	6105                	addi	sp,sp,32
    80000b2c:	8082                	ret
  release(&kmem.lock);
    80000b2e:	00010517          	auipc	a0,0x10
    80000b32:	75250513          	addi	a0,a0,1874 # 80011280 <kmem>
    80000b36:	00000097          	auipc	ra,0x0
    80000b3a:	14e080e7          	jalr	334(ra) # 80000c84 <release>
  if(r)
    80000b3e:	b7d5                	j	80000b22 <kalloc+0x42>

0000000080000b40 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b40:	1141                	addi	sp,sp,-16
    80000b42:	e422                	sd	s0,8(sp)
    80000b44:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b46:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b48:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b4c:	00053823          	sd	zero,16(a0)
}
    80000b50:	6422                	ld	s0,8(sp)
    80000b52:	0141                	addi	sp,sp,16
    80000b54:	8082                	ret

0000000080000b56 <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b56:	411c                	lw	a5,0(a0)
    80000b58:	e399                	bnez	a5,80000b5e <holding+0x8>
    80000b5a:	4501                	li	a0,0
  return r;
}
    80000b5c:	8082                	ret
{
    80000b5e:	1101                	addi	sp,sp,-32
    80000b60:	ec06                	sd	ra,24(sp)
    80000b62:	e822                	sd	s0,16(sp)
    80000b64:	e426                	sd	s1,8(sp)
    80000b66:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000b68:	6904                	ld	s1,16(a0)
    80000b6a:	00001097          	auipc	ra,0x1
    80000b6e:	e10080e7          	jalr	-496(ra) # 8000197a <mycpu>
    80000b72:	40a48533          	sub	a0,s1,a0
    80000b76:	00153513          	seqz	a0,a0
}
    80000b7a:	60e2                	ld	ra,24(sp)
    80000b7c:	6442                	ld	s0,16(sp)
    80000b7e:	64a2                	ld	s1,8(sp)
    80000b80:	6105                	addi	sp,sp,32
    80000b82:	8082                	ret

0000000080000b84 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000b84:	1101                	addi	sp,sp,-32
    80000b86:	ec06                	sd	ra,24(sp)
    80000b88:	e822                	sd	s0,16(sp)
    80000b8a:	e426                	sd	s1,8(sp)
    80000b8c:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000b8e:	100024f3          	csrr	s1,sstatus
    80000b92:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000b96:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000b98:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000b9c:	00001097          	auipc	ra,0x1
    80000ba0:	dde080e7          	jalr	-546(ra) # 8000197a <mycpu>
    80000ba4:	5d3c                	lw	a5,120(a0)
    80000ba6:	cf89                	beqz	a5,80000bc0 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000ba8:	00001097          	auipc	ra,0x1
    80000bac:	dd2080e7          	jalr	-558(ra) # 8000197a <mycpu>
    80000bb0:	5d3c                	lw	a5,120(a0)
    80000bb2:	2785                	addiw	a5,a5,1
    80000bb4:	dd3c                	sw	a5,120(a0)
}
    80000bb6:	60e2                	ld	ra,24(sp)
    80000bb8:	6442                	ld	s0,16(sp)
    80000bba:	64a2                	ld	s1,8(sp)
    80000bbc:	6105                	addi	sp,sp,32
    80000bbe:	8082                	ret
    mycpu()->intena = old;
    80000bc0:	00001097          	auipc	ra,0x1
    80000bc4:	dba080e7          	jalr	-582(ra) # 8000197a <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000bc8:	8085                	srli	s1,s1,0x1
    80000bca:	8885                	andi	s1,s1,1
    80000bcc:	dd64                	sw	s1,124(a0)
    80000bce:	bfe9                	j	80000ba8 <push_off+0x24>

0000000080000bd0 <acquire>:
{
    80000bd0:	1101                	addi	sp,sp,-32
    80000bd2:	ec06                	sd	ra,24(sp)
    80000bd4:	e822                	sd	s0,16(sp)
    80000bd6:	e426                	sd	s1,8(sp)
    80000bd8:	1000                	addi	s0,sp,32
    80000bda:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000bdc:	00000097          	auipc	ra,0x0
    80000be0:	fa8080e7          	jalr	-88(ra) # 80000b84 <push_off>
  if(holding(lk))
    80000be4:	8526                	mv	a0,s1
    80000be6:	00000097          	auipc	ra,0x0
    80000bea:	f70080e7          	jalr	-144(ra) # 80000b56 <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000bee:	4705                	li	a4,1
  if(holding(lk))
    80000bf0:	e115                	bnez	a0,80000c14 <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000bf2:	87ba                	mv	a5,a4
    80000bf4:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000bf8:	2781                	sext.w	a5,a5
    80000bfa:	ffe5                	bnez	a5,80000bf2 <acquire+0x22>
  __sync_synchronize();
    80000bfc:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c00:	00001097          	auipc	ra,0x1
    80000c04:	d7a080e7          	jalr	-646(ra) # 8000197a <mycpu>
    80000c08:	e888                	sd	a0,16(s1)
}
    80000c0a:	60e2                	ld	ra,24(sp)
    80000c0c:	6442                	ld	s0,16(sp)
    80000c0e:	64a2                	ld	s1,8(sp)
    80000c10:	6105                	addi	sp,sp,32
    80000c12:	8082                	ret
    panic("acquire");
    80000c14:	00007517          	auipc	a0,0x7
    80000c18:	45c50513          	addi	a0,a0,1116 # 80008070 <digits+0x30>
    80000c1c:	00000097          	auipc	ra,0x0
    80000c20:	91e080e7          	jalr	-1762(ra) # 8000053a <panic>

0000000080000c24 <pop_off>:

void
pop_off(void)
{
    80000c24:	1141                	addi	sp,sp,-16
    80000c26:	e406                	sd	ra,8(sp)
    80000c28:	e022                	sd	s0,0(sp)
    80000c2a:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c2c:	00001097          	auipc	ra,0x1
    80000c30:	d4e080e7          	jalr	-690(ra) # 8000197a <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c34:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c38:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c3a:	e78d                	bnez	a5,80000c64 <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c3c:	5d3c                	lw	a5,120(a0)
    80000c3e:	02f05b63          	blez	a5,80000c74 <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c42:	37fd                	addiw	a5,a5,-1
    80000c44:	0007871b          	sext.w	a4,a5
    80000c48:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c4a:	eb09                	bnez	a4,80000c5c <pop_off+0x38>
    80000c4c:	5d7c                	lw	a5,124(a0)
    80000c4e:	c799                	beqz	a5,80000c5c <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c50:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c54:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c58:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c5c:	60a2                	ld	ra,8(sp)
    80000c5e:	6402                	ld	s0,0(sp)
    80000c60:	0141                	addi	sp,sp,16
    80000c62:	8082                	ret
    panic("pop_off - interruptible");
    80000c64:	00007517          	auipc	a0,0x7
    80000c68:	41450513          	addi	a0,a0,1044 # 80008078 <digits+0x38>
    80000c6c:	00000097          	auipc	ra,0x0
    80000c70:	8ce080e7          	jalr	-1842(ra) # 8000053a <panic>
    panic("pop_off");
    80000c74:	00007517          	auipc	a0,0x7
    80000c78:	41c50513          	addi	a0,a0,1052 # 80008090 <digits+0x50>
    80000c7c:	00000097          	auipc	ra,0x0
    80000c80:	8be080e7          	jalr	-1858(ra) # 8000053a <panic>

0000000080000c84 <release>:
{
    80000c84:	1101                	addi	sp,sp,-32
    80000c86:	ec06                	sd	ra,24(sp)
    80000c88:	e822                	sd	s0,16(sp)
    80000c8a:	e426                	sd	s1,8(sp)
    80000c8c:	1000                	addi	s0,sp,32
    80000c8e:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000c90:	00000097          	auipc	ra,0x0
    80000c94:	ec6080e7          	jalr	-314(ra) # 80000b56 <holding>
    80000c98:	c115                	beqz	a0,80000cbc <release+0x38>
  lk->cpu = 0;
    80000c9a:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000c9e:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000ca2:	0f50000f          	fence	iorw,ow
    80000ca6:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000caa:	00000097          	auipc	ra,0x0
    80000cae:	f7a080e7          	jalr	-134(ra) # 80000c24 <pop_off>
}
    80000cb2:	60e2                	ld	ra,24(sp)
    80000cb4:	6442                	ld	s0,16(sp)
    80000cb6:	64a2                	ld	s1,8(sp)
    80000cb8:	6105                	addi	sp,sp,32
    80000cba:	8082                	ret
    panic("release");
    80000cbc:	00007517          	auipc	a0,0x7
    80000cc0:	3dc50513          	addi	a0,a0,988 # 80008098 <digits+0x58>
    80000cc4:	00000097          	auipc	ra,0x0
    80000cc8:	876080e7          	jalr	-1930(ra) # 8000053a <panic>

0000000080000ccc <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000ccc:	1141                	addi	sp,sp,-16
    80000cce:	e422                	sd	s0,8(sp)
    80000cd0:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000cd2:	ca19                	beqz	a2,80000ce8 <memset+0x1c>
    80000cd4:	87aa                	mv	a5,a0
    80000cd6:	1602                	slli	a2,a2,0x20
    80000cd8:	9201                	srli	a2,a2,0x20
    80000cda:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000cde:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000ce2:	0785                	addi	a5,a5,1
    80000ce4:	fee79de3          	bne	a5,a4,80000cde <memset+0x12>
  }
  return dst;
}
    80000ce8:	6422                	ld	s0,8(sp)
    80000cea:	0141                	addi	sp,sp,16
    80000cec:	8082                	ret

0000000080000cee <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000cee:	1141                	addi	sp,sp,-16
    80000cf0:	e422                	sd	s0,8(sp)
    80000cf2:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000cf4:	ca05                	beqz	a2,80000d24 <memcmp+0x36>
    80000cf6:	fff6069b          	addiw	a3,a2,-1
    80000cfa:	1682                	slli	a3,a3,0x20
    80000cfc:	9281                	srli	a3,a3,0x20
    80000cfe:	0685                	addi	a3,a3,1
    80000d00:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d02:	00054783          	lbu	a5,0(a0)
    80000d06:	0005c703          	lbu	a4,0(a1)
    80000d0a:	00e79863          	bne	a5,a4,80000d1a <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d0e:	0505                	addi	a0,a0,1
    80000d10:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d12:	fed518e3          	bne	a0,a3,80000d02 <memcmp+0x14>
  }

  return 0;
    80000d16:	4501                	li	a0,0
    80000d18:	a019                	j	80000d1e <memcmp+0x30>
      return *s1 - *s2;
    80000d1a:	40e7853b          	subw	a0,a5,a4
}
    80000d1e:	6422                	ld	s0,8(sp)
    80000d20:	0141                	addi	sp,sp,16
    80000d22:	8082                	ret
  return 0;
    80000d24:	4501                	li	a0,0
    80000d26:	bfe5                	j	80000d1e <memcmp+0x30>

0000000080000d28 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d28:	1141                	addi	sp,sp,-16
    80000d2a:	e422                	sd	s0,8(sp)
    80000d2c:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000d2e:	c205                	beqz	a2,80000d4e <memmove+0x26>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d30:	02a5e263          	bltu	a1,a0,80000d54 <memmove+0x2c>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d34:	1602                	slli	a2,a2,0x20
    80000d36:	9201                	srli	a2,a2,0x20
    80000d38:	00c587b3          	add	a5,a1,a2
{
    80000d3c:	872a                	mv	a4,a0
      *d++ = *s++;
    80000d3e:	0585                	addi	a1,a1,1
    80000d40:	0705                	addi	a4,a4,1
    80000d42:	fff5c683          	lbu	a3,-1(a1)
    80000d46:	fed70fa3          	sb	a3,-1(a4) # ffffffffffffefff <end+0xffffffff7ffd7fff>
    while(n-- > 0)
    80000d4a:	fef59ae3          	bne	a1,a5,80000d3e <memmove+0x16>

  return dst;
}
    80000d4e:	6422                	ld	s0,8(sp)
    80000d50:	0141                	addi	sp,sp,16
    80000d52:	8082                	ret
  if(s < d && s + n > d){
    80000d54:	02061693          	slli	a3,a2,0x20
    80000d58:	9281                	srli	a3,a3,0x20
    80000d5a:	00d58733          	add	a4,a1,a3
    80000d5e:	fce57be3          	bgeu	a0,a4,80000d34 <memmove+0xc>
    d += n;
    80000d62:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000d64:	fff6079b          	addiw	a5,a2,-1
    80000d68:	1782                	slli	a5,a5,0x20
    80000d6a:	9381                	srli	a5,a5,0x20
    80000d6c:	fff7c793          	not	a5,a5
    80000d70:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000d72:	177d                	addi	a4,a4,-1
    80000d74:	16fd                	addi	a3,a3,-1
    80000d76:	00074603          	lbu	a2,0(a4)
    80000d7a:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000d7e:	fee79ae3          	bne	a5,a4,80000d72 <memmove+0x4a>
    80000d82:	b7f1                	j	80000d4e <memmove+0x26>

0000000080000d84 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000d84:	1141                	addi	sp,sp,-16
    80000d86:	e406                	sd	ra,8(sp)
    80000d88:	e022                	sd	s0,0(sp)
    80000d8a:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000d8c:	00000097          	auipc	ra,0x0
    80000d90:	f9c080e7          	jalr	-100(ra) # 80000d28 <memmove>
}
    80000d94:	60a2                	ld	ra,8(sp)
    80000d96:	6402                	ld	s0,0(sp)
    80000d98:	0141                	addi	sp,sp,16
    80000d9a:	8082                	ret

0000000080000d9c <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000d9c:	1141                	addi	sp,sp,-16
    80000d9e:	e422                	sd	s0,8(sp)
    80000da0:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000da2:	ce11                	beqz	a2,80000dbe <strncmp+0x22>
    80000da4:	00054783          	lbu	a5,0(a0)
    80000da8:	cf89                	beqz	a5,80000dc2 <strncmp+0x26>
    80000daa:	0005c703          	lbu	a4,0(a1)
    80000dae:	00f71a63          	bne	a4,a5,80000dc2 <strncmp+0x26>
    n--, p++, q++;
    80000db2:	367d                	addiw	a2,a2,-1
    80000db4:	0505                	addi	a0,a0,1
    80000db6:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000db8:	f675                	bnez	a2,80000da4 <strncmp+0x8>
  if(n == 0)
    return 0;
    80000dba:	4501                	li	a0,0
    80000dbc:	a809                	j	80000dce <strncmp+0x32>
    80000dbe:	4501                	li	a0,0
    80000dc0:	a039                	j	80000dce <strncmp+0x32>
  if(n == 0)
    80000dc2:	ca09                	beqz	a2,80000dd4 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000dc4:	00054503          	lbu	a0,0(a0)
    80000dc8:	0005c783          	lbu	a5,0(a1)
    80000dcc:	9d1d                	subw	a0,a0,a5
}
    80000dce:	6422                	ld	s0,8(sp)
    80000dd0:	0141                	addi	sp,sp,16
    80000dd2:	8082                	ret
    return 0;
    80000dd4:	4501                	li	a0,0
    80000dd6:	bfe5                	j	80000dce <strncmp+0x32>

0000000080000dd8 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000dd8:	1141                	addi	sp,sp,-16
    80000dda:	e422                	sd	s0,8(sp)
    80000ddc:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000dde:	872a                	mv	a4,a0
    80000de0:	8832                	mv	a6,a2
    80000de2:	367d                	addiw	a2,a2,-1
    80000de4:	01005963          	blez	a6,80000df6 <strncpy+0x1e>
    80000de8:	0705                	addi	a4,a4,1
    80000dea:	0005c783          	lbu	a5,0(a1)
    80000dee:	fef70fa3          	sb	a5,-1(a4)
    80000df2:	0585                	addi	a1,a1,1
    80000df4:	f7f5                	bnez	a5,80000de0 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000df6:	86ba                	mv	a3,a4
    80000df8:	00c05c63          	blez	a2,80000e10 <strncpy+0x38>
    *s++ = 0;
    80000dfc:	0685                	addi	a3,a3,1
    80000dfe:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e02:	40d707bb          	subw	a5,a4,a3
    80000e06:	37fd                	addiw	a5,a5,-1
    80000e08:	010787bb          	addw	a5,a5,a6
    80000e0c:	fef048e3          	bgtz	a5,80000dfc <strncpy+0x24>
  return os;
}
    80000e10:	6422                	ld	s0,8(sp)
    80000e12:	0141                	addi	sp,sp,16
    80000e14:	8082                	ret

0000000080000e16 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e16:	1141                	addi	sp,sp,-16
    80000e18:	e422                	sd	s0,8(sp)
    80000e1a:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e1c:	02c05363          	blez	a2,80000e42 <safestrcpy+0x2c>
    80000e20:	fff6069b          	addiw	a3,a2,-1
    80000e24:	1682                	slli	a3,a3,0x20
    80000e26:	9281                	srli	a3,a3,0x20
    80000e28:	96ae                	add	a3,a3,a1
    80000e2a:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e2c:	00d58963          	beq	a1,a3,80000e3e <safestrcpy+0x28>
    80000e30:	0585                	addi	a1,a1,1
    80000e32:	0785                	addi	a5,a5,1
    80000e34:	fff5c703          	lbu	a4,-1(a1)
    80000e38:	fee78fa3          	sb	a4,-1(a5)
    80000e3c:	fb65                	bnez	a4,80000e2c <safestrcpy+0x16>
    ;
  *s = 0;
    80000e3e:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e42:	6422                	ld	s0,8(sp)
    80000e44:	0141                	addi	sp,sp,16
    80000e46:	8082                	ret

0000000080000e48 <strlen>:

int
strlen(const char *s)
{
    80000e48:	1141                	addi	sp,sp,-16
    80000e4a:	e422                	sd	s0,8(sp)
    80000e4c:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e4e:	00054783          	lbu	a5,0(a0)
    80000e52:	cf91                	beqz	a5,80000e6e <strlen+0x26>
    80000e54:	0505                	addi	a0,a0,1
    80000e56:	87aa                	mv	a5,a0
    80000e58:	4685                	li	a3,1
    80000e5a:	9e89                	subw	a3,a3,a0
    80000e5c:	00f6853b          	addw	a0,a3,a5
    80000e60:	0785                	addi	a5,a5,1
    80000e62:	fff7c703          	lbu	a4,-1(a5)
    80000e66:	fb7d                	bnez	a4,80000e5c <strlen+0x14>
    ;
  return n;
}
    80000e68:	6422                	ld	s0,8(sp)
    80000e6a:	0141                	addi	sp,sp,16
    80000e6c:	8082                	ret
  for(n = 0; s[n]; n++)
    80000e6e:	4501                	li	a0,0
    80000e70:	bfe5                	j	80000e68 <strlen+0x20>

0000000080000e72 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000e72:	1141                	addi	sp,sp,-16
    80000e74:	e406                	sd	ra,8(sp)
    80000e76:	e022                	sd	s0,0(sp)
    80000e78:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000e7a:	00001097          	auipc	ra,0x1
    80000e7e:	af0080e7          	jalr	-1296(ra) # 8000196a <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000e82:	00008717          	auipc	a4,0x8
    80000e86:	19670713          	addi	a4,a4,406 # 80009018 <started>
  if(cpuid() == 0){
    80000e8a:	c139                	beqz	a0,80000ed0 <main+0x5e>
    while(started == 0)
    80000e8c:	431c                	lw	a5,0(a4)
    80000e8e:	2781                	sext.w	a5,a5
    80000e90:	dff5                	beqz	a5,80000e8c <main+0x1a>
      ;
    __sync_synchronize();
    80000e92:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000e96:	00001097          	auipc	ra,0x1
    80000e9a:	ad4080e7          	jalr	-1324(ra) # 8000196a <cpuid>
    80000e9e:	85aa                	mv	a1,a0
    80000ea0:	00007517          	auipc	a0,0x7
    80000ea4:	21850513          	addi	a0,a0,536 # 800080b8 <digits+0x78>
    80000ea8:	fffff097          	auipc	ra,0xfffff
    80000eac:	6dc080e7          	jalr	1756(ra) # 80000584 <printf>
    kvminithart();    // turn on paging
    80000eb0:	00000097          	auipc	ra,0x0
    80000eb4:	0d8080e7          	jalr	216(ra) # 80000f88 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000eb8:	00002097          	auipc	ra,0x2
    80000ebc:	bf2080e7          	jalr	-1038(ra) # 80002aaa <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ec0:	00005097          	auipc	ra,0x5
    80000ec4:	3f0080e7          	jalr	1008(ra) # 800062b0 <plicinithart>
  }

  scheduler();        
    80000ec8:	00001097          	auipc	ra,0x1
    80000ecc:	020080e7          	jalr	32(ra) # 80001ee8 <scheduler>
    consoleinit();
    80000ed0:	fffff097          	auipc	ra,0xfffff
    80000ed4:	57a080e7          	jalr	1402(ra) # 8000044a <consoleinit>
    printfinit();
    80000ed8:	00000097          	auipc	ra,0x0
    80000edc:	88c080e7          	jalr	-1908(ra) # 80000764 <printfinit>
    printf("\n");
    80000ee0:	00007517          	auipc	a0,0x7
    80000ee4:	1e850513          	addi	a0,a0,488 # 800080c8 <digits+0x88>
    80000ee8:	fffff097          	auipc	ra,0xfffff
    80000eec:	69c080e7          	jalr	1692(ra) # 80000584 <printf>
    printf("xv6 kernel is booting\n");
    80000ef0:	00007517          	auipc	a0,0x7
    80000ef4:	1b050513          	addi	a0,a0,432 # 800080a0 <digits+0x60>
    80000ef8:	fffff097          	auipc	ra,0xfffff
    80000efc:	68c080e7          	jalr	1676(ra) # 80000584 <printf>
    printf("\n");
    80000f00:	00007517          	auipc	a0,0x7
    80000f04:	1c850513          	addi	a0,a0,456 # 800080c8 <digits+0x88>
    80000f08:	fffff097          	auipc	ra,0xfffff
    80000f0c:	67c080e7          	jalr	1660(ra) # 80000584 <printf>
    kinit();         // physical page allocator
    80000f10:	00000097          	auipc	ra,0x0
    80000f14:	b94080e7          	jalr	-1132(ra) # 80000aa4 <kinit>
    kvminit();       // create kernel page table
    80000f18:	00000097          	auipc	ra,0x0
    80000f1c:	322080e7          	jalr	802(ra) # 8000123a <kvminit>
    kvminithart();   // turn on paging
    80000f20:	00000097          	auipc	ra,0x0
    80000f24:	068080e7          	jalr	104(ra) # 80000f88 <kvminithart>
    procinit();      // process table
    80000f28:	00001097          	auipc	ra,0x1
    80000f2c:	992080e7          	jalr	-1646(ra) # 800018ba <procinit>
    trapinit();      // trap vectors
    80000f30:	00002097          	auipc	ra,0x2
    80000f34:	b52080e7          	jalr	-1198(ra) # 80002a82 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f38:	00002097          	auipc	ra,0x2
    80000f3c:	b72080e7          	jalr	-1166(ra) # 80002aaa <trapinithart>
    plicinit();      // set up interrupt controller
    80000f40:	00005097          	auipc	ra,0x5
    80000f44:	35a080e7          	jalr	858(ra) # 8000629a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f48:	00005097          	auipc	ra,0x5
    80000f4c:	368080e7          	jalr	872(ra) # 800062b0 <plicinithart>
    binit();         // buffer cache
    80000f50:	00002097          	auipc	ra,0x2
    80000f54:	528080e7          	jalr	1320(ra) # 80003478 <binit>
    iinit();         // inode table
    80000f58:	00003097          	auipc	ra,0x3
    80000f5c:	bb6080e7          	jalr	-1098(ra) # 80003b0e <iinit>
    fileinit();      // file table
    80000f60:	00004097          	auipc	ra,0x4
    80000f64:	b68080e7          	jalr	-1176(ra) # 80004ac8 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f68:	00005097          	auipc	ra,0x5
    80000f6c:	468080e7          	jalr	1128(ra) # 800063d0 <virtio_disk_init>
    userinit();      // first user process
    80000f70:	00001097          	auipc	ra,0x1
    80000f74:	d5c080e7          	jalr	-676(ra) # 80001ccc <userinit>
    __sync_synchronize();
    80000f78:	0ff0000f          	fence
    started = 1;
    80000f7c:	4785                	li	a5,1
    80000f7e:	00008717          	auipc	a4,0x8
    80000f82:	08f72d23          	sw	a5,154(a4) # 80009018 <started>
    80000f86:	b789                	j	80000ec8 <main+0x56>

0000000080000f88 <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000f88:	1141                	addi	sp,sp,-16
    80000f8a:	e422                	sd	s0,8(sp)
    80000f8c:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    80000f8e:	00008797          	auipc	a5,0x8
    80000f92:	0927b783          	ld	a5,146(a5) # 80009020 <kernel_pagetable>
    80000f96:	83b1                	srli	a5,a5,0xc
    80000f98:	577d                	li	a4,-1
    80000f9a:	177e                	slli	a4,a4,0x3f
    80000f9c:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000f9e:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000fa2:	12000073          	sfence.vma
  sfence_vma();
}
    80000fa6:	6422                	ld	s0,8(sp)
    80000fa8:	0141                	addi	sp,sp,16
    80000faa:	8082                	ret

0000000080000fac <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000fac:	7139                	addi	sp,sp,-64
    80000fae:	fc06                	sd	ra,56(sp)
    80000fb0:	f822                	sd	s0,48(sp)
    80000fb2:	f426                	sd	s1,40(sp)
    80000fb4:	f04a                	sd	s2,32(sp)
    80000fb6:	ec4e                	sd	s3,24(sp)
    80000fb8:	e852                	sd	s4,16(sp)
    80000fba:	e456                	sd	s5,8(sp)
    80000fbc:	e05a                	sd	s6,0(sp)
    80000fbe:	0080                	addi	s0,sp,64
    80000fc0:	84aa                	mv	s1,a0
    80000fc2:	89ae                	mv	s3,a1
    80000fc4:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000fc6:	57fd                	li	a5,-1
    80000fc8:	83e9                	srli	a5,a5,0x1a
    80000fca:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000fcc:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000fce:	04b7f263          	bgeu	a5,a1,80001012 <walk+0x66>
    panic("walk");
    80000fd2:	00007517          	auipc	a0,0x7
    80000fd6:	0fe50513          	addi	a0,a0,254 # 800080d0 <digits+0x90>
    80000fda:	fffff097          	auipc	ra,0xfffff
    80000fde:	560080e7          	jalr	1376(ra) # 8000053a <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80000fe2:	060a8663          	beqz	s5,8000104e <walk+0xa2>
    80000fe6:	00000097          	auipc	ra,0x0
    80000fea:	afa080e7          	jalr	-1286(ra) # 80000ae0 <kalloc>
    80000fee:	84aa                	mv	s1,a0
    80000ff0:	c529                	beqz	a0,8000103a <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80000ff2:	6605                	lui	a2,0x1
    80000ff4:	4581                	li	a1,0
    80000ff6:	00000097          	auipc	ra,0x0
    80000ffa:	cd6080e7          	jalr	-810(ra) # 80000ccc <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80000ffe:	00c4d793          	srli	a5,s1,0xc
    80001002:	07aa                	slli	a5,a5,0xa
    80001004:	0017e793          	ori	a5,a5,1
    80001008:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    8000100c:	3a5d                	addiw	s4,s4,-9
    8000100e:	036a0063          	beq	s4,s6,8000102e <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    80001012:	0149d933          	srl	s2,s3,s4
    80001016:	1ff97913          	andi	s2,s2,511
    8000101a:	090e                	slli	s2,s2,0x3
    8000101c:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    8000101e:	00093483          	ld	s1,0(s2)
    80001022:	0014f793          	andi	a5,s1,1
    80001026:	dfd5                	beqz	a5,80000fe2 <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001028:	80a9                	srli	s1,s1,0xa
    8000102a:	04b2                	slli	s1,s1,0xc
    8000102c:	b7c5                	j	8000100c <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    8000102e:	00c9d513          	srli	a0,s3,0xc
    80001032:	1ff57513          	andi	a0,a0,511
    80001036:	050e                	slli	a0,a0,0x3
    80001038:	9526                	add	a0,a0,s1
}
    8000103a:	70e2                	ld	ra,56(sp)
    8000103c:	7442                	ld	s0,48(sp)
    8000103e:	74a2                	ld	s1,40(sp)
    80001040:	7902                	ld	s2,32(sp)
    80001042:	69e2                	ld	s3,24(sp)
    80001044:	6a42                	ld	s4,16(sp)
    80001046:	6aa2                	ld	s5,8(sp)
    80001048:	6b02                	ld	s6,0(sp)
    8000104a:	6121                	addi	sp,sp,64
    8000104c:	8082                	ret
        return 0;
    8000104e:	4501                	li	a0,0
    80001050:	b7ed                	j	8000103a <walk+0x8e>

0000000080001052 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    80001052:	57fd                	li	a5,-1
    80001054:	83e9                	srli	a5,a5,0x1a
    80001056:	00b7f463          	bgeu	a5,a1,8000105e <walkaddr+0xc>
    return 0;
    8000105a:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    8000105c:	8082                	ret
{
    8000105e:	1141                	addi	sp,sp,-16
    80001060:	e406                	sd	ra,8(sp)
    80001062:	e022                	sd	s0,0(sp)
    80001064:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80001066:	4601                	li	a2,0
    80001068:	00000097          	auipc	ra,0x0
    8000106c:	f44080e7          	jalr	-188(ra) # 80000fac <walk>
  if(pte == 0)
    80001070:	c105                	beqz	a0,80001090 <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    80001072:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    80001074:	0117f693          	andi	a3,a5,17
    80001078:	4745                	li	a4,17
    return 0;
    8000107a:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    8000107c:	00e68663          	beq	a3,a4,80001088 <walkaddr+0x36>
}
    80001080:	60a2                	ld	ra,8(sp)
    80001082:	6402                	ld	s0,0(sp)
    80001084:	0141                	addi	sp,sp,16
    80001086:	8082                	ret
  pa = PTE2PA(*pte);
    80001088:	83a9                	srli	a5,a5,0xa
    8000108a:	00c79513          	slli	a0,a5,0xc
  return pa;
    8000108e:	bfcd                	j	80001080 <walkaddr+0x2e>
    return 0;
    80001090:	4501                	li	a0,0
    80001092:	b7fd                	j	80001080 <walkaddr+0x2e>

0000000080001094 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    80001094:	715d                	addi	sp,sp,-80
    80001096:	e486                	sd	ra,72(sp)
    80001098:	e0a2                	sd	s0,64(sp)
    8000109a:	fc26                	sd	s1,56(sp)
    8000109c:	f84a                	sd	s2,48(sp)
    8000109e:	f44e                	sd	s3,40(sp)
    800010a0:	f052                	sd	s4,32(sp)
    800010a2:	ec56                	sd	s5,24(sp)
    800010a4:	e85a                	sd	s6,16(sp)
    800010a6:	e45e                	sd	s7,8(sp)
    800010a8:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    800010aa:	c639                	beqz	a2,800010f8 <mappages+0x64>
    800010ac:	8aaa                	mv	s5,a0
    800010ae:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    800010b0:	777d                	lui	a4,0xfffff
    800010b2:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    800010b6:	fff58993          	addi	s3,a1,-1
    800010ba:	99b2                	add	s3,s3,a2
    800010bc:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    800010c0:	893e                	mv	s2,a5
    800010c2:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800010c6:	6b85                	lui	s7,0x1
    800010c8:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    800010cc:	4605                	li	a2,1
    800010ce:	85ca                	mv	a1,s2
    800010d0:	8556                	mv	a0,s5
    800010d2:	00000097          	auipc	ra,0x0
    800010d6:	eda080e7          	jalr	-294(ra) # 80000fac <walk>
    800010da:	cd1d                	beqz	a0,80001118 <mappages+0x84>
    if(*pte & PTE_V)
    800010dc:	611c                	ld	a5,0(a0)
    800010de:	8b85                	andi	a5,a5,1
    800010e0:	e785                	bnez	a5,80001108 <mappages+0x74>
    *pte = PA2PTE(pa) | perm | PTE_V;
    800010e2:	80b1                	srli	s1,s1,0xc
    800010e4:	04aa                	slli	s1,s1,0xa
    800010e6:	0164e4b3          	or	s1,s1,s6
    800010ea:	0014e493          	ori	s1,s1,1
    800010ee:	e104                	sd	s1,0(a0)
    if(a == last)
    800010f0:	05390063          	beq	s2,s3,80001130 <mappages+0x9c>
    a += PGSIZE;
    800010f4:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    800010f6:	bfc9                	j	800010c8 <mappages+0x34>
    panic("mappages: size");
    800010f8:	00007517          	auipc	a0,0x7
    800010fc:	fe050513          	addi	a0,a0,-32 # 800080d8 <digits+0x98>
    80001100:	fffff097          	auipc	ra,0xfffff
    80001104:	43a080e7          	jalr	1082(ra) # 8000053a <panic>
      panic("mappages: remap");
    80001108:	00007517          	auipc	a0,0x7
    8000110c:	fe050513          	addi	a0,a0,-32 # 800080e8 <digits+0xa8>
    80001110:	fffff097          	auipc	ra,0xfffff
    80001114:	42a080e7          	jalr	1066(ra) # 8000053a <panic>
      return -1;
    80001118:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    8000111a:	60a6                	ld	ra,72(sp)
    8000111c:	6406                	ld	s0,64(sp)
    8000111e:	74e2                	ld	s1,56(sp)
    80001120:	7942                	ld	s2,48(sp)
    80001122:	79a2                	ld	s3,40(sp)
    80001124:	7a02                	ld	s4,32(sp)
    80001126:	6ae2                	ld	s5,24(sp)
    80001128:	6b42                	ld	s6,16(sp)
    8000112a:	6ba2                	ld	s7,8(sp)
    8000112c:	6161                	addi	sp,sp,80
    8000112e:	8082                	ret
  return 0;
    80001130:	4501                	li	a0,0
    80001132:	b7e5                	j	8000111a <mappages+0x86>

0000000080001134 <kvmmap>:
{
    80001134:	1141                	addi	sp,sp,-16
    80001136:	e406                	sd	ra,8(sp)
    80001138:	e022                	sd	s0,0(sp)
    8000113a:	0800                	addi	s0,sp,16
    8000113c:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    8000113e:	86b2                	mv	a3,a2
    80001140:	863e                	mv	a2,a5
    80001142:	00000097          	auipc	ra,0x0
    80001146:	f52080e7          	jalr	-174(ra) # 80001094 <mappages>
    8000114a:	e509                	bnez	a0,80001154 <kvmmap+0x20>
}
    8000114c:	60a2                	ld	ra,8(sp)
    8000114e:	6402                	ld	s0,0(sp)
    80001150:	0141                	addi	sp,sp,16
    80001152:	8082                	ret
    panic("kvmmap");
    80001154:	00007517          	auipc	a0,0x7
    80001158:	fa450513          	addi	a0,a0,-92 # 800080f8 <digits+0xb8>
    8000115c:	fffff097          	auipc	ra,0xfffff
    80001160:	3de080e7          	jalr	990(ra) # 8000053a <panic>

0000000080001164 <kvmmake>:
{
    80001164:	1101                	addi	sp,sp,-32
    80001166:	ec06                	sd	ra,24(sp)
    80001168:	e822                	sd	s0,16(sp)
    8000116a:	e426                	sd	s1,8(sp)
    8000116c:	e04a                	sd	s2,0(sp)
    8000116e:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    80001170:	00000097          	auipc	ra,0x0
    80001174:	970080e7          	jalr	-1680(ra) # 80000ae0 <kalloc>
    80001178:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    8000117a:	6605                	lui	a2,0x1
    8000117c:	4581                	li	a1,0
    8000117e:	00000097          	auipc	ra,0x0
    80001182:	b4e080e7          	jalr	-1202(ra) # 80000ccc <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    80001186:	4719                	li	a4,6
    80001188:	6685                	lui	a3,0x1
    8000118a:	10000637          	lui	a2,0x10000
    8000118e:	100005b7          	lui	a1,0x10000
    80001192:	8526                	mv	a0,s1
    80001194:	00000097          	auipc	ra,0x0
    80001198:	fa0080e7          	jalr	-96(ra) # 80001134 <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    8000119c:	4719                	li	a4,6
    8000119e:	6685                	lui	a3,0x1
    800011a0:	10001637          	lui	a2,0x10001
    800011a4:	100015b7          	lui	a1,0x10001
    800011a8:	8526                	mv	a0,s1
    800011aa:	00000097          	auipc	ra,0x0
    800011ae:	f8a080e7          	jalr	-118(ra) # 80001134 <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800011b2:	4719                	li	a4,6
    800011b4:	004006b7          	lui	a3,0x400
    800011b8:	0c000637          	lui	a2,0xc000
    800011bc:	0c0005b7          	lui	a1,0xc000
    800011c0:	8526                	mv	a0,s1
    800011c2:	00000097          	auipc	ra,0x0
    800011c6:	f72080e7          	jalr	-142(ra) # 80001134 <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800011ca:	00007917          	auipc	s2,0x7
    800011ce:	e3690913          	addi	s2,s2,-458 # 80008000 <etext>
    800011d2:	4729                	li	a4,10
    800011d4:	80007697          	auipc	a3,0x80007
    800011d8:	e2c68693          	addi	a3,a3,-468 # 8000 <_entry-0x7fff8000>
    800011dc:	4605                	li	a2,1
    800011de:	067e                	slli	a2,a2,0x1f
    800011e0:	85b2                	mv	a1,a2
    800011e2:	8526                	mv	a0,s1
    800011e4:	00000097          	auipc	ra,0x0
    800011e8:	f50080e7          	jalr	-176(ra) # 80001134 <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    800011ec:	4719                	li	a4,6
    800011ee:	46c5                	li	a3,17
    800011f0:	06ee                	slli	a3,a3,0x1b
    800011f2:	412686b3          	sub	a3,a3,s2
    800011f6:	864a                	mv	a2,s2
    800011f8:	85ca                	mv	a1,s2
    800011fa:	8526                	mv	a0,s1
    800011fc:	00000097          	auipc	ra,0x0
    80001200:	f38080e7          	jalr	-200(ra) # 80001134 <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80001204:	4729                	li	a4,10
    80001206:	6685                	lui	a3,0x1
    80001208:	00006617          	auipc	a2,0x6
    8000120c:	df860613          	addi	a2,a2,-520 # 80007000 <_trampoline>
    80001210:	040005b7          	lui	a1,0x4000
    80001214:	15fd                	addi	a1,a1,-1
    80001216:	05b2                	slli	a1,a1,0xc
    80001218:	8526                	mv	a0,s1
    8000121a:	00000097          	auipc	ra,0x0
    8000121e:	f1a080e7          	jalr	-230(ra) # 80001134 <kvmmap>
  proc_mapstacks(kpgtbl);
    80001222:	8526                	mv	a0,s1
    80001224:	00000097          	auipc	ra,0x0
    80001228:	600080e7          	jalr	1536(ra) # 80001824 <proc_mapstacks>
}
    8000122c:	8526                	mv	a0,s1
    8000122e:	60e2                	ld	ra,24(sp)
    80001230:	6442                	ld	s0,16(sp)
    80001232:	64a2                	ld	s1,8(sp)
    80001234:	6902                	ld	s2,0(sp)
    80001236:	6105                	addi	sp,sp,32
    80001238:	8082                	ret

000000008000123a <kvminit>:
{
    8000123a:	1141                	addi	sp,sp,-16
    8000123c:	e406                	sd	ra,8(sp)
    8000123e:	e022                	sd	s0,0(sp)
    80001240:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    80001242:	00000097          	auipc	ra,0x0
    80001246:	f22080e7          	jalr	-222(ra) # 80001164 <kvmmake>
    8000124a:	00008797          	auipc	a5,0x8
    8000124e:	dca7bb23          	sd	a0,-554(a5) # 80009020 <kernel_pagetable>
}
    80001252:	60a2                	ld	ra,8(sp)
    80001254:	6402                	ld	s0,0(sp)
    80001256:	0141                	addi	sp,sp,16
    80001258:	8082                	ret

000000008000125a <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    8000125a:	715d                	addi	sp,sp,-80
    8000125c:	e486                	sd	ra,72(sp)
    8000125e:	e0a2                	sd	s0,64(sp)
    80001260:	fc26                	sd	s1,56(sp)
    80001262:	f84a                	sd	s2,48(sp)
    80001264:	f44e                	sd	s3,40(sp)
    80001266:	f052                	sd	s4,32(sp)
    80001268:	ec56                	sd	s5,24(sp)
    8000126a:	e85a                	sd	s6,16(sp)
    8000126c:	e45e                	sd	s7,8(sp)
    8000126e:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    80001270:	03459793          	slli	a5,a1,0x34
    80001274:	e795                	bnez	a5,800012a0 <uvmunmap+0x46>
    80001276:	8a2a                	mv	s4,a0
    80001278:	892e                	mv	s2,a1
    8000127a:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000127c:	0632                	slli	a2,a2,0xc
    8000127e:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    80001282:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001284:	6b05                	lui	s6,0x1
    80001286:	0735e263          	bltu	a1,s3,800012ea <uvmunmap+0x90>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    8000128a:	60a6                	ld	ra,72(sp)
    8000128c:	6406                	ld	s0,64(sp)
    8000128e:	74e2                	ld	s1,56(sp)
    80001290:	7942                	ld	s2,48(sp)
    80001292:	79a2                	ld	s3,40(sp)
    80001294:	7a02                	ld	s4,32(sp)
    80001296:	6ae2                	ld	s5,24(sp)
    80001298:	6b42                	ld	s6,16(sp)
    8000129a:	6ba2                	ld	s7,8(sp)
    8000129c:	6161                	addi	sp,sp,80
    8000129e:	8082                	ret
    panic("uvmunmap: not aligned");
    800012a0:	00007517          	auipc	a0,0x7
    800012a4:	e6050513          	addi	a0,a0,-416 # 80008100 <digits+0xc0>
    800012a8:	fffff097          	auipc	ra,0xfffff
    800012ac:	292080e7          	jalr	658(ra) # 8000053a <panic>
      panic("uvmunmap: walk");
    800012b0:	00007517          	auipc	a0,0x7
    800012b4:	e6850513          	addi	a0,a0,-408 # 80008118 <digits+0xd8>
    800012b8:	fffff097          	auipc	ra,0xfffff
    800012bc:	282080e7          	jalr	642(ra) # 8000053a <panic>
      panic("uvmunmap: not mapped");
    800012c0:	00007517          	auipc	a0,0x7
    800012c4:	e6850513          	addi	a0,a0,-408 # 80008128 <digits+0xe8>
    800012c8:	fffff097          	auipc	ra,0xfffff
    800012cc:	272080e7          	jalr	626(ra) # 8000053a <panic>
      panic("uvmunmap: not a leaf");
    800012d0:	00007517          	auipc	a0,0x7
    800012d4:	e7050513          	addi	a0,a0,-400 # 80008140 <digits+0x100>
    800012d8:	fffff097          	auipc	ra,0xfffff
    800012dc:	262080e7          	jalr	610(ra) # 8000053a <panic>
    *pte = 0;
    800012e0:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012e4:	995a                	add	s2,s2,s6
    800012e6:	fb3972e3          	bgeu	s2,s3,8000128a <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    800012ea:	4601                	li	a2,0
    800012ec:	85ca                	mv	a1,s2
    800012ee:	8552                	mv	a0,s4
    800012f0:	00000097          	auipc	ra,0x0
    800012f4:	cbc080e7          	jalr	-836(ra) # 80000fac <walk>
    800012f8:	84aa                	mv	s1,a0
    800012fa:	d95d                	beqz	a0,800012b0 <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    800012fc:	6108                	ld	a0,0(a0)
    800012fe:	00157793          	andi	a5,a0,1
    80001302:	dfdd                	beqz	a5,800012c0 <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    80001304:	3ff57793          	andi	a5,a0,1023
    80001308:	fd7784e3          	beq	a5,s7,800012d0 <uvmunmap+0x76>
    if(do_free){
    8000130c:	fc0a8ae3          	beqz	s5,800012e0 <uvmunmap+0x86>
      uint64 pa = PTE2PA(*pte);
    80001310:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    80001312:	0532                	slli	a0,a0,0xc
    80001314:	fffff097          	auipc	ra,0xfffff
    80001318:	6ce080e7          	jalr	1742(ra) # 800009e2 <kfree>
    8000131c:	b7d1                	j	800012e0 <uvmunmap+0x86>

000000008000131e <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    8000131e:	1101                	addi	sp,sp,-32
    80001320:	ec06                	sd	ra,24(sp)
    80001322:	e822                	sd	s0,16(sp)
    80001324:	e426                	sd	s1,8(sp)
    80001326:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    80001328:	fffff097          	auipc	ra,0xfffff
    8000132c:	7b8080e7          	jalr	1976(ra) # 80000ae0 <kalloc>
    80001330:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001332:	c519                	beqz	a0,80001340 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    80001334:	6605                	lui	a2,0x1
    80001336:	4581                	li	a1,0
    80001338:	00000097          	auipc	ra,0x0
    8000133c:	994080e7          	jalr	-1644(ra) # 80000ccc <memset>
  return pagetable;
}
    80001340:	8526                	mv	a0,s1
    80001342:	60e2                	ld	ra,24(sp)
    80001344:	6442                	ld	s0,16(sp)
    80001346:	64a2                	ld	s1,8(sp)
    80001348:	6105                	addi	sp,sp,32
    8000134a:	8082                	ret

000000008000134c <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    8000134c:	7179                	addi	sp,sp,-48
    8000134e:	f406                	sd	ra,40(sp)
    80001350:	f022                	sd	s0,32(sp)
    80001352:	ec26                	sd	s1,24(sp)
    80001354:	e84a                	sd	s2,16(sp)
    80001356:	e44e                	sd	s3,8(sp)
    80001358:	e052                	sd	s4,0(sp)
    8000135a:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    8000135c:	6785                	lui	a5,0x1
    8000135e:	04f67863          	bgeu	a2,a5,800013ae <uvminit+0x62>
    80001362:	8a2a                	mv	s4,a0
    80001364:	89ae                	mv	s3,a1
    80001366:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    80001368:	fffff097          	auipc	ra,0xfffff
    8000136c:	778080e7          	jalr	1912(ra) # 80000ae0 <kalloc>
    80001370:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    80001372:	6605                	lui	a2,0x1
    80001374:	4581                	li	a1,0
    80001376:	00000097          	auipc	ra,0x0
    8000137a:	956080e7          	jalr	-1706(ra) # 80000ccc <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    8000137e:	4779                	li	a4,30
    80001380:	86ca                	mv	a3,s2
    80001382:	6605                	lui	a2,0x1
    80001384:	4581                	li	a1,0
    80001386:	8552                	mv	a0,s4
    80001388:	00000097          	auipc	ra,0x0
    8000138c:	d0c080e7          	jalr	-756(ra) # 80001094 <mappages>
  memmove(mem, src, sz);
    80001390:	8626                	mv	a2,s1
    80001392:	85ce                	mv	a1,s3
    80001394:	854a                	mv	a0,s2
    80001396:	00000097          	auipc	ra,0x0
    8000139a:	992080e7          	jalr	-1646(ra) # 80000d28 <memmove>
}
    8000139e:	70a2                	ld	ra,40(sp)
    800013a0:	7402                	ld	s0,32(sp)
    800013a2:	64e2                	ld	s1,24(sp)
    800013a4:	6942                	ld	s2,16(sp)
    800013a6:	69a2                	ld	s3,8(sp)
    800013a8:	6a02                	ld	s4,0(sp)
    800013aa:	6145                	addi	sp,sp,48
    800013ac:	8082                	ret
    panic("inituvm: more than a page");
    800013ae:	00007517          	auipc	a0,0x7
    800013b2:	daa50513          	addi	a0,a0,-598 # 80008158 <digits+0x118>
    800013b6:	fffff097          	auipc	ra,0xfffff
    800013ba:	184080e7          	jalr	388(ra) # 8000053a <panic>

00000000800013be <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800013be:	1101                	addi	sp,sp,-32
    800013c0:	ec06                	sd	ra,24(sp)
    800013c2:	e822                	sd	s0,16(sp)
    800013c4:	e426                	sd	s1,8(sp)
    800013c6:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800013c8:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800013ca:	00b67d63          	bgeu	a2,a1,800013e4 <uvmdealloc+0x26>
    800013ce:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800013d0:	6785                	lui	a5,0x1
    800013d2:	17fd                	addi	a5,a5,-1
    800013d4:	00f60733          	add	a4,a2,a5
    800013d8:	76fd                	lui	a3,0xfffff
    800013da:	8f75                	and	a4,a4,a3
    800013dc:	97ae                	add	a5,a5,a1
    800013de:	8ff5                	and	a5,a5,a3
    800013e0:	00f76863          	bltu	a4,a5,800013f0 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    800013e4:	8526                	mv	a0,s1
    800013e6:	60e2                	ld	ra,24(sp)
    800013e8:	6442                	ld	s0,16(sp)
    800013ea:	64a2                	ld	s1,8(sp)
    800013ec:	6105                	addi	sp,sp,32
    800013ee:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    800013f0:	8f99                	sub	a5,a5,a4
    800013f2:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    800013f4:	4685                	li	a3,1
    800013f6:	0007861b          	sext.w	a2,a5
    800013fa:	85ba                	mv	a1,a4
    800013fc:	00000097          	auipc	ra,0x0
    80001400:	e5e080e7          	jalr	-418(ra) # 8000125a <uvmunmap>
    80001404:	b7c5                	j	800013e4 <uvmdealloc+0x26>

0000000080001406 <uvmalloc>:
  if(newsz < oldsz)
    80001406:	0ab66163          	bltu	a2,a1,800014a8 <uvmalloc+0xa2>
{
    8000140a:	7139                	addi	sp,sp,-64
    8000140c:	fc06                	sd	ra,56(sp)
    8000140e:	f822                	sd	s0,48(sp)
    80001410:	f426                	sd	s1,40(sp)
    80001412:	f04a                	sd	s2,32(sp)
    80001414:	ec4e                	sd	s3,24(sp)
    80001416:	e852                	sd	s4,16(sp)
    80001418:	e456                	sd	s5,8(sp)
    8000141a:	0080                	addi	s0,sp,64
    8000141c:	8aaa                	mv	s5,a0
    8000141e:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    80001420:	6785                	lui	a5,0x1
    80001422:	17fd                	addi	a5,a5,-1
    80001424:	95be                	add	a1,a1,a5
    80001426:	77fd                	lui	a5,0xfffff
    80001428:	00f5f9b3          	and	s3,a1,a5
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000142c:	08c9f063          	bgeu	s3,a2,800014ac <uvmalloc+0xa6>
    80001430:	894e                	mv	s2,s3
    mem = kalloc();
    80001432:	fffff097          	auipc	ra,0xfffff
    80001436:	6ae080e7          	jalr	1710(ra) # 80000ae0 <kalloc>
    8000143a:	84aa                	mv	s1,a0
    if(mem == 0){
    8000143c:	c51d                	beqz	a0,8000146a <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    8000143e:	6605                	lui	a2,0x1
    80001440:	4581                	li	a1,0
    80001442:	00000097          	auipc	ra,0x0
    80001446:	88a080e7          	jalr	-1910(ra) # 80000ccc <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    8000144a:	4779                	li	a4,30
    8000144c:	86a6                	mv	a3,s1
    8000144e:	6605                	lui	a2,0x1
    80001450:	85ca                	mv	a1,s2
    80001452:	8556                	mv	a0,s5
    80001454:	00000097          	auipc	ra,0x0
    80001458:	c40080e7          	jalr	-960(ra) # 80001094 <mappages>
    8000145c:	e905                	bnez	a0,8000148c <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000145e:	6785                	lui	a5,0x1
    80001460:	993e                	add	s2,s2,a5
    80001462:	fd4968e3          	bltu	s2,s4,80001432 <uvmalloc+0x2c>
  return newsz;
    80001466:	8552                	mv	a0,s4
    80001468:	a809                	j	8000147a <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    8000146a:	864e                	mv	a2,s3
    8000146c:	85ca                	mv	a1,s2
    8000146e:	8556                	mv	a0,s5
    80001470:	00000097          	auipc	ra,0x0
    80001474:	f4e080e7          	jalr	-178(ra) # 800013be <uvmdealloc>
      return 0;
    80001478:	4501                	li	a0,0
}
    8000147a:	70e2                	ld	ra,56(sp)
    8000147c:	7442                	ld	s0,48(sp)
    8000147e:	74a2                	ld	s1,40(sp)
    80001480:	7902                	ld	s2,32(sp)
    80001482:	69e2                	ld	s3,24(sp)
    80001484:	6a42                	ld	s4,16(sp)
    80001486:	6aa2                	ld	s5,8(sp)
    80001488:	6121                	addi	sp,sp,64
    8000148a:	8082                	ret
      kfree(mem);
    8000148c:	8526                	mv	a0,s1
    8000148e:	fffff097          	auipc	ra,0xfffff
    80001492:	554080e7          	jalr	1364(ra) # 800009e2 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    80001496:	864e                	mv	a2,s3
    80001498:	85ca                	mv	a1,s2
    8000149a:	8556                	mv	a0,s5
    8000149c:	00000097          	auipc	ra,0x0
    800014a0:	f22080e7          	jalr	-222(ra) # 800013be <uvmdealloc>
      return 0;
    800014a4:	4501                	li	a0,0
    800014a6:	bfd1                	j	8000147a <uvmalloc+0x74>
    return oldsz;
    800014a8:	852e                	mv	a0,a1
}
    800014aa:	8082                	ret
  return newsz;
    800014ac:	8532                	mv	a0,a2
    800014ae:	b7f1                	j	8000147a <uvmalloc+0x74>

00000000800014b0 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800014b0:	7179                	addi	sp,sp,-48
    800014b2:	f406                	sd	ra,40(sp)
    800014b4:	f022                	sd	s0,32(sp)
    800014b6:	ec26                	sd	s1,24(sp)
    800014b8:	e84a                	sd	s2,16(sp)
    800014ba:	e44e                	sd	s3,8(sp)
    800014bc:	e052                	sd	s4,0(sp)
    800014be:	1800                	addi	s0,sp,48
    800014c0:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800014c2:	84aa                	mv	s1,a0
    800014c4:	6905                	lui	s2,0x1
    800014c6:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014c8:	4985                	li	s3,1
    800014ca:	a829                	j	800014e4 <freewalk+0x34>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800014cc:	83a9                	srli	a5,a5,0xa
      freewalk((pagetable_t)child);
    800014ce:	00c79513          	slli	a0,a5,0xc
    800014d2:	00000097          	auipc	ra,0x0
    800014d6:	fde080e7          	jalr	-34(ra) # 800014b0 <freewalk>
      pagetable[i] = 0;
    800014da:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800014de:	04a1                	addi	s1,s1,8
    800014e0:	03248163          	beq	s1,s2,80001502 <freewalk+0x52>
    pte_t pte = pagetable[i];
    800014e4:	609c                	ld	a5,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014e6:	00f7f713          	andi	a4,a5,15
    800014ea:	ff3701e3          	beq	a4,s3,800014cc <freewalk+0x1c>
    } else if(pte & PTE_V){
    800014ee:	8b85                	andi	a5,a5,1
    800014f0:	d7fd                	beqz	a5,800014de <freewalk+0x2e>
      panic("freewalk: leaf");
    800014f2:	00007517          	auipc	a0,0x7
    800014f6:	c8650513          	addi	a0,a0,-890 # 80008178 <digits+0x138>
    800014fa:	fffff097          	auipc	ra,0xfffff
    800014fe:	040080e7          	jalr	64(ra) # 8000053a <panic>
    }
  }
  kfree((void*)pagetable);
    80001502:	8552                	mv	a0,s4
    80001504:	fffff097          	auipc	ra,0xfffff
    80001508:	4de080e7          	jalr	1246(ra) # 800009e2 <kfree>
}
    8000150c:	70a2                	ld	ra,40(sp)
    8000150e:	7402                	ld	s0,32(sp)
    80001510:	64e2                	ld	s1,24(sp)
    80001512:	6942                	ld	s2,16(sp)
    80001514:	69a2                	ld	s3,8(sp)
    80001516:	6a02                	ld	s4,0(sp)
    80001518:	6145                	addi	sp,sp,48
    8000151a:	8082                	ret

000000008000151c <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    8000151c:	1101                	addi	sp,sp,-32
    8000151e:	ec06                	sd	ra,24(sp)
    80001520:	e822                	sd	s0,16(sp)
    80001522:	e426                	sd	s1,8(sp)
    80001524:	1000                	addi	s0,sp,32
    80001526:	84aa                	mv	s1,a0
  if(sz > 0)
    80001528:	e999                	bnez	a1,8000153e <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    8000152a:	8526                	mv	a0,s1
    8000152c:	00000097          	auipc	ra,0x0
    80001530:	f84080e7          	jalr	-124(ra) # 800014b0 <freewalk>
}
    80001534:	60e2                	ld	ra,24(sp)
    80001536:	6442                	ld	s0,16(sp)
    80001538:	64a2                	ld	s1,8(sp)
    8000153a:	6105                	addi	sp,sp,32
    8000153c:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    8000153e:	6785                	lui	a5,0x1
    80001540:	17fd                	addi	a5,a5,-1
    80001542:	95be                	add	a1,a1,a5
    80001544:	4685                	li	a3,1
    80001546:	00c5d613          	srli	a2,a1,0xc
    8000154a:	4581                	li	a1,0
    8000154c:	00000097          	auipc	ra,0x0
    80001550:	d0e080e7          	jalr	-754(ra) # 8000125a <uvmunmap>
    80001554:	bfd9                	j	8000152a <uvmfree+0xe>

0000000080001556 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    80001556:	c679                	beqz	a2,80001624 <uvmcopy+0xce>
{
    80001558:	715d                	addi	sp,sp,-80
    8000155a:	e486                	sd	ra,72(sp)
    8000155c:	e0a2                	sd	s0,64(sp)
    8000155e:	fc26                	sd	s1,56(sp)
    80001560:	f84a                	sd	s2,48(sp)
    80001562:	f44e                	sd	s3,40(sp)
    80001564:	f052                	sd	s4,32(sp)
    80001566:	ec56                	sd	s5,24(sp)
    80001568:	e85a                	sd	s6,16(sp)
    8000156a:	e45e                	sd	s7,8(sp)
    8000156c:	0880                	addi	s0,sp,80
    8000156e:	8b2a                	mv	s6,a0
    80001570:	8aae                	mv	s5,a1
    80001572:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    80001574:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    80001576:	4601                	li	a2,0
    80001578:	85ce                	mv	a1,s3
    8000157a:	855a                	mv	a0,s6
    8000157c:	00000097          	auipc	ra,0x0
    80001580:	a30080e7          	jalr	-1488(ra) # 80000fac <walk>
    80001584:	c531                	beqz	a0,800015d0 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    80001586:	6118                	ld	a4,0(a0)
    80001588:	00177793          	andi	a5,a4,1
    8000158c:	cbb1                	beqz	a5,800015e0 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    8000158e:	00a75593          	srli	a1,a4,0xa
    80001592:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    80001596:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    8000159a:	fffff097          	auipc	ra,0xfffff
    8000159e:	546080e7          	jalr	1350(ra) # 80000ae0 <kalloc>
    800015a2:	892a                	mv	s2,a0
    800015a4:	c939                	beqz	a0,800015fa <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800015a6:	6605                	lui	a2,0x1
    800015a8:	85de                	mv	a1,s7
    800015aa:	fffff097          	auipc	ra,0xfffff
    800015ae:	77e080e7          	jalr	1918(ra) # 80000d28 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800015b2:	8726                	mv	a4,s1
    800015b4:	86ca                	mv	a3,s2
    800015b6:	6605                	lui	a2,0x1
    800015b8:	85ce                	mv	a1,s3
    800015ba:	8556                	mv	a0,s5
    800015bc:	00000097          	auipc	ra,0x0
    800015c0:	ad8080e7          	jalr	-1320(ra) # 80001094 <mappages>
    800015c4:	e515                	bnez	a0,800015f0 <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800015c6:	6785                	lui	a5,0x1
    800015c8:	99be                	add	s3,s3,a5
    800015ca:	fb49e6e3          	bltu	s3,s4,80001576 <uvmcopy+0x20>
    800015ce:	a081                	j	8000160e <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800015d0:	00007517          	auipc	a0,0x7
    800015d4:	bb850513          	addi	a0,a0,-1096 # 80008188 <digits+0x148>
    800015d8:	fffff097          	auipc	ra,0xfffff
    800015dc:	f62080e7          	jalr	-158(ra) # 8000053a <panic>
      panic("uvmcopy: page not present");
    800015e0:	00007517          	auipc	a0,0x7
    800015e4:	bc850513          	addi	a0,a0,-1080 # 800081a8 <digits+0x168>
    800015e8:	fffff097          	auipc	ra,0xfffff
    800015ec:	f52080e7          	jalr	-174(ra) # 8000053a <panic>
      kfree(mem);
    800015f0:	854a                	mv	a0,s2
    800015f2:	fffff097          	auipc	ra,0xfffff
    800015f6:	3f0080e7          	jalr	1008(ra) # 800009e2 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    800015fa:	4685                	li	a3,1
    800015fc:	00c9d613          	srli	a2,s3,0xc
    80001600:	4581                	li	a1,0
    80001602:	8556                	mv	a0,s5
    80001604:	00000097          	auipc	ra,0x0
    80001608:	c56080e7          	jalr	-938(ra) # 8000125a <uvmunmap>
  return -1;
    8000160c:	557d                	li	a0,-1
}
    8000160e:	60a6                	ld	ra,72(sp)
    80001610:	6406                	ld	s0,64(sp)
    80001612:	74e2                	ld	s1,56(sp)
    80001614:	7942                	ld	s2,48(sp)
    80001616:	79a2                	ld	s3,40(sp)
    80001618:	7a02                	ld	s4,32(sp)
    8000161a:	6ae2                	ld	s5,24(sp)
    8000161c:	6b42                	ld	s6,16(sp)
    8000161e:	6ba2                	ld	s7,8(sp)
    80001620:	6161                	addi	sp,sp,80
    80001622:	8082                	ret
  return 0;
    80001624:	4501                	li	a0,0
}
    80001626:	8082                	ret

0000000080001628 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001628:	1141                	addi	sp,sp,-16
    8000162a:	e406                	sd	ra,8(sp)
    8000162c:	e022                	sd	s0,0(sp)
    8000162e:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001630:	4601                	li	a2,0
    80001632:	00000097          	auipc	ra,0x0
    80001636:	97a080e7          	jalr	-1670(ra) # 80000fac <walk>
  if(pte == 0)
    8000163a:	c901                	beqz	a0,8000164a <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    8000163c:	611c                	ld	a5,0(a0)
    8000163e:	9bbd                	andi	a5,a5,-17
    80001640:	e11c                	sd	a5,0(a0)
}
    80001642:	60a2                	ld	ra,8(sp)
    80001644:	6402                	ld	s0,0(sp)
    80001646:	0141                	addi	sp,sp,16
    80001648:	8082                	ret
    panic("uvmclear");
    8000164a:	00007517          	auipc	a0,0x7
    8000164e:	b7e50513          	addi	a0,a0,-1154 # 800081c8 <digits+0x188>
    80001652:	fffff097          	auipc	ra,0xfffff
    80001656:	ee8080e7          	jalr	-280(ra) # 8000053a <panic>

000000008000165a <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    8000165a:	c6bd                	beqz	a3,800016c8 <copyout+0x6e>
{
    8000165c:	715d                	addi	sp,sp,-80
    8000165e:	e486                	sd	ra,72(sp)
    80001660:	e0a2                	sd	s0,64(sp)
    80001662:	fc26                	sd	s1,56(sp)
    80001664:	f84a                	sd	s2,48(sp)
    80001666:	f44e                	sd	s3,40(sp)
    80001668:	f052                	sd	s4,32(sp)
    8000166a:	ec56                	sd	s5,24(sp)
    8000166c:	e85a                	sd	s6,16(sp)
    8000166e:	e45e                	sd	s7,8(sp)
    80001670:	e062                	sd	s8,0(sp)
    80001672:	0880                	addi	s0,sp,80
    80001674:	8b2a                	mv	s6,a0
    80001676:	8c2e                	mv	s8,a1
    80001678:	8a32                	mv	s4,a2
    8000167a:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    8000167c:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    8000167e:	6a85                	lui	s5,0x1
    80001680:	a015                	j	800016a4 <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    80001682:	9562                	add	a0,a0,s8
    80001684:	0004861b          	sext.w	a2,s1
    80001688:	85d2                	mv	a1,s4
    8000168a:	41250533          	sub	a0,a0,s2
    8000168e:	fffff097          	auipc	ra,0xfffff
    80001692:	69a080e7          	jalr	1690(ra) # 80000d28 <memmove>

    len -= n;
    80001696:	409989b3          	sub	s3,s3,s1
    src += n;
    8000169a:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    8000169c:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800016a0:	02098263          	beqz	s3,800016c4 <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800016a4:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800016a8:	85ca                	mv	a1,s2
    800016aa:	855a                	mv	a0,s6
    800016ac:	00000097          	auipc	ra,0x0
    800016b0:	9a6080e7          	jalr	-1626(ra) # 80001052 <walkaddr>
    if(pa0 == 0)
    800016b4:	cd01                	beqz	a0,800016cc <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800016b6:	418904b3          	sub	s1,s2,s8
    800016ba:	94d6                	add	s1,s1,s5
    800016bc:	fc99f3e3          	bgeu	s3,s1,80001682 <copyout+0x28>
    800016c0:	84ce                	mv	s1,s3
    800016c2:	b7c1                	j	80001682 <copyout+0x28>
  }
  return 0;
    800016c4:	4501                	li	a0,0
    800016c6:	a021                	j	800016ce <copyout+0x74>
    800016c8:	4501                	li	a0,0
}
    800016ca:	8082                	ret
      return -1;
    800016cc:	557d                	li	a0,-1
}
    800016ce:	60a6                	ld	ra,72(sp)
    800016d0:	6406                	ld	s0,64(sp)
    800016d2:	74e2                	ld	s1,56(sp)
    800016d4:	7942                	ld	s2,48(sp)
    800016d6:	79a2                	ld	s3,40(sp)
    800016d8:	7a02                	ld	s4,32(sp)
    800016da:	6ae2                	ld	s5,24(sp)
    800016dc:	6b42                	ld	s6,16(sp)
    800016de:	6ba2                	ld	s7,8(sp)
    800016e0:	6c02                	ld	s8,0(sp)
    800016e2:	6161                	addi	sp,sp,80
    800016e4:	8082                	ret

00000000800016e6 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800016e6:	caa5                	beqz	a3,80001756 <copyin+0x70>
{
    800016e8:	715d                	addi	sp,sp,-80
    800016ea:	e486                	sd	ra,72(sp)
    800016ec:	e0a2                	sd	s0,64(sp)
    800016ee:	fc26                	sd	s1,56(sp)
    800016f0:	f84a                	sd	s2,48(sp)
    800016f2:	f44e                	sd	s3,40(sp)
    800016f4:	f052                	sd	s4,32(sp)
    800016f6:	ec56                	sd	s5,24(sp)
    800016f8:	e85a                	sd	s6,16(sp)
    800016fa:	e45e                	sd	s7,8(sp)
    800016fc:	e062                	sd	s8,0(sp)
    800016fe:	0880                	addi	s0,sp,80
    80001700:	8b2a                	mv	s6,a0
    80001702:	8a2e                	mv	s4,a1
    80001704:	8c32                	mv	s8,a2
    80001706:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001708:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    8000170a:	6a85                	lui	s5,0x1
    8000170c:	a01d                	j	80001732 <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    8000170e:	018505b3          	add	a1,a0,s8
    80001712:	0004861b          	sext.w	a2,s1
    80001716:	412585b3          	sub	a1,a1,s2
    8000171a:	8552                	mv	a0,s4
    8000171c:	fffff097          	auipc	ra,0xfffff
    80001720:	60c080e7          	jalr	1548(ra) # 80000d28 <memmove>

    len -= n;
    80001724:	409989b3          	sub	s3,s3,s1
    dst += n;
    80001728:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    8000172a:	01590c33          	add	s8,s2,s5
  while(len > 0){
    8000172e:	02098263          	beqz	s3,80001752 <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    80001732:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001736:	85ca                	mv	a1,s2
    80001738:	855a                	mv	a0,s6
    8000173a:	00000097          	auipc	ra,0x0
    8000173e:	918080e7          	jalr	-1768(ra) # 80001052 <walkaddr>
    if(pa0 == 0)
    80001742:	cd01                	beqz	a0,8000175a <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    80001744:	418904b3          	sub	s1,s2,s8
    80001748:	94d6                	add	s1,s1,s5
    8000174a:	fc99f2e3          	bgeu	s3,s1,8000170e <copyin+0x28>
    8000174e:	84ce                	mv	s1,s3
    80001750:	bf7d                	j	8000170e <copyin+0x28>
  }
  return 0;
    80001752:	4501                	li	a0,0
    80001754:	a021                	j	8000175c <copyin+0x76>
    80001756:	4501                	li	a0,0
}
    80001758:	8082                	ret
      return -1;
    8000175a:	557d                	li	a0,-1
}
    8000175c:	60a6                	ld	ra,72(sp)
    8000175e:	6406                	ld	s0,64(sp)
    80001760:	74e2                	ld	s1,56(sp)
    80001762:	7942                	ld	s2,48(sp)
    80001764:	79a2                	ld	s3,40(sp)
    80001766:	7a02                	ld	s4,32(sp)
    80001768:	6ae2                	ld	s5,24(sp)
    8000176a:	6b42                	ld	s6,16(sp)
    8000176c:	6ba2                	ld	s7,8(sp)
    8000176e:	6c02                	ld	s8,0(sp)
    80001770:	6161                	addi	sp,sp,80
    80001772:	8082                	ret

0000000080001774 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    80001774:	c2dd                	beqz	a3,8000181a <copyinstr+0xa6>
{
    80001776:	715d                	addi	sp,sp,-80
    80001778:	e486                	sd	ra,72(sp)
    8000177a:	e0a2                	sd	s0,64(sp)
    8000177c:	fc26                	sd	s1,56(sp)
    8000177e:	f84a                	sd	s2,48(sp)
    80001780:	f44e                	sd	s3,40(sp)
    80001782:	f052                	sd	s4,32(sp)
    80001784:	ec56                	sd	s5,24(sp)
    80001786:	e85a                	sd	s6,16(sp)
    80001788:	e45e                	sd	s7,8(sp)
    8000178a:	0880                	addi	s0,sp,80
    8000178c:	8a2a                	mv	s4,a0
    8000178e:	8b2e                	mv	s6,a1
    80001790:	8bb2                	mv	s7,a2
    80001792:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    80001794:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001796:	6985                	lui	s3,0x1
    80001798:	a02d                	j	800017c2 <copyinstr+0x4e>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    8000179a:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    8000179e:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800017a0:	37fd                	addiw	a5,a5,-1
    800017a2:	0007851b          	sext.w	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800017a6:	60a6                	ld	ra,72(sp)
    800017a8:	6406                	ld	s0,64(sp)
    800017aa:	74e2                	ld	s1,56(sp)
    800017ac:	7942                	ld	s2,48(sp)
    800017ae:	79a2                	ld	s3,40(sp)
    800017b0:	7a02                	ld	s4,32(sp)
    800017b2:	6ae2                	ld	s5,24(sp)
    800017b4:	6b42                	ld	s6,16(sp)
    800017b6:	6ba2                	ld	s7,8(sp)
    800017b8:	6161                	addi	sp,sp,80
    800017ba:	8082                	ret
    srcva = va0 + PGSIZE;
    800017bc:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800017c0:	c8a9                	beqz	s1,80001812 <copyinstr+0x9e>
    va0 = PGROUNDDOWN(srcva);
    800017c2:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800017c6:	85ca                	mv	a1,s2
    800017c8:	8552                	mv	a0,s4
    800017ca:	00000097          	auipc	ra,0x0
    800017ce:	888080e7          	jalr	-1912(ra) # 80001052 <walkaddr>
    if(pa0 == 0)
    800017d2:	c131                	beqz	a0,80001816 <copyinstr+0xa2>
    n = PGSIZE - (srcva - va0);
    800017d4:	417906b3          	sub	a3,s2,s7
    800017d8:	96ce                	add	a3,a3,s3
    800017da:	00d4f363          	bgeu	s1,a3,800017e0 <copyinstr+0x6c>
    800017de:	86a6                	mv	a3,s1
    char *p = (char *) (pa0 + (srcva - va0));
    800017e0:	955e                	add	a0,a0,s7
    800017e2:	41250533          	sub	a0,a0,s2
    while(n > 0){
    800017e6:	daf9                	beqz	a3,800017bc <copyinstr+0x48>
    800017e8:	87da                	mv	a5,s6
      if(*p == '\0'){
    800017ea:	41650633          	sub	a2,a0,s6
    800017ee:	fff48593          	addi	a1,s1,-1
    800017f2:	95da                	add	a1,a1,s6
    while(n > 0){
    800017f4:	96da                	add	a3,a3,s6
      if(*p == '\0'){
    800017f6:	00f60733          	add	a4,a2,a5
    800017fa:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffd8000>
    800017fe:	df51                	beqz	a4,8000179a <copyinstr+0x26>
        *dst = *p;
    80001800:	00e78023          	sb	a4,0(a5)
      --max;
    80001804:	40f584b3          	sub	s1,a1,a5
      dst++;
    80001808:	0785                	addi	a5,a5,1
    while(n > 0){
    8000180a:	fed796e3          	bne	a5,a3,800017f6 <copyinstr+0x82>
      dst++;
    8000180e:	8b3e                	mv	s6,a5
    80001810:	b775                	j	800017bc <copyinstr+0x48>
    80001812:	4781                	li	a5,0
    80001814:	b771                	j	800017a0 <copyinstr+0x2c>
      return -1;
    80001816:	557d                	li	a0,-1
    80001818:	b779                	j	800017a6 <copyinstr+0x32>
  int got_null = 0;
    8000181a:	4781                	li	a5,0
  if(got_null){
    8000181c:	37fd                	addiw	a5,a5,-1
    8000181e:	0007851b          	sext.w	a0,a5
}
    80001822:	8082                	ret

0000000080001824 <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void proc_mapstacks(pagetable_t kpgtbl)
{
    80001824:	7139                	addi	sp,sp,-64
    80001826:	fc06                	sd	ra,56(sp)
    80001828:	f822                	sd	s0,48(sp)
    8000182a:	f426                	sd	s1,40(sp)
    8000182c:	f04a                	sd	s2,32(sp)
    8000182e:	ec4e                	sd	s3,24(sp)
    80001830:	e852                	sd	s4,16(sp)
    80001832:	e456                	sd	s5,8(sp)
    80001834:	e05a                	sd	s6,0(sp)
    80001836:	0080                	addi	s0,sp,64
    80001838:	89aa                	mv	s3,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    8000183a:	00010497          	auipc	s1,0x10
    8000183e:	e9648493          	addi	s1,s1,-362 # 800116d0 <proc>
  {
    char *pa = kalloc();
    if (pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int)(p - proc));
    80001842:	8b26                	mv	s6,s1
    80001844:	00006a97          	auipc	s5,0x6
    80001848:	7bca8a93          	addi	s5,s5,1980 # 80008000 <etext>
    8000184c:	04000937          	lui	s2,0x4000
    80001850:	197d                	addi	s2,s2,-1
    80001852:	0932                	slli	s2,s2,0xc
  for (p = proc; p < &proc[NPROC]; p++)
    80001854:	00017a17          	auipc	s4,0x17
    80001858:	e7ca0a13          	addi	s4,s4,-388 # 800186d0 <tickslock>
    char *pa = kalloc();
    8000185c:	fffff097          	auipc	ra,0xfffff
    80001860:	284080e7          	jalr	644(ra) # 80000ae0 <kalloc>
    80001864:	862a                	mv	a2,a0
    if (pa == 0)
    80001866:	c131                	beqz	a0,800018aa <proc_mapstacks+0x86>
    uint64 va = KSTACK((int)(p - proc));
    80001868:	416485b3          	sub	a1,s1,s6
    8000186c:	8599                	srai	a1,a1,0x6
    8000186e:	000ab783          	ld	a5,0(s5)
    80001872:	02f585b3          	mul	a1,a1,a5
    80001876:	2585                	addiw	a1,a1,1
    80001878:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    8000187c:	4719                	li	a4,6
    8000187e:	6685                	lui	a3,0x1
    80001880:	40b905b3          	sub	a1,s2,a1
    80001884:	854e                	mv	a0,s3
    80001886:	00000097          	auipc	ra,0x0
    8000188a:	8ae080e7          	jalr	-1874(ra) # 80001134 <kvmmap>
  for (p = proc; p < &proc[NPROC]; p++)
    8000188e:	1c048493          	addi	s1,s1,448
    80001892:	fd4495e3          	bne	s1,s4,8000185c <proc_mapstacks+0x38>
  }
}
    80001896:	70e2                	ld	ra,56(sp)
    80001898:	7442                	ld	s0,48(sp)
    8000189a:	74a2                	ld	s1,40(sp)
    8000189c:	7902                	ld	s2,32(sp)
    8000189e:	69e2                	ld	s3,24(sp)
    800018a0:	6a42                	ld	s4,16(sp)
    800018a2:	6aa2                	ld	s5,8(sp)
    800018a4:	6b02                	ld	s6,0(sp)
    800018a6:	6121                	addi	sp,sp,64
    800018a8:	8082                	ret
      panic("kalloc");
    800018aa:	00007517          	auipc	a0,0x7
    800018ae:	92e50513          	addi	a0,a0,-1746 # 800081d8 <digits+0x198>
    800018b2:	fffff097          	auipc	ra,0xfffff
    800018b6:	c88080e7          	jalr	-888(ra) # 8000053a <panic>

00000000800018ba <procinit>:

// initialize the proc table at boot time.
void procinit(void)
{
    800018ba:	7139                	addi	sp,sp,-64
    800018bc:	fc06                	sd	ra,56(sp)
    800018be:	f822                	sd	s0,48(sp)
    800018c0:	f426                	sd	s1,40(sp)
    800018c2:	f04a                	sd	s2,32(sp)
    800018c4:	ec4e                	sd	s3,24(sp)
    800018c6:	e852                	sd	s4,16(sp)
    800018c8:	e456                	sd	s5,8(sp)
    800018ca:	e05a                	sd	s6,0(sp)
    800018cc:	0080                	addi	s0,sp,64
  struct proc *p;

  initlock(&pid_lock, "nextpid");
    800018ce:	00007597          	auipc	a1,0x7
    800018d2:	91258593          	addi	a1,a1,-1774 # 800081e0 <digits+0x1a0>
    800018d6:	00010517          	auipc	a0,0x10
    800018da:	9ca50513          	addi	a0,a0,-1590 # 800112a0 <pid_lock>
    800018de:	fffff097          	auipc	ra,0xfffff
    800018e2:	262080e7          	jalr	610(ra) # 80000b40 <initlock>
  initlock(&wait_lock, "wait_lock");
    800018e6:	00007597          	auipc	a1,0x7
    800018ea:	90258593          	addi	a1,a1,-1790 # 800081e8 <digits+0x1a8>
    800018ee:	00010517          	auipc	a0,0x10
    800018f2:	9ca50513          	addi	a0,a0,-1590 # 800112b8 <wait_lock>
    800018f6:	fffff097          	auipc	ra,0xfffff
    800018fa:	24a080e7          	jalr	586(ra) # 80000b40 <initlock>
  for (p = proc; p < &proc[NPROC]; p++)
    800018fe:	00010497          	auipc	s1,0x10
    80001902:	dd248493          	addi	s1,s1,-558 # 800116d0 <proc>
  {
    initlock(&p->lock, "proc");
    80001906:	00007b17          	auipc	s6,0x7
    8000190a:	8f2b0b13          	addi	s6,s6,-1806 # 800081f8 <digits+0x1b8>
    p->kstack = KSTACK((int)(p - proc));
    8000190e:	8aa6                	mv	s5,s1
    80001910:	00006a17          	auipc	s4,0x6
    80001914:	6f0a0a13          	addi	s4,s4,1776 # 80008000 <etext>
    80001918:	04000937          	lui	s2,0x4000
    8000191c:	197d                	addi	s2,s2,-1
    8000191e:	0932                	slli	s2,s2,0xc
  for (p = proc; p < &proc[NPROC]; p++)
    80001920:	00017997          	auipc	s3,0x17
    80001924:	db098993          	addi	s3,s3,-592 # 800186d0 <tickslock>
    initlock(&p->lock, "proc");
    80001928:	85da                	mv	a1,s6
    8000192a:	8526                	mv	a0,s1
    8000192c:	fffff097          	auipc	ra,0xfffff
    80001930:	214080e7          	jalr	532(ra) # 80000b40 <initlock>
    p->kstack = KSTACK((int)(p - proc));
    80001934:	415487b3          	sub	a5,s1,s5
    80001938:	8799                	srai	a5,a5,0x6
    8000193a:	000a3703          	ld	a4,0(s4)
    8000193e:	02e787b3          	mul	a5,a5,a4
    80001942:	2785                	addiw	a5,a5,1
    80001944:	00d7979b          	slliw	a5,a5,0xd
    80001948:	40f907b3          	sub	a5,s2,a5
    8000194c:	e0bc                	sd	a5,64(s1)
  for (p = proc; p < &proc[NPROC]; p++)
    8000194e:	1c048493          	addi	s1,s1,448
    80001952:	fd349be3          	bne	s1,s3,80001928 <procinit+0x6e>
  }
}
    80001956:	70e2                	ld	ra,56(sp)
    80001958:	7442                	ld	s0,48(sp)
    8000195a:	74a2                	ld	s1,40(sp)
    8000195c:	7902                	ld	s2,32(sp)
    8000195e:	69e2                	ld	s3,24(sp)
    80001960:	6a42                	ld	s4,16(sp)
    80001962:	6aa2                	ld	s5,8(sp)
    80001964:	6b02                	ld	s6,0(sp)
    80001966:	6121                	addi	sp,sp,64
    80001968:	8082                	ret

000000008000196a <cpuid>:

// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int cpuid()
{
    8000196a:	1141                	addi	sp,sp,-16
    8000196c:	e422                	sd	s0,8(sp)
    8000196e:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001970:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001972:	2501                	sext.w	a0,a0
    80001974:	6422                	ld	s0,8(sp)
    80001976:	0141                	addi	sp,sp,16
    80001978:	8082                	ret

000000008000197a <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu *
mycpu(void)
{
    8000197a:	1141                	addi	sp,sp,-16
    8000197c:	e422                	sd	s0,8(sp)
    8000197e:	0800                	addi	s0,sp,16
    80001980:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001982:	2781                	sext.w	a5,a5
    80001984:	079e                	slli	a5,a5,0x7
  return c;
}
    80001986:	00010517          	auipc	a0,0x10
    8000198a:	94a50513          	addi	a0,a0,-1718 # 800112d0 <cpus>
    8000198e:	953e                	add	a0,a0,a5
    80001990:	6422                	ld	s0,8(sp)
    80001992:	0141                	addi	sp,sp,16
    80001994:	8082                	ret

0000000080001996 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc *
myproc(void)
{
    80001996:	1101                	addi	sp,sp,-32
    80001998:	ec06                	sd	ra,24(sp)
    8000199a:	e822                	sd	s0,16(sp)
    8000199c:	e426                	sd	s1,8(sp)
    8000199e:	1000                	addi	s0,sp,32
  push_off();
    800019a0:	fffff097          	auipc	ra,0xfffff
    800019a4:	1e4080e7          	jalr	484(ra) # 80000b84 <push_off>
    800019a8:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    800019aa:	2781                	sext.w	a5,a5
    800019ac:	079e                	slli	a5,a5,0x7
    800019ae:	00010717          	auipc	a4,0x10
    800019b2:	8f270713          	addi	a4,a4,-1806 # 800112a0 <pid_lock>
    800019b6:	97ba                	add	a5,a5,a4
    800019b8:	7b84                	ld	s1,48(a5)
  pop_off();
    800019ba:	fffff097          	auipc	ra,0xfffff
    800019be:	26a080e7          	jalr	618(ra) # 80000c24 <pop_off>
  return p;
}
    800019c2:	8526                	mv	a0,s1
    800019c4:	60e2                	ld	ra,24(sp)
    800019c6:	6442                	ld	s0,16(sp)
    800019c8:	64a2                	ld	s1,8(sp)
    800019ca:	6105                	addi	sp,sp,32
    800019cc:	8082                	ret

00000000800019ce <forkret>:
}

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void forkret(void)
{
    800019ce:	1141                	addi	sp,sp,-16
    800019d0:	e406                	sd	ra,8(sp)
    800019d2:	e022                	sd	s0,0(sp)
    800019d4:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    800019d6:	00000097          	auipc	ra,0x0
    800019da:	fc0080e7          	jalr	-64(ra) # 80001996 <myproc>
    800019de:	fffff097          	auipc	ra,0xfffff
    800019e2:	2a6080e7          	jalr	678(ra) # 80000c84 <release>

  if (first)
    800019e6:	00007797          	auipc	a5,0x7
    800019ea:	f2a7a783          	lw	a5,-214(a5) # 80008910 <first.1>
    800019ee:	eb89                	bnez	a5,80001a00 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    800019f0:	00001097          	auipc	ra,0x1
    800019f4:	0d2080e7          	jalr	210(ra) # 80002ac2 <usertrapret>
}
    800019f8:	60a2                	ld	ra,8(sp)
    800019fa:	6402                	ld	s0,0(sp)
    800019fc:	0141                	addi	sp,sp,16
    800019fe:	8082                	ret
    first = 0;
    80001a00:	00007797          	auipc	a5,0x7
    80001a04:	f007a823          	sw	zero,-240(a5) # 80008910 <first.1>
    fsinit(ROOTDEV);
    80001a08:	4505                	li	a0,1
    80001a0a:	00002097          	auipc	ra,0x2
    80001a0e:	084080e7          	jalr	132(ra) # 80003a8e <fsinit>
    80001a12:	bff9                	j	800019f0 <forkret+0x22>

0000000080001a14 <allocpid>:
{
    80001a14:	1101                	addi	sp,sp,-32
    80001a16:	ec06                	sd	ra,24(sp)
    80001a18:	e822                	sd	s0,16(sp)
    80001a1a:	e426                	sd	s1,8(sp)
    80001a1c:	e04a                	sd	s2,0(sp)
    80001a1e:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001a20:	00010917          	auipc	s2,0x10
    80001a24:	88090913          	addi	s2,s2,-1920 # 800112a0 <pid_lock>
    80001a28:	854a                	mv	a0,s2
    80001a2a:	fffff097          	auipc	ra,0xfffff
    80001a2e:	1a6080e7          	jalr	422(ra) # 80000bd0 <acquire>
  pid = nextpid;
    80001a32:	00007797          	auipc	a5,0x7
    80001a36:	ee278793          	addi	a5,a5,-286 # 80008914 <nextpid>
    80001a3a:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001a3c:	0014871b          	addiw	a4,s1,1
    80001a40:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001a42:	854a                	mv	a0,s2
    80001a44:	fffff097          	auipc	ra,0xfffff
    80001a48:	240080e7          	jalr	576(ra) # 80000c84 <release>
}
    80001a4c:	8526                	mv	a0,s1
    80001a4e:	60e2                	ld	ra,24(sp)
    80001a50:	6442                	ld	s0,16(sp)
    80001a52:	64a2                	ld	s1,8(sp)
    80001a54:	6902                	ld	s2,0(sp)
    80001a56:	6105                	addi	sp,sp,32
    80001a58:	8082                	ret

0000000080001a5a <proc_pagetable>:
{
    80001a5a:	1101                	addi	sp,sp,-32
    80001a5c:	ec06                	sd	ra,24(sp)
    80001a5e:	e822                	sd	s0,16(sp)
    80001a60:	e426                	sd	s1,8(sp)
    80001a62:	e04a                	sd	s2,0(sp)
    80001a64:	1000                	addi	s0,sp,32
    80001a66:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001a68:	00000097          	auipc	ra,0x0
    80001a6c:	8b6080e7          	jalr	-1866(ra) # 8000131e <uvmcreate>
    80001a70:	84aa                	mv	s1,a0
  if (pagetable == 0)
    80001a72:	c121                	beqz	a0,80001ab2 <proc_pagetable+0x58>
  if (mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001a74:	4729                	li	a4,10
    80001a76:	00005697          	auipc	a3,0x5
    80001a7a:	58a68693          	addi	a3,a3,1418 # 80007000 <_trampoline>
    80001a7e:	6605                	lui	a2,0x1
    80001a80:	040005b7          	lui	a1,0x4000
    80001a84:	15fd                	addi	a1,a1,-1
    80001a86:	05b2                	slli	a1,a1,0xc
    80001a88:	fffff097          	auipc	ra,0xfffff
    80001a8c:	60c080e7          	jalr	1548(ra) # 80001094 <mappages>
    80001a90:	02054863          	bltz	a0,80001ac0 <proc_pagetable+0x66>
  if (mappages(pagetable, TRAPFRAME, PGSIZE,
    80001a94:	4719                	li	a4,6
    80001a96:	05893683          	ld	a3,88(s2)
    80001a9a:	6605                	lui	a2,0x1
    80001a9c:	020005b7          	lui	a1,0x2000
    80001aa0:	15fd                	addi	a1,a1,-1
    80001aa2:	05b6                	slli	a1,a1,0xd
    80001aa4:	8526                	mv	a0,s1
    80001aa6:	fffff097          	auipc	ra,0xfffff
    80001aaa:	5ee080e7          	jalr	1518(ra) # 80001094 <mappages>
    80001aae:	02054163          	bltz	a0,80001ad0 <proc_pagetable+0x76>
}
    80001ab2:	8526                	mv	a0,s1
    80001ab4:	60e2                	ld	ra,24(sp)
    80001ab6:	6442                	ld	s0,16(sp)
    80001ab8:	64a2                	ld	s1,8(sp)
    80001aba:	6902                	ld	s2,0(sp)
    80001abc:	6105                	addi	sp,sp,32
    80001abe:	8082                	ret
    uvmfree(pagetable, 0);
    80001ac0:	4581                	li	a1,0
    80001ac2:	8526                	mv	a0,s1
    80001ac4:	00000097          	auipc	ra,0x0
    80001ac8:	a58080e7          	jalr	-1448(ra) # 8000151c <uvmfree>
    return 0;
    80001acc:	4481                	li	s1,0
    80001ace:	b7d5                	j	80001ab2 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001ad0:	4681                	li	a3,0
    80001ad2:	4605                	li	a2,1
    80001ad4:	040005b7          	lui	a1,0x4000
    80001ad8:	15fd                	addi	a1,a1,-1
    80001ada:	05b2                	slli	a1,a1,0xc
    80001adc:	8526                	mv	a0,s1
    80001ade:	fffff097          	auipc	ra,0xfffff
    80001ae2:	77c080e7          	jalr	1916(ra) # 8000125a <uvmunmap>
    uvmfree(pagetable, 0);
    80001ae6:	4581                	li	a1,0
    80001ae8:	8526                	mv	a0,s1
    80001aea:	00000097          	auipc	ra,0x0
    80001aee:	a32080e7          	jalr	-1486(ra) # 8000151c <uvmfree>
    return 0;
    80001af2:	4481                	li	s1,0
    80001af4:	bf7d                	j	80001ab2 <proc_pagetable+0x58>

0000000080001af6 <proc_freepagetable>:
{
    80001af6:	1101                	addi	sp,sp,-32
    80001af8:	ec06                	sd	ra,24(sp)
    80001afa:	e822                	sd	s0,16(sp)
    80001afc:	e426                	sd	s1,8(sp)
    80001afe:	e04a                	sd	s2,0(sp)
    80001b00:	1000                	addi	s0,sp,32
    80001b02:	84aa                	mv	s1,a0
    80001b04:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b06:	4681                	li	a3,0
    80001b08:	4605                	li	a2,1
    80001b0a:	040005b7          	lui	a1,0x4000
    80001b0e:	15fd                	addi	a1,a1,-1
    80001b10:	05b2                	slli	a1,a1,0xc
    80001b12:	fffff097          	auipc	ra,0xfffff
    80001b16:	748080e7          	jalr	1864(ra) # 8000125a <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001b1a:	4681                	li	a3,0
    80001b1c:	4605                	li	a2,1
    80001b1e:	020005b7          	lui	a1,0x2000
    80001b22:	15fd                	addi	a1,a1,-1
    80001b24:	05b6                	slli	a1,a1,0xd
    80001b26:	8526                	mv	a0,s1
    80001b28:	fffff097          	auipc	ra,0xfffff
    80001b2c:	732080e7          	jalr	1842(ra) # 8000125a <uvmunmap>
  uvmfree(pagetable, sz);
    80001b30:	85ca                	mv	a1,s2
    80001b32:	8526                	mv	a0,s1
    80001b34:	00000097          	auipc	ra,0x0
    80001b38:	9e8080e7          	jalr	-1560(ra) # 8000151c <uvmfree>
}
    80001b3c:	60e2                	ld	ra,24(sp)
    80001b3e:	6442                	ld	s0,16(sp)
    80001b40:	64a2                	ld	s1,8(sp)
    80001b42:	6902                	ld	s2,0(sp)
    80001b44:	6105                	addi	sp,sp,32
    80001b46:	8082                	ret

0000000080001b48 <freeproc>:
{
    80001b48:	1101                	addi	sp,sp,-32
    80001b4a:	ec06                	sd	ra,24(sp)
    80001b4c:	e822                	sd	s0,16(sp)
    80001b4e:	e426                	sd	s1,8(sp)
    80001b50:	1000                	addi	s0,sp,32
    80001b52:	84aa                	mv	s1,a0
  if (p->trapframe)
    80001b54:	6d28                	ld	a0,88(a0)
    80001b56:	c509                	beqz	a0,80001b60 <freeproc+0x18>
    kfree((void *)p->trapframe);
    80001b58:	fffff097          	auipc	ra,0xfffff
    80001b5c:	e8a080e7          	jalr	-374(ra) # 800009e2 <kfree>
  p->trapframe = 0;
    80001b60:	0404bc23          	sd	zero,88(s1)
  if (p->pagetable)
    80001b64:	68a8                	ld	a0,80(s1)
    80001b66:	c511                	beqz	a0,80001b72 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001b68:	64ac                	ld	a1,72(s1)
    80001b6a:	00000097          	auipc	ra,0x0
    80001b6e:	f8c080e7          	jalr	-116(ra) # 80001af6 <proc_freepagetable>
  p->pagetable = 0;
    80001b72:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001b76:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001b7a:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001b7e:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001b82:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001b86:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001b8a:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001b8e:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001b92:	0004ac23          	sw	zero,24(s1)
}
    80001b96:	60e2                	ld	ra,24(sp)
    80001b98:	6442                	ld	s0,16(sp)
    80001b9a:	64a2                	ld	s1,8(sp)
    80001b9c:	6105                	addi	sp,sp,32
    80001b9e:	8082                	ret

0000000080001ba0 <allocproc>:
{
    80001ba0:	1101                	addi	sp,sp,-32
    80001ba2:	ec06                	sd	ra,24(sp)
    80001ba4:	e822                	sd	s0,16(sp)
    80001ba6:	e426                	sd	s1,8(sp)
    80001ba8:	e04a                	sd	s2,0(sp)
    80001baa:	1000                	addi	s0,sp,32
  for (p = proc; p < &proc[NPROC]; p++)
    80001bac:	00010497          	auipc	s1,0x10
    80001bb0:	b2448493          	addi	s1,s1,-1244 # 800116d0 <proc>
    80001bb4:	00017917          	auipc	s2,0x17
    80001bb8:	b1c90913          	addi	s2,s2,-1252 # 800186d0 <tickslock>
    acquire(&p->lock);
    80001bbc:	8526                	mv	a0,s1
    80001bbe:	fffff097          	auipc	ra,0xfffff
    80001bc2:	012080e7          	jalr	18(ra) # 80000bd0 <acquire>
    if (p->state == UNUSED)
    80001bc6:	4c9c                	lw	a5,24(s1)
    80001bc8:	cf81                	beqz	a5,80001be0 <allocproc+0x40>
      release(&p->lock);
    80001bca:	8526                	mv	a0,s1
    80001bcc:	fffff097          	auipc	ra,0xfffff
    80001bd0:	0b8080e7          	jalr	184(ra) # 80000c84 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80001bd4:	1c048493          	addi	s1,s1,448
    80001bd8:	ff2492e3          	bne	s1,s2,80001bbc <allocproc+0x1c>
  return 0;
    80001bdc:	4481                	li	s1,0
    80001bde:	a845                	j	80001c8e <allocproc+0xee>
  p->pid = allocpid();
    80001be0:	00000097          	auipc	ra,0x0
    80001be4:	e34080e7          	jalr	-460(ra) # 80001a14 <allocpid>
    80001be8:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001bea:	4785                	li	a5,1
    80001bec:	cc9c                	sw	a5,24(s1)
  if ((p->trapframe = (struct trapframe *)kalloc()) == 0)
    80001bee:	fffff097          	auipc	ra,0xfffff
    80001bf2:	ef2080e7          	jalr	-270(ra) # 80000ae0 <kalloc>
    80001bf6:	892a                	mv	s2,a0
    80001bf8:	eca8                	sd	a0,88(s1)
    80001bfa:	c14d                	beqz	a0,80001c9c <allocproc+0xfc>
  p->pagetable = proc_pagetable(p);
    80001bfc:	8526                	mv	a0,s1
    80001bfe:	00000097          	auipc	ra,0x0
    80001c02:	e5c080e7          	jalr	-420(ra) # 80001a5a <proc_pagetable>
    80001c06:	892a                	mv	s2,a0
    80001c08:	e8a8                	sd	a0,80(s1)
  if (p->pagetable == 0)
    80001c0a:	c54d                	beqz	a0,80001cb4 <allocproc+0x114>
  memset(&p->context, 0, sizeof(p->context));
    80001c0c:	07000613          	li	a2,112
    80001c10:	4581                	li	a1,0
    80001c12:	06048513          	addi	a0,s1,96
    80001c16:	fffff097          	auipc	ra,0xfffff
    80001c1a:	0b6080e7          	jalr	182(ra) # 80000ccc <memset>
  p->context.ra = (uint64)forkret;
    80001c1e:	00000797          	auipc	a5,0x0
    80001c22:	db078793          	addi	a5,a5,-592 # 800019ce <forkret>
    80001c26:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001c28:	60bc                	ld	a5,64(s1)
    80001c2a:	6705                	lui	a4,0x1
    80001c2c:	97ba                	add	a5,a5,a4
    80001c2e:	f4bc                	sd	a5,104(s1)
  p->rtime = 0;
    80001c30:	1604a423          	sw	zero,360(s1)
  p->etime = 0;
    80001c34:	1604a823          	sw	zero,368(s1)
  p->ctime = ticks;
    80001c38:	00007797          	auipc	a5,0x7
    80001c3c:	3f87a783          	lw	a5,1016(a5) # 80009030 <ticks>
    80001c40:	16f4a623          	sw	a5,364(s1)
  p->priority = 60;
    80001c44:	03c00793          	li	a5,60
    80001c48:	16f4ac23          	sw	a5,376(s1)
  p->run_time = 0;
    80001c4c:	1804a023          	sw	zero,384(s1)
  p->sleep_time = 0;
    80001c50:	1804a223          	sw	zero,388(s1)
  p->scheduled = 0;
    80001c54:	1604ae23          	sw	zero,380(s1)
  p->call_sleep = -1;
    80001c58:	57fd                	li	a5,-1
    80001c5a:	18f4a823          	sw	a5,400(s1)
  p->dynamic_priority = 0;
    80001c5e:	1804a423          	sw	zero,392(s1)
  p->cur_ticks = 0;
    80001c62:	1804aa23          	sw	zero,404(s1)
  p->num_runs = 0;
    80001c66:	1804ac23          	sw	zero,408(s1)
  p->ticks[0] = p->ticks[1] = p->ticks[2] = p->ticks[3] = p->ticks[4] = 0;
    80001c6a:	1a04a623          	sw	zero,428(s1)
    80001c6e:	1a04a423          	sw	zero,424(s1)
    80001c72:	1a04a223          	sw	zero,420(s1)
    80001c76:	1a04a023          	sw	zero,416(s1)
    80001c7a:	1804ae23          	sw	zero,412(s1)
  p->exec_last = 0;
    80001c7e:	1a04a823          	sw	zero,432(s1)
  p->queue = 0;
    80001c82:	1a04aa23          	sw	zero,436(s1)
  p->wait_time_in_queue=0;
    80001c86:	1a04ae23          	sw	zero,444(s1)
  p->flag = 0;
    80001c8a:	1a04ac23          	sw	zero,440(s1)
}
    80001c8e:	8526                	mv	a0,s1
    80001c90:	60e2                	ld	ra,24(sp)
    80001c92:	6442                	ld	s0,16(sp)
    80001c94:	64a2                	ld	s1,8(sp)
    80001c96:	6902                	ld	s2,0(sp)
    80001c98:	6105                	addi	sp,sp,32
    80001c9a:	8082                	ret
    freeproc(p);
    80001c9c:	8526                	mv	a0,s1
    80001c9e:	00000097          	auipc	ra,0x0
    80001ca2:	eaa080e7          	jalr	-342(ra) # 80001b48 <freeproc>
    release(&p->lock);
    80001ca6:	8526                	mv	a0,s1
    80001ca8:	fffff097          	auipc	ra,0xfffff
    80001cac:	fdc080e7          	jalr	-36(ra) # 80000c84 <release>
    return 0;
    80001cb0:	84ca                	mv	s1,s2
    80001cb2:	bff1                	j	80001c8e <allocproc+0xee>
    freeproc(p);
    80001cb4:	8526                	mv	a0,s1
    80001cb6:	00000097          	auipc	ra,0x0
    80001cba:	e92080e7          	jalr	-366(ra) # 80001b48 <freeproc>
    release(&p->lock);
    80001cbe:	8526                	mv	a0,s1
    80001cc0:	fffff097          	auipc	ra,0xfffff
    80001cc4:	fc4080e7          	jalr	-60(ra) # 80000c84 <release>
    return 0;
    80001cc8:	84ca                	mv	s1,s2
    80001cca:	b7d1                	j	80001c8e <allocproc+0xee>

0000000080001ccc <userinit>:
{
    80001ccc:	1101                	addi	sp,sp,-32
    80001cce:	ec06                	sd	ra,24(sp)
    80001cd0:	e822                	sd	s0,16(sp)
    80001cd2:	e426                	sd	s1,8(sp)
    80001cd4:	1000                	addi	s0,sp,32
  p = allocproc();
    80001cd6:	00000097          	auipc	ra,0x0
    80001cda:	eca080e7          	jalr	-310(ra) # 80001ba0 <allocproc>
    80001cde:	84aa                	mv	s1,a0
  initproc = p;
    80001ce0:	00007797          	auipc	a5,0x7
    80001ce4:	34a7b423          	sd	a0,840(a5) # 80009028 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001ce8:	03400613          	li	a2,52
    80001cec:	00007597          	auipc	a1,0x7
    80001cf0:	c3458593          	addi	a1,a1,-972 # 80008920 <initcode>
    80001cf4:	6928                	ld	a0,80(a0)
    80001cf6:	fffff097          	auipc	ra,0xfffff
    80001cfa:	656080e7          	jalr	1622(ra) # 8000134c <uvminit>
  p->sz = PGSIZE;
    80001cfe:	6785                	lui	a5,0x1
    80001d00:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;     // user program counter
    80001d02:	6cb8                	ld	a4,88(s1)
    80001d04:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE; // user stack pointer
    80001d08:	6cb8                	ld	a4,88(s1)
    80001d0a:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001d0c:	4641                	li	a2,16
    80001d0e:	00006597          	auipc	a1,0x6
    80001d12:	4f258593          	addi	a1,a1,1266 # 80008200 <digits+0x1c0>
    80001d16:	15848513          	addi	a0,s1,344
    80001d1a:	fffff097          	auipc	ra,0xfffff
    80001d1e:	0fc080e7          	jalr	252(ra) # 80000e16 <safestrcpy>
  p->cwd = namei("/");
    80001d22:	00006517          	auipc	a0,0x6
    80001d26:	4ee50513          	addi	a0,a0,1262 # 80008210 <digits+0x1d0>
    80001d2a:	00002097          	auipc	ra,0x2
    80001d2e:	79a080e7          	jalr	1946(ra) # 800044c4 <namei>
    80001d32:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001d36:	478d                	li	a5,3
    80001d38:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001d3a:	8526                	mv	a0,s1
    80001d3c:	fffff097          	auipc	ra,0xfffff
    80001d40:	f48080e7          	jalr	-184(ra) # 80000c84 <release>
}
    80001d44:	60e2                	ld	ra,24(sp)
    80001d46:	6442                	ld	s0,16(sp)
    80001d48:	64a2                	ld	s1,8(sp)
    80001d4a:	6105                	addi	sp,sp,32
    80001d4c:	8082                	ret

0000000080001d4e <growproc>:
{
    80001d4e:	1101                	addi	sp,sp,-32
    80001d50:	ec06                	sd	ra,24(sp)
    80001d52:	e822                	sd	s0,16(sp)
    80001d54:	e426                	sd	s1,8(sp)
    80001d56:	e04a                	sd	s2,0(sp)
    80001d58:	1000                	addi	s0,sp,32
    80001d5a:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001d5c:	00000097          	auipc	ra,0x0
    80001d60:	c3a080e7          	jalr	-966(ra) # 80001996 <myproc>
    80001d64:	892a                	mv	s2,a0
  sz = p->sz;
    80001d66:	652c                	ld	a1,72(a0)
    80001d68:	0005879b          	sext.w	a5,a1
  if (n > 0)
    80001d6c:	00904f63          	bgtz	s1,80001d8a <growproc+0x3c>
  else if (n < 0)
    80001d70:	0204cd63          	bltz	s1,80001daa <growproc+0x5c>
  p->sz = sz;
    80001d74:	1782                	slli	a5,a5,0x20
    80001d76:	9381                	srli	a5,a5,0x20
    80001d78:	04f93423          	sd	a5,72(s2)
  return 0;
    80001d7c:	4501                	li	a0,0
}
    80001d7e:	60e2                	ld	ra,24(sp)
    80001d80:	6442                	ld	s0,16(sp)
    80001d82:	64a2                	ld	s1,8(sp)
    80001d84:	6902                	ld	s2,0(sp)
    80001d86:	6105                	addi	sp,sp,32
    80001d88:	8082                	ret
    if ((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0)
    80001d8a:	00f4863b          	addw	a2,s1,a5
    80001d8e:	1602                	slli	a2,a2,0x20
    80001d90:	9201                	srli	a2,a2,0x20
    80001d92:	1582                	slli	a1,a1,0x20
    80001d94:	9181                	srli	a1,a1,0x20
    80001d96:	6928                	ld	a0,80(a0)
    80001d98:	fffff097          	auipc	ra,0xfffff
    80001d9c:	66e080e7          	jalr	1646(ra) # 80001406 <uvmalloc>
    80001da0:	0005079b          	sext.w	a5,a0
    80001da4:	fbe1                	bnez	a5,80001d74 <growproc+0x26>
      return -1;
    80001da6:	557d                	li	a0,-1
    80001da8:	bfd9                	j	80001d7e <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001daa:	00f4863b          	addw	a2,s1,a5
    80001dae:	1602                	slli	a2,a2,0x20
    80001db0:	9201                	srli	a2,a2,0x20
    80001db2:	1582                	slli	a1,a1,0x20
    80001db4:	9181                	srli	a1,a1,0x20
    80001db6:	6928                	ld	a0,80(a0)
    80001db8:	fffff097          	auipc	ra,0xfffff
    80001dbc:	606080e7          	jalr	1542(ra) # 800013be <uvmdealloc>
    80001dc0:	0005079b          	sext.w	a5,a0
    80001dc4:	bf45                	j	80001d74 <growproc+0x26>

0000000080001dc6 <update_time>:
{
    80001dc6:	7139                	addi	sp,sp,-64
    80001dc8:	fc06                	sd	ra,56(sp)
    80001dca:	f822                	sd	s0,48(sp)
    80001dcc:	f426                	sd	s1,40(sp)
    80001dce:	f04a                	sd	s2,32(sp)
    80001dd0:	ec4e                	sd	s3,24(sp)
    80001dd2:	e852                	sd	s4,16(sp)
    80001dd4:	e456                	sd	s5,8(sp)
    80001dd6:	0080                	addi	s0,sp,64
  for (p = proc; p < &proc[NPROC]; p++)
    80001dd8:	00010497          	auipc	s1,0x10
    80001ddc:	8f848493          	addi	s1,s1,-1800 # 800116d0 <proc>
    if (p->state == RUNNING)
    80001de0:	4991                	li	s3,4
    if(p->state != ZOMBIE && p->state != RUNNING)
    80001de2:	4a05                	li	s4,1
      p->exec_last = ticks;
    80001de4:	00007a97          	auipc	s5,0x7
    80001de8:	24ca8a93          	addi	s5,s5,588 # 80009030 <ticks>
  for (p = proc; p < &proc[NPROC]; p++)
    80001dec:	00017917          	auipc	s2,0x17
    80001df0:	8e490913          	addi	s2,s2,-1820 # 800186d0 <tickslock>
    80001df4:	a0b1                	j	80001e40 <update_time+0x7a>
      p->rtime++;
    80001df6:	1684a783          	lw	a5,360(s1)
    80001dfa:	2785                	addiw	a5,a5,1
    80001dfc:	16f4a423          	sw	a5,360(s1)
      p->run_time++;
    80001e00:	1804a783          	lw	a5,384(s1)
    80001e04:	2785                	addiw	a5,a5,1
    80001e06:	18f4a023          	sw	a5,384(s1)
      p->cur_ticks++;
    80001e0a:	1944a783          	lw	a5,404(s1)
    80001e0e:	2785                	addiw	a5,a5,1
    80001e10:	18f4aa23          	sw	a5,404(s1)
      p->ticks[p->queue]++;
    80001e14:	1b44a783          	lw	a5,436(s1)
    80001e18:	078a                	slli	a5,a5,0x2
    80001e1a:	97a6                	add	a5,a5,s1
    80001e1c:	19c7a703          	lw	a4,412(a5) # 119c <_entry-0x7fffee64>
    80001e20:	2705                	addiw	a4,a4,1
    80001e22:	18e7ae23          	sw	a4,412(a5)
      p->exec_last = ticks;
    80001e26:	000aa783          	lw	a5,0(s5)
    80001e2a:	1af4a823          	sw	a5,432(s1)
    release(&p->lock);
    80001e2e:	8526                	mv	a0,s1
    80001e30:	fffff097          	auipc	ra,0xfffff
    80001e34:	e54080e7          	jalr	-428(ra) # 80000c84 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80001e38:	1c048493          	addi	s1,s1,448
    80001e3c:	03248363          	beq	s1,s2,80001e62 <update_time+0x9c>
    acquire(&p->lock);
    80001e40:	8526                	mv	a0,s1
    80001e42:	fffff097          	auipc	ra,0xfffff
    80001e46:	d8e080e7          	jalr	-626(ra) # 80000bd0 <acquire>
    if (p->state == RUNNING)
    80001e4a:	4c9c                	lw	a5,24(s1)
    80001e4c:	fb3785e3          	beq	a5,s3,80001df6 <update_time+0x30>
    if(p->state != ZOMBIE && p->state != RUNNING)
    80001e50:	37f1                	addiw	a5,a5,-4
    80001e52:	fcfa7ee3          	bgeu	s4,a5,80001e2e <update_time+0x68>
      p->wait_time_in_queue ++;
    80001e56:	1bc4a783          	lw	a5,444(s1)
    80001e5a:	2785                	addiw	a5,a5,1
    80001e5c:	1af4ae23          	sw	a5,444(s1)
    80001e60:	b7f9                	j	80001e2e <update_time+0x68>
}
    80001e62:	70e2                	ld	ra,56(sp)
    80001e64:	7442                	ld	s0,48(sp)
    80001e66:	74a2                	ld	s1,40(sp)
    80001e68:	7902                	ld	s2,32(sp)
    80001e6a:	69e2                	ld	s3,24(sp)
    80001e6c:	6a42                	ld	s4,16(sp)
    80001e6e:	6aa2                	ld	s5,8(sp)
    80001e70:	6121                	addi	sp,sp,64
    80001e72:	8082                	ret

0000000080001e74 <calc_dp>:
{
    80001e74:	1141                	addi	sp,sp,-16
    80001e76:	e422                	sd	s0,8(sp)
    80001e78:	0800                	addi	s0,sp,16
    80001e7a:	87aa                	mv	a5,a0
  if (p->sleep_time + p->run_time == 0)
    80001e7c:	18452603          	lw	a2,388(a0)
    80001e80:	18052683          	lw	a3,384(a0)
    80001e84:	9eb1                	addw	a3,a3,a2
    80001e86:	0006871b          	sext.w	a4,a3
    80001e8a:	cf05                	beqz	a4,80001ec2 <calc_dp+0x4e>
  int niceness = ((10 * p->sleep_time) / (p->sleep_time + p->run_time));
    80001e8c:	0026171b          	slliw	a4,a2,0x2
    80001e90:	9f31                	addw	a4,a4,a2
    80001e92:	0017171b          	slliw	a4,a4,0x1
    80001e96:	02d7473b          	divw	a4,a4,a3
  p->niceness = niceness;
    80001e9a:	18e52623          	sw	a4,396(a0)
  int x = p->priority - niceness + 5;
    80001e9e:	17852683          	lw	a3,376(a0)
    80001ea2:	40e6873b          	subw	a4,a3,a4
    80001ea6:	2715                	addiw	a4,a4,5
    80001ea8:	0007051b          	sext.w	a0,a4
  if (x > 100)
    80001eac:	06400693          	li	a3,100
    80001eb0:	02a6c163          	blt	a3,a0,80001ed2 <calc_dp+0x5e>
  if (x < 0)
    80001eb4:	02054663          	bltz	a0,80001ee0 <calc_dp+0x6c>
  p->dynamic_priority = x;
    80001eb8:	18e7a423          	sw	a4,392(a5)
}
    80001ebc:	6422                	ld	s0,8(sp)
    80001ebe:	0141                	addi	sp,sp,16
    80001ec0:	8082                	ret
    p->niceness = 5;
    80001ec2:	4715                	li	a4,5
    80001ec4:	18e52623          	sw	a4,396(a0)
    p->dynamic_priority = p->priority;
    80001ec8:	17852503          	lw	a0,376(a0)
    80001ecc:	18a7a423          	sw	a0,392(a5)
    return p->dynamic_priority;
    80001ed0:	b7f5                	j	80001ebc <calc_dp+0x48>
    p->dynamic_priority = 100;
    80001ed2:	06400713          	li	a4,100
    80001ed6:	18e7a423          	sw	a4,392(a5)
    return 100;
    80001eda:	06400513          	li	a0,100
    80001ede:	bff9                	j	80001ebc <calc_dp+0x48>
    p->dynamic_priority = 0;
    80001ee0:	1807a423          	sw	zero,392(a5)
    return 0;
    80001ee4:	4501                	li	a0,0
    80001ee6:	bfd9                	j	80001ebc <calc_dp+0x48>

0000000080001ee8 <scheduler>:
{
    80001ee8:	711d                	addi	sp,sp,-96
    80001eea:	ec86                	sd	ra,88(sp)
    80001eec:	e8a2                	sd	s0,80(sp)
    80001eee:	e4a6                	sd	s1,72(sp)
    80001ef0:	e0ca                	sd	s2,64(sp)
    80001ef2:	fc4e                	sd	s3,56(sp)
    80001ef4:	f852                	sd	s4,48(sp)
    80001ef6:	f456                	sd	s5,40(sp)
    80001ef8:	f05a                	sd	s6,32(sp)
    80001efa:	ec5e                	sd	s7,24(sp)
    80001efc:	e862                	sd	s8,16(sp)
    80001efe:	e466                	sd	s9,8(sp)
    80001f00:	1080                	addi	s0,sp,96
    80001f02:	8792                	mv	a5,tp
  int id = r_tp();
    80001f04:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001f06:	00779b93          	slli	s7,a5,0x7
    80001f0a:	0000f717          	auipc	a4,0xf
    80001f0e:	39670713          	addi	a4,a4,918 # 800112a0 <pid_lock>
    80001f12:	975e                	add	a4,a4,s7
    80001f14:	02073823          	sd	zero,48(a4)
          swtch(&c->context, &p->context);
    80001f18:	0000f717          	auipc	a4,0xf
    80001f1c:	3c070713          	addi	a4,a4,960 # 800112d8 <cpus+0x8>
    80001f20:	9bba                	add	s7,s7,a4
      if (p->state == RUNNABLE && p->flag == 1)
    80001f22:	490d                	li	s2,3
    for (p = proc; p < &proc[NPROC]; p++)
    80001f24:	00016997          	auipc	s3,0x16
    80001f28:	7ac98993          	addi	s3,s3,1964 # 800186d0 <tickslock>
      if (p->state == RUNNABLE && ticks - p->exec_last > 500)
    80001f2c:	00007b17          	auipc	s6,0x7
    80001f30:	104b0b13          	addi	s6,s6,260 # 80009030 <ticks>
          c->proc = p;
    80001f34:	079e                	slli	a5,a5,0x7
    80001f36:	0000fa97          	auipc	s5,0xf
    80001f3a:	36aa8a93          	addi	s5,s5,874 # 800112a0 <pid_lock>
    80001f3e:	9abe                	add	s5,s5,a5
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f40:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001f44:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001f48:	10079073          	csrw	sstatus,a5
    for (p = proc; p < &proc[NPROC]; p++)
    80001f4c:	0000f497          	auipc	s1,0xf
    80001f50:	78448493          	addi	s1,s1,1924 # 800116d0 <proc>
      if (p->state == RUNNABLE && p->flag == 1)
    80001f54:	4a05                	li	s4,1
    80001f56:	a811                	j	80001f6a <scheduler+0x82>
      release(&p->lock);
    80001f58:	8526                	mv	a0,s1
    80001f5a:	fffff097          	auipc	ra,0xfffff
    80001f5e:	d2a080e7          	jalr	-726(ra) # 80000c84 <release>
    for (p = proc; p < &proc[NPROC]; p++)
    80001f62:	1c048493          	addi	s1,s1,448
    80001f66:	05348163          	beq	s1,s3,80001fa8 <scheduler+0xc0>
      acquire(&p->lock);
    80001f6a:	8526                	mv	a0,s1
    80001f6c:	fffff097          	auipc	ra,0xfffff
    80001f70:	c64080e7          	jalr	-924(ra) # 80000bd0 <acquire>
      if (p->state == RUNNABLE && p->flag == 1)
    80001f74:	4c9c                	lw	a5,24(s1)
    80001f76:	ff2791e3          	bne	a5,s2,80001f58 <scheduler+0x70>
    80001f7a:	1b84a783          	lw	a5,440(s1)
    80001f7e:	fd479de3          	bne	a5,s4,80001f58 <scheduler+0x70>
        if (p->queue < 4)
    80001f82:	1b44a783          	lw	a5,436(s1)
    80001f86:	00f94b63          	blt	s2,a5,80001f9c <scheduler+0xb4>
          p->queue++;
    80001f8a:	2785                	addiw	a5,a5,1
    80001f8c:	1af4aa23          	sw	a5,436(s1)
          p->wait_time_in_queue=0;
    80001f90:	1a04ae23          	sw	zero,444(s1)
          p->cur_ticks = 0;
    80001f94:	1804aa23          	sw	zero,404(s1)
          p->flag = 0;
    80001f98:	1a04ac23          	sw	zero,440(s1)
        release(&p->lock);
    80001f9c:	8526                	mv	a0,s1
    80001f9e:	fffff097          	auipc	ra,0xfffff
    80001fa2:	ce6080e7          	jalr	-794(ra) # 80000c84 <release>
        continue;
    80001fa6:	bf75                	j	80001f62 <scheduler+0x7a>
    for (p = proc; p < &proc[NPROC]; p++)
    80001fa8:	0000f497          	auipc	s1,0xf
    80001fac:	72848493          	addi	s1,s1,1832 # 800116d0 <proc>
      if (p->state == RUNNABLE && ticks - p->exec_last > 500)
    80001fb0:	1f400a13          	li	s4,500
    80001fb4:	a811                	j	80001fc8 <scheduler+0xe0>
      release(&p->lock);
    80001fb6:	8526                	mv	a0,s1
    80001fb8:	fffff097          	auipc	ra,0xfffff
    80001fbc:	ccc080e7          	jalr	-820(ra) # 80000c84 <release>
    for (p = proc; p < &proc[NPROC]; p++)
    80001fc0:	1c048493          	addi	s1,s1,448
    80001fc4:	05348263          	beq	s1,s3,80002008 <scheduler+0x120>
      acquire(&p->lock);
    80001fc8:	8526                	mv	a0,s1
    80001fca:	fffff097          	auipc	ra,0xfffff
    80001fce:	c06080e7          	jalr	-1018(ra) # 80000bd0 <acquire>
      if (p->state == RUNNABLE && ticks - p->exec_last > 500)
    80001fd2:	4c9c                	lw	a5,24(s1)
    80001fd4:	ff2791e3          	bne	a5,s2,80001fb6 <scheduler+0xce>
    80001fd8:	000b2783          	lw	a5,0(s6)
    80001fdc:	1b04a703          	lw	a4,432(s1)
    80001fe0:	9f99                	subw	a5,a5,a4
    80001fe2:	fcfa7ae3          	bgeu	s4,a5,80001fb6 <scheduler+0xce>
        if (p->queue > 0)
    80001fe6:	1b44a783          	lw	a5,436(s1)
    80001fea:	00f05963          	blez	a5,80001ffc <scheduler+0x114>
          p->queue--;
    80001fee:	37fd                	addiw	a5,a5,-1
    80001ff0:	1af4aa23          	sw	a5,436(s1)
          p->cur_ticks = 0;
    80001ff4:	1804aa23          	sw	zero,404(s1)
          p->wait_time_in_queue=0;
    80001ff8:	1a04ae23          	sw	zero,444(s1)
        release(&p->lock);
    80001ffc:	8526                	mv	a0,s1
    80001ffe:	fffff097          	auipc	ra,0xfffff
    80002002:	c86080e7          	jalr	-890(ra) # 80000c84 <release>
        continue;
    80002006:	bf6d                	j	80001fc0 <scheduler+0xd8>
    for (int que_num = 0; que_num < 5; que_num++)
    80002008:	4c01                	li	s8,0
          p->state = RUNNING;
    8000200a:	4c91                	li	s9,4
    8000200c:	a095                	j	80002070 <scheduler+0x188>
        release(&p->lock);
    8000200e:	8526                	mv	a0,s1
    80002010:	fffff097          	auipc	ra,0xfffff
    80002014:	c74080e7          	jalr	-908(ra) # 80000c84 <release>
      for (p = proc; p < &proc[NPROC]; p++)
    80002018:	1c048493          	addi	s1,s1,448
    8000201c:	05348663          	beq	s1,s3,80002068 <scheduler+0x180>
        acquire(&p->lock);
    80002020:	8526                	mv	a0,s1
    80002022:	fffff097          	auipc	ra,0xfffff
    80002026:	bae080e7          	jalr	-1106(ra) # 80000bd0 <acquire>
        if (p->state == RUNNABLE && p->queue == que_num)
    8000202a:	4c9c                	lw	a5,24(s1)
    8000202c:	ff2791e3          	bne	a5,s2,8000200e <scheduler+0x126>
    80002030:	1b44a783          	lw	a5,436(s1)
    80002034:	fd879de3          	bne	a5,s8,8000200e <scheduler+0x126>
          p->num_runs++;
    80002038:	1984a783          	lw	a5,408(s1)
    8000203c:	2785                	addiw	a5,a5,1
    8000203e:	18f4ac23          	sw	a5,408(s1)
          c->proc = p;
    80002042:	029ab823          	sd	s1,48(s5)
          p->state = RUNNING;
    80002046:	0194ac23          	sw	s9,24(s1)
          swtch(&c->context, &p->context);
    8000204a:	06048593          	addi	a1,s1,96
    8000204e:	855e                	mv	a0,s7
    80002050:	00001097          	auipc	ra,0x1
    80002054:	9c8080e7          	jalr	-1592(ra) # 80002a18 <swtch>
          c->proc = 0;
    80002058:	020ab823          	sd	zero,48(s5)
          release(&p->lock);
    8000205c:	8526                	mv	a0,s1
    8000205e:	fffff097          	auipc	ra,0xfffff
    80002062:	c26080e7          	jalr	-986(ra) # 80000c84 <release>
          continue;
    80002066:	bf4d                	j	80002018 <scheduler+0x130>
    for (int que_num = 0; que_num < 5; que_num++)
    80002068:	2c05                	addiw	s8,s8,1
    8000206a:	4795                	li	a5,5
    8000206c:	ecfc0ae3          	beq	s8,a5,80001f40 <scheduler+0x58>
      for (p = proc; p < &proc[NPROC]; p++)
    80002070:	0000f497          	auipc	s1,0xf
    80002074:	66048493          	addi	s1,s1,1632 # 800116d0 <proc>
    80002078:	b765                	j	80002020 <scheduler+0x138>

000000008000207a <sched>:
{
    8000207a:	7179                	addi	sp,sp,-48
    8000207c:	f406                	sd	ra,40(sp)
    8000207e:	f022                	sd	s0,32(sp)
    80002080:	ec26                	sd	s1,24(sp)
    80002082:	e84a                	sd	s2,16(sp)
    80002084:	e44e                	sd	s3,8(sp)
    80002086:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80002088:	00000097          	auipc	ra,0x0
    8000208c:	90e080e7          	jalr	-1778(ra) # 80001996 <myproc>
    80002090:	84aa                	mv	s1,a0
  if (!holding(&p->lock))
    80002092:	fffff097          	auipc	ra,0xfffff
    80002096:	ac4080e7          	jalr	-1340(ra) # 80000b56 <holding>
    8000209a:	c93d                	beqz	a0,80002110 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    8000209c:	8792                	mv	a5,tp
  if (mycpu()->noff != 1)
    8000209e:	2781                	sext.w	a5,a5
    800020a0:	079e                	slli	a5,a5,0x7
    800020a2:	0000f717          	auipc	a4,0xf
    800020a6:	1fe70713          	addi	a4,a4,510 # 800112a0 <pid_lock>
    800020aa:	97ba                	add	a5,a5,a4
    800020ac:	0a87a703          	lw	a4,168(a5)
    800020b0:	4785                	li	a5,1
    800020b2:	06f71763          	bne	a4,a5,80002120 <sched+0xa6>
  if (p->state == RUNNING)
    800020b6:	4c98                	lw	a4,24(s1)
    800020b8:	4791                	li	a5,4
    800020ba:	06f70b63          	beq	a4,a5,80002130 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800020be:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800020c2:	8b89                	andi	a5,a5,2
  if (intr_get())
    800020c4:	efb5                	bnez	a5,80002140 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    800020c6:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    800020c8:	0000f917          	auipc	s2,0xf
    800020cc:	1d890913          	addi	s2,s2,472 # 800112a0 <pid_lock>
    800020d0:	2781                	sext.w	a5,a5
    800020d2:	079e                	slli	a5,a5,0x7
    800020d4:	97ca                	add	a5,a5,s2
    800020d6:	0ac7a983          	lw	s3,172(a5)
    800020da:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    800020dc:	2781                	sext.w	a5,a5
    800020de:	079e                	slli	a5,a5,0x7
    800020e0:	0000f597          	auipc	a1,0xf
    800020e4:	1f858593          	addi	a1,a1,504 # 800112d8 <cpus+0x8>
    800020e8:	95be                	add	a1,a1,a5
    800020ea:	06048513          	addi	a0,s1,96
    800020ee:	00001097          	auipc	ra,0x1
    800020f2:	92a080e7          	jalr	-1750(ra) # 80002a18 <swtch>
    800020f6:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    800020f8:	2781                	sext.w	a5,a5
    800020fa:	079e                	slli	a5,a5,0x7
    800020fc:	993e                	add	s2,s2,a5
    800020fe:	0b392623          	sw	s3,172(s2)
}
    80002102:	70a2                	ld	ra,40(sp)
    80002104:	7402                	ld	s0,32(sp)
    80002106:	64e2                	ld	s1,24(sp)
    80002108:	6942                	ld	s2,16(sp)
    8000210a:	69a2                	ld	s3,8(sp)
    8000210c:	6145                	addi	sp,sp,48
    8000210e:	8082                	ret
    panic("sched p->lock");
    80002110:	00006517          	auipc	a0,0x6
    80002114:	10850513          	addi	a0,a0,264 # 80008218 <digits+0x1d8>
    80002118:	ffffe097          	auipc	ra,0xffffe
    8000211c:	422080e7          	jalr	1058(ra) # 8000053a <panic>
    panic("sched locks");
    80002120:	00006517          	auipc	a0,0x6
    80002124:	10850513          	addi	a0,a0,264 # 80008228 <digits+0x1e8>
    80002128:	ffffe097          	auipc	ra,0xffffe
    8000212c:	412080e7          	jalr	1042(ra) # 8000053a <panic>
    panic("sched running");
    80002130:	00006517          	auipc	a0,0x6
    80002134:	10850513          	addi	a0,a0,264 # 80008238 <digits+0x1f8>
    80002138:	ffffe097          	auipc	ra,0xffffe
    8000213c:	402080e7          	jalr	1026(ra) # 8000053a <panic>
    panic("sched interruptible");
    80002140:	00006517          	auipc	a0,0x6
    80002144:	10850513          	addi	a0,a0,264 # 80008248 <digits+0x208>
    80002148:	ffffe097          	auipc	ra,0xffffe
    8000214c:	3f2080e7          	jalr	1010(ra) # 8000053a <panic>

0000000080002150 <yield>:
{
    80002150:	1101                	addi	sp,sp,-32
    80002152:	ec06                	sd	ra,24(sp)
    80002154:	e822                	sd	s0,16(sp)
    80002156:	e426                	sd	s1,8(sp)
    80002158:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    8000215a:	00000097          	auipc	ra,0x0
    8000215e:	83c080e7          	jalr	-1988(ra) # 80001996 <myproc>
    80002162:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002164:	fffff097          	auipc	ra,0xfffff
    80002168:	a6c080e7          	jalr	-1428(ra) # 80000bd0 <acquire>
  p->state = RUNNABLE;
    8000216c:	478d                	li	a5,3
    8000216e:	cc9c                	sw	a5,24(s1)
  sched();
    80002170:	00000097          	auipc	ra,0x0
    80002174:	f0a080e7          	jalr	-246(ra) # 8000207a <sched>
  release(&p->lock);
    80002178:	8526                	mv	a0,s1
    8000217a:	fffff097          	auipc	ra,0xfffff
    8000217e:	b0a080e7          	jalr	-1270(ra) # 80000c84 <release>
}
    80002182:	60e2                	ld	ra,24(sp)
    80002184:	6442                	ld	s0,16(sp)
    80002186:	64a2                	ld	s1,8(sp)
    80002188:	6105                	addi	sp,sp,32
    8000218a:	8082                	ret

000000008000218c <fork>:
{
    8000218c:	7139                	addi	sp,sp,-64
    8000218e:	fc06                	sd	ra,56(sp)
    80002190:	f822                	sd	s0,48(sp)
    80002192:	f426                	sd	s1,40(sp)
    80002194:	f04a                	sd	s2,32(sp)
    80002196:	ec4e                	sd	s3,24(sp)
    80002198:	e852                	sd	s4,16(sp)
    8000219a:	e456                	sd	s5,8(sp)
    8000219c:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    8000219e:	fffff097          	auipc	ra,0xfffff
    800021a2:	7f8080e7          	jalr	2040(ra) # 80001996 <myproc>
    800021a6:	8aaa                	mv	s5,a0
  if ((np = allocproc()) == 0)
    800021a8:	00000097          	auipc	ra,0x0
    800021ac:	9f8080e7          	jalr	-1544(ra) # 80001ba0 <allocproc>
    800021b0:	12050463          	beqz	a0,800022d8 <fork+0x14c>
    800021b4:	89aa                	mv	s3,a0
  if (uvmcopy(p->pagetable, np->pagetable, p->sz) < 0)
    800021b6:	048ab603          	ld	a2,72(s5)
    800021ba:	692c                	ld	a1,80(a0)
    800021bc:	050ab503          	ld	a0,80(s5)
    800021c0:	fffff097          	auipc	ra,0xfffff
    800021c4:	396080e7          	jalr	918(ra) # 80001556 <uvmcopy>
    800021c8:	04054c63          	bltz	a0,80002220 <fork+0x94>
  np->sz = p->sz;
    800021cc:	048ab783          	ld	a5,72(s5)
    800021d0:	04f9b423          	sd	a5,72(s3)
  *(np->trapframe) = *(p->trapframe);
    800021d4:	058ab683          	ld	a3,88(s5)
    800021d8:	87b6                	mv	a5,a3
    800021da:	0589b703          	ld	a4,88(s3)
    800021de:	12068693          	addi	a3,a3,288
    800021e2:	0007b803          	ld	a6,0(a5)
    800021e6:	6788                	ld	a0,8(a5)
    800021e8:	6b8c                	ld	a1,16(a5)
    800021ea:	6f90                	ld	a2,24(a5)
    800021ec:	01073023          	sd	a6,0(a4)
    800021f0:	e708                	sd	a0,8(a4)
    800021f2:	eb0c                	sd	a1,16(a4)
    800021f4:	ef10                	sd	a2,24(a4)
    800021f6:	02078793          	addi	a5,a5,32
    800021fa:	02070713          	addi	a4,a4,32
    800021fe:	fed792e3          	bne	a5,a3,800021e2 <fork+0x56>
   np->mask = p->mask;
    80002202:	174aa783          	lw	a5,372(s5)
    80002206:	16f9aa23          	sw	a5,372(s3)
  np->trapframe->a0 = 0;
    8000220a:	0589b783          	ld	a5,88(s3)
    8000220e:	0607b823          	sd	zero,112(a5)
  for (i = 0; i < NOFILE; i++)
    80002212:	0d0a8493          	addi	s1,s5,208
    80002216:	0d098913          	addi	s2,s3,208
    8000221a:	150a8a13          	addi	s4,s5,336
    8000221e:	a00d                	j	80002240 <fork+0xb4>
    freeproc(np);
    80002220:	854e                	mv	a0,s3
    80002222:	00000097          	auipc	ra,0x0
    80002226:	926080e7          	jalr	-1754(ra) # 80001b48 <freeproc>
    release(&np->lock);
    8000222a:	854e                	mv	a0,s3
    8000222c:	fffff097          	auipc	ra,0xfffff
    80002230:	a58080e7          	jalr	-1448(ra) # 80000c84 <release>
    return -1;
    80002234:	597d                	li	s2,-1
    80002236:	a079                	j	800022c4 <fork+0x138>
  for (i = 0; i < NOFILE; i++)
    80002238:	04a1                	addi	s1,s1,8
    8000223a:	0921                	addi	s2,s2,8
    8000223c:	01448b63          	beq	s1,s4,80002252 <fork+0xc6>
    if (p->ofile[i])
    80002240:	6088                	ld	a0,0(s1)
    80002242:	d97d                	beqz	a0,80002238 <fork+0xac>
      np->ofile[i] = filedup(p->ofile[i]);
    80002244:	00003097          	auipc	ra,0x3
    80002248:	916080e7          	jalr	-1770(ra) # 80004b5a <filedup>
    8000224c:	00a93023          	sd	a0,0(s2)
    80002250:	b7e5                	j	80002238 <fork+0xac>
  np->cwd = idup(p->cwd);
    80002252:	150ab503          	ld	a0,336(s5)
    80002256:	00002097          	auipc	ra,0x2
    8000225a:	a74080e7          	jalr	-1420(ra) # 80003cca <idup>
    8000225e:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80002262:	4641                	li	a2,16
    80002264:	158a8593          	addi	a1,s5,344
    80002268:	15898513          	addi	a0,s3,344
    8000226c:	fffff097          	auipc	ra,0xfffff
    80002270:	baa080e7          	jalr	-1110(ra) # 80000e16 <safestrcpy>
  pid = np->pid;
    80002274:	0309a903          	lw	s2,48(s3)
  release(&np->lock);
    80002278:	854e                	mv	a0,s3
    8000227a:	fffff097          	auipc	ra,0xfffff
    8000227e:	a0a080e7          	jalr	-1526(ra) # 80000c84 <release>
  acquire(&wait_lock);
    80002282:	0000f497          	auipc	s1,0xf
    80002286:	03648493          	addi	s1,s1,54 # 800112b8 <wait_lock>
    8000228a:	8526                	mv	a0,s1
    8000228c:	fffff097          	auipc	ra,0xfffff
    80002290:	944080e7          	jalr	-1724(ra) # 80000bd0 <acquire>
  np->parent = p;
    80002294:	0359bc23          	sd	s5,56(s3)
  release(&wait_lock);
    80002298:	8526                	mv	a0,s1
    8000229a:	fffff097          	auipc	ra,0xfffff
    8000229e:	9ea080e7          	jalr	-1558(ra) # 80000c84 <release>
  acquire(&np->lock);
    800022a2:	854e                	mv	a0,s3
    800022a4:	fffff097          	auipc	ra,0xfffff
    800022a8:	92c080e7          	jalr	-1748(ra) # 80000bd0 <acquire>
  np->state = RUNNABLE;
    800022ac:	478d                	li	a5,3
    800022ae:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    800022b2:	854e                	mv	a0,s3
    800022b4:	fffff097          	auipc	ra,0xfffff
    800022b8:	9d0080e7          	jalr	-1584(ra) # 80000c84 <release>
  yield();
    800022bc:	00000097          	auipc	ra,0x0
    800022c0:	e94080e7          	jalr	-364(ra) # 80002150 <yield>
}
    800022c4:	854a                	mv	a0,s2
    800022c6:	70e2                	ld	ra,56(sp)
    800022c8:	7442                	ld	s0,48(sp)
    800022ca:	74a2                	ld	s1,40(sp)
    800022cc:	7902                	ld	s2,32(sp)
    800022ce:	69e2                	ld	s3,24(sp)
    800022d0:	6a42                	ld	s4,16(sp)
    800022d2:	6aa2                	ld	s5,8(sp)
    800022d4:	6121                	addi	sp,sp,64
    800022d6:	8082                	ret
    return -1;
    800022d8:	597d                	li	s2,-1
    800022da:	b7ed                	j	800022c4 <fork+0x138>

00000000800022dc <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void sleep(void *chan, struct spinlock *lk)
{
    800022dc:	7179                	addi	sp,sp,-48
    800022de:	f406                	sd	ra,40(sp)
    800022e0:	f022                	sd	s0,32(sp)
    800022e2:	ec26                	sd	s1,24(sp)
    800022e4:	e84a                	sd	s2,16(sp)
    800022e6:	e44e                	sd	s3,8(sp)
    800022e8:	1800                	addi	s0,sp,48
    800022ea:	89aa                	mv	s3,a0
    800022ec:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800022ee:	fffff097          	auipc	ra,0xfffff
    800022f2:	6a8080e7          	jalr	1704(ra) # 80001996 <myproc>
    800022f6:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock); //DOC: sleeplock1
    800022f8:	fffff097          	auipc	ra,0xfffff
    800022fc:	8d8080e7          	jalr	-1832(ra) # 80000bd0 <acquire>
  release(lk);
    80002300:	854a                	mv	a0,s2
    80002302:	fffff097          	auipc	ra,0xfffff
    80002306:	982080e7          	jalr	-1662(ra) # 80000c84 <release>

  // Go to sleep.
  p->chan = chan;
    8000230a:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    8000230e:	4789                	li	a5,2
    80002310:	cc9c                	sw	a5,24(s1)
  p->call_sleep = ticks;
    80002312:	00007797          	auipc	a5,0x7
    80002316:	d1e7a783          	lw	a5,-738(a5) # 80009030 <ticks>
    8000231a:	18f4a823          	sw	a5,400(s1)
  p->cur_ticks = 0;
    8000231e:	1804aa23          	sw	zero,404(s1)

  sched();
    80002322:	00000097          	auipc	ra,0x0
    80002326:	d58080e7          	jalr	-680(ra) # 8000207a <sched>

  // Tidy up.
  p->chan = 0;
    8000232a:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    8000232e:	8526                	mv	a0,s1
    80002330:	fffff097          	auipc	ra,0xfffff
    80002334:	954080e7          	jalr	-1708(ra) # 80000c84 <release>
  acquire(lk);
    80002338:	854a                	mv	a0,s2
    8000233a:	fffff097          	auipc	ra,0xfffff
    8000233e:	896080e7          	jalr	-1898(ra) # 80000bd0 <acquire>
}
    80002342:	70a2                	ld	ra,40(sp)
    80002344:	7402                	ld	s0,32(sp)
    80002346:	64e2                	ld	s1,24(sp)
    80002348:	6942                	ld	s2,16(sp)
    8000234a:	69a2                	ld	s3,8(sp)
    8000234c:	6145                	addi	sp,sp,48
    8000234e:	8082                	ret

0000000080002350 <wait>:
{
    80002350:	715d                	addi	sp,sp,-80
    80002352:	e486                	sd	ra,72(sp)
    80002354:	e0a2                	sd	s0,64(sp)
    80002356:	fc26                	sd	s1,56(sp)
    80002358:	f84a                	sd	s2,48(sp)
    8000235a:	f44e                	sd	s3,40(sp)
    8000235c:	f052                	sd	s4,32(sp)
    8000235e:	ec56                	sd	s5,24(sp)
    80002360:	e85a                	sd	s6,16(sp)
    80002362:	e45e                	sd	s7,8(sp)
    80002364:	e062                	sd	s8,0(sp)
    80002366:	0880                	addi	s0,sp,80
    80002368:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    8000236a:	fffff097          	auipc	ra,0xfffff
    8000236e:	62c080e7          	jalr	1580(ra) # 80001996 <myproc>
    80002372:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002374:	0000f517          	auipc	a0,0xf
    80002378:	f4450513          	addi	a0,a0,-188 # 800112b8 <wait_lock>
    8000237c:	fffff097          	auipc	ra,0xfffff
    80002380:	854080e7          	jalr	-1964(ra) # 80000bd0 <acquire>
    havekids = 0;
    80002384:	4b81                	li	s7,0
        if (np->state == ZOMBIE)
    80002386:	4a15                	li	s4,5
        havekids = 1;
    80002388:	4a85                	li	s5,1
    for (np = proc; np < &proc[NPROC]; np++)
    8000238a:	00016997          	auipc	s3,0x16
    8000238e:	34698993          	addi	s3,s3,838 # 800186d0 <tickslock>
    sleep(p, &wait_lock); //DOC: wait-sleep
    80002392:	0000fc17          	auipc	s8,0xf
    80002396:	f26c0c13          	addi	s8,s8,-218 # 800112b8 <wait_lock>
    havekids = 0;
    8000239a:	875e                	mv	a4,s7
    for (np = proc; np < &proc[NPROC]; np++)
    8000239c:	0000f497          	auipc	s1,0xf
    800023a0:	33448493          	addi	s1,s1,820 # 800116d0 <proc>
    800023a4:	a0bd                	j	80002412 <wait+0xc2>
          pid = np->pid;
    800023a6:	0304a983          	lw	s3,48(s1)
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    800023aa:	000b0e63          	beqz	s6,800023c6 <wait+0x76>
    800023ae:	4691                	li	a3,4
    800023b0:	02c48613          	addi	a2,s1,44
    800023b4:	85da                	mv	a1,s6
    800023b6:	05093503          	ld	a0,80(s2)
    800023ba:	fffff097          	auipc	ra,0xfffff
    800023be:	2a0080e7          	jalr	672(ra) # 8000165a <copyout>
    800023c2:	02054563          	bltz	a0,800023ec <wait+0x9c>
          freeproc(np);
    800023c6:	8526                	mv	a0,s1
    800023c8:	fffff097          	auipc	ra,0xfffff
    800023cc:	780080e7          	jalr	1920(ra) # 80001b48 <freeproc>
          release(&np->lock);
    800023d0:	8526                	mv	a0,s1
    800023d2:	fffff097          	auipc	ra,0xfffff
    800023d6:	8b2080e7          	jalr	-1870(ra) # 80000c84 <release>
          release(&wait_lock);
    800023da:	0000f517          	auipc	a0,0xf
    800023de:	ede50513          	addi	a0,a0,-290 # 800112b8 <wait_lock>
    800023e2:	fffff097          	auipc	ra,0xfffff
    800023e6:	8a2080e7          	jalr	-1886(ra) # 80000c84 <release>
          return pid;
    800023ea:	a09d                	j	80002450 <wait+0x100>
            release(&np->lock);
    800023ec:	8526                	mv	a0,s1
    800023ee:	fffff097          	auipc	ra,0xfffff
    800023f2:	896080e7          	jalr	-1898(ra) # 80000c84 <release>
            release(&wait_lock);
    800023f6:	0000f517          	auipc	a0,0xf
    800023fa:	ec250513          	addi	a0,a0,-318 # 800112b8 <wait_lock>
    800023fe:	fffff097          	auipc	ra,0xfffff
    80002402:	886080e7          	jalr	-1914(ra) # 80000c84 <release>
            return -1;
    80002406:	59fd                	li	s3,-1
    80002408:	a0a1                	j	80002450 <wait+0x100>
    for (np = proc; np < &proc[NPROC]; np++)
    8000240a:	1c048493          	addi	s1,s1,448
    8000240e:	03348463          	beq	s1,s3,80002436 <wait+0xe6>
      if (np->parent == p)
    80002412:	7c9c                	ld	a5,56(s1)
    80002414:	ff279be3          	bne	a5,s2,8000240a <wait+0xba>
        acquire(&np->lock);
    80002418:	8526                	mv	a0,s1
    8000241a:	ffffe097          	auipc	ra,0xffffe
    8000241e:	7b6080e7          	jalr	1974(ra) # 80000bd0 <acquire>
        if (np->state == ZOMBIE)
    80002422:	4c9c                	lw	a5,24(s1)
    80002424:	f94781e3          	beq	a5,s4,800023a6 <wait+0x56>
        release(&np->lock);
    80002428:	8526                	mv	a0,s1
    8000242a:	fffff097          	auipc	ra,0xfffff
    8000242e:	85a080e7          	jalr	-1958(ra) # 80000c84 <release>
        havekids = 1;
    80002432:	8756                	mv	a4,s5
    80002434:	bfd9                	j	8000240a <wait+0xba>
    if (!havekids || p->killed)
    80002436:	c701                	beqz	a4,8000243e <wait+0xee>
    80002438:	02892783          	lw	a5,40(s2)
    8000243c:	c79d                	beqz	a5,8000246a <wait+0x11a>
      release(&wait_lock);
    8000243e:	0000f517          	auipc	a0,0xf
    80002442:	e7a50513          	addi	a0,a0,-390 # 800112b8 <wait_lock>
    80002446:	fffff097          	auipc	ra,0xfffff
    8000244a:	83e080e7          	jalr	-1986(ra) # 80000c84 <release>
      return -1;
    8000244e:	59fd                	li	s3,-1
}
    80002450:	854e                	mv	a0,s3
    80002452:	60a6                	ld	ra,72(sp)
    80002454:	6406                	ld	s0,64(sp)
    80002456:	74e2                	ld	s1,56(sp)
    80002458:	7942                	ld	s2,48(sp)
    8000245a:	79a2                	ld	s3,40(sp)
    8000245c:	7a02                	ld	s4,32(sp)
    8000245e:	6ae2                	ld	s5,24(sp)
    80002460:	6b42                	ld	s6,16(sp)
    80002462:	6ba2                	ld	s7,8(sp)
    80002464:	6c02                	ld	s8,0(sp)
    80002466:	6161                	addi	sp,sp,80
    80002468:	8082                	ret
    sleep(p, &wait_lock); //DOC: wait-sleep
    8000246a:	85e2                	mv	a1,s8
    8000246c:	854a                	mv	a0,s2
    8000246e:	00000097          	auipc	ra,0x0
    80002472:	e6e080e7          	jalr	-402(ra) # 800022dc <sleep>
    havekids = 0;
    80002476:	b715                	j	8000239a <wait+0x4a>

0000000080002478 <waitx>:
{
    80002478:	711d                	addi	sp,sp,-96
    8000247a:	ec86                	sd	ra,88(sp)
    8000247c:	e8a2                	sd	s0,80(sp)
    8000247e:	e4a6                	sd	s1,72(sp)
    80002480:	e0ca                	sd	s2,64(sp)
    80002482:	fc4e                	sd	s3,56(sp)
    80002484:	f852                	sd	s4,48(sp)
    80002486:	f456                	sd	s5,40(sp)
    80002488:	f05a                	sd	s6,32(sp)
    8000248a:	ec5e                	sd	s7,24(sp)
    8000248c:	e862                	sd	s8,16(sp)
    8000248e:	e466                	sd	s9,8(sp)
    80002490:	e06a                	sd	s10,0(sp)
    80002492:	1080                	addi	s0,sp,96
    80002494:	8b2a                	mv	s6,a0
    80002496:	8c2e                	mv	s8,a1
    80002498:	8bb2                	mv	s7,a2
  struct proc *p = myproc();
    8000249a:	fffff097          	auipc	ra,0xfffff
    8000249e:	4fc080e7          	jalr	1276(ra) # 80001996 <myproc>
    800024a2:	892a                	mv	s2,a0
  acquire(&wait_lock);
    800024a4:	0000f517          	auipc	a0,0xf
    800024a8:	e1450513          	addi	a0,a0,-492 # 800112b8 <wait_lock>
    800024ac:	ffffe097          	auipc	ra,0xffffe
    800024b0:	724080e7          	jalr	1828(ra) # 80000bd0 <acquire>
    havekids = 0;
    800024b4:	4c81                	li	s9,0
        if (np->state == ZOMBIE)
    800024b6:	4a15                	li	s4,5
        havekids = 1;
    800024b8:	4a85                	li	s5,1
    for (np = proc; np < &proc[NPROC]; np++)
    800024ba:	00016997          	auipc	s3,0x16
    800024be:	21698993          	addi	s3,s3,534 # 800186d0 <tickslock>
    sleep(p, &wait_lock); //DOC: wait-sleep
    800024c2:	0000fd17          	auipc	s10,0xf
    800024c6:	df6d0d13          	addi	s10,s10,-522 # 800112b8 <wait_lock>
    havekids = 0;
    800024ca:	8766                	mv	a4,s9
    for (np = proc; np < &proc[NPROC]; np++)
    800024cc:	0000f497          	auipc	s1,0xf
    800024d0:	20448493          	addi	s1,s1,516 # 800116d0 <proc>
    800024d4:	a059                	j	8000255a <waitx+0xe2>
          pid = np->pid;
    800024d6:	0304a983          	lw	s3,48(s1)
          *rtime = np->rtime;
    800024da:	1684a783          	lw	a5,360(s1)
    800024de:	00fc2023          	sw	a5,0(s8)
          *wtime = np->etime - np->ctime - np->rtime;
    800024e2:	16c4a703          	lw	a4,364(s1)
    800024e6:	9f3d                	addw	a4,a4,a5
    800024e8:	1704a783          	lw	a5,368(s1)
    800024ec:	9f99                	subw	a5,a5,a4
    800024ee:	00fba023          	sw	a5,0(s7) # fffffffffffff000 <end+0xffffffff7ffd8000>
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    800024f2:	000b0e63          	beqz	s6,8000250e <waitx+0x96>
    800024f6:	4691                	li	a3,4
    800024f8:	02c48613          	addi	a2,s1,44
    800024fc:	85da                	mv	a1,s6
    800024fe:	05093503          	ld	a0,80(s2)
    80002502:	fffff097          	auipc	ra,0xfffff
    80002506:	158080e7          	jalr	344(ra) # 8000165a <copyout>
    8000250a:	02054563          	bltz	a0,80002534 <waitx+0xbc>
          freeproc(np);
    8000250e:	8526                	mv	a0,s1
    80002510:	fffff097          	auipc	ra,0xfffff
    80002514:	638080e7          	jalr	1592(ra) # 80001b48 <freeproc>
          release(&np->lock);
    80002518:	8526                	mv	a0,s1
    8000251a:	ffffe097          	auipc	ra,0xffffe
    8000251e:	76a080e7          	jalr	1898(ra) # 80000c84 <release>
          release(&wait_lock);
    80002522:	0000f517          	auipc	a0,0xf
    80002526:	d9650513          	addi	a0,a0,-618 # 800112b8 <wait_lock>
    8000252a:	ffffe097          	auipc	ra,0xffffe
    8000252e:	75a080e7          	jalr	1882(ra) # 80000c84 <release>
          return pid;
    80002532:	a09d                	j	80002598 <waitx+0x120>
            release(&np->lock);
    80002534:	8526                	mv	a0,s1
    80002536:	ffffe097          	auipc	ra,0xffffe
    8000253a:	74e080e7          	jalr	1870(ra) # 80000c84 <release>
            release(&wait_lock);
    8000253e:	0000f517          	auipc	a0,0xf
    80002542:	d7a50513          	addi	a0,a0,-646 # 800112b8 <wait_lock>
    80002546:	ffffe097          	auipc	ra,0xffffe
    8000254a:	73e080e7          	jalr	1854(ra) # 80000c84 <release>
            return -1;
    8000254e:	59fd                	li	s3,-1
    80002550:	a0a1                	j	80002598 <waitx+0x120>
    for (np = proc; np < &proc[NPROC]; np++)
    80002552:	1c048493          	addi	s1,s1,448
    80002556:	03348463          	beq	s1,s3,8000257e <waitx+0x106>
      if (np->parent == p)
    8000255a:	7c9c                	ld	a5,56(s1)
    8000255c:	ff279be3          	bne	a5,s2,80002552 <waitx+0xda>
        acquire(&np->lock);
    80002560:	8526                	mv	a0,s1
    80002562:	ffffe097          	auipc	ra,0xffffe
    80002566:	66e080e7          	jalr	1646(ra) # 80000bd0 <acquire>
        if (np->state == ZOMBIE)
    8000256a:	4c9c                	lw	a5,24(s1)
    8000256c:	f74785e3          	beq	a5,s4,800024d6 <waitx+0x5e>
        release(&np->lock);
    80002570:	8526                	mv	a0,s1
    80002572:	ffffe097          	auipc	ra,0xffffe
    80002576:	712080e7          	jalr	1810(ra) # 80000c84 <release>
        havekids = 1;
    8000257a:	8756                	mv	a4,s5
    8000257c:	bfd9                	j	80002552 <waitx+0xda>
    if (!havekids || p->killed)
    8000257e:	c701                	beqz	a4,80002586 <waitx+0x10e>
    80002580:	02892783          	lw	a5,40(s2)
    80002584:	cb8d                	beqz	a5,800025b6 <waitx+0x13e>
      release(&wait_lock);
    80002586:	0000f517          	auipc	a0,0xf
    8000258a:	d3250513          	addi	a0,a0,-718 # 800112b8 <wait_lock>
    8000258e:	ffffe097          	auipc	ra,0xffffe
    80002592:	6f6080e7          	jalr	1782(ra) # 80000c84 <release>
      return -1;
    80002596:	59fd                	li	s3,-1
}
    80002598:	854e                	mv	a0,s3
    8000259a:	60e6                	ld	ra,88(sp)
    8000259c:	6446                	ld	s0,80(sp)
    8000259e:	64a6                	ld	s1,72(sp)
    800025a0:	6906                	ld	s2,64(sp)
    800025a2:	79e2                	ld	s3,56(sp)
    800025a4:	7a42                	ld	s4,48(sp)
    800025a6:	7aa2                	ld	s5,40(sp)
    800025a8:	7b02                	ld	s6,32(sp)
    800025aa:	6be2                	ld	s7,24(sp)
    800025ac:	6c42                	ld	s8,16(sp)
    800025ae:	6ca2                	ld	s9,8(sp)
    800025b0:	6d02                	ld	s10,0(sp)
    800025b2:	6125                	addi	sp,sp,96
    800025b4:	8082                	ret
    sleep(p, &wait_lock); //DOC: wait-sleep
    800025b6:	85ea                	mv	a1,s10
    800025b8:	854a                	mv	a0,s2
    800025ba:	00000097          	auipc	ra,0x0
    800025be:	d22080e7          	jalr	-734(ra) # 800022dc <sleep>
    havekids = 0;
    800025c2:	b721                	j	800024ca <waitx+0x52>

00000000800025c4 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void wakeup(void *chan)
{
    800025c4:	7139                	addi	sp,sp,-64
    800025c6:	fc06                	sd	ra,56(sp)
    800025c8:	f822                	sd	s0,48(sp)
    800025ca:	f426                	sd	s1,40(sp)
    800025cc:	f04a                	sd	s2,32(sp)
    800025ce:	ec4e                	sd	s3,24(sp)
    800025d0:	e852                	sd	s4,16(sp)
    800025d2:	e456                	sd	s5,8(sp)
    800025d4:	e05a                	sd	s6,0(sp)
    800025d6:	0080                	addi	s0,sp,64
    800025d8:	8a2a                	mv	s4,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    800025da:	0000f497          	auipc	s1,0xf
    800025de:	0f648493          	addi	s1,s1,246 # 800116d0 <proc>
  {
    if (p != myproc())
    {
      acquire(&p->lock);
      if (p->state == SLEEPING && p->chan == chan)
    800025e2:	4989                	li	s3,2
      {
        p->state = RUNNABLE;
    800025e4:	4b0d                	li	s6,3
        p->sleep_time += ticks - p->call_sleep;
    800025e6:	00007a97          	auipc	s5,0x7
    800025ea:	a4aa8a93          	addi	s5,s5,-1462 # 80009030 <ticks>
  for (p = proc; p < &proc[NPROC]; p++)
    800025ee:	00016917          	auipc	s2,0x16
    800025f2:	0e290913          	addi	s2,s2,226 # 800186d0 <tickslock>
    800025f6:	a811                	j	8000260a <wakeup+0x46>
      }
      release(&p->lock);
    800025f8:	8526                	mv	a0,s1
    800025fa:	ffffe097          	auipc	ra,0xffffe
    800025fe:	68a080e7          	jalr	1674(ra) # 80000c84 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80002602:	1c048493          	addi	s1,s1,448
    80002606:	05248063          	beq	s1,s2,80002646 <wakeup+0x82>
    if (p != myproc())
    8000260a:	fffff097          	auipc	ra,0xfffff
    8000260e:	38c080e7          	jalr	908(ra) # 80001996 <myproc>
    80002612:	fea488e3          	beq	s1,a0,80002602 <wakeup+0x3e>
      acquire(&p->lock);
    80002616:	8526                	mv	a0,s1
    80002618:	ffffe097          	auipc	ra,0xffffe
    8000261c:	5b8080e7          	jalr	1464(ra) # 80000bd0 <acquire>
      if (p->state == SLEEPING && p->chan == chan)
    80002620:	4c9c                	lw	a5,24(s1)
    80002622:	fd379be3          	bne	a5,s3,800025f8 <wakeup+0x34>
    80002626:	709c                	ld	a5,32(s1)
    80002628:	fd4798e3          	bne	a5,s4,800025f8 <wakeup+0x34>
        p->state = RUNNABLE;
    8000262c:	0164ac23          	sw	s6,24(s1)
        p->sleep_time += ticks - p->call_sleep;
    80002630:	1844a703          	lw	a4,388(s1)
    80002634:	000aa783          	lw	a5,0(s5)
    80002638:	9fb9                	addw	a5,a5,a4
    8000263a:	1904a703          	lw	a4,400(s1)
    8000263e:	9f99                	subw	a5,a5,a4
    80002640:	18f4a223          	sw	a5,388(s1)
    80002644:	bf55                	j	800025f8 <wakeup+0x34>
    }
  }
}
    80002646:	70e2                	ld	ra,56(sp)
    80002648:	7442                	ld	s0,48(sp)
    8000264a:	74a2                	ld	s1,40(sp)
    8000264c:	7902                	ld	s2,32(sp)
    8000264e:	69e2                	ld	s3,24(sp)
    80002650:	6a42                	ld	s4,16(sp)
    80002652:	6aa2                	ld	s5,8(sp)
    80002654:	6b02                	ld	s6,0(sp)
    80002656:	6121                	addi	sp,sp,64
    80002658:	8082                	ret

000000008000265a <reparent>:
{
    8000265a:	7179                	addi	sp,sp,-48
    8000265c:	f406                	sd	ra,40(sp)
    8000265e:	f022                	sd	s0,32(sp)
    80002660:	ec26                	sd	s1,24(sp)
    80002662:	e84a                	sd	s2,16(sp)
    80002664:	e44e                	sd	s3,8(sp)
    80002666:	e052                	sd	s4,0(sp)
    80002668:	1800                	addi	s0,sp,48
    8000266a:	892a                	mv	s2,a0
  for (pp = proc; pp < &proc[NPROC]; pp++)
    8000266c:	0000f497          	auipc	s1,0xf
    80002670:	06448493          	addi	s1,s1,100 # 800116d0 <proc>
      pp->parent = initproc;
    80002674:	00007a17          	auipc	s4,0x7
    80002678:	9b4a0a13          	addi	s4,s4,-1612 # 80009028 <initproc>
  for (pp = proc; pp < &proc[NPROC]; pp++)
    8000267c:	00016997          	auipc	s3,0x16
    80002680:	05498993          	addi	s3,s3,84 # 800186d0 <tickslock>
    80002684:	a029                	j	8000268e <reparent+0x34>
    80002686:	1c048493          	addi	s1,s1,448
    8000268a:	01348d63          	beq	s1,s3,800026a4 <reparent+0x4a>
    if (pp->parent == p)
    8000268e:	7c9c                	ld	a5,56(s1)
    80002690:	ff279be3          	bne	a5,s2,80002686 <reparent+0x2c>
      pp->parent = initproc;
    80002694:	000a3503          	ld	a0,0(s4)
    80002698:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    8000269a:	00000097          	auipc	ra,0x0
    8000269e:	f2a080e7          	jalr	-214(ra) # 800025c4 <wakeup>
    800026a2:	b7d5                	j	80002686 <reparent+0x2c>
}
    800026a4:	70a2                	ld	ra,40(sp)
    800026a6:	7402                	ld	s0,32(sp)
    800026a8:	64e2                	ld	s1,24(sp)
    800026aa:	6942                	ld	s2,16(sp)
    800026ac:	69a2                	ld	s3,8(sp)
    800026ae:	6a02                	ld	s4,0(sp)
    800026b0:	6145                	addi	sp,sp,48
    800026b2:	8082                	ret

00000000800026b4 <exit>:
{
    800026b4:	7179                	addi	sp,sp,-48
    800026b6:	f406                	sd	ra,40(sp)
    800026b8:	f022                	sd	s0,32(sp)
    800026ba:	ec26                	sd	s1,24(sp)
    800026bc:	e84a                	sd	s2,16(sp)
    800026be:	e44e                	sd	s3,8(sp)
    800026c0:	e052                	sd	s4,0(sp)
    800026c2:	1800                	addi	s0,sp,48
    800026c4:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800026c6:	fffff097          	auipc	ra,0xfffff
    800026ca:	2d0080e7          	jalr	720(ra) # 80001996 <myproc>
    800026ce:	89aa                	mv	s3,a0
  if (p == initproc)
    800026d0:	00007797          	auipc	a5,0x7
    800026d4:	9587b783          	ld	a5,-1704(a5) # 80009028 <initproc>
    800026d8:	0d050493          	addi	s1,a0,208
    800026dc:	15050913          	addi	s2,a0,336
    800026e0:	02a79363          	bne	a5,a0,80002706 <exit+0x52>
    panic("init exiting");
    800026e4:	00006517          	auipc	a0,0x6
    800026e8:	b7c50513          	addi	a0,a0,-1156 # 80008260 <digits+0x220>
    800026ec:	ffffe097          	auipc	ra,0xffffe
    800026f0:	e4e080e7          	jalr	-434(ra) # 8000053a <panic>
      fileclose(f);
    800026f4:	00002097          	auipc	ra,0x2
    800026f8:	4b8080e7          	jalr	1208(ra) # 80004bac <fileclose>
      p->ofile[fd] = 0;
    800026fc:	0004b023          	sd	zero,0(s1)
  for (int fd = 0; fd < NOFILE; fd++)
    80002700:	04a1                	addi	s1,s1,8
    80002702:	01248563          	beq	s1,s2,8000270c <exit+0x58>
    if (p->ofile[fd])
    80002706:	6088                	ld	a0,0(s1)
    80002708:	f575                	bnez	a0,800026f4 <exit+0x40>
    8000270a:	bfdd                	j	80002700 <exit+0x4c>
  begin_op();
    8000270c:	00002097          	auipc	ra,0x2
    80002710:	fd8080e7          	jalr	-40(ra) # 800046e4 <begin_op>
  iput(p->cwd);
    80002714:	1509b503          	ld	a0,336(s3)
    80002718:	00001097          	auipc	ra,0x1
    8000271c:	7aa080e7          	jalr	1962(ra) # 80003ec2 <iput>
  end_op();
    80002720:	00002097          	auipc	ra,0x2
    80002724:	042080e7          	jalr	66(ra) # 80004762 <end_op>
  p->cwd = 0;
    80002728:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    8000272c:	0000f497          	auipc	s1,0xf
    80002730:	b8c48493          	addi	s1,s1,-1140 # 800112b8 <wait_lock>
    80002734:	8526                	mv	a0,s1
    80002736:	ffffe097          	auipc	ra,0xffffe
    8000273a:	49a080e7          	jalr	1178(ra) # 80000bd0 <acquire>
  reparent(p);
    8000273e:	854e                	mv	a0,s3
    80002740:	00000097          	auipc	ra,0x0
    80002744:	f1a080e7          	jalr	-230(ra) # 8000265a <reparent>
  wakeup(p->parent);
    80002748:	0389b503          	ld	a0,56(s3)
    8000274c:	00000097          	auipc	ra,0x0
    80002750:	e78080e7          	jalr	-392(ra) # 800025c4 <wakeup>
  acquire(&p->lock);
    80002754:	854e                	mv	a0,s3
    80002756:	ffffe097          	auipc	ra,0xffffe
    8000275a:	47a080e7          	jalr	1146(ra) # 80000bd0 <acquire>
  p->xstate = status;
    8000275e:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    80002762:	4795                	li	a5,5
    80002764:	00f9ac23          	sw	a5,24(s3)
  p->etime = ticks;
    80002768:	00007797          	auipc	a5,0x7
    8000276c:	8c87a783          	lw	a5,-1848(a5) # 80009030 <ticks>
    80002770:	16f9a823          	sw	a5,368(s3)
  release(&wait_lock);
    80002774:	8526                	mv	a0,s1
    80002776:	ffffe097          	auipc	ra,0xffffe
    8000277a:	50e080e7          	jalr	1294(ra) # 80000c84 <release>
  sched();
    8000277e:	00000097          	auipc	ra,0x0
    80002782:	8fc080e7          	jalr	-1796(ra) # 8000207a <sched>
  panic("zombie exit");
    80002786:	00006517          	auipc	a0,0x6
    8000278a:	aea50513          	addi	a0,a0,-1302 # 80008270 <digits+0x230>
    8000278e:	ffffe097          	auipc	ra,0xffffe
    80002792:	dac080e7          	jalr	-596(ra) # 8000053a <panic>

0000000080002796 <kill>:

// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int kill(int pid)
{
    80002796:	7179                	addi	sp,sp,-48
    80002798:	f406                	sd	ra,40(sp)
    8000279a:	f022                	sd	s0,32(sp)
    8000279c:	ec26                	sd	s1,24(sp)
    8000279e:	e84a                	sd	s2,16(sp)
    800027a0:	e44e                	sd	s3,8(sp)
    800027a2:	1800                	addi	s0,sp,48
    800027a4:	892a                	mv	s2,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    800027a6:	0000f497          	auipc	s1,0xf
    800027aa:	f2a48493          	addi	s1,s1,-214 # 800116d0 <proc>
    800027ae:	00016997          	auipc	s3,0x16
    800027b2:	f2298993          	addi	s3,s3,-222 # 800186d0 <tickslock>
  {
    acquire(&p->lock);
    800027b6:	8526                	mv	a0,s1
    800027b8:	ffffe097          	auipc	ra,0xffffe
    800027bc:	418080e7          	jalr	1048(ra) # 80000bd0 <acquire>
    if (p->pid == pid)
    800027c0:	589c                	lw	a5,48(s1)
    800027c2:	01278d63          	beq	a5,s2,800027dc <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800027c6:	8526                	mv	a0,s1
    800027c8:	ffffe097          	auipc	ra,0xffffe
    800027cc:	4bc080e7          	jalr	1212(ra) # 80000c84 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    800027d0:	1c048493          	addi	s1,s1,448
    800027d4:	ff3491e3          	bne	s1,s3,800027b6 <kill+0x20>
  }
  return -1;
    800027d8:	557d                	li	a0,-1
    800027da:	a829                	j	800027f4 <kill+0x5e>
      p->killed = 1;
    800027dc:	4785                	li	a5,1
    800027de:	d49c                	sw	a5,40(s1)
      if (p->state == SLEEPING)
    800027e0:	4c98                	lw	a4,24(s1)
    800027e2:	4789                	li	a5,2
    800027e4:	00f70f63          	beq	a4,a5,80002802 <kill+0x6c>
      release(&p->lock);
    800027e8:	8526                	mv	a0,s1
    800027ea:	ffffe097          	auipc	ra,0xffffe
    800027ee:	49a080e7          	jalr	1178(ra) # 80000c84 <release>
      return 0;
    800027f2:	4501                	li	a0,0
}
    800027f4:	70a2                	ld	ra,40(sp)
    800027f6:	7402                	ld	s0,32(sp)
    800027f8:	64e2                	ld	s1,24(sp)
    800027fa:	6942                	ld	s2,16(sp)
    800027fc:	69a2                	ld	s3,8(sp)
    800027fe:	6145                	addi	sp,sp,48
    80002800:	8082                	ret
        p->state = RUNNABLE;
    80002802:	478d                	li	a5,3
    80002804:	cc9c                	sw	a5,24(s1)
    80002806:	b7cd                	j	800027e8 <kill+0x52>

0000000080002808 <either_copyout>:

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002808:	7179                	addi	sp,sp,-48
    8000280a:	f406                	sd	ra,40(sp)
    8000280c:	f022                	sd	s0,32(sp)
    8000280e:	ec26                	sd	s1,24(sp)
    80002810:	e84a                	sd	s2,16(sp)
    80002812:	e44e                	sd	s3,8(sp)
    80002814:	e052                	sd	s4,0(sp)
    80002816:	1800                	addi	s0,sp,48
    80002818:	84aa                	mv	s1,a0
    8000281a:	892e                	mv	s2,a1
    8000281c:	89b2                	mv	s3,a2
    8000281e:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002820:	fffff097          	auipc	ra,0xfffff
    80002824:	176080e7          	jalr	374(ra) # 80001996 <myproc>
  if (user_dst)
    80002828:	c08d                	beqz	s1,8000284a <either_copyout+0x42>
  {
    return copyout(p->pagetable, dst, src, len);
    8000282a:	86d2                	mv	a3,s4
    8000282c:	864e                	mv	a2,s3
    8000282e:	85ca                	mv	a1,s2
    80002830:	6928                	ld	a0,80(a0)
    80002832:	fffff097          	auipc	ra,0xfffff
    80002836:	e28080e7          	jalr	-472(ra) # 8000165a <copyout>
  else
  {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    8000283a:	70a2                	ld	ra,40(sp)
    8000283c:	7402                	ld	s0,32(sp)
    8000283e:	64e2                	ld	s1,24(sp)
    80002840:	6942                	ld	s2,16(sp)
    80002842:	69a2                	ld	s3,8(sp)
    80002844:	6a02                	ld	s4,0(sp)
    80002846:	6145                	addi	sp,sp,48
    80002848:	8082                	ret
    memmove((char *)dst, src, len);
    8000284a:	000a061b          	sext.w	a2,s4
    8000284e:	85ce                	mv	a1,s3
    80002850:	854a                	mv	a0,s2
    80002852:	ffffe097          	auipc	ra,0xffffe
    80002856:	4d6080e7          	jalr	1238(ra) # 80000d28 <memmove>
    return 0;
    8000285a:	8526                	mv	a0,s1
    8000285c:	bff9                	j	8000283a <either_copyout+0x32>

000000008000285e <either_copyin>:

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    8000285e:	7179                	addi	sp,sp,-48
    80002860:	f406                	sd	ra,40(sp)
    80002862:	f022                	sd	s0,32(sp)
    80002864:	ec26                	sd	s1,24(sp)
    80002866:	e84a                	sd	s2,16(sp)
    80002868:	e44e                	sd	s3,8(sp)
    8000286a:	e052                	sd	s4,0(sp)
    8000286c:	1800                	addi	s0,sp,48
    8000286e:	892a                	mv	s2,a0
    80002870:	84ae                	mv	s1,a1
    80002872:	89b2                	mv	s3,a2
    80002874:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002876:	fffff097          	auipc	ra,0xfffff
    8000287a:	120080e7          	jalr	288(ra) # 80001996 <myproc>
  if (user_src)
    8000287e:	c08d                	beqz	s1,800028a0 <either_copyin+0x42>
  {
    return copyin(p->pagetable, dst, src, len);
    80002880:	86d2                	mv	a3,s4
    80002882:	864e                	mv	a2,s3
    80002884:	85ca                	mv	a1,s2
    80002886:	6928                	ld	a0,80(a0)
    80002888:	fffff097          	auipc	ra,0xfffff
    8000288c:	e5e080e7          	jalr	-418(ra) # 800016e6 <copyin>
  else
  {
    memmove(dst, (char *)src, len);
    return 0;
  }
}
    80002890:	70a2                	ld	ra,40(sp)
    80002892:	7402                	ld	s0,32(sp)
    80002894:	64e2                	ld	s1,24(sp)
    80002896:	6942                	ld	s2,16(sp)
    80002898:	69a2                	ld	s3,8(sp)
    8000289a:	6a02                	ld	s4,0(sp)
    8000289c:	6145                	addi	sp,sp,48
    8000289e:	8082                	ret
    memmove(dst, (char *)src, len);
    800028a0:	000a061b          	sext.w	a2,s4
    800028a4:	85ce                	mv	a1,s3
    800028a6:	854a                	mv	a0,s2
    800028a8:	ffffe097          	auipc	ra,0xffffe
    800028ac:	480080e7          	jalr	1152(ra) # 80000d28 <memmove>
    return 0;
    800028b0:	8526                	mv	a0,s1
    800028b2:	bff9                	j	80002890 <either_copyin+0x32>

00000000800028b4 <procdump>:

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void procdump(void)
{
    800028b4:	7159                	addi	sp,sp,-112
    800028b6:	f486                	sd	ra,104(sp)
    800028b8:	f0a2                	sd	s0,96(sp)
    800028ba:	eca6                	sd	s1,88(sp)
    800028bc:	e8ca                	sd	s2,80(sp)
    800028be:	e4ce                	sd	s3,72(sp)
    800028c0:	e0d2                	sd	s4,64(sp)
    800028c2:	fc56                	sd	s5,56(sp)
    800028c4:	f85a                	sd	s6,48(sp)
    800028c6:	f45e                	sd	s7,40(sp)
    800028c8:	1880                	addi	s0,sp,112
      [RUNNING] "run   ",
      [ZOMBIE] "zombie"};
  struct proc *p;
  char *state;

  printf("\n");
    800028ca:	00005517          	auipc	a0,0x5
    800028ce:	7fe50513          	addi	a0,a0,2046 # 800080c8 <digits+0x88>
    800028d2:	ffffe097          	auipc	ra,0xffffe
    800028d6:	cb2080e7          	jalr	-846(ra) # 80000584 <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    800028da:	0000f497          	auipc	s1,0xf
    800028de:	df648493          	addi	s1,s1,-522 # 800116d0 <proc>
  {
    if (p->state == UNUSED)
      continue;
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800028e2:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    800028e4:	00006997          	auipc	s3,0x6
    800028e8:	99c98993          	addi	s3,s3,-1636 # 80008280 <digits+0x240>
    // int queue = p->queue;
    // if (p->state == ZOMBIE)
    // {
    //   queue = -1;
    // }
    printf("%d %d %s %d %d %d %d %d %d %d", p->pid, p->queue, state, p->rtime, p->wait_time_in_queue, p->num_runs, p->ticks[0], p->ticks[1], p->ticks[2], p->ticks[3], p->ticks[4]);
    800028ec:	00006a97          	auipc	s5,0x6
    800028f0:	99ca8a93          	addi	s5,s5,-1636 # 80008288 <digits+0x248>
    printf("\n");
    800028f4:	00005a17          	auipc	s4,0x5
    800028f8:	7d4a0a13          	addi	s4,s4,2004 # 800080c8 <digits+0x88>
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800028fc:	00006b97          	auipc	s7,0x6
    80002900:	9d4b8b93          	addi	s7,s7,-1580 # 800082d0 <states.0>
  for (p = proc; p < &proc[NPROC]; p++)
    80002904:	00016917          	auipc	s2,0x16
    80002908:	dcc90913          	addi	s2,s2,-564 # 800186d0 <tickslock>
    8000290c:	a0b1                	j	80002958 <procdump+0xa4>
    printf("%d %d %s %d %d %d %d %d %d %d", p->pid, p->queue, state, p->rtime, p->wait_time_in_queue, p->num_runs, p->ticks[0], p->ticks[1], p->ticks[2], p->ticks[3], p->ticks[4]);
    8000290e:	1ac4a783          	lw	a5,428(s1)
    80002912:	ec3e                	sd	a5,24(sp)
    80002914:	1a84a783          	lw	a5,424(s1)
    80002918:	e83e                	sd	a5,16(sp)
    8000291a:	1a44a783          	lw	a5,420(s1)
    8000291e:	e43e                	sd	a5,8(sp)
    80002920:	1a04a783          	lw	a5,416(s1)
    80002924:	e03e                	sd	a5,0(sp)
    80002926:	19c4a883          	lw	a7,412(s1)
    8000292a:	1984a803          	lw	a6,408(s1)
    8000292e:	1bc4a783          	lw	a5,444(s1)
    80002932:	1684a703          	lw	a4,360(s1)
    80002936:	1b44a603          	lw	a2,436(s1)
    8000293a:	588c                	lw	a1,48(s1)
    8000293c:	8556                	mv	a0,s5
    8000293e:	ffffe097          	auipc	ra,0xffffe
    80002942:	c46080e7          	jalr	-954(ra) # 80000584 <printf>
    printf("\n");
    80002946:	8552                	mv	a0,s4
    80002948:	ffffe097          	auipc	ra,0xffffe
    8000294c:	c3c080e7          	jalr	-964(ra) # 80000584 <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    80002950:	1c048493          	addi	s1,s1,448
    80002954:	03248063          	beq	s1,s2,80002974 <procdump+0xc0>
    if (p->state == UNUSED)
    80002958:	4c9c                	lw	a5,24(s1)
    8000295a:	dbfd                	beqz	a5,80002950 <procdump+0x9c>
      state = "???";
    8000295c:	86ce                	mv	a3,s3
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000295e:	fafb68e3          	bltu	s6,a5,8000290e <procdump+0x5a>
    80002962:	02079713          	slli	a4,a5,0x20
    80002966:	01d75793          	srli	a5,a4,0x1d
    8000296a:	97de                	add	a5,a5,s7
    8000296c:	6394                	ld	a3,0(a5)
    8000296e:	f2c5                	bnez	a3,8000290e <procdump+0x5a>
      state = "???";
    80002970:	86ce                	mv	a3,s3
    80002972:	bf71                	j	8000290e <procdump+0x5a>
#endif
#endif
#endif
#endif
  }
}
    80002974:	70a6                	ld	ra,104(sp)
    80002976:	7406                	ld	s0,96(sp)
    80002978:	64e6                	ld	s1,88(sp)
    8000297a:	6946                	ld	s2,80(sp)
    8000297c:	69a6                	ld	s3,72(sp)
    8000297e:	6a06                	ld	s4,64(sp)
    80002980:	7ae2                	ld	s5,56(sp)
    80002982:	7b42                	ld	s6,48(sp)
    80002984:	7ba2                	ld	s7,40(sp)
    80002986:	6165                	addi	sp,sp,112
    80002988:	8082                	ret

000000008000298a <set_priority>:
int set_priority(int new_priority, int pid)
{
    8000298a:	7179                	addi	sp,sp,-48
    8000298c:	f406                	sd	ra,40(sp)
    8000298e:	f022                	sd	s0,32(sp)
    80002990:	ec26                	sd	s1,24(sp)
    80002992:	e84a                	sd	s2,16(sp)
    80002994:	e44e                	sd	s3,8(sp)
    80002996:	e052                	sd	s4,0(sp)
    80002998:	1800                	addi	s0,sp,48
  //printf("hello");
  if (new_priority < 0 || new_priority > 100)
    8000299a:	06400793          	li	a5,100
    8000299e:	06a7eb63          	bltu	a5,a0,80002a14 <set_priority+0x8a>
    800029a2:	892e                	mv	s2,a1
    800029a4:	8a2a                	mv	s4,a0
    return -1;

  for (struct proc *p = proc; p < &proc[NPROC]; p++)
    800029a6:	0000f497          	auipc	s1,0xf
    800029aa:	d2a48493          	addi	s1,s1,-726 # 800116d0 <proc>
    800029ae:	00016997          	auipc	s3,0x16
    800029b2:	d2298993          	addi	s3,s3,-734 # 800186d0 <tickslock>
  {
    acquire(&p->lock);
    800029b6:	8526                	mv	a0,s1
    800029b8:	ffffe097          	auipc	ra,0xffffe
    800029bc:	218080e7          	jalr	536(ra) # 80000bd0 <acquire>
    if (p->pid == pid)
    800029c0:	589c                	lw	a5,48(s1)
    800029c2:	01278d63          	beq	a5,s2,800029dc <set_priority+0x52>
      }

      return old_priority;
    }

    release(&p->lock);
    800029c6:	8526                	mv	a0,s1
    800029c8:	ffffe097          	auipc	ra,0xffffe
    800029cc:	2bc080e7          	jalr	700(ra) # 80000c84 <release>
  for (struct proc *p = proc; p < &proc[NPROC]; p++)
    800029d0:	1c048493          	addi	s1,s1,448
    800029d4:	ff3491e3          	bne	s1,s3,800029b6 <set_priority+0x2c>
  }

  return -1;
    800029d8:	597d                	li	s2,-1
    800029da:	a839                	j	800029f8 <set_priority+0x6e>
      int old_priority = p->priority;
    800029dc:	1784a903          	lw	s2,376(s1)
      p->priority = new_priority;
    800029e0:	1744ac23          	sw	s4,376(s1)
      p->niceness = 5;
    800029e4:	4795                	li	a5,5
    800029e6:	18f4a623          	sw	a5,396(s1)
      release(&p->lock);
    800029ea:	8526                	mv	a0,s1
    800029ec:	ffffe097          	auipc	ra,0xffffe
    800029f0:	298080e7          	jalr	664(ra) # 80000c84 <release>
      if (new_priority < old_priority)
    800029f4:	012a4b63          	blt	s4,s2,80002a0a <set_priority+0x80>
}
    800029f8:	854a                	mv	a0,s2
    800029fa:	70a2                	ld	ra,40(sp)
    800029fc:	7402                	ld	s0,32(sp)
    800029fe:	64e2                	ld	s1,24(sp)
    80002a00:	6942                	ld	s2,16(sp)
    80002a02:	69a2                	ld	s3,8(sp)
    80002a04:	6a02                	ld	s4,0(sp)
    80002a06:	6145                	addi	sp,sp,48
    80002a08:	8082                	ret
        yield();
    80002a0a:	fffff097          	auipc	ra,0xfffff
    80002a0e:	746080e7          	jalr	1862(ra) # 80002150 <yield>
    80002a12:	b7dd                	j	800029f8 <set_priority+0x6e>
    return -1;
    80002a14:	597d                	li	s2,-1
    80002a16:	b7cd                	j	800029f8 <set_priority+0x6e>

0000000080002a18 <swtch>:
    80002a18:	00153023          	sd	ra,0(a0)
    80002a1c:	00253423          	sd	sp,8(a0)
    80002a20:	e900                	sd	s0,16(a0)
    80002a22:	ed04                	sd	s1,24(a0)
    80002a24:	03253023          	sd	s2,32(a0)
    80002a28:	03353423          	sd	s3,40(a0)
    80002a2c:	03453823          	sd	s4,48(a0)
    80002a30:	03553c23          	sd	s5,56(a0)
    80002a34:	05653023          	sd	s6,64(a0)
    80002a38:	05753423          	sd	s7,72(a0)
    80002a3c:	05853823          	sd	s8,80(a0)
    80002a40:	05953c23          	sd	s9,88(a0)
    80002a44:	07a53023          	sd	s10,96(a0)
    80002a48:	07b53423          	sd	s11,104(a0)
    80002a4c:	0005b083          	ld	ra,0(a1)
    80002a50:	0085b103          	ld	sp,8(a1)
    80002a54:	6980                	ld	s0,16(a1)
    80002a56:	6d84                	ld	s1,24(a1)
    80002a58:	0205b903          	ld	s2,32(a1)
    80002a5c:	0285b983          	ld	s3,40(a1)
    80002a60:	0305ba03          	ld	s4,48(a1)
    80002a64:	0385ba83          	ld	s5,56(a1)
    80002a68:	0405bb03          	ld	s6,64(a1)
    80002a6c:	0485bb83          	ld	s7,72(a1)
    80002a70:	0505bc03          	ld	s8,80(a1)
    80002a74:	0585bc83          	ld	s9,88(a1)
    80002a78:	0605bd03          	ld	s10,96(a1)
    80002a7c:	0685bd83          	ld	s11,104(a1)
    80002a80:	8082                	ret

0000000080002a82 <trapinit>:
void kernelvec();

extern int devintr();

void trapinit(void)
{
    80002a82:	1141                	addi	sp,sp,-16
    80002a84:	e406                	sd	ra,8(sp)
    80002a86:	e022                	sd	s0,0(sp)
    80002a88:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002a8a:	00006597          	auipc	a1,0x6
    80002a8e:	87658593          	addi	a1,a1,-1930 # 80008300 <states.0+0x30>
    80002a92:	00016517          	auipc	a0,0x16
    80002a96:	c3e50513          	addi	a0,a0,-962 # 800186d0 <tickslock>
    80002a9a:	ffffe097          	auipc	ra,0xffffe
    80002a9e:	0a6080e7          	jalr	166(ra) # 80000b40 <initlock>
}
    80002aa2:	60a2                	ld	ra,8(sp)
    80002aa4:	6402                	ld	s0,0(sp)
    80002aa6:	0141                	addi	sp,sp,16
    80002aa8:	8082                	ret

0000000080002aaa <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void trapinithart(void)
{
    80002aaa:	1141                	addi	sp,sp,-16
    80002aac:	e422                	sd	s0,8(sp)
    80002aae:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002ab0:	00003797          	auipc	a5,0x3
    80002ab4:	73078793          	addi	a5,a5,1840 # 800061e0 <kernelvec>
    80002ab8:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002abc:	6422                	ld	s0,8(sp)
    80002abe:	0141                	addi	sp,sp,16
    80002ac0:	8082                	ret

0000000080002ac2 <usertrapret>:

//
// return to user space
//
void usertrapret(void)
{
    80002ac2:	1141                	addi	sp,sp,-16
    80002ac4:	e406                	sd	ra,8(sp)
    80002ac6:	e022                	sd	s0,0(sp)
    80002ac8:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002aca:	fffff097          	auipc	ra,0xfffff
    80002ace:	ecc080e7          	jalr	-308(ra) # 80001996 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002ad2:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002ad6:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002ad8:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002adc:	00004697          	auipc	a3,0x4
    80002ae0:	52468693          	addi	a3,a3,1316 # 80007000 <_trampoline>
    80002ae4:	00004717          	auipc	a4,0x4
    80002ae8:	51c70713          	addi	a4,a4,1308 # 80007000 <_trampoline>
    80002aec:	8f15                	sub	a4,a4,a3
    80002aee:	040007b7          	lui	a5,0x4000
    80002af2:	17fd                	addi	a5,a5,-1
    80002af4:	07b2                	slli	a5,a5,0xc
    80002af6:	973e                	add	a4,a4,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002af8:	10571073          	csrw	stvec,a4

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002afc:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002afe:	18002673          	csrr	a2,satp
    80002b02:	e310                	sd	a2,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002b04:	6d30                	ld	a2,88(a0)
    80002b06:	6138                	ld	a4,64(a0)
    80002b08:	6585                	lui	a1,0x1
    80002b0a:	972e                	add	a4,a4,a1
    80002b0c:	e618                	sd	a4,8(a2)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002b0e:	6d38                	ld	a4,88(a0)
    80002b10:	00000617          	auipc	a2,0x0
    80002b14:	14660613          	addi	a2,a2,326 # 80002c56 <usertrap>
    80002b18:	eb10                	sd	a2,16(a4)
  p->trapframe->kernel_hartid = r_tp(); // hartid for cpuid()
    80002b1a:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002b1c:	8612                	mv	a2,tp
    80002b1e:	f310                	sd	a2,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b20:	10002773          	csrr	a4,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.

  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002b24:	eff77713          	andi	a4,a4,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002b28:	02076713          	ori	a4,a4,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002b2c:	10071073          	csrw	sstatus,a4
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002b30:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002b32:	6f18                	ld	a4,24(a4)
    80002b34:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002b38:	692c                	ld	a1,80(a0)
    80002b3a:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002b3c:	00004717          	auipc	a4,0x4
    80002b40:	55470713          	addi	a4,a4,1364 # 80007090 <userret>
    80002b44:	8f15                	sub	a4,a4,a3
    80002b46:	97ba                	add	a5,a5,a4
  ((void (*)(uint64, uint64))fn)(TRAPFRAME, satp);
    80002b48:	577d                	li	a4,-1
    80002b4a:	177e                	slli	a4,a4,0x3f
    80002b4c:	8dd9                	or	a1,a1,a4
    80002b4e:	02000537          	lui	a0,0x2000
    80002b52:	157d                	addi	a0,a0,-1
    80002b54:	0536                	slli	a0,a0,0xd
    80002b56:	9782                	jalr	a5
}
    80002b58:	60a2                	ld	ra,8(sp)
    80002b5a:	6402                	ld	s0,0(sp)
    80002b5c:	0141                	addi	sp,sp,16
    80002b5e:	8082                	ret

0000000080002b60 <clockintr>:
  w_sepc(sepc);
  w_sstatus(sstatus);
}

void clockintr()
{
    80002b60:	1101                	addi	sp,sp,-32
    80002b62:	ec06                	sd	ra,24(sp)
    80002b64:	e822                	sd	s0,16(sp)
    80002b66:	e426                	sd	s1,8(sp)
    80002b68:	e04a                	sd	s2,0(sp)
    80002b6a:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002b6c:	00016917          	auipc	s2,0x16
    80002b70:	b6490913          	addi	s2,s2,-1180 # 800186d0 <tickslock>
    80002b74:	854a                	mv	a0,s2
    80002b76:	ffffe097          	auipc	ra,0xffffe
    80002b7a:	05a080e7          	jalr	90(ra) # 80000bd0 <acquire>
  ticks++;
    80002b7e:	00006497          	auipc	s1,0x6
    80002b82:	4b248493          	addi	s1,s1,1202 # 80009030 <ticks>
    80002b86:	409c                	lw	a5,0(s1)
    80002b88:	2785                	addiw	a5,a5,1
    80002b8a:	c09c                	sw	a5,0(s1)
  update_time();
    80002b8c:	fffff097          	auipc	ra,0xfffff
    80002b90:	23a080e7          	jalr	570(ra) # 80001dc6 <update_time>
  wakeup(&ticks);
    80002b94:	8526                	mv	a0,s1
    80002b96:	00000097          	auipc	ra,0x0
    80002b9a:	a2e080e7          	jalr	-1490(ra) # 800025c4 <wakeup>
  release(&tickslock);
    80002b9e:	854a                	mv	a0,s2
    80002ba0:	ffffe097          	auipc	ra,0xffffe
    80002ba4:	0e4080e7          	jalr	228(ra) # 80000c84 <release>
}
    80002ba8:	60e2                	ld	ra,24(sp)
    80002baa:	6442                	ld	s0,16(sp)
    80002bac:	64a2                	ld	s1,8(sp)
    80002bae:	6902                	ld	s2,0(sp)
    80002bb0:	6105                	addi	sp,sp,32
    80002bb2:	8082                	ret

0000000080002bb4 <devintr>:
// and handle it.
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int devintr()
{
    80002bb4:	1101                	addi	sp,sp,-32
    80002bb6:	ec06                	sd	ra,24(sp)
    80002bb8:	e822                	sd	s0,16(sp)
    80002bba:	e426                	sd	s1,8(sp)
    80002bbc:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002bbe:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if ((scause & 0x8000000000000000L) &&
    80002bc2:	00074d63          	bltz	a4,80002bdc <devintr+0x28>
    if (irq)
      plic_complete(irq);

    return 1;
  }
  else if (scause == 0x8000000000000001L)
    80002bc6:	57fd                	li	a5,-1
    80002bc8:	17fe                	slli	a5,a5,0x3f
    80002bca:	0785                	addi	a5,a5,1

    return 2;
  }
  else
  {
    return 0;
    80002bcc:	4501                	li	a0,0
  else if (scause == 0x8000000000000001L)
    80002bce:	06f70363          	beq	a4,a5,80002c34 <devintr+0x80>
  }
}
    80002bd2:	60e2                	ld	ra,24(sp)
    80002bd4:	6442                	ld	s0,16(sp)
    80002bd6:	64a2                	ld	s1,8(sp)
    80002bd8:	6105                	addi	sp,sp,32
    80002bda:	8082                	ret
      (scause & 0xff) == 9)
    80002bdc:	0ff77793          	zext.b	a5,a4
  if ((scause & 0x8000000000000000L) &&
    80002be0:	46a5                	li	a3,9
    80002be2:	fed792e3          	bne	a5,a3,80002bc6 <devintr+0x12>
    int irq = plic_claim();
    80002be6:	00003097          	auipc	ra,0x3
    80002bea:	702080e7          	jalr	1794(ra) # 800062e8 <plic_claim>
    80002bee:	84aa                	mv	s1,a0
    if (irq == UART0_IRQ)
    80002bf0:	47a9                	li	a5,10
    80002bf2:	02f50763          	beq	a0,a5,80002c20 <devintr+0x6c>
    else if (irq == VIRTIO0_IRQ)
    80002bf6:	4785                	li	a5,1
    80002bf8:	02f50963          	beq	a0,a5,80002c2a <devintr+0x76>
    return 1;
    80002bfc:	4505                	li	a0,1
    else if (irq)
    80002bfe:	d8f1                	beqz	s1,80002bd2 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002c00:	85a6                	mv	a1,s1
    80002c02:	00005517          	auipc	a0,0x5
    80002c06:	70650513          	addi	a0,a0,1798 # 80008308 <states.0+0x38>
    80002c0a:	ffffe097          	auipc	ra,0xffffe
    80002c0e:	97a080e7          	jalr	-1670(ra) # 80000584 <printf>
      plic_complete(irq);
    80002c12:	8526                	mv	a0,s1
    80002c14:	00003097          	auipc	ra,0x3
    80002c18:	6f8080e7          	jalr	1784(ra) # 8000630c <plic_complete>
    return 1;
    80002c1c:	4505                	li	a0,1
    80002c1e:	bf55                	j	80002bd2 <devintr+0x1e>
      uartintr();
    80002c20:	ffffe097          	auipc	ra,0xffffe
    80002c24:	d72080e7          	jalr	-654(ra) # 80000992 <uartintr>
    80002c28:	b7ed                	j	80002c12 <devintr+0x5e>
      virtio_disk_intr();
    80002c2a:	00004097          	auipc	ra,0x4
    80002c2e:	b6e080e7          	jalr	-1170(ra) # 80006798 <virtio_disk_intr>
    80002c32:	b7c5                	j	80002c12 <devintr+0x5e>
    if (cpuid() == 0)
    80002c34:	fffff097          	auipc	ra,0xfffff
    80002c38:	d36080e7          	jalr	-714(ra) # 8000196a <cpuid>
    80002c3c:	c901                	beqz	a0,80002c4c <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002c3e:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002c42:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002c44:	14479073          	csrw	sip,a5
    return 2;
    80002c48:	4509                	li	a0,2
    80002c4a:	b761                	j	80002bd2 <devintr+0x1e>
      clockintr();
    80002c4c:	00000097          	auipc	ra,0x0
    80002c50:	f14080e7          	jalr	-236(ra) # 80002b60 <clockintr>
    80002c54:	b7ed                	j	80002c3e <devintr+0x8a>

0000000080002c56 <usertrap>:
{
    80002c56:	1101                	addi	sp,sp,-32
    80002c58:	ec06                	sd	ra,24(sp)
    80002c5a:	e822                	sd	s0,16(sp)
    80002c5c:	e426                	sd	s1,8(sp)
    80002c5e:	e04a                	sd	s2,0(sp)
    80002c60:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c62:	100027f3          	csrr	a5,sstatus
  if ((r_sstatus() & SSTATUS_SPP) != 0)
    80002c66:	1007f793          	andi	a5,a5,256
    80002c6a:	e3ad                	bnez	a5,80002ccc <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002c6c:	00003797          	auipc	a5,0x3
    80002c70:	57478793          	addi	a5,a5,1396 # 800061e0 <kernelvec>
    80002c74:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002c78:	fffff097          	auipc	ra,0xfffff
    80002c7c:	d1e080e7          	jalr	-738(ra) # 80001996 <myproc>
    80002c80:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002c82:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002c84:	14102773          	csrr	a4,sepc
    80002c88:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002c8a:	14202773          	csrr	a4,scause
  if (r_scause() == 8)
    80002c8e:	47a1                	li	a5,8
    80002c90:	04f71c63          	bne	a4,a5,80002ce8 <usertrap+0x92>
    if (p->killed)
    80002c94:	551c                	lw	a5,40(a0)
    80002c96:	e3b9                	bnez	a5,80002cdc <usertrap+0x86>
    p->trapframe->epc += 4;
    80002c98:	6cb8                	ld	a4,88(s1)
    80002c9a:	6f1c                	ld	a5,24(a4)
    80002c9c:	0791                	addi	a5,a5,4
    80002c9e:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002ca0:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002ca4:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002ca8:	10079073          	csrw	sstatus,a5
    syscall();
    80002cac:	00000097          	auipc	ra,0x0
    80002cb0:	35a080e7          	jalr	858(ra) # 80003006 <syscall>
  if (p->killed)
    80002cb4:	549c                	lw	a5,40(s1)
    80002cb6:	efe9                	bnez	a5,80002d90 <usertrap+0x13a>
  usertrapret();
    80002cb8:	00000097          	auipc	ra,0x0
    80002cbc:	e0a080e7          	jalr	-502(ra) # 80002ac2 <usertrapret>
}
    80002cc0:	60e2                	ld	ra,24(sp)
    80002cc2:	6442                	ld	s0,16(sp)
    80002cc4:	64a2                	ld	s1,8(sp)
    80002cc6:	6902                	ld	s2,0(sp)
    80002cc8:	6105                	addi	sp,sp,32
    80002cca:	8082                	ret
    panic("usertrap: not from user mode");
    80002ccc:	00005517          	auipc	a0,0x5
    80002cd0:	65c50513          	addi	a0,a0,1628 # 80008328 <states.0+0x58>
    80002cd4:	ffffe097          	auipc	ra,0xffffe
    80002cd8:	866080e7          	jalr	-1946(ra) # 8000053a <panic>
      exit(-1);
    80002cdc:	557d                	li	a0,-1
    80002cde:	00000097          	auipc	ra,0x0
    80002ce2:	9d6080e7          	jalr	-1578(ra) # 800026b4 <exit>
    80002ce6:	bf4d                	j	80002c98 <usertrap+0x42>
  else if ((which_dev = devintr()) != 0)
    80002ce8:	00000097          	auipc	ra,0x0
    80002cec:	ecc080e7          	jalr	-308(ra) # 80002bb4 <devintr>
    80002cf0:	892a                	mv	s2,a0
    80002cf2:	c501                	beqz	a0,80002cfa <usertrap+0xa4>
  if (p->killed)
    80002cf4:	549c                	lw	a5,40(s1)
    80002cf6:	c3a1                	beqz	a5,80002d36 <usertrap+0xe0>
    80002cf8:	a815                	j	80002d2c <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002cfa:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002cfe:	5890                	lw	a2,48(s1)
    80002d00:	00005517          	auipc	a0,0x5
    80002d04:	64850513          	addi	a0,a0,1608 # 80008348 <states.0+0x78>
    80002d08:	ffffe097          	auipc	ra,0xffffe
    80002d0c:	87c080e7          	jalr	-1924(ra) # 80000584 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002d10:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002d14:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002d18:	00005517          	auipc	a0,0x5
    80002d1c:	66050513          	addi	a0,a0,1632 # 80008378 <states.0+0xa8>
    80002d20:	ffffe097          	auipc	ra,0xffffe
    80002d24:	864080e7          	jalr	-1948(ra) # 80000584 <printf>
    p->killed = 1;
    80002d28:	4785                	li	a5,1
    80002d2a:	d49c                	sw	a5,40(s1)
    exit(-1);
    80002d2c:	557d                	li	a0,-1
    80002d2e:	00000097          	auipc	ra,0x0
    80002d32:	986080e7          	jalr	-1658(ra) # 800026b4 <exit>
  if (which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING && myproc()->cur_ticks >= (1 << myproc()->queue))
    80002d36:	4789                	li	a5,2
    80002d38:	f8f910e3          	bne	s2,a5,80002cb8 <usertrap+0x62>
    80002d3c:	fffff097          	auipc	ra,0xfffff
    80002d40:	c5a080e7          	jalr	-934(ra) # 80001996 <myproc>
    80002d44:	d935                	beqz	a0,80002cb8 <usertrap+0x62>
    80002d46:	fffff097          	auipc	ra,0xfffff
    80002d4a:	c50080e7          	jalr	-944(ra) # 80001996 <myproc>
    80002d4e:	4d18                	lw	a4,24(a0)
    80002d50:	4791                	li	a5,4
    80002d52:	f6f713e3          	bne	a4,a5,80002cb8 <usertrap+0x62>
    80002d56:	fffff097          	auipc	ra,0xfffff
    80002d5a:	c40080e7          	jalr	-960(ra) # 80001996 <myproc>
    80002d5e:	19452483          	lw	s1,404(a0)
    80002d62:	fffff097          	auipc	ra,0xfffff
    80002d66:	c34080e7          	jalr	-972(ra) # 80001996 <myproc>
    80002d6a:	1b452703          	lw	a4,436(a0)
    80002d6e:	4785                	li	a5,1
    80002d70:	00e797bb          	sllw	a5,a5,a4
    80002d74:	f4f4c2e3          	blt	s1,a5,80002cb8 <usertrap+0x62>
    myproc()->flag = 1;
    80002d78:	fffff097          	auipc	ra,0xfffff
    80002d7c:	c1e080e7          	jalr	-994(ra) # 80001996 <myproc>
    80002d80:	4785                	li	a5,1
    80002d82:	1af52c23          	sw	a5,440(a0)
    yield();
    80002d86:	fffff097          	auipc	ra,0xfffff
    80002d8a:	3ca080e7          	jalr	970(ra) # 80002150 <yield>
    80002d8e:	b72d                	j	80002cb8 <usertrap+0x62>
  int which_dev = 0;
    80002d90:	4901                	li	s2,0
    80002d92:	bf69                	j	80002d2c <usertrap+0xd6>

0000000080002d94 <kerneltrap>:
{
    80002d94:	7179                	addi	sp,sp,-48
    80002d96:	f406                	sd	ra,40(sp)
    80002d98:	f022                	sd	s0,32(sp)
    80002d9a:	ec26                	sd	s1,24(sp)
    80002d9c:	e84a                	sd	s2,16(sp)
    80002d9e:	e44e                	sd	s3,8(sp)
    80002da0:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002da2:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002da6:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002daa:	142029f3          	csrr	s3,scause
  if ((sstatus & SSTATUS_SPP) == 0)
    80002dae:	1004f793          	andi	a5,s1,256
    80002db2:	cb85                	beqz	a5,80002de2 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002db4:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002db8:	8b89                	andi	a5,a5,2
  if (intr_get() != 0)
    80002dba:	ef85                	bnez	a5,80002df2 <kerneltrap+0x5e>
  if ((which_dev = devintr()) == 0)
    80002dbc:	00000097          	auipc	ra,0x0
    80002dc0:	df8080e7          	jalr	-520(ra) # 80002bb4 <devintr>
    80002dc4:	cd1d                	beqz	a0,80002e02 <kerneltrap+0x6e>
  if (which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING && myproc()->cur_ticks >= (1 << myproc()->queue))
    80002dc6:	4789                	li	a5,2
    80002dc8:	06f50a63          	beq	a0,a5,80002e3c <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002dcc:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002dd0:	10049073          	csrw	sstatus,s1
}
    80002dd4:	70a2                	ld	ra,40(sp)
    80002dd6:	7402                	ld	s0,32(sp)
    80002dd8:	64e2                	ld	s1,24(sp)
    80002dda:	6942                	ld	s2,16(sp)
    80002ddc:	69a2                	ld	s3,8(sp)
    80002dde:	6145                	addi	sp,sp,48
    80002de0:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002de2:	00005517          	auipc	a0,0x5
    80002de6:	5b650513          	addi	a0,a0,1462 # 80008398 <states.0+0xc8>
    80002dea:	ffffd097          	auipc	ra,0xffffd
    80002dee:	750080e7          	jalr	1872(ra) # 8000053a <panic>
    panic("kerneltrap: interrupts enabled");
    80002df2:	00005517          	auipc	a0,0x5
    80002df6:	5ce50513          	addi	a0,a0,1486 # 800083c0 <states.0+0xf0>
    80002dfa:	ffffd097          	auipc	ra,0xffffd
    80002dfe:	740080e7          	jalr	1856(ra) # 8000053a <panic>
    printf("scause %p\n", scause);
    80002e02:	85ce                	mv	a1,s3
    80002e04:	00005517          	auipc	a0,0x5
    80002e08:	5dc50513          	addi	a0,a0,1500 # 800083e0 <states.0+0x110>
    80002e0c:	ffffd097          	auipc	ra,0xffffd
    80002e10:	778080e7          	jalr	1912(ra) # 80000584 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002e14:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002e18:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002e1c:	00005517          	auipc	a0,0x5
    80002e20:	5d450513          	addi	a0,a0,1492 # 800083f0 <states.0+0x120>
    80002e24:	ffffd097          	auipc	ra,0xffffd
    80002e28:	760080e7          	jalr	1888(ra) # 80000584 <printf>
    panic("kerneltrap");
    80002e2c:	00005517          	auipc	a0,0x5
    80002e30:	5dc50513          	addi	a0,a0,1500 # 80008408 <states.0+0x138>
    80002e34:	ffffd097          	auipc	ra,0xffffd
    80002e38:	706080e7          	jalr	1798(ra) # 8000053a <panic>
  if (which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING && myproc()->cur_ticks >= (1 << myproc()->queue))
    80002e3c:	fffff097          	auipc	ra,0xfffff
    80002e40:	b5a080e7          	jalr	-1190(ra) # 80001996 <myproc>
    80002e44:	d541                	beqz	a0,80002dcc <kerneltrap+0x38>
    80002e46:	fffff097          	auipc	ra,0xfffff
    80002e4a:	b50080e7          	jalr	-1200(ra) # 80001996 <myproc>
    80002e4e:	4d18                	lw	a4,24(a0)
    80002e50:	4791                	li	a5,4
    80002e52:	f6f71de3          	bne	a4,a5,80002dcc <kerneltrap+0x38>
    80002e56:	fffff097          	auipc	ra,0xfffff
    80002e5a:	b40080e7          	jalr	-1216(ra) # 80001996 <myproc>
    80002e5e:	19452983          	lw	s3,404(a0)
    80002e62:	fffff097          	auipc	ra,0xfffff
    80002e66:	b34080e7          	jalr	-1228(ra) # 80001996 <myproc>
    80002e6a:	1b452703          	lw	a4,436(a0)
    80002e6e:	4785                	li	a5,1
    80002e70:	00e797bb          	sllw	a5,a5,a4
    80002e74:	f4f9cce3          	blt	s3,a5,80002dcc <kerneltrap+0x38>
    myproc()->flag = 1;
    80002e78:	fffff097          	auipc	ra,0xfffff
    80002e7c:	b1e080e7          	jalr	-1250(ra) # 80001996 <myproc>
    80002e80:	4785                	li	a5,1
    80002e82:	1af52c23          	sw	a5,440(a0)
    yield();
    80002e86:	fffff097          	auipc	ra,0xfffff
    80002e8a:	2ca080e7          	jalr	714(ra) # 80002150 <yield>
    80002e8e:	bf3d                	j	80002dcc <kerneltrap+0x38>

0000000080002e90 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002e90:	1101                	addi	sp,sp,-32
    80002e92:	ec06                	sd	ra,24(sp)
    80002e94:	e822                	sd	s0,16(sp)
    80002e96:	e426                	sd	s1,8(sp)
    80002e98:	1000                	addi	s0,sp,32
    80002e9a:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002e9c:	fffff097          	auipc	ra,0xfffff
    80002ea0:	afa080e7          	jalr	-1286(ra) # 80001996 <myproc>
  switch (n)
    80002ea4:	4795                	li	a5,5
    80002ea6:	0497e163          	bltu	a5,s1,80002ee8 <argraw+0x58>
    80002eaa:	048a                	slli	s1,s1,0x2
    80002eac:	00005717          	auipc	a4,0x5
    80002eb0:	66c70713          	addi	a4,a4,1644 # 80008518 <states.0+0x248>
    80002eb4:	94ba                	add	s1,s1,a4
    80002eb6:	409c                	lw	a5,0(s1)
    80002eb8:	97ba                	add	a5,a5,a4
    80002eba:	8782                	jr	a5
  {
  case 0:
    return p->trapframe->a0;
    80002ebc:	6d3c                	ld	a5,88(a0)
    80002ebe:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002ec0:	60e2                	ld	ra,24(sp)
    80002ec2:	6442                	ld	s0,16(sp)
    80002ec4:	64a2                	ld	s1,8(sp)
    80002ec6:	6105                	addi	sp,sp,32
    80002ec8:	8082                	ret
    return p->trapframe->a1;
    80002eca:	6d3c                	ld	a5,88(a0)
    80002ecc:	7fa8                	ld	a0,120(a5)
    80002ece:	bfcd                	j	80002ec0 <argraw+0x30>
    return p->trapframe->a2;
    80002ed0:	6d3c                	ld	a5,88(a0)
    80002ed2:	63c8                	ld	a0,128(a5)
    80002ed4:	b7f5                	j	80002ec0 <argraw+0x30>
    return p->trapframe->a3;
    80002ed6:	6d3c                	ld	a5,88(a0)
    80002ed8:	67c8                	ld	a0,136(a5)
    80002eda:	b7dd                	j	80002ec0 <argraw+0x30>
    return p->trapframe->a4;
    80002edc:	6d3c                	ld	a5,88(a0)
    80002ede:	6bc8                	ld	a0,144(a5)
    80002ee0:	b7c5                	j	80002ec0 <argraw+0x30>
    return p->trapframe->a5;
    80002ee2:	6d3c                	ld	a5,88(a0)
    80002ee4:	6fc8                	ld	a0,152(a5)
    80002ee6:	bfe9                	j	80002ec0 <argraw+0x30>
  panic("argraw");
    80002ee8:	00005517          	auipc	a0,0x5
    80002eec:	53050513          	addi	a0,a0,1328 # 80008418 <states.0+0x148>
    80002ef0:	ffffd097          	auipc	ra,0xffffd
    80002ef4:	64a080e7          	jalr	1610(ra) # 8000053a <panic>

0000000080002ef8 <fetchaddr>:
{
    80002ef8:	1101                	addi	sp,sp,-32
    80002efa:	ec06                	sd	ra,24(sp)
    80002efc:	e822                	sd	s0,16(sp)
    80002efe:	e426                	sd	s1,8(sp)
    80002f00:	e04a                	sd	s2,0(sp)
    80002f02:	1000                	addi	s0,sp,32
    80002f04:	84aa                	mv	s1,a0
    80002f06:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002f08:	fffff097          	auipc	ra,0xfffff
    80002f0c:	a8e080e7          	jalr	-1394(ra) # 80001996 <myproc>
  if (addr >= p->sz || addr + sizeof(uint64) > p->sz)
    80002f10:	653c                	ld	a5,72(a0)
    80002f12:	02f4f863          	bgeu	s1,a5,80002f42 <fetchaddr+0x4a>
    80002f16:	00848713          	addi	a4,s1,8
    80002f1a:	02e7e663          	bltu	a5,a4,80002f46 <fetchaddr+0x4e>
  if (copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002f1e:	46a1                	li	a3,8
    80002f20:	8626                	mv	a2,s1
    80002f22:	85ca                	mv	a1,s2
    80002f24:	6928                	ld	a0,80(a0)
    80002f26:	ffffe097          	auipc	ra,0xffffe
    80002f2a:	7c0080e7          	jalr	1984(ra) # 800016e6 <copyin>
    80002f2e:	00a03533          	snez	a0,a0
    80002f32:	40a00533          	neg	a0,a0
}
    80002f36:	60e2                	ld	ra,24(sp)
    80002f38:	6442                	ld	s0,16(sp)
    80002f3a:	64a2                	ld	s1,8(sp)
    80002f3c:	6902                	ld	s2,0(sp)
    80002f3e:	6105                	addi	sp,sp,32
    80002f40:	8082                	ret
    return -1;
    80002f42:	557d                	li	a0,-1
    80002f44:	bfcd                	j	80002f36 <fetchaddr+0x3e>
    80002f46:	557d                	li	a0,-1
    80002f48:	b7fd                	j	80002f36 <fetchaddr+0x3e>

0000000080002f4a <fetchstr>:
{
    80002f4a:	7179                	addi	sp,sp,-48
    80002f4c:	f406                	sd	ra,40(sp)
    80002f4e:	f022                	sd	s0,32(sp)
    80002f50:	ec26                	sd	s1,24(sp)
    80002f52:	e84a                	sd	s2,16(sp)
    80002f54:	e44e                	sd	s3,8(sp)
    80002f56:	1800                	addi	s0,sp,48
    80002f58:	892a                	mv	s2,a0
    80002f5a:	84ae                	mv	s1,a1
    80002f5c:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002f5e:	fffff097          	auipc	ra,0xfffff
    80002f62:	a38080e7          	jalr	-1480(ra) # 80001996 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002f66:	86ce                	mv	a3,s3
    80002f68:	864a                	mv	a2,s2
    80002f6a:	85a6                	mv	a1,s1
    80002f6c:	6928                	ld	a0,80(a0)
    80002f6e:	fffff097          	auipc	ra,0xfffff
    80002f72:	806080e7          	jalr	-2042(ra) # 80001774 <copyinstr>
  if (err < 0)
    80002f76:	00054763          	bltz	a0,80002f84 <fetchstr+0x3a>
  return strlen(buf);
    80002f7a:	8526                	mv	a0,s1
    80002f7c:	ffffe097          	auipc	ra,0xffffe
    80002f80:	ecc080e7          	jalr	-308(ra) # 80000e48 <strlen>
}
    80002f84:	70a2                	ld	ra,40(sp)
    80002f86:	7402                	ld	s0,32(sp)
    80002f88:	64e2                	ld	s1,24(sp)
    80002f8a:	6942                	ld	s2,16(sp)
    80002f8c:	69a2                	ld	s3,8(sp)
    80002f8e:	6145                	addi	sp,sp,48
    80002f90:	8082                	ret

0000000080002f92 <argint>:

// Fetch the nth 32-bit system call argument.
int argint(int n, int *ip)
{
    80002f92:	1101                	addi	sp,sp,-32
    80002f94:	ec06                	sd	ra,24(sp)
    80002f96:	e822                	sd	s0,16(sp)
    80002f98:	e426                	sd	s1,8(sp)
    80002f9a:	1000                	addi	s0,sp,32
    80002f9c:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002f9e:	00000097          	auipc	ra,0x0
    80002fa2:	ef2080e7          	jalr	-270(ra) # 80002e90 <argraw>
    80002fa6:	c088                	sw	a0,0(s1)
  return 0;
}
    80002fa8:	4501                	li	a0,0
    80002faa:	60e2                	ld	ra,24(sp)
    80002fac:	6442                	ld	s0,16(sp)
    80002fae:	64a2                	ld	s1,8(sp)
    80002fb0:	6105                	addi	sp,sp,32
    80002fb2:	8082                	ret

0000000080002fb4 <argaddr>:

// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int argaddr(int n, uint64 *ip)
{
    80002fb4:	1101                	addi	sp,sp,-32
    80002fb6:	ec06                	sd	ra,24(sp)
    80002fb8:	e822                	sd	s0,16(sp)
    80002fba:	e426                	sd	s1,8(sp)
    80002fbc:	1000                	addi	s0,sp,32
    80002fbe:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002fc0:	00000097          	auipc	ra,0x0
    80002fc4:	ed0080e7          	jalr	-304(ra) # 80002e90 <argraw>
    80002fc8:	e088                	sd	a0,0(s1)
  return 0;
}
    80002fca:	4501                	li	a0,0
    80002fcc:	60e2                	ld	ra,24(sp)
    80002fce:	6442                	ld	s0,16(sp)
    80002fd0:	64a2                	ld	s1,8(sp)
    80002fd2:	6105                	addi	sp,sp,32
    80002fd4:	8082                	ret

0000000080002fd6 <argstr>:

// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int argstr(int n, char *buf, int max)
{
    80002fd6:	1101                	addi	sp,sp,-32
    80002fd8:	ec06                	sd	ra,24(sp)
    80002fda:	e822                	sd	s0,16(sp)
    80002fdc:	e426                	sd	s1,8(sp)
    80002fde:	e04a                	sd	s2,0(sp)
    80002fe0:	1000                	addi	s0,sp,32
    80002fe2:	84ae                	mv	s1,a1
    80002fe4:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002fe6:	00000097          	auipc	ra,0x0
    80002fea:	eaa080e7          	jalr	-342(ra) # 80002e90 <argraw>
  uint64 addr;
  if (argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002fee:	864a                	mv	a2,s2
    80002ff0:	85a6                	mv	a1,s1
    80002ff2:	00000097          	auipc	ra,0x0
    80002ff6:	f58080e7          	jalr	-168(ra) # 80002f4a <fetchstr>
}
    80002ffa:	60e2                	ld	ra,24(sp)
    80002ffc:	6442                	ld	s0,16(sp)
    80002ffe:	64a2                	ld	s1,8(sp)
    80003000:	6902                	ld	s2,0(sp)
    80003002:	6105                	addi	sp,sp,32
    80003004:	8082                	ret

0000000080003006 <syscall>:
};

uint arg_numbers[24] = {0, 1, 1, 1, 3, 1, 2, 2, 2, 1, 0, 1, 1, 0, 2, 3, 3, 1, 2, 1, 1, 3, 2, 1};

void syscall(void)
{
    80003006:	711d                	addi	sp,sp,-96
    80003008:	ec86                	sd	ra,88(sp)
    8000300a:	e8a2                	sd	s0,80(sp)
    8000300c:	e4a6                	sd	s1,72(sp)
    8000300e:	e0ca                	sd	s2,64(sp)
    80003010:	fc4e                	sd	s3,56(sp)
    80003012:	f852                	sd	s4,48(sp)
    80003014:	f456                	sd	s5,40(sp)
    80003016:	f05a                	sd	s6,32(sp)
    80003018:	ec5e                	sd	s7,24(sp)
    8000301a:	e862                	sd	s8,16(sp)
    8000301c:	e466                	sd	s9,8(sp)
    8000301e:	1080                	addi	s0,sp,96
  int num;
  int arg = 0;
  struct proc *p = myproc();
    80003020:	fffff097          	auipc	ra,0xfffff
    80003024:	976080e7          	jalr	-1674(ra) # 80001996 <myproc>
    80003028:	84aa                	mv	s1,a0
  num = p->trapframe->a7;
    8000302a:	05853983          	ld	s3,88(a0)
    8000302e:	0a89b783          	ld	a5,168(s3)
    80003032:	0007891b          	sext.w	s2,a5
  if (num > 0 && num < NELEM(syscalls) && syscalls[num])
    80003036:	37fd                	addiw	a5,a5,-1
    80003038:	475d                	li	a4,23
    8000303a:	0ef76163          	bltu	a4,a5,8000311c <syscall+0x116>
    8000303e:	00391713          	slli	a4,s2,0x3
    80003042:	00005797          	auipc	a5,0x5
    80003046:	4ee78793          	addi	a5,a5,1262 # 80008530 <syscalls>
    8000304a:	97ba                	add	a5,a5,a4
    8000304c:	639c                	ld	a5,0(a5)
    8000304e:	c7f9                	beqz	a5,8000311c <syscall+0x116>
  {
    arg = p->trapframe->a0;
    80003050:	0709bb03          	ld	s6,112(s3)
    p->trapframe->a0 = syscalls[num]();
    80003054:	9782                	jalr	a5
    80003056:	06a9b823          	sd	a0,112(s3)
    if (p->mask >> num)
    8000305a:	1744a783          	lw	a5,372(s1)
    8000305e:	4127d7bb          	sraw	a5,a5,s2
    80003062:	cfe1                	beqz	a5,8000313a <syscall+0x134>
    {
      printf("%d: syscall %s (", p->pid, syscall_names[num]);
    80003064:	00006997          	auipc	s3,0x6
    80003068:	90c98993          	addi	s3,s3,-1780 # 80008970 <syscall_names>
    8000306c:	00391793          	slli	a5,s2,0x3
    80003070:	97ce                	add	a5,a5,s3
    80003072:	6390                	ld	a2,0(a5)
    80003074:	588c                	lw	a1,48(s1)
    80003076:	00005517          	auipc	a0,0x5
    8000307a:	3aa50513          	addi	a0,a0,938 # 80008420 <states.0+0x150>
    8000307e:	ffffd097          	auipc	ra,0xffffd
    80003082:	506080e7          	jalr	1286(ra) # 80000584 <printf>
      for (int i = 1; i <= arg_numbers[num - 1]; i++)
    80003086:	fff9079b          	addiw	a5,s2,-1
    8000308a:	00279713          	slli	a4,a5,0x2
    8000308e:	99ba                	add	s3,s3,a4
    80003090:	0c89a703          	lw	a4,200(s3)
    80003094:	cb2d                	beqz	a4,80003106 <syscall+0x100>
    arg = p->trapframe->a0;
    80003096:	2b01                	sext.w	s6,s6
      for (int i = 1; i <= arg_numbers[num - 1]; i++)
    80003098:	4905                	li	s2,1
      {
        if (i == 1)
    8000309a:	4a05                	li	s4,1
        {
          printf("%d ", arg);
        }
        if (i == 2)
    8000309c:	4a89                	li	s5,2
        {
          printf("%d ", p->trapframe->a1);
        }
        if (i == 3)
    8000309e:	4b8d                	li	s7,3
        {
          printf("%d", p->trapframe->a2);
    800030a0:	00005c97          	auipc	s9,0x5
    800030a4:	3a0c8c93          	addi	s9,s9,928 # 80008440 <states.0+0x170>
          printf("%d ", p->trapframe->a1);
    800030a8:	00005c17          	auipc	s8,0x5
    800030ac:	390c0c13          	addi	s8,s8,912 # 80008438 <states.0+0x168>
      for (int i = 1; i <= arg_numbers[num - 1]; i++)
    800030b0:	078a                	slli	a5,a5,0x2
    800030b2:	00006997          	auipc	s3,0x6
    800030b6:	8be98993          	addi	s3,s3,-1858 # 80008970 <syscall_names>
    800030ba:	99be                	add	s3,s3,a5
    800030bc:	a03d                	j	800030ea <syscall+0xe4>
          printf("%d ", arg);
    800030be:	85da                	mv	a1,s6
    800030c0:	8562                	mv	a0,s8
    800030c2:	ffffd097          	auipc	ra,0xffffd
    800030c6:	4c2080e7          	jalr	1218(ra) # 80000584 <printf>
        if (i == 3)
    800030ca:	a801                	j	800030da <syscall+0xd4>
          printf("%d ", p->trapframe->a1);
    800030cc:	6cbc                	ld	a5,88(s1)
    800030ce:	7fac                	ld	a1,120(a5)
    800030d0:	8562                	mv	a0,s8
    800030d2:	ffffd097          	auipc	ra,0xffffd
    800030d6:	4b2080e7          	jalr	1202(ra) # 80000584 <printf>
      for (int i = 1; i <= arg_numbers[num - 1]; i++)
    800030da:	0019079b          	addiw	a5,s2,1
    800030de:	0007891b          	sext.w	s2,a5
    800030e2:	0c89a703          	lw	a4,200(s3)
    800030e6:	03276063          	bltu	a4,s2,80003106 <syscall+0x100>
        if (i == 1)
    800030ea:	fd490ae3          	beq	s2,s4,800030be <syscall+0xb8>
        if (i == 2)
    800030ee:	fd590fe3          	beq	s2,s5,800030cc <syscall+0xc6>
        if (i == 3)
    800030f2:	ff7914e3          	bne	s2,s7,800030da <syscall+0xd4>
          printf("%d", p->trapframe->a2);
    800030f6:	6cbc                	ld	a5,88(s1)
    800030f8:	63cc                	ld	a1,128(a5)
    800030fa:	8566                	mv	a0,s9
    800030fc:	ffffd097          	auipc	ra,0xffffd
    80003100:	488080e7          	jalr	1160(ra) # 80000584 <printf>
    80003104:	bfd9                	j	800030da <syscall+0xd4>
        }
      }
      printf(")-> %d\n", p->trapframe->a0);
    80003106:	6cbc                	ld	a5,88(s1)
    80003108:	7bac                	ld	a1,112(a5)
    8000310a:	00005517          	auipc	a0,0x5
    8000310e:	33e50513          	addi	a0,a0,830 # 80008448 <states.0+0x178>
    80003112:	ffffd097          	auipc	ra,0xffffd
    80003116:	472080e7          	jalr	1138(ra) # 80000584 <printf>
    8000311a:	a005                	j	8000313a <syscall+0x134>
    }
  }
  else
  {
    printf("%d %s: unknown sys call %d\n",
    8000311c:	86ca                	mv	a3,s2
    8000311e:	15848613          	addi	a2,s1,344
    80003122:	588c                	lw	a1,48(s1)
    80003124:	00005517          	auipc	a0,0x5
    80003128:	32c50513          	addi	a0,a0,812 # 80008450 <states.0+0x180>
    8000312c:	ffffd097          	auipc	ra,0xffffd
    80003130:	458080e7          	jalr	1112(ra) # 80000584 <printf>
           p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80003134:	6cbc                	ld	a5,88(s1)
    80003136:	577d                	li	a4,-1
    80003138:	fbb8                	sd	a4,112(a5)
  }
}
    8000313a:	60e6                	ld	ra,88(sp)
    8000313c:	6446                	ld	s0,80(sp)
    8000313e:	64a6                	ld	s1,72(sp)
    80003140:	6906                	ld	s2,64(sp)
    80003142:	79e2                	ld	s3,56(sp)
    80003144:	7a42                	ld	s4,48(sp)
    80003146:	7aa2                	ld	s5,40(sp)
    80003148:	7b02                	ld	s6,32(sp)
    8000314a:	6be2                	ld	s7,24(sp)
    8000314c:	6c42                	ld	s8,16(sp)
    8000314e:	6ca2                	ld	s9,8(sp)
    80003150:	6125                	addi	sp,sp,96
    80003152:	8082                	ret

0000000080003154 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80003154:	1101                	addi	sp,sp,-32
    80003156:	ec06                	sd	ra,24(sp)
    80003158:	e822                	sd	s0,16(sp)
    8000315a:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    8000315c:	fec40593          	addi	a1,s0,-20
    80003160:	4501                	li	a0,0
    80003162:	00000097          	auipc	ra,0x0
    80003166:	e30080e7          	jalr	-464(ra) # 80002f92 <argint>
    return -1;
    8000316a:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    8000316c:	00054963          	bltz	a0,8000317e <sys_exit+0x2a>
  exit(n);
    80003170:	fec42503          	lw	a0,-20(s0)
    80003174:	fffff097          	auipc	ra,0xfffff
    80003178:	540080e7          	jalr	1344(ra) # 800026b4 <exit>
  return 0;  // not reached
    8000317c:	4781                	li	a5,0
}
    8000317e:	853e                	mv	a0,a5
    80003180:	60e2                	ld	ra,24(sp)
    80003182:	6442                	ld	s0,16(sp)
    80003184:	6105                	addi	sp,sp,32
    80003186:	8082                	ret

0000000080003188 <sys_getpid>:

uint64
sys_getpid(void)
{
    80003188:	1141                	addi	sp,sp,-16
    8000318a:	e406                	sd	ra,8(sp)
    8000318c:	e022                	sd	s0,0(sp)
    8000318e:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80003190:	fffff097          	auipc	ra,0xfffff
    80003194:	806080e7          	jalr	-2042(ra) # 80001996 <myproc>
}
    80003198:	5908                	lw	a0,48(a0)
    8000319a:	60a2                	ld	ra,8(sp)
    8000319c:	6402                	ld	s0,0(sp)
    8000319e:	0141                	addi	sp,sp,16
    800031a0:	8082                	ret

00000000800031a2 <sys_fork>:

uint64
sys_fork(void)
{
    800031a2:	1141                	addi	sp,sp,-16
    800031a4:	e406                	sd	ra,8(sp)
    800031a6:	e022                	sd	s0,0(sp)
    800031a8:	0800                	addi	s0,sp,16
  return fork();
    800031aa:	fffff097          	auipc	ra,0xfffff
    800031ae:	fe2080e7          	jalr	-30(ra) # 8000218c <fork>
}
    800031b2:	60a2                	ld	ra,8(sp)
    800031b4:	6402                	ld	s0,0(sp)
    800031b6:	0141                	addi	sp,sp,16
    800031b8:	8082                	ret

00000000800031ba <sys_wait>:

uint64
sys_wait(void)
{
    800031ba:	1101                	addi	sp,sp,-32
    800031bc:	ec06                	sd	ra,24(sp)
    800031be:	e822                	sd	s0,16(sp)
    800031c0:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    800031c2:	fe840593          	addi	a1,s0,-24
    800031c6:	4501                	li	a0,0
    800031c8:	00000097          	auipc	ra,0x0
    800031cc:	dec080e7          	jalr	-532(ra) # 80002fb4 <argaddr>
    800031d0:	87aa                	mv	a5,a0
    return -1;
    800031d2:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    800031d4:	0007c863          	bltz	a5,800031e4 <sys_wait+0x2a>
  return wait(p);
    800031d8:	fe843503          	ld	a0,-24(s0)
    800031dc:	fffff097          	auipc	ra,0xfffff
    800031e0:	174080e7          	jalr	372(ra) # 80002350 <wait>
}
    800031e4:	60e2                	ld	ra,24(sp)
    800031e6:	6442                	ld	s0,16(sp)
    800031e8:	6105                	addi	sp,sp,32
    800031ea:	8082                	ret

00000000800031ec <sys_waitx>:

uint64
sys_waitx(void)
{
    800031ec:	7139                	addi	sp,sp,-64
    800031ee:	fc06                	sd	ra,56(sp)
    800031f0:	f822                	sd	s0,48(sp)
    800031f2:	f426                	sd	s1,40(sp)
    800031f4:	f04a                	sd	s2,32(sp)
    800031f6:	0080                	addi	s0,sp,64
  uint64 addr, addr1, addr2;
  uint wtime, rtime;
  if(argaddr(0, &addr) < 0)
    800031f8:	fd840593          	addi	a1,s0,-40
    800031fc:	4501                	li	a0,0
    800031fe:	00000097          	auipc	ra,0x0
    80003202:	db6080e7          	jalr	-586(ra) # 80002fb4 <argaddr>
    return -1;
    80003206:	57fd                	li	a5,-1
  if(argaddr(0, &addr) < 0)
    80003208:	08054063          	bltz	a0,80003288 <sys_waitx+0x9c>
  if(argaddr(1, &addr1) < 0) // user virtual memory
    8000320c:	fd040593          	addi	a1,s0,-48
    80003210:	4505                	li	a0,1
    80003212:	00000097          	auipc	ra,0x0
    80003216:	da2080e7          	jalr	-606(ra) # 80002fb4 <argaddr>
    return -1;
    8000321a:	57fd                	li	a5,-1
  if(argaddr(1, &addr1) < 0) // user virtual memory
    8000321c:	06054663          	bltz	a0,80003288 <sys_waitx+0x9c>
  if(argaddr(2, &addr2) < 0)
    80003220:	fc840593          	addi	a1,s0,-56
    80003224:	4509                	li	a0,2
    80003226:	00000097          	auipc	ra,0x0
    8000322a:	d8e080e7          	jalr	-626(ra) # 80002fb4 <argaddr>
    return -1;
    8000322e:	57fd                	li	a5,-1
  if(argaddr(2, &addr2) < 0)
    80003230:	04054c63          	bltz	a0,80003288 <sys_waitx+0x9c>
  int ret = waitx(addr, &wtime, &rtime);
    80003234:	fc040613          	addi	a2,s0,-64
    80003238:	fc440593          	addi	a1,s0,-60
    8000323c:	fd843503          	ld	a0,-40(s0)
    80003240:	fffff097          	auipc	ra,0xfffff
    80003244:	238080e7          	jalr	568(ra) # 80002478 <waitx>
    80003248:	892a                	mv	s2,a0
  struct proc* p = myproc();
    8000324a:	ffffe097          	auipc	ra,0xffffe
    8000324e:	74c080e7          	jalr	1868(ra) # 80001996 <myproc>
    80003252:	84aa                	mv	s1,a0
  if (copyout(p->pagetable, addr1,(char*)&wtime, sizeof(int)) < 0)
    80003254:	4691                	li	a3,4
    80003256:	fc440613          	addi	a2,s0,-60
    8000325a:	fd043583          	ld	a1,-48(s0)
    8000325e:	6928                	ld	a0,80(a0)
    80003260:	ffffe097          	auipc	ra,0xffffe
    80003264:	3fa080e7          	jalr	1018(ra) # 8000165a <copyout>
    return -1;
    80003268:	57fd                	li	a5,-1
  if (copyout(p->pagetable, addr1,(char*)&wtime, sizeof(int)) < 0)
    8000326a:	00054f63          	bltz	a0,80003288 <sys_waitx+0x9c>
  if (copyout(p->pagetable, addr2,(char*)&rtime, sizeof(int)) < 0)
    8000326e:	4691                	li	a3,4
    80003270:	fc040613          	addi	a2,s0,-64
    80003274:	fc843583          	ld	a1,-56(s0)
    80003278:	68a8                	ld	a0,80(s1)
    8000327a:	ffffe097          	auipc	ra,0xffffe
    8000327e:	3e0080e7          	jalr	992(ra) # 8000165a <copyout>
    80003282:	00054a63          	bltz	a0,80003296 <sys_waitx+0xaa>
    return -1;
  return ret;
    80003286:	87ca                	mv	a5,s2
}
    80003288:	853e                	mv	a0,a5
    8000328a:	70e2                	ld	ra,56(sp)
    8000328c:	7442                	ld	s0,48(sp)
    8000328e:	74a2                	ld	s1,40(sp)
    80003290:	7902                	ld	s2,32(sp)
    80003292:	6121                	addi	sp,sp,64
    80003294:	8082                	ret
    return -1;
    80003296:	57fd                	li	a5,-1
    80003298:	bfc5                	j	80003288 <sys_waitx+0x9c>

000000008000329a <sys_sbrk>:

uint64
sys_sbrk(void)
{
    8000329a:	7179                	addi	sp,sp,-48
    8000329c:	f406                	sd	ra,40(sp)
    8000329e:	f022                	sd	s0,32(sp)
    800032a0:	ec26                	sd	s1,24(sp)
    800032a2:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    800032a4:	fdc40593          	addi	a1,s0,-36
    800032a8:	4501                	li	a0,0
    800032aa:	00000097          	auipc	ra,0x0
    800032ae:	ce8080e7          	jalr	-792(ra) # 80002f92 <argint>
    800032b2:	87aa                	mv	a5,a0
    return -1;
    800032b4:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    800032b6:	0207c063          	bltz	a5,800032d6 <sys_sbrk+0x3c>
  addr = myproc()->sz;
    800032ba:	ffffe097          	auipc	ra,0xffffe
    800032be:	6dc080e7          	jalr	1756(ra) # 80001996 <myproc>
    800032c2:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    800032c4:	fdc42503          	lw	a0,-36(s0)
    800032c8:	fffff097          	auipc	ra,0xfffff
    800032cc:	a86080e7          	jalr	-1402(ra) # 80001d4e <growproc>
    800032d0:	00054863          	bltz	a0,800032e0 <sys_sbrk+0x46>
    return -1;
  return addr;
    800032d4:	8526                	mv	a0,s1
}
    800032d6:	70a2                	ld	ra,40(sp)
    800032d8:	7402                	ld	s0,32(sp)
    800032da:	64e2                	ld	s1,24(sp)
    800032dc:	6145                	addi	sp,sp,48
    800032de:	8082                	ret
    return -1;
    800032e0:	557d                	li	a0,-1
    800032e2:	bfd5                	j	800032d6 <sys_sbrk+0x3c>

00000000800032e4 <sys_sleep>:

uint64
sys_sleep(void)
{
    800032e4:	7139                	addi	sp,sp,-64
    800032e6:	fc06                	sd	ra,56(sp)
    800032e8:	f822                	sd	s0,48(sp)
    800032ea:	f426                	sd	s1,40(sp)
    800032ec:	f04a                	sd	s2,32(sp)
    800032ee:	ec4e                	sd	s3,24(sp)
    800032f0:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    800032f2:	fcc40593          	addi	a1,s0,-52
    800032f6:	4501                	li	a0,0
    800032f8:	00000097          	auipc	ra,0x0
    800032fc:	c9a080e7          	jalr	-870(ra) # 80002f92 <argint>
    return -1;
    80003300:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80003302:	06054563          	bltz	a0,8000336c <sys_sleep+0x88>
  acquire(&tickslock);
    80003306:	00015517          	auipc	a0,0x15
    8000330a:	3ca50513          	addi	a0,a0,970 # 800186d0 <tickslock>
    8000330e:	ffffe097          	auipc	ra,0xffffe
    80003312:	8c2080e7          	jalr	-1854(ra) # 80000bd0 <acquire>
  ticks0 = ticks;
    80003316:	00006917          	auipc	s2,0x6
    8000331a:	d1a92903          	lw	s2,-742(s2) # 80009030 <ticks>
  while(ticks - ticks0 < n){
    8000331e:	fcc42783          	lw	a5,-52(s0)
    80003322:	cf85                	beqz	a5,8000335a <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80003324:	00015997          	auipc	s3,0x15
    80003328:	3ac98993          	addi	s3,s3,940 # 800186d0 <tickslock>
    8000332c:	00006497          	auipc	s1,0x6
    80003330:	d0448493          	addi	s1,s1,-764 # 80009030 <ticks>
    if(myproc()->killed){
    80003334:	ffffe097          	auipc	ra,0xffffe
    80003338:	662080e7          	jalr	1634(ra) # 80001996 <myproc>
    8000333c:	551c                	lw	a5,40(a0)
    8000333e:	ef9d                	bnez	a5,8000337c <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80003340:	85ce                	mv	a1,s3
    80003342:	8526                	mv	a0,s1
    80003344:	fffff097          	auipc	ra,0xfffff
    80003348:	f98080e7          	jalr	-104(ra) # 800022dc <sleep>
  while(ticks - ticks0 < n){
    8000334c:	409c                	lw	a5,0(s1)
    8000334e:	412787bb          	subw	a5,a5,s2
    80003352:	fcc42703          	lw	a4,-52(s0)
    80003356:	fce7efe3          	bltu	a5,a4,80003334 <sys_sleep+0x50>
  }
  release(&tickslock);
    8000335a:	00015517          	auipc	a0,0x15
    8000335e:	37650513          	addi	a0,a0,886 # 800186d0 <tickslock>
    80003362:	ffffe097          	auipc	ra,0xffffe
    80003366:	922080e7          	jalr	-1758(ra) # 80000c84 <release>
  return 0;
    8000336a:	4781                	li	a5,0
}
    8000336c:	853e                	mv	a0,a5
    8000336e:	70e2                	ld	ra,56(sp)
    80003370:	7442                	ld	s0,48(sp)
    80003372:	74a2                	ld	s1,40(sp)
    80003374:	7902                	ld	s2,32(sp)
    80003376:	69e2                	ld	s3,24(sp)
    80003378:	6121                	addi	sp,sp,64
    8000337a:	8082                	ret
      release(&tickslock);
    8000337c:	00015517          	auipc	a0,0x15
    80003380:	35450513          	addi	a0,a0,852 # 800186d0 <tickslock>
    80003384:	ffffe097          	auipc	ra,0xffffe
    80003388:	900080e7          	jalr	-1792(ra) # 80000c84 <release>
      return -1;
    8000338c:	57fd                	li	a5,-1
    8000338e:	bff9                	j	8000336c <sys_sleep+0x88>

0000000080003390 <sys_kill>:

uint64
sys_kill(void)
{
    80003390:	1101                	addi	sp,sp,-32
    80003392:	ec06                	sd	ra,24(sp)
    80003394:	e822                	sd	s0,16(sp)
    80003396:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80003398:	fec40593          	addi	a1,s0,-20
    8000339c:	4501                	li	a0,0
    8000339e:	00000097          	auipc	ra,0x0
    800033a2:	bf4080e7          	jalr	-1036(ra) # 80002f92 <argint>
    800033a6:	87aa                	mv	a5,a0
    return -1;
    800033a8:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    800033aa:	0007c863          	bltz	a5,800033ba <sys_kill+0x2a>
  return kill(pid);
    800033ae:	fec42503          	lw	a0,-20(s0)
    800033b2:	fffff097          	auipc	ra,0xfffff
    800033b6:	3e4080e7          	jalr	996(ra) # 80002796 <kill>
}
    800033ba:	60e2                	ld	ra,24(sp)
    800033bc:	6442                	ld	s0,16(sp)
    800033be:	6105                	addi	sp,sp,32
    800033c0:	8082                	ret

00000000800033c2 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    800033c2:	1101                	addi	sp,sp,-32
    800033c4:	ec06                	sd	ra,24(sp)
    800033c6:	e822                	sd	s0,16(sp)
    800033c8:	e426                	sd	s1,8(sp)
    800033ca:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    800033cc:	00015517          	auipc	a0,0x15
    800033d0:	30450513          	addi	a0,a0,772 # 800186d0 <tickslock>
    800033d4:	ffffd097          	auipc	ra,0xffffd
    800033d8:	7fc080e7          	jalr	2044(ra) # 80000bd0 <acquire>
  xticks = ticks;
    800033dc:	00006497          	auipc	s1,0x6
    800033e0:	c544a483          	lw	s1,-940(s1) # 80009030 <ticks>
  release(&tickslock);
    800033e4:	00015517          	auipc	a0,0x15
    800033e8:	2ec50513          	addi	a0,a0,748 # 800186d0 <tickslock>
    800033ec:	ffffe097          	auipc	ra,0xffffe
    800033f0:	898080e7          	jalr	-1896(ra) # 80000c84 <release>
  return xticks;
}
    800033f4:	02049513          	slli	a0,s1,0x20
    800033f8:	9101                	srli	a0,a0,0x20
    800033fa:	60e2                	ld	ra,24(sp)
    800033fc:	6442                	ld	s0,16(sp)
    800033fe:	64a2                	ld	s1,8(sp)
    80003400:	6105                	addi	sp,sp,32
    80003402:	8082                	ret

0000000080003404 <sys_trace>:

uint64
sys_trace(void)
{
    80003404:	1141                	addi	sp,sp,-16
    80003406:	e406                	sd	ra,8(sp)
    80003408:	e022                	sd	s0,0(sp)
    8000340a:	0800                	addi	s0,sp,16
	if (argint(0, &myproc()->mask) < 0)
    8000340c:	ffffe097          	auipc	ra,0xffffe
    80003410:	58a080e7          	jalr	1418(ra) # 80001996 <myproc>
    80003414:	17450593          	addi	a1,a0,372
    80003418:	4501                	li	a0,0
    8000341a:	00000097          	auipc	ra,0x0
    8000341e:	b78080e7          	jalr	-1160(ra) # 80002f92 <argint>
		return -1;

	return 0;
}
    80003422:	957d                	srai	a0,a0,0x3f
    80003424:	60a2                	ld	ra,8(sp)
    80003426:	6402                	ld	s0,0(sp)
    80003428:	0141                	addi	sp,sp,16
    8000342a:	8082                	ret

000000008000342c <sys_set_priority>:

uint64
sys_set_priority(void)
{
    8000342c:	1101                	addi	sp,sp,-32
    8000342e:	ec06                	sd	ra,24(sp)
    80003430:	e822                	sd	s0,16(sp)
    80003432:	1000                	addi	s0,sp,32
  int pri, pid;
  if (argint(0, &pri) < 0)
    80003434:	fec40593          	addi	a1,s0,-20
    80003438:	4501                	li	a0,0
    8000343a:	00000097          	auipc	ra,0x0
    8000343e:	b58080e7          	jalr	-1192(ra) # 80002f92 <argint>
    return -1;
    80003442:	57fd                	li	a5,-1
  if (argint(0, &pri) < 0)
    80003444:	02054563          	bltz	a0,8000346e <sys_set_priority+0x42>
  if (argint(1, &pid) < 0)
    80003448:	fe840593          	addi	a1,s0,-24
    8000344c:	4505                	li	a0,1
    8000344e:	00000097          	auipc	ra,0x0
    80003452:	b44080e7          	jalr	-1212(ra) # 80002f92 <argint>
    return -1;
    80003456:	57fd                	li	a5,-1
  if (argint(1, &pid) < 0)
    80003458:	00054b63          	bltz	a0,8000346e <sys_set_priority+0x42>
  return set_priority(pri , pid);
    8000345c:	fe842583          	lw	a1,-24(s0)
    80003460:	fec42503          	lw	a0,-20(s0)
    80003464:	fffff097          	auipc	ra,0xfffff
    80003468:	526080e7          	jalr	1318(ra) # 8000298a <set_priority>
    8000346c:	87aa                	mv	a5,a0
    8000346e:	853e                	mv	a0,a5
    80003470:	60e2                	ld	ra,24(sp)
    80003472:	6442                	ld	s0,16(sp)
    80003474:	6105                	addi	sp,sp,32
    80003476:	8082                	ret

0000000080003478 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80003478:	7179                	addi	sp,sp,-48
    8000347a:	f406                	sd	ra,40(sp)
    8000347c:	f022                	sd	s0,32(sp)
    8000347e:	ec26                	sd	s1,24(sp)
    80003480:	e84a                	sd	s2,16(sp)
    80003482:	e44e                	sd	s3,8(sp)
    80003484:	e052                	sd	s4,0(sp)
    80003486:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80003488:	00005597          	auipc	a1,0x5
    8000348c:	17058593          	addi	a1,a1,368 # 800085f8 <syscalls+0xc8>
    80003490:	00015517          	auipc	a0,0x15
    80003494:	25850513          	addi	a0,a0,600 # 800186e8 <bcache>
    80003498:	ffffd097          	auipc	ra,0xffffd
    8000349c:	6a8080e7          	jalr	1704(ra) # 80000b40 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    800034a0:	0001d797          	auipc	a5,0x1d
    800034a4:	24878793          	addi	a5,a5,584 # 800206e8 <bcache+0x8000>
    800034a8:	0001d717          	auipc	a4,0x1d
    800034ac:	4a870713          	addi	a4,a4,1192 # 80020950 <bcache+0x8268>
    800034b0:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    800034b4:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800034b8:	00015497          	auipc	s1,0x15
    800034bc:	24848493          	addi	s1,s1,584 # 80018700 <bcache+0x18>
    b->next = bcache.head.next;
    800034c0:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    800034c2:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    800034c4:	00005a17          	auipc	s4,0x5
    800034c8:	13ca0a13          	addi	s4,s4,316 # 80008600 <syscalls+0xd0>
    b->next = bcache.head.next;
    800034cc:	2b893783          	ld	a5,696(s2)
    800034d0:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    800034d2:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    800034d6:	85d2                	mv	a1,s4
    800034d8:	01048513          	addi	a0,s1,16
    800034dc:	00001097          	auipc	ra,0x1
    800034e0:	4c2080e7          	jalr	1218(ra) # 8000499e <initsleeplock>
    bcache.head.next->prev = b;
    800034e4:	2b893783          	ld	a5,696(s2)
    800034e8:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    800034ea:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800034ee:	45848493          	addi	s1,s1,1112
    800034f2:	fd349de3          	bne	s1,s3,800034cc <binit+0x54>
  }
}
    800034f6:	70a2                	ld	ra,40(sp)
    800034f8:	7402                	ld	s0,32(sp)
    800034fa:	64e2                	ld	s1,24(sp)
    800034fc:	6942                	ld	s2,16(sp)
    800034fe:	69a2                	ld	s3,8(sp)
    80003500:	6a02                	ld	s4,0(sp)
    80003502:	6145                	addi	sp,sp,48
    80003504:	8082                	ret

0000000080003506 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80003506:	7179                	addi	sp,sp,-48
    80003508:	f406                	sd	ra,40(sp)
    8000350a:	f022                	sd	s0,32(sp)
    8000350c:	ec26                	sd	s1,24(sp)
    8000350e:	e84a                	sd	s2,16(sp)
    80003510:	e44e                	sd	s3,8(sp)
    80003512:	1800                	addi	s0,sp,48
    80003514:	892a                	mv	s2,a0
    80003516:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    80003518:	00015517          	auipc	a0,0x15
    8000351c:	1d050513          	addi	a0,a0,464 # 800186e8 <bcache>
    80003520:	ffffd097          	auipc	ra,0xffffd
    80003524:	6b0080e7          	jalr	1712(ra) # 80000bd0 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80003528:	0001d497          	auipc	s1,0x1d
    8000352c:	4784b483          	ld	s1,1144(s1) # 800209a0 <bcache+0x82b8>
    80003530:	0001d797          	auipc	a5,0x1d
    80003534:	42078793          	addi	a5,a5,1056 # 80020950 <bcache+0x8268>
    80003538:	02f48f63          	beq	s1,a5,80003576 <bread+0x70>
    8000353c:	873e                	mv	a4,a5
    8000353e:	a021                	j	80003546 <bread+0x40>
    80003540:	68a4                	ld	s1,80(s1)
    80003542:	02e48a63          	beq	s1,a4,80003576 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80003546:	449c                	lw	a5,8(s1)
    80003548:	ff279ce3          	bne	a5,s2,80003540 <bread+0x3a>
    8000354c:	44dc                	lw	a5,12(s1)
    8000354e:	ff3799e3          	bne	a5,s3,80003540 <bread+0x3a>
      b->refcnt++;
    80003552:	40bc                	lw	a5,64(s1)
    80003554:	2785                	addiw	a5,a5,1
    80003556:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003558:	00015517          	auipc	a0,0x15
    8000355c:	19050513          	addi	a0,a0,400 # 800186e8 <bcache>
    80003560:	ffffd097          	auipc	ra,0xffffd
    80003564:	724080e7          	jalr	1828(ra) # 80000c84 <release>
      acquiresleep(&b->lock);
    80003568:	01048513          	addi	a0,s1,16
    8000356c:	00001097          	auipc	ra,0x1
    80003570:	46c080e7          	jalr	1132(ra) # 800049d8 <acquiresleep>
      return b;
    80003574:	a8b9                	j	800035d2 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003576:	0001d497          	auipc	s1,0x1d
    8000357a:	4224b483          	ld	s1,1058(s1) # 80020998 <bcache+0x82b0>
    8000357e:	0001d797          	auipc	a5,0x1d
    80003582:	3d278793          	addi	a5,a5,978 # 80020950 <bcache+0x8268>
    80003586:	00f48863          	beq	s1,a5,80003596 <bread+0x90>
    8000358a:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    8000358c:	40bc                	lw	a5,64(s1)
    8000358e:	cf81                	beqz	a5,800035a6 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003590:	64a4                	ld	s1,72(s1)
    80003592:	fee49de3          	bne	s1,a4,8000358c <bread+0x86>
  panic("bget: no buffers");
    80003596:	00005517          	auipc	a0,0x5
    8000359a:	07250513          	addi	a0,a0,114 # 80008608 <syscalls+0xd8>
    8000359e:	ffffd097          	auipc	ra,0xffffd
    800035a2:	f9c080e7          	jalr	-100(ra) # 8000053a <panic>
      b->dev = dev;
    800035a6:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    800035aa:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    800035ae:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    800035b2:	4785                	li	a5,1
    800035b4:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800035b6:	00015517          	auipc	a0,0x15
    800035ba:	13250513          	addi	a0,a0,306 # 800186e8 <bcache>
    800035be:	ffffd097          	auipc	ra,0xffffd
    800035c2:	6c6080e7          	jalr	1734(ra) # 80000c84 <release>
      acquiresleep(&b->lock);
    800035c6:	01048513          	addi	a0,s1,16
    800035ca:	00001097          	auipc	ra,0x1
    800035ce:	40e080e7          	jalr	1038(ra) # 800049d8 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    800035d2:	409c                	lw	a5,0(s1)
    800035d4:	cb89                	beqz	a5,800035e6 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    800035d6:	8526                	mv	a0,s1
    800035d8:	70a2                	ld	ra,40(sp)
    800035da:	7402                	ld	s0,32(sp)
    800035dc:	64e2                	ld	s1,24(sp)
    800035de:	6942                	ld	s2,16(sp)
    800035e0:	69a2                	ld	s3,8(sp)
    800035e2:	6145                	addi	sp,sp,48
    800035e4:	8082                	ret
    virtio_disk_rw(b, 0);
    800035e6:	4581                	li	a1,0
    800035e8:	8526                	mv	a0,s1
    800035ea:	00003097          	auipc	ra,0x3
    800035ee:	f28080e7          	jalr	-216(ra) # 80006512 <virtio_disk_rw>
    b->valid = 1;
    800035f2:	4785                	li	a5,1
    800035f4:	c09c                	sw	a5,0(s1)
  return b;
    800035f6:	b7c5                	j	800035d6 <bread+0xd0>

00000000800035f8 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    800035f8:	1101                	addi	sp,sp,-32
    800035fa:	ec06                	sd	ra,24(sp)
    800035fc:	e822                	sd	s0,16(sp)
    800035fe:	e426                	sd	s1,8(sp)
    80003600:	1000                	addi	s0,sp,32
    80003602:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003604:	0541                	addi	a0,a0,16
    80003606:	00001097          	auipc	ra,0x1
    8000360a:	46c080e7          	jalr	1132(ra) # 80004a72 <holdingsleep>
    8000360e:	cd01                	beqz	a0,80003626 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003610:	4585                	li	a1,1
    80003612:	8526                	mv	a0,s1
    80003614:	00003097          	auipc	ra,0x3
    80003618:	efe080e7          	jalr	-258(ra) # 80006512 <virtio_disk_rw>
}
    8000361c:	60e2                	ld	ra,24(sp)
    8000361e:	6442                	ld	s0,16(sp)
    80003620:	64a2                	ld	s1,8(sp)
    80003622:	6105                	addi	sp,sp,32
    80003624:	8082                	ret
    panic("bwrite");
    80003626:	00005517          	auipc	a0,0x5
    8000362a:	ffa50513          	addi	a0,a0,-6 # 80008620 <syscalls+0xf0>
    8000362e:	ffffd097          	auipc	ra,0xffffd
    80003632:	f0c080e7          	jalr	-244(ra) # 8000053a <panic>

0000000080003636 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003636:	1101                	addi	sp,sp,-32
    80003638:	ec06                	sd	ra,24(sp)
    8000363a:	e822                	sd	s0,16(sp)
    8000363c:	e426                	sd	s1,8(sp)
    8000363e:	e04a                	sd	s2,0(sp)
    80003640:	1000                	addi	s0,sp,32
    80003642:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003644:	01050913          	addi	s2,a0,16
    80003648:	854a                	mv	a0,s2
    8000364a:	00001097          	auipc	ra,0x1
    8000364e:	428080e7          	jalr	1064(ra) # 80004a72 <holdingsleep>
    80003652:	c92d                	beqz	a0,800036c4 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003654:	854a                	mv	a0,s2
    80003656:	00001097          	auipc	ra,0x1
    8000365a:	3d8080e7          	jalr	984(ra) # 80004a2e <releasesleep>

  acquire(&bcache.lock);
    8000365e:	00015517          	auipc	a0,0x15
    80003662:	08a50513          	addi	a0,a0,138 # 800186e8 <bcache>
    80003666:	ffffd097          	auipc	ra,0xffffd
    8000366a:	56a080e7          	jalr	1386(ra) # 80000bd0 <acquire>
  b->refcnt--;
    8000366e:	40bc                	lw	a5,64(s1)
    80003670:	37fd                	addiw	a5,a5,-1
    80003672:	0007871b          	sext.w	a4,a5
    80003676:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003678:	eb05                	bnez	a4,800036a8 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    8000367a:	68bc                	ld	a5,80(s1)
    8000367c:	64b8                	ld	a4,72(s1)
    8000367e:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003680:	64bc                	ld	a5,72(s1)
    80003682:	68b8                	ld	a4,80(s1)
    80003684:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003686:	0001d797          	auipc	a5,0x1d
    8000368a:	06278793          	addi	a5,a5,98 # 800206e8 <bcache+0x8000>
    8000368e:	2b87b703          	ld	a4,696(a5)
    80003692:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003694:	0001d717          	auipc	a4,0x1d
    80003698:	2bc70713          	addi	a4,a4,700 # 80020950 <bcache+0x8268>
    8000369c:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    8000369e:	2b87b703          	ld	a4,696(a5)
    800036a2:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    800036a4:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    800036a8:	00015517          	auipc	a0,0x15
    800036ac:	04050513          	addi	a0,a0,64 # 800186e8 <bcache>
    800036b0:	ffffd097          	auipc	ra,0xffffd
    800036b4:	5d4080e7          	jalr	1492(ra) # 80000c84 <release>
}
    800036b8:	60e2                	ld	ra,24(sp)
    800036ba:	6442                	ld	s0,16(sp)
    800036bc:	64a2                	ld	s1,8(sp)
    800036be:	6902                	ld	s2,0(sp)
    800036c0:	6105                	addi	sp,sp,32
    800036c2:	8082                	ret
    panic("brelse");
    800036c4:	00005517          	auipc	a0,0x5
    800036c8:	f6450513          	addi	a0,a0,-156 # 80008628 <syscalls+0xf8>
    800036cc:	ffffd097          	auipc	ra,0xffffd
    800036d0:	e6e080e7          	jalr	-402(ra) # 8000053a <panic>

00000000800036d4 <bpin>:

void
bpin(struct buf *b) {
    800036d4:	1101                	addi	sp,sp,-32
    800036d6:	ec06                	sd	ra,24(sp)
    800036d8:	e822                	sd	s0,16(sp)
    800036da:	e426                	sd	s1,8(sp)
    800036dc:	1000                	addi	s0,sp,32
    800036de:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800036e0:	00015517          	auipc	a0,0x15
    800036e4:	00850513          	addi	a0,a0,8 # 800186e8 <bcache>
    800036e8:	ffffd097          	auipc	ra,0xffffd
    800036ec:	4e8080e7          	jalr	1256(ra) # 80000bd0 <acquire>
  b->refcnt++;
    800036f0:	40bc                	lw	a5,64(s1)
    800036f2:	2785                	addiw	a5,a5,1
    800036f4:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800036f6:	00015517          	auipc	a0,0x15
    800036fa:	ff250513          	addi	a0,a0,-14 # 800186e8 <bcache>
    800036fe:	ffffd097          	auipc	ra,0xffffd
    80003702:	586080e7          	jalr	1414(ra) # 80000c84 <release>
}
    80003706:	60e2                	ld	ra,24(sp)
    80003708:	6442                	ld	s0,16(sp)
    8000370a:	64a2                	ld	s1,8(sp)
    8000370c:	6105                	addi	sp,sp,32
    8000370e:	8082                	ret

0000000080003710 <bunpin>:

void
bunpin(struct buf *b) {
    80003710:	1101                	addi	sp,sp,-32
    80003712:	ec06                	sd	ra,24(sp)
    80003714:	e822                	sd	s0,16(sp)
    80003716:	e426                	sd	s1,8(sp)
    80003718:	1000                	addi	s0,sp,32
    8000371a:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000371c:	00015517          	auipc	a0,0x15
    80003720:	fcc50513          	addi	a0,a0,-52 # 800186e8 <bcache>
    80003724:	ffffd097          	auipc	ra,0xffffd
    80003728:	4ac080e7          	jalr	1196(ra) # 80000bd0 <acquire>
  b->refcnt--;
    8000372c:	40bc                	lw	a5,64(s1)
    8000372e:	37fd                	addiw	a5,a5,-1
    80003730:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003732:	00015517          	auipc	a0,0x15
    80003736:	fb650513          	addi	a0,a0,-74 # 800186e8 <bcache>
    8000373a:	ffffd097          	auipc	ra,0xffffd
    8000373e:	54a080e7          	jalr	1354(ra) # 80000c84 <release>
}
    80003742:	60e2                	ld	ra,24(sp)
    80003744:	6442                	ld	s0,16(sp)
    80003746:	64a2                	ld	s1,8(sp)
    80003748:	6105                	addi	sp,sp,32
    8000374a:	8082                	ret

000000008000374c <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    8000374c:	1101                	addi	sp,sp,-32
    8000374e:	ec06                	sd	ra,24(sp)
    80003750:	e822                	sd	s0,16(sp)
    80003752:	e426                	sd	s1,8(sp)
    80003754:	e04a                	sd	s2,0(sp)
    80003756:	1000                	addi	s0,sp,32
    80003758:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    8000375a:	00d5d59b          	srliw	a1,a1,0xd
    8000375e:	0001d797          	auipc	a5,0x1d
    80003762:	6667a783          	lw	a5,1638(a5) # 80020dc4 <sb+0x1c>
    80003766:	9dbd                	addw	a1,a1,a5
    80003768:	00000097          	auipc	ra,0x0
    8000376c:	d9e080e7          	jalr	-610(ra) # 80003506 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003770:	0074f713          	andi	a4,s1,7
    80003774:	4785                	li	a5,1
    80003776:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    8000377a:	14ce                	slli	s1,s1,0x33
    8000377c:	90d9                	srli	s1,s1,0x36
    8000377e:	00950733          	add	a4,a0,s1
    80003782:	05874703          	lbu	a4,88(a4)
    80003786:	00e7f6b3          	and	a3,a5,a4
    8000378a:	c69d                	beqz	a3,800037b8 <bfree+0x6c>
    8000378c:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    8000378e:	94aa                	add	s1,s1,a0
    80003790:	fff7c793          	not	a5,a5
    80003794:	8f7d                	and	a4,a4,a5
    80003796:	04e48c23          	sb	a4,88(s1)
  log_write(bp);
    8000379a:	00001097          	auipc	ra,0x1
    8000379e:	120080e7          	jalr	288(ra) # 800048ba <log_write>
  brelse(bp);
    800037a2:	854a                	mv	a0,s2
    800037a4:	00000097          	auipc	ra,0x0
    800037a8:	e92080e7          	jalr	-366(ra) # 80003636 <brelse>
}
    800037ac:	60e2                	ld	ra,24(sp)
    800037ae:	6442                	ld	s0,16(sp)
    800037b0:	64a2                	ld	s1,8(sp)
    800037b2:	6902                	ld	s2,0(sp)
    800037b4:	6105                	addi	sp,sp,32
    800037b6:	8082                	ret
    panic("freeing free block");
    800037b8:	00005517          	auipc	a0,0x5
    800037bc:	e7850513          	addi	a0,a0,-392 # 80008630 <syscalls+0x100>
    800037c0:	ffffd097          	auipc	ra,0xffffd
    800037c4:	d7a080e7          	jalr	-646(ra) # 8000053a <panic>

00000000800037c8 <balloc>:
{
    800037c8:	711d                	addi	sp,sp,-96
    800037ca:	ec86                	sd	ra,88(sp)
    800037cc:	e8a2                	sd	s0,80(sp)
    800037ce:	e4a6                	sd	s1,72(sp)
    800037d0:	e0ca                	sd	s2,64(sp)
    800037d2:	fc4e                	sd	s3,56(sp)
    800037d4:	f852                	sd	s4,48(sp)
    800037d6:	f456                	sd	s5,40(sp)
    800037d8:	f05a                	sd	s6,32(sp)
    800037da:	ec5e                	sd	s7,24(sp)
    800037dc:	e862                	sd	s8,16(sp)
    800037de:	e466                	sd	s9,8(sp)
    800037e0:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800037e2:	0001d797          	auipc	a5,0x1d
    800037e6:	5ca7a783          	lw	a5,1482(a5) # 80020dac <sb+0x4>
    800037ea:	cbc1                	beqz	a5,8000387a <balloc+0xb2>
    800037ec:	8baa                	mv	s7,a0
    800037ee:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800037f0:	0001db17          	auipc	s6,0x1d
    800037f4:	5b8b0b13          	addi	s6,s6,1464 # 80020da8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800037f8:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800037fa:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800037fc:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800037fe:	6c89                	lui	s9,0x2
    80003800:	a831                	j	8000381c <balloc+0x54>
    brelse(bp);
    80003802:	854a                	mv	a0,s2
    80003804:	00000097          	auipc	ra,0x0
    80003808:	e32080e7          	jalr	-462(ra) # 80003636 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    8000380c:	015c87bb          	addw	a5,s9,s5
    80003810:	00078a9b          	sext.w	s5,a5
    80003814:	004b2703          	lw	a4,4(s6)
    80003818:	06eaf163          	bgeu	s5,a4,8000387a <balloc+0xb2>
    bp = bread(dev, BBLOCK(b, sb));
    8000381c:	41fad79b          	sraiw	a5,s5,0x1f
    80003820:	0137d79b          	srliw	a5,a5,0x13
    80003824:	015787bb          	addw	a5,a5,s5
    80003828:	40d7d79b          	sraiw	a5,a5,0xd
    8000382c:	01cb2583          	lw	a1,28(s6)
    80003830:	9dbd                	addw	a1,a1,a5
    80003832:	855e                	mv	a0,s7
    80003834:	00000097          	auipc	ra,0x0
    80003838:	cd2080e7          	jalr	-814(ra) # 80003506 <bread>
    8000383c:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000383e:	004b2503          	lw	a0,4(s6)
    80003842:	000a849b          	sext.w	s1,s5
    80003846:	8762                	mv	a4,s8
    80003848:	faa4fde3          	bgeu	s1,a0,80003802 <balloc+0x3a>
      m = 1 << (bi % 8);
    8000384c:	00777693          	andi	a3,a4,7
    80003850:	00d996bb          	sllw	a3,s3,a3
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003854:	41f7579b          	sraiw	a5,a4,0x1f
    80003858:	01d7d79b          	srliw	a5,a5,0x1d
    8000385c:	9fb9                	addw	a5,a5,a4
    8000385e:	4037d79b          	sraiw	a5,a5,0x3
    80003862:	00f90633          	add	a2,s2,a5
    80003866:	05864603          	lbu	a2,88(a2)
    8000386a:	00c6f5b3          	and	a1,a3,a2
    8000386e:	cd91                	beqz	a1,8000388a <balloc+0xc2>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003870:	2705                	addiw	a4,a4,1
    80003872:	2485                	addiw	s1,s1,1
    80003874:	fd471ae3          	bne	a4,s4,80003848 <balloc+0x80>
    80003878:	b769                	j	80003802 <balloc+0x3a>
  panic("balloc: out of blocks");
    8000387a:	00005517          	auipc	a0,0x5
    8000387e:	dce50513          	addi	a0,a0,-562 # 80008648 <syscalls+0x118>
    80003882:	ffffd097          	auipc	ra,0xffffd
    80003886:	cb8080e7          	jalr	-840(ra) # 8000053a <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    8000388a:	97ca                	add	a5,a5,s2
    8000388c:	8e55                	or	a2,a2,a3
    8000388e:	04c78c23          	sb	a2,88(a5)
        log_write(bp);
    80003892:	854a                	mv	a0,s2
    80003894:	00001097          	auipc	ra,0x1
    80003898:	026080e7          	jalr	38(ra) # 800048ba <log_write>
        brelse(bp);
    8000389c:	854a                	mv	a0,s2
    8000389e:	00000097          	auipc	ra,0x0
    800038a2:	d98080e7          	jalr	-616(ra) # 80003636 <brelse>
  bp = bread(dev, bno);
    800038a6:	85a6                	mv	a1,s1
    800038a8:	855e                	mv	a0,s7
    800038aa:	00000097          	auipc	ra,0x0
    800038ae:	c5c080e7          	jalr	-932(ra) # 80003506 <bread>
    800038b2:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800038b4:	40000613          	li	a2,1024
    800038b8:	4581                	li	a1,0
    800038ba:	05850513          	addi	a0,a0,88
    800038be:	ffffd097          	auipc	ra,0xffffd
    800038c2:	40e080e7          	jalr	1038(ra) # 80000ccc <memset>
  log_write(bp);
    800038c6:	854a                	mv	a0,s2
    800038c8:	00001097          	auipc	ra,0x1
    800038cc:	ff2080e7          	jalr	-14(ra) # 800048ba <log_write>
  brelse(bp);
    800038d0:	854a                	mv	a0,s2
    800038d2:	00000097          	auipc	ra,0x0
    800038d6:	d64080e7          	jalr	-668(ra) # 80003636 <brelse>
}
    800038da:	8526                	mv	a0,s1
    800038dc:	60e6                	ld	ra,88(sp)
    800038de:	6446                	ld	s0,80(sp)
    800038e0:	64a6                	ld	s1,72(sp)
    800038e2:	6906                	ld	s2,64(sp)
    800038e4:	79e2                	ld	s3,56(sp)
    800038e6:	7a42                	ld	s4,48(sp)
    800038e8:	7aa2                	ld	s5,40(sp)
    800038ea:	7b02                	ld	s6,32(sp)
    800038ec:	6be2                	ld	s7,24(sp)
    800038ee:	6c42                	ld	s8,16(sp)
    800038f0:	6ca2                	ld	s9,8(sp)
    800038f2:	6125                	addi	sp,sp,96
    800038f4:	8082                	ret

00000000800038f6 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    800038f6:	7179                	addi	sp,sp,-48
    800038f8:	f406                	sd	ra,40(sp)
    800038fa:	f022                	sd	s0,32(sp)
    800038fc:	ec26                	sd	s1,24(sp)
    800038fe:	e84a                	sd	s2,16(sp)
    80003900:	e44e                	sd	s3,8(sp)
    80003902:	e052                	sd	s4,0(sp)
    80003904:	1800                	addi	s0,sp,48
    80003906:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003908:	47ad                	li	a5,11
    8000390a:	04b7fe63          	bgeu	a5,a1,80003966 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    8000390e:	ff45849b          	addiw	s1,a1,-12
    80003912:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003916:	0ff00793          	li	a5,255
    8000391a:	0ae7e463          	bltu	a5,a4,800039c2 <bmap+0xcc>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    8000391e:	08052583          	lw	a1,128(a0)
    80003922:	c5b5                	beqz	a1,8000398e <bmap+0x98>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    80003924:	00092503          	lw	a0,0(s2)
    80003928:	00000097          	auipc	ra,0x0
    8000392c:	bde080e7          	jalr	-1058(ra) # 80003506 <bread>
    80003930:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003932:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003936:	02049713          	slli	a4,s1,0x20
    8000393a:	01e75593          	srli	a1,a4,0x1e
    8000393e:	00b784b3          	add	s1,a5,a1
    80003942:	0004a983          	lw	s3,0(s1)
    80003946:	04098e63          	beqz	s3,800039a2 <bmap+0xac>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    8000394a:	8552                	mv	a0,s4
    8000394c:	00000097          	auipc	ra,0x0
    80003950:	cea080e7          	jalr	-790(ra) # 80003636 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003954:	854e                	mv	a0,s3
    80003956:	70a2                	ld	ra,40(sp)
    80003958:	7402                	ld	s0,32(sp)
    8000395a:	64e2                	ld	s1,24(sp)
    8000395c:	6942                	ld	s2,16(sp)
    8000395e:	69a2                	ld	s3,8(sp)
    80003960:	6a02                	ld	s4,0(sp)
    80003962:	6145                	addi	sp,sp,48
    80003964:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    80003966:	02059793          	slli	a5,a1,0x20
    8000396a:	01e7d593          	srli	a1,a5,0x1e
    8000396e:	00b504b3          	add	s1,a0,a1
    80003972:	0504a983          	lw	s3,80(s1)
    80003976:	fc099fe3          	bnez	s3,80003954 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    8000397a:	4108                	lw	a0,0(a0)
    8000397c:	00000097          	auipc	ra,0x0
    80003980:	e4c080e7          	jalr	-436(ra) # 800037c8 <balloc>
    80003984:	0005099b          	sext.w	s3,a0
    80003988:	0534a823          	sw	s3,80(s1)
    8000398c:	b7e1                	j	80003954 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    8000398e:	4108                	lw	a0,0(a0)
    80003990:	00000097          	auipc	ra,0x0
    80003994:	e38080e7          	jalr	-456(ra) # 800037c8 <balloc>
    80003998:	0005059b          	sext.w	a1,a0
    8000399c:	08b92023          	sw	a1,128(s2)
    800039a0:	b751                	j	80003924 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    800039a2:	00092503          	lw	a0,0(s2)
    800039a6:	00000097          	auipc	ra,0x0
    800039aa:	e22080e7          	jalr	-478(ra) # 800037c8 <balloc>
    800039ae:	0005099b          	sext.w	s3,a0
    800039b2:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    800039b6:	8552                	mv	a0,s4
    800039b8:	00001097          	auipc	ra,0x1
    800039bc:	f02080e7          	jalr	-254(ra) # 800048ba <log_write>
    800039c0:	b769                	j	8000394a <bmap+0x54>
  panic("bmap: out of range");
    800039c2:	00005517          	auipc	a0,0x5
    800039c6:	c9e50513          	addi	a0,a0,-866 # 80008660 <syscalls+0x130>
    800039ca:	ffffd097          	auipc	ra,0xffffd
    800039ce:	b70080e7          	jalr	-1168(ra) # 8000053a <panic>

00000000800039d2 <iget>:
{
    800039d2:	7179                	addi	sp,sp,-48
    800039d4:	f406                	sd	ra,40(sp)
    800039d6:	f022                	sd	s0,32(sp)
    800039d8:	ec26                	sd	s1,24(sp)
    800039da:	e84a                	sd	s2,16(sp)
    800039dc:	e44e                	sd	s3,8(sp)
    800039de:	e052                	sd	s4,0(sp)
    800039e0:	1800                	addi	s0,sp,48
    800039e2:	89aa                	mv	s3,a0
    800039e4:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    800039e6:	0001d517          	auipc	a0,0x1d
    800039ea:	3e250513          	addi	a0,a0,994 # 80020dc8 <itable>
    800039ee:	ffffd097          	auipc	ra,0xffffd
    800039f2:	1e2080e7          	jalr	482(ra) # 80000bd0 <acquire>
  empty = 0;
    800039f6:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800039f8:	0001d497          	auipc	s1,0x1d
    800039fc:	3e848493          	addi	s1,s1,1000 # 80020de0 <itable+0x18>
    80003a00:	0001f697          	auipc	a3,0x1f
    80003a04:	e7068693          	addi	a3,a3,-400 # 80022870 <log>
    80003a08:	a039                	j	80003a16 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003a0a:	02090b63          	beqz	s2,80003a40 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003a0e:	08848493          	addi	s1,s1,136
    80003a12:	02d48a63          	beq	s1,a3,80003a46 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003a16:	449c                	lw	a5,8(s1)
    80003a18:	fef059e3          	blez	a5,80003a0a <iget+0x38>
    80003a1c:	4098                	lw	a4,0(s1)
    80003a1e:	ff3716e3          	bne	a4,s3,80003a0a <iget+0x38>
    80003a22:	40d8                	lw	a4,4(s1)
    80003a24:	ff4713e3          	bne	a4,s4,80003a0a <iget+0x38>
      ip->ref++;
    80003a28:	2785                	addiw	a5,a5,1
    80003a2a:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003a2c:	0001d517          	auipc	a0,0x1d
    80003a30:	39c50513          	addi	a0,a0,924 # 80020dc8 <itable>
    80003a34:	ffffd097          	auipc	ra,0xffffd
    80003a38:	250080e7          	jalr	592(ra) # 80000c84 <release>
      return ip;
    80003a3c:	8926                	mv	s2,s1
    80003a3e:	a03d                	j	80003a6c <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003a40:	f7f9                	bnez	a5,80003a0e <iget+0x3c>
    80003a42:	8926                	mv	s2,s1
    80003a44:	b7e9                	j	80003a0e <iget+0x3c>
  if(empty == 0)
    80003a46:	02090c63          	beqz	s2,80003a7e <iget+0xac>
  ip->dev = dev;
    80003a4a:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003a4e:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003a52:	4785                	li	a5,1
    80003a54:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003a58:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003a5c:	0001d517          	auipc	a0,0x1d
    80003a60:	36c50513          	addi	a0,a0,876 # 80020dc8 <itable>
    80003a64:	ffffd097          	auipc	ra,0xffffd
    80003a68:	220080e7          	jalr	544(ra) # 80000c84 <release>
}
    80003a6c:	854a                	mv	a0,s2
    80003a6e:	70a2                	ld	ra,40(sp)
    80003a70:	7402                	ld	s0,32(sp)
    80003a72:	64e2                	ld	s1,24(sp)
    80003a74:	6942                	ld	s2,16(sp)
    80003a76:	69a2                	ld	s3,8(sp)
    80003a78:	6a02                	ld	s4,0(sp)
    80003a7a:	6145                	addi	sp,sp,48
    80003a7c:	8082                	ret
    panic("iget: no inodes");
    80003a7e:	00005517          	auipc	a0,0x5
    80003a82:	bfa50513          	addi	a0,a0,-1030 # 80008678 <syscalls+0x148>
    80003a86:	ffffd097          	auipc	ra,0xffffd
    80003a8a:	ab4080e7          	jalr	-1356(ra) # 8000053a <panic>

0000000080003a8e <fsinit>:
fsinit(int dev) {
    80003a8e:	7179                	addi	sp,sp,-48
    80003a90:	f406                	sd	ra,40(sp)
    80003a92:	f022                	sd	s0,32(sp)
    80003a94:	ec26                	sd	s1,24(sp)
    80003a96:	e84a                	sd	s2,16(sp)
    80003a98:	e44e                	sd	s3,8(sp)
    80003a9a:	1800                	addi	s0,sp,48
    80003a9c:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003a9e:	4585                	li	a1,1
    80003aa0:	00000097          	auipc	ra,0x0
    80003aa4:	a66080e7          	jalr	-1434(ra) # 80003506 <bread>
    80003aa8:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003aaa:	0001d997          	auipc	s3,0x1d
    80003aae:	2fe98993          	addi	s3,s3,766 # 80020da8 <sb>
    80003ab2:	02000613          	li	a2,32
    80003ab6:	05850593          	addi	a1,a0,88
    80003aba:	854e                	mv	a0,s3
    80003abc:	ffffd097          	auipc	ra,0xffffd
    80003ac0:	26c080e7          	jalr	620(ra) # 80000d28 <memmove>
  brelse(bp);
    80003ac4:	8526                	mv	a0,s1
    80003ac6:	00000097          	auipc	ra,0x0
    80003aca:	b70080e7          	jalr	-1168(ra) # 80003636 <brelse>
  if(sb.magic != FSMAGIC)
    80003ace:	0009a703          	lw	a4,0(s3)
    80003ad2:	102037b7          	lui	a5,0x10203
    80003ad6:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003ada:	02f71263          	bne	a4,a5,80003afe <fsinit+0x70>
  initlog(dev, &sb);
    80003ade:	0001d597          	auipc	a1,0x1d
    80003ae2:	2ca58593          	addi	a1,a1,714 # 80020da8 <sb>
    80003ae6:	854a                	mv	a0,s2
    80003ae8:	00001097          	auipc	ra,0x1
    80003aec:	b56080e7          	jalr	-1194(ra) # 8000463e <initlog>
}
    80003af0:	70a2                	ld	ra,40(sp)
    80003af2:	7402                	ld	s0,32(sp)
    80003af4:	64e2                	ld	s1,24(sp)
    80003af6:	6942                	ld	s2,16(sp)
    80003af8:	69a2                	ld	s3,8(sp)
    80003afa:	6145                	addi	sp,sp,48
    80003afc:	8082                	ret
    panic("invalid file system");
    80003afe:	00005517          	auipc	a0,0x5
    80003b02:	b8a50513          	addi	a0,a0,-1142 # 80008688 <syscalls+0x158>
    80003b06:	ffffd097          	auipc	ra,0xffffd
    80003b0a:	a34080e7          	jalr	-1484(ra) # 8000053a <panic>

0000000080003b0e <iinit>:
{
    80003b0e:	7179                	addi	sp,sp,-48
    80003b10:	f406                	sd	ra,40(sp)
    80003b12:	f022                	sd	s0,32(sp)
    80003b14:	ec26                	sd	s1,24(sp)
    80003b16:	e84a                	sd	s2,16(sp)
    80003b18:	e44e                	sd	s3,8(sp)
    80003b1a:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003b1c:	00005597          	auipc	a1,0x5
    80003b20:	b8458593          	addi	a1,a1,-1148 # 800086a0 <syscalls+0x170>
    80003b24:	0001d517          	auipc	a0,0x1d
    80003b28:	2a450513          	addi	a0,a0,676 # 80020dc8 <itable>
    80003b2c:	ffffd097          	auipc	ra,0xffffd
    80003b30:	014080e7          	jalr	20(ra) # 80000b40 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003b34:	0001d497          	auipc	s1,0x1d
    80003b38:	2bc48493          	addi	s1,s1,700 # 80020df0 <itable+0x28>
    80003b3c:	0001f997          	auipc	s3,0x1f
    80003b40:	d4498993          	addi	s3,s3,-700 # 80022880 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003b44:	00005917          	auipc	s2,0x5
    80003b48:	b6490913          	addi	s2,s2,-1180 # 800086a8 <syscalls+0x178>
    80003b4c:	85ca                	mv	a1,s2
    80003b4e:	8526                	mv	a0,s1
    80003b50:	00001097          	auipc	ra,0x1
    80003b54:	e4e080e7          	jalr	-434(ra) # 8000499e <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003b58:	08848493          	addi	s1,s1,136
    80003b5c:	ff3498e3          	bne	s1,s3,80003b4c <iinit+0x3e>
}
    80003b60:	70a2                	ld	ra,40(sp)
    80003b62:	7402                	ld	s0,32(sp)
    80003b64:	64e2                	ld	s1,24(sp)
    80003b66:	6942                	ld	s2,16(sp)
    80003b68:	69a2                	ld	s3,8(sp)
    80003b6a:	6145                	addi	sp,sp,48
    80003b6c:	8082                	ret

0000000080003b6e <ialloc>:
{
    80003b6e:	715d                	addi	sp,sp,-80
    80003b70:	e486                	sd	ra,72(sp)
    80003b72:	e0a2                	sd	s0,64(sp)
    80003b74:	fc26                	sd	s1,56(sp)
    80003b76:	f84a                	sd	s2,48(sp)
    80003b78:	f44e                	sd	s3,40(sp)
    80003b7a:	f052                	sd	s4,32(sp)
    80003b7c:	ec56                	sd	s5,24(sp)
    80003b7e:	e85a                	sd	s6,16(sp)
    80003b80:	e45e                	sd	s7,8(sp)
    80003b82:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003b84:	0001d717          	auipc	a4,0x1d
    80003b88:	23072703          	lw	a4,560(a4) # 80020db4 <sb+0xc>
    80003b8c:	4785                	li	a5,1
    80003b8e:	04e7fa63          	bgeu	a5,a4,80003be2 <ialloc+0x74>
    80003b92:	8aaa                	mv	s5,a0
    80003b94:	8bae                	mv	s7,a1
    80003b96:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003b98:	0001da17          	auipc	s4,0x1d
    80003b9c:	210a0a13          	addi	s4,s4,528 # 80020da8 <sb>
    80003ba0:	00048b1b          	sext.w	s6,s1
    80003ba4:	0044d593          	srli	a1,s1,0x4
    80003ba8:	018a2783          	lw	a5,24(s4)
    80003bac:	9dbd                	addw	a1,a1,a5
    80003bae:	8556                	mv	a0,s5
    80003bb0:	00000097          	auipc	ra,0x0
    80003bb4:	956080e7          	jalr	-1706(ra) # 80003506 <bread>
    80003bb8:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003bba:	05850993          	addi	s3,a0,88
    80003bbe:	00f4f793          	andi	a5,s1,15
    80003bc2:	079a                	slli	a5,a5,0x6
    80003bc4:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003bc6:	00099783          	lh	a5,0(s3)
    80003bca:	c785                	beqz	a5,80003bf2 <ialloc+0x84>
    brelse(bp);
    80003bcc:	00000097          	auipc	ra,0x0
    80003bd0:	a6a080e7          	jalr	-1430(ra) # 80003636 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003bd4:	0485                	addi	s1,s1,1
    80003bd6:	00ca2703          	lw	a4,12(s4)
    80003bda:	0004879b          	sext.w	a5,s1
    80003bde:	fce7e1e3          	bltu	a5,a4,80003ba0 <ialloc+0x32>
  panic("ialloc: no inodes");
    80003be2:	00005517          	auipc	a0,0x5
    80003be6:	ace50513          	addi	a0,a0,-1330 # 800086b0 <syscalls+0x180>
    80003bea:	ffffd097          	auipc	ra,0xffffd
    80003bee:	950080e7          	jalr	-1712(ra) # 8000053a <panic>
      memset(dip, 0, sizeof(*dip));
    80003bf2:	04000613          	li	a2,64
    80003bf6:	4581                	li	a1,0
    80003bf8:	854e                	mv	a0,s3
    80003bfa:	ffffd097          	auipc	ra,0xffffd
    80003bfe:	0d2080e7          	jalr	210(ra) # 80000ccc <memset>
      dip->type = type;
    80003c02:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003c06:	854a                	mv	a0,s2
    80003c08:	00001097          	auipc	ra,0x1
    80003c0c:	cb2080e7          	jalr	-846(ra) # 800048ba <log_write>
      brelse(bp);
    80003c10:	854a                	mv	a0,s2
    80003c12:	00000097          	auipc	ra,0x0
    80003c16:	a24080e7          	jalr	-1500(ra) # 80003636 <brelse>
      return iget(dev, inum);
    80003c1a:	85da                	mv	a1,s6
    80003c1c:	8556                	mv	a0,s5
    80003c1e:	00000097          	auipc	ra,0x0
    80003c22:	db4080e7          	jalr	-588(ra) # 800039d2 <iget>
}
    80003c26:	60a6                	ld	ra,72(sp)
    80003c28:	6406                	ld	s0,64(sp)
    80003c2a:	74e2                	ld	s1,56(sp)
    80003c2c:	7942                	ld	s2,48(sp)
    80003c2e:	79a2                	ld	s3,40(sp)
    80003c30:	7a02                	ld	s4,32(sp)
    80003c32:	6ae2                	ld	s5,24(sp)
    80003c34:	6b42                	ld	s6,16(sp)
    80003c36:	6ba2                	ld	s7,8(sp)
    80003c38:	6161                	addi	sp,sp,80
    80003c3a:	8082                	ret

0000000080003c3c <iupdate>:
{
    80003c3c:	1101                	addi	sp,sp,-32
    80003c3e:	ec06                	sd	ra,24(sp)
    80003c40:	e822                	sd	s0,16(sp)
    80003c42:	e426                	sd	s1,8(sp)
    80003c44:	e04a                	sd	s2,0(sp)
    80003c46:	1000                	addi	s0,sp,32
    80003c48:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003c4a:	415c                	lw	a5,4(a0)
    80003c4c:	0047d79b          	srliw	a5,a5,0x4
    80003c50:	0001d597          	auipc	a1,0x1d
    80003c54:	1705a583          	lw	a1,368(a1) # 80020dc0 <sb+0x18>
    80003c58:	9dbd                	addw	a1,a1,a5
    80003c5a:	4108                	lw	a0,0(a0)
    80003c5c:	00000097          	auipc	ra,0x0
    80003c60:	8aa080e7          	jalr	-1878(ra) # 80003506 <bread>
    80003c64:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003c66:	05850793          	addi	a5,a0,88
    80003c6a:	40d8                	lw	a4,4(s1)
    80003c6c:	8b3d                	andi	a4,a4,15
    80003c6e:	071a                	slli	a4,a4,0x6
    80003c70:	97ba                	add	a5,a5,a4
  dip->type = ip->type;
    80003c72:	04449703          	lh	a4,68(s1)
    80003c76:	00e79023          	sh	a4,0(a5)
  dip->major = ip->major;
    80003c7a:	04649703          	lh	a4,70(s1)
    80003c7e:	00e79123          	sh	a4,2(a5)
  dip->minor = ip->minor;
    80003c82:	04849703          	lh	a4,72(s1)
    80003c86:	00e79223          	sh	a4,4(a5)
  dip->nlink = ip->nlink;
    80003c8a:	04a49703          	lh	a4,74(s1)
    80003c8e:	00e79323          	sh	a4,6(a5)
  dip->size = ip->size;
    80003c92:	44f8                	lw	a4,76(s1)
    80003c94:	c798                	sw	a4,8(a5)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003c96:	03400613          	li	a2,52
    80003c9a:	05048593          	addi	a1,s1,80
    80003c9e:	00c78513          	addi	a0,a5,12
    80003ca2:	ffffd097          	auipc	ra,0xffffd
    80003ca6:	086080e7          	jalr	134(ra) # 80000d28 <memmove>
  log_write(bp);
    80003caa:	854a                	mv	a0,s2
    80003cac:	00001097          	auipc	ra,0x1
    80003cb0:	c0e080e7          	jalr	-1010(ra) # 800048ba <log_write>
  brelse(bp);
    80003cb4:	854a                	mv	a0,s2
    80003cb6:	00000097          	auipc	ra,0x0
    80003cba:	980080e7          	jalr	-1664(ra) # 80003636 <brelse>
}
    80003cbe:	60e2                	ld	ra,24(sp)
    80003cc0:	6442                	ld	s0,16(sp)
    80003cc2:	64a2                	ld	s1,8(sp)
    80003cc4:	6902                	ld	s2,0(sp)
    80003cc6:	6105                	addi	sp,sp,32
    80003cc8:	8082                	ret

0000000080003cca <idup>:
{
    80003cca:	1101                	addi	sp,sp,-32
    80003ccc:	ec06                	sd	ra,24(sp)
    80003cce:	e822                	sd	s0,16(sp)
    80003cd0:	e426                	sd	s1,8(sp)
    80003cd2:	1000                	addi	s0,sp,32
    80003cd4:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003cd6:	0001d517          	auipc	a0,0x1d
    80003cda:	0f250513          	addi	a0,a0,242 # 80020dc8 <itable>
    80003cde:	ffffd097          	auipc	ra,0xffffd
    80003ce2:	ef2080e7          	jalr	-270(ra) # 80000bd0 <acquire>
  ip->ref++;
    80003ce6:	449c                	lw	a5,8(s1)
    80003ce8:	2785                	addiw	a5,a5,1
    80003cea:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003cec:	0001d517          	auipc	a0,0x1d
    80003cf0:	0dc50513          	addi	a0,a0,220 # 80020dc8 <itable>
    80003cf4:	ffffd097          	auipc	ra,0xffffd
    80003cf8:	f90080e7          	jalr	-112(ra) # 80000c84 <release>
}
    80003cfc:	8526                	mv	a0,s1
    80003cfe:	60e2                	ld	ra,24(sp)
    80003d00:	6442                	ld	s0,16(sp)
    80003d02:	64a2                	ld	s1,8(sp)
    80003d04:	6105                	addi	sp,sp,32
    80003d06:	8082                	ret

0000000080003d08 <ilock>:
{
    80003d08:	1101                	addi	sp,sp,-32
    80003d0a:	ec06                	sd	ra,24(sp)
    80003d0c:	e822                	sd	s0,16(sp)
    80003d0e:	e426                	sd	s1,8(sp)
    80003d10:	e04a                	sd	s2,0(sp)
    80003d12:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003d14:	c115                	beqz	a0,80003d38 <ilock+0x30>
    80003d16:	84aa                	mv	s1,a0
    80003d18:	451c                	lw	a5,8(a0)
    80003d1a:	00f05f63          	blez	a5,80003d38 <ilock+0x30>
  acquiresleep(&ip->lock);
    80003d1e:	0541                	addi	a0,a0,16
    80003d20:	00001097          	auipc	ra,0x1
    80003d24:	cb8080e7          	jalr	-840(ra) # 800049d8 <acquiresleep>
  if(ip->valid == 0){
    80003d28:	40bc                	lw	a5,64(s1)
    80003d2a:	cf99                	beqz	a5,80003d48 <ilock+0x40>
}
    80003d2c:	60e2                	ld	ra,24(sp)
    80003d2e:	6442                	ld	s0,16(sp)
    80003d30:	64a2                	ld	s1,8(sp)
    80003d32:	6902                	ld	s2,0(sp)
    80003d34:	6105                	addi	sp,sp,32
    80003d36:	8082                	ret
    panic("ilock");
    80003d38:	00005517          	auipc	a0,0x5
    80003d3c:	99050513          	addi	a0,a0,-1648 # 800086c8 <syscalls+0x198>
    80003d40:	ffffc097          	auipc	ra,0xffffc
    80003d44:	7fa080e7          	jalr	2042(ra) # 8000053a <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003d48:	40dc                	lw	a5,4(s1)
    80003d4a:	0047d79b          	srliw	a5,a5,0x4
    80003d4e:	0001d597          	auipc	a1,0x1d
    80003d52:	0725a583          	lw	a1,114(a1) # 80020dc0 <sb+0x18>
    80003d56:	9dbd                	addw	a1,a1,a5
    80003d58:	4088                	lw	a0,0(s1)
    80003d5a:	fffff097          	auipc	ra,0xfffff
    80003d5e:	7ac080e7          	jalr	1964(ra) # 80003506 <bread>
    80003d62:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003d64:	05850593          	addi	a1,a0,88
    80003d68:	40dc                	lw	a5,4(s1)
    80003d6a:	8bbd                	andi	a5,a5,15
    80003d6c:	079a                	slli	a5,a5,0x6
    80003d6e:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003d70:	00059783          	lh	a5,0(a1)
    80003d74:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003d78:	00259783          	lh	a5,2(a1)
    80003d7c:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003d80:	00459783          	lh	a5,4(a1)
    80003d84:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003d88:	00659783          	lh	a5,6(a1)
    80003d8c:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003d90:	459c                	lw	a5,8(a1)
    80003d92:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003d94:	03400613          	li	a2,52
    80003d98:	05b1                	addi	a1,a1,12
    80003d9a:	05048513          	addi	a0,s1,80
    80003d9e:	ffffd097          	auipc	ra,0xffffd
    80003da2:	f8a080e7          	jalr	-118(ra) # 80000d28 <memmove>
    brelse(bp);
    80003da6:	854a                	mv	a0,s2
    80003da8:	00000097          	auipc	ra,0x0
    80003dac:	88e080e7          	jalr	-1906(ra) # 80003636 <brelse>
    ip->valid = 1;
    80003db0:	4785                	li	a5,1
    80003db2:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003db4:	04449783          	lh	a5,68(s1)
    80003db8:	fbb5                	bnez	a5,80003d2c <ilock+0x24>
      panic("ilock: no type");
    80003dba:	00005517          	auipc	a0,0x5
    80003dbe:	91650513          	addi	a0,a0,-1770 # 800086d0 <syscalls+0x1a0>
    80003dc2:	ffffc097          	auipc	ra,0xffffc
    80003dc6:	778080e7          	jalr	1912(ra) # 8000053a <panic>

0000000080003dca <iunlock>:
{
    80003dca:	1101                	addi	sp,sp,-32
    80003dcc:	ec06                	sd	ra,24(sp)
    80003dce:	e822                	sd	s0,16(sp)
    80003dd0:	e426                	sd	s1,8(sp)
    80003dd2:	e04a                	sd	s2,0(sp)
    80003dd4:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003dd6:	c905                	beqz	a0,80003e06 <iunlock+0x3c>
    80003dd8:	84aa                	mv	s1,a0
    80003dda:	01050913          	addi	s2,a0,16
    80003dde:	854a                	mv	a0,s2
    80003de0:	00001097          	auipc	ra,0x1
    80003de4:	c92080e7          	jalr	-878(ra) # 80004a72 <holdingsleep>
    80003de8:	cd19                	beqz	a0,80003e06 <iunlock+0x3c>
    80003dea:	449c                	lw	a5,8(s1)
    80003dec:	00f05d63          	blez	a5,80003e06 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003df0:	854a                	mv	a0,s2
    80003df2:	00001097          	auipc	ra,0x1
    80003df6:	c3c080e7          	jalr	-964(ra) # 80004a2e <releasesleep>
}
    80003dfa:	60e2                	ld	ra,24(sp)
    80003dfc:	6442                	ld	s0,16(sp)
    80003dfe:	64a2                	ld	s1,8(sp)
    80003e00:	6902                	ld	s2,0(sp)
    80003e02:	6105                	addi	sp,sp,32
    80003e04:	8082                	ret
    panic("iunlock");
    80003e06:	00005517          	auipc	a0,0x5
    80003e0a:	8da50513          	addi	a0,a0,-1830 # 800086e0 <syscalls+0x1b0>
    80003e0e:	ffffc097          	auipc	ra,0xffffc
    80003e12:	72c080e7          	jalr	1836(ra) # 8000053a <panic>

0000000080003e16 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003e16:	7179                	addi	sp,sp,-48
    80003e18:	f406                	sd	ra,40(sp)
    80003e1a:	f022                	sd	s0,32(sp)
    80003e1c:	ec26                	sd	s1,24(sp)
    80003e1e:	e84a                	sd	s2,16(sp)
    80003e20:	e44e                	sd	s3,8(sp)
    80003e22:	e052                	sd	s4,0(sp)
    80003e24:	1800                	addi	s0,sp,48
    80003e26:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003e28:	05050493          	addi	s1,a0,80
    80003e2c:	08050913          	addi	s2,a0,128
    80003e30:	a021                	j	80003e38 <itrunc+0x22>
    80003e32:	0491                	addi	s1,s1,4
    80003e34:	01248d63          	beq	s1,s2,80003e4e <itrunc+0x38>
    if(ip->addrs[i]){
    80003e38:	408c                	lw	a1,0(s1)
    80003e3a:	dde5                	beqz	a1,80003e32 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003e3c:	0009a503          	lw	a0,0(s3)
    80003e40:	00000097          	auipc	ra,0x0
    80003e44:	90c080e7          	jalr	-1780(ra) # 8000374c <bfree>
      ip->addrs[i] = 0;
    80003e48:	0004a023          	sw	zero,0(s1)
    80003e4c:	b7dd                	j	80003e32 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003e4e:	0809a583          	lw	a1,128(s3)
    80003e52:	e185                	bnez	a1,80003e72 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003e54:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003e58:	854e                	mv	a0,s3
    80003e5a:	00000097          	auipc	ra,0x0
    80003e5e:	de2080e7          	jalr	-542(ra) # 80003c3c <iupdate>
}
    80003e62:	70a2                	ld	ra,40(sp)
    80003e64:	7402                	ld	s0,32(sp)
    80003e66:	64e2                	ld	s1,24(sp)
    80003e68:	6942                	ld	s2,16(sp)
    80003e6a:	69a2                	ld	s3,8(sp)
    80003e6c:	6a02                	ld	s4,0(sp)
    80003e6e:	6145                	addi	sp,sp,48
    80003e70:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003e72:	0009a503          	lw	a0,0(s3)
    80003e76:	fffff097          	auipc	ra,0xfffff
    80003e7a:	690080e7          	jalr	1680(ra) # 80003506 <bread>
    80003e7e:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003e80:	05850493          	addi	s1,a0,88
    80003e84:	45850913          	addi	s2,a0,1112
    80003e88:	a021                	j	80003e90 <itrunc+0x7a>
    80003e8a:	0491                	addi	s1,s1,4
    80003e8c:	01248b63          	beq	s1,s2,80003ea2 <itrunc+0x8c>
      if(a[j])
    80003e90:	408c                	lw	a1,0(s1)
    80003e92:	dde5                	beqz	a1,80003e8a <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003e94:	0009a503          	lw	a0,0(s3)
    80003e98:	00000097          	auipc	ra,0x0
    80003e9c:	8b4080e7          	jalr	-1868(ra) # 8000374c <bfree>
    80003ea0:	b7ed                	j	80003e8a <itrunc+0x74>
    brelse(bp);
    80003ea2:	8552                	mv	a0,s4
    80003ea4:	fffff097          	auipc	ra,0xfffff
    80003ea8:	792080e7          	jalr	1938(ra) # 80003636 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003eac:	0809a583          	lw	a1,128(s3)
    80003eb0:	0009a503          	lw	a0,0(s3)
    80003eb4:	00000097          	auipc	ra,0x0
    80003eb8:	898080e7          	jalr	-1896(ra) # 8000374c <bfree>
    ip->addrs[NDIRECT] = 0;
    80003ebc:	0809a023          	sw	zero,128(s3)
    80003ec0:	bf51                	j	80003e54 <itrunc+0x3e>

0000000080003ec2 <iput>:
{
    80003ec2:	1101                	addi	sp,sp,-32
    80003ec4:	ec06                	sd	ra,24(sp)
    80003ec6:	e822                	sd	s0,16(sp)
    80003ec8:	e426                	sd	s1,8(sp)
    80003eca:	e04a                	sd	s2,0(sp)
    80003ecc:	1000                	addi	s0,sp,32
    80003ece:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003ed0:	0001d517          	auipc	a0,0x1d
    80003ed4:	ef850513          	addi	a0,a0,-264 # 80020dc8 <itable>
    80003ed8:	ffffd097          	auipc	ra,0xffffd
    80003edc:	cf8080e7          	jalr	-776(ra) # 80000bd0 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003ee0:	4498                	lw	a4,8(s1)
    80003ee2:	4785                	li	a5,1
    80003ee4:	02f70363          	beq	a4,a5,80003f0a <iput+0x48>
  ip->ref--;
    80003ee8:	449c                	lw	a5,8(s1)
    80003eea:	37fd                	addiw	a5,a5,-1
    80003eec:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003eee:	0001d517          	auipc	a0,0x1d
    80003ef2:	eda50513          	addi	a0,a0,-294 # 80020dc8 <itable>
    80003ef6:	ffffd097          	auipc	ra,0xffffd
    80003efa:	d8e080e7          	jalr	-626(ra) # 80000c84 <release>
}
    80003efe:	60e2                	ld	ra,24(sp)
    80003f00:	6442                	ld	s0,16(sp)
    80003f02:	64a2                	ld	s1,8(sp)
    80003f04:	6902                	ld	s2,0(sp)
    80003f06:	6105                	addi	sp,sp,32
    80003f08:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003f0a:	40bc                	lw	a5,64(s1)
    80003f0c:	dff1                	beqz	a5,80003ee8 <iput+0x26>
    80003f0e:	04a49783          	lh	a5,74(s1)
    80003f12:	fbf9                	bnez	a5,80003ee8 <iput+0x26>
    acquiresleep(&ip->lock);
    80003f14:	01048913          	addi	s2,s1,16
    80003f18:	854a                	mv	a0,s2
    80003f1a:	00001097          	auipc	ra,0x1
    80003f1e:	abe080e7          	jalr	-1346(ra) # 800049d8 <acquiresleep>
    release(&itable.lock);
    80003f22:	0001d517          	auipc	a0,0x1d
    80003f26:	ea650513          	addi	a0,a0,-346 # 80020dc8 <itable>
    80003f2a:	ffffd097          	auipc	ra,0xffffd
    80003f2e:	d5a080e7          	jalr	-678(ra) # 80000c84 <release>
    itrunc(ip);
    80003f32:	8526                	mv	a0,s1
    80003f34:	00000097          	auipc	ra,0x0
    80003f38:	ee2080e7          	jalr	-286(ra) # 80003e16 <itrunc>
    ip->type = 0;
    80003f3c:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003f40:	8526                	mv	a0,s1
    80003f42:	00000097          	auipc	ra,0x0
    80003f46:	cfa080e7          	jalr	-774(ra) # 80003c3c <iupdate>
    ip->valid = 0;
    80003f4a:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003f4e:	854a                	mv	a0,s2
    80003f50:	00001097          	auipc	ra,0x1
    80003f54:	ade080e7          	jalr	-1314(ra) # 80004a2e <releasesleep>
    acquire(&itable.lock);
    80003f58:	0001d517          	auipc	a0,0x1d
    80003f5c:	e7050513          	addi	a0,a0,-400 # 80020dc8 <itable>
    80003f60:	ffffd097          	auipc	ra,0xffffd
    80003f64:	c70080e7          	jalr	-912(ra) # 80000bd0 <acquire>
    80003f68:	b741                	j	80003ee8 <iput+0x26>

0000000080003f6a <iunlockput>:
{
    80003f6a:	1101                	addi	sp,sp,-32
    80003f6c:	ec06                	sd	ra,24(sp)
    80003f6e:	e822                	sd	s0,16(sp)
    80003f70:	e426                	sd	s1,8(sp)
    80003f72:	1000                	addi	s0,sp,32
    80003f74:	84aa                	mv	s1,a0
  iunlock(ip);
    80003f76:	00000097          	auipc	ra,0x0
    80003f7a:	e54080e7          	jalr	-428(ra) # 80003dca <iunlock>
  iput(ip);
    80003f7e:	8526                	mv	a0,s1
    80003f80:	00000097          	auipc	ra,0x0
    80003f84:	f42080e7          	jalr	-190(ra) # 80003ec2 <iput>
}
    80003f88:	60e2                	ld	ra,24(sp)
    80003f8a:	6442                	ld	s0,16(sp)
    80003f8c:	64a2                	ld	s1,8(sp)
    80003f8e:	6105                	addi	sp,sp,32
    80003f90:	8082                	ret

0000000080003f92 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003f92:	1141                	addi	sp,sp,-16
    80003f94:	e422                	sd	s0,8(sp)
    80003f96:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003f98:	411c                	lw	a5,0(a0)
    80003f9a:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003f9c:	415c                	lw	a5,4(a0)
    80003f9e:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003fa0:	04451783          	lh	a5,68(a0)
    80003fa4:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003fa8:	04a51783          	lh	a5,74(a0)
    80003fac:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003fb0:	04c56783          	lwu	a5,76(a0)
    80003fb4:	e99c                	sd	a5,16(a1)
}
    80003fb6:	6422                	ld	s0,8(sp)
    80003fb8:	0141                	addi	sp,sp,16
    80003fba:	8082                	ret

0000000080003fbc <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003fbc:	457c                	lw	a5,76(a0)
    80003fbe:	0ed7e963          	bltu	a5,a3,800040b0 <readi+0xf4>
{
    80003fc2:	7159                	addi	sp,sp,-112
    80003fc4:	f486                	sd	ra,104(sp)
    80003fc6:	f0a2                	sd	s0,96(sp)
    80003fc8:	eca6                	sd	s1,88(sp)
    80003fca:	e8ca                	sd	s2,80(sp)
    80003fcc:	e4ce                	sd	s3,72(sp)
    80003fce:	e0d2                	sd	s4,64(sp)
    80003fd0:	fc56                	sd	s5,56(sp)
    80003fd2:	f85a                	sd	s6,48(sp)
    80003fd4:	f45e                	sd	s7,40(sp)
    80003fd6:	f062                	sd	s8,32(sp)
    80003fd8:	ec66                	sd	s9,24(sp)
    80003fda:	e86a                	sd	s10,16(sp)
    80003fdc:	e46e                	sd	s11,8(sp)
    80003fde:	1880                	addi	s0,sp,112
    80003fe0:	8baa                	mv	s7,a0
    80003fe2:	8c2e                	mv	s8,a1
    80003fe4:	8ab2                	mv	s5,a2
    80003fe6:	84b6                	mv	s1,a3
    80003fe8:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003fea:	9f35                	addw	a4,a4,a3
    return 0;
    80003fec:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003fee:	0ad76063          	bltu	a4,a3,8000408e <readi+0xd2>
  if(off + n > ip->size)
    80003ff2:	00e7f463          	bgeu	a5,a4,80003ffa <readi+0x3e>
    n = ip->size - off;
    80003ff6:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003ffa:	0a0b0963          	beqz	s6,800040ac <readi+0xf0>
    80003ffe:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80004000:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80004004:	5cfd                	li	s9,-1
    80004006:	a82d                	j	80004040 <readi+0x84>
    80004008:	020a1d93          	slli	s11,s4,0x20
    8000400c:	020ddd93          	srli	s11,s11,0x20
    80004010:	05890613          	addi	a2,s2,88
    80004014:	86ee                	mv	a3,s11
    80004016:	963a                	add	a2,a2,a4
    80004018:	85d6                	mv	a1,s5
    8000401a:	8562                	mv	a0,s8
    8000401c:	ffffe097          	auipc	ra,0xffffe
    80004020:	7ec080e7          	jalr	2028(ra) # 80002808 <either_copyout>
    80004024:	05950d63          	beq	a0,s9,8000407e <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80004028:	854a                	mv	a0,s2
    8000402a:	fffff097          	auipc	ra,0xfffff
    8000402e:	60c080e7          	jalr	1548(ra) # 80003636 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004032:	013a09bb          	addw	s3,s4,s3
    80004036:	009a04bb          	addw	s1,s4,s1
    8000403a:	9aee                	add	s5,s5,s11
    8000403c:	0569f763          	bgeu	s3,s6,8000408a <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80004040:	000ba903          	lw	s2,0(s7)
    80004044:	00a4d59b          	srliw	a1,s1,0xa
    80004048:	855e                	mv	a0,s7
    8000404a:	00000097          	auipc	ra,0x0
    8000404e:	8ac080e7          	jalr	-1876(ra) # 800038f6 <bmap>
    80004052:	0005059b          	sext.w	a1,a0
    80004056:	854a                	mv	a0,s2
    80004058:	fffff097          	auipc	ra,0xfffff
    8000405c:	4ae080e7          	jalr	1198(ra) # 80003506 <bread>
    80004060:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80004062:	3ff4f713          	andi	a4,s1,1023
    80004066:	40ed07bb          	subw	a5,s10,a4
    8000406a:	413b06bb          	subw	a3,s6,s3
    8000406e:	8a3e                	mv	s4,a5
    80004070:	2781                	sext.w	a5,a5
    80004072:	0006861b          	sext.w	a2,a3
    80004076:	f8f679e3          	bgeu	a2,a5,80004008 <readi+0x4c>
    8000407a:	8a36                	mv	s4,a3
    8000407c:	b771                	j	80004008 <readi+0x4c>
      brelse(bp);
    8000407e:	854a                	mv	a0,s2
    80004080:	fffff097          	auipc	ra,0xfffff
    80004084:	5b6080e7          	jalr	1462(ra) # 80003636 <brelse>
      tot = -1;
    80004088:	59fd                	li	s3,-1
  }
  return tot;
    8000408a:	0009851b          	sext.w	a0,s3
}
    8000408e:	70a6                	ld	ra,104(sp)
    80004090:	7406                	ld	s0,96(sp)
    80004092:	64e6                	ld	s1,88(sp)
    80004094:	6946                	ld	s2,80(sp)
    80004096:	69a6                	ld	s3,72(sp)
    80004098:	6a06                	ld	s4,64(sp)
    8000409a:	7ae2                	ld	s5,56(sp)
    8000409c:	7b42                	ld	s6,48(sp)
    8000409e:	7ba2                	ld	s7,40(sp)
    800040a0:	7c02                	ld	s8,32(sp)
    800040a2:	6ce2                	ld	s9,24(sp)
    800040a4:	6d42                	ld	s10,16(sp)
    800040a6:	6da2                	ld	s11,8(sp)
    800040a8:	6165                	addi	sp,sp,112
    800040aa:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800040ac:	89da                	mv	s3,s6
    800040ae:	bff1                	j	8000408a <readi+0xce>
    return 0;
    800040b0:	4501                	li	a0,0
}
    800040b2:	8082                	ret

00000000800040b4 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    800040b4:	457c                	lw	a5,76(a0)
    800040b6:	10d7e863          	bltu	a5,a3,800041c6 <writei+0x112>
{
    800040ba:	7159                	addi	sp,sp,-112
    800040bc:	f486                	sd	ra,104(sp)
    800040be:	f0a2                	sd	s0,96(sp)
    800040c0:	eca6                	sd	s1,88(sp)
    800040c2:	e8ca                	sd	s2,80(sp)
    800040c4:	e4ce                	sd	s3,72(sp)
    800040c6:	e0d2                	sd	s4,64(sp)
    800040c8:	fc56                	sd	s5,56(sp)
    800040ca:	f85a                	sd	s6,48(sp)
    800040cc:	f45e                	sd	s7,40(sp)
    800040ce:	f062                	sd	s8,32(sp)
    800040d0:	ec66                	sd	s9,24(sp)
    800040d2:	e86a                	sd	s10,16(sp)
    800040d4:	e46e                	sd	s11,8(sp)
    800040d6:	1880                	addi	s0,sp,112
    800040d8:	8b2a                	mv	s6,a0
    800040da:	8c2e                	mv	s8,a1
    800040dc:	8ab2                	mv	s5,a2
    800040de:	8936                	mv	s2,a3
    800040e0:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    800040e2:	00e687bb          	addw	a5,a3,a4
    800040e6:	0ed7e263          	bltu	a5,a3,800041ca <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    800040ea:	00043737          	lui	a4,0x43
    800040ee:	0ef76063          	bltu	a4,a5,800041ce <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800040f2:	0c0b8863          	beqz	s7,800041c2 <writei+0x10e>
    800040f6:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    800040f8:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    800040fc:	5cfd                	li	s9,-1
    800040fe:	a091                	j	80004142 <writei+0x8e>
    80004100:	02099d93          	slli	s11,s3,0x20
    80004104:	020ddd93          	srli	s11,s11,0x20
    80004108:	05848513          	addi	a0,s1,88
    8000410c:	86ee                	mv	a3,s11
    8000410e:	8656                	mv	a2,s5
    80004110:	85e2                	mv	a1,s8
    80004112:	953a                	add	a0,a0,a4
    80004114:	ffffe097          	auipc	ra,0xffffe
    80004118:	74a080e7          	jalr	1866(ra) # 8000285e <either_copyin>
    8000411c:	07950263          	beq	a0,s9,80004180 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80004120:	8526                	mv	a0,s1
    80004122:	00000097          	auipc	ra,0x0
    80004126:	798080e7          	jalr	1944(ra) # 800048ba <log_write>
    brelse(bp);
    8000412a:	8526                	mv	a0,s1
    8000412c:	fffff097          	auipc	ra,0xfffff
    80004130:	50a080e7          	jalr	1290(ra) # 80003636 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004134:	01498a3b          	addw	s4,s3,s4
    80004138:	0129893b          	addw	s2,s3,s2
    8000413c:	9aee                	add	s5,s5,s11
    8000413e:	057a7663          	bgeu	s4,s7,8000418a <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80004142:	000b2483          	lw	s1,0(s6)
    80004146:	00a9559b          	srliw	a1,s2,0xa
    8000414a:	855a                	mv	a0,s6
    8000414c:	fffff097          	auipc	ra,0xfffff
    80004150:	7aa080e7          	jalr	1962(ra) # 800038f6 <bmap>
    80004154:	0005059b          	sext.w	a1,a0
    80004158:	8526                	mv	a0,s1
    8000415a:	fffff097          	auipc	ra,0xfffff
    8000415e:	3ac080e7          	jalr	940(ra) # 80003506 <bread>
    80004162:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80004164:	3ff97713          	andi	a4,s2,1023
    80004168:	40ed07bb          	subw	a5,s10,a4
    8000416c:	414b86bb          	subw	a3,s7,s4
    80004170:	89be                	mv	s3,a5
    80004172:	2781                	sext.w	a5,a5
    80004174:	0006861b          	sext.w	a2,a3
    80004178:	f8f674e3          	bgeu	a2,a5,80004100 <writei+0x4c>
    8000417c:	89b6                	mv	s3,a3
    8000417e:	b749                	j	80004100 <writei+0x4c>
      brelse(bp);
    80004180:	8526                	mv	a0,s1
    80004182:	fffff097          	auipc	ra,0xfffff
    80004186:	4b4080e7          	jalr	1204(ra) # 80003636 <brelse>
  }

  if(off > ip->size)
    8000418a:	04cb2783          	lw	a5,76(s6)
    8000418e:	0127f463          	bgeu	a5,s2,80004196 <writei+0xe2>
    ip->size = off;
    80004192:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80004196:	855a                	mv	a0,s6
    80004198:	00000097          	auipc	ra,0x0
    8000419c:	aa4080e7          	jalr	-1372(ra) # 80003c3c <iupdate>

  return tot;
    800041a0:	000a051b          	sext.w	a0,s4
}
    800041a4:	70a6                	ld	ra,104(sp)
    800041a6:	7406                	ld	s0,96(sp)
    800041a8:	64e6                	ld	s1,88(sp)
    800041aa:	6946                	ld	s2,80(sp)
    800041ac:	69a6                	ld	s3,72(sp)
    800041ae:	6a06                	ld	s4,64(sp)
    800041b0:	7ae2                	ld	s5,56(sp)
    800041b2:	7b42                	ld	s6,48(sp)
    800041b4:	7ba2                	ld	s7,40(sp)
    800041b6:	7c02                	ld	s8,32(sp)
    800041b8:	6ce2                	ld	s9,24(sp)
    800041ba:	6d42                	ld	s10,16(sp)
    800041bc:	6da2                	ld	s11,8(sp)
    800041be:	6165                	addi	sp,sp,112
    800041c0:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800041c2:	8a5e                	mv	s4,s7
    800041c4:	bfc9                	j	80004196 <writei+0xe2>
    return -1;
    800041c6:	557d                	li	a0,-1
}
    800041c8:	8082                	ret
    return -1;
    800041ca:	557d                	li	a0,-1
    800041cc:	bfe1                	j	800041a4 <writei+0xf0>
    return -1;
    800041ce:	557d                	li	a0,-1
    800041d0:	bfd1                	j	800041a4 <writei+0xf0>

00000000800041d2 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    800041d2:	1141                	addi	sp,sp,-16
    800041d4:	e406                	sd	ra,8(sp)
    800041d6:	e022                	sd	s0,0(sp)
    800041d8:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    800041da:	4639                	li	a2,14
    800041dc:	ffffd097          	auipc	ra,0xffffd
    800041e0:	bc0080e7          	jalr	-1088(ra) # 80000d9c <strncmp>
}
    800041e4:	60a2                	ld	ra,8(sp)
    800041e6:	6402                	ld	s0,0(sp)
    800041e8:	0141                	addi	sp,sp,16
    800041ea:	8082                	ret

00000000800041ec <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    800041ec:	7139                	addi	sp,sp,-64
    800041ee:	fc06                	sd	ra,56(sp)
    800041f0:	f822                	sd	s0,48(sp)
    800041f2:	f426                	sd	s1,40(sp)
    800041f4:	f04a                	sd	s2,32(sp)
    800041f6:	ec4e                	sd	s3,24(sp)
    800041f8:	e852                	sd	s4,16(sp)
    800041fa:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    800041fc:	04451703          	lh	a4,68(a0)
    80004200:	4785                	li	a5,1
    80004202:	00f71a63          	bne	a4,a5,80004216 <dirlookup+0x2a>
    80004206:	892a                	mv	s2,a0
    80004208:	89ae                	mv	s3,a1
    8000420a:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    8000420c:	457c                	lw	a5,76(a0)
    8000420e:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80004210:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004212:	e79d                	bnez	a5,80004240 <dirlookup+0x54>
    80004214:	a8a5                	j	8000428c <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80004216:	00004517          	auipc	a0,0x4
    8000421a:	4d250513          	addi	a0,a0,1234 # 800086e8 <syscalls+0x1b8>
    8000421e:	ffffc097          	auipc	ra,0xffffc
    80004222:	31c080e7          	jalr	796(ra) # 8000053a <panic>
      panic("dirlookup read");
    80004226:	00004517          	auipc	a0,0x4
    8000422a:	4da50513          	addi	a0,a0,1242 # 80008700 <syscalls+0x1d0>
    8000422e:	ffffc097          	auipc	ra,0xffffc
    80004232:	30c080e7          	jalr	780(ra) # 8000053a <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004236:	24c1                	addiw	s1,s1,16
    80004238:	04c92783          	lw	a5,76(s2)
    8000423c:	04f4f763          	bgeu	s1,a5,8000428a <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004240:	4741                	li	a4,16
    80004242:	86a6                	mv	a3,s1
    80004244:	fc040613          	addi	a2,s0,-64
    80004248:	4581                	li	a1,0
    8000424a:	854a                	mv	a0,s2
    8000424c:	00000097          	auipc	ra,0x0
    80004250:	d70080e7          	jalr	-656(ra) # 80003fbc <readi>
    80004254:	47c1                	li	a5,16
    80004256:	fcf518e3          	bne	a0,a5,80004226 <dirlookup+0x3a>
    if(de.inum == 0)
    8000425a:	fc045783          	lhu	a5,-64(s0)
    8000425e:	dfe1                	beqz	a5,80004236 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80004260:	fc240593          	addi	a1,s0,-62
    80004264:	854e                	mv	a0,s3
    80004266:	00000097          	auipc	ra,0x0
    8000426a:	f6c080e7          	jalr	-148(ra) # 800041d2 <namecmp>
    8000426e:	f561                	bnez	a0,80004236 <dirlookup+0x4a>
      if(poff)
    80004270:	000a0463          	beqz	s4,80004278 <dirlookup+0x8c>
        *poff = off;
    80004274:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80004278:	fc045583          	lhu	a1,-64(s0)
    8000427c:	00092503          	lw	a0,0(s2)
    80004280:	fffff097          	auipc	ra,0xfffff
    80004284:	752080e7          	jalr	1874(ra) # 800039d2 <iget>
    80004288:	a011                	j	8000428c <dirlookup+0xa0>
  return 0;
    8000428a:	4501                	li	a0,0
}
    8000428c:	70e2                	ld	ra,56(sp)
    8000428e:	7442                	ld	s0,48(sp)
    80004290:	74a2                	ld	s1,40(sp)
    80004292:	7902                	ld	s2,32(sp)
    80004294:	69e2                	ld	s3,24(sp)
    80004296:	6a42                	ld	s4,16(sp)
    80004298:	6121                	addi	sp,sp,64
    8000429a:	8082                	ret

000000008000429c <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    8000429c:	711d                	addi	sp,sp,-96
    8000429e:	ec86                	sd	ra,88(sp)
    800042a0:	e8a2                	sd	s0,80(sp)
    800042a2:	e4a6                	sd	s1,72(sp)
    800042a4:	e0ca                	sd	s2,64(sp)
    800042a6:	fc4e                	sd	s3,56(sp)
    800042a8:	f852                	sd	s4,48(sp)
    800042aa:	f456                	sd	s5,40(sp)
    800042ac:	f05a                	sd	s6,32(sp)
    800042ae:	ec5e                	sd	s7,24(sp)
    800042b0:	e862                	sd	s8,16(sp)
    800042b2:	e466                	sd	s9,8(sp)
    800042b4:	e06a                	sd	s10,0(sp)
    800042b6:	1080                	addi	s0,sp,96
    800042b8:	84aa                	mv	s1,a0
    800042ba:	8b2e                	mv	s6,a1
    800042bc:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    800042be:	00054703          	lbu	a4,0(a0)
    800042c2:	02f00793          	li	a5,47
    800042c6:	02f70363          	beq	a4,a5,800042ec <namex+0x50>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    800042ca:	ffffd097          	auipc	ra,0xffffd
    800042ce:	6cc080e7          	jalr	1740(ra) # 80001996 <myproc>
    800042d2:	15053503          	ld	a0,336(a0)
    800042d6:	00000097          	auipc	ra,0x0
    800042da:	9f4080e7          	jalr	-1548(ra) # 80003cca <idup>
    800042de:	8a2a                	mv	s4,a0
  while(*path == '/')
    800042e0:	02f00913          	li	s2,47
  if(len >= DIRSIZ)
    800042e4:	4cb5                	li	s9,13
  len = path - s;
    800042e6:	4b81                	li	s7,0

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    800042e8:	4c05                	li	s8,1
    800042ea:	a87d                	j	800043a8 <namex+0x10c>
    ip = iget(ROOTDEV, ROOTINO);
    800042ec:	4585                	li	a1,1
    800042ee:	4505                	li	a0,1
    800042f0:	fffff097          	auipc	ra,0xfffff
    800042f4:	6e2080e7          	jalr	1762(ra) # 800039d2 <iget>
    800042f8:	8a2a                	mv	s4,a0
    800042fa:	b7dd                	j	800042e0 <namex+0x44>
      iunlockput(ip);
    800042fc:	8552                	mv	a0,s4
    800042fe:	00000097          	auipc	ra,0x0
    80004302:	c6c080e7          	jalr	-916(ra) # 80003f6a <iunlockput>
      return 0;
    80004306:	4a01                	li	s4,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80004308:	8552                	mv	a0,s4
    8000430a:	60e6                	ld	ra,88(sp)
    8000430c:	6446                	ld	s0,80(sp)
    8000430e:	64a6                	ld	s1,72(sp)
    80004310:	6906                	ld	s2,64(sp)
    80004312:	79e2                	ld	s3,56(sp)
    80004314:	7a42                	ld	s4,48(sp)
    80004316:	7aa2                	ld	s5,40(sp)
    80004318:	7b02                	ld	s6,32(sp)
    8000431a:	6be2                	ld	s7,24(sp)
    8000431c:	6c42                	ld	s8,16(sp)
    8000431e:	6ca2                	ld	s9,8(sp)
    80004320:	6d02                	ld	s10,0(sp)
    80004322:	6125                	addi	sp,sp,96
    80004324:	8082                	ret
      iunlock(ip);
    80004326:	8552                	mv	a0,s4
    80004328:	00000097          	auipc	ra,0x0
    8000432c:	aa2080e7          	jalr	-1374(ra) # 80003dca <iunlock>
      return ip;
    80004330:	bfe1                	j	80004308 <namex+0x6c>
      iunlockput(ip);
    80004332:	8552                	mv	a0,s4
    80004334:	00000097          	auipc	ra,0x0
    80004338:	c36080e7          	jalr	-970(ra) # 80003f6a <iunlockput>
      return 0;
    8000433c:	8a4e                	mv	s4,s3
    8000433e:	b7e9                	j	80004308 <namex+0x6c>
  len = path - s;
    80004340:	40998633          	sub	a2,s3,s1
    80004344:	00060d1b          	sext.w	s10,a2
  if(len >= DIRSIZ)
    80004348:	09acd863          	bge	s9,s10,800043d8 <namex+0x13c>
    memmove(name, s, DIRSIZ);
    8000434c:	4639                	li	a2,14
    8000434e:	85a6                	mv	a1,s1
    80004350:	8556                	mv	a0,s5
    80004352:	ffffd097          	auipc	ra,0xffffd
    80004356:	9d6080e7          	jalr	-1578(ra) # 80000d28 <memmove>
    8000435a:	84ce                	mv	s1,s3
  while(*path == '/')
    8000435c:	0004c783          	lbu	a5,0(s1)
    80004360:	01279763          	bne	a5,s2,8000436e <namex+0xd2>
    path++;
    80004364:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004366:	0004c783          	lbu	a5,0(s1)
    8000436a:	ff278de3          	beq	a5,s2,80004364 <namex+0xc8>
    ilock(ip);
    8000436e:	8552                	mv	a0,s4
    80004370:	00000097          	auipc	ra,0x0
    80004374:	998080e7          	jalr	-1640(ra) # 80003d08 <ilock>
    if(ip->type != T_DIR){
    80004378:	044a1783          	lh	a5,68(s4)
    8000437c:	f98790e3          	bne	a5,s8,800042fc <namex+0x60>
    if(nameiparent && *path == '\0'){
    80004380:	000b0563          	beqz	s6,8000438a <namex+0xee>
    80004384:	0004c783          	lbu	a5,0(s1)
    80004388:	dfd9                	beqz	a5,80004326 <namex+0x8a>
    if((next = dirlookup(ip, name, 0)) == 0){
    8000438a:	865e                	mv	a2,s7
    8000438c:	85d6                	mv	a1,s5
    8000438e:	8552                	mv	a0,s4
    80004390:	00000097          	auipc	ra,0x0
    80004394:	e5c080e7          	jalr	-420(ra) # 800041ec <dirlookup>
    80004398:	89aa                	mv	s3,a0
    8000439a:	dd41                	beqz	a0,80004332 <namex+0x96>
    iunlockput(ip);
    8000439c:	8552                	mv	a0,s4
    8000439e:	00000097          	auipc	ra,0x0
    800043a2:	bcc080e7          	jalr	-1076(ra) # 80003f6a <iunlockput>
    ip = next;
    800043a6:	8a4e                	mv	s4,s3
  while(*path == '/')
    800043a8:	0004c783          	lbu	a5,0(s1)
    800043ac:	01279763          	bne	a5,s2,800043ba <namex+0x11e>
    path++;
    800043b0:	0485                	addi	s1,s1,1
  while(*path == '/')
    800043b2:	0004c783          	lbu	a5,0(s1)
    800043b6:	ff278de3          	beq	a5,s2,800043b0 <namex+0x114>
  if(*path == 0)
    800043ba:	cb9d                	beqz	a5,800043f0 <namex+0x154>
  while(*path != '/' && *path != 0)
    800043bc:	0004c783          	lbu	a5,0(s1)
    800043c0:	89a6                	mv	s3,s1
  len = path - s;
    800043c2:	8d5e                	mv	s10,s7
    800043c4:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    800043c6:	01278963          	beq	a5,s2,800043d8 <namex+0x13c>
    800043ca:	dbbd                	beqz	a5,80004340 <namex+0xa4>
    path++;
    800043cc:	0985                	addi	s3,s3,1
  while(*path != '/' && *path != 0)
    800043ce:	0009c783          	lbu	a5,0(s3)
    800043d2:	ff279ce3          	bne	a5,s2,800043ca <namex+0x12e>
    800043d6:	b7ad                	j	80004340 <namex+0xa4>
    memmove(name, s, len);
    800043d8:	2601                	sext.w	a2,a2
    800043da:	85a6                	mv	a1,s1
    800043dc:	8556                	mv	a0,s5
    800043de:	ffffd097          	auipc	ra,0xffffd
    800043e2:	94a080e7          	jalr	-1718(ra) # 80000d28 <memmove>
    name[len] = 0;
    800043e6:	9d56                	add	s10,s10,s5
    800043e8:	000d0023          	sb	zero,0(s10)
    800043ec:	84ce                	mv	s1,s3
    800043ee:	b7bd                	j	8000435c <namex+0xc0>
  if(nameiparent){
    800043f0:	f00b0ce3          	beqz	s6,80004308 <namex+0x6c>
    iput(ip);
    800043f4:	8552                	mv	a0,s4
    800043f6:	00000097          	auipc	ra,0x0
    800043fa:	acc080e7          	jalr	-1332(ra) # 80003ec2 <iput>
    return 0;
    800043fe:	4a01                	li	s4,0
    80004400:	b721                	j	80004308 <namex+0x6c>

0000000080004402 <dirlink>:
{
    80004402:	7139                	addi	sp,sp,-64
    80004404:	fc06                	sd	ra,56(sp)
    80004406:	f822                	sd	s0,48(sp)
    80004408:	f426                	sd	s1,40(sp)
    8000440a:	f04a                	sd	s2,32(sp)
    8000440c:	ec4e                	sd	s3,24(sp)
    8000440e:	e852                	sd	s4,16(sp)
    80004410:	0080                	addi	s0,sp,64
    80004412:	892a                	mv	s2,a0
    80004414:	8a2e                	mv	s4,a1
    80004416:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80004418:	4601                	li	a2,0
    8000441a:	00000097          	auipc	ra,0x0
    8000441e:	dd2080e7          	jalr	-558(ra) # 800041ec <dirlookup>
    80004422:	e93d                	bnez	a0,80004498 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004424:	04c92483          	lw	s1,76(s2)
    80004428:	c49d                	beqz	s1,80004456 <dirlink+0x54>
    8000442a:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000442c:	4741                	li	a4,16
    8000442e:	86a6                	mv	a3,s1
    80004430:	fc040613          	addi	a2,s0,-64
    80004434:	4581                	li	a1,0
    80004436:	854a                	mv	a0,s2
    80004438:	00000097          	auipc	ra,0x0
    8000443c:	b84080e7          	jalr	-1148(ra) # 80003fbc <readi>
    80004440:	47c1                	li	a5,16
    80004442:	06f51163          	bne	a0,a5,800044a4 <dirlink+0xa2>
    if(de.inum == 0)
    80004446:	fc045783          	lhu	a5,-64(s0)
    8000444a:	c791                	beqz	a5,80004456 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000444c:	24c1                	addiw	s1,s1,16
    8000444e:	04c92783          	lw	a5,76(s2)
    80004452:	fcf4ede3          	bltu	s1,a5,8000442c <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80004456:	4639                	li	a2,14
    80004458:	85d2                	mv	a1,s4
    8000445a:	fc240513          	addi	a0,s0,-62
    8000445e:	ffffd097          	auipc	ra,0xffffd
    80004462:	97a080e7          	jalr	-1670(ra) # 80000dd8 <strncpy>
  de.inum = inum;
    80004466:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000446a:	4741                	li	a4,16
    8000446c:	86a6                	mv	a3,s1
    8000446e:	fc040613          	addi	a2,s0,-64
    80004472:	4581                	li	a1,0
    80004474:	854a                	mv	a0,s2
    80004476:	00000097          	auipc	ra,0x0
    8000447a:	c3e080e7          	jalr	-962(ra) # 800040b4 <writei>
    8000447e:	872a                	mv	a4,a0
    80004480:	47c1                	li	a5,16
  return 0;
    80004482:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004484:	02f71863          	bne	a4,a5,800044b4 <dirlink+0xb2>
}
    80004488:	70e2                	ld	ra,56(sp)
    8000448a:	7442                	ld	s0,48(sp)
    8000448c:	74a2                	ld	s1,40(sp)
    8000448e:	7902                	ld	s2,32(sp)
    80004490:	69e2                	ld	s3,24(sp)
    80004492:	6a42                	ld	s4,16(sp)
    80004494:	6121                	addi	sp,sp,64
    80004496:	8082                	ret
    iput(ip);
    80004498:	00000097          	auipc	ra,0x0
    8000449c:	a2a080e7          	jalr	-1494(ra) # 80003ec2 <iput>
    return -1;
    800044a0:	557d                	li	a0,-1
    800044a2:	b7dd                	j	80004488 <dirlink+0x86>
      panic("dirlink read");
    800044a4:	00004517          	auipc	a0,0x4
    800044a8:	26c50513          	addi	a0,a0,620 # 80008710 <syscalls+0x1e0>
    800044ac:	ffffc097          	auipc	ra,0xffffc
    800044b0:	08e080e7          	jalr	142(ra) # 8000053a <panic>
    panic("dirlink");
    800044b4:	00004517          	auipc	a0,0x4
    800044b8:	36450513          	addi	a0,a0,868 # 80008818 <syscalls+0x2e8>
    800044bc:	ffffc097          	auipc	ra,0xffffc
    800044c0:	07e080e7          	jalr	126(ra) # 8000053a <panic>

00000000800044c4 <namei>:

struct inode*
namei(char *path)
{
    800044c4:	1101                	addi	sp,sp,-32
    800044c6:	ec06                	sd	ra,24(sp)
    800044c8:	e822                	sd	s0,16(sp)
    800044ca:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    800044cc:	fe040613          	addi	a2,s0,-32
    800044d0:	4581                	li	a1,0
    800044d2:	00000097          	auipc	ra,0x0
    800044d6:	dca080e7          	jalr	-566(ra) # 8000429c <namex>
}
    800044da:	60e2                	ld	ra,24(sp)
    800044dc:	6442                	ld	s0,16(sp)
    800044de:	6105                	addi	sp,sp,32
    800044e0:	8082                	ret

00000000800044e2 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    800044e2:	1141                	addi	sp,sp,-16
    800044e4:	e406                	sd	ra,8(sp)
    800044e6:	e022                	sd	s0,0(sp)
    800044e8:	0800                	addi	s0,sp,16
    800044ea:	862e                	mv	a2,a1
  return namex(path, 1, name);
    800044ec:	4585                	li	a1,1
    800044ee:	00000097          	auipc	ra,0x0
    800044f2:	dae080e7          	jalr	-594(ra) # 8000429c <namex>
}
    800044f6:	60a2                	ld	ra,8(sp)
    800044f8:	6402                	ld	s0,0(sp)
    800044fa:	0141                	addi	sp,sp,16
    800044fc:	8082                	ret

00000000800044fe <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    800044fe:	1101                	addi	sp,sp,-32
    80004500:	ec06                	sd	ra,24(sp)
    80004502:	e822                	sd	s0,16(sp)
    80004504:	e426                	sd	s1,8(sp)
    80004506:	e04a                	sd	s2,0(sp)
    80004508:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    8000450a:	0001e917          	auipc	s2,0x1e
    8000450e:	36690913          	addi	s2,s2,870 # 80022870 <log>
    80004512:	01892583          	lw	a1,24(s2)
    80004516:	02892503          	lw	a0,40(s2)
    8000451a:	fffff097          	auipc	ra,0xfffff
    8000451e:	fec080e7          	jalr	-20(ra) # 80003506 <bread>
    80004522:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004524:	02c92683          	lw	a3,44(s2)
    80004528:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    8000452a:	02d05863          	blez	a3,8000455a <write_head+0x5c>
    8000452e:	0001e797          	auipc	a5,0x1e
    80004532:	37278793          	addi	a5,a5,882 # 800228a0 <log+0x30>
    80004536:	05c50713          	addi	a4,a0,92
    8000453a:	36fd                	addiw	a3,a3,-1
    8000453c:	02069613          	slli	a2,a3,0x20
    80004540:	01e65693          	srli	a3,a2,0x1e
    80004544:	0001e617          	auipc	a2,0x1e
    80004548:	36060613          	addi	a2,a2,864 # 800228a4 <log+0x34>
    8000454c:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    8000454e:	4390                	lw	a2,0(a5)
    80004550:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004552:	0791                	addi	a5,a5,4
    80004554:	0711                	addi	a4,a4,4
    80004556:	fed79ce3          	bne	a5,a3,8000454e <write_head+0x50>
  }
  bwrite(buf);
    8000455a:	8526                	mv	a0,s1
    8000455c:	fffff097          	auipc	ra,0xfffff
    80004560:	09c080e7          	jalr	156(ra) # 800035f8 <bwrite>
  brelse(buf);
    80004564:	8526                	mv	a0,s1
    80004566:	fffff097          	auipc	ra,0xfffff
    8000456a:	0d0080e7          	jalr	208(ra) # 80003636 <brelse>
}
    8000456e:	60e2                	ld	ra,24(sp)
    80004570:	6442                	ld	s0,16(sp)
    80004572:	64a2                	ld	s1,8(sp)
    80004574:	6902                	ld	s2,0(sp)
    80004576:	6105                	addi	sp,sp,32
    80004578:	8082                	ret

000000008000457a <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    8000457a:	0001e797          	auipc	a5,0x1e
    8000457e:	3227a783          	lw	a5,802(a5) # 8002289c <log+0x2c>
    80004582:	0af05d63          	blez	a5,8000463c <install_trans+0xc2>
{
    80004586:	7139                	addi	sp,sp,-64
    80004588:	fc06                	sd	ra,56(sp)
    8000458a:	f822                	sd	s0,48(sp)
    8000458c:	f426                	sd	s1,40(sp)
    8000458e:	f04a                	sd	s2,32(sp)
    80004590:	ec4e                	sd	s3,24(sp)
    80004592:	e852                	sd	s4,16(sp)
    80004594:	e456                	sd	s5,8(sp)
    80004596:	e05a                	sd	s6,0(sp)
    80004598:	0080                	addi	s0,sp,64
    8000459a:	8b2a                	mv	s6,a0
    8000459c:	0001ea97          	auipc	s5,0x1e
    800045a0:	304a8a93          	addi	s5,s5,772 # 800228a0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    800045a4:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800045a6:	0001e997          	auipc	s3,0x1e
    800045aa:	2ca98993          	addi	s3,s3,714 # 80022870 <log>
    800045ae:	a00d                	j	800045d0 <install_trans+0x56>
    brelse(lbuf);
    800045b0:	854a                	mv	a0,s2
    800045b2:	fffff097          	auipc	ra,0xfffff
    800045b6:	084080e7          	jalr	132(ra) # 80003636 <brelse>
    brelse(dbuf);
    800045ba:	8526                	mv	a0,s1
    800045bc:	fffff097          	auipc	ra,0xfffff
    800045c0:	07a080e7          	jalr	122(ra) # 80003636 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800045c4:	2a05                	addiw	s4,s4,1
    800045c6:	0a91                	addi	s5,s5,4
    800045c8:	02c9a783          	lw	a5,44(s3)
    800045cc:	04fa5e63          	bge	s4,a5,80004628 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800045d0:	0189a583          	lw	a1,24(s3)
    800045d4:	014585bb          	addw	a1,a1,s4
    800045d8:	2585                	addiw	a1,a1,1
    800045da:	0289a503          	lw	a0,40(s3)
    800045de:	fffff097          	auipc	ra,0xfffff
    800045e2:	f28080e7          	jalr	-216(ra) # 80003506 <bread>
    800045e6:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    800045e8:	000aa583          	lw	a1,0(s5)
    800045ec:	0289a503          	lw	a0,40(s3)
    800045f0:	fffff097          	auipc	ra,0xfffff
    800045f4:	f16080e7          	jalr	-234(ra) # 80003506 <bread>
    800045f8:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    800045fa:	40000613          	li	a2,1024
    800045fe:	05890593          	addi	a1,s2,88
    80004602:	05850513          	addi	a0,a0,88
    80004606:	ffffc097          	auipc	ra,0xffffc
    8000460a:	722080e7          	jalr	1826(ra) # 80000d28 <memmove>
    bwrite(dbuf);  // write dst to disk
    8000460e:	8526                	mv	a0,s1
    80004610:	fffff097          	auipc	ra,0xfffff
    80004614:	fe8080e7          	jalr	-24(ra) # 800035f8 <bwrite>
    if(recovering == 0)
    80004618:	f80b1ce3          	bnez	s6,800045b0 <install_trans+0x36>
      bunpin(dbuf);
    8000461c:	8526                	mv	a0,s1
    8000461e:	fffff097          	auipc	ra,0xfffff
    80004622:	0f2080e7          	jalr	242(ra) # 80003710 <bunpin>
    80004626:	b769                	j	800045b0 <install_trans+0x36>
}
    80004628:	70e2                	ld	ra,56(sp)
    8000462a:	7442                	ld	s0,48(sp)
    8000462c:	74a2                	ld	s1,40(sp)
    8000462e:	7902                	ld	s2,32(sp)
    80004630:	69e2                	ld	s3,24(sp)
    80004632:	6a42                	ld	s4,16(sp)
    80004634:	6aa2                	ld	s5,8(sp)
    80004636:	6b02                	ld	s6,0(sp)
    80004638:	6121                	addi	sp,sp,64
    8000463a:	8082                	ret
    8000463c:	8082                	ret

000000008000463e <initlog>:
{
    8000463e:	7179                	addi	sp,sp,-48
    80004640:	f406                	sd	ra,40(sp)
    80004642:	f022                	sd	s0,32(sp)
    80004644:	ec26                	sd	s1,24(sp)
    80004646:	e84a                	sd	s2,16(sp)
    80004648:	e44e                	sd	s3,8(sp)
    8000464a:	1800                	addi	s0,sp,48
    8000464c:	892a                	mv	s2,a0
    8000464e:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004650:	0001e497          	auipc	s1,0x1e
    80004654:	22048493          	addi	s1,s1,544 # 80022870 <log>
    80004658:	00004597          	auipc	a1,0x4
    8000465c:	0c858593          	addi	a1,a1,200 # 80008720 <syscalls+0x1f0>
    80004660:	8526                	mv	a0,s1
    80004662:	ffffc097          	auipc	ra,0xffffc
    80004666:	4de080e7          	jalr	1246(ra) # 80000b40 <initlock>
  log.start = sb->logstart;
    8000466a:	0149a583          	lw	a1,20(s3)
    8000466e:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004670:	0109a783          	lw	a5,16(s3)
    80004674:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004676:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    8000467a:	854a                	mv	a0,s2
    8000467c:	fffff097          	auipc	ra,0xfffff
    80004680:	e8a080e7          	jalr	-374(ra) # 80003506 <bread>
  log.lh.n = lh->n;
    80004684:	4d34                	lw	a3,88(a0)
    80004686:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004688:	02d05663          	blez	a3,800046b4 <initlog+0x76>
    8000468c:	05c50793          	addi	a5,a0,92
    80004690:	0001e717          	auipc	a4,0x1e
    80004694:	21070713          	addi	a4,a4,528 # 800228a0 <log+0x30>
    80004698:	36fd                	addiw	a3,a3,-1
    8000469a:	02069613          	slli	a2,a3,0x20
    8000469e:	01e65693          	srli	a3,a2,0x1e
    800046a2:	06050613          	addi	a2,a0,96
    800046a6:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    800046a8:	4390                	lw	a2,0(a5)
    800046aa:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800046ac:	0791                	addi	a5,a5,4
    800046ae:	0711                	addi	a4,a4,4
    800046b0:	fed79ce3          	bne	a5,a3,800046a8 <initlog+0x6a>
  brelse(buf);
    800046b4:	fffff097          	auipc	ra,0xfffff
    800046b8:	f82080e7          	jalr	-126(ra) # 80003636 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    800046bc:	4505                	li	a0,1
    800046be:	00000097          	auipc	ra,0x0
    800046c2:	ebc080e7          	jalr	-324(ra) # 8000457a <install_trans>
  log.lh.n = 0;
    800046c6:	0001e797          	auipc	a5,0x1e
    800046ca:	1c07ab23          	sw	zero,470(a5) # 8002289c <log+0x2c>
  write_head(); // clear the log
    800046ce:	00000097          	auipc	ra,0x0
    800046d2:	e30080e7          	jalr	-464(ra) # 800044fe <write_head>
}
    800046d6:	70a2                	ld	ra,40(sp)
    800046d8:	7402                	ld	s0,32(sp)
    800046da:	64e2                	ld	s1,24(sp)
    800046dc:	6942                	ld	s2,16(sp)
    800046de:	69a2                	ld	s3,8(sp)
    800046e0:	6145                	addi	sp,sp,48
    800046e2:	8082                	ret

00000000800046e4 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    800046e4:	1101                	addi	sp,sp,-32
    800046e6:	ec06                	sd	ra,24(sp)
    800046e8:	e822                	sd	s0,16(sp)
    800046ea:	e426                	sd	s1,8(sp)
    800046ec:	e04a                	sd	s2,0(sp)
    800046ee:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    800046f0:	0001e517          	auipc	a0,0x1e
    800046f4:	18050513          	addi	a0,a0,384 # 80022870 <log>
    800046f8:	ffffc097          	auipc	ra,0xffffc
    800046fc:	4d8080e7          	jalr	1240(ra) # 80000bd0 <acquire>
  while(1){
    if(log.committing){
    80004700:	0001e497          	auipc	s1,0x1e
    80004704:	17048493          	addi	s1,s1,368 # 80022870 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004708:	4979                	li	s2,30
    8000470a:	a039                	j	80004718 <begin_op+0x34>
      sleep(&log, &log.lock);
    8000470c:	85a6                	mv	a1,s1
    8000470e:	8526                	mv	a0,s1
    80004710:	ffffe097          	auipc	ra,0xffffe
    80004714:	bcc080e7          	jalr	-1076(ra) # 800022dc <sleep>
    if(log.committing){
    80004718:	50dc                	lw	a5,36(s1)
    8000471a:	fbed                	bnez	a5,8000470c <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000471c:	5098                	lw	a4,32(s1)
    8000471e:	2705                	addiw	a4,a4,1
    80004720:	0007069b          	sext.w	a3,a4
    80004724:	0027179b          	slliw	a5,a4,0x2
    80004728:	9fb9                	addw	a5,a5,a4
    8000472a:	0017979b          	slliw	a5,a5,0x1
    8000472e:	54d8                	lw	a4,44(s1)
    80004730:	9fb9                	addw	a5,a5,a4
    80004732:	00f95963          	bge	s2,a5,80004744 <begin_op+0x60>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004736:	85a6                	mv	a1,s1
    80004738:	8526                	mv	a0,s1
    8000473a:	ffffe097          	auipc	ra,0xffffe
    8000473e:	ba2080e7          	jalr	-1118(ra) # 800022dc <sleep>
    80004742:	bfd9                	j	80004718 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004744:	0001e517          	auipc	a0,0x1e
    80004748:	12c50513          	addi	a0,a0,300 # 80022870 <log>
    8000474c:	d114                	sw	a3,32(a0)
      release(&log.lock);
    8000474e:	ffffc097          	auipc	ra,0xffffc
    80004752:	536080e7          	jalr	1334(ra) # 80000c84 <release>
      break;
    }
  }
}
    80004756:	60e2                	ld	ra,24(sp)
    80004758:	6442                	ld	s0,16(sp)
    8000475a:	64a2                	ld	s1,8(sp)
    8000475c:	6902                	ld	s2,0(sp)
    8000475e:	6105                	addi	sp,sp,32
    80004760:	8082                	ret

0000000080004762 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004762:	7139                	addi	sp,sp,-64
    80004764:	fc06                	sd	ra,56(sp)
    80004766:	f822                	sd	s0,48(sp)
    80004768:	f426                	sd	s1,40(sp)
    8000476a:	f04a                	sd	s2,32(sp)
    8000476c:	ec4e                	sd	s3,24(sp)
    8000476e:	e852                	sd	s4,16(sp)
    80004770:	e456                	sd	s5,8(sp)
    80004772:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004774:	0001e497          	auipc	s1,0x1e
    80004778:	0fc48493          	addi	s1,s1,252 # 80022870 <log>
    8000477c:	8526                	mv	a0,s1
    8000477e:	ffffc097          	auipc	ra,0xffffc
    80004782:	452080e7          	jalr	1106(ra) # 80000bd0 <acquire>
  log.outstanding -= 1;
    80004786:	509c                	lw	a5,32(s1)
    80004788:	37fd                	addiw	a5,a5,-1
    8000478a:	0007891b          	sext.w	s2,a5
    8000478e:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004790:	50dc                	lw	a5,36(s1)
    80004792:	e7b9                	bnez	a5,800047e0 <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004794:	04091e63          	bnez	s2,800047f0 <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    80004798:	0001e497          	auipc	s1,0x1e
    8000479c:	0d848493          	addi	s1,s1,216 # 80022870 <log>
    800047a0:	4785                	li	a5,1
    800047a2:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800047a4:	8526                	mv	a0,s1
    800047a6:	ffffc097          	auipc	ra,0xffffc
    800047aa:	4de080e7          	jalr	1246(ra) # 80000c84 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800047ae:	54dc                	lw	a5,44(s1)
    800047b0:	06f04763          	bgtz	a5,8000481e <end_op+0xbc>
    acquire(&log.lock);
    800047b4:	0001e497          	auipc	s1,0x1e
    800047b8:	0bc48493          	addi	s1,s1,188 # 80022870 <log>
    800047bc:	8526                	mv	a0,s1
    800047be:	ffffc097          	auipc	ra,0xffffc
    800047c2:	412080e7          	jalr	1042(ra) # 80000bd0 <acquire>
    log.committing = 0;
    800047c6:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800047ca:	8526                	mv	a0,s1
    800047cc:	ffffe097          	auipc	ra,0xffffe
    800047d0:	df8080e7          	jalr	-520(ra) # 800025c4 <wakeup>
    release(&log.lock);
    800047d4:	8526                	mv	a0,s1
    800047d6:	ffffc097          	auipc	ra,0xffffc
    800047da:	4ae080e7          	jalr	1198(ra) # 80000c84 <release>
}
    800047de:	a03d                	j	8000480c <end_op+0xaa>
    panic("log.committing");
    800047e0:	00004517          	auipc	a0,0x4
    800047e4:	f4850513          	addi	a0,a0,-184 # 80008728 <syscalls+0x1f8>
    800047e8:	ffffc097          	auipc	ra,0xffffc
    800047ec:	d52080e7          	jalr	-686(ra) # 8000053a <panic>
    wakeup(&log);
    800047f0:	0001e497          	auipc	s1,0x1e
    800047f4:	08048493          	addi	s1,s1,128 # 80022870 <log>
    800047f8:	8526                	mv	a0,s1
    800047fa:	ffffe097          	auipc	ra,0xffffe
    800047fe:	dca080e7          	jalr	-566(ra) # 800025c4 <wakeup>
  release(&log.lock);
    80004802:	8526                	mv	a0,s1
    80004804:	ffffc097          	auipc	ra,0xffffc
    80004808:	480080e7          	jalr	1152(ra) # 80000c84 <release>
}
    8000480c:	70e2                	ld	ra,56(sp)
    8000480e:	7442                	ld	s0,48(sp)
    80004810:	74a2                	ld	s1,40(sp)
    80004812:	7902                	ld	s2,32(sp)
    80004814:	69e2                	ld	s3,24(sp)
    80004816:	6a42                	ld	s4,16(sp)
    80004818:	6aa2                	ld	s5,8(sp)
    8000481a:	6121                	addi	sp,sp,64
    8000481c:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    8000481e:	0001ea97          	auipc	s5,0x1e
    80004822:	082a8a93          	addi	s5,s5,130 # 800228a0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004826:	0001ea17          	auipc	s4,0x1e
    8000482a:	04aa0a13          	addi	s4,s4,74 # 80022870 <log>
    8000482e:	018a2583          	lw	a1,24(s4)
    80004832:	012585bb          	addw	a1,a1,s2
    80004836:	2585                	addiw	a1,a1,1
    80004838:	028a2503          	lw	a0,40(s4)
    8000483c:	fffff097          	auipc	ra,0xfffff
    80004840:	cca080e7          	jalr	-822(ra) # 80003506 <bread>
    80004844:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004846:	000aa583          	lw	a1,0(s5)
    8000484a:	028a2503          	lw	a0,40(s4)
    8000484e:	fffff097          	auipc	ra,0xfffff
    80004852:	cb8080e7          	jalr	-840(ra) # 80003506 <bread>
    80004856:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004858:	40000613          	li	a2,1024
    8000485c:	05850593          	addi	a1,a0,88
    80004860:	05848513          	addi	a0,s1,88
    80004864:	ffffc097          	auipc	ra,0xffffc
    80004868:	4c4080e7          	jalr	1220(ra) # 80000d28 <memmove>
    bwrite(to);  // write the log
    8000486c:	8526                	mv	a0,s1
    8000486e:	fffff097          	auipc	ra,0xfffff
    80004872:	d8a080e7          	jalr	-630(ra) # 800035f8 <bwrite>
    brelse(from);
    80004876:	854e                	mv	a0,s3
    80004878:	fffff097          	auipc	ra,0xfffff
    8000487c:	dbe080e7          	jalr	-578(ra) # 80003636 <brelse>
    brelse(to);
    80004880:	8526                	mv	a0,s1
    80004882:	fffff097          	auipc	ra,0xfffff
    80004886:	db4080e7          	jalr	-588(ra) # 80003636 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000488a:	2905                	addiw	s2,s2,1
    8000488c:	0a91                	addi	s5,s5,4
    8000488e:	02ca2783          	lw	a5,44(s4)
    80004892:	f8f94ee3          	blt	s2,a5,8000482e <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004896:	00000097          	auipc	ra,0x0
    8000489a:	c68080e7          	jalr	-920(ra) # 800044fe <write_head>
    install_trans(0); // Now install writes to home locations
    8000489e:	4501                	li	a0,0
    800048a0:	00000097          	auipc	ra,0x0
    800048a4:	cda080e7          	jalr	-806(ra) # 8000457a <install_trans>
    log.lh.n = 0;
    800048a8:	0001e797          	auipc	a5,0x1e
    800048ac:	fe07aa23          	sw	zero,-12(a5) # 8002289c <log+0x2c>
    write_head();    // Erase the transaction from the log
    800048b0:	00000097          	auipc	ra,0x0
    800048b4:	c4e080e7          	jalr	-946(ra) # 800044fe <write_head>
    800048b8:	bdf5                	j	800047b4 <end_op+0x52>

00000000800048ba <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800048ba:	1101                	addi	sp,sp,-32
    800048bc:	ec06                	sd	ra,24(sp)
    800048be:	e822                	sd	s0,16(sp)
    800048c0:	e426                	sd	s1,8(sp)
    800048c2:	e04a                	sd	s2,0(sp)
    800048c4:	1000                	addi	s0,sp,32
    800048c6:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    800048c8:	0001e917          	auipc	s2,0x1e
    800048cc:	fa890913          	addi	s2,s2,-88 # 80022870 <log>
    800048d0:	854a                	mv	a0,s2
    800048d2:	ffffc097          	auipc	ra,0xffffc
    800048d6:	2fe080e7          	jalr	766(ra) # 80000bd0 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800048da:	02c92603          	lw	a2,44(s2)
    800048de:	47f5                	li	a5,29
    800048e0:	06c7c563          	blt	a5,a2,8000494a <log_write+0x90>
    800048e4:	0001e797          	auipc	a5,0x1e
    800048e8:	fa87a783          	lw	a5,-88(a5) # 8002288c <log+0x1c>
    800048ec:	37fd                	addiw	a5,a5,-1
    800048ee:	04f65e63          	bge	a2,a5,8000494a <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800048f2:	0001e797          	auipc	a5,0x1e
    800048f6:	f9e7a783          	lw	a5,-98(a5) # 80022890 <log+0x20>
    800048fa:	06f05063          	blez	a5,8000495a <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    800048fe:	4781                	li	a5,0
    80004900:	06c05563          	blez	a2,8000496a <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004904:	44cc                	lw	a1,12(s1)
    80004906:	0001e717          	auipc	a4,0x1e
    8000490a:	f9a70713          	addi	a4,a4,-102 # 800228a0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    8000490e:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004910:	4314                	lw	a3,0(a4)
    80004912:	04b68c63          	beq	a3,a1,8000496a <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004916:	2785                	addiw	a5,a5,1
    80004918:	0711                	addi	a4,a4,4
    8000491a:	fef61be3          	bne	a2,a5,80004910 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    8000491e:	0621                	addi	a2,a2,8
    80004920:	060a                	slli	a2,a2,0x2
    80004922:	0001e797          	auipc	a5,0x1e
    80004926:	f4e78793          	addi	a5,a5,-178 # 80022870 <log>
    8000492a:	97b2                	add	a5,a5,a2
    8000492c:	44d8                	lw	a4,12(s1)
    8000492e:	cb98                	sw	a4,16(a5)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004930:	8526                	mv	a0,s1
    80004932:	fffff097          	auipc	ra,0xfffff
    80004936:	da2080e7          	jalr	-606(ra) # 800036d4 <bpin>
    log.lh.n++;
    8000493a:	0001e717          	auipc	a4,0x1e
    8000493e:	f3670713          	addi	a4,a4,-202 # 80022870 <log>
    80004942:	575c                	lw	a5,44(a4)
    80004944:	2785                	addiw	a5,a5,1
    80004946:	d75c                	sw	a5,44(a4)
    80004948:	a82d                	j	80004982 <log_write+0xc8>
    panic("too big a transaction");
    8000494a:	00004517          	auipc	a0,0x4
    8000494e:	dee50513          	addi	a0,a0,-530 # 80008738 <syscalls+0x208>
    80004952:	ffffc097          	auipc	ra,0xffffc
    80004956:	be8080e7          	jalr	-1048(ra) # 8000053a <panic>
    panic("log_write outside of trans");
    8000495a:	00004517          	auipc	a0,0x4
    8000495e:	df650513          	addi	a0,a0,-522 # 80008750 <syscalls+0x220>
    80004962:	ffffc097          	auipc	ra,0xffffc
    80004966:	bd8080e7          	jalr	-1064(ra) # 8000053a <panic>
  log.lh.block[i] = b->blockno;
    8000496a:	00878693          	addi	a3,a5,8
    8000496e:	068a                	slli	a3,a3,0x2
    80004970:	0001e717          	auipc	a4,0x1e
    80004974:	f0070713          	addi	a4,a4,-256 # 80022870 <log>
    80004978:	9736                	add	a4,a4,a3
    8000497a:	44d4                	lw	a3,12(s1)
    8000497c:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    8000497e:	faf609e3          	beq	a2,a5,80004930 <log_write+0x76>
  }
  release(&log.lock);
    80004982:	0001e517          	auipc	a0,0x1e
    80004986:	eee50513          	addi	a0,a0,-274 # 80022870 <log>
    8000498a:	ffffc097          	auipc	ra,0xffffc
    8000498e:	2fa080e7          	jalr	762(ra) # 80000c84 <release>
}
    80004992:	60e2                	ld	ra,24(sp)
    80004994:	6442                	ld	s0,16(sp)
    80004996:	64a2                	ld	s1,8(sp)
    80004998:	6902                	ld	s2,0(sp)
    8000499a:	6105                	addi	sp,sp,32
    8000499c:	8082                	ret

000000008000499e <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    8000499e:	1101                	addi	sp,sp,-32
    800049a0:	ec06                	sd	ra,24(sp)
    800049a2:	e822                	sd	s0,16(sp)
    800049a4:	e426                	sd	s1,8(sp)
    800049a6:	e04a                	sd	s2,0(sp)
    800049a8:	1000                	addi	s0,sp,32
    800049aa:	84aa                	mv	s1,a0
    800049ac:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    800049ae:	00004597          	auipc	a1,0x4
    800049b2:	dc258593          	addi	a1,a1,-574 # 80008770 <syscalls+0x240>
    800049b6:	0521                	addi	a0,a0,8
    800049b8:	ffffc097          	auipc	ra,0xffffc
    800049bc:	188080e7          	jalr	392(ra) # 80000b40 <initlock>
  lk->name = name;
    800049c0:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800049c4:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800049c8:	0204a423          	sw	zero,40(s1)
}
    800049cc:	60e2                	ld	ra,24(sp)
    800049ce:	6442                	ld	s0,16(sp)
    800049d0:	64a2                	ld	s1,8(sp)
    800049d2:	6902                	ld	s2,0(sp)
    800049d4:	6105                	addi	sp,sp,32
    800049d6:	8082                	ret

00000000800049d8 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    800049d8:	1101                	addi	sp,sp,-32
    800049da:	ec06                	sd	ra,24(sp)
    800049dc:	e822                	sd	s0,16(sp)
    800049de:	e426                	sd	s1,8(sp)
    800049e0:	e04a                	sd	s2,0(sp)
    800049e2:	1000                	addi	s0,sp,32
    800049e4:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800049e6:	00850913          	addi	s2,a0,8
    800049ea:	854a                	mv	a0,s2
    800049ec:	ffffc097          	auipc	ra,0xffffc
    800049f0:	1e4080e7          	jalr	484(ra) # 80000bd0 <acquire>
  while (lk->locked) {
    800049f4:	409c                	lw	a5,0(s1)
    800049f6:	cb89                	beqz	a5,80004a08 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    800049f8:	85ca                	mv	a1,s2
    800049fa:	8526                	mv	a0,s1
    800049fc:	ffffe097          	auipc	ra,0xffffe
    80004a00:	8e0080e7          	jalr	-1824(ra) # 800022dc <sleep>
  while (lk->locked) {
    80004a04:	409c                	lw	a5,0(s1)
    80004a06:	fbed                	bnez	a5,800049f8 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004a08:	4785                	li	a5,1
    80004a0a:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004a0c:	ffffd097          	auipc	ra,0xffffd
    80004a10:	f8a080e7          	jalr	-118(ra) # 80001996 <myproc>
    80004a14:	591c                	lw	a5,48(a0)
    80004a16:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004a18:	854a                	mv	a0,s2
    80004a1a:	ffffc097          	auipc	ra,0xffffc
    80004a1e:	26a080e7          	jalr	618(ra) # 80000c84 <release>
}
    80004a22:	60e2                	ld	ra,24(sp)
    80004a24:	6442                	ld	s0,16(sp)
    80004a26:	64a2                	ld	s1,8(sp)
    80004a28:	6902                	ld	s2,0(sp)
    80004a2a:	6105                	addi	sp,sp,32
    80004a2c:	8082                	ret

0000000080004a2e <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004a2e:	1101                	addi	sp,sp,-32
    80004a30:	ec06                	sd	ra,24(sp)
    80004a32:	e822                	sd	s0,16(sp)
    80004a34:	e426                	sd	s1,8(sp)
    80004a36:	e04a                	sd	s2,0(sp)
    80004a38:	1000                	addi	s0,sp,32
    80004a3a:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004a3c:	00850913          	addi	s2,a0,8
    80004a40:	854a                	mv	a0,s2
    80004a42:	ffffc097          	auipc	ra,0xffffc
    80004a46:	18e080e7          	jalr	398(ra) # 80000bd0 <acquire>
  lk->locked = 0;
    80004a4a:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004a4e:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004a52:	8526                	mv	a0,s1
    80004a54:	ffffe097          	auipc	ra,0xffffe
    80004a58:	b70080e7          	jalr	-1168(ra) # 800025c4 <wakeup>
  release(&lk->lk);
    80004a5c:	854a                	mv	a0,s2
    80004a5e:	ffffc097          	auipc	ra,0xffffc
    80004a62:	226080e7          	jalr	550(ra) # 80000c84 <release>
}
    80004a66:	60e2                	ld	ra,24(sp)
    80004a68:	6442                	ld	s0,16(sp)
    80004a6a:	64a2                	ld	s1,8(sp)
    80004a6c:	6902                	ld	s2,0(sp)
    80004a6e:	6105                	addi	sp,sp,32
    80004a70:	8082                	ret

0000000080004a72 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004a72:	7179                	addi	sp,sp,-48
    80004a74:	f406                	sd	ra,40(sp)
    80004a76:	f022                	sd	s0,32(sp)
    80004a78:	ec26                	sd	s1,24(sp)
    80004a7a:	e84a                	sd	s2,16(sp)
    80004a7c:	e44e                	sd	s3,8(sp)
    80004a7e:	1800                	addi	s0,sp,48
    80004a80:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004a82:	00850913          	addi	s2,a0,8
    80004a86:	854a                	mv	a0,s2
    80004a88:	ffffc097          	auipc	ra,0xffffc
    80004a8c:	148080e7          	jalr	328(ra) # 80000bd0 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004a90:	409c                	lw	a5,0(s1)
    80004a92:	ef99                	bnez	a5,80004ab0 <holdingsleep+0x3e>
    80004a94:	4481                	li	s1,0
  release(&lk->lk);
    80004a96:	854a                	mv	a0,s2
    80004a98:	ffffc097          	auipc	ra,0xffffc
    80004a9c:	1ec080e7          	jalr	492(ra) # 80000c84 <release>
  return r;
}
    80004aa0:	8526                	mv	a0,s1
    80004aa2:	70a2                	ld	ra,40(sp)
    80004aa4:	7402                	ld	s0,32(sp)
    80004aa6:	64e2                	ld	s1,24(sp)
    80004aa8:	6942                	ld	s2,16(sp)
    80004aaa:	69a2                	ld	s3,8(sp)
    80004aac:	6145                	addi	sp,sp,48
    80004aae:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004ab0:	0284a983          	lw	s3,40(s1)
    80004ab4:	ffffd097          	auipc	ra,0xffffd
    80004ab8:	ee2080e7          	jalr	-286(ra) # 80001996 <myproc>
    80004abc:	5904                	lw	s1,48(a0)
    80004abe:	413484b3          	sub	s1,s1,s3
    80004ac2:	0014b493          	seqz	s1,s1
    80004ac6:	bfc1                	j	80004a96 <holdingsleep+0x24>

0000000080004ac8 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004ac8:	1141                	addi	sp,sp,-16
    80004aca:	e406                	sd	ra,8(sp)
    80004acc:	e022                	sd	s0,0(sp)
    80004ace:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004ad0:	00004597          	auipc	a1,0x4
    80004ad4:	cb058593          	addi	a1,a1,-848 # 80008780 <syscalls+0x250>
    80004ad8:	0001e517          	auipc	a0,0x1e
    80004adc:	ee050513          	addi	a0,a0,-288 # 800229b8 <ftable>
    80004ae0:	ffffc097          	auipc	ra,0xffffc
    80004ae4:	060080e7          	jalr	96(ra) # 80000b40 <initlock>
}
    80004ae8:	60a2                	ld	ra,8(sp)
    80004aea:	6402                	ld	s0,0(sp)
    80004aec:	0141                	addi	sp,sp,16
    80004aee:	8082                	ret

0000000080004af0 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004af0:	1101                	addi	sp,sp,-32
    80004af2:	ec06                	sd	ra,24(sp)
    80004af4:	e822                	sd	s0,16(sp)
    80004af6:	e426                	sd	s1,8(sp)
    80004af8:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004afa:	0001e517          	auipc	a0,0x1e
    80004afe:	ebe50513          	addi	a0,a0,-322 # 800229b8 <ftable>
    80004b02:	ffffc097          	auipc	ra,0xffffc
    80004b06:	0ce080e7          	jalr	206(ra) # 80000bd0 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004b0a:	0001e497          	auipc	s1,0x1e
    80004b0e:	ec648493          	addi	s1,s1,-314 # 800229d0 <ftable+0x18>
    80004b12:	0001f717          	auipc	a4,0x1f
    80004b16:	e5e70713          	addi	a4,a4,-418 # 80023970 <ftable+0xfb8>
    if(f->ref == 0){
    80004b1a:	40dc                	lw	a5,4(s1)
    80004b1c:	cf99                	beqz	a5,80004b3a <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004b1e:	02848493          	addi	s1,s1,40
    80004b22:	fee49ce3          	bne	s1,a4,80004b1a <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004b26:	0001e517          	auipc	a0,0x1e
    80004b2a:	e9250513          	addi	a0,a0,-366 # 800229b8 <ftable>
    80004b2e:	ffffc097          	auipc	ra,0xffffc
    80004b32:	156080e7          	jalr	342(ra) # 80000c84 <release>
  return 0;
    80004b36:	4481                	li	s1,0
    80004b38:	a819                	j	80004b4e <filealloc+0x5e>
      f->ref = 1;
    80004b3a:	4785                	li	a5,1
    80004b3c:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004b3e:	0001e517          	auipc	a0,0x1e
    80004b42:	e7a50513          	addi	a0,a0,-390 # 800229b8 <ftable>
    80004b46:	ffffc097          	auipc	ra,0xffffc
    80004b4a:	13e080e7          	jalr	318(ra) # 80000c84 <release>
}
    80004b4e:	8526                	mv	a0,s1
    80004b50:	60e2                	ld	ra,24(sp)
    80004b52:	6442                	ld	s0,16(sp)
    80004b54:	64a2                	ld	s1,8(sp)
    80004b56:	6105                	addi	sp,sp,32
    80004b58:	8082                	ret

0000000080004b5a <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004b5a:	1101                	addi	sp,sp,-32
    80004b5c:	ec06                	sd	ra,24(sp)
    80004b5e:	e822                	sd	s0,16(sp)
    80004b60:	e426                	sd	s1,8(sp)
    80004b62:	1000                	addi	s0,sp,32
    80004b64:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004b66:	0001e517          	auipc	a0,0x1e
    80004b6a:	e5250513          	addi	a0,a0,-430 # 800229b8 <ftable>
    80004b6e:	ffffc097          	auipc	ra,0xffffc
    80004b72:	062080e7          	jalr	98(ra) # 80000bd0 <acquire>
  if(f->ref < 1)
    80004b76:	40dc                	lw	a5,4(s1)
    80004b78:	02f05263          	blez	a5,80004b9c <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004b7c:	2785                	addiw	a5,a5,1
    80004b7e:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004b80:	0001e517          	auipc	a0,0x1e
    80004b84:	e3850513          	addi	a0,a0,-456 # 800229b8 <ftable>
    80004b88:	ffffc097          	auipc	ra,0xffffc
    80004b8c:	0fc080e7          	jalr	252(ra) # 80000c84 <release>
  return f;
}
    80004b90:	8526                	mv	a0,s1
    80004b92:	60e2                	ld	ra,24(sp)
    80004b94:	6442                	ld	s0,16(sp)
    80004b96:	64a2                	ld	s1,8(sp)
    80004b98:	6105                	addi	sp,sp,32
    80004b9a:	8082                	ret
    panic("filedup");
    80004b9c:	00004517          	auipc	a0,0x4
    80004ba0:	bec50513          	addi	a0,a0,-1044 # 80008788 <syscalls+0x258>
    80004ba4:	ffffc097          	auipc	ra,0xffffc
    80004ba8:	996080e7          	jalr	-1642(ra) # 8000053a <panic>

0000000080004bac <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004bac:	7139                	addi	sp,sp,-64
    80004bae:	fc06                	sd	ra,56(sp)
    80004bb0:	f822                	sd	s0,48(sp)
    80004bb2:	f426                	sd	s1,40(sp)
    80004bb4:	f04a                	sd	s2,32(sp)
    80004bb6:	ec4e                	sd	s3,24(sp)
    80004bb8:	e852                	sd	s4,16(sp)
    80004bba:	e456                	sd	s5,8(sp)
    80004bbc:	0080                	addi	s0,sp,64
    80004bbe:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004bc0:	0001e517          	auipc	a0,0x1e
    80004bc4:	df850513          	addi	a0,a0,-520 # 800229b8 <ftable>
    80004bc8:	ffffc097          	auipc	ra,0xffffc
    80004bcc:	008080e7          	jalr	8(ra) # 80000bd0 <acquire>
  if(f->ref < 1)
    80004bd0:	40dc                	lw	a5,4(s1)
    80004bd2:	06f05163          	blez	a5,80004c34 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004bd6:	37fd                	addiw	a5,a5,-1
    80004bd8:	0007871b          	sext.w	a4,a5
    80004bdc:	c0dc                	sw	a5,4(s1)
    80004bde:	06e04363          	bgtz	a4,80004c44 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004be2:	0004a903          	lw	s2,0(s1)
    80004be6:	0094ca83          	lbu	s5,9(s1)
    80004bea:	0104ba03          	ld	s4,16(s1)
    80004bee:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004bf2:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004bf6:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004bfa:	0001e517          	auipc	a0,0x1e
    80004bfe:	dbe50513          	addi	a0,a0,-578 # 800229b8 <ftable>
    80004c02:	ffffc097          	auipc	ra,0xffffc
    80004c06:	082080e7          	jalr	130(ra) # 80000c84 <release>

  if(ff.type == FD_PIPE){
    80004c0a:	4785                	li	a5,1
    80004c0c:	04f90d63          	beq	s2,a5,80004c66 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004c10:	3979                	addiw	s2,s2,-2
    80004c12:	4785                	li	a5,1
    80004c14:	0527e063          	bltu	a5,s2,80004c54 <fileclose+0xa8>
    begin_op();
    80004c18:	00000097          	auipc	ra,0x0
    80004c1c:	acc080e7          	jalr	-1332(ra) # 800046e4 <begin_op>
    iput(ff.ip);
    80004c20:	854e                	mv	a0,s3
    80004c22:	fffff097          	auipc	ra,0xfffff
    80004c26:	2a0080e7          	jalr	672(ra) # 80003ec2 <iput>
    end_op();
    80004c2a:	00000097          	auipc	ra,0x0
    80004c2e:	b38080e7          	jalr	-1224(ra) # 80004762 <end_op>
    80004c32:	a00d                	j	80004c54 <fileclose+0xa8>
    panic("fileclose");
    80004c34:	00004517          	auipc	a0,0x4
    80004c38:	b5c50513          	addi	a0,a0,-1188 # 80008790 <syscalls+0x260>
    80004c3c:	ffffc097          	auipc	ra,0xffffc
    80004c40:	8fe080e7          	jalr	-1794(ra) # 8000053a <panic>
    release(&ftable.lock);
    80004c44:	0001e517          	auipc	a0,0x1e
    80004c48:	d7450513          	addi	a0,a0,-652 # 800229b8 <ftable>
    80004c4c:	ffffc097          	auipc	ra,0xffffc
    80004c50:	038080e7          	jalr	56(ra) # 80000c84 <release>
  }
}
    80004c54:	70e2                	ld	ra,56(sp)
    80004c56:	7442                	ld	s0,48(sp)
    80004c58:	74a2                	ld	s1,40(sp)
    80004c5a:	7902                	ld	s2,32(sp)
    80004c5c:	69e2                	ld	s3,24(sp)
    80004c5e:	6a42                	ld	s4,16(sp)
    80004c60:	6aa2                	ld	s5,8(sp)
    80004c62:	6121                	addi	sp,sp,64
    80004c64:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004c66:	85d6                	mv	a1,s5
    80004c68:	8552                	mv	a0,s4
    80004c6a:	00000097          	auipc	ra,0x0
    80004c6e:	34c080e7          	jalr	844(ra) # 80004fb6 <pipeclose>
    80004c72:	b7cd                	j	80004c54 <fileclose+0xa8>

0000000080004c74 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004c74:	715d                	addi	sp,sp,-80
    80004c76:	e486                	sd	ra,72(sp)
    80004c78:	e0a2                	sd	s0,64(sp)
    80004c7a:	fc26                	sd	s1,56(sp)
    80004c7c:	f84a                	sd	s2,48(sp)
    80004c7e:	f44e                	sd	s3,40(sp)
    80004c80:	0880                	addi	s0,sp,80
    80004c82:	84aa                	mv	s1,a0
    80004c84:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004c86:	ffffd097          	auipc	ra,0xffffd
    80004c8a:	d10080e7          	jalr	-752(ra) # 80001996 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004c8e:	409c                	lw	a5,0(s1)
    80004c90:	37f9                	addiw	a5,a5,-2
    80004c92:	4705                	li	a4,1
    80004c94:	04f76763          	bltu	a4,a5,80004ce2 <filestat+0x6e>
    80004c98:	892a                	mv	s2,a0
    ilock(f->ip);
    80004c9a:	6c88                	ld	a0,24(s1)
    80004c9c:	fffff097          	auipc	ra,0xfffff
    80004ca0:	06c080e7          	jalr	108(ra) # 80003d08 <ilock>
    stati(f->ip, &st);
    80004ca4:	fb840593          	addi	a1,s0,-72
    80004ca8:	6c88                	ld	a0,24(s1)
    80004caa:	fffff097          	auipc	ra,0xfffff
    80004cae:	2e8080e7          	jalr	744(ra) # 80003f92 <stati>
    iunlock(f->ip);
    80004cb2:	6c88                	ld	a0,24(s1)
    80004cb4:	fffff097          	auipc	ra,0xfffff
    80004cb8:	116080e7          	jalr	278(ra) # 80003dca <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004cbc:	46e1                	li	a3,24
    80004cbe:	fb840613          	addi	a2,s0,-72
    80004cc2:	85ce                	mv	a1,s3
    80004cc4:	05093503          	ld	a0,80(s2)
    80004cc8:	ffffd097          	auipc	ra,0xffffd
    80004ccc:	992080e7          	jalr	-1646(ra) # 8000165a <copyout>
    80004cd0:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004cd4:	60a6                	ld	ra,72(sp)
    80004cd6:	6406                	ld	s0,64(sp)
    80004cd8:	74e2                	ld	s1,56(sp)
    80004cda:	7942                	ld	s2,48(sp)
    80004cdc:	79a2                	ld	s3,40(sp)
    80004cde:	6161                	addi	sp,sp,80
    80004ce0:	8082                	ret
  return -1;
    80004ce2:	557d                	li	a0,-1
    80004ce4:	bfc5                	j	80004cd4 <filestat+0x60>

0000000080004ce6 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004ce6:	7179                	addi	sp,sp,-48
    80004ce8:	f406                	sd	ra,40(sp)
    80004cea:	f022                	sd	s0,32(sp)
    80004cec:	ec26                	sd	s1,24(sp)
    80004cee:	e84a                	sd	s2,16(sp)
    80004cf0:	e44e                	sd	s3,8(sp)
    80004cf2:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004cf4:	00854783          	lbu	a5,8(a0)
    80004cf8:	c3d5                	beqz	a5,80004d9c <fileread+0xb6>
    80004cfa:	84aa                	mv	s1,a0
    80004cfc:	89ae                	mv	s3,a1
    80004cfe:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004d00:	411c                	lw	a5,0(a0)
    80004d02:	4705                	li	a4,1
    80004d04:	04e78963          	beq	a5,a4,80004d56 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004d08:	470d                	li	a4,3
    80004d0a:	04e78d63          	beq	a5,a4,80004d64 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004d0e:	4709                	li	a4,2
    80004d10:	06e79e63          	bne	a5,a4,80004d8c <fileread+0xa6>
    ilock(f->ip);
    80004d14:	6d08                	ld	a0,24(a0)
    80004d16:	fffff097          	auipc	ra,0xfffff
    80004d1a:	ff2080e7          	jalr	-14(ra) # 80003d08 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004d1e:	874a                	mv	a4,s2
    80004d20:	5094                	lw	a3,32(s1)
    80004d22:	864e                	mv	a2,s3
    80004d24:	4585                	li	a1,1
    80004d26:	6c88                	ld	a0,24(s1)
    80004d28:	fffff097          	auipc	ra,0xfffff
    80004d2c:	294080e7          	jalr	660(ra) # 80003fbc <readi>
    80004d30:	892a                	mv	s2,a0
    80004d32:	00a05563          	blez	a0,80004d3c <fileread+0x56>
      f->off += r;
    80004d36:	509c                	lw	a5,32(s1)
    80004d38:	9fa9                	addw	a5,a5,a0
    80004d3a:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004d3c:	6c88                	ld	a0,24(s1)
    80004d3e:	fffff097          	auipc	ra,0xfffff
    80004d42:	08c080e7          	jalr	140(ra) # 80003dca <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004d46:	854a                	mv	a0,s2
    80004d48:	70a2                	ld	ra,40(sp)
    80004d4a:	7402                	ld	s0,32(sp)
    80004d4c:	64e2                	ld	s1,24(sp)
    80004d4e:	6942                	ld	s2,16(sp)
    80004d50:	69a2                	ld	s3,8(sp)
    80004d52:	6145                	addi	sp,sp,48
    80004d54:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004d56:	6908                	ld	a0,16(a0)
    80004d58:	00000097          	auipc	ra,0x0
    80004d5c:	3c0080e7          	jalr	960(ra) # 80005118 <piperead>
    80004d60:	892a                	mv	s2,a0
    80004d62:	b7d5                	j	80004d46 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004d64:	02451783          	lh	a5,36(a0)
    80004d68:	03079693          	slli	a3,a5,0x30
    80004d6c:	92c1                	srli	a3,a3,0x30
    80004d6e:	4725                	li	a4,9
    80004d70:	02d76863          	bltu	a4,a3,80004da0 <fileread+0xba>
    80004d74:	0792                	slli	a5,a5,0x4
    80004d76:	0001e717          	auipc	a4,0x1e
    80004d7a:	ba270713          	addi	a4,a4,-1118 # 80022918 <devsw>
    80004d7e:	97ba                	add	a5,a5,a4
    80004d80:	639c                	ld	a5,0(a5)
    80004d82:	c38d                	beqz	a5,80004da4 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004d84:	4505                	li	a0,1
    80004d86:	9782                	jalr	a5
    80004d88:	892a                	mv	s2,a0
    80004d8a:	bf75                	j	80004d46 <fileread+0x60>
    panic("fileread");
    80004d8c:	00004517          	auipc	a0,0x4
    80004d90:	a1450513          	addi	a0,a0,-1516 # 800087a0 <syscalls+0x270>
    80004d94:	ffffb097          	auipc	ra,0xffffb
    80004d98:	7a6080e7          	jalr	1958(ra) # 8000053a <panic>
    return -1;
    80004d9c:	597d                	li	s2,-1
    80004d9e:	b765                	j	80004d46 <fileread+0x60>
      return -1;
    80004da0:	597d                	li	s2,-1
    80004da2:	b755                	j	80004d46 <fileread+0x60>
    80004da4:	597d                	li	s2,-1
    80004da6:	b745                	j	80004d46 <fileread+0x60>

0000000080004da8 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004da8:	715d                	addi	sp,sp,-80
    80004daa:	e486                	sd	ra,72(sp)
    80004dac:	e0a2                	sd	s0,64(sp)
    80004dae:	fc26                	sd	s1,56(sp)
    80004db0:	f84a                	sd	s2,48(sp)
    80004db2:	f44e                	sd	s3,40(sp)
    80004db4:	f052                	sd	s4,32(sp)
    80004db6:	ec56                	sd	s5,24(sp)
    80004db8:	e85a                	sd	s6,16(sp)
    80004dba:	e45e                	sd	s7,8(sp)
    80004dbc:	e062                	sd	s8,0(sp)
    80004dbe:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004dc0:	00954783          	lbu	a5,9(a0)
    80004dc4:	10078663          	beqz	a5,80004ed0 <filewrite+0x128>
    80004dc8:	892a                	mv	s2,a0
    80004dca:	8b2e                	mv	s6,a1
    80004dcc:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004dce:	411c                	lw	a5,0(a0)
    80004dd0:	4705                	li	a4,1
    80004dd2:	02e78263          	beq	a5,a4,80004df6 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004dd6:	470d                	li	a4,3
    80004dd8:	02e78663          	beq	a5,a4,80004e04 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004ddc:	4709                	li	a4,2
    80004dde:	0ee79163          	bne	a5,a4,80004ec0 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004de2:	0ac05d63          	blez	a2,80004e9c <filewrite+0xf4>
    int i = 0;
    80004de6:	4981                	li	s3,0
    80004de8:	6b85                	lui	s7,0x1
    80004dea:	c00b8b93          	addi	s7,s7,-1024 # c00 <_entry-0x7ffff400>
    80004dee:	6c05                	lui	s8,0x1
    80004df0:	c00c0c1b          	addiw	s8,s8,-1024
    80004df4:	a861                	j	80004e8c <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004df6:	6908                	ld	a0,16(a0)
    80004df8:	00000097          	auipc	ra,0x0
    80004dfc:	22e080e7          	jalr	558(ra) # 80005026 <pipewrite>
    80004e00:	8a2a                	mv	s4,a0
    80004e02:	a045                	j	80004ea2 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004e04:	02451783          	lh	a5,36(a0)
    80004e08:	03079693          	slli	a3,a5,0x30
    80004e0c:	92c1                	srli	a3,a3,0x30
    80004e0e:	4725                	li	a4,9
    80004e10:	0cd76263          	bltu	a4,a3,80004ed4 <filewrite+0x12c>
    80004e14:	0792                	slli	a5,a5,0x4
    80004e16:	0001e717          	auipc	a4,0x1e
    80004e1a:	b0270713          	addi	a4,a4,-1278 # 80022918 <devsw>
    80004e1e:	97ba                	add	a5,a5,a4
    80004e20:	679c                	ld	a5,8(a5)
    80004e22:	cbdd                	beqz	a5,80004ed8 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004e24:	4505                	li	a0,1
    80004e26:	9782                	jalr	a5
    80004e28:	8a2a                	mv	s4,a0
    80004e2a:	a8a5                	j	80004ea2 <filewrite+0xfa>
    80004e2c:	00048a9b          	sext.w	s5,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004e30:	00000097          	auipc	ra,0x0
    80004e34:	8b4080e7          	jalr	-1868(ra) # 800046e4 <begin_op>
      ilock(f->ip);
    80004e38:	01893503          	ld	a0,24(s2)
    80004e3c:	fffff097          	auipc	ra,0xfffff
    80004e40:	ecc080e7          	jalr	-308(ra) # 80003d08 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004e44:	8756                	mv	a4,s5
    80004e46:	02092683          	lw	a3,32(s2)
    80004e4a:	01698633          	add	a2,s3,s6
    80004e4e:	4585                	li	a1,1
    80004e50:	01893503          	ld	a0,24(s2)
    80004e54:	fffff097          	auipc	ra,0xfffff
    80004e58:	260080e7          	jalr	608(ra) # 800040b4 <writei>
    80004e5c:	84aa                	mv	s1,a0
    80004e5e:	00a05763          	blez	a0,80004e6c <filewrite+0xc4>
        f->off += r;
    80004e62:	02092783          	lw	a5,32(s2)
    80004e66:	9fa9                	addw	a5,a5,a0
    80004e68:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004e6c:	01893503          	ld	a0,24(s2)
    80004e70:	fffff097          	auipc	ra,0xfffff
    80004e74:	f5a080e7          	jalr	-166(ra) # 80003dca <iunlock>
      end_op();
    80004e78:	00000097          	auipc	ra,0x0
    80004e7c:	8ea080e7          	jalr	-1814(ra) # 80004762 <end_op>

      if(r != n1){
    80004e80:	009a9f63          	bne	s5,s1,80004e9e <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004e84:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004e88:	0149db63          	bge	s3,s4,80004e9e <filewrite+0xf6>
      int n1 = n - i;
    80004e8c:	413a04bb          	subw	s1,s4,s3
    80004e90:	0004879b          	sext.w	a5,s1
    80004e94:	f8fbdce3          	bge	s7,a5,80004e2c <filewrite+0x84>
    80004e98:	84e2                	mv	s1,s8
    80004e9a:	bf49                	j	80004e2c <filewrite+0x84>
    int i = 0;
    80004e9c:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004e9e:	013a1f63          	bne	s4,s3,80004ebc <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004ea2:	8552                	mv	a0,s4
    80004ea4:	60a6                	ld	ra,72(sp)
    80004ea6:	6406                	ld	s0,64(sp)
    80004ea8:	74e2                	ld	s1,56(sp)
    80004eaa:	7942                	ld	s2,48(sp)
    80004eac:	79a2                	ld	s3,40(sp)
    80004eae:	7a02                	ld	s4,32(sp)
    80004eb0:	6ae2                	ld	s5,24(sp)
    80004eb2:	6b42                	ld	s6,16(sp)
    80004eb4:	6ba2                	ld	s7,8(sp)
    80004eb6:	6c02                	ld	s8,0(sp)
    80004eb8:	6161                	addi	sp,sp,80
    80004eba:	8082                	ret
    ret = (i == n ? n : -1);
    80004ebc:	5a7d                	li	s4,-1
    80004ebe:	b7d5                	j	80004ea2 <filewrite+0xfa>
    panic("filewrite");
    80004ec0:	00004517          	auipc	a0,0x4
    80004ec4:	8f050513          	addi	a0,a0,-1808 # 800087b0 <syscalls+0x280>
    80004ec8:	ffffb097          	auipc	ra,0xffffb
    80004ecc:	672080e7          	jalr	1650(ra) # 8000053a <panic>
    return -1;
    80004ed0:	5a7d                	li	s4,-1
    80004ed2:	bfc1                	j	80004ea2 <filewrite+0xfa>
      return -1;
    80004ed4:	5a7d                	li	s4,-1
    80004ed6:	b7f1                	j	80004ea2 <filewrite+0xfa>
    80004ed8:	5a7d                	li	s4,-1
    80004eda:	b7e1                	j	80004ea2 <filewrite+0xfa>

0000000080004edc <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004edc:	7179                	addi	sp,sp,-48
    80004ede:	f406                	sd	ra,40(sp)
    80004ee0:	f022                	sd	s0,32(sp)
    80004ee2:	ec26                	sd	s1,24(sp)
    80004ee4:	e84a                	sd	s2,16(sp)
    80004ee6:	e44e                	sd	s3,8(sp)
    80004ee8:	e052                	sd	s4,0(sp)
    80004eea:	1800                	addi	s0,sp,48
    80004eec:	84aa                	mv	s1,a0
    80004eee:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004ef0:	0005b023          	sd	zero,0(a1)
    80004ef4:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004ef8:	00000097          	auipc	ra,0x0
    80004efc:	bf8080e7          	jalr	-1032(ra) # 80004af0 <filealloc>
    80004f00:	e088                	sd	a0,0(s1)
    80004f02:	c551                	beqz	a0,80004f8e <pipealloc+0xb2>
    80004f04:	00000097          	auipc	ra,0x0
    80004f08:	bec080e7          	jalr	-1044(ra) # 80004af0 <filealloc>
    80004f0c:	00aa3023          	sd	a0,0(s4)
    80004f10:	c92d                	beqz	a0,80004f82 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004f12:	ffffc097          	auipc	ra,0xffffc
    80004f16:	bce080e7          	jalr	-1074(ra) # 80000ae0 <kalloc>
    80004f1a:	892a                	mv	s2,a0
    80004f1c:	c125                	beqz	a0,80004f7c <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004f1e:	4985                	li	s3,1
    80004f20:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004f24:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004f28:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004f2c:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004f30:	00003597          	auipc	a1,0x3
    80004f34:	55858593          	addi	a1,a1,1368 # 80008488 <states.0+0x1b8>
    80004f38:	ffffc097          	auipc	ra,0xffffc
    80004f3c:	c08080e7          	jalr	-1016(ra) # 80000b40 <initlock>
  (*f0)->type = FD_PIPE;
    80004f40:	609c                	ld	a5,0(s1)
    80004f42:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004f46:	609c                	ld	a5,0(s1)
    80004f48:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004f4c:	609c                	ld	a5,0(s1)
    80004f4e:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004f52:	609c                	ld	a5,0(s1)
    80004f54:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004f58:	000a3783          	ld	a5,0(s4)
    80004f5c:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004f60:	000a3783          	ld	a5,0(s4)
    80004f64:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004f68:	000a3783          	ld	a5,0(s4)
    80004f6c:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004f70:	000a3783          	ld	a5,0(s4)
    80004f74:	0127b823          	sd	s2,16(a5)
  return 0;
    80004f78:	4501                	li	a0,0
    80004f7a:	a025                	j	80004fa2 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004f7c:	6088                	ld	a0,0(s1)
    80004f7e:	e501                	bnez	a0,80004f86 <pipealloc+0xaa>
    80004f80:	a039                	j	80004f8e <pipealloc+0xb2>
    80004f82:	6088                	ld	a0,0(s1)
    80004f84:	c51d                	beqz	a0,80004fb2 <pipealloc+0xd6>
    fileclose(*f0);
    80004f86:	00000097          	auipc	ra,0x0
    80004f8a:	c26080e7          	jalr	-986(ra) # 80004bac <fileclose>
  if(*f1)
    80004f8e:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004f92:	557d                	li	a0,-1
  if(*f1)
    80004f94:	c799                	beqz	a5,80004fa2 <pipealloc+0xc6>
    fileclose(*f1);
    80004f96:	853e                	mv	a0,a5
    80004f98:	00000097          	auipc	ra,0x0
    80004f9c:	c14080e7          	jalr	-1004(ra) # 80004bac <fileclose>
  return -1;
    80004fa0:	557d                	li	a0,-1
}
    80004fa2:	70a2                	ld	ra,40(sp)
    80004fa4:	7402                	ld	s0,32(sp)
    80004fa6:	64e2                	ld	s1,24(sp)
    80004fa8:	6942                	ld	s2,16(sp)
    80004faa:	69a2                	ld	s3,8(sp)
    80004fac:	6a02                	ld	s4,0(sp)
    80004fae:	6145                	addi	sp,sp,48
    80004fb0:	8082                	ret
  return -1;
    80004fb2:	557d                	li	a0,-1
    80004fb4:	b7fd                	j	80004fa2 <pipealloc+0xc6>

0000000080004fb6 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004fb6:	1101                	addi	sp,sp,-32
    80004fb8:	ec06                	sd	ra,24(sp)
    80004fba:	e822                	sd	s0,16(sp)
    80004fbc:	e426                	sd	s1,8(sp)
    80004fbe:	e04a                	sd	s2,0(sp)
    80004fc0:	1000                	addi	s0,sp,32
    80004fc2:	84aa                	mv	s1,a0
    80004fc4:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004fc6:	ffffc097          	auipc	ra,0xffffc
    80004fca:	c0a080e7          	jalr	-1014(ra) # 80000bd0 <acquire>
  if(writable){
    80004fce:	02090d63          	beqz	s2,80005008 <pipeclose+0x52>
    pi->writeopen = 0;
    80004fd2:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004fd6:	21848513          	addi	a0,s1,536
    80004fda:	ffffd097          	auipc	ra,0xffffd
    80004fde:	5ea080e7          	jalr	1514(ra) # 800025c4 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004fe2:	2204b783          	ld	a5,544(s1)
    80004fe6:	eb95                	bnez	a5,8000501a <pipeclose+0x64>
    release(&pi->lock);
    80004fe8:	8526                	mv	a0,s1
    80004fea:	ffffc097          	auipc	ra,0xffffc
    80004fee:	c9a080e7          	jalr	-870(ra) # 80000c84 <release>
    kfree((char*)pi);
    80004ff2:	8526                	mv	a0,s1
    80004ff4:	ffffc097          	auipc	ra,0xffffc
    80004ff8:	9ee080e7          	jalr	-1554(ra) # 800009e2 <kfree>
  } else
    release(&pi->lock);
}
    80004ffc:	60e2                	ld	ra,24(sp)
    80004ffe:	6442                	ld	s0,16(sp)
    80005000:	64a2                	ld	s1,8(sp)
    80005002:	6902                	ld	s2,0(sp)
    80005004:	6105                	addi	sp,sp,32
    80005006:	8082                	ret
    pi->readopen = 0;
    80005008:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    8000500c:	21c48513          	addi	a0,s1,540
    80005010:	ffffd097          	auipc	ra,0xffffd
    80005014:	5b4080e7          	jalr	1460(ra) # 800025c4 <wakeup>
    80005018:	b7e9                	j	80004fe2 <pipeclose+0x2c>
    release(&pi->lock);
    8000501a:	8526                	mv	a0,s1
    8000501c:	ffffc097          	auipc	ra,0xffffc
    80005020:	c68080e7          	jalr	-920(ra) # 80000c84 <release>
}
    80005024:	bfe1                	j	80004ffc <pipeclose+0x46>

0000000080005026 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80005026:	711d                	addi	sp,sp,-96
    80005028:	ec86                	sd	ra,88(sp)
    8000502a:	e8a2                	sd	s0,80(sp)
    8000502c:	e4a6                	sd	s1,72(sp)
    8000502e:	e0ca                	sd	s2,64(sp)
    80005030:	fc4e                	sd	s3,56(sp)
    80005032:	f852                	sd	s4,48(sp)
    80005034:	f456                	sd	s5,40(sp)
    80005036:	f05a                	sd	s6,32(sp)
    80005038:	ec5e                	sd	s7,24(sp)
    8000503a:	e862                	sd	s8,16(sp)
    8000503c:	1080                	addi	s0,sp,96
    8000503e:	84aa                	mv	s1,a0
    80005040:	8aae                	mv	s5,a1
    80005042:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80005044:	ffffd097          	auipc	ra,0xffffd
    80005048:	952080e7          	jalr	-1710(ra) # 80001996 <myproc>
    8000504c:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    8000504e:	8526                	mv	a0,s1
    80005050:	ffffc097          	auipc	ra,0xffffc
    80005054:	b80080e7          	jalr	-1152(ra) # 80000bd0 <acquire>
  while(i < n){
    80005058:	0b405363          	blez	s4,800050fe <pipewrite+0xd8>
  int i = 0;
    8000505c:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    8000505e:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80005060:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80005064:	21c48b93          	addi	s7,s1,540
    80005068:	a089                	j	800050aa <pipewrite+0x84>
      release(&pi->lock);
    8000506a:	8526                	mv	a0,s1
    8000506c:	ffffc097          	auipc	ra,0xffffc
    80005070:	c18080e7          	jalr	-1000(ra) # 80000c84 <release>
      return -1;
    80005074:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80005076:	854a                	mv	a0,s2
    80005078:	60e6                	ld	ra,88(sp)
    8000507a:	6446                	ld	s0,80(sp)
    8000507c:	64a6                	ld	s1,72(sp)
    8000507e:	6906                	ld	s2,64(sp)
    80005080:	79e2                	ld	s3,56(sp)
    80005082:	7a42                	ld	s4,48(sp)
    80005084:	7aa2                	ld	s5,40(sp)
    80005086:	7b02                	ld	s6,32(sp)
    80005088:	6be2                	ld	s7,24(sp)
    8000508a:	6c42                	ld	s8,16(sp)
    8000508c:	6125                	addi	sp,sp,96
    8000508e:	8082                	ret
      wakeup(&pi->nread);
    80005090:	8562                	mv	a0,s8
    80005092:	ffffd097          	auipc	ra,0xffffd
    80005096:	532080e7          	jalr	1330(ra) # 800025c4 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    8000509a:	85a6                	mv	a1,s1
    8000509c:	855e                	mv	a0,s7
    8000509e:	ffffd097          	auipc	ra,0xffffd
    800050a2:	23e080e7          	jalr	574(ra) # 800022dc <sleep>
  while(i < n){
    800050a6:	05495d63          	bge	s2,s4,80005100 <pipewrite+0xda>
    if(pi->readopen == 0 || pr->killed){
    800050aa:	2204a783          	lw	a5,544(s1)
    800050ae:	dfd5                	beqz	a5,8000506a <pipewrite+0x44>
    800050b0:	0289a783          	lw	a5,40(s3)
    800050b4:	fbdd                	bnez	a5,8000506a <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    800050b6:	2184a783          	lw	a5,536(s1)
    800050ba:	21c4a703          	lw	a4,540(s1)
    800050be:	2007879b          	addiw	a5,a5,512
    800050c2:	fcf707e3          	beq	a4,a5,80005090 <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    800050c6:	4685                	li	a3,1
    800050c8:	01590633          	add	a2,s2,s5
    800050cc:	faf40593          	addi	a1,s0,-81
    800050d0:	0509b503          	ld	a0,80(s3)
    800050d4:	ffffc097          	auipc	ra,0xffffc
    800050d8:	612080e7          	jalr	1554(ra) # 800016e6 <copyin>
    800050dc:	03650263          	beq	a0,s6,80005100 <pipewrite+0xda>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    800050e0:	21c4a783          	lw	a5,540(s1)
    800050e4:	0017871b          	addiw	a4,a5,1
    800050e8:	20e4ae23          	sw	a4,540(s1)
    800050ec:	1ff7f793          	andi	a5,a5,511
    800050f0:	97a6                	add	a5,a5,s1
    800050f2:	faf44703          	lbu	a4,-81(s0)
    800050f6:	00e78c23          	sb	a4,24(a5)
      i++;
    800050fa:	2905                	addiw	s2,s2,1
    800050fc:	b76d                	j	800050a6 <pipewrite+0x80>
  int i = 0;
    800050fe:	4901                	li	s2,0
  wakeup(&pi->nread);
    80005100:	21848513          	addi	a0,s1,536
    80005104:	ffffd097          	auipc	ra,0xffffd
    80005108:	4c0080e7          	jalr	1216(ra) # 800025c4 <wakeup>
  release(&pi->lock);
    8000510c:	8526                	mv	a0,s1
    8000510e:	ffffc097          	auipc	ra,0xffffc
    80005112:	b76080e7          	jalr	-1162(ra) # 80000c84 <release>
  return i;
    80005116:	b785                	j	80005076 <pipewrite+0x50>

0000000080005118 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80005118:	715d                	addi	sp,sp,-80
    8000511a:	e486                	sd	ra,72(sp)
    8000511c:	e0a2                	sd	s0,64(sp)
    8000511e:	fc26                	sd	s1,56(sp)
    80005120:	f84a                	sd	s2,48(sp)
    80005122:	f44e                	sd	s3,40(sp)
    80005124:	f052                	sd	s4,32(sp)
    80005126:	ec56                	sd	s5,24(sp)
    80005128:	e85a                	sd	s6,16(sp)
    8000512a:	0880                	addi	s0,sp,80
    8000512c:	84aa                	mv	s1,a0
    8000512e:	892e                	mv	s2,a1
    80005130:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80005132:	ffffd097          	auipc	ra,0xffffd
    80005136:	864080e7          	jalr	-1948(ra) # 80001996 <myproc>
    8000513a:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    8000513c:	8526                	mv	a0,s1
    8000513e:	ffffc097          	auipc	ra,0xffffc
    80005142:	a92080e7          	jalr	-1390(ra) # 80000bd0 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005146:	2184a703          	lw	a4,536(s1)
    8000514a:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    8000514e:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005152:	02f71463          	bne	a4,a5,8000517a <piperead+0x62>
    80005156:	2244a783          	lw	a5,548(s1)
    8000515a:	c385                	beqz	a5,8000517a <piperead+0x62>
    if(pr->killed){
    8000515c:	028a2783          	lw	a5,40(s4)
    80005160:	ebc9                	bnez	a5,800051f2 <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80005162:	85a6                	mv	a1,s1
    80005164:	854e                	mv	a0,s3
    80005166:	ffffd097          	auipc	ra,0xffffd
    8000516a:	176080e7          	jalr	374(ra) # 800022dc <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    8000516e:	2184a703          	lw	a4,536(s1)
    80005172:	21c4a783          	lw	a5,540(s1)
    80005176:	fef700e3          	beq	a4,a5,80005156 <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    8000517a:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    8000517c:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    8000517e:	05505463          	blez	s5,800051c6 <piperead+0xae>
    if(pi->nread == pi->nwrite)
    80005182:	2184a783          	lw	a5,536(s1)
    80005186:	21c4a703          	lw	a4,540(s1)
    8000518a:	02f70e63          	beq	a4,a5,800051c6 <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    8000518e:	0017871b          	addiw	a4,a5,1
    80005192:	20e4ac23          	sw	a4,536(s1)
    80005196:	1ff7f793          	andi	a5,a5,511
    8000519a:	97a6                	add	a5,a5,s1
    8000519c:	0187c783          	lbu	a5,24(a5)
    800051a0:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    800051a4:	4685                	li	a3,1
    800051a6:	fbf40613          	addi	a2,s0,-65
    800051aa:	85ca                	mv	a1,s2
    800051ac:	050a3503          	ld	a0,80(s4)
    800051b0:	ffffc097          	auipc	ra,0xffffc
    800051b4:	4aa080e7          	jalr	1194(ra) # 8000165a <copyout>
    800051b8:	01650763          	beq	a0,s6,800051c6 <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800051bc:	2985                	addiw	s3,s3,1
    800051be:	0905                	addi	s2,s2,1
    800051c0:	fd3a91e3          	bne	s5,s3,80005182 <piperead+0x6a>
    800051c4:	89d6                	mv	s3,s5
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    800051c6:	21c48513          	addi	a0,s1,540
    800051ca:	ffffd097          	auipc	ra,0xffffd
    800051ce:	3fa080e7          	jalr	1018(ra) # 800025c4 <wakeup>
  release(&pi->lock);
    800051d2:	8526                	mv	a0,s1
    800051d4:	ffffc097          	auipc	ra,0xffffc
    800051d8:	ab0080e7          	jalr	-1360(ra) # 80000c84 <release>
  return i;
}
    800051dc:	854e                	mv	a0,s3
    800051de:	60a6                	ld	ra,72(sp)
    800051e0:	6406                	ld	s0,64(sp)
    800051e2:	74e2                	ld	s1,56(sp)
    800051e4:	7942                	ld	s2,48(sp)
    800051e6:	79a2                	ld	s3,40(sp)
    800051e8:	7a02                	ld	s4,32(sp)
    800051ea:	6ae2                	ld	s5,24(sp)
    800051ec:	6b42                	ld	s6,16(sp)
    800051ee:	6161                	addi	sp,sp,80
    800051f0:	8082                	ret
      release(&pi->lock);
    800051f2:	8526                	mv	a0,s1
    800051f4:	ffffc097          	auipc	ra,0xffffc
    800051f8:	a90080e7          	jalr	-1392(ra) # 80000c84 <release>
      return -1;
    800051fc:	59fd                	li	s3,-1
    800051fe:	bff9                	j	800051dc <piperead+0xc4>

0000000080005200 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80005200:	de010113          	addi	sp,sp,-544
    80005204:	20113c23          	sd	ra,536(sp)
    80005208:	20813823          	sd	s0,528(sp)
    8000520c:	20913423          	sd	s1,520(sp)
    80005210:	21213023          	sd	s2,512(sp)
    80005214:	ffce                	sd	s3,504(sp)
    80005216:	fbd2                	sd	s4,496(sp)
    80005218:	f7d6                	sd	s5,488(sp)
    8000521a:	f3da                	sd	s6,480(sp)
    8000521c:	efde                	sd	s7,472(sp)
    8000521e:	ebe2                	sd	s8,464(sp)
    80005220:	e7e6                	sd	s9,456(sp)
    80005222:	e3ea                	sd	s10,448(sp)
    80005224:	ff6e                	sd	s11,440(sp)
    80005226:	1400                	addi	s0,sp,544
    80005228:	892a                	mv	s2,a0
    8000522a:	dea43423          	sd	a0,-536(s0)
    8000522e:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80005232:	ffffc097          	auipc	ra,0xffffc
    80005236:	764080e7          	jalr	1892(ra) # 80001996 <myproc>
    8000523a:	84aa                	mv	s1,a0

  begin_op();
    8000523c:	fffff097          	auipc	ra,0xfffff
    80005240:	4a8080e7          	jalr	1192(ra) # 800046e4 <begin_op>

  if((ip = namei(path)) == 0){
    80005244:	854a                	mv	a0,s2
    80005246:	fffff097          	auipc	ra,0xfffff
    8000524a:	27e080e7          	jalr	638(ra) # 800044c4 <namei>
    8000524e:	c93d                	beqz	a0,800052c4 <exec+0xc4>
    80005250:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80005252:	fffff097          	auipc	ra,0xfffff
    80005256:	ab6080e7          	jalr	-1354(ra) # 80003d08 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    8000525a:	04000713          	li	a4,64
    8000525e:	4681                	li	a3,0
    80005260:	e5040613          	addi	a2,s0,-432
    80005264:	4581                	li	a1,0
    80005266:	8556                	mv	a0,s5
    80005268:	fffff097          	auipc	ra,0xfffff
    8000526c:	d54080e7          	jalr	-684(ra) # 80003fbc <readi>
    80005270:	04000793          	li	a5,64
    80005274:	00f51a63          	bne	a0,a5,80005288 <exec+0x88>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80005278:	e5042703          	lw	a4,-432(s0)
    8000527c:	464c47b7          	lui	a5,0x464c4
    80005280:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80005284:	04f70663          	beq	a4,a5,800052d0 <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80005288:	8556                	mv	a0,s5
    8000528a:	fffff097          	auipc	ra,0xfffff
    8000528e:	ce0080e7          	jalr	-800(ra) # 80003f6a <iunlockput>
    end_op();
    80005292:	fffff097          	auipc	ra,0xfffff
    80005296:	4d0080e7          	jalr	1232(ra) # 80004762 <end_op>
  }
  return -1;
    8000529a:	557d                	li	a0,-1
}
    8000529c:	21813083          	ld	ra,536(sp)
    800052a0:	21013403          	ld	s0,528(sp)
    800052a4:	20813483          	ld	s1,520(sp)
    800052a8:	20013903          	ld	s2,512(sp)
    800052ac:	79fe                	ld	s3,504(sp)
    800052ae:	7a5e                	ld	s4,496(sp)
    800052b0:	7abe                	ld	s5,488(sp)
    800052b2:	7b1e                	ld	s6,480(sp)
    800052b4:	6bfe                	ld	s7,472(sp)
    800052b6:	6c5e                	ld	s8,464(sp)
    800052b8:	6cbe                	ld	s9,456(sp)
    800052ba:	6d1e                	ld	s10,448(sp)
    800052bc:	7dfa                	ld	s11,440(sp)
    800052be:	22010113          	addi	sp,sp,544
    800052c2:	8082                	ret
    end_op();
    800052c4:	fffff097          	auipc	ra,0xfffff
    800052c8:	49e080e7          	jalr	1182(ra) # 80004762 <end_op>
    return -1;
    800052cc:	557d                	li	a0,-1
    800052ce:	b7f9                	j	8000529c <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    800052d0:	8526                	mv	a0,s1
    800052d2:	ffffc097          	auipc	ra,0xffffc
    800052d6:	788080e7          	jalr	1928(ra) # 80001a5a <proc_pagetable>
    800052da:	8b2a                	mv	s6,a0
    800052dc:	d555                	beqz	a0,80005288 <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800052de:	e7042783          	lw	a5,-400(s0)
    800052e2:	e8845703          	lhu	a4,-376(s0)
    800052e6:	c735                	beqz	a4,80005352 <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    800052e8:	4481                	li	s1,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800052ea:	e0043423          	sd	zero,-504(s0)
    if((ph.vaddr % PGSIZE) != 0)
    800052ee:	6a05                	lui	s4,0x1
    800052f0:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    800052f4:	dee43023          	sd	a4,-544(s0)
loadseg(pagetable_t pagetable, uint64 va, struct inode *ip, uint offset, uint sz)
{
  uint i, n;
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    800052f8:	6d85                	lui	s11,0x1
    800052fa:	7d7d                	lui	s10,0xfffff
    800052fc:	ac1d                	j	80005532 <exec+0x332>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    800052fe:	00003517          	auipc	a0,0x3
    80005302:	4c250513          	addi	a0,a0,1218 # 800087c0 <syscalls+0x290>
    80005306:	ffffb097          	auipc	ra,0xffffb
    8000530a:	234080e7          	jalr	564(ra) # 8000053a <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    8000530e:	874a                	mv	a4,s2
    80005310:	009c86bb          	addw	a3,s9,s1
    80005314:	4581                	li	a1,0
    80005316:	8556                	mv	a0,s5
    80005318:	fffff097          	auipc	ra,0xfffff
    8000531c:	ca4080e7          	jalr	-860(ra) # 80003fbc <readi>
    80005320:	2501                	sext.w	a0,a0
    80005322:	1aa91863          	bne	s2,a0,800054d2 <exec+0x2d2>
  for(i = 0; i < sz; i += PGSIZE){
    80005326:	009d84bb          	addw	s1,s11,s1
    8000532a:	013d09bb          	addw	s3,s10,s3
    8000532e:	1f74f263          	bgeu	s1,s7,80005512 <exec+0x312>
    pa = walkaddr(pagetable, va + i);
    80005332:	02049593          	slli	a1,s1,0x20
    80005336:	9181                	srli	a1,a1,0x20
    80005338:	95e2                	add	a1,a1,s8
    8000533a:	855a                	mv	a0,s6
    8000533c:	ffffc097          	auipc	ra,0xffffc
    80005340:	d16080e7          	jalr	-746(ra) # 80001052 <walkaddr>
    80005344:	862a                	mv	a2,a0
    if(pa == 0)
    80005346:	dd45                	beqz	a0,800052fe <exec+0xfe>
      n = PGSIZE;
    80005348:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    8000534a:	fd49f2e3          	bgeu	s3,s4,8000530e <exec+0x10e>
      n = sz - i;
    8000534e:	894e                	mv	s2,s3
    80005350:	bf7d                	j	8000530e <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005352:	4481                	li	s1,0
  iunlockput(ip);
    80005354:	8556                	mv	a0,s5
    80005356:	fffff097          	auipc	ra,0xfffff
    8000535a:	c14080e7          	jalr	-1004(ra) # 80003f6a <iunlockput>
  end_op();
    8000535e:	fffff097          	auipc	ra,0xfffff
    80005362:	404080e7          	jalr	1028(ra) # 80004762 <end_op>
  p = myproc();
    80005366:	ffffc097          	auipc	ra,0xffffc
    8000536a:	630080e7          	jalr	1584(ra) # 80001996 <myproc>
    8000536e:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    80005370:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80005374:	6785                	lui	a5,0x1
    80005376:	17fd                	addi	a5,a5,-1
    80005378:	97a6                	add	a5,a5,s1
    8000537a:	777d                	lui	a4,0xfffff
    8000537c:	8ff9                	and	a5,a5,a4
    8000537e:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80005382:	6609                	lui	a2,0x2
    80005384:	963e                	add	a2,a2,a5
    80005386:	85be                	mv	a1,a5
    80005388:	855a                	mv	a0,s6
    8000538a:	ffffc097          	auipc	ra,0xffffc
    8000538e:	07c080e7          	jalr	124(ra) # 80001406 <uvmalloc>
    80005392:	8c2a                	mv	s8,a0
  ip = 0;
    80005394:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80005396:	12050e63          	beqz	a0,800054d2 <exec+0x2d2>
  uvmclear(pagetable, sz-2*PGSIZE);
    8000539a:	75f9                	lui	a1,0xffffe
    8000539c:	95aa                	add	a1,a1,a0
    8000539e:	855a                	mv	a0,s6
    800053a0:	ffffc097          	auipc	ra,0xffffc
    800053a4:	288080e7          	jalr	648(ra) # 80001628 <uvmclear>
  stackbase = sp - PGSIZE;
    800053a8:	7afd                	lui	s5,0xfffff
    800053aa:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    800053ac:	df043783          	ld	a5,-528(s0)
    800053b0:	6388                	ld	a0,0(a5)
    800053b2:	c925                	beqz	a0,80005422 <exec+0x222>
    800053b4:	e9040993          	addi	s3,s0,-368
    800053b8:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    800053bc:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    800053be:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    800053c0:	ffffc097          	auipc	ra,0xffffc
    800053c4:	a88080e7          	jalr	-1400(ra) # 80000e48 <strlen>
    800053c8:	0015079b          	addiw	a5,a0,1
    800053cc:	40f907b3          	sub	a5,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    800053d0:	ff07f913          	andi	s2,a5,-16
    if(sp < stackbase)
    800053d4:	13596363          	bltu	s2,s5,800054fa <exec+0x2fa>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    800053d8:	df043d83          	ld	s11,-528(s0)
    800053dc:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    800053e0:	8552                	mv	a0,s4
    800053e2:	ffffc097          	auipc	ra,0xffffc
    800053e6:	a66080e7          	jalr	-1434(ra) # 80000e48 <strlen>
    800053ea:	0015069b          	addiw	a3,a0,1
    800053ee:	8652                	mv	a2,s4
    800053f0:	85ca                	mv	a1,s2
    800053f2:	855a                	mv	a0,s6
    800053f4:	ffffc097          	auipc	ra,0xffffc
    800053f8:	266080e7          	jalr	614(ra) # 8000165a <copyout>
    800053fc:	10054363          	bltz	a0,80005502 <exec+0x302>
    ustack[argc] = sp;
    80005400:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80005404:	0485                	addi	s1,s1,1
    80005406:	008d8793          	addi	a5,s11,8
    8000540a:	def43823          	sd	a5,-528(s0)
    8000540e:	008db503          	ld	a0,8(s11)
    80005412:	c911                	beqz	a0,80005426 <exec+0x226>
    if(argc >= MAXARG)
    80005414:	09a1                	addi	s3,s3,8
    80005416:	fb3c95e3          	bne	s9,s3,800053c0 <exec+0x1c0>
  sz = sz1;
    8000541a:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    8000541e:	4a81                	li	s5,0
    80005420:	a84d                	j	800054d2 <exec+0x2d2>
  sp = sz;
    80005422:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80005424:	4481                	li	s1,0
  ustack[argc] = 0;
    80005426:	00349793          	slli	a5,s1,0x3
    8000542a:	f9078793          	addi	a5,a5,-112 # f90 <_entry-0x7ffff070>
    8000542e:	97a2                	add	a5,a5,s0
    80005430:	f007b023          	sd	zero,-256(a5)
  sp -= (argc+1) * sizeof(uint64);
    80005434:	00148693          	addi	a3,s1,1
    80005438:	068e                	slli	a3,a3,0x3
    8000543a:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    8000543e:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80005442:	01597663          	bgeu	s2,s5,8000544e <exec+0x24e>
  sz = sz1;
    80005446:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    8000544a:	4a81                	li	s5,0
    8000544c:	a059                	j	800054d2 <exec+0x2d2>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    8000544e:	e9040613          	addi	a2,s0,-368
    80005452:	85ca                	mv	a1,s2
    80005454:	855a                	mv	a0,s6
    80005456:	ffffc097          	auipc	ra,0xffffc
    8000545a:	204080e7          	jalr	516(ra) # 8000165a <copyout>
    8000545e:	0a054663          	bltz	a0,8000550a <exec+0x30a>
  p->trapframe->a1 = sp;
    80005462:	058bb783          	ld	a5,88(s7)
    80005466:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    8000546a:	de843783          	ld	a5,-536(s0)
    8000546e:	0007c703          	lbu	a4,0(a5)
    80005472:	cf11                	beqz	a4,8000548e <exec+0x28e>
    80005474:	0785                	addi	a5,a5,1
    if(*s == '/')
    80005476:	02f00693          	li	a3,47
    8000547a:	a039                	j	80005488 <exec+0x288>
      last = s+1;
    8000547c:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    80005480:	0785                	addi	a5,a5,1
    80005482:	fff7c703          	lbu	a4,-1(a5)
    80005486:	c701                	beqz	a4,8000548e <exec+0x28e>
    if(*s == '/')
    80005488:	fed71ce3          	bne	a4,a3,80005480 <exec+0x280>
    8000548c:	bfc5                	j	8000547c <exec+0x27c>
  safestrcpy(p->name, last, sizeof(p->name));
    8000548e:	4641                	li	a2,16
    80005490:	de843583          	ld	a1,-536(s0)
    80005494:	158b8513          	addi	a0,s7,344
    80005498:	ffffc097          	auipc	ra,0xffffc
    8000549c:	97e080e7          	jalr	-1666(ra) # 80000e16 <safestrcpy>
  oldpagetable = p->pagetable;
    800054a0:	050bb503          	ld	a0,80(s7)
  p->pagetable = pagetable;
    800054a4:	056bb823          	sd	s6,80(s7)
  p->sz = sz;
    800054a8:	058bb423          	sd	s8,72(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    800054ac:	058bb783          	ld	a5,88(s7)
    800054b0:	e6843703          	ld	a4,-408(s0)
    800054b4:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    800054b6:	058bb783          	ld	a5,88(s7)
    800054ba:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    800054be:	85ea                	mv	a1,s10
    800054c0:	ffffc097          	auipc	ra,0xffffc
    800054c4:	636080e7          	jalr	1590(ra) # 80001af6 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    800054c8:	0004851b          	sext.w	a0,s1
    800054cc:	bbc1                	j	8000529c <exec+0x9c>
    800054ce:	de943c23          	sd	s1,-520(s0)
    proc_freepagetable(pagetable, sz);
    800054d2:	df843583          	ld	a1,-520(s0)
    800054d6:	855a                	mv	a0,s6
    800054d8:	ffffc097          	auipc	ra,0xffffc
    800054dc:	61e080e7          	jalr	1566(ra) # 80001af6 <proc_freepagetable>
  if(ip){
    800054e0:	da0a94e3          	bnez	s5,80005288 <exec+0x88>
  return -1;
    800054e4:	557d                	li	a0,-1
    800054e6:	bb5d                	j	8000529c <exec+0x9c>
    800054e8:	de943c23          	sd	s1,-520(s0)
    800054ec:	b7dd                	j	800054d2 <exec+0x2d2>
    800054ee:	de943c23          	sd	s1,-520(s0)
    800054f2:	b7c5                	j	800054d2 <exec+0x2d2>
    800054f4:	de943c23          	sd	s1,-520(s0)
    800054f8:	bfe9                	j	800054d2 <exec+0x2d2>
  sz = sz1;
    800054fa:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800054fe:	4a81                	li	s5,0
    80005500:	bfc9                	j	800054d2 <exec+0x2d2>
  sz = sz1;
    80005502:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005506:	4a81                	li	s5,0
    80005508:	b7e9                	j	800054d2 <exec+0x2d2>
  sz = sz1;
    8000550a:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    8000550e:	4a81                	li	s5,0
    80005510:	b7c9                	j	800054d2 <exec+0x2d2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005512:	df843483          	ld	s1,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005516:	e0843783          	ld	a5,-504(s0)
    8000551a:	0017869b          	addiw	a3,a5,1
    8000551e:	e0d43423          	sd	a3,-504(s0)
    80005522:	e0043783          	ld	a5,-512(s0)
    80005526:	0387879b          	addiw	a5,a5,56
    8000552a:	e8845703          	lhu	a4,-376(s0)
    8000552e:	e2e6d3e3          	bge	a3,a4,80005354 <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005532:	2781                	sext.w	a5,a5
    80005534:	e0f43023          	sd	a5,-512(s0)
    80005538:	03800713          	li	a4,56
    8000553c:	86be                	mv	a3,a5
    8000553e:	e1840613          	addi	a2,s0,-488
    80005542:	4581                	li	a1,0
    80005544:	8556                	mv	a0,s5
    80005546:	fffff097          	auipc	ra,0xfffff
    8000554a:	a76080e7          	jalr	-1418(ra) # 80003fbc <readi>
    8000554e:	03800793          	li	a5,56
    80005552:	f6f51ee3          	bne	a0,a5,800054ce <exec+0x2ce>
    if(ph.type != ELF_PROG_LOAD)
    80005556:	e1842783          	lw	a5,-488(s0)
    8000555a:	4705                	li	a4,1
    8000555c:	fae79de3          	bne	a5,a4,80005516 <exec+0x316>
    if(ph.memsz < ph.filesz)
    80005560:	e4043603          	ld	a2,-448(s0)
    80005564:	e3843783          	ld	a5,-456(s0)
    80005568:	f8f660e3          	bltu	a2,a5,800054e8 <exec+0x2e8>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    8000556c:	e2843783          	ld	a5,-472(s0)
    80005570:	963e                	add	a2,a2,a5
    80005572:	f6f66ee3          	bltu	a2,a5,800054ee <exec+0x2ee>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005576:	85a6                	mv	a1,s1
    80005578:	855a                	mv	a0,s6
    8000557a:	ffffc097          	auipc	ra,0xffffc
    8000557e:	e8c080e7          	jalr	-372(ra) # 80001406 <uvmalloc>
    80005582:	dea43c23          	sd	a0,-520(s0)
    80005586:	d53d                	beqz	a0,800054f4 <exec+0x2f4>
    if((ph.vaddr % PGSIZE) != 0)
    80005588:	e2843c03          	ld	s8,-472(s0)
    8000558c:	de043783          	ld	a5,-544(s0)
    80005590:	00fc77b3          	and	a5,s8,a5
    80005594:	ff9d                	bnez	a5,800054d2 <exec+0x2d2>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005596:	e2042c83          	lw	s9,-480(s0)
    8000559a:	e3842b83          	lw	s7,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    8000559e:	f60b8ae3          	beqz	s7,80005512 <exec+0x312>
    800055a2:	89de                	mv	s3,s7
    800055a4:	4481                	li	s1,0
    800055a6:	b371                	j	80005332 <exec+0x132>

00000000800055a8 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    800055a8:	7179                	addi	sp,sp,-48
    800055aa:	f406                	sd	ra,40(sp)
    800055ac:	f022                	sd	s0,32(sp)
    800055ae:	ec26                	sd	s1,24(sp)
    800055b0:	e84a                	sd	s2,16(sp)
    800055b2:	1800                	addi	s0,sp,48
    800055b4:	892e                	mv	s2,a1
    800055b6:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    800055b8:	fdc40593          	addi	a1,s0,-36
    800055bc:	ffffe097          	auipc	ra,0xffffe
    800055c0:	9d6080e7          	jalr	-1578(ra) # 80002f92 <argint>
    800055c4:	04054063          	bltz	a0,80005604 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    800055c8:	fdc42703          	lw	a4,-36(s0)
    800055cc:	47bd                	li	a5,15
    800055ce:	02e7ed63          	bltu	a5,a4,80005608 <argfd+0x60>
    800055d2:	ffffc097          	auipc	ra,0xffffc
    800055d6:	3c4080e7          	jalr	964(ra) # 80001996 <myproc>
    800055da:	fdc42703          	lw	a4,-36(s0)
    800055de:	01a70793          	addi	a5,a4,26 # fffffffffffff01a <end+0xffffffff7ffd801a>
    800055e2:	078e                	slli	a5,a5,0x3
    800055e4:	953e                	add	a0,a0,a5
    800055e6:	611c                	ld	a5,0(a0)
    800055e8:	c395                	beqz	a5,8000560c <argfd+0x64>
    return -1;
  if(pfd)
    800055ea:	00090463          	beqz	s2,800055f2 <argfd+0x4a>
    *pfd = fd;
    800055ee:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    800055f2:	4501                	li	a0,0
  if(pf)
    800055f4:	c091                	beqz	s1,800055f8 <argfd+0x50>
    *pf = f;
    800055f6:	e09c                	sd	a5,0(s1)
}
    800055f8:	70a2                	ld	ra,40(sp)
    800055fa:	7402                	ld	s0,32(sp)
    800055fc:	64e2                	ld	s1,24(sp)
    800055fe:	6942                	ld	s2,16(sp)
    80005600:	6145                	addi	sp,sp,48
    80005602:	8082                	ret
    return -1;
    80005604:	557d                	li	a0,-1
    80005606:	bfcd                	j	800055f8 <argfd+0x50>
    return -1;
    80005608:	557d                	li	a0,-1
    8000560a:	b7fd                	j	800055f8 <argfd+0x50>
    8000560c:	557d                	li	a0,-1
    8000560e:	b7ed                	j	800055f8 <argfd+0x50>

0000000080005610 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005610:	1101                	addi	sp,sp,-32
    80005612:	ec06                	sd	ra,24(sp)
    80005614:	e822                	sd	s0,16(sp)
    80005616:	e426                	sd	s1,8(sp)
    80005618:	1000                	addi	s0,sp,32
    8000561a:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    8000561c:	ffffc097          	auipc	ra,0xffffc
    80005620:	37a080e7          	jalr	890(ra) # 80001996 <myproc>
    80005624:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005626:	0d050793          	addi	a5,a0,208
    8000562a:	4501                	li	a0,0
    8000562c:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    8000562e:	6398                	ld	a4,0(a5)
    80005630:	cb19                	beqz	a4,80005646 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005632:	2505                	addiw	a0,a0,1
    80005634:	07a1                	addi	a5,a5,8
    80005636:	fed51ce3          	bne	a0,a3,8000562e <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    8000563a:	557d                	li	a0,-1
}
    8000563c:	60e2                	ld	ra,24(sp)
    8000563e:	6442                	ld	s0,16(sp)
    80005640:	64a2                	ld	s1,8(sp)
    80005642:	6105                	addi	sp,sp,32
    80005644:	8082                	ret
      p->ofile[fd] = f;
    80005646:	01a50793          	addi	a5,a0,26
    8000564a:	078e                	slli	a5,a5,0x3
    8000564c:	963e                	add	a2,a2,a5
    8000564e:	e204                	sd	s1,0(a2)
      return fd;
    80005650:	b7f5                	j	8000563c <fdalloc+0x2c>

0000000080005652 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005652:	715d                	addi	sp,sp,-80
    80005654:	e486                	sd	ra,72(sp)
    80005656:	e0a2                	sd	s0,64(sp)
    80005658:	fc26                	sd	s1,56(sp)
    8000565a:	f84a                	sd	s2,48(sp)
    8000565c:	f44e                	sd	s3,40(sp)
    8000565e:	f052                	sd	s4,32(sp)
    80005660:	ec56                	sd	s5,24(sp)
    80005662:	0880                	addi	s0,sp,80
    80005664:	89ae                	mv	s3,a1
    80005666:	8ab2                	mv	s5,a2
    80005668:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    8000566a:	fb040593          	addi	a1,s0,-80
    8000566e:	fffff097          	auipc	ra,0xfffff
    80005672:	e74080e7          	jalr	-396(ra) # 800044e2 <nameiparent>
    80005676:	892a                	mv	s2,a0
    80005678:	12050e63          	beqz	a0,800057b4 <create+0x162>
    return 0;

  ilock(dp);
    8000567c:	ffffe097          	auipc	ra,0xffffe
    80005680:	68c080e7          	jalr	1676(ra) # 80003d08 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005684:	4601                	li	a2,0
    80005686:	fb040593          	addi	a1,s0,-80
    8000568a:	854a                	mv	a0,s2
    8000568c:	fffff097          	auipc	ra,0xfffff
    80005690:	b60080e7          	jalr	-1184(ra) # 800041ec <dirlookup>
    80005694:	84aa                	mv	s1,a0
    80005696:	c921                	beqz	a0,800056e6 <create+0x94>
    iunlockput(dp);
    80005698:	854a                	mv	a0,s2
    8000569a:	fffff097          	auipc	ra,0xfffff
    8000569e:	8d0080e7          	jalr	-1840(ra) # 80003f6a <iunlockput>
    ilock(ip);
    800056a2:	8526                	mv	a0,s1
    800056a4:	ffffe097          	auipc	ra,0xffffe
    800056a8:	664080e7          	jalr	1636(ra) # 80003d08 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800056ac:	2981                	sext.w	s3,s3
    800056ae:	4789                	li	a5,2
    800056b0:	02f99463          	bne	s3,a5,800056d8 <create+0x86>
    800056b4:	0444d783          	lhu	a5,68(s1)
    800056b8:	37f9                	addiw	a5,a5,-2
    800056ba:	17c2                	slli	a5,a5,0x30
    800056bc:	93c1                	srli	a5,a5,0x30
    800056be:	4705                	li	a4,1
    800056c0:	00f76c63          	bltu	a4,a5,800056d8 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    800056c4:	8526                	mv	a0,s1
    800056c6:	60a6                	ld	ra,72(sp)
    800056c8:	6406                	ld	s0,64(sp)
    800056ca:	74e2                	ld	s1,56(sp)
    800056cc:	7942                	ld	s2,48(sp)
    800056ce:	79a2                	ld	s3,40(sp)
    800056d0:	7a02                	ld	s4,32(sp)
    800056d2:	6ae2                	ld	s5,24(sp)
    800056d4:	6161                	addi	sp,sp,80
    800056d6:	8082                	ret
    iunlockput(ip);
    800056d8:	8526                	mv	a0,s1
    800056da:	fffff097          	auipc	ra,0xfffff
    800056de:	890080e7          	jalr	-1904(ra) # 80003f6a <iunlockput>
    return 0;
    800056e2:	4481                	li	s1,0
    800056e4:	b7c5                	j	800056c4 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    800056e6:	85ce                	mv	a1,s3
    800056e8:	00092503          	lw	a0,0(s2)
    800056ec:	ffffe097          	auipc	ra,0xffffe
    800056f0:	482080e7          	jalr	1154(ra) # 80003b6e <ialloc>
    800056f4:	84aa                	mv	s1,a0
    800056f6:	c521                	beqz	a0,8000573e <create+0xec>
  ilock(ip);
    800056f8:	ffffe097          	auipc	ra,0xffffe
    800056fc:	610080e7          	jalr	1552(ra) # 80003d08 <ilock>
  ip->major = major;
    80005700:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    80005704:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    80005708:	4a05                	li	s4,1
    8000570a:	05449523          	sh	s4,74(s1)
  iupdate(ip);
    8000570e:	8526                	mv	a0,s1
    80005710:	ffffe097          	auipc	ra,0xffffe
    80005714:	52c080e7          	jalr	1324(ra) # 80003c3c <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005718:	2981                	sext.w	s3,s3
    8000571a:	03498a63          	beq	s3,s4,8000574e <create+0xfc>
  if(dirlink(dp, name, ip->inum) < 0)
    8000571e:	40d0                	lw	a2,4(s1)
    80005720:	fb040593          	addi	a1,s0,-80
    80005724:	854a                	mv	a0,s2
    80005726:	fffff097          	auipc	ra,0xfffff
    8000572a:	cdc080e7          	jalr	-804(ra) # 80004402 <dirlink>
    8000572e:	06054b63          	bltz	a0,800057a4 <create+0x152>
  iunlockput(dp);
    80005732:	854a                	mv	a0,s2
    80005734:	fffff097          	auipc	ra,0xfffff
    80005738:	836080e7          	jalr	-1994(ra) # 80003f6a <iunlockput>
  return ip;
    8000573c:	b761                	j	800056c4 <create+0x72>
    panic("create: ialloc");
    8000573e:	00003517          	auipc	a0,0x3
    80005742:	0a250513          	addi	a0,a0,162 # 800087e0 <syscalls+0x2b0>
    80005746:	ffffb097          	auipc	ra,0xffffb
    8000574a:	df4080e7          	jalr	-524(ra) # 8000053a <panic>
    dp->nlink++;  // for ".."
    8000574e:	04a95783          	lhu	a5,74(s2)
    80005752:	2785                	addiw	a5,a5,1
    80005754:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    80005758:	854a                	mv	a0,s2
    8000575a:	ffffe097          	auipc	ra,0xffffe
    8000575e:	4e2080e7          	jalr	1250(ra) # 80003c3c <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005762:	40d0                	lw	a2,4(s1)
    80005764:	00003597          	auipc	a1,0x3
    80005768:	08c58593          	addi	a1,a1,140 # 800087f0 <syscalls+0x2c0>
    8000576c:	8526                	mv	a0,s1
    8000576e:	fffff097          	auipc	ra,0xfffff
    80005772:	c94080e7          	jalr	-876(ra) # 80004402 <dirlink>
    80005776:	00054f63          	bltz	a0,80005794 <create+0x142>
    8000577a:	00492603          	lw	a2,4(s2)
    8000577e:	00003597          	auipc	a1,0x3
    80005782:	07a58593          	addi	a1,a1,122 # 800087f8 <syscalls+0x2c8>
    80005786:	8526                	mv	a0,s1
    80005788:	fffff097          	auipc	ra,0xfffff
    8000578c:	c7a080e7          	jalr	-902(ra) # 80004402 <dirlink>
    80005790:	f80557e3          	bgez	a0,8000571e <create+0xcc>
      panic("create dots");
    80005794:	00003517          	auipc	a0,0x3
    80005798:	06c50513          	addi	a0,a0,108 # 80008800 <syscalls+0x2d0>
    8000579c:	ffffb097          	auipc	ra,0xffffb
    800057a0:	d9e080e7          	jalr	-610(ra) # 8000053a <panic>
    panic("create: dirlink");
    800057a4:	00003517          	auipc	a0,0x3
    800057a8:	06c50513          	addi	a0,a0,108 # 80008810 <syscalls+0x2e0>
    800057ac:	ffffb097          	auipc	ra,0xffffb
    800057b0:	d8e080e7          	jalr	-626(ra) # 8000053a <panic>
    return 0;
    800057b4:	84aa                	mv	s1,a0
    800057b6:	b739                	j	800056c4 <create+0x72>

00000000800057b8 <sys_dup>:
{
    800057b8:	7179                	addi	sp,sp,-48
    800057ba:	f406                	sd	ra,40(sp)
    800057bc:	f022                	sd	s0,32(sp)
    800057be:	ec26                	sd	s1,24(sp)
    800057c0:	e84a                	sd	s2,16(sp)
    800057c2:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800057c4:	fd840613          	addi	a2,s0,-40
    800057c8:	4581                	li	a1,0
    800057ca:	4501                	li	a0,0
    800057cc:	00000097          	auipc	ra,0x0
    800057d0:	ddc080e7          	jalr	-548(ra) # 800055a8 <argfd>
    return -1;
    800057d4:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800057d6:	02054363          	bltz	a0,800057fc <sys_dup+0x44>
  if((fd=fdalloc(f)) < 0)
    800057da:	fd843903          	ld	s2,-40(s0)
    800057de:	854a                	mv	a0,s2
    800057e0:	00000097          	auipc	ra,0x0
    800057e4:	e30080e7          	jalr	-464(ra) # 80005610 <fdalloc>
    800057e8:	84aa                	mv	s1,a0
    return -1;
    800057ea:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800057ec:	00054863          	bltz	a0,800057fc <sys_dup+0x44>
  filedup(f);
    800057f0:	854a                	mv	a0,s2
    800057f2:	fffff097          	auipc	ra,0xfffff
    800057f6:	368080e7          	jalr	872(ra) # 80004b5a <filedup>
  return fd;
    800057fa:	87a6                	mv	a5,s1
}
    800057fc:	853e                	mv	a0,a5
    800057fe:	70a2                	ld	ra,40(sp)
    80005800:	7402                	ld	s0,32(sp)
    80005802:	64e2                	ld	s1,24(sp)
    80005804:	6942                	ld	s2,16(sp)
    80005806:	6145                	addi	sp,sp,48
    80005808:	8082                	ret

000000008000580a <sys_read>:
{
    8000580a:	7179                	addi	sp,sp,-48
    8000580c:	f406                	sd	ra,40(sp)
    8000580e:	f022                	sd	s0,32(sp)
    80005810:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005812:	fe840613          	addi	a2,s0,-24
    80005816:	4581                	li	a1,0
    80005818:	4501                	li	a0,0
    8000581a:	00000097          	auipc	ra,0x0
    8000581e:	d8e080e7          	jalr	-626(ra) # 800055a8 <argfd>
    return -1;
    80005822:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005824:	04054163          	bltz	a0,80005866 <sys_read+0x5c>
    80005828:	fe440593          	addi	a1,s0,-28
    8000582c:	4509                	li	a0,2
    8000582e:	ffffd097          	auipc	ra,0xffffd
    80005832:	764080e7          	jalr	1892(ra) # 80002f92 <argint>
    return -1;
    80005836:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005838:	02054763          	bltz	a0,80005866 <sys_read+0x5c>
    8000583c:	fd840593          	addi	a1,s0,-40
    80005840:	4505                	li	a0,1
    80005842:	ffffd097          	auipc	ra,0xffffd
    80005846:	772080e7          	jalr	1906(ra) # 80002fb4 <argaddr>
    return -1;
    8000584a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000584c:	00054d63          	bltz	a0,80005866 <sys_read+0x5c>
  return fileread(f, p, n);
    80005850:	fe442603          	lw	a2,-28(s0)
    80005854:	fd843583          	ld	a1,-40(s0)
    80005858:	fe843503          	ld	a0,-24(s0)
    8000585c:	fffff097          	auipc	ra,0xfffff
    80005860:	48a080e7          	jalr	1162(ra) # 80004ce6 <fileread>
    80005864:	87aa                	mv	a5,a0
}
    80005866:	853e                	mv	a0,a5
    80005868:	70a2                	ld	ra,40(sp)
    8000586a:	7402                	ld	s0,32(sp)
    8000586c:	6145                	addi	sp,sp,48
    8000586e:	8082                	ret

0000000080005870 <sys_write>:
{
    80005870:	7179                	addi	sp,sp,-48
    80005872:	f406                	sd	ra,40(sp)
    80005874:	f022                	sd	s0,32(sp)
    80005876:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005878:	fe840613          	addi	a2,s0,-24
    8000587c:	4581                	li	a1,0
    8000587e:	4501                	li	a0,0
    80005880:	00000097          	auipc	ra,0x0
    80005884:	d28080e7          	jalr	-728(ra) # 800055a8 <argfd>
    return -1;
    80005888:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000588a:	04054163          	bltz	a0,800058cc <sys_write+0x5c>
    8000588e:	fe440593          	addi	a1,s0,-28
    80005892:	4509                	li	a0,2
    80005894:	ffffd097          	auipc	ra,0xffffd
    80005898:	6fe080e7          	jalr	1790(ra) # 80002f92 <argint>
    return -1;
    8000589c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000589e:	02054763          	bltz	a0,800058cc <sys_write+0x5c>
    800058a2:	fd840593          	addi	a1,s0,-40
    800058a6:	4505                	li	a0,1
    800058a8:	ffffd097          	auipc	ra,0xffffd
    800058ac:	70c080e7          	jalr	1804(ra) # 80002fb4 <argaddr>
    return -1;
    800058b0:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800058b2:	00054d63          	bltz	a0,800058cc <sys_write+0x5c>
  return filewrite(f, p, n);
    800058b6:	fe442603          	lw	a2,-28(s0)
    800058ba:	fd843583          	ld	a1,-40(s0)
    800058be:	fe843503          	ld	a0,-24(s0)
    800058c2:	fffff097          	auipc	ra,0xfffff
    800058c6:	4e6080e7          	jalr	1254(ra) # 80004da8 <filewrite>
    800058ca:	87aa                	mv	a5,a0
}
    800058cc:	853e                	mv	a0,a5
    800058ce:	70a2                	ld	ra,40(sp)
    800058d0:	7402                	ld	s0,32(sp)
    800058d2:	6145                	addi	sp,sp,48
    800058d4:	8082                	ret

00000000800058d6 <sys_close>:
{
    800058d6:	1101                	addi	sp,sp,-32
    800058d8:	ec06                	sd	ra,24(sp)
    800058da:	e822                	sd	s0,16(sp)
    800058dc:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    800058de:	fe040613          	addi	a2,s0,-32
    800058e2:	fec40593          	addi	a1,s0,-20
    800058e6:	4501                	li	a0,0
    800058e8:	00000097          	auipc	ra,0x0
    800058ec:	cc0080e7          	jalr	-832(ra) # 800055a8 <argfd>
    return -1;
    800058f0:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800058f2:	02054463          	bltz	a0,8000591a <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    800058f6:	ffffc097          	auipc	ra,0xffffc
    800058fa:	0a0080e7          	jalr	160(ra) # 80001996 <myproc>
    800058fe:	fec42783          	lw	a5,-20(s0)
    80005902:	07e9                	addi	a5,a5,26
    80005904:	078e                	slli	a5,a5,0x3
    80005906:	953e                	add	a0,a0,a5
    80005908:	00053023          	sd	zero,0(a0)
  fileclose(f);
    8000590c:	fe043503          	ld	a0,-32(s0)
    80005910:	fffff097          	auipc	ra,0xfffff
    80005914:	29c080e7          	jalr	668(ra) # 80004bac <fileclose>
  return 0;
    80005918:	4781                	li	a5,0
}
    8000591a:	853e                	mv	a0,a5
    8000591c:	60e2                	ld	ra,24(sp)
    8000591e:	6442                	ld	s0,16(sp)
    80005920:	6105                	addi	sp,sp,32
    80005922:	8082                	ret

0000000080005924 <sys_fstat>:
{
    80005924:	1101                	addi	sp,sp,-32
    80005926:	ec06                	sd	ra,24(sp)
    80005928:	e822                	sd	s0,16(sp)
    8000592a:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000592c:	fe840613          	addi	a2,s0,-24
    80005930:	4581                	li	a1,0
    80005932:	4501                	li	a0,0
    80005934:	00000097          	auipc	ra,0x0
    80005938:	c74080e7          	jalr	-908(ra) # 800055a8 <argfd>
    return -1;
    8000593c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000593e:	02054563          	bltz	a0,80005968 <sys_fstat+0x44>
    80005942:	fe040593          	addi	a1,s0,-32
    80005946:	4505                	li	a0,1
    80005948:	ffffd097          	auipc	ra,0xffffd
    8000594c:	66c080e7          	jalr	1644(ra) # 80002fb4 <argaddr>
    return -1;
    80005950:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005952:	00054b63          	bltz	a0,80005968 <sys_fstat+0x44>
  return filestat(f, st);
    80005956:	fe043583          	ld	a1,-32(s0)
    8000595a:	fe843503          	ld	a0,-24(s0)
    8000595e:	fffff097          	auipc	ra,0xfffff
    80005962:	316080e7          	jalr	790(ra) # 80004c74 <filestat>
    80005966:	87aa                	mv	a5,a0
}
    80005968:	853e                	mv	a0,a5
    8000596a:	60e2                	ld	ra,24(sp)
    8000596c:	6442                	ld	s0,16(sp)
    8000596e:	6105                	addi	sp,sp,32
    80005970:	8082                	ret

0000000080005972 <sys_link>:
{
    80005972:	7169                	addi	sp,sp,-304
    80005974:	f606                	sd	ra,296(sp)
    80005976:	f222                	sd	s0,288(sp)
    80005978:	ee26                	sd	s1,280(sp)
    8000597a:	ea4a                	sd	s2,272(sp)
    8000597c:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000597e:	08000613          	li	a2,128
    80005982:	ed040593          	addi	a1,s0,-304
    80005986:	4501                	li	a0,0
    80005988:	ffffd097          	auipc	ra,0xffffd
    8000598c:	64e080e7          	jalr	1614(ra) # 80002fd6 <argstr>
    return -1;
    80005990:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005992:	10054e63          	bltz	a0,80005aae <sys_link+0x13c>
    80005996:	08000613          	li	a2,128
    8000599a:	f5040593          	addi	a1,s0,-176
    8000599e:	4505                	li	a0,1
    800059a0:	ffffd097          	auipc	ra,0xffffd
    800059a4:	636080e7          	jalr	1590(ra) # 80002fd6 <argstr>
    return -1;
    800059a8:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800059aa:	10054263          	bltz	a0,80005aae <sys_link+0x13c>
  begin_op();
    800059ae:	fffff097          	auipc	ra,0xfffff
    800059b2:	d36080e7          	jalr	-714(ra) # 800046e4 <begin_op>
  if((ip = namei(old)) == 0){
    800059b6:	ed040513          	addi	a0,s0,-304
    800059ba:	fffff097          	auipc	ra,0xfffff
    800059be:	b0a080e7          	jalr	-1270(ra) # 800044c4 <namei>
    800059c2:	84aa                	mv	s1,a0
    800059c4:	c551                	beqz	a0,80005a50 <sys_link+0xde>
  ilock(ip);
    800059c6:	ffffe097          	auipc	ra,0xffffe
    800059ca:	342080e7          	jalr	834(ra) # 80003d08 <ilock>
  if(ip->type == T_DIR){
    800059ce:	04449703          	lh	a4,68(s1)
    800059d2:	4785                	li	a5,1
    800059d4:	08f70463          	beq	a4,a5,80005a5c <sys_link+0xea>
  ip->nlink++;
    800059d8:	04a4d783          	lhu	a5,74(s1)
    800059dc:	2785                	addiw	a5,a5,1
    800059de:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800059e2:	8526                	mv	a0,s1
    800059e4:	ffffe097          	auipc	ra,0xffffe
    800059e8:	258080e7          	jalr	600(ra) # 80003c3c <iupdate>
  iunlock(ip);
    800059ec:	8526                	mv	a0,s1
    800059ee:	ffffe097          	auipc	ra,0xffffe
    800059f2:	3dc080e7          	jalr	988(ra) # 80003dca <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    800059f6:	fd040593          	addi	a1,s0,-48
    800059fa:	f5040513          	addi	a0,s0,-176
    800059fe:	fffff097          	auipc	ra,0xfffff
    80005a02:	ae4080e7          	jalr	-1308(ra) # 800044e2 <nameiparent>
    80005a06:	892a                	mv	s2,a0
    80005a08:	c935                	beqz	a0,80005a7c <sys_link+0x10a>
  ilock(dp);
    80005a0a:	ffffe097          	auipc	ra,0xffffe
    80005a0e:	2fe080e7          	jalr	766(ra) # 80003d08 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005a12:	00092703          	lw	a4,0(s2)
    80005a16:	409c                	lw	a5,0(s1)
    80005a18:	04f71d63          	bne	a4,a5,80005a72 <sys_link+0x100>
    80005a1c:	40d0                	lw	a2,4(s1)
    80005a1e:	fd040593          	addi	a1,s0,-48
    80005a22:	854a                	mv	a0,s2
    80005a24:	fffff097          	auipc	ra,0xfffff
    80005a28:	9de080e7          	jalr	-1570(ra) # 80004402 <dirlink>
    80005a2c:	04054363          	bltz	a0,80005a72 <sys_link+0x100>
  iunlockput(dp);
    80005a30:	854a                	mv	a0,s2
    80005a32:	ffffe097          	auipc	ra,0xffffe
    80005a36:	538080e7          	jalr	1336(ra) # 80003f6a <iunlockput>
  iput(ip);
    80005a3a:	8526                	mv	a0,s1
    80005a3c:	ffffe097          	auipc	ra,0xffffe
    80005a40:	486080e7          	jalr	1158(ra) # 80003ec2 <iput>
  end_op();
    80005a44:	fffff097          	auipc	ra,0xfffff
    80005a48:	d1e080e7          	jalr	-738(ra) # 80004762 <end_op>
  return 0;
    80005a4c:	4781                	li	a5,0
    80005a4e:	a085                	j	80005aae <sys_link+0x13c>
    end_op();
    80005a50:	fffff097          	auipc	ra,0xfffff
    80005a54:	d12080e7          	jalr	-750(ra) # 80004762 <end_op>
    return -1;
    80005a58:	57fd                	li	a5,-1
    80005a5a:	a891                	j	80005aae <sys_link+0x13c>
    iunlockput(ip);
    80005a5c:	8526                	mv	a0,s1
    80005a5e:	ffffe097          	auipc	ra,0xffffe
    80005a62:	50c080e7          	jalr	1292(ra) # 80003f6a <iunlockput>
    end_op();
    80005a66:	fffff097          	auipc	ra,0xfffff
    80005a6a:	cfc080e7          	jalr	-772(ra) # 80004762 <end_op>
    return -1;
    80005a6e:	57fd                	li	a5,-1
    80005a70:	a83d                	j	80005aae <sys_link+0x13c>
    iunlockput(dp);
    80005a72:	854a                	mv	a0,s2
    80005a74:	ffffe097          	auipc	ra,0xffffe
    80005a78:	4f6080e7          	jalr	1270(ra) # 80003f6a <iunlockput>
  ilock(ip);
    80005a7c:	8526                	mv	a0,s1
    80005a7e:	ffffe097          	auipc	ra,0xffffe
    80005a82:	28a080e7          	jalr	650(ra) # 80003d08 <ilock>
  ip->nlink--;
    80005a86:	04a4d783          	lhu	a5,74(s1)
    80005a8a:	37fd                	addiw	a5,a5,-1
    80005a8c:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005a90:	8526                	mv	a0,s1
    80005a92:	ffffe097          	auipc	ra,0xffffe
    80005a96:	1aa080e7          	jalr	426(ra) # 80003c3c <iupdate>
  iunlockput(ip);
    80005a9a:	8526                	mv	a0,s1
    80005a9c:	ffffe097          	auipc	ra,0xffffe
    80005aa0:	4ce080e7          	jalr	1230(ra) # 80003f6a <iunlockput>
  end_op();
    80005aa4:	fffff097          	auipc	ra,0xfffff
    80005aa8:	cbe080e7          	jalr	-834(ra) # 80004762 <end_op>
  return -1;
    80005aac:	57fd                	li	a5,-1
}
    80005aae:	853e                	mv	a0,a5
    80005ab0:	70b2                	ld	ra,296(sp)
    80005ab2:	7412                	ld	s0,288(sp)
    80005ab4:	64f2                	ld	s1,280(sp)
    80005ab6:	6952                	ld	s2,272(sp)
    80005ab8:	6155                	addi	sp,sp,304
    80005aba:	8082                	ret

0000000080005abc <sys_unlink>:
{
    80005abc:	7151                	addi	sp,sp,-240
    80005abe:	f586                	sd	ra,232(sp)
    80005ac0:	f1a2                	sd	s0,224(sp)
    80005ac2:	eda6                	sd	s1,216(sp)
    80005ac4:	e9ca                	sd	s2,208(sp)
    80005ac6:	e5ce                	sd	s3,200(sp)
    80005ac8:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005aca:	08000613          	li	a2,128
    80005ace:	f3040593          	addi	a1,s0,-208
    80005ad2:	4501                	li	a0,0
    80005ad4:	ffffd097          	auipc	ra,0xffffd
    80005ad8:	502080e7          	jalr	1282(ra) # 80002fd6 <argstr>
    80005adc:	18054163          	bltz	a0,80005c5e <sys_unlink+0x1a2>
  begin_op();
    80005ae0:	fffff097          	auipc	ra,0xfffff
    80005ae4:	c04080e7          	jalr	-1020(ra) # 800046e4 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005ae8:	fb040593          	addi	a1,s0,-80
    80005aec:	f3040513          	addi	a0,s0,-208
    80005af0:	fffff097          	auipc	ra,0xfffff
    80005af4:	9f2080e7          	jalr	-1550(ra) # 800044e2 <nameiparent>
    80005af8:	84aa                	mv	s1,a0
    80005afa:	c979                	beqz	a0,80005bd0 <sys_unlink+0x114>
  ilock(dp);
    80005afc:	ffffe097          	auipc	ra,0xffffe
    80005b00:	20c080e7          	jalr	524(ra) # 80003d08 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005b04:	00003597          	auipc	a1,0x3
    80005b08:	cec58593          	addi	a1,a1,-788 # 800087f0 <syscalls+0x2c0>
    80005b0c:	fb040513          	addi	a0,s0,-80
    80005b10:	ffffe097          	auipc	ra,0xffffe
    80005b14:	6c2080e7          	jalr	1730(ra) # 800041d2 <namecmp>
    80005b18:	14050a63          	beqz	a0,80005c6c <sys_unlink+0x1b0>
    80005b1c:	00003597          	auipc	a1,0x3
    80005b20:	cdc58593          	addi	a1,a1,-804 # 800087f8 <syscalls+0x2c8>
    80005b24:	fb040513          	addi	a0,s0,-80
    80005b28:	ffffe097          	auipc	ra,0xffffe
    80005b2c:	6aa080e7          	jalr	1706(ra) # 800041d2 <namecmp>
    80005b30:	12050e63          	beqz	a0,80005c6c <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005b34:	f2c40613          	addi	a2,s0,-212
    80005b38:	fb040593          	addi	a1,s0,-80
    80005b3c:	8526                	mv	a0,s1
    80005b3e:	ffffe097          	auipc	ra,0xffffe
    80005b42:	6ae080e7          	jalr	1710(ra) # 800041ec <dirlookup>
    80005b46:	892a                	mv	s2,a0
    80005b48:	12050263          	beqz	a0,80005c6c <sys_unlink+0x1b0>
  ilock(ip);
    80005b4c:	ffffe097          	auipc	ra,0xffffe
    80005b50:	1bc080e7          	jalr	444(ra) # 80003d08 <ilock>
  if(ip->nlink < 1)
    80005b54:	04a91783          	lh	a5,74(s2)
    80005b58:	08f05263          	blez	a5,80005bdc <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005b5c:	04491703          	lh	a4,68(s2)
    80005b60:	4785                	li	a5,1
    80005b62:	08f70563          	beq	a4,a5,80005bec <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005b66:	4641                	li	a2,16
    80005b68:	4581                	li	a1,0
    80005b6a:	fc040513          	addi	a0,s0,-64
    80005b6e:	ffffb097          	auipc	ra,0xffffb
    80005b72:	15e080e7          	jalr	350(ra) # 80000ccc <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005b76:	4741                	li	a4,16
    80005b78:	f2c42683          	lw	a3,-212(s0)
    80005b7c:	fc040613          	addi	a2,s0,-64
    80005b80:	4581                	li	a1,0
    80005b82:	8526                	mv	a0,s1
    80005b84:	ffffe097          	auipc	ra,0xffffe
    80005b88:	530080e7          	jalr	1328(ra) # 800040b4 <writei>
    80005b8c:	47c1                	li	a5,16
    80005b8e:	0af51563          	bne	a0,a5,80005c38 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005b92:	04491703          	lh	a4,68(s2)
    80005b96:	4785                	li	a5,1
    80005b98:	0af70863          	beq	a4,a5,80005c48 <sys_unlink+0x18c>
  iunlockput(dp);
    80005b9c:	8526                	mv	a0,s1
    80005b9e:	ffffe097          	auipc	ra,0xffffe
    80005ba2:	3cc080e7          	jalr	972(ra) # 80003f6a <iunlockput>
  ip->nlink--;
    80005ba6:	04a95783          	lhu	a5,74(s2)
    80005baa:	37fd                	addiw	a5,a5,-1
    80005bac:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005bb0:	854a                	mv	a0,s2
    80005bb2:	ffffe097          	auipc	ra,0xffffe
    80005bb6:	08a080e7          	jalr	138(ra) # 80003c3c <iupdate>
  iunlockput(ip);
    80005bba:	854a                	mv	a0,s2
    80005bbc:	ffffe097          	auipc	ra,0xffffe
    80005bc0:	3ae080e7          	jalr	942(ra) # 80003f6a <iunlockput>
  end_op();
    80005bc4:	fffff097          	auipc	ra,0xfffff
    80005bc8:	b9e080e7          	jalr	-1122(ra) # 80004762 <end_op>
  return 0;
    80005bcc:	4501                	li	a0,0
    80005bce:	a84d                	j	80005c80 <sys_unlink+0x1c4>
    end_op();
    80005bd0:	fffff097          	auipc	ra,0xfffff
    80005bd4:	b92080e7          	jalr	-1134(ra) # 80004762 <end_op>
    return -1;
    80005bd8:	557d                	li	a0,-1
    80005bda:	a05d                	j	80005c80 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005bdc:	00003517          	auipc	a0,0x3
    80005be0:	c4450513          	addi	a0,a0,-956 # 80008820 <syscalls+0x2f0>
    80005be4:	ffffb097          	auipc	ra,0xffffb
    80005be8:	956080e7          	jalr	-1706(ra) # 8000053a <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005bec:	04c92703          	lw	a4,76(s2)
    80005bf0:	02000793          	li	a5,32
    80005bf4:	f6e7f9e3          	bgeu	a5,a4,80005b66 <sys_unlink+0xaa>
    80005bf8:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005bfc:	4741                	li	a4,16
    80005bfe:	86ce                	mv	a3,s3
    80005c00:	f1840613          	addi	a2,s0,-232
    80005c04:	4581                	li	a1,0
    80005c06:	854a                	mv	a0,s2
    80005c08:	ffffe097          	auipc	ra,0xffffe
    80005c0c:	3b4080e7          	jalr	948(ra) # 80003fbc <readi>
    80005c10:	47c1                	li	a5,16
    80005c12:	00f51b63          	bne	a0,a5,80005c28 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005c16:	f1845783          	lhu	a5,-232(s0)
    80005c1a:	e7a1                	bnez	a5,80005c62 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005c1c:	29c1                	addiw	s3,s3,16
    80005c1e:	04c92783          	lw	a5,76(s2)
    80005c22:	fcf9ede3          	bltu	s3,a5,80005bfc <sys_unlink+0x140>
    80005c26:	b781                	j	80005b66 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005c28:	00003517          	auipc	a0,0x3
    80005c2c:	c1050513          	addi	a0,a0,-1008 # 80008838 <syscalls+0x308>
    80005c30:	ffffb097          	auipc	ra,0xffffb
    80005c34:	90a080e7          	jalr	-1782(ra) # 8000053a <panic>
    panic("unlink: writei");
    80005c38:	00003517          	auipc	a0,0x3
    80005c3c:	c1850513          	addi	a0,a0,-1000 # 80008850 <syscalls+0x320>
    80005c40:	ffffb097          	auipc	ra,0xffffb
    80005c44:	8fa080e7          	jalr	-1798(ra) # 8000053a <panic>
    dp->nlink--;
    80005c48:	04a4d783          	lhu	a5,74(s1)
    80005c4c:	37fd                	addiw	a5,a5,-1
    80005c4e:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005c52:	8526                	mv	a0,s1
    80005c54:	ffffe097          	auipc	ra,0xffffe
    80005c58:	fe8080e7          	jalr	-24(ra) # 80003c3c <iupdate>
    80005c5c:	b781                	j	80005b9c <sys_unlink+0xe0>
    return -1;
    80005c5e:	557d                	li	a0,-1
    80005c60:	a005                	j	80005c80 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005c62:	854a                	mv	a0,s2
    80005c64:	ffffe097          	auipc	ra,0xffffe
    80005c68:	306080e7          	jalr	774(ra) # 80003f6a <iunlockput>
  iunlockput(dp);
    80005c6c:	8526                	mv	a0,s1
    80005c6e:	ffffe097          	auipc	ra,0xffffe
    80005c72:	2fc080e7          	jalr	764(ra) # 80003f6a <iunlockput>
  end_op();
    80005c76:	fffff097          	auipc	ra,0xfffff
    80005c7a:	aec080e7          	jalr	-1300(ra) # 80004762 <end_op>
  return -1;
    80005c7e:	557d                	li	a0,-1
}
    80005c80:	70ae                	ld	ra,232(sp)
    80005c82:	740e                	ld	s0,224(sp)
    80005c84:	64ee                	ld	s1,216(sp)
    80005c86:	694e                	ld	s2,208(sp)
    80005c88:	69ae                	ld	s3,200(sp)
    80005c8a:	616d                	addi	sp,sp,240
    80005c8c:	8082                	ret

0000000080005c8e <sys_open>:

uint64
sys_open(void)
{
    80005c8e:	7131                	addi	sp,sp,-192
    80005c90:	fd06                	sd	ra,184(sp)
    80005c92:	f922                	sd	s0,176(sp)
    80005c94:	f526                	sd	s1,168(sp)
    80005c96:	f14a                	sd	s2,160(sp)
    80005c98:	ed4e                	sd	s3,152(sp)
    80005c9a:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005c9c:	08000613          	li	a2,128
    80005ca0:	f5040593          	addi	a1,s0,-176
    80005ca4:	4501                	li	a0,0
    80005ca6:	ffffd097          	auipc	ra,0xffffd
    80005caa:	330080e7          	jalr	816(ra) # 80002fd6 <argstr>
    return -1;
    80005cae:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005cb0:	0c054163          	bltz	a0,80005d72 <sys_open+0xe4>
    80005cb4:	f4c40593          	addi	a1,s0,-180
    80005cb8:	4505                	li	a0,1
    80005cba:	ffffd097          	auipc	ra,0xffffd
    80005cbe:	2d8080e7          	jalr	728(ra) # 80002f92 <argint>
    80005cc2:	0a054863          	bltz	a0,80005d72 <sys_open+0xe4>

  begin_op();
    80005cc6:	fffff097          	auipc	ra,0xfffff
    80005cca:	a1e080e7          	jalr	-1506(ra) # 800046e4 <begin_op>

  if(omode & O_CREATE){
    80005cce:	f4c42783          	lw	a5,-180(s0)
    80005cd2:	2007f793          	andi	a5,a5,512
    80005cd6:	cbdd                	beqz	a5,80005d8c <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005cd8:	4681                	li	a3,0
    80005cda:	4601                	li	a2,0
    80005cdc:	4589                	li	a1,2
    80005cde:	f5040513          	addi	a0,s0,-176
    80005ce2:	00000097          	auipc	ra,0x0
    80005ce6:	970080e7          	jalr	-1680(ra) # 80005652 <create>
    80005cea:	892a                	mv	s2,a0
    if(ip == 0){
    80005cec:	c959                	beqz	a0,80005d82 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005cee:	04491703          	lh	a4,68(s2)
    80005cf2:	478d                	li	a5,3
    80005cf4:	00f71763          	bne	a4,a5,80005d02 <sys_open+0x74>
    80005cf8:	04695703          	lhu	a4,70(s2)
    80005cfc:	47a5                	li	a5,9
    80005cfe:	0ce7ec63          	bltu	a5,a4,80005dd6 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005d02:	fffff097          	auipc	ra,0xfffff
    80005d06:	dee080e7          	jalr	-530(ra) # 80004af0 <filealloc>
    80005d0a:	89aa                	mv	s3,a0
    80005d0c:	10050263          	beqz	a0,80005e10 <sys_open+0x182>
    80005d10:	00000097          	auipc	ra,0x0
    80005d14:	900080e7          	jalr	-1792(ra) # 80005610 <fdalloc>
    80005d18:	84aa                	mv	s1,a0
    80005d1a:	0e054663          	bltz	a0,80005e06 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005d1e:	04491703          	lh	a4,68(s2)
    80005d22:	478d                	li	a5,3
    80005d24:	0cf70463          	beq	a4,a5,80005dec <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005d28:	4789                	li	a5,2
    80005d2a:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005d2e:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005d32:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005d36:	f4c42783          	lw	a5,-180(s0)
    80005d3a:	0017c713          	xori	a4,a5,1
    80005d3e:	8b05                	andi	a4,a4,1
    80005d40:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005d44:	0037f713          	andi	a4,a5,3
    80005d48:	00e03733          	snez	a4,a4
    80005d4c:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005d50:	4007f793          	andi	a5,a5,1024
    80005d54:	c791                	beqz	a5,80005d60 <sys_open+0xd2>
    80005d56:	04491703          	lh	a4,68(s2)
    80005d5a:	4789                	li	a5,2
    80005d5c:	08f70f63          	beq	a4,a5,80005dfa <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005d60:	854a                	mv	a0,s2
    80005d62:	ffffe097          	auipc	ra,0xffffe
    80005d66:	068080e7          	jalr	104(ra) # 80003dca <iunlock>
  end_op();
    80005d6a:	fffff097          	auipc	ra,0xfffff
    80005d6e:	9f8080e7          	jalr	-1544(ra) # 80004762 <end_op>

  return fd;
}
    80005d72:	8526                	mv	a0,s1
    80005d74:	70ea                	ld	ra,184(sp)
    80005d76:	744a                	ld	s0,176(sp)
    80005d78:	74aa                	ld	s1,168(sp)
    80005d7a:	790a                	ld	s2,160(sp)
    80005d7c:	69ea                	ld	s3,152(sp)
    80005d7e:	6129                	addi	sp,sp,192
    80005d80:	8082                	ret
      end_op();
    80005d82:	fffff097          	auipc	ra,0xfffff
    80005d86:	9e0080e7          	jalr	-1568(ra) # 80004762 <end_op>
      return -1;
    80005d8a:	b7e5                	j	80005d72 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005d8c:	f5040513          	addi	a0,s0,-176
    80005d90:	ffffe097          	auipc	ra,0xffffe
    80005d94:	734080e7          	jalr	1844(ra) # 800044c4 <namei>
    80005d98:	892a                	mv	s2,a0
    80005d9a:	c905                	beqz	a0,80005dca <sys_open+0x13c>
    ilock(ip);
    80005d9c:	ffffe097          	auipc	ra,0xffffe
    80005da0:	f6c080e7          	jalr	-148(ra) # 80003d08 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005da4:	04491703          	lh	a4,68(s2)
    80005da8:	4785                	li	a5,1
    80005daa:	f4f712e3          	bne	a4,a5,80005cee <sys_open+0x60>
    80005dae:	f4c42783          	lw	a5,-180(s0)
    80005db2:	dba1                	beqz	a5,80005d02 <sys_open+0x74>
      iunlockput(ip);
    80005db4:	854a                	mv	a0,s2
    80005db6:	ffffe097          	auipc	ra,0xffffe
    80005dba:	1b4080e7          	jalr	436(ra) # 80003f6a <iunlockput>
      end_op();
    80005dbe:	fffff097          	auipc	ra,0xfffff
    80005dc2:	9a4080e7          	jalr	-1628(ra) # 80004762 <end_op>
      return -1;
    80005dc6:	54fd                	li	s1,-1
    80005dc8:	b76d                	j	80005d72 <sys_open+0xe4>
      end_op();
    80005dca:	fffff097          	auipc	ra,0xfffff
    80005dce:	998080e7          	jalr	-1640(ra) # 80004762 <end_op>
      return -1;
    80005dd2:	54fd                	li	s1,-1
    80005dd4:	bf79                	j	80005d72 <sys_open+0xe4>
    iunlockput(ip);
    80005dd6:	854a                	mv	a0,s2
    80005dd8:	ffffe097          	auipc	ra,0xffffe
    80005ddc:	192080e7          	jalr	402(ra) # 80003f6a <iunlockput>
    end_op();
    80005de0:	fffff097          	auipc	ra,0xfffff
    80005de4:	982080e7          	jalr	-1662(ra) # 80004762 <end_op>
    return -1;
    80005de8:	54fd                	li	s1,-1
    80005dea:	b761                	j	80005d72 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005dec:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005df0:	04691783          	lh	a5,70(s2)
    80005df4:	02f99223          	sh	a5,36(s3)
    80005df8:	bf2d                	j	80005d32 <sys_open+0xa4>
    itrunc(ip);
    80005dfa:	854a                	mv	a0,s2
    80005dfc:	ffffe097          	auipc	ra,0xffffe
    80005e00:	01a080e7          	jalr	26(ra) # 80003e16 <itrunc>
    80005e04:	bfb1                	j	80005d60 <sys_open+0xd2>
      fileclose(f);
    80005e06:	854e                	mv	a0,s3
    80005e08:	fffff097          	auipc	ra,0xfffff
    80005e0c:	da4080e7          	jalr	-604(ra) # 80004bac <fileclose>
    iunlockput(ip);
    80005e10:	854a                	mv	a0,s2
    80005e12:	ffffe097          	auipc	ra,0xffffe
    80005e16:	158080e7          	jalr	344(ra) # 80003f6a <iunlockput>
    end_op();
    80005e1a:	fffff097          	auipc	ra,0xfffff
    80005e1e:	948080e7          	jalr	-1720(ra) # 80004762 <end_op>
    return -1;
    80005e22:	54fd                	li	s1,-1
    80005e24:	b7b9                	j	80005d72 <sys_open+0xe4>

0000000080005e26 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005e26:	7175                	addi	sp,sp,-144
    80005e28:	e506                	sd	ra,136(sp)
    80005e2a:	e122                	sd	s0,128(sp)
    80005e2c:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005e2e:	fffff097          	auipc	ra,0xfffff
    80005e32:	8b6080e7          	jalr	-1866(ra) # 800046e4 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005e36:	08000613          	li	a2,128
    80005e3a:	f7040593          	addi	a1,s0,-144
    80005e3e:	4501                	li	a0,0
    80005e40:	ffffd097          	auipc	ra,0xffffd
    80005e44:	196080e7          	jalr	406(ra) # 80002fd6 <argstr>
    80005e48:	02054963          	bltz	a0,80005e7a <sys_mkdir+0x54>
    80005e4c:	4681                	li	a3,0
    80005e4e:	4601                	li	a2,0
    80005e50:	4585                	li	a1,1
    80005e52:	f7040513          	addi	a0,s0,-144
    80005e56:	fffff097          	auipc	ra,0xfffff
    80005e5a:	7fc080e7          	jalr	2044(ra) # 80005652 <create>
    80005e5e:	cd11                	beqz	a0,80005e7a <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005e60:	ffffe097          	auipc	ra,0xffffe
    80005e64:	10a080e7          	jalr	266(ra) # 80003f6a <iunlockput>
  end_op();
    80005e68:	fffff097          	auipc	ra,0xfffff
    80005e6c:	8fa080e7          	jalr	-1798(ra) # 80004762 <end_op>
  return 0;
    80005e70:	4501                	li	a0,0
}
    80005e72:	60aa                	ld	ra,136(sp)
    80005e74:	640a                	ld	s0,128(sp)
    80005e76:	6149                	addi	sp,sp,144
    80005e78:	8082                	ret
    end_op();
    80005e7a:	fffff097          	auipc	ra,0xfffff
    80005e7e:	8e8080e7          	jalr	-1816(ra) # 80004762 <end_op>
    return -1;
    80005e82:	557d                	li	a0,-1
    80005e84:	b7fd                	j	80005e72 <sys_mkdir+0x4c>

0000000080005e86 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005e86:	7135                	addi	sp,sp,-160
    80005e88:	ed06                	sd	ra,152(sp)
    80005e8a:	e922                	sd	s0,144(sp)
    80005e8c:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005e8e:	fffff097          	auipc	ra,0xfffff
    80005e92:	856080e7          	jalr	-1962(ra) # 800046e4 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005e96:	08000613          	li	a2,128
    80005e9a:	f7040593          	addi	a1,s0,-144
    80005e9e:	4501                	li	a0,0
    80005ea0:	ffffd097          	auipc	ra,0xffffd
    80005ea4:	136080e7          	jalr	310(ra) # 80002fd6 <argstr>
    80005ea8:	04054a63          	bltz	a0,80005efc <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005eac:	f6c40593          	addi	a1,s0,-148
    80005eb0:	4505                	li	a0,1
    80005eb2:	ffffd097          	auipc	ra,0xffffd
    80005eb6:	0e0080e7          	jalr	224(ra) # 80002f92 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005eba:	04054163          	bltz	a0,80005efc <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005ebe:	f6840593          	addi	a1,s0,-152
    80005ec2:	4509                	li	a0,2
    80005ec4:	ffffd097          	auipc	ra,0xffffd
    80005ec8:	0ce080e7          	jalr	206(ra) # 80002f92 <argint>
     argint(1, &major) < 0 ||
    80005ecc:	02054863          	bltz	a0,80005efc <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005ed0:	f6841683          	lh	a3,-152(s0)
    80005ed4:	f6c41603          	lh	a2,-148(s0)
    80005ed8:	458d                	li	a1,3
    80005eda:	f7040513          	addi	a0,s0,-144
    80005ede:	fffff097          	auipc	ra,0xfffff
    80005ee2:	774080e7          	jalr	1908(ra) # 80005652 <create>
     argint(2, &minor) < 0 ||
    80005ee6:	c919                	beqz	a0,80005efc <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005ee8:	ffffe097          	auipc	ra,0xffffe
    80005eec:	082080e7          	jalr	130(ra) # 80003f6a <iunlockput>
  end_op();
    80005ef0:	fffff097          	auipc	ra,0xfffff
    80005ef4:	872080e7          	jalr	-1934(ra) # 80004762 <end_op>
  return 0;
    80005ef8:	4501                	li	a0,0
    80005efa:	a031                	j	80005f06 <sys_mknod+0x80>
    end_op();
    80005efc:	fffff097          	auipc	ra,0xfffff
    80005f00:	866080e7          	jalr	-1946(ra) # 80004762 <end_op>
    return -1;
    80005f04:	557d                	li	a0,-1
}
    80005f06:	60ea                	ld	ra,152(sp)
    80005f08:	644a                	ld	s0,144(sp)
    80005f0a:	610d                	addi	sp,sp,160
    80005f0c:	8082                	ret

0000000080005f0e <sys_chdir>:

uint64
sys_chdir(void)
{
    80005f0e:	7135                	addi	sp,sp,-160
    80005f10:	ed06                	sd	ra,152(sp)
    80005f12:	e922                	sd	s0,144(sp)
    80005f14:	e526                	sd	s1,136(sp)
    80005f16:	e14a                	sd	s2,128(sp)
    80005f18:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005f1a:	ffffc097          	auipc	ra,0xffffc
    80005f1e:	a7c080e7          	jalr	-1412(ra) # 80001996 <myproc>
    80005f22:	892a                	mv	s2,a0
  
  begin_op();
    80005f24:	ffffe097          	auipc	ra,0xffffe
    80005f28:	7c0080e7          	jalr	1984(ra) # 800046e4 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005f2c:	08000613          	li	a2,128
    80005f30:	f6040593          	addi	a1,s0,-160
    80005f34:	4501                	li	a0,0
    80005f36:	ffffd097          	auipc	ra,0xffffd
    80005f3a:	0a0080e7          	jalr	160(ra) # 80002fd6 <argstr>
    80005f3e:	04054b63          	bltz	a0,80005f94 <sys_chdir+0x86>
    80005f42:	f6040513          	addi	a0,s0,-160
    80005f46:	ffffe097          	auipc	ra,0xffffe
    80005f4a:	57e080e7          	jalr	1406(ra) # 800044c4 <namei>
    80005f4e:	84aa                	mv	s1,a0
    80005f50:	c131                	beqz	a0,80005f94 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005f52:	ffffe097          	auipc	ra,0xffffe
    80005f56:	db6080e7          	jalr	-586(ra) # 80003d08 <ilock>
  if(ip->type != T_DIR){
    80005f5a:	04449703          	lh	a4,68(s1)
    80005f5e:	4785                	li	a5,1
    80005f60:	04f71063          	bne	a4,a5,80005fa0 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005f64:	8526                	mv	a0,s1
    80005f66:	ffffe097          	auipc	ra,0xffffe
    80005f6a:	e64080e7          	jalr	-412(ra) # 80003dca <iunlock>
  iput(p->cwd);
    80005f6e:	15093503          	ld	a0,336(s2)
    80005f72:	ffffe097          	auipc	ra,0xffffe
    80005f76:	f50080e7          	jalr	-176(ra) # 80003ec2 <iput>
  end_op();
    80005f7a:	ffffe097          	auipc	ra,0xffffe
    80005f7e:	7e8080e7          	jalr	2024(ra) # 80004762 <end_op>
  p->cwd = ip;
    80005f82:	14993823          	sd	s1,336(s2)
  return 0;
    80005f86:	4501                	li	a0,0
}
    80005f88:	60ea                	ld	ra,152(sp)
    80005f8a:	644a                	ld	s0,144(sp)
    80005f8c:	64aa                	ld	s1,136(sp)
    80005f8e:	690a                	ld	s2,128(sp)
    80005f90:	610d                	addi	sp,sp,160
    80005f92:	8082                	ret
    end_op();
    80005f94:	ffffe097          	auipc	ra,0xffffe
    80005f98:	7ce080e7          	jalr	1998(ra) # 80004762 <end_op>
    return -1;
    80005f9c:	557d                	li	a0,-1
    80005f9e:	b7ed                	j	80005f88 <sys_chdir+0x7a>
    iunlockput(ip);
    80005fa0:	8526                	mv	a0,s1
    80005fa2:	ffffe097          	auipc	ra,0xffffe
    80005fa6:	fc8080e7          	jalr	-56(ra) # 80003f6a <iunlockput>
    end_op();
    80005faa:	ffffe097          	auipc	ra,0xffffe
    80005fae:	7b8080e7          	jalr	1976(ra) # 80004762 <end_op>
    return -1;
    80005fb2:	557d                	li	a0,-1
    80005fb4:	bfd1                	j	80005f88 <sys_chdir+0x7a>

0000000080005fb6 <sys_exec>:

uint64
sys_exec(void)
{
    80005fb6:	7145                	addi	sp,sp,-464
    80005fb8:	e786                	sd	ra,456(sp)
    80005fba:	e3a2                	sd	s0,448(sp)
    80005fbc:	ff26                	sd	s1,440(sp)
    80005fbe:	fb4a                	sd	s2,432(sp)
    80005fc0:	f74e                	sd	s3,424(sp)
    80005fc2:	f352                	sd	s4,416(sp)
    80005fc4:	ef56                	sd	s5,408(sp)
    80005fc6:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005fc8:	08000613          	li	a2,128
    80005fcc:	f4040593          	addi	a1,s0,-192
    80005fd0:	4501                	li	a0,0
    80005fd2:	ffffd097          	auipc	ra,0xffffd
    80005fd6:	004080e7          	jalr	4(ra) # 80002fd6 <argstr>
    return -1;
    80005fda:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005fdc:	0c054b63          	bltz	a0,800060b2 <sys_exec+0xfc>
    80005fe0:	e3840593          	addi	a1,s0,-456
    80005fe4:	4505                	li	a0,1
    80005fe6:	ffffd097          	auipc	ra,0xffffd
    80005fea:	fce080e7          	jalr	-50(ra) # 80002fb4 <argaddr>
    80005fee:	0c054263          	bltz	a0,800060b2 <sys_exec+0xfc>
  }
  memset(argv, 0, sizeof(argv));
    80005ff2:	10000613          	li	a2,256
    80005ff6:	4581                	li	a1,0
    80005ff8:	e4040513          	addi	a0,s0,-448
    80005ffc:	ffffb097          	auipc	ra,0xffffb
    80006000:	cd0080e7          	jalr	-816(ra) # 80000ccc <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80006004:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80006008:	89a6                	mv	s3,s1
    8000600a:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    8000600c:	02000a13          	li	s4,32
    80006010:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80006014:	00391513          	slli	a0,s2,0x3
    80006018:	e3040593          	addi	a1,s0,-464
    8000601c:	e3843783          	ld	a5,-456(s0)
    80006020:	953e                	add	a0,a0,a5
    80006022:	ffffd097          	auipc	ra,0xffffd
    80006026:	ed6080e7          	jalr	-298(ra) # 80002ef8 <fetchaddr>
    8000602a:	02054a63          	bltz	a0,8000605e <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    8000602e:	e3043783          	ld	a5,-464(s0)
    80006032:	c3b9                	beqz	a5,80006078 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80006034:	ffffb097          	auipc	ra,0xffffb
    80006038:	aac080e7          	jalr	-1364(ra) # 80000ae0 <kalloc>
    8000603c:	85aa                	mv	a1,a0
    8000603e:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80006042:	cd11                	beqz	a0,8000605e <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80006044:	6605                	lui	a2,0x1
    80006046:	e3043503          	ld	a0,-464(s0)
    8000604a:	ffffd097          	auipc	ra,0xffffd
    8000604e:	f00080e7          	jalr	-256(ra) # 80002f4a <fetchstr>
    80006052:	00054663          	bltz	a0,8000605e <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80006056:	0905                	addi	s2,s2,1
    80006058:	09a1                	addi	s3,s3,8
    8000605a:	fb491be3          	bne	s2,s4,80006010 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000605e:	f4040913          	addi	s2,s0,-192
    80006062:	6088                	ld	a0,0(s1)
    80006064:	c531                	beqz	a0,800060b0 <sys_exec+0xfa>
    kfree(argv[i]);
    80006066:	ffffb097          	auipc	ra,0xffffb
    8000606a:	97c080e7          	jalr	-1668(ra) # 800009e2 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000606e:	04a1                	addi	s1,s1,8
    80006070:	ff2499e3          	bne	s1,s2,80006062 <sys_exec+0xac>
  return -1;
    80006074:	597d                	li	s2,-1
    80006076:	a835                	j	800060b2 <sys_exec+0xfc>
      argv[i] = 0;
    80006078:	0a8e                	slli	s5,s5,0x3
    8000607a:	fc0a8793          	addi	a5,s5,-64 # ffffffffffffefc0 <end+0xffffffff7ffd7fc0>
    8000607e:	00878ab3          	add	s5,a5,s0
    80006082:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80006086:	e4040593          	addi	a1,s0,-448
    8000608a:	f4040513          	addi	a0,s0,-192
    8000608e:	fffff097          	auipc	ra,0xfffff
    80006092:	172080e7          	jalr	370(ra) # 80005200 <exec>
    80006096:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006098:	f4040993          	addi	s3,s0,-192
    8000609c:	6088                	ld	a0,0(s1)
    8000609e:	c911                	beqz	a0,800060b2 <sys_exec+0xfc>
    kfree(argv[i]);
    800060a0:	ffffb097          	auipc	ra,0xffffb
    800060a4:	942080e7          	jalr	-1726(ra) # 800009e2 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800060a8:	04a1                	addi	s1,s1,8
    800060aa:	ff3499e3          	bne	s1,s3,8000609c <sys_exec+0xe6>
    800060ae:	a011                	j	800060b2 <sys_exec+0xfc>
  return -1;
    800060b0:	597d                	li	s2,-1
}
    800060b2:	854a                	mv	a0,s2
    800060b4:	60be                	ld	ra,456(sp)
    800060b6:	641e                	ld	s0,448(sp)
    800060b8:	74fa                	ld	s1,440(sp)
    800060ba:	795a                	ld	s2,432(sp)
    800060bc:	79ba                	ld	s3,424(sp)
    800060be:	7a1a                	ld	s4,416(sp)
    800060c0:	6afa                	ld	s5,408(sp)
    800060c2:	6179                	addi	sp,sp,464
    800060c4:	8082                	ret

00000000800060c6 <sys_pipe>:

uint64
sys_pipe(void)
{
    800060c6:	7139                	addi	sp,sp,-64
    800060c8:	fc06                	sd	ra,56(sp)
    800060ca:	f822                	sd	s0,48(sp)
    800060cc:	f426                	sd	s1,40(sp)
    800060ce:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    800060d0:	ffffc097          	auipc	ra,0xffffc
    800060d4:	8c6080e7          	jalr	-1850(ra) # 80001996 <myproc>
    800060d8:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    800060da:	fd840593          	addi	a1,s0,-40
    800060de:	4501                	li	a0,0
    800060e0:	ffffd097          	auipc	ra,0xffffd
    800060e4:	ed4080e7          	jalr	-300(ra) # 80002fb4 <argaddr>
    return -1;
    800060e8:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    800060ea:	0e054063          	bltz	a0,800061ca <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    800060ee:	fc840593          	addi	a1,s0,-56
    800060f2:	fd040513          	addi	a0,s0,-48
    800060f6:	fffff097          	auipc	ra,0xfffff
    800060fa:	de6080e7          	jalr	-538(ra) # 80004edc <pipealloc>
    return -1;
    800060fe:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80006100:	0c054563          	bltz	a0,800061ca <sys_pipe+0x104>
  fd0 = -1;
    80006104:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80006108:	fd043503          	ld	a0,-48(s0)
    8000610c:	fffff097          	auipc	ra,0xfffff
    80006110:	504080e7          	jalr	1284(ra) # 80005610 <fdalloc>
    80006114:	fca42223          	sw	a0,-60(s0)
    80006118:	08054c63          	bltz	a0,800061b0 <sys_pipe+0xea>
    8000611c:	fc843503          	ld	a0,-56(s0)
    80006120:	fffff097          	auipc	ra,0xfffff
    80006124:	4f0080e7          	jalr	1264(ra) # 80005610 <fdalloc>
    80006128:	fca42023          	sw	a0,-64(s0)
    8000612c:	06054963          	bltz	a0,8000619e <sys_pipe+0xd8>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006130:	4691                	li	a3,4
    80006132:	fc440613          	addi	a2,s0,-60
    80006136:	fd843583          	ld	a1,-40(s0)
    8000613a:	68a8                	ld	a0,80(s1)
    8000613c:	ffffb097          	auipc	ra,0xffffb
    80006140:	51e080e7          	jalr	1310(ra) # 8000165a <copyout>
    80006144:	02054063          	bltz	a0,80006164 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80006148:	4691                	li	a3,4
    8000614a:	fc040613          	addi	a2,s0,-64
    8000614e:	fd843583          	ld	a1,-40(s0)
    80006152:	0591                	addi	a1,a1,4
    80006154:	68a8                	ld	a0,80(s1)
    80006156:	ffffb097          	auipc	ra,0xffffb
    8000615a:	504080e7          	jalr	1284(ra) # 8000165a <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    8000615e:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006160:	06055563          	bgez	a0,800061ca <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80006164:	fc442783          	lw	a5,-60(s0)
    80006168:	07e9                	addi	a5,a5,26
    8000616a:	078e                	slli	a5,a5,0x3
    8000616c:	97a6                	add	a5,a5,s1
    8000616e:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80006172:	fc042783          	lw	a5,-64(s0)
    80006176:	07e9                	addi	a5,a5,26
    80006178:	078e                	slli	a5,a5,0x3
    8000617a:	00f48533          	add	a0,s1,a5
    8000617e:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80006182:	fd043503          	ld	a0,-48(s0)
    80006186:	fffff097          	auipc	ra,0xfffff
    8000618a:	a26080e7          	jalr	-1498(ra) # 80004bac <fileclose>
    fileclose(wf);
    8000618e:	fc843503          	ld	a0,-56(s0)
    80006192:	fffff097          	auipc	ra,0xfffff
    80006196:	a1a080e7          	jalr	-1510(ra) # 80004bac <fileclose>
    return -1;
    8000619a:	57fd                	li	a5,-1
    8000619c:	a03d                	j	800061ca <sys_pipe+0x104>
    if(fd0 >= 0)
    8000619e:	fc442783          	lw	a5,-60(s0)
    800061a2:	0007c763          	bltz	a5,800061b0 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    800061a6:	07e9                	addi	a5,a5,26
    800061a8:	078e                	slli	a5,a5,0x3
    800061aa:	97a6                	add	a5,a5,s1
    800061ac:	0007b023          	sd	zero,0(a5)
    fileclose(rf);
    800061b0:	fd043503          	ld	a0,-48(s0)
    800061b4:	fffff097          	auipc	ra,0xfffff
    800061b8:	9f8080e7          	jalr	-1544(ra) # 80004bac <fileclose>
    fileclose(wf);
    800061bc:	fc843503          	ld	a0,-56(s0)
    800061c0:	fffff097          	auipc	ra,0xfffff
    800061c4:	9ec080e7          	jalr	-1556(ra) # 80004bac <fileclose>
    return -1;
    800061c8:	57fd                	li	a5,-1
}
    800061ca:	853e                	mv	a0,a5
    800061cc:	70e2                	ld	ra,56(sp)
    800061ce:	7442                	ld	s0,48(sp)
    800061d0:	74a2                	ld	s1,40(sp)
    800061d2:	6121                	addi	sp,sp,64
    800061d4:	8082                	ret
	...

00000000800061e0 <kernelvec>:
    800061e0:	7111                	addi	sp,sp,-256
    800061e2:	e006                	sd	ra,0(sp)
    800061e4:	e40a                	sd	sp,8(sp)
    800061e6:	e80e                	sd	gp,16(sp)
    800061e8:	ec12                	sd	tp,24(sp)
    800061ea:	f016                	sd	t0,32(sp)
    800061ec:	f41a                	sd	t1,40(sp)
    800061ee:	f81e                	sd	t2,48(sp)
    800061f0:	fc22                	sd	s0,56(sp)
    800061f2:	e0a6                	sd	s1,64(sp)
    800061f4:	e4aa                	sd	a0,72(sp)
    800061f6:	e8ae                	sd	a1,80(sp)
    800061f8:	ecb2                	sd	a2,88(sp)
    800061fa:	f0b6                	sd	a3,96(sp)
    800061fc:	f4ba                	sd	a4,104(sp)
    800061fe:	f8be                	sd	a5,112(sp)
    80006200:	fcc2                	sd	a6,120(sp)
    80006202:	e146                	sd	a7,128(sp)
    80006204:	e54a                	sd	s2,136(sp)
    80006206:	e94e                	sd	s3,144(sp)
    80006208:	ed52                	sd	s4,152(sp)
    8000620a:	f156                	sd	s5,160(sp)
    8000620c:	f55a                	sd	s6,168(sp)
    8000620e:	f95e                	sd	s7,176(sp)
    80006210:	fd62                	sd	s8,184(sp)
    80006212:	e1e6                	sd	s9,192(sp)
    80006214:	e5ea                	sd	s10,200(sp)
    80006216:	e9ee                	sd	s11,208(sp)
    80006218:	edf2                	sd	t3,216(sp)
    8000621a:	f1f6                	sd	t4,224(sp)
    8000621c:	f5fa                	sd	t5,232(sp)
    8000621e:	f9fe                	sd	t6,240(sp)
    80006220:	b75fc0ef          	jal	ra,80002d94 <kerneltrap>
    80006224:	6082                	ld	ra,0(sp)
    80006226:	6122                	ld	sp,8(sp)
    80006228:	61c2                	ld	gp,16(sp)
    8000622a:	7282                	ld	t0,32(sp)
    8000622c:	7322                	ld	t1,40(sp)
    8000622e:	73c2                	ld	t2,48(sp)
    80006230:	7462                	ld	s0,56(sp)
    80006232:	6486                	ld	s1,64(sp)
    80006234:	6526                	ld	a0,72(sp)
    80006236:	65c6                	ld	a1,80(sp)
    80006238:	6666                	ld	a2,88(sp)
    8000623a:	7686                	ld	a3,96(sp)
    8000623c:	7726                	ld	a4,104(sp)
    8000623e:	77c6                	ld	a5,112(sp)
    80006240:	7866                	ld	a6,120(sp)
    80006242:	688a                	ld	a7,128(sp)
    80006244:	692a                	ld	s2,136(sp)
    80006246:	69ca                	ld	s3,144(sp)
    80006248:	6a6a                	ld	s4,152(sp)
    8000624a:	7a8a                	ld	s5,160(sp)
    8000624c:	7b2a                	ld	s6,168(sp)
    8000624e:	7bca                	ld	s7,176(sp)
    80006250:	7c6a                	ld	s8,184(sp)
    80006252:	6c8e                	ld	s9,192(sp)
    80006254:	6d2e                	ld	s10,200(sp)
    80006256:	6dce                	ld	s11,208(sp)
    80006258:	6e6e                	ld	t3,216(sp)
    8000625a:	7e8e                	ld	t4,224(sp)
    8000625c:	7f2e                	ld	t5,232(sp)
    8000625e:	7fce                	ld	t6,240(sp)
    80006260:	6111                	addi	sp,sp,256
    80006262:	10200073          	sret
    80006266:	00000013          	nop
    8000626a:	00000013          	nop
    8000626e:	0001                	nop

0000000080006270 <timervec>:
    80006270:	34051573          	csrrw	a0,mscratch,a0
    80006274:	e10c                	sd	a1,0(a0)
    80006276:	e510                	sd	a2,8(a0)
    80006278:	e914                	sd	a3,16(a0)
    8000627a:	6d0c                	ld	a1,24(a0)
    8000627c:	7110                	ld	a2,32(a0)
    8000627e:	6194                	ld	a3,0(a1)
    80006280:	96b2                	add	a3,a3,a2
    80006282:	e194                	sd	a3,0(a1)
    80006284:	4589                	li	a1,2
    80006286:	14459073          	csrw	sip,a1
    8000628a:	6914                	ld	a3,16(a0)
    8000628c:	6510                	ld	a2,8(a0)
    8000628e:	610c                	ld	a1,0(a0)
    80006290:	34051573          	csrrw	a0,mscratch,a0
    80006294:	30200073          	mret
	...

000000008000629a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    8000629a:	1141                	addi	sp,sp,-16
    8000629c:	e422                	sd	s0,8(sp)
    8000629e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    800062a0:	0c0007b7          	lui	a5,0xc000
    800062a4:	4705                	li	a4,1
    800062a6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    800062a8:	c3d8                	sw	a4,4(a5)
}
    800062aa:	6422                	ld	s0,8(sp)
    800062ac:	0141                	addi	sp,sp,16
    800062ae:	8082                	ret

00000000800062b0 <plicinithart>:

void
plicinithart(void)
{
    800062b0:	1141                	addi	sp,sp,-16
    800062b2:	e406                	sd	ra,8(sp)
    800062b4:	e022                	sd	s0,0(sp)
    800062b6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800062b8:	ffffb097          	auipc	ra,0xffffb
    800062bc:	6b2080e7          	jalr	1714(ra) # 8000196a <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    800062c0:	0085171b          	slliw	a4,a0,0x8
    800062c4:	0c0027b7          	lui	a5,0xc002
    800062c8:	97ba                	add	a5,a5,a4
    800062ca:	40200713          	li	a4,1026
    800062ce:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    800062d2:	00d5151b          	slliw	a0,a0,0xd
    800062d6:	0c2017b7          	lui	a5,0xc201
    800062da:	97aa                	add	a5,a5,a0
    800062dc:	0007a023          	sw	zero,0(a5) # c201000 <_entry-0x73dff000>
}
    800062e0:	60a2                	ld	ra,8(sp)
    800062e2:	6402                	ld	s0,0(sp)
    800062e4:	0141                	addi	sp,sp,16
    800062e6:	8082                	ret

00000000800062e8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    800062e8:	1141                	addi	sp,sp,-16
    800062ea:	e406                	sd	ra,8(sp)
    800062ec:	e022                	sd	s0,0(sp)
    800062ee:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800062f0:	ffffb097          	auipc	ra,0xffffb
    800062f4:	67a080e7          	jalr	1658(ra) # 8000196a <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    800062f8:	00d5151b          	slliw	a0,a0,0xd
    800062fc:	0c2017b7          	lui	a5,0xc201
    80006300:	97aa                	add	a5,a5,a0
  return irq;
}
    80006302:	43c8                	lw	a0,4(a5)
    80006304:	60a2                	ld	ra,8(sp)
    80006306:	6402                	ld	s0,0(sp)
    80006308:	0141                	addi	sp,sp,16
    8000630a:	8082                	ret

000000008000630c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    8000630c:	1101                	addi	sp,sp,-32
    8000630e:	ec06                	sd	ra,24(sp)
    80006310:	e822                	sd	s0,16(sp)
    80006312:	e426                	sd	s1,8(sp)
    80006314:	1000                	addi	s0,sp,32
    80006316:	84aa                	mv	s1,a0
  int hart = cpuid();
    80006318:	ffffb097          	auipc	ra,0xffffb
    8000631c:	652080e7          	jalr	1618(ra) # 8000196a <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006320:	00d5151b          	slliw	a0,a0,0xd
    80006324:	0c2017b7          	lui	a5,0xc201
    80006328:	97aa                	add	a5,a5,a0
    8000632a:	c3c4                	sw	s1,4(a5)
}
    8000632c:	60e2                	ld	ra,24(sp)
    8000632e:	6442                	ld	s0,16(sp)
    80006330:	64a2                	ld	s1,8(sp)
    80006332:	6105                	addi	sp,sp,32
    80006334:	8082                	ret

0000000080006336 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006336:	1141                	addi	sp,sp,-16
    80006338:	e406                	sd	ra,8(sp)
    8000633a:	e022                	sd	s0,0(sp)
    8000633c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    8000633e:	479d                	li	a5,7
    80006340:	06a7c863          	blt	a5,a0,800063b0 <free_desc+0x7a>
    panic("free_desc 1");
  if(disk.free[i])
    80006344:	0001e717          	auipc	a4,0x1e
    80006348:	cbc70713          	addi	a4,a4,-836 # 80024000 <disk>
    8000634c:	972a                	add	a4,a4,a0
    8000634e:	6789                	lui	a5,0x2
    80006350:	97ba                	add	a5,a5,a4
    80006352:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80006356:	e7ad                	bnez	a5,800063c0 <free_desc+0x8a>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80006358:	00451793          	slli	a5,a0,0x4
    8000635c:	00020717          	auipc	a4,0x20
    80006360:	ca470713          	addi	a4,a4,-860 # 80026000 <disk+0x2000>
    80006364:	6314                	ld	a3,0(a4)
    80006366:	96be                	add	a3,a3,a5
    80006368:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    8000636c:	6314                	ld	a3,0(a4)
    8000636e:	96be                	add	a3,a3,a5
    80006370:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80006374:	6314                	ld	a3,0(a4)
    80006376:	96be                	add	a3,a3,a5
    80006378:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    8000637c:	6318                	ld	a4,0(a4)
    8000637e:	97ba                	add	a5,a5,a4
    80006380:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80006384:	0001e717          	auipc	a4,0x1e
    80006388:	c7c70713          	addi	a4,a4,-900 # 80024000 <disk>
    8000638c:	972a                	add	a4,a4,a0
    8000638e:	6789                	lui	a5,0x2
    80006390:	97ba                	add	a5,a5,a4
    80006392:	4705                	li	a4,1
    80006394:	00e78c23          	sb	a4,24(a5) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80006398:	00020517          	auipc	a0,0x20
    8000639c:	c8050513          	addi	a0,a0,-896 # 80026018 <disk+0x2018>
    800063a0:	ffffc097          	auipc	ra,0xffffc
    800063a4:	224080e7          	jalr	548(ra) # 800025c4 <wakeup>
}
    800063a8:	60a2                	ld	ra,8(sp)
    800063aa:	6402                	ld	s0,0(sp)
    800063ac:	0141                	addi	sp,sp,16
    800063ae:	8082                	ret
    panic("free_desc 1");
    800063b0:	00002517          	auipc	a0,0x2
    800063b4:	4b050513          	addi	a0,a0,1200 # 80008860 <syscalls+0x330>
    800063b8:	ffffa097          	auipc	ra,0xffffa
    800063bc:	182080e7          	jalr	386(ra) # 8000053a <panic>
    panic("free_desc 2");
    800063c0:	00002517          	auipc	a0,0x2
    800063c4:	4b050513          	addi	a0,a0,1200 # 80008870 <syscalls+0x340>
    800063c8:	ffffa097          	auipc	ra,0xffffa
    800063cc:	172080e7          	jalr	370(ra) # 8000053a <panic>

00000000800063d0 <virtio_disk_init>:
{
    800063d0:	1101                	addi	sp,sp,-32
    800063d2:	ec06                	sd	ra,24(sp)
    800063d4:	e822                	sd	s0,16(sp)
    800063d6:	e426                	sd	s1,8(sp)
    800063d8:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    800063da:	00002597          	auipc	a1,0x2
    800063de:	4a658593          	addi	a1,a1,1190 # 80008880 <syscalls+0x350>
    800063e2:	00020517          	auipc	a0,0x20
    800063e6:	d4650513          	addi	a0,a0,-698 # 80026128 <disk+0x2128>
    800063ea:	ffffa097          	auipc	ra,0xffffa
    800063ee:	756080e7          	jalr	1878(ra) # 80000b40 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800063f2:	100017b7          	lui	a5,0x10001
    800063f6:	4398                	lw	a4,0(a5)
    800063f8:	2701                	sext.w	a4,a4
    800063fa:	747277b7          	lui	a5,0x74727
    800063fe:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80006402:	0ef71063          	bne	a4,a5,800064e2 <virtio_disk_init+0x112>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80006406:	100017b7          	lui	a5,0x10001
    8000640a:	43dc                	lw	a5,4(a5)
    8000640c:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    8000640e:	4705                	li	a4,1
    80006410:	0ce79963          	bne	a5,a4,800064e2 <virtio_disk_init+0x112>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006414:	100017b7          	lui	a5,0x10001
    80006418:	479c                	lw	a5,8(a5)
    8000641a:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    8000641c:	4709                	li	a4,2
    8000641e:	0ce79263          	bne	a5,a4,800064e2 <virtio_disk_init+0x112>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80006422:	100017b7          	lui	a5,0x10001
    80006426:	47d8                	lw	a4,12(a5)
    80006428:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000642a:	554d47b7          	lui	a5,0x554d4
    8000642e:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80006432:	0af71863          	bne	a4,a5,800064e2 <virtio_disk_init+0x112>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006436:	100017b7          	lui	a5,0x10001
    8000643a:	4705                	li	a4,1
    8000643c:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000643e:	470d                	li	a4,3
    80006440:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80006442:	4b98                	lw	a4,16(a5)
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006444:	c7ffe6b7          	lui	a3,0xc7ffe
    80006448:	75f68693          	addi	a3,a3,1887 # ffffffffc7ffe75f <end+0xffffffff47fd775f>
    8000644c:	8f75                	and	a4,a4,a3
    8000644e:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006450:	472d                	li	a4,11
    80006452:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006454:	473d                	li	a4,15
    80006456:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    80006458:	6705                	lui	a4,0x1
    8000645a:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    8000645c:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80006460:	5bdc                	lw	a5,52(a5)
    80006462:	2781                	sext.w	a5,a5
  if(max == 0)
    80006464:	c7d9                	beqz	a5,800064f2 <virtio_disk_init+0x122>
  if(max < NUM)
    80006466:	471d                	li	a4,7
    80006468:	08f77d63          	bgeu	a4,a5,80006502 <virtio_disk_init+0x132>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    8000646c:	100014b7          	lui	s1,0x10001
    80006470:	47a1                	li	a5,8
    80006472:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80006474:	6609                	lui	a2,0x2
    80006476:	4581                	li	a1,0
    80006478:	0001e517          	auipc	a0,0x1e
    8000647c:	b8850513          	addi	a0,a0,-1144 # 80024000 <disk>
    80006480:	ffffb097          	auipc	ra,0xffffb
    80006484:	84c080e7          	jalr	-1972(ra) # 80000ccc <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    80006488:	0001e717          	auipc	a4,0x1e
    8000648c:	b7870713          	addi	a4,a4,-1160 # 80024000 <disk>
    80006490:	00c75793          	srli	a5,a4,0xc
    80006494:	2781                	sext.w	a5,a5
    80006496:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    80006498:	00020797          	auipc	a5,0x20
    8000649c:	b6878793          	addi	a5,a5,-1176 # 80026000 <disk+0x2000>
    800064a0:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    800064a2:	0001e717          	auipc	a4,0x1e
    800064a6:	bde70713          	addi	a4,a4,-1058 # 80024080 <disk+0x80>
    800064aa:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    800064ac:	0001f717          	auipc	a4,0x1f
    800064b0:	b5470713          	addi	a4,a4,-1196 # 80025000 <disk+0x1000>
    800064b4:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    800064b6:	4705                	li	a4,1
    800064b8:	00e78c23          	sb	a4,24(a5)
    800064bc:	00e78ca3          	sb	a4,25(a5)
    800064c0:	00e78d23          	sb	a4,26(a5)
    800064c4:	00e78da3          	sb	a4,27(a5)
    800064c8:	00e78e23          	sb	a4,28(a5)
    800064cc:	00e78ea3          	sb	a4,29(a5)
    800064d0:	00e78f23          	sb	a4,30(a5)
    800064d4:	00e78fa3          	sb	a4,31(a5)
}
    800064d8:	60e2                	ld	ra,24(sp)
    800064da:	6442                	ld	s0,16(sp)
    800064dc:	64a2                	ld	s1,8(sp)
    800064de:	6105                	addi	sp,sp,32
    800064e0:	8082                	ret
    panic("could not find virtio disk");
    800064e2:	00002517          	auipc	a0,0x2
    800064e6:	3ae50513          	addi	a0,a0,942 # 80008890 <syscalls+0x360>
    800064ea:	ffffa097          	auipc	ra,0xffffa
    800064ee:	050080e7          	jalr	80(ra) # 8000053a <panic>
    panic("virtio disk has no queue 0");
    800064f2:	00002517          	auipc	a0,0x2
    800064f6:	3be50513          	addi	a0,a0,958 # 800088b0 <syscalls+0x380>
    800064fa:	ffffa097          	auipc	ra,0xffffa
    800064fe:	040080e7          	jalr	64(ra) # 8000053a <panic>
    panic("virtio disk max queue too short");
    80006502:	00002517          	auipc	a0,0x2
    80006506:	3ce50513          	addi	a0,a0,974 # 800088d0 <syscalls+0x3a0>
    8000650a:	ffffa097          	auipc	ra,0xffffa
    8000650e:	030080e7          	jalr	48(ra) # 8000053a <panic>

0000000080006512 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006512:	7119                	addi	sp,sp,-128
    80006514:	fc86                	sd	ra,120(sp)
    80006516:	f8a2                	sd	s0,112(sp)
    80006518:	f4a6                	sd	s1,104(sp)
    8000651a:	f0ca                	sd	s2,96(sp)
    8000651c:	ecce                	sd	s3,88(sp)
    8000651e:	e8d2                	sd	s4,80(sp)
    80006520:	e4d6                	sd	s5,72(sp)
    80006522:	e0da                	sd	s6,64(sp)
    80006524:	fc5e                	sd	s7,56(sp)
    80006526:	f862                	sd	s8,48(sp)
    80006528:	f466                	sd	s9,40(sp)
    8000652a:	f06a                	sd	s10,32(sp)
    8000652c:	ec6e                	sd	s11,24(sp)
    8000652e:	0100                	addi	s0,sp,128
    80006530:	8aaa                	mv	s5,a0
    80006532:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006534:	00c52c83          	lw	s9,12(a0)
    80006538:	001c9c9b          	slliw	s9,s9,0x1
    8000653c:	1c82                	slli	s9,s9,0x20
    8000653e:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006542:	00020517          	auipc	a0,0x20
    80006546:	be650513          	addi	a0,a0,-1050 # 80026128 <disk+0x2128>
    8000654a:	ffffa097          	auipc	ra,0xffffa
    8000654e:	686080e7          	jalr	1670(ra) # 80000bd0 <acquire>
  for(int i = 0; i < 3; i++){
    80006552:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006554:	44a1                	li	s1,8
      disk.free[i] = 0;
    80006556:	0001ec17          	auipc	s8,0x1e
    8000655a:	aaac0c13          	addi	s8,s8,-1366 # 80024000 <disk>
    8000655e:	6b89                	lui	s7,0x2
  for(int i = 0; i < 3; i++){
    80006560:	4b0d                	li	s6,3
    80006562:	a0ad                	j	800065cc <virtio_disk_rw+0xba>
      disk.free[i] = 0;
    80006564:	00fc0733          	add	a4,s8,a5
    80006568:	975e                	add	a4,a4,s7
    8000656a:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    8000656e:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    80006570:	0207c563          	bltz	a5,8000659a <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80006574:	2905                	addiw	s2,s2,1
    80006576:	0611                	addi	a2,a2,4
    80006578:	19690c63          	beq	s2,s6,80006710 <virtio_disk_rw+0x1fe>
    idx[i] = alloc_desc();
    8000657c:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    8000657e:	00020717          	auipc	a4,0x20
    80006582:	a9a70713          	addi	a4,a4,-1382 # 80026018 <disk+0x2018>
    80006586:	87ce                	mv	a5,s3
    if(disk.free[i]){
    80006588:	00074683          	lbu	a3,0(a4)
    8000658c:	fee1                	bnez	a3,80006564 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    8000658e:	2785                	addiw	a5,a5,1
    80006590:	0705                	addi	a4,a4,1
    80006592:	fe979be3          	bne	a5,s1,80006588 <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    80006596:	57fd                	li	a5,-1
    80006598:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    8000659a:	01205d63          	blez	s2,800065b4 <virtio_disk_rw+0xa2>
    8000659e:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    800065a0:	000a2503          	lw	a0,0(s4)
    800065a4:	00000097          	auipc	ra,0x0
    800065a8:	d92080e7          	jalr	-622(ra) # 80006336 <free_desc>
      for(int j = 0; j < i; j++)
    800065ac:	2d85                	addiw	s11,s11,1
    800065ae:	0a11                	addi	s4,s4,4
    800065b0:	ff2d98e3          	bne	s11,s2,800065a0 <virtio_disk_rw+0x8e>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    800065b4:	00020597          	auipc	a1,0x20
    800065b8:	b7458593          	addi	a1,a1,-1164 # 80026128 <disk+0x2128>
    800065bc:	00020517          	auipc	a0,0x20
    800065c0:	a5c50513          	addi	a0,a0,-1444 # 80026018 <disk+0x2018>
    800065c4:	ffffc097          	auipc	ra,0xffffc
    800065c8:	d18080e7          	jalr	-744(ra) # 800022dc <sleep>
  for(int i = 0; i < 3; i++){
    800065cc:	f8040a13          	addi	s4,s0,-128
{
    800065d0:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    800065d2:	894e                	mv	s2,s3
    800065d4:	b765                	j	8000657c <virtio_disk_rw+0x6a>
  disk.desc[idx[0]].next = idx[1];

  disk.desc[idx[1]].addr = (uint64) b->data;
  disk.desc[idx[1]].len = BSIZE;
  if(write)
    disk.desc[idx[1]].flags = 0; // device reads b->data
    800065d6:	00020697          	auipc	a3,0x20
    800065da:	a2a6b683          	ld	a3,-1494(a3) # 80026000 <disk+0x2000>
    800065de:	96ba                	add	a3,a3,a4
    800065e0:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    800065e4:	0001e817          	auipc	a6,0x1e
    800065e8:	a1c80813          	addi	a6,a6,-1508 # 80024000 <disk>
    800065ec:	00020697          	auipc	a3,0x20
    800065f0:	a1468693          	addi	a3,a3,-1516 # 80026000 <disk+0x2000>
    800065f4:	6290                	ld	a2,0(a3)
    800065f6:	963a                	add	a2,a2,a4
    800065f8:	00c65583          	lhu	a1,12(a2) # 200c <_entry-0x7fffdff4>
    800065fc:	0015e593          	ori	a1,a1,1
    80006600:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[1]].next = idx[2];
    80006604:	f8842603          	lw	a2,-120(s0)
    80006608:	628c                	ld	a1,0(a3)
    8000660a:	972e                	add	a4,a4,a1
    8000660c:	00c71723          	sh	a2,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006610:	20050593          	addi	a1,a0,512
    80006614:	0592                	slli	a1,a1,0x4
    80006616:	95c2                	add	a1,a1,a6
    80006618:	577d                	li	a4,-1
    8000661a:	02e58823          	sb	a4,48(a1)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    8000661e:	00461713          	slli	a4,a2,0x4
    80006622:	6290                	ld	a2,0(a3)
    80006624:	963a                	add	a2,a2,a4
    80006626:	03078793          	addi	a5,a5,48
    8000662a:	97c2                	add	a5,a5,a6
    8000662c:	e21c                	sd	a5,0(a2)
  disk.desc[idx[2]].len = 1;
    8000662e:	629c                	ld	a5,0(a3)
    80006630:	97ba                	add	a5,a5,a4
    80006632:	4605                	li	a2,1
    80006634:	c790                	sw	a2,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006636:	629c                	ld	a5,0(a3)
    80006638:	97ba                	add	a5,a5,a4
    8000663a:	4809                	li	a6,2
    8000663c:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80006640:	629c                	ld	a5,0(a3)
    80006642:	97ba                	add	a5,a5,a4
    80006644:	00079723          	sh	zero,14(a5)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006648:	00caa223          	sw	a2,4(s5)
  disk.info[idx[0]].b = b;
    8000664c:	0355b423          	sd	s5,40(a1)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006650:	6698                	ld	a4,8(a3)
    80006652:	00275783          	lhu	a5,2(a4)
    80006656:	8b9d                	andi	a5,a5,7
    80006658:	0786                	slli	a5,a5,0x1
    8000665a:	973e                	add	a4,a4,a5
    8000665c:	00a71223          	sh	a0,4(a4)

  __sync_synchronize();
    80006660:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006664:	6698                	ld	a4,8(a3)
    80006666:	00275783          	lhu	a5,2(a4)
    8000666a:	2785                	addiw	a5,a5,1
    8000666c:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006670:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006674:	100017b7          	lui	a5,0x10001
    80006678:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    8000667c:	004aa783          	lw	a5,4(s5)
    80006680:	02c79163          	bne	a5,a2,800066a2 <virtio_disk_rw+0x190>
    sleep(b, &disk.vdisk_lock);
    80006684:	00020917          	auipc	s2,0x20
    80006688:	aa490913          	addi	s2,s2,-1372 # 80026128 <disk+0x2128>
  while(b->disk == 1) {
    8000668c:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    8000668e:	85ca                	mv	a1,s2
    80006690:	8556                	mv	a0,s5
    80006692:	ffffc097          	auipc	ra,0xffffc
    80006696:	c4a080e7          	jalr	-950(ra) # 800022dc <sleep>
  while(b->disk == 1) {
    8000669a:	004aa783          	lw	a5,4(s5)
    8000669e:	fe9788e3          	beq	a5,s1,8000668e <virtio_disk_rw+0x17c>
  }

  disk.info[idx[0]].b = 0;
    800066a2:	f8042903          	lw	s2,-128(s0)
    800066a6:	20090713          	addi	a4,s2,512
    800066aa:	0712                	slli	a4,a4,0x4
    800066ac:	0001e797          	auipc	a5,0x1e
    800066b0:	95478793          	addi	a5,a5,-1708 # 80024000 <disk>
    800066b4:	97ba                	add	a5,a5,a4
    800066b6:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    800066ba:	00020997          	auipc	s3,0x20
    800066be:	94698993          	addi	s3,s3,-1722 # 80026000 <disk+0x2000>
    800066c2:	00491713          	slli	a4,s2,0x4
    800066c6:	0009b783          	ld	a5,0(s3)
    800066ca:	97ba                	add	a5,a5,a4
    800066cc:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    800066d0:	854a                	mv	a0,s2
    800066d2:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    800066d6:	00000097          	auipc	ra,0x0
    800066da:	c60080e7          	jalr	-928(ra) # 80006336 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    800066de:	8885                	andi	s1,s1,1
    800066e0:	f0ed                	bnez	s1,800066c2 <virtio_disk_rw+0x1b0>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800066e2:	00020517          	auipc	a0,0x20
    800066e6:	a4650513          	addi	a0,a0,-1466 # 80026128 <disk+0x2128>
    800066ea:	ffffa097          	auipc	ra,0xffffa
    800066ee:	59a080e7          	jalr	1434(ra) # 80000c84 <release>
}
    800066f2:	70e6                	ld	ra,120(sp)
    800066f4:	7446                	ld	s0,112(sp)
    800066f6:	74a6                	ld	s1,104(sp)
    800066f8:	7906                	ld	s2,96(sp)
    800066fa:	69e6                	ld	s3,88(sp)
    800066fc:	6a46                	ld	s4,80(sp)
    800066fe:	6aa6                	ld	s5,72(sp)
    80006700:	6b06                	ld	s6,64(sp)
    80006702:	7be2                	ld	s7,56(sp)
    80006704:	7c42                	ld	s8,48(sp)
    80006706:	7ca2                	ld	s9,40(sp)
    80006708:	7d02                	ld	s10,32(sp)
    8000670a:	6de2                	ld	s11,24(sp)
    8000670c:	6109                	addi	sp,sp,128
    8000670e:	8082                	ret
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006710:	f8042503          	lw	a0,-128(s0)
    80006714:	20050793          	addi	a5,a0,512
    80006718:	0792                	slli	a5,a5,0x4
  if(write)
    8000671a:	0001e817          	auipc	a6,0x1e
    8000671e:	8e680813          	addi	a6,a6,-1818 # 80024000 <disk>
    80006722:	00f80733          	add	a4,a6,a5
    80006726:	01a036b3          	snez	a3,s10
    8000672a:	0ad72423          	sw	a3,168(a4)
  buf0->reserved = 0;
    8000672e:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    80006732:	0b973823          	sd	s9,176(a4)
  disk.desc[idx[0]].addr = (uint64) buf0;
    80006736:	7679                	lui	a2,0xffffe
    80006738:	963e                	add	a2,a2,a5
    8000673a:	00020697          	auipc	a3,0x20
    8000673e:	8c668693          	addi	a3,a3,-1850 # 80026000 <disk+0x2000>
    80006742:	6298                	ld	a4,0(a3)
    80006744:	9732                	add	a4,a4,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006746:	0a878593          	addi	a1,a5,168
    8000674a:	95c2                	add	a1,a1,a6
  disk.desc[idx[0]].addr = (uint64) buf0;
    8000674c:	e30c                	sd	a1,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    8000674e:	6298                	ld	a4,0(a3)
    80006750:	9732                	add	a4,a4,a2
    80006752:	45c1                	li	a1,16
    80006754:	c70c                	sw	a1,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006756:	6298                	ld	a4,0(a3)
    80006758:	9732                	add	a4,a4,a2
    8000675a:	4585                	li	a1,1
    8000675c:	00b71623          	sh	a1,12(a4)
  disk.desc[idx[0]].next = idx[1];
    80006760:	f8442703          	lw	a4,-124(s0)
    80006764:	628c                	ld	a1,0(a3)
    80006766:	962e                	add	a2,a2,a1
    80006768:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd700e>
  disk.desc[idx[1]].addr = (uint64) b->data;
    8000676c:	0712                	slli	a4,a4,0x4
    8000676e:	6290                	ld	a2,0(a3)
    80006770:	963a                	add	a2,a2,a4
    80006772:	058a8593          	addi	a1,s5,88
    80006776:	e20c                	sd	a1,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    80006778:	6294                	ld	a3,0(a3)
    8000677a:	96ba                	add	a3,a3,a4
    8000677c:	40000613          	li	a2,1024
    80006780:	c690                	sw	a2,8(a3)
  if(write)
    80006782:	e40d1ae3          	bnez	s10,800065d6 <virtio_disk_rw+0xc4>
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    80006786:	00020697          	auipc	a3,0x20
    8000678a:	87a6b683          	ld	a3,-1926(a3) # 80026000 <disk+0x2000>
    8000678e:	96ba                	add	a3,a3,a4
    80006790:	4609                	li	a2,2
    80006792:	00c69623          	sh	a2,12(a3)
    80006796:	b5b9                	j	800065e4 <virtio_disk_rw+0xd2>

0000000080006798 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006798:	1101                	addi	sp,sp,-32
    8000679a:	ec06                	sd	ra,24(sp)
    8000679c:	e822                	sd	s0,16(sp)
    8000679e:	e426                	sd	s1,8(sp)
    800067a0:	e04a                	sd	s2,0(sp)
    800067a2:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    800067a4:	00020517          	auipc	a0,0x20
    800067a8:	98450513          	addi	a0,a0,-1660 # 80026128 <disk+0x2128>
    800067ac:	ffffa097          	auipc	ra,0xffffa
    800067b0:	424080e7          	jalr	1060(ra) # 80000bd0 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800067b4:	10001737          	lui	a4,0x10001
    800067b8:	533c                	lw	a5,96(a4)
    800067ba:	8b8d                	andi	a5,a5,3
    800067bc:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    800067be:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    800067c2:	00020797          	auipc	a5,0x20
    800067c6:	83e78793          	addi	a5,a5,-1986 # 80026000 <disk+0x2000>
    800067ca:	6b94                	ld	a3,16(a5)
    800067cc:	0207d703          	lhu	a4,32(a5)
    800067d0:	0026d783          	lhu	a5,2(a3)
    800067d4:	06f70163          	beq	a4,a5,80006836 <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800067d8:	0001e917          	auipc	s2,0x1e
    800067dc:	82890913          	addi	s2,s2,-2008 # 80024000 <disk>
    800067e0:	00020497          	auipc	s1,0x20
    800067e4:	82048493          	addi	s1,s1,-2016 # 80026000 <disk+0x2000>
    __sync_synchronize();
    800067e8:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800067ec:	6898                	ld	a4,16(s1)
    800067ee:	0204d783          	lhu	a5,32(s1)
    800067f2:	8b9d                	andi	a5,a5,7
    800067f4:	078e                	slli	a5,a5,0x3
    800067f6:	97ba                	add	a5,a5,a4
    800067f8:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    800067fa:	20078713          	addi	a4,a5,512
    800067fe:	0712                	slli	a4,a4,0x4
    80006800:	974a                	add	a4,a4,s2
    80006802:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    80006806:	e731                	bnez	a4,80006852 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006808:	20078793          	addi	a5,a5,512
    8000680c:	0792                	slli	a5,a5,0x4
    8000680e:	97ca                	add	a5,a5,s2
    80006810:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    80006812:	00052223          	sw	zero,4(a0)
    wakeup(b);
    80006816:	ffffc097          	auipc	ra,0xffffc
    8000681a:	dae080e7          	jalr	-594(ra) # 800025c4 <wakeup>

    disk.used_idx += 1;
    8000681e:	0204d783          	lhu	a5,32(s1)
    80006822:	2785                	addiw	a5,a5,1
    80006824:	17c2                	slli	a5,a5,0x30
    80006826:	93c1                	srli	a5,a5,0x30
    80006828:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    8000682c:	6898                	ld	a4,16(s1)
    8000682e:	00275703          	lhu	a4,2(a4)
    80006832:	faf71be3          	bne	a4,a5,800067e8 <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    80006836:	00020517          	auipc	a0,0x20
    8000683a:	8f250513          	addi	a0,a0,-1806 # 80026128 <disk+0x2128>
    8000683e:	ffffa097          	auipc	ra,0xffffa
    80006842:	446080e7          	jalr	1094(ra) # 80000c84 <release>
}
    80006846:	60e2                	ld	ra,24(sp)
    80006848:	6442                	ld	s0,16(sp)
    8000684a:	64a2                	ld	s1,8(sp)
    8000684c:	6902                	ld	s2,0(sp)
    8000684e:	6105                	addi	sp,sp,32
    80006850:	8082                	ret
      panic("virtio_disk_intr status");
    80006852:	00002517          	auipc	a0,0x2
    80006856:	09e50513          	addi	a0,a0,158 # 800088f0 <syscalls+0x3c0>
    8000685a:	ffffa097          	auipc	ra,0xffffa
    8000685e:	ce0080e7          	jalr	-800(ra) # 8000053a <panic>
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
