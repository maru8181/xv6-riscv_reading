
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
    80000068:	b7c78793          	addi	a5,a5,-1156 # 80005be0 <timervec>
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
    80000ee0:	d44080e7          	jalr	-700(ra) # 80005c20 <plicinithart>
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
    80000f60:	cae080e7          	jalr	-850(ra) # 80005c0a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f64:	00005097          	auipc	ra,0x5
    80000f68:	cbc080e7          	jalr	-836(ra) # 80005c20 <plicinithart>
		binit();         // buffer cache
    80000f6c:	00002097          	auipc	ra,0x2
    80000f70:	e9e080e7          	jalr	-354(ra) # 80002e0a <binit>
		iinit();         // inode table
    80000f74:	00002097          	auipc	ra,0x2
    80000f78:	52e080e7          	jalr	1326(ra) # 800034a2 <iinit>
		fileinit();      // file table
    80000f7c:	00003097          	auipc	ra,0x3
    80000f80:	4d8080e7          	jalr	1240(ra) # 80004454 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f84:	00005097          	auipc	ra,0x5
    80000f88:	dbe080e7          	jalr	-578(ra) # 80005d42 <virtio_disk_init>
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
	uint64 a, last;
	pte_t *pte;

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
		if(*pte & PTE_V)
			panic("mappages: remap");
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
		if(*pte & PTE_V)
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
    80001aa4:	982080e7          	jalr	-1662(ra) # 80003422 <fsinit>
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
    80001d66:	0ee080e7          	jalr	238(ra) # 80003e50 <namei>
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
    80001e9c:	64e080e7          	jalr	1614(ra) # 800044e6 <filedup>
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
    80001ebe:	7a2080e7          	jalr	1954(ra) # 8000365c <idup>
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
    80002388:	1b4080e7          	jalr	436(ra) # 80004538 <fileclose>
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
    800023a0:	cd0080e7          	jalr	-816(ra) # 8000406c <begin_op>
	iput(p->cwd);
    800023a4:	1509b503          	ld	a0,336(s3)
    800023a8:	00001097          	auipc	ra,0x1
    800023ac:	4ac080e7          	jalr	1196(ra) # 80003854 <iput>
	end_op();
    800023b0:	00002097          	auipc	ra,0x2
    800023b4:	d3c080e7          	jalr	-708(ra) # 800040ec <end_op>
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
    80002682:	4d278793          	addi	a5,a5,1234 # 80005b50 <kernelvec>
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
    800027aa:	4b2080e7          	jalr	1202(ra) # 80005c58 <plic_claim>
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
    800027d8:	4a8080e7          	jalr	1192(ra) # 80005c7c <plic_complete>
    return 1;
    800027dc:	4505                	li	a0,1
    800027de:	bf55                	j	80002792 <devintr+0x1e>
      uartintr();
    800027e0:	ffffe097          	auipc	ra,0xffffe
    800027e4:	1c8080e7          	jalr	456(ra) # 800009a8 <uartintr>
    800027e8:	b7ed                	j	800027d2 <devintr+0x5e>
      virtio_disk_intr();
    800027ea:	00004097          	auipc	ra,0x4
    800027ee:	972080e7          	jalr	-1678(ra) # 8000615c <virtio_disk_intr>
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
    80002830:	32478793          	addi	a5,a5,804 # 80005b50 <kernelvec>
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
    80002c58:	e84a                	sd	s2,16(sp)
    80002c5a:	1800                	addi	s0,sp,48
	int addr;
	int n;
	struct proc *p = myproc();
    80002c5c:	fffff097          	auipc	ra,0xfffff
    80002c60:	dd0080e7          	jalr	-560(ra) # 80001a2c <myproc>
    80002c64:	84aa                	mv	s1,a0

	if(argint(0, &n) < 0)
    80002c66:	fdc40593          	addi	a1,s0,-36
    80002c6a:	4501                	li	a0,0
    80002c6c:	00000097          	auipc	ra,0x0
    80002c70:	e6c080e7          	jalr	-404(ra) # 80002ad8 <argint>
		return -1;
    80002c74:	57fd                	li	a5,-1
	if(argint(0, &n) < 0)
    80002c76:	06054363          	bltz	a0,80002cdc <sys_sbrk+0x8c>
	addr = myproc()->sz;
    80002c7a:	fffff097          	auipc	ra,0xfffff
    80002c7e:	db2080e7          	jalr	-590(ra) # 80001a2c <myproc>
    80002c82:	04853903          	ld	s2,72(a0)

	printf("%x\n", p->sz);
    80002c86:	64ac                	ld	a1,72(s1)
    80002c88:	00005517          	auipc	a0,0x5
    80002c8c:	55050513          	addi	a0,a0,1360 # 800081d8 <digits+0x198>
    80002c90:	ffffe097          	auipc	ra,0xffffe
    80002c94:	8f8080e7          	jalr	-1800(ra) # 80000588 <printf>
	debug_uvmpte(p->pagetable, 0, p->sz);
    80002c98:	64b0                	ld	a2,72(s1)
    80002c9a:	4581                	li	a1,0
    80002c9c:	68a8                	ld	a0,80(s1)
    80002c9e:	fffff097          	auipc	ra,0xfffff
    80002ca2:	ba0080e7          	jalr	-1120(ra) # 8000183e <debug_uvmpte>

	if(growproc(n) < 0)
    80002ca6:	fdc42503          	lw	a0,-36(s0)
    80002caa:	fffff097          	auipc	ra,0xfffff
    80002cae:	0dc080e7          	jalr	220(ra) # 80001d86 <growproc>
		return -1;
    80002cb2:	57fd                	li	a5,-1
	if(growproc(n) < 0)
    80002cb4:	02054463          	bltz	a0,80002cdc <sys_sbrk+0x8c>

	printf("%x\n", p->sz);
    80002cb8:	64ac                	ld	a1,72(s1)
    80002cba:	00005517          	auipc	a0,0x5
    80002cbe:	51e50513          	addi	a0,a0,1310 # 800081d8 <digits+0x198>
    80002cc2:	ffffe097          	auipc	ra,0xffffe
    80002cc6:	8c6080e7          	jalr	-1850(ra) # 80000588 <printf>
	debug_uvmpte(p->pagetable, 0, p->sz);
    80002cca:	64b0                	ld	a2,72(s1)
    80002ccc:	4581                	li	a1,0
    80002cce:	68a8                	ld	a0,80(s1)
    80002cd0:	fffff097          	auipc	ra,0xfffff
    80002cd4:	b6e080e7          	jalr	-1170(ra) # 8000183e <debug_uvmpte>

	return addr;
    80002cd8:	0009079b          	sext.w	a5,s2
}
    80002cdc:	853e                	mv	a0,a5
    80002cde:	70a2                	ld	ra,40(sp)
    80002ce0:	7402                	ld	s0,32(sp)
    80002ce2:	64e2                	ld	s1,24(sp)
    80002ce4:	6942                	ld	s2,16(sp)
    80002ce6:	6145                	addi	sp,sp,48
    80002ce8:	8082                	ret

0000000080002cea <sys_sleep>:

uint64
sys_sleep(void)
{
    80002cea:	7139                	addi	sp,sp,-64
    80002cec:	fc06                	sd	ra,56(sp)
    80002cee:	f822                	sd	s0,48(sp)
    80002cf0:	f426                	sd	s1,40(sp)
    80002cf2:	f04a                	sd	s2,32(sp)
    80002cf4:	ec4e                	sd	s3,24(sp)
    80002cf6:	0080                	addi	s0,sp,64
	int n;
	uint ticks0;

	if(argint(0, &n) < 0)
    80002cf8:	fcc40593          	addi	a1,s0,-52
    80002cfc:	4501                	li	a0,0
    80002cfe:	00000097          	auipc	ra,0x0
    80002d02:	dda080e7          	jalr	-550(ra) # 80002ad8 <argint>
		return -1;
    80002d06:	57fd                	li	a5,-1
	if(argint(0, &n) < 0)
    80002d08:	06054563          	bltz	a0,80002d72 <sys_sleep+0x88>
	acquire(&tickslock);
    80002d0c:	00014517          	auipc	a0,0x14
    80002d10:	3c450513          	addi	a0,a0,964 # 800170d0 <tickslock>
    80002d14:	ffffe097          	auipc	ra,0xffffe
    80002d18:	ed0080e7          	jalr	-304(ra) # 80000be4 <acquire>
	ticks0 = ticks;
    80002d1c:	00006917          	auipc	s2,0x6
    80002d20:	31492903          	lw	s2,788(s2) # 80009030 <ticks>
	while(ticks - ticks0 < n){
    80002d24:	fcc42783          	lw	a5,-52(s0)
    80002d28:	cf85                	beqz	a5,80002d60 <sys_sleep+0x76>
		if(myproc()->killed){
			release(&tickslock);
			return -1;
		}
		sleep(&ticks, &tickslock);
    80002d2a:	00014997          	auipc	s3,0x14
    80002d2e:	3a698993          	addi	s3,s3,934 # 800170d0 <tickslock>
    80002d32:	00006497          	auipc	s1,0x6
    80002d36:	2fe48493          	addi	s1,s1,766 # 80009030 <ticks>
		if(myproc()->killed){
    80002d3a:	fffff097          	auipc	ra,0xfffff
    80002d3e:	cf2080e7          	jalr	-782(ra) # 80001a2c <myproc>
    80002d42:	551c                	lw	a5,40(a0)
    80002d44:	ef9d                	bnez	a5,80002d82 <sys_sleep+0x98>
		sleep(&ticks, &tickslock);
    80002d46:	85ce                	mv	a1,s3
    80002d48:	8526                	mv	a0,s1
    80002d4a:	fffff097          	auipc	ra,0xfffff
    80002d4e:	39e080e7          	jalr	926(ra) # 800020e8 <sleep>
	while(ticks - ticks0 < n){
    80002d52:	409c                	lw	a5,0(s1)
    80002d54:	412787bb          	subw	a5,a5,s2
    80002d58:	fcc42703          	lw	a4,-52(s0)
    80002d5c:	fce7efe3          	bltu	a5,a4,80002d3a <sys_sleep+0x50>
	}
	release(&tickslock);
    80002d60:	00014517          	auipc	a0,0x14
    80002d64:	37050513          	addi	a0,a0,880 # 800170d0 <tickslock>
    80002d68:	ffffe097          	auipc	ra,0xffffe
    80002d6c:	f30080e7          	jalr	-208(ra) # 80000c98 <release>
	return 0;
    80002d70:	4781                	li	a5,0
}
    80002d72:	853e                	mv	a0,a5
    80002d74:	70e2                	ld	ra,56(sp)
    80002d76:	7442                	ld	s0,48(sp)
    80002d78:	74a2                	ld	s1,40(sp)
    80002d7a:	7902                	ld	s2,32(sp)
    80002d7c:	69e2                	ld	s3,24(sp)
    80002d7e:	6121                	addi	sp,sp,64
    80002d80:	8082                	ret
			release(&tickslock);
    80002d82:	00014517          	auipc	a0,0x14
    80002d86:	34e50513          	addi	a0,a0,846 # 800170d0 <tickslock>
    80002d8a:	ffffe097          	auipc	ra,0xffffe
    80002d8e:	f0e080e7          	jalr	-242(ra) # 80000c98 <release>
			return -1;
    80002d92:	57fd                	li	a5,-1
    80002d94:	bff9                	j	80002d72 <sys_sleep+0x88>

0000000080002d96 <sys_kill>:

uint64
sys_kill(void)
{
    80002d96:	1101                	addi	sp,sp,-32
    80002d98:	ec06                	sd	ra,24(sp)
    80002d9a:	e822                	sd	s0,16(sp)
    80002d9c:	1000                	addi	s0,sp,32
	int pid;

	if(argint(0, &pid) < 0)
    80002d9e:	fec40593          	addi	a1,s0,-20
    80002da2:	4501                	li	a0,0
    80002da4:	00000097          	auipc	ra,0x0
    80002da8:	d34080e7          	jalr	-716(ra) # 80002ad8 <argint>
    80002dac:	87aa                	mv	a5,a0
		return -1;
    80002dae:	557d                	li	a0,-1
	if(argint(0, &pid) < 0)
    80002db0:	0007c863          	bltz	a5,80002dc0 <sys_kill+0x2a>
	return kill(pid);
    80002db4:	fec42503          	lw	a0,-20(s0)
    80002db8:	fffff097          	auipc	ra,0xfffff
    80002dbc:	662080e7          	jalr	1634(ra) # 8000241a <kill>
}
    80002dc0:	60e2                	ld	ra,24(sp)
    80002dc2:	6442                	ld	s0,16(sp)
    80002dc4:	6105                	addi	sp,sp,32
    80002dc6:	8082                	ret

0000000080002dc8 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002dc8:	1101                	addi	sp,sp,-32
    80002dca:	ec06                	sd	ra,24(sp)
    80002dcc:	e822                	sd	s0,16(sp)
    80002dce:	e426                	sd	s1,8(sp)
    80002dd0:	1000                	addi	s0,sp,32
	uint xticks;

	acquire(&tickslock);
    80002dd2:	00014517          	auipc	a0,0x14
    80002dd6:	2fe50513          	addi	a0,a0,766 # 800170d0 <tickslock>
    80002dda:	ffffe097          	auipc	ra,0xffffe
    80002dde:	e0a080e7          	jalr	-502(ra) # 80000be4 <acquire>
	xticks = ticks;
    80002de2:	00006497          	auipc	s1,0x6
    80002de6:	24e4a483          	lw	s1,590(s1) # 80009030 <ticks>
	release(&tickslock);
    80002dea:	00014517          	auipc	a0,0x14
    80002dee:	2e650513          	addi	a0,a0,742 # 800170d0 <tickslock>
    80002df2:	ffffe097          	auipc	ra,0xffffe
    80002df6:	ea6080e7          	jalr	-346(ra) # 80000c98 <release>
	return xticks;
}
    80002dfa:	02049513          	slli	a0,s1,0x20
    80002dfe:	9101                	srli	a0,a0,0x20
    80002e00:	60e2                	ld	ra,24(sp)
    80002e02:	6442                	ld	s0,16(sp)
    80002e04:	64a2                	ld	s1,8(sp)
    80002e06:	6105                	addi	sp,sp,32
    80002e08:	8082                	ret

0000000080002e0a <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002e0a:	7179                	addi	sp,sp,-48
    80002e0c:	f406                	sd	ra,40(sp)
    80002e0e:	f022                	sd	s0,32(sp)
    80002e10:	ec26                	sd	s1,24(sp)
    80002e12:	e84a                	sd	s2,16(sp)
    80002e14:	e44e                	sd	s3,8(sp)
    80002e16:	e052                	sd	s4,0(sp)
    80002e18:	1800                	addi	s0,sp,48
	struct buf *b;

	initlock(&bcache.lock, "bcache");
    80002e1a:	00005597          	auipc	a1,0x5
    80002e1e:	6e658593          	addi	a1,a1,1766 # 80008500 <syscalls+0xb0>
    80002e22:	00014517          	auipc	a0,0x14
    80002e26:	2c650513          	addi	a0,a0,710 # 800170e8 <bcache>
    80002e2a:	ffffe097          	auipc	ra,0xffffe
    80002e2e:	d2a080e7          	jalr	-726(ra) # 80000b54 <initlock>

	// Create linked list of buffers
	bcache.head.prev = &bcache.head;
    80002e32:	0001c797          	auipc	a5,0x1c
    80002e36:	2b678793          	addi	a5,a5,694 # 8001f0e8 <bcache+0x8000>
    80002e3a:	0001c717          	auipc	a4,0x1c
    80002e3e:	51670713          	addi	a4,a4,1302 # 8001f350 <bcache+0x8268>
    80002e42:	2ae7b823          	sd	a4,688(a5)
	bcache.head.next = &bcache.head;
    80002e46:	2ae7bc23          	sd	a4,696(a5)
	for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002e4a:	00014497          	auipc	s1,0x14
    80002e4e:	2b648493          	addi	s1,s1,694 # 80017100 <bcache+0x18>
		b->next = bcache.head.next;
    80002e52:	893e                	mv	s2,a5
		b->prev = &bcache.head;
    80002e54:	89ba                	mv	s3,a4
		initsleeplock(&b->lock, "buffer");
    80002e56:	00005a17          	auipc	s4,0x5
    80002e5a:	6b2a0a13          	addi	s4,s4,1714 # 80008508 <syscalls+0xb8>
		b->next = bcache.head.next;
    80002e5e:	2b893783          	ld	a5,696(s2)
    80002e62:	e8bc                	sd	a5,80(s1)
		b->prev = &bcache.head;
    80002e64:	0534b423          	sd	s3,72(s1)
		initsleeplock(&b->lock, "buffer");
    80002e68:	85d2                	mv	a1,s4
    80002e6a:	01048513          	addi	a0,s1,16
    80002e6e:	00001097          	auipc	ra,0x1
    80002e72:	4bc080e7          	jalr	1212(ra) # 8000432a <initsleeplock>
		bcache.head.next->prev = b;
    80002e76:	2b893783          	ld	a5,696(s2)
    80002e7a:	e7a4                	sd	s1,72(a5)
		bcache.head.next = b;
    80002e7c:	2a993c23          	sd	s1,696(s2)
	for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002e80:	45848493          	addi	s1,s1,1112
    80002e84:	fd349de3          	bne	s1,s3,80002e5e <binit+0x54>
	}
}
    80002e88:	70a2                	ld	ra,40(sp)
    80002e8a:	7402                	ld	s0,32(sp)
    80002e8c:	64e2                	ld	s1,24(sp)
    80002e8e:	6942                	ld	s2,16(sp)
    80002e90:	69a2                	ld	s3,8(sp)
    80002e92:	6a02                	ld	s4,0(sp)
    80002e94:	6145                	addi	sp,sp,48
    80002e96:	8082                	ret

0000000080002e98 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80002e98:	7179                	addi	sp,sp,-48
    80002e9a:	f406                	sd	ra,40(sp)
    80002e9c:	f022                	sd	s0,32(sp)
    80002e9e:	ec26                	sd	s1,24(sp)
    80002ea0:	e84a                	sd	s2,16(sp)
    80002ea2:	e44e                	sd	s3,8(sp)
    80002ea4:	1800                	addi	s0,sp,48
    80002ea6:	89aa                	mv	s3,a0
    80002ea8:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    80002eaa:	00014517          	auipc	a0,0x14
    80002eae:	23e50513          	addi	a0,a0,574 # 800170e8 <bcache>
    80002eb2:	ffffe097          	auipc	ra,0xffffe
    80002eb6:	d32080e7          	jalr	-718(ra) # 80000be4 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80002eba:	0001c497          	auipc	s1,0x1c
    80002ebe:	4e64b483          	ld	s1,1254(s1) # 8001f3a0 <bcache+0x82b8>
    80002ec2:	0001c797          	auipc	a5,0x1c
    80002ec6:	48e78793          	addi	a5,a5,1166 # 8001f350 <bcache+0x8268>
    80002eca:	02f48f63          	beq	s1,a5,80002f08 <bread+0x70>
    80002ece:	873e                	mv	a4,a5
    80002ed0:	a021                	j	80002ed8 <bread+0x40>
    80002ed2:	68a4                	ld	s1,80(s1)
    80002ed4:	02e48a63          	beq	s1,a4,80002f08 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80002ed8:	449c                	lw	a5,8(s1)
    80002eda:	ff379ce3          	bne	a5,s3,80002ed2 <bread+0x3a>
    80002ede:	44dc                	lw	a5,12(s1)
    80002ee0:	ff2799e3          	bne	a5,s2,80002ed2 <bread+0x3a>
      b->refcnt++;
    80002ee4:	40bc                	lw	a5,64(s1)
    80002ee6:	2785                	addiw	a5,a5,1
    80002ee8:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002eea:	00014517          	auipc	a0,0x14
    80002eee:	1fe50513          	addi	a0,a0,510 # 800170e8 <bcache>
    80002ef2:	ffffe097          	auipc	ra,0xffffe
    80002ef6:	da6080e7          	jalr	-602(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    80002efa:	01048513          	addi	a0,s1,16
    80002efe:	00001097          	auipc	ra,0x1
    80002f02:	466080e7          	jalr	1126(ra) # 80004364 <acquiresleep>
      return b;
    80002f06:	a8b9                	j	80002f64 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002f08:	0001c497          	auipc	s1,0x1c
    80002f0c:	4904b483          	ld	s1,1168(s1) # 8001f398 <bcache+0x82b0>
    80002f10:	0001c797          	auipc	a5,0x1c
    80002f14:	44078793          	addi	a5,a5,1088 # 8001f350 <bcache+0x8268>
    80002f18:	00f48863          	beq	s1,a5,80002f28 <bread+0x90>
    80002f1c:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80002f1e:	40bc                	lw	a5,64(s1)
    80002f20:	cf81                	beqz	a5,80002f38 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002f22:	64a4                	ld	s1,72(s1)
    80002f24:	fee49de3          	bne	s1,a4,80002f1e <bread+0x86>
  panic("bget: no buffers");
    80002f28:	00005517          	auipc	a0,0x5
    80002f2c:	5e850513          	addi	a0,a0,1512 # 80008510 <syscalls+0xc0>
    80002f30:	ffffd097          	auipc	ra,0xffffd
    80002f34:	60e080e7          	jalr	1550(ra) # 8000053e <panic>
      b->dev = dev;
    80002f38:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    80002f3c:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    80002f40:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80002f44:	4785                	li	a5,1
    80002f46:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002f48:	00014517          	auipc	a0,0x14
    80002f4c:	1a050513          	addi	a0,a0,416 # 800170e8 <bcache>
    80002f50:	ffffe097          	auipc	ra,0xffffe
    80002f54:	d48080e7          	jalr	-696(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    80002f58:	01048513          	addi	a0,s1,16
    80002f5c:	00001097          	auipc	ra,0x1
    80002f60:	408080e7          	jalr	1032(ra) # 80004364 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80002f64:	409c                	lw	a5,0(s1)
    80002f66:	cb89                	beqz	a5,80002f78 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80002f68:	8526                	mv	a0,s1
    80002f6a:	70a2                	ld	ra,40(sp)
    80002f6c:	7402                	ld	s0,32(sp)
    80002f6e:	64e2                	ld	s1,24(sp)
    80002f70:	6942                	ld	s2,16(sp)
    80002f72:	69a2                	ld	s3,8(sp)
    80002f74:	6145                	addi	sp,sp,48
    80002f76:	8082                	ret
    virtio_disk_rw(b, 0);
    80002f78:	4581                	li	a1,0
    80002f7a:	8526                	mv	a0,s1
    80002f7c:	00003097          	auipc	ra,0x3
    80002f80:	f0a080e7          	jalr	-246(ra) # 80005e86 <virtio_disk_rw>
    b->valid = 1;
    80002f84:	4785                	li	a5,1
    80002f86:	c09c                	sw	a5,0(s1)
  return b;
    80002f88:	b7c5                	j	80002f68 <bread+0xd0>

0000000080002f8a <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80002f8a:	1101                	addi	sp,sp,-32
    80002f8c:	ec06                	sd	ra,24(sp)
    80002f8e:	e822                	sd	s0,16(sp)
    80002f90:	e426                	sd	s1,8(sp)
    80002f92:	1000                	addi	s0,sp,32
    80002f94:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80002f96:	0541                	addi	a0,a0,16
    80002f98:	00001097          	auipc	ra,0x1
    80002f9c:	466080e7          	jalr	1126(ra) # 800043fe <holdingsleep>
    80002fa0:	cd01                	beqz	a0,80002fb8 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80002fa2:	4585                	li	a1,1
    80002fa4:	8526                	mv	a0,s1
    80002fa6:	00003097          	auipc	ra,0x3
    80002faa:	ee0080e7          	jalr	-288(ra) # 80005e86 <virtio_disk_rw>
}
    80002fae:	60e2                	ld	ra,24(sp)
    80002fb0:	6442                	ld	s0,16(sp)
    80002fb2:	64a2                	ld	s1,8(sp)
    80002fb4:	6105                	addi	sp,sp,32
    80002fb6:	8082                	ret
    panic("bwrite");
    80002fb8:	00005517          	auipc	a0,0x5
    80002fbc:	57050513          	addi	a0,a0,1392 # 80008528 <syscalls+0xd8>
    80002fc0:	ffffd097          	auipc	ra,0xffffd
    80002fc4:	57e080e7          	jalr	1406(ra) # 8000053e <panic>

0000000080002fc8 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80002fc8:	1101                	addi	sp,sp,-32
    80002fca:	ec06                	sd	ra,24(sp)
    80002fcc:	e822                	sd	s0,16(sp)
    80002fce:	e426                	sd	s1,8(sp)
    80002fd0:	e04a                	sd	s2,0(sp)
    80002fd2:	1000                	addi	s0,sp,32
    80002fd4:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80002fd6:	01050913          	addi	s2,a0,16
    80002fda:	854a                	mv	a0,s2
    80002fdc:	00001097          	auipc	ra,0x1
    80002fe0:	422080e7          	jalr	1058(ra) # 800043fe <holdingsleep>
    80002fe4:	c92d                	beqz	a0,80003056 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80002fe6:	854a                	mv	a0,s2
    80002fe8:	00001097          	auipc	ra,0x1
    80002fec:	3d2080e7          	jalr	978(ra) # 800043ba <releasesleep>

  acquire(&bcache.lock);
    80002ff0:	00014517          	auipc	a0,0x14
    80002ff4:	0f850513          	addi	a0,a0,248 # 800170e8 <bcache>
    80002ff8:	ffffe097          	auipc	ra,0xffffe
    80002ffc:	bec080e7          	jalr	-1044(ra) # 80000be4 <acquire>
  b->refcnt--;
    80003000:	40bc                	lw	a5,64(s1)
    80003002:	37fd                	addiw	a5,a5,-1
    80003004:	0007871b          	sext.w	a4,a5
    80003008:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    8000300a:	eb05                	bnez	a4,8000303a <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    8000300c:	68bc                	ld	a5,80(s1)
    8000300e:	64b8                	ld	a4,72(s1)
    80003010:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003012:	64bc                	ld	a5,72(s1)
    80003014:	68b8                	ld	a4,80(s1)
    80003016:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003018:	0001c797          	auipc	a5,0x1c
    8000301c:	0d078793          	addi	a5,a5,208 # 8001f0e8 <bcache+0x8000>
    80003020:	2b87b703          	ld	a4,696(a5)
    80003024:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003026:	0001c717          	auipc	a4,0x1c
    8000302a:	32a70713          	addi	a4,a4,810 # 8001f350 <bcache+0x8268>
    8000302e:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003030:	2b87b703          	ld	a4,696(a5)
    80003034:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003036:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    8000303a:	00014517          	auipc	a0,0x14
    8000303e:	0ae50513          	addi	a0,a0,174 # 800170e8 <bcache>
    80003042:	ffffe097          	auipc	ra,0xffffe
    80003046:	c56080e7          	jalr	-938(ra) # 80000c98 <release>
}
    8000304a:	60e2                	ld	ra,24(sp)
    8000304c:	6442                	ld	s0,16(sp)
    8000304e:	64a2                	ld	s1,8(sp)
    80003050:	6902                	ld	s2,0(sp)
    80003052:	6105                	addi	sp,sp,32
    80003054:	8082                	ret
    panic("brelse");
    80003056:	00005517          	auipc	a0,0x5
    8000305a:	4da50513          	addi	a0,a0,1242 # 80008530 <syscalls+0xe0>
    8000305e:	ffffd097          	auipc	ra,0xffffd
    80003062:	4e0080e7          	jalr	1248(ra) # 8000053e <panic>

0000000080003066 <bpin>:

void
bpin(struct buf *b) {
    80003066:	1101                	addi	sp,sp,-32
    80003068:	ec06                	sd	ra,24(sp)
    8000306a:	e822                	sd	s0,16(sp)
    8000306c:	e426                	sd	s1,8(sp)
    8000306e:	1000                	addi	s0,sp,32
    80003070:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003072:	00014517          	auipc	a0,0x14
    80003076:	07650513          	addi	a0,a0,118 # 800170e8 <bcache>
    8000307a:	ffffe097          	auipc	ra,0xffffe
    8000307e:	b6a080e7          	jalr	-1174(ra) # 80000be4 <acquire>
  b->refcnt++;
    80003082:	40bc                	lw	a5,64(s1)
    80003084:	2785                	addiw	a5,a5,1
    80003086:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003088:	00014517          	auipc	a0,0x14
    8000308c:	06050513          	addi	a0,a0,96 # 800170e8 <bcache>
    80003090:	ffffe097          	auipc	ra,0xffffe
    80003094:	c08080e7          	jalr	-1016(ra) # 80000c98 <release>
}
    80003098:	60e2                	ld	ra,24(sp)
    8000309a:	6442                	ld	s0,16(sp)
    8000309c:	64a2                	ld	s1,8(sp)
    8000309e:	6105                	addi	sp,sp,32
    800030a0:	8082                	ret

00000000800030a2 <bunpin>:

void
bunpin(struct buf *b) {
    800030a2:	1101                	addi	sp,sp,-32
    800030a4:	ec06                	sd	ra,24(sp)
    800030a6:	e822                	sd	s0,16(sp)
    800030a8:	e426                	sd	s1,8(sp)
    800030aa:	1000                	addi	s0,sp,32
    800030ac:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800030ae:	00014517          	auipc	a0,0x14
    800030b2:	03a50513          	addi	a0,a0,58 # 800170e8 <bcache>
    800030b6:	ffffe097          	auipc	ra,0xffffe
    800030ba:	b2e080e7          	jalr	-1234(ra) # 80000be4 <acquire>
  b->refcnt--;
    800030be:	40bc                	lw	a5,64(s1)
    800030c0:	37fd                	addiw	a5,a5,-1
    800030c2:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800030c4:	00014517          	auipc	a0,0x14
    800030c8:	02450513          	addi	a0,a0,36 # 800170e8 <bcache>
    800030cc:	ffffe097          	auipc	ra,0xffffe
    800030d0:	bcc080e7          	jalr	-1076(ra) # 80000c98 <release>
}
    800030d4:	60e2                	ld	ra,24(sp)
    800030d6:	6442                	ld	s0,16(sp)
    800030d8:	64a2                	ld	s1,8(sp)
    800030da:	6105                	addi	sp,sp,32
    800030dc:	8082                	ret

00000000800030de <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800030de:	1101                	addi	sp,sp,-32
    800030e0:	ec06                	sd	ra,24(sp)
    800030e2:	e822                	sd	s0,16(sp)
    800030e4:	e426                	sd	s1,8(sp)
    800030e6:	e04a                	sd	s2,0(sp)
    800030e8:	1000                	addi	s0,sp,32
    800030ea:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800030ec:	00d5d59b          	srliw	a1,a1,0xd
    800030f0:	0001c797          	auipc	a5,0x1c
    800030f4:	6d47a783          	lw	a5,1748(a5) # 8001f7c4 <sb+0x1c>
    800030f8:	9dbd                	addw	a1,a1,a5
    800030fa:	00000097          	auipc	ra,0x0
    800030fe:	d9e080e7          	jalr	-610(ra) # 80002e98 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003102:	0074f713          	andi	a4,s1,7
    80003106:	4785                	li	a5,1
    80003108:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    8000310c:	14ce                	slli	s1,s1,0x33
    8000310e:	90d9                	srli	s1,s1,0x36
    80003110:	00950733          	add	a4,a0,s1
    80003114:	05874703          	lbu	a4,88(a4)
    80003118:	00e7f6b3          	and	a3,a5,a4
    8000311c:	c69d                	beqz	a3,8000314a <bfree+0x6c>
    8000311e:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003120:	94aa                	add	s1,s1,a0
    80003122:	fff7c793          	not	a5,a5
    80003126:	8ff9                	and	a5,a5,a4
    80003128:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    8000312c:	00001097          	auipc	ra,0x1
    80003130:	118080e7          	jalr	280(ra) # 80004244 <log_write>
  brelse(bp);
    80003134:	854a                	mv	a0,s2
    80003136:	00000097          	auipc	ra,0x0
    8000313a:	e92080e7          	jalr	-366(ra) # 80002fc8 <brelse>
}
    8000313e:	60e2                	ld	ra,24(sp)
    80003140:	6442                	ld	s0,16(sp)
    80003142:	64a2                	ld	s1,8(sp)
    80003144:	6902                	ld	s2,0(sp)
    80003146:	6105                	addi	sp,sp,32
    80003148:	8082                	ret
    panic("freeing free block");
    8000314a:	00005517          	auipc	a0,0x5
    8000314e:	3ee50513          	addi	a0,a0,1006 # 80008538 <syscalls+0xe8>
    80003152:	ffffd097          	auipc	ra,0xffffd
    80003156:	3ec080e7          	jalr	1004(ra) # 8000053e <panic>

000000008000315a <balloc>:
{
    8000315a:	711d                	addi	sp,sp,-96
    8000315c:	ec86                	sd	ra,88(sp)
    8000315e:	e8a2                	sd	s0,80(sp)
    80003160:	e4a6                	sd	s1,72(sp)
    80003162:	e0ca                	sd	s2,64(sp)
    80003164:	fc4e                	sd	s3,56(sp)
    80003166:	f852                	sd	s4,48(sp)
    80003168:	f456                	sd	s5,40(sp)
    8000316a:	f05a                	sd	s6,32(sp)
    8000316c:	ec5e                	sd	s7,24(sp)
    8000316e:	e862                	sd	s8,16(sp)
    80003170:	e466                	sd	s9,8(sp)
    80003172:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003174:	0001c797          	auipc	a5,0x1c
    80003178:	6387a783          	lw	a5,1592(a5) # 8001f7ac <sb+0x4>
    8000317c:	cbd1                	beqz	a5,80003210 <balloc+0xb6>
    8000317e:	8baa                	mv	s7,a0
    80003180:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003182:	0001cb17          	auipc	s6,0x1c
    80003186:	626b0b13          	addi	s6,s6,1574 # 8001f7a8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000318a:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    8000318c:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000318e:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003190:	6c89                	lui	s9,0x2
    80003192:	a831                	j	800031ae <balloc+0x54>
    brelse(bp);
    80003194:	854a                	mv	a0,s2
    80003196:	00000097          	auipc	ra,0x0
    8000319a:	e32080e7          	jalr	-462(ra) # 80002fc8 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    8000319e:	015c87bb          	addw	a5,s9,s5
    800031a2:	00078a9b          	sext.w	s5,a5
    800031a6:	004b2703          	lw	a4,4(s6)
    800031aa:	06eaf363          	bgeu	s5,a4,80003210 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    800031ae:	41fad79b          	sraiw	a5,s5,0x1f
    800031b2:	0137d79b          	srliw	a5,a5,0x13
    800031b6:	015787bb          	addw	a5,a5,s5
    800031ba:	40d7d79b          	sraiw	a5,a5,0xd
    800031be:	01cb2583          	lw	a1,28(s6)
    800031c2:	9dbd                	addw	a1,a1,a5
    800031c4:	855e                	mv	a0,s7
    800031c6:	00000097          	auipc	ra,0x0
    800031ca:	cd2080e7          	jalr	-814(ra) # 80002e98 <bread>
    800031ce:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800031d0:	004b2503          	lw	a0,4(s6)
    800031d4:	000a849b          	sext.w	s1,s5
    800031d8:	8662                	mv	a2,s8
    800031da:	faa4fde3          	bgeu	s1,a0,80003194 <balloc+0x3a>
      m = 1 << (bi % 8);
    800031de:	41f6579b          	sraiw	a5,a2,0x1f
    800031e2:	01d7d69b          	srliw	a3,a5,0x1d
    800031e6:	00c6873b          	addw	a4,a3,a2
    800031ea:	00777793          	andi	a5,a4,7
    800031ee:	9f95                	subw	a5,a5,a3
    800031f0:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800031f4:	4037571b          	sraiw	a4,a4,0x3
    800031f8:	00e906b3          	add	a3,s2,a4
    800031fc:	0586c683          	lbu	a3,88(a3)
    80003200:	00d7f5b3          	and	a1,a5,a3
    80003204:	cd91                	beqz	a1,80003220 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003206:	2605                	addiw	a2,a2,1
    80003208:	2485                	addiw	s1,s1,1
    8000320a:	fd4618e3          	bne	a2,s4,800031da <balloc+0x80>
    8000320e:	b759                	j	80003194 <balloc+0x3a>
  panic("balloc: out of blocks");
    80003210:	00005517          	auipc	a0,0x5
    80003214:	34050513          	addi	a0,a0,832 # 80008550 <syscalls+0x100>
    80003218:	ffffd097          	auipc	ra,0xffffd
    8000321c:	326080e7          	jalr	806(ra) # 8000053e <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003220:	974a                	add	a4,a4,s2
    80003222:	8fd5                	or	a5,a5,a3
    80003224:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80003228:	854a                	mv	a0,s2
    8000322a:	00001097          	auipc	ra,0x1
    8000322e:	01a080e7          	jalr	26(ra) # 80004244 <log_write>
        brelse(bp);
    80003232:	854a                	mv	a0,s2
    80003234:	00000097          	auipc	ra,0x0
    80003238:	d94080e7          	jalr	-620(ra) # 80002fc8 <brelse>
  bp = bread(dev, bno);
    8000323c:	85a6                	mv	a1,s1
    8000323e:	855e                	mv	a0,s7
    80003240:	00000097          	auipc	ra,0x0
    80003244:	c58080e7          	jalr	-936(ra) # 80002e98 <bread>
    80003248:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    8000324a:	40000613          	li	a2,1024
    8000324e:	4581                	li	a1,0
    80003250:	05850513          	addi	a0,a0,88
    80003254:	ffffe097          	auipc	ra,0xffffe
    80003258:	a8c080e7          	jalr	-1396(ra) # 80000ce0 <memset>
  log_write(bp);
    8000325c:	854a                	mv	a0,s2
    8000325e:	00001097          	auipc	ra,0x1
    80003262:	fe6080e7          	jalr	-26(ra) # 80004244 <log_write>
  brelse(bp);
    80003266:	854a                	mv	a0,s2
    80003268:	00000097          	auipc	ra,0x0
    8000326c:	d60080e7          	jalr	-672(ra) # 80002fc8 <brelse>
}
    80003270:	8526                	mv	a0,s1
    80003272:	60e6                	ld	ra,88(sp)
    80003274:	6446                	ld	s0,80(sp)
    80003276:	64a6                	ld	s1,72(sp)
    80003278:	6906                	ld	s2,64(sp)
    8000327a:	79e2                	ld	s3,56(sp)
    8000327c:	7a42                	ld	s4,48(sp)
    8000327e:	7aa2                	ld	s5,40(sp)
    80003280:	7b02                	ld	s6,32(sp)
    80003282:	6be2                	ld	s7,24(sp)
    80003284:	6c42                	ld	s8,16(sp)
    80003286:	6ca2                	ld	s9,8(sp)
    80003288:	6125                	addi	sp,sp,96
    8000328a:	8082                	ret

