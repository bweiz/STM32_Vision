TARGET := vision_event
BUILD  := build

CC      := arm-none-eabi-gcc
OBJDUMP := arm-none-eabi-objdump
SIZE    := arm-none-eabi-size

CPUFLAGS := -mcpu=cortex-m7 -mthumb

CFLAGS := $(CPUFLAGS) \
          -Og \
          -g3 \
          -Wall \
          -Wextra \
          -ffreestanding \
          -ffunction-sections \
          -fdata-sections \
          -Iinclude \
          -Ivendor/CMSIS_5/CMSIS/Core/Include \
          -Ivendor/cmsis-device-h7/Include

LDFLAGS := $(CPUFLAGS) \
           -T linker/stm32h723.ld \
           -nostartfiles \
           -nostdlib \
           -Wl,--gc-sections \
           -Wl,-Map=$(BUILD)/$(TARGET).map

SOURCES := \
    startup/startup.c \
    src/main.c \
	src/watchdog.c \
	drivers/gpio.c

OBJECTS := $(SOURCES:%.c=$(BUILD)/%.o)

ELF := $(BUILD)/$(TARGET).elf


all: $(ELF)


$(ELF): $(OBJECTS) linker/stm32h723.ld Makefile
	@mkdir -p $(dir $@)
	$(CC) $(OBJECTS) $(LDFLAGS) -o $@
	$(SIZE) $@


$(BUILD)/%.o: %.c
	@mkdir -p $(dir $@)
	$(CC) $(CFLAGS) -c $< -o $@


inspect: $(ELF)
	$(OBJDUMP) -h $(ELF)


clean:
	rm -rf $(BUILD)


.PHONY: all inspect clean
