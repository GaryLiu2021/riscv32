#define UART_DATA_ADDR 0x00000000
#define UART_TX_REG 0x00000002
#define UART_TX_BUF 0x00000003
#define UART_RX_REG 0x00000004
#define UART_RX_BUF 0x00000006

int print(char* c, int len);
int scanf(char* rx_array, int max_len);