000000008000328c <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    8000328c:	7179                	addi	sp,sp,-48
    8000328e:	f406                	sd	ra,40(sp)
    80003290:	f022                	sd	s0,32(sp)
    80003292:	ec26                	sd	s1,24(sp)
    80003294:	e84a                	sd	s2,16(sp)
    80003296:	e44e                	sd	s3,8(sp)
    80003298:	e052                	sd	s4,0(sp)
    8000329a:	1800                	addi	s0,sp,48
    8000329c:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    8000329e:	47ad                	li	a5,11
    800032a0:	04b7fe63          	bgeu	a5,a1,800032fc <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    800032a4:	ff45849b          	addiw	s1,a1,-12
    800032a8:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800032ac:	0ff00793          	li	a5,255
    800032b0:	0ae7e363          	bltu	a5,a4,80003356 <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    800032b4:	08052583          	lw	a1,128(a0)
    800032b8:	c5ad                	beqz	a1,80003322 <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    800032ba:	00092503          	lw	a0,0(s2)
    800032be:	00000097          	auipc	ra,0x0
    800032c2:	bda080e7          	jalr	-1062(ra) # 80002e98 <bread>
    800032c6:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    800032c8:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    800032cc:	02049593          	slli	a1,s1,0x20
    800032d0:	9181                	srli	a1,a1,0x20
    800032d2:	058a                	slli	a1,a1,0x2
    800032d4:	00b784b3          	add	s1,a5,a1
    800032d8:	0004a983          	lw	s3,0(s1)
    800032dc:	04098d63          	beqz	s3,80003336 <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    800032e0:	8552                	mv	a0,s4
    800032e2:	00000097          	auipc	ra,0x0
    800032e6:	ce6080e7          	jalr	-794(ra) # 80002fc8 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    800032ea:	854e                	mv	a0,s3
    800032ec:	70a2                	ld	ra,40(sp)
    800032ee:	7402                	ld	s0,32(sp)
    800032f0:	64e2                	ld	s1,24(sp)
    800032f2:	6942                	ld	s2,16(sp)
    800032f4:	69a2                	ld	s3,8(sp)
    800032f6:	6a02                	ld	s4,0(sp)
    800032f8:	6145                	addi	sp,sp,48
    800032fa:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    800032fc:	02059493          	slli	s1,a1,0x20
    80003300:	9081                	srli	s1,s1,0x20
    80003302:	048a                	slli	s1,s1,0x2
    80003304:	94aa                	add	s1,s1,a0
    80003306:	0504a983          	lw	s3,80(s1)
    8000330a:	fe0990e3          	bnez	s3,800032ea <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    8000330e:	4108                	lw	a0,0(a0)
    80003310:	00000097          	auipc	ra,0x0
    80003314:	e4a080e7          	jalr	-438(ra) # 8000315a <balloc>
    80003318:	0005099b          	sext.w	s3,a0
    8000331c:	0534a823          	sw	s3,80(s1)
    80003320:	b7e9                	j	800032ea <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80003322:	4108                	lw	a0,0(a0)
    80003324:	00000097          	auipc	ra,0x0
    80003328:	e36080e7          	jalr	-458(ra) # 8000315a <balloc>
    8000332c:	0005059b          	sext.w	a1,a0
    80003330:	08b92023          	sw	a1,128(s2)
    80003334:	b759                	j	800032ba <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    80003336:	00092503          	lw	a0,0(s2)
    8000333a:	00000097          	auipc	ra,0x0
    8000333e:	e20080e7          	jalr	-480(ra) # 8000315a <balloc>
    80003342:	0005099b          	sext.w	s3,a0
    80003346:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    8000334a:	8552                	mv	a0,s4
    8000334c:	00001097          	auipc	ra,0x1
    80003350:	ef8080e7          	jalr	-264(ra) # 80004244 <log_write>
    80003354:	b771                	j	800032e0 <bmap+0x54>
  panic("bmap: out of range");
    80003356:	00005517          	auipc	a0,0x5
    8000335a:	21250513          	addi	a0,a0,530 # 80008568 <syscalls+0x118>
    8000335e:	ffffd097          	auipc	ra,0xffffd
    80003362:	1e0080e7          	jalr	480(ra) # 8000053e <panic>

0000000080003366 <iget>:
{
    80003366:	7179                	addi	sp,sp,-48
    80003368:	f406                	sd	ra,40(sp)
    8000336a:	f022                	sd	s0,32(sp)
    8000336c:	ec26                	sd	s1,24(sp)
    8000336e:	e84a                	sd	s2,16(sp)
    80003370:	e44e                	sd	s3,8(sp)
    80003372:	e052                	sd	s4,0(sp)
    80003374:	1800                	addi	s0,sp,48
    80003376:	89aa                	mv	s3,a0
    80003378:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    8000337a:	0001c517          	auipc	a0,0x1c
    8000337e:	44e50513          	addi	a0,a0,1102 # 8001f7c8 <itable>
    80003382:	ffffe097          	auipc	ra,0xffffe
    80003386:	862080e7          	jalr	-1950(ra) # 80000be4 <acquire>
  empty = 0;
    8000338a:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    8000338c:	0001c497          	auipc	s1,0x1c
    80003390:	45448493          	addi	s1,s1,1108 # 8001f7e0 <itable+0x18>
    80003394:	0001e697          	auipc	a3,0x1e
    80003398:	edc68693          	addi	a3,a3,-292 # 80021270 <log>
    8000339c:	a039                	j	800033aa <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000339e:	02090b63          	beqz	s2,800033d4 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800033a2:	08848493          	addi	s1,s1,136
    800033a6:	02d48a63          	beq	s1,a3,800033da <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    800033aa:	449c                	lw	a5,8(s1)
    800033ac:	fef059e3          	blez	a5,8000339e <iget+0x38>
    800033b0:	4098                	lw	a4,0(s1)
    800033b2:	ff3716e3          	bne	a4,s3,8000339e <iget+0x38>
    800033b6:	40d8                	lw	a4,4(s1)
    800033b8:	ff4713e3          	bne	a4,s4,8000339e <iget+0x38>
      ip->ref++;
    800033bc:	2785                	addiw	a5,a5,1
    800033be:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    800033c0:	0001c517          	auipc	a0,0x1c
    800033c4:	40850513          	addi	a0,a0,1032 # 8001f7c8 <itable>
    800033c8:	ffffe097          	auipc	ra,0xffffe
    800033cc:	8d0080e7          	jalr	-1840(ra) # 80000c98 <release>
      return ip;
    800033d0:	8926                	mv	s2,s1
    800033d2:	a03d                	j	80003400 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800033d4:	f7f9                	bnez	a5,800033a2 <iget+0x3c>
    800033d6:	8926                	mv	s2,s1
    800033d8:	b7e9                	j	800033a2 <iget+0x3c>
  if(empty == 0)
    800033da:	02090c63          	beqz	s2,80003412 <iget+0xac>
  ip->dev = dev;
    800033de:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    800033e2:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    800033e6:	4785                	li	a5,1
    800033e8:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    800033ec:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    800033f0:	0001c517          	auipc	a0,0x1c
    800033f4:	3d850513          	addi	a0,a0,984 # 8001f7c8 <itable>
    800033f8:	ffffe097          	auipc	ra,0xffffe
    800033fc:	8a0080e7          	jalr	-1888(ra) # 80000c98 <release>
}
    80003400:	854a                	mv	a0,s2
    80003402:	70a2                	ld	ra,40(sp)
    80003404:	7402                	ld	s0,32(sp)
    80003406:	64e2                	ld	s1,24(sp)
    80003408:	6942                	ld	s2,16(sp)
    8000340a:	69a2                	ld	s3,8(sp)
    8000340c:	6a02                	ld	s4,0(sp)
    8000340e:	6145                	addi	sp,sp,48
    80003410:	8082                	ret
    panic("iget: no inodes");
    80003412:	00005517          	auipc	a0,0x5
    80003416:	16e50513          	addi	a0,a0,366 # 80008580 <syscalls+0x130>
    8000341a:	ffffd097          	auipc	ra,0xffffd
    8000341e:	124080e7          	jalr	292(ra) # 8000053e <panic>

0000000080003422 <fsinit>:
fsinit(int dev) {
    80003422:	7179                	addi	sp,sp,-48
    80003424:	f406                	sd	ra,40(sp)
    80003426:	f022                	sd	s0,32(sp)
    80003428:	ec26                	sd	s1,24(sp)
    8000342a:	e84a                	sd	s2,16(sp)
    8000342c:	e44e                	sd	s3,8(sp)
    8000342e:	1800                	addi	s0,sp,48
    80003430:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003432:	4585                	li	a1,1
    80003434:	00000097          	auipc	ra,0x0
    80003438:	a64080e7          	jalr	-1436(ra) # 80002e98 <bread>
    8000343c:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    8000343e:	0001c997          	auipc	s3,0x1c
    80003442:	36a98993          	addi	s3,s3,874 # 8001f7a8 <sb>
    80003446:	02000613          	li	a2,32
    8000344a:	05850593          	addi	a1,a0,88
    8000344e:	854e                	mv	a0,s3
    80003450:	ffffe097          	auipc	ra,0xffffe
    80003454:	8f0080e7          	jalr	-1808(ra) # 80000d40 <memmove>
  brelse(bp);
    80003458:	8526                	mv	a0,s1
    8000345a:	00000097          	auipc	ra,0x0
    8000345e:	b6e080e7          	jalr	-1170(ra) # 80002fc8 <brelse>
  if(sb.magic != FSMAGIC)
    80003462:	0009a703          	lw	a4,0(s3)
    80003466:	102037b7          	lui	a5,0x10203
    8000346a:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    8000346e:	02f71263          	bne	a4,a5,80003492 <fsinit+0x70>
  initlog(dev, &sb);
    80003472:	0001c597          	auipc	a1,0x1c
    80003476:	33658593          	addi	a1,a1,822 # 8001f7a8 <sb>
    8000347a:	854a                	mv	a0,s2
    8000347c:	00001097          	auipc	ra,0x1
    80003480:	b4c080e7          	jalr	-1204(ra) # 80003fc8 <initlog>
}
    80003484:	70a2                	ld	ra,40(sp)
    80003486:	7402                	ld	s0,32(sp)
    80003488:	64e2                	ld	s1,24(sp)
    8000348a:	6942                	ld	s2,16(sp)
    8000348c:	69a2                	ld	s3,8(sp)
    8000348e:	6145                	addi	sp,sp,48
    80003490:	8082                	ret
    panic("invalid file system");
    80003492:	00005517          	auipc	a0,0x5
    80003496:	0fe50513          	addi	a0,a0,254 # 80008590 <syscalls+0x140>
    8000349a:	ffffd097          	auipc	ra,0xffffd
    8000349e:	0a4080e7          	jalr	164(ra) # 8000053e <panic>

00000000800034a2 <iinit>:
{
    800034a2:	7179                	addi	sp,sp,-48
    800034a4:	f406                	sd	ra,40(sp)
    800034a6:	f022                	sd	s0,32(sp)
    800034a8:	ec26                	sd	s1,24(sp)
    800034aa:	e84a                	sd	s2,16(sp)
    800034ac:	e44e                	sd	s3,8(sp)
    800034ae:	1800                	addi	s0,sp,48
	initlock(&itable.lock, "itable");
    800034b0:	00005597          	auipc	a1,0x5
    800034b4:	0f858593          	addi	a1,a1,248 # 800085a8 <syscalls+0x158>
    800034b8:	0001c517          	auipc	a0,0x1c
    800034bc:	31050513          	addi	a0,a0,784 # 8001f7c8 <itable>
    800034c0:	ffffd097          	auipc	ra,0xffffd
    800034c4:	694080e7          	jalr	1684(ra) # 80000b54 <initlock>
	for(i = 0; i < NINODE; i++) {
    800034c8:	0001c497          	auipc	s1,0x1c
    800034cc:	32848493          	addi	s1,s1,808 # 8001f7f0 <itable+0x28>
    800034d0:	0001e997          	auipc	s3,0x1e
    800034d4:	db098993          	addi	s3,s3,-592 # 80021280 <log+0x10>
		initsleeplock(&itable.inode[i].lock, "inode");
    800034d8:	00005917          	auipc	s2,0x5
    800034dc:	0d890913          	addi	s2,s2,216 # 800085b0 <syscalls+0x160>
    800034e0:	85ca                	mv	a1,s2
    800034e2:	8526                	mv	a0,s1
    800034e4:	00001097          	auipc	ra,0x1
    800034e8:	e46080e7          	jalr	-442(ra) # 8000432a <initsleeplock>
	for(i = 0; i < NINODE; i++) {
    800034ec:	08848493          	addi	s1,s1,136
    800034f0:	ff3498e3          	bne	s1,s3,800034e0 <iinit+0x3e>
}
    800034f4:	70a2                	ld	ra,40(sp)
    800034f6:	7402                	ld	s0,32(sp)
    800034f8:	64e2                	ld	s1,24(sp)
    800034fa:	6942                	ld	s2,16(sp)
    800034fc:	69a2                	ld	s3,8(sp)
    800034fe:	6145                	addi	sp,sp,48
    80003500:	8082                	ret

0000000080003502 <ialloc>:
{
    80003502:	715d                	addi	sp,sp,-80
    80003504:	e486                	sd	ra,72(sp)
    80003506:	e0a2                	sd	s0,64(sp)
    80003508:	fc26                	sd	s1,56(sp)
    8000350a:	f84a                	sd	s2,48(sp)
    8000350c:	f44e                	sd	s3,40(sp)
    8000350e:	f052                	sd	s4,32(sp)
    80003510:	ec56                	sd	s5,24(sp)
    80003512:	e85a                	sd	s6,16(sp)
    80003514:	e45e                	sd	s7,8(sp)
    80003516:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003518:	0001c717          	auipc	a4,0x1c
    8000351c:	29c72703          	lw	a4,668(a4) # 8001f7b4 <sb+0xc>
    80003520:	4785                	li	a5,1
    80003522:	04e7fa63          	bgeu	a5,a4,80003576 <ialloc+0x74>
    80003526:	8aaa                	mv	s5,a0
    80003528:	8bae                	mv	s7,a1
    8000352a:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    8000352c:	0001ca17          	auipc	s4,0x1c
    80003530:	27ca0a13          	addi	s4,s4,636 # 8001f7a8 <sb>
    80003534:	00048b1b          	sext.w	s6,s1
    80003538:	0044d593          	srli	a1,s1,0x4
    8000353c:	018a2783          	lw	a5,24(s4)
    80003540:	9dbd                	addw	a1,a1,a5
    80003542:	8556                	mv	a0,s5
    80003544:	00000097          	auipc	ra,0x0
    80003548:	954080e7          	jalr	-1708(ra) # 80002e98 <bread>
    8000354c:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    8000354e:	05850993          	addi	s3,a0,88
    80003552:	00f4f793          	andi	a5,s1,15
    80003556:	079a                	slli	a5,a5,0x6
    80003558:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    8000355a:	00099783          	lh	a5,0(s3)
    8000355e:	c785                	beqz	a5,80003586 <ialloc+0x84>
    brelse(bp);
    80003560:	00000097          	auipc	ra,0x0
    80003564:	a68080e7          	jalr	-1432(ra) # 80002fc8 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003568:	0485                	addi	s1,s1,1
    8000356a:	00ca2703          	lw	a4,12(s4)
    8000356e:	0004879b          	sext.w	a5,s1
    80003572:	fce7e1e3          	bltu	a5,a4,80003534 <ialloc+0x32>
  panic("ialloc: no inodes");
    80003576:	00005517          	auipc	a0,0x5
    8000357a:	04250513          	addi	a0,a0,66 # 800085b8 <syscalls+0x168>
    8000357e:	ffffd097          	auipc	ra,0xffffd
    80003582:	fc0080e7          	jalr	-64(ra) # 8000053e <panic>
      memset(dip, 0, sizeof(*dip));
    80003586:	04000613          	li	a2,64
    8000358a:	4581                	li	a1,0
    8000358c:	854e                	mv	a0,s3
    8000358e:	ffffd097          	auipc	ra,0xffffd
    80003592:	752080e7          	jalr	1874(ra) # 80000ce0 <memset>
      dip->type = type;
    80003596:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    8000359a:	854a                	mv	a0,s2
    8000359c:	00001097          	auipc	ra,0x1
    800035a0:	ca8080e7          	jalr	-856(ra) # 80004244 <log_write>
      brelse(bp);
    800035a4:	854a                	mv	a0,s2
    800035a6:	00000097          	auipc	ra,0x0
    800035aa:	a22080e7          	jalr	-1502(ra) # 80002fc8 <brelse>
      return iget(dev, inum);
    800035ae:	85da                	mv	a1,s6
    800035b0:	8556                	mv	a0,s5
    800035b2:	00000097          	auipc	ra,0x0
    800035b6:	db4080e7          	jalr	-588(ra) # 80003366 <iget>
}
    800035ba:	60a6                	ld	ra,72(sp)
    800035bc:	6406                	ld	s0,64(sp)
    800035be:	74e2                	ld	s1,56(sp)
    800035c0:	7942                	ld	s2,48(sp)
    800035c2:	79a2                	ld	s3,40(sp)
    800035c4:	7a02                	ld	s4,32(sp)
    800035c6:	6ae2                	ld	s5,24(sp)
    800035c8:	6b42                	ld	s6,16(sp)
    800035ca:	6ba2                	ld	s7,8(sp)
    800035cc:	6161                	addi	sp,sp,80
    800035ce:	8082                	ret

00000000800035d0 <iupdate>:
{
    800035d0:	1101                	addi	sp,sp,-32
    800035d2:	ec06                	sd	ra,24(sp)
    800035d4:	e822                	sd	s0,16(sp)
    800035d6:	e426                	sd	s1,8(sp)
    800035d8:	e04a                	sd	s2,0(sp)
    800035da:	1000                	addi	s0,sp,32
    800035dc:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800035de:	415c                	lw	a5,4(a0)
    800035e0:	0047d79b          	srliw	a5,a5,0x4
    800035e4:	0001c597          	auipc	a1,0x1c
    800035e8:	1dc5a583          	lw	a1,476(a1) # 8001f7c0 <sb+0x18>
    800035ec:	9dbd                	addw	a1,a1,a5
    800035ee:	4108                	lw	a0,0(a0)
    800035f0:	00000097          	auipc	ra,0x0
    800035f4:	8a8080e7          	jalr	-1880(ra) # 80002e98 <bread>
    800035f8:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    800035fa:	05850793          	addi	a5,a0,88
    800035fe:	40c8                	lw	a0,4(s1)
    80003600:	893d                	andi	a0,a0,15
    80003602:	051a                	slli	a0,a0,0x6
    80003604:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003606:	04449703          	lh	a4,68(s1)
    8000360a:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    8000360e:	04649703          	lh	a4,70(s1)
    80003612:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003616:	04849703          	lh	a4,72(s1)
    8000361a:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    8000361e:	04a49703          	lh	a4,74(s1)
    80003622:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003626:	44f8                	lw	a4,76(s1)
    80003628:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    8000362a:	03400613          	li	a2,52
    8000362e:	05048593          	addi	a1,s1,80
    80003632:	0531                	addi	a0,a0,12
    80003634:	ffffd097          	auipc	ra,0xffffd
    80003638:	70c080e7          	jalr	1804(ra) # 80000d40 <memmove>
  log_write(bp);
    8000363c:	854a                	mv	a0,s2
    8000363e:	00001097          	auipc	ra,0x1
    80003642:	c06080e7          	jalr	-1018(ra) # 80004244 <log_write>
  brelse(bp);
    80003646:	854a                	mv	a0,s2
    80003648:	00000097          	auipc	ra,0x0
    8000364c:	980080e7          	jalr	-1664(ra) # 80002fc8 <brelse>
}
    80003650:	60e2                	ld	ra,24(sp)
    80003652:	6442                	ld	s0,16(sp)
    80003654:	64a2                	ld	s1,8(sp)
    80003656:	6902                	ld	s2,0(sp)
    80003658:	6105                	addi	sp,sp,32
    8000365a:	8082                	ret

000000008000365c <idup>:
{
    8000365c:	1101                	addi	sp,sp,-32
    8000365e:	ec06                	sd	ra,24(sp)
    80003660:	e822                	sd	s0,16(sp)
    80003662:	e426                	sd	s1,8(sp)
    80003664:	1000                	addi	s0,sp,32
    80003666:	84aa                	mv	s1,a0
	acquire(&itable.lock);
    80003668:	0001c517          	auipc	a0,0x1c
    8000366c:	16050513          	addi	a0,a0,352 # 8001f7c8 <itable>
    80003670:	ffffd097          	auipc	ra,0xffffd
    80003674:	574080e7          	jalr	1396(ra) # 80000be4 <acquire>
	ip->ref++;
    80003678:	449c                	lw	a5,8(s1)
    8000367a:	2785                	addiw	a5,a5,1
    8000367c:	c49c                	sw	a5,8(s1)
	release(&itable.lock);
    8000367e:	0001c517          	auipc	a0,0x1c
    80003682:	14a50513          	addi	a0,a0,330 # 8001f7c8 <itable>
    80003686:	ffffd097          	auipc	ra,0xffffd
    8000368a:	612080e7          	jalr	1554(ra) # 80000c98 <release>
}
    8000368e:	8526                	mv	a0,s1
    80003690:	60e2                	ld	ra,24(sp)
    80003692:	6442                	ld	s0,16(sp)
    80003694:	64a2                	ld	s1,8(sp)
    80003696:	6105                	addi	sp,sp,32
    80003698:	8082                	ret

000000008000369a <ilock>:
{
    8000369a:	1101                	addi	sp,sp,-32
    8000369c:	ec06                	sd	ra,24(sp)
    8000369e:	e822                	sd	s0,16(sp)
    800036a0:	e426                	sd	s1,8(sp)
    800036a2:	e04a                	sd	s2,0(sp)
    800036a4:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    800036a6:	c115                	beqz	a0,800036ca <ilock+0x30>
    800036a8:	84aa                	mv	s1,a0
    800036aa:	451c                	lw	a5,8(a0)
    800036ac:	00f05f63          	blez	a5,800036ca <ilock+0x30>
  acquiresleep(&ip->lock);
    800036b0:	0541                	addi	a0,a0,16
    800036b2:	00001097          	auipc	ra,0x1
    800036b6:	cb2080e7          	jalr	-846(ra) # 80004364 <acquiresleep>
  if(ip->valid == 0){
    800036ba:	40bc                	lw	a5,64(s1)
    800036bc:	cf99                	beqz	a5,800036da <ilock+0x40>
}
    800036be:	60e2                	ld	ra,24(sp)
    800036c0:	6442                	ld	s0,16(sp)
    800036c2:	64a2                	ld	s1,8(sp)
    800036c4:	6902                	ld	s2,0(sp)
    800036c6:	6105                	addi	sp,sp,32
    800036c8:	8082                	ret
    panic("ilock");
    800036ca:	00005517          	auipc	a0,0x5
    800036ce:	f0650513          	addi	a0,a0,-250 # 800085d0 <syscalls+0x180>
    800036d2:	ffffd097          	auipc	ra,0xffffd
    800036d6:	e6c080e7          	jalr	-404(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800036da:	40dc                	lw	a5,4(s1)
    800036dc:	0047d79b          	srliw	a5,a5,0x4
    800036e0:	0001c597          	auipc	a1,0x1c
    800036e4:	0e05a583          	lw	a1,224(a1) # 8001f7c0 <sb+0x18>
    800036e8:	9dbd                	addw	a1,a1,a5
    800036ea:	4088                	lw	a0,0(s1)
    800036ec:	fffff097          	auipc	ra,0xfffff
    800036f0:	7ac080e7          	jalr	1964(ra) # 80002e98 <bread>
    800036f4:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    800036f6:	05850593          	addi	a1,a0,88
    800036fa:	40dc                	lw	a5,4(s1)
    800036fc:	8bbd                	andi	a5,a5,15
    800036fe:	079a                	slli	a5,a5,0x6
    80003700:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003702:	00059783          	lh	a5,0(a1)
    80003706:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    8000370a:	00259783          	lh	a5,2(a1)
    8000370e:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003712:	00459783          	lh	a5,4(a1)
    80003716:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    8000371a:	00659783          	lh	a5,6(a1)
    8000371e:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003722:	459c                	lw	a5,8(a1)
    80003724:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003726:	03400613          	li	a2,52
    8000372a:	05b1                	addi	a1,a1,12
    8000372c:	05048513          	addi	a0,s1,80
    80003730:	ffffd097          	auipc	ra,0xffffd
    80003734:	610080e7          	jalr	1552(ra) # 80000d40 <memmove>
    brelse(bp);
    80003738:	854a                	mv	a0,s2
    8000373a:	00000097          	auipc	ra,0x0
    8000373e:	88e080e7          	jalr	-1906(ra) # 80002fc8 <brelse>
    ip->valid = 1;
    80003742:	4785                	li	a5,1
    80003744:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003746:	04449783          	lh	a5,68(s1)
    8000374a:	fbb5                	bnez	a5,800036be <ilock+0x24>
      panic("ilock: no type");
    8000374c:	00005517          	auipc	a0,0x5
    80003750:	e8c50513          	addi	a0,a0,-372 # 800085d8 <syscalls+0x188>
    80003754:	ffffd097          	auipc	ra,0xffffd
    80003758:	dea080e7          	jalr	-534(ra) # 8000053e <panic>

000000008000375c <iunlock>:
{
    8000375c:	1101                	addi	sp,sp,-32
    8000375e:	ec06                	sd	ra,24(sp)
    80003760:	e822                	sd	s0,16(sp)
    80003762:	e426                	sd	s1,8(sp)
    80003764:	e04a                	sd	s2,0(sp)
    80003766:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003768:	c905                	beqz	a0,80003798 <iunlock+0x3c>
    8000376a:	84aa                	mv	s1,a0
    8000376c:	01050913          	addi	s2,a0,16
    80003770:	854a                	mv	a0,s2
    80003772:	00001097          	auipc	ra,0x1
    80003776:	c8c080e7          	jalr	-884(ra) # 800043fe <holdingsleep>
    8000377a:	cd19                	beqz	a0,80003798 <iunlock+0x3c>
    8000377c:	449c                	lw	a5,8(s1)
    8000377e:	00f05d63          	blez	a5,80003798 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003782:	854a                	mv	a0,s2
    80003784:	00001097          	auipc	ra,0x1
    80003788:	c36080e7          	jalr	-970(ra) # 800043ba <releasesleep>
}
    8000378c:	60e2                	ld	ra,24(sp)
    8000378e:	6442                	ld	s0,16(sp)
    80003790:	64a2                	ld	s1,8(sp)
    80003792:	6902                	ld	s2,0(sp)
    80003794:	6105                	addi	sp,sp,32
    80003796:	8082                	ret
    panic("iunlock");
    80003798:	00005517          	auipc	a0,0x5
    8000379c:	e5050513          	addi	a0,a0,-432 # 800085e8 <syscalls+0x198>
    800037a0:	ffffd097          	auipc	ra,0xffffd
    800037a4:	d9e080e7          	jalr	-610(ra) # 8000053e <panic>

00000000800037a8 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    800037a8:	7179                	addi	sp,sp,-48
    800037aa:	f406                	sd	ra,40(sp)
    800037ac:	f022                	sd	s0,32(sp)
    800037ae:	ec26                	sd	s1,24(sp)
    800037b0:	e84a                	sd	s2,16(sp)
    800037b2:	e44e                	sd	s3,8(sp)
    800037b4:	e052                	sd	s4,0(sp)
    800037b6:	1800                	addi	s0,sp,48
    800037b8:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    800037ba:	05050493          	addi	s1,a0,80
    800037be:	08050913          	addi	s2,a0,128
    800037c2:	a021                	j	800037ca <itrunc+0x22>
    800037c4:	0491                	addi	s1,s1,4
    800037c6:	01248d63          	beq	s1,s2,800037e0 <itrunc+0x38>
    if(ip->addrs[i]){
    800037ca:	408c                	lw	a1,0(s1)
    800037cc:	dde5                	beqz	a1,800037c4 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    800037ce:	0009a503          	lw	a0,0(s3)
    800037d2:	00000097          	auipc	ra,0x0
    800037d6:	90c080e7          	jalr	-1780(ra) # 800030de <bfree>
      ip->addrs[i] = 0;
    800037da:	0004a023          	sw	zero,0(s1)
    800037de:	b7dd                	j	800037c4 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    800037e0:	0809a583          	lw	a1,128(s3)
    800037e4:	e185                	bnez	a1,80003804 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    800037e6:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    800037ea:	854e                	mv	a0,s3
    800037ec:	00000097          	auipc	ra,0x0
    800037f0:	de4080e7          	jalr	-540(ra) # 800035d0 <iupdate>
}
    800037f4:	70a2                	ld	ra,40(sp)
    800037f6:	7402                	ld	s0,32(sp)
    800037f8:	64e2                	ld	s1,24(sp)
    800037fa:	6942                	ld	s2,16(sp)
    800037fc:	69a2                	ld	s3,8(sp)
    800037fe:	6a02                	ld	s4,0(sp)
    80003800:	6145                	addi	sp,sp,48
    80003802:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003804:	0009a503          	lw	a0,0(s3)
    80003808:	fffff097          	auipc	ra,0xfffff
    8000380c:	690080e7          	jalr	1680(ra) # 80002e98 <bread>
    80003810:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003812:	05850493          	addi	s1,a0,88
    80003816:	45850913          	addi	s2,a0,1112
    8000381a:	a811                	j	8000382e <itrunc+0x86>
        bfree(ip->dev, a[j]);
    8000381c:	0009a503          	lw	a0,0(s3)
    80003820:	00000097          	auipc	ra,0x0
    80003824:	8be080e7          	jalr	-1858(ra) # 800030de <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80003828:	0491                	addi	s1,s1,4
    8000382a:	01248563          	beq	s1,s2,80003834 <itrunc+0x8c>
      if(a[j])
    8000382e:	408c                	lw	a1,0(s1)
    80003830:	dde5                	beqz	a1,80003828 <itrunc+0x80>
    80003832:	b7ed                	j	8000381c <itrunc+0x74>
    brelse(bp);
    80003834:	8552                	mv	a0,s4
    80003836:	fffff097          	auipc	ra,0xfffff
    8000383a:	792080e7          	jalr	1938(ra) # 80002fc8 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    8000383e:	0809a583          	lw	a1,128(s3)
    80003842:	0009a503          	lw	a0,0(s3)
    80003846:	00000097          	auipc	ra,0x0
    8000384a:	898080e7          	jalr	-1896(ra) # 800030de <bfree>
    ip->addrs[NDIRECT] = 0;
    8000384e:	0809a023          	sw	zero,128(s3)
    80003852:	bf51                	j	800037e6 <itrunc+0x3e>

0000000080003854 <iput>:
{
    80003854:	1101                	addi	sp,sp,-32
    80003856:	ec06                	sd	ra,24(sp)
    80003858:	e822                	sd	s0,16(sp)
    8000385a:	e426                	sd	s1,8(sp)
    8000385c:	e04a                	sd	s2,0(sp)
    8000385e:	1000                	addi	s0,sp,32
    80003860:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003862:	0001c517          	auipc	a0,0x1c
    80003866:	f6650513          	addi	a0,a0,-154 # 8001f7c8 <itable>
    8000386a:	ffffd097          	auipc	ra,0xffffd
    8000386e:	37a080e7          	jalr	890(ra) # 80000be4 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003872:	4498                	lw	a4,8(s1)
    80003874:	4785                	li	a5,1
    80003876:	02f70363          	beq	a4,a5,8000389c <iput+0x48>
  ip->ref--;
    8000387a:	449c                	lw	a5,8(s1)
    8000387c:	37fd                	addiw	a5,a5,-1
    8000387e:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003880:	0001c517          	auipc	a0,0x1c
    80003884:	f4850513          	addi	a0,a0,-184 # 8001f7c8 <itable>
    80003888:	ffffd097          	auipc	ra,0xffffd
    8000388c:	410080e7          	jalr	1040(ra) # 80000c98 <release>
}
    80003890:	60e2                	ld	ra,24(sp)
    80003892:	6442                	ld	s0,16(sp)
    80003894:	64a2                	ld	s1,8(sp)
    80003896:	6902                	ld	s2,0(sp)
    80003898:	6105                	addi	sp,sp,32
    8000389a:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    8000389c:	40bc                	lw	a5,64(s1)
    8000389e:	dff1                	beqz	a5,8000387a <iput+0x26>
    800038a0:	04a49783          	lh	a5,74(s1)
    800038a4:	fbf9                	bnez	a5,8000387a <iput+0x26>
    acquiresleep(&ip->lock);
    800038a6:	01048913          	addi	s2,s1,16
    800038aa:	854a                	mv	a0,s2
    800038ac:	00001097          	auipc	ra,0x1
    800038b0:	ab8080e7          	jalr	-1352(ra) # 80004364 <acquiresleep>
    release(&itable.lock);
    800038b4:	0001c517          	auipc	a0,0x1c
    800038b8:	f1450513          	addi	a0,a0,-236 # 8001f7c8 <itable>
    800038bc:	ffffd097          	auipc	ra,0xffffd
    800038c0:	3dc080e7          	jalr	988(ra) # 80000c98 <release>
    itrunc(ip);
    800038c4:	8526                	mv	a0,s1
    800038c6:	00000097          	auipc	ra,0x0
    800038ca:	ee2080e7          	jalr	-286(ra) # 800037a8 <itrunc>
    ip->type = 0;
    800038ce:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    800038d2:	8526                	mv	a0,s1
    800038d4:	00000097          	auipc	ra,0x0
    800038d8:	cfc080e7          	jalr	-772(ra) # 800035d0 <iupdate>
    ip->valid = 0;
    800038dc:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    800038e0:	854a                	mv	a0,s2
    800038e2:	00001097          	auipc	ra,0x1
    800038e6:	ad8080e7          	jalr	-1320(ra) # 800043ba <releasesleep>
    acquire(&itable.lock);
    800038ea:	0001c517          	auipc	a0,0x1c
    800038ee:	ede50513          	addi	a0,a0,-290 # 8001f7c8 <itable>
    800038f2:	ffffd097          	auipc	ra,0xffffd
    800038f6:	2f2080e7          	jalr	754(ra) # 80000be4 <acquire>
    800038fa:	b741                	j	8000387a <iput+0x26>

00000000800038fc <iunlockput>:
{
    800038fc:	1101                	addi	sp,sp,-32
    800038fe:	ec06                	sd	ra,24(sp)
    80003900:	e822                	sd	s0,16(sp)
    80003902:	e426                	sd	s1,8(sp)
    80003904:	1000                	addi	s0,sp,32
    80003906:	84aa                	mv	s1,a0
	iunlock(ip);
    80003908:	00000097          	auipc	ra,0x0
    8000390c:	e54080e7          	jalr	-428(ra) # 8000375c <iunlock>
	iput(ip);
    80003910:	8526                	mv	a0,s1
    80003912:	00000097          	auipc	ra,0x0
    80003916:	f42080e7          	jalr	-190(ra) # 80003854 <iput>
}
    8000391a:	60e2                	ld	ra,24(sp)
    8000391c:	6442                	ld	s0,16(sp)
    8000391e:	64a2                	ld	s1,8(sp)
    80003920:	6105                	addi	sp,sp,32
    80003922:	8082                	ret

0000000080003924 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003924:	1141                	addi	sp,sp,-16
    80003926:	e422                	sd	s0,8(sp)
    80003928:	0800                	addi	s0,sp,16
	st->dev = ip->dev;
    8000392a:	411c                	lw	a5,0(a0)
    8000392c:	c19c                	sw	a5,0(a1)
	st->ino = ip->inum;
    8000392e:	415c                	lw	a5,4(a0)
    80003930:	c1dc                	sw	a5,4(a1)
	st->type = ip->type;
    80003932:	04451783          	lh	a5,68(a0)
    80003936:	00f59423          	sh	a5,8(a1)
	st->nlink = ip->nlink;
    8000393a:	04a51783          	lh	a5,74(a0)
    8000393e:	00f59523          	sh	a5,10(a1)
	st->size = ip->size;
    80003942:	04c56783          	lwu	a5,76(a0)
    80003946:	e99c                	sd	a5,16(a1)
}
    80003948:	6422                	ld	s0,8(sp)
    8000394a:	0141                	addi	sp,sp,16
    8000394c:	8082                	ret

000000008000394e <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    8000394e:	457c                	lw	a5,76(a0)
    80003950:	0ed7e963          	bltu	a5,a3,80003a42 <readi+0xf4>
{
    80003954:	7159                	addi	sp,sp,-112
    80003956:	f486                	sd	ra,104(sp)
    80003958:	f0a2                	sd	s0,96(sp)
    8000395a:	eca6                	sd	s1,88(sp)
    8000395c:	e8ca                	sd	s2,80(sp)
    8000395e:	e4ce                	sd	s3,72(sp)
    80003960:	e0d2                	sd	s4,64(sp)
    80003962:	fc56                	sd	s5,56(sp)
    80003964:	f85a                	sd	s6,48(sp)
    80003966:	f45e                	sd	s7,40(sp)
    80003968:	f062                	sd	s8,32(sp)
    8000396a:	ec66                	sd	s9,24(sp)
    8000396c:	e86a                	sd	s10,16(sp)
    8000396e:	e46e                	sd	s11,8(sp)
    80003970:	1880                	addi	s0,sp,112
    80003972:	8baa                	mv	s7,a0
    80003974:	8c2e                	mv	s8,a1
    80003976:	8ab2                	mv	s5,a2
    80003978:	84b6                	mv	s1,a3
    8000397a:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    8000397c:	9f35                	addw	a4,a4,a3
    return 0;
    8000397e:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003980:	0ad76063          	bltu	a4,a3,80003a20 <readi+0xd2>
  if(off + n > ip->size)
    80003984:	00e7f463          	bgeu	a5,a4,8000398c <readi+0x3e>
    n = ip->size - off;
    80003988:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    8000398c:	0a0b0963          	beqz	s6,80003a3e <readi+0xf0>
    80003990:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003992:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003996:	5cfd                	li	s9,-1
    80003998:	a82d                	j	800039d2 <readi+0x84>
    8000399a:	020a1d93          	slli	s11,s4,0x20
    8000399e:	020ddd93          	srli	s11,s11,0x20
    800039a2:	05890613          	addi	a2,s2,88
    800039a6:	86ee                	mv	a3,s11
    800039a8:	963a                	add	a2,a2,a4
    800039aa:	85d6                	mv	a1,s5
    800039ac:	8562                	mv	a0,s8
    800039ae:	fffff097          	auipc	ra,0xfffff
    800039b2:	ade080e7          	jalr	-1314(ra) # 8000248c <either_copyout>
    800039b6:	05950d63          	beq	a0,s9,80003a10 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    800039ba:	854a                	mv	a0,s2
    800039bc:	fffff097          	auipc	ra,0xfffff
    800039c0:	60c080e7          	jalr	1548(ra) # 80002fc8 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800039c4:	013a09bb          	addw	s3,s4,s3
    800039c8:	009a04bb          	addw	s1,s4,s1
    800039cc:	9aee                	add	s5,s5,s11
    800039ce:	0569f763          	bgeu	s3,s6,80003a1c <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    800039d2:	000ba903          	lw	s2,0(s7)
    800039d6:	00a4d59b          	srliw	a1,s1,0xa
    800039da:	855e                	mv	a0,s7
    800039dc:	00000097          	auipc	ra,0x0
    800039e0:	8b0080e7          	jalr	-1872(ra) # 8000328c <bmap>
    800039e4:	0005059b          	sext.w	a1,a0
    800039e8:	854a                	mv	a0,s2
    800039ea:	fffff097          	auipc	ra,0xfffff
    800039ee:	4ae080e7          	jalr	1198(ra) # 80002e98 <bread>
    800039f2:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    800039f4:	3ff4f713          	andi	a4,s1,1023
    800039f8:	40ed07bb          	subw	a5,s10,a4
    800039fc:	413b06bb          	subw	a3,s6,s3
    80003a00:	8a3e                	mv	s4,a5
    80003a02:	2781                	sext.w	a5,a5
    80003a04:	0006861b          	sext.w	a2,a3
    80003a08:	f8f679e3          	bgeu	a2,a5,8000399a <readi+0x4c>
    80003a0c:	8a36                	mv	s4,a3
    80003a0e:	b771                	j	8000399a <readi+0x4c>
      brelse(bp);
    80003a10:	854a                	mv	a0,s2
    80003a12:	fffff097          	auipc	ra,0xfffff
    80003a16:	5b6080e7          	jalr	1462(ra) # 80002fc8 <brelse>
      tot = -1;
    80003a1a:	59fd                	li	s3,-1
  }
  return tot;
    80003a1c:	0009851b          	sext.w	a0,s3
}
    80003a20:	70a6                	ld	ra,104(sp)
    80003a22:	7406                	ld	s0,96(sp)
    80003a24:	64e6                	ld	s1,88(sp)
    80003a26:	6946                	ld	s2,80(sp)
    80003a28:	69a6                	ld	s3,72(sp)
    80003a2a:	6a06                	ld	s4,64(sp)
    80003a2c:	7ae2                	ld	s5,56(sp)
    80003a2e:	7b42                	ld	s6,48(sp)
    80003a30:	7ba2                	ld	s7,40(sp)
    80003a32:	7c02                	ld	s8,32(sp)
    80003a34:	6ce2                	ld	s9,24(sp)
    80003a36:	6d42                	ld	s10,16(sp)
    80003a38:	6da2                	ld	s11,8(sp)
    80003a3a:	6165                	addi	sp,sp,112
    80003a3c:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003a3e:	89da                	mv	s3,s6
    80003a40:	bff1                	j	80003a1c <readi+0xce>
    return 0;
    80003a42:	4501                	li	a0,0
}
    80003a44:	8082                	ret

0000000080003a46 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003a46:	457c                	lw	a5,76(a0)
    80003a48:	10d7e863          	bltu	a5,a3,80003b58 <writei+0x112>
{
    80003a4c:	7159                	addi	sp,sp,-112
    80003a4e:	f486                	sd	ra,104(sp)
    80003a50:	f0a2                	sd	s0,96(sp)
    80003a52:	eca6                	sd	s1,88(sp)
    80003a54:	e8ca                	sd	s2,80(sp)
    80003a56:	e4ce                	sd	s3,72(sp)
    80003a58:	e0d2                	sd	s4,64(sp)
    80003a5a:	fc56                	sd	s5,56(sp)
    80003a5c:	f85a                	sd	s6,48(sp)
    80003a5e:	f45e                	sd	s7,40(sp)
    80003a60:	f062                	sd	s8,32(sp)
    80003a62:	ec66                	sd	s9,24(sp)
    80003a64:	e86a                	sd	s10,16(sp)
    80003a66:	e46e                	sd	s11,8(sp)
    80003a68:	1880                	addi	s0,sp,112
    80003a6a:	8b2a                	mv	s6,a0
    80003a6c:	8c2e                	mv	s8,a1
    80003a6e:	8ab2                	mv	s5,a2
    80003a70:	8936                	mv	s2,a3
    80003a72:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    80003a74:	00e687bb          	addw	a5,a3,a4
    80003a78:	0ed7e263          	bltu	a5,a3,80003b5c <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003a7c:	00043737          	lui	a4,0x43
    80003a80:	0ef76063          	bltu	a4,a5,80003b60 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003a84:	0c0b8863          	beqz	s7,80003b54 <writei+0x10e>
    80003a88:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003a8a:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003a8e:	5cfd                	li	s9,-1
    80003a90:	a091                	j	80003ad4 <writei+0x8e>
    80003a92:	02099d93          	slli	s11,s3,0x20
    80003a96:	020ddd93          	srli	s11,s11,0x20
    80003a9a:	05848513          	addi	a0,s1,88
    80003a9e:	86ee                	mv	a3,s11
    80003aa0:	8656                	mv	a2,s5
    80003aa2:	85e2                	mv	a1,s8
    80003aa4:	953a                	add	a0,a0,a4
    80003aa6:	fffff097          	auipc	ra,0xfffff
    80003aaa:	a3c080e7          	jalr	-1476(ra) # 800024e2 <either_copyin>
    80003aae:	07950263          	beq	a0,s9,80003b12 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003ab2:	8526                	mv	a0,s1
    80003ab4:	00000097          	auipc	ra,0x0
    80003ab8:	790080e7          	jalr	1936(ra) # 80004244 <log_write>
    brelse(bp);
    80003abc:	8526                	mv	a0,s1
    80003abe:	fffff097          	auipc	ra,0xfffff
    80003ac2:	50a080e7          	jalr	1290(ra) # 80002fc8 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003ac6:	01498a3b          	addw	s4,s3,s4
    80003aca:	0129893b          	addw	s2,s3,s2
    80003ace:	9aee                	add	s5,s5,s11
    80003ad0:	057a7663          	bgeu	s4,s7,80003b1c <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003ad4:	000b2483          	lw	s1,0(s6)
    80003ad8:	00a9559b          	srliw	a1,s2,0xa
    80003adc:	855a                	mv	a0,s6
    80003ade:	fffff097          	auipc	ra,0xfffff
    80003ae2:	7ae080e7          	jalr	1966(ra) # 8000328c <bmap>
    80003ae6:	0005059b          	sext.w	a1,a0
    80003aea:	8526                	mv	a0,s1
    80003aec:	fffff097          	auipc	ra,0xfffff
    80003af0:	3ac080e7          	jalr	940(ra) # 80002e98 <bread>
    80003af4:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003af6:	3ff97713          	andi	a4,s2,1023
    80003afa:	40ed07bb          	subw	a5,s10,a4
    80003afe:	414b86bb          	subw	a3,s7,s4
    80003b02:	89be                	mv	s3,a5
    80003b04:	2781                	sext.w	a5,a5
    80003b06:	0006861b          	sext.w	a2,a3
    80003b0a:	f8f674e3          	bgeu	a2,a5,80003a92 <writei+0x4c>
    80003b0e:	89b6                	mv	s3,a3
    80003b10:	b749                	j	80003a92 <writei+0x4c>
      brelse(bp);
    80003b12:	8526                	mv	a0,s1
    80003b14:	fffff097          	auipc	ra,0xfffff
    80003b18:	4b4080e7          	jalr	1204(ra) # 80002fc8 <brelse>
  }

  if(off > ip->size)
    80003b1c:	04cb2783          	lw	a5,76(s6)
    80003b20:	0127f463          	bgeu	a5,s2,80003b28 <writei+0xe2>
    ip->size = off;
    80003b24:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003b28:	855a                	mv	a0,s6
    80003b2a:	00000097          	auipc	ra,0x0
    80003b2e:	aa6080e7          	jalr	-1370(ra) # 800035d0 <iupdate>

  return tot;
    80003b32:	000a051b          	sext.w	a0,s4
}
    80003b36:	70a6                	ld	ra,104(sp)
    80003b38:	7406                	ld	s0,96(sp)
    80003b3a:	64e6                	ld	s1,88(sp)
    80003b3c:	6946                	ld	s2,80(sp)
    80003b3e:	69a6                	ld	s3,72(sp)
    80003b40:	6a06                	ld	s4,64(sp)
    80003b42:	7ae2                	ld	s5,56(sp)
    80003b44:	7b42                	ld	s6,48(sp)
    80003b46:	7ba2                	ld	s7,40(sp)
    80003b48:	7c02                	ld	s8,32(sp)
    80003b4a:	6ce2                	ld	s9,24(sp)
    80003b4c:	6d42                	ld	s10,16(sp)
    80003b4e:	6da2                	ld	s11,8(sp)
    80003b50:	6165                	addi	sp,sp,112
    80003b52:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003b54:	8a5e                	mv	s4,s7
    80003b56:	bfc9                	j	80003b28 <writei+0xe2>
    return -1;
    80003b58:	557d                	li	a0,-1
}
    80003b5a:	8082                	ret
    return -1;
    80003b5c:	557d                	li	a0,-1
    80003b5e:	bfe1                	j	80003b36 <writei+0xf0>
    return -1;
    80003b60:	557d                	li	a0,-1
    80003b62:	bfd1                	j	80003b36 <writei+0xf0>

