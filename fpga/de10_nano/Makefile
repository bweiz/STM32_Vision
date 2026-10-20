PROJECT := vision_event
SOF := output_files/$(PROJECT).sof

.PHONY: all compile program clean jtag

all: compile

compile:
	quartus_sh --flow compile $(PROJECT)

program: compile
	quartus_pgm -m JTAG -o "p;$(SOF)@2"

jtag:
	jtagconfig

clean:
	rm -rf db incremental_db output_files
	rm -f *.qws *.rpt *.smsg *.summary

SIM := sim/timestamp_sim

.PHONY: all compile program clean jtag sim wave

sim:
	iverilog -g2012 \
		-o $(SIM) \
		sim/tb_timestamp.sv \
		rtl/cdc_sync.sv \
		rtl/timestamp_counter.sv \
		rtl/event_capture.sv
		rtl/fifo.sv
	vvp $(SIM)

wave: sim
	gtkwave sim/timestamp.vcd

.PHONY: sim-fifo

sim-fifo:
	iverilog -g2012 \
		-o sim/event_fifo_sim \
		sim/tb_event_fifo.sv \
		rtl/cdc_sync.sv \
		rtl/timestamp_counter.sv \
		rtl/event_capture.sv \
		rtl/fifo.sv
	vvp sim/event_fifo_sim

sim-spi:
	iverilog -g2012 \
		-o sim/spi_slave_sim \
		sim/tb_spi_slave.sv \
		rtl/spi_slave.sv
	vvp sim/spi_slave_sim

sim-protocol:
	iverilog -g2012 \
		-o sim/spi_protocol_sim \
		sim/tb_spi_protocol.sv \
		rtl/spi_slave.sv \
		rtl/spi_command.sv \
		rtl/fifo.sv
	vvp sim/spi_protocol_sim
