


# Toaplan Version 1 FPGA Implemenation for [MiSTerFPGA](https://github.com/MiSTer-devel/Main_MiSTer/wiki)

FPGA compatible core for Toaplan Version 1 arcade hardware for MiSTerFPGA written by Darren Olafson. This core is based on Zero Wing/Out Zone hardware and will be verified against a Out Zone TP-015 PCB. 

This FPGA compatible core is in active development with assistance from [**𝕓𝕝𝕒𝕔𝕜𝕨𝕚𝕟𝕖**](https://github.com/blackwine) and [**atrac17**](https://github.com/atrac17).

![Toaplan_logo_shadow_small](https://user-images.githubusercontent.com/32810066/151543842-5f7380a4-9b29-472d-bc03-8cc04a579cf2.png)

## Toaplan Version 1 Hardware

| Title | Status | Beta Release |
|------|---------|--------------|
[**Truxton**](https://en.wikipedia.org/wiki/Truxton_%28video_game%29) | Implemented | 20220304 |
[**Hellfire**](https://en.wikipedia.org/wiki/Hellfire_%28video_game%29) | Implemented | 20220304 |
[**Zero Wing**](https://en.wikipedia.org/wiki/Zero_Wing) | Implemented | 20220304 |
[**Out Zone**](https://en.wikipedia.org/wiki/Out_Zone) | Implemented | 20220304 |
[**Fire Shark**](https://en.wikipedia.org/wiki/Fire_Shark) | **W.I.P** | No |
[**Vimana**](https://en.wikipedia.org/wiki/Vimana_%28video_game%29) | Ongoing | No |
[**Rally Bike**](https://en.wikipedia.org/wiki/Rally_Bike) | Ongoing | No |
[**Demon's World**](https://en.wikipedia.org/wiki/Demon%27s_World) | Implementation slated by [**Jotego**](https://github.com/jotego) | N/A


# Known Issues

-Clock domains need to be verified  
-OPL2 sound implementation  
-HD647180X sound implementation  

# PCB Check List

FPGA core timings taken from Out Zone (Zero Wing TP-015 PCB conversion) on loan courtesy of [**@owlnonymous**](https://twitter.com/owlnonymous).

### Clock Information (Out Zone TP-015 PCB conversion)

H-Sync   | V-Sync   | Source    | Title 
---------|----------|-----------|-------
15.56kHz | 55.16Hz  | OSSC/RT5X | Out Zone, Rally Bike, Demon's World
15.56kHz | 57.61Hz  | OSSC/RT5X | All Others

### Crystal Oscillators

Location | Freq (MHz) | Use
---------|------------|-------
X1       | 10.00      | M68k
R1       | 28.000     | Video/Sound

**Pixel clock:** 7.00 MHz

**Estimated geometry:**

    450 pixels/line  (Out Zone, Rally Bike, Demon's World)
    282 lines/frame  (Out Zone, Rally Bike, Demon's World)
  
    450 pixels/line  (All Others)
    270 lines/frame  (All Others)

# Licensing

Contact the author for special licensing needs. Otherwise follow the GPLv2 license attached.
