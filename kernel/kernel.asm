
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
    80000016:	078000ef          	jal	ra,8000008e <start>

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
    80000026:	0007869b          	sext.w	a3,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873583          	ld	a1,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	95b2                	add	a1,a1,a2
    80000046:	e38c                	sd	a1,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00269713          	slli	a4,a3,0x2
    8000004c:	9736                	add	a4,a4,a3
    8000004e:	00371693          	slli	a3,a4,0x3
    80000052:	00009717          	auipc	a4,0x9
    80000056:	fee70713          	addi	a4,a4,-18 # 80009040 <timer_scratch>
    8000005a:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005c:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005e:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    80000060:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000064:	00006797          	auipc	a5,0x6
    80000068:	b2c78793          	addi	a5,a5,-1236 # 80005b90 <timervec>
    8000006c:	30579073          	csrw	mtvec,a5
	asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000070:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000074:	0087e793          	ori	a5,a5,8
	asm volatile("csrw mstatus, %0" : : "r" (x));
    80000078:	30079073          	csrw	mstatus,a5
	asm volatile("csrr %0, mie" : "=r" (x) );
    8000007c:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    80000080:	0807e793          	ori	a5,a5,128
	asm volatile("csrw mie, %0" : : "r" (x));
    80000084:	30479073          	csrw	mie,a5
}
    80000088:	6422                	ld	s0,8(sp)
    8000008a:	0141                	addi	sp,sp,16
    8000008c:	8082                	ret

000000008000008e <start>:
{
    8000008e:	1141                	addi	sp,sp,-16
    80000090:	e406                	sd	ra,8(sp)
    80000092:	e022                	sd	s0,0(sp)
    80000094:	0800                	addi	s0,sp,16
	asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000096:	300027f3          	csrr	a5,mstatus
	x &= ~MSTATUS_MPP_MASK;
    8000009a:	7779                	lui	a4,0xffffe
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd87ff>
    800000a0:	8ff9                	and	a5,a5,a4
	x |= MSTATUS_MPP_S;
    800000a2:	6705                	lui	a4,0x1
    800000a4:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a8:	8fd9                	or	a5,a5,a4
	asm volatile("csrw mstatus, %0" : : "r" (x));
    800000aa:	30079073          	csrw	mstatus,a5
	asm volatile("csrw mepc, %0" : : "r" (x));
    800000ae:	00001797          	auipc	a5,0x1
    800000b2:	de078793          	addi	a5,a5,-544 # 80000e8e <main>
    800000b6:	34179073          	csrw	mepc,a5
	asm volatile("csrw satp, %0" : : "r" (x));
    800000ba:	4781                	li	a5,0
    800000bc:	18079073          	csrw	satp,a5
	asm volatile("csrw medeleg, %0" : : "r" (x));
    800000c0:	67c1                	lui	a5,0x10
    800000c2:	17fd                	addi	a5,a5,-1
    800000c4:	30279073          	csrw	medeleg,a5
	asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c8:	30379073          	csrw	mideleg,a5
	asm volatile("csrr %0, sie" : "=r" (x) );
    800000cc:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000d0:	2227e793          	ori	a5,a5,546
	asm volatile("csrw sie, %0" : : "r" (x));
    800000d4:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000d8:	57fd                	li	a5,-1
    800000da:	83a9                	srli	a5,a5,0xa
    800000dc:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000e0:	47bd                	li	a5,15
    800000e2:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000e6:	00000097          	auipc	ra,0x0
    800000ea:	f36080e7          	jalr	-202(ra) # 8000001c <timerinit>
	asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000ee:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000f2:	2781                	sext.w	a5,a5
}

static inline void
w_tp(uint64 x)
{
	asm volatile("mv tp, %0" : : "r" (x));
    800000f4:	823e                	mv	tp,a5
  asm volatile("mret");
    800000f6:	30200073          	mret
}
    800000fa:	60a2                	ld	ra,8(sp)
    800000fc:	6402                	ld	s0,0(sp)
    800000fe:	0141                	addi	sp,sp,16
    80000100:	8082                	ret

0000000080000102 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    80000102:	715d                	addi	sp,sp,-80
    80000104:	e486                	sd	ra,72(sp)
    80000106:	e0a2                	sd	s0,64(sp)
    80000108:	fc26                	sd	s1,56(sp)
    8000010a:	f84a                	sd	s2,48(sp)
    8000010c:	f44e                	sd	s3,40(sp)
    8000010e:	f052                	sd	s4,32(sp)
    80000110:	ec56                	sd	s5,24(sp)
    80000112:	0880                	addi	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    80000114:	04c05663          	blez	a2,80000160 <consolewrite+0x5e>
    80000118:	8a2a                	mv	s4,a0
    8000011a:	84ae                	mv	s1,a1
    8000011c:	89b2                	mv	s3,a2
    8000011e:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    80000120:	5afd                	li	s5,-1
    80000122:	4685                	li	a3,1
    80000124:	8626                	mv	a2,s1
    80000126:	85d2                	mv	a1,s4
    80000128:	fbf40513          	addi	a0,s0,-65
    8000012c:	00002097          	auipc	ra,0x2
    80000130:	3b6080e7          	jalr	950(ra) # 800024e2 <either_copyin>
    80000134:	01550c63          	beq	a0,s5,8000014c <consolewrite+0x4a>
      break;
    uartputc(c);
    80000138:	fbf44503          	lbu	a0,-65(s0)
    8000013c:	00000097          	auipc	ra,0x0
    80000140:	78e080e7          	jalr	1934(ra) # 800008ca <uartputc>
  for(i = 0; i < n; i++){
    80000144:	2905                	addiw	s2,s2,1
    80000146:	0485                	addi	s1,s1,1
    80000148:	fd299de3          	bne	s3,s2,80000122 <consolewrite+0x20>
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
    80000162:	b7ed                	j	8000014c <consolewrite+0x4a>

0000000080000164 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000164:	7119                	addi	sp,sp,-128
    80000166:	fc86                	sd	ra,120(sp)
    80000168:	f8a2                	sd	s0,112(sp)
    8000016a:	f4a6                	sd	s1,104(sp)
    8000016c:	f0ca                	sd	s2,96(sp)
    8000016e:	ecce                	sd	s3,88(sp)
    80000170:	e8d2                	sd	s4,80(sp)
    80000172:	e4d6                	sd	s5,72(sp)
    80000174:	e0da                	sd	s6,64(sp)
    80000176:	fc5e                	sd	s7,56(sp)
    80000178:	f862                	sd	s8,48(sp)
    8000017a:	f466                	sd	s9,40(sp)
    8000017c:	f06a                	sd	s10,32(sp)
    8000017e:	ec6e                	sd	s11,24(sp)
    80000180:	0100                	addi	s0,sp,128
    80000182:	8b2a                	mv	s6,a0
    80000184:	8aae                	mv	s5,a1
    80000186:	8a32                	mv	s4,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000188:	00060b9b          	sext.w	s7,a2
  acquire(&cons.lock);
    8000018c:	00011517          	auipc	a0,0x11
    80000190:	ff450513          	addi	a0,a0,-12 # 80011180 <cons>
    80000194:	00001097          	auipc	ra,0x1
    80000198:	a50080e7          	jalr	-1456(ra) # 80000be4 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019c:	00011497          	auipc	s1,0x11
    800001a0:	fe448493          	addi	s1,s1,-28 # 80011180 <cons>
      if(myproc()->killed){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a4:	89a6                	mv	s3,s1
    800001a6:	00011917          	auipc	s2,0x11
    800001aa:	07290913          	addi	s2,s2,114 # 80011218 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF];

    if(c == C('D')){  // end-of-file
    800001ae:	4c91                	li	s9,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001b0:	5d7d                	li	s10,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001b2:	4da9                	li	s11,10
  while(n > 0){
    800001b4:	07405863          	blez	s4,80000224 <consoleread+0xc0>
    while(cons.r == cons.w){
    800001b8:	0984a783          	lw	a5,152(s1)
    800001bc:	09c4a703          	lw	a4,156(s1)
    800001c0:	02f71463          	bne	a4,a5,800001e8 <consoleread+0x84>
      if(myproc()->killed){
    800001c4:	00002097          	auipc	ra,0x2
    800001c8:	868080e7          	jalr	-1944(ra) # 80001a2c <myproc>
    800001cc:	551c                	lw	a5,40(a0)
    800001ce:	e7b5                	bnez	a5,8000023a <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    800001d0:	85ce                	mv	a1,s3
    800001d2:	854a                	mv	a0,s2
    800001d4:	00002097          	auipc	ra,0x2
    800001d8:	f14080e7          	jalr	-236(ra) # 800020e8 <sleep>
    while(cons.r == cons.w){
    800001dc:	0984a783          	lw	a5,152(s1)
    800001e0:	09c4a703          	lw	a4,156(s1)
    800001e4:	fef700e3          	beq	a4,a5,800001c4 <consoleread+0x60>
    c = cons.buf[cons.r++ % INPUT_BUF];
    800001e8:	0017871b          	addiw	a4,a5,1
    800001ec:	08e4ac23          	sw	a4,152(s1)
    800001f0:	07f7f713          	andi	a4,a5,127
    800001f4:	9726                	add	a4,a4,s1
    800001f6:	01874703          	lbu	a4,24(a4)
    800001fa:	00070c1b          	sext.w	s8,a4
    if(c == C('D')){  // end-of-file
    800001fe:	079c0663          	beq	s8,s9,8000026a <consoleread+0x106>
    cbuf = c;
    80000202:	f8e407a3          	sb	a4,-113(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000206:	4685                	li	a3,1
    80000208:	f8f40613          	addi	a2,s0,-113
    8000020c:	85d6                	mv	a1,s5
    8000020e:	855a                	mv	a0,s6
    80000210:	00002097          	auipc	ra,0x2
    80000214:	27c080e7          	jalr	636(ra) # 8000248c <either_copyout>
    80000218:	01a50663          	beq	a0,s10,80000224 <consoleread+0xc0>
    dst++;
    8000021c:	0a85                	addi	s5,s5,1
    --n;
    8000021e:	3a7d                	addiw	s4,s4,-1
    if(c == '\n'){
    80000220:	f9bc1ae3          	bne	s8,s11,800001b4 <consoleread+0x50>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    80000224:	00011517          	auipc	a0,0x11
    80000228:	f5c50513          	addi	a0,a0,-164 # 80011180 <cons>
    8000022c:	00001097          	auipc	ra,0x1
    80000230:	a6c080e7          	jalr	-1428(ra) # 80000c98 <release>

  return target - n;
    80000234:	414b853b          	subw	a0,s7,s4
    80000238:	a811                	j	8000024c <consoleread+0xe8>
        release(&cons.lock);
    8000023a:	00011517          	auipc	a0,0x11
    8000023e:	f4650513          	addi	a0,a0,-186 # 80011180 <cons>
    80000242:	00001097          	auipc	ra,0x1
    80000246:	a56080e7          	jalr	-1450(ra) # 80000c98 <release>
        return -1;
    8000024a:	557d                	li	a0,-1
}
    8000024c:	70e6                	ld	ra,120(sp)
    8000024e:	7446                	ld	s0,112(sp)
    80000250:	74a6                	ld	s1,104(sp)
    80000252:	7906                	ld	s2,96(sp)
    80000254:	69e6                	ld	s3,88(sp)
    80000256:	6a46                	ld	s4,80(sp)
    80000258:	6aa6                	ld	s5,72(sp)
    8000025a:	6b06                	ld	s6,64(sp)
    8000025c:	7be2                	ld	s7,56(sp)
    8000025e:	7c42                	ld	s8,48(sp)
    80000260:	7ca2                	ld	s9,40(sp)
    80000262:	7d02                	ld	s10,32(sp)
    80000264:	6de2                	ld	s11,24(sp)
    80000266:	6109                	addi	sp,sp,128
    80000268:	8082                	ret
      if(n < target){
    8000026a:	000a071b          	sext.w	a4,s4
    8000026e:	fb777be3          	bgeu	a4,s7,80000224 <consoleread+0xc0>
        cons.r--;
    80000272:	00011717          	auipc	a4,0x11
    80000276:	faf72323          	sw	a5,-90(a4) # 80011218 <cons+0x98>
    8000027a:	b76d                	j	80000224 <consoleread+0xc0>

000000008000027c <consputc>:
{
    8000027c:	1141                	addi	sp,sp,-16
    8000027e:	e406                	sd	ra,8(sp)
    80000280:	e022                	sd	s0,0(sp)
    80000282:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    80000284:	10000793          	li	a5,256
    80000288:	00f50a63          	beq	a0,a5,8000029c <consputc+0x20>
    uartputc_sync(c);
    8000028c:	00000097          	auipc	ra,0x0
    80000290:	564080e7          	jalr	1380(ra) # 800007f0 <uartputc_sync>
}
    80000294:	60a2                	ld	ra,8(sp)
    80000296:	6402                	ld	s0,0(sp)
    80000298:	0141                	addi	sp,sp,16
    8000029a:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    8000029c:	4521                	li	a0,8
    8000029e:	00000097          	auipc	ra,0x0
    800002a2:	552080e7          	jalr	1362(ra) # 800007f0 <uartputc_sync>
    800002a6:	02000513          	li	a0,32
    800002aa:	00000097          	auipc	ra,0x0
    800002ae:	546080e7          	jalr	1350(ra) # 800007f0 <uartputc_sync>
    800002b2:	4521                	li	a0,8
    800002b4:	00000097          	auipc	ra,0x0
    800002b8:	53c080e7          	jalr	1340(ra) # 800007f0 <uartputc_sync>
    800002bc:	bfe1                	j	80000294 <consputc+0x18>

00000000800002be <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002be:	1101                	addi	sp,sp,-32
    800002c0:	ec06                	sd	ra,24(sp)
    800002c2:	e822                	sd	s0,16(sp)
    800002c4:	e426                	sd	s1,8(sp)
    800002c6:	e04a                	sd	s2,0(sp)
    800002c8:	1000                	addi	s0,sp,32
    800002ca:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002cc:	00011517          	auipc	a0,0x11
    800002d0:	eb450513          	addi	a0,a0,-332 # 80011180 <cons>
    800002d4:	00001097          	auipc	ra,0x1
    800002d8:	910080e7          	jalr	-1776(ra) # 80000be4 <acquire>

  switch(c){
    800002dc:	47d5                	li	a5,21
    800002de:	0af48663          	beq	s1,a5,8000038a <consoleintr+0xcc>
    800002e2:	0297ca63          	blt	a5,s1,80000316 <consoleintr+0x58>
    800002e6:	47a1                	li	a5,8
    800002e8:	0ef48763          	beq	s1,a5,800003d6 <consoleintr+0x118>
    800002ec:	47c1                	li	a5,16
    800002ee:	10f49a63          	bne	s1,a5,80000402 <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002f2:	00002097          	auipc	ra,0x2
    800002f6:	246080e7          	jalr	582(ra) # 80002538 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002fa:	00011517          	auipc	a0,0x11
    800002fe:	e8650513          	addi	a0,a0,-378 # 80011180 <cons>
    80000302:	00001097          	auipc	ra,0x1
    80000306:	996080e7          	jalr	-1642(ra) # 80000c98 <release>
}
    8000030a:	60e2                	ld	ra,24(sp)
    8000030c:	6442                	ld	s0,16(sp)
    8000030e:	64a2                	ld	s1,8(sp)
    80000310:	6902                	ld	s2,0(sp)
    80000312:	6105                	addi	sp,sp,32
    80000314:	8082                	ret
  switch(c){
    80000316:	07f00793          	li	a5,127
    8000031a:	0af48e63          	beq	s1,a5,800003d6 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    8000031e:	00011717          	auipc	a4,0x11
    80000322:	e6270713          	addi	a4,a4,-414 # 80011180 <cons>
    80000326:	0a072783          	lw	a5,160(a4)
    8000032a:	09872703          	lw	a4,152(a4)
    8000032e:	9f99                	subw	a5,a5,a4
    80000330:	07f00713          	li	a4,127
    80000334:	fcf763e3          	bltu	a4,a5,800002fa <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    80000338:	47b5                	li	a5,13
    8000033a:	0cf48763          	beq	s1,a5,80000408 <consoleintr+0x14a>
      consputc(c);
    8000033e:	8526                	mv	a0,s1
    80000340:	00000097          	auipc	ra,0x0
    80000344:	f3c080e7          	jalr	-196(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000348:	00011797          	auipc	a5,0x11
    8000034c:	e3878793          	addi	a5,a5,-456 # 80011180 <cons>
    80000350:	0a07a703          	lw	a4,160(a5)
    80000354:	0017069b          	addiw	a3,a4,1
    80000358:	0006861b          	sext.w	a2,a3
    8000035c:	0ad7a023          	sw	a3,160(a5)
    80000360:	07f77713          	andi	a4,a4,127
    80000364:	97ba                	add	a5,a5,a4
    80000366:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e == cons.r+INPUT_BUF){
    8000036a:	47a9                	li	a5,10
    8000036c:	0cf48563          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000370:	4791                	li	a5,4
    80000372:	0cf48263          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000376:	00011797          	auipc	a5,0x11
    8000037a:	ea27a783          	lw	a5,-350(a5) # 80011218 <cons+0x98>
    8000037e:	0807879b          	addiw	a5,a5,128
    80000382:	f6f61ce3          	bne	a2,a5,800002fa <consoleintr+0x3c>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000386:	863e                	mv	a2,a5
    80000388:	a07d                	j	80000436 <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000038a:	00011717          	auipc	a4,0x11
    8000038e:	df670713          	addi	a4,a4,-522 # 80011180 <cons>
    80000392:	0a072783          	lw	a5,160(a4)
    80000396:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    8000039a:	00011497          	auipc	s1,0x11
    8000039e:	de648493          	addi	s1,s1,-538 # 80011180 <cons>
    while(cons.e != cons.w &&
    800003a2:	4929                	li	s2,10
    800003a4:	f4f70be3          	beq	a4,a5,800002fa <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    800003a8:	37fd                	addiw	a5,a5,-1
    800003aa:	07f7f713          	andi	a4,a5,127
    800003ae:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003b0:	01874703          	lbu	a4,24(a4)
    800003b4:	f52703e3          	beq	a4,s2,800002fa <consoleintr+0x3c>
      cons.e--;
    800003b8:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003bc:	10000513          	li	a0,256
    800003c0:	00000097          	auipc	ra,0x0
    800003c4:	ebc080e7          	jalr	-324(ra) # 8000027c <consputc>
    while(cons.e != cons.w &&
    800003c8:	0a04a783          	lw	a5,160(s1)
    800003cc:	09c4a703          	lw	a4,156(s1)
    800003d0:	fcf71ce3          	bne	a4,a5,800003a8 <consoleintr+0xea>
    800003d4:	b71d                	j	800002fa <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003d6:	00011717          	auipc	a4,0x11
    800003da:	daa70713          	addi	a4,a4,-598 # 80011180 <cons>
    800003de:	0a072783          	lw	a5,160(a4)
    800003e2:	09c72703          	lw	a4,156(a4)
    800003e6:	f0f70ae3          	beq	a4,a5,800002fa <consoleintr+0x3c>
      cons.e--;
    800003ea:	37fd                	addiw	a5,a5,-1
    800003ec:	00011717          	auipc	a4,0x11
    800003f0:	e2f72a23          	sw	a5,-460(a4) # 80011220 <cons+0xa0>
      consputc(BACKSPACE);
    800003f4:	10000513          	li	a0,256
    800003f8:	00000097          	auipc	ra,0x0
    800003fc:	e84080e7          	jalr	-380(ra) # 8000027c <consputc>
    80000400:	bded                	j	800002fa <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    80000402:	ee048ce3          	beqz	s1,800002fa <consoleintr+0x3c>
    80000406:	bf21                	j	8000031e <consoleintr+0x60>
      consputc(c);
    80000408:	4529                	li	a0,10
    8000040a:	00000097          	auipc	ra,0x0
    8000040e:	e72080e7          	jalr	-398(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000412:	00011797          	auipc	a5,0x11
    80000416:	d6e78793          	addi	a5,a5,-658 # 80011180 <cons>
    8000041a:	0a07a703          	lw	a4,160(a5)
    8000041e:	0017069b          	addiw	a3,a4,1
    80000422:	0006861b          	sext.w	a2,a3
    80000426:	0ad7a023          	sw	a3,160(a5)
    8000042a:	07f77713          	andi	a4,a4,127
    8000042e:	97ba                	add	a5,a5,a4
    80000430:	4729                	li	a4,10
    80000432:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000436:	00011797          	auipc	a5,0x11
    8000043a:	dec7a323          	sw	a2,-538(a5) # 8001121c <cons+0x9c>
        wakeup(&cons.r);
    8000043e:	00011517          	auipc	a0,0x11
    80000442:	dda50513          	addi	a0,a0,-550 # 80011218 <cons+0x98>
    80000446:	00002097          	auipc	ra,0x2
    8000044a:	e2e080e7          	jalr	-466(ra) # 80002274 <wakeup>
    8000044e:	b575                	j	800002fa <consoleintr+0x3c>

0000000080000450 <consoleinit>:

void
consoleinit(void)
{
    80000450:	1141                	addi	sp,sp,-16
    80000452:	e406                	sd	ra,8(sp)
    80000454:	e022                	sd	s0,0(sp)
    80000456:	0800                	addi	s0,sp,16
	initlock(&cons.lock, "cons");
    80000458:	00008597          	auipc	a1,0x8
    8000045c:	bb858593          	addi	a1,a1,-1096 # 80008010 <etext+0x10>
    80000460:	00011517          	auipc	a0,0x11
    80000464:	d2050513          	addi	a0,a0,-736 # 80011180 <cons>
    80000468:	00000097          	auipc	ra,0x0
    8000046c:	6ec080e7          	jalr	1772(ra) # 80000b54 <initlock>

	uartinit();
    80000470:	00000097          	auipc	ra,0x0
    80000474:	330080e7          	jalr	816(ra) # 800007a0 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000478:	00021797          	auipc	a5,0x21
    8000047c:	ea078793          	addi	a5,a5,-352 # 80021318 <devsw>
    80000480:	00000717          	auipc	a4,0x0
    80000484:	ce470713          	addi	a4,a4,-796 # 80000164 <consoleread>
    80000488:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    8000048a:	00000717          	auipc	a4,0x0
    8000048e:	c7870713          	addi	a4,a4,-904 # 80000102 <consolewrite>
    80000492:	ef98                	sd	a4,24(a5)
}
    80000494:	60a2                	ld	ra,8(sp)
    80000496:	6402                	ld	s0,0(sp)
    80000498:	0141                	addi	sp,sp,16
    8000049a:	8082                	ret

000000008000049c <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    8000049c:	7179                	addi	sp,sp,-48
    8000049e:	f406                	sd	ra,40(sp)
    800004a0:	f022                	sd	s0,32(sp)
    800004a2:	ec26                	sd	s1,24(sp)
    800004a4:	e84a                	sd	s2,16(sp)
    800004a6:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004a8:	c219                	beqz	a2,800004ae <printint+0x12>
    800004aa:	08054663          	bltz	a0,80000536 <printint+0x9a>
    x = -xx;
  else
    x = xx;
    800004ae:	2501                	sext.w	a0,a0
    800004b0:	4881                	li	a7,0
    800004b2:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004b6:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004b8:	2581                	sext.w	a1,a1
    800004ba:	00008617          	auipc	a2,0x8
    800004be:	b8660613          	addi	a2,a2,-1146 # 80008040 <digits>
    800004c2:	883a                	mv	a6,a4
    800004c4:	2705                	addiw	a4,a4,1
    800004c6:	02b577bb          	remuw	a5,a0,a1
    800004ca:	1782                	slli	a5,a5,0x20
    800004cc:	9381                	srli	a5,a5,0x20
    800004ce:	97b2                	add	a5,a5,a2
    800004d0:	0007c783          	lbu	a5,0(a5)
    800004d4:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004d8:	0005079b          	sext.w	a5,a0
    800004dc:	02b5553b          	divuw	a0,a0,a1
    800004e0:	0685                	addi	a3,a3,1
    800004e2:	feb7f0e3          	bgeu	a5,a1,800004c2 <printint+0x26>

  if(sign)
    800004e6:	00088b63          	beqz	a7,800004fc <printint+0x60>
    buf[i++] = '-';
    800004ea:	fe040793          	addi	a5,s0,-32
    800004ee:	973e                	add	a4,a4,a5
    800004f0:	02d00793          	li	a5,45
    800004f4:	fef70823          	sb	a5,-16(a4)
    800004f8:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    800004fc:	02e05763          	blez	a4,8000052a <printint+0x8e>
    80000500:	fd040793          	addi	a5,s0,-48
    80000504:	00e784b3          	add	s1,a5,a4
    80000508:	fff78913          	addi	s2,a5,-1
    8000050c:	993a                	add	s2,s2,a4
    8000050e:	377d                	addiw	a4,a4,-1
    80000510:	1702                	slli	a4,a4,0x20
    80000512:	9301                	srli	a4,a4,0x20
    80000514:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    80000518:	fff4c503          	lbu	a0,-1(s1)
    8000051c:	00000097          	auipc	ra,0x0
    80000520:	d60080e7          	jalr	-672(ra) # 8000027c <consputc>
  while(--i >= 0)
    80000524:	14fd                	addi	s1,s1,-1
    80000526:	ff2499e3          	bne	s1,s2,80000518 <printint+0x7c>
}
    8000052a:	70a2                	ld	ra,40(sp)
    8000052c:	7402                	ld	s0,32(sp)
    8000052e:	64e2                	ld	s1,24(sp)
    80000530:	6942                	ld	s2,16(sp)
    80000532:	6145                	addi	sp,sp,48
    80000534:	8082                	ret
    x = -xx;
    80000536:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    8000053a:	4885                	li	a7,1
    x = -xx;
    8000053c:	bf9d                	j	800004b2 <printint+0x16>

000000008000053e <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    8000053e:	1101                	addi	sp,sp,-32
    80000540:	ec06                	sd	ra,24(sp)
    80000542:	e822                	sd	s0,16(sp)
    80000544:	e426                	sd	s1,8(sp)
    80000546:	1000                	addi	s0,sp,32
    80000548:	84aa                	mv	s1,a0
  pr.locking = 0;
    8000054a:	00011797          	auipc	a5,0x11
    8000054e:	ce07ab23          	sw	zero,-778(a5) # 80011240 <pr+0x18>
  printf("panic: ");
    80000552:	00008517          	auipc	a0,0x8
    80000556:	ac650513          	addi	a0,a0,-1338 # 80008018 <etext+0x18>
    8000055a:	00000097          	auipc	ra,0x0
    8000055e:	02e080e7          	jalr	46(ra) # 80000588 <printf>
  printf(s);
    80000562:	8526                	mv	a0,s1
    80000564:	00000097          	auipc	ra,0x0
    80000568:	024080e7          	jalr	36(ra) # 80000588 <printf>
  printf("\n");
    8000056c:	00008517          	auipc	a0,0x8
    80000570:	b5c50513          	addi	a0,a0,-1188 # 800080c8 <digits+0x88>
    80000574:	00000097          	auipc	ra,0x0
    80000578:	014080e7          	jalr	20(ra) # 80000588 <printf>
  panicked = 1; // freeze uart output from other CPUs
    8000057c:	4785                	li	a5,1
    8000057e:	00009717          	auipc	a4,0x9
    80000582:	a8f72123          	sw	a5,-1406(a4) # 80009000 <panicked>
  for(;;)
    80000586:	a001                	j	80000586 <panic+0x48>

0000000080000588 <printf>:
{
    80000588:	7131                	addi	sp,sp,-192
    8000058a:	fc86                	sd	ra,120(sp)
    8000058c:	f8a2                	sd	s0,112(sp)
    8000058e:	f4a6                	sd	s1,104(sp)
    80000590:	f0ca                	sd	s2,96(sp)
    80000592:	ecce                	sd	s3,88(sp)
    80000594:	e8d2                	sd	s4,80(sp)
    80000596:	e4d6                	sd	s5,72(sp)
    80000598:	e0da                	sd	s6,64(sp)
    8000059a:	fc5e                	sd	s7,56(sp)
    8000059c:	f862                	sd	s8,48(sp)
    8000059e:	f466                	sd	s9,40(sp)
    800005a0:	f06a                	sd	s10,32(sp)
    800005a2:	ec6e                	sd	s11,24(sp)
    800005a4:	0100                	addi	s0,sp,128
    800005a6:	8a2a                	mv	s4,a0
    800005a8:	e40c                	sd	a1,8(s0)
    800005aa:	e810                	sd	a2,16(s0)
    800005ac:	ec14                	sd	a3,24(s0)
    800005ae:	f018                	sd	a4,32(s0)
    800005b0:	f41c                	sd	a5,40(s0)
    800005b2:	03043823          	sd	a6,48(s0)
    800005b6:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005ba:	00011d97          	auipc	s11,0x11
    800005be:	c86dad83          	lw	s11,-890(s11) # 80011240 <pr+0x18>
  if(locking)
    800005c2:	020d9b63          	bnez	s11,800005f8 <printf+0x70>
  if (fmt == 0)
    800005c6:	040a0263          	beqz	s4,8000060a <printf+0x82>
  va_start(ap, fmt);
    800005ca:	00840793          	addi	a5,s0,8
    800005ce:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005d2:	000a4503          	lbu	a0,0(s4)
    800005d6:	16050263          	beqz	a0,8000073a <printf+0x1b2>
    800005da:	4481                	li	s1,0
    if(c != '%'){
    800005dc:	02500a93          	li	s5,37
    switch(c){
    800005e0:	07000b13          	li	s6,112
  consputc('x');
    800005e4:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005e6:	00008b97          	auipc	s7,0x8
    800005ea:	a5ab8b93          	addi	s7,s7,-1446 # 80008040 <digits>
    switch(c){
    800005ee:	07300c93          	li	s9,115
    800005f2:	06400c13          	li	s8,100
    800005f6:	a82d                	j	80000630 <printf+0xa8>
    acquire(&pr.lock);
    800005f8:	00011517          	auipc	a0,0x11
    800005fc:	c3050513          	addi	a0,a0,-976 # 80011228 <pr>
    80000600:	00000097          	auipc	ra,0x0
    80000604:	5e4080e7          	jalr	1508(ra) # 80000be4 <acquire>
    80000608:	bf7d                	j	800005c6 <printf+0x3e>
    panic("null fmt");
    8000060a:	00008517          	auipc	a0,0x8
    8000060e:	a1e50513          	addi	a0,a0,-1506 # 80008028 <etext+0x28>
    80000612:	00000097          	auipc	ra,0x0
    80000616:	f2c080e7          	jalr	-212(ra) # 8000053e <panic>
      consputc(c);
    8000061a:	00000097          	auipc	ra,0x0
    8000061e:	c62080e7          	jalr	-926(ra) # 8000027c <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000622:	2485                	addiw	s1,s1,1
    80000624:	009a07b3          	add	a5,s4,s1
    80000628:	0007c503          	lbu	a0,0(a5)
    8000062c:	10050763          	beqz	a0,8000073a <printf+0x1b2>
    if(c != '%'){
    80000630:	ff5515e3          	bne	a0,s5,8000061a <printf+0x92>
    c = fmt[++i] & 0xff;
    80000634:	2485                	addiw	s1,s1,1
    80000636:	009a07b3          	add	a5,s4,s1
    8000063a:	0007c783          	lbu	a5,0(a5)
    8000063e:	0007891b          	sext.w	s2,a5
    if(c == 0)
    80000642:	cfe5                	beqz	a5,8000073a <printf+0x1b2>
    switch(c){
    80000644:	05678a63          	beq	a5,s6,80000698 <printf+0x110>
    80000648:	02fb7663          	bgeu	s6,a5,80000674 <printf+0xec>
    8000064c:	09978963          	beq	a5,s9,800006de <printf+0x156>
    80000650:	07800713          	li	a4,120
    80000654:	0ce79863          	bne	a5,a4,80000724 <printf+0x19c>
      printint(va_arg(ap, int), 16, 1);
    80000658:	f8843783          	ld	a5,-120(s0)
    8000065c:	00878713          	addi	a4,a5,8
    80000660:	f8e43423          	sd	a4,-120(s0)
    80000664:	4605                	li	a2,1
    80000666:	85ea                	mv	a1,s10
    80000668:	4388                	lw	a0,0(a5)
    8000066a:	00000097          	auipc	ra,0x0
    8000066e:	e32080e7          	jalr	-462(ra) # 8000049c <printint>
      break;
    80000672:	bf45                	j	80000622 <printf+0x9a>
    switch(c){
    80000674:	0b578263          	beq	a5,s5,80000718 <printf+0x190>
    80000678:	0b879663          	bne	a5,s8,80000724 <printf+0x19c>
      printint(va_arg(ap, int), 10, 1);
    8000067c:	f8843783          	ld	a5,-120(s0)
    80000680:	00878713          	addi	a4,a5,8
    80000684:	f8e43423          	sd	a4,-120(s0)
    80000688:	4605                	li	a2,1
    8000068a:	45a9                	li	a1,10
    8000068c:	4388                	lw	a0,0(a5)
    8000068e:	00000097          	auipc	ra,0x0
    80000692:	e0e080e7          	jalr	-498(ra) # 8000049c <printint>
      break;
    80000696:	b771                	j	80000622 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    80000698:	f8843783          	ld	a5,-120(s0)
    8000069c:	00878713          	addi	a4,a5,8
    800006a0:	f8e43423          	sd	a4,-120(s0)
    800006a4:	0007b983          	ld	s3,0(a5)
  consputc('0');
    800006a8:	03000513          	li	a0,48
    800006ac:	00000097          	auipc	ra,0x0
    800006b0:	bd0080e7          	jalr	-1072(ra) # 8000027c <consputc>
  consputc('x');
    800006b4:	07800513          	li	a0,120
    800006b8:	00000097          	auipc	ra,0x0
    800006bc:	bc4080e7          	jalr	-1084(ra) # 8000027c <consputc>
    800006c0:	896a                	mv	s2,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006c2:	03c9d793          	srli	a5,s3,0x3c
    800006c6:	97de                	add	a5,a5,s7
    800006c8:	0007c503          	lbu	a0,0(a5)
    800006cc:	00000097          	auipc	ra,0x0
    800006d0:	bb0080e7          	jalr	-1104(ra) # 8000027c <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006d4:	0992                	slli	s3,s3,0x4
    800006d6:	397d                	addiw	s2,s2,-1
    800006d8:	fe0915e3          	bnez	s2,800006c2 <printf+0x13a>
    800006dc:	b799                	j	80000622 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006de:	f8843783          	ld	a5,-120(s0)
    800006e2:	00878713          	addi	a4,a5,8
    800006e6:	f8e43423          	sd	a4,-120(s0)
    800006ea:	0007b903          	ld	s2,0(a5)
    800006ee:	00090e63          	beqz	s2,8000070a <printf+0x182>
      for(; *s; s++)
    800006f2:	00094503          	lbu	a0,0(s2)
    800006f6:	d515                	beqz	a0,80000622 <printf+0x9a>
        consputc(*s);
    800006f8:	00000097          	auipc	ra,0x0
    800006fc:	b84080e7          	jalr	-1148(ra) # 8000027c <consputc>
      for(; *s; s++)
    80000700:	0905                	addi	s2,s2,1
    80000702:	00094503          	lbu	a0,0(s2)
    80000706:	f96d                	bnez	a0,800006f8 <printf+0x170>
    80000708:	bf29                	j	80000622 <printf+0x9a>
        s = "(null)";
    8000070a:	00008917          	auipc	s2,0x8
    8000070e:	91690913          	addi	s2,s2,-1770 # 80008020 <etext+0x20>
      for(; *s; s++)
    80000712:	02800513          	li	a0,40
    80000716:	b7cd                	j	800006f8 <printf+0x170>
      consputc('%');
    80000718:	8556                	mv	a0,s5
    8000071a:	00000097          	auipc	ra,0x0
    8000071e:	b62080e7          	jalr	-1182(ra) # 8000027c <consputc>
      break;
    80000722:	b701                	j	80000622 <printf+0x9a>
      consputc('%');
    80000724:	8556                	mv	a0,s5
    80000726:	00000097          	auipc	ra,0x0
    8000072a:	b56080e7          	jalr	-1194(ra) # 8000027c <consputc>
      consputc(c);
    8000072e:	854a                	mv	a0,s2
    80000730:	00000097          	auipc	ra,0x0
    80000734:	b4c080e7          	jalr	-1204(ra) # 8000027c <consputc>
      break;
    80000738:	b5ed                	j	80000622 <printf+0x9a>
  if(locking)
    8000073a:	020d9163          	bnez	s11,8000075c <printf+0x1d4>
}
    8000073e:	70e6                	ld	ra,120(sp)
    80000740:	7446                	ld	s0,112(sp)
    80000742:	74a6                	ld	s1,104(sp)
    80000744:	7906                	ld	s2,96(sp)
    80000746:	69e6                	ld	s3,88(sp)
    80000748:	6a46                	ld	s4,80(sp)
    8000074a:	6aa6                	ld	s5,72(sp)
    8000074c:	6b06                	ld	s6,64(sp)
    8000074e:	7be2                	ld	s7,56(sp)
    80000750:	7c42                	ld	s8,48(sp)
    80000752:	7ca2                	ld	s9,40(sp)
    80000754:	7d02                	ld	s10,32(sp)
    80000756:	6de2                	ld	s11,24(sp)
    80000758:	6129                	addi	sp,sp,192
    8000075a:	8082                	ret
    release(&pr.lock);
    8000075c:	00011517          	auipc	a0,0x11
    80000760:	acc50513          	addi	a0,a0,-1332 # 80011228 <pr>
    80000764:	00000097          	auipc	ra,0x0
    80000768:	534080e7          	jalr	1332(ra) # 80000c98 <release>
}
    8000076c:	bfc9                	j	8000073e <printf+0x1b6>

000000008000076e <printfinit>:
    ;
}

void
printfinit(void)
{
    8000076e:	1101                	addi	sp,sp,-32
    80000770:	ec06                	sd	ra,24(sp)
    80000772:	e822                	sd	s0,16(sp)
    80000774:	e426                	sd	s1,8(sp)
    80000776:	1000                	addi	s0,sp,32
	initlock(&pr.lock, "pr");
    80000778:	00011497          	auipc	s1,0x11
    8000077c:	ab048493          	addi	s1,s1,-1360 # 80011228 <pr>
    80000780:	00008597          	auipc	a1,0x8
    80000784:	8b858593          	addi	a1,a1,-1864 # 80008038 <etext+0x38>
    80000788:	8526                	mv	a0,s1
    8000078a:	00000097          	auipc	ra,0x0
    8000078e:	3ca080e7          	jalr	970(ra) # 80000b54 <initlock>
	pr.locking = 1;
    80000792:	4785                	li	a5,1
    80000794:	cc9c                	sw	a5,24(s1)
}
    80000796:	60e2                	ld	ra,24(sp)
    80000798:	6442                	ld	s0,16(sp)
    8000079a:	64a2                	ld	s1,8(sp)
    8000079c:	6105                	addi	sp,sp,32
    8000079e:	8082                	ret

00000000800007a0 <uartinit>:

void uartstart();

void
uartinit(void)
{
    800007a0:	1141                	addi	sp,sp,-16
    800007a2:	e406                	sd	ra,8(sp)
    800007a4:	e022                	sd	s0,0(sp)
    800007a6:	0800                	addi	s0,sp,16
  // disable interrupts.
	WriteReg(IER, 0x00);
    800007a8:	100007b7          	lui	a5,0x10000
    800007ac:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
	WriteReg(LCR, LCR_BAUD_LATCH);
    800007b0:	f8000713          	li	a4,-128
    800007b4:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
	WriteReg(0, 0x03);
    800007b8:	470d                	li	a4,3
    800007ba:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
	WriteReg(1, 0x00);
    800007be:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
	WriteReg(LCR, LCR_EIGHT_BITS);
    800007c2:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
	WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007c6:	469d                	li	a3,7
    800007c8:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
	WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007cc:	00e780a3          	sb	a4,1(a5)

	initlock(&uart_tx_lock, "uart");
    800007d0:	00008597          	auipc	a1,0x8
    800007d4:	88858593          	addi	a1,a1,-1912 # 80008058 <digits+0x18>
    800007d8:	00011517          	auipc	a0,0x11
    800007dc:	a7050513          	addi	a0,a0,-1424 # 80011248 <uart_tx_lock>
    800007e0:	00000097          	auipc	ra,0x0
    800007e4:	374080e7          	jalr	884(ra) # 80000b54 <initlock>
}
    800007e8:	60a2                	ld	ra,8(sp)
    800007ea:	6402                	ld	s0,0(sp)
    800007ec:	0141                	addi	sp,sp,16
    800007ee:	8082                	ret

00000000800007f0 <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007f0:	1101                	addi	sp,sp,-32
    800007f2:	ec06                	sd	ra,24(sp)
    800007f4:	e822                	sd	s0,16(sp)
    800007f6:	e426                	sd	s1,8(sp)
    800007f8:	1000                	addi	s0,sp,32
    800007fa:	84aa                	mv	s1,a0
  push_off();
    800007fc:	00000097          	auipc	ra,0x0
    80000800:	39c080e7          	jalr	924(ra) # 80000b98 <push_off>

  if(panicked){
    80000804:	00008797          	auipc	a5,0x8
    80000808:	7fc7a783          	lw	a5,2044(a5) # 80009000 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000080c:	10000737          	lui	a4,0x10000
  if(panicked){
    80000810:	c391                	beqz	a5,80000814 <uartputc_sync+0x24>
    for(;;)
    80000812:	a001                	j	80000812 <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000814:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000818:	0ff7f793          	andi	a5,a5,255
    8000081c:	0207f793          	andi	a5,a5,32
    80000820:	dbf5                	beqz	a5,80000814 <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    80000822:	0ff4f793          	andi	a5,s1,255
    80000826:	10000737          	lui	a4,0x10000
    8000082a:	00f70023          	sb	a5,0(a4) # 10000000 <_entry-0x70000000>

  pop_off();
    8000082e:	00000097          	auipc	ra,0x0
    80000832:	40a080e7          	jalr	1034(ra) # 80000c38 <pop_off>
}
    80000836:	60e2                	ld	ra,24(sp)
    80000838:	6442                	ld	s0,16(sp)
    8000083a:	64a2                	ld	s1,8(sp)
    8000083c:	6105                	addi	sp,sp,32
    8000083e:	8082                	ret

0000000080000840 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000840:	00008717          	auipc	a4,0x8
    80000844:	7c873703          	ld	a4,1992(a4) # 80009008 <uart_tx_r>
    80000848:	00008797          	auipc	a5,0x8
    8000084c:	7c87b783          	ld	a5,1992(a5) # 80009010 <uart_tx_w>
    80000850:	06e78c63          	beq	a5,a4,800008c8 <uartstart+0x88>
{
    80000854:	7139                	addi	sp,sp,-64
    80000856:	fc06                	sd	ra,56(sp)
    80000858:	f822                	sd	s0,48(sp)
    8000085a:	f426                	sd	s1,40(sp)
    8000085c:	f04a                	sd	s2,32(sp)
    8000085e:	ec4e                	sd	s3,24(sp)
    80000860:	e852                	sd	s4,16(sp)
    80000862:	e456                	sd	s5,8(sp)
    80000864:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000866:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    8000086a:	00011a17          	auipc	s4,0x11
    8000086e:	9dea0a13          	addi	s4,s4,-1570 # 80011248 <uart_tx_lock>
    uart_tx_r += 1;
    80000872:	00008497          	auipc	s1,0x8
    80000876:	79648493          	addi	s1,s1,1942 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    8000087a:	00008997          	auipc	s3,0x8
    8000087e:	79698993          	addi	s3,s3,1942 # 80009010 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000882:	00594783          	lbu	a5,5(s2) # 10000005 <_entry-0x6ffffffb>
    80000886:	0ff7f793          	andi	a5,a5,255
    8000088a:	0207f793          	andi	a5,a5,32
    8000088e:	c785                	beqz	a5,800008b6 <uartstart+0x76>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000890:	01f77793          	andi	a5,a4,31
    80000894:	97d2                	add	a5,a5,s4
    80000896:	0187ca83          	lbu	s5,24(a5)
    uart_tx_r += 1;
    8000089a:	0705                	addi	a4,a4,1
    8000089c:	e098                	sd	a4,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    8000089e:	8526                	mv	a0,s1
    800008a0:	00002097          	auipc	ra,0x2
    800008a4:	9d4080e7          	jalr	-1580(ra) # 80002274 <wakeup>
    
    WriteReg(THR, c);
    800008a8:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    800008ac:	6098                	ld	a4,0(s1)
    800008ae:	0009b783          	ld	a5,0(s3)
    800008b2:	fce798e3          	bne	a5,a4,80000882 <uartstart+0x42>
  }
}
    800008b6:	70e2                	ld	ra,56(sp)
    800008b8:	7442                	ld	s0,48(sp)
    800008ba:	74a2                	ld	s1,40(sp)
    800008bc:	7902                	ld	s2,32(sp)
    800008be:	69e2                	ld	s3,24(sp)
    800008c0:	6a42                	ld	s4,16(sp)
    800008c2:	6aa2                	ld	s5,8(sp)
    800008c4:	6121                	addi	sp,sp,64
    800008c6:	8082                	ret
    800008c8:	8082                	ret

00000000800008ca <uartputc>:
{
    800008ca:	7179                	addi	sp,sp,-48
    800008cc:	f406                	sd	ra,40(sp)
    800008ce:	f022                	sd	s0,32(sp)
    800008d0:	ec26                	sd	s1,24(sp)
    800008d2:	e84a                	sd	s2,16(sp)
    800008d4:	e44e                	sd	s3,8(sp)
    800008d6:	e052                	sd	s4,0(sp)
    800008d8:	1800                	addi	s0,sp,48
    800008da:	89aa                	mv	s3,a0
  acquire(&uart_tx_lock);
    800008dc:	00011517          	auipc	a0,0x11
    800008e0:	96c50513          	addi	a0,a0,-1684 # 80011248 <uart_tx_lock>
    800008e4:	00000097          	auipc	ra,0x0
    800008e8:	300080e7          	jalr	768(ra) # 80000be4 <acquire>
  if(panicked){
    800008ec:	00008797          	auipc	a5,0x8
    800008f0:	7147a783          	lw	a5,1812(a5) # 80009000 <panicked>
    800008f4:	c391                	beqz	a5,800008f8 <uartputc+0x2e>
    for(;;)
    800008f6:	a001                	j	800008f6 <uartputc+0x2c>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008f8:	00008797          	auipc	a5,0x8
    800008fc:	7187b783          	ld	a5,1816(a5) # 80009010 <uart_tx_w>
    80000900:	00008717          	auipc	a4,0x8
    80000904:	70873703          	ld	a4,1800(a4) # 80009008 <uart_tx_r>
    80000908:	02070713          	addi	a4,a4,32
    8000090c:	02f71b63          	bne	a4,a5,80000942 <uartputc+0x78>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000910:	00011a17          	auipc	s4,0x11
    80000914:	938a0a13          	addi	s4,s4,-1736 # 80011248 <uart_tx_lock>
    80000918:	00008497          	auipc	s1,0x8
    8000091c:	6f048493          	addi	s1,s1,1776 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000920:	00008917          	auipc	s2,0x8
    80000924:	6f090913          	addi	s2,s2,1776 # 80009010 <uart_tx_w>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000928:	85d2                	mv	a1,s4
    8000092a:	8526                	mv	a0,s1
    8000092c:	00001097          	auipc	ra,0x1
    80000930:	7bc080e7          	jalr	1980(ra) # 800020e8 <sleep>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000934:	00093783          	ld	a5,0(s2)
    80000938:	6098                	ld	a4,0(s1)
    8000093a:	02070713          	addi	a4,a4,32
    8000093e:	fef705e3          	beq	a4,a5,80000928 <uartputc+0x5e>
      uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000942:	00011497          	auipc	s1,0x11
    80000946:	90648493          	addi	s1,s1,-1786 # 80011248 <uart_tx_lock>
    8000094a:	01f7f713          	andi	a4,a5,31
    8000094e:	9726                	add	a4,a4,s1
    80000950:	01370c23          	sb	s3,24(a4)
      uart_tx_w += 1;
    80000954:	0785                	addi	a5,a5,1
    80000956:	00008717          	auipc	a4,0x8
    8000095a:	6af73d23          	sd	a5,1722(a4) # 80009010 <uart_tx_w>
      uartstart();
    8000095e:	00000097          	auipc	ra,0x0
    80000962:	ee2080e7          	jalr	-286(ra) # 80000840 <uartstart>
      release(&uart_tx_lock);
    80000966:	8526                	mv	a0,s1
    80000968:	00000097          	auipc	ra,0x0
    8000096c:	330080e7          	jalr	816(ra) # 80000c98 <release>
}
    80000970:	70a2                	ld	ra,40(sp)
    80000972:	7402                	ld	s0,32(sp)
    80000974:	64e2                	ld	s1,24(sp)
    80000976:	6942                	ld	s2,16(sp)
    80000978:	69a2                	ld	s3,8(sp)
    8000097a:	6a02                	ld	s4,0(sp)
    8000097c:	6145                	addi	sp,sp,48
    8000097e:	8082                	ret

0000000080000980 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000980:	1141                	addi	sp,sp,-16
    80000982:	e422                	sd	s0,8(sp)
    80000984:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    80000986:	100007b7          	lui	a5,0x10000
    8000098a:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    8000098e:	8b85                	andi	a5,a5,1
    80000990:	cb91                	beqz	a5,800009a4 <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    80000992:	100007b7          	lui	a5,0x10000
    80000996:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    8000099a:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    8000099e:	6422                	ld	s0,8(sp)
    800009a0:	0141                	addi	sp,sp,16
    800009a2:	8082                	ret
    return -1;
    800009a4:	557d                	li	a0,-1
    800009a6:	bfe5                	j	8000099e <uartgetc+0x1e>

00000000800009a8 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from trap.c.
void
uartintr(void)
{
    800009a8:	1101                	addi	sp,sp,-32
    800009aa:	ec06                	sd	ra,24(sp)
    800009ac:	e822                	sd	s0,16(sp)
    800009ae:	e426                	sd	s1,8(sp)
    800009b0:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009b2:	54fd                	li	s1,-1
    int c = uartgetc();
    800009b4:	00000097          	auipc	ra,0x0
    800009b8:	fcc080e7          	jalr	-52(ra) # 80000980 <uartgetc>
    if(c == -1)
    800009bc:	00950763          	beq	a0,s1,800009ca <uartintr+0x22>
      break;
    consoleintr(c);
    800009c0:	00000097          	auipc	ra,0x0
    800009c4:	8fe080e7          	jalr	-1794(ra) # 800002be <consoleintr>
  while(1){
    800009c8:	b7f5                	j	800009b4 <uartintr+0xc>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009ca:	00011497          	auipc	s1,0x11
    800009ce:	87e48493          	addi	s1,s1,-1922 # 80011248 <uart_tx_lock>
    800009d2:	8526                	mv	a0,s1
    800009d4:	00000097          	auipc	ra,0x0
    800009d8:	210080e7          	jalr	528(ra) # 80000be4 <acquire>
  uartstart();
    800009dc:	00000097          	auipc	ra,0x0
    800009e0:	e64080e7          	jalr	-412(ra) # 80000840 <uartstart>
  release(&uart_tx_lock);
    800009e4:	8526                	mv	a0,s1
    800009e6:	00000097          	auipc	ra,0x0
    800009ea:	2b2080e7          	jalr	690(ra) # 80000c98 <release>
}
    800009ee:	60e2                	ld	ra,24(sp)
    800009f0:	6442                	ld	s0,16(sp)
    800009f2:	64a2                	ld	s1,8(sp)
    800009f4:	6105                	addi	sp,sp,32
    800009f6:	8082                	ret

00000000800009f8 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    800009f8:	1101                	addi	sp,sp,-32
    800009fa:	ec06                	sd	ra,24(sp)
    800009fc:	e822                	sd	s0,16(sp)
    800009fe:	e426                	sd	s1,8(sp)
    80000a00:	e04a                	sd	s2,0(sp)
    80000a02:	1000                	addi	s0,sp,32
	struct run *r;

	if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    80000a04:	03451793          	slli	a5,a0,0x34
    80000a08:	ebb9                	bnez	a5,80000a5e <kfree+0x66>
    80000a0a:	84aa                	mv	s1,a0
    80000a0c:	00025797          	auipc	a5,0x25
    80000a10:	5f478793          	addi	a5,a5,1524 # 80026000 <end>
    80000a14:	04f56563          	bltu	a0,a5,80000a5e <kfree+0x66>
    80000a18:	47c5                	li	a5,17
    80000a1a:	07ee                	slli	a5,a5,0x1b
    80000a1c:	04f57163          	bgeu	a0,a5,80000a5e <kfree+0x66>
		panic("kfree");

	// Fill with junk to catch dangling refs.
	memset(pa, 1, PGSIZE);
    80000a20:	6605                	lui	a2,0x1
    80000a22:	4585                	li	a1,1
    80000a24:	00000097          	auipc	ra,0x0
    80000a28:	2bc080e7          	jalr	700(ra) # 80000ce0 <memset>

	r = (struct run*)pa;

	acquire(&kmem.lock);
    80000a2c:	00011917          	auipc	s2,0x11
    80000a30:	85490913          	addi	s2,s2,-1964 # 80011280 <kmem>
    80000a34:	854a                	mv	a0,s2
    80000a36:	00000097          	auipc	ra,0x0
    80000a3a:	1ae080e7          	jalr	430(ra) # 80000be4 <acquire>
	r->next = kmem.freelist;
    80000a3e:	01893783          	ld	a5,24(s2)
    80000a42:	e09c                	sd	a5,0(s1)
	kmem.freelist = r;
    80000a44:	00993c23          	sd	s1,24(s2)
	release(&kmem.lock);
    80000a48:	854a                	mv	a0,s2
    80000a4a:	00000097          	auipc	ra,0x0
    80000a4e:	24e080e7          	jalr	590(ra) # 80000c98 <release>
}
    80000a52:	60e2                	ld	ra,24(sp)
    80000a54:	6442                	ld	s0,16(sp)
    80000a56:	64a2                	ld	s1,8(sp)
    80000a58:	6902                	ld	s2,0(sp)
    80000a5a:	6105                	addi	sp,sp,32
    80000a5c:	8082                	ret
		panic("kfree");
    80000a5e:	00007517          	auipc	a0,0x7
    80000a62:	60250513          	addi	a0,a0,1538 # 80008060 <digits+0x20>
    80000a66:	00000097          	auipc	ra,0x0
    80000a6a:	ad8080e7          	jalr	-1320(ra) # 8000053e <panic>

0000000080000a6e <freerange>:
{
    80000a6e:	7179                	addi	sp,sp,-48
    80000a70:	f406                	sd	ra,40(sp)
    80000a72:	f022                	sd	s0,32(sp)
    80000a74:	ec26                	sd	s1,24(sp)
    80000a76:	e84a                	sd	s2,16(sp)
    80000a78:	e44e                	sd	s3,8(sp)
    80000a7a:	e052                	sd	s4,0(sp)
    80000a7c:	1800                	addi	s0,sp,48
	p = (char*)PGROUNDUP((uint64)pa_start);
    80000a7e:	6785                	lui	a5,0x1
    80000a80:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000a84:	94aa                	add	s1,s1,a0
    80000a86:	757d                	lui	a0,0xfffff
    80000a88:	8ce9                	and	s1,s1,a0
	for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a8a:	94be                	add	s1,s1,a5
    80000a8c:	0095ee63          	bltu	a1,s1,80000aa8 <freerange+0x3a>
    80000a90:	892e                	mv	s2,a1
		kfree(p);
    80000a92:	7a7d                	lui	s4,0xfffff
	for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a94:	6985                	lui	s3,0x1
		kfree(p);
    80000a96:	01448533          	add	a0,s1,s4
    80000a9a:	00000097          	auipc	ra,0x0
    80000a9e:	f5e080e7          	jalr	-162(ra) # 800009f8 <kfree>
	for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000aa2:	94ce                	add	s1,s1,s3
    80000aa4:	fe9979e3          	bgeu	s2,s1,80000a96 <freerange+0x28>
}
    80000aa8:	70a2                	ld	ra,40(sp)
    80000aaa:	7402                	ld	s0,32(sp)
    80000aac:	64e2                	ld	s1,24(sp)
    80000aae:	6942                	ld	s2,16(sp)
    80000ab0:	69a2                	ld	s3,8(sp)
    80000ab2:	6a02                	ld	s4,0(sp)
    80000ab4:	6145                	addi	sp,sp,48
    80000ab6:	8082                	ret

0000000080000ab8 <kinit>:
{
    80000ab8:	1141                	addi	sp,sp,-16
    80000aba:	e406                	sd	ra,8(sp)
    80000abc:	e022                	sd	s0,0(sp)
    80000abe:	0800                	addi	s0,sp,16
	initlock(&kmem.lock, "kmem");
    80000ac0:	00007597          	auipc	a1,0x7
    80000ac4:	5a858593          	addi	a1,a1,1448 # 80008068 <digits+0x28>
    80000ac8:	00010517          	auipc	a0,0x10
    80000acc:	7b850513          	addi	a0,a0,1976 # 80011280 <kmem>
    80000ad0:	00000097          	auipc	ra,0x0
    80000ad4:	084080e7          	jalr	132(ra) # 80000b54 <initlock>
	freerange(end, (void*)PHYSTOP);
    80000ad8:	45c5                	li	a1,17
    80000ada:	05ee                	slli	a1,a1,0x1b
    80000adc:	00025517          	auipc	a0,0x25
    80000ae0:	52450513          	addi	a0,a0,1316 # 80026000 <end>
    80000ae4:	00000097          	auipc	ra,0x0
    80000ae8:	f8a080e7          	jalr	-118(ra) # 80000a6e <freerange>
}
    80000aec:	60a2                	ld	ra,8(sp)
    80000aee:	6402                	ld	s0,0(sp)
    80000af0:	0141                	addi	sp,sp,16
    80000af2:	8082                	ret

0000000080000af4 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000af4:	1101                	addi	sp,sp,-32
    80000af6:	ec06                	sd	ra,24(sp)
    80000af8:	e822                	sd	s0,16(sp)
    80000afa:	e426                	sd	s1,8(sp)
    80000afc:	1000                	addi	s0,sp,32
	struct run *r;

	acquire(&kmem.lock);
    80000afe:	00010497          	auipc	s1,0x10
    80000b02:	78248493          	addi	s1,s1,1922 # 80011280 <kmem>
    80000b06:	8526                	mv	a0,s1
    80000b08:	00000097          	auipc	ra,0x0
    80000b0c:	0dc080e7          	jalr	220(ra) # 80000be4 <acquire>
	r = kmem.freelist;
    80000b10:	6c84                	ld	s1,24(s1)
	if(r)
    80000b12:	c885                	beqz	s1,80000b42 <kalloc+0x4e>
		kmem.freelist = r->next;
    80000b14:	609c                	ld	a5,0(s1)
    80000b16:	00010517          	auipc	a0,0x10
    80000b1a:	76a50513          	addi	a0,a0,1898 # 80011280 <kmem>
    80000b1e:	ed1c                	sd	a5,24(a0)
	release(&kmem.lock);
    80000b20:	00000097          	auipc	ra,0x0
    80000b24:	178080e7          	jalr	376(ra) # 80000c98 <release>

	if(r)
		memset((char*)r, 5, PGSIZE); // fill with junk
    80000b28:	6605                	lui	a2,0x1
    80000b2a:	4595                	li	a1,5
    80000b2c:	8526                	mv	a0,s1
    80000b2e:	00000097          	auipc	ra,0x0
    80000b32:	1b2080e7          	jalr	434(ra) # 80000ce0 <memset>
	return (void*)r;
}
    80000b36:	8526                	mv	a0,s1
    80000b38:	60e2                	ld	ra,24(sp)
    80000b3a:	6442                	ld	s0,16(sp)
    80000b3c:	64a2                	ld	s1,8(sp)
    80000b3e:	6105                	addi	sp,sp,32
    80000b40:	8082                	ret
	release(&kmem.lock);
    80000b42:	00010517          	auipc	a0,0x10
    80000b46:	73e50513          	addi	a0,a0,1854 # 80011280 <kmem>
    80000b4a:	00000097          	auipc	ra,0x0
    80000b4e:	14e080e7          	jalr	334(ra) # 80000c98 <release>
	if(r)
    80000b52:	b7d5                	j	80000b36 <kalloc+0x42>

0000000080000b54 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b54:	1141                	addi	sp,sp,-16
    80000b56:	e422                	sd	s0,8(sp)
    80000b58:	0800                	addi	s0,sp,16
	lk->name = name;
    80000b5a:	e50c                	sd	a1,8(a0)
	lk->locked = 0;
    80000b5c:	00052023          	sw	zero,0(a0)
	lk->cpu = 0;
    80000b60:	00053823          	sd	zero,16(a0)
}
    80000b64:	6422                	ld	s0,8(sp)
    80000b66:	0141                	addi	sp,sp,16
    80000b68:	8082                	ret

0000000080000b6a <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b6a:	411c                	lw	a5,0(a0)
    80000b6c:	e399                	bnez	a5,80000b72 <holding+0x8>
    80000b6e:	4501                	li	a0,0
  return r;
}
    80000b70:	8082                	ret
{
    80000b72:	1101                	addi	sp,sp,-32
    80000b74:	ec06                	sd	ra,24(sp)
    80000b76:	e822                	sd	s0,16(sp)
    80000b78:	e426                	sd	s1,8(sp)
    80000b7a:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000b7c:	6904                	ld	s1,16(a0)
    80000b7e:	00001097          	auipc	ra,0x1
    80000b82:	e92080e7          	jalr	-366(ra) # 80001a10 <mycpu>
    80000b86:	40a48533          	sub	a0,s1,a0
    80000b8a:	00153513          	seqz	a0,a0
}
    80000b8e:	60e2                	ld	ra,24(sp)
    80000b90:	6442                	ld	s0,16(sp)
    80000b92:	64a2                	ld	s1,8(sp)
    80000b94:	6105                	addi	sp,sp,32
    80000b96:	8082                	ret

0000000080000b98 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000b98:	1101                	addi	sp,sp,-32
    80000b9a:	ec06                	sd	ra,24(sp)
    80000b9c:	e822                	sd	s0,16(sp)
    80000b9e:	e426                	sd	s1,8(sp)
    80000ba0:	1000                	addi	s0,sp,32
	asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000ba2:	100024f3          	csrr	s1,sstatus
    80000ba6:	100027f3          	csrr	a5,sstatus
	w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000baa:	9bf5                	andi	a5,a5,-3
	asm volatile("csrw sstatus, %0" : : "r" (x));
    80000bac:	10079073          	csrw	sstatus,a5
	int old = intr_get();

	intr_off();
	if(mycpu()->noff == 0)
    80000bb0:	00001097          	auipc	ra,0x1
    80000bb4:	e60080e7          	jalr	-416(ra) # 80001a10 <mycpu>
    80000bb8:	5d3c                	lw	a5,120(a0)
    80000bba:	cf89                	beqz	a5,80000bd4 <push_off+0x3c>
		mycpu()->intena = old;
	mycpu()->noff += 1;
    80000bbc:	00001097          	auipc	ra,0x1
    80000bc0:	e54080e7          	jalr	-428(ra) # 80001a10 <mycpu>
    80000bc4:	5d3c                	lw	a5,120(a0)
    80000bc6:	2785                	addiw	a5,a5,1
    80000bc8:	dd3c                	sw	a5,120(a0)
}
    80000bca:	60e2                	ld	ra,24(sp)
    80000bcc:	6442                	ld	s0,16(sp)
    80000bce:	64a2                	ld	s1,8(sp)
    80000bd0:	6105                	addi	sp,sp,32
    80000bd2:	8082                	ret
		mycpu()->intena = old;
    80000bd4:	00001097          	auipc	ra,0x1
    80000bd8:	e3c080e7          	jalr	-452(ra) # 80001a10 <mycpu>
	return (x & SSTATUS_SIE) != 0;
    80000bdc:	8085                	srli	s1,s1,0x1
    80000bde:	8885                	andi	s1,s1,1
    80000be0:	dd64                	sw	s1,124(a0)
    80000be2:	bfe9                	j	80000bbc <push_off+0x24>

0000000080000be4 <acquire>:
{
    80000be4:	1101                	addi	sp,sp,-32
    80000be6:	ec06                	sd	ra,24(sp)
    80000be8:	e822                	sd	s0,16(sp)
    80000bea:	e426                	sd	s1,8(sp)
    80000bec:	1000                	addi	s0,sp,32
    80000bee:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000bf0:	00000097          	auipc	ra,0x0
    80000bf4:	fa8080e7          	jalr	-88(ra) # 80000b98 <push_off>
  if(holding(lk))
    80000bf8:	8526                	mv	a0,s1
    80000bfa:	00000097          	auipc	ra,0x0
    80000bfe:	f70080e7          	jalr	-144(ra) # 80000b6a <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c02:	4705                	li	a4,1
  if(holding(lk))
    80000c04:	e115                	bnez	a0,80000c28 <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c06:	87ba                	mv	a5,a4
    80000c08:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000c0c:	2781                	sext.w	a5,a5
    80000c0e:	ffe5                	bnez	a5,80000c06 <acquire+0x22>
  __sync_synchronize();
    80000c10:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c14:	00001097          	auipc	ra,0x1
    80000c18:	dfc080e7          	jalr	-516(ra) # 80001a10 <mycpu>
    80000c1c:	e888                	sd	a0,16(s1)
}
    80000c1e:	60e2                	ld	ra,24(sp)
    80000c20:	6442                	ld	s0,16(sp)
    80000c22:	64a2                	ld	s1,8(sp)
    80000c24:	6105                	addi	sp,sp,32
    80000c26:	8082                	ret
    panic("acquire");
    80000c28:	00007517          	auipc	a0,0x7
    80000c2c:	44850513          	addi	a0,a0,1096 # 80008070 <digits+0x30>
    80000c30:	00000097          	auipc	ra,0x0
    80000c34:	90e080e7          	jalr	-1778(ra) # 8000053e <panic>

0000000080000c38 <pop_off>:

void
pop_off(void)
{
    80000c38:	1141                	addi	sp,sp,-16
    80000c3a:	e406                	sd	ra,8(sp)
    80000c3c:	e022                	sd	s0,0(sp)
    80000c3e:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c40:	00001097          	auipc	ra,0x1
    80000c44:	dd0080e7          	jalr	-560(ra) # 80001a10 <mycpu>
	asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c48:	100027f3          	csrr	a5,sstatus
	return (x & SSTATUS_SIE) != 0;
    80000c4c:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c4e:	e78d                	bnez	a5,80000c78 <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c50:	5d3c                	lw	a5,120(a0)
    80000c52:	02f05b63          	blez	a5,80000c88 <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c56:	37fd                	addiw	a5,a5,-1
    80000c58:	0007871b          	sext.w	a4,a5
    80000c5c:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c5e:	eb09                	bnez	a4,80000c70 <pop_off+0x38>
    80000c60:	5d7c                	lw	a5,124(a0)
    80000c62:	c799                	beqz	a5,80000c70 <pop_off+0x38>
	asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c64:	100027f3          	csrr	a5,sstatus
	w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c68:	0027e793          	ori	a5,a5,2
	asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c6c:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c70:	60a2                	ld	ra,8(sp)
    80000c72:	6402                	ld	s0,0(sp)
    80000c74:	0141                	addi	sp,sp,16
    80000c76:	8082                	ret
    panic("pop_off - interruptible");
    80000c78:	00007517          	auipc	a0,0x7
    80000c7c:	40050513          	addi	a0,a0,1024 # 80008078 <digits+0x38>
    80000c80:	00000097          	auipc	ra,0x0
    80000c84:	8be080e7          	jalr	-1858(ra) # 8000053e <panic>
    panic("pop_off");
    80000c88:	00007517          	auipc	a0,0x7
    80000c8c:	40850513          	addi	a0,a0,1032 # 80008090 <digits+0x50>
    80000c90:	00000097          	auipc	ra,0x0
    80000c94:	8ae080e7          	jalr	-1874(ra) # 8000053e <panic>

0000000080000c98 <release>:
{
    80000c98:	1101                	addi	sp,sp,-32
    80000c9a:	ec06                	sd	ra,24(sp)
    80000c9c:	e822                	sd	s0,16(sp)
    80000c9e:	e426                	sd	s1,8(sp)
    80000ca0:	1000                	addi	s0,sp,32
    80000ca2:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000ca4:	00000097          	auipc	ra,0x0
    80000ca8:	ec6080e7          	jalr	-314(ra) # 80000b6a <holding>
    80000cac:	c115                	beqz	a0,80000cd0 <release+0x38>
  lk->cpu = 0;
    80000cae:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000cb2:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000cb6:	0f50000f          	fence	iorw,ow
    80000cba:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000cbe:	00000097          	auipc	ra,0x0
    80000cc2:	f7a080e7          	jalr	-134(ra) # 80000c38 <pop_off>
}
    80000cc6:	60e2                	ld	ra,24(sp)
    80000cc8:	6442                	ld	s0,16(sp)
    80000cca:	64a2                	ld	s1,8(sp)
    80000ccc:	6105                	addi	sp,sp,32
    80000cce:	8082                	ret
    panic("release");
    80000cd0:	00007517          	auipc	a0,0x7
    80000cd4:	3c850513          	addi	a0,a0,968 # 80008098 <digits+0x58>
    80000cd8:	00000097          	auipc	ra,0x0
    80000cdc:	866080e7          	jalr	-1946(ra) # 8000053e <panic>

0000000080000ce0 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000ce0:	1141                	addi	sp,sp,-16
    80000ce2:	e422                	sd	s0,8(sp)
    80000ce4:	0800                	addi	s0,sp,16
	char *cdst = (char *) dst;
	int i;
	for(i = 0; i < n; i++){
    80000ce6:	ce09                	beqz	a2,80000d00 <memset+0x20>
    80000ce8:	87aa                	mv	a5,a0
    80000cea:	fff6071b          	addiw	a4,a2,-1
    80000cee:	1702                	slli	a4,a4,0x20
    80000cf0:	9301                	srli	a4,a4,0x20
    80000cf2:	0705                	addi	a4,a4,1
    80000cf4:	972a                	add	a4,a4,a0
		cdst[i] = c;
    80000cf6:	00b78023          	sb	a1,0(a5)
	for(i = 0; i < n; i++){
    80000cfa:	0785                	addi	a5,a5,1
    80000cfc:	fee79de3          	bne	a5,a4,80000cf6 <memset+0x16>
	}
	return dst;
}
    80000d00:	6422                	ld	s0,8(sp)
    80000d02:	0141                	addi	sp,sp,16
    80000d04:	8082                	ret

0000000080000d06 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000d06:	1141                	addi	sp,sp,-16
    80000d08:	e422                	sd	s0,8(sp)
    80000d0a:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000d0c:	ca05                	beqz	a2,80000d3c <memcmp+0x36>
    80000d0e:	fff6069b          	addiw	a3,a2,-1
    80000d12:	1682                	slli	a3,a3,0x20
    80000d14:	9281                	srli	a3,a3,0x20
    80000d16:	0685                	addi	a3,a3,1
    80000d18:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d1a:	00054783          	lbu	a5,0(a0)
    80000d1e:	0005c703          	lbu	a4,0(a1)
    80000d22:	00e79863          	bne	a5,a4,80000d32 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d26:	0505                	addi	a0,a0,1
    80000d28:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d2a:	fed518e3          	bne	a0,a3,80000d1a <memcmp+0x14>
  }

  return 0;
    80000d2e:	4501                	li	a0,0
    80000d30:	a019                	j	80000d36 <memcmp+0x30>
      return *s1 - *s2;
    80000d32:	40e7853b          	subw	a0,a5,a4
}
    80000d36:	6422                	ld	s0,8(sp)
    80000d38:	0141                	addi	sp,sp,16
    80000d3a:	8082                	ret
  return 0;
    80000d3c:	4501                	li	a0,0
    80000d3e:	bfe5                	j	80000d36 <memcmp+0x30>

0000000080000d40 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d40:	1141                	addi	sp,sp,-16
    80000d42:	e422                	sd	s0,8(sp)
    80000d44:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000d46:	ca0d                	beqz	a2,80000d78 <memmove+0x38>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d48:	00a5f963          	bgeu	a1,a0,80000d5a <memmove+0x1a>
    80000d4c:	02061693          	slli	a3,a2,0x20
    80000d50:	9281                	srli	a3,a3,0x20
    80000d52:	00d58733          	add	a4,a1,a3
    80000d56:	02e56463          	bltu	a0,a4,80000d7e <memmove+0x3e>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d5a:	fff6079b          	addiw	a5,a2,-1
    80000d5e:	1782                	slli	a5,a5,0x20
    80000d60:	9381                	srli	a5,a5,0x20
    80000d62:	0785                	addi	a5,a5,1
    80000d64:	97ae                	add	a5,a5,a1
    80000d66:	872a                	mv	a4,a0
      *d++ = *s++;
    80000d68:	0585                	addi	a1,a1,1
    80000d6a:	0705                	addi	a4,a4,1
    80000d6c:	fff5c683          	lbu	a3,-1(a1)
    80000d70:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000d74:	fef59ae3          	bne	a1,a5,80000d68 <memmove+0x28>

  return dst;
}
    80000d78:	6422                	ld	s0,8(sp)
    80000d7a:	0141                	addi	sp,sp,16
    80000d7c:	8082                	ret
    d += n;
    80000d7e:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000d80:	fff6079b          	addiw	a5,a2,-1
    80000d84:	1782                	slli	a5,a5,0x20
    80000d86:	9381                	srli	a5,a5,0x20
    80000d88:	fff7c793          	not	a5,a5
    80000d8c:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000d8e:	177d                	addi	a4,a4,-1
    80000d90:	16fd                	addi	a3,a3,-1
    80000d92:	00074603          	lbu	a2,0(a4)
    80000d96:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000d9a:	fef71ae3          	bne	a4,a5,80000d8e <memmove+0x4e>
    80000d9e:	bfe9                	j	80000d78 <memmove+0x38>

0000000080000da0 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000da0:	1141                	addi	sp,sp,-16
    80000da2:	e406                	sd	ra,8(sp)
    80000da4:	e022                	sd	s0,0(sp)
    80000da6:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000da8:	00000097          	auipc	ra,0x0
    80000dac:	f98080e7          	jalr	-104(ra) # 80000d40 <memmove>
}
    80000db0:	60a2                	ld	ra,8(sp)
    80000db2:	6402                	ld	s0,0(sp)
    80000db4:	0141                	addi	sp,sp,16
    80000db6:	8082                	ret

0000000080000db8 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000db8:	1141                	addi	sp,sp,-16
    80000dba:	e422                	sd	s0,8(sp)
    80000dbc:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000dbe:	ce11                	beqz	a2,80000dda <strncmp+0x22>
    80000dc0:	00054783          	lbu	a5,0(a0)
    80000dc4:	cf89                	beqz	a5,80000dde <strncmp+0x26>
    80000dc6:	0005c703          	lbu	a4,0(a1)
    80000dca:	00f71a63          	bne	a4,a5,80000dde <strncmp+0x26>
    n--, p++, q++;
    80000dce:	367d                	addiw	a2,a2,-1
    80000dd0:	0505                	addi	a0,a0,1
    80000dd2:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000dd4:	f675                	bnez	a2,80000dc0 <strncmp+0x8>
  if(n == 0)
    return 0;
    80000dd6:	4501                	li	a0,0
    80000dd8:	a809                	j	80000dea <strncmp+0x32>
    80000dda:	4501                	li	a0,0
    80000ddc:	a039                	j	80000dea <strncmp+0x32>
  if(n == 0)
    80000dde:	ca09                	beqz	a2,80000df0 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000de0:	00054503          	lbu	a0,0(a0)
    80000de4:	0005c783          	lbu	a5,0(a1)
    80000de8:	9d1d                	subw	a0,a0,a5
}
    80000dea:	6422                	ld	s0,8(sp)
    80000dec:	0141                	addi	sp,sp,16
    80000dee:	8082                	ret
    return 0;
    80000df0:	4501                	li	a0,0
    80000df2:	bfe5                	j	80000dea <strncmp+0x32>

0000000080000df4 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000df4:	1141                	addi	sp,sp,-16
    80000df6:	e422                	sd	s0,8(sp)
    80000df8:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000dfa:	872a                	mv	a4,a0
    80000dfc:	8832                	mv	a6,a2
    80000dfe:	367d                	addiw	a2,a2,-1
    80000e00:	01005963          	blez	a6,80000e12 <strncpy+0x1e>
    80000e04:	0705                	addi	a4,a4,1
    80000e06:	0005c783          	lbu	a5,0(a1)
    80000e0a:	fef70fa3          	sb	a5,-1(a4)
    80000e0e:	0585                	addi	a1,a1,1
    80000e10:	f7f5                	bnez	a5,80000dfc <strncpy+0x8>
    ;
  while(n-- > 0)
    80000e12:	00c05d63          	blez	a2,80000e2c <strncpy+0x38>
    80000e16:	86ba                	mv	a3,a4
    *s++ = 0;
    80000e18:	0685                	addi	a3,a3,1
    80000e1a:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e1e:	fff6c793          	not	a5,a3
    80000e22:	9fb9                	addw	a5,a5,a4
    80000e24:	010787bb          	addw	a5,a5,a6
    80000e28:	fef048e3          	bgtz	a5,80000e18 <strncpy+0x24>
  return os;
}
    80000e2c:	6422                	ld	s0,8(sp)
    80000e2e:	0141                	addi	sp,sp,16
    80000e30:	8082                	ret

0000000080000e32 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e32:	1141                	addi	sp,sp,-16
    80000e34:	e422                	sd	s0,8(sp)
    80000e36:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e38:	02c05363          	blez	a2,80000e5e <safestrcpy+0x2c>
    80000e3c:	fff6069b          	addiw	a3,a2,-1
    80000e40:	1682                	slli	a3,a3,0x20
    80000e42:	9281                	srli	a3,a3,0x20
    80000e44:	96ae                	add	a3,a3,a1
    80000e46:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e48:	00d58963          	beq	a1,a3,80000e5a <safestrcpy+0x28>
    80000e4c:	0585                	addi	a1,a1,1
    80000e4e:	0785                	addi	a5,a5,1
    80000e50:	fff5c703          	lbu	a4,-1(a1)
    80000e54:	fee78fa3          	sb	a4,-1(a5)
    80000e58:	fb65                	bnez	a4,80000e48 <safestrcpy+0x16>
    ;
  *s = 0;
    80000e5a:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e5e:	6422                	ld	s0,8(sp)
    80000e60:	0141                	addi	sp,sp,16
    80000e62:	8082                	ret

0000000080000e64 <strlen>:

int
strlen(const char *s)
{
    80000e64:	1141                	addi	sp,sp,-16
    80000e66:	e422                	sd	s0,8(sp)
    80000e68:	0800                	addi	s0,sp,16
	int n;

	for(n = 0; s[n]; n++)
    80000e6a:	00054783          	lbu	a5,0(a0)
    80000e6e:	cf91                	beqz	a5,80000e8a <strlen+0x26>
    80000e70:	0505                	addi	a0,a0,1
    80000e72:	87aa                	mv	a5,a0
    80000e74:	4685                	li	a3,1
    80000e76:	9e89                	subw	a3,a3,a0
    80000e78:	00f6853b          	addw	a0,a3,a5
    80000e7c:	0785                	addi	a5,a5,1
    80000e7e:	fff7c703          	lbu	a4,-1(a5)
    80000e82:	fb7d                	bnez	a4,80000e78 <strlen+0x14>
		;
	return n;
}
    80000e84:	6422                	ld	s0,8(sp)
    80000e86:	0141                	addi	sp,sp,16
    80000e88:	8082                	ret
	for(n = 0; s[n]; n++)
    80000e8a:	4501                	li	a0,0
    80000e8c:	bfe5                	j	80000e84 <strlen+0x20>

0000000080000e8e <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000e8e:	1141                	addi	sp,sp,-16
    80000e90:	e406                	sd	ra,8(sp)
    80000e92:	e022                	sd	s0,0(sp)
    80000e94:	0800                	addi	s0,sp,16
	if(cpuid() == 0){
    80000e96:	00001097          	auipc	ra,0x1
    80000e9a:	b6a080e7          	jalr	-1174(ra) # 80001a00 <cpuid>
    virtio_disk_init(); // emulated hard disk
		userinit();      // first user process
		__sync_synchronize();
		started = 1;
	} else {
		while(started == 0)
    80000e9e:	00008717          	auipc	a4,0x8
    80000ea2:	17a70713          	addi	a4,a4,378 # 80009018 <started>
	if(cpuid() == 0){
    80000ea6:	c139                	beqz	a0,80000eec <main+0x5e>
		while(started == 0)
    80000ea8:	431c                	lw	a5,0(a4)
    80000eaa:	2781                	sext.w	a5,a5
    80000eac:	dff5                	beqz	a5,80000ea8 <main+0x1a>
			;
		__sync_synchronize();
    80000eae:	0ff0000f          	fence
		printf("hart %d starting\n", cpuid());
    80000eb2:	00001097          	auipc	ra,0x1
    80000eb6:	b4e080e7          	jalr	-1202(ra) # 80001a00 <cpuid>
    80000eba:	85aa                	mv	a1,a0
    80000ebc:	00007517          	auipc	a0,0x7
    80000ec0:	1fc50513          	addi	a0,a0,508 # 800080b8 <digits+0x78>
    80000ec4:	fffff097          	auipc	ra,0xfffff
    80000ec8:	6c4080e7          	jalr	1732(ra) # 80000588 <printf>
    kvminithart();    // turn on paging
    80000ecc:	00000097          	auipc	ra,0x0
    80000ed0:	0d8080e7          	jalr	216(ra) # 80000fa4 <kvminithart>
		trapinithart();   // install kernel trap vector
    80000ed4:	00001097          	auipc	ra,0x1
    80000ed8:	7a4080e7          	jalr	1956(ra) # 80002678 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000edc:	00005097          	auipc	ra,0x5
    80000ee0:	cf4080e7          	jalr	-780(ra) # 80005bd0 <plicinithart>
	}

	scheduler();
    80000ee4:	00001097          	auipc	ra,0x1
    80000ee8:	052080e7          	jalr	82(ra) # 80001f36 <scheduler>
		consoleinit();
    80000eec:	fffff097          	auipc	ra,0xfffff
    80000ef0:	564080e7          	jalr	1380(ra) # 80000450 <consoleinit>
		printfinit();
    80000ef4:	00000097          	auipc	ra,0x0
    80000ef8:	87a080e7          	jalr	-1926(ra) # 8000076e <printfinit>
		printf("\n");
    80000efc:	00007517          	auipc	a0,0x7
    80000f00:	1cc50513          	addi	a0,a0,460 # 800080c8 <digits+0x88>
    80000f04:	fffff097          	auipc	ra,0xfffff
    80000f08:	684080e7          	jalr	1668(ra) # 80000588 <printf>
		printf("xv6 kernel is booting\n");
    80000f0c:	00007517          	auipc	a0,0x7
    80000f10:	19450513          	addi	a0,a0,404 # 800080a0 <digits+0x60>
    80000f14:	fffff097          	auipc	ra,0xfffff
    80000f18:	674080e7          	jalr	1652(ra) # 80000588 <printf>
		printf("\n");
    80000f1c:	00007517          	auipc	a0,0x7
    80000f20:	1ac50513          	addi	a0,a0,428 # 800080c8 <digits+0x88>
    80000f24:	fffff097          	auipc	ra,0xfffff
    80000f28:	664080e7          	jalr	1636(ra) # 80000588 <printf>
		kinit();         // physical page allocator
    80000f2c:	00000097          	auipc	ra,0x0
    80000f30:	b8c080e7          	jalr	-1140(ra) # 80000ab8 <kinit>
		kvminit();       // create kernel page table
    80000f34:	00000097          	auipc	ra,0x0
    80000f38:	322080e7          	jalr	802(ra) # 80001256 <kvminit>
		kvminithart();   // turn on paging
    80000f3c:	00000097          	auipc	ra,0x0
    80000f40:	068080e7          	jalr	104(ra) # 80000fa4 <kvminithart>
		procinit();      // process table
    80000f44:	00001097          	auipc	ra,0x1
    80000f48:	a0c080e7          	jalr	-1524(ra) # 80001950 <procinit>
		trapinit();      // trap vectors
    80000f4c:	00001097          	auipc	ra,0x1
    80000f50:	704080e7          	jalr	1796(ra) # 80002650 <trapinit>
		trapinithart();  // install kernel trap vector
    80000f54:	00001097          	auipc	ra,0x1
    80000f58:	724080e7          	jalr	1828(ra) # 80002678 <trapinithart>
	plicinit();      // set up interrupt controller
    80000f5c:	00005097          	auipc	ra,0x5
    80000f60:	c5e080e7          	jalr	-930(ra) # 80005bba <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f64:	00005097          	auipc	ra,0x5
    80000f68:	c6c080e7          	jalr	-916(ra) # 80005bd0 <plicinithart>
		binit();         // buffer cache
    80000f6c:	00002097          	auipc	ra,0x2
    80000f70:	e4e080e7          	jalr	-434(ra) # 80002dba <binit>
		iinit();         // inode table
    80000f74:	00002097          	auipc	ra,0x2
    80000f78:	4de080e7          	jalr	1246(ra) # 80003452 <iinit>
		fileinit();      // file table
    80000f7c:	00003097          	auipc	ra,0x3
    80000f80:	488080e7          	jalr	1160(ra) # 80004404 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f84:	00005097          	auipc	ra,0x5
    80000f88:	d6e080e7          	jalr	-658(ra) # 80005cf2 <virtio_disk_init>
		userinit();      // first user process
    80000f8c:	00001097          	auipc	ra,0x1
    80000f90:	d78080e7          	jalr	-648(ra) # 80001d04 <userinit>
		__sync_synchronize();
    80000f94:	0ff0000f          	fence
		started = 1;
    80000f98:	4785                	li	a5,1
    80000f9a:	00008717          	auipc	a4,0x8
    80000f9e:	06f72f23          	sw	a5,126(a4) # 80009018 <started>
    80000fa2:	b789                	j	80000ee4 <main+0x56>

0000000080000fa4 <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000fa4:	1141                	addi	sp,sp,-16
    80000fa6:	e422                	sd	s0,8(sp)
    80000fa8:	0800                	addi	s0,sp,16
	w_satp(MAKE_SATP(kernel_pagetable));
    80000faa:	00008797          	auipc	a5,0x8
    80000fae:	0767b783          	ld	a5,118(a5) # 80009020 <kernel_pagetable>
    80000fb2:	83b1                	srli	a5,a5,0xc
    80000fb4:	577d                	li	a4,-1
    80000fb6:	177e                	slli	a4,a4,0x3f
    80000fb8:	8fd9                	or	a5,a5,a4
	asm volatile("csrw satp, %0" : : "r" (x));
    80000fba:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
	// the zero, zero means flush all TLB entries.
	asm volatile("sfence.vma zero, zero");
    80000fbe:	12000073          	sfence.vma
	sfence_vma();
}
    80000fc2:	6422                	ld	s0,8(sp)
    80000fc4:	0141                	addi	sp,sp,16
    80000fc6:	8082                	ret

0000000080000fc8 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000fc8:	7139                	addi	sp,sp,-64
    80000fca:	fc06                	sd	ra,56(sp)
    80000fcc:	f822                	sd	s0,48(sp)
    80000fce:	f426                	sd	s1,40(sp)
    80000fd0:	f04a                	sd	s2,32(sp)
    80000fd2:	ec4e                	sd	s3,24(sp)
    80000fd4:	e852                	sd	s4,16(sp)
    80000fd6:	e456                	sd	s5,8(sp)
    80000fd8:	e05a                	sd	s6,0(sp)
    80000fda:	0080                	addi	s0,sp,64
    80000fdc:	84aa                	mv	s1,a0
    80000fde:	89ae                	mv	s3,a1
    80000fe0:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000fe2:	57fd                	li	a5,-1
    80000fe4:	83e9                	srli	a5,a5,0x1a
    80000fe6:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000fe8:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000fea:	04b7f263          	bgeu	a5,a1,8000102e <walk+0x66>
    panic("walk");
    80000fee:	00007517          	auipc	a0,0x7
    80000ff2:	0e250513          	addi	a0,a0,226 # 800080d0 <digits+0x90>
    80000ff6:	fffff097          	auipc	ra,0xfffff
    80000ffa:	548080e7          	jalr	1352(ra) # 8000053e <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80000ffe:	060a8663          	beqz	s5,8000106a <walk+0xa2>
    80001002:	00000097          	auipc	ra,0x0
    80001006:	af2080e7          	jalr	-1294(ra) # 80000af4 <kalloc>
    8000100a:	84aa                	mv	s1,a0
    8000100c:	c529                	beqz	a0,80001056 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    8000100e:	6605                	lui	a2,0x1
    80001010:	4581                	li	a1,0
    80001012:	00000097          	auipc	ra,0x0
    80001016:	cce080e7          	jalr	-818(ra) # 80000ce0 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    8000101a:	00c4d793          	srli	a5,s1,0xc
    8000101e:	07aa                	slli	a5,a5,0xa
    80001020:	0017e793          	ori	a5,a5,1
    80001024:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001028:	3a5d                	addiw	s4,s4,-9
    8000102a:	036a0063          	beq	s4,s6,8000104a <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    8000102e:	0149d933          	srl	s2,s3,s4
    80001032:	1ff97913          	andi	s2,s2,511
    80001036:	090e                	slli	s2,s2,0x3
    80001038:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    8000103a:	00093483          	ld	s1,0(s2)
    8000103e:	0014f793          	andi	a5,s1,1
    80001042:	dfd5                	beqz	a5,80000ffe <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001044:	80a9                	srli	s1,s1,0xa
    80001046:	04b2                	slli	s1,s1,0xc
    80001048:	b7c5                	j	80001028 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    8000104a:	00c9d513          	srli	a0,s3,0xc
    8000104e:	1ff57513          	andi	a0,a0,511
    80001052:	050e                	slli	a0,a0,0x3
    80001054:	9526                	add	a0,a0,s1
}
    80001056:	70e2                	ld	ra,56(sp)
    80001058:	7442                	ld	s0,48(sp)
    8000105a:	74a2                	ld	s1,40(sp)
    8000105c:	7902                	ld	s2,32(sp)
    8000105e:	69e2                	ld	s3,24(sp)
    80001060:	6a42                	ld	s4,16(sp)
    80001062:	6aa2                	ld	s5,8(sp)
    80001064:	6b02                	ld	s6,0(sp)
    80001066:	6121                	addi	sp,sp,64
    80001068:	8082                	ret
        return 0;
    8000106a:	4501                	li	a0,0
    8000106c:	b7ed                	j	80001056 <walk+0x8e>

000000008000106e <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    8000106e:	57fd                	li	a5,-1
    80001070:	83e9                	srli	a5,a5,0x1a
    80001072:	00b7f463          	bgeu	a5,a1,8000107a <walkaddr+0xc>
    return 0;
    80001076:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001078:	8082                	ret
{
    8000107a:	1141                	addi	sp,sp,-16
    8000107c:	e406                	sd	ra,8(sp)
    8000107e:	e022                	sd	s0,0(sp)
    80001080:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80001082:	4601                	li	a2,0
    80001084:	00000097          	auipc	ra,0x0
    80001088:	f44080e7          	jalr	-188(ra) # 80000fc8 <walk>
  if(pte == 0)
    8000108c:	c105                	beqz	a0,800010ac <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    8000108e:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    80001090:	0117f693          	andi	a3,a5,17
    80001094:	4745                	li	a4,17
    return 0;
    80001096:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    80001098:	00e68663          	beq	a3,a4,800010a4 <walkaddr+0x36>
}
    8000109c:	60a2                	ld	ra,8(sp)
    8000109e:	6402                	ld	s0,0(sp)
    800010a0:	0141                	addi	sp,sp,16
    800010a2:	8082                	ret
  pa = PTE2PA(*pte);
    800010a4:	00a7d513          	srli	a0,a5,0xa
    800010a8:	0532                	slli	a0,a0,0xc
  return pa;
    800010aa:	bfcd                	j	8000109c <walkaddr+0x2e>
    return 0;
    800010ac:	4501                	li	a0,0
    800010ae:	b7fd                	j	8000109c <walkaddr+0x2e>

00000000800010b0 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    800010b0:	715d                	addi	sp,sp,-80
    800010b2:	e486                	sd	ra,72(sp)
    800010b4:	e0a2                	sd	s0,64(sp)
    800010b6:	fc26                	sd	s1,56(sp)
    800010b8:	f84a                	sd	s2,48(sp)
    800010ba:	f44e                	sd	s3,40(sp)
    800010bc:	f052                	sd	s4,32(sp)
    800010be:	ec56                	sd	s5,24(sp)
    800010c0:	e85a                	sd	s6,16(sp)
    800010c2:	e45e                	sd	s7,8(sp)
    800010c4:	0880                	addi	s0,sp,80
	// uint64 i;
	pte_t *pte;

	// i = 0;

	if(size == 0)
    800010c6:	c205                	beqz	a2,800010e6 <mappages+0x36>
    800010c8:	8aaa                	mv	s5,a0
    800010ca:	8b3a                	mv	s6,a4
		panic("mappages: size");

	a = PGROUNDDOWN(va);
    800010cc:	77fd                	lui	a5,0xfffff
    800010ce:	00f5fa33          	and	s4,a1,a5
	last = PGROUNDDOWN(va + size - 1);
    800010d2:	15fd                	addi	a1,a1,-1
    800010d4:	00c589b3          	add	s3,a1,a2
    800010d8:	00f9f9b3          	and	s3,s3,a5
	a = PGROUNDDOWN(va);
    800010dc:	8952                	mv	s2,s4
    800010de:	41468a33          	sub	s4,a3,s4
			panic("mappages: remap");
		}
		*pte = PA2PTE(pa) | perm | PTE_V;
		if(a == last)
			break;
		a += PGSIZE;
    800010e2:	6b85                	lui	s7,0x1
    800010e4:	a015                	j	80001108 <mappages+0x58>
		panic("mappages: size");
    800010e6:	00007517          	auipc	a0,0x7
    800010ea:	ff250513          	addi	a0,a0,-14 # 800080d8 <digits+0x98>
    800010ee:	fffff097          	auipc	ra,0xfffff
    800010f2:	450080e7          	jalr	1104(ra) # 8000053e <panic>
			panic("mappages: remap");
    800010f6:	00007517          	auipc	a0,0x7
    800010fa:	ff250513          	addi	a0,a0,-14 # 800080e8 <digits+0xa8>
    800010fe:	fffff097          	auipc	ra,0xfffff
    80001102:	440080e7          	jalr	1088(ra) # 8000053e <panic>
		a += PGSIZE;
    80001106:	995e                	add	s2,s2,s7
	for(;;){
    80001108:	012a04b3          	add	s1,s4,s2
		if((pte = walk(pagetable, a, 1)) == 0)
    8000110c:	4605                	li	a2,1
    8000110e:	85ca                	mv	a1,s2
    80001110:	8556                	mv	a0,s5
    80001112:	00000097          	auipc	ra,0x0
    80001116:	eb6080e7          	jalr	-330(ra) # 80000fc8 <walk>
    8000111a:	cd19                	beqz	a0,80001138 <mappages+0x88>
		if(*pte & PTE_V){
    8000111c:	611c                	ld	a5,0(a0)
    8000111e:	8b85                	andi	a5,a5,1
    80001120:	fbf9                	bnez	a5,800010f6 <mappages+0x46>
		*pte = PA2PTE(pa) | perm | PTE_V;
    80001122:	80b1                	srli	s1,s1,0xc
    80001124:	04aa                	slli	s1,s1,0xa
    80001126:	0164e4b3          	or	s1,s1,s6
    8000112a:	0014e493          	ori	s1,s1,1
    8000112e:	e104                	sd	s1,0(a0)
		if(a == last)
    80001130:	fd391be3          	bne	s2,s3,80001106 <mappages+0x56>
		pa += PGSIZE;
	}
	return 0;
    80001134:	4501                	li	a0,0
    80001136:	a011                	j	8000113a <mappages+0x8a>
			return -1;
    80001138:	557d                	li	a0,-1
}
    8000113a:	60a6                	ld	ra,72(sp)
    8000113c:	6406                	ld	s0,64(sp)
    8000113e:	74e2                	ld	s1,56(sp)
    80001140:	7942                	ld	s2,48(sp)
    80001142:	79a2                	ld	s3,40(sp)
    80001144:	7a02                	ld	s4,32(sp)
    80001146:	6ae2                	ld	s5,24(sp)
    80001148:	6b42                	ld	s6,16(sp)
    8000114a:	6ba2                	ld	s7,8(sp)
    8000114c:	6161                	addi	sp,sp,80
    8000114e:	8082                	ret

0000000080001150 <kvmmap>:
{
    80001150:	1141                	addi	sp,sp,-16
    80001152:	e406                	sd	ra,8(sp)
    80001154:	e022                	sd	s0,0(sp)
    80001156:	0800                	addi	s0,sp,16
    80001158:	87b6                	mv	a5,a3
	if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    8000115a:	86b2                	mv	a3,a2
    8000115c:	863e                	mv	a2,a5
    8000115e:	00000097          	auipc	ra,0x0
    80001162:	f52080e7          	jalr	-174(ra) # 800010b0 <mappages>
    80001166:	e509                	bnez	a0,80001170 <kvmmap+0x20>
}
    80001168:	60a2                	ld	ra,8(sp)
    8000116a:	6402                	ld	s0,0(sp)
    8000116c:	0141                	addi	sp,sp,16
    8000116e:	8082                	ret
		panic("kvmmap");
    80001170:	00007517          	auipc	a0,0x7
    80001174:	f8850513          	addi	a0,a0,-120 # 800080f8 <digits+0xb8>
    80001178:	fffff097          	auipc	ra,0xfffff
    8000117c:	3c6080e7          	jalr	966(ra) # 8000053e <panic>

0000000080001180 <kvmmake>:
{
    80001180:	1101                	addi	sp,sp,-32
    80001182:	ec06                	sd	ra,24(sp)
    80001184:	e822                	sd	s0,16(sp)
    80001186:	e426                	sd	s1,8(sp)
    80001188:	e04a                	sd	s2,0(sp)
    8000118a:	1000                	addi	s0,sp,32
	kpgtbl = (pagetable_t) kalloc();
    8000118c:	00000097          	auipc	ra,0x0
    80001190:	968080e7          	jalr	-1688(ra) # 80000af4 <kalloc>
    80001194:	84aa                	mv	s1,a0
	memset(kpgtbl, 0, PGSIZE);
    80001196:	6605                	lui	a2,0x1
    80001198:	4581                	li	a1,0
    8000119a:	00000097          	auipc	ra,0x0
    8000119e:	b46080e7          	jalr	-1210(ra) # 80000ce0 <memset>
	kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    800011a2:	4719                	li	a4,6
    800011a4:	6685                	lui	a3,0x1
    800011a6:	10000637          	lui	a2,0x10000
    800011aa:	100005b7          	lui	a1,0x10000
    800011ae:	8526                	mv	a0,s1
    800011b0:	00000097          	auipc	ra,0x0
    800011b4:	fa0080e7          	jalr	-96(ra) # 80001150 <kvmmap>
	kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800011b8:	4719                	li	a4,6
    800011ba:	6685                	lui	a3,0x1
    800011bc:	10001637          	lui	a2,0x10001
    800011c0:	100015b7          	lui	a1,0x10001
    800011c4:	8526                	mv	a0,s1
    800011c6:	00000097          	auipc	ra,0x0
    800011ca:	f8a080e7          	jalr	-118(ra) # 80001150 <kvmmap>
	kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800011ce:	4719                	li	a4,6
    800011d0:	004006b7          	lui	a3,0x400
    800011d4:	0c000637          	lui	a2,0xc000
    800011d8:	0c0005b7          	lui	a1,0xc000
    800011dc:	8526                	mv	a0,s1
    800011de:	00000097          	auipc	ra,0x0
    800011e2:	f72080e7          	jalr	-142(ra) # 80001150 <kvmmap>
	kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800011e6:	00007917          	auipc	s2,0x7
    800011ea:	e1a90913          	addi	s2,s2,-486 # 80008000 <etext>
    800011ee:	4729                	li	a4,10
    800011f0:	80007697          	auipc	a3,0x80007
    800011f4:	e1068693          	addi	a3,a3,-496 # 8000 <_entry-0x7fff8000>
    800011f8:	4605                	li	a2,1
    800011fa:	067e                	slli	a2,a2,0x1f
    800011fc:	85b2                	mv	a1,a2
    800011fe:	8526                	mv	a0,s1
    80001200:	00000097          	auipc	ra,0x0
    80001204:	f50080e7          	jalr	-176(ra) # 80001150 <kvmmap>
	kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    80001208:	4719                	li	a4,6
    8000120a:	46c5                	li	a3,17
    8000120c:	06ee                	slli	a3,a3,0x1b
    8000120e:	412686b3          	sub	a3,a3,s2
    80001212:	864a                	mv	a2,s2
    80001214:	85ca                	mv	a1,s2
    80001216:	8526                	mv	a0,s1
    80001218:	00000097          	auipc	ra,0x0
    8000121c:	f38080e7          	jalr	-200(ra) # 80001150 <kvmmap>
	kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80001220:	4729                	li	a4,10
    80001222:	6685                	lui	a3,0x1
    80001224:	00006617          	auipc	a2,0x6
    80001228:	ddc60613          	addi	a2,a2,-548 # 80007000 <_trampoline>
    8000122c:	040005b7          	lui	a1,0x4000
    80001230:	15fd                	addi	a1,a1,-1
    80001232:	05b2                	slli	a1,a1,0xc
    80001234:	8526                	mv	a0,s1
    80001236:	00000097          	auipc	ra,0x0
    8000123a:	f1a080e7          	jalr	-230(ra) # 80001150 <kvmmap>
	proc_mapstacks(kpgtbl);
    8000123e:	8526                	mv	a0,s1
    80001240:	00000097          	auipc	ra,0x0
    80001244:	67a080e7          	jalr	1658(ra) # 800018ba <proc_mapstacks>
}
    80001248:	8526                	mv	a0,s1
    8000124a:	60e2                	ld	ra,24(sp)
    8000124c:	6442                	ld	s0,16(sp)
    8000124e:	64a2                	ld	s1,8(sp)
    80001250:	6902                	ld	s2,0(sp)
    80001252:	6105                	addi	sp,sp,32
    80001254:	8082                	ret

0000000080001256 <kvminit>:
{
    80001256:	1141                	addi	sp,sp,-16
    80001258:	e406                	sd	ra,8(sp)
    8000125a:	e022                	sd	s0,0(sp)
    8000125c:	0800                	addi	s0,sp,16
	kernel_pagetable = kvmmake();
    8000125e:	00000097          	auipc	ra,0x0
    80001262:	f22080e7          	jalr	-222(ra) # 80001180 <kvmmake>
    80001266:	00008797          	auipc	a5,0x8
    8000126a:	daa7bd23          	sd	a0,-582(a5) # 80009020 <kernel_pagetable>
}
    8000126e:	60a2                	ld	ra,8(sp)
    80001270:	6402                	ld	s0,0(sp)
    80001272:	0141                	addi	sp,sp,16
    80001274:	8082                	ret

0000000080001276 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001276:	715d                	addi	sp,sp,-80
    80001278:	e486                	sd	ra,72(sp)
    8000127a:	e0a2                	sd	s0,64(sp)
    8000127c:	fc26                	sd	s1,56(sp)
    8000127e:	f84a                	sd	s2,48(sp)
    80001280:	f44e                	sd	s3,40(sp)
    80001282:	f052                	sd	s4,32(sp)
    80001284:	ec56                	sd	s5,24(sp)
    80001286:	e85a                	sd	s6,16(sp)
    80001288:	e45e                	sd	s7,8(sp)
    8000128a:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    8000128c:	03459793          	slli	a5,a1,0x34
    80001290:	e795                	bnez	a5,800012bc <uvmunmap+0x46>
    80001292:	8a2a                	mv	s4,a0
    80001294:	892e                	mv	s2,a1
    80001296:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001298:	0632                	slli	a2,a2,0xc
    8000129a:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    8000129e:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012a0:	6b05                	lui	s6,0x1
    800012a2:	0735e863          	bltu	a1,s3,80001312 <uvmunmap+0x9c>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    800012a6:	60a6                	ld	ra,72(sp)
    800012a8:	6406                	ld	s0,64(sp)
    800012aa:	74e2                	ld	s1,56(sp)
    800012ac:	7942                	ld	s2,48(sp)
    800012ae:	79a2                	ld	s3,40(sp)
    800012b0:	7a02                	ld	s4,32(sp)
    800012b2:	6ae2                	ld	s5,24(sp)
    800012b4:	6b42                	ld	s6,16(sp)
    800012b6:	6ba2                	ld	s7,8(sp)
    800012b8:	6161                	addi	sp,sp,80
    800012ba:	8082                	ret
    panic("uvmunmap: not aligned");
    800012bc:	00007517          	auipc	a0,0x7
    800012c0:	e4450513          	addi	a0,a0,-444 # 80008100 <digits+0xc0>
    800012c4:	fffff097          	auipc	ra,0xfffff
    800012c8:	27a080e7          	jalr	634(ra) # 8000053e <panic>
      panic("uvmunmap: walk");
    800012cc:	00007517          	auipc	a0,0x7
    800012d0:	e4c50513          	addi	a0,a0,-436 # 80008118 <digits+0xd8>
    800012d4:	fffff097          	auipc	ra,0xfffff
    800012d8:	26a080e7          	jalr	618(ra) # 8000053e <panic>
      panic("uvmunmap: not mapped");
    800012dc:	00007517          	auipc	a0,0x7
    800012e0:	e4c50513          	addi	a0,a0,-436 # 80008128 <digits+0xe8>
    800012e4:	fffff097          	auipc	ra,0xfffff
    800012e8:	25a080e7          	jalr	602(ra) # 8000053e <panic>
      panic("uvmunmap: not a leaf");
    800012ec:	00007517          	auipc	a0,0x7
    800012f0:	e5450513          	addi	a0,a0,-428 # 80008140 <digits+0x100>
    800012f4:	fffff097          	auipc	ra,0xfffff
    800012f8:	24a080e7          	jalr	586(ra) # 8000053e <panic>
      uint64 pa = PTE2PA(*pte);
    800012fc:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    800012fe:	0532                	slli	a0,a0,0xc
    80001300:	fffff097          	auipc	ra,0xfffff
    80001304:	6f8080e7          	jalr	1784(ra) # 800009f8 <kfree>
    *pte = 0;
    80001308:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000130c:	995a                	add	s2,s2,s6
    8000130e:	f9397ce3          	bgeu	s2,s3,800012a6 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    80001312:	4601                	li	a2,0
    80001314:	85ca                	mv	a1,s2
    80001316:	8552                	mv	a0,s4
    80001318:	00000097          	auipc	ra,0x0
    8000131c:	cb0080e7          	jalr	-848(ra) # 80000fc8 <walk>
    80001320:	84aa                	mv	s1,a0
    80001322:	d54d                	beqz	a0,800012cc <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    80001324:	6108                	ld	a0,0(a0)
    80001326:	00157793          	andi	a5,a0,1
    8000132a:	dbcd                	beqz	a5,800012dc <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    8000132c:	3ff57793          	andi	a5,a0,1023
    80001330:	fb778ee3          	beq	a5,s7,800012ec <uvmunmap+0x76>
    if(do_free){
    80001334:	fc0a8ae3          	beqz	s5,80001308 <uvmunmap+0x92>
    80001338:	b7d1                	j	800012fc <uvmunmap+0x86>

000000008000133a <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    8000133a:	1101                	addi	sp,sp,-32
    8000133c:	ec06                	sd	ra,24(sp)
    8000133e:	e822                	sd	s0,16(sp)
    80001340:	e426                	sd	s1,8(sp)
    80001342:	1000                	addi	s0,sp,32
	pagetable_t pagetable;
	pagetable = (pagetable_t) kalloc();
    80001344:	fffff097          	auipc	ra,0xfffff
    80001348:	7b0080e7          	jalr	1968(ra) # 80000af4 <kalloc>
    8000134c:	84aa                	mv	s1,a0
	if(pagetable == 0)
    8000134e:	c519                	beqz	a0,8000135c <uvmcreate+0x22>
		return 0;
	memset(pagetable, 0, PGSIZE);
    80001350:	6605                	lui	a2,0x1
    80001352:	4581                	li	a1,0
    80001354:	00000097          	auipc	ra,0x0
    80001358:	98c080e7          	jalr	-1652(ra) # 80000ce0 <memset>
	return pagetable;
}
    8000135c:	8526                	mv	a0,s1
    8000135e:	60e2                	ld	ra,24(sp)
    80001360:	6442                	ld	s0,16(sp)
    80001362:	64a2                	ld	s1,8(sp)
    80001364:	6105                	addi	sp,sp,32
    80001366:	8082                	ret

0000000080001368 <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    80001368:	7179                	addi	sp,sp,-48
    8000136a:	f406                	sd	ra,40(sp)
    8000136c:	f022                	sd	s0,32(sp)
    8000136e:	ec26                	sd	s1,24(sp)
    80001370:	e84a                	sd	s2,16(sp)
    80001372:	e44e                	sd	s3,8(sp)
    80001374:	e052                	sd	s4,0(sp)
    80001376:	1800                	addi	s0,sp,48
	char *mem;

	if(sz >= PGSIZE)
    80001378:	6785                	lui	a5,0x1
    8000137a:	04f67863          	bgeu	a2,a5,800013ca <uvminit+0x62>
    8000137e:	8a2a                	mv	s4,a0
    80001380:	89ae                	mv	s3,a1
    80001382:	84b2                	mv	s1,a2
		panic("inituvm: more than a page");
	mem = kalloc();
    80001384:	fffff097          	auipc	ra,0xfffff
    80001388:	770080e7          	jalr	1904(ra) # 80000af4 <kalloc>
    8000138c:	892a                	mv	s2,a0
	memset(mem, 0, PGSIZE);
    8000138e:	6605                	lui	a2,0x1
    80001390:	4581                	li	a1,0
    80001392:	00000097          	auipc	ra,0x0
    80001396:	94e080e7          	jalr	-1714(ra) # 80000ce0 <memset>
	mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    8000139a:	4779                	li	a4,30
    8000139c:	86ca                	mv	a3,s2
    8000139e:	6605                	lui	a2,0x1
    800013a0:	4581                	li	a1,0
    800013a2:	8552                	mv	a0,s4
    800013a4:	00000097          	auipc	ra,0x0
    800013a8:	d0c080e7          	jalr	-756(ra) # 800010b0 <mappages>
	memmove(mem, src, sz);
    800013ac:	8626                	mv	a2,s1
    800013ae:	85ce                	mv	a1,s3
    800013b0:	854a                	mv	a0,s2
    800013b2:	00000097          	auipc	ra,0x0
    800013b6:	98e080e7          	jalr	-1650(ra) # 80000d40 <memmove>
}
    800013ba:	70a2                	ld	ra,40(sp)
    800013bc:	7402                	ld	s0,32(sp)
    800013be:	64e2                	ld	s1,24(sp)
    800013c0:	6942                	ld	s2,16(sp)
    800013c2:	69a2                	ld	s3,8(sp)
    800013c4:	6a02                	ld	s4,0(sp)
    800013c6:	6145                	addi	sp,sp,48
    800013c8:	8082                	ret
		panic("inituvm: more than a page");
    800013ca:	00007517          	auipc	a0,0x7
    800013ce:	d8e50513          	addi	a0,a0,-626 # 80008158 <digits+0x118>
    800013d2:	fffff097          	auipc	ra,0xfffff
    800013d6:	16c080e7          	jalr	364(ra) # 8000053e <panic>

00000000800013da <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800013da:	1101                	addi	sp,sp,-32
    800013dc:	ec06                	sd	ra,24(sp)
    800013de:	e822                	sd	s0,16(sp)
    800013e0:	e426                	sd	s1,8(sp)
    800013e2:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800013e4:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800013e6:	00b67d63          	bgeu	a2,a1,80001400 <uvmdealloc+0x26>
    800013ea:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800013ec:	6785                	lui	a5,0x1
    800013ee:	17fd                	addi	a5,a5,-1
    800013f0:	00f60733          	add	a4,a2,a5
    800013f4:	767d                	lui	a2,0xfffff
    800013f6:	8f71                	and	a4,a4,a2
    800013f8:	97ae                	add	a5,a5,a1
    800013fa:	8ff1                	and	a5,a5,a2
    800013fc:	00f76863          	bltu	a4,a5,8000140c <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    80001400:	8526                	mv	a0,s1
    80001402:	60e2                	ld	ra,24(sp)
    80001404:	6442                	ld	s0,16(sp)
    80001406:	64a2                	ld	s1,8(sp)
    80001408:	6105                	addi	sp,sp,32
    8000140a:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    8000140c:	8f99                	sub	a5,a5,a4
    8000140e:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    80001410:	4685                	li	a3,1
    80001412:	0007861b          	sext.w	a2,a5
    80001416:	85ba                	mv	a1,a4
    80001418:	00000097          	auipc	ra,0x0
    8000141c:	e5e080e7          	jalr	-418(ra) # 80001276 <uvmunmap>
    80001420:	b7c5                	j	80001400 <uvmdealloc+0x26>

0000000080001422 <uvmalloc>:
	if(newsz < oldsz)
    80001422:	0ab66163          	bltu	a2,a1,800014c4 <uvmalloc+0xa2>
{
    80001426:	7139                	addi	sp,sp,-64
    80001428:	fc06                	sd	ra,56(sp)
    8000142a:	f822                	sd	s0,48(sp)
    8000142c:	f426                	sd	s1,40(sp)
    8000142e:	f04a                	sd	s2,32(sp)
    80001430:	ec4e                	sd	s3,24(sp)
    80001432:	e852                	sd	s4,16(sp)
    80001434:	e456                	sd	s5,8(sp)
    80001436:	0080                	addi	s0,sp,64
    80001438:	8aaa                	mv	s5,a0
    8000143a:	8a32                	mv	s4,a2
	oldsz = PGROUNDUP(oldsz);
    8000143c:	6985                	lui	s3,0x1
    8000143e:	19fd                	addi	s3,s3,-1
    80001440:	95ce                	add	a1,a1,s3
    80001442:	79fd                	lui	s3,0xfffff
    80001444:	0135f9b3          	and	s3,a1,s3
	for(a = oldsz; a < newsz; a += PGSIZE){
    80001448:	08c9f063          	bgeu	s3,a2,800014c8 <uvmalloc+0xa6>
    8000144c:	894e                	mv	s2,s3
		mem = kalloc();
    8000144e:	fffff097          	auipc	ra,0xfffff
    80001452:	6a6080e7          	jalr	1702(ra) # 80000af4 <kalloc>
    80001456:	84aa                	mv	s1,a0
		if(mem == 0){
    80001458:	c51d                	beqz	a0,80001486 <uvmalloc+0x64>
		memset(mem, 0, PGSIZE);
    8000145a:	6605                	lui	a2,0x1
    8000145c:	4581                	li	a1,0
    8000145e:	00000097          	auipc	ra,0x0
    80001462:	882080e7          	jalr	-1918(ra) # 80000ce0 <memset>
		if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    80001466:	4779                	li	a4,30
    80001468:	86a6                	mv	a3,s1
    8000146a:	6605                	lui	a2,0x1
    8000146c:	85ca                	mv	a1,s2
    8000146e:	8556                	mv	a0,s5
    80001470:	00000097          	auipc	ra,0x0
    80001474:	c40080e7          	jalr	-960(ra) # 800010b0 <mappages>
    80001478:	e905                	bnez	a0,800014a8 <uvmalloc+0x86>
	for(a = oldsz; a < newsz; a += PGSIZE){
    8000147a:	6785                	lui	a5,0x1
    8000147c:	993e                	add	s2,s2,a5
    8000147e:	fd4968e3          	bltu	s2,s4,8000144e <uvmalloc+0x2c>
	return newsz;
    80001482:	8552                	mv	a0,s4
    80001484:	a809                	j	80001496 <uvmalloc+0x74>
			uvmdealloc(pagetable, a, oldsz);
    80001486:	864e                	mv	a2,s3
    80001488:	85ca                	mv	a1,s2
    8000148a:	8556                	mv	a0,s5
    8000148c:	00000097          	auipc	ra,0x0
    80001490:	f4e080e7          	jalr	-178(ra) # 800013da <uvmdealloc>
			return 0;
    80001494:	4501                	li	a0,0
}
    80001496:	70e2                	ld	ra,56(sp)
    80001498:	7442                	ld	s0,48(sp)
    8000149a:	74a2                	ld	s1,40(sp)
    8000149c:	7902                	ld	s2,32(sp)
    8000149e:	69e2                	ld	s3,24(sp)
    800014a0:	6a42                	ld	s4,16(sp)
    800014a2:	6aa2                	ld	s5,8(sp)
    800014a4:	6121                	addi	sp,sp,64
    800014a6:	8082                	ret
			kfree(mem);
    800014a8:	8526                	mv	a0,s1
    800014aa:	fffff097          	auipc	ra,0xfffff
    800014ae:	54e080e7          	jalr	1358(ra) # 800009f8 <kfree>
			uvmdealloc(pagetable, a, oldsz);
    800014b2:	864e                	mv	a2,s3
    800014b4:	85ca                	mv	a1,s2
    800014b6:	8556                	mv	a0,s5
    800014b8:	00000097          	auipc	ra,0x0
    800014bc:	f22080e7          	jalr	-222(ra) # 800013da <uvmdealloc>
			return 0;
    800014c0:	4501                	li	a0,0
    800014c2:	bfd1                	j	80001496 <uvmalloc+0x74>
		return oldsz;
    800014c4:	852e                	mv	a0,a1
}
    800014c6:	8082                	ret
	return newsz;
    800014c8:	8532                	mv	a0,a2
    800014ca:	b7f1                	j	80001496 <uvmalloc+0x74>

00000000800014cc <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800014cc:	7179                	addi	sp,sp,-48
    800014ce:	f406                	sd	ra,40(sp)
    800014d0:	f022                	sd	s0,32(sp)
    800014d2:	ec26                	sd	s1,24(sp)
    800014d4:	e84a                	sd	s2,16(sp)
    800014d6:	e44e                	sd	s3,8(sp)
    800014d8:	e052                	sd	s4,0(sp)
    800014da:	1800                	addi	s0,sp,48
    800014dc:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800014de:	84aa                	mv	s1,a0
    800014e0:	6905                	lui	s2,0x1
    800014e2:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014e4:	4985                	li	s3,1
    800014e6:	a821                	j	800014fe <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800014e8:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    800014ea:	0532                	slli	a0,a0,0xc
    800014ec:	00000097          	auipc	ra,0x0
    800014f0:	fe0080e7          	jalr	-32(ra) # 800014cc <freewalk>
      pagetable[i] = 0;
    800014f4:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800014f8:	04a1                	addi	s1,s1,8
    800014fa:	03248163          	beq	s1,s2,8000151c <freewalk+0x50>
    pte_t pte = pagetable[i];
    800014fe:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001500:	00f57793          	andi	a5,a0,15
    80001504:	ff3782e3          	beq	a5,s3,800014e8 <freewalk+0x1c>
    } else if(pte & PTE_V){
    80001508:	8905                	andi	a0,a0,1
    8000150a:	d57d                	beqz	a0,800014f8 <freewalk+0x2c>
      panic("freewalk: leaf");
    8000150c:	00007517          	auipc	a0,0x7
    80001510:	c6c50513          	addi	a0,a0,-916 # 80008178 <digits+0x138>
    80001514:	fffff097          	auipc	ra,0xfffff
    80001518:	02a080e7          	jalr	42(ra) # 8000053e <panic>
    }
  }
  kfree((void*)pagetable);
    8000151c:	8552                	mv	a0,s4
    8000151e:	fffff097          	auipc	ra,0xfffff
    80001522:	4da080e7          	jalr	1242(ra) # 800009f8 <kfree>
}
    80001526:	70a2                	ld	ra,40(sp)
    80001528:	7402                	ld	s0,32(sp)
    8000152a:	64e2                	ld	s1,24(sp)
    8000152c:	6942                	ld	s2,16(sp)
    8000152e:	69a2                	ld	s3,8(sp)
    80001530:	6a02                	ld	s4,0(sp)
    80001532:	6145                	addi	sp,sp,48
    80001534:	8082                	ret

0000000080001536 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    80001536:	1101                	addi	sp,sp,-32
    80001538:	ec06                	sd	ra,24(sp)
    8000153a:	e822                	sd	s0,16(sp)
    8000153c:	e426                	sd	s1,8(sp)
    8000153e:	1000                	addi	s0,sp,32
    80001540:	84aa                	mv	s1,a0
	if(sz > 0)
    80001542:	e999                	bnez	a1,80001558 <uvmfree+0x22>
		uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
	freewalk(pagetable);
    80001544:	8526                	mv	a0,s1
    80001546:	00000097          	auipc	ra,0x0
    8000154a:	f86080e7          	jalr	-122(ra) # 800014cc <freewalk>
}
    8000154e:	60e2                	ld	ra,24(sp)
    80001550:	6442                	ld	s0,16(sp)
    80001552:	64a2                	ld	s1,8(sp)
    80001554:	6105                	addi	sp,sp,32
    80001556:	8082                	ret
		uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001558:	6605                	lui	a2,0x1
    8000155a:	167d                	addi	a2,a2,-1
    8000155c:	962e                	add	a2,a2,a1
    8000155e:	4685                	li	a3,1
    80001560:	8231                	srli	a2,a2,0xc
    80001562:	4581                	li	a1,0
    80001564:	00000097          	auipc	ra,0x0
    80001568:	d12080e7          	jalr	-750(ra) # 80001276 <uvmunmap>
    8000156c:	bfe1                	j	80001544 <uvmfree+0xe>

000000008000156e <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    8000156e:	c679                	beqz	a2,8000163c <uvmcopy+0xce>
{
    80001570:	715d                	addi	sp,sp,-80
    80001572:	e486                	sd	ra,72(sp)
    80001574:	e0a2                	sd	s0,64(sp)
    80001576:	fc26                	sd	s1,56(sp)
    80001578:	f84a                	sd	s2,48(sp)
    8000157a:	f44e                	sd	s3,40(sp)
    8000157c:	f052                	sd	s4,32(sp)
    8000157e:	ec56                	sd	s5,24(sp)
    80001580:	e85a                	sd	s6,16(sp)
    80001582:	e45e                	sd	s7,8(sp)
    80001584:	0880                	addi	s0,sp,80
    80001586:	8b2a                	mv	s6,a0
    80001588:	8aae                	mv	s5,a1
    8000158a:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    8000158c:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    8000158e:	4601                	li	a2,0
    80001590:	85ce                	mv	a1,s3
    80001592:	855a                	mv	a0,s6
    80001594:	00000097          	auipc	ra,0x0
    80001598:	a34080e7          	jalr	-1484(ra) # 80000fc8 <walk>
    8000159c:	c531                	beqz	a0,800015e8 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    8000159e:	6118                	ld	a4,0(a0)
    800015a0:	00177793          	andi	a5,a4,1
    800015a4:	cbb1                	beqz	a5,800015f8 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    800015a6:	00a75593          	srli	a1,a4,0xa
    800015aa:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    800015ae:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    800015b2:	fffff097          	auipc	ra,0xfffff
    800015b6:	542080e7          	jalr	1346(ra) # 80000af4 <kalloc>
    800015ba:	892a                	mv	s2,a0
    800015bc:	c939                	beqz	a0,80001612 <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800015be:	6605                	lui	a2,0x1
    800015c0:	85de                	mv	a1,s7
    800015c2:	fffff097          	auipc	ra,0xfffff
    800015c6:	77e080e7          	jalr	1918(ra) # 80000d40 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800015ca:	8726                	mv	a4,s1
    800015cc:	86ca                	mv	a3,s2
    800015ce:	6605                	lui	a2,0x1
    800015d0:	85ce                	mv	a1,s3
    800015d2:	8556                	mv	a0,s5
    800015d4:	00000097          	auipc	ra,0x0
    800015d8:	adc080e7          	jalr	-1316(ra) # 800010b0 <mappages>
    800015dc:	e515                	bnez	a0,80001608 <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800015de:	6785                	lui	a5,0x1
    800015e0:	99be                	add	s3,s3,a5
    800015e2:	fb49e6e3          	bltu	s3,s4,8000158e <uvmcopy+0x20>
    800015e6:	a081                	j	80001626 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800015e8:	00007517          	auipc	a0,0x7
    800015ec:	ba050513          	addi	a0,a0,-1120 # 80008188 <digits+0x148>
    800015f0:	fffff097          	auipc	ra,0xfffff
    800015f4:	f4e080e7          	jalr	-178(ra) # 8000053e <panic>
      panic("uvmcopy: page not present");
    800015f8:	00007517          	auipc	a0,0x7
    800015fc:	bb050513          	addi	a0,a0,-1104 # 800081a8 <digits+0x168>
    80001600:	fffff097          	auipc	ra,0xfffff
    80001604:	f3e080e7          	jalr	-194(ra) # 8000053e <panic>
      kfree(mem);
    80001608:	854a                	mv	a0,s2
    8000160a:	fffff097          	auipc	ra,0xfffff
    8000160e:	3ee080e7          	jalr	1006(ra) # 800009f8 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001612:	4685                	li	a3,1
    80001614:	00c9d613          	srli	a2,s3,0xc
    80001618:	4581                	li	a1,0
    8000161a:	8556                	mv	a0,s5
    8000161c:	00000097          	auipc	ra,0x0
    80001620:	c5a080e7          	jalr	-934(ra) # 80001276 <uvmunmap>
  return -1;
    80001624:	557d                	li	a0,-1
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
  return 0;
    8000163c:	4501                	li	a0,0
}
    8000163e:	8082                	ret

0000000080001640 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001640:	1141                	addi	sp,sp,-16
    80001642:	e406                	sd	ra,8(sp)
    80001644:	e022                	sd	s0,0(sp)
    80001646:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001648:	4601                	li	a2,0
    8000164a:	00000097          	auipc	ra,0x0
    8000164e:	97e080e7          	jalr	-1666(ra) # 80000fc8 <walk>
  if(pte == 0)
    80001652:	c901                	beqz	a0,80001662 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    80001654:	611c                	ld	a5,0(a0)
    80001656:	9bbd                	andi	a5,a5,-17
    80001658:	e11c                	sd	a5,0(a0)
}
    8000165a:	60a2                	ld	ra,8(sp)
    8000165c:	6402                	ld	s0,0(sp)
    8000165e:	0141                	addi	sp,sp,16
    80001660:	8082                	ret
    panic("uvmclear");
    80001662:	00007517          	auipc	a0,0x7
    80001666:	b6650513          	addi	a0,a0,-1178 # 800081c8 <digits+0x188>
    8000166a:	fffff097          	auipc	ra,0xfffff
    8000166e:	ed4080e7          	jalr	-300(ra) # 8000053e <panic>

0000000080001672 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001672:	c6bd                	beqz	a3,800016e0 <copyout+0x6e>
{
    80001674:	715d                	addi	sp,sp,-80
    80001676:	e486                	sd	ra,72(sp)
    80001678:	e0a2                	sd	s0,64(sp)
    8000167a:	fc26                	sd	s1,56(sp)
    8000167c:	f84a                	sd	s2,48(sp)
    8000167e:	f44e                	sd	s3,40(sp)
    80001680:	f052                	sd	s4,32(sp)
    80001682:	ec56                	sd	s5,24(sp)
    80001684:	e85a                	sd	s6,16(sp)
    80001686:	e45e                	sd	s7,8(sp)
    80001688:	e062                	sd	s8,0(sp)
    8000168a:	0880                	addi	s0,sp,80
    8000168c:	8b2a                	mv	s6,a0
    8000168e:	8c2e                	mv	s8,a1
    80001690:	8a32                	mv	s4,a2
    80001692:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    80001694:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    80001696:	6a85                	lui	s5,0x1
    80001698:	a015                	j	800016bc <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    8000169a:	9562                	add	a0,a0,s8
    8000169c:	0004861b          	sext.w	a2,s1
    800016a0:	85d2                	mv	a1,s4
    800016a2:	41250533          	sub	a0,a0,s2
    800016a6:	fffff097          	auipc	ra,0xfffff
    800016aa:	69a080e7          	jalr	1690(ra) # 80000d40 <memmove>

    len -= n;
    800016ae:	409989b3          	sub	s3,s3,s1
    src += n;
    800016b2:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    800016b4:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800016b8:	02098263          	beqz	s3,800016dc <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800016bc:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800016c0:	85ca                	mv	a1,s2
    800016c2:	855a                	mv	a0,s6
    800016c4:	00000097          	auipc	ra,0x0
    800016c8:	9aa080e7          	jalr	-1622(ra) # 8000106e <walkaddr>
    if(pa0 == 0)
    800016cc:	cd01                	beqz	a0,800016e4 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800016ce:	418904b3          	sub	s1,s2,s8
    800016d2:	94d6                	add	s1,s1,s5
    if(n > len)
    800016d4:	fc99f3e3          	bgeu	s3,s1,8000169a <copyout+0x28>
    800016d8:	84ce                	mv	s1,s3
    800016da:	b7c1                	j	8000169a <copyout+0x28>
  }
  return 0;
    800016dc:	4501                	li	a0,0
    800016de:	a021                	j	800016e6 <copyout+0x74>
    800016e0:	4501                	li	a0,0
}
    800016e2:	8082                	ret
      return -1;
    800016e4:	557d                	li	a0,-1
}
    800016e6:	60a6                	ld	ra,72(sp)
    800016e8:	6406                	ld	s0,64(sp)
    800016ea:	74e2                	ld	s1,56(sp)
    800016ec:	7942                	ld	s2,48(sp)
    800016ee:	79a2                	ld	s3,40(sp)
    800016f0:	7a02                	ld	s4,32(sp)
    800016f2:	6ae2                	ld	s5,24(sp)
    800016f4:	6b42                	ld	s6,16(sp)
    800016f6:	6ba2                	ld	s7,8(sp)
    800016f8:	6c02                	ld	s8,0(sp)
    800016fa:	6161                	addi	sp,sp,80
    800016fc:	8082                	ret

00000000800016fe <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800016fe:	c6bd                	beqz	a3,8000176c <copyin+0x6e>
{
    80001700:	715d                	addi	sp,sp,-80
    80001702:	e486                	sd	ra,72(sp)
    80001704:	e0a2                	sd	s0,64(sp)
    80001706:	fc26                	sd	s1,56(sp)
    80001708:	f84a                	sd	s2,48(sp)
    8000170a:	f44e                	sd	s3,40(sp)
    8000170c:	f052                	sd	s4,32(sp)
    8000170e:	ec56                	sd	s5,24(sp)
    80001710:	e85a                	sd	s6,16(sp)
    80001712:	e45e                	sd	s7,8(sp)
    80001714:	e062                	sd	s8,0(sp)
    80001716:	0880                	addi	s0,sp,80
    80001718:	8b2a                	mv	s6,a0
    8000171a:	8a2e                	mv	s4,a1
    8000171c:	8c32                	mv	s8,a2
    8000171e:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001720:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001722:	6a85                	lui	s5,0x1
    80001724:	a015                	j	80001748 <copyin+0x4a>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001726:	9562                	add	a0,a0,s8
    80001728:	0004861b          	sext.w	a2,s1
    8000172c:	412505b3          	sub	a1,a0,s2
    80001730:	8552                	mv	a0,s4
    80001732:	fffff097          	auipc	ra,0xfffff
    80001736:	60e080e7          	jalr	1550(ra) # 80000d40 <memmove>

    len -= n;
    8000173a:	409989b3          	sub	s3,s3,s1
    dst += n;
    8000173e:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001740:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001744:	02098263          	beqz	s3,80001768 <copyin+0x6a>
    va0 = PGROUNDDOWN(srcva);
    80001748:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    8000174c:	85ca                	mv	a1,s2
    8000174e:	855a                	mv	a0,s6
    80001750:	00000097          	auipc	ra,0x0
    80001754:	91e080e7          	jalr	-1762(ra) # 8000106e <walkaddr>
    if(pa0 == 0)
    80001758:	cd01                	beqz	a0,80001770 <copyin+0x72>
    n = PGSIZE - (srcva - va0);
    8000175a:	418904b3          	sub	s1,s2,s8
    8000175e:	94d6                	add	s1,s1,s5
    if(n > len)
    80001760:	fc99f3e3          	bgeu	s3,s1,80001726 <copyin+0x28>
    80001764:	84ce                	mv	s1,s3
    80001766:	b7c1                	j	80001726 <copyin+0x28>
  }
  return 0;
    80001768:	4501                	li	a0,0
    8000176a:	a021                	j	80001772 <copyin+0x74>
    8000176c:	4501                	li	a0,0
}
    8000176e:	8082                	ret
      return -1;
    80001770:	557d                	li	a0,-1
}
    80001772:	60a6                	ld	ra,72(sp)
    80001774:	6406                	ld	s0,64(sp)
    80001776:	74e2                	ld	s1,56(sp)
    80001778:	7942                	ld	s2,48(sp)
    8000177a:	79a2                	ld	s3,40(sp)
    8000177c:	7a02                	ld	s4,32(sp)
    8000177e:	6ae2                	ld	s5,24(sp)
    80001780:	6b42                	ld	s6,16(sp)
    80001782:	6ba2                	ld	s7,8(sp)
    80001784:	6c02                	ld	s8,0(sp)
    80001786:	6161                	addi	sp,sp,80
    80001788:	8082                	ret

000000008000178a <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    8000178a:	c6c5                	beqz	a3,80001832 <copyinstr+0xa8>
{
    8000178c:	715d                	addi	sp,sp,-80
    8000178e:	e486                	sd	ra,72(sp)
    80001790:	e0a2                	sd	s0,64(sp)
    80001792:	fc26                	sd	s1,56(sp)
    80001794:	f84a                	sd	s2,48(sp)
    80001796:	f44e                	sd	s3,40(sp)
    80001798:	f052                	sd	s4,32(sp)
    8000179a:	ec56                	sd	s5,24(sp)
    8000179c:	e85a                	sd	s6,16(sp)
    8000179e:	e45e                	sd	s7,8(sp)
    800017a0:	0880                	addi	s0,sp,80
    800017a2:	8a2a                	mv	s4,a0
    800017a4:	8b2e                	mv	s6,a1
    800017a6:	8bb2                	mv	s7,a2
    800017a8:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800017aa:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017ac:	6985                	lui	s3,0x1
    800017ae:	a035                	j	800017da <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800017b0:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800017b4:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800017b6:	0017b793          	seqz	a5,a5
    800017ba:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800017be:	60a6                	ld	ra,72(sp)
    800017c0:	6406                	ld	s0,64(sp)
    800017c2:	74e2                	ld	s1,56(sp)
    800017c4:	7942                	ld	s2,48(sp)
    800017c6:	79a2                	ld	s3,40(sp)
    800017c8:	7a02                	ld	s4,32(sp)
    800017ca:	6ae2                	ld	s5,24(sp)
    800017cc:	6b42                	ld	s6,16(sp)
    800017ce:	6ba2                	ld	s7,8(sp)
    800017d0:	6161                	addi	sp,sp,80
    800017d2:	8082                	ret
    srcva = va0 + PGSIZE;
    800017d4:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800017d8:	c8a9                	beqz	s1,8000182a <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    800017da:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800017de:	85ca                	mv	a1,s2
    800017e0:	8552                	mv	a0,s4
    800017e2:	00000097          	auipc	ra,0x0
    800017e6:	88c080e7          	jalr	-1908(ra) # 8000106e <walkaddr>
    if(pa0 == 0)
    800017ea:	c131                	beqz	a0,8000182e <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    800017ec:	41790833          	sub	a6,s2,s7
    800017f0:	984e                	add	a6,a6,s3
    if(n > max)
    800017f2:	0104f363          	bgeu	s1,a6,800017f8 <copyinstr+0x6e>
    800017f6:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    800017f8:	955e                	add	a0,a0,s7
    800017fa:	41250533          	sub	a0,a0,s2
    while(n > 0){
    800017fe:	fc080be3          	beqz	a6,800017d4 <copyinstr+0x4a>
    80001802:	985a                	add	a6,a6,s6
    80001804:	87da                	mv	a5,s6
      if(*p == '\0'){
    80001806:	41650633          	sub	a2,a0,s6
    8000180a:	14fd                	addi	s1,s1,-1
    8000180c:	9b26                	add	s6,s6,s1
    8000180e:	00f60733          	add	a4,a2,a5
    80001812:	00074703          	lbu	a4,0(a4)
    80001816:	df49                	beqz	a4,800017b0 <copyinstr+0x26>
        *dst = *p;
    80001818:	00e78023          	sb	a4,0(a5)
      --max;
    8000181c:	40fb04b3          	sub	s1,s6,a5
      dst++;
    80001820:	0785                	addi	a5,a5,1
    while(n > 0){
    80001822:	ff0796e3          	bne	a5,a6,8000180e <copyinstr+0x84>
      dst++;
    80001826:	8b42                	mv	s6,a6
    80001828:	b775                	j	800017d4 <copyinstr+0x4a>
    8000182a:	4781                	li	a5,0
    8000182c:	b769                	j	800017b6 <copyinstr+0x2c>
      return -1;
    8000182e:	557d                	li	a0,-1
    80001830:	b779                	j	800017be <copyinstr+0x34>
  int got_null = 0;
    80001832:	4781                	li	a5,0
  if(got_null){
    80001834:	0017b793          	seqz	a5,a5
    80001838:	40f00533          	neg	a0,a5
}
    8000183c:	8082                	ret

000000008000183e <debug_uvmpte>:

int
debug_uvmpte(pagetable_t pagetable, uint64 va, uint64 size)
{
    8000183e:	7139                	addi	sp,sp,-64
    80001840:	fc06                	sd	ra,56(sp)
    80001842:	f822                	sd	s0,48(sp)
    80001844:	f426                	sd	s1,40(sp)
    80001846:	f04a                	sd	s2,32(sp)
    80001848:	ec4e                	sd	s3,24(sp)
    8000184a:	e852                	sd	s4,16(sp)
    8000184c:	e456                	sd	s5,8(sp)
    8000184e:	0080                	addi	s0,sp,64
    80001850:	89aa                	mv	s3,a0
	uint64 a, last;
	pte_t *pte;

	a = PGROUNDDOWN(va);
    80001852:	77fd                	lui	a5,0xfffff
    80001854:	00f5f4b3          	and	s1,a1,a5
	last = PGROUNDDOWN(va + size - 1);
    80001858:	fff60913          	addi	s2,a2,-1 # fff <_entry-0x7ffff001>
    8000185c:	992e                	add	s2,s2,a1
    8000185e:	00f97933          	and	s2,s2,a5
		if((pte = walk(pagetable, a, 1)) == 0) return -1;
		if(a == last){
			printf("%x\n", *pte);
			break;
		}
		a += PGSIZE;
    80001862:	6a85                	lui	s5,0x1
		printf("%x\n", *pte);
    80001864:	00007a17          	auipc	s4,0x7
    80001868:	974a0a13          	addi	s4,s4,-1676 # 800081d8 <digits+0x198>
		if((pte = walk(pagetable, a, 1)) == 0) return -1;
    8000186c:	4605                	li	a2,1
    8000186e:	85a6                	mv	a1,s1
    80001870:	854e                	mv	a0,s3
    80001872:	fffff097          	auipc	ra,0xfffff
    80001876:	756080e7          	jalr	1878(ra) # 80000fc8 <walk>
    8000187a:	c515                	beqz	a0,800018a6 <debug_uvmpte+0x68>
		if(a == last){
    8000187c:	01248a63          	beq	s1,s2,80001890 <debug_uvmpte+0x52>
		a += PGSIZE;
    80001880:	94d6                	add	s1,s1,s5
		printf("%x\n", *pte);
    80001882:	610c                	ld	a1,0(a0)
    80001884:	8552                	mv	a0,s4
    80001886:	fffff097          	auipc	ra,0xfffff
    8000188a:	d02080e7          	jalr	-766(ra) # 80000588 <printf>
		if((pte = walk(pagetable, a, 1)) == 0) return -1;
    8000188e:	bff9                	j	8000186c <debug_uvmpte+0x2e>
			printf("%x\n", *pte);
    80001890:	610c                	ld	a1,0(a0)
    80001892:	00007517          	auipc	a0,0x7
    80001896:	94650513          	addi	a0,a0,-1722 # 800081d8 <digits+0x198>
    8000189a:	fffff097          	auipc	ra,0xfffff
    8000189e:	cee080e7          	jalr	-786(ra) # 80000588 <printf>
	}
	return 0;
    800018a2:	4501                	li	a0,0
    800018a4:	a011                	j	800018a8 <debug_uvmpte+0x6a>
		if((pte = walk(pagetable, a, 1)) == 0) return -1;
    800018a6:	557d                	li	a0,-1

}
    800018a8:	70e2                	ld	ra,56(sp)
    800018aa:	7442                	ld	s0,48(sp)
    800018ac:	74a2                	ld	s1,40(sp)
    800018ae:	7902                	ld	s2,32(sp)
    800018b0:	69e2                	ld	s3,24(sp)
    800018b2:	6a42                	ld	s4,16(sp)
    800018b4:	6aa2                	ld	s5,8(sp)
    800018b6:	6121                	addi	sp,sp,64
    800018b8:	8082                	ret

00000000800018ba <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl) {
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
    800018ce:	89aa                	mv	s3,a0
	struct proc *p;

	for(p = proc; p < &proc[NPROC]; p++) {
    800018d0:	00010497          	auipc	s1,0x10
    800018d4:	e0048493          	addi	s1,s1,-512 # 800116d0 <proc>
		char *pa = kalloc();
		if(pa == 0)
			panic("kalloc");
		uint64 va = KSTACK((int) (p - proc));
    800018d8:	8b26                	mv	s6,s1
    800018da:	00006a97          	auipc	s5,0x6
    800018de:	726a8a93          	addi	s5,s5,1830 # 80008000 <etext>
    800018e2:	04000937          	lui	s2,0x4000
    800018e6:	197d                	addi	s2,s2,-1
    800018e8:	0932                	slli	s2,s2,0xc
	for(p = proc; p < &proc[NPROC]; p++) {
    800018ea:	00015a17          	auipc	s4,0x15
    800018ee:	7e6a0a13          	addi	s4,s4,2022 # 800170d0 <tickslock>
		char *pa = kalloc();
    800018f2:	fffff097          	auipc	ra,0xfffff
    800018f6:	202080e7          	jalr	514(ra) # 80000af4 <kalloc>
    800018fa:	862a                	mv	a2,a0
		if(pa == 0)
    800018fc:	c131                	beqz	a0,80001940 <proc_mapstacks+0x86>
		uint64 va = KSTACK((int) (p - proc));
    800018fe:	416485b3          	sub	a1,s1,s6
    80001902:	858d                	srai	a1,a1,0x3
    80001904:	000ab783          	ld	a5,0(s5)
    80001908:	02f585b3          	mul	a1,a1,a5
    8000190c:	2585                	addiw	a1,a1,1
    8000190e:	00d5959b          	slliw	a1,a1,0xd
		kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001912:	4719                	li	a4,6
    80001914:	6685                	lui	a3,0x1
    80001916:	40b905b3          	sub	a1,s2,a1
    8000191a:	854e                	mv	a0,s3
    8000191c:	00000097          	auipc	ra,0x0
    80001920:	834080e7          	jalr	-1996(ra) # 80001150 <kvmmap>
	for(p = proc; p < &proc[NPROC]; p++) {
    80001924:	16848493          	addi	s1,s1,360
    80001928:	fd4495e3          	bne	s1,s4,800018f2 <proc_mapstacks+0x38>
	}
}
    8000192c:	70e2                	ld	ra,56(sp)
    8000192e:	7442                	ld	s0,48(sp)
    80001930:	74a2                	ld	s1,40(sp)
    80001932:	7902                	ld	s2,32(sp)
    80001934:	69e2                	ld	s3,24(sp)
    80001936:	6a42                	ld	s4,16(sp)
    80001938:	6aa2                	ld	s5,8(sp)
    8000193a:	6b02                	ld	s6,0(sp)
    8000193c:	6121                	addi	sp,sp,64
    8000193e:	8082                	ret
			panic("kalloc");
    80001940:	00007517          	auipc	a0,0x7
    80001944:	8a050513          	addi	a0,a0,-1888 # 800081e0 <digits+0x1a0>
    80001948:	fffff097          	auipc	ra,0xfffff
    8000194c:	bf6080e7          	jalr	-1034(ra) # 8000053e <panic>

0000000080001950 <procinit>:

// initialize the proc table at boot time.
void
procinit(void)
{
    80001950:	7139                	addi	sp,sp,-64
    80001952:	fc06                	sd	ra,56(sp)
    80001954:	f822                	sd	s0,48(sp)
    80001956:	f426                	sd	s1,40(sp)
    80001958:	f04a                	sd	s2,32(sp)
    8000195a:	ec4e                	sd	s3,24(sp)
    8000195c:	e852                	sd	s4,16(sp)
    8000195e:	e456                	sd	s5,8(sp)
    80001960:	e05a                	sd	s6,0(sp)
    80001962:	0080                	addi	s0,sp,64
	struct proc *p;

	initlock(&pid_lock, "nextpid");
    80001964:	00007597          	auipc	a1,0x7
    80001968:	88458593          	addi	a1,a1,-1916 # 800081e8 <digits+0x1a8>
    8000196c:	00010517          	auipc	a0,0x10
    80001970:	93450513          	addi	a0,a0,-1740 # 800112a0 <pid_lock>
    80001974:	fffff097          	auipc	ra,0xfffff
    80001978:	1e0080e7          	jalr	480(ra) # 80000b54 <initlock>
	initlock(&wait_lock, "wait_lock");
    8000197c:	00007597          	auipc	a1,0x7
    80001980:	87458593          	addi	a1,a1,-1932 # 800081f0 <digits+0x1b0>
    80001984:	00010517          	auipc	a0,0x10
    80001988:	93450513          	addi	a0,a0,-1740 # 800112b8 <wait_lock>
    8000198c:	fffff097          	auipc	ra,0xfffff
    80001990:	1c8080e7          	jalr	456(ra) # 80000b54 <initlock>
	for(p = proc; p < &proc[NPROC]; p++) {
    80001994:	00010497          	auipc	s1,0x10
    80001998:	d3c48493          	addi	s1,s1,-708 # 800116d0 <proc>
		initlock(&p->lock, "proc");
    8000199c:	00007b17          	auipc	s6,0x7
    800019a0:	864b0b13          	addi	s6,s6,-1948 # 80008200 <digits+0x1c0>
		p->kstack = KSTACK((int) (p - proc));
    800019a4:	8aa6                	mv	s5,s1
    800019a6:	00006a17          	auipc	s4,0x6
    800019aa:	65aa0a13          	addi	s4,s4,1626 # 80008000 <etext>
    800019ae:	04000937          	lui	s2,0x4000
    800019b2:	197d                	addi	s2,s2,-1
    800019b4:	0932                	slli	s2,s2,0xc
	for(p = proc; p < &proc[NPROC]; p++) {
    800019b6:	00015997          	auipc	s3,0x15
    800019ba:	71a98993          	addi	s3,s3,1818 # 800170d0 <tickslock>
		initlock(&p->lock, "proc");
    800019be:	85da                	mv	a1,s6
    800019c0:	8526                	mv	a0,s1
    800019c2:	fffff097          	auipc	ra,0xfffff
    800019c6:	192080e7          	jalr	402(ra) # 80000b54 <initlock>
		p->kstack = KSTACK((int) (p - proc));
    800019ca:	415487b3          	sub	a5,s1,s5
    800019ce:	878d                	srai	a5,a5,0x3
    800019d0:	000a3703          	ld	a4,0(s4)
    800019d4:	02e787b3          	mul	a5,a5,a4
    800019d8:	2785                	addiw	a5,a5,1
    800019da:	00d7979b          	slliw	a5,a5,0xd
    800019de:	40f907b3          	sub	a5,s2,a5
    800019e2:	e0bc                	sd	a5,64(s1)
	for(p = proc; p < &proc[NPROC]; p++) {
    800019e4:	16848493          	addi	s1,s1,360
    800019e8:	fd349be3          	bne	s1,s3,800019be <procinit+0x6e>
	}
}
    800019ec:	70e2                	ld	ra,56(sp)
    800019ee:	7442                	ld	s0,48(sp)
    800019f0:	74a2                	ld	s1,40(sp)
    800019f2:	7902                	ld	s2,32(sp)
    800019f4:	69e2                	ld	s3,24(sp)
    800019f6:	6a42                	ld	s4,16(sp)
    800019f8:	6aa2                	ld	s5,8(sp)
    800019fa:	6b02                	ld	s6,0(sp)
    800019fc:	6121                	addi	sp,sp,64
    800019fe:	8082                	ret

0000000080001a00 <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    80001a00:	1141                	addi	sp,sp,-16
    80001a02:	e422                	sd	s0,8(sp)
    80001a04:	0800                	addi	s0,sp,16
	asm volatile("mv %0, tp" : "=r" (x) );
    80001a06:	8512                	mv	a0,tp
	int id = r_tp();
	return id;
}
    80001a08:	2501                	sext.w	a0,a0
    80001a0a:	6422                	ld	s0,8(sp)
    80001a0c:	0141                	addi	sp,sp,16
    80001a0e:	8082                	ret

0000000080001a10 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void) {
    80001a10:	1141                	addi	sp,sp,-16
    80001a12:	e422                	sd	s0,8(sp)
    80001a14:	0800                	addi	s0,sp,16
    80001a16:	8792                	mv	a5,tp
	int id = cpuid();
	struct cpu *c = &cpus[id];
    80001a18:	2781                	sext.w	a5,a5
    80001a1a:	079e                	slli	a5,a5,0x7
	return c;
}
    80001a1c:	00010517          	auipc	a0,0x10
    80001a20:	8b450513          	addi	a0,a0,-1868 # 800112d0 <cpus>
    80001a24:	953e                	add	a0,a0,a5
    80001a26:	6422                	ld	s0,8(sp)
    80001a28:	0141                	addi	sp,sp,16
    80001a2a:	8082                	ret

0000000080001a2c <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void) {
    80001a2c:	1101                	addi	sp,sp,-32
    80001a2e:	ec06                	sd	ra,24(sp)
    80001a30:	e822                	sd	s0,16(sp)
    80001a32:	e426                	sd	s1,8(sp)
    80001a34:	1000                	addi	s0,sp,32
	push_off();
    80001a36:	fffff097          	auipc	ra,0xfffff
    80001a3a:	162080e7          	jalr	354(ra) # 80000b98 <push_off>
    80001a3e:	8792                	mv	a5,tp
	struct cpu *c = mycpu();
	struct proc *p = c->proc;
    80001a40:	2781                	sext.w	a5,a5
    80001a42:	079e                	slli	a5,a5,0x7
    80001a44:	00010717          	auipc	a4,0x10
    80001a48:	85c70713          	addi	a4,a4,-1956 # 800112a0 <pid_lock>
    80001a4c:	97ba                	add	a5,a5,a4
    80001a4e:	7b84                	ld	s1,48(a5)
	pop_off();
    80001a50:	fffff097          	auipc	ra,0xfffff
    80001a54:	1e8080e7          	jalr	488(ra) # 80000c38 <pop_off>
	return p;
}
    80001a58:	8526                	mv	a0,s1
    80001a5a:	60e2                	ld	ra,24(sp)
    80001a5c:	6442                	ld	s0,16(sp)
    80001a5e:	64a2                	ld	s1,8(sp)
    80001a60:	6105                	addi	sp,sp,32
    80001a62:	8082                	ret

0000000080001a64 <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    80001a64:	1141                	addi	sp,sp,-16
    80001a66:	e406                	sd	ra,8(sp)
    80001a68:	e022                	sd	s0,0(sp)
    80001a6a:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001a6c:	00000097          	auipc	ra,0x0
    80001a70:	fc0080e7          	jalr	-64(ra) # 80001a2c <myproc>
    80001a74:	fffff097          	auipc	ra,0xfffff
    80001a78:	224080e7          	jalr	548(ra) # 80000c98 <release>

  if (first) {
    80001a7c:	00007797          	auipc	a5,0x7
    80001a80:	da47a783          	lw	a5,-604(a5) # 80008820 <first.1676>
    80001a84:	eb89                	bnez	a5,80001a96 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001a86:	00001097          	auipc	ra,0x1
    80001a8a:	c0a080e7          	jalr	-1014(ra) # 80002690 <usertrapret>
}
    80001a8e:	60a2                	ld	ra,8(sp)
    80001a90:	6402                	ld	s0,0(sp)
    80001a92:	0141                	addi	sp,sp,16
    80001a94:	8082                	ret
    first = 0;
    80001a96:	00007797          	auipc	a5,0x7
    80001a9a:	d807a523          	sw	zero,-630(a5) # 80008820 <first.1676>
    fsinit(ROOTDEV);
    80001a9e:	4505                	li	a0,1
    80001aa0:	00002097          	auipc	ra,0x2
    80001aa4:	932080e7          	jalr	-1742(ra) # 800033d2 <fsinit>
    80001aa8:	bff9                	j	80001a86 <forkret+0x22>

0000000080001aaa <allocpid>:
allocpid() {
    80001aaa:	1101                	addi	sp,sp,-32
    80001aac:	ec06                	sd	ra,24(sp)
    80001aae:	e822                	sd	s0,16(sp)
    80001ab0:	e426                	sd	s1,8(sp)
    80001ab2:	e04a                	sd	s2,0(sp)
    80001ab4:	1000                	addi	s0,sp,32
	acquire(&pid_lock);
    80001ab6:	0000f917          	auipc	s2,0xf
    80001aba:	7ea90913          	addi	s2,s2,2026 # 800112a0 <pid_lock>
    80001abe:	854a                	mv	a0,s2
    80001ac0:	fffff097          	auipc	ra,0xfffff
    80001ac4:	124080e7          	jalr	292(ra) # 80000be4 <acquire>
	pid = nextpid;
    80001ac8:	00007797          	auipc	a5,0x7
    80001acc:	d5c78793          	addi	a5,a5,-676 # 80008824 <nextpid>
    80001ad0:	4384                	lw	s1,0(a5)
	nextpid = nextpid + 1;
    80001ad2:	0014871b          	addiw	a4,s1,1
    80001ad6:	c398                	sw	a4,0(a5)
	release(&pid_lock);
    80001ad8:	854a                	mv	a0,s2
    80001ada:	fffff097          	auipc	ra,0xfffff
    80001ade:	1be080e7          	jalr	446(ra) # 80000c98 <release>
}
    80001ae2:	8526                	mv	a0,s1
    80001ae4:	60e2                	ld	ra,24(sp)
    80001ae6:	6442                	ld	s0,16(sp)
    80001ae8:	64a2                	ld	s1,8(sp)
    80001aea:	6902                	ld	s2,0(sp)
    80001aec:	6105                	addi	sp,sp,32
    80001aee:	8082                	ret

0000000080001af0 <proc_pagetable>:
{
    80001af0:	1101                	addi	sp,sp,-32
    80001af2:	ec06                	sd	ra,24(sp)
    80001af4:	e822                	sd	s0,16(sp)
    80001af6:	e426                	sd	s1,8(sp)
    80001af8:	e04a                	sd	s2,0(sp)
    80001afa:	1000                	addi	s0,sp,32
    80001afc:	892a                	mv	s2,a0
	pagetable = uvmcreate();
    80001afe:	00000097          	auipc	ra,0x0
    80001b02:	83c080e7          	jalr	-1988(ra) # 8000133a <uvmcreate>
    80001b06:	84aa                	mv	s1,a0
	if(pagetable == 0)
    80001b08:	c121                	beqz	a0,80001b48 <proc_pagetable+0x58>
	if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001b0a:	4729                	li	a4,10
    80001b0c:	00005697          	auipc	a3,0x5
    80001b10:	4f468693          	addi	a3,a3,1268 # 80007000 <_trampoline>
    80001b14:	6605                	lui	a2,0x1
    80001b16:	040005b7          	lui	a1,0x4000
    80001b1a:	15fd                	addi	a1,a1,-1
    80001b1c:	05b2                	slli	a1,a1,0xc
    80001b1e:	fffff097          	auipc	ra,0xfffff
    80001b22:	592080e7          	jalr	1426(ra) # 800010b0 <mappages>
    80001b26:	02054863          	bltz	a0,80001b56 <proc_pagetable+0x66>
	if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001b2a:	4719                	li	a4,6
    80001b2c:	05893683          	ld	a3,88(s2)
    80001b30:	6605                	lui	a2,0x1
    80001b32:	020005b7          	lui	a1,0x2000
    80001b36:	15fd                	addi	a1,a1,-1
    80001b38:	05b6                	slli	a1,a1,0xd
    80001b3a:	8526                	mv	a0,s1
    80001b3c:	fffff097          	auipc	ra,0xfffff
    80001b40:	574080e7          	jalr	1396(ra) # 800010b0 <mappages>
    80001b44:	02054163          	bltz	a0,80001b66 <proc_pagetable+0x76>
}
    80001b48:	8526                	mv	a0,s1
    80001b4a:	60e2                	ld	ra,24(sp)
    80001b4c:	6442                	ld	s0,16(sp)
    80001b4e:	64a2                	ld	s1,8(sp)
    80001b50:	6902                	ld	s2,0(sp)
    80001b52:	6105                	addi	sp,sp,32
    80001b54:	8082                	ret
		uvmfree(pagetable, 0);
    80001b56:	4581                	li	a1,0
    80001b58:	8526                	mv	a0,s1
    80001b5a:	00000097          	auipc	ra,0x0
    80001b5e:	9dc080e7          	jalr	-1572(ra) # 80001536 <uvmfree>
		return 0;
    80001b62:	4481                	li	s1,0
    80001b64:	b7d5                	j	80001b48 <proc_pagetable+0x58>
		uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b66:	4681                	li	a3,0
    80001b68:	4605                	li	a2,1
    80001b6a:	040005b7          	lui	a1,0x4000
    80001b6e:	15fd                	addi	a1,a1,-1
    80001b70:	05b2                	slli	a1,a1,0xc
    80001b72:	8526                	mv	a0,s1
    80001b74:	fffff097          	auipc	ra,0xfffff
    80001b78:	702080e7          	jalr	1794(ra) # 80001276 <uvmunmap>
		uvmfree(pagetable, 0);
    80001b7c:	4581                	li	a1,0
    80001b7e:	8526                	mv	a0,s1
    80001b80:	00000097          	auipc	ra,0x0
    80001b84:	9b6080e7          	jalr	-1610(ra) # 80001536 <uvmfree>
		return 0;
    80001b88:	4481                	li	s1,0
    80001b8a:	bf7d                	j	80001b48 <proc_pagetable+0x58>

0000000080001b8c <proc_freepagetable>:
{
    80001b8c:	1101                	addi	sp,sp,-32
    80001b8e:	ec06                	sd	ra,24(sp)
    80001b90:	e822                	sd	s0,16(sp)
    80001b92:	e426                	sd	s1,8(sp)
    80001b94:	e04a                	sd	s2,0(sp)
    80001b96:	1000                	addi	s0,sp,32
    80001b98:	84aa                	mv	s1,a0
    80001b9a:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b9c:	4681                	li	a3,0
    80001b9e:	4605                	li	a2,1
    80001ba0:	040005b7          	lui	a1,0x4000
    80001ba4:	15fd                	addi	a1,a1,-1
    80001ba6:	05b2                	slli	a1,a1,0xc
    80001ba8:	fffff097          	auipc	ra,0xfffff
    80001bac:	6ce080e7          	jalr	1742(ra) # 80001276 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001bb0:	4681                	li	a3,0
    80001bb2:	4605                	li	a2,1
    80001bb4:	020005b7          	lui	a1,0x2000
    80001bb8:	15fd                	addi	a1,a1,-1
    80001bba:	05b6                	slli	a1,a1,0xd
    80001bbc:	8526                	mv	a0,s1
    80001bbe:	fffff097          	auipc	ra,0xfffff
    80001bc2:	6b8080e7          	jalr	1720(ra) # 80001276 <uvmunmap>
  uvmfree(pagetable, sz);
    80001bc6:	85ca                	mv	a1,s2
    80001bc8:	8526                	mv	a0,s1
    80001bca:	00000097          	auipc	ra,0x0
    80001bce:	96c080e7          	jalr	-1684(ra) # 80001536 <uvmfree>
}
    80001bd2:	60e2                	ld	ra,24(sp)
    80001bd4:	6442                	ld	s0,16(sp)
    80001bd6:	64a2                	ld	s1,8(sp)
    80001bd8:	6902                	ld	s2,0(sp)
    80001bda:	6105                	addi	sp,sp,32
    80001bdc:	8082                	ret

0000000080001bde <freeproc>:
{
    80001bde:	1101                	addi	sp,sp,-32
    80001be0:	ec06                	sd	ra,24(sp)
    80001be2:	e822                	sd	s0,16(sp)
    80001be4:	e426                	sd	s1,8(sp)
    80001be6:	1000                	addi	s0,sp,32
    80001be8:	84aa                	mv	s1,a0
	if(p->trapframe)
    80001bea:	6d28                	ld	a0,88(a0)
    80001bec:	c509                	beqz	a0,80001bf6 <freeproc+0x18>
		kfree((void*)p->trapframe);
    80001bee:	fffff097          	auipc	ra,0xfffff
    80001bf2:	e0a080e7          	jalr	-502(ra) # 800009f8 <kfree>
	p->trapframe = 0;
    80001bf6:	0404bc23          	sd	zero,88(s1)
	if(p->pagetable)
    80001bfa:	68a8                	ld	a0,80(s1)
    80001bfc:	c511                	beqz	a0,80001c08 <freeproc+0x2a>
		proc_freepagetable(p->pagetable, p->sz);
    80001bfe:	64ac                	ld	a1,72(s1)
    80001c00:	00000097          	auipc	ra,0x0
    80001c04:	f8c080e7          	jalr	-116(ra) # 80001b8c <proc_freepagetable>
	p->pagetable = 0;
    80001c08:	0404b823          	sd	zero,80(s1)
	p->sz = 0;
    80001c0c:	0404b423          	sd	zero,72(s1)
	p->pid = 0;
    80001c10:	0204a823          	sw	zero,48(s1)
	p->parent = 0;
    80001c14:	0204bc23          	sd	zero,56(s1)
	p->name[0] = 0;
    80001c18:	14048c23          	sb	zero,344(s1)
	p->chan = 0;
    80001c1c:	0204b023          	sd	zero,32(s1)
	p->killed = 0;
    80001c20:	0204a423          	sw	zero,40(s1)
	p->xstate = 0;
    80001c24:	0204a623          	sw	zero,44(s1)
	p->state = UNUSED;
    80001c28:	0004ac23          	sw	zero,24(s1)
}
    80001c2c:	60e2                	ld	ra,24(sp)
    80001c2e:	6442                	ld	s0,16(sp)
    80001c30:	64a2                	ld	s1,8(sp)
    80001c32:	6105                	addi	sp,sp,32
    80001c34:	8082                	ret

0000000080001c36 <allocproc>:
{
    80001c36:	1101                	addi	sp,sp,-32
    80001c38:	ec06                	sd	ra,24(sp)
    80001c3a:	e822                	sd	s0,16(sp)
    80001c3c:	e426                	sd	s1,8(sp)
    80001c3e:	e04a                	sd	s2,0(sp)
    80001c40:	1000                	addi	s0,sp,32
	for(p = proc; p < &proc[NPROC]; p++) {
    80001c42:	00010497          	auipc	s1,0x10
    80001c46:	a8e48493          	addi	s1,s1,-1394 # 800116d0 <proc>
    80001c4a:	00015917          	auipc	s2,0x15
    80001c4e:	48690913          	addi	s2,s2,1158 # 800170d0 <tickslock>
		acquire(&p->lock);
    80001c52:	8526                	mv	a0,s1
    80001c54:	fffff097          	auipc	ra,0xfffff
    80001c58:	f90080e7          	jalr	-112(ra) # 80000be4 <acquire>
		if(p->state == UNUSED) {
    80001c5c:	4c9c                	lw	a5,24(s1)
    80001c5e:	cf81                	beqz	a5,80001c76 <allocproc+0x40>
			release(&p->lock);
    80001c60:	8526                	mv	a0,s1
    80001c62:	fffff097          	auipc	ra,0xfffff
    80001c66:	036080e7          	jalr	54(ra) # 80000c98 <release>
	for(p = proc; p < &proc[NPROC]; p++) {
    80001c6a:	16848493          	addi	s1,s1,360
    80001c6e:	ff2492e3          	bne	s1,s2,80001c52 <allocproc+0x1c>
	return 0;
    80001c72:	4481                	li	s1,0
    80001c74:	a889                	j	80001cc6 <allocproc+0x90>
	p->pid = allocpid();
    80001c76:	00000097          	auipc	ra,0x0
    80001c7a:	e34080e7          	jalr	-460(ra) # 80001aaa <allocpid>
    80001c7e:	d888                	sw	a0,48(s1)
	p->state = USED;
    80001c80:	4785                	li	a5,1
    80001c82:	cc9c                	sw	a5,24(s1)
	if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001c84:	fffff097          	auipc	ra,0xfffff
    80001c88:	e70080e7          	jalr	-400(ra) # 80000af4 <kalloc>
    80001c8c:	892a                	mv	s2,a0
    80001c8e:	eca8                	sd	a0,88(s1)
    80001c90:	c131                	beqz	a0,80001cd4 <allocproc+0x9e>
	p->pagetable = proc_pagetable(p);
    80001c92:	8526                	mv	a0,s1
    80001c94:	00000097          	auipc	ra,0x0
    80001c98:	e5c080e7          	jalr	-420(ra) # 80001af0 <proc_pagetable>
    80001c9c:	892a                	mv	s2,a0
    80001c9e:	e8a8                	sd	a0,80(s1)
	if(p->pagetable == 0){
    80001ca0:	c531                	beqz	a0,80001cec <allocproc+0xb6>
	memset(&p->context, 0, sizeof(p->context));
    80001ca2:	07000613          	li	a2,112
    80001ca6:	4581                	li	a1,0
    80001ca8:	06048513          	addi	a0,s1,96
    80001cac:	fffff097          	auipc	ra,0xfffff
    80001cb0:	034080e7          	jalr	52(ra) # 80000ce0 <memset>
	p->context.ra = (uint64)forkret;
    80001cb4:	00000797          	auipc	a5,0x0
    80001cb8:	db078793          	addi	a5,a5,-592 # 80001a64 <forkret>
    80001cbc:	f0bc                	sd	a5,96(s1)
	p->context.sp = p->kstack + PGSIZE;
    80001cbe:	60bc                	ld	a5,64(s1)
    80001cc0:	6705                	lui	a4,0x1
    80001cc2:	97ba                	add	a5,a5,a4
    80001cc4:	f4bc                	sd	a5,104(s1)
}
    80001cc6:	8526                	mv	a0,s1
    80001cc8:	60e2                	ld	ra,24(sp)
    80001cca:	6442                	ld	s0,16(sp)
    80001ccc:	64a2                	ld	s1,8(sp)
    80001cce:	6902                	ld	s2,0(sp)
    80001cd0:	6105                	addi	sp,sp,32
    80001cd2:	8082                	ret
		freeproc(p);
    80001cd4:	8526                	mv	a0,s1
    80001cd6:	00000097          	auipc	ra,0x0
    80001cda:	f08080e7          	jalr	-248(ra) # 80001bde <freeproc>
		release(&p->lock);
    80001cde:	8526                	mv	a0,s1
    80001ce0:	fffff097          	auipc	ra,0xfffff
    80001ce4:	fb8080e7          	jalr	-72(ra) # 80000c98 <release>
		return 0;
    80001ce8:	84ca                	mv	s1,s2
    80001cea:	bff1                	j	80001cc6 <allocproc+0x90>
		freeproc(p);
    80001cec:	8526                	mv	a0,s1
    80001cee:	00000097          	auipc	ra,0x0
    80001cf2:	ef0080e7          	jalr	-272(ra) # 80001bde <freeproc>
		release(&p->lock);
    80001cf6:	8526                	mv	a0,s1
    80001cf8:	fffff097          	auipc	ra,0xfffff
    80001cfc:	fa0080e7          	jalr	-96(ra) # 80000c98 <release>
		return 0;
    80001d00:	84ca                	mv	s1,s2
    80001d02:	b7d1                	j	80001cc6 <allocproc+0x90>

0000000080001d04 <userinit>:
{
    80001d04:	1101                	addi	sp,sp,-32
    80001d06:	ec06                	sd	ra,24(sp)
    80001d08:	e822                	sd	s0,16(sp)
    80001d0a:	e426                	sd	s1,8(sp)
    80001d0c:	1000                	addi	s0,sp,32
	p = allocproc();
    80001d0e:	00000097          	auipc	ra,0x0
    80001d12:	f28080e7          	jalr	-216(ra) # 80001c36 <allocproc>
    80001d16:	84aa                	mv	s1,a0
	initproc = p;
    80001d18:	00007797          	auipc	a5,0x7
    80001d1c:	30a7b823          	sd	a0,784(a5) # 80009028 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001d20:	03400613          	li	a2,52
    80001d24:	00007597          	auipc	a1,0x7
    80001d28:	b0c58593          	addi	a1,a1,-1268 # 80008830 <initcode>
    80001d2c:	6928                	ld	a0,80(a0)
    80001d2e:	fffff097          	auipc	ra,0xfffff
    80001d32:	63a080e7          	jalr	1594(ra) # 80001368 <uvminit>
	p->sz = PGSIZE;
    80001d36:	6785                	lui	a5,0x1
    80001d38:	e4bc                	sd	a5,72(s1)
	p->trapframe->epc = 0;      // user program counter
    80001d3a:	6cb8                	ld	a4,88(s1)
    80001d3c:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
	p->trapframe->sp = PGSIZE;  // user stack pointer
    80001d40:	6cb8                	ld	a4,88(s1)
    80001d42:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001d44:	4641                	li	a2,16
    80001d46:	00006597          	auipc	a1,0x6
    80001d4a:	4c258593          	addi	a1,a1,1218 # 80008208 <digits+0x1c8>
    80001d4e:	15848513          	addi	a0,s1,344
    80001d52:	fffff097          	auipc	ra,0xfffff
    80001d56:	0e0080e7          	jalr	224(ra) # 80000e32 <safestrcpy>
	p->cwd = namei("/");
    80001d5a:	00006517          	auipc	a0,0x6
    80001d5e:	4be50513          	addi	a0,a0,1214 # 80008218 <digits+0x1d8>
    80001d62:	00002097          	auipc	ra,0x2
    80001d66:	09e080e7          	jalr	158(ra) # 80003e00 <namei>
    80001d6a:	14a4b823          	sd	a0,336(s1)
	p->state = RUNNABLE;
    80001d6e:	478d                	li	a5,3
    80001d70:	cc9c                	sw	a5,24(s1)
	release(&p->lock);
    80001d72:	8526                	mv	a0,s1
    80001d74:	fffff097          	auipc	ra,0xfffff
    80001d78:	f24080e7          	jalr	-220(ra) # 80000c98 <release>
}
    80001d7c:	60e2                	ld	ra,24(sp)
    80001d7e:	6442                	ld	s0,16(sp)
    80001d80:	64a2                	ld	s1,8(sp)
    80001d82:	6105                	addi	sp,sp,32
    80001d84:	8082                	ret

0000000080001d86 <growproc>:
{
    80001d86:	1101                	addi	sp,sp,-32
    80001d88:	ec06                	sd	ra,24(sp)
    80001d8a:	e822                	sd	s0,16(sp)
    80001d8c:	e426                	sd	s1,8(sp)
    80001d8e:	e04a                	sd	s2,0(sp)
    80001d90:	1000                	addi	s0,sp,32
    80001d92:	84aa                	mv	s1,a0
	struct proc *p = myproc();
    80001d94:	00000097          	auipc	ra,0x0
    80001d98:	c98080e7          	jalr	-872(ra) # 80001a2c <myproc>
    80001d9c:	892a                	mv	s2,a0
	sz = p->sz;
    80001d9e:	652c                	ld	a1,72(a0)
    80001da0:	0005861b          	sext.w	a2,a1
	if(n > 0){
    80001da4:	00904f63          	bgtz	s1,80001dc2 <growproc+0x3c>
	} else if(n < 0){
    80001da8:	0204cc63          	bltz	s1,80001de0 <growproc+0x5a>
	p->sz = sz;
    80001dac:	1602                	slli	a2,a2,0x20
    80001dae:	9201                	srli	a2,a2,0x20
    80001db0:	04c93423          	sd	a2,72(s2)
	return 0;
    80001db4:	4501                	li	a0,0
}
    80001db6:	60e2                	ld	ra,24(sp)
    80001db8:	6442                	ld	s0,16(sp)
    80001dba:	64a2                	ld	s1,8(sp)
    80001dbc:	6902                	ld	s2,0(sp)
    80001dbe:	6105                	addi	sp,sp,32
    80001dc0:	8082                	ret
		if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001dc2:	9e25                	addw	a2,a2,s1
    80001dc4:	1602                	slli	a2,a2,0x20
    80001dc6:	9201                	srli	a2,a2,0x20
    80001dc8:	1582                	slli	a1,a1,0x20
    80001dca:	9181                	srli	a1,a1,0x20
    80001dcc:	6928                	ld	a0,80(a0)
    80001dce:	fffff097          	auipc	ra,0xfffff
    80001dd2:	654080e7          	jalr	1620(ra) # 80001422 <uvmalloc>
    80001dd6:	0005061b          	sext.w	a2,a0
    80001dda:	fa69                	bnez	a2,80001dac <growproc+0x26>
			return -1;
    80001ddc:	557d                	li	a0,-1
    80001dde:	bfe1                	j	80001db6 <growproc+0x30>
		sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001de0:	9e25                	addw	a2,a2,s1
    80001de2:	1602                	slli	a2,a2,0x20
    80001de4:	9201                	srli	a2,a2,0x20
    80001de6:	1582                	slli	a1,a1,0x20
    80001de8:	9181                	srli	a1,a1,0x20
    80001dea:	6928                	ld	a0,80(a0)
    80001dec:	fffff097          	auipc	ra,0xfffff
    80001df0:	5ee080e7          	jalr	1518(ra) # 800013da <uvmdealloc>
    80001df4:	0005061b          	sext.w	a2,a0
    80001df8:	bf55                	j	80001dac <growproc+0x26>

0000000080001dfa <fork>:
{
    80001dfa:	7179                	addi	sp,sp,-48
    80001dfc:	f406                	sd	ra,40(sp)
    80001dfe:	f022                	sd	s0,32(sp)
    80001e00:	ec26                	sd	s1,24(sp)
    80001e02:	e84a                	sd	s2,16(sp)
    80001e04:	e44e                	sd	s3,8(sp)
    80001e06:	e052                	sd	s4,0(sp)
    80001e08:	1800                	addi	s0,sp,48
	struct proc *p = myproc();
    80001e0a:	00000097          	auipc	ra,0x0
    80001e0e:	c22080e7          	jalr	-990(ra) # 80001a2c <myproc>
    80001e12:	892a                	mv	s2,a0
	if((np = allocproc()) == 0){
    80001e14:	00000097          	auipc	ra,0x0
    80001e18:	e22080e7          	jalr	-478(ra) # 80001c36 <allocproc>
    80001e1c:	10050b63          	beqz	a0,80001f32 <fork+0x138>
    80001e20:	89aa                	mv	s3,a0
	if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001e22:	04893603          	ld	a2,72(s2)
    80001e26:	692c                	ld	a1,80(a0)
    80001e28:	05093503          	ld	a0,80(s2)
    80001e2c:	fffff097          	auipc	ra,0xfffff
    80001e30:	742080e7          	jalr	1858(ra) # 8000156e <uvmcopy>
    80001e34:	04054663          	bltz	a0,80001e80 <fork+0x86>
	np->sz = p->sz;
    80001e38:	04893783          	ld	a5,72(s2)
    80001e3c:	04f9b423          	sd	a5,72(s3)
	*(np->trapframe) = *(p->trapframe);
    80001e40:	05893683          	ld	a3,88(s2)
    80001e44:	87b6                	mv	a5,a3
    80001e46:	0589b703          	ld	a4,88(s3)
    80001e4a:	12068693          	addi	a3,a3,288
    80001e4e:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001e52:	6788                	ld	a0,8(a5)
    80001e54:	6b8c                	ld	a1,16(a5)
    80001e56:	6f90                	ld	a2,24(a5)
    80001e58:	01073023          	sd	a6,0(a4)
    80001e5c:	e708                	sd	a0,8(a4)
    80001e5e:	eb0c                	sd	a1,16(a4)
    80001e60:	ef10                	sd	a2,24(a4)
    80001e62:	02078793          	addi	a5,a5,32
    80001e66:	02070713          	addi	a4,a4,32
    80001e6a:	fed792e3          	bne	a5,a3,80001e4e <fork+0x54>
	np->trapframe->a0 = 0;
    80001e6e:	0589b783          	ld	a5,88(s3)
    80001e72:	0607b823          	sd	zero,112(a5)
    80001e76:	0d000493          	li	s1,208
	for(i = 0; i < NOFILE; i++)
    80001e7a:	15000a13          	li	s4,336
    80001e7e:	a03d                	j	80001eac <fork+0xb2>
		freeproc(np);
    80001e80:	854e                	mv	a0,s3
    80001e82:	00000097          	auipc	ra,0x0
    80001e86:	d5c080e7          	jalr	-676(ra) # 80001bde <freeproc>
		release(&np->lock);
    80001e8a:	854e                	mv	a0,s3
    80001e8c:	fffff097          	auipc	ra,0xfffff
    80001e90:	e0c080e7          	jalr	-500(ra) # 80000c98 <release>
		return -1;
    80001e94:	5a7d                	li	s4,-1
    80001e96:	a069                	j	80001f20 <fork+0x126>
			np->ofile[i] = filedup(p->ofile[i]);
    80001e98:	00002097          	auipc	ra,0x2
    80001e9c:	5fe080e7          	jalr	1534(ra) # 80004496 <filedup>
    80001ea0:	009987b3          	add	a5,s3,s1
    80001ea4:	e388                	sd	a0,0(a5)
	for(i = 0; i < NOFILE; i++)
    80001ea6:	04a1                	addi	s1,s1,8
    80001ea8:	01448763          	beq	s1,s4,80001eb6 <fork+0xbc>
		if(p->ofile[i])
    80001eac:	009907b3          	add	a5,s2,s1
    80001eb0:	6388                	ld	a0,0(a5)
    80001eb2:	f17d                	bnez	a0,80001e98 <fork+0x9e>
    80001eb4:	bfcd                	j	80001ea6 <fork+0xac>
	np->cwd = idup(p->cwd);
    80001eb6:	15093503          	ld	a0,336(s2)
    80001eba:	00001097          	auipc	ra,0x1
    80001ebe:	752080e7          	jalr	1874(ra) # 8000360c <idup>
    80001ec2:	14a9b823          	sd	a0,336(s3)
	safestrcpy(np->name, p->name, sizeof(p->name));
    80001ec6:	4641                	li	a2,16
    80001ec8:	15890593          	addi	a1,s2,344
    80001ecc:	15898513          	addi	a0,s3,344
    80001ed0:	fffff097          	auipc	ra,0xfffff
    80001ed4:	f62080e7          	jalr	-158(ra) # 80000e32 <safestrcpy>
	pid = np->pid;
    80001ed8:	0309aa03          	lw	s4,48(s3)
	release(&np->lock);
    80001edc:	854e                	mv	a0,s3
    80001ede:	fffff097          	auipc	ra,0xfffff
    80001ee2:	dba080e7          	jalr	-582(ra) # 80000c98 <release>
	acquire(&wait_lock);
    80001ee6:	0000f497          	auipc	s1,0xf
    80001eea:	3d248493          	addi	s1,s1,978 # 800112b8 <wait_lock>
    80001eee:	8526                	mv	a0,s1
    80001ef0:	fffff097          	auipc	ra,0xfffff
    80001ef4:	cf4080e7          	jalr	-780(ra) # 80000be4 <acquire>
	np->parent = p;
    80001ef8:	0329bc23          	sd	s2,56(s3)
	release(&wait_lock);
    80001efc:	8526                	mv	a0,s1
    80001efe:	fffff097          	auipc	ra,0xfffff
    80001f02:	d9a080e7          	jalr	-614(ra) # 80000c98 <release>
	acquire(&np->lock);
    80001f06:	854e                	mv	a0,s3
    80001f08:	fffff097          	auipc	ra,0xfffff
    80001f0c:	cdc080e7          	jalr	-804(ra) # 80000be4 <acquire>
	np->state = RUNNABLE;
    80001f10:	478d                	li	a5,3
    80001f12:	00f9ac23          	sw	a5,24(s3)
	release(&np->lock);
    80001f16:	854e                	mv	a0,s3
    80001f18:	fffff097          	auipc	ra,0xfffff
    80001f1c:	d80080e7          	jalr	-640(ra) # 80000c98 <release>
}
    80001f20:	8552                	mv	a0,s4
    80001f22:	70a2                	ld	ra,40(sp)
    80001f24:	7402                	ld	s0,32(sp)
    80001f26:	64e2                	ld	s1,24(sp)
    80001f28:	6942                	ld	s2,16(sp)
    80001f2a:	69a2                	ld	s3,8(sp)
    80001f2c:	6a02                	ld	s4,0(sp)
    80001f2e:	6145                	addi	sp,sp,48
    80001f30:	8082                	ret
		return -1;
    80001f32:	5a7d                	li	s4,-1
    80001f34:	b7f5                	j	80001f20 <fork+0x126>

0000000080001f36 <scheduler>:
{
    80001f36:	7139                	addi	sp,sp,-64
    80001f38:	fc06                	sd	ra,56(sp)
    80001f3a:	f822                	sd	s0,48(sp)
    80001f3c:	f426                	sd	s1,40(sp)
    80001f3e:	f04a                	sd	s2,32(sp)
    80001f40:	ec4e                	sd	s3,24(sp)
    80001f42:	e852                	sd	s4,16(sp)
    80001f44:	e456                	sd	s5,8(sp)
    80001f46:	e05a                	sd	s6,0(sp)
    80001f48:	0080                	addi	s0,sp,64
    80001f4a:	8792                	mv	a5,tp
	int id = r_tp();
    80001f4c:	2781                	sext.w	a5,a5
	c->proc = 0;
    80001f4e:	00779a93          	slli	s5,a5,0x7
    80001f52:	0000f717          	auipc	a4,0xf
    80001f56:	34e70713          	addi	a4,a4,846 # 800112a0 <pid_lock>
    80001f5a:	9756                	add	a4,a4,s5
    80001f5c:	02073823          	sd	zero,48(a4)
				swtch(&c->context, &p->context);
    80001f60:	0000f717          	auipc	a4,0xf
    80001f64:	37870713          	addi	a4,a4,888 # 800112d8 <cpus+0x8>
    80001f68:	9aba                	add	s5,s5,a4
			if(p->state == RUNNABLE) {
    80001f6a:	498d                	li	s3,3
				p->state = RUNNING;
    80001f6c:	4b11                	li	s6,4
				c->proc = p;
    80001f6e:	079e                	slli	a5,a5,0x7
    80001f70:	0000fa17          	auipc	s4,0xf
    80001f74:	330a0a13          	addi	s4,s4,816 # 800112a0 <pid_lock>
    80001f78:	9a3e                	add	s4,s4,a5
		for(p = proc; p < &proc[NPROC]; p++) {
    80001f7a:	00015917          	auipc	s2,0x15
    80001f7e:	15690913          	addi	s2,s2,342 # 800170d0 <tickslock>
	asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f82:	100027f3          	csrr	a5,sstatus
	w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001f86:	0027e793          	ori	a5,a5,2
	asm volatile("csrw sstatus, %0" : : "r" (x));
    80001f8a:	10079073          	csrw	sstatus,a5
    80001f8e:	0000f497          	auipc	s1,0xf
    80001f92:	74248493          	addi	s1,s1,1858 # 800116d0 <proc>
    80001f96:	a03d                	j	80001fc4 <scheduler+0x8e>
				p->state = RUNNING;
    80001f98:	0164ac23          	sw	s6,24(s1)
				c->proc = p;
    80001f9c:	029a3823          	sd	s1,48(s4)
				swtch(&c->context, &p->context);
    80001fa0:	06048593          	addi	a1,s1,96
    80001fa4:	8556                	mv	a0,s5
    80001fa6:	00000097          	auipc	ra,0x0
    80001faa:	640080e7          	jalr	1600(ra) # 800025e6 <swtch>
				c->proc = 0;
    80001fae:	020a3823          	sd	zero,48(s4)
			release(&p->lock);
    80001fb2:	8526                	mv	a0,s1
    80001fb4:	fffff097          	auipc	ra,0xfffff
    80001fb8:	ce4080e7          	jalr	-796(ra) # 80000c98 <release>
		for(p = proc; p < &proc[NPROC]; p++) {
    80001fbc:	16848493          	addi	s1,s1,360
    80001fc0:	fd2481e3          	beq	s1,s2,80001f82 <scheduler+0x4c>
			acquire(&p->lock);
    80001fc4:	8526                	mv	a0,s1
    80001fc6:	fffff097          	auipc	ra,0xfffff
    80001fca:	c1e080e7          	jalr	-994(ra) # 80000be4 <acquire>
			if(p->state == RUNNABLE) {
    80001fce:	4c9c                	lw	a5,24(s1)
    80001fd0:	ff3791e3          	bne	a5,s3,80001fb2 <scheduler+0x7c>
    80001fd4:	b7d1                	j	80001f98 <scheduler+0x62>

0000000080001fd6 <sched>:
{
    80001fd6:	7179                	addi	sp,sp,-48
    80001fd8:	f406                	sd	ra,40(sp)
    80001fda:	f022                	sd	s0,32(sp)
    80001fdc:	ec26                	sd	s1,24(sp)
    80001fde:	e84a                	sd	s2,16(sp)
    80001fe0:	e44e                	sd	s3,8(sp)
    80001fe2:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001fe4:	00000097          	auipc	ra,0x0
    80001fe8:	a48080e7          	jalr	-1464(ra) # 80001a2c <myproc>
    80001fec:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001fee:	fffff097          	auipc	ra,0xfffff
    80001ff2:	b7c080e7          	jalr	-1156(ra) # 80000b6a <holding>
    80001ff6:	c93d                	beqz	a0,8000206c <sched+0x96>
	asm volatile("mv %0, tp" : "=r" (x) );
    80001ff8:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80001ffa:	2781                	sext.w	a5,a5
    80001ffc:	079e                	slli	a5,a5,0x7
    80001ffe:	0000f717          	auipc	a4,0xf
    80002002:	2a270713          	addi	a4,a4,674 # 800112a0 <pid_lock>
    80002006:	97ba                	add	a5,a5,a4
    80002008:	0a87a703          	lw	a4,168(a5)
    8000200c:	4785                	li	a5,1
    8000200e:	06f71763          	bne	a4,a5,8000207c <sched+0xa6>
  if(p->state == RUNNING)
    80002012:	4c98                	lw	a4,24(s1)
    80002014:	4791                	li	a5,4
    80002016:	06f70b63          	beq	a4,a5,8000208c <sched+0xb6>
	asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000201a:	100027f3          	csrr	a5,sstatus
	return (x & SSTATUS_SIE) != 0;
    8000201e:	8b89                	andi	a5,a5,2
  if(intr_get())
    80002020:	efb5                	bnez	a5,8000209c <sched+0xc6>
	asm volatile("mv %0, tp" : "=r" (x) );
    80002022:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80002024:	0000f917          	auipc	s2,0xf
    80002028:	27c90913          	addi	s2,s2,636 # 800112a0 <pid_lock>
    8000202c:	2781                	sext.w	a5,a5
    8000202e:	079e                	slli	a5,a5,0x7
    80002030:	97ca                	add	a5,a5,s2
    80002032:	0ac7a983          	lw	s3,172(a5)
    80002036:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80002038:	2781                	sext.w	a5,a5
    8000203a:	079e                	slli	a5,a5,0x7
    8000203c:	0000f597          	auipc	a1,0xf
    80002040:	29c58593          	addi	a1,a1,668 # 800112d8 <cpus+0x8>
    80002044:	95be                	add	a1,a1,a5
    80002046:	06048513          	addi	a0,s1,96
    8000204a:	00000097          	auipc	ra,0x0
    8000204e:	59c080e7          	jalr	1436(ra) # 800025e6 <swtch>
    80002052:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80002054:	2781                	sext.w	a5,a5
    80002056:	079e                	slli	a5,a5,0x7
    80002058:	97ca                	add	a5,a5,s2
    8000205a:	0b37a623          	sw	s3,172(a5)
}
    8000205e:	70a2                	ld	ra,40(sp)
    80002060:	7402                	ld	s0,32(sp)
    80002062:	64e2                	ld	s1,24(sp)
    80002064:	6942                	ld	s2,16(sp)
    80002066:	69a2                	ld	s3,8(sp)
    80002068:	6145                	addi	sp,sp,48
    8000206a:	8082                	ret
    panic("sched p->lock");
    8000206c:	00006517          	auipc	a0,0x6
    80002070:	1b450513          	addi	a0,a0,436 # 80008220 <digits+0x1e0>
    80002074:	ffffe097          	auipc	ra,0xffffe
    80002078:	4ca080e7          	jalr	1226(ra) # 8000053e <panic>
    panic("sched locks");
    8000207c:	00006517          	auipc	a0,0x6
    80002080:	1b450513          	addi	a0,a0,436 # 80008230 <digits+0x1f0>
    80002084:	ffffe097          	auipc	ra,0xffffe
    80002088:	4ba080e7          	jalr	1210(ra) # 8000053e <panic>
    panic("sched running");
    8000208c:	00006517          	auipc	a0,0x6
    80002090:	1b450513          	addi	a0,a0,436 # 80008240 <digits+0x200>
    80002094:	ffffe097          	auipc	ra,0xffffe
    80002098:	4aa080e7          	jalr	1194(ra) # 8000053e <panic>
    panic("sched interruptible");
    8000209c:	00006517          	auipc	a0,0x6
    800020a0:	1b450513          	addi	a0,a0,436 # 80008250 <digits+0x210>
    800020a4:	ffffe097          	auipc	ra,0xffffe
    800020a8:	49a080e7          	jalr	1178(ra) # 8000053e <panic>

00000000800020ac <yield>:
{
    800020ac:	1101                	addi	sp,sp,-32
    800020ae:	ec06                	sd	ra,24(sp)
    800020b0:	e822                	sd	s0,16(sp)
    800020b2:	e426                	sd	s1,8(sp)
    800020b4:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    800020b6:	00000097          	auipc	ra,0x0
    800020ba:	976080e7          	jalr	-1674(ra) # 80001a2c <myproc>
    800020be:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800020c0:	fffff097          	auipc	ra,0xfffff
    800020c4:	b24080e7          	jalr	-1244(ra) # 80000be4 <acquire>
  p->state = RUNNABLE;
    800020c8:	478d                	li	a5,3
    800020ca:	cc9c                	sw	a5,24(s1)
  sched();
    800020cc:	00000097          	auipc	ra,0x0
    800020d0:	f0a080e7          	jalr	-246(ra) # 80001fd6 <sched>
  release(&p->lock);
    800020d4:	8526                	mv	a0,s1
    800020d6:	fffff097          	auipc	ra,0xfffff
    800020da:	bc2080e7          	jalr	-1086(ra) # 80000c98 <release>
}
    800020de:	60e2                	ld	ra,24(sp)
    800020e0:	6442                	ld	s0,16(sp)
    800020e2:	64a2                	ld	s1,8(sp)
    800020e4:	6105                	addi	sp,sp,32
    800020e6:	8082                	ret

00000000800020e8 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    800020e8:	7179                	addi	sp,sp,-48
    800020ea:	f406                	sd	ra,40(sp)
    800020ec:	f022                	sd	s0,32(sp)
    800020ee:	ec26                	sd	s1,24(sp)
    800020f0:	e84a                	sd	s2,16(sp)
    800020f2:	e44e                	sd	s3,8(sp)
    800020f4:	1800                	addi	s0,sp,48
    800020f6:	89aa                	mv	s3,a0
    800020f8:	892e                	mv	s2,a1
	struct proc *p = myproc();
    800020fa:	00000097          	auipc	ra,0x0
    800020fe:	932080e7          	jalr	-1742(ra) # 80001a2c <myproc>
    80002102:	84aa                	mv	s1,a0
	// Once we hold p->lock, we can be
	// guaranteed that we won't miss any wakeup
	// (wakeup locks p->lock),
	// so it's okay to release lk.

	acquire(&p->lock);  //DOC: sleeplock1
    80002104:	fffff097          	auipc	ra,0xfffff
    80002108:	ae0080e7          	jalr	-1312(ra) # 80000be4 <acquire>
	release(lk);
    8000210c:	854a                	mv	a0,s2
    8000210e:	fffff097          	auipc	ra,0xfffff
    80002112:	b8a080e7          	jalr	-1142(ra) # 80000c98 <release>

	// Go to sleep.
	p->chan = chan;
    80002116:	0334b023          	sd	s3,32(s1)
	p->state = SLEEPING;
    8000211a:	4789                	li	a5,2
    8000211c:	cc9c                	sw	a5,24(s1)

	sched();
    8000211e:	00000097          	auipc	ra,0x0
    80002122:	eb8080e7          	jalr	-328(ra) # 80001fd6 <sched>

	// Tidy up.
	p->chan = 0;
    80002126:	0204b023          	sd	zero,32(s1)

	// Reacquire original lock.
	release(&p->lock);
    8000212a:	8526                	mv	a0,s1
    8000212c:	fffff097          	auipc	ra,0xfffff
    80002130:	b6c080e7          	jalr	-1172(ra) # 80000c98 <release>
	acquire(lk);
    80002134:	854a                	mv	a0,s2
    80002136:	fffff097          	auipc	ra,0xfffff
    8000213a:	aae080e7          	jalr	-1362(ra) # 80000be4 <acquire>
}
    8000213e:	70a2                	ld	ra,40(sp)
    80002140:	7402                	ld	s0,32(sp)
    80002142:	64e2                	ld	s1,24(sp)
    80002144:	6942                	ld	s2,16(sp)
    80002146:	69a2                	ld	s3,8(sp)
    80002148:	6145                	addi	sp,sp,48
    8000214a:	8082                	ret

000000008000214c <wait>:
{
    8000214c:	715d                	addi	sp,sp,-80
    8000214e:	e486                	sd	ra,72(sp)
    80002150:	e0a2                	sd	s0,64(sp)
    80002152:	fc26                	sd	s1,56(sp)
    80002154:	f84a                	sd	s2,48(sp)
    80002156:	f44e                	sd	s3,40(sp)
    80002158:	f052                	sd	s4,32(sp)
    8000215a:	ec56                	sd	s5,24(sp)
    8000215c:	e85a                	sd	s6,16(sp)
    8000215e:	e45e                	sd	s7,8(sp)
    80002160:	e062                	sd	s8,0(sp)
    80002162:	0880                	addi	s0,sp,80
    80002164:	8b2a                	mv	s6,a0
	struct proc *p = myproc();
    80002166:	00000097          	auipc	ra,0x0
    8000216a:	8c6080e7          	jalr	-1850(ra) # 80001a2c <myproc>
    8000216e:	892a                	mv	s2,a0
	acquire(&wait_lock);
    80002170:	0000f517          	auipc	a0,0xf
    80002174:	14850513          	addi	a0,a0,328 # 800112b8 <wait_lock>
    80002178:	fffff097          	auipc	ra,0xfffff
    8000217c:	a6c080e7          	jalr	-1428(ra) # 80000be4 <acquire>
		havekids = 0;
    80002180:	4b81                	li	s7,0
				if(np->state == ZOMBIE){
    80002182:	4a15                	li	s4,5
		for(np = proc; np < &proc[NPROC]; np++){
    80002184:	00015997          	auipc	s3,0x15
    80002188:	f4c98993          	addi	s3,s3,-180 # 800170d0 <tickslock>
				havekids = 1;
    8000218c:	4a85                	li	s5,1
		sleep(p, &wait_lock);  //DOC: wait-sleep
    8000218e:	0000fc17          	auipc	s8,0xf
    80002192:	12ac0c13          	addi	s8,s8,298 # 800112b8 <wait_lock>
		havekids = 0;
    80002196:	875e                	mv	a4,s7
		for(np = proc; np < &proc[NPROC]; np++){
    80002198:	0000f497          	auipc	s1,0xf
    8000219c:	53848493          	addi	s1,s1,1336 # 800116d0 <proc>
    800021a0:	a0bd                	j	8000220e <wait+0xc2>
					pid = np->pid;
    800021a2:	0304a983          	lw	s3,48(s1)
					if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    800021a6:	000b0e63          	beqz	s6,800021c2 <wait+0x76>
    800021aa:	4691                	li	a3,4
    800021ac:	02c48613          	addi	a2,s1,44
    800021b0:	85da                	mv	a1,s6
    800021b2:	05093503          	ld	a0,80(s2)
    800021b6:	fffff097          	auipc	ra,0xfffff
    800021ba:	4bc080e7          	jalr	1212(ra) # 80001672 <copyout>
    800021be:	02054563          	bltz	a0,800021e8 <wait+0x9c>
					freeproc(np);
    800021c2:	8526                	mv	a0,s1
    800021c4:	00000097          	auipc	ra,0x0
    800021c8:	a1a080e7          	jalr	-1510(ra) # 80001bde <freeproc>
					release(&np->lock);
    800021cc:	8526                	mv	a0,s1
    800021ce:	fffff097          	auipc	ra,0xfffff
    800021d2:	aca080e7          	jalr	-1334(ra) # 80000c98 <release>
					release(&wait_lock);
    800021d6:	0000f517          	auipc	a0,0xf
    800021da:	0e250513          	addi	a0,a0,226 # 800112b8 <wait_lock>
    800021de:	fffff097          	auipc	ra,0xfffff
    800021e2:	aba080e7          	jalr	-1350(ra) # 80000c98 <release>
					return pid;
    800021e6:	a09d                	j	8000224c <wait+0x100>
						release(&np->lock);
    800021e8:	8526                	mv	a0,s1
    800021ea:	fffff097          	auipc	ra,0xfffff
    800021ee:	aae080e7          	jalr	-1362(ra) # 80000c98 <release>
						release(&wait_lock);
    800021f2:	0000f517          	auipc	a0,0xf
    800021f6:	0c650513          	addi	a0,a0,198 # 800112b8 <wait_lock>
    800021fa:	fffff097          	auipc	ra,0xfffff
    800021fe:	a9e080e7          	jalr	-1378(ra) # 80000c98 <release>
						return -1;
    80002202:	59fd                	li	s3,-1
    80002204:	a0a1                	j	8000224c <wait+0x100>
		for(np = proc; np < &proc[NPROC]; np++){
    80002206:	16848493          	addi	s1,s1,360
    8000220a:	03348463          	beq	s1,s3,80002232 <wait+0xe6>
			if(np->parent == p){
    8000220e:	7c9c                	ld	a5,56(s1)
    80002210:	ff279be3          	bne	a5,s2,80002206 <wait+0xba>
				acquire(&np->lock);
    80002214:	8526                	mv	a0,s1
    80002216:	fffff097          	auipc	ra,0xfffff
    8000221a:	9ce080e7          	jalr	-1586(ra) # 80000be4 <acquire>
				if(np->state == ZOMBIE){
    8000221e:	4c9c                	lw	a5,24(s1)
    80002220:	f94781e3          	beq	a5,s4,800021a2 <wait+0x56>
				release(&np->lock);
    80002224:	8526                	mv	a0,s1
    80002226:	fffff097          	auipc	ra,0xfffff
    8000222a:	a72080e7          	jalr	-1422(ra) # 80000c98 <release>
				havekids = 1;
    8000222e:	8756                	mv	a4,s5
    80002230:	bfd9                	j	80002206 <wait+0xba>
		if(!havekids || p->killed){
    80002232:	c701                	beqz	a4,8000223a <wait+0xee>
    80002234:	02892783          	lw	a5,40(s2)
    80002238:	c79d                	beqz	a5,80002266 <wait+0x11a>
			release(&wait_lock);
    8000223a:	0000f517          	auipc	a0,0xf
    8000223e:	07e50513          	addi	a0,a0,126 # 800112b8 <wait_lock>
    80002242:	fffff097          	auipc	ra,0xfffff
    80002246:	a56080e7          	jalr	-1450(ra) # 80000c98 <release>
			return -1;
    8000224a:	59fd                	li	s3,-1
}
    8000224c:	854e                	mv	a0,s3
    8000224e:	60a6                	ld	ra,72(sp)
    80002250:	6406                	ld	s0,64(sp)
    80002252:	74e2                	ld	s1,56(sp)
    80002254:	7942                	ld	s2,48(sp)
    80002256:	79a2                	ld	s3,40(sp)
    80002258:	7a02                	ld	s4,32(sp)
    8000225a:	6ae2                	ld	s5,24(sp)
    8000225c:	6b42                	ld	s6,16(sp)
    8000225e:	6ba2                	ld	s7,8(sp)
    80002260:	6c02                	ld	s8,0(sp)
    80002262:	6161                	addi	sp,sp,80
    80002264:	8082                	ret
		sleep(p, &wait_lock);  //DOC: wait-sleep
    80002266:	85e2                	mv	a1,s8
    80002268:	854a                	mv	a0,s2
    8000226a:	00000097          	auipc	ra,0x0
    8000226e:	e7e080e7          	jalr	-386(ra) # 800020e8 <sleep>
		havekids = 0;
    80002272:	b715                	j	80002196 <wait+0x4a>

0000000080002274 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    80002274:	7139                	addi	sp,sp,-64
    80002276:	fc06                	sd	ra,56(sp)
    80002278:	f822                	sd	s0,48(sp)
    8000227a:	f426                	sd	s1,40(sp)
    8000227c:	f04a                	sd	s2,32(sp)
    8000227e:	ec4e                	sd	s3,24(sp)
    80002280:	e852                	sd	s4,16(sp)
    80002282:	e456                	sd	s5,8(sp)
    80002284:	0080                	addi	s0,sp,64
    80002286:	8a2a                	mv	s4,a0
	struct proc *p;

	for(p = proc; p < &proc[NPROC]; p++) {
    80002288:	0000f497          	auipc	s1,0xf
    8000228c:	44848493          	addi	s1,s1,1096 # 800116d0 <proc>
		if(p != myproc()){
			acquire(&p->lock);
			if(p->state == SLEEPING && p->chan == chan) {
    80002290:	4989                	li	s3,2
				p->state = RUNNABLE;
    80002292:	4a8d                	li	s5,3
	for(p = proc; p < &proc[NPROC]; p++) {
    80002294:	00015917          	auipc	s2,0x15
    80002298:	e3c90913          	addi	s2,s2,-452 # 800170d0 <tickslock>
    8000229c:	a821                	j	800022b4 <wakeup+0x40>
				p->state = RUNNABLE;
    8000229e:	0154ac23          	sw	s5,24(s1)
			}
			release(&p->lock);
    800022a2:	8526                	mv	a0,s1
    800022a4:	fffff097          	auipc	ra,0xfffff
    800022a8:	9f4080e7          	jalr	-1548(ra) # 80000c98 <release>
	for(p = proc; p < &proc[NPROC]; p++) {
    800022ac:	16848493          	addi	s1,s1,360
    800022b0:	03248463          	beq	s1,s2,800022d8 <wakeup+0x64>
		if(p != myproc()){
    800022b4:	fffff097          	auipc	ra,0xfffff
    800022b8:	778080e7          	jalr	1912(ra) # 80001a2c <myproc>
    800022bc:	fea488e3          	beq	s1,a0,800022ac <wakeup+0x38>
			acquire(&p->lock);
    800022c0:	8526                	mv	a0,s1
    800022c2:	fffff097          	auipc	ra,0xfffff
    800022c6:	922080e7          	jalr	-1758(ra) # 80000be4 <acquire>
			if(p->state == SLEEPING && p->chan == chan) {
    800022ca:	4c9c                	lw	a5,24(s1)
    800022cc:	fd379be3          	bne	a5,s3,800022a2 <wakeup+0x2e>
    800022d0:	709c                	ld	a5,32(s1)
    800022d2:	fd4798e3          	bne	a5,s4,800022a2 <wakeup+0x2e>
    800022d6:	b7e1                	j	8000229e <wakeup+0x2a>
		}
	}
}
    800022d8:	70e2                	ld	ra,56(sp)
    800022da:	7442                	ld	s0,48(sp)
    800022dc:	74a2                	ld	s1,40(sp)
    800022de:	7902                	ld	s2,32(sp)
    800022e0:	69e2                	ld	s3,24(sp)
    800022e2:	6a42                	ld	s4,16(sp)
    800022e4:	6aa2                	ld	s5,8(sp)
    800022e6:	6121                	addi	sp,sp,64
    800022e8:	8082                	ret

00000000800022ea <reparent>:
{
    800022ea:	7179                	addi	sp,sp,-48
    800022ec:	f406                	sd	ra,40(sp)
    800022ee:	f022                	sd	s0,32(sp)
    800022f0:	ec26                	sd	s1,24(sp)
    800022f2:	e84a                	sd	s2,16(sp)
    800022f4:	e44e                	sd	s3,8(sp)
    800022f6:	e052                	sd	s4,0(sp)
    800022f8:	1800                	addi	s0,sp,48
    800022fa:	892a                	mv	s2,a0
	for(pp = proc; pp < &proc[NPROC]; pp++){
    800022fc:	0000f497          	auipc	s1,0xf
    80002300:	3d448493          	addi	s1,s1,980 # 800116d0 <proc>
			pp->parent = initproc;
    80002304:	00007a17          	auipc	s4,0x7
    80002308:	d24a0a13          	addi	s4,s4,-732 # 80009028 <initproc>
	for(pp = proc; pp < &proc[NPROC]; pp++){
    8000230c:	00015997          	auipc	s3,0x15
    80002310:	dc498993          	addi	s3,s3,-572 # 800170d0 <tickslock>
    80002314:	a029                	j	8000231e <reparent+0x34>
    80002316:	16848493          	addi	s1,s1,360
    8000231a:	01348d63          	beq	s1,s3,80002334 <reparent+0x4a>
		if(pp->parent == p){
    8000231e:	7c9c                	ld	a5,56(s1)
    80002320:	ff279be3          	bne	a5,s2,80002316 <reparent+0x2c>
			pp->parent = initproc;
    80002324:	000a3503          	ld	a0,0(s4)
    80002328:	fc88                	sd	a0,56(s1)
			wakeup(initproc);
    8000232a:	00000097          	auipc	ra,0x0
    8000232e:	f4a080e7          	jalr	-182(ra) # 80002274 <wakeup>
    80002332:	b7d5                	j	80002316 <reparent+0x2c>
}
    80002334:	70a2                	ld	ra,40(sp)
    80002336:	7402                	ld	s0,32(sp)
    80002338:	64e2                	ld	s1,24(sp)
    8000233a:	6942                	ld	s2,16(sp)
    8000233c:	69a2                	ld	s3,8(sp)
    8000233e:	6a02                	ld	s4,0(sp)
    80002340:	6145                	addi	sp,sp,48
    80002342:	8082                	ret

0000000080002344 <exit>:
{
    80002344:	7179                	addi	sp,sp,-48
    80002346:	f406                	sd	ra,40(sp)
    80002348:	f022                	sd	s0,32(sp)
    8000234a:	ec26                	sd	s1,24(sp)
    8000234c:	e84a                	sd	s2,16(sp)
    8000234e:	e44e                	sd	s3,8(sp)
    80002350:	e052                	sd	s4,0(sp)
    80002352:	1800                	addi	s0,sp,48
    80002354:	8a2a                	mv	s4,a0
	struct proc *p = myproc();
    80002356:	fffff097          	auipc	ra,0xfffff
    8000235a:	6d6080e7          	jalr	1750(ra) # 80001a2c <myproc>
    8000235e:	89aa                	mv	s3,a0
	if(p == initproc)
    80002360:	00007797          	auipc	a5,0x7
    80002364:	cc87b783          	ld	a5,-824(a5) # 80009028 <initproc>
    80002368:	0d050493          	addi	s1,a0,208
    8000236c:	15050913          	addi	s2,a0,336
    80002370:	02a79363          	bne	a5,a0,80002396 <exit+0x52>
		panic("init exiting");
    80002374:	00006517          	auipc	a0,0x6
    80002378:	ef450513          	addi	a0,a0,-268 # 80008268 <digits+0x228>
    8000237c:	ffffe097          	auipc	ra,0xffffe
    80002380:	1c2080e7          	jalr	450(ra) # 8000053e <panic>
			fileclose(f);
    80002384:	00002097          	auipc	ra,0x2
    80002388:	164080e7          	jalr	356(ra) # 800044e8 <fileclose>
			p->ofile[fd] = 0;
    8000238c:	0004b023          	sd	zero,0(s1)
	for(int fd = 0; fd < NOFILE; fd++){
    80002390:	04a1                	addi	s1,s1,8
    80002392:	01248563          	beq	s1,s2,8000239c <exit+0x58>
		if(p->ofile[fd]){
    80002396:	6088                	ld	a0,0(s1)
    80002398:	f575                	bnez	a0,80002384 <exit+0x40>
    8000239a:	bfdd                	j	80002390 <exit+0x4c>
	begin_op();
    8000239c:	00002097          	auipc	ra,0x2
    800023a0:	c80080e7          	jalr	-896(ra) # 8000401c <begin_op>
	iput(p->cwd);
    800023a4:	1509b503          	ld	a0,336(s3)
    800023a8:	00001097          	auipc	ra,0x1
    800023ac:	45c080e7          	jalr	1116(ra) # 80003804 <iput>
	end_op();
    800023b0:	00002097          	auipc	ra,0x2
    800023b4:	cec080e7          	jalr	-788(ra) # 8000409c <end_op>
	p->cwd = 0;
    800023b8:	1409b823          	sd	zero,336(s3)
	acquire(&wait_lock);
    800023bc:	0000f497          	auipc	s1,0xf
    800023c0:	efc48493          	addi	s1,s1,-260 # 800112b8 <wait_lock>
    800023c4:	8526                	mv	a0,s1
    800023c6:	fffff097          	auipc	ra,0xfffff
    800023ca:	81e080e7          	jalr	-2018(ra) # 80000be4 <acquire>
	reparent(p);
    800023ce:	854e                	mv	a0,s3
    800023d0:	00000097          	auipc	ra,0x0
    800023d4:	f1a080e7          	jalr	-230(ra) # 800022ea <reparent>
	wakeup(p->parent);
    800023d8:	0389b503          	ld	a0,56(s3)
    800023dc:	00000097          	auipc	ra,0x0
    800023e0:	e98080e7          	jalr	-360(ra) # 80002274 <wakeup>
	acquire(&p->lock);
    800023e4:	854e                	mv	a0,s3
    800023e6:	ffffe097          	auipc	ra,0xffffe
    800023ea:	7fe080e7          	jalr	2046(ra) # 80000be4 <acquire>
	p->xstate = status;
    800023ee:	0349a623          	sw	s4,44(s3)
	p->state = ZOMBIE;
    800023f2:	4795                	li	a5,5
    800023f4:	00f9ac23          	sw	a5,24(s3)
	release(&wait_lock);
    800023f8:	8526                	mv	a0,s1
    800023fa:	fffff097          	auipc	ra,0xfffff
    800023fe:	89e080e7          	jalr	-1890(ra) # 80000c98 <release>
	sched();
    80002402:	00000097          	auipc	ra,0x0
    80002406:	bd4080e7          	jalr	-1068(ra) # 80001fd6 <sched>
	panic("zombie exit");
    8000240a:	00006517          	auipc	a0,0x6
    8000240e:	e6e50513          	addi	a0,a0,-402 # 80008278 <digits+0x238>
    80002412:	ffffe097          	auipc	ra,0xffffe
    80002416:	12c080e7          	jalr	300(ra) # 8000053e <panic>

000000008000241a <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    8000241a:	7179                	addi	sp,sp,-48
    8000241c:	f406                	sd	ra,40(sp)
    8000241e:	f022                	sd	s0,32(sp)
    80002420:	ec26                	sd	s1,24(sp)
    80002422:	e84a                	sd	s2,16(sp)
    80002424:	e44e                	sd	s3,8(sp)
    80002426:	1800                	addi	s0,sp,48
    80002428:	892a                	mv	s2,a0
	struct proc *p;

	for(p = proc; p < &proc[NPROC]; p++){
    8000242a:	0000f497          	auipc	s1,0xf
    8000242e:	2a648493          	addi	s1,s1,678 # 800116d0 <proc>
    80002432:	00015997          	auipc	s3,0x15
    80002436:	c9e98993          	addi	s3,s3,-866 # 800170d0 <tickslock>
		acquire(&p->lock);
    8000243a:	8526                	mv	a0,s1
    8000243c:	ffffe097          	auipc	ra,0xffffe
    80002440:	7a8080e7          	jalr	1960(ra) # 80000be4 <acquire>
		if(p->pid == pid){
    80002444:	589c                	lw	a5,48(s1)
    80002446:	01278d63          	beq	a5,s2,80002460 <kill+0x46>
				p->state = RUNNABLE;
			}
			release(&p->lock);
			return 0;
		}
		release(&p->lock);
    8000244a:	8526                	mv	a0,s1
    8000244c:	fffff097          	auipc	ra,0xfffff
    80002450:	84c080e7          	jalr	-1972(ra) # 80000c98 <release>
	for(p = proc; p < &proc[NPROC]; p++){
    80002454:	16848493          	addi	s1,s1,360
    80002458:	ff3491e3          	bne	s1,s3,8000243a <kill+0x20>
	}
	return -1;
    8000245c:	557d                	li	a0,-1
    8000245e:	a829                	j	80002478 <kill+0x5e>
			p->killed = 1;
    80002460:	4785                	li	a5,1
    80002462:	d49c                	sw	a5,40(s1)
			if(p->state == SLEEPING){
    80002464:	4c98                	lw	a4,24(s1)
    80002466:	4789                	li	a5,2
    80002468:	00f70f63          	beq	a4,a5,80002486 <kill+0x6c>
			release(&p->lock);
    8000246c:	8526                	mv	a0,s1
    8000246e:	fffff097          	auipc	ra,0xfffff
    80002472:	82a080e7          	jalr	-2006(ra) # 80000c98 <release>
			return 0;
    80002476:	4501                	li	a0,0
}
    80002478:	70a2                	ld	ra,40(sp)
    8000247a:	7402                	ld	s0,32(sp)
    8000247c:	64e2                	ld	s1,24(sp)
    8000247e:	6942                	ld	s2,16(sp)
    80002480:	69a2                	ld	s3,8(sp)
    80002482:	6145                	addi	sp,sp,48
    80002484:	8082                	ret
				p->state = RUNNABLE;
    80002486:	478d                	li	a5,3
    80002488:	cc9c                	sw	a5,24(s1)
    8000248a:	b7cd                	j	8000246c <kill+0x52>

000000008000248c <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    8000248c:	7179                	addi	sp,sp,-48
    8000248e:	f406                	sd	ra,40(sp)
    80002490:	f022                	sd	s0,32(sp)
    80002492:	ec26                	sd	s1,24(sp)
    80002494:	e84a                	sd	s2,16(sp)
    80002496:	e44e                	sd	s3,8(sp)
    80002498:	e052                	sd	s4,0(sp)
    8000249a:	1800                	addi	s0,sp,48
    8000249c:	84aa                	mv	s1,a0
    8000249e:	892e                	mv	s2,a1
    800024a0:	89b2                	mv	s3,a2
    800024a2:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800024a4:	fffff097          	auipc	ra,0xfffff
    800024a8:	588080e7          	jalr	1416(ra) # 80001a2c <myproc>
  if(user_dst){
    800024ac:	c08d                	beqz	s1,800024ce <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    800024ae:	86d2                	mv	a3,s4
    800024b0:	864e                	mv	a2,s3
    800024b2:	85ca                	mv	a1,s2
    800024b4:	6928                	ld	a0,80(a0)
    800024b6:	fffff097          	auipc	ra,0xfffff
    800024ba:	1bc080e7          	jalr	444(ra) # 80001672 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    800024be:	70a2                	ld	ra,40(sp)
    800024c0:	7402                	ld	s0,32(sp)
    800024c2:	64e2                	ld	s1,24(sp)
    800024c4:	6942                	ld	s2,16(sp)
    800024c6:	69a2                	ld	s3,8(sp)
    800024c8:	6a02                	ld	s4,0(sp)
    800024ca:	6145                	addi	sp,sp,48
    800024cc:	8082                	ret
    memmove((char *)dst, src, len);
    800024ce:	000a061b          	sext.w	a2,s4
    800024d2:	85ce                	mv	a1,s3
    800024d4:	854a                	mv	a0,s2
    800024d6:	fffff097          	auipc	ra,0xfffff
    800024da:	86a080e7          	jalr	-1942(ra) # 80000d40 <memmove>
    return 0;
    800024de:	8526                	mv	a0,s1
    800024e0:	bff9                	j	800024be <either_copyout+0x32>

00000000800024e2 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800024e2:	7179                	addi	sp,sp,-48
    800024e4:	f406                	sd	ra,40(sp)
    800024e6:	f022                	sd	s0,32(sp)
    800024e8:	ec26                	sd	s1,24(sp)
    800024ea:	e84a                	sd	s2,16(sp)
    800024ec:	e44e                	sd	s3,8(sp)
    800024ee:	e052                	sd	s4,0(sp)
    800024f0:	1800                	addi	s0,sp,48
    800024f2:	892a                	mv	s2,a0
    800024f4:	84ae                	mv	s1,a1
    800024f6:	89b2                	mv	s3,a2
    800024f8:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800024fa:	fffff097          	auipc	ra,0xfffff
    800024fe:	532080e7          	jalr	1330(ra) # 80001a2c <myproc>
  if(user_src){
    80002502:	c08d                	beqz	s1,80002524 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    80002504:	86d2                	mv	a3,s4
    80002506:	864e                	mv	a2,s3
    80002508:	85ca                	mv	a1,s2
    8000250a:	6928                	ld	a0,80(a0)
    8000250c:	fffff097          	auipc	ra,0xfffff
    80002510:	1f2080e7          	jalr	498(ra) # 800016fe <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80002514:	70a2                	ld	ra,40(sp)
    80002516:	7402                	ld	s0,32(sp)
    80002518:	64e2                	ld	s1,24(sp)
    8000251a:	6942                	ld	s2,16(sp)
    8000251c:	69a2                	ld	s3,8(sp)
    8000251e:	6a02                	ld	s4,0(sp)
    80002520:	6145                	addi	sp,sp,48
    80002522:	8082                	ret
    memmove(dst, (char*)src, len);
    80002524:	000a061b          	sext.w	a2,s4
    80002528:	85ce                	mv	a1,s3
    8000252a:	854a                	mv	a0,s2
    8000252c:	fffff097          	auipc	ra,0xfffff
    80002530:	814080e7          	jalr	-2028(ra) # 80000d40 <memmove>
    return 0;
    80002534:	8526                	mv	a0,s1
    80002536:	bff9                	j	80002514 <either_copyin+0x32>

0000000080002538 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    80002538:	715d                	addi	sp,sp,-80
    8000253a:	e486                	sd	ra,72(sp)
    8000253c:	e0a2                	sd	s0,64(sp)
    8000253e:	fc26                	sd	s1,56(sp)
    80002540:	f84a                	sd	s2,48(sp)
    80002542:	f44e                	sd	s3,40(sp)
    80002544:	f052                	sd	s4,32(sp)
    80002546:	ec56                	sd	s5,24(sp)
    80002548:	e85a                	sd	s6,16(sp)
    8000254a:	e45e                	sd	s7,8(sp)
    8000254c:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    8000254e:	00006517          	auipc	a0,0x6
    80002552:	b7a50513          	addi	a0,a0,-1158 # 800080c8 <digits+0x88>
    80002556:	ffffe097          	auipc	ra,0xffffe
    8000255a:	032080e7          	jalr	50(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    8000255e:	0000f497          	auipc	s1,0xf
    80002562:	2ca48493          	addi	s1,s1,714 # 80011828 <proc+0x158>
    80002566:	00015917          	auipc	s2,0x15
    8000256a:	cc290913          	addi	s2,s2,-830 # 80017228 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000256e:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    80002570:	00006997          	auipc	s3,0x6
    80002574:	d1898993          	addi	s3,s3,-744 # 80008288 <digits+0x248>
    printf("%d %s %s", p->pid, state, p->name);
    80002578:	00006a97          	auipc	s5,0x6
    8000257c:	d18a8a93          	addi	s5,s5,-744 # 80008290 <digits+0x250>
    printf("\n");
    80002580:	00006a17          	auipc	s4,0x6
    80002584:	b48a0a13          	addi	s4,s4,-1208 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002588:	00006b97          	auipc	s7,0x6
    8000258c:	d40b8b93          	addi	s7,s7,-704 # 800082c8 <states.1713>
    80002590:	a00d                	j	800025b2 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002592:	ed86a583          	lw	a1,-296(a3)
    80002596:	8556                	mv	a0,s5
    80002598:	ffffe097          	auipc	ra,0xffffe
    8000259c:	ff0080e7          	jalr	-16(ra) # 80000588 <printf>
    printf("\n");
    800025a0:	8552                	mv	a0,s4
    800025a2:	ffffe097          	auipc	ra,0xffffe
    800025a6:	fe6080e7          	jalr	-26(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800025aa:	16848493          	addi	s1,s1,360
    800025ae:	03248163          	beq	s1,s2,800025d0 <procdump+0x98>
    if(p->state == UNUSED)
    800025b2:	86a6                	mv	a3,s1
    800025b4:	ec04a783          	lw	a5,-320(s1)
    800025b8:	dbed                	beqz	a5,800025aa <procdump+0x72>
      state = "???";
    800025ba:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800025bc:	fcfb6be3          	bltu	s6,a5,80002592 <procdump+0x5a>
    800025c0:	1782                	slli	a5,a5,0x20
    800025c2:	9381                	srli	a5,a5,0x20
    800025c4:	078e                	slli	a5,a5,0x3
    800025c6:	97de                	add	a5,a5,s7
    800025c8:	6390                	ld	a2,0(a5)
    800025ca:	f661                	bnez	a2,80002592 <procdump+0x5a>
      state = "???";
    800025cc:	864e                	mv	a2,s3
    800025ce:	b7d1                	j	80002592 <procdump+0x5a>
  }
}
    800025d0:	60a6                	ld	ra,72(sp)
    800025d2:	6406                	ld	s0,64(sp)
    800025d4:	74e2                	ld	s1,56(sp)
    800025d6:	7942                	ld	s2,48(sp)
    800025d8:	79a2                	ld	s3,40(sp)
    800025da:	7a02                	ld	s4,32(sp)
    800025dc:	6ae2                	ld	s5,24(sp)
    800025de:	6b42                	ld	s6,16(sp)
    800025e0:	6ba2                	ld	s7,8(sp)
    800025e2:	6161                	addi	sp,sp,80
    800025e4:	8082                	ret

00000000800025e6 <swtch>:
    800025e6:	00153023          	sd	ra,0(a0)
    800025ea:	00253423          	sd	sp,8(a0)
    800025ee:	e900                	sd	s0,16(a0)
    800025f0:	ed04                	sd	s1,24(a0)
    800025f2:	03253023          	sd	s2,32(a0)
    800025f6:	03353423          	sd	s3,40(a0)
    800025fa:	03453823          	sd	s4,48(a0)
    800025fe:	03553c23          	sd	s5,56(a0)
    80002602:	05653023          	sd	s6,64(a0)
    80002606:	05753423          	sd	s7,72(a0)
    8000260a:	05853823          	sd	s8,80(a0)
    8000260e:	05953c23          	sd	s9,88(a0)
    80002612:	07a53023          	sd	s10,96(a0)
    80002616:	07b53423          	sd	s11,104(a0)
    8000261a:	0005b083          	ld	ra,0(a1)
    8000261e:	0085b103          	ld	sp,8(a1)
    80002622:	6980                	ld	s0,16(a1)
    80002624:	6d84                	ld	s1,24(a1)
    80002626:	0205b903          	ld	s2,32(a1)
    8000262a:	0285b983          	ld	s3,40(a1)
    8000262e:	0305ba03          	ld	s4,48(a1)
    80002632:	0385ba83          	ld	s5,56(a1)
    80002636:	0405bb03          	ld	s6,64(a1)
    8000263a:	0485bb83          	ld	s7,72(a1)
    8000263e:	0505bc03          	ld	s8,80(a1)
    80002642:	0585bc83          	ld	s9,88(a1)
    80002646:	0605bd03          	ld	s10,96(a1)
    8000264a:	0685bd83          	ld	s11,104(a1)
    8000264e:	8082                	ret

0000000080002650 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002650:	1141                	addi	sp,sp,-16
    80002652:	e406                	sd	ra,8(sp)
    80002654:	e022                	sd	s0,0(sp)
    80002656:	0800                	addi	s0,sp,16
	initlock(&tickslock, "time");
    80002658:	00006597          	auipc	a1,0x6
    8000265c:	ca058593          	addi	a1,a1,-864 # 800082f8 <states.1713+0x30>
    80002660:	00015517          	auipc	a0,0x15
    80002664:	a7050513          	addi	a0,a0,-1424 # 800170d0 <tickslock>
    80002668:	ffffe097          	auipc	ra,0xffffe
    8000266c:	4ec080e7          	jalr	1260(ra) # 80000b54 <initlock>
}
    80002670:	60a2                	ld	ra,8(sp)
    80002672:	6402                	ld	s0,0(sp)
    80002674:	0141                	addi	sp,sp,16
    80002676:	8082                	ret

0000000080002678 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002678:	1141                	addi	sp,sp,-16
    8000267a:	e422                	sd	s0,8(sp)
    8000267c:	0800                	addi	s0,sp,16
	asm volatile("csrw stvec, %0" : : "r" (x));
    8000267e:	00003797          	auipc	a5,0x3
    80002682:	48278793          	addi	a5,a5,1154 # 80005b00 <kernelvec>
    80002686:	10579073          	csrw	stvec,a5
	w_stvec((uint64)kernelvec);
}
    8000268a:	6422                	ld	s0,8(sp)
    8000268c:	0141                	addi	sp,sp,16
    8000268e:	8082                	ret

0000000080002690 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002690:	1141                	addi	sp,sp,-16
    80002692:	e406                	sd	ra,8(sp)
    80002694:	e022                	sd	s0,0(sp)
    80002696:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002698:	fffff097          	auipc	ra,0xfffff
    8000269c:	394080e7          	jalr	916(ra) # 80001a2c <myproc>
	asm volatile("csrr %0, sstatus" : "=r" (x) );
    800026a0:	100027f3          	csrr	a5,sstatus
	w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    800026a4:	9bf5                	andi	a5,a5,-3
	asm volatile("csrw sstatus, %0" : : "r" (x));
    800026a6:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    800026aa:	00005617          	auipc	a2,0x5
    800026ae:	95660613          	addi	a2,a2,-1706 # 80007000 <_trampoline>
    800026b2:	00005697          	auipc	a3,0x5
    800026b6:	94e68693          	addi	a3,a3,-1714 # 80007000 <_trampoline>
    800026ba:	8e91                	sub	a3,a3,a2
    800026bc:	040007b7          	lui	a5,0x4000
    800026c0:	17fd                	addi	a5,a5,-1
    800026c2:	07b2                	slli	a5,a5,0xc
    800026c4:	96be                	add	a3,a3,a5
	asm volatile("csrw stvec, %0" : : "r" (x));
    800026c6:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    800026ca:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    800026cc:	180026f3          	csrr	a3,satp
    800026d0:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    800026d2:	6d38                	ld	a4,88(a0)
    800026d4:	6134                	ld	a3,64(a0)
    800026d6:	6585                	lui	a1,0x1
    800026d8:	96ae                	add	a3,a3,a1
    800026da:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    800026dc:	6d38                	ld	a4,88(a0)
    800026de:	00000697          	auipc	a3,0x0
    800026e2:	13868693          	addi	a3,a3,312 # 80002816 <usertrap>
    800026e6:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    800026e8:	6d38                	ld	a4,88(a0)
	asm volatile("mv %0, tp" : "=r" (x) );
    800026ea:	8692                	mv	a3,tp
    800026ec:	f314                	sd	a3,32(a4)
	asm volatile("csrr %0, sstatus" : "=r" (x) );
    800026ee:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    800026f2:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    800026f6:	0206e693          	ori	a3,a3,32
	asm volatile("csrw sstatus, %0" : : "r" (x));
    800026fa:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    800026fe:	6d38                	ld	a4,88(a0)
	asm volatile("csrw sepc, %0" : : "r" (x));
    80002700:	6f18                	ld	a4,24(a4)
    80002702:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002706:	692c                	ld	a1,80(a0)
    80002708:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    8000270a:	00005717          	auipc	a4,0x5
    8000270e:	98670713          	addi	a4,a4,-1658 # 80007090 <userret>
    80002712:	8f11                	sub	a4,a4,a2
    80002714:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80002716:	577d                	li	a4,-1
    80002718:	177e                	slli	a4,a4,0x3f
    8000271a:	8dd9                	or	a1,a1,a4
    8000271c:	02000537          	lui	a0,0x2000
    80002720:	157d                	addi	a0,a0,-1
    80002722:	0536                	slli	a0,a0,0xd
    80002724:	9782                	jalr	a5
}
    80002726:	60a2                	ld	ra,8(sp)
    80002728:	6402                	ld	s0,0(sp)
    8000272a:	0141                	addi	sp,sp,16
    8000272c:	8082                	ret

000000008000272e <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    8000272e:	1101                	addi	sp,sp,-32
    80002730:	ec06                	sd	ra,24(sp)
    80002732:	e822                	sd	s0,16(sp)
    80002734:	e426                	sd	s1,8(sp)
    80002736:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002738:	00015497          	auipc	s1,0x15
    8000273c:	99848493          	addi	s1,s1,-1640 # 800170d0 <tickslock>
    80002740:	8526                	mv	a0,s1
    80002742:	ffffe097          	auipc	ra,0xffffe
    80002746:	4a2080e7          	jalr	1186(ra) # 80000be4 <acquire>
  ticks++;
    8000274a:	00007517          	auipc	a0,0x7
    8000274e:	8e650513          	addi	a0,a0,-1818 # 80009030 <ticks>
    80002752:	411c                	lw	a5,0(a0)
    80002754:	2785                	addiw	a5,a5,1
    80002756:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002758:	00000097          	auipc	ra,0x0
    8000275c:	b1c080e7          	jalr	-1252(ra) # 80002274 <wakeup>
  release(&tickslock);
    80002760:	8526                	mv	a0,s1
    80002762:	ffffe097          	auipc	ra,0xffffe
    80002766:	536080e7          	jalr	1334(ra) # 80000c98 <release>
}
    8000276a:	60e2                	ld	ra,24(sp)
    8000276c:	6442                	ld	s0,16(sp)
    8000276e:	64a2                	ld	s1,8(sp)
    80002770:	6105                	addi	sp,sp,32
    80002772:	8082                	ret

0000000080002774 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002774:	1101                	addi	sp,sp,-32
    80002776:	ec06                	sd	ra,24(sp)
    80002778:	e822                	sd	s0,16(sp)
    8000277a:	e426                	sd	s1,8(sp)
    8000277c:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000277e:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002782:	00074d63          	bltz	a4,8000279c <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002786:	57fd                	li	a5,-1
    80002788:	17fe                	slli	a5,a5,0x3f
    8000278a:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    8000278c:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    8000278e:	06f70363          	beq	a4,a5,800027f4 <devintr+0x80>
  }
}
    80002792:	60e2                	ld	ra,24(sp)
    80002794:	6442                	ld	s0,16(sp)
    80002796:	64a2                	ld	s1,8(sp)
    80002798:	6105                	addi	sp,sp,32
    8000279a:	8082                	ret
     (scause & 0xff) == 9){
    8000279c:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    800027a0:	46a5                	li	a3,9
    800027a2:	fed792e3          	bne	a5,a3,80002786 <devintr+0x12>
    int irq = plic_claim();
    800027a6:	00003097          	auipc	ra,0x3
    800027aa:	462080e7          	jalr	1122(ra) # 80005c08 <plic_claim>
    800027ae:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    800027b0:	47a9                	li	a5,10
    800027b2:	02f50763          	beq	a0,a5,800027e0 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    800027b6:	4785                	li	a5,1
    800027b8:	02f50963          	beq	a0,a5,800027ea <devintr+0x76>
    return 1;
    800027bc:	4505                	li	a0,1
    } else if(irq){
    800027be:	d8f1                	beqz	s1,80002792 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    800027c0:	85a6                	mv	a1,s1
    800027c2:	00006517          	auipc	a0,0x6
    800027c6:	b3e50513          	addi	a0,a0,-1218 # 80008300 <states.1713+0x38>
    800027ca:	ffffe097          	auipc	ra,0xffffe
    800027ce:	dbe080e7          	jalr	-578(ra) # 80000588 <printf>
      plic_complete(irq);
    800027d2:	8526                	mv	a0,s1
    800027d4:	00003097          	auipc	ra,0x3
    800027d8:	458080e7          	jalr	1112(ra) # 80005c2c <plic_complete>
    return 1;
    800027dc:	4505                	li	a0,1
    800027de:	bf55                	j	80002792 <devintr+0x1e>
      uartintr();
    800027e0:	ffffe097          	auipc	ra,0xffffe
    800027e4:	1c8080e7          	jalr	456(ra) # 800009a8 <uartintr>
    800027e8:	b7ed                	j	800027d2 <devintr+0x5e>
      virtio_disk_intr();
    800027ea:	00004097          	auipc	ra,0x4
    800027ee:	922080e7          	jalr	-1758(ra) # 8000610c <virtio_disk_intr>
    800027f2:	b7c5                	j	800027d2 <devintr+0x5e>
    if(cpuid() == 0){
    800027f4:	fffff097          	auipc	ra,0xfffff
    800027f8:	20c080e7          	jalr	524(ra) # 80001a00 <cpuid>
    800027fc:	c901                	beqz	a0,8000280c <devintr+0x98>
	asm volatile("csrr %0, sip" : "=r" (x) );
    800027fe:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002802:	9bf5                	andi	a5,a5,-3
	asm volatile("csrw sip, %0" : : "r" (x));
    80002804:	14479073          	csrw	sip,a5
    return 2;
    80002808:	4509                	li	a0,2
    8000280a:	b761                	j	80002792 <devintr+0x1e>
      clockintr();
    8000280c:	00000097          	auipc	ra,0x0
    80002810:	f22080e7          	jalr	-222(ra) # 8000272e <clockintr>
    80002814:	b7ed                	j	800027fe <devintr+0x8a>

0000000080002816 <usertrap>:
{
    80002816:	1101                	addi	sp,sp,-32
    80002818:	ec06                	sd	ra,24(sp)
    8000281a:	e822                	sd	s0,16(sp)
    8000281c:	e426                	sd	s1,8(sp)
    8000281e:	e04a                	sd	s2,0(sp)
    80002820:	1000                	addi	s0,sp,32
	asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002822:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002826:	1007f793          	andi	a5,a5,256
    8000282a:	e3ad                	bnez	a5,8000288c <usertrap+0x76>
	asm volatile("csrw stvec, %0" : : "r" (x));
    8000282c:	00003797          	auipc	a5,0x3
    80002830:	2d478793          	addi	a5,a5,724 # 80005b00 <kernelvec>
    80002834:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002838:	fffff097          	auipc	ra,0xfffff
    8000283c:	1f4080e7          	jalr	500(ra) # 80001a2c <myproc>
    80002840:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002842:	6d3c                	ld	a5,88(a0)
	asm volatile("csrr %0, sepc" : "=r" (x) );
    80002844:	14102773          	csrr	a4,sepc
    80002848:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000284a:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    8000284e:	47a1                	li	a5,8
    80002850:	04f71c63          	bne	a4,a5,800028a8 <usertrap+0x92>
    if(p->killed)
    80002854:	551c                	lw	a5,40(a0)
    80002856:	e3b9                	bnez	a5,8000289c <usertrap+0x86>
    p->trapframe->epc += 4;
    80002858:	6cb8                	ld	a4,88(s1)
    8000285a:	6f1c                	ld	a5,24(a4)
    8000285c:	0791                	addi	a5,a5,4
    8000285e:	ef1c                	sd	a5,24(a4)
	asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002860:	100027f3          	csrr	a5,sstatus
	w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002864:	0027e793          	ori	a5,a5,2
	asm volatile("csrw sstatus, %0" : : "r" (x));
    80002868:	10079073          	csrw	sstatus,a5
    syscall();
    8000286c:	00000097          	auipc	ra,0x0
    80002870:	2e0080e7          	jalr	736(ra) # 80002b4c <syscall>
  if(p->killed)
    80002874:	549c                	lw	a5,40(s1)
    80002876:	ebc1                	bnez	a5,80002906 <usertrap+0xf0>
  usertrapret();
    80002878:	00000097          	auipc	ra,0x0
    8000287c:	e18080e7          	jalr	-488(ra) # 80002690 <usertrapret>
}
    80002880:	60e2                	ld	ra,24(sp)
    80002882:	6442                	ld	s0,16(sp)
    80002884:	64a2                	ld	s1,8(sp)
    80002886:	6902                	ld	s2,0(sp)
    80002888:	6105                	addi	sp,sp,32
    8000288a:	8082                	ret
    panic("usertrap: not from user mode");
    8000288c:	00006517          	auipc	a0,0x6
    80002890:	a9450513          	addi	a0,a0,-1388 # 80008320 <states.1713+0x58>
    80002894:	ffffe097          	auipc	ra,0xffffe
    80002898:	caa080e7          	jalr	-854(ra) # 8000053e <panic>
      exit(-1);
    8000289c:	557d                	li	a0,-1
    8000289e:	00000097          	auipc	ra,0x0
    800028a2:	aa6080e7          	jalr	-1370(ra) # 80002344 <exit>
    800028a6:	bf4d                	j	80002858 <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    800028a8:	00000097          	auipc	ra,0x0
    800028ac:	ecc080e7          	jalr	-308(ra) # 80002774 <devintr>
    800028b0:	892a                	mv	s2,a0
    800028b2:	c501                	beqz	a0,800028ba <usertrap+0xa4>
  if(p->killed)
    800028b4:	549c                	lw	a5,40(s1)
    800028b6:	c3a1                	beqz	a5,800028f6 <usertrap+0xe0>
    800028b8:	a815                	j	800028ec <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    800028ba:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    800028be:	5890                	lw	a2,48(s1)
    800028c0:	00006517          	auipc	a0,0x6
    800028c4:	a8050513          	addi	a0,a0,-1408 # 80008340 <states.1713+0x78>
    800028c8:	ffffe097          	auipc	ra,0xffffe
    800028cc:	cc0080e7          	jalr	-832(ra) # 80000588 <printf>
	asm volatile("csrr %0, sepc" : "=r" (x) );
    800028d0:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    800028d4:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    800028d8:	00006517          	auipc	a0,0x6
    800028dc:	a9850513          	addi	a0,a0,-1384 # 80008370 <states.1713+0xa8>
    800028e0:	ffffe097          	auipc	ra,0xffffe
    800028e4:	ca8080e7          	jalr	-856(ra) # 80000588 <printf>
    p->killed = 1;
    800028e8:	4785                	li	a5,1
    800028ea:	d49c                	sw	a5,40(s1)
    exit(-1);
    800028ec:	557d                	li	a0,-1
    800028ee:	00000097          	auipc	ra,0x0
    800028f2:	a56080e7          	jalr	-1450(ra) # 80002344 <exit>
  if(which_dev == 2)
    800028f6:	4789                	li	a5,2
    800028f8:	f8f910e3          	bne	s2,a5,80002878 <usertrap+0x62>
    yield();
    800028fc:	fffff097          	auipc	ra,0xfffff
    80002900:	7b0080e7          	jalr	1968(ra) # 800020ac <yield>
    80002904:	bf95                	j	80002878 <usertrap+0x62>
  int which_dev = 0;
    80002906:	4901                	li	s2,0
    80002908:	b7d5                	j	800028ec <usertrap+0xd6>

000000008000290a <kerneltrap>:
{
    8000290a:	7179                	addi	sp,sp,-48
    8000290c:	f406                	sd	ra,40(sp)
    8000290e:	f022                	sd	s0,32(sp)
    80002910:	ec26                	sd	s1,24(sp)
    80002912:	e84a                	sd	s2,16(sp)
    80002914:	e44e                	sd	s3,8(sp)
    80002916:	1800                	addi	s0,sp,48
	asm volatile("csrr %0, sepc" : "=r" (x) );
    80002918:	14102973          	csrr	s2,sepc
	asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000291c:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002920:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002924:	1004f793          	andi	a5,s1,256
    80002928:	cb85                	beqz	a5,80002958 <kerneltrap+0x4e>
	asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000292a:	100027f3          	csrr	a5,sstatus
	return (x & SSTATUS_SIE) != 0;
    8000292e:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002930:	ef85                	bnez	a5,80002968 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002932:	00000097          	auipc	ra,0x0
    80002936:	e42080e7          	jalr	-446(ra) # 80002774 <devintr>
    8000293a:	cd1d                	beqz	a0,80002978 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    8000293c:	4789                	li	a5,2
    8000293e:	06f50a63          	beq	a0,a5,800029b2 <kerneltrap+0xa8>
	asm volatile("csrw sepc, %0" : : "r" (x));
    80002942:	14191073          	csrw	sepc,s2
	asm volatile("csrw sstatus, %0" : : "r" (x));
    80002946:	10049073          	csrw	sstatus,s1
}
    8000294a:	70a2                	ld	ra,40(sp)
    8000294c:	7402                	ld	s0,32(sp)
    8000294e:	64e2                	ld	s1,24(sp)
    80002950:	6942                	ld	s2,16(sp)
    80002952:	69a2                	ld	s3,8(sp)
    80002954:	6145                	addi	sp,sp,48
    80002956:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002958:	00006517          	auipc	a0,0x6
    8000295c:	a3850513          	addi	a0,a0,-1480 # 80008390 <states.1713+0xc8>
    80002960:	ffffe097          	auipc	ra,0xffffe
    80002964:	bde080e7          	jalr	-1058(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    80002968:	00006517          	auipc	a0,0x6
    8000296c:	a5050513          	addi	a0,a0,-1456 # 800083b8 <states.1713+0xf0>
    80002970:	ffffe097          	auipc	ra,0xffffe
    80002974:	bce080e7          	jalr	-1074(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    80002978:	85ce                	mv	a1,s3
    8000297a:	00006517          	auipc	a0,0x6
    8000297e:	a5e50513          	addi	a0,a0,-1442 # 800083d8 <states.1713+0x110>
    80002982:	ffffe097          	auipc	ra,0xffffe
    80002986:	c06080e7          	jalr	-1018(ra) # 80000588 <printf>
	asm volatile("csrr %0, sepc" : "=r" (x) );
    8000298a:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    8000298e:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002992:	00006517          	auipc	a0,0x6
    80002996:	a5650513          	addi	a0,a0,-1450 # 800083e8 <states.1713+0x120>
    8000299a:	ffffe097          	auipc	ra,0xffffe
    8000299e:	bee080e7          	jalr	-1042(ra) # 80000588 <printf>
    panic("kerneltrap");
    800029a2:	00006517          	auipc	a0,0x6
    800029a6:	a5e50513          	addi	a0,a0,-1442 # 80008400 <states.1713+0x138>
    800029aa:	ffffe097          	auipc	ra,0xffffe
    800029ae:	b94080e7          	jalr	-1132(ra) # 8000053e <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    800029b2:	fffff097          	auipc	ra,0xfffff
    800029b6:	07a080e7          	jalr	122(ra) # 80001a2c <myproc>
    800029ba:	d541                	beqz	a0,80002942 <kerneltrap+0x38>
    800029bc:	fffff097          	auipc	ra,0xfffff
    800029c0:	070080e7          	jalr	112(ra) # 80001a2c <myproc>
    800029c4:	4d18                	lw	a4,24(a0)
    800029c6:	4791                	li	a5,4
    800029c8:	f6f71de3          	bne	a4,a5,80002942 <kerneltrap+0x38>
    yield();
    800029cc:	fffff097          	auipc	ra,0xfffff
    800029d0:	6e0080e7          	jalr	1760(ra) # 800020ac <yield>
    800029d4:	b7bd                	j	80002942 <kerneltrap+0x38>

00000000800029d6 <argraw>:
	return strlen(buf);
}

static uint64
argraw(int n)
{
    800029d6:	1101                	addi	sp,sp,-32
    800029d8:	ec06                	sd	ra,24(sp)
    800029da:	e822                	sd	s0,16(sp)
    800029dc:	e426                	sd	s1,8(sp)
    800029de:	1000                	addi	s0,sp,32
    800029e0:	84aa                	mv	s1,a0
	struct proc *p = myproc();
    800029e2:	fffff097          	auipc	ra,0xfffff
    800029e6:	04a080e7          	jalr	74(ra) # 80001a2c <myproc>
	switch (n) {
    800029ea:	4795                	li	a5,5
    800029ec:	0497e163          	bltu	a5,s1,80002a2e <argraw+0x58>
    800029f0:	048a                	slli	s1,s1,0x2
    800029f2:	00006717          	auipc	a4,0x6
    800029f6:	a4670713          	addi	a4,a4,-1466 # 80008438 <states.1713+0x170>
    800029fa:	94ba                	add	s1,s1,a4
    800029fc:	409c                	lw	a5,0(s1)
    800029fe:	97ba                	add	a5,a5,a4
    80002a00:	8782                	jr	a5
	case 0:
		return p->trapframe->a0;
    80002a02:	6d3c                	ld	a5,88(a0)
    80002a04:	7ba8                	ld	a0,112(a5)
	case 5:
		return p->trapframe->a5;
	}
	panic("argraw");
	return -1;
}
    80002a06:	60e2                	ld	ra,24(sp)
    80002a08:	6442                	ld	s0,16(sp)
    80002a0a:	64a2                	ld	s1,8(sp)
    80002a0c:	6105                	addi	sp,sp,32
    80002a0e:	8082                	ret
		return p->trapframe->a1;
    80002a10:	6d3c                	ld	a5,88(a0)
    80002a12:	7fa8                	ld	a0,120(a5)
    80002a14:	bfcd                	j	80002a06 <argraw+0x30>
		return p->trapframe->a2;
    80002a16:	6d3c                	ld	a5,88(a0)
    80002a18:	63c8                	ld	a0,128(a5)
    80002a1a:	b7f5                	j	80002a06 <argraw+0x30>
		return p->trapframe->a3;
    80002a1c:	6d3c                	ld	a5,88(a0)
    80002a1e:	67c8                	ld	a0,136(a5)
    80002a20:	b7dd                	j	80002a06 <argraw+0x30>
		return p->trapframe->a4;
    80002a22:	6d3c                	ld	a5,88(a0)
    80002a24:	6bc8                	ld	a0,144(a5)
    80002a26:	b7c5                	j	80002a06 <argraw+0x30>
		return p->trapframe->a5;
    80002a28:	6d3c                	ld	a5,88(a0)
    80002a2a:	6fc8                	ld	a0,152(a5)
    80002a2c:	bfe9                	j	80002a06 <argraw+0x30>
	panic("argraw");
    80002a2e:	00006517          	auipc	a0,0x6
    80002a32:	9e250513          	addi	a0,a0,-1566 # 80008410 <states.1713+0x148>
    80002a36:	ffffe097          	auipc	ra,0xffffe
    80002a3a:	b08080e7          	jalr	-1272(ra) # 8000053e <panic>

0000000080002a3e <fetchaddr>:
{
    80002a3e:	1101                	addi	sp,sp,-32
    80002a40:	ec06                	sd	ra,24(sp)
    80002a42:	e822                	sd	s0,16(sp)
    80002a44:	e426                	sd	s1,8(sp)
    80002a46:	e04a                	sd	s2,0(sp)
    80002a48:	1000                	addi	s0,sp,32
    80002a4a:	84aa                	mv	s1,a0
    80002a4c:	892e                	mv	s2,a1
	struct proc *p = myproc();
    80002a4e:	fffff097          	auipc	ra,0xfffff
    80002a52:	fde080e7          	jalr	-34(ra) # 80001a2c <myproc>
	if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002a56:	653c                	ld	a5,72(a0)
    80002a58:	02f4f863          	bgeu	s1,a5,80002a88 <fetchaddr+0x4a>
    80002a5c:	00848713          	addi	a4,s1,8
    80002a60:	02e7e663          	bltu	a5,a4,80002a8c <fetchaddr+0x4e>
	if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002a64:	46a1                	li	a3,8
    80002a66:	8626                	mv	a2,s1
    80002a68:	85ca                	mv	a1,s2
    80002a6a:	6928                	ld	a0,80(a0)
    80002a6c:	fffff097          	auipc	ra,0xfffff
    80002a70:	c92080e7          	jalr	-878(ra) # 800016fe <copyin>
    80002a74:	00a03533          	snez	a0,a0
    80002a78:	40a00533          	neg	a0,a0
}
    80002a7c:	60e2                	ld	ra,24(sp)
    80002a7e:	6442                	ld	s0,16(sp)
    80002a80:	64a2                	ld	s1,8(sp)
    80002a82:	6902                	ld	s2,0(sp)
    80002a84:	6105                	addi	sp,sp,32
    80002a86:	8082                	ret
		return -1;
    80002a88:	557d                	li	a0,-1
    80002a8a:	bfcd                	j	80002a7c <fetchaddr+0x3e>
    80002a8c:	557d                	li	a0,-1
    80002a8e:	b7fd                	j	80002a7c <fetchaddr+0x3e>

0000000080002a90 <fetchstr>:
{
    80002a90:	7179                	addi	sp,sp,-48
    80002a92:	f406                	sd	ra,40(sp)
    80002a94:	f022                	sd	s0,32(sp)
    80002a96:	ec26                	sd	s1,24(sp)
    80002a98:	e84a                	sd	s2,16(sp)
    80002a9a:	e44e                	sd	s3,8(sp)
    80002a9c:	1800                	addi	s0,sp,48
    80002a9e:	892a                	mv	s2,a0
    80002aa0:	84ae                	mv	s1,a1
    80002aa2:	89b2                	mv	s3,a2
	struct proc *p = myproc();
    80002aa4:	fffff097          	auipc	ra,0xfffff
    80002aa8:	f88080e7          	jalr	-120(ra) # 80001a2c <myproc>
	int err = copyinstr(p->pagetable, buf, addr, max);
    80002aac:	86ce                	mv	a3,s3
    80002aae:	864a                	mv	a2,s2
    80002ab0:	85a6                	mv	a1,s1
    80002ab2:	6928                	ld	a0,80(a0)
    80002ab4:	fffff097          	auipc	ra,0xfffff
    80002ab8:	cd6080e7          	jalr	-810(ra) # 8000178a <copyinstr>
	if(err < 0)
    80002abc:	00054763          	bltz	a0,80002aca <fetchstr+0x3a>
	return strlen(buf);
    80002ac0:	8526                	mv	a0,s1
    80002ac2:	ffffe097          	auipc	ra,0xffffe
    80002ac6:	3a2080e7          	jalr	930(ra) # 80000e64 <strlen>
}
    80002aca:	70a2                	ld	ra,40(sp)
    80002acc:	7402                	ld	s0,32(sp)
    80002ace:	64e2                	ld	s1,24(sp)
    80002ad0:	6942                	ld	s2,16(sp)
    80002ad2:	69a2                	ld	s3,8(sp)
    80002ad4:	6145                	addi	sp,sp,48
    80002ad6:	8082                	ret

0000000080002ad8 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002ad8:	1101                	addi	sp,sp,-32
    80002ada:	ec06                	sd	ra,24(sp)
    80002adc:	e822                	sd	s0,16(sp)
    80002ade:	e426                	sd	s1,8(sp)
    80002ae0:	1000                	addi	s0,sp,32
    80002ae2:	84ae                	mv	s1,a1
	*ip = argraw(n);
    80002ae4:	00000097          	auipc	ra,0x0
    80002ae8:	ef2080e7          	jalr	-270(ra) # 800029d6 <argraw>
    80002aec:	c088                	sw	a0,0(s1)
	return 0;
}
    80002aee:	4501                	li	a0,0
    80002af0:	60e2                	ld	ra,24(sp)
    80002af2:	6442                	ld	s0,16(sp)
    80002af4:	64a2                	ld	s1,8(sp)
    80002af6:	6105                	addi	sp,sp,32
    80002af8:	8082                	ret

0000000080002afa <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002afa:	1101                	addi	sp,sp,-32
    80002afc:	ec06                	sd	ra,24(sp)
    80002afe:	e822                	sd	s0,16(sp)
    80002b00:	e426                	sd	s1,8(sp)
    80002b02:	1000                	addi	s0,sp,32
    80002b04:	84ae                	mv	s1,a1
	*ip = argraw(n);
    80002b06:	00000097          	auipc	ra,0x0
    80002b0a:	ed0080e7          	jalr	-304(ra) # 800029d6 <argraw>
    80002b0e:	e088                	sd	a0,0(s1)
	return 0;
}
    80002b10:	4501                	li	a0,0
    80002b12:	60e2                	ld	ra,24(sp)
    80002b14:	6442                	ld	s0,16(sp)
    80002b16:	64a2                	ld	s1,8(sp)
    80002b18:	6105                	addi	sp,sp,32
    80002b1a:	8082                	ret

0000000080002b1c <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002b1c:	1101                	addi	sp,sp,-32
    80002b1e:	ec06                	sd	ra,24(sp)
    80002b20:	e822                	sd	s0,16(sp)
    80002b22:	e426                	sd	s1,8(sp)
    80002b24:	e04a                	sd	s2,0(sp)
    80002b26:	1000                	addi	s0,sp,32
    80002b28:	84ae                	mv	s1,a1
    80002b2a:	8932                	mv	s2,a2
	*ip = argraw(n);
    80002b2c:	00000097          	auipc	ra,0x0
    80002b30:	eaa080e7          	jalr	-342(ra) # 800029d6 <argraw>
	uint64 addr;
	if(argaddr(n, &addr) < 0)
		return -1;
	return fetchstr(addr, buf, max);
    80002b34:	864a                	mv	a2,s2
    80002b36:	85a6                	mv	a1,s1
    80002b38:	00000097          	auipc	ra,0x0
    80002b3c:	f58080e7          	jalr	-168(ra) # 80002a90 <fetchstr>
}
    80002b40:	60e2                	ld	ra,24(sp)
    80002b42:	6442                	ld	s0,16(sp)
    80002b44:	64a2                	ld	s1,8(sp)
    80002b46:	6902                	ld	s2,0(sp)
    80002b48:	6105                	addi	sp,sp,32
    80002b4a:	8082                	ret

0000000080002b4c <syscall>:
[SYS_close]   sys_close,
};

void
syscall(void)
{
    80002b4c:	1101                	addi	sp,sp,-32
    80002b4e:	ec06                	sd	ra,24(sp)
    80002b50:	e822                	sd	s0,16(sp)
    80002b52:	e426                	sd	s1,8(sp)
    80002b54:	e04a                	sd	s2,0(sp)
    80002b56:	1000                	addi	s0,sp,32
	int num;
	struct proc *p = myproc();
    80002b58:	fffff097          	auipc	ra,0xfffff
    80002b5c:	ed4080e7          	jalr	-300(ra) # 80001a2c <myproc>
    80002b60:	84aa                	mv	s1,a0

	num = p->trapframe->a7;
    80002b62:	05853903          	ld	s2,88(a0)
    80002b66:	0a893783          	ld	a5,168(s2)
    80002b6a:	0007869b          	sext.w	a3,a5
	if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002b6e:	37fd                	addiw	a5,a5,-1
    80002b70:	4751                	li	a4,20
    80002b72:	00f76f63          	bltu	a4,a5,80002b90 <syscall+0x44>
    80002b76:	00369713          	slli	a4,a3,0x3
    80002b7a:	00006797          	auipc	a5,0x6
    80002b7e:	8d678793          	addi	a5,a5,-1834 # 80008450 <syscalls>
    80002b82:	97ba                	add	a5,a5,a4
    80002b84:	639c                	ld	a5,0(a5)
    80002b86:	c789                	beqz	a5,80002b90 <syscall+0x44>
		p->trapframe->a0 = syscalls[num]();
    80002b88:	9782                	jalr	a5
    80002b8a:	06a93823          	sd	a0,112(s2)
    80002b8e:	a839                	j	80002bac <syscall+0x60>
	} else {
		printf("%d %s: unknown sys call %d\n",
    80002b90:	15848613          	addi	a2,s1,344
    80002b94:	588c                	lw	a1,48(s1)
    80002b96:	00006517          	auipc	a0,0x6
    80002b9a:	88250513          	addi	a0,a0,-1918 # 80008418 <states.1713+0x150>
    80002b9e:	ffffe097          	auipc	ra,0xffffe
    80002ba2:	9ea080e7          	jalr	-1558(ra) # 80000588 <printf>
				p->pid, p->name, num);
		p->trapframe->a0 = -1;
    80002ba6:	6cbc                	ld	a5,88(s1)
    80002ba8:	577d                	li	a4,-1
    80002baa:	fbb8                	sd	a4,112(a5)
	}
}
    80002bac:	60e2                	ld	ra,24(sp)
    80002bae:	6442                	ld	s0,16(sp)
    80002bb0:	64a2                	ld	s1,8(sp)
    80002bb2:	6902                	ld	s2,0(sp)
    80002bb4:	6105                	addi	sp,sp,32
    80002bb6:	8082                	ret

0000000080002bb8 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002bb8:	1101                	addi	sp,sp,-32
    80002bba:	ec06                	sd	ra,24(sp)
    80002bbc:	e822                	sd	s0,16(sp)
    80002bbe:	1000                	addi	s0,sp,32
	int n;
	if(argint(0, &n) < 0)
    80002bc0:	fec40593          	addi	a1,s0,-20
    80002bc4:	4501                	li	a0,0
    80002bc6:	00000097          	auipc	ra,0x0
    80002bca:	f12080e7          	jalr	-238(ra) # 80002ad8 <argint>
		return -1;
    80002bce:	57fd                	li	a5,-1
	if(argint(0, &n) < 0)
    80002bd0:	00054963          	bltz	a0,80002be2 <sys_exit+0x2a>
	exit(n);
    80002bd4:	fec42503          	lw	a0,-20(s0)
    80002bd8:	fffff097          	auipc	ra,0xfffff
    80002bdc:	76c080e7          	jalr	1900(ra) # 80002344 <exit>
	return 0;  // not reached
    80002be0:	4781                	li	a5,0
}
    80002be2:	853e                	mv	a0,a5
    80002be4:	60e2                	ld	ra,24(sp)
    80002be6:	6442                	ld	s0,16(sp)
    80002be8:	6105                	addi	sp,sp,32
    80002bea:	8082                	ret

0000000080002bec <sys_getpid>:

uint64
sys_getpid(void)
{
    80002bec:	1141                	addi	sp,sp,-16
    80002bee:	e406                	sd	ra,8(sp)
    80002bf0:	e022                	sd	s0,0(sp)
    80002bf2:	0800                	addi	s0,sp,16
	return myproc()->pid;
    80002bf4:	fffff097          	auipc	ra,0xfffff
    80002bf8:	e38080e7          	jalr	-456(ra) # 80001a2c <myproc>
}
    80002bfc:	5908                	lw	a0,48(a0)
    80002bfe:	60a2                	ld	ra,8(sp)
    80002c00:	6402                	ld	s0,0(sp)
    80002c02:	0141                	addi	sp,sp,16
    80002c04:	8082                	ret

0000000080002c06 <sys_fork>:

uint64
sys_fork(void)
{
    80002c06:	1141                	addi	sp,sp,-16
    80002c08:	e406                	sd	ra,8(sp)
    80002c0a:	e022                	sd	s0,0(sp)
    80002c0c:	0800                	addi	s0,sp,16
	return fork();
    80002c0e:	fffff097          	auipc	ra,0xfffff
    80002c12:	1ec080e7          	jalr	492(ra) # 80001dfa <fork>
}
    80002c16:	60a2                	ld	ra,8(sp)
    80002c18:	6402                	ld	s0,0(sp)
    80002c1a:	0141                	addi	sp,sp,16
    80002c1c:	8082                	ret

0000000080002c1e <sys_wait>:

uint64
sys_wait(void)
{
    80002c1e:	1101                	addi	sp,sp,-32
    80002c20:	ec06                	sd	ra,24(sp)
    80002c22:	e822                	sd	s0,16(sp)
    80002c24:	1000                	addi	s0,sp,32
	uint64 p;
	if(argaddr(0, &p) < 0)
    80002c26:	fe840593          	addi	a1,s0,-24
    80002c2a:	4501                	li	a0,0
    80002c2c:	00000097          	auipc	ra,0x0
    80002c30:	ece080e7          	jalr	-306(ra) # 80002afa <argaddr>
    80002c34:	87aa                	mv	a5,a0
		return -1;
    80002c36:	557d                	li	a0,-1
	if(argaddr(0, &p) < 0)
    80002c38:	0007c863          	bltz	a5,80002c48 <sys_wait+0x2a>
	return wait(p);
    80002c3c:	fe843503          	ld	a0,-24(s0)
    80002c40:	fffff097          	auipc	ra,0xfffff
    80002c44:	50c080e7          	jalr	1292(ra) # 8000214c <wait>
}
    80002c48:	60e2                	ld	ra,24(sp)
    80002c4a:	6442                	ld	s0,16(sp)
    80002c4c:	6105                	addi	sp,sp,32
    80002c4e:	8082                	ret

0000000080002c50 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002c50:	7179                	addi	sp,sp,-48
    80002c52:	f406                	sd	ra,40(sp)
    80002c54:	f022                	sd	s0,32(sp)
    80002c56:	ec26                	sd	s1,24(sp)
    80002c58:	1800                	addi	s0,sp,48
	int addr;
	int n;
	// struct proc *p = myproc();

	if(argint(0, &n) < 0)
    80002c5a:	fdc40593          	addi	a1,s0,-36
    80002c5e:	4501                	li	a0,0
    80002c60:	00000097          	auipc	ra,0x0
    80002c64:	e78080e7          	jalr	-392(ra) # 80002ad8 <argint>
    80002c68:	87aa                	mv	a5,a0
		return -1;
    80002c6a:	557d                	li	a0,-1
	if(argint(0, &n) < 0)
    80002c6c:	0207c063          	bltz	a5,80002c8c <sys_sbrk+0x3c>
	addr = myproc()->sz;
    80002c70:	fffff097          	auipc	ra,0xfffff
    80002c74:	dbc080e7          	jalr	-580(ra) # 80001a2c <myproc>
    80002c78:	4524                	lw	s1,72(a0)

	// printf("%x\n", p->sz);
	// debug_uvmpte(p->pagetable, 0, p->sz);

	if(growproc(n) < 0)
    80002c7a:	fdc42503          	lw	a0,-36(s0)
    80002c7e:	fffff097          	auipc	ra,0xfffff
    80002c82:	108080e7          	jalr	264(ra) # 80001d86 <growproc>
    80002c86:	00054863          	bltz	a0,80002c96 <sys_sbrk+0x46>
		return -1;

	// printf("%x\n", p->sz);
	// debug_uvmpte(p->pagetable, 0, p->sz);

	return addr;
    80002c8a:	8526                	mv	a0,s1
}
    80002c8c:	70a2                	ld	ra,40(sp)
    80002c8e:	7402                	ld	s0,32(sp)
    80002c90:	64e2                	ld	s1,24(sp)
    80002c92:	6145                	addi	sp,sp,48
    80002c94:	8082                	ret
		return -1;
    80002c96:	557d                	li	a0,-1
    80002c98:	bfd5                	j	80002c8c <sys_sbrk+0x3c>

0000000080002c9a <sys_sleep>:

uint64
sys_sleep(void)
{
    80002c9a:	7139                	addi	sp,sp,-64
    80002c9c:	fc06                	sd	ra,56(sp)
    80002c9e:	f822                	sd	s0,48(sp)
    80002ca0:	f426                	sd	s1,40(sp)
    80002ca2:	f04a                	sd	s2,32(sp)
    80002ca4:	ec4e                	sd	s3,24(sp)
    80002ca6:	0080                	addi	s0,sp,64
	int n;
	uint ticks0;

	if(argint(0, &n) < 0)
    80002ca8:	fcc40593          	addi	a1,s0,-52
    80002cac:	4501                	li	a0,0
    80002cae:	00000097          	auipc	ra,0x0
    80002cb2:	e2a080e7          	jalr	-470(ra) # 80002ad8 <argint>
		return -1;
    80002cb6:	57fd                	li	a5,-1
	if(argint(0, &n) < 0)
    80002cb8:	06054563          	bltz	a0,80002d22 <sys_sleep+0x88>
	acquire(&tickslock);
    80002cbc:	00014517          	auipc	a0,0x14
    80002cc0:	41450513          	addi	a0,a0,1044 # 800170d0 <tickslock>
    80002cc4:	ffffe097          	auipc	ra,0xffffe
    80002cc8:	f20080e7          	jalr	-224(ra) # 80000be4 <acquire>
	ticks0 = ticks;
    80002ccc:	00006917          	auipc	s2,0x6
    80002cd0:	36492903          	lw	s2,868(s2) # 80009030 <ticks>
	while(ticks - ticks0 < n){
    80002cd4:	fcc42783          	lw	a5,-52(s0)
    80002cd8:	cf85                	beqz	a5,80002d10 <sys_sleep+0x76>
		if(myproc()->killed){
			release(&tickslock);
			return -1;
		}
		sleep(&ticks, &tickslock);
    80002cda:	00014997          	auipc	s3,0x14
    80002cde:	3f698993          	addi	s3,s3,1014 # 800170d0 <tickslock>
    80002ce2:	00006497          	auipc	s1,0x6
    80002ce6:	34e48493          	addi	s1,s1,846 # 80009030 <ticks>
		if(myproc()->killed){
    80002cea:	fffff097          	auipc	ra,0xfffff
    80002cee:	d42080e7          	jalr	-702(ra) # 80001a2c <myproc>
    80002cf2:	551c                	lw	a5,40(a0)
    80002cf4:	ef9d                	bnez	a5,80002d32 <sys_sleep+0x98>
		sleep(&ticks, &tickslock);
    80002cf6:	85ce                	mv	a1,s3
    80002cf8:	8526                	mv	a0,s1
    80002cfa:	fffff097          	auipc	ra,0xfffff
    80002cfe:	3ee080e7          	jalr	1006(ra) # 800020e8 <sleep>
	while(ticks - ticks0 < n){
    80002d02:	409c                	lw	a5,0(s1)
    80002d04:	412787bb          	subw	a5,a5,s2
    80002d08:	fcc42703          	lw	a4,-52(s0)
    80002d0c:	fce7efe3          	bltu	a5,a4,80002cea <sys_sleep+0x50>
	}
	release(&tickslock);
    80002d10:	00014517          	auipc	a0,0x14
    80002d14:	3c050513          	addi	a0,a0,960 # 800170d0 <tickslock>
    80002d18:	ffffe097          	auipc	ra,0xffffe
    80002d1c:	f80080e7          	jalr	-128(ra) # 80000c98 <release>
	return 0;
    80002d20:	4781                	li	a5,0
}
    80002d22:	853e                	mv	a0,a5
    80002d24:	70e2                	ld	ra,56(sp)
    80002d26:	7442                	ld	s0,48(sp)
    80002d28:	74a2                	ld	s1,40(sp)
    80002d2a:	7902                	ld	s2,32(sp)
    80002d2c:	69e2                	ld	s3,24(sp)
    80002d2e:	6121                	addi	sp,sp,64
    80002d30:	8082                	ret
			release(&tickslock);
    80002d32:	00014517          	auipc	a0,0x14
    80002d36:	39e50513          	addi	a0,a0,926 # 800170d0 <tickslock>
    80002d3a:	ffffe097          	auipc	ra,0xffffe
    80002d3e:	f5e080e7          	jalr	-162(ra) # 80000c98 <release>
			return -1;
    80002d42:	57fd                	li	a5,-1
    80002d44:	bff9                	j	80002d22 <sys_sleep+0x88>

0000000080002d46 <sys_kill>:

uint64
sys_kill(void)
{
    80002d46:	1101                	addi	sp,sp,-32
    80002d48:	ec06                	sd	ra,24(sp)
    80002d4a:	e822                	sd	s0,16(sp)
    80002d4c:	1000                	addi	s0,sp,32
	int pid;

	if(argint(0, &pid) < 0)
    80002d4e:	fec40593          	addi	a1,s0,-20
    80002d52:	4501                	li	a0,0
    80002d54:	00000097          	auipc	ra,0x0
    80002d58:	d84080e7          	jalr	-636(ra) # 80002ad8 <argint>
    80002d5c:	87aa                	mv	a5,a0
		return -1;
    80002d5e:	557d                	li	a0,-1
	if(argint(0, &pid) < 0)
    80002d60:	0007c863          	bltz	a5,80002d70 <sys_kill+0x2a>
	return kill(pid);
    80002d64:	fec42503          	lw	a0,-20(s0)
    80002d68:	fffff097          	auipc	ra,0xfffff
    80002d6c:	6b2080e7          	jalr	1714(ra) # 8000241a <kill>
}
    80002d70:	60e2                	ld	ra,24(sp)
    80002d72:	6442                	ld	s0,16(sp)
    80002d74:	6105                	addi	sp,sp,32
    80002d76:	8082                	ret

0000000080002d78 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002d78:	1101                	addi	sp,sp,-32
    80002d7a:	ec06                	sd	ra,24(sp)
    80002d7c:	e822                	sd	s0,16(sp)
    80002d7e:	e426                	sd	s1,8(sp)
    80002d80:	1000                	addi	s0,sp,32
	uint xticks;

	acquire(&tickslock);
    80002d82:	00014517          	auipc	a0,0x14
    80002d86:	34e50513          	addi	a0,a0,846 # 800170d0 <tickslock>
    80002d8a:	ffffe097          	auipc	ra,0xffffe
    80002d8e:	e5a080e7          	jalr	-422(ra) # 80000be4 <acquire>
	xticks = ticks;
    80002d92:	00006497          	auipc	s1,0x6
    80002d96:	29e4a483          	lw	s1,670(s1) # 80009030 <ticks>
	release(&tickslock);
    80002d9a:	00014517          	auipc	a0,0x14
    80002d9e:	33650513          	addi	a0,a0,822 # 800170d0 <tickslock>
    80002da2:	ffffe097          	auipc	ra,0xffffe
    80002da6:	ef6080e7          	jalr	-266(ra) # 80000c98 <release>
	return xticks;
}
    80002daa:	02049513          	slli	a0,s1,0x20
    80002dae:	9101                	srli	a0,a0,0x20
    80002db0:	60e2                	ld	ra,24(sp)
    80002db2:	6442                	ld	s0,16(sp)
    80002db4:	64a2                	ld	s1,8(sp)
    80002db6:	6105                	addi	sp,sp,32
    80002db8:	8082                	ret

0000000080002dba <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002dba:	7179                	addi	sp,sp,-48
    80002dbc:	f406                	sd	ra,40(sp)
    80002dbe:	f022                	sd	s0,32(sp)
    80002dc0:	ec26                	sd	s1,24(sp)
    80002dc2:	e84a                	sd	s2,16(sp)
    80002dc4:	e44e                	sd	s3,8(sp)
    80002dc6:	e052                	sd	s4,0(sp)
    80002dc8:	1800                	addi	s0,sp,48
	struct buf *b;

	initlock(&bcache.lock, "bcache");
    80002dca:	00005597          	auipc	a1,0x5
    80002dce:	73658593          	addi	a1,a1,1846 # 80008500 <syscalls+0xb0>
    80002dd2:	00014517          	auipc	a0,0x14
    80002dd6:	31650513          	addi	a0,a0,790 # 800170e8 <bcache>
    80002dda:	ffffe097          	auipc	ra,0xffffe
    80002dde:	d7a080e7          	jalr	-646(ra) # 80000b54 <initlock>

	// Create linked list of buffers
	bcache.head.prev = &bcache.head;
    80002de2:	0001c797          	auipc	a5,0x1c
    80002de6:	30678793          	addi	a5,a5,774 # 8001f0e8 <bcache+0x8000>
    80002dea:	0001c717          	auipc	a4,0x1c
    80002dee:	56670713          	addi	a4,a4,1382 # 8001f350 <bcache+0x8268>
    80002df2:	2ae7b823          	sd	a4,688(a5)
	bcache.head.next = &bcache.head;
    80002df6:	2ae7bc23          	sd	a4,696(a5)
	for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002dfa:	00014497          	auipc	s1,0x14
    80002dfe:	30648493          	addi	s1,s1,774 # 80017100 <bcache+0x18>
		b->next = bcache.head.next;
    80002e02:	893e                	mv	s2,a5
		b->prev = &bcache.head;
    80002e04:	89ba                	mv	s3,a4
		initsleeplock(&b->lock, "buffer");
    80002e06:	00005a17          	auipc	s4,0x5
    80002e0a:	702a0a13          	addi	s4,s4,1794 # 80008508 <syscalls+0xb8>
		b->next = bcache.head.next;
    80002e0e:	2b893783          	ld	a5,696(s2)
    80002e12:	e8bc                	sd	a5,80(s1)
		b->prev = &bcache.head;
    80002e14:	0534b423          	sd	s3,72(s1)
		initsleeplock(&b->lock, "buffer");
    80002e18:	85d2                	mv	a1,s4
    80002e1a:	01048513          	addi	a0,s1,16
    80002e1e:	00001097          	auipc	ra,0x1
    80002e22:	4bc080e7          	jalr	1212(ra) # 800042da <initsleeplock>
		bcache.head.next->prev = b;
    80002e26:	2b893783          	ld	a5,696(s2)
    80002e2a:	e7a4                	sd	s1,72(a5)
		bcache.head.next = b;
    80002e2c:	2a993c23          	sd	s1,696(s2)
	for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002e30:	45848493          	addi	s1,s1,1112
    80002e34:	fd349de3          	bne	s1,s3,80002e0e <binit+0x54>
	}
}
    80002e38:	70a2                	ld	ra,40(sp)
    80002e3a:	7402                	ld	s0,32(sp)
    80002e3c:	64e2                	ld	s1,24(sp)
    80002e3e:	6942                	ld	s2,16(sp)
    80002e40:	69a2                	ld	s3,8(sp)
    80002e42:	6a02                	ld	s4,0(sp)
    80002e44:	6145                	addi	sp,sp,48
    80002e46:	8082                	ret

0000000080002e48 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80002e48:	7179                	addi	sp,sp,-48
    80002e4a:	f406                	sd	ra,40(sp)
    80002e4c:	f022                	sd	s0,32(sp)
    80002e4e:	ec26                	sd	s1,24(sp)
    80002e50:	e84a                	sd	s2,16(sp)
    80002e52:	e44e                	sd	s3,8(sp)
    80002e54:	1800                	addi	s0,sp,48
    80002e56:	89aa                	mv	s3,a0
    80002e58:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    80002e5a:	00014517          	auipc	a0,0x14
    80002e5e:	28e50513          	addi	a0,a0,654 # 800170e8 <bcache>
    80002e62:	ffffe097          	auipc	ra,0xffffe
    80002e66:	d82080e7          	jalr	-638(ra) # 80000be4 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80002e6a:	0001c497          	auipc	s1,0x1c
    80002e6e:	5364b483          	ld	s1,1334(s1) # 8001f3a0 <bcache+0x82b8>
    80002e72:	0001c797          	auipc	a5,0x1c
    80002e76:	4de78793          	addi	a5,a5,1246 # 8001f350 <bcache+0x8268>
    80002e7a:	02f48f63          	beq	s1,a5,80002eb8 <bread+0x70>
    80002e7e:	873e                	mv	a4,a5
    80002e80:	a021                	j	80002e88 <bread+0x40>
    80002e82:	68a4                	ld	s1,80(s1)
    80002e84:	02e48a63          	beq	s1,a4,80002eb8 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80002e88:	449c                	lw	a5,8(s1)
    80002e8a:	ff379ce3          	bne	a5,s3,80002e82 <bread+0x3a>
    80002e8e:	44dc                	lw	a5,12(s1)
    80002e90:	ff2799e3          	bne	a5,s2,80002e82 <bread+0x3a>
      b->refcnt++;
    80002e94:	40bc                	lw	a5,64(s1)
    80002e96:	2785                	addiw	a5,a5,1
    80002e98:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002e9a:	00014517          	auipc	a0,0x14
    80002e9e:	24e50513          	addi	a0,a0,590 # 800170e8 <bcache>
    80002ea2:	ffffe097          	auipc	ra,0xffffe
    80002ea6:	df6080e7          	jalr	-522(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    80002eaa:	01048513          	addi	a0,s1,16
    80002eae:	00001097          	auipc	ra,0x1
    80002eb2:	466080e7          	jalr	1126(ra) # 80004314 <acquiresleep>
      return b;
    80002eb6:	a8b9                	j	80002f14 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002eb8:	0001c497          	auipc	s1,0x1c
    80002ebc:	4e04b483          	ld	s1,1248(s1) # 8001f398 <bcache+0x82b0>
    80002ec0:	0001c797          	auipc	a5,0x1c
    80002ec4:	49078793          	addi	a5,a5,1168 # 8001f350 <bcache+0x8268>
    80002ec8:	00f48863          	beq	s1,a5,80002ed8 <bread+0x90>
    80002ecc:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80002ece:	40bc                	lw	a5,64(s1)
    80002ed0:	cf81                	beqz	a5,80002ee8 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002ed2:	64a4                	ld	s1,72(s1)
    80002ed4:	fee49de3          	bne	s1,a4,80002ece <bread+0x86>
  panic("bget: no buffers");
    80002ed8:	00005517          	auipc	a0,0x5
    80002edc:	63850513          	addi	a0,a0,1592 # 80008510 <syscalls+0xc0>
    80002ee0:	ffffd097          	auipc	ra,0xffffd
    80002ee4:	65e080e7          	jalr	1630(ra) # 8000053e <panic>
      b->dev = dev;
    80002ee8:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    80002eec:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    80002ef0:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80002ef4:	4785                	li	a5,1
    80002ef6:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002ef8:	00014517          	auipc	a0,0x14
    80002efc:	1f050513          	addi	a0,a0,496 # 800170e8 <bcache>
    80002f00:	ffffe097          	auipc	ra,0xffffe
    80002f04:	d98080e7          	jalr	-616(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    80002f08:	01048513          	addi	a0,s1,16
    80002f0c:	00001097          	auipc	ra,0x1
    80002f10:	408080e7          	jalr	1032(ra) # 80004314 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80002f14:	409c                	lw	a5,0(s1)
    80002f16:	cb89                	beqz	a5,80002f28 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80002f18:	8526                	mv	a0,s1
    80002f1a:	70a2                	ld	ra,40(sp)
    80002f1c:	7402                	ld	s0,32(sp)
    80002f1e:	64e2                	ld	s1,24(sp)
    80002f20:	6942                	ld	s2,16(sp)
    80002f22:	69a2                	ld	s3,8(sp)
    80002f24:	6145                	addi	sp,sp,48
    80002f26:	8082                	ret
    virtio_disk_rw(b, 0);
    80002f28:	4581                	li	a1,0
    80002f2a:	8526                	mv	a0,s1
    80002f2c:	00003097          	auipc	ra,0x3
    80002f30:	f0a080e7          	jalr	-246(ra) # 80005e36 <virtio_disk_rw>
    b->valid = 1;
    80002f34:	4785                	li	a5,1
    80002f36:	c09c                	sw	a5,0(s1)
  return b;
    80002f38:	b7c5                	j	80002f18 <bread+0xd0>

0000000080002f3a <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80002f3a:	1101                	addi	sp,sp,-32
    80002f3c:	ec06                	sd	ra,24(sp)
    80002f3e:	e822                	sd	s0,16(sp)
    80002f40:	e426                	sd	s1,8(sp)
    80002f42:	1000                	addi	s0,sp,32
    80002f44:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80002f46:	0541                	addi	a0,a0,16
    80002f48:	00001097          	auipc	ra,0x1
    80002f4c:	466080e7          	jalr	1126(ra) # 800043ae <holdingsleep>
    80002f50:	cd01                	beqz	a0,80002f68 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80002f52:	4585                	li	a1,1
    80002f54:	8526                	mv	a0,s1
    80002f56:	00003097          	auipc	ra,0x3
    80002f5a:	ee0080e7          	jalr	-288(ra) # 80005e36 <virtio_disk_rw>
}
    80002f5e:	60e2                	ld	ra,24(sp)
    80002f60:	6442                	ld	s0,16(sp)
    80002f62:	64a2                	ld	s1,8(sp)
    80002f64:	6105                	addi	sp,sp,32
    80002f66:	8082                	ret
    panic("bwrite");
    80002f68:	00005517          	auipc	a0,0x5
    80002f6c:	5c050513          	addi	a0,a0,1472 # 80008528 <syscalls+0xd8>
    80002f70:	ffffd097          	auipc	ra,0xffffd
    80002f74:	5ce080e7          	jalr	1486(ra) # 8000053e <panic>

0000000080002f78 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80002f78:	1101                	addi	sp,sp,-32
    80002f7a:	ec06                	sd	ra,24(sp)
    80002f7c:	e822                	sd	s0,16(sp)
    80002f7e:	e426                	sd	s1,8(sp)
    80002f80:	e04a                	sd	s2,0(sp)
    80002f82:	1000                	addi	s0,sp,32
    80002f84:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80002f86:	01050913          	addi	s2,a0,16
    80002f8a:	854a                	mv	a0,s2
    80002f8c:	00001097          	auipc	ra,0x1
    80002f90:	422080e7          	jalr	1058(ra) # 800043ae <holdingsleep>
    80002f94:	c92d                	beqz	a0,80003006 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80002f96:	854a                	mv	a0,s2
    80002f98:	00001097          	auipc	ra,0x1
    80002f9c:	3d2080e7          	jalr	978(ra) # 8000436a <releasesleep>

  acquire(&bcache.lock);
    80002fa0:	00014517          	auipc	a0,0x14
    80002fa4:	14850513          	addi	a0,a0,328 # 800170e8 <bcache>
    80002fa8:	ffffe097          	auipc	ra,0xffffe
    80002fac:	c3c080e7          	jalr	-964(ra) # 80000be4 <acquire>
  b->refcnt--;
    80002fb0:	40bc                	lw	a5,64(s1)
    80002fb2:	37fd                	addiw	a5,a5,-1
    80002fb4:	0007871b          	sext.w	a4,a5
    80002fb8:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80002fba:	eb05                	bnez	a4,80002fea <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80002fbc:	68bc                	ld	a5,80(s1)
    80002fbe:	64b8                	ld	a4,72(s1)
    80002fc0:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80002fc2:	64bc                	ld	a5,72(s1)
    80002fc4:	68b8                	ld	a4,80(s1)
    80002fc6:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80002fc8:	0001c797          	auipc	a5,0x1c
    80002fcc:	12078793          	addi	a5,a5,288 # 8001f0e8 <bcache+0x8000>
    80002fd0:	2b87b703          	ld	a4,696(a5)
    80002fd4:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80002fd6:	0001c717          	auipc	a4,0x1c
    80002fda:	37a70713          	addi	a4,a4,890 # 8001f350 <bcache+0x8268>
    80002fde:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80002fe0:	2b87b703          	ld	a4,696(a5)
    80002fe4:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80002fe6:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80002fea:	00014517          	auipc	a0,0x14
    80002fee:	0fe50513          	addi	a0,a0,254 # 800170e8 <bcache>
    80002ff2:	ffffe097          	auipc	ra,0xffffe
    80002ff6:	ca6080e7          	jalr	-858(ra) # 80000c98 <release>
}
    80002ffa:	60e2                	ld	ra,24(sp)
    80002ffc:	6442                	ld	s0,16(sp)
    80002ffe:	64a2                	ld	s1,8(sp)
    80003000:	6902                	ld	s2,0(sp)
    80003002:	6105                	addi	sp,sp,32
    80003004:	8082                	ret
    panic("brelse");
    80003006:	00005517          	auipc	a0,0x5
    8000300a:	52a50513          	addi	a0,a0,1322 # 80008530 <syscalls+0xe0>
    8000300e:	ffffd097          	auipc	ra,0xffffd
    80003012:	530080e7          	jalr	1328(ra) # 8000053e <panic>

0000000080003016 <bpin>:

void
bpin(struct buf *b) {
    80003016:	1101                	addi	sp,sp,-32
    80003018:	ec06                	sd	ra,24(sp)
    8000301a:	e822                	sd	s0,16(sp)
    8000301c:	e426                	sd	s1,8(sp)
    8000301e:	1000                	addi	s0,sp,32
    80003020:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003022:	00014517          	auipc	a0,0x14
    80003026:	0c650513          	addi	a0,a0,198 # 800170e8 <bcache>
    8000302a:	ffffe097          	auipc	ra,0xffffe
    8000302e:	bba080e7          	jalr	-1094(ra) # 80000be4 <acquire>
  b->refcnt++;
    80003032:	40bc                	lw	a5,64(s1)
    80003034:	2785                	addiw	a5,a5,1
    80003036:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003038:	00014517          	auipc	a0,0x14
    8000303c:	0b050513          	addi	a0,a0,176 # 800170e8 <bcache>
    80003040:	ffffe097          	auipc	ra,0xffffe
    80003044:	c58080e7          	jalr	-936(ra) # 80000c98 <release>
}
    80003048:	60e2                	ld	ra,24(sp)
    8000304a:	6442                	ld	s0,16(sp)
    8000304c:	64a2                	ld	s1,8(sp)
    8000304e:	6105                	addi	sp,sp,32
    80003050:	8082                	ret

0000000080003052 <bunpin>:

void
bunpin(struct buf *b) {
    80003052:	1101                	addi	sp,sp,-32
    80003054:	ec06                	sd	ra,24(sp)
    80003056:	e822                	sd	s0,16(sp)
    80003058:	e426                	sd	s1,8(sp)
    8000305a:	1000                	addi	s0,sp,32
    8000305c:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000305e:	00014517          	auipc	a0,0x14
    80003062:	08a50513          	addi	a0,a0,138 # 800170e8 <bcache>
    80003066:	ffffe097          	auipc	ra,0xffffe
    8000306a:	b7e080e7          	jalr	-1154(ra) # 80000be4 <acquire>
  b->refcnt--;
    8000306e:	40bc                	lw	a5,64(s1)
    80003070:	37fd                	addiw	a5,a5,-1
    80003072:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003074:	00014517          	auipc	a0,0x14
    80003078:	07450513          	addi	a0,a0,116 # 800170e8 <bcache>
    8000307c:	ffffe097          	auipc	ra,0xffffe
    80003080:	c1c080e7          	jalr	-996(ra) # 80000c98 <release>
}
    80003084:	60e2                	ld	ra,24(sp)
    80003086:	6442                	ld	s0,16(sp)
    80003088:	64a2                	ld	s1,8(sp)
    8000308a:	6105                	addi	sp,sp,32
    8000308c:	8082                	ret

000000008000308e <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    8000308e:	1101                	addi	sp,sp,-32
    80003090:	ec06                	sd	ra,24(sp)
    80003092:	e822                	sd	s0,16(sp)
    80003094:	e426                	sd	s1,8(sp)
    80003096:	e04a                	sd	s2,0(sp)
    80003098:	1000                	addi	s0,sp,32
    8000309a:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    8000309c:	00d5d59b          	srliw	a1,a1,0xd
    800030a0:	0001c797          	auipc	a5,0x1c
    800030a4:	7247a783          	lw	a5,1828(a5) # 8001f7c4 <sb+0x1c>
    800030a8:	9dbd                	addw	a1,a1,a5
    800030aa:	00000097          	auipc	ra,0x0
    800030ae:	d9e080e7          	jalr	-610(ra) # 80002e48 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800030b2:	0074f713          	andi	a4,s1,7
    800030b6:	4785                	li	a5,1
    800030b8:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800030bc:	14ce                	slli	s1,s1,0x33
    800030be:	90d9                	srli	s1,s1,0x36
    800030c0:	00950733          	add	a4,a0,s1
    800030c4:	05874703          	lbu	a4,88(a4)
    800030c8:	00e7f6b3          	and	a3,a5,a4
    800030cc:	c69d                	beqz	a3,800030fa <bfree+0x6c>
    800030ce:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800030d0:	94aa                	add	s1,s1,a0
    800030d2:	fff7c793          	not	a5,a5
    800030d6:	8ff9                	and	a5,a5,a4
    800030d8:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    800030dc:	00001097          	auipc	ra,0x1
    800030e0:	118080e7          	jalr	280(ra) # 800041f4 <log_write>
  brelse(bp);
    800030e4:	854a                	mv	a0,s2
    800030e6:	00000097          	auipc	ra,0x0
    800030ea:	e92080e7          	jalr	-366(ra) # 80002f78 <brelse>
}
    800030ee:	60e2                	ld	ra,24(sp)
    800030f0:	6442                	ld	s0,16(sp)
    800030f2:	64a2                	ld	s1,8(sp)
    800030f4:	6902                	ld	s2,0(sp)
    800030f6:	6105                	addi	sp,sp,32
    800030f8:	8082                	ret
    panic("freeing free block");
    800030fa:	00005517          	auipc	a0,0x5
    800030fe:	43e50513          	addi	a0,a0,1086 # 80008538 <syscalls+0xe8>
    80003102:	ffffd097          	auipc	ra,0xffffd
    80003106:	43c080e7          	jalr	1084(ra) # 8000053e <panic>

000000008000310a <balloc>:
{
    8000310a:	711d                	addi	sp,sp,-96
    8000310c:	ec86                	sd	ra,88(sp)
    8000310e:	e8a2                	sd	s0,80(sp)
    80003110:	e4a6                	sd	s1,72(sp)
    80003112:	e0ca                	sd	s2,64(sp)
    80003114:	fc4e                	sd	s3,56(sp)
    80003116:	f852                	sd	s4,48(sp)
    80003118:	f456                	sd	s5,40(sp)
    8000311a:	f05a                	sd	s6,32(sp)
    8000311c:	ec5e                	sd	s7,24(sp)
    8000311e:	e862                	sd	s8,16(sp)
    80003120:	e466                	sd	s9,8(sp)
    80003122:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003124:	0001c797          	auipc	a5,0x1c
    80003128:	6887a783          	lw	a5,1672(a5) # 8001f7ac <sb+0x4>
    8000312c:	cbd1                	beqz	a5,800031c0 <balloc+0xb6>
    8000312e:	8baa                	mv	s7,a0
    80003130:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003132:	0001cb17          	auipc	s6,0x1c
    80003136:	676b0b13          	addi	s6,s6,1654 # 8001f7a8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000313a:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    8000313c:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000313e:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003140:	6c89                	lui	s9,0x2
    80003142:	a831                	j	8000315e <balloc+0x54>
    brelse(bp);
    80003144:	854a                	mv	a0,s2
    80003146:	00000097          	auipc	ra,0x0
    8000314a:	e32080e7          	jalr	-462(ra) # 80002f78 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    8000314e:	015c87bb          	addw	a5,s9,s5
    80003152:	00078a9b          	sext.w	s5,a5
    80003156:	004b2703          	lw	a4,4(s6)
    8000315a:	06eaf363          	bgeu	s5,a4,800031c0 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    8000315e:	41fad79b          	sraiw	a5,s5,0x1f
    80003162:	0137d79b          	srliw	a5,a5,0x13
    80003166:	015787bb          	addw	a5,a5,s5
    8000316a:	40d7d79b          	sraiw	a5,a5,0xd
    8000316e:	01cb2583          	lw	a1,28(s6)
    80003172:	9dbd                	addw	a1,a1,a5
    80003174:	855e                	mv	a0,s7
    80003176:	00000097          	auipc	ra,0x0
    8000317a:	cd2080e7          	jalr	-814(ra) # 80002e48 <bread>
    8000317e:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003180:	004b2503          	lw	a0,4(s6)
    80003184:	000a849b          	sext.w	s1,s5
    80003188:	8662                	mv	a2,s8
    8000318a:	faa4fde3          	bgeu	s1,a0,80003144 <balloc+0x3a>
      m = 1 << (bi % 8);
    8000318e:	41f6579b          	sraiw	a5,a2,0x1f
    80003192:	01d7d69b          	srliw	a3,a5,0x1d
    80003196:	00c6873b          	addw	a4,a3,a2
    8000319a:	00777793          	andi	a5,a4,7
    8000319e:	9f95                	subw	a5,a5,a3
    800031a0:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800031a4:	4037571b          	sraiw	a4,a4,0x3
    800031a8:	00e906b3          	add	a3,s2,a4
    800031ac:	0586c683          	lbu	a3,88(a3)
    800031b0:	00d7f5b3          	and	a1,a5,a3
    800031b4:	cd91                	beqz	a1,800031d0 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800031b6:	2605                	addiw	a2,a2,1
    800031b8:	2485                	addiw	s1,s1,1
    800031ba:	fd4618e3          	bne	a2,s4,8000318a <balloc+0x80>
    800031be:	b759                	j	80003144 <balloc+0x3a>
  panic("balloc: out of blocks");
    800031c0:	00005517          	auipc	a0,0x5
    800031c4:	39050513          	addi	a0,a0,912 # 80008550 <syscalls+0x100>
    800031c8:	ffffd097          	auipc	ra,0xffffd
    800031cc:	376080e7          	jalr	886(ra) # 8000053e <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    800031d0:	974a                	add	a4,a4,s2
    800031d2:	8fd5                	or	a5,a5,a3
    800031d4:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    800031d8:	854a                	mv	a0,s2
    800031da:	00001097          	auipc	ra,0x1
    800031de:	01a080e7          	jalr	26(ra) # 800041f4 <log_write>
        brelse(bp);
    800031e2:	854a                	mv	a0,s2
    800031e4:	00000097          	auipc	ra,0x0
    800031e8:	d94080e7          	jalr	-620(ra) # 80002f78 <brelse>
  bp = bread(dev, bno);
    800031ec:	85a6                	mv	a1,s1
    800031ee:	855e                	mv	a0,s7
    800031f0:	00000097          	auipc	ra,0x0
    800031f4:	c58080e7          	jalr	-936(ra) # 80002e48 <bread>
    800031f8:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800031fa:	40000613          	li	a2,1024
    800031fe:	4581                	li	a1,0
    80003200:	05850513          	addi	a0,a0,88
    80003204:	ffffe097          	auipc	ra,0xffffe
    80003208:	adc080e7          	jalr	-1316(ra) # 80000ce0 <memset>
  log_write(bp);
    8000320c:	854a                	mv	a0,s2
    8000320e:	00001097          	auipc	ra,0x1
    80003212:	fe6080e7          	jalr	-26(ra) # 800041f4 <log_write>
  brelse(bp);
    80003216:	854a                	mv	a0,s2
    80003218:	00000097          	auipc	ra,0x0
    8000321c:	d60080e7          	jalr	-672(ra) # 80002f78 <brelse>
}
    80003220:	8526                	mv	a0,s1
    80003222:	60e6                	ld	ra,88(sp)
    80003224:	6446                	ld	s0,80(sp)
    80003226:	64a6                	ld	s1,72(sp)
    80003228:	6906                	ld	s2,64(sp)
    8000322a:	79e2                	ld	s3,56(sp)
    8000322c:	7a42                	ld	s4,48(sp)
    8000322e:	7aa2                	ld	s5,40(sp)
    80003230:	7b02                	ld	s6,32(sp)
    80003232:	6be2                	ld	s7,24(sp)
    80003234:	6c42                	ld	s8,16(sp)
    80003236:	6ca2                	ld	s9,8(sp)
    80003238:	6125                	addi	sp,sp,96
    8000323a:	8082                	ret

000000008000323c <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    8000323c:	7179                	addi	sp,sp,-48
    8000323e:	f406                	sd	ra,40(sp)
    80003240:	f022                	sd	s0,32(sp)
    80003242:	ec26                	sd	s1,24(sp)
    80003244:	e84a                	sd	s2,16(sp)
    80003246:	e44e                	sd	s3,8(sp)
    80003248:	e052                	sd	s4,0(sp)
    8000324a:	1800                	addi	s0,sp,48
    8000324c:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    8000324e:	47ad                	li	a5,11
    80003250:	04b7fe63          	bgeu	a5,a1,800032ac <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    80003254:	ff45849b          	addiw	s1,a1,-12
    80003258:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    8000325c:	0ff00793          	li	a5,255
    80003260:	0ae7e363          	bltu	a5,a4,80003306 <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    80003264:	08052583          	lw	a1,128(a0)
    80003268:	c5ad                	beqz	a1,800032d2 <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    8000326a:	00092503          	lw	a0,0(s2)
    8000326e:	00000097          	auipc	ra,0x0
    80003272:	bda080e7          	jalr	-1062(ra) # 80002e48 <bread>
    80003276:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003278:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    8000327c:	02049593          	slli	a1,s1,0x20
    80003280:	9181                	srli	a1,a1,0x20
    80003282:	058a                	slli	a1,a1,0x2
    80003284:	00b784b3          	add	s1,a5,a1
    80003288:	0004a983          	lw	s3,0(s1)
    8000328c:	04098d63          	beqz	s3,800032e6 <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80003290:	8552                	mv	a0,s4
    80003292:	00000097          	auipc	ra,0x0
    80003296:	ce6080e7          	jalr	-794(ra) # 80002f78 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    8000329a:	854e                	mv	a0,s3
    8000329c:	70a2                	ld	ra,40(sp)
    8000329e:	7402                	ld	s0,32(sp)
    800032a0:	64e2                	ld	s1,24(sp)
    800032a2:	6942                	ld	s2,16(sp)
    800032a4:	69a2                	ld	s3,8(sp)
    800032a6:	6a02                	ld	s4,0(sp)
    800032a8:	6145                	addi	sp,sp,48
    800032aa:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    800032ac:	02059493          	slli	s1,a1,0x20
    800032b0:	9081                	srli	s1,s1,0x20
    800032b2:	048a                	slli	s1,s1,0x2
    800032b4:	94aa                	add	s1,s1,a0
    800032b6:	0504a983          	lw	s3,80(s1)
    800032ba:	fe0990e3          	bnez	s3,8000329a <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    800032be:	4108                	lw	a0,0(a0)
    800032c0:	00000097          	auipc	ra,0x0
    800032c4:	e4a080e7          	jalr	-438(ra) # 8000310a <balloc>
    800032c8:	0005099b          	sext.w	s3,a0
    800032cc:	0534a823          	sw	s3,80(s1)
    800032d0:	b7e9                	j	8000329a <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    800032d2:	4108                	lw	a0,0(a0)
    800032d4:	00000097          	auipc	ra,0x0
    800032d8:	e36080e7          	jalr	-458(ra) # 8000310a <balloc>
    800032dc:	0005059b          	sext.w	a1,a0
    800032e0:	08b92023          	sw	a1,128(s2)
    800032e4:	b759                	j	8000326a <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    800032e6:	00092503          	lw	a0,0(s2)
    800032ea:	00000097          	auipc	ra,0x0
    800032ee:	e20080e7          	jalr	-480(ra) # 8000310a <balloc>
    800032f2:	0005099b          	sext.w	s3,a0
    800032f6:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    800032fa:	8552                	mv	a0,s4
    800032fc:	00001097          	auipc	ra,0x1
    80003300:	ef8080e7          	jalr	-264(ra) # 800041f4 <log_write>
    80003304:	b771                	j	80003290 <bmap+0x54>
  panic("bmap: out of range");
    80003306:	00005517          	auipc	a0,0x5
    8000330a:	26250513          	addi	a0,a0,610 # 80008568 <syscalls+0x118>
    8000330e:	ffffd097          	auipc	ra,0xffffd
    80003312:	230080e7          	jalr	560(ra) # 8000053e <panic>

0000000080003316 <iget>:
{
    80003316:	7179                	addi	sp,sp,-48
    80003318:	f406                	sd	ra,40(sp)
    8000331a:	f022                	sd	s0,32(sp)
    8000331c:	ec26                	sd	s1,24(sp)
    8000331e:	e84a                	sd	s2,16(sp)
    80003320:	e44e                	sd	s3,8(sp)
    80003322:	e052                	sd	s4,0(sp)
    80003324:	1800                	addi	s0,sp,48
    80003326:	89aa                	mv	s3,a0
    80003328:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    8000332a:	0001c517          	auipc	a0,0x1c
    8000332e:	49e50513          	addi	a0,a0,1182 # 8001f7c8 <itable>
    80003332:	ffffe097          	auipc	ra,0xffffe
    80003336:	8b2080e7          	jalr	-1870(ra) # 80000be4 <acquire>
  empty = 0;
    8000333a:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    8000333c:	0001c497          	auipc	s1,0x1c
    80003340:	4a448493          	addi	s1,s1,1188 # 8001f7e0 <itable+0x18>
    80003344:	0001e697          	auipc	a3,0x1e
    80003348:	f2c68693          	addi	a3,a3,-212 # 80021270 <log>
    8000334c:	a039                	j	8000335a <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000334e:	02090b63          	beqz	s2,80003384 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003352:	08848493          	addi	s1,s1,136
    80003356:	02d48a63          	beq	s1,a3,8000338a <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    8000335a:	449c                	lw	a5,8(s1)
    8000335c:	fef059e3          	blez	a5,8000334e <iget+0x38>
    80003360:	4098                	lw	a4,0(s1)
    80003362:	ff3716e3          	bne	a4,s3,8000334e <iget+0x38>
    80003366:	40d8                	lw	a4,4(s1)
    80003368:	ff4713e3          	bne	a4,s4,8000334e <iget+0x38>
      ip->ref++;
    8000336c:	2785                	addiw	a5,a5,1
    8000336e:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003370:	0001c517          	auipc	a0,0x1c
    80003374:	45850513          	addi	a0,a0,1112 # 8001f7c8 <itable>
    80003378:	ffffe097          	auipc	ra,0xffffe
    8000337c:	920080e7          	jalr	-1760(ra) # 80000c98 <release>
      return ip;
    80003380:	8926                	mv	s2,s1
    80003382:	a03d                	j	800033b0 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003384:	f7f9                	bnez	a5,80003352 <iget+0x3c>
    80003386:	8926                	mv	s2,s1
    80003388:	b7e9                	j	80003352 <iget+0x3c>
  if(empty == 0)
    8000338a:	02090c63          	beqz	s2,800033c2 <iget+0xac>
  ip->dev = dev;
    8000338e:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003392:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003396:	4785                	li	a5,1
    80003398:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    8000339c:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    800033a0:	0001c517          	auipc	a0,0x1c
    800033a4:	42850513          	addi	a0,a0,1064 # 8001f7c8 <itable>
    800033a8:	ffffe097          	auipc	ra,0xffffe
    800033ac:	8f0080e7          	jalr	-1808(ra) # 80000c98 <release>
}
    800033b0:	854a                	mv	a0,s2
    800033b2:	70a2                	ld	ra,40(sp)
    800033b4:	7402                	ld	s0,32(sp)
    800033b6:	64e2                	ld	s1,24(sp)
    800033b8:	6942                	ld	s2,16(sp)
    800033ba:	69a2                	ld	s3,8(sp)
    800033bc:	6a02                	ld	s4,0(sp)
    800033be:	6145                	addi	sp,sp,48
    800033c0:	8082                	ret
    panic("iget: no inodes");
    800033c2:	00005517          	auipc	a0,0x5
    800033c6:	1be50513          	addi	a0,a0,446 # 80008580 <syscalls+0x130>
    800033ca:	ffffd097          	auipc	ra,0xffffd
    800033ce:	174080e7          	jalr	372(ra) # 8000053e <panic>

00000000800033d2 <fsinit>:
fsinit(int dev) {
    800033d2:	7179                	addi	sp,sp,-48
    800033d4:	f406                	sd	ra,40(sp)
    800033d6:	f022                	sd	s0,32(sp)
    800033d8:	ec26                	sd	s1,24(sp)
    800033da:	e84a                	sd	s2,16(sp)
    800033dc:	e44e                	sd	s3,8(sp)
    800033de:	1800                	addi	s0,sp,48
    800033e0:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    800033e2:	4585                	li	a1,1
    800033e4:	00000097          	auipc	ra,0x0
    800033e8:	a64080e7          	jalr	-1436(ra) # 80002e48 <bread>
    800033ec:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    800033ee:	0001c997          	auipc	s3,0x1c
    800033f2:	3ba98993          	addi	s3,s3,954 # 8001f7a8 <sb>
    800033f6:	02000613          	li	a2,32
    800033fa:	05850593          	addi	a1,a0,88
    800033fe:	854e                	mv	a0,s3
    80003400:	ffffe097          	auipc	ra,0xffffe
    80003404:	940080e7          	jalr	-1728(ra) # 80000d40 <memmove>
  brelse(bp);
    80003408:	8526                	mv	a0,s1
    8000340a:	00000097          	auipc	ra,0x0
    8000340e:	b6e080e7          	jalr	-1170(ra) # 80002f78 <brelse>
  if(sb.magic != FSMAGIC)
    80003412:	0009a703          	lw	a4,0(s3)
    80003416:	102037b7          	lui	a5,0x10203
    8000341a:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    8000341e:	02f71263          	bne	a4,a5,80003442 <fsinit+0x70>
  initlog(dev, &sb);
    80003422:	0001c597          	auipc	a1,0x1c
    80003426:	38658593          	addi	a1,a1,902 # 8001f7a8 <sb>
    8000342a:	854a                	mv	a0,s2
    8000342c:	00001097          	auipc	ra,0x1
    80003430:	b4c080e7          	jalr	-1204(ra) # 80003f78 <initlog>
}
    80003434:	70a2                	ld	ra,40(sp)
    80003436:	7402                	ld	s0,32(sp)
    80003438:	64e2                	ld	s1,24(sp)
    8000343a:	6942                	ld	s2,16(sp)
    8000343c:	69a2                	ld	s3,8(sp)
    8000343e:	6145                	addi	sp,sp,48
    80003440:	8082                	ret
    panic("invalid file system");
    80003442:	00005517          	auipc	a0,0x5
    80003446:	14e50513          	addi	a0,a0,334 # 80008590 <syscalls+0x140>
    8000344a:	ffffd097          	auipc	ra,0xffffd
    8000344e:	0f4080e7          	jalr	244(ra) # 8000053e <panic>

0000000080003452 <iinit>:
{
    80003452:	7179                	addi	sp,sp,-48
    80003454:	f406                	sd	ra,40(sp)
    80003456:	f022                	sd	s0,32(sp)
    80003458:	ec26                	sd	s1,24(sp)
    8000345a:	e84a                	sd	s2,16(sp)
    8000345c:	e44e                	sd	s3,8(sp)
    8000345e:	1800                	addi	s0,sp,48
	initlock(&itable.lock, "itable");
    80003460:	00005597          	auipc	a1,0x5
    80003464:	14858593          	addi	a1,a1,328 # 800085a8 <syscalls+0x158>
    80003468:	0001c517          	auipc	a0,0x1c
    8000346c:	36050513          	addi	a0,a0,864 # 8001f7c8 <itable>
    80003470:	ffffd097          	auipc	ra,0xffffd
    80003474:	6e4080e7          	jalr	1764(ra) # 80000b54 <initlock>
	for(i = 0; i < NINODE; i++) {
    80003478:	0001c497          	auipc	s1,0x1c
    8000347c:	37848493          	addi	s1,s1,888 # 8001f7f0 <itable+0x28>
    80003480:	0001e997          	auipc	s3,0x1e
    80003484:	e0098993          	addi	s3,s3,-512 # 80021280 <log+0x10>
		initsleeplock(&itable.inode[i].lock, "inode");
    80003488:	00005917          	auipc	s2,0x5
    8000348c:	12890913          	addi	s2,s2,296 # 800085b0 <syscalls+0x160>
    80003490:	85ca                	mv	a1,s2
    80003492:	8526                	mv	a0,s1
    80003494:	00001097          	auipc	ra,0x1
    80003498:	e46080e7          	jalr	-442(ra) # 800042da <initsleeplock>
	for(i = 0; i < NINODE; i++) {
    8000349c:	08848493          	addi	s1,s1,136
    800034a0:	ff3498e3          	bne	s1,s3,80003490 <iinit+0x3e>
}
    800034a4:	70a2                	ld	ra,40(sp)
    800034a6:	7402                	ld	s0,32(sp)
    800034a8:	64e2                	ld	s1,24(sp)
    800034aa:	6942                	ld	s2,16(sp)
    800034ac:	69a2                	ld	s3,8(sp)
    800034ae:	6145                	addi	sp,sp,48
    800034b0:	8082                	ret

00000000800034b2 <ialloc>:
{
    800034b2:	715d                	addi	sp,sp,-80
    800034b4:	e486                	sd	ra,72(sp)
    800034b6:	e0a2                	sd	s0,64(sp)
    800034b8:	fc26                	sd	s1,56(sp)
    800034ba:	f84a                	sd	s2,48(sp)
    800034bc:	f44e                	sd	s3,40(sp)
    800034be:	f052                	sd	s4,32(sp)
    800034c0:	ec56                	sd	s5,24(sp)
    800034c2:	e85a                	sd	s6,16(sp)
    800034c4:	e45e                	sd	s7,8(sp)
    800034c6:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    800034c8:	0001c717          	auipc	a4,0x1c
    800034cc:	2ec72703          	lw	a4,748(a4) # 8001f7b4 <sb+0xc>
    800034d0:	4785                	li	a5,1
    800034d2:	04e7fa63          	bgeu	a5,a4,80003526 <ialloc+0x74>
    800034d6:	8aaa                	mv	s5,a0
    800034d8:	8bae                	mv	s7,a1
    800034da:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    800034dc:	0001ca17          	auipc	s4,0x1c
    800034e0:	2cca0a13          	addi	s4,s4,716 # 8001f7a8 <sb>
    800034e4:	00048b1b          	sext.w	s6,s1
    800034e8:	0044d593          	srli	a1,s1,0x4
    800034ec:	018a2783          	lw	a5,24(s4)
    800034f0:	9dbd                	addw	a1,a1,a5
    800034f2:	8556                	mv	a0,s5
    800034f4:	00000097          	auipc	ra,0x0
    800034f8:	954080e7          	jalr	-1708(ra) # 80002e48 <bread>
    800034fc:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    800034fe:	05850993          	addi	s3,a0,88
    80003502:	00f4f793          	andi	a5,s1,15
    80003506:	079a                	slli	a5,a5,0x6
    80003508:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    8000350a:	00099783          	lh	a5,0(s3)
    8000350e:	c785                	beqz	a5,80003536 <ialloc+0x84>
    brelse(bp);
    80003510:	00000097          	auipc	ra,0x0
    80003514:	a68080e7          	jalr	-1432(ra) # 80002f78 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003518:	0485                	addi	s1,s1,1
    8000351a:	00ca2703          	lw	a4,12(s4)
    8000351e:	0004879b          	sext.w	a5,s1
    80003522:	fce7e1e3          	bltu	a5,a4,800034e4 <ialloc+0x32>
  panic("ialloc: no inodes");
    80003526:	00005517          	auipc	a0,0x5
    8000352a:	09250513          	addi	a0,a0,146 # 800085b8 <syscalls+0x168>
    8000352e:	ffffd097          	auipc	ra,0xffffd
    80003532:	010080e7          	jalr	16(ra) # 8000053e <panic>
      memset(dip, 0, sizeof(*dip));
    80003536:	04000613          	li	a2,64
    8000353a:	4581                	li	a1,0
    8000353c:	854e                	mv	a0,s3
    8000353e:	ffffd097          	auipc	ra,0xffffd
    80003542:	7a2080e7          	jalr	1954(ra) # 80000ce0 <memset>
      dip->type = type;
    80003546:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    8000354a:	854a                	mv	a0,s2
    8000354c:	00001097          	auipc	ra,0x1
    80003550:	ca8080e7          	jalr	-856(ra) # 800041f4 <log_write>
      brelse(bp);
    80003554:	854a                	mv	a0,s2
    80003556:	00000097          	auipc	ra,0x0
    8000355a:	a22080e7          	jalr	-1502(ra) # 80002f78 <brelse>
      return iget(dev, inum);
    8000355e:	85da                	mv	a1,s6
    80003560:	8556                	mv	a0,s5
    80003562:	00000097          	auipc	ra,0x0
    80003566:	db4080e7          	jalr	-588(ra) # 80003316 <iget>
}
    8000356a:	60a6                	ld	ra,72(sp)
    8000356c:	6406                	ld	s0,64(sp)
    8000356e:	74e2                	ld	s1,56(sp)
    80003570:	7942                	ld	s2,48(sp)
    80003572:	79a2                	ld	s3,40(sp)
    80003574:	7a02                	ld	s4,32(sp)
    80003576:	6ae2                	ld	s5,24(sp)
    80003578:	6b42                	ld	s6,16(sp)
    8000357a:	6ba2                	ld	s7,8(sp)
    8000357c:	6161                	addi	sp,sp,80
    8000357e:	8082                	ret

0000000080003580 <iupdate>:
{
    80003580:	1101                	addi	sp,sp,-32
    80003582:	ec06                	sd	ra,24(sp)
    80003584:	e822                	sd	s0,16(sp)
    80003586:	e426                	sd	s1,8(sp)
    80003588:	e04a                	sd	s2,0(sp)
    8000358a:	1000                	addi	s0,sp,32
    8000358c:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    8000358e:	415c                	lw	a5,4(a0)
    80003590:	0047d79b          	srliw	a5,a5,0x4
    80003594:	0001c597          	auipc	a1,0x1c
    80003598:	22c5a583          	lw	a1,556(a1) # 8001f7c0 <sb+0x18>
    8000359c:	9dbd                	addw	a1,a1,a5
    8000359e:	4108                	lw	a0,0(a0)
    800035a0:	00000097          	auipc	ra,0x0
    800035a4:	8a8080e7          	jalr	-1880(ra) # 80002e48 <bread>
    800035a8:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    800035aa:	05850793          	addi	a5,a0,88
    800035ae:	40c8                	lw	a0,4(s1)
    800035b0:	893d                	andi	a0,a0,15
    800035b2:	051a                	slli	a0,a0,0x6
    800035b4:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    800035b6:	04449703          	lh	a4,68(s1)
    800035ba:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    800035be:	04649703          	lh	a4,70(s1)
    800035c2:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    800035c6:	04849703          	lh	a4,72(s1)
    800035ca:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    800035ce:	04a49703          	lh	a4,74(s1)
    800035d2:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    800035d6:	44f8                	lw	a4,76(s1)
    800035d8:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    800035da:	03400613          	li	a2,52
    800035de:	05048593          	addi	a1,s1,80
    800035e2:	0531                	addi	a0,a0,12
    800035e4:	ffffd097          	auipc	ra,0xffffd
    800035e8:	75c080e7          	jalr	1884(ra) # 80000d40 <memmove>
  log_write(bp);
    800035ec:	854a                	mv	a0,s2
    800035ee:	00001097          	auipc	ra,0x1
    800035f2:	c06080e7          	jalr	-1018(ra) # 800041f4 <log_write>
  brelse(bp);
    800035f6:	854a                	mv	a0,s2
    800035f8:	00000097          	auipc	ra,0x0
    800035fc:	980080e7          	jalr	-1664(ra) # 80002f78 <brelse>
}
    80003600:	60e2                	ld	ra,24(sp)
    80003602:	6442                	ld	s0,16(sp)
    80003604:	64a2                	ld	s1,8(sp)
    80003606:	6902                	ld	s2,0(sp)
    80003608:	6105                	addi	sp,sp,32
    8000360a:	8082                	ret

000000008000360c <idup>:
{
    8000360c:	1101                	addi	sp,sp,-32
    8000360e:	ec06                	sd	ra,24(sp)
    80003610:	e822                	sd	s0,16(sp)
    80003612:	e426                	sd	s1,8(sp)
    80003614:	1000                	addi	s0,sp,32
    80003616:	84aa                	mv	s1,a0
	acquire(&itable.lock);
    80003618:	0001c517          	auipc	a0,0x1c
    8000361c:	1b050513          	addi	a0,a0,432 # 8001f7c8 <itable>
    80003620:	ffffd097          	auipc	ra,0xffffd
    80003624:	5c4080e7          	jalr	1476(ra) # 80000be4 <acquire>
	ip->ref++;
    80003628:	449c                	lw	a5,8(s1)
    8000362a:	2785                	addiw	a5,a5,1
    8000362c:	c49c                	sw	a5,8(s1)
	release(&itable.lock);
    8000362e:	0001c517          	auipc	a0,0x1c
    80003632:	19a50513          	addi	a0,a0,410 # 8001f7c8 <itable>
    80003636:	ffffd097          	auipc	ra,0xffffd
    8000363a:	662080e7          	jalr	1634(ra) # 80000c98 <release>
}
    8000363e:	8526                	mv	a0,s1
    80003640:	60e2                	ld	ra,24(sp)
    80003642:	6442                	ld	s0,16(sp)
    80003644:	64a2                	ld	s1,8(sp)
    80003646:	6105                	addi	sp,sp,32
    80003648:	8082                	ret

000000008000364a <ilock>:
{
    8000364a:	1101                	addi	sp,sp,-32
    8000364c:	ec06                	sd	ra,24(sp)
    8000364e:	e822                	sd	s0,16(sp)
    80003650:	e426                	sd	s1,8(sp)
    80003652:	e04a                	sd	s2,0(sp)
    80003654:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003656:	c115                	beqz	a0,8000367a <ilock+0x30>
    80003658:	84aa                	mv	s1,a0
    8000365a:	451c                	lw	a5,8(a0)
    8000365c:	00f05f63          	blez	a5,8000367a <ilock+0x30>
  acquiresleep(&ip->lock);
    80003660:	0541                	addi	a0,a0,16
    80003662:	00001097          	auipc	ra,0x1
    80003666:	cb2080e7          	jalr	-846(ra) # 80004314 <acquiresleep>
  if(ip->valid == 0){
    8000366a:	40bc                	lw	a5,64(s1)
    8000366c:	cf99                	beqz	a5,8000368a <ilock+0x40>
}
    8000366e:	60e2                	ld	ra,24(sp)
    80003670:	6442                	ld	s0,16(sp)
    80003672:	64a2                	ld	s1,8(sp)
    80003674:	6902                	ld	s2,0(sp)
    80003676:	6105                	addi	sp,sp,32
    80003678:	8082                	ret
    panic("ilock");
    8000367a:	00005517          	auipc	a0,0x5
    8000367e:	f5650513          	addi	a0,a0,-170 # 800085d0 <syscalls+0x180>
    80003682:	ffffd097          	auipc	ra,0xffffd
    80003686:	ebc080e7          	jalr	-324(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    8000368a:	40dc                	lw	a5,4(s1)
    8000368c:	0047d79b          	srliw	a5,a5,0x4
    80003690:	0001c597          	auipc	a1,0x1c
    80003694:	1305a583          	lw	a1,304(a1) # 8001f7c0 <sb+0x18>
    80003698:	9dbd                	addw	a1,a1,a5
    8000369a:	4088                	lw	a0,0(s1)
    8000369c:	fffff097          	auipc	ra,0xfffff
    800036a0:	7ac080e7          	jalr	1964(ra) # 80002e48 <bread>
    800036a4:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    800036a6:	05850593          	addi	a1,a0,88
    800036aa:	40dc                	lw	a5,4(s1)
    800036ac:	8bbd                	andi	a5,a5,15
    800036ae:	079a                	slli	a5,a5,0x6
    800036b0:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    800036b2:	00059783          	lh	a5,0(a1)
    800036b6:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    800036ba:	00259783          	lh	a5,2(a1)
    800036be:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    800036c2:	00459783          	lh	a5,4(a1)
    800036c6:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    800036ca:	00659783          	lh	a5,6(a1)
    800036ce:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    800036d2:	459c                	lw	a5,8(a1)
    800036d4:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    800036d6:	03400613          	li	a2,52
    800036da:	05b1                	addi	a1,a1,12
    800036dc:	05048513          	addi	a0,s1,80
    800036e0:	ffffd097          	auipc	ra,0xffffd
    800036e4:	660080e7          	jalr	1632(ra) # 80000d40 <memmove>
    brelse(bp);
    800036e8:	854a                	mv	a0,s2
    800036ea:	00000097          	auipc	ra,0x0
    800036ee:	88e080e7          	jalr	-1906(ra) # 80002f78 <brelse>
    ip->valid = 1;
    800036f2:	4785                	li	a5,1
    800036f4:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    800036f6:	04449783          	lh	a5,68(s1)
    800036fa:	fbb5                	bnez	a5,8000366e <ilock+0x24>
      panic("ilock: no type");
    800036fc:	00005517          	auipc	a0,0x5
    80003700:	edc50513          	addi	a0,a0,-292 # 800085d8 <syscalls+0x188>
    80003704:	ffffd097          	auipc	ra,0xffffd
    80003708:	e3a080e7          	jalr	-454(ra) # 8000053e <panic>

000000008000370c <iunlock>:
{
    8000370c:	1101                	addi	sp,sp,-32
    8000370e:	ec06                	sd	ra,24(sp)
    80003710:	e822                	sd	s0,16(sp)
    80003712:	e426                	sd	s1,8(sp)
    80003714:	e04a                	sd	s2,0(sp)
    80003716:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003718:	c905                	beqz	a0,80003748 <iunlock+0x3c>
    8000371a:	84aa                	mv	s1,a0
    8000371c:	01050913          	addi	s2,a0,16
    80003720:	854a                	mv	a0,s2
    80003722:	00001097          	auipc	ra,0x1
    80003726:	c8c080e7          	jalr	-884(ra) # 800043ae <holdingsleep>
    8000372a:	cd19                	beqz	a0,80003748 <iunlock+0x3c>
    8000372c:	449c                	lw	a5,8(s1)
    8000372e:	00f05d63          	blez	a5,80003748 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003732:	854a                	mv	a0,s2
    80003734:	00001097          	auipc	ra,0x1
    80003738:	c36080e7          	jalr	-970(ra) # 8000436a <releasesleep>
}
    8000373c:	60e2                	ld	ra,24(sp)
    8000373e:	6442                	ld	s0,16(sp)
    80003740:	64a2                	ld	s1,8(sp)
    80003742:	6902                	ld	s2,0(sp)
    80003744:	6105                	addi	sp,sp,32
    80003746:	8082                	ret
    panic("iunlock");
    80003748:	00005517          	auipc	a0,0x5
    8000374c:	ea050513          	addi	a0,a0,-352 # 800085e8 <syscalls+0x198>
    80003750:	ffffd097          	auipc	ra,0xffffd
    80003754:	dee080e7          	jalr	-530(ra) # 8000053e <panic>

0000000080003758 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003758:	7179                	addi	sp,sp,-48
    8000375a:	f406                	sd	ra,40(sp)
    8000375c:	f022                	sd	s0,32(sp)
    8000375e:	ec26                	sd	s1,24(sp)
    80003760:	e84a                	sd	s2,16(sp)
    80003762:	e44e                	sd	s3,8(sp)
    80003764:	e052                	sd	s4,0(sp)
    80003766:	1800                	addi	s0,sp,48
    80003768:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    8000376a:	05050493          	addi	s1,a0,80
    8000376e:	08050913          	addi	s2,a0,128
    80003772:	a021                	j	8000377a <itrunc+0x22>
    80003774:	0491                	addi	s1,s1,4
    80003776:	01248d63          	beq	s1,s2,80003790 <itrunc+0x38>
    if(ip->addrs[i]){
    8000377a:	408c                	lw	a1,0(s1)
    8000377c:	dde5                	beqz	a1,80003774 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    8000377e:	0009a503          	lw	a0,0(s3)
    80003782:	00000097          	auipc	ra,0x0
    80003786:	90c080e7          	jalr	-1780(ra) # 8000308e <bfree>
      ip->addrs[i] = 0;
    8000378a:	0004a023          	sw	zero,0(s1)
    8000378e:	b7dd                	j	80003774 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003790:	0809a583          	lw	a1,128(s3)
    80003794:	e185                	bnez	a1,800037b4 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003796:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    8000379a:	854e                	mv	a0,s3
    8000379c:	00000097          	auipc	ra,0x0
    800037a0:	de4080e7          	jalr	-540(ra) # 80003580 <iupdate>
}
    800037a4:	70a2                	ld	ra,40(sp)
    800037a6:	7402                	ld	s0,32(sp)
    800037a8:	64e2                	ld	s1,24(sp)
    800037aa:	6942                	ld	s2,16(sp)
    800037ac:	69a2                	ld	s3,8(sp)
    800037ae:	6a02                	ld	s4,0(sp)
    800037b0:	6145                	addi	sp,sp,48
    800037b2:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    800037b4:	0009a503          	lw	a0,0(s3)
    800037b8:	fffff097          	auipc	ra,0xfffff
    800037bc:	690080e7          	jalr	1680(ra) # 80002e48 <bread>
    800037c0:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    800037c2:	05850493          	addi	s1,a0,88
    800037c6:	45850913          	addi	s2,a0,1112
    800037ca:	a811                	j	800037de <itrunc+0x86>
        bfree(ip->dev, a[j]);
    800037cc:	0009a503          	lw	a0,0(s3)
    800037d0:	00000097          	auipc	ra,0x0
    800037d4:	8be080e7          	jalr	-1858(ra) # 8000308e <bfree>
    for(j = 0; j < NINDIRECT; j++){
    800037d8:	0491                	addi	s1,s1,4
    800037da:	01248563          	beq	s1,s2,800037e4 <itrunc+0x8c>
      if(a[j])
    800037de:	408c                	lw	a1,0(s1)
    800037e0:	dde5                	beqz	a1,800037d8 <itrunc+0x80>
    800037e2:	b7ed                	j	800037cc <itrunc+0x74>
    brelse(bp);
    800037e4:	8552                	mv	a0,s4
    800037e6:	fffff097          	auipc	ra,0xfffff
    800037ea:	792080e7          	jalr	1938(ra) # 80002f78 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    800037ee:	0809a583          	lw	a1,128(s3)
    800037f2:	0009a503          	lw	a0,0(s3)
    800037f6:	00000097          	auipc	ra,0x0
    800037fa:	898080e7          	jalr	-1896(ra) # 8000308e <bfree>
    ip->addrs[NDIRECT] = 0;
    800037fe:	0809a023          	sw	zero,128(s3)
    80003802:	bf51                	j	80003796 <itrunc+0x3e>

0000000080003804 <iput>:
{
    80003804:	1101                	addi	sp,sp,-32
    80003806:	ec06                	sd	ra,24(sp)
    80003808:	e822                	sd	s0,16(sp)
    8000380a:	e426                	sd	s1,8(sp)
    8000380c:	e04a                	sd	s2,0(sp)
    8000380e:	1000                	addi	s0,sp,32
    80003810:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003812:	0001c517          	auipc	a0,0x1c
    80003816:	fb650513          	addi	a0,a0,-74 # 8001f7c8 <itable>
    8000381a:	ffffd097          	auipc	ra,0xffffd
    8000381e:	3ca080e7          	jalr	970(ra) # 80000be4 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003822:	4498                	lw	a4,8(s1)
    80003824:	4785                	li	a5,1
    80003826:	02f70363          	beq	a4,a5,8000384c <iput+0x48>
  ip->ref--;
    8000382a:	449c                	lw	a5,8(s1)
    8000382c:	37fd                	addiw	a5,a5,-1
    8000382e:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003830:	0001c517          	auipc	a0,0x1c
    80003834:	f9850513          	addi	a0,a0,-104 # 8001f7c8 <itable>
    80003838:	ffffd097          	auipc	ra,0xffffd
    8000383c:	460080e7          	jalr	1120(ra) # 80000c98 <release>
}
    80003840:	60e2                	ld	ra,24(sp)
    80003842:	6442                	ld	s0,16(sp)
    80003844:	64a2                	ld	s1,8(sp)
    80003846:	6902                	ld	s2,0(sp)
    80003848:	6105                	addi	sp,sp,32
    8000384a:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    8000384c:	40bc                	lw	a5,64(s1)
    8000384e:	dff1                	beqz	a5,8000382a <iput+0x26>
    80003850:	04a49783          	lh	a5,74(s1)
    80003854:	fbf9                	bnez	a5,8000382a <iput+0x26>
    acquiresleep(&ip->lock);
    80003856:	01048913          	addi	s2,s1,16
    8000385a:	854a                	mv	a0,s2
    8000385c:	00001097          	auipc	ra,0x1
    80003860:	ab8080e7          	jalr	-1352(ra) # 80004314 <acquiresleep>
    release(&itable.lock);
    80003864:	0001c517          	auipc	a0,0x1c
    80003868:	f6450513          	addi	a0,a0,-156 # 8001f7c8 <itable>
    8000386c:	ffffd097          	auipc	ra,0xffffd
    80003870:	42c080e7          	jalr	1068(ra) # 80000c98 <release>
    itrunc(ip);
    80003874:	8526                	mv	a0,s1
    80003876:	00000097          	auipc	ra,0x0
    8000387a:	ee2080e7          	jalr	-286(ra) # 80003758 <itrunc>
    ip->type = 0;
    8000387e:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003882:	8526                	mv	a0,s1
    80003884:	00000097          	auipc	ra,0x0
    80003888:	cfc080e7          	jalr	-772(ra) # 80003580 <iupdate>
    ip->valid = 0;
    8000388c:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003890:	854a                	mv	a0,s2
    80003892:	00001097          	auipc	ra,0x1
    80003896:	ad8080e7          	jalr	-1320(ra) # 8000436a <releasesleep>
    acquire(&itable.lock);
    8000389a:	0001c517          	auipc	a0,0x1c
    8000389e:	f2e50513          	addi	a0,a0,-210 # 8001f7c8 <itable>
    800038a2:	ffffd097          	auipc	ra,0xffffd
    800038a6:	342080e7          	jalr	834(ra) # 80000be4 <acquire>
    800038aa:	b741                	j	8000382a <iput+0x26>

00000000800038ac <iunlockput>:
{
    800038ac:	1101                	addi	sp,sp,-32
    800038ae:	ec06                	sd	ra,24(sp)
    800038b0:	e822                	sd	s0,16(sp)
    800038b2:	e426                	sd	s1,8(sp)
    800038b4:	1000                	addi	s0,sp,32
    800038b6:	84aa                	mv	s1,a0
	iunlock(ip);
    800038b8:	00000097          	auipc	ra,0x0
    800038bc:	e54080e7          	jalr	-428(ra) # 8000370c <iunlock>
	iput(ip);
    800038c0:	8526                	mv	a0,s1
    800038c2:	00000097          	auipc	ra,0x0
    800038c6:	f42080e7          	jalr	-190(ra) # 80003804 <iput>
}
    800038ca:	60e2                	ld	ra,24(sp)
    800038cc:	6442                	ld	s0,16(sp)
    800038ce:	64a2                	ld	s1,8(sp)
    800038d0:	6105                	addi	sp,sp,32
    800038d2:	8082                	ret

00000000800038d4 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    800038d4:	1141                	addi	sp,sp,-16
    800038d6:	e422                	sd	s0,8(sp)
    800038d8:	0800                	addi	s0,sp,16
	st->dev = ip->dev;
    800038da:	411c                	lw	a5,0(a0)
    800038dc:	c19c                	sw	a5,0(a1)
	st->ino = ip->inum;
    800038de:	415c                	lw	a5,4(a0)
    800038e0:	c1dc                	sw	a5,4(a1)
	st->type = ip->type;
    800038e2:	04451783          	lh	a5,68(a0)
    800038e6:	00f59423          	sh	a5,8(a1)
	st->nlink = ip->nlink;
    800038ea:	04a51783          	lh	a5,74(a0)
    800038ee:	00f59523          	sh	a5,10(a1)
	st->size = ip->size;
    800038f2:	04c56783          	lwu	a5,76(a0)
    800038f6:	e99c                	sd	a5,16(a1)
}
    800038f8:	6422                	ld	s0,8(sp)
    800038fa:	0141                	addi	sp,sp,16
    800038fc:	8082                	ret

00000000800038fe <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    800038fe:	457c                	lw	a5,76(a0)
    80003900:	0ed7e963          	bltu	a5,a3,800039f2 <readi+0xf4>
{
    80003904:	7159                	addi	sp,sp,-112
    80003906:	f486                	sd	ra,104(sp)
    80003908:	f0a2                	sd	s0,96(sp)
    8000390a:	eca6                	sd	s1,88(sp)
    8000390c:	e8ca                	sd	s2,80(sp)
    8000390e:	e4ce                	sd	s3,72(sp)
    80003910:	e0d2                	sd	s4,64(sp)
    80003912:	fc56                	sd	s5,56(sp)
    80003914:	f85a                	sd	s6,48(sp)
    80003916:	f45e                	sd	s7,40(sp)
    80003918:	f062                	sd	s8,32(sp)
    8000391a:	ec66                	sd	s9,24(sp)
    8000391c:	e86a                	sd	s10,16(sp)
    8000391e:	e46e                	sd	s11,8(sp)
    80003920:	1880                	addi	s0,sp,112
    80003922:	8baa                	mv	s7,a0
    80003924:	8c2e                	mv	s8,a1
    80003926:	8ab2                	mv	s5,a2
    80003928:	84b6                	mv	s1,a3
    8000392a:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    8000392c:	9f35                	addw	a4,a4,a3
    return 0;
    8000392e:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003930:	0ad76063          	bltu	a4,a3,800039d0 <readi+0xd2>
  if(off + n > ip->size)
    80003934:	00e7f463          	bgeu	a5,a4,8000393c <readi+0x3e>
    n = ip->size - off;
    80003938:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    8000393c:	0a0b0963          	beqz	s6,800039ee <readi+0xf0>
    80003940:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003942:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003946:	5cfd                	li	s9,-1
    80003948:	a82d                	j	80003982 <readi+0x84>
    8000394a:	020a1d93          	slli	s11,s4,0x20
    8000394e:	020ddd93          	srli	s11,s11,0x20
    80003952:	05890613          	addi	a2,s2,88
    80003956:	86ee                	mv	a3,s11
    80003958:	963a                	add	a2,a2,a4
    8000395a:	85d6                	mv	a1,s5
    8000395c:	8562                	mv	a0,s8
    8000395e:	fffff097          	auipc	ra,0xfffff
    80003962:	b2e080e7          	jalr	-1234(ra) # 8000248c <either_copyout>
    80003966:	05950d63          	beq	a0,s9,800039c0 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    8000396a:	854a                	mv	a0,s2
    8000396c:	fffff097          	auipc	ra,0xfffff
    80003970:	60c080e7          	jalr	1548(ra) # 80002f78 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003974:	013a09bb          	addw	s3,s4,s3
    80003978:	009a04bb          	addw	s1,s4,s1
    8000397c:	9aee                	add	s5,s5,s11
    8000397e:	0569f763          	bgeu	s3,s6,800039cc <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003982:	000ba903          	lw	s2,0(s7)
    80003986:	00a4d59b          	srliw	a1,s1,0xa
    8000398a:	855e                	mv	a0,s7
    8000398c:	00000097          	auipc	ra,0x0
    80003990:	8b0080e7          	jalr	-1872(ra) # 8000323c <bmap>
    80003994:	0005059b          	sext.w	a1,a0
    80003998:	854a                	mv	a0,s2
    8000399a:	fffff097          	auipc	ra,0xfffff
    8000399e:	4ae080e7          	jalr	1198(ra) # 80002e48 <bread>
    800039a2:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    800039a4:	3ff4f713          	andi	a4,s1,1023
    800039a8:	40ed07bb          	subw	a5,s10,a4
    800039ac:	413b06bb          	subw	a3,s6,s3
    800039b0:	8a3e                	mv	s4,a5
    800039b2:	2781                	sext.w	a5,a5
    800039b4:	0006861b          	sext.w	a2,a3
    800039b8:	f8f679e3          	bgeu	a2,a5,8000394a <readi+0x4c>
    800039bc:	8a36                	mv	s4,a3
    800039be:	b771                	j	8000394a <readi+0x4c>
      brelse(bp);
    800039c0:	854a                	mv	a0,s2
    800039c2:	fffff097          	auipc	ra,0xfffff
    800039c6:	5b6080e7          	jalr	1462(ra) # 80002f78 <brelse>
      tot = -1;
    800039ca:	59fd                	li	s3,-1
  }
  return tot;
    800039cc:	0009851b          	sext.w	a0,s3
}
    800039d0:	70a6                	ld	ra,104(sp)
    800039d2:	7406                	ld	s0,96(sp)
    800039d4:	64e6                	ld	s1,88(sp)
    800039d6:	6946                	ld	s2,80(sp)
    800039d8:	69a6                	ld	s3,72(sp)
    800039da:	6a06                	ld	s4,64(sp)
    800039dc:	7ae2                	ld	s5,56(sp)
    800039de:	7b42                	ld	s6,48(sp)
    800039e0:	7ba2                	ld	s7,40(sp)
    800039e2:	7c02                	ld	s8,32(sp)
    800039e4:	6ce2                	ld	s9,24(sp)
    800039e6:	6d42                	ld	s10,16(sp)
    800039e8:	6da2                	ld	s11,8(sp)
    800039ea:	6165                	addi	sp,sp,112
    800039ec:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800039ee:	89da                	mv	s3,s6
    800039f0:	bff1                	j	800039cc <readi+0xce>
    return 0;
    800039f2:	4501                	li	a0,0
}
    800039f4:	8082                	ret

00000000800039f6 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    800039f6:	457c                	lw	a5,76(a0)
    800039f8:	10d7e863          	bltu	a5,a3,80003b08 <writei+0x112>
{
    800039fc:	7159                	addi	sp,sp,-112
    800039fe:	f486                	sd	ra,104(sp)
    80003a00:	f0a2                	sd	s0,96(sp)
    80003a02:	eca6                	sd	s1,88(sp)
    80003a04:	e8ca                	sd	s2,80(sp)
    80003a06:	e4ce                	sd	s3,72(sp)
    80003a08:	e0d2                	sd	s4,64(sp)
    80003a0a:	fc56                	sd	s5,56(sp)
    80003a0c:	f85a                	sd	s6,48(sp)
    80003a0e:	f45e                	sd	s7,40(sp)
    80003a10:	f062                	sd	s8,32(sp)
    80003a12:	ec66                	sd	s9,24(sp)
    80003a14:	e86a                	sd	s10,16(sp)
    80003a16:	e46e                	sd	s11,8(sp)
    80003a18:	1880                	addi	s0,sp,112
    80003a1a:	8b2a                	mv	s6,a0
    80003a1c:	8c2e                	mv	s8,a1
    80003a1e:	8ab2                	mv	s5,a2
    80003a20:	8936                	mv	s2,a3
    80003a22:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    80003a24:	00e687bb          	addw	a5,a3,a4
    80003a28:	0ed7e263          	bltu	a5,a3,80003b0c <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003a2c:	00043737          	lui	a4,0x43
    80003a30:	0ef76063          	bltu	a4,a5,80003b10 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003a34:	0c0b8863          	beqz	s7,80003b04 <writei+0x10e>
    80003a38:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003a3a:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003a3e:	5cfd                	li	s9,-1
    80003a40:	a091                	j	80003a84 <writei+0x8e>
    80003a42:	02099d93          	slli	s11,s3,0x20
    80003a46:	020ddd93          	srli	s11,s11,0x20
    80003a4a:	05848513          	addi	a0,s1,88
    80003a4e:	86ee                	mv	a3,s11
    80003a50:	8656                	mv	a2,s5
    80003a52:	85e2                	mv	a1,s8
    80003a54:	953a                	add	a0,a0,a4
    80003a56:	fffff097          	auipc	ra,0xfffff
    80003a5a:	a8c080e7          	jalr	-1396(ra) # 800024e2 <either_copyin>
    80003a5e:	07950263          	beq	a0,s9,80003ac2 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003a62:	8526                	mv	a0,s1
    80003a64:	00000097          	auipc	ra,0x0
    80003a68:	790080e7          	jalr	1936(ra) # 800041f4 <log_write>
    brelse(bp);
    80003a6c:	8526                	mv	a0,s1
    80003a6e:	fffff097          	auipc	ra,0xfffff
    80003a72:	50a080e7          	jalr	1290(ra) # 80002f78 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003a76:	01498a3b          	addw	s4,s3,s4
    80003a7a:	0129893b          	addw	s2,s3,s2
    80003a7e:	9aee                	add	s5,s5,s11
    80003a80:	057a7663          	bgeu	s4,s7,80003acc <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003a84:	000b2483          	lw	s1,0(s6)
    80003a88:	00a9559b          	srliw	a1,s2,0xa
    80003a8c:	855a                	mv	a0,s6
    80003a8e:	fffff097          	auipc	ra,0xfffff
    80003a92:	7ae080e7          	jalr	1966(ra) # 8000323c <bmap>
    80003a96:	0005059b          	sext.w	a1,a0
    80003a9a:	8526                	mv	a0,s1
    80003a9c:	fffff097          	auipc	ra,0xfffff
    80003aa0:	3ac080e7          	jalr	940(ra) # 80002e48 <bread>
    80003aa4:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003aa6:	3ff97713          	andi	a4,s2,1023
    80003aaa:	40ed07bb          	subw	a5,s10,a4
    80003aae:	414b86bb          	subw	a3,s7,s4
    80003ab2:	89be                	mv	s3,a5
    80003ab4:	2781                	sext.w	a5,a5
    80003ab6:	0006861b          	sext.w	a2,a3
    80003aba:	f8f674e3          	bgeu	a2,a5,80003a42 <writei+0x4c>
    80003abe:	89b6                	mv	s3,a3
    80003ac0:	b749                	j	80003a42 <writei+0x4c>
      brelse(bp);
    80003ac2:	8526                	mv	a0,s1
    80003ac4:	fffff097          	auipc	ra,0xfffff
    80003ac8:	4b4080e7          	jalr	1204(ra) # 80002f78 <brelse>
  }

  if(off > ip->size)
    80003acc:	04cb2783          	lw	a5,76(s6)
    80003ad0:	0127f463          	bgeu	a5,s2,80003ad8 <writei+0xe2>
    ip->size = off;
    80003ad4:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003ad8:	855a                	mv	a0,s6
    80003ada:	00000097          	auipc	ra,0x0
    80003ade:	aa6080e7          	jalr	-1370(ra) # 80003580 <iupdate>

  return tot;
    80003ae2:	000a051b          	sext.w	a0,s4
}
    80003ae6:	70a6                	ld	ra,104(sp)
    80003ae8:	7406                	ld	s0,96(sp)
    80003aea:	64e6                	ld	s1,88(sp)
    80003aec:	6946                	ld	s2,80(sp)
    80003aee:	69a6                	ld	s3,72(sp)
    80003af0:	6a06                	ld	s4,64(sp)
    80003af2:	7ae2                	ld	s5,56(sp)
    80003af4:	7b42                	ld	s6,48(sp)
    80003af6:	7ba2                	ld	s7,40(sp)
    80003af8:	7c02                	ld	s8,32(sp)
    80003afa:	6ce2                	ld	s9,24(sp)
    80003afc:	6d42                	ld	s10,16(sp)
    80003afe:	6da2                	ld	s11,8(sp)
    80003b00:	6165                	addi	sp,sp,112
    80003b02:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003b04:	8a5e                	mv	s4,s7
    80003b06:	bfc9                	j	80003ad8 <writei+0xe2>
    return -1;
    80003b08:	557d                	li	a0,-1
}
    80003b0a:	8082                	ret
    return -1;
    80003b0c:	557d                	li	a0,-1
    80003b0e:	bfe1                	j	80003ae6 <writei+0xf0>
    return -1;
    80003b10:	557d                	li	a0,-1
    80003b12:	bfd1                	j	80003ae6 <writei+0xf0>

0000000080003b14 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003b14:	1141                	addi	sp,sp,-16
    80003b16:	e406                	sd	ra,8(sp)
    80003b18:	e022                	sd	s0,0(sp)
    80003b1a:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003b1c:	4639                	li	a2,14
    80003b1e:	ffffd097          	auipc	ra,0xffffd
    80003b22:	29a080e7          	jalr	666(ra) # 80000db8 <strncmp>
}
    80003b26:	60a2                	ld	ra,8(sp)
    80003b28:	6402                	ld	s0,0(sp)
    80003b2a:	0141                	addi	sp,sp,16
    80003b2c:	8082                	ret

0000000080003b2e <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003b2e:	7139                	addi	sp,sp,-64
    80003b30:	fc06                	sd	ra,56(sp)
    80003b32:	f822                	sd	s0,48(sp)
    80003b34:	f426                	sd	s1,40(sp)
    80003b36:	f04a                	sd	s2,32(sp)
    80003b38:	ec4e                	sd	s3,24(sp)
    80003b3a:	e852                	sd	s4,16(sp)
    80003b3c:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003b3e:	04451703          	lh	a4,68(a0)
    80003b42:	4785                	li	a5,1
    80003b44:	00f71a63          	bne	a4,a5,80003b58 <dirlookup+0x2a>
    80003b48:	892a                	mv	s2,a0
    80003b4a:	89ae                	mv	s3,a1
    80003b4c:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003b4e:	457c                	lw	a5,76(a0)
    80003b50:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003b52:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003b54:	e79d                	bnez	a5,80003b82 <dirlookup+0x54>
    80003b56:	a8a5                	j	80003bce <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003b58:	00005517          	auipc	a0,0x5
    80003b5c:	a9850513          	addi	a0,a0,-1384 # 800085f0 <syscalls+0x1a0>
    80003b60:	ffffd097          	auipc	ra,0xffffd
    80003b64:	9de080e7          	jalr	-1570(ra) # 8000053e <panic>
      panic("dirlookup read");
    80003b68:	00005517          	auipc	a0,0x5
    80003b6c:	aa050513          	addi	a0,a0,-1376 # 80008608 <syscalls+0x1b8>
    80003b70:	ffffd097          	auipc	ra,0xffffd
    80003b74:	9ce080e7          	jalr	-1586(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003b78:	24c1                	addiw	s1,s1,16
    80003b7a:	04c92783          	lw	a5,76(s2)
    80003b7e:	04f4f763          	bgeu	s1,a5,80003bcc <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003b82:	4741                	li	a4,16
    80003b84:	86a6                	mv	a3,s1
    80003b86:	fc040613          	addi	a2,s0,-64
    80003b8a:	4581                	li	a1,0
    80003b8c:	854a                	mv	a0,s2
    80003b8e:	00000097          	auipc	ra,0x0
    80003b92:	d70080e7          	jalr	-656(ra) # 800038fe <readi>
    80003b96:	47c1                	li	a5,16
    80003b98:	fcf518e3          	bne	a0,a5,80003b68 <dirlookup+0x3a>
    if(de.inum == 0)
    80003b9c:	fc045783          	lhu	a5,-64(s0)
    80003ba0:	dfe1                	beqz	a5,80003b78 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003ba2:	fc240593          	addi	a1,s0,-62
    80003ba6:	854e                	mv	a0,s3
    80003ba8:	00000097          	auipc	ra,0x0
    80003bac:	f6c080e7          	jalr	-148(ra) # 80003b14 <namecmp>
    80003bb0:	f561                	bnez	a0,80003b78 <dirlookup+0x4a>
      if(poff)
    80003bb2:	000a0463          	beqz	s4,80003bba <dirlookup+0x8c>
        *poff = off;
    80003bb6:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003bba:	fc045583          	lhu	a1,-64(s0)
    80003bbe:	00092503          	lw	a0,0(s2)
    80003bc2:	fffff097          	auipc	ra,0xfffff
    80003bc6:	754080e7          	jalr	1876(ra) # 80003316 <iget>
    80003bca:	a011                	j	80003bce <dirlookup+0xa0>
  return 0;
    80003bcc:	4501                	li	a0,0
}
    80003bce:	70e2                	ld	ra,56(sp)
    80003bd0:	7442                	ld	s0,48(sp)
    80003bd2:	74a2                	ld	s1,40(sp)
    80003bd4:	7902                	ld	s2,32(sp)
    80003bd6:	69e2                	ld	s3,24(sp)
    80003bd8:	6a42                	ld	s4,16(sp)
    80003bda:	6121                	addi	sp,sp,64
    80003bdc:	8082                	ret

0000000080003bde <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003bde:	711d                	addi	sp,sp,-96
    80003be0:	ec86                	sd	ra,88(sp)
    80003be2:	e8a2                	sd	s0,80(sp)
    80003be4:	e4a6                	sd	s1,72(sp)
    80003be6:	e0ca                	sd	s2,64(sp)
    80003be8:	fc4e                	sd	s3,56(sp)
    80003bea:	f852                	sd	s4,48(sp)
    80003bec:	f456                	sd	s5,40(sp)
    80003bee:	f05a                	sd	s6,32(sp)
    80003bf0:	ec5e                	sd	s7,24(sp)
    80003bf2:	e862                	sd	s8,16(sp)
    80003bf4:	e466                	sd	s9,8(sp)
    80003bf6:	1080                	addi	s0,sp,96
    80003bf8:	84aa                	mv	s1,a0
    80003bfa:	8b2e                	mv	s6,a1
    80003bfc:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003bfe:	00054703          	lbu	a4,0(a0)
    80003c02:	02f00793          	li	a5,47
    80003c06:	02f70363          	beq	a4,a5,80003c2c <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003c0a:	ffffe097          	auipc	ra,0xffffe
    80003c0e:	e22080e7          	jalr	-478(ra) # 80001a2c <myproc>
    80003c12:	15053503          	ld	a0,336(a0)
    80003c16:	00000097          	auipc	ra,0x0
    80003c1a:	9f6080e7          	jalr	-1546(ra) # 8000360c <idup>
    80003c1e:	89aa                	mv	s3,a0
  while(*path == '/')
    80003c20:	02f00913          	li	s2,47
  len = path - s;
    80003c24:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80003c26:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003c28:	4c05                	li	s8,1
    80003c2a:	a865                	j	80003ce2 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003c2c:	4585                	li	a1,1
    80003c2e:	4505                	li	a0,1
    80003c30:	fffff097          	auipc	ra,0xfffff
    80003c34:	6e6080e7          	jalr	1766(ra) # 80003316 <iget>
    80003c38:	89aa                	mv	s3,a0
    80003c3a:	b7dd                	j	80003c20 <namex+0x42>
      iunlockput(ip);
    80003c3c:	854e                	mv	a0,s3
    80003c3e:	00000097          	auipc	ra,0x0
    80003c42:	c6e080e7          	jalr	-914(ra) # 800038ac <iunlockput>
      return 0;
    80003c46:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003c48:	854e                	mv	a0,s3
    80003c4a:	60e6                	ld	ra,88(sp)
    80003c4c:	6446                	ld	s0,80(sp)
    80003c4e:	64a6                	ld	s1,72(sp)
    80003c50:	6906                	ld	s2,64(sp)
    80003c52:	79e2                	ld	s3,56(sp)
    80003c54:	7a42                	ld	s4,48(sp)
    80003c56:	7aa2                	ld	s5,40(sp)
    80003c58:	7b02                	ld	s6,32(sp)
    80003c5a:	6be2                	ld	s7,24(sp)
    80003c5c:	6c42                	ld	s8,16(sp)
    80003c5e:	6ca2                	ld	s9,8(sp)
    80003c60:	6125                	addi	sp,sp,96
    80003c62:	8082                	ret
      iunlock(ip);
    80003c64:	854e                	mv	a0,s3
    80003c66:	00000097          	auipc	ra,0x0
    80003c6a:	aa6080e7          	jalr	-1370(ra) # 8000370c <iunlock>
      return ip;
    80003c6e:	bfe9                	j	80003c48 <namex+0x6a>
      iunlockput(ip);
    80003c70:	854e                	mv	a0,s3
    80003c72:	00000097          	auipc	ra,0x0
    80003c76:	c3a080e7          	jalr	-966(ra) # 800038ac <iunlockput>
      return 0;
    80003c7a:	89d2                	mv	s3,s4
    80003c7c:	b7f1                	j	80003c48 <namex+0x6a>
  len = path - s;
    80003c7e:	40b48633          	sub	a2,s1,a1
    80003c82:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80003c86:	094cd463          	bge	s9,s4,80003d0e <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003c8a:	4639                	li	a2,14
    80003c8c:	8556                	mv	a0,s5
    80003c8e:	ffffd097          	auipc	ra,0xffffd
    80003c92:	0b2080e7          	jalr	178(ra) # 80000d40 <memmove>
  while(*path == '/')
    80003c96:	0004c783          	lbu	a5,0(s1)
    80003c9a:	01279763          	bne	a5,s2,80003ca8 <namex+0xca>
    path++;
    80003c9e:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003ca0:	0004c783          	lbu	a5,0(s1)
    80003ca4:	ff278de3          	beq	a5,s2,80003c9e <namex+0xc0>
    ilock(ip);
    80003ca8:	854e                	mv	a0,s3
    80003caa:	00000097          	auipc	ra,0x0
    80003cae:	9a0080e7          	jalr	-1632(ra) # 8000364a <ilock>
    if(ip->type != T_DIR){
    80003cb2:	04499783          	lh	a5,68(s3)
    80003cb6:	f98793e3          	bne	a5,s8,80003c3c <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003cba:	000b0563          	beqz	s6,80003cc4 <namex+0xe6>
    80003cbe:	0004c783          	lbu	a5,0(s1)
    80003cc2:	d3cd                	beqz	a5,80003c64 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003cc4:	865e                	mv	a2,s7
    80003cc6:	85d6                	mv	a1,s5
    80003cc8:	854e                	mv	a0,s3
    80003cca:	00000097          	auipc	ra,0x0
    80003cce:	e64080e7          	jalr	-412(ra) # 80003b2e <dirlookup>
    80003cd2:	8a2a                	mv	s4,a0
    80003cd4:	dd51                	beqz	a0,80003c70 <namex+0x92>
    iunlockput(ip);
    80003cd6:	854e                	mv	a0,s3
    80003cd8:	00000097          	auipc	ra,0x0
    80003cdc:	bd4080e7          	jalr	-1068(ra) # 800038ac <iunlockput>
    ip = next;
    80003ce0:	89d2                	mv	s3,s4
  while(*path == '/')
    80003ce2:	0004c783          	lbu	a5,0(s1)
    80003ce6:	05279763          	bne	a5,s2,80003d34 <namex+0x156>
    path++;
    80003cea:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003cec:	0004c783          	lbu	a5,0(s1)
    80003cf0:	ff278de3          	beq	a5,s2,80003cea <namex+0x10c>
  if(*path == 0)
    80003cf4:	c79d                	beqz	a5,80003d22 <namex+0x144>
    path++;
    80003cf6:	85a6                	mv	a1,s1
  len = path - s;
    80003cf8:	8a5e                	mv	s4,s7
    80003cfa:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80003cfc:	01278963          	beq	a5,s2,80003d0e <namex+0x130>
    80003d00:	dfbd                	beqz	a5,80003c7e <namex+0xa0>
    path++;
    80003d02:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003d04:	0004c783          	lbu	a5,0(s1)
    80003d08:	ff279ce3          	bne	a5,s2,80003d00 <namex+0x122>
    80003d0c:	bf8d                	j	80003c7e <namex+0xa0>
    memmove(name, s, len);
    80003d0e:	2601                	sext.w	a2,a2
    80003d10:	8556                	mv	a0,s5
    80003d12:	ffffd097          	auipc	ra,0xffffd
    80003d16:	02e080e7          	jalr	46(ra) # 80000d40 <memmove>
    name[len] = 0;
    80003d1a:	9a56                	add	s4,s4,s5
    80003d1c:	000a0023          	sb	zero,0(s4)
    80003d20:	bf9d                	j	80003c96 <namex+0xb8>
  if(nameiparent){
    80003d22:	f20b03e3          	beqz	s6,80003c48 <namex+0x6a>
    iput(ip);
    80003d26:	854e                	mv	a0,s3
    80003d28:	00000097          	auipc	ra,0x0
    80003d2c:	adc080e7          	jalr	-1316(ra) # 80003804 <iput>
    return 0;
    80003d30:	4981                	li	s3,0
    80003d32:	bf19                	j	80003c48 <namex+0x6a>
  if(*path == 0)
    80003d34:	d7fd                	beqz	a5,80003d22 <namex+0x144>
  while(*path != '/' && *path != 0)
    80003d36:	0004c783          	lbu	a5,0(s1)
    80003d3a:	85a6                	mv	a1,s1
    80003d3c:	b7d1                	j	80003d00 <namex+0x122>

0000000080003d3e <dirlink>:
{
    80003d3e:	7139                	addi	sp,sp,-64
    80003d40:	fc06                	sd	ra,56(sp)
    80003d42:	f822                	sd	s0,48(sp)
    80003d44:	f426                	sd	s1,40(sp)
    80003d46:	f04a                	sd	s2,32(sp)
    80003d48:	ec4e                	sd	s3,24(sp)
    80003d4a:	e852                	sd	s4,16(sp)
    80003d4c:	0080                	addi	s0,sp,64
    80003d4e:	892a                	mv	s2,a0
    80003d50:	8a2e                	mv	s4,a1
    80003d52:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003d54:	4601                	li	a2,0
    80003d56:	00000097          	auipc	ra,0x0
    80003d5a:	dd8080e7          	jalr	-552(ra) # 80003b2e <dirlookup>
    80003d5e:	e93d                	bnez	a0,80003dd4 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d60:	04c92483          	lw	s1,76(s2)
    80003d64:	c49d                	beqz	s1,80003d92 <dirlink+0x54>
    80003d66:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003d68:	4741                	li	a4,16
    80003d6a:	86a6                	mv	a3,s1
    80003d6c:	fc040613          	addi	a2,s0,-64
    80003d70:	4581                	li	a1,0
    80003d72:	854a                	mv	a0,s2
    80003d74:	00000097          	auipc	ra,0x0
    80003d78:	b8a080e7          	jalr	-1142(ra) # 800038fe <readi>
    80003d7c:	47c1                	li	a5,16
    80003d7e:	06f51163          	bne	a0,a5,80003de0 <dirlink+0xa2>
    if(de.inum == 0)
    80003d82:	fc045783          	lhu	a5,-64(s0)
    80003d86:	c791                	beqz	a5,80003d92 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d88:	24c1                	addiw	s1,s1,16
    80003d8a:	04c92783          	lw	a5,76(s2)
    80003d8e:	fcf4ede3          	bltu	s1,a5,80003d68 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003d92:	4639                	li	a2,14
    80003d94:	85d2                	mv	a1,s4
    80003d96:	fc240513          	addi	a0,s0,-62
    80003d9a:	ffffd097          	auipc	ra,0xffffd
    80003d9e:	05a080e7          	jalr	90(ra) # 80000df4 <strncpy>
  de.inum = inum;
    80003da2:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003da6:	4741                	li	a4,16
    80003da8:	86a6                	mv	a3,s1
    80003daa:	fc040613          	addi	a2,s0,-64
    80003dae:	4581                	li	a1,0
    80003db0:	854a                	mv	a0,s2
    80003db2:	00000097          	auipc	ra,0x0
    80003db6:	c44080e7          	jalr	-956(ra) # 800039f6 <writei>
    80003dba:	872a                	mv	a4,a0
    80003dbc:	47c1                	li	a5,16
  return 0;
    80003dbe:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003dc0:	02f71863          	bne	a4,a5,80003df0 <dirlink+0xb2>
}
    80003dc4:	70e2                	ld	ra,56(sp)
    80003dc6:	7442                	ld	s0,48(sp)
    80003dc8:	74a2                	ld	s1,40(sp)
    80003dca:	7902                	ld	s2,32(sp)
    80003dcc:	69e2                	ld	s3,24(sp)
    80003dce:	6a42                	ld	s4,16(sp)
    80003dd0:	6121                	addi	sp,sp,64
    80003dd2:	8082                	ret
    iput(ip);
    80003dd4:	00000097          	auipc	ra,0x0
    80003dd8:	a30080e7          	jalr	-1488(ra) # 80003804 <iput>
    return -1;
    80003ddc:	557d                	li	a0,-1
    80003dde:	b7dd                	j	80003dc4 <dirlink+0x86>
      panic("dirlink read");
    80003de0:	00005517          	auipc	a0,0x5
    80003de4:	83850513          	addi	a0,a0,-1992 # 80008618 <syscalls+0x1c8>
    80003de8:	ffffc097          	auipc	ra,0xffffc
    80003dec:	756080e7          	jalr	1878(ra) # 8000053e <panic>
    panic("dirlink");
    80003df0:	00005517          	auipc	a0,0x5
    80003df4:	93850513          	addi	a0,a0,-1736 # 80008728 <syscalls+0x2d8>
    80003df8:	ffffc097          	auipc	ra,0xffffc
    80003dfc:	746080e7          	jalr	1862(ra) # 8000053e <panic>

0000000080003e00 <namei>:

struct inode*
namei(char *path)
{
    80003e00:	1101                	addi	sp,sp,-32
    80003e02:	ec06                	sd	ra,24(sp)
    80003e04:	e822                	sd	s0,16(sp)
    80003e06:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003e08:	fe040613          	addi	a2,s0,-32
    80003e0c:	4581                	li	a1,0
    80003e0e:	00000097          	auipc	ra,0x0
    80003e12:	dd0080e7          	jalr	-560(ra) # 80003bde <namex>
}
    80003e16:	60e2                	ld	ra,24(sp)
    80003e18:	6442                	ld	s0,16(sp)
    80003e1a:	6105                	addi	sp,sp,32
    80003e1c:	8082                	ret

0000000080003e1e <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003e1e:	1141                	addi	sp,sp,-16
    80003e20:	e406                	sd	ra,8(sp)
    80003e22:	e022                	sd	s0,0(sp)
    80003e24:	0800                	addi	s0,sp,16
    80003e26:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80003e28:	4585                	li	a1,1
    80003e2a:	00000097          	auipc	ra,0x0
    80003e2e:	db4080e7          	jalr	-588(ra) # 80003bde <namex>
}
    80003e32:	60a2                	ld	ra,8(sp)
    80003e34:	6402                	ld	s0,0(sp)
    80003e36:	0141                	addi	sp,sp,16
    80003e38:	8082                	ret

0000000080003e3a <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80003e3a:	1101                	addi	sp,sp,-32
    80003e3c:	ec06                	sd	ra,24(sp)
    80003e3e:	e822                	sd	s0,16(sp)
    80003e40:	e426                	sd	s1,8(sp)
    80003e42:	e04a                	sd	s2,0(sp)
    80003e44:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80003e46:	0001d917          	auipc	s2,0x1d
    80003e4a:	42a90913          	addi	s2,s2,1066 # 80021270 <log>
    80003e4e:	01892583          	lw	a1,24(s2)
    80003e52:	02892503          	lw	a0,40(s2)
    80003e56:	fffff097          	auipc	ra,0xfffff
    80003e5a:	ff2080e7          	jalr	-14(ra) # 80002e48 <bread>
    80003e5e:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80003e60:	02c92683          	lw	a3,44(s2)
    80003e64:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80003e66:	02d05763          	blez	a3,80003e94 <write_head+0x5a>
    80003e6a:	0001d797          	auipc	a5,0x1d
    80003e6e:	43678793          	addi	a5,a5,1078 # 800212a0 <log+0x30>
    80003e72:	05c50713          	addi	a4,a0,92
    80003e76:	36fd                	addiw	a3,a3,-1
    80003e78:	1682                	slli	a3,a3,0x20
    80003e7a:	9281                	srli	a3,a3,0x20
    80003e7c:	068a                	slli	a3,a3,0x2
    80003e7e:	0001d617          	auipc	a2,0x1d
    80003e82:	42660613          	addi	a2,a2,1062 # 800212a4 <log+0x34>
    80003e86:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80003e88:	4390                	lw	a2,0(a5)
    80003e8a:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80003e8c:	0791                	addi	a5,a5,4
    80003e8e:	0711                	addi	a4,a4,4
    80003e90:	fed79ce3          	bne	a5,a3,80003e88 <write_head+0x4e>
  }
  bwrite(buf);
    80003e94:	8526                	mv	a0,s1
    80003e96:	fffff097          	auipc	ra,0xfffff
    80003e9a:	0a4080e7          	jalr	164(ra) # 80002f3a <bwrite>
  brelse(buf);
    80003e9e:	8526                	mv	a0,s1
    80003ea0:	fffff097          	auipc	ra,0xfffff
    80003ea4:	0d8080e7          	jalr	216(ra) # 80002f78 <brelse>
}
    80003ea8:	60e2                	ld	ra,24(sp)
    80003eaa:	6442                	ld	s0,16(sp)
    80003eac:	64a2                	ld	s1,8(sp)
    80003eae:	6902                	ld	s2,0(sp)
    80003eb0:	6105                	addi	sp,sp,32
    80003eb2:	8082                	ret

0000000080003eb4 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80003eb4:	0001d797          	auipc	a5,0x1d
    80003eb8:	3e87a783          	lw	a5,1000(a5) # 8002129c <log+0x2c>
    80003ebc:	0af05d63          	blez	a5,80003f76 <install_trans+0xc2>
{
    80003ec0:	7139                	addi	sp,sp,-64
    80003ec2:	fc06                	sd	ra,56(sp)
    80003ec4:	f822                	sd	s0,48(sp)
    80003ec6:	f426                	sd	s1,40(sp)
    80003ec8:	f04a                	sd	s2,32(sp)
    80003eca:	ec4e                	sd	s3,24(sp)
    80003ecc:	e852                	sd	s4,16(sp)
    80003ece:	e456                	sd	s5,8(sp)
    80003ed0:	e05a                	sd	s6,0(sp)
    80003ed2:	0080                	addi	s0,sp,64
    80003ed4:	8b2a                	mv	s6,a0
    80003ed6:	0001da97          	auipc	s5,0x1d
    80003eda:	3caa8a93          	addi	s5,s5,970 # 800212a0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003ede:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80003ee0:	0001d997          	auipc	s3,0x1d
    80003ee4:	39098993          	addi	s3,s3,912 # 80021270 <log>
    80003ee8:	a035                	j	80003f14 <install_trans+0x60>
      bunpin(dbuf);
    80003eea:	8526                	mv	a0,s1
    80003eec:	fffff097          	auipc	ra,0xfffff
    80003ef0:	166080e7          	jalr	358(ra) # 80003052 <bunpin>
    brelse(lbuf);
    80003ef4:	854a                	mv	a0,s2
    80003ef6:	fffff097          	auipc	ra,0xfffff
    80003efa:	082080e7          	jalr	130(ra) # 80002f78 <brelse>
    brelse(dbuf);
    80003efe:	8526                	mv	a0,s1
    80003f00:	fffff097          	auipc	ra,0xfffff
    80003f04:	078080e7          	jalr	120(ra) # 80002f78 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003f08:	2a05                	addiw	s4,s4,1
    80003f0a:	0a91                	addi	s5,s5,4
    80003f0c:	02c9a783          	lw	a5,44(s3)
    80003f10:	04fa5963          	bge	s4,a5,80003f62 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80003f14:	0189a583          	lw	a1,24(s3)
    80003f18:	014585bb          	addw	a1,a1,s4
    80003f1c:	2585                	addiw	a1,a1,1
    80003f1e:	0289a503          	lw	a0,40(s3)
    80003f22:	fffff097          	auipc	ra,0xfffff
    80003f26:	f26080e7          	jalr	-218(ra) # 80002e48 <bread>
    80003f2a:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80003f2c:	000aa583          	lw	a1,0(s5)
    80003f30:	0289a503          	lw	a0,40(s3)
    80003f34:	fffff097          	auipc	ra,0xfffff
    80003f38:	f14080e7          	jalr	-236(ra) # 80002e48 <bread>
    80003f3c:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80003f3e:	40000613          	li	a2,1024
    80003f42:	05890593          	addi	a1,s2,88
    80003f46:	05850513          	addi	a0,a0,88
    80003f4a:	ffffd097          	auipc	ra,0xffffd
    80003f4e:	df6080e7          	jalr	-522(ra) # 80000d40 <memmove>
    bwrite(dbuf);  // write dst to disk
    80003f52:	8526                	mv	a0,s1
    80003f54:	fffff097          	auipc	ra,0xfffff
    80003f58:	fe6080e7          	jalr	-26(ra) # 80002f3a <bwrite>
    if(recovering == 0)
    80003f5c:	f80b1ce3          	bnez	s6,80003ef4 <install_trans+0x40>
    80003f60:	b769                	j	80003eea <install_trans+0x36>
}
    80003f62:	70e2                	ld	ra,56(sp)
    80003f64:	7442                	ld	s0,48(sp)
    80003f66:	74a2                	ld	s1,40(sp)
    80003f68:	7902                	ld	s2,32(sp)
    80003f6a:	69e2                	ld	s3,24(sp)
    80003f6c:	6a42                	ld	s4,16(sp)
    80003f6e:	6aa2                	ld	s5,8(sp)
    80003f70:	6b02                	ld	s6,0(sp)
    80003f72:	6121                	addi	sp,sp,64
    80003f74:	8082                	ret
    80003f76:	8082                	ret

0000000080003f78 <initlog>:
{
    80003f78:	7179                	addi	sp,sp,-48
    80003f7a:	f406                	sd	ra,40(sp)
    80003f7c:	f022                	sd	s0,32(sp)
    80003f7e:	ec26                	sd	s1,24(sp)
    80003f80:	e84a                	sd	s2,16(sp)
    80003f82:	e44e                	sd	s3,8(sp)
    80003f84:	1800                	addi	s0,sp,48
    80003f86:	892a                	mv	s2,a0
    80003f88:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80003f8a:	0001d497          	auipc	s1,0x1d
    80003f8e:	2e648493          	addi	s1,s1,742 # 80021270 <log>
    80003f92:	00004597          	auipc	a1,0x4
    80003f96:	69658593          	addi	a1,a1,1686 # 80008628 <syscalls+0x1d8>
    80003f9a:	8526                	mv	a0,s1
    80003f9c:	ffffd097          	auipc	ra,0xffffd
    80003fa0:	bb8080e7          	jalr	-1096(ra) # 80000b54 <initlock>
  log.start = sb->logstart;
    80003fa4:	0149a583          	lw	a1,20(s3)
    80003fa8:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80003faa:	0109a783          	lw	a5,16(s3)
    80003fae:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80003fb0:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80003fb4:	854a                	mv	a0,s2
    80003fb6:	fffff097          	auipc	ra,0xfffff
    80003fba:	e92080e7          	jalr	-366(ra) # 80002e48 <bread>
  log.lh.n = lh->n;
    80003fbe:	4d3c                	lw	a5,88(a0)
    80003fc0:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80003fc2:	02f05563          	blez	a5,80003fec <initlog+0x74>
    80003fc6:	05c50713          	addi	a4,a0,92
    80003fca:	0001d697          	auipc	a3,0x1d
    80003fce:	2d668693          	addi	a3,a3,726 # 800212a0 <log+0x30>
    80003fd2:	37fd                	addiw	a5,a5,-1
    80003fd4:	1782                	slli	a5,a5,0x20
    80003fd6:	9381                	srli	a5,a5,0x20
    80003fd8:	078a                	slli	a5,a5,0x2
    80003fda:	06050613          	addi	a2,a0,96
    80003fde:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    80003fe0:	4310                	lw	a2,0(a4)
    80003fe2:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    80003fe4:	0711                	addi	a4,a4,4
    80003fe6:	0691                	addi	a3,a3,4
    80003fe8:	fef71ce3          	bne	a4,a5,80003fe0 <initlog+0x68>
  brelse(buf);
    80003fec:	fffff097          	auipc	ra,0xfffff
    80003ff0:	f8c080e7          	jalr	-116(ra) # 80002f78 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80003ff4:	4505                	li	a0,1
    80003ff6:	00000097          	auipc	ra,0x0
    80003ffa:	ebe080e7          	jalr	-322(ra) # 80003eb4 <install_trans>
  log.lh.n = 0;
    80003ffe:	0001d797          	auipc	a5,0x1d
    80004002:	2807af23          	sw	zero,670(a5) # 8002129c <log+0x2c>
  write_head(); // clear the log
    80004006:	00000097          	auipc	ra,0x0
    8000400a:	e34080e7          	jalr	-460(ra) # 80003e3a <write_head>
}
    8000400e:	70a2                	ld	ra,40(sp)
    80004010:	7402                	ld	s0,32(sp)
    80004012:	64e2                	ld	s1,24(sp)
    80004014:	6942                	ld	s2,16(sp)
    80004016:	69a2                	ld	s3,8(sp)
    80004018:	6145                	addi	sp,sp,48
    8000401a:	8082                	ret

000000008000401c <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    8000401c:	1101                	addi	sp,sp,-32
    8000401e:	ec06                	sd	ra,24(sp)
    80004020:	e822                	sd	s0,16(sp)
    80004022:	e426                	sd	s1,8(sp)
    80004024:	e04a                	sd	s2,0(sp)
    80004026:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004028:	0001d517          	auipc	a0,0x1d
    8000402c:	24850513          	addi	a0,a0,584 # 80021270 <log>
    80004030:	ffffd097          	auipc	ra,0xffffd
    80004034:	bb4080e7          	jalr	-1100(ra) # 80000be4 <acquire>
  while(1){
    if(log.committing){
    80004038:	0001d497          	auipc	s1,0x1d
    8000403c:	23848493          	addi	s1,s1,568 # 80021270 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004040:	4979                	li	s2,30
    80004042:	a039                	j	80004050 <begin_op+0x34>
      sleep(&log, &log.lock);
    80004044:	85a6                	mv	a1,s1
    80004046:	8526                	mv	a0,s1
    80004048:	ffffe097          	auipc	ra,0xffffe
    8000404c:	0a0080e7          	jalr	160(ra) # 800020e8 <sleep>
    if(log.committing){
    80004050:	50dc                	lw	a5,36(s1)
    80004052:	fbed                	bnez	a5,80004044 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004054:	509c                	lw	a5,32(s1)
    80004056:	0017871b          	addiw	a4,a5,1
    8000405a:	0007069b          	sext.w	a3,a4
    8000405e:	0027179b          	slliw	a5,a4,0x2
    80004062:	9fb9                	addw	a5,a5,a4
    80004064:	0017979b          	slliw	a5,a5,0x1
    80004068:	54d8                	lw	a4,44(s1)
    8000406a:	9fb9                	addw	a5,a5,a4
    8000406c:	00f95963          	bge	s2,a5,8000407e <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004070:	85a6                	mv	a1,s1
    80004072:	8526                	mv	a0,s1
    80004074:	ffffe097          	auipc	ra,0xffffe
    80004078:	074080e7          	jalr	116(ra) # 800020e8 <sleep>
    8000407c:	bfd1                	j	80004050 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    8000407e:	0001d517          	auipc	a0,0x1d
    80004082:	1f250513          	addi	a0,a0,498 # 80021270 <log>
    80004086:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004088:	ffffd097          	auipc	ra,0xffffd
    8000408c:	c10080e7          	jalr	-1008(ra) # 80000c98 <release>
      break;
    }
  }
}
    80004090:	60e2                	ld	ra,24(sp)
    80004092:	6442                	ld	s0,16(sp)
    80004094:	64a2                	ld	s1,8(sp)
    80004096:	6902                	ld	s2,0(sp)
    80004098:	6105                	addi	sp,sp,32
    8000409a:	8082                	ret

000000008000409c <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    8000409c:	7139                	addi	sp,sp,-64
    8000409e:	fc06                	sd	ra,56(sp)
    800040a0:	f822                	sd	s0,48(sp)
    800040a2:	f426                	sd	s1,40(sp)
    800040a4:	f04a                	sd	s2,32(sp)
    800040a6:	ec4e                	sd	s3,24(sp)
    800040a8:	e852                	sd	s4,16(sp)
    800040aa:	e456                	sd	s5,8(sp)
    800040ac:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    800040ae:	0001d497          	auipc	s1,0x1d
    800040b2:	1c248493          	addi	s1,s1,450 # 80021270 <log>
    800040b6:	8526                	mv	a0,s1
    800040b8:	ffffd097          	auipc	ra,0xffffd
    800040bc:	b2c080e7          	jalr	-1236(ra) # 80000be4 <acquire>
  log.outstanding -= 1;
    800040c0:	509c                	lw	a5,32(s1)
    800040c2:	37fd                	addiw	a5,a5,-1
    800040c4:	0007891b          	sext.w	s2,a5
    800040c8:	d09c                	sw	a5,32(s1)
  if(log.committing)
    800040ca:	50dc                	lw	a5,36(s1)
    800040cc:	efb9                	bnez	a5,8000412a <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    800040ce:	06091663          	bnez	s2,8000413a <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    800040d2:	0001d497          	auipc	s1,0x1d
    800040d6:	19e48493          	addi	s1,s1,414 # 80021270 <log>
    800040da:	4785                	li	a5,1
    800040dc:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800040de:	8526                	mv	a0,s1
    800040e0:	ffffd097          	auipc	ra,0xffffd
    800040e4:	bb8080e7          	jalr	-1096(ra) # 80000c98 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800040e8:	54dc                	lw	a5,44(s1)
    800040ea:	06f04763          	bgtz	a5,80004158 <end_op+0xbc>
    acquire(&log.lock);
    800040ee:	0001d497          	auipc	s1,0x1d
    800040f2:	18248493          	addi	s1,s1,386 # 80021270 <log>
    800040f6:	8526                	mv	a0,s1
    800040f8:	ffffd097          	auipc	ra,0xffffd
    800040fc:	aec080e7          	jalr	-1300(ra) # 80000be4 <acquire>
    log.committing = 0;
    80004100:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004104:	8526                	mv	a0,s1
    80004106:	ffffe097          	auipc	ra,0xffffe
    8000410a:	16e080e7          	jalr	366(ra) # 80002274 <wakeup>
    release(&log.lock);
    8000410e:	8526                	mv	a0,s1
    80004110:	ffffd097          	auipc	ra,0xffffd
    80004114:	b88080e7          	jalr	-1144(ra) # 80000c98 <release>
}
    80004118:	70e2                	ld	ra,56(sp)
    8000411a:	7442                	ld	s0,48(sp)
    8000411c:	74a2                	ld	s1,40(sp)
    8000411e:	7902                	ld	s2,32(sp)
    80004120:	69e2                	ld	s3,24(sp)
    80004122:	6a42                	ld	s4,16(sp)
    80004124:	6aa2                	ld	s5,8(sp)
    80004126:	6121                	addi	sp,sp,64
    80004128:	8082                	ret
    panic("log.committing");
    8000412a:	00004517          	auipc	a0,0x4
    8000412e:	50650513          	addi	a0,a0,1286 # 80008630 <syscalls+0x1e0>
    80004132:	ffffc097          	auipc	ra,0xffffc
    80004136:	40c080e7          	jalr	1036(ra) # 8000053e <panic>
    wakeup(&log);
    8000413a:	0001d497          	auipc	s1,0x1d
    8000413e:	13648493          	addi	s1,s1,310 # 80021270 <log>
    80004142:	8526                	mv	a0,s1
    80004144:	ffffe097          	auipc	ra,0xffffe
    80004148:	130080e7          	jalr	304(ra) # 80002274 <wakeup>
  release(&log.lock);
    8000414c:	8526                	mv	a0,s1
    8000414e:	ffffd097          	auipc	ra,0xffffd
    80004152:	b4a080e7          	jalr	-1206(ra) # 80000c98 <release>
  if(do_commit){
    80004156:	b7c9                	j	80004118 <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004158:	0001da97          	auipc	s5,0x1d
    8000415c:	148a8a93          	addi	s5,s5,328 # 800212a0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004160:	0001da17          	auipc	s4,0x1d
    80004164:	110a0a13          	addi	s4,s4,272 # 80021270 <log>
    80004168:	018a2583          	lw	a1,24(s4)
    8000416c:	012585bb          	addw	a1,a1,s2
    80004170:	2585                	addiw	a1,a1,1
    80004172:	028a2503          	lw	a0,40(s4)
    80004176:	fffff097          	auipc	ra,0xfffff
    8000417a:	cd2080e7          	jalr	-814(ra) # 80002e48 <bread>
    8000417e:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004180:	000aa583          	lw	a1,0(s5)
    80004184:	028a2503          	lw	a0,40(s4)
    80004188:	fffff097          	auipc	ra,0xfffff
    8000418c:	cc0080e7          	jalr	-832(ra) # 80002e48 <bread>
    80004190:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004192:	40000613          	li	a2,1024
    80004196:	05850593          	addi	a1,a0,88
    8000419a:	05848513          	addi	a0,s1,88
    8000419e:	ffffd097          	auipc	ra,0xffffd
    800041a2:	ba2080e7          	jalr	-1118(ra) # 80000d40 <memmove>
    bwrite(to);  // write the log
    800041a6:	8526                	mv	a0,s1
    800041a8:	fffff097          	auipc	ra,0xfffff
    800041ac:	d92080e7          	jalr	-622(ra) # 80002f3a <bwrite>
    brelse(from);
    800041b0:	854e                	mv	a0,s3
    800041b2:	fffff097          	auipc	ra,0xfffff
    800041b6:	dc6080e7          	jalr	-570(ra) # 80002f78 <brelse>
    brelse(to);
    800041ba:	8526                	mv	a0,s1
    800041bc:	fffff097          	auipc	ra,0xfffff
    800041c0:	dbc080e7          	jalr	-580(ra) # 80002f78 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800041c4:	2905                	addiw	s2,s2,1
    800041c6:	0a91                	addi	s5,s5,4
    800041c8:	02ca2783          	lw	a5,44(s4)
    800041cc:	f8f94ee3          	blt	s2,a5,80004168 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    800041d0:	00000097          	auipc	ra,0x0
    800041d4:	c6a080e7          	jalr	-918(ra) # 80003e3a <write_head>
    install_trans(0); // Now install writes to home locations
    800041d8:	4501                	li	a0,0
    800041da:	00000097          	auipc	ra,0x0
    800041de:	cda080e7          	jalr	-806(ra) # 80003eb4 <install_trans>
    log.lh.n = 0;
    800041e2:	0001d797          	auipc	a5,0x1d
    800041e6:	0a07ad23          	sw	zero,186(a5) # 8002129c <log+0x2c>
    write_head();    // Erase the transaction from the log
    800041ea:	00000097          	auipc	ra,0x0
    800041ee:	c50080e7          	jalr	-944(ra) # 80003e3a <write_head>
    800041f2:	bdf5                	j	800040ee <end_op+0x52>

00000000800041f4 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800041f4:	1101                	addi	sp,sp,-32
    800041f6:	ec06                	sd	ra,24(sp)
    800041f8:	e822                	sd	s0,16(sp)
    800041fa:	e426                	sd	s1,8(sp)
    800041fc:	e04a                	sd	s2,0(sp)
    800041fe:	1000                	addi	s0,sp,32
    80004200:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004202:	0001d917          	auipc	s2,0x1d
    80004206:	06e90913          	addi	s2,s2,110 # 80021270 <log>
    8000420a:	854a                	mv	a0,s2
    8000420c:	ffffd097          	auipc	ra,0xffffd
    80004210:	9d8080e7          	jalr	-1576(ra) # 80000be4 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004214:	02c92603          	lw	a2,44(s2)
    80004218:	47f5                	li	a5,29
    8000421a:	06c7c563          	blt	a5,a2,80004284 <log_write+0x90>
    8000421e:	0001d797          	auipc	a5,0x1d
    80004222:	06e7a783          	lw	a5,110(a5) # 8002128c <log+0x1c>
    80004226:	37fd                	addiw	a5,a5,-1
    80004228:	04f65e63          	bge	a2,a5,80004284 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    8000422c:	0001d797          	auipc	a5,0x1d
    80004230:	0647a783          	lw	a5,100(a5) # 80021290 <log+0x20>
    80004234:	06f05063          	blez	a5,80004294 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004238:	4781                	li	a5,0
    8000423a:	06c05563          	blez	a2,800042a4 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    8000423e:	44cc                	lw	a1,12(s1)
    80004240:	0001d717          	auipc	a4,0x1d
    80004244:	06070713          	addi	a4,a4,96 # 800212a0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004248:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    8000424a:	4314                	lw	a3,0(a4)
    8000424c:	04b68c63          	beq	a3,a1,800042a4 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004250:	2785                	addiw	a5,a5,1
    80004252:	0711                	addi	a4,a4,4
    80004254:	fef61be3          	bne	a2,a5,8000424a <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004258:	0621                	addi	a2,a2,8
    8000425a:	060a                	slli	a2,a2,0x2
    8000425c:	0001d797          	auipc	a5,0x1d
    80004260:	01478793          	addi	a5,a5,20 # 80021270 <log>
    80004264:	963e                	add	a2,a2,a5
    80004266:	44dc                	lw	a5,12(s1)
    80004268:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    8000426a:	8526                	mv	a0,s1
    8000426c:	fffff097          	auipc	ra,0xfffff
    80004270:	daa080e7          	jalr	-598(ra) # 80003016 <bpin>
    log.lh.n++;
    80004274:	0001d717          	auipc	a4,0x1d
    80004278:	ffc70713          	addi	a4,a4,-4 # 80021270 <log>
    8000427c:	575c                	lw	a5,44(a4)
    8000427e:	2785                	addiw	a5,a5,1
    80004280:	d75c                	sw	a5,44(a4)
    80004282:	a835                	j	800042be <log_write+0xca>
    panic("too big a transaction");
    80004284:	00004517          	auipc	a0,0x4
    80004288:	3bc50513          	addi	a0,a0,956 # 80008640 <syscalls+0x1f0>
    8000428c:	ffffc097          	auipc	ra,0xffffc
    80004290:	2b2080e7          	jalr	690(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    80004294:	00004517          	auipc	a0,0x4
    80004298:	3c450513          	addi	a0,a0,964 # 80008658 <syscalls+0x208>
    8000429c:	ffffc097          	auipc	ra,0xffffc
    800042a0:	2a2080e7          	jalr	674(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    800042a4:	00878713          	addi	a4,a5,8
    800042a8:	00271693          	slli	a3,a4,0x2
    800042ac:	0001d717          	auipc	a4,0x1d
    800042b0:	fc470713          	addi	a4,a4,-60 # 80021270 <log>
    800042b4:	9736                	add	a4,a4,a3
    800042b6:	44d4                	lw	a3,12(s1)
    800042b8:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    800042ba:	faf608e3          	beq	a2,a5,8000426a <log_write+0x76>
  }
  release(&log.lock);
    800042be:	0001d517          	auipc	a0,0x1d
    800042c2:	fb250513          	addi	a0,a0,-78 # 80021270 <log>
    800042c6:	ffffd097          	auipc	ra,0xffffd
    800042ca:	9d2080e7          	jalr	-1582(ra) # 80000c98 <release>
}
    800042ce:	60e2                	ld	ra,24(sp)
    800042d0:	6442                	ld	s0,16(sp)
    800042d2:	64a2                	ld	s1,8(sp)
    800042d4:	6902                	ld	s2,0(sp)
    800042d6:	6105                	addi	sp,sp,32
    800042d8:	8082                	ret

00000000800042da <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    800042da:	1101                	addi	sp,sp,-32
    800042dc:	ec06                	sd	ra,24(sp)
    800042de:	e822                	sd	s0,16(sp)
    800042e0:	e426                	sd	s1,8(sp)
    800042e2:	e04a                	sd	s2,0(sp)
    800042e4:	1000                	addi	s0,sp,32
    800042e6:	84aa                	mv	s1,a0
    800042e8:	892e                	mv	s2,a1
	initlock(&lk->lk, "sleep lock");
    800042ea:	00004597          	auipc	a1,0x4
    800042ee:	38e58593          	addi	a1,a1,910 # 80008678 <syscalls+0x228>
    800042f2:	0521                	addi	a0,a0,8
    800042f4:	ffffd097          	auipc	ra,0xffffd
    800042f8:	860080e7          	jalr	-1952(ra) # 80000b54 <initlock>
	lk->name = name;
    800042fc:	0324b023          	sd	s2,32(s1)
	lk->locked = 0;
    80004300:	0004a023          	sw	zero,0(s1)
	lk->pid = 0;
    80004304:	0204a423          	sw	zero,40(s1)
}
    80004308:	60e2                	ld	ra,24(sp)
    8000430a:	6442                	ld	s0,16(sp)
    8000430c:	64a2                	ld	s1,8(sp)
    8000430e:	6902                	ld	s2,0(sp)
    80004310:	6105                	addi	sp,sp,32
    80004312:	8082                	ret

0000000080004314 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004314:	1101                	addi	sp,sp,-32
    80004316:	ec06                	sd	ra,24(sp)
    80004318:	e822                	sd	s0,16(sp)
    8000431a:	e426                	sd	s1,8(sp)
    8000431c:	e04a                	sd	s2,0(sp)
    8000431e:	1000                	addi	s0,sp,32
    80004320:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004322:	00850913          	addi	s2,a0,8
    80004326:	854a                	mv	a0,s2
    80004328:	ffffd097          	auipc	ra,0xffffd
    8000432c:	8bc080e7          	jalr	-1860(ra) # 80000be4 <acquire>
  while (lk->locked) {
    80004330:	409c                	lw	a5,0(s1)
    80004332:	cb89                	beqz	a5,80004344 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004334:	85ca                	mv	a1,s2
    80004336:	8526                	mv	a0,s1
    80004338:	ffffe097          	auipc	ra,0xffffe
    8000433c:	db0080e7          	jalr	-592(ra) # 800020e8 <sleep>
  while (lk->locked) {
    80004340:	409c                	lw	a5,0(s1)
    80004342:	fbed                	bnez	a5,80004334 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004344:	4785                	li	a5,1
    80004346:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004348:	ffffd097          	auipc	ra,0xffffd
    8000434c:	6e4080e7          	jalr	1764(ra) # 80001a2c <myproc>
    80004350:	591c                	lw	a5,48(a0)
    80004352:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004354:	854a                	mv	a0,s2
    80004356:	ffffd097          	auipc	ra,0xffffd
    8000435a:	942080e7          	jalr	-1726(ra) # 80000c98 <release>
}
    8000435e:	60e2                	ld	ra,24(sp)
    80004360:	6442                	ld	s0,16(sp)
    80004362:	64a2                	ld	s1,8(sp)
    80004364:	6902                	ld	s2,0(sp)
    80004366:	6105                	addi	sp,sp,32
    80004368:	8082                	ret

000000008000436a <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    8000436a:	1101                	addi	sp,sp,-32
    8000436c:	ec06                	sd	ra,24(sp)
    8000436e:	e822                	sd	s0,16(sp)
    80004370:	e426                	sd	s1,8(sp)
    80004372:	e04a                	sd	s2,0(sp)
    80004374:	1000                	addi	s0,sp,32
    80004376:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004378:	00850913          	addi	s2,a0,8
    8000437c:	854a                	mv	a0,s2
    8000437e:	ffffd097          	auipc	ra,0xffffd
    80004382:	866080e7          	jalr	-1946(ra) # 80000be4 <acquire>
  lk->locked = 0;
    80004386:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000438a:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    8000438e:	8526                	mv	a0,s1
    80004390:	ffffe097          	auipc	ra,0xffffe
    80004394:	ee4080e7          	jalr	-284(ra) # 80002274 <wakeup>
  release(&lk->lk);
    80004398:	854a                	mv	a0,s2
    8000439a:	ffffd097          	auipc	ra,0xffffd
    8000439e:	8fe080e7          	jalr	-1794(ra) # 80000c98 <release>
}
    800043a2:	60e2                	ld	ra,24(sp)
    800043a4:	6442                	ld	s0,16(sp)
    800043a6:	64a2                	ld	s1,8(sp)
    800043a8:	6902                	ld	s2,0(sp)
    800043aa:	6105                	addi	sp,sp,32
    800043ac:	8082                	ret

00000000800043ae <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    800043ae:	7179                	addi	sp,sp,-48
    800043b0:	f406                	sd	ra,40(sp)
    800043b2:	f022                	sd	s0,32(sp)
    800043b4:	ec26                	sd	s1,24(sp)
    800043b6:	e84a                	sd	s2,16(sp)
    800043b8:	e44e                	sd	s3,8(sp)
    800043ba:	1800                	addi	s0,sp,48
    800043bc:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    800043be:	00850913          	addi	s2,a0,8
    800043c2:	854a                	mv	a0,s2
    800043c4:	ffffd097          	auipc	ra,0xffffd
    800043c8:	820080e7          	jalr	-2016(ra) # 80000be4 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    800043cc:	409c                	lw	a5,0(s1)
    800043ce:	ef99                	bnez	a5,800043ec <holdingsleep+0x3e>
    800043d0:	4481                	li	s1,0
  release(&lk->lk);
    800043d2:	854a                	mv	a0,s2
    800043d4:	ffffd097          	auipc	ra,0xffffd
    800043d8:	8c4080e7          	jalr	-1852(ra) # 80000c98 <release>
  return r;
}
    800043dc:	8526                	mv	a0,s1
    800043de:	70a2                	ld	ra,40(sp)
    800043e0:	7402                	ld	s0,32(sp)
    800043e2:	64e2                	ld	s1,24(sp)
    800043e4:	6942                	ld	s2,16(sp)
    800043e6:	69a2                	ld	s3,8(sp)
    800043e8:	6145                	addi	sp,sp,48
    800043ea:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    800043ec:	0284a983          	lw	s3,40(s1)
    800043f0:	ffffd097          	auipc	ra,0xffffd
    800043f4:	63c080e7          	jalr	1596(ra) # 80001a2c <myproc>
    800043f8:	5904                	lw	s1,48(a0)
    800043fa:	413484b3          	sub	s1,s1,s3
    800043fe:	0014b493          	seqz	s1,s1
    80004402:	bfc1                	j	800043d2 <holdingsleep+0x24>

0000000080004404 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004404:	1141                	addi	sp,sp,-16
    80004406:	e406                	sd	ra,8(sp)
    80004408:	e022                	sd	s0,0(sp)
    8000440a:	0800                	addi	s0,sp,16
	initlock(&ftable.lock, "ftable");
    8000440c:	00004597          	auipc	a1,0x4
    80004410:	27c58593          	addi	a1,a1,636 # 80008688 <syscalls+0x238>
    80004414:	0001d517          	auipc	a0,0x1d
    80004418:	fa450513          	addi	a0,a0,-92 # 800213b8 <ftable>
    8000441c:	ffffc097          	auipc	ra,0xffffc
    80004420:	738080e7          	jalr	1848(ra) # 80000b54 <initlock>
}
    80004424:	60a2                	ld	ra,8(sp)
    80004426:	6402                	ld	s0,0(sp)
    80004428:	0141                	addi	sp,sp,16
    8000442a:	8082                	ret

000000008000442c <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    8000442c:	1101                	addi	sp,sp,-32
    8000442e:	ec06                	sd	ra,24(sp)
    80004430:	e822                	sd	s0,16(sp)
    80004432:	e426                	sd	s1,8(sp)
    80004434:	1000                	addi	s0,sp,32
	struct file *f;

	acquire(&ftable.lock);
    80004436:	0001d517          	auipc	a0,0x1d
    8000443a:	f8250513          	addi	a0,a0,-126 # 800213b8 <ftable>
    8000443e:	ffffc097          	auipc	ra,0xffffc
    80004442:	7a6080e7          	jalr	1958(ra) # 80000be4 <acquire>
	for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004446:	0001d497          	auipc	s1,0x1d
    8000444a:	f8a48493          	addi	s1,s1,-118 # 800213d0 <ftable+0x18>
    8000444e:	0001e717          	auipc	a4,0x1e
    80004452:	f2270713          	addi	a4,a4,-222 # 80022370 <ftable+0xfb8>
		if(f->ref == 0){
    80004456:	40dc                	lw	a5,4(s1)
    80004458:	cf99                	beqz	a5,80004476 <filealloc+0x4a>
	for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000445a:	02848493          	addi	s1,s1,40
    8000445e:	fee49ce3          	bne	s1,a4,80004456 <filealloc+0x2a>
			f->ref = 1;
			release(&ftable.lock);
			return f;
		}
	}
	release(&ftable.lock);
    80004462:	0001d517          	auipc	a0,0x1d
    80004466:	f5650513          	addi	a0,a0,-170 # 800213b8 <ftable>
    8000446a:	ffffd097          	auipc	ra,0xffffd
    8000446e:	82e080e7          	jalr	-2002(ra) # 80000c98 <release>
	return 0;
    80004472:	4481                	li	s1,0
    80004474:	a819                	j	8000448a <filealloc+0x5e>
			f->ref = 1;
    80004476:	4785                	li	a5,1
    80004478:	c0dc                	sw	a5,4(s1)
			release(&ftable.lock);
    8000447a:	0001d517          	auipc	a0,0x1d
    8000447e:	f3e50513          	addi	a0,a0,-194 # 800213b8 <ftable>
    80004482:	ffffd097          	auipc	ra,0xffffd
    80004486:	816080e7          	jalr	-2026(ra) # 80000c98 <release>
}
    8000448a:	8526                	mv	a0,s1
    8000448c:	60e2                	ld	ra,24(sp)
    8000448e:	6442                	ld	s0,16(sp)
    80004490:	64a2                	ld	s1,8(sp)
    80004492:	6105                	addi	sp,sp,32
    80004494:	8082                	ret

0000000080004496 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004496:	1101                	addi	sp,sp,-32
    80004498:	ec06                	sd	ra,24(sp)
    8000449a:	e822                	sd	s0,16(sp)
    8000449c:	e426                	sd	s1,8(sp)
    8000449e:	1000                	addi	s0,sp,32
    800044a0:	84aa                	mv	s1,a0
	acquire(&ftable.lock);
    800044a2:	0001d517          	auipc	a0,0x1d
    800044a6:	f1650513          	addi	a0,a0,-234 # 800213b8 <ftable>
    800044aa:	ffffc097          	auipc	ra,0xffffc
    800044ae:	73a080e7          	jalr	1850(ra) # 80000be4 <acquire>
	if(f->ref < 1)
    800044b2:	40dc                	lw	a5,4(s1)
    800044b4:	02f05263          	blez	a5,800044d8 <filedup+0x42>
		panic("filedup");
	f->ref++;
    800044b8:	2785                	addiw	a5,a5,1
    800044ba:	c0dc                	sw	a5,4(s1)
	release(&ftable.lock);
    800044bc:	0001d517          	auipc	a0,0x1d
    800044c0:	efc50513          	addi	a0,a0,-260 # 800213b8 <ftable>
    800044c4:	ffffc097          	auipc	ra,0xffffc
    800044c8:	7d4080e7          	jalr	2004(ra) # 80000c98 <release>
	return f;
}
    800044cc:	8526                	mv	a0,s1
    800044ce:	60e2                	ld	ra,24(sp)
    800044d0:	6442                	ld	s0,16(sp)
    800044d2:	64a2                	ld	s1,8(sp)
    800044d4:	6105                	addi	sp,sp,32
    800044d6:	8082                	ret
		panic("filedup");
    800044d8:	00004517          	auipc	a0,0x4
    800044dc:	1b850513          	addi	a0,a0,440 # 80008690 <syscalls+0x240>
    800044e0:	ffffc097          	auipc	ra,0xffffc
    800044e4:	05e080e7          	jalr	94(ra) # 8000053e <panic>

00000000800044e8 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    800044e8:	7139                	addi	sp,sp,-64
    800044ea:	fc06                	sd	ra,56(sp)
    800044ec:	f822                	sd	s0,48(sp)
    800044ee:	f426                	sd	s1,40(sp)
    800044f0:	f04a                	sd	s2,32(sp)
    800044f2:	ec4e                	sd	s3,24(sp)
    800044f4:	e852                	sd	s4,16(sp)
    800044f6:	e456                	sd	s5,8(sp)
    800044f8:	0080                	addi	s0,sp,64
    800044fa:	84aa                	mv	s1,a0
	struct file ff;

	acquire(&ftable.lock);
    800044fc:	0001d517          	auipc	a0,0x1d
    80004500:	ebc50513          	addi	a0,a0,-324 # 800213b8 <ftable>
    80004504:	ffffc097          	auipc	ra,0xffffc
    80004508:	6e0080e7          	jalr	1760(ra) # 80000be4 <acquire>
	if(f->ref < 1)
    8000450c:	40dc                	lw	a5,4(s1)
    8000450e:	06f05163          	blez	a5,80004570 <fileclose+0x88>
		panic("fileclose");
	if(--f->ref > 0){
    80004512:	37fd                	addiw	a5,a5,-1
    80004514:	0007871b          	sext.w	a4,a5
    80004518:	c0dc                	sw	a5,4(s1)
    8000451a:	06e04363          	bgtz	a4,80004580 <fileclose+0x98>
		release(&ftable.lock);
		return;
	}
	ff = *f;
    8000451e:	0004a903          	lw	s2,0(s1)
    80004522:	0094ca83          	lbu	s5,9(s1)
    80004526:	0104ba03          	ld	s4,16(s1)
    8000452a:	0184b983          	ld	s3,24(s1)
	f->ref = 0;
    8000452e:	0004a223          	sw	zero,4(s1)
	f->type = FD_NONE;
    80004532:	0004a023          	sw	zero,0(s1)
	release(&ftable.lock);
    80004536:	0001d517          	auipc	a0,0x1d
    8000453a:	e8250513          	addi	a0,a0,-382 # 800213b8 <ftable>
    8000453e:	ffffc097          	auipc	ra,0xffffc
    80004542:	75a080e7          	jalr	1882(ra) # 80000c98 <release>

	if(ff.type == FD_PIPE){
    80004546:	4785                	li	a5,1
    80004548:	04f90d63          	beq	s2,a5,800045a2 <fileclose+0xba>
		pipeclose(ff.pipe, ff.writable);
	} else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    8000454c:	3979                	addiw	s2,s2,-2
    8000454e:	4785                	li	a5,1
    80004550:	0527e063          	bltu	a5,s2,80004590 <fileclose+0xa8>
		begin_op();
    80004554:	00000097          	auipc	ra,0x0
    80004558:	ac8080e7          	jalr	-1336(ra) # 8000401c <begin_op>
		iput(ff.ip);
    8000455c:	854e                	mv	a0,s3
    8000455e:	fffff097          	auipc	ra,0xfffff
    80004562:	2a6080e7          	jalr	678(ra) # 80003804 <iput>
		end_op();
    80004566:	00000097          	auipc	ra,0x0
    8000456a:	b36080e7          	jalr	-1226(ra) # 8000409c <end_op>
    8000456e:	a00d                	j	80004590 <fileclose+0xa8>
		panic("fileclose");
    80004570:	00004517          	auipc	a0,0x4
    80004574:	12850513          	addi	a0,a0,296 # 80008698 <syscalls+0x248>
    80004578:	ffffc097          	auipc	ra,0xffffc
    8000457c:	fc6080e7          	jalr	-58(ra) # 8000053e <panic>
		release(&ftable.lock);
    80004580:	0001d517          	auipc	a0,0x1d
    80004584:	e3850513          	addi	a0,a0,-456 # 800213b8 <ftable>
    80004588:	ffffc097          	auipc	ra,0xffffc
    8000458c:	710080e7          	jalr	1808(ra) # 80000c98 <release>
	}
}
    80004590:	70e2                	ld	ra,56(sp)
    80004592:	7442                	ld	s0,48(sp)
    80004594:	74a2                	ld	s1,40(sp)
    80004596:	7902                	ld	s2,32(sp)
    80004598:	69e2                	ld	s3,24(sp)
    8000459a:	6a42                	ld	s4,16(sp)
    8000459c:	6aa2                	ld	s5,8(sp)
    8000459e:	6121                	addi	sp,sp,64
    800045a0:	8082                	ret
		pipeclose(ff.pipe, ff.writable);
    800045a2:	85d6                	mv	a1,s5
    800045a4:	8552                	mv	a0,s4
    800045a6:	00000097          	auipc	ra,0x0
    800045aa:	34c080e7          	jalr	844(ra) # 800048f2 <pipeclose>
    800045ae:	b7cd                	j	80004590 <fileclose+0xa8>

00000000800045b0 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    800045b0:	715d                	addi	sp,sp,-80
    800045b2:	e486                	sd	ra,72(sp)
    800045b4:	e0a2                	sd	s0,64(sp)
    800045b6:	fc26                	sd	s1,56(sp)
    800045b8:	f84a                	sd	s2,48(sp)
    800045ba:	f44e                	sd	s3,40(sp)
    800045bc:	0880                	addi	s0,sp,80
    800045be:	84aa                	mv	s1,a0
    800045c0:	89ae                	mv	s3,a1
	struct proc *p = myproc();
    800045c2:	ffffd097          	auipc	ra,0xffffd
    800045c6:	46a080e7          	jalr	1130(ra) # 80001a2c <myproc>
	struct stat st;

	if(f->type == FD_INODE || f->type == FD_DEVICE){
    800045ca:	409c                	lw	a5,0(s1)
    800045cc:	37f9                	addiw	a5,a5,-2
    800045ce:	4705                	li	a4,1
    800045d0:	04f76763          	bltu	a4,a5,8000461e <filestat+0x6e>
    800045d4:	892a                	mv	s2,a0
		ilock(f->ip);
    800045d6:	6c88                	ld	a0,24(s1)
    800045d8:	fffff097          	auipc	ra,0xfffff
    800045dc:	072080e7          	jalr	114(ra) # 8000364a <ilock>
		stati(f->ip, &st);
    800045e0:	fb840593          	addi	a1,s0,-72
    800045e4:	6c88                	ld	a0,24(s1)
    800045e6:	fffff097          	auipc	ra,0xfffff
    800045ea:	2ee080e7          	jalr	750(ra) # 800038d4 <stati>
		iunlock(f->ip);
    800045ee:	6c88                	ld	a0,24(s1)
    800045f0:	fffff097          	auipc	ra,0xfffff
    800045f4:	11c080e7          	jalr	284(ra) # 8000370c <iunlock>
		if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    800045f8:	46e1                	li	a3,24
    800045fa:	fb840613          	addi	a2,s0,-72
    800045fe:	85ce                	mv	a1,s3
    80004600:	05093503          	ld	a0,80(s2)
    80004604:	ffffd097          	auipc	ra,0xffffd
    80004608:	06e080e7          	jalr	110(ra) # 80001672 <copyout>
    8000460c:	41f5551b          	sraiw	a0,a0,0x1f
			return -1;
		return 0;
	}
	return -1;
}
    80004610:	60a6                	ld	ra,72(sp)
    80004612:	6406                	ld	s0,64(sp)
    80004614:	74e2                	ld	s1,56(sp)
    80004616:	7942                	ld	s2,48(sp)
    80004618:	79a2                	ld	s3,40(sp)
    8000461a:	6161                	addi	sp,sp,80
    8000461c:	8082                	ret
	return -1;
    8000461e:	557d                	li	a0,-1
    80004620:	bfc5                	j	80004610 <filestat+0x60>

0000000080004622 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004622:	7179                	addi	sp,sp,-48
    80004624:	f406                	sd	ra,40(sp)
    80004626:	f022                	sd	s0,32(sp)
    80004628:	ec26                	sd	s1,24(sp)
    8000462a:	e84a                	sd	s2,16(sp)
    8000462c:	e44e                	sd	s3,8(sp)
    8000462e:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004630:	00854783          	lbu	a5,8(a0)
    80004634:	c3d5                	beqz	a5,800046d8 <fileread+0xb6>
    80004636:	84aa                	mv	s1,a0
    80004638:	89ae                	mv	s3,a1
    8000463a:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    8000463c:	411c                	lw	a5,0(a0)
    8000463e:	4705                	li	a4,1
    80004640:	04e78963          	beq	a5,a4,80004692 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004644:	470d                	li	a4,3
    80004646:	04e78d63          	beq	a5,a4,800046a0 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    8000464a:	4709                	li	a4,2
    8000464c:	06e79e63          	bne	a5,a4,800046c8 <fileread+0xa6>
    ilock(f->ip);
    80004650:	6d08                	ld	a0,24(a0)
    80004652:	fffff097          	auipc	ra,0xfffff
    80004656:	ff8080e7          	jalr	-8(ra) # 8000364a <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    8000465a:	874a                	mv	a4,s2
    8000465c:	5094                	lw	a3,32(s1)
    8000465e:	864e                	mv	a2,s3
    80004660:	4585                	li	a1,1
    80004662:	6c88                	ld	a0,24(s1)
    80004664:	fffff097          	auipc	ra,0xfffff
    80004668:	29a080e7          	jalr	666(ra) # 800038fe <readi>
    8000466c:	892a                	mv	s2,a0
    8000466e:	00a05563          	blez	a0,80004678 <fileread+0x56>
      f->off += r;
    80004672:	509c                	lw	a5,32(s1)
    80004674:	9fa9                	addw	a5,a5,a0
    80004676:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004678:	6c88                	ld	a0,24(s1)
    8000467a:	fffff097          	auipc	ra,0xfffff
    8000467e:	092080e7          	jalr	146(ra) # 8000370c <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004682:	854a                	mv	a0,s2
    80004684:	70a2                	ld	ra,40(sp)
    80004686:	7402                	ld	s0,32(sp)
    80004688:	64e2                	ld	s1,24(sp)
    8000468a:	6942                	ld	s2,16(sp)
    8000468c:	69a2                	ld	s3,8(sp)
    8000468e:	6145                	addi	sp,sp,48
    80004690:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004692:	6908                	ld	a0,16(a0)
    80004694:	00000097          	auipc	ra,0x0
    80004698:	3c8080e7          	jalr	968(ra) # 80004a5c <piperead>
    8000469c:	892a                	mv	s2,a0
    8000469e:	b7d5                	j	80004682 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    800046a0:	02451783          	lh	a5,36(a0)
    800046a4:	03079693          	slli	a3,a5,0x30
    800046a8:	92c1                	srli	a3,a3,0x30
    800046aa:	4725                	li	a4,9
    800046ac:	02d76863          	bltu	a4,a3,800046dc <fileread+0xba>
    800046b0:	0792                	slli	a5,a5,0x4
    800046b2:	0001d717          	auipc	a4,0x1d
    800046b6:	c6670713          	addi	a4,a4,-922 # 80021318 <devsw>
    800046ba:	97ba                	add	a5,a5,a4
    800046bc:	639c                	ld	a5,0(a5)
    800046be:	c38d                	beqz	a5,800046e0 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    800046c0:	4505                	li	a0,1
    800046c2:	9782                	jalr	a5
    800046c4:	892a                	mv	s2,a0
    800046c6:	bf75                	j	80004682 <fileread+0x60>
    panic("fileread");
    800046c8:	00004517          	auipc	a0,0x4
    800046cc:	fe050513          	addi	a0,a0,-32 # 800086a8 <syscalls+0x258>
    800046d0:	ffffc097          	auipc	ra,0xffffc
    800046d4:	e6e080e7          	jalr	-402(ra) # 8000053e <panic>
    return -1;
    800046d8:	597d                	li	s2,-1
    800046da:	b765                	j	80004682 <fileread+0x60>
      return -1;
    800046dc:	597d                	li	s2,-1
    800046de:	b755                	j	80004682 <fileread+0x60>
    800046e0:	597d                	li	s2,-1
    800046e2:	b745                	j	80004682 <fileread+0x60>

00000000800046e4 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    800046e4:	715d                	addi	sp,sp,-80
    800046e6:	e486                	sd	ra,72(sp)
    800046e8:	e0a2                	sd	s0,64(sp)
    800046ea:	fc26                	sd	s1,56(sp)
    800046ec:	f84a                	sd	s2,48(sp)
    800046ee:	f44e                	sd	s3,40(sp)
    800046f0:	f052                	sd	s4,32(sp)
    800046f2:	ec56                	sd	s5,24(sp)
    800046f4:	e85a                	sd	s6,16(sp)
    800046f6:	e45e                	sd	s7,8(sp)
    800046f8:	e062                	sd	s8,0(sp)
    800046fa:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    800046fc:	00954783          	lbu	a5,9(a0)
    80004700:	10078663          	beqz	a5,8000480c <filewrite+0x128>
    80004704:	892a                	mv	s2,a0
    80004706:	8aae                	mv	s5,a1
    80004708:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    8000470a:	411c                	lw	a5,0(a0)
    8000470c:	4705                	li	a4,1
    8000470e:	02e78263          	beq	a5,a4,80004732 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004712:	470d                	li	a4,3
    80004714:	02e78663          	beq	a5,a4,80004740 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004718:	4709                	li	a4,2
    8000471a:	0ee79163          	bne	a5,a4,800047fc <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    8000471e:	0ac05d63          	blez	a2,800047d8 <filewrite+0xf4>
    int i = 0;
    80004722:	4981                	li	s3,0
    80004724:	6b05                	lui	s6,0x1
    80004726:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    8000472a:	6b85                	lui	s7,0x1
    8000472c:	c00b8b9b          	addiw	s7,s7,-1024
    80004730:	a861                	j	800047c8 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004732:	6908                	ld	a0,16(a0)
    80004734:	00000097          	auipc	ra,0x0
    80004738:	22e080e7          	jalr	558(ra) # 80004962 <pipewrite>
    8000473c:	8a2a                	mv	s4,a0
    8000473e:	a045                	j	800047de <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004740:	02451783          	lh	a5,36(a0)
    80004744:	03079693          	slli	a3,a5,0x30
    80004748:	92c1                	srli	a3,a3,0x30
    8000474a:	4725                	li	a4,9
    8000474c:	0cd76263          	bltu	a4,a3,80004810 <filewrite+0x12c>
    80004750:	0792                	slli	a5,a5,0x4
    80004752:	0001d717          	auipc	a4,0x1d
    80004756:	bc670713          	addi	a4,a4,-1082 # 80021318 <devsw>
    8000475a:	97ba                	add	a5,a5,a4
    8000475c:	679c                	ld	a5,8(a5)
    8000475e:	cbdd                	beqz	a5,80004814 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004760:	4505                	li	a0,1
    80004762:	9782                	jalr	a5
    80004764:	8a2a                	mv	s4,a0
    80004766:	a8a5                	j	800047de <filewrite+0xfa>
    80004768:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    8000476c:	00000097          	auipc	ra,0x0
    80004770:	8b0080e7          	jalr	-1872(ra) # 8000401c <begin_op>
      ilock(f->ip);
    80004774:	01893503          	ld	a0,24(s2)
    80004778:	fffff097          	auipc	ra,0xfffff
    8000477c:	ed2080e7          	jalr	-302(ra) # 8000364a <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004780:	8762                	mv	a4,s8
    80004782:	02092683          	lw	a3,32(s2)
    80004786:	01598633          	add	a2,s3,s5
    8000478a:	4585                	li	a1,1
    8000478c:	01893503          	ld	a0,24(s2)
    80004790:	fffff097          	auipc	ra,0xfffff
    80004794:	266080e7          	jalr	614(ra) # 800039f6 <writei>
    80004798:	84aa                	mv	s1,a0
    8000479a:	00a05763          	blez	a0,800047a8 <filewrite+0xc4>
        f->off += r;
    8000479e:	02092783          	lw	a5,32(s2)
    800047a2:	9fa9                	addw	a5,a5,a0
    800047a4:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    800047a8:	01893503          	ld	a0,24(s2)
    800047ac:	fffff097          	auipc	ra,0xfffff
    800047b0:	f60080e7          	jalr	-160(ra) # 8000370c <iunlock>
      end_op();
    800047b4:	00000097          	auipc	ra,0x0
    800047b8:	8e8080e7          	jalr	-1816(ra) # 8000409c <end_op>

      if(r != n1){
    800047bc:	009c1f63          	bne	s8,s1,800047da <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    800047c0:	013489bb          	addw	s3,s1,s3
    while(i < n){
    800047c4:	0149db63          	bge	s3,s4,800047da <filewrite+0xf6>
      int n1 = n - i;
    800047c8:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    800047cc:	84be                	mv	s1,a5
    800047ce:	2781                	sext.w	a5,a5
    800047d0:	f8fb5ce3          	bge	s6,a5,80004768 <filewrite+0x84>
    800047d4:	84de                	mv	s1,s7
    800047d6:	bf49                	j	80004768 <filewrite+0x84>
    int i = 0;
    800047d8:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    800047da:	013a1f63          	bne	s4,s3,800047f8 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    800047de:	8552                	mv	a0,s4
    800047e0:	60a6                	ld	ra,72(sp)
    800047e2:	6406                	ld	s0,64(sp)
    800047e4:	74e2                	ld	s1,56(sp)
    800047e6:	7942                	ld	s2,48(sp)
    800047e8:	79a2                	ld	s3,40(sp)
    800047ea:	7a02                	ld	s4,32(sp)
    800047ec:	6ae2                	ld	s5,24(sp)
    800047ee:	6b42                	ld	s6,16(sp)
    800047f0:	6ba2                	ld	s7,8(sp)
    800047f2:	6c02                	ld	s8,0(sp)
    800047f4:	6161                	addi	sp,sp,80
    800047f6:	8082                	ret
    ret = (i == n ? n : -1);
    800047f8:	5a7d                	li	s4,-1
    800047fa:	b7d5                	j	800047de <filewrite+0xfa>
    panic("filewrite");
    800047fc:	00004517          	auipc	a0,0x4
    80004800:	ebc50513          	addi	a0,a0,-324 # 800086b8 <syscalls+0x268>
    80004804:	ffffc097          	auipc	ra,0xffffc
    80004808:	d3a080e7          	jalr	-710(ra) # 8000053e <panic>
    return -1;
    8000480c:	5a7d                	li	s4,-1
    8000480e:	bfc1                	j	800047de <filewrite+0xfa>
      return -1;
    80004810:	5a7d                	li	s4,-1
    80004812:	b7f1                	j	800047de <filewrite+0xfa>
    80004814:	5a7d                	li	s4,-1
    80004816:	b7e1                	j	800047de <filewrite+0xfa>

0000000080004818 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004818:	7179                	addi	sp,sp,-48
    8000481a:	f406                	sd	ra,40(sp)
    8000481c:	f022                	sd	s0,32(sp)
    8000481e:	ec26                	sd	s1,24(sp)
    80004820:	e84a                	sd	s2,16(sp)
    80004822:	e44e                	sd	s3,8(sp)
    80004824:	e052                	sd	s4,0(sp)
    80004826:	1800                	addi	s0,sp,48
    80004828:	84aa                	mv	s1,a0
    8000482a:	8a2e                	mv	s4,a1
	struct pipe *pi;

	pi = 0;
	*f0 = *f1 = 0;
    8000482c:	0005b023          	sd	zero,0(a1)
    80004830:	00053023          	sd	zero,0(a0)
	if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004834:	00000097          	auipc	ra,0x0
    80004838:	bf8080e7          	jalr	-1032(ra) # 8000442c <filealloc>
    8000483c:	e088                	sd	a0,0(s1)
    8000483e:	c551                	beqz	a0,800048ca <pipealloc+0xb2>
    80004840:	00000097          	auipc	ra,0x0
    80004844:	bec080e7          	jalr	-1044(ra) # 8000442c <filealloc>
    80004848:	00aa3023          	sd	a0,0(s4)
    8000484c:	c92d                	beqz	a0,800048be <pipealloc+0xa6>
		goto bad;
	if((pi = (struct pipe*)kalloc()) == 0)
    8000484e:	ffffc097          	auipc	ra,0xffffc
    80004852:	2a6080e7          	jalr	678(ra) # 80000af4 <kalloc>
    80004856:	892a                	mv	s2,a0
    80004858:	c125                	beqz	a0,800048b8 <pipealloc+0xa0>
		goto bad;
	pi->readopen = 1;
    8000485a:	4985                	li	s3,1
    8000485c:	23352023          	sw	s3,544(a0)
	pi->writeopen = 1;
    80004860:	23352223          	sw	s3,548(a0)
	pi->nwrite = 0;
    80004864:	20052e23          	sw	zero,540(a0)
	pi->nread = 0;
    80004868:	20052c23          	sw	zero,536(a0)
	initlock(&pi->lock, "pipe");
    8000486c:	00004597          	auipc	a1,0x4
    80004870:	e5c58593          	addi	a1,a1,-420 # 800086c8 <syscalls+0x278>
    80004874:	ffffc097          	auipc	ra,0xffffc
    80004878:	2e0080e7          	jalr	736(ra) # 80000b54 <initlock>
	(*f0)->type = FD_PIPE;
    8000487c:	609c                	ld	a5,0(s1)
    8000487e:	0137a023          	sw	s3,0(a5)
	(*f0)->readable = 1;
    80004882:	609c                	ld	a5,0(s1)
    80004884:	01378423          	sb	s3,8(a5)
	(*f0)->writable = 0;
    80004888:	609c                	ld	a5,0(s1)
    8000488a:	000784a3          	sb	zero,9(a5)
	(*f0)->pipe = pi;
    8000488e:	609c                	ld	a5,0(s1)
    80004890:	0127b823          	sd	s2,16(a5)
	(*f1)->type = FD_PIPE;
    80004894:	000a3783          	ld	a5,0(s4)
    80004898:	0137a023          	sw	s3,0(a5)
	(*f1)->readable = 0;
    8000489c:	000a3783          	ld	a5,0(s4)
    800048a0:	00078423          	sb	zero,8(a5)
	(*f1)->writable = 1;
    800048a4:	000a3783          	ld	a5,0(s4)
    800048a8:	013784a3          	sb	s3,9(a5)
	(*f1)->pipe = pi;
    800048ac:	000a3783          	ld	a5,0(s4)
    800048b0:	0127b823          	sd	s2,16(a5)
	return 0;
    800048b4:	4501                	li	a0,0
    800048b6:	a025                	j	800048de <pipealloc+0xc6>

bad:
	if(pi)
		kfree((char*)pi);
	if(*f0)
    800048b8:	6088                	ld	a0,0(s1)
    800048ba:	e501                	bnez	a0,800048c2 <pipealloc+0xaa>
    800048bc:	a039                	j	800048ca <pipealloc+0xb2>
    800048be:	6088                	ld	a0,0(s1)
    800048c0:	c51d                	beqz	a0,800048ee <pipealloc+0xd6>
		fileclose(*f0);
    800048c2:	00000097          	auipc	ra,0x0
    800048c6:	c26080e7          	jalr	-986(ra) # 800044e8 <fileclose>
	if(*f1)
    800048ca:	000a3783          	ld	a5,0(s4)
		fileclose(*f1);
	return -1;
    800048ce:	557d                	li	a0,-1
	if(*f1)
    800048d0:	c799                	beqz	a5,800048de <pipealloc+0xc6>
		fileclose(*f1);
    800048d2:	853e                	mv	a0,a5
    800048d4:	00000097          	auipc	ra,0x0
    800048d8:	c14080e7          	jalr	-1004(ra) # 800044e8 <fileclose>
	return -1;
    800048dc:	557d                	li	a0,-1
}
    800048de:	70a2                	ld	ra,40(sp)
    800048e0:	7402                	ld	s0,32(sp)
    800048e2:	64e2                	ld	s1,24(sp)
    800048e4:	6942                	ld	s2,16(sp)
    800048e6:	69a2                	ld	s3,8(sp)
    800048e8:	6a02                	ld	s4,0(sp)
    800048ea:	6145                	addi	sp,sp,48
    800048ec:	8082                	ret
	return -1;
    800048ee:	557d                	li	a0,-1
    800048f0:	b7fd                	j	800048de <pipealloc+0xc6>

00000000800048f2 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    800048f2:	1101                	addi	sp,sp,-32
    800048f4:	ec06                	sd	ra,24(sp)
    800048f6:	e822                	sd	s0,16(sp)
    800048f8:	e426                	sd	s1,8(sp)
    800048fa:	e04a                	sd	s2,0(sp)
    800048fc:	1000                	addi	s0,sp,32
    800048fe:	84aa                	mv	s1,a0
    80004900:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004902:	ffffc097          	auipc	ra,0xffffc
    80004906:	2e2080e7          	jalr	738(ra) # 80000be4 <acquire>
  if(writable){
    8000490a:	02090d63          	beqz	s2,80004944 <pipeclose+0x52>
    pi->writeopen = 0;
    8000490e:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004912:	21848513          	addi	a0,s1,536
    80004916:	ffffe097          	auipc	ra,0xffffe
    8000491a:	95e080e7          	jalr	-1698(ra) # 80002274 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    8000491e:	2204b783          	ld	a5,544(s1)
    80004922:	eb95                	bnez	a5,80004956 <pipeclose+0x64>
    release(&pi->lock);
    80004924:	8526                	mv	a0,s1
    80004926:	ffffc097          	auipc	ra,0xffffc
    8000492a:	372080e7          	jalr	882(ra) # 80000c98 <release>
    kfree((char*)pi);
    8000492e:	8526                	mv	a0,s1
    80004930:	ffffc097          	auipc	ra,0xffffc
    80004934:	0c8080e7          	jalr	200(ra) # 800009f8 <kfree>
  } else
    release(&pi->lock);
}
    80004938:	60e2                	ld	ra,24(sp)
    8000493a:	6442                	ld	s0,16(sp)
    8000493c:	64a2                	ld	s1,8(sp)
    8000493e:	6902                	ld	s2,0(sp)
    80004940:	6105                	addi	sp,sp,32
    80004942:	8082                	ret
    pi->readopen = 0;
    80004944:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004948:	21c48513          	addi	a0,s1,540
    8000494c:	ffffe097          	auipc	ra,0xffffe
    80004950:	928080e7          	jalr	-1752(ra) # 80002274 <wakeup>
    80004954:	b7e9                	j	8000491e <pipeclose+0x2c>
    release(&pi->lock);
    80004956:	8526                	mv	a0,s1
    80004958:	ffffc097          	auipc	ra,0xffffc
    8000495c:	340080e7          	jalr	832(ra) # 80000c98 <release>
}
    80004960:	bfe1                	j	80004938 <pipeclose+0x46>

0000000080004962 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004962:	7159                	addi	sp,sp,-112
    80004964:	f486                	sd	ra,104(sp)
    80004966:	f0a2                	sd	s0,96(sp)
    80004968:	eca6                	sd	s1,88(sp)
    8000496a:	e8ca                	sd	s2,80(sp)
    8000496c:	e4ce                	sd	s3,72(sp)
    8000496e:	e0d2                	sd	s4,64(sp)
    80004970:	fc56                	sd	s5,56(sp)
    80004972:	f85a                	sd	s6,48(sp)
    80004974:	f45e                	sd	s7,40(sp)
    80004976:	f062                	sd	s8,32(sp)
    80004978:	ec66                	sd	s9,24(sp)
    8000497a:	1880                	addi	s0,sp,112
    8000497c:	84aa                	mv	s1,a0
    8000497e:	8aae                	mv	s5,a1
    80004980:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004982:	ffffd097          	auipc	ra,0xffffd
    80004986:	0aa080e7          	jalr	170(ra) # 80001a2c <myproc>
    8000498a:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    8000498c:	8526                	mv	a0,s1
    8000498e:	ffffc097          	auipc	ra,0xffffc
    80004992:	256080e7          	jalr	598(ra) # 80000be4 <acquire>
  while(i < n){
    80004996:	0d405163          	blez	s4,80004a58 <pipewrite+0xf6>
    8000499a:	8ba6                	mv	s7,s1
  int i = 0;
    8000499c:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    8000499e:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    800049a0:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    800049a4:	21c48c13          	addi	s8,s1,540
    800049a8:	a08d                	j	80004a0a <pipewrite+0xa8>
      release(&pi->lock);
    800049aa:	8526                	mv	a0,s1
    800049ac:	ffffc097          	auipc	ra,0xffffc
    800049b0:	2ec080e7          	jalr	748(ra) # 80000c98 <release>
      return -1;
    800049b4:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    800049b6:	854a                	mv	a0,s2
    800049b8:	70a6                	ld	ra,104(sp)
    800049ba:	7406                	ld	s0,96(sp)
    800049bc:	64e6                	ld	s1,88(sp)
    800049be:	6946                	ld	s2,80(sp)
    800049c0:	69a6                	ld	s3,72(sp)
    800049c2:	6a06                	ld	s4,64(sp)
    800049c4:	7ae2                	ld	s5,56(sp)
    800049c6:	7b42                	ld	s6,48(sp)
    800049c8:	7ba2                	ld	s7,40(sp)
    800049ca:	7c02                	ld	s8,32(sp)
    800049cc:	6ce2                	ld	s9,24(sp)
    800049ce:	6165                	addi	sp,sp,112
    800049d0:	8082                	ret
      wakeup(&pi->nread);
    800049d2:	8566                	mv	a0,s9
    800049d4:	ffffe097          	auipc	ra,0xffffe
    800049d8:	8a0080e7          	jalr	-1888(ra) # 80002274 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    800049dc:	85de                	mv	a1,s7
    800049de:	8562                	mv	a0,s8
    800049e0:	ffffd097          	auipc	ra,0xffffd
    800049e4:	708080e7          	jalr	1800(ra) # 800020e8 <sleep>
    800049e8:	a839                	j	80004a06 <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    800049ea:	21c4a783          	lw	a5,540(s1)
    800049ee:	0017871b          	addiw	a4,a5,1
    800049f2:	20e4ae23          	sw	a4,540(s1)
    800049f6:	1ff7f793          	andi	a5,a5,511
    800049fa:	97a6                	add	a5,a5,s1
    800049fc:	f9f44703          	lbu	a4,-97(s0)
    80004a00:	00e78c23          	sb	a4,24(a5)
      i++;
    80004a04:	2905                	addiw	s2,s2,1
  while(i < n){
    80004a06:	03495d63          	bge	s2,s4,80004a40 <pipewrite+0xde>
    if(pi->readopen == 0 || pr->killed){
    80004a0a:	2204a783          	lw	a5,544(s1)
    80004a0e:	dfd1                	beqz	a5,800049aa <pipewrite+0x48>
    80004a10:	0289a783          	lw	a5,40(s3)
    80004a14:	fbd9                	bnez	a5,800049aa <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004a16:	2184a783          	lw	a5,536(s1)
    80004a1a:	21c4a703          	lw	a4,540(s1)
    80004a1e:	2007879b          	addiw	a5,a5,512
    80004a22:	faf708e3          	beq	a4,a5,800049d2 <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004a26:	4685                	li	a3,1
    80004a28:	01590633          	add	a2,s2,s5
    80004a2c:	f9f40593          	addi	a1,s0,-97
    80004a30:	0509b503          	ld	a0,80(s3)
    80004a34:	ffffd097          	auipc	ra,0xffffd
    80004a38:	cca080e7          	jalr	-822(ra) # 800016fe <copyin>
    80004a3c:	fb6517e3          	bne	a0,s6,800049ea <pipewrite+0x88>
  wakeup(&pi->nread);
    80004a40:	21848513          	addi	a0,s1,536
    80004a44:	ffffe097          	auipc	ra,0xffffe
    80004a48:	830080e7          	jalr	-2000(ra) # 80002274 <wakeup>
  release(&pi->lock);
    80004a4c:	8526                	mv	a0,s1
    80004a4e:	ffffc097          	auipc	ra,0xffffc
    80004a52:	24a080e7          	jalr	586(ra) # 80000c98 <release>
  return i;
    80004a56:	b785                	j	800049b6 <pipewrite+0x54>
  int i = 0;
    80004a58:	4901                	li	s2,0
    80004a5a:	b7dd                	j	80004a40 <pipewrite+0xde>

0000000080004a5c <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004a5c:	715d                	addi	sp,sp,-80
    80004a5e:	e486                	sd	ra,72(sp)
    80004a60:	e0a2                	sd	s0,64(sp)
    80004a62:	fc26                	sd	s1,56(sp)
    80004a64:	f84a                	sd	s2,48(sp)
    80004a66:	f44e                	sd	s3,40(sp)
    80004a68:	f052                	sd	s4,32(sp)
    80004a6a:	ec56                	sd	s5,24(sp)
    80004a6c:	e85a                	sd	s6,16(sp)
    80004a6e:	0880                	addi	s0,sp,80
    80004a70:	84aa                	mv	s1,a0
    80004a72:	892e                	mv	s2,a1
    80004a74:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004a76:	ffffd097          	auipc	ra,0xffffd
    80004a7a:	fb6080e7          	jalr	-74(ra) # 80001a2c <myproc>
    80004a7e:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004a80:	8b26                	mv	s6,s1
    80004a82:	8526                	mv	a0,s1
    80004a84:	ffffc097          	auipc	ra,0xffffc
    80004a88:	160080e7          	jalr	352(ra) # 80000be4 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004a8c:	2184a703          	lw	a4,536(s1)
    80004a90:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004a94:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004a98:	02f71463          	bne	a4,a5,80004ac0 <piperead+0x64>
    80004a9c:	2244a783          	lw	a5,548(s1)
    80004aa0:	c385                	beqz	a5,80004ac0 <piperead+0x64>
    if(pr->killed){
    80004aa2:	028a2783          	lw	a5,40(s4)
    80004aa6:	ebc1                	bnez	a5,80004b36 <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004aa8:	85da                	mv	a1,s6
    80004aaa:	854e                	mv	a0,s3
    80004aac:	ffffd097          	auipc	ra,0xffffd
    80004ab0:	63c080e7          	jalr	1596(ra) # 800020e8 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004ab4:	2184a703          	lw	a4,536(s1)
    80004ab8:	21c4a783          	lw	a5,540(s1)
    80004abc:	fef700e3          	beq	a4,a5,80004a9c <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004ac0:	09505263          	blez	s5,80004b44 <piperead+0xe8>
    80004ac4:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004ac6:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80004ac8:	2184a783          	lw	a5,536(s1)
    80004acc:	21c4a703          	lw	a4,540(s1)
    80004ad0:	02f70d63          	beq	a4,a5,80004b0a <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004ad4:	0017871b          	addiw	a4,a5,1
    80004ad8:	20e4ac23          	sw	a4,536(s1)
    80004adc:	1ff7f793          	andi	a5,a5,511
    80004ae0:	97a6                	add	a5,a5,s1
    80004ae2:	0187c783          	lbu	a5,24(a5)
    80004ae6:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004aea:	4685                	li	a3,1
    80004aec:	fbf40613          	addi	a2,s0,-65
    80004af0:	85ca                	mv	a1,s2
    80004af2:	050a3503          	ld	a0,80(s4)
    80004af6:	ffffd097          	auipc	ra,0xffffd
    80004afa:	b7c080e7          	jalr	-1156(ra) # 80001672 <copyout>
    80004afe:	01650663          	beq	a0,s6,80004b0a <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004b02:	2985                	addiw	s3,s3,1
    80004b04:	0905                	addi	s2,s2,1
    80004b06:	fd3a91e3          	bne	s5,s3,80004ac8 <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004b0a:	21c48513          	addi	a0,s1,540
    80004b0e:	ffffd097          	auipc	ra,0xffffd
    80004b12:	766080e7          	jalr	1894(ra) # 80002274 <wakeup>
  release(&pi->lock);
    80004b16:	8526                	mv	a0,s1
    80004b18:	ffffc097          	auipc	ra,0xffffc
    80004b1c:	180080e7          	jalr	384(ra) # 80000c98 <release>
  return i;
}
    80004b20:	854e                	mv	a0,s3
    80004b22:	60a6                	ld	ra,72(sp)
    80004b24:	6406                	ld	s0,64(sp)
    80004b26:	74e2                	ld	s1,56(sp)
    80004b28:	7942                	ld	s2,48(sp)
    80004b2a:	79a2                	ld	s3,40(sp)
    80004b2c:	7a02                	ld	s4,32(sp)
    80004b2e:	6ae2                	ld	s5,24(sp)
    80004b30:	6b42                	ld	s6,16(sp)
    80004b32:	6161                	addi	sp,sp,80
    80004b34:	8082                	ret
      release(&pi->lock);
    80004b36:	8526                	mv	a0,s1
    80004b38:	ffffc097          	auipc	ra,0xffffc
    80004b3c:	160080e7          	jalr	352(ra) # 80000c98 <release>
      return -1;
    80004b40:	59fd                	li	s3,-1
    80004b42:	bff9                	j	80004b20 <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004b44:	4981                	li	s3,0
    80004b46:	b7d1                	j	80004b0a <piperead+0xae>

0000000080004b48 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004b48:	df010113          	addi	sp,sp,-528
    80004b4c:	20113423          	sd	ra,520(sp)
    80004b50:	20813023          	sd	s0,512(sp)
    80004b54:	ffa6                	sd	s1,504(sp)
    80004b56:	fbca                	sd	s2,496(sp)
    80004b58:	f7ce                	sd	s3,488(sp)
    80004b5a:	f3d2                	sd	s4,480(sp)
    80004b5c:	efd6                	sd	s5,472(sp)
    80004b5e:	ebda                	sd	s6,464(sp)
    80004b60:	e7de                	sd	s7,456(sp)
    80004b62:	e3e2                	sd	s8,448(sp)
    80004b64:	ff66                	sd	s9,440(sp)
    80004b66:	fb6a                	sd	s10,432(sp)
    80004b68:	f76e                	sd	s11,424(sp)
    80004b6a:	0c00                	addi	s0,sp,528
    80004b6c:	84aa                	mv	s1,a0
    80004b6e:	dea43c23          	sd	a0,-520(s0)
    80004b72:	e0b43023          	sd	a1,-512(s0)
	uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
	struct elfhdr elf;
	struct inode *ip;
	struct proghdr ph;
	pagetable_t pagetable = 0, oldpagetable;
	struct proc *p = myproc();
    80004b76:	ffffd097          	auipc	ra,0xffffd
    80004b7a:	eb6080e7          	jalr	-330(ra) # 80001a2c <myproc>
    80004b7e:	892a                	mv	s2,a0

	begin_op();
    80004b80:	fffff097          	auipc	ra,0xfffff
    80004b84:	49c080e7          	jalr	1180(ra) # 8000401c <begin_op>

	if((ip = namei(path)) == 0){
    80004b88:	8526                	mv	a0,s1
    80004b8a:	fffff097          	auipc	ra,0xfffff
    80004b8e:	276080e7          	jalr	630(ra) # 80003e00 <namei>
    80004b92:	c92d                	beqz	a0,80004c04 <exec+0xbc>
    80004b94:	84aa                	mv	s1,a0
		end_op();
		return -1;
	}
	ilock(ip);
    80004b96:	fffff097          	auipc	ra,0xfffff
    80004b9a:	ab4080e7          	jalr	-1356(ra) # 8000364a <ilock>

	// Check ELF header
	if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004b9e:	04000713          	li	a4,64
    80004ba2:	4681                	li	a3,0
    80004ba4:	e5040613          	addi	a2,s0,-432
    80004ba8:	4581                	li	a1,0
    80004baa:	8526                	mv	a0,s1
    80004bac:	fffff097          	auipc	ra,0xfffff
    80004bb0:	d52080e7          	jalr	-686(ra) # 800038fe <readi>
    80004bb4:	04000793          	li	a5,64
    80004bb8:	00f51a63          	bne	a0,a5,80004bcc <exec+0x84>
		goto bad;
	if(elf.magic != ELF_MAGIC)
    80004bbc:	e5042703          	lw	a4,-432(s0)
    80004bc0:	464c47b7          	lui	a5,0x464c4
    80004bc4:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004bc8:	04f70463          	beq	a4,a5,80004c10 <exec+0xc8>

bad:
	if(pagetable)
		proc_freepagetable(pagetable, sz);
	if(ip){
		iunlockput(ip);
    80004bcc:	8526                	mv	a0,s1
    80004bce:	fffff097          	auipc	ra,0xfffff
    80004bd2:	cde080e7          	jalr	-802(ra) # 800038ac <iunlockput>
		end_op();
    80004bd6:	fffff097          	auipc	ra,0xfffff
    80004bda:	4c6080e7          	jalr	1222(ra) # 8000409c <end_op>
	}
	return -1;
    80004bde:	557d                	li	a0,-1
}
    80004be0:	20813083          	ld	ra,520(sp)
    80004be4:	20013403          	ld	s0,512(sp)
    80004be8:	74fe                	ld	s1,504(sp)
    80004bea:	795e                	ld	s2,496(sp)
    80004bec:	79be                	ld	s3,488(sp)
    80004bee:	7a1e                	ld	s4,480(sp)
    80004bf0:	6afe                	ld	s5,472(sp)
    80004bf2:	6b5e                	ld	s6,464(sp)
    80004bf4:	6bbe                	ld	s7,456(sp)
    80004bf6:	6c1e                	ld	s8,448(sp)
    80004bf8:	7cfa                	ld	s9,440(sp)
    80004bfa:	7d5a                	ld	s10,432(sp)
    80004bfc:	7dba                	ld	s11,424(sp)
    80004bfe:	21010113          	addi	sp,sp,528
    80004c02:	8082                	ret
		end_op();
    80004c04:	fffff097          	auipc	ra,0xfffff
    80004c08:	498080e7          	jalr	1176(ra) # 8000409c <end_op>
		return -1;
    80004c0c:	557d                	li	a0,-1
    80004c0e:	bfc9                	j	80004be0 <exec+0x98>
	if((pagetable = proc_pagetable(p)) == 0)
    80004c10:	854a                	mv	a0,s2
    80004c12:	ffffd097          	auipc	ra,0xffffd
    80004c16:	ede080e7          	jalr	-290(ra) # 80001af0 <proc_pagetable>
    80004c1a:	8baa                	mv	s7,a0
    80004c1c:	d945                	beqz	a0,80004bcc <exec+0x84>
	for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004c1e:	e7042983          	lw	s3,-400(s0)
    80004c22:	e8845783          	lhu	a5,-376(s0)
    80004c26:	c7ad                	beqz	a5,80004c90 <exec+0x148>
	uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004c28:	4901                	li	s2,0
	for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004c2a:	4b01                	li	s6,0
		if((ph.vaddr % PGSIZE) != 0)
    80004c2c:	6c85                	lui	s9,0x1
    80004c2e:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80004c32:	def43823          	sd	a5,-528(s0)
    80004c36:	a42d                	j	80004e60 <exec+0x318>
	uint64 pa;

	for(i = 0; i < sz; i += PGSIZE){
		pa = walkaddr(pagetable, va + i);
		if(pa == 0)
			panic("loadseg: address should exist");
    80004c38:	00004517          	auipc	a0,0x4
    80004c3c:	a9850513          	addi	a0,a0,-1384 # 800086d0 <syscalls+0x280>
    80004c40:	ffffc097          	auipc	ra,0xffffc
    80004c44:	8fe080e7          	jalr	-1794(ra) # 8000053e <panic>
		if(sz - i < PGSIZE)
			n = sz - i;
		else
			n = PGSIZE;
		if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004c48:	8756                	mv	a4,s5
    80004c4a:	012d86bb          	addw	a3,s11,s2
    80004c4e:	4581                	li	a1,0
    80004c50:	8526                	mv	a0,s1
    80004c52:	fffff097          	auipc	ra,0xfffff
    80004c56:	cac080e7          	jalr	-852(ra) # 800038fe <readi>
    80004c5a:	2501                	sext.w	a0,a0
    80004c5c:	1aaa9963          	bne	s5,a0,80004e0e <exec+0x2c6>
	for(i = 0; i < sz; i += PGSIZE){
    80004c60:	6785                	lui	a5,0x1
    80004c62:	0127893b          	addw	s2,a5,s2
    80004c66:	77fd                	lui	a5,0xfffff
    80004c68:	01478a3b          	addw	s4,a5,s4
    80004c6c:	1f897163          	bgeu	s2,s8,80004e4e <exec+0x306>
		pa = walkaddr(pagetable, va + i);
    80004c70:	02091593          	slli	a1,s2,0x20
    80004c74:	9181                	srli	a1,a1,0x20
    80004c76:	95ea                	add	a1,a1,s10
    80004c78:	855e                	mv	a0,s7
    80004c7a:	ffffc097          	auipc	ra,0xffffc
    80004c7e:	3f4080e7          	jalr	1012(ra) # 8000106e <walkaddr>
    80004c82:	862a                	mv	a2,a0
		if(pa == 0)
    80004c84:	d955                	beqz	a0,80004c38 <exec+0xf0>
			n = PGSIZE;
    80004c86:	8ae6                	mv	s5,s9
		if(sz - i < PGSIZE)
    80004c88:	fd9a70e3          	bgeu	s4,s9,80004c48 <exec+0x100>
			n = sz - i;
    80004c8c:	8ad2                	mv	s5,s4
    80004c8e:	bf6d                	j	80004c48 <exec+0x100>
	uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004c90:	4901                	li	s2,0
	iunlockput(ip);
    80004c92:	8526                	mv	a0,s1
    80004c94:	fffff097          	auipc	ra,0xfffff
    80004c98:	c18080e7          	jalr	-1000(ra) # 800038ac <iunlockput>
	end_op();
    80004c9c:	fffff097          	auipc	ra,0xfffff
    80004ca0:	400080e7          	jalr	1024(ra) # 8000409c <end_op>
	p = myproc();
    80004ca4:	ffffd097          	auipc	ra,0xffffd
    80004ca8:	d88080e7          	jalr	-632(ra) # 80001a2c <myproc>
    80004cac:	8aaa                	mv	s5,a0
	uint64 oldsz = p->sz;
    80004cae:	04853d03          	ld	s10,72(a0)
	sz = PGROUNDUP(sz);
    80004cb2:	6785                	lui	a5,0x1
    80004cb4:	17fd                	addi	a5,a5,-1
    80004cb6:	993e                	add	s2,s2,a5
    80004cb8:	757d                	lui	a0,0xfffff
    80004cba:	00a977b3          	and	a5,s2,a0
    80004cbe:	e0f43423          	sd	a5,-504(s0)
	if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004cc2:	6609                	lui	a2,0x2
    80004cc4:	963e                	add	a2,a2,a5
    80004cc6:	85be                	mv	a1,a5
    80004cc8:	855e                	mv	a0,s7
    80004cca:	ffffc097          	auipc	ra,0xffffc
    80004cce:	758080e7          	jalr	1880(ra) # 80001422 <uvmalloc>
    80004cd2:	8b2a                	mv	s6,a0
	ip = 0;
    80004cd4:	4481                	li	s1,0
	if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004cd6:	12050c63          	beqz	a0,80004e0e <exec+0x2c6>
	uvmclear(pagetable, sz-2*PGSIZE);
    80004cda:	75f9                	lui	a1,0xffffe
    80004cdc:	95aa                	add	a1,a1,a0
    80004cde:	855e                	mv	a0,s7
    80004ce0:	ffffd097          	auipc	ra,0xffffd
    80004ce4:	960080e7          	jalr	-1696(ra) # 80001640 <uvmclear>
	stackbase = sp - PGSIZE;
    80004ce8:	7c7d                	lui	s8,0xfffff
    80004cea:	9c5a                	add	s8,s8,s6
	for(argc = 0; argv[argc]; argc++) {
    80004cec:	e0043783          	ld	a5,-512(s0)
    80004cf0:	6388                	ld	a0,0(a5)
    80004cf2:	c535                	beqz	a0,80004d5e <exec+0x216>
    80004cf4:	e9040993          	addi	s3,s0,-368
    80004cf8:	f9040c93          	addi	s9,s0,-112
	sp = sz;
    80004cfc:	895a                	mv	s2,s6
		sp -= strlen(argv[argc]) + 1;
    80004cfe:	ffffc097          	auipc	ra,0xffffc
    80004d02:	166080e7          	jalr	358(ra) # 80000e64 <strlen>
    80004d06:	2505                	addiw	a0,a0,1
    80004d08:	40a90933          	sub	s2,s2,a0
		sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004d0c:	ff097913          	andi	s2,s2,-16
		if(sp < stackbase)
    80004d10:	13896363          	bltu	s2,s8,80004e36 <exec+0x2ee>
		if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004d14:	e0043d83          	ld	s11,-512(s0)
    80004d18:	000dba03          	ld	s4,0(s11)
    80004d1c:	8552                	mv	a0,s4
    80004d1e:	ffffc097          	auipc	ra,0xffffc
    80004d22:	146080e7          	jalr	326(ra) # 80000e64 <strlen>
    80004d26:	0015069b          	addiw	a3,a0,1
    80004d2a:	8652                	mv	a2,s4
    80004d2c:	85ca                	mv	a1,s2
    80004d2e:	855e                	mv	a0,s7
    80004d30:	ffffd097          	auipc	ra,0xffffd
    80004d34:	942080e7          	jalr	-1726(ra) # 80001672 <copyout>
    80004d38:	10054363          	bltz	a0,80004e3e <exec+0x2f6>
		ustack[argc] = sp;
    80004d3c:	0129b023          	sd	s2,0(s3)
	for(argc = 0; argv[argc]; argc++) {
    80004d40:	0485                	addi	s1,s1,1
    80004d42:	008d8793          	addi	a5,s11,8
    80004d46:	e0f43023          	sd	a5,-512(s0)
    80004d4a:	008db503          	ld	a0,8(s11)
    80004d4e:	c911                	beqz	a0,80004d62 <exec+0x21a>
		if(argc >= MAXARG)
    80004d50:	09a1                	addi	s3,s3,8
    80004d52:	fb3c96e3          	bne	s9,s3,80004cfe <exec+0x1b6>
	sz = sz1;
    80004d56:	e1643423          	sd	s6,-504(s0)
	ip = 0;
    80004d5a:	4481                	li	s1,0
    80004d5c:	a84d                	j	80004e0e <exec+0x2c6>
	sp = sz;
    80004d5e:	895a                	mv	s2,s6
	for(argc = 0; argv[argc]; argc++) {
    80004d60:	4481                	li	s1,0
	ustack[argc] = 0;
    80004d62:	00349793          	slli	a5,s1,0x3
    80004d66:	f9040713          	addi	a4,s0,-112
    80004d6a:	97ba                	add	a5,a5,a4
    80004d6c:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
	sp -= (argc+1) * sizeof(uint64);
    80004d70:	00148693          	addi	a3,s1,1
    80004d74:	068e                	slli	a3,a3,0x3
    80004d76:	40d90933          	sub	s2,s2,a3
	sp -= sp % 16;
    80004d7a:	ff097913          	andi	s2,s2,-16
	if(sp < stackbase)
    80004d7e:	01897663          	bgeu	s2,s8,80004d8a <exec+0x242>
	sz = sz1;
    80004d82:	e1643423          	sd	s6,-504(s0)
	ip = 0;
    80004d86:	4481                	li	s1,0
    80004d88:	a059                	j	80004e0e <exec+0x2c6>
	if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004d8a:	e9040613          	addi	a2,s0,-368
    80004d8e:	85ca                	mv	a1,s2
    80004d90:	855e                	mv	a0,s7
    80004d92:	ffffd097          	auipc	ra,0xffffd
    80004d96:	8e0080e7          	jalr	-1824(ra) # 80001672 <copyout>
    80004d9a:	0a054663          	bltz	a0,80004e46 <exec+0x2fe>
	p->trapframe->a1 = sp;
    80004d9e:	058ab783          	ld	a5,88(s5)
    80004da2:	0727bc23          	sd	s2,120(a5)
	for(last=s=path; *s; s++)
    80004da6:	df843783          	ld	a5,-520(s0)
    80004daa:	0007c703          	lbu	a4,0(a5)
    80004dae:	cf11                	beqz	a4,80004dca <exec+0x282>
    80004db0:	0785                	addi	a5,a5,1
		if(*s == '/')
    80004db2:	02f00693          	li	a3,47
    80004db6:	a039                	j	80004dc4 <exec+0x27c>
			last = s+1;
    80004db8:	def43c23          	sd	a5,-520(s0)
	for(last=s=path; *s; s++)
    80004dbc:	0785                	addi	a5,a5,1
    80004dbe:	fff7c703          	lbu	a4,-1(a5)
    80004dc2:	c701                	beqz	a4,80004dca <exec+0x282>
		if(*s == '/')
    80004dc4:	fed71ce3          	bne	a4,a3,80004dbc <exec+0x274>
    80004dc8:	bfc5                	j	80004db8 <exec+0x270>
	safestrcpy(p->name, last, sizeof(p->name));
    80004dca:	4641                	li	a2,16
    80004dcc:	df843583          	ld	a1,-520(s0)
    80004dd0:	158a8513          	addi	a0,s5,344
    80004dd4:	ffffc097          	auipc	ra,0xffffc
    80004dd8:	05e080e7          	jalr	94(ra) # 80000e32 <safestrcpy>
	oldpagetable = p->pagetable;
    80004ddc:	050ab503          	ld	a0,80(s5)
	p->pagetable = pagetable;
    80004de0:	057ab823          	sd	s7,80(s5)
	p->sz = sz;
    80004de4:	056ab423          	sd	s6,72(s5)
	p->trapframe->epc = elf.entry;  // initial program counter = main
    80004de8:	058ab783          	ld	a5,88(s5)
    80004dec:	e6843703          	ld	a4,-408(s0)
    80004df0:	ef98                	sd	a4,24(a5)
	p->trapframe->sp = sp; // initial stack pointer
    80004df2:	058ab783          	ld	a5,88(s5)
    80004df6:	0327b823          	sd	s2,48(a5)
	proc_freepagetable(oldpagetable, oldsz);
    80004dfa:	85ea                	mv	a1,s10
    80004dfc:	ffffd097          	auipc	ra,0xffffd
    80004e00:	d90080e7          	jalr	-624(ra) # 80001b8c <proc_freepagetable>
	return argc; // this ends up in a0, the first argument to main(argc, argv)
    80004e04:	0004851b          	sext.w	a0,s1
    80004e08:	bbe1                	j	80004be0 <exec+0x98>
    80004e0a:	e1243423          	sd	s2,-504(s0)
		proc_freepagetable(pagetable, sz);
    80004e0e:	e0843583          	ld	a1,-504(s0)
    80004e12:	855e                	mv	a0,s7
    80004e14:	ffffd097          	auipc	ra,0xffffd
    80004e18:	d78080e7          	jalr	-648(ra) # 80001b8c <proc_freepagetable>
	if(ip){
    80004e1c:	da0498e3          	bnez	s1,80004bcc <exec+0x84>
	return -1;
    80004e20:	557d                	li	a0,-1
    80004e22:	bb7d                	j	80004be0 <exec+0x98>
    80004e24:	e1243423          	sd	s2,-504(s0)
    80004e28:	b7dd                	j	80004e0e <exec+0x2c6>
    80004e2a:	e1243423          	sd	s2,-504(s0)
    80004e2e:	b7c5                	j	80004e0e <exec+0x2c6>
    80004e30:	e1243423          	sd	s2,-504(s0)
    80004e34:	bfe9                	j	80004e0e <exec+0x2c6>
	sz = sz1;
    80004e36:	e1643423          	sd	s6,-504(s0)
	ip = 0;
    80004e3a:	4481                	li	s1,0
    80004e3c:	bfc9                	j	80004e0e <exec+0x2c6>
	sz = sz1;
    80004e3e:	e1643423          	sd	s6,-504(s0)
	ip = 0;
    80004e42:	4481                	li	s1,0
    80004e44:	b7e9                	j	80004e0e <exec+0x2c6>
	sz = sz1;
    80004e46:	e1643423          	sd	s6,-504(s0)
	ip = 0;
    80004e4a:	4481                	li	s1,0
    80004e4c:	b7c9                	j	80004e0e <exec+0x2c6>
		if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80004e4e:	e0843903          	ld	s2,-504(s0)
	for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004e52:	2b05                	addiw	s6,s6,1
    80004e54:	0389899b          	addiw	s3,s3,56
    80004e58:	e8845783          	lhu	a5,-376(s0)
    80004e5c:	e2fb5be3          	bge	s6,a5,80004c92 <exec+0x14a>
		if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80004e60:	2981                	sext.w	s3,s3
    80004e62:	03800713          	li	a4,56
    80004e66:	86ce                	mv	a3,s3
    80004e68:	e1840613          	addi	a2,s0,-488
    80004e6c:	4581                	li	a1,0
    80004e6e:	8526                	mv	a0,s1
    80004e70:	fffff097          	auipc	ra,0xfffff
    80004e74:	a8e080e7          	jalr	-1394(ra) # 800038fe <readi>
    80004e78:	03800793          	li	a5,56
    80004e7c:	f8f517e3          	bne	a0,a5,80004e0a <exec+0x2c2>
		if(ph.type != ELF_PROG_LOAD)
    80004e80:	e1842783          	lw	a5,-488(s0)
    80004e84:	4705                	li	a4,1
    80004e86:	fce796e3          	bne	a5,a4,80004e52 <exec+0x30a>
		if(ph.memsz < ph.filesz)
    80004e8a:	e4043603          	ld	a2,-448(s0)
    80004e8e:	e3843783          	ld	a5,-456(s0)
    80004e92:	f8f669e3          	bltu	a2,a5,80004e24 <exec+0x2dc>
		if(ph.vaddr + ph.memsz < ph.vaddr)	// オーバーフロー
    80004e96:	e2843783          	ld	a5,-472(s0)
    80004e9a:	963e                	add	a2,a2,a5
    80004e9c:	f8f667e3          	bltu	a2,a5,80004e2a <exec+0x2e2>
		if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80004ea0:	85ca                	mv	a1,s2
    80004ea2:	855e                	mv	a0,s7
    80004ea4:	ffffc097          	auipc	ra,0xffffc
    80004ea8:	57e080e7          	jalr	1406(ra) # 80001422 <uvmalloc>
    80004eac:	e0a43423          	sd	a0,-504(s0)
    80004eb0:	d141                	beqz	a0,80004e30 <exec+0x2e8>
		if((ph.vaddr % PGSIZE) != 0)
    80004eb2:	e2843d03          	ld	s10,-472(s0)
    80004eb6:	df043783          	ld	a5,-528(s0)
    80004eba:	00fd77b3          	and	a5,s10,a5
    80004ebe:	fba1                	bnez	a5,80004e0e <exec+0x2c6>
		if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80004ec0:	e2042d83          	lw	s11,-480(s0)
    80004ec4:	e3842c03          	lw	s8,-456(s0)
	for(i = 0; i < sz; i += PGSIZE){
    80004ec8:	f80c03e3          	beqz	s8,80004e4e <exec+0x306>
    80004ecc:	8a62                	mv	s4,s8
    80004ece:	4901                	li	s2,0
    80004ed0:	b345                	j	80004c70 <exec+0x128>

0000000080004ed2 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80004ed2:	7179                	addi	sp,sp,-48
    80004ed4:	f406                	sd	ra,40(sp)
    80004ed6:	f022                	sd	s0,32(sp)
    80004ed8:	ec26                	sd	s1,24(sp)
    80004eda:	e84a                	sd	s2,16(sp)
    80004edc:	1800                	addi	s0,sp,48
    80004ede:	892e                	mv	s2,a1
    80004ee0:	84b2                	mv	s1,a2
	int fd;
	struct file *f;

	if(argint(n, &fd) < 0)
    80004ee2:	fdc40593          	addi	a1,s0,-36
    80004ee6:	ffffe097          	auipc	ra,0xffffe
    80004eea:	bf2080e7          	jalr	-1038(ra) # 80002ad8 <argint>
    80004eee:	04054063          	bltz	a0,80004f2e <argfd+0x5c>
		return -1;
	if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80004ef2:	fdc42703          	lw	a4,-36(s0)
    80004ef6:	47bd                	li	a5,15
    80004ef8:	02e7ed63          	bltu	a5,a4,80004f32 <argfd+0x60>
    80004efc:	ffffd097          	auipc	ra,0xffffd
    80004f00:	b30080e7          	jalr	-1232(ra) # 80001a2c <myproc>
    80004f04:	fdc42703          	lw	a4,-36(s0)
    80004f08:	01a70793          	addi	a5,a4,26
    80004f0c:	078e                	slli	a5,a5,0x3
    80004f0e:	953e                	add	a0,a0,a5
    80004f10:	611c                	ld	a5,0(a0)
    80004f12:	c395                	beqz	a5,80004f36 <argfd+0x64>
		return -1;
	if(pfd)
    80004f14:	00090463          	beqz	s2,80004f1c <argfd+0x4a>
		*pfd = fd;
    80004f18:	00e92023          	sw	a4,0(s2)
	if(pf)
		*pf = f;
	return 0;
    80004f1c:	4501                	li	a0,0
	if(pf)
    80004f1e:	c091                	beqz	s1,80004f22 <argfd+0x50>
		*pf = f;
    80004f20:	e09c                	sd	a5,0(s1)
}
    80004f22:	70a2                	ld	ra,40(sp)
    80004f24:	7402                	ld	s0,32(sp)
    80004f26:	64e2                	ld	s1,24(sp)
    80004f28:	6942                	ld	s2,16(sp)
    80004f2a:	6145                	addi	sp,sp,48
    80004f2c:	8082                	ret
		return -1;
    80004f2e:	557d                	li	a0,-1
    80004f30:	bfcd                	j	80004f22 <argfd+0x50>
		return -1;
    80004f32:	557d                	li	a0,-1
    80004f34:	b7fd                	j	80004f22 <argfd+0x50>
    80004f36:	557d                	li	a0,-1
    80004f38:	b7ed                	j	80004f22 <argfd+0x50>

0000000080004f3a <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80004f3a:	1101                	addi	sp,sp,-32
    80004f3c:	ec06                	sd	ra,24(sp)
    80004f3e:	e822                	sd	s0,16(sp)
    80004f40:	e426                	sd	s1,8(sp)
    80004f42:	1000                	addi	s0,sp,32
    80004f44:	84aa                	mv	s1,a0
	int fd;
	struct proc *p = myproc();
    80004f46:	ffffd097          	auipc	ra,0xffffd
    80004f4a:	ae6080e7          	jalr	-1306(ra) # 80001a2c <myproc>
    80004f4e:	862a                	mv	a2,a0

	for(fd = 0; fd < NOFILE; fd++){
    80004f50:	0d050793          	addi	a5,a0,208 # fffffffffffff0d0 <end+0xffffffff7ffd90d0>
    80004f54:	4501                	li	a0,0
    80004f56:	46c1                	li	a3,16
		if(p->ofile[fd] == 0){
    80004f58:	6398                	ld	a4,0(a5)
    80004f5a:	cb19                	beqz	a4,80004f70 <fdalloc+0x36>
	for(fd = 0; fd < NOFILE; fd++){
    80004f5c:	2505                	addiw	a0,a0,1
    80004f5e:	07a1                	addi	a5,a5,8
    80004f60:	fed51ce3          	bne	a0,a3,80004f58 <fdalloc+0x1e>
			p->ofile[fd] = f;
			return fd;
		}
	}
	return -1;
    80004f64:	557d                	li	a0,-1
}
    80004f66:	60e2                	ld	ra,24(sp)
    80004f68:	6442                	ld	s0,16(sp)
    80004f6a:	64a2                	ld	s1,8(sp)
    80004f6c:	6105                	addi	sp,sp,32
    80004f6e:	8082                	ret
			p->ofile[fd] = f;
    80004f70:	01a50793          	addi	a5,a0,26
    80004f74:	078e                	slli	a5,a5,0x3
    80004f76:	963e                	add	a2,a2,a5
    80004f78:	e204                	sd	s1,0(a2)
			return fd;
    80004f7a:	b7f5                	j	80004f66 <fdalloc+0x2c>

0000000080004f7c <create>:
	return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80004f7c:	715d                	addi	sp,sp,-80
    80004f7e:	e486                	sd	ra,72(sp)
    80004f80:	e0a2                	sd	s0,64(sp)
    80004f82:	fc26                	sd	s1,56(sp)
    80004f84:	f84a                	sd	s2,48(sp)
    80004f86:	f44e                	sd	s3,40(sp)
    80004f88:	f052                	sd	s4,32(sp)
    80004f8a:	ec56                	sd	s5,24(sp)
    80004f8c:	0880                	addi	s0,sp,80
    80004f8e:	89ae                	mv	s3,a1
    80004f90:	8ab2                	mv	s5,a2
    80004f92:	8a36                	mv	s4,a3
	struct inode *ip, *dp;
	char name[DIRSIZ];

	if((dp = nameiparent(path, name)) == 0)
    80004f94:	fb040593          	addi	a1,s0,-80
    80004f98:	fffff097          	auipc	ra,0xfffff
    80004f9c:	e86080e7          	jalr	-378(ra) # 80003e1e <nameiparent>
    80004fa0:	892a                	mv	s2,a0
    80004fa2:	12050f63          	beqz	a0,800050e0 <create+0x164>
		return 0;

	ilock(dp);
    80004fa6:	ffffe097          	auipc	ra,0xffffe
    80004faa:	6a4080e7          	jalr	1700(ra) # 8000364a <ilock>

	if((ip = dirlookup(dp, name, 0)) != 0){
    80004fae:	4601                	li	a2,0
    80004fb0:	fb040593          	addi	a1,s0,-80
    80004fb4:	854a                	mv	a0,s2
    80004fb6:	fffff097          	auipc	ra,0xfffff
    80004fba:	b78080e7          	jalr	-1160(ra) # 80003b2e <dirlookup>
    80004fbe:	84aa                	mv	s1,a0
    80004fc0:	c921                	beqz	a0,80005010 <create+0x94>
		iunlockput(dp);
    80004fc2:	854a                	mv	a0,s2
    80004fc4:	fffff097          	auipc	ra,0xfffff
    80004fc8:	8e8080e7          	jalr	-1816(ra) # 800038ac <iunlockput>
		ilock(ip);
    80004fcc:	8526                	mv	a0,s1
    80004fce:	ffffe097          	auipc	ra,0xffffe
    80004fd2:	67c080e7          	jalr	1660(ra) # 8000364a <ilock>
		if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80004fd6:	2981                	sext.w	s3,s3
    80004fd8:	4789                	li	a5,2
    80004fda:	02f99463          	bne	s3,a5,80005002 <create+0x86>
    80004fde:	0444d783          	lhu	a5,68(s1)
    80004fe2:	37f9                	addiw	a5,a5,-2
    80004fe4:	17c2                	slli	a5,a5,0x30
    80004fe6:	93c1                	srli	a5,a5,0x30
    80004fe8:	4705                	li	a4,1
    80004fea:	00f76c63          	bltu	a4,a5,80005002 <create+0x86>
		panic("create: dirlink");

	iunlockput(dp);

	return ip;
}
    80004fee:	8526                	mv	a0,s1
    80004ff0:	60a6                	ld	ra,72(sp)
    80004ff2:	6406                	ld	s0,64(sp)
    80004ff4:	74e2                	ld	s1,56(sp)
    80004ff6:	7942                	ld	s2,48(sp)
    80004ff8:	79a2                	ld	s3,40(sp)
    80004ffa:	7a02                	ld	s4,32(sp)
    80004ffc:	6ae2                	ld	s5,24(sp)
    80004ffe:	6161                	addi	sp,sp,80
    80005000:	8082                	ret
		iunlockput(ip);
    80005002:	8526                	mv	a0,s1
    80005004:	fffff097          	auipc	ra,0xfffff
    80005008:	8a8080e7          	jalr	-1880(ra) # 800038ac <iunlockput>
		return 0;
    8000500c:	4481                	li	s1,0
    8000500e:	b7c5                	j	80004fee <create+0x72>
	if((ip = ialloc(dp->dev, type)) == 0)
    80005010:	85ce                	mv	a1,s3
    80005012:	00092503          	lw	a0,0(s2)
    80005016:	ffffe097          	auipc	ra,0xffffe
    8000501a:	49c080e7          	jalr	1180(ra) # 800034b2 <ialloc>
    8000501e:	84aa                	mv	s1,a0
    80005020:	c529                	beqz	a0,8000506a <create+0xee>
	ilock(ip);
    80005022:	ffffe097          	auipc	ra,0xffffe
    80005026:	628080e7          	jalr	1576(ra) # 8000364a <ilock>
	ip->major = major;
    8000502a:	05549323          	sh	s5,70(s1)
	ip->minor = minor;
    8000502e:	05449423          	sh	s4,72(s1)
	ip->nlink = 1;
    80005032:	4785                	li	a5,1
    80005034:	04f49523          	sh	a5,74(s1)
	iupdate(ip);
    80005038:	8526                	mv	a0,s1
    8000503a:	ffffe097          	auipc	ra,0xffffe
    8000503e:	546080e7          	jalr	1350(ra) # 80003580 <iupdate>
	if(type == T_DIR){  // Create . and .. entries.
    80005042:	2981                	sext.w	s3,s3
    80005044:	4785                	li	a5,1
    80005046:	02f98a63          	beq	s3,a5,8000507a <create+0xfe>
	if(dirlink(dp, name, ip->inum) < 0)
    8000504a:	40d0                	lw	a2,4(s1)
    8000504c:	fb040593          	addi	a1,s0,-80
    80005050:	854a                	mv	a0,s2
    80005052:	fffff097          	auipc	ra,0xfffff
    80005056:	cec080e7          	jalr	-788(ra) # 80003d3e <dirlink>
    8000505a:	06054b63          	bltz	a0,800050d0 <create+0x154>
	iunlockput(dp);
    8000505e:	854a                	mv	a0,s2
    80005060:	fffff097          	auipc	ra,0xfffff
    80005064:	84c080e7          	jalr	-1972(ra) # 800038ac <iunlockput>
	return ip;
    80005068:	b759                	j	80004fee <create+0x72>
		panic("create: ialloc");
    8000506a:	00003517          	auipc	a0,0x3
    8000506e:	68650513          	addi	a0,a0,1670 # 800086f0 <syscalls+0x2a0>
    80005072:	ffffb097          	auipc	ra,0xffffb
    80005076:	4cc080e7          	jalr	1228(ra) # 8000053e <panic>
		dp->nlink++;  // for ".."
    8000507a:	04a95783          	lhu	a5,74(s2)
    8000507e:	2785                	addiw	a5,a5,1
    80005080:	04f91523          	sh	a5,74(s2)
		iupdate(dp);
    80005084:	854a                	mv	a0,s2
    80005086:	ffffe097          	auipc	ra,0xffffe
    8000508a:	4fa080e7          	jalr	1274(ra) # 80003580 <iupdate>
		if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    8000508e:	40d0                	lw	a2,4(s1)
    80005090:	00003597          	auipc	a1,0x3
    80005094:	67058593          	addi	a1,a1,1648 # 80008700 <syscalls+0x2b0>
    80005098:	8526                	mv	a0,s1
    8000509a:	fffff097          	auipc	ra,0xfffff
    8000509e:	ca4080e7          	jalr	-860(ra) # 80003d3e <dirlink>
    800050a2:	00054f63          	bltz	a0,800050c0 <create+0x144>
    800050a6:	00492603          	lw	a2,4(s2)
    800050aa:	00003597          	auipc	a1,0x3
    800050ae:	65e58593          	addi	a1,a1,1630 # 80008708 <syscalls+0x2b8>
    800050b2:	8526                	mv	a0,s1
    800050b4:	fffff097          	auipc	ra,0xfffff
    800050b8:	c8a080e7          	jalr	-886(ra) # 80003d3e <dirlink>
    800050bc:	f80557e3          	bgez	a0,8000504a <create+0xce>
			panic("create dots");
    800050c0:	00003517          	auipc	a0,0x3
    800050c4:	65050513          	addi	a0,a0,1616 # 80008710 <syscalls+0x2c0>
    800050c8:	ffffb097          	auipc	ra,0xffffb
    800050cc:	476080e7          	jalr	1142(ra) # 8000053e <panic>
		panic("create: dirlink");
    800050d0:	00003517          	auipc	a0,0x3
    800050d4:	65050513          	addi	a0,a0,1616 # 80008720 <syscalls+0x2d0>
    800050d8:	ffffb097          	auipc	ra,0xffffb
    800050dc:	466080e7          	jalr	1126(ra) # 8000053e <panic>
		return 0;
    800050e0:	84aa                	mv	s1,a0
    800050e2:	b731                	j	80004fee <create+0x72>

00000000800050e4 <sys_dup>:
{
    800050e4:	7179                	addi	sp,sp,-48
    800050e6:	f406                	sd	ra,40(sp)
    800050e8:	f022                	sd	s0,32(sp)
    800050ea:	ec26                	sd	s1,24(sp)
    800050ec:	1800                	addi	s0,sp,48
	if(argfd(0, 0, &f) < 0)
    800050ee:	fd840613          	addi	a2,s0,-40
    800050f2:	4581                	li	a1,0
    800050f4:	4501                	li	a0,0
    800050f6:	00000097          	auipc	ra,0x0
    800050fa:	ddc080e7          	jalr	-548(ra) # 80004ed2 <argfd>
		return -1;
    800050fe:	57fd                	li	a5,-1
	if(argfd(0, 0, &f) < 0)
    80005100:	02054363          	bltz	a0,80005126 <sys_dup+0x42>
	if((fd=fdalloc(f)) < 0)
    80005104:	fd843503          	ld	a0,-40(s0)
    80005108:	00000097          	auipc	ra,0x0
    8000510c:	e32080e7          	jalr	-462(ra) # 80004f3a <fdalloc>
    80005110:	84aa                	mv	s1,a0
		return -1;
    80005112:	57fd                	li	a5,-1
	if((fd=fdalloc(f)) < 0)
    80005114:	00054963          	bltz	a0,80005126 <sys_dup+0x42>
	filedup(f);
    80005118:	fd843503          	ld	a0,-40(s0)
    8000511c:	fffff097          	auipc	ra,0xfffff
    80005120:	37a080e7          	jalr	890(ra) # 80004496 <filedup>
	return fd;
    80005124:	87a6                	mv	a5,s1
}
    80005126:	853e                	mv	a0,a5
    80005128:	70a2                	ld	ra,40(sp)
    8000512a:	7402                	ld	s0,32(sp)
    8000512c:	64e2                	ld	s1,24(sp)
    8000512e:	6145                	addi	sp,sp,48
    80005130:	8082                	ret

0000000080005132 <sys_read>:
{
    80005132:	7179                	addi	sp,sp,-48
    80005134:	f406                	sd	ra,40(sp)
    80005136:	f022                	sd	s0,32(sp)
    80005138:	1800                	addi	s0,sp,48
	if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000513a:	fe840613          	addi	a2,s0,-24
    8000513e:	4581                	li	a1,0
    80005140:	4501                	li	a0,0
    80005142:	00000097          	auipc	ra,0x0
    80005146:	d90080e7          	jalr	-624(ra) # 80004ed2 <argfd>
		return -1;
    8000514a:	57fd                	li	a5,-1
	if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000514c:	04054163          	bltz	a0,8000518e <sys_read+0x5c>
    80005150:	fe440593          	addi	a1,s0,-28
    80005154:	4509                	li	a0,2
    80005156:	ffffe097          	auipc	ra,0xffffe
    8000515a:	982080e7          	jalr	-1662(ra) # 80002ad8 <argint>
		return -1;
    8000515e:	57fd                	li	a5,-1
	if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005160:	02054763          	bltz	a0,8000518e <sys_read+0x5c>
    80005164:	fd840593          	addi	a1,s0,-40
    80005168:	4505                	li	a0,1
    8000516a:	ffffe097          	auipc	ra,0xffffe
    8000516e:	990080e7          	jalr	-1648(ra) # 80002afa <argaddr>
		return -1;
    80005172:	57fd                	li	a5,-1
	if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005174:	00054d63          	bltz	a0,8000518e <sys_read+0x5c>
	return fileread(f, p, n);
    80005178:	fe442603          	lw	a2,-28(s0)
    8000517c:	fd843583          	ld	a1,-40(s0)
    80005180:	fe843503          	ld	a0,-24(s0)
    80005184:	fffff097          	auipc	ra,0xfffff
    80005188:	49e080e7          	jalr	1182(ra) # 80004622 <fileread>
    8000518c:	87aa                	mv	a5,a0
}
    8000518e:	853e                	mv	a0,a5
    80005190:	70a2                	ld	ra,40(sp)
    80005192:	7402                	ld	s0,32(sp)
    80005194:	6145                	addi	sp,sp,48
    80005196:	8082                	ret

0000000080005198 <sys_write>:
{
    80005198:	7179                	addi	sp,sp,-48
    8000519a:	f406                	sd	ra,40(sp)
    8000519c:	f022                	sd	s0,32(sp)
    8000519e:	1800                	addi	s0,sp,48
	if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800051a0:	fe840613          	addi	a2,s0,-24
    800051a4:	4581                	li	a1,0
    800051a6:	4501                	li	a0,0
    800051a8:	00000097          	auipc	ra,0x0
    800051ac:	d2a080e7          	jalr	-726(ra) # 80004ed2 <argfd>
		return -1;
    800051b0:	57fd                	li	a5,-1
	if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800051b2:	04054163          	bltz	a0,800051f4 <sys_write+0x5c>
    800051b6:	fe440593          	addi	a1,s0,-28
    800051ba:	4509                	li	a0,2
    800051bc:	ffffe097          	auipc	ra,0xffffe
    800051c0:	91c080e7          	jalr	-1764(ra) # 80002ad8 <argint>
		return -1;
    800051c4:	57fd                	li	a5,-1
	if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800051c6:	02054763          	bltz	a0,800051f4 <sys_write+0x5c>
    800051ca:	fd840593          	addi	a1,s0,-40
    800051ce:	4505                	li	a0,1
    800051d0:	ffffe097          	auipc	ra,0xffffe
    800051d4:	92a080e7          	jalr	-1750(ra) # 80002afa <argaddr>
		return -1;
    800051d8:	57fd                	li	a5,-1
	if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800051da:	00054d63          	bltz	a0,800051f4 <sys_write+0x5c>
	return filewrite(f, p, n);
    800051de:	fe442603          	lw	a2,-28(s0)
    800051e2:	fd843583          	ld	a1,-40(s0)
    800051e6:	fe843503          	ld	a0,-24(s0)
    800051ea:	fffff097          	auipc	ra,0xfffff
    800051ee:	4fa080e7          	jalr	1274(ra) # 800046e4 <filewrite>
    800051f2:	87aa                	mv	a5,a0
}
    800051f4:	853e                	mv	a0,a5
    800051f6:	70a2                	ld	ra,40(sp)
    800051f8:	7402                	ld	s0,32(sp)
    800051fa:	6145                	addi	sp,sp,48
    800051fc:	8082                	ret

00000000800051fe <sys_close>:
{
    800051fe:	1101                	addi	sp,sp,-32
    80005200:	ec06                	sd	ra,24(sp)
    80005202:	e822                	sd	s0,16(sp)
    80005204:	1000                	addi	s0,sp,32
	if(argfd(0, &fd, &f) < 0)
    80005206:	fe040613          	addi	a2,s0,-32
    8000520a:	fec40593          	addi	a1,s0,-20
    8000520e:	4501                	li	a0,0
    80005210:	00000097          	auipc	ra,0x0
    80005214:	cc2080e7          	jalr	-830(ra) # 80004ed2 <argfd>
		return -1;
    80005218:	57fd                	li	a5,-1
	if(argfd(0, &fd, &f) < 0)
    8000521a:	02054463          	bltz	a0,80005242 <sys_close+0x44>
	myproc()->ofile[fd] = 0;
    8000521e:	ffffd097          	auipc	ra,0xffffd
    80005222:	80e080e7          	jalr	-2034(ra) # 80001a2c <myproc>
    80005226:	fec42783          	lw	a5,-20(s0)
    8000522a:	07e9                	addi	a5,a5,26
    8000522c:	078e                	slli	a5,a5,0x3
    8000522e:	97aa                	add	a5,a5,a0
    80005230:	0007b023          	sd	zero,0(a5)
	fileclose(f);
    80005234:	fe043503          	ld	a0,-32(s0)
    80005238:	fffff097          	auipc	ra,0xfffff
    8000523c:	2b0080e7          	jalr	688(ra) # 800044e8 <fileclose>
	return 0;
    80005240:	4781                	li	a5,0
}
    80005242:	853e                	mv	a0,a5
    80005244:	60e2                	ld	ra,24(sp)
    80005246:	6442                	ld	s0,16(sp)
    80005248:	6105                	addi	sp,sp,32
    8000524a:	8082                	ret

000000008000524c <sys_fstat>:
{
    8000524c:	1101                	addi	sp,sp,-32
    8000524e:	ec06                	sd	ra,24(sp)
    80005250:	e822                	sd	s0,16(sp)
    80005252:	1000                	addi	s0,sp,32
	if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005254:	fe840613          	addi	a2,s0,-24
    80005258:	4581                	li	a1,0
    8000525a:	4501                	li	a0,0
    8000525c:	00000097          	auipc	ra,0x0
    80005260:	c76080e7          	jalr	-906(ra) # 80004ed2 <argfd>
		return -1;
    80005264:	57fd                	li	a5,-1
	if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005266:	02054563          	bltz	a0,80005290 <sys_fstat+0x44>
    8000526a:	fe040593          	addi	a1,s0,-32
    8000526e:	4505                	li	a0,1
    80005270:	ffffe097          	auipc	ra,0xffffe
    80005274:	88a080e7          	jalr	-1910(ra) # 80002afa <argaddr>
		return -1;
    80005278:	57fd                	li	a5,-1
	if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000527a:	00054b63          	bltz	a0,80005290 <sys_fstat+0x44>
	return filestat(f, st);
    8000527e:	fe043583          	ld	a1,-32(s0)
    80005282:	fe843503          	ld	a0,-24(s0)
    80005286:	fffff097          	auipc	ra,0xfffff
    8000528a:	32a080e7          	jalr	810(ra) # 800045b0 <filestat>
    8000528e:	87aa                	mv	a5,a0
}
    80005290:	853e                	mv	a0,a5
    80005292:	60e2                	ld	ra,24(sp)
    80005294:	6442                	ld	s0,16(sp)
    80005296:	6105                	addi	sp,sp,32
    80005298:	8082                	ret

000000008000529a <sys_link>:
{
    8000529a:	7169                	addi	sp,sp,-304
    8000529c:	f606                	sd	ra,296(sp)
    8000529e:	f222                	sd	s0,288(sp)
    800052a0:	ee26                	sd	s1,280(sp)
    800052a2:	ea4a                	sd	s2,272(sp)
    800052a4:	1a00                	addi	s0,sp,304
	if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800052a6:	08000613          	li	a2,128
    800052aa:	ed040593          	addi	a1,s0,-304
    800052ae:	4501                	li	a0,0
    800052b0:	ffffe097          	auipc	ra,0xffffe
    800052b4:	86c080e7          	jalr	-1940(ra) # 80002b1c <argstr>
		return -1;
    800052b8:	57fd                	li	a5,-1
	if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800052ba:	10054e63          	bltz	a0,800053d6 <sys_link+0x13c>
    800052be:	08000613          	li	a2,128
    800052c2:	f5040593          	addi	a1,s0,-176
    800052c6:	4505                	li	a0,1
    800052c8:	ffffe097          	auipc	ra,0xffffe
    800052cc:	854080e7          	jalr	-1964(ra) # 80002b1c <argstr>
		return -1;
    800052d0:	57fd                	li	a5,-1
	if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800052d2:	10054263          	bltz	a0,800053d6 <sys_link+0x13c>
	begin_op();
    800052d6:	fffff097          	auipc	ra,0xfffff
    800052da:	d46080e7          	jalr	-698(ra) # 8000401c <begin_op>
	if((ip = namei(old)) == 0){
    800052de:	ed040513          	addi	a0,s0,-304
    800052e2:	fffff097          	auipc	ra,0xfffff
    800052e6:	b1e080e7          	jalr	-1250(ra) # 80003e00 <namei>
    800052ea:	84aa                	mv	s1,a0
    800052ec:	c551                	beqz	a0,80005378 <sys_link+0xde>
	ilock(ip);
    800052ee:	ffffe097          	auipc	ra,0xffffe
    800052f2:	35c080e7          	jalr	860(ra) # 8000364a <ilock>
	if(ip->type == T_DIR){
    800052f6:	04449703          	lh	a4,68(s1)
    800052fa:	4785                	li	a5,1
    800052fc:	08f70463          	beq	a4,a5,80005384 <sys_link+0xea>
	ip->nlink++;
    80005300:	04a4d783          	lhu	a5,74(s1)
    80005304:	2785                	addiw	a5,a5,1
    80005306:	04f49523          	sh	a5,74(s1)
	iupdate(ip);
    8000530a:	8526                	mv	a0,s1
    8000530c:	ffffe097          	auipc	ra,0xffffe
    80005310:	274080e7          	jalr	628(ra) # 80003580 <iupdate>
	iunlock(ip);
    80005314:	8526                	mv	a0,s1
    80005316:	ffffe097          	auipc	ra,0xffffe
    8000531a:	3f6080e7          	jalr	1014(ra) # 8000370c <iunlock>
	if((dp = nameiparent(new, name)) == 0)
    8000531e:	fd040593          	addi	a1,s0,-48
    80005322:	f5040513          	addi	a0,s0,-176
    80005326:	fffff097          	auipc	ra,0xfffff
    8000532a:	af8080e7          	jalr	-1288(ra) # 80003e1e <nameiparent>
    8000532e:	892a                	mv	s2,a0
    80005330:	c935                	beqz	a0,800053a4 <sys_link+0x10a>
	ilock(dp);
    80005332:	ffffe097          	auipc	ra,0xffffe
    80005336:	318080e7          	jalr	792(ra) # 8000364a <ilock>
	if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    8000533a:	00092703          	lw	a4,0(s2)
    8000533e:	409c                	lw	a5,0(s1)
    80005340:	04f71d63          	bne	a4,a5,8000539a <sys_link+0x100>
    80005344:	40d0                	lw	a2,4(s1)
    80005346:	fd040593          	addi	a1,s0,-48
    8000534a:	854a                	mv	a0,s2
    8000534c:	fffff097          	auipc	ra,0xfffff
    80005350:	9f2080e7          	jalr	-1550(ra) # 80003d3e <dirlink>
    80005354:	04054363          	bltz	a0,8000539a <sys_link+0x100>
	iunlockput(dp);
    80005358:	854a                	mv	a0,s2
    8000535a:	ffffe097          	auipc	ra,0xffffe
    8000535e:	552080e7          	jalr	1362(ra) # 800038ac <iunlockput>
	iput(ip);
    80005362:	8526                	mv	a0,s1
    80005364:	ffffe097          	auipc	ra,0xffffe
    80005368:	4a0080e7          	jalr	1184(ra) # 80003804 <iput>
	end_op();
    8000536c:	fffff097          	auipc	ra,0xfffff
    80005370:	d30080e7          	jalr	-720(ra) # 8000409c <end_op>
	return 0;
    80005374:	4781                	li	a5,0
    80005376:	a085                	j	800053d6 <sys_link+0x13c>
		end_op();
    80005378:	fffff097          	auipc	ra,0xfffff
    8000537c:	d24080e7          	jalr	-732(ra) # 8000409c <end_op>
		return -1;
    80005380:	57fd                	li	a5,-1
    80005382:	a891                	j	800053d6 <sys_link+0x13c>
		iunlockput(ip);
    80005384:	8526                	mv	a0,s1
    80005386:	ffffe097          	auipc	ra,0xffffe
    8000538a:	526080e7          	jalr	1318(ra) # 800038ac <iunlockput>
		end_op();
    8000538e:	fffff097          	auipc	ra,0xfffff
    80005392:	d0e080e7          	jalr	-754(ra) # 8000409c <end_op>
		return -1;
    80005396:	57fd                	li	a5,-1
    80005398:	a83d                	j	800053d6 <sys_link+0x13c>
		iunlockput(dp);
    8000539a:	854a                	mv	a0,s2
    8000539c:	ffffe097          	auipc	ra,0xffffe
    800053a0:	510080e7          	jalr	1296(ra) # 800038ac <iunlockput>
	ilock(ip);
    800053a4:	8526                	mv	a0,s1
    800053a6:	ffffe097          	auipc	ra,0xffffe
    800053aa:	2a4080e7          	jalr	676(ra) # 8000364a <ilock>
	ip->nlink--;
    800053ae:	04a4d783          	lhu	a5,74(s1)
    800053b2:	37fd                	addiw	a5,a5,-1
    800053b4:	04f49523          	sh	a5,74(s1)
	iupdate(ip);
    800053b8:	8526                	mv	a0,s1
    800053ba:	ffffe097          	auipc	ra,0xffffe
    800053be:	1c6080e7          	jalr	454(ra) # 80003580 <iupdate>
	iunlockput(ip);
    800053c2:	8526                	mv	a0,s1
    800053c4:	ffffe097          	auipc	ra,0xffffe
    800053c8:	4e8080e7          	jalr	1256(ra) # 800038ac <iunlockput>
	end_op();
    800053cc:	fffff097          	auipc	ra,0xfffff
    800053d0:	cd0080e7          	jalr	-816(ra) # 8000409c <end_op>
	return -1;
    800053d4:	57fd                	li	a5,-1
}
    800053d6:	853e                	mv	a0,a5
    800053d8:	70b2                	ld	ra,296(sp)
    800053da:	7412                	ld	s0,288(sp)
    800053dc:	64f2                	ld	s1,280(sp)
    800053de:	6952                	ld	s2,272(sp)
    800053e0:	6155                	addi	sp,sp,304
    800053e2:	8082                	ret

00000000800053e4 <sys_unlink>:
{
    800053e4:	7151                	addi	sp,sp,-240
    800053e6:	f586                	sd	ra,232(sp)
    800053e8:	f1a2                	sd	s0,224(sp)
    800053ea:	eda6                	sd	s1,216(sp)
    800053ec:	e9ca                	sd	s2,208(sp)
    800053ee:	e5ce                	sd	s3,200(sp)
    800053f0:	1980                	addi	s0,sp,240
	if(argstr(0, path, MAXPATH) < 0)
    800053f2:	08000613          	li	a2,128
    800053f6:	f3040593          	addi	a1,s0,-208
    800053fa:	4501                	li	a0,0
    800053fc:	ffffd097          	auipc	ra,0xffffd
    80005400:	720080e7          	jalr	1824(ra) # 80002b1c <argstr>
    80005404:	18054163          	bltz	a0,80005586 <sys_unlink+0x1a2>
	begin_op();
    80005408:	fffff097          	auipc	ra,0xfffff
    8000540c:	c14080e7          	jalr	-1004(ra) # 8000401c <begin_op>
	if((dp = nameiparent(path, name)) == 0){
    80005410:	fb040593          	addi	a1,s0,-80
    80005414:	f3040513          	addi	a0,s0,-208
    80005418:	fffff097          	auipc	ra,0xfffff
    8000541c:	a06080e7          	jalr	-1530(ra) # 80003e1e <nameiparent>
    80005420:	84aa                	mv	s1,a0
    80005422:	c979                	beqz	a0,800054f8 <sys_unlink+0x114>
	ilock(dp);
    80005424:	ffffe097          	auipc	ra,0xffffe
    80005428:	226080e7          	jalr	550(ra) # 8000364a <ilock>
	if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    8000542c:	00003597          	auipc	a1,0x3
    80005430:	2d458593          	addi	a1,a1,724 # 80008700 <syscalls+0x2b0>
    80005434:	fb040513          	addi	a0,s0,-80
    80005438:	ffffe097          	auipc	ra,0xffffe
    8000543c:	6dc080e7          	jalr	1756(ra) # 80003b14 <namecmp>
    80005440:	14050a63          	beqz	a0,80005594 <sys_unlink+0x1b0>
    80005444:	00003597          	auipc	a1,0x3
    80005448:	2c458593          	addi	a1,a1,708 # 80008708 <syscalls+0x2b8>
    8000544c:	fb040513          	addi	a0,s0,-80
    80005450:	ffffe097          	auipc	ra,0xffffe
    80005454:	6c4080e7          	jalr	1732(ra) # 80003b14 <namecmp>
    80005458:	12050e63          	beqz	a0,80005594 <sys_unlink+0x1b0>
	if((ip = dirlookup(dp, name, &off)) == 0)
    8000545c:	f2c40613          	addi	a2,s0,-212
    80005460:	fb040593          	addi	a1,s0,-80
    80005464:	8526                	mv	a0,s1
    80005466:	ffffe097          	auipc	ra,0xffffe
    8000546a:	6c8080e7          	jalr	1736(ra) # 80003b2e <dirlookup>
    8000546e:	892a                	mv	s2,a0
    80005470:	12050263          	beqz	a0,80005594 <sys_unlink+0x1b0>
	ilock(ip);
    80005474:	ffffe097          	auipc	ra,0xffffe
    80005478:	1d6080e7          	jalr	470(ra) # 8000364a <ilock>
	if(ip->nlink < 1)
    8000547c:	04a91783          	lh	a5,74(s2)
    80005480:	08f05263          	blez	a5,80005504 <sys_unlink+0x120>
	if(ip->type == T_DIR && !isdirempty(ip)){
    80005484:	04491703          	lh	a4,68(s2)
    80005488:	4785                	li	a5,1
    8000548a:	08f70563          	beq	a4,a5,80005514 <sys_unlink+0x130>
	memset(&de, 0, sizeof(de));
    8000548e:	4641                	li	a2,16
    80005490:	4581                	li	a1,0
    80005492:	fc040513          	addi	a0,s0,-64
    80005496:	ffffc097          	auipc	ra,0xffffc
    8000549a:	84a080e7          	jalr	-1974(ra) # 80000ce0 <memset>
	if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000549e:	4741                	li	a4,16
    800054a0:	f2c42683          	lw	a3,-212(s0)
    800054a4:	fc040613          	addi	a2,s0,-64
    800054a8:	4581                	li	a1,0
    800054aa:	8526                	mv	a0,s1
    800054ac:	ffffe097          	auipc	ra,0xffffe
    800054b0:	54a080e7          	jalr	1354(ra) # 800039f6 <writei>
    800054b4:	47c1                	li	a5,16
    800054b6:	0af51563          	bne	a0,a5,80005560 <sys_unlink+0x17c>
	if(ip->type == T_DIR){
    800054ba:	04491703          	lh	a4,68(s2)
    800054be:	4785                	li	a5,1
    800054c0:	0af70863          	beq	a4,a5,80005570 <sys_unlink+0x18c>
	iunlockput(dp);
    800054c4:	8526                	mv	a0,s1
    800054c6:	ffffe097          	auipc	ra,0xffffe
    800054ca:	3e6080e7          	jalr	998(ra) # 800038ac <iunlockput>
	ip->nlink--;
    800054ce:	04a95783          	lhu	a5,74(s2)
    800054d2:	37fd                	addiw	a5,a5,-1
    800054d4:	04f91523          	sh	a5,74(s2)
	iupdate(ip);
    800054d8:	854a                	mv	a0,s2
    800054da:	ffffe097          	auipc	ra,0xffffe
    800054de:	0a6080e7          	jalr	166(ra) # 80003580 <iupdate>
	iunlockput(ip);
    800054e2:	854a                	mv	a0,s2
    800054e4:	ffffe097          	auipc	ra,0xffffe
    800054e8:	3c8080e7          	jalr	968(ra) # 800038ac <iunlockput>
	end_op();
    800054ec:	fffff097          	auipc	ra,0xfffff
    800054f0:	bb0080e7          	jalr	-1104(ra) # 8000409c <end_op>
	return 0;
    800054f4:	4501                	li	a0,0
    800054f6:	a84d                	j	800055a8 <sys_unlink+0x1c4>
		end_op();
    800054f8:	fffff097          	auipc	ra,0xfffff
    800054fc:	ba4080e7          	jalr	-1116(ra) # 8000409c <end_op>
		return -1;
    80005500:	557d                	li	a0,-1
    80005502:	a05d                	j	800055a8 <sys_unlink+0x1c4>
		panic("unlink: nlink < 1");
    80005504:	00003517          	auipc	a0,0x3
    80005508:	22c50513          	addi	a0,a0,556 # 80008730 <syscalls+0x2e0>
    8000550c:	ffffb097          	auipc	ra,0xffffb
    80005510:	032080e7          	jalr	50(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005514:	04c92703          	lw	a4,76(s2)
    80005518:	02000793          	li	a5,32
    8000551c:	f6e7f9e3          	bgeu	a5,a4,8000548e <sys_unlink+0xaa>
    80005520:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005524:	4741                	li	a4,16
    80005526:	86ce                	mv	a3,s3
    80005528:	f1840613          	addi	a2,s0,-232
    8000552c:	4581                	li	a1,0
    8000552e:	854a                	mv	a0,s2
    80005530:	ffffe097          	auipc	ra,0xffffe
    80005534:	3ce080e7          	jalr	974(ra) # 800038fe <readi>
    80005538:	47c1                	li	a5,16
    8000553a:	00f51b63          	bne	a0,a5,80005550 <sys_unlink+0x16c>
    if(de.inum != 0)
    8000553e:	f1845783          	lhu	a5,-232(s0)
    80005542:	e7a1                	bnez	a5,8000558a <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005544:	29c1                	addiw	s3,s3,16
    80005546:	04c92783          	lw	a5,76(s2)
    8000554a:	fcf9ede3          	bltu	s3,a5,80005524 <sys_unlink+0x140>
    8000554e:	b781                	j	8000548e <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005550:	00003517          	auipc	a0,0x3
    80005554:	1f850513          	addi	a0,a0,504 # 80008748 <syscalls+0x2f8>
    80005558:	ffffb097          	auipc	ra,0xffffb
    8000555c:	fe6080e7          	jalr	-26(ra) # 8000053e <panic>
		panic("unlink: writei");
    80005560:	00003517          	auipc	a0,0x3
    80005564:	20050513          	addi	a0,a0,512 # 80008760 <syscalls+0x310>
    80005568:	ffffb097          	auipc	ra,0xffffb
    8000556c:	fd6080e7          	jalr	-42(ra) # 8000053e <panic>
		dp->nlink--;
    80005570:	04a4d783          	lhu	a5,74(s1)
    80005574:	37fd                	addiw	a5,a5,-1
    80005576:	04f49523          	sh	a5,74(s1)
		iupdate(dp);
    8000557a:	8526                	mv	a0,s1
    8000557c:	ffffe097          	auipc	ra,0xffffe
    80005580:	004080e7          	jalr	4(ra) # 80003580 <iupdate>
    80005584:	b781                	j	800054c4 <sys_unlink+0xe0>
		return -1;
    80005586:	557d                	li	a0,-1
    80005588:	a005                	j	800055a8 <sys_unlink+0x1c4>
		iunlockput(ip);
    8000558a:	854a                	mv	a0,s2
    8000558c:	ffffe097          	auipc	ra,0xffffe
    80005590:	320080e7          	jalr	800(ra) # 800038ac <iunlockput>
	iunlockput(dp);
    80005594:	8526                	mv	a0,s1
    80005596:	ffffe097          	auipc	ra,0xffffe
    8000559a:	316080e7          	jalr	790(ra) # 800038ac <iunlockput>
	end_op();
    8000559e:	fffff097          	auipc	ra,0xfffff
    800055a2:	afe080e7          	jalr	-1282(ra) # 8000409c <end_op>
	return -1;
    800055a6:	557d                	li	a0,-1
}
    800055a8:	70ae                	ld	ra,232(sp)
    800055aa:	740e                	ld	s0,224(sp)
    800055ac:	64ee                	ld	s1,216(sp)
    800055ae:	694e                	ld	s2,208(sp)
    800055b0:	69ae                	ld	s3,200(sp)
    800055b2:	616d                	addi	sp,sp,240
    800055b4:	8082                	ret

00000000800055b6 <sys_open>:

uint64
sys_open(void)
{
    800055b6:	7131                	addi	sp,sp,-192
    800055b8:	fd06                	sd	ra,184(sp)
    800055ba:	f922                	sd	s0,176(sp)
    800055bc:	f526                	sd	s1,168(sp)
    800055be:	f14a                	sd	s2,160(sp)
    800055c0:	ed4e                	sd	s3,152(sp)
    800055c2:	0180                	addi	s0,sp,192
	int fd, omode;
	struct file *f;
	struct inode *ip;
	int n;

	if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    800055c4:	08000613          	li	a2,128
    800055c8:	f5040593          	addi	a1,s0,-176
    800055cc:	4501                	li	a0,0
    800055ce:	ffffd097          	auipc	ra,0xffffd
    800055d2:	54e080e7          	jalr	1358(ra) # 80002b1c <argstr>
		return -1;
    800055d6:	54fd                	li	s1,-1
	if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    800055d8:	0c054163          	bltz	a0,8000569a <sys_open+0xe4>
    800055dc:	f4c40593          	addi	a1,s0,-180
    800055e0:	4505                	li	a0,1
    800055e2:	ffffd097          	auipc	ra,0xffffd
    800055e6:	4f6080e7          	jalr	1270(ra) # 80002ad8 <argint>
    800055ea:	0a054863          	bltz	a0,8000569a <sys_open+0xe4>

	begin_op();
    800055ee:	fffff097          	auipc	ra,0xfffff
    800055f2:	a2e080e7          	jalr	-1490(ra) # 8000401c <begin_op>

	if(omode & O_CREATE){
    800055f6:	f4c42783          	lw	a5,-180(s0)
    800055fa:	2007f793          	andi	a5,a5,512
    800055fe:	cbdd                	beqz	a5,800056b4 <sys_open+0xfe>
		ip = create(path, T_FILE, 0, 0);
    80005600:	4681                	li	a3,0
    80005602:	4601                	li	a2,0
    80005604:	4589                	li	a1,2
    80005606:	f5040513          	addi	a0,s0,-176
    8000560a:	00000097          	auipc	ra,0x0
    8000560e:	972080e7          	jalr	-1678(ra) # 80004f7c <create>
    80005612:	892a                	mv	s2,a0
		if(ip == 0){
    80005614:	c959                	beqz	a0,800056aa <sys_open+0xf4>
			end_op();
			return -1;
		}
	}

	if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005616:	04491703          	lh	a4,68(s2)
    8000561a:	478d                	li	a5,3
    8000561c:	00f71763          	bne	a4,a5,8000562a <sys_open+0x74>
    80005620:	04695703          	lhu	a4,70(s2)
    80005624:	47a5                	li	a5,9
    80005626:	0ce7ec63          	bltu	a5,a4,800056fe <sys_open+0x148>
		iunlockput(ip);
		end_op();
		return -1;
	}

	if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    8000562a:	fffff097          	auipc	ra,0xfffff
    8000562e:	e02080e7          	jalr	-510(ra) # 8000442c <filealloc>
    80005632:	89aa                	mv	s3,a0
    80005634:	10050263          	beqz	a0,80005738 <sys_open+0x182>
    80005638:	00000097          	auipc	ra,0x0
    8000563c:	902080e7          	jalr	-1790(ra) # 80004f3a <fdalloc>
    80005640:	84aa                	mv	s1,a0
    80005642:	0e054663          	bltz	a0,8000572e <sys_open+0x178>
		iunlockput(ip);
		end_op();
		return -1;
	}

	if(ip->type == T_DEVICE){
    80005646:	04491703          	lh	a4,68(s2)
    8000564a:	478d                	li	a5,3
    8000564c:	0cf70463          	beq	a4,a5,80005714 <sys_open+0x15e>
		f->type = FD_DEVICE;
		f->major = ip->major;
	} else {
		f->type = FD_INODE;
    80005650:	4789                	li	a5,2
    80005652:	00f9a023          	sw	a5,0(s3)
		f->off = 0;
    80005656:	0209a023          	sw	zero,32(s3)
	}
	f->ip = ip;
    8000565a:	0129bc23          	sd	s2,24(s3)
	f->readable = !(omode & O_WRONLY);
    8000565e:	f4c42783          	lw	a5,-180(s0)
    80005662:	0017c713          	xori	a4,a5,1
    80005666:	8b05                	andi	a4,a4,1
    80005668:	00e98423          	sb	a4,8(s3)
	f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    8000566c:	0037f713          	andi	a4,a5,3
    80005670:	00e03733          	snez	a4,a4
    80005674:	00e984a3          	sb	a4,9(s3)

	if((omode & O_TRUNC) && ip->type == T_FILE){
    80005678:	4007f793          	andi	a5,a5,1024
    8000567c:	c791                	beqz	a5,80005688 <sys_open+0xd2>
    8000567e:	04491703          	lh	a4,68(s2)
    80005682:	4789                	li	a5,2
    80005684:	08f70f63          	beq	a4,a5,80005722 <sys_open+0x16c>
		itrunc(ip);
	}

	iunlock(ip);
    80005688:	854a                	mv	a0,s2
    8000568a:	ffffe097          	auipc	ra,0xffffe
    8000568e:	082080e7          	jalr	130(ra) # 8000370c <iunlock>
	end_op();
    80005692:	fffff097          	auipc	ra,0xfffff
    80005696:	a0a080e7          	jalr	-1526(ra) # 8000409c <end_op>

	return fd;
}
    8000569a:	8526                	mv	a0,s1
    8000569c:	70ea                	ld	ra,184(sp)
    8000569e:	744a                	ld	s0,176(sp)
    800056a0:	74aa                	ld	s1,168(sp)
    800056a2:	790a                	ld	s2,160(sp)
    800056a4:	69ea                	ld	s3,152(sp)
    800056a6:	6129                	addi	sp,sp,192
    800056a8:	8082                	ret
			end_op();
    800056aa:	fffff097          	auipc	ra,0xfffff
    800056ae:	9f2080e7          	jalr	-1550(ra) # 8000409c <end_op>
			return -1;
    800056b2:	b7e5                	j	8000569a <sys_open+0xe4>
		if((ip = namei(path)) == 0){
    800056b4:	f5040513          	addi	a0,s0,-176
    800056b8:	ffffe097          	auipc	ra,0xffffe
    800056bc:	748080e7          	jalr	1864(ra) # 80003e00 <namei>
    800056c0:	892a                	mv	s2,a0
    800056c2:	c905                	beqz	a0,800056f2 <sys_open+0x13c>
		ilock(ip);
    800056c4:	ffffe097          	auipc	ra,0xffffe
    800056c8:	f86080e7          	jalr	-122(ra) # 8000364a <ilock>
		if(ip->type == T_DIR && omode != O_RDONLY){
    800056cc:	04491703          	lh	a4,68(s2)
    800056d0:	4785                	li	a5,1
    800056d2:	f4f712e3          	bne	a4,a5,80005616 <sys_open+0x60>
    800056d6:	f4c42783          	lw	a5,-180(s0)
    800056da:	dba1                	beqz	a5,8000562a <sys_open+0x74>
			iunlockput(ip);
    800056dc:	854a                	mv	a0,s2
    800056de:	ffffe097          	auipc	ra,0xffffe
    800056e2:	1ce080e7          	jalr	462(ra) # 800038ac <iunlockput>
			end_op();
    800056e6:	fffff097          	auipc	ra,0xfffff
    800056ea:	9b6080e7          	jalr	-1610(ra) # 8000409c <end_op>
			return -1;
    800056ee:	54fd                	li	s1,-1
    800056f0:	b76d                	j	8000569a <sys_open+0xe4>
			end_op();
    800056f2:	fffff097          	auipc	ra,0xfffff
    800056f6:	9aa080e7          	jalr	-1622(ra) # 8000409c <end_op>
			return -1;
    800056fa:	54fd                	li	s1,-1
    800056fc:	bf79                	j	8000569a <sys_open+0xe4>
		iunlockput(ip);
    800056fe:	854a                	mv	a0,s2
    80005700:	ffffe097          	auipc	ra,0xffffe
    80005704:	1ac080e7          	jalr	428(ra) # 800038ac <iunlockput>
		end_op();
    80005708:	fffff097          	auipc	ra,0xfffff
    8000570c:	994080e7          	jalr	-1644(ra) # 8000409c <end_op>
		return -1;
    80005710:	54fd                	li	s1,-1
    80005712:	b761                	j	8000569a <sys_open+0xe4>
		f->type = FD_DEVICE;
    80005714:	00f9a023          	sw	a5,0(s3)
		f->major = ip->major;
    80005718:	04691783          	lh	a5,70(s2)
    8000571c:	02f99223          	sh	a5,36(s3)
    80005720:	bf2d                	j	8000565a <sys_open+0xa4>
		itrunc(ip);
    80005722:	854a                	mv	a0,s2
    80005724:	ffffe097          	auipc	ra,0xffffe
    80005728:	034080e7          	jalr	52(ra) # 80003758 <itrunc>
    8000572c:	bfb1                	j	80005688 <sys_open+0xd2>
			fileclose(f);
    8000572e:	854e                	mv	a0,s3
    80005730:	fffff097          	auipc	ra,0xfffff
    80005734:	db8080e7          	jalr	-584(ra) # 800044e8 <fileclose>
		iunlockput(ip);
    80005738:	854a                	mv	a0,s2
    8000573a:	ffffe097          	auipc	ra,0xffffe
    8000573e:	172080e7          	jalr	370(ra) # 800038ac <iunlockput>
		end_op();
    80005742:	fffff097          	auipc	ra,0xfffff
    80005746:	95a080e7          	jalr	-1702(ra) # 8000409c <end_op>
		return -1;
    8000574a:	54fd                	li	s1,-1
    8000574c:	b7b9                	j	8000569a <sys_open+0xe4>

000000008000574e <sys_mkdir>:

uint64
sys_mkdir(void)
{
    8000574e:	7175                	addi	sp,sp,-144
    80005750:	e506                	sd	ra,136(sp)
    80005752:	e122                	sd	s0,128(sp)
    80005754:	0900                	addi	s0,sp,144
	char path[MAXPATH];
	struct inode *ip;

	begin_op();
    80005756:	fffff097          	auipc	ra,0xfffff
    8000575a:	8c6080e7          	jalr	-1850(ra) # 8000401c <begin_op>
	if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    8000575e:	08000613          	li	a2,128
    80005762:	f7040593          	addi	a1,s0,-144
    80005766:	4501                	li	a0,0
    80005768:	ffffd097          	auipc	ra,0xffffd
    8000576c:	3b4080e7          	jalr	948(ra) # 80002b1c <argstr>
    80005770:	02054963          	bltz	a0,800057a2 <sys_mkdir+0x54>
    80005774:	4681                	li	a3,0
    80005776:	4601                	li	a2,0
    80005778:	4585                	li	a1,1
    8000577a:	f7040513          	addi	a0,s0,-144
    8000577e:	fffff097          	auipc	ra,0xfffff
    80005782:	7fe080e7          	jalr	2046(ra) # 80004f7c <create>
    80005786:	cd11                	beqz	a0,800057a2 <sys_mkdir+0x54>
		end_op();
		return -1;
	}
	iunlockput(ip);
    80005788:	ffffe097          	auipc	ra,0xffffe
    8000578c:	124080e7          	jalr	292(ra) # 800038ac <iunlockput>
	end_op();
    80005790:	fffff097          	auipc	ra,0xfffff
    80005794:	90c080e7          	jalr	-1780(ra) # 8000409c <end_op>
	return 0;
    80005798:	4501                	li	a0,0
}
    8000579a:	60aa                	ld	ra,136(sp)
    8000579c:	640a                	ld	s0,128(sp)
    8000579e:	6149                	addi	sp,sp,144
    800057a0:	8082                	ret
		end_op();
    800057a2:	fffff097          	auipc	ra,0xfffff
    800057a6:	8fa080e7          	jalr	-1798(ra) # 8000409c <end_op>
		return -1;
    800057aa:	557d                	li	a0,-1
    800057ac:	b7fd                	j	8000579a <sys_mkdir+0x4c>

00000000800057ae <sys_mknod>:

uint64
sys_mknod(void)
{
    800057ae:	7135                	addi	sp,sp,-160
    800057b0:	ed06                	sd	ra,152(sp)
    800057b2:	e922                	sd	s0,144(sp)
    800057b4:	1100                	addi	s0,sp,160
	struct inode *ip;
	char path[MAXPATH];
	int major, minor;

	begin_op();
    800057b6:	fffff097          	auipc	ra,0xfffff
    800057ba:	866080e7          	jalr	-1946(ra) # 8000401c <begin_op>
	if((argstr(0, path, MAXPATH)) < 0 ||
    800057be:	08000613          	li	a2,128
    800057c2:	f7040593          	addi	a1,s0,-144
    800057c6:	4501                	li	a0,0
    800057c8:	ffffd097          	auipc	ra,0xffffd
    800057cc:	354080e7          	jalr	852(ra) # 80002b1c <argstr>
    800057d0:	04054a63          	bltz	a0,80005824 <sys_mknod+0x76>
			argint(1, &major) < 0 ||
    800057d4:	f6c40593          	addi	a1,s0,-148
    800057d8:	4505                	li	a0,1
    800057da:	ffffd097          	auipc	ra,0xffffd
    800057de:	2fe080e7          	jalr	766(ra) # 80002ad8 <argint>
	if((argstr(0, path, MAXPATH)) < 0 ||
    800057e2:	04054163          	bltz	a0,80005824 <sys_mknod+0x76>
			argint(2, &minor) < 0 ||
    800057e6:	f6840593          	addi	a1,s0,-152
    800057ea:	4509                	li	a0,2
    800057ec:	ffffd097          	auipc	ra,0xffffd
    800057f0:	2ec080e7          	jalr	748(ra) # 80002ad8 <argint>
			argint(1, &major) < 0 ||
    800057f4:	02054863          	bltz	a0,80005824 <sys_mknod+0x76>
			(ip = create(path, T_DEVICE, major, minor)) == 0){
    800057f8:	f6841683          	lh	a3,-152(s0)
    800057fc:	f6c41603          	lh	a2,-148(s0)
    80005800:	458d                	li	a1,3
    80005802:	f7040513          	addi	a0,s0,-144
    80005806:	fffff097          	auipc	ra,0xfffff
    8000580a:	776080e7          	jalr	1910(ra) # 80004f7c <create>
			argint(2, &minor) < 0 ||
    8000580e:	c919                	beqz	a0,80005824 <sys_mknod+0x76>
		end_op();
		return -1;
	}
	iunlockput(ip);
    80005810:	ffffe097          	auipc	ra,0xffffe
    80005814:	09c080e7          	jalr	156(ra) # 800038ac <iunlockput>
	end_op();
    80005818:	fffff097          	auipc	ra,0xfffff
    8000581c:	884080e7          	jalr	-1916(ra) # 8000409c <end_op>
	return 0;
    80005820:	4501                	li	a0,0
    80005822:	a031                	j	8000582e <sys_mknod+0x80>
		end_op();
    80005824:	fffff097          	auipc	ra,0xfffff
    80005828:	878080e7          	jalr	-1928(ra) # 8000409c <end_op>
		return -1;
    8000582c:	557d                	li	a0,-1
}
    8000582e:	60ea                	ld	ra,152(sp)
    80005830:	644a                	ld	s0,144(sp)
    80005832:	610d                	addi	sp,sp,160
    80005834:	8082                	ret

0000000080005836 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005836:	7135                	addi	sp,sp,-160
    80005838:	ed06                	sd	ra,152(sp)
    8000583a:	e922                	sd	s0,144(sp)
    8000583c:	e526                	sd	s1,136(sp)
    8000583e:	e14a                	sd	s2,128(sp)
    80005840:	1100                	addi	s0,sp,160
	char path[MAXPATH];
	struct inode *ip;
	struct proc *p = myproc();
    80005842:	ffffc097          	auipc	ra,0xffffc
    80005846:	1ea080e7          	jalr	490(ra) # 80001a2c <myproc>
    8000584a:	892a                	mv	s2,a0

	begin_op();
    8000584c:	ffffe097          	auipc	ra,0xffffe
    80005850:	7d0080e7          	jalr	2000(ra) # 8000401c <begin_op>
	if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005854:	08000613          	li	a2,128
    80005858:	f6040593          	addi	a1,s0,-160
    8000585c:	4501                	li	a0,0
    8000585e:	ffffd097          	auipc	ra,0xffffd
    80005862:	2be080e7          	jalr	702(ra) # 80002b1c <argstr>
    80005866:	04054b63          	bltz	a0,800058bc <sys_chdir+0x86>
    8000586a:	f6040513          	addi	a0,s0,-160
    8000586e:	ffffe097          	auipc	ra,0xffffe
    80005872:	592080e7          	jalr	1426(ra) # 80003e00 <namei>
    80005876:	84aa                	mv	s1,a0
    80005878:	c131                	beqz	a0,800058bc <sys_chdir+0x86>
		end_op();
		return -1;
	}
	ilock(ip);
    8000587a:	ffffe097          	auipc	ra,0xffffe
    8000587e:	dd0080e7          	jalr	-560(ra) # 8000364a <ilock>
	if(ip->type != T_DIR){
    80005882:	04449703          	lh	a4,68(s1)
    80005886:	4785                	li	a5,1
    80005888:	04f71063          	bne	a4,a5,800058c8 <sys_chdir+0x92>
		iunlockput(ip);
		end_op();
		return -1;
	}
	iunlock(ip);
    8000588c:	8526                	mv	a0,s1
    8000588e:	ffffe097          	auipc	ra,0xffffe
    80005892:	e7e080e7          	jalr	-386(ra) # 8000370c <iunlock>
	iput(p->cwd);
    80005896:	15093503          	ld	a0,336(s2)
    8000589a:	ffffe097          	auipc	ra,0xffffe
    8000589e:	f6a080e7          	jalr	-150(ra) # 80003804 <iput>
	end_op();
    800058a2:	ffffe097          	auipc	ra,0xffffe
    800058a6:	7fa080e7          	jalr	2042(ra) # 8000409c <end_op>
	p->cwd = ip;
    800058aa:	14993823          	sd	s1,336(s2)
	return 0;
    800058ae:	4501                	li	a0,0
}
    800058b0:	60ea                	ld	ra,152(sp)
    800058b2:	644a                	ld	s0,144(sp)
    800058b4:	64aa                	ld	s1,136(sp)
    800058b6:	690a                	ld	s2,128(sp)
    800058b8:	610d                	addi	sp,sp,160
    800058ba:	8082                	ret
		end_op();
    800058bc:	ffffe097          	auipc	ra,0xffffe
    800058c0:	7e0080e7          	jalr	2016(ra) # 8000409c <end_op>
		return -1;
    800058c4:	557d                	li	a0,-1
    800058c6:	b7ed                	j	800058b0 <sys_chdir+0x7a>
		iunlockput(ip);
    800058c8:	8526                	mv	a0,s1
    800058ca:	ffffe097          	auipc	ra,0xffffe
    800058ce:	fe2080e7          	jalr	-30(ra) # 800038ac <iunlockput>
		end_op();
    800058d2:	ffffe097          	auipc	ra,0xffffe
    800058d6:	7ca080e7          	jalr	1994(ra) # 8000409c <end_op>
		return -1;
    800058da:	557d                	li	a0,-1
    800058dc:	bfd1                	j	800058b0 <sys_chdir+0x7a>

00000000800058de <sys_exec>:

uint64
sys_exec(void)
{
    800058de:	7145                	addi	sp,sp,-464
    800058e0:	e786                	sd	ra,456(sp)
    800058e2:	e3a2                	sd	s0,448(sp)
    800058e4:	ff26                	sd	s1,440(sp)
    800058e6:	fb4a                	sd	s2,432(sp)
    800058e8:	f74e                	sd	s3,424(sp)
    800058ea:	f352                	sd	s4,416(sp)
    800058ec:	ef56                	sd	s5,408(sp)
    800058ee:	0b80                	addi	s0,sp,464
	char path[MAXPATH], *argv[MAXARG];
	int i;
	uint64 uargv, uarg;

	if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    800058f0:	08000613          	li	a2,128
    800058f4:	f4040593          	addi	a1,s0,-192
    800058f8:	4501                	li	a0,0
    800058fa:	ffffd097          	auipc	ra,0xffffd
    800058fe:	222080e7          	jalr	546(ra) # 80002b1c <argstr>
		return -1;
    80005902:	597d                	li	s2,-1
	if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005904:	0c054a63          	bltz	a0,800059d8 <sys_exec+0xfa>
    80005908:	e3840593          	addi	a1,s0,-456
    8000590c:	4505                	li	a0,1
    8000590e:	ffffd097          	auipc	ra,0xffffd
    80005912:	1ec080e7          	jalr	492(ra) # 80002afa <argaddr>
    80005916:	0c054163          	bltz	a0,800059d8 <sys_exec+0xfa>
	}
	memset(argv, 0, sizeof(argv));
    8000591a:	10000613          	li	a2,256
    8000591e:	4581                	li	a1,0
    80005920:	e4040513          	addi	a0,s0,-448
    80005924:	ffffb097          	auipc	ra,0xffffb
    80005928:	3bc080e7          	jalr	956(ra) # 80000ce0 <memset>
	for(i=0;; i++){
		if(i >= NELEM(argv)){
    8000592c:	e4040493          	addi	s1,s0,-448
	memset(argv, 0, sizeof(argv));
    80005930:	89a6                	mv	s3,s1
    80005932:	4901                	li	s2,0
		if(i >= NELEM(argv)){
    80005934:	02000a13          	li	s4,32
    80005938:	00090a9b          	sext.w	s5,s2
			goto bad;
		}
		if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    8000593c:	00391513          	slli	a0,s2,0x3
    80005940:	e3040593          	addi	a1,s0,-464
    80005944:	e3843783          	ld	a5,-456(s0)
    80005948:	953e                	add	a0,a0,a5
    8000594a:	ffffd097          	auipc	ra,0xffffd
    8000594e:	0f4080e7          	jalr	244(ra) # 80002a3e <fetchaddr>
    80005952:	02054a63          	bltz	a0,80005986 <sys_exec+0xa8>
			goto bad;
		}
		if(uarg == 0){
    80005956:	e3043783          	ld	a5,-464(s0)
    8000595a:	c3b9                	beqz	a5,800059a0 <sys_exec+0xc2>
			argv[i] = 0;
			break;
		}
		argv[i] = kalloc();
    8000595c:	ffffb097          	auipc	ra,0xffffb
    80005960:	198080e7          	jalr	408(ra) # 80000af4 <kalloc>
    80005964:	85aa                	mv	a1,a0
    80005966:	00a9b023          	sd	a0,0(s3)
		if(argv[i] == 0)
    8000596a:	cd11                	beqz	a0,80005986 <sys_exec+0xa8>
			goto bad;
		if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    8000596c:	6605                	lui	a2,0x1
    8000596e:	e3043503          	ld	a0,-464(s0)
    80005972:	ffffd097          	auipc	ra,0xffffd
    80005976:	11e080e7          	jalr	286(ra) # 80002a90 <fetchstr>
    8000597a:	00054663          	bltz	a0,80005986 <sys_exec+0xa8>
		if(i >= NELEM(argv)){
    8000597e:	0905                	addi	s2,s2,1
    80005980:	09a1                	addi	s3,s3,8
    80005982:	fb491be3          	bne	s2,s4,80005938 <sys_exec+0x5a>
		kfree(argv[i]);

	return ret;

bad:
	for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005986:	10048913          	addi	s2,s1,256
    8000598a:	6088                	ld	a0,0(s1)
    8000598c:	c529                	beqz	a0,800059d6 <sys_exec+0xf8>
		kfree(argv[i]);
    8000598e:	ffffb097          	auipc	ra,0xffffb
    80005992:	06a080e7          	jalr	106(ra) # 800009f8 <kfree>
	for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005996:	04a1                	addi	s1,s1,8
    80005998:	ff2499e3          	bne	s1,s2,8000598a <sys_exec+0xac>
	return -1;
    8000599c:	597d                	li	s2,-1
    8000599e:	a82d                	j	800059d8 <sys_exec+0xfa>
			argv[i] = 0;
    800059a0:	0a8e                	slli	s5,s5,0x3
    800059a2:	fc040793          	addi	a5,s0,-64
    800059a6:	9abe                	add	s5,s5,a5
    800059a8:	e80ab023          	sd	zero,-384(s5)
	int ret = exec(path, argv);
    800059ac:	e4040593          	addi	a1,s0,-448
    800059b0:	f4040513          	addi	a0,s0,-192
    800059b4:	fffff097          	auipc	ra,0xfffff
    800059b8:	194080e7          	jalr	404(ra) # 80004b48 <exec>
    800059bc:	892a                	mv	s2,a0
	for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800059be:	10048993          	addi	s3,s1,256
    800059c2:	6088                	ld	a0,0(s1)
    800059c4:	c911                	beqz	a0,800059d8 <sys_exec+0xfa>
		kfree(argv[i]);
    800059c6:	ffffb097          	auipc	ra,0xffffb
    800059ca:	032080e7          	jalr	50(ra) # 800009f8 <kfree>
	for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800059ce:	04a1                	addi	s1,s1,8
    800059d0:	ff3499e3          	bne	s1,s3,800059c2 <sys_exec+0xe4>
    800059d4:	a011                	j	800059d8 <sys_exec+0xfa>
	return -1;
    800059d6:	597d                	li	s2,-1
}
    800059d8:	854a                	mv	a0,s2
    800059da:	60be                	ld	ra,456(sp)
    800059dc:	641e                	ld	s0,448(sp)
    800059de:	74fa                	ld	s1,440(sp)
    800059e0:	795a                	ld	s2,432(sp)
    800059e2:	79ba                	ld	s3,424(sp)
    800059e4:	7a1a                	ld	s4,416(sp)
    800059e6:	6afa                	ld	s5,408(sp)
    800059e8:	6179                	addi	sp,sp,464
    800059ea:	8082                	ret

00000000800059ec <sys_pipe>:

uint64
sys_pipe(void)
{
    800059ec:	7139                	addi	sp,sp,-64
    800059ee:	fc06                	sd	ra,56(sp)
    800059f0:	f822                	sd	s0,48(sp)
    800059f2:	f426                	sd	s1,40(sp)
    800059f4:	0080                	addi	s0,sp,64
	uint64 fdarray; // user pointer to array of two integers
	struct file *rf, *wf;
	int fd0, fd1;
	struct proc *p = myproc();
    800059f6:	ffffc097          	auipc	ra,0xffffc
    800059fa:	036080e7          	jalr	54(ra) # 80001a2c <myproc>
    800059fe:	84aa                	mv	s1,a0

	if(argaddr(0, &fdarray) < 0)
    80005a00:	fd840593          	addi	a1,s0,-40
    80005a04:	4501                	li	a0,0
    80005a06:	ffffd097          	auipc	ra,0xffffd
    80005a0a:	0f4080e7          	jalr	244(ra) # 80002afa <argaddr>
		return -1;
    80005a0e:	57fd                	li	a5,-1
	if(argaddr(0, &fdarray) < 0)
    80005a10:	0e054063          	bltz	a0,80005af0 <sys_pipe+0x104>
	if(pipealloc(&rf, &wf) < 0)
    80005a14:	fc840593          	addi	a1,s0,-56
    80005a18:	fd040513          	addi	a0,s0,-48
    80005a1c:	fffff097          	auipc	ra,0xfffff
    80005a20:	dfc080e7          	jalr	-516(ra) # 80004818 <pipealloc>
		return -1;
    80005a24:	57fd                	li	a5,-1
	if(pipealloc(&rf, &wf) < 0)
    80005a26:	0c054563          	bltz	a0,80005af0 <sys_pipe+0x104>
	fd0 = -1;
    80005a2a:	fcf42223          	sw	a5,-60(s0)
	if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005a2e:	fd043503          	ld	a0,-48(s0)
    80005a32:	fffff097          	auipc	ra,0xfffff
    80005a36:	508080e7          	jalr	1288(ra) # 80004f3a <fdalloc>
    80005a3a:	fca42223          	sw	a0,-60(s0)
    80005a3e:	08054c63          	bltz	a0,80005ad6 <sys_pipe+0xea>
    80005a42:	fc843503          	ld	a0,-56(s0)
    80005a46:	fffff097          	auipc	ra,0xfffff
    80005a4a:	4f4080e7          	jalr	1268(ra) # 80004f3a <fdalloc>
    80005a4e:	fca42023          	sw	a0,-64(s0)
    80005a52:	06054863          	bltz	a0,80005ac2 <sys_pipe+0xd6>
			p->ofile[fd0] = 0;
		fileclose(rf);
		fileclose(wf);
		return -1;
	}
	if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005a56:	4691                	li	a3,4
    80005a58:	fc440613          	addi	a2,s0,-60
    80005a5c:	fd843583          	ld	a1,-40(s0)
    80005a60:	68a8                	ld	a0,80(s1)
    80005a62:	ffffc097          	auipc	ra,0xffffc
    80005a66:	c10080e7          	jalr	-1008(ra) # 80001672 <copyout>
    80005a6a:	02054063          	bltz	a0,80005a8a <sys_pipe+0x9e>
			copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005a6e:	4691                	li	a3,4
    80005a70:	fc040613          	addi	a2,s0,-64
    80005a74:	fd843583          	ld	a1,-40(s0)
    80005a78:	0591                	addi	a1,a1,4
    80005a7a:	68a8                	ld	a0,80(s1)
    80005a7c:	ffffc097          	auipc	ra,0xffffc
    80005a80:	bf6080e7          	jalr	-1034(ra) # 80001672 <copyout>
		p->ofile[fd1] = 0;
		fileclose(rf);
		fileclose(wf);
		return -1;
	}
	return 0;
    80005a84:	4781                	li	a5,0
	if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005a86:	06055563          	bgez	a0,80005af0 <sys_pipe+0x104>
		p->ofile[fd0] = 0;
    80005a8a:	fc442783          	lw	a5,-60(s0)
    80005a8e:	07e9                	addi	a5,a5,26
    80005a90:	078e                	slli	a5,a5,0x3
    80005a92:	97a6                	add	a5,a5,s1
    80005a94:	0007b023          	sd	zero,0(a5)
		p->ofile[fd1] = 0;
    80005a98:	fc042503          	lw	a0,-64(s0)
    80005a9c:	0569                	addi	a0,a0,26
    80005a9e:	050e                	slli	a0,a0,0x3
    80005aa0:	9526                	add	a0,a0,s1
    80005aa2:	00053023          	sd	zero,0(a0)
		fileclose(rf);
    80005aa6:	fd043503          	ld	a0,-48(s0)
    80005aaa:	fffff097          	auipc	ra,0xfffff
    80005aae:	a3e080e7          	jalr	-1474(ra) # 800044e8 <fileclose>
		fileclose(wf);
    80005ab2:	fc843503          	ld	a0,-56(s0)
    80005ab6:	fffff097          	auipc	ra,0xfffff
    80005aba:	a32080e7          	jalr	-1486(ra) # 800044e8 <fileclose>
		return -1;
    80005abe:	57fd                	li	a5,-1
    80005ac0:	a805                	j	80005af0 <sys_pipe+0x104>
		if(fd0 >= 0)
    80005ac2:	fc442783          	lw	a5,-60(s0)
    80005ac6:	0007c863          	bltz	a5,80005ad6 <sys_pipe+0xea>
			p->ofile[fd0] = 0;
    80005aca:	01a78513          	addi	a0,a5,26
    80005ace:	050e                	slli	a0,a0,0x3
    80005ad0:	9526                	add	a0,a0,s1
    80005ad2:	00053023          	sd	zero,0(a0)
		fileclose(rf);
    80005ad6:	fd043503          	ld	a0,-48(s0)
    80005ada:	fffff097          	auipc	ra,0xfffff
    80005ade:	a0e080e7          	jalr	-1522(ra) # 800044e8 <fileclose>
		fileclose(wf);
    80005ae2:	fc843503          	ld	a0,-56(s0)
    80005ae6:	fffff097          	auipc	ra,0xfffff
    80005aea:	a02080e7          	jalr	-1534(ra) # 800044e8 <fileclose>
		return -1;
    80005aee:	57fd                	li	a5,-1
}
    80005af0:	853e                	mv	a0,a5
    80005af2:	70e2                	ld	ra,56(sp)
    80005af4:	7442                	ld	s0,48(sp)
    80005af6:	74a2                	ld	s1,40(sp)
    80005af8:	6121                	addi	sp,sp,64
    80005afa:	8082                	ret
    80005afc:	0000                	unimp
	...

0000000080005b00 <kernelvec>:
    80005b00:	7111                	addi	sp,sp,-256
    80005b02:	e006                	sd	ra,0(sp)
    80005b04:	e40a                	sd	sp,8(sp)
    80005b06:	e80e                	sd	gp,16(sp)
    80005b08:	ec12                	sd	tp,24(sp)
    80005b0a:	f016                	sd	t0,32(sp)
    80005b0c:	f41a                	sd	t1,40(sp)
    80005b0e:	f81e                	sd	t2,48(sp)
    80005b10:	fc22                	sd	s0,56(sp)
    80005b12:	e0a6                	sd	s1,64(sp)
    80005b14:	e4aa                	sd	a0,72(sp)
    80005b16:	e8ae                	sd	a1,80(sp)
    80005b18:	ecb2                	sd	a2,88(sp)
    80005b1a:	f0b6                	sd	a3,96(sp)
    80005b1c:	f4ba                	sd	a4,104(sp)
    80005b1e:	f8be                	sd	a5,112(sp)
    80005b20:	fcc2                	sd	a6,120(sp)
    80005b22:	e146                	sd	a7,128(sp)
    80005b24:	e54a                	sd	s2,136(sp)
    80005b26:	e94e                	sd	s3,144(sp)
    80005b28:	ed52                	sd	s4,152(sp)
    80005b2a:	f156                	sd	s5,160(sp)
    80005b2c:	f55a                	sd	s6,168(sp)
    80005b2e:	f95e                	sd	s7,176(sp)
    80005b30:	fd62                	sd	s8,184(sp)
    80005b32:	e1e6                	sd	s9,192(sp)
    80005b34:	e5ea                	sd	s10,200(sp)
    80005b36:	e9ee                	sd	s11,208(sp)
    80005b38:	edf2                	sd	t3,216(sp)
    80005b3a:	f1f6                	sd	t4,224(sp)
    80005b3c:	f5fa                	sd	t5,232(sp)
    80005b3e:	f9fe                	sd	t6,240(sp)
    80005b40:	dcbfc0ef          	jal	ra,8000290a <kerneltrap>
    80005b44:	6082                	ld	ra,0(sp)
    80005b46:	6122                	ld	sp,8(sp)
    80005b48:	61c2                	ld	gp,16(sp)
    80005b4a:	7282                	ld	t0,32(sp)
    80005b4c:	7322                	ld	t1,40(sp)
    80005b4e:	73c2                	ld	t2,48(sp)
    80005b50:	7462                	ld	s0,56(sp)
    80005b52:	6486                	ld	s1,64(sp)
    80005b54:	6526                	ld	a0,72(sp)
    80005b56:	65c6                	ld	a1,80(sp)
    80005b58:	6666                	ld	a2,88(sp)
    80005b5a:	7686                	ld	a3,96(sp)
    80005b5c:	7726                	ld	a4,104(sp)
    80005b5e:	77c6                	ld	a5,112(sp)
    80005b60:	7866                	ld	a6,120(sp)
    80005b62:	688a                	ld	a7,128(sp)
    80005b64:	692a                	ld	s2,136(sp)
    80005b66:	69ca                	ld	s3,144(sp)
    80005b68:	6a6a                	ld	s4,152(sp)
    80005b6a:	7a8a                	ld	s5,160(sp)
    80005b6c:	7b2a                	ld	s6,168(sp)
    80005b6e:	7bca                	ld	s7,176(sp)
    80005b70:	7c6a                	ld	s8,184(sp)
    80005b72:	6c8e                	ld	s9,192(sp)
    80005b74:	6d2e                	ld	s10,200(sp)
    80005b76:	6dce                	ld	s11,208(sp)
    80005b78:	6e6e                	ld	t3,216(sp)
    80005b7a:	7e8e                	ld	t4,224(sp)
    80005b7c:	7f2e                	ld	t5,232(sp)
    80005b7e:	7fce                	ld	t6,240(sp)
    80005b80:	6111                	addi	sp,sp,256
    80005b82:	10200073          	sret
    80005b86:	00000013          	nop
    80005b8a:	00000013          	nop
    80005b8e:	0001                	nop

0000000080005b90 <timervec>:
    80005b90:	34051573          	csrrw	a0,mscratch,a0
    80005b94:	e10c                	sd	a1,0(a0)
    80005b96:	e510                	sd	a2,8(a0)
    80005b98:	e914                	sd	a3,16(a0)
    80005b9a:	6d0c                	ld	a1,24(a0)
    80005b9c:	7110                	ld	a2,32(a0)
    80005b9e:	6194                	ld	a3,0(a1)
    80005ba0:	96b2                	add	a3,a3,a2
    80005ba2:	e194                	sd	a3,0(a1)
    80005ba4:	4589                	li	a1,2
    80005ba6:	14459073          	csrw	sip,a1
    80005baa:	6914                	ld	a3,16(a0)
    80005bac:	6510                	ld	a2,8(a0)
    80005bae:	610c                	ld	a1,0(a0)
    80005bb0:	34051573          	csrrw	a0,mscratch,a0
    80005bb4:	30200073          	mret
	...

0000000080005bba <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005bba:	1141                	addi	sp,sp,-16
    80005bbc:	e422                	sd	s0,8(sp)
    80005bbe:	0800                	addi	s0,sp,16
	// set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005bc0:	0c0007b7          	lui	a5,0xc000
    80005bc4:	4705                	li	a4,1
    80005bc6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005bc8:	c3d8                	sw	a4,4(a5)
}
    80005bca:	6422                	ld	s0,8(sp)
    80005bcc:	0141                	addi	sp,sp,16
    80005bce:	8082                	ret

0000000080005bd0 <plicinithart>:

void
plicinithart(void)
{
    80005bd0:	1141                	addi	sp,sp,-16
    80005bd2:	e406                	sd	ra,8(sp)
    80005bd4:	e022                	sd	s0,0(sp)
    80005bd6:	0800                	addi	s0,sp,16
	int hart = cpuid();
    80005bd8:	ffffc097          	auipc	ra,0xffffc
    80005bdc:	e28080e7          	jalr	-472(ra) # 80001a00 <cpuid>

  // set uart's enable bit for this hart's S-mode.
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005be0:	0085171b          	slliw	a4,a0,0x8
    80005be4:	0c0027b7          	lui	a5,0xc002
    80005be8:	97ba                	add	a5,a5,a4
    80005bea:	40200713          	li	a4,1026
    80005bee:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005bf2:	00d5151b          	slliw	a0,a0,0xd
    80005bf6:	0c2017b7          	lui	a5,0xc201
    80005bfa:	953e                	add	a0,a0,a5
    80005bfc:	00052023          	sw	zero,0(a0)
}
    80005c00:	60a2                	ld	ra,8(sp)
    80005c02:	6402                	ld	s0,0(sp)
    80005c04:	0141                	addi	sp,sp,16
    80005c06:	8082                	ret

0000000080005c08 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005c08:	1141                	addi	sp,sp,-16
    80005c0a:	e406                	sd	ra,8(sp)
    80005c0c:	e022                	sd	s0,0(sp)
    80005c0e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005c10:	ffffc097          	auipc	ra,0xffffc
    80005c14:	df0080e7          	jalr	-528(ra) # 80001a00 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005c18:	00d5179b          	slliw	a5,a0,0xd
    80005c1c:	0c201537          	lui	a0,0xc201
    80005c20:	953e                	add	a0,a0,a5
  return irq;
}
    80005c22:	4148                	lw	a0,4(a0)
    80005c24:	60a2                	ld	ra,8(sp)
    80005c26:	6402                	ld	s0,0(sp)
    80005c28:	0141                	addi	sp,sp,16
    80005c2a:	8082                	ret

0000000080005c2c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005c2c:	1101                	addi	sp,sp,-32
    80005c2e:	ec06                	sd	ra,24(sp)
    80005c30:	e822                	sd	s0,16(sp)
    80005c32:	e426                	sd	s1,8(sp)
    80005c34:	1000                	addi	s0,sp,32
    80005c36:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005c38:	ffffc097          	auipc	ra,0xffffc
    80005c3c:	dc8080e7          	jalr	-568(ra) # 80001a00 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005c40:	00d5151b          	slliw	a0,a0,0xd
    80005c44:	0c2017b7          	lui	a5,0xc201
    80005c48:	97aa                	add	a5,a5,a0
    80005c4a:	c3c4                	sw	s1,4(a5)
}
    80005c4c:	60e2                	ld	ra,24(sp)
    80005c4e:	6442                	ld	s0,16(sp)
    80005c50:	64a2                	ld	s1,8(sp)
    80005c52:	6105                	addi	sp,sp,32
    80005c54:	8082                	ret

0000000080005c56 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005c56:	1141                	addi	sp,sp,-16
    80005c58:	e406                	sd	ra,8(sp)
    80005c5a:	e022                	sd	s0,0(sp)
    80005c5c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005c5e:	479d                	li	a5,7
    80005c60:	06a7c963          	blt	a5,a0,80005cd2 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    80005c64:	0001d797          	auipc	a5,0x1d
    80005c68:	39c78793          	addi	a5,a5,924 # 80023000 <disk>
    80005c6c:	00a78733          	add	a4,a5,a0
    80005c70:	6789                	lui	a5,0x2
    80005c72:	97ba                	add	a5,a5,a4
    80005c74:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80005c78:	e7ad                	bnez	a5,80005ce2 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005c7a:	00451793          	slli	a5,a0,0x4
    80005c7e:	0001f717          	auipc	a4,0x1f
    80005c82:	38270713          	addi	a4,a4,898 # 80025000 <disk+0x2000>
    80005c86:	6314                	ld	a3,0(a4)
    80005c88:	96be                	add	a3,a3,a5
    80005c8a:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80005c8e:	6314                	ld	a3,0(a4)
    80005c90:	96be                	add	a3,a3,a5
    80005c92:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80005c96:	6314                	ld	a3,0(a4)
    80005c98:	96be                	add	a3,a3,a5
    80005c9a:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    80005c9e:	6318                	ld	a4,0(a4)
    80005ca0:	97ba                	add	a5,a5,a4
    80005ca2:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80005ca6:	0001d797          	auipc	a5,0x1d
    80005caa:	35a78793          	addi	a5,a5,858 # 80023000 <disk>
    80005cae:	97aa                	add	a5,a5,a0
    80005cb0:	6509                	lui	a0,0x2
    80005cb2:	953e                	add	a0,a0,a5
    80005cb4:	4785                	li	a5,1
    80005cb6:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80005cba:	0001f517          	auipc	a0,0x1f
    80005cbe:	35e50513          	addi	a0,a0,862 # 80025018 <disk+0x2018>
    80005cc2:	ffffc097          	auipc	ra,0xffffc
    80005cc6:	5b2080e7          	jalr	1458(ra) # 80002274 <wakeup>
}
    80005cca:	60a2                	ld	ra,8(sp)
    80005ccc:	6402                	ld	s0,0(sp)
    80005cce:	0141                	addi	sp,sp,16
    80005cd0:	8082                	ret
    panic("free_desc 1");
    80005cd2:	00003517          	auipc	a0,0x3
    80005cd6:	a9e50513          	addi	a0,a0,-1378 # 80008770 <syscalls+0x320>
    80005cda:	ffffb097          	auipc	ra,0xffffb
    80005cde:	864080e7          	jalr	-1948(ra) # 8000053e <panic>
    panic("free_desc 2");
    80005ce2:	00003517          	auipc	a0,0x3
    80005ce6:	a9e50513          	addi	a0,a0,-1378 # 80008780 <syscalls+0x330>
    80005cea:	ffffb097          	auipc	ra,0xffffb
    80005cee:	854080e7          	jalr	-1964(ra) # 8000053e <panic>

0000000080005cf2 <virtio_disk_init>:
{
    80005cf2:	1101                	addi	sp,sp,-32
    80005cf4:	ec06                	sd	ra,24(sp)
    80005cf6:	e822                	sd	s0,16(sp)
    80005cf8:	e426                	sd	s1,8(sp)
    80005cfa:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005cfc:	00003597          	auipc	a1,0x3
    80005d00:	a9458593          	addi	a1,a1,-1388 # 80008790 <syscalls+0x340>
    80005d04:	0001f517          	auipc	a0,0x1f
    80005d08:	42450513          	addi	a0,a0,1060 # 80025128 <disk+0x2128>
    80005d0c:	ffffb097          	auipc	ra,0xffffb
    80005d10:	e48080e7          	jalr	-440(ra) # 80000b54 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005d14:	100017b7          	lui	a5,0x10001
    80005d18:	4398                	lw	a4,0(a5)
    80005d1a:	2701                	sext.w	a4,a4
    80005d1c:	747277b7          	lui	a5,0x74727
    80005d20:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005d24:	0ef71163          	bne	a4,a5,80005e06 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005d28:	100017b7          	lui	a5,0x10001
    80005d2c:	43dc                	lw	a5,4(a5)
    80005d2e:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005d30:	4705                	li	a4,1
    80005d32:	0ce79a63          	bne	a5,a4,80005e06 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005d36:	100017b7          	lui	a5,0x10001
    80005d3a:	479c                	lw	a5,8(a5)
    80005d3c:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005d3e:	4709                	li	a4,2
    80005d40:	0ce79363          	bne	a5,a4,80005e06 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005d44:	100017b7          	lui	a5,0x10001
    80005d48:	47d8                	lw	a4,12(a5)
    80005d4a:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005d4c:	554d47b7          	lui	a5,0x554d4
    80005d50:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005d54:	0af71963          	bne	a4,a5,80005e06 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005d58:	100017b7          	lui	a5,0x10001
    80005d5c:	4705                	li	a4,1
    80005d5e:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005d60:	470d                	li	a4,3
    80005d62:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005d64:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80005d66:	c7ffe737          	lui	a4,0xc7ffe
    80005d6a:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    80005d6e:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005d70:	2701                	sext.w	a4,a4
    80005d72:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005d74:	472d                	li	a4,11
    80005d76:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005d78:	473d                	li	a4,15
    80005d7a:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    80005d7c:	6705                	lui	a4,0x1
    80005d7e:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005d80:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005d84:	5bdc                	lw	a5,52(a5)
    80005d86:	2781                	sext.w	a5,a5
  if(max == 0)
    80005d88:	c7d9                	beqz	a5,80005e16 <virtio_disk_init+0x124>
  if(max < NUM)
    80005d8a:	471d                	li	a4,7
    80005d8c:	08f77d63          	bgeu	a4,a5,80005e26 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80005d90:	100014b7          	lui	s1,0x10001
    80005d94:	47a1                	li	a5,8
    80005d96:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80005d98:	6609                	lui	a2,0x2
    80005d9a:	4581                	li	a1,0
    80005d9c:	0001d517          	auipc	a0,0x1d
    80005da0:	26450513          	addi	a0,a0,612 # 80023000 <disk>
    80005da4:	ffffb097          	auipc	ra,0xffffb
    80005da8:	f3c080e7          	jalr	-196(ra) # 80000ce0 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    80005dac:	0001d717          	auipc	a4,0x1d
    80005db0:	25470713          	addi	a4,a4,596 # 80023000 <disk>
    80005db4:	00c75793          	srli	a5,a4,0xc
    80005db8:	2781                	sext.w	a5,a5
    80005dba:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    80005dbc:	0001f797          	auipc	a5,0x1f
    80005dc0:	24478793          	addi	a5,a5,580 # 80025000 <disk+0x2000>
    80005dc4:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80005dc6:	0001d717          	auipc	a4,0x1d
    80005dca:	2ba70713          	addi	a4,a4,698 # 80023080 <disk+0x80>
    80005dce:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80005dd0:	0001e717          	auipc	a4,0x1e
    80005dd4:	23070713          	addi	a4,a4,560 # 80024000 <disk+0x1000>
    80005dd8:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    80005dda:	4705                	li	a4,1
    80005ddc:	00e78c23          	sb	a4,24(a5)
    80005de0:	00e78ca3          	sb	a4,25(a5)
    80005de4:	00e78d23          	sb	a4,26(a5)
    80005de8:	00e78da3          	sb	a4,27(a5)
    80005dec:	00e78e23          	sb	a4,28(a5)
    80005df0:	00e78ea3          	sb	a4,29(a5)
    80005df4:	00e78f23          	sb	a4,30(a5)
    80005df8:	00e78fa3          	sb	a4,31(a5)
}
    80005dfc:	60e2                	ld	ra,24(sp)
    80005dfe:	6442                	ld	s0,16(sp)
    80005e00:	64a2                	ld	s1,8(sp)
    80005e02:	6105                	addi	sp,sp,32
    80005e04:	8082                	ret
    panic("could not find virtio disk");
    80005e06:	00003517          	auipc	a0,0x3
    80005e0a:	99a50513          	addi	a0,a0,-1638 # 800087a0 <syscalls+0x350>
    80005e0e:	ffffa097          	auipc	ra,0xffffa
    80005e12:	730080e7          	jalr	1840(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    80005e16:	00003517          	auipc	a0,0x3
    80005e1a:	9aa50513          	addi	a0,a0,-1622 # 800087c0 <syscalls+0x370>
    80005e1e:	ffffa097          	auipc	ra,0xffffa
    80005e22:	720080e7          	jalr	1824(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    80005e26:	00003517          	auipc	a0,0x3
    80005e2a:	9ba50513          	addi	a0,a0,-1606 # 800087e0 <syscalls+0x390>
    80005e2e:	ffffa097          	auipc	ra,0xffffa
    80005e32:	710080e7          	jalr	1808(ra) # 8000053e <panic>

0000000080005e36 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80005e36:	7159                	addi	sp,sp,-112
    80005e38:	f486                	sd	ra,104(sp)
    80005e3a:	f0a2                	sd	s0,96(sp)
    80005e3c:	eca6                	sd	s1,88(sp)
    80005e3e:	e8ca                	sd	s2,80(sp)
    80005e40:	e4ce                	sd	s3,72(sp)
    80005e42:	e0d2                	sd	s4,64(sp)
    80005e44:	fc56                	sd	s5,56(sp)
    80005e46:	f85a                	sd	s6,48(sp)
    80005e48:	f45e                	sd	s7,40(sp)
    80005e4a:	f062                	sd	s8,32(sp)
    80005e4c:	ec66                	sd	s9,24(sp)
    80005e4e:	e86a                	sd	s10,16(sp)
    80005e50:	1880                	addi	s0,sp,112
    80005e52:	892a                	mv	s2,a0
    80005e54:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80005e56:	00c52c83          	lw	s9,12(a0)
    80005e5a:	001c9c9b          	slliw	s9,s9,0x1
    80005e5e:	1c82                	slli	s9,s9,0x20
    80005e60:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80005e64:	0001f517          	auipc	a0,0x1f
    80005e68:	2c450513          	addi	a0,a0,708 # 80025128 <disk+0x2128>
    80005e6c:	ffffb097          	auipc	ra,0xffffb
    80005e70:	d78080e7          	jalr	-648(ra) # 80000be4 <acquire>
  for(int i = 0; i < 3; i++){
    80005e74:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80005e76:	4c21                	li	s8,8
      disk.free[i] = 0;
    80005e78:	0001db97          	auipc	s7,0x1d
    80005e7c:	188b8b93          	addi	s7,s7,392 # 80023000 <disk>
    80005e80:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    80005e82:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80005e84:	8a4e                	mv	s4,s3
    80005e86:	a051                	j	80005f0a <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    80005e88:	00fb86b3          	add	a3,s7,a5
    80005e8c:	96da                	add	a3,a3,s6
    80005e8e:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80005e92:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    80005e94:	0207c563          	bltz	a5,80005ebe <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80005e98:	2485                	addiw	s1,s1,1
    80005e9a:	0711                	addi	a4,a4,4
    80005e9c:	25548063          	beq	s1,s5,800060dc <virtio_disk_rw+0x2a6>
    idx[i] = alloc_desc();
    80005ea0:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80005ea2:	0001f697          	auipc	a3,0x1f
    80005ea6:	17668693          	addi	a3,a3,374 # 80025018 <disk+0x2018>
    80005eaa:	87d2                	mv	a5,s4
    if(disk.free[i]){
    80005eac:	0006c583          	lbu	a1,0(a3)
    80005eb0:	fde1                	bnez	a1,80005e88 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80005eb2:	2785                	addiw	a5,a5,1
    80005eb4:	0685                	addi	a3,a3,1
    80005eb6:	ff879be3          	bne	a5,s8,80005eac <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    80005eba:	57fd                	li	a5,-1
    80005ebc:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    80005ebe:	02905a63          	blez	s1,80005ef2 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80005ec2:	f9042503          	lw	a0,-112(s0)
    80005ec6:	00000097          	auipc	ra,0x0
    80005eca:	d90080e7          	jalr	-624(ra) # 80005c56 <free_desc>
      for(int j = 0; j < i; j++)
    80005ece:	4785                	li	a5,1
    80005ed0:	0297d163          	bge	a5,s1,80005ef2 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80005ed4:	f9442503          	lw	a0,-108(s0)
    80005ed8:	00000097          	auipc	ra,0x0
    80005edc:	d7e080e7          	jalr	-642(ra) # 80005c56 <free_desc>
      for(int j = 0; j < i; j++)
    80005ee0:	4789                	li	a5,2
    80005ee2:	0097d863          	bge	a5,s1,80005ef2 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80005ee6:	f9842503          	lw	a0,-104(s0)
    80005eea:	00000097          	auipc	ra,0x0
    80005eee:	d6c080e7          	jalr	-660(ra) # 80005c56 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80005ef2:	0001f597          	auipc	a1,0x1f
    80005ef6:	23658593          	addi	a1,a1,566 # 80025128 <disk+0x2128>
    80005efa:	0001f517          	auipc	a0,0x1f
    80005efe:	11e50513          	addi	a0,a0,286 # 80025018 <disk+0x2018>
    80005f02:	ffffc097          	auipc	ra,0xffffc
    80005f06:	1e6080e7          	jalr	486(ra) # 800020e8 <sleep>
  for(int i = 0; i < 3; i++){
    80005f0a:	f9040713          	addi	a4,s0,-112
    80005f0e:	84ce                	mv	s1,s3
    80005f10:	bf41                	j	80005ea0 <virtio_disk_rw+0x6a>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    80005f12:	20058713          	addi	a4,a1,512
    80005f16:	00471693          	slli	a3,a4,0x4
    80005f1a:	0001d717          	auipc	a4,0x1d
    80005f1e:	0e670713          	addi	a4,a4,230 # 80023000 <disk>
    80005f22:	9736                	add	a4,a4,a3
    80005f24:	4685                	li	a3,1
    80005f26:	0ad72423          	sw	a3,168(a4)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    80005f2a:	20058713          	addi	a4,a1,512
    80005f2e:	00471693          	slli	a3,a4,0x4
    80005f32:	0001d717          	auipc	a4,0x1d
    80005f36:	0ce70713          	addi	a4,a4,206 # 80023000 <disk>
    80005f3a:	9736                	add	a4,a4,a3
    80005f3c:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    80005f40:	0b973823          	sd	s9,176(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80005f44:	7679                	lui	a2,0xffffe
    80005f46:	963e                	add	a2,a2,a5
    80005f48:	0001f697          	auipc	a3,0x1f
    80005f4c:	0b868693          	addi	a3,a3,184 # 80025000 <disk+0x2000>
    80005f50:	6298                	ld	a4,0(a3)
    80005f52:	9732                	add	a4,a4,a2
    80005f54:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80005f56:	6298                	ld	a4,0(a3)
    80005f58:	9732                	add	a4,a4,a2
    80005f5a:	4541                	li	a0,16
    80005f5c:	c708                	sw	a0,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80005f5e:	6298                	ld	a4,0(a3)
    80005f60:	9732                	add	a4,a4,a2
    80005f62:	4505                	li	a0,1
    80005f64:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[0]].next = idx[1];
    80005f68:	f9442703          	lw	a4,-108(s0)
    80005f6c:	6288                	ld	a0,0(a3)
    80005f6e:	962a                	add	a2,a2,a0
    80005f70:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd800e>

  disk.desc[idx[1]].addr = (uint64) b->data;
    80005f74:	0712                	slli	a4,a4,0x4
    80005f76:	6290                	ld	a2,0(a3)
    80005f78:	963a                	add	a2,a2,a4
    80005f7a:	05890513          	addi	a0,s2,88
    80005f7e:	e208                	sd	a0,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    80005f80:	6294                	ld	a3,0(a3)
    80005f82:	96ba                	add	a3,a3,a4
    80005f84:	40000613          	li	a2,1024
    80005f88:	c690                	sw	a2,8(a3)
  if(write)
    80005f8a:	140d0063          	beqz	s10,800060ca <virtio_disk_rw+0x294>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    80005f8e:	0001f697          	auipc	a3,0x1f
    80005f92:	0726b683          	ld	a3,114(a3) # 80025000 <disk+0x2000>
    80005f96:	96ba                	add	a3,a3,a4
    80005f98:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80005f9c:	0001d817          	auipc	a6,0x1d
    80005fa0:	06480813          	addi	a6,a6,100 # 80023000 <disk>
    80005fa4:	0001f517          	auipc	a0,0x1f
    80005fa8:	05c50513          	addi	a0,a0,92 # 80025000 <disk+0x2000>
    80005fac:	6114                	ld	a3,0(a0)
    80005fae:	96ba                	add	a3,a3,a4
    80005fb0:	00c6d603          	lhu	a2,12(a3)
    80005fb4:	00166613          	ori	a2,a2,1
    80005fb8:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    80005fbc:	f9842683          	lw	a3,-104(s0)
    80005fc0:	6110                	ld	a2,0(a0)
    80005fc2:	9732                	add	a4,a4,a2
    80005fc4:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80005fc8:	20058613          	addi	a2,a1,512
    80005fcc:	0612                	slli	a2,a2,0x4
    80005fce:	9642                	add	a2,a2,a6
    80005fd0:	577d                	li	a4,-1
    80005fd2:	02e60823          	sb	a4,48(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80005fd6:	00469713          	slli	a4,a3,0x4
    80005fda:	6114                	ld	a3,0(a0)
    80005fdc:	96ba                	add	a3,a3,a4
    80005fde:	03078793          	addi	a5,a5,48
    80005fe2:	97c2                	add	a5,a5,a6
    80005fe4:	e29c                	sd	a5,0(a3)
  disk.desc[idx[2]].len = 1;
    80005fe6:	611c                	ld	a5,0(a0)
    80005fe8:	97ba                	add	a5,a5,a4
    80005fea:	4685                	li	a3,1
    80005fec:	c794                	sw	a3,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80005fee:	611c                	ld	a5,0(a0)
    80005ff0:	97ba                	add	a5,a5,a4
    80005ff2:	4809                	li	a6,2
    80005ff4:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80005ff8:	611c                	ld	a5,0(a0)
    80005ffa:	973e                	add	a4,a4,a5
    80005ffc:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006000:	00d92223          	sw	a3,4(s2)
  disk.info[idx[0]].b = b;
    80006004:	03263423          	sd	s2,40(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006008:	6518                	ld	a4,8(a0)
    8000600a:	00275783          	lhu	a5,2(a4)
    8000600e:	8b9d                	andi	a5,a5,7
    80006010:	0786                	slli	a5,a5,0x1
    80006012:	97ba                	add	a5,a5,a4
    80006014:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    80006018:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    8000601c:	6518                	ld	a4,8(a0)
    8000601e:	00275783          	lhu	a5,2(a4)
    80006022:	2785                	addiw	a5,a5,1
    80006024:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006028:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    8000602c:	100017b7          	lui	a5,0x10001
    80006030:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006034:	00492703          	lw	a4,4(s2)
    80006038:	4785                	li	a5,1
    8000603a:	02f71163          	bne	a4,a5,8000605c <virtio_disk_rw+0x226>
    sleep(b, &disk.vdisk_lock);
    8000603e:	0001f997          	auipc	s3,0x1f
    80006042:	0ea98993          	addi	s3,s3,234 # 80025128 <disk+0x2128>
  while(b->disk == 1) {
    80006046:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006048:	85ce                	mv	a1,s3
    8000604a:	854a                	mv	a0,s2
    8000604c:	ffffc097          	auipc	ra,0xffffc
    80006050:	09c080e7          	jalr	156(ra) # 800020e8 <sleep>
  while(b->disk == 1) {
    80006054:	00492783          	lw	a5,4(s2)
    80006058:	fe9788e3          	beq	a5,s1,80006048 <virtio_disk_rw+0x212>
  }

  disk.info[idx[0]].b = 0;
    8000605c:	f9042903          	lw	s2,-112(s0)
    80006060:	20090793          	addi	a5,s2,512
    80006064:	00479713          	slli	a4,a5,0x4
    80006068:	0001d797          	auipc	a5,0x1d
    8000606c:	f9878793          	addi	a5,a5,-104 # 80023000 <disk>
    80006070:	97ba                	add	a5,a5,a4
    80006072:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    80006076:	0001f997          	auipc	s3,0x1f
    8000607a:	f8a98993          	addi	s3,s3,-118 # 80025000 <disk+0x2000>
    8000607e:	00491713          	slli	a4,s2,0x4
    80006082:	0009b783          	ld	a5,0(s3)
    80006086:	97ba                	add	a5,a5,a4
    80006088:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    8000608c:	854a                	mv	a0,s2
    8000608e:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006092:	00000097          	auipc	ra,0x0
    80006096:	bc4080e7          	jalr	-1084(ra) # 80005c56 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    8000609a:	8885                	andi	s1,s1,1
    8000609c:	f0ed                	bnez	s1,8000607e <virtio_disk_rw+0x248>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    8000609e:	0001f517          	auipc	a0,0x1f
    800060a2:	08a50513          	addi	a0,a0,138 # 80025128 <disk+0x2128>
    800060a6:	ffffb097          	auipc	ra,0xffffb
    800060aa:	bf2080e7          	jalr	-1038(ra) # 80000c98 <release>
}
    800060ae:	70a6                	ld	ra,104(sp)
    800060b0:	7406                	ld	s0,96(sp)
    800060b2:	64e6                	ld	s1,88(sp)
    800060b4:	6946                	ld	s2,80(sp)
    800060b6:	69a6                	ld	s3,72(sp)
    800060b8:	6a06                	ld	s4,64(sp)
    800060ba:	7ae2                	ld	s5,56(sp)
    800060bc:	7b42                	ld	s6,48(sp)
    800060be:	7ba2                	ld	s7,40(sp)
    800060c0:	7c02                	ld	s8,32(sp)
    800060c2:	6ce2                	ld	s9,24(sp)
    800060c4:	6d42                	ld	s10,16(sp)
    800060c6:	6165                	addi	sp,sp,112
    800060c8:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    800060ca:	0001f697          	auipc	a3,0x1f
    800060ce:	f366b683          	ld	a3,-202(a3) # 80025000 <disk+0x2000>
    800060d2:	96ba                	add	a3,a3,a4
    800060d4:	4609                	li	a2,2
    800060d6:	00c69623          	sh	a2,12(a3)
    800060da:	b5c9                	j	80005f9c <virtio_disk_rw+0x166>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800060dc:	f9042583          	lw	a1,-112(s0)
    800060e0:	20058793          	addi	a5,a1,512
    800060e4:	0792                	slli	a5,a5,0x4
    800060e6:	0001d517          	auipc	a0,0x1d
    800060ea:	fc250513          	addi	a0,a0,-62 # 800230a8 <disk+0xa8>
    800060ee:	953e                	add	a0,a0,a5
  if(write)
    800060f0:	e20d11e3          	bnez	s10,80005f12 <virtio_disk_rw+0xdc>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    800060f4:	20058713          	addi	a4,a1,512
    800060f8:	00471693          	slli	a3,a4,0x4
    800060fc:	0001d717          	auipc	a4,0x1d
    80006100:	f0470713          	addi	a4,a4,-252 # 80023000 <disk>
    80006104:	9736                	add	a4,a4,a3
    80006106:	0a072423          	sw	zero,168(a4)
    8000610a:	b505                	j	80005f2a <virtio_disk_rw+0xf4>

000000008000610c <virtio_disk_intr>:

void
virtio_disk_intr()
{
    8000610c:	1101                	addi	sp,sp,-32
    8000610e:	ec06                	sd	ra,24(sp)
    80006110:	e822                	sd	s0,16(sp)
    80006112:	e426                	sd	s1,8(sp)
    80006114:	e04a                	sd	s2,0(sp)
    80006116:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006118:	0001f517          	auipc	a0,0x1f
    8000611c:	01050513          	addi	a0,a0,16 # 80025128 <disk+0x2128>
    80006120:	ffffb097          	auipc	ra,0xffffb
    80006124:	ac4080e7          	jalr	-1340(ra) # 80000be4 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006128:	10001737          	lui	a4,0x10001
    8000612c:	533c                	lw	a5,96(a4)
    8000612e:	8b8d                	andi	a5,a5,3
    80006130:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006132:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006136:	0001f797          	auipc	a5,0x1f
    8000613a:	eca78793          	addi	a5,a5,-310 # 80025000 <disk+0x2000>
    8000613e:	6b94                	ld	a3,16(a5)
    80006140:	0207d703          	lhu	a4,32(a5)
    80006144:	0026d783          	lhu	a5,2(a3)
    80006148:	06f70163          	beq	a4,a5,800061aa <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    8000614c:	0001d917          	auipc	s2,0x1d
    80006150:	eb490913          	addi	s2,s2,-332 # 80023000 <disk>
    80006154:	0001f497          	auipc	s1,0x1f
    80006158:	eac48493          	addi	s1,s1,-340 # 80025000 <disk+0x2000>
    __sync_synchronize();
    8000615c:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006160:	6898                	ld	a4,16(s1)
    80006162:	0204d783          	lhu	a5,32(s1)
    80006166:	8b9d                	andi	a5,a5,7
    80006168:	078e                	slli	a5,a5,0x3
    8000616a:	97ba                	add	a5,a5,a4
    8000616c:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    8000616e:	20078713          	addi	a4,a5,512
    80006172:	0712                	slli	a4,a4,0x4
    80006174:	974a                	add	a4,a4,s2
    80006176:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    8000617a:	e731                	bnez	a4,800061c6 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    8000617c:	20078793          	addi	a5,a5,512
    80006180:	0792                	slli	a5,a5,0x4
    80006182:	97ca                	add	a5,a5,s2
    80006184:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    80006186:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000618a:	ffffc097          	auipc	ra,0xffffc
    8000618e:	0ea080e7          	jalr	234(ra) # 80002274 <wakeup>

    disk.used_idx += 1;
    80006192:	0204d783          	lhu	a5,32(s1)
    80006196:	2785                	addiw	a5,a5,1
    80006198:	17c2                	slli	a5,a5,0x30
    8000619a:	93c1                	srli	a5,a5,0x30
    8000619c:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    800061a0:	6898                	ld	a4,16(s1)
    800061a2:	00275703          	lhu	a4,2(a4)
    800061a6:	faf71be3          	bne	a4,a5,8000615c <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    800061aa:	0001f517          	auipc	a0,0x1f
    800061ae:	f7e50513          	addi	a0,a0,-130 # 80025128 <disk+0x2128>
    800061b2:	ffffb097          	auipc	ra,0xffffb
    800061b6:	ae6080e7          	jalr	-1306(ra) # 80000c98 <release>
}
    800061ba:	60e2                	ld	ra,24(sp)
    800061bc:	6442                	ld	s0,16(sp)
    800061be:	64a2                	ld	s1,8(sp)
    800061c0:	6902                	ld	s2,0(sp)
    800061c2:	6105                	addi	sp,sp,32
    800061c4:	8082                	ret
      panic("virtio_disk_intr status");
    800061c6:	00002517          	auipc	a0,0x2
    800061ca:	63a50513          	addi	a0,a0,1594 # 80008800 <syscalls+0x3b0>
    800061ce:	ffffa097          	auipc	ra,0xffffa
    800061d2:	370080e7          	jalr	880(ra) # 8000053e <panic>
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
