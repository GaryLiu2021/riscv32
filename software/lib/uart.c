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
        // print("Rx buffer is ready...", 22);
        /*
         * Load 4 bytes from UART_RX_BUF
         */
        __UINT32_TYPE__ rx_str = *(__UINT32_TYPE__*)UART_RX_BUF;

        /*
         * Store the rx_str to rx_array one(char) by one,
         * if recved a '\0', finish the scanf process.
         */
        for (j = 0;(i + j) < max_len && j < 4;j++) {
            char rxchar = *((char*)(&rx_str) + 3 - j);
            *(rx_array + i + j) = rxchar;
            length++;
            if (rxchar == '\0')
                return length;
        }
    }
    return length;
}

int strcmp(char* str1, char* str2, int len1, int len2) {
    int i = 0;
    while (i < len1 || i < len2) {
        if (str1[i] != str2[i]) {
            return str1[i] - str2[i];
        }
        i++;
    }
    return 0;
}


int int_to_ascii(int number, char* buffer) {
    int i = 0;
    // int is_negative = 0;

    // if (number < 0) {
    //     is_negative = 1;
    //     number = -number;
    // }
    do {
        int hex_bit = number & 0xf;
        if (hex_bit <= 9) {
            buffer[i++] = '0' + hex_bit;
        }
        else {
            buffer[i++] = 'a' + hex_bit - 0xa;
        }
        number >>= 4;
    } while (number != 0);

    // // 若为负数，加上负号
    // if (is_negative) {
    //     buffer[i++] = '-';
    // }

    // reverse
    int start = 0;
    int end = i - 1;
    while (start < end) {
        char temp = buffer[start];
        buffer[start] = buffer[end];
        buffer[end] = temp;
        start++;
        end--;
    }
    buffer[i] = '\0';
    return i;
}