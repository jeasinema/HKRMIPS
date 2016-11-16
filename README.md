## HKRMIPS

An implementation of MIPS32 Release2, using verilog.

## Build

### Using ISE

#### for old version thinpad

use these constraints files:
- `./xilinx/HKRMIPS/soc_hkrmips.ucf` or `./xilinx/HKRMIPS/soc_hkrmips_usb_serial.ucf` if usb-seial on your board works well.
- `./xilinx/HKRMIPS/io_timing.ucf`

#### for new version thinpad(since 2016 fall semester)

use these constraints files:
- `./xilinx/HKRMIPS/soc_hkrmips_new_thinpad.ucf`
- `./xilinx/HKRMIPS/io_timing.ucf`

## Test

### ucore

use this version of ucore:
[ucore-thumips](https://git.net9.org/jeasinema/ucore-thumips.git)

## TODO

- [ ] VGA support
- [ ] ps/2 keyboard support
- [ ] run linux
