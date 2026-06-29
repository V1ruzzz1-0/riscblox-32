#include "../include/platform.h"

#define UART_ADDR 0x10000000

extern const unsigned char font8x8[95][8];

void clear_screen(unsigned short color) {
    for (int y = 0; y < SCREEN_HEIGHT; y++) {
        for (int x = 0; x < SCREEN_WIDTH; x++) {
            WRITE_PIXEL(x, y, color);
        }
    }
}

void print_char_screen(char c, int x, int y, unsigned short color) {
    const unsigned char *glyph = font8x8[c - 32];
    for (int i = 0; i < 8; i++) {
        for (int j = 0; j < 8; j++) {
            if (glyph[i] & (1 << (7 - j))) {
                WRITE_PIXEL(x + j, y + i, color);
            }
        }
    }
}

/* UART output */

void print_char_uart(char c) {
    *(volatile char*)UART_ADDR = c;
}

/* UART string output */

void print_str_uart(const char *s) {
    while (*s != '\0') {
        print_char_uart(*s);
        s++;
    }
}

void main() {
    clear_screen(0x001F);

    /* Screen output */

    print_char_screen('A', 10, 10, 0xFFFF);

    /* UART output */

    print_str_uart("RISCBLOX-32: SYSTEM_INITIALIZED\n");
    print_str_uart("STATUS: READY_FOR_KERNEL\n");

    while (1);
}
