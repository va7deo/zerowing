
# Toaplan Version 1 FPGA Implemenation for [MiSTerFPGA](https://github.com/MiSTer-devel/Main_MiSTer/wiki)

FPGA compatible core for Toaplan Version 1 arcade hardware for MiSTerFPGA written by [**Darren Olafson**](https://twitter.com/Darren__O).

FPGA implementation based on Zero Wing. Verified against Out Zone TP-015 Conversion PCB.

This FPGA compatible core is in active development with assistance from [**𝕓𝕝𝕒𝕔𝕜𝕨𝕚𝕟𝕖**](https://github.com/blackwine) and [**atrac17**](https://github.com/atrac17).

![Toaplan_logo_shadow_small](https://user-images.githubusercontent.com/32810066/151543842-5f7380a4-9b29-472d-bc03-8cc04a579cf2.png)

## Supported Games

| Title | Status | Released |
|------|---------|----------|
[**Rally Bike**](https://en.wikipedia.org/wiki/Rally_Bike) | **W.I.P** | N |
[**Truxton**](https://en.wikipedia.org/wiki/Truxton_%28video_game%29) | Implemented | **Y** |
[**Hellfire**](https://en.wikipedia.org/wiki/Hellfire_%28video_game%29) | Implemented | **Y** |
[**Zero Wing**](https://en.wikipedia.org/wiki/Zero_Wing) | Implemented | **Y** |
[**Demon's World**](https://en.wikipedia.org/wiki/Demon%27s_World) | Implementation slated by [**Jotego**](https://github.com/jotego) | N/A |
[**Fire Shark**](https://en.wikipedia.org/wiki/Fire_Shark) | **W.I.P** | N |
[**Out Zone**](https://en.wikipedia.org/wiki/Out_Zone) | Implemented | **Y** |
[**Vimana**](https://en.wikipedia.org/wiki/Vimana_%28video_game%29) | **W.I.P** | N |

## External Modules

|Name| Purpose | Author |
|----|---------|--------|
| [**fx68k**](https://github.com/ijor/fx68k) | [**Motorola 68000 CPU**](https://en.wikipedia.org/wiki/Motorola_68000) | Jorge Cwik |
| [**t80**](https://opencores.org/projects/t80) | [**Zilog Z80 CPU**](https://en.wikipedia.org/wiki/Zilog_Z80) | Daniel Wallner |
| [**y80e**](https://opencores.org/projects/y80e) | [**Zilog Z180 CPU**](https://en.wikipedia.org/wiki/Zilog_Z180) | Sergey Belyashov |
| [**jtopl2**](https://github.com/jotego/jtopl) | [**Yamaha OPL 2**](https://en.wikipedia.org/wiki/Yamaha_OPL#OPL2) | Jose Tejada |

# Known Issues

-Clock domains need to be verified  
-HD647180X (Z180) sound implementation  

# PCB Check List

FPGA core timings taken from **Out Zone (Zero Wing TP-015 PCB conversion)** on loan courtesy of [**@owlnonymous**](https://twitter.com/owlnonymous).

### Clock Information

H-Sync   | V-Sync   | Source    | Title 
---------|----------|-----------|-------
15.56kHz | 55.16Hz  | OSSC/RT5X | Out Zone, Rally Bike, Demon's World
15.56kHz | 57.61Hz  | OSSC/RT5X | All Others

### Crystal Oscillators

Location | Freq (MHz) | Use
---------|------------|-------
X1       | 10.00      | M68000
R1       | 28.000     | Video/Sound

**Pixel clock:** 7.00 MHz

**Estimated geometry:**

    450 pixels/line  (Out Zone, Rally Bike, Demon's World)
    282 lines/frame  (Out Zone, Rally Bike, Demon's World)
  
    450 pixels/line  (All Others)
    270 lines/frame  (All Others)

### Main Components

Location | Chip | Use |
---------|------|-----|
K 10-11 | [**Motorola 68000 CPU**](https://en.wikipedia.org/wiki/Motorola_68000) | Main CPU |
N 7-8 |  [**Zilog Z80 CPU**](https://en.wikipedia.org/wiki/Zilog_Z80) | Sound CPU |
M 1-2 | [**Yamaha YM3812**](https://en.wikipedia.org/wiki/Yamaha_OPL#OPL2) | OPL 2 |

### Additional Components

[**Texas Instruments TMS32010**](https://en.wikipedia.org/wiki/Texas_Instruments_TMS320) currently has no verilog implementation; used in **Demon's World**.

[**Hitachi HD647180X MCU**](https://en.wikipedia.org/wiki/Zilog_Z180) used in **Fire Shark** and **Vimana**.

# Licensing

Contact the author for special licensing needs. Otherwise follow the GPLv2 license attached.
