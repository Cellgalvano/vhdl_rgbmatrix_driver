# vhdl_rgbmatrix_driver
A simple driver for RGB Led Panels of different sizes

This project is an entry for the Arrow European FPGA Developer Contest 2019.

The goal of this project is to write a universal driver for rgb panels (HUB75) and provide a simple interface for microcontrollers to send pixeldata.  

Currently the dataflow looks like this:
SPI or UART --> FPGA[ FRAMEBUFFER --> BUFFERCONV --> LEDCTRL ] --> PANEL

This project was initialy inspired by the code of https://github.com/adafruit/rgbmatrix-fpga

Features:
- [x] basic functionality
- [x] compatible with 16x32 panels (should work, untested)
- [x] compatible with 32x32 panels + chained
- [x] compatible with 64x64 panels + chained
- [x] UART receiver
- [x] SPI slave 
- [ ] I2C slave
- [x] double framebuffer / backbuffer
- [ ] multiple framebuffers (in SDRAM?)
- [x] basic gamma correction
- [ ] dynamicly reconfigurable gamma correction
- [x] configuration via generics (config.vhd)
- [ ] advanced command interface to change config on the fly
