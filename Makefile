COMP = iverilog
SIM = vvp
SYN = yosys
PNR = arachne-pnr
PACK = icepack
PROG = iceprog

PCF = top.pcf
SOURCE = top
TESTS = top_test_sub.vcd top_test_add.vcd top_test_jump.vcd top_test_load_out.vcd \
				top_test_load_store.vcd top_test_shl.vcd top_test_mul.vcd top_test_fibonacci.vcd

all: $(TESTS)

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
