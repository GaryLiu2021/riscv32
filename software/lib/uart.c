#include <uart.h>

int print(char* c, int len) {
    int i, j;
    for (i = 0;i < len;i += 4) {
        /*
         * Polling the UART_TX_REG until the tx buffer is not full
         */
        while (1) {
            int tx_buffer_ready = *(__UINT32_TYPE__*)UART_TX_REG;
            if (tx_buffer_ready)
                break;
        }

        /*
         * Pack the chars by 4, if the length is not multiple of 4, complement by 0
         */
        __UINT32_TYPE__ tx_str = 0;
        for (j = 0;(i + j) < len && j < 4;j++) {
            tx_str = tx_str << 8 | *(c + i + j);
        }
        for (;j < 4;j++) {
            tx_str = tx_str << 8 | (__UINT32_TYPE__)(0);
        }

        /*
         * Tx 4 bytes to UART_TX_BUF
         */
        *(__UINT32_TYPE__*)(UART_TX_BUF) = tx_str;
    }
    return 0;
}

int scanf(char* rx_array, int max_len) {
    int i, j;
    int length = 0;
    for (i = 0;i < max_len;i += 4) {
        /*
         * Polling the UART_RX_REG until the rx buffer is not empty
         */
        while (1) {
            int rx_buffer_ready = *(__UINT32_TYPE__*)UART_RX_REG;
            if (rx_buffer_ready)
                break;
        }

        /*
         * Load 4 bytes from UART_RX_BUF
         */
        __UINT32_TYPE__ rx_str = *(__UINT32_TYPE__*)UART_RX_BUF;

        /*
         * Store the rx_str to rx_array one(char) by one,
         * if recved a '\0', finish the scanf process.
         */
        for (j = 0;(i + j) < max_len && j < 4;j++) {
            char rxchar = *(char*)(&rx_str);
            if (rxchar == '\0')
                return length;
            *(rx_array + i + j) = rxchar;
            rx_str <<= 8;
            length++;
        }
    }
    return length;
}

// int _read(int fd, char* ptr, int len) {
//     int count = len / 4;
//     int remain = len - count * 4;
//     int i = 0;
//     for (int it = 0; it < count; it++) {
//         int data = *(int*)UART_DATA_ADDR;
//         char byte1 = (data >> 24) & 0xFF;
//         char byte2 = (data >> 16) & 0xFF;
//         char byte3 = (data >> 8) & 0xFF;
//         char byte4 = data & 0xFF;
//         ptr[i] = byte1;
//         ptr[i + 1] = byte2;
//         ptr[i + 2] = byte3;
//         ptr[i + 3] = byte4;
//         i += 4;
//     }
//     if (remain != 0) {
//         int data = *(int*)UART_DATA_ADDR;
//         int shift = 32;
//         for (int it = 0; it < remain; it++) {
//             shift -= 8;
//             ptr[i] = (data >> shift) & 0xFF;
//             i++;
//         }
//     }
//     ptr[i] = 0;
//     i++;
//     return i;
// }

// int _write(int fd, char* ptr, int len) {
//     int count = len / 4;
//     int remain = len - count * 4;
//     int i = 0;
//     for (int it = 0; it < count; it++) {
//         char byte1 = ptr[i];
//         char byte2 = ptr[i + 1];
//         char byte3 = ptr[i + 2];
//         char byte4 = ptr[i + 3];
//         int data = (byte1 << 24) | (byte2 << 16) | (byte3 << 8) | byte4;
//         *(int*)UART_DATA_ADDR = data;
//         i += 4;
//     }
//     if (remain != 0) {
//         char byte1 = ptr[i++];
//         char byte2 = i < len ? ptr[i++] : 0;
//         char byte3 = i < len ? ptr[i++] : 0;
//         char byte4 = 0;
//         int data = (byte1 << 24) | (byte2 << 16) | (byte3 << 8) | byte4;
//         *(int*)UART_DATA_ADDR = data;
//     }
//     return i;
// }