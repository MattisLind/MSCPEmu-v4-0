# MSCP Emulator

MSCP Emulator is a dual-width Q-BUS card for PDP-11. It emulates an MSCP disk controller
and allows to store disk images on a SD-Card. The following operating systems boot
successfully as of release v1.3.0
- RT-11 V5.3
- RT-11 V5.7
- RSX-11Mplus V4.6
- 2.11 BSD
- RSTS/E 10.1
- ULTRIX-11 V3.1
- XXDP V2.5


## Content

This repository contains the main firmware. The firmware is written in AVR Assembler 
for the assembler `avrasm2`, which is included in Microchip Studio.

## Requirements

### PCB DISKEmu-v5-1

The MSCP Emulator runs on the DISKEmu-v5-1 Q-BUS card. This card fits in any Q-BUS slot
of a LSI-11 system.

### CPLD Programming

The CPLDs on the DISKEmu hardware need to be programmed with the appropriate JEDEC files.

### Microcontroller Firmware

To build the firmware for this MSCP Emulator you need also the include and FAT
repositories


## Releases

### v1.0.0

First public release. Boots RT-11 V5.3, RT-11 V5.7, RSX-11M+ V4.6 and BSD 2.11.
There is still an issue booting RSTS/E

### v1.0.1

Minor corrections for output

### v1.1.0

This is the first release that supports MSCP or RLV12 emulation. Select the
appropriate HEX file to program the microcontroller. 

### v1.2.1

This release fixes the return status of MSCP commands CMP, ACC and others 
which prevented RSTS/E and XXDP from booting successfully. This release
now boots into RT-11, RSX-11Mplus, BSD 2.11, RSTS/E and XXDP

### v1.3.0

This release brings the `bootrom` command from my RLV12 emulator to the DISK
emulator. This release requires the CPLD design files v1.1.0 or higher. The
CPLD can now be set by the microcontroller to respond to IO-Page addresses 
173000<sub>8</sub> to 173177<sub>8</sub>. When this boot ROM range is enabled
the microcontroller can provide the instructions of a small bootstrap ROM image.
The bootstrap ROM can be up to 64. words. The default is a small bootstrap
program that boots unit 0 from the MSCP controller at address 172150<sub>8</sub>.

You can manually load your own boostrap code via the command line interface
from files stored on the SD-Card uinsg the bootrom load <i>filename</i> command.

### v2.0.0

This release bringes two important changes, first it uses the AVR-DB USERROW to
save important settings that will survive a firmware upgrade, reset or power cycle.
The settings are saved as `config`. Three commands allow to show, save and erase
the config stored to the USERROW. USERROW is a 32byte flash region that is not
affected by a flash erase.

The settings that are saved in v2.0.0 are, the logging flags for general log
output and unit related logging, the setting about the boot ROM and whether the
controller should be configured for the primary or secondary device register
address. 

Boot ROM settings require CPLD design files v1.3.0 or newer. Device register
address setting requires CPLD design files v2.0.0.

The bootrom intern command now copies the bootstrap loader for either DL or
DU to the 173000<sub>8</sub> range of the IO page, depending on the firmware.
This is also the default boot ROM loaded when the boot ROM is enabled.

This allows to boot the PDP-11 directly form either DL0: or DU0: at power-up,
if the bootstrap option has been selected to start with address 173000<sub>8</sub>.
