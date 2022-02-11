

# Toaplan Version 1 FPGA Implemenation for [MiSTerFPGA](https://github.com/MiSTer-devel/Main_MiSTer/wiki)

FPGA compatible core for Toaplan Version 1 arcade hardware for MiSTerFPGA written by Darren Olafson. This core is based on Zero Wing and will be verified against physical hardware (Out Zone/Zero Wing Conversion). 

This FPGA compatible core is in active development with assistance from [**𝕓𝕝𝕒𝕔𝕜𝕨𝕚𝕟𝕖**](https://github.com/blackwine) and [**atrac17**](https://github.com/atrac17). Physical hardware on loan from [**@owlnonymous**](https://twitter.com/owlnonymous).

![Toaplan_logo_shadow_small](https://user-images.githubusercontent.com/32810066/151543842-5f7380a4-9b29-472d-bc03-8cc04a579cf2.png)

## Toaplan Version 1 Hardware

Game                |  Status | Released
--------------------|---------|---------
[**Zero Wing**](https://en.wikipedia.org/wiki/Zero_Wing) | Implemented | **Pending**
[**Out Zone (Zero Wing TP-015 PCB conversion)**](https://en.wikipedia.org/wiki/Out_Zone) | Implemented | **Pending**
[**Out Zone**](https://en.wikipedia.org/wiki/Out_Zone) | Implemented | **Pending**
[**Hellfire**](https://en.wikipedia.org/wiki/Hellfire_%28video_game%29) | Implemented | **Pending**
[**Truxton**](https://en.wikipedia.org/wiki/Truxton_%28video_game%29) | Implemented | **Pending**
[**Vimana**](https://en.wikipedia.org/wiki/Vimana_%28video_game%29) | Ongoing | No
[**Fire Shark**](https://en.wikipedia.org/wiki/Fire_Shark) | **W.I.P** | No
[**Rally Bike**](https://en.wikipedia.org/wiki/Rally_Bike) | Ongoing | No
[**Demon's World**](https://en.wikipedia.org/wiki/Demon%27s_World) | FPGA Implementation slated by [**Jotego**](https://github.com/jotego) | **N/A**


# Known Issues

-Screen Flip/Cocktail Mode has yet to be implemented **[Implemented]**  
-Exiting the service menu hangs on a sound error  
-Clock domains need to be verified (W.I.P)  
-Sprites disappearing when they touch the first scanline or first pixel of a scanline (Out Zone) **[Corrected]**  
-OPL2 sound implementation (W.I.P)  
-HD647180X sound implementation (Fire Shark / Vimana)  

# PCB Check List

FPGA core timings will be taken from Out Zone (Zero Wing TP-015 PCB conversion) on loan courtesy of [**@owlnonymous**](https://twitter.com/owlnonymous). More information to follow.

### Clock Information (Out Zone TP-015 PCB conversion)

H-Sync   | V-Sync   | Source    | Title 
---------|----------|-----------|-------
15.55kHz | 55.16Hz  | OSSC/RT5X | Out Zone, Rally Bike, Demon's World
15.55kHz | 57.61Hz  | OSSC/RT5X | All Others

### Crystal Oscillators

Location | Freq (MHz) | Use
---------|------------|-------
X1       | 10.00      | M68k
R1       | 28.000     | Video/Sound

**Pixel clock:** 12.6900 MHz

**Estimated geometry:**

    450 pixels/line  (Out Zone, Rally Bike, Demon's World)
    282 lines/frame  (Out Zone, Rally Bike, Demon's World)
  
    450 pixels/line  (All Others)
    282 lines/frame  (All Others)

# Licensing

Contact the author for special licensing needs. Otherwise follow the GPLv2 license attached.
