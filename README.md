
# Toaplan Version 1 FPGA Implemenation for [MiSTerFPGA](https://github.com/MiSTer-devel/Main_MiSTer/wiki)

FPGA compatible core for Toaplan Version 1 arcade hardware for MiSTerFPGA written by Darren Olafson. This core is based on Zero Wing and will be verified against physical hardware (Out Zone/Zero Wing Conversion). 

This FPGA compatible core is in active development with assistance from [**𝕓𝕝𝕒𝕔𝕜𝕨𝕚𝕟𝕖**](https://github.com/blackwine) and [**atrac17**](https://github.com/atrac17). Physical hardware on loan from [**@owlnonymous**](https://twitter.com/owlnonymous).

![Toaplan_logo_shadow_small](https://user-images.githubusercontent.com/32810066/151543842-5f7380a4-9b29-472d-bc03-8cc04a579cf2.png)

## Toaplan Version 1 Hardware

Game                |  Status | Released
--------------------|---------|---------
[**Zero Wing**](https://en.wikipedia.org/wiki/Zero_Wing) | Implemented | **Yes**
[**Out Zone (Zero Wing TP-015 PCB conversion)**](https://en.wikipedia.org/wiki/Out_Zone) | Implemented | **Yes**
[**Out Zone**](https://en.wikipedia.org/wiki/Out_Zone) | Ongoing | No
[**Fire Shark**](https://en.wikipedia.org/wiki/Fire_Shark) | Ongoing | No
[**Hellfire**](https://en.wikipedia.org/wiki/Hellfire_%28video_game%29) | Ongoing | No
[**Truxton**](https://en.wikipedia.org/wiki/Truxton_%28video_game%29) | Ongoing | No
[**Vimana**](https://en.wikipedia.org/wiki/Vimana_%28video_game%29) | Ongoing | No
[**Rally Bike**](https://en.wikipedia.org/wiki/Rally_Bike) | Ongoing | No
[**Demon's World**](https://en.wikipedia.org/wiki/Demon%27s_World) | FPGA Implementation slatted by [**Jotego**](https://github.com/jotego) | No


# Known Issues

-Screen Flip/Cocktail Mode has yet to be implemented  
-Exiting the service menu hangs on a sound error  
-Clock domains need to be verified  
-Sprites disappearing when they touch the first scanline or first pixel of a scanline (Out Zone)  
-OPL2 sound implementation (W.I.P)  

# PCB Check List

FPGA core timings will be taken from Out Zone (Zero Wing TP-015 PCB conversion) on loan courtesy of [**@owlnonymous**](https://twitter.com/owlnonymous). More information to follow.

# Licensing

Contact the author for special licensing needs. Otherwise follow the GPLv2 license attached.