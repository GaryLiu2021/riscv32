#include <uart.h>

int main() {
	char hello[32] = { 'h','e','l','l','o','\n' };
	print(hello, 6);
	return 0;
}