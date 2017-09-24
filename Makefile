COMP = iverilog
SIM = vvp
SYN = yosys
PNR = arachne-pnr
PACK = icepack
PROG = iceprog

PCF = top.pcf
SOURCE = top
TEST = top_test

all: $(TEST).vcd

%.vcd: %.vvp
	$(SIM) $<

%.vvp: %.v
	$(COMP) -o $@ $<

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
