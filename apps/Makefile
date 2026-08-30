CROSS = $(HOME)/pi-pico2-linux/buildroot/output/host/bin/riscv32-buildroot-linux-uclibc-
CC    = $(CROSS)gcc
FLTHDR = $(CROSS)flthdr

CFLAGS  = -fPIC -mno-relax -Os
LDFLAGS = -Wl,-elf2flt

BINS = hello

all: $(BINS)

%: %.c
	$(CC) $(CFLAGS) $(LDFLAGS) -o $@ $<
	$(FLTHDR) -r $@

clean:
	rm -f $(BINS) *.gdb

.PHONY: all clean
