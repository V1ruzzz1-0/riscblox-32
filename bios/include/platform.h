#ifndef PLATFORM_H
#define PLATFORM_H

#define VRAM_BASE      0x80010000
#define SCREEN_WIDTH   600
#define SCREEN_HEIGHT  480

#define WRITE_PIXEL(x, y, color) \
    (*(volatile unsigned short*)((unsigned int)VRAM_BASE + (((y) * SCREEN_WIDTH + (x)) * 2)) = (color))

#endif
