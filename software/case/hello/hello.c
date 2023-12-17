#include <uart.h>
void copycmd();
void addcmd();

int main() {
	char* hello = " \
____  ___ ____   ______     ___________  ___ \n\
|  _ \\|_ _/ ___| / ___\\ \\   / /___ /___ \\|_ _|\n\
| |_) || |\\___ \\| |    \\ \\ / /  |_ \\ __) || | \n\
|  _ < | | ___) | |___  \\ V /  ___) / __/ | | \n\
|_| \\_\\___|____/ \\____|  \\_/  |____/_____|___|\n\n";
	char* welcome = "HELLO FROM RV32I!\n";
	char* terminal = "ljl@riscv32:term$ ";
	print(hello, 237);
	while (1) {
		print(terminal, 19);

		volatile char rxbuf[32];
		int rxnum = scanf(rxbuf, 32);

		char* inst_list[] = { \
			"hello", \
			"copy", \
			"add" };
		
		if (strcmp(rxbuf, inst_list[0], 6, 6) == 0) {
			print(welcome, 19);
		}
		else if (strcmp(rxbuf, inst_list[1], 5, 5) == 0) {
			copycmd();
		}
		else if (strcmp(rxbuf, inst_list[2], 4, 4) == 0) {
			addcmd();
		}
		else
			print("syntax error\n", 14);
	}
	return 0;
}

void copycmd() {
	while (1) {
		char* cmd = "ljl@riscv32:copy$ ";
		print(cmd, 19);
		char buf[32];
		int rxnum = scanf(buf, 32);
		if (strcmp(buf, "exit", 4, 4) == 0)
			return;
		print("Your command is:", 17);
		print(buf, rxnum);
		print("\n", 2);
	}
}

void addcmd() {
	char* cmd = "ljl@riscv32:add$ ";
	while (1) {
	new_cycle:
		print(cmd, 18);

		char rxbuf[32];
		int rxnum = scanf(rxbuf, 32);

		if (strcmp(rxbuf, "exit", 4, 4) == 0)
			return;
		int add1 = 0;
		int add2 = 0;
		int i = 0;
		while (rxbuf[i] == ' ')i++;
		while (rxbuf[i] != ' ') {
			if (rxbuf[i] >= 48 && rxbuf[i] <= 57) {
				add1 = add1 * 10 + (rxbuf[i] - 48);
			}
			else {
				print("syntax error\n", 14);
				goto new_cycle;
			}
			i++;
		}
		while (rxbuf[i] == ' ')i++;
		while (rxbuf[i] != ' ' && rxbuf[i] != '\0') {
			if (rxbuf[i] >= 48 && rxbuf[i] <= 57) {
				add2 = add2 * 10 + (rxbuf[i] - 48);
			}
			else {
				print("syntax error\n", 14);
				goto new_cycle;
			}
			i++;
		}
		int add_result = add1 + add2;
		volatile char add_out[32];
		int add_len = int_to_ascii(add_result, add_out);
		print("result = 0x", 12);
		print(add_out, add_len);
		print("\n", 2);
	}
}