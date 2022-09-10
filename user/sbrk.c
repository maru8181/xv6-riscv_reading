#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"

int main(void){

	sbrk(1);
	exit(0);

	return 0;
}
