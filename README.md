# BBSoftCPU

A Verilog HDL implementation of a breadboard TTL CPU design. The design itself is based on the
series of educational [videos][1] by Ben Eater.

Testing can be done on the Lattice iCE40 family of FPGAs. The specific board used during development is:

* [icestick][2]

This particular family of FPGAs is currently supported by a fully open source toolchain.
For anyone interested further information is available at:

* [Yosys][3]
* [arachne-pnr][4]
* [IceStorm][5]

There are several notable modifications from the original design:

* There is no internal bus or tri-state logic. The latter is rarely if ever supported internally on current FPGAs. Muxers
are used as a replacement.
* The control logic is not triggered by the negative clock edge. The positive clock edge is used throughout.
* The 'OUT' instruction doesn't output to any display HW. The FPGA board used for testing does have an extra UART port.
The instruction will transmit the value of register 'A' on the second port.

## Build environment

Ubuntu 16.04 or newer. The toolchain and verilog simulator can be installed via:

```
sudo apt-get install build-essential arachne-pnr iverilog
```

You could also install GtkWave for viewing the simulation waveforms:

```
sudo apt-get install gtkwave
```

And minicom for receiving the output:

```
sudo apt-get install minicom
```

## Running the simulator test bench

The simulator can be invoked via:

```
make
```

The output should be a 'top_test.vcd' file that can be viewed using GtkWave:

```
gtkwave top_test.vcd
```

## USB permissions for the FPGA board

Before flashing the FPGA board, the USB access permissions need a minor adjustment that will allow the tools to
write a bitstream on the device. Create a new file at:
```
/etc/udev/rules.d/53-lattice-ftdi.rules
```

Add this line inside:

```
ACTION=="add", ATTR{idVendor}=="0403", ATTR{idProduct}=="6010", MODE:="666"
```

## Flashing

Make sure that the icestick board is connected to the host PC.
Flashing the bitstream on the FPGA can be done by invoking:

```
make flash
```

## Receiving output

The default program will currently calculate the fibonacci sequence of numbers.
As mentioned before the 'OUT' instruction will transmit the register 'A' contents on the second UART port.
The serial device will usually appear on the host as '/dev/ttyUSB1'. The configuration used right now is:

* baudrate: 19000
* bits: 8
* parity: none
* stop bits: 2
* no hw flow control

The data comes in as binary so for nicer output you can instruct minicom to display in hex mode:

```
minicom -H
```

This is not an official Google product

[1]: https://www.youtube.com/user/eaterbc
[2]: http://www.latticesemi.com/icestick
[3]: http://www.clifford.at/yosys/
[4]: https://github.com/cseed/arachne-pnr
[5]: http://www.clifford.at/icestorm/

