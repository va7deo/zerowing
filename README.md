
# Toaplan Version 1  FPGA Implementation

FPGA compatible core of Toaplan Version 1 arcade hardware for [**MiSTerFPGA**](https://github.com/MiSTer-devel/Main_MiSTer/wiki) written by [**Darren Olafson**](https://twitter.com/Darren__O). FPGA implementation is based on schematics and verified against an Out Zone (TP-015 Conversion / TP-018), Vimana (TP-019), Tatsujin (TP-013B), and Rally Bike (TP-012).

The intent is for this core to be a 1:1 implementation of Toaplan V1 hardware. Currently in beta state, this core is in active development with assistance from [**𝕓𝕝𝕒𝕔𝕜𝕨𝕚𝕟𝕖**](https://github.com/blackwine) and [**atrac17**](https://github.com/atrac17).

![Toaplan_logo_shadow_small](https://user-images.githubusercontent.com/32810066/151543842-5f7380a4-9b29-472d-bc03-8cc04a579cf2.png)

## Supported Games

| Title | Status | Released |
|------|---------|----------|
[**Dash Yarou**](https://en.wikipedia.org/wiki/Rally_Bike) | **W.I.P** | N |
[**Tatsujin**](https://en.wikipedia.org/wiki/Truxton_%28video_game%29) | Implemented | **Y** |
[**Hellfire**](https://en.wikipedia.org/wiki/Hellfire_%28video_game%29) | Implemented | **Y** |
[**Zero Wing**](https://en.wikipedia.org/wiki/Zero_Wing) | Implemented | **Y** |
[**Horror Story**](https://en.wikipedia.org/wiki/Demon%27s_World) | Implementation slated by [**Jotego**](https://github.com/jotego) | N/A |
[**Same! Same! Same!**](https://en.wikipedia.org/wiki/Fire_Shark) | **W.I.P** | N |
[**Out Zone**](https://en.wikipedia.org/wiki/Out_Zone) | Implemented | **Y** |
[**Vimana**](https://en.wikipedia.org/wiki/Vimana_%28video_game%29) | **W.I.P** | N |

## External Modules

|Name| Purpose | Author |
|----|---------|--------|
| [**fx68k**](https://github.com/ijor/fx68k) | [**Motorola 68000 CPU**](https://en.wikipedia.org/wiki/Motorola_68000) | Jorge Cwik |
| [**t80**](https://opencores.org/projects/t80) | [**Zilog Z80 CPU**](https://en.wikipedia.org/wiki/Zilog_Z80) | Daniel Wallner |
| [**y80e**](https://opencores.org/projects/y80e) | [**Zilog Z180 CPU**](https://en.wikipedia.org/wiki/Zilog_Z180) | Sergey Belyashov |
| [**jtopl2**](https://github.com/jotego/jtopl) | [**Yamaha OPL 2**](https://en.wikipedia.org/wiki/Yamaha_OPL#OPL2) | Jose Tejada |

# Known Issues / Tasks

- ~~Screen Flip/Cocktail Mode has yet to be implemented~~  
- ~~Exiting the service menu hangs on a sound error~~  
- ~~Clock domains need to be verified (Out Zone TP-015)~~  
- ~~Sprites disappearing when they touch the first scanline or first pixel of a scanline (Out Zone)~~  
- ~~OPL2 sound implementation~~  
- ~~Clock domains need to be verified (Tatsujin)~~  
- Dot Crawl on Y/C video output  
- Clock domains need to be verified (Dash Yarou)  
- Clock domains need to be verified (Out Zone TP-018)  
- Clock domains need to be verified (Vimana)  
- Sprite handler for Dash Yarou  
- HD647180X (Z180) sound implementation  
- jtopl2 percussion mix  

# PCB Check List

### Clock Information

H-Sync | V-Sync | Source | Title |
-------|--------|--------|-------|
15.556938kHz | 55.161153Hz  | DSLogic + | Out Zone, Rally Bike, Demon's World
15.56kHz     | 57.61Hz      | DSLogic + | Tatsujin, Vimana, Fire Shark, Zero Wing, Hellfire

### Crystal Oscillators

Location | Freq (MHz) | Use
---------|------------|-------
X1       | 10.00      | M68000
R1       | 28.000     | Video/Sound

**Pixel clock:** 7.00 MHz

**Estimated geometry:**

    450 pixels/line  (Out Zone, Dash Yarou, Horror Story)
    282 lines/frame  
  
    450 pixels/line  (Tatsujin, Vimana, Same!(3x), Zero Wing, Hellfire)
    270 lines/frame  

### Main Components

Location | Chip | Use |
---------|------|-----|
K 10-11 | [**Motorola 68000 CPU**](https://en.wikipedia.org/wiki/Motorola_68000) | Main CPU |
N 7-8   | [**Zilog Z80 CPU**](https://en.wikipedia.org/wiki/Zilog_Z80)           | Sound CPU |
M 1-2   | [**Yamaha YM3812**](https://en.wikipedia.org/wiki/Yamaha_OPL#OPL2)     | OPL 2 |

### Custom Components

Location | Chip | Use |
---------|------|-----|
A 3-6   | **FCU-2**              | Custom Graphics IC  |
H 9     | **NEC D65081R077**     | Custom Graphics IC  |
E 1     | **TOAPLAN-02 M70H005** | Custom Toaplan Chip |

### Additional Components

Location | Chip | Use | PCB |
---------|------|-----|-----|
N/A | [**TMS32010**](https://en.wikipedia.org/wiki/Texas_Instruments_TMS320) | DSP MCU | **Horror Story** |
N/A | [**HD647180X**](https://en.wikipedia.org/wiki/Zilog_Z180)              | Sound CPU & I/O Handling | **Same! (3x) / Vimana** |

<br>

The [**Texas Instruments TMS32010**](https://en.wikipedia.org/wiki/Texas_Instruments_TMS320) DSP currently has no verilog implementation; used on the **Horror Story** PCB. The core author has no desire to write this DSP. Implementation of this game will be handled by [**Jotego**](https://github.com/jotego).

# PCB / Debugging Features

**W.I.P**

# Control Layout

<h3 align="left">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;2L6B Control Panel Layout (Common Layout)&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</h3>

<p align="left"><img width="630" height="138" src="https://user-images.githubusercontent.com/32810066/167370068-13dadae8-e7f5-478f-90b4-8d5f5f5c7316.png"></p> 

<h3 align="left">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;1L3B Control Panel Layout (Table Layout)&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</h3>

<p align="left"><img width="630" height="138" src="https://user-images.githubusercontent.com/32810066/167615931-feb562eb-8d16-4fdd-a7af-99cb51968784.png"></p>

Game | Joystick | Service Menu | Shared Controls | Dip Default |
:---: | :---: | :---: | :---: | :---: |
Tatsujin  | 8-Way | <p align="center"><img width="120" height="160" src="https://user-images.githubusercontent.com/32810066/167747857-36df66e5-723d-4f71-a78d-43ee8c0cca4d.png"></p> | No | **Upright**
Hellfire  | 8-Way | <p align="center"><img width="160" height="120" src="https://user-images.githubusercontent.com/32810066/167690883-79115100-7587-44e8-9600-e62ae3b95fc5.png"></p> | Co-Operative | **Upright**
Zero Wing | 8-Way | <p align="center"><img width="160" height="120" src="https://user-images.githubusercontent.com/32810066/167689998-8d41e9cb-1782-4400-9ba5-18be07ac2d6b.png"></p> | Co-Operative | **Upright**
Out Zone  | 8-Way | <p align="center"><img width="120" height="160" src="https://user-images.githubusercontent.com/32810066/167690988-bf045fc4-9e78-4cdd-b167-6e55fbd3470b.png"></p> | Co-Operative | **Upright**

<br>

- Upright cabinets share a **1L3B** control panel layout. Players are required to switch controller. If set the cabinet type is set to table, the screen inverts for cocktail mode per player and has multiple controls. <br><br>Push button 3 may have no function in game, but corresponds to the original hardware and service menu.

### Keyboard Handler

- Keyboard inputs mapped to mame defaults for all functions.

|Services|Coin/Start|
|--|--|
|<table> <tr><th>Functions</th><th>Keymap</th></tr><tr><td>Test</td><td>F2</td></tr><tr><td>Reset</td><td>F3</td></tr><tr><td>Service</td><td>9</td></tr><tr><td>Pause</td><td>P</td></tr> </table> | <table><tr><th>Functions</th><th>Keymap</th><tr><tr><td>P1 Start</td><td>1</td></tr><tr><td>P2 Start</td><td>2</td></tr><tr><td>P1 Coin</td><td>5</td></tr><tr><td>P2 Coin</td><td>6</td></tr> </table>|

|Player 1|Player 2|
|--|--|
|<table> <tr><th>Functions</th><th>Keymap</th></tr><tr><td>P1 Up</td><td>Up</td></tr><tr><td>P1 Down</td><td>Down</td></tr><tr><td>P1 Left</td><td>Left</td></tr><tr><td>P1 Right</td><td>Right</td></tr><tr><td>P1 Bttn 1</td><td>L-CTRL</td></tr><tr><td>P1 Bttn 2</td><td>L-ALT</td></tr><tr><td>P1 Bttn 3</td><td>Space</td></tr> </table> | <table> <tr><th>Functions</th><th>Keymap</th></tr><tr><td>P2 Up</td><td>R</td></tr><tr><td>P2 Down</td><td>F</td></tr><tr><td>P2 Left</td><td>D</td></tr><tr><td>P2 Right</td><td>G</td></tr><tr><td>P2 Bttn 1</td><td>A</td></tr><tr><td>P2 Bttn 2</td><td>S</td></tr><tr><td>P2 Bttn 3</td><td>Q</td></tr> </table>|

# Support

Please consider showing support for this and future projects via [**Ko-fi**](https://ko-fi.com/darreno). While it isn't necessary, it's greatly appreciated.

# Acknowledgments

The following individuals loaned hardware used during development. Team Toaplan can't thank you enough!

[**@owlnonymous**](https://twitter.com/owlnonymous) for loaning Out Zone (TP-015 Conversion)<br>
[**@cathoderaze**](https://twitter.com/cathoderaze)  for loaning Tatsujin (TP-013B)<br>
[**@90s_cyber_thriller**](https://www.instagram.com/90s_cyber_thriller/) for loaning Vimana (TP-019) and Outzone (TP-018)<br>

# Licensing

Contact the author for special licensing needs. Otherwise follow the GPLv2 license attached.
