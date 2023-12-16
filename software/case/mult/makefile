NAME := mult
INC := -I../../include
BUILD_DIR := ./build

GNU = riscv32-unknown-elf
CC = $(GNU)-gcc
CFLAGS = -Wall -march=rv32i -mabi=ilp32 -nostartfiles $(INC)

LD = $(GNU)-ld
LD_SC = link.ld
LIB_PATH := ../../lib
LIB_NAME := uart
LIB_FLAG := -L$(LIB_PATH)/build -l$(LIB_NAME)
LDFLAGS = -T $(LD_SC) $(LIB_FLAG)

DP = $(GNU)-objdump
DPFLAGS = -S

CP = $(GNU)-objcopy
CPFLAGS = -O binary

OBJS := $(patsubst %.c,%.o,$(wildcard *.c))

all: $(NAME).elf $(NAME).dump $(NAME).bin $(OBJS)
	mkdir -p $(BUILD_DIR)
	mv $^ $(BUILD_DIR)

%.elf: $(OBJS) $(LD_SC) lib
	$(LD) $(OBJS) $(LDFLAGS) -o $@

%.dump: %.elf
	$(DP) $(DPFLAGS) $< > $@

%.bin: %.elf
	$(CP) $(CPFLAGS) $< $@

%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

lib:
	make -C $(LIB_PATH)

clean:
	rm -rf $(BUILD_DIR)