
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
15.556938kHz | 57.612182Hz  | DSLogic + | Tatsujin, Vimana, Fire Shark, Zero Wing, Hellfire

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
E 1     | **TOAPLAN-02 M70H005** | Custom Toaplan IC   |

### Additional Components

Location | Chip | Use | PCB |
---------|------|-----|-----|
N/A | [**TMS32010**](https://en.wikipedia.org/wiki/Texas_Instruments_TMS320) | DSP MCU | **Horror Story** |
N/A | [**HD647180X**](https://en.wikipedia.org/wiki/Zilog_Z180)              | Sound CPU & I/O Handling | **Same! (3x) / Vimana** |

<br>

The [**Texas Instruments TMS32010**](https://en.wikipedia.org/wiki/Texas_Instruments_TMS320) DSP currently has no verilog implementation; used on the **Horror Story** PCB. The core author has no desire to write this DSP. Implementation of this game will be handled by [**Jotego**](https://github.com/jotego).

# PCB Information

|<p align="center">Game Debugging|
:---: |
|<table> <tr><th>Tatsujin</th><th>Debugging Features</th></tr><tr><td><p align="center"><img align="center" width="120" height="160" src="https://user-images.githubusercontent.com/32810066/168002706-4ce9d953-3354-4a3d-ae21-8ca35d9d8b79.png"></img></p></td><td><p align="left"> To access test mode, press P1 Start when the grid is displayed in "Service Mode".<br><br> To access sound test, press P2 Start when the grid is displayed in "Service Mode".<br><br> Turn the "Service Mode" dipswitch on in game for invulnerability.<br><br> Set the "Dip Switch Display" dipswitch to on in game to pause.<br><br> When the cabinet dipswitch is "Upright", you can use controls from both players.</p></td><tr><th>Hellfire</th><th>Debugging Features [hellfire/hellfire1]</th></tr><tr><td><img align="center" width="160" height="120" src="https://user-images.githubusercontent.com/32810066/168088336-98975efb-bc6a-4c87-a5af-1d7b9f174f2d.png"></img></td><td><p align="left"> In game, enable the "Invulnerability" dip and press P2 Start to pause; P1 Start to resume.<br><br> When holding P1 Start and P2 Start, this will enable a slower framerate in game.<br><br> When the cabinet dipswitch is "Upright", you can use controls from both players.</p></td><tr><th>Zero Wing</th><th>Debugging Features [zerowing]</th></tr><tr><td><img align="center" width="160" height="120" src="https://user-images.githubusercontent.com/32810066/168094988-8e159945-6152-43f9-8f73-3dd738a4bcdd.png"></img></td><td><p align="left"> In game, enable the "Invulnerability" dip and press P2 Start to pause; P1 Start to resume.<br><br> When holding P1 Start and P2 Start, this will enable a slower framerate in game.<br><br> When the cabinet dipswitch is "Upright", you can use controls from both players.</p></td><tr><th>Out Zone</th><th>Debugging Features [outzoneb]</th></tr><tr><td><br><p align="center"><img align="center" width="120" height="160" src="https://user-images.githubusercontent.com/32810066/168094995-0b7b919c-65b4-409b-95dd-be2b47ea2923.png"></img></p></td><td><p align="left"> Set both "Debug" dipswitches to on and reset the game. Hold P2 Down during the boot sequence. <br><br>This enables the CRTC registers to be programmed for a smaller VTOTAL enabling a higher frame<br>rate by reducing the edges of the screen. This changes the native refresh rate of Out Zone from 55.2Hz to 58.5Hz. It's fully functional in the core. (**This is not correctly emulated in mame**)</p></td> </table>


|<p align="center">Regional Differences|
 :---: |
|<b>Tatsujin</b>|
|<table> <tr><th>Title Screen</th><th>Notice Screen</th><th>Copyright Screen</th><th>Notes</th></tr><tr><td><p align="center"><img width="120" height="160" src="https://user-images.githubusercontent.com/32810066/168115413-58da3fba-c8a5-4c71-b7f9-2092ce021c9e.png"></img> <br><b>Japan<br><br> <p align="center"><img width="120" height="160" src="https://user-images.githubusercontent.com/32810066/168115428-947cc08b-9316-465d-881e-01c69609b0b2.png"></img> <br><b>USA / Europe </p></td><td><p align="center"><img width="120" height="160" src="https://user-images.githubusercontent.com/32810066/168115440-3e7c8f8a-f1ac-49dc-85bf-24e032e18d46.png"></img> <br><b>Japan<br><br> </p><p align="center"><img width="120" height="160" src="https://user-images.githubusercontent.com/32810066/168115447-d86d5672-d4d1-458a-a2a2-7f0e6b97c2c9.png"></img><br><b>USA (ROMSTAR) </p></td><td><img width="120" height="160" src="https://user-images.githubusercontent.com/32810066/168115455-989c3081-85c2-4eb2-8a09-e20096199402.png"/>  <img width="120" height="160" src="https://user-images.githubusercontent.com/32810066/168115461-f32febb4-0267-4d15-ba99-2dd635820a64.png"/><br><b>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Japan / USA (ROMSTAR) <br><br><img width="120" height="160" src="https://user-images.githubusercontent.com/32810066/168120995-9b3f9419-fe7e-4761-adcf-f957573002d0.png"/>  <img width="120" height="160" src="https://user-images.githubusercontent.com/32810066/168118147-4b412655-0d44-4264-ab01-b29e049e0375.png"/><br><b>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;USA / Europe<br></td><td><p align="left"> <u>**Title / Notice Screen:**</u><br>Tatsujin (Japan)<br>Truxton (All others)<br>"FOR USE IN JAPAN ONLY"<br>"FOR USE IN U.S.A. ONLY"<br><br><u>**Copyright Screen:**</u><br>"TAITO CORPORATION"<br>"TAITO AMERICA CORP."<br>"ALL RIGHTS RESERVED"<br>"LICENCED TO ROMSTAR FOR U.S.A."<br><br><u>**High Score Entry:**</u><br>Japan / 6 letters<br>All others / 3 letters </td></table>
|<b>Hellfire</b>|
|<table> <tr><th>Notice Screen</th><th>Copyright Screen</th><th>Notes</th></tr><td><p align="center"><img width="160" height="120" src="https://user-images.githubusercontent.com/32810066/168159492-9816379a-841a-4e99-9c32-57cb6991a41a.png"></img><p align="center"><b>Japan<td><p align="center"><img width="160" height="120" src="https://user-images.githubusercontent.com/32810066/168159142-37ae319e-41fa-425e-a23b-ffdaf499fcfe.png"/> <img width="160" height="120" src="https://user-images.githubusercontent.com/32810066/168159138-72ad3e09-9280-4508-b805-98b56f395135.png"/></p><p align="center"><b>All others / USA<td><p align="left"> <u>**Title / Notice Screen:**</u><br>"FOR USE IN JAPAN ONLY"<br>"FOR USE IN U.S.A. ONLY"<br><br><u>**Copyright Screen:**</u><br>"LICENSED TO TAITO CORPORATION"<br>"LICENSED TO TAITO<br> AMERICA CORPORATION"<br>"@ TOAPLAN CO. LTD. 1989"<br><br><u>**High Score Entry:**</u><br>All / 3 letters </td></table>
|<b>Zero Wing</b>|
|<table> <tr><th>Notice Screen</th><th>Notes</th></tr><tr><td><p align="center"><img width="160" height="120" src="https://user-images.githubusercontent.com/32810066/168165410-926bd13b-14ec-4fb4-b032-834674ced316.png"></img> <br><b>Japan<br></p></td><td> <u>**Title / Notice Screen:**</u><br>"FOR USE IN JAPAN ONLY"<br>"FOR USE IN U.S.A. ONLY"<br><br><u>**High Score Entry:**</u><br>Japan / 6 letters<br>All others / 3 letters </td>
</table>

# Control Layout

Game | Joystick | Service Menu | Shared Controls | Dip Default |
:---: | :---: | :---: | :---: | :---: |
**Tatsujin**  | 8-Way | <p align="center"><img width="120" height="160" src="https://user-images.githubusercontent.com/32810066/167747857-36df66e5-723d-4f71-a78d-43ee8c0cca4d.png"></p> | No | **Upright**
**Hellfire**  | 8-Way | <p align="center"><img width="160" height="120" src="https://user-images.githubusercontent.com/32810066/167690883-79115100-7587-44e8-9600-e62ae3b95fc5.png"></p> | Co-Operative | **Upright**
**Zero Wing** | 8-Way | <p align="center"><img width="160" height="120" src="https://user-images.githubusercontent.com/32810066/167689998-8d41e9cb-1782-4400-9ba5-18be07ac2d6b.png"></p> | Co-Operative | **Upright**
**Out Zone**  | 8-Way | <p align="center"><img width="120" height="160" src="https://user-images.githubusercontent.com/32810066/167690988-bf045fc4-9e78-4cdd-b167-6e55fbd3470b.png"></p> | Co-Operative | **Upright**

<br>

- Upright cabinets by default should be a **2L3B** control panel layout. Alternatively, they may share a **1L3B** control panel layout. If so, players are required to switch their controller method. 
- If the cabinet type is set to table, the screen inverts for cocktail mode per player and has multiple controls.
- Push button 3 may have no function in game, but corresponds to the original hardware and service menu.

### Keyboard Handler

- Keyboard inputs mapped to mame defaults for all functions.

|Services|Coin/Start|
|--|--|
|<table> <tr><th>Functions</th><th>Keymap</th></tr><tr><td>Test</td><td>F2</td></tr><tr><td>Reset</td><td>F3</td></tr><tr><td>Service</td><td>9</td></tr><tr><td>Pause</td><td>P</td></tr> </table> | <table><tr><th>Functions</th><th>Keymap</th><tr><tr><td>P1 Start</td><td>1</td></tr><tr><td>P2 Start</td><td>2</td></tr><tr><td>P1 Coin</td><td>5</td></tr><tr><td>P2 Coin</td><td>6</td></tr> </table>|

|Player 1|Player 2|
|--|--|
|<table> <tr><th>Functions</th><th>Keymap</th></tr><tr><td>P1 Up</td><td>Up</td></tr><tr><td>P1 Down</td><td>Down</td></tr><tr><td>P1 Left</td><td>Left</td></tr><tr><td>P1 Right</td><td>Right</td></tr><tr><td>P1 Bttn 1</td><td>L-CTRL</td></tr><tr><td>P1 Bttn 2</td><td>L-ALT</td></tr><tr><td>P1 Bttn 3</td><td>Space</td></tr> </table> | <table> <tr><th>Functions</th><th>Keymap</th></tr><tr><td>P2 Up</td><td>R</td></tr><tr><td>P2 Down</td><td>F</td></tr><tr><td>P2 Left</td><td>D</td></tr><tr><td>P2 Right</td><td>G</td></tr><tr><td>P2 Bttn 1</td><td>A</td></tr><tr><td>P2 Bttn 2</td><td>S</td></tr><tr><td>P2 Bttn 3</td><td>Q</td></tr> </table>|

# Acknowledgments

The following individuals loaned hardware used during development. Team Toaplan can't thank you enough!

[**@owlnonymous**](https://twitter.com/owlnonymous) for loaning Out Zone (TP-015 Conversion)<br>
[**@cathoderaze**](https://twitter.com/cathoderaze)  for loaning Tatsujin (TP-013B)<br>
[**@90s_cyber_thriller**](https://www.instagram.com/90s_cyber_thriller/) for loaning Vimana (TP-019) and Outzone (TP-018)<br>

# Support

Please consider showing support for this and future projects via [**Ko-fi**](https://ko-fi.com/darreno). While it isn't necessary, it's greatly appreciated.

# Licensing

Contact the author for special licensing needs. Otherwise follow the GPLv2 license attached.
