#define UART_TX_REG 0x00000002
#define UART_TX_BUF 0x00000003
#define UART_RX_REG 0x00000004
#define UART_RX_BUF 0x00000006

int print(char* c, int len);
int scanf(char* rx_array, int max_len);
int strcmp(char* str1, char* str2, int len1, int len2);
int int_to_ascii(int number, char* buffer);