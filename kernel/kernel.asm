
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
    80000130:	3b4080e7          	jalr	948(ra) # 800024e0 <either_copyin>
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
    800001c8:	866080e7          	jalr	-1946(ra) # 80001a2a <myproc>
    800001cc:	551c                	lw	a5,40(a0)
    800001ce:	e7b5                	bnez	a5,8000023a <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    800001d0:	85ce                	mv	a1,s3
    800001d2:	854a                	mv	a0,s2
    800001d4:	00002097          	auipc	ra,0x2
    800001d8:	f12080e7          	jalr	-238(ra) # 800020e6 <sleep>
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
    80000214:	27a080e7          	jalr	634(ra) # 8000248a <either_copyout>
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
    800002f6:	244080e7          	jalr	580(ra) # 80002536 <procdump>
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
    8000044a:	e2c080e7          	jalr	-468(ra) # 80002272 <wakeup>
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
    800008a4:	9d2080e7          	jalr	-1582(ra) # 80002272 <wakeup>
    
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
    80000930:	7ba080e7          	jalr	1978(ra) # 800020e6 <sleep>
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
    80000b82:	e90080e7          	jalr	-368(ra) # 80001a0e <mycpu>
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
    80000bb4:	e5e080e7          	jalr	-418(ra) # 80001a0e <mycpu>
    80000bb8:	5d3c                	lw	a5,120(a0)
    80000bba:	cf89                	beqz	a5,80000bd4 <push_off+0x3c>
		mycpu()->intena = old;
	mycpu()->noff += 1;
    80000bbc:	00001097          	auipc	ra,0x1
    80000bc0:	e52080e7          	jalr	-430(ra) # 80001a0e <mycpu>
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
    80000bd8:	e3a080e7          	jalr	-454(ra) # 80001a0e <mycpu>
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
    80000c18:	dfa080e7          	jalr	-518(ra) # 80001a0e <mycpu>
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
    80000c44:	dce080e7          	jalr	-562(ra) # 80001a0e <mycpu>
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
    80000e9a:	b68080e7          	jalr	-1176(ra) # 800019fe <cpuid>
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
    80000eb6:	b4c080e7          	jalr	-1204(ra) # 800019fe <cpuid>
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
    80000ed8:	7a2080e7          	jalr	1954(ra) # 80002676 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000edc:	00005097          	auipc	ra,0x5
    80000ee0:	cf4080e7          	jalr	-780(ra) # 80005bd0 <plicinithart>
	}

	scheduler();
    80000ee4:	00001097          	auipc	ra,0x1
    80000ee8:	050080e7          	jalr	80(ra) # 80001f34 <scheduler>
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
    80000f38:	320080e7          	jalr	800(ra) # 80001254 <kvminit>
		kvminithart();   // turn on paging
    80000f3c:	00000097          	auipc	ra,0x0
    80000f40:	068080e7          	jalr	104(ra) # 80000fa4 <kvminithart>
		procinit();      // process table
    80000f44:	00001097          	auipc	ra,0x1
    80000f48:	a0a080e7          	jalr	-1526(ra) # 8000194e <procinit>
		trapinit();      // trap vectors
    80000f4c:	00001097          	auipc	ra,0x1
    80000f50:	702080e7          	jalr	1794(ra) # 8000264e <trapinit>
		trapinithart();  // install kernel trap vector
    80000f54:	00001097          	auipc	ra,0x1
    80000f58:	722080e7          	jalr	1826(ra) # 80002676 <trapinithart>
	plicinit();      // set up interrupt controller
    80000f5c:	00005097          	auipc	ra,0x5
    80000f60:	c5e080e7          	jalr	-930(ra) # 80005bba <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f64:	00005097          	auipc	ra,0x5
    80000f68:	c6c080e7          	jalr	-916(ra) # 80005bd0 <plicinithart>
		binit();         // buffer cache
    80000f6c:	00002097          	auipc	ra,0x2
    80000f70:	e4c080e7          	jalr	-436(ra) # 80002db8 <binit>
		iinit();         // inode table
    80000f74:	00002097          	auipc	ra,0x2
    80000f78:	4dc080e7          	jalr	1244(ra) # 80003450 <iinit>
		fileinit();      // file table
    80000f7c:	00003097          	auipc	ra,0x3
    80000f80:	486080e7          	jalr	1158(ra) # 80004402 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f84:	00005097          	auipc	ra,0x5
    80000f88:	d6e080e7          	jalr	-658(ra) # 80005cf2 <virtio_disk_init>
		userinit();      // first user process
    80000f8c:	00001097          	auipc	ra,0x1
    80000f90:	d76080e7          	jalr	-650(ra) # 80001d02 <userinit>
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
    800010e2:	a015                	j	80001106 <mappages+0x58>
		panic("mappages: size");
    800010e4:	00007517          	auipc	a0,0x7
    800010e8:	ff450513          	addi	a0,a0,-12 # 800080d8 <digits+0x98>
    800010ec:	fffff097          	auipc	ra,0xfffff
    800010f0:	452080e7          	jalr	1106(ra) # 8000053e <panic>
			panic("mappages: remap");
    800010f4:	00007517          	auipc	a0,0x7
    800010f8:	ff450513          	addi	a0,a0,-12 # 800080e8 <digits+0xa8>
    800010fc:	fffff097          	auipc	ra,0xfffff
    80001100:	442080e7          	jalr	1090(ra) # 8000053e <panic>
		a += PGSIZE;
    80001104:	995e                	add	s2,s2,s7
	for(;;){
    80001106:	012a04b3          	add	s1,s4,s2
		if((pte = walk(pagetable, a, 1)) == 0)
    8000110a:	4605                	li	a2,1
    8000110c:	85ca                	mv	a1,s2
    8000110e:	8556                	mv	a0,s5
    80001110:	00000097          	auipc	ra,0x0
    80001114:	eb8080e7          	jalr	-328(ra) # 80000fc8 <walk>
    80001118:	cd19                	beqz	a0,80001136 <mappages+0x88>
		if(*pte & PTE_V){
    8000111a:	611c                	ld	a5,0(a0)
    8000111c:	8b85                	andi	a5,a5,1
    8000111e:	fbf9                	bnez	a5,800010f4 <mappages+0x46>
		*pte = PA2PTE(pa) | perm | PTE_V;
    80001120:	80bd                	srli	s1,s1,0xf
    80001122:	04aa                	slli	s1,s1,0xa
    80001124:	0164e4b3          	or	s1,s1,s6
    80001128:	0014e493          	ori	s1,s1,1
    8000112c:	e104                	sd	s1,0(a0)
		if(a == last)
    8000112e:	fd391be3          	bne	s2,s3,80001104 <mappages+0x56>
		pa += PGSIZE;
	}
	return 0;
    80001132:	4501                	li	a0,0
    80001134:	a011                	j	80001138 <mappages+0x8a>
			return -1;
    80001136:	557d                	li	a0,-1
}
    80001138:	60a6                	ld	ra,72(sp)
    8000113a:	6406                	ld	s0,64(sp)
    8000113c:	74e2                	ld	s1,56(sp)
    8000113e:	7942                	ld	s2,48(sp)
    80001140:	79a2                	ld	s3,40(sp)
    80001142:	7a02                	ld	s4,32(sp)
    80001144:	6ae2                	ld	s5,24(sp)
    80001146:	6b42                	ld	s6,16(sp)
    80001148:	6ba2                	ld	s7,8(sp)
    8000114a:	6161                	addi	sp,sp,80
    8000114c:	8082                	ret

000000008000114e <kvmmap>:
{
    8000114e:	1141                	addi	sp,sp,-16
    80001150:	e406                	sd	ra,8(sp)
    80001152:	e022                	sd	s0,0(sp)
    80001154:	0800                	addi	s0,sp,16
    80001156:	87b6                	mv	a5,a3
	if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    80001158:	86b2                	mv	a3,a2
    8000115a:	863e                	mv	a2,a5
    8000115c:	00000097          	auipc	ra,0x0
    80001160:	f52080e7          	jalr	-174(ra) # 800010ae <mappages>
    80001164:	e509                	bnez	a0,8000116e <kvmmap+0x20>
}
    80001166:	60a2                	ld	ra,8(sp)
    80001168:	6402                	ld	s0,0(sp)
    8000116a:	0141                	addi	sp,sp,16
    8000116c:	8082                	ret
		panic("kvmmap");
    8000116e:	00007517          	auipc	a0,0x7
    80001172:	f8a50513          	addi	a0,a0,-118 # 800080f8 <digits+0xb8>
    80001176:	fffff097          	auipc	ra,0xfffff
    8000117a:	3c8080e7          	jalr	968(ra) # 8000053e <panic>

000000008000117e <kvmmake>:
{
    8000117e:	1101                	addi	sp,sp,-32
    80001180:	ec06                	sd	ra,24(sp)
    80001182:	e822                	sd	s0,16(sp)
    80001184:	e426                	sd	s1,8(sp)
    80001186:	e04a                	sd	s2,0(sp)
    80001188:	1000                	addi	s0,sp,32
	kpgtbl = (pagetable_t) kalloc();
    8000118a:	00000097          	auipc	ra,0x0
    8000118e:	96a080e7          	jalr	-1686(ra) # 80000af4 <kalloc>
    80001192:	84aa                	mv	s1,a0
	memset(kpgtbl, 0, PGSIZE);
    80001194:	6621                	lui	a2,0x8
    80001196:	4581                	li	a1,0
    80001198:	00000097          	auipc	ra,0x0
    8000119c:	b48080e7          	jalr	-1208(ra) # 80000ce0 <memset>
	kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    800011a0:	4719                	li	a4,6
    800011a2:	66a1                	lui	a3,0x8
    800011a4:	10000637          	lui	a2,0x10000
    800011a8:	100005b7          	lui	a1,0x10000
    800011ac:	8526                	mv	a0,s1
    800011ae:	00000097          	auipc	ra,0x0
    800011b2:	fa0080e7          	jalr	-96(ra) # 8000114e <kvmmap>
	kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800011b6:	4719                	li	a4,6
    800011b8:	66a1                	lui	a3,0x8
    800011ba:	10001637          	lui	a2,0x10001
    800011be:	100015b7          	lui	a1,0x10001
    800011c2:	8526                	mv	a0,s1
    800011c4:	00000097          	auipc	ra,0x0
    800011c8:	f8a080e7          	jalr	-118(ra) # 8000114e <kvmmap>
	kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800011cc:	4719                	li	a4,6
    800011ce:	004006b7          	lui	a3,0x400
    800011d2:	0c000637          	lui	a2,0xc000
    800011d6:	0c0005b7          	lui	a1,0xc000
    800011da:	8526                	mv	a0,s1
    800011dc:	00000097          	auipc	ra,0x0
    800011e0:	f72080e7          	jalr	-142(ra) # 8000114e <kvmmap>
	kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800011e4:	00007917          	auipc	s2,0x7
    800011e8:	e1c90913          	addi	s2,s2,-484 # 80008000 <etext>
    800011ec:	4729                	li	a4,10
    800011ee:	80007697          	auipc	a3,0x80007
    800011f2:	e1268693          	addi	a3,a3,-494 # 8000 <_entry-0x7fff8000>
    800011f6:	4605                	li	a2,1
    800011f8:	067e                	slli	a2,a2,0x1f
    800011fa:	85b2                	mv	a1,a2
    800011fc:	8526                	mv	a0,s1
    800011fe:	00000097          	auipc	ra,0x0
    80001202:	f50080e7          	jalr	-176(ra) # 8000114e <kvmmap>
	kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    80001206:	4719                	li	a4,6
    80001208:	46c5                	li	a3,17
    8000120a:	06ee                	slli	a3,a3,0x1b
    8000120c:	412686b3          	sub	a3,a3,s2
    80001210:	864a                	mv	a2,s2
    80001212:	85ca                	mv	a1,s2
    80001214:	8526                	mv	a0,s1
    80001216:	00000097          	auipc	ra,0x0
    8000121a:	f38080e7          	jalr	-200(ra) # 8000114e <kvmmap>
	kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    8000121e:	4729                	li	a4,10
    80001220:	66a1                	lui	a3,0x8
    80001222:	00006617          	auipc	a2,0x6
    80001226:	dde60613          	addi	a2,a2,-546 # 80007000 <_trampoline>
    8000122a:	008005b7          	lui	a1,0x800
    8000122e:	15fd                	addi	a1,a1,-1
    80001230:	05be                	slli	a1,a1,0xf
    80001232:	8526                	mv	a0,s1
    80001234:	00000097          	auipc	ra,0x0
    80001238:	f1a080e7          	jalr	-230(ra) # 8000114e <kvmmap>
	proc_mapstacks(kpgtbl);
    8000123c:	8526                	mv	a0,s1
    8000123e:	00000097          	auipc	ra,0x0
    80001242:	67a080e7          	jalr	1658(ra) # 800018b8 <proc_mapstacks>
}
    80001246:	8526                	mv	a0,s1
    80001248:	60e2                	ld	ra,24(sp)
    8000124a:	6442                	ld	s0,16(sp)
    8000124c:	64a2                	ld	s1,8(sp)
    8000124e:	6902                	ld	s2,0(sp)
    80001250:	6105                	addi	sp,sp,32
    80001252:	8082                	ret

0000000080001254 <kvminit>:
{
    80001254:	1141                	addi	sp,sp,-16
    80001256:	e406                	sd	ra,8(sp)
    80001258:	e022                	sd	s0,0(sp)
    8000125a:	0800                	addi	s0,sp,16
	kernel_pagetable = kvmmake();
    8000125c:	00000097          	auipc	ra,0x0
    80001260:	f22080e7          	jalr	-222(ra) # 8000117e <kvmmake>
    80001264:	0000f797          	auipc	a5,0xf
    80001268:	daa7be23          	sd	a0,-580(a5) # 80010020 <kernel_pagetable>
}
    8000126c:	60a2                	ld	ra,8(sp)
    8000126e:	6402                	ld	s0,0(sp)
    80001270:	0141                	addi	sp,sp,16
    80001272:	8082                	ret

0000000080001274 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001274:	715d                	addi	sp,sp,-80
    80001276:	e486                	sd	ra,72(sp)
    80001278:	e0a2                	sd	s0,64(sp)
    8000127a:	fc26                	sd	s1,56(sp)
    8000127c:	f84a                	sd	s2,48(sp)
    8000127e:	f44e                	sd	s3,40(sp)
    80001280:	f052                	sd	s4,32(sp)
    80001282:	ec56                	sd	s5,24(sp)
    80001284:	e85a                	sd	s6,16(sp)
    80001286:	e45e                	sd	s7,8(sp)
    80001288:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    8000128a:	03159793          	slli	a5,a1,0x31
    8000128e:	e795                	bnez	a5,800012ba <uvmunmap+0x46>
    80001290:	8a2a                	mv	s4,a0
    80001292:	892e                	mv	s2,a1
    80001294:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001296:	063e                	slli	a2,a2,0xf
    80001298:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    8000129c:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000129e:	6b21                	lui	s6,0x8
    800012a0:	0735e863          	bltu	a1,s3,80001310 <uvmunmap+0x9c>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    800012a4:	60a6                	ld	ra,72(sp)
    800012a6:	6406                	ld	s0,64(sp)
    800012a8:	74e2                	ld	s1,56(sp)
    800012aa:	7942                	ld	s2,48(sp)
    800012ac:	79a2                	ld	s3,40(sp)
    800012ae:	7a02                	ld	s4,32(sp)
    800012b0:	6ae2                	ld	s5,24(sp)
    800012b2:	6b42                	ld	s6,16(sp)
    800012b4:	6ba2                	ld	s7,8(sp)
    800012b6:	6161                	addi	sp,sp,80
    800012b8:	8082                	ret
    panic("uvmunmap: not aligned");
    800012ba:	00007517          	auipc	a0,0x7
    800012be:	e4650513          	addi	a0,a0,-442 # 80008100 <digits+0xc0>
    800012c2:	fffff097          	auipc	ra,0xfffff
    800012c6:	27c080e7          	jalr	636(ra) # 8000053e <panic>
      panic("uvmunmap: walk");
    800012ca:	00007517          	auipc	a0,0x7
    800012ce:	e4e50513          	addi	a0,a0,-434 # 80008118 <digits+0xd8>
    800012d2:	fffff097          	auipc	ra,0xfffff
    800012d6:	26c080e7          	jalr	620(ra) # 8000053e <panic>
      panic("uvmunmap: not mapped");
    800012da:	00007517          	auipc	a0,0x7
    800012de:	e4e50513          	addi	a0,a0,-434 # 80008128 <digits+0xe8>
    800012e2:	fffff097          	auipc	ra,0xfffff
    800012e6:	25c080e7          	jalr	604(ra) # 8000053e <panic>
      panic("uvmunmap: not a leaf");
    800012ea:	00007517          	auipc	a0,0x7
    800012ee:	e5650513          	addi	a0,a0,-426 # 80008140 <digits+0x100>
    800012f2:	fffff097          	auipc	ra,0xfffff
    800012f6:	24c080e7          	jalr	588(ra) # 8000053e <panic>
      uint64 pa = PTE2PA(*pte);
    800012fa:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    800012fc:	053e                	slli	a0,a0,0xf
    800012fe:	fffff097          	auipc	ra,0xfffff
    80001302:	6fa080e7          	jalr	1786(ra) # 800009f8 <kfree>
    *pte = 0;
    80001306:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000130a:	995a                	add	s2,s2,s6
    8000130c:	f9397ce3          	bgeu	s2,s3,800012a4 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    80001310:	4601                	li	a2,0
    80001312:	85ca                	mv	a1,s2
    80001314:	8552                	mv	a0,s4
    80001316:	00000097          	auipc	ra,0x0
    8000131a:	cb2080e7          	jalr	-846(ra) # 80000fc8 <walk>
    8000131e:	84aa                	mv	s1,a0
    80001320:	d54d                	beqz	a0,800012ca <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    80001322:	6108                	ld	a0,0(a0)
    80001324:	00157793          	andi	a5,a0,1
    80001328:	dbcd                	beqz	a5,800012da <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    8000132a:	3ff57793          	andi	a5,a0,1023
    8000132e:	fb778ee3          	beq	a5,s7,800012ea <uvmunmap+0x76>
    if(do_free){
    80001332:	fc0a8ae3          	beqz	s5,80001306 <uvmunmap+0x92>
    80001336:	b7d1                	j	800012fa <uvmunmap+0x86>

0000000080001338 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    80001338:	1101                	addi	sp,sp,-32
    8000133a:	ec06                	sd	ra,24(sp)
    8000133c:	e822                	sd	s0,16(sp)
    8000133e:	e426                	sd	s1,8(sp)
    80001340:	1000                	addi	s0,sp,32
	pagetable_t pagetable;
	pagetable = (pagetable_t) kalloc();
    80001342:	fffff097          	auipc	ra,0xfffff
    80001346:	7b2080e7          	jalr	1970(ra) # 80000af4 <kalloc>
    8000134a:	84aa                	mv	s1,a0
	if(pagetable == 0)
    8000134c:	c519                	beqz	a0,8000135a <uvmcreate+0x22>
		return 0;
	memset(pagetable, 0, PGSIZE);
    8000134e:	6621                	lui	a2,0x8
    80001350:	4581                	li	a1,0
    80001352:	00000097          	auipc	ra,0x0
    80001356:	98e080e7          	jalr	-1650(ra) # 80000ce0 <memset>
	return pagetable;
}
    8000135a:	8526                	mv	a0,s1
    8000135c:	60e2                	ld	ra,24(sp)
    8000135e:	6442                	ld	s0,16(sp)
    80001360:	64a2                	ld	s1,8(sp)
    80001362:	6105                	addi	sp,sp,32
    80001364:	8082                	ret

0000000080001366 <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    80001366:	7179                	addi	sp,sp,-48
    80001368:	f406                	sd	ra,40(sp)
    8000136a:	f022                	sd	s0,32(sp)
    8000136c:	ec26                	sd	s1,24(sp)
    8000136e:	e84a                	sd	s2,16(sp)
    80001370:	e44e                	sd	s3,8(sp)
    80001372:	e052                	sd	s4,0(sp)
    80001374:	1800                	addi	s0,sp,48
	char *mem;

	if(sz >= PGSIZE)
    80001376:	67a1                	lui	a5,0x8
    80001378:	04f67863          	bgeu	a2,a5,800013c8 <uvminit+0x62>
    8000137c:	8a2a                	mv	s4,a0
    8000137e:	89ae                	mv	s3,a1
    80001380:	84b2                	mv	s1,a2
		panic("inituvm: more than a page");
	mem = kalloc();
    80001382:	fffff097          	auipc	ra,0xfffff
    80001386:	772080e7          	jalr	1906(ra) # 80000af4 <kalloc>
    8000138a:	892a                	mv	s2,a0
	memset(mem, 0, PGSIZE);
    8000138c:	6621                	lui	a2,0x8
    8000138e:	4581                	li	a1,0
    80001390:	00000097          	auipc	ra,0x0
    80001394:	950080e7          	jalr	-1712(ra) # 80000ce0 <memset>
	mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    80001398:	4779                	li	a4,30
    8000139a:	86ca                	mv	a3,s2
    8000139c:	6621                	lui	a2,0x8
    8000139e:	4581                	li	a1,0
    800013a0:	8552                	mv	a0,s4
    800013a2:	00000097          	auipc	ra,0x0
    800013a6:	d0c080e7          	jalr	-756(ra) # 800010ae <mappages>
	memmove(mem, src, sz);
    800013aa:	8626                	mv	a2,s1
    800013ac:	85ce                	mv	a1,s3
    800013ae:	854a                	mv	a0,s2
    800013b0:	00000097          	auipc	ra,0x0
    800013b4:	990080e7          	jalr	-1648(ra) # 80000d40 <memmove>
}
    800013b8:	70a2                	ld	ra,40(sp)
    800013ba:	7402                	ld	s0,32(sp)
    800013bc:	64e2                	ld	s1,24(sp)
    800013be:	6942                	ld	s2,16(sp)
    800013c0:	69a2                	ld	s3,8(sp)
    800013c2:	6a02                	ld	s4,0(sp)
    800013c4:	6145                	addi	sp,sp,48
    800013c6:	8082                	ret
		panic("inituvm: more than a page");
    800013c8:	00007517          	auipc	a0,0x7
    800013cc:	d9050513          	addi	a0,a0,-624 # 80008158 <digits+0x118>
    800013d0:	fffff097          	auipc	ra,0xfffff
    800013d4:	16e080e7          	jalr	366(ra) # 8000053e <panic>

00000000800013d8 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800013d8:	1101                	addi	sp,sp,-32
    800013da:	ec06                	sd	ra,24(sp)
    800013dc:	e822                	sd	s0,16(sp)
    800013de:	e426                	sd	s1,8(sp)
    800013e0:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800013e2:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800013e4:	00b67d63          	bgeu	a2,a1,800013fe <uvmdealloc+0x26>
    800013e8:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800013ea:	67a1                	lui	a5,0x8
    800013ec:	17fd                	addi	a5,a5,-1
    800013ee:	00f60733          	add	a4,a2,a5
    800013f2:	7661                	lui	a2,0xffff8
    800013f4:	8f71                	and	a4,a4,a2
    800013f6:	97ae                	add	a5,a5,a1
    800013f8:	8ff1                	and	a5,a5,a2
    800013fa:	00f76863          	bltu	a4,a5,8000140a <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    800013fe:	8526                	mv	a0,s1
    80001400:	60e2                	ld	ra,24(sp)
    80001402:	6442                	ld	s0,16(sp)
    80001404:	64a2                	ld	s1,8(sp)
    80001406:	6105                	addi	sp,sp,32
    80001408:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    8000140a:	8f99                	sub	a5,a5,a4
    8000140c:	83bd                	srli	a5,a5,0xf
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    8000140e:	4685                	li	a3,1
    80001410:	0007861b          	sext.w	a2,a5
    80001414:	85ba                	mv	a1,a4
    80001416:	00000097          	auipc	ra,0x0
    8000141a:	e5e080e7          	jalr	-418(ra) # 80001274 <uvmunmap>
    8000141e:	b7c5                	j	800013fe <uvmdealloc+0x26>

0000000080001420 <uvmalloc>:
	if(newsz < oldsz)
    80001420:	0ab66163          	bltu	a2,a1,800014c2 <uvmalloc+0xa2>
{
    80001424:	7139                	addi	sp,sp,-64
    80001426:	fc06                	sd	ra,56(sp)
    80001428:	f822                	sd	s0,48(sp)
    8000142a:	f426                	sd	s1,40(sp)
    8000142c:	f04a                	sd	s2,32(sp)
    8000142e:	ec4e                	sd	s3,24(sp)
    80001430:	e852                	sd	s4,16(sp)
    80001432:	e456                	sd	s5,8(sp)
    80001434:	0080                	addi	s0,sp,64
    80001436:	8aaa                	mv	s5,a0
    80001438:	8a32                	mv	s4,a2
	oldsz = PGROUNDUP(oldsz);
    8000143a:	69a1                	lui	s3,0x8
    8000143c:	19fd                	addi	s3,s3,-1
    8000143e:	95ce                	add	a1,a1,s3
    80001440:	79e1                	lui	s3,0xffff8
    80001442:	0135f9b3          	and	s3,a1,s3
	for(a = oldsz; a < newsz; a += PGSIZE){
    80001446:	08c9f063          	bgeu	s3,a2,800014c6 <uvmalloc+0xa6>
    8000144a:	894e                	mv	s2,s3
		mem = kalloc();
    8000144c:	fffff097          	auipc	ra,0xfffff
    80001450:	6a8080e7          	jalr	1704(ra) # 80000af4 <kalloc>
    80001454:	84aa                	mv	s1,a0
		if(mem == 0){
    80001456:	c51d                	beqz	a0,80001484 <uvmalloc+0x64>
		memset(mem, 0, PGSIZE);
    80001458:	6621                	lui	a2,0x8
    8000145a:	4581                	li	a1,0
    8000145c:	00000097          	auipc	ra,0x0
    80001460:	884080e7          	jalr	-1916(ra) # 80000ce0 <memset>
		if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    80001464:	4779                	li	a4,30
    80001466:	86a6                	mv	a3,s1
    80001468:	6621                	lui	a2,0x8
    8000146a:	85ca                	mv	a1,s2
    8000146c:	8556                	mv	a0,s5
    8000146e:	00000097          	auipc	ra,0x0
    80001472:	c40080e7          	jalr	-960(ra) # 800010ae <mappages>
    80001476:	e905                	bnez	a0,800014a6 <uvmalloc+0x86>
	for(a = oldsz; a < newsz; a += PGSIZE){
    80001478:	67a1                	lui	a5,0x8
    8000147a:	993e                	add	s2,s2,a5
    8000147c:	fd4968e3          	bltu	s2,s4,8000144c <uvmalloc+0x2c>
	return newsz;
    80001480:	8552                	mv	a0,s4
    80001482:	a809                	j	80001494 <uvmalloc+0x74>
			uvmdealloc(pagetable, a, oldsz);
    80001484:	864e                	mv	a2,s3
    80001486:	85ca                	mv	a1,s2
    80001488:	8556                	mv	a0,s5
    8000148a:	00000097          	auipc	ra,0x0
    8000148e:	f4e080e7          	jalr	-178(ra) # 800013d8 <uvmdealloc>
			return 0;
    80001492:	4501                	li	a0,0
}
    80001494:	70e2                	ld	ra,56(sp)
    80001496:	7442                	ld	s0,48(sp)
    80001498:	74a2                	ld	s1,40(sp)
    8000149a:	7902                	ld	s2,32(sp)
    8000149c:	69e2                	ld	s3,24(sp)
    8000149e:	6a42                	ld	s4,16(sp)
    800014a0:	6aa2                	ld	s5,8(sp)
    800014a2:	6121                	addi	sp,sp,64
    800014a4:	8082                	ret
			kfree(mem);
    800014a6:	8526                	mv	a0,s1
    800014a8:	fffff097          	auipc	ra,0xfffff
    800014ac:	550080e7          	jalr	1360(ra) # 800009f8 <kfree>
			uvmdealloc(pagetable, a, oldsz);
    800014b0:	864e                	mv	a2,s3
    800014b2:	85ca                	mv	a1,s2
    800014b4:	8556                	mv	a0,s5
    800014b6:	00000097          	auipc	ra,0x0
    800014ba:	f22080e7          	jalr	-222(ra) # 800013d8 <uvmdealloc>
			return 0;
    800014be:	4501                	li	a0,0
    800014c0:	bfd1                	j	80001494 <uvmalloc+0x74>
		return oldsz;
    800014c2:	852e                	mv	a0,a1
}
    800014c4:	8082                	ret
	return newsz;
    800014c6:	8532                	mv	a0,a2
    800014c8:	b7f1                	j	80001494 <uvmalloc+0x74>

00000000800014ca <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800014ca:	7179                	addi	sp,sp,-48
    800014cc:	f406                	sd	ra,40(sp)
    800014ce:	f022                	sd	s0,32(sp)
    800014d0:	ec26                	sd	s1,24(sp)
    800014d2:	e84a                	sd	s2,16(sp)
    800014d4:	e44e                	sd	s3,8(sp)
    800014d6:	e052                	sd	s4,0(sp)
    800014d8:	1800                	addi	s0,sp,48
    800014da:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800014dc:	84aa                	mv	s1,a0
    800014de:	6905                	lui	s2,0x1
    800014e0:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014e2:	4985                	li	s3,1
    800014e4:	a821                	j	800014fc <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800014e6:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    800014e8:	053e                	slli	a0,a0,0xf
    800014ea:	00000097          	auipc	ra,0x0
    800014ee:	fe0080e7          	jalr	-32(ra) # 800014ca <freewalk>
      pagetable[i] = 0;
    800014f2:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800014f6:	04a1                	addi	s1,s1,8
    800014f8:	03248163          	beq	s1,s2,8000151a <freewalk+0x50>
    pte_t pte = pagetable[i];
    800014fc:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014fe:	00f57793          	andi	a5,a0,15
    80001502:	ff3782e3          	beq	a5,s3,800014e6 <freewalk+0x1c>
    } else if(pte & PTE_V){
    80001506:	8905                	andi	a0,a0,1
    80001508:	d57d                	beqz	a0,800014f6 <freewalk+0x2c>
      panic("freewalk: leaf");
    8000150a:	00007517          	auipc	a0,0x7
    8000150e:	c6e50513          	addi	a0,a0,-914 # 80008178 <digits+0x138>
    80001512:	fffff097          	auipc	ra,0xfffff
    80001516:	02c080e7          	jalr	44(ra) # 8000053e <panic>
    }
  }
  kfree((void*)pagetable);
    8000151a:	8552                	mv	a0,s4
    8000151c:	fffff097          	auipc	ra,0xfffff
    80001520:	4dc080e7          	jalr	1244(ra) # 800009f8 <kfree>
}
    80001524:	70a2                	ld	ra,40(sp)
    80001526:	7402                	ld	s0,32(sp)
    80001528:	64e2                	ld	s1,24(sp)
    8000152a:	6942                	ld	s2,16(sp)
    8000152c:	69a2                	ld	s3,8(sp)
    8000152e:	6a02                	ld	s4,0(sp)
    80001530:	6145                	addi	sp,sp,48
    80001532:	8082                	ret

0000000080001534 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    80001534:	1101                	addi	sp,sp,-32
    80001536:	ec06                	sd	ra,24(sp)
    80001538:	e822                	sd	s0,16(sp)
    8000153a:	e426                	sd	s1,8(sp)
    8000153c:	1000                	addi	s0,sp,32
    8000153e:	84aa                	mv	s1,a0
	if(sz > 0)
    80001540:	e999                	bnez	a1,80001556 <uvmfree+0x22>
		uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
	freewalk(pagetable);
    80001542:	8526                	mv	a0,s1
    80001544:	00000097          	auipc	ra,0x0
    80001548:	f86080e7          	jalr	-122(ra) # 800014ca <freewalk>
}
    8000154c:	60e2                	ld	ra,24(sp)
    8000154e:	6442                	ld	s0,16(sp)
    80001550:	64a2                	ld	s1,8(sp)
    80001552:	6105                	addi	sp,sp,32
    80001554:	8082                	ret
		uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001556:	6621                	lui	a2,0x8
    80001558:	167d                	addi	a2,a2,-1
    8000155a:	962e                	add	a2,a2,a1
    8000155c:	4685                	li	a3,1
    8000155e:	823d                	srli	a2,a2,0xf
    80001560:	4581                	li	a1,0
    80001562:	00000097          	auipc	ra,0x0
    80001566:	d12080e7          	jalr	-750(ra) # 80001274 <uvmunmap>
    8000156a:	bfe1                	j	80001542 <uvmfree+0xe>

000000008000156c <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    8000156c:	c679                	beqz	a2,8000163a <uvmcopy+0xce>
{
    8000156e:	715d                	addi	sp,sp,-80
    80001570:	e486                	sd	ra,72(sp)
    80001572:	e0a2                	sd	s0,64(sp)
    80001574:	fc26                	sd	s1,56(sp)
    80001576:	f84a                	sd	s2,48(sp)
    80001578:	f44e                	sd	s3,40(sp)
    8000157a:	f052                	sd	s4,32(sp)
    8000157c:	ec56                	sd	s5,24(sp)
    8000157e:	e85a                	sd	s6,16(sp)
    80001580:	e45e                	sd	s7,8(sp)
    80001582:	0880                	addi	s0,sp,80
    80001584:	8b2a                	mv	s6,a0
    80001586:	8aae                	mv	s5,a1
    80001588:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    8000158a:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    8000158c:	4601                	li	a2,0
    8000158e:	85ce                	mv	a1,s3
    80001590:	855a                	mv	a0,s6
    80001592:	00000097          	auipc	ra,0x0
    80001596:	a36080e7          	jalr	-1482(ra) # 80000fc8 <walk>
    8000159a:	c531                	beqz	a0,800015e6 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    8000159c:	6118                	ld	a4,0(a0)
    8000159e:	00177793          	andi	a5,a4,1
    800015a2:	cbb1                	beqz	a5,800015f6 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    800015a4:	00a75593          	srli	a1,a4,0xa
    800015a8:	00f59b93          	slli	s7,a1,0xf
    flags = PTE_FLAGS(*pte);
    800015ac:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    800015b0:	fffff097          	auipc	ra,0xfffff
    800015b4:	544080e7          	jalr	1348(ra) # 80000af4 <kalloc>
    800015b8:	892a                	mv	s2,a0
    800015ba:	c939                	beqz	a0,80001610 <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800015bc:	6621                	lui	a2,0x8
    800015be:	85de                	mv	a1,s7
    800015c0:	fffff097          	auipc	ra,0xfffff
    800015c4:	780080e7          	jalr	1920(ra) # 80000d40 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800015c8:	8726                	mv	a4,s1
    800015ca:	86ca                	mv	a3,s2
    800015cc:	6621                	lui	a2,0x8
    800015ce:	85ce                	mv	a1,s3
    800015d0:	8556                	mv	a0,s5
    800015d2:	00000097          	auipc	ra,0x0
    800015d6:	adc080e7          	jalr	-1316(ra) # 800010ae <mappages>
    800015da:	e515                	bnez	a0,80001606 <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800015dc:	67a1                	lui	a5,0x8
    800015de:	99be                	add	s3,s3,a5
    800015e0:	fb49e6e3          	bltu	s3,s4,8000158c <uvmcopy+0x20>
    800015e4:	a081                	j	80001624 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800015e6:	00007517          	auipc	a0,0x7
    800015ea:	ba250513          	addi	a0,a0,-1118 # 80008188 <digits+0x148>
    800015ee:	fffff097          	auipc	ra,0xfffff
    800015f2:	f50080e7          	jalr	-176(ra) # 8000053e <panic>
      panic("uvmcopy: page not present");
    800015f6:	00007517          	auipc	a0,0x7
    800015fa:	bb250513          	addi	a0,a0,-1102 # 800081a8 <digits+0x168>
    800015fe:	fffff097          	auipc	ra,0xfffff
    80001602:	f40080e7          	jalr	-192(ra) # 8000053e <panic>
      kfree(mem);
    80001606:	854a                	mv	a0,s2
    80001608:	fffff097          	auipc	ra,0xfffff
    8000160c:	3f0080e7          	jalr	1008(ra) # 800009f8 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001610:	4685                	li	a3,1
    80001612:	00f9d613          	srli	a2,s3,0xf
    80001616:	4581                	li	a1,0
    80001618:	8556                	mv	a0,s5
    8000161a:	00000097          	auipc	ra,0x0
    8000161e:	c5a080e7          	jalr	-934(ra) # 80001274 <uvmunmap>
  return -1;
    80001622:	557d                	li	a0,-1
}
    80001624:	60a6                	ld	ra,72(sp)
    80001626:	6406                	ld	s0,64(sp)
    80001628:	74e2                	ld	s1,56(sp)
    8000162a:	7942                	ld	s2,48(sp)
    8000162c:	79a2                	ld	s3,40(sp)
    8000162e:	7a02                	ld	s4,32(sp)
    80001630:	6ae2                	ld	s5,24(sp)
    80001632:	6b42                	ld	s6,16(sp)
    80001634:	6ba2                	ld	s7,8(sp)
    80001636:	6161                	addi	sp,sp,80
    80001638:	8082                	ret
  return 0;
    8000163a:	4501                	li	a0,0
}
    8000163c:	8082                	ret

000000008000163e <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    8000163e:	1141                	addi	sp,sp,-16
    80001640:	e406                	sd	ra,8(sp)
    80001642:	e022                	sd	s0,0(sp)
    80001644:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001646:	4601                	li	a2,0
    80001648:	00000097          	auipc	ra,0x0
    8000164c:	980080e7          	jalr	-1664(ra) # 80000fc8 <walk>
  if(pte == 0)
    80001650:	c901                	beqz	a0,80001660 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    80001652:	611c                	ld	a5,0(a0)
    80001654:	9bbd                	andi	a5,a5,-17
    80001656:	e11c                	sd	a5,0(a0)
}
    80001658:	60a2                	ld	ra,8(sp)
    8000165a:	6402                	ld	s0,0(sp)
    8000165c:	0141                	addi	sp,sp,16
    8000165e:	8082                	ret
    panic("uvmclear");
    80001660:	00007517          	auipc	a0,0x7
    80001664:	b6850513          	addi	a0,a0,-1176 # 800081c8 <digits+0x188>
    80001668:	fffff097          	auipc	ra,0xfffff
    8000166c:	ed6080e7          	jalr	-298(ra) # 8000053e <panic>

0000000080001670 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001670:	c6bd                	beqz	a3,800016de <copyout+0x6e>
{
    80001672:	715d                	addi	sp,sp,-80
    80001674:	e486                	sd	ra,72(sp)
    80001676:	e0a2                	sd	s0,64(sp)
    80001678:	fc26                	sd	s1,56(sp)
    8000167a:	f84a                	sd	s2,48(sp)
    8000167c:	f44e                	sd	s3,40(sp)
    8000167e:	f052                	sd	s4,32(sp)
    80001680:	ec56                	sd	s5,24(sp)
    80001682:	e85a                	sd	s6,16(sp)
    80001684:	e45e                	sd	s7,8(sp)
    80001686:	e062                	sd	s8,0(sp)
    80001688:	0880                	addi	s0,sp,80
    8000168a:	8b2a                	mv	s6,a0
    8000168c:	8c2e                	mv	s8,a1
    8000168e:	8a32                	mv	s4,a2
    80001690:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    80001692:	7be1                	lui	s7,0xffff8
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    80001694:	6aa1                	lui	s5,0x8
    80001696:	a015                	j	800016ba <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    80001698:	9562                	add	a0,a0,s8
    8000169a:	0004861b          	sext.w	a2,s1
    8000169e:	85d2                	mv	a1,s4
    800016a0:	41250533          	sub	a0,a0,s2
    800016a4:	fffff097          	auipc	ra,0xfffff
    800016a8:	69c080e7          	jalr	1692(ra) # 80000d40 <memmove>

    len -= n;
    800016ac:	409989b3          	sub	s3,s3,s1
    src += n;
    800016b0:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    800016b2:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800016b6:	02098263          	beqz	s3,800016da <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800016ba:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800016be:	85ca                	mv	a1,s2
    800016c0:	855a                	mv	a0,s6
    800016c2:	00000097          	auipc	ra,0x0
    800016c6:	9aa080e7          	jalr	-1622(ra) # 8000106c <walkaddr>
    if(pa0 == 0)
    800016ca:	cd01                	beqz	a0,800016e2 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800016cc:	418904b3          	sub	s1,s2,s8
    800016d0:	94d6                	add	s1,s1,s5
    if(n > len)
    800016d2:	fc99f3e3          	bgeu	s3,s1,80001698 <copyout+0x28>
    800016d6:	84ce                	mv	s1,s3
    800016d8:	b7c1                	j	80001698 <copyout+0x28>
  }
  return 0;
    800016da:	4501                	li	a0,0
    800016dc:	a021                	j	800016e4 <copyout+0x74>
    800016de:	4501                	li	a0,0
}
    800016e0:	8082                	ret
      return -1;
    800016e2:	557d                	li	a0,-1
}
    800016e4:	60a6                	ld	ra,72(sp)
    800016e6:	6406                	ld	s0,64(sp)
    800016e8:	74e2                	ld	s1,56(sp)
    800016ea:	7942                	ld	s2,48(sp)
    800016ec:	79a2                	ld	s3,40(sp)
    800016ee:	7a02                	ld	s4,32(sp)
    800016f0:	6ae2                	ld	s5,24(sp)
    800016f2:	6b42                	ld	s6,16(sp)
    800016f4:	6ba2                	ld	s7,8(sp)
    800016f6:	6c02                	ld	s8,0(sp)
    800016f8:	6161                	addi	sp,sp,80
    800016fa:	8082                	ret

00000000800016fc <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800016fc:	c6bd                	beqz	a3,8000176a <copyin+0x6e>
{
    800016fe:	715d                	addi	sp,sp,-80
    80001700:	e486                	sd	ra,72(sp)
    80001702:	e0a2                	sd	s0,64(sp)
    80001704:	fc26                	sd	s1,56(sp)
    80001706:	f84a                	sd	s2,48(sp)
    80001708:	f44e                	sd	s3,40(sp)
    8000170a:	f052                	sd	s4,32(sp)
    8000170c:	ec56                	sd	s5,24(sp)
    8000170e:	e85a                	sd	s6,16(sp)
    80001710:	e45e                	sd	s7,8(sp)
    80001712:	e062                	sd	s8,0(sp)
    80001714:	0880                	addi	s0,sp,80
    80001716:	8b2a                	mv	s6,a0
    80001718:	8a2e                	mv	s4,a1
    8000171a:	8c32                	mv	s8,a2
    8000171c:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    8000171e:	7be1                	lui	s7,0xffff8
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001720:	6aa1                	lui	s5,0x8
    80001722:	a015                	j	80001746 <copyin+0x4a>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001724:	9562                	add	a0,a0,s8
    80001726:	0004861b          	sext.w	a2,s1
    8000172a:	412505b3          	sub	a1,a0,s2
    8000172e:	8552                	mv	a0,s4
    80001730:	fffff097          	auipc	ra,0xfffff
    80001734:	610080e7          	jalr	1552(ra) # 80000d40 <memmove>

    len -= n;
    80001738:	409989b3          	sub	s3,s3,s1
    dst += n;
    8000173c:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    8000173e:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001742:	02098263          	beqz	s3,80001766 <copyin+0x6a>
    va0 = PGROUNDDOWN(srcva);
    80001746:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    8000174a:	85ca                	mv	a1,s2
    8000174c:	855a                	mv	a0,s6
    8000174e:	00000097          	auipc	ra,0x0
    80001752:	91e080e7          	jalr	-1762(ra) # 8000106c <walkaddr>
    if(pa0 == 0)
    80001756:	cd01                	beqz	a0,8000176e <copyin+0x72>
    n = PGSIZE - (srcva - va0);
    80001758:	418904b3          	sub	s1,s2,s8
    8000175c:	94d6                	add	s1,s1,s5
    if(n > len)
    8000175e:	fc99f3e3          	bgeu	s3,s1,80001724 <copyin+0x28>
    80001762:	84ce                	mv	s1,s3
    80001764:	b7c1                	j	80001724 <copyin+0x28>
  }
  return 0;
    80001766:	4501                	li	a0,0
    80001768:	a021                	j	80001770 <copyin+0x74>
    8000176a:	4501                	li	a0,0
}
    8000176c:	8082                	ret
      return -1;
    8000176e:	557d                	li	a0,-1
}
    80001770:	60a6                	ld	ra,72(sp)
    80001772:	6406                	ld	s0,64(sp)
    80001774:	74e2                	ld	s1,56(sp)
    80001776:	7942                	ld	s2,48(sp)
    80001778:	79a2                	ld	s3,40(sp)
    8000177a:	7a02                	ld	s4,32(sp)
    8000177c:	6ae2                	ld	s5,24(sp)
    8000177e:	6b42                	ld	s6,16(sp)
    80001780:	6ba2                	ld	s7,8(sp)
    80001782:	6c02                	ld	s8,0(sp)
    80001784:	6161                	addi	sp,sp,80
    80001786:	8082                	ret

0000000080001788 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    80001788:	c6c5                	beqz	a3,80001830 <copyinstr+0xa8>
{
    8000178a:	715d                	addi	sp,sp,-80
    8000178c:	e486                	sd	ra,72(sp)
    8000178e:	e0a2                	sd	s0,64(sp)
    80001790:	fc26                	sd	s1,56(sp)
    80001792:	f84a                	sd	s2,48(sp)
    80001794:	f44e                	sd	s3,40(sp)
    80001796:	f052                	sd	s4,32(sp)
    80001798:	ec56                	sd	s5,24(sp)
    8000179a:	e85a                	sd	s6,16(sp)
    8000179c:	e45e                	sd	s7,8(sp)
    8000179e:	0880                	addi	s0,sp,80
    800017a0:	8a2a                	mv	s4,a0
    800017a2:	8b2e                	mv	s6,a1
    800017a4:	8bb2                	mv	s7,a2
    800017a6:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800017a8:	7ae1                	lui	s5,0xffff8
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017aa:	69a1                	lui	s3,0x8
    800017ac:	a035                	j	800017d8 <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800017ae:	00078023          	sb	zero,0(a5) # 8000 <_entry-0x7fff8000>
    800017b2:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800017b4:	0017b793          	seqz	a5,a5
    800017b8:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800017bc:	60a6                	ld	ra,72(sp)
    800017be:	6406                	ld	s0,64(sp)
    800017c0:	74e2                	ld	s1,56(sp)
    800017c2:	7942                	ld	s2,48(sp)
    800017c4:	79a2                	ld	s3,40(sp)
    800017c6:	7a02                	ld	s4,32(sp)
    800017c8:	6ae2                	ld	s5,24(sp)
    800017ca:	6b42                	ld	s6,16(sp)
    800017cc:	6ba2                	ld	s7,8(sp)
    800017ce:	6161                	addi	sp,sp,80
    800017d0:	8082                	ret
    srcva = va0 + PGSIZE;
    800017d2:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800017d6:	c8a9                	beqz	s1,80001828 <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    800017d8:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800017dc:	85ca                	mv	a1,s2
    800017de:	8552                	mv	a0,s4
    800017e0:	00000097          	auipc	ra,0x0
    800017e4:	88c080e7          	jalr	-1908(ra) # 8000106c <walkaddr>
    if(pa0 == 0)
    800017e8:	c131                	beqz	a0,8000182c <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    800017ea:	41790833          	sub	a6,s2,s7
    800017ee:	984e                	add	a6,a6,s3
    if(n > max)
    800017f0:	0104f363          	bgeu	s1,a6,800017f6 <copyinstr+0x6e>
    800017f4:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    800017f6:	955e                	add	a0,a0,s7
    800017f8:	41250533          	sub	a0,a0,s2
    while(n > 0){
    800017fc:	fc080be3          	beqz	a6,800017d2 <copyinstr+0x4a>
    80001800:	985a                	add	a6,a6,s6
    80001802:	87da                	mv	a5,s6
      if(*p == '\0'){
    80001804:	41650633          	sub	a2,a0,s6
    80001808:	14fd                	addi	s1,s1,-1
    8000180a:	9b26                	add	s6,s6,s1
    8000180c:	00f60733          	add	a4,a2,a5
    80001810:	00074703          	lbu	a4,0(a4)
    80001814:	df49                	beqz	a4,800017ae <copyinstr+0x26>
        *dst = *p;
    80001816:	00e78023          	sb	a4,0(a5)
      --max;
    8000181a:	40fb04b3          	sub	s1,s6,a5
      dst++;
    8000181e:	0785                	addi	a5,a5,1
    while(n > 0){
    80001820:	ff0796e3          	bne	a5,a6,8000180c <copyinstr+0x84>
      dst++;
    80001824:	8b42                	mv	s6,a6
    80001826:	b775                	j	800017d2 <copyinstr+0x4a>
    80001828:	4781                	li	a5,0
    8000182a:	b769                	j	800017b4 <copyinstr+0x2c>
      return -1;
    8000182c:	557d                	li	a0,-1
    8000182e:	b779                	j	800017bc <copyinstr+0x34>
  int got_null = 0;
    80001830:	4781                	li	a5,0
  if(got_null){
    80001832:	0017b793          	seqz	a5,a5
    80001836:	40f00533          	neg	a0,a5
}
    8000183a:	8082                	ret

000000008000183c <debug_uvmpte>:

int
debug_uvmpte(pagetable_t pagetable, uint64 va, uint64 size)
{
    8000183c:	7139                	addi	sp,sp,-64
    8000183e:	fc06                	sd	ra,56(sp)
    80001840:	f822                	sd	s0,48(sp)
    80001842:	f426                	sd	s1,40(sp)
    80001844:	f04a                	sd	s2,32(sp)
    80001846:	ec4e                	sd	s3,24(sp)
    80001848:	e852                	sd	s4,16(sp)
    8000184a:	e456                	sd	s5,8(sp)
    8000184c:	0080                	addi	s0,sp,64
    8000184e:	89aa                	mv	s3,a0
	uint64 a, last;
	pte_t *pte;

	a = PGROUNDDOWN(va);
    80001850:	77e1                	lui	a5,0xffff8
    80001852:	00f5f4b3          	and	s1,a1,a5
	last = PGROUNDDOWN(va + size - 1);
    80001856:	fff60913          	addi	s2,a2,-1 # 7fff <_entry-0x7fff8001>
    8000185a:	992e                	add	s2,s2,a1
    8000185c:	00f97933          	and	s2,s2,a5
		if((pte = walk(pagetable, a, 1)) == 0) return -1;
		if(a == last){
			printf("%x\n", *pte);
			break;
		}
		a += PGSIZE;
    80001860:	6aa1                	lui	s5,0x8
		printf("%x\n", *pte);
    80001862:	00007a17          	auipc	s4,0x7
    80001866:	976a0a13          	addi	s4,s4,-1674 # 800081d8 <digits+0x198>
		if((pte = walk(pagetable, a, 1)) == 0) return -1;
    8000186a:	4605                	li	a2,1
    8000186c:	85a6                	mv	a1,s1
    8000186e:	854e                	mv	a0,s3
    80001870:	fffff097          	auipc	ra,0xfffff
    80001874:	758080e7          	jalr	1880(ra) # 80000fc8 <walk>
    80001878:	c515                	beqz	a0,800018a4 <debug_uvmpte+0x68>
		if(a == last){
    8000187a:	01248a63          	beq	s1,s2,8000188e <debug_uvmpte+0x52>
		a += PGSIZE;
    8000187e:	94d6                	add	s1,s1,s5
		printf("%x\n", *pte);
    80001880:	610c                	ld	a1,0(a0)
    80001882:	8552                	mv	a0,s4
    80001884:	fffff097          	auipc	ra,0xfffff
    80001888:	d04080e7          	jalr	-764(ra) # 80000588 <printf>
		if((pte = walk(pagetable, a, 1)) == 0) return -1;
    8000188c:	bff9                	j	8000186a <debug_uvmpte+0x2e>
			printf("%x\n", *pte);
    8000188e:	610c                	ld	a1,0(a0)
    80001890:	00007517          	auipc	a0,0x7
    80001894:	94850513          	addi	a0,a0,-1720 # 800081d8 <digits+0x198>
    80001898:	fffff097          	auipc	ra,0xfffff
    8000189c:	cf0080e7          	jalr	-784(ra) # 80000588 <printf>
	}
	return 0;
    800018a0:	4501                	li	a0,0
    800018a2:	a011                	j	800018a6 <debug_uvmpte+0x6a>
		if((pte = walk(pagetable, a, 1)) == 0) return -1;
    800018a4:	557d                	li	a0,-1

}
    800018a6:	70e2                	ld	ra,56(sp)
    800018a8:	7442                	ld	s0,48(sp)
    800018aa:	74a2                	ld	s1,40(sp)
    800018ac:	7902                	ld	s2,32(sp)
    800018ae:	69e2                	ld	s3,24(sp)
    800018b0:	6a42                	ld	s4,16(sp)
    800018b2:	6aa2                	ld	s5,8(sp)
    800018b4:	6121                	addi	sp,sp,64
    800018b6:	8082                	ret

00000000800018b8 <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl) {
    800018b8:	7139                	addi	sp,sp,-64
    800018ba:	fc06                	sd	ra,56(sp)
    800018bc:	f822                	sd	s0,48(sp)
    800018be:	f426                	sd	s1,40(sp)
    800018c0:	f04a                	sd	s2,32(sp)
    800018c2:	ec4e                	sd	s3,24(sp)
    800018c4:	e852                	sd	s4,16(sp)
    800018c6:	e456                	sd	s5,8(sp)
    800018c8:	e05a                	sd	s6,0(sp)
    800018ca:	0080                	addi	s0,sp,64
    800018cc:	89aa                	mv	s3,a0
	struct proc *p;

	for(p = proc; p < &proc[NPROC]; p++) {
    800018ce:	00017497          	auipc	s1,0x17
    800018d2:	e0248493          	addi	s1,s1,-510 # 800186d0 <proc>
		char *pa = kalloc();
		if(pa == 0)
			panic("kalloc");
		uint64 va = KSTACK((int) (p - proc));
    800018d6:	8b26                	mv	s6,s1
    800018d8:	00006a97          	auipc	s5,0x6
    800018dc:	728a8a93          	addi	s5,s5,1832 # 80008000 <etext>
    800018e0:	00800937          	lui	s2,0x800
    800018e4:	197d                	addi	s2,s2,-1
    800018e6:	093e                	slli	s2,s2,0xf
	for(p = proc; p < &proc[NPROC]; p++) {
    800018e8:	0001ca17          	auipc	s4,0x1c
    800018ec:	7e8a0a13          	addi	s4,s4,2024 # 8001e0d0 <tickslock>
		char *pa = kalloc();
    800018f0:	fffff097          	auipc	ra,0xfffff
    800018f4:	204080e7          	jalr	516(ra) # 80000af4 <kalloc>
    800018f8:	862a                	mv	a2,a0
		if(pa == 0)
    800018fa:	c131                	beqz	a0,8000193e <proc_mapstacks+0x86>
		uint64 va = KSTACK((int) (p - proc));
    800018fc:	416485b3          	sub	a1,s1,s6
    80001900:	858d                	srai	a1,a1,0x3
    80001902:	000ab783          	ld	a5,0(s5)
    80001906:	02f585b3          	mul	a1,a1,a5
    8000190a:	2585                	addiw	a1,a1,1
    8000190c:	0105959b          	slliw	a1,a1,0x10
		kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001910:	4719                	li	a4,6
    80001912:	66a1                	lui	a3,0x8
    80001914:	40b905b3          	sub	a1,s2,a1
    80001918:	854e                	mv	a0,s3
    8000191a:	00000097          	auipc	ra,0x0
    8000191e:	834080e7          	jalr	-1996(ra) # 8000114e <kvmmap>
	for(p = proc; p < &proc[NPROC]; p++) {
    80001922:	16848493          	addi	s1,s1,360
    80001926:	fd4495e3          	bne	s1,s4,800018f0 <proc_mapstacks+0x38>
	}
}
    8000192a:	70e2                	ld	ra,56(sp)
    8000192c:	7442                	ld	s0,48(sp)
    8000192e:	74a2                	ld	s1,40(sp)
    80001930:	7902                	ld	s2,32(sp)
    80001932:	69e2                	ld	s3,24(sp)
    80001934:	6a42                	ld	s4,16(sp)
    80001936:	6aa2                	ld	s5,8(sp)
    80001938:	6b02                	ld	s6,0(sp)
    8000193a:	6121                	addi	sp,sp,64
    8000193c:	8082                	ret
			panic("kalloc");
    8000193e:	00007517          	auipc	a0,0x7
    80001942:	8a250513          	addi	a0,a0,-1886 # 800081e0 <digits+0x1a0>
    80001946:	fffff097          	auipc	ra,0xfffff
    8000194a:	bf8080e7          	jalr	-1032(ra) # 8000053e <panic>

000000008000194e <procinit>:

// initialize the proc table at boot time.
void
procinit(void)
{
    8000194e:	7139                	addi	sp,sp,-64
    80001950:	fc06                	sd	ra,56(sp)
    80001952:	f822                	sd	s0,48(sp)
    80001954:	f426                	sd	s1,40(sp)
    80001956:	f04a                	sd	s2,32(sp)
    80001958:	ec4e                	sd	s3,24(sp)
    8000195a:	e852                	sd	s4,16(sp)
    8000195c:	e456                	sd	s5,8(sp)
    8000195e:	e05a                	sd	s6,0(sp)
    80001960:	0080                	addi	s0,sp,64
	struct proc *p;

	initlock(&pid_lock, "nextpid");
    80001962:	00007597          	auipc	a1,0x7
    80001966:	88658593          	addi	a1,a1,-1914 # 800081e8 <digits+0x1a8>
    8000196a:	00017517          	auipc	a0,0x17
    8000196e:	93650513          	addi	a0,a0,-1738 # 800182a0 <pid_lock>
    80001972:	fffff097          	auipc	ra,0xfffff
    80001976:	1e2080e7          	jalr	482(ra) # 80000b54 <initlock>
	initlock(&wait_lock, "wait_lock");
    8000197a:	00007597          	auipc	a1,0x7
    8000197e:	87658593          	addi	a1,a1,-1930 # 800081f0 <digits+0x1b0>
    80001982:	00017517          	auipc	a0,0x17
    80001986:	93650513          	addi	a0,a0,-1738 # 800182b8 <wait_lock>
    8000198a:	fffff097          	auipc	ra,0xfffff
    8000198e:	1ca080e7          	jalr	458(ra) # 80000b54 <initlock>
	for(p = proc; p < &proc[NPROC]; p++) {
    80001992:	00017497          	auipc	s1,0x17
    80001996:	d3e48493          	addi	s1,s1,-706 # 800186d0 <proc>
		initlock(&p->lock, "proc");
    8000199a:	00007b17          	auipc	s6,0x7
    8000199e:	866b0b13          	addi	s6,s6,-1946 # 80008200 <digits+0x1c0>
		p->kstack = KSTACK((int) (p - proc));
    800019a2:	8aa6                	mv	s5,s1
    800019a4:	00006a17          	auipc	s4,0x6
    800019a8:	65ca0a13          	addi	s4,s4,1628 # 80008000 <etext>
    800019ac:	00800937          	lui	s2,0x800
    800019b0:	197d                	addi	s2,s2,-1
    800019b2:	093e                	slli	s2,s2,0xf
	for(p = proc; p < &proc[NPROC]; p++) {
    800019b4:	0001c997          	auipc	s3,0x1c
    800019b8:	71c98993          	addi	s3,s3,1820 # 8001e0d0 <tickslock>
		initlock(&p->lock, "proc");
    800019bc:	85da                	mv	a1,s6
    800019be:	8526                	mv	a0,s1
    800019c0:	fffff097          	auipc	ra,0xfffff
    800019c4:	194080e7          	jalr	404(ra) # 80000b54 <initlock>
		p->kstack = KSTACK((int) (p - proc));
    800019c8:	415487b3          	sub	a5,s1,s5
    800019cc:	878d                	srai	a5,a5,0x3
    800019ce:	000a3703          	ld	a4,0(s4)
    800019d2:	02e787b3          	mul	a5,a5,a4
    800019d6:	2785                	addiw	a5,a5,1
    800019d8:	0107979b          	slliw	a5,a5,0x10
    800019dc:	40f907b3          	sub	a5,s2,a5
    800019e0:	e0bc                	sd	a5,64(s1)
	for(p = proc; p < &proc[NPROC]; p++) {
    800019e2:	16848493          	addi	s1,s1,360
    800019e6:	fd349be3          	bne	s1,s3,800019bc <procinit+0x6e>
	}
}
    800019ea:	70e2                	ld	ra,56(sp)
    800019ec:	7442                	ld	s0,48(sp)
    800019ee:	74a2                	ld	s1,40(sp)
    800019f0:	7902                	ld	s2,32(sp)
    800019f2:	69e2                	ld	s3,24(sp)
    800019f4:	6a42                	ld	s4,16(sp)
    800019f6:	6aa2                	ld	s5,8(sp)
    800019f8:	6b02                	ld	s6,0(sp)
    800019fa:	6121                	addi	sp,sp,64
    800019fc:	8082                	ret

00000000800019fe <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    800019fe:	1141                	addi	sp,sp,-16
    80001a00:	e422                	sd	s0,8(sp)
    80001a02:	0800                	addi	s0,sp,16
	asm volatile("mv %0, tp" : "=r" (x) );
    80001a04:	8512                	mv	a0,tp
	int id = r_tp();
	return id;
}
    80001a06:	2501                	sext.w	a0,a0
    80001a08:	6422                	ld	s0,8(sp)
    80001a0a:	0141                	addi	sp,sp,16
    80001a0c:	8082                	ret

0000000080001a0e <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void) {
    80001a0e:	1141                	addi	sp,sp,-16
    80001a10:	e422                	sd	s0,8(sp)
    80001a12:	0800                	addi	s0,sp,16
    80001a14:	8792                	mv	a5,tp
	int id = cpuid();
	struct cpu *c = &cpus[id];
    80001a16:	2781                	sext.w	a5,a5
    80001a18:	079e                	slli	a5,a5,0x7
	return c;
}
    80001a1a:	00017517          	auipc	a0,0x17
    80001a1e:	8b650513          	addi	a0,a0,-1866 # 800182d0 <cpus>
    80001a22:	953e                	add	a0,a0,a5
    80001a24:	6422                	ld	s0,8(sp)
    80001a26:	0141                	addi	sp,sp,16
    80001a28:	8082                	ret

0000000080001a2a <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void) {
    80001a2a:	1101                	addi	sp,sp,-32
    80001a2c:	ec06                	sd	ra,24(sp)
    80001a2e:	e822                	sd	s0,16(sp)
    80001a30:	e426                	sd	s1,8(sp)
    80001a32:	1000                	addi	s0,sp,32
	push_off();
    80001a34:	fffff097          	auipc	ra,0xfffff
    80001a38:	164080e7          	jalr	356(ra) # 80000b98 <push_off>
    80001a3c:	8792                	mv	a5,tp
	struct cpu *c = mycpu();
	struct proc *p = c->proc;
    80001a3e:	2781                	sext.w	a5,a5
    80001a40:	079e                	slli	a5,a5,0x7
    80001a42:	00017717          	auipc	a4,0x17
    80001a46:	85e70713          	addi	a4,a4,-1954 # 800182a0 <pid_lock>
    80001a4a:	97ba                	add	a5,a5,a4
    80001a4c:	7b84                	ld	s1,48(a5)
	pop_off();
    80001a4e:	fffff097          	auipc	ra,0xfffff
    80001a52:	1ea080e7          	jalr	490(ra) # 80000c38 <pop_off>
	return p;
}
    80001a56:	8526                	mv	a0,s1
    80001a58:	60e2                	ld	ra,24(sp)
    80001a5a:	6442                	ld	s0,16(sp)
    80001a5c:	64a2                	ld	s1,8(sp)
    80001a5e:	6105                	addi	sp,sp,32
    80001a60:	8082                	ret

0000000080001a62 <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    80001a62:	1141                	addi	sp,sp,-16
    80001a64:	e406                	sd	ra,8(sp)
    80001a66:	e022                	sd	s0,0(sp)
    80001a68:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001a6a:	00000097          	auipc	ra,0x0
    80001a6e:	fc0080e7          	jalr	-64(ra) # 80001a2a <myproc>
    80001a72:	fffff097          	auipc	ra,0xfffff
    80001a76:	226080e7          	jalr	550(ra) # 80000c98 <release>

  if (first) {
    80001a7a:	00007797          	auipc	a5,0x7
    80001a7e:	da67a783          	lw	a5,-602(a5) # 80008820 <first.1676>
    80001a82:	eb89                	bnez	a5,80001a94 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001a84:	00001097          	auipc	ra,0x1
    80001a88:	c0a080e7          	jalr	-1014(ra) # 8000268e <usertrapret>
}
    80001a8c:	60a2                	ld	ra,8(sp)
    80001a8e:	6402                	ld	s0,0(sp)
    80001a90:	0141                	addi	sp,sp,16
    80001a92:	8082                	ret
    first = 0;
    80001a94:	00007797          	auipc	a5,0x7
    80001a98:	d807a623          	sw	zero,-628(a5) # 80008820 <first.1676>
    fsinit(ROOTDEV);
    80001a9c:	4505                	li	a0,1
    80001a9e:	00002097          	auipc	ra,0x2
    80001aa2:	932080e7          	jalr	-1742(ra) # 800033d0 <fsinit>
    80001aa6:	bff9                	j	80001a84 <forkret+0x22>

0000000080001aa8 <allocpid>:
allocpid() {
    80001aa8:	1101                	addi	sp,sp,-32
    80001aaa:	ec06                	sd	ra,24(sp)
    80001aac:	e822                	sd	s0,16(sp)
    80001aae:	e426                	sd	s1,8(sp)
    80001ab0:	e04a                	sd	s2,0(sp)
    80001ab2:	1000                	addi	s0,sp,32
	acquire(&pid_lock);
    80001ab4:	00016917          	auipc	s2,0x16
    80001ab8:	7ec90913          	addi	s2,s2,2028 # 800182a0 <pid_lock>
    80001abc:	854a                	mv	a0,s2
    80001abe:	fffff097          	auipc	ra,0xfffff
    80001ac2:	126080e7          	jalr	294(ra) # 80000be4 <acquire>
	pid = nextpid;
    80001ac6:	00007797          	auipc	a5,0x7
    80001aca:	d5e78793          	addi	a5,a5,-674 # 80008824 <nextpid>
    80001ace:	4384                	lw	s1,0(a5)
	nextpid = nextpid + 1;
    80001ad0:	0014871b          	addiw	a4,s1,1
    80001ad4:	c398                	sw	a4,0(a5)
	release(&pid_lock);
    80001ad6:	854a                	mv	a0,s2
    80001ad8:	fffff097          	auipc	ra,0xfffff
    80001adc:	1c0080e7          	jalr	448(ra) # 80000c98 <release>
}
    80001ae0:	8526                	mv	a0,s1
    80001ae2:	60e2                	ld	ra,24(sp)
    80001ae4:	6442                	ld	s0,16(sp)
    80001ae6:	64a2                	ld	s1,8(sp)
    80001ae8:	6902                	ld	s2,0(sp)
    80001aea:	6105                	addi	sp,sp,32
    80001aec:	8082                	ret

0000000080001aee <proc_pagetable>:
{
    80001aee:	1101                	addi	sp,sp,-32
    80001af0:	ec06                	sd	ra,24(sp)
    80001af2:	e822                	sd	s0,16(sp)
    80001af4:	e426                	sd	s1,8(sp)
    80001af6:	e04a                	sd	s2,0(sp)
    80001af8:	1000                	addi	s0,sp,32
    80001afa:	892a                	mv	s2,a0
	pagetable = uvmcreate();
    80001afc:	00000097          	auipc	ra,0x0
    80001b00:	83c080e7          	jalr	-1988(ra) # 80001338 <uvmcreate>
    80001b04:	84aa                	mv	s1,a0
	if(pagetable == 0)
    80001b06:	c121                	beqz	a0,80001b46 <proc_pagetable+0x58>
	if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001b08:	4729                	li	a4,10
    80001b0a:	00005697          	auipc	a3,0x5
    80001b0e:	4f668693          	addi	a3,a3,1270 # 80007000 <_trampoline>
    80001b12:	6621                	lui	a2,0x8
    80001b14:	008005b7          	lui	a1,0x800
    80001b18:	15fd                	addi	a1,a1,-1
    80001b1a:	05be                	slli	a1,a1,0xf
    80001b1c:	fffff097          	auipc	ra,0xfffff
    80001b20:	592080e7          	jalr	1426(ra) # 800010ae <mappages>
    80001b24:	02054863          	bltz	a0,80001b54 <proc_pagetable+0x66>
	if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001b28:	4719                	li	a4,6
    80001b2a:	05893683          	ld	a3,88(s2)
    80001b2e:	6621                	lui	a2,0x8
    80001b30:	004005b7          	lui	a1,0x400
    80001b34:	15fd                	addi	a1,a1,-1
    80001b36:	05c2                	slli	a1,a1,0x10
    80001b38:	8526                	mv	a0,s1
    80001b3a:	fffff097          	auipc	ra,0xfffff
    80001b3e:	574080e7          	jalr	1396(ra) # 800010ae <mappages>
    80001b42:	02054163          	bltz	a0,80001b64 <proc_pagetable+0x76>
}
    80001b46:	8526                	mv	a0,s1
    80001b48:	60e2                	ld	ra,24(sp)
    80001b4a:	6442                	ld	s0,16(sp)
    80001b4c:	64a2                	ld	s1,8(sp)
    80001b4e:	6902                	ld	s2,0(sp)
    80001b50:	6105                	addi	sp,sp,32
    80001b52:	8082                	ret
		uvmfree(pagetable, 0);
    80001b54:	4581                	li	a1,0
    80001b56:	8526                	mv	a0,s1
    80001b58:	00000097          	auipc	ra,0x0
    80001b5c:	9dc080e7          	jalr	-1572(ra) # 80001534 <uvmfree>
		return 0;
    80001b60:	4481                	li	s1,0
    80001b62:	b7d5                	j	80001b46 <proc_pagetable+0x58>
		uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b64:	4681                	li	a3,0
    80001b66:	4605                	li	a2,1
    80001b68:	008005b7          	lui	a1,0x800
    80001b6c:	15fd                	addi	a1,a1,-1
    80001b6e:	05be                	slli	a1,a1,0xf
    80001b70:	8526                	mv	a0,s1
    80001b72:	fffff097          	auipc	ra,0xfffff
    80001b76:	702080e7          	jalr	1794(ra) # 80001274 <uvmunmap>
		uvmfree(pagetable, 0);
    80001b7a:	4581                	li	a1,0
    80001b7c:	8526                	mv	a0,s1
    80001b7e:	00000097          	auipc	ra,0x0
    80001b82:	9b6080e7          	jalr	-1610(ra) # 80001534 <uvmfree>
		return 0;
    80001b86:	4481                	li	s1,0
    80001b88:	bf7d                	j	80001b46 <proc_pagetable+0x58>

0000000080001b8a <proc_freepagetable>:
{
    80001b8a:	1101                	addi	sp,sp,-32
    80001b8c:	ec06                	sd	ra,24(sp)
    80001b8e:	e822                	sd	s0,16(sp)
    80001b90:	e426                	sd	s1,8(sp)
    80001b92:	e04a                	sd	s2,0(sp)
    80001b94:	1000                	addi	s0,sp,32
    80001b96:	84aa                	mv	s1,a0
    80001b98:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b9a:	4681                	li	a3,0
    80001b9c:	4605                	li	a2,1
    80001b9e:	008005b7          	lui	a1,0x800
    80001ba2:	15fd                	addi	a1,a1,-1
    80001ba4:	05be                	slli	a1,a1,0xf
    80001ba6:	fffff097          	auipc	ra,0xfffff
    80001baa:	6ce080e7          	jalr	1742(ra) # 80001274 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001bae:	4681                	li	a3,0
    80001bb0:	4605                	li	a2,1
    80001bb2:	004005b7          	lui	a1,0x400
    80001bb6:	15fd                	addi	a1,a1,-1
    80001bb8:	05c2                	slli	a1,a1,0x10
    80001bba:	8526                	mv	a0,s1
    80001bbc:	fffff097          	auipc	ra,0xfffff
    80001bc0:	6b8080e7          	jalr	1720(ra) # 80001274 <uvmunmap>
  uvmfree(pagetable, sz);
    80001bc4:	85ca                	mv	a1,s2
    80001bc6:	8526                	mv	a0,s1
    80001bc8:	00000097          	auipc	ra,0x0
    80001bcc:	96c080e7          	jalr	-1684(ra) # 80001534 <uvmfree>
}
    80001bd0:	60e2                	ld	ra,24(sp)
    80001bd2:	6442                	ld	s0,16(sp)
    80001bd4:	64a2                	ld	s1,8(sp)
    80001bd6:	6902                	ld	s2,0(sp)
    80001bd8:	6105                	addi	sp,sp,32
    80001bda:	8082                	ret

0000000080001bdc <freeproc>:
{
    80001bdc:	1101                	addi	sp,sp,-32
    80001bde:	ec06                	sd	ra,24(sp)
    80001be0:	e822                	sd	s0,16(sp)
    80001be2:	e426                	sd	s1,8(sp)
    80001be4:	1000                	addi	s0,sp,32
    80001be6:	84aa                	mv	s1,a0
	if(p->trapframe)
    80001be8:	6d28                	ld	a0,88(a0)
    80001bea:	c509                	beqz	a0,80001bf4 <freeproc+0x18>
		kfree((void*)p->trapframe);
    80001bec:	fffff097          	auipc	ra,0xfffff
    80001bf0:	e0c080e7          	jalr	-500(ra) # 800009f8 <kfree>
	p->trapframe = 0;
    80001bf4:	0404bc23          	sd	zero,88(s1)
	if(p->pagetable)
    80001bf8:	68a8                	ld	a0,80(s1)
    80001bfa:	c511                	beqz	a0,80001c06 <freeproc+0x2a>
		proc_freepagetable(p->pagetable, p->sz);
    80001bfc:	64ac                	ld	a1,72(s1)
    80001bfe:	00000097          	auipc	ra,0x0
    80001c02:	f8c080e7          	jalr	-116(ra) # 80001b8a <proc_freepagetable>
	p->pagetable = 0;
    80001c06:	0404b823          	sd	zero,80(s1)
	p->sz = 0;
    80001c0a:	0404b423          	sd	zero,72(s1)
	p->pid = 0;
    80001c0e:	0204a823          	sw	zero,48(s1)
	p->parent = 0;
    80001c12:	0204bc23          	sd	zero,56(s1)
	p->name[0] = 0;
    80001c16:	14048c23          	sb	zero,344(s1)
	p->chan = 0;
    80001c1a:	0204b023          	sd	zero,32(s1)
	p->killed = 0;
    80001c1e:	0204a423          	sw	zero,40(s1)
	p->xstate = 0;
    80001c22:	0204a623          	sw	zero,44(s1)
	p->state = UNUSED;
    80001c26:	0004ac23          	sw	zero,24(s1)
}
    80001c2a:	60e2                	ld	ra,24(sp)
    80001c2c:	6442                	ld	s0,16(sp)
    80001c2e:	64a2                	ld	s1,8(sp)
    80001c30:	6105                	addi	sp,sp,32
    80001c32:	8082                	ret

0000000080001c34 <allocproc>:
{
    80001c34:	1101                	addi	sp,sp,-32
    80001c36:	ec06                	sd	ra,24(sp)
    80001c38:	e822                	sd	s0,16(sp)
    80001c3a:	e426                	sd	s1,8(sp)
    80001c3c:	e04a                	sd	s2,0(sp)
    80001c3e:	1000                	addi	s0,sp,32
	for(p = proc; p < &proc[NPROC]; p++) {
    80001c40:	00017497          	auipc	s1,0x17
    80001c44:	a9048493          	addi	s1,s1,-1392 # 800186d0 <proc>
    80001c48:	0001c917          	auipc	s2,0x1c
    80001c4c:	48890913          	addi	s2,s2,1160 # 8001e0d0 <tickslock>
		acquire(&p->lock);
    80001c50:	8526                	mv	a0,s1
    80001c52:	fffff097          	auipc	ra,0xfffff
    80001c56:	f92080e7          	jalr	-110(ra) # 80000be4 <acquire>
		if(p->state == UNUSED) {
    80001c5a:	4c9c                	lw	a5,24(s1)
    80001c5c:	cf81                	beqz	a5,80001c74 <allocproc+0x40>
			release(&p->lock);
    80001c5e:	8526                	mv	a0,s1
    80001c60:	fffff097          	auipc	ra,0xfffff
    80001c64:	038080e7          	jalr	56(ra) # 80000c98 <release>
	for(p = proc; p < &proc[NPROC]; p++) {
    80001c68:	16848493          	addi	s1,s1,360
    80001c6c:	ff2492e3          	bne	s1,s2,80001c50 <allocproc+0x1c>
	return 0;
    80001c70:	4481                	li	s1,0
    80001c72:	a889                	j	80001cc4 <allocproc+0x90>
	p->pid = allocpid();
    80001c74:	00000097          	auipc	ra,0x0
    80001c78:	e34080e7          	jalr	-460(ra) # 80001aa8 <allocpid>
    80001c7c:	d888                	sw	a0,48(s1)
	p->state = USED;
    80001c7e:	4785                	li	a5,1
    80001c80:	cc9c                	sw	a5,24(s1)
	if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001c82:	fffff097          	auipc	ra,0xfffff
    80001c86:	e72080e7          	jalr	-398(ra) # 80000af4 <kalloc>
    80001c8a:	892a                	mv	s2,a0
    80001c8c:	eca8                	sd	a0,88(s1)
    80001c8e:	c131                	beqz	a0,80001cd2 <allocproc+0x9e>
	p->pagetable = proc_pagetable(p);
    80001c90:	8526                	mv	a0,s1
    80001c92:	00000097          	auipc	ra,0x0
    80001c96:	e5c080e7          	jalr	-420(ra) # 80001aee <proc_pagetable>
    80001c9a:	892a                	mv	s2,a0
    80001c9c:	e8a8                	sd	a0,80(s1)
	if(p->pagetable == 0){
    80001c9e:	c531                	beqz	a0,80001cea <allocproc+0xb6>
	memset(&p->context, 0, sizeof(p->context));
    80001ca0:	07000613          	li	a2,112
    80001ca4:	4581                	li	a1,0
    80001ca6:	06048513          	addi	a0,s1,96
    80001caa:	fffff097          	auipc	ra,0xfffff
    80001cae:	036080e7          	jalr	54(ra) # 80000ce0 <memset>
	p->context.ra = (uint64)forkret;
    80001cb2:	00000797          	auipc	a5,0x0
    80001cb6:	db078793          	addi	a5,a5,-592 # 80001a62 <forkret>
    80001cba:	f0bc                	sd	a5,96(s1)
	p->context.sp = p->kstack + PGSIZE;
    80001cbc:	60bc                	ld	a5,64(s1)
    80001cbe:	6721                	lui	a4,0x8
    80001cc0:	97ba                	add	a5,a5,a4
    80001cc2:	f4bc                	sd	a5,104(s1)
}
    80001cc4:	8526                	mv	a0,s1
    80001cc6:	60e2                	ld	ra,24(sp)
    80001cc8:	6442                	ld	s0,16(sp)
    80001cca:	64a2                	ld	s1,8(sp)
    80001ccc:	6902                	ld	s2,0(sp)
    80001cce:	6105                	addi	sp,sp,32
    80001cd0:	8082                	ret
		freeproc(p);
    80001cd2:	8526                	mv	a0,s1
    80001cd4:	00000097          	auipc	ra,0x0
    80001cd8:	f08080e7          	jalr	-248(ra) # 80001bdc <freeproc>
		release(&p->lock);
    80001cdc:	8526                	mv	a0,s1
    80001cde:	fffff097          	auipc	ra,0xfffff
    80001ce2:	fba080e7          	jalr	-70(ra) # 80000c98 <release>
		return 0;
    80001ce6:	84ca                	mv	s1,s2
    80001ce8:	bff1                	j	80001cc4 <allocproc+0x90>
		freeproc(p);
    80001cea:	8526                	mv	a0,s1
    80001cec:	00000097          	auipc	ra,0x0
    80001cf0:	ef0080e7          	jalr	-272(ra) # 80001bdc <freeproc>
		release(&p->lock);
    80001cf4:	8526                	mv	a0,s1
    80001cf6:	fffff097          	auipc	ra,0xfffff
    80001cfa:	fa2080e7          	jalr	-94(ra) # 80000c98 <release>
		return 0;
    80001cfe:	84ca                	mv	s1,s2
    80001d00:	b7d1                	j	80001cc4 <allocproc+0x90>

0000000080001d02 <userinit>:
{
    80001d02:	1101                	addi	sp,sp,-32
    80001d04:	ec06                	sd	ra,24(sp)
    80001d06:	e822                	sd	s0,16(sp)
    80001d08:	e426                	sd	s1,8(sp)
    80001d0a:	1000                	addi	s0,sp,32
	p = allocproc();
    80001d0c:	00000097          	auipc	ra,0x0
    80001d10:	f28080e7          	jalr	-216(ra) # 80001c34 <allocproc>
    80001d14:	84aa                	mv	s1,a0
	initproc = p;
    80001d16:	0000e797          	auipc	a5,0xe
    80001d1a:	30a7b923          	sd	a0,786(a5) # 80010028 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001d1e:	03400613          	li	a2,52
    80001d22:	00007597          	auipc	a1,0x7
    80001d26:	b0e58593          	addi	a1,a1,-1266 # 80008830 <initcode>
    80001d2a:	6928                	ld	a0,80(a0)
    80001d2c:	fffff097          	auipc	ra,0xfffff
    80001d30:	63a080e7          	jalr	1594(ra) # 80001366 <uvminit>
	p->sz = PGSIZE;
    80001d34:	67a1                	lui	a5,0x8
    80001d36:	e4bc                	sd	a5,72(s1)
	p->trapframe->epc = 0;      // user program counter
    80001d38:	6cb8                	ld	a4,88(s1)
    80001d3a:	00073c23          	sd	zero,24(a4) # 8018 <_entry-0x7fff7fe8>
	p->trapframe->sp = PGSIZE;  // user stack pointer
    80001d3e:	6cb8                	ld	a4,88(s1)
    80001d40:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001d42:	4641                	li	a2,16
    80001d44:	00006597          	auipc	a1,0x6
    80001d48:	4c458593          	addi	a1,a1,1220 # 80008208 <digits+0x1c8>
    80001d4c:	15848513          	addi	a0,s1,344
    80001d50:	fffff097          	auipc	ra,0xfffff
    80001d54:	0e2080e7          	jalr	226(ra) # 80000e32 <safestrcpy>
	p->cwd = namei("/");
    80001d58:	00006517          	auipc	a0,0x6
    80001d5c:	4c050513          	addi	a0,a0,1216 # 80008218 <digits+0x1d8>
    80001d60:	00002097          	auipc	ra,0x2
    80001d64:	09e080e7          	jalr	158(ra) # 80003dfe <namei>
    80001d68:	14a4b823          	sd	a0,336(s1)
	p->state = RUNNABLE;
    80001d6c:	478d                	li	a5,3
    80001d6e:	cc9c                	sw	a5,24(s1)
	release(&p->lock);
    80001d70:	8526                	mv	a0,s1
    80001d72:	fffff097          	auipc	ra,0xfffff
    80001d76:	f26080e7          	jalr	-218(ra) # 80000c98 <release>
}
    80001d7a:	60e2                	ld	ra,24(sp)
    80001d7c:	6442                	ld	s0,16(sp)
    80001d7e:	64a2                	ld	s1,8(sp)
    80001d80:	6105                	addi	sp,sp,32
    80001d82:	8082                	ret

0000000080001d84 <growproc>:
{
    80001d84:	1101                	addi	sp,sp,-32
    80001d86:	ec06                	sd	ra,24(sp)
    80001d88:	e822                	sd	s0,16(sp)
    80001d8a:	e426                	sd	s1,8(sp)
    80001d8c:	e04a                	sd	s2,0(sp)
    80001d8e:	1000                	addi	s0,sp,32
    80001d90:	84aa                	mv	s1,a0
	struct proc *p = myproc();
    80001d92:	00000097          	auipc	ra,0x0
    80001d96:	c98080e7          	jalr	-872(ra) # 80001a2a <myproc>
    80001d9a:	892a                	mv	s2,a0
	sz = p->sz;
    80001d9c:	652c                	ld	a1,72(a0)
    80001d9e:	0005861b          	sext.w	a2,a1
	if(n > 0){
    80001da2:	00904f63          	bgtz	s1,80001dc0 <growproc+0x3c>
	} else if(n < 0){
    80001da6:	0204cc63          	bltz	s1,80001dde <growproc+0x5a>
	p->sz = sz;
    80001daa:	1602                	slli	a2,a2,0x20
    80001dac:	9201                	srli	a2,a2,0x20
    80001dae:	04c93423          	sd	a2,72(s2)
	return 0;
    80001db2:	4501                	li	a0,0
}
    80001db4:	60e2                	ld	ra,24(sp)
    80001db6:	6442                	ld	s0,16(sp)
    80001db8:	64a2                	ld	s1,8(sp)
    80001dba:	6902                	ld	s2,0(sp)
    80001dbc:	6105                	addi	sp,sp,32
    80001dbe:	8082                	ret
		if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001dc0:	9e25                	addw	a2,a2,s1
    80001dc2:	1602                	slli	a2,a2,0x20
    80001dc4:	9201                	srli	a2,a2,0x20
    80001dc6:	1582                	slli	a1,a1,0x20
    80001dc8:	9181                	srli	a1,a1,0x20
    80001dca:	6928                	ld	a0,80(a0)
    80001dcc:	fffff097          	auipc	ra,0xfffff
    80001dd0:	654080e7          	jalr	1620(ra) # 80001420 <uvmalloc>
    80001dd4:	0005061b          	sext.w	a2,a0
    80001dd8:	fa69                	bnez	a2,80001daa <growproc+0x26>
			return -1;
    80001dda:	557d                	li	a0,-1
    80001ddc:	bfe1                	j	80001db4 <growproc+0x30>
		sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001dde:	9e25                	addw	a2,a2,s1
    80001de0:	1602                	slli	a2,a2,0x20
    80001de2:	9201                	srli	a2,a2,0x20
    80001de4:	1582                	slli	a1,a1,0x20
    80001de6:	9181                	srli	a1,a1,0x20
    80001de8:	6928                	ld	a0,80(a0)
    80001dea:	fffff097          	auipc	ra,0xfffff
    80001dee:	5ee080e7          	jalr	1518(ra) # 800013d8 <uvmdealloc>
    80001df2:	0005061b          	sext.w	a2,a0
    80001df6:	bf55                	j	80001daa <growproc+0x26>

0000000080001df8 <fork>:
{
    80001df8:	7179                	addi	sp,sp,-48
    80001dfa:	f406                	sd	ra,40(sp)
    80001dfc:	f022                	sd	s0,32(sp)
    80001dfe:	ec26                	sd	s1,24(sp)
    80001e00:	e84a                	sd	s2,16(sp)
    80001e02:	e44e                	sd	s3,8(sp)
    80001e04:	e052                	sd	s4,0(sp)
    80001e06:	1800                	addi	s0,sp,48
	struct proc *p = myproc();
    80001e08:	00000097          	auipc	ra,0x0
    80001e0c:	c22080e7          	jalr	-990(ra) # 80001a2a <myproc>
    80001e10:	892a                	mv	s2,a0
	if((np = allocproc()) == 0){
    80001e12:	00000097          	auipc	ra,0x0
    80001e16:	e22080e7          	jalr	-478(ra) # 80001c34 <allocproc>
    80001e1a:	10050b63          	beqz	a0,80001f30 <fork+0x138>
    80001e1e:	89aa                	mv	s3,a0
	if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001e20:	04893603          	ld	a2,72(s2)
    80001e24:	692c                	ld	a1,80(a0)
    80001e26:	05093503          	ld	a0,80(s2)
    80001e2a:	fffff097          	auipc	ra,0xfffff
    80001e2e:	742080e7          	jalr	1858(ra) # 8000156c <uvmcopy>
    80001e32:	04054663          	bltz	a0,80001e7e <fork+0x86>
	np->sz = p->sz;
    80001e36:	04893783          	ld	a5,72(s2)
    80001e3a:	04f9b423          	sd	a5,72(s3)
	*(np->trapframe) = *(p->trapframe);
    80001e3e:	05893683          	ld	a3,88(s2)
    80001e42:	87b6                	mv	a5,a3
    80001e44:	0589b703          	ld	a4,88(s3)
    80001e48:	12068693          	addi	a3,a3,288
    80001e4c:	0007b803          	ld	a6,0(a5) # 8000 <_entry-0x7fff8000>
    80001e50:	6788                	ld	a0,8(a5)
    80001e52:	6b8c                	ld	a1,16(a5)
    80001e54:	6f90                	ld	a2,24(a5)
    80001e56:	01073023          	sd	a6,0(a4)
    80001e5a:	e708                	sd	a0,8(a4)
    80001e5c:	eb0c                	sd	a1,16(a4)
    80001e5e:	ef10                	sd	a2,24(a4)
    80001e60:	02078793          	addi	a5,a5,32
    80001e64:	02070713          	addi	a4,a4,32
    80001e68:	fed792e3          	bne	a5,a3,80001e4c <fork+0x54>
	np->trapframe->a0 = 0;
    80001e6c:	0589b783          	ld	a5,88(s3)
    80001e70:	0607b823          	sd	zero,112(a5)
    80001e74:	0d000493          	li	s1,208
	for(i = 0; i < NOFILE; i++)
    80001e78:	15000a13          	li	s4,336
    80001e7c:	a03d                	j	80001eaa <fork+0xb2>
		freeproc(np);
    80001e7e:	854e                	mv	a0,s3
    80001e80:	00000097          	auipc	ra,0x0
    80001e84:	d5c080e7          	jalr	-676(ra) # 80001bdc <freeproc>
		release(&np->lock);
    80001e88:	854e                	mv	a0,s3
    80001e8a:	fffff097          	auipc	ra,0xfffff
    80001e8e:	e0e080e7          	jalr	-498(ra) # 80000c98 <release>
		return -1;
    80001e92:	5a7d                	li	s4,-1
    80001e94:	a069                	j	80001f1e <fork+0x126>
			np->ofile[i] = filedup(p->ofile[i]);
    80001e96:	00002097          	auipc	ra,0x2
    80001e9a:	5fe080e7          	jalr	1534(ra) # 80004494 <filedup>
    80001e9e:	009987b3          	add	a5,s3,s1
    80001ea2:	e388                	sd	a0,0(a5)
	for(i = 0; i < NOFILE; i++)
    80001ea4:	04a1                	addi	s1,s1,8
    80001ea6:	01448763          	beq	s1,s4,80001eb4 <fork+0xbc>
		if(p->ofile[i])
    80001eaa:	009907b3          	add	a5,s2,s1
    80001eae:	6388                	ld	a0,0(a5)
    80001eb0:	f17d                	bnez	a0,80001e96 <fork+0x9e>
    80001eb2:	bfcd                	j	80001ea4 <fork+0xac>
	np->cwd = idup(p->cwd);
    80001eb4:	15093503          	ld	a0,336(s2)
    80001eb8:	00001097          	auipc	ra,0x1
    80001ebc:	752080e7          	jalr	1874(ra) # 8000360a <idup>
    80001ec0:	14a9b823          	sd	a0,336(s3)
	safestrcpy(np->name, p->name, sizeof(p->name));
    80001ec4:	4641                	li	a2,16
    80001ec6:	15890593          	addi	a1,s2,344
    80001eca:	15898513          	addi	a0,s3,344
    80001ece:	fffff097          	auipc	ra,0xfffff
    80001ed2:	f64080e7          	jalr	-156(ra) # 80000e32 <safestrcpy>
	pid = np->pid;
    80001ed6:	0309aa03          	lw	s4,48(s3)
	release(&np->lock);
    80001eda:	854e                	mv	a0,s3
    80001edc:	fffff097          	auipc	ra,0xfffff
    80001ee0:	dbc080e7          	jalr	-580(ra) # 80000c98 <release>
	acquire(&wait_lock);
    80001ee4:	00016497          	auipc	s1,0x16
    80001ee8:	3d448493          	addi	s1,s1,980 # 800182b8 <wait_lock>
    80001eec:	8526                	mv	a0,s1
    80001eee:	fffff097          	auipc	ra,0xfffff
    80001ef2:	cf6080e7          	jalr	-778(ra) # 80000be4 <acquire>
	np->parent = p;
    80001ef6:	0329bc23          	sd	s2,56(s3)
	release(&wait_lock);
    80001efa:	8526                	mv	a0,s1
    80001efc:	fffff097          	auipc	ra,0xfffff
    80001f00:	d9c080e7          	jalr	-612(ra) # 80000c98 <release>
	acquire(&np->lock);
    80001f04:	854e                	mv	a0,s3
    80001f06:	fffff097          	auipc	ra,0xfffff
    80001f0a:	cde080e7          	jalr	-802(ra) # 80000be4 <acquire>
	np->state = RUNNABLE;
    80001f0e:	478d                	li	a5,3
    80001f10:	00f9ac23          	sw	a5,24(s3)
	release(&np->lock);
    80001f14:	854e                	mv	a0,s3
    80001f16:	fffff097          	auipc	ra,0xfffff
    80001f1a:	d82080e7          	jalr	-638(ra) # 80000c98 <release>
}
    80001f1e:	8552                	mv	a0,s4
    80001f20:	70a2                	ld	ra,40(sp)
    80001f22:	7402                	ld	s0,32(sp)
    80001f24:	64e2                	ld	s1,24(sp)
    80001f26:	6942                	ld	s2,16(sp)
    80001f28:	69a2                	ld	s3,8(sp)
    80001f2a:	6a02                	ld	s4,0(sp)
    80001f2c:	6145                	addi	sp,sp,48
    80001f2e:	8082                	ret
		return -1;
    80001f30:	5a7d                	li	s4,-1
    80001f32:	b7f5                	j	80001f1e <fork+0x126>

0000000080001f34 <scheduler>:
{
    80001f34:	7139                	addi	sp,sp,-64
    80001f36:	fc06                	sd	ra,56(sp)
    80001f38:	f822                	sd	s0,48(sp)
    80001f3a:	f426                	sd	s1,40(sp)
    80001f3c:	f04a                	sd	s2,32(sp)
    80001f3e:	ec4e                	sd	s3,24(sp)
    80001f40:	e852                	sd	s4,16(sp)
    80001f42:	e456                	sd	s5,8(sp)
    80001f44:	e05a                	sd	s6,0(sp)
    80001f46:	0080                	addi	s0,sp,64
    80001f48:	8792                	mv	a5,tp
	int id = r_tp();
    80001f4a:	2781                	sext.w	a5,a5
	c->proc = 0;
    80001f4c:	00779a93          	slli	s5,a5,0x7
    80001f50:	00016717          	auipc	a4,0x16
    80001f54:	35070713          	addi	a4,a4,848 # 800182a0 <pid_lock>
    80001f58:	9756                	add	a4,a4,s5
    80001f5a:	02073823          	sd	zero,48(a4)
				swtch(&c->context, &p->context);
    80001f5e:	00016717          	auipc	a4,0x16
    80001f62:	37a70713          	addi	a4,a4,890 # 800182d8 <cpus+0x8>
    80001f66:	9aba                	add	s5,s5,a4
			if(p->state == RUNNABLE) {
    80001f68:	498d                	li	s3,3
				p->state = RUNNING;
    80001f6a:	4b11                	li	s6,4
				c->proc = p;
    80001f6c:	079e                	slli	a5,a5,0x7
    80001f6e:	00016a17          	auipc	s4,0x16
    80001f72:	332a0a13          	addi	s4,s4,818 # 800182a0 <pid_lock>
    80001f76:	9a3e                	add	s4,s4,a5
		for(p = proc; p < &proc[NPROC]; p++) {
    80001f78:	0001c917          	auipc	s2,0x1c
    80001f7c:	15890913          	addi	s2,s2,344 # 8001e0d0 <tickslock>
	asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f80:	100027f3          	csrr	a5,sstatus
	w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001f84:	0027e793          	ori	a5,a5,2
	asm volatile("csrw sstatus, %0" : : "r" (x));
    80001f88:	10079073          	csrw	sstatus,a5
    80001f8c:	00016497          	auipc	s1,0x16
    80001f90:	74448493          	addi	s1,s1,1860 # 800186d0 <proc>
    80001f94:	a03d                	j	80001fc2 <scheduler+0x8e>
				p->state = RUNNING;
    80001f96:	0164ac23          	sw	s6,24(s1)
				c->proc = p;
    80001f9a:	029a3823          	sd	s1,48(s4)
				swtch(&c->context, &p->context);
    80001f9e:	06048593          	addi	a1,s1,96
    80001fa2:	8556                	mv	a0,s5
    80001fa4:	00000097          	auipc	ra,0x0
    80001fa8:	640080e7          	jalr	1600(ra) # 800025e4 <swtch>
				c->proc = 0;
    80001fac:	020a3823          	sd	zero,48(s4)
			release(&p->lock);
    80001fb0:	8526                	mv	a0,s1
    80001fb2:	fffff097          	auipc	ra,0xfffff
    80001fb6:	ce6080e7          	jalr	-794(ra) # 80000c98 <release>
		for(p = proc; p < &proc[NPROC]; p++) {
    80001fba:	16848493          	addi	s1,s1,360
    80001fbe:	fd2481e3          	beq	s1,s2,80001f80 <scheduler+0x4c>
			acquire(&p->lock);
    80001fc2:	8526                	mv	a0,s1
    80001fc4:	fffff097          	auipc	ra,0xfffff
    80001fc8:	c20080e7          	jalr	-992(ra) # 80000be4 <acquire>
			if(p->state == RUNNABLE) {
    80001fcc:	4c9c                	lw	a5,24(s1)
    80001fce:	ff3791e3          	bne	a5,s3,80001fb0 <scheduler+0x7c>
    80001fd2:	b7d1                	j	80001f96 <scheduler+0x62>

0000000080001fd4 <sched>:
{
    80001fd4:	7179                	addi	sp,sp,-48
    80001fd6:	f406                	sd	ra,40(sp)
    80001fd8:	f022                	sd	s0,32(sp)
    80001fda:	ec26                	sd	s1,24(sp)
    80001fdc:	e84a                	sd	s2,16(sp)
    80001fde:	e44e                	sd	s3,8(sp)
    80001fe0:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001fe2:	00000097          	auipc	ra,0x0
    80001fe6:	a48080e7          	jalr	-1464(ra) # 80001a2a <myproc>
    80001fea:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001fec:	fffff097          	auipc	ra,0xfffff
    80001ff0:	b7e080e7          	jalr	-1154(ra) # 80000b6a <holding>
    80001ff4:	c93d                	beqz	a0,8000206a <sched+0x96>
	asm volatile("mv %0, tp" : "=r" (x) );
    80001ff6:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80001ff8:	2781                	sext.w	a5,a5
    80001ffa:	079e                	slli	a5,a5,0x7
    80001ffc:	00016717          	auipc	a4,0x16
    80002000:	2a470713          	addi	a4,a4,676 # 800182a0 <pid_lock>
    80002004:	97ba                	add	a5,a5,a4
    80002006:	0a87a703          	lw	a4,168(a5)
    8000200a:	4785                	li	a5,1
    8000200c:	06f71763          	bne	a4,a5,8000207a <sched+0xa6>
  if(p->state == RUNNING)
    80002010:	4c98                	lw	a4,24(s1)
    80002012:	4791                	li	a5,4
    80002014:	06f70b63          	beq	a4,a5,8000208a <sched+0xb6>
	asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002018:	100027f3          	csrr	a5,sstatus
	return (x & SSTATUS_SIE) != 0;
    8000201c:	8b89                	andi	a5,a5,2
  if(intr_get())
    8000201e:	efb5                	bnez	a5,8000209a <sched+0xc6>
	asm volatile("mv %0, tp" : "=r" (x) );
    80002020:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80002022:	00016917          	auipc	s2,0x16
    80002026:	27e90913          	addi	s2,s2,638 # 800182a0 <pid_lock>
    8000202a:	2781                	sext.w	a5,a5
    8000202c:	079e                	slli	a5,a5,0x7
    8000202e:	97ca                	add	a5,a5,s2
    80002030:	0ac7a983          	lw	s3,172(a5)
    80002034:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80002036:	2781                	sext.w	a5,a5
    80002038:	079e                	slli	a5,a5,0x7
    8000203a:	00016597          	auipc	a1,0x16
    8000203e:	29e58593          	addi	a1,a1,670 # 800182d8 <cpus+0x8>
    80002042:	95be                	add	a1,a1,a5
    80002044:	06048513          	addi	a0,s1,96
    80002048:	00000097          	auipc	ra,0x0
    8000204c:	59c080e7          	jalr	1436(ra) # 800025e4 <swtch>
    80002050:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80002052:	2781                	sext.w	a5,a5
    80002054:	079e                	slli	a5,a5,0x7
    80002056:	97ca                	add	a5,a5,s2
    80002058:	0b37a623          	sw	s3,172(a5)
}
    8000205c:	70a2                	ld	ra,40(sp)
    8000205e:	7402                	ld	s0,32(sp)
    80002060:	64e2                	ld	s1,24(sp)
    80002062:	6942                	ld	s2,16(sp)
    80002064:	69a2                	ld	s3,8(sp)
    80002066:	6145                	addi	sp,sp,48
    80002068:	8082                	ret
    panic("sched p->lock");
    8000206a:	00006517          	auipc	a0,0x6
    8000206e:	1b650513          	addi	a0,a0,438 # 80008220 <digits+0x1e0>
    80002072:	ffffe097          	auipc	ra,0xffffe
    80002076:	4cc080e7          	jalr	1228(ra) # 8000053e <panic>
    panic("sched locks");
    8000207a:	00006517          	auipc	a0,0x6
    8000207e:	1b650513          	addi	a0,a0,438 # 80008230 <digits+0x1f0>
    80002082:	ffffe097          	auipc	ra,0xffffe
    80002086:	4bc080e7          	jalr	1212(ra) # 8000053e <panic>
    panic("sched running");
    8000208a:	00006517          	auipc	a0,0x6
    8000208e:	1b650513          	addi	a0,a0,438 # 80008240 <digits+0x200>
    80002092:	ffffe097          	auipc	ra,0xffffe
    80002096:	4ac080e7          	jalr	1196(ra) # 8000053e <panic>
    panic("sched interruptible");
    8000209a:	00006517          	auipc	a0,0x6
    8000209e:	1b650513          	addi	a0,a0,438 # 80008250 <digits+0x210>
    800020a2:	ffffe097          	auipc	ra,0xffffe
    800020a6:	49c080e7          	jalr	1180(ra) # 8000053e <panic>

00000000800020aa <yield>:
{
    800020aa:	1101                	addi	sp,sp,-32
    800020ac:	ec06                	sd	ra,24(sp)
    800020ae:	e822                	sd	s0,16(sp)
    800020b0:	e426                	sd	s1,8(sp)
    800020b2:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    800020b4:	00000097          	auipc	ra,0x0
    800020b8:	976080e7          	jalr	-1674(ra) # 80001a2a <myproc>
    800020bc:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800020be:	fffff097          	auipc	ra,0xfffff
    800020c2:	b26080e7          	jalr	-1242(ra) # 80000be4 <acquire>
  p->state = RUNNABLE;
    800020c6:	478d                	li	a5,3
    800020c8:	cc9c                	sw	a5,24(s1)
  sched();
    800020ca:	00000097          	auipc	ra,0x0
    800020ce:	f0a080e7          	jalr	-246(ra) # 80001fd4 <sched>
  release(&p->lock);
    800020d2:	8526                	mv	a0,s1
    800020d4:	fffff097          	auipc	ra,0xfffff
    800020d8:	bc4080e7          	jalr	-1084(ra) # 80000c98 <release>
}
    800020dc:	60e2                	ld	ra,24(sp)
    800020de:	6442                	ld	s0,16(sp)
    800020e0:	64a2                	ld	s1,8(sp)
    800020e2:	6105                	addi	sp,sp,32
    800020e4:	8082                	ret

00000000800020e6 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    800020e6:	7179                	addi	sp,sp,-48
    800020e8:	f406                	sd	ra,40(sp)
    800020ea:	f022                	sd	s0,32(sp)
    800020ec:	ec26                	sd	s1,24(sp)
    800020ee:	e84a                	sd	s2,16(sp)
    800020f0:	e44e                	sd	s3,8(sp)
    800020f2:	1800                	addi	s0,sp,48
    800020f4:	89aa                	mv	s3,a0
    800020f6:	892e                	mv	s2,a1
	struct proc *p = myproc();
    800020f8:	00000097          	auipc	ra,0x0
    800020fc:	932080e7          	jalr	-1742(ra) # 80001a2a <myproc>
    80002100:	84aa                	mv	s1,a0
	// Once we hold p->lock, we can be
	// guaranteed that we won't miss any wakeup
	// (wakeup locks p->lock),
	// so it's okay to release lk.

	acquire(&p->lock);  //DOC: sleeplock1
    80002102:	fffff097          	auipc	ra,0xfffff
    80002106:	ae2080e7          	jalr	-1310(ra) # 80000be4 <acquire>
	release(lk);
    8000210a:	854a                	mv	a0,s2
    8000210c:	fffff097          	auipc	ra,0xfffff
    80002110:	b8c080e7          	jalr	-1140(ra) # 80000c98 <release>

	// Go to sleep.
	p->chan = chan;
    80002114:	0334b023          	sd	s3,32(s1)
	p->state = SLEEPING;
    80002118:	4789                	li	a5,2
    8000211a:	cc9c                	sw	a5,24(s1)

	sched();
    8000211c:	00000097          	auipc	ra,0x0
    80002120:	eb8080e7          	jalr	-328(ra) # 80001fd4 <sched>

	// Tidy up.
	p->chan = 0;
    80002124:	0204b023          	sd	zero,32(s1)

	// Reacquire original lock.
	release(&p->lock);
    80002128:	8526                	mv	a0,s1
    8000212a:	fffff097          	auipc	ra,0xfffff
    8000212e:	b6e080e7          	jalr	-1170(ra) # 80000c98 <release>
	acquire(lk);
    80002132:	854a                	mv	a0,s2
    80002134:	fffff097          	auipc	ra,0xfffff
    80002138:	ab0080e7          	jalr	-1360(ra) # 80000be4 <acquire>
}
    8000213c:	70a2                	ld	ra,40(sp)
    8000213e:	7402                	ld	s0,32(sp)
    80002140:	64e2                	ld	s1,24(sp)
    80002142:	6942                	ld	s2,16(sp)
    80002144:	69a2                	ld	s3,8(sp)
    80002146:	6145                	addi	sp,sp,48
    80002148:	8082                	ret

000000008000214a <wait>:
{
    8000214a:	715d                	addi	sp,sp,-80
    8000214c:	e486                	sd	ra,72(sp)
    8000214e:	e0a2                	sd	s0,64(sp)
    80002150:	fc26                	sd	s1,56(sp)
    80002152:	f84a                	sd	s2,48(sp)
    80002154:	f44e                	sd	s3,40(sp)
    80002156:	f052                	sd	s4,32(sp)
    80002158:	ec56                	sd	s5,24(sp)
    8000215a:	e85a                	sd	s6,16(sp)
    8000215c:	e45e                	sd	s7,8(sp)
    8000215e:	e062                	sd	s8,0(sp)
    80002160:	0880                	addi	s0,sp,80
    80002162:	8b2a                	mv	s6,a0
	struct proc *p = myproc();
    80002164:	00000097          	auipc	ra,0x0
    80002168:	8c6080e7          	jalr	-1850(ra) # 80001a2a <myproc>
    8000216c:	892a                	mv	s2,a0
	acquire(&wait_lock);
    8000216e:	00016517          	auipc	a0,0x16
    80002172:	14a50513          	addi	a0,a0,330 # 800182b8 <wait_lock>
    80002176:	fffff097          	auipc	ra,0xfffff
    8000217a:	a6e080e7          	jalr	-1426(ra) # 80000be4 <acquire>
		havekids = 0;
    8000217e:	4b81                	li	s7,0
				if(np->state == ZOMBIE){
    80002180:	4a15                	li	s4,5
		for(np = proc; np < &proc[NPROC]; np++){
    80002182:	0001c997          	auipc	s3,0x1c
    80002186:	f4e98993          	addi	s3,s3,-178 # 8001e0d0 <tickslock>
				havekids = 1;
    8000218a:	4a85                	li	s5,1
		sleep(p, &wait_lock);  //DOC: wait-sleep
    8000218c:	00016c17          	auipc	s8,0x16
    80002190:	12cc0c13          	addi	s8,s8,300 # 800182b8 <wait_lock>
		havekids = 0;
    80002194:	875e                	mv	a4,s7
		for(np = proc; np < &proc[NPROC]; np++){
    80002196:	00016497          	auipc	s1,0x16
    8000219a:	53a48493          	addi	s1,s1,1338 # 800186d0 <proc>
    8000219e:	a0bd                	j	8000220c <wait+0xc2>
					pid = np->pid;
    800021a0:	0304a983          	lw	s3,48(s1)
					if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    800021a4:	000b0e63          	beqz	s6,800021c0 <wait+0x76>
    800021a8:	4691                	li	a3,4
    800021aa:	02c48613          	addi	a2,s1,44
    800021ae:	85da                	mv	a1,s6
    800021b0:	05093503          	ld	a0,80(s2)
    800021b4:	fffff097          	auipc	ra,0xfffff
    800021b8:	4bc080e7          	jalr	1212(ra) # 80001670 <copyout>
    800021bc:	02054563          	bltz	a0,800021e6 <wait+0x9c>
					freeproc(np);
    800021c0:	8526                	mv	a0,s1
    800021c2:	00000097          	auipc	ra,0x0
    800021c6:	a1a080e7          	jalr	-1510(ra) # 80001bdc <freeproc>
					release(&np->lock);
    800021ca:	8526                	mv	a0,s1
    800021cc:	fffff097          	auipc	ra,0xfffff
    800021d0:	acc080e7          	jalr	-1332(ra) # 80000c98 <release>
					release(&wait_lock);
    800021d4:	00016517          	auipc	a0,0x16
    800021d8:	0e450513          	addi	a0,a0,228 # 800182b8 <wait_lock>
    800021dc:	fffff097          	auipc	ra,0xfffff
    800021e0:	abc080e7          	jalr	-1348(ra) # 80000c98 <release>
					return pid;
    800021e4:	a09d                	j	8000224a <wait+0x100>
						release(&np->lock);
    800021e6:	8526                	mv	a0,s1
    800021e8:	fffff097          	auipc	ra,0xfffff
    800021ec:	ab0080e7          	jalr	-1360(ra) # 80000c98 <release>
						release(&wait_lock);
    800021f0:	00016517          	auipc	a0,0x16
    800021f4:	0c850513          	addi	a0,a0,200 # 800182b8 <wait_lock>
    800021f8:	fffff097          	auipc	ra,0xfffff
    800021fc:	aa0080e7          	jalr	-1376(ra) # 80000c98 <release>
						return -1;
    80002200:	59fd                	li	s3,-1
    80002202:	a0a1                	j	8000224a <wait+0x100>
		for(np = proc; np < &proc[NPROC]; np++){
    80002204:	16848493          	addi	s1,s1,360
    80002208:	03348463          	beq	s1,s3,80002230 <wait+0xe6>
			if(np->parent == p){
    8000220c:	7c9c                	ld	a5,56(s1)
    8000220e:	ff279be3          	bne	a5,s2,80002204 <wait+0xba>
				acquire(&np->lock);
    80002212:	8526                	mv	a0,s1
    80002214:	fffff097          	auipc	ra,0xfffff
    80002218:	9d0080e7          	jalr	-1584(ra) # 80000be4 <acquire>
				if(np->state == ZOMBIE){
    8000221c:	4c9c                	lw	a5,24(s1)
    8000221e:	f94781e3          	beq	a5,s4,800021a0 <wait+0x56>
				release(&np->lock);
    80002222:	8526                	mv	a0,s1
    80002224:	fffff097          	auipc	ra,0xfffff
    80002228:	a74080e7          	jalr	-1420(ra) # 80000c98 <release>
				havekids = 1;
    8000222c:	8756                	mv	a4,s5
    8000222e:	bfd9                	j	80002204 <wait+0xba>
		if(!havekids || p->killed){
    80002230:	c701                	beqz	a4,80002238 <wait+0xee>
    80002232:	02892783          	lw	a5,40(s2)
    80002236:	c79d                	beqz	a5,80002264 <wait+0x11a>
			release(&wait_lock);
    80002238:	00016517          	auipc	a0,0x16
    8000223c:	08050513          	addi	a0,a0,128 # 800182b8 <wait_lock>
    80002240:	fffff097          	auipc	ra,0xfffff
    80002244:	a58080e7          	jalr	-1448(ra) # 80000c98 <release>
			return -1;
    80002248:	59fd                	li	s3,-1
}
    8000224a:	854e                	mv	a0,s3
    8000224c:	60a6                	ld	ra,72(sp)
    8000224e:	6406                	ld	s0,64(sp)
    80002250:	74e2                	ld	s1,56(sp)
    80002252:	7942                	ld	s2,48(sp)
    80002254:	79a2                	ld	s3,40(sp)
    80002256:	7a02                	ld	s4,32(sp)
    80002258:	6ae2                	ld	s5,24(sp)
    8000225a:	6b42                	ld	s6,16(sp)
    8000225c:	6ba2                	ld	s7,8(sp)
    8000225e:	6c02                	ld	s8,0(sp)
    80002260:	6161                	addi	sp,sp,80
    80002262:	8082                	ret
		sleep(p, &wait_lock);  //DOC: wait-sleep
    80002264:	85e2                	mv	a1,s8
    80002266:	854a                	mv	a0,s2
    80002268:	00000097          	auipc	ra,0x0
    8000226c:	e7e080e7          	jalr	-386(ra) # 800020e6 <sleep>
		havekids = 0;
    80002270:	b715                	j	80002194 <wait+0x4a>

0000000080002272 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    80002272:	7139                	addi	sp,sp,-64
    80002274:	fc06                	sd	ra,56(sp)
    80002276:	f822                	sd	s0,48(sp)
    80002278:	f426                	sd	s1,40(sp)
    8000227a:	f04a                	sd	s2,32(sp)
    8000227c:	ec4e                	sd	s3,24(sp)
    8000227e:	e852                	sd	s4,16(sp)
    80002280:	e456                	sd	s5,8(sp)
    80002282:	0080                	addi	s0,sp,64
    80002284:	8a2a                	mv	s4,a0
	struct proc *p;

	for(p = proc; p < &proc[NPROC]; p++) {
    80002286:	00016497          	auipc	s1,0x16
    8000228a:	44a48493          	addi	s1,s1,1098 # 800186d0 <proc>
		if(p != myproc()){
			acquire(&p->lock);
			if(p->state == SLEEPING && p->chan == chan) {
    8000228e:	4989                	li	s3,2
				p->state = RUNNABLE;
    80002290:	4a8d                	li	s5,3
	for(p = proc; p < &proc[NPROC]; p++) {
    80002292:	0001c917          	auipc	s2,0x1c
    80002296:	e3e90913          	addi	s2,s2,-450 # 8001e0d0 <tickslock>
    8000229a:	a821                	j	800022b2 <wakeup+0x40>
				p->state = RUNNABLE;
    8000229c:	0154ac23          	sw	s5,24(s1)
			}
			release(&p->lock);
    800022a0:	8526                	mv	a0,s1
    800022a2:	fffff097          	auipc	ra,0xfffff
    800022a6:	9f6080e7          	jalr	-1546(ra) # 80000c98 <release>
	for(p = proc; p < &proc[NPROC]; p++) {
    800022aa:	16848493          	addi	s1,s1,360
    800022ae:	03248463          	beq	s1,s2,800022d6 <wakeup+0x64>
		if(p != myproc()){
    800022b2:	fffff097          	auipc	ra,0xfffff
    800022b6:	778080e7          	jalr	1912(ra) # 80001a2a <myproc>
    800022ba:	fea488e3          	beq	s1,a0,800022aa <wakeup+0x38>
			acquire(&p->lock);
    800022be:	8526                	mv	a0,s1
    800022c0:	fffff097          	auipc	ra,0xfffff
    800022c4:	924080e7          	jalr	-1756(ra) # 80000be4 <acquire>
			if(p->state == SLEEPING && p->chan == chan) {
    800022c8:	4c9c                	lw	a5,24(s1)
    800022ca:	fd379be3          	bne	a5,s3,800022a0 <wakeup+0x2e>
    800022ce:	709c                	ld	a5,32(s1)
    800022d0:	fd4798e3          	bne	a5,s4,800022a0 <wakeup+0x2e>
    800022d4:	b7e1                	j	8000229c <wakeup+0x2a>
		}
	}
}
    800022d6:	70e2                	ld	ra,56(sp)
    800022d8:	7442                	ld	s0,48(sp)
    800022da:	74a2                	ld	s1,40(sp)
    800022dc:	7902                	ld	s2,32(sp)
    800022de:	69e2                	ld	s3,24(sp)
    800022e0:	6a42                	ld	s4,16(sp)
    800022e2:	6aa2                	ld	s5,8(sp)
    800022e4:	6121                	addi	sp,sp,64
    800022e6:	8082                	ret

00000000800022e8 <reparent>:
{
    800022e8:	7179                	addi	sp,sp,-48
    800022ea:	f406                	sd	ra,40(sp)
    800022ec:	f022                	sd	s0,32(sp)
    800022ee:	ec26                	sd	s1,24(sp)
    800022f0:	e84a                	sd	s2,16(sp)
    800022f2:	e44e                	sd	s3,8(sp)
    800022f4:	e052                	sd	s4,0(sp)
    800022f6:	1800                	addi	s0,sp,48
    800022f8:	892a                	mv	s2,a0
	for(pp = proc; pp < &proc[NPROC]; pp++){
    800022fa:	00016497          	auipc	s1,0x16
    800022fe:	3d648493          	addi	s1,s1,982 # 800186d0 <proc>
			pp->parent = initproc;
    80002302:	0000ea17          	auipc	s4,0xe
    80002306:	d26a0a13          	addi	s4,s4,-730 # 80010028 <initproc>
	for(pp = proc; pp < &proc[NPROC]; pp++){
    8000230a:	0001c997          	auipc	s3,0x1c
    8000230e:	dc698993          	addi	s3,s3,-570 # 8001e0d0 <tickslock>
    80002312:	a029                	j	8000231c <reparent+0x34>
    80002314:	16848493          	addi	s1,s1,360
    80002318:	01348d63          	beq	s1,s3,80002332 <reparent+0x4a>
		if(pp->parent == p){
    8000231c:	7c9c                	ld	a5,56(s1)
    8000231e:	ff279be3          	bne	a5,s2,80002314 <reparent+0x2c>
			pp->parent = initproc;
    80002322:	000a3503          	ld	a0,0(s4)
    80002326:	fc88                	sd	a0,56(s1)
			wakeup(initproc);
    80002328:	00000097          	auipc	ra,0x0
    8000232c:	f4a080e7          	jalr	-182(ra) # 80002272 <wakeup>
    80002330:	b7d5                	j	80002314 <reparent+0x2c>
}
    80002332:	70a2                	ld	ra,40(sp)
    80002334:	7402                	ld	s0,32(sp)
    80002336:	64e2                	ld	s1,24(sp)
    80002338:	6942                	ld	s2,16(sp)
    8000233a:	69a2                	ld	s3,8(sp)
    8000233c:	6a02                	ld	s4,0(sp)
    8000233e:	6145                	addi	sp,sp,48
    80002340:	8082                	ret

0000000080002342 <exit>:
{
    80002342:	7179                	addi	sp,sp,-48
    80002344:	f406                	sd	ra,40(sp)
    80002346:	f022                	sd	s0,32(sp)
    80002348:	ec26                	sd	s1,24(sp)
    8000234a:	e84a                	sd	s2,16(sp)
    8000234c:	e44e                	sd	s3,8(sp)
    8000234e:	e052                	sd	s4,0(sp)
    80002350:	1800                	addi	s0,sp,48
    80002352:	8a2a                	mv	s4,a0
	struct proc *p = myproc();
    80002354:	fffff097          	auipc	ra,0xfffff
    80002358:	6d6080e7          	jalr	1750(ra) # 80001a2a <myproc>
    8000235c:	89aa                	mv	s3,a0
	if(p == initproc)
    8000235e:	0000e797          	auipc	a5,0xe
    80002362:	cca7b783          	ld	a5,-822(a5) # 80010028 <initproc>
    80002366:	0d050493          	addi	s1,a0,208
    8000236a:	15050913          	addi	s2,a0,336
    8000236e:	02a79363          	bne	a5,a0,80002394 <exit+0x52>
		panic("init exiting");
    80002372:	00006517          	auipc	a0,0x6
    80002376:	ef650513          	addi	a0,a0,-266 # 80008268 <digits+0x228>
    8000237a:	ffffe097          	auipc	ra,0xffffe
    8000237e:	1c4080e7          	jalr	452(ra) # 8000053e <panic>
			fileclose(f);
    80002382:	00002097          	auipc	ra,0x2
    80002386:	164080e7          	jalr	356(ra) # 800044e6 <fileclose>
			p->ofile[fd] = 0;
    8000238a:	0004b023          	sd	zero,0(s1)
	for(int fd = 0; fd < NOFILE; fd++){
    8000238e:	04a1                	addi	s1,s1,8
    80002390:	01248563          	beq	s1,s2,8000239a <exit+0x58>
		if(p->ofile[fd]){
    80002394:	6088                	ld	a0,0(s1)
    80002396:	f575                	bnez	a0,80002382 <exit+0x40>
    80002398:	bfdd                	j	8000238e <exit+0x4c>
	begin_op();
    8000239a:	00002097          	auipc	ra,0x2
    8000239e:	c80080e7          	jalr	-896(ra) # 8000401a <begin_op>
	iput(p->cwd);
    800023a2:	1509b503          	ld	a0,336(s3)
    800023a6:	00001097          	auipc	ra,0x1
    800023aa:	45c080e7          	jalr	1116(ra) # 80003802 <iput>
	end_op();
    800023ae:	00002097          	auipc	ra,0x2
    800023b2:	cec080e7          	jalr	-788(ra) # 8000409a <end_op>
	p->cwd = 0;
    800023b6:	1409b823          	sd	zero,336(s3)
	acquire(&wait_lock);
    800023ba:	00016497          	auipc	s1,0x16
    800023be:	efe48493          	addi	s1,s1,-258 # 800182b8 <wait_lock>
    800023c2:	8526                	mv	a0,s1
    800023c4:	fffff097          	auipc	ra,0xfffff
    800023c8:	820080e7          	jalr	-2016(ra) # 80000be4 <acquire>
	reparent(p);
    800023cc:	854e                	mv	a0,s3
    800023ce:	00000097          	auipc	ra,0x0
    800023d2:	f1a080e7          	jalr	-230(ra) # 800022e8 <reparent>
	wakeup(p->parent);
    800023d6:	0389b503          	ld	a0,56(s3)
    800023da:	00000097          	auipc	ra,0x0
    800023de:	e98080e7          	jalr	-360(ra) # 80002272 <wakeup>
	acquire(&p->lock);
    800023e2:	854e                	mv	a0,s3
    800023e4:	fffff097          	auipc	ra,0xfffff
    800023e8:	800080e7          	jalr	-2048(ra) # 80000be4 <acquire>
	p->xstate = status;
    800023ec:	0349a623          	sw	s4,44(s3)
	p->state = ZOMBIE;
    800023f0:	4795                	li	a5,5
    800023f2:	00f9ac23          	sw	a5,24(s3)
	release(&wait_lock);
    800023f6:	8526                	mv	a0,s1
    800023f8:	fffff097          	auipc	ra,0xfffff
    800023fc:	8a0080e7          	jalr	-1888(ra) # 80000c98 <release>
	sched();
    80002400:	00000097          	auipc	ra,0x0
    80002404:	bd4080e7          	jalr	-1068(ra) # 80001fd4 <sched>
	panic("zombie exit");
    80002408:	00006517          	auipc	a0,0x6
    8000240c:	e7050513          	addi	a0,a0,-400 # 80008278 <digits+0x238>
    80002410:	ffffe097          	auipc	ra,0xffffe
    80002414:	12e080e7          	jalr	302(ra) # 8000053e <panic>

0000000080002418 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    80002418:	7179                	addi	sp,sp,-48
    8000241a:	f406                	sd	ra,40(sp)
    8000241c:	f022                	sd	s0,32(sp)
    8000241e:	ec26                	sd	s1,24(sp)
    80002420:	e84a                	sd	s2,16(sp)
    80002422:	e44e                	sd	s3,8(sp)
    80002424:	1800                	addi	s0,sp,48
    80002426:	892a                	mv	s2,a0
	struct proc *p;

	for(p = proc; p < &proc[NPROC]; p++){
    80002428:	00016497          	auipc	s1,0x16
    8000242c:	2a848493          	addi	s1,s1,680 # 800186d0 <proc>
    80002430:	0001c997          	auipc	s3,0x1c
    80002434:	ca098993          	addi	s3,s3,-864 # 8001e0d0 <tickslock>
		acquire(&p->lock);
    80002438:	8526                	mv	a0,s1
    8000243a:	ffffe097          	auipc	ra,0xffffe
    8000243e:	7aa080e7          	jalr	1962(ra) # 80000be4 <acquire>
		if(p->pid == pid){
    80002442:	589c                	lw	a5,48(s1)
    80002444:	01278d63          	beq	a5,s2,8000245e <kill+0x46>
				p->state = RUNNABLE;
			}
			release(&p->lock);
			return 0;
		}
		release(&p->lock);
    80002448:	8526                	mv	a0,s1
    8000244a:	fffff097          	auipc	ra,0xfffff
    8000244e:	84e080e7          	jalr	-1970(ra) # 80000c98 <release>
	for(p = proc; p < &proc[NPROC]; p++){
    80002452:	16848493          	addi	s1,s1,360
    80002456:	ff3491e3          	bne	s1,s3,80002438 <kill+0x20>
	}
	return -1;
    8000245a:	557d                	li	a0,-1
    8000245c:	a829                	j	80002476 <kill+0x5e>
			p->killed = 1;
    8000245e:	4785                	li	a5,1
    80002460:	d49c                	sw	a5,40(s1)
			if(p->state == SLEEPING){
    80002462:	4c98                	lw	a4,24(s1)
    80002464:	4789                	li	a5,2
    80002466:	00f70f63          	beq	a4,a5,80002484 <kill+0x6c>
			release(&p->lock);
    8000246a:	8526                	mv	a0,s1
    8000246c:	fffff097          	auipc	ra,0xfffff
    80002470:	82c080e7          	jalr	-2004(ra) # 80000c98 <release>
			return 0;
    80002474:	4501                	li	a0,0
}
    80002476:	70a2                	ld	ra,40(sp)
    80002478:	7402                	ld	s0,32(sp)
    8000247a:	64e2                	ld	s1,24(sp)
    8000247c:	6942                	ld	s2,16(sp)
    8000247e:	69a2                	ld	s3,8(sp)
    80002480:	6145                	addi	sp,sp,48
    80002482:	8082                	ret
				p->state = RUNNABLE;
    80002484:	478d                	li	a5,3
    80002486:	cc9c                	sw	a5,24(s1)
    80002488:	b7cd                	j	8000246a <kill+0x52>

000000008000248a <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    8000248a:	7179                	addi	sp,sp,-48
    8000248c:	f406                	sd	ra,40(sp)
    8000248e:	f022                	sd	s0,32(sp)
    80002490:	ec26                	sd	s1,24(sp)
    80002492:	e84a                	sd	s2,16(sp)
    80002494:	e44e                	sd	s3,8(sp)
    80002496:	e052                	sd	s4,0(sp)
    80002498:	1800                	addi	s0,sp,48
    8000249a:	84aa                	mv	s1,a0
    8000249c:	892e                	mv	s2,a1
    8000249e:	89b2                	mv	s3,a2
    800024a0:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800024a2:	fffff097          	auipc	ra,0xfffff
    800024a6:	588080e7          	jalr	1416(ra) # 80001a2a <myproc>
  if(user_dst){
    800024aa:	c08d                	beqz	s1,800024cc <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    800024ac:	86d2                	mv	a3,s4
    800024ae:	864e                	mv	a2,s3
    800024b0:	85ca                	mv	a1,s2
    800024b2:	6928                	ld	a0,80(a0)
    800024b4:	fffff097          	auipc	ra,0xfffff
    800024b8:	1bc080e7          	jalr	444(ra) # 80001670 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    800024bc:	70a2                	ld	ra,40(sp)
    800024be:	7402                	ld	s0,32(sp)
    800024c0:	64e2                	ld	s1,24(sp)
    800024c2:	6942                	ld	s2,16(sp)
    800024c4:	69a2                	ld	s3,8(sp)
    800024c6:	6a02                	ld	s4,0(sp)
    800024c8:	6145                	addi	sp,sp,48
    800024ca:	8082                	ret
    memmove((char *)dst, src, len);
    800024cc:	000a061b          	sext.w	a2,s4
    800024d0:	85ce                	mv	a1,s3
    800024d2:	854a                	mv	a0,s2
    800024d4:	fffff097          	auipc	ra,0xfffff
    800024d8:	86c080e7          	jalr	-1940(ra) # 80000d40 <memmove>
    return 0;
    800024dc:	8526                	mv	a0,s1
    800024de:	bff9                	j	800024bc <either_copyout+0x32>

00000000800024e0 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800024e0:	7179                	addi	sp,sp,-48
    800024e2:	f406                	sd	ra,40(sp)
    800024e4:	f022                	sd	s0,32(sp)
    800024e6:	ec26                	sd	s1,24(sp)
    800024e8:	e84a                	sd	s2,16(sp)
    800024ea:	e44e                	sd	s3,8(sp)
    800024ec:	e052                	sd	s4,0(sp)
    800024ee:	1800                	addi	s0,sp,48
    800024f0:	892a                	mv	s2,a0
    800024f2:	84ae                	mv	s1,a1
    800024f4:	89b2                	mv	s3,a2
    800024f6:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800024f8:	fffff097          	auipc	ra,0xfffff
    800024fc:	532080e7          	jalr	1330(ra) # 80001a2a <myproc>
  if(user_src){
    80002500:	c08d                	beqz	s1,80002522 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    80002502:	86d2                	mv	a3,s4
    80002504:	864e                	mv	a2,s3
    80002506:	85ca                	mv	a1,s2
    80002508:	6928                	ld	a0,80(a0)
    8000250a:	fffff097          	auipc	ra,0xfffff
    8000250e:	1f2080e7          	jalr	498(ra) # 800016fc <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80002512:	70a2                	ld	ra,40(sp)
    80002514:	7402                	ld	s0,32(sp)
    80002516:	64e2                	ld	s1,24(sp)
    80002518:	6942                	ld	s2,16(sp)
    8000251a:	69a2                	ld	s3,8(sp)
    8000251c:	6a02                	ld	s4,0(sp)
    8000251e:	6145                	addi	sp,sp,48
    80002520:	8082                	ret
    memmove(dst, (char*)src, len);
    80002522:	000a061b          	sext.w	a2,s4
    80002526:	85ce                	mv	a1,s3
    80002528:	854a                	mv	a0,s2
    8000252a:	fffff097          	auipc	ra,0xfffff
    8000252e:	816080e7          	jalr	-2026(ra) # 80000d40 <memmove>
    return 0;
    80002532:	8526                	mv	a0,s1
    80002534:	bff9                	j	80002512 <either_copyin+0x32>

0000000080002536 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    80002536:	715d                	addi	sp,sp,-80
    80002538:	e486                	sd	ra,72(sp)
    8000253a:	e0a2                	sd	s0,64(sp)
    8000253c:	fc26                	sd	s1,56(sp)
    8000253e:	f84a                	sd	s2,48(sp)
    80002540:	f44e                	sd	s3,40(sp)
    80002542:	f052                	sd	s4,32(sp)
    80002544:	ec56                	sd	s5,24(sp)
    80002546:	e85a                	sd	s6,16(sp)
    80002548:	e45e                	sd	s7,8(sp)
    8000254a:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    8000254c:	00006517          	auipc	a0,0x6
    80002550:	b7c50513          	addi	a0,a0,-1156 # 800080c8 <digits+0x88>
    80002554:	ffffe097          	auipc	ra,0xffffe
    80002558:	034080e7          	jalr	52(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    8000255c:	00016497          	auipc	s1,0x16
    80002560:	2cc48493          	addi	s1,s1,716 # 80018828 <proc+0x158>
    80002564:	0001c917          	auipc	s2,0x1c
    80002568:	cc490913          	addi	s2,s2,-828 # 8001e228 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000256c:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    8000256e:	00006997          	auipc	s3,0x6
    80002572:	d1a98993          	addi	s3,s3,-742 # 80008288 <digits+0x248>
    printf("%d %s %s", p->pid, state, p->name);
    80002576:	00006a97          	auipc	s5,0x6
    8000257a:	d1aa8a93          	addi	s5,s5,-742 # 80008290 <digits+0x250>
    printf("\n");
    8000257e:	00006a17          	auipc	s4,0x6
    80002582:	b4aa0a13          	addi	s4,s4,-1206 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002586:	00006b97          	auipc	s7,0x6
    8000258a:	d42b8b93          	addi	s7,s7,-702 # 800082c8 <states.1713>
    8000258e:	a00d                	j	800025b0 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002590:	ed86a583          	lw	a1,-296(a3)
    80002594:	8556                	mv	a0,s5
    80002596:	ffffe097          	auipc	ra,0xffffe
    8000259a:	ff2080e7          	jalr	-14(ra) # 80000588 <printf>
    printf("\n");
    8000259e:	8552                	mv	a0,s4
    800025a0:	ffffe097          	auipc	ra,0xffffe
    800025a4:	fe8080e7          	jalr	-24(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800025a8:	16848493          	addi	s1,s1,360
    800025ac:	03248163          	beq	s1,s2,800025ce <procdump+0x98>
    if(p->state == UNUSED)
    800025b0:	86a6                	mv	a3,s1
    800025b2:	ec04a783          	lw	a5,-320(s1)
    800025b6:	dbed                	beqz	a5,800025a8 <procdump+0x72>
      state = "???";
    800025b8:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800025ba:	fcfb6be3          	bltu	s6,a5,80002590 <procdump+0x5a>
    800025be:	1782                	slli	a5,a5,0x20
    800025c0:	9381                	srli	a5,a5,0x20
    800025c2:	078e                	slli	a5,a5,0x3
    800025c4:	97de                	add	a5,a5,s7
    800025c6:	6390                	ld	a2,0(a5)
    800025c8:	f661                	bnez	a2,80002590 <procdump+0x5a>
      state = "???";
    800025ca:	864e                	mv	a2,s3
    800025cc:	b7d1                	j	80002590 <procdump+0x5a>
  }
}
    800025ce:	60a6                	ld	ra,72(sp)
    800025d0:	6406                	ld	s0,64(sp)
    800025d2:	74e2                	ld	s1,56(sp)
    800025d4:	7942                	ld	s2,48(sp)
    800025d6:	79a2                	ld	s3,40(sp)
    800025d8:	7a02                	ld	s4,32(sp)
    800025da:	6ae2                	ld	s5,24(sp)
    800025dc:	6b42                	ld	s6,16(sp)
    800025de:	6ba2                	ld	s7,8(sp)
    800025e0:	6161                	addi	sp,sp,80
    800025e2:	8082                	ret

00000000800025e4 <swtch>:
    800025e4:	00153023          	sd	ra,0(a0)
    800025e8:	00253423          	sd	sp,8(a0)
    800025ec:	e900                	sd	s0,16(a0)
    800025ee:	ed04                	sd	s1,24(a0)
    800025f0:	03253023          	sd	s2,32(a0)
    800025f4:	03353423          	sd	s3,40(a0)
    800025f8:	03453823          	sd	s4,48(a0)
    800025fc:	03553c23          	sd	s5,56(a0)
    80002600:	05653023          	sd	s6,64(a0)
    80002604:	05753423          	sd	s7,72(a0)
    80002608:	05853823          	sd	s8,80(a0)
    8000260c:	05953c23          	sd	s9,88(a0)
    80002610:	07a53023          	sd	s10,96(a0)
    80002614:	07b53423          	sd	s11,104(a0)
    80002618:	0005b083          	ld	ra,0(a1)
    8000261c:	0085b103          	ld	sp,8(a1)
    80002620:	6980                	ld	s0,16(a1)
    80002622:	6d84                	ld	s1,24(a1)
    80002624:	0205b903          	ld	s2,32(a1)
    80002628:	0285b983          	ld	s3,40(a1)
    8000262c:	0305ba03          	ld	s4,48(a1)
    80002630:	0385ba83          	ld	s5,56(a1)
    80002634:	0405bb03          	ld	s6,64(a1)
    80002638:	0485bb83          	ld	s7,72(a1)
    8000263c:	0505bc03          	ld	s8,80(a1)
    80002640:	0585bc83          	ld	s9,88(a1)
    80002644:	0605bd03          	ld	s10,96(a1)
    80002648:	0685bd83          	ld	s11,104(a1)
    8000264c:	8082                	ret

000000008000264e <trapinit>:

extern int devintr();

void
trapinit(void)
{
    8000264e:	1141                	addi	sp,sp,-16
    80002650:	e406                	sd	ra,8(sp)
    80002652:	e022                	sd	s0,0(sp)
    80002654:	0800                	addi	s0,sp,16
	initlock(&tickslock, "time");
    80002656:	00006597          	auipc	a1,0x6
    8000265a:	ca258593          	addi	a1,a1,-862 # 800082f8 <states.1713+0x30>
    8000265e:	0001c517          	auipc	a0,0x1c
    80002662:	a7250513          	addi	a0,a0,-1422 # 8001e0d0 <tickslock>
    80002666:	ffffe097          	auipc	ra,0xffffe
    8000266a:	4ee080e7          	jalr	1262(ra) # 80000b54 <initlock>
}
    8000266e:	60a2                	ld	ra,8(sp)
    80002670:	6402                	ld	s0,0(sp)
    80002672:	0141                	addi	sp,sp,16
    80002674:	8082                	ret

0000000080002676 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002676:	1141                	addi	sp,sp,-16
    80002678:	e422                	sd	s0,8(sp)
    8000267a:	0800                	addi	s0,sp,16
	asm volatile("csrw stvec, %0" : : "r" (x));
    8000267c:	00003797          	auipc	a5,0x3
    80002680:	48478793          	addi	a5,a5,1156 # 80005b00 <kernelvec>
    80002684:	10579073          	csrw	stvec,a5
	w_stvec((uint64)kernelvec);
}
    80002688:	6422                	ld	s0,8(sp)
    8000268a:	0141                	addi	sp,sp,16
    8000268c:	8082                	ret

000000008000268e <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    8000268e:	1141                	addi	sp,sp,-16
    80002690:	e406                	sd	ra,8(sp)
    80002692:	e022                	sd	s0,0(sp)
    80002694:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002696:	fffff097          	auipc	ra,0xfffff
    8000269a:	394080e7          	jalr	916(ra) # 80001a2a <myproc>
	asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000269e:	100027f3          	csrr	a5,sstatus
	w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    800026a2:	9bf5                	andi	a5,a5,-3
	asm volatile("csrw sstatus, %0" : : "r" (x));
    800026a4:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    800026a8:	00005617          	auipc	a2,0x5
    800026ac:	95860613          	addi	a2,a2,-1704 # 80007000 <_trampoline>
    800026b0:	00005697          	auipc	a3,0x5
    800026b4:	95068693          	addi	a3,a3,-1712 # 80007000 <_trampoline>
    800026b8:	8e91                	sub	a3,a3,a2
    800026ba:	008007b7          	lui	a5,0x800
    800026be:	17fd                	addi	a5,a5,-1
    800026c0:	07be                	slli	a5,a5,0xf
    800026c2:	96be                	add	a3,a3,a5
	asm volatile("csrw stvec, %0" : : "r" (x));
    800026c4:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    800026c8:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    800026ca:	180026f3          	csrr	a3,satp
    800026ce:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    800026d0:	6d38                	ld	a4,88(a0)
    800026d2:	6134                	ld	a3,64(a0)
    800026d4:	65a1                	lui	a1,0x8
    800026d6:	96ae                	add	a3,a3,a1
    800026d8:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    800026da:	6d38                	ld	a4,88(a0)
    800026dc:	00000697          	auipc	a3,0x0
    800026e0:	13868693          	addi	a3,a3,312 # 80002814 <usertrap>
    800026e4:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    800026e6:	6d38                	ld	a4,88(a0)
	asm volatile("mv %0, tp" : "=r" (x) );
    800026e8:	8692                	mv	a3,tp
    800026ea:	f314                	sd	a3,32(a4)
	asm volatile("csrr %0, sstatus" : "=r" (x) );
    800026ec:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    800026f0:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    800026f4:	0206e693          	ori	a3,a3,32
	asm volatile("csrw sstatus, %0" : : "r" (x));
    800026f8:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    800026fc:	6d38                	ld	a4,88(a0)
	asm volatile("csrw sepc, %0" : : "r" (x));
    800026fe:	6f18                	ld	a4,24(a4)
    80002700:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002704:	692c                	ld	a1,80(a0)
    80002706:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002708:	00005717          	auipc	a4,0x5
    8000270c:	98870713          	addi	a4,a4,-1656 # 80007090 <userret>
    80002710:	8f11                	sub	a4,a4,a2
    80002712:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80002714:	577d                	li	a4,-1
    80002716:	177e                	slli	a4,a4,0x3f
    80002718:	8dd9                	or	a1,a1,a4
    8000271a:	00400537          	lui	a0,0x400
    8000271e:	157d                	addi	a0,a0,-1
    80002720:	0542                	slli	a0,a0,0x10
    80002722:	9782                	jalr	a5
}
    80002724:	60a2                	ld	ra,8(sp)
    80002726:	6402                	ld	s0,0(sp)
    80002728:	0141                	addi	sp,sp,16
    8000272a:	8082                	ret

000000008000272c <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    8000272c:	1101                	addi	sp,sp,-32
    8000272e:	ec06                	sd	ra,24(sp)
    80002730:	e822                	sd	s0,16(sp)
    80002732:	e426                	sd	s1,8(sp)
    80002734:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002736:	0001c497          	auipc	s1,0x1c
    8000273a:	99a48493          	addi	s1,s1,-1638 # 8001e0d0 <tickslock>
    8000273e:	8526                	mv	a0,s1
    80002740:	ffffe097          	auipc	ra,0xffffe
    80002744:	4a4080e7          	jalr	1188(ra) # 80000be4 <acquire>
  ticks++;
    80002748:	0000e517          	auipc	a0,0xe
    8000274c:	8e850513          	addi	a0,a0,-1816 # 80010030 <ticks>
    80002750:	411c                	lw	a5,0(a0)
    80002752:	2785                	addiw	a5,a5,1
    80002754:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002756:	00000097          	auipc	ra,0x0
    8000275a:	b1c080e7          	jalr	-1252(ra) # 80002272 <wakeup>
  release(&tickslock);
    8000275e:	8526                	mv	a0,s1
    80002760:	ffffe097          	auipc	ra,0xffffe
    80002764:	538080e7          	jalr	1336(ra) # 80000c98 <release>
}
    80002768:	60e2                	ld	ra,24(sp)
    8000276a:	6442                	ld	s0,16(sp)
    8000276c:	64a2                	ld	s1,8(sp)
    8000276e:	6105                	addi	sp,sp,32
    80002770:	8082                	ret

0000000080002772 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002772:	1101                	addi	sp,sp,-32
    80002774:	ec06                	sd	ra,24(sp)
    80002776:	e822                	sd	s0,16(sp)
    80002778:	e426                	sd	s1,8(sp)
    8000277a:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000277c:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002780:	00074d63          	bltz	a4,8000279a <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002784:	57fd                	li	a5,-1
    80002786:	17fe                	slli	a5,a5,0x3f
    80002788:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    8000278a:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    8000278c:	06f70363          	beq	a4,a5,800027f2 <devintr+0x80>
  }
}
    80002790:	60e2                	ld	ra,24(sp)
    80002792:	6442                	ld	s0,16(sp)
    80002794:	64a2                	ld	s1,8(sp)
    80002796:	6105                	addi	sp,sp,32
    80002798:	8082                	ret
     (scause & 0xff) == 9){
    8000279a:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    8000279e:	46a5                	li	a3,9
    800027a0:	fed792e3          	bne	a5,a3,80002784 <devintr+0x12>
    int irq = plic_claim();
    800027a4:	00003097          	auipc	ra,0x3
    800027a8:	464080e7          	jalr	1124(ra) # 80005c08 <plic_claim>
    800027ac:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    800027ae:	47a9                	li	a5,10
    800027b0:	02f50763          	beq	a0,a5,800027de <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    800027b4:	4785                	li	a5,1
    800027b6:	02f50963          	beq	a0,a5,800027e8 <devintr+0x76>
    return 1;
    800027ba:	4505                	li	a0,1
    } else if(irq){
    800027bc:	d8f1                	beqz	s1,80002790 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    800027be:	85a6                	mv	a1,s1
    800027c0:	00006517          	auipc	a0,0x6
    800027c4:	b4050513          	addi	a0,a0,-1216 # 80008300 <states.1713+0x38>
    800027c8:	ffffe097          	auipc	ra,0xffffe
    800027cc:	dc0080e7          	jalr	-576(ra) # 80000588 <printf>
      plic_complete(irq);
    800027d0:	8526                	mv	a0,s1
    800027d2:	00003097          	auipc	ra,0x3
    800027d6:	45a080e7          	jalr	1114(ra) # 80005c2c <plic_complete>
    return 1;
    800027da:	4505                	li	a0,1
    800027dc:	bf55                	j	80002790 <devintr+0x1e>
      uartintr();
    800027de:	ffffe097          	auipc	ra,0xffffe
    800027e2:	1ca080e7          	jalr	458(ra) # 800009a8 <uartintr>
    800027e6:	b7ed                	j	800027d0 <devintr+0x5e>
      virtio_disk_intr();
    800027e8:	00004097          	auipc	ra,0x4
    800027ec:	91a080e7          	jalr	-1766(ra) # 80006102 <virtio_disk_intr>
    800027f0:	b7c5                	j	800027d0 <devintr+0x5e>
    if(cpuid() == 0){
    800027f2:	fffff097          	auipc	ra,0xfffff
    800027f6:	20c080e7          	jalr	524(ra) # 800019fe <cpuid>
    800027fa:	c901                	beqz	a0,8000280a <devintr+0x98>
	asm volatile("csrr %0, sip" : "=r" (x) );
    800027fc:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002800:	9bf5                	andi	a5,a5,-3
	asm volatile("csrw sip, %0" : : "r" (x));
    80002802:	14479073          	csrw	sip,a5
    return 2;
    80002806:	4509                	li	a0,2
    80002808:	b761                	j	80002790 <devintr+0x1e>
      clockintr();
    8000280a:	00000097          	auipc	ra,0x0
    8000280e:	f22080e7          	jalr	-222(ra) # 8000272c <clockintr>
    80002812:	b7ed                	j	800027fc <devintr+0x8a>

0000000080002814 <usertrap>:
{
    80002814:	1101                	addi	sp,sp,-32
    80002816:	ec06                	sd	ra,24(sp)
    80002818:	e822                	sd	s0,16(sp)
    8000281a:	e426                	sd	s1,8(sp)
    8000281c:	e04a                	sd	s2,0(sp)
    8000281e:	1000                	addi	s0,sp,32
	asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002820:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002824:	1007f793          	andi	a5,a5,256
    80002828:	e3ad                	bnez	a5,8000288a <usertrap+0x76>
	asm volatile("csrw stvec, %0" : : "r" (x));
    8000282a:	00003797          	auipc	a5,0x3
    8000282e:	2d678793          	addi	a5,a5,726 # 80005b00 <kernelvec>
    80002832:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002836:	fffff097          	auipc	ra,0xfffff
    8000283a:	1f4080e7          	jalr	500(ra) # 80001a2a <myproc>
    8000283e:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002840:	6d3c                	ld	a5,88(a0)
	asm volatile("csrr %0, sepc" : "=r" (x) );
    80002842:	14102773          	csrr	a4,sepc
    80002846:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002848:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    8000284c:	47a1                	li	a5,8
    8000284e:	04f71c63          	bne	a4,a5,800028a6 <usertrap+0x92>
    if(p->killed)
    80002852:	551c                	lw	a5,40(a0)
    80002854:	e3b9                	bnez	a5,8000289a <usertrap+0x86>
    p->trapframe->epc += 4;
    80002856:	6cb8                	ld	a4,88(s1)
    80002858:	6f1c                	ld	a5,24(a4)
    8000285a:	0791                	addi	a5,a5,4
    8000285c:	ef1c                	sd	a5,24(a4)
	asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000285e:	100027f3          	csrr	a5,sstatus
	w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002862:	0027e793          	ori	a5,a5,2
	asm volatile("csrw sstatus, %0" : : "r" (x));
    80002866:	10079073          	csrw	sstatus,a5
    syscall();
    8000286a:	00000097          	auipc	ra,0x0
    8000286e:	2e0080e7          	jalr	736(ra) # 80002b4a <syscall>
  if(p->killed)
    80002872:	549c                	lw	a5,40(s1)
    80002874:	ebc1                	bnez	a5,80002904 <usertrap+0xf0>
  usertrapret();
    80002876:	00000097          	auipc	ra,0x0
    8000287a:	e18080e7          	jalr	-488(ra) # 8000268e <usertrapret>
}
    8000287e:	60e2                	ld	ra,24(sp)
    80002880:	6442                	ld	s0,16(sp)
    80002882:	64a2                	ld	s1,8(sp)
    80002884:	6902                	ld	s2,0(sp)
    80002886:	6105                	addi	sp,sp,32
    80002888:	8082                	ret
    panic("usertrap: not from user mode");
    8000288a:	00006517          	auipc	a0,0x6
    8000288e:	a9650513          	addi	a0,a0,-1386 # 80008320 <states.1713+0x58>
    80002892:	ffffe097          	auipc	ra,0xffffe
    80002896:	cac080e7          	jalr	-852(ra) # 8000053e <panic>
      exit(-1);
    8000289a:	557d                	li	a0,-1
    8000289c:	00000097          	auipc	ra,0x0
    800028a0:	aa6080e7          	jalr	-1370(ra) # 80002342 <exit>
    800028a4:	bf4d                	j	80002856 <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    800028a6:	00000097          	auipc	ra,0x0
    800028aa:	ecc080e7          	jalr	-308(ra) # 80002772 <devintr>
    800028ae:	892a                	mv	s2,a0
    800028b0:	c501                	beqz	a0,800028b8 <usertrap+0xa4>
  if(p->killed)
    800028b2:	549c                	lw	a5,40(s1)
    800028b4:	c3a1                	beqz	a5,800028f4 <usertrap+0xe0>
    800028b6:	a815                	j	800028ea <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    800028b8:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    800028bc:	5890                	lw	a2,48(s1)
    800028be:	00006517          	auipc	a0,0x6
    800028c2:	a8250513          	addi	a0,a0,-1406 # 80008340 <states.1713+0x78>
    800028c6:	ffffe097          	auipc	ra,0xffffe
    800028ca:	cc2080e7          	jalr	-830(ra) # 80000588 <printf>
	asm volatile("csrr %0, sepc" : "=r" (x) );
    800028ce:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    800028d2:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    800028d6:	00006517          	auipc	a0,0x6
    800028da:	a9a50513          	addi	a0,a0,-1382 # 80008370 <states.1713+0xa8>
    800028de:	ffffe097          	auipc	ra,0xffffe
    800028e2:	caa080e7          	jalr	-854(ra) # 80000588 <printf>
    p->killed = 1;
    800028e6:	4785                	li	a5,1
    800028e8:	d49c                	sw	a5,40(s1)
    exit(-1);
    800028ea:	557d                	li	a0,-1
    800028ec:	00000097          	auipc	ra,0x0
    800028f0:	a56080e7          	jalr	-1450(ra) # 80002342 <exit>
  if(which_dev == 2)
    800028f4:	4789                	li	a5,2
    800028f6:	f8f910e3          	bne	s2,a5,80002876 <usertrap+0x62>
    yield();
    800028fa:	fffff097          	auipc	ra,0xfffff
    800028fe:	7b0080e7          	jalr	1968(ra) # 800020aa <yield>
    80002902:	bf95                	j	80002876 <usertrap+0x62>
  int which_dev = 0;
    80002904:	4901                	li	s2,0
    80002906:	b7d5                	j	800028ea <usertrap+0xd6>

0000000080002908 <kerneltrap>:
{
    80002908:	7179                	addi	sp,sp,-48
    8000290a:	f406                	sd	ra,40(sp)
    8000290c:	f022                	sd	s0,32(sp)
    8000290e:	ec26                	sd	s1,24(sp)
    80002910:	e84a                	sd	s2,16(sp)
    80002912:	e44e                	sd	s3,8(sp)
    80002914:	1800                	addi	s0,sp,48
	asm volatile("csrr %0, sepc" : "=r" (x) );
    80002916:	14102973          	csrr	s2,sepc
	asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000291a:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000291e:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002922:	1004f793          	andi	a5,s1,256
    80002926:	cb85                	beqz	a5,80002956 <kerneltrap+0x4e>
	asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002928:	100027f3          	csrr	a5,sstatus
	return (x & SSTATUS_SIE) != 0;
    8000292c:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    8000292e:	ef85                	bnez	a5,80002966 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002930:	00000097          	auipc	ra,0x0
    80002934:	e42080e7          	jalr	-446(ra) # 80002772 <devintr>
    80002938:	cd1d                	beqz	a0,80002976 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    8000293a:	4789                	li	a5,2
    8000293c:	06f50a63          	beq	a0,a5,800029b0 <kerneltrap+0xa8>
	asm volatile("csrw sepc, %0" : : "r" (x));
    80002940:	14191073          	csrw	sepc,s2
	asm volatile("csrw sstatus, %0" : : "r" (x));
    80002944:	10049073          	csrw	sstatus,s1
}
    80002948:	70a2                	ld	ra,40(sp)
    8000294a:	7402                	ld	s0,32(sp)
    8000294c:	64e2                	ld	s1,24(sp)
    8000294e:	6942                	ld	s2,16(sp)
    80002950:	69a2                	ld	s3,8(sp)
    80002952:	6145                	addi	sp,sp,48
    80002954:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002956:	00006517          	auipc	a0,0x6
    8000295a:	a3a50513          	addi	a0,a0,-1478 # 80008390 <states.1713+0xc8>
    8000295e:	ffffe097          	auipc	ra,0xffffe
    80002962:	be0080e7          	jalr	-1056(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    80002966:	00006517          	auipc	a0,0x6
    8000296a:	a5250513          	addi	a0,a0,-1454 # 800083b8 <states.1713+0xf0>
    8000296e:	ffffe097          	auipc	ra,0xffffe
    80002972:	bd0080e7          	jalr	-1072(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    80002976:	85ce                	mv	a1,s3
    80002978:	00006517          	auipc	a0,0x6
    8000297c:	a6050513          	addi	a0,a0,-1440 # 800083d8 <states.1713+0x110>
    80002980:	ffffe097          	auipc	ra,0xffffe
    80002984:	c08080e7          	jalr	-1016(ra) # 80000588 <printf>
	asm volatile("csrr %0, sepc" : "=r" (x) );
    80002988:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    8000298c:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002990:	00006517          	auipc	a0,0x6
    80002994:	a5850513          	addi	a0,a0,-1448 # 800083e8 <states.1713+0x120>
    80002998:	ffffe097          	auipc	ra,0xffffe
    8000299c:	bf0080e7          	jalr	-1040(ra) # 80000588 <printf>
    panic("kerneltrap");
    800029a0:	00006517          	auipc	a0,0x6
    800029a4:	a6050513          	addi	a0,a0,-1440 # 80008400 <states.1713+0x138>
    800029a8:	ffffe097          	auipc	ra,0xffffe
    800029ac:	b96080e7          	jalr	-1130(ra) # 8000053e <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    800029b0:	fffff097          	auipc	ra,0xfffff
    800029b4:	07a080e7          	jalr	122(ra) # 80001a2a <myproc>
    800029b8:	d541                	beqz	a0,80002940 <kerneltrap+0x38>
    800029ba:	fffff097          	auipc	ra,0xfffff
    800029be:	070080e7          	jalr	112(ra) # 80001a2a <myproc>
    800029c2:	4d18                	lw	a4,24(a0)
    800029c4:	4791                	li	a5,4
    800029c6:	f6f71de3          	bne	a4,a5,80002940 <kerneltrap+0x38>
    yield();
    800029ca:	fffff097          	auipc	ra,0xfffff
    800029ce:	6e0080e7          	jalr	1760(ra) # 800020aa <yield>
    800029d2:	b7bd                	j	80002940 <kerneltrap+0x38>

00000000800029d4 <argraw>:
	return strlen(buf);
}

static uint64
argraw(int n)
{
    800029d4:	1101                	addi	sp,sp,-32
    800029d6:	ec06                	sd	ra,24(sp)
    800029d8:	e822                	sd	s0,16(sp)
    800029da:	e426                	sd	s1,8(sp)
    800029dc:	1000                	addi	s0,sp,32
    800029de:	84aa                	mv	s1,a0
	struct proc *p = myproc();
    800029e0:	fffff097          	auipc	ra,0xfffff
    800029e4:	04a080e7          	jalr	74(ra) # 80001a2a <myproc>
	switch (n) {
    800029e8:	4795                	li	a5,5
    800029ea:	0497e163          	bltu	a5,s1,80002a2c <argraw+0x58>
    800029ee:	048a                	slli	s1,s1,0x2
    800029f0:	00006717          	auipc	a4,0x6
    800029f4:	a4870713          	addi	a4,a4,-1464 # 80008438 <states.1713+0x170>
    800029f8:	94ba                	add	s1,s1,a4
    800029fa:	409c                	lw	a5,0(s1)
    800029fc:	97ba                	add	a5,a5,a4
    800029fe:	8782                	jr	a5
	case 0:
		return p->trapframe->a0;
    80002a00:	6d3c                	ld	a5,88(a0)
    80002a02:	7ba8                	ld	a0,112(a5)
	case 5:
		return p->trapframe->a5;
	}
	panic("argraw");
	return -1;
}
    80002a04:	60e2                	ld	ra,24(sp)
    80002a06:	6442                	ld	s0,16(sp)
    80002a08:	64a2                	ld	s1,8(sp)
    80002a0a:	6105                	addi	sp,sp,32
    80002a0c:	8082                	ret
		return p->trapframe->a1;
    80002a0e:	6d3c                	ld	a5,88(a0)
    80002a10:	7fa8                	ld	a0,120(a5)
    80002a12:	bfcd                	j	80002a04 <argraw+0x30>
		return p->trapframe->a2;
    80002a14:	6d3c                	ld	a5,88(a0)
    80002a16:	63c8                	ld	a0,128(a5)
    80002a18:	b7f5                	j	80002a04 <argraw+0x30>
		return p->trapframe->a3;
    80002a1a:	6d3c                	ld	a5,88(a0)
    80002a1c:	67c8                	ld	a0,136(a5)
    80002a1e:	b7dd                	j	80002a04 <argraw+0x30>
		return p->trapframe->a4;
    80002a20:	6d3c                	ld	a5,88(a0)
    80002a22:	6bc8                	ld	a0,144(a5)
    80002a24:	b7c5                	j	80002a04 <argraw+0x30>
		return p->trapframe->a5;
    80002a26:	6d3c                	ld	a5,88(a0)
    80002a28:	6fc8                	ld	a0,152(a5)
    80002a2a:	bfe9                	j	80002a04 <argraw+0x30>
	panic("argraw");
    80002a2c:	00006517          	auipc	a0,0x6
    80002a30:	9e450513          	addi	a0,a0,-1564 # 80008410 <states.1713+0x148>
    80002a34:	ffffe097          	auipc	ra,0xffffe
    80002a38:	b0a080e7          	jalr	-1270(ra) # 8000053e <panic>

0000000080002a3c <fetchaddr>:
{
    80002a3c:	1101                	addi	sp,sp,-32
    80002a3e:	ec06                	sd	ra,24(sp)
    80002a40:	e822                	sd	s0,16(sp)
    80002a42:	e426                	sd	s1,8(sp)
    80002a44:	e04a                	sd	s2,0(sp)
    80002a46:	1000                	addi	s0,sp,32
    80002a48:	84aa                	mv	s1,a0
    80002a4a:	892e                	mv	s2,a1
	struct proc *p = myproc();
    80002a4c:	fffff097          	auipc	ra,0xfffff
    80002a50:	fde080e7          	jalr	-34(ra) # 80001a2a <myproc>
	if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002a54:	653c                	ld	a5,72(a0)
    80002a56:	02f4f863          	bgeu	s1,a5,80002a86 <fetchaddr+0x4a>
    80002a5a:	00848713          	addi	a4,s1,8
    80002a5e:	02e7e663          	bltu	a5,a4,80002a8a <fetchaddr+0x4e>
	if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002a62:	46a1                	li	a3,8
    80002a64:	8626                	mv	a2,s1
    80002a66:	85ca                	mv	a1,s2
    80002a68:	6928                	ld	a0,80(a0)
    80002a6a:	fffff097          	auipc	ra,0xfffff
    80002a6e:	c92080e7          	jalr	-878(ra) # 800016fc <copyin>
    80002a72:	00a03533          	snez	a0,a0
    80002a76:	40a00533          	neg	a0,a0
}
    80002a7a:	60e2                	ld	ra,24(sp)
    80002a7c:	6442                	ld	s0,16(sp)
    80002a7e:	64a2                	ld	s1,8(sp)
    80002a80:	6902                	ld	s2,0(sp)
    80002a82:	6105                	addi	sp,sp,32
    80002a84:	8082                	ret
		return -1;
    80002a86:	557d                	li	a0,-1
    80002a88:	bfcd                	j	80002a7a <fetchaddr+0x3e>
    80002a8a:	557d                	li	a0,-1
    80002a8c:	b7fd                	j	80002a7a <fetchaddr+0x3e>

0000000080002a8e <fetchstr>:
{
    80002a8e:	7179                	addi	sp,sp,-48
    80002a90:	f406                	sd	ra,40(sp)
    80002a92:	f022                	sd	s0,32(sp)
    80002a94:	ec26                	sd	s1,24(sp)
    80002a96:	e84a                	sd	s2,16(sp)
    80002a98:	e44e                	sd	s3,8(sp)
    80002a9a:	1800                	addi	s0,sp,48
    80002a9c:	892a                	mv	s2,a0
    80002a9e:	84ae                	mv	s1,a1
    80002aa0:	89b2                	mv	s3,a2
	struct proc *p = myproc();
    80002aa2:	fffff097          	auipc	ra,0xfffff
    80002aa6:	f88080e7          	jalr	-120(ra) # 80001a2a <myproc>
	int err = copyinstr(p->pagetable, buf, addr, max);
    80002aaa:	86ce                	mv	a3,s3
    80002aac:	864a                	mv	a2,s2
    80002aae:	85a6                	mv	a1,s1
    80002ab0:	6928                	ld	a0,80(a0)
    80002ab2:	fffff097          	auipc	ra,0xfffff
    80002ab6:	cd6080e7          	jalr	-810(ra) # 80001788 <copyinstr>
	if(err < 0)
    80002aba:	00054763          	bltz	a0,80002ac8 <fetchstr+0x3a>
	return strlen(buf);
    80002abe:	8526                	mv	a0,s1
    80002ac0:	ffffe097          	auipc	ra,0xffffe
    80002ac4:	3a4080e7          	jalr	932(ra) # 80000e64 <strlen>
}
    80002ac8:	70a2                	ld	ra,40(sp)
    80002aca:	7402                	ld	s0,32(sp)
    80002acc:	64e2                	ld	s1,24(sp)
    80002ace:	6942                	ld	s2,16(sp)
    80002ad0:	69a2                	ld	s3,8(sp)
    80002ad2:	6145                	addi	sp,sp,48
    80002ad4:	8082                	ret

0000000080002ad6 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002ad6:	1101                	addi	sp,sp,-32
    80002ad8:	ec06                	sd	ra,24(sp)
    80002ada:	e822                	sd	s0,16(sp)
    80002adc:	e426                	sd	s1,8(sp)
    80002ade:	1000                	addi	s0,sp,32
    80002ae0:	84ae                	mv	s1,a1
	*ip = argraw(n);
    80002ae2:	00000097          	auipc	ra,0x0
    80002ae6:	ef2080e7          	jalr	-270(ra) # 800029d4 <argraw>
    80002aea:	c088                	sw	a0,0(s1)
	return 0;
}
    80002aec:	4501                	li	a0,0
    80002aee:	60e2                	ld	ra,24(sp)
    80002af0:	6442                	ld	s0,16(sp)
    80002af2:	64a2                	ld	s1,8(sp)
    80002af4:	6105                	addi	sp,sp,32
    80002af6:	8082                	ret

0000000080002af8 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002af8:	1101                	addi	sp,sp,-32
    80002afa:	ec06                	sd	ra,24(sp)
    80002afc:	e822                	sd	s0,16(sp)
    80002afe:	e426                	sd	s1,8(sp)
    80002b00:	1000                	addi	s0,sp,32
    80002b02:	84ae                	mv	s1,a1
	*ip = argraw(n);
    80002b04:	00000097          	auipc	ra,0x0
    80002b08:	ed0080e7          	jalr	-304(ra) # 800029d4 <argraw>
    80002b0c:	e088                	sd	a0,0(s1)
	return 0;
}
    80002b0e:	4501                	li	a0,0
    80002b10:	60e2                	ld	ra,24(sp)
    80002b12:	6442                	ld	s0,16(sp)
    80002b14:	64a2                	ld	s1,8(sp)
    80002b16:	6105                	addi	sp,sp,32
    80002b18:	8082                	ret

0000000080002b1a <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002b1a:	1101                	addi	sp,sp,-32
    80002b1c:	ec06                	sd	ra,24(sp)
    80002b1e:	e822                	sd	s0,16(sp)
    80002b20:	e426                	sd	s1,8(sp)
    80002b22:	e04a                	sd	s2,0(sp)
    80002b24:	1000                	addi	s0,sp,32
    80002b26:	84ae                	mv	s1,a1
    80002b28:	8932                	mv	s2,a2
	*ip = argraw(n);
    80002b2a:	00000097          	auipc	ra,0x0
    80002b2e:	eaa080e7          	jalr	-342(ra) # 800029d4 <argraw>
	uint64 addr;
	if(argaddr(n, &addr) < 0)
		return -1;
	return fetchstr(addr, buf, max);
    80002b32:	864a                	mv	a2,s2
    80002b34:	85a6                	mv	a1,s1
    80002b36:	00000097          	auipc	ra,0x0
    80002b3a:	f58080e7          	jalr	-168(ra) # 80002a8e <fetchstr>
}
    80002b3e:	60e2                	ld	ra,24(sp)
    80002b40:	6442                	ld	s0,16(sp)
    80002b42:	64a2                	ld	s1,8(sp)
    80002b44:	6902                	ld	s2,0(sp)
    80002b46:	6105                	addi	sp,sp,32
    80002b48:	8082                	ret

0000000080002b4a <syscall>:
[SYS_close]   sys_close,
};

void
syscall(void)
{
    80002b4a:	1101                	addi	sp,sp,-32
    80002b4c:	ec06                	sd	ra,24(sp)
    80002b4e:	e822                	sd	s0,16(sp)
    80002b50:	e426                	sd	s1,8(sp)
    80002b52:	e04a                	sd	s2,0(sp)
    80002b54:	1000                	addi	s0,sp,32
	int num;
	struct proc *p = myproc();
    80002b56:	fffff097          	auipc	ra,0xfffff
    80002b5a:	ed4080e7          	jalr	-300(ra) # 80001a2a <myproc>
    80002b5e:	84aa                	mv	s1,a0

	num = p->trapframe->a7;
    80002b60:	05853903          	ld	s2,88(a0)
    80002b64:	0a893783          	ld	a5,168(s2)
    80002b68:	0007869b          	sext.w	a3,a5
	if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002b6c:	37fd                	addiw	a5,a5,-1
    80002b6e:	4751                	li	a4,20
    80002b70:	00f76f63          	bltu	a4,a5,80002b8e <syscall+0x44>
    80002b74:	00369713          	slli	a4,a3,0x3
    80002b78:	00006797          	auipc	a5,0x6
    80002b7c:	8d878793          	addi	a5,a5,-1832 # 80008450 <syscalls>
    80002b80:	97ba                	add	a5,a5,a4
    80002b82:	639c                	ld	a5,0(a5)
    80002b84:	c789                	beqz	a5,80002b8e <syscall+0x44>
		p->trapframe->a0 = syscalls[num]();
    80002b86:	9782                	jalr	a5
    80002b88:	06a93823          	sd	a0,112(s2)
    80002b8c:	a839                	j	80002baa <syscall+0x60>
	} else {
		printf("%d %s: unknown sys call %d\n",
    80002b8e:	15848613          	addi	a2,s1,344
    80002b92:	588c                	lw	a1,48(s1)
    80002b94:	00006517          	auipc	a0,0x6
    80002b98:	88450513          	addi	a0,a0,-1916 # 80008418 <states.1713+0x150>
    80002b9c:	ffffe097          	auipc	ra,0xffffe
    80002ba0:	9ec080e7          	jalr	-1556(ra) # 80000588 <printf>
				p->pid, p->name, num);
		p->trapframe->a0 = -1;
    80002ba4:	6cbc                	ld	a5,88(s1)
    80002ba6:	577d                	li	a4,-1
    80002ba8:	fbb8                	sd	a4,112(a5)
	}
}
    80002baa:	60e2                	ld	ra,24(sp)
    80002bac:	6442                	ld	s0,16(sp)
    80002bae:	64a2                	ld	s1,8(sp)
    80002bb0:	6902                	ld	s2,0(sp)
    80002bb2:	6105                	addi	sp,sp,32
    80002bb4:	8082                	ret

0000000080002bb6 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002bb6:	1101                	addi	sp,sp,-32
    80002bb8:	ec06                	sd	ra,24(sp)
    80002bba:	e822                	sd	s0,16(sp)
    80002bbc:	1000                	addi	s0,sp,32
	int n;
	if(argint(0, &n) < 0)
    80002bbe:	fec40593          	addi	a1,s0,-20
    80002bc2:	4501                	li	a0,0
    80002bc4:	00000097          	auipc	ra,0x0
    80002bc8:	f12080e7          	jalr	-238(ra) # 80002ad6 <argint>
		return -1;
    80002bcc:	57fd                	li	a5,-1
	if(argint(0, &n) < 0)
    80002bce:	00054963          	bltz	a0,80002be0 <sys_exit+0x2a>
	exit(n);
    80002bd2:	fec42503          	lw	a0,-20(s0)
    80002bd6:	fffff097          	auipc	ra,0xfffff
    80002bda:	76c080e7          	jalr	1900(ra) # 80002342 <exit>
	return 0;  // not reached
    80002bde:	4781                	li	a5,0
}
    80002be0:	853e                	mv	a0,a5
    80002be2:	60e2                	ld	ra,24(sp)
    80002be4:	6442                	ld	s0,16(sp)
    80002be6:	6105                	addi	sp,sp,32
    80002be8:	8082                	ret

0000000080002bea <sys_getpid>:

uint64
sys_getpid(void)
{
    80002bea:	1141                	addi	sp,sp,-16
    80002bec:	e406                	sd	ra,8(sp)
    80002bee:	e022                	sd	s0,0(sp)
    80002bf0:	0800                	addi	s0,sp,16
	return myproc()->pid;
    80002bf2:	fffff097          	auipc	ra,0xfffff
    80002bf6:	e38080e7          	jalr	-456(ra) # 80001a2a <myproc>
}
    80002bfa:	5908                	lw	a0,48(a0)
    80002bfc:	60a2                	ld	ra,8(sp)
    80002bfe:	6402                	ld	s0,0(sp)
    80002c00:	0141                	addi	sp,sp,16
    80002c02:	8082                	ret

0000000080002c04 <sys_fork>:

uint64
sys_fork(void)
{
    80002c04:	1141                	addi	sp,sp,-16
    80002c06:	e406                	sd	ra,8(sp)
    80002c08:	e022                	sd	s0,0(sp)
    80002c0a:	0800                	addi	s0,sp,16
	return fork();
    80002c0c:	fffff097          	auipc	ra,0xfffff
    80002c10:	1ec080e7          	jalr	492(ra) # 80001df8 <fork>
}
    80002c14:	60a2                	ld	ra,8(sp)
    80002c16:	6402                	ld	s0,0(sp)
    80002c18:	0141                	addi	sp,sp,16
    80002c1a:	8082                	ret

0000000080002c1c <sys_wait>:

uint64
sys_wait(void)
{
    80002c1c:	1101                	addi	sp,sp,-32
    80002c1e:	ec06                	sd	ra,24(sp)
    80002c20:	e822                	sd	s0,16(sp)
    80002c22:	1000                	addi	s0,sp,32
	uint64 p;
	if(argaddr(0, &p) < 0)
    80002c24:	fe840593          	addi	a1,s0,-24
    80002c28:	4501                	li	a0,0
    80002c2a:	00000097          	auipc	ra,0x0
    80002c2e:	ece080e7          	jalr	-306(ra) # 80002af8 <argaddr>
    80002c32:	87aa                	mv	a5,a0
		return -1;
    80002c34:	557d                	li	a0,-1
	if(argaddr(0, &p) < 0)
    80002c36:	0007c863          	bltz	a5,80002c46 <sys_wait+0x2a>
	return wait(p);
    80002c3a:	fe843503          	ld	a0,-24(s0)
    80002c3e:	fffff097          	auipc	ra,0xfffff
    80002c42:	50c080e7          	jalr	1292(ra) # 8000214a <wait>
}
    80002c46:	60e2                	ld	ra,24(sp)
    80002c48:	6442                	ld	s0,16(sp)
    80002c4a:	6105                	addi	sp,sp,32
    80002c4c:	8082                	ret

0000000080002c4e <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002c4e:	7179                	addi	sp,sp,-48
    80002c50:	f406                	sd	ra,40(sp)
    80002c52:	f022                	sd	s0,32(sp)
    80002c54:	ec26                	sd	s1,24(sp)
    80002c56:	1800                	addi	s0,sp,48
	int addr;
	int n;
	// struct proc *p = myproc();

	if(argint(0, &n) < 0)
    80002c58:	fdc40593          	addi	a1,s0,-36
    80002c5c:	4501                	li	a0,0
    80002c5e:	00000097          	auipc	ra,0x0
    80002c62:	e78080e7          	jalr	-392(ra) # 80002ad6 <argint>
    80002c66:	87aa                	mv	a5,a0
		return -1;
    80002c68:	557d                	li	a0,-1
	if(argint(0, &n) < 0)
    80002c6a:	0207c063          	bltz	a5,80002c8a <sys_sbrk+0x3c>
	addr = myproc()->sz;
    80002c6e:	fffff097          	auipc	ra,0xfffff
    80002c72:	dbc080e7          	jalr	-580(ra) # 80001a2a <myproc>
    80002c76:	4524                	lw	s1,72(a0)

	// printf("%x\n", p->sz);
	// debug_uvmpte(p->pagetable, 0, p->sz);

	if(growproc(n) < 0)
    80002c78:	fdc42503          	lw	a0,-36(s0)
    80002c7c:	fffff097          	auipc	ra,0xfffff
    80002c80:	108080e7          	jalr	264(ra) # 80001d84 <growproc>
    80002c84:	00054863          	bltz	a0,80002c94 <sys_sbrk+0x46>
		return -1;

	// printf("%x\n", p->sz);
	// debug_uvmpte(p->pagetable, 0, p->sz);

	return addr;
    80002c88:	8526                	mv	a0,s1
}
    80002c8a:	70a2                	ld	ra,40(sp)
    80002c8c:	7402                	ld	s0,32(sp)
    80002c8e:	64e2                	ld	s1,24(sp)
    80002c90:	6145                	addi	sp,sp,48
    80002c92:	8082                	ret
		return -1;
    80002c94:	557d                	li	a0,-1
    80002c96:	bfd5                	j	80002c8a <sys_sbrk+0x3c>

0000000080002c98 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002c98:	7139                	addi	sp,sp,-64
    80002c9a:	fc06                	sd	ra,56(sp)
    80002c9c:	f822                	sd	s0,48(sp)
    80002c9e:	f426                	sd	s1,40(sp)
    80002ca0:	f04a                	sd	s2,32(sp)
    80002ca2:	ec4e                	sd	s3,24(sp)
    80002ca4:	0080                	addi	s0,sp,64
	int n;
	uint ticks0;

	if(argint(0, &n) < 0)
    80002ca6:	fcc40593          	addi	a1,s0,-52
    80002caa:	4501                	li	a0,0
    80002cac:	00000097          	auipc	ra,0x0
    80002cb0:	e2a080e7          	jalr	-470(ra) # 80002ad6 <argint>
		return -1;
    80002cb4:	57fd                	li	a5,-1
	if(argint(0, &n) < 0)
    80002cb6:	06054563          	bltz	a0,80002d20 <sys_sleep+0x88>
	acquire(&tickslock);
    80002cba:	0001b517          	auipc	a0,0x1b
    80002cbe:	41650513          	addi	a0,a0,1046 # 8001e0d0 <tickslock>
    80002cc2:	ffffe097          	auipc	ra,0xffffe
    80002cc6:	f22080e7          	jalr	-222(ra) # 80000be4 <acquire>
	ticks0 = ticks;
    80002cca:	0000d917          	auipc	s2,0xd
    80002cce:	36692903          	lw	s2,870(s2) # 80010030 <ticks>
	while(ticks - ticks0 < n){
    80002cd2:	fcc42783          	lw	a5,-52(s0)
    80002cd6:	cf85                	beqz	a5,80002d0e <sys_sleep+0x76>
		if(myproc()->killed){
			release(&tickslock);
			return -1;
		}
		sleep(&ticks, &tickslock);
    80002cd8:	0001b997          	auipc	s3,0x1b
    80002cdc:	3f898993          	addi	s3,s3,1016 # 8001e0d0 <tickslock>
    80002ce0:	0000d497          	auipc	s1,0xd
    80002ce4:	35048493          	addi	s1,s1,848 # 80010030 <ticks>
		if(myproc()->killed){
    80002ce8:	fffff097          	auipc	ra,0xfffff
    80002cec:	d42080e7          	jalr	-702(ra) # 80001a2a <myproc>
    80002cf0:	551c                	lw	a5,40(a0)
    80002cf2:	ef9d                	bnez	a5,80002d30 <sys_sleep+0x98>
		sleep(&ticks, &tickslock);
    80002cf4:	85ce                	mv	a1,s3
    80002cf6:	8526                	mv	a0,s1
    80002cf8:	fffff097          	auipc	ra,0xfffff
    80002cfc:	3ee080e7          	jalr	1006(ra) # 800020e6 <sleep>
	while(ticks - ticks0 < n){
    80002d00:	409c                	lw	a5,0(s1)
    80002d02:	412787bb          	subw	a5,a5,s2
    80002d06:	fcc42703          	lw	a4,-52(s0)
    80002d0a:	fce7efe3          	bltu	a5,a4,80002ce8 <sys_sleep+0x50>
	}
	release(&tickslock);
    80002d0e:	0001b517          	auipc	a0,0x1b
    80002d12:	3c250513          	addi	a0,a0,962 # 8001e0d0 <tickslock>
    80002d16:	ffffe097          	auipc	ra,0xffffe
    80002d1a:	f82080e7          	jalr	-126(ra) # 80000c98 <release>
	return 0;
    80002d1e:	4781                	li	a5,0
}
    80002d20:	853e                	mv	a0,a5
    80002d22:	70e2                	ld	ra,56(sp)
    80002d24:	7442                	ld	s0,48(sp)
    80002d26:	74a2                	ld	s1,40(sp)
    80002d28:	7902                	ld	s2,32(sp)
    80002d2a:	69e2                	ld	s3,24(sp)
    80002d2c:	6121                	addi	sp,sp,64
    80002d2e:	8082                	ret
			release(&tickslock);
    80002d30:	0001b517          	auipc	a0,0x1b
    80002d34:	3a050513          	addi	a0,a0,928 # 8001e0d0 <tickslock>
    80002d38:	ffffe097          	auipc	ra,0xffffe
    80002d3c:	f60080e7          	jalr	-160(ra) # 80000c98 <release>
			return -1;
    80002d40:	57fd                	li	a5,-1
    80002d42:	bff9                	j	80002d20 <sys_sleep+0x88>

0000000080002d44 <sys_kill>:

uint64
sys_kill(void)
{
    80002d44:	1101                	addi	sp,sp,-32
    80002d46:	ec06                	sd	ra,24(sp)
    80002d48:	e822                	sd	s0,16(sp)
    80002d4a:	1000                	addi	s0,sp,32
	int pid;

	if(argint(0, &pid) < 0)
    80002d4c:	fec40593          	addi	a1,s0,-20
    80002d50:	4501                	li	a0,0
    80002d52:	00000097          	auipc	ra,0x0
    80002d56:	d84080e7          	jalr	-636(ra) # 80002ad6 <argint>
    80002d5a:	87aa                	mv	a5,a0
		return -1;
    80002d5c:	557d                	li	a0,-1
	if(argint(0, &pid) < 0)
    80002d5e:	0007c863          	bltz	a5,80002d6e <sys_kill+0x2a>
	return kill(pid);
    80002d62:	fec42503          	lw	a0,-20(s0)
    80002d66:	fffff097          	auipc	ra,0xfffff
    80002d6a:	6b2080e7          	jalr	1714(ra) # 80002418 <kill>
}
    80002d6e:	60e2                	ld	ra,24(sp)
    80002d70:	6442                	ld	s0,16(sp)
    80002d72:	6105                	addi	sp,sp,32
    80002d74:	8082                	ret

0000000080002d76 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002d76:	1101                	addi	sp,sp,-32
    80002d78:	ec06                	sd	ra,24(sp)
    80002d7a:	e822                	sd	s0,16(sp)
    80002d7c:	e426                	sd	s1,8(sp)
    80002d7e:	1000                	addi	s0,sp,32
	uint xticks;

	acquire(&tickslock);
    80002d80:	0001b517          	auipc	a0,0x1b
    80002d84:	35050513          	addi	a0,a0,848 # 8001e0d0 <tickslock>
    80002d88:	ffffe097          	auipc	ra,0xffffe
    80002d8c:	e5c080e7          	jalr	-420(ra) # 80000be4 <acquire>
	xticks = ticks;
    80002d90:	0000d497          	auipc	s1,0xd
    80002d94:	2a04a483          	lw	s1,672(s1) # 80010030 <ticks>
	release(&tickslock);
    80002d98:	0001b517          	auipc	a0,0x1b
    80002d9c:	33850513          	addi	a0,a0,824 # 8001e0d0 <tickslock>
    80002da0:	ffffe097          	auipc	ra,0xffffe
    80002da4:	ef8080e7          	jalr	-264(ra) # 80000c98 <release>
	return xticks;
}
    80002da8:	02049513          	slli	a0,s1,0x20
    80002dac:	9101                	srli	a0,a0,0x20
    80002dae:	60e2                	ld	ra,24(sp)
    80002db0:	6442                	ld	s0,16(sp)
    80002db2:	64a2                	ld	s1,8(sp)
    80002db4:	6105                	addi	sp,sp,32
    80002db6:	8082                	ret

0000000080002db8 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002db8:	7179                	addi	sp,sp,-48
    80002dba:	f406                	sd	ra,40(sp)
    80002dbc:	f022                	sd	s0,32(sp)
    80002dbe:	ec26                	sd	s1,24(sp)
    80002dc0:	e84a                	sd	s2,16(sp)
    80002dc2:	e44e                	sd	s3,8(sp)
    80002dc4:	e052                	sd	s4,0(sp)
    80002dc6:	1800                	addi	s0,sp,48
	struct buf *b;

	initlock(&bcache.lock, "bcache");
    80002dc8:	00005597          	auipc	a1,0x5
    80002dcc:	73858593          	addi	a1,a1,1848 # 80008500 <syscalls+0xb0>
    80002dd0:	0001b517          	auipc	a0,0x1b
    80002dd4:	31850513          	addi	a0,a0,792 # 8001e0e8 <bcache>
    80002dd8:	ffffe097          	auipc	ra,0xffffe
    80002ddc:	d7c080e7          	jalr	-644(ra) # 80000b54 <initlock>

	// Create linked list of buffers
	bcache.head.prev = &bcache.head;
    80002de0:	00023797          	auipc	a5,0x23
    80002de4:	30878793          	addi	a5,a5,776 # 800260e8 <bcache+0x8000>
    80002de8:	00023717          	auipc	a4,0x23
    80002dec:	56870713          	addi	a4,a4,1384 # 80026350 <bcache+0x8268>
    80002df0:	2ae7b823          	sd	a4,688(a5)
	bcache.head.next = &bcache.head;
    80002df4:	2ae7bc23          	sd	a4,696(a5)
	for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002df8:	0001b497          	auipc	s1,0x1b
    80002dfc:	30848493          	addi	s1,s1,776 # 8001e100 <bcache+0x18>
		b->next = bcache.head.next;
    80002e00:	893e                	mv	s2,a5
		b->prev = &bcache.head;
    80002e02:	89ba                	mv	s3,a4
		initsleeplock(&b->lock, "buffer");
    80002e04:	00005a17          	auipc	s4,0x5
    80002e08:	704a0a13          	addi	s4,s4,1796 # 80008508 <syscalls+0xb8>
		b->next = bcache.head.next;
    80002e0c:	2b893783          	ld	a5,696(s2)
    80002e10:	e8bc                	sd	a5,80(s1)
		b->prev = &bcache.head;
    80002e12:	0534b423          	sd	s3,72(s1)
		initsleeplock(&b->lock, "buffer");
    80002e16:	85d2                	mv	a1,s4
    80002e18:	01048513          	addi	a0,s1,16
    80002e1c:	00001097          	auipc	ra,0x1
    80002e20:	4bc080e7          	jalr	1212(ra) # 800042d8 <initsleeplock>
		bcache.head.next->prev = b;
    80002e24:	2b893783          	ld	a5,696(s2)
    80002e28:	e7a4                	sd	s1,72(a5)
		bcache.head.next = b;
    80002e2a:	2a993c23          	sd	s1,696(s2)
	for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002e2e:	45848493          	addi	s1,s1,1112
    80002e32:	fd349de3          	bne	s1,s3,80002e0c <binit+0x54>
	}
}
    80002e36:	70a2                	ld	ra,40(sp)
    80002e38:	7402                	ld	s0,32(sp)
    80002e3a:	64e2                	ld	s1,24(sp)
    80002e3c:	6942                	ld	s2,16(sp)
    80002e3e:	69a2                	ld	s3,8(sp)
    80002e40:	6a02                	ld	s4,0(sp)
    80002e42:	6145                	addi	sp,sp,48
    80002e44:	8082                	ret

0000000080002e46 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80002e46:	7179                	addi	sp,sp,-48
    80002e48:	f406                	sd	ra,40(sp)
    80002e4a:	f022                	sd	s0,32(sp)
    80002e4c:	ec26                	sd	s1,24(sp)
    80002e4e:	e84a                	sd	s2,16(sp)
    80002e50:	e44e                	sd	s3,8(sp)
    80002e52:	1800                	addi	s0,sp,48
    80002e54:	89aa                	mv	s3,a0
    80002e56:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    80002e58:	0001b517          	auipc	a0,0x1b
    80002e5c:	29050513          	addi	a0,a0,656 # 8001e0e8 <bcache>
    80002e60:	ffffe097          	auipc	ra,0xffffe
    80002e64:	d84080e7          	jalr	-636(ra) # 80000be4 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80002e68:	00023497          	auipc	s1,0x23
    80002e6c:	5384b483          	ld	s1,1336(s1) # 800263a0 <bcache+0x82b8>
    80002e70:	00023797          	auipc	a5,0x23
    80002e74:	4e078793          	addi	a5,a5,1248 # 80026350 <bcache+0x8268>
    80002e78:	02f48f63          	beq	s1,a5,80002eb6 <bread+0x70>
    80002e7c:	873e                	mv	a4,a5
    80002e7e:	a021                	j	80002e86 <bread+0x40>
    80002e80:	68a4                	ld	s1,80(s1)
    80002e82:	02e48a63          	beq	s1,a4,80002eb6 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80002e86:	449c                	lw	a5,8(s1)
    80002e88:	ff379ce3          	bne	a5,s3,80002e80 <bread+0x3a>
    80002e8c:	44dc                	lw	a5,12(s1)
    80002e8e:	ff2799e3          	bne	a5,s2,80002e80 <bread+0x3a>
      b->refcnt++;
    80002e92:	40bc                	lw	a5,64(s1)
    80002e94:	2785                	addiw	a5,a5,1
    80002e96:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002e98:	0001b517          	auipc	a0,0x1b
    80002e9c:	25050513          	addi	a0,a0,592 # 8001e0e8 <bcache>
    80002ea0:	ffffe097          	auipc	ra,0xffffe
    80002ea4:	df8080e7          	jalr	-520(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    80002ea8:	01048513          	addi	a0,s1,16
    80002eac:	00001097          	auipc	ra,0x1
    80002eb0:	466080e7          	jalr	1126(ra) # 80004312 <acquiresleep>
      return b;
    80002eb4:	a8b9                	j	80002f12 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002eb6:	00023497          	auipc	s1,0x23
    80002eba:	4e24b483          	ld	s1,1250(s1) # 80026398 <bcache+0x82b0>
    80002ebe:	00023797          	auipc	a5,0x23
    80002ec2:	49278793          	addi	a5,a5,1170 # 80026350 <bcache+0x8268>
    80002ec6:	00f48863          	beq	s1,a5,80002ed6 <bread+0x90>
    80002eca:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80002ecc:	40bc                	lw	a5,64(s1)
    80002ece:	cf81                	beqz	a5,80002ee6 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002ed0:	64a4                	ld	s1,72(s1)
    80002ed2:	fee49de3          	bne	s1,a4,80002ecc <bread+0x86>
  panic("bget: no buffers");
    80002ed6:	00005517          	auipc	a0,0x5
    80002eda:	63a50513          	addi	a0,a0,1594 # 80008510 <syscalls+0xc0>
    80002ede:	ffffd097          	auipc	ra,0xffffd
    80002ee2:	660080e7          	jalr	1632(ra) # 8000053e <panic>
      b->dev = dev;
    80002ee6:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    80002eea:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    80002eee:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80002ef2:	4785                	li	a5,1
    80002ef4:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002ef6:	0001b517          	auipc	a0,0x1b
    80002efa:	1f250513          	addi	a0,a0,498 # 8001e0e8 <bcache>
    80002efe:	ffffe097          	auipc	ra,0xffffe
    80002f02:	d9a080e7          	jalr	-614(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    80002f06:	01048513          	addi	a0,s1,16
    80002f0a:	00001097          	auipc	ra,0x1
    80002f0e:	408080e7          	jalr	1032(ra) # 80004312 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80002f12:	409c                	lw	a5,0(s1)
    80002f14:	cb89                	beqz	a5,80002f26 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80002f16:	8526                	mv	a0,s1
    80002f18:	70a2                	ld	ra,40(sp)
    80002f1a:	7402                	ld	s0,32(sp)
    80002f1c:	64e2                	ld	s1,24(sp)
    80002f1e:	6942                	ld	s2,16(sp)
    80002f20:	69a2                	ld	s3,8(sp)
    80002f22:	6145                	addi	sp,sp,48
    80002f24:	8082                	ret
    virtio_disk_rw(b, 0);
    80002f26:	4581                	li	a1,0
    80002f28:	8526                	mv	a0,s1
    80002f2a:	00003097          	auipc	ra,0x3
    80002f2e:	f0c080e7          	jalr	-244(ra) # 80005e36 <virtio_disk_rw>
    b->valid = 1;
    80002f32:	4785                	li	a5,1
    80002f34:	c09c                	sw	a5,0(s1)
  return b;
    80002f36:	b7c5                	j	80002f16 <bread+0xd0>

0000000080002f38 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80002f38:	1101                	addi	sp,sp,-32
    80002f3a:	ec06                	sd	ra,24(sp)
    80002f3c:	e822                	sd	s0,16(sp)
    80002f3e:	e426                	sd	s1,8(sp)
    80002f40:	1000                	addi	s0,sp,32
    80002f42:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80002f44:	0541                	addi	a0,a0,16
    80002f46:	00001097          	auipc	ra,0x1
    80002f4a:	466080e7          	jalr	1126(ra) # 800043ac <holdingsleep>
    80002f4e:	cd01                	beqz	a0,80002f66 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80002f50:	4585                	li	a1,1
    80002f52:	8526                	mv	a0,s1
    80002f54:	00003097          	auipc	ra,0x3
    80002f58:	ee2080e7          	jalr	-286(ra) # 80005e36 <virtio_disk_rw>
}
    80002f5c:	60e2                	ld	ra,24(sp)
    80002f5e:	6442                	ld	s0,16(sp)
    80002f60:	64a2                	ld	s1,8(sp)
    80002f62:	6105                	addi	sp,sp,32
    80002f64:	8082                	ret
    panic("bwrite");
    80002f66:	00005517          	auipc	a0,0x5
    80002f6a:	5c250513          	addi	a0,a0,1474 # 80008528 <syscalls+0xd8>
    80002f6e:	ffffd097          	auipc	ra,0xffffd
    80002f72:	5d0080e7          	jalr	1488(ra) # 8000053e <panic>

0000000080002f76 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80002f76:	1101                	addi	sp,sp,-32
    80002f78:	ec06                	sd	ra,24(sp)
    80002f7a:	e822                	sd	s0,16(sp)
    80002f7c:	e426                	sd	s1,8(sp)
    80002f7e:	e04a                	sd	s2,0(sp)
    80002f80:	1000                	addi	s0,sp,32
    80002f82:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80002f84:	01050913          	addi	s2,a0,16
    80002f88:	854a                	mv	a0,s2
    80002f8a:	00001097          	auipc	ra,0x1
    80002f8e:	422080e7          	jalr	1058(ra) # 800043ac <holdingsleep>
    80002f92:	c92d                	beqz	a0,80003004 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80002f94:	854a                	mv	a0,s2
    80002f96:	00001097          	auipc	ra,0x1
    80002f9a:	3d2080e7          	jalr	978(ra) # 80004368 <releasesleep>

  acquire(&bcache.lock);
    80002f9e:	0001b517          	auipc	a0,0x1b
    80002fa2:	14a50513          	addi	a0,a0,330 # 8001e0e8 <bcache>
    80002fa6:	ffffe097          	auipc	ra,0xffffe
    80002faa:	c3e080e7          	jalr	-962(ra) # 80000be4 <acquire>
  b->refcnt--;
    80002fae:	40bc                	lw	a5,64(s1)
    80002fb0:	37fd                	addiw	a5,a5,-1
    80002fb2:	0007871b          	sext.w	a4,a5
    80002fb6:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80002fb8:	eb05                	bnez	a4,80002fe8 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80002fba:	68bc                	ld	a5,80(s1)
    80002fbc:	64b8                	ld	a4,72(s1)
    80002fbe:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80002fc0:	64bc                	ld	a5,72(s1)
    80002fc2:	68b8                	ld	a4,80(s1)
    80002fc4:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80002fc6:	00023797          	auipc	a5,0x23
    80002fca:	12278793          	addi	a5,a5,290 # 800260e8 <bcache+0x8000>
    80002fce:	2b87b703          	ld	a4,696(a5)
    80002fd2:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80002fd4:	00023717          	auipc	a4,0x23
    80002fd8:	37c70713          	addi	a4,a4,892 # 80026350 <bcache+0x8268>
    80002fdc:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80002fde:	2b87b703          	ld	a4,696(a5)
    80002fe2:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80002fe4:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80002fe8:	0001b517          	auipc	a0,0x1b
    80002fec:	10050513          	addi	a0,a0,256 # 8001e0e8 <bcache>
    80002ff0:	ffffe097          	auipc	ra,0xffffe
    80002ff4:	ca8080e7          	jalr	-856(ra) # 80000c98 <release>
}
    80002ff8:	60e2                	ld	ra,24(sp)
    80002ffa:	6442                	ld	s0,16(sp)
    80002ffc:	64a2                	ld	s1,8(sp)
    80002ffe:	6902                	ld	s2,0(sp)
    80003000:	6105                	addi	sp,sp,32
    80003002:	8082                	ret
    panic("brelse");
    80003004:	00005517          	auipc	a0,0x5
    80003008:	52c50513          	addi	a0,a0,1324 # 80008530 <syscalls+0xe0>
    8000300c:	ffffd097          	auipc	ra,0xffffd
    80003010:	532080e7          	jalr	1330(ra) # 8000053e <panic>

0000000080003014 <bpin>:

void
bpin(struct buf *b) {
    80003014:	1101                	addi	sp,sp,-32
    80003016:	ec06                	sd	ra,24(sp)
    80003018:	e822                	sd	s0,16(sp)
    8000301a:	e426                	sd	s1,8(sp)
    8000301c:	1000                	addi	s0,sp,32
    8000301e:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003020:	0001b517          	auipc	a0,0x1b
    80003024:	0c850513          	addi	a0,a0,200 # 8001e0e8 <bcache>
    80003028:	ffffe097          	auipc	ra,0xffffe
    8000302c:	bbc080e7          	jalr	-1092(ra) # 80000be4 <acquire>
  b->refcnt++;
    80003030:	40bc                	lw	a5,64(s1)
    80003032:	2785                	addiw	a5,a5,1
    80003034:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003036:	0001b517          	auipc	a0,0x1b
    8000303a:	0b250513          	addi	a0,a0,178 # 8001e0e8 <bcache>
    8000303e:	ffffe097          	auipc	ra,0xffffe
    80003042:	c5a080e7          	jalr	-934(ra) # 80000c98 <release>
}
    80003046:	60e2                	ld	ra,24(sp)
    80003048:	6442                	ld	s0,16(sp)
    8000304a:	64a2                	ld	s1,8(sp)
    8000304c:	6105                	addi	sp,sp,32
    8000304e:	8082                	ret

0000000080003050 <bunpin>:

void
bunpin(struct buf *b) {
    80003050:	1101                	addi	sp,sp,-32
    80003052:	ec06                	sd	ra,24(sp)
    80003054:	e822                	sd	s0,16(sp)
    80003056:	e426                	sd	s1,8(sp)
    80003058:	1000                	addi	s0,sp,32
    8000305a:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000305c:	0001b517          	auipc	a0,0x1b
    80003060:	08c50513          	addi	a0,a0,140 # 8001e0e8 <bcache>
    80003064:	ffffe097          	auipc	ra,0xffffe
    80003068:	b80080e7          	jalr	-1152(ra) # 80000be4 <acquire>
  b->refcnt--;
    8000306c:	40bc                	lw	a5,64(s1)
    8000306e:	37fd                	addiw	a5,a5,-1
    80003070:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003072:	0001b517          	auipc	a0,0x1b
    80003076:	07650513          	addi	a0,a0,118 # 8001e0e8 <bcache>
    8000307a:	ffffe097          	auipc	ra,0xffffe
    8000307e:	c1e080e7          	jalr	-994(ra) # 80000c98 <release>
}
    80003082:	60e2                	ld	ra,24(sp)
    80003084:	6442                	ld	s0,16(sp)
    80003086:	64a2                	ld	s1,8(sp)
    80003088:	6105                	addi	sp,sp,32
    8000308a:	8082                	ret

000000008000308c <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    8000308c:	1101                	addi	sp,sp,-32
    8000308e:	ec06                	sd	ra,24(sp)
    80003090:	e822                	sd	s0,16(sp)
    80003092:	e426                	sd	s1,8(sp)
    80003094:	e04a                	sd	s2,0(sp)
    80003096:	1000                	addi	s0,sp,32
    80003098:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    8000309a:	00d5d59b          	srliw	a1,a1,0xd
    8000309e:	00023797          	auipc	a5,0x23
    800030a2:	7267a783          	lw	a5,1830(a5) # 800267c4 <sb+0x1c>
    800030a6:	9dbd                	addw	a1,a1,a5
    800030a8:	00000097          	auipc	ra,0x0
    800030ac:	d9e080e7          	jalr	-610(ra) # 80002e46 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800030b0:	0074f713          	andi	a4,s1,7
    800030b4:	4785                	li	a5,1
    800030b6:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800030ba:	14ce                	slli	s1,s1,0x33
    800030bc:	90d9                	srli	s1,s1,0x36
    800030be:	00950733          	add	a4,a0,s1
    800030c2:	05874703          	lbu	a4,88(a4)
    800030c6:	00e7f6b3          	and	a3,a5,a4
    800030ca:	c69d                	beqz	a3,800030f8 <bfree+0x6c>
    800030cc:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800030ce:	94aa                	add	s1,s1,a0
    800030d0:	fff7c793          	not	a5,a5
    800030d4:	8ff9                	and	a5,a5,a4
    800030d6:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    800030da:	00001097          	auipc	ra,0x1
    800030de:	118080e7          	jalr	280(ra) # 800041f2 <log_write>
  brelse(bp);
    800030e2:	854a                	mv	a0,s2
    800030e4:	00000097          	auipc	ra,0x0
    800030e8:	e92080e7          	jalr	-366(ra) # 80002f76 <brelse>
}
    800030ec:	60e2                	ld	ra,24(sp)
    800030ee:	6442                	ld	s0,16(sp)
    800030f0:	64a2                	ld	s1,8(sp)
    800030f2:	6902                	ld	s2,0(sp)
    800030f4:	6105                	addi	sp,sp,32
    800030f6:	8082                	ret
    panic("freeing free block");
    800030f8:	00005517          	auipc	a0,0x5
    800030fc:	44050513          	addi	a0,a0,1088 # 80008538 <syscalls+0xe8>
    80003100:	ffffd097          	auipc	ra,0xffffd
    80003104:	43e080e7          	jalr	1086(ra) # 8000053e <panic>

0000000080003108 <balloc>:
{
    80003108:	711d                	addi	sp,sp,-96
    8000310a:	ec86                	sd	ra,88(sp)
    8000310c:	e8a2                	sd	s0,80(sp)
    8000310e:	e4a6                	sd	s1,72(sp)
    80003110:	e0ca                	sd	s2,64(sp)
    80003112:	fc4e                	sd	s3,56(sp)
    80003114:	f852                	sd	s4,48(sp)
    80003116:	f456                	sd	s5,40(sp)
    80003118:	f05a                	sd	s6,32(sp)
    8000311a:	ec5e                	sd	s7,24(sp)
    8000311c:	e862                	sd	s8,16(sp)
    8000311e:	e466                	sd	s9,8(sp)
    80003120:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003122:	00023797          	auipc	a5,0x23
    80003126:	68a7a783          	lw	a5,1674(a5) # 800267ac <sb+0x4>
    8000312a:	cbd1                	beqz	a5,800031be <balloc+0xb6>
    8000312c:	8baa                	mv	s7,a0
    8000312e:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003130:	00023b17          	auipc	s6,0x23
    80003134:	678b0b13          	addi	s6,s6,1656 # 800267a8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003138:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    8000313a:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000313c:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    8000313e:	6c89                	lui	s9,0x2
    80003140:	a831                	j	8000315c <balloc+0x54>
    brelse(bp);
    80003142:	854a                	mv	a0,s2
    80003144:	00000097          	auipc	ra,0x0
    80003148:	e32080e7          	jalr	-462(ra) # 80002f76 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    8000314c:	015c87bb          	addw	a5,s9,s5
    80003150:	00078a9b          	sext.w	s5,a5
    80003154:	004b2703          	lw	a4,4(s6)
    80003158:	06eaf363          	bgeu	s5,a4,800031be <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    8000315c:	41fad79b          	sraiw	a5,s5,0x1f
    80003160:	0137d79b          	srliw	a5,a5,0x13
    80003164:	015787bb          	addw	a5,a5,s5
    80003168:	40d7d79b          	sraiw	a5,a5,0xd
    8000316c:	01cb2583          	lw	a1,28(s6)
    80003170:	9dbd                	addw	a1,a1,a5
    80003172:	855e                	mv	a0,s7
    80003174:	00000097          	auipc	ra,0x0
    80003178:	cd2080e7          	jalr	-814(ra) # 80002e46 <bread>
    8000317c:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000317e:	004b2503          	lw	a0,4(s6)
    80003182:	000a849b          	sext.w	s1,s5
    80003186:	8662                	mv	a2,s8
    80003188:	faa4fde3          	bgeu	s1,a0,80003142 <balloc+0x3a>
      m = 1 << (bi % 8);
    8000318c:	41f6579b          	sraiw	a5,a2,0x1f
    80003190:	01d7d69b          	srliw	a3,a5,0x1d
    80003194:	00c6873b          	addw	a4,a3,a2
    80003198:	00777793          	andi	a5,a4,7
    8000319c:	9f95                	subw	a5,a5,a3
    8000319e:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800031a2:	4037571b          	sraiw	a4,a4,0x3
    800031a6:	00e906b3          	add	a3,s2,a4
    800031aa:	0586c683          	lbu	a3,88(a3)
    800031ae:	00d7f5b3          	and	a1,a5,a3
    800031b2:	cd91                	beqz	a1,800031ce <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800031b4:	2605                	addiw	a2,a2,1
    800031b6:	2485                	addiw	s1,s1,1
    800031b8:	fd4618e3          	bne	a2,s4,80003188 <balloc+0x80>
    800031bc:	b759                	j	80003142 <balloc+0x3a>
  panic("balloc: out of blocks");
    800031be:	00005517          	auipc	a0,0x5
    800031c2:	39250513          	addi	a0,a0,914 # 80008550 <syscalls+0x100>
    800031c6:	ffffd097          	auipc	ra,0xffffd
    800031ca:	378080e7          	jalr	888(ra) # 8000053e <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    800031ce:	974a                	add	a4,a4,s2
    800031d0:	8fd5                	or	a5,a5,a3
    800031d2:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    800031d6:	854a                	mv	a0,s2
    800031d8:	00001097          	auipc	ra,0x1
    800031dc:	01a080e7          	jalr	26(ra) # 800041f2 <log_write>
        brelse(bp);
    800031e0:	854a                	mv	a0,s2
    800031e2:	00000097          	auipc	ra,0x0
    800031e6:	d94080e7          	jalr	-620(ra) # 80002f76 <brelse>
  bp = bread(dev, bno);
    800031ea:	85a6                	mv	a1,s1
    800031ec:	855e                	mv	a0,s7
    800031ee:	00000097          	auipc	ra,0x0
    800031f2:	c58080e7          	jalr	-936(ra) # 80002e46 <bread>
    800031f6:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800031f8:	40000613          	li	a2,1024
    800031fc:	4581                	li	a1,0
    800031fe:	05850513          	addi	a0,a0,88
    80003202:	ffffe097          	auipc	ra,0xffffe
    80003206:	ade080e7          	jalr	-1314(ra) # 80000ce0 <memset>
  log_write(bp);
    8000320a:	854a                	mv	a0,s2
    8000320c:	00001097          	auipc	ra,0x1
    80003210:	fe6080e7          	jalr	-26(ra) # 800041f2 <log_write>
  brelse(bp);
    80003214:	854a                	mv	a0,s2
    80003216:	00000097          	auipc	ra,0x0
    8000321a:	d60080e7          	jalr	-672(ra) # 80002f76 <brelse>
}
    8000321e:	8526                	mv	a0,s1
    80003220:	60e6                	ld	ra,88(sp)
    80003222:	6446                	ld	s0,80(sp)
    80003224:	64a6                	ld	s1,72(sp)
    80003226:	6906                	ld	s2,64(sp)
    80003228:	79e2                	ld	s3,56(sp)
    8000322a:	7a42                	ld	s4,48(sp)
    8000322c:	7aa2                	ld	s5,40(sp)
    8000322e:	7b02                	ld	s6,32(sp)
    80003230:	6be2                	ld	s7,24(sp)
    80003232:	6c42                	ld	s8,16(sp)
    80003234:	6ca2                	ld	s9,8(sp)
    80003236:	6125                	addi	sp,sp,96
    80003238:	8082                	ret

000000008000323a <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    8000323a:	7179                	addi	sp,sp,-48
    8000323c:	f406                	sd	ra,40(sp)
    8000323e:	f022                	sd	s0,32(sp)
    80003240:	ec26                	sd	s1,24(sp)
    80003242:	e84a                	sd	s2,16(sp)
    80003244:	e44e                	sd	s3,8(sp)
    80003246:	e052                	sd	s4,0(sp)
    80003248:	1800                	addi	s0,sp,48
    8000324a:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    8000324c:	47ad                	li	a5,11
    8000324e:	04b7fe63          	bgeu	a5,a1,800032aa <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    80003252:	ff45849b          	addiw	s1,a1,-12
    80003256:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    8000325a:	0ff00793          	li	a5,255
    8000325e:	0ae7e363          	bltu	a5,a4,80003304 <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    80003262:	08052583          	lw	a1,128(a0)
    80003266:	c5ad                	beqz	a1,800032d0 <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    80003268:	00092503          	lw	a0,0(s2)
    8000326c:	00000097          	auipc	ra,0x0
    80003270:	bda080e7          	jalr	-1062(ra) # 80002e46 <bread>
    80003274:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003276:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    8000327a:	02049593          	slli	a1,s1,0x20
    8000327e:	9181                	srli	a1,a1,0x20
    80003280:	058a                	slli	a1,a1,0x2
    80003282:	00b784b3          	add	s1,a5,a1
    80003286:	0004a983          	lw	s3,0(s1)
    8000328a:	04098d63          	beqz	s3,800032e4 <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    8000328e:	8552                	mv	a0,s4
    80003290:	00000097          	auipc	ra,0x0
    80003294:	ce6080e7          	jalr	-794(ra) # 80002f76 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003298:	854e                	mv	a0,s3
    8000329a:	70a2                	ld	ra,40(sp)
    8000329c:	7402                	ld	s0,32(sp)
    8000329e:	64e2                	ld	s1,24(sp)
    800032a0:	6942                	ld	s2,16(sp)
    800032a2:	69a2                	ld	s3,8(sp)
    800032a4:	6a02                	ld	s4,0(sp)
    800032a6:	6145                	addi	sp,sp,48
    800032a8:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    800032aa:	02059493          	slli	s1,a1,0x20
    800032ae:	9081                	srli	s1,s1,0x20
    800032b0:	048a                	slli	s1,s1,0x2
    800032b2:	94aa                	add	s1,s1,a0
    800032b4:	0504a983          	lw	s3,80(s1)
    800032b8:	fe0990e3          	bnez	s3,80003298 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    800032bc:	4108                	lw	a0,0(a0)
    800032be:	00000097          	auipc	ra,0x0
    800032c2:	e4a080e7          	jalr	-438(ra) # 80003108 <balloc>
    800032c6:	0005099b          	sext.w	s3,a0
    800032ca:	0534a823          	sw	s3,80(s1)
    800032ce:	b7e9                	j	80003298 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    800032d0:	4108                	lw	a0,0(a0)
    800032d2:	00000097          	auipc	ra,0x0
    800032d6:	e36080e7          	jalr	-458(ra) # 80003108 <balloc>
    800032da:	0005059b          	sext.w	a1,a0
    800032de:	08b92023          	sw	a1,128(s2)
    800032e2:	b759                	j	80003268 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    800032e4:	00092503          	lw	a0,0(s2)
    800032e8:	00000097          	auipc	ra,0x0
    800032ec:	e20080e7          	jalr	-480(ra) # 80003108 <balloc>
    800032f0:	0005099b          	sext.w	s3,a0
    800032f4:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    800032f8:	8552                	mv	a0,s4
    800032fa:	00001097          	auipc	ra,0x1
    800032fe:	ef8080e7          	jalr	-264(ra) # 800041f2 <log_write>
    80003302:	b771                	j	8000328e <bmap+0x54>
  panic("bmap: out of range");
    80003304:	00005517          	auipc	a0,0x5
    80003308:	26450513          	addi	a0,a0,612 # 80008568 <syscalls+0x118>
    8000330c:	ffffd097          	auipc	ra,0xffffd
    80003310:	232080e7          	jalr	562(ra) # 8000053e <panic>

0000000080003314 <iget>:
{
    80003314:	7179                	addi	sp,sp,-48
    80003316:	f406                	sd	ra,40(sp)
    80003318:	f022                	sd	s0,32(sp)
    8000331a:	ec26                	sd	s1,24(sp)
    8000331c:	e84a                	sd	s2,16(sp)
    8000331e:	e44e                	sd	s3,8(sp)
    80003320:	e052                	sd	s4,0(sp)
    80003322:	1800                	addi	s0,sp,48
    80003324:	89aa                	mv	s3,a0
    80003326:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003328:	00023517          	auipc	a0,0x23
    8000332c:	4a050513          	addi	a0,a0,1184 # 800267c8 <itable>
    80003330:	ffffe097          	auipc	ra,0xffffe
    80003334:	8b4080e7          	jalr	-1868(ra) # 80000be4 <acquire>
  empty = 0;
    80003338:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    8000333a:	00023497          	auipc	s1,0x23
    8000333e:	4a648493          	addi	s1,s1,1190 # 800267e0 <itable+0x18>
    80003342:	00025697          	auipc	a3,0x25
    80003346:	f2e68693          	addi	a3,a3,-210 # 80028270 <log>
    8000334a:	a039                	j	80003358 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000334c:	02090b63          	beqz	s2,80003382 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003350:	08848493          	addi	s1,s1,136
    80003354:	02d48a63          	beq	s1,a3,80003388 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003358:	449c                	lw	a5,8(s1)
    8000335a:	fef059e3          	blez	a5,8000334c <iget+0x38>
    8000335e:	4098                	lw	a4,0(s1)
    80003360:	ff3716e3          	bne	a4,s3,8000334c <iget+0x38>
    80003364:	40d8                	lw	a4,4(s1)
    80003366:	ff4713e3          	bne	a4,s4,8000334c <iget+0x38>
      ip->ref++;
    8000336a:	2785                	addiw	a5,a5,1
    8000336c:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    8000336e:	00023517          	auipc	a0,0x23
    80003372:	45a50513          	addi	a0,a0,1114 # 800267c8 <itable>
    80003376:	ffffe097          	auipc	ra,0xffffe
    8000337a:	922080e7          	jalr	-1758(ra) # 80000c98 <release>
      return ip;
    8000337e:	8926                	mv	s2,s1
    80003380:	a03d                	j	800033ae <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003382:	f7f9                	bnez	a5,80003350 <iget+0x3c>
    80003384:	8926                	mv	s2,s1
    80003386:	b7e9                	j	80003350 <iget+0x3c>
  if(empty == 0)
    80003388:	02090c63          	beqz	s2,800033c0 <iget+0xac>
  ip->dev = dev;
    8000338c:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003390:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003394:	4785                	li	a5,1
    80003396:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    8000339a:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    8000339e:	00023517          	auipc	a0,0x23
    800033a2:	42a50513          	addi	a0,a0,1066 # 800267c8 <itable>
    800033a6:	ffffe097          	auipc	ra,0xffffe
    800033aa:	8f2080e7          	jalr	-1806(ra) # 80000c98 <release>
}
    800033ae:	854a                	mv	a0,s2
    800033b0:	70a2                	ld	ra,40(sp)
    800033b2:	7402                	ld	s0,32(sp)
    800033b4:	64e2                	ld	s1,24(sp)
    800033b6:	6942                	ld	s2,16(sp)
    800033b8:	69a2                	ld	s3,8(sp)
    800033ba:	6a02                	ld	s4,0(sp)
    800033bc:	6145                	addi	sp,sp,48
    800033be:	8082                	ret
    panic("iget: no inodes");
    800033c0:	00005517          	auipc	a0,0x5
    800033c4:	1c050513          	addi	a0,a0,448 # 80008580 <syscalls+0x130>
    800033c8:	ffffd097          	auipc	ra,0xffffd
    800033cc:	176080e7          	jalr	374(ra) # 8000053e <panic>

00000000800033d0 <fsinit>:
fsinit(int dev) {
    800033d0:	7179                	addi	sp,sp,-48
    800033d2:	f406                	sd	ra,40(sp)
    800033d4:	f022                	sd	s0,32(sp)
    800033d6:	ec26                	sd	s1,24(sp)
    800033d8:	e84a                	sd	s2,16(sp)
    800033da:	e44e                	sd	s3,8(sp)
    800033dc:	1800                	addi	s0,sp,48
    800033de:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    800033e0:	4585                	li	a1,1
    800033e2:	00000097          	auipc	ra,0x0
    800033e6:	a64080e7          	jalr	-1436(ra) # 80002e46 <bread>
    800033ea:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    800033ec:	00023997          	auipc	s3,0x23
    800033f0:	3bc98993          	addi	s3,s3,956 # 800267a8 <sb>
    800033f4:	02000613          	li	a2,32
    800033f8:	05850593          	addi	a1,a0,88
    800033fc:	854e                	mv	a0,s3
    800033fe:	ffffe097          	auipc	ra,0xffffe
    80003402:	942080e7          	jalr	-1726(ra) # 80000d40 <memmove>
  brelse(bp);
    80003406:	8526                	mv	a0,s1
    80003408:	00000097          	auipc	ra,0x0
    8000340c:	b6e080e7          	jalr	-1170(ra) # 80002f76 <brelse>
  if(sb.magic != FSMAGIC)
    80003410:	0009a703          	lw	a4,0(s3)
    80003414:	102037b7          	lui	a5,0x10203
    80003418:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    8000341c:	02f71263          	bne	a4,a5,80003440 <fsinit+0x70>
  initlog(dev, &sb);
    80003420:	00023597          	auipc	a1,0x23
    80003424:	38858593          	addi	a1,a1,904 # 800267a8 <sb>
    80003428:	854a                	mv	a0,s2
    8000342a:	00001097          	auipc	ra,0x1
    8000342e:	b4c080e7          	jalr	-1204(ra) # 80003f76 <initlog>
}
    80003432:	70a2                	ld	ra,40(sp)
    80003434:	7402                	ld	s0,32(sp)
    80003436:	64e2                	ld	s1,24(sp)
    80003438:	6942                	ld	s2,16(sp)
    8000343a:	69a2                	ld	s3,8(sp)
    8000343c:	6145                	addi	sp,sp,48
    8000343e:	8082                	ret
    panic("invalid file system");
    80003440:	00005517          	auipc	a0,0x5
    80003444:	15050513          	addi	a0,a0,336 # 80008590 <syscalls+0x140>
    80003448:	ffffd097          	auipc	ra,0xffffd
    8000344c:	0f6080e7          	jalr	246(ra) # 8000053e <panic>

0000000080003450 <iinit>:
{
    80003450:	7179                	addi	sp,sp,-48
    80003452:	f406                	sd	ra,40(sp)
    80003454:	f022                	sd	s0,32(sp)
    80003456:	ec26                	sd	s1,24(sp)
    80003458:	e84a                	sd	s2,16(sp)
    8000345a:	e44e                	sd	s3,8(sp)
    8000345c:	1800                	addi	s0,sp,48
	initlock(&itable.lock, "itable");
    8000345e:	00005597          	auipc	a1,0x5
    80003462:	14a58593          	addi	a1,a1,330 # 800085a8 <syscalls+0x158>
    80003466:	00023517          	auipc	a0,0x23
    8000346a:	36250513          	addi	a0,a0,866 # 800267c8 <itable>
    8000346e:	ffffd097          	auipc	ra,0xffffd
    80003472:	6e6080e7          	jalr	1766(ra) # 80000b54 <initlock>
	for(i = 0; i < NINODE; i++) {
    80003476:	00023497          	auipc	s1,0x23
    8000347a:	37a48493          	addi	s1,s1,890 # 800267f0 <itable+0x28>
    8000347e:	00025997          	auipc	s3,0x25
    80003482:	e0298993          	addi	s3,s3,-510 # 80028280 <log+0x10>
		initsleeplock(&itable.inode[i].lock, "inode");
    80003486:	00005917          	auipc	s2,0x5
    8000348a:	12a90913          	addi	s2,s2,298 # 800085b0 <syscalls+0x160>
    8000348e:	85ca                	mv	a1,s2
    80003490:	8526                	mv	a0,s1
    80003492:	00001097          	auipc	ra,0x1
    80003496:	e46080e7          	jalr	-442(ra) # 800042d8 <initsleeplock>
	for(i = 0; i < NINODE; i++) {
    8000349a:	08848493          	addi	s1,s1,136
    8000349e:	ff3498e3          	bne	s1,s3,8000348e <iinit+0x3e>
}
    800034a2:	70a2                	ld	ra,40(sp)
    800034a4:	7402                	ld	s0,32(sp)
    800034a6:	64e2                	ld	s1,24(sp)
    800034a8:	6942                	ld	s2,16(sp)
    800034aa:	69a2                	ld	s3,8(sp)
    800034ac:	6145                	addi	sp,sp,48
    800034ae:	8082                	ret

00000000800034b0 <ialloc>:
{
    800034b0:	715d                	addi	sp,sp,-80
    800034b2:	e486                	sd	ra,72(sp)
    800034b4:	e0a2                	sd	s0,64(sp)
    800034b6:	fc26                	sd	s1,56(sp)
    800034b8:	f84a                	sd	s2,48(sp)
    800034ba:	f44e                	sd	s3,40(sp)
    800034bc:	f052                	sd	s4,32(sp)
    800034be:	ec56                	sd	s5,24(sp)
    800034c0:	e85a                	sd	s6,16(sp)
    800034c2:	e45e                	sd	s7,8(sp)
    800034c4:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    800034c6:	00023717          	auipc	a4,0x23
    800034ca:	2ee72703          	lw	a4,750(a4) # 800267b4 <sb+0xc>
    800034ce:	4785                	li	a5,1
    800034d0:	04e7fa63          	bgeu	a5,a4,80003524 <ialloc+0x74>
    800034d4:	8aaa                	mv	s5,a0
    800034d6:	8bae                	mv	s7,a1
    800034d8:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    800034da:	00023a17          	auipc	s4,0x23
    800034de:	2cea0a13          	addi	s4,s4,718 # 800267a8 <sb>
    800034e2:	00048b1b          	sext.w	s6,s1
    800034e6:	0044d593          	srli	a1,s1,0x4
    800034ea:	018a2783          	lw	a5,24(s4)
    800034ee:	9dbd                	addw	a1,a1,a5
    800034f0:	8556                	mv	a0,s5
    800034f2:	00000097          	auipc	ra,0x0
    800034f6:	954080e7          	jalr	-1708(ra) # 80002e46 <bread>
    800034fa:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    800034fc:	05850993          	addi	s3,a0,88
    80003500:	00f4f793          	andi	a5,s1,15
    80003504:	079a                	slli	a5,a5,0x6
    80003506:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003508:	00099783          	lh	a5,0(s3)
    8000350c:	c785                	beqz	a5,80003534 <ialloc+0x84>
    brelse(bp);
    8000350e:	00000097          	auipc	ra,0x0
    80003512:	a68080e7          	jalr	-1432(ra) # 80002f76 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003516:	0485                	addi	s1,s1,1
    80003518:	00ca2703          	lw	a4,12(s4)
    8000351c:	0004879b          	sext.w	a5,s1
    80003520:	fce7e1e3          	bltu	a5,a4,800034e2 <ialloc+0x32>
  panic("ialloc: no inodes");
    80003524:	00005517          	auipc	a0,0x5
    80003528:	09450513          	addi	a0,a0,148 # 800085b8 <syscalls+0x168>
    8000352c:	ffffd097          	auipc	ra,0xffffd
    80003530:	012080e7          	jalr	18(ra) # 8000053e <panic>
      memset(dip, 0, sizeof(*dip));
    80003534:	04000613          	li	a2,64
    80003538:	4581                	li	a1,0
    8000353a:	854e                	mv	a0,s3
    8000353c:	ffffd097          	auipc	ra,0xffffd
    80003540:	7a4080e7          	jalr	1956(ra) # 80000ce0 <memset>
      dip->type = type;
    80003544:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003548:	854a                	mv	a0,s2
    8000354a:	00001097          	auipc	ra,0x1
    8000354e:	ca8080e7          	jalr	-856(ra) # 800041f2 <log_write>
      brelse(bp);
    80003552:	854a                	mv	a0,s2
    80003554:	00000097          	auipc	ra,0x0
    80003558:	a22080e7          	jalr	-1502(ra) # 80002f76 <brelse>
      return iget(dev, inum);
    8000355c:	85da                	mv	a1,s6
    8000355e:	8556                	mv	a0,s5
    80003560:	00000097          	auipc	ra,0x0
    80003564:	db4080e7          	jalr	-588(ra) # 80003314 <iget>
}
    80003568:	60a6                	ld	ra,72(sp)
    8000356a:	6406                	ld	s0,64(sp)
    8000356c:	74e2                	ld	s1,56(sp)
    8000356e:	7942                	ld	s2,48(sp)
    80003570:	79a2                	ld	s3,40(sp)
    80003572:	7a02                	ld	s4,32(sp)
    80003574:	6ae2                	ld	s5,24(sp)
    80003576:	6b42                	ld	s6,16(sp)
    80003578:	6ba2                	ld	s7,8(sp)
    8000357a:	6161                	addi	sp,sp,80
    8000357c:	8082                	ret

000000008000357e <iupdate>:
{
    8000357e:	1101                	addi	sp,sp,-32
    80003580:	ec06                	sd	ra,24(sp)
    80003582:	e822                	sd	s0,16(sp)
    80003584:	e426                	sd	s1,8(sp)
    80003586:	e04a                	sd	s2,0(sp)
    80003588:	1000                	addi	s0,sp,32
    8000358a:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    8000358c:	415c                	lw	a5,4(a0)
    8000358e:	0047d79b          	srliw	a5,a5,0x4
    80003592:	00023597          	auipc	a1,0x23
    80003596:	22e5a583          	lw	a1,558(a1) # 800267c0 <sb+0x18>
    8000359a:	9dbd                	addw	a1,a1,a5
    8000359c:	4108                	lw	a0,0(a0)
    8000359e:	00000097          	auipc	ra,0x0
    800035a2:	8a8080e7          	jalr	-1880(ra) # 80002e46 <bread>
    800035a6:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    800035a8:	05850793          	addi	a5,a0,88
    800035ac:	40c8                	lw	a0,4(s1)
    800035ae:	893d                	andi	a0,a0,15
    800035b0:	051a                	slli	a0,a0,0x6
    800035b2:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    800035b4:	04449703          	lh	a4,68(s1)
    800035b8:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    800035bc:	04649703          	lh	a4,70(s1)
    800035c0:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    800035c4:	04849703          	lh	a4,72(s1)
    800035c8:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    800035cc:	04a49703          	lh	a4,74(s1)
    800035d0:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    800035d4:	44f8                	lw	a4,76(s1)
    800035d6:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    800035d8:	03400613          	li	a2,52
    800035dc:	05048593          	addi	a1,s1,80
    800035e0:	0531                	addi	a0,a0,12
    800035e2:	ffffd097          	auipc	ra,0xffffd
    800035e6:	75e080e7          	jalr	1886(ra) # 80000d40 <memmove>
  log_write(bp);
    800035ea:	854a                	mv	a0,s2
    800035ec:	00001097          	auipc	ra,0x1
    800035f0:	c06080e7          	jalr	-1018(ra) # 800041f2 <log_write>
  brelse(bp);
    800035f4:	854a                	mv	a0,s2
    800035f6:	00000097          	auipc	ra,0x0
    800035fa:	980080e7          	jalr	-1664(ra) # 80002f76 <brelse>
}
    800035fe:	60e2                	ld	ra,24(sp)
    80003600:	6442                	ld	s0,16(sp)
    80003602:	64a2                	ld	s1,8(sp)
    80003604:	6902                	ld	s2,0(sp)
    80003606:	6105                	addi	sp,sp,32
    80003608:	8082                	ret

000000008000360a <idup>:
{
    8000360a:	1101                	addi	sp,sp,-32
    8000360c:	ec06                	sd	ra,24(sp)
    8000360e:	e822                	sd	s0,16(sp)
    80003610:	e426                	sd	s1,8(sp)
    80003612:	1000                	addi	s0,sp,32
    80003614:	84aa                	mv	s1,a0
	acquire(&itable.lock);
    80003616:	00023517          	auipc	a0,0x23
    8000361a:	1b250513          	addi	a0,a0,434 # 800267c8 <itable>
    8000361e:	ffffd097          	auipc	ra,0xffffd
    80003622:	5c6080e7          	jalr	1478(ra) # 80000be4 <acquire>
	ip->ref++;
    80003626:	449c                	lw	a5,8(s1)
    80003628:	2785                	addiw	a5,a5,1
    8000362a:	c49c                	sw	a5,8(s1)
	release(&itable.lock);
    8000362c:	00023517          	auipc	a0,0x23
    80003630:	19c50513          	addi	a0,a0,412 # 800267c8 <itable>
    80003634:	ffffd097          	auipc	ra,0xffffd
    80003638:	664080e7          	jalr	1636(ra) # 80000c98 <release>
}
    8000363c:	8526                	mv	a0,s1
    8000363e:	60e2                	ld	ra,24(sp)
    80003640:	6442                	ld	s0,16(sp)
    80003642:	64a2                	ld	s1,8(sp)
    80003644:	6105                	addi	sp,sp,32
    80003646:	8082                	ret

0000000080003648 <ilock>:
{
    80003648:	1101                	addi	sp,sp,-32
    8000364a:	ec06                	sd	ra,24(sp)
    8000364c:	e822                	sd	s0,16(sp)
    8000364e:	e426                	sd	s1,8(sp)
    80003650:	e04a                	sd	s2,0(sp)
    80003652:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003654:	c115                	beqz	a0,80003678 <ilock+0x30>
    80003656:	84aa                	mv	s1,a0
    80003658:	451c                	lw	a5,8(a0)
    8000365a:	00f05f63          	blez	a5,80003678 <ilock+0x30>
  acquiresleep(&ip->lock);
    8000365e:	0541                	addi	a0,a0,16
    80003660:	00001097          	auipc	ra,0x1
    80003664:	cb2080e7          	jalr	-846(ra) # 80004312 <acquiresleep>
  if(ip->valid == 0){
    80003668:	40bc                	lw	a5,64(s1)
    8000366a:	cf99                	beqz	a5,80003688 <ilock+0x40>
}
    8000366c:	60e2                	ld	ra,24(sp)
    8000366e:	6442                	ld	s0,16(sp)
    80003670:	64a2                	ld	s1,8(sp)
    80003672:	6902                	ld	s2,0(sp)
    80003674:	6105                	addi	sp,sp,32
    80003676:	8082                	ret
    panic("ilock");
    80003678:	00005517          	auipc	a0,0x5
    8000367c:	f5850513          	addi	a0,a0,-168 # 800085d0 <syscalls+0x180>
    80003680:	ffffd097          	auipc	ra,0xffffd
    80003684:	ebe080e7          	jalr	-322(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003688:	40dc                	lw	a5,4(s1)
    8000368a:	0047d79b          	srliw	a5,a5,0x4
    8000368e:	00023597          	auipc	a1,0x23
    80003692:	1325a583          	lw	a1,306(a1) # 800267c0 <sb+0x18>
    80003696:	9dbd                	addw	a1,a1,a5
    80003698:	4088                	lw	a0,0(s1)
    8000369a:	fffff097          	auipc	ra,0xfffff
    8000369e:	7ac080e7          	jalr	1964(ra) # 80002e46 <bread>
    800036a2:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    800036a4:	05850593          	addi	a1,a0,88
    800036a8:	40dc                	lw	a5,4(s1)
    800036aa:	8bbd                	andi	a5,a5,15
    800036ac:	079a                	slli	a5,a5,0x6
    800036ae:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    800036b0:	00059783          	lh	a5,0(a1)
    800036b4:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    800036b8:	00259783          	lh	a5,2(a1)
    800036bc:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    800036c0:	00459783          	lh	a5,4(a1)
    800036c4:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    800036c8:	00659783          	lh	a5,6(a1)
    800036cc:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    800036d0:	459c                	lw	a5,8(a1)
    800036d2:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    800036d4:	03400613          	li	a2,52
    800036d8:	05b1                	addi	a1,a1,12
    800036da:	05048513          	addi	a0,s1,80
    800036de:	ffffd097          	auipc	ra,0xffffd
    800036e2:	662080e7          	jalr	1634(ra) # 80000d40 <memmove>
    brelse(bp);
    800036e6:	854a                	mv	a0,s2
    800036e8:	00000097          	auipc	ra,0x0
    800036ec:	88e080e7          	jalr	-1906(ra) # 80002f76 <brelse>
    ip->valid = 1;
    800036f0:	4785                	li	a5,1
    800036f2:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    800036f4:	04449783          	lh	a5,68(s1)
    800036f8:	fbb5                	bnez	a5,8000366c <ilock+0x24>
      panic("ilock: no type");
    800036fa:	00005517          	auipc	a0,0x5
    800036fe:	ede50513          	addi	a0,a0,-290 # 800085d8 <syscalls+0x188>
    80003702:	ffffd097          	auipc	ra,0xffffd
    80003706:	e3c080e7          	jalr	-452(ra) # 8000053e <panic>

000000008000370a <iunlock>:
{
    8000370a:	1101                	addi	sp,sp,-32
    8000370c:	ec06                	sd	ra,24(sp)
    8000370e:	e822                	sd	s0,16(sp)
    80003710:	e426                	sd	s1,8(sp)
    80003712:	e04a                	sd	s2,0(sp)
    80003714:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003716:	c905                	beqz	a0,80003746 <iunlock+0x3c>
    80003718:	84aa                	mv	s1,a0
    8000371a:	01050913          	addi	s2,a0,16
    8000371e:	854a                	mv	a0,s2
    80003720:	00001097          	auipc	ra,0x1
    80003724:	c8c080e7          	jalr	-884(ra) # 800043ac <holdingsleep>
    80003728:	cd19                	beqz	a0,80003746 <iunlock+0x3c>
    8000372a:	449c                	lw	a5,8(s1)
    8000372c:	00f05d63          	blez	a5,80003746 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003730:	854a                	mv	a0,s2
    80003732:	00001097          	auipc	ra,0x1
    80003736:	c36080e7          	jalr	-970(ra) # 80004368 <releasesleep>
}
    8000373a:	60e2                	ld	ra,24(sp)
    8000373c:	6442                	ld	s0,16(sp)
    8000373e:	64a2                	ld	s1,8(sp)
    80003740:	6902                	ld	s2,0(sp)
    80003742:	6105                	addi	sp,sp,32
    80003744:	8082                	ret
    panic("iunlock");
    80003746:	00005517          	auipc	a0,0x5
    8000374a:	ea250513          	addi	a0,a0,-350 # 800085e8 <syscalls+0x198>
    8000374e:	ffffd097          	auipc	ra,0xffffd
    80003752:	df0080e7          	jalr	-528(ra) # 8000053e <panic>

0000000080003756 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003756:	7179                	addi	sp,sp,-48
    80003758:	f406                	sd	ra,40(sp)
    8000375a:	f022                	sd	s0,32(sp)
    8000375c:	ec26                	sd	s1,24(sp)
    8000375e:	e84a                	sd	s2,16(sp)
    80003760:	e44e                	sd	s3,8(sp)
    80003762:	e052                	sd	s4,0(sp)
    80003764:	1800                	addi	s0,sp,48
    80003766:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003768:	05050493          	addi	s1,a0,80
    8000376c:	08050913          	addi	s2,a0,128
    80003770:	a021                	j	80003778 <itrunc+0x22>
    80003772:	0491                	addi	s1,s1,4
    80003774:	01248d63          	beq	s1,s2,8000378e <itrunc+0x38>
    if(ip->addrs[i]){
    80003778:	408c                	lw	a1,0(s1)
    8000377a:	dde5                	beqz	a1,80003772 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    8000377c:	0009a503          	lw	a0,0(s3)
    80003780:	00000097          	auipc	ra,0x0
    80003784:	90c080e7          	jalr	-1780(ra) # 8000308c <bfree>
      ip->addrs[i] = 0;
    80003788:	0004a023          	sw	zero,0(s1)
    8000378c:	b7dd                	j	80003772 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    8000378e:	0809a583          	lw	a1,128(s3)
    80003792:	e185                	bnez	a1,800037b2 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003794:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003798:	854e                	mv	a0,s3
    8000379a:	00000097          	auipc	ra,0x0
    8000379e:	de4080e7          	jalr	-540(ra) # 8000357e <iupdate>
}
    800037a2:	70a2                	ld	ra,40(sp)
    800037a4:	7402                	ld	s0,32(sp)
    800037a6:	64e2                	ld	s1,24(sp)
    800037a8:	6942                	ld	s2,16(sp)
    800037aa:	69a2                	ld	s3,8(sp)
    800037ac:	6a02                	ld	s4,0(sp)
    800037ae:	6145                	addi	sp,sp,48
    800037b0:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    800037b2:	0009a503          	lw	a0,0(s3)
    800037b6:	fffff097          	auipc	ra,0xfffff
    800037ba:	690080e7          	jalr	1680(ra) # 80002e46 <bread>
    800037be:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    800037c0:	05850493          	addi	s1,a0,88
    800037c4:	45850913          	addi	s2,a0,1112
    800037c8:	a811                	j	800037dc <itrunc+0x86>
        bfree(ip->dev, a[j]);
    800037ca:	0009a503          	lw	a0,0(s3)
    800037ce:	00000097          	auipc	ra,0x0
    800037d2:	8be080e7          	jalr	-1858(ra) # 8000308c <bfree>
    for(j = 0; j < NINDIRECT; j++){
    800037d6:	0491                	addi	s1,s1,4
    800037d8:	01248563          	beq	s1,s2,800037e2 <itrunc+0x8c>
      if(a[j])
    800037dc:	408c                	lw	a1,0(s1)
    800037de:	dde5                	beqz	a1,800037d6 <itrunc+0x80>
    800037e0:	b7ed                	j	800037ca <itrunc+0x74>
    brelse(bp);
    800037e2:	8552                	mv	a0,s4
    800037e4:	fffff097          	auipc	ra,0xfffff
    800037e8:	792080e7          	jalr	1938(ra) # 80002f76 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    800037ec:	0809a583          	lw	a1,128(s3)
    800037f0:	0009a503          	lw	a0,0(s3)
    800037f4:	00000097          	auipc	ra,0x0
    800037f8:	898080e7          	jalr	-1896(ra) # 8000308c <bfree>
    ip->addrs[NDIRECT] = 0;
    800037fc:	0809a023          	sw	zero,128(s3)
    80003800:	bf51                	j	80003794 <itrunc+0x3e>

0000000080003802 <iput>:
{
    80003802:	1101                	addi	sp,sp,-32
    80003804:	ec06                	sd	ra,24(sp)
    80003806:	e822                	sd	s0,16(sp)
    80003808:	e426                	sd	s1,8(sp)
    8000380a:	e04a                	sd	s2,0(sp)
    8000380c:	1000                	addi	s0,sp,32
    8000380e:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003810:	00023517          	auipc	a0,0x23
    80003814:	fb850513          	addi	a0,a0,-72 # 800267c8 <itable>
    80003818:	ffffd097          	auipc	ra,0xffffd
    8000381c:	3cc080e7          	jalr	972(ra) # 80000be4 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003820:	4498                	lw	a4,8(s1)
    80003822:	4785                	li	a5,1
    80003824:	02f70363          	beq	a4,a5,8000384a <iput+0x48>
  ip->ref--;
    80003828:	449c                	lw	a5,8(s1)
    8000382a:	37fd                	addiw	a5,a5,-1
    8000382c:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    8000382e:	00023517          	auipc	a0,0x23
    80003832:	f9a50513          	addi	a0,a0,-102 # 800267c8 <itable>
    80003836:	ffffd097          	auipc	ra,0xffffd
    8000383a:	462080e7          	jalr	1122(ra) # 80000c98 <release>
}
    8000383e:	60e2                	ld	ra,24(sp)
    80003840:	6442                	ld	s0,16(sp)
    80003842:	64a2                	ld	s1,8(sp)
    80003844:	6902                	ld	s2,0(sp)
    80003846:	6105                	addi	sp,sp,32
    80003848:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    8000384a:	40bc                	lw	a5,64(s1)
    8000384c:	dff1                	beqz	a5,80003828 <iput+0x26>
    8000384e:	04a49783          	lh	a5,74(s1)
    80003852:	fbf9                	bnez	a5,80003828 <iput+0x26>
    acquiresleep(&ip->lock);
    80003854:	01048913          	addi	s2,s1,16
    80003858:	854a                	mv	a0,s2
    8000385a:	00001097          	auipc	ra,0x1
    8000385e:	ab8080e7          	jalr	-1352(ra) # 80004312 <acquiresleep>
    release(&itable.lock);
    80003862:	00023517          	auipc	a0,0x23
    80003866:	f6650513          	addi	a0,a0,-154 # 800267c8 <itable>
    8000386a:	ffffd097          	auipc	ra,0xffffd
    8000386e:	42e080e7          	jalr	1070(ra) # 80000c98 <release>
    itrunc(ip);
    80003872:	8526                	mv	a0,s1
    80003874:	00000097          	auipc	ra,0x0
    80003878:	ee2080e7          	jalr	-286(ra) # 80003756 <itrunc>
    ip->type = 0;
    8000387c:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003880:	8526                	mv	a0,s1
    80003882:	00000097          	auipc	ra,0x0
    80003886:	cfc080e7          	jalr	-772(ra) # 8000357e <iupdate>
    ip->valid = 0;
    8000388a:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    8000388e:	854a                	mv	a0,s2
    80003890:	00001097          	auipc	ra,0x1
    80003894:	ad8080e7          	jalr	-1320(ra) # 80004368 <releasesleep>
    acquire(&itable.lock);
    80003898:	00023517          	auipc	a0,0x23
    8000389c:	f3050513          	addi	a0,a0,-208 # 800267c8 <itable>
    800038a0:	ffffd097          	auipc	ra,0xffffd
    800038a4:	344080e7          	jalr	836(ra) # 80000be4 <acquire>
    800038a8:	b741                	j	80003828 <iput+0x26>

00000000800038aa <iunlockput>:
{
    800038aa:	1101                	addi	sp,sp,-32
    800038ac:	ec06                	sd	ra,24(sp)
    800038ae:	e822                	sd	s0,16(sp)
    800038b0:	e426                	sd	s1,8(sp)
    800038b2:	1000                	addi	s0,sp,32
    800038b4:	84aa                	mv	s1,a0
	iunlock(ip);
    800038b6:	00000097          	auipc	ra,0x0
    800038ba:	e54080e7          	jalr	-428(ra) # 8000370a <iunlock>
	iput(ip);
    800038be:	8526                	mv	a0,s1
    800038c0:	00000097          	auipc	ra,0x0
    800038c4:	f42080e7          	jalr	-190(ra) # 80003802 <iput>
}
    800038c8:	60e2                	ld	ra,24(sp)
    800038ca:	6442                	ld	s0,16(sp)
    800038cc:	64a2                	ld	s1,8(sp)
    800038ce:	6105                	addi	sp,sp,32
    800038d0:	8082                	ret

00000000800038d2 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    800038d2:	1141                	addi	sp,sp,-16
    800038d4:	e422                	sd	s0,8(sp)
    800038d6:	0800                	addi	s0,sp,16
	st->dev = ip->dev;
    800038d8:	411c                	lw	a5,0(a0)
    800038da:	c19c                	sw	a5,0(a1)
	st->ino = ip->inum;
    800038dc:	415c                	lw	a5,4(a0)
    800038de:	c1dc                	sw	a5,4(a1)
	st->type = ip->type;
    800038e0:	04451783          	lh	a5,68(a0)
    800038e4:	00f59423          	sh	a5,8(a1)
	st->nlink = ip->nlink;
    800038e8:	04a51783          	lh	a5,74(a0)
    800038ec:	00f59523          	sh	a5,10(a1)
	st->size = ip->size;
    800038f0:	04c56783          	lwu	a5,76(a0)
    800038f4:	e99c                	sd	a5,16(a1)
}
    800038f6:	6422                	ld	s0,8(sp)
    800038f8:	0141                	addi	sp,sp,16
    800038fa:	8082                	ret

00000000800038fc <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    800038fc:	457c                	lw	a5,76(a0)
    800038fe:	0ed7e963          	bltu	a5,a3,800039f0 <readi+0xf4>
{
    80003902:	7159                	addi	sp,sp,-112
    80003904:	f486                	sd	ra,104(sp)
    80003906:	f0a2                	sd	s0,96(sp)
    80003908:	eca6                	sd	s1,88(sp)
    8000390a:	e8ca                	sd	s2,80(sp)
    8000390c:	e4ce                	sd	s3,72(sp)
    8000390e:	e0d2                	sd	s4,64(sp)
    80003910:	fc56                	sd	s5,56(sp)
    80003912:	f85a                	sd	s6,48(sp)
    80003914:	f45e                	sd	s7,40(sp)
    80003916:	f062                	sd	s8,32(sp)
    80003918:	ec66                	sd	s9,24(sp)
    8000391a:	e86a                	sd	s10,16(sp)
    8000391c:	e46e                	sd	s11,8(sp)
    8000391e:	1880                	addi	s0,sp,112
    80003920:	8baa                	mv	s7,a0
    80003922:	8c2e                	mv	s8,a1
    80003924:	8ab2                	mv	s5,a2
    80003926:	84b6                	mv	s1,a3
    80003928:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    8000392a:	9f35                	addw	a4,a4,a3
    return 0;
    8000392c:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    8000392e:	0ad76063          	bltu	a4,a3,800039ce <readi+0xd2>
  if(off + n > ip->size)
    80003932:	00e7f463          	bgeu	a5,a4,8000393a <readi+0x3e>
    n = ip->size - off;
    80003936:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    8000393a:	0a0b0963          	beqz	s6,800039ec <readi+0xf0>
    8000393e:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003940:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003944:	5cfd                	li	s9,-1
    80003946:	a82d                	j	80003980 <readi+0x84>
    80003948:	020a1d93          	slli	s11,s4,0x20
    8000394c:	020ddd93          	srli	s11,s11,0x20
    80003950:	05890613          	addi	a2,s2,88
    80003954:	86ee                	mv	a3,s11
    80003956:	963a                	add	a2,a2,a4
    80003958:	85d6                	mv	a1,s5
    8000395a:	8562                	mv	a0,s8
    8000395c:	fffff097          	auipc	ra,0xfffff
    80003960:	b2e080e7          	jalr	-1234(ra) # 8000248a <either_copyout>
    80003964:	05950d63          	beq	a0,s9,800039be <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003968:	854a                	mv	a0,s2
    8000396a:	fffff097          	auipc	ra,0xfffff
    8000396e:	60c080e7          	jalr	1548(ra) # 80002f76 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003972:	013a09bb          	addw	s3,s4,s3
    80003976:	009a04bb          	addw	s1,s4,s1
    8000397a:	9aee                	add	s5,s5,s11
    8000397c:	0569f763          	bgeu	s3,s6,800039ca <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003980:	000ba903          	lw	s2,0(s7)
    80003984:	00a4d59b          	srliw	a1,s1,0xa
    80003988:	855e                	mv	a0,s7
    8000398a:	00000097          	auipc	ra,0x0
    8000398e:	8b0080e7          	jalr	-1872(ra) # 8000323a <bmap>
    80003992:	0005059b          	sext.w	a1,a0
    80003996:	854a                	mv	a0,s2
    80003998:	fffff097          	auipc	ra,0xfffff
    8000399c:	4ae080e7          	jalr	1198(ra) # 80002e46 <bread>
    800039a0:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    800039a2:	3ff4f713          	andi	a4,s1,1023
    800039a6:	40ed07bb          	subw	a5,s10,a4
    800039aa:	413b06bb          	subw	a3,s6,s3
    800039ae:	8a3e                	mv	s4,a5
    800039b0:	2781                	sext.w	a5,a5
    800039b2:	0006861b          	sext.w	a2,a3
    800039b6:	f8f679e3          	bgeu	a2,a5,80003948 <readi+0x4c>
    800039ba:	8a36                	mv	s4,a3
    800039bc:	b771                	j	80003948 <readi+0x4c>
      brelse(bp);
    800039be:	854a                	mv	a0,s2
    800039c0:	fffff097          	auipc	ra,0xfffff
    800039c4:	5b6080e7          	jalr	1462(ra) # 80002f76 <brelse>
      tot = -1;
    800039c8:	59fd                	li	s3,-1
  }
  return tot;
    800039ca:	0009851b          	sext.w	a0,s3
}
    800039ce:	70a6                	ld	ra,104(sp)
    800039d0:	7406                	ld	s0,96(sp)
    800039d2:	64e6                	ld	s1,88(sp)
    800039d4:	6946                	ld	s2,80(sp)
    800039d6:	69a6                	ld	s3,72(sp)
    800039d8:	6a06                	ld	s4,64(sp)
    800039da:	7ae2                	ld	s5,56(sp)
    800039dc:	7b42                	ld	s6,48(sp)
    800039de:	7ba2                	ld	s7,40(sp)
    800039e0:	7c02                	ld	s8,32(sp)
    800039e2:	6ce2                	ld	s9,24(sp)
    800039e4:	6d42                	ld	s10,16(sp)
    800039e6:	6da2                	ld	s11,8(sp)
    800039e8:	6165                	addi	sp,sp,112
    800039ea:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800039ec:	89da                	mv	s3,s6
    800039ee:	bff1                	j	800039ca <readi+0xce>
    return 0;
    800039f0:	4501                	li	a0,0
}
    800039f2:	8082                	ret

00000000800039f4 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    800039f4:	457c                	lw	a5,76(a0)
    800039f6:	10d7e863          	bltu	a5,a3,80003b06 <writei+0x112>
{
    800039fa:	7159                	addi	sp,sp,-112
    800039fc:	f486                	sd	ra,104(sp)
    800039fe:	f0a2                	sd	s0,96(sp)
    80003a00:	eca6                	sd	s1,88(sp)
    80003a02:	e8ca                	sd	s2,80(sp)
    80003a04:	e4ce                	sd	s3,72(sp)
    80003a06:	e0d2                	sd	s4,64(sp)
    80003a08:	fc56                	sd	s5,56(sp)
    80003a0a:	f85a                	sd	s6,48(sp)
    80003a0c:	f45e                	sd	s7,40(sp)
    80003a0e:	f062                	sd	s8,32(sp)
    80003a10:	ec66                	sd	s9,24(sp)
    80003a12:	e86a                	sd	s10,16(sp)
    80003a14:	e46e                	sd	s11,8(sp)
    80003a16:	1880                	addi	s0,sp,112
    80003a18:	8b2a                	mv	s6,a0
    80003a1a:	8c2e                	mv	s8,a1
    80003a1c:	8ab2                	mv	s5,a2
    80003a1e:	8936                	mv	s2,a3
    80003a20:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    80003a22:	00e687bb          	addw	a5,a3,a4
    80003a26:	0ed7e263          	bltu	a5,a3,80003b0a <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003a2a:	00043737          	lui	a4,0x43
    80003a2e:	0ef76063          	bltu	a4,a5,80003b0e <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003a32:	0c0b8863          	beqz	s7,80003b02 <writei+0x10e>
    80003a36:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003a38:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003a3c:	5cfd                	li	s9,-1
    80003a3e:	a091                	j	80003a82 <writei+0x8e>
    80003a40:	02099d93          	slli	s11,s3,0x20
    80003a44:	020ddd93          	srli	s11,s11,0x20
    80003a48:	05848513          	addi	a0,s1,88
    80003a4c:	86ee                	mv	a3,s11
    80003a4e:	8656                	mv	a2,s5
    80003a50:	85e2                	mv	a1,s8
    80003a52:	953a                	add	a0,a0,a4
    80003a54:	fffff097          	auipc	ra,0xfffff
    80003a58:	a8c080e7          	jalr	-1396(ra) # 800024e0 <either_copyin>
    80003a5c:	07950263          	beq	a0,s9,80003ac0 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003a60:	8526                	mv	a0,s1
    80003a62:	00000097          	auipc	ra,0x0
    80003a66:	790080e7          	jalr	1936(ra) # 800041f2 <log_write>
    brelse(bp);
    80003a6a:	8526                	mv	a0,s1
    80003a6c:	fffff097          	auipc	ra,0xfffff
    80003a70:	50a080e7          	jalr	1290(ra) # 80002f76 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003a74:	01498a3b          	addw	s4,s3,s4
    80003a78:	0129893b          	addw	s2,s3,s2
    80003a7c:	9aee                	add	s5,s5,s11
    80003a7e:	057a7663          	bgeu	s4,s7,80003aca <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003a82:	000b2483          	lw	s1,0(s6)
    80003a86:	00a9559b          	srliw	a1,s2,0xa
    80003a8a:	855a                	mv	a0,s6
    80003a8c:	fffff097          	auipc	ra,0xfffff
    80003a90:	7ae080e7          	jalr	1966(ra) # 8000323a <bmap>
    80003a94:	0005059b          	sext.w	a1,a0
    80003a98:	8526                	mv	a0,s1
    80003a9a:	fffff097          	auipc	ra,0xfffff
    80003a9e:	3ac080e7          	jalr	940(ra) # 80002e46 <bread>
    80003aa2:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003aa4:	3ff97713          	andi	a4,s2,1023
    80003aa8:	40ed07bb          	subw	a5,s10,a4
    80003aac:	414b86bb          	subw	a3,s7,s4
    80003ab0:	89be                	mv	s3,a5
    80003ab2:	2781                	sext.w	a5,a5
    80003ab4:	0006861b          	sext.w	a2,a3
    80003ab8:	f8f674e3          	bgeu	a2,a5,80003a40 <writei+0x4c>
    80003abc:	89b6                	mv	s3,a3
    80003abe:	b749                	j	80003a40 <writei+0x4c>
      brelse(bp);
    80003ac0:	8526                	mv	a0,s1
    80003ac2:	fffff097          	auipc	ra,0xfffff
    80003ac6:	4b4080e7          	jalr	1204(ra) # 80002f76 <brelse>
  }

  if(off > ip->size)
    80003aca:	04cb2783          	lw	a5,76(s6)
    80003ace:	0127f463          	bgeu	a5,s2,80003ad6 <writei+0xe2>
    ip->size = off;
    80003ad2:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003ad6:	855a                	mv	a0,s6
    80003ad8:	00000097          	auipc	ra,0x0
    80003adc:	aa6080e7          	jalr	-1370(ra) # 8000357e <iupdate>

  return tot;
    80003ae0:	000a051b          	sext.w	a0,s4
}
    80003ae4:	70a6                	ld	ra,104(sp)
    80003ae6:	7406                	ld	s0,96(sp)
    80003ae8:	64e6                	ld	s1,88(sp)
    80003aea:	6946                	ld	s2,80(sp)
    80003aec:	69a6                	ld	s3,72(sp)
    80003aee:	6a06                	ld	s4,64(sp)
    80003af0:	7ae2                	ld	s5,56(sp)
    80003af2:	7b42                	ld	s6,48(sp)
    80003af4:	7ba2                	ld	s7,40(sp)
    80003af6:	7c02                	ld	s8,32(sp)
    80003af8:	6ce2                	ld	s9,24(sp)
    80003afa:	6d42                	ld	s10,16(sp)
    80003afc:	6da2                	ld	s11,8(sp)
    80003afe:	6165                	addi	sp,sp,112
    80003b00:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003b02:	8a5e                	mv	s4,s7
    80003b04:	bfc9                	j	80003ad6 <writei+0xe2>
    return -1;
    80003b06:	557d                	li	a0,-1
}
    80003b08:	8082                	ret
    return -1;
    80003b0a:	557d                	li	a0,-1
    80003b0c:	bfe1                	j	80003ae4 <writei+0xf0>
    return -1;
    80003b0e:	557d                	li	a0,-1
    80003b10:	bfd1                	j	80003ae4 <writei+0xf0>

0000000080003b12 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003b12:	1141                	addi	sp,sp,-16
    80003b14:	e406                	sd	ra,8(sp)
    80003b16:	e022                	sd	s0,0(sp)
    80003b18:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003b1a:	4639                	li	a2,14
    80003b1c:	ffffd097          	auipc	ra,0xffffd
    80003b20:	29c080e7          	jalr	668(ra) # 80000db8 <strncmp>
}
    80003b24:	60a2                	ld	ra,8(sp)
    80003b26:	6402                	ld	s0,0(sp)
    80003b28:	0141                	addi	sp,sp,16
    80003b2a:	8082                	ret

0000000080003b2c <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003b2c:	7139                	addi	sp,sp,-64
    80003b2e:	fc06                	sd	ra,56(sp)
    80003b30:	f822                	sd	s0,48(sp)
    80003b32:	f426                	sd	s1,40(sp)
    80003b34:	f04a                	sd	s2,32(sp)
    80003b36:	ec4e                	sd	s3,24(sp)
    80003b38:	e852                	sd	s4,16(sp)
    80003b3a:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003b3c:	04451703          	lh	a4,68(a0)
    80003b40:	4785                	li	a5,1
    80003b42:	00f71a63          	bne	a4,a5,80003b56 <dirlookup+0x2a>
    80003b46:	892a                	mv	s2,a0
    80003b48:	89ae                	mv	s3,a1
    80003b4a:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003b4c:	457c                	lw	a5,76(a0)
    80003b4e:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003b50:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003b52:	e79d                	bnez	a5,80003b80 <dirlookup+0x54>
    80003b54:	a8a5                	j	80003bcc <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003b56:	00005517          	auipc	a0,0x5
    80003b5a:	a9a50513          	addi	a0,a0,-1382 # 800085f0 <syscalls+0x1a0>
    80003b5e:	ffffd097          	auipc	ra,0xffffd
    80003b62:	9e0080e7          	jalr	-1568(ra) # 8000053e <panic>
      panic("dirlookup read");
    80003b66:	00005517          	auipc	a0,0x5
    80003b6a:	aa250513          	addi	a0,a0,-1374 # 80008608 <syscalls+0x1b8>
    80003b6e:	ffffd097          	auipc	ra,0xffffd
    80003b72:	9d0080e7          	jalr	-1584(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003b76:	24c1                	addiw	s1,s1,16
    80003b78:	04c92783          	lw	a5,76(s2)
    80003b7c:	04f4f763          	bgeu	s1,a5,80003bca <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003b80:	4741                	li	a4,16
    80003b82:	86a6                	mv	a3,s1
    80003b84:	fc040613          	addi	a2,s0,-64
    80003b88:	4581                	li	a1,0
    80003b8a:	854a                	mv	a0,s2
    80003b8c:	00000097          	auipc	ra,0x0
    80003b90:	d70080e7          	jalr	-656(ra) # 800038fc <readi>
    80003b94:	47c1                	li	a5,16
    80003b96:	fcf518e3          	bne	a0,a5,80003b66 <dirlookup+0x3a>
    if(de.inum == 0)
    80003b9a:	fc045783          	lhu	a5,-64(s0)
    80003b9e:	dfe1                	beqz	a5,80003b76 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003ba0:	fc240593          	addi	a1,s0,-62
    80003ba4:	854e                	mv	a0,s3
    80003ba6:	00000097          	auipc	ra,0x0
    80003baa:	f6c080e7          	jalr	-148(ra) # 80003b12 <namecmp>
    80003bae:	f561                	bnez	a0,80003b76 <dirlookup+0x4a>
      if(poff)
    80003bb0:	000a0463          	beqz	s4,80003bb8 <dirlookup+0x8c>
        *poff = off;
    80003bb4:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003bb8:	fc045583          	lhu	a1,-64(s0)
    80003bbc:	00092503          	lw	a0,0(s2)
    80003bc0:	fffff097          	auipc	ra,0xfffff
    80003bc4:	754080e7          	jalr	1876(ra) # 80003314 <iget>
    80003bc8:	a011                	j	80003bcc <dirlookup+0xa0>
  return 0;
    80003bca:	4501                	li	a0,0
}
    80003bcc:	70e2                	ld	ra,56(sp)
    80003bce:	7442                	ld	s0,48(sp)
    80003bd0:	74a2                	ld	s1,40(sp)
    80003bd2:	7902                	ld	s2,32(sp)
    80003bd4:	69e2                	ld	s3,24(sp)
    80003bd6:	6a42                	ld	s4,16(sp)
    80003bd8:	6121                	addi	sp,sp,64
    80003bda:	8082                	ret

0000000080003bdc <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003bdc:	711d                	addi	sp,sp,-96
    80003bde:	ec86                	sd	ra,88(sp)
    80003be0:	e8a2                	sd	s0,80(sp)
    80003be2:	e4a6                	sd	s1,72(sp)
    80003be4:	e0ca                	sd	s2,64(sp)
    80003be6:	fc4e                	sd	s3,56(sp)
    80003be8:	f852                	sd	s4,48(sp)
    80003bea:	f456                	sd	s5,40(sp)
    80003bec:	f05a                	sd	s6,32(sp)
    80003bee:	ec5e                	sd	s7,24(sp)
    80003bf0:	e862                	sd	s8,16(sp)
    80003bf2:	e466                	sd	s9,8(sp)
    80003bf4:	1080                	addi	s0,sp,96
    80003bf6:	84aa                	mv	s1,a0
    80003bf8:	8b2e                	mv	s6,a1
    80003bfa:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003bfc:	00054703          	lbu	a4,0(a0)
    80003c00:	02f00793          	li	a5,47
    80003c04:	02f70363          	beq	a4,a5,80003c2a <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003c08:	ffffe097          	auipc	ra,0xffffe
    80003c0c:	e22080e7          	jalr	-478(ra) # 80001a2a <myproc>
    80003c10:	15053503          	ld	a0,336(a0)
    80003c14:	00000097          	auipc	ra,0x0
    80003c18:	9f6080e7          	jalr	-1546(ra) # 8000360a <idup>
    80003c1c:	89aa                	mv	s3,a0
  while(*path == '/')
    80003c1e:	02f00913          	li	s2,47
  len = path - s;
    80003c22:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80003c24:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003c26:	4c05                	li	s8,1
    80003c28:	a865                	j	80003ce0 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003c2a:	4585                	li	a1,1
    80003c2c:	4505                	li	a0,1
    80003c2e:	fffff097          	auipc	ra,0xfffff
    80003c32:	6e6080e7          	jalr	1766(ra) # 80003314 <iget>
    80003c36:	89aa                	mv	s3,a0
    80003c38:	b7dd                	j	80003c1e <namex+0x42>
      iunlockput(ip);
    80003c3a:	854e                	mv	a0,s3
    80003c3c:	00000097          	auipc	ra,0x0
    80003c40:	c6e080e7          	jalr	-914(ra) # 800038aa <iunlockput>
      return 0;
    80003c44:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003c46:	854e                	mv	a0,s3
    80003c48:	60e6                	ld	ra,88(sp)
    80003c4a:	6446                	ld	s0,80(sp)
    80003c4c:	64a6                	ld	s1,72(sp)
    80003c4e:	6906                	ld	s2,64(sp)
    80003c50:	79e2                	ld	s3,56(sp)
    80003c52:	7a42                	ld	s4,48(sp)
    80003c54:	7aa2                	ld	s5,40(sp)
    80003c56:	7b02                	ld	s6,32(sp)
    80003c58:	6be2                	ld	s7,24(sp)
    80003c5a:	6c42                	ld	s8,16(sp)
    80003c5c:	6ca2                	ld	s9,8(sp)
    80003c5e:	6125                	addi	sp,sp,96
    80003c60:	8082                	ret
      iunlock(ip);
    80003c62:	854e                	mv	a0,s3
    80003c64:	00000097          	auipc	ra,0x0
    80003c68:	aa6080e7          	jalr	-1370(ra) # 8000370a <iunlock>
      return ip;
    80003c6c:	bfe9                	j	80003c46 <namex+0x6a>
      iunlockput(ip);
    80003c6e:	854e                	mv	a0,s3
    80003c70:	00000097          	auipc	ra,0x0
    80003c74:	c3a080e7          	jalr	-966(ra) # 800038aa <iunlockput>
      return 0;
    80003c78:	89d2                	mv	s3,s4
    80003c7a:	b7f1                	j	80003c46 <namex+0x6a>
  len = path - s;
    80003c7c:	40b48633          	sub	a2,s1,a1
    80003c80:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80003c84:	094cd463          	bge	s9,s4,80003d0c <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003c88:	4639                	li	a2,14
    80003c8a:	8556                	mv	a0,s5
    80003c8c:	ffffd097          	auipc	ra,0xffffd
    80003c90:	0b4080e7          	jalr	180(ra) # 80000d40 <memmove>
  while(*path == '/')
    80003c94:	0004c783          	lbu	a5,0(s1)
    80003c98:	01279763          	bne	a5,s2,80003ca6 <namex+0xca>
    path++;
    80003c9c:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003c9e:	0004c783          	lbu	a5,0(s1)
    80003ca2:	ff278de3          	beq	a5,s2,80003c9c <namex+0xc0>
    ilock(ip);
    80003ca6:	854e                	mv	a0,s3
    80003ca8:	00000097          	auipc	ra,0x0
    80003cac:	9a0080e7          	jalr	-1632(ra) # 80003648 <ilock>
    if(ip->type != T_DIR){
    80003cb0:	04499783          	lh	a5,68(s3)
    80003cb4:	f98793e3          	bne	a5,s8,80003c3a <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003cb8:	000b0563          	beqz	s6,80003cc2 <namex+0xe6>
    80003cbc:	0004c783          	lbu	a5,0(s1)
    80003cc0:	d3cd                	beqz	a5,80003c62 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003cc2:	865e                	mv	a2,s7
    80003cc4:	85d6                	mv	a1,s5
    80003cc6:	854e                	mv	a0,s3
    80003cc8:	00000097          	auipc	ra,0x0
    80003ccc:	e64080e7          	jalr	-412(ra) # 80003b2c <dirlookup>
    80003cd0:	8a2a                	mv	s4,a0
    80003cd2:	dd51                	beqz	a0,80003c6e <namex+0x92>
    iunlockput(ip);
    80003cd4:	854e                	mv	a0,s3
    80003cd6:	00000097          	auipc	ra,0x0
    80003cda:	bd4080e7          	jalr	-1068(ra) # 800038aa <iunlockput>
    ip = next;
    80003cde:	89d2                	mv	s3,s4
  while(*path == '/')
    80003ce0:	0004c783          	lbu	a5,0(s1)
    80003ce4:	05279763          	bne	a5,s2,80003d32 <namex+0x156>
    path++;
    80003ce8:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003cea:	0004c783          	lbu	a5,0(s1)
    80003cee:	ff278de3          	beq	a5,s2,80003ce8 <namex+0x10c>
  if(*path == 0)
    80003cf2:	c79d                	beqz	a5,80003d20 <namex+0x144>
    path++;
    80003cf4:	85a6                	mv	a1,s1
  len = path - s;
    80003cf6:	8a5e                	mv	s4,s7
    80003cf8:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80003cfa:	01278963          	beq	a5,s2,80003d0c <namex+0x130>
    80003cfe:	dfbd                	beqz	a5,80003c7c <namex+0xa0>
    path++;
    80003d00:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003d02:	0004c783          	lbu	a5,0(s1)
    80003d06:	ff279ce3          	bne	a5,s2,80003cfe <namex+0x122>
    80003d0a:	bf8d                	j	80003c7c <namex+0xa0>
    memmove(name, s, len);
    80003d0c:	2601                	sext.w	a2,a2
    80003d0e:	8556                	mv	a0,s5
    80003d10:	ffffd097          	auipc	ra,0xffffd
    80003d14:	030080e7          	jalr	48(ra) # 80000d40 <memmove>
    name[len] = 0;
    80003d18:	9a56                	add	s4,s4,s5
    80003d1a:	000a0023          	sb	zero,0(s4)
    80003d1e:	bf9d                	j	80003c94 <namex+0xb8>
  if(nameiparent){
    80003d20:	f20b03e3          	beqz	s6,80003c46 <namex+0x6a>
    iput(ip);
    80003d24:	854e                	mv	a0,s3
    80003d26:	00000097          	auipc	ra,0x0
    80003d2a:	adc080e7          	jalr	-1316(ra) # 80003802 <iput>
    return 0;
    80003d2e:	4981                	li	s3,0
    80003d30:	bf19                	j	80003c46 <namex+0x6a>
  if(*path == 0)
    80003d32:	d7fd                	beqz	a5,80003d20 <namex+0x144>
  while(*path != '/' && *path != 0)
    80003d34:	0004c783          	lbu	a5,0(s1)
    80003d38:	85a6                	mv	a1,s1
    80003d3a:	b7d1                	j	80003cfe <namex+0x122>

0000000080003d3c <dirlink>:
{
    80003d3c:	7139                	addi	sp,sp,-64
    80003d3e:	fc06                	sd	ra,56(sp)
    80003d40:	f822                	sd	s0,48(sp)
    80003d42:	f426                	sd	s1,40(sp)
    80003d44:	f04a                	sd	s2,32(sp)
    80003d46:	ec4e                	sd	s3,24(sp)
    80003d48:	e852                	sd	s4,16(sp)
    80003d4a:	0080                	addi	s0,sp,64
    80003d4c:	892a                	mv	s2,a0
    80003d4e:	8a2e                	mv	s4,a1
    80003d50:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003d52:	4601                	li	a2,0
    80003d54:	00000097          	auipc	ra,0x0
    80003d58:	dd8080e7          	jalr	-552(ra) # 80003b2c <dirlookup>
    80003d5c:	e93d                	bnez	a0,80003dd2 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d5e:	04c92483          	lw	s1,76(s2)
    80003d62:	c49d                	beqz	s1,80003d90 <dirlink+0x54>
    80003d64:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003d66:	4741                	li	a4,16
    80003d68:	86a6                	mv	a3,s1
    80003d6a:	fc040613          	addi	a2,s0,-64
    80003d6e:	4581                	li	a1,0
    80003d70:	854a                	mv	a0,s2
    80003d72:	00000097          	auipc	ra,0x0
    80003d76:	b8a080e7          	jalr	-1142(ra) # 800038fc <readi>
    80003d7a:	47c1                	li	a5,16
    80003d7c:	06f51163          	bne	a0,a5,80003dde <dirlink+0xa2>
    if(de.inum == 0)
    80003d80:	fc045783          	lhu	a5,-64(s0)
    80003d84:	c791                	beqz	a5,80003d90 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d86:	24c1                	addiw	s1,s1,16
    80003d88:	04c92783          	lw	a5,76(s2)
    80003d8c:	fcf4ede3          	bltu	s1,a5,80003d66 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003d90:	4639                	li	a2,14
    80003d92:	85d2                	mv	a1,s4
    80003d94:	fc240513          	addi	a0,s0,-62
    80003d98:	ffffd097          	auipc	ra,0xffffd
    80003d9c:	05c080e7          	jalr	92(ra) # 80000df4 <strncpy>
  de.inum = inum;
    80003da0:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003da4:	4741                	li	a4,16
    80003da6:	86a6                	mv	a3,s1
    80003da8:	fc040613          	addi	a2,s0,-64
    80003dac:	4581                	li	a1,0
    80003dae:	854a                	mv	a0,s2
    80003db0:	00000097          	auipc	ra,0x0
    80003db4:	c44080e7          	jalr	-956(ra) # 800039f4 <writei>
    80003db8:	872a                	mv	a4,a0
    80003dba:	47c1                	li	a5,16
  return 0;
    80003dbc:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003dbe:	02f71863          	bne	a4,a5,80003dee <dirlink+0xb2>
}
    80003dc2:	70e2                	ld	ra,56(sp)
    80003dc4:	7442                	ld	s0,48(sp)
    80003dc6:	74a2                	ld	s1,40(sp)
    80003dc8:	7902                	ld	s2,32(sp)
    80003dca:	69e2                	ld	s3,24(sp)
    80003dcc:	6a42                	ld	s4,16(sp)
    80003dce:	6121                	addi	sp,sp,64
    80003dd0:	8082                	ret
    iput(ip);
    80003dd2:	00000097          	auipc	ra,0x0
    80003dd6:	a30080e7          	jalr	-1488(ra) # 80003802 <iput>
    return -1;
    80003dda:	557d                	li	a0,-1
    80003ddc:	b7dd                	j	80003dc2 <dirlink+0x86>
      panic("dirlink read");
    80003dde:	00005517          	auipc	a0,0x5
    80003de2:	83a50513          	addi	a0,a0,-1990 # 80008618 <syscalls+0x1c8>
    80003de6:	ffffc097          	auipc	ra,0xffffc
    80003dea:	758080e7          	jalr	1880(ra) # 8000053e <panic>
    panic("dirlink");
    80003dee:	00005517          	auipc	a0,0x5
    80003df2:	93a50513          	addi	a0,a0,-1734 # 80008728 <syscalls+0x2d8>
    80003df6:	ffffc097          	auipc	ra,0xffffc
    80003dfa:	748080e7          	jalr	1864(ra) # 8000053e <panic>

0000000080003dfe <namei>:

struct inode*
namei(char *path)
{
    80003dfe:	1101                	addi	sp,sp,-32
    80003e00:	ec06                	sd	ra,24(sp)
    80003e02:	e822                	sd	s0,16(sp)
    80003e04:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003e06:	fe040613          	addi	a2,s0,-32
    80003e0a:	4581                	li	a1,0
    80003e0c:	00000097          	auipc	ra,0x0
    80003e10:	dd0080e7          	jalr	-560(ra) # 80003bdc <namex>
}
    80003e14:	60e2                	ld	ra,24(sp)
    80003e16:	6442                	ld	s0,16(sp)
    80003e18:	6105                	addi	sp,sp,32
    80003e1a:	8082                	ret

0000000080003e1c <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003e1c:	1141                	addi	sp,sp,-16
    80003e1e:	e406                	sd	ra,8(sp)
    80003e20:	e022                	sd	s0,0(sp)
    80003e22:	0800                	addi	s0,sp,16
    80003e24:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80003e26:	4585                	li	a1,1
    80003e28:	00000097          	auipc	ra,0x0
    80003e2c:	db4080e7          	jalr	-588(ra) # 80003bdc <namex>
}
    80003e30:	60a2                	ld	ra,8(sp)
    80003e32:	6402                	ld	s0,0(sp)
    80003e34:	0141                	addi	sp,sp,16
    80003e36:	8082                	ret

0000000080003e38 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80003e38:	1101                	addi	sp,sp,-32
    80003e3a:	ec06                	sd	ra,24(sp)
    80003e3c:	e822                	sd	s0,16(sp)
    80003e3e:	e426                	sd	s1,8(sp)
    80003e40:	e04a                	sd	s2,0(sp)
    80003e42:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80003e44:	00024917          	auipc	s2,0x24
    80003e48:	42c90913          	addi	s2,s2,1068 # 80028270 <log>
    80003e4c:	01892583          	lw	a1,24(s2)
    80003e50:	02892503          	lw	a0,40(s2)
    80003e54:	fffff097          	auipc	ra,0xfffff
    80003e58:	ff2080e7          	jalr	-14(ra) # 80002e46 <bread>
    80003e5c:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80003e5e:	02c92683          	lw	a3,44(s2)
    80003e62:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80003e64:	02d05763          	blez	a3,80003e92 <write_head+0x5a>
    80003e68:	00024797          	auipc	a5,0x24
    80003e6c:	43878793          	addi	a5,a5,1080 # 800282a0 <log+0x30>
    80003e70:	05c50713          	addi	a4,a0,92
    80003e74:	36fd                	addiw	a3,a3,-1
    80003e76:	1682                	slli	a3,a3,0x20
    80003e78:	9281                	srli	a3,a3,0x20
    80003e7a:	068a                	slli	a3,a3,0x2
    80003e7c:	00024617          	auipc	a2,0x24
    80003e80:	42860613          	addi	a2,a2,1064 # 800282a4 <log+0x34>
    80003e84:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80003e86:	4390                	lw	a2,0(a5)
    80003e88:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80003e8a:	0791                	addi	a5,a5,4
    80003e8c:	0711                	addi	a4,a4,4
    80003e8e:	fed79ce3          	bne	a5,a3,80003e86 <write_head+0x4e>
  }
  bwrite(buf);
    80003e92:	8526                	mv	a0,s1
    80003e94:	fffff097          	auipc	ra,0xfffff
    80003e98:	0a4080e7          	jalr	164(ra) # 80002f38 <bwrite>
  brelse(buf);
    80003e9c:	8526                	mv	a0,s1
    80003e9e:	fffff097          	auipc	ra,0xfffff
    80003ea2:	0d8080e7          	jalr	216(ra) # 80002f76 <brelse>
}
    80003ea6:	60e2                	ld	ra,24(sp)
    80003ea8:	6442                	ld	s0,16(sp)
    80003eaa:	64a2                	ld	s1,8(sp)
    80003eac:	6902                	ld	s2,0(sp)
    80003eae:	6105                	addi	sp,sp,32
    80003eb0:	8082                	ret

0000000080003eb2 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80003eb2:	00024797          	auipc	a5,0x24
    80003eb6:	3ea7a783          	lw	a5,1002(a5) # 8002829c <log+0x2c>
    80003eba:	0af05d63          	blez	a5,80003f74 <install_trans+0xc2>
{
    80003ebe:	7139                	addi	sp,sp,-64
    80003ec0:	fc06                	sd	ra,56(sp)
    80003ec2:	f822                	sd	s0,48(sp)
    80003ec4:	f426                	sd	s1,40(sp)
    80003ec6:	f04a                	sd	s2,32(sp)
    80003ec8:	ec4e                	sd	s3,24(sp)
    80003eca:	e852                	sd	s4,16(sp)
    80003ecc:	e456                	sd	s5,8(sp)
    80003ece:	e05a                	sd	s6,0(sp)
    80003ed0:	0080                	addi	s0,sp,64
    80003ed2:	8b2a                	mv	s6,a0
    80003ed4:	00024a97          	auipc	s5,0x24
    80003ed8:	3cca8a93          	addi	s5,s5,972 # 800282a0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003edc:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80003ede:	00024997          	auipc	s3,0x24
    80003ee2:	39298993          	addi	s3,s3,914 # 80028270 <log>
    80003ee6:	a035                	j	80003f12 <install_trans+0x60>
      bunpin(dbuf);
    80003ee8:	8526                	mv	a0,s1
    80003eea:	fffff097          	auipc	ra,0xfffff
    80003eee:	166080e7          	jalr	358(ra) # 80003050 <bunpin>
    brelse(lbuf);
    80003ef2:	854a                	mv	a0,s2
    80003ef4:	fffff097          	auipc	ra,0xfffff
    80003ef8:	082080e7          	jalr	130(ra) # 80002f76 <brelse>
    brelse(dbuf);
    80003efc:	8526                	mv	a0,s1
    80003efe:	fffff097          	auipc	ra,0xfffff
    80003f02:	078080e7          	jalr	120(ra) # 80002f76 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003f06:	2a05                	addiw	s4,s4,1
    80003f08:	0a91                	addi	s5,s5,4
    80003f0a:	02c9a783          	lw	a5,44(s3)
    80003f0e:	04fa5963          	bge	s4,a5,80003f60 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80003f12:	0189a583          	lw	a1,24(s3)
    80003f16:	014585bb          	addw	a1,a1,s4
    80003f1a:	2585                	addiw	a1,a1,1
    80003f1c:	0289a503          	lw	a0,40(s3)
    80003f20:	fffff097          	auipc	ra,0xfffff
    80003f24:	f26080e7          	jalr	-218(ra) # 80002e46 <bread>
    80003f28:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80003f2a:	000aa583          	lw	a1,0(s5)
    80003f2e:	0289a503          	lw	a0,40(s3)
    80003f32:	fffff097          	auipc	ra,0xfffff
    80003f36:	f14080e7          	jalr	-236(ra) # 80002e46 <bread>
    80003f3a:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80003f3c:	40000613          	li	a2,1024
    80003f40:	05890593          	addi	a1,s2,88
    80003f44:	05850513          	addi	a0,a0,88
    80003f48:	ffffd097          	auipc	ra,0xffffd
    80003f4c:	df8080e7          	jalr	-520(ra) # 80000d40 <memmove>
    bwrite(dbuf);  // write dst to disk
    80003f50:	8526                	mv	a0,s1
    80003f52:	fffff097          	auipc	ra,0xfffff
    80003f56:	fe6080e7          	jalr	-26(ra) # 80002f38 <bwrite>
    if(recovering == 0)
    80003f5a:	f80b1ce3          	bnez	s6,80003ef2 <install_trans+0x40>
    80003f5e:	b769                	j	80003ee8 <install_trans+0x36>
}
    80003f60:	70e2                	ld	ra,56(sp)
    80003f62:	7442                	ld	s0,48(sp)
    80003f64:	74a2                	ld	s1,40(sp)
    80003f66:	7902                	ld	s2,32(sp)
    80003f68:	69e2                	ld	s3,24(sp)
    80003f6a:	6a42                	ld	s4,16(sp)
    80003f6c:	6aa2                	ld	s5,8(sp)
    80003f6e:	6b02                	ld	s6,0(sp)
    80003f70:	6121                	addi	sp,sp,64
    80003f72:	8082                	ret
    80003f74:	8082                	ret

0000000080003f76 <initlog>:
{
    80003f76:	7179                	addi	sp,sp,-48
    80003f78:	f406                	sd	ra,40(sp)
    80003f7a:	f022                	sd	s0,32(sp)
    80003f7c:	ec26                	sd	s1,24(sp)
    80003f7e:	e84a                	sd	s2,16(sp)
    80003f80:	e44e                	sd	s3,8(sp)
    80003f82:	1800                	addi	s0,sp,48
    80003f84:	892a                	mv	s2,a0
    80003f86:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80003f88:	00024497          	auipc	s1,0x24
    80003f8c:	2e848493          	addi	s1,s1,744 # 80028270 <log>
    80003f90:	00004597          	auipc	a1,0x4
    80003f94:	69858593          	addi	a1,a1,1688 # 80008628 <syscalls+0x1d8>
    80003f98:	8526                	mv	a0,s1
    80003f9a:	ffffd097          	auipc	ra,0xffffd
    80003f9e:	bba080e7          	jalr	-1094(ra) # 80000b54 <initlock>
  log.start = sb->logstart;
    80003fa2:	0149a583          	lw	a1,20(s3)
    80003fa6:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80003fa8:	0109a783          	lw	a5,16(s3)
    80003fac:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80003fae:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80003fb2:	854a                	mv	a0,s2
    80003fb4:	fffff097          	auipc	ra,0xfffff
    80003fb8:	e92080e7          	jalr	-366(ra) # 80002e46 <bread>
  log.lh.n = lh->n;
    80003fbc:	4d3c                	lw	a5,88(a0)
    80003fbe:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80003fc0:	02f05563          	blez	a5,80003fea <initlog+0x74>
    80003fc4:	05c50713          	addi	a4,a0,92
    80003fc8:	00024697          	auipc	a3,0x24
    80003fcc:	2d868693          	addi	a3,a3,728 # 800282a0 <log+0x30>
    80003fd0:	37fd                	addiw	a5,a5,-1
    80003fd2:	1782                	slli	a5,a5,0x20
    80003fd4:	9381                	srli	a5,a5,0x20
    80003fd6:	078a                	slli	a5,a5,0x2
    80003fd8:	06050613          	addi	a2,a0,96
    80003fdc:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    80003fde:	4310                	lw	a2,0(a4)
    80003fe0:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    80003fe2:	0711                	addi	a4,a4,4
    80003fe4:	0691                	addi	a3,a3,4
    80003fe6:	fef71ce3          	bne	a4,a5,80003fde <initlog+0x68>
  brelse(buf);
    80003fea:	fffff097          	auipc	ra,0xfffff
    80003fee:	f8c080e7          	jalr	-116(ra) # 80002f76 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80003ff2:	4505                	li	a0,1
    80003ff4:	00000097          	auipc	ra,0x0
    80003ff8:	ebe080e7          	jalr	-322(ra) # 80003eb2 <install_trans>
  log.lh.n = 0;
    80003ffc:	00024797          	auipc	a5,0x24
    80004000:	2a07a023          	sw	zero,672(a5) # 8002829c <log+0x2c>
  write_head(); // clear the log
    80004004:	00000097          	auipc	ra,0x0
    80004008:	e34080e7          	jalr	-460(ra) # 80003e38 <write_head>
}
    8000400c:	70a2                	ld	ra,40(sp)
    8000400e:	7402                	ld	s0,32(sp)
    80004010:	64e2                	ld	s1,24(sp)
    80004012:	6942                	ld	s2,16(sp)
    80004014:	69a2                	ld	s3,8(sp)
    80004016:	6145                	addi	sp,sp,48
    80004018:	8082                	ret

000000008000401a <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    8000401a:	1101                	addi	sp,sp,-32
    8000401c:	ec06                	sd	ra,24(sp)
    8000401e:	e822                	sd	s0,16(sp)
    80004020:	e426                	sd	s1,8(sp)
    80004022:	e04a                	sd	s2,0(sp)
    80004024:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004026:	00024517          	auipc	a0,0x24
    8000402a:	24a50513          	addi	a0,a0,586 # 80028270 <log>
    8000402e:	ffffd097          	auipc	ra,0xffffd
    80004032:	bb6080e7          	jalr	-1098(ra) # 80000be4 <acquire>
  while(1){
    if(log.committing){
    80004036:	00024497          	auipc	s1,0x24
    8000403a:	23a48493          	addi	s1,s1,570 # 80028270 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000403e:	4979                	li	s2,30
    80004040:	a039                	j	8000404e <begin_op+0x34>
      sleep(&log, &log.lock);
    80004042:	85a6                	mv	a1,s1
    80004044:	8526                	mv	a0,s1
    80004046:	ffffe097          	auipc	ra,0xffffe
    8000404a:	0a0080e7          	jalr	160(ra) # 800020e6 <sleep>
    if(log.committing){
    8000404e:	50dc                	lw	a5,36(s1)
    80004050:	fbed                	bnez	a5,80004042 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004052:	509c                	lw	a5,32(s1)
    80004054:	0017871b          	addiw	a4,a5,1
    80004058:	0007069b          	sext.w	a3,a4
    8000405c:	0027179b          	slliw	a5,a4,0x2
    80004060:	9fb9                	addw	a5,a5,a4
    80004062:	0017979b          	slliw	a5,a5,0x1
    80004066:	54d8                	lw	a4,44(s1)
    80004068:	9fb9                	addw	a5,a5,a4
    8000406a:	00f95963          	bge	s2,a5,8000407c <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    8000406e:	85a6                	mv	a1,s1
    80004070:	8526                	mv	a0,s1
    80004072:	ffffe097          	auipc	ra,0xffffe
    80004076:	074080e7          	jalr	116(ra) # 800020e6 <sleep>
    8000407a:	bfd1                	j	8000404e <begin_op+0x34>
    } else {
      log.outstanding += 1;
    8000407c:	00024517          	auipc	a0,0x24
    80004080:	1f450513          	addi	a0,a0,500 # 80028270 <log>
    80004084:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004086:	ffffd097          	auipc	ra,0xffffd
    8000408a:	c12080e7          	jalr	-1006(ra) # 80000c98 <release>
      break;
    }
  }
}
    8000408e:	60e2                	ld	ra,24(sp)
    80004090:	6442                	ld	s0,16(sp)
    80004092:	64a2                	ld	s1,8(sp)
    80004094:	6902                	ld	s2,0(sp)
    80004096:	6105                	addi	sp,sp,32
    80004098:	8082                	ret

000000008000409a <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    8000409a:	7139                	addi	sp,sp,-64
    8000409c:	fc06                	sd	ra,56(sp)
    8000409e:	f822                	sd	s0,48(sp)
    800040a0:	f426                	sd	s1,40(sp)
    800040a2:	f04a                	sd	s2,32(sp)
    800040a4:	ec4e                	sd	s3,24(sp)
    800040a6:	e852                	sd	s4,16(sp)
    800040a8:	e456                	sd	s5,8(sp)
    800040aa:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    800040ac:	00024497          	auipc	s1,0x24
    800040b0:	1c448493          	addi	s1,s1,452 # 80028270 <log>
    800040b4:	8526                	mv	a0,s1
    800040b6:	ffffd097          	auipc	ra,0xffffd
    800040ba:	b2e080e7          	jalr	-1234(ra) # 80000be4 <acquire>
  log.outstanding -= 1;
    800040be:	509c                	lw	a5,32(s1)
    800040c0:	37fd                	addiw	a5,a5,-1
    800040c2:	0007891b          	sext.w	s2,a5
    800040c6:	d09c                	sw	a5,32(s1)
  if(log.committing)
    800040c8:	50dc                	lw	a5,36(s1)
    800040ca:	efb9                	bnez	a5,80004128 <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    800040cc:	06091663          	bnez	s2,80004138 <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    800040d0:	00024497          	auipc	s1,0x24
    800040d4:	1a048493          	addi	s1,s1,416 # 80028270 <log>
    800040d8:	4785                	li	a5,1
    800040da:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800040dc:	8526                	mv	a0,s1
    800040de:	ffffd097          	auipc	ra,0xffffd
    800040e2:	bba080e7          	jalr	-1094(ra) # 80000c98 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800040e6:	54dc                	lw	a5,44(s1)
    800040e8:	06f04763          	bgtz	a5,80004156 <end_op+0xbc>
    acquire(&log.lock);
    800040ec:	00024497          	auipc	s1,0x24
    800040f0:	18448493          	addi	s1,s1,388 # 80028270 <log>
    800040f4:	8526                	mv	a0,s1
    800040f6:	ffffd097          	auipc	ra,0xffffd
    800040fa:	aee080e7          	jalr	-1298(ra) # 80000be4 <acquire>
    log.committing = 0;
    800040fe:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004102:	8526                	mv	a0,s1
    80004104:	ffffe097          	auipc	ra,0xffffe
    80004108:	16e080e7          	jalr	366(ra) # 80002272 <wakeup>
    release(&log.lock);
    8000410c:	8526                	mv	a0,s1
    8000410e:	ffffd097          	auipc	ra,0xffffd
    80004112:	b8a080e7          	jalr	-1142(ra) # 80000c98 <release>
}
    80004116:	70e2                	ld	ra,56(sp)
    80004118:	7442                	ld	s0,48(sp)
    8000411a:	74a2                	ld	s1,40(sp)
    8000411c:	7902                	ld	s2,32(sp)
    8000411e:	69e2                	ld	s3,24(sp)
    80004120:	6a42                	ld	s4,16(sp)
    80004122:	6aa2                	ld	s5,8(sp)
    80004124:	6121                	addi	sp,sp,64
    80004126:	8082                	ret
    panic("log.committing");
    80004128:	00004517          	auipc	a0,0x4
    8000412c:	50850513          	addi	a0,a0,1288 # 80008630 <syscalls+0x1e0>
    80004130:	ffffc097          	auipc	ra,0xffffc
    80004134:	40e080e7          	jalr	1038(ra) # 8000053e <panic>
    wakeup(&log);
    80004138:	00024497          	auipc	s1,0x24
    8000413c:	13848493          	addi	s1,s1,312 # 80028270 <log>
    80004140:	8526                	mv	a0,s1
    80004142:	ffffe097          	auipc	ra,0xffffe
    80004146:	130080e7          	jalr	304(ra) # 80002272 <wakeup>
  release(&log.lock);
    8000414a:	8526                	mv	a0,s1
    8000414c:	ffffd097          	auipc	ra,0xffffd
    80004150:	b4c080e7          	jalr	-1204(ra) # 80000c98 <release>
  if(do_commit){
    80004154:	b7c9                	j	80004116 <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004156:	00024a97          	auipc	s5,0x24
    8000415a:	14aa8a93          	addi	s5,s5,330 # 800282a0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    8000415e:	00024a17          	auipc	s4,0x24
    80004162:	112a0a13          	addi	s4,s4,274 # 80028270 <log>
    80004166:	018a2583          	lw	a1,24(s4)
    8000416a:	012585bb          	addw	a1,a1,s2
    8000416e:	2585                	addiw	a1,a1,1
    80004170:	028a2503          	lw	a0,40(s4)
    80004174:	fffff097          	auipc	ra,0xfffff
    80004178:	cd2080e7          	jalr	-814(ra) # 80002e46 <bread>
    8000417c:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    8000417e:	000aa583          	lw	a1,0(s5)
    80004182:	028a2503          	lw	a0,40(s4)
    80004186:	fffff097          	auipc	ra,0xfffff
    8000418a:	cc0080e7          	jalr	-832(ra) # 80002e46 <bread>
    8000418e:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004190:	40000613          	li	a2,1024
    80004194:	05850593          	addi	a1,a0,88
    80004198:	05848513          	addi	a0,s1,88
    8000419c:	ffffd097          	auipc	ra,0xffffd
    800041a0:	ba4080e7          	jalr	-1116(ra) # 80000d40 <memmove>
    bwrite(to);  // write the log
    800041a4:	8526                	mv	a0,s1
    800041a6:	fffff097          	auipc	ra,0xfffff
    800041aa:	d92080e7          	jalr	-622(ra) # 80002f38 <bwrite>
    brelse(from);
    800041ae:	854e                	mv	a0,s3
    800041b0:	fffff097          	auipc	ra,0xfffff
    800041b4:	dc6080e7          	jalr	-570(ra) # 80002f76 <brelse>
    brelse(to);
    800041b8:	8526                	mv	a0,s1
    800041ba:	fffff097          	auipc	ra,0xfffff
    800041be:	dbc080e7          	jalr	-580(ra) # 80002f76 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800041c2:	2905                	addiw	s2,s2,1
    800041c4:	0a91                	addi	s5,s5,4
    800041c6:	02ca2783          	lw	a5,44(s4)
    800041ca:	f8f94ee3          	blt	s2,a5,80004166 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    800041ce:	00000097          	auipc	ra,0x0
    800041d2:	c6a080e7          	jalr	-918(ra) # 80003e38 <write_head>
    install_trans(0); // Now install writes to home locations
    800041d6:	4501                	li	a0,0
    800041d8:	00000097          	auipc	ra,0x0
    800041dc:	cda080e7          	jalr	-806(ra) # 80003eb2 <install_trans>
    log.lh.n = 0;
    800041e0:	00024797          	auipc	a5,0x24
    800041e4:	0a07ae23          	sw	zero,188(a5) # 8002829c <log+0x2c>
    write_head();    // Erase the transaction from the log
    800041e8:	00000097          	auipc	ra,0x0
    800041ec:	c50080e7          	jalr	-944(ra) # 80003e38 <write_head>
    800041f0:	bdf5                	j	800040ec <end_op+0x52>

00000000800041f2 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800041f2:	1101                	addi	sp,sp,-32
    800041f4:	ec06                	sd	ra,24(sp)
    800041f6:	e822                	sd	s0,16(sp)
    800041f8:	e426                	sd	s1,8(sp)
    800041fa:	e04a                	sd	s2,0(sp)
    800041fc:	1000                	addi	s0,sp,32
    800041fe:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004200:	00024917          	auipc	s2,0x24
    80004204:	07090913          	addi	s2,s2,112 # 80028270 <log>
    80004208:	854a                	mv	a0,s2
    8000420a:	ffffd097          	auipc	ra,0xffffd
    8000420e:	9da080e7          	jalr	-1574(ra) # 80000be4 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004212:	02c92603          	lw	a2,44(s2)
    80004216:	47f5                	li	a5,29
    80004218:	06c7c563          	blt	a5,a2,80004282 <log_write+0x90>
    8000421c:	00024797          	auipc	a5,0x24
    80004220:	0707a783          	lw	a5,112(a5) # 8002828c <log+0x1c>
    80004224:	37fd                	addiw	a5,a5,-1
    80004226:	04f65e63          	bge	a2,a5,80004282 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    8000422a:	00024797          	auipc	a5,0x24
    8000422e:	0667a783          	lw	a5,102(a5) # 80028290 <log+0x20>
    80004232:	06f05063          	blez	a5,80004292 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004236:	4781                	li	a5,0
    80004238:	06c05563          	blez	a2,800042a2 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    8000423c:	44cc                	lw	a1,12(s1)
    8000423e:	00024717          	auipc	a4,0x24
    80004242:	06270713          	addi	a4,a4,98 # 800282a0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004246:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004248:	4314                	lw	a3,0(a4)
    8000424a:	04b68c63          	beq	a3,a1,800042a2 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    8000424e:	2785                	addiw	a5,a5,1
    80004250:	0711                	addi	a4,a4,4
    80004252:	fef61be3          	bne	a2,a5,80004248 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004256:	0621                	addi	a2,a2,8
    80004258:	060a                	slli	a2,a2,0x2
    8000425a:	00024797          	auipc	a5,0x24
    8000425e:	01678793          	addi	a5,a5,22 # 80028270 <log>
    80004262:	963e                	add	a2,a2,a5
    80004264:	44dc                	lw	a5,12(s1)
    80004266:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004268:	8526                	mv	a0,s1
    8000426a:	fffff097          	auipc	ra,0xfffff
    8000426e:	daa080e7          	jalr	-598(ra) # 80003014 <bpin>
    log.lh.n++;
    80004272:	00024717          	auipc	a4,0x24
    80004276:	ffe70713          	addi	a4,a4,-2 # 80028270 <log>
    8000427a:	575c                	lw	a5,44(a4)
    8000427c:	2785                	addiw	a5,a5,1
    8000427e:	d75c                	sw	a5,44(a4)
    80004280:	a835                	j	800042bc <log_write+0xca>
    panic("too big a transaction");
    80004282:	00004517          	auipc	a0,0x4
    80004286:	3be50513          	addi	a0,a0,958 # 80008640 <syscalls+0x1f0>
    8000428a:	ffffc097          	auipc	ra,0xffffc
    8000428e:	2b4080e7          	jalr	692(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    80004292:	00004517          	auipc	a0,0x4
    80004296:	3c650513          	addi	a0,a0,966 # 80008658 <syscalls+0x208>
    8000429a:	ffffc097          	auipc	ra,0xffffc
    8000429e:	2a4080e7          	jalr	676(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    800042a2:	00878713          	addi	a4,a5,8
    800042a6:	00271693          	slli	a3,a4,0x2
    800042aa:	00024717          	auipc	a4,0x24
    800042ae:	fc670713          	addi	a4,a4,-58 # 80028270 <log>
    800042b2:	9736                	add	a4,a4,a3
    800042b4:	44d4                	lw	a3,12(s1)
    800042b6:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    800042b8:	faf608e3          	beq	a2,a5,80004268 <log_write+0x76>
  }
  release(&log.lock);
    800042bc:	00024517          	auipc	a0,0x24
    800042c0:	fb450513          	addi	a0,a0,-76 # 80028270 <log>
    800042c4:	ffffd097          	auipc	ra,0xffffd
    800042c8:	9d4080e7          	jalr	-1580(ra) # 80000c98 <release>
}
    800042cc:	60e2                	ld	ra,24(sp)
    800042ce:	6442                	ld	s0,16(sp)
    800042d0:	64a2                	ld	s1,8(sp)
    800042d2:	6902                	ld	s2,0(sp)
    800042d4:	6105                	addi	sp,sp,32
    800042d6:	8082                	ret

00000000800042d8 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    800042d8:	1101                	addi	sp,sp,-32
    800042da:	ec06                	sd	ra,24(sp)
    800042dc:	e822                	sd	s0,16(sp)
    800042de:	e426                	sd	s1,8(sp)
    800042e0:	e04a                	sd	s2,0(sp)
    800042e2:	1000                	addi	s0,sp,32
    800042e4:	84aa                	mv	s1,a0
    800042e6:	892e                	mv	s2,a1
	initlock(&lk->lk, "sleep lock");
    800042e8:	00004597          	auipc	a1,0x4
    800042ec:	39058593          	addi	a1,a1,912 # 80008678 <syscalls+0x228>
    800042f0:	0521                	addi	a0,a0,8
    800042f2:	ffffd097          	auipc	ra,0xffffd
    800042f6:	862080e7          	jalr	-1950(ra) # 80000b54 <initlock>
	lk->name = name;
    800042fa:	0324b023          	sd	s2,32(s1)
	lk->locked = 0;
    800042fe:	0004a023          	sw	zero,0(s1)
	lk->pid = 0;
    80004302:	0204a423          	sw	zero,40(s1)
}
    80004306:	60e2                	ld	ra,24(sp)
    80004308:	6442                	ld	s0,16(sp)
    8000430a:	64a2                	ld	s1,8(sp)
    8000430c:	6902                	ld	s2,0(sp)
    8000430e:	6105                	addi	sp,sp,32
    80004310:	8082                	ret

0000000080004312 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004312:	1101                	addi	sp,sp,-32
    80004314:	ec06                	sd	ra,24(sp)
    80004316:	e822                	sd	s0,16(sp)
    80004318:	e426                	sd	s1,8(sp)
    8000431a:	e04a                	sd	s2,0(sp)
    8000431c:	1000                	addi	s0,sp,32
    8000431e:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004320:	00850913          	addi	s2,a0,8
    80004324:	854a                	mv	a0,s2
    80004326:	ffffd097          	auipc	ra,0xffffd
    8000432a:	8be080e7          	jalr	-1858(ra) # 80000be4 <acquire>
  while (lk->locked) {
    8000432e:	409c                	lw	a5,0(s1)
    80004330:	cb89                	beqz	a5,80004342 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004332:	85ca                	mv	a1,s2
    80004334:	8526                	mv	a0,s1
    80004336:	ffffe097          	auipc	ra,0xffffe
    8000433a:	db0080e7          	jalr	-592(ra) # 800020e6 <sleep>
  while (lk->locked) {
    8000433e:	409c                	lw	a5,0(s1)
    80004340:	fbed                	bnez	a5,80004332 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004342:	4785                	li	a5,1
    80004344:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004346:	ffffd097          	auipc	ra,0xffffd
    8000434a:	6e4080e7          	jalr	1764(ra) # 80001a2a <myproc>
    8000434e:	591c                	lw	a5,48(a0)
    80004350:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004352:	854a                	mv	a0,s2
    80004354:	ffffd097          	auipc	ra,0xffffd
    80004358:	944080e7          	jalr	-1724(ra) # 80000c98 <release>
}
    8000435c:	60e2                	ld	ra,24(sp)
    8000435e:	6442                	ld	s0,16(sp)
    80004360:	64a2                	ld	s1,8(sp)
    80004362:	6902                	ld	s2,0(sp)
    80004364:	6105                	addi	sp,sp,32
    80004366:	8082                	ret

0000000080004368 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004368:	1101                	addi	sp,sp,-32
    8000436a:	ec06                	sd	ra,24(sp)
    8000436c:	e822                	sd	s0,16(sp)
    8000436e:	e426                	sd	s1,8(sp)
    80004370:	e04a                	sd	s2,0(sp)
    80004372:	1000                	addi	s0,sp,32
    80004374:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004376:	00850913          	addi	s2,a0,8
    8000437a:	854a                	mv	a0,s2
    8000437c:	ffffd097          	auipc	ra,0xffffd
    80004380:	868080e7          	jalr	-1944(ra) # 80000be4 <acquire>
  lk->locked = 0;
    80004384:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004388:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    8000438c:	8526                	mv	a0,s1
    8000438e:	ffffe097          	auipc	ra,0xffffe
    80004392:	ee4080e7          	jalr	-284(ra) # 80002272 <wakeup>
  release(&lk->lk);
    80004396:	854a                	mv	a0,s2
    80004398:	ffffd097          	auipc	ra,0xffffd
    8000439c:	900080e7          	jalr	-1792(ra) # 80000c98 <release>
}
    800043a0:	60e2                	ld	ra,24(sp)
    800043a2:	6442                	ld	s0,16(sp)
    800043a4:	64a2                	ld	s1,8(sp)
    800043a6:	6902                	ld	s2,0(sp)
    800043a8:	6105                	addi	sp,sp,32
    800043aa:	8082                	ret

00000000800043ac <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    800043ac:	7179                	addi	sp,sp,-48
    800043ae:	f406                	sd	ra,40(sp)
    800043b0:	f022                	sd	s0,32(sp)
    800043b2:	ec26                	sd	s1,24(sp)
    800043b4:	e84a                	sd	s2,16(sp)
    800043b6:	e44e                	sd	s3,8(sp)
    800043b8:	1800                	addi	s0,sp,48
    800043ba:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    800043bc:	00850913          	addi	s2,a0,8
    800043c0:	854a                	mv	a0,s2
    800043c2:	ffffd097          	auipc	ra,0xffffd
    800043c6:	822080e7          	jalr	-2014(ra) # 80000be4 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    800043ca:	409c                	lw	a5,0(s1)
    800043cc:	ef99                	bnez	a5,800043ea <holdingsleep+0x3e>
    800043ce:	4481                	li	s1,0
  release(&lk->lk);
    800043d0:	854a                	mv	a0,s2
    800043d2:	ffffd097          	auipc	ra,0xffffd
    800043d6:	8c6080e7          	jalr	-1850(ra) # 80000c98 <release>
  return r;
}
    800043da:	8526                	mv	a0,s1
    800043dc:	70a2                	ld	ra,40(sp)
    800043de:	7402                	ld	s0,32(sp)
    800043e0:	64e2                	ld	s1,24(sp)
    800043e2:	6942                	ld	s2,16(sp)
    800043e4:	69a2                	ld	s3,8(sp)
    800043e6:	6145                	addi	sp,sp,48
    800043e8:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    800043ea:	0284a983          	lw	s3,40(s1)
    800043ee:	ffffd097          	auipc	ra,0xffffd
    800043f2:	63c080e7          	jalr	1596(ra) # 80001a2a <myproc>
    800043f6:	5904                	lw	s1,48(a0)
    800043f8:	413484b3          	sub	s1,s1,s3
    800043fc:	0014b493          	seqz	s1,s1
    80004400:	bfc1                	j	800043d0 <holdingsleep+0x24>

0000000080004402 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004402:	1141                	addi	sp,sp,-16
    80004404:	e406                	sd	ra,8(sp)
    80004406:	e022                	sd	s0,0(sp)
    80004408:	0800                	addi	s0,sp,16
	initlock(&ftable.lock, "ftable");
    8000440a:	00004597          	auipc	a1,0x4
    8000440e:	27e58593          	addi	a1,a1,638 # 80008688 <syscalls+0x238>
    80004412:	00024517          	auipc	a0,0x24
    80004416:	fa650513          	addi	a0,a0,-90 # 800283b8 <ftable>
    8000441a:	ffffc097          	auipc	ra,0xffffc
    8000441e:	73a080e7          	jalr	1850(ra) # 80000b54 <initlock>
}
    80004422:	60a2                	ld	ra,8(sp)
    80004424:	6402                	ld	s0,0(sp)
    80004426:	0141                	addi	sp,sp,16
    80004428:	8082                	ret

000000008000442a <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    8000442a:	1101                	addi	sp,sp,-32
    8000442c:	ec06                	sd	ra,24(sp)
    8000442e:	e822                	sd	s0,16(sp)
    80004430:	e426                	sd	s1,8(sp)
    80004432:	1000                	addi	s0,sp,32
	struct file *f;

	acquire(&ftable.lock);
    80004434:	00024517          	auipc	a0,0x24
    80004438:	f8450513          	addi	a0,a0,-124 # 800283b8 <ftable>
    8000443c:	ffffc097          	auipc	ra,0xffffc
    80004440:	7a8080e7          	jalr	1960(ra) # 80000be4 <acquire>
	for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004444:	00024497          	auipc	s1,0x24
    80004448:	f8c48493          	addi	s1,s1,-116 # 800283d0 <ftable+0x18>
    8000444c:	00025717          	auipc	a4,0x25
    80004450:	f2470713          	addi	a4,a4,-220 # 80029370 <ftable+0xfb8>
		if(f->ref == 0){
    80004454:	40dc                	lw	a5,4(s1)
    80004456:	cf99                	beqz	a5,80004474 <filealloc+0x4a>
	for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004458:	02848493          	addi	s1,s1,40
    8000445c:	fee49ce3          	bne	s1,a4,80004454 <filealloc+0x2a>
			f->ref = 1;
			release(&ftable.lock);
			return f;
		}
	}
	release(&ftable.lock);
    80004460:	00024517          	auipc	a0,0x24
    80004464:	f5850513          	addi	a0,a0,-168 # 800283b8 <ftable>
    80004468:	ffffd097          	auipc	ra,0xffffd
    8000446c:	830080e7          	jalr	-2000(ra) # 80000c98 <release>
	return 0;
    80004470:	4481                	li	s1,0
    80004472:	a819                	j	80004488 <filealloc+0x5e>
			f->ref = 1;
    80004474:	4785                	li	a5,1
    80004476:	c0dc                	sw	a5,4(s1)
			release(&ftable.lock);
    80004478:	00024517          	auipc	a0,0x24
    8000447c:	f4050513          	addi	a0,a0,-192 # 800283b8 <ftable>
    80004480:	ffffd097          	auipc	ra,0xffffd
    80004484:	818080e7          	jalr	-2024(ra) # 80000c98 <release>
}
    80004488:	8526                	mv	a0,s1
    8000448a:	60e2                	ld	ra,24(sp)
    8000448c:	6442                	ld	s0,16(sp)
    8000448e:	64a2                	ld	s1,8(sp)
    80004490:	6105                	addi	sp,sp,32
    80004492:	8082                	ret

0000000080004494 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004494:	1101                	addi	sp,sp,-32
    80004496:	ec06                	sd	ra,24(sp)
    80004498:	e822                	sd	s0,16(sp)
    8000449a:	e426                	sd	s1,8(sp)
    8000449c:	1000                	addi	s0,sp,32
    8000449e:	84aa                	mv	s1,a0
	acquire(&ftable.lock);
    800044a0:	00024517          	auipc	a0,0x24
    800044a4:	f1850513          	addi	a0,a0,-232 # 800283b8 <ftable>
    800044a8:	ffffc097          	auipc	ra,0xffffc
    800044ac:	73c080e7          	jalr	1852(ra) # 80000be4 <acquire>
	if(f->ref < 1)
    800044b0:	40dc                	lw	a5,4(s1)
    800044b2:	02f05263          	blez	a5,800044d6 <filedup+0x42>
		panic("filedup");
	f->ref++;
    800044b6:	2785                	addiw	a5,a5,1
    800044b8:	c0dc                	sw	a5,4(s1)
	release(&ftable.lock);
    800044ba:	00024517          	auipc	a0,0x24
    800044be:	efe50513          	addi	a0,a0,-258 # 800283b8 <ftable>
    800044c2:	ffffc097          	auipc	ra,0xffffc
    800044c6:	7d6080e7          	jalr	2006(ra) # 80000c98 <release>
	return f;
}
    800044ca:	8526                	mv	a0,s1
    800044cc:	60e2                	ld	ra,24(sp)
    800044ce:	6442                	ld	s0,16(sp)
    800044d0:	64a2                	ld	s1,8(sp)
    800044d2:	6105                	addi	sp,sp,32
    800044d4:	8082                	ret
		panic("filedup");
    800044d6:	00004517          	auipc	a0,0x4
    800044da:	1ba50513          	addi	a0,a0,442 # 80008690 <syscalls+0x240>
    800044de:	ffffc097          	auipc	ra,0xffffc
    800044e2:	060080e7          	jalr	96(ra) # 8000053e <panic>

00000000800044e6 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    800044e6:	7139                	addi	sp,sp,-64
    800044e8:	fc06                	sd	ra,56(sp)
    800044ea:	f822                	sd	s0,48(sp)
    800044ec:	f426                	sd	s1,40(sp)
    800044ee:	f04a                	sd	s2,32(sp)
    800044f0:	ec4e                	sd	s3,24(sp)
    800044f2:	e852                	sd	s4,16(sp)
    800044f4:	e456                	sd	s5,8(sp)
    800044f6:	0080                	addi	s0,sp,64
    800044f8:	84aa                	mv	s1,a0
	struct file ff;

	acquire(&ftable.lock);
    800044fa:	00024517          	auipc	a0,0x24
    800044fe:	ebe50513          	addi	a0,a0,-322 # 800283b8 <ftable>
    80004502:	ffffc097          	auipc	ra,0xffffc
    80004506:	6e2080e7          	jalr	1762(ra) # 80000be4 <acquire>
	if(f->ref < 1)
    8000450a:	40dc                	lw	a5,4(s1)
    8000450c:	06f05163          	blez	a5,8000456e <fileclose+0x88>
		panic("fileclose");
	if(--f->ref > 0){
    80004510:	37fd                	addiw	a5,a5,-1
    80004512:	0007871b          	sext.w	a4,a5
    80004516:	c0dc                	sw	a5,4(s1)
    80004518:	06e04363          	bgtz	a4,8000457e <fileclose+0x98>
		release(&ftable.lock);
		return;
	}
	ff = *f;
    8000451c:	0004a903          	lw	s2,0(s1)
    80004520:	0094ca83          	lbu	s5,9(s1)
    80004524:	0104ba03          	ld	s4,16(s1)
    80004528:	0184b983          	ld	s3,24(s1)
	f->ref = 0;
    8000452c:	0004a223          	sw	zero,4(s1)
	f->type = FD_NONE;
    80004530:	0004a023          	sw	zero,0(s1)
	release(&ftable.lock);
    80004534:	00024517          	auipc	a0,0x24
    80004538:	e8450513          	addi	a0,a0,-380 # 800283b8 <ftable>
    8000453c:	ffffc097          	auipc	ra,0xffffc
    80004540:	75c080e7          	jalr	1884(ra) # 80000c98 <release>

	if(ff.type == FD_PIPE){
    80004544:	4785                	li	a5,1
    80004546:	04f90d63          	beq	s2,a5,800045a0 <fileclose+0xba>
		pipeclose(ff.pipe, ff.writable);
	} else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    8000454a:	3979                	addiw	s2,s2,-2
    8000454c:	4785                	li	a5,1
    8000454e:	0527e063          	bltu	a5,s2,8000458e <fileclose+0xa8>
		begin_op();
    80004552:	00000097          	auipc	ra,0x0
    80004556:	ac8080e7          	jalr	-1336(ra) # 8000401a <begin_op>
		iput(ff.ip);
    8000455a:	854e                	mv	a0,s3
    8000455c:	fffff097          	auipc	ra,0xfffff
    80004560:	2a6080e7          	jalr	678(ra) # 80003802 <iput>
		end_op();
    80004564:	00000097          	auipc	ra,0x0
    80004568:	b36080e7          	jalr	-1226(ra) # 8000409a <end_op>
    8000456c:	a00d                	j	8000458e <fileclose+0xa8>
		panic("fileclose");
    8000456e:	00004517          	auipc	a0,0x4
    80004572:	12a50513          	addi	a0,a0,298 # 80008698 <syscalls+0x248>
    80004576:	ffffc097          	auipc	ra,0xffffc
    8000457a:	fc8080e7          	jalr	-56(ra) # 8000053e <panic>
		release(&ftable.lock);
    8000457e:	00024517          	auipc	a0,0x24
    80004582:	e3a50513          	addi	a0,a0,-454 # 800283b8 <ftable>
    80004586:	ffffc097          	auipc	ra,0xffffc
    8000458a:	712080e7          	jalr	1810(ra) # 80000c98 <release>
	}
}
    8000458e:	70e2                	ld	ra,56(sp)
    80004590:	7442                	ld	s0,48(sp)
    80004592:	74a2                	ld	s1,40(sp)
    80004594:	7902                	ld	s2,32(sp)
    80004596:	69e2                	ld	s3,24(sp)
    80004598:	6a42                	ld	s4,16(sp)
    8000459a:	6aa2                	ld	s5,8(sp)
    8000459c:	6121                	addi	sp,sp,64
    8000459e:	8082                	ret
		pipeclose(ff.pipe, ff.writable);
    800045a0:	85d6                	mv	a1,s5
    800045a2:	8552                	mv	a0,s4
    800045a4:	00000097          	auipc	ra,0x0
    800045a8:	34c080e7          	jalr	844(ra) # 800048f0 <pipeclose>
    800045ac:	b7cd                	j	8000458e <fileclose+0xa8>

00000000800045ae <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    800045ae:	715d                	addi	sp,sp,-80
    800045b0:	e486                	sd	ra,72(sp)
    800045b2:	e0a2                	sd	s0,64(sp)
    800045b4:	fc26                	sd	s1,56(sp)
    800045b6:	f84a                	sd	s2,48(sp)
    800045b8:	f44e                	sd	s3,40(sp)
    800045ba:	0880                	addi	s0,sp,80
    800045bc:	84aa                	mv	s1,a0
    800045be:	89ae                	mv	s3,a1
	struct proc *p = myproc();
    800045c0:	ffffd097          	auipc	ra,0xffffd
    800045c4:	46a080e7          	jalr	1130(ra) # 80001a2a <myproc>
	struct stat st;

	if(f->type == FD_INODE || f->type == FD_DEVICE){
    800045c8:	409c                	lw	a5,0(s1)
    800045ca:	37f9                	addiw	a5,a5,-2
    800045cc:	4705                	li	a4,1
    800045ce:	04f76763          	bltu	a4,a5,8000461c <filestat+0x6e>
    800045d2:	892a                	mv	s2,a0
		ilock(f->ip);
    800045d4:	6c88                	ld	a0,24(s1)
    800045d6:	fffff097          	auipc	ra,0xfffff
    800045da:	072080e7          	jalr	114(ra) # 80003648 <ilock>
		stati(f->ip, &st);
    800045de:	fb840593          	addi	a1,s0,-72
    800045e2:	6c88                	ld	a0,24(s1)
    800045e4:	fffff097          	auipc	ra,0xfffff
    800045e8:	2ee080e7          	jalr	750(ra) # 800038d2 <stati>
		iunlock(f->ip);
    800045ec:	6c88                	ld	a0,24(s1)
    800045ee:	fffff097          	auipc	ra,0xfffff
    800045f2:	11c080e7          	jalr	284(ra) # 8000370a <iunlock>
		if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    800045f6:	46e1                	li	a3,24
    800045f8:	fb840613          	addi	a2,s0,-72
    800045fc:	85ce                	mv	a1,s3
    800045fe:	05093503          	ld	a0,80(s2)
    80004602:	ffffd097          	auipc	ra,0xffffd
    80004606:	06e080e7          	jalr	110(ra) # 80001670 <copyout>
    8000460a:	41f5551b          	sraiw	a0,a0,0x1f
			return -1;
		return 0;
	}
	return -1;
}
    8000460e:	60a6                	ld	ra,72(sp)
    80004610:	6406                	ld	s0,64(sp)
    80004612:	74e2                	ld	s1,56(sp)
    80004614:	7942                	ld	s2,48(sp)
    80004616:	79a2                	ld	s3,40(sp)
    80004618:	6161                	addi	sp,sp,80
    8000461a:	8082                	ret
	return -1;
    8000461c:	557d                	li	a0,-1
    8000461e:	bfc5                	j	8000460e <filestat+0x60>

0000000080004620 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004620:	7179                	addi	sp,sp,-48
    80004622:	f406                	sd	ra,40(sp)
    80004624:	f022                	sd	s0,32(sp)
    80004626:	ec26                	sd	s1,24(sp)
    80004628:	e84a                	sd	s2,16(sp)
    8000462a:	e44e                	sd	s3,8(sp)
    8000462c:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    8000462e:	00854783          	lbu	a5,8(a0)
    80004632:	c3d5                	beqz	a5,800046d6 <fileread+0xb6>
    80004634:	84aa                	mv	s1,a0
    80004636:	89ae                	mv	s3,a1
    80004638:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    8000463a:	411c                	lw	a5,0(a0)
    8000463c:	4705                	li	a4,1
    8000463e:	04e78963          	beq	a5,a4,80004690 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004642:	470d                	li	a4,3
    80004644:	04e78d63          	beq	a5,a4,8000469e <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004648:	4709                	li	a4,2
    8000464a:	06e79e63          	bne	a5,a4,800046c6 <fileread+0xa6>
    ilock(f->ip);
    8000464e:	6d08                	ld	a0,24(a0)
    80004650:	fffff097          	auipc	ra,0xfffff
    80004654:	ff8080e7          	jalr	-8(ra) # 80003648 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004658:	874a                	mv	a4,s2
    8000465a:	5094                	lw	a3,32(s1)
    8000465c:	864e                	mv	a2,s3
    8000465e:	4585                	li	a1,1
    80004660:	6c88                	ld	a0,24(s1)
    80004662:	fffff097          	auipc	ra,0xfffff
    80004666:	29a080e7          	jalr	666(ra) # 800038fc <readi>
    8000466a:	892a                	mv	s2,a0
    8000466c:	00a05563          	blez	a0,80004676 <fileread+0x56>
      f->off += r;
    80004670:	509c                	lw	a5,32(s1)
    80004672:	9fa9                	addw	a5,a5,a0
    80004674:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004676:	6c88                	ld	a0,24(s1)
    80004678:	fffff097          	auipc	ra,0xfffff
    8000467c:	092080e7          	jalr	146(ra) # 8000370a <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004680:	854a                	mv	a0,s2
    80004682:	70a2                	ld	ra,40(sp)
    80004684:	7402                	ld	s0,32(sp)
    80004686:	64e2                	ld	s1,24(sp)
    80004688:	6942                	ld	s2,16(sp)
    8000468a:	69a2                	ld	s3,8(sp)
    8000468c:	6145                	addi	sp,sp,48
    8000468e:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004690:	6908                	ld	a0,16(a0)
    80004692:	00000097          	auipc	ra,0x0
    80004696:	3c8080e7          	jalr	968(ra) # 80004a5a <piperead>
    8000469a:	892a                	mv	s2,a0
    8000469c:	b7d5                	j	80004680 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    8000469e:	02451783          	lh	a5,36(a0)
    800046a2:	03079693          	slli	a3,a5,0x30
    800046a6:	92c1                	srli	a3,a3,0x30
    800046a8:	4725                	li	a4,9
    800046aa:	02d76863          	bltu	a4,a3,800046da <fileread+0xba>
    800046ae:	0792                	slli	a5,a5,0x4
    800046b0:	00024717          	auipc	a4,0x24
    800046b4:	c6870713          	addi	a4,a4,-920 # 80028318 <devsw>
    800046b8:	97ba                	add	a5,a5,a4
    800046ba:	639c                	ld	a5,0(a5)
    800046bc:	c38d                	beqz	a5,800046de <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    800046be:	4505                	li	a0,1
    800046c0:	9782                	jalr	a5
    800046c2:	892a                	mv	s2,a0
    800046c4:	bf75                	j	80004680 <fileread+0x60>
    panic("fileread");
    800046c6:	00004517          	auipc	a0,0x4
    800046ca:	fe250513          	addi	a0,a0,-30 # 800086a8 <syscalls+0x258>
    800046ce:	ffffc097          	auipc	ra,0xffffc
    800046d2:	e70080e7          	jalr	-400(ra) # 8000053e <panic>
    return -1;
    800046d6:	597d                	li	s2,-1
    800046d8:	b765                	j	80004680 <fileread+0x60>
      return -1;
    800046da:	597d                	li	s2,-1
    800046dc:	b755                	j	80004680 <fileread+0x60>
    800046de:	597d                	li	s2,-1
    800046e0:	b745                	j	80004680 <fileread+0x60>

00000000800046e2 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    800046e2:	715d                	addi	sp,sp,-80
    800046e4:	e486                	sd	ra,72(sp)
    800046e6:	e0a2                	sd	s0,64(sp)
    800046e8:	fc26                	sd	s1,56(sp)
    800046ea:	f84a                	sd	s2,48(sp)
    800046ec:	f44e                	sd	s3,40(sp)
    800046ee:	f052                	sd	s4,32(sp)
    800046f0:	ec56                	sd	s5,24(sp)
    800046f2:	e85a                	sd	s6,16(sp)
    800046f4:	e45e                	sd	s7,8(sp)
    800046f6:	e062                	sd	s8,0(sp)
    800046f8:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    800046fa:	00954783          	lbu	a5,9(a0)
    800046fe:	10078663          	beqz	a5,8000480a <filewrite+0x128>
    80004702:	892a                	mv	s2,a0
    80004704:	8aae                	mv	s5,a1
    80004706:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004708:	411c                	lw	a5,0(a0)
    8000470a:	4705                	li	a4,1
    8000470c:	02e78263          	beq	a5,a4,80004730 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004710:	470d                	li	a4,3
    80004712:	02e78663          	beq	a5,a4,8000473e <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004716:	4709                	li	a4,2
    80004718:	0ee79163          	bne	a5,a4,800047fa <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    8000471c:	0ac05d63          	blez	a2,800047d6 <filewrite+0xf4>
    int i = 0;
    80004720:	4981                	li	s3,0
    80004722:	6b05                	lui	s6,0x1
    80004724:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004728:	6b85                	lui	s7,0x1
    8000472a:	c00b8b9b          	addiw	s7,s7,-1024
    8000472e:	a861                	j	800047c6 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004730:	6908                	ld	a0,16(a0)
    80004732:	00000097          	auipc	ra,0x0
    80004736:	22e080e7          	jalr	558(ra) # 80004960 <pipewrite>
    8000473a:	8a2a                	mv	s4,a0
    8000473c:	a045                	j	800047dc <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    8000473e:	02451783          	lh	a5,36(a0)
    80004742:	03079693          	slli	a3,a5,0x30
    80004746:	92c1                	srli	a3,a3,0x30
    80004748:	4725                	li	a4,9
    8000474a:	0cd76263          	bltu	a4,a3,8000480e <filewrite+0x12c>
    8000474e:	0792                	slli	a5,a5,0x4
    80004750:	00024717          	auipc	a4,0x24
    80004754:	bc870713          	addi	a4,a4,-1080 # 80028318 <devsw>
    80004758:	97ba                	add	a5,a5,a4
    8000475a:	679c                	ld	a5,8(a5)
    8000475c:	cbdd                	beqz	a5,80004812 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    8000475e:	4505                	li	a0,1
    80004760:	9782                	jalr	a5
    80004762:	8a2a                	mv	s4,a0
    80004764:	a8a5                	j	800047dc <filewrite+0xfa>
    80004766:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    8000476a:	00000097          	auipc	ra,0x0
    8000476e:	8b0080e7          	jalr	-1872(ra) # 8000401a <begin_op>
      ilock(f->ip);
    80004772:	01893503          	ld	a0,24(s2)
    80004776:	fffff097          	auipc	ra,0xfffff
    8000477a:	ed2080e7          	jalr	-302(ra) # 80003648 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    8000477e:	8762                	mv	a4,s8
    80004780:	02092683          	lw	a3,32(s2)
    80004784:	01598633          	add	a2,s3,s5
    80004788:	4585                	li	a1,1
    8000478a:	01893503          	ld	a0,24(s2)
    8000478e:	fffff097          	auipc	ra,0xfffff
    80004792:	266080e7          	jalr	614(ra) # 800039f4 <writei>
    80004796:	84aa                	mv	s1,a0
    80004798:	00a05763          	blez	a0,800047a6 <filewrite+0xc4>
        f->off += r;
    8000479c:	02092783          	lw	a5,32(s2)
    800047a0:	9fa9                	addw	a5,a5,a0
    800047a2:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    800047a6:	01893503          	ld	a0,24(s2)
    800047aa:	fffff097          	auipc	ra,0xfffff
    800047ae:	f60080e7          	jalr	-160(ra) # 8000370a <iunlock>
      end_op();
    800047b2:	00000097          	auipc	ra,0x0
    800047b6:	8e8080e7          	jalr	-1816(ra) # 8000409a <end_op>

      if(r != n1){
    800047ba:	009c1f63          	bne	s8,s1,800047d8 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    800047be:	013489bb          	addw	s3,s1,s3
    while(i < n){
    800047c2:	0149db63          	bge	s3,s4,800047d8 <filewrite+0xf6>
      int n1 = n - i;
    800047c6:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    800047ca:	84be                	mv	s1,a5
    800047cc:	2781                	sext.w	a5,a5
    800047ce:	f8fb5ce3          	bge	s6,a5,80004766 <filewrite+0x84>
    800047d2:	84de                	mv	s1,s7
    800047d4:	bf49                	j	80004766 <filewrite+0x84>
    int i = 0;
    800047d6:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    800047d8:	013a1f63          	bne	s4,s3,800047f6 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    800047dc:	8552                	mv	a0,s4
    800047de:	60a6                	ld	ra,72(sp)
    800047e0:	6406                	ld	s0,64(sp)
    800047e2:	74e2                	ld	s1,56(sp)
    800047e4:	7942                	ld	s2,48(sp)
    800047e6:	79a2                	ld	s3,40(sp)
    800047e8:	7a02                	ld	s4,32(sp)
    800047ea:	6ae2                	ld	s5,24(sp)
    800047ec:	6b42                	ld	s6,16(sp)
    800047ee:	6ba2                	ld	s7,8(sp)
    800047f0:	6c02                	ld	s8,0(sp)
    800047f2:	6161                	addi	sp,sp,80
    800047f4:	8082                	ret
    ret = (i == n ? n : -1);
    800047f6:	5a7d                	li	s4,-1
    800047f8:	b7d5                	j	800047dc <filewrite+0xfa>
    panic("filewrite");
    800047fa:	00004517          	auipc	a0,0x4
    800047fe:	ebe50513          	addi	a0,a0,-322 # 800086b8 <syscalls+0x268>
    80004802:	ffffc097          	auipc	ra,0xffffc
    80004806:	d3c080e7          	jalr	-708(ra) # 8000053e <panic>
    return -1;
    8000480a:	5a7d                	li	s4,-1
    8000480c:	bfc1                	j	800047dc <filewrite+0xfa>
      return -1;
    8000480e:	5a7d                	li	s4,-1
    80004810:	b7f1                	j	800047dc <filewrite+0xfa>
    80004812:	5a7d                	li	s4,-1
    80004814:	b7e1                	j	800047dc <filewrite+0xfa>

0000000080004816 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004816:	7179                	addi	sp,sp,-48
    80004818:	f406                	sd	ra,40(sp)
    8000481a:	f022                	sd	s0,32(sp)
    8000481c:	ec26                	sd	s1,24(sp)
    8000481e:	e84a                	sd	s2,16(sp)
    80004820:	e44e                	sd	s3,8(sp)
    80004822:	e052                	sd	s4,0(sp)
    80004824:	1800                	addi	s0,sp,48
    80004826:	84aa                	mv	s1,a0
    80004828:	8a2e                	mv	s4,a1
	struct pipe *pi;

	pi = 0;
	*f0 = *f1 = 0;
    8000482a:	0005b023          	sd	zero,0(a1)
    8000482e:	00053023          	sd	zero,0(a0)
	if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004832:	00000097          	auipc	ra,0x0
    80004836:	bf8080e7          	jalr	-1032(ra) # 8000442a <filealloc>
    8000483a:	e088                	sd	a0,0(s1)
    8000483c:	c551                	beqz	a0,800048c8 <pipealloc+0xb2>
    8000483e:	00000097          	auipc	ra,0x0
    80004842:	bec080e7          	jalr	-1044(ra) # 8000442a <filealloc>
    80004846:	00aa3023          	sd	a0,0(s4)
    8000484a:	c92d                	beqz	a0,800048bc <pipealloc+0xa6>
		goto bad;
	if((pi = (struct pipe*)kalloc()) == 0)
    8000484c:	ffffc097          	auipc	ra,0xffffc
    80004850:	2a8080e7          	jalr	680(ra) # 80000af4 <kalloc>
    80004854:	892a                	mv	s2,a0
    80004856:	c125                	beqz	a0,800048b6 <pipealloc+0xa0>
		goto bad;
	pi->readopen = 1;
    80004858:	4985                	li	s3,1
    8000485a:	23352023          	sw	s3,544(a0)
	pi->writeopen = 1;
    8000485e:	23352223          	sw	s3,548(a0)
	pi->nwrite = 0;
    80004862:	20052e23          	sw	zero,540(a0)
	pi->nread = 0;
    80004866:	20052c23          	sw	zero,536(a0)
	initlock(&pi->lock, "pipe");
    8000486a:	00004597          	auipc	a1,0x4
    8000486e:	e5e58593          	addi	a1,a1,-418 # 800086c8 <syscalls+0x278>
    80004872:	ffffc097          	auipc	ra,0xffffc
    80004876:	2e2080e7          	jalr	738(ra) # 80000b54 <initlock>
	(*f0)->type = FD_PIPE;
    8000487a:	609c                	ld	a5,0(s1)
    8000487c:	0137a023          	sw	s3,0(a5)
	(*f0)->readable = 1;
    80004880:	609c                	ld	a5,0(s1)
    80004882:	01378423          	sb	s3,8(a5)
	(*f0)->writable = 0;
    80004886:	609c                	ld	a5,0(s1)
    80004888:	000784a3          	sb	zero,9(a5)
	(*f0)->pipe = pi;
    8000488c:	609c                	ld	a5,0(s1)
    8000488e:	0127b823          	sd	s2,16(a5)
	(*f1)->type = FD_PIPE;
    80004892:	000a3783          	ld	a5,0(s4)
    80004896:	0137a023          	sw	s3,0(a5)
	(*f1)->readable = 0;
    8000489a:	000a3783          	ld	a5,0(s4)
    8000489e:	00078423          	sb	zero,8(a5)
	(*f1)->writable = 1;
    800048a2:	000a3783          	ld	a5,0(s4)
    800048a6:	013784a3          	sb	s3,9(a5)
	(*f1)->pipe = pi;
    800048aa:	000a3783          	ld	a5,0(s4)
    800048ae:	0127b823          	sd	s2,16(a5)
	return 0;
    800048b2:	4501                	li	a0,0
    800048b4:	a025                	j	800048dc <pipealloc+0xc6>

bad:
	if(pi)
		kfree((char*)pi);
	if(*f0)
    800048b6:	6088                	ld	a0,0(s1)
    800048b8:	e501                	bnez	a0,800048c0 <pipealloc+0xaa>
    800048ba:	a039                	j	800048c8 <pipealloc+0xb2>
    800048bc:	6088                	ld	a0,0(s1)
    800048be:	c51d                	beqz	a0,800048ec <pipealloc+0xd6>
		fileclose(*f0);
    800048c0:	00000097          	auipc	ra,0x0
    800048c4:	c26080e7          	jalr	-986(ra) # 800044e6 <fileclose>
	if(*f1)
    800048c8:	000a3783          	ld	a5,0(s4)
		fileclose(*f1);
	return -1;
    800048cc:	557d                	li	a0,-1
	if(*f1)
    800048ce:	c799                	beqz	a5,800048dc <pipealloc+0xc6>
		fileclose(*f1);
    800048d0:	853e                	mv	a0,a5
    800048d2:	00000097          	auipc	ra,0x0
    800048d6:	c14080e7          	jalr	-1004(ra) # 800044e6 <fileclose>
	return -1;
    800048da:	557d                	li	a0,-1
}
    800048dc:	70a2                	ld	ra,40(sp)
    800048de:	7402                	ld	s0,32(sp)
    800048e0:	64e2                	ld	s1,24(sp)
    800048e2:	6942                	ld	s2,16(sp)
    800048e4:	69a2                	ld	s3,8(sp)
    800048e6:	6a02                	ld	s4,0(sp)
    800048e8:	6145                	addi	sp,sp,48
    800048ea:	8082                	ret
	return -1;
    800048ec:	557d                	li	a0,-1
    800048ee:	b7fd                	j	800048dc <pipealloc+0xc6>

00000000800048f0 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    800048f0:	1101                	addi	sp,sp,-32
    800048f2:	ec06                	sd	ra,24(sp)
    800048f4:	e822                	sd	s0,16(sp)
    800048f6:	e426                	sd	s1,8(sp)
    800048f8:	e04a                	sd	s2,0(sp)
    800048fa:	1000                	addi	s0,sp,32
    800048fc:	84aa                	mv	s1,a0
    800048fe:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004900:	ffffc097          	auipc	ra,0xffffc
    80004904:	2e4080e7          	jalr	740(ra) # 80000be4 <acquire>
  if(writable){
    80004908:	02090d63          	beqz	s2,80004942 <pipeclose+0x52>
    pi->writeopen = 0;
    8000490c:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004910:	21848513          	addi	a0,s1,536
    80004914:	ffffe097          	auipc	ra,0xffffe
    80004918:	95e080e7          	jalr	-1698(ra) # 80002272 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    8000491c:	2204b783          	ld	a5,544(s1)
    80004920:	eb95                	bnez	a5,80004954 <pipeclose+0x64>
    release(&pi->lock);
    80004922:	8526                	mv	a0,s1
    80004924:	ffffc097          	auipc	ra,0xffffc
    80004928:	374080e7          	jalr	884(ra) # 80000c98 <release>
    kfree((char*)pi);
    8000492c:	8526                	mv	a0,s1
    8000492e:	ffffc097          	auipc	ra,0xffffc
    80004932:	0ca080e7          	jalr	202(ra) # 800009f8 <kfree>
  } else
    release(&pi->lock);
}
    80004936:	60e2                	ld	ra,24(sp)
    80004938:	6442                	ld	s0,16(sp)
    8000493a:	64a2                	ld	s1,8(sp)
    8000493c:	6902                	ld	s2,0(sp)
    8000493e:	6105                	addi	sp,sp,32
    80004940:	8082                	ret
    pi->readopen = 0;
    80004942:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004946:	21c48513          	addi	a0,s1,540
    8000494a:	ffffe097          	auipc	ra,0xffffe
    8000494e:	928080e7          	jalr	-1752(ra) # 80002272 <wakeup>
    80004952:	b7e9                	j	8000491c <pipeclose+0x2c>
    release(&pi->lock);
    80004954:	8526                	mv	a0,s1
    80004956:	ffffc097          	auipc	ra,0xffffc
    8000495a:	342080e7          	jalr	834(ra) # 80000c98 <release>
}
    8000495e:	bfe1                	j	80004936 <pipeclose+0x46>

0000000080004960 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004960:	7159                	addi	sp,sp,-112
    80004962:	f486                	sd	ra,104(sp)
    80004964:	f0a2                	sd	s0,96(sp)
    80004966:	eca6                	sd	s1,88(sp)
    80004968:	e8ca                	sd	s2,80(sp)
    8000496a:	e4ce                	sd	s3,72(sp)
    8000496c:	e0d2                	sd	s4,64(sp)
    8000496e:	fc56                	sd	s5,56(sp)
    80004970:	f85a                	sd	s6,48(sp)
    80004972:	f45e                	sd	s7,40(sp)
    80004974:	f062                	sd	s8,32(sp)
    80004976:	ec66                	sd	s9,24(sp)
    80004978:	1880                	addi	s0,sp,112
    8000497a:	84aa                	mv	s1,a0
    8000497c:	8aae                	mv	s5,a1
    8000497e:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004980:	ffffd097          	auipc	ra,0xffffd
    80004984:	0aa080e7          	jalr	170(ra) # 80001a2a <myproc>
    80004988:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    8000498a:	8526                	mv	a0,s1
    8000498c:	ffffc097          	auipc	ra,0xffffc
    80004990:	258080e7          	jalr	600(ra) # 80000be4 <acquire>
  while(i < n){
    80004994:	0d405163          	blez	s4,80004a56 <pipewrite+0xf6>
    80004998:	8ba6                	mv	s7,s1
  int i = 0;
    8000499a:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    8000499c:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    8000499e:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    800049a2:	21c48c13          	addi	s8,s1,540
    800049a6:	a08d                	j	80004a08 <pipewrite+0xa8>
      release(&pi->lock);
    800049a8:	8526                	mv	a0,s1
    800049aa:	ffffc097          	auipc	ra,0xffffc
    800049ae:	2ee080e7          	jalr	750(ra) # 80000c98 <release>
      return -1;
    800049b2:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    800049b4:	854a                	mv	a0,s2
    800049b6:	70a6                	ld	ra,104(sp)
    800049b8:	7406                	ld	s0,96(sp)
    800049ba:	64e6                	ld	s1,88(sp)
    800049bc:	6946                	ld	s2,80(sp)
    800049be:	69a6                	ld	s3,72(sp)
    800049c0:	6a06                	ld	s4,64(sp)
    800049c2:	7ae2                	ld	s5,56(sp)
    800049c4:	7b42                	ld	s6,48(sp)
    800049c6:	7ba2                	ld	s7,40(sp)
    800049c8:	7c02                	ld	s8,32(sp)
    800049ca:	6ce2                	ld	s9,24(sp)
    800049cc:	6165                	addi	sp,sp,112
    800049ce:	8082                	ret
      wakeup(&pi->nread);
    800049d0:	8566                	mv	a0,s9
    800049d2:	ffffe097          	auipc	ra,0xffffe
    800049d6:	8a0080e7          	jalr	-1888(ra) # 80002272 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    800049da:	85de                	mv	a1,s7
    800049dc:	8562                	mv	a0,s8
    800049de:	ffffd097          	auipc	ra,0xffffd
    800049e2:	708080e7          	jalr	1800(ra) # 800020e6 <sleep>
    800049e6:	a839                	j	80004a04 <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    800049e8:	21c4a783          	lw	a5,540(s1)
    800049ec:	0017871b          	addiw	a4,a5,1
    800049f0:	20e4ae23          	sw	a4,540(s1)
    800049f4:	1ff7f793          	andi	a5,a5,511
    800049f8:	97a6                	add	a5,a5,s1
    800049fa:	f9f44703          	lbu	a4,-97(s0)
    800049fe:	00e78c23          	sb	a4,24(a5)
      i++;
    80004a02:	2905                	addiw	s2,s2,1
  while(i < n){
    80004a04:	03495d63          	bge	s2,s4,80004a3e <pipewrite+0xde>
    if(pi->readopen == 0 || pr->killed){
    80004a08:	2204a783          	lw	a5,544(s1)
    80004a0c:	dfd1                	beqz	a5,800049a8 <pipewrite+0x48>
    80004a0e:	0289a783          	lw	a5,40(s3)
    80004a12:	fbd9                	bnez	a5,800049a8 <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004a14:	2184a783          	lw	a5,536(s1)
    80004a18:	21c4a703          	lw	a4,540(s1)
    80004a1c:	2007879b          	addiw	a5,a5,512
    80004a20:	faf708e3          	beq	a4,a5,800049d0 <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004a24:	4685                	li	a3,1
    80004a26:	01590633          	add	a2,s2,s5
    80004a2a:	f9f40593          	addi	a1,s0,-97
    80004a2e:	0509b503          	ld	a0,80(s3)
    80004a32:	ffffd097          	auipc	ra,0xffffd
    80004a36:	cca080e7          	jalr	-822(ra) # 800016fc <copyin>
    80004a3a:	fb6517e3          	bne	a0,s6,800049e8 <pipewrite+0x88>
  wakeup(&pi->nread);
    80004a3e:	21848513          	addi	a0,s1,536
    80004a42:	ffffe097          	auipc	ra,0xffffe
    80004a46:	830080e7          	jalr	-2000(ra) # 80002272 <wakeup>
  release(&pi->lock);
    80004a4a:	8526                	mv	a0,s1
    80004a4c:	ffffc097          	auipc	ra,0xffffc
    80004a50:	24c080e7          	jalr	588(ra) # 80000c98 <release>
  return i;
    80004a54:	b785                	j	800049b4 <pipewrite+0x54>
  int i = 0;
    80004a56:	4901                	li	s2,0
    80004a58:	b7dd                	j	80004a3e <pipewrite+0xde>

0000000080004a5a <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004a5a:	715d                	addi	sp,sp,-80
    80004a5c:	e486                	sd	ra,72(sp)
    80004a5e:	e0a2                	sd	s0,64(sp)
    80004a60:	fc26                	sd	s1,56(sp)
    80004a62:	f84a                	sd	s2,48(sp)
    80004a64:	f44e                	sd	s3,40(sp)
    80004a66:	f052                	sd	s4,32(sp)
    80004a68:	ec56                	sd	s5,24(sp)
    80004a6a:	e85a                	sd	s6,16(sp)
    80004a6c:	0880                	addi	s0,sp,80
    80004a6e:	84aa                	mv	s1,a0
    80004a70:	892e                	mv	s2,a1
    80004a72:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004a74:	ffffd097          	auipc	ra,0xffffd
    80004a78:	fb6080e7          	jalr	-74(ra) # 80001a2a <myproc>
    80004a7c:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004a7e:	8b26                	mv	s6,s1
    80004a80:	8526                	mv	a0,s1
    80004a82:	ffffc097          	auipc	ra,0xffffc
    80004a86:	162080e7          	jalr	354(ra) # 80000be4 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004a8a:	2184a703          	lw	a4,536(s1)
    80004a8e:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004a92:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004a96:	02f71463          	bne	a4,a5,80004abe <piperead+0x64>
    80004a9a:	2244a783          	lw	a5,548(s1)
    80004a9e:	c385                	beqz	a5,80004abe <piperead+0x64>
    if(pr->killed){
    80004aa0:	028a2783          	lw	a5,40(s4)
    80004aa4:	ebc1                	bnez	a5,80004b34 <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004aa6:	85da                	mv	a1,s6
    80004aa8:	854e                	mv	a0,s3
    80004aaa:	ffffd097          	auipc	ra,0xffffd
    80004aae:	63c080e7          	jalr	1596(ra) # 800020e6 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004ab2:	2184a703          	lw	a4,536(s1)
    80004ab6:	21c4a783          	lw	a5,540(s1)
    80004aba:	fef700e3          	beq	a4,a5,80004a9a <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004abe:	09505263          	blez	s5,80004b42 <piperead+0xe8>
    80004ac2:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004ac4:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80004ac6:	2184a783          	lw	a5,536(s1)
    80004aca:	21c4a703          	lw	a4,540(s1)
    80004ace:	02f70d63          	beq	a4,a5,80004b08 <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004ad2:	0017871b          	addiw	a4,a5,1
    80004ad6:	20e4ac23          	sw	a4,536(s1)
    80004ada:	1ff7f793          	andi	a5,a5,511
    80004ade:	97a6                	add	a5,a5,s1
    80004ae0:	0187c783          	lbu	a5,24(a5)
    80004ae4:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004ae8:	4685                	li	a3,1
    80004aea:	fbf40613          	addi	a2,s0,-65
    80004aee:	85ca                	mv	a1,s2
    80004af0:	050a3503          	ld	a0,80(s4)
    80004af4:	ffffd097          	auipc	ra,0xffffd
    80004af8:	b7c080e7          	jalr	-1156(ra) # 80001670 <copyout>
    80004afc:	01650663          	beq	a0,s6,80004b08 <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004b00:	2985                	addiw	s3,s3,1
    80004b02:	0905                	addi	s2,s2,1
    80004b04:	fd3a91e3          	bne	s5,s3,80004ac6 <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004b08:	21c48513          	addi	a0,s1,540
    80004b0c:	ffffd097          	auipc	ra,0xffffd
    80004b10:	766080e7          	jalr	1894(ra) # 80002272 <wakeup>
  release(&pi->lock);
    80004b14:	8526                	mv	a0,s1
    80004b16:	ffffc097          	auipc	ra,0xffffc
    80004b1a:	182080e7          	jalr	386(ra) # 80000c98 <release>
  return i;
}
    80004b1e:	854e                	mv	a0,s3
    80004b20:	60a6                	ld	ra,72(sp)
    80004b22:	6406                	ld	s0,64(sp)
    80004b24:	74e2                	ld	s1,56(sp)
    80004b26:	7942                	ld	s2,48(sp)
    80004b28:	79a2                	ld	s3,40(sp)
    80004b2a:	7a02                	ld	s4,32(sp)
    80004b2c:	6ae2                	ld	s5,24(sp)
    80004b2e:	6b42                	ld	s6,16(sp)
    80004b30:	6161                	addi	sp,sp,80
    80004b32:	8082                	ret
      release(&pi->lock);
    80004b34:	8526                	mv	a0,s1
    80004b36:	ffffc097          	auipc	ra,0xffffc
    80004b3a:	162080e7          	jalr	354(ra) # 80000c98 <release>
      return -1;
    80004b3e:	59fd                	li	s3,-1
    80004b40:	bff9                	j	80004b1e <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004b42:	4981                	li	s3,0
    80004b44:	b7d1                	j	80004b08 <piperead+0xae>

0000000080004b46 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004b46:	df010113          	addi	sp,sp,-528
    80004b4a:	20113423          	sd	ra,520(sp)
    80004b4e:	20813023          	sd	s0,512(sp)
    80004b52:	ffa6                	sd	s1,504(sp)
    80004b54:	fbca                	sd	s2,496(sp)
    80004b56:	f7ce                	sd	s3,488(sp)
    80004b58:	f3d2                	sd	s4,480(sp)
    80004b5a:	efd6                	sd	s5,472(sp)
    80004b5c:	ebda                	sd	s6,464(sp)
    80004b5e:	e7de                	sd	s7,456(sp)
    80004b60:	e3e2                	sd	s8,448(sp)
    80004b62:	ff66                	sd	s9,440(sp)
    80004b64:	fb6a                	sd	s10,432(sp)
    80004b66:	f76e                	sd	s11,424(sp)
    80004b68:	0c00                	addi	s0,sp,528
    80004b6a:	84aa                	mv	s1,a0
    80004b6c:	dea43c23          	sd	a0,-520(s0)
    80004b70:	e0b43023          	sd	a1,-512(s0)
	uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
	struct elfhdr elf;
	struct inode *ip;
	struct proghdr ph;
	pagetable_t pagetable = 0, oldpagetable;
	struct proc *p = myproc();
    80004b74:	ffffd097          	auipc	ra,0xffffd
    80004b78:	eb6080e7          	jalr	-330(ra) # 80001a2a <myproc>
    80004b7c:	892a                	mv	s2,a0

	begin_op();
    80004b7e:	fffff097          	auipc	ra,0xfffff
    80004b82:	49c080e7          	jalr	1180(ra) # 8000401a <begin_op>

	if((ip = namei(path)) == 0){
    80004b86:	8526                	mv	a0,s1
    80004b88:	fffff097          	auipc	ra,0xfffff
    80004b8c:	276080e7          	jalr	630(ra) # 80003dfe <namei>
    80004b90:	c92d                	beqz	a0,80004c02 <exec+0xbc>
    80004b92:	84aa                	mv	s1,a0
		end_op();
		return -1;
	}
	ilock(ip);
    80004b94:	fffff097          	auipc	ra,0xfffff
    80004b98:	ab4080e7          	jalr	-1356(ra) # 80003648 <ilock>

	// Check ELF header
	if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004b9c:	04000713          	li	a4,64
    80004ba0:	4681                	li	a3,0
    80004ba2:	e5040613          	addi	a2,s0,-432
    80004ba6:	4581                	li	a1,0
    80004ba8:	8526                	mv	a0,s1
    80004baa:	fffff097          	auipc	ra,0xfffff
    80004bae:	d52080e7          	jalr	-686(ra) # 800038fc <readi>
    80004bb2:	04000793          	li	a5,64
    80004bb6:	00f51a63          	bne	a0,a5,80004bca <exec+0x84>
		goto bad;
	if(elf.magic != ELF_MAGIC)
    80004bba:	e5042703          	lw	a4,-432(s0)
    80004bbe:	464c47b7          	lui	a5,0x464c4
    80004bc2:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004bc6:	04f70463          	beq	a4,a5,80004c0e <exec+0xc8>

bad:
	if(pagetable)
		proc_freepagetable(pagetable, sz);
	if(ip){
		iunlockput(ip);
    80004bca:	8526                	mv	a0,s1
    80004bcc:	fffff097          	auipc	ra,0xfffff
    80004bd0:	cde080e7          	jalr	-802(ra) # 800038aa <iunlockput>
		end_op();
    80004bd4:	fffff097          	auipc	ra,0xfffff
    80004bd8:	4c6080e7          	jalr	1222(ra) # 8000409a <end_op>
	}
	return -1;
    80004bdc:	557d                	li	a0,-1
}
    80004bde:	20813083          	ld	ra,520(sp)
    80004be2:	20013403          	ld	s0,512(sp)
    80004be6:	74fe                	ld	s1,504(sp)
    80004be8:	795e                	ld	s2,496(sp)
    80004bea:	79be                	ld	s3,488(sp)
    80004bec:	7a1e                	ld	s4,480(sp)
    80004bee:	6afe                	ld	s5,472(sp)
    80004bf0:	6b5e                	ld	s6,464(sp)
    80004bf2:	6bbe                	ld	s7,456(sp)
    80004bf4:	6c1e                	ld	s8,448(sp)
    80004bf6:	7cfa                	ld	s9,440(sp)
    80004bf8:	7d5a                	ld	s10,432(sp)
    80004bfa:	7dba                	ld	s11,424(sp)
    80004bfc:	21010113          	addi	sp,sp,528
    80004c00:	8082                	ret
		end_op();
    80004c02:	fffff097          	auipc	ra,0xfffff
    80004c06:	498080e7          	jalr	1176(ra) # 8000409a <end_op>
		return -1;
    80004c0a:	557d                	li	a0,-1
    80004c0c:	bfc9                	j	80004bde <exec+0x98>
	if((pagetable = proc_pagetable(p)) == 0)
    80004c0e:	854a                	mv	a0,s2
    80004c10:	ffffd097          	auipc	ra,0xffffd
    80004c14:	ede080e7          	jalr	-290(ra) # 80001aee <proc_pagetable>
    80004c18:	8baa                	mv	s7,a0
    80004c1a:	d945                	beqz	a0,80004bca <exec+0x84>
	for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004c1c:	e7042983          	lw	s3,-400(s0)
    80004c20:	e8845783          	lhu	a5,-376(s0)
    80004c24:	c7ad                	beqz	a5,80004c8e <exec+0x148>
	uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004c26:	4901                	li	s2,0
	for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004c28:	4b01                	li	s6,0
		if((ph.vaddr % PGSIZE) != 0)
    80004c2a:	6ca1                	lui	s9,0x8
    80004c2c:	fffc8793          	addi	a5,s9,-1 # 7fff <_entry-0x7fff8001>
    80004c30:	def43823          	sd	a5,-528(s0)
    80004c34:	a42d                	j	80004e5e <exec+0x318>
	uint64 pa;

	for(i = 0; i < sz; i += PGSIZE){
		pa = walkaddr(pagetable, va + i);
		if(pa == 0)
			panic("loadseg: address should exist");
    80004c36:	00004517          	auipc	a0,0x4
    80004c3a:	a9a50513          	addi	a0,a0,-1382 # 800086d0 <syscalls+0x280>
    80004c3e:	ffffc097          	auipc	ra,0xffffc
    80004c42:	900080e7          	jalr	-1792(ra) # 8000053e <panic>
		if(sz - i < PGSIZE)
			n = sz - i;
		else
			n = PGSIZE;
		if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004c46:	8756                	mv	a4,s5
    80004c48:	012d86bb          	addw	a3,s11,s2
    80004c4c:	4581                	li	a1,0
    80004c4e:	8526                	mv	a0,s1
    80004c50:	fffff097          	auipc	ra,0xfffff
    80004c54:	cac080e7          	jalr	-852(ra) # 800038fc <readi>
    80004c58:	2501                	sext.w	a0,a0
    80004c5a:	1aaa9963          	bne	s5,a0,80004e0c <exec+0x2c6>
	for(i = 0; i < sz; i += PGSIZE){
    80004c5e:	67a1                	lui	a5,0x8
    80004c60:	0127893b          	addw	s2,a5,s2
    80004c64:	77e1                	lui	a5,0xffff8
    80004c66:	01478a3b          	addw	s4,a5,s4
    80004c6a:	1f897163          	bgeu	s2,s8,80004e4c <exec+0x306>
		pa = walkaddr(pagetable, va + i);
    80004c6e:	02091593          	slli	a1,s2,0x20
    80004c72:	9181                	srli	a1,a1,0x20
    80004c74:	95ea                	add	a1,a1,s10
    80004c76:	855e                	mv	a0,s7
    80004c78:	ffffc097          	auipc	ra,0xffffc
    80004c7c:	3f4080e7          	jalr	1012(ra) # 8000106c <walkaddr>
    80004c80:	862a                	mv	a2,a0
		if(pa == 0)
    80004c82:	d955                	beqz	a0,80004c36 <exec+0xf0>
			n = PGSIZE;
    80004c84:	8ae6                	mv	s5,s9
		if(sz - i < PGSIZE)
    80004c86:	fd9a70e3          	bgeu	s4,s9,80004c46 <exec+0x100>
			n = sz - i;
    80004c8a:	8ad2                	mv	s5,s4
    80004c8c:	bf6d                	j	80004c46 <exec+0x100>
	uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004c8e:	4901                	li	s2,0
	iunlockput(ip);
    80004c90:	8526                	mv	a0,s1
    80004c92:	fffff097          	auipc	ra,0xfffff
    80004c96:	c18080e7          	jalr	-1000(ra) # 800038aa <iunlockput>
	end_op();
    80004c9a:	fffff097          	auipc	ra,0xfffff
    80004c9e:	400080e7          	jalr	1024(ra) # 8000409a <end_op>
	p = myproc();
    80004ca2:	ffffd097          	auipc	ra,0xffffd
    80004ca6:	d88080e7          	jalr	-632(ra) # 80001a2a <myproc>
    80004caa:	8aaa                	mv	s5,a0
	uint64 oldsz = p->sz;
    80004cac:	04853d03          	ld	s10,72(a0)
	sz = PGROUNDUP(sz);
    80004cb0:	67a1                	lui	a5,0x8
    80004cb2:	17fd                	addi	a5,a5,-1
    80004cb4:	993e                	add	s2,s2,a5
    80004cb6:	7561                	lui	a0,0xffff8
    80004cb8:	00a977b3          	and	a5,s2,a0
    80004cbc:	e0f43423          	sd	a5,-504(s0)
	if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004cc0:	6641                	lui	a2,0x10
    80004cc2:	963e                	add	a2,a2,a5
    80004cc4:	85be                	mv	a1,a5
    80004cc6:	855e                	mv	a0,s7
    80004cc8:	ffffc097          	auipc	ra,0xffffc
    80004ccc:	758080e7          	jalr	1880(ra) # 80001420 <uvmalloc>
    80004cd0:	8b2a                	mv	s6,a0
	ip = 0;
    80004cd2:	4481                	li	s1,0
	if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004cd4:	12050c63          	beqz	a0,80004e0c <exec+0x2c6>
	uvmclear(pagetable, sz-2*PGSIZE);
    80004cd8:	75c1                	lui	a1,0xffff0
    80004cda:	95aa                	add	a1,a1,a0
    80004cdc:	855e                	mv	a0,s7
    80004cde:	ffffd097          	auipc	ra,0xffffd
    80004ce2:	960080e7          	jalr	-1696(ra) # 8000163e <uvmclear>
	stackbase = sp - PGSIZE;
    80004ce6:	7c61                	lui	s8,0xffff8
    80004ce8:	9c5a                	add	s8,s8,s6
	for(argc = 0; argv[argc]; argc++) {
    80004cea:	e0043783          	ld	a5,-512(s0)
    80004cee:	6388                	ld	a0,0(a5)
    80004cf0:	c535                	beqz	a0,80004d5c <exec+0x216>
    80004cf2:	e9040993          	addi	s3,s0,-368
    80004cf6:	f9040c93          	addi	s9,s0,-112
	sp = sz;
    80004cfa:	895a                	mv	s2,s6
		sp -= strlen(argv[argc]) + 1;
    80004cfc:	ffffc097          	auipc	ra,0xffffc
    80004d00:	168080e7          	jalr	360(ra) # 80000e64 <strlen>
    80004d04:	2505                	addiw	a0,a0,1
    80004d06:	40a90933          	sub	s2,s2,a0
		sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004d0a:	ff097913          	andi	s2,s2,-16
		if(sp < stackbase)
    80004d0e:	13896363          	bltu	s2,s8,80004e34 <exec+0x2ee>
		if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004d12:	e0043d83          	ld	s11,-512(s0)
    80004d16:	000dba03          	ld	s4,0(s11)
    80004d1a:	8552                	mv	a0,s4
    80004d1c:	ffffc097          	auipc	ra,0xffffc
    80004d20:	148080e7          	jalr	328(ra) # 80000e64 <strlen>
    80004d24:	0015069b          	addiw	a3,a0,1
    80004d28:	8652                	mv	a2,s4
    80004d2a:	85ca                	mv	a1,s2
    80004d2c:	855e                	mv	a0,s7
    80004d2e:	ffffd097          	auipc	ra,0xffffd
    80004d32:	942080e7          	jalr	-1726(ra) # 80001670 <copyout>
    80004d36:	10054363          	bltz	a0,80004e3c <exec+0x2f6>
		ustack[argc] = sp;
    80004d3a:	0129b023          	sd	s2,0(s3)
	for(argc = 0; argv[argc]; argc++) {
    80004d3e:	0485                	addi	s1,s1,1
    80004d40:	008d8793          	addi	a5,s11,8
    80004d44:	e0f43023          	sd	a5,-512(s0)
    80004d48:	008db503          	ld	a0,8(s11)
    80004d4c:	c911                	beqz	a0,80004d60 <exec+0x21a>
		if(argc >= MAXARG)
    80004d4e:	09a1                	addi	s3,s3,8
    80004d50:	fb3c96e3          	bne	s9,s3,80004cfc <exec+0x1b6>
	sz = sz1;
    80004d54:	e1643423          	sd	s6,-504(s0)
	ip = 0;
    80004d58:	4481                	li	s1,0
    80004d5a:	a84d                	j	80004e0c <exec+0x2c6>
	sp = sz;
    80004d5c:	895a                	mv	s2,s6
	for(argc = 0; argv[argc]; argc++) {
    80004d5e:	4481                	li	s1,0
	ustack[argc] = 0;
    80004d60:	00349793          	slli	a5,s1,0x3
    80004d64:	f9040713          	addi	a4,s0,-112
    80004d68:	97ba                	add	a5,a5,a4
    80004d6a:	f007b023          	sd	zero,-256(a5) # 7f00 <_entry-0x7fff8100>
	sp -= (argc+1) * sizeof(uint64);
    80004d6e:	00148693          	addi	a3,s1,1
    80004d72:	068e                	slli	a3,a3,0x3
    80004d74:	40d90933          	sub	s2,s2,a3
	sp -= sp % 16;
    80004d78:	ff097913          	andi	s2,s2,-16
	if(sp < stackbase)
    80004d7c:	01897663          	bgeu	s2,s8,80004d88 <exec+0x242>
	sz = sz1;
    80004d80:	e1643423          	sd	s6,-504(s0)
	ip = 0;
    80004d84:	4481                	li	s1,0
    80004d86:	a059                	j	80004e0c <exec+0x2c6>
	if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004d88:	e9040613          	addi	a2,s0,-368
    80004d8c:	85ca                	mv	a1,s2
    80004d8e:	855e                	mv	a0,s7
    80004d90:	ffffd097          	auipc	ra,0xffffd
    80004d94:	8e0080e7          	jalr	-1824(ra) # 80001670 <copyout>
    80004d98:	0a054663          	bltz	a0,80004e44 <exec+0x2fe>
	p->trapframe->a1 = sp;
    80004d9c:	058ab783          	ld	a5,88(s5)
    80004da0:	0727bc23          	sd	s2,120(a5)
	for(last=s=path; *s; s++)
    80004da4:	df843783          	ld	a5,-520(s0)
    80004da8:	0007c703          	lbu	a4,0(a5)
    80004dac:	cf11                	beqz	a4,80004dc8 <exec+0x282>
    80004dae:	0785                	addi	a5,a5,1
		if(*s == '/')
    80004db0:	02f00693          	li	a3,47
    80004db4:	a039                	j	80004dc2 <exec+0x27c>
			last = s+1;
    80004db6:	def43c23          	sd	a5,-520(s0)
	for(last=s=path; *s; s++)
    80004dba:	0785                	addi	a5,a5,1
    80004dbc:	fff7c703          	lbu	a4,-1(a5)
    80004dc0:	c701                	beqz	a4,80004dc8 <exec+0x282>
		if(*s == '/')
    80004dc2:	fed71ce3          	bne	a4,a3,80004dba <exec+0x274>
    80004dc6:	bfc5                	j	80004db6 <exec+0x270>
	safestrcpy(p->name, last, sizeof(p->name));
    80004dc8:	4641                	li	a2,16
    80004dca:	df843583          	ld	a1,-520(s0)
    80004dce:	158a8513          	addi	a0,s5,344
    80004dd2:	ffffc097          	auipc	ra,0xffffc
    80004dd6:	060080e7          	jalr	96(ra) # 80000e32 <safestrcpy>
	oldpagetable = p->pagetable;
    80004dda:	050ab503          	ld	a0,80(s5)
	p->pagetable = pagetable;
    80004dde:	057ab823          	sd	s7,80(s5)
	p->sz = sz;
    80004de2:	056ab423          	sd	s6,72(s5)
	p->trapframe->epc = elf.entry;  // initial program counter = main
    80004de6:	058ab783          	ld	a5,88(s5)
    80004dea:	e6843703          	ld	a4,-408(s0)
    80004dee:	ef98                	sd	a4,24(a5)
	p->trapframe->sp = sp; // initial stack pointer
    80004df0:	058ab783          	ld	a5,88(s5)
    80004df4:	0327b823          	sd	s2,48(a5)
	proc_freepagetable(oldpagetable, oldsz);
    80004df8:	85ea                	mv	a1,s10
    80004dfa:	ffffd097          	auipc	ra,0xffffd
    80004dfe:	d90080e7          	jalr	-624(ra) # 80001b8a <proc_freepagetable>
	return argc; // this ends up in a0, the first argument to main(argc, argv)
    80004e02:	0004851b          	sext.w	a0,s1
    80004e06:	bbe1                	j	80004bde <exec+0x98>
    80004e08:	e1243423          	sd	s2,-504(s0)
		proc_freepagetable(pagetable, sz);
    80004e0c:	e0843583          	ld	a1,-504(s0)
    80004e10:	855e                	mv	a0,s7
    80004e12:	ffffd097          	auipc	ra,0xffffd
    80004e16:	d78080e7          	jalr	-648(ra) # 80001b8a <proc_freepagetable>
	if(ip){
    80004e1a:	da0498e3          	bnez	s1,80004bca <exec+0x84>
	return -1;
    80004e1e:	557d                	li	a0,-1
    80004e20:	bb7d                	j	80004bde <exec+0x98>
    80004e22:	e1243423          	sd	s2,-504(s0)
    80004e26:	b7dd                	j	80004e0c <exec+0x2c6>
    80004e28:	e1243423          	sd	s2,-504(s0)
    80004e2c:	b7c5                	j	80004e0c <exec+0x2c6>
    80004e2e:	e1243423          	sd	s2,-504(s0)
    80004e32:	bfe9                	j	80004e0c <exec+0x2c6>
	sz = sz1;
    80004e34:	e1643423          	sd	s6,-504(s0)
	ip = 0;
    80004e38:	4481                	li	s1,0
    80004e3a:	bfc9                	j	80004e0c <exec+0x2c6>
	sz = sz1;
    80004e3c:	e1643423          	sd	s6,-504(s0)
	ip = 0;
    80004e40:	4481                	li	s1,0
    80004e42:	b7e9                	j	80004e0c <exec+0x2c6>
	sz = sz1;
    80004e44:	e1643423          	sd	s6,-504(s0)
	ip = 0;
    80004e48:	4481                	li	s1,0
    80004e4a:	b7c9                	j	80004e0c <exec+0x2c6>
		if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80004e4c:	e0843903          	ld	s2,-504(s0)
	for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004e50:	2b05                	addiw	s6,s6,1
    80004e52:	0389899b          	addiw	s3,s3,56
    80004e56:	e8845783          	lhu	a5,-376(s0)
    80004e5a:	e2fb5be3          	bge	s6,a5,80004c90 <exec+0x14a>
		if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80004e5e:	2981                	sext.w	s3,s3
    80004e60:	03800713          	li	a4,56
    80004e64:	86ce                	mv	a3,s3
    80004e66:	e1840613          	addi	a2,s0,-488
    80004e6a:	4581                	li	a1,0
    80004e6c:	8526                	mv	a0,s1
    80004e6e:	fffff097          	auipc	ra,0xfffff
    80004e72:	a8e080e7          	jalr	-1394(ra) # 800038fc <readi>
    80004e76:	03800793          	li	a5,56
    80004e7a:	f8f517e3          	bne	a0,a5,80004e08 <exec+0x2c2>
		if(ph.type != ELF_PROG_LOAD)
    80004e7e:	e1842783          	lw	a5,-488(s0)
    80004e82:	4705                	li	a4,1
    80004e84:	fce796e3          	bne	a5,a4,80004e50 <exec+0x30a>
		if(ph.memsz < ph.filesz)
    80004e88:	e4043603          	ld	a2,-448(s0)
    80004e8c:	e3843783          	ld	a5,-456(s0)
    80004e90:	f8f669e3          	bltu	a2,a5,80004e22 <exec+0x2dc>
		if(ph.vaddr + ph.memsz < ph.vaddr)	// オーバーフロー
    80004e94:	e2843783          	ld	a5,-472(s0)
    80004e98:	963e                	add	a2,a2,a5
    80004e9a:	f8f667e3          	bltu	a2,a5,80004e28 <exec+0x2e2>
		if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80004e9e:	85ca                	mv	a1,s2
    80004ea0:	855e                	mv	a0,s7
    80004ea2:	ffffc097          	auipc	ra,0xffffc
    80004ea6:	57e080e7          	jalr	1406(ra) # 80001420 <uvmalloc>
    80004eaa:	e0a43423          	sd	a0,-504(s0)
    80004eae:	d141                	beqz	a0,80004e2e <exec+0x2e8>
		if((ph.vaddr % PGSIZE) != 0)
    80004eb0:	e2843d03          	ld	s10,-472(s0)
    80004eb4:	df043783          	ld	a5,-528(s0)
    80004eb8:	00fd77b3          	and	a5,s10,a5
    80004ebc:	fba1                	bnez	a5,80004e0c <exec+0x2c6>
		if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80004ebe:	e2042d83          	lw	s11,-480(s0)
    80004ec2:	e3842c03          	lw	s8,-456(s0)
	for(i = 0; i < sz; i += PGSIZE){
    80004ec6:	f80c03e3          	beqz	s8,80004e4c <exec+0x306>
    80004eca:	8a62                	mv	s4,s8
    80004ecc:	4901                	li	s2,0
    80004ece:	b345                	j	80004c6e <exec+0x128>

0000000080004ed0 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80004ed0:	7179                	addi	sp,sp,-48
    80004ed2:	f406                	sd	ra,40(sp)
    80004ed4:	f022                	sd	s0,32(sp)
    80004ed6:	ec26                	sd	s1,24(sp)
    80004ed8:	e84a                	sd	s2,16(sp)
    80004eda:	1800                	addi	s0,sp,48
    80004edc:	892e                	mv	s2,a1
    80004ede:	84b2                	mv	s1,a2
	int fd;
	struct file *f;

	if(argint(n, &fd) < 0)
    80004ee0:	fdc40593          	addi	a1,s0,-36
    80004ee4:	ffffe097          	auipc	ra,0xffffe
    80004ee8:	bf2080e7          	jalr	-1038(ra) # 80002ad6 <argint>
    80004eec:	04054063          	bltz	a0,80004f2c <argfd+0x5c>
		return -1;
	if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80004ef0:	fdc42703          	lw	a4,-36(s0)
    80004ef4:	47bd                	li	a5,15
    80004ef6:	02e7ed63          	bltu	a5,a4,80004f30 <argfd+0x60>
    80004efa:	ffffd097          	auipc	ra,0xffffd
    80004efe:	b30080e7          	jalr	-1232(ra) # 80001a2a <myproc>
    80004f02:	fdc42703          	lw	a4,-36(s0)
    80004f06:	01a70793          	addi	a5,a4,26
    80004f0a:	078e                	slli	a5,a5,0x3
    80004f0c:	953e                	add	a0,a0,a5
    80004f0e:	611c                	ld	a5,0(a0)
    80004f10:	c395                	beqz	a5,80004f34 <argfd+0x64>
		return -1;
	if(pfd)
    80004f12:	00090463          	beqz	s2,80004f1a <argfd+0x4a>
		*pfd = fd;
    80004f16:	00e92023          	sw	a4,0(s2)
	if(pf)
		*pf = f;
	return 0;
    80004f1a:	4501                	li	a0,0
	if(pf)
    80004f1c:	c091                	beqz	s1,80004f20 <argfd+0x50>
		*pf = f;
    80004f1e:	e09c                	sd	a5,0(s1)
}
    80004f20:	70a2                	ld	ra,40(sp)
    80004f22:	7402                	ld	s0,32(sp)
    80004f24:	64e2                	ld	s1,24(sp)
    80004f26:	6942                	ld	s2,16(sp)
    80004f28:	6145                	addi	sp,sp,48
    80004f2a:	8082                	ret
		return -1;
    80004f2c:	557d                	li	a0,-1
    80004f2e:	bfcd                	j	80004f20 <argfd+0x50>
		return -1;
    80004f30:	557d                	li	a0,-1
    80004f32:	b7fd                	j	80004f20 <argfd+0x50>
    80004f34:	557d                	li	a0,-1
    80004f36:	b7ed                	j	80004f20 <argfd+0x50>

0000000080004f38 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80004f38:	1101                	addi	sp,sp,-32
    80004f3a:	ec06                	sd	ra,24(sp)
    80004f3c:	e822                	sd	s0,16(sp)
    80004f3e:	e426                	sd	s1,8(sp)
    80004f40:	1000                	addi	s0,sp,32
    80004f42:	84aa                	mv	s1,a0
	int fd;
	struct proc *p = myproc();
    80004f44:	ffffd097          	auipc	ra,0xffffd
    80004f48:	ae6080e7          	jalr	-1306(ra) # 80001a2a <myproc>
    80004f4c:	862a                	mv	a2,a0

	for(fd = 0; fd < NOFILE; fd++){
    80004f4e:	0d050793          	addi	a5,a0,208 # ffffffffffff80d0 <end+0xffffffff7ffb00d0>
    80004f52:	4501                	li	a0,0
    80004f54:	46c1                	li	a3,16
		if(p->ofile[fd] == 0){
    80004f56:	6398                	ld	a4,0(a5)
    80004f58:	cb19                	beqz	a4,80004f6e <fdalloc+0x36>
	for(fd = 0; fd < NOFILE; fd++){
    80004f5a:	2505                	addiw	a0,a0,1
    80004f5c:	07a1                	addi	a5,a5,8
    80004f5e:	fed51ce3          	bne	a0,a3,80004f56 <fdalloc+0x1e>
			p->ofile[fd] = f;
			return fd;
		}
	}
	return -1;
    80004f62:	557d                	li	a0,-1
}
    80004f64:	60e2                	ld	ra,24(sp)
    80004f66:	6442                	ld	s0,16(sp)
    80004f68:	64a2                	ld	s1,8(sp)
    80004f6a:	6105                	addi	sp,sp,32
    80004f6c:	8082                	ret
			p->ofile[fd] = f;
    80004f6e:	01a50793          	addi	a5,a0,26
    80004f72:	078e                	slli	a5,a5,0x3
    80004f74:	963e                	add	a2,a2,a5
    80004f76:	e204                	sd	s1,0(a2)
			return fd;
    80004f78:	b7f5                	j	80004f64 <fdalloc+0x2c>

0000000080004f7a <create>:
	return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80004f7a:	715d                	addi	sp,sp,-80
    80004f7c:	e486                	sd	ra,72(sp)
    80004f7e:	e0a2                	sd	s0,64(sp)
    80004f80:	fc26                	sd	s1,56(sp)
    80004f82:	f84a                	sd	s2,48(sp)
    80004f84:	f44e                	sd	s3,40(sp)
    80004f86:	f052                	sd	s4,32(sp)
    80004f88:	ec56                	sd	s5,24(sp)
    80004f8a:	0880                	addi	s0,sp,80
    80004f8c:	89ae                	mv	s3,a1
    80004f8e:	8ab2                	mv	s5,a2
    80004f90:	8a36                	mv	s4,a3
	struct inode *ip, *dp;
	char name[DIRSIZ];

	if((dp = nameiparent(path, name)) == 0)
    80004f92:	fb040593          	addi	a1,s0,-80
    80004f96:	fffff097          	auipc	ra,0xfffff
    80004f9a:	e86080e7          	jalr	-378(ra) # 80003e1c <nameiparent>
    80004f9e:	892a                	mv	s2,a0
    80004fa0:	12050f63          	beqz	a0,800050de <create+0x164>
		return 0;

	ilock(dp);
    80004fa4:	ffffe097          	auipc	ra,0xffffe
    80004fa8:	6a4080e7          	jalr	1700(ra) # 80003648 <ilock>

	if((ip = dirlookup(dp, name, 0)) != 0){
    80004fac:	4601                	li	a2,0
    80004fae:	fb040593          	addi	a1,s0,-80
    80004fb2:	854a                	mv	a0,s2
    80004fb4:	fffff097          	auipc	ra,0xfffff
    80004fb8:	b78080e7          	jalr	-1160(ra) # 80003b2c <dirlookup>
    80004fbc:	84aa                	mv	s1,a0
    80004fbe:	c921                	beqz	a0,8000500e <create+0x94>
		iunlockput(dp);
    80004fc0:	854a                	mv	a0,s2
    80004fc2:	fffff097          	auipc	ra,0xfffff
    80004fc6:	8e8080e7          	jalr	-1816(ra) # 800038aa <iunlockput>
		ilock(ip);
    80004fca:	8526                	mv	a0,s1
    80004fcc:	ffffe097          	auipc	ra,0xffffe
    80004fd0:	67c080e7          	jalr	1660(ra) # 80003648 <ilock>
		if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80004fd4:	2981                	sext.w	s3,s3
    80004fd6:	4789                	li	a5,2
    80004fd8:	02f99463          	bne	s3,a5,80005000 <create+0x86>
    80004fdc:	0444d783          	lhu	a5,68(s1)
    80004fe0:	37f9                	addiw	a5,a5,-2
    80004fe2:	17c2                	slli	a5,a5,0x30
    80004fe4:	93c1                	srli	a5,a5,0x30
    80004fe6:	4705                	li	a4,1
    80004fe8:	00f76c63          	bltu	a4,a5,80005000 <create+0x86>
		panic("create: dirlink");

	iunlockput(dp);

	return ip;
}
    80004fec:	8526                	mv	a0,s1
    80004fee:	60a6                	ld	ra,72(sp)
    80004ff0:	6406                	ld	s0,64(sp)
    80004ff2:	74e2                	ld	s1,56(sp)
    80004ff4:	7942                	ld	s2,48(sp)
    80004ff6:	79a2                	ld	s3,40(sp)
    80004ff8:	7a02                	ld	s4,32(sp)
    80004ffa:	6ae2                	ld	s5,24(sp)
    80004ffc:	6161                	addi	sp,sp,80
    80004ffe:	8082                	ret
		iunlockput(ip);
    80005000:	8526                	mv	a0,s1
    80005002:	fffff097          	auipc	ra,0xfffff
    80005006:	8a8080e7          	jalr	-1880(ra) # 800038aa <iunlockput>
		return 0;
    8000500a:	4481                	li	s1,0
    8000500c:	b7c5                	j	80004fec <create+0x72>
	if((ip = ialloc(dp->dev, type)) == 0)
    8000500e:	85ce                	mv	a1,s3
    80005010:	00092503          	lw	a0,0(s2)
    80005014:	ffffe097          	auipc	ra,0xffffe
    80005018:	49c080e7          	jalr	1180(ra) # 800034b0 <ialloc>
    8000501c:	84aa                	mv	s1,a0
    8000501e:	c529                	beqz	a0,80005068 <create+0xee>
	ilock(ip);
    80005020:	ffffe097          	auipc	ra,0xffffe
    80005024:	628080e7          	jalr	1576(ra) # 80003648 <ilock>
	ip->major = major;
    80005028:	05549323          	sh	s5,70(s1)
	ip->minor = minor;
    8000502c:	05449423          	sh	s4,72(s1)
	ip->nlink = 1;
    80005030:	4785                	li	a5,1
    80005032:	04f49523          	sh	a5,74(s1)
	iupdate(ip);
    80005036:	8526                	mv	a0,s1
    80005038:	ffffe097          	auipc	ra,0xffffe
    8000503c:	546080e7          	jalr	1350(ra) # 8000357e <iupdate>
	if(type == T_DIR){  // Create . and .. entries.
    80005040:	2981                	sext.w	s3,s3
    80005042:	4785                	li	a5,1
    80005044:	02f98a63          	beq	s3,a5,80005078 <create+0xfe>
	if(dirlink(dp, name, ip->inum) < 0)
    80005048:	40d0                	lw	a2,4(s1)
    8000504a:	fb040593          	addi	a1,s0,-80
    8000504e:	854a                	mv	a0,s2
    80005050:	fffff097          	auipc	ra,0xfffff
    80005054:	cec080e7          	jalr	-788(ra) # 80003d3c <dirlink>
    80005058:	06054b63          	bltz	a0,800050ce <create+0x154>
	iunlockput(dp);
    8000505c:	854a                	mv	a0,s2
    8000505e:	fffff097          	auipc	ra,0xfffff
    80005062:	84c080e7          	jalr	-1972(ra) # 800038aa <iunlockput>
	return ip;
    80005066:	b759                	j	80004fec <create+0x72>
		panic("create: ialloc");
    80005068:	00003517          	auipc	a0,0x3
    8000506c:	68850513          	addi	a0,a0,1672 # 800086f0 <syscalls+0x2a0>
    80005070:	ffffb097          	auipc	ra,0xffffb
    80005074:	4ce080e7          	jalr	1230(ra) # 8000053e <panic>
		dp->nlink++;  // for ".."
    80005078:	04a95783          	lhu	a5,74(s2)
    8000507c:	2785                	addiw	a5,a5,1
    8000507e:	04f91523          	sh	a5,74(s2)
		iupdate(dp);
    80005082:	854a                	mv	a0,s2
    80005084:	ffffe097          	auipc	ra,0xffffe
    80005088:	4fa080e7          	jalr	1274(ra) # 8000357e <iupdate>
		if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    8000508c:	40d0                	lw	a2,4(s1)
    8000508e:	00003597          	auipc	a1,0x3
    80005092:	67258593          	addi	a1,a1,1650 # 80008700 <syscalls+0x2b0>
    80005096:	8526                	mv	a0,s1
    80005098:	fffff097          	auipc	ra,0xfffff
    8000509c:	ca4080e7          	jalr	-860(ra) # 80003d3c <dirlink>
    800050a0:	00054f63          	bltz	a0,800050be <create+0x144>
    800050a4:	00492603          	lw	a2,4(s2)
    800050a8:	00003597          	auipc	a1,0x3
    800050ac:	66058593          	addi	a1,a1,1632 # 80008708 <syscalls+0x2b8>
    800050b0:	8526                	mv	a0,s1
    800050b2:	fffff097          	auipc	ra,0xfffff
    800050b6:	c8a080e7          	jalr	-886(ra) # 80003d3c <dirlink>
    800050ba:	f80557e3          	bgez	a0,80005048 <create+0xce>
			panic("create dots");
    800050be:	00003517          	auipc	a0,0x3
    800050c2:	65250513          	addi	a0,a0,1618 # 80008710 <syscalls+0x2c0>
    800050c6:	ffffb097          	auipc	ra,0xffffb
    800050ca:	478080e7          	jalr	1144(ra) # 8000053e <panic>
		panic("create: dirlink");
    800050ce:	00003517          	auipc	a0,0x3
    800050d2:	65250513          	addi	a0,a0,1618 # 80008720 <syscalls+0x2d0>
    800050d6:	ffffb097          	auipc	ra,0xffffb
    800050da:	468080e7          	jalr	1128(ra) # 8000053e <panic>
		return 0;
    800050de:	84aa                	mv	s1,a0
    800050e0:	b731                	j	80004fec <create+0x72>

00000000800050e2 <sys_dup>:
{
    800050e2:	7179                	addi	sp,sp,-48
    800050e4:	f406                	sd	ra,40(sp)
    800050e6:	f022                	sd	s0,32(sp)
    800050e8:	ec26                	sd	s1,24(sp)
    800050ea:	1800                	addi	s0,sp,48
	if(argfd(0, 0, &f) < 0)
    800050ec:	fd840613          	addi	a2,s0,-40
    800050f0:	4581                	li	a1,0
    800050f2:	4501                	li	a0,0
    800050f4:	00000097          	auipc	ra,0x0
    800050f8:	ddc080e7          	jalr	-548(ra) # 80004ed0 <argfd>
		return -1;
    800050fc:	57fd                	li	a5,-1
	if(argfd(0, 0, &f) < 0)
    800050fe:	02054363          	bltz	a0,80005124 <sys_dup+0x42>
	if((fd=fdalloc(f)) < 0)
    80005102:	fd843503          	ld	a0,-40(s0)
    80005106:	00000097          	auipc	ra,0x0
    8000510a:	e32080e7          	jalr	-462(ra) # 80004f38 <fdalloc>
    8000510e:	84aa                	mv	s1,a0
		return -1;
    80005110:	57fd                	li	a5,-1
	if((fd=fdalloc(f)) < 0)
    80005112:	00054963          	bltz	a0,80005124 <sys_dup+0x42>
	filedup(f);
    80005116:	fd843503          	ld	a0,-40(s0)
    8000511a:	fffff097          	auipc	ra,0xfffff
    8000511e:	37a080e7          	jalr	890(ra) # 80004494 <filedup>
	return fd;
    80005122:	87a6                	mv	a5,s1
}
    80005124:	853e                	mv	a0,a5
    80005126:	70a2                	ld	ra,40(sp)
    80005128:	7402                	ld	s0,32(sp)
    8000512a:	64e2                	ld	s1,24(sp)
    8000512c:	6145                	addi	sp,sp,48
    8000512e:	8082                	ret

0000000080005130 <sys_read>:
{
    80005130:	7179                	addi	sp,sp,-48
    80005132:	f406                	sd	ra,40(sp)
    80005134:	f022                	sd	s0,32(sp)
    80005136:	1800                	addi	s0,sp,48
	if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005138:	fe840613          	addi	a2,s0,-24
    8000513c:	4581                	li	a1,0
    8000513e:	4501                	li	a0,0
    80005140:	00000097          	auipc	ra,0x0
    80005144:	d90080e7          	jalr	-624(ra) # 80004ed0 <argfd>
		return -1;
    80005148:	57fd                	li	a5,-1
	if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000514a:	04054163          	bltz	a0,8000518c <sys_read+0x5c>
    8000514e:	fe440593          	addi	a1,s0,-28
    80005152:	4509                	li	a0,2
    80005154:	ffffe097          	auipc	ra,0xffffe
    80005158:	982080e7          	jalr	-1662(ra) # 80002ad6 <argint>
		return -1;
    8000515c:	57fd                	li	a5,-1
	if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000515e:	02054763          	bltz	a0,8000518c <sys_read+0x5c>
    80005162:	fd840593          	addi	a1,s0,-40
    80005166:	4505                	li	a0,1
    80005168:	ffffe097          	auipc	ra,0xffffe
    8000516c:	990080e7          	jalr	-1648(ra) # 80002af8 <argaddr>
		return -1;
    80005170:	57fd                	li	a5,-1
	if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005172:	00054d63          	bltz	a0,8000518c <sys_read+0x5c>
	return fileread(f, p, n);
    80005176:	fe442603          	lw	a2,-28(s0)
    8000517a:	fd843583          	ld	a1,-40(s0)
    8000517e:	fe843503          	ld	a0,-24(s0)
    80005182:	fffff097          	auipc	ra,0xfffff
    80005186:	49e080e7          	jalr	1182(ra) # 80004620 <fileread>
    8000518a:	87aa                	mv	a5,a0
}
    8000518c:	853e                	mv	a0,a5
    8000518e:	70a2                	ld	ra,40(sp)
    80005190:	7402                	ld	s0,32(sp)
    80005192:	6145                	addi	sp,sp,48
    80005194:	8082                	ret

0000000080005196 <sys_write>:
{
    80005196:	7179                	addi	sp,sp,-48
    80005198:	f406                	sd	ra,40(sp)
    8000519a:	f022                	sd	s0,32(sp)
    8000519c:	1800                	addi	s0,sp,48
	if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000519e:	fe840613          	addi	a2,s0,-24
    800051a2:	4581                	li	a1,0
    800051a4:	4501                	li	a0,0
    800051a6:	00000097          	auipc	ra,0x0
    800051aa:	d2a080e7          	jalr	-726(ra) # 80004ed0 <argfd>
		return -1;
    800051ae:	57fd                	li	a5,-1
	if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800051b0:	04054163          	bltz	a0,800051f2 <sys_write+0x5c>
    800051b4:	fe440593          	addi	a1,s0,-28
    800051b8:	4509                	li	a0,2
    800051ba:	ffffe097          	auipc	ra,0xffffe
    800051be:	91c080e7          	jalr	-1764(ra) # 80002ad6 <argint>
		return -1;
    800051c2:	57fd                	li	a5,-1
	if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800051c4:	02054763          	bltz	a0,800051f2 <sys_write+0x5c>
    800051c8:	fd840593          	addi	a1,s0,-40
    800051cc:	4505                	li	a0,1
    800051ce:	ffffe097          	auipc	ra,0xffffe
    800051d2:	92a080e7          	jalr	-1750(ra) # 80002af8 <argaddr>
		return -1;
    800051d6:	57fd                	li	a5,-1
	if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800051d8:	00054d63          	bltz	a0,800051f2 <sys_write+0x5c>
	return filewrite(f, p, n);
    800051dc:	fe442603          	lw	a2,-28(s0)
    800051e0:	fd843583          	ld	a1,-40(s0)
    800051e4:	fe843503          	ld	a0,-24(s0)
    800051e8:	fffff097          	auipc	ra,0xfffff
    800051ec:	4fa080e7          	jalr	1274(ra) # 800046e2 <filewrite>
    800051f0:	87aa                	mv	a5,a0
}
    800051f2:	853e                	mv	a0,a5
    800051f4:	70a2                	ld	ra,40(sp)
    800051f6:	7402                	ld	s0,32(sp)
    800051f8:	6145                	addi	sp,sp,48
    800051fa:	8082                	ret

00000000800051fc <sys_close>:
{
    800051fc:	1101                	addi	sp,sp,-32
    800051fe:	ec06                	sd	ra,24(sp)
    80005200:	e822                	sd	s0,16(sp)
    80005202:	1000                	addi	s0,sp,32
	if(argfd(0, &fd, &f) < 0)
    80005204:	fe040613          	addi	a2,s0,-32
    80005208:	fec40593          	addi	a1,s0,-20
    8000520c:	4501                	li	a0,0
    8000520e:	00000097          	auipc	ra,0x0
    80005212:	cc2080e7          	jalr	-830(ra) # 80004ed0 <argfd>
		return -1;
    80005216:	57fd                	li	a5,-1
	if(argfd(0, &fd, &f) < 0)
    80005218:	02054463          	bltz	a0,80005240 <sys_close+0x44>
	myproc()->ofile[fd] = 0;
    8000521c:	ffffd097          	auipc	ra,0xffffd
    80005220:	80e080e7          	jalr	-2034(ra) # 80001a2a <myproc>
    80005224:	fec42783          	lw	a5,-20(s0)
    80005228:	07e9                	addi	a5,a5,26
    8000522a:	078e                	slli	a5,a5,0x3
    8000522c:	97aa                	add	a5,a5,a0
    8000522e:	0007b023          	sd	zero,0(a5)
	fileclose(f);
    80005232:	fe043503          	ld	a0,-32(s0)
    80005236:	fffff097          	auipc	ra,0xfffff
    8000523a:	2b0080e7          	jalr	688(ra) # 800044e6 <fileclose>
	return 0;
    8000523e:	4781                	li	a5,0
}
    80005240:	853e                	mv	a0,a5
    80005242:	60e2                	ld	ra,24(sp)
    80005244:	6442                	ld	s0,16(sp)
    80005246:	6105                	addi	sp,sp,32
    80005248:	8082                	ret

000000008000524a <sys_fstat>:
{
    8000524a:	1101                	addi	sp,sp,-32
    8000524c:	ec06                	sd	ra,24(sp)
    8000524e:	e822                	sd	s0,16(sp)
    80005250:	1000                	addi	s0,sp,32
	if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005252:	fe840613          	addi	a2,s0,-24
    80005256:	4581                	li	a1,0
    80005258:	4501                	li	a0,0
    8000525a:	00000097          	auipc	ra,0x0
    8000525e:	c76080e7          	jalr	-906(ra) # 80004ed0 <argfd>
		return -1;
    80005262:	57fd                	li	a5,-1
	if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005264:	02054563          	bltz	a0,8000528e <sys_fstat+0x44>
    80005268:	fe040593          	addi	a1,s0,-32
    8000526c:	4505                	li	a0,1
    8000526e:	ffffe097          	auipc	ra,0xffffe
    80005272:	88a080e7          	jalr	-1910(ra) # 80002af8 <argaddr>
		return -1;
    80005276:	57fd                	li	a5,-1
	if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005278:	00054b63          	bltz	a0,8000528e <sys_fstat+0x44>
	return filestat(f, st);
    8000527c:	fe043583          	ld	a1,-32(s0)
    80005280:	fe843503          	ld	a0,-24(s0)
    80005284:	fffff097          	auipc	ra,0xfffff
    80005288:	32a080e7          	jalr	810(ra) # 800045ae <filestat>
    8000528c:	87aa                	mv	a5,a0
}
    8000528e:	853e                	mv	a0,a5
    80005290:	60e2                	ld	ra,24(sp)
    80005292:	6442                	ld	s0,16(sp)
    80005294:	6105                	addi	sp,sp,32
    80005296:	8082                	ret

0000000080005298 <sys_link>:
{
    80005298:	7169                	addi	sp,sp,-304
    8000529a:	f606                	sd	ra,296(sp)
    8000529c:	f222                	sd	s0,288(sp)
    8000529e:	ee26                	sd	s1,280(sp)
    800052a0:	ea4a                	sd	s2,272(sp)
    800052a2:	1a00                	addi	s0,sp,304
	if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800052a4:	08000613          	li	a2,128
    800052a8:	ed040593          	addi	a1,s0,-304
    800052ac:	4501                	li	a0,0
    800052ae:	ffffe097          	auipc	ra,0xffffe
    800052b2:	86c080e7          	jalr	-1940(ra) # 80002b1a <argstr>
		return -1;
    800052b6:	57fd                	li	a5,-1
	if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800052b8:	10054e63          	bltz	a0,800053d4 <sys_link+0x13c>
    800052bc:	08000613          	li	a2,128
    800052c0:	f5040593          	addi	a1,s0,-176
    800052c4:	4505                	li	a0,1
    800052c6:	ffffe097          	auipc	ra,0xffffe
    800052ca:	854080e7          	jalr	-1964(ra) # 80002b1a <argstr>
		return -1;
    800052ce:	57fd                	li	a5,-1
	if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800052d0:	10054263          	bltz	a0,800053d4 <sys_link+0x13c>
	begin_op();
    800052d4:	fffff097          	auipc	ra,0xfffff
    800052d8:	d46080e7          	jalr	-698(ra) # 8000401a <begin_op>
	if((ip = namei(old)) == 0){
    800052dc:	ed040513          	addi	a0,s0,-304
    800052e0:	fffff097          	auipc	ra,0xfffff
    800052e4:	b1e080e7          	jalr	-1250(ra) # 80003dfe <namei>
    800052e8:	84aa                	mv	s1,a0
    800052ea:	c551                	beqz	a0,80005376 <sys_link+0xde>
	ilock(ip);
    800052ec:	ffffe097          	auipc	ra,0xffffe
    800052f0:	35c080e7          	jalr	860(ra) # 80003648 <ilock>
	if(ip->type == T_DIR){
    800052f4:	04449703          	lh	a4,68(s1)
    800052f8:	4785                	li	a5,1
    800052fa:	08f70463          	beq	a4,a5,80005382 <sys_link+0xea>
	ip->nlink++;
    800052fe:	04a4d783          	lhu	a5,74(s1)
    80005302:	2785                	addiw	a5,a5,1
    80005304:	04f49523          	sh	a5,74(s1)
	iupdate(ip);
    80005308:	8526                	mv	a0,s1
    8000530a:	ffffe097          	auipc	ra,0xffffe
    8000530e:	274080e7          	jalr	628(ra) # 8000357e <iupdate>
	iunlock(ip);
    80005312:	8526                	mv	a0,s1
    80005314:	ffffe097          	auipc	ra,0xffffe
    80005318:	3f6080e7          	jalr	1014(ra) # 8000370a <iunlock>
	if((dp = nameiparent(new, name)) == 0)
    8000531c:	fd040593          	addi	a1,s0,-48
    80005320:	f5040513          	addi	a0,s0,-176
    80005324:	fffff097          	auipc	ra,0xfffff
    80005328:	af8080e7          	jalr	-1288(ra) # 80003e1c <nameiparent>
    8000532c:	892a                	mv	s2,a0
    8000532e:	c935                	beqz	a0,800053a2 <sys_link+0x10a>
	ilock(dp);
    80005330:	ffffe097          	auipc	ra,0xffffe
    80005334:	318080e7          	jalr	792(ra) # 80003648 <ilock>
	if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005338:	00092703          	lw	a4,0(s2)
    8000533c:	409c                	lw	a5,0(s1)
    8000533e:	04f71d63          	bne	a4,a5,80005398 <sys_link+0x100>
    80005342:	40d0                	lw	a2,4(s1)
    80005344:	fd040593          	addi	a1,s0,-48
    80005348:	854a                	mv	a0,s2
    8000534a:	fffff097          	auipc	ra,0xfffff
    8000534e:	9f2080e7          	jalr	-1550(ra) # 80003d3c <dirlink>
    80005352:	04054363          	bltz	a0,80005398 <sys_link+0x100>
	iunlockput(dp);
    80005356:	854a                	mv	a0,s2
    80005358:	ffffe097          	auipc	ra,0xffffe
    8000535c:	552080e7          	jalr	1362(ra) # 800038aa <iunlockput>
	iput(ip);
    80005360:	8526                	mv	a0,s1
    80005362:	ffffe097          	auipc	ra,0xffffe
    80005366:	4a0080e7          	jalr	1184(ra) # 80003802 <iput>
	end_op();
    8000536a:	fffff097          	auipc	ra,0xfffff
    8000536e:	d30080e7          	jalr	-720(ra) # 8000409a <end_op>
	return 0;
    80005372:	4781                	li	a5,0
    80005374:	a085                	j	800053d4 <sys_link+0x13c>
		end_op();
    80005376:	fffff097          	auipc	ra,0xfffff
    8000537a:	d24080e7          	jalr	-732(ra) # 8000409a <end_op>
		return -1;
    8000537e:	57fd                	li	a5,-1
    80005380:	a891                	j	800053d4 <sys_link+0x13c>
		iunlockput(ip);
    80005382:	8526                	mv	a0,s1
    80005384:	ffffe097          	auipc	ra,0xffffe
    80005388:	526080e7          	jalr	1318(ra) # 800038aa <iunlockput>
		end_op();
    8000538c:	fffff097          	auipc	ra,0xfffff
    80005390:	d0e080e7          	jalr	-754(ra) # 8000409a <end_op>
		return -1;
    80005394:	57fd                	li	a5,-1
    80005396:	a83d                	j	800053d4 <sys_link+0x13c>
		iunlockput(dp);
    80005398:	854a                	mv	a0,s2
    8000539a:	ffffe097          	auipc	ra,0xffffe
    8000539e:	510080e7          	jalr	1296(ra) # 800038aa <iunlockput>
	ilock(ip);
    800053a2:	8526                	mv	a0,s1
    800053a4:	ffffe097          	auipc	ra,0xffffe
    800053a8:	2a4080e7          	jalr	676(ra) # 80003648 <ilock>
	ip->nlink--;
    800053ac:	04a4d783          	lhu	a5,74(s1)
    800053b0:	37fd                	addiw	a5,a5,-1
    800053b2:	04f49523          	sh	a5,74(s1)
	iupdate(ip);
    800053b6:	8526                	mv	a0,s1
    800053b8:	ffffe097          	auipc	ra,0xffffe
    800053bc:	1c6080e7          	jalr	454(ra) # 8000357e <iupdate>
	iunlockput(ip);
    800053c0:	8526                	mv	a0,s1
    800053c2:	ffffe097          	auipc	ra,0xffffe
    800053c6:	4e8080e7          	jalr	1256(ra) # 800038aa <iunlockput>
	end_op();
    800053ca:	fffff097          	auipc	ra,0xfffff
    800053ce:	cd0080e7          	jalr	-816(ra) # 8000409a <end_op>
	return -1;
    800053d2:	57fd                	li	a5,-1
}
    800053d4:	853e                	mv	a0,a5
    800053d6:	70b2                	ld	ra,296(sp)
    800053d8:	7412                	ld	s0,288(sp)
    800053da:	64f2                	ld	s1,280(sp)
    800053dc:	6952                	ld	s2,272(sp)
    800053de:	6155                	addi	sp,sp,304
    800053e0:	8082                	ret

00000000800053e2 <sys_unlink>:
{
    800053e2:	7151                	addi	sp,sp,-240
    800053e4:	f586                	sd	ra,232(sp)
    800053e6:	f1a2                	sd	s0,224(sp)
    800053e8:	eda6                	sd	s1,216(sp)
    800053ea:	e9ca                	sd	s2,208(sp)
    800053ec:	e5ce                	sd	s3,200(sp)
    800053ee:	1980                	addi	s0,sp,240
	if(argstr(0, path, MAXPATH) < 0)
    800053f0:	08000613          	li	a2,128
    800053f4:	f3040593          	addi	a1,s0,-208
    800053f8:	4501                	li	a0,0
    800053fa:	ffffd097          	auipc	ra,0xffffd
    800053fe:	720080e7          	jalr	1824(ra) # 80002b1a <argstr>
    80005402:	18054163          	bltz	a0,80005584 <sys_unlink+0x1a2>
	begin_op();
    80005406:	fffff097          	auipc	ra,0xfffff
    8000540a:	c14080e7          	jalr	-1004(ra) # 8000401a <begin_op>
	if((dp = nameiparent(path, name)) == 0){
    8000540e:	fb040593          	addi	a1,s0,-80
    80005412:	f3040513          	addi	a0,s0,-208
    80005416:	fffff097          	auipc	ra,0xfffff
    8000541a:	a06080e7          	jalr	-1530(ra) # 80003e1c <nameiparent>
    8000541e:	84aa                	mv	s1,a0
    80005420:	c979                	beqz	a0,800054f6 <sys_unlink+0x114>
	ilock(dp);
    80005422:	ffffe097          	auipc	ra,0xffffe
    80005426:	226080e7          	jalr	550(ra) # 80003648 <ilock>
	if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    8000542a:	00003597          	auipc	a1,0x3
    8000542e:	2d658593          	addi	a1,a1,726 # 80008700 <syscalls+0x2b0>
    80005432:	fb040513          	addi	a0,s0,-80
    80005436:	ffffe097          	auipc	ra,0xffffe
    8000543a:	6dc080e7          	jalr	1756(ra) # 80003b12 <namecmp>
    8000543e:	14050a63          	beqz	a0,80005592 <sys_unlink+0x1b0>
    80005442:	00003597          	auipc	a1,0x3
    80005446:	2c658593          	addi	a1,a1,710 # 80008708 <syscalls+0x2b8>
    8000544a:	fb040513          	addi	a0,s0,-80
    8000544e:	ffffe097          	auipc	ra,0xffffe
    80005452:	6c4080e7          	jalr	1732(ra) # 80003b12 <namecmp>
    80005456:	12050e63          	beqz	a0,80005592 <sys_unlink+0x1b0>
	if((ip = dirlookup(dp, name, &off)) == 0)
    8000545a:	f2c40613          	addi	a2,s0,-212
    8000545e:	fb040593          	addi	a1,s0,-80
    80005462:	8526                	mv	a0,s1
    80005464:	ffffe097          	auipc	ra,0xffffe
    80005468:	6c8080e7          	jalr	1736(ra) # 80003b2c <dirlookup>
    8000546c:	892a                	mv	s2,a0
    8000546e:	12050263          	beqz	a0,80005592 <sys_unlink+0x1b0>
	ilock(ip);
    80005472:	ffffe097          	auipc	ra,0xffffe
    80005476:	1d6080e7          	jalr	470(ra) # 80003648 <ilock>
	if(ip->nlink < 1)
    8000547a:	04a91783          	lh	a5,74(s2)
    8000547e:	08f05263          	blez	a5,80005502 <sys_unlink+0x120>
	if(ip->type == T_DIR && !isdirempty(ip)){
    80005482:	04491703          	lh	a4,68(s2)
    80005486:	4785                	li	a5,1
    80005488:	08f70563          	beq	a4,a5,80005512 <sys_unlink+0x130>
	memset(&de, 0, sizeof(de));
    8000548c:	4641                	li	a2,16
    8000548e:	4581                	li	a1,0
    80005490:	fc040513          	addi	a0,s0,-64
    80005494:	ffffc097          	auipc	ra,0xffffc
    80005498:	84c080e7          	jalr	-1972(ra) # 80000ce0 <memset>
	if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000549c:	4741                	li	a4,16
    8000549e:	f2c42683          	lw	a3,-212(s0)
    800054a2:	fc040613          	addi	a2,s0,-64
    800054a6:	4581                	li	a1,0
    800054a8:	8526                	mv	a0,s1
    800054aa:	ffffe097          	auipc	ra,0xffffe
    800054ae:	54a080e7          	jalr	1354(ra) # 800039f4 <writei>
    800054b2:	47c1                	li	a5,16
    800054b4:	0af51563          	bne	a0,a5,8000555e <sys_unlink+0x17c>
	if(ip->type == T_DIR){
    800054b8:	04491703          	lh	a4,68(s2)
    800054bc:	4785                	li	a5,1
    800054be:	0af70863          	beq	a4,a5,8000556e <sys_unlink+0x18c>
	iunlockput(dp);
    800054c2:	8526                	mv	a0,s1
    800054c4:	ffffe097          	auipc	ra,0xffffe
    800054c8:	3e6080e7          	jalr	998(ra) # 800038aa <iunlockput>
	ip->nlink--;
    800054cc:	04a95783          	lhu	a5,74(s2)
    800054d0:	37fd                	addiw	a5,a5,-1
    800054d2:	04f91523          	sh	a5,74(s2)
	iupdate(ip);
    800054d6:	854a                	mv	a0,s2
    800054d8:	ffffe097          	auipc	ra,0xffffe
    800054dc:	0a6080e7          	jalr	166(ra) # 8000357e <iupdate>
	iunlockput(ip);
    800054e0:	854a                	mv	a0,s2
    800054e2:	ffffe097          	auipc	ra,0xffffe
    800054e6:	3c8080e7          	jalr	968(ra) # 800038aa <iunlockput>
	end_op();
    800054ea:	fffff097          	auipc	ra,0xfffff
    800054ee:	bb0080e7          	jalr	-1104(ra) # 8000409a <end_op>
	return 0;
    800054f2:	4501                	li	a0,0
    800054f4:	a84d                	j	800055a6 <sys_unlink+0x1c4>
		end_op();
    800054f6:	fffff097          	auipc	ra,0xfffff
    800054fa:	ba4080e7          	jalr	-1116(ra) # 8000409a <end_op>
		return -1;
    800054fe:	557d                	li	a0,-1
    80005500:	a05d                	j	800055a6 <sys_unlink+0x1c4>
		panic("unlink: nlink < 1");
    80005502:	00003517          	auipc	a0,0x3
    80005506:	22e50513          	addi	a0,a0,558 # 80008730 <syscalls+0x2e0>
    8000550a:	ffffb097          	auipc	ra,0xffffb
    8000550e:	034080e7          	jalr	52(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005512:	04c92703          	lw	a4,76(s2)
    80005516:	02000793          	li	a5,32
    8000551a:	f6e7f9e3          	bgeu	a5,a4,8000548c <sys_unlink+0xaa>
    8000551e:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005522:	4741                	li	a4,16
    80005524:	86ce                	mv	a3,s3
    80005526:	f1840613          	addi	a2,s0,-232
    8000552a:	4581                	li	a1,0
    8000552c:	854a                	mv	a0,s2
    8000552e:	ffffe097          	auipc	ra,0xffffe
    80005532:	3ce080e7          	jalr	974(ra) # 800038fc <readi>
    80005536:	47c1                	li	a5,16
    80005538:	00f51b63          	bne	a0,a5,8000554e <sys_unlink+0x16c>
    if(de.inum != 0)
    8000553c:	f1845783          	lhu	a5,-232(s0)
    80005540:	e7a1                	bnez	a5,80005588 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005542:	29c1                	addiw	s3,s3,16
    80005544:	04c92783          	lw	a5,76(s2)
    80005548:	fcf9ede3          	bltu	s3,a5,80005522 <sys_unlink+0x140>
    8000554c:	b781                	j	8000548c <sys_unlink+0xaa>
      panic("isdirempty: readi");
    8000554e:	00003517          	auipc	a0,0x3
    80005552:	1fa50513          	addi	a0,a0,506 # 80008748 <syscalls+0x2f8>
    80005556:	ffffb097          	auipc	ra,0xffffb
    8000555a:	fe8080e7          	jalr	-24(ra) # 8000053e <panic>
		panic("unlink: writei");
    8000555e:	00003517          	auipc	a0,0x3
    80005562:	20250513          	addi	a0,a0,514 # 80008760 <syscalls+0x310>
    80005566:	ffffb097          	auipc	ra,0xffffb
    8000556a:	fd8080e7          	jalr	-40(ra) # 8000053e <panic>
		dp->nlink--;
    8000556e:	04a4d783          	lhu	a5,74(s1)
    80005572:	37fd                	addiw	a5,a5,-1
    80005574:	04f49523          	sh	a5,74(s1)
		iupdate(dp);
    80005578:	8526                	mv	a0,s1
    8000557a:	ffffe097          	auipc	ra,0xffffe
    8000557e:	004080e7          	jalr	4(ra) # 8000357e <iupdate>
    80005582:	b781                	j	800054c2 <sys_unlink+0xe0>
		return -1;
    80005584:	557d                	li	a0,-1
    80005586:	a005                	j	800055a6 <sys_unlink+0x1c4>
		iunlockput(ip);
    80005588:	854a                	mv	a0,s2
    8000558a:	ffffe097          	auipc	ra,0xffffe
    8000558e:	320080e7          	jalr	800(ra) # 800038aa <iunlockput>
	iunlockput(dp);
    80005592:	8526                	mv	a0,s1
    80005594:	ffffe097          	auipc	ra,0xffffe
    80005598:	316080e7          	jalr	790(ra) # 800038aa <iunlockput>
	end_op();
    8000559c:	fffff097          	auipc	ra,0xfffff
    800055a0:	afe080e7          	jalr	-1282(ra) # 8000409a <end_op>
	return -1;
    800055a4:	557d                	li	a0,-1
}
    800055a6:	70ae                	ld	ra,232(sp)
    800055a8:	740e                	ld	s0,224(sp)
    800055aa:	64ee                	ld	s1,216(sp)
    800055ac:	694e                	ld	s2,208(sp)
    800055ae:	69ae                	ld	s3,200(sp)
    800055b0:	616d                	addi	sp,sp,240
    800055b2:	8082                	ret

00000000800055b4 <sys_open>:

uint64
sys_open(void)
{
    800055b4:	7131                	addi	sp,sp,-192
    800055b6:	fd06                	sd	ra,184(sp)
    800055b8:	f922                	sd	s0,176(sp)
    800055ba:	f526                	sd	s1,168(sp)
    800055bc:	f14a                	sd	s2,160(sp)
    800055be:	ed4e                	sd	s3,152(sp)
    800055c0:	0180                	addi	s0,sp,192
	int fd, omode;
	struct file *f;
	struct inode *ip;
	int n;

	if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    800055c2:	08000613          	li	a2,128
    800055c6:	f5040593          	addi	a1,s0,-176
    800055ca:	4501                	li	a0,0
    800055cc:	ffffd097          	auipc	ra,0xffffd
    800055d0:	54e080e7          	jalr	1358(ra) # 80002b1a <argstr>
		return -1;
    800055d4:	54fd                	li	s1,-1
	if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    800055d6:	0c054163          	bltz	a0,80005698 <sys_open+0xe4>
    800055da:	f4c40593          	addi	a1,s0,-180
    800055de:	4505                	li	a0,1
    800055e0:	ffffd097          	auipc	ra,0xffffd
    800055e4:	4f6080e7          	jalr	1270(ra) # 80002ad6 <argint>
    800055e8:	0a054863          	bltz	a0,80005698 <sys_open+0xe4>

	begin_op();
    800055ec:	fffff097          	auipc	ra,0xfffff
    800055f0:	a2e080e7          	jalr	-1490(ra) # 8000401a <begin_op>

	if(omode & O_CREATE){
    800055f4:	f4c42783          	lw	a5,-180(s0)
    800055f8:	2007f793          	andi	a5,a5,512
    800055fc:	cbdd                	beqz	a5,800056b2 <sys_open+0xfe>
		ip = create(path, T_FILE, 0, 0);
    800055fe:	4681                	li	a3,0
    80005600:	4601                	li	a2,0
    80005602:	4589                	li	a1,2
    80005604:	f5040513          	addi	a0,s0,-176
    80005608:	00000097          	auipc	ra,0x0
    8000560c:	972080e7          	jalr	-1678(ra) # 80004f7a <create>
    80005610:	892a                	mv	s2,a0
		if(ip == 0){
    80005612:	c959                	beqz	a0,800056a8 <sys_open+0xf4>
			end_op();
			return -1;
		}
	}

	if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005614:	04491703          	lh	a4,68(s2)
    80005618:	478d                	li	a5,3
    8000561a:	00f71763          	bne	a4,a5,80005628 <sys_open+0x74>
    8000561e:	04695703          	lhu	a4,70(s2)
    80005622:	47a5                	li	a5,9
    80005624:	0ce7ec63          	bltu	a5,a4,800056fc <sys_open+0x148>
		iunlockput(ip);
		end_op();
		return -1;
	}

	if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005628:	fffff097          	auipc	ra,0xfffff
    8000562c:	e02080e7          	jalr	-510(ra) # 8000442a <filealloc>
    80005630:	89aa                	mv	s3,a0
    80005632:	10050263          	beqz	a0,80005736 <sys_open+0x182>
    80005636:	00000097          	auipc	ra,0x0
    8000563a:	902080e7          	jalr	-1790(ra) # 80004f38 <fdalloc>
    8000563e:	84aa                	mv	s1,a0
    80005640:	0e054663          	bltz	a0,8000572c <sys_open+0x178>
		iunlockput(ip);
		end_op();
		return -1;
	}

	if(ip->type == T_DEVICE){
    80005644:	04491703          	lh	a4,68(s2)
    80005648:	478d                	li	a5,3
    8000564a:	0cf70463          	beq	a4,a5,80005712 <sys_open+0x15e>
		f->type = FD_DEVICE;
		f->major = ip->major;
	} else {
		f->type = FD_INODE;
    8000564e:	4789                	li	a5,2
    80005650:	00f9a023          	sw	a5,0(s3)
		f->off = 0;
    80005654:	0209a023          	sw	zero,32(s3)
	}
	f->ip = ip;
    80005658:	0129bc23          	sd	s2,24(s3)
	f->readable = !(omode & O_WRONLY);
    8000565c:	f4c42783          	lw	a5,-180(s0)
    80005660:	0017c713          	xori	a4,a5,1
    80005664:	8b05                	andi	a4,a4,1
    80005666:	00e98423          	sb	a4,8(s3)
	f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    8000566a:	0037f713          	andi	a4,a5,3
    8000566e:	00e03733          	snez	a4,a4
    80005672:	00e984a3          	sb	a4,9(s3)

	if((omode & O_TRUNC) && ip->type == T_FILE){
    80005676:	4007f793          	andi	a5,a5,1024
    8000567a:	c791                	beqz	a5,80005686 <sys_open+0xd2>
    8000567c:	04491703          	lh	a4,68(s2)
    80005680:	4789                	li	a5,2
    80005682:	08f70f63          	beq	a4,a5,80005720 <sys_open+0x16c>
		itrunc(ip);
	}

	iunlock(ip);
    80005686:	854a                	mv	a0,s2
    80005688:	ffffe097          	auipc	ra,0xffffe
    8000568c:	082080e7          	jalr	130(ra) # 8000370a <iunlock>
	end_op();
    80005690:	fffff097          	auipc	ra,0xfffff
    80005694:	a0a080e7          	jalr	-1526(ra) # 8000409a <end_op>

	return fd;
}
    80005698:	8526                	mv	a0,s1
    8000569a:	70ea                	ld	ra,184(sp)
    8000569c:	744a                	ld	s0,176(sp)
    8000569e:	74aa                	ld	s1,168(sp)
    800056a0:	790a                	ld	s2,160(sp)
    800056a2:	69ea                	ld	s3,152(sp)
    800056a4:	6129                	addi	sp,sp,192
    800056a6:	8082                	ret
			end_op();
    800056a8:	fffff097          	auipc	ra,0xfffff
    800056ac:	9f2080e7          	jalr	-1550(ra) # 8000409a <end_op>
			return -1;
    800056b0:	b7e5                	j	80005698 <sys_open+0xe4>
		if((ip = namei(path)) == 0){
    800056b2:	f5040513          	addi	a0,s0,-176
    800056b6:	ffffe097          	auipc	ra,0xffffe
    800056ba:	748080e7          	jalr	1864(ra) # 80003dfe <namei>
    800056be:	892a                	mv	s2,a0
    800056c0:	c905                	beqz	a0,800056f0 <sys_open+0x13c>
		ilock(ip);
    800056c2:	ffffe097          	auipc	ra,0xffffe
    800056c6:	f86080e7          	jalr	-122(ra) # 80003648 <ilock>
		if(ip->type == T_DIR && omode != O_RDONLY){
    800056ca:	04491703          	lh	a4,68(s2)
    800056ce:	4785                	li	a5,1
    800056d0:	f4f712e3          	bne	a4,a5,80005614 <sys_open+0x60>
    800056d4:	f4c42783          	lw	a5,-180(s0)
    800056d8:	dba1                	beqz	a5,80005628 <sys_open+0x74>
			iunlockput(ip);
    800056da:	854a                	mv	a0,s2
    800056dc:	ffffe097          	auipc	ra,0xffffe
    800056e0:	1ce080e7          	jalr	462(ra) # 800038aa <iunlockput>
			end_op();
    800056e4:	fffff097          	auipc	ra,0xfffff
    800056e8:	9b6080e7          	jalr	-1610(ra) # 8000409a <end_op>
			return -1;
    800056ec:	54fd                	li	s1,-1
    800056ee:	b76d                	j	80005698 <sys_open+0xe4>
			end_op();
    800056f0:	fffff097          	auipc	ra,0xfffff
    800056f4:	9aa080e7          	jalr	-1622(ra) # 8000409a <end_op>
			return -1;
    800056f8:	54fd                	li	s1,-1
    800056fa:	bf79                	j	80005698 <sys_open+0xe4>
		iunlockput(ip);
    800056fc:	854a                	mv	a0,s2
    800056fe:	ffffe097          	auipc	ra,0xffffe
    80005702:	1ac080e7          	jalr	428(ra) # 800038aa <iunlockput>
		end_op();
    80005706:	fffff097          	auipc	ra,0xfffff
    8000570a:	994080e7          	jalr	-1644(ra) # 8000409a <end_op>
		return -1;
    8000570e:	54fd                	li	s1,-1
    80005710:	b761                	j	80005698 <sys_open+0xe4>
		f->type = FD_DEVICE;
    80005712:	00f9a023          	sw	a5,0(s3)
		f->major = ip->major;
    80005716:	04691783          	lh	a5,70(s2)
    8000571a:	02f99223          	sh	a5,36(s3)
    8000571e:	bf2d                	j	80005658 <sys_open+0xa4>
		itrunc(ip);
    80005720:	854a                	mv	a0,s2
    80005722:	ffffe097          	auipc	ra,0xffffe
    80005726:	034080e7          	jalr	52(ra) # 80003756 <itrunc>
    8000572a:	bfb1                	j	80005686 <sys_open+0xd2>
			fileclose(f);
    8000572c:	854e                	mv	a0,s3
    8000572e:	fffff097          	auipc	ra,0xfffff
    80005732:	db8080e7          	jalr	-584(ra) # 800044e6 <fileclose>
		iunlockput(ip);
    80005736:	854a                	mv	a0,s2
    80005738:	ffffe097          	auipc	ra,0xffffe
    8000573c:	172080e7          	jalr	370(ra) # 800038aa <iunlockput>
		end_op();
    80005740:	fffff097          	auipc	ra,0xfffff
    80005744:	95a080e7          	jalr	-1702(ra) # 8000409a <end_op>
		return -1;
    80005748:	54fd                	li	s1,-1
    8000574a:	b7b9                	j	80005698 <sys_open+0xe4>

000000008000574c <sys_mkdir>:

uint64
sys_mkdir(void)
{
    8000574c:	7175                	addi	sp,sp,-144
    8000574e:	e506                	sd	ra,136(sp)
    80005750:	e122                	sd	s0,128(sp)
    80005752:	0900                	addi	s0,sp,144
	char path[MAXPATH];
	struct inode *ip;

	begin_op();
    80005754:	fffff097          	auipc	ra,0xfffff
    80005758:	8c6080e7          	jalr	-1850(ra) # 8000401a <begin_op>
	if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    8000575c:	08000613          	li	a2,128
    80005760:	f7040593          	addi	a1,s0,-144
    80005764:	4501                	li	a0,0
    80005766:	ffffd097          	auipc	ra,0xffffd
    8000576a:	3b4080e7          	jalr	948(ra) # 80002b1a <argstr>
    8000576e:	02054963          	bltz	a0,800057a0 <sys_mkdir+0x54>
    80005772:	4681                	li	a3,0
    80005774:	4601                	li	a2,0
    80005776:	4585                	li	a1,1
    80005778:	f7040513          	addi	a0,s0,-144
    8000577c:	fffff097          	auipc	ra,0xfffff
    80005780:	7fe080e7          	jalr	2046(ra) # 80004f7a <create>
    80005784:	cd11                	beqz	a0,800057a0 <sys_mkdir+0x54>
		end_op();
		return -1;
	}
	iunlockput(ip);
    80005786:	ffffe097          	auipc	ra,0xffffe
    8000578a:	124080e7          	jalr	292(ra) # 800038aa <iunlockput>
	end_op();
    8000578e:	fffff097          	auipc	ra,0xfffff
    80005792:	90c080e7          	jalr	-1780(ra) # 8000409a <end_op>
	return 0;
    80005796:	4501                	li	a0,0
}
    80005798:	60aa                	ld	ra,136(sp)
    8000579a:	640a                	ld	s0,128(sp)
    8000579c:	6149                	addi	sp,sp,144
    8000579e:	8082                	ret
		end_op();
    800057a0:	fffff097          	auipc	ra,0xfffff
    800057a4:	8fa080e7          	jalr	-1798(ra) # 8000409a <end_op>
		return -1;
    800057a8:	557d                	li	a0,-1
    800057aa:	b7fd                	j	80005798 <sys_mkdir+0x4c>

00000000800057ac <sys_mknod>:

uint64
sys_mknod(void)
{
    800057ac:	7135                	addi	sp,sp,-160
    800057ae:	ed06                	sd	ra,152(sp)
    800057b0:	e922                	sd	s0,144(sp)
    800057b2:	1100                	addi	s0,sp,160
	struct inode *ip;
	char path[MAXPATH];
	int major, minor;

	begin_op();
    800057b4:	fffff097          	auipc	ra,0xfffff
    800057b8:	866080e7          	jalr	-1946(ra) # 8000401a <begin_op>
	if((argstr(0, path, MAXPATH)) < 0 ||
    800057bc:	08000613          	li	a2,128
    800057c0:	f7040593          	addi	a1,s0,-144
    800057c4:	4501                	li	a0,0
    800057c6:	ffffd097          	auipc	ra,0xffffd
    800057ca:	354080e7          	jalr	852(ra) # 80002b1a <argstr>
    800057ce:	04054a63          	bltz	a0,80005822 <sys_mknod+0x76>
			argint(1, &major) < 0 ||
    800057d2:	f6c40593          	addi	a1,s0,-148
    800057d6:	4505                	li	a0,1
    800057d8:	ffffd097          	auipc	ra,0xffffd
    800057dc:	2fe080e7          	jalr	766(ra) # 80002ad6 <argint>
	if((argstr(0, path, MAXPATH)) < 0 ||
    800057e0:	04054163          	bltz	a0,80005822 <sys_mknod+0x76>
			argint(2, &minor) < 0 ||
    800057e4:	f6840593          	addi	a1,s0,-152
    800057e8:	4509                	li	a0,2
    800057ea:	ffffd097          	auipc	ra,0xffffd
    800057ee:	2ec080e7          	jalr	748(ra) # 80002ad6 <argint>
			argint(1, &major) < 0 ||
    800057f2:	02054863          	bltz	a0,80005822 <sys_mknod+0x76>
			(ip = create(path, T_DEVICE, major, minor)) == 0){
    800057f6:	f6841683          	lh	a3,-152(s0)
    800057fa:	f6c41603          	lh	a2,-148(s0)
    800057fe:	458d                	li	a1,3
    80005800:	f7040513          	addi	a0,s0,-144
    80005804:	fffff097          	auipc	ra,0xfffff
    80005808:	776080e7          	jalr	1910(ra) # 80004f7a <create>
			argint(2, &minor) < 0 ||
    8000580c:	c919                	beqz	a0,80005822 <sys_mknod+0x76>
		end_op();
		return -1;
	}
	iunlockput(ip);
    8000580e:	ffffe097          	auipc	ra,0xffffe
    80005812:	09c080e7          	jalr	156(ra) # 800038aa <iunlockput>
	end_op();
    80005816:	fffff097          	auipc	ra,0xfffff
    8000581a:	884080e7          	jalr	-1916(ra) # 8000409a <end_op>
	return 0;
    8000581e:	4501                	li	a0,0
    80005820:	a031                	j	8000582c <sys_mknod+0x80>
		end_op();
    80005822:	fffff097          	auipc	ra,0xfffff
    80005826:	878080e7          	jalr	-1928(ra) # 8000409a <end_op>
		return -1;
    8000582a:	557d                	li	a0,-1
}
    8000582c:	60ea                	ld	ra,152(sp)
    8000582e:	644a                	ld	s0,144(sp)
    80005830:	610d                	addi	sp,sp,160
    80005832:	8082                	ret

0000000080005834 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005834:	7135                	addi	sp,sp,-160
    80005836:	ed06                	sd	ra,152(sp)
    80005838:	e922                	sd	s0,144(sp)
    8000583a:	e526                	sd	s1,136(sp)
    8000583c:	e14a                	sd	s2,128(sp)
    8000583e:	1100                	addi	s0,sp,160
	char path[MAXPATH];
	struct inode *ip;
	struct proc *p = myproc();
    80005840:	ffffc097          	auipc	ra,0xffffc
    80005844:	1ea080e7          	jalr	490(ra) # 80001a2a <myproc>
    80005848:	892a                	mv	s2,a0

	begin_op();
    8000584a:	ffffe097          	auipc	ra,0xffffe
    8000584e:	7d0080e7          	jalr	2000(ra) # 8000401a <begin_op>
	if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005852:	08000613          	li	a2,128
    80005856:	f6040593          	addi	a1,s0,-160
    8000585a:	4501                	li	a0,0
    8000585c:	ffffd097          	auipc	ra,0xffffd
    80005860:	2be080e7          	jalr	702(ra) # 80002b1a <argstr>
    80005864:	04054b63          	bltz	a0,800058ba <sys_chdir+0x86>
    80005868:	f6040513          	addi	a0,s0,-160
    8000586c:	ffffe097          	auipc	ra,0xffffe
    80005870:	592080e7          	jalr	1426(ra) # 80003dfe <namei>
    80005874:	84aa                	mv	s1,a0
    80005876:	c131                	beqz	a0,800058ba <sys_chdir+0x86>
		end_op();
		return -1;
	}
	ilock(ip);
    80005878:	ffffe097          	auipc	ra,0xffffe
    8000587c:	dd0080e7          	jalr	-560(ra) # 80003648 <ilock>
	if(ip->type != T_DIR){
    80005880:	04449703          	lh	a4,68(s1)
    80005884:	4785                	li	a5,1
    80005886:	04f71063          	bne	a4,a5,800058c6 <sys_chdir+0x92>
		iunlockput(ip);
		end_op();
		return -1;
	}
	iunlock(ip);
    8000588a:	8526                	mv	a0,s1
    8000588c:	ffffe097          	auipc	ra,0xffffe
    80005890:	e7e080e7          	jalr	-386(ra) # 8000370a <iunlock>
	iput(p->cwd);
    80005894:	15093503          	ld	a0,336(s2)
    80005898:	ffffe097          	auipc	ra,0xffffe
    8000589c:	f6a080e7          	jalr	-150(ra) # 80003802 <iput>
	end_op();
    800058a0:	ffffe097          	auipc	ra,0xffffe
    800058a4:	7fa080e7          	jalr	2042(ra) # 8000409a <end_op>
	p->cwd = ip;
    800058a8:	14993823          	sd	s1,336(s2)
	return 0;
    800058ac:	4501                	li	a0,0
}
    800058ae:	60ea                	ld	ra,152(sp)
    800058b0:	644a                	ld	s0,144(sp)
    800058b2:	64aa                	ld	s1,136(sp)
    800058b4:	690a                	ld	s2,128(sp)
    800058b6:	610d                	addi	sp,sp,160
    800058b8:	8082                	ret
		end_op();
    800058ba:	ffffe097          	auipc	ra,0xffffe
    800058be:	7e0080e7          	jalr	2016(ra) # 8000409a <end_op>
		return -1;
    800058c2:	557d                	li	a0,-1
    800058c4:	b7ed                	j	800058ae <sys_chdir+0x7a>
		iunlockput(ip);
    800058c6:	8526                	mv	a0,s1
    800058c8:	ffffe097          	auipc	ra,0xffffe
    800058cc:	fe2080e7          	jalr	-30(ra) # 800038aa <iunlockput>
		end_op();
    800058d0:	ffffe097          	auipc	ra,0xffffe
    800058d4:	7ca080e7          	jalr	1994(ra) # 8000409a <end_op>
		return -1;
    800058d8:	557d                	li	a0,-1
    800058da:	bfd1                	j	800058ae <sys_chdir+0x7a>

00000000800058dc <sys_exec>:

uint64
sys_exec(void)
{
    800058dc:	7145                	addi	sp,sp,-464
    800058de:	e786                	sd	ra,456(sp)
    800058e0:	e3a2                	sd	s0,448(sp)
    800058e2:	ff26                	sd	s1,440(sp)
    800058e4:	fb4a                	sd	s2,432(sp)
    800058e6:	f74e                	sd	s3,424(sp)
    800058e8:	f352                	sd	s4,416(sp)
    800058ea:	ef56                	sd	s5,408(sp)
    800058ec:	0b80                	addi	s0,sp,464
	char path[MAXPATH], *argv[MAXARG];
	int i;
	uint64 uargv, uarg;

	if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    800058ee:	08000613          	li	a2,128
    800058f2:	f4040593          	addi	a1,s0,-192
    800058f6:	4501                	li	a0,0
    800058f8:	ffffd097          	auipc	ra,0xffffd
    800058fc:	222080e7          	jalr	546(ra) # 80002b1a <argstr>
		return -1;
    80005900:	597d                	li	s2,-1
	if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005902:	0c054a63          	bltz	a0,800059d6 <sys_exec+0xfa>
    80005906:	e3840593          	addi	a1,s0,-456
    8000590a:	4505                	li	a0,1
    8000590c:	ffffd097          	auipc	ra,0xffffd
    80005910:	1ec080e7          	jalr	492(ra) # 80002af8 <argaddr>
    80005914:	0c054163          	bltz	a0,800059d6 <sys_exec+0xfa>
	}
	memset(argv, 0, sizeof(argv));
    80005918:	10000613          	li	a2,256
    8000591c:	4581                	li	a1,0
    8000591e:	e4040513          	addi	a0,s0,-448
    80005922:	ffffb097          	auipc	ra,0xffffb
    80005926:	3be080e7          	jalr	958(ra) # 80000ce0 <memset>
	for(i=0;; i++){
		if(i >= NELEM(argv)){
    8000592a:	e4040493          	addi	s1,s0,-448
	memset(argv, 0, sizeof(argv));
    8000592e:	89a6                	mv	s3,s1
    80005930:	4901                	li	s2,0
		if(i >= NELEM(argv)){
    80005932:	02000a13          	li	s4,32
    80005936:	00090a9b          	sext.w	s5,s2
			goto bad;
		}
		if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    8000593a:	00391513          	slli	a0,s2,0x3
    8000593e:	e3040593          	addi	a1,s0,-464
    80005942:	e3843783          	ld	a5,-456(s0)
    80005946:	953e                	add	a0,a0,a5
    80005948:	ffffd097          	auipc	ra,0xffffd
    8000594c:	0f4080e7          	jalr	244(ra) # 80002a3c <fetchaddr>
    80005950:	02054a63          	bltz	a0,80005984 <sys_exec+0xa8>
			goto bad;
		}
		if(uarg == 0){
    80005954:	e3043783          	ld	a5,-464(s0)
    80005958:	c3b9                	beqz	a5,8000599e <sys_exec+0xc2>
			argv[i] = 0;
			break;
		}
		argv[i] = kalloc();
    8000595a:	ffffb097          	auipc	ra,0xffffb
    8000595e:	19a080e7          	jalr	410(ra) # 80000af4 <kalloc>
    80005962:	85aa                	mv	a1,a0
    80005964:	00a9b023          	sd	a0,0(s3)
		if(argv[i] == 0)
    80005968:	cd11                	beqz	a0,80005984 <sys_exec+0xa8>
			goto bad;
		if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    8000596a:	6621                	lui	a2,0x8
    8000596c:	e3043503          	ld	a0,-464(s0)
    80005970:	ffffd097          	auipc	ra,0xffffd
    80005974:	11e080e7          	jalr	286(ra) # 80002a8e <fetchstr>
    80005978:	00054663          	bltz	a0,80005984 <sys_exec+0xa8>
		if(i >= NELEM(argv)){
    8000597c:	0905                	addi	s2,s2,1
    8000597e:	09a1                	addi	s3,s3,8
    80005980:	fb491be3          	bne	s2,s4,80005936 <sys_exec+0x5a>
		kfree(argv[i]);

	return ret;

bad:
	for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005984:	10048913          	addi	s2,s1,256
    80005988:	6088                	ld	a0,0(s1)
    8000598a:	c529                	beqz	a0,800059d4 <sys_exec+0xf8>
		kfree(argv[i]);
    8000598c:	ffffb097          	auipc	ra,0xffffb
    80005990:	06c080e7          	jalr	108(ra) # 800009f8 <kfree>
	for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005994:	04a1                	addi	s1,s1,8
    80005996:	ff2499e3          	bne	s1,s2,80005988 <sys_exec+0xac>
	return -1;
    8000599a:	597d                	li	s2,-1
    8000599c:	a82d                	j	800059d6 <sys_exec+0xfa>
			argv[i] = 0;
    8000599e:	0a8e                	slli	s5,s5,0x3
    800059a0:	fc040793          	addi	a5,s0,-64
    800059a4:	9abe                	add	s5,s5,a5
    800059a6:	e80ab023          	sd	zero,-384(s5)
	int ret = exec(path, argv);
    800059aa:	e4040593          	addi	a1,s0,-448
    800059ae:	f4040513          	addi	a0,s0,-192
    800059b2:	fffff097          	auipc	ra,0xfffff
    800059b6:	194080e7          	jalr	404(ra) # 80004b46 <exec>
    800059ba:	892a                	mv	s2,a0
	for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800059bc:	10048993          	addi	s3,s1,256
    800059c0:	6088                	ld	a0,0(s1)
    800059c2:	c911                	beqz	a0,800059d6 <sys_exec+0xfa>
		kfree(argv[i]);
    800059c4:	ffffb097          	auipc	ra,0xffffb
    800059c8:	034080e7          	jalr	52(ra) # 800009f8 <kfree>
	for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800059cc:	04a1                	addi	s1,s1,8
    800059ce:	ff3499e3          	bne	s1,s3,800059c0 <sys_exec+0xe4>
    800059d2:	a011                	j	800059d6 <sys_exec+0xfa>
	return -1;
    800059d4:	597d                	li	s2,-1
}
    800059d6:	854a                	mv	a0,s2
    800059d8:	60be                	ld	ra,456(sp)
    800059da:	641e                	ld	s0,448(sp)
    800059dc:	74fa                	ld	s1,440(sp)
    800059de:	795a                	ld	s2,432(sp)
    800059e0:	79ba                	ld	s3,424(sp)
    800059e2:	7a1a                	ld	s4,416(sp)
    800059e4:	6afa                	ld	s5,408(sp)
    800059e6:	6179                	addi	sp,sp,464
    800059e8:	8082                	ret

00000000800059ea <sys_pipe>:

uint64
sys_pipe(void)
{
    800059ea:	7139                	addi	sp,sp,-64
    800059ec:	fc06                	sd	ra,56(sp)
    800059ee:	f822                	sd	s0,48(sp)
    800059f0:	f426                	sd	s1,40(sp)
    800059f2:	0080                	addi	s0,sp,64
	uint64 fdarray; // user pointer to array of two integers
	struct file *rf, *wf;
	int fd0, fd1;
	struct proc *p = myproc();
    800059f4:	ffffc097          	auipc	ra,0xffffc
    800059f8:	036080e7          	jalr	54(ra) # 80001a2a <myproc>
    800059fc:	84aa                	mv	s1,a0

	if(argaddr(0, &fdarray) < 0)
    800059fe:	fd840593          	addi	a1,s0,-40
    80005a02:	4501                	li	a0,0
    80005a04:	ffffd097          	auipc	ra,0xffffd
    80005a08:	0f4080e7          	jalr	244(ra) # 80002af8 <argaddr>
		return -1;
    80005a0c:	57fd                	li	a5,-1
	if(argaddr(0, &fdarray) < 0)
    80005a0e:	0e054063          	bltz	a0,80005aee <sys_pipe+0x104>
	if(pipealloc(&rf, &wf) < 0)
    80005a12:	fc840593          	addi	a1,s0,-56
    80005a16:	fd040513          	addi	a0,s0,-48
    80005a1a:	fffff097          	auipc	ra,0xfffff
    80005a1e:	dfc080e7          	jalr	-516(ra) # 80004816 <pipealloc>
		return -1;
    80005a22:	57fd                	li	a5,-1
	if(pipealloc(&rf, &wf) < 0)
    80005a24:	0c054563          	bltz	a0,80005aee <sys_pipe+0x104>
	fd0 = -1;
    80005a28:	fcf42223          	sw	a5,-60(s0)
	if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005a2c:	fd043503          	ld	a0,-48(s0)
    80005a30:	fffff097          	auipc	ra,0xfffff
    80005a34:	508080e7          	jalr	1288(ra) # 80004f38 <fdalloc>
    80005a38:	fca42223          	sw	a0,-60(s0)
    80005a3c:	08054c63          	bltz	a0,80005ad4 <sys_pipe+0xea>
    80005a40:	fc843503          	ld	a0,-56(s0)
    80005a44:	fffff097          	auipc	ra,0xfffff
    80005a48:	4f4080e7          	jalr	1268(ra) # 80004f38 <fdalloc>
    80005a4c:	fca42023          	sw	a0,-64(s0)
    80005a50:	06054863          	bltz	a0,80005ac0 <sys_pipe+0xd6>
			p->ofile[fd0] = 0;
		fileclose(rf);
		fileclose(wf);
		return -1;
	}
	if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005a54:	4691                	li	a3,4
    80005a56:	fc440613          	addi	a2,s0,-60
    80005a5a:	fd843583          	ld	a1,-40(s0)
    80005a5e:	68a8                	ld	a0,80(s1)
    80005a60:	ffffc097          	auipc	ra,0xffffc
    80005a64:	c10080e7          	jalr	-1008(ra) # 80001670 <copyout>
    80005a68:	02054063          	bltz	a0,80005a88 <sys_pipe+0x9e>
			copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005a6c:	4691                	li	a3,4
    80005a6e:	fc040613          	addi	a2,s0,-64
    80005a72:	fd843583          	ld	a1,-40(s0)
    80005a76:	0591                	addi	a1,a1,4
    80005a78:	68a8                	ld	a0,80(s1)
    80005a7a:	ffffc097          	auipc	ra,0xffffc
    80005a7e:	bf6080e7          	jalr	-1034(ra) # 80001670 <copyout>
		p->ofile[fd1] = 0;
		fileclose(rf);
		fileclose(wf);
		return -1;
	}
	return 0;
    80005a82:	4781                	li	a5,0
	if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005a84:	06055563          	bgez	a0,80005aee <sys_pipe+0x104>
		p->ofile[fd0] = 0;
    80005a88:	fc442783          	lw	a5,-60(s0)
    80005a8c:	07e9                	addi	a5,a5,26
    80005a8e:	078e                	slli	a5,a5,0x3
    80005a90:	97a6                	add	a5,a5,s1
    80005a92:	0007b023          	sd	zero,0(a5)
		p->ofile[fd1] = 0;
    80005a96:	fc042503          	lw	a0,-64(s0)
    80005a9a:	0569                	addi	a0,a0,26
    80005a9c:	050e                	slli	a0,a0,0x3
    80005a9e:	9526                	add	a0,a0,s1
    80005aa0:	00053023          	sd	zero,0(a0)
		fileclose(rf);
    80005aa4:	fd043503          	ld	a0,-48(s0)
    80005aa8:	fffff097          	auipc	ra,0xfffff
    80005aac:	a3e080e7          	jalr	-1474(ra) # 800044e6 <fileclose>
		fileclose(wf);
    80005ab0:	fc843503          	ld	a0,-56(s0)
    80005ab4:	fffff097          	auipc	ra,0xfffff
    80005ab8:	a32080e7          	jalr	-1486(ra) # 800044e6 <fileclose>
		return -1;
    80005abc:	57fd                	li	a5,-1
    80005abe:	a805                	j	80005aee <sys_pipe+0x104>
		if(fd0 >= 0)
    80005ac0:	fc442783          	lw	a5,-60(s0)
    80005ac4:	0007c863          	bltz	a5,80005ad4 <sys_pipe+0xea>
			p->ofile[fd0] = 0;
    80005ac8:	01a78513          	addi	a0,a5,26
    80005acc:	050e                	slli	a0,a0,0x3
    80005ace:	9526                	add	a0,a0,s1
    80005ad0:	00053023          	sd	zero,0(a0)
		fileclose(rf);
    80005ad4:	fd043503          	ld	a0,-48(s0)
    80005ad8:	fffff097          	auipc	ra,0xfffff
    80005adc:	a0e080e7          	jalr	-1522(ra) # 800044e6 <fileclose>
		fileclose(wf);
    80005ae0:	fc843503          	ld	a0,-56(s0)
    80005ae4:	fffff097          	auipc	ra,0xfffff
    80005ae8:	a02080e7          	jalr	-1534(ra) # 800044e6 <fileclose>
		return -1;
    80005aec:	57fd                	li	a5,-1
}
    80005aee:	853e                	mv	a0,a5
    80005af0:	70e2                	ld	ra,56(sp)
    80005af2:	7442                	ld	s0,48(sp)
    80005af4:	74a2                	ld	s1,40(sp)
    80005af6:	6121                	addi	sp,sp,64
    80005af8:	8082                	ret
    80005afa:	0000                	unimp
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
    80005b40:	dc9fc0ef          	jal	ra,80002908 <kerneltrap>
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
    80005bdc:	e26080e7          	jalr	-474(ra) # 800019fe <cpuid>

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
    80005c14:	dee080e7          	jalr	-530(ra) # 800019fe <cpuid>
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
    80005c3c:	dc6080e7          	jalr	-570(ra) # 800019fe <cpuid>
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
    80005c64:	0002a797          	auipc	a5,0x2a
    80005c68:	39c78793          	addi	a5,a5,924 # 80030000 <disk>
    80005c6c:	00a78733          	add	a4,a5,a0
    80005c70:	67c1                	lui	a5,0x10
    80005c72:	97ba                	add	a5,a5,a4
    80005c74:	0187c783          	lbu	a5,24(a5) # 10018 <_entry-0x7ffeffe8>
    80005c78:	e7ad                	bnez	a5,80005ce2 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005c7a:	00451793          	slli	a5,a0,0x4
    80005c7e:	0003a717          	auipc	a4,0x3a
    80005c82:	38270713          	addi	a4,a4,898 # 80040000 <disk+0x10000>
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
    80005ca6:	0002a797          	auipc	a5,0x2a
    80005caa:	35a78793          	addi	a5,a5,858 # 80030000 <disk>
    80005cae:	97aa                	add	a5,a5,a0
    80005cb0:	6541                	lui	a0,0x10
    80005cb2:	953e                	add	a0,a0,a5
    80005cb4:	4785                	li	a5,1
    80005cb6:	00f50c23          	sb	a5,24(a0) # 10018 <_entry-0x7ffeffe8>
  wakeup(&disk.free[0]);
    80005cba:	0003a517          	auipc	a0,0x3a
    80005cbe:	35e50513          	addi	a0,a0,862 # 80040018 <disk+0x10018>
    80005cc2:	ffffc097          	auipc	ra,0xffffc
    80005cc6:	5b0080e7          	jalr	1456(ra) # 80002272 <wakeup>
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
    80005d04:	0003a517          	auipc	a0,0x3a
    80005d08:	42450513          	addi	a0,a0,1060 # 80040128 <disk+0x10128>
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
    80005d6a:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fb675f>
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
    80005d7c:	6721                	lui	a4,0x8
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
    80005d98:	6641                	lui	a2,0x10
    80005d9a:	4581                	li	a1,0
    80005d9c:	0002a517          	auipc	a0,0x2a
    80005da0:	26450513          	addi	a0,a0,612 # 80030000 <disk>
    80005da4:	ffffb097          	auipc	ra,0xffffb
    80005da8:	f3c080e7          	jalr	-196(ra) # 80000ce0 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    80005dac:	0002a717          	auipc	a4,0x2a
    80005db0:	25470713          	addi	a4,a4,596 # 80030000 <disk>
    80005db4:	00f75793          	srli	a5,a4,0xf
    80005db8:	2781                	sext.w	a5,a5
    80005dba:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    80005dbc:	0003a797          	auipc	a5,0x3a
    80005dc0:	24478793          	addi	a5,a5,580 # 80040000 <disk+0x10000>
    80005dc4:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80005dc6:	0002a717          	auipc	a4,0x2a
    80005dca:	2ba70713          	addi	a4,a4,698 # 80030080 <disk+0x80>
    80005dce:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80005dd0:	00032717          	auipc	a4,0x32
    80005dd4:	23070713          	addi	a4,a4,560 # 80038000 <disk+0x8000>
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
    80005e64:	0003a517          	auipc	a0,0x3a
    80005e68:	2c450513          	addi	a0,a0,708 # 80040128 <disk+0x10128>
    80005e6c:	ffffb097          	auipc	ra,0xffffb
    80005e70:	d78080e7          	jalr	-648(ra) # 80000be4 <acquire>
  for(int i = 0; i < 3; i++){
    80005e74:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80005e76:	4c21                	li	s8,8
      disk.free[i] = 0;
    80005e78:	0002ab97          	auipc	s7,0x2a
    80005e7c:	188b8b93          	addi	s7,s7,392 # 80030000 <disk>
    80005e80:	6b41                	lui	s6,0x10
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
    80005e9c:	23548c63          	beq	s1,s5,800060d4 <virtio_disk_rw+0x29e>
    idx[i] = alloc_desc();
    80005ea0:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80005ea2:	0003a697          	auipc	a3,0x3a
    80005ea6:	17668693          	addi	a3,a3,374 # 80040018 <disk+0x10018>
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
    80005ef2:	0003a597          	auipc	a1,0x3a
    80005ef6:	23658593          	addi	a1,a1,566 # 80040128 <disk+0x10128>
    80005efa:	0003a517          	auipc	a0,0x3a
    80005efe:	11e50513          	addi	a0,a0,286 # 80040018 <disk+0x10018>
    80005f02:	ffffc097          	auipc	ra,0xffffc
    80005f06:	1e4080e7          	jalr	484(ra) # 800020e6 <sleep>
  for(int i = 0; i < 3; i++){
    80005f0a:	f9040713          	addi	a4,s0,-112
    80005f0e:	84ce                	mv	s1,s3
    80005f10:	bf41                	j	80005ea0 <virtio_disk_rw+0x6a>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    80005f12:	6705                	lui	a4,0x1
    80005f14:	972e                	add	a4,a4,a1
    80005f16:	0712                	slli	a4,a4,0x4
    80005f18:	0002a697          	auipc	a3,0x2a
    80005f1c:	0e868693          	addi	a3,a3,232 # 80030000 <disk>
    80005f20:	9736                	add	a4,a4,a3
    80005f22:	4685                	li	a3,1
    80005f24:	0ad72423          	sw	a3,168(a4) # 10a8 <_entry-0x7fffef58>
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    80005f28:	6705                	lui	a4,0x1
    80005f2a:	972e                	add	a4,a4,a1
    80005f2c:	0712                	slli	a4,a4,0x4
    80005f2e:	0002a697          	auipc	a3,0x2a
    80005f32:	0d268693          	addi	a3,a3,210 # 80030000 <disk>
    80005f36:	9736                	add	a4,a4,a3
    80005f38:	0a072623          	sw	zero,172(a4) # 10ac <_entry-0x7fffef54>
  buf0->sector = sector;
    80005f3c:	0b973823          	sd	s9,176(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80005f40:	7641                	lui	a2,0xffff0
    80005f42:	963e                	add	a2,a2,a5
    80005f44:	0003a717          	auipc	a4,0x3a
    80005f48:	0bc70713          	addi	a4,a4,188 # 80040000 <disk+0x10000>
    80005f4c:	6314                	ld	a3,0(a4)
    80005f4e:	96b2                	add	a3,a3,a2
    80005f50:	e288                	sd	a0,0(a3)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80005f52:	6314                	ld	a3,0(a4)
    80005f54:	96b2                	add	a3,a3,a2
    80005f56:	4541                	li	a0,16
    80005f58:	c688                	sw	a0,8(a3)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80005f5a:	6314                	ld	a3,0(a4)
    80005f5c:	96b2                	add	a3,a3,a2
    80005f5e:	4505                	li	a0,1
    80005f60:	00a69623          	sh	a0,12(a3)
  disk.desc[idx[0]].next = idx[1];
    80005f64:	f9442683          	lw	a3,-108(s0)
    80005f68:	6308                	ld	a0,0(a4)
    80005f6a:	962a                	add	a2,a2,a0
    80005f6c:	00d61723          	sh	a3,14(a2) # ffffffffffff000e <end+0xffffffff7ffa800e>

  disk.desc[idx[1]].addr = (uint64) b->data;
    80005f70:	0692                	slli	a3,a3,0x4
    80005f72:	6310                	ld	a2,0(a4)
    80005f74:	9636                	add	a2,a2,a3
    80005f76:	05890513          	addi	a0,s2,88
    80005f7a:	e208                	sd	a0,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    80005f7c:	6318                	ld	a4,0(a4)
    80005f7e:	9736                	add	a4,a4,a3
    80005f80:	40000613          	li	a2,1024
    80005f84:	c710                	sw	a2,8(a4)
  if(write)
    80005f86:	120d0e63          	beqz	s10,800060c2 <virtio_disk_rw+0x28c>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    80005f8a:	0003a717          	auipc	a4,0x3a
    80005f8e:	07673703          	ld	a4,118(a4) # 80040000 <disk+0x10000>
    80005f92:	9736                	add	a4,a4,a3
    80005f94:	00071623          	sh	zero,12(a4)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80005f98:	0002a817          	auipc	a6,0x2a
    80005f9c:	06880813          	addi	a6,a6,104 # 80030000 <disk>
    80005fa0:	0003a717          	auipc	a4,0x3a
    80005fa4:	06070713          	addi	a4,a4,96 # 80040000 <disk+0x10000>
    80005fa8:	6310                	ld	a2,0(a4)
    80005faa:	9636                	add	a2,a2,a3
    80005fac:	00c65503          	lhu	a0,12(a2)
    80005fb0:	00156513          	ori	a0,a0,1
    80005fb4:	00a61623          	sh	a0,12(a2)
  disk.desc[idx[1]].next = idx[2];
    80005fb8:	f9842603          	lw	a2,-104(s0)
    80005fbc:	6308                	ld	a0,0(a4)
    80005fbe:	96aa                	add	a3,a3,a0
    80005fc0:	00c69723          	sh	a2,14(a3)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80005fc4:	6685                	lui	a3,0x1
    80005fc6:	96ae                	add	a3,a3,a1
    80005fc8:	0692                	slli	a3,a3,0x4
    80005fca:	96c2                	add	a3,a3,a6
    80005fcc:	557d                	li	a0,-1
    80005fce:	02a68823          	sb	a0,48(a3) # 1030 <_entry-0x7fffefd0>
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80005fd2:	0612                	slli	a2,a2,0x4
    80005fd4:	6308                	ld	a0,0(a4)
    80005fd6:	9532                	add	a0,a0,a2
    80005fd8:	03078793          	addi	a5,a5,48
    80005fdc:	97c2                	add	a5,a5,a6
    80005fde:	e11c                	sd	a5,0(a0)
  disk.desc[idx[2]].len = 1;
    80005fe0:	631c                	ld	a5,0(a4)
    80005fe2:	97b2                	add	a5,a5,a2
    80005fe4:	4505                	li	a0,1
    80005fe6:	c788                	sw	a0,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80005fe8:	631c                	ld	a5,0(a4)
    80005fea:	97b2                	add	a5,a5,a2
    80005fec:	4809                	li	a6,2
    80005fee:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80005ff2:	631c                	ld	a5,0(a4)
    80005ff4:	963e                	add	a2,a2,a5
    80005ff6:	00061723          	sh	zero,14(a2)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80005ffa:	00a92223          	sw	a0,4(s2)
  disk.info[idx[0]].b = b;
    80005ffe:	0326b423          	sd	s2,40(a3)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006002:	6714                	ld	a3,8(a4)
    80006004:	0026d783          	lhu	a5,2(a3)
    80006008:	8b9d                	andi	a5,a5,7
    8000600a:	0786                	slli	a5,a5,0x1
    8000600c:	97b6                	add	a5,a5,a3
    8000600e:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    80006012:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006016:	6718                	ld	a4,8(a4)
    80006018:	00275783          	lhu	a5,2(a4)
    8000601c:	2785                	addiw	a5,a5,1
    8000601e:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006022:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006026:	100017b7          	lui	a5,0x10001
    8000602a:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    8000602e:	00492703          	lw	a4,4(s2)
    80006032:	4785                	li	a5,1
    80006034:	02f71163          	bne	a4,a5,80006056 <virtio_disk_rw+0x220>
    sleep(b, &disk.vdisk_lock);
    80006038:	0003a997          	auipc	s3,0x3a
    8000603c:	0f098993          	addi	s3,s3,240 # 80040128 <disk+0x10128>
  while(b->disk == 1) {
    80006040:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006042:	85ce                	mv	a1,s3
    80006044:	854a                	mv	a0,s2
    80006046:	ffffc097          	auipc	ra,0xffffc
    8000604a:	0a0080e7          	jalr	160(ra) # 800020e6 <sleep>
  while(b->disk == 1) {
    8000604e:	00492783          	lw	a5,4(s2)
    80006052:	fe9788e3          	beq	a5,s1,80006042 <virtio_disk_rw+0x20c>
  }

  disk.info[idx[0]].b = 0;
    80006056:	f9042903          	lw	s2,-112(s0)
    8000605a:	6785                	lui	a5,0x1
    8000605c:	97ca                	add	a5,a5,s2
    8000605e:	0792                	slli	a5,a5,0x4
    80006060:	0002a717          	auipc	a4,0x2a
    80006064:	fa070713          	addi	a4,a4,-96 # 80030000 <disk>
    80006068:	97ba                	add	a5,a5,a4
    8000606a:	0207b423          	sd	zero,40(a5) # 1028 <_entry-0x7fffefd8>
    int flag = disk.desc[i].flags;
    8000606e:	0003a997          	auipc	s3,0x3a
    80006072:	f9298993          	addi	s3,s3,-110 # 80040000 <disk+0x10000>
    80006076:	00491713          	slli	a4,s2,0x4
    8000607a:	0009b783          	ld	a5,0(s3)
    8000607e:	97ba                	add	a5,a5,a4
    80006080:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006084:	854a                	mv	a0,s2
    80006086:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    8000608a:	00000097          	auipc	ra,0x0
    8000608e:	bcc080e7          	jalr	-1076(ra) # 80005c56 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80006092:	8885                	andi	s1,s1,1
    80006094:	f0ed                	bnez	s1,80006076 <virtio_disk_rw+0x240>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006096:	0003a517          	auipc	a0,0x3a
    8000609a:	09250513          	addi	a0,a0,146 # 80040128 <disk+0x10128>
    8000609e:	ffffb097          	auipc	ra,0xffffb
    800060a2:	bfa080e7          	jalr	-1030(ra) # 80000c98 <release>
}
    800060a6:	70a6                	ld	ra,104(sp)
    800060a8:	7406                	ld	s0,96(sp)
    800060aa:	64e6                	ld	s1,88(sp)
    800060ac:	6946                	ld	s2,80(sp)
    800060ae:	69a6                	ld	s3,72(sp)
    800060b0:	6a06                	ld	s4,64(sp)
    800060b2:	7ae2                	ld	s5,56(sp)
    800060b4:	7b42                	ld	s6,48(sp)
    800060b6:	7ba2                	ld	s7,40(sp)
    800060b8:	7c02                	ld	s8,32(sp)
    800060ba:	6ce2                	ld	s9,24(sp)
    800060bc:	6d42                	ld	s10,16(sp)
    800060be:	6165                	addi	sp,sp,112
    800060c0:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    800060c2:	0003a717          	auipc	a4,0x3a
    800060c6:	f3e73703          	ld	a4,-194(a4) # 80040000 <disk+0x10000>
    800060ca:	9736                	add	a4,a4,a3
    800060cc:	4609                	li	a2,2
    800060ce:	00c71623          	sh	a2,12(a4)
    800060d2:	b5d9                	j	80005f98 <virtio_disk_rw+0x162>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800060d4:	f9042583          	lw	a1,-112(s0)
    800060d8:	6785                	lui	a5,0x1
    800060da:	97ae                	add	a5,a5,a1
    800060dc:	0792                	slli	a5,a5,0x4
    800060de:	0002a517          	auipc	a0,0x2a
    800060e2:	fca50513          	addi	a0,a0,-54 # 800300a8 <disk+0xa8>
    800060e6:	953e                	add	a0,a0,a5
  if(write)
    800060e8:	e20d15e3          	bnez	s10,80005f12 <virtio_disk_rw+0xdc>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    800060ec:	6705                	lui	a4,0x1
    800060ee:	972e                	add	a4,a4,a1
    800060f0:	0712                	slli	a4,a4,0x4
    800060f2:	0002a697          	auipc	a3,0x2a
    800060f6:	f0e68693          	addi	a3,a3,-242 # 80030000 <disk>
    800060fa:	9736                	add	a4,a4,a3
    800060fc:	0a072423          	sw	zero,168(a4) # 10a8 <_entry-0x7fffef58>
    80006100:	b525                	j	80005f28 <virtio_disk_rw+0xf2>

0000000080006102 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006102:	7179                	addi	sp,sp,-48
    80006104:	f406                	sd	ra,40(sp)
    80006106:	f022                	sd	s0,32(sp)
    80006108:	ec26                	sd	s1,24(sp)
    8000610a:	e84a                	sd	s2,16(sp)
    8000610c:	e44e                	sd	s3,8(sp)
    8000610e:	1800                	addi	s0,sp,48
  acquire(&disk.vdisk_lock);
    80006110:	0003a517          	auipc	a0,0x3a
    80006114:	01850513          	addi	a0,a0,24 # 80040128 <disk+0x10128>
    80006118:	ffffb097          	auipc	ra,0xffffb
    8000611c:	acc080e7          	jalr	-1332(ra) # 80000be4 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006120:	10001737          	lui	a4,0x10001
    80006124:	533c                	lw	a5,96(a4)
    80006126:	8b8d                	andi	a5,a5,3
    80006128:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    8000612a:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    8000612e:	0003a797          	auipc	a5,0x3a
    80006132:	ed278793          	addi	a5,a5,-302 # 80040000 <disk+0x10000>
    80006136:	6b94                	ld	a3,16(a5)
    80006138:	0207d703          	lhu	a4,32(a5)
    8000613c:	0026d783          	lhu	a5,2(a3)
    80006140:	06f70163          	beq	a4,a5,800061a2 <virtio_disk_intr+0xa0>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006144:	0002a997          	auipc	s3,0x2a
    80006148:	ebc98993          	addi	s3,s3,-324 # 80030000 <disk>
    8000614c:	0003a497          	auipc	s1,0x3a
    80006150:	eb448493          	addi	s1,s1,-332 # 80040000 <disk+0x10000>

    if(disk.info[id].status != 0)
    80006154:	6905                	lui	s2,0x1
    __sync_synchronize();
    80006156:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    8000615a:	6898                	ld	a4,16(s1)
    8000615c:	0204d783          	lhu	a5,32(s1)
    80006160:	8b9d                	andi	a5,a5,7
    80006162:	078e                	slli	a5,a5,0x3
    80006164:	97ba                	add	a5,a5,a4
    80006166:	43dc                	lw	a5,4(a5)
    if(disk.info[id].status != 0)
    80006168:	01278733          	add	a4,a5,s2
    8000616c:	0712                	slli	a4,a4,0x4
    8000616e:	974e                	add	a4,a4,s3
    80006170:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    80006174:	e731                	bnez	a4,800061c0 <virtio_disk_intr+0xbe>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006176:	97ca                	add	a5,a5,s2
    80006178:	0792                	slli	a5,a5,0x4
    8000617a:	97ce                	add	a5,a5,s3
    8000617c:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    8000617e:	00052223          	sw	zero,4(a0)
    wakeup(b);
    80006182:	ffffc097          	auipc	ra,0xffffc
    80006186:	0f0080e7          	jalr	240(ra) # 80002272 <wakeup>

    disk.used_idx += 1;
    8000618a:	0204d783          	lhu	a5,32(s1)
    8000618e:	2785                	addiw	a5,a5,1
    80006190:	17c2                	slli	a5,a5,0x30
    80006192:	93c1                	srli	a5,a5,0x30
    80006194:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006198:	6898                	ld	a4,16(s1)
    8000619a:	00275703          	lhu	a4,2(a4)
    8000619e:	faf71ce3          	bne	a4,a5,80006156 <virtio_disk_intr+0x54>
  }

  release(&disk.vdisk_lock);
    800061a2:	0003a517          	auipc	a0,0x3a
    800061a6:	f8650513          	addi	a0,a0,-122 # 80040128 <disk+0x10128>
    800061aa:	ffffb097          	auipc	ra,0xffffb
    800061ae:	aee080e7          	jalr	-1298(ra) # 80000c98 <release>
}
    800061b2:	70a2                	ld	ra,40(sp)
    800061b4:	7402                	ld	s0,32(sp)
    800061b6:	64e2                	ld	s1,24(sp)
    800061b8:	6942                	ld	s2,16(sp)
    800061ba:	69a2                	ld	s3,8(sp)
    800061bc:	6145                	addi	sp,sp,48
    800061be:	8082                	ret
      panic("virtio_disk_intr status");
    800061c0:	00002517          	auipc	a0,0x2
    800061c4:	64050513          	addi	a0,a0,1600 # 80008800 <syscalls+0x3b0>
    800061c8:	ffffa097          	auipc	ra,0xffffa
    800061cc:	376080e7          	jalr	886(ra) # 8000053e <panic>
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
