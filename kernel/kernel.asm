
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00010117          	auipc	sp,0x10
    80000004:	18010113          	addi	sp,sp,384 # 80010180 <stack0>
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
    80000052:	00010717          	auipc	a4,0x10
    80000056:	fee70713          	addi	a4,a4,-18 # 80010040 <timer_scratch>
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
    80000068:	b3c78793          	addi	a5,a5,-1220 # 80005ba0 <timervec>
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
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffb67ff>
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
    80000130:	3c6080e7          	jalr	966(ra) # 800024f2 <either_copyin>
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
    8000018c:	00018517          	auipc	a0,0x18
    80000190:	ff450513          	addi	a0,a0,-12 # 80018180 <cons>
    80000194:	00001097          	auipc	ra,0x1
    80000198:	a50080e7          	jalr	-1456(ra) # 80000be4 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019c:	00018497          	auipc	s1,0x18
    800001a0:	fe448493          	addi	s1,s1,-28 # 80018180 <cons>
      if(myproc()->killed){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a4:	89a6                	mv	s3,s1
    800001a6:	00018917          	auipc	s2,0x18
    800001aa:	07290913          	addi	s2,s2,114 # 80018218 <cons+0x98>
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
    800001c8:	878080e7          	jalr	-1928(ra) # 80001a3c <myproc>
    800001cc:	551c                	lw	a5,40(a0)
    800001ce:	e7b5                	bnez	a5,8000023a <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    800001d0:	85ce                	mv	a1,s3
    800001d2:	854a                	mv	a0,s2
    800001d4:	00002097          	auipc	ra,0x2
    800001d8:	f24080e7          	jalr	-220(ra) # 800020f8 <sleep>
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
    80000214:	28c080e7          	jalr	652(ra) # 8000249c <either_copyout>
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
    80000224:	00018517          	auipc	a0,0x18
    80000228:	f5c50513          	addi	a0,a0,-164 # 80018180 <cons>
    8000022c:	00001097          	auipc	ra,0x1
    80000230:	a6c080e7          	jalr	-1428(ra) # 80000c98 <release>

  return target - n;
    80000234:	414b853b          	subw	a0,s7,s4
    80000238:	a811                	j	8000024c <consoleread+0xe8>
        release(&cons.lock);
    8000023a:	00018517          	auipc	a0,0x18
    8000023e:	f4650513          	addi	a0,a0,-186 # 80018180 <cons>
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
    80000272:	00018717          	auipc	a4,0x18
    80000276:	faf72323          	sw	a5,-90(a4) # 80018218 <cons+0x98>
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
    800002cc:	00018517          	auipc	a0,0x18
    800002d0:	eb450513          	addi	a0,a0,-332 # 80018180 <cons>
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
    800002f6:	256080e7          	jalr	598(ra) # 80002548 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002fa:	00018517          	auipc	a0,0x18
    800002fe:	e8650513          	addi	a0,a0,-378 # 80018180 <cons>
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
    8000031e:	00018717          	auipc	a4,0x18
    80000322:	e6270713          	addi	a4,a4,-414 # 80018180 <cons>
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
    80000348:	00018797          	auipc	a5,0x18
    8000034c:	e3878793          	addi	a5,a5,-456 # 80018180 <cons>
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
    80000376:	00018797          	auipc	a5,0x18
    8000037a:	ea27a783          	lw	a5,-350(a5) # 80018218 <cons+0x98>
    8000037e:	0807879b          	addiw	a5,a5,128
    80000382:	f6f61ce3          	bne	a2,a5,800002fa <consoleintr+0x3c>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000386:	863e                	mv	a2,a5
    80000388:	a07d                	j	80000436 <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000038a:	00018717          	auipc	a4,0x18
    8000038e:	df670713          	addi	a4,a4,-522 # 80018180 <cons>
    80000392:	0a072783          	lw	a5,160(a4)
    80000396:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    8000039a:	00018497          	auipc	s1,0x18
    8000039e:	de648493          	addi	s1,s1,-538 # 80018180 <cons>
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
    800003d6:	00018717          	auipc	a4,0x18
    800003da:	daa70713          	addi	a4,a4,-598 # 80018180 <cons>
    800003de:	0a072783          	lw	a5,160(a4)
    800003e2:	09c72703          	lw	a4,156(a4)
    800003e6:	f0f70ae3          	beq	a4,a5,800002fa <consoleintr+0x3c>
      cons.e--;
    800003ea:	37fd                	addiw	a5,a5,-1
    800003ec:	00018717          	auipc	a4,0x18
    800003f0:	e2f72a23          	sw	a5,-460(a4) # 80018220 <cons+0xa0>
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
    80000412:	00018797          	auipc	a5,0x18
    80000416:	d6e78793          	addi	a5,a5,-658 # 80018180 <cons>
    8000041a:	0a07a703          	lw	a4,160(a5)
    8000041e:	0017069b          	addiw	a3,a4,1
    80000422:	0006861b          	sext.w	a2,a3
    80000426:	0ad7a023          	sw	a3,160(a5)
    8000042a:	07f77713          	andi	a4,a4,127
    8000042e:	97ba                	add	a5,a5,a4
    80000430:	4729                	li	a4,10
    80000432:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000436:	00018797          	auipc	a5,0x18
    8000043a:	dec7a323          	sw	a2,-538(a5) # 8001821c <cons+0x9c>
        wakeup(&cons.r);
    8000043e:	00018517          	auipc	a0,0x18
    80000442:	dda50513          	addi	a0,a0,-550 # 80018218 <cons+0x98>
    80000446:	00002097          	auipc	ra,0x2
    8000044a:	e3e080e7          	jalr	-450(ra) # 80002284 <wakeup>
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
    80000460:	00018517          	auipc	a0,0x18
    80000464:	d2050513          	addi	a0,a0,-736 # 80018180 <cons>
    80000468:	00000097          	auipc	ra,0x0
    8000046c:	6ec080e7          	jalr	1772(ra) # 80000b54 <initlock>

	uartinit();
    80000470:	00000097          	auipc	ra,0x0
    80000474:	330080e7          	jalr	816(ra) # 800007a0 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000478:	00028797          	auipc	a5,0x28
    8000047c:	ea078793          	addi	a5,a5,-352 # 80028318 <devsw>
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
    8000054a:	00018797          	auipc	a5,0x18
    8000054e:	ce07ab23          	sw	zero,-778(a5) # 80018240 <pr+0x18>
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
    8000057e:	00010717          	auipc	a4,0x10
    80000582:	a8f72123          	sw	a5,-1406(a4) # 80010000 <panicked>
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
    800005ba:	00018d97          	auipc	s11,0x18
    800005be:	c86dad83          	lw	s11,-890(s11) # 80018240 <pr+0x18>
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
    800005f8:	00018517          	auipc	a0,0x18
    800005fc:	c3050513          	addi	a0,a0,-976 # 80018228 <pr>
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
    8000075c:	00018517          	auipc	a0,0x18
    80000760:	acc50513          	addi	a0,a0,-1332 # 80018228 <pr>
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
    80000778:	00018497          	auipc	s1,0x18
    8000077c:	ab048493          	addi	s1,s1,-1360 # 80018228 <pr>
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
    800007d8:	00018517          	auipc	a0,0x18
    800007dc:	a7050513          	addi	a0,a0,-1424 # 80018248 <uart_tx_lock>
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
    80000804:	0000f797          	auipc	a5,0xf
    80000808:	7fc7a783          	lw	a5,2044(a5) # 80010000 <panicked>
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
    80000840:	0000f717          	auipc	a4,0xf
    80000844:	7c873703          	ld	a4,1992(a4) # 80010008 <uart_tx_r>
    80000848:	0000f797          	auipc	a5,0xf
    8000084c:	7c87b783          	ld	a5,1992(a5) # 80010010 <uart_tx_w>
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
    8000086a:	00018a17          	auipc	s4,0x18
    8000086e:	9dea0a13          	addi	s4,s4,-1570 # 80018248 <uart_tx_lock>
    uart_tx_r += 1;
    80000872:	0000f497          	auipc	s1,0xf
    80000876:	79648493          	addi	s1,s1,1942 # 80010008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    8000087a:	0000f997          	auipc	s3,0xf
    8000087e:	79698993          	addi	s3,s3,1942 # 80010010 <uart_tx_w>
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
    800008a4:	9e4080e7          	jalr	-1564(ra) # 80002284 <wakeup>
    
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
    800008dc:	00018517          	auipc	a0,0x18
    800008e0:	96c50513          	addi	a0,a0,-1684 # 80018248 <uart_tx_lock>
    800008e4:	00000097          	auipc	ra,0x0
    800008e8:	300080e7          	jalr	768(ra) # 80000be4 <acquire>
  if(panicked){
    800008ec:	0000f797          	auipc	a5,0xf
    800008f0:	7147a783          	lw	a5,1812(a5) # 80010000 <panicked>
    800008f4:	c391                	beqz	a5,800008f8 <uartputc+0x2e>
    for(;;)
    800008f6:	a001                	j	800008f6 <uartputc+0x2c>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008f8:	0000f797          	auipc	a5,0xf
    800008fc:	7187b783          	ld	a5,1816(a5) # 80010010 <uart_tx_w>
    80000900:	0000f717          	auipc	a4,0xf
    80000904:	70873703          	ld	a4,1800(a4) # 80010008 <uart_tx_r>
    80000908:	02070713          	addi	a4,a4,32
    8000090c:	02f71b63          	bne	a4,a5,80000942 <uartputc+0x78>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000910:	00018a17          	auipc	s4,0x18
    80000914:	938a0a13          	addi	s4,s4,-1736 # 80018248 <uart_tx_lock>
    80000918:	0000f497          	auipc	s1,0xf
    8000091c:	6f048493          	addi	s1,s1,1776 # 80010008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000920:	0000f917          	auipc	s2,0xf
    80000924:	6f090913          	addi	s2,s2,1776 # 80010010 <uart_tx_w>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000928:	85d2                	mv	a1,s4
    8000092a:	8526                	mv	a0,s1
    8000092c:	00001097          	auipc	ra,0x1
    80000930:	7cc080e7          	jalr	1996(ra) # 800020f8 <sleep>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000934:	00093783          	ld	a5,0(s2)
    80000938:	6098                	ld	a4,0(s1)
    8000093a:	02070713          	addi	a4,a4,32
    8000093e:	fef705e3          	beq	a4,a5,80000928 <uartputc+0x5e>
      uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000942:	00018497          	auipc	s1,0x18
    80000946:	90648493          	addi	s1,s1,-1786 # 80018248 <uart_tx_lock>
    8000094a:	01f7f713          	andi	a4,a5,31
    8000094e:	9726                	add	a4,a4,s1
    80000950:	01370c23          	sb	s3,24(a4)
      uart_tx_w += 1;
    80000954:	0785                	addi	a5,a5,1
    80000956:	0000f717          	auipc	a4,0xf
    8000095a:	6af73d23          	sd	a5,1722(a4) # 80010010 <uart_tx_w>
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
    800009ca:	00018497          	auipc	s1,0x18
    800009ce:	87e48493          	addi	s1,s1,-1922 # 80018248 <uart_tx_lock>
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
    80000a04:	03151793          	slli	a5,a0,0x31
    80000a08:	ebb9                	bnez	a5,80000a5e <kfree+0x66>
    80000a0a:	84aa                	mv	s1,a0
    80000a0c:	00047797          	auipc	a5,0x47
    80000a10:	5f478793          	addi	a5,a5,1524 # 80048000 <end>
    80000a14:	04f56563          	bltu	a0,a5,80000a5e <kfree+0x66>
    80000a18:	47c5                	li	a5,17
    80000a1a:	07ee                	slli	a5,a5,0x1b
    80000a1c:	04f57163          	bgeu	a0,a5,80000a5e <kfree+0x66>
		panic("kfree");

	// Fill with junk to catch dangling refs.
	memset(pa, 1, PGSIZE);
    80000a20:	6621                	lui	a2,0x8
    80000a22:	4585                	li	a1,1
    80000a24:	00000097          	auipc	ra,0x0
    80000a28:	2bc080e7          	jalr	700(ra) # 80000ce0 <memset>

	r = (struct run*)pa;

	acquire(&kmem.lock);
    80000a2c:	00018917          	auipc	s2,0x18
    80000a30:	85490913          	addi	s2,s2,-1964 # 80018280 <kmem>
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
    80000a7e:	67a1                	lui	a5,0x8
    80000a80:	fff78493          	addi	s1,a5,-1 # 7fff <_entry-0x7fff8001>
    80000a84:	94aa                	add	s1,s1,a0
    80000a86:	7561                	lui	a0,0xffff8
    80000a88:	8ce9                	and	s1,s1,a0
	for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a8a:	94be                	add	s1,s1,a5
    80000a8c:	0095ee63          	bltu	a1,s1,80000aa8 <freerange+0x3a>
    80000a90:	892e                	mv	s2,a1
		kfree(p);
    80000a92:	7a61                	lui	s4,0xffff8
	for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a94:	69a1                	lui	s3,0x8
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
    80000ac8:	00017517          	auipc	a0,0x17
    80000acc:	7b850513          	addi	a0,a0,1976 # 80018280 <kmem>
    80000ad0:	00000097          	auipc	ra,0x0
    80000ad4:	084080e7          	jalr	132(ra) # 80000b54 <initlock>
	freerange(end, (void*)PHYSTOP);
    80000ad8:	45c5                	li	a1,17
    80000ada:	05ee                	slli	a1,a1,0x1b
    80000adc:	00047517          	auipc	a0,0x47
    80000ae0:	52450513          	addi	a0,a0,1316 # 80048000 <end>
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
    80000afe:	00017497          	auipc	s1,0x17
    80000b02:	78248493          	addi	s1,s1,1922 # 80018280 <kmem>
    80000b06:	8526                	mv	a0,s1
    80000b08:	00000097          	auipc	ra,0x0
    80000b0c:	0dc080e7          	jalr	220(ra) # 80000be4 <acquire>
	r = kmem.freelist;
    80000b10:	6c84                	ld	s1,24(s1)
	if(r)
    80000b12:	c885                	beqz	s1,80000b42 <kalloc+0x4e>
		kmem.freelist = r->next;
    80000b14:	609c                	ld	a5,0(s1)
    80000b16:	00017517          	auipc	a0,0x17
    80000b1a:	76a50513          	addi	a0,a0,1898 # 80018280 <kmem>
    80000b1e:	ed1c                	sd	a5,24(a0)
	release(&kmem.lock);
    80000b20:	00000097          	auipc	ra,0x0
    80000b24:	178080e7          	jalr	376(ra) # 80000c98 <release>

	if(r)
		memset((char*)r, 5, PGSIZE); // fill with junk
    80000b28:	6621                	lui	a2,0x8
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
    80000b42:	00017517          	auipc	a0,0x17
    80000b46:	73e50513          	addi	a0,a0,1854 # 80018280 <kmem>
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
    80000b82:	ea2080e7          	jalr	-350(ra) # 80001a20 <mycpu>
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
    80000bb4:	e70080e7          	jalr	-400(ra) # 80001a20 <mycpu>
    80000bb8:	5d3c                	lw	a5,120(a0)
    80000bba:	cf89                	beqz	a5,80000bd4 <push_off+0x3c>
		mycpu()->intena = old;
	mycpu()->noff += 1;
    80000bbc:	00001097          	auipc	ra,0x1
    80000bc0:	e64080e7          	jalr	-412(ra) # 80001a20 <mycpu>
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
    80000bd8:	e4c080e7          	jalr	-436(ra) # 80001a20 <mycpu>
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
    80000c18:	e0c080e7          	jalr	-500(ra) # 80001a20 <mycpu>
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
    80000c44:	de0080e7          	jalr	-544(ra) # 80001a20 <mycpu>
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
    80000e9a:	b7a080e7          	jalr	-1158(ra) # 80001a10 <cpuid>
    virtio_disk_init(); // emulated hard disk
		userinit();      // first user process
		__sync_synchronize();
		started = 1;
	} else {
		while(started == 0)
    80000e9e:	0000f717          	auipc	a4,0xf
    80000ea2:	17a70713          	addi	a4,a4,378 # 80010018 <started>
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
    80000eb6:	b5e080e7          	jalr	-1186(ra) # 80001a10 <cpuid>
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
    80000ed8:	7b4080e7          	jalr	1972(ra) # 80002688 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000edc:	00005097          	auipc	ra,0x5
    80000ee0:	d04080e7          	jalr	-764(ra) # 80005be0 <plicinithart>
	}

	scheduler();
    80000ee4:	00001097          	auipc	ra,0x1
    80000ee8:	062080e7          	jalr	98(ra) # 80001f46 <scheduler>
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
    80000f38:	332080e7          	jalr	818(ra) # 80001266 <kvminit>
		kvminithart();   // turn on paging
    80000f3c:	00000097          	auipc	ra,0x0
    80000f40:	068080e7          	jalr	104(ra) # 80000fa4 <kvminithart>
		procinit();      // process table
    80000f44:	00001097          	auipc	ra,0x1
    80000f48:	a1c080e7          	jalr	-1508(ra) # 80001960 <procinit>
		trapinit();      // trap vectors
    80000f4c:	00001097          	auipc	ra,0x1
    80000f50:	714080e7          	jalr	1812(ra) # 80002660 <trapinit>
		trapinithart();  // install kernel trap vector
    80000f54:	00001097          	auipc	ra,0x1
    80000f58:	734080e7          	jalr	1844(ra) # 80002688 <trapinithart>
	plicinit();      // set up interrupt controller
    80000f5c:	00005097          	auipc	ra,0x5
    80000f60:	c6e080e7          	jalr	-914(ra) # 80005bca <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f64:	00005097          	auipc	ra,0x5
    80000f68:	c7c080e7          	jalr	-900(ra) # 80005be0 <plicinithart>
		binit();         // buffer cache
    80000f6c:	00002097          	auipc	ra,0x2
    80000f70:	e5e080e7          	jalr	-418(ra) # 80002dca <binit>
		iinit();         // inode table
    80000f74:	00002097          	auipc	ra,0x2
    80000f78:	4ee080e7          	jalr	1262(ra) # 80003462 <iinit>
		fileinit();      // file table
    80000f7c:	00003097          	auipc	ra,0x3
    80000f80:	498080e7          	jalr	1176(ra) # 80004414 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f84:	00005097          	auipc	ra,0x5
    80000f88:	d7e080e7          	jalr	-642(ra) # 80005d02 <virtio_disk_init>
		userinit();      // first user process
    80000f8c:	00001097          	auipc	ra,0x1
    80000f90:	d88080e7          	jalr	-632(ra) # 80001d14 <userinit>
		__sync_synchronize();
    80000f94:	0ff0000f          	fence
		started = 1;
    80000f98:	4785                	li	a5,1
    80000f9a:	0000f717          	auipc	a4,0xf
    80000f9e:	06f72f23          	sw	a5,126(a4) # 80010018 <started>
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
    80000faa:	0000f797          	auipc	a5,0xf
    80000fae:	0767b783          	ld	a5,118(a5) # 80010020 <kernel_pagetable>
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
    80000fe6:	4a7d                	li	s4,31
		panic("walk");

	for(int level = 2; level > 0; level--) {
    80000fe8:	4b3d                	li	s6,15
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
    80000ffe:	060a8563          	beqz	s5,80001068 <walk+0xa0>
    80001002:	00000097          	auipc	ra,0x0
    80001006:	af2080e7          	jalr	-1294(ra) # 80000af4 <kalloc>
    8000100a:	84aa                	mv	s1,a0
    8000100c:	c521                	beqz	a0,80001054 <walk+0x8c>
				return 0;
			memset(pagetable, 0, PGSIZE);
    8000100e:	6621                	lui	a2,0x8
    80001010:	4581                	li	a1,0
    80001012:	00000097          	auipc	ra,0x0
    80001016:	cce080e7          	jalr	-818(ra) # 80000ce0 <memset>
			*pte = PA2PTE(pagetable) | PTE_V;
    8000101a:	00f4d793          	srli	a5,s1,0xf
    8000101e:	07aa                	slli	a5,a5,0xa
    80001020:	0017e793          	ori	a5,a5,1
    80001024:	00f93023          	sd	a5,0(s2)
	for(int level = 2; level > 0; level--) {
    80001028:	3a61                	addiw	s4,s4,-8
    8000102a:	036a0063          	beq	s4,s6,8000104a <walk+0x82>
		pte_t *pte = &pagetable[PX(level, va)];
    8000102e:	0149d933          	srl	s2,s3,s4
    80001032:	0ff97913          	andi	s2,s2,255
    80001036:	090e                	slli	s2,s2,0x3
    80001038:	9926                	add	s2,s2,s1
		if(*pte & PTE_V) {
    8000103a:	00093483          	ld	s1,0(s2)
    8000103e:	0014f793          	andi	a5,s1,1
    80001042:	dfd5                	beqz	a5,80000ffe <walk+0x36>
			pagetable = (pagetable_t)PTE2PA(*pte);
    80001044:	80a9                	srli	s1,s1,0xa
    80001046:	04be                	slli	s1,s1,0xf
    80001048:	b7c5                	j	80001028 <walk+0x60>
		}
	}
	return &pagetable[PX(0, va)];
    8000104a:	00c9d513          	srli	a0,s3,0xc
    8000104e:	7f857513          	andi	a0,a0,2040
    80001052:	9526                	add	a0,a0,s1
}
    80001054:	70e2                	ld	ra,56(sp)
    80001056:	7442                	ld	s0,48(sp)
    80001058:	74a2                	ld	s1,40(sp)
    8000105a:	7902                	ld	s2,32(sp)
    8000105c:	69e2                	ld	s3,24(sp)
    8000105e:	6a42                	ld	s4,16(sp)
    80001060:	6aa2                	ld	s5,8(sp)
    80001062:	6b02                	ld	s6,0(sp)
    80001064:	6121                	addi	sp,sp,64
    80001066:	8082                	ret
				return 0;
    80001068:	4501                	li	a0,0
    8000106a:	b7ed                	j	80001054 <walk+0x8c>

000000008000106c <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    8000106c:	57fd                	li	a5,-1
    8000106e:	83e9                	srli	a5,a5,0x1a
    80001070:	00b7f463          	bgeu	a5,a1,80001078 <walkaddr+0xc>
    return 0;
    80001074:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001076:	8082                	ret
{
    80001078:	1141                	addi	sp,sp,-16
    8000107a:	e406                	sd	ra,8(sp)
    8000107c:	e022                	sd	s0,0(sp)
    8000107e:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80001080:	4601                	li	a2,0
    80001082:	00000097          	auipc	ra,0x0
    80001086:	f46080e7          	jalr	-186(ra) # 80000fc8 <walk>
  if(pte == 0)
    8000108a:	c105                	beqz	a0,800010aa <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    8000108c:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    8000108e:	0117f693          	andi	a3,a5,17
    80001092:	4745                	li	a4,17
    return 0;
    80001094:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    80001096:	00e68663          	beq	a3,a4,800010a2 <walkaddr+0x36>
}
    8000109a:	60a2                	ld	ra,8(sp)
    8000109c:	6402                	ld	s0,0(sp)
    8000109e:	0141                	addi	sp,sp,16
    800010a0:	8082                	ret
  pa = PTE2PA(*pte);
    800010a2:	00a7d513          	srli	a0,a5,0xa
    800010a6:	053e                	slli	a0,a0,0xf
  return pa;
    800010a8:	bfcd                	j	8000109a <walkaddr+0x2e>
    return 0;
    800010aa:	4501                	li	a0,0
    800010ac:	b7fd                	j	8000109a <walkaddr+0x2e>

00000000800010ae <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    800010ae:	715d                	addi	sp,sp,-80
    800010b0:	e486                	sd	ra,72(sp)
    800010b2:	e0a2                	sd	s0,64(sp)
    800010b4:	fc26                	sd	s1,56(sp)
    800010b6:	f84a                	sd	s2,48(sp)
    800010b8:	f44e                	sd	s3,40(sp)
    800010ba:	f052                	sd	s4,32(sp)
    800010bc:	ec56                	sd	s5,24(sp)
    800010be:	e85a                	sd	s6,16(sp)
    800010c0:	e45e                	sd	s7,8(sp)
    800010c2:	0880                	addi	s0,sp,80
	// uint64 i;
	pte_t *pte;

	// i = 0;

	if(size == 0)
    800010c4:	c205                	beqz	a2,800010e4 <mappages+0x36>
    800010c6:	8aaa                	mv	s5,a0
    800010c8:	8b3a                	mv	s6,a4
		panic("mappages: size");

	a = PGROUNDDOWN(va);
    800010ca:	77e1                	lui	a5,0xffff8
    800010cc:	00f5fa33          	and	s4,a1,a5
	last = PGROUNDDOWN(va + size - 1);
    800010d0:	15fd                	addi	a1,a1,-1
    800010d2:	00c589b3          	add	s3,a1,a2
    800010d6:	00f9f9b3          	and	s3,s3,a5
	a = PGROUNDDOWN(va);
    800010da:	8952                	mv	s2,s4
    800010dc:	41468a33          	sub	s4,a3,s4
			panic("mappages: remap");
		}
		*pte = PA2PTE(pa) | perm | PTE_V;
		if(a == last)
			break;
		a += PGSIZE;
    800010e0:	6ba1                	lui	s7,0x8
    800010e2:	a815                	j	80001116 <mappages+0x68>
		panic("mappages: size");
    800010e4:	00007517          	auipc	a0,0x7
    800010e8:	ff450513          	addi	a0,a0,-12 # 800080d8 <digits+0x98>
    800010ec:	fffff097          	auipc	ra,0xfffff
    800010f0:	452080e7          	jalr	1106(ra) # 8000053e <panic>
			printf("%x\n", *pte);
    800010f4:	00007517          	auipc	a0,0x7
    800010f8:	ff450513          	addi	a0,a0,-12 # 800080e8 <digits+0xa8>
    800010fc:	fffff097          	auipc	ra,0xfffff
    80001100:	48c080e7          	jalr	1164(ra) # 80000588 <printf>
			panic("mappages: remap");
    80001104:	00007517          	auipc	a0,0x7
    80001108:	fec50513          	addi	a0,a0,-20 # 800080f0 <digits+0xb0>
    8000110c:	fffff097          	auipc	ra,0xfffff
    80001110:	432080e7          	jalr	1074(ra) # 8000053e <panic>
		a += PGSIZE;
    80001114:	995e                	add	s2,s2,s7
	for(;;){
    80001116:	012a04b3          	add	s1,s4,s2
		if((pte = walk(pagetable, a, 1)) == 0)
    8000111a:	4605                	li	a2,1
    8000111c:	85ca                	mv	a1,s2
    8000111e:	8556                	mv	a0,s5
    80001120:	00000097          	auipc	ra,0x0
    80001124:	ea8080e7          	jalr	-344(ra) # 80000fc8 <walk>
    80001128:	c105                	beqz	a0,80001148 <mappages+0x9a>
		if(!(*pte & PTE_V)){
    8000112a:	610c                	ld	a1,0(a0)
    8000112c:	0015f793          	andi	a5,a1,1
    80001130:	d3f1                	beqz	a5,800010f4 <mappages+0x46>
		*pte = PA2PTE(pa) | perm | PTE_V;
    80001132:	80bd                	srli	s1,s1,0xf
    80001134:	04aa                	slli	s1,s1,0xa
    80001136:	0164e4b3          	or	s1,s1,s6
    8000113a:	0014e493          	ori	s1,s1,1
    8000113e:	e104                	sd	s1,0(a0)
		if(a == last)
    80001140:	fd391ae3          	bne	s2,s3,80001114 <mappages+0x66>
		pa += PGSIZE;
	}
	return 0;
    80001144:	4501                	li	a0,0
    80001146:	a011                	j	8000114a <mappages+0x9c>
			return -1;
    80001148:	557d                	li	a0,-1
}
    8000114a:	60a6                	ld	ra,72(sp)
    8000114c:	6406                	ld	s0,64(sp)
    8000114e:	74e2                	ld	s1,56(sp)
    80001150:	7942                	ld	s2,48(sp)
    80001152:	79a2                	ld	s3,40(sp)
    80001154:	7a02                	ld	s4,32(sp)
    80001156:	6ae2                	ld	s5,24(sp)
    80001158:	6b42                	ld	s6,16(sp)
    8000115a:	6ba2                	ld	s7,8(sp)
    8000115c:	6161                	addi	sp,sp,80
    8000115e:	8082                	ret

0000000080001160 <kvmmap>:
{
    80001160:	1141                	addi	sp,sp,-16
    80001162:	e406                	sd	ra,8(sp)
    80001164:	e022                	sd	s0,0(sp)
    80001166:	0800                	addi	s0,sp,16
    80001168:	87b6                	mv	a5,a3
	if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    8000116a:	86b2                	mv	a3,a2
    8000116c:	863e                	mv	a2,a5
    8000116e:	00000097          	auipc	ra,0x0
    80001172:	f40080e7          	jalr	-192(ra) # 800010ae <mappages>
    80001176:	e509                	bnez	a0,80001180 <kvmmap+0x20>
}
    80001178:	60a2                	ld	ra,8(sp)
    8000117a:	6402                	ld	s0,0(sp)
    8000117c:	0141                	addi	sp,sp,16
    8000117e:	8082                	ret
		panic("kvmmap");
    80001180:	00007517          	auipc	a0,0x7
    80001184:	f8050513          	addi	a0,a0,-128 # 80008100 <digits+0xc0>
    80001188:	fffff097          	auipc	ra,0xfffff
    8000118c:	3b6080e7          	jalr	950(ra) # 8000053e <panic>

0000000080001190 <kvmmake>:
{
    80001190:	1101                	addi	sp,sp,-32
    80001192:	ec06                	sd	ra,24(sp)
    80001194:	e822                	sd	s0,16(sp)
    80001196:	e426                	sd	s1,8(sp)
    80001198:	e04a                	sd	s2,0(sp)
    8000119a:	1000                	addi	s0,sp,32
	kpgtbl = (pagetable_t) kalloc();
    8000119c:	00000097          	auipc	ra,0x0
    800011a0:	958080e7          	jalr	-1704(ra) # 80000af4 <kalloc>
    800011a4:	84aa                	mv	s1,a0
	memset(kpgtbl, 0, PGSIZE);
    800011a6:	6621                	lui	a2,0x8
    800011a8:	4581                	li	a1,0
    800011aa:	00000097          	auipc	ra,0x0
    800011ae:	b36080e7          	jalr	-1226(ra) # 80000ce0 <memset>
	kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    800011b2:	4719                	li	a4,6
    800011b4:	66a1                	lui	a3,0x8
    800011b6:	10000637          	lui	a2,0x10000
    800011ba:	100005b7          	lui	a1,0x10000
    800011be:	8526                	mv	a0,s1
    800011c0:	00000097          	auipc	ra,0x0
    800011c4:	fa0080e7          	jalr	-96(ra) # 80001160 <kvmmap>
	kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800011c8:	4719                	li	a4,6
    800011ca:	66a1                	lui	a3,0x8
    800011cc:	10001637          	lui	a2,0x10001
    800011d0:	100015b7          	lui	a1,0x10001
    800011d4:	8526                	mv	a0,s1
    800011d6:	00000097          	auipc	ra,0x0
    800011da:	f8a080e7          	jalr	-118(ra) # 80001160 <kvmmap>
	kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800011de:	4719                	li	a4,6
    800011e0:	004006b7          	lui	a3,0x400
    800011e4:	0c000637          	lui	a2,0xc000
    800011e8:	0c0005b7          	lui	a1,0xc000
    800011ec:	8526                	mv	a0,s1
    800011ee:	00000097          	auipc	ra,0x0
    800011f2:	f72080e7          	jalr	-142(ra) # 80001160 <kvmmap>
	kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800011f6:	00007917          	auipc	s2,0x7
    800011fa:	e0a90913          	addi	s2,s2,-502 # 80008000 <etext>
    800011fe:	4729                	li	a4,10
    80001200:	80007697          	auipc	a3,0x80007
    80001204:	e0068693          	addi	a3,a3,-512 # 8000 <_entry-0x7fff8000>
    80001208:	4605                	li	a2,1
    8000120a:	067e                	slli	a2,a2,0x1f
    8000120c:	85b2                	mv	a1,a2
    8000120e:	8526                	mv	a0,s1
    80001210:	00000097          	auipc	ra,0x0
    80001214:	f50080e7          	jalr	-176(ra) # 80001160 <kvmmap>
	kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    80001218:	4719                	li	a4,6
    8000121a:	46c5                	li	a3,17
    8000121c:	06ee                	slli	a3,a3,0x1b
    8000121e:	412686b3          	sub	a3,a3,s2
    80001222:	864a                	mv	a2,s2
    80001224:	85ca                	mv	a1,s2
    80001226:	8526                	mv	a0,s1
    80001228:	00000097          	auipc	ra,0x0
    8000122c:	f38080e7          	jalr	-200(ra) # 80001160 <kvmmap>
	kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80001230:	4729                	li	a4,10
    80001232:	66a1                	lui	a3,0x8
    80001234:	00006617          	auipc	a2,0x6
    80001238:	dcc60613          	addi	a2,a2,-564 # 80007000 <_trampoline>
    8000123c:	008005b7          	lui	a1,0x800
    80001240:	15fd                	addi	a1,a1,-1
    80001242:	05be                	slli	a1,a1,0xf
    80001244:	8526                	mv	a0,s1
    80001246:	00000097          	auipc	ra,0x0
    8000124a:	f1a080e7          	jalr	-230(ra) # 80001160 <kvmmap>
	proc_mapstacks(kpgtbl);
    8000124e:	8526                	mv	a0,s1
    80001250:	00000097          	auipc	ra,0x0
    80001254:	67a080e7          	jalr	1658(ra) # 800018ca <proc_mapstacks>
}
    80001258:	8526                	mv	a0,s1
    8000125a:	60e2                	ld	ra,24(sp)
    8000125c:	6442                	ld	s0,16(sp)
    8000125e:	64a2                	ld	s1,8(sp)
    80001260:	6902                	ld	s2,0(sp)
    80001262:	6105                	addi	sp,sp,32
    80001264:	8082                	ret

0000000080001266 <kvminit>:
{
    80001266:	1141                	addi	sp,sp,-16
    80001268:	e406                	sd	ra,8(sp)
    8000126a:	e022                	sd	s0,0(sp)
    8000126c:	0800                	addi	s0,sp,16
	kernel_pagetable = kvmmake();
    8000126e:	00000097          	auipc	ra,0x0
    80001272:	f22080e7          	jalr	-222(ra) # 80001190 <kvmmake>
    80001276:	0000f797          	auipc	a5,0xf
    8000127a:	daa7b523          	sd	a0,-598(a5) # 80010020 <kernel_pagetable>
}
    8000127e:	60a2                	ld	ra,8(sp)
    80001280:	6402                	ld	s0,0(sp)
    80001282:	0141                	addi	sp,sp,16
    80001284:	8082                	ret

0000000080001286 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001286:	715d                	addi	sp,sp,-80
    80001288:	e486                	sd	ra,72(sp)
    8000128a:	e0a2                	sd	s0,64(sp)
    8000128c:	fc26                	sd	s1,56(sp)
    8000128e:	f84a                	sd	s2,48(sp)
    80001290:	f44e                	sd	s3,40(sp)
    80001292:	f052                	sd	s4,32(sp)
    80001294:	ec56                	sd	s5,24(sp)
    80001296:	e85a                	sd	s6,16(sp)
    80001298:	e45e                	sd	s7,8(sp)
    8000129a:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    8000129c:	03159793          	slli	a5,a1,0x31
    800012a0:	e795                	bnez	a5,800012cc <uvmunmap+0x46>
    800012a2:	8a2a                	mv	s4,a0
    800012a4:	892e                	mv	s2,a1
    800012a6:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012a8:	063e                	slli	a2,a2,0xf
    800012aa:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    800012ae:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012b0:	6b21                	lui	s6,0x8
    800012b2:	0735e863          	bltu	a1,s3,80001322 <uvmunmap+0x9c>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    800012b6:	60a6                	ld	ra,72(sp)
    800012b8:	6406                	ld	s0,64(sp)
    800012ba:	74e2                	ld	s1,56(sp)
    800012bc:	7942                	ld	s2,48(sp)
    800012be:	79a2                	ld	s3,40(sp)
    800012c0:	7a02                	ld	s4,32(sp)
    800012c2:	6ae2                	ld	s5,24(sp)
    800012c4:	6b42                	ld	s6,16(sp)
    800012c6:	6ba2                	ld	s7,8(sp)
    800012c8:	6161                	addi	sp,sp,80
    800012ca:	8082                	ret
    panic("uvmunmap: not aligned");
    800012cc:	00007517          	auipc	a0,0x7
    800012d0:	e3c50513          	addi	a0,a0,-452 # 80008108 <digits+0xc8>
    800012d4:	fffff097          	auipc	ra,0xfffff
    800012d8:	26a080e7          	jalr	618(ra) # 8000053e <panic>
      panic("uvmunmap: walk");
    800012dc:	00007517          	auipc	a0,0x7
    800012e0:	e4450513          	addi	a0,a0,-444 # 80008120 <digits+0xe0>
    800012e4:	fffff097          	auipc	ra,0xfffff
    800012e8:	25a080e7          	jalr	602(ra) # 8000053e <panic>
      panic("uvmunmap: not mapped");
    800012ec:	00007517          	auipc	a0,0x7
    800012f0:	e4450513          	addi	a0,a0,-444 # 80008130 <digits+0xf0>
    800012f4:	fffff097          	auipc	ra,0xfffff
    800012f8:	24a080e7          	jalr	586(ra) # 8000053e <panic>
      panic("uvmunmap: not a leaf");
    800012fc:	00007517          	auipc	a0,0x7
    80001300:	e4c50513          	addi	a0,a0,-436 # 80008148 <digits+0x108>
    80001304:	fffff097          	auipc	ra,0xfffff
    80001308:	23a080e7          	jalr	570(ra) # 8000053e <panic>
      uint64 pa = PTE2PA(*pte);
    8000130c:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    8000130e:	053e                	slli	a0,a0,0xf
    80001310:	fffff097          	auipc	ra,0xfffff
    80001314:	6e8080e7          	jalr	1768(ra) # 800009f8 <kfree>
    *pte = 0;
    80001318:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000131c:	995a                	add	s2,s2,s6
    8000131e:	f9397ce3          	bgeu	s2,s3,800012b6 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    80001322:	4601                	li	a2,0
    80001324:	85ca                	mv	a1,s2
    80001326:	8552                	mv	a0,s4
    80001328:	00000097          	auipc	ra,0x0
    8000132c:	ca0080e7          	jalr	-864(ra) # 80000fc8 <walk>
    80001330:	84aa                	mv	s1,a0
    80001332:	d54d                	beqz	a0,800012dc <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    80001334:	6108                	ld	a0,0(a0)
    80001336:	00157793          	andi	a5,a0,1
    8000133a:	dbcd                	beqz	a5,800012ec <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    8000133c:	3ff57793          	andi	a5,a0,1023
    80001340:	fb778ee3          	beq	a5,s7,800012fc <uvmunmap+0x76>
    if(do_free){
    80001344:	fc0a8ae3          	beqz	s5,80001318 <uvmunmap+0x92>
    80001348:	b7d1                	j	8000130c <uvmunmap+0x86>

000000008000134a <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    8000134a:	1101                	addi	sp,sp,-32
    8000134c:	ec06                	sd	ra,24(sp)
    8000134e:	e822                	sd	s0,16(sp)
    80001350:	e426                	sd	s1,8(sp)
    80001352:	1000                	addi	s0,sp,32
	pagetable_t pagetable;
	pagetable = (pagetable_t) kalloc();
    80001354:	fffff097          	auipc	ra,0xfffff
    80001358:	7a0080e7          	jalr	1952(ra) # 80000af4 <kalloc>
    8000135c:	84aa                	mv	s1,a0
	if(pagetable == 0)
    8000135e:	c519                	beqz	a0,8000136c <uvmcreate+0x22>
		return 0;
	memset(pagetable, 0, PGSIZE);
    80001360:	6621                	lui	a2,0x8
    80001362:	4581                	li	a1,0
    80001364:	00000097          	auipc	ra,0x0
    80001368:	97c080e7          	jalr	-1668(ra) # 80000ce0 <memset>
	return pagetable;
}
    8000136c:	8526                	mv	a0,s1
    8000136e:	60e2                	ld	ra,24(sp)
    80001370:	6442                	ld	s0,16(sp)
    80001372:	64a2                	ld	s1,8(sp)
    80001374:	6105                	addi	sp,sp,32
    80001376:	8082                	ret

0000000080001378 <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    80001378:	7179                	addi	sp,sp,-48
    8000137a:	f406                	sd	ra,40(sp)
    8000137c:	f022                	sd	s0,32(sp)
    8000137e:	ec26                	sd	s1,24(sp)
    80001380:	e84a                	sd	s2,16(sp)
    80001382:	e44e                	sd	s3,8(sp)
    80001384:	e052                	sd	s4,0(sp)
    80001386:	1800                	addi	s0,sp,48
	char *mem;

	if(sz >= PGSIZE)
    80001388:	67a1                	lui	a5,0x8
    8000138a:	04f67863          	bgeu	a2,a5,800013da <uvminit+0x62>
    8000138e:	8a2a                	mv	s4,a0
    80001390:	89ae                	mv	s3,a1
    80001392:	84b2                	mv	s1,a2
		panic("inituvm: more than a page");
	mem = kalloc();
    80001394:	fffff097          	auipc	ra,0xfffff
    80001398:	760080e7          	jalr	1888(ra) # 80000af4 <kalloc>
    8000139c:	892a                	mv	s2,a0
	memset(mem, 0, PGSIZE);
    8000139e:	6621                	lui	a2,0x8
    800013a0:	4581                	li	a1,0
    800013a2:	00000097          	auipc	ra,0x0
    800013a6:	93e080e7          	jalr	-1730(ra) # 80000ce0 <memset>
	mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    800013aa:	4779                	li	a4,30
    800013ac:	86ca                	mv	a3,s2
    800013ae:	6621                	lui	a2,0x8
    800013b0:	4581                	li	a1,0
    800013b2:	8552                	mv	a0,s4
    800013b4:	00000097          	auipc	ra,0x0
    800013b8:	cfa080e7          	jalr	-774(ra) # 800010ae <mappages>
	memmove(mem, src, sz);
    800013bc:	8626                	mv	a2,s1
    800013be:	85ce                	mv	a1,s3
    800013c0:	854a                	mv	a0,s2
    800013c2:	00000097          	auipc	ra,0x0
    800013c6:	97e080e7          	jalr	-1666(ra) # 80000d40 <memmove>
}
    800013ca:	70a2                	ld	ra,40(sp)
    800013cc:	7402                	ld	s0,32(sp)
    800013ce:	64e2                	ld	s1,24(sp)
    800013d0:	6942                	ld	s2,16(sp)
    800013d2:	69a2                	ld	s3,8(sp)
    800013d4:	6a02                	ld	s4,0(sp)
    800013d6:	6145                	addi	sp,sp,48
    800013d8:	8082                	ret
		panic("inituvm: more than a page");
    800013da:	00007517          	auipc	a0,0x7
    800013de:	d8650513          	addi	a0,a0,-634 # 80008160 <digits+0x120>
    800013e2:	fffff097          	auipc	ra,0xfffff
    800013e6:	15c080e7          	jalr	348(ra) # 8000053e <panic>

00000000800013ea <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800013ea:	1101                	addi	sp,sp,-32
    800013ec:	ec06                	sd	ra,24(sp)
    800013ee:	e822                	sd	s0,16(sp)
    800013f0:	e426                	sd	s1,8(sp)
    800013f2:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800013f4:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800013f6:	00b67d63          	bgeu	a2,a1,80001410 <uvmdealloc+0x26>
    800013fa:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800013fc:	67a1                	lui	a5,0x8
    800013fe:	17fd                	addi	a5,a5,-1
    80001400:	00f60733          	add	a4,a2,a5
    80001404:	7661                	lui	a2,0xffff8
    80001406:	8f71                	and	a4,a4,a2
    80001408:	97ae                	add	a5,a5,a1
    8000140a:	8ff1                	and	a5,a5,a2
    8000140c:	00f76863          	bltu	a4,a5,8000141c <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    80001410:	8526                	mv	a0,s1
    80001412:	60e2                	ld	ra,24(sp)
    80001414:	6442                	ld	s0,16(sp)
    80001416:	64a2                	ld	s1,8(sp)
    80001418:	6105                	addi	sp,sp,32
    8000141a:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    8000141c:	8f99                	sub	a5,a5,a4
    8000141e:	83bd                	srli	a5,a5,0xf
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    80001420:	4685                	li	a3,1
    80001422:	0007861b          	sext.w	a2,a5
    80001426:	85ba                	mv	a1,a4
    80001428:	00000097          	auipc	ra,0x0
    8000142c:	e5e080e7          	jalr	-418(ra) # 80001286 <uvmunmap>
    80001430:	b7c5                	j	80001410 <uvmdealloc+0x26>

0000000080001432 <uvmalloc>:
	if(newsz < oldsz)
    80001432:	0ab66163          	bltu	a2,a1,800014d4 <uvmalloc+0xa2>
{
    80001436:	7139                	addi	sp,sp,-64
    80001438:	fc06                	sd	ra,56(sp)
    8000143a:	f822                	sd	s0,48(sp)
    8000143c:	f426                	sd	s1,40(sp)
    8000143e:	f04a                	sd	s2,32(sp)
    80001440:	ec4e                	sd	s3,24(sp)
    80001442:	e852                	sd	s4,16(sp)
    80001444:	e456                	sd	s5,8(sp)
    80001446:	0080                	addi	s0,sp,64
    80001448:	8aaa                	mv	s5,a0
    8000144a:	8a32                	mv	s4,a2
	oldsz = PGROUNDUP(oldsz);
    8000144c:	69a1                	lui	s3,0x8
    8000144e:	19fd                	addi	s3,s3,-1
    80001450:	95ce                	add	a1,a1,s3
    80001452:	79e1                	lui	s3,0xffff8
    80001454:	0135f9b3          	and	s3,a1,s3
	for(a = oldsz; a < newsz; a += PGSIZE){
    80001458:	08c9f063          	bgeu	s3,a2,800014d8 <uvmalloc+0xa6>
    8000145c:	894e                	mv	s2,s3
		mem = kalloc();
    8000145e:	fffff097          	auipc	ra,0xfffff
    80001462:	696080e7          	jalr	1686(ra) # 80000af4 <kalloc>
    80001466:	84aa                	mv	s1,a0
		if(mem == 0){
    80001468:	c51d                	beqz	a0,80001496 <uvmalloc+0x64>
		memset(mem, 0, PGSIZE);
    8000146a:	6621                	lui	a2,0x8
    8000146c:	4581                	li	a1,0
    8000146e:	00000097          	auipc	ra,0x0
    80001472:	872080e7          	jalr	-1934(ra) # 80000ce0 <memset>
		if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    80001476:	4779                	li	a4,30
    80001478:	86a6                	mv	a3,s1
    8000147a:	6621                	lui	a2,0x8
    8000147c:	85ca                	mv	a1,s2
    8000147e:	8556                	mv	a0,s5
    80001480:	00000097          	auipc	ra,0x0
    80001484:	c2e080e7          	jalr	-978(ra) # 800010ae <mappages>
    80001488:	e905                	bnez	a0,800014b8 <uvmalloc+0x86>
	for(a = oldsz; a < newsz; a += PGSIZE){
    8000148a:	67a1                	lui	a5,0x8
    8000148c:	993e                	add	s2,s2,a5
    8000148e:	fd4968e3          	bltu	s2,s4,8000145e <uvmalloc+0x2c>
	return newsz;
    80001492:	8552                	mv	a0,s4
    80001494:	a809                	j	800014a6 <uvmalloc+0x74>
			uvmdealloc(pagetable, a, oldsz);
    80001496:	864e                	mv	a2,s3
    80001498:	85ca                	mv	a1,s2
    8000149a:	8556                	mv	a0,s5
    8000149c:	00000097          	auipc	ra,0x0
    800014a0:	f4e080e7          	jalr	-178(ra) # 800013ea <uvmdealloc>
			return 0;
    800014a4:	4501                	li	a0,0
}
    800014a6:	70e2                	ld	ra,56(sp)
    800014a8:	7442                	ld	s0,48(sp)
    800014aa:	74a2                	ld	s1,40(sp)
    800014ac:	7902                	ld	s2,32(sp)
    800014ae:	69e2                	ld	s3,24(sp)
    800014b0:	6a42                	ld	s4,16(sp)
    800014b2:	6aa2                	ld	s5,8(sp)
    800014b4:	6121                	addi	sp,sp,64
    800014b6:	8082                	ret
			kfree(mem);
    800014b8:	8526                	mv	a0,s1
    800014ba:	fffff097          	auipc	ra,0xfffff
    800014be:	53e080e7          	jalr	1342(ra) # 800009f8 <kfree>
			uvmdealloc(pagetable, a, oldsz);
    800014c2:	864e                	mv	a2,s3
    800014c4:	85ca                	mv	a1,s2
    800014c6:	8556                	mv	a0,s5
    800014c8:	00000097          	auipc	ra,0x0
    800014cc:	f22080e7          	jalr	-222(ra) # 800013ea <uvmdealloc>
			return 0;
    800014d0:	4501                	li	a0,0
    800014d2:	bfd1                	j	800014a6 <uvmalloc+0x74>
		return oldsz;
    800014d4:	852e                	mv	a0,a1
}
    800014d6:	8082                	ret
	return newsz;
    800014d8:	8532                	mv	a0,a2
    800014da:	b7f1                	j	800014a6 <uvmalloc+0x74>

00000000800014dc <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800014dc:	7179                	addi	sp,sp,-48
    800014de:	f406                	sd	ra,40(sp)
    800014e0:	f022                	sd	s0,32(sp)
    800014e2:	ec26                	sd	s1,24(sp)
    800014e4:	e84a                	sd	s2,16(sp)
    800014e6:	e44e                	sd	s3,8(sp)
    800014e8:	e052                	sd	s4,0(sp)
    800014ea:	1800                	addi	s0,sp,48
    800014ec:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800014ee:	84aa                	mv	s1,a0
    800014f0:	6905                	lui	s2,0x1
    800014f2:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014f4:	4985                	li	s3,1
    800014f6:	a821                	j	8000150e <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800014f8:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    800014fa:	053e                	slli	a0,a0,0xf
    800014fc:	00000097          	auipc	ra,0x0
    80001500:	fe0080e7          	jalr	-32(ra) # 800014dc <freewalk>
      pagetable[i] = 0;
    80001504:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    80001508:	04a1                	addi	s1,s1,8
    8000150a:	03248163          	beq	s1,s2,8000152c <freewalk+0x50>
    pte_t pte = pagetable[i];
    8000150e:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001510:	00f57793          	andi	a5,a0,15
    80001514:	ff3782e3          	beq	a5,s3,800014f8 <freewalk+0x1c>
    } else if(pte & PTE_V){
    80001518:	8905                	andi	a0,a0,1
    8000151a:	d57d                	beqz	a0,80001508 <freewalk+0x2c>
      panic("freewalk: leaf");
    8000151c:	00007517          	auipc	a0,0x7
    80001520:	c6450513          	addi	a0,a0,-924 # 80008180 <digits+0x140>
    80001524:	fffff097          	auipc	ra,0xfffff
    80001528:	01a080e7          	jalr	26(ra) # 8000053e <panic>
    }
  }
  kfree((void*)pagetable);
    8000152c:	8552                	mv	a0,s4
    8000152e:	fffff097          	auipc	ra,0xfffff
    80001532:	4ca080e7          	jalr	1226(ra) # 800009f8 <kfree>
}
    80001536:	70a2                	ld	ra,40(sp)
    80001538:	7402                	ld	s0,32(sp)
    8000153a:	64e2                	ld	s1,24(sp)
    8000153c:	6942                	ld	s2,16(sp)
    8000153e:	69a2                	ld	s3,8(sp)
    80001540:	6a02                	ld	s4,0(sp)
    80001542:	6145                	addi	sp,sp,48
    80001544:	8082                	ret

0000000080001546 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    80001546:	1101                	addi	sp,sp,-32
    80001548:	ec06                	sd	ra,24(sp)
    8000154a:	e822                	sd	s0,16(sp)
    8000154c:	e426                	sd	s1,8(sp)
    8000154e:	1000                	addi	s0,sp,32
    80001550:	84aa                	mv	s1,a0
	if(sz > 0)
    80001552:	e999                	bnez	a1,80001568 <uvmfree+0x22>
		uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
	freewalk(pagetable);
    80001554:	8526                	mv	a0,s1
    80001556:	00000097          	auipc	ra,0x0
    8000155a:	f86080e7          	jalr	-122(ra) # 800014dc <freewalk>
}
    8000155e:	60e2                	ld	ra,24(sp)
    80001560:	6442                	ld	s0,16(sp)
    80001562:	64a2                	ld	s1,8(sp)
    80001564:	6105                	addi	sp,sp,32
    80001566:	8082                	ret
		uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001568:	6621                	lui	a2,0x8
    8000156a:	167d                	addi	a2,a2,-1
    8000156c:	962e                	add	a2,a2,a1
    8000156e:	4685                	li	a3,1
    80001570:	823d                	srli	a2,a2,0xf
    80001572:	4581                	li	a1,0
    80001574:	00000097          	auipc	ra,0x0
    80001578:	d12080e7          	jalr	-750(ra) # 80001286 <uvmunmap>
    8000157c:	bfe1                	j	80001554 <uvmfree+0xe>

000000008000157e <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    8000157e:	c679                	beqz	a2,8000164c <uvmcopy+0xce>
{
    80001580:	715d                	addi	sp,sp,-80
    80001582:	e486                	sd	ra,72(sp)
    80001584:	e0a2                	sd	s0,64(sp)
    80001586:	fc26                	sd	s1,56(sp)
    80001588:	f84a                	sd	s2,48(sp)
    8000158a:	f44e                	sd	s3,40(sp)
    8000158c:	f052                	sd	s4,32(sp)
    8000158e:	ec56                	sd	s5,24(sp)
    80001590:	e85a                	sd	s6,16(sp)
    80001592:	e45e                	sd	s7,8(sp)
    80001594:	0880                	addi	s0,sp,80
    80001596:	8b2a                	mv	s6,a0
    80001598:	8aae                	mv	s5,a1
    8000159a:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    8000159c:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    8000159e:	4601                	li	a2,0
    800015a0:	85ce                	mv	a1,s3
    800015a2:	855a                	mv	a0,s6
    800015a4:	00000097          	auipc	ra,0x0
    800015a8:	a24080e7          	jalr	-1500(ra) # 80000fc8 <walk>
    800015ac:	c531                	beqz	a0,800015f8 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    800015ae:	6118                	ld	a4,0(a0)
    800015b0:	00177793          	andi	a5,a4,1
    800015b4:	cbb1                	beqz	a5,80001608 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    800015b6:	00a75593          	srli	a1,a4,0xa
    800015ba:	00f59b93          	slli	s7,a1,0xf
    flags = PTE_FLAGS(*pte);
    800015be:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    800015c2:	fffff097          	auipc	ra,0xfffff
    800015c6:	532080e7          	jalr	1330(ra) # 80000af4 <kalloc>
    800015ca:	892a                	mv	s2,a0
    800015cc:	c939                	beqz	a0,80001622 <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800015ce:	6621                	lui	a2,0x8
    800015d0:	85de                	mv	a1,s7
    800015d2:	fffff097          	auipc	ra,0xfffff
    800015d6:	76e080e7          	jalr	1902(ra) # 80000d40 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800015da:	8726                	mv	a4,s1
    800015dc:	86ca                	mv	a3,s2
    800015de:	6621                	lui	a2,0x8
    800015e0:	85ce                	mv	a1,s3
    800015e2:	8556                	mv	a0,s5
    800015e4:	00000097          	auipc	ra,0x0
    800015e8:	aca080e7          	jalr	-1334(ra) # 800010ae <mappages>
    800015ec:	e515                	bnez	a0,80001618 <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800015ee:	67a1                	lui	a5,0x8
    800015f0:	99be                	add	s3,s3,a5
    800015f2:	fb49e6e3          	bltu	s3,s4,8000159e <uvmcopy+0x20>
    800015f6:	a081                	j	80001636 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800015f8:	00007517          	auipc	a0,0x7
    800015fc:	b9850513          	addi	a0,a0,-1128 # 80008190 <digits+0x150>
    80001600:	fffff097          	auipc	ra,0xfffff
    80001604:	f3e080e7          	jalr	-194(ra) # 8000053e <panic>
      panic("uvmcopy: page not present");
    80001608:	00007517          	auipc	a0,0x7
    8000160c:	ba850513          	addi	a0,a0,-1112 # 800081b0 <digits+0x170>
    80001610:	fffff097          	auipc	ra,0xfffff
    80001614:	f2e080e7          	jalr	-210(ra) # 8000053e <panic>
      kfree(mem);
    80001618:	854a                	mv	a0,s2
    8000161a:	fffff097          	auipc	ra,0xfffff
    8000161e:	3de080e7          	jalr	990(ra) # 800009f8 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001622:	4685                	li	a3,1
    80001624:	00f9d613          	srli	a2,s3,0xf
    80001628:	4581                	li	a1,0
    8000162a:	8556                	mv	a0,s5
    8000162c:	00000097          	auipc	ra,0x0
    80001630:	c5a080e7          	jalr	-934(ra) # 80001286 <uvmunmap>
  return -1;
    80001634:	557d                	li	a0,-1
}
    80001636:	60a6                	ld	ra,72(sp)
    80001638:	6406                	ld	s0,64(sp)
    8000163a:	74e2                	ld	s1,56(sp)
    8000163c:	7942                	ld	s2,48(sp)
    8000163e:	79a2                	ld	s3,40(sp)
    80001640:	7a02                	ld	s4,32(sp)
    80001642:	6ae2                	ld	s5,24(sp)
    80001644:	6b42                	ld	s6,16(sp)
    80001646:	6ba2                	ld	s7,8(sp)
    80001648:	6161                	addi	sp,sp,80
    8000164a:	8082                	ret
  return 0;
    8000164c:	4501                	li	a0,0
}
    8000164e:	8082                	ret

0000000080001650 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001650:	1141                	addi	sp,sp,-16
    80001652:	e406                	sd	ra,8(sp)
    80001654:	e022                	sd	s0,0(sp)
    80001656:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001658:	4601                	li	a2,0
    8000165a:	00000097          	auipc	ra,0x0
    8000165e:	96e080e7          	jalr	-1682(ra) # 80000fc8 <walk>
  if(pte == 0)
    80001662:	c901                	beqz	a0,80001672 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    80001664:	611c                	ld	a5,0(a0)
    80001666:	9bbd                	andi	a5,a5,-17
    80001668:	e11c                	sd	a5,0(a0)
}
    8000166a:	60a2                	ld	ra,8(sp)
    8000166c:	6402                	ld	s0,0(sp)
    8000166e:	0141                	addi	sp,sp,16
    80001670:	8082                	ret
    panic("uvmclear");
    80001672:	00007517          	auipc	a0,0x7
    80001676:	b5e50513          	addi	a0,a0,-1186 # 800081d0 <digits+0x190>
    8000167a:	fffff097          	auipc	ra,0xfffff
    8000167e:	ec4080e7          	jalr	-316(ra) # 8000053e <panic>

0000000080001682 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001682:	c6bd                	beqz	a3,800016f0 <copyout+0x6e>
{
    80001684:	715d                	addi	sp,sp,-80
    80001686:	e486                	sd	ra,72(sp)
    80001688:	e0a2                	sd	s0,64(sp)
    8000168a:	fc26                	sd	s1,56(sp)
    8000168c:	f84a                	sd	s2,48(sp)
    8000168e:	f44e                	sd	s3,40(sp)
    80001690:	f052                	sd	s4,32(sp)
    80001692:	ec56                	sd	s5,24(sp)
    80001694:	e85a                	sd	s6,16(sp)
    80001696:	e45e                	sd	s7,8(sp)
    80001698:	e062                	sd	s8,0(sp)
    8000169a:	0880                	addi	s0,sp,80
    8000169c:	8b2a                	mv	s6,a0
    8000169e:	8c2e                	mv	s8,a1
    800016a0:	8a32                	mv	s4,a2
    800016a2:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    800016a4:	7be1                	lui	s7,0xffff8
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    800016a6:	6aa1                	lui	s5,0x8
    800016a8:	a015                	j	800016cc <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    800016aa:	9562                	add	a0,a0,s8
    800016ac:	0004861b          	sext.w	a2,s1
    800016b0:	85d2                	mv	a1,s4
    800016b2:	41250533          	sub	a0,a0,s2
    800016b6:	fffff097          	auipc	ra,0xfffff
    800016ba:	68a080e7          	jalr	1674(ra) # 80000d40 <memmove>

    len -= n;
    800016be:	409989b3          	sub	s3,s3,s1
    src += n;
    800016c2:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    800016c4:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800016c8:	02098263          	beqz	s3,800016ec <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800016cc:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800016d0:	85ca                	mv	a1,s2
    800016d2:	855a                	mv	a0,s6
    800016d4:	00000097          	auipc	ra,0x0
    800016d8:	998080e7          	jalr	-1640(ra) # 8000106c <walkaddr>
    if(pa0 == 0)
    800016dc:	cd01                	beqz	a0,800016f4 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800016de:	418904b3          	sub	s1,s2,s8
    800016e2:	94d6                	add	s1,s1,s5
    if(n > len)
    800016e4:	fc99f3e3          	bgeu	s3,s1,800016aa <copyout+0x28>
    800016e8:	84ce                	mv	s1,s3
    800016ea:	b7c1                	j	800016aa <copyout+0x28>
  }
  return 0;
    800016ec:	4501                	li	a0,0
    800016ee:	a021                	j	800016f6 <copyout+0x74>
    800016f0:	4501                	li	a0,0
}
    800016f2:	8082                	ret
      return -1;
    800016f4:	557d                	li	a0,-1
}
    800016f6:	60a6                	ld	ra,72(sp)
    800016f8:	6406                	ld	s0,64(sp)
    800016fa:	74e2                	ld	s1,56(sp)
    800016fc:	7942                	ld	s2,48(sp)
    800016fe:	79a2                	ld	s3,40(sp)
    80001700:	7a02                	ld	s4,32(sp)
    80001702:	6ae2                	ld	s5,24(sp)
    80001704:	6b42                	ld	s6,16(sp)
    80001706:	6ba2                	ld	s7,8(sp)
    80001708:	6c02                	ld	s8,0(sp)
    8000170a:	6161                	addi	sp,sp,80
    8000170c:	8082                	ret

000000008000170e <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    8000170e:	c6bd                	beqz	a3,8000177c <copyin+0x6e>
{
    80001710:	715d                	addi	sp,sp,-80
    80001712:	e486                	sd	ra,72(sp)
    80001714:	e0a2                	sd	s0,64(sp)
    80001716:	fc26                	sd	s1,56(sp)
    80001718:	f84a                	sd	s2,48(sp)
    8000171a:	f44e                	sd	s3,40(sp)
    8000171c:	f052                	sd	s4,32(sp)
    8000171e:	ec56                	sd	s5,24(sp)
    80001720:	e85a                	sd	s6,16(sp)
    80001722:	e45e                	sd	s7,8(sp)
    80001724:	e062                	sd	s8,0(sp)
    80001726:	0880                	addi	s0,sp,80
    80001728:	8b2a                	mv	s6,a0
    8000172a:	8a2e                	mv	s4,a1
    8000172c:	8c32                	mv	s8,a2
    8000172e:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001730:	7be1                	lui	s7,0xffff8
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001732:	6aa1                	lui	s5,0x8
    80001734:	a015                	j	80001758 <copyin+0x4a>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001736:	9562                	add	a0,a0,s8
    80001738:	0004861b          	sext.w	a2,s1
    8000173c:	412505b3          	sub	a1,a0,s2
    80001740:	8552                	mv	a0,s4
    80001742:	fffff097          	auipc	ra,0xfffff
    80001746:	5fe080e7          	jalr	1534(ra) # 80000d40 <memmove>

    len -= n;
    8000174a:	409989b3          	sub	s3,s3,s1
    dst += n;
    8000174e:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001750:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001754:	02098263          	beqz	s3,80001778 <copyin+0x6a>
    va0 = PGROUNDDOWN(srcva);
    80001758:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    8000175c:	85ca                	mv	a1,s2
    8000175e:	855a                	mv	a0,s6
    80001760:	00000097          	auipc	ra,0x0
    80001764:	90c080e7          	jalr	-1780(ra) # 8000106c <walkaddr>
    if(pa0 == 0)
    80001768:	cd01                	beqz	a0,80001780 <copyin+0x72>
    n = PGSIZE - (srcva - va0);
    8000176a:	418904b3          	sub	s1,s2,s8
    8000176e:	94d6                	add	s1,s1,s5
    if(n > len)
    80001770:	fc99f3e3          	bgeu	s3,s1,80001736 <copyin+0x28>
    80001774:	84ce                	mv	s1,s3
    80001776:	b7c1                	j	80001736 <copyin+0x28>
  }
  return 0;
    80001778:	4501                	li	a0,0
    8000177a:	a021                	j	80001782 <copyin+0x74>
    8000177c:	4501                	li	a0,0
}
    8000177e:	8082                	ret
      return -1;
    80001780:	557d                	li	a0,-1
}
    80001782:	60a6                	ld	ra,72(sp)
    80001784:	6406                	ld	s0,64(sp)
    80001786:	74e2                	ld	s1,56(sp)
    80001788:	7942                	ld	s2,48(sp)
    8000178a:	79a2                	ld	s3,40(sp)
    8000178c:	7a02                	ld	s4,32(sp)
    8000178e:	6ae2                	ld	s5,24(sp)
    80001790:	6b42                	ld	s6,16(sp)
    80001792:	6ba2                	ld	s7,8(sp)
    80001794:	6c02                	ld	s8,0(sp)
    80001796:	6161                	addi	sp,sp,80
    80001798:	8082                	ret

000000008000179a <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    8000179a:	c6c5                	beqz	a3,80001842 <copyinstr+0xa8>
{
    8000179c:	715d                	addi	sp,sp,-80
    8000179e:	e486                	sd	ra,72(sp)
    800017a0:	e0a2                	sd	s0,64(sp)
    800017a2:	fc26                	sd	s1,56(sp)
    800017a4:	f84a                	sd	s2,48(sp)
    800017a6:	f44e                	sd	s3,40(sp)
    800017a8:	f052                	sd	s4,32(sp)
    800017aa:	ec56                	sd	s5,24(sp)
    800017ac:	e85a                	sd	s6,16(sp)
    800017ae:	e45e                	sd	s7,8(sp)
    800017b0:	0880                	addi	s0,sp,80
    800017b2:	8a2a                	mv	s4,a0
    800017b4:	8b2e                	mv	s6,a1
    800017b6:	8bb2                	mv	s7,a2
    800017b8:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800017ba:	7ae1                	lui	s5,0xffff8
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017bc:	69a1                	lui	s3,0x8
    800017be:	a035                	j	800017ea <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800017c0:	00078023          	sb	zero,0(a5) # 8000 <_entry-0x7fff8000>
    800017c4:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800017c6:	0017b793          	seqz	a5,a5
    800017ca:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800017ce:	60a6                	ld	ra,72(sp)
    800017d0:	6406                	ld	s0,64(sp)
    800017d2:	74e2                	ld	s1,56(sp)
    800017d4:	7942                	ld	s2,48(sp)
    800017d6:	79a2                	ld	s3,40(sp)
    800017d8:	7a02                	ld	s4,32(sp)
    800017da:	6ae2                	ld	s5,24(sp)
    800017dc:	6b42                	ld	s6,16(sp)
    800017de:	6ba2                	ld	s7,8(sp)
    800017e0:	6161                	addi	sp,sp,80
    800017e2:	8082                	ret
    srcva = va0 + PGSIZE;
    800017e4:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800017e8:	c8a9                	beqz	s1,8000183a <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    800017ea:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800017ee:	85ca                	mv	a1,s2
    800017f0:	8552                	mv	a0,s4
    800017f2:	00000097          	auipc	ra,0x0
    800017f6:	87a080e7          	jalr	-1926(ra) # 8000106c <walkaddr>
    if(pa0 == 0)
    800017fa:	c131                	beqz	a0,8000183e <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    800017fc:	41790833          	sub	a6,s2,s7
    80001800:	984e                	add	a6,a6,s3
    if(n > max)
    80001802:	0104f363          	bgeu	s1,a6,80001808 <copyinstr+0x6e>
    80001806:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    80001808:	955e                	add	a0,a0,s7
    8000180a:	41250533          	sub	a0,a0,s2
    while(n > 0){
    8000180e:	fc080be3          	beqz	a6,800017e4 <copyinstr+0x4a>
    80001812:	985a                	add	a6,a6,s6
    80001814:	87da                	mv	a5,s6
      if(*p == '\0'){
    80001816:	41650633          	sub	a2,a0,s6
    8000181a:	14fd                	addi	s1,s1,-1
    8000181c:	9b26                	add	s6,s6,s1
    8000181e:	00f60733          	add	a4,a2,a5
    80001822:	00074703          	lbu	a4,0(a4)
    80001826:	df49                	beqz	a4,800017c0 <copyinstr+0x26>
        *dst = *p;
    80001828:	00e78023          	sb	a4,0(a5)
      --max;
    8000182c:	40fb04b3          	sub	s1,s6,a5
      dst++;
    80001830:	0785                	addi	a5,a5,1
    while(n > 0){
    80001832:	ff0796e3          	bne	a5,a6,8000181e <copyinstr+0x84>
      dst++;
    80001836:	8b42                	mv	s6,a6
    80001838:	b775                	j	800017e4 <copyinstr+0x4a>
    8000183a:	4781                	li	a5,0
    8000183c:	b769                	j	800017c6 <copyinstr+0x2c>
      return -1;
    8000183e:	557d                	li	a0,-1
    80001840:	b779                	j	800017ce <copyinstr+0x34>
  int got_null = 0;
    80001842:	4781                	li	a5,0
  if(got_null){
    80001844:	0017b793          	seqz	a5,a5
    80001848:	40f00533          	neg	a0,a5
}
    8000184c:	8082                	ret

000000008000184e <debug_uvmpte>:

int
debug_uvmpte(pagetable_t pagetable, uint64 va, uint64 size)
{
    8000184e:	7139                	addi	sp,sp,-64
    80001850:	fc06                	sd	ra,56(sp)
    80001852:	f822                	sd	s0,48(sp)
    80001854:	f426                	sd	s1,40(sp)
    80001856:	f04a                	sd	s2,32(sp)
    80001858:	ec4e                	sd	s3,24(sp)
    8000185a:	e852                	sd	s4,16(sp)
    8000185c:	e456                	sd	s5,8(sp)
    8000185e:	0080                	addi	s0,sp,64
    80001860:	89aa                	mv	s3,a0
	uint64 a, last;
	pte_t *pte;

	a = PGROUNDDOWN(va);
    80001862:	77e1                	lui	a5,0xffff8
    80001864:	00f5f4b3          	and	s1,a1,a5
	last = PGROUNDDOWN(va + size - 1);
    80001868:	fff60913          	addi	s2,a2,-1 # 7fff <_entry-0x7fff8001>
    8000186c:	992e                	add	s2,s2,a1
    8000186e:	00f97933          	and	s2,s2,a5
		if((pte = walk(pagetable, a, 1)) == 0) return -1;
		if(a == last){
			printf("%x\n", *pte);
			break;
		}
		a += PGSIZE;
    80001872:	6aa1                	lui	s5,0x8
		printf("%x\n", *pte);
    80001874:	00007a17          	auipc	s4,0x7
    80001878:	874a0a13          	addi	s4,s4,-1932 # 800080e8 <digits+0xa8>
		if((pte = walk(pagetable, a, 1)) == 0) return -1;
    8000187c:	4605                	li	a2,1
    8000187e:	85a6                	mv	a1,s1
    80001880:	854e                	mv	a0,s3
    80001882:	fffff097          	auipc	ra,0xfffff
    80001886:	746080e7          	jalr	1862(ra) # 80000fc8 <walk>
    8000188a:	c515                	beqz	a0,800018b6 <debug_uvmpte+0x68>
		if(a == last){
    8000188c:	01248a63          	beq	s1,s2,800018a0 <debug_uvmpte+0x52>
		a += PGSIZE;
    80001890:	94d6                	add	s1,s1,s5
		printf("%x\n", *pte);
    80001892:	610c                	ld	a1,0(a0)
    80001894:	8552                	mv	a0,s4
    80001896:	fffff097          	auipc	ra,0xfffff
    8000189a:	cf2080e7          	jalr	-782(ra) # 80000588 <printf>
		if((pte = walk(pagetable, a, 1)) == 0) return -1;
    8000189e:	bff9                	j	8000187c <debug_uvmpte+0x2e>
			printf("%x\n", *pte);
    800018a0:	610c                	ld	a1,0(a0)
    800018a2:	00007517          	auipc	a0,0x7
    800018a6:	84650513          	addi	a0,a0,-1978 # 800080e8 <digits+0xa8>
    800018aa:	fffff097          	auipc	ra,0xfffff
    800018ae:	cde080e7          	jalr	-802(ra) # 80000588 <printf>
	}
	return 0;
    800018b2:	4501                	li	a0,0
    800018b4:	a011                	j	800018b8 <debug_uvmpte+0x6a>
		if((pte = walk(pagetable, a, 1)) == 0) return -1;
    800018b6:	557d                	li	a0,-1

}
    800018b8:	70e2                	ld	ra,56(sp)
    800018ba:	7442                	ld	s0,48(sp)
    800018bc:	74a2                	ld	s1,40(sp)
    800018be:	7902                	ld	s2,32(sp)
    800018c0:	69e2                	ld	s3,24(sp)
    800018c2:	6a42                	ld	s4,16(sp)
    800018c4:	6aa2                	ld	s5,8(sp)
    800018c6:	6121                	addi	sp,sp,64
    800018c8:	8082                	ret

00000000800018ca <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl) {
    800018ca:	7139                	addi	sp,sp,-64
    800018cc:	fc06                	sd	ra,56(sp)
    800018ce:	f822                	sd	s0,48(sp)
    800018d0:	f426                	sd	s1,40(sp)
    800018d2:	f04a                	sd	s2,32(sp)
    800018d4:	ec4e                	sd	s3,24(sp)
    800018d6:	e852                	sd	s4,16(sp)
    800018d8:	e456                	sd	s5,8(sp)
    800018da:	e05a                	sd	s6,0(sp)
    800018dc:	0080                	addi	s0,sp,64
    800018de:	89aa                	mv	s3,a0
	struct proc *p;

	for(p = proc; p < &proc[NPROC]; p++) {
    800018e0:	00017497          	auipc	s1,0x17
    800018e4:	df048493          	addi	s1,s1,-528 # 800186d0 <proc>
		char *pa = kalloc();
		if(pa == 0)
			panic("kalloc");
		uint64 va = KSTACK((int) (p - proc));
    800018e8:	8b26                	mv	s6,s1
    800018ea:	00006a97          	auipc	s5,0x6
    800018ee:	716a8a93          	addi	s5,s5,1814 # 80008000 <etext>
    800018f2:	00800937          	lui	s2,0x800
    800018f6:	197d                	addi	s2,s2,-1
    800018f8:	093e                	slli	s2,s2,0xf
	for(p = proc; p < &proc[NPROC]; p++) {
    800018fa:	0001ca17          	auipc	s4,0x1c
    800018fe:	7d6a0a13          	addi	s4,s4,2006 # 8001e0d0 <tickslock>
		char *pa = kalloc();
    80001902:	fffff097          	auipc	ra,0xfffff
    80001906:	1f2080e7          	jalr	498(ra) # 80000af4 <kalloc>
    8000190a:	862a                	mv	a2,a0
		if(pa == 0)
    8000190c:	c131                	beqz	a0,80001950 <proc_mapstacks+0x86>
		uint64 va = KSTACK((int) (p - proc));
    8000190e:	416485b3          	sub	a1,s1,s6
    80001912:	858d                	srai	a1,a1,0x3
    80001914:	000ab783          	ld	a5,0(s5)
    80001918:	02f585b3          	mul	a1,a1,a5
    8000191c:	2585                	addiw	a1,a1,1
    8000191e:	0105959b          	slliw	a1,a1,0x10
		kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001922:	4719                	li	a4,6
    80001924:	66a1                	lui	a3,0x8
    80001926:	40b905b3          	sub	a1,s2,a1
    8000192a:	854e                	mv	a0,s3
    8000192c:	00000097          	auipc	ra,0x0
    80001930:	834080e7          	jalr	-1996(ra) # 80001160 <kvmmap>
	for(p = proc; p < &proc[NPROC]; p++) {
    80001934:	16848493          	addi	s1,s1,360
    80001938:	fd4495e3          	bne	s1,s4,80001902 <proc_mapstacks+0x38>
	}
}
    8000193c:	70e2                	ld	ra,56(sp)
    8000193e:	7442                	ld	s0,48(sp)
    80001940:	74a2                	ld	s1,40(sp)
    80001942:	7902                	ld	s2,32(sp)
    80001944:	69e2                	ld	s3,24(sp)
    80001946:	6a42                	ld	s4,16(sp)
    80001948:	6aa2                	ld	s5,8(sp)
    8000194a:	6b02                	ld	s6,0(sp)
    8000194c:	6121                	addi	sp,sp,64
    8000194e:	8082                	ret
			panic("kalloc");
    80001950:	00007517          	auipc	a0,0x7
    80001954:	89050513          	addi	a0,a0,-1904 # 800081e0 <digits+0x1a0>
    80001958:	fffff097          	auipc	ra,0xfffff
    8000195c:	be6080e7          	jalr	-1050(ra) # 8000053e <panic>

0000000080001960 <procinit>:

// initialize the proc table at boot time.
void
procinit(void)
{
    80001960:	7139                	addi	sp,sp,-64
    80001962:	fc06                	sd	ra,56(sp)
    80001964:	f822                	sd	s0,48(sp)
    80001966:	f426                	sd	s1,40(sp)
    80001968:	f04a                	sd	s2,32(sp)
    8000196a:	ec4e                	sd	s3,24(sp)
    8000196c:	e852                	sd	s4,16(sp)
    8000196e:	e456                	sd	s5,8(sp)
    80001970:	e05a                	sd	s6,0(sp)
    80001972:	0080                	addi	s0,sp,64
	struct proc *p;

	initlock(&pid_lock, "nextpid");
    80001974:	00007597          	auipc	a1,0x7
    80001978:	87458593          	addi	a1,a1,-1932 # 800081e8 <digits+0x1a8>
    8000197c:	00017517          	auipc	a0,0x17
    80001980:	92450513          	addi	a0,a0,-1756 # 800182a0 <pid_lock>
    80001984:	fffff097          	auipc	ra,0xfffff
    80001988:	1d0080e7          	jalr	464(ra) # 80000b54 <initlock>
	initlock(&wait_lock, "wait_lock");
    8000198c:	00007597          	auipc	a1,0x7
    80001990:	86458593          	addi	a1,a1,-1948 # 800081f0 <digits+0x1b0>
    80001994:	00017517          	auipc	a0,0x17
    80001998:	92450513          	addi	a0,a0,-1756 # 800182b8 <wait_lock>
    8000199c:	fffff097          	auipc	ra,0xfffff
    800019a0:	1b8080e7          	jalr	440(ra) # 80000b54 <initlock>
	for(p = proc; p < &proc[NPROC]; p++) {
    800019a4:	00017497          	auipc	s1,0x17
    800019a8:	d2c48493          	addi	s1,s1,-724 # 800186d0 <proc>
		initlock(&p->lock, "proc");
    800019ac:	00007b17          	auipc	s6,0x7
    800019b0:	854b0b13          	addi	s6,s6,-1964 # 80008200 <digits+0x1c0>
		p->kstack = KSTACK((int) (p - proc));
    800019b4:	8aa6                	mv	s5,s1
    800019b6:	00006a17          	auipc	s4,0x6
    800019ba:	64aa0a13          	addi	s4,s4,1610 # 80008000 <etext>
    800019be:	00800937          	lui	s2,0x800
    800019c2:	197d                	addi	s2,s2,-1
    800019c4:	093e                	slli	s2,s2,0xf
	for(p = proc; p < &proc[NPROC]; p++) {
    800019c6:	0001c997          	auipc	s3,0x1c
    800019ca:	70a98993          	addi	s3,s3,1802 # 8001e0d0 <tickslock>
		initlock(&p->lock, "proc");
    800019ce:	85da                	mv	a1,s6
    800019d0:	8526                	mv	a0,s1
    800019d2:	fffff097          	auipc	ra,0xfffff
    800019d6:	182080e7          	jalr	386(ra) # 80000b54 <initlock>
		p->kstack = KSTACK((int) (p - proc));
    800019da:	415487b3          	sub	a5,s1,s5
    800019de:	878d                	srai	a5,a5,0x3
    800019e0:	000a3703          	ld	a4,0(s4)
    800019e4:	02e787b3          	mul	a5,a5,a4
    800019e8:	2785                	addiw	a5,a5,1
    800019ea:	0107979b          	slliw	a5,a5,0x10
    800019ee:	40f907b3          	sub	a5,s2,a5
    800019f2:	e0bc                	sd	a5,64(s1)
	for(p = proc; p < &proc[NPROC]; p++) {
    800019f4:	16848493          	addi	s1,s1,360
    800019f8:	fd349be3          	bne	s1,s3,800019ce <procinit+0x6e>
	}
}
    800019fc:	70e2                	ld	ra,56(sp)
    800019fe:	7442                	ld	s0,48(sp)
    80001a00:	74a2                	ld	s1,40(sp)
    80001a02:	7902                	ld	s2,32(sp)
    80001a04:	69e2                	ld	s3,24(sp)
    80001a06:	6a42                	ld	s4,16(sp)
    80001a08:	6aa2                	ld	s5,8(sp)
    80001a0a:	6b02                	ld	s6,0(sp)
    80001a0c:	6121                	addi	sp,sp,64
    80001a0e:	8082                	ret

0000000080001a10 <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    80001a10:	1141                	addi	sp,sp,-16
    80001a12:	e422                	sd	s0,8(sp)
    80001a14:	0800                	addi	s0,sp,16
	asm volatile("mv %0, tp" : "=r" (x) );
    80001a16:	8512                	mv	a0,tp
	int id = r_tp();
	return id;
}
    80001a18:	2501                	sext.w	a0,a0
    80001a1a:	6422                	ld	s0,8(sp)
    80001a1c:	0141                	addi	sp,sp,16
    80001a1e:	8082                	ret

0000000080001a20 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void) {
    80001a20:	1141                	addi	sp,sp,-16
    80001a22:	e422                	sd	s0,8(sp)
    80001a24:	0800                	addi	s0,sp,16
    80001a26:	8792                	mv	a5,tp
	int id = cpuid();
	struct cpu *c = &cpus[id];
    80001a28:	2781                	sext.w	a5,a5
    80001a2a:	079e                	slli	a5,a5,0x7
	return c;
}
    80001a2c:	00017517          	auipc	a0,0x17
    80001a30:	8a450513          	addi	a0,a0,-1884 # 800182d0 <cpus>
    80001a34:	953e                	add	a0,a0,a5
    80001a36:	6422                	ld	s0,8(sp)
    80001a38:	0141                	addi	sp,sp,16
    80001a3a:	8082                	ret

0000000080001a3c <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void) {
    80001a3c:	1101                	addi	sp,sp,-32
    80001a3e:	ec06                	sd	ra,24(sp)
    80001a40:	e822                	sd	s0,16(sp)
    80001a42:	e426                	sd	s1,8(sp)
    80001a44:	1000                	addi	s0,sp,32
	push_off();
    80001a46:	fffff097          	auipc	ra,0xfffff
    80001a4a:	152080e7          	jalr	338(ra) # 80000b98 <push_off>
    80001a4e:	8792                	mv	a5,tp
	struct cpu *c = mycpu();
	struct proc *p = c->proc;
    80001a50:	2781                	sext.w	a5,a5
    80001a52:	079e                	slli	a5,a5,0x7
    80001a54:	00017717          	auipc	a4,0x17
    80001a58:	84c70713          	addi	a4,a4,-1972 # 800182a0 <pid_lock>
    80001a5c:	97ba                	add	a5,a5,a4
    80001a5e:	7b84                	ld	s1,48(a5)
	pop_off();
    80001a60:	fffff097          	auipc	ra,0xfffff
    80001a64:	1d8080e7          	jalr	472(ra) # 80000c38 <pop_off>
	return p;
}
    80001a68:	8526                	mv	a0,s1
    80001a6a:	60e2                	ld	ra,24(sp)
    80001a6c:	6442                	ld	s0,16(sp)
    80001a6e:	64a2                	ld	s1,8(sp)
    80001a70:	6105                	addi	sp,sp,32
    80001a72:	8082                	ret

0000000080001a74 <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    80001a74:	1141                	addi	sp,sp,-16
    80001a76:	e406                	sd	ra,8(sp)
    80001a78:	e022                	sd	s0,0(sp)
    80001a7a:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001a7c:	00000097          	auipc	ra,0x0
    80001a80:	fc0080e7          	jalr	-64(ra) # 80001a3c <myproc>
    80001a84:	fffff097          	auipc	ra,0xfffff
    80001a88:	214080e7          	jalr	532(ra) # 80000c98 <release>

  if (first) {
    80001a8c:	00007797          	auipc	a5,0x7
    80001a90:	d947a783          	lw	a5,-620(a5) # 80008820 <first.1676>
    80001a94:	eb89                	bnez	a5,80001aa6 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001a96:	00001097          	auipc	ra,0x1
    80001a9a:	c0a080e7          	jalr	-1014(ra) # 800026a0 <usertrapret>
}
    80001a9e:	60a2                	ld	ra,8(sp)
    80001aa0:	6402                	ld	s0,0(sp)
    80001aa2:	0141                	addi	sp,sp,16
    80001aa4:	8082                	ret
    first = 0;
    80001aa6:	00007797          	auipc	a5,0x7
    80001aaa:	d607ad23          	sw	zero,-646(a5) # 80008820 <first.1676>
    fsinit(ROOTDEV);
    80001aae:	4505                	li	a0,1
    80001ab0:	00002097          	auipc	ra,0x2
    80001ab4:	932080e7          	jalr	-1742(ra) # 800033e2 <fsinit>
    80001ab8:	bff9                	j	80001a96 <forkret+0x22>

0000000080001aba <allocpid>:
allocpid() {
    80001aba:	1101                	addi	sp,sp,-32
    80001abc:	ec06                	sd	ra,24(sp)
    80001abe:	e822                	sd	s0,16(sp)
    80001ac0:	e426                	sd	s1,8(sp)
    80001ac2:	e04a                	sd	s2,0(sp)
    80001ac4:	1000                	addi	s0,sp,32
	acquire(&pid_lock);
    80001ac6:	00016917          	auipc	s2,0x16
    80001aca:	7da90913          	addi	s2,s2,2010 # 800182a0 <pid_lock>
    80001ace:	854a                	mv	a0,s2
    80001ad0:	fffff097          	auipc	ra,0xfffff
    80001ad4:	114080e7          	jalr	276(ra) # 80000be4 <acquire>
	pid = nextpid;
    80001ad8:	00007797          	auipc	a5,0x7
    80001adc:	d4c78793          	addi	a5,a5,-692 # 80008824 <nextpid>
    80001ae0:	4384                	lw	s1,0(a5)
	nextpid = nextpid + 1;
    80001ae2:	0014871b          	addiw	a4,s1,1
    80001ae6:	c398                	sw	a4,0(a5)
	release(&pid_lock);
    80001ae8:	854a                	mv	a0,s2
    80001aea:	fffff097          	auipc	ra,0xfffff
    80001aee:	1ae080e7          	jalr	430(ra) # 80000c98 <release>
}
    80001af2:	8526                	mv	a0,s1
    80001af4:	60e2                	ld	ra,24(sp)
    80001af6:	6442                	ld	s0,16(sp)
    80001af8:	64a2                	ld	s1,8(sp)
    80001afa:	6902                	ld	s2,0(sp)
    80001afc:	6105                	addi	sp,sp,32
    80001afe:	8082                	ret

0000000080001b00 <proc_pagetable>:
{
    80001b00:	1101                	addi	sp,sp,-32
    80001b02:	ec06                	sd	ra,24(sp)
    80001b04:	e822                	sd	s0,16(sp)
    80001b06:	e426                	sd	s1,8(sp)
    80001b08:	e04a                	sd	s2,0(sp)
    80001b0a:	1000                	addi	s0,sp,32
    80001b0c:	892a                	mv	s2,a0
	pagetable = uvmcreate();
    80001b0e:	00000097          	auipc	ra,0x0
    80001b12:	83c080e7          	jalr	-1988(ra) # 8000134a <uvmcreate>
    80001b16:	84aa                	mv	s1,a0
	if(pagetable == 0)
    80001b18:	c121                	beqz	a0,80001b58 <proc_pagetable+0x58>
	if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001b1a:	4729                	li	a4,10
    80001b1c:	00005697          	auipc	a3,0x5
    80001b20:	4e468693          	addi	a3,a3,1252 # 80007000 <_trampoline>
    80001b24:	6621                	lui	a2,0x8
    80001b26:	008005b7          	lui	a1,0x800
    80001b2a:	15fd                	addi	a1,a1,-1
    80001b2c:	05be                	slli	a1,a1,0xf
    80001b2e:	fffff097          	auipc	ra,0xfffff
    80001b32:	580080e7          	jalr	1408(ra) # 800010ae <mappages>
    80001b36:	02054863          	bltz	a0,80001b66 <proc_pagetable+0x66>
	if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001b3a:	4719                	li	a4,6
    80001b3c:	05893683          	ld	a3,88(s2)
    80001b40:	6621                	lui	a2,0x8
    80001b42:	004005b7          	lui	a1,0x400
    80001b46:	15fd                	addi	a1,a1,-1
    80001b48:	05c2                	slli	a1,a1,0x10
    80001b4a:	8526                	mv	a0,s1
    80001b4c:	fffff097          	auipc	ra,0xfffff
    80001b50:	562080e7          	jalr	1378(ra) # 800010ae <mappages>
    80001b54:	02054163          	bltz	a0,80001b76 <proc_pagetable+0x76>
}
    80001b58:	8526                	mv	a0,s1
    80001b5a:	60e2                	ld	ra,24(sp)
    80001b5c:	6442                	ld	s0,16(sp)
    80001b5e:	64a2                	ld	s1,8(sp)
    80001b60:	6902                	ld	s2,0(sp)
    80001b62:	6105                	addi	sp,sp,32
    80001b64:	8082                	ret
		uvmfree(pagetable, 0);
    80001b66:	4581                	li	a1,0
    80001b68:	8526                	mv	a0,s1
    80001b6a:	00000097          	auipc	ra,0x0
    80001b6e:	9dc080e7          	jalr	-1572(ra) # 80001546 <uvmfree>
		return 0;
    80001b72:	4481                	li	s1,0
    80001b74:	b7d5                	j	80001b58 <proc_pagetable+0x58>
		uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b76:	4681                	li	a3,0
    80001b78:	4605                	li	a2,1
    80001b7a:	008005b7          	lui	a1,0x800
    80001b7e:	15fd                	addi	a1,a1,-1
    80001b80:	05be                	slli	a1,a1,0xf
    80001b82:	8526                	mv	a0,s1
    80001b84:	fffff097          	auipc	ra,0xfffff
    80001b88:	702080e7          	jalr	1794(ra) # 80001286 <uvmunmap>
		uvmfree(pagetable, 0);
    80001b8c:	4581                	li	a1,0
    80001b8e:	8526                	mv	a0,s1
    80001b90:	00000097          	auipc	ra,0x0
    80001b94:	9b6080e7          	jalr	-1610(ra) # 80001546 <uvmfree>
		return 0;
    80001b98:	4481                	li	s1,0
    80001b9a:	bf7d                	j	80001b58 <proc_pagetable+0x58>

0000000080001b9c <proc_freepagetable>:
{
    80001b9c:	1101                	addi	sp,sp,-32
    80001b9e:	ec06                	sd	ra,24(sp)
    80001ba0:	e822                	sd	s0,16(sp)
    80001ba2:	e426                	sd	s1,8(sp)
    80001ba4:	e04a                	sd	s2,0(sp)
    80001ba6:	1000                	addi	s0,sp,32
    80001ba8:	84aa                	mv	s1,a0
    80001baa:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001bac:	4681                	li	a3,0
    80001bae:	4605                	li	a2,1
    80001bb0:	008005b7          	lui	a1,0x800
    80001bb4:	15fd                	addi	a1,a1,-1
    80001bb6:	05be                	slli	a1,a1,0xf
    80001bb8:	fffff097          	auipc	ra,0xfffff
    80001bbc:	6ce080e7          	jalr	1742(ra) # 80001286 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001bc0:	4681                	li	a3,0
    80001bc2:	4605                	li	a2,1
    80001bc4:	004005b7          	lui	a1,0x400
    80001bc8:	15fd                	addi	a1,a1,-1
    80001bca:	05c2                	slli	a1,a1,0x10
    80001bcc:	8526                	mv	a0,s1
    80001bce:	fffff097          	auipc	ra,0xfffff
    80001bd2:	6b8080e7          	jalr	1720(ra) # 80001286 <uvmunmap>
  uvmfree(pagetable, sz);
    80001bd6:	85ca                	mv	a1,s2
    80001bd8:	8526                	mv	a0,s1
    80001bda:	00000097          	auipc	ra,0x0
    80001bde:	96c080e7          	jalr	-1684(ra) # 80001546 <uvmfree>
}
    80001be2:	60e2                	ld	ra,24(sp)
    80001be4:	6442                	ld	s0,16(sp)
    80001be6:	64a2                	ld	s1,8(sp)
    80001be8:	6902                	ld	s2,0(sp)
    80001bea:	6105                	addi	sp,sp,32
    80001bec:	8082                	ret

0000000080001bee <freeproc>:
{
    80001bee:	1101                	addi	sp,sp,-32
    80001bf0:	ec06                	sd	ra,24(sp)
    80001bf2:	e822                	sd	s0,16(sp)
    80001bf4:	e426                	sd	s1,8(sp)
    80001bf6:	1000                	addi	s0,sp,32
    80001bf8:	84aa                	mv	s1,a0
	if(p->trapframe)
    80001bfa:	6d28                	ld	a0,88(a0)
    80001bfc:	c509                	beqz	a0,80001c06 <freeproc+0x18>
		kfree((void*)p->trapframe);
    80001bfe:	fffff097          	auipc	ra,0xfffff
    80001c02:	dfa080e7          	jalr	-518(ra) # 800009f8 <kfree>
	p->trapframe = 0;
    80001c06:	0404bc23          	sd	zero,88(s1)
	if(p->pagetable)
    80001c0a:	68a8                	ld	a0,80(s1)
    80001c0c:	c511                	beqz	a0,80001c18 <freeproc+0x2a>
		proc_freepagetable(p->pagetable, p->sz);
    80001c0e:	64ac                	ld	a1,72(s1)
    80001c10:	00000097          	auipc	ra,0x0
    80001c14:	f8c080e7          	jalr	-116(ra) # 80001b9c <proc_freepagetable>
	p->pagetable = 0;
    80001c18:	0404b823          	sd	zero,80(s1)
	p->sz = 0;
    80001c1c:	0404b423          	sd	zero,72(s1)
	p->pid = 0;
    80001c20:	0204a823          	sw	zero,48(s1)
	p->parent = 0;
    80001c24:	0204bc23          	sd	zero,56(s1)
	p->name[0] = 0;
    80001c28:	14048c23          	sb	zero,344(s1)
	p->chan = 0;
    80001c2c:	0204b023          	sd	zero,32(s1)
	p->killed = 0;
    80001c30:	0204a423          	sw	zero,40(s1)
	p->xstate = 0;
    80001c34:	0204a623          	sw	zero,44(s1)
	p->state = UNUSED;
    80001c38:	0004ac23          	sw	zero,24(s1)
}
    80001c3c:	60e2                	ld	ra,24(sp)
    80001c3e:	6442                	ld	s0,16(sp)
    80001c40:	64a2                	ld	s1,8(sp)
    80001c42:	6105                	addi	sp,sp,32
    80001c44:	8082                	ret

0000000080001c46 <allocproc>:
{
    80001c46:	1101                	addi	sp,sp,-32
    80001c48:	ec06                	sd	ra,24(sp)
    80001c4a:	e822                	sd	s0,16(sp)
    80001c4c:	e426                	sd	s1,8(sp)
    80001c4e:	e04a                	sd	s2,0(sp)
    80001c50:	1000                	addi	s0,sp,32
	for(p = proc; p < &proc[NPROC]; p++) {
    80001c52:	00017497          	auipc	s1,0x17
    80001c56:	a7e48493          	addi	s1,s1,-1410 # 800186d0 <proc>
    80001c5a:	0001c917          	auipc	s2,0x1c
    80001c5e:	47690913          	addi	s2,s2,1142 # 8001e0d0 <tickslock>
		acquire(&p->lock);
    80001c62:	8526                	mv	a0,s1
    80001c64:	fffff097          	auipc	ra,0xfffff
    80001c68:	f80080e7          	jalr	-128(ra) # 80000be4 <acquire>
		if(p->state == UNUSED) {
    80001c6c:	4c9c                	lw	a5,24(s1)
    80001c6e:	cf81                	beqz	a5,80001c86 <allocproc+0x40>
			release(&p->lock);
    80001c70:	8526                	mv	a0,s1
    80001c72:	fffff097          	auipc	ra,0xfffff
    80001c76:	026080e7          	jalr	38(ra) # 80000c98 <release>
	for(p = proc; p < &proc[NPROC]; p++) {
    80001c7a:	16848493          	addi	s1,s1,360
    80001c7e:	ff2492e3          	bne	s1,s2,80001c62 <allocproc+0x1c>
	return 0;
    80001c82:	4481                	li	s1,0
    80001c84:	a889                	j	80001cd6 <allocproc+0x90>
	p->pid = allocpid();
    80001c86:	00000097          	auipc	ra,0x0
    80001c8a:	e34080e7          	jalr	-460(ra) # 80001aba <allocpid>
    80001c8e:	d888                	sw	a0,48(s1)
	p->state = USED;
    80001c90:	4785                	li	a5,1
    80001c92:	cc9c                	sw	a5,24(s1)
	if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001c94:	fffff097          	auipc	ra,0xfffff
    80001c98:	e60080e7          	jalr	-416(ra) # 80000af4 <kalloc>
    80001c9c:	892a                	mv	s2,a0
    80001c9e:	eca8                	sd	a0,88(s1)
    80001ca0:	c131                	beqz	a0,80001ce4 <allocproc+0x9e>
	p->pagetable = proc_pagetable(p);
    80001ca2:	8526                	mv	a0,s1
    80001ca4:	00000097          	auipc	ra,0x0
    80001ca8:	e5c080e7          	jalr	-420(ra) # 80001b00 <proc_pagetable>
    80001cac:	892a                	mv	s2,a0
    80001cae:	e8a8                	sd	a0,80(s1)
	if(p->pagetable == 0){
    80001cb0:	c531                	beqz	a0,80001cfc <allocproc+0xb6>
	memset(&p->context, 0, sizeof(p->context));
    80001cb2:	07000613          	li	a2,112
    80001cb6:	4581                	li	a1,0
    80001cb8:	06048513          	addi	a0,s1,96
    80001cbc:	fffff097          	auipc	ra,0xfffff
    80001cc0:	024080e7          	jalr	36(ra) # 80000ce0 <memset>
	p->context.ra = (uint64)forkret;
    80001cc4:	00000797          	auipc	a5,0x0
    80001cc8:	db078793          	addi	a5,a5,-592 # 80001a74 <forkret>
    80001ccc:	f0bc                	sd	a5,96(s1)
	p->context.sp = p->kstack + PGSIZE;
    80001cce:	60bc                	ld	a5,64(s1)
    80001cd0:	6721                	lui	a4,0x8
    80001cd2:	97ba                	add	a5,a5,a4
    80001cd4:	f4bc                	sd	a5,104(s1)
}
    80001cd6:	8526                	mv	a0,s1
    80001cd8:	60e2                	ld	ra,24(sp)
    80001cda:	6442                	ld	s0,16(sp)
    80001cdc:	64a2                	ld	s1,8(sp)
    80001cde:	6902                	ld	s2,0(sp)
    80001ce0:	6105                	addi	sp,sp,32
    80001ce2:	8082                	ret
		freeproc(p);
    80001ce4:	8526                	mv	a0,s1
    80001ce6:	00000097          	auipc	ra,0x0
    80001cea:	f08080e7          	jalr	-248(ra) # 80001bee <freeproc>
		release(&p->lock);
    80001cee:	8526                	mv	a0,s1
    80001cf0:	fffff097          	auipc	ra,0xfffff
    80001cf4:	fa8080e7          	jalr	-88(ra) # 80000c98 <release>
		return 0;
    80001cf8:	84ca                	mv	s1,s2
    80001cfa:	bff1                	j	80001cd6 <allocproc+0x90>
		freeproc(p);
    80001cfc:	8526                	mv	a0,s1
    80001cfe:	00000097          	auipc	ra,0x0
    80001d02:	ef0080e7          	jalr	-272(ra) # 80001bee <freeproc>
		release(&p->lock);
    80001d06:	8526                	mv	a0,s1
    80001d08:	fffff097          	auipc	ra,0xfffff
    80001d0c:	f90080e7          	jalr	-112(ra) # 80000c98 <release>
		return 0;
    80001d10:	84ca                	mv	s1,s2
    80001d12:	b7d1                	j	80001cd6 <allocproc+0x90>

0000000080001d14 <userinit>:
{
    80001d14:	1101                	addi	sp,sp,-32
    80001d16:	ec06                	sd	ra,24(sp)
    80001d18:	e822                	sd	s0,16(sp)
    80001d1a:	e426                	sd	s1,8(sp)
    80001d1c:	1000                	addi	s0,sp,32
	p = allocproc();
    80001d1e:	00000097          	auipc	ra,0x0
    80001d22:	f28080e7          	jalr	-216(ra) # 80001c46 <allocproc>
    80001d26:	84aa                	mv	s1,a0
	initproc = p;
    80001d28:	0000e797          	auipc	a5,0xe
    80001d2c:	30a7b023          	sd	a0,768(a5) # 80010028 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001d30:	03400613          	li	a2,52
    80001d34:	00007597          	auipc	a1,0x7
    80001d38:	afc58593          	addi	a1,a1,-1284 # 80008830 <initcode>
    80001d3c:	6928                	ld	a0,80(a0)
    80001d3e:	fffff097          	auipc	ra,0xfffff
    80001d42:	63a080e7          	jalr	1594(ra) # 80001378 <uvminit>
	p->sz = PGSIZE;
    80001d46:	67a1                	lui	a5,0x8
    80001d48:	e4bc                	sd	a5,72(s1)
	p->trapframe->epc = 0;      // user program counter
    80001d4a:	6cb8                	ld	a4,88(s1)
    80001d4c:	00073c23          	sd	zero,24(a4) # 8018 <_entry-0x7fff7fe8>
	p->trapframe->sp = PGSIZE;  // user stack pointer
    80001d50:	6cb8                	ld	a4,88(s1)
    80001d52:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001d54:	4641                	li	a2,16
    80001d56:	00006597          	auipc	a1,0x6
    80001d5a:	4b258593          	addi	a1,a1,1202 # 80008208 <digits+0x1c8>
    80001d5e:	15848513          	addi	a0,s1,344
    80001d62:	fffff097          	auipc	ra,0xfffff
    80001d66:	0d0080e7          	jalr	208(ra) # 80000e32 <safestrcpy>
	p->cwd = namei("/");
    80001d6a:	00006517          	auipc	a0,0x6
    80001d6e:	4ae50513          	addi	a0,a0,1198 # 80008218 <digits+0x1d8>
    80001d72:	00002097          	auipc	ra,0x2
    80001d76:	09e080e7          	jalr	158(ra) # 80003e10 <namei>
    80001d7a:	14a4b823          	sd	a0,336(s1)
	p->state = RUNNABLE;
    80001d7e:	478d                	li	a5,3
    80001d80:	cc9c                	sw	a5,24(s1)
	release(&p->lock);
    80001d82:	8526                	mv	a0,s1
    80001d84:	fffff097          	auipc	ra,0xfffff
    80001d88:	f14080e7          	jalr	-236(ra) # 80000c98 <release>
}
    80001d8c:	60e2                	ld	ra,24(sp)
    80001d8e:	6442                	ld	s0,16(sp)
    80001d90:	64a2                	ld	s1,8(sp)
    80001d92:	6105                	addi	sp,sp,32
    80001d94:	8082                	ret

0000000080001d96 <growproc>:
{
    80001d96:	1101                	addi	sp,sp,-32
    80001d98:	ec06                	sd	ra,24(sp)
    80001d9a:	e822                	sd	s0,16(sp)
    80001d9c:	e426                	sd	s1,8(sp)
    80001d9e:	e04a                	sd	s2,0(sp)
    80001da0:	1000                	addi	s0,sp,32
    80001da2:	84aa                	mv	s1,a0
	struct proc *p = myproc();
    80001da4:	00000097          	auipc	ra,0x0
    80001da8:	c98080e7          	jalr	-872(ra) # 80001a3c <myproc>
    80001dac:	892a                	mv	s2,a0
	sz = p->sz;
    80001dae:	652c                	ld	a1,72(a0)
    80001db0:	0005861b          	sext.w	a2,a1
	if(n > 0){
    80001db4:	00904f63          	bgtz	s1,80001dd2 <growproc+0x3c>
	} else if(n < 0){
    80001db8:	0204cc63          	bltz	s1,80001df0 <growproc+0x5a>
	p->sz = sz;
    80001dbc:	1602                	slli	a2,a2,0x20
    80001dbe:	9201                	srli	a2,a2,0x20
    80001dc0:	04c93423          	sd	a2,72(s2)
	return 0;
    80001dc4:	4501                	li	a0,0
}
    80001dc6:	60e2                	ld	ra,24(sp)
    80001dc8:	6442                	ld	s0,16(sp)
    80001dca:	64a2                	ld	s1,8(sp)
    80001dcc:	6902                	ld	s2,0(sp)
    80001dce:	6105                	addi	sp,sp,32
    80001dd0:	8082                	ret
		if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001dd2:	9e25                	addw	a2,a2,s1
    80001dd4:	1602                	slli	a2,a2,0x20
    80001dd6:	9201                	srli	a2,a2,0x20
    80001dd8:	1582                	slli	a1,a1,0x20
    80001dda:	9181                	srli	a1,a1,0x20
    80001ddc:	6928                	ld	a0,80(a0)
    80001dde:	fffff097          	auipc	ra,0xfffff
    80001de2:	654080e7          	jalr	1620(ra) # 80001432 <uvmalloc>
    80001de6:	0005061b          	sext.w	a2,a0
    80001dea:	fa69                	bnez	a2,80001dbc <growproc+0x26>
			return -1;
    80001dec:	557d                	li	a0,-1
    80001dee:	bfe1                	j	80001dc6 <growproc+0x30>
		sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001df0:	9e25                	addw	a2,a2,s1
    80001df2:	1602                	slli	a2,a2,0x20
    80001df4:	9201                	srli	a2,a2,0x20
    80001df6:	1582                	slli	a1,a1,0x20
    80001df8:	9181                	srli	a1,a1,0x20
    80001dfa:	6928                	ld	a0,80(a0)
    80001dfc:	fffff097          	auipc	ra,0xfffff
    80001e00:	5ee080e7          	jalr	1518(ra) # 800013ea <uvmdealloc>
    80001e04:	0005061b          	sext.w	a2,a0
    80001e08:	bf55                	j	80001dbc <growproc+0x26>

0000000080001e0a <fork>:
{
    80001e0a:	7179                	addi	sp,sp,-48
    80001e0c:	f406                	sd	ra,40(sp)
    80001e0e:	f022                	sd	s0,32(sp)
    80001e10:	ec26                	sd	s1,24(sp)
    80001e12:	e84a                	sd	s2,16(sp)
    80001e14:	e44e                	sd	s3,8(sp)
    80001e16:	e052                	sd	s4,0(sp)
    80001e18:	1800                	addi	s0,sp,48
	struct proc *p = myproc();
    80001e1a:	00000097          	auipc	ra,0x0
    80001e1e:	c22080e7          	jalr	-990(ra) # 80001a3c <myproc>
    80001e22:	892a                	mv	s2,a0
	if((np = allocproc()) == 0){
    80001e24:	00000097          	auipc	ra,0x0
    80001e28:	e22080e7          	jalr	-478(ra) # 80001c46 <allocproc>
    80001e2c:	10050b63          	beqz	a0,80001f42 <fork+0x138>
    80001e30:	89aa                	mv	s3,a0
	if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001e32:	04893603          	ld	a2,72(s2)
    80001e36:	692c                	ld	a1,80(a0)
    80001e38:	05093503          	ld	a0,80(s2)
    80001e3c:	fffff097          	auipc	ra,0xfffff
    80001e40:	742080e7          	jalr	1858(ra) # 8000157e <uvmcopy>
    80001e44:	04054663          	bltz	a0,80001e90 <fork+0x86>
	np->sz = p->sz;
    80001e48:	04893783          	ld	a5,72(s2)
    80001e4c:	04f9b423          	sd	a5,72(s3)
	*(np->trapframe) = *(p->trapframe);
    80001e50:	05893683          	ld	a3,88(s2)
    80001e54:	87b6                	mv	a5,a3
    80001e56:	0589b703          	ld	a4,88(s3)
    80001e5a:	12068693          	addi	a3,a3,288
    80001e5e:	0007b803          	ld	a6,0(a5) # 8000 <_entry-0x7fff8000>
    80001e62:	6788                	ld	a0,8(a5)
    80001e64:	6b8c                	ld	a1,16(a5)
    80001e66:	6f90                	ld	a2,24(a5)
    80001e68:	01073023          	sd	a6,0(a4)
    80001e6c:	e708                	sd	a0,8(a4)
    80001e6e:	eb0c                	sd	a1,16(a4)
    80001e70:	ef10                	sd	a2,24(a4)
    80001e72:	02078793          	addi	a5,a5,32
    80001e76:	02070713          	addi	a4,a4,32
    80001e7a:	fed792e3          	bne	a5,a3,80001e5e <fork+0x54>
	np->trapframe->a0 = 0;
    80001e7e:	0589b783          	ld	a5,88(s3)
    80001e82:	0607b823          	sd	zero,112(a5)
    80001e86:	0d000493          	li	s1,208
	for(i = 0; i < NOFILE; i++)
    80001e8a:	15000a13          	li	s4,336
    80001e8e:	a03d                	j	80001ebc <fork+0xb2>
		freeproc(np);
    80001e90:	854e                	mv	a0,s3
    80001e92:	00000097          	auipc	ra,0x0
    80001e96:	d5c080e7          	jalr	-676(ra) # 80001bee <freeproc>
		release(&np->lock);
    80001e9a:	854e                	mv	a0,s3
    80001e9c:	fffff097          	auipc	ra,0xfffff
    80001ea0:	dfc080e7          	jalr	-516(ra) # 80000c98 <release>
		return -1;
    80001ea4:	5a7d                	li	s4,-1
    80001ea6:	a069                	j	80001f30 <fork+0x126>
			np->ofile[i] = filedup(p->ofile[i]);
    80001ea8:	00002097          	auipc	ra,0x2
    80001eac:	5fe080e7          	jalr	1534(ra) # 800044a6 <filedup>
    80001eb0:	009987b3          	add	a5,s3,s1
    80001eb4:	e388                	sd	a0,0(a5)
	for(i = 0; i < NOFILE; i++)
    80001eb6:	04a1                	addi	s1,s1,8
    80001eb8:	01448763          	beq	s1,s4,80001ec6 <fork+0xbc>
		if(p->ofile[i])
    80001ebc:	009907b3          	add	a5,s2,s1
    80001ec0:	6388                	ld	a0,0(a5)
    80001ec2:	f17d                	bnez	a0,80001ea8 <fork+0x9e>
    80001ec4:	bfcd                	j	80001eb6 <fork+0xac>
	np->cwd = idup(p->cwd);
    80001ec6:	15093503          	ld	a0,336(s2)
    80001eca:	00001097          	auipc	ra,0x1
    80001ece:	752080e7          	jalr	1874(ra) # 8000361c <idup>
    80001ed2:	14a9b823          	sd	a0,336(s3)
	safestrcpy(np->name, p->name, sizeof(p->name));
    80001ed6:	4641                	li	a2,16
    80001ed8:	15890593          	addi	a1,s2,344
    80001edc:	15898513          	addi	a0,s3,344
    80001ee0:	fffff097          	auipc	ra,0xfffff
    80001ee4:	f52080e7          	jalr	-174(ra) # 80000e32 <safestrcpy>
	pid = np->pid;
    80001ee8:	0309aa03          	lw	s4,48(s3)
	release(&np->lock);
    80001eec:	854e                	mv	a0,s3
    80001eee:	fffff097          	auipc	ra,0xfffff
    80001ef2:	daa080e7          	jalr	-598(ra) # 80000c98 <release>
	acquire(&wait_lock);
    80001ef6:	00016497          	auipc	s1,0x16
    80001efa:	3c248493          	addi	s1,s1,962 # 800182b8 <wait_lock>
    80001efe:	8526                	mv	a0,s1
    80001f00:	fffff097          	auipc	ra,0xfffff
    80001f04:	ce4080e7          	jalr	-796(ra) # 80000be4 <acquire>
	np->parent = p;
    80001f08:	0329bc23          	sd	s2,56(s3)
	release(&wait_lock);
    80001f0c:	8526                	mv	a0,s1
    80001f0e:	fffff097          	auipc	ra,0xfffff
    80001f12:	d8a080e7          	jalr	-630(ra) # 80000c98 <release>
	acquire(&np->lock);
    80001f16:	854e                	mv	a0,s3
    80001f18:	fffff097          	auipc	ra,0xfffff
    80001f1c:	ccc080e7          	jalr	-820(ra) # 80000be4 <acquire>
	np->state = RUNNABLE;
    80001f20:	478d                	li	a5,3
    80001f22:	00f9ac23          	sw	a5,24(s3)
	release(&np->lock);
    80001f26:	854e                	mv	a0,s3
    80001f28:	fffff097          	auipc	ra,0xfffff
    80001f2c:	d70080e7          	jalr	-656(ra) # 80000c98 <release>
}
    80001f30:	8552                	mv	a0,s4
    80001f32:	70a2                	ld	ra,40(sp)
    80001f34:	7402                	ld	s0,32(sp)
    80001f36:	64e2                	ld	s1,24(sp)
    80001f38:	6942                	ld	s2,16(sp)
    80001f3a:	69a2                	ld	s3,8(sp)
    80001f3c:	6a02                	ld	s4,0(sp)
    80001f3e:	6145                	addi	sp,sp,48
    80001f40:	8082                	ret
		return -1;
    80001f42:	5a7d                	li	s4,-1
    80001f44:	b7f5                	j	80001f30 <fork+0x126>

0000000080001f46 <scheduler>:
{
    80001f46:	7139                	addi	sp,sp,-64
    80001f48:	fc06                	sd	ra,56(sp)
    80001f4a:	f822                	sd	s0,48(sp)
    80001f4c:	f426                	sd	s1,40(sp)
    80001f4e:	f04a                	sd	s2,32(sp)
    80001f50:	ec4e                	sd	s3,24(sp)
    80001f52:	e852                	sd	s4,16(sp)
    80001f54:	e456                	sd	s5,8(sp)
    80001f56:	e05a                	sd	s6,0(sp)
    80001f58:	0080                	addi	s0,sp,64
    80001f5a:	8792                	mv	a5,tp
	int id = r_tp();
    80001f5c:	2781                	sext.w	a5,a5
	c->proc = 0;
    80001f5e:	00779a93          	slli	s5,a5,0x7
    80001f62:	00016717          	auipc	a4,0x16
    80001f66:	33e70713          	addi	a4,a4,830 # 800182a0 <pid_lock>
    80001f6a:	9756                	add	a4,a4,s5
    80001f6c:	02073823          	sd	zero,48(a4)
				swtch(&c->context, &p->context);
    80001f70:	00016717          	auipc	a4,0x16
    80001f74:	36870713          	addi	a4,a4,872 # 800182d8 <cpus+0x8>
    80001f78:	9aba                	add	s5,s5,a4
			if(p->state == RUNNABLE) {
    80001f7a:	498d                	li	s3,3
				p->state = RUNNING;
    80001f7c:	4b11                	li	s6,4
				c->proc = p;
    80001f7e:	079e                	slli	a5,a5,0x7
    80001f80:	00016a17          	auipc	s4,0x16
    80001f84:	320a0a13          	addi	s4,s4,800 # 800182a0 <pid_lock>
    80001f88:	9a3e                	add	s4,s4,a5
		for(p = proc; p < &proc[NPROC]; p++) {
    80001f8a:	0001c917          	auipc	s2,0x1c
    80001f8e:	14690913          	addi	s2,s2,326 # 8001e0d0 <tickslock>
	asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f92:	100027f3          	csrr	a5,sstatus
	w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001f96:	0027e793          	ori	a5,a5,2
	asm volatile("csrw sstatus, %0" : : "r" (x));
    80001f9a:	10079073          	csrw	sstatus,a5
    80001f9e:	00016497          	auipc	s1,0x16
    80001fa2:	73248493          	addi	s1,s1,1842 # 800186d0 <proc>
    80001fa6:	a03d                	j	80001fd4 <scheduler+0x8e>
				p->state = RUNNING;
    80001fa8:	0164ac23          	sw	s6,24(s1)
				c->proc = p;
    80001fac:	029a3823          	sd	s1,48(s4)
				swtch(&c->context, &p->context);
    80001fb0:	06048593          	addi	a1,s1,96
    80001fb4:	8556                	mv	a0,s5
    80001fb6:	00000097          	auipc	ra,0x0
    80001fba:	640080e7          	jalr	1600(ra) # 800025f6 <swtch>
				c->proc = 0;
    80001fbe:	020a3823          	sd	zero,48(s4)
			release(&p->lock);
    80001fc2:	8526                	mv	a0,s1
    80001fc4:	fffff097          	auipc	ra,0xfffff
    80001fc8:	cd4080e7          	jalr	-812(ra) # 80000c98 <release>
		for(p = proc; p < &proc[NPROC]; p++) {
    80001fcc:	16848493          	addi	s1,s1,360
    80001fd0:	fd2481e3          	beq	s1,s2,80001f92 <scheduler+0x4c>
			acquire(&p->lock);
    80001fd4:	8526                	mv	a0,s1
    80001fd6:	fffff097          	auipc	ra,0xfffff
    80001fda:	c0e080e7          	jalr	-1010(ra) # 80000be4 <acquire>
			if(p->state == RUNNABLE) {
    80001fde:	4c9c                	lw	a5,24(s1)
    80001fe0:	ff3791e3          	bne	a5,s3,80001fc2 <scheduler+0x7c>
    80001fe4:	b7d1                	j	80001fa8 <scheduler+0x62>

0000000080001fe6 <sched>:
{
    80001fe6:	7179                	addi	sp,sp,-48
    80001fe8:	f406                	sd	ra,40(sp)
    80001fea:	f022                	sd	s0,32(sp)
    80001fec:	ec26                	sd	s1,24(sp)
    80001fee:	e84a                	sd	s2,16(sp)
    80001ff0:	e44e                	sd	s3,8(sp)
    80001ff2:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001ff4:	00000097          	auipc	ra,0x0
    80001ff8:	a48080e7          	jalr	-1464(ra) # 80001a3c <myproc>
    80001ffc:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001ffe:	fffff097          	auipc	ra,0xfffff
    80002002:	b6c080e7          	jalr	-1172(ra) # 80000b6a <holding>
    80002006:	c93d                	beqz	a0,8000207c <sched+0x96>
	asm volatile("mv %0, tp" : "=r" (x) );
    80002008:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    8000200a:	2781                	sext.w	a5,a5
    8000200c:	079e                	slli	a5,a5,0x7
    8000200e:	00016717          	auipc	a4,0x16
    80002012:	29270713          	addi	a4,a4,658 # 800182a0 <pid_lock>
    80002016:	97ba                	add	a5,a5,a4
    80002018:	0a87a703          	lw	a4,168(a5)
    8000201c:	4785                	li	a5,1
    8000201e:	06f71763          	bne	a4,a5,8000208c <sched+0xa6>
  if(p->state == RUNNING)
    80002022:	4c98                	lw	a4,24(s1)
    80002024:	4791                	li	a5,4
    80002026:	06f70b63          	beq	a4,a5,8000209c <sched+0xb6>
	asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000202a:	100027f3          	csrr	a5,sstatus
	return (x & SSTATUS_SIE) != 0;
    8000202e:	8b89                	andi	a5,a5,2
  if(intr_get())
    80002030:	efb5                	bnez	a5,800020ac <sched+0xc6>
	asm volatile("mv %0, tp" : "=r" (x) );
    80002032:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80002034:	00016917          	auipc	s2,0x16
    80002038:	26c90913          	addi	s2,s2,620 # 800182a0 <pid_lock>
    8000203c:	2781                	sext.w	a5,a5
    8000203e:	079e                	slli	a5,a5,0x7
    80002040:	97ca                	add	a5,a5,s2
    80002042:	0ac7a983          	lw	s3,172(a5)
    80002046:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80002048:	2781                	sext.w	a5,a5
    8000204a:	079e                	slli	a5,a5,0x7
    8000204c:	00016597          	auipc	a1,0x16
    80002050:	28c58593          	addi	a1,a1,652 # 800182d8 <cpus+0x8>
    80002054:	95be                	add	a1,a1,a5
    80002056:	06048513          	addi	a0,s1,96
    8000205a:	00000097          	auipc	ra,0x0
    8000205e:	59c080e7          	jalr	1436(ra) # 800025f6 <swtch>
    80002062:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80002064:	2781                	sext.w	a5,a5
    80002066:	079e                	slli	a5,a5,0x7
    80002068:	97ca                	add	a5,a5,s2
    8000206a:	0b37a623          	sw	s3,172(a5)
}
    8000206e:	70a2                	ld	ra,40(sp)
    80002070:	7402                	ld	s0,32(sp)
    80002072:	64e2                	ld	s1,24(sp)
    80002074:	6942                	ld	s2,16(sp)
    80002076:	69a2                	ld	s3,8(sp)
    80002078:	6145                	addi	sp,sp,48
    8000207a:	8082                	ret
    panic("sched p->lock");
    8000207c:	00006517          	auipc	a0,0x6
    80002080:	1a450513          	addi	a0,a0,420 # 80008220 <digits+0x1e0>
    80002084:	ffffe097          	auipc	ra,0xffffe
    80002088:	4ba080e7          	jalr	1210(ra) # 8000053e <panic>
    panic("sched locks");
    8000208c:	00006517          	auipc	a0,0x6
    80002090:	1a450513          	addi	a0,a0,420 # 80008230 <digits+0x1f0>
    80002094:	ffffe097          	auipc	ra,0xffffe
    80002098:	4aa080e7          	jalr	1194(ra) # 8000053e <panic>
    panic("sched running");
    8000209c:	00006517          	auipc	a0,0x6
    800020a0:	1a450513          	addi	a0,a0,420 # 80008240 <digits+0x200>
    800020a4:	ffffe097          	auipc	ra,0xffffe
    800020a8:	49a080e7          	jalr	1178(ra) # 8000053e <panic>
    panic("sched interruptible");
    800020ac:	00006517          	auipc	a0,0x6
    800020b0:	1a450513          	addi	a0,a0,420 # 80008250 <digits+0x210>
    800020b4:	ffffe097          	auipc	ra,0xffffe
    800020b8:	48a080e7          	jalr	1162(ra) # 8000053e <panic>

00000000800020bc <yield>:
{
    800020bc:	1101                	addi	sp,sp,-32
    800020be:	ec06                	sd	ra,24(sp)
    800020c0:	e822                	sd	s0,16(sp)
    800020c2:	e426                	sd	s1,8(sp)
    800020c4:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    800020c6:	00000097          	auipc	ra,0x0
    800020ca:	976080e7          	jalr	-1674(ra) # 80001a3c <myproc>
    800020ce:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800020d0:	fffff097          	auipc	ra,0xfffff
    800020d4:	b14080e7          	jalr	-1260(ra) # 80000be4 <acquire>
  p->state = RUNNABLE;
    800020d8:	478d                	li	a5,3
    800020da:	cc9c                	sw	a5,24(s1)
  sched();
    800020dc:	00000097          	auipc	ra,0x0
    800020e0:	f0a080e7          	jalr	-246(ra) # 80001fe6 <sched>
  release(&p->lock);
    800020e4:	8526                	mv	a0,s1
    800020e6:	fffff097          	auipc	ra,0xfffff
    800020ea:	bb2080e7          	jalr	-1102(ra) # 80000c98 <release>
}
    800020ee:	60e2                	ld	ra,24(sp)
    800020f0:	6442                	ld	s0,16(sp)
    800020f2:	64a2                	ld	s1,8(sp)
    800020f4:	6105                	addi	sp,sp,32
    800020f6:	8082                	ret

00000000800020f8 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    800020f8:	7179                	addi	sp,sp,-48
    800020fa:	f406                	sd	ra,40(sp)
    800020fc:	f022                	sd	s0,32(sp)
    800020fe:	ec26                	sd	s1,24(sp)
    80002100:	e84a                	sd	s2,16(sp)
    80002102:	e44e                	sd	s3,8(sp)
    80002104:	1800                	addi	s0,sp,48
    80002106:	89aa                	mv	s3,a0
    80002108:	892e                	mv	s2,a1
	struct proc *p = myproc();
    8000210a:	00000097          	auipc	ra,0x0
    8000210e:	932080e7          	jalr	-1742(ra) # 80001a3c <myproc>
    80002112:	84aa                	mv	s1,a0
	// Once we hold p->lock, we can be
	// guaranteed that we won't miss any wakeup
	// (wakeup locks p->lock),
	// so it's okay to release lk.

	acquire(&p->lock);  //DOC: sleeplock1
    80002114:	fffff097          	auipc	ra,0xfffff
    80002118:	ad0080e7          	jalr	-1328(ra) # 80000be4 <acquire>
	release(lk);
    8000211c:	854a                	mv	a0,s2
    8000211e:	fffff097          	auipc	ra,0xfffff
    80002122:	b7a080e7          	jalr	-1158(ra) # 80000c98 <release>

	// Go to sleep.
	p->chan = chan;
    80002126:	0334b023          	sd	s3,32(s1)
	p->state = SLEEPING;
    8000212a:	4789                	li	a5,2
    8000212c:	cc9c                	sw	a5,24(s1)

	sched();
    8000212e:	00000097          	auipc	ra,0x0
    80002132:	eb8080e7          	jalr	-328(ra) # 80001fe6 <sched>

	// Tidy up.
	p->chan = 0;
    80002136:	0204b023          	sd	zero,32(s1)

	// Reacquire original lock.
	release(&p->lock);
    8000213a:	8526                	mv	a0,s1
    8000213c:	fffff097          	auipc	ra,0xfffff
    80002140:	b5c080e7          	jalr	-1188(ra) # 80000c98 <release>
	acquire(lk);
    80002144:	854a                	mv	a0,s2
    80002146:	fffff097          	auipc	ra,0xfffff
    8000214a:	a9e080e7          	jalr	-1378(ra) # 80000be4 <acquire>
}
    8000214e:	70a2                	ld	ra,40(sp)
    80002150:	7402                	ld	s0,32(sp)
    80002152:	64e2                	ld	s1,24(sp)
    80002154:	6942                	ld	s2,16(sp)
    80002156:	69a2                	ld	s3,8(sp)
    80002158:	6145                	addi	sp,sp,48
    8000215a:	8082                	ret

000000008000215c <wait>:
{
    8000215c:	715d                	addi	sp,sp,-80
    8000215e:	e486                	sd	ra,72(sp)
    80002160:	e0a2                	sd	s0,64(sp)
    80002162:	fc26                	sd	s1,56(sp)
    80002164:	f84a                	sd	s2,48(sp)
    80002166:	f44e                	sd	s3,40(sp)
    80002168:	f052                	sd	s4,32(sp)
    8000216a:	ec56                	sd	s5,24(sp)
    8000216c:	e85a                	sd	s6,16(sp)
    8000216e:	e45e                	sd	s7,8(sp)
    80002170:	e062                	sd	s8,0(sp)
    80002172:	0880                	addi	s0,sp,80
    80002174:	8b2a                	mv	s6,a0
	struct proc *p = myproc();
    80002176:	00000097          	auipc	ra,0x0
    8000217a:	8c6080e7          	jalr	-1850(ra) # 80001a3c <myproc>
    8000217e:	892a                	mv	s2,a0
	acquire(&wait_lock);
    80002180:	00016517          	auipc	a0,0x16
    80002184:	13850513          	addi	a0,a0,312 # 800182b8 <wait_lock>
    80002188:	fffff097          	auipc	ra,0xfffff
    8000218c:	a5c080e7          	jalr	-1444(ra) # 80000be4 <acquire>
		havekids = 0;
    80002190:	4b81                	li	s7,0
				if(np->state == ZOMBIE){
    80002192:	4a15                	li	s4,5
		for(np = proc; np < &proc[NPROC]; np++){
    80002194:	0001c997          	auipc	s3,0x1c
    80002198:	f3c98993          	addi	s3,s3,-196 # 8001e0d0 <tickslock>
				havekids = 1;
    8000219c:	4a85                	li	s5,1
		sleep(p, &wait_lock);  //DOC: wait-sleep
    8000219e:	00016c17          	auipc	s8,0x16
    800021a2:	11ac0c13          	addi	s8,s8,282 # 800182b8 <wait_lock>
		havekids = 0;
    800021a6:	875e                	mv	a4,s7
		for(np = proc; np < &proc[NPROC]; np++){
    800021a8:	00016497          	auipc	s1,0x16
    800021ac:	52848493          	addi	s1,s1,1320 # 800186d0 <proc>
    800021b0:	a0bd                	j	8000221e <wait+0xc2>
					pid = np->pid;
    800021b2:	0304a983          	lw	s3,48(s1)
					if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    800021b6:	000b0e63          	beqz	s6,800021d2 <wait+0x76>
    800021ba:	4691                	li	a3,4
    800021bc:	02c48613          	addi	a2,s1,44
    800021c0:	85da                	mv	a1,s6
    800021c2:	05093503          	ld	a0,80(s2)
    800021c6:	fffff097          	auipc	ra,0xfffff
    800021ca:	4bc080e7          	jalr	1212(ra) # 80001682 <copyout>
    800021ce:	02054563          	bltz	a0,800021f8 <wait+0x9c>
					freeproc(np);
    800021d2:	8526                	mv	a0,s1
    800021d4:	00000097          	auipc	ra,0x0
    800021d8:	a1a080e7          	jalr	-1510(ra) # 80001bee <freeproc>
					release(&np->lock);
    800021dc:	8526                	mv	a0,s1
    800021de:	fffff097          	auipc	ra,0xfffff
    800021e2:	aba080e7          	jalr	-1350(ra) # 80000c98 <release>
					release(&wait_lock);
    800021e6:	00016517          	auipc	a0,0x16
    800021ea:	0d250513          	addi	a0,a0,210 # 800182b8 <wait_lock>
    800021ee:	fffff097          	auipc	ra,0xfffff
    800021f2:	aaa080e7          	jalr	-1366(ra) # 80000c98 <release>
					return pid;
    800021f6:	a09d                	j	8000225c <wait+0x100>
						release(&np->lock);
    800021f8:	8526                	mv	a0,s1
    800021fa:	fffff097          	auipc	ra,0xfffff
    800021fe:	a9e080e7          	jalr	-1378(ra) # 80000c98 <release>
						release(&wait_lock);
    80002202:	00016517          	auipc	a0,0x16
    80002206:	0b650513          	addi	a0,a0,182 # 800182b8 <wait_lock>
    8000220a:	fffff097          	auipc	ra,0xfffff
    8000220e:	a8e080e7          	jalr	-1394(ra) # 80000c98 <release>
						return -1;
    80002212:	59fd                	li	s3,-1
    80002214:	a0a1                	j	8000225c <wait+0x100>
		for(np = proc; np < &proc[NPROC]; np++){
    80002216:	16848493          	addi	s1,s1,360
    8000221a:	03348463          	beq	s1,s3,80002242 <wait+0xe6>
			if(np->parent == p){
    8000221e:	7c9c                	ld	a5,56(s1)
    80002220:	ff279be3          	bne	a5,s2,80002216 <wait+0xba>
				acquire(&np->lock);
    80002224:	8526                	mv	a0,s1
    80002226:	fffff097          	auipc	ra,0xfffff
    8000222a:	9be080e7          	jalr	-1602(ra) # 80000be4 <acquire>
				if(np->state == ZOMBIE){
    8000222e:	4c9c                	lw	a5,24(s1)
    80002230:	f94781e3          	beq	a5,s4,800021b2 <wait+0x56>
				release(&np->lock);
    80002234:	8526                	mv	a0,s1
    80002236:	fffff097          	auipc	ra,0xfffff
    8000223a:	a62080e7          	jalr	-1438(ra) # 80000c98 <release>
				havekids = 1;
    8000223e:	8756                	mv	a4,s5
    80002240:	bfd9                	j	80002216 <wait+0xba>
		if(!havekids || p->killed){
    80002242:	c701                	beqz	a4,8000224a <wait+0xee>
    80002244:	02892783          	lw	a5,40(s2)
    80002248:	c79d                	beqz	a5,80002276 <wait+0x11a>
			release(&wait_lock);
    8000224a:	00016517          	auipc	a0,0x16
    8000224e:	06e50513          	addi	a0,a0,110 # 800182b8 <wait_lock>
    80002252:	fffff097          	auipc	ra,0xfffff
    80002256:	a46080e7          	jalr	-1466(ra) # 80000c98 <release>
			return -1;
    8000225a:	59fd                	li	s3,-1
}
    8000225c:	854e                	mv	a0,s3
    8000225e:	60a6                	ld	ra,72(sp)
    80002260:	6406                	ld	s0,64(sp)
    80002262:	74e2                	ld	s1,56(sp)
    80002264:	7942                	ld	s2,48(sp)
    80002266:	79a2                	ld	s3,40(sp)
    80002268:	7a02                	ld	s4,32(sp)
    8000226a:	6ae2                	ld	s5,24(sp)
    8000226c:	6b42                	ld	s6,16(sp)
    8000226e:	6ba2                	ld	s7,8(sp)
    80002270:	6c02                	ld	s8,0(sp)
    80002272:	6161                	addi	sp,sp,80
    80002274:	8082                	ret
		sleep(p, &wait_lock);  //DOC: wait-sleep
    80002276:	85e2                	mv	a1,s8
    80002278:	854a                	mv	a0,s2
    8000227a:	00000097          	auipc	ra,0x0
    8000227e:	e7e080e7          	jalr	-386(ra) # 800020f8 <sleep>
		havekids = 0;
    80002282:	b715                	j	800021a6 <wait+0x4a>

0000000080002284 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    80002284:	7139                	addi	sp,sp,-64
    80002286:	fc06                	sd	ra,56(sp)
    80002288:	f822                	sd	s0,48(sp)
    8000228a:	f426                	sd	s1,40(sp)
    8000228c:	f04a                	sd	s2,32(sp)
    8000228e:	ec4e                	sd	s3,24(sp)
    80002290:	e852                	sd	s4,16(sp)
    80002292:	e456                	sd	s5,8(sp)
    80002294:	0080                	addi	s0,sp,64
    80002296:	8a2a                	mv	s4,a0
	struct proc *p;

	for(p = proc; p < &proc[NPROC]; p++) {
    80002298:	00016497          	auipc	s1,0x16
    8000229c:	43848493          	addi	s1,s1,1080 # 800186d0 <proc>
		if(p != myproc()){
			acquire(&p->lock);
			if(p->state == SLEEPING && p->chan == chan) {
    800022a0:	4989                	li	s3,2
				p->state = RUNNABLE;
    800022a2:	4a8d                	li	s5,3
	for(p = proc; p < &proc[NPROC]; p++) {
    800022a4:	0001c917          	auipc	s2,0x1c
    800022a8:	e2c90913          	addi	s2,s2,-468 # 8001e0d0 <tickslock>
    800022ac:	a821                	j	800022c4 <wakeup+0x40>
				p->state = RUNNABLE;
    800022ae:	0154ac23          	sw	s5,24(s1)
			}
			release(&p->lock);
    800022b2:	8526                	mv	a0,s1
    800022b4:	fffff097          	auipc	ra,0xfffff
    800022b8:	9e4080e7          	jalr	-1564(ra) # 80000c98 <release>
	for(p = proc; p < &proc[NPROC]; p++) {
    800022bc:	16848493          	addi	s1,s1,360
    800022c0:	03248463          	beq	s1,s2,800022e8 <wakeup+0x64>
		if(p != myproc()){
    800022c4:	fffff097          	auipc	ra,0xfffff
    800022c8:	778080e7          	jalr	1912(ra) # 80001a3c <myproc>
    800022cc:	fea488e3          	beq	s1,a0,800022bc <wakeup+0x38>
			acquire(&p->lock);
    800022d0:	8526                	mv	a0,s1
    800022d2:	fffff097          	auipc	ra,0xfffff
    800022d6:	912080e7          	jalr	-1774(ra) # 80000be4 <acquire>
			if(p->state == SLEEPING && p->chan == chan) {
    800022da:	4c9c                	lw	a5,24(s1)
    800022dc:	fd379be3          	bne	a5,s3,800022b2 <wakeup+0x2e>
    800022e0:	709c                	ld	a5,32(s1)
    800022e2:	fd4798e3          	bne	a5,s4,800022b2 <wakeup+0x2e>
    800022e6:	b7e1                	j	800022ae <wakeup+0x2a>
		}
	}
}
    800022e8:	70e2                	ld	ra,56(sp)
    800022ea:	7442                	ld	s0,48(sp)
    800022ec:	74a2                	ld	s1,40(sp)
    800022ee:	7902                	ld	s2,32(sp)
    800022f0:	69e2                	ld	s3,24(sp)
    800022f2:	6a42                	ld	s4,16(sp)
    800022f4:	6aa2                	ld	s5,8(sp)
    800022f6:	6121                	addi	sp,sp,64
    800022f8:	8082                	ret

00000000800022fa <reparent>:
{
    800022fa:	7179                	addi	sp,sp,-48
    800022fc:	f406                	sd	ra,40(sp)
    800022fe:	f022                	sd	s0,32(sp)
    80002300:	ec26                	sd	s1,24(sp)
    80002302:	e84a                	sd	s2,16(sp)
    80002304:	e44e                	sd	s3,8(sp)
    80002306:	e052                	sd	s4,0(sp)
    80002308:	1800                	addi	s0,sp,48
    8000230a:	892a                	mv	s2,a0
	for(pp = proc; pp < &proc[NPROC]; pp++){
    8000230c:	00016497          	auipc	s1,0x16
    80002310:	3c448493          	addi	s1,s1,964 # 800186d0 <proc>
			pp->parent = initproc;
    80002314:	0000ea17          	auipc	s4,0xe
    80002318:	d14a0a13          	addi	s4,s4,-748 # 80010028 <initproc>
	for(pp = proc; pp < &proc[NPROC]; pp++){
    8000231c:	0001c997          	auipc	s3,0x1c
    80002320:	db498993          	addi	s3,s3,-588 # 8001e0d0 <tickslock>
    80002324:	a029                	j	8000232e <reparent+0x34>
    80002326:	16848493          	addi	s1,s1,360
    8000232a:	01348d63          	beq	s1,s3,80002344 <reparent+0x4a>
		if(pp->parent == p){
    8000232e:	7c9c                	ld	a5,56(s1)
    80002330:	ff279be3          	bne	a5,s2,80002326 <reparent+0x2c>
			pp->parent = initproc;
    80002334:	000a3503          	ld	a0,0(s4)
    80002338:	fc88                	sd	a0,56(s1)
			wakeup(initproc);
    8000233a:	00000097          	auipc	ra,0x0
    8000233e:	f4a080e7          	jalr	-182(ra) # 80002284 <wakeup>
    80002342:	b7d5                	j	80002326 <reparent+0x2c>
}
    80002344:	70a2                	ld	ra,40(sp)
    80002346:	7402                	ld	s0,32(sp)
    80002348:	64e2                	ld	s1,24(sp)
    8000234a:	6942                	ld	s2,16(sp)
    8000234c:	69a2                	ld	s3,8(sp)
    8000234e:	6a02                	ld	s4,0(sp)
    80002350:	6145                	addi	sp,sp,48
    80002352:	8082                	ret

0000000080002354 <exit>:
{
    80002354:	7179                	addi	sp,sp,-48
    80002356:	f406                	sd	ra,40(sp)
    80002358:	f022                	sd	s0,32(sp)
    8000235a:	ec26                	sd	s1,24(sp)
    8000235c:	e84a                	sd	s2,16(sp)
    8000235e:	e44e                	sd	s3,8(sp)
    80002360:	e052                	sd	s4,0(sp)
    80002362:	1800                	addi	s0,sp,48
    80002364:	8a2a                	mv	s4,a0
	struct proc *p = myproc();
    80002366:	fffff097          	auipc	ra,0xfffff
    8000236a:	6d6080e7          	jalr	1750(ra) # 80001a3c <myproc>
    8000236e:	89aa                	mv	s3,a0
	if(p == initproc)
    80002370:	0000e797          	auipc	a5,0xe
    80002374:	cb87b783          	ld	a5,-840(a5) # 80010028 <initproc>
    80002378:	0d050493          	addi	s1,a0,208
    8000237c:	15050913          	addi	s2,a0,336
    80002380:	02a79363          	bne	a5,a0,800023a6 <exit+0x52>
		panic("init exiting");
    80002384:	00006517          	auipc	a0,0x6
    80002388:	ee450513          	addi	a0,a0,-284 # 80008268 <digits+0x228>
    8000238c:	ffffe097          	auipc	ra,0xffffe
    80002390:	1b2080e7          	jalr	434(ra) # 8000053e <panic>
			fileclose(f);
    80002394:	00002097          	auipc	ra,0x2
    80002398:	164080e7          	jalr	356(ra) # 800044f8 <fileclose>
			p->ofile[fd] = 0;
    8000239c:	0004b023          	sd	zero,0(s1)
	for(int fd = 0; fd < NOFILE; fd++){
    800023a0:	04a1                	addi	s1,s1,8
    800023a2:	01248563          	beq	s1,s2,800023ac <exit+0x58>
		if(p->ofile[fd]){
    800023a6:	6088                	ld	a0,0(s1)
    800023a8:	f575                	bnez	a0,80002394 <exit+0x40>
    800023aa:	bfdd                	j	800023a0 <exit+0x4c>
	begin_op();
    800023ac:	00002097          	auipc	ra,0x2
    800023b0:	c80080e7          	jalr	-896(ra) # 8000402c <begin_op>
	iput(p->cwd);
    800023b4:	1509b503          	ld	a0,336(s3)
    800023b8:	00001097          	auipc	ra,0x1
    800023bc:	45c080e7          	jalr	1116(ra) # 80003814 <iput>
	end_op();
    800023c0:	00002097          	auipc	ra,0x2
    800023c4:	cec080e7          	jalr	-788(ra) # 800040ac <end_op>
	p->cwd = 0;
    800023c8:	1409b823          	sd	zero,336(s3)
	acquire(&wait_lock);
    800023cc:	00016497          	auipc	s1,0x16
    800023d0:	eec48493          	addi	s1,s1,-276 # 800182b8 <wait_lock>
    800023d4:	8526                	mv	a0,s1
    800023d6:	fffff097          	auipc	ra,0xfffff
    800023da:	80e080e7          	jalr	-2034(ra) # 80000be4 <acquire>
	reparent(p);
    800023de:	854e                	mv	a0,s3
    800023e0:	00000097          	auipc	ra,0x0
    800023e4:	f1a080e7          	jalr	-230(ra) # 800022fa <reparent>
	wakeup(p->parent);
    800023e8:	0389b503          	ld	a0,56(s3)
    800023ec:	00000097          	auipc	ra,0x0
    800023f0:	e98080e7          	jalr	-360(ra) # 80002284 <wakeup>
	acquire(&p->lock);
    800023f4:	854e                	mv	a0,s3
    800023f6:	ffffe097          	auipc	ra,0xffffe
    800023fa:	7ee080e7          	jalr	2030(ra) # 80000be4 <acquire>
	p->xstate = status;
    800023fe:	0349a623          	sw	s4,44(s3)
	p->state = ZOMBIE;
    80002402:	4795                	li	a5,5
    80002404:	00f9ac23          	sw	a5,24(s3)
	release(&wait_lock);
    80002408:	8526                	mv	a0,s1
    8000240a:	fffff097          	auipc	ra,0xfffff
    8000240e:	88e080e7          	jalr	-1906(ra) # 80000c98 <release>
	sched();
    80002412:	00000097          	auipc	ra,0x0
    80002416:	bd4080e7          	jalr	-1068(ra) # 80001fe6 <sched>
	panic("zombie exit");
    8000241a:	00006517          	auipc	a0,0x6
    8000241e:	e5e50513          	addi	a0,a0,-418 # 80008278 <digits+0x238>
    80002422:	ffffe097          	auipc	ra,0xffffe
    80002426:	11c080e7          	jalr	284(ra) # 8000053e <panic>

000000008000242a <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    8000242a:	7179                	addi	sp,sp,-48
    8000242c:	f406                	sd	ra,40(sp)
    8000242e:	f022                	sd	s0,32(sp)
    80002430:	ec26                	sd	s1,24(sp)
    80002432:	e84a                	sd	s2,16(sp)
    80002434:	e44e                	sd	s3,8(sp)
    80002436:	1800                	addi	s0,sp,48
    80002438:	892a                	mv	s2,a0
	struct proc *p;

	for(p = proc; p < &proc[NPROC]; p++){
    8000243a:	00016497          	auipc	s1,0x16
    8000243e:	29648493          	addi	s1,s1,662 # 800186d0 <proc>
    80002442:	0001c997          	auipc	s3,0x1c
    80002446:	c8e98993          	addi	s3,s3,-882 # 8001e0d0 <tickslock>
		acquire(&p->lock);
    8000244a:	8526                	mv	a0,s1
    8000244c:	ffffe097          	auipc	ra,0xffffe
    80002450:	798080e7          	jalr	1944(ra) # 80000be4 <acquire>
		if(p->pid == pid){
    80002454:	589c                	lw	a5,48(s1)
    80002456:	01278d63          	beq	a5,s2,80002470 <kill+0x46>
				p->state = RUNNABLE;
			}
			release(&p->lock);
			return 0;
		}
		release(&p->lock);
    8000245a:	8526                	mv	a0,s1
    8000245c:	fffff097          	auipc	ra,0xfffff
    80002460:	83c080e7          	jalr	-1988(ra) # 80000c98 <release>
	for(p = proc; p < &proc[NPROC]; p++){
    80002464:	16848493          	addi	s1,s1,360
    80002468:	ff3491e3          	bne	s1,s3,8000244a <kill+0x20>
	}
	return -1;
    8000246c:	557d                	li	a0,-1
    8000246e:	a829                	j	80002488 <kill+0x5e>
			p->killed = 1;
    80002470:	4785                	li	a5,1
    80002472:	d49c                	sw	a5,40(s1)
			if(p->state == SLEEPING){
    80002474:	4c98                	lw	a4,24(s1)
    80002476:	4789                	li	a5,2
    80002478:	00f70f63          	beq	a4,a5,80002496 <kill+0x6c>
			release(&p->lock);
    8000247c:	8526                	mv	a0,s1
    8000247e:	fffff097          	auipc	ra,0xfffff
    80002482:	81a080e7          	jalr	-2022(ra) # 80000c98 <release>
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
    80002496:	478d                	li	a5,3
    80002498:	cc9c                	sw	a5,24(s1)
    8000249a:	b7cd                	j	8000247c <kill+0x52>

000000008000249c <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    8000249c:	7179                	addi	sp,sp,-48
    8000249e:	f406                	sd	ra,40(sp)
    800024a0:	f022                	sd	s0,32(sp)
    800024a2:	ec26                	sd	s1,24(sp)
    800024a4:	e84a                	sd	s2,16(sp)
    800024a6:	e44e                	sd	s3,8(sp)
    800024a8:	e052                	sd	s4,0(sp)
    800024aa:	1800                	addi	s0,sp,48
    800024ac:	84aa                	mv	s1,a0
    800024ae:	892e                	mv	s2,a1
    800024b0:	89b2                	mv	s3,a2
    800024b2:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800024b4:	fffff097          	auipc	ra,0xfffff
    800024b8:	588080e7          	jalr	1416(ra) # 80001a3c <myproc>
  if(user_dst){
    800024bc:	c08d                	beqz	s1,800024de <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    800024be:	86d2                	mv	a3,s4
    800024c0:	864e                	mv	a2,s3
    800024c2:	85ca                	mv	a1,s2
    800024c4:	6928                	ld	a0,80(a0)
    800024c6:	fffff097          	auipc	ra,0xfffff
    800024ca:	1bc080e7          	jalr	444(ra) # 80001682 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    800024ce:	70a2                	ld	ra,40(sp)
    800024d0:	7402                	ld	s0,32(sp)
    800024d2:	64e2                	ld	s1,24(sp)
    800024d4:	6942                	ld	s2,16(sp)
    800024d6:	69a2                	ld	s3,8(sp)
    800024d8:	6a02                	ld	s4,0(sp)
    800024da:	6145                	addi	sp,sp,48
    800024dc:	8082                	ret
    memmove((char *)dst, src, len);
    800024de:	000a061b          	sext.w	a2,s4
    800024e2:	85ce                	mv	a1,s3
    800024e4:	854a                	mv	a0,s2
    800024e6:	fffff097          	auipc	ra,0xfffff
    800024ea:	85a080e7          	jalr	-1958(ra) # 80000d40 <memmove>
    return 0;
    800024ee:	8526                	mv	a0,s1
    800024f0:	bff9                	j	800024ce <either_copyout+0x32>

00000000800024f2 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800024f2:	7179                	addi	sp,sp,-48
    800024f4:	f406                	sd	ra,40(sp)
    800024f6:	f022                	sd	s0,32(sp)
    800024f8:	ec26                	sd	s1,24(sp)
    800024fa:	e84a                	sd	s2,16(sp)
    800024fc:	e44e                	sd	s3,8(sp)
    800024fe:	e052                	sd	s4,0(sp)
    80002500:	1800                	addi	s0,sp,48
    80002502:	892a                	mv	s2,a0
    80002504:	84ae                	mv	s1,a1
    80002506:	89b2                	mv	s3,a2
    80002508:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000250a:	fffff097          	auipc	ra,0xfffff
    8000250e:	532080e7          	jalr	1330(ra) # 80001a3c <myproc>
  if(user_src){
    80002512:	c08d                	beqz	s1,80002534 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    80002514:	86d2                	mv	a3,s4
    80002516:	864e                	mv	a2,s3
    80002518:	85ca                	mv	a1,s2
    8000251a:	6928                	ld	a0,80(a0)
    8000251c:	fffff097          	auipc	ra,0xfffff
    80002520:	1f2080e7          	jalr	498(ra) # 8000170e <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80002524:	70a2                	ld	ra,40(sp)
    80002526:	7402                	ld	s0,32(sp)
    80002528:	64e2                	ld	s1,24(sp)
    8000252a:	6942                	ld	s2,16(sp)
    8000252c:	69a2                	ld	s3,8(sp)
    8000252e:	6a02                	ld	s4,0(sp)
    80002530:	6145                	addi	sp,sp,48
    80002532:	8082                	ret
    memmove(dst, (char*)src, len);
    80002534:	000a061b          	sext.w	a2,s4
    80002538:	85ce                	mv	a1,s3
    8000253a:	854a                	mv	a0,s2
    8000253c:	fffff097          	auipc	ra,0xfffff
    80002540:	804080e7          	jalr	-2044(ra) # 80000d40 <memmove>
    return 0;
    80002544:	8526                	mv	a0,s1
    80002546:	bff9                	j	80002524 <either_copyin+0x32>

0000000080002548 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    80002548:	715d                	addi	sp,sp,-80
    8000254a:	e486                	sd	ra,72(sp)
    8000254c:	e0a2                	sd	s0,64(sp)
    8000254e:	fc26                	sd	s1,56(sp)
    80002550:	f84a                	sd	s2,48(sp)
    80002552:	f44e                	sd	s3,40(sp)
    80002554:	f052                	sd	s4,32(sp)
    80002556:	ec56                	sd	s5,24(sp)
    80002558:	e85a                	sd	s6,16(sp)
    8000255a:	e45e                	sd	s7,8(sp)
    8000255c:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    8000255e:	00006517          	auipc	a0,0x6
    80002562:	b6a50513          	addi	a0,a0,-1174 # 800080c8 <digits+0x88>
    80002566:	ffffe097          	auipc	ra,0xffffe
    8000256a:	022080e7          	jalr	34(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    8000256e:	00016497          	auipc	s1,0x16
    80002572:	2ba48493          	addi	s1,s1,698 # 80018828 <proc+0x158>
    80002576:	0001c917          	auipc	s2,0x1c
    8000257a:	cb290913          	addi	s2,s2,-846 # 8001e228 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000257e:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    80002580:	00006997          	auipc	s3,0x6
    80002584:	d0898993          	addi	s3,s3,-760 # 80008288 <digits+0x248>
    printf("%d %s %s", p->pid, state, p->name);
    80002588:	00006a97          	auipc	s5,0x6
    8000258c:	d08a8a93          	addi	s5,s5,-760 # 80008290 <digits+0x250>
    printf("\n");
    80002590:	00006a17          	auipc	s4,0x6
    80002594:	b38a0a13          	addi	s4,s4,-1224 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002598:	00006b97          	auipc	s7,0x6
    8000259c:	d30b8b93          	addi	s7,s7,-720 # 800082c8 <states.1713>
    800025a0:	a00d                	j	800025c2 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    800025a2:	ed86a583          	lw	a1,-296(a3)
    800025a6:	8556                	mv	a0,s5
    800025a8:	ffffe097          	auipc	ra,0xffffe
    800025ac:	fe0080e7          	jalr	-32(ra) # 80000588 <printf>
    printf("\n");
    800025b0:	8552                	mv	a0,s4
    800025b2:	ffffe097          	auipc	ra,0xffffe
    800025b6:	fd6080e7          	jalr	-42(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800025ba:	16848493          	addi	s1,s1,360
    800025be:	03248163          	beq	s1,s2,800025e0 <procdump+0x98>
    if(p->state == UNUSED)
    800025c2:	86a6                	mv	a3,s1
    800025c4:	ec04a783          	lw	a5,-320(s1)
    800025c8:	dbed                	beqz	a5,800025ba <procdump+0x72>
      state = "???";
    800025ca:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800025cc:	fcfb6be3          	bltu	s6,a5,800025a2 <procdump+0x5a>
    800025d0:	1782                	slli	a5,a5,0x20
    800025d2:	9381                	srli	a5,a5,0x20
    800025d4:	078e                	slli	a5,a5,0x3
    800025d6:	97de                	add	a5,a5,s7
    800025d8:	6390                	ld	a2,0(a5)
    800025da:	f661                	bnez	a2,800025a2 <procdump+0x5a>
      state = "???";
    800025dc:	864e                	mv	a2,s3
    800025de:	b7d1                	j	800025a2 <procdump+0x5a>
  }
}
    800025e0:	60a6                	ld	ra,72(sp)
    800025e2:	6406                	ld	s0,64(sp)
    800025e4:	74e2                	ld	s1,56(sp)
    800025e6:	7942                	ld	s2,48(sp)
    800025e8:	79a2                	ld	s3,40(sp)
    800025ea:	7a02                	ld	s4,32(sp)
    800025ec:	6ae2                	ld	s5,24(sp)
    800025ee:	6b42                	ld	s6,16(sp)
    800025f0:	6ba2                	ld	s7,8(sp)
    800025f2:	6161                	addi	sp,sp,80
    800025f4:	8082                	ret

00000000800025f6 <swtch>:
    800025f6:	00153023          	sd	ra,0(a0)
    800025fa:	00253423          	sd	sp,8(a0)
    800025fe:	e900                	sd	s0,16(a0)
    80002600:	ed04                	sd	s1,24(a0)
    80002602:	03253023          	sd	s2,32(a0)
    80002606:	03353423          	sd	s3,40(a0)
    8000260a:	03453823          	sd	s4,48(a0)
    8000260e:	03553c23          	sd	s5,56(a0)
    80002612:	05653023          	sd	s6,64(a0)
    80002616:	05753423          	sd	s7,72(a0)
    8000261a:	05853823          	sd	s8,80(a0)
    8000261e:	05953c23          	sd	s9,88(a0)
    80002622:	07a53023          	sd	s10,96(a0)
    80002626:	07b53423          	sd	s11,104(a0)
    8000262a:	0005b083          	ld	ra,0(a1)
    8000262e:	0085b103          	ld	sp,8(a1)
    80002632:	6980                	ld	s0,16(a1)
    80002634:	6d84                	ld	s1,24(a1)
    80002636:	0205b903          	ld	s2,32(a1)
    8000263a:	0285b983          	ld	s3,40(a1)
    8000263e:	0305ba03          	ld	s4,48(a1)
    80002642:	0385ba83          	ld	s5,56(a1)
    80002646:	0405bb03          	ld	s6,64(a1)
    8000264a:	0485bb83          	ld	s7,72(a1)
    8000264e:	0505bc03          	ld	s8,80(a1)
    80002652:	0585bc83          	ld	s9,88(a1)
    80002656:	0605bd03          	ld	s10,96(a1)
    8000265a:	0685bd83          	ld	s11,104(a1)
    8000265e:	8082                	ret

0000000080002660 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002660:	1141                	addi	sp,sp,-16
    80002662:	e406                	sd	ra,8(sp)
    80002664:	e022                	sd	s0,0(sp)
    80002666:	0800                	addi	s0,sp,16
	initlock(&tickslock, "time");
    80002668:	00006597          	auipc	a1,0x6
    8000266c:	c9058593          	addi	a1,a1,-880 # 800082f8 <states.1713+0x30>
    80002670:	0001c517          	auipc	a0,0x1c
    80002674:	a6050513          	addi	a0,a0,-1440 # 8001e0d0 <tickslock>
    80002678:	ffffe097          	auipc	ra,0xffffe
    8000267c:	4dc080e7          	jalr	1244(ra) # 80000b54 <initlock>
}
    80002680:	60a2                	ld	ra,8(sp)
    80002682:	6402                	ld	s0,0(sp)
    80002684:	0141                	addi	sp,sp,16
    80002686:	8082                	ret

0000000080002688 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002688:	1141                	addi	sp,sp,-16
    8000268a:	e422                	sd	s0,8(sp)
    8000268c:	0800                	addi	s0,sp,16
	asm volatile("csrw stvec, %0" : : "r" (x));
    8000268e:	00003797          	auipc	a5,0x3
    80002692:	48278793          	addi	a5,a5,1154 # 80005b10 <kernelvec>
    80002696:	10579073          	csrw	stvec,a5
	w_stvec((uint64)kernelvec);
}
    8000269a:	6422                	ld	s0,8(sp)
    8000269c:	0141                	addi	sp,sp,16
    8000269e:	8082                	ret

00000000800026a0 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    800026a0:	1141                	addi	sp,sp,-16
    800026a2:	e406                	sd	ra,8(sp)
    800026a4:	e022                	sd	s0,0(sp)
    800026a6:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    800026a8:	fffff097          	auipc	ra,0xfffff
    800026ac:	394080e7          	jalr	916(ra) # 80001a3c <myproc>
	asm volatile("csrr %0, sstatus" : "=r" (x) );
    800026b0:	100027f3          	csrr	a5,sstatus
	w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    800026b4:	9bf5                	andi	a5,a5,-3
	asm volatile("csrw sstatus, %0" : : "r" (x));
    800026b6:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    800026ba:	00005617          	auipc	a2,0x5
    800026be:	94660613          	addi	a2,a2,-1722 # 80007000 <_trampoline>
    800026c2:	00005697          	auipc	a3,0x5
    800026c6:	93e68693          	addi	a3,a3,-1730 # 80007000 <_trampoline>
    800026ca:	8e91                	sub	a3,a3,a2
    800026cc:	008007b7          	lui	a5,0x800
    800026d0:	17fd                	addi	a5,a5,-1
    800026d2:	07be                	slli	a5,a5,0xf
    800026d4:	96be                	add	a3,a3,a5
	asm volatile("csrw stvec, %0" : : "r" (x));
    800026d6:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    800026da:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    800026dc:	180026f3          	csrr	a3,satp
    800026e0:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    800026e2:	6d38                	ld	a4,88(a0)
    800026e4:	6134                	ld	a3,64(a0)
    800026e6:	65a1                	lui	a1,0x8
    800026e8:	96ae                	add	a3,a3,a1
    800026ea:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    800026ec:	6d38                	ld	a4,88(a0)
    800026ee:	00000697          	auipc	a3,0x0
    800026f2:	13868693          	addi	a3,a3,312 # 80002826 <usertrap>
    800026f6:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    800026f8:	6d38                	ld	a4,88(a0)
	asm volatile("mv %0, tp" : "=r" (x) );
    800026fa:	8692                	mv	a3,tp
    800026fc:	f314                	sd	a3,32(a4)
	asm volatile("csrr %0, sstatus" : "=r" (x) );
    800026fe:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002702:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002706:	0206e693          	ori	a3,a3,32
	asm volatile("csrw sstatus, %0" : : "r" (x));
    8000270a:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    8000270e:	6d38                	ld	a4,88(a0)
	asm volatile("csrw sepc, %0" : : "r" (x));
    80002710:	6f18                	ld	a4,24(a4)
    80002712:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002716:	692c                	ld	a1,80(a0)
    80002718:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    8000271a:	00005717          	auipc	a4,0x5
    8000271e:	97670713          	addi	a4,a4,-1674 # 80007090 <userret>
    80002722:	8f11                	sub	a4,a4,a2
    80002724:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80002726:	577d                	li	a4,-1
    80002728:	177e                	slli	a4,a4,0x3f
    8000272a:	8dd9                	or	a1,a1,a4
    8000272c:	00400537          	lui	a0,0x400
    80002730:	157d                	addi	a0,a0,-1
    80002732:	0542                	slli	a0,a0,0x10
    80002734:	9782                	jalr	a5
}
    80002736:	60a2                	ld	ra,8(sp)
    80002738:	6402                	ld	s0,0(sp)
    8000273a:	0141                	addi	sp,sp,16
    8000273c:	8082                	ret

000000008000273e <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    8000273e:	1101                	addi	sp,sp,-32
    80002740:	ec06                	sd	ra,24(sp)
    80002742:	e822                	sd	s0,16(sp)
    80002744:	e426                	sd	s1,8(sp)
    80002746:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002748:	0001c497          	auipc	s1,0x1c
    8000274c:	98848493          	addi	s1,s1,-1656 # 8001e0d0 <tickslock>
    80002750:	8526                	mv	a0,s1
    80002752:	ffffe097          	auipc	ra,0xffffe
    80002756:	492080e7          	jalr	1170(ra) # 80000be4 <acquire>
  ticks++;
    8000275a:	0000e517          	auipc	a0,0xe
    8000275e:	8d650513          	addi	a0,a0,-1834 # 80010030 <ticks>
    80002762:	411c                	lw	a5,0(a0)
    80002764:	2785                	addiw	a5,a5,1
    80002766:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002768:	00000097          	auipc	ra,0x0
    8000276c:	b1c080e7          	jalr	-1252(ra) # 80002284 <wakeup>
  release(&tickslock);
    80002770:	8526                	mv	a0,s1
    80002772:	ffffe097          	auipc	ra,0xffffe
    80002776:	526080e7          	jalr	1318(ra) # 80000c98 <release>
}
    8000277a:	60e2                	ld	ra,24(sp)
    8000277c:	6442                	ld	s0,16(sp)
    8000277e:	64a2                	ld	s1,8(sp)
    80002780:	6105                	addi	sp,sp,32
    80002782:	8082                	ret

0000000080002784 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002784:	1101                	addi	sp,sp,-32
    80002786:	ec06                	sd	ra,24(sp)
    80002788:	e822                	sd	s0,16(sp)
    8000278a:	e426                	sd	s1,8(sp)
    8000278c:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000278e:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002792:	00074d63          	bltz	a4,800027ac <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002796:	57fd                	li	a5,-1
    80002798:	17fe                	slli	a5,a5,0x3f
    8000279a:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    8000279c:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    8000279e:	06f70363          	beq	a4,a5,80002804 <devintr+0x80>
  }
}
    800027a2:	60e2                	ld	ra,24(sp)
    800027a4:	6442                	ld	s0,16(sp)
    800027a6:	64a2                	ld	s1,8(sp)
    800027a8:	6105                	addi	sp,sp,32
    800027aa:	8082                	ret
     (scause & 0xff) == 9){
    800027ac:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    800027b0:	46a5                	li	a3,9
    800027b2:	fed792e3          	bne	a5,a3,80002796 <devintr+0x12>
    int irq = plic_claim();
    800027b6:	00003097          	auipc	ra,0x3
    800027ba:	462080e7          	jalr	1122(ra) # 80005c18 <plic_claim>
    800027be:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    800027c0:	47a9                	li	a5,10
    800027c2:	02f50763          	beq	a0,a5,800027f0 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    800027c6:	4785                	li	a5,1
    800027c8:	02f50963          	beq	a0,a5,800027fa <devintr+0x76>
    return 1;
    800027cc:	4505                	li	a0,1
    } else if(irq){
    800027ce:	d8f1                	beqz	s1,800027a2 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    800027d0:	85a6                	mv	a1,s1
    800027d2:	00006517          	auipc	a0,0x6
    800027d6:	b2e50513          	addi	a0,a0,-1234 # 80008300 <states.1713+0x38>
    800027da:	ffffe097          	auipc	ra,0xffffe
    800027de:	dae080e7          	jalr	-594(ra) # 80000588 <printf>
      plic_complete(irq);
    800027e2:	8526                	mv	a0,s1
    800027e4:	00003097          	auipc	ra,0x3
    800027e8:	458080e7          	jalr	1112(ra) # 80005c3c <plic_complete>
    return 1;
    800027ec:	4505                	li	a0,1
    800027ee:	bf55                	j	800027a2 <devintr+0x1e>
      uartintr();
    800027f0:	ffffe097          	auipc	ra,0xffffe
    800027f4:	1b8080e7          	jalr	440(ra) # 800009a8 <uartintr>
    800027f8:	b7ed                	j	800027e2 <devintr+0x5e>
      virtio_disk_intr();
    800027fa:	00004097          	auipc	ra,0x4
    800027fe:	918080e7          	jalr	-1768(ra) # 80006112 <virtio_disk_intr>
    80002802:	b7c5                	j	800027e2 <devintr+0x5e>
    if(cpuid() == 0){
    80002804:	fffff097          	auipc	ra,0xfffff
    80002808:	20c080e7          	jalr	524(ra) # 80001a10 <cpuid>
    8000280c:	c901                	beqz	a0,8000281c <devintr+0x98>
	asm volatile("csrr %0, sip" : "=r" (x) );
    8000280e:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002812:	9bf5                	andi	a5,a5,-3
	asm volatile("csrw sip, %0" : : "r" (x));
    80002814:	14479073          	csrw	sip,a5
    return 2;
    80002818:	4509                	li	a0,2
    8000281a:	b761                	j	800027a2 <devintr+0x1e>
      clockintr();
    8000281c:	00000097          	auipc	ra,0x0
    80002820:	f22080e7          	jalr	-222(ra) # 8000273e <clockintr>
    80002824:	b7ed                	j	8000280e <devintr+0x8a>

0000000080002826 <usertrap>:
{
    80002826:	1101                	addi	sp,sp,-32
    80002828:	ec06                	sd	ra,24(sp)
    8000282a:	e822                	sd	s0,16(sp)
    8000282c:	e426                	sd	s1,8(sp)
    8000282e:	e04a                	sd	s2,0(sp)
    80002830:	1000                	addi	s0,sp,32
	asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002832:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002836:	1007f793          	andi	a5,a5,256
    8000283a:	e3ad                	bnez	a5,8000289c <usertrap+0x76>
	asm volatile("csrw stvec, %0" : : "r" (x));
    8000283c:	00003797          	auipc	a5,0x3
    80002840:	2d478793          	addi	a5,a5,724 # 80005b10 <kernelvec>
    80002844:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002848:	fffff097          	auipc	ra,0xfffff
    8000284c:	1f4080e7          	jalr	500(ra) # 80001a3c <myproc>
    80002850:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002852:	6d3c                	ld	a5,88(a0)
	asm volatile("csrr %0, sepc" : "=r" (x) );
    80002854:	14102773          	csrr	a4,sepc
    80002858:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000285a:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    8000285e:	47a1                	li	a5,8
    80002860:	04f71c63          	bne	a4,a5,800028b8 <usertrap+0x92>
    if(p->killed)
    80002864:	551c                	lw	a5,40(a0)
    80002866:	e3b9                	bnez	a5,800028ac <usertrap+0x86>
    p->trapframe->epc += 4;
    80002868:	6cb8                	ld	a4,88(s1)
    8000286a:	6f1c                	ld	a5,24(a4)
    8000286c:	0791                	addi	a5,a5,4
    8000286e:	ef1c                	sd	a5,24(a4)
	asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002870:	100027f3          	csrr	a5,sstatus
	w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002874:	0027e793          	ori	a5,a5,2
	asm volatile("csrw sstatus, %0" : : "r" (x));
    80002878:	10079073          	csrw	sstatus,a5
    syscall();
    8000287c:	00000097          	auipc	ra,0x0
    80002880:	2e0080e7          	jalr	736(ra) # 80002b5c <syscall>
  if(p->killed)
    80002884:	549c                	lw	a5,40(s1)
    80002886:	ebc1                	bnez	a5,80002916 <usertrap+0xf0>
  usertrapret();
    80002888:	00000097          	auipc	ra,0x0
    8000288c:	e18080e7          	jalr	-488(ra) # 800026a0 <usertrapret>
}
    80002890:	60e2                	ld	ra,24(sp)
    80002892:	6442                	ld	s0,16(sp)
    80002894:	64a2                	ld	s1,8(sp)
    80002896:	6902                	ld	s2,0(sp)
    80002898:	6105                	addi	sp,sp,32
    8000289a:	8082                	ret
    panic("usertrap: not from user mode");
    8000289c:	00006517          	auipc	a0,0x6
    800028a0:	a8450513          	addi	a0,a0,-1404 # 80008320 <states.1713+0x58>
    800028a4:	ffffe097          	auipc	ra,0xffffe
    800028a8:	c9a080e7          	jalr	-870(ra) # 8000053e <panic>
      exit(-1);
    800028ac:	557d                	li	a0,-1
    800028ae:	00000097          	auipc	ra,0x0
    800028b2:	aa6080e7          	jalr	-1370(ra) # 80002354 <exit>
    800028b6:	bf4d                	j	80002868 <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    800028b8:	00000097          	auipc	ra,0x0
    800028bc:	ecc080e7          	jalr	-308(ra) # 80002784 <devintr>
    800028c0:	892a                	mv	s2,a0
    800028c2:	c501                	beqz	a0,800028ca <usertrap+0xa4>
  if(p->killed)
    800028c4:	549c                	lw	a5,40(s1)
    800028c6:	c3a1                	beqz	a5,80002906 <usertrap+0xe0>
    800028c8:	a815                	j	800028fc <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    800028ca:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    800028ce:	5890                	lw	a2,48(s1)
    800028d0:	00006517          	auipc	a0,0x6
    800028d4:	a7050513          	addi	a0,a0,-1424 # 80008340 <states.1713+0x78>
    800028d8:	ffffe097          	auipc	ra,0xffffe
    800028dc:	cb0080e7          	jalr	-848(ra) # 80000588 <printf>
	asm volatile("csrr %0, sepc" : "=r" (x) );
    800028e0:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    800028e4:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    800028e8:	00006517          	auipc	a0,0x6
    800028ec:	a8850513          	addi	a0,a0,-1400 # 80008370 <states.1713+0xa8>
    800028f0:	ffffe097          	auipc	ra,0xffffe
    800028f4:	c98080e7          	jalr	-872(ra) # 80000588 <printf>
    p->killed = 1;
    800028f8:	4785                	li	a5,1
    800028fa:	d49c                	sw	a5,40(s1)
    exit(-1);
    800028fc:	557d                	li	a0,-1
    800028fe:	00000097          	auipc	ra,0x0
    80002902:	a56080e7          	jalr	-1450(ra) # 80002354 <exit>
  if(which_dev == 2)
    80002906:	4789                	li	a5,2
    80002908:	f8f910e3          	bne	s2,a5,80002888 <usertrap+0x62>
    yield();
    8000290c:	fffff097          	auipc	ra,0xfffff
    80002910:	7b0080e7          	jalr	1968(ra) # 800020bc <yield>
    80002914:	bf95                	j	80002888 <usertrap+0x62>
  int which_dev = 0;
    80002916:	4901                	li	s2,0
    80002918:	b7d5                	j	800028fc <usertrap+0xd6>

000000008000291a <kerneltrap>:
{
    8000291a:	7179                	addi	sp,sp,-48
    8000291c:	f406                	sd	ra,40(sp)
    8000291e:	f022                	sd	s0,32(sp)
    80002920:	ec26                	sd	s1,24(sp)
    80002922:	e84a                	sd	s2,16(sp)
    80002924:	e44e                	sd	s3,8(sp)
    80002926:	1800                	addi	s0,sp,48
	asm volatile("csrr %0, sepc" : "=r" (x) );
    80002928:	14102973          	csrr	s2,sepc
	asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000292c:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002930:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002934:	1004f793          	andi	a5,s1,256
    80002938:	cb85                	beqz	a5,80002968 <kerneltrap+0x4e>
	asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000293a:	100027f3          	csrr	a5,sstatus
	return (x & SSTATUS_SIE) != 0;
    8000293e:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002940:	ef85                	bnez	a5,80002978 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002942:	00000097          	auipc	ra,0x0
    80002946:	e42080e7          	jalr	-446(ra) # 80002784 <devintr>
    8000294a:	cd1d                	beqz	a0,80002988 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    8000294c:	4789                	li	a5,2
    8000294e:	06f50a63          	beq	a0,a5,800029c2 <kerneltrap+0xa8>
	asm volatile("csrw sepc, %0" : : "r" (x));
    80002952:	14191073          	csrw	sepc,s2
	asm volatile("csrw sstatus, %0" : : "r" (x));
    80002956:	10049073          	csrw	sstatus,s1
}
    8000295a:	70a2                	ld	ra,40(sp)
    8000295c:	7402                	ld	s0,32(sp)
    8000295e:	64e2                	ld	s1,24(sp)
    80002960:	6942                	ld	s2,16(sp)
    80002962:	69a2                	ld	s3,8(sp)
    80002964:	6145                	addi	sp,sp,48
    80002966:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002968:	00006517          	auipc	a0,0x6
    8000296c:	a2850513          	addi	a0,a0,-1496 # 80008390 <states.1713+0xc8>
    80002970:	ffffe097          	auipc	ra,0xffffe
    80002974:	bce080e7          	jalr	-1074(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    80002978:	00006517          	auipc	a0,0x6
    8000297c:	a4050513          	addi	a0,a0,-1472 # 800083b8 <states.1713+0xf0>
    80002980:	ffffe097          	auipc	ra,0xffffe
    80002984:	bbe080e7          	jalr	-1090(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    80002988:	85ce                	mv	a1,s3
    8000298a:	00006517          	auipc	a0,0x6
    8000298e:	a4e50513          	addi	a0,a0,-1458 # 800083d8 <states.1713+0x110>
    80002992:	ffffe097          	auipc	ra,0xffffe
    80002996:	bf6080e7          	jalr	-1034(ra) # 80000588 <printf>
	asm volatile("csrr %0, sepc" : "=r" (x) );
    8000299a:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    8000299e:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    800029a2:	00006517          	auipc	a0,0x6
    800029a6:	a4650513          	addi	a0,a0,-1466 # 800083e8 <states.1713+0x120>
    800029aa:	ffffe097          	auipc	ra,0xffffe
    800029ae:	bde080e7          	jalr	-1058(ra) # 80000588 <printf>
    panic("kerneltrap");
    800029b2:	00006517          	auipc	a0,0x6
    800029b6:	a4e50513          	addi	a0,a0,-1458 # 80008400 <states.1713+0x138>
    800029ba:	ffffe097          	auipc	ra,0xffffe
    800029be:	b84080e7          	jalr	-1148(ra) # 8000053e <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    800029c2:	fffff097          	auipc	ra,0xfffff
    800029c6:	07a080e7          	jalr	122(ra) # 80001a3c <myproc>
    800029ca:	d541                	beqz	a0,80002952 <kerneltrap+0x38>
    800029cc:	fffff097          	auipc	ra,0xfffff
    800029d0:	070080e7          	jalr	112(ra) # 80001a3c <myproc>
    800029d4:	4d18                	lw	a4,24(a0)
    800029d6:	4791                	li	a5,4
    800029d8:	f6f71de3          	bne	a4,a5,80002952 <kerneltrap+0x38>
    yield();
    800029dc:	fffff097          	auipc	ra,0xfffff
    800029e0:	6e0080e7          	jalr	1760(ra) # 800020bc <yield>
    800029e4:	b7bd                	j	80002952 <kerneltrap+0x38>

00000000800029e6 <argraw>:
	return strlen(buf);
}

static uint64
argraw(int n)
{
    800029e6:	1101                	addi	sp,sp,-32
    800029e8:	ec06                	sd	ra,24(sp)
    800029ea:	e822                	sd	s0,16(sp)
    800029ec:	e426                	sd	s1,8(sp)
    800029ee:	1000                	addi	s0,sp,32
    800029f0:	84aa                	mv	s1,a0
	struct proc *p = myproc();
    800029f2:	fffff097          	auipc	ra,0xfffff
    800029f6:	04a080e7          	jalr	74(ra) # 80001a3c <myproc>
	switch (n) {
    800029fa:	4795                	li	a5,5
    800029fc:	0497e163          	bltu	a5,s1,80002a3e <argraw+0x58>
    80002a00:	048a                	slli	s1,s1,0x2
    80002a02:	00006717          	auipc	a4,0x6
    80002a06:	a3670713          	addi	a4,a4,-1482 # 80008438 <states.1713+0x170>
    80002a0a:	94ba                	add	s1,s1,a4
    80002a0c:	409c                	lw	a5,0(s1)
    80002a0e:	97ba                	add	a5,a5,a4
    80002a10:	8782                	jr	a5
	case 0:
		return p->trapframe->a0;
    80002a12:	6d3c                	ld	a5,88(a0)
    80002a14:	7ba8                	ld	a0,112(a5)
	case 5:
		return p->trapframe->a5;
	}
	panic("argraw");
	return -1;
}
    80002a16:	60e2                	ld	ra,24(sp)
    80002a18:	6442                	ld	s0,16(sp)
    80002a1a:	64a2                	ld	s1,8(sp)
    80002a1c:	6105                	addi	sp,sp,32
    80002a1e:	8082                	ret
		return p->trapframe->a1;
    80002a20:	6d3c                	ld	a5,88(a0)
    80002a22:	7fa8                	ld	a0,120(a5)
    80002a24:	bfcd                	j	80002a16 <argraw+0x30>
		return p->trapframe->a2;
    80002a26:	6d3c                	ld	a5,88(a0)
    80002a28:	63c8                	ld	a0,128(a5)
    80002a2a:	b7f5                	j	80002a16 <argraw+0x30>
		return p->trapframe->a3;
    80002a2c:	6d3c                	ld	a5,88(a0)
    80002a2e:	67c8                	ld	a0,136(a5)
    80002a30:	b7dd                	j	80002a16 <argraw+0x30>
		return p->trapframe->a4;
    80002a32:	6d3c                	ld	a5,88(a0)
    80002a34:	6bc8                	ld	a0,144(a5)
    80002a36:	b7c5                	j	80002a16 <argraw+0x30>
		return p->trapframe->a5;
    80002a38:	6d3c                	ld	a5,88(a0)
    80002a3a:	6fc8                	ld	a0,152(a5)
    80002a3c:	bfe9                	j	80002a16 <argraw+0x30>
	panic("argraw");
    80002a3e:	00006517          	auipc	a0,0x6
    80002a42:	9d250513          	addi	a0,a0,-1582 # 80008410 <states.1713+0x148>
    80002a46:	ffffe097          	auipc	ra,0xffffe
    80002a4a:	af8080e7          	jalr	-1288(ra) # 8000053e <panic>

0000000080002a4e <fetchaddr>:
{
    80002a4e:	1101                	addi	sp,sp,-32
    80002a50:	ec06                	sd	ra,24(sp)
    80002a52:	e822                	sd	s0,16(sp)
    80002a54:	e426                	sd	s1,8(sp)
    80002a56:	e04a                	sd	s2,0(sp)
    80002a58:	1000                	addi	s0,sp,32
    80002a5a:	84aa                	mv	s1,a0
    80002a5c:	892e                	mv	s2,a1
	struct proc *p = myproc();
    80002a5e:	fffff097          	auipc	ra,0xfffff
    80002a62:	fde080e7          	jalr	-34(ra) # 80001a3c <myproc>
	if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002a66:	653c                	ld	a5,72(a0)
    80002a68:	02f4f863          	bgeu	s1,a5,80002a98 <fetchaddr+0x4a>
    80002a6c:	00848713          	addi	a4,s1,8
    80002a70:	02e7e663          	bltu	a5,a4,80002a9c <fetchaddr+0x4e>
	if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002a74:	46a1                	li	a3,8
    80002a76:	8626                	mv	a2,s1
    80002a78:	85ca                	mv	a1,s2
    80002a7a:	6928                	ld	a0,80(a0)
    80002a7c:	fffff097          	auipc	ra,0xfffff
    80002a80:	c92080e7          	jalr	-878(ra) # 8000170e <copyin>
    80002a84:	00a03533          	snez	a0,a0
    80002a88:	40a00533          	neg	a0,a0
}
    80002a8c:	60e2                	ld	ra,24(sp)
    80002a8e:	6442                	ld	s0,16(sp)
    80002a90:	64a2                	ld	s1,8(sp)
    80002a92:	6902                	ld	s2,0(sp)
    80002a94:	6105                	addi	sp,sp,32
    80002a96:	8082                	ret
		return -1;
    80002a98:	557d                	li	a0,-1
    80002a9a:	bfcd                	j	80002a8c <fetchaddr+0x3e>
    80002a9c:	557d                	li	a0,-1
    80002a9e:	b7fd                	j	80002a8c <fetchaddr+0x3e>

0000000080002aa0 <fetchstr>:
{
    80002aa0:	7179                	addi	sp,sp,-48
    80002aa2:	f406                	sd	ra,40(sp)
    80002aa4:	f022                	sd	s0,32(sp)
    80002aa6:	ec26                	sd	s1,24(sp)
    80002aa8:	e84a                	sd	s2,16(sp)
    80002aaa:	e44e                	sd	s3,8(sp)
    80002aac:	1800                	addi	s0,sp,48
    80002aae:	892a                	mv	s2,a0
    80002ab0:	84ae                	mv	s1,a1
    80002ab2:	89b2                	mv	s3,a2
	struct proc *p = myproc();
    80002ab4:	fffff097          	auipc	ra,0xfffff
    80002ab8:	f88080e7          	jalr	-120(ra) # 80001a3c <myproc>
	int err = copyinstr(p->pagetable, buf, addr, max);
    80002abc:	86ce                	mv	a3,s3
    80002abe:	864a                	mv	a2,s2
    80002ac0:	85a6                	mv	a1,s1
    80002ac2:	6928                	ld	a0,80(a0)
    80002ac4:	fffff097          	auipc	ra,0xfffff
    80002ac8:	cd6080e7          	jalr	-810(ra) # 8000179a <copyinstr>
	if(err < 0)
    80002acc:	00054763          	bltz	a0,80002ada <fetchstr+0x3a>
	return strlen(buf);
    80002ad0:	8526                	mv	a0,s1
    80002ad2:	ffffe097          	auipc	ra,0xffffe
    80002ad6:	392080e7          	jalr	914(ra) # 80000e64 <strlen>
}
    80002ada:	70a2                	ld	ra,40(sp)
    80002adc:	7402                	ld	s0,32(sp)
    80002ade:	64e2                	ld	s1,24(sp)
    80002ae0:	6942                	ld	s2,16(sp)
    80002ae2:	69a2                	ld	s3,8(sp)
    80002ae4:	6145                	addi	sp,sp,48
    80002ae6:	8082                	ret

0000000080002ae8 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002ae8:	1101                	addi	sp,sp,-32
    80002aea:	ec06                	sd	ra,24(sp)
    80002aec:	e822                	sd	s0,16(sp)
    80002aee:	e426                	sd	s1,8(sp)
    80002af0:	1000                	addi	s0,sp,32
    80002af2:	84ae                	mv	s1,a1
	*ip = argraw(n);
    80002af4:	00000097          	auipc	ra,0x0
    80002af8:	ef2080e7          	jalr	-270(ra) # 800029e6 <argraw>
    80002afc:	c088                	sw	a0,0(s1)
	return 0;
}
    80002afe:	4501                	li	a0,0
    80002b00:	60e2                	ld	ra,24(sp)
    80002b02:	6442                	ld	s0,16(sp)
    80002b04:	64a2                	ld	s1,8(sp)
    80002b06:	6105                	addi	sp,sp,32
    80002b08:	8082                	ret

0000000080002b0a <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002b0a:	1101                	addi	sp,sp,-32
    80002b0c:	ec06                	sd	ra,24(sp)
    80002b0e:	e822                	sd	s0,16(sp)
    80002b10:	e426                	sd	s1,8(sp)
    80002b12:	1000                	addi	s0,sp,32
    80002b14:	84ae                	mv	s1,a1
	*ip = argraw(n);
    80002b16:	00000097          	auipc	ra,0x0
    80002b1a:	ed0080e7          	jalr	-304(ra) # 800029e6 <argraw>
    80002b1e:	e088                	sd	a0,0(s1)
	return 0;
}
    80002b20:	4501                	li	a0,0
    80002b22:	60e2                	ld	ra,24(sp)
    80002b24:	6442                	ld	s0,16(sp)
    80002b26:	64a2                	ld	s1,8(sp)
    80002b28:	6105                	addi	sp,sp,32
    80002b2a:	8082                	ret

0000000080002b2c <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002b2c:	1101                	addi	sp,sp,-32
    80002b2e:	ec06                	sd	ra,24(sp)
    80002b30:	e822                	sd	s0,16(sp)
    80002b32:	e426                	sd	s1,8(sp)
    80002b34:	e04a                	sd	s2,0(sp)
    80002b36:	1000                	addi	s0,sp,32
    80002b38:	84ae                	mv	s1,a1
    80002b3a:	8932                	mv	s2,a2
	*ip = argraw(n);
    80002b3c:	00000097          	auipc	ra,0x0
    80002b40:	eaa080e7          	jalr	-342(ra) # 800029e6 <argraw>
	uint64 addr;
	if(argaddr(n, &addr) < 0)
		return -1;
	return fetchstr(addr, buf, max);
    80002b44:	864a                	mv	a2,s2
    80002b46:	85a6                	mv	a1,s1
    80002b48:	00000097          	auipc	ra,0x0
    80002b4c:	f58080e7          	jalr	-168(ra) # 80002aa0 <fetchstr>
}
    80002b50:	60e2                	ld	ra,24(sp)
    80002b52:	6442                	ld	s0,16(sp)
    80002b54:	64a2                	ld	s1,8(sp)
    80002b56:	6902                	ld	s2,0(sp)
    80002b58:	6105                	addi	sp,sp,32
    80002b5a:	8082                	ret

0000000080002b5c <syscall>:
[SYS_close]   sys_close,
};

void
syscall(void)
{
    80002b5c:	1101                	addi	sp,sp,-32
    80002b5e:	ec06                	sd	ra,24(sp)
    80002b60:	e822                	sd	s0,16(sp)
    80002b62:	e426                	sd	s1,8(sp)
    80002b64:	e04a                	sd	s2,0(sp)
    80002b66:	1000                	addi	s0,sp,32
	int num;
	struct proc *p = myproc();
    80002b68:	fffff097          	auipc	ra,0xfffff
    80002b6c:	ed4080e7          	jalr	-300(ra) # 80001a3c <myproc>
    80002b70:	84aa                	mv	s1,a0

	num = p->trapframe->a7;
    80002b72:	05853903          	ld	s2,88(a0)
    80002b76:	0a893783          	ld	a5,168(s2)
    80002b7a:	0007869b          	sext.w	a3,a5
	if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002b7e:	37fd                	addiw	a5,a5,-1
    80002b80:	4751                	li	a4,20
    80002b82:	00f76f63          	bltu	a4,a5,80002ba0 <syscall+0x44>
    80002b86:	00369713          	slli	a4,a3,0x3
    80002b8a:	00006797          	auipc	a5,0x6
    80002b8e:	8c678793          	addi	a5,a5,-1850 # 80008450 <syscalls>
    80002b92:	97ba                	add	a5,a5,a4
    80002b94:	639c                	ld	a5,0(a5)
    80002b96:	c789                	beqz	a5,80002ba0 <syscall+0x44>
		p->trapframe->a0 = syscalls[num]();
    80002b98:	9782                	jalr	a5
    80002b9a:	06a93823          	sd	a0,112(s2)
    80002b9e:	a839                	j	80002bbc <syscall+0x60>
	} else {
		printf("%d %s: unknown sys call %d\n",
    80002ba0:	15848613          	addi	a2,s1,344
    80002ba4:	588c                	lw	a1,48(s1)
    80002ba6:	00006517          	auipc	a0,0x6
    80002baa:	87250513          	addi	a0,a0,-1934 # 80008418 <states.1713+0x150>
    80002bae:	ffffe097          	auipc	ra,0xffffe
    80002bb2:	9da080e7          	jalr	-1574(ra) # 80000588 <printf>
				p->pid, p->name, num);
		p->trapframe->a0 = -1;
    80002bb6:	6cbc                	ld	a5,88(s1)
    80002bb8:	577d                	li	a4,-1
    80002bba:	fbb8                	sd	a4,112(a5)
	}
}
    80002bbc:	60e2                	ld	ra,24(sp)
    80002bbe:	6442                	ld	s0,16(sp)
    80002bc0:	64a2                	ld	s1,8(sp)
    80002bc2:	6902                	ld	s2,0(sp)
    80002bc4:	6105                	addi	sp,sp,32
    80002bc6:	8082                	ret

0000000080002bc8 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002bc8:	1101                	addi	sp,sp,-32
    80002bca:	ec06                	sd	ra,24(sp)
    80002bcc:	e822                	sd	s0,16(sp)
    80002bce:	1000                	addi	s0,sp,32
	int n;
	if(argint(0, &n) < 0)
    80002bd0:	fec40593          	addi	a1,s0,-20
    80002bd4:	4501                	li	a0,0
    80002bd6:	00000097          	auipc	ra,0x0
    80002bda:	f12080e7          	jalr	-238(ra) # 80002ae8 <argint>
		return -1;
    80002bde:	57fd                	li	a5,-1
	if(argint(0, &n) < 0)
    80002be0:	00054963          	bltz	a0,80002bf2 <sys_exit+0x2a>
	exit(n);
    80002be4:	fec42503          	lw	a0,-20(s0)
    80002be8:	fffff097          	auipc	ra,0xfffff
    80002bec:	76c080e7          	jalr	1900(ra) # 80002354 <exit>
	return 0;  // not reached
    80002bf0:	4781                	li	a5,0
}
    80002bf2:	853e                	mv	a0,a5
    80002bf4:	60e2                	ld	ra,24(sp)
    80002bf6:	6442                	ld	s0,16(sp)
    80002bf8:	6105                	addi	sp,sp,32
    80002bfa:	8082                	ret

0000000080002bfc <sys_getpid>:

uint64
sys_getpid(void)
{
    80002bfc:	1141                	addi	sp,sp,-16
    80002bfe:	e406                	sd	ra,8(sp)
    80002c00:	e022                	sd	s0,0(sp)
    80002c02:	0800                	addi	s0,sp,16
	return myproc()->pid;
    80002c04:	fffff097          	auipc	ra,0xfffff
    80002c08:	e38080e7          	jalr	-456(ra) # 80001a3c <myproc>
}
    80002c0c:	5908                	lw	a0,48(a0)
    80002c0e:	60a2                	ld	ra,8(sp)
    80002c10:	6402                	ld	s0,0(sp)
    80002c12:	0141                	addi	sp,sp,16
    80002c14:	8082                	ret

0000000080002c16 <sys_fork>:

uint64
sys_fork(void)
{
    80002c16:	1141                	addi	sp,sp,-16
    80002c18:	e406                	sd	ra,8(sp)
    80002c1a:	e022                	sd	s0,0(sp)
    80002c1c:	0800                	addi	s0,sp,16
	return fork();
    80002c1e:	fffff097          	auipc	ra,0xfffff
    80002c22:	1ec080e7          	jalr	492(ra) # 80001e0a <fork>
}
    80002c26:	60a2                	ld	ra,8(sp)
    80002c28:	6402                	ld	s0,0(sp)
    80002c2a:	0141                	addi	sp,sp,16
    80002c2c:	8082                	ret

0000000080002c2e <sys_wait>:

uint64
sys_wait(void)
{
    80002c2e:	1101                	addi	sp,sp,-32
    80002c30:	ec06                	sd	ra,24(sp)
    80002c32:	e822                	sd	s0,16(sp)
    80002c34:	1000                	addi	s0,sp,32
	uint64 p;
	if(argaddr(0, &p) < 0)
    80002c36:	fe840593          	addi	a1,s0,-24
    80002c3a:	4501                	li	a0,0
    80002c3c:	00000097          	auipc	ra,0x0
    80002c40:	ece080e7          	jalr	-306(ra) # 80002b0a <argaddr>
    80002c44:	87aa                	mv	a5,a0
		return -1;
    80002c46:	557d                	li	a0,-1
	if(argaddr(0, &p) < 0)
    80002c48:	0007c863          	bltz	a5,80002c58 <sys_wait+0x2a>
	return wait(p);
    80002c4c:	fe843503          	ld	a0,-24(s0)
    80002c50:	fffff097          	auipc	ra,0xfffff
    80002c54:	50c080e7          	jalr	1292(ra) # 8000215c <wait>
}
    80002c58:	60e2                	ld	ra,24(sp)
    80002c5a:	6442                	ld	s0,16(sp)
    80002c5c:	6105                	addi	sp,sp,32
    80002c5e:	8082                	ret

0000000080002c60 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002c60:	7179                	addi	sp,sp,-48
    80002c62:	f406                	sd	ra,40(sp)
    80002c64:	f022                	sd	s0,32(sp)
    80002c66:	ec26                	sd	s1,24(sp)
    80002c68:	1800                	addi	s0,sp,48
	int addr;
	int n;
	// struct proc *p = myproc();

	if(argint(0, &n) < 0)
    80002c6a:	fdc40593          	addi	a1,s0,-36
    80002c6e:	4501                	li	a0,0
    80002c70:	00000097          	auipc	ra,0x0
    80002c74:	e78080e7          	jalr	-392(ra) # 80002ae8 <argint>
    80002c78:	87aa                	mv	a5,a0
		return -1;
    80002c7a:	557d                	li	a0,-1
	if(argint(0, &n) < 0)
    80002c7c:	0207c063          	bltz	a5,80002c9c <sys_sbrk+0x3c>
	addr = myproc()->sz;
    80002c80:	fffff097          	auipc	ra,0xfffff
    80002c84:	dbc080e7          	jalr	-580(ra) # 80001a3c <myproc>
    80002c88:	4524                	lw	s1,72(a0)

	// printf("%x\n", p->sz);
	// debug_uvmpte(p->pagetable, 0, p->sz);

	if(growproc(n) < 0)
    80002c8a:	fdc42503          	lw	a0,-36(s0)
    80002c8e:	fffff097          	auipc	ra,0xfffff
    80002c92:	108080e7          	jalr	264(ra) # 80001d96 <growproc>
    80002c96:	00054863          	bltz	a0,80002ca6 <sys_sbrk+0x46>
		return -1;

	// printf("%x\n", p->sz);
	// debug_uvmpte(p->pagetable, 0, p->sz);

	return addr;
    80002c9a:	8526                	mv	a0,s1
}
    80002c9c:	70a2                	ld	ra,40(sp)
    80002c9e:	7402                	ld	s0,32(sp)
    80002ca0:	64e2                	ld	s1,24(sp)
    80002ca2:	6145                	addi	sp,sp,48
    80002ca4:	8082                	ret
		return -1;
    80002ca6:	557d                	li	a0,-1
    80002ca8:	bfd5                	j	80002c9c <sys_sbrk+0x3c>

0000000080002caa <sys_sleep>:

uint64
sys_sleep(void)
{
    80002caa:	7139                	addi	sp,sp,-64
    80002cac:	fc06                	sd	ra,56(sp)
    80002cae:	f822                	sd	s0,48(sp)
    80002cb0:	f426                	sd	s1,40(sp)
    80002cb2:	f04a                	sd	s2,32(sp)
    80002cb4:	ec4e                	sd	s3,24(sp)
    80002cb6:	0080                	addi	s0,sp,64
	int n;
	uint ticks0;

	if(argint(0, &n) < 0)
    80002cb8:	fcc40593          	addi	a1,s0,-52
    80002cbc:	4501                	li	a0,0
    80002cbe:	00000097          	auipc	ra,0x0
    80002cc2:	e2a080e7          	jalr	-470(ra) # 80002ae8 <argint>
		return -1;
    80002cc6:	57fd                	li	a5,-1
	if(argint(0, &n) < 0)
    80002cc8:	06054563          	bltz	a0,80002d32 <sys_sleep+0x88>
	acquire(&tickslock);
    80002ccc:	0001b517          	auipc	a0,0x1b
    80002cd0:	40450513          	addi	a0,a0,1028 # 8001e0d0 <tickslock>
    80002cd4:	ffffe097          	auipc	ra,0xffffe
    80002cd8:	f10080e7          	jalr	-240(ra) # 80000be4 <acquire>
	ticks0 = ticks;
    80002cdc:	0000d917          	auipc	s2,0xd
    80002ce0:	35492903          	lw	s2,852(s2) # 80010030 <ticks>
	while(ticks - ticks0 < n){
    80002ce4:	fcc42783          	lw	a5,-52(s0)
    80002ce8:	cf85                	beqz	a5,80002d20 <sys_sleep+0x76>
		if(myproc()->killed){
			release(&tickslock);
			return -1;
		}
		sleep(&ticks, &tickslock);
    80002cea:	0001b997          	auipc	s3,0x1b
    80002cee:	3e698993          	addi	s3,s3,998 # 8001e0d0 <tickslock>
    80002cf2:	0000d497          	auipc	s1,0xd
    80002cf6:	33e48493          	addi	s1,s1,830 # 80010030 <ticks>
		if(myproc()->killed){
    80002cfa:	fffff097          	auipc	ra,0xfffff
    80002cfe:	d42080e7          	jalr	-702(ra) # 80001a3c <myproc>
    80002d02:	551c                	lw	a5,40(a0)
    80002d04:	ef9d                	bnez	a5,80002d42 <sys_sleep+0x98>
		sleep(&ticks, &tickslock);
    80002d06:	85ce                	mv	a1,s3
    80002d08:	8526                	mv	a0,s1
    80002d0a:	fffff097          	auipc	ra,0xfffff
    80002d0e:	3ee080e7          	jalr	1006(ra) # 800020f8 <sleep>
	while(ticks - ticks0 < n){
    80002d12:	409c                	lw	a5,0(s1)
    80002d14:	412787bb          	subw	a5,a5,s2
    80002d18:	fcc42703          	lw	a4,-52(s0)
    80002d1c:	fce7efe3          	bltu	a5,a4,80002cfa <sys_sleep+0x50>
	}
	release(&tickslock);
    80002d20:	0001b517          	auipc	a0,0x1b
    80002d24:	3b050513          	addi	a0,a0,944 # 8001e0d0 <tickslock>
    80002d28:	ffffe097          	auipc	ra,0xffffe
    80002d2c:	f70080e7          	jalr	-144(ra) # 80000c98 <release>
	return 0;
    80002d30:	4781                	li	a5,0
}
    80002d32:	853e                	mv	a0,a5
    80002d34:	70e2                	ld	ra,56(sp)
    80002d36:	7442                	ld	s0,48(sp)
    80002d38:	74a2                	ld	s1,40(sp)
    80002d3a:	7902                	ld	s2,32(sp)
    80002d3c:	69e2                	ld	s3,24(sp)
    80002d3e:	6121                	addi	sp,sp,64
    80002d40:	8082                	ret
			release(&tickslock);
    80002d42:	0001b517          	auipc	a0,0x1b
    80002d46:	38e50513          	addi	a0,a0,910 # 8001e0d0 <tickslock>
    80002d4a:	ffffe097          	auipc	ra,0xffffe
    80002d4e:	f4e080e7          	jalr	-178(ra) # 80000c98 <release>
			return -1;
    80002d52:	57fd                	li	a5,-1
    80002d54:	bff9                	j	80002d32 <sys_sleep+0x88>

0000000080002d56 <sys_kill>:

uint64
sys_kill(void)
{
    80002d56:	1101                	addi	sp,sp,-32
    80002d58:	ec06                	sd	ra,24(sp)
    80002d5a:	e822                	sd	s0,16(sp)
    80002d5c:	1000                	addi	s0,sp,32
	int pid;

	if(argint(0, &pid) < 0)
    80002d5e:	fec40593          	addi	a1,s0,-20
    80002d62:	4501                	li	a0,0
    80002d64:	00000097          	auipc	ra,0x0
    80002d68:	d84080e7          	jalr	-636(ra) # 80002ae8 <argint>
    80002d6c:	87aa                	mv	a5,a0
		return -1;
    80002d6e:	557d                	li	a0,-1
	if(argint(0, &pid) < 0)
    80002d70:	0007c863          	bltz	a5,80002d80 <sys_kill+0x2a>
	return kill(pid);
    80002d74:	fec42503          	lw	a0,-20(s0)
    80002d78:	fffff097          	auipc	ra,0xfffff
    80002d7c:	6b2080e7          	jalr	1714(ra) # 8000242a <kill>
}
    80002d80:	60e2                	ld	ra,24(sp)
    80002d82:	6442                	ld	s0,16(sp)
    80002d84:	6105                	addi	sp,sp,32
    80002d86:	8082                	ret

0000000080002d88 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002d88:	1101                	addi	sp,sp,-32
    80002d8a:	ec06                	sd	ra,24(sp)
    80002d8c:	e822                	sd	s0,16(sp)
    80002d8e:	e426                	sd	s1,8(sp)
    80002d90:	1000                	addi	s0,sp,32
	uint xticks;

	acquire(&tickslock);
    80002d92:	0001b517          	auipc	a0,0x1b
    80002d96:	33e50513          	addi	a0,a0,830 # 8001e0d0 <tickslock>
    80002d9a:	ffffe097          	auipc	ra,0xffffe
    80002d9e:	e4a080e7          	jalr	-438(ra) # 80000be4 <acquire>
	xticks = ticks;
    80002da2:	0000d497          	auipc	s1,0xd
    80002da6:	28e4a483          	lw	s1,654(s1) # 80010030 <ticks>
	release(&tickslock);
    80002daa:	0001b517          	auipc	a0,0x1b
    80002dae:	32650513          	addi	a0,a0,806 # 8001e0d0 <tickslock>
    80002db2:	ffffe097          	auipc	ra,0xffffe
    80002db6:	ee6080e7          	jalr	-282(ra) # 80000c98 <release>
	return xticks;
}
    80002dba:	02049513          	slli	a0,s1,0x20
    80002dbe:	9101                	srli	a0,a0,0x20
    80002dc0:	60e2                	ld	ra,24(sp)
    80002dc2:	6442                	ld	s0,16(sp)
    80002dc4:	64a2                	ld	s1,8(sp)
    80002dc6:	6105                	addi	sp,sp,32
    80002dc8:	8082                	ret

0000000080002dca <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002dca:	7179                	addi	sp,sp,-48
    80002dcc:	f406                	sd	ra,40(sp)
    80002dce:	f022                	sd	s0,32(sp)
    80002dd0:	ec26                	sd	s1,24(sp)
    80002dd2:	e84a                	sd	s2,16(sp)
    80002dd4:	e44e                	sd	s3,8(sp)
    80002dd6:	e052                	sd	s4,0(sp)
    80002dd8:	1800                	addi	s0,sp,48
	struct buf *b;

	initlock(&bcache.lock, "bcache");
    80002dda:	00005597          	auipc	a1,0x5
    80002dde:	72658593          	addi	a1,a1,1830 # 80008500 <syscalls+0xb0>
    80002de2:	0001b517          	auipc	a0,0x1b
    80002de6:	30650513          	addi	a0,a0,774 # 8001e0e8 <bcache>
    80002dea:	ffffe097          	auipc	ra,0xffffe
    80002dee:	d6a080e7          	jalr	-662(ra) # 80000b54 <initlock>

	// Create linked list of buffers
	bcache.head.prev = &bcache.head;
    80002df2:	00023797          	auipc	a5,0x23
    80002df6:	2f678793          	addi	a5,a5,758 # 800260e8 <bcache+0x8000>
    80002dfa:	00023717          	auipc	a4,0x23
    80002dfe:	55670713          	addi	a4,a4,1366 # 80026350 <bcache+0x8268>
    80002e02:	2ae7b823          	sd	a4,688(a5)
	bcache.head.next = &bcache.head;
    80002e06:	2ae7bc23          	sd	a4,696(a5)
	for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002e0a:	0001b497          	auipc	s1,0x1b
    80002e0e:	2f648493          	addi	s1,s1,758 # 8001e100 <bcache+0x18>
		b->next = bcache.head.next;
    80002e12:	893e                	mv	s2,a5
		b->prev = &bcache.head;
    80002e14:	89ba                	mv	s3,a4
		initsleeplock(&b->lock, "buffer");
    80002e16:	00005a17          	auipc	s4,0x5
    80002e1a:	6f2a0a13          	addi	s4,s4,1778 # 80008508 <syscalls+0xb8>
		b->next = bcache.head.next;
    80002e1e:	2b893783          	ld	a5,696(s2)
    80002e22:	e8bc                	sd	a5,80(s1)
		b->prev = &bcache.head;
    80002e24:	0534b423          	sd	s3,72(s1)
		initsleeplock(&b->lock, "buffer");
    80002e28:	85d2                	mv	a1,s4
    80002e2a:	01048513          	addi	a0,s1,16
    80002e2e:	00001097          	auipc	ra,0x1
    80002e32:	4bc080e7          	jalr	1212(ra) # 800042ea <initsleeplock>
		bcache.head.next->prev = b;
    80002e36:	2b893783          	ld	a5,696(s2)
    80002e3a:	e7a4                	sd	s1,72(a5)
		bcache.head.next = b;
    80002e3c:	2a993c23          	sd	s1,696(s2)
	for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002e40:	45848493          	addi	s1,s1,1112
    80002e44:	fd349de3          	bne	s1,s3,80002e1e <binit+0x54>
	}
}
    80002e48:	70a2                	ld	ra,40(sp)
    80002e4a:	7402                	ld	s0,32(sp)
    80002e4c:	64e2                	ld	s1,24(sp)
    80002e4e:	6942                	ld	s2,16(sp)
    80002e50:	69a2                	ld	s3,8(sp)
    80002e52:	6a02                	ld	s4,0(sp)
    80002e54:	6145                	addi	sp,sp,48
    80002e56:	8082                	ret

0000000080002e58 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80002e58:	7179                	addi	sp,sp,-48
    80002e5a:	f406                	sd	ra,40(sp)
    80002e5c:	f022                	sd	s0,32(sp)
    80002e5e:	ec26                	sd	s1,24(sp)
    80002e60:	e84a                	sd	s2,16(sp)
    80002e62:	e44e                	sd	s3,8(sp)
    80002e64:	1800                	addi	s0,sp,48
    80002e66:	89aa                	mv	s3,a0
    80002e68:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    80002e6a:	0001b517          	auipc	a0,0x1b
    80002e6e:	27e50513          	addi	a0,a0,638 # 8001e0e8 <bcache>
    80002e72:	ffffe097          	auipc	ra,0xffffe
    80002e76:	d72080e7          	jalr	-654(ra) # 80000be4 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80002e7a:	00023497          	auipc	s1,0x23
    80002e7e:	5264b483          	ld	s1,1318(s1) # 800263a0 <bcache+0x82b8>
    80002e82:	00023797          	auipc	a5,0x23
    80002e86:	4ce78793          	addi	a5,a5,1230 # 80026350 <bcache+0x8268>
    80002e8a:	02f48f63          	beq	s1,a5,80002ec8 <bread+0x70>
    80002e8e:	873e                	mv	a4,a5
    80002e90:	a021                	j	80002e98 <bread+0x40>
    80002e92:	68a4                	ld	s1,80(s1)
    80002e94:	02e48a63          	beq	s1,a4,80002ec8 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80002e98:	449c                	lw	a5,8(s1)
    80002e9a:	ff379ce3          	bne	a5,s3,80002e92 <bread+0x3a>
    80002e9e:	44dc                	lw	a5,12(s1)
    80002ea0:	ff2799e3          	bne	a5,s2,80002e92 <bread+0x3a>
      b->refcnt++;
    80002ea4:	40bc                	lw	a5,64(s1)
    80002ea6:	2785                	addiw	a5,a5,1
    80002ea8:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002eaa:	0001b517          	auipc	a0,0x1b
    80002eae:	23e50513          	addi	a0,a0,574 # 8001e0e8 <bcache>
    80002eb2:	ffffe097          	auipc	ra,0xffffe
    80002eb6:	de6080e7          	jalr	-538(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    80002eba:	01048513          	addi	a0,s1,16
    80002ebe:	00001097          	auipc	ra,0x1
    80002ec2:	466080e7          	jalr	1126(ra) # 80004324 <acquiresleep>
      return b;
    80002ec6:	a8b9                	j	80002f24 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002ec8:	00023497          	auipc	s1,0x23
    80002ecc:	4d04b483          	ld	s1,1232(s1) # 80026398 <bcache+0x82b0>
    80002ed0:	00023797          	auipc	a5,0x23
    80002ed4:	48078793          	addi	a5,a5,1152 # 80026350 <bcache+0x8268>
    80002ed8:	00f48863          	beq	s1,a5,80002ee8 <bread+0x90>
    80002edc:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80002ede:	40bc                	lw	a5,64(s1)
    80002ee0:	cf81                	beqz	a5,80002ef8 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002ee2:	64a4                	ld	s1,72(s1)
    80002ee4:	fee49de3          	bne	s1,a4,80002ede <bread+0x86>
  panic("bget: no buffers");
    80002ee8:	00005517          	auipc	a0,0x5
    80002eec:	62850513          	addi	a0,a0,1576 # 80008510 <syscalls+0xc0>
    80002ef0:	ffffd097          	auipc	ra,0xffffd
    80002ef4:	64e080e7          	jalr	1614(ra) # 8000053e <panic>
      b->dev = dev;
    80002ef8:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    80002efc:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    80002f00:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80002f04:	4785                	li	a5,1
    80002f06:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002f08:	0001b517          	auipc	a0,0x1b
    80002f0c:	1e050513          	addi	a0,a0,480 # 8001e0e8 <bcache>
    80002f10:	ffffe097          	auipc	ra,0xffffe
    80002f14:	d88080e7          	jalr	-632(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    80002f18:	01048513          	addi	a0,s1,16
    80002f1c:	00001097          	auipc	ra,0x1
    80002f20:	408080e7          	jalr	1032(ra) # 80004324 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80002f24:	409c                	lw	a5,0(s1)
    80002f26:	cb89                	beqz	a5,80002f38 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80002f28:	8526                	mv	a0,s1
    80002f2a:	70a2                	ld	ra,40(sp)
    80002f2c:	7402                	ld	s0,32(sp)
    80002f2e:	64e2                	ld	s1,24(sp)
    80002f30:	6942                	ld	s2,16(sp)
    80002f32:	69a2                	ld	s3,8(sp)
    80002f34:	6145                	addi	sp,sp,48
    80002f36:	8082                	ret
    virtio_disk_rw(b, 0);
    80002f38:	4581                	li	a1,0
    80002f3a:	8526                	mv	a0,s1
    80002f3c:	00003097          	auipc	ra,0x3
    80002f40:	f0a080e7          	jalr	-246(ra) # 80005e46 <virtio_disk_rw>
    b->valid = 1;
    80002f44:	4785                	li	a5,1
    80002f46:	c09c                	sw	a5,0(s1)
  return b;
    80002f48:	b7c5                	j	80002f28 <bread+0xd0>

0000000080002f4a <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80002f4a:	1101                	addi	sp,sp,-32
    80002f4c:	ec06                	sd	ra,24(sp)
    80002f4e:	e822                	sd	s0,16(sp)
    80002f50:	e426                	sd	s1,8(sp)
    80002f52:	1000                	addi	s0,sp,32
    80002f54:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80002f56:	0541                	addi	a0,a0,16
    80002f58:	00001097          	auipc	ra,0x1
    80002f5c:	466080e7          	jalr	1126(ra) # 800043be <holdingsleep>
    80002f60:	cd01                	beqz	a0,80002f78 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80002f62:	4585                	li	a1,1
    80002f64:	8526                	mv	a0,s1
    80002f66:	00003097          	auipc	ra,0x3
    80002f6a:	ee0080e7          	jalr	-288(ra) # 80005e46 <virtio_disk_rw>
}
    80002f6e:	60e2                	ld	ra,24(sp)
    80002f70:	6442                	ld	s0,16(sp)
    80002f72:	64a2                	ld	s1,8(sp)
    80002f74:	6105                	addi	sp,sp,32
    80002f76:	8082                	ret
    panic("bwrite");
    80002f78:	00005517          	auipc	a0,0x5
    80002f7c:	5b050513          	addi	a0,a0,1456 # 80008528 <syscalls+0xd8>
    80002f80:	ffffd097          	auipc	ra,0xffffd
    80002f84:	5be080e7          	jalr	1470(ra) # 8000053e <panic>

0000000080002f88 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80002f88:	1101                	addi	sp,sp,-32
    80002f8a:	ec06                	sd	ra,24(sp)
    80002f8c:	e822                	sd	s0,16(sp)
    80002f8e:	e426                	sd	s1,8(sp)
    80002f90:	e04a                	sd	s2,0(sp)
    80002f92:	1000                	addi	s0,sp,32
    80002f94:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80002f96:	01050913          	addi	s2,a0,16
    80002f9a:	854a                	mv	a0,s2
    80002f9c:	00001097          	auipc	ra,0x1
    80002fa0:	422080e7          	jalr	1058(ra) # 800043be <holdingsleep>
    80002fa4:	c92d                	beqz	a0,80003016 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80002fa6:	854a                	mv	a0,s2
    80002fa8:	00001097          	auipc	ra,0x1
    80002fac:	3d2080e7          	jalr	978(ra) # 8000437a <releasesleep>

  acquire(&bcache.lock);
    80002fb0:	0001b517          	auipc	a0,0x1b
    80002fb4:	13850513          	addi	a0,a0,312 # 8001e0e8 <bcache>
    80002fb8:	ffffe097          	auipc	ra,0xffffe
    80002fbc:	c2c080e7          	jalr	-980(ra) # 80000be4 <acquire>
  b->refcnt--;
    80002fc0:	40bc                	lw	a5,64(s1)
    80002fc2:	37fd                	addiw	a5,a5,-1
    80002fc4:	0007871b          	sext.w	a4,a5
    80002fc8:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80002fca:	eb05                	bnez	a4,80002ffa <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80002fcc:	68bc                	ld	a5,80(s1)
    80002fce:	64b8                	ld	a4,72(s1)
    80002fd0:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80002fd2:	64bc                	ld	a5,72(s1)
    80002fd4:	68b8                	ld	a4,80(s1)
    80002fd6:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80002fd8:	00023797          	auipc	a5,0x23
    80002fdc:	11078793          	addi	a5,a5,272 # 800260e8 <bcache+0x8000>
    80002fe0:	2b87b703          	ld	a4,696(a5)
    80002fe4:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80002fe6:	00023717          	auipc	a4,0x23
    80002fea:	36a70713          	addi	a4,a4,874 # 80026350 <bcache+0x8268>
    80002fee:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80002ff0:	2b87b703          	ld	a4,696(a5)
    80002ff4:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80002ff6:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80002ffa:	0001b517          	auipc	a0,0x1b
    80002ffe:	0ee50513          	addi	a0,a0,238 # 8001e0e8 <bcache>
    80003002:	ffffe097          	auipc	ra,0xffffe
    80003006:	c96080e7          	jalr	-874(ra) # 80000c98 <release>
}
    8000300a:	60e2                	ld	ra,24(sp)
    8000300c:	6442                	ld	s0,16(sp)
    8000300e:	64a2                	ld	s1,8(sp)
    80003010:	6902                	ld	s2,0(sp)
    80003012:	6105                	addi	sp,sp,32
    80003014:	8082                	ret
    panic("brelse");
    80003016:	00005517          	auipc	a0,0x5
    8000301a:	51a50513          	addi	a0,a0,1306 # 80008530 <syscalls+0xe0>
    8000301e:	ffffd097          	auipc	ra,0xffffd
    80003022:	520080e7          	jalr	1312(ra) # 8000053e <panic>

0000000080003026 <bpin>:

void
bpin(struct buf *b) {
    80003026:	1101                	addi	sp,sp,-32
    80003028:	ec06                	sd	ra,24(sp)
    8000302a:	e822                	sd	s0,16(sp)
    8000302c:	e426                	sd	s1,8(sp)
    8000302e:	1000                	addi	s0,sp,32
    80003030:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003032:	0001b517          	auipc	a0,0x1b
    80003036:	0b650513          	addi	a0,a0,182 # 8001e0e8 <bcache>
    8000303a:	ffffe097          	auipc	ra,0xffffe
    8000303e:	baa080e7          	jalr	-1110(ra) # 80000be4 <acquire>
  b->refcnt++;
    80003042:	40bc                	lw	a5,64(s1)
    80003044:	2785                	addiw	a5,a5,1
    80003046:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003048:	0001b517          	auipc	a0,0x1b
    8000304c:	0a050513          	addi	a0,a0,160 # 8001e0e8 <bcache>
    80003050:	ffffe097          	auipc	ra,0xffffe
    80003054:	c48080e7          	jalr	-952(ra) # 80000c98 <release>
}
    80003058:	60e2                	ld	ra,24(sp)
    8000305a:	6442                	ld	s0,16(sp)
    8000305c:	64a2                	ld	s1,8(sp)
    8000305e:	6105                	addi	sp,sp,32
    80003060:	8082                	ret

0000000080003062 <bunpin>:

void
bunpin(struct buf *b) {
    80003062:	1101                	addi	sp,sp,-32
    80003064:	ec06                	sd	ra,24(sp)
    80003066:	e822                	sd	s0,16(sp)
    80003068:	e426                	sd	s1,8(sp)
    8000306a:	1000                	addi	s0,sp,32
    8000306c:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000306e:	0001b517          	auipc	a0,0x1b
    80003072:	07a50513          	addi	a0,a0,122 # 8001e0e8 <bcache>
    80003076:	ffffe097          	auipc	ra,0xffffe
    8000307a:	b6e080e7          	jalr	-1170(ra) # 80000be4 <acquire>
  b->refcnt--;
    8000307e:	40bc                	lw	a5,64(s1)
    80003080:	37fd                	addiw	a5,a5,-1
    80003082:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003084:	0001b517          	auipc	a0,0x1b
    80003088:	06450513          	addi	a0,a0,100 # 8001e0e8 <bcache>
    8000308c:	ffffe097          	auipc	ra,0xffffe
    80003090:	c0c080e7          	jalr	-1012(ra) # 80000c98 <release>
}
    80003094:	60e2                	ld	ra,24(sp)
    80003096:	6442                	ld	s0,16(sp)
    80003098:	64a2                	ld	s1,8(sp)
    8000309a:	6105                	addi	sp,sp,32
    8000309c:	8082                	ret

000000008000309e <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    8000309e:	1101                	addi	sp,sp,-32
    800030a0:	ec06                	sd	ra,24(sp)
    800030a2:	e822                	sd	s0,16(sp)
    800030a4:	e426                	sd	s1,8(sp)
    800030a6:	e04a                	sd	s2,0(sp)
    800030a8:	1000                	addi	s0,sp,32
    800030aa:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800030ac:	00d5d59b          	srliw	a1,a1,0xd
    800030b0:	00023797          	auipc	a5,0x23
    800030b4:	7147a783          	lw	a5,1812(a5) # 800267c4 <sb+0x1c>
    800030b8:	9dbd                	addw	a1,a1,a5
    800030ba:	00000097          	auipc	ra,0x0
    800030be:	d9e080e7          	jalr	-610(ra) # 80002e58 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800030c2:	0074f713          	andi	a4,s1,7
    800030c6:	4785                	li	a5,1
    800030c8:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800030cc:	14ce                	slli	s1,s1,0x33
    800030ce:	90d9                	srli	s1,s1,0x36
    800030d0:	00950733          	add	a4,a0,s1
    800030d4:	05874703          	lbu	a4,88(a4)
    800030d8:	00e7f6b3          	and	a3,a5,a4
    800030dc:	c69d                	beqz	a3,8000310a <bfree+0x6c>
    800030de:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800030e0:	94aa                	add	s1,s1,a0
    800030e2:	fff7c793          	not	a5,a5
    800030e6:	8ff9                	and	a5,a5,a4
    800030e8:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    800030ec:	00001097          	auipc	ra,0x1
    800030f0:	118080e7          	jalr	280(ra) # 80004204 <log_write>
  brelse(bp);
    800030f4:	854a                	mv	a0,s2
    800030f6:	00000097          	auipc	ra,0x0
    800030fa:	e92080e7          	jalr	-366(ra) # 80002f88 <brelse>
}
    800030fe:	60e2                	ld	ra,24(sp)
    80003100:	6442                	ld	s0,16(sp)
    80003102:	64a2                	ld	s1,8(sp)
    80003104:	6902                	ld	s2,0(sp)
    80003106:	6105                	addi	sp,sp,32
    80003108:	8082                	ret
    panic("freeing free block");
    8000310a:	00005517          	auipc	a0,0x5
    8000310e:	42e50513          	addi	a0,a0,1070 # 80008538 <syscalls+0xe8>
    80003112:	ffffd097          	auipc	ra,0xffffd
    80003116:	42c080e7          	jalr	1068(ra) # 8000053e <panic>

000000008000311a <balloc>:
{
    8000311a:	711d                	addi	sp,sp,-96
    8000311c:	ec86                	sd	ra,88(sp)
    8000311e:	e8a2                	sd	s0,80(sp)
    80003120:	e4a6                	sd	s1,72(sp)
    80003122:	e0ca                	sd	s2,64(sp)
    80003124:	fc4e                	sd	s3,56(sp)
    80003126:	f852                	sd	s4,48(sp)
    80003128:	f456                	sd	s5,40(sp)
    8000312a:	f05a                	sd	s6,32(sp)
    8000312c:	ec5e                	sd	s7,24(sp)
    8000312e:	e862                	sd	s8,16(sp)
    80003130:	e466                	sd	s9,8(sp)
    80003132:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003134:	00023797          	auipc	a5,0x23
    80003138:	6787a783          	lw	a5,1656(a5) # 800267ac <sb+0x4>
    8000313c:	cbd1                	beqz	a5,800031d0 <balloc+0xb6>
    8000313e:	8baa                	mv	s7,a0
    80003140:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003142:	00023b17          	auipc	s6,0x23
    80003146:	666b0b13          	addi	s6,s6,1638 # 800267a8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000314a:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    8000314c:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000314e:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003150:	6c89                	lui	s9,0x2
    80003152:	a831                	j	8000316e <balloc+0x54>
    brelse(bp);
    80003154:	854a                	mv	a0,s2
    80003156:	00000097          	auipc	ra,0x0
    8000315a:	e32080e7          	jalr	-462(ra) # 80002f88 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    8000315e:	015c87bb          	addw	a5,s9,s5
    80003162:	00078a9b          	sext.w	s5,a5
    80003166:	004b2703          	lw	a4,4(s6)
    8000316a:	06eaf363          	bgeu	s5,a4,800031d0 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    8000316e:	41fad79b          	sraiw	a5,s5,0x1f
    80003172:	0137d79b          	srliw	a5,a5,0x13
    80003176:	015787bb          	addw	a5,a5,s5
    8000317a:	40d7d79b          	sraiw	a5,a5,0xd
    8000317e:	01cb2583          	lw	a1,28(s6)
    80003182:	9dbd                	addw	a1,a1,a5
    80003184:	855e                	mv	a0,s7
    80003186:	00000097          	auipc	ra,0x0
    8000318a:	cd2080e7          	jalr	-814(ra) # 80002e58 <bread>
    8000318e:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003190:	004b2503          	lw	a0,4(s6)
    80003194:	000a849b          	sext.w	s1,s5
    80003198:	8662                	mv	a2,s8
    8000319a:	faa4fde3          	bgeu	s1,a0,80003154 <balloc+0x3a>
      m = 1 << (bi % 8);
    8000319e:	41f6579b          	sraiw	a5,a2,0x1f
    800031a2:	01d7d69b          	srliw	a3,a5,0x1d
    800031a6:	00c6873b          	addw	a4,a3,a2
    800031aa:	00777793          	andi	a5,a4,7
    800031ae:	9f95                	subw	a5,a5,a3
    800031b0:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800031b4:	4037571b          	sraiw	a4,a4,0x3
    800031b8:	00e906b3          	add	a3,s2,a4
    800031bc:	0586c683          	lbu	a3,88(a3)
    800031c0:	00d7f5b3          	and	a1,a5,a3
    800031c4:	cd91                	beqz	a1,800031e0 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800031c6:	2605                	addiw	a2,a2,1
    800031c8:	2485                	addiw	s1,s1,1
    800031ca:	fd4618e3          	bne	a2,s4,8000319a <balloc+0x80>
    800031ce:	b759                	j	80003154 <balloc+0x3a>
  panic("balloc: out of blocks");
    800031d0:	00005517          	auipc	a0,0x5
    800031d4:	38050513          	addi	a0,a0,896 # 80008550 <syscalls+0x100>
    800031d8:	ffffd097          	auipc	ra,0xffffd
    800031dc:	366080e7          	jalr	870(ra) # 8000053e <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    800031e0:	974a                	add	a4,a4,s2
    800031e2:	8fd5                	or	a5,a5,a3
    800031e4:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    800031e8:	854a                	mv	a0,s2
    800031ea:	00001097          	auipc	ra,0x1
    800031ee:	01a080e7          	jalr	26(ra) # 80004204 <log_write>
        brelse(bp);
    800031f2:	854a                	mv	a0,s2
    800031f4:	00000097          	auipc	ra,0x0
    800031f8:	d94080e7          	jalr	-620(ra) # 80002f88 <brelse>
  bp = bread(dev, bno);
    800031fc:	85a6                	mv	a1,s1
    800031fe:	855e                	mv	a0,s7
    80003200:	00000097          	auipc	ra,0x0
    80003204:	c58080e7          	jalr	-936(ra) # 80002e58 <bread>
    80003208:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    8000320a:	40000613          	li	a2,1024
    8000320e:	4581                	li	a1,0
    80003210:	05850513          	addi	a0,a0,88
    80003214:	ffffe097          	auipc	ra,0xffffe
    80003218:	acc080e7          	jalr	-1332(ra) # 80000ce0 <memset>
  log_write(bp);
    8000321c:	854a                	mv	a0,s2
    8000321e:	00001097          	auipc	ra,0x1
    80003222:	fe6080e7          	jalr	-26(ra) # 80004204 <log_write>
  brelse(bp);
    80003226:	854a                	mv	a0,s2
    80003228:	00000097          	auipc	ra,0x0
    8000322c:	d60080e7          	jalr	-672(ra) # 80002f88 <brelse>
}
    80003230:	8526                	mv	a0,s1
    80003232:	60e6                	ld	ra,88(sp)
    80003234:	6446                	ld	s0,80(sp)
    80003236:	64a6                	ld	s1,72(sp)
    80003238:	6906                	ld	s2,64(sp)
    8000323a:	79e2                	ld	s3,56(sp)
    8000323c:	7a42                	ld	s4,48(sp)
    8000323e:	7aa2                	ld	s5,40(sp)
    80003240:	7b02                	ld	s6,32(sp)
    80003242:	6be2                	ld	s7,24(sp)
    80003244:	6c42                	ld	s8,16(sp)
    80003246:	6ca2                	ld	s9,8(sp)
    80003248:	6125                	addi	sp,sp,96
    8000324a:	8082                	ret

000000008000324c <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    8000324c:	7179                	addi	sp,sp,-48
    8000324e:	f406                	sd	ra,40(sp)
    80003250:	f022                	sd	s0,32(sp)
    80003252:	ec26                	sd	s1,24(sp)
    80003254:	e84a                	sd	s2,16(sp)
    80003256:	e44e                	sd	s3,8(sp)
    80003258:	e052                	sd	s4,0(sp)
    8000325a:	1800                	addi	s0,sp,48
    8000325c:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    8000325e:	47ad                	li	a5,11
    80003260:	04b7fe63          	bgeu	a5,a1,800032bc <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    80003264:	ff45849b          	addiw	s1,a1,-12
    80003268:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    8000326c:	0ff00793          	li	a5,255
    80003270:	0ae7e363          	bltu	a5,a4,80003316 <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    80003274:	08052583          	lw	a1,128(a0)
    80003278:	c5ad                	beqz	a1,800032e2 <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    8000327a:	00092503          	lw	a0,0(s2)
    8000327e:	00000097          	auipc	ra,0x0
    80003282:	bda080e7          	jalr	-1062(ra) # 80002e58 <bread>
    80003286:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003288:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    8000328c:	02049593          	slli	a1,s1,0x20
    80003290:	9181                	srli	a1,a1,0x20
    80003292:	058a                	slli	a1,a1,0x2
    80003294:	00b784b3          	add	s1,a5,a1
    80003298:	0004a983          	lw	s3,0(s1)
    8000329c:	04098d63          	beqz	s3,800032f6 <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    800032a0:	8552                	mv	a0,s4
    800032a2:	00000097          	auipc	ra,0x0
    800032a6:	ce6080e7          	jalr	-794(ra) # 80002f88 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    800032aa:	854e                	mv	a0,s3
    800032ac:	70a2                	ld	ra,40(sp)
    800032ae:	7402                	ld	s0,32(sp)
    800032b0:	64e2                	ld	s1,24(sp)
    800032b2:	6942                	ld	s2,16(sp)
    800032b4:	69a2                	ld	s3,8(sp)
    800032b6:	6a02                	ld	s4,0(sp)
    800032b8:	6145                	addi	sp,sp,48
    800032ba:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    800032bc:	02059493          	slli	s1,a1,0x20
    800032c0:	9081                	srli	s1,s1,0x20
    800032c2:	048a                	slli	s1,s1,0x2
    800032c4:	94aa                	add	s1,s1,a0
    800032c6:	0504a983          	lw	s3,80(s1)
    800032ca:	fe0990e3          	bnez	s3,800032aa <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    800032ce:	4108                	lw	a0,0(a0)
    800032d0:	00000097          	auipc	ra,0x0
    800032d4:	e4a080e7          	jalr	-438(ra) # 8000311a <balloc>
    800032d8:	0005099b          	sext.w	s3,a0
    800032dc:	0534a823          	sw	s3,80(s1)
    800032e0:	b7e9                	j	800032aa <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    800032e2:	4108                	lw	a0,0(a0)
    800032e4:	00000097          	auipc	ra,0x0
    800032e8:	e36080e7          	jalr	-458(ra) # 8000311a <balloc>
    800032ec:	0005059b          	sext.w	a1,a0
    800032f0:	08b92023          	sw	a1,128(s2)
    800032f4:	b759                	j	8000327a <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    800032f6:	00092503          	lw	a0,0(s2)
    800032fa:	00000097          	auipc	ra,0x0
    800032fe:	e20080e7          	jalr	-480(ra) # 8000311a <balloc>
    80003302:	0005099b          	sext.w	s3,a0
    80003306:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    8000330a:	8552                	mv	a0,s4
    8000330c:	00001097          	auipc	ra,0x1
    80003310:	ef8080e7          	jalr	-264(ra) # 80004204 <log_write>
    80003314:	b771                	j	800032a0 <bmap+0x54>
  panic("bmap: out of range");
    80003316:	00005517          	auipc	a0,0x5
    8000331a:	25250513          	addi	a0,a0,594 # 80008568 <syscalls+0x118>
    8000331e:	ffffd097          	auipc	ra,0xffffd
    80003322:	220080e7          	jalr	544(ra) # 8000053e <panic>

0000000080003326 <iget>:
{
    80003326:	7179                	addi	sp,sp,-48
    80003328:	f406                	sd	ra,40(sp)
    8000332a:	f022                	sd	s0,32(sp)
    8000332c:	ec26                	sd	s1,24(sp)
    8000332e:	e84a                	sd	s2,16(sp)
    80003330:	e44e                	sd	s3,8(sp)
    80003332:	e052                	sd	s4,0(sp)
    80003334:	1800                	addi	s0,sp,48
    80003336:	89aa                	mv	s3,a0
    80003338:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    8000333a:	00023517          	auipc	a0,0x23
    8000333e:	48e50513          	addi	a0,a0,1166 # 800267c8 <itable>
    80003342:	ffffe097          	auipc	ra,0xffffe
    80003346:	8a2080e7          	jalr	-1886(ra) # 80000be4 <acquire>
  empty = 0;
    8000334a:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    8000334c:	00023497          	auipc	s1,0x23
    80003350:	49448493          	addi	s1,s1,1172 # 800267e0 <itable+0x18>
    80003354:	00025697          	auipc	a3,0x25
    80003358:	f1c68693          	addi	a3,a3,-228 # 80028270 <log>
    8000335c:	a039                	j	8000336a <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000335e:	02090b63          	beqz	s2,80003394 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003362:	08848493          	addi	s1,s1,136
    80003366:	02d48a63          	beq	s1,a3,8000339a <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    8000336a:	449c                	lw	a5,8(s1)
    8000336c:	fef059e3          	blez	a5,8000335e <iget+0x38>
    80003370:	4098                	lw	a4,0(s1)
    80003372:	ff3716e3          	bne	a4,s3,8000335e <iget+0x38>
    80003376:	40d8                	lw	a4,4(s1)
    80003378:	ff4713e3          	bne	a4,s4,8000335e <iget+0x38>
      ip->ref++;
    8000337c:	2785                	addiw	a5,a5,1
    8000337e:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003380:	00023517          	auipc	a0,0x23
    80003384:	44850513          	addi	a0,a0,1096 # 800267c8 <itable>
    80003388:	ffffe097          	auipc	ra,0xffffe
    8000338c:	910080e7          	jalr	-1776(ra) # 80000c98 <release>
      return ip;
    80003390:	8926                	mv	s2,s1
    80003392:	a03d                	j	800033c0 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003394:	f7f9                	bnez	a5,80003362 <iget+0x3c>
    80003396:	8926                	mv	s2,s1
    80003398:	b7e9                	j	80003362 <iget+0x3c>
  if(empty == 0)
    8000339a:	02090c63          	beqz	s2,800033d2 <iget+0xac>
  ip->dev = dev;
    8000339e:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    800033a2:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    800033a6:	4785                	li	a5,1
    800033a8:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    800033ac:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    800033b0:	00023517          	auipc	a0,0x23
    800033b4:	41850513          	addi	a0,a0,1048 # 800267c8 <itable>
    800033b8:	ffffe097          	auipc	ra,0xffffe
    800033bc:	8e0080e7          	jalr	-1824(ra) # 80000c98 <release>
}
    800033c0:	854a                	mv	a0,s2
    800033c2:	70a2                	ld	ra,40(sp)
    800033c4:	7402                	ld	s0,32(sp)
    800033c6:	64e2                	ld	s1,24(sp)
    800033c8:	6942                	ld	s2,16(sp)
    800033ca:	69a2                	ld	s3,8(sp)
    800033cc:	6a02                	ld	s4,0(sp)
    800033ce:	6145                	addi	sp,sp,48
    800033d0:	8082                	ret
    panic("iget: no inodes");
    800033d2:	00005517          	auipc	a0,0x5
    800033d6:	1ae50513          	addi	a0,a0,430 # 80008580 <syscalls+0x130>
    800033da:	ffffd097          	auipc	ra,0xffffd
    800033de:	164080e7          	jalr	356(ra) # 8000053e <panic>

00000000800033e2 <fsinit>:
fsinit(int dev) {
    800033e2:	7179                	addi	sp,sp,-48
    800033e4:	f406                	sd	ra,40(sp)
    800033e6:	f022                	sd	s0,32(sp)
    800033e8:	ec26                	sd	s1,24(sp)
    800033ea:	e84a                	sd	s2,16(sp)
    800033ec:	e44e                	sd	s3,8(sp)
    800033ee:	1800                	addi	s0,sp,48
    800033f0:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    800033f2:	4585                	li	a1,1
    800033f4:	00000097          	auipc	ra,0x0
    800033f8:	a64080e7          	jalr	-1436(ra) # 80002e58 <bread>
    800033fc:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    800033fe:	00023997          	auipc	s3,0x23
    80003402:	3aa98993          	addi	s3,s3,938 # 800267a8 <sb>
    80003406:	02000613          	li	a2,32
    8000340a:	05850593          	addi	a1,a0,88
    8000340e:	854e                	mv	a0,s3
    80003410:	ffffe097          	auipc	ra,0xffffe
    80003414:	930080e7          	jalr	-1744(ra) # 80000d40 <memmove>
  brelse(bp);
    80003418:	8526                	mv	a0,s1
    8000341a:	00000097          	auipc	ra,0x0
    8000341e:	b6e080e7          	jalr	-1170(ra) # 80002f88 <brelse>
  if(sb.magic != FSMAGIC)
    80003422:	0009a703          	lw	a4,0(s3)
    80003426:	102037b7          	lui	a5,0x10203
    8000342a:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    8000342e:	02f71263          	bne	a4,a5,80003452 <fsinit+0x70>
  initlog(dev, &sb);
    80003432:	00023597          	auipc	a1,0x23
    80003436:	37658593          	addi	a1,a1,886 # 800267a8 <sb>
    8000343a:	854a                	mv	a0,s2
    8000343c:	00001097          	auipc	ra,0x1
    80003440:	b4c080e7          	jalr	-1204(ra) # 80003f88 <initlog>
}
    80003444:	70a2                	ld	ra,40(sp)
    80003446:	7402                	ld	s0,32(sp)
    80003448:	64e2                	ld	s1,24(sp)
    8000344a:	6942                	ld	s2,16(sp)
    8000344c:	69a2                	ld	s3,8(sp)
    8000344e:	6145                	addi	sp,sp,48
    80003450:	8082                	ret
    panic("invalid file system");
    80003452:	00005517          	auipc	a0,0x5
    80003456:	13e50513          	addi	a0,a0,318 # 80008590 <syscalls+0x140>
    8000345a:	ffffd097          	auipc	ra,0xffffd
    8000345e:	0e4080e7          	jalr	228(ra) # 8000053e <panic>

0000000080003462 <iinit>:
{
    80003462:	7179                	addi	sp,sp,-48
    80003464:	f406                	sd	ra,40(sp)
    80003466:	f022                	sd	s0,32(sp)
    80003468:	ec26                	sd	s1,24(sp)
    8000346a:	e84a                	sd	s2,16(sp)
    8000346c:	e44e                	sd	s3,8(sp)
    8000346e:	1800                	addi	s0,sp,48
	initlock(&itable.lock, "itable");
    80003470:	00005597          	auipc	a1,0x5
    80003474:	13858593          	addi	a1,a1,312 # 800085a8 <syscalls+0x158>
    80003478:	00023517          	auipc	a0,0x23
    8000347c:	35050513          	addi	a0,a0,848 # 800267c8 <itable>
    80003480:	ffffd097          	auipc	ra,0xffffd
    80003484:	6d4080e7          	jalr	1748(ra) # 80000b54 <initlock>
	for(i = 0; i < NINODE; i++) {
    80003488:	00023497          	auipc	s1,0x23
    8000348c:	36848493          	addi	s1,s1,872 # 800267f0 <itable+0x28>
    80003490:	00025997          	auipc	s3,0x25
    80003494:	df098993          	addi	s3,s3,-528 # 80028280 <log+0x10>
		initsleeplock(&itable.inode[i].lock, "inode");
    80003498:	00005917          	auipc	s2,0x5
    8000349c:	11890913          	addi	s2,s2,280 # 800085b0 <syscalls+0x160>
    800034a0:	85ca                	mv	a1,s2
    800034a2:	8526                	mv	a0,s1
    800034a4:	00001097          	auipc	ra,0x1
    800034a8:	e46080e7          	jalr	-442(ra) # 800042ea <initsleeplock>
	for(i = 0; i < NINODE; i++) {
    800034ac:	08848493          	addi	s1,s1,136
    800034b0:	ff3498e3          	bne	s1,s3,800034a0 <iinit+0x3e>
}
    800034b4:	70a2                	ld	ra,40(sp)
    800034b6:	7402                	ld	s0,32(sp)
    800034b8:	64e2                	ld	s1,24(sp)
    800034ba:	6942                	ld	s2,16(sp)
    800034bc:	69a2                	ld	s3,8(sp)
    800034be:	6145                	addi	sp,sp,48
    800034c0:	8082                	ret

00000000800034c2 <ialloc>:
{
    800034c2:	715d                	addi	sp,sp,-80
    800034c4:	e486                	sd	ra,72(sp)
    800034c6:	e0a2                	sd	s0,64(sp)
    800034c8:	fc26                	sd	s1,56(sp)
    800034ca:	f84a                	sd	s2,48(sp)
    800034cc:	f44e                	sd	s3,40(sp)
    800034ce:	f052                	sd	s4,32(sp)
    800034d0:	ec56                	sd	s5,24(sp)
    800034d2:	e85a                	sd	s6,16(sp)
    800034d4:	e45e                	sd	s7,8(sp)
    800034d6:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    800034d8:	00023717          	auipc	a4,0x23
    800034dc:	2dc72703          	lw	a4,732(a4) # 800267b4 <sb+0xc>
    800034e0:	4785                	li	a5,1
    800034e2:	04e7fa63          	bgeu	a5,a4,80003536 <ialloc+0x74>
    800034e6:	8aaa                	mv	s5,a0
    800034e8:	8bae                	mv	s7,a1
    800034ea:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    800034ec:	00023a17          	auipc	s4,0x23
    800034f0:	2bca0a13          	addi	s4,s4,700 # 800267a8 <sb>
    800034f4:	00048b1b          	sext.w	s6,s1
    800034f8:	0044d593          	srli	a1,s1,0x4
    800034fc:	018a2783          	lw	a5,24(s4)
    80003500:	9dbd                	addw	a1,a1,a5
    80003502:	8556                	mv	a0,s5
    80003504:	00000097          	auipc	ra,0x0
    80003508:	954080e7          	jalr	-1708(ra) # 80002e58 <bread>
    8000350c:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    8000350e:	05850993          	addi	s3,a0,88
    80003512:	00f4f793          	andi	a5,s1,15
    80003516:	079a                	slli	a5,a5,0x6
    80003518:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    8000351a:	00099783          	lh	a5,0(s3)
    8000351e:	c785                	beqz	a5,80003546 <ialloc+0x84>
    brelse(bp);
    80003520:	00000097          	auipc	ra,0x0
    80003524:	a68080e7          	jalr	-1432(ra) # 80002f88 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003528:	0485                	addi	s1,s1,1
    8000352a:	00ca2703          	lw	a4,12(s4)
    8000352e:	0004879b          	sext.w	a5,s1
    80003532:	fce7e1e3          	bltu	a5,a4,800034f4 <ialloc+0x32>
  panic("ialloc: no inodes");
    80003536:	00005517          	auipc	a0,0x5
    8000353a:	08250513          	addi	a0,a0,130 # 800085b8 <syscalls+0x168>
    8000353e:	ffffd097          	auipc	ra,0xffffd
    80003542:	000080e7          	jalr	ra # 8000053e <panic>
      memset(dip, 0, sizeof(*dip));
    80003546:	04000613          	li	a2,64
    8000354a:	4581                	li	a1,0
    8000354c:	854e                	mv	a0,s3
    8000354e:	ffffd097          	auipc	ra,0xffffd
    80003552:	792080e7          	jalr	1938(ra) # 80000ce0 <memset>
      dip->type = type;
    80003556:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    8000355a:	854a                	mv	a0,s2
    8000355c:	00001097          	auipc	ra,0x1
    80003560:	ca8080e7          	jalr	-856(ra) # 80004204 <log_write>
      brelse(bp);
    80003564:	854a                	mv	a0,s2
    80003566:	00000097          	auipc	ra,0x0
    8000356a:	a22080e7          	jalr	-1502(ra) # 80002f88 <brelse>
      return iget(dev, inum);
    8000356e:	85da                	mv	a1,s6
    80003570:	8556                	mv	a0,s5
    80003572:	00000097          	auipc	ra,0x0
    80003576:	db4080e7          	jalr	-588(ra) # 80003326 <iget>
}
    8000357a:	60a6                	ld	ra,72(sp)
    8000357c:	6406                	ld	s0,64(sp)
    8000357e:	74e2                	ld	s1,56(sp)
    80003580:	7942                	ld	s2,48(sp)
    80003582:	79a2                	ld	s3,40(sp)
    80003584:	7a02                	ld	s4,32(sp)
    80003586:	6ae2                	ld	s5,24(sp)
    80003588:	6b42                	ld	s6,16(sp)
    8000358a:	6ba2                	ld	s7,8(sp)
    8000358c:	6161                	addi	sp,sp,80
    8000358e:	8082                	ret

0000000080003590 <iupdate>:
{
    80003590:	1101                	addi	sp,sp,-32
    80003592:	ec06                	sd	ra,24(sp)
    80003594:	e822                	sd	s0,16(sp)
    80003596:	e426                	sd	s1,8(sp)
    80003598:	e04a                	sd	s2,0(sp)
    8000359a:	1000                	addi	s0,sp,32
    8000359c:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    8000359e:	415c                	lw	a5,4(a0)
    800035a0:	0047d79b          	srliw	a5,a5,0x4
    800035a4:	00023597          	auipc	a1,0x23
    800035a8:	21c5a583          	lw	a1,540(a1) # 800267c0 <sb+0x18>
    800035ac:	9dbd                	addw	a1,a1,a5
    800035ae:	4108                	lw	a0,0(a0)
    800035b0:	00000097          	auipc	ra,0x0
    800035b4:	8a8080e7          	jalr	-1880(ra) # 80002e58 <bread>
    800035b8:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    800035ba:	05850793          	addi	a5,a0,88
    800035be:	40c8                	lw	a0,4(s1)
    800035c0:	893d                	andi	a0,a0,15
    800035c2:	051a                	slli	a0,a0,0x6
    800035c4:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    800035c6:	04449703          	lh	a4,68(s1)
    800035ca:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    800035ce:	04649703          	lh	a4,70(s1)
    800035d2:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    800035d6:	04849703          	lh	a4,72(s1)
    800035da:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    800035de:	04a49703          	lh	a4,74(s1)
    800035e2:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    800035e6:	44f8                	lw	a4,76(s1)
    800035e8:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    800035ea:	03400613          	li	a2,52
    800035ee:	05048593          	addi	a1,s1,80
    800035f2:	0531                	addi	a0,a0,12
    800035f4:	ffffd097          	auipc	ra,0xffffd
    800035f8:	74c080e7          	jalr	1868(ra) # 80000d40 <memmove>
  log_write(bp);
    800035fc:	854a                	mv	a0,s2
    800035fe:	00001097          	auipc	ra,0x1
    80003602:	c06080e7          	jalr	-1018(ra) # 80004204 <log_write>
  brelse(bp);
    80003606:	854a                	mv	a0,s2
    80003608:	00000097          	auipc	ra,0x0
    8000360c:	980080e7          	jalr	-1664(ra) # 80002f88 <brelse>
}
    80003610:	60e2                	ld	ra,24(sp)
    80003612:	6442                	ld	s0,16(sp)
    80003614:	64a2                	ld	s1,8(sp)
    80003616:	6902                	ld	s2,0(sp)
    80003618:	6105                	addi	sp,sp,32
    8000361a:	8082                	ret

000000008000361c <idup>:
{
    8000361c:	1101                	addi	sp,sp,-32
    8000361e:	ec06                	sd	ra,24(sp)
    80003620:	e822                	sd	s0,16(sp)
    80003622:	e426                	sd	s1,8(sp)
    80003624:	1000                	addi	s0,sp,32
    80003626:	84aa                	mv	s1,a0
	acquire(&itable.lock);
    80003628:	00023517          	auipc	a0,0x23
    8000362c:	1a050513          	addi	a0,a0,416 # 800267c8 <itable>
    80003630:	ffffd097          	auipc	ra,0xffffd
    80003634:	5b4080e7          	jalr	1460(ra) # 80000be4 <acquire>
	ip->ref++;
    80003638:	449c                	lw	a5,8(s1)
    8000363a:	2785                	addiw	a5,a5,1
    8000363c:	c49c                	sw	a5,8(s1)
	release(&itable.lock);
    8000363e:	00023517          	auipc	a0,0x23
    80003642:	18a50513          	addi	a0,a0,394 # 800267c8 <itable>
    80003646:	ffffd097          	auipc	ra,0xffffd
    8000364a:	652080e7          	jalr	1618(ra) # 80000c98 <release>
}
    8000364e:	8526                	mv	a0,s1
    80003650:	60e2                	ld	ra,24(sp)
    80003652:	6442                	ld	s0,16(sp)
    80003654:	64a2                	ld	s1,8(sp)
    80003656:	6105                	addi	sp,sp,32
    80003658:	8082                	ret

000000008000365a <ilock>:
{
    8000365a:	1101                	addi	sp,sp,-32
    8000365c:	ec06                	sd	ra,24(sp)
    8000365e:	e822                	sd	s0,16(sp)
    80003660:	e426                	sd	s1,8(sp)
    80003662:	e04a                	sd	s2,0(sp)
    80003664:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003666:	c115                	beqz	a0,8000368a <ilock+0x30>
    80003668:	84aa                	mv	s1,a0
    8000366a:	451c                	lw	a5,8(a0)
    8000366c:	00f05f63          	blez	a5,8000368a <ilock+0x30>
  acquiresleep(&ip->lock);
    80003670:	0541                	addi	a0,a0,16
    80003672:	00001097          	auipc	ra,0x1
    80003676:	cb2080e7          	jalr	-846(ra) # 80004324 <acquiresleep>
  if(ip->valid == 0){
    8000367a:	40bc                	lw	a5,64(s1)
    8000367c:	cf99                	beqz	a5,8000369a <ilock+0x40>
}
    8000367e:	60e2                	ld	ra,24(sp)
    80003680:	6442                	ld	s0,16(sp)
    80003682:	64a2                	ld	s1,8(sp)
    80003684:	6902                	ld	s2,0(sp)
    80003686:	6105                	addi	sp,sp,32
    80003688:	8082                	ret
    panic("ilock");
    8000368a:	00005517          	auipc	a0,0x5
    8000368e:	f4650513          	addi	a0,a0,-186 # 800085d0 <syscalls+0x180>
    80003692:	ffffd097          	auipc	ra,0xffffd
    80003696:	eac080e7          	jalr	-340(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    8000369a:	40dc                	lw	a5,4(s1)
    8000369c:	0047d79b          	srliw	a5,a5,0x4
    800036a0:	00023597          	auipc	a1,0x23
    800036a4:	1205a583          	lw	a1,288(a1) # 800267c0 <sb+0x18>
    800036a8:	9dbd                	addw	a1,a1,a5
    800036aa:	4088                	lw	a0,0(s1)
    800036ac:	fffff097          	auipc	ra,0xfffff
    800036b0:	7ac080e7          	jalr	1964(ra) # 80002e58 <bread>
    800036b4:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    800036b6:	05850593          	addi	a1,a0,88
    800036ba:	40dc                	lw	a5,4(s1)
    800036bc:	8bbd                	andi	a5,a5,15
    800036be:	079a                	slli	a5,a5,0x6
    800036c0:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    800036c2:	00059783          	lh	a5,0(a1)
    800036c6:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    800036ca:	00259783          	lh	a5,2(a1)
    800036ce:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    800036d2:	00459783          	lh	a5,4(a1)
    800036d6:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    800036da:	00659783          	lh	a5,6(a1)
    800036de:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    800036e2:	459c                	lw	a5,8(a1)
    800036e4:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    800036e6:	03400613          	li	a2,52
    800036ea:	05b1                	addi	a1,a1,12
    800036ec:	05048513          	addi	a0,s1,80
    800036f0:	ffffd097          	auipc	ra,0xffffd
    800036f4:	650080e7          	jalr	1616(ra) # 80000d40 <memmove>
    brelse(bp);
    800036f8:	854a                	mv	a0,s2
    800036fa:	00000097          	auipc	ra,0x0
    800036fe:	88e080e7          	jalr	-1906(ra) # 80002f88 <brelse>
    ip->valid = 1;
    80003702:	4785                	li	a5,1
    80003704:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003706:	04449783          	lh	a5,68(s1)
    8000370a:	fbb5                	bnez	a5,8000367e <ilock+0x24>
      panic("ilock: no type");
    8000370c:	00005517          	auipc	a0,0x5
    80003710:	ecc50513          	addi	a0,a0,-308 # 800085d8 <syscalls+0x188>
    80003714:	ffffd097          	auipc	ra,0xffffd
    80003718:	e2a080e7          	jalr	-470(ra) # 8000053e <panic>

000000008000371c <iunlock>:
{
    8000371c:	1101                	addi	sp,sp,-32
    8000371e:	ec06                	sd	ra,24(sp)
    80003720:	e822                	sd	s0,16(sp)
    80003722:	e426                	sd	s1,8(sp)
    80003724:	e04a                	sd	s2,0(sp)
    80003726:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003728:	c905                	beqz	a0,80003758 <iunlock+0x3c>
    8000372a:	84aa                	mv	s1,a0
    8000372c:	01050913          	addi	s2,a0,16
    80003730:	854a                	mv	a0,s2
    80003732:	00001097          	auipc	ra,0x1
    80003736:	c8c080e7          	jalr	-884(ra) # 800043be <holdingsleep>
    8000373a:	cd19                	beqz	a0,80003758 <iunlock+0x3c>
    8000373c:	449c                	lw	a5,8(s1)
    8000373e:	00f05d63          	blez	a5,80003758 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003742:	854a                	mv	a0,s2
    80003744:	00001097          	auipc	ra,0x1
    80003748:	c36080e7          	jalr	-970(ra) # 8000437a <releasesleep>
}
    8000374c:	60e2                	ld	ra,24(sp)
    8000374e:	6442                	ld	s0,16(sp)
    80003750:	64a2                	ld	s1,8(sp)
    80003752:	6902                	ld	s2,0(sp)
    80003754:	6105                	addi	sp,sp,32
    80003756:	8082                	ret
    panic("iunlock");
    80003758:	00005517          	auipc	a0,0x5
    8000375c:	e9050513          	addi	a0,a0,-368 # 800085e8 <syscalls+0x198>
    80003760:	ffffd097          	auipc	ra,0xffffd
    80003764:	dde080e7          	jalr	-546(ra) # 8000053e <panic>

0000000080003768 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003768:	7179                	addi	sp,sp,-48
    8000376a:	f406                	sd	ra,40(sp)
    8000376c:	f022                	sd	s0,32(sp)
    8000376e:	ec26                	sd	s1,24(sp)
    80003770:	e84a                	sd	s2,16(sp)
    80003772:	e44e                	sd	s3,8(sp)
    80003774:	e052                	sd	s4,0(sp)
    80003776:	1800                	addi	s0,sp,48
    80003778:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    8000377a:	05050493          	addi	s1,a0,80
    8000377e:	08050913          	addi	s2,a0,128
    80003782:	a021                	j	8000378a <itrunc+0x22>
    80003784:	0491                	addi	s1,s1,4
    80003786:	01248d63          	beq	s1,s2,800037a0 <itrunc+0x38>
    if(ip->addrs[i]){
    8000378a:	408c                	lw	a1,0(s1)
    8000378c:	dde5                	beqz	a1,80003784 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    8000378e:	0009a503          	lw	a0,0(s3)
    80003792:	00000097          	auipc	ra,0x0
    80003796:	90c080e7          	jalr	-1780(ra) # 8000309e <bfree>
      ip->addrs[i] = 0;
    8000379a:	0004a023          	sw	zero,0(s1)
    8000379e:	b7dd                	j	80003784 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    800037a0:	0809a583          	lw	a1,128(s3)
    800037a4:	e185                	bnez	a1,800037c4 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    800037a6:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    800037aa:	854e                	mv	a0,s3
    800037ac:	00000097          	auipc	ra,0x0
    800037b0:	de4080e7          	jalr	-540(ra) # 80003590 <iupdate>
}
    800037b4:	70a2                	ld	ra,40(sp)
    800037b6:	7402                	ld	s0,32(sp)
    800037b8:	64e2                	ld	s1,24(sp)
    800037ba:	6942                	ld	s2,16(sp)
    800037bc:	69a2                	ld	s3,8(sp)
    800037be:	6a02                	ld	s4,0(sp)
    800037c0:	6145                	addi	sp,sp,48
    800037c2:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    800037c4:	0009a503          	lw	a0,0(s3)
    800037c8:	fffff097          	auipc	ra,0xfffff
    800037cc:	690080e7          	jalr	1680(ra) # 80002e58 <bread>
    800037d0:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    800037d2:	05850493          	addi	s1,a0,88
    800037d6:	45850913          	addi	s2,a0,1112
    800037da:	a811                	j	800037ee <itrunc+0x86>
        bfree(ip->dev, a[j]);
    800037dc:	0009a503          	lw	a0,0(s3)
    800037e0:	00000097          	auipc	ra,0x0
    800037e4:	8be080e7          	jalr	-1858(ra) # 8000309e <bfree>
    for(j = 0; j < NINDIRECT; j++){
    800037e8:	0491                	addi	s1,s1,4
    800037ea:	01248563          	beq	s1,s2,800037f4 <itrunc+0x8c>
      if(a[j])
    800037ee:	408c                	lw	a1,0(s1)
    800037f0:	dde5                	beqz	a1,800037e8 <itrunc+0x80>
    800037f2:	b7ed                	j	800037dc <itrunc+0x74>
    brelse(bp);
    800037f4:	8552                	mv	a0,s4
    800037f6:	fffff097          	auipc	ra,0xfffff
    800037fa:	792080e7          	jalr	1938(ra) # 80002f88 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    800037fe:	0809a583          	lw	a1,128(s3)
    80003802:	0009a503          	lw	a0,0(s3)
    80003806:	00000097          	auipc	ra,0x0
    8000380a:	898080e7          	jalr	-1896(ra) # 8000309e <bfree>
    ip->addrs[NDIRECT] = 0;
    8000380e:	0809a023          	sw	zero,128(s3)
    80003812:	bf51                	j	800037a6 <itrunc+0x3e>

0000000080003814 <iput>:
{
    80003814:	1101                	addi	sp,sp,-32
    80003816:	ec06                	sd	ra,24(sp)
    80003818:	e822                	sd	s0,16(sp)
    8000381a:	e426                	sd	s1,8(sp)
    8000381c:	e04a                	sd	s2,0(sp)
    8000381e:	1000                	addi	s0,sp,32
    80003820:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003822:	00023517          	auipc	a0,0x23
    80003826:	fa650513          	addi	a0,a0,-90 # 800267c8 <itable>
    8000382a:	ffffd097          	auipc	ra,0xffffd
    8000382e:	3ba080e7          	jalr	954(ra) # 80000be4 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003832:	4498                	lw	a4,8(s1)
    80003834:	4785                	li	a5,1
    80003836:	02f70363          	beq	a4,a5,8000385c <iput+0x48>
  ip->ref--;
    8000383a:	449c                	lw	a5,8(s1)
    8000383c:	37fd                	addiw	a5,a5,-1
    8000383e:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003840:	00023517          	auipc	a0,0x23
    80003844:	f8850513          	addi	a0,a0,-120 # 800267c8 <itable>
    80003848:	ffffd097          	auipc	ra,0xffffd
    8000384c:	450080e7          	jalr	1104(ra) # 80000c98 <release>
}
    80003850:	60e2                	ld	ra,24(sp)
    80003852:	6442                	ld	s0,16(sp)
    80003854:	64a2                	ld	s1,8(sp)
    80003856:	6902                	ld	s2,0(sp)
    80003858:	6105                	addi	sp,sp,32
    8000385a:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    8000385c:	40bc                	lw	a5,64(s1)
    8000385e:	dff1                	beqz	a5,8000383a <iput+0x26>
    80003860:	04a49783          	lh	a5,74(s1)
    80003864:	fbf9                	bnez	a5,8000383a <iput+0x26>
    acquiresleep(&ip->lock);
    80003866:	01048913          	addi	s2,s1,16
    8000386a:	854a                	mv	a0,s2
    8000386c:	00001097          	auipc	ra,0x1
    80003870:	ab8080e7          	jalr	-1352(ra) # 80004324 <acquiresleep>
    release(&itable.lock);
    80003874:	00023517          	auipc	a0,0x23
    80003878:	f5450513          	addi	a0,a0,-172 # 800267c8 <itable>
    8000387c:	ffffd097          	auipc	ra,0xffffd
    80003880:	41c080e7          	jalr	1052(ra) # 80000c98 <release>
    itrunc(ip);
    80003884:	8526                	mv	a0,s1
    80003886:	00000097          	auipc	ra,0x0
    8000388a:	ee2080e7          	jalr	-286(ra) # 80003768 <itrunc>
    ip->type = 0;
    8000388e:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003892:	8526                	mv	a0,s1
    80003894:	00000097          	auipc	ra,0x0
    80003898:	cfc080e7          	jalr	-772(ra) # 80003590 <iupdate>
    ip->valid = 0;
    8000389c:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    800038a0:	854a                	mv	a0,s2
    800038a2:	00001097          	auipc	ra,0x1
    800038a6:	ad8080e7          	jalr	-1320(ra) # 8000437a <releasesleep>
    acquire(&itable.lock);
    800038aa:	00023517          	auipc	a0,0x23
    800038ae:	f1e50513          	addi	a0,a0,-226 # 800267c8 <itable>
    800038b2:	ffffd097          	auipc	ra,0xffffd
    800038b6:	332080e7          	jalr	818(ra) # 80000be4 <acquire>
    800038ba:	b741                	j	8000383a <iput+0x26>

00000000800038bc <iunlockput>:
{
    800038bc:	1101                	addi	sp,sp,-32
    800038be:	ec06                	sd	ra,24(sp)
    800038c0:	e822                	sd	s0,16(sp)
    800038c2:	e426                	sd	s1,8(sp)
    800038c4:	1000                	addi	s0,sp,32
    800038c6:	84aa                	mv	s1,a0
	iunlock(ip);
    800038c8:	00000097          	auipc	ra,0x0
    800038cc:	e54080e7          	jalr	-428(ra) # 8000371c <iunlock>
	iput(ip);
    800038d0:	8526                	mv	a0,s1
    800038d2:	00000097          	auipc	ra,0x0
    800038d6:	f42080e7          	jalr	-190(ra) # 80003814 <iput>
}
    800038da:	60e2                	ld	ra,24(sp)
    800038dc:	6442                	ld	s0,16(sp)
    800038de:	64a2                	ld	s1,8(sp)
    800038e0:	6105                	addi	sp,sp,32
    800038e2:	8082                	ret

00000000800038e4 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    800038e4:	1141                	addi	sp,sp,-16
    800038e6:	e422                	sd	s0,8(sp)
    800038e8:	0800                	addi	s0,sp,16
	st->dev = ip->dev;
    800038ea:	411c                	lw	a5,0(a0)
    800038ec:	c19c                	sw	a5,0(a1)
	st->ino = ip->inum;
    800038ee:	415c                	lw	a5,4(a0)
    800038f0:	c1dc                	sw	a5,4(a1)
	st->type = ip->type;
    800038f2:	04451783          	lh	a5,68(a0)
    800038f6:	00f59423          	sh	a5,8(a1)
	st->nlink = ip->nlink;
    800038fa:	04a51783          	lh	a5,74(a0)
    800038fe:	00f59523          	sh	a5,10(a1)
	st->size = ip->size;
    80003902:	04c56783          	lwu	a5,76(a0)
    80003906:	e99c                	sd	a5,16(a1)
}
    80003908:	6422                	ld	s0,8(sp)
    8000390a:	0141                	addi	sp,sp,16
    8000390c:	8082                	ret

000000008000390e <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    8000390e:	457c                	lw	a5,76(a0)
    80003910:	0ed7e963          	bltu	a5,a3,80003a02 <readi+0xf4>
{
    80003914:	7159                	addi	sp,sp,-112
    80003916:	f486                	sd	ra,104(sp)
    80003918:	f0a2                	sd	s0,96(sp)
    8000391a:	eca6                	sd	s1,88(sp)
    8000391c:	e8ca                	sd	s2,80(sp)
    8000391e:	e4ce                	sd	s3,72(sp)
    80003920:	e0d2                	sd	s4,64(sp)
    80003922:	fc56                	sd	s5,56(sp)
    80003924:	f85a                	sd	s6,48(sp)
    80003926:	f45e                	sd	s7,40(sp)
    80003928:	f062                	sd	s8,32(sp)
    8000392a:	ec66                	sd	s9,24(sp)
    8000392c:	e86a                	sd	s10,16(sp)
    8000392e:	e46e                	sd	s11,8(sp)
    80003930:	1880                	addi	s0,sp,112
    80003932:	8baa                	mv	s7,a0
    80003934:	8c2e                	mv	s8,a1
    80003936:	8ab2                	mv	s5,a2
    80003938:	84b6                	mv	s1,a3
    8000393a:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    8000393c:	9f35                	addw	a4,a4,a3
    return 0;
    8000393e:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003940:	0ad76063          	bltu	a4,a3,800039e0 <readi+0xd2>
  if(off + n > ip->size)
    80003944:	00e7f463          	bgeu	a5,a4,8000394c <readi+0x3e>
    n = ip->size - off;
    80003948:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    8000394c:	0a0b0963          	beqz	s6,800039fe <readi+0xf0>
    80003950:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003952:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003956:	5cfd                	li	s9,-1
    80003958:	a82d                	j	80003992 <readi+0x84>
    8000395a:	020a1d93          	slli	s11,s4,0x20
    8000395e:	020ddd93          	srli	s11,s11,0x20
    80003962:	05890613          	addi	a2,s2,88
    80003966:	86ee                	mv	a3,s11
    80003968:	963a                	add	a2,a2,a4
    8000396a:	85d6                	mv	a1,s5
    8000396c:	8562                	mv	a0,s8
    8000396e:	fffff097          	auipc	ra,0xfffff
    80003972:	b2e080e7          	jalr	-1234(ra) # 8000249c <either_copyout>
    80003976:	05950d63          	beq	a0,s9,800039d0 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    8000397a:	854a                	mv	a0,s2
    8000397c:	fffff097          	auipc	ra,0xfffff
    80003980:	60c080e7          	jalr	1548(ra) # 80002f88 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003984:	013a09bb          	addw	s3,s4,s3
    80003988:	009a04bb          	addw	s1,s4,s1
    8000398c:	9aee                	add	s5,s5,s11
    8000398e:	0569f763          	bgeu	s3,s6,800039dc <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003992:	000ba903          	lw	s2,0(s7)
    80003996:	00a4d59b          	srliw	a1,s1,0xa
    8000399a:	855e                	mv	a0,s7
    8000399c:	00000097          	auipc	ra,0x0
    800039a0:	8b0080e7          	jalr	-1872(ra) # 8000324c <bmap>
    800039a4:	0005059b          	sext.w	a1,a0
    800039a8:	854a                	mv	a0,s2
    800039aa:	fffff097          	auipc	ra,0xfffff
    800039ae:	4ae080e7          	jalr	1198(ra) # 80002e58 <bread>
    800039b2:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    800039b4:	3ff4f713          	andi	a4,s1,1023
    800039b8:	40ed07bb          	subw	a5,s10,a4
    800039bc:	413b06bb          	subw	a3,s6,s3
    800039c0:	8a3e                	mv	s4,a5
    800039c2:	2781                	sext.w	a5,a5
    800039c4:	0006861b          	sext.w	a2,a3
    800039c8:	f8f679e3          	bgeu	a2,a5,8000395a <readi+0x4c>
    800039cc:	8a36                	mv	s4,a3
    800039ce:	b771                	j	8000395a <readi+0x4c>
      brelse(bp);
    800039d0:	854a                	mv	a0,s2
    800039d2:	fffff097          	auipc	ra,0xfffff
    800039d6:	5b6080e7          	jalr	1462(ra) # 80002f88 <brelse>
      tot = -1;
    800039da:	59fd                	li	s3,-1
  }
  return tot;
    800039dc:	0009851b          	sext.w	a0,s3
}
    800039e0:	70a6                	ld	ra,104(sp)
    800039e2:	7406                	ld	s0,96(sp)
    800039e4:	64e6                	ld	s1,88(sp)
    800039e6:	6946                	ld	s2,80(sp)
    800039e8:	69a6                	ld	s3,72(sp)
    800039ea:	6a06                	ld	s4,64(sp)
    800039ec:	7ae2                	ld	s5,56(sp)
    800039ee:	7b42                	ld	s6,48(sp)
    800039f0:	7ba2                	ld	s7,40(sp)
    800039f2:	7c02                	ld	s8,32(sp)
    800039f4:	6ce2                	ld	s9,24(sp)
    800039f6:	6d42                	ld	s10,16(sp)
    800039f8:	6da2                	ld	s11,8(sp)
    800039fa:	6165                	addi	sp,sp,112
    800039fc:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800039fe:	89da                	mv	s3,s6
    80003a00:	bff1                	j	800039dc <readi+0xce>
    return 0;
    80003a02:	4501                	li	a0,0
}
    80003a04:	8082                	ret

0000000080003a06 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003a06:	457c                	lw	a5,76(a0)
    80003a08:	10d7e863          	bltu	a5,a3,80003b18 <writei+0x112>
{
    80003a0c:	7159                	addi	sp,sp,-112
    80003a0e:	f486                	sd	ra,104(sp)
    80003a10:	f0a2                	sd	s0,96(sp)
    80003a12:	eca6                	sd	s1,88(sp)
    80003a14:	e8ca                	sd	s2,80(sp)
    80003a16:	e4ce                	sd	s3,72(sp)
    80003a18:	e0d2                	sd	s4,64(sp)
    80003a1a:	fc56                	sd	s5,56(sp)
    80003a1c:	f85a                	sd	s6,48(sp)
    80003a1e:	f45e                	sd	s7,40(sp)
    80003a20:	f062                	sd	s8,32(sp)
    80003a22:	ec66                	sd	s9,24(sp)
    80003a24:	e86a                	sd	s10,16(sp)
    80003a26:	e46e                	sd	s11,8(sp)
    80003a28:	1880                	addi	s0,sp,112
    80003a2a:	8b2a                	mv	s6,a0
    80003a2c:	8c2e                	mv	s8,a1
    80003a2e:	8ab2                	mv	s5,a2
    80003a30:	8936                	mv	s2,a3
    80003a32:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    80003a34:	00e687bb          	addw	a5,a3,a4
    80003a38:	0ed7e263          	bltu	a5,a3,80003b1c <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003a3c:	00043737          	lui	a4,0x43
    80003a40:	0ef76063          	bltu	a4,a5,80003b20 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003a44:	0c0b8863          	beqz	s7,80003b14 <writei+0x10e>
    80003a48:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003a4a:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003a4e:	5cfd                	li	s9,-1
    80003a50:	a091                	j	80003a94 <writei+0x8e>
    80003a52:	02099d93          	slli	s11,s3,0x20
    80003a56:	020ddd93          	srli	s11,s11,0x20
    80003a5a:	05848513          	addi	a0,s1,88
    80003a5e:	86ee                	mv	a3,s11
    80003a60:	8656                	mv	a2,s5
    80003a62:	85e2                	mv	a1,s8
    80003a64:	953a                	add	a0,a0,a4
    80003a66:	fffff097          	auipc	ra,0xfffff
    80003a6a:	a8c080e7          	jalr	-1396(ra) # 800024f2 <either_copyin>
    80003a6e:	07950263          	beq	a0,s9,80003ad2 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003a72:	8526                	mv	a0,s1
    80003a74:	00000097          	auipc	ra,0x0
    80003a78:	790080e7          	jalr	1936(ra) # 80004204 <log_write>
    brelse(bp);
    80003a7c:	8526                	mv	a0,s1
    80003a7e:	fffff097          	auipc	ra,0xfffff
    80003a82:	50a080e7          	jalr	1290(ra) # 80002f88 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003a86:	01498a3b          	addw	s4,s3,s4
    80003a8a:	0129893b          	addw	s2,s3,s2
    80003a8e:	9aee                	add	s5,s5,s11
    80003a90:	057a7663          	bgeu	s4,s7,80003adc <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003a94:	000b2483          	lw	s1,0(s6)
    80003a98:	00a9559b          	srliw	a1,s2,0xa
    80003a9c:	855a                	mv	a0,s6
    80003a9e:	fffff097          	auipc	ra,0xfffff
    80003aa2:	7ae080e7          	jalr	1966(ra) # 8000324c <bmap>
    80003aa6:	0005059b          	sext.w	a1,a0
    80003aaa:	8526                	mv	a0,s1
    80003aac:	fffff097          	auipc	ra,0xfffff
    80003ab0:	3ac080e7          	jalr	940(ra) # 80002e58 <bread>
    80003ab4:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003ab6:	3ff97713          	andi	a4,s2,1023
    80003aba:	40ed07bb          	subw	a5,s10,a4
    80003abe:	414b86bb          	subw	a3,s7,s4
    80003ac2:	89be                	mv	s3,a5
    80003ac4:	2781                	sext.w	a5,a5
    80003ac6:	0006861b          	sext.w	a2,a3
    80003aca:	f8f674e3          	bgeu	a2,a5,80003a52 <writei+0x4c>
    80003ace:	89b6                	mv	s3,a3
    80003ad0:	b749                	j	80003a52 <writei+0x4c>
      brelse(bp);
    80003ad2:	8526                	mv	a0,s1
    80003ad4:	fffff097          	auipc	ra,0xfffff
    80003ad8:	4b4080e7          	jalr	1204(ra) # 80002f88 <brelse>
  }

  if(off > ip->size)
    80003adc:	04cb2783          	lw	a5,76(s6)
    80003ae0:	0127f463          	bgeu	a5,s2,80003ae8 <writei+0xe2>
    ip->size = off;
    80003ae4:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003ae8:	855a                	mv	a0,s6
    80003aea:	00000097          	auipc	ra,0x0
    80003aee:	aa6080e7          	jalr	-1370(ra) # 80003590 <iupdate>

  return tot;
    80003af2:	000a051b          	sext.w	a0,s4
}
    80003af6:	70a6                	ld	ra,104(sp)
    80003af8:	7406                	ld	s0,96(sp)
    80003afa:	64e6                	ld	s1,88(sp)
    80003afc:	6946                	ld	s2,80(sp)
    80003afe:	69a6                	ld	s3,72(sp)
    80003b00:	6a06                	ld	s4,64(sp)
    80003b02:	7ae2                	ld	s5,56(sp)
    80003b04:	7b42                	ld	s6,48(sp)
    80003b06:	7ba2                	ld	s7,40(sp)
    80003b08:	7c02                	ld	s8,32(sp)
    80003b0a:	6ce2                	ld	s9,24(sp)
    80003b0c:	6d42                	ld	s10,16(sp)
    80003b0e:	6da2                	ld	s11,8(sp)
    80003b10:	6165                	addi	sp,sp,112
    80003b12:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003b14:	8a5e                	mv	s4,s7
    80003b16:	bfc9                	j	80003ae8 <writei+0xe2>
    return -1;
    80003b18:	557d                	li	a0,-1
}
    80003b1a:	8082                	ret
    return -1;
    80003b1c:	557d                	li	a0,-1
    80003b1e:	bfe1                	j	80003af6 <writei+0xf0>
    return -1;
    80003b20:	557d                	li	a0,-1
    80003b22:	bfd1                	j	80003af6 <writei+0xf0>

0000000080003b24 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003b24:	1141                	addi	sp,sp,-16
    80003b26:	e406                	sd	ra,8(sp)
    80003b28:	e022                	sd	s0,0(sp)
    80003b2a:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003b2c:	4639                	li	a2,14
    80003b2e:	ffffd097          	auipc	ra,0xffffd
    80003b32:	28a080e7          	jalr	650(ra) # 80000db8 <strncmp>
}
    80003b36:	60a2                	ld	ra,8(sp)
    80003b38:	6402                	ld	s0,0(sp)
    80003b3a:	0141                	addi	sp,sp,16
    80003b3c:	8082                	ret

0000000080003b3e <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003b3e:	7139                	addi	sp,sp,-64
    80003b40:	fc06                	sd	ra,56(sp)
    80003b42:	f822                	sd	s0,48(sp)
    80003b44:	f426                	sd	s1,40(sp)
    80003b46:	f04a                	sd	s2,32(sp)
    80003b48:	ec4e                	sd	s3,24(sp)
    80003b4a:	e852                	sd	s4,16(sp)
    80003b4c:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003b4e:	04451703          	lh	a4,68(a0)
    80003b52:	4785                	li	a5,1
    80003b54:	00f71a63          	bne	a4,a5,80003b68 <dirlookup+0x2a>
    80003b58:	892a                	mv	s2,a0
    80003b5a:	89ae                	mv	s3,a1
    80003b5c:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003b5e:	457c                	lw	a5,76(a0)
    80003b60:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003b62:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003b64:	e79d                	bnez	a5,80003b92 <dirlookup+0x54>
    80003b66:	a8a5                	j	80003bde <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003b68:	00005517          	auipc	a0,0x5
    80003b6c:	a8850513          	addi	a0,a0,-1400 # 800085f0 <syscalls+0x1a0>
    80003b70:	ffffd097          	auipc	ra,0xffffd
    80003b74:	9ce080e7          	jalr	-1586(ra) # 8000053e <panic>
      panic("dirlookup read");
    80003b78:	00005517          	auipc	a0,0x5
    80003b7c:	a9050513          	addi	a0,a0,-1392 # 80008608 <syscalls+0x1b8>
    80003b80:	ffffd097          	auipc	ra,0xffffd
    80003b84:	9be080e7          	jalr	-1602(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003b88:	24c1                	addiw	s1,s1,16
    80003b8a:	04c92783          	lw	a5,76(s2)
    80003b8e:	04f4f763          	bgeu	s1,a5,80003bdc <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003b92:	4741                	li	a4,16
    80003b94:	86a6                	mv	a3,s1
    80003b96:	fc040613          	addi	a2,s0,-64
    80003b9a:	4581                	li	a1,0
    80003b9c:	854a                	mv	a0,s2
    80003b9e:	00000097          	auipc	ra,0x0
    80003ba2:	d70080e7          	jalr	-656(ra) # 8000390e <readi>
    80003ba6:	47c1                	li	a5,16
    80003ba8:	fcf518e3          	bne	a0,a5,80003b78 <dirlookup+0x3a>
    if(de.inum == 0)
    80003bac:	fc045783          	lhu	a5,-64(s0)
    80003bb0:	dfe1                	beqz	a5,80003b88 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003bb2:	fc240593          	addi	a1,s0,-62
    80003bb6:	854e                	mv	a0,s3
    80003bb8:	00000097          	auipc	ra,0x0
    80003bbc:	f6c080e7          	jalr	-148(ra) # 80003b24 <namecmp>
    80003bc0:	f561                	bnez	a0,80003b88 <dirlookup+0x4a>
      if(poff)
    80003bc2:	000a0463          	beqz	s4,80003bca <dirlookup+0x8c>
        *poff = off;
    80003bc6:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003bca:	fc045583          	lhu	a1,-64(s0)
    80003bce:	00092503          	lw	a0,0(s2)
    80003bd2:	fffff097          	auipc	ra,0xfffff
    80003bd6:	754080e7          	jalr	1876(ra) # 80003326 <iget>
    80003bda:	a011                	j	80003bde <dirlookup+0xa0>
  return 0;
    80003bdc:	4501                	li	a0,0
}
    80003bde:	70e2                	ld	ra,56(sp)
    80003be0:	7442                	ld	s0,48(sp)
    80003be2:	74a2                	ld	s1,40(sp)
    80003be4:	7902                	ld	s2,32(sp)
    80003be6:	69e2                	ld	s3,24(sp)
    80003be8:	6a42                	ld	s4,16(sp)
    80003bea:	6121                	addi	sp,sp,64
    80003bec:	8082                	ret

0000000080003bee <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003bee:	711d                	addi	sp,sp,-96
    80003bf0:	ec86                	sd	ra,88(sp)
    80003bf2:	e8a2                	sd	s0,80(sp)
    80003bf4:	e4a6                	sd	s1,72(sp)
    80003bf6:	e0ca                	sd	s2,64(sp)
    80003bf8:	fc4e                	sd	s3,56(sp)
    80003bfa:	f852                	sd	s4,48(sp)
    80003bfc:	f456                	sd	s5,40(sp)
    80003bfe:	f05a                	sd	s6,32(sp)
    80003c00:	ec5e                	sd	s7,24(sp)
    80003c02:	e862                	sd	s8,16(sp)
    80003c04:	e466                	sd	s9,8(sp)
    80003c06:	1080                	addi	s0,sp,96
    80003c08:	84aa                	mv	s1,a0
    80003c0a:	8b2e                	mv	s6,a1
    80003c0c:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003c0e:	00054703          	lbu	a4,0(a0)
    80003c12:	02f00793          	li	a5,47
    80003c16:	02f70363          	beq	a4,a5,80003c3c <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003c1a:	ffffe097          	auipc	ra,0xffffe
    80003c1e:	e22080e7          	jalr	-478(ra) # 80001a3c <myproc>
    80003c22:	15053503          	ld	a0,336(a0)
    80003c26:	00000097          	auipc	ra,0x0
    80003c2a:	9f6080e7          	jalr	-1546(ra) # 8000361c <idup>
    80003c2e:	89aa                	mv	s3,a0
  while(*path == '/')
    80003c30:	02f00913          	li	s2,47
  len = path - s;
    80003c34:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80003c36:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003c38:	4c05                	li	s8,1
    80003c3a:	a865                	j	80003cf2 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003c3c:	4585                	li	a1,1
    80003c3e:	4505                	li	a0,1
    80003c40:	fffff097          	auipc	ra,0xfffff
    80003c44:	6e6080e7          	jalr	1766(ra) # 80003326 <iget>
    80003c48:	89aa                	mv	s3,a0
    80003c4a:	b7dd                	j	80003c30 <namex+0x42>
      iunlockput(ip);
    80003c4c:	854e                	mv	a0,s3
    80003c4e:	00000097          	auipc	ra,0x0
    80003c52:	c6e080e7          	jalr	-914(ra) # 800038bc <iunlockput>
      return 0;
    80003c56:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003c58:	854e                	mv	a0,s3
    80003c5a:	60e6                	ld	ra,88(sp)
    80003c5c:	6446                	ld	s0,80(sp)
    80003c5e:	64a6                	ld	s1,72(sp)
    80003c60:	6906                	ld	s2,64(sp)
    80003c62:	79e2                	ld	s3,56(sp)
    80003c64:	7a42                	ld	s4,48(sp)
    80003c66:	7aa2                	ld	s5,40(sp)
    80003c68:	7b02                	ld	s6,32(sp)
    80003c6a:	6be2                	ld	s7,24(sp)
    80003c6c:	6c42                	ld	s8,16(sp)
    80003c6e:	6ca2                	ld	s9,8(sp)
    80003c70:	6125                	addi	sp,sp,96
    80003c72:	8082                	ret
      iunlock(ip);
    80003c74:	854e                	mv	a0,s3
    80003c76:	00000097          	auipc	ra,0x0
    80003c7a:	aa6080e7          	jalr	-1370(ra) # 8000371c <iunlock>
      return ip;
    80003c7e:	bfe9                	j	80003c58 <namex+0x6a>
      iunlockput(ip);
    80003c80:	854e                	mv	a0,s3
    80003c82:	00000097          	auipc	ra,0x0
    80003c86:	c3a080e7          	jalr	-966(ra) # 800038bc <iunlockput>
      return 0;
    80003c8a:	89d2                	mv	s3,s4
    80003c8c:	b7f1                	j	80003c58 <namex+0x6a>
  len = path - s;
    80003c8e:	40b48633          	sub	a2,s1,a1
    80003c92:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80003c96:	094cd463          	bge	s9,s4,80003d1e <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003c9a:	4639                	li	a2,14
    80003c9c:	8556                	mv	a0,s5
    80003c9e:	ffffd097          	auipc	ra,0xffffd
    80003ca2:	0a2080e7          	jalr	162(ra) # 80000d40 <memmove>
  while(*path == '/')
    80003ca6:	0004c783          	lbu	a5,0(s1)
    80003caa:	01279763          	bne	a5,s2,80003cb8 <namex+0xca>
    path++;
    80003cae:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003cb0:	0004c783          	lbu	a5,0(s1)
    80003cb4:	ff278de3          	beq	a5,s2,80003cae <namex+0xc0>
    ilock(ip);
    80003cb8:	854e                	mv	a0,s3
    80003cba:	00000097          	auipc	ra,0x0
    80003cbe:	9a0080e7          	jalr	-1632(ra) # 8000365a <ilock>
    if(ip->type != T_DIR){
    80003cc2:	04499783          	lh	a5,68(s3)
    80003cc6:	f98793e3          	bne	a5,s8,80003c4c <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003cca:	000b0563          	beqz	s6,80003cd4 <namex+0xe6>
    80003cce:	0004c783          	lbu	a5,0(s1)
    80003cd2:	d3cd                	beqz	a5,80003c74 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003cd4:	865e                	mv	a2,s7
    80003cd6:	85d6                	mv	a1,s5
    80003cd8:	854e                	mv	a0,s3
    80003cda:	00000097          	auipc	ra,0x0
    80003cde:	e64080e7          	jalr	-412(ra) # 80003b3e <dirlookup>
    80003ce2:	8a2a                	mv	s4,a0
    80003ce4:	dd51                	beqz	a0,80003c80 <namex+0x92>
    iunlockput(ip);
    80003ce6:	854e                	mv	a0,s3
    80003ce8:	00000097          	auipc	ra,0x0
    80003cec:	bd4080e7          	jalr	-1068(ra) # 800038bc <iunlockput>
    ip = next;
    80003cf0:	89d2                	mv	s3,s4
  while(*path == '/')
    80003cf2:	0004c783          	lbu	a5,0(s1)
    80003cf6:	05279763          	bne	a5,s2,80003d44 <namex+0x156>
    path++;
    80003cfa:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003cfc:	0004c783          	lbu	a5,0(s1)
    80003d00:	ff278de3          	beq	a5,s2,80003cfa <namex+0x10c>
  if(*path == 0)
    80003d04:	c79d                	beqz	a5,80003d32 <namex+0x144>
    path++;
    80003d06:	85a6                	mv	a1,s1
  len = path - s;
    80003d08:	8a5e                	mv	s4,s7
    80003d0a:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80003d0c:	01278963          	beq	a5,s2,80003d1e <namex+0x130>
    80003d10:	dfbd                	beqz	a5,80003c8e <namex+0xa0>
    path++;
    80003d12:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003d14:	0004c783          	lbu	a5,0(s1)
    80003d18:	ff279ce3          	bne	a5,s2,80003d10 <namex+0x122>
    80003d1c:	bf8d                	j	80003c8e <namex+0xa0>
    memmove(name, s, len);
    80003d1e:	2601                	sext.w	a2,a2
    80003d20:	8556                	mv	a0,s5
    80003d22:	ffffd097          	auipc	ra,0xffffd
    80003d26:	01e080e7          	jalr	30(ra) # 80000d40 <memmove>
    name[len] = 0;
    80003d2a:	9a56                	add	s4,s4,s5
    80003d2c:	000a0023          	sb	zero,0(s4)
    80003d30:	bf9d                	j	80003ca6 <namex+0xb8>
  if(nameiparent){
    80003d32:	f20b03e3          	beqz	s6,80003c58 <namex+0x6a>
    iput(ip);
    80003d36:	854e                	mv	a0,s3
    80003d38:	00000097          	auipc	ra,0x0
    80003d3c:	adc080e7          	jalr	-1316(ra) # 80003814 <iput>
    return 0;
    80003d40:	4981                	li	s3,0
    80003d42:	bf19                	j	80003c58 <namex+0x6a>
  if(*path == 0)
    80003d44:	d7fd                	beqz	a5,80003d32 <namex+0x144>
  while(*path != '/' && *path != 0)
    80003d46:	0004c783          	lbu	a5,0(s1)
    80003d4a:	85a6                	mv	a1,s1
    80003d4c:	b7d1                	j	80003d10 <namex+0x122>

0000000080003d4e <dirlink>:
{
    80003d4e:	7139                	addi	sp,sp,-64
    80003d50:	fc06                	sd	ra,56(sp)
    80003d52:	f822                	sd	s0,48(sp)
    80003d54:	f426                	sd	s1,40(sp)
    80003d56:	f04a                	sd	s2,32(sp)
    80003d58:	ec4e                	sd	s3,24(sp)
    80003d5a:	e852                	sd	s4,16(sp)
    80003d5c:	0080                	addi	s0,sp,64
    80003d5e:	892a                	mv	s2,a0
    80003d60:	8a2e                	mv	s4,a1
    80003d62:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003d64:	4601                	li	a2,0
    80003d66:	00000097          	auipc	ra,0x0
    80003d6a:	dd8080e7          	jalr	-552(ra) # 80003b3e <dirlookup>
    80003d6e:	e93d                	bnez	a0,80003de4 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d70:	04c92483          	lw	s1,76(s2)
    80003d74:	c49d                	beqz	s1,80003da2 <dirlink+0x54>
    80003d76:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003d78:	4741                	li	a4,16
    80003d7a:	86a6                	mv	a3,s1
    80003d7c:	fc040613          	addi	a2,s0,-64
    80003d80:	4581                	li	a1,0
    80003d82:	854a                	mv	a0,s2
    80003d84:	00000097          	auipc	ra,0x0
    80003d88:	b8a080e7          	jalr	-1142(ra) # 8000390e <readi>
    80003d8c:	47c1                	li	a5,16
    80003d8e:	06f51163          	bne	a0,a5,80003df0 <dirlink+0xa2>
    if(de.inum == 0)
    80003d92:	fc045783          	lhu	a5,-64(s0)
    80003d96:	c791                	beqz	a5,80003da2 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d98:	24c1                	addiw	s1,s1,16
    80003d9a:	04c92783          	lw	a5,76(s2)
    80003d9e:	fcf4ede3          	bltu	s1,a5,80003d78 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003da2:	4639                	li	a2,14
    80003da4:	85d2                	mv	a1,s4
    80003da6:	fc240513          	addi	a0,s0,-62
    80003daa:	ffffd097          	auipc	ra,0xffffd
    80003dae:	04a080e7          	jalr	74(ra) # 80000df4 <strncpy>
  de.inum = inum;
    80003db2:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003db6:	4741                	li	a4,16
    80003db8:	86a6                	mv	a3,s1
    80003dba:	fc040613          	addi	a2,s0,-64
    80003dbe:	4581                	li	a1,0
    80003dc0:	854a                	mv	a0,s2
    80003dc2:	00000097          	auipc	ra,0x0
    80003dc6:	c44080e7          	jalr	-956(ra) # 80003a06 <writei>
    80003dca:	872a                	mv	a4,a0
    80003dcc:	47c1                	li	a5,16
  return 0;
    80003dce:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003dd0:	02f71863          	bne	a4,a5,80003e00 <dirlink+0xb2>
}
    80003dd4:	70e2                	ld	ra,56(sp)
    80003dd6:	7442                	ld	s0,48(sp)
    80003dd8:	74a2                	ld	s1,40(sp)
    80003dda:	7902                	ld	s2,32(sp)
    80003ddc:	69e2                	ld	s3,24(sp)
    80003dde:	6a42                	ld	s4,16(sp)
    80003de0:	6121                	addi	sp,sp,64
    80003de2:	8082                	ret
    iput(ip);
    80003de4:	00000097          	auipc	ra,0x0
    80003de8:	a30080e7          	jalr	-1488(ra) # 80003814 <iput>
    return -1;
    80003dec:	557d                	li	a0,-1
    80003dee:	b7dd                	j	80003dd4 <dirlink+0x86>
      panic("dirlink read");
    80003df0:	00005517          	auipc	a0,0x5
    80003df4:	82850513          	addi	a0,a0,-2008 # 80008618 <syscalls+0x1c8>
    80003df8:	ffffc097          	auipc	ra,0xffffc
    80003dfc:	746080e7          	jalr	1862(ra) # 8000053e <panic>
    panic("dirlink");
    80003e00:	00005517          	auipc	a0,0x5
    80003e04:	92850513          	addi	a0,a0,-1752 # 80008728 <syscalls+0x2d8>
    80003e08:	ffffc097          	auipc	ra,0xffffc
    80003e0c:	736080e7          	jalr	1846(ra) # 8000053e <panic>

0000000080003e10 <namei>:

struct inode*
namei(char *path)
{
    80003e10:	1101                	addi	sp,sp,-32
    80003e12:	ec06                	sd	ra,24(sp)
    80003e14:	e822                	sd	s0,16(sp)
    80003e16:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003e18:	fe040613          	addi	a2,s0,-32
    80003e1c:	4581                	li	a1,0
    80003e1e:	00000097          	auipc	ra,0x0
    80003e22:	dd0080e7          	jalr	-560(ra) # 80003bee <namex>
}
    80003e26:	60e2                	ld	ra,24(sp)
    80003e28:	6442                	ld	s0,16(sp)
    80003e2a:	6105                	addi	sp,sp,32
    80003e2c:	8082                	ret

0000000080003e2e <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003e2e:	1141                	addi	sp,sp,-16
    80003e30:	e406                	sd	ra,8(sp)
    80003e32:	e022                	sd	s0,0(sp)
    80003e34:	0800                	addi	s0,sp,16
    80003e36:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80003e38:	4585                	li	a1,1
    80003e3a:	00000097          	auipc	ra,0x0
    80003e3e:	db4080e7          	jalr	-588(ra) # 80003bee <namex>
}
    80003e42:	60a2                	ld	ra,8(sp)
    80003e44:	6402                	ld	s0,0(sp)
    80003e46:	0141                	addi	sp,sp,16
    80003e48:	8082                	ret

0000000080003e4a <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80003e4a:	1101                	addi	sp,sp,-32
    80003e4c:	ec06                	sd	ra,24(sp)
    80003e4e:	e822                	sd	s0,16(sp)
    80003e50:	e426                	sd	s1,8(sp)
    80003e52:	e04a                	sd	s2,0(sp)
    80003e54:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80003e56:	00024917          	auipc	s2,0x24
    80003e5a:	41a90913          	addi	s2,s2,1050 # 80028270 <log>
    80003e5e:	01892583          	lw	a1,24(s2)
    80003e62:	02892503          	lw	a0,40(s2)
    80003e66:	fffff097          	auipc	ra,0xfffff
    80003e6a:	ff2080e7          	jalr	-14(ra) # 80002e58 <bread>
    80003e6e:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80003e70:	02c92683          	lw	a3,44(s2)
    80003e74:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80003e76:	02d05763          	blez	a3,80003ea4 <write_head+0x5a>
    80003e7a:	00024797          	auipc	a5,0x24
    80003e7e:	42678793          	addi	a5,a5,1062 # 800282a0 <log+0x30>
    80003e82:	05c50713          	addi	a4,a0,92
    80003e86:	36fd                	addiw	a3,a3,-1
    80003e88:	1682                	slli	a3,a3,0x20
    80003e8a:	9281                	srli	a3,a3,0x20
    80003e8c:	068a                	slli	a3,a3,0x2
    80003e8e:	00024617          	auipc	a2,0x24
    80003e92:	41660613          	addi	a2,a2,1046 # 800282a4 <log+0x34>
    80003e96:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80003e98:	4390                	lw	a2,0(a5)
    80003e9a:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80003e9c:	0791                	addi	a5,a5,4
    80003e9e:	0711                	addi	a4,a4,4
    80003ea0:	fed79ce3          	bne	a5,a3,80003e98 <write_head+0x4e>
  }
  bwrite(buf);
    80003ea4:	8526                	mv	a0,s1
    80003ea6:	fffff097          	auipc	ra,0xfffff
    80003eaa:	0a4080e7          	jalr	164(ra) # 80002f4a <bwrite>
  brelse(buf);
    80003eae:	8526                	mv	a0,s1
    80003eb0:	fffff097          	auipc	ra,0xfffff
    80003eb4:	0d8080e7          	jalr	216(ra) # 80002f88 <brelse>
}
    80003eb8:	60e2                	ld	ra,24(sp)
    80003eba:	6442                	ld	s0,16(sp)
    80003ebc:	64a2                	ld	s1,8(sp)
    80003ebe:	6902                	ld	s2,0(sp)
    80003ec0:	6105                	addi	sp,sp,32
    80003ec2:	8082                	ret

0000000080003ec4 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80003ec4:	00024797          	auipc	a5,0x24
    80003ec8:	3d87a783          	lw	a5,984(a5) # 8002829c <log+0x2c>
    80003ecc:	0af05d63          	blez	a5,80003f86 <install_trans+0xc2>
{
    80003ed0:	7139                	addi	sp,sp,-64
    80003ed2:	fc06                	sd	ra,56(sp)
    80003ed4:	f822                	sd	s0,48(sp)
    80003ed6:	f426                	sd	s1,40(sp)
    80003ed8:	f04a                	sd	s2,32(sp)
    80003eda:	ec4e                	sd	s3,24(sp)
    80003edc:	e852                	sd	s4,16(sp)
    80003ede:	e456                	sd	s5,8(sp)
    80003ee0:	e05a                	sd	s6,0(sp)
    80003ee2:	0080                	addi	s0,sp,64
    80003ee4:	8b2a                	mv	s6,a0
    80003ee6:	00024a97          	auipc	s5,0x24
    80003eea:	3baa8a93          	addi	s5,s5,954 # 800282a0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003eee:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80003ef0:	00024997          	auipc	s3,0x24
    80003ef4:	38098993          	addi	s3,s3,896 # 80028270 <log>
    80003ef8:	a035                	j	80003f24 <install_trans+0x60>
      bunpin(dbuf);
    80003efa:	8526                	mv	a0,s1
    80003efc:	fffff097          	auipc	ra,0xfffff
    80003f00:	166080e7          	jalr	358(ra) # 80003062 <bunpin>
    brelse(lbuf);
    80003f04:	854a                	mv	a0,s2
    80003f06:	fffff097          	auipc	ra,0xfffff
    80003f0a:	082080e7          	jalr	130(ra) # 80002f88 <brelse>
    brelse(dbuf);
    80003f0e:	8526                	mv	a0,s1
    80003f10:	fffff097          	auipc	ra,0xfffff
    80003f14:	078080e7          	jalr	120(ra) # 80002f88 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003f18:	2a05                	addiw	s4,s4,1
    80003f1a:	0a91                	addi	s5,s5,4
    80003f1c:	02c9a783          	lw	a5,44(s3)
    80003f20:	04fa5963          	bge	s4,a5,80003f72 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80003f24:	0189a583          	lw	a1,24(s3)
    80003f28:	014585bb          	addw	a1,a1,s4
    80003f2c:	2585                	addiw	a1,a1,1
    80003f2e:	0289a503          	lw	a0,40(s3)
    80003f32:	fffff097          	auipc	ra,0xfffff
    80003f36:	f26080e7          	jalr	-218(ra) # 80002e58 <bread>
    80003f3a:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80003f3c:	000aa583          	lw	a1,0(s5)
    80003f40:	0289a503          	lw	a0,40(s3)
    80003f44:	fffff097          	auipc	ra,0xfffff
    80003f48:	f14080e7          	jalr	-236(ra) # 80002e58 <bread>
    80003f4c:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80003f4e:	40000613          	li	a2,1024
    80003f52:	05890593          	addi	a1,s2,88
    80003f56:	05850513          	addi	a0,a0,88
    80003f5a:	ffffd097          	auipc	ra,0xffffd
    80003f5e:	de6080e7          	jalr	-538(ra) # 80000d40 <memmove>
    bwrite(dbuf);  // write dst to disk
    80003f62:	8526                	mv	a0,s1
    80003f64:	fffff097          	auipc	ra,0xfffff
    80003f68:	fe6080e7          	jalr	-26(ra) # 80002f4a <bwrite>
    if(recovering == 0)
    80003f6c:	f80b1ce3          	bnez	s6,80003f04 <install_trans+0x40>
    80003f70:	b769                	j	80003efa <install_trans+0x36>
}
    80003f72:	70e2                	ld	ra,56(sp)
    80003f74:	7442                	ld	s0,48(sp)
    80003f76:	74a2                	ld	s1,40(sp)
    80003f78:	7902                	ld	s2,32(sp)
    80003f7a:	69e2                	ld	s3,24(sp)
    80003f7c:	6a42                	ld	s4,16(sp)
    80003f7e:	6aa2                	ld	s5,8(sp)
    80003f80:	6b02                	ld	s6,0(sp)
    80003f82:	6121                	addi	sp,sp,64
    80003f84:	8082                	ret
    80003f86:	8082                	ret

0000000080003f88 <initlog>:
{
    80003f88:	7179                	addi	sp,sp,-48
    80003f8a:	f406                	sd	ra,40(sp)
    80003f8c:	f022                	sd	s0,32(sp)
    80003f8e:	ec26                	sd	s1,24(sp)
    80003f90:	e84a                	sd	s2,16(sp)
    80003f92:	e44e                	sd	s3,8(sp)
    80003f94:	1800                	addi	s0,sp,48
    80003f96:	892a                	mv	s2,a0
    80003f98:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80003f9a:	00024497          	auipc	s1,0x24
    80003f9e:	2d648493          	addi	s1,s1,726 # 80028270 <log>
    80003fa2:	00004597          	auipc	a1,0x4
    80003fa6:	68658593          	addi	a1,a1,1670 # 80008628 <syscalls+0x1d8>
    80003faa:	8526                	mv	a0,s1
    80003fac:	ffffd097          	auipc	ra,0xffffd
    80003fb0:	ba8080e7          	jalr	-1112(ra) # 80000b54 <initlock>
  log.start = sb->logstart;
    80003fb4:	0149a583          	lw	a1,20(s3)
    80003fb8:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80003fba:	0109a783          	lw	a5,16(s3)
    80003fbe:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80003fc0:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80003fc4:	854a                	mv	a0,s2
    80003fc6:	fffff097          	auipc	ra,0xfffff
    80003fca:	e92080e7          	jalr	-366(ra) # 80002e58 <bread>
  log.lh.n = lh->n;
    80003fce:	4d3c                	lw	a5,88(a0)
    80003fd0:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80003fd2:	02f05563          	blez	a5,80003ffc <initlog+0x74>
    80003fd6:	05c50713          	addi	a4,a0,92
    80003fda:	00024697          	auipc	a3,0x24
    80003fde:	2c668693          	addi	a3,a3,710 # 800282a0 <log+0x30>
    80003fe2:	37fd                	addiw	a5,a5,-1
    80003fe4:	1782                	slli	a5,a5,0x20
    80003fe6:	9381                	srli	a5,a5,0x20
    80003fe8:	078a                	slli	a5,a5,0x2
    80003fea:	06050613          	addi	a2,a0,96
    80003fee:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    80003ff0:	4310                	lw	a2,0(a4)
    80003ff2:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    80003ff4:	0711                	addi	a4,a4,4
    80003ff6:	0691                	addi	a3,a3,4
    80003ff8:	fef71ce3          	bne	a4,a5,80003ff0 <initlog+0x68>
  brelse(buf);
    80003ffc:	fffff097          	auipc	ra,0xfffff
    80004000:	f8c080e7          	jalr	-116(ra) # 80002f88 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004004:	4505                	li	a0,1
    80004006:	00000097          	auipc	ra,0x0
    8000400a:	ebe080e7          	jalr	-322(ra) # 80003ec4 <install_trans>
  log.lh.n = 0;
    8000400e:	00024797          	auipc	a5,0x24
    80004012:	2807a723          	sw	zero,654(a5) # 8002829c <log+0x2c>
  write_head(); // clear the log
    80004016:	00000097          	auipc	ra,0x0
    8000401a:	e34080e7          	jalr	-460(ra) # 80003e4a <write_head>
}
    8000401e:	70a2                	ld	ra,40(sp)
    80004020:	7402                	ld	s0,32(sp)
    80004022:	64e2                	ld	s1,24(sp)
    80004024:	6942                	ld	s2,16(sp)
    80004026:	69a2                	ld	s3,8(sp)
    80004028:	6145                	addi	sp,sp,48
    8000402a:	8082                	ret

000000008000402c <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    8000402c:	1101                	addi	sp,sp,-32
    8000402e:	ec06                	sd	ra,24(sp)
    80004030:	e822                	sd	s0,16(sp)
    80004032:	e426                	sd	s1,8(sp)
    80004034:	e04a                	sd	s2,0(sp)
    80004036:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004038:	00024517          	auipc	a0,0x24
    8000403c:	23850513          	addi	a0,a0,568 # 80028270 <log>
    80004040:	ffffd097          	auipc	ra,0xffffd
    80004044:	ba4080e7          	jalr	-1116(ra) # 80000be4 <acquire>
  while(1){
    if(log.committing){
    80004048:	00024497          	auipc	s1,0x24
    8000404c:	22848493          	addi	s1,s1,552 # 80028270 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004050:	4979                	li	s2,30
    80004052:	a039                	j	80004060 <begin_op+0x34>
      sleep(&log, &log.lock);
    80004054:	85a6                	mv	a1,s1
    80004056:	8526                	mv	a0,s1
    80004058:	ffffe097          	auipc	ra,0xffffe
    8000405c:	0a0080e7          	jalr	160(ra) # 800020f8 <sleep>
    if(log.committing){
    80004060:	50dc                	lw	a5,36(s1)
    80004062:	fbed                	bnez	a5,80004054 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004064:	509c                	lw	a5,32(s1)
    80004066:	0017871b          	addiw	a4,a5,1
    8000406a:	0007069b          	sext.w	a3,a4
    8000406e:	0027179b          	slliw	a5,a4,0x2
    80004072:	9fb9                	addw	a5,a5,a4
    80004074:	0017979b          	slliw	a5,a5,0x1
    80004078:	54d8                	lw	a4,44(s1)
    8000407a:	9fb9                	addw	a5,a5,a4
    8000407c:	00f95963          	bge	s2,a5,8000408e <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004080:	85a6                	mv	a1,s1
    80004082:	8526                	mv	a0,s1
    80004084:	ffffe097          	auipc	ra,0xffffe
    80004088:	074080e7          	jalr	116(ra) # 800020f8 <sleep>
    8000408c:	bfd1                	j	80004060 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    8000408e:	00024517          	auipc	a0,0x24
    80004092:	1e250513          	addi	a0,a0,482 # 80028270 <log>
    80004096:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004098:	ffffd097          	auipc	ra,0xffffd
    8000409c:	c00080e7          	jalr	-1024(ra) # 80000c98 <release>
      break;
    }
  }
}
    800040a0:	60e2                	ld	ra,24(sp)
    800040a2:	6442                	ld	s0,16(sp)
    800040a4:	64a2                	ld	s1,8(sp)
    800040a6:	6902                	ld	s2,0(sp)
    800040a8:	6105                	addi	sp,sp,32
    800040aa:	8082                	ret

00000000800040ac <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    800040ac:	7139                	addi	sp,sp,-64
    800040ae:	fc06                	sd	ra,56(sp)
    800040b0:	f822                	sd	s0,48(sp)
    800040b2:	f426                	sd	s1,40(sp)
    800040b4:	f04a                	sd	s2,32(sp)
    800040b6:	ec4e                	sd	s3,24(sp)
    800040b8:	e852                	sd	s4,16(sp)
    800040ba:	e456                	sd	s5,8(sp)
    800040bc:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    800040be:	00024497          	auipc	s1,0x24
    800040c2:	1b248493          	addi	s1,s1,434 # 80028270 <log>
    800040c6:	8526                	mv	a0,s1
    800040c8:	ffffd097          	auipc	ra,0xffffd
    800040cc:	b1c080e7          	jalr	-1252(ra) # 80000be4 <acquire>
  log.outstanding -= 1;
    800040d0:	509c                	lw	a5,32(s1)
    800040d2:	37fd                	addiw	a5,a5,-1
    800040d4:	0007891b          	sext.w	s2,a5
    800040d8:	d09c                	sw	a5,32(s1)
  if(log.committing)
    800040da:	50dc                	lw	a5,36(s1)
    800040dc:	efb9                	bnez	a5,8000413a <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    800040de:	06091663          	bnez	s2,8000414a <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    800040e2:	00024497          	auipc	s1,0x24
    800040e6:	18e48493          	addi	s1,s1,398 # 80028270 <log>
    800040ea:	4785                	li	a5,1
    800040ec:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800040ee:	8526                	mv	a0,s1
    800040f0:	ffffd097          	auipc	ra,0xffffd
    800040f4:	ba8080e7          	jalr	-1112(ra) # 80000c98 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800040f8:	54dc                	lw	a5,44(s1)
    800040fa:	06f04763          	bgtz	a5,80004168 <end_op+0xbc>
    acquire(&log.lock);
    800040fe:	00024497          	auipc	s1,0x24
    80004102:	17248493          	addi	s1,s1,370 # 80028270 <log>
    80004106:	8526                	mv	a0,s1
    80004108:	ffffd097          	auipc	ra,0xffffd
    8000410c:	adc080e7          	jalr	-1316(ra) # 80000be4 <acquire>
    log.committing = 0;
    80004110:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004114:	8526                	mv	a0,s1
    80004116:	ffffe097          	auipc	ra,0xffffe
    8000411a:	16e080e7          	jalr	366(ra) # 80002284 <wakeup>
    release(&log.lock);
    8000411e:	8526                	mv	a0,s1
    80004120:	ffffd097          	auipc	ra,0xffffd
    80004124:	b78080e7          	jalr	-1160(ra) # 80000c98 <release>
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
    panic("log.committing");
    8000413a:	00004517          	auipc	a0,0x4
    8000413e:	4f650513          	addi	a0,a0,1270 # 80008630 <syscalls+0x1e0>
    80004142:	ffffc097          	auipc	ra,0xffffc
    80004146:	3fc080e7          	jalr	1020(ra) # 8000053e <panic>
    wakeup(&log);
    8000414a:	00024497          	auipc	s1,0x24
    8000414e:	12648493          	addi	s1,s1,294 # 80028270 <log>
    80004152:	8526                	mv	a0,s1
    80004154:	ffffe097          	auipc	ra,0xffffe
    80004158:	130080e7          	jalr	304(ra) # 80002284 <wakeup>
  release(&log.lock);
    8000415c:	8526                	mv	a0,s1
    8000415e:	ffffd097          	auipc	ra,0xffffd
    80004162:	b3a080e7          	jalr	-1222(ra) # 80000c98 <release>
  if(do_commit){
    80004166:	b7c9                	j	80004128 <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004168:	00024a97          	auipc	s5,0x24
    8000416c:	138a8a93          	addi	s5,s5,312 # 800282a0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004170:	00024a17          	auipc	s4,0x24
    80004174:	100a0a13          	addi	s4,s4,256 # 80028270 <log>
    80004178:	018a2583          	lw	a1,24(s4)
    8000417c:	012585bb          	addw	a1,a1,s2
    80004180:	2585                	addiw	a1,a1,1
    80004182:	028a2503          	lw	a0,40(s4)
    80004186:	fffff097          	auipc	ra,0xfffff
    8000418a:	cd2080e7          	jalr	-814(ra) # 80002e58 <bread>
    8000418e:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004190:	000aa583          	lw	a1,0(s5)
    80004194:	028a2503          	lw	a0,40(s4)
    80004198:	fffff097          	auipc	ra,0xfffff
    8000419c:	cc0080e7          	jalr	-832(ra) # 80002e58 <bread>
    800041a0:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    800041a2:	40000613          	li	a2,1024
    800041a6:	05850593          	addi	a1,a0,88
    800041aa:	05848513          	addi	a0,s1,88
    800041ae:	ffffd097          	auipc	ra,0xffffd
    800041b2:	b92080e7          	jalr	-1134(ra) # 80000d40 <memmove>
    bwrite(to);  // write the log
    800041b6:	8526                	mv	a0,s1
    800041b8:	fffff097          	auipc	ra,0xfffff
    800041bc:	d92080e7          	jalr	-622(ra) # 80002f4a <bwrite>
    brelse(from);
    800041c0:	854e                	mv	a0,s3
    800041c2:	fffff097          	auipc	ra,0xfffff
    800041c6:	dc6080e7          	jalr	-570(ra) # 80002f88 <brelse>
    brelse(to);
    800041ca:	8526                	mv	a0,s1
    800041cc:	fffff097          	auipc	ra,0xfffff
    800041d0:	dbc080e7          	jalr	-580(ra) # 80002f88 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800041d4:	2905                	addiw	s2,s2,1
    800041d6:	0a91                	addi	s5,s5,4
    800041d8:	02ca2783          	lw	a5,44(s4)
    800041dc:	f8f94ee3          	blt	s2,a5,80004178 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    800041e0:	00000097          	auipc	ra,0x0
    800041e4:	c6a080e7          	jalr	-918(ra) # 80003e4a <write_head>
    install_trans(0); // Now install writes to home locations
    800041e8:	4501                	li	a0,0
    800041ea:	00000097          	auipc	ra,0x0
    800041ee:	cda080e7          	jalr	-806(ra) # 80003ec4 <install_trans>
    log.lh.n = 0;
    800041f2:	00024797          	auipc	a5,0x24
    800041f6:	0a07a523          	sw	zero,170(a5) # 8002829c <log+0x2c>
    write_head();    // Erase the transaction from the log
    800041fa:	00000097          	auipc	ra,0x0
    800041fe:	c50080e7          	jalr	-944(ra) # 80003e4a <write_head>
    80004202:	bdf5                	j	800040fe <end_op+0x52>

0000000080004204 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004204:	1101                	addi	sp,sp,-32
    80004206:	ec06                	sd	ra,24(sp)
    80004208:	e822                	sd	s0,16(sp)
    8000420a:	e426                	sd	s1,8(sp)
    8000420c:	e04a                	sd	s2,0(sp)
    8000420e:	1000                	addi	s0,sp,32
    80004210:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004212:	00024917          	auipc	s2,0x24
    80004216:	05e90913          	addi	s2,s2,94 # 80028270 <log>
    8000421a:	854a                	mv	a0,s2
    8000421c:	ffffd097          	auipc	ra,0xffffd
    80004220:	9c8080e7          	jalr	-1592(ra) # 80000be4 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004224:	02c92603          	lw	a2,44(s2)
    80004228:	47f5                	li	a5,29
    8000422a:	06c7c563          	blt	a5,a2,80004294 <log_write+0x90>
    8000422e:	00024797          	auipc	a5,0x24
    80004232:	05e7a783          	lw	a5,94(a5) # 8002828c <log+0x1c>
    80004236:	37fd                	addiw	a5,a5,-1
    80004238:	04f65e63          	bge	a2,a5,80004294 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    8000423c:	00024797          	auipc	a5,0x24
    80004240:	0547a783          	lw	a5,84(a5) # 80028290 <log+0x20>
    80004244:	06f05063          	blez	a5,800042a4 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004248:	4781                	li	a5,0
    8000424a:	06c05563          	blez	a2,800042b4 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    8000424e:	44cc                	lw	a1,12(s1)
    80004250:	00024717          	auipc	a4,0x24
    80004254:	05070713          	addi	a4,a4,80 # 800282a0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004258:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    8000425a:	4314                	lw	a3,0(a4)
    8000425c:	04b68c63          	beq	a3,a1,800042b4 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004260:	2785                	addiw	a5,a5,1
    80004262:	0711                	addi	a4,a4,4
    80004264:	fef61be3          	bne	a2,a5,8000425a <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004268:	0621                	addi	a2,a2,8
    8000426a:	060a                	slli	a2,a2,0x2
    8000426c:	00024797          	auipc	a5,0x24
    80004270:	00478793          	addi	a5,a5,4 # 80028270 <log>
    80004274:	963e                	add	a2,a2,a5
    80004276:	44dc                	lw	a5,12(s1)
    80004278:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    8000427a:	8526                	mv	a0,s1
    8000427c:	fffff097          	auipc	ra,0xfffff
    80004280:	daa080e7          	jalr	-598(ra) # 80003026 <bpin>
    log.lh.n++;
    80004284:	00024717          	auipc	a4,0x24
    80004288:	fec70713          	addi	a4,a4,-20 # 80028270 <log>
    8000428c:	575c                	lw	a5,44(a4)
    8000428e:	2785                	addiw	a5,a5,1
    80004290:	d75c                	sw	a5,44(a4)
    80004292:	a835                	j	800042ce <log_write+0xca>
    panic("too big a transaction");
    80004294:	00004517          	auipc	a0,0x4
    80004298:	3ac50513          	addi	a0,a0,940 # 80008640 <syscalls+0x1f0>
    8000429c:	ffffc097          	auipc	ra,0xffffc
    800042a0:	2a2080e7          	jalr	674(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    800042a4:	00004517          	auipc	a0,0x4
    800042a8:	3b450513          	addi	a0,a0,948 # 80008658 <syscalls+0x208>
    800042ac:	ffffc097          	auipc	ra,0xffffc
    800042b0:	292080e7          	jalr	658(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    800042b4:	00878713          	addi	a4,a5,8
    800042b8:	00271693          	slli	a3,a4,0x2
    800042bc:	00024717          	auipc	a4,0x24
    800042c0:	fb470713          	addi	a4,a4,-76 # 80028270 <log>
    800042c4:	9736                	add	a4,a4,a3
    800042c6:	44d4                	lw	a3,12(s1)
    800042c8:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    800042ca:	faf608e3          	beq	a2,a5,8000427a <log_write+0x76>
  }
  release(&log.lock);
    800042ce:	00024517          	auipc	a0,0x24
    800042d2:	fa250513          	addi	a0,a0,-94 # 80028270 <log>
    800042d6:	ffffd097          	auipc	ra,0xffffd
    800042da:	9c2080e7          	jalr	-1598(ra) # 80000c98 <release>
}
    800042de:	60e2                	ld	ra,24(sp)
    800042e0:	6442                	ld	s0,16(sp)
    800042e2:	64a2                	ld	s1,8(sp)
    800042e4:	6902                	ld	s2,0(sp)
    800042e6:	6105                	addi	sp,sp,32
    800042e8:	8082                	ret

00000000800042ea <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    800042ea:	1101                	addi	sp,sp,-32
    800042ec:	ec06                	sd	ra,24(sp)
    800042ee:	e822                	sd	s0,16(sp)
    800042f0:	e426                	sd	s1,8(sp)
    800042f2:	e04a                	sd	s2,0(sp)
    800042f4:	1000                	addi	s0,sp,32
    800042f6:	84aa                	mv	s1,a0
    800042f8:	892e                	mv	s2,a1
	initlock(&lk->lk, "sleep lock");
    800042fa:	00004597          	auipc	a1,0x4
    800042fe:	37e58593          	addi	a1,a1,894 # 80008678 <syscalls+0x228>
    80004302:	0521                	addi	a0,a0,8
    80004304:	ffffd097          	auipc	ra,0xffffd
    80004308:	850080e7          	jalr	-1968(ra) # 80000b54 <initlock>
	lk->name = name;
    8000430c:	0324b023          	sd	s2,32(s1)
	lk->locked = 0;
    80004310:	0004a023          	sw	zero,0(s1)
	lk->pid = 0;
    80004314:	0204a423          	sw	zero,40(s1)
}
    80004318:	60e2                	ld	ra,24(sp)
    8000431a:	6442                	ld	s0,16(sp)
    8000431c:	64a2                	ld	s1,8(sp)
    8000431e:	6902                	ld	s2,0(sp)
    80004320:	6105                	addi	sp,sp,32
    80004322:	8082                	ret

0000000080004324 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004324:	1101                	addi	sp,sp,-32
    80004326:	ec06                	sd	ra,24(sp)
    80004328:	e822                	sd	s0,16(sp)
    8000432a:	e426                	sd	s1,8(sp)
    8000432c:	e04a                	sd	s2,0(sp)
    8000432e:	1000                	addi	s0,sp,32
    80004330:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004332:	00850913          	addi	s2,a0,8
    80004336:	854a                	mv	a0,s2
    80004338:	ffffd097          	auipc	ra,0xffffd
    8000433c:	8ac080e7          	jalr	-1876(ra) # 80000be4 <acquire>
  while (lk->locked) {
    80004340:	409c                	lw	a5,0(s1)
    80004342:	cb89                	beqz	a5,80004354 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004344:	85ca                	mv	a1,s2
    80004346:	8526                	mv	a0,s1
    80004348:	ffffe097          	auipc	ra,0xffffe
    8000434c:	db0080e7          	jalr	-592(ra) # 800020f8 <sleep>
  while (lk->locked) {
    80004350:	409c                	lw	a5,0(s1)
    80004352:	fbed                	bnez	a5,80004344 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004354:	4785                	li	a5,1
    80004356:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004358:	ffffd097          	auipc	ra,0xffffd
    8000435c:	6e4080e7          	jalr	1764(ra) # 80001a3c <myproc>
    80004360:	591c                	lw	a5,48(a0)
    80004362:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004364:	854a                	mv	a0,s2
    80004366:	ffffd097          	auipc	ra,0xffffd
    8000436a:	932080e7          	jalr	-1742(ra) # 80000c98 <release>
}
    8000436e:	60e2                	ld	ra,24(sp)
    80004370:	6442                	ld	s0,16(sp)
    80004372:	64a2                	ld	s1,8(sp)
    80004374:	6902                	ld	s2,0(sp)
    80004376:	6105                	addi	sp,sp,32
    80004378:	8082                	ret

000000008000437a <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    8000437a:	1101                	addi	sp,sp,-32
    8000437c:	ec06                	sd	ra,24(sp)
    8000437e:	e822                	sd	s0,16(sp)
    80004380:	e426                	sd	s1,8(sp)
    80004382:	e04a                	sd	s2,0(sp)
    80004384:	1000                	addi	s0,sp,32
    80004386:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004388:	00850913          	addi	s2,a0,8
    8000438c:	854a                	mv	a0,s2
    8000438e:	ffffd097          	auipc	ra,0xffffd
    80004392:	856080e7          	jalr	-1962(ra) # 80000be4 <acquire>
  lk->locked = 0;
    80004396:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000439a:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    8000439e:	8526                	mv	a0,s1
    800043a0:	ffffe097          	auipc	ra,0xffffe
    800043a4:	ee4080e7          	jalr	-284(ra) # 80002284 <wakeup>
  release(&lk->lk);
    800043a8:	854a                	mv	a0,s2
    800043aa:	ffffd097          	auipc	ra,0xffffd
    800043ae:	8ee080e7          	jalr	-1810(ra) # 80000c98 <release>
}
    800043b2:	60e2                	ld	ra,24(sp)
    800043b4:	6442                	ld	s0,16(sp)
    800043b6:	64a2                	ld	s1,8(sp)
    800043b8:	6902                	ld	s2,0(sp)
    800043ba:	6105                	addi	sp,sp,32
    800043bc:	8082                	ret

00000000800043be <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    800043be:	7179                	addi	sp,sp,-48
    800043c0:	f406                	sd	ra,40(sp)
    800043c2:	f022                	sd	s0,32(sp)
    800043c4:	ec26                	sd	s1,24(sp)
    800043c6:	e84a                	sd	s2,16(sp)
    800043c8:	e44e                	sd	s3,8(sp)
    800043ca:	1800                	addi	s0,sp,48
    800043cc:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    800043ce:	00850913          	addi	s2,a0,8
    800043d2:	854a                	mv	a0,s2
    800043d4:	ffffd097          	auipc	ra,0xffffd
    800043d8:	810080e7          	jalr	-2032(ra) # 80000be4 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    800043dc:	409c                	lw	a5,0(s1)
    800043de:	ef99                	bnez	a5,800043fc <holdingsleep+0x3e>
    800043e0:	4481                	li	s1,0
  release(&lk->lk);
    800043e2:	854a                	mv	a0,s2
    800043e4:	ffffd097          	auipc	ra,0xffffd
    800043e8:	8b4080e7          	jalr	-1868(ra) # 80000c98 <release>
  return r;
}
    800043ec:	8526                	mv	a0,s1
    800043ee:	70a2                	ld	ra,40(sp)
    800043f0:	7402                	ld	s0,32(sp)
    800043f2:	64e2                	ld	s1,24(sp)
    800043f4:	6942                	ld	s2,16(sp)
    800043f6:	69a2                	ld	s3,8(sp)
    800043f8:	6145                	addi	sp,sp,48
    800043fa:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    800043fc:	0284a983          	lw	s3,40(s1)
    80004400:	ffffd097          	auipc	ra,0xffffd
    80004404:	63c080e7          	jalr	1596(ra) # 80001a3c <myproc>
    80004408:	5904                	lw	s1,48(a0)
    8000440a:	413484b3          	sub	s1,s1,s3
    8000440e:	0014b493          	seqz	s1,s1
    80004412:	bfc1                	j	800043e2 <holdingsleep+0x24>

0000000080004414 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004414:	1141                	addi	sp,sp,-16
    80004416:	e406                	sd	ra,8(sp)
    80004418:	e022                	sd	s0,0(sp)
    8000441a:	0800                	addi	s0,sp,16
	initlock(&ftable.lock, "ftable");
    8000441c:	00004597          	auipc	a1,0x4
    80004420:	26c58593          	addi	a1,a1,620 # 80008688 <syscalls+0x238>
    80004424:	00024517          	auipc	a0,0x24
    80004428:	f9450513          	addi	a0,a0,-108 # 800283b8 <ftable>
    8000442c:	ffffc097          	auipc	ra,0xffffc
    80004430:	728080e7          	jalr	1832(ra) # 80000b54 <initlock>
}
    80004434:	60a2                	ld	ra,8(sp)
    80004436:	6402                	ld	s0,0(sp)
    80004438:	0141                	addi	sp,sp,16
    8000443a:	8082                	ret

000000008000443c <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    8000443c:	1101                	addi	sp,sp,-32
    8000443e:	ec06                	sd	ra,24(sp)
    80004440:	e822                	sd	s0,16(sp)
    80004442:	e426                	sd	s1,8(sp)
    80004444:	1000                	addi	s0,sp,32
	struct file *f;

	acquire(&ftable.lock);
    80004446:	00024517          	auipc	a0,0x24
    8000444a:	f7250513          	addi	a0,a0,-142 # 800283b8 <ftable>
    8000444e:	ffffc097          	auipc	ra,0xffffc
    80004452:	796080e7          	jalr	1942(ra) # 80000be4 <acquire>
	for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004456:	00024497          	auipc	s1,0x24
    8000445a:	f7a48493          	addi	s1,s1,-134 # 800283d0 <ftable+0x18>
    8000445e:	00025717          	auipc	a4,0x25
    80004462:	f1270713          	addi	a4,a4,-238 # 80029370 <ftable+0xfb8>
		if(f->ref == 0){
    80004466:	40dc                	lw	a5,4(s1)
    80004468:	cf99                	beqz	a5,80004486 <filealloc+0x4a>
	for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000446a:	02848493          	addi	s1,s1,40
    8000446e:	fee49ce3          	bne	s1,a4,80004466 <filealloc+0x2a>
			f->ref = 1;
			release(&ftable.lock);
			return f;
		}
	}
	release(&ftable.lock);
    80004472:	00024517          	auipc	a0,0x24
    80004476:	f4650513          	addi	a0,a0,-186 # 800283b8 <ftable>
    8000447a:	ffffd097          	auipc	ra,0xffffd
    8000447e:	81e080e7          	jalr	-2018(ra) # 80000c98 <release>
	return 0;
    80004482:	4481                	li	s1,0
    80004484:	a819                	j	8000449a <filealloc+0x5e>
			f->ref = 1;
    80004486:	4785                	li	a5,1
    80004488:	c0dc                	sw	a5,4(s1)
			release(&ftable.lock);
    8000448a:	00024517          	auipc	a0,0x24
    8000448e:	f2e50513          	addi	a0,a0,-210 # 800283b8 <ftable>
    80004492:	ffffd097          	auipc	ra,0xffffd
    80004496:	806080e7          	jalr	-2042(ra) # 80000c98 <release>
}
    8000449a:	8526                	mv	a0,s1
    8000449c:	60e2                	ld	ra,24(sp)
    8000449e:	6442                	ld	s0,16(sp)
    800044a0:	64a2                	ld	s1,8(sp)
    800044a2:	6105                	addi	sp,sp,32
    800044a4:	8082                	ret

00000000800044a6 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    800044a6:	1101                	addi	sp,sp,-32
    800044a8:	ec06                	sd	ra,24(sp)
    800044aa:	e822                	sd	s0,16(sp)
    800044ac:	e426                	sd	s1,8(sp)
    800044ae:	1000                	addi	s0,sp,32
    800044b0:	84aa                	mv	s1,a0
	acquire(&ftable.lock);
    800044b2:	00024517          	auipc	a0,0x24
    800044b6:	f0650513          	addi	a0,a0,-250 # 800283b8 <ftable>
    800044ba:	ffffc097          	auipc	ra,0xffffc
    800044be:	72a080e7          	jalr	1834(ra) # 80000be4 <acquire>
	if(f->ref < 1)
    800044c2:	40dc                	lw	a5,4(s1)
    800044c4:	02f05263          	blez	a5,800044e8 <filedup+0x42>
		panic("filedup");
	f->ref++;
    800044c8:	2785                	addiw	a5,a5,1
    800044ca:	c0dc                	sw	a5,4(s1)
	release(&ftable.lock);
    800044cc:	00024517          	auipc	a0,0x24
    800044d0:	eec50513          	addi	a0,a0,-276 # 800283b8 <ftable>
    800044d4:	ffffc097          	auipc	ra,0xffffc
    800044d8:	7c4080e7          	jalr	1988(ra) # 80000c98 <release>
	return f;
}
    800044dc:	8526                	mv	a0,s1
    800044de:	60e2                	ld	ra,24(sp)
    800044e0:	6442                	ld	s0,16(sp)
    800044e2:	64a2                	ld	s1,8(sp)
    800044e4:	6105                	addi	sp,sp,32
    800044e6:	8082                	ret
		panic("filedup");
    800044e8:	00004517          	auipc	a0,0x4
    800044ec:	1a850513          	addi	a0,a0,424 # 80008690 <syscalls+0x240>
    800044f0:	ffffc097          	auipc	ra,0xffffc
    800044f4:	04e080e7          	jalr	78(ra) # 8000053e <panic>

00000000800044f8 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    800044f8:	7139                	addi	sp,sp,-64
    800044fa:	fc06                	sd	ra,56(sp)
    800044fc:	f822                	sd	s0,48(sp)
    800044fe:	f426                	sd	s1,40(sp)
    80004500:	f04a                	sd	s2,32(sp)
    80004502:	ec4e                	sd	s3,24(sp)
    80004504:	e852                	sd	s4,16(sp)
    80004506:	e456                	sd	s5,8(sp)
    80004508:	0080                	addi	s0,sp,64
    8000450a:	84aa                	mv	s1,a0
	struct file ff;

	acquire(&ftable.lock);
    8000450c:	00024517          	auipc	a0,0x24
    80004510:	eac50513          	addi	a0,a0,-340 # 800283b8 <ftable>
    80004514:	ffffc097          	auipc	ra,0xffffc
    80004518:	6d0080e7          	jalr	1744(ra) # 80000be4 <acquire>
	if(f->ref < 1)
    8000451c:	40dc                	lw	a5,4(s1)
    8000451e:	06f05163          	blez	a5,80004580 <fileclose+0x88>
		panic("fileclose");
	if(--f->ref > 0){
    80004522:	37fd                	addiw	a5,a5,-1
    80004524:	0007871b          	sext.w	a4,a5
    80004528:	c0dc                	sw	a5,4(s1)
    8000452a:	06e04363          	bgtz	a4,80004590 <fileclose+0x98>
		release(&ftable.lock);
		return;
	}
	ff = *f;
    8000452e:	0004a903          	lw	s2,0(s1)
    80004532:	0094ca83          	lbu	s5,9(s1)
    80004536:	0104ba03          	ld	s4,16(s1)
    8000453a:	0184b983          	ld	s3,24(s1)
	f->ref = 0;
    8000453e:	0004a223          	sw	zero,4(s1)
	f->type = FD_NONE;
    80004542:	0004a023          	sw	zero,0(s1)
	release(&ftable.lock);
    80004546:	00024517          	auipc	a0,0x24
    8000454a:	e7250513          	addi	a0,a0,-398 # 800283b8 <ftable>
    8000454e:	ffffc097          	auipc	ra,0xffffc
    80004552:	74a080e7          	jalr	1866(ra) # 80000c98 <release>

	if(ff.type == FD_PIPE){
    80004556:	4785                	li	a5,1
    80004558:	04f90d63          	beq	s2,a5,800045b2 <fileclose+0xba>
		pipeclose(ff.pipe, ff.writable);
	} else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    8000455c:	3979                	addiw	s2,s2,-2
    8000455e:	4785                	li	a5,1
    80004560:	0527e063          	bltu	a5,s2,800045a0 <fileclose+0xa8>
		begin_op();
    80004564:	00000097          	auipc	ra,0x0
    80004568:	ac8080e7          	jalr	-1336(ra) # 8000402c <begin_op>
		iput(ff.ip);
    8000456c:	854e                	mv	a0,s3
    8000456e:	fffff097          	auipc	ra,0xfffff
    80004572:	2a6080e7          	jalr	678(ra) # 80003814 <iput>
		end_op();
    80004576:	00000097          	auipc	ra,0x0
    8000457a:	b36080e7          	jalr	-1226(ra) # 800040ac <end_op>
    8000457e:	a00d                	j	800045a0 <fileclose+0xa8>
		panic("fileclose");
    80004580:	00004517          	auipc	a0,0x4
    80004584:	11850513          	addi	a0,a0,280 # 80008698 <syscalls+0x248>
    80004588:	ffffc097          	auipc	ra,0xffffc
    8000458c:	fb6080e7          	jalr	-74(ra) # 8000053e <panic>
		release(&ftable.lock);
    80004590:	00024517          	auipc	a0,0x24
    80004594:	e2850513          	addi	a0,a0,-472 # 800283b8 <ftable>
    80004598:	ffffc097          	auipc	ra,0xffffc
    8000459c:	700080e7          	jalr	1792(ra) # 80000c98 <release>
	}
}
    800045a0:	70e2                	ld	ra,56(sp)
    800045a2:	7442                	ld	s0,48(sp)
    800045a4:	74a2                	ld	s1,40(sp)
    800045a6:	7902                	ld	s2,32(sp)
    800045a8:	69e2                	ld	s3,24(sp)
    800045aa:	6a42                	ld	s4,16(sp)
    800045ac:	6aa2                	ld	s5,8(sp)
    800045ae:	6121                	addi	sp,sp,64
    800045b0:	8082                	ret
		pipeclose(ff.pipe, ff.writable);
    800045b2:	85d6                	mv	a1,s5
    800045b4:	8552                	mv	a0,s4
    800045b6:	00000097          	auipc	ra,0x0
    800045ba:	34c080e7          	jalr	844(ra) # 80004902 <pipeclose>
    800045be:	b7cd                	j	800045a0 <fileclose+0xa8>

00000000800045c0 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    800045c0:	715d                	addi	sp,sp,-80
    800045c2:	e486                	sd	ra,72(sp)
    800045c4:	e0a2                	sd	s0,64(sp)
    800045c6:	fc26                	sd	s1,56(sp)
    800045c8:	f84a                	sd	s2,48(sp)
    800045ca:	f44e                	sd	s3,40(sp)
    800045cc:	0880                	addi	s0,sp,80
    800045ce:	84aa                	mv	s1,a0
    800045d0:	89ae                	mv	s3,a1
	struct proc *p = myproc();
    800045d2:	ffffd097          	auipc	ra,0xffffd
    800045d6:	46a080e7          	jalr	1130(ra) # 80001a3c <myproc>
	struct stat st;

	if(f->type == FD_INODE || f->type == FD_DEVICE){
    800045da:	409c                	lw	a5,0(s1)
    800045dc:	37f9                	addiw	a5,a5,-2
    800045de:	4705                	li	a4,1
    800045e0:	04f76763          	bltu	a4,a5,8000462e <filestat+0x6e>
    800045e4:	892a                	mv	s2,a0
		ilock(f->ip);
    800045e6:	6c88                	ld	a0,24(s1)
    800045e8:	fffff097          	auipc	ra,0xfffff
    800045ec:	072080e7          	jalr	114(ra) # 8000365a <ilock>
		stati(f->ip, &st);
    800045f0:	fb840593          	addi	a1,s0,-72
    800045f4:	6c88                	ld	a0,24(s1)
    800045f6:	fffff097          	auipc	ra,0xfffff
    800045fa:	2ee080e7          	jalr	750(ra) # 800038e4 <stati>
		iunlock(f->ip);
    800045fe:	6c88                	ld	a0,24(s1)
    80004600:	fffff097          	auipc	ra,0xfffff
    80004604:	11c080e7          	jalr	284(ra) # 8000371c <iunlock>
		if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004608:	46e1                	li	a3,24
    8000460a:	fb840613          	addi	a2,s0,-72
    8000460e:	85ce                	mv	a1,s3
    80004610:	05093503          	ld	a0,80(s2)
    80004614:	ffffd097          	auipc	ra,0xffffd
    80004618:	06e080e7          	jalr	110(ra) # 80001682 <copyout>
    8000461c:	41f5551b          	sraiw	a0,a0,0x1f
			return -1;
		return 0;
	}
	return -1;
}
    80004620:	60a6                	ld	ra,72(sp)
    80004622:	6406                	ld	s0,64(sp)
    80004624:	74e2                	ld	s1,56(sp)
    80004626:	7942                	ld	s2,48(sp)
    80004628:	79a2                	ld	s3,40(sp)
    8000462a:	6161                	addi	sp,sp,80
    8000462c:	8082                	ret
	return -1;
    8000462e:	557d                	li	a0,-1
    80004630:	bfc5                	j	80004620 <filestat+0x60>

0000000080004632 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004632:	7179                	addi	sp,sp,-48
    80004634:	f406                	sd	ra,40(sp)
    80004636:	f022                	sd	s0,32(sp)
    80004638:	ec26                	sd	s1,24(sp)
    8000463a:	e84a                	sd	s2,16(sp)
    8000463c:	e44e                	sd	s3,8(sp)
    8000463e:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004640:	00854783          	lbu	a5,8(a0)
    80004644:	c3d5                	beqz	a5,800046e8 <fileread+0xb6>
    80004646:	84aa                	mv	s1,a0
    80004648:	89ae                	mv	s3,a1
    8000464a:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    8000464c:	411c                	lw	a5,0(a0)
    8000464e:	4705                	li	a4,1
    80004650:	04e78963          	beq	a5,a4,800046a2 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004654:	470d                	li	a4,3
    80004656:	04e78d63          	beq	a5,a4,800046b0 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    8000465a:	4709                	li	a4,2
    8000465c:	06e79e63          	bne	a5,a4,800046d8 <fileread+0xa6>
    ilock(f->ip);
    80004660:	6d08                	ld	a0,24(a0)
    80004662:	fffff097          	auipc	ra,0xfffff
    80004666:	ff8080e7          	jalr	-8(ra) # 8000365a <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    8000466a:	874a                	mv	a4,s2
    8000466c:	5094                	lw	a3,32(s1)
    8000466e:	864e                	mv	a2,s3
    80004670:	4585                	li	a1,1
    80004672:	6c88                	ld	a0,24(s1)
    80004674:	fffff097          	auipc	ra,0xfffff
    80004678:	29a080e7          	jalr	666(ra) # 8000390e <readi>
    8000467c:	892a                	mv	s2,a0
    8000467e:	00a05563          	blez	a0,80004688 <fileread+0x56>
      f->off += r;
    80004682:	509c                	lw	a5,32(s1)
    80004684:	9fa9                	addw	a5,a5,a0
    80004686:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004688:	6c88                	ld	a0,24(s1)
    8000468a:	fffff097          	auipc	ra,0xfffff
    8000468e:	092080e7          	jalr	146(ra) # 8000371c <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004692:	854a                	mv	a0,s2
    80004694:	70a2                	ld	ra,40(sp)
    80004696:	7402                	ld	s0,32(sp)
    80004698:	64e2                	ld	s1,24(sp)
    8000469a:	6942                	ld	s2,16(sp)
    8000469c:	69a2                	ld	s3,8(sp)
    8000469e:	6145                	addi	sp,sp,48
    800046a0:	8082                	ret
    r = piperead(f->pipe, addr, n);
    800046a2:	6908                	ld	a0,16(a0)
    800046a4:	00000097          	auipc	ra,0x0
    800046a8:	3c8080e7          	jalr	968(ra) # 80004a6c <piperead>
    800046ac:	892a                	mv	s2,a0
    800046ae:	b7d5                	j	80004692 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    800046b0:	02451783          	lh	a5,36(a0)
    800046b4:	03079693          	slli	a3,a5,0x30
    800046b8:	92c1                	srli	a3,a3,0x30
    800046ba:	4725                	li	a4,9
    800046bc:	02d76863          	bltu	a4,a3,800046ec <fileread+0xba>
    800046c0:	0792                	slli	a5,a5,0x4
    800046c2:	00024717          	auipc	a4,0x24
    800046c6:	c5670713          	addi	a4,a4,-938 # 80028318 <devsw>
    800046ca:	97ba                	add	a5,a5,a4
    800046cc:	639c                	ld	a5,0(a5)
    800046ce:	c38d                	beqz	a5,800046f0 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    800046d0:	4505                	li	a0,1
    800046d2:	9782                	jalr	a5
    800046d4:	892a                	mv	s2,a0
    800046d6:	bf75                	j	80004692 <fileread+0x60>
    panic("fileread");
    800046d8:	00004517          	auipc	a0,0x4
    800046dc:	fd050513          	addi	a0,a0,-48 # 800086a8 <syscalls+0x258>
    800046e0:	ffffc097          	auipc	ra,0xffffc
    800046e4:	e5e080e7          	jalr	-418(ra) # 8000053e <panic>
    return -1;
    800046e8:	597d                	li	s2,-1
    800046ea:	b765                	j	80004692 <fileread+0x60>
      return -1;
    800046ec:	597d                	li	s2,-1
    800046ee:	b755                	j	80004692 <fileread+0x60>
    800046f0:	597d                	li	s2,-1
    800046f2:	b745                	j	80004692 <fileread+0x60>

00000000800046f4 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    800046f4:	715d                	addi	sp,sp,-80
    800046f6:	e486                	sd	ra,72(sp)
    800046f8:	e0a2                	sd	s0,64(sp)
    800046fa:	fc26                	sd	s1,56(sp)
    800046fc:	f84a                	sd	s2,48(sp)
    800046fe:	f44e                	sd	s3,40(sp)
    80004700:	f052                	sd	s4,32(sp)
    80004702:	ec56                	sd	s5,24(sp)
    80004704:	e85a                	sd	s6,16(sp)
    80004706:	e45e                	sd	s7,8(sp)
    80004708:	e062                	sd	s8,0(sp)
    8000470a:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    8000470c:	00954783          	lbu	a5,9(a0)
    80004710:	10078663          	beqz	a5,8000481c <filewrite+0x128>
    80004714:	892a                	mv	s2,a0
    80004716:	8aae                	mv	s5,a1
    80004718:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    8000471a:	411c                	lw	a5,0(a0)
    8000471c:	4705                	li	a4,1
    8000471e:	02e78263          	beq	a5,a4,80004742 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004722:	470d                	li	a4,3
    80004724:	02e78663          	beq	a5,a4,80004750 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004728:	4709                	li	a4,2
    8000472a:	0ee79163          	bne	a5,a4,8000480c <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    8000472e:	0ac05d63          	blez	a2,800047e8 <filewrite+0xf4>
    int i = 0;
    80004732:	4981                	li	s3,0
    80004734:	6b05                	lui	s6,0x1
    80004736:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    8000473a:	6b85                	lui	s7,0x1
    8000473c:	c00b8b9b          	addiw	s7,s7,-1024
    80004740:	a861                	j	800047d8 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004742:	6908                	ld	a0,16(a0)
    80004744:	00000097          	auipc	ra,0x0
    80004748:	22e080e7          	jalr	558(ra) # 80004972 <pipewrite>
    8000474c:	8a2a                	mv	s4,a0
    8000474e:	a045                	j	800047ee <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004750:	02451783          	lh	a5,36(a0)
    80004754:	03079693          	slli	a3,a5,0x30
    80004758:	92c1                	srli	a3,a3,0x30
    8000475a:	4725                	li	a4,9
    8000475c:	0cd76263          	bltu	a4,a3,80004820 <filewrite+0x12c>
    80004760:	0792                	slli	a5,a5,0x4
    80004762:	00024717          	auipc	a4,0x24
    80004766:	bb670713          	addi	a4,a4,-1098 # 80028318 <devsw>
    8000476a:	97ba                	add	a5,a5,a4
    8000476c:	679c                	ld	a5,8(a5)
    8000476e:	cbdd                	beqz	a5,80004824 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004770:	4505                	li	a0,1
    80004772:	9782                	jalr	a5
    80004774:	8a2a                	mv	s4,a0
    80004776:	a8a5                	j	800047ee <filewrite+0xfa>
    80004778:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    8000477c:	00000097          	auipc	ra,0x0
    80004780:	8b0080e7          	jalr	-1872(ra) # 8000402c <begin_op>
      ilock(f->ip);
    80004784:	01893503          	ld	a0,24(s2)
    80004788:	fffff097          	auipc	ra,0xfffff
    8000478c:	ed2080e7          	jalr	-302(ra) # 8000365a <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004790:	8762                	mv	a4,s8
    80004792:	02092683          	lw	a3,32(s2)
    80004796:	01598633          	add	a2,s3,s5
    8000479a:	4585                	li	a1,1
    8000479c:	01893503          	ld	a0,24(s2)
    800047a0:	fffff097          	auipc	ra,0xfffff
    800047a4:	266080e7          	jalr	614(ra) # 80003a06 <writei>
    800047a8:	84aa                	mv	s1,a0
    800047aa:	00a05763          	blez	a0,800047b8 <filewrite+0xc4>
        f->off += r;
    800047ae:	02092783          	lw	a5,32(s2)
    800047b2:	9fa9                	addw	a5,a5,a0
    800047b4:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    800047b8:	01893503          	ld	a0,24(s2)
    800047bc:	fffff097          	auipc	ra,0xfffff
    800047c0:	f60080e7          	jalr	-160(ra) # 8000371c <iunlock>
      end_op();
    800047c4:	00000097          	auipc	ra,0x0
    800047c8:	8e8080e7          	jalr	-1816(ra) # 800040ac <end_op>

      if(r != n1){
    800047cc:	009c1f63          	bne	s8,s1,800047ea <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    800047d0:	013489bb          	addw	s3,s1,s3
    while(i < n){
    800047d4:	0149db63          	bge	s3,s4,800047ea <filewrite+0xf6>
      int n1 = n - i;
    800047d8:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    800047dc:	84be                	mv	s1,a5
    800047de:	2781                	sext.w	a5,a5
    800047e0:	f8fb5ce3          	bge	s6,a5,80004778 <filewrite+0x84>
    800047e4:	84de                	mv	s1,s7
    800047e6:	bf49                	j	80004778 <filewrite+0x84>
    int i = 0;
    800047e8:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    800047ea:	013a1f63          	bne	s4,s3,80004808 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    800047ee:	8552                	mv	a0,s4
    800047f0:	60a6                	ld	ra,72(sp)
    800047f2:	6406                	ld	s0,64(sp)
    800047f4:	74e2                	ld	s1,56(sp)
    800047f6:	7942                	ld	s2,48(sp)
    800047f8:	79a2                	ld	s3,40(sp)
    800047fa:	7a02                	ld	s4,32(sp)
    800047fc:	6ae2                	ld	s5,24(sp)
    800047fe:	6b42                	ld	s6,16(sp)
    80004800:	6ba2                	ld	s7,8(sp)
    80004802:	6c02                	ld	s8,0(sp)
    80004804:	6161                	addi	sp,sp,80
    80004806:	8082                	ret
    ret = (i == n ? n : -1);
    80004808:	5a7d                	li	s4,-1
    8000480a:	b7d5                	j	800047ee <filewrite+0xfa>
    panic("filewrite");
    8000480c:	00004517          	auipc	a0,0x4
    80004810:	eac50513          	addi	a0,a0,-340 # 800086b8 <syscalls+0x268>
    80004814:	ffffc097          	auipc	ra,0xffffc
    80004818:	d2a080e7          	jalr	-726(ra) # 8000053e <panic>
    return -1;
    8000481c:	5a7d                	li	s4,-1
    8000481e:	bfc1                	j	800047ee <filewrite+0xfa>
      return -1;
    80004820:	5a7d                	li	s4,-1
    80004822:	b7f1                	j	800047ee <filewrite+0xfa>
    80004824:	5a7d                	li	s4,-1
    80004826:	b7e1                	j	800047ee <filewrite+0xfa>

0000000080004828 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004828:	7179                	addi	sp,sp,-48
    8000482a:	f406                	sd	ra,40(sp)
    8000482c:	f022                	sd	s0,32(sp)
    8000482e:	ec26                	sd	s1,24(sp)
    80004830:	e84a                	sd	s2,16(sp)
    80004832:	e44e                	sd	s3,8(sp)
    80004834:	e052                	sd	s4,0(sp)
    80004836:	1800                	addi	s0,sp,48
    80004838:	84aa                	mv	s1,a0
    8000483a:	8a2e                	mv	s4,a1
	struct pipe *pi;

	pi = 0;
	*f0 = *f1 = 0;
    8000483c:	0005b023          	sd	zero,0(a1)
    80004840:	00053023          	sd	zero,0(a0)
	if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004844:	00000097          	auipc	ra,0x0
    80004848:	bf8080e7          	jalr	-1032(ra) # 8000443c <filealloc>
    8000484c:	e088                	sd	a0,0(s1)
    8000484e:	c551                	beqz	a0,800048da <pipealloc+0xb2>
    80004850:	00000097          	auipc	ra,0x0
    80004854:	bec080e7          	jalr	-1044(ra) # 8000443c <filealloc>
    80004858:	00aa3023          	sd	a0,0(s4)
    8000485c:	c92d                	beqz	a0,800048ce <pipealloc+0xa6>
		goto bad;
	if((pi = (struct pipe*)kalloc()) == 0)
    8000485e:	ffffc097          	auipc	ra,0xffffc
    80004862:	296080e7          	jalr	662(ra) # 80000af4 <kalloc>
    80004866:	892a                	mv	s2,a0
    80004868:	c125                	beqz	a0,800048c8 <pipealloc+0xa0>
		goto bad;
	pi->readopen = 1;
    8000486a:	4985                	li	s3,1
    8000486c:	23352023          	sw	s3,544(a0)
	pi->writeopen = 1;
    80004870:	23352223          	sw	s3,548(a0)
	pi->nwrite = 0;
    80004874:	20052e23          	sw	zero,540(a0)
	pi->nread = 0;
    80004878:	20052c23          	sw	zero,536(a0)
	initlock(&pi->lock, "pipe");
    8000487c:	00004597          	auipc	a1,0x4
    80004880:	e4c58593          	addi	a1,a1,-436 # 800086c8 <syscalls+0x278>
    80004884:	ffffc097          	auipc	ra,0xffffc
    80004888:	2d0080e7          	jalr	720(ra) # 80000b54 <initlock>
	(*f0)->type = FD_PIPE;
    8000488c:	609c                	ld	a5,0(s1)
    8000488e:	0137a023          	sw	s3,0(a5)
	(*f0)->readable = 1;
    80004892:	609c                	ld	a5,0(s1)
    80004894:	01378423          	sb	s3,8(a5)
	(*f0)->writable = 0;
    80004898:	609c                	ld	a5,0(s1)
    8000489a:	000784a3          	sb	zero,9(a5)
	(*f0)->pipe = pi;
    8000489e:	609c                	ld	a5,0(s1)
    800048a0:	0127b823          	sd	s2,16(a5)
	(*f1)->type = FD_PIPE;
    800048a4:	000a3783          	ld	a5,0(s4)
    800048a8:	0137a023          	sw	s3,0(a5)
	(*f1)->readable = 0;
    800048ac:	000a3783          	ld	a5,0(s4)
    800048b0:	00078423          	sb	zero,8(a5)
	(*f1)->writable = 1;
    800048b4:	000a3783          	ld	a5,0(s4)
    800048b8:	013784a3          	sb	s3,9(a5)
	(*f1)->pipe = pi;
    800048bc:	000a3783          	ld	a5,0(s4)
    800048c0:	0127b823          	sd	s2,16(a5)
	return 0;
    800048c4:	4501                	li	a0,0
    800048c6:	a025                	j	800048ee <pipealloc+0xc6>

bad:
	if(pi)
		kfree((char*)pi);
	if(*f0)
    800048c8:	6088                	ld	a0,0(s1)
    800048ca:	e501                	bnez	a0,800048d2 <pipealloc+0xaa>
    800048cc:	a039                	j	800048da <pipealloc+0xb2>
    800048ce:	6088                	ld	a0,0(s1)
    800048d0:	c51d                	beqz	a0,800048fe <pipealloc+0xd6>
		fileclose(*f0);
    800048d2:	00000097          	auipc	ra,0x0
    800048d6:	c26080e7          	jalr	-986(ra) # 800044f8 <fileclose>
	if(*f1)
    800048da:	000a3783          	ld	a5,0(s4)
		fileclose(*f1);
	return -1;
    800048de:	557d                	li	a0,-1
	if(*f1)
    800048e0:	c799                	beqz	a5,800048ee <pipealloc+0xc6>
		fileclose(*f1);
    800048e2:	853e                	mv	a0,a5
    800048e4:	00000097          	auipc	ra,0x0
    800048e8:	c14080e7          	jalr	-1004(ra) # 800044f8 <fileclose>
	return -1;
    800048ec:	557d                	li	a0,-1
}
    800048ee:	70a2                	ld	ra,40(sp)
    800048f0:	7402                	ld	s0,32(sp)
    800048f2:	64e2                	ld	s1,24(sp)
    800048f4:	6942                	ld	s2,16(sp)
    800048f6:	69a2                	ld	s3,8(sp)
    800048f8:	6a02                	ld	s4,0(sp)
    800048fa:	6145                	addi	sp,sp,48
    800048fc:	8082                	ret
	return -1;
    800048fe:	557d                	li	a0,-1
    80004900:	b7fd                	j	800048ee <pipealloc+0xc6>

0000000080004902 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004902:	1101                	addi	sp,sp,-32
    80004904:	ec06                	sd	ra,24(sp)
    80004906:	e822                	sd	s0,16(sp)
    80004908:	e426                	sd	s1,8(sp)
    8000490a:	e04a                	sd	s2,0(sp)
    8000490c:	1000                	addi	s0,sp,32
    8000490e:	84aa                	mv	s1,a0
    80004910:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004912:	ffffc097          	auipc	ra,0xffffc
    80004916:	2d2080e7          	jalr	722(ra) # 80000be4 <acquire>
  if(writable){
    8000491a:	02090d63          	beqz	s2,80004954 <pipeclose+0x52>
    pi->writeopen = 0;
    8000491e:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004922:	21848513          	addi	a0,s1,536
    80004926:	ffffe097          	auipc	ra,0xffffe
    8000492a:	95e080e7          	jalr	-1698(ra) # 80002284 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    8000492e:	2204b783          	ld	a5,544(s1)
    80004932:	eb95                	bnez	a5,80004966 <pipeclose+0x64>
    release(&pi->lock);
    80004934:	8526                	mv	a0,s1
    80004936:	ffffc097          	auipc	ra,0xffffc
    8000493a:	362080e7          	jalr	866(ra) # 80000c98 <release>
    kfree((char*)pi);
    8000493e:	8526                	mv	a0,s1
    80004940:	ffffc097          	auipc	ra,0xffffc
    80004944:	0b8080e7          	jalr	184(ra) # 800009f8 <kfree>
  } else
    release(&pi->lock);
}
    80004948:	60e2                	ld	ra,24(sp)
    8000494a:	6442                	ld	s0,16(sp)
    8000494c:	64a2                	ld	s1,8(sp)
    8000494e:	6902                	ld	s2,0(sp)
    80004950:	6105                	addi	sp,sp,32
    80004952:	8082                	ret
    pi->readopen = 0;
    80004954:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004958:	21c48513          	addi	a0,s1,540
    8000495c:	ffffe097          	auipc	ra,0xffffe
    80004960:	928080e7          	jalr	-1752(ra) # 80002284 <wakeup>
    80004964:	b7e9                	j	8000492e <pipeclose+0x2c>
    release(&pi->lock);
    80004966:	8526                	mv	a0,s1
    80004968:	ffffc097          	auipc	ra,0xffffc
    8000496c:	330080e7          	jalr	816(ra) # 80000c98 <release>
}
    80004970:	bfe1                	j	80004948 <pipeclose+0x46>

0000000080004972 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004972:	7159                	addi	sp,sp,-112
    80004974:	f486                	sd	ra,104(sp)
    80004976:	f0a2                	sd	s0,96(sp)
    80004978:	eca6                	sd	s1,88(sp)
    8000497a:	e8ca                	sd	s2,80(sp)
    8000497c:	e4ce                	sd	s3,72(sp)
    8000497e:	e0d2                	sd	s4,64(sp)
    80004980:	fc56                	sd	s5,56(sp)
    80004982:	f85a                	sd	s6,48(sp)
    80004984:	f45e                	sd	s7,40(sp)
    80004986:	f062                	sd	s8,32(sp)
    80004988:	ec66                	sd	s9,24(sp)
    8000498a:	1880                	addi	s0,sp,112
    8000498c:	84aa                	mv	s1,a0
    8000498e:	8aae                	mv	s5,a1
    80004990:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004992:	ffffd097          	auipc	ra,0xffffd
    80004996:	0aa080e7          	jalr	170(ra) # 80001a3c <myproc>
    8000499a:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    8000499c:	8526                	mv	a0,s1
    8000499e:	ffffc097          	auipc	ra,0xffffc
    800049a2:	246080e7          	jalr	582(ra) # 80000be4 <acquire>
  while(i < n){
    800049a6:	0d405163          	blez	s4,80004a68 <pipewrite+0xf6>
    800049aa:	8ba6                	mv	s7,s1
  int i = 0;
    800049ac:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    800049ae:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    800049b0:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    800049b4:	21c48c13          	addi	s8,s1,540
    800049b8:	a08d                	j	80004a1a <pipewrite+0xa8>
      release(&pi->lock);
    800049ba:	8526                	mv	a0,s1
    800049bc:	ffffc097          	auipc	ra,0xffffc
    800049c0:	2dc080e7          	jalr	732(ra) # 80000c98 <release>
      return -1;
    800049c4:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    800049c6:	854a                	mv	a0,s2
    800049c8:	70a6                	ld	ra,104(sp)
    800049ca:	7406                	ld	s0,96(sp)
    800049cc:	64e6                	ld	s1,88(sp)
    800049ce:	6946                	ld	s2,80(sp)
    800049d0:	69a6                	ld	s3,72(sp)
    800049d2:	6a06                	ld	s4,64(sp)
    800049d4:	7ae2                	ld	s5,56(sp)
    800049d6:	7b42                	ld	s6,48(sp)
    800049d8:	7ba2                	ld	s7,40(sp)
    800049da:	7c02                	ld	s8,32(sp)
    800049dc:	6ce2                	ld	s9,24(sp)
    800049de:	6165                	addi	sp,sp,112
    800049e0:	8082                	ret
      wakeup(&pi->nread);
    800049e2:	8566                	mv	a0,s9
    800049e4:	ffffe097          	auipc	ra,0xffffe
    800049e8:	8a0080e7          	jalr	-1888(ra) # 80002284 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    800049ec:	85de                	mv	a1,s7
    800049ee:	8562                	mv	a0,s8
    800049f0:	ffffd097          	auipc	ra,0xffffd
    800049f4:	708080e7          	jalr	1800(ra) # 800020f8 <sleep>
    800049f8:	a839                	j	80004a16 <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    800049fa:	21c4a783          	lw	a5,540(s1)
    800049fe:	0017871b          	addiw	a4,a5,1
    80004a02:	20e4ae23          	sw	a4,540(s1)
    80004a06:	1ff7f793          	andi	a5,a5,511
    80004a0a:	97a6                	add	a5,a5,s1
    80004a0c:	f9f44703          	lbu	a4,-97(s0)
    80004a10:	00e78c23          	sb	a4,24(a5)
      i++;
    80004a14:	2905                	addiw	s2,s2,1
  while(i < n){
    80004a16:	03495d63          	bge	s2,s4,80004a50 <pipewrite+0xde>
    if(pi->readopen == 0 || pr->killed){
    80004a1a:	2204a783          	lw	a5,544(s1)
    80004a1e:	dfd1                	beqz	a5,800049ba <pipewrite+0x48>
    80004a20:	0289a783          	lw	a5,40(s3)
    80004a24:	fbd9                	bnez	a5,800049ba <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004a26:	2184a783          	lw	a5,536(s1)
    80004a2a:	21c4a703          	lw	a4,540(s1)
    80004a2e:	2007879b          	addiw	a5,a5,512
    80004a32:	faf708e3          	beq	a4,a5,800049e2 <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004a36:	4685                	li	a3,1
    80004a38:	01590633          	add	a2,s2,s5
    80004a3c:	f9f40593          	addi	a1,s0,-97
    80004a40:	0509b503          	ld	a0,80(s3)
    80004a44:	ffffd097          	auipc	ra,0xffffd
    80004a48:	cca080e7          	jalr	-822(ra) # 8000170e <copyin>
    80004a4c:	fb6517e3          	bne	a0,s6,800049fa <pipewrite+0x88>
  wakeup(&pi->nread);
    80004a50:	21848513          	addi	a0,s1,536
    80004a54:	ffffe097          	auipc	ra,0xffffe
    80004a58:	830080e7          	jalr	-2000(ra) # 80002284 <wakeup>
  release(&pi->lock);
    80004a5c:	8526                	mv	a0,s1
    80004a5e:	ffffc097          	auipc	ra,0xffffc
    80004a62:	23a080e7          	jalr	570(ra) # 80000c98 <release>
  return i;
    80004a66:	b785                	j	800049c6 <pipewrite+0x54>
  int i = 0;
    80004a68:	4901                	li	s2,0
    80004a6a:	b7dd                	j	80004a50 <pipewrite+0xde>

0000000080004a6c <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004a6c:	715d                	addi	sp,sp,-80
    80004a6e:	e486                	sd	ra,72(sp)
    80004a70:	e0a2                	sd	s0,64(sp)
    80004a72:	fc26                	sd	s1,56(sp)
    80004a74:	f84a                	sd	s2,48(sp)
    80004a76:	f44e                	sd	s3,40(sp)
    80004a78:	f052                	sd	s4,32(sp)
    80004a7a:	ec56                	sd	s5,24(sp)
    80004a7c:	e85a                	sd	s6,16(sp)
    80004a7e:	0880                	addi	s0,sp,80
    80004a80:	84aa                	mv	s1,a0
    80004a82:	892e                	mv	s2,a1
    80004a84:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004a86:	ffffd097          	auipc	ra,0xffffd
    80004a8a:	fb6080e7          	jalr	-74(ra) # 80001a3c <myproc>
    80004a8e:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004a90:	8b26                	mv	s6,s1
    80004a92:	8526                	mv	a0,s1
    80004a94:	ffffc097          	auipc	ra,0xffffc
    80004a98:	150080e7          	jalr	336(ra) # 80000be4 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004a9c:	2184a703          	lw	a4,536(s1)
    80004aa0:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004aa4:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004aa8:	02f71463          	bne	a4,a5,80004ad0 <piperead+0x64>
    80004aac:	2244a783          	lw	a5,548(s1)
    80004ab0:	c385                	beqz	a5,80004ad0 <piperead+0x64>
    if(pr->killed){
    80004ab2:	028a2783          	lw	a5,40(s4)
    80004ab6:	ebc1                	bnez	a5,80004b46 <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004ab8:	85da                	mv	a1,s6
    80004aba:	854e                	mv	a0,s3
    80004abc:	ffffd097          	auipc	ra,0xffffd
    80004ac0:	63c080e7          	jalr	1596(ra) # 800020f8 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004ac4:	2184a703          	lw	a4,536(s1)
    80004ac8:	21c4a783          	lw	a5,540(s1)
    80004acc:	fef700e3          	beq	a4,a5,80004aac <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004ad0:	09505263          	blez	s5,80004b54 <piperead+0xe8>
    80004ad4:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004ad6:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80004ad8:	2184a783          	lw	a5,536(s1)
    80004adc:	21c4a703          	lw	a4,540(s1)
    80004ae0:	02f70d63          	beq	a4,a5,80004b1a <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004ae4:	0017871b          	addiw	a4,a5,1
    80004ae8:	20e4ac23          	sw	a4,536(s1)
    80004aec:	1ff7f793          	andi	a5,a5,511
    80004af0:	97a6                	add	a5,a5,s1
    80004af2:	0187c783          	lbu	a5,24(a5)
    80004af6:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004afa:	4685                	li	a3,1
    80004afc:	fbf40613          	addi	a2,s0,-65
    80004b00:	85ca                	mv	a1,s2
    80004b02:	050a3503          	ld	a0,80(s4)
    80004b06:	ffffd097          	auipc	ra,0xffffd
    80004b0a:	b7c080e7          	jalr	-1156(ra) # 80001682 <copyout>
    80004b0e:	01650663          	beq	a0,s6,80004b1a <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004b12:	2985                	addiw	s3,s3,1
    80004b14:	0905                	addi	s2,s2,1
    80004b16:	fd3a91e3          	bne	s5,s3,80004ad8 <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004b1a:	21c48513          	addi	a0,s1,540
    80004b1e:	ffffd097          	auipc	ra,0xffffd
    80004b22:	766080e7          	jalr	1894(ra) # 80002284 <wakeup>
  release(&pi->lock);
    80004b26:	8526                	mv	a0,s1
    80004b28:	ffffc097          	auipc	ra,0xffffc
    80004b2c:	170080e7          	jalr	368(ra) # 80000c98 <release>
  return i;
}
    80004b30:	854e                	mv	a0,s3
    80004b32:	60a6                	ld	ra,72(sp)
    80004b34:	6406                	ld	s0,64(sp)
    80004b36:	74e2                	ld	s1,56(sp)
    80004b38:	7942                	ld	s2,48(sp)
    80004b3a:	79a2                	ld	s3,40(sp)
    80004b3c:	7a02                	ld	s4,32(sp)
    80004b3e:	6ae2                	ld	s5,24(sp)
    80004b40:	6b42                	ld	s6,16(sp)
    80004b42:	6161                	addi	sp,sp,80
    80004b44:	8082                	ret
      release(&pi->lock);
    80004b46:	8526                	mv	a0,s1
    80004b48:	ffffc097          	auipc	ra,0xffffc
    80004b4c:	150080e7          	jalr	336(ra) # 80000c98 <release>
      return -1;
    80004b50:	59fd                	li	s3,-1
    80004b52:	bff9                	j	80004b30 <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004b54:	4981                	li	s3,0
    80004b56:	b7d1                	j	80004b1a <piperead+0xae>

0000000080004b58 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004b58:	df010113          	addi	sp,sp,-528
    80004b5c:	20113423          	sd	ra,520(sp)
    80004b60:	20813023          	sd	s0,512(sp)
    80004b64:	ffa6                	sd	s1,504(sp)
    80004b66:	fbca                	sd	s2,496(sp)
    80004b68:	f7ce                	sd	s3,488(sp)
    80004b6a:	f3d2                	sd	s4,480(sp)
    80004b6c:	efd6                	sd	s5,472(sp)
    80004b6e:	ebda                	sd	s6,464(sp)
    80004b70:	e7de                	sd	s7,456(sp)
    80004b72:	e3e2                	sd	s8,448(sp)
    80004b74:	ff66                	sd	s9,440(sp)
    80004b76:	fb6a                	sd	s10,432(sp)
    80004b78:	f76e                	sd	s11,424(sp)
    80004b7a:	0c00                	addi	s0,sp,528
    80004b7c:	84aa                	mv	s1,a0
    80004b7e:	dea43c23          	sd	a0,-520(s0)
    80004b82:	e0b43023          	sd	a1,-512(s0)
	uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
	struct elfhdr elf;
	struct inode *ip;
	struct proghdr ph;
	pagetable_t pagetable = 0, oldpagetable;
	struct proc *p = myproc();
    80004b86:	ffffd097          	auipc	ra,0xffffd
    80004b8a:	eb6080e7          	jalr	-330(ra) # 80001a3c <myproc>
    80004b8e:	892a                	mv	s2,a0

	begin_op();
    80004b90:	fffff097          	auipc	ra,0xfffff
    80004b94:	49c080e7          	jalr	1180(ra) # 8000402c <begin_op>

	if((ip = namei(path)) == 0){
    80004b98:	8526                	mv	a0,s1
    80004b9a:	fffff097          	auipc	ra,0xfffff
    80004b9e:	276080e7          	jalr	630(ra) # 80003e10 <namei>
    80004ba2:	c92d                	beqz	a0,80004c14 <exec+0xbc>
    80004ba4:	84aa                	mv	s1,a0
		end_op();
		return -1;
	}
	ilock(ip);
    80004ba6:	fffff097          	auipc	ra,0xfffff
    80004baa:	ab4080e7          	jalr	-1356(ra) # 8000365a <ilock>

	// Check ELF header
	if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004bae:	04000713          	li	a4,64
    80004bb2:	4681                	li	a3,0
    80004bb4:	e5040613          	addi	a2,s0,-432
    80004bb8:	4581                	li	a1,0
    80004bba:	8526                	mv	a0,s1
    80004bbc:	fffff097          	auipc	ra,0xfffff
    80004bc0:	d52080e7          	jalr	-686(ra) # 8000390e <readi>
    80004bc4:	04000793          	li	a5,64
    80004bc8:	00f51a63          	bne	a0,a5,80004bdc <exec+0x84>
		goto bad;
	if(elf.magic != ELF_MAGIC)
    80004bcc:	e5042703          	lw	a4,-432(s0)
    80004bd0:	464c47b7          	lui	a5,0x464c4
    80004bd4:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004bd8:	04f70463          	beq	a4,a5,80004c20 <exec+0xc8>

bad:
	if(pagetable)
		proc_freepagetable(pagetable, sz);
	if(ip){
		iunlockput(ip);
    80004bdc:	8526                	mv	a0,s1
    80004bde:	fffff097          	auipc	ra,0xfffff
    80004be2:	cde080e7          	jalr	-802(ra) # 800038bc <iunlockput>
		end_op();
    80004be6:	fffff097          	auipc	ra,0xfffff
    80004bea:	4c6080e7          	jalr	1222(ra) # 800040ac <end_op>
	}
	return -1;
    80004bee:	557d                	li	a0,-1
}
    80004bf0:	20813083          	ld	ra,520(sp)
    80004bf4:	20013403          	ld	s0,512(sp)
    80004bf8:	74fe                	ld	s1,504(sp)
    80004bfa:	795e                	ld	s2,496(sp)
    80004bfc:	79be                	ld	s3,488(sp)
    80004bfe:	7a1e                	ld	s4,480(sp)
    80004c00:	6afe                	ld	s5,472(sp)
    80004c02:	6b5e                	ld	s6,464(sp)
    80004c04:	6bbe                	ld	s7,456(sp)
    80004c06:	6c1e                	ld	s8,448(sp)
    80004c08:	7cfa                	ld	s9,440(sp)
    80004c0a:	7d5a                	ld	s10,432(sp)
    80004c0c:	7dba                	ld	s11,424(sp)
    80004c0e:	21010113          	addi	sp,sp,528
    80004c12:	8082                	ret
		end_op();
    80004c14:	fffff097          	auipc	ra,0xfffff
    80004c18:	498080e7          	jalr	1176(ra) # 800040ac <end_op>
		return -1;
    80004c1c:	557d                	li	a0,-1
    80004c1e:	bfc9                	j	80004bf0 <exec+0x98>
	if((pagetable = proc_pagetable(p)) == 0)
    80004c20:	854a                	mv	a0,s2
    80004c22:	ffffd097          	auipc	ra,0xffffd
    80004c26:	ede080e7          	jalr	-290(ra) # 80001b00 <proc_pagetable>
    80004c2a:	8baa                	mv	s7,a0
    80004c2c:	d945                	beqz	a0,80004bdc <exec+0x84>
	for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004c2e:	e7042983          	lw	s3,-400(s0)
    80004c32:	e8845783          	lhu	a5,-376(s0)
    80004c36:	c7ad                	beqz	a5,80004ca0 <exec+0x148>
	uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004c38:	4901                	li	s2,0
	for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004c3a:	4b01                	li	s6,0
		if((ph.vaddr % PGSIZE) != 0)
    80004c3c:	6ca1                	lui	s9,0x8
    80004c3e:	fffc8793          	addi	a5,s9,-1 # 7fff <_entry-0x7fff8001>
    80004c42:	def43823          	sd	a5,-528(s0)
    80004c46:	a42d                	j	80004e70 <exec+0x318>
	uint64 pa;

	for(i = 0; i < sz; i += PGSIZE){
		pa = walkaddr(pagetable, va + i);
		if(pa == 0)
			panic("loadseg: address should exist");
    80004c48:	00004517          	auipc	a0,0x4
    80004c4c:	a8850513          	addi	a0,a0,-1400 # 800086d0 <syscalls+0x280>
    80004c50:	ffffc097          	auipc	ra,0xffffc
    80004c54:	8ee080e7          	jalr	-1810(ra) # 8000053e <panic>
		if(sz - i < PGSIZE)
			n = sz - i;
		else
			n = PGSIZE;
		if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004c58:	8756                	mv	a4,s5
    80004c5a:	012d86bb          	addw	a3,s11,s2
    80004c5e:	4581                	li	a1,0
    80004c60:	8526                	mv	a0,s1
    80004c62:	fffff097          	auipc	ra,0xfffff
    80004c66:	cac080e7          	jalr	-852(ra) # 8000390e <readi>
    80004c6a:	2501                	sext.w	a0,a0
    80004c6c:	1aaa9963          	bne	s5,a0,80004e1e <exec+0x2c6>
	for(i = 0; i < sz; i += PGSIZE){
    80004c70:	67a1                	lui	a5,0x8
    80004c72:	0127893b          	addw	s2,a5,s2
    80004c76:	77e1                	lui	a5,0xffff8
    80004c78:	01478a3b          	addw	s4,a5,s4
    80004c7c:	1f897163          	bgeu	s2,s8,80004e5e <exec+0x306>
		pa = walkaddr(pagetable, va + i);
    80004c80:	02091593          	slli	a1,s2,0x20
    80004c84:	9181                	srli	a1,a1,0x20
    80004c86:	95ea                	add	a1,a1,s10
    80004c88:	855e                	mv	a0,s7
    80004c8a:	ffffc097          	auipc	ra,0xffffc
    80004c8e:	3e2080e7          	jalr	994(ra) # 8000106c <walkaddr>
    80004c92:	862a                	mv	a2,a0
		if(pa == 0)
    80004c94:	d955                	beqz	a0,80004c48 <exec+0xf0>
			n = PGSIZE;
    80004c96:	8ae6                	mv	s5,s9
		if(sz - i < PGSIZE)
    80004c98:	fd9a70e3          	bgeu	s4,s9,80004c58 <exec+0x100>
			n = sz - i;
    80004c9c:	8ad2                	mv	s5,s4
    80004c9e:	bf6d                	j	80004c58 <exec+0x100>
	uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004ca0:	4901                	li	s2,0
	iunlockput(ip);
    80004ca2:	8526                	mv	a0,s1
    80004ca4:	fffff097          	auipc	ra,0xfffff
    80004ca8:	c18080e7          	jalr	-1000(ra) # 800038bc <iunlockput>
	end_op();
    80004cac:	fffff097          	auipc	ra,0xfffff
    80004cb0:	400080e7          	jalr	1024(ra) # 800040ac <end_op>
	p = myproc();
    80004cb4:	ffffd097          	auipc	ra,0xffffd
    80004cb8:	d88080e7          	jalr	-632(ra) # 80001a3c <myproc>
    80004cbc:	8aaa                	mv	s5,a0
	uint64 oldsz = p->sz;
    80004cbe:	04853d03          	ld	s10,72(a0)
	sz = PGROUNDUP(sz);
    80004cc2:	67a1                	lui	a5,0x8
    80004cc4:	17fd                	addi	a5,a5,-1
    80004cc6:	993e                	add	s2,s2,a5
    80004cc8:	7561                	lui	a0,0xffff8
    80004cca:	00a977b3          	and	a5,s2,a0
    80004cce:	e0f43423          	sd	a5,-504(s0)
	if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004cd2:	6641                	lui	a2,0x10
    80004cd4:	963e                	add	a2,a2,a5
    80004cd6:	85be                	mv	a1,a5
    80004cd8:	855e                	mv	a0,s7
    80004cda:	ffffc097          	auipc	ra,0xffffc
    80004cde:	758080e7          	jalr	1880(ra) # 80001432 <uvmalloc>
    80004ce2:	8b2a                	mv	s6,a0
	ip = 0;
    80004ce4:	4481                	li	s1,0
	if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004ce6:	12050c63          	beqz	a0,80004e1e <exec+0x2c6>
	uvmclear(pagetable, sz-2*PGSIZE);
    80004cea:	75c1                	lui	a1,0xffff0
    80004cec:	95aa                	add	a1,a1,a0
    80004cee:	855e                	mv	a0,s7
    80004cf0:	ffffd097          	auipc	ra,0xffffd
    80004cf4:	960080e7          	jalr	-1696(ra) # 80001650 <uvmclear>
	stackbase = sp - PGSIZE;
    80004cf8:	7c61                	lui	s8,0xffff8
    80004cfa:	9c5a                	add	s8,s8,s6
	for(argc = 0; argv[argc]; argc++) {
    80004cfc:	e0043783          	ld	a5,-512(s0)
    80004d00:	6388                	ld	a0,0(a5)
    80004d02:	c535                	beqz	a0,80004d6e <exec+0x216>
    80004d04:	e9040993          	addi	s3,s0,-368
    80004d08:	f9040c93          	addi	s9,s0,-112
	sp = sz;
    80004d0c:	895a                	mv	s2,s6
		sp -= strlen(argv[argc]) + 1;
    80004d0e:	ffffc097          	auipc	ra,0xffffc
    80004d12:	156080e7          	jalr	342(ra) # 80000e64 <strlen>
    80004d16:	2505                	addiw	a0,a0,1
    80004d18:	40a90933          	sub	s2,s2,a0
		sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004d1c:	ff097913          	andi	s2,s2,-16
		if(sp < stackbase)
    80004d20:	13896363          	bltu	s2,s8,80004e46 <exec+0x2ee>
		if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004d24:	e0043d83          	ld	s11,-512(s0)
    80004d28:	000dba03          	ld	s4,0(s11)
    80004d2c:	8552                	mv	a0,s4
    80004d2e:	ffffc097          	auipc	ra,0xffffc
    80004d32:	136080e7          	jalr	310(ra) # 80000e64 <strlen>
    80004d36:	0015069b          	addiw	a3,a0,1
    80004d3a:	8652                	mv	a2,s4
    80004d3c:	85ca                	mv	a1,s2
    80004d3e:	855e                	mv	a0,s7
    80004d40:	ffffd097          	auipc	ra,0xffffd
    80004d44:	942080e7          	jalr	-1726(ra) # 80001682 <copyout>
    80004d48:	10054363          	bltz	a0,80004e4e <exec+0x2f6>
		ustack[argc] = sp;
    80004d4c:	0129b023          	sd	s2,0(s3)
	for(argc = 0; argv[argc]; argc++) {
    80004d50:	0485                	addi	s1,s1,1
    80004d52:	008d8793          	addi	a5,s11,8
    80004d56:	e0f43023          	sd	a5,-512(s0)
    80004d5a:	008db503          	ld	a0,8(s11)
    80004d5e:	c911                	beqz	a0,80004d72 <exec+0x21a>
		if(argc >= MAXARG)
    80004d60:	09a1                	addi	s3,s3,8
    80004d62:	fb3c96e3          	bne	s9,s3,80004d0e <exec+0x1b6>
	sz = sz1;
    80004d66:	e1643423          	sd	s6,-504(s0)
	ip = 0;
    80004d6a:	4481                	li	s1,0
    80004d6c:	a84d                	j	80004e1e <exec+0x2c6>
	sp = sz;
    80004d6e:	895a                	mv	s2,s6
	for(argc = 0; argv[argc]; argc++) {
    80004d70:	4481                	li	s1,0
	ustack[argc] = 0;
    80004d72:	00349793          	slli	a5,s1,0x3
    80004d76:	f9040713          	addi	a4,s0,-112
    80004d7a:	97ba                	add	a5,a5,a4
    80004d7c:	f007b023          	sd	zero,-256(a5) # 7f00 <_entry-0x7fff8100>
	sp -= (argc+1) * sizeof(uint64);
    80004d80:	00148693          	addi	a3,s1,1
    80004d84:	068e                	slli	a3,a3,0x3
    80004d86:	40d90933          	sub	s2,s2,a3
	sp -= sp % 16;
    80004d8a:	ff097913          	andi	s2,s2,-16
	if(sp < stackbase)
    80004d8e:	01897663          	bgeu	s2,s8,80004d9a <exec+0x242>
	sz = sz1;
    80004d92:	e1643423          	sd	s6,-504(s0)
	ip = 0;
    80004d96:	4481                	li	s1,0
    80004d98:	a059                	j	80004e1e <exec+0x2c6>
	if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004d9a:	e9040613          	addi	a2,s0,-368
    80004d9e:	85ca                	mv	a1,s2
    80004da0:	855e                	mv	a0,s7
    80004da2:	ffffd097          	auipc	ra,0xffffd
    80004da6:	8e0080e7          	jalr	-1824(ra) # 80001682 <copyout>
    80004daa:	0a054663          	bltz	a0,80004e56 <exec+0x2fe>
	p->trapframe->a1 = sp;
    80004dae:	058ab783          	ld	a5,88(s5)
    80004db2:	0727bc23          	sd	s2,120(a5)
	for(last=s=path; *s; s++)
    80004db6:	df843783          	ld	a5,-520(s0)
    80004dba:	0007c703          	lbu	a4,0(a5)
    80004dbe:	cf11                	beqz	a4,80004dda <exec+0x282>
    80004dc0:	0785                	addi	a5,a5,1
		if(*s == '/')
    80004dc2:	02f00693          	li	a3,47
    80004dc6:	a039                	j	80004dd4 <exec+0x27c>
			last = s+1;
    80004dc8:	def43c23          	sd	a5,-520(s0)
	for(last=s=path; *s; s++)
    80004dcc:	0785                	addi	a5,a5,1
    80004dce:	fff7c703          	lbu	a4,-1(a5)
    80004dd2:	c701                	beqz	a4,80004dda <exec+0x282>
		if(*s == '/')
    80004dd4:	fed71ce3          	bne	a4,a3,80004dcc <exec+0x274>
    80004dd8:	bfc5                	j	80004dc8 <exec+0x270>
	safestrcpy(p->name, last, sizeof(p->name));
    80004dda:	4641                	li	a2,16
    80004ddc:	df843583          	ld	a1,-520(s0)
    80004de0:	158a8513          	addi	a0,s5,344
    80004de4:	ffffc097          	auipc	ra,0xffffc
    80004de8:	04e080e7          	jalr	78(ra) # 80000e32 <safestrcpy>
	oldpagetable = p->pagetable;
    80004dec:	050ab503          	ld	a0,80(s5)
	p->pagetable = pagetable;
    80004df0:	057ab823          	sd	s7,80(s5)
	p->sz = sz;
    80004df4:	056ab423          	sd	s6,72(s5)
	p->trapframe->epc = elf.entry;  // initial program counter = main
    80004df8:	058ab783          	ld	a5,88(s5)
    80004dfc:	e6843703          	ld	a4,-408(s0)
    80004e00:	ef98                	sd	a4,24(a5)
	p->trapframe->sp = sp; // initial stack pointer
    80004e02:	058ab783          	ld	a5,88(s5)
    80004e06:	0327b823          	sd	s2,48(a5)
	proc_freepagetable(oldpagetable, oldsz);
    80004e0a:	85ea                	mv	a1,s10
    80004e0c:	ffffd097          	auipc	ra,0xffffd
    80004e10:	d90080e7          	jalr	-624(ra) # 80001b9c <proc_freepagetable>
	return argc; // this ends up in a0, the first argument to main(argc, argv)
    80004e14:	0004851b          	sext.w	a0,s1
    80004e18:	bbe1                	j	80004bf0 <exec+0x98>
    80004e1a:	e1243423          	sd	s2,-504(s0)
		proc_freepagetable(pagetable, sz);
    80004e1e:	e0843583          	ld	a1,-504(s0)
    80004e22:	855e                	mv	a0,s7
    80004e24:	ffffd097          	auipc	ra,0xffffd
    80004e28:	d78080e7          	jalr	-648(ra) # 80001b9c <proc_freepagetable>
	if(ip){
    80004e2c:	da0498e3          	bnez	s1,80004bdc <exec+0x84>
	return -1;
    80004e30:	557d                	li	a0,-1
    80004e32:	bb7d                	j	80004bf0 <exec+0x98>
    80004e34:	e1243423          	sd	s2,-504(s0)
    80004e38:	b7dd                	j	80004e1e <exec+0x2c6>
    80004e3a:	e1243423          	sd	s2,-504(s0)
    80004e3e:	b7c5                	j	80004e1e <exec+0x2c6>
    80004e40:	e1243423          	sd	s2,-504(s0)
    80004e44:	bfe9                	j	80004e1e <exec+0x2c6>
	sz = sz1;
    80004e46:	e1643423          	sd	s6,-504(s0)
	ip = 0;
    80004e4a:	4481                	li	s1,0
    80004e4c:	bfc9                	j	80004e1e <exec+0x2c6>
	sz = sz1;
    80004e4e:	e1643423          	sd	s6,-504(s0)
	ip = 0;
    80004e52:	4481                	li	s1,0
    80004e54:	b7e9                	j	80004e1e <exec+0x2c6>
	sz = sz1;
    80004e56:	e1643423          	sd	s6,-504(s0)
	ip = 0;
    80004e5a:	4481                	li	s1,0
    80004e5c:	b7c9                	j	80004e1e <exec+0x2c6>
		if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80004e5e:	e0843903          	ld	s2,-504(s0)
	for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004e62:	2b05                	addiw	s6,s6,1
    80004e64:	0389899b          	addiw	s3,s3,56
    80004e68:	e8845783          	lhu	a5,-376(s0)
    80004e6c:	e2fb5be3          	bge	s6,a5,80004ca2 <exec+0x14a>
		if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80004e70:	2981                	sext.w	s3,s3
    80004e72:	03800713          	li	a4,56
    80004e76:	86ce                	mv	a3,s3
    80004e78:	e1840613          	addi	a2,s0,-488
    80004e7c:	4581                	li	a1,0
    80004e7e:	8526                	mv	a0,s1
    80004e80:	fffff097          	auipc	ra,0xfffff
    80004e84:	a8e080e7          	jalr	-1394(ra) # 8000390e <readi>
    80004e88:	03800793          	li	a5,56
    80004e8c:	f8f517e3          	bne	a0,a5,80004e1a <exec+0x2c2>
		if(ph.type != ELF_PROG_LOAD)
    80004e90:	e1842783          	lw	a5,-488(s0)
    80004e94:	4705                	li	a4,1
    80004e96:	fce796e3          	bne	a5,a4,80004e62 <exec+0x30a>
		if(ph.memsz < ph.filesz)
    80004e9a:	e4043603          	ld	a2,-448(s0)
    80004e9e:	e3843783          	ld	a5,-456(s0)
    80004ea2:	f8f669e3          	bltu	a2,a5,80004e34 <exec+0x2dc>
		if(ph.vaddr + ph.memsz < ph.vaddr)	// オーバーフロー
    80004ea6:	e2843783          	ld	a5,-472(s0)
    80004eaa:	963e                	add	a2,a2,a5
    80004eac:	f8f667e3          	bltu	a2,a5,80004e3a <exec+0x2e2>
		if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80004eb0:	85ca                	mv	a1,s2
    80004eb2:	855e                	mv	a0,s7
    80004eb4:	ffffc097          	auipc	ra,0xffffc
    80004eb8:	57e080e7          	jalr	1406(ra) # 80001432 <uvmalloc>
    80004ebc:	e0a43423          	sd	a0,-504(s0)
    80004ec0:	d141                	beqz	a0,80004e40 <exec+0x2e8>
		if((ph.vaddr % PGSIZE) != 0)
    80004ec2:	e2843d03          	ld	s10,-472(s0)
    80004ec6:	df043783          	ld	a5,-528(s0)
    80004eca:	00fd77b3          	and	a5,s10,a5
    80004ece:	fba1                	bnez	a5,80004e1e <exec+0x2c6>
		if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80004ed0:	e2042d83          	lw	s11,-480(s0)
    80004ed4:	e3842c03          	lw	s8,-456(s0)
	for(i = 0; i < sz; i += PGSIZE){
    80004ed8:	f80c03e3          	beqz	s8,80004e5e <exec+0x306>
    80004edc:	8a62                	mv	s4,s8
    80004ede:	4901                	li	s2,0
    80004ee0:	b345                	j	80004c80 <exec+0x128>

0000000080004ee2 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80004ee2:	7179                	addi	sp,sp,-48
    80004ee4:	f406                	sd	ra,40(sp)
    80004ee6:	f022                	sd	s0,32(sp)
    80004ee8:	ec26                	sd	s1,24(sp)
    80004eea:	e84a                	sd	s2,16(sp)
    80004eec:	1800                	addi	s0,sp,48
    80004eee:	892e                	mv	s2,a1
    80004ef0:	84b2                	mv	s1,a2
	int fd;
	struct file *f;

	if(argint(n, &fd) < 0)
    80004ef2:	fdc40593          	addi	a1,s0,-36
    80004ef6:	ffffe097          	auipc	ra,0xffffe
    80004efa:	bf2080e7          	jalr	-1038(ra) # 80002ae8 <argint>
    80004efe:	04054063          	bltz	a0,80004f3e <argfd+0x5c>
		return -1;
	if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80004f02:	fdc42703          	lw	a4,-36(s0)
    80004f06:	47bd                	li	a5,15
    80004f08:	02e7ed63          	bltu	a5,a4,80004f42 <argfd+0x60>
    80004f0c:	ffffd097          	auipc	ra,0xffffd
    80004f10:	b30080e7          	jalr	-1232(ra) # 80001a3c <myproc>
    80004f14:	fdc42703          	lw	a4,-36(s0)
    80004f18:	01a70793          	addi	a5,a4,26
    80004f1c:	078e                	slli	a5,a5,0x3
    80004f1e:	953e                	add	a0,a0,a5
    80004f20:	611c                	ld	a5,0(a0)
    80004f22:	c395                	beqz	a5,80004f46 <argfd+0x64>
		return -1;
	if(pfd)
    80004f24:	00090463          	beqz	s2,80004f2c <argfd+0x4a>
		*pfd = fd;
    80004f28:	00e92023          	sw	a4,0(s2)
	if(pf)
		*pf = f;
	return 0;
    80004f2c:	4501                	li	a0,0
	if(pf)
    80004f2e:	c091                	beqz	s1,80004f32 <argfd+0x50>
		*pf = f;
    80004f30:	e09c                	sd	a5,0(s1)
}
    80004f32:	70a2                	ld	ra,40(sp)
    80004f34:	7402                	ld	s0,32(sp)
    80004f36:	64e2                	ld	s1,24(sp)
    80004f38:	6942                	ld	s2,16(sp)
    80004f3a:	6145                	addi	sp,sp,48
    80004f3c:	8082                	ret
		return -1;
    80004f3e:	557d                	li	a0,-1
    80004f40:	bfcd                	j	80004f32 <argfd+0x50>
		return -1;
    80004f42:	557d                	li	a0,-1
    80004f44:	b7fd                	j	80004f32 <argfd+0x50>
    80004f46:	557d                	li	a0,-1
    80004f48:	b7ed                	j	80004f32 <argfd+0x50>

0000000080004f4a <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80004f4a:	1101                	addi	sp,sp,-32
    80004f4c:	ec06                	sd	ra,24(sp)
    80004f4e:	e822                	sd	s0,16(sp)
    80004f50:	e426                	sd	s1,8(sp)
    80004f52:	1000                	addi	s0,sp,32
    80004f54:	84aa                	mv	s1,a0
	int fd;
	struct proc *p = myproc();
    80004f56:	ffffd097          	auipc	ra,0xffffd
    80004f5a:	ae6080e7          	jalr	-1306(ra) # 80001a3c <myproc>
    80004f5e:	862a                	mv	a2,a0

	for(fd = 0; fd < NOFILE; fd++){
    80004f60:	0d050793          	addi	a5,a0,208 # ffffffffffff80d0 <end+0xffffffff7ffb00d0>
    80004f64:	4501                	li	a0,0
    80004f66:	46c1                	li	a3,16
		if(p->ofile[fd] == 0){
    80004f68:	6398                	ld	a4,0(a5)
    80004f6a:	cb19                	beqz	a4,80004f80 <fdalloc+0x36>
	for(fd = 0; fd < NOFILE; fd++){
    80004f6c:	2505                	addiw	a0,a0,1
    80004f6e:	07a1                	addi	a5,a5,8
    80004f70:	fed51ce3          	bne	a0,a3,80004f68 <fdalloc+0x1e>
			p->ofile[fd] = f;
			return fd;
		}
	}
	return -1;
    80004f74:	557d                	li	a0,-1
}
    80004f76:	60e2                	ld	ra,24(sp)
    80004f78:	6442                	ld	s0,16(sp)
    80004f7a:	64a2                	ld	s1,8(sp)
    80004f7c:	6105                	addi	sp,sp,32
    80004f7e:	8082                	ret
			p->ofile[fd] = f;
    80004f80:	01a50793          	addi	a5,a0,26
    80004f84:	078e                	slli	a5,a5,0x3
    80004f86:	963e                	add	a2,a2,a5
    80004f88:	e204                	sd	s1,0(a2)
			return fd;
    80004f8a:	b7f5                	j	80004f76 <fdalloc+0x2c>

0000000080004f8c <create>:
	return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80004f8c:	715d                	addi	sp,sp,-80
    80004f8e:	e486                	sd	ra,72(sp)
    80004f90:	e0a2                	sd	s0,64(sp)
    80004f92:	fc26                	sd	s1,56(sp)
    80004f94:	f84a                	sd	s2,48(sp)
    80004f96:	f44e                	sd	s3,40(sp)
    80004f98:	f052                	sd	s4,32(sp)
    80004f9a:	ec56                	sd	s5,24(sp)
    80004f9c:	0880                	addi	s0,sp,80
    80004f9e:	89ae                	mv	s3,a1
    80004fa0:	8ab2                	mv	s5,a2
    80004fa2:	8a36                	mv	s4,a3
	struct inode *ip, *dp;
	char name[DIRSIZ];

	if((dp = nameiparent(path, name)) == 0)
    80004fa4:	fb040593          	addi	a1,s0,-80
    80004fa8:	fffff097          	auipc	ra,0xfffff
    80004fac:	e86080e7          	jalr	-378(ra) # 80003e2e <nameiparent>
    80004fb0:	892a                	mv	s2,a0
    80004fb2:	12050f63          	beqz	a0,800050f0 <create+0x164>
		return 0;

	ilock(dp);
    80004fb6:	ffffe097          	auipc	ra,0xffffe
    80004fba:	6a4080e7          	jalr	1700(ra) # 8000365a <ilock>

	if((ip = dirlookup(dp, name, 0)) != 0){
    80004fbe:	4601                	li	a2,0
    80004fc0:	fb040593          	addi	a1,s0,-80
    80004fc4:	854a                	mv	a0,s2
    80004fc6:	fffff097          	auipc	ra,0xfffff
    80004fca:	b78080e7          	jalr	-1160(ra) # 80003b3e <dirlookup>
    80004fce:	84aa                	mv	s1,a0
    80004fd0:	c921                	beqz	a0,80005020 <create+0x94>
		iunlockput(dp);
    80004fd2:	854a                	mv	a0,s2
    80004fd4:	fffff097          	auipc	ra,0xfffff
    80004fd8:	8e8080e7          	jalr	-1816(ra) # 800038bc <iunlockput>
		ilock(ip);
    80004fdc:	8526                	mv	a0,s1
    80004fde:	ffffe097          	auipc	ra,0xffffe
    80004fe2:	67c080e7          	jalr	1660(ra) # 8000365a <ilock>
		if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80004fe6:	2981                	sext.w	s3,s3
    80004fe8:	4789                	li	a5,2
    80004fea:	02f99463          	bne	s3,a5,80005012 <create+0x86>
    80004fee:	0444d783          	lhu	a5,68(s1)
    80004ff2:	37f9                	addiw	a5,a5,-2
    80004ff4:	17c2                	slli	a5,a5,0x30
    80004ff6:	93c1                	srli	a5,a5,0x30
    80004ff8:	4705                	li	a4,1
    80004ffa:	00f76c63          	bltu	a4,a5,80005012 <create+0x86>
		panic("create: dirlink");

	iunlockput(dp);

	return ip;
}
    80004ffe:	8526                	mv	a0,s1
    80005000:	60a6                	ld	ra,72(sp)
    80005002:	6406                	ld	s0,64(sp)
    80005004:	74e2                	ld	s1,56(sp)
    80005006:	7942                	ld	s2,48(sp)
    80005008:	79a2                	ld	s3,40(sp)
    8000500a:	7a02                	ld	s4,32(sp)
    8000500c:	6ae2                	ld	s5,24(sp)
    8000500e:	6161                	addi	sp,sp,80
    80005010:	8082                	ret
		iunlockput(ip);
    80005012:	8526                	mv	a0,s1
    80005014:	fffff097          	auipc	ra,0xfffff
    80005018:	8a8080e7          	jalr	-1880(ra) # 800038bc <iunlockput>
		return 0;
    8000501c:	4481                	li	s1,0
    8000501e:	b7c5                	j	80004ffe <create+0x72>
	if((ip = ialloc(dp->dev, type)) == 0)
    80005020:	85ce                	mv	a1,s3
    80005022:	00092503          	lw	a0,0(s2)
    80005026:	ffffe097          	auipc	ra,0xffffe
    8000502a:	49c080e7          	jalr	1180(ra) # 800034c2 <ialloc>
    8000502e:	84aa                	mv	s1,a0
    80005030:	c529                	beqz	a0,8000507a <create+0xee>
	ilock(ip);
    80005032:	ffffe097          	auipc	ra,0xffffe
    80005036:	628080e7          	jalr	1576(ra) # 8000365a <ilock>
	ip->major = major;
    8000503a:	05549323          	sh	s5,70(s1)
	ip->minor = minor;
    8000503e:	05449423          	sh	s4,72(s1)
	ip->nlink = 1;
    80005042:	4785                	li	a5,1
    80005044:	04f49523          	sh	a5,74(s1)
	iupdate(ip);
    80005048:	8526                	mv	a0,s1
    8000504a:	ffffe097          	auipc	ra,0xffffe
    8000504e:	546080e7          	jalr	1350(ra) # 80003590 <iupdate>
	if(type == T_DIR){  // Create . and .. entries.
    80005052:	2981                	sext.w	s3,s3
    80005054:	4785                	li	a5,1
    80005056:	02f98a63          	beq	s3,a5,8000508a <create+0xfe>
	if(dirlink(dp, name, ip->inum) < 0)
    8000505a:	40d0                	lw	a2,4(s1)
    8000505c:	fb040593          	addi	a1,s0,-80
    80005060:	854a                	mv	a0,s2
    80005062:	fffff097          	auipc	ra,0xfffff
    80005066:	cec080e7          	jalr	-788(ra) # 80003d4e <dirlink>
    8000506a:	06054b63          	bltz	a0,800050e0 <create+0x154>
	iunlockput(dp);
    8000506e:	854a                	mv	a0,s2
    80005070:	fffff097          	auipc	ra,0xfffff
    80005074:	84c080e7          	jalr	-1972(ra) # 800038bc <iunlockput>
	return ip;
    80005078:	b759                	j	80004ffe <create+0x72>
		panic("create: ialloc");
    8000507a:	00003517          	auipc	a0,0x3
    8000507e:	67650513          	addi	a0,a0,1654 # 800086f0 <syscalls+0x2a0>
    80005082:	ffffb097          	auipc	ra,0xffffb
    80005086:	4bc080e7          	jalr	1212(ra) # 8000053e <panic>
		dp->nlink++;  // for ".."
    8000508a:	04a95783          	lhu	a5,74(s2)
    8000508e:	2785                	addiw	a5,a5,1
    80005090:	04f91523          	sh	a5,74(s2)
		iupdate(dp);
    80005094:	854a                	mv	a0,s2
    80005096:	ffffe097          	auipc	ra,0xffffe
    8000509a:	4fa080e7          	jalr	1274(ra) # 80003590 <iupdate>
		if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    8000509e:	40d0                	lw	a2,4(s1)
    800050a0:	00003597          	auipc	a1,0x3
    800050a4:	66058593          	addi	a1,a1,1632 # 80008700 <syscalls+0x2b0>
    800050a8:	8526                	mv	a0,s1
    800050aa:	fffff097          	auipc	ra,0xfffff
    800050ae:	ca4080e7          	jalr	-860(ra) # 80003d4e <dirlink>
    800050b2:	00054f63          	bltz	a0,800050d0 <create+0x144>
    800050b6:	00492603          	lw	a2,4(s2)
    800050ba:	00003597          	auipc	a1,0x3
    800050be:	64e58593          	addi	a1,a1,1614 # 80008708 <syscalls+0x2b8>
    800050c2:	8526                	mv	a0,s1
    800050c4:	fffff097          	auipc	ra,0xfffff
    800050c8:	c8a080e7          	jalr	-886(ra) # 80003d4e <dirlink>
    800050cc:	f80557e3          	bgez	a0,8000505a <create+0xce>
			panic("create dots");
    800050d0:	00003517          	auipc	a0,0x3
    800050d4:	64050513          	addi	a0,a0,1600 # 80008710 <syscalls+0x2c0>
    800050d8:	ffffb097          	auipc	ra,0xffffb
    800050dc:	466080e7          	jalr	1126(ra) # 8000053e <panic>
		panic("create: dirlink");
    800050e0:	00003517          	auipc	a0,0x3
    800050e4:	64050513          	addi	a0,a0,1600 # 80008720 <syscalls+0x2d0>
    800050e8:	ffffb097          	auipc	ra,0xffffb
    800050ec:	456080e7          	jalr	1110(ra) # 8000053e <panic>
		return 0;
    800050f0:	84aa                	mv	s1,a0
    800050f2:	b731                	j	80004ffe <create+0x72>

00000000800050f4 <sys_dup>:
{
    800050f4:	7179                	addi	sp,sp,-48
    800050f6:	f406                	sd	ra,40(sp)
    800050f8:	f022                	sd	s0,32(sp)
    800050fa:	ec26                	sd	s1,24(sp)
    800050fc:	1800                	addi	s0,sp,48
	if(argfd(0, 0, &f) < 0)
    800050fe:	fd840613          	addi	a2,s0,-40
    80005102:	4581                	li	a1,0
    80005104:	4501                	li	a0,0
    80005106:	00000097          	auipc	ra,0x0
    8000510a:	ddc080e7          	jalr	-548(ra) # 80004ee2 <argfd>
		return -1;
    8000510e:	57fd                	li	a5,-1
	if(argfd(0, 0, &f) < 0)
    80005110:	02054363          	bltz	a0,80005136 <sys_dup+0x42>
	if((fd=fdalloc(f)) < 0)
    80005114:	fd843503          	ld	a0,-40(s0)
    80005118:	00000097          	auipc	ra,0x0
    8000511c:	e32080e7          	jalr	-462(ra) # 80004f4a <fdalloc>
    80005120:	84aa                	mv	s1,a0
		return -1;
    80005122:	57fd                	li	a5,-1
	if((fd=fdalloc(f)) < 0)
    80005124:	00054963          	bltz	a0,80005136 <sys_dup+0x42>
	filedup(f);
    80005128:	fd843503          	ld	a0,-40(s0)
    8000512c:	fffff097          	auipc	ra,0xfffff
    80005130:	37a080e7          	jalr	890(ra) # 800044a6 <filedup>
	return fd;
    80005134:	87a6                	mv	a5,s1
}
    80005136:	853e                	mv	a0,a5
    80005138:	70a2                	ld	ra,40(sp)
    8000513a:	7402                	ld	s0,32(sp)
    8000513c:	64e2                	ld	s1,24(sp)
    8000513e:	6145                	addi	sp,sp,48
    80005140:	8082                	ret

0000000080005142 <sys_read>:
{
    80005142:	7179                	addi	sp,sp,-48
    80005144:	f406                	sd	ra,40(sp)
    80005146:	f022                	sd	s0,32(sp)
    80005148:	1800                	addi	s0,sp,48
	if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000514a:	fe840613          	addi	a2,s0,-24
    8000514e:	4581                	li	a1,0
    80005150:	4501                	li	a0,0
    80005152:	00000097          	auipc	ra,0x0
    80005156:	d90080e7          	jalr	-624(ra) # 80004ee2 <argfd>
		return -1;
    8000515a:	57fd                	li	a5,-1
	if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000515c:	04054163          	bltz	a0,8000519e <sys_read+0x5c>
    80005160:	fe440593          	addi	a1,s0,-28
    80005164:	4509                	li	a0,2
    80005166:	ffffe097          	auipc	ra,0xffffe
    8000516a:	982080e7          	jalr	-1662(ra) # 80002ae8 <argint>
		return -1;
    8000516e:	57fd                	li	a5,-1
	if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005170:	02054763          	bltz	a0,8000519e <sys_read+0x5c>
    80005174:	fd840593          	addi	a1,s0,-40
    80005178:	4505                	li	a0,1
    8000517a:	ffffe097          	auipc	ra,0xffffe
    8000517e:	990080e7          	jalr	-1648(ra) # 80002b0a <argaddr>
		return -1;
    80005182:	57fd                	li	a5,-1
	if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005184:	00054d63          	bltz	a0,8000519e <sys_read+0x5c>
	return fileread(f, p, n);
    80005188:	fe442603          	lw	a2,-28(s0)
    8000518c:	fd843583          	ld	a1,-40(s0)
    80005190:	fe843503          	ld	a0,-24(s0)
    80005194:	fffff097          	auipc	ra,0xfffff
    80005198:	49e080e7          	jalr	1182(ra) # 80004632 <fileread>
    8000519c:	87aa                	mv	a5,a0
}
    8000519e:	853e                	mv	a0,a5
    800051a0:	70a2                	ld	ra,40(sp)
    800051a2:	7402                	ld	s0,32(sp)
    800051a4:	6145                	addi	sp,sp,48
    800051a6:	8082                	ret

00000000800051a8 <sys_write>:
{
    800051a8:	7179                	addi	sp,sp,-48
    800051aa:	f406                	sd	ra,40(sp)
    800051ac:	f022                	sd	s0,32(sp)
    800051ae:	1800                	addi	s0,sp,48
	if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800051b0:	fe840613          	addi	a2,s0,-24
    800051b4:	4581                	li	a1,0
    800051b6:	4501                	li	a0,0
    800051b8:	00000097          	auipc	ra,0x0
    800051bc:	d2a080e7          	jalr	-726(ra) # 80004ee2 <argfd>
		return -1;
    800051c0:	57fd                	li	a5,-1
	if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800051c2:	04054163          	bltz	a0,80005204 <sys_write+0x5c>
    800051c6:	fe440593          	addi	a1,s0,-28
    800051ca:	4509                	li	a0,2
    800051cc:	ffffe097          	auipc	ra,0xffffe
    800051d0:	91c080e7          	jalr	-1764(ra) # 80002ae8 <argint>
		return -1;
    800051d4:	57fd                	li	a5,-1
	if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800051d6:	02054763          	bltz	a0,80005204 <sys_write+0x5c>
    800051da:	fd840593          	addi	a1,s0,-40
    800051de:	4505                	li	a0,1
    800051e0:	ffffe097          	auipc	ra,0xffffe
    800051e4:	92a080e7          	jalr	-1750(ra) # 80002b0a <argaddr>
		return -1;
    800051e8:	57fd                	li	a5,-1
	if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800051ea:	00054d63          	bltz	a0,80005204 <sys_write+0x5c>
	return filewrite(f, p, n);
    800051ee:	fe442603          	lw	a2,-28(s0)
    800051f2:	fd843583          	ld	a1,-40(s0)
    800051f6:	fe843503          	ld	a0,-24(s0)
    800051fa:	fffff097          	auipc	ra,0xfffff
    800051fe:	4fa080e7          	jalr	1274(ra) # 800046f4 <filewrite>
    80005202:	87aa                	mv	a5,a0
}
    80005204:	853e                	mv	a0,a5
    80005206:	70a2                	ld	ra,40(sp)
    80005208:	7402                	ld	s0,32(sp)
    8000520a:	6145                	addi	sp,sp,48
    8000520c:	8082                	ret

000000008000520e <sys_close>:
{
    8000520e:	1101                	addi	sp,sp,-32
    80005210:	ec06                	sd	ra,24(sp)
    80005212:	e822                	sd	s0,16(sp)
    80005214:	1000                	addi	s0,sp,32
	if(argfd(0, &fd, &f) < 0)
    80005216:	fe040613          	addi	a2,s0,-32
    8000521a:	fec40593          	addi	a1,s0,-20
    8000521e:	4501                	li	a0,0
    80005220:	00000097          	auipc	ra,0x0
    80005224:	cc2080e7          	jalr	-830(ra) # 80004ee2 <argfd>
		return -1;
    80005228:	57fd                	li	a5,-1
	if(argfd(0, &fd, &f) < 0)
    8000522a:	02054463          	bltz	a0,80005252 <sys_close+0x44>
	myproc()->ofile[fd] = 0;
    8000522e:	ffffd097          	auipc	ra,0xffffd
    80005232:	80e080e7          	jalr	-2034(ra) # 80001a3c <myproc>
    80005236:	fec42783          	lw	a5,-20(s0)
    8000523a:	07e9                	addi	a5,a5,26
    8000523c:	078e                	slli	a5,a5,0x3
    8000523e:	97aa                	add	a5,a5,a0
    80005240:	0007b023          	sd	zero,0(a5)
	fileclose(f);
    80005244:	fe043503          	ld	a0,-32(s0)
    80005248:	fffff097          	auipc	ra,0xfffff
    8000524c:	2b0080e7          	jalr	688(ra) # 800044f8 <fileclose>
	return 0;
    80005250:	4781                	li	a5,0
}
    80005252:	853e                	mv	a0,a5
    80005254:	60e2                	ld	ra,24(sp)
    80005256:	6442                	ld	s0,16(sp)
    80005258:	6105                	addi	sp,sp,32
    8000525a:	8082                	ret

000000008000525c <sys_fstat>:
{
    8000525c:	1101                	addi	sp,sp,-32
    8000525e:	ec06                	sd	ra,24(sp)
    80005260:	e822                	sd	s0,16(sp)
    80005262:	1000                	addi	s0,sp,32
	if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005264:	fe840613          	addi	a2,s0,-24
    80005268:	4581                	li	a1,0
    8000526a:	4501                	li	a0,0
    8000526c:	00000097          	auipc	ra,0x0
    80005270:	c76080e7          	jalr	-906(ra) # 80004ee2 <argfd>
		return -1;
    80005274:	57fd                	li	a5,-1
	if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005276:	02054563          	bltz	a0,800052a0 <sys_fstat+0x44>
    8000527a:	fe040593          	addi	a1,s0,-32
    8000527e:	4505                	li	a0,1
    80005280:	ffffe097          	auipc	ra,0xffffe
    80005284:	88a080e7          	jalr	-1910(ra) # 80002b0a <argaddr>
		return -1;
    80005288:	57fd                	li	a5,-1
	if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000528a:	00054b63          	bltz	a0,800052a0 <sys_fstat+0x44>
	return filestat(f, st);
    8000528e:	fe043583          	ld	a1,-32(s0)
    80005292:	fe843503          	ld	a0,-24(s0)
    80005296:	fffff097          	auipc	ra,0xfffff
    8000529a:	32a080e7          	jalr	810(ra) # 800045c0 <filestat>
    8000529e:	87aa                	mv	a5,a0
}
    800052a0:	853e                	mv	a0,a5
    800052a2:	60e2                	ld	ra,24(sp)
    800052a4:	6442                	ld	s0,16(sp)
    800052a6:	6105                	addi	sp,sp,32
    800052a8:	8082                	ret

00000000800052aa <sys_link>:
{
    800052aa:	7169                	addi	sp,sp,-304
    800052ac:	f606                	sd	ra,296(sp)
    800052ae:	f222                	sd	s0,288(sp)
    800052b0:	ee26                	sd	s1,280(sp)
    800052b2:	ea4a                	sd	s2,272(sp)
    800052b4:	1a00                	addi	s0,sp,304
	if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800052b6:	08000613          	li	a2,128
    800052ba:	ed040593          	addi	a1,s0,-304
    800052be:	4501                	li	a0,0
    800052c0:	ffffe097          	auipc	ra,0xffffe
    800052c4:	86c080e7          	jalr	-1940(ra) # 80002b2c <argstr>
		return -1;
    800052c8:	57fd                	li	a5,-1
	if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800052ca:	10054e63          	bltz	a0,800053e6 <sys_link+0x13c>
    800052ce:	08000613          	li	a2,128
    800052d2:	f5040593          	addi	a1,s0,-176
    800052d6:	4505                	li	a0,1
    800052d8:	ffffe097          	auipc	ra,0xffffe
    800052dc:	854080e7          	jalr	-1964(ra) # 80002b2c <argstr>
		return -1;
    800052e0:	57fd                	li	a5,-1
	if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800052e2:	10054263          	bltz	a0,800053e6 <sys_link+0x13c>
	begin_op();
    800052e6:	fffff097          	auipc	ra,0xfffff
    800052ea:	d46080e7          	jalr	-698(ra) # 8000402c <begin_op>
	if((ip = namei(old)) == 0){
    800052ee:	ed040513          	addi	a0,s0,-304
    800052f2:	fffff097          	auipc	ra,0xfffff
    800052f6:	b1e080e7          	jalr	-1250(ra) # 80003e10 <namei>
    800052fa:	84aa                	mv	s1,a0
    800052fc:	c551                	beqz	a0,80005388 <sys_link+0xde>
	ilock(ip);
    800052fe:	ffffe097          	auipc	ra,0xffffe
    80005302:	35c080e7          	jalr	860(ra) # 8000365a <ilock>
	if(ip->type == T_DIR){
    80005306:	04449703          	lh	a4,68(s1)
    8000530a:	4785                	li	a5,1
    8000530c:	08f70463          	beq	a4,a5,80005394 <sys_link+0xea>
	ip->nlink++;
    80005310:	04a4d783          	lhu	a5,74(s1)
    80005314:	2785                	addiw	a5,a5,1
    80005316:	04f49523          	sh	a5,74(s1)
	iupdate(ip);
    8000531a:	8526                	mv	a0,s1
    8000531c:	ffffe097          	auipc	ra,0xffffe
    80005320:	274080e7          	jalr	628(ra) # 80003590 <iupdate>
	iunlock(ip);
    80005324:	8526                	mv	a0,s1
    80005326:	ffffe097          	auipc	ra,0xffffe
    8000532a:	3f6080e7          	jalr	1014(ra) # 8000371c <iunlock>
	if((dp = nameiparent(new, name)) == 0)
    8000532e:	fd040593          	addi	a1,s0,-48
    80005332:	f5040513          	addi	a0,s0,-176
    80005336:	fffff097          	auipc	ra,0xfffff
    8000533a:	af8080e7          	jalr	-1288(ra) # 80003e2e <nameiparent>
    8000533e:	892a                	mv	s2,a0
    80005340:	c935                	beqz	a0,800053b4 <sys_link+0x10a>
	ilock(dp);
    80005342:	ffffe097          	auipc	ra,0xffffe
    80005346:	318080e7          	jalr	792(ra) # 8000365a <ilock>
	if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    8000534a:	00092703          	lw	a4,0(s2)
    8000534e:	409c                	lw	a5,0(s1)
    80005350:	04f71d63          	bne	a4,a5,800053aa <sys_link+0x100>
    80005354:	40d0                	lw	a2,4(s1)
    80005356:	fd040593          	addi	a1,s0,-48
    8000535a:	854a                	mv	a0,s2
    8000535c:	fffff097          	auipc	ra,0xfffff
    80005360:	9f2080e7          	jalr	-1550(ra) # 80003d4e <dirlink>
    80005364:	04054363          	bltz	a0,800053aa <sys_link+0x100>
	iunlockput(dp);
    80005368:	854a                	mv	a0,s2
    8000536a:	ffffe097          	auipc	ra,0xffffe
    8000536e:	552080e7          	jalr	1362(ra) # 800038bc <iunlockput>
	iput(ip);
    80005372:	8526                	mv	a0,s1
    80005374:	ffffe097          	auipc	ra,0xffffe
    80005378:	4a0080e7          	jalr	1184(ra) # 80003814 <iput>
	end_op();
    8000537c:	fffff097          	auipc	ra,0xfffff
    80005380:	d30080e7          	jalr	-720(ra) # 800040ac <end_op>
	return 0;
    80005384:	4781                	li	a5,0
    80005386:	a085                	j	800053e6 <sys_link+0x13c>
		end_op();
    80005388:	fffff097          	auipc	ra,0xfffff
    8000538c:	d24080e7          	jalr	-732(ra) # 800040ac <end_op>
		return -1;
    80005390:	57fd                	li	a5,-1
    80005392:	a891                	j	800053e6 <sys_link+0x13c>
		iunlockput(ip);
    80005394:	8526                	mv	a0,s1
    80005396:	ffffe097          	auipc	ra,0xffffe
    8000539a:	526080e7          	jalr	1318(ra) # 800038bc <iunlockput>
		end_op();
    8000539e:	fffff097          	auipc	ra,0xfffff
    800053a2:	d0e080e7          	jalr	-754(ra) # 800040ac <end_op>
		return -1;
    800053a6:	57fd                	li	a5,-1
    800053a8:	a83d                	j	800053e6 <sys_link+0x13c>
		iunlockput(dp);
    800053aa:	854a                	mv	a0,s2
    800053ac:	ffffe097          	auipc	ra,0xffffe
    800053b0:	510080e7          	jalr	1296(ra) # 800038bc <iunlockput>
	ilock(ip);
    800053b4:	8526                	mv	a0,s1
    800053b6:	ffffe097          	auipc	ra,0xffffe
    800053ba:	2a4080e7          	jalr	676(ra) # 8000365a <ilock>
	ip->nlink--;
    800053be:	04a4d783          	lhu	a5,74(s1)
    800053c2:	37fd                	addiw	a5,a5,-1
    800053c4:	04f49523          	sh	a5,74(s1)
	iupdate(ip);
    800053c8:	8526                	mv	a0,s1
    800053ca:	ffffe097          	auipc	ra,0xffffe
    800053ce:	1c6080e7          	jalr	454(ra) # 80003590 <iupdate>
	iunlockput(ip);
    800053d2:	8526                	mv	a0,s1
    800053d4:	ffffe097          	auipc	ra,0xffffe
    800053d8:	4e8080e7          	jalr	1256(ra) # 800038bc <iunlockput>
	end_op();
    800053dc:	fffff097          	auipc	ra,0xfffff
    800053e0:	cd0080e7          	jalr	-816(ra) # 800040ac <end_op>
	return -1;
    800053e4:	57fd                	li	a5,-1
}
    800053e6:	853e                	mv	a0,a5
    800053e8:	70b2                	ld	ra,296(sp)
    800053ea:	7412                	ld	s0,288(sp)
    800053ec:	64f2                	ld	s1,280(sp)
    800053ee:	6952                	ld	s2,272(sp)
    800053f0:	6155                	addi	sp,sp,304
    800053f2:	8082                	ret

00000000800053f4 <sys_unlink>:
{
    800053f4:	7151                	addi	sp,sp,-240
    800053f6:	f586                	sd	ra,232(sp)
    800053f8:	f1a2                	sd	s0,224(sp)
    800053fa:	eda6                	sd	s1,216(sp)
    800053fc:	e9ca                	sd	s2,208(sp)
    800053fe:	e5ce                	sd	s3,200(sp)
    80005400:	1980                	addi	s0,sp,240
	if(argstr(0, path, MAXPATH) < 0)
    80005402:	08000613          	li	a2,128
    80005406:	f3040593          	addi	a1,s0,-208
    8000540a:	4501                	li	a0,0
    8000540c:	ffffd097          	auipc	ra,0xffffd
    80005410:	720080e7          	jalr	1824(ra) # 80002b2c <argstr>
    80005414:	18054163          	bltz	a0,80005596 <sys_unlink+0x1a2>
	begin_op();
    80005418:	fffff097          	auipc	ra,0xfffff
    8000541c:	c14080e7          	jalr	-1004(ra) # 8000402c <begin_op>
	if((dp = nameiparent(path, name)) == 0){
    80005420:	fb040593          	addi	a1,s0,-80
    80005424:	f3040513          	addi	a0,s0,-208
    80005428:	fffff097          	auipc	ra,0xfffff
    8000542c:	a06080e7          	jalr	-1530(ra) # 80003e2e <nameiparent>
    80005430:	84aa                	mv	s1,a0
    80005432:	c979                	beqz	a0,80005508 <sys_unlink+0x114>
	ilock(dp);
    80005434:	ffffe097          	auipc	ra,0xffffe
    80005438:	226080e7          	jalr	550(ra) # 8000365a <ilock>
	if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    8000543c:	00003597          	auipc	a1,0x3
    80005440:	2c458593          	addi	a1,a1,708 # 80008700 <syscalls+0x2b0>
    80005444:	fb040513          	addi	a0,s0,-80
    80005448:	ffffe097          	auipc	ra,0xffffe
    8000544c:	6dc080e7          	jalr	1756(ra) # 80003b24 <namecmp>
    80005450:	14050a63          	beqz	a0,800055a4 <sys_unlink+0x1b0>
    80005454:	00003597          	auipc	a1,0x3
    80005458:	2b458593          	addi	a1,a1,692 # 80008708 <syscalls+0x2b8>
    8000545c:	fb040513          	addi	a0,s0,-80
    80005460:	ffffe097          	auipc	ra,0xffffe
    80005464:	6c4080e7          	jalr	1732(ra) # 80003b24 <namecmp>
    80005468:	12050e63          	beqz	a0,800055a4 <sys_unlink+0x1b0>
	if((ip = dirlookup(dp, name, &off)) == 0)
    8000546c:	f2c40613          	addi	a2,s0,-212
    80005470:	fb040593          	addi	a1,s0,-80
    80005474:	8526                	mv	a0,s1
    80005476:	ffffe097          	auipc	ra,0xffffe
    8000547a:	6c8080e7          	jalr	1736(ra) # 80003b3e <dirlookup>
    8000547e:	892a                	mv	s2,a0
    80005480:	12050263          	beqz	a0,800055a4 <sys_unlink+0x1b0>
	ilock(ip);
    80005484:	ffffe097          	auipc	ra,0xffffe
    80005488:	1d6080e7          	jalr	470(ra) # 8000365a <ilock>
	if(ip->nlink < 1)
    8000548c:	04a91783          	lh	a5,74(s2)
    80005490:	08f05263          	blez	a5,80005514 <sys_unlink+0x120>
	if(ip->type == T_DIR && !isdirempty(ip)){
    80005494:	04491703          	lh	a4,68(s2)
    80005498:	4785                	li	a5,1
    8000549a:	08f70563          	beq	a4,a5,80005524 <sys_unlink+0x130>
	memset(&de, 0, sizeof(de));
    8000549e:	4641                	li	a2,16
    800054a0:	4581                	li	a1,0
    800054a2:	fc040513          	addi	a0,s0,-64
    800054a6:	ffffc097          	auipc	ra,0xffffc
    800054aa:	83a080e7          	jalr	-1990(ra) # 80000ce0 <memset>
	if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800054ae:	4741                	li	a4,16
    800054b0:	f2c42683          	lw	a3,-212(s0)
    800054b4:	fc040613          	addi	a2,s0,-64
    800054b8:	4581                	li	a1,0
    800054ba:	8526                	mv	a0,s1
    800054bc:	ffffe097          	auipc	ra,0xffffe
    800054c0:	54a080e7          	jalr	1354(ra) # 80003a06 <writei>
    800054c4:	47c1                	li	a5,16
    800054c6:	0af51563          	bne	a0,a5,80005570 <sys_unlink+0x17c>
	if(ip->type == T_DIR){
    800054ca:	04491703          	lh	a4,68(s2)
    800054ce:	4785                	li	a5,1
    800054d0:	0af70863          	beq	a4,a5,80005580 <sys_unlink+0x18c>
	iunlockput(dp);
    800054d4:	8526                	mv	a0,s1
    800054d6:	ffffe097          	auipc	ra,0xffffe
    800054da:	3e6080e7          	jalr	998(ra) # 800038bc <iunlockput>
	ip->nlink--;
    800054de:	04a95783          	lhu	a5,74(s2)
    800054e2:	37fd                	addiw	a5,a5,-1
    800054e4:	04f91523          	sh	a5,74(s2)
	iupdate(ip);
    800054e8:	854a                	mv	a0,s2
    800054ea:	ffffe097          	auipc	ra,0xffffe
    800054ee:	0a6080e7          	jalr	166(ra) # 80003590 <iupdate>
	iunlockput(ip);
    800054f2:	854a                	mv	a0,s2
    800054f4:	ffffe097          	auipc	ra,0xffffe
    800054f8:	3c8080e7          	jalr	968(ra) # 800038bc <iunlockput>
	end_op();
    800054fc:	fffff097          	auipc	ra,0xfffff
    80005500:	bb0080e7          	jalr	-1104(ra) # 800040ac <end_op>
	return 0;
    80005504:	4501                	li	a0,0
    80005506:	a84d                	j	800055b8 <sys_unlink+0x1c4>
		end_op();
    80005508:	fffff097          	auipc	ra,0xfffff
    8000550c:	ba4080e7          	jalr	-1116(ra) # 800040ac <end_op>
		return -1;
    80005510:	557d                	li	a0,-1
    80005512:	a05d                	j	800055b8 <sys_unlink+0x1c4>
		panic("unlink: nlink < 1");
    80005514:	00003517          	auipc	a0,0x3
    80005518:	21c50513          	addi	a0,a0,540 # 80008730 <syscalls+0x2e0>
    8000551c:	ffffb097          	auipc	ra,0xffffb
    80005520:	022080e7          	jalr	34(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005524:	04c92703          	lw	a4,76(s2)
    80005528:	02000793          	li	a5,32
    8000552c:	f6e7f9e3          	bgeu	a5,a4,8000549e <sys_unlink+0xaa>
    80005530:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005534:	4741                	li	a4,16
    80005536:	86ce                	mv	a3,s3
    80005538:	f1840613          	addi	a2,s0,-232
    8000553c:	4581                	li	a1,0
    8000553e:	854a                	mv	a0,s2
    80005540:	ffffe097          	auipc	ra,0xffffe
    80005544:	3ce080e7          	jalr	974(ra) # 8000390e <readi>
    80005548:	47c1                	li	a5,16
    8000554a:	00f51b63          	bne	a0,a5,80005560 <sys_unlink+0x16c>
    if(de.inum != 0)
    8000554e:	f1845783          	lhu	a5,-232(s0)
    80005552:	e7a1                	bnez	a5,8000559a <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005554:	29c1                	addiw	s3,s3,16
    80005556:	04c92783          	lw	a5,76(s2)
    8000555a:	fcf9ede3          	bltu	s3,a5,80005534 <sys_unlink+0x140>
    8000555e:	b781                	j	8000549e <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005560:	00003517          	auipc	a0,0x3
    80005564:	1e850513          	addi	a0,a0,488 # 80008748 <syscalls+0x2f8>
    80005568:	ffffb097          	auipc	ra,0xffffb
    8000556c:	fd6080e7          	jalr	-42(ra) # 8000053e <panic>
		panic("unlink: writei");
    80005570:	00003517          	auipc	a0,0x3
    80005574:	1f050513          	addi	a0,a0,496 # 80008760 <syscalls+0x310>
    80005578:	ffffb097          	auipc	ra,0xffffb
    8000557c:	fc6080e7          	jalr	-58(ra) # 8000053e <panic>
		dp->nlink--;
    80005580:	04a4d783          	lhu	a5,74(s1)
    80005584:	37fd                	addiw	a5,a5,-1
    80005586:	04f49523          	sh	a5,74(s1)
		iupdate(dp);
    8000558a:	8526                	mv	a0,s1
    8000558c:	ffffe097          	auipc	ra,0xffffe
    80005590:	004080e7          	jalr	4(ra) # 80003590 <iupdate>
    80005594:	b781                	j	800054d4 <sys_unlink+0xe0>
		return -1;
    80005596:	557d                	li	a0,-1
    80005598:	a005                	j	800055b8 <sys_unlink+0x1c4>
		iunlockput(ip);
    8000559a:	854a                	mv	a0,s2
    8000559c:	ffffe097          	auipc	ra,0xffffe
    800055a0:	320080e7          	jalr	800(ra) # 800038bc <iunlockput>
	iunlockput(dp);
    800055a4:	8526                	mv	a0,s1
    800055a6:	ffffe097          	auipc	ra,0xffffe
    800055aa:	316080e7          	jalr	790(ra) # 800038bc <iunlockput>
	end_op();
    800055ae:	fffff097          	auipc	ra,0xfffff
    800055b2:	afe080e7          	jalr	-1282(ra) # 800040ac <end_op>
	return -1;
    800055b6:	557d                	li	a0,-1
}
    800055b8:	70ae                	ld	ra,232(sp)
    800055ba:	740e                	ld	s0,224(sp)
    800055bc:	64ee                	ld	s1,216(sp)
    800055be:	694e                	ld	s2,208(sp)
    800055c0:	69ae                	ld	s3,200(sp)
    800055c2:	616d                	addi	sp,sp,240
    800055c4:	8082                	ret

00000000800055c6 <sys_open>:

uint64
sys_open(void)
{
    800055c6:	7131                	addi	sp,sp,-192
    800055c8:	fd06                	sd	ra,184(sp)
    800055ca:	f922                	sd	s0,176(sp)
    800055cc:	f526                	sd	s1,168(sp)
    800055ce:	f14a                	sd	s2,160(sp)
    800055d0:	ed4e                	sd	s3,152(sp)
    800055d2:	0180                	addi	s0,sp,192
	int fd, omode;
	struct file *f;
	struct inode *ip;
	int n;

	if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    800055d4:	08000613          	li	a2,128
    800055d8:	f5040593          	addi	a1,s0,-176
    800055dc:	4501                	li	a0,0
    800055de:	ffffd097          	auipc	ra,0xffffd
    800055e2:	54e080e7          	jalr	1358(ra) # 80002b2c <argstr>
		return -1;
    800055e6:	54fd                	li	s1,-1
	if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    800055e8:	0c054163          	bltz	a0,800056aa <sys_open+0xe4>
    800055ec:	f4c40593          	addi	a1,s0,-180
    800055f0:	4505                	li	a0,1
    800055f2:	ffffd097          	auipc	ra,0xffffd
    800055f6:	4f6080e7          	jalr	1270(ra) # 80002ae8 <argint>
    800055fa:	0a054863          	bltz	a0,800056aa <sys_open+0xe4>

	begin_op();
    800055fe:	fffff097          	auipc	ra,0xfffff
    80005602:	a2e080e7          	jalr	-1490(ra) # 8000402c <begin_op>

	if(omode & O_CREATE){
    80005606:	f4c42783          	lw	a5,-180(s0)
    8000560a:	2007f793          	andi	a5,a5,512
    8000560e:	cbdd                	beqz	a5,800056c4 <sys_open+0xfe>
		ip = create(path, T_FILE, 0, 0);
    80005610:	4681                	li	a3,0
    80005612:	4601                	li	a2,0
    80005614:	4589                	li	a1,2
    80005616:	f5040513          	addi	a0,s0,-176
    8000561a:	00000097          	auipc	ra,0x0
    8000561e:	972080e7          	jalr	-1678(ra) # 80004f8c <create>
    80005622:	892a                	mv	s2,a0
		if(ip == 0){
    80005624:	c959                	beqz	a0,800056ba <sys_open+0xf4>
			end_op();
			return -1;
		}
	}

	if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005626:	04491703          	lh	a4,68(s2)
    8000562a:	478d                	li	a5,3
    8000562c:	00f71763          	bne	a4,a5,8000563a <sys_open+0x74>
    80005630:	04695703          	lhu	a4,70(s2)
    80005634:	47a5                	li	a5,9
    80005636:	0ce7ec63          	bltu	a5,a4,8000570e <sys_open+0x148>
		iunlockput(ip);
		end_op();
		return -1;
	}

	if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    8000563a:	fffff097          	auipc	ra,0xfffff
    8000563e:	e02080e7          	jalr	-510(ra) # 8000443c <filealloc>
    80005642:	89aa                	mv	s3,a0
    80005644:	10050263          	beqz	a0,80005748 <sys_open+0x182>
    80005648:	00000097          	auipc	ra,0x0
    8000564c:	902080e7          	jalr	-1790(ra) # 80004f4a <fdalloc>
    80005650:	84aa                	mv	s1,a0
    80005652:	0e054663          	bltz	a0,8000573e <sys_open+0x178>
		iunlockput(ip);
		end_op();
		return -1;
	}

	if(ip->type == T_DEVICE){
    80005656:	04491703          	lh	a4,68(s2)
    8000565a:	478d                	li	a5,3
    8000565c:	0cf70463          	beq	a4,a5,80005724 <sys_open+0x15e>
		f->type = FD_DEVICE;
		f->major = ip->major;
	} else {
		f->type = FD_INODE;
    80005660:	4789                	li	a5,2
    80005662:	00f9a023          	sw	a5,0(s3)
		f->off = 0;
    80005666:	0209a023          	sw	zero,32(s3)
	}
	f->ip = ip;
    8000566a:	0129bc23          	sd	s2,24(s3)
	f->readable = !(omode & O_WRONLY);
    8000566e:	f4c42783          	lw	a5,-180(s0)
    80005672:	0017c713          	xori	a4,a5,1
    80005676:	8b05                	andi	a4,a4,1
    80005678:	00e98423          	sb	a4,8(s3)
	f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    8000567c:	0037f713          	andi	a4,a5,3
    80005680:	00e03733          	snez	a4,a4
    80005684:	00e984a3          	sb	a4,9(s3)

	if((omode & O_TRUNC) && ip->type == T_FILE){
    80005688:	4007f793          	andi	a5,a5,1024
    8000568c:	c791                	beqz	a5,80005698 <sys_open+0xd2>
    8000568e:	04491703          	lh	a4,68(s2)
    80005692:	4789                	li	a5,2
    80005694:	08f70f63          	beq	a4,a5,80005732 <sys_open+0x16c>
		itrunc(ip);
	}

	iunlock(ip);
    80005698:	854a                	mv	a0,s2
    8000569a:	ffffe097          	auipc	ra,0xffffe
    8000569e:	082080e7          	jalr	130(ra) # 8000371c <iunlock>
	end_op();
    800056a2:	fffff097          	auipc	ra,0xfffff
    800056a6:	a0a080e7          	jalr	-1526(ra) # 800040ac <end_op>

	return fd;
}
    800056aa:	8526                	mv	a0,s1
    800056ac:	70ea                	ld	ra,184(sp)
    800056ae:	744a                	ld	s0,176(sp)
    800056b0:	74aa                	ld	s1,168(sp)
    800056b2:	790a                	ld	s2,160(sp)
    800056b4:	69ea                	ld	s3,152(sp)
    800056b6:	6129                	addi	sp,sp,192
    800056b8:	8082                	ret
			end_op();
    800056ba:	fffff097          	auipc	ra,0xfffff
    800056be:	9f2080e7          	jalr	-1550(ra) # 800040ac <end_op>
			return -1;
    800056c2:	b7e5                	j	800056aa <sys_open+0xe4>
		if((ip = namei(path)) == 0){
    800056c4:	f5040513          	addi	a0,s0,-176
    800056c8:	ffffe097          	auipc	ra,0xffffe
    800056cc:	748080e7          	jalr	1864(ra) # 80003e10 <namei>
    800056d0:	892a                	mv	s2,a0
    800056d2:	c905                	beqz	a0,80005702 <sys_open+0x13c>
		ilock(ip);
    800056d4:	ffffe097          	auipc	ra,0xffffe
    800056d8:	f86080e7          	jalr	-122(ra) # 8000365a <ilock>
		if(ip->type == T_DIR && omode != O_RDONLY){
    800056dc:	04491703          	lh	a4,68(s2)
    800056e0:	4785                	li	a5,1
    800056e2:	f4f712e3          	bne	a4,a5,80005626 <sys_open+0x60>
    800056e6:	f4c42783          	lw	a5,-180(s0)
    800056ea:	dba1                	beqz	a5,8000563a <sys_open+0x74>
			iunlockput(ip);
    800056ec:	854a                	mv	a0,s2
    800056ee:	ffffe097          	auipc	ra,0xffffe
    800056f2:	1ce080e7          	jalr	462(ra) # 800038bc <iunlockput>
			end_op();
    800056f6:	fffff097          	auipc	ra,0xfffff
    800056fa:	9b6080e7          	jalr	-1610(ra) # 800040ac <end_op>
			return -1;
    800056fe:	54fd                	li	s1,-1
    80005700:	b76d                	j	800056aa <sys_open+0xe4>
			end_op();
    80005702:	fffff097          	auipc	ra,0xfffff
    80005706:	9aa080e7          	jalr	-1622(ra) # 800040ac <end_op>
			return -1;
    8000570a:	54fd                	li	s1,-1
    8000570c:	bf79                	j	800056aa <sys_open+0xe4>
		iunlockput(ip);
    8000570e:	854a                	mv	a0,s2
    80005710:	ffffe097          	auipc	ra,0xffffe
    80005714:	1ac080e7          	jalr	428(ra) # 800038bc <iunlockput>
		end_op();
    80005718:	fffff097          	auipc	ra,0xfffff
    8000571c:	994080e7          	jalr	-1644(ra) # 800040ac <end_op>
		return -1;
    80005720:	54fd                	li	s1,-1
    80005722:	b761                	j	800056aa <sys_open+0xe4>
		f->type = FD_DEVICE;
    80005724:	00f9a023          	sw	a5,0(s3)
		f->major = ip->major;
    80005728:	04691783          	lh	a5,70(s2)
    8000572c:	02f99223          	sh	a5,36(s3)
    80005730:	bf2d                	j	8000566a <sys_open+0xa4>
		itrunc(ip);
    80005732:	854a                	mv	a0,s2
    80005734:	ffffe097          	auipc	ra,0xffffe
    80005738:	034080e7          	jalr	52(ra) # 80003768 <itrunc>
    8000573c:	bfb1                	j	80005698 <sys_open+0xd2>
			fileclose(f);
    8000573e:	854e                	mv	a0,s3
    80005740:	fffff097          	auipc	ra,0xfffff
    80005744:	db8080e7          	jalr	-584(ra) # 800044f8 <fileclose>
		iunlockput(ip);
    80005748:	854a                	mv	a0,s2
    8000574a:	ffffe097          	auipc	ra,0xffffe
    8000574e:	172080e7          	jalr	370(ra) # 800038bc <iunlockput>
		end_op();
    80005752:	fffff097          	auipc	ra,0xfffff
    80005756:	95a080e7          	jalr	-1702(ra) # 800040ac <end_op>
		return -1;
    8000575a:	54fd                	li	s1,-1
    8000575c:	b7b9                	j	800056aa <sys_open+0xe4>

000000008000575e <sys_mkdir>:

uint64
sys_mkdir(void)
{
    8000575e:	7175                	addi	sp,sp,-144
    80005760:	e506                	sd	ra,136(sp)
    80005762:	e122                	sd	s0,128(sp)
    80005764:	0900                	addi	s0,sp,144
	char path[MAXPATH];
	struct inode *ip;

	begin_op();
    80005766:	fffff097          	auipc	ra,0xfffff
    8000576a:	8c6080e7          	jalr	-1850(ra) # 8000402c <begin_op>
	if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    8000576e:	08000613          	li	a2,128
    80005772:	f7040593          	addi	a1,s0,-144
    80005776:	4501                	li	a0,0
    80005778:	ffffd097          	auipc	ra,0xffffd
    8000577c:	3b4080e7          	jalr	948(ra) # 80002b2c <argstr>
    80005780:	02054963          	bltz	a0,800057b2 <sys_mkdir+0x54>
    80005784:	4681                	li	a3,0
    80005786:	4601                	li	a2,0
    80005788:	4585                	li	a1,1
    8000578a:	f7040513          	addi	a0,s0,-144
    8000578e:	fffff097          	auipc	ra,0xfffff
    80005792:	7fe080e7          	jalr	2046(ra) # 80004f8c <create>
    80005796:	cd11                	beqz	a0,800057b2 <sys_mkdir+0x54>
		end_op();
		return -1;
	}
	iunlockput(ip);
    80005798:	ffffe097          	auipc	ra,0xffffe
    8000579c:	124080e7          	jalr	292(ra) # 800038bc <iunlockput>
	end_op();
    800057a0:	fffff097          	auipc	ra,0xfffff
    800057a4:	90c080e7          	jalr	-1780(ra) # 800040ac <end_op>
	return 0;
    800057a8:	4501                	li	a0,0
}
    800057aa:	60aa                	ld	ra,136(sp)
    800057ac:	640a                	ld	s0,128(sp)
    800057ae:	6149                	addi	sp,sp,144
    800057b0:	8082                	ret
		end_op();
    800057b2:	fffff097          	auipc	ra,0xfffff
    800057b6:	8fa080e7          	jalr	-1798(ra) # 800040ac <end_op>
		return -1;
    800057ba:	557d                	li	a0,-1
    800057bc:	b7fd                	j	800057aa <sys_mkdir+0x4c>

00000000800057be <sys_mknod>:

uint64
sys_mknod(void)
{
    800057be:	7135                	addi	sp,sp,-160
    800057c0:	ed06                	sd	ra,152(sp)
    800057c2:	e922                	sd	s0,144(sp)
    800057c4:	1100                	addi	s0,sp,160
	struct inode *ip;
	char path[MAXPATH];
	int major, minor;

	begin_op();
    800057c6:	fffff097          	auipc	ra,0xfffff
    800057ca:	866080e7          	jalr	-1946(ra) # 8000402c <begin_op>
	if((argstr(0, path, MAXPATH)) < 0 ||
    800057ce:	08000613          	li	a2,128
    800057d2:	f7040593          	addi	a1,s0,-144
    800057d6:	4501                	li	a0,0
    800057d8:	ffffd097          	auipc	ra,0xffffd
    800057dc:	354080e7          	jalr	852(ra) # 80002b2c <argstr>
    800057e0:	04054a63          	bltz	a0,80005834 <sys_mknod+0x76>
			argint(1, &major) < 0 ||
    800057e4:	f6c40593          	addi	a1,s0,-148
    800057e8:	4505                	li	a0,1
    800057ea:	ffffd097          	auipc	ra,0xffffd
    800057ee:	2fe080e7          	jalr	766(ra) # 80002ae8 <argint>
	if((argstr(0, path, MAXPATH)) < 0 ||
    800057f2:	04054163          	bltz	a0,80005834 <sys_mknod+0x76>
			argint(2, &minor) < 0 ||
    800057f6:	f6840593          	addi	a1,s0,-152
    800057fa:	4509                	li	a0,2
    800057fc:	ffffd097          	auipc	ra,0xffffd
    80005800:	2ec080e7          	jalr	748(ra) # 80002ae8 <argint>
			argint(1, &major) < 0 ||
    80005804:	02054863          	bltz	a0,80005834 <sys_mknod+0x76>
			(ip = create(path, T_DEVICE, major, minor)) == 0){
    80005808:	f6841683          	lh	a3,-152(s0)
    8000580c:	f6c41603          	lh	a2,-148(s0)
    80005810:	458d                	li	a1,3
    80005812:	f7040513          	addi	a0,s0,-144
    80005816:	fffff097          	auipc	ra,0xfffff
    8000581a:	776080e7          	jalr	1910(ra) # 80004f8c <create>
			argint(2, &minor) < 0 ||
    8000581e:	c919                	beqz	a0,80005834 <sys_mknod+0x76>
		end_op();
		return -1;
	}
	iunlockput(ip);
    80005820:	ffffe097          	auipc	ra,0xffffe
    80005824:	09c080e7          	jalr	156(ra) # 800038bc <iunlockput>
	end_op();
    80005828:	fffff097          	auipc	ra,0xfffff
    8000582c:	884080e7          	jalr	-1916(ra) # 800040ac <end_op>
	return 0;
    80005830:	4501                	li	a0,0
    80005832:	a031                	j	8000583e <sys_mknod+0x80>
		end_op();
    80005834:	fffff097          	auipc	ra,0xfffff
    80005838:	878080e7          	jalr	-1928(ra) # 800040ac <end_op>
		return -1;
    8000583c:	557d                	li	a0,-1
}
    8000583e:	60ea                	ld	ra,152(sp)
    80005840:	644a                	ld	s0,144(sp)
    80005842:	610d                	addi	sp,sp,160
    80005844:	8082                	ret

0000000080005846 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005846:	7135                	addi	sp,sp,-160
    80005848:	ed06                	sd	ra,152(sp)
    8000584a:	e922                	sd	s0,144(sp)
    8000584c:	e526                	sd	s1,136(sp)
    8000584e:	e14a                	sd	s2,128(sp)
    80005850:	1100                	addi	s0,sp,160
	char path[MAXPATH];
	struct inode *ip;
	struct proc *p = myproc();
    80005852:	ffffc097          	auipc	ra,0xffffc
    80005856:	1ea080e7          	jalr	490(ra) # 80001a3c <myproc>
    8000585a:	892a                	mv	s2,a0

	begin_op();
    8000585c:	ffffe097          	auipc	ra,0xffffe
    80005860:	7d0080e7          	jalr	2000(ra) # 8000402c <begin_op>
	if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005864:	08000613          	li	a2,128
    80005868:	f6040593          	addi	a1,s0,-160
    8000586c:	4501                	li	a0,0
    8000586e:	ffffd097          	auipc	ra,0xffffd
    80005872:	2be080e7          	jalr	702(ra) # 80002b2c <argstr>
    80005876:	04054b63          	bltz	a0,800058cc <sys_chdir+0x86>
    8000587a:	f6040513          	addi	a0,s0,-160
    8000587e:	ffffe097          	auipc	ra,0xffffe
    80005882:	592080e7          	jalr	1426(ra) # 80003e10 <namei>
    80005886:	84aa                	mv	s1,a0
    80005888:	c131                	beqz	a0,800058cc <sys_chdir+0x86>
		end_op();
		return -1;
	}
	ilock(ip);
    8000588a:	ffffe097          	auipc	ra,0xffffe
    8000588e:	dd0080e7          	jalr	-560(ra) # 8000365a <ilock>
	if(ip->type != T_DIR){
    80005892:	04449703          	lh	a4,68(s1)
    80005896:	4785                	li	a5,1
    80005898:	04f71063          	bne	a4,a5,800058d8 <sys_chdir+0x92>
		iunlockput(ip);
		end_op();
		return -1;
	}
	iunlock(ip);
    8000589c:	8526                	mv	a0,s1
    8000589e:	ffffe097          	auipc	ra,0xffffe
    800058a2:	e7e080e7          	jalr	-386(ra) # 8000371c <iunlock>
	iput(p->cwd);
    800058a6:	15093503          	ld	a0,336(s2)
    800058aa:	ffffe097          	auipc	ra,0xffffe
    800058ae:	f6a080e7          	jalr	-150(ra) # 80003814 <iput>
	end_op();
    800058b2:	ffffe097          	auipc	ra,0xffffe
    800058b6:	7fa080e7          	jalr	2042(ra) # 800040ac <end_op>
	p->cwd = ip;
    800058ba:	14993823          	sd	s1,336(s2)
	return 0;
    800058be:	4501                	li	a0,0
}
    800058c0:	60ea                	ld	ra,152(sp)
    800058c2:	644a                	ld	s0,144(sp)
    800058c4:	64aa                	ld	s1,136(sp)
    800058c6:	690a                	ld	s2,128(sp)
    800058c8:	610d                	addi	sp,sp,160
    800058ca:	8082                	ret
		end_op();
    800058cc:	ffffe097          	auipc	ra,0xffffe
    800058d0:	7e0080e7          	jalr	2016(ra) # 800040ac <end_op>
		return -1;
    800058d4:	557d                	li	a0,-1
    800058d6:	b7ed                	j	800058c0 <sys_chdir+0x7a>
		iunlockput(ip);
    800058d8:	8526                	mv	a0,s1
    800058da:	ffffe097          	auipc	ra,0xffffe
    800058de:	fe2080e7          	jalr	-30(ra) # 800038bc <iunlockput>
		end_op();
    800058e2:	ffffe097          	auipc	ra,0xffffe
    800058e6:	7ca080e7          	jalr	1994(ra) # 800040ac <end_op>
		return -1;
    800058ea:	557d                	li	a0,-1
    800058ec:	bfd1                	j	800058c0 <sys_chdir+0x7a>

00000000800058ee <sys_exec>:

uint64
sys_exec(void)
{
    800058ee:	7145                	addi	sp,sp,-464
    800058f0:	e786                	sd	ra,456(sp)
    800058f2:	e3a2                	sd	s0,448(sp)
    800058f4:	ff26                	sd	s1,440(sp)
    800058f6:	fb4a                	sd	s2,432(sp)
    800058f8:	f74e                	sd	s3,424(sp)
    800058fa:	f352                	sd	s4,416(sp)
    800058fc:	ef56                	sd	s5,408(sp)
    800058fe:	0b80                	addi	s0,sp,464
	char path[MAXPATH], *argv[MAXARG];
	int i;
	uint64 uargv, uarg;

	if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005900:	08000613          	li	a2,128
    80005904:	f4040593          	addi	a1,s0,-192
    80005908:	4501                	li	a0,0
    8000590a:	ffffd097          	auipc	ra,0xffffd
    8000590e:	222080e7          	jalr	546(ra) # 80002b2c <argstr>
		return -1;
    80005912:	597d                	li	s2,-1
	if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005914:	0c054a63          	bltz	a0,800059e8 <sys_exec+0xfa>
    80005918:	e3840593          	addi	a1,s0,-456
    8000591c:	4505                	li	a0,1
    8000591e:	ffffd097          	auipc	ra,0xffffd
    80005922:	1ec080e7          	jalr	492(ra) # 80002b0a <argaddr>
    80005926:	0c054163          	bltz	a0,800059e8 <sys_exec+0xfa>
	}
	memset(argv, 0, sizeof(argv));
    8000592a:	10000613          	li	a2,256
    8000592e:	4581                	li	a1,0
    80005930:	e4040513          	addi	a0,s0,-448
    80005934:	ffffb097          	auipc	ra,0xffffb
    80005938:	3ac080e7          	jalr	940(ra) # 80000ce0 <memset>
	for(i=0;; i++){
		if(i >= NELEM(argv)){
    8000593c:	e4040493          	addi	s1,s0,-448
	memset(argv, 0, sizeof(argv));
    80005940:	89a6                	mv	s3,s1
    80005942:	4901                	li	s2,0
		if(i >= NELEM(argv)){
    80005944:	02000a13          	li	s4,32
    80005948:	00090a9b          	sext.w	s5,s2
			goto bad;
		}
		if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    8000594c:	00391513          	slli	a0,s2,0x3
    80005950:	e3040593          	addi	a1,s0,-464
    80005954:	e3843783          	ld	a5,-456(s0)
    80005958:	953e                	add	a0,a0,a5
    8000595a:	ffffd097          	auipc	ra,0xffffd
    8000595e:	0f4080e7          	jalr	244(ra) # 80002a4e <fetchaddr>
    80005962:	02054a63          	bltz	a0,80005996 <sys_exec+0xa8>
			goto bad;
		}
		if(uarg == 0){
    80005966:	e3043783          	ld	a5,-464(s0)
    8000596a:	c3b9                	beqz	a5,800059b0 <sys_exec+0xc2>
			argv[i] = 0;
			break;
		}
		argv[i] = kalloc();
    8000596c:	ffffb097          	auipc	ra,0xffffb
    80005970:	188080e7          	jalr	392(ra) # 80000af4 <kalloc>
    80005974:	85aa                	mv	a1,a0
    80005976:	00a9b023          	sd	a0,0(s3)
		if(argv[i] == 0)
    8000597a:	cd11                	beqz	a0,80005996 <sys_exec+0xa8>
			goto bad;
		if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    8000597c:	6621                	lui	a2,0x8
    8000597e:	e3043503          	ld	a0,-464(s0)
    80005982:	ffffd097          	auipc	ra,0xffffd
    80005986:	11e080e7          	jalr	286(ra) # 80002aa0 <fetchstr>
    8000598a:	00054663          	bltz	a0,80005996 <sys_exec+0xa8>
		if(i >= NELEM(argv)){
    8000598e:	0905                	addi	s2,s2,1
    80005990:	09a1                	addi	s3,s3,8
    80005992:	fb491be3          	bne	s2,s4,80005948 <sys_exec+0x5a>
		kfree(argv[i]);

	return ret;

bad:
	for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005996:	10048913          	addi	s2,s1,256
    8000599a:	6088                	ld	a0,0(s1)
    8000599c:	c529                	beqz	a0,800059e6 <sys_exec+0xf8>
		kfree(argv[i]);
    8000599e:	ffffb097          	auipc	ra,0xffffb
    800059a2:	05a080e7          	jalr	90(ra) # 800009f8 <kfree>
	for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800059a6:	04a1                	addi	s1,s1,8
    800059a8:	ff2499e3          	bne	s1,s2,8000599a <sys_exec+0xac>
	return -1;
    800059ac:	597d                	li	s2,-1
    800059ae:	a82d                	j	800059e8 <sys_exec+0xfa>
			argv[i] = 0;
    800059b0:	0a8e                	slli	s5,s5,0x3
    800059b2:	fc040793          	addi	a5,s0,-64
    800059b6:	9abe                	add	s5,s5,a5
    800059b8:	e80ab023          	sd	zero,-384(s5)
	int ret = exec(path, argv);
    800059bc:	e4040593          	addi	a1,s0,-448
    800059c0:	f4040513          	addi	a0,s0,-192
    800059c4:	fffff097          	auipc	ra,0xfffff
    800059c8:	194080e7          	jalr	404(ra) # 80004b58 <exec>
    800059cc:	892a                	mv	s2,a0
	for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800059ce:	10048993          	addi	s3,s1,256
    800059d2:	6088                	ld	a0,0(s1)
    800059d4:	c911                	beqz	a0,800059e8 <sys_exec+0xfa>
		kfree(argv[i]);
    800059d6:	ffffb097          	auipc	ra,0xffffb
    800059da:	022080e7          	jalr	34(ra) # 800009f8 <kfree>
	for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800059de:	04a1                	addi	s1,s1,8
    800059e0:	ff3499e3          	bne	s1,s3,800059d2 <sys_exec+0xe4>
    800059e4:	a011                	j	800059e8 <sys_exec+0xfa>
	return -1;
    800059e6:	597d                	li	s2,-1
}
    800059e8:	854a                	mv	a0,s2
    800059ea:	60be                	ld	ra,456(sp)
    800059ec:	641e                	ld	s0,448(sp)
    800059ee:	74fa                	ld	s1,440(sp)
    800059f0:	795a                	ld	s2,432(sp)
    800059f2:	79ba                	ld	s3,424(sp)
    800059f4:	7a1a                	ld	s4,416(sp)
    800059f6:	6afa                	ld	s5,408(sp)
    800059f8:	6179                	addi	sp,sp,464
    800059fa:	8082                	ret

00000000800059fc <sys_pipe>:

uint64
sys_pipe(void)
{
    800059fc:	7139                	addi	sp,sp,-64
    800059fe:	fc06                	sd	ra,56(sp)
    80005a00:	f822                	sd	s0,48(sp)
    80005a02:	f426                	sd	s1,40(sp)
    80005a04:	0080                	addi	s0,sp,64
	uint64 fdarray; // user pointer to array of two integers
	struct file *rf, *wf;
	int fd0, fd1;
	struct proc *p = myproc();
    80005a06:	ffffc097          	auipc	ra,0xffffc
    80005a0a:	036080e7          	jalr	54(ra) # 80001a3c <myproc>
    80005a0e:	84aa                	mv	s1,a0

	if(argaddr(0, &fdarray) < 0)
    80005a10:	fd840593          	addi	a1,s0,-40
    80005a14:	4501                	li	a0,0
    80005a16:	ffffd097          	auipc	ra,0xffffd
    80005a1a:	0f4080e7          	jalr	244(ra) # 80002b0a <argaddr>
		return -1;
    80005a1e:	57fd                	li	a5,-1
	if(argaddr(0, &fdarray) < 0)
    80005a20:	0e054063          	bltz	a0,80005b00 <sys_pipe+0x104>
	if(pipealloc(&rf, &wf) < 0)
    80005a24:	fc840593          	addi	a1,s0,-56
    80005a28:	fd040513          	addi	a0,s0,-48
    80005a2c:	fffff097          	auipc	ra,0xfffff
    80005a30:	dfc080e7          	jalr	-516(ra) # 80004828 <pipealloc>
		return -1;
    80005a34:	57fd                	li	a5,-1
	if(pipealloc(&rf, &wf) < 0)
    80005a36:	0c054563          	bltz	a0,80005b00 <sys_pipe+0x104>
	fd0 = -1;
    80005a3a:	fcf42223          	sw	a5,-60(s0)
	if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005a3e:	fd043503          	ld	a0,-48(s0)
    80005a42:	fffff097          	auipc	ra,0xfffff
    80005a46:	508080e7          	jalr	1288(ra) # 80004f4a <fdalloc>
    80005a4a:	fca42223          	sw	a0,-60(s0)
    80005a4e:	08054c63          	bltz	a0,80005ae6 <sys_pipe+0xea>
    80005a52:	fc843503          	ld	a0,-56(s0)
    80005a56:	fffff097          	auipc	ra,0xfffff
    80005a5a:	4f4080e7          	jalr	1268(ra) # 80004f4a <fdalloc>
    80005a5e:	fca42023          	sw	a0,-64(s0)
    80005a62:	06054863          	bltz	a0,80005ad2 <sys_pipe+0xd6>
			p->ofile[fd0] = 0;
		fileclose(rf);
		fileclose(wf);
		return -1;
	}
	if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005a66:	4691                	li	a3,4
    80005a68:	fc440613          	addi	a2,s0,-60
    80005a6c:	fd843583          	ld	a1,-40(s0)
    80005a70:	68a8                	ld	a0,80(s1)
    80005a72:	ffffc097          	auipc	ra,0xffffc
    80005a76:	c10080e7          	jalr	-1008(ra) # 80001682 <copyout>
    80005a7a:	02054063          	bltz	a0,80005a9a <sys_pipe+0x9e>
			copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005a7e:	4691                	li	a3,4
    80005a80:	fc040613          	addi	a2,s0,-64
    80005a84:	fd843583          	ld	a1,-40(s0)
    80005a88:	0591                	addi	a1,a1,4
    80005a8a:	68a8                	ld	a0,80(s1)
    80005a8c:	ffffc097          	auipc	ra,0xffffc
    80005a90:	bf6080e7          	jalr	-1034(ra) # 80001682 <copyout>
		p->ofile[fd1] = 0;
		fileclose(rf);
		fileclose(wf);
		return -1;
	}
	return 0;
    80005a94:	4781                	li	a5,0
	if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005a96:	06055563          	bgez	a0,80005b00 <sys_pipe+0x104>
		p->ofile[fd0] = 0;
    80005a9a:	fc442783          	lw	a5,-60(s0)
    80005a9e:	07e9                	addi	a5,a5,26
    80005aa0:	078e                	slli	a5,a5,0x3
    80005aa2:	97a6                	add	a5,a5,s1
    80005aa4:	0007b023          	sd	zero,0(a5)
		p->ofile[fd1] = 0;
    80005aa8:	fc042503          	lw	a0,-64(s0)
    80005aac:	0569                	addi	a0,a0,26
    80005aae:	050e                	slli	a0,a0,0x3
    80005ab0:	9526                	add	a0,a0,s1
    80005ab2:	00053023          	sd	zero,0(a0)
		fileclose(rf);
    80005ab6:	fd043503          	ld	a0,-48(s0)
    80005aba:	fffff097          	auipc	ra,0xfffff
    80005abe:	a3e080e7          	jalr	-1474(ra) # 800044f8 <fileclose>
		fileclose(wf);
    80005ac2:	fc843503          	ld	a0,-56(s0)
    80005ac6:	fffff097          	auipc	ra,0xfffff
    80005aca:	a32080e7          	jalr	-1486(ra) # 800044f8 <fileclose>
		return -1;
    80005ace:	57fd                	li	a5,-1
    80005ad0:	a805                	j	80005b00 <sys_pipe+0x104>
		if(fd0 >= 0)
    80005ad2:	fc442783          	lw	a5,-60(s0)
    80005ad6:	0007c863          	bltz	a5,80005ae6 <sys_pipe+0xea>
			p->ofile[fd0] = 0;
    80005ada:	01a78513          	addi	a0,a5,26
    80005ade:	050e                	slli	a0,a0,0x3
    80005ae0:	9526                	add	a0,a0,s1
    80005ae2:	00053023          	sd	zero,0(a0)
		fileclose(rf);
    80005ae6:	fd043503          	ld	a0,-48(s0)
    80005aea:	fffff097          	auipc	ra,0xfffff
    80005aee:	a0e080e7          	jalr	-1522(ra) # 800044f8 <fileclose>
		fileclose(wf);
    80005af2:	fc843503          	ld	a0,-56(s0)
    80005af6:	fffff097          	auipc	ra,0xfffff
    80005afa:	a02080e7          	jalr	-1534(ra) # 800044f8 <fileclose>
		return -1;
    80005afe:	57fd                	li	a5,-1
}
    80005b00:	853e                	mv	a0,a5
    80005b02:	70e2                	ld	ra,56(sp)
    80005b04:	7442                	ld	s0,48(sp)
    80005b06:	74a2                	ld	s1,40(sp)
    80005b08:	6121                	addi	sp,sp,64
    80005b0a:	8082                	ret
    80005b0c:	0000                	unimp
	...

0000000080005b10 <kernelvec>:
    80005b10:	7111                	addi	sp,sp,-256
    80005b12:	e006                	sd	ra,0(sp)
    80005b14:	e40a                	sd	sp,8(sp)
    80005b16:	e80e                	sd	gp,16(sp)
    80005b18:	ec12                	sd	tp,24(sp)
    80005b1a:	f016                	sd	t0,32(sp)
    80005b1c:	f41a                	sd	t1,40(sp)
    80005b1e:	f81e                	sd	t2,48(sp)
    80005b20:	fc22                	sd	s0,56(sp)
    80005b22:	e0a6                	sd	s1,64(sp)
    80005b24:	e4aa                	sd	a0,72(sp)
    80005b26:	e8ae                	sd	a1,80(sp)
    80005b28:	ecb2                	sd	a2,88(sp)
    80005b2a:	f0b6                	sd	a3,96(sp)
    80005b2c:	f4ba                	sd	a4,104(sp)
    80005b2e:	f8be                	sd	a5,112(sp)
    80005b30:	fcc2                	sd	a6,120(sp)
    80005b32:	e146                	sd	a7,128(sp)
    80005b34:	e54a                	sd	s2,136(sp)
    80005b36:	e94e                	sd	s3,144(sp)
    80005b38:	ed52                	sd	s4,152(sp)
    80005b3a:	f156                	sd	s5,160(sp)
    80005b3c:	f55a                	sd	s6,168(sp)
    80005b3e:	f95e                	sd	s7,176(sp)
    80005b40:	fd62                	sd	s8,184(sp)
    80005b42:	e1e6                	sd	s9,192(sp)
    80005b44:	e5ea                	sd	s10,200(sp)
    80005b46:	e9ee                	sd	s11,208(sp)
    80005b48:	edf2                	sd	t3,216(sp)
    80005b4a:	f1f6                	sd	t4,224(sp)
    80005b4c:	f5fa                	sd	t5,232(sp)
    80005b4e:	f9fe                	sd	t6,240(sp)
    80005b50:	dcbfc0ef          	jal	ra,8000291a <kerneltrap>
    80005b54:	6082                	ld	ra,0(sp)
    80005b56:	6122                	ld	sp,8(sp)
    80005b58:	61c2                	ld	gp,16(sp)
    80005b5a:	7282                	ld	t0,32(sp)
    80005b5c:	7322                	ld	t1,40(sp)
    80005b5e:	73c2                	ld	t2,48(sp)
    80005b60:	7462                	ld	s0,56(sp)
    80005b62:	6486                	ld	s1,64(sp)
    80005b64:	6526                	ld	a0,72(sp)
    80005b66:	65c6                	ld	a1,80(sp)
    80005b68:	6666                	ld	a2,88(sp)
    80005b6a:	7686                	ld	a3,96(sp)
    80005b6c:	7726                	ld	a4,104(sp)
    80005b6e:	77c6                	ld	a5,112(sp)
    80005b70:	7866                	ld	a6,120(sp)
    80005b72:	688a                	ld	a7,128(sp)
    80005b74:	692a                	ld	s2,136(sp)
    80005b76:	69ca                	ld	s3,144(sp)
    80005b78:	6a6a                	ld	s4,152(sp)
    80005b7a:	7a8a                	ld	s5,160(sp)
    80005b7c:	7b2a                	ld	s6,168(sp)
    80005b7e:	7bca                	ld	s7,176(sp)
    80005b80:	7c6a                	ld	s8,184(sp)
    80005b82:	6c8e                	ld	s9,192(sp)
    80005b84:	6d2e                	ld	s10,200(sp)
    80005b86:	6dce                	ld	s11,208(sp)
    80005b88:	6e6e                	ld	t3,216(sp)
    80005b8a:	7e8e                	ld	t4,224(sp)
    80005b8c:	7f2e                	ld	t5,232(sp)
    80005b8e:	7fce                	ld	t6,240(sp)
    80005b90:	6111                	addi	sp,sp,256
    80005b92:	10200073          	sret
    80005b96:	00000013          	nop
    80005b9a:	00000013          	nop
    80005b9e:	0001                	nop

0000000080005ba0 <timervec>:
    80005ba0:	34051573          	csrrw	a0,mscratch,a0
    80005ba4:	e10c                	sd	a1,0(a0)
    80005ba6:	e510                	sd	a2,8(a0)
    80005ba8:	e914                	sd	a3,16(a0)
    80005baa:	6d0c                	ld	a1,24(a0)
    80005bac:	7110                	ld	a2,32(a0)
    80005bae:	6194                	ld	a3,0(a1)
    80005bb0:	96b2                	add	a3,a3,a2
    80005bb2:	e194                	sd	a3,0(a1)
    80005bb4:	4589                	li	a1,2
    80005bb6:	14459073          	csrw	sip,a1
    80005bba:	6914                	ld	a3,16(a0)
    80005bbc:	6510                	ld	a2,8(a0)
    80005bbe:	610c                	ld	a1,0(a0)
    80005bc0:	34051573          	csrrw	a0,mscratch,a0
    80005bc4:	30200073          	mret
	...

0000000080005bca <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005bca:	1141                	addi	sp,sp,-16
    80005bcc:	e422                	sd	s0,8(sp)
    80005bce:	0800                	addi	s0,sp,16
	// set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005bd0:	0c0007b7          	lui	a5,0xc000
    80005bd4:	4705                	li	a4,1
    80005bd6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005bd8:	c3d8                	sw	a4,4(a5)
}
    80005bda:	6422                	ld	s0,8(sp)
    80005bdc:	0141                	addi	sp,sp,16
    80005bde:	8082                	ret

0000000080005be0 <plicinithart>:

void
plicinithart(void)
{
    80005be0:	1141                	addi	sp,sp,-16
    80005be2:	e406                	sd	ra,8(sp)
    80005be4:	e022                	sd	s0,0(sp)
    80005be6:	0800                	addi	s0,sp,16
	int hart = cpuid();
    80005be8:	ffffc097          	auipc	ra,0xffffc
    80005bec:	e28080e7          	jalr	-472(ra) # 80001a10 <cpuid>

  // set uart's enable bit for this hart's S-mode.
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005bf0:	0085171b          	slliw	a4,a0,0x8
    80005bf4:	0c0027b7          	lui	a5,0xc002
    80005bf8:	97ba                	add	a5,a5,a4
    80005bfa:	40200713          	li	a4,1026
    80005bfe:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005c02:	00d5151b          	slliw	a0,a0,0xd
    80005c06:	0c2017b7          	lui	a5,0xc201
    80005c0a:	953e                	add	a0,a0,a5
    80005c0c:	00052023          	sw	zero,0(a0)
}
    80005c10:	60a2                	ld	ra,8(sp)
    80005c12:	6402                	ld	s0,0(sp)
    80005c14:	0141                	addi	sp,sp,16
    80005c16:	8082                	ret

0000000080005c18 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005c18:	1141                	addi	sp,sp,-16
    80005c1a:	e406                	sd	ra,8(sp)
    80005c1c:	e022                	sd	s0,0(sp)
    80005c1e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005c20:	ffffc097          	auipc	ra,0xffffc
    80005c24:	df0080e7          	jalr	-528(ra) # 80001a10 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005c28:	00d5179b          	slliw	a5,a0,0xd
    80005c2c:	0c201537          	lui	a0,0xc201
    80005c30:	953e                	add	a0,a0,a5
  return irq;
}
    80005c32:	4148                	lw	a0,4(a0)
    80005c34:	60a2                	ld	ra,8(sp)
    80005c36:	6402                	ld	s0,0(sp)
    80005c38:	0141                	addi	sp,sp,16
    80005c3a:	8082                	ret

0000000080005c3c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005c3c:	1101                	addi	sp,sp,-32
    80005c3e:	ec06                	sd	ra,24(sp)
    80005c40:	e822                	sd	s0,16(sp)
    80005c42:	e426                	sd	s1,8(sp)
    80005c44:	1000                	addi	s0,sp,32
    80005c46:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005c48:	ffffc097          	auipc	ra,0xffffc
    80005c4c:	dc8080e7          	jalr	-568(ra) # 80001a10 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005c50:	00d5151b          	slliw	a0,a0,0xd
    80005c54:	0c2017b7          	lui	a5,0xc201
    80005c58:	97aa                	add	a5,a5,a0
    80005c5a:	c3c4                	sw	s1,4(a5)
}
    80005c5c:	60e2                	ld	ra,24(sp)
    80005c5e:	6442                	ld	s0,16(sp)
    80005c60:	64a2                	ld	s1,8(sp)
    80005c62:	6105                	addi	sp,sp,32
    80005c64:	8082                	ret

0000000080005c66 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005c66:	1141                	addi	sp,sp,-16
    80005c68:	e406                	sd	ra,8(sp)
    80005c6a:	e022                	sd	s0,0(sp)
    80005c6c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005c6e:	479d                	li	a5,7
    80005c70:	06a7c963          	blt	a5,a0,80005ce2 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    80005c74:	0002a797          	auipc	a5,0x2a
    80005c78:	38c78793          	addi	a5,a5,908 # 80030000 <disk>
    80005c7c:	00a78733          	add	a4,a5,a0
    80005c80:	67c1                	lui	a5,0x10
    80005c82:	97ba                	add	a5,a5,a4
    80005c84:	0187c783          	lbu	a5,24(a5) # 10018 <_entry-0x7ffeffe8>
    80005c88:	e7ad                	bnez	a5,80005cf2 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005c8a:	00451793          	slli	a5,a0,0x4
    80005c8e:	0003a717          	auipc	a4,0x3a
    80005c92:	37270713          	addi	a4,a4,882 # 80040000 <disk+0x10000>
    80005c96:	6314                	ld	a3,0(a4)
    80005c98:	96be                	add	a3,a3,a5
    80005c9a:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80005c9e:	6314                	ld	a3,0(a4)
    80005ca0:	96be                	add	a3,a3,a5
    80005ca2:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80005ca6:	6314                	ld	a3,0(a4)
    80005ca8:	96be                	add	a3,a3,a5
    80005caa:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    80005cae:	6318                	ld	a4,0(a4)
    80005cb0:	97ba                	add	a5,a5,a4
    80005cb2:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80005cb6:	0002a797          	auipc	a5,0x2a
    80005cba:	34a78793          	addi	a5,a5,842 # 80030000 <disk>
    80005cbe:	97aa                	add	a5,a5,a0
    80005cc0:	6541                	lui	a0,0x10
    80005cc2:	953e                	add	a0,a0,a5
    80005cc4:	4785                	li	a5,1
    80005cc6:	00f50c23          	sb	a5,24(a0) # 10018 <_entry-0x7ffeffe8>
  wakeup(&disk.free[0]);
    80005cca:	0003a517          	auipc	a0,0x3a
    80005cce:	34e50513          	addi	a0,a0,846 # 80040018 <disk+0x10018>
    80005cd2:	ffffc097          	auipc	ra,0xffffc
    80005cd6:	5b2080e7          	jalr	1458(ra) # 80002284 <wakeup>
}
    80005cda:	60a2                	ld	ra,8(sp)
    80005cdc:	6402                	ld	s0,0(sp)
    80005cde:	0141                	addi	sp,sp,16
    80005ce0:	8082                	ret
    panic("free_desc 1");
    80005ce2:	00003517          	auipc	a0,0x3
    80005ce6:	a8e50513          	addi	a0,a0,-1394 # 80008770 <syscalls+0x320>
    80005cea:	ffffb097          	auipc	ra,0xffffb
    80005cee:	854080e7          	jalr	-1964(ra) # 8000053e <panic>
    panic("free_desc 2");
    80005cf2:	00003517          	auipc	a0,0x3
    80005cf6:	a8e50513          	addi	a0,a0,-1394 # 80008780 <syscalls+0x330>
    80005cfa:	ffffb097          	auipc	ra,0xffffb
    80005cfe:	844080e7          	jalr	-1980(ra) # 8000053e <panic>

0000000080005d02 <virtio_disk_init>:
{
    80005d02:	1101                	addi	sp,sp,-32
    80005d04:	ec06                	sd	ra,24(sp)
    80005d06:	e822                	sd	s0,16(sp)
    80005d08:	e426                	sd	s1,8(sp)
    80005d0a:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005d0c:	00003597          	auipc	a1,0x3
    80005d10:	a8458593          	addi	a1,a1,-1404 # 80008790 <syscalls+0x340>
    80005d14:	0003a517          	auipc	a0,0x3a
    80005d18:	41450513          	addi	a0,a0,1044 # 80040128 <disk+0x10128>
    80005d1c:	ffffb097          	auipc	ra,0xffffb
    80005d20:	e38080e7          	jalr	-456(ra) # 80000b54 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005d24:	100017b7          	lui	a5,0x10001
    80005d28:	4398                	lw	a4,0(a5)
    80005d2a:	2701                	sext.w	a4,a4
    80005d2c:	747277b7          	lui	a5,0x74727
    80005d30:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005d34:	0ef71163          	bne	a4,a5,80005e16 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005d38:	100017b7          	lui	a5,0x10001
    80005d3c:	43dc                	lw	a5,4(a5)
    80005d3e:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005d40:	4705                	li	a4,1
    80005d42:	0ce79a63          	bne	a5,a4,80005e16 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005d46:	100017b7          	lui	a5,0x10001
    80005d4a:	479c                	lw	a5,8(a5)
    80005d4c:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005d4e:	4709                	li	a4,2
    80005d50:	0ce79363          	bne	a5,a4,80005e16 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005d54:	100017b7          	lui	a5,0x10001
    80005d58:	47d8                	lw	a4,12(a5)
    80005d5a:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005d5c:	554d47b7          	lui	a5,0x554d4
    80005d60:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005d64:	0af71963          	bne	a4,a5,80005e16 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005d68:	100017b7          	lui	a5,0x10001
    80005d6c:	4705                	li	a4,1
    80005d6e:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005d70:	470d                	li	a4,3
    80005d72:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005d74:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80005d76:	c7ffe737          	lui	a4,0xc7ffe
    80005d7a:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fb675f>
    80005d7e:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005d80:	2701                	sext.w	a4,a4
    80005d82:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005d84:	472d                	li	a4,11
    80005d86:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005d88:	473d                	li	a4,15
    80005d8a:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    80005d8c:	6721                	lui	a4,0x8
    80005d8e:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005d90:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005d94:	5bdc                	lw	a5,52(a5)
    80005d96:	2781                	sext.w	a5,a5
  if(max == 0)
    80005d98:	c7d9                	beqz	a5,80005e26 <virtio_disk_init+0x124>
  if(max < NUM)
    80005d9a:	471d                	li	a4,7
    80005d9c:	08f77d63          	bgeu	a4,a5,80005e36 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80005da0:	100014b7          	lui	s1,0x10001
    80005da4:	47a1                	li	a5,8
    80005da6:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80005da8:	6641                	lui	a2,0x10
    80005daa:	4581                	li	a1,0
    80005dac:	0002a517          	auipc	a0,0x2a
    80005db0:	25450513          	addi	a0,a0,596 # 80030000 <disk>
    80005db4:	ffffb097          	auipc	ra,0xffffb
    80005db8:	f2c080e7          	jalr	-212(ra) # 80000ce0 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    80005dbc:	0002a717          	auipc	a4,0x2a
    80005dc0:	24470713          	addi	a4,a4,580 # 80030000 <disk>
    80005dc4:	00f75793          	srli	a5,a4,0xf
    80005dc8:	2781                	sext.w	a5,a5
    80005dca:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    80005dcc:	0003a797          	auipc	a5,0x3a
    80005dd0:	23478793          	addi	a5,a5,564 # 80040000 <disk+0x10000>
    80005dd4:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80005dd6:	0002a717          	auipc	a4,0x2a
    80005dda:	2aa70713          	addi	a4,a4,682 # 80030080 <disk+0x80>
    80005dde:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80005de0:	00032717          	auipc	a4,0x32
    80005de4:	22070713          	addi	a4,a4,544 # 80038000 <disk+0x8000>
    80005de8:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    80005dea:	4705                	li	a4,1
    80005dec:	00e78c23          	sb	a4,24(a5)
    80005df0:	00e78ca3          	sb	a4,25(a5)
    80005df4:	00e78d23          	sb	a4,26(a5)
    80005df8:	00e78da3          	sb	a4,27(a5)
    80005dfc:	00e78e23          	sb	a4,28(a5)
    80005e00:	00e78ea3          	sb	a4,29(a5)
    80005e04:	00e78f23          	sb	a4,30(a5)
    80005e08:	00e78fa3          	sb	a4,31(a5)
}
    80005e0c:	60e2                	ld	ra,24(sp)
    80005e0e:	6442                	ld	s0,16(sp)
    80005e10:	64a2                	ld	s1,8(sp)
    80005e12:	6105                	addi	sp,sp,32
    80005e14:	8082                	ret
    panic("could not find virtio disk");
    80005e16:	00003517          	auipc	a0,0x3
    80005e1a:	98a50513          	addi	a0,a0,-1654 # 800087a0 <syscalls+0x350>
    80005e1e:	ffffa097          	auipc	ra,0xffffa
    80005e22:	720080e7          	jalr	1824(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    80005e26:	00003517          	auipc	a0,0x3
    80005e2a:	99a50513          	addi	a0,a0,-1638 # 800087c0 <syscalls+0x370>
    80005e2e:	ffffa097          	auipc	ra,0xffffa
    80005e32:	710080e7          	jalr	1808(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    80005e36:	00003517          	auipc	a0,0x3
    80005e3a:	9aa50513          	addi	a0,a0,-1622 # 800087e0 <syscalls+0x390>
    80005e3e:	ffffa097          	auipc	ra,0xffffa
    80005e42:	700080e7          	jalr	1792(ra) # 8000053e <panic>

0000000080005e46 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80005e46:	7159                	addi	sp,sp,-112
    80005e48:	f486                	sd	ra,104(sp)
    80005e4a:	f0a2                	sd	s0,96(sp)
    80005e4c:	eca6                	sd	s1,88(sp)
    80005e4e:	e8ca                	sd	s2,80(sp)
    80005e50:	e4ce                	sd	s3,72(sp)
    80005e52:	e0d2                	sd	s4,64(sp)
    80005e54:	fc56                	sd	s5,56(sp)
    80005e56:	f85a                	sd	s6,48(sp)
    80005e58:	f45e                	sd	s7,40(sp)
    80005e5a:	f062                	sd	s8,32(sp)
    80005e5c:	ec66                	sd	s9,24(sp)
    80005e5e:	e86a                	sd	s10,16(sp)
    80005e60:	1880                	addi	s0,sp,112
    80005e62:	892a                	mv	s2,a0
    80005e64:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80005e66:	00c52c83          	lw	s9,12(a0)
    80005e6a:	001c9c9b          	slliw	s9,s9,0x1
    80005e6e:	1c82                	slli	s9,s9,0x20
    80005e70:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80005e74:	0003a517          	auipc	a0,0x3a
    80005e78:	2b450513          	addi	a0,a0,692 # 80040128 <disk+0x10128>
    80005e7c:	ffffb097          	auipc	ra,0xffffb
    80005e80:	d68080e7          	jalr	-664(ra) # 80000be4 <acquire>
  for(int i = 0; i < 3; i++){
    80005e84:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80005e86:	4c21                	li	s8,8
      disk.free[i] = 0;
    80005e88:	0002ab97          	auipc	s7,0x2a
    80005e8c:	178b8b93          	addi	s7,s7,376 # 80030000 <disk>
    80005e90:	6b41                	lui	s6,0x10
  for(int i = 0; i < 3; i++){
    80005e92:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80005e94:	8a4e                	mv	s4,s3
    80005e96:	a051                	j	80005f1a <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    80005e98:	00fb86b3          	add	a3,s7,a5
    80005e9c:	96da                	add	a3,a3,s6
    80005e9e:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80005ea2:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    80005ea4:	0207c563          	bltz	a5,80005ece <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80005ea8:	2485                	addiw	s1,s1,1
    80005eaa:	0711                	addi	a4,a4,4
    80005eac:	23548c63          	beq	s1,s5,800060e4 <virtio_disk_rw+0x29e>
    idx[i] = alloc_desc();
    80005eb0:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80005eb2:	0003a697          	auipc	a3,0x3a
    80005eb6:	16668693          	addi	a3,a3,358 # 80040018 <disk+0x10018>
    80005eba:	87d2                	mv	a5,s4
    if(disk.free[i]){
    80005ebc:	0006c583          	lbu	a1,0(a3)
    80005ec0:	fde1                	bnez	a1,80005e98 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80005ec2:	2785                	addiw	a5,a5,1
    80005ec4:	0685                	addi	a3,a3,1
    80005ec6:	ff879be3          	bne	a5,s8,80005ebc <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    80005eca:	57fd                	li	a5,-1
    80005ecc:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    80005ece:	02905a63          	blez	s1,80005f02 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80005ed2:	f9042503          	lw	a0,-112(s0)
    80005ed6:	00000097          	auipc	ra,0x0
    80005eda:	d90080e7          	jalr	-624(ra) # 80005c66 <free_desc>
      for(int j = 0; j < i; j++)
    80005ede:	4785                	li	a5,1
    80005ee0:	0297d163          	bge	a5,s1,80005f02 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80005ee4:	f9442503          	lw	a0,-108(s0)
    80005ee8:	00000097          	auipc	ra,0x0
    80005eec:	d7e080e7          	jalr	-642(ra) # 80005c66 <free_desc>
      for(int j = 0; j < i; j++)
    80005ef0:	4789                	li	a5,2
    80005ef2:	0097d863          	bge	a5,s1,80005f02 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80005ef6:	f9842503          	lw	a0,-104(s0)
    80005efa:	00000097          	auipc	ra,0x0
    80005efe:	d6c080e7          	jalr	-660(ra) # 80005c66 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80005f02:	0003a597          	auipc	a1,0x3a
    80005f06:	22658593          	addi	a1,a1,550 # 80040128 <disk+0x10128>
    80005f0a:	0003a517          	auipc	a0,0x3a
    80005f0e:	10e50513          	addi	a0,a0,270 # 80040018 <disk+0x10018>
    80005f12:	ffffc097          	auipc	ra,0xffffc
    80005f16:	1e6080e7          	jalr	486(ra) # 800020f8 <sleep>
  for(int i = 0; i < 3; i++){
    80005f1a:	f9040713          	addi	a4,s0,-112
    80005f1e:	84ce                	mv	s1,s3
    80005f20:	bf41                	j	80005eb0 <virtio_disk_rw+0x6a>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    80005f22:	6705                	lui	a4,0x1
    80005f24:	972e                	add	a4,a4,a1
    80005f26:	0712                	slli	a4,a4,0x4
    80005f28:	0002a697          	auipc	a3,0x2a
    80005f2c:	0d868693          	addi	a3,a3,216 # 80030000 <disk>
    80005f30:	9736                	add	a4,a4,a3
    80005f32:	4685                	li	a3,1
    80005f34:	0ad72423          	sw	a3,168(a4) # 10a8 <_entry-0x7fffef58>
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    80005f38:	6705                	lui	a4,0x1
    80005f3a:	972e                	add	a4,a4,a1
    80005f3c:	0712                	slli	a4,a4,0x4
    80005f3e:	0002a697          	auipc	a3,0x2a
    80005f42:	0c268693          	addi	a3,a3,194 # 80030000 <disk>
    80005f46:	9736                	add	a4,a4,a3
    80005f48:	0a072623          	sw	zero,172(a4) # 10ac <_entry-0x7fffef54>
  buf0->sector = sector;
    80005f4c:	0b973823          	sd	s9,176(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80005f50:	7641                	lui	a2,0xffff0
    80005f52:	963e                	add	a2,a2,a5
    80005f54:	0003a717          	auipc	a4,0x3a
    80005f58:	0ac70713          	addi	a4,a4,172 # 80040000 <disk+0x10000>
    80005f5c:	6314                	ld	a3,0(a4)
    80005f5e:	96b2                	add	a3,a3,a2
    80005f60:	e288                	sd	a0,0(a3)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80005f62:	6314                	ld	a3,0(a4)
    80005f64:	96b2                	add	a3,a3,a2
    80005f66:	4541                	li	a0,16
    80005f68:	c688                	sw	a0,8(a3)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80005f6a:	6314                	ld	a3,0(a4)
    80005f6c:	96b2                	add	a3,a3,a2
    80005f6e:	4505                	li	a0,1
    80005f70:	00a69623          	sh	a0,12(a3)
  disk.desc[idx[0]].next = idx[1];
    80005f74:	f9442683          	lw	a3,-108(s0)
    80005f78:	6308                	ld	a0,0(a4)
    80005f7a:	962a                	add	a2,a2,a0
    80005f7c:	00d61723          	sh	a3,14(a2) # ffffffffffff000e <end+0xffffffff7ffa800e>

  disk.desc[idx[1]].addr = (uint64) b->data;
    80005f80:	0692                	slli	a3,a3,0x4
    80005f82:	6310                	ld	a2,0(a4)
    80005f84:	9636                	add	a2,a2,a3
    80005f86:	05890513          	addi	a0,s2,88
    80005f8a:	e208                	sd	a0,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    80005f8c:	6318                	ld	a4,0(a4)
    80005f8e:	9736                	add	a4,a4,a3
    80005f90:	40000613          	li	a2,1024
    80005f94:	c710                	sw	a2,8(a4)
  if(write)
    80005f96:	120d0e63          	beqz	s10,800060d2 <virtio_disk_rw+0x28c>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    80005f9a:	0003a717          	auipc	a4,0x3a
    80005f9e:	06673703          	ld	a4,102(a4) # 80040000 <disk+0x10000>
    80005fa2:	9736                	add	a4,a4,a3
    80005fa4:	00071623          	sh	zero,12(a4)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80005fa8:	0002a817          	auipc	a6,0x2a
    80005fac:	05880813          	addi	a6,a6,88 # 80030000 <disk>
    80005fb0:	0003a717          	auipc	a4,0x3a
    80005fb4:	05070713          	addi	a4,a4,80 # 80040000 <disk+0x10000>
    80005fb8:	6310                	ld	a2,0(a4)
    80005fba:	9636                	add	a2,a2,a3
    80005fbc:	00c65503          	lhu	a0,12(a2)
    80005fc0:	00156513          	ori	a0,a0,1
    80005fc4:	00a61623          	sh	a0,12(a2)
  disk.desc[idx[1]].next = idx[2];
    80005fc8:	f9842603          	lw	a2,-104(s0)
    80005fcc:	6308                	ld	a0,0(a4)
    80005fce:	96aa                	add	a3,a3,a0
    80005fd0:	00c69723          	sh	a2,14(a3)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80005fd4:	6685                	lui	a3,0x1
    80005fd6:	96ae                	add	a3,a3,a1
    80005fd8:	0692                	slli	a3,a3,0x4
    80005fda:	96c2                	add	a3,a3,a6
    80005fdc:	557d                	li	a0,-1
    80005fde:	02a68823          	sb	a0,48(a3) # 1030 <_entry-0x7fffefd0>
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80005fe2:	0612                	slli	a2,a2,0x4
    80005fe4:	6308                	ld	a0,0(a4)
    80005fe6:	9532                	add	a0,a0,a2
    80005fe8:	03078793          	addi	a5,a5,48
    80005fec:	97c2                	add	a5,a5,a6
    80005fee:	e11c                	sd	a5,0(a0)
  disk.desc[idx[2]].len = 1;
    80005ff0:	631c                	ld	a5,0(a4)
    80005ff2:	97b2                	add	a5,a5,a2
    80005ff4:	4505                	li	a0,1
    80005ff6:	c788                	sw	a0,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80005ff8:	631c                	ld	a5,0(a4)
    80005ffa:	97b2                	add	a5,a5,a2
    80005ffc:	4809                	li	a6,2
    80005ffe:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80006002:	631c                	ld	a5,0(a4)
    80006004:	963e                	add	a2,a2,a5
    80006006:	00061723          	sh	zero,14(a2)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    8000600a:	00a92223          	sw	a0,4(s2)
  disk.info[idx[0]].b = b;
    8000600e:	0326b423          	sd	s2,40(a3)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006012:	6714                	ld	a3,8(a4)
    80006014:	0026d783          	lhu	a5,2(a3)
    80006018:	8b9d                	andi	a5,a5,7
    8000601a:	0786                	slli	a5,a5,0x1
    8000601c:	97b6                	add	a5,a5,a3
    8000601e:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    80006022:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006026:	6718                	ld	a4,8(a4)
    80006028:	00275783          	lhu	a5,2(a4)
    8000602c:	2785                	addiw	a5,a5,1
    8000602e:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006032:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006036:	100017b7          	lui	a5,0x10001
    8000603a:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    8000603e:	00492703          	lw	a4,4(s2)
    80006042:	4785                	li	a5,1
    80006044:	02f71163          	bne	a4,a5,80006066 <virtio_disk_rw+0x220>
    sleep(b, &disk.vdisk_lock);
    80006048:	0003a997          	auipc	s3,0x3a
    8000604c:	0e098993          	addi	s3,s3,224 # 80040128 <disk+0x10128>
  while(b->disk == 1) {
    80006050:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006052:	85ce                	mv	a1,s3
    80006054:	854a                	mv	a0,s2
    80006056:	ffffc097          	auipc	ra,0xffffc
    8000605a:	0a2080e7          	jalr	162(ra) # 800020f8 <sleep>
  while(b->disk == 1) {
    8000605e:	00492783          	lw	a5,4(s2)
    80006062:	fe9788e3          	beq	a5,s1,80006052 <virtio_disk_rw+0x20c>
  }

  disk.info[idx[0]].b = 0;
    80006066:	f9042903          	lw	s2,-112(s0)
    8000606a:	6785                	lui	a5,0x1
    8000606c:	97ca                	add	a5,a5,s2
    8000606e:	0792                	slli	a5,a5,0x4
    80006070:	0002a717          	auipc	a4,0x2a
    80006074:	f9070713          	addi	a4,a4,-112 # 80030000 <disk>
    80006078:	97ba                	add	a5,a5,a4
    8000607a:	0207b423          	sd	zero,40(a5) # 1028 <_entry-0x7fffefd8>
    int flag = disk.desc[i].flags;
    8000607e:	0003a997          	auipc	s3,0x3a
    80006082:	f8298993          	addi	s3,s3,-126 # 80040000 <disk+0x10000>
    80006086:	00491713          	slli	a4,s2,0x4
    8000608a:	0009b783          	ld	a5,0(s3)
    8000608e:	97ba                	add	a5,a5,a4
    80006090:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006094:	854a                	mv	a0,s2
    80006096:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    8000609a:	00000097          	auipc	ra,0x0
    8000609e:	bcc080e7          	jalr	-1076(ra) # 80005c66 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    800060a2:	8885                	andi	s1,s1,1
    800060a4:	f0ed                	bnez	s1,80006086 <virtio_disk_rw+0x240>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800060a6:	0003a517          	auipc	a0,0x3a
    800060aa:	08250513          	addi	a0,a0,130 # 80040128 <disk+0x10128>
    800060ae:	ffffb097          	auipc	ra,0xffffb
    800060b2:	bea080e7          	jalr	-1046(ra) # 80000c98 <release>
}
    800060b6:	70a6                	ld	ra,104(sp)
    800060b8:	7406                	ld	s0,96(sp)
    800060ba:	64e6                	ld	s1,88(sp)
    800060bc:	6946                	ld	s2,80(sp)
    800060be:	69a6                	ld	s3,72(sp)
    800060c0:	6a06                	ld	s4,64(sp)
    800060c2:	7ae2                	ld	s5,56(sp)
    800060c4:	7b42                	ld	s6,48(sp)
    800060c6:	7ba2                	ld	s7,40(sp)
    800060c8:	7c02                	ld	s8,32(sp)
    800060ca:	6ce2                	ld	s9,24(sp)
    800060cc:	6d42                	ld	s10,16(sp)
    800060ce:	6165                	addi	sp,sp,112
    800060d0:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    800060d2:	0003a717          	auipc	a4,0x3a
    800060d6:	f2e73703          	ld	a4,-210(a4) # 80040000 <disk+0x10000>
    800060da:	9736                	add	a4,a4,a3
    800060dc:	4609                	li	a2,2
    800060de:	00c71623          	sh	a2,12(a4)
    800060e2:	b5d9                	j	80005fa8 <virtio_disk_rw+0x162>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800060e4:	f9042583          	lw	a1,-112(s0)
    800060e8:	6785                	lui	a5,0x1
    800060ea:	97ae                	add	a5,a5,a1
    800060ec:	0792                	slli	a5,a5,0x4
    800060ee:	0002a517          	auipc	a0,0x2a
    800060f2:	fba50513          	addi	a0,a0,-70 # 800300a8 <disk+0xa8>
    800060f6:	953e                	add	a0,a0,a5
  if(write)
    800060f8:	e20d15e3          	bnez	s10,80005f22 <virtio_disk_rw+0xdc>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    800060fc:	6705                	lui	a4,0x1
    800060fe:	972e                	add	a4,a4,a1
    80006100:	0712                	slli	a4,a4,0x4
    80006102:	0002a697          	auipc	a3,0x2a
    80006106:	efe68693          	addi	a3,a3,-258 # 80030000 <disk>
    8000610a:	9736                	add	a4,a4,a3
    8000610c:	0a072423          	sw	zero,168(a4) # 10a8 <_entry-0x7fffef58>
    80006110:	b525                	j	80005f38 <virtio_disk_rw+0xf2>

0000000080006112 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006112:	7179                	addi	sp,sp,-48
    80006114:	f406                	sd	ra,40(sp)
    80006116:	f022                	sd	s0,32(sp)
    80006118:	ec26                	sd	s1,24(sp)
    8000611a:	e84a                	sd	s2,16(sp)
    8000611c:	e44e                	sd	s3,8(sp)
    8000611e:	1800                	addi	s0,sp,48
  acquire(&disk.vdisk_lock);
    80006120:	0003a517          	auipc	a0,0x3a
    80006124:	00850513          	addi	a0,a0,8 # 80040128 <disk+0x10128>
    80006128:	ffffb097          	auipc	ra,0xffffb
    8000612c:	abc080e7          	jalr	-1348(ra) # 80000be4 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006130:	10001737          	lui	a4,0x10001
    80006134:	533c                	lw	a5,96(a4)
    80006136:	8b8d                	andi	a5,a5,3
    80006138:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    8000613a:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    8000613e:	0003a797          	auipc	a5,0x3a
    80006142:	ec278793          	addi	a5,a5,-318 # 80040000 <disk+0x10000>
    80006146:	6b94                	ld	a3,16(a5)
    80006148:	0207d703          	lhu	a4,32(a5)
    8000614c:	0026d783          	lhu	a5,2(a3)
    80006150:	06f70163          	beq	a4,a5,800061b2 <virtio_disk_intr+0xa0>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006154:	0002a997          	auipc	s3,0x2a
    80006158:	eac98993          	addi	s3,s3,-340 # 80030000 <disk>
    8000615c:	0003a497          	auipc	s1,0x3a
    80006160:	ea448493          	addi	s1,s1,-348 # 80040000 <disk+0x10000>

    if(disk.info[id].status != 0)
    80006164:	6905                	lui	s2,0x1
    __sync_synchronize();
    80006166:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    8000616a:	6898                	ld	a4,16(s1)
    8000616c:	0204d783          	lhu	a5,32(s1)
    80006170:	8b9d                	andi	a5,a5,7
    80006172:	078e                	slli	a5,a5,0x3
    80006174:	97ba                	add	a5,a5,a4
    80006176:	43dc                	lw	a5,4(a5)
    if(disk.info[id].status != 0)
    80006178:	01278733          	add	a4,a5,s2
    8000617c:	0712                	slli	a4,a4,0x4
    8000617e:	974e                	add	a4,a4,s3
    80006180:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    80006184:	e731                	bnez	a4,800061d0 <virtio_disk_intr+0xbe>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006186:	97ca                	add	a5,a5,s2
    80006188:	0792                	slli	a5,a5,0x4
    8000618a:	97ce                	add	a5,a5,s3
    8000618c:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    8000618e:	00052223          	sw	zero,4(a0)
    wakeup(b);
    80006192:	ffffc097          	auipc	ra,0xffffc
    80006196:	0f2080e7          	jalr	242(ra) # 80002284 <wakeup>

    disk.used_idx += 1;
    8000619a:	0204d783          	lhu	a5,32(s1)
    8000619e:	2785                	addiw	a5,a5,1
    800061a0:	17c2                	slli	a5,a5,0x30
    800061a2:	93c1                	srli	a5,a5,0x30
    800061a4:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    800061a8:	6898                	ld	a4,16(s1)
    800061aa:	00275703          	lhu	a4,2(a4)
    800061ae:	faf71ce3          	bne	a4,a5,80006166 <virtio_disk_intr+0x54>
  }

  release(&disk.vdisk_lock);
    800061b2:	0003a517          	auipc	a0,0x3a
    800061b6:	f7650513          	addi	a0,a0,-138 # 80040128 <disk+0x10128>
    800061ba:	ffffb097          	auipc	ra,0xffffb
    800061be:	ade080e7          	jalr	-1314(ra) # 80000c98 <release>
}
    800061c2:	70a2                	ld	ra,40(sp)
    800061c4:	7402                	ld	s0,32(sp)
    800061c6:	64e2                	ld	s1,24(sp)
    800061c8:	6942                	ld	s2,16(sp)
    800061ca:	69a2                	ld	s3,8(sp)
    800061cc:	6145                	addi	sp,sp,48
    800061ce:	8082                	ret
      panic("virtio_disk_intr status");
    800061d0:	00002517          	auipc	a0,0x2
    800061d4:	63050513          	addi	a0,a0,1584 # 80008800 <syscalls+0x3b0>
    800061d8:	ffffa097          	auipc	ra,0xffffa
    800061dc:	366080e7          	jalr	870(ra) # 8000053e <panic>
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
