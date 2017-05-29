COMP = iverilog
SIM = vvp

SOURCES = top_test

all: $(SOURCES).vcd

%.vcd: %.vvp
	$(SIM) $<

%.vvp: %.v
	$(COMP) -o $@ $<

clean:
	rm -f *.vvp *.vcd

.PHONY: all clean
