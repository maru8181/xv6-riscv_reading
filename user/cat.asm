
user/_cat:     file format elf64-littleriscv


Disassembly of section .text:

0000000000000000 <cat>:

char buf[512];

void
cat(int fd)
{
   0:	7179                	addi	sp,sp,-48
   2:	f406                	sd	ra,40(sp)
   4:	f022                	sd	s0,32(sp)
   6:	ec26                	sd	s1,24(sp)
   8:	e84a                	sd	s2,16(sp)
   a:	e44e                	sd	s3,8(sp)
   c:	e052                	sd	s4,0(sp)
   e:	1800                	addi	s0,sp,48
  10:	8a2a                	mv	s4,a0
	int n;

	while((n = read(fd, buf, sizeof(buf))) > 1) {
  12:	00001997          	auipc	s3,0x1
  16:	91698993          	addi	s3,s3,-1770 # 928 <buf>
  1a:	4905                	li	s2,1
  1c:	20000613          	li	a2,512
  20:	85ce                	mv	a1,s3
  22:	8552                	mv	a0,s4
  24:	00000097          	auipc	ra,0x0
  28:	38e080e7          	jalr	910(ra) # 3b2 <read>
  2c:	84aa                	mv	s1,a0
  2e:	02a95963          	bge	s2,a0,60 <cat+0x60>
		if (write(1, buf, n) != n) {
  32:	8626                	mv	a2,s1
  34:	85ce                	mv	a1,s3
  36:	854a                	mv	a0,s2
  38:	00000097          	auipc	ra,0x0
  3c:	382080e7          	jalr	898(ra) # 3ba <write>
  40:	fc950ee3          	beq	a0,s1,1c <cat+0x1c>
			fprintf(2, "cat: write error\n");
  44:	00001597          	auipc	a1,0x1
  48:	87458593          	addi	a1,a1,-1932 # 8b8 <malloc+0xe8>
  4c:	4509                	li	a0,2
  4e:	00000097          	auipc	ra,0x0
  52:	696080e7          	jalr	1686(ra) # 6e4 <fprintf>
			exit(1);
  56:	4505                	li	a0,1
  58:	00000097          	auipc	ra,0x0
  5c:	342080e7          	jalr	834(ra) # 39a <exit>
		}
	}
	if(n < 0){
  60:	00054a63          	bltz	a0,74 <cat+0x74>
		fprintf(2, "cat: read error\n");
		exit(1);
	}
}
  64:	70a2                	ld	ra,40(sp)
  66:	7402                	ld	s0,32(sp)
  68:	64e2                	ld	s1,24(sp)
  6a:	6942                	ld	s2,16(sp)
  6c:	69a2                	ld	s3,8(sp)
  6e:	6a02                	ld	s4,0(sp)
  70:	6145                	addi	sp,sp,48
  72:	8082                	ret
		fprintf(2, "cat: read error\n");
  74:	00001597          	auipc	a1,0x1
  78:	85c58593          	addi	a1,a1,-1956 # 8d0 <malloc+0x100>
  7c:	4509                	li	a0,2
  7e:	00000097          	auipc	ra,0x0
  82:	666080e7          	jalr	1638(ra) # 6e4 <fprintf>
		exit(1);
  86:	4505                	li	a0,1
  88:	00000097          	auipc	ra,0x0
  8c:	312080e7          	jalr	786(ra) # 39a <exit>

0000000000000090 <main>:

int
main(int argc, char *argv[])
{
  90:	7179                	addi	sp,sp,-48
  92:	f406                	sd	ra,40(sp)
  94:	f022                	sd	s0,32(sp)
  96:	ec26                	sd	s1,24(sp)
  98:	e84a                	sd	s2,16(sp)
  9a:	e44e                	sd	s3,8(sp)
  9c:	e052                	sd	s4,0(sp)
  9e:	1800                	addi	s0,sp,48
	int fd, i;

	if(argc <= 1){
  a0:	4785                	li	a5,1
  a2:	04a7d763          	bge	a5,a0,f0 <main+0x60>
  a6:	00858913          	addi	s2,a1,8
  aa:	ffe5099b          	addiw	s3,a0,-2
  ae:	1982                	slli	s3,s3,0x20
  b0:	0209d993          	srli	s3,s3,0x20
  b4:	098e                	slli	s3,s3,0x3
  b6:	05c1                	addi	a1,a1,16
  b8:	99ae                	add	s3,s3,a1
		cat(0);
		exit(0);
	}

	for(i = 1; i < argc; i++){
		if((fd = open(argv[i], 0)) < 0){
  ba:	4581                	li	a1,0
  bc:	00093503          	ld	a0,0(s2)
  c0:	00000097          	auipc	ra,0x0
  c4:	31a080e7          	jalr	794(ra) # 3da <open>
  c8:	84aa                	mv	s1,a0
  ca:	02054d63          	bltz	a0,104 <main+0x74>
			fprintf(2, "cat: cannot open %s\n", argv[i]);
			exit(1);
		}
		cat(fd);
  ce:	00000097          	auipc	ra,0x0
  d2:	f32080e7          	jalr	-206(ra) # 0 <cat>
		close(fd);
  d6:	8526                	mv	a0,s1
  d8:	00000097          	auipc	ra,0x0
  dc:	2ea080e7          	jalr	746(ra) # 3c2 <close>
	for(i = 1; i < argc; i++){
  e0:	0921                	addi	s2,s2,8
  e2:	fd391ce3          	bne	s2,s3,ba <main+0x2a>
	}
	exit(0);
  e6:	4501                	li	a0,0
  e8:	00000097          	auipc	ra,0x0
  ec:	2b2080e7          	jalr	690(ra) # 39a <exit>
		cat(0);
  f0:	4501                	li	a0,0
  f2:	00000097          	auipc	ra,0x0
  f6:	f0e080e7          	jalr	-242(ra) # 0 <cat>
		exit(0);
  fa:	4501                	li	a0,0
  fc:	00000097          	auipc	ra,0x0
 100:	29e080e7          	jalr	670(ra) # 39a <exit>
			fprintf(2, "cat: cannot open %s\n", argv[i]);
 104:	00093603          	ld	a2,0(s2)
 108:	00000597          	auipc	a1,0x0
 10c:	7e058593          	addi	a1,a1,2016 # 8e8 <malloc+0x118>
 110:	4509                	li	a0,2
 112:	00000097          	auipc	ra,0x0
 116:	5d2080e7          	jalr	1490(ra) # 6e4 <fprintf>
			exit(1);
 11a:	4505                	li	a0,1
 11c:	00000097          	auipc	ra,0x0
 120:	27e080e7          	jalr	638(ra) # 39a <exit>

0000000000000124 <strcpy>:
#include "kernel/fcntl.h"
#include "user/user.h"

char*
strcpy(char *s, const char *t)
{
 124:	1141                	addi	sp,sp,-16
 126:	e422                	sd	s0,8(sp)
 128:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
 12a:	87aa                	mv	a5,a0
 12c:	0585                	addi	a1,a1,1
 12e:	0785                	addi	a5,a5,1
 130:	fff5c703          	lbu	a4,-1(a1)
 134:	fee78fa3          	sb	a4,-1(a5)
 138:	fb75                	bnez	a4,12c <strcpy+0x8>
    ;
  return os;
}
 13a:	6422                	ld	s0,8(sp)
 13c:	0141                	addi	sp,sp,16
 13e:	8082                	ret

0000000000000140 <strcmp>:

int
strcmp(const char *p, const char *q)
{
 140:	1141                	addi	sp,sp,-16
 142:	e422                	sd	s0,8(sp)
 144:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
 146:	00054783          	lbu	a5,0(a0)
 14a:	cb91                	beqz	a5,15e <strcmp+0x1e>
 14c:	0005c703          	lbu	a4,0(a1)
 150:	00f71763          	bne	a4,a5,15e <strcmp+0x1e>
    p++, q++;
 154:	0505                	addi	a0,a0,1
 156:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
 158:	00054783          	lbu	a5,0(a0)
 15c:	fbe5                	bnez	a5,14c <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
 15e:	0005c503          	lbu	a0,0(a1)
}
 162:	40a7853b          	subw	a0,a5,a0
 166:	6422                	ld	s0,8(sp)
 168:	0141                	addi	sp,sp,16
 16a:	8082                	ret

000000000000016c <strlen>:

uint
strlen(const char *s)
{
 16c:	1141                	addi	sp,sp,-16
 16e:	e422                	sd	s0,8(sp)
 170:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
 172:	00054783          	lbu	a5,0(a0)
 176:	cf91                	beqz	a5,192 <strlen+0x26>
 178:	0505                	addi	a0,a0,1
 17a:	87aa                	mv	a5,a0
 17c:	4685                	li	a3,1
 17e:	9e89                	subw	a3,a3,a0
 180:	00f6853b          	addw	a0,a3,a5
 184:	0785                	addi	a5,a5,1
 186:	fff7c703          	lbu	a4,-1(a5)
 18a:	fb7d                	bnez	a4,180 <strlen+0x14>
    ;
  return n;
}
 18c:	6422                	ld	s0,8(sp)
 18e:	0141                	addi	sp,sp,16
 190:	8082                	ret
  for(n = 0; s[n]; n++)
 192:	4501                	li	a0,0
 194:	bfe5                	j	18c <strlen+0x20>

0000000000000196 <memset>:

void*
memset(void *dst, int c, uint n)
{
 196:	1141                	addi	sp,sp,-16
 198:	e422                	sd	s0,8(sp)
 19a:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
 19c:	ce09                	beqz	a2,1b6 <memset+0x20>
 19e:	87aa                	mv	a5,a0
 1a0:	fff6071b          	addiw	a4,a2,-1
 1a4:	1702                	slli	a4,a4,0x20
 1a6:	9301                	srli	a4,a4,0x20
 1a8:	0705                	addi	a4,a4,1
 1aa:	972a                	add	a4,a4,a0
    cdst[i] = c;
 1ac:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
 1b0:	0785                	addi	a5,a5,1
 1b2:	fee79de3          	bne	a5,a4,1ac <memset+0x16>
  }
  return dst;
}
 1b6:	6422                	ld	s0,8(sp)
 1b8:	0141                	addi	sp,sp,16
 1ba:	8082                	ret

00000000000001bc <strchr>:

char*
strchr(const char *s, char c)
{
 1bc:	1141                	addi	sp,sp,-16
 1be:	e422                	sd	s0,8(sp)
 1c0:	0800                	addi	s0,sp,16
  for(; *s; s++)
 1c2:	00054783          	lbu	a5,0(a0)
 1c6:	cb99                	beqz	a5,1dc <strchr+0x20>
    if(*s == c)
 1c8:	00f58763          	beq	a1,a5,1d6 <strchr+0x1a>
  for(; *s; s++)
 1cc:	0505                	addi	a0,a0,1
 1ce:	00054783          	lbu	a5,0(a0)
 1d2:	fbfd                	bnez	a5,1c8 <strchr+0xc>
      return (char*)s;
  return 0;
 1d4:	4501                	li	a0,0
}
 1d6:	6422                	ld	s0,8(sp)
 1d8:	0141                	addi	sp,sp,16
 1da:	8082                	ret
  return 0;
 1dc:	4501                	li	a0,0
 1de:	bfe5                	j	1d6 <strchr+0x1a>

00000000000001e0 <gets>:

char*
gets(char *buf, int max)
{
 1e0:	711d                	addi	sp,sp,-96
 1e2:	ec86                	sd	ra,88(sp)
 1e4:	e8a2                	sd	s0,80(sp)
 1e6:	e4a6                	sd	s1,72(sp)
 1e8:	e0ca                	sd	s2,64(sp)
 1ea:	fc4e                	sd	s3,56(sp)
 1ec:	f852                	sd	s4,48(sp)
 1ee:	f456                	sd	s5,40(sp)
 1f0:	f05a                	sd	s6,32(sp)
 1f2:	ec5e                	sd	s7,24(sp)
 1f4:	1080                	addi	s0,sp,96
 1f6:	8baa                	mv	s7,a0
 1f8:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 1fa:	892a                	mv	s2,a0
 1fc:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
 1fe:	4aa9                	li	s5,10
 200:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
 202:	89a6                	mv	s3,s1
 204:	2485                	addiw	s1,s1,1
 206:	0344d863          	bge	s1,s4,236 <gets+0x56>
    cc = read(0, &c, 1);
 20a:	4605                	li	a2,1
 20c:	faf40593          	addi	a1,s0,-81
 210:	4501                	li	a0,0
 212:	00000097          	auipc	ra,0x0
 216:	1a0080e7          	jalr	416(ra) # 3b2 <read>
    if(cc < 1)
 21a:	00a05e63          	blez	a0,236 <gets+0x56>
    buf[i++] = c;
 21e:	faf44783          	lbu	a5,-81(s0)
 222:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
 226:	01578763          	beq	a5,s5,234 <gets+0x54>
 22a:	0905                	addi	s2,s2,1
 22c:	fd679be3          	bne	a5,s6,202 <gets+0x22>
  for(i=0; i+1 < max; ){
 230:	89a6                	mv	s3,s1
 232:	a011                	j	236 <gets+0x56>
 234:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 236:	99de                	add	s3,s3,s7
 238:	00098023          	sb	zero,0(s3)
  return buf;
}
 23c:	855e                	mv	a0,s7
 23e:	60e6                	ld	ra,88(sp)
 240:	6446                	ld	s0,80(sp)
 242:	64a6                	ld	s1,72(sp)
 244:	6906                	ld	s2,64(sp)
 246:	79e2                	ld	s3,56(sp)
 248:	7a42                	ld	s4,48(sp)
 24a:	7aa2                	ld	s5,40(sp)
 24c:	7b02                	ld	s6,32(sp)
 24e:	6be2                	ld	s7,24(sp)
 250:	6125                	addi	sp,sp,96
 252:	8082                	ret

0000000000000254 <stat>:

int
stat(const char *n, struct stat *st)
{
 254:	1101                	addi	sp,sp,-32
 256:	ec06                	sd	ra,24(sp)
 258:	e822                	sd	s0,16(sp)
 25a:	e426                	sd	s1,8(sp)
 25c:	e04a                	sd	s2,0(sp)
 25e:	1000                	addi	s0,sp,32
 260:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 262:	4581                	li	a1,0
 264:	00000097          	auipc	ra,0x0
 268:	176080e7          	jalr	374(ra) # 3da <open>
  if(fd < 0)
 26c:	02054563          	bltz	a0,296 <stat+0x42>
 270:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 272:	85ca                	mv	a1,s2
 274:	00000097          	auipc	ra,0x0
 278:	17e080e7          	jalr	382(ra) # 3f2 <fstat>
 27c:	892a                	mv	s2,a0
  close(fd);
 27e:	8526                	mv	a0,s1
 280:	00000097          	auipc	ra,0x0
 284:	142080e7          	jalr	322(ra) # 3c2 <close>
  return r;
}
 288:	854a                	mv	a0,s2
 28a:	60e2                	ld	ra,24(sp)
 28c:	6442                	ld	s0,16(sp)
 28e:	64a2                	ld	s1,8(sp)
 290:	6902                	ld	s2,0(sp)
 292:	6105                	addi	sp,sp,32
 294:	8082                	ret
    return -1;
 296:	597d                	li	s2,-1
 298:	bfc5                	j	288 <stat+0x34>

000000000000029a <atoi>:

int
atoi(const char *s)
{
 29a:	1141                	addi	sp,sp,-16
 29c:	e422                	sd	s0,8(sp)
 29e:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 2a0:	00054603          	lbu	a2,0(a0)
 2a4:	fd06079b          	addiw	a5,a2,-48
 2a8:	0ff7f793          	andi	a5,a5,255
 2ac:	4725                	li	a4,9
 2ae:	02f76963          	bltu	a4,a5,2e0 <atoi+0x46>
 2b2:	86aa                	mv	a3,a0
  n = 0;
 2b4:	4501                	li	a0,0
  while('0' <= *s && *s <= '9')
 2b6:	45a5                	li	a1,9
    n = n*10 + *s++ - '0';
 2b8:	0685                	addi	a3,a3,1
 2ba:	0025179b          	slliw	a5,a0,0x2
 2be:	9fa9                	addw	a5,a5,a0
 2c0:	0017979b          	slliw	a5,a5,0x1
 2c4:	9fb1                	addw	a5,a5,a2
 2c6:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 2ca:	0006c603          	lbu	a2,0(a3)
 2ce:	fd06071b          	addiw	a4,a2,-48
 2d2:	0ff77713          	andi	a4,a4,255
 2d6:	fee5f1e3          	bgeu	a1,a4,2b8 <atoi+0x1e>
  return n;
}
 2da:	6422                	ld	s0,8(sp)
 2dc:	0141                	addi	sp,sp,16
 2de:	8082                	ret
  n = 0;
 2e0:	4501                	li	a0,0
 2e2:	bfe5                	j	2da <atoi+0x40>

00000000000002e4 <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 2e4:	1141                	addi	sp,sp,-16
 2e6:	e422                	sd	s0,8(sp)
 2e8:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
 2ea:	02b57663          	bgeu	a0,a1,316 <memmove+0x32>
    while(n-- > 0)
 2ee:	02c05163          	blez	a2,310 <memmove+0x2c>
 2f2:	fff6079b          	addiw	a5,a2,-1
 2f6:	1782                	slli	a5,a5,0x20
 2f8:	9381                	srli	a5,a5,0x20
 2fa:	0785                	addi	a5,a5,1
 2fc:	97aa                	add	a5,a5,a0
  dst = vdst;
 2fe:	872a                	mv	a4,a0
      *dst++ = *src++;
 300:	0585                	addi	a1,a1,1
 302:	0705                	addi	a4,a4,1
 304:	fff5c683          	lbu	a3,-1(a1)
 308:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
 30c:	fee79ae3          	bne	a5,a4,300 <memmove+0x1c>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
 310:	6422                	ld	s0,8(sp)
 312:	0141                	addi	sp,sp,16
 314:	8082                	ret
    dst += n;
 316:	00c50733          	add	a4,a0,a2
    src += n;
 31a:	95b2                	add	a1,a1,a2
    while(n-- > 0)
 31c:	fec05ae3          	blez	a2,310 <memmove+0x2c>
 320:	fff6079b          	addiw	a5,a2,-1
 324:	1782                	slli	a5,a5,0x20
 326:	9381                	srli	a5,a5,0x20
 328:	fff7c793          	not	a5,a5
 32c:	97ba                	add	a5,a5,a4
      *--dst = *--src;
 32e:	15fd                	addi	a1,a1,-1
 330:	177d                	addi	a4,a4,-1
 332:	0005c683          	lbu	a3,0(a1)
 336:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
 33a:	fee79ae3          	bne	a5,a4,32e <memmove+0x4a>
 33e:	bfc9                	j	310 <memmove+0x2c>

0000000000000340 <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
 340:	1141                	addi	sp,sp,-16
 342:	e422                	sd	s0,8(sp)
 344:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
 346:	ca05                	beqz	a2,376 <memcmp+0x36>
 348:	fff6069b          	addiw	a3,a2,-1
 34c:	1682                	slli	a3,a3,0x20
 34e:	9281                	srli	a3,a3,0x20
 350:	0685                	addi	a3,a3,1
 352:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
 354:	00054783          	lbu	a5,0(a0)
 358:	0005c703          	lbu	a4,0(a1)
 35c:	00e79863          	bne	a5,a4,36c <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
 360:	0505                	addi	a0,a0,1
    p2++;
 362:	0585                	addi	a1,a1,1
  while (n-- > 0) {
 364:	fed518e3          	bne	a0,a3,354 <memcmp+0x14>
  }
  return 0;
 368:	4501                	li	a0,0
 36a:	a019                	j	370 <memcmp+0x30>
      return *p1 - *p2;
 36c:	40e7853b          	subw	a0,a5,a4
}
 370:	6422                	ld	s0,8(sp)
 372:	0141                	addi	sp,sp,16
 374:	8082                	ret
  return 0;
 376:	4501                	li	a0,0
 378:	bfe5                	j	370 <memcmp+0x30>

000000000000037a <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
 37a:	1141                	addi	sp,sp,-16
 37c:	e406                	sd	ra,8(sp)
 37e:	e022                	sd	s0,0(sp)
 380:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
 382:	00000097          	auipc	ra,0x0
 386:	f62080e7          	jalr	-158(ra) # 2e4 <memmove>
}
 38a:	60a2                	ld	ra,8(sp)
 38c:	6402                	ld	s0,0(sp)
 38e:	0141                	addi	sp,sp,16
 390:	8082                	ret

