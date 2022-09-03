#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"

int main(void){
	int p[2];
	int i = 0;
	char buf = 0x00;

	pipe(p);
	if(fork() == 0){
		close(p[1]);
		while(i < 10){
			read(p[0], &buf, 1);
			// buf++;
			write(p[0], &buf, 1);
			i++;
		}
		// printf("%x",buf);
		exit(0);
	}else{
		close(p[0]);
		while(i < 10){
			write(p[1], &buf, 1);
			read(p[1], &buf, 1);
			// buf++;
			i++;
		}
		// printf("%x",buf);
		exit(0);
	}

}