0000000080003b64 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003b64:	1141                	addi	sp,sp,-16
    80003b66:	e406                	sd	ra,8(sp)
    80003b68:	e022                	sd	s0,0(sp)
    80003b6a:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003b6c:	4639                	li	a2,14
    80003b6e:	ffffd097          	auipc	ra,0xffffd
    80003b72:	24a080e7          	jalr	586(ra) # 80000db8 <strncmp>
}
    80003b76:	60a2                	ld	ra,8(sp)
    80003b78:	6402                	ld	s0,0(sp)
    80003b7a:	0141                	addi	sp,sp,16
    80003b7c:	8082                	ret

0000000080003b7e <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003b7e:	7139                	addi	sp,sp,-64
    80003b80:	fc06                	sd	ra,56(sp)
    80003b82:	f822                	sd	s0,48(sp)
    80003b84:	f426                	sd	s1,40(sp)
    80003b86:	f04a                	sd	s2,32(sp)
    80003b88:	ec4e                	sd	s3,24(sp)
    80003b8a:	e852                	sd	s4,16(sp)
    80003b8c:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003b8e:	04451703          	lh	a4,68(a0)
    80003b92:	4785                	li	a5,1
    80003b94:	00f71a63          	bne	a4,a5,80003ba8 <dirlookup+0x2a>
    80003b98:	892a                	mv	s2,a0
    80003b9a:	89ae                	mv	s3,a1
    80003b9c:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003b9e:	457c                	lw	a5,76(a0)
    80003ba0:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003ba2:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003ba4:	e79d                	bnez	a5,80003bd2 <dirlookup+0x54>
    80003ba6:	a8a5                	j	80003c1e <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003ba8:	00005517          	auipc	a0,0x5
    80003bac:	a4850513          	addi	a0,a0,-1464 # 800085f0 <syscalls+0x1a0>
    80003bb0:	ffffd097          	auipc	ra,0xffffd
    80003bb4:	98e080e7          	jalr	-1650(ra) # 8000053e <panic>
      panic("dirlookup read");
    80003bb8:	00005517          	auipc	a0,0x5
    80003bbc:	a5050513          	addi	a0,a0,-1456 # 80008608 <syscalls+0x1b8>
    80003bc0:	ffffd097          	auipc	ra,0xffffd
    80003bc4:	97e080e7          	jalr	-1666(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003bc8:	24c1                	addiw	s1,s1,16
    80003bca:	04c92783          	lw	a5,76(s2)
    80003bce:	04f4f763          	bgeu	s1,a5,80003c1c <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003bd2:	4741                	li	a4,16
    80003bd4:	86a6                	mv	a3,s1
    80003bd6:	fc040613          	addi	a2,s0,-64
    80003bda:	4581                	li	a1,0
    80003bdc:	854a                	mv	a0,s2
    80003bde:	00000097          	auipc	ra,0x0
    80003be2:	d70080e7          	jalr	-656(ra) # 8000394e <readi>
    80003be6:	47c1                	li	a5,16
    80003be8:	fcf518e3          	bne	a0,a5,80003bb8 <dirlookup+0x3a>
    if(de.inum == 0)
    80003bec:	fc045783          	lhu	a5,-64(s0)
    80003bf0:	dfe1                	beqz	a5,80003bc8 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003bf2:	fc240593          	addi	a1,s0,-62
    80003bf6:	854e                	mv	a0,s3
    80003bf8:	00000097          	auipc	ra,0x0
    80003bfc:	f6c080e7          	jalr	-148(ra) # 80003b64 <namecmp>
    80003c00:	f561                	bnez	a0,80003bc8 <dirlookup+0x4a>
      if(poff)
    80003c02:	000a0463          	beqz	s4,80003c0a <dirlookup+0x8c>
        *poff = off;
    80003c06:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003c0a:	fc045583          	lhu	a1,-64(s0)
    80003c0e:	00092503          	lw	a0,0(s2)
    80003c12:	fffff097          	auipc	ra,0xfffff
    80003c16:	754080e7          	jalr	1876(ra) # 80003366 <iget>
    80003c1a:	a011                	j	80003c1e <dirlookup+0xa0>
  return 0;
    80003c1c:	4501                	li	a0,0
}
    80003c1e:	70e2                	ld	ra,56(sp)
    80003c20:	7442                	ld	s0,48(sp)
    80003c22:	74a2                	ld	s1,40(sp)
    80003c24:	7902                	ld	s2,32(sp)
    80003c26:	69e2                	ld	s3,24(sp)
    80003c28:	6a42                	ld	s4,16(sp)
    80003c2a:	6121                	addi	sp,sp,64
    80003c2c:	8082                	ret

0000000080003c2e <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003c2e:	711d                	addi	sp,sp,-96
    80003c30:	ec86                	sd	ra,88(sp)
    80003c32:	e8a2                	sd	s0,80(sp)
    80003c34:	e4a6                	sd	s1,72(sp)
    80003c36:	e0ca                	sd	s2,64(sp)
    80003c38:	fc4e                	sd	s3,56(sp)
    80003c3a:	f852                	sd	s4,48(sp)
    80003c3c:	f456                	sd	s5,40(sp)
    80003c3e:	f05a                	sd	s6,32(sp)
    80003c40:	ec5e                	sd	s7,24(sp)
    80003c42:	e862                	sd	s8,16(sp)
    80003c44:	e466                	sd	s9,8(sp)
    80003c46:	1080                	addi	s0,sp,96
    80003c48:	84aa                	mv	s1,a0
    80003c4a:	8b2e                	mv	s6,a1
    80003c4c:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003c4e:	00054703          	lbu	a4,0(a0)
    80003c52:	02f00793          	li	a5,47
    80003c56:	02f70363          	beq	a4,a5,80003c7c <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003c5a:	ffffe097          	auipc	ra,0xffffe
    80003c5e:	dd2080e7          	jalr	-558(ra) # 80001a2c <myproc>
    80003c62:	15053503          	ld	a0,336(a0)
    80003c66:	00000097          	auipc	ra,0x0
    80003c6a:	9f6080e7          	jalr	-1546(ra) # 8000365c <idup>
    80003c6e:	89aa                	mv	s3,a0
  while(*path == '/')
    80003c70:	02f00913          	li	s2,47
  len = path - s;
    80003c74:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80003c76:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003c78:	4c05                	li	s8,1
    80003c7a:	a865                	j	80003d32 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003c7c:	4585                	li	a1,1
    80003c7e:	4505                	li	a0,1
    80003c80:	fffff097          	auipc	ra,0xfffff
    80003c84:	6e6080e7          	jalr	1766(ra) # 80003366 <iget>
    80003c88:	89aa                	mv	s3,a0
    80003c8a:	b7dd                	j	80003c70 <namex+0x42>
      iunlockput(ip);
    80003c8c:	854e                	mv	a0,s3
    80003c8e:	00000097          	auipc	ra,0x0
    80003c92:	c6e080e7          	jalr	-914(ra) # 800038fc <iunlockput>
      return 0;
    80003c96:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003c98:	854e                	mv	a0,s3
    80003c9a:	60e6                	ld	ra,88(sp)
    80003c9c:	6446                	ld	s0,80(sp)
    80003c9e:	64a6                	ld	s1,72(sp)
    80003ca0:	6906                	ld	s2,64(sp)
    80003ca2:	79e2                	ld	s3,56(sp)
    80003ca4:	7a42                	ld	s4,48(sp)
    80003ca6:	7aa2                	ld	s5,40(sp)
    80003ca8:	7b02                	ld	s6,32(sp)
    80003caa:	6be2                	ld	s7,24(sp)
    80003cac:	6c42                	ld	s8,16(sp)
    80003cae:	6ca2                	ld	s9,8(sp)
    80003cb0:	6125                	addi	sp,sp,96
    80003cb2:	8082                	ret
      iunlock(ip);
    80003cb4:	854e                	mv	a0,s3
    80003cb6:	00000097          	auipc	ra,0x0
    80003cba:	aa6080e7          	jalr	-1370(ra) # 8000375c <iunlock>
      return ip;
    80003cbe:	bfe9                	j	80003c98 <namex+0x6a>
      iunlockput(ip);
    80003cc0:	854e                	mv	a0,s3
    80003cc2:	00000097          	auipc	ra,0x0
    80003cc6:	c3a080e7          	jalr	-966(ra) # 800038fc <iunlockput>
      return 0;
    80003cca:	89d2                	mv	s3,s4
    80003ccc:	b7f1                	j	80003c98 <namex+0x6a>
  len = path - s;
    80003cce:	40b48633          	sub	a2,s1,a1
    80003cd2:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80003cd6:	094cd463          	bge	s9,s4,80003d5e <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003cda:	4639                	li	a2,14
    80003cdc:	8556                	mv	a0,s5
    80003cde:	ffffd097          	auipc	ra,0xffffd
    80003ce2:	062080e7          	jalr	98(ra) # 80000d40 <memmove>
  while(*path == '/')
    80003ce6:	0004c783          	lbu	a5,0(s1)
    80003cea:	01279763          	bne	a5,s2,80003cf8 <namex+0xca>
    path++;
    80003cee:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003cf0:	0004c783          	lbu	a5,0(s1)
    80003cf4:	ff278de3          	beq	a5,s2,80003cee <namex+0xc0>
    ilock(ip);
    80003cf8:	854e                	mv	a0,s3
    80003cfa:	00000097          	auipc	ra,0x0
    80003cfe:	9a0080e7          	jalr	-1632(ra) # 8000369a <ilock>
    if(ip->type != T_DIR){
    80003d02:	04499783          	lh	a5,68(s3)
    80003d06:	f98793e3          	bne	a5,s8,80003c8c <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003d0a:	000b0563          	beqz	s6,80003d14 <namex+0xe6>
    80003d0e:	0004c783          	lbu	a5,0(s1)
    80003d12:	d3cd                	beqz	a5,80003cb4 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003d14:	865e                	mv	a2,s7
    80003d16:	85d6                	mv	a1,s5
    80003d18:	854e                	mv	a0,s3
    80003d1a:	00000097          	auipc	ra,0x0
    80003d1e:	e64080e7          	jalr	-412(ra) # 80003b7e <dirlookup>
    80003d22:	8a2a                	mv	s4,a0
    80003d24:	dd51                	beqz	a0,80003cc0 <namex+0x92>
    iunlockput(ip);
    80003d26:	854e                	mv	a0,s3
    80003d28:	00000097          	auipc	ra,0x0
    80003d2c:	bd4080e7          	jalr	-1068(ra) # 800038fc <iunlockput>
    ip = next;
    80003d30:	89d2                	mv	s3,s4
  while(*path == '/')
    80003d32:	0004c783          	lbu	a5,0(s1)
    80003d36:	05279763          	bne	a5,s2,80003d84 <namex+0x156>
    path++;
    80003d3a:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003d3c:	0004c783          	lbu	a5,0(s1)
    80003d40:	ff278de3          	beq	a5,s2,80003d3a <namex+0x10c>
  if(*path == 0)
    80003d44:	c79d                	beqz	a5,80003d72 <namex+0x144>
    path++;
    80003d46:	85a6                	mv	a1,s1
  len = path - s;
    80003d48:	8a5e                	mv	s4,s7
    80003d4a:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80003d4c:	01278963          	beq	a5,s2,80003d5e <namex+0x130>
    80003d50:	dfbd                	beqz	a5,80003cce <namex+0xa0>
    path++;
    80003d52:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003d54:	0004c783          	lbu	a5,0(s1)
    80003d58:	ff279ce3          	bne	a5,s2,80003d50 <namex+0x122>
    80003d5c:	bf8d                	j	80003cce <namex+0xa0>
    memmove(name, s, len);
    80003d5e:	2601                	sext.w	a2,a2
    80003d60:	8556                	mv	a0,s5
    80003d62:	ffffd097          	auipc	ra,0xffffd
    80003d66:	fde080e7          	jalr	-34(ra) # 80000d40 <memmove>
    name[len] = 0;
    80003d6a:	9a56                	add	s4,s4,s5
    80003d6c:	000a0023          	sb	zero,0(s4)
    80003d70:	bf9d                	j	80003ce6 <namex+0xb8>
  if(nameiparent){
    80003d72:	f20b03e3          	beqz	s6,80003c98 <namex+0x6a>
    iput(ip);
    80003d76:	854e                	mv	a0,s3
    80003d78:	00000097          	auipc	ra,0x0
    80003d7c:	adc080e7          	jalr	-1316(ra) # 80003854 <iput>
    return 0;
    80003d80:	4981                	li	s3,0
    80003d82:	bf19                	j	80003c98 <namex+0x6a>
  if(*path == 0)
    80003d84:	d7fd                	beqz	a5,80003d72 <namex+0x144>
  while(*path != '/' && *path != 0)
    80003d86:	0004c783          	lbu	a5,0(s1)
    80003d8a:	85a6                	mv	a1,s1
    80003d8c:	b7d1                	j	80003d50 <namex+0x122>

0000000080003d8e <dirlink>:
{
    80003d8e:	7139                	addi	sp,sp,-64
    80003d90:	fc06                	sd	ra,56(sp)
    80003d92:	f822                	sd	s0,48(sp)
    80003d94:	f426                	sd	s1,40(sp)
    80003d96:	f04a                	sd	s2,32(sp)
    80003d98:	ec4e                	sd	s3,24(sp)
    80003d9a:	e852                	sd	s4,16(sp)
    80003d9c:	0080                	addi	s0,sp,64
    80003d9e:	892a                	mv	s2,a0
    80003da0:	8a2e                	mv	s4,a1
    80003da2:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003da4:	4601                	li	a2,0
    80003da6:	00000097          	auipc	ra,0x0
    80003daa:	dd8080e7          	jalr	-552(ra) # 80003b7e <dirlookup>
    80003dae:	e93d                	bnez	a0,80003e24 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003db0:	04c92483          	lw	s1,76(s2)
    80003db4:	c49d                	beqz	s1,80003de2 <dirlink+0x54>
    80003db6:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003db8:	4741                	li	a4,16
    80003dba:	86a6                	mv	a3,s1
    80003dbc:	fc040613          	addi	a2,s0,-64
    80003dc0:	4581                	li	a1,0
    80003dc2:	854a                	mv	a0,s2
    80003dc4:	00000097          	auipc	ra,0x0
    80003dc8:	b8a080e7          	jalr	-1142(ra) # 8000394e <readi>
    80003dcc:	47c1                	li	a5,16
    80003dce:	06f51163          	bne	a0,a5,80003e30 <dirlink+0xa2>
    if(de.inum == 0)
    80003dd2:	fc045783          	lhu	a5,-64(s0)
    80003dd6:	c791                	beqz	a5,80003de2 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003dd8:	24c1                	addiw	s1,s1,16
    80003dda:	04c92783          	lw	a5,76(s2)
    80003dde:	fcf4ede3          	bltu	s1,a5,80003db8 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003de2:	4639                	li	a2,14
    80003de4:	85d2                	mv	a1,s4
    80003de6:	fc240513          	addi	a0,s0,-62
    80003dea:	ffffd097          	auipc	ra,0xffffd
    80003dee:	00a080e7          	jalr	10(ra) # 80000df4 <strncpy>
  de.inum = inum;
    80003df2:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003df6:	4741                	li	a4,16
    80003df8:	86a6                	mv	a3,s1
    80003dfa:	fc040613          	addi	a2,s0,-64
    80003dfe:	4581                	li	a1,0
    80003e00:	854a                	mv	a0,s2
    80003e02:	00000097          	auipc	ra,0x0
    80003e06:	c44080e7          	jalr	-956(ra) # 80003a46 <writei>
    80003e0a:	872a                	mv	a4,a0
    80003e0c:	47c1                	li	a5,16
  return 0;
    80003e0e:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003e10:	02f71863          	bne	a4,a5,80003e40 <dirlink+0xb2>
}
    80003e14:	70e2                	ld	ra,56(sp)
    80003e16:	7442                	ld	s0,48(sp)
    80003e18:	74a2                	ld	s1,40(sp)
    80003e1a:	7902                	ld	s2,32(sp)
    80003e1c:	69e2                	ld	s3,24(sp)
    80003e1e:	6a42                	ld	s4,16(sp)
    80003e20:	6121                	addi	sp,sp,64
    80003e22:	8082                	ret
    iput(ip);
    80003e24:	00000097          	auipc	ra,0x0
    80003e28:	a30080e7          	jalr	-1488(ra) # 80003854 <iput>
    return -1;
    80003e2c:	557d                	li	a0,-1
    80003e2e:	b7dd                	j	80003e14 <dirlink+0x86>
      panic("dirlink read");
    80003e30:	00004517          	auipc	a0,0x4
    80003e34:	7e850513          	addi	a0,a0,2024 # 80008618 <syscalls+0x1c8>
    80003e38:	ffffc097          	auipc	ra,0xffffc
    80003e3c:	706080e7          	jalr	1798(ra) # 8000053e <panic>
    panic("dirlink");
    80003e40:	00005517          	auipc	a0,0x5
    80003e44:	8e850513          	addi	a0,a0,-1816 # 80008728 <syscalls+0x2d8>
    80003e48:	ffffc097          	auipc	ra,0xffffc
    80003e4c:	6f6080e7          	jalr	1782(ra) # 8000053e <panic>

0000000080003e50 <namei>:

struct inode*
namei(char *path)
{
    80003e50:	1101                	addi	sp,sp,-32
    80003e52:	ec06                	sd	ra,24(sp)
    80003e54:	e822                	sd	s0,16(sp)
    80003e56:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003e58:	fe040613          	addi	a2,s0,-32
    80003e5c:	4581                	li	a1,0
    80003e5e:	00000097          	auipc	ra,0x0
    80003e62:	dd0080e7          	jalr	-560(ra) # 80003c2e <namex>
}
    80003e66:	60e2                	ld	ra,24(sp)
    80003e68:	6442                	ld	s0,16(sp)
    80003e6a:	6105                	addi	sp,sp,32
    80003e6c:	8082                	ret

0000000080003e6e <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003e6e:	1141                	addi	sp,sp,-16
    80003e70:	e406                	sd	ra,8(sp)
    80003e72:	e022                	sd	s0,0(sp)
    80003e74:	0800                	addi	s0,sp,16
    80003e76:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80003e78:	4585                	li	a1,1
    80003e7a:	00000097          	auipc	ra,0x0
    80003e7e:	db4080e7          	jalr	-588(ra) # 80003c2e <namex>
}
    80003e82:	60a2                	ld	ra,8(sp)
    80003e84:	6402                	ld	s0,0(sp)
    80003e86:	0141                	addi	sp,sp,16
    80003e88:	8082                	ret

0000000080003e8a <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80003e8a:	1101                	addi	sp,sp,-32
    80003e8c:	ec06                	sd	ra,24(sp)
    80003e8e:	e822                	sd	s0,16(sp)
    80003e90:	e426                	sd	s1,8(sp)
    80003e92:	e04a                	sd	s2,0(sp)
    80003e94:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80003e96:	0001d917          	auipc	s2,0x1d
    80003e9a:	3da90913          	addi	s2,s2,986 # 80021270 <log>
    80003e9e:	01892583          	lw	a1,24(s2)
    80003ea2:	02892503          	lw	a0,40(s2)
    80003ea6:	fffff097          	auipc	ra,0xfffff
    80003eaa:	ff2080e7          	jalr	-14(ra) # 80002e98 <bread>
    80003eae:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80003eb0:	02c92683          	lw	a3,44(s2)
    80003eb4:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80003eb6:	02d05763          	blez	a3,80003ee4 <write_head+0x5a>
    80003eba:	0001d797          	auipc	a5,0x1d
    80003ebe:	3e678793          	addi	a5,a5,998 # 800212a0 <log+0x30>
    80003ec2:	05c50713          	addi	a4,a0,92
    80003ec6:	36fd                	addiw	a3,a3,-1
    80003ec8:	1682                	slli	a3,a3,0x20
    80003eca:	9281                	srli	a3,a3,0x20
    80003ecc:	068a                	slli	a3,a3,0x2
    80003ece:	0001d617          	auipc	a2,0x1d
    80003ed2:	3d660613          	addi	a2,a2,982 # 800212a4 <log+0x34>
    80003ed6:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80003ed8:	4390                	lw	a2,0(a5)
    80003eda:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80003edc:	0791                	addi	a5,a5,4
    80003ede:	0711                	addi	a4,a4,4
    80003ee0:	fed79ce3          	bne	a5,a3,80003ed8 <write_head+0x4e>
  }
  bwrite(buf);
    80003ee4:	8526                	mv	a0,s1
    80003ee6:	fffff097          	auipc	ra,0xfffff
    80003eea:	0a4080e7          	jalr	164(ra) # 80002f8a <bwrite>
  brelse(buf);
    80003eee:	8526                	mv	a0,s1
    80003ef0:	fffff097          	auipc	ra,0xfffff
    80003ef4:	0d8080e7          	jalr	216(ra) # 80002fc8 <brelse>
}
    80003ef8:	60e2                	ld	ra,24(sp)
    80003efa:	6442                	ld	s0,16(sp)
    80003efc:	64a2                	ld	s1,8(sp)
    80003efe:	6902                	ld	s2,0(sp)
    80003f00:	6105                	addi	sp,sp,32
    80003f02:	8082                	ret

0000000080003f04 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80003f04:	0001d797          	auipc	a5,0x1d
    80003f08:	3987a783          	lw	a5,920(a5) # 8002129c <log+0x2c>
    80003f0c:	0af05d63          	blez	a5,80003fc6 <install_trans+0xc2>
{
    80003f10:	7139                	addi	sp,sp,-64
    80003f12:	fc06                	sd	ra,56(sp)
    80003f14:	f822                	sd	s0,48(sp)
    80003f16:	f426                	sd	s1,40(sp)
    80003f18:	f04a                	sd	s2,32(sp)
    80003f1a:	ec4e                	sd	s3,24(sp)
    80003f1c:	e852                	sd	s4,16(sp)
    80003f1e:	e456                	sd	s5,8(sp)
    80003f20:	e05a                	sd	s6,0(sp)
    80003f22:	0080                	addi	s0,sp,64
    80003f24:	8b2a                	mv	s6,a0
    80003f26:	0001da97          	auipc	s5,0x1d
    80003f2a:	37aa8a93          	addi	s5,s5,890 # 800212a0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003f2e:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80003f30:	0001d997          	auipc	s3,0x1d
    80003f34:	34098993          	addi	s3,s3,832 # 80021270 <log>
    80003f38:	a035                	j	80003f64 <install_trans+0x60>
      bunpin(dbuf);
    80003f3a:	8526                	mv	a0,s1
    80003f3c:	fffff097          	auipc	ra,0xfffff
    80003f40:	166080e7          	jalr	358(ra) # 800030a2 <bunpin>
    brelse(lbuf);
    80003f44:	854a                	mv	a0,s2
    80003f46:	fffff097          	auipc	ra,0xfffff
    80003f4a:	082080e7          	jalr	130(ra) # 80002fc8 <brelse>
    brelse(dbuf);
    80003f4e:	8526                	mv	a0,s1
    80003f50:	fffff097          	auipc	ra,0xfffff
    80003f54:	078080e7          	jalr	120(ra) # 80002fc8 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003f58:	2a05                	addiw	s4,s4,1
    80003f5a:	0a91                	addi	s5,s5,4
    80003f5c:	02c9a783          	lw	a5,44(s3)
    80003f60:	04fa5963          	bge	s4,a5,80003fb2 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80003f64:	0189a583          	lw	a1,24(s3)
    80003f68:	014585bb          	addw	a1,a1,s4
    80003f6c:	2585                	addiw	a1,a1,1
    80003f6e:	0289a503          	lw	a0,40(s3)
    80003f72:	fffff097          	auipc	ra,0xfffff
    80003f76:	f26080e7          	jalr	-218(ra) # 80002e98 <bread>
    80003f7a:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80003f7c:	000aa583          	lw	a1,0(s5)
    80003f80:	0289a503          	lw	a0,40(s3)
    80003f84:	fffff097          	auipc	ra,0xfffff
    80003f88:	f14080e7          	jalr	-236(ra) # 80002e98 <bread>
    80003f8c:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80003f8e:	40000613          	li	a2,1024
    80003f92:	05890593          	addi	a1,s2,88
    80003f96:	05850513          	addi	a0,a0,88
    80003f9a:	ffffd097          	auipc	ra,0xffffd
    80003f9e:	da6080e7          	jalr	-602(ra) # 80000d40 <memmove>
    bwrite(dbuf);  // write dst to disk
    80003fa2:	8526                	mv	a0,s1
    80003fa4:	fffff097          	auipc	ra,0xfffff
    80003fa8:	fe6080e7          	jalr	-26(ra) # 80002f8a <bwrite>
    if(recovering == 0)
    80003fac:	f80b1ce3          	bnez	s6,80003f44 <install_trans+0x40>
    80003fb0:	b769                	j	80003f3a <install_trans+0x36>
}
    80003fb2:	70e2                	ld	ra,56(sp)
    80003fb4:	7442                	ld	s0,48(sp)
    80003fb6:	74a2                	ld	s1,40(sp)
    80003fb8:	7902                	ld	s2,32(sp)
    80003fba:	69e2                	ld	s3,24(sp)
    80003fbc:	6a42                	ld	s4,16(sp)
    80003fbe:	6aa2                	ld	s5,8(sp)
    80003fc0:	6b02                	ld	s6,0(sp)
    80003fc2:	6121                	addi	sp,sp,64
    80003fc4:	8082                	ret
    80003fc6:	8082                	ret

0000000080003fc8 <initlog>:
{
    80003fc8:	7179                	addi	sp,sp,-48
    80003fca:	f406                	sd	ra,40(sp)
    80003fcc:	f022                	sd	s0,32(sp)
    80003fce:	ec26                	sd	s1,24(sp)
    80003fd0:	e84a                	sd	s2,16(sp)
    80003fd2:	e44e                	sd	s3,8(sp)
    80003fd4:	1800                	addi	s0,sp,48
    80003fd6:	892a                	mv	s2,a0
    80003fd8:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80003fda:	0001d497          	auipc	s1,0x1d
    80003fde:	29648493          	addi	s1,s1,662 # 80021270 <log>
    80003fe2:	00004597          	auipc	a1,0x4
    80003fe6:	64658593          	addi	a1,a1,1606 # 80008628 <syscalls+0x1d8>
    80003fea:	8526                	mv	a0,s1
    80003fec:	ffffd097          	auipc	ra,0xffffd
    80003ff0:	b68080e7          	jalr	-1176(ra) # 80000b54 <initlock>
  log.start = sb->logstart;
    80003ff4:	0149a583          	lw	a1,20(s3)
    80003ff8:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80003ffa:	0109a783          	lw	a5,16(s3)
    80003ffe:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004000:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004004:	854a                	mv	a0,s2
    80004006:	fffff097          	auipc	ra,0xfffff
    8000400a:	e92080e7          	jalr	-366(ra) # 80002e98 <bread>
  log.lh.n = lh->n;
    8000400e:	4d3c                	lw	a5,88(a0)
    80004010:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004012:	02f05563          	blez	a5,8000403c <initlog+0x74>
    80004016:	05c50713          	addi	a4,a0,92
    8000401a:	0001d697          	auipc	a3,0x1d
    8000401e:	28668693          	addi	a3,a3,646 # 800212a0 <log+0x30>
    80004022:	37fd                	addiw	a5,a5,-1
    80004024:	1782                	slli	a5,a5,0x20
    80004026:	9381                	srli	a5,a5,0x20
    80004028:	078a                	slli	a5,a5,0x2
    8000402a:	06050613          	addi	a2,a0,96
    8000402e:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    80004030:	4310                	lw	a2,0(a4)
    80004032:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    80004034:	0711                	addi	a4,a4,4
    80004036:	0691                	addi	a3,a3,4
    80004038:	fef71ce3          	bne	a4,a5,80004030 <initlog+0x68>
  brelse(buf);
    8000403c:	fffff097          	auipc	ra,0xfffff
    80004040:	f8c080e7          	jalr	-116(ra) # 80002fc8 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004044:	4505                	li	a0,1
    80004046:	00000097          	auipc	ra,0x0
    8000404a:	ebe080e7          	jalr	-322(ra) # 80003f04 <install_trans>
  log.lh.n = 0;
    8000404e:	0001d797          	auipc	a5,0x1d
    80004052:	2407a723          	sw	zero,590(a5) # 8002129c <log+0x2c>
  write_head(); // clear the log
    80004056:	00000097          	auipc	ra,0x0
    8000405a:	e34080e7          	jalr	-460(ra) # 80003e8a <write_head>
}
    8000405e:	70a2                	ld	ra,40(sp)
    80004060:	7402                	ld	s0,32(sp)
    80004062:	64e2                	ld	s1,24(sp)
    80004064:	6942                	ld	s2,16(sp)
    80004066:	69a2                	ld	s3,8(sp)
    80004068:	6145                	addi	sp,sp,48
    8000406a:	8082                	ret