0000000000000392 <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 392:	4885                	li	a7,1
 ecall
 394:	00000073          	ecall
 ret
 398:	8082                	ret

000000000000039a <exit>:
.global exit
exit:
 li a7, SYS_exit
 39a:	4889                	li	a7,2
 ecall
 39c:	00000073          	ecall
 ret
 3a0:	8082                	ret

00000000000003a2 <wait>:
.global wait
wait:
 li a7, SYS_wait
 3a2:	488d                	li	a7,3
 ecall
 3a4:	00000073          	ecall
 ret
 3a8:	8082                	ret

00000000000003aa <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 3aa:	4891                	li	a7,4
 ecall
 3ac:	00000073          	ecall
 ret
 3b0:	8082                	ret

00000000000003b2 <read>:
.global read
read:
 li a7, SYS_read
 3b2:	4895                	li	a7,5
 ecall
 3b4:	00000073          	ecall
 ret
 3b8:	8082                	ret

00000000000003ba <write>:
.global write
write:
 li a7, SYS_write
 3ba:	48c1                	li	a7,16
 ecall
 3bc:	00000073          	ecall
 ret
 3c0:	8082                	ret

00000000000003c2 <close>:
.global close
close:
 li a7, SYS_close
 3c2:	48d5                	li	a7,21
 ecall
 3c4:	00000073          	ecall
 ret
 3c8:	8082                	ret

