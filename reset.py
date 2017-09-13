import usb.core
dev = usb.core.find(idVendor=0x0403, idProduct=0x6010)

if dev is None:
    raise ValueError('ICE40 FPGA device not found')

dev.reset()