000000008000406c <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    8000406c:	1101                	addi	sp,sp,-32
    8000406e:	ec06                	sd	ra,24(sp)
    80004070:	e822                	sd	s0,16(sp)
    80004072:	e426                	sd	s1,8(sp)
    80004074:	e04a                	sd	s2,0(sp)
    80004076:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004078:	0001d517          	auipc	a0,0x1d
    8000407c:	1f850513          	addi	a0,a0,504 # 80021270 <log>
    80004080:	ffffd097          	auipc	ra,0xffffd
    80004084:	b64080e7          	jalr	-1180(ra) # 80000be4 <acquire>
  while(1){
    if(log.committing){
    80004088:	0001d497          	auipc	s1,0x1d
    8000408c:	1e848493          	addi	s1,s1,488 # 80021270 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004090:	4979                	li	s2,30
    80004092:	a039                	j	800040a0 <begin_op+0x34>
      sleep(&log, &log.lock);
    80004094:	85a6                	mv	a1,s1
    80004096:	8526                	mv	a0,s1
    80004098:	ffffe097          	auipc	ra,0xffffe
    8000409c:	050080e7          	jalr	80(ra) # 800020e8 <sleep>
    if(log.committing){
    800040a0:	50dc                	lw	a5,36(s1)
    800040a2:	fbed                	bnez	a5,80004094 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800040a4:	509c                	lw	a5,32(s1)
    800040a6:	0017871b          	addiw	a4,a5,1
    800040aa:	0007069b          	sext.w	a3,a4
    800040ae:	0027179b          	slliw	a5,a4,0x2
    800040b2:	9fb9                	addw	a5,a5,a4
    800040b4:	0017979b          	slliw	a5,a5,0x1
    800040b8:	54d8                	lw	a4,44(s1)
    800040ba:	9fb9                	addw	a5,a5,a4
    800040bc:	00f95963          	bge	s2,a5,800040ce <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    800040c0:	85a6                	mv	a1,s1
    800040c2:	8526                	mv	a0,s1
    800040c4:	ffffe097          	auipc	ra,0xffffe
    800040c8:	024080e7          	jalr	36(ra) # 800020e8 <sleep>
    800040cc:	bfd1                	j	800040a0 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    800040ce:	0001d517          	auipc	a0,0x1d
    800040d2:	1a250513          	addi	a0,a0,418 # 80021270 <log>
    800040d6:	d114                	sw	a3,32(a0)
      release(&log.lock);
    800040d8:	ffffd097          	auipc	ra,0xffffd
    800040dc:	bc0080e7          	jalr	-1088(ra) # 80000c98 <release>
      break;
    }
  }
}
    800040e0:	60e2                	ld	ra,24(sp)
    800040e2:	6442                	ld	s0,16(sp)
    800040e4:	64a2                	ld	s1,8(sp)
    800040e6:	6902                	ld	s2,0(sp)
    800040e8:	6105                	addi	sp,sp,32
    800040ea:	8082                	ret

00000000800040ec <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    800040ec:	7139                	addi	sp,sp,-64
    800040ee:	fc06                	sd	ra,56(sp)
    800040f0:	f822                	sd	s0,48(sp)
    800040f2:	f426                	sd	s1,40(sp)
    800040f4:	f04a                	sd	s2,32(sp)
    800040f6:	ec4e                	sd	s3,24(sp)
    800040f8:	e852                	sd	s4,16(sp)
    800040fa:	e456                	sd	s5,8(sp)
    800040fc:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    800040fe:	0001d497          	auipc	s1,0x1d
    80004102:	17248493          	addi	s1,s1,370 # 80021270 <log>
    80004106:	8526                	mv	a0,s1
    80004108:	ffffd097          	auipc	ra,0xffffd
    8000410c:	adc080e7          	jalr	-1316(ra) # 80000be4 <acquire>
  log.outstanding -= 1;
    80004110:	509c                	lw	a5,32(s1)
    80004112:	37fd                	addiw	a5,a5,-1
    80004114:	0007891b          	sext.w	s2,a5
    80004118:	d09c                	sw	a5,32(s1)
  if(log.committing)
    8000411a:	50dc                	lw	a5,36(s1)
    8000411c:	efb9                	bnez	a5,8000417a <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    8000411e:	06091663          	bnez	s2,8000418a <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    80004122:	0001d497          	auipc	s1,0x1d
    80004126:	14e48493          	addi	s1,s1,334 # 80021270 <log>
    8000412a:	4785                	li	a5,1
    8000412c:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    8000412e:	8526                	mv	a0,s1
    80004130:	ffffd097          	auipc	ra,0xffffd
    80004134:	b68080e7          	jalr	-1176(ra) # 80000c98 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004138:	54dc                	lw	a5,44(s1)
    8000413a:	06f04763          	bgtz	a5,800041a8 <end_op+0xbc>
    acquire(&log.lock);
    8000413e:	0001d497          	auipc	s1,0x1d
    80004142:	13248493          	addi	s1,s1,306 # 80021270 <log>
    80004146:	8526                	mv	a0,s1
    80004148:	ffffd097          	auipc	ra,0xffffd
    8000414c:	a9c080e7          	jalr	-1380(ra) # 80000be4 <acquire>
    log.committing = 0;
    80004150:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004154:	8526                	mv	a0,s1
    80004156:	ffffe097          	auipc	ra,0xffffe
    8000415a:	11e080e7          	jalr	286(ra) # 80002274 <wakeup>
    release(&log.lock);
    8000415e:	8526                	mv	a0,s1
    80004160:	ffffd097          	auipc	ra,0xffffd
    80004164:	b38080e7          	jalr	-1224(ra) # 80000c98 <release>
}
    80004168:	70e2                	ld	ra,56(sp)
    8000416a:	7442                	ld	s0,48(sp)
    8000416c:	74a2                	ld	s1,40(sp)
    8000416e:	7902                	ld	s2,32(sp)
    80004170:	69e2                	ld	s3,24(sp)
    80004172:	6a42                	ld	s4,16(sp)
    80004174:	6aa2                	ld	s5,8(sp)
    80004176:	6121                	addi	sp,sp,64
    80004178:	8082                	ret
    panic("log.committing");
    8000417a:	00004517          	auipc	a0,0x4
    8000417e:	4b650513          	addi	a0,a0,1206 # 80008630 <syscalls+0x1e0>
    80004182:	ffffc097          	auipc	ra,0xffffc
    80004186:	3bc080e7          	jalr	956(ra) # 8000053e <panic>
    wakeup(&log);
    8000418a:	0001d497          	auipc	s1,0x1d
    8000418e:	0e648493          	addi	s1,s1,230 # 80021270 <log>
    80004192:	8526                	mv	a0,s1
    80004194:	ffffe097          	auipc	ra,0xffffe
    80004198:	0e0080e7          	jalr	224(ra) # 80002274 <wakeup>
  release(&log.lock);
    8000419c:	8526                	mv	a0,s1
    8000419e:	ffffd097          	auipc	ra,0xffffd
    800041a2:	afa080e7          	jalr	-1286(ra) # 80000c98 <release>
  if(do_commit){
    800041a6:	b7c9                	j	80004168 <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    800041a8:	0001da97          	auipc	s5,0x1d
    800041ac:	0f8a8a93          	addi	s5,s5,248 # 800212a0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    800041b0:	0001da17          	auipc	s4,0x1d
    800041b4:	0c0a0a13          	addi	s4,s4,192 # 80021270 <log>
    800041b8:	018a2583          	lw	a1,24(s4)
    800041bc:	012585bb          	addw	a1,a1,s2
    800041c0:	2585                	addiw	a1,a1,1
    800041c2:	028a2503          	lw	a0,40(s4)
    800041c6:	fffff097          	auipc	ra,0xfffff
    800041ca:	cd2080e7          	jalr	-814(ra) # 80002e98 <bread>
    800041ce:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    800041d0:	000aa583          	lw	a1,0(s5)
    800041d4:	028a2503          	lw	a0,40(s4)
    800041d8:	fffff097          	auipc	ra,0xfffff
    800041dc:	cc0080e7          	jalr	-832(ra) # 80002e98 <bread>
    800041e0:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    800041e2:	40000613          	li	a2,1024
    800041e6:	05850593          	addi	a1,a0,88
    800041ea:	05848513          	addi	a0,s1,88
    800041ee:	ffffd097          	auipc	ra,0xffffd
    800041f2:	b52080e7          	jalr	-1198(ra) # 80000d40 <memmove>
    bwrite(to);  // write the log
    800041f6:	8526                	mv	a0,s1
    800041f8:	fffff097          	auipc	ra,0xfffff
    800041fc:	d92080e7          	jalr	-622(ra) # 80002f8a <bwrite>
    brelse(from);
    80004200:	854e                	mv	a0,s3
    80004202:	fffff097          	auipc	ra,0xfffff
    80004206:	dc6080e7          	jalr	-570(ra) # 80002fc8 <brelse>
    brelse(to);
    8000420a:	8526                	mv	a0,s1
    8000420c:	fffff097          	auipc	ra,0xfffff
    80004210:	dbc080e7          	jalr	-580(ra) # 80002fc8 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004214:	2905                	addiw	s2,s2,1
    80004216:	0a91                	addi	s5,s5,4
    80004218:	02ca2783          	lw	a5,44(s4)
    8000421c:	f8f94ee3          	blt	s2,a5,800041b8 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004220:	00000097          	auipc	ra,0x0
    80004224:	c6a080e7          	jalr	-918(ra) # 80003e8a <write_head>
    install_trans(0); // Now install writes to home locations
    80004228:	4501                	li	a0,0
    8000422a:	00000097          	auipc	ra,0x0
    8000422e:	cda080e7          	jalr	-806(ra) # 80003f04 <install_trans>
    log.lh.n = 0;
    80004232:	0001d797          	auipc	a5,0x1d
    80004236:	0607a523          	sw	zero,106(a5) # 8002129c <log+0x2c>
    write_head();    // Erase the transaction from the log
    8000423a:	00000097          	auipc	ra,0x0
    8000423e:	c50080e7          	jalr	-944(ra) # 80003e8a <write_head>
    80004242:	bdf5                	j	8000413e <end_op+0x52>

0000000080004244 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004244:	1101                	addi	sp,sp,-32
    80004246:	ec06                	sd	ra,24(sp)
    80004248:	e822                	sd	s0,16(sp)
    8000424a:	e426                	sd	s1,8(sp)
    8000424c:	e04a                	sd	s2,0(sp)
    8000424e:	1000                	addi	s0,sp,32
    80004250:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004252:	0001d917          	auipc	s2,0x1d
    80004256:	01e90913          	addi	s2,s2,30 # 80021270 <log>
    8000425a:	854a                	mv	a0,s2
    8000425c:	ffffd097          	auipc	ra,0xffffd
    80004260:	988080e7          	jalr	-1656(ra) # 80000be4 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004264:	02c92603          	lw	a2,44(s2)
    80004268:	47f5                	li	a5,29
    8000426a:	06c7c563          	blt	a5,a2,800042d4 <log_write+0x90>
    8000426e:	0001d797          	auipc	a5,0x1d
    80004272:	01e7a783          	lw	a5,30(a5) # 8002128c <log+0x1c>
    80004276:	37fd                	addiw	a5,a5,-1
    80004278:	04f65e63          	bge	a2,a5,800042d4 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    8000427c:	0001d797          	auipc	a5,0x1d
    80004280:	0147a783          	lw	a5,20(a5) # 80021290 <log+0x20>
    80004284:	06f05063          	blez	a5,800042e4 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004288:	4781                	li	a5,0
    8000428a:	06c05563          	blez	a2,800042f4 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    8000428e:	44cc                	lw	a1,12(s1)
    80004290:	0001d717          	auipc	a4,0x1d
    80004294:	01070713          	addi	a4,a4,16 # 800212a0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004298:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    8000429a:	4314                	lw	a3,0(a4)
    8000429c:	04b68c63          	beq	a3,a1,800042f4 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    800042a0:	2785                	addiw	a5,a5,1
    800042a2:	0711                	addi	a4,a4,4
    800042a4:	fef61be3          	bne	a2,a5,8000429a <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    800042a8:	0621                	addi	a2,a2,8
    800042aa:	060a                	slli	a2,a2,0x2
    800042ac:	0001d797          	auipc	a5,0x1d
    800042b0:	fc478793          	addi	a5,a5,-60 # 80021270 <log>
    800042b4:	963e                	add	a2,a2,a5
    800042b6:	44dc                	lw	a5,12(s1)
    800042b8:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    800042ba:	8526                	mv	a0,s1
    800042bc:	fffff097          	auipc	ra,0xfffff
    800042c0:	daa080e7          	jalr	-598(ra) # 80003066 <bpin>
    log.lh.n++;
    800042c4:	0001d717          	auipc	a4,0x1d
    800042c8:	fac70713          	addi	a4,a4,-84 # 80021270 <log>
    800042cc:	575c                	lw	a5,44(a4)
    800042ce:	2785                	addiw	a5,a5,1
    800042d0:	d75c                	sw	a5,44(a4)
    800042d2:	a835                	j	8000430e <log_write+0xca>
    panic("too big a transaction");
    800042d4:	00004517          	auipc	a0,0x4
    800042d8:	36c50513          	addi	a0,a0,876 # 80008640 <syscalls+0x1f0>
    800042dc:	ffffc097          	auipc	ra,0xffffc
    800042e0:	262080e7          	jalr	610(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    800042e4:	00004517          	auipc	a0,0x4
    800042e8:	37450513          	addi	a0,a0,884 # 80008658 <syscalls+0x208>
    800042ec:	ffffc097          	auipc	ra,0xffffc
    800042f0:	252080e7          	jalr	594(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    800042f4:	00878713          	addi	a4,a5,8
    800042f8:	00271693          	slli	a3,a4,0x2
    800042fc:	0001d717          	auipc	a4,0x1d
    80004300:	f7470713          	addi	a4,a4,-140 # 80021270 <log>
    80004304:	9736                	add	a4,a4,a3
    80004306:	44d4                	lw	a3,12(s1)
    80004308:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    8000430a:	faf608e3          	beq	a2,a5,800042ba <log_write+0x76>
  }
  release(&log.lock);
    8000430e:	0001d517          	auipc	a0,0x1d
    80004312:	f6250513          	addi	a0,a0,-158 # 80021270 <log>
    80004316:	ffffd097          	auipc	ra,0xffffd
    8000431a:	982080e7          	jalr	-1662(ra) # 80000c98 <release>
}
    8000431e:	60e2                	ld	ra,24(sp)
    80004320:	6442                	ld	s0,16(sp)
    80004322:	64a2                	ld	s1,8(sp)
    80004324:	6902                	ld	s2,0(sp)
    80004326:	6105                	addi	sp,sp,32
    80004328:	8082                	ret

000000008000432a <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    8000432a:	1101                	addi	sp,sp,-32
    8000432c:	ec06                	sd	ra,24(sp)
    8000432e:	e822                	sd	s0,16(sp)
    80004330:	e426                	sd	s1,8(sp)
    80004332:	e04a                	sd	s2,0(sp)
    80004334:	1000                	addi	s0,sp,32
    80004336:	84aa                	mv	s1,a0
    80004338:	892e                	mv	s2,a1
	initlock(&lk->lk, "sleep lock");
    8000433a:	00004597          	auipc	a1,0x4
    8000433e:	33e58593          	addi	a1,a1,830 # 80008678 <syscalls+0x228>
    80004342:	0521                	addi	a0,a0,8
    80004344:	ffffd097          	auipc	ra,0xffffd
    80004348:	810080e7          	jalr	-2032(ra) # 80000b54 <initlock>
	lk->name = name;
    8000434c:	0324b023          	sd	s2,32(s1)
	lk->locked = 0;
    80004350:	0004a023          	sw	zero,0(s1)
	lk->pid = 0;
    80004354:	0204a423          	sw	zero,40(s1)
}
    80004358:	60e2                	ld	ra,24(sp)
    8000435a:	6442                	ld	s0,16(sp)
    8000435c:	64a2                	ld	s1,8(sp)
    8000435e:	6902                	ld	s2,0(sp)
    80004360:	6105                	addi	sp,sp,32
    80004362:	8082                	ret

0000000080004364 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004364:	1101                	addi	sp,sp,-32
    80004366:	ec06                	sd	ra,24(sp)
    80004368:	e822                	sd	s0,16(sp)
    8000436a:	e426                	sd	s1,8(sp)
    8000436c:	e04a                	sd	s2,0(sp)
    8000436e:	1000                	addi	s0,sp,32
    80004370:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004372:	00850913          	addi	s2,a0,8
    80004376:	854a                	mv	a0,s2
    80004378:	ffffd097          	auipc	ra,0xffffd
    8000437c:	86c080e7          	jalr	-1940(ra) # 80000be4 <acquire>
  while (lk->locked) {
    80004380:	409c                	lw	a5,0(s1)
    80004382:	cb89                	beqz	a5,80004394 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004384:	85ca                	mv	a1,s2
    80004386:	8526                	mv	a0,s1
    80004388:	ffffe097          	auipc	ra,0xffffe
    8000438c:	d60080e7          	jalr	-672(ra) # 800020e8 <sleep>
  while (lk->locked) {
    80004390:	409c                	lw	a5,0(s1)
    80004392:	fbed                	bnez	a5,80004384 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004394:	4785                	li	a5,1
    80004396:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004398:	ffffd097          	auipc	ra,0xffffd
    8000439c:	694080e7          	jalr	1684(ra) # 80001a2c <myproc>
    800043a0:	591c                	lw	a5,48(a0)
    800043a2:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    800043a4:	854a                	mv	a0,s2
    800043a6:	ffffd097          	auipc	ra,0xffffd
    800043aa:	8f2080e7          	jalr	-1806(ra) # 80000c98 <release>
}
    800043ae:	60e2                	ld	ra,24(sp)
    800043b0:	6442                	ld	s0,16(sp)
    800043b2:	64a2                	ld	s1,8(sp)
    800043b4:	6902                	ld	s2,0(sp)
    800043b6:	6105                	addi	sp,sp,32
    800043b8:	8082                	ret

00000000800043ba <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    800043ba:	1101                	addi	sp,sp,-32
    800043bc:	ec06                	sd	ra,24(sp)
    800043be:	e822                	sd	s0,16(sp)
    800043c0:	e426                	sd	s1,8(sp)
    800043c2:	e04a                	sd	s2,0(sp)
    800043c4:	1000                	addi	s0,sp,32
    800043c6:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800043c8:	00850913          	addi	s2,a0,8
    800043cc:	854a                	mv	a0,s2
    800043ce:	ffffd097          	auipc	ra,0xffffd
    800043d2:	816080e7          	jalr	-2026(ra) # 80000be4 <acquire>
  lk->locked = 0;
    800043d6:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800043da:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    800043de:	8526                	mv	a0,s1
    800043e0:	ffffe097          	auipc	ra,0xffffe
    800043e4:	e94080e7          	jalr	-364(ra) # 80002274 <wakeup>
  release(&lk->lk);
    800043e8:	854a                	mv	a0,s2
    800043ea:	ffffd097          	auipc	ra,0xffffd
    800043ee:	8ae080e7          	jalr	-1874(ra) # 80000c98 <release>
}
    800043f2:	60e2                	ld	ra,24(sp)
    800043f4:	6442                	ld	s0,16(sp)
    800043f6:	64a2                	ld	s1,8(sp)
    800043f8:	6902                	ld	s2,0(sp)
    800043fa:	6105                	addi	sp,sp,32
    800043fc:	8082                	ret

00000000800043fe <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    800043fe:	7179                	addi	sp,sp,-48
    80004400:	f406                	sd	ra,40(sp)
    80004402:	f022                	sd	s0,32(sp)
    80004404:	ec26                	sd	s1,24(sp)
    80004406:	e84a                	sd	s2,16(sp)
    80004408:	e44e                	sd	s3,8(sp)
    8000440a:	1800                	addi	s0,sp,48
    8000440c:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    8000440e:	00850913          	addi	s2,a0,8
    80004412:	854a                	mv	a0,s2
    80004414:	ffffc097          	auipc	ra,0xffffc
    80004418:	7d0080e7          	jalr	2000(ra) # 80000be4 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    8000441c:	409c                	lw	a5,0(s1)
    8000441e:	ef99                	bnez	a5,8000443c <holdingsleep+0x3e>
    80004420:	4481                	li	s1,0
  release(&lk->lk);
    80004422:	854a                	mv	a0,s2
    80004424:	ffffd097          	auipc	ra,0xffffd
    80004428:	874080e7          	jalr	-1932(ra) # 80000c98 <release>
  return r;
}
    8000442c:	8526                	mv	a0,s1
    8000442e:	70a2                	ld	ra,40(sp)
    80004430:	7402                	ld	s0,32(sp)
    80004432:	64e2                	ld	s1,24(sp)
    80004434:	6942                	ld	s2,16(sp)
    80004436:	69a2                	ld	s3,8(sp)
    80004438:	6145                	addi	sp,sp,48
    8000443a:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    8000443c:	0284a983          	lw	s3,40(s1)
    80004440:	ffffd097          	auipc	ra,0xffffd
    80004444:	5ec080e7          	jalr	1516(ra) # 80001a2c <myproc>
    80004448:	5904                	lw	s1,48(a0)
    8000444a:	413484b3          	sub	s1,s1,s3
    8000444e:	0014b493          	seqz	s1,s1
    80004452:	bfc1                	j	80004422 <holdingsleep+0x24>

0000000080004454 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004454:	1141                	addi	sp,sp,-16
    80004456:	e406                	sd	ra,8(sp)
    80004458:	e022                	sd	s0,0(sp)
    8000445a:	0800                	addi	s0,sp,16
	initlock(&ftable.lock, "ftable");
    8000445c:	00004597          	auipc	a1,0x4
    80004460:	22c58593          	addi	a1,a1,556 # 80008688 <syscalls+0x238>
    80004464:	0001d517          	auipc	a0,0x1d
    80004468:	f5450513          	addi	a0,a0,-172 # 800213b8 <ftable>
    8000446c:	ffffc097          	auipc	ra,0xffffc
    80004470:	6e8080e7          	jalr	1768(ra) # 80000b54 <initlock>
}
    80004474:	60a2                	ld	ra,8(sp)
    80004476:	6402                	ld	s0,0(sp)
    80004478:	0141                	addi	sp,sp,16
    8000447a:	8082                	ret

000000008000447c <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    8000447c:	1101                	addi	sp,sp,-32
    8000447e:	ec06                	sd	ra,24(sp)
    80004480:	e822                	sd	s0,16(sp)
    80004482:	e426                	sd	s1,8(sp)
    80004484:	1000                	addi	s0,sp,32
	struct file *f;

	acquire(&ftable.lock);
    80004486:	0001d517          	auipc	a0,0x1d
    8000448a:	f3250513          	addi	a0,a0,-206 # 800213b8 <ftable>
    8000448e:	ffffc097          	auipc	ra,0xffffc
    80004492:	756080e7          	jalr	1878(ra) # 80000be4 <acquire>
	for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004496:	0001d497          	auipc	s1,0x1d
    8000449a:	f3a48493          	addi	s1,s1,-198 # 800213d0 <ftable+0x18>
    8000449e:	0001e717          	auipc	a4,0x1e
    800044a2:	ed270713          	addi	a4,a4,-302 # 80022370 <ftable+0xfb8>
		if(f->ref == 0){
    800044a6:	40dc                	lw	a5,4(s1)
    800044a8:	cf99                	beqz	a5,800044c6 <filealloc+0x4a>
	for(f = ftable.file; f < ftable.file + NFILE; f++){
    800044aa:	02848493          	addi	s1,s1,40
    800044ae:	fee49ce3          	bne	s1,a4,800044a6 <filealloc+0x2a>
			f->ref = 1;
			release(&ftable.lock);
			return f;
		}
	}
	release(&ftable.lock);
    800044b2:	0001d517          	auipc	a0,0x1d
    800044b6:	f0650513          	addi	a0,a0,-250 # 800213b8 <ftable>
    800044ba:	ffffc097          	auipc	ra,0xffffc
    800044be:	7de080e7          	jalr	2014(ra) # 80000c98 <release>
	return 0;
    800044c2:	4481                	li	s1,0
    800044c4:	a819                	j	800044da <filealloc+0x5e>
			f->ref = 1;
    800044c6:	4785                	li	a5,1
    800044c8:	c0dc                	sw	a5,4(s1)
			release(&ftable.lock);
    800044ca:	0001d517          	auipc	a0,0x1d
    800044ce:	eee50513          	addi	a0,a0,-274 # 800213b8 <ftable>
    800044d2:	ffffc097          	auipc	ra,0xffffc
    800044d6:	7c6080e7          	jalr	1990(ra) # 80000c98 <release>
}
    800044da:	8526                	mv	a0,s1
    800044dc:	60e2                	ld	ra,24(sp)
    800044de:	6442                	ld	s0,16(sp)
    800044e0:	64a2                	ld	s1,8(sp)
    800044e2:	6105                	addi	sp,sp,32
    800044e4:	8082                	ret

00000000800044e6 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    800044e6:	1101                	addi	sp,sp,-32
    800044e8:	ec06                	sd	ra,24(sp)
    800044ea:	e822                	sd	s0,16(sp)
    800044ec:	e426                	sd	s1,8(sp)
    800044ee:	1000                	addi	s0,sp,32
    800044f0:	84aa                	mv	s1,a0
	acquire(&ftable.lock);
    800044f2:	0001d517          	auipc	a0,0x1d
    800044f6:	ec650513          	addi	a0,a0,-314 # 800213b8 <ftable>
    800044fa:	ffffc097          	auipc	ra,0xffffc
    800044fe:	6ea080e7          	jalr	1770(ra) # 80000be4 <acquire>
	if(f->ref < 1)
    80004502:	40dc                	lw	a5,4(s1)
    80004504:	02f05263          	blez	a5,80004528 <filedup+0x42>
		panic("filedup");
	f->ref++;
    80004508:	2785                	addiw	a5,a5,1
    8000450a:	c0dc                	sw	a5,4(s1)
	release(&ftable.lock);
    8000450c:	0001d517          	auipc	a0,0x1d
    80004510:	eac50513          	addi	a0,a0,-340 # 800213b8 <ftable>
    80004514:	ffffc097          	auipc	ra,0xffffc
    80004518:	784080e7          	jalr	1924(ra) # 80000c98 <release>
	return f;
}
    8000451c:	8526                	mv	a0,s1
    8000451e:	60e2                	ld	ra,24(sp)
    80004520:	6442                	ld	s0,16(sp)
    80004522:	64a2                	ld	s1,8(sp)
    80004524:	6105                	addi	sp,sp,32
    80004526:	8082                	ret
		panic("filedup");
    80004528:	00004517          	auipc	a0,0x4
    8000452c:	16850513          	addi	a0,a0,360 # 80008690 <syscalls+0x240>
    80004530:	ffffc097          	auipc	ra,0xffffc
    80004534:	00e080e7          	jalr	14(ra) # 8000053e <panic>

0000000080004538 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004538:	7139                	addi	sp,sp,-64
    8000453a:	fc06                	sd	ra,56(sp)
    8000453c:	f822                	sd	s0,48(sp)
    8000453e:	f426                	sd	s1,40(sp)
    80004540:	f04a                	sd	s2,32(sp)
    80004542:	ec4e                	sd	s3,24(sp)
    80004544:	e852                	sd	s4,16(sp)
    80004546:	e456                	sd	s5,8(sp)
    80004548:	0080                	addi	s0,sp,64
    8000454a:	84aa                	mv	s1,a0
	struct file ff;

	acquire(&ftable.lock);
    8000454c:	0001d517          	auipc	a0,0x1d
    80004550:	e6c50513          	addi	a0,a0,-404 # 800213b8 <ftable>
    80004554:	ffffc097          	auipc	ra,0xffffc
    80004558:	690080e7          	jalr	1680(ra) # 80000be4 <acquire>
	if(f->ref < 1)
    8000455c:	40dc                	lw	a5,4(s1)
    8000455e:	06f05163          	blez	a5,800045c0 <fileclose+0x88>
		panic("fileclose");
	if(--f->ref > 0){
    80004562:	37fd                	addiw	a5,a5,-1
    80004564:	0007871b          	sext.w	a4,a5
    80004568:	c0dc                	sw	a5,4(s1)
    8000456a:	06e04363          	bgtz	a4,800045d0 <fileclose+0x98>
		release(&ftable.lock);
		return;
	}
	ff = *f;
    8000456e:	0004a903          	lw	s2,0(s1)
    80004572:	0094ca83          	lbu	s5,9(s1)
    80004576:	0104ba03          	ld	s4,16(s1)
    8000457a:	0184b983          	ld	s3,24(s1)
	f->ref = 0;
    8000457e:	0004a223          	sw	zero,4(s1)
	f->type = FD_NONE;
    80004582:	0004a023          	sw	zero,0(s1)
	release(&ftable.lock);
    80004586:	0001d517          	auipc	a0,0x1d
    8000458a:	e3250513          	addi	a0,a0,-462 # 800213b8 <ftable>
    8000458e:	ffffc097          	auipc	ra,0xffffc
    80004592:	70a080e7          	jalr	1802(ra) # 80000c98 <release>

	if(ff.type == FD_PIPE){
    80004596:	4785                	li	a5,1
    80004598:	04f90d63          	beq	s2,a5,800045f2 <fileclose+0xba>
		pipeclose(ff.pipe, ff.writable);
	} else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    8000459c:	3979                	addiw	s2,s2,-2
    8000459e:	4785                	li	a5,1
    800045a0:	0527e063          	bltu	a5,s2,800045e0 <fileclose+0xa8>
		begin_op();
    800045a4:	00000097          	auipc	ra,0x0
    800045a8:	ac8080e7          	jalr	-1336(ra) # 8000406c <begin_op>
		iput(ff.ip);
    800045ac:	854e                	mv	a0,s3
    800045ae:	fffff097          	auipc	ra,0xfffff
    800045b2:	2a6080e7          	jalr	678(ra) # 80003854 <iput>
		end_op();
    800045b6:	00000097          	auipc	ra,0x0
    800045ba:	b36080e7          	jalr	-1226(ra) # 800040ec <end_op>
    800045be:	a00d                	j	800045e0 <fileclose+0xa8>
		panic("fileclose");
    800045c0:	00004517          	auipc	a0,0x4
    800045c4:	0d850513          	addi	a0,a0,216 # 80008698 <syscalls+0x248>
    800045c8:	ffffc097          	auipc	ra,0xffffc
    800045cc:	f76080e7          	jalr	-138(ra) # 8000053e <panic>
		release(&ftable.lock);
    800045d0:	0001d517          	auipc	a0,0x1d
    800045d4:	de850513          	addi	a0,a0,-536 # 800213b8 <ftable>
    800045d8:	ffffc097          	auipc	ra,0xffffc
    800045dc:	6c0080e7          	jalr	1728(ra) # 80000c98 <release>
	}
}
    800045e0:	70e2                	ld	ra,56(sp)
    800045e2:	7442                	ld	s0,48(sp)
    800045e4:	74a2                	ld	s1,40(sp)
    800045e6:	7902                	ld	s2,32(sp)
    800045e8:	69e2                	ld	s3,24(sp)
    800045ea:	6a42                	ld	s4,16(sp)
    800045ec:	6aa2                	ld	s5,8(sp)
    800045ee:	6121                	addi	sp,sp,64
    800045f0:	8082                	ret
		pipeclose(ff.pipe, ff.writable);
    800045f2:	85d6                	mv	a1,s5
    800045f4:	8552                	mv	a0,s4
    800045f6:	00000097          	auipc	ra,0x0
    800045fa:	34c080e7          	jalr	844(ra) # 80004942 <pipeclose>
    800045fe:	b7cd                	j	800045e0 <fileclose+0xa8>

0000000080004600 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004600:	715d                	addi	sp,sp,-80
    80004602:	e486                	sd	ra,72(sp)
    80004604:	e0a2                	sd	s0,64(sp)
    80004606:	fc26                	sd	s1,56(sp)
    80004608:	f84a                	sd	s2,48(sp)
    8000460a:	f44e                	sd	s3,40(sp)
    8000460c:	0880                	addi	s0,sp,80
    8000460e:	84aa                	mv	s1,a0
    80004610:	89ae                	mv	s3,a1
	struct proc *p = myproc();
    80004612:	ffffd097          	auipc	ra,0xffffd
    80004616:	41a080e7          	jalr	1050(ra) # 80001a2c <myproc>
	struct stat st;

	if(f->type == FD_INODE || f->type == FD_DEVICE){
    8000461a:	409c                	lw	a5,0(s1)
    8000461c:	37f9                	addiw	a5,a5,-2
    8000461e:	4705                	li	a4,1
    80004620:	04f76763          	bltu	a4,a5,8000466e <filestat+0x6e>
    80004624:	892a                	mv	s2,a0
		ilock(f->ip);
    80004626:	6c88                	ld	a0,24(s1)
    80004628:	fffff097          	auipc	ra,0xfffff
    8000462c:	072080e7          	jalr	114(ra) # 8000369a <ilock>
		stati(f->ip, &st);
    80004630:	fb840593          	addi	a1,s0,-72
    80004634:	6c88                	ld	a0,24(s1)
    80004636:	fffff097          	auipc	ra,0xfffff
    8000463a:	2ee080e7          	jalr	750(ra) # 80003924 <stati>
		iunlock(f->ip);
    8000463e:	6c88                	ld	a0,24(s1)
    80004640:	fffff097          	auipc	ra,0xfffff
    80004644:	11c080e7          	jalr	284(ra) # 8000375c <iunlock>
		if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004648:	46e1                	li	a3,24
    8000464a:	fb840613          	addi	a2,s0,-72
    8000464e:	85ce                	mv	a1,s3
    80004650:	05093503          	ld	a0,80(s2)
    80004654:	ffffd097          	auipc	ra,0xffffd
    80004658:	01e080e7          	jalr	30(ra) # 80001672 <copyout>
    8000465c:	41f5551b          	sraiw	a0,a0,0x1f
			return -1;
		return 0;
	}
	return -1;
}
    80004660:	60a6                	ld	ra,72(sp)
    80004662:	6406                	ld	s0,64(sp)
    80004664:	74e2                	ld	s1,56(sp)
    80004666:	7942                	ld	s2,48(sp)
    80004668:	79a2                	ld	s3,40(sp)
    8000466a:	6161                	addi	sp,sp,80
    8000466c:	8082                	ret
	return -1;
    8000466e:	557d                	li	a0,-1
    80004670:	bfc5                	j	80004660 <filestat+0x60>

0000000080004672 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004672:	7179                	addi	sp,sp,-48
    80004674:	f406                	sd	ra,40(sp)
    80004676:	f022                	sd	s0,32(sp)
    80004678:	ec26                	sd	s1,24(sp)
    8000467a:	e84a                	sd	s2,16(sp)
    8000467c:	e44e                	sd	s3,8(sp)
    8000467e:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004680:	00854783          	lbu	a5,8(a0)
    80004684:	c3d5                	beqz	a5,80004728 <fileread+0xb6>
    80004686:	84aa                	mv	s1,a0
    80004688:	89ae                	mv	s3,a1
    8000468a:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    8000468c:	411c                	lw	a5,0(a0)
    8000468e:	4705                	li	a4,1
    80004690:	04e78963          	beq	a5,a4,800046e2 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004694:	470d                	li	a4,3
    80004696:	04e78d63          	beq	a5,a4,800046f0 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    8000469a:	4709                	li	a4,2
    8000469c:	06e79e63          	bne	a5,a4,80004718 <fileread+0xa6>
    ilock(f->ip);
    800046a0:	6d08                	ld	a0,24(a0)
    800046a2:	fffff097          	auipc	ra,0xfffff
    800046a6:	ff8080e7          	jalr	-8(ra) # 8000369a <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    800046aa:	874a                	mv	a4,s2
    800046ac:	5094                	lw	a3,32(s1)
    800046ae:	864e                	mv	a2,s3
    800046b0:	4585                	li	a1,1
    800046b2:	6c88                	ld	a0,24(s1)
    800046b4:	fffff097          	auipc	ra,0xfffff
    800046b8:	29a080e7          	jalr	666(ra) # 8000394e <readi>
    800046bc:	892a                	mv	s2,a0
    800046be:	00a05563          	blez	a0,800046c8 <fileread+0x56>
      f->off += r;
    800046c2:	509c                	lw	a5,32(s1)
    800046c4:	9fa9                	addw	a5,a5,a0
    800046c6:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    800046c8:	6c88                	ld	a0,24(s1)
    800046ca:	fffff097          	auipc	ra,0xfffff
    800046ce:	092080e7          	jalr	146(ra) # 8000375c <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    800046d2:	854a                	mv	a0,s2
    800046d4:	70a2                	ld	ra,40(sp)
    800046d6:	7402                	ld	s0,32(sp)
    800046d8:	64e2                	ld	s1,24(sp)
    800046da:	6942                	ld	s2,16(sp)
    800046dc:	69a2                	ld	s3,8(sp)
    800046de:	6145                	addi	sp,sp,48
    800046e0:	8082                	ret
    r = piperead(f->pipe, addr, n);
    800046e2:	6908                	ld	a0,16(a0)
    800046e4:	00000097          	auipc	ra,0x0
    800046e8:	3c8080e7          	jalr	968(ra) # 80004aac <piperead>
    800046ec:	892a                	mv	s2,a0
    800046ee:	b7d5                	j	800046d2 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    800046f0:	02451783          	lh	a5,36(a0)
    800046f4:	03079693          	slli	a3,a5,0x30
    800046f8:	92c1                	srli	a3,a3,0x30
    800046fa:	4725                	li	a4,9
    800046fc:	02d76863          	bltu	a4,a3,8000472c <fileread+0xba>
    80004700:	0792                	slli	a5,a5,0x4
    80004702:	0001d717          	auipc	a4,0x1d
    80004706:	c1670713          	addi	a4,a4,-1002 # 80021318 <devsw>
    8000470a:	97ba                	add	a5,a5,a4
    8000470c:	639c                	ld	a5,0(a5)
    8000470e:	c38d                	beqz	a5,80004730 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004710:	4505                	li	a0,1
    80004712:	9782                	jalr	a5
    80004714:	892a                	mv	s2,a0
    80004716:	bf75                	j	800046d2 <fileread+0x60>
    panic("fileread");
    80004718:	00004517          	auipc	a0,0x4
    8000471c:	f9050513          	addi	a0,a0,-112 # 800086a8 <syscalls+0x258>
    80004720:	ffffc097          	auipc	ra,0xffffc
    80004724:	e1e080e7          	jalr	-482(ra) # 8000053e <panic>
    return -1;
    80004728:	597d                	li	s2,-1
    8000472a:	b765                	j	800046d2 <fileread+0x60>
      return -1;
    8000472c:	597d                	li	s2,-1
    8000472e:	b755                	j	800046d2 <fileread+0x60>
    80004730:	597d                	li	s2,-1
    80004732:	b745                	j	800046d2 <fileread+0x60>