00000000000003ca <kill>:
.global kill
kill:
 li a7, SYS_kill
 3ca:	4899                	li	a7,6
 ecall
 3cc:	00000073          	ecall
 ret
 3d0:	8082                	ret

00000000000003d2 <exec>:
.global exec
exec:
 li a7, SYS_exec
 3d2:	489d                	li	a7,7
 ecall
 3d4:	00000073          	ecall
 ret
 3d8:	8082                	ret

00000000000003da <open>:
.global open
open:
 li a7, SYS_open
 3da:	48bd                	li	a7,15
 ecall
 3dc:	00000073          	ecall
 ret
 3e0:	8082                	ret

00000000000003e2 <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 3e2:	48c5                	li	a7,17
 ecall
 3e4:	00000073          	ecall
 ret
 3e8:	8082                	ret

00000000000003ea <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 3ea:	48c9                	li	a7,18
 ecall
 3ec:	00000073          	ecall
 ret
 3f0:	8082                	ret

00000000000003f2 <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 3f2:	48a1                	li	a7,8
 ecall
 3f4:	00000073          	ecall
 ret
 3f8:	8082                	ret

00000000000003fa <link>:
.global link
link:
 li a7, SYS_link
 3fa:	48cd                	li	a7,19
 ecall
 3fc:	00000073          	ecall
 ret
 400:	8082                	ret

0000000000000402 <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 402:	48d1                	li	a7,20
 ecall
 404:	00000073          	ecall
 ret
 408:	8082                	ret

000000000000040a <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 40a:	48a5                	li	a7,9
 ecall
 40c:	00000073          	ecall
 ret
 410:	8082                	ret

0000000000000412 <dup>:
.global dup
dup:
 li a7, SYS_dup
 412:	48a9                	li	a7,10
 ecall
 414:	00000073          	ecall
 ret
 418:	8082                	ret

000000000000041a <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 41a:	48ad                	li	a7,11
 ecall
 41c:	00000073          	ecall
 ret
 420:	8082                	ret

0000000000000422 <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
 422:	48b1                	li	a7,12
 ecall
 424:	00000073          	ecall
 ret
 428:	8082                	ret

000000000000042a <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
 42a:	48b5                	li	a7,13
 ecall
 42c:	00000073          	ecall
 ret
 430:	8082                	ret

0000000000000432 <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 432:	48b9                	li	a7,14
 ecall
 434:	00000073          	ecall
 ret
 438:	8082                	ret

