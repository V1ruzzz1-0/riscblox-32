CC = riscv64-elf-gcc
OBJCOPY = riscv64-elf-objcopy

CFLAGS = -march=rv32i -mabi=ilp32 -ffreestanding -nostdlib -O2
LDFLAGS = -T linker.ld -nostdlib -Wl,-m,elf32lriscv

OBJS = src/entry.o src/main.o src/font.o

# --------------------------------------------------
# Build
# --------------------------------------------------

all: bios.bin post-build

bios.bin: bios.elf
	$(OBJCOPY) -O binary $< $@

bios.elf: $(OBJS)
	$(CC) $(LDFLAGS) -o $@ $^

# --------------------------------------------------
# Compilation
# --------------------------------------------------

%.o: %.S
	$(CC) $(CFLAGS) -c -o $@ $<

%.o: %.c
	$(CC) $(CFLAGS) -c -o $@ $<

# --------------------------------------------------
# Post-build
# --------------------------------------------------

post-build:
	./bios_make.sh

# --------------------------------------------------
# Cleanup
# --------------------------------------------------

clean:
	rm -f src/*.o *.elf *.bin *.lua