0000000080004734 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004734:	715d                	addi	sp,sp,-80
    80004736:	e486                	sd	ra,72(sp)
    80004738:	e0a2                	sd	s0,64(sp)
    8000473a:	fc26                	sd	s1,56(sp)
    8000473c:	f84a                	sd	s2,48(sp)
    8000473e:	f44e                	sd	s3,40(sp)
    80004740:	f052                	sd	s4,32(sp)
    80004742:	ec56                	sd	s5,24(sp)
    80004744:	e85a                	sd	s6,16(sp)
    80004746:	e45e                	sd	s7,8(sp)
    80004748:	e062                	sd	s8,0(sp)
    8000474a:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    8000474c:	00954783          	lbu	a5,9(a0)
    80004750:	10078663          	beqz	a5,8000485c <filewrite+0x128>
    80004754:	892a                	mv	s2,a0
    80004756:	8aae                	mv	s5,a1
    80004758:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    8000475a:	411c                	lw	a5,0(a0)
    8000475c:	4705                	li	a4,1
    8000475e:	02e78263          	beq	a5,a4,80004782 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004762:	470d                	li	a4,3
    80004764:	02e78663          	beq	a5,a4,80004790 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004768:	4709                	li	a4,2
    8000476a:	0ee79163          	bne	a5,a4,8000484c <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    8000476e:	0ac05d63          	blez	a2,80004828 <filewrite+0xf4>
    int i = 0;
    80004772:	4981                	li	s3,0
    80004774:	6b05                	lui	s6,0x1
    80004776:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    8000477a:	6b85                	lui	s7,0x1
    8000477c:	c00b8b9b          	addiw	s7,s7,-1024
    80004780:	a861                	j	80004818 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004782:	6908                	ld	a0,16(a0)
    80004784:	00000097          	auipc	ra,0x0
    80004788:	22e080e7          	jalr	558(ra) # 800049b2 <pipewrite>
    8000478c:	8a2a                	mv	s4,a0
    8000478e:	a045                	j	8000482e <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004790:	02451783          	lh	a5,36(a0)
    80004794:	03079693          	slli	a3,a5,0x30
    80004798:	92c1                	srli	a3,a3,0x30
    8000479a:	4725                	li	a4,9
    8000479c:	0cd76263          	bltu	a4,a3,80004860 <filewrite+0x12c>
    800047a0:	0792                	slli	a5,a5,0x4
    800047a2:	0001d717          	auipc	a4,0x1d
    800047a6:	b7670713          	addi	a4,a4,-1162 # 80021318 <devsw>
    800047aa:	97ba                	add	a5,a5,a4
    800047ac:	679c                	ld	a5,8(a5)
    800047ae:	cbdd                	beqz	a5,80004864 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    800047b0:	4505                	li	a0,1
    800047b2:	9782                	jalr	a5
    800047b4:	8a2a                	mv	s4,a0
    800047b6:	a8a5                	j	8000482e <filewrite+0xfa>
    800047b8:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    800047bc:	00000097          	auipc	ra,0x0
    800047c0:	8b0080e7          	jalr	-1872(ra) # 8000406c <begin_op>
      ilock(f->ip);
    800047c4:	01893503          	ld	a0,24(s2)
    800047c8:	fffff097          	auipc	ra,0xfffff
    800047cc:	ed2080e7          	jalr	-302(ra) # 8000369a <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    800047d0:	8762                	mv	a4,s8
    800047d2:	02092683          	lw	a3,32(s2)
    800047d6:	01598633          	add	a2,s3,s5
    800047da:	4585                	li	a1,1
    800047dc:	01893503          	ld	a0,24(s2)
    800047e0:	fffff097          	auipc	ra,0xfffff
    800047e4:	266080e7          	jalr	614(ra) # 80003a46 <writei>
    800047e8:	84aa                	mv	s1,a0
    800047ea:	00a05763          	blez	a0,800047f8 <filewrite+0xc4>
        f->off += r;
    800047ee:	02092783          	lw	a5,32(s2)
    800047f2:	9fa9                	addw	a5,a5,a0
    800047f4:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    800047f8:	01893503          	ld	a0,24(s2)
    800047fc:	fffff097          	auipc	ra,0xfffff
    80004800:	f60080e7          	jalr	-160(ra) # 8000375c <iunlock>
      end_op();
    80004804:	00000097          	auipc	ra,0x0
    80004808:	8e8080e7          	jalr	-1816(ra) # 800040ec <end_op>

      if(r != n1){
    8000480c:	009c1f63          	bne	s8,s1,8000482a <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004810:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004814:	0149db63          	bge	s3,s4,8000482a <filewrite+0xf6>
      int n1 = n - i;
    80004818:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    8000481c:	84be                	mv	s1,a5
    8000481e:	2781                	sext.w	a5,a5
    80004820:	f8fb5ce3          	bge	s6,a5,800047b8 <filewrite+0x84>
    80004824:	84de                	mv	s1,s7
    80004826:	bf49                	j	800047b8 <filewrite+0x84>
    int i = 0;
    80004828:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    8000482a:	013a1f63          	bne	s4,s3,80004848 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    8000482e:	8552                	mv	a0,s4
    80004830:	60a6                	ld	ra,72(sp)
    80004832:	6406                	ld	s0,64(sp)
    80004834:	74e2                	ld	s1,56(sp)
    80004836:	7942                	ld	s2,48(sp)
    80004838:	79a2                	ld	s3,40(sp)
    8000483a:	7a02                	ld	s4,32(sp)
    8000483c:	6ae2                	ld	s5,24(sp)
    8000483e:	6b42                	ld	s6,16(sp)
    80004840:	6ba2                	ld	s7,8(sp)
    80004842:	6c02                	ld	s8,0(sp)
    80004844:	6161                	addi	sp,sp,80
    80004846:	8082                	ret
    ret = (i == n ? n : -1);
    80004848:	5a7d                	li	s4,-1
    8000484a:	b7d5                	j	8000482e <filewrite+0xfa>
    panic("filewrite");
    8000484c:	00004517          	auipc	a0,0x4
    80004850:	e6c50513          	addi	a0,a0,-404 # 800086b8 <syscalls+0x268>
    80004854:	ffffc097          	auipc	ra,0xffffc
    80004858:	cea080e7          	jalr	-790(ra) # 8000053e <panic>
    return -1;
    8000485c:	5a7d                	li	s4,-1
    8000485e:	bfc1                	j	8000482e <filewrite+0xfa>
      return -1;
    80004860:	5a7d                	li	s4,-1
    80004862:	b7f1                	j	8000482e <filewrite+0xfa>
    80004864:	5a7d                	li	s4,-1
    80004866:	b7e1                	j	8000482e <filewrite+0xfa>

0000000080004868 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004868:	7179                	addi	sp,sp,-48
    8000486a:	f406                	sd	ra,40(sp)
    8000486c:	f022                	sd	s0,32(sp)
    8000486e:	ec26                	sd	s1,24(sp)
    80004870:	e84a                	sd	s2,16(sp)
    80004872:	e44e                	sd	s3,8(sp)
    80004874:	e052                	sd	s4,0(sp)
    80004876:	1800                	addi	s0,sp,48
    80004878:	84aa                	mv	s1,a0
    8000487a:	8a2e                	mv	s4,a1
	struct pipe *pi;

	pi = 0;
	*f0 = *f1 = 0;
    8000487c:	0005b023          	sd	zero,0(a1)
    80004880:	00053023          	sd	zero,0(a0)
	if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004884:	00000097          	auipc	ra,0x0
    80004888:	bf8080e7          	jalr	-1032(ra) # 8000447c <filealloc>
    8000488c:	e088                	sd	a0,0(s1)
    8000488e:	c551                	beqz	a0,8000491a <pipealloc+0xb2>
    80004890:	00000097          	auipc	ra,0x0
    80004894:	bec080e7          	jalr	-1044(ra) # 8000447c <filealloc>
    80004898:	00aa3023          	sd	a0,0(s4)
    8000489c:	c92d                	beqz	a0,8000490e <pipealloc+0xa6>
		goto bad;
	if((pi = (struct pipe*)kalloc()) == 0)
    8000489e:	ffffc097          	auipc	ra,0xffffc
    800048a2:	256080e7          	jalr	598(ra) # 80000af4 <kalloc>
    800048a6:	892a                	mv	s2,a0
    800048a8:	c125                	beqz	a0,80004908 <pipealloc+0xa0>
		goto bad;
	pi->readopen = 1;
    800048aa:	4985                	li	s3,1
    800048ac:	23352023          	sw	s3,544(a0)
	pi->writeopen = 1;
    800048b0:	23352223          	sw	s3,548(a0)
	pi->nwrite = 0;
    800048b4:	20052e23          	sw	zero,540(a0)
	pi->nread = 0;
    800048b8:	20052c23          	sw	zero,536(a0)
	initlock(&pi->lock, "pipe");
    800048bc:	00004597          	auipc	a1,0x4
    800048c0:	e0c58593          	addi	a1,a1,-500 # 800086c8 <syscalls+0x278>
    800048c4:	ffffc097          	auipc	ra,0xffffc
    800048c8:	290080e7          	jalr	656(ra) # 80000b54 <initlock>
	(*f0)->type = FD_PIPE;
    800048cc:	609c                	ld	a5,0(s1)
    800048ce:	0137a023          	sw	s3,0(a5)
	(*f0)->readable = 1;
    800048d2:	609c                	ld	a5,0(s1)
    800048d4:	01378423          	sb	s3,8(a5)
	(*f0)->writable = 0;
    800048d8:	609c                	ld	a5,0(s1)
    800048da:	000784a3          	sb	zero,9(a5)
	(*f0)->pipe = pi;
    800048de:	609c                	ld	a5,0(s1)
    800048e0:	0127b823          	sd	s2,16(a5)
	(*f1)->type = FD_PIPE;
    800048e4:	000a3783          	ld	a5,0(s4)
    800048e8:	0137a023          	sw	s3,0(a5)
	(*f1)->readable = 0;
    800048ec:	000a3783          	ld	a5,0(s4)
    800048f0:	00078423          	sb	zero,8(a5)
	(*f1)->writable = 1;
    800048f4:	000a3783          	ld	a5,0(s4)
    800048f8:	013784a3          	sb	s3,9(a5)
	(*f1)->pipe = pi;
    800048fc:	000a3783          	ld	a5,0(s4)
    80004900:	0127b823          	sd	s2,16(a5)
	return 0;
    80004904:	4501                	li	a0,0
    80004906:	a025                	j	8000492e <pipealloc+0xc6>

bad:
	if(pi)
		kfree((char*)pi);
	if(*f0)
    80004908:	6088                	ld	a0,0(s1)
    8000490a:	e501                	bnez	a0,80004912 <pipealloc+0xaa>
    8000490c:	a039                	j	8000491a <pipealloc+0xb2>
    8000490e:	6088                	ld	a0,0(s1)
    80004910:	c51d                	beqz	a0,8000493e <pipealloc+0xd6>
		fileclose(*f0);
    80004912:	00000097          	auipc	ra,0x0
    80004916:	c26080e7          	jalr	-986(ra) # 80004538 <fileclose>
	if(*f1)
    8000491a:	000a3783          	ld	a5,0(s4)
		fileclose(*f1);
	return -1;
    8000491e:	557d                	li	a0,-1
	if(*f1)
    80004920:	c799                	beqz	a5,8000492e <pipealloc+0xc6>
		fileclose(*f1);
    80004922:	853e                	mv	a0,a5
    80004924:	00000097          	auipc	ra,0x0
    80004928:	c14080e7          	jalr	-1004(ra) # 80004538 <fileclose>
	return -1;
    8000492c:	557d                	li	a0,-1
}
    8000492e:	70a2                	ld	ra,40(sp)
    80004930:	7402                	ld	s0,32(sp)
    80004932:	64e2                	ld	s1,24(sp)
    80004934:	6942                	ld	s2,16(sp)
    80004936:	69a2                	ld	s3,8(sp)
    80004938:	6a02                	ld	s4,0(sp)
    8000493a:	6145                	addi	sp,sp,48
    8000493c:	8082                	ret
	return -1;
    8000493e:	557d                	li	a0,-1
    80004940:	b7fd                	j	8000492e <pipealloc+0xc6>

0000000080004942 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004942:	1101                	addi	sp,sp,-32
    80004944:	ec06                	sd	ra,24(sp)
    80004946:	e822                	sd	s0,16(sp)
    80004948:	e426                	sd	s1,8(sp)
    8000494a:	e04a                	sd	s2,0(sp)
    8000494c:	1000                	addi	s0,sp,32
    8000494e:	84aa                	mv	s1,a0
    80004950:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004952:	ffffc097          	auipc	ra,0xffffc
    80004956:	292080e7          	jalr	658(ra) # 80000be4 <acquire>
  if(writable){
    8000495a:	02090d63          	beqz	s2,80004994 <pipeclose+0x52>
    pi->writeopen = 0;
    8000495e:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004962:	21848513          	addi	a0,s1,536
    80004966:	ffffe097          	auipc	ra,0xffffe
    8000496a:	90e080e7          	jalr	-1778(ra) # 80002274 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    8000496e:	2204b783          	ld	a5,544(s1)
    80004972:	eb95                	bnez	a5,800049a6 <pipeclose+0x64>
    release(&pi->lock);
    80004974:	8526                	mv	a0,s1
    80004976:	ffffc097          	auipc	ra,0xffffc
    8000497a:	322080e7          	jalr	802(ra) # 80000c98 <release>
    kfree((char*)pi);
    8000497e:	8526                	mv	a0,s1
    80004980:	ffffc097          	auipc	ra,0xffffc
    80004984:	078080e7          	jalr	120(ra) # 800009f8 <kfree>
  } else
    release(&pi->lock);
}
    80004988:	60e2                	ld	ra,24(sp)
    8000498a:	6442                	ld	s0,16(sp)
    8000498c:	64a2                	ld	s1,8(sp)
    8000498e:	6902                	ld	s2,0(sp)
    80004990:	6105                	addi	sp,sp,32
    80004992:	8082                	ret
    pi->readopen = 0;
    80004994:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004998:	21c48513          	addi	a0,s1,540
    8000499c:	ffffe097          	auipc	ra,0xffffe
    800049a0:	8d8080e7          	jalr	-1832(ra) # 80002274 <wakeup>
    800049a4:	b7e9                	j	8000496e <pipeclose+0x2c>
    release(&pi->lock);
    800049a6:	8526                	mv	a0,s1
    800049a8:	ffffc097          	auipc	ra,0xffffc
    800049ac:	2f0080e7          	jalr	752(ra) # 80000c98 <release>
}
    800049b0:	bfe1                	j	80004988 <pipeclose+0x46>