000000000000043a <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 43a:	1101                	addi	sp,sp,-32
 43c:	ec06                	sd	ra,24(sp)
 43e:	e822                	sd	s0,16(sp)
 440:	1000                	addi	s0,sp,32
 442:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 446:	4605                	li	a2,1
 448:	fef40593          	addi	a1,s0,-17
 44c:	00000097          	auipc	ra,0x0
 450:	f6e080e7          	jalr	-146(ra) # 3ba <write>
}
 454:	60e2                	ld	ra,24(sp)
 456:	6442                	ld	s0,16(sp)
 458:	6105                	addi	sp,sp,32
 45a:	8082                	ret

000000000000045c <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 45c:	7139                	addi	sp,sp,-64
 45e:	fc06                	sd	ra,56(sp)
 460:	f822                	sd	s0,48(sp)
 462:	f426                	sd	s1,40(sp)
 464:	f04a                	sd	s2,32(sp)
 466:	ec4e                	sd	s3,24(sp)
 468:	0080                	addi	s0,sp,64
 46a:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 46c:	c299                	beqz	a3,472 <printint+0x16>
 46e:	0805c863          	bltz	a1,4fe <printint+0xa2>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
 472:	2581                	sext.w	a1,a1
  neg = 0;
 474:	4881                	li	a7,0
 476:	fc040693          	addi	a3,s0,-64
  }

  i = 0;
 47a:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
 47c:	2601                	sext.w	a2,a2
 47e:	00000517          	auipc	a0,0x0
 482:	48a50513          	addi	a0,a0,1162 # 908 <digits>
 486:	883a                	mv	a6,a4
 488:	2705                	addiw	a4,a4,1
 48a:	02c5f7bb          	remuw	a5,a1,a2
 48e:	1782                	slli	a5,a5,0x20
 490:	9381                	srli	a5,a5,0x20
 492:	97aa                	add	a5,a5,a0
 494:	0007c783          	lbu	a5,0(a5)
 498:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
 49c:	0005879b          	sext.w	a5,a1
 4a0:	02c5d5bb          	divuw	a1,a1,a2
 4a4:	0685                	addi	a3,a3,1
 4a6:	fec7f0e3          	bgeu	a5,a2,486 <printint+0x2a>
  if(neg)
 4aa:	00088b63          	beqz	a7,4c0 <printint+0x64>
    buf[i++] = '-';
 4ae:	fd040793          	addi	a5,s0,-48
 4b2:	973e                	add	a4,a4,a5
 4b4:	02d00793          	li	a5,45
 4b8:	fef70823          	sb	a5,-16(a4)
 4bc:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
 4c0:	02e05863          	blez	a4,4f0 <printint+0x94>
 4c4:	fc040793          	addi	a5,s0,-64
 4c8:	00e78933          	add	s2,a5,a4
 4cc:	fff78993          	addi	s3,a5,-1
 4d0:	99ba                	add	s3,s3,a4
 4d2:	377d                	addiw	a4,a4,-1
 4d4:	1702                	slli	a4,a4,0x20
 4d6:	9301                	srli	a4,a4,0x20
 4d8:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
 4dc:	fff94583          	lbu	a1,-1(s2)
 4e0:	8526                	mv	a0,s1
 4e2:	00000097          	auipc	ra,0x0
 4e6:	f58080e7          	jalr	-168(ra) # 43a <putc>
  while(--i >= 0)
 4ea:	197d                	addi	s2,s2,-1
 4ec:	ff3918e3          	bne	s2,s3,4dc <printint+0x80>
}
 4f0:	70e2                	ld	ra,56(sp)
 4f2:	7442                	ld	s0,48(sp)
 4f4:	74a2                	ld	s1,40(sp)
 4f6:	7902                	ld	s2,32(sp)
 4f8:	69e2                	ld	s3,24(sp)
 4fa:	6121                	addi	sp,sp,64
 4fc:	8082                	ret
    x = -xx;
 4fe:	40b005bb          	negw	a1,a1
    neg = 1;
 502:	4885                	li	a7,1
    x = -xx;
 504:	bf8d                	j	476 <printint+0x1a>

