
# Toaplan Version 1 FPGA Implemenation for [MiSTerFPGA](https://github.com/MiSTer-devel/Main_MiSTer/wiki)

FPGA compatible core for Toaplan Version 1 arcade hardware for MiSTerFPGA written by Darren Olafson. This core will be based off of Zero Wing. This FPGA compatible core is in active development.

![Toaplan_logo_shadow_small](https://user-images.githubusercontent.com/32810066/151543842-5f7380a4-9b29-472d-bc03-8cc04a579cf2.png)

## Toaplan Version 1 Hardware

Game                |  Status | Released
--------------------|---------|---------
Zero Wing | Implemented | Yes
Out Zone (Zero Wing TP-015 PCB conversion) | Implemented | Yes
Out Zone | Ongoing Implementation | No
Fire Shark | Ongoing Implementation | No
Hellfire | Ongoing Implementation | No
Truxton | Ongoing Implementation | No
Vimana | Ongoing Implementation | No
Rally Bike | Ongoing Implementation | No
Demon's World | FPGA Implementation planned by [Jotego](https://github.com/jotego) | No

# Known Issues

-Screen Flip/Cocktail Mode has yet to be implemented
-Exiting the service menu hangs on a sound error
-Clock domains need to be verified
-Sprites disappearing when they touch the first scanline or first pixel of a scanline (Out Zone)
-OPL2 sound implementation (W.I.P)

# PCB Check List

FPGA core timings will be taken from Out Zone (Zero Wing TP-015 PCB conversion) on loan courtesy of [@owlnonymous](https://twitter.com/owlnonymous). More information to follow.

# Licensing

Contact the author for special licensing needs. Otherwise follow the GPLv2 license attached.