00000000800049b2 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    800049b2:	7159                	addi	sp,sp,-112
    800049b4:	f486                	sd	ra,104(sp)
    800049b6:	f0a2                	sd	s0,96(sp)
    800049b8:	eca6                	sd	s1,88(sp)
    800049ba:	e8ca                	sd	s2,80(sp)
    800049bc:	e4ce                	sd	s3,72(sp)
    800049be:	e0d2                	sd	s4,64(sp)
    800049c0:	fc56                	sd	s5,56(sp)
    800049c2:	f85a                	sd	s6,48(sp)
    800049c4:	f45e                	sd	s7,40(sp)
    800049c6:	f062                	sd	s8,32(sp)
    800049c8:	ec66                	sd	s9,24(sp)
    800049ca:	1880                	addi	s0,sp,112
    800049cc:	84aa                	mv	s1,a0
    800049ce:	8aae                	mv	s5,a1
    800049d0:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    800049d2:	ffffd097          	auipc	ra,0xffffd
    800049d6:	05a080e7          	jalr	90(ra) # 80001a2c <myproc>
    800049da:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    800049dc:	8526                	mv	a0,s1
    800049de:	ffffc097          	auipc	ra,0xffffc
    800049e2:	206080e7          	jalr	518(ra) # 80000be4 <acquire>
  while(i < n){
    800049e6:	0d405163          	blez	s4,80004aa8 <pipewrite+0xf6>
    800049ea:	8ba6                	mv	s7,s1
  int i = 0;
    800049ec:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    800049ee:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    800049f0:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    800049f4:	21c48c13          	addi	s8,s1,540
    800049f8:	a08d                	j	80004a5a <pipewrite+0xa8>
      release(&pi->lock);
    800049fa:	8526                	mv	a0,s1
    800049fc:	ffffc097          	auipc	ra,0xffffc
    80004a00:	29c080e7          	jalr	668(ra) # 80000c98 <release>
      return -1;
    80004a04:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004a06:	854a                	mv	a0,s2
    80004a08:	70a6                	ld	ra,104(sp)
    80004a0a:	7406                	ld	s0,96(sp)
    80004a0c:	64e6                	ld	s1,88(sp)
    80004a0e:	6946                	ld	s2,80(sp)
    80004a10:	69a6                	ld	s3,72(sp)
    80004a12:	6a06                	ld	s4,64(sp)
    80004a14:	7ae2                	ld	s5,56(sp)
    80004a16:	7b42                	ld	s6,48(sp)
    80004a18:	7ba2                	ld	s7,40(sp)
    80004a1a:	7c02                	ld	s8,32(sp)
    80004a1c:	6ce2                	ld	s9,24(sp)
    80004a1e:	6165                	addi	sp,sp,112
    80004a20:	8082                	ret
      wakeup(&pi->nread);
    80004a22:	8566                	mv	a0,s9
    80004a24:	ffffe097          	auipc	ra,0xffffe
    80004a28:	850080e7          	jalr	-1968(ra) # 80002274 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004a2c:	85de                	mv	a1,s7
    80004a2e:	8562                	mv	a0,s8
    80004a30:	ffffd097          	auipc	ra,0xffffd
    80004a34:	6b8080e7          	jalr	1720(ra) # 800020e8 <sleep>
    80004a38:	a839                	j	80004a56 <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004a3a:	21c4a783          	lw	a5,540(s1)
    80004a3e:	0017871b          	addiw	a4,a5,1
    80004a42:	20e4ae23          	sw	a4,540(s1)
    80004a46:	1ff7f793          	andi	a5,a5,511
    80004a4a:	97a6                	add	a5,a5,s1
    80004a4c:	f9f44703          	lbu	a4,-97(s0)
    80004a50:	00e78c23          	sb	a4,24(a5)
      i++;
    80004a54:	2905                	addiw	s2,s2,1
  while(i < n){
    80004a56:	03495d63          	bge	s2,s4,80004a90 <pipewrite+0xde>
    if(pi->readopen == 0 || pr->killed){
    80004a5a:	2204a783          	lw	a5,544(s1)
    80004a5e:	dfd1                	beqz	a5,800049fa <pipewrite+0x48>
    80004a60:	0289a783          	lw	a5,40(s3)
    80004a64:	fbd9                	bnez	a5,800049fa <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004a66:	2184a783          	lw	a5,536(s1)
    80004a6a:	21c4a703          	lw	a4,540(s1)
    80004a6e:	2007879b          	addiw	a5,a5,512
    80004a72:	faf708e3          	beq	a4,a5,80004a22 <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004a76:	4685                	li	a3,1
    80004a78:	01590633          	add	a2,s2,s5
    80004a7c:	f9f40593          	addi	a1,s0,-97
    80004a80:	0509b503          	ld	a0,80(s3)
    80004a84:	ffffd097          	auipc	ra,0xffffd
    80004a88:	c7a080e7          	jalr	-902(ra) # 800016fe <copyin>
    80004a8c:	fb6517e3          	bne	a0,s6,80004a3a <pipewrite+0x88>
  wakeup(&pi->nread);
    80004a90:	21848513          	addi	a0,s1,536
    80004a94:	ffffd097          	auipc	ra,0xffffd
    80004a98:	7e0080e7          	jalr	2016(ra) # 80002274 <wakeup>
  release(&pi->lock);
    80004a9c:	8526                	mv	a0,s1
    80004a9e:	ffffc097          	auipc	ra,0xffffc
    80004aa2:	1fa080e7          	jalr	506(ra) # 80000c98 <release>
  return i;
    80004aa6:	b785                	j	80004a06 <pipewrite+0x54>
  int i = 0;
    80004aa8:	4901                	li	s2,0
    80004aaa:	b7dd                	j	80004a90 <pipewrite+0xde>

0000000080004aac <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004aac:	715d                	addi	sp,sp,-80
    80004aae:	e486                	sd	ra,72(sp)
    80004ab0:	e0a2                	sd	s0,64(sp)
    80004ab2:	fc26                	sd	s1,56(sp)
    80004ab4:	f84a                	sd	s2,48(sp)
    80004ab6:	f44e                	sd	s3,40(sp)
    80004ab8:	f052                	sd	s4,32(sp)
    80004aba:	ec56                	sd	s5,24(sp)
    80004abc:	e85a                	sd	s6,16(sp)
    80004abe:	0880                	addi	s0,sp,80
    80004ac0:	84aa                	mv	s1,a0
    80004ac2:	892e                	mv	s2,a1
    80004ac4:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004ac6:	ffffd097          	auipc	ra,0xffffd
    80004aca:	f66080e7          	jalr	-154(ra) # 80001a2c <myproc>
    80004ace:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004ad0:	8b26                	mv	s6,s1
    80004ad2:	8526                	mv	a0,s1
    80004ad4:	ffffc097          	auipc	ra,0xffffc
    80004ad8:	110080e7          	jalr	272(ra) # 80000be4 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004adc:	2184a703          	lw	a4,536(s1)
    80004ae0:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004ae4:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004ae8:	02f71463          	bne	a4,a5,80004b10 <piperead+0x64>
    80004aec:	2244a783          	lw	a5,548(s1)
    80004af0:	c385                	beqz	a5,80004b10 <piperead+0x64>
    if(pr->killed){
    80004af2:	028a2783          	lw	a5,40(s4)
    80004af6:	ebc1                	bnez	a5,80004b86 <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004af8:	85da                	mv	a1,s6
    80004afa:	854e                	mv	a0,s3
    80004afc:	ffffd097          	auipc	ra,0xffffd
    80004b00:	5ec080e7          	jalr	1516(ra) # 800020e8 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004b04:	2184a703          	lw	a4,536(s1)
    80004b08:	21c4a783          	lw	a5,540(s1)
    80004b0c:	fef700e3          	beq	a4,a5,80004aec <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004b10:	09505263          	blez	s5,80004b94 <piperead+0xe8>
    80004b14:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004b16:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80004b18:	2184a783          	lw	a5,536(s1)
    80004b1c:	21c4a703          	lw	a4,540(s1)
    80004b20:	02f70d63          	beq	a4,a5,80004b5a <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004b24:	0017871b          	addiw	a4,a5,1
    80004b28:	20e4ac23          	sw	a4,536(s1)
    80004b2c:	1ff7f793          	andi	a5,a5,511
    80004b30:	97a6                	add	a5,a5,s1
    80004b32:	0187c783          	lbu	a5,24(a5)
    80004b36:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004b3a:	4685                	li	a3,1
    80004b3c:	fbf40613          	addi	a2,s0,-65
    80004b40:	85ca                	mv	a1,s2
    80004b42:	050a3503          	ld	a0,80(s4)
    80004b46:	ffffd097          	auipc	ra,0xffffd
    80004b4a:	b2c080e7          	jalr	-1236(ra) # 80001672 <copyout>
    80004b4e:	01650663          	beq	a0,s6,80004b5a <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004b52:	2985                	addiw	s3,s3,1
    80004b54:	0905                	addi	s2,s2,1
    80004b56:	fd3a91e3          	bne	s5,s3,80004b18 <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004b5a:	21c48513          	addi	a0,s1,540
    80004b5e:	ffffd097          	auipc	ra,0xffffd
    80004b62:	716080e7          	jalr	1814(ra) # 80002274 <wakeup>
  release(&pi->lock);
    80004b66:	8526                	mv	a0,s1
    80004b68:	ffffc097          	auipc	ra,0xffffc
    80004b6c:	130080e7          	jalr	304(ra) # 80000c98 <release>
  return i;
}
    80004b70:	854e                	mv	a0,s3
    80004b72:	60a6                	ld	ra,72(sp)
    80004b74:	6406                	ld	s0,64(sp)
    80004b76:	74e2                	ld	s1,56(sp)
    80004b78:	7942                	ld	s2,48(sp)
    80004b7a:	79a2                	ld	s3,40(sp)
    80004b7c:	7a02                	ld	s4,32(sp)
    80004b7e:	6ae2                	ld	s5,24(sp)
    80004b80:	6b42                	ld	s6,16(sp)
    80004b82:	6161                	addi	sp,sp,80
    80004b84:	8082                	ret
      release(&pi->lock);
    80004b86:	8526                	mv	a0,s1
    80004b88:	ffffc097          	auipc	ra,0xffffc
    80004b8c:	110080e7          	jalr	272(ra) # 80000c98 <release>
      return -1;
    80004b90:	59fd                	li	s3,-1
    80004b92:	bff9                	j	80004b70 <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004b94:	4981                	li	s3,0
    80004b96:	b7d1                	j	80004b5a <piperead+0xae>

0000000080004b98 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004b98:	df010113          	addi	sp,sp,-528
    80004b9c:	20113423          	sd	ra,520(sp)
    80004ba0:	20813023          	sd	s0,512(sp)
    80004ba4:	ffa6                	sd	s1,504(sp)
    80004ba6:	fbca                	sd	s2,496(sp)
    80004ba8:	f7ce                	sd	s3,488(sp)
    80004baa:	f3d2                	sd	s4,480(sp)
    80004bac:	efd6                	sd	s5,472(sp)
    80004bae:	ebda                	sd	s6,464(sp)
    80004bb0:	e7de                	sd	s7,456(sp)
    80004bb2:	e3e2                	sd	s8,448(sp)
    80004bb4:	ff66                	sd	s9,440(sp)
    80004bb6:	fb6a                	sd	s10,432(sp)
    80004bb8:	f76e                	sd	s11,424(sp)
    80004bba:	0c00                	addi	s0,sp,528
    80004bbc:	84aa                	mv	s1,a0
    80004bbe:	dea43c23          	sd	a0,-520(s0)
    80004bc2:	e0b43023          	sd	a1,-512(s0)
	uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
	struct elfhdr elf;
	struct inode *ip;
	struct proghdr ph;
	pagetable_t pagetable = 0, oldpagetable;
	struct proc *p = myproc();
    80004bc6:	ffffd097          	auipc	ra,0xffffd
    80004bca:	e66080e7          	jalr	-410(ra) # 80001a2c <myproc>
    80004bce:	892a                	mv	s2,a0

	begin_op();
    80004bd0:	fffff097          	auipc	ra,0xfffff
    80004bd4:	49c080e7          	jalr	1180(ra) # 8000406c <begin_op>

	if((ip = namei(path)) == 0){
    80004bd8:	8526                	mv	a0,s1
    80004bda:	fffff097          	auipc	ra,0xfffff
    80004bde:	276080e7          	jalr	630(ra) # 80003e50 <namei>
    80004be2:	c92d                	beqz	a0,80004c54 <exec+0xbc>
    80004be4:	84aa                	mv	s1,a0
		end_op();
		return -1;
	}
	ilock(ip);
    80004be6:	fffff097          	auipc	ra,0xfffff
    80004bea:	ab4080e7          	jalr	-1356(ra) # 8000369a <ilock>

	// Check ELF header
	if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004bee:	04000713          	li	a4,64
    80004bf2:	4681                	li	a3,0
    80004bf4:	e5040613          	addi	a2,s0,-432
    80004bf8:	4581                	li	a1,0
    80004bfa:	8526                	mv	a0,s1
    80004bfc:	fffff097          	auipc	ra,0xfffff
    80004c00:	d52080e7          	jalr	-686(ra) # 8000394e <readi>
    80004c04:	04000793          	li	a5,64
    80004c08:	00f51a63          	bne	a0,a5,80004c1c <exec+0x84>
		goto bad;
	if(elf.magic != ELF_MAGIC)
    80004c0c:	e5042703          	lw	a4,-432(s0)
    80004c10:	464c47b7          	lui	a5,0x464c4
    80004c14:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004c18:	04f70463          	beq	a4,a5,80004c60 <exec+0xc8>

bad:
	if(pagetable)
		proc_freepagetable(pagetable, sz);
	if(ip){
		iunlockput(ip);
    80004c1c:	8526                	mv	a0,s1
    80004c1e:	fffff097          	auipc	ra,0xfffff
    80004c22:	cde080e7          	jalr	-802(ra) # 800038fc <iunlockput>
		end_op();
    80004c26:	fffff097          	auipc	ra,0xfffff
    80004c2a:	4c6080e7          	jalr	1222(ra) # 800040ec <end_op>
	}
	return -1;
    80004c2e:	557d                	li	a0,-1
}
    80004c30:	20813083          	ld	ra,520(sp)
    80004c34:	20013403          	ld	s0,512(sp)
    80004c38:	74fe                	ld	s1,504(sp)
    80004c3a:	795e                	ld	s2,496(sp)
    80004c3c:	79be                	ld	s3,488(sp)
    80004c3e:	7a1e                	ld	s4,480(sp)
    80004c40:	6afe                	ld	s5,472(sp)
    80004c42:	6b5e                	ld	s6,464(sp)
    80004c44:	6bbe                	ld	s7,456(sp)
    80004c46:	6c1e                	ld	s8,448(sp)
    80004c48:	7cfa                	ld	s9,440(sp)
    80004c4a:	7d5a                	ld	s10,432(sp)
    80004c4c:	7dba                	ld	s11,424(sp)
    80004c4e:	21010113          	addi	sp,sp,528
    80004c52:	8082                	ret
		end_op();
    80004c54:	fffff097          	auipc	ra,0xfffff
    80004c58:	498080e7          	jalr	1176(ra) # 800040ec <end_op>
		return -1;
    80004c5c:	557d                	li	a0,-1
    80004c5e:	bfc9                	j	80004c30 <exec+0x98>
	if((pagetable = proc_pagetable(p)) == 0)
    80004c60:	854a                	mv	a0,s2
    80004c62:	ffffd097          	auipc	ra,0xffffd
    80004c66:	e8e080e7          	jalr	-370(ra) # 80001af0 <proc_pagetable>
    80004c6a:	8baa                	mv	s7,a0
    80004c6c:	d945                	beqz	a0,80004c1c <exec+0x84>
	for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004c6e:	e7042983          	lw	s3,-400(s0)
    80004c72:	e8845783          	lhu	a5,-376(s0)
    80004c76:	c7ad                	beqz	a5,80004ce0 <exec+0x148>
	uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004c78:	4901                	li	s2,0
	for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004c7a:	4b01                	li	s6,0
		if((ph.vaddr % PGSIZE) != 0)
    80004c7c:	6c85                	lui	s9,0x1
    80004c7e:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80004c82:	def43823          	sd	a5,-528(s0)
    80004c86:	a42d                	j	80004eb0 <exec+0x318>
	uint64 pa;

	for(i = 0; i < sz; i += PGSIZE){
		pa = walkaddr(pagetable, va + i);
		if(pa == 0)
			panic("loadseg: address should exist");
    80004c88:	00004517          	auipc	a0,0x4
    80004c8c:	a4850513          	addi	a0,a0,-1464 # 800086d0 <syscalls+0x280>
    80004c90:	ffffc097          	auipc	ra,0xffffc
    80004c94:	8ae080e7          	jalr	-1874(ra) # 8000053e <panic>
		if(sz - i < PGSIZE)
			n = sz - i;
		else
			n = PGSIZE;
		if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004c98:	8756                	mv	a4,s5
    80004c9a:	012d86bb          	addw	a3,s11,s2
    80004c9e:	4581                	li	a1,0
    80004ca0:	8526                	mv	a0,s1
    80004ca2:	fffff097          	auipc	ra,0xfffff
    80004ca6:	cac080e7          	jalr	-852(ra) # 8000394e <readi>
    80004caa:	2501                	sext.w	a0,a0
    80004cac:	1aaa9963          	bne	s5,a0,80004e5e <exec+0x2c6>
	for(i = 0; i < sz; i += PGSIZE){
    80004cb0:	6785                	lui	a5,0x1
    80004cb2:	0127893b          	addw	s2,a5,s2
    80004cb6:	77fd                	lui	a5,0xfffff
    80004cb8:	01478a3b          	addw	s4,a5,s4
    80004cbc:	1f897163          	bgeu	s2,s8,80004e9e <exec+0x306>
		pa = walkaddr(pagetable, va + i);
    80004cc0:	02091593          	slli	a1,s2,0x20
    80004cc4:	9181                	srli	a1,a1,0x20
    80004cc6:	95ea                	add	a1,a1,s10
    80004cc8:	855e                	mv	a0,s7
    80004cca:	ffffc097          	auipc	ra,0xffffc
    80004cce:	3a4080e7          	jalr	932(ra) # 8000106e <walkaddr>
    80004cd2:	862a                	mv	a2,a0
		if(pa == 0)
    80004cd4:	d955                	beqz	a0,80004c88 <exec+0xf0>
			n = PGSIZE;
    80004cd6:	8ae6                	mv	s5,s9
		if(sz - i < PGSIZE)
    80004cd8:	fd9a70e3          	bgeu	s4,s9,80004c98 <exec+0x100>
			n = sz - i;
    80004cdc:	8ad2                	mv	s5,s4
    80004cde:	bf6d                	j	80004c98 <exec+0x100>
	uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004ce0:	4901                	li	s2,0
	iunlockput(ip);
    80004ce2:	8526                	mv	a0,s1
    80004ce4:	fffff097          	auipc	ra,0xfffff
    80004ce8:	c18080e7          	jalr	-1000(ra) # 800038fc <iunlockput>
	end_op();
    80004cec:	fffff097          	auipc	ra,0xfffff
    80004cf0:	400080e7          	jalr	1024(ra) # 800040ec <end_op>
	p = myproc();
    80004cf4:	ffffd097          	auipc	ra,0xffffd
    80004cf8:	d38080e7          	jalr	-712(ra) # 80001a2c <myproc>
    80004cfc:	8aaa                	mv	s5,a0
	uint64 oldsz = p->sz;
    80004cfe:	04853d03          	ld	s10,72(a0)
	sz = PGROUNDUP(sz);
    80004d02:	6785                	lui	a5,0x1
    80004d04:	17fd                	addi	a5,a5,-1
    80004d06:	993e                	add	s2,s2,a5
    80004d08:	757d                	lui	a0,0xfffff
    80004d0a:	00a977b3          	and	a5,s2,a0
    80004d0e:	e0f43423          	sd	a5,-504(s0)
	if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004d12:	6609                	lui	a2,0x2
    80004d14:	963e                	add	a2,a2,a5
    80004d16:	85be                	mv	a1,a5
    80004d18:	855e                	mv	a0,s7
    80004d1a:	ffffc097          	auipc	ra,0xffffc
    80004d1e:	708080e7          	jalr	1800(ra) # 80001422 <uvmalloc>
    80004d22:	8b2a                	mv	s6,a0
	ip = 0;
    80004d24:	4481                	li	s1,0
	if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004d26:	12050c63          	beqz	a0,80004e5e <exec+0x2c6>
	uvmclear(pagetable, sz-2*PGSIZE);
    80004d2a:	75f9                	lui	a1,0xffffe
    80004d2c:	95aa                	add	a1,a1,a0
    80004d2e:	855e                	mv	a0,s7
    80004d30:	ffffd097          	auipc	ra,0xffffd
    80004d34:	910080e7          	jalr	-1776(ra) # 80001640 <uvmclear>
	stackbase = sp - PGSIZE;
    80004d38:	7c7d                	lui	s8,0xfffff
    80004d3a:	9c5a                	add	s8,s8,s6
	for(argc = 0; argv[argc]; argc++) {
    80004d3c:	e0043783          	ld	a5,-512(s0)
    80004d40:	6388                	ld	a0,0(a5)
    80004d42:	c535                	beqz	a0,80004dae <exec+0x216>
    80004d44:	e9040993          	addi	s3,s0,-368
    80004d48:	f9040c93          	addi	s9,s0,-112
	sp = sz;
    80004d4c:	895a                	mv	s2,s6
		sp -= strlen(argv[argc]) + 1;
    80004d4e:	ffffc097          	auipc	ra,0xffffc
    80004d52:	116080e7          	jalr	278(ra) # 80000e64 <strlen>
    80004d56:	2505                	addiw	a0,a0,1
    80004d58:	40a90933          	sub	s2,s2,a0
		sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004d5c:	ff097913          	andi	s2,s2,-16
		if(sp < stackbase)
    80004d60:	13896363          	bltu	s2,s8,80004e86 <exec+0x2ee>
		if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004d64:	e0043d83          	ld	s11,-512(s0)
    80004d68:	000dba03          	ld	s4,0(s11)
    80004d6c:	8552                	mv	a0,s4
    80004d6e:	ffffc097          	auipc	ra,0xffffc
    80004d72:	0f6080e7          	jalr	246(ra) # 80000e64 <strlen>
    80004d76:	0015069b          	addiw	a3,a0,1
    80004d7a:	8652                	mv	a2,s4
    80004d7c:	85ca                	mv	a1,s2
    80004d7e:	855e                	mv	a0,s7
    80004d80:	ffffd097          	auipc	ra,0xffffd
    80004d84:	8f2080e7          	jalr	-1806(ra) # 80001672 <copyout>
    80004d88:	10054363          	bltz	a0,80004e8e <exec+0x2f6>
		ustack[argc] = sp;
    80004d8c:	0129b023          	sd	s2,0(s3)
	for(argc = 0; argv[argc]; argc++) {
    80004d90:	0485                	addi	s1,s1,1
    80004d92:	008d8793          	addi	a5,s11,8
    80004d96:	e0f43023          	sd	a5,-512(s0)
    80004d9a:	008db503          	ld	a0,8(s11)
    80004d9e:	c911                	beqz	a0,80004db2 <exec+0x21a>
		if(argc >= MAXARG)
    80004da0:	09a1                	addi	s3,s3,8
    80004da2:	fb3c96e3          	bne	s9,s3,80004d4e <exec+0x1b6>
	sz = sz1;
    80004da6:	e1643423          	sd	s6,-504(s0)
	ip = 0;
    80004daa:	4481                	li	s1,0
    80004dac:	a84d                	j	80004e5e <exec+0x2c6>
	sp = sz;
    80004dae:	895a                	mv	s2,s6
	for(argc = 0; argv[argc]; argc++) {
    80004db0:	4481                	li	s1,0
	ustack[argc] = 0;
    80004db2:	00349793          	slli	a5,s1,0x3
    80004db6:	f9040713          	addi	a4,s0,-112
    80004dba:	97ba                	add	a5,a5,a4
    80004dbc:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
	sp -= (argc+1) * sizeof(uint64);
    80004dc0:	00148693          	addi	a3,s1,1
    80004dc4:	068e                	slli	a3,a3,0x3
    80004dc6:	40d90933          	sub	s2,s2,a3
	sp -= sp % 16;
    80004dca:	ff097913          	andi	s2,s2,-16
	if(sp < stackbase)
    80004dce:	01897663          	bgeu	s2,s8,80004dda <exec+0x242>
	sz = sz1;
    80004dd2:	e1643423          	sd	s6,-504(s0)
	ip = 0;
    80004dd6:	4481                	li	s1,0
    80004dd8:	a059                	j	80004e5e <exec+0x2c6>
	if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004dda:	e9040613          	addi	a2,s0,-368
    80004dde:	85ca                	mv	a1,s2
    80004de0:	855e                	mv	a0,s7
    80004de2:	ffffd097          	auipc	ra,0xffffd
    80004de6:	890080e7          	jalr	-1904(ra) # 80001672 <copyout>
    80004dea:	0a054663          	bltz	a0,80004e96 <exec+0x2fe>
	p->trapframe->a1 = sp;
    80004dee:	058ab783          	ld	a5,88(s5)
    80004df2:	0727bc23          	sd	s2,120(a5)
	for(last=s=path; *s; s++)
    80004df6:	df843783          	ld	a5,-520(s0)
    80004dfa:	0007c703          	lbu	a4,0(a5)
    80004dfe:	cf11                	beqz	a4,80004e1a <exec+0x282>
    80004e00:	0785                	addi	a5,a5,1
		if(*s == '/')
    80004e02:	02f00693          	li	a3,47
    80004e06:	a039                	j	80004e14 <exec+0x27c>
			last = s+1;
    80004e08:	def43c23          	sd	a5,-520(s0)
	for(last=s=path; *s; s++)
    80004e0c:	0785                	addi	a5,a5,1
    80004e0e:	fff7c703          	lbu	a4,-1(a5)
    80004e12:	c701                	beqz	a4,80004e1a <exec+0x282>
		if(*s == '/')
    80004e14:	fed71ce3          	bne	a4,a3,80004e0c <exec+0x274>
    80004e18:	bfc5                	j	80004e08 <exec+0x270>
	safestrcpy(p->name, last, sizeof(p->name));
    80004e1a:	4641                	li	a2,16
    80004e1c:	df843583          	ld	a1,-520(s0)
    80004e20:	158a8513          	addi	a0,s5,344
    80004e24:	ffffc097          	auipc	ra,0xffffc
    80004e28:	00e080e7          	jalr	14(ra) # 80000e32 <safestrcpy>
	oldpagetable = p->pagetable;
    80004e2c:	050ab503          	ld	a0,80(s5)
	p->pagetable = pagetable;
    80004e30:	057ab823          	sd	s7,80(s5)
	p->sz = sz;
    80004e34:	056ab423          	sd	s6,72(s5)
	p->trapframe->epc = elf.entry;  // initial program counter = main
    80004e38:	058ab783          	ld	a5,88(s5)
    80004e3c:	e6843703          	ld	a4,-408(s0)
    80004e40:	ef98                	sd	a4,24(a5)
	p->trapframe->sp = sp; // initial stack pointer
    80004e42:	058ab783          	ld	a5,88(s5)
    80004e46:	0327b823          	sd	s2,48(a5)
	proc_freepagetable(oldpagetable, oldsz);
    80004e4a:	85ea                	mv	a1,s10
    80004e4c:	ffffd097          	auipc	ra,0xffffd
    80004e50:	d40080e7          	jalr	-704(ra) # 80001b8c <proc_freepagetable>
	return argc; // this ends up in a0, the first argument to main(argc, argv)
    80004e54:	0004851b          	sext.w	a0,s1
    80004e58:	bbe1                	j	80004c30 <exec+0x98>
    80004e5a:	e1243423          	sd	s2,-504(s0)
		proc_freepagetable(pagetable, sz);
    80004e5e:	e0843583          	ld	a1,-504(s0)
    80004e62:	855e                	mv	a0,s7
    80004e64:	ffffd097          	auipc	ra,0xffffd
    80004e68:	d28080e7          	jalr	-728(ra) # 80001b8c <proc_freepagetable>
	if(ip){
    80004e6c:	da0498e3          	bnez	s1,80004c1c <exec+0x84>
	return -1;
    80004e70:	557d                	li	a0,-1
    80004e72:	bb7d                	j	80004c30 <exec+0x98>
    80004e74:	e1243423          	sd	s2,-504(s0)
    80004e78:	b7dd                	j	80004e5e <exec+0x2c6>
    80004e7a:	e1243423          	sd	s2,-504(s0)
    80004e7e:	b7c5                	j	80004e5e <exec+0x2c6>
    80004e80:	e1243423          	sd	s2,-504(s0)
    80004e84:	bfe9                	j	80004e5e <exec+0x2c6>
	sz = sz1;
    80004e86:	e1643423          	sd	s6,-504(s0)
	ip = 0;
    80004e8a:	4481                	li	s1,0
    80004e8c:	bfc9                	j	80004e5e <exec+0x2c6>
	sz = sz1;
    80004e8e:	e1643423          	sd	s6,-504(s0)
	ip = 0;
    80004e92:	4481                	li	s1,0
    80004e94:	b7e9                	j	80004e5e <exec+0x2c6>
	sz = sz1;
    80004e96:	e1643423          	sd	s6,-504(s0)
	ip = 0;
    80004e9a:	4481                	li	s1,0
    80004e9c:	b7c9                	j	80004e5e <exec+0x2c6>
		if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80004e9e:	e0843903          	ld	s2,-504(s0)
	for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004ea2:	2b05                	addiw	s6,s6,1
    80004ea4:	0389899b          	addiw	s3,s3,56
    80004ea8:	e8845783          	lhu	a5,-376(s0)
    80004eac:	e2fb5be3          	bge	s6,a5,80004ce2 <exec+0x14a>
		if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80004eb0:	2981                	sext.w	s3,s3
    80004eb2:	03800713          	li	a4,56
    80004eb6:	86ce                	mv	a3,s3
    80004eb8:	e1840613          	addi	a2,s0,-488
    80004ebc:	4581                	li	a1,0
    80004ebe:	8526                	mv	a0,s1
    80004ec0:	fffff097          	auipc	ra,0xfffff
    80004ec4:	a8e080e7          	jalr	-1394(ra) # 8000394e <readi>
    80004ec8:	03800793          	li	a5,56
    80004ecc:	f8f517e3          	bne	a0,a5,80004e5a <exec+0x2c2>
		if(ph.type != ELF_PROG_LOAD)
    80004ed0:	e1842783          	lw	a5,-488(s0)
    80004ed4:	4705                	li	a4,1
    80004ed6:	fce796e3          	bne	a5,a4,80004ea2 <exec+0x30a>
		if(ph.memsz < ph.filesz)
    80004eda:	e4043603          	ld	a2,-448(s0)
    80004ede:	e3843783          	ld	a5,-456(s0)
    80004ee2:	f8f669e3          	bltu	a2,a5,80004e74 <exec+0x2dc>
		if(ph.vaddr + ph.memsz < ph.vaddr)	// オーバーフロー
    80004ee6:	e2843783          	ld	a5,-472(s0)
    80004eea:	963e                	add	a2,a2,a5
    80004eec:	f8f667e3          	bltu	a2,a5,80004e7a <exec+0x2e2>
		if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80004ef0:	85ca                	mv	a1,s2
    80004ef2:	855e                	mv	a0,s7
    80004ef4:	ffffc097          	auipc	ra,0xffffc
    80004ef8:	52e080e7          	jalr	1326(ra) # 80001422 <uvmalloc>
    80004efc:	e0a43423          	sd	a0,-504(s0)
    80004f00:	d141                	beqz	a0,80004e80 <exec+0x2e8>
		if((ph.vaddr % PGSIZE) != 0)
    80004f02:	e2843d03          	ld	s10,-472(s0)
    80004f06:	df043783          	ld	a5,-528(s0)
    80004f0a:	00fd77b3          	and	a5,s10,a5
    80004f0e:	fba1                	bnez	a5,80004e5e <exec+0x2c6>
		if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80004f10:	e2042d83          	lw	s11,-480(s0)
    80004f14:	e3842c03          	lw	s8,-456(s0)
	for(i = 0; i < sz; i += PGSIZE){
    80004f18:	f80c03e3          	beqz	s8,80004e9e <exec+0x306>
    80004f1c:	8a62                	mv	s4,s8
    80004f1e:	4901                	li	s2,0
    80004f20:	b345                	j	80004cc0 <exec+0x128>

0000000080004f22 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80004f22:	7179                	addi	sp,sp,-48
    80004f24:	f406                	sd	ra,40(sp)
    80004f26:	f022                	sd	s0,32(sp)
    80004f28:	ec26                	sd	s1,24(sp)
    80004f2a:	e84a                	sd	s2,16(sp)
    80004f2c:	1800                	addi	s0,sp,48
    80004f2e:	892e                	mv	s2,a1
    80004f30:	84b2                	mv	s1,a2
	int fd;
	struct file *f;

	if(argint(n, &fd) < 0)
    80004f32:	fdc40593          	addi	a1,s0,-36
    80004f36:	ffffe097          	auipc	ra,0xffffe
    80004f3a:	ba2080e7          	jalr	-1118(ra) # 80002ad8 <argint>
    80004f3e:	04054063          	bltz	a0,80004f7e <argfd+0x5c>
		return -1;
	if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80004f42:	fdc42703          	lw	a4,-36(s0)
    80004f46:	47bd                	li	a5,15
    80004f48:	02e7ed63          	bltu	a5,a4,80004f82 <argfd+0x60>
    80004f4c:	ffffd097          	auipc	ra,0xffffd
    80004f50:	ae0080e7          	jalr	-1312(ra) # 80001a2c <myproc>
    80004f54:	fdc42703          	lw	a4,-36(s0)
    80004f58:	01a70793          	addi	a5,a4,26
    80004f5c:	078e                	slli	a5,a5,0x3
    80004f5e:	953e                	add	a0,a0,a5
    80004f60:	611c                	ld	a5,0(a0)
    80004f62:	c395                	beqz	a5,80004f86 <argfd+0x64>
		return -1;
	if(pfd)
    80004f64:	00090463          	beqz	s2,80004f6c <argfd+0x4a>
		*pfd = fd;
    80004f68:	00e92023          	sw	a4,0(s2)
	if(pf)
		*pf = f;
	return 0;
    80004f6c:	4501                	li	a0,0
	if(pf)
    80004f6e:	c091                	beqz	s1,80004f72 <argfd+0x50>
		*pf = f;
    80004f70:	e09c                	sd	a5,0(s1)
}
    80004f72:	70a2                	ld	ra,40(sp)
    80004f74:	7402                	ld	s0,32(sp)
    80004f76:	64e2                	ld	s1,24(sp)
    80004f78:	6942                	ld	s2,16(sp)
    80004f7a:	6145                	addi	sp,sp,48
    80004f7c:	8082                	ret
		return -1;
    80004f7e:	557d                	li	a0,-1
    80004f80:	bfcd                	j	80004f72 <argfd+0x50>
		return -1;
    80004f82:	557d                	li	a0,-1
    80004f84:	b7fd                	j	80004f72 <argfd+0x50>
    80004f86:	557d                	li	a0,-1
    80004f88:	b7ed                	j	80004f72 <argfd+0x50>

0000000080004f8a <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80004f8a:	1101                	addi	sp,sp,-32
    80004f8c:	ec06                	sd	ra,24(sp)
    80004f8e:	e822                	sd	s0,16(sp)
    80004f90:	e426                	sd	s1,8(sp)
    80004f92:	1000                	addi	s0,sp,32
    80004f94:	84aa                	mv	s1,a0
	int fd;
	struct proc *p = myproc();
    80004f96:	ffffd097          	auipc	ra,0xffffd
    80004f9a:	a96080e7          	jalr	-1386(ra) # 80001a2c <myproc>
    80004f9e:	862a                	mv	a2,a0

	for(fd = 0; fd < NOFILE; fd++){
    80004fa0:	0d050793          	addi	a5,a0,208 # fffffffffffff0d0 <end+0xffffffff7ffd90d0>
    80004fa4:	4501                	li	a0,0
    80004fa6:	46c1                	li	a3,16
		if(p->ofile[fd] == 0){
    80004fa8:	6398                	ld	a4,0(a5)
    80004faa:	cb19                	beqz	a4,80004fc0 <fdalloc+0x36>
	for(fd = 0; fd < NOFILE; fd++){
    80004fac:	2505                	addiw	a0,a0,1
    80004fae:	07a1                	addi	a5,a5,8
    80004fb0:	fed51ce3          	bne	a0,a3,80004fa8 <fdalloc+0x1e>
			p->ofile[fd] = f;
			return fd;
		}
	}
	return -1;
    80004fb4:	557d                	li	a0,-1
}
    80004fb6:	60e2                	ld	ra,24(sp)
    80004fb8:	6442                	ld	s0,16(sp)
    80004fba:	64a2                	ld	s1,8(sp)
    80004fbc:	6105                	addi	sp,sp,32
    80004fbe:	8082                	ret
			p->ofile[fd] = f;
    80004fc0:	01a50793          	addi	a5,a0,26
    80004fc4:	078e                	slli	a5,a5,0x3
    80004fc6:	963e                	add	a2,a2,a5
    80004fc8:	e204                	sd	s1,0(a2)
			return fd;
    80004fca:	b7f5                	j	80004fb6 <fdalloc+0x2c>

0000000080004fcc <create>:
	return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80004fcc:	715d                	addi	sp,sp,-80
    80004fce:	e486                	sd	ra,72(sp)
    80004fd0:	e0a2                	sd	s0,64(sp)
    80004fd2:	fc26                	sd	s1,56(sp)
    80004fd4:	f84a                	sd	s2,48(sp)
    80004fd6:	f44e                	sd	s3,40(sp)
    80004fd8:	f052                	sd	s4,32(sp)
    80004fda:	ec56                	sd	s5,24(sp)
    80004fdc:	0880                	addi	s0,sp,80
    80004fde:	89ae                	mv	s3,a1
    80004fe0:	8ab2                	mv	s5,a2
    80004fe2:	8a36                	mv	s4,a3
	struct inode *ip, *dp;
	char name[DIRSIZ];

	if((dp = nameiparent(path, name)) == 0)
    80004fe4:	fb040593          	addi	a1,s0,-80
    80004fe8:	fffff097          	auipc	ra,0xfffff
    80004fec:	e86080e7          	jalr	-378(ra) # 80003e6e <nameiparent>
    80004ff0:	892a                	mv	s2,a0
    80004ff2:	12050f63          	beqz	a0,80005130 <create+0x164>
		return 0;

	ilock(dp);
    80004ff6:	ffffe097          	auipc	ra,0xffffe
    80004ffa:	6a4080e7          	jalr	1700(ra) # 8000369a <ilock>

	if((ip = dirlookup(dp, name, 0)) != 0){
    80004ffe:	4601                	li	a2,0
    80005000:	fb040593          	addi	a1,s0,-80
    80005004:	854a                	mv	a0,s2
    80005006:	fffff097          	auipc	ra,0xfffff
    8000500a:	b78080e7          	jalr	-1160(ra) # 80003b7e <dirlookup>
    8000500e:	84aa                	mv	s1,a0
    80005010:	c921                	beqz	a0,80005060 <create+0x94>
		iunlockput(dp);
    80005012:	854a                	mv	a0,s2
    80005014:	fffff097          	auipc	ra,0xfffff
    80005018:	8e8080e7          	jalr	-1816(ra) # 800038fc <iunlockput>
		ilock(ip);
    8000501c:	8526                	mv	a0,s1
    8000501e:	ffffe097          	auipc	ra,0xffffe
    80005022:	67c080e7          	jalr	1660(ra) # 8000369a <ilock>
		if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005026:	2981                	sext.w	s3,s3
    80005028:	4789                	li	a5,2
    8000502a:	02f99463          	bne	s3,a5,80005052 <create+0x86>
    8000502e:	0444d783          	lhu	a5,68(s1)
    80005032:	37f9                	addiw	a5,a5,-2
    80005034:	17c2                	slli	a5,a5,0x30
    80005036:	93c1                	srli	a5,a5,0x30
    80005038:	4705                	li	a4,1
    8000503a:	00f76c63          	bltu	a4,a5,80005052 <create+0x86>
		panic("create: dirlink");

	iunlockput(dp);

	return ip;
}
    8000503e:	8526                	mv	a0,s1
    80005040:	60a6                	ld	ra,72(sp)
    80005042:	6406                	ld	s0,64(sp)
    80005044:	74e2                	ld	s1,56(sp)
    80005046:	7942                	ld	s2,48(sp)
    80005048:	79a2                	ld	s3,40(sp)
    8000504a:	7a02                	ld	s4,32(sp)
    8000504c:	6ae2                	ld	s5,24(sp)
    8000504e:	6161                	addi	sp,sp,80
    80005050:	8082                	ret
		iunlockput(ip);
    80005052:	8526                	mv	a0,s1
    80005054:	fffff097          	auipc	ra,0xfffff
    80005058:	8a8080e7          	jalr	-1880(ra) # 800038fc <iunlockput>
		return 0;
    8000505c:	4481                	li	s1,0
    8000505e:	b7c5                	j	8000503e <create+0x72>
	if((ip = ialloc(dp->dev, type)) == 0)
    80005060:	85ce                	mv	a1,s3
    80005062:	00092503          	lw	a0,0(s2)
    80005066:	ffffe097          	auipc	ra,0xffffe
    8000506a:	49c080e7          	jalr	1180(ra) # 80003502 <ialloc>
    8000506e:	84aa                	mv	s1,a0
    80005070:	c529                	beqz	a0,800050ba <create+0xee>
	ilock(ip);
    80005072:	ffffe097          	auipc	ra,0xffffe
    80005076:	628080e7          	jalr	1576(ra) # 8000369a <ilock>
	ip->major = major;
    8000507a:	05549323          	sh	s5,70(s1)
	ip->minor = minor;
    8000507e:	05449423          	sh	s4,72(s1)
	ip->nlink = 1;
    80005082:	4785                	li	a5,1
    80005084:	04f49523          	sh	a5,74(s1)
	iupdate(ip);
    80005088:	8526                	mv	a0,s1
    8000508a:	ffffe097          	auipc	ra,0xffffe
    8000508e:	546080e7          	jalr	1350(ra) # 800035d0 <iupdate>
	if(type == T_DIR){  // Create . and .. entries.
    80005092:	2981                	sext.w	s3,s3
    80005094:	4785                	li	a5,1
    80005096:	02f98a63          	beq	s3,a5,800050ca <create+0xfe>
	if(dirlink(dp, name, ip->inum) < 0)
    8000509a:	40d0                	lw	a2,4(s1)
    8000509c:	fb040593          	addi	a1,s0,-80
    800050a0:	854a                	mv	a0,s2
    800050a2:	fffff097          	auipc	ra,0xfffff
    800050a6:	cec080e7          	jalr	-788(ra) # 80003d8e <dirlink>
    800050aa:	06054b63          	bltz	a0,80005120 <create+0x154>
	iunlockput(dp);
    800050ae:	854a                	mv	a0,s2
    800050b0:	fffff097          	auipc	ra,0xfffff
    800050b4:	84c080e7          	jalr	-1972(ra) # 800038fc <iunlockput>
	return ip;
    800050b8:	b759                	j	8000503e <create+0x72>
		panic("create: ialloc");
    800050ba:	00003517          	auipc	a0,0x3
    800050be:	63650513          	addi	a0,a0,1590 # 800086f0 <syscalls+0x2a0>
    800050c2:	ffffb097          	auipc	ra,0xffffb
    800050c6:	47c080e7          	jalr	1148(ra) # 8000053e <panic>
		dp->nlink++;  // for ".."
    800050ca:	04a95783          	lhu	a5,74(s2)
    800050ce:	2785                	addiw	a5,a5,1
    800050d0:	04f91523          	sh	a5,74(s2)
		iupdate(dp);
    800050d4:	854a                	mv	a0,s2
    800050d6:	ffffe097          	auipc	ra,0xffffe
    800050da:	4fa080e7          	jalr	1274(ra) # 800035d0 <iupdate>
		if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    800050de:	40d0                	lw	a2,4(s1)
    800050e0:	00003597          	auipc	a1,0x3
    800050e4:	62058593          	addi	a1,a1,1568 # 80008700 <syscalls+0x2b0>
    800050e8:	8526                	mv	a0,s1
    800050ea:	fffff097          	auipc	ra,0xfffff
    800050ee:	ca4080e7          	jalr	-860(ra) # 80003d8e <dirlink>
    800050f2:	00054f63          	bltz	a0,80005110 <create+0x144>
    800050f6:	00492603          	lw	a2,4(s2)
    800050fa:	00003597          	auipc	a1,0x3
    800050fe:	60e58593          	addi	a1,a1,1550 # 80008708 <syscalls+0x2b8>
    80005102:	8526                	mv	a0,s1
    80005104:	fffff097          	auipc	ra,0xfffff
    80005108:	c8a080e7          	jalr	-886(ra) # 80003d8e <dirlink>
    8000510c:	f80557e3          	bgez	a0,8000509a <create+0xce>
			panic("create dots");
    80005110:	00003517          	auipc	a0,0x3
    80005114:	60050513          	addi	a0,a0,1536 # 80008710 <syscalls+0x2c0>
    80005118:	ffffb097          	auipc	ra,0xffffb
    8000511c:	426080e7          	jalr	1062(ra) # 8000053e <panic>
		panic("create: dirlink");
    80005120:	00003517          	auipc	a0,0x3
    80005124:	60050513          	addi	a0,a0,1536 # 80008720 <syscalls+0x2d0>
    80005128:	ffffb097          	auipc	ra,0xffffb
    8000512c:	416080e7          	jalr	1046(ra) # 8000053e <panic>
		return 0;
    80005130:	84aa                	mv	s1,a0
    80005132:	b731                	j	8000503e <create+0x72>

0000000080005134 <sys_dup>:
{
    80005134:	7179                	addi	sp,sp,-48
    80005136:	f406                	sd	ra,40(sp)
    80005138:	f022                	sd	s0,32(sp)
    8000513a:	ec26                	sd	s1,24(sp)
    8000513c:	1800                	addi	s0,sp,48
	if(argfd(0, 0, &f) < 0)
    8000513e:	fd840613          	addi	a2,s0,-40
    80005142:	4581                	li	a1,0
    80005144:	4501                	li	a0,0
    80005146:	00000097          	auipc	ra,0x0
    8000514a:	ddc080e7          	jalr	-548(ra) # 80004f22 <argfd>
		return -1;
    8000514e:	57fd                	li	a5,-1
	if(argfd(0, 0, &f) < 0)
    80005150:	02054363          	bltz	a0,80005176 <sys_dup+0x42>
	if((fd=fdalloc(f)) < 0)
    80005154:	fd843503          	ld	a0,-40(s0)
    80005158:	00000097          	auipc	ra,0x0
    8000515c:	e32080e7          	jalr	-462(ra) # 80004f8a <fdalloc>
    80005160:	84aa                	mv	s1,a0
		return -1;
    80005162:	57fd                	li	a5,-1
	if((fd=fdalloc(f)) < 0)
    80005164:	00054963          	bltz	a0,80005176 <sys_dup+0x42>
	filedup(f);
    80005168:	fd843503          	ld	a0,-40(s0)
    8000516c:	fffff097          	auipc	ra,0xfffff
    80005170:	37a080e7          	jalr	890(ra) # 800044e6 <filedup>
	return fd;
    80005174:	87a6                	mv	a5,s1
}
    80005176:	853e                	mv	a0,a5
    80005178:	70a2                	ld	ra,40(sp)
    8000517a:	7402                	ld	s0,32(sp)
    8000517c:	64e2                	ld	s1,24(sp)
    8000517e:	6145                	addi	sp,sp,48
    80005180:	8082                	ret

0000000080005182 <sys_read>:
{
    80005182:	7179                	addi	sp,sp,-48
    80005184:	f406                	sd	ra,40(sp)
    80005186:	f022                	sd	s0,32(sp)
    80005188:	1800                	addi	s0,sp,48
	if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000518a:	fe840613          	addi	a2,s0,-24
    8000518e:	4581                	li	a1,0
    80005190:	4501                	li	a0,0
    80005192:	00000097          	auipc	ra,0x0
    80005196:	d90080e7          	jalr	-624(ra) # 80004f22 <argfd>
		return -1;
    8000519a:	57fd                	li	a5,-1
	if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000519c:	04054163          	bltz	a0,800051de <sys_read+0x5c>
    800051a0:	fe440593          	addi	a1,s0,-28
    800051a4:	4509                	li	a0,2
    800051a6:	ffffe097          	auipc	ra,0xffffe
    800051aa:	932080e7          	jalr	-1742(ra) # 80002ad8 <argint>
		return -1;
    800051ae:	57fd                	li	a5,-1
	if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800051b0:	02054763          	bltz	a0,800051de <sys_read+0x5c>
    800051b4:	fd840593          	addi	a1,s0,-40
    800051b8:	4505                	li	a0,1
    800051ba:	ffffe097          	auipc	ra,0xffffe
    800051be:	940080e7          	jalr	-1728(ra) # 80002afa <argaddr>
		return -1;
    800051c2:	57fd                	li	a5,-1
	if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800051c4:	00054d63          	bltz	a0,800051de <sys_read+0x5c>
	return fileread(f, p, n);
    800051c8:	fe442603          	lw	a2,-28(s0)
    800051cc:	fd843583          	ld	a1,-40(s0)
    800051d0:	fe843503          	ld	a0,-24(s0)
    800051d4:	fffff097          	auipc	ra,0xfffff
    800051d8:	49e080e7          	jalr	1182(ra) # 80004672 <fileread>
    800051dc:	87aa                	mv	a5,a0
}
    800051de:	853e                	mv	a0,a5
    800051e0:	70a2                	ld	ra,40(sp)
    800051e2:	7402                	ld	s0,32(sp)
    800051e4:	6145                	addi	sp,sp,48
    800051e6:	8082                	ret

00000000800051e8 <sys_write>:
{
    800051e8:	7179                	addi	sp,sp,-48
    800051ea:	f406                	sd	ra,40(sp)
    800051ec:	f022                	sd	s0,32(sp)
    800051ee:	1800                	addi	s0,sp,48
	if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800051f0:	fe840613          	addi	a2,s0,-24
    800051f4:	4581                	li	a1,0
    800051f6:	4501                	li	a0,0
    800051f8:	00000097          	auipc	ra,0x0
    800051fc:	d2a080e7          	jalr	-726(ra) # 80004f22 <argfd>
		return -1;
    80005200:	57fd                	li	a5,-1
	if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005202:	04054163          	bltz	a0,80005244 <sys_write+0x5c>
    80005206:	fe440593          	addi	a1,s0,-28
    8000520a:	4509                	li	a0,2
    8000520c:	ffffe097          	auipc	ra,0xffffe
    80005210:	8cc080e7          	jalr	-1844(ra) # 80002ad8 <argint>
		return -1;
    80005214:	57fd                	li	a5,-1
	if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005216:	02054763          	bltz	a0,80005244 <sys_write+0x5c>
    8000521a:	fd840593          	addi	a1,s0,-40
    8000521e:	4505                	li	a0,1
    80005220:	ffffe097          	auipc	ra,0xffffe
    80005224:	8da080e7          	jalr	-1830(ra) # 80002afa <argaddr>
		return -1;
    80005228:	57fd                	li	a5,-1
	if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000522a:	00054d63          	bltz	a0,80005244 <sys_write+0x5c>
	return filewrite(f, p, n);
    8000522e:	fe442603          	lw	a2,-28(s0)
    80005232:	fd843583          	ld	a1,-40(s0)
    80005236:	fe843503          	ld	a0,-24(s0)
    8000523a:	fffff097          	auipc	ra,0xfffff
    8000523e:	4fa080e7          	jalr	1274(ra) # 80004734 <filewrite>
    80005242:	87aa                	mv	a5,a0
}
    80005244:	853e                	mv	a0,a5
    80005246:	70a2                	ld	ra,40(sp)
    80005248:	7402                	ld	s0,32(sp)
    8000524a:	6145                	addi	sp,sp,48
    8000524c:	8082                	ret

000000008000524e <sys_close>:
{
    8000524e:	1101                	addi	sp,sp,-32
    80005250:	ec06                	sd	ra,24(sp)
    80005252:	e822                	sd	s0,16(sp)
    80005254:	1000                	addi	s0,sp,32
	if(argfd(0, &fd, &f) < 0)
    80005256:	fe040613          	addi	a2,s0,-32
    8000525a:	fec40593          	addi	a1,s0,-20
    8000525e:	4501                	li	a0,0
    80005260:	00000097          	auipc	ra,0x0
    80005264:	cc2080e7          	jalr	-830(ra) # 80004f22 <argfd>
		return -1;
    80005268:	57fd                	li	a5,-1
	if(argfd(0, &fd, &f) < 0)
    8000526a:	02054463          	bltz	a0,80005292 <sys_close+0x44>
	myproc()->ofile[fd] = 0;
    8000526e:	ffffc097          	auipc	ra,0xffffc
    80005272:	7be080e7          	jalr	1982(ra) # 80001a2c <myproc>
    80005276:	fec42783          	lw	a5,-20(s0)
    8000527a:	07e9                	addi	a5,a5,26
    8000527c:	078e                	slli	a5,a5,0x3
    8000527e:	97aa                	add	a5,a5,a0
    80005280:	0007b023          	sd	zero,0(a5)
	fileclose(f);
    80005284:	fe043503          	ld	a0,-32(s0)
    80005288:	fffff097          	auipc	ra,0xfffff
    8000528c:	2b0080e7          	jalr	688(ra) # 80004538 <fileclose>
	return 0;
    80005290:	4781                	li	a5,0
}
    80005292:	853e                	mv	a0,a5
    80005294:	60e2                	ld	ra,24(sp)
    80005296:	6442                	ld	s0,16(sp)
    80005298:	6105                	addi	sp,sp,32
    8000529a:	8082                	ret

000000008000529c <sys_fstat>:
{
    8000529c:	1101                	addi	sp,sp,-32
    8000529e:	ec06                	sd	ra,24(sp)
    800052a0:	e822                	sd	s0,16(sp)
    800052a2:	1000                	addi	s0,sp,32
	if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800052a4:	fe840613          	addi	a2,s0,-24
    800052a8:	4581                	li	a1,0
    800052aa:	4501                	li	a0,0
    800052ac:	00000097          	auipc	ra,0x0
    800052b0:	c76080e7          	jalr	-906(ra) # 80004f22 <argfd>
		return -1;
    800052b4:	57fd                	li	a5,-1
	if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800052b6:	02054563          	bltz	a0,800052e0 <sys_fstat+0x44>
    800052ba:	fe040593          	addi	a1,s0,-32
    800052be:	4505                	li	a0,1
    800052c0:	ffffe097          	auipc	ra,0xffffe
    800052c4:	83a080e7          	jalr	-1990(ra) # 80002afa <argaddr>
		return -1;
    800052c8:	57fd                	li	a5,-1
	if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800052ca:	00054b63          	bltz	a0,800052e0 <sys_fstat+0x44>
	return filestat(f, st);
    800052ce:	fe043583          	ld	a1,-32(s0)
    800052d2:	fe843503          	ld	a0,-24(s0)
    800052d6:	fffff097          	auipc	ra,0xfffff
    800052da:	32a080e7          	jalr	810(ra) # 80004600 <filestat>
    800052de:	87aa                	mv	a5,a0
}
    800052e0:	853e                	mv	a0,a5
    800052e2:	60e2                	ld	ra,24(sp)
    800052e4:	6442                	ld	s0,16(sp)
    800052e6:	6105                	addi	sp,sp,32
    800052e8:	8082                	ret

00000000800052ea <sys_link>:
{
    800052ea:	7169                	addi	sp,sp,-304
    800052ec:	f606                	sd	ra,296(sp)
    800052ee:	f222                	sd	s0,288(sp)
    800052f0:	ee26                	sd	s1,280(sp)
    800052f2:	ea4a                	sd	s2,272(sp)
    800052f4:	1a00                	addi	s0,sp,304
	if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800052f6:	08000613          	li	a2,128
    800052fa:	ed040593          	addi	a1,s0,-304
    800052fe:	4501                	li	a0,0
    80005300:	ffffe097          	auipc	ra,0xffffe
    80005304:	81c080e7          	jalr	-2020(ra) # 80002b1c <argstr>
		return -1;
    80005308:	57fd                	li	a5,-1
	if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000530a:	10054e63          	bltz	a0,80005426 <sys_link+0x13c>
    8000530e:	08000613          	li	a2,128
    80005312:	f5040593          	addi	a1,s0,-176
    80005316:	4505                	li	a0,1
    80005318:	ffffe097          	auipc	ra,0xffffe
    8000531c:	804080e7          	jalr	-2044(ra) # 80002b1c <argstr>
		return -1;
    80005320:	57fd                	li	a5,-1
	if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005322:	10054263          	bltz	a0,80005426 <sys_link+0x13c>
	begin_op();
    80005326:	fffff097          	auipc	ra,0xfffff
    8000532a:	d46080e7          	jalr	-698(ra) # 8000406c <begin_op>
	if((ip = namei(old)) == 0){
    8000532e:	ed040513          	addi	a0,s0,-304
    80005332:	fffff097          	auipc	ra,0xfffff
    80005336:	b1e080e7          	jalr	-1250(ra) # 80003e50 <namei>
    8000533a:	84aa                	mv	s1,a0
    8000533c:	c551                	beqz	a0,800053c8 <sys_link+0xde>
	ilock(ip);
    8000533e:	ffffe097          	auipc	ra,0xffffe
    80005342:	35c080e7          	jalr	860(ra) # 8000369a <ilock>
	if(ip->type == T_DIR){
    80005346:	04449703          	lh	a4,68(s1)
    8000534a:	4785                	li	a5,1
    8000534c:	08f70463          	beq	a4,a5,800053d4 <sys_link+0xea>
	ip->nlink++;
    80005350:	04a4d783          	lhu	a5,74(s1)
    80005354:	2785                	addiw	a5,a5,1
    80005356:	04f49523          	sh	a5,74(s1)
	iupdate(ip);
    8000535a:	8526                	mv	a0,s1
    8000535c:	ffffe097          	auipc	ra,0xffffe
    80005360:	274080e7          	jalr	628(ra) # 800035d0 <iupdate>
	iunlock(ip);
    80005364:	8526                	mv	a0,s1
    80005366:	ffffe097          	auipc	ra,0xffffe
    8000536a:	3f6080e7          	jalr	1014(ra) # 8000375c <iunlock>
	if((dp = nameiparent(new, name)) == 0)
    8000536e:	fd040593          	addi	a1,s0,-48
    80005372:	f5040513          	addi	a0,s0,-176
    80005376:	fffff097          	auipc	ra,0xfffff
    8000537a:	af8080e7          	jalr	-1288(ra) # 80003e6e <nameiparent>
    8000537e:	892a                	mv	s2,a0
    80005380:	c935                	beqz	a0,800053f4 <sys_link+0x10a>
	ilock(dp);
    80005382:	ffffe097          	auipc	ra,0xffffe
    80005386:	318080e7          	jalr	792(ra) # 8000369a <ilock>
	if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    8000538a:	00092703          	lw	a4,0(s2)
    8000538e:	409c                	lw	a5,0(s1)
    80005390:	04f71d63          	bne	a4,a5,800053ea <sys_link+0x100>
    80005394:	40d0                	lw	a2,4(s1)
    80005396:	fd040593          	addi	a1,s0,-48
    8000539a:	854a                	mv	a0,s2
    8000539c:	fffff097          	auipc	ra,0xfffff
    800053a0:	9f2080e7          	jalr	-1550(ra) # 80003d8e <dirlink>
    800053a4:	04054363          	bltz	a0,800053ea <sys_link+0x100>
	iunlockput(dp);
    800053a8:	854a                	mv	a0,s2
    800053aa:	ffffe097          	auipc	ra,0xffffe
    800053ae:	552080e7          	jalr	1362(ra) # 800038fc <iunlockput>
	iput(ip);
    800053b2:	8526                	mv	a0,s1
    800053b4:	ffffe097          	auipc	ra,0xffffe
    800053b8:	4a0080e7          	jalr	1184(ra) # 80003854 <iput>
	end_op();
    800053bc:	fffff097          	auipc	ra,0xfffff
    800053c0:	d30080e7          	jalr	-720(ra) # 800040ec <end_op>
	return 0;
    800053c4:	4781                	li	a5,0
    800053c6:	a085                	j	80005426 <sys_link+0x13c>
		end_op();
    800053c8:	fffff097          	auipc	ra,0xfffff
    800053cc:	d24080e7          	jalr	-732(ra) # 800040ec <end_op>
		return -1;
    800053d0:	57fd                	li	a5,-1
    800053d2:	a891                	j	80005426 <sys_link+0x13c>
		iunlockput(ip);
    800053d4:	8526                	mv	a0,s1
    800053d6:	ffffe097          	auipc	ra,0xffffe
    800053da:	526080e7          	jalr	1318(ra) # 800038fc <iunlockput>
		end_op();
    800053de:	fffff097          	auipc	ra,0xfffff
    800053e2:	d0e080e7          	jalr	-754(ra) # 800040ec <end_op>
		return -1;
    800053e6:	57fd                	li	a5,-1
    800053e8:	a83d                	j	80005426 <sys_link+0x13c>
		iunlockput(dp);
    800053ea:	854a                	mv	a0,s2
    800053ec:	ffffe097          	auipc	ra,0xffffe
    800053f0:	510080e7          	jalr	1296(ra) # 800038fc <iunlockput>
	ilock(ip);
    800053f4:	8526                	mv	a0,s1
    800053f6:	ffffe097          	auipc	ra,0xffffe
    800053fa:	2a4080e7          	jalr	676(ra) # 8000369a <ilock>
	ip->nlink--;
    800053fe:	04a4d783          	lhu	a5,74(s1)
    80005402:	37fd                	addiw	a5,a5,-1
    80005404:	04f49523          	sh	a5,74(s1)
	iupdate(ip);
    80005408:	8526                	mv	a0,s1
    8000540a:	ffffe097          	auipc	ra,0xffffe
    8000540e:	1c6080e7          	jalr	454(ra) # 800035d0 <iupdate>
	iunlockput(ip);
    80005412:	8526                	mv	a0,s1
    80005414:	ffffe097          	auipc	ra,0xffffe
    80005418:	4e8080e7          	jalr	1256(ra) # 800038fc <iunlockput>
	end_op();
    8000541c:	fffff097          	auipc	ra,0xfffff
    80005420:	cd0080e7          	jalr	-816(ra) # 800040ec <end_op>
	return -1;
    80005424:	57fd                	li	a5,-1
}
    80005426:	853e                	mv	a0,a5
    80005428:	70b2                	ld	ra,296(sp)
    8000542a:	7412                	ld	s0,288(sp)
    8000542c:	64f2                	ld	s1,280(sp)
    8000542e:	6952                	ld	s2,272(sp)
    80005430:	6155                	addi	sp,sp,304
    80005432:	8082                	ret

0000000080005434 <sys_unlink>:
{
    80005434:	7151                	addi	sp,sp,-240
    80005436:	f586                	sd	ra,232(sp)
    80005438:	f1a2                	sd	s0,224(sp)
    8000543a:	eda6                	sd	s1,216(sp)
    8000543c:	e9ca                	sd	s2,208(sp)
    8000543e:	e5ce                	sd	s3,200(sp)
    80005440:	1980                	addi	s0,sp,240
	if(argstr(0, path, MAXPATH) < 0)
    80005442:	08000613          	li	a2,128
    80005446:	f3040593          	addi	a1,s0,-208
    8000544a:	4501                	li	a0,0
    8000544c:	ffffd097          	auipc	ra,0xffffd
    80005450:	6d0080e7          	jalr	1744(ra) # 80002b1c <argstr>
    80005454:	18054163          	bltz	a0,800055d6 <sys_unlink+0x1a2>
	begin_op();
    80005458:	fffff097          	auipc	ra,0xfffff
    8000545c:	c14080e7          	jalr	-1004(ra) # 8000406c <begin_op>
	if((dp = nameiparent(path, name)) == 0){
    80005460:	fb040593          	addi	a1,s0,-80
    80005464:	f3040513          	addi	a0,s0,-208
    80005468:	fffff097          	auipc	ra,0xfffff
    8000546c:	a06080e7          	jalr	-1530(ra) # 80003e6e <nameiparent>
    80005470:	84aa                	mv	s1,a0
    80005472:	c979                	beqz	a0,80005548 <sys_unlink+0x114>
	ilock(dp);
    80005474:	ffffe097          	auipc	ra,0xffffe
    80005478:	226080e7          	jalr	550(ra) # 8000369a <ilock>
	if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    8000547c:	00003597          	auipc	a1,0x3
    80005480:	28458593          	addi	a1,a1,644 # 80008700 <syscalls+0x2b0>
    80005484:	fb040513          	addi	a0,s0,-80
    80005488:	ffffe097          	auipc	ra,0xffffe
    8000548c:	6dc080e7          	jalr	1756(ra) # 80003b64 <namecmp>
    80005490:	14050a63          	beqz	a0,800055e4 <sys_unlink+0x1b0>
    80005494:	00003597          	auipc	a1,0x3
    80005498:	27458593          	addi	a1,a1,628 # 80008708 <syscalls+0x2b8>
    8000549c:	fb040513          	addi	a0,s0,-80
    800054a0:	ffffe097          	auipc	ra,0xffffe
    800054a4:	6c4080e7          	jalr	1732(ra) # 80003b64 <namecmp>
    800054a8:	12050e63          	beqz	a0,800055e4 <sys_unlink+0x1b0>
	if((ip = dirlookup(dp, name, &off)) == 0)
    800054ac:	f2c40613          	addi	a2,s0,-212
    800054b0:	fb040593          	addi	a1,s0,-80
    800054b4:	8526                	mv	a0,s1
    800054b6:	ffffe097          	auipc	ra,0xffffe
    800054ba:	6c8080e7          	jalr	1736(ra) # 80003b7e <dirlookup>
    800054be:	892a                	mv	s2,a0
    800054c0:	12050263          	beqz	a0,800055e4 <sys_unlink+0x1b0>
	ilock(ip);
    800054c4:	ffffe097          	auipc	ra,0xffffe
    800054c8:	1d6080e7          	jalr	470(ra) # 8000369a <ilock>
	if(ip->nlink < 1)
    800054cc:	04a91783          	lh	a5,74(s2)
    800054d0:	08f05263          	blez	a5,80005554 <sys_unlink+0x120>
	if(ip->type == T_DIR && !isdirempty(ip)){
    800054d4:	04491703          	lh	a4,68(s2)
    800054d8:	4785                	li	a5,1
    800054da:	08f70563          	beq	a4,a5,80005564 <sys_unlink+0x130>
	memset(&de, 0, sizeof(de));
    800054de:	4641                	li	a2,16
    800054e0:	4581                	li	a1,0
    800054e2:	fc040513          	addi	a0,s0,-64
    800054e6:	ffffb097          	auipc	ra,0xffffb
    800054ea:	7fa080e7          	jalr	2042(ra) # 80000ce0 <memset>
	if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800054ee:	4741                	li	a4,16
    800054f0:	f2c42683          	lw	a3,-212(s0)
    800054f4:	fc040613          	addi	a2,s0,-64
    800054f8:	4581                	li	a1,0
    800054fa:	8526                	mv	a0,s1
    800054fc:	ffffe097          	auipc	ra,0xffffe
    80005500:	54a080e7          	jalr	1354(ra) # 80003a46 <writei>
    80005504:	47c1                	li	a5,16
    80005506:	0af51563          	bne	a0,a5,800055b0 <sys_unlink+0x17c>
	if(ip->type == T_DIR){
    8000550a:	04491703          	lh	a4,68(s2)
    8000550e:	4785                	li	a5,1
    80005510:	0af70863          	beq	a4,a5,800055c0 <sys_unlink+0x18c>
	iunlockput(dp);
    80005514:	8526                	mv	a0,s1
    80005516:	ffffe097          	auipc	ra,0xffffe
    8000551a:	3e6080e7          	jalr	998(ra) # 800038fc <iunlockput>
	ip->nlink--;
    8000551e:	04a95783          	lhu	a5,74(s2)
    80005522:	37fd                	addiw	a5,a5,-1
    80005524:	04f91523          	sh	a5,74(s2)
	iupdate(ip);
    80005528:	854a                	mv	a0,s2
    8000552a:	ffffe097          	auipc	ra,0xffffe
    8000552e:	0a6080e7          	jalr	166(ra) # 800035d0 <iupdate>
	iunlockput(ip);
    80005532:	854a                	mv	a0,s2
    80005534:	ffffe097          	auipc	ra,0xffffe
    80005538:	3c8080e7          	jalr	968(ra) # 800038fc <iunlockput>
	end_op();
    8000553c:	fffff097          	auipc	ra,0xfffff
    80005540:	bb0080e7          	jalr	-1104(ra) # 800040ec <end_op>
	return 0;
    80005544:	4501                	li	a0,0
    80005546:	a84d                	j	800055f8 <sys_unlink+0x1c4>
		end_op();
    80005548:	fffff097          	auipc	ra,0xfffff
    8000554c:	ba4080e7          	jalr	-1116(ra) # 800040ec <end_op>
		return -1;
    80005550:	557d                	li	a0,-1
    80005552:	a05d                	j	800055f8 <sys_unlink+0x1c4>
		panic("unlink: nlink < 1");
    80005554:	00003517          	auipc	a0,0x3
    80005558:	1dc50513          	addi	a0,a0,476 # 80008730 <syscalls+0x2e0>
    8000555c:	ffffb097          	auipc	ra,0xffffb
    80005560:	fe2080e7          	jalr	-30(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005564:	04c92703          	lw	a4,76(s2)
    80005568:	02000793          	li	a5,32
    8000556c:	f6e7f9e3          	bgeu	a5,a4,800054de <sys_unlink+0xaa>
    80005570:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005574:	4741                	li	a4,16
    80005576:	86ce                	mv	a3,s3
    80005578:	f1840613          	addi	a2,s0,-232
    8000557c:	4581                	li	a1,0
    8000557e:	854a                	mv	a0,s2
    80005580:	ffffe097          	auipc	ra,0xffffe
    80005584:	3ce080e7          	jalr	974(ra) # 8000394e <readi>
    80005588:	47c1                	li	a5,16
    8000558a:	00f51b63          	bne	a0,a5,800055a0 <sys_unlink+0x16c>
    if(de.inum != 0)
    8000558e:	f1845783          	lhu	a5,-232(s0)
    80005592:	e7a1                	bnez	a5,800055da <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005594:	29c1                	addiw	s3,s3,16
    80005596:	04c92783          	lw	a5,76(s2)
    8000559a:	fcf9ede3          	bltu	s3,a5,80005574 <sys_unlink+0x140>
    8000559e:	b781                	j	800054de <sys_unlink+0xaa>
      panic("isdirempty: readi");
    800055a0:	00003517          	auipc	a0,0x3
    800055a4:	1a850513          	addi	a0,a0,424 # 80008748 <syscalls+0x2f8>
    800055a8:	ffffb097          	auipc	ra,0xffffb
    800055ac:	f96080e7          	jalr	-106(ra) # 8000053e <panic>
		panic("unlink: writei");
    800055b0:	00003517          	auipc	a0,0x3
    800055b4:	1b050513          	addi	a0,a0,432 # 80008760 <syscalls+0x310>
    800055b8:	ffffb097          	auipc	ra,0xffffb
    800055bc:	f86080e7          	jalr	-122(ra) # 8000053e <panic>
		dp->nlink--;
    800055c0:	04a4d783          	lhu	a5,74(s1)
    800055c4:	37fd                	addiw	a5,a5,-1
    800055c6:	04f49523          	sh	a5,74(s1)
		iupdate(dp);
    800055ca:	8526                	mv	a0,s1
    800055cc:	ffffe097          	auipc	ra,0xffffe
    800055d0:	004080e7          	jalr	4(ra) # 800035d0 <iupdate>
    800055d4:	b781                	j	80005514 <sys_unlink+0xe0>
		return -1;
    800055d6:	557d                	li	a0,-1
    800055d8:	a005                	j	800055f8 <sys_unlink+0x1c4>
		iunlockput(ip);
    800055da:	854a                	mv	a0,s2
    800055dc:	ffffe097          	auipc	ra,0xffffe
    800055e0:	320080e7          	jalr	800(ra) # 800038fc <iunlockput>
	iunlockput(dp);
    800055e4:	8526                	mv	a0,s1
    800055e6:	ffffe097          	auipc	ra,0xffffe
    800055ea:	316080e7          	jalr	790(ra) # 800038fc <iunlockput>
	end_op();
    800055ee:	fffff097          	auipc	ra,0xfffff
    800055f2:	afe080e7          	jalr	-1282(ra) # 800040ec <end_op>
	return -1;
    800055f6:	557d                	li	a0,-1
}
    800055f8:	70ae                	ld	ra,232(sp)
    800055fa:	740e                	ld	s0,224(sp)
    800055fc:	64ee                	ld	s1,216(sp)
    800055fe:	694e                	ld	s2,208(sp)
    80005600:	69ae                	ld	s3,200(sp)
    80005602:	616d                	addi	sp,sp,240
    80005604:	8082                	ret

0000000080005606 <sys_open>:

uint64
sys_open(void)
{
    80005606:	7131                	addi	sp,sp,-192
    80005608:	fd06                	sd	ra,184(sp)
    8000560a:	f922                	sd	s0,176(sp)
    8000560c:	f526                	sd	s1,168(sp)
    8000560e:	f14a                	sd	s2,160(sp)
    80005610:	ed4e                	sd	s3,152(sp)
    80005612:	0180                	addi	s0,sp,192
	int fd, omode;
	struct file *f;
	struct inode *ip;
	int n;

	if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005614:	08000613          	li	a2,128
    80005618:	f5040593          	addi	a1,s0,-176
    8000561c:	4501                	li	a0,0
    8000561e:	ffffd097          	auipc	ra,0xffffd
    80005622:	4fe080e7          	jalr	1278(ra) # 80002b1c <argstr>
		return -1;
    80005626:	54fd                	li	s1,-1
	if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005628:	0c054163          	bltz	a0,800056ea <sys_open+0xe4>
    8000562c:	f4c40593          	addi	a1,s0,-180
    80005630:	4505                	li	a0,1
    80005632:	ffffd097          	auipc	ra,0xffffd
    80005636:	4a6080e7          	jalr	1190(ra) # 80002ad8 <argint>
    8000563a:	0a054863          	bltz	a0,800056ea <sys_open+0xe4>

	begin_op();
    8000563e:	fffff097          	auipc	ra,0xfffff
    80005642:	a2e080e7          	jalr	-1490(ra) # 8000406c <begin_op>

	if(omode & O_CREATE){
    80005646:	f4c42783          	lw	a5,-180(s0)
    8000564a:	2007f793          	andi	a5,a5,512
    8000564e:	cbdd                	beqz	a5,80005704 <sys_open+0xfe>
		ip = create(path, T_FILE, 0, 0);
    80005650:	4681                	li	a3,0
    80005652:	4601                	li	a2,0
    80005654:	4589                	li	a1,2
    80005656:	f5040513          	addi	a0,s0,-176
    8000565a:	00000097          	auipc	ra,0x0
    8000565e:	972080e7          	jalr	-1678(ra) # 80004fcc <create>
    80005662:	892a                	mv	s2,a0
		if(ip == 0){
    80005664:	c959                	beqz	a0,800056fa <sys_open+0xf4>
			end_op();
			return -1;
		}
	}

	if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005666:	04491703          	lh	a4,68(s2)
    8000566a:	478d                	li	a5,3
    8000566c:	00f71763          	bne	a4,a5,8000567a <sys_open+0x74>
    80005670:	04695703          	lhu	a4,70(s2)
    80005674:	47a5                	li	a5,9
    80005676:	0ce7ec63          	bltu	a5,a4,8000574e <sys_open+0x148>
		iunlockput(ip);
		end_op();
		return -1;
	}

	if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    8000567a:	fffff097          	auipc	ra,0xfffff
    8000567e:	e02080e7          	jalr	-510(ra) # 8000447c <filealloc>
    80005682:	89aa                	mv	s3,a0
    80005684:	10050263          	beqz	a0,80005788 <sys_open+0x182>
    80005688:	00000097          	auipc	ra,0x0
    8000568c:	902080e7          	jalr	-1790(ra) # 80004f8a <fdalloc>
    80005690:	84aa                	mv	s1,a0
    80005692:	0e054663          	bltz	a0,8000577e <sys_open+0x178>
		iunlockput(ip);
		end_op();
		return -1;
	}

	if(ip->type == T_DEVICE){
    80005696:	04491703          	lh	a4,68(s2)
    8000569a:	478d                	li	a5,3
    8000569c:	0cf70463          	beq	a4,a5,80005764 <sys_open+0x15e>
		f->type = FD_DEVICE;
		f->major = ip->major;
	} else {
		f->type = FD_INODE;
    800056a0:	4789                	li	a5,2
    800056a2:	00f9a023          	sw	a5,0(s3)
		f->off = 0;
    800056a6:	0209a023          	sw	zero,32(s3)
	}
	f->ip = ip;
    800056aa:	0129bc23          	sd	s2,24(s3)
	f->readable = !(omode & O_WRONLY);
    800056ae:	f4c42783          	lw	a5,-180(s0)
    800056b2:	0017c713          	xori	a4,a5,1
    800056b6:	8b05                	andi	a4,a4,1
    800056b8:	00e98423          	sb	a4,8(s3)
	f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    800056bc:	0037f713          	andi	a4,a5,3
    800056c0:	00e03733          	snez	a4,a4
    800056c4:	00e984a3          	sb	a4,9(s3)

	if((omode & O_TRUNC) && ip->type == T_FILE){
    800056c8:	4007f793          	andi	a5,a5,1024
    800056cc:	c791                	beqz	a5,800056d8 <sys_open+0xd2>
    800056ce:	04491703          	lh	a4,68(s2)
    800056d2:	4789                	li	a5,2
    800056d4:	08f70f63          	beq	a4,a5,80005772 <sys_open+0x16c>
		itrunc(ip);
	}

	iunlock(ip);
    800056d8:	854a                	mv	a0,s2
    800056da:	ffffe097          	auipc	ra,0xffffe
    800056de:	082080e7          	jalr	130(ra) # 8000375c <iunlock>
	end_op();
    800056e2:	fffff097          	auipc	ra,0xfffff
    800056e6:	a0a080e7          	jalr	-1526(ra) # 800040ec <end_op>

	return fd;
}
    800056ea:	8526                	mv	a0,s1
    800056ec:	70ea                	ld	ra,184(sp)
    800056ee:	744a                	ld	s0,176(sp)
    800056f0:	74aa                	ld	s1,168(sp)
    800056f2:	790a                	ld	s2,160(sp)
    800056f4:	69ea                	ld	s3,152(sp)
    800056f6:	6129                	addi	sp,sp,192
    800056f8:	8082                	ret
			end_op();
    800056fa:	fffff097          	auipc	ra,0xfffff
    800056fe:	9f2080e7          	jalr	-1550(ra) # 800040ec <end_op>
			return -1;
    80005702:	b7e5                	j	800056ea <sys_open+0xe4>
		if((ip = namei(path)) == 0){
    80005704:	f5040513          	addi	a0,s0,-176
    80005708:	ffffe097          	auipc	ra,0xffffe
    8000570c:	748080e7          	jalr	1864(ra) # 80003e50 <namei>
    80005710:	892a                	mv	s2,a0
    80005712:	c905                	beqz	a0,80005742 <sys_open+0x13c>
		ilock(ip);
    80005714:	ffffe097          	auipc	ra,0xffffe
    80005718:	f86080e7          	jalr	-122(ra) # 8000369a <ilock>
		if(ip->type == T_DIR && omode != O_RDONLY){
    8000571c:	04491703          	lh	a4,68(s2)
    80005720:	4785                	li	a5,1
    80005722:	f4f712e3          	bne	a4,a5,80005666 <sys_open+0x60>
    80005726:	f4c42783          	lw	a5,-180(s0)
    8000572a:	dba1                	beqz	a5,8000567a <sys_open+0x74>
			iunlockput(ip);
    8000572c:	854a                	mv	a0,s2
    8000572e:	ffffe097          	auipc	ra,0xffffe
    80005732:	1ce080e7          	jalr	462(ra) # 800038fc <iunlockput>
			end_op();
    80005736:	fffff097          	auipc	ra,0xfffff
    8000573a:	9b6080e7          	jalr	-1610(ra) # 800040ec <end_op>
			return -1;
    8000573e:	54fd                	li	s1,-1
    80005740:	b76d                	j	800056ea <sys_open+0xe4>
			end_op();
    80005742:	fffff097          	auipc	ra,0xfffff
    80005746:	9aa080e7          	jalr	-1622(ra) # 800040ec <end_op>
			return -1;
    8000574a:	54fd                	li	s1,-1
    8000574c:	bf79                	j	800056ea <sys_open+0xe4>
		iunlockput(ip);
    8000574e:	854a                	mv	a0,s2
    80005750:	ffffe097          	auipc	ra,0xffffe
    80005754:	1ac080e7          	jalr	428(ra) # 800038fc <iunlockput>
		end_op();
    80005758:	fffff097          	auipc	ra,0xfffff
    8000575c:	994080e7          	jalr	-1644(ra) # 800040ec <end_op>
		return -1;
    80005760:	54fd                	li	s1,-1
    80005762:	b761                	j	800056ea <sys_open+0xe4>
		f->type = FD_DEVICE;
    80005764:	00f9a023          	sw	a5,0(s3)
		f->major = ip->major;
    80005768:	04691783          	lh	a5,70(s2)
    8000576c:	02f99223          	sh	a5,36(s3)
    80005770:	bf2d                	j	800056aa <sys_open+0xa4>
		itrunc(ip);
    80005772:	854a                	mv	a0,s2
    80005774:	ffffe097          	auipc	ra,0xffffe
    80005778:	034080e7          	jalr	52(ra) # 800037a8 <itrunc>
    8000577c:	bfb1                	j	800056d8 <sys_open+0xd2>
			fileclose(f);
    8000577e:	854e                	mv	a0,s3
    80005780:	fffff097          	auipc	ra,0xfffff
    80005784:	db8080e7          	jalr	-584(ra) # 80004538 <fileclose>
		iunlockput(ip);
    80005788:	854a                	mv	a0,s2
    8000578a:	ffffe097          	auipc	ra,0xffffe
    8000578e:	172080e7          	jalr	370(ra) # 800038fc <iunlockput>
		end_op();
    80005792:	fffff097          	auipc	ra,0xfffff
    80005796:	95a080e7          	jalr	-1702(ra) # 800040ec <end_op>
		return -1;
    8000579a:	54fd                	li	s1,-1
    8000579c:	b7b9                	j	800056ea <sys_open+0xe4>

000000008000579e <sys_mkdir>:

uint64
sys_mkdir(void)
{
    8000579e:	7175                	addi	sp,sp,-144
    800057a0:	e506                	sd	ra,136(sp)
    800057a2:	e122                	sd	s0,128(sp)
    800057a4:	0900                	addi	s0,sp,144
	char path[MAXPATH];
	struct inode *ip;

	begin_op();
    800057a6:	fffff097          	auipc	ra,0xfffff
    800057aa:	8c6080e7          	jalr	-1850(ra) # 8000406c <begin_op>
	if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    800057ae:	08000613          	li	a2,128
    800057b2:	f7040593          	addi	a1,s0,-144
    800057b6:	4501                	li	a0,0
    800057b8:	ffffd097          	auipc	ra,0xffffd
    800057bc:	364080e7          	jalr	868(ra) # 80002b1c <argstr>
    800057c0:	02054963          	bltz	a0,800057f2 <sys_mkdir+0x54>
    800057c4:	4681                	li	a3,0
    800057c6:	4601                	li	a2,0
    800057c8:	4585                	li	a1,1
    800057ca:	f7040513          	addi	a0,s0,-144
    800057ce:	fffff097          	auipc	ra,0xfffff
    800057d2:	7fe080e7          	jalr	2046(ra) # 80004fcc <create>
    800057d6:	cd11                	beqz	a0,800057f2 <sys_mkdir+0x54>
		end_op();
		return -1;
	}
	iunlockput(ip);
    800057d8:	ffffe097          	auipc	ra,0xffffe
    800057dc:	124080e7          	jalr	292(ra) # 800038fc <iunlockput>
	end_op();
    800057e0:	fffff097          	auipc	ra,0xfffff
    800057e4:	90c080e7          	jalr	-1780(ra) # 800040ec <end_op>
	return 0;
    800057e8:	4501                	li	a0,0
}
    800057ea:	60aa                	ld	ra,136(sp)
    800057ec:	640a                	ld	s0,128(sp)
    800057ee:	6149                	addi	sp,sp,144
    800057f0:	8082                	ret
		end_op();
    800057f2:	fffff097          	auipc	ra,0xfffff
    800057f6:	8fa080e7          	jalr	-1798(ra) # 800040ec <end_op>
		return -1;
    800057fa:	557d                	li	a0,-1
    800057fc:	b7fd                	j	800057ea <sys_mkdir+0x4c>

00000000800057fe <sys_mknod>:

uint64
sys_mknod(void)
{
    800057fe:	7135                	addi	sp,sp,-160
    80005800:	ed06                	sd	ra,152(sp)
    80005802:	e922                	sd	s0,144(sp)
    80005804:	1100                	addi	s0,sp,160
	struct inode *ip;
	char path[MAXPATH];
	int major, minor;

	begin_op();
    80005806:	fffff097          	auipc	ra,0xfffff
    8000580a:	866080e7          	jalr	-1946(ra) # 8000406c <begin_op>
	if((argstr(0, path, MAXPATH)) < 0 ||
    8000580e:	08000613          	li	a2,128
    80005812:	f7040593          	addi	a1,s0,-144
    80005816:	4501                	li	a0,0
    80005818:	ffffd097          	auipc	ra,0xffffd
    8000581c:	304080e7          	jalr	772(ra) # 80002b1c <argstr>
    80005820:	04054a63          	bltz	a0,80005874 <sys_mknod+0x76>
			argint(1, &major) < 0 ||
    80005824:	f6c40593          	addi	a1,s0,-148
    80005828:	4505                	li	a0,1
    8000582a:	ffffd097          	auipc	ra,0xffffd
    8000582e:	2ae080e7          	jalr	686(ra) # 80002ad8 <argint>
	if((argstr(0, path, MAXPATH)) < 0 ||
    80005832:	04054163          	bltz	a0,80005874 <sys_mknod+0x76>
			argint(2, &minor) < 0 ||
    80005836:	f6840593          	addi	a1,s0,-152
    8000583a:	4509                	li	a0,2
    8000583c:	ffffd097          	auipc	ra,0xffffd
    80005840:	29c080e7          	jalr	668(ra) # 80002ad8 <argint>
			argint(1, &major) < 0 ||
    80005844:	02054863          	bltz	a0,80005874 <sys_mknod+0x76>
			(ip = create(path, T_DEVICE, major, minor)) == 0){
    80005848:	f6841683          	lh	a3,-152(s0)
    8000584c:	f6c41603          	lh	a2,-148(s0)
    80005850:	458d                	li	a1,3
    80005852:	f7040513          	addi	a0,s0,-144
    80005856:	fffff097          	auipc	ra,0xfffff
    8000585a:	776080e7          	jalr	1910(ra) # 80004fcc <create>
			argint(2, &minor) < 0 ||
    8000585e:	c919                	beqz	a0,80005874 <sys_mknod+0x76>
		end_op();
		return -1;
	}
	iunlockput(ip);
    80005860:	ffffe097          	auipc	ra,0xffffe
    80005864:	09c080e7          	jalr	156(ra) # 800038fc <iunlockput>
	end_op();
    80005868:	fffff097          	auipc	ra,0xfffff
    8000586c:	884080e7          	jalr	-1916(ra) # 800040ec <end_op>
	return 0;
    80005870:	4501                	li	a0,0
    80005872:	a031                	j	8000587e <sys_mknod+0x80>
		end_op();
    80005874:	fffff097          	auipc	ra,0xfffff
    80005878:	878080e7          	jalr	-1928(ra) # 800040ec <end_op>
		return -1;
    8000587c:	557d                	li	a0,-1
}
    8000587e:	60ea                	ld	ra,152(sp)
    80005880:	644a                	ld	s0,144(sp)
    80005882:	610d                	addi	sp,sp,160
    80005884:	8082                	ret

0000000080005886 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005886:	7135                	addi	sp,sp,-160
    80005888:	ed06                	sd	ra,152(sp)
    8000588a:	e922                	sd	s0,144(sp)
    8000588c:	e526                	sd	s1,136(sp)
    8000588e:	e14a                	sd	s2,128(sp)
    80005890:	1100                	addi	s0,sp,160
	char path[MAXPATH];
	struct inode *ip;
	struct proc *p = myproc();
    80005892:	ffffc097          	auipc	ra,0xffffc
    80005896:	19a080e7          	jalr	410(ra) # 80001a2c <myproc>
    8000589a:	892a                	mv	s2,a0

	begin_op();
    8000589c:	ffffe097          	auipc	ra,0xffffe
    800058a0:	7d0080e7          	jalr	2000(ra) # 8000406c <begin_op>
	if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    800058a4:	08000613          	li	a2,128
    800058a8:	f6040593          	addi	a1,s0,-160
    800058ac:	4501                	li	a0,0
    800058ae:	ffffd097          	auipc	ra,0xffffd
    800058b2:	26e080e7          	jalr	622(ra) # 80002b1c <argstr>
    800058b6:	04054b63          	bltz	a0,8000590c <sys_chdir+0x86>
    800058ba:	f6040513          	addi	a0,s0,-160
    800058be:	ffffe097          	auipc	ra,0xffffe
    800058c2:	592080e7          	jalr	1426(ra) # 80003e50 <namei>
    800058c6:	84aa                	mv	s1,a0
    800058c8:	c131                	beqz	a0,8000590c <sys_chdir+0x86>
		end_op();
		return -1;
	}
	ilock(ip);
    800058ca:	ffffe097          	auipc	ra,0xffffe
    800058ce:	dd0080e7          	jalr	-560(ra) # 8000369a <ilock>
	if(ip->type != T_DIR){
    800058d2:	04449703          	lh	a4,68(s1)
    800058d6:	4785                	li	a5,1
    800058d8:	04f71063          	bne	a4,a5,80005918 <sys_chdir+0x92>
		iunlockput(ip);
		end_op();
		return -1;
	}
	iunlock(ip);
    800058dc:	8526                	mv	a0,s1
    800058de:	ffffe097          	auipc	ra,0xffffe
    800058e2:	e7e080e7          	jalr	-386(ra) # 8000375c <iunlock>
	iput(p->cwd);
    800058e6:	15093503          	ld	a0,336(s2)
    800058ea:	ffffe097          	auipc	ra,0xffffe
    800058ee:	f6a080e7          	jalr	-150(ra) # 80003854 <iput>
	end_op();
    800058f2:	ffffe097          	auipc	ra,0xffffe
    800058f6:	7fa080e7          	jalr	2042(ra) # 800040ec <end_op>
	p->cwd = ip;
    800058fa:	14993823          	sd	s1,336(s2)
	return 0;
    800058fe:	4501                	li	a0,0
}
    80005900:	60ea                	ld	ra,152(sp)
    80005902:	644a                	ld	s0,144(sp)
    80005904:	64aa                	ld	s1,136(sp)
    80005906:	690a                	ld	s2,128(sp)
    80005908:	610d                	addi	sp,sp,160
    8000590a:	8082                	ret
		end_op();
    8000590c:	ffffe097          	auipc	ra,0xffffe
    80005910:	7e0080e7          	jalr	2016(ra) # 800040ec <end_op>
		return -1;
    80005914:	557d                	li	a0,-1
    80005916:	b7ed                	j	80005900 <sys_chdir+0x7a>
		iunlockput(ip);
    80005918:	8526                	mv	a0,s1
    8000591a:	ffffe097          	auipc	ra,0xffffe
    8000591e:	fe2080e7          	jalr	-30(ra) # 800038fc <iunlockput>
		end_op();
    80005922:	ffffe097          	auipc	ra,0xffffe
    80005926:	7ca080e7          	jalr	1994(ra) # 800040ec <end_op>
		return -1;
    8000592a:	557d                	li	a0,-1
    8000592c:	bfd1                	j	80005900 <sys_chdir+0x7a>

000000008000592e <sys_exec>:

uint64
sys_exec(void)
{
    8000592e:	7145                	addi	sp,sp,-464
    80005930:	e786                	sd	ra,456(sp)
    80005932:	e3a2                	sd	s0,448(sp)
    80005934:	ff26                	sd	s1,440(sp)
    80005936:	fb4a                	sd	s2,432(sp)
    80005938:	f74e                	sd	s3,424(sp)
    8000593a:	f352                	sd	s4,416(sp)
    8000593c:	ef56                	sd	s5,408(sp)
    8000593e:	0b80                	addi	s0,sp,464
	char path[MAXPATH], *argv[MAXARG];
	int i;
	uint64 uargv, uarg;

	if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005940:	08000613          	li	a2,128
    80005944:	f4040593          	addi	a1,s0,-192
    80005948:	4501                	li	a0,0
    8000594a:	ffffd097          	auipc	ra,0xffffd
    8000594e:	1d2080e7          	jalr	466(ra) # 80002b1c <argstr>
		return -1;
    80005952:	597d                	li	s2,-1
	if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005954:	0c054a63          	bltz	a0,80005a28 <sys_exec+0xfa>
    80005958:	e3840593          	addi	a1,s0,-456
    8000595c:	4505                	li	a0,1
    8000595e:	ffffd097          	auipc	ra,0xffffd
    80005962:	19c080e7          	jalr	412(ra) # 80002afa <argaddr>
    80005966:	0c054163          	bltz	a0,80005a28 <sys_exec+0xfa>
	}
	memset(argv, 0, sizeof(argv));
    8000596a:	10000613          	li	a2,256
    8000596e:	4581                	li	a1,0
    80005970:	e4040513          	addi	a0,s0,-448
    80005974:	ffffb097          	auipc	ra,0xffffb
    80005978:	36c080e7          	jalr	876(ra) # 80000ce0 <memset>
	for(i=0;; i++){
		if(i >= NELEM(argv)){
    8000597c:	e4040493          	addi	s1,s0,-448
	memset(argv, 0, sizeof(argv));
    80005980:	89a6                	mv	s3,s1
    80005982:	4901                	li	s2,0
		if(i >= NELEM(argv)){
    80005984:	02000a13          	li	s4,32
    80005988:	00090a9b          	sext.w	s5,s2
			goto bad;
		}
		if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    8000598c:	00391513          	slli	a0,s2,0x3
    80005990:	e3040593          	addi	a1,s0,-464
    80005994:	e3843783          	ld	a5,-456(s0)
    80005998:	953e                	add	a0,a0,a5
    8000599a:	ffffd097          	auipc	ra,0xffffd
    8000599e:	0a4080e7          	jalr	164(ra) # 80002a3e <fetchaddr>
    800059a2:	02054a63          	bltz	a0,800059d6 <sys_exec+0xa8>
			goto bad;
		}
		if(uarg == 0){
    800059a6:	e3043783          	ld	a5,-464(s0)
    800059aa:	c3b9                	beqz	a5,800059f0 <sys_exec+0xc2>
			argv[i] = 0;
			break;
		}
		argv[i] = kalloc();
    800059ac:	ffffb097          	auipc	ra,0xffffb
    800059b0:	148080e7          	jalr	328(ra) # 80000af4 <kalloc>
    800059b4:	85aa                	mv	a1,a0
    800059b6:	00a9b023          	sd	a0,0(s3)
		if(argv[i] == 0)
    800059ba:	cd11                	beqz	a0,800059d6 <sys_exec+0xa8>
			goto bad;
		if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    800059bc:	6605                	lui	a2,0x1
    800059be:	e3043503          	ld	a0,-464(s0)
    800059c2:	ffffd097          	auipc	ra,0xffffd
    800059c6:	0ce080e7          	jalr	206(ra) # 80002a90 <fetchstr>
    800059ca:	00054663          	bltz	a0,800059d6 <sys_exec+0xa8>
		if(i >= NELEM(argv)){
    800059ce:	0905                	addi	s2,s2,1
    800059d0:	09a1                	addi	s3,s3,8
    800059d2:	fb491be3          	bne	s2,s4,80005988 <sys_exec+0x5a>
		kfree(argv[i]);

	return ret;

bad:
	for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800059d6:	10048913          	addi	s2,s1,256
    800059da:	6088                	ld	a0,0(s1)
    800059dc:	c529                	beqz	a0,80005a26 <sys_exec+0xf8>
		kfree(argv[i]);
    800059de:	ffffb097          	auipc	ra,0xffffb
    800059e2:	01a080e7          	jalr	26(ra) # 800009f8 <kfree>
	for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800059e6:	04a1                	addi	s1,s1,8
    800059e8:	ff2499e3          	bne	s1,s2,800059da <sys_exec+0xac>
	return -1;
    800059ec:	597d                	li	s2,-1
    800059ee:	a82d                	j	80005a28 <sys_exec+0xfa>
			argv[i] = 0;
    800059f0:	0a8e                	slli	s5,s5,0x3
    800059f2:	fc040793          	addi	a5,s0,-64
    800059f6:	9abe                	add	s5,s5,a5
    800059f8:	e80ab023          	sd	zero,-384(s5)
	int ret = exec(path, argv);
    800059fc:	e4040593          	addi	a1,s0,-448
    80005a00:	f4040513          	addi	a0,s0,-192
    80005a04:	fffff097          	auipc	ra,0xfffff
    80005a08:	194080e7          	jalr	404(ra) # 80004b98 <exec>
    80005a0c:	892a                	mv	s2,a0
	for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005a0e:	10048993          	addi	s3,s1,256
    80005a12:	6088                	ld	a0,0(s1)
    80005a14:	c911                	beqz	a0,80005a28 <sys_exec+0xfa>
		kfree(argv[i]);
    80005a16:	ffffb097          	auipc	ra,0xffffb
    80005a1a:	fe2080e7          	jalr	-30(ra) # 800009f8 <kfree>
	for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005a1e:	04a1                	addi	s1,s1,8
    80005a20:	ff3499e3          	bne	s1,s3,80005a12 <sys_exec+0xe4>
    80005a24:	a011                	j	80005a28 <sys_exec+0xfa>
	return -1;
    80005a26:	597d                	li	s2,-1
}
    80005a28:	854a                	mv	a0,s2
    80005a2a:	60be                	ld	ra,456(sp)
    80005a2c:	641e                	ld	s0,448(sp)
    80005a2e:	74fa                	ld	s1,440(sp)
    80005a30:	795a                	ld	s2,432(sp)
    80005a32:	79ba                	ld	s3,424(sp)
    80005a34:	7a1a                	ld	s4,416(sp)
    80005a36:	6afa                	ld	s5,408(sp)
    80005a38:	6179                	addi	sp,sp,464
    80005a3a:	8082                	ret

0000000080005a3c <sys_pipe>:

uint64
sys_pipe(void)
{
    80005a3c:	7139                	addi	sp,sp,-64
    80005a3e:	fc06                	sd	ra,56(sp)
    80005a40:	f822                	sd	s0,48(sp)
    80005a42:	f426                	sd	s1,40(sp)
    80005a44:	0080                	addi	s0,sp,64
	uint64 fdarray; // user pointer to array of two integers
	struct file *rf, *wf;
	int fd0, fd1;
	struct proc *p = myproc();
    80005a46:	ffffc097          	auipc	ra,0xffffc
    80005a4a:	fe6080e7          	jalr	-26(ra) # 80001a2c <myproc>
    80005a4e:	84aa                	mv	s1,a0

	if(argaddr(0, &fdarray) < 0)
    80005a50:	fd840593          	addi	a1,s0,-40
    80005a54:	4501                	li	a0,0
    80005a56:	ffffd097          	auipc	ra,0xffffd
    80005a5a:	0a4080e7          	jalr	164(ra) # 80002afa <argaddr>
		return -1;
    80005a5e:	57fd                	li	a5,-1
	if(argaddr(0, &fdarray) < 0)
    80005a60:	0e054063          	bltz	a0,80005b40 <sys_pipe+0x104>
	if(pipealloc(&rf, &wf) < 0)
    80005a64:	fc840593          	addi	a1,s0,-56
    80005a68:	fd040513          	addi	a0,s0,-48
    80005a6c:	fffff097          	auipc	ra,0xfffff
    80005a70:	dfc080e7          	jalr	-516(ra) # 80004868 <pipealloc>
		return -1;
    80005a74:	57fd                	li	a5,-1
	if(pipealloc(&rf, &wf) < 0)
    80005a76:	0c054563          	bltz	a0,80005b40 <sys_pipe+0x104>
	fd0 = -1;
    80005a7a:	fcf42223          	sw	a5,-60(s0)
	if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005a7e:	fd043503          	ld	a0,-48(s0)
    80005a82:	fffff097          	auipc	ra,0xfffff
    80005a86:	508080e7          	jalr	1288(ra) # 80004f8a <fdalloc>
    80005a8a:	fca42223          	sw	a0,-60(s0)
    80005a8e:	08054c63          	bltz	a0,80005b26 <sys_pipe+0xea>
    80005a92:	fc843503          	ld	a0,-56(s0)
    80005a96:	fffff097          	auipc	ra,0xfffff
    80005a9a:	4f4080e7          	jalr	1268(ra) # 80004f8a <fdalloc>
    80005a9e:	fca42023          	sw	a0,-64(s0)
    80005aa2:	06054863          	bltz	a0,80005b12 <sys_pipe+0xd6>
			p->ofile[fd0] = 0;
		fileclose(rf);
		fileclose(wf);
		return -1;
	}
	if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005aa6:	4691                	li	a3,4
    80005aa8:	fc440613          	addi	a2,s0,-60
    80005aac:	fd843583          	ld	a1,-40(s0)
    80005ab0:	68a8                	ld	a0,80(s1)
    80005ab2:	ffffc097          	auipc	ra,0xffffc
    80005ab6:	bc0080e7          	jalr	-1088(ra) # 80001672 <copyout>
    80005aba:	02054063          	bltz	a0,80005ada <sys_pipe+0x9e>
			copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005abe:	4691                	li	a3,4
    80005ac0:	fc040613          	addi	a2,s0,-64
    80005ac4:	fd843583          	ld	a1,-40(s0)
    80005ac8:	0591                	addi	a1,a1,4
    80005aca:	68a8                	ld	a0,80(s1)
    80005acc:	ffffc097          	auipc	ra,0xffffc
    80005ad0:	ba6080e7          	jalr	-1114(ra) # 80001672 <copyout>
		p->ofile[fd1] = 0;
		fileclose(rf);
		fileclose(wf);
		return -1;
	}
	return 0;
    80005ad4:	4781                	li	a5,0
	if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005ad6:	06055563          	bgez	a0,80005b40 <sys_pipe+0x104>
		p->ofile[fd0] = 0;
    80005ada:	fc442783          	lw	a5,-60(s0)
    80005ade:	07e9                	addi	a5,a5,26
    80005ae0:	078e                	slli	a5,a5,0x3
    80005ae2:	97a6                	add	a5,a5,s1
    80005ae4:	0007b023          	sd	zero,0(a5)
		p->ofile[fd1] = 0;
    80005ae8:	fc042503          	lw	a0,-64(s0)
    80005aec:	0569                	addi	a0,a0,26
    80005aee:	050e                	slli	a0,a0,0x3
    80005af0:	9526                	add	a0,a0,s1
    80005af2:	00053023          	sd	zero,0(a0)
		fileclose(rf);
    80005af6:	fd043503          	ld	a0,-48(s0)
    80005afa:	fffff097          	auipc	ra,0xfffff
    80005afe:	a3e080e7          	jalr	-1474(ra) # 80004538 <fileclose>
		fileclose(wf);
    80005b02:	fc843503          	ld	a0,-56(s0)
    80005b06:	fffff097          	auipc	ra,0xfffff
    80005b0a:	a32080e7          	jalr	-1486(ra) # 80004538 <fileclose>
		return -1;
    80005b0e:	57fd                	li	a5,-1
    80005b10:	a805                	j	80005b40 <sys_pipe+0x104>
		if(fd0 >= 0)
    80005b12:	fc442783          	lw	a5,-60(s0)
    80005b16:	0007c863          	bltz	a5,80005b26 <sys_pipe+0xea>
			p->ofile[fd0] = 0;
    80005b1a:	01a78513          	addi	a0,a5,26
    80005b1e:	050e                	slli	a0,a0,0x3
    80005b20:	9526                	add	a0,a0,s1
    80005b22:	00053023          	sd	zero,0(a0)
		fileclose(rf);
    80005b26:	fd043503          	ld	a0,-48(s0)
    80005b2a:	fffff097          	auipc	ra,0xfffff
    80005b2e:	a0e080e7          	jalr	-1522(ra) # 80004538 <fileclose>
		fileclose(wf);
    80005b32:	fc843503          	ld	a0,-56(s0)
    80005b36:	fffff097          	auipc	ra,0xfffff
    80005b3a:	a02080e7          	jalr	-1534(ra) # 80004538 <fileclose>
		return -1;
    80005b3e:	57fd                	li	a5,-1
}
    80005b40:	853e                	mv	a0,a5
    80005b42:	70e2                	ld	ra,56(sp)
    80005b44:	7442                	ld	s0,48(sp)
    80005b46:	74a2                	ld	s1,40(sp)
    80005b48:	6121                	addi	sp,sp,64
    80005b4a:	8082                	ret
    80005b4c:	0000                	unimp
	...

0000000080005b50 <kernelvec>:
    80005b50:	7111                	addi	sp,sp,-256
    80005b52:	e006                	sd	ra,0(sp)
    80005b54:	e40a                	sd	sp,8(sp)
    80005b56:	e80e                	sd	gp,16(sp)
    80005b58:	ec12                	sd	tp,24(sp)
    80005b5a:	f016                	sd	t0,32(sp)
    80005b5c:	f41a                	sd	t1,40(sp)
    80005b5e:	f81e                	sd	t2,48(sp)
    80005b60:	fc22                	sd	s0,56(sp)
    80005b62:	e0a6                	sd	s1,64(sp)
    80005b64:	e4aa                	sd	a0,72(sp)
    80005b66:	e8ae                	sd	a1,80(sp)
    80005b68:	ecb2                	sd	a2,88(sp)
    80005b6a:	f0b6                	sd	a3,96(sp)
    80005b6c:	f4ba                	sd	a4,104(sp)
    80005b6e:	f8be                	sd	a5,112(sp)
    80005b70:	fcc2                	sd	a6,120(sp)
    80005b72:	e146                	sd	a7,128(sp)
    80005b74:	e54a                	sd	s2,136(sp)
    80005b76:	e94e                	sd	s3,144(sp)
    80005b78:	ed52                	sd	s4,152(sp)
    80005b7a:	f156                	sd	s5,160(sp)
    80005b7c:	f55a                	sd	s6,168(sp)
    80005b7e:	f95e                	sd	s7,176(sp)
    80005b80:	fd62                	sd	s8,184(sp)
    80005b82:	e1e6                	sd	s9,192(sp)
    80005b84:	e5ea                	sd	s10,200(sp)
    80005b86:	e9ee                	sd	s11,208(sp)
    80005b88:	edf2                	sd	t3,216(sp)
    80005b8a:	f1f6                	sd	t4,224(sp)
    80005b8c:	f5fa                	sd	t5,232(sp)
    80005b8e:	f9fe                	sd	t6,240(sp)
    80005b90:	d7bfc0ef          	jal	ra,8000290a <kerneltrap>
    80005b94:	6082                	ld	ra,0(sp)
    80005b96:	6122                	ld	sp,8(sp)
    80005b98:	61c2                	ld	gp,16(sp)
    80005b9a:	7282                	ld	t0,32(sp)
    80005b9c:	7322                	ld	t1,40(sp)
    80005b9e:	73c2                	ld	t2,48(sp)
    80005ba0:	7462                	ld	s0,56(sp)
    80005ba2:	6486                	ld	s1,64(sp)
    80005ba4:	6526                	ld	a0,72(sp)
    80005ba6:	65c6                	ld	a1,80(sp)
    80005ba8:	6666                	ld	a2,88(sp)
    80005baa:	7686                	ld	a3,96(sp)
    80005bac:	7726                	ld	a4,104(sp)
    80005bae:	77c6                	ld	a5,112(sp)
    80005bb0:	7866                	ld	a6,120(sp)
    80005bb2:	688a                	ld	a7,128(sp)
    80005bb4:	692a                	ld	s2,136(sp)
    80005bb6:	69ca                	ld	s3,144(sp)
    80005bb8:	6a6a                	ld	s4,152(sp)
    80005bba:	7a8a                	ld	s5,160(sp)
    80005bbc:	7b2a                	ld	s6,168(sp)
    80005bbe:	7bca                	ld	s7,176(sp)
    80005bc0:	7c6a                	ld	s8,184(sp)
    80005bc2:	6c8e                	ld	s9,192(sp)
    80005bc4:	6d2e                	ld	s10,200(sp)
    80005bc6:	6dce                	ld	s11,208(sp)
    80005bc8:	6e6e                	ld	t3,216(sp)
    80005bca:	7e8e                	ld	t4,224(sp)
    80005bcc:	7f2e                	ld	t5,232(sp)
    80005bce:	7fce                	ld	t6,240(sp)
    80005bd0:	6111                	addi	sp,sp,256
    80005bd2:	10200073          	sret
    80005bd6:	00000013          	nop
    80005bda:	00000013          	nop
    80005bde:	0001                	nop

0000000080005be0 <timervec>:
    80005be0:	34051573          	csrrw	a0,mscratch,a0
    80005be4:	e10c                	sd	a1,0(a0)
    80005be6:	e510                	sd	a2,8(a0)
    80005be8:	e914                	sd	a3,16(a0)
    80005bea:	6d0c                	ld	a1,24(a0)
    80005bec:	7110                	ld	a2,32(a0)
    80005bee:	6194                	ld	a3,0(a1)
    80005bf0:	96b2                	add	a3,a3,a2
    80005bf2:	e194                	sd	a3,0(a1)
    80005bf4:	4589                	li	a1,2
    80005bf6:	14459073          	csrw	sip,a1
    80005bfa:	6914                	ld	a3,16(a0)
    80005bfc:	6510                	ld	a2,8(a0)
    80005bfe:	610c                	ld	a1,0(a0)
    80005c00:	34051573          	csrrw	a0,mscratch,a0
    80005c04:	30200073          	mret
	...

0000000080005c0a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005c0a:	1141                	addi	sp,sp,-16
    80005c0c:	e422                	sd	s0,8(sp)
    80005c0e:	0800                	addi	s0,sp,16
	// set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005c10:	0c0007b7          	lui	a5,0xc000
    80005c14:	4705                	li	a4,1
    80005c16:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005c18:	c3d8                	sw	a4,4(a5)
}
    80005c1a:	6422                	ld	s0,8(sp)
    80005c1c:	0141                	addi	sp,sp,16
    80005c1e:	8082                	ret

0000000080005c20 <plicinithart>:

void
plicinithart(void)
{
    80005c20:	1141                	addi	sp,sp,-16
    80005c22:	e406                	sd	ra,8(sp)
    80005c24:	e022                	sd	s0,0(sp)
    80005c26:	0800                	addi	s0,sp,16
	int hart = cpuid();
    80005c28:	ffffc097          	auipc	ra,0xffffc
    80005c2c:	dd8080e7          	jalr	-552(ra) # 80001a00 <cpuid>

  // set uart's enable bit for this hart's S-mode.
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005c30:	0085171b          	slliw	a4,a0,0x8
    80005c34:	0c0027b7          	lui	a5,0xc002
    80005c38:	97ba                	add	a5,a5,a4
    80005c3a:	40200713          	li	a4,1026
    80005c3e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005c42:	00d5151b          	slliw	a0,a0,0xd
    80005c46:	0c2017b7          	lui	a5,0xc201
    80005c4a:	953e                	add	a0,a0,a5
    80005c4c:	00052023          	sw	zero,0(a0)
}
    80005c50:	60a2                	ld	ra,8(sp)
    80005c52:	6402                	ld	s0,0(sp)
    80005c54:	0141                	addi	sp,sp,16
    80005c56:	8082                	ret

0000000080005c58 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005c58:	1141                	addi	sp,sp,-16
    80005c5a:	e406                	sd	ra,8(sp)
    80005c5c:	e022                	sd	s0,0(sp)
    80005c5e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005c60:	ffffc097          	auipc	ra,0xffffc
    80005c64:	da0080e7          	jalr	-608(ra) # 80001a00 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005c68:	00d5179b          	slliw	a5,a0,0xd
    80005c6c:	0c201537          	lui	a0,0xc201
    80005c70:	953e                	add	a0,a0,a5
  return irq;
}
    80005c72:	4148                	lw	a0,4(a0)
    80005c74:	60a2                	ld	ra,8(sp)
    80005c76:	6402                	ld	s0,0(sp)
    80005c78:	0141                	addi	sp,sp,16
    80005c7a:	8082                	ret

0000000080005c7c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005c7c:	1101                	addi	sp,sp,-32
    80005c7e:	ec06                	sd	ra,24(sp)
    80005c80:	e822                	sd	s0,16(sp)
    80005c82:	e426                	sd	s1,8(sp)
    80005c84:	1000                	addi	s0,sp,32
    80005c86:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005c88:	ffffc097          	auipc	ra,0xffffc
    80005c8c:	d78080e7          	jalr	-648(ra) # 80001a00 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005c90:	00d5151b          	slliw	a0,a0,0xd
    80005c94:	0c2017b7          	lui	a5,0xc201
    80005c98:	97aa                	add	a5,a5,a0
    80005c9a:	c3c4                	sw	s1,4(a5)
}
    80005c9c:	60e2                	ld	ra,24(sp)
    80005c9e:	6442                	ld	s0,16(sp)
    80005ca0:	64a2                	ld	s1,8(sp)
    80005ca2:	6105                	addi	sp,sp,32
    80005ca4:	8082                	ret

0000000080005ca6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005ca6:	1141                	addi	sp,sp,-16
    80005ca8:	e406                	sd	ra,8(sp)
    80005caa:	e022                	sd	s0,0(sp)
    80005cac:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005cae:	479d                	li	a5,7
    80005cb0:	06a7c963          	blt	a5,a0,80005d22 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    80005cb4:	0001d797          	auipc	a5,0x1d
    80005cb8:	34c78793          	addi	a5,a5,844 # 80023000 <disk>
    80005cbc:	00a78733          	add	a4,a5,a0
    80005cc0:	6789                	lui	a5,0x2
    80005cc2:	97ba                	add	a5,a5,a4
    80005cc4:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80005cc8:	e7ad                	bnez	a5,80005d32 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005cca:	00451793          	slli	a5,a0,0x4
    80005cce:	0001f717          	auipc	a4,0x1f
    80005cd2:	33270713          	addi	a4,a4,818 # 80025000 <disk+0x2000>
    80005cd6:	6314                	ld	a3,0(a4)
    80005cd8:	96be                	add	a3,a3,a5
    80005cda:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80005cde:	6314                	ld	a3,0(a4)
    80005ce0:	96be                	add	a3,a3,a5
    80005ce2:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80005ce6:	6314                	ld	a3,0(a4)
    80005ce8:	96be                	add	a3,a3,a5
    80005cea:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    80005cee:	6318                	ld	a4,0(a4)
    80005cf0:	97ba                	add	a5,a5,a4
    80005cf2:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80005cf6:	0001d797          	auipc	a5,0x1d
    80005cfa:	30a78793          	addi	a5,a5,778 # 80023000 <disk>
    80005cfe:	97aa                	add	a5,a5,a0
    80005d00:	6509                	lui	a0,0x2
    80005d02:	953e                	add	a0,a0,a5
    80005d04:	4785                	li	a5,1
    80005d06:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80005d0a:	0001f517          	auipc	a0,0x1f
    80005d0e:	30e50513          	addi	a0,a0,782 # 80025018 <disk+0x2018>
    80005d12:	ffffc097          	auipc	ra,0xffffc
    80005d16:	562080e7          	jalr	1378(ra) # 80002274 <wakeup>
}
    80005d1a:	60a2                	ld	ra,8(sp)
    80005d1c:	6402                	ld	s0,0(sp)
    80005d1e:	0141                	addi	sp,sp,16
    80005d20:	8082                	ret
    panic("free_desc 1");
    80005d22:	00003517          	auipc	a0,0x3
    80005d26:	a4e50513          	addi	a0,a0,-1458 # 80008770 <syscalls+0x320>
    80005d2a:	ffffb097          	auipc	ra,0xffffb
    80005d2e:	814080e7          	jalr	-2028(ra) # 8000053e <panic>
    panic("free_desc 2");
    80005d32:	00003517          	auipc	a0,0x3
    80005d36:	a4e50513          	addi	a0,a0,-1458 # 80008780 <syscalls+0x330>
    80005d3a:	ffffb097          	auipc	ra,0xffffb
    80005d3e:	804080e7          	jalr	-2044(ra) # 8000053e <panic>

0000000080005d42 <virtio_disk_init>:
{
    80005d42:	1101                	addi	sp,sp,-32
    80005d44:	ec06                	sd	ra,24(sp)
    80005d46:	e822                	sd	s0,16(sp)
    80005d48:	e426                	sd	s1,8(sp)
    80005d4a:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005d4c:	00003597          	auipc	a1,0x3
    80005d50:	a4458593          	addi	a1,a1,-1468 # 80008790 <syscalls+0x340>
    80005d54:	0001f517          	auipc	a0,0x1f
    80005d58:	3d450513          	addi	a0,a0,980 # 80025128 <disk+0x2128>
    80005d5c:	ffffb097          	auipc	ra,0xffffb
    80005d60:	df8080e7          	jalr	-520(ra) # 80000b54 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005d64:	100017b7          	lui	a5,0x10001
    80005d68:	4398                	lw	a4,0(a5)
    80005d6a:	2701                	sext.w	a4,a4
    80005d6c:	747277b7          	lui	a5,0x74727
    80005d70:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005d74:	0ef71163          	bne	a4,a5,80005e56 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005d78:	100017b7          	lui	a5,0x10001
    80005d7c:	43dc                	lw	a5,4(a5)
    80005d7e:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005d80:	4705                	li	a4,1
    80005d82:	0ce79a63          	bne	a5,a4,80005e56 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005d86:	100017b7          	lui	a5,0x10001
    80005d8a:	479c                	lw	a5,8(a5)
    80005d8c:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005d8e:	4709                	li	a4,2
    80005d90:	0ce79363          	bne	a5,a4,80005e56 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005d94:	100017b7          	lui	a5,0x10001
    80005d98:	47d8                	lw	a4,12(a5)
    80005d9a:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005d9c:	554d47b7          	lui	a5,0x554d4
    80005da0:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005da4:	0af71963          	bne	a4,a5,80005e56 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005da8:	100017b7          	lui	a5,0x10001
    80005dac:	4705                	li	a4,1
    80005dae:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005db0:	470d                	li	a4,3
    80005db2:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005db4:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80005db6:	c7ffe737          	lui	a4,0xc7ffe
    80005dba:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    80005dbe:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005dc0:	2701                	sext.w	a4,a4
    80005dc2:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005dc4:	472d                	li	a4,11
    80005dc6:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005dc8:	473d                	li	a4,15
    80005dca:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    80005dcc:	6705                	lui	a4,0x1
    80005dce:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005dd0:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005dd4:	5bdc                	lw	a5,52(a5)
    80005dd6:	2781                	sext.w	a5,a5
  if(max == 0)
    80005dd8:	c7d9                	beqz	a5,80005e66 <virtio_disk_init+0x124>
  if(max < NUM)
    80005dda:	471d                	li	a4,7
    80005ddc:	08f77d63          	bgeu	a4,a5,80005e76 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80005de0:	100014b7          	lui	s1,0x10001
    80005de4:	47a1                	li	a5,8
    80005de6:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80005de8:	6609                	lui	a2,0x2
    80005dea:	4581                	li	a1,0
    80005dec:	0001d517          	auipc	a0,0x1d
    80005df0:	21450513          	addi	a0,a0,532 # 80023000 <disk>
    80005df4:	ffffb097          	auipc	ra,0xffffb
    80005df8:	eec080e7          	jalr	-276(ra) # 80000ce0 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    80005dfc:	0001d717          	auipc	a4,0x1d
    80005e00:	20470713          	addi	a4,a4,516 # 80023000 <disk>
    80005e04:	00c75793          	srli	a5,a4,0xc
    80005e08:	2781                	sext.w	a5,a5
    80005e0a:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    80005e0c:	0001f797          	auipc	a5,0x1f
    80005e10:	1f478793          	addi	a5,a5,500 # 80025000 <disk+0x2000>
    80005e14:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80005e16:	0001d717          	auipc	a4,0x1d
    80005e1a:	26a70713          	addi	a4,a4,618 # 80023080 <disk+0x80>
    80005e1e:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80005e20:	0001e717          	auipc	a4,0x1e
    80005e24:	1e070713          	addi	a4,a4,480 # 80024000 <disk+0x1000>
    80005e28:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    80005e2a:	4705                	li	a4,1
    80005e2c:	00e78c23          	sb	a4,24(a5)
    80005e30:	00e78ca3          	sb	a4,25(a5)
    80005e34:	00e78d23          	sb	a4,26(a5)
    80005e38:	00e78da3          	sb	a4,27(a5)
    80005e3c:	00e78e23          	sb	a4,28(a5)
    80005e40:	00e78ea3          	sb	a4,29(a5)
    80005e44:	00e78f23          	sb	a4,30(a5)
    80005e48:	00e78fa3          	sb	a4,31(a5)
}
    80005e4c:	60e2                	ld	ra,24(sp)
    80005e4e:	6442                	ld	s0,16(sp)
    80005e50:	64a2                	ld	s1,8(sp)
    80005e52:	6105                	addi	sp,sp,32
    80005e54:	8082                	ret
    panic("could not find virtio disk");
    80005e56:	00003517          	auipc	a0,0x3
    80005e5a:	94a50513          	addi	a0,a0,-1718 # 800087a0 <syscalls+0x350>
    80005e5e:	ffffa097          	auipc	ra,0xffffa
    80005e62:	6e0080e7          	jalr	1760(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    80005e66:	00003517          	auipc	a0,0x3
    80005e6a:	95a50513          	addi	a0,a0,-1702 # 800087c0 <syscalls+0x370>
    80005e6e:	ffffa097          	auipc	ra,0xffffa
    80005e72:	6d0080e7          	jalr	1744(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    80005e76:	00003517          	auipc	a0,0x3
    80005e7a:	96a50513          	addi	a0,a0,-1686 # 800087e0 <syscalls+0x390>
    80005e7e:	ffffa097          	auipc	ra,0xffffa
    80005e82:	6c0080e7          	jalr	1728(ra) # 8000053e <panic>

0000000080005e86 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80005e86:	7159                	addi	sp,sp,-112
    80005e88:	f486                	sd	ra,104(sp)
    80005e8a:	f0a2                	sd	s0,96(sp)
    80005e8c:	eca6                	sd	s1,88(sp)
    80005e8e:	e8ca                	sd	s2,80(sp)
    80005e90:	e4ce                	sd	s3,72(sp)
    80005e92:	e0d2                	sd	s4,64(sp)
    80005e94:	fc56                	sd	s5,56(sp)
    80005e96:	f85a                	sd	s6,48(sp)
    80005e98:	f45e                	sd	s7,40(sp)
    80005e9a:	f062                	sd	s8,32(sp)
    80005e9c:	ec66                	sd	s9,24(sp)
    80005e9e:	e86a                	sd	s10,16(sp)
    80005ea0:	1880                	addi	s0,sp,112
    80005ea2:	892a                	mv	s2,a0
    80005ea4:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80005ea6:	00c52c83          	lw	s9,12(a0)
    80005eaa:	001c9c9b          	slliw	s9,s9,0x1
    80005eae:	1c82                	slli	s9,s9,0x20
    80005eb0:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80005eb4:	0001f517          	auipc	a0,0x1f
    80005eb8:	27450513          	addi	a0,a0,628 # 80025128 <disk+0x2128>
    80005ebc:	ffffb097          	auipc	ra,0xffffb
    80005ec0:	d28080e7          	jalr	-728(ra) # 80000be4 <acquire>
  for(int i = 0; i < 3; i++){
    80005ec4:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80005ec6:	4c21                	li	s8,8
      disk.free[i] = 0;
    80005ec8:	0001db97          	auipc	s7,0x1d
    80005ecc:	138b8b93          	addi	s7,s7,312 # 80023000 <disk>
    80005ed0:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    80005ed2:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80005ed4:	8a4e                	mv	s4,s3
    80005ed6:	a051                	j	80005f5a <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    80005ed8:	00fb86b3          	add	a3,s7,a5
    80005edc:	96da                	add	a3,a3,s6
    80005ede:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80005ee2:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    80005ee4:	0207c563          	bltz	a5,80005f0e <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80005ee8:	2485                	addiw	s1,s1,1
    80005eea:	0711                	addi	a4,a4,4
    80005eec:	25548063          	beq	s1,s5,8000612c <virtio_disk_rw+0x2a6>
    idx[i] = alloc_desc();
    80005ef0:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80005ef2:	0001f697          	auipc	a3,0x1f
    80005ef6:	12668693          	addi	a3,a3,294 # 80025018 <disk+0x2018>
    80005efa:	87d2                	mv	a5,s4
    if(disk.free[i]){
    80005efc:	0006c583          	lbu	a1,0(a3)
    80005f00:	fde1                	bnez	a1,80005ed8 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80005f02:	2785                	addiw	a5,a5,1
    80005f04:	0685                	addi	a3,a3,1
    80005f06:	ff879be3          	bne	a5,s8,80005efc <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    80005f0a:	57fd                	li	a5,-1
    80005f0c:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    80005f0e:	02905a63          	blez	s1,80005f42 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80005f12:	f9042503          	lw	a0,-112(s0)
    80005f16:	00000097          	auipc	ra,0x0
    80005f1a:	d90080e7          	jalr	-624(ra) # 80005ca6 <free_desc>
      for(int j = 0; j < i; j++)
    80005f1e:	4785                	li	a5,1
    80005f20:	0297d163          	bge	a5,s1,80005f42 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80005f24:	f9442503          	lw	a0,-108(s0)
    80005f28:	00000097          	auipc	ra,0x0
    80005f2c:	d7e080e7          	jalr	-642(ra) # 80005ca6 <free_desc>
      for(int j = 0; j < i; j++)
    80005f30:	4789                	li	a5,2
    80005f32:	0097d863          	bge	a5,s1,80005f42 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80005f36:	f9842503          	lw	a0,-104(s0)
    80005f3a:	00000097          	auipc	ra,0x0
    80005f3e:	d6c080e7          	jalr	-660(ra) # 80005ca6 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80005f42:	0001f597          	auipc	a1,0x1f
    80005f46:	1e658593          	addi	a1,a1,486 # 80025128 <disk+0x2128>
    80005f4a:	0001f517          	auipc	a0,0x1f
    80005f4e:	0ce50513          	addi	a0,a0,206 # 80025018 <disk+0x2018>
    80005f52:	ffffc097          	auipc	ra,0xffffc
    80005f56:	196080e7          	jalr	406(ra) # 800020e8 <sleep>
  for(int i = 0; i < 3; i++){
    80005f5a:	f9040713          	addi	a4,s0,-112
    80005f5e:	84ce                	mv	s1,s3
    80005f60:	bf41                	j	80005ef0 <virtio_disk_rw+0x6a>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    80005f62:	20058713          	addi	a4,a1,512
    80005f66:	00471693          	slli	a3,a4,0x4
    80005f6a:	0001d717          	auipc	a4,0x1d
    80005f6e:	09670713          	addi	a4,a4,150 # 80023000 <disk>
    80005f72:	9736                	add	a4,a4,a3
    80005f74:	4685                	li	a3,1
    80005f76:	0ad72423          	sw	a3,168(a4)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    80005f7a:	20058713          	addi	a4,a1,512
    80005f7e:	00471693          	slli	a3,a4,0x4
    80005f82:	0001d717          	auipc	a4,0x1d
    80005f86:	07e70713          	addi	a4,a4,126 # 80023000 <disk>
    80005f8a:	9736                	add	a4,a4,a3
    80005f8c:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    80005f90:	0b973823          	sd	s9,176(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80005f94:	7679                	lui	a2,0xffffe
    80005f96:	963e                	add	a2,a2,a5
    80005f98:	0001f697          	auipc	a3,0x1f
    80005f9c:	06868693          	addi	a3,a3,104 # 80025000 <disk+0x2000>
    80005fa0:	6298                	ld	a4,0(a3)
    80005fa2:	9732                	add	a4,a4,a2
    80005fa4:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80005fa6:	6298                	ld	a4,0(a3)
    80005fa8:	9732                	add	a4,a4,a2
    80005faa:	4541                	li	a0,16
    80005fac:	c708                	sw	a0,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80005fae:	6298                	ld	a4,0(a3)
    80005fb0:	9732                	add	a4,a4,a2
    80005fb2:	4505                	li	a0,1
    80005fb4:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[0]].next = idx[1];
    80005fb8:	f9442703          	lw	a4,-108(s0)
    80005fbc:	6288                	ld	a0,0(a3)
    80005fbe:	962a                	add	a2,a2,a0
    80005fc0:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd800e>

  disk.desc[idx[1]].addr = (uint64) b->data;
    80005fc4:	0712                	slli	a4,a4,0x4
    80005fc6:	6290                	ld	a2,0(a3)
    80005fc8:	963a                	add	a2,a2,a4
    80005fca:	05890513          	addi	a0,s2,88
    80005fce:	e208                	sd	a0,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    80005fd0:	6294                	ld	a3,0(a3)
    80005fd2:	96ba                	add	a3,a3,a4
    80005fd4:	40000613          	li	a2,1024
    80005fd8:	c690                	sw	a2,8(a3)
  if(write)
    80005fda:	140d0063          	beqz	s10,8000611a <virtio_disk_rw+0x294>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    80005fde:	0001f697          	auipc	a3,0x1f
    80005fe2:	0226b683          	ld	a3,34(a3) # 80025000 <disk+0x2000>
    80005fe6:	96ba                	add	a3,a3,a4
    80005fe8:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80005fec:	0001d817          	auipc	a6,0x1d
    80005ff0:	01480813          	addi	a6,a6,20 # 80023000 <disk>
    80005ff4:	0001f517          	auipc	a0,0x1f
    80005ff8:	00c50513          	addi	a0,a0,12 # 80025000 <disk+0x2000>
    80005ffc:	6114                	ld	a3,0(a0)
    80005ffe:	96ba                	add	a3,a3,a4
    80006000:	00c6d603          	lhu	a2,12(a3)
    80006004:	00166613          	ori	a2,a2,1
    80006008:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    8000600c:	f9842683          	lw	a3,-104(s0)
    80006010:	6110                	ld	a2,0(a0)
    80006012:	9732                	add	a4,a4,a2
    80006014:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006018:	20058613          	addi	a2,a1,512
    8000601c:	0612                	slli	a2,a2,0x4
    8000601e:	9642                	add	a2,a2,a6
    80006020:	577d                	li	a4,-1
    80006022:	02e60823          	sb	a4,48(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006026:	00469713          	slli	a4,a3,0x4
    8000602a:	6114                	ld	a3,0(a0)
    8000602c:	96ba                	add	a3,a3,a4
    8000602e:	03078793          	addi	a5,a5,48
    80006032:	97c2                	add	a5,a5,a6
    80006034:	e29c                	sd	a5,0(a3)
  disk.desc[idx[2]].len = 1;
    80006036:	611c                	ld	a5,0(a0)
    80006038:	97ba                	add	a5,a5,a4
    8000603a:	4685                	li	a3,1
    8000603c:	c794                	sw	a3,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    8000603e:	611c                	ld	a5,0(a0)
    80006040:	97ba                	add	a5,a5,a4
    80006042:	4809                	li	a6,2
    80006044:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80006048:	611c                	ld	a5,0(a0)
    8000604a:	973e                	add	a4,a4,a5
    8000604c:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006050:	00d92223          	sw	a3,4(s2)
  disk.info[idx[0]].b = b;
    80006054:	03263423          	sd	s2,40(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006058:	6518                	ld	a4,8(a0)
    8000605a:	00275783          	lhu	a5,2(a4)
    8000605e:	8b9d                	andi	a5,a5,7
    80006060:	0786                	slli	a5,a5,0x1
    80006062:	97ba                	add	a5,a5,a4
    80006064:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    80006068:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    8000606c:	6518                	ld	a4,8(a0)
    8000606e:	00275783          	lhu	a5,2(a4)
    80006072:	2785                	addiw	a5,a5,1
    80006074:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006078:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    8000607c:	100017b7          	lui	a5,0x10001
    80006080:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006084:	00492703          	lw	a4,4(s2)
    80006088:	4785                	li	a5,1
    8000608a:	02f71163          	bne	a4,a5,800060ac <virtio_disk_rw+0x226>
    sleep(b, &disk.vdisk_lock);
    8000608e:	0001f997          	auipc	s3,0x1f
    80006092:	09a98993          	addi	s3,s3,154 # 80025128 <disk+0x2128>
  while(b->disk == 1) {
    80006096:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006098:	85ce                	mv	a1,s3
    8000609a:	854a                	mv	a0,s2
    8000609c:	ffffc097          	auipc	ra,0xffffc
    800060a0:	04c080e7          	jalr	76(ra) # 800020e8 <sleep>
  while(b->disk == 1) {
    800060a4:	00492783          	lw	a5,4(s2)
    800060a8:	fe9788e3          	beq	a5,s1,80006098 <virtio_disk_rw+0x212>
  }

  disk.info[idx[0]].b = 0;
    800060ac:	f9042903          	lw	s2,-112(s0)
    800060b0:	20090793          	addi	a5,s2,512
    800060b4:	00479713          	slli	a4,a5,0x4
    800060b8:	0001d797          	auipc	a5,0x1d
    800060bc:	f4878793          	addi	a5,a5,-184 # 80023000 <disk>
    800060c0:	97ba                	add	a5,a5,a4
    800060c2:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    800060c6:	0001f997          	auipc	s3,0x1f
    800060ca:	f3a98993          	addi	s3,s3,-198 # 80025000 <disk+0x2000>
    800060ce:	00491713          	slli	a4,s2,0x4
    800060d2:	0009b783          	ld	a5,0(s3)
    800060d6:	97ba                	add	a5,a5,a4
    800060d8:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    800060dc:	854a                	mv	a0,s2
    800060de:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    800060e2:	00000097          	auipc	ra,0x0
    800060e6:	bc4080e7          	jalr	-1084(ra) # 80005ca6 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    800060ea:	8885                	andi	s1,s1,1
    800060ec:	f0ed                	bnez	s1,800060ce <virtio_disk_rw+0x248>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800060ee:	0001f517          	auipc	a0,0x1f
    800060f2:	03a50513          	addi	a0,a0,58 # 80025128 <disk+0x2128>
    800060f6:	ffffb097          	auipc	ra,0xffffb
    800060fa:	ba2080e7          	jalr	-1118(ra) # 80000c98 <release>
}
    800060fe:	70a6                	ld	ra,104(sp)
    80006100:	7406                	ld	s0,96(sp)
    80006102:	64e6                	ld	s1,88(sp)
    80006104:	6946                	ld	s2,80(sp)
    80006106:	69a6                	ld	s3,72(sp)
    80006108:	6a06                	ld	s4,64(sp)
    8000610a:	7ae2                	ld	s5,56(sp)
    8000610c:	7b42                	ld	s6,48(sp)
    8000610e:	7ba2                	ld	s7,40(sp)
    80006110:	7c02                	ld	s8,32(sp)
    80006112:	6ce2                	ld	s9,24(sp)
    80006114:	6d42                	ld	s10,16(sp)
    80006116:	6165                	addi	sp,sp,112
    80006118:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000611a:	0001f697          	auipc	a3,0x1f
    8000611e:	ee66b683          	ld	a3,-282(a3) # 80025000 <disk+0x2000>
    80006122:	96ba                	add	a3,a3,a4
    80006124:	4609                	li	a2,2
    80006126:	00c69623          	sh	a2,12(a3)
    8000612a:	b5c9                	j	80005fec <virtio_disk_rw+0x166>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    8000612c:	f9042583          	lw	a1,-112(s0)
    80006130:	20058793          	addi	a5,a1,512
    80006134:	0792                	slli	a5,a5,0x4
    80006136:	0001d517          	auipc	a0,0x1d
    8000613a:	f7250513          	addi	a0,a0,-142 # 800230a8 <disk+0xa8>
    8000613e:	953e                	add	a0,a0,a5
  if(write)
    80006140:	e20d11e3          	bnez	s10,80005f62 <virtio_disk_rw+0xdc>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    80006144:	20058713          	addi	a4,a1,512
    80006148:	00471693          	slli	a3,a4,0x4
    8000614c:	0001d717          	auipc	a4,0x1d
    80006150:	eb470713          	addi	a4,a4,-332 # 80023000 <disk>
    80006154:	9736                	add	a4,a4,a3
    80006156:	0a072423          	sw	zero,168(a4)
    8000615a:	b505                	j	80005f7a <virtio_disk_rw+0xf4>

000000008000615c <virtio_disk_intr>:

void
virtio_disk_intr()
{
    8000615c:	1101                	addi	sp,sp,-32
    8000615e:	ec06                	sd	ra,24(sp)
    80006160:	e822                	sd	s0,16(sp)
    80006162:	e426                	sd	s1,8(sp)
    80006164:	e04a                	sd	s2,0(sp)
    80006166:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006168:	0001f517          	auipc	a0,0x1f
    8000616c:	fc050513          	addi	a0,a0,-64 # 80025128 <disk+0x2128>
    80006170:	ffffb097          	auipc	ra,0xffffb
    80006174:	a74080e7          	jalr	-1420(ra) # 80000be4 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006178:	10001737          	lui	a4,0x10001
    8000617c:	533c                	lw	a5,96(a4)
    8000617e:	8b8d                	andi	a5,a5,3
    80006180:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006182:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006186:	0001f797          	auipc	a5,0x1f
    8000618a:	e7a78793          	addi	a5,a5,-390 # 80025000 <disk+0x2000>
    8000618e:	6b94                	ld	a3,16(a5)
    80006190:	0207d703          	lhu	a4,32(a5)
    80006194:	0026d783          	lhu	a5,2(a3)
    80006198:	06f70163          	beq	a4,a5,800061fa <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    8000619c:	0001d917          	auipc	s2,0x1d
    800061a0:	e6490913          	addi	s2,s2,-412 # 80023000 <disk>
    800061a4:	0001f497          	auipc	s1,0x1f
    800061a8:	e5c48493          	addi	s1,s1,-420 # 80025000 <disk+0x2000>
    __sync_synchronize();
    800061ac:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800061b0:	6898                	ld	a4,16(s1)
    800061b2:	0204d783          	lhu	a5,32(s1)
    800061b6:	8b9d                	andi	a5,a5,7
    800061b8:	078e                	slli	a5,a5,0x3
    800061ba:	97ba                	add	a5,a5,a4
    800061bc:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    800061be:	20078713          	addi	a4,a5,512
    800061c2:	0712                	slli	a4,a4,0x4
    800061c4:	974a                	add	a4,a4,s2
    800061c6:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    800061ca:	e731                	bnez	a4,80006216 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    800061cc:	20078793          	addi	a5,a5,512
    800061d0:	0792                	slli	a5,a5,0x4
    800061d2:	97ca                	add	a5,a5,s2
    800061d4:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    800061d6:	00052223          	sw	zero,4(a0)
    wakeup(b);
    800061da:	ffffc097          	auipc	ra,0xffffc
    800061de:	09a080e7          	jalr	154(ra) # 80002274 <wakeup>

    disk.used_idx += 1;
    800061e2:	0204d783          	lhu	a5,32(s1)
    800061e6:	2785                	addiw	a5,a5,1
    800061e8:	17c2                	slli	a5,a5,0x30
    800061ea:	93c1                	srli	a5,a5,0x30
    800061ec:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    800061f0:	6898                	ld	a4,16(s1)
    800061f2:	00275703          	lhu	a4,2(a4)
    800061f6:	faf71be3          	bne	a4,a5,800061ac <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    800061fa:	0001f517          	auipc	a0,0x1f
    800061fe:	f2e50513          	addi	a0,a0,-210 # 80025128 <disk+0x2128>
    80006202:	ffffb097          	auipc	ra,0xffffb
    80006206:	a96080e7          	jalr	-1386(ra) # 80000c98 <release>
}
    8000620a:	60e2                	ld	ra,24(sp)
    8000620c:	6442                	ld	s0,16(sp)
    8000620e:	64a2                	ld	s1,8(sp)
    80006210:	6902                	ld	s2,0(sp)
    80006212:	6105                	addi	sp,sp,32
    80006214:	8082                	ret
      panic("virtio_disk_intr status");
    80006216:	00002517          	auipc	a0,0x2
    8000621a:	5ea50513          	addi	a0,a0,1514 # 80008800 <syscalls+0x3b0>
    8000621e:	ffffa097          	auipc	ra,0xffffa
    80006222:	320080e7          	jalr	800(ra) # 8000053e <panic>
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
