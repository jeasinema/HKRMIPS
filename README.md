## HKRMIPS

An implementation of MIPS32 Release2, written in verilog.

## Build

### Using ISE

#### for old version thinpad

Use these constraints files:
- `./xilinx/HKRMIPS/soc_hkrmips.ucf` or `./xilinx/HKRMIPS/soc_hkrmips_usb_serial.ucf` if usb-seial on your board works well.
- `./xilinx/HKRMIPS/io_timing.ucf`

#### for new version thinpad(since 2016 fall semester)

Use these constraints files:
- `./xilinx/HKRMIPS/soc_hkrmips_new_thinpad.ucf`
- `./xilinx/HKRMIPS/io_timing.ucf`

## Test

### basic test

Please read `./testbench/cpu_test/test_cpu.sv` or `./testbench/cpu_test/test_cpu_no_ibus_stall.sv` for details.

### ucore

Try this version of ucore:
[ucore-thumips](https://git.net9.org/jeasinema/ucore-thumips.git)
then use `./utility/serial_load.py` to load it to your borad(SRAM or Flash).

## Somthing else

Please put your \*.bit into `./xilinx/HKRMIPS/bitstream/.`, remember to rename it.


## TODO

- [ ] VGA support
- [ ] ps/2 keyboard support
- [ ] run linux
