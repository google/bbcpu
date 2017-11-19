COMP = iverilog
SIM = vvp
SYN = yosys
PNR = arachne-pnr
PACK = icepack
PROG = iceprog

PCF = top.pcf
SOURCE = top
TEST_FIB = top_test_fibonacci
TEST_LOAD_OUT = top_test_load_out
TEST_JMP = top_test_jump
TEST_ADD = top_test_add
TEST_SUB = top_test_sub
TEST_SHL = top_test_shl

all: $(TEST_SHL).vcd $(TEST_SUB).vcd $(TEST_ADD).vcd $(TEST_JMP).vcd $(TEST_LOAD_OUT).vcd\
 $(TEST_FIB).vcd

%.vcd: %.vvp
	$(SIM) $<

%.vvp: %.v
	$(COMP) -Wall -o $@ $<

%.blif: %.v
	$(SYN) -q -p "synth_ice40 -blif $@" $<

%.txt: %.blif
	$(PNR) -p $(PCF) -o $@ $<

%.bin: %.txt
	$(PACK) $< $@

flash: $(SOURCE).bin
	$(PROG) $<

clean:
	rm -f *.vvp *.vcd *.blif *.bin *.txt

.PHONY: clean
