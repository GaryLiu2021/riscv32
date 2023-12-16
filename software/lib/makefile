INC := -I../include
LIB_NAME := uart
BUILD_DIR := ./build

gnu = riscv32-unknown-elf
CC = $(gnu)-gcc
CFLAGS = -Wall -march=rv32i -mabi=ilp32 -nostartfiles $(INC)

AR := $(gnu)-ar
ARFLAGS := rc

DP = $(gnu)-objdump
DPFLAGS = -S

OBJS := $(patsubst %.c,%.o,$(wildcard *.c)) $(patsubst %.S,%.o,$(wildcard *.S))

all: lib$(LIB_NAME).a lib$(LIB_NAME).dump $(OBJS)
	mkdir -p $(BUILD_DIR)
	mv $^ $(BUILD_DIR)

%.a: objects
	$(AR) $(ARFLAGS) $@ $(OBJS)

objects: $(OBJS)

%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

%.o: %.S
	$(CC) $(CFLAGS) -c $< -o $@

%.dump: %.a
	$(DP) $(DPFLAGS) $< > $@

clean:
	rm -rf $(BUILD_DIR)