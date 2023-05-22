
# Toaplan (Zero Wing) FPGA Implementation

FPGA compatible core of Toaplan Version 1 arcade hardware for [**MiSTerFPGA**](https://github.com/MiSTer-devel/Main_MiSTer/wiki) written by [**Darren Olafson**](https://twitter.com/Darren__O). Based on schematics and verified against OutZone (TP-015 Conversion / TP-018) and Tatsujin (TP-013B).

The intent is for this core to be a 1:1 implementation of Toaplan V1 hardware. This core was developed with assistance from [**atrac17**](https://github.com/atrac17) and [**𝕓𝕝𝕒𝕔𝕜𝕨𝕚𝕟𝕖**](https://github.com/blackwine).

Rally Bike (TP-012), Horror Story / Demon's World (TP-016), Fireshark (TP-017), and Vimana (TP-019) are also Toaplan V1 hardware and have separate repositories located [here](https://github.com/va7deo?tab=repositories).

![zwcore_github](https://github.com/va7deo/zerowing/assets/32810066/db31670a-dc4e-4ff6-a803-2738e2ef9a86)

## Supported Titles

| Title                                                                   | PCB<br>Number | Status      | Released |
|-------------------------------------------------------------------------|---------------|-------------|----------|
| [**Tatsujin**](https://en.wikipedia.org/wiki/Truxton_%28video_game%29)  | TP-013B       | Implemented | Yes      |
| [**Hellfire**](https://en.wikipedia.org/wiki/Hellfire_%28video_game%29) | B90 (TP-014)  | Implemented | Yes      |
| [**Zero Wing**](https://en.wikipedia.org/wiki/Zero_Wing)                | TP-015        | Implemented | Yes      |
| [**OutZone**](https://en.wikipedia.org/wiki/Out_Zone)                   | TP-018        | Implemented | Yes      |

## External Modules

| Module                                                                                | Function                                                               | Author                                         |
|---------------------------------------------------------------------------------------|------------------------------------------------------------------------|------------------------------------------------|
| [**fx68k**](https://github.com/ijor/fx68k)                                            | [**Motorola 68000 CPU**](https://en.wikipedia.org/wiki/Motorola_68000) | Jorge Cwik                                     |
| [**t80**](https://opencores.org/projects/t80)                                         | [**Zilog Z80 CPU**](https://en.wikipedia.org/wiki/Zilog_Z80)           | Daniel Wallner                                 |
| [**jtopl2**](https://github.com/jotego/jtopl)                                         | [**Yamaha OPL2**](https://en.wikipedia.org/wiki/Yamaha_OPL#OPL2)       | Jose Tejada                                    |
| [**yc_out**](https://github.com/MikeS11/MiSTerFPGA_YC_Encoder)                        | [**Y/C Video Module**](https://en.wikipedia.org/wiki/S-Video)          | Mike Simone                                    |
| [**mem**](https://github.com/MiSTer-devel/Arcade-Rygar_MiSTer/tree/master/src/mem)    | SDRAM Controller / Rom Downloader                                      | Josh Bassett, modified by Darren Olafson       |
| [**core_template**](https://github.com/MiSTer-devel/Template_MiSTer)                  | MiSTer Framework Template                                              | sorgelig, modified by Darren Olafson / atrac17 |

# Known Issues / Tasks

- [**OPL2 Audio**](https://github.com/jotego/jtopl/issues/11)  **[Issue]**  
- Timing issues with jtframe_mixer module; false paths added to sdc (may need refactor?)  **[Task]**  

# PCB Check List

### Clock Information

| H-Sync       | V-Sync      | Source    | PCB<br>Number     |
|--------------|-------------|-----------|-------------------|
| 15.556938kHz | 55.161153Hz | DSLogic + | TP-018            |
| 15.556938kHz | 57.612182Hz | DSLogic + | TP-013B<br>TP-015 |

### Crystal Oscillators

| Freq (MHz) | Use                                                            |
|------------|----------------------------------------------------------------|
| 10.00      | M68000 CLK (10 MHz)                                            |
| 28.000     | Z80 CLK (3.5 MHz)<br>YM3812 CLK (3.5 MHz)<br>Pixel CLK (7 MHz) |

**Pixel clock:** 7.00 MHz

**Estimated geometry:**

_**(OutZone)**_

    450 pixels/line  
  
    282 lines/frame  

_**(Tatsujin, Hellfire, Zero Wing)**_

    450 pixels/line  
  
    270 lines/frame  

### Main Components

| Chip                                                                   | Function   |
| -----------------------------------------------------------------------|------------|
| [**Motorola 68000 CPU**](https://en.wikipedia.org/wiki/Motorola_68000) | Main CPU   |
| [**Zilog Z80 CPU**](https://en.wikipedia.org/wiki/Zilog_Z80)           | Sound CPU  |
| [**Yamaha YM3812**](https://en.wikipedia.org/wiki/Yamaha_OPL#OPL2)     | OPL2 Audio |

### Custom Components

| Chip                                             | Function           |
| -------------------------------------------------|--------------------|
| **NEC D65081R077**                               | Custom Gate-Array  |
| **FCU-02**                                       | Sprite RAM         |
| **FDA MN53007T0A / TOAPLAN-02 M70H005 / GXL-02** | Sprite Counter     |
| **BCU-02**                                       | Tile Map Generator | <br>

# Core Features

### Refresh Rate Compatibility Option

- Video timings can be modified if you experience sync issues with CRT or modern displays; this will alter gameplay from it's original state.

| Refresh Rate      | Timing Parameter     | HTOTAL | VTOTAL |
|-------------------|----------------------|--------|--------|
| 15.56kHz / 55.2Hz | TP-018               | 450    | 282    |
| 15.56kHz / 57.6Hz | TP-013B, B90, TP-015 | 450    | 270    |
| 15.73kHz / 59.8Hz | NTSC                 | 445    | 264    |

### P1/P2 Input Swap Option

- There is a toggle to swap inputs from Player 1 to Player 2. This only swaps inputs for the joystick, it does not effect keyboard inputs.

### Audio Options

- There is a toggle to disable playback of OPL2 audio.

### Overclock Options

- There is a toggle to increase the M68000 frequency from 10MHz to 17.5MHz; this will alter gameplay from it's original state.

### Native Y/C Output

- Native Y/C ouput is possible with the [**analog I/O rev 6.1 pcb**](https://github.com/MiSTer-devel/Main_MiSTer/wiki/IO-Board). Using the following cables, [**HD-15 to BNC cable**](https://www.amazon.com/StarTech-com-Coax-RGBHV-Monitor-Cable/dp/B0033AF5Y0/) will transmit Y/C over the green and red lines. Choose an appropriate adapter to feed [**Y/C (S-Video)**](https://www.amazon.com/MEIRIYFA-Splitter-Extension-Monitors-Transmission/dp/B09N19XZJQ) to your display.

### H/V Adjustments

- There are two H/V toggles, H/V-sync positioning adjust and H/V-sync width adjust. Positioning will move the display for centering on CRT display. The sync width adjust can be used to for sync issues (rolling, flagging etc) without modifying the video timings.

### Scandoubler Options

- Additional toggle to enable the scandoubler without changing ini settings and new scanline option for 100% is available, this draws a black line every other frame. Below is an example.

<table><tr><th>Scandoubler Fx</th><th>Scanlines 25%</th><th>Scanlines 50%</th><th>Scanlines 75%</th><th>Scanlines 100%</th><tr><td><br> <p align="center"><img width="160" height="120" src="https://github.com/va7deo/zerowing/assets/32810066/05d03e41-7550-4103-b19e-e67b8d56f2ea"></td><td><br> <p align="center"><img width="160" height="120" src="https://github.com/va7deo/zerowing/assets/32810066/9d435d61-82b6-49d4-a1b7-642fc3ca0b66"></td><td><br> <p align="center"><img width="160" height="120" src="https://github.com/va7deo/zerowing/assets/32810066/6dd54cdd-34d4-4d1e-b9e9-4d8b95954bdd"></td><td><br> <p align="center"><img width="160" height="120" src="https://github.com/va7deo/zerowing/assets/32810066/0b7f8f89-f35d-40ac-afde-16abc633bf01"></td><td><br> <p align="center"><img width="160" height="120" src="https://github.com/va7deo/zerowing/assets/32810066/d0d46729-f19a-4883-a89b-9a302d405b6c"></td></tr></table> <br>

# PCB Information / Control Layout

| Title         | Joystick | Service Menu                                                                                                | Dip Switches                                                                                             | Shared Controls | Dip Default | PCB Information                                                                                                                                                                                                                                                                                                                                                                                                                                                                 |
|---------------|----------|-------------------------------------------------------------------------------------------------------------|----------------------------------------------------------------------------------------------------------|-----------------|-------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| **Tatsujin**  | 8-Way    | [**Service Menu**](https://github.com/va7deo/zerowing/assets/32810066/3cf757be-6514-4700-a2de-9e42723c703e) | [**Dip Sheet**](https://github.com/va7deo/zerowing/assets/32810066/f4745145-a31f-4152-98e1-a6fa315051a4) | No              | **Upright** | To access test mode, press P1 Start when the grid is displayed in "Service Mode". <br><br> To access sound test, press P2 Start when the grid is displayed in "Service Mode". <br><br> Turn the "Service Mode" dipswitch on in game for invulnerability. <br><br> Set the "Dip Switch Display" dipswitch to on in game to pause. <br><br> When the cabinet dipswitch is "Upright", you can use controls from both players.                                                      |
| **Hellfire**  | 8-Way    | [**Service Menu**](https://github.com/va7deo/zerowing/assets/32810066/e262e14f-6224-487d-9fd8-c6cffdca7ffe) | [**Dip Sheet**](https://github.com/va7deo/zerowing/assets/32810066/58c7dd68-05cc-419a-a62e-258a95754679) | Co-Op           | **Upright** | In game, enable the "Invulnerability" dip and press P2 Start to pause; P1 Start to resume. <br><br> When holding P1 Start and P2 Start, this will enable a slower framerate in game. <br><br> When the cabinet dipswitch is "Upright", you can use controls from both players.                                                                                                                                                                                                  |
| **Zero Wing** | 8-Way    | [**Service Menu**](https://github.com/va7deo/zerowing/assets/32810066/f3e6d951-cd02-40fd-a6a9-17db64bf0e94) | [**Dip Sheet**](https://github.com/va7deo/zerowing/assets/32810066/6e9e51fa-c695-480f-9f60-9bc828492f26) | Co-Op           | **Upright** | In game, enable the "Invulnerability" dip and press P2 Start to pause; P1 Start to resume. <br><br> When holding P1 Start and P2 Start, this will enable a slower framerate in game. <br><br> When the cabinet dipswitch is "Upright", you can use controls from both players.                                                                                                                                                                                                  |
| **OutZone**   | 8-Way    | [**Service Menu**](https://github.com/va7deo/zerowing/assets/32810066/8383054b-e7d4-470a-aaef-d6bd6f9dd71c) | [**Dip Sheet**](https://github.com/va7deo/zerowing/assets/32810066/4eec59fe-fc59-42ef-9d47-f55f5428c374) | Co-Op           | **Upright** | In OutZone (Older Set) [outzoneb], set both "Debug" dipswitches to on and reset the game. Hold P2 Down during the boot sequence. <br><br> This enables the CRTC registers to be programmed for a smaller VTOTAL enabling a higher framerate by reducing the edges of the screen. <br><br> This changes the native refresh rate of  OutZone from 55.2Hz to 58.5Hz and the resolution from 240p to 224p. <br><br> It's functional in the core and currently not emulated in mame. |

<br>

- Upright cabinets by default use a **2L3B** control panel layout. Alternatively, they may share a <br>**1L3B** control panel layout and require players to switch their controller method.<br><br>
- If the cabinet type is set to table, the screen inverts for cocktail mode per player and has <br> multiple controls.<br><br>
- Push button 3 may have no function in game, but corresponds to the original hardware and <br> service menu depending on the title.<br><br>

### Keyboard Handler

<br>

- Keyboard inputs mapped to mame defaults for Player 1 / Player 2.

<br>

| Services                                                                                                                                                                                           | Coin/Start                                                                                                                                                                                              |
|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| <table> <tr><th>Functions</th><th>Keymap</th></tr><tr><td>Test</td><td>F2</td></tr><tr><td>Reset</td><td>F3</td></tr><tr><td>Service</td><td>9</td></tr><tr><td>Pause</td><td>P</td></tr> </table> | <table><tr><th>Functions</th><th>Keymap</th><tr><tr><td>P1 Start</td><td>1</td></tr><tr><td>P2 Start</td><td>2</td></tr><tr><td>P1 Coin</td><td>5</td></tr><tr><td>P2 Coin</td><td>6</td></tr> </table> |

| Player 1                                                                                                                                                                                                                                                                                                                                      | Player 2                                                                                                                                                                                                                                                                                                              |
|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| <table> <tr><th>Functions</th><th>Keymap</th></tr><tr><td>P1 Up</td><td>Up</td></tr><tr><td>P1 Down</td><td>Down</td></tr><tr><td>P1 Left</td><td>Left</td></tr><tr><td>P1 Right</td><td>Right</td></tr><tr><td>P1 Bttn 1</td><td>L-CTRL</td></tr><tr><td>P1 Bttn 2</td><td>L-ALT</td></tr><tr><td>P1 Bttn 3</td><td>Space</td></tr> </table> | <table> <tr><th>Functions</th><th>Keymap</th></tr><tr><td>P2 Up</td><td>R</td></tr><tr><td>P2 Down</td><td>F</td></tr><tr><td>P2 Left</td><td>D</td></tr><tr><td>P2 Right</td><td>G</td></tr><tr><td>P2 Bttn 1</td><td>A</td></tr><tr><td>P2 Bttn 2</td><td>S</td></tr><tr><td>P2 Bttn 3</td><td>Q</td></tr> </table> |

# Acknowledgments

Thank you to the following below who loaned hardware used during development:<br>

[**@owlnonymous**](https://twitter.com/owlnonymous) for loaning OutZone (TP-015 Conversion)<br>
[**@cathoderaze**](https://twitter.com/cathoderaze) for loaning Tatsujin (TP-013B)<br>
[**@90s_cyber_thriller**](https://www.instagram.com/90s_cyber_thriller/) for loaning Outzone (TP-018)<br>

# Support

Please consider showing support for this and future projects via [**Darren's Ko-fi**](https://ko-fi.com/darreno) and [**atrac17's Patreon**](https://www.patreon.com/atrac17). While it isn't necessary, it's greatly appreciated.<br>

# Licensing

Contact the author for special licensing needs. Otherwise follow the GPLv2 license attached.