0000000000000506 <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 506:	7119                	addi	sp,sp,-128
 508:	fc86                	sd	ra,120(sp)
 50a:	f8a2                	sd	s0,112(sp)
 50c:	f4a6                	sd	s1,104(sp)
 50e:	f0ca                	sd	s2,96(sp)
 510:	ecce                	sd	s3,88(sp)
 512:	e8d2                	sd	s4,80(sp)
 514:	e4d6                	sd	s5,72(sp)
 516:	e0da                	sd	s6,64(sp)
 518:	fc5e                	sd	s7,56(sp)
 51a:	f862                	sd	s8,48(sp)
 51c:	f466                	sd	s9,40(sp)
 51e:	f06a                	sd	s10,32(sp)
 520:	ec6e                	sd	s11,24(sp)
 522:	0100                	addi	s0,sp,128
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 524:	0005c903          	lbu	s2,0(a1)
 528:	18090f63          	beqz	s2,6c6 <vprintf+0x1c0>
 52c:	8aaa                	mv	s5,a0
 52e:	8b32                	mv	s6,a2
 530:	00158493          	addi	s1,a1,1
  state = 0;
 534:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
 536:	02500a13          	li	s4,37
      if(c == 'd'){
 53a:	06400c13          	li	s8,100
        printint(fd, va_arg(ap, int), 10, 1);
      } else if(c == 'l') {
 53e:	06c00c93          	li	s9,108
        printint(fd, va_arg(ap, uint64), 10, 0);
      } else if(c == 'x') {
 542:	07800d13          	li	s10,120
        printint(fd, va_arg(ap, int), 16, 0);
      } else if(c == 'p') {
 546:	07000d93          	li	s11,112
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 54a:	00000b97          	auipc	s7,0x0
 54e:	3beb8b93          	addi	s7,s7,958 # 908 <digits>
 552:	a839                	j	570 <vprintf+0x6a>
        putc(fd, c);
 554:	85ca                	mv	a1,s2
 556:	8556                	mv	a0,s5
 558:	00000097          	auipc	ra,0x0
 55c:	ee2080e7          	jalr	-286(ra) # 43a <putc>
 560:	a019                	j	566 <vprintf+0x60>
    } else if(state == '%'){
 562:	01498f63          	beq	s3,s4,580 <vprintf+0x7a>
  for(i = 0; fmt[i]; i++){
 566:	0485                	addi	s1,s1,1
 568:	fff4c903          	lbu	s2,-1(s1)
 56c:	14090d63          	beqz	s2,6c6 <vprintf+0x1c0>
    c = fmt[i] & 0xff;
 570:	0009079b          	sext.w	a5,s2
    if(state == 0){
 574:	fe0997e3          	bnez	s3,562 <vprintf+0x5c>
      if(c == '%'){
 578:	fd479ee3          	bne	a5,s4,554 <vprintf+0x4e>
        state = '%';
 57c:	89be                	mv	s3,a5
 57e:	b7e5                	j	566 <vprintf+0x60>
      if(c == 'd'){
 580:	05878063          	beq	a5,s8,5c0 <vprintf+0xba>
      } else if(c == 'l') {
 584:	05978c63          	beq	a5,s9,5dc <vprintf+0xd6>
      } else if(c == 'x') {
 588:	07a78863          	beq	a5,s10,5f8 <vprintf+0xf2>
      } else if(c == 'p') {
 58c:	09b78463          	beq	a5,s11,614 <vprintf+0x10e>
        printptr(fd, va_arg(ap, uint64));
      } else if(c == 's'){
 590:	07300713          	li	a4,115
 594:	0ce78663          	beq	a5,a4,660 <vprintf+0x15a>
          s = "(null)";
        while(*s != 0){
          putc(fd, *s);
          s++;
        }
      } else if(c == 'c'){
 598:	06300713          	li	a4,99
 59c:	0ee78e63          	beq	a5,a4,698 <vprintf+0x192>
        putc(fd, va_arg(ap, uint));
      } else if(c == '%'){
 5a0:	11478863          	beq	a5,s4,6b0 <vprintf+0x1aa>
        putc(fd, c);
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
 5a4:	85d2                	mv	a1,s4
 5a6:	8556                	mv	a0,s5
 5a8:	00000097          	auipc	ra,0x0
 5ac:	e92080e7          	jalr	-366(ra) # 43a <putc>
        putc(fd, c);
 5b0:	85ca                	mv	a1,s2
 5b2:	8556                	mv	a0,s5
 5b4:	00000097          	auipc	ra,0x0
 5b8:	e86080e7          	jalr	-378(ra) # 43a <putc>
      }
      state = 0;
 5bc:	4981                	li	s3,0
 5be:	b765                	j	566 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 10, 1);
 5c0:	008b0913          	addi	s2,s6,8
 5c4:	4685                	li	a3,1
 5c6:	4629                	li	a2,10
 5c8:	000b2583          	lw	a1,0(s6)
 5cc:	8556                	mv	a0,s5
 5ce:	00000097          	auipc	ra,0x0
 5d2:	e8e080e7          	jalr	-370(ra) # 45c <printint>
 5d6:	8b4a                	mv	s6,s2
      state = 0;
 5d8:	4981                	li	s3,0
 5da:	b771                	j	566 <vprintf+0x60>
        printint(fd, va_arg(ap, uint64), 10, 0);
 5dc:	008b0913          	addi	s2,s6,8
 5e0:	4681                	li	a3,0
 5e2:	4629                	li	a2,10
 5e4:	000b2583          	lw	a1,0(s6)
 5e8:	8556                	mv	a0,s5
 5ea:	00000097          	auipc	ra,0x0
 5ee:	e72080e7          	jalr	-398(ra) # 45c <printint>
 5f2:	8b4a                	mv	s6,s2
      state = 0;
 5f4:	4981                	li	s3,0
 5f6:	bf85                	j	566 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 16, 0);
 5f8:	008b0913          	addi	s2,s6,8
 5fc:	4681                	li	a3,0
 5fe:	4641                	li	a2,16
 600:	000b2583          	lw	a1,0(s6)
 604:	8556                	mv	a0,s5
 606:	00000097          	auipc	ra,0x0
 60a:	e56080e7          	jalr	-426(ra) # 45c <printint>
 60e:	8b4a                	mv	s6,s2
      state = 0;
 610:	4981                	li	s3,0
 612:	bf91                	j	566 <vprintf+0x60>
        printptr(fd, va_arg(ap, uint64));
 614:	008b0793          	addi	a5,s6,8
 618:	f8f43423          	sd	a5,-120(s0)
 61c:	000b3983          	ld	s3,0(s6)
  putc(fd, '0');
 620:	03000593          	li	a1,48
 624:	8556                	mv	a0,s5
 626:	00000097          	auipc	ra,0x0
 62a:	e14080e7          	jalr	-492(ra) # 43a <putc>
  putc(fd, 'x');
 62e:	85ea                	mv	a1,s10
 630:	8556                	mv	a0,s5
 632:	00000097          	auipc	ra,0x0
 636:	e08080e7          	jalr	-504(ra) # 43a <putc>
 63a:	4941                	li	s2,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 63c:	03c9d793          	srli	a5,s3,0x3c
 640:	97de                	add	a5,a5,s7
 642:	0007c583          	lbu	a1,0(a5)
 646:	8556                	mv	a0,s5
 648:	00000097          	auipc	ra,0x0
 64c:	df2080e7          	jalr	-526(ra) # 43a <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 650:	0992                	slli	s3,s3,0x4
 652:	397d                	addiw	s2,s2,-1
 654:	fe0914e3          	bnez	s2,63c <vprintf+0x136>
        printptr(fd, va_arg(ap, uint64));
 658:	f8843b03          	ld	s6,-120(s0)
      state = 0;
 65c:	4981                	li	s3,0
 65e:	b721                	j	566 <vprintf+0x60>
        s = va_arg(ap, char*);
 660:	008b0993          	addi	s3,s6,8
 664:	000b3903          	ld	s2,0(s6)
        if(s == 0)
 668:	02090163          	beqz	s2,68a <vprintf+0x184>
        while(*s != 0){
 66c:	00094583          	lbu	a1,0(s2)
 670:	c9a1                	beqz	a1,6c0 <vprintf+0x1ba>
          putc(fd, *s);
 672:	8556                	mv	a0,s5
 674:	00000097          	auipc	ra,0x0
 678:	dc6080e7          	jalr	-570(ra) # 43a <putc>
          s++;
 67c:	0905                	addi	s2,s2,1
        while(*s != 0){
 67e:	00094583          	lbu	a1,0(s2)
 682:	f9e5                	bnez	a1,672 <vprintf+0x16c>
        s = va_arg(ap, char*);
 684:	8b4e                	mv	s6,s3
      state = 0;
 686:	4981                	li	s3,0
 688:	bdf9                	j	566 <vprintf+0x60>
          s = "(null)";
 68a:	00000917          	auipc	s2,0x0
 68e:	27690913          	addi	s2,s2,630 # 900 <malloc+0x130>
        while(*s != 0){
 692:	02800593          	li	a1,40
 696:	bff1                	j	672 <vprintf+0x16c>
        putc(fd, va_arg(ap, uint));
 698:	008b0913          	addi	s2,s6,8
 69c:	000b4583          	lbu	a1,0(s6)
 6a0:	8556                	mv	a0,s5
 6a2:	00000097          	auipc	ra,0x0
 6a6:	d98080e7          	jalr	-616(ra) # 43a <putc>
 6aa:	8b4a                	mv	s6,s2
      state = 0;
 6ac:	4981                	li	s3,0
 6ae:	bd65                	j	566 <vprintf+0x60>
        putc(fd, c);
 6b0:	85d2                	mv	a1,s4
 6b2:	8556                	mv	a0,s5
 6b4:	00000097          	auipc	ra,0x0
 6b8:	d86080e7          	jalr	-634(ra) # 43a <putc>
      state = 0;
 6bc:	4981                	li	s3,0
 6be:	b565                	j	566 <vprintf+0x60>
        s = va_arg(ap, char*);
 6c0:	8b4e                	mv	s6,s3
      state = 0;
 6c2:	4981                	li	s3,0
 6c4:	b54d                	j	566 <vprintf+0x60>
    }
  }
}
 6c6:	70e6                	ld	ra,120(sp)
 6c8:	7446                	ld	s0,112(sp)
 6ca:	74a6                	ld	s1,104(sp)
 6cc:	7906                	ld	s2,96(sp)
 6ce:	69e6                	ld	s3,88(sp)
 6d0:	6a46                	ld	s4,80(sp)
 6d2:	6aa6                	ld	s5,72(sp)
 6d4:	6b06                	ld	s6,64(sp)
 6d6:	7be2                	ld	s7,56(sp)
 6d8:	7c42                	ld	s8,48(sp)
 6da:	7ca2                	ld	s9,40(sp)
 6dc:	7d02                	ld	s10,32(sp)
 6de:	6de2                	ld	s11,24(sp)
 6e0:	6109                	addi	sp,sp,128
 6e2:	8082                	ret

00000000000006e4 <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 6e4:	715d                	addi	sp,sp,-80
 6e6:	ec06                	sd	ra,24(sp)
 6e8:	e822                	sd	s0,16(sp)
 6ea:	1000                	addi	s0,sp,32
 6ec:	e010                	sd	a2,0(s0)
 6ee:	e414                	sd	a3,8(s0)
 6f0:	e818                	sd	a4,16(s0)
 6f2:	ec1c                	sd	a5,24(s0)
 6f4:	03043023          	sd	a6,32(s0)
 6f8:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 6fc:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 700:	8622                	mv	a2,s0
 702:	00000097          	auipc	ra,0x0
 706:	e04080e7          	jalr	-508(ra) # 506 <vprintf>
}
 70a:	60e2                	ld	ra,24(sp)
 70c:	6442                	ld	s0,16(sp)
 70e:	6161                	addi	sp,sp,80
 710:	8082                	ret

0000000000000712 <printf>:

void
printf(const char *fmt, ...)
{
 712:	711d                	addi	sp,sp,-96
 714:	ec06                	sd	ra,24(sp)
 716:	e822                	sd	s0,16(sp)
 718:	1000                	addi	s0,sp,32
 71a:	e40c                	sd	a1,8(s0)
 71c:	e810                	sd	a2,16(s0)
 71e:	ec14                	sd	a3,24(s0)
 720:	f018                	sd	a4,32(s0)
 722:	f41c                	sd	a5,40(s0)
 724:	03043823          	sd	a6,48(s0)
 728:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 72c:	00840613          	addi	a2,s0,8
 730:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 734:	85aa                	mv	a1,a0
 736:	4505                	li	a0,1
 738:	00000097          	auipc	ra,0x0
 73c:	dce080e7          	jalr	-562(ra) # 506 <vprintf>
}
 740:	60e2                	ld	ra,24(sp)
 742:	6442                	ld	s0,16(sp)
 744:	6125                	addi	sp,sp,96
 746:	8082                	ret

0000000000000748 <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 748:	1141                	addi	sp,sp,-16
 74a:	e422                	sd	s0,8(sp)
 74c:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 74e:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 752:	00000797          	auipc	a5,0x0
 756:	1ce7b783          	ld	a5,462(a5) # 920 <freep>
 75a:	a805                	j	78a <free+0x42>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 75c:	4618                	lw	a4,8(a2)
 75e:	9db9                	addw	a1,a1,a4
 760:	feb52c23          	sw	a1,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 764:	6398                	ld	a4,0(a5)
 766:	6318                	ld	a4,0(a4)
 768:	fee53823          	sd	a4,-16(a0)
 76c:	a091                	j	7b0 <free+0x68>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 76e:	ff852703          	lw	a4,-8(a0)
 772:	9e39                	addw	a2,a2,a4
 774:	c790                	sw	a2,8(a5)
    p->s.ptr = bp->s.ptr;
 776:	ff053703          	ld	a4,-16(a0)
 77a:	e398                	sd	a4,0(a5)
 77c:	a099                	j	7c2 <free+0x7a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 77e:	6398                	ld	a4,0(a5)
 780:	00e7e463          	bltu	a5,a4,788 <free+0x40>
 784:	00e6ea63          	bltu	a3,a4,798 <free+0x50>
{
 788:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 78a:	fed7fae3          	bgeu	a5,a3,77e <free+0x36>
 78e:	6398                	ld	a4,0(a5)
 790:	00e6e463          	bltu	a3,a4,798 <free+0x50>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 794:	fee7eae3          	bltu	a5,a4,788 <free+0x40>
  if(bp + bp->s.size == p->s.ptr){
 798:	ff852583          	lw	a1,-8(a0)
 79c:	6390                	ld	a2,0(a5)
 79e:	02059713          	slli	a4,a1,0x20
 7a2:	9301                	srli	a4,a4,0x20
 7a4:	0712                	slli	a4,a4,0x4
 7a6:	9736                	add	a4,a4,a3
 7a8:	fae60ae3          	beq	a2,a4,75c <free+0x14>
    bp->s.ptr = p->s.ptr;
 7ac:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 7b0:	4790                	lw	a2,8(a5)
 7b2:	02061713          	slli	a4,a2,0x20
 7b6:	9301                	srli	a4,a4,0x20
 7b8:	0712                	slli	a4,a4,0x4
 7ba:	973e                	add	a4,a4,a5
 7bc:	fae689e3          	beq	a3,a4,76e <free+0x26>
  } else
    p->s.ptr = bp;
 7c0:	e394                	sd	a3,0(a5)
  freep = p;
 7c2:	00000717          	auipc	a4,0x0
 7c6:	14f73f23          	sd	a5,350(a4) # 920 <freep>
}
 7ca:	6422                	ld	s0,8(sp)
 7cc:	0141                	addi	sp,sp,16
 7ce:	8082                	ret

00000000000007d0 <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 7d0:	7139                	addi	sp,sp,-64
 7d2:	fc06                	sd	ra,56(sp)
 7d4:	f822                	sd	s0,48(sp)
 7d6:	f426                	sd	s1,40(sp)
 7d8:	f04a                	sd	s2,32(sp)
 7da:	ec4e                	sd	s3,24(sp)
 7dc:	e852                	sd	s4,16(sp)
 7de:	e456                	sd	s5,8(sp)
 7e0:	e05a                	sd	s6,0(sp)
 7e2:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 7e4:	02051493          	slli	s1,a0,0x20
 7e8:	9081                	srli	s1,s1,0x20
 7ea:	04bd                	addi	s1,s1,15
 7ec:	8091                	srli	s1,s1,0x4
 7ee:	0014899b          	addiw	s3,s1,1
 7f2:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
 7f4:	00000517          	auipc	a0,0x0
 7f8:	12c53503          	ld	a0,300(a0) # 920 <freep>
 7fc:	c515                	beqz	a0,828 <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 7fe:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 800:	4798                	lw	a4,8(a5)
 802:	02977f63          	bgeu	a4,s1,840 <malloc+0x70>
 806:	8a4e                	mv	s4,s3
 808:	0009871b          	sext.w	a4,s3
 80c:	6685                	lui	a3,0x1
 80e:	00d77363          	bgeu	a4,a3,814 <malloc+0x44>
 812:	6a05                	lui	s4,0x1
 814:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 818:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 81c:	00000917          	auipc	s2,0x0
 820:	10490913          	addi	s2,s2,260 # 920 <freep>
  if(p == (char*)-1)
 824:	5afd                	li	s5,-1
 826:	a88d                	j	898 <malloc+0xc8>
    base.s.ptr = freep = prevp = &base;
 828:	00000797          	auipc	a5,0x0
 82c:	30078793          	addi	a5,a5,768 # b28 <base>
 830:	00000717          	auipc	a4,0x0
 834:	0ef73823          	sd	a5,240(a4) # 920 <freep>
 838:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 83a:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 83e:	b7e1                	j	806 <malloc+0x36>
      if(p->s.size == nunits)
 840:	02e48b63          	beq	s1,a4,876 <malloc+0xa6>
        p->s.size -= nunits;
 844:	4137073b          	subw	a4,a4,s3
 848:	c798                	sw	a4,8(a5)
        p += p->s.size;
 84a:	1702                	slli	a4,a4,0x20
 84c:	9301                	srli	a4,a4,0x20
 84e:	0712                	slli	a4,a4,0x4
 850:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 852:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 856:	00000717          	auipc	a4,0x0
 85a:	0ca73523          	sd	a0,202(a4) # 920 <freep>
      return (void*)(p + 1);
 85e:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 862:	70e2                	ld	ra,56(sp)
 864:	7442                	ld	s0,48(sp)
 866:	74a2                	ld	s1,40(sp)
 868:	7902                	ld	s2,32(sp)
 86a:	69e2                	ld	s3,24(sp)
 86c:	6a42                	ld	s4,16(sp)
 86e:	6aa2                	ld	s5,8(sp)
 870:	6b02                	ld	s6,0(sp)
 872:	6121                	addi	sp,sp,64
 874:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 876:	6398                	ld	a4,0(a5)
 878:	e118                	sd	a4,0(a0)
 87a:	bff1                	j	856 <malloc+0x86>
  hp->s.size = nu;
 87c:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 880:	0541                	addi	a0,a0,16
 882:	00000097          	auipc	ra,0x0
 886:	ec6080e7          	jalr	-314(ra) # 748 <free>
  return freep;
 88a:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 88e:	d971                	beqz	a0,862 <malloc+0x92>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 890:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 892:	4798                	lw	a4,8(a5)
 894:	fa9776e3          	bgeu	a4,s1,840 <malloc+0x70>
    if(p == freep)
 898:	00093703          	ld	a4,0(s2)
 89c:	853e                	mv	a0,a5
 89e:	fef719e3          	bne	a4,a5,890 <malloc+0xc0>
  p = sbrk(nu * sizeof(Header));
 8a2:	8552                	mv	a0,s4
 8a4:	00000097          	auipc	ra,0x0
 8a8:	b7e080e7          	jalr	-1154(ra) # 422 <sbrk>
  if(p == (char*)-1)
 8ac:	fd5518e3          	bne	a0,s5,87c <malloc+0xac>
        return 0;
 8b0:	4501                	li	a0,0
 8b2:	bf45                	j	862 <malloc+0x92>
