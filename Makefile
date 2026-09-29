.PHONY: all stm32 clean

all: stm32

stm32:
	$(MAKE) -C stm32

clean:
	$(MAKE) -C stm32 clean
