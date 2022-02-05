///----------------------------------------------------------------------------
//
//  Copyright 2021 Darren Olafson
//
//  MiSTer Copyright (C) 2017 Sorgelig
//
//  This program is free software; you can redistribute it and/or modify it
//  under the terms of the GNU General Public License as published by the Free
//  Software Foundation; either version 2 of the License, or (at your option)
//  any later version.
//
//  This program is distributed in the hope that it will be useful, but WITHOUT
//  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
//  FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
//  more details.
//
//  You should have received a copy of the GNU General Public License along
//  with this program; if not, write to the Free Software Foundation, Inc.,
//  51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
//
//----------------------------------------------------------------------------

`default_nettype none

module emu
(
    //Master input clock
    input         CLK_50M,

    //Async reset from top-level module.
    //Can be used as initial reset.
    input         RESET,

    //Must be passed to hps_io module
    inout  [47:0] HPS_BUS,

    //Base video clock. Usually equals to CLK_SYS.
    output        CLK_VIDEO,

    //Multiple resolutions are supported using different CE_PIXEL rates.
    //Must be based on CLK_VIDEO
    output        CE_PIXEL,

    //Video aspect ratio for HDMI. Most retro systems have ratio 4:3.
    //if VIDEO_ARX[12] or VIDEO_ARY[12] is set then [11:0] contains scaled size instead of aspect ratio.
    output [12:0] VIDEO_ARX,
    output [12:0] VIDEO_ARY,

    output  [7:0] VGA_R,
    output  [7:0] VGA_G,
    output  [7:0] VGA_B,
    output        VGA_HS,
    output        VGA_VS,
    output        VGA_DE,    // = ~(VBlank | HBlank)
    output        VGA_F1,
    output [1:0]  VGA_SL,
    output        VGA_SCALER, // Force VGA scaler

    input  [11:0] HDMI_WIDTH,
    input  [11:0] HDMI_HEIGHT,
    output        HDMI_FREEZE,

`ifdef MISTER_FB
    // Use framebuffer in DDRAM (USE_FB=1 in qsf)
    // FB_FORMAT:
    //    [2:0] : 011=8bpp(palette) 100=16bpp 101=24bpp 110=32bpp
    //    [3]   : 0=16bits 565 1=16bits 1555
    //    [4]   : 0=RGB  1=BGR (for 16/24/32 modes)
    //
    // FB_STRIDE either 0 (rounded to 256 bytes) or multiple of pixel size (in bytes)
    output        FB_EN,
    output  [4:0] FB_FORMAT,
    output [11:0] FB_WIDTH,
    output [11:0] FB_HEIGHT,
    output [31:0] FB_BASE,
    output [13:0] FB_STRIDE,
    input         FB_VBL,
    input         FB_LL,
    output        FB_FORCE_BLANK,

`ifdef MISTER_FB_PALETTE
    // Palette control for 8bit modes.
    // Ignored for other video modes.
    output        FB_PAL_CLK,
    output  [7:0] FB_PAL_ADDR,
    output [23:0] FB_PAL_DOUT,
    input  [23:0] FB_PAL_DIN,
    output        FB_PAL_WR,
`endif
`endif

    output        LED_USER,  // 1 - ON, 0 - OFF.

    // b[1]: 0 - LED status is system status OR'd with b[0]
    //       1 - LED status is controled solely by b[0]
    // hint: supply 2'b00 to let the system control the LED.
    output  [1:0] LED_POWER,
    output  [1:0] LED_DISK,

    // I/O board button press simulation (active high)
    // b[1]: user button
    // b[0]: osd button
    output  [1:0] BUTTONS,

    input         CLK_AUDIO, // 24.576 MHz
    output [15:0] AUDIO_L,
    output [15:0] AUDIO_R,
    output        AUDIO_S,   // 1 - signed audio samples, 0 - unsigned
    output  [1:0] AUDIO_MIX, // 0 - no mix, 1 - 25%, 2 - 50%, 3 - 100% (mono)

    //ADC
    inout   [3:0] ADC_BUS,

    //SD-SPI
    output        SD_SCK,
    output        SD_MOSI,
    input         SD_MISO,
    output        SD_CS,
    input         SD_CD,

    //High latency DDR3 RAM interface
    //Use for non-critical time purposes
    output        DDRAM_CLK,
    input         DDRAM_BUSY,
    output  [7:0] DDRAM_BURSTCNT,
    output [28:0] DDRAM_ADDR,
    input  [63:0] DDRAM_DOUT,
    input         DDRAM_DOUT_READY,
    output        DDRAM_RD,
    output [63:0] DDRAM_DIN,
    output  [7:0] DDRAM_BE,
    output        DDRAM_WE,

    //SDRAM interface with lower latency
    output        SDRAM_CLK,
    output        SDRAM_CKE,
    output [12:0] SDRAM_A,
    output  [1:0] SDRAM_BA,
    inout  [15:0] SDRAM_DQ,
    output        SDRAM_DQML,
    output        SDRAM_DQMH,
    output        SDRAM_nCS,
    output        SDRAM_nCAS,
    output        SDRAM_nRAS,
    output        SDRAM_nWE,

`ifdef MISTER_DUAL_SDRAM
    //Secondary SDRAM
    //Set all output SDRAM_* signals to Z ASAP if SDRAM2_EN is 0
    input         SDRAM2_EN,
    output        SDRAM2_CLK,
    output [12:0] SDRAM2_A,
    output  [1:0] SDRAM2_BA,
    inout  [15:0] SDRAM2_DQ,
    output        SDRAM2_nCS,
    output        SDRAM2_nCAS,
    output        SDRAM2_nRAS,
    output        SDRAM2_nWE,
`endif

    input         UART_CTS,
    output        UART_RTS,
    input         UART_RXD,
    output        UART_TXD,
    output        UART_DTR,
    input         UART_DSR,

    // Open-drain User port.
    // 0 - D+/RX
    // 1 - D-/TX
    // 2..6 - USR2..USR6
    // Set USER_OUT to 1 to read from USER_IN.
    input   [6:0] USER_IN,
    output  [6:0] USER_OUT,

    input         OSD_STATUS
);


assign {UART_RTS, UART_TXD, UART_DTR} = 0;

assign VGA_F1    = 0;
assign VGA_SCALER= 0;
assign HDMI_FREEZE = 0;

assign USER_OUT  = '1;
assign AUDIO_MIX = 0;
//assign LED_USER  = ioctl_download ;
assign LED_DISK  = 0;
assign LED_POWER = 0;
assign BUTTONS = 0;

wire [1:0] aspect_ratio = status[2:1];
wire orientation = ~status[3];
wire [2:0] scan_lines = status[6:4];

// Status Bit Map:
//              Upper                          Lower
// 0         1         2         3          4         5         6
// 01234567890123456789012345678901 23456789012345678901234567890123
// 0123456789ABCDEFGHIJKLMNOPQRSTUV 0123456789ABCDEFGHIJKLMNOPQRSTUV

assign VIDEO_ARX = (!aspect_ratio) ? (orientation  ? 8'd4 : 8'd3) : (aspect_ratio - 1'd1);
assign VIDEO_ARY = (!aspect_ratio) ? (orientation  ? 8'd3 : 8'd4) : 12'd0;

`include "build_id.v" 
localparam CONF_STR = {
    "Zero Wing;;",
    "-;",
    "P1,Video Settings;",
    "P1-;",
    "P1O12,Aspect ratio,Original,Full Screen,[ARC1],[ARC2];",
    "P1O3,Orientation,Horz,Vert;",
    "P1-;",
    "P1O46,Scandoubler Fx,None,HQ2x,CRT 25%,CRT 50%,CRT 75%;",
    "P1OOR,H-sync Adjust,0,1,2,3,4,5,6,7,-8,-7,-6,-5,-4,-3,-2,-1;",
    "P1OSV,V-sync Adjust,0,1,2,3,4,5,6,7,-8,-7,-6,-5,-4,-3,-2,-1;",
    "P1-;",
    //"P1OB,Flip Screen,Off,On;",

    "DIP;",
    "-;",

    "R0,Reset;",
    "J1,Button 1,Button 2,Button 3,Start,Coin,Pause;",
    "jn,A,B,X,R,L,Start;",	       // name mapping
    "V,v",`BUILD_DATE
};

// CLOCKS

wire pll_locked;

wire  clk_sys;
wire  clk_70M;

reg  clk_7M;
reg  clk_10M;   // 20MHz.  68k core needs twice freq
reg  clk_14M;

assign    SDRAM_CLK = clk_70M;

pll pll
(
    .refclk(CLK_50M),
    .rst(0),
    .outclk_0(clk_sys),     // 70
    .outclk_1(clk_70M),     
    .locked(pll_locked)
);

reg [3:0] clk10_count;
reg [3:0] clk7_count;
reg [3:0] clk14_count;

always @ (posedge clk_sys ) begin

    clk_10M <= 0;
    case (clk10_count)
        1: clk_10M <= 1;
        3: clk_10M <= 1;
    endcase
    
    if ( clk10_count == 6 ) begin
        clk10_count <= 0;
    end else begin
        clk10_count <= clk10_count + 1;
    end
    
    clk_7M <= ( clk7_count == 0);
    if ( clk7_count == 9 ) begin
        clk7_count <= 0;
    end else begin
        clk7_count <= clk7_count + 1;
    end
    
    clk_14M <= ( clk14_count == 0);
    if ( clk14_count == 4 ) begin
        clk14_count <= 0;
    end else begin
        clk14_count <= clk14_count + 1;
    end

end

// 8 dip switches of 8 bits
reg [7:0] sw[8];
always @(posedge clk_sys) begin
    if (ioctl_wr && (ioctl_index==254) && !ioctl_addr[24:3]) begin
        sw[ioctl_addr[2:0]] <= ioctl_dout;
    end
end

// Status bits
wire [31:0] status;

// Video settings
wire        forced_scandoubler;
wire        direct_video;

wire [3:0] hs_offset = status[27:24];
wire [3:0] vs_offset = status[31:28];

wire [9:0] sprite_adj_x = 0;
wire [9:0] sprite_adj_y = 0;

// Controls
wire  [1:0] buttons;
wire [15:0] joy0, joy1;
wire [10:0] ps2_key;

wire [21:0] gamma_bus;

wire       p1_up      = joy0[3] | key_p1_up;
wire       p1_down    = joy0[2] | key_p1_down;
wire       p1_left    = joy0[1] | key_p1_left;
wire       p1_right   = joy0[0] | key_p1_right;
wire [2:0] p1_buttons = joy0[6:4] | {key_p1_c, key_p1_b, key_p1_a};

wire       p2_up      = joy1[3] | key_p2_up;
wire       p2_down    = joy1[2] | key_p2_down;
wire       p2_left    = joy1[1] | key_p2_left;
wire       p2_right   = joy1[0] | key_p2_right;
wire [2:0] p2_buttons = joy1[6:4] | {key_p2_c, key_p2_b, key_p2_a};

wire p1_start = joy0[7] | key_p1_start;
wire p2_start = joy1[7] | key_p2_start;
wire p1_coin  = joy0[8] | key_p1_coin;
wire p2_coin  = joy1[8] | key_p2_coin;
wire b_pause  = joy0[9] | joy1[9];

// Keyboard handler

wire key_p1_start, key_p2_start, key_p1_coin, key_p2_coin;
wire key_test, key_reset, key_service;

wire key_p1_up, key_p1_left, key_p1_down, key_p1_right, key_p1_a, key_p1_b, key_p1_c;
wire key_p2_up, key_p2_left, key_p2_down, key_p2_right, key_p2_a, key_p2_b, key_p2_c;

wire pressed = ps2_key[9];

always @(posedge clk_sys) begin
	reg old_state;

	old_state <= ps2_key[10];
	if(old_state ^ ps2_key[10]) begin
		casex(ps2_key[8:0])
			'h016: key_p1_start <= pressed; // 1
			'h01e: key_p2_start <= pressed; // 2
			'h02E: key_p1_coin  <= pressed; // 5
			'h036: key_p2_coin  <= pressed; // 6
			'h006: key_test     <= pressed; // F2
			'h004: key_reset    <= pressed; // F3
			'h046: key_service  <= pressed; // 9

			'hX75: key_p1_up    <= pressed; // up
			'hX72: key_p1_down  <= pressed; // down
			'hX6b: key_p1_left  <= pressed; // left
			'hX74: key_p1_right <= pressed; // right
			'h014: key_p1_a     <= pressed; // lctrl
			'h011: key_p1_b     <= pressed; // lalt
			'h029: key_p1_c     <= pressed; // space

			'h02d: key_p2_up    <= pressed; // r
			'h02b: key_p2_down  <= pressed; // f
			'h023: key_p2_left  <= pressed; // d
			'h034: key_p2_right <= pressed; // g
			'h01c: key_p2_a     <= pressed; // a
			'h01b: key_p2_b     <= pressed; // s
			'h015: key_p2_c     <= pressed; // q
		endcase
	end
end

// PAUSE SYSTEM
reg        pause;                                    // Pause signal (active-high)
reg        pause_toggle = 1'b0;                    // User paused (active-high)
reg [31:0] pause_timer;                            // Time since pause
reg [31:0] pause_timer_dim = 31'h11E1A300;    // Time until screen dim (10 seconds @ 48Mhz)
reg        dim_video = 1'b0;                        // Dim video output (active-high)

// Pause when highscore module requires access, user has pressed pause, or OSD is open and option is set
assign pause =  pause_toggle | (OSD_STATUS && ~status[7]);
assign dim_video = (pause_timer >= pause_timer_dim);

reg [1:0] adj_layer ;
reg [15:0] scroll_adj_x [3:0];
reg [15:0] scroll_adj_y [3:0];
reg layer_en [3:0];

reg old_pause;

always @(posedge clk_sys) begin
    old_pause <= b_pause;
    if (~old_pause & b_pause) begin
        pause_toggle <= ~pause_toggle;
    end
    if (pause_toggle) begin
        if (pause_timer < pause_timer_dim)
        begin
            pause_timer <= pause_timer + 1'b1;
        end
    end    else begin
        pause_timer <= 1'b0;
    end
end

wire        ioctl_download;
wire        ioctl_upload;
wire        ioctl_wr;
wire [15:0]    ioctl_index;
wire [26:0] ioctl_addr;
wire [15:0] ioctl_dout;
wire [15:0] ioctl_din;
wire        ioctl_wait;

//

hps_io #(.CONF_STR(CONF_STR)) hps_io
(
    .clk_sys(clk_sys),
    .HPS_BUS(HPS_BUS),

    .buttons(buttons),
    .ps2_key(ps2_key),
    .status(status),
    .status_menumask(direct_video),
    .forced_scandoubler(forced_scandoubler),
    .gamma_bus(gamma_bus),
    .direct_video(direct_video),

    .ioctl_download(ioctl_download),
    .ioctl_upload(ioctl_upload),
    .ioctl_wr(ioctl_wr),
    .ioctl_addr(ioctl_addr),
    .ioctl_dout(ioctl_dout),
    .ioctl_din(ioctl_din),
    .ioctl_index(ioctl_index),
    .ioctl_wait(ioctl_wait),

    .joystick_0(joy0),
    .joystick_1(joy1)
);




reg ce_pix;

wire hbl;
wire vbl;

wire hsync;
wire vsync;

wire [8:0] hc;
wire [8:0] vc;

wire no_rotate = orientation | direct_video;
wire rotate_ccw = 1;
wire flip = 0;
screen_rotate screen_rotate (.*);

arcade_video #(320,24) arcade_video
(
        .*,

        .clk_video(clk_sys),
        .ce_pix(clk_7M),

        .RGB_in(rgb_out[23:0]),

        .HBlank(hbl),
        .VBlank(vbl),
        .HSync(hsync),
        .VSync(vsync),

        .fx(scan_lines)
);

wire reset;
assign reset = RESET | status[0] | (ioctl_download & !ioctl_index) | buttons[1] | key_reset;

wire vid_clk = clk_7M;

video_timing video_timing (
    .clk( vid_clk ),       // pixel clock
    .reset(reset),      // reset

    .hs_offset(hs_offset),
    .vs_offset(vs_offset),

    .hc(hc),  
    .vc(vc),  

    .hbl_delay(hbl),
    .vbl(vbl),
    
    .hsync(hsync),     
    .vsync(vsync)   
    );


reg  [23:0] rgb_out;

// ===============================================================
// 68000 CPU
// ===============================================================

// clock generation
reg  fx68_phi1 = 0; 
wire fx68_phi2 = !fx68_phi1;

// phases for 68k clock
always @(posedge clk_sys) begin
    if ( clk_10M == 1 ) begin
        fx68_phi1 <= ~fx68_phi1; 
    end
end

// CPU outputs
wire cpu_rw         ;    // Read = 1, Write = 0
wire cpu_as_n       ;    // Address strobe
wire cpu_lds_n      ;    // Lower byte strobe
wire cpu_uds_n      ;    // Upper byte strobe
wire cpu_E;         
wire vma_n          ;    // Valid peripheral memory address
wire [2:0]cpu_fc    ;    // Processor state
wire cpu_reset_n_o  ;    // Reset output signal
wire cpu_halted_n   ;    // Halt output
wire bg_n           ;    // Bus grant

// CPU busses
wire [15:0] cpu_dout       ;
wire [23:0] cpu_a          ;
reg  [15:0] cpu_din        ;    

// CPU inputs
wire berr_n = 1'b1;            // Bus error (never error)
reg  dtack_n ;// = !vpa_n;         // Data transfer ack (always ready)
wire vpa_n;                    // Valid peripheral address detected

reg  cpu_br_n = 1'b1;          // Bus request
reg  bgack_n = 1'b1;           // Bus grant ack
reg  ipl0_n = 1'b1 ;            // Interrupt request signals
reg  ipl1_n = 1'b1;
reg  ipl2_n ;//= 1'b1;

assign cpu_a[0] = 0;           // odd memory address should cause cpu exception

     
fx68k fx68k (
    // input
    .clk( clk_10M ),
    .enPhi1(fx68_phi1),
    .enPhi2(fx68_phi2),
    .extReset(reset),
    .pwrUp(reset),

    // output
    .eRWn(cpu_rw),
    .ASn( cpu_as_n),
    .LDSn(cpu_lds_n),
    .UDSn(cpu_uds_n),
//    .E(cpu_E),
    .VMAn(vma_n),
    .FC0(cpu_fc[0]),
    .FC1(cpu_fc[1]),
    .FC2(cpu_fc[2]),
    .BGn(bg_n),
    .oRESETn(cpu_reset_n_o),
    .oHALTEDn(cpu_halted_n),

    // input
    .VPAn(cpu_as_n & ipl2_n),       // autovector int ack needs VPA low and DTACK high
    .DTACKn(dtack_n & ipl2_n),     // 
    .BERRn(berr_n), 
    .BRn(cpu_br_n),  
    .BGACKn(bgack_n),
    
    .IPL0n(ipl0_n),
    .IPL1n(ipl1_n),
    .IPL2n(ipl2_n),

    // busses
    .iEdb(cpu_din),
    .oEdb(cpu_dout),
    .eab(cpu_a[23:1])
);

always @ (posedge clk_sys) begin

    // tell 68k to wait for valid data. 0=ready 1=wait
    // always ack when it's not program rom
    dtack_n <= prog_rom_cs ? !prog_rom_data_valid : 0; 

// select cpu data input based on what is active 
    cpu_din <= prog_rom_cs ? prog_rom_data :
        ram_cs ? ram_dout :
        tile_palette_cs ?  tile_palette_cpu_dout :
        sprite_palette_cs ?  sprite_palette_cpu_dout :
        shared_ram_cs ? cpu_shared_dout :
        tile_ofs_cs ? curr_tile_ofs :  
        sprite_ofs_cs ? curr_sprite_ofs :  
        tile_attr_cs ? cpu_tile_dout_attr :
        tile_num_cs ? cpu_tile_dout_num :
        sprite_0_cs ? sprite_0_dout :
        sprite_1_cs ? sprite_1_dout :
        sprite_2_cs ? sprite_2_dout :
        sprite_3_cs ? sprite_3_dout :
        sprite_size_cs ? sprite_size_cpu_dout :
        frame_done_cs ? { 16 { vbl } } : // get vblank state
        int_en_cs ? 16'hffff :
        16'd0;
        

end  

wire [15:0] cpu_shared_dout;
wire [7:0] z80_shared_dout;
reg [15:0] z80_a;

wire [15:0] z80_addr;
reg  [7:0] z80_din;
wire [7:0] z80_dout;
wire z80_wr_n;
wire z80_rd_n;


wire IORQ_n;
wire MREQ_n;

wire z80_halt_n;
reg z80_wait_n;
reg z80_int;


always @ (posedge clk_sys) begin
    if ( reset == 1 ) begin
        z80_wait_n <= 0;
        sound_wr <= 0 ;
    end else if ( clk_7M == 1 ) begin

        z80_wait_n <= 1;
        
        if ( ioctl_download | ( z80_rd_n == 0 && sound_rom_1_data_valid == 0 && sound_rom_1_cs == 1 ) ) begin
            // wait if rom is selected and data is not yet available
            z80_wait_n <= 0;
        end 

        if ( z80_rd_n == 0 ) begin 
            if ( sound_rom_1_cs ) begin
                if ( sound_rom_1_data_valid ) begin
                    z80_din <= sound_rom_1_data;
                end else begin
                    z80_wait_n <= 0;
                end
            end else if ( sound_ram_1_cs ) begin
                z80_din <= z80_shared_dout;
            end else if ( z80_p1_cs ) begin
                z80_din <= { 1'b0, p1_buttons, p1_right, p1_left, p1_down, p1_up };
            end else if ( z80_p2_cs ) begin
                z80_din <= { 1'b0, p2_buttons, p2_right, p2_left, p2_down, p2_up };
            end else if ( z80_dswa_cs ) begin
                z80_din <= sw[0];
            end else if ( z80_dswb_cs ) begin
                z80_din <= sw[1];
            end else if ( z80_tjump_cs ) begin
                z80_din <= sw[3];
            end else if ( z80_system_cs ) begin
                z80_din <= { 1'b0, p2_start, p1_start, p2_coin, p1_coin, 1'b0, 1'b0, key_service };
            end else if ( z80_sound0_cs ) begin
                z80_din <= opl_dout;
            end else begin
                z80_din <= 8'h00;
            end
        end
        
        sound_wr <= 0 ;
        if ( z80_wr_n == 0 ) begin 
            if ( z80_sound0_cs | z80_sound1_cs ) begin    
                sound_data  <= z80_dout;
                sound_addr <= { 1'b0, z80_sound1_cs }; // opl3
//                sound_addr <= z80_sound1_cs ;  // opl2 is single bit address
                sound_wr <= 1;
            end
        end

    end
end

always @ (posedge clk_7M ) begin
    z80_int <= ( vc[7] == 1 && hc[8:7] == 3 ) ;
end

reg  [1:0] sound_addr ;
reg  [7:0] sound_data ;
reg sound_wr;

wire [7:0] opl_dout;
wire opl_irq_n;

//wire [15:0] sample_from_opl_l;
//wire [15:0] sample_from_opl_r;

//reg [7:0] count_1us;
//always @ (posedge clk_sys) begin
//    // every 70 clocks @ 70MHz
//    if ( count_1us == 69 ) begin
//        count_1us <= 0;
//    end else begin
//        count_1us <= count_1us + 1;
//    end
//end
//
//wire ce_1us = ( count_1us == 0 );

assign AUDIO_S = 1'b1 ;

opl3_intf opl
(
    .clk(clk_7M),
    .clk_opl(clk_14M),
    .rst_n(~reset),

    .irq_n(opl_irq_n),

    .addr(sound_addr),
    .din(sound_data),
    .dout(opl_dout),
    .we(sound_wr),
    .rd(z80_sound0_cs & ~z80_rd_n ),

    .sample_l(AUDIO_L),
    .sample_r(AUDIO_R)
);

  
T80pa u_cpu(
    .RESET_n    ( ~reset ),
    .CLK        ( clk_7M ),
    .CEN_p      ( 1'b1 ),     
    .CEN_n      ( 1'b1 ),
    .WAIT_n     ( z80_wait_n ), // don't wait if data is valid or rom access isn't selected
    .INT_n      ( opl_irq_n ),  // opl timer
    .NMI_n      ( 1'b1 ),
    .BUSRQ_n    ( 1'b1 ),
    .RD_n       ( z80_rd_n ),
    .WR_n       ( z80_wr_n ),
    .A          ( z80_addr ),
    .DI         ( z80_din  ),
    .DO         ( z80_dout ),
    // unused
    .DIRSET     ( 1'b0     ),
    .DIR        ( 212'b0   ),
    .OUT0       ( 1'b0     ),
    .RFSH_n     (),
    .IORQ_n     ( IORQ_n ),
    .M1_n       (),
    .BUSAK_n    (),
    .HALT_n     ( z80_halt_n ),
    .MREQ_n     ( MREQ_n ),
    .Stop       (),
    .REG        ()
);

// Chip select mux
wire prog_rom_cs;
wire scroll_ofs_x_cs;
wire scroll_ofs_y_cs;
wire ram_cs;
wire vblank_cs;
wire int_en_cs;
wire tile_ofs_cs;
wire tile_attr_cs;
wire tile_num_cs;
wire scroll_cs;
wire shared_ram_cs;
wire frame_done_cs; // word
wire tile_palette_cs;
wire sprite_palette_cs ;
wire sprite_ofs_cs;
wire sprite_cs; // *** offset needs to be auto-incremented
wire sprite_size_cs; // *** offset needs to be auto-incremented

wire z80_p1_cs;
wire z80_p2_cs;
wire z80_dswa_cs;
wire z80_dswb_cs;
wire z80_system_cs;
wire z80_tjump_cs;
wire z80_sound0_cs;
wire z80_sound1_cs;


// Select PCB Title and set chip select lines
reg   [7:0] pcb;
wire        tile_priority_type;
wire [15:0] scroll_y_offset;

always @(posedge clk_sys)
    if (ioctl_wr && (ioctl_index==1))
        pcb <= ioctl_dout;

chip_select cs (.*);

wire sprite_0_cs      = ( curr_sprite_ofs[1:0] == 2'b00 ) & sprite_cs ;
wire sprite_1_cs      = ( curr_sprite_ofs[1:0] == 2'b01 ) & sprite_cs ;
wire sprite_2_cs      = ( curr_sprite_ofs[1:0] == 2'b10 ) & sprite_cs ;
wire sprite_3_cs      = ( curr_sprite_ofs[1:0] == 2'b11 ) & sprite_cs ;

wire sound_rom_1_cs   = ( MREQ_n == 0 && z80_addr <= 16'h7fff )  ;
wire sound_ram_1_cs   = ( MREQ_n == 0 && z80_addr >= 16'h8000 && z80_addr <= 16'h87ff ) ;

reg int_en ;
reg int_ack ;

reg [1:0] vbl_sr;
// vblank interrupt on rising vbl 
always @ (posedge clk_sys ) begin
    if ( reset == 1 ) begin
        ipl2_n <= 1 ;
        int_ack <= 0;
    end else begin
        vbl_sr <= { vbl_sr[0], vbl };

        if ( clk_10M == 1 ) begin
            int_ack <= ( cpu_as_n == 0 ) && ( cpu_fc == 3'b111 ); // cpu acknowledged the interrupt
        end

        if ( vbl_sr == 2'b01 ) begin // rising edge
            ipl2_n <= ~int_en;
        end else if ( int_ack == 1 || vbl_sr == 2'b10 ) begin
            ipl2_n <= 1 ;
        end
    end
end


reg [15:0] scroll_x [3:0] ;
reg [15:0] scroll_y [3:0] ;

reg [15:0] scroll_x_latch [3:0] ;
reg [15:0] scroll_y_latch [3:0] ;

reg inc_sprite_ofs;

always @ (posedge clk_sys) begin
    if ( reset == 1 ) begin
    
//        scroll_x[ 0 ] = 16'h01ed ;
//        scroll_x[ 1 ] = 16'h01ef ;
//        scroll_x[ 2 ] = 16'h01f1 ;
//        scroll_x[ 3 ] = 16'h01f3 ;
//
//        scroll_y[ 0 ] = 16'h00ef ;
//        scroll_y[ 1 ] = 16'h00ef ;
//        scroll_y[ 2 ] = 16'h00ef ;
//        scroll_y[ 3 ] = 16'h00ef ;
//        
//        scroll_ofs_x <= 16'h01b7;
//        scroll_ofs_y <= 16'h0102;
        int_en <= 0;
    end else begin
        // write asserted and rising cpu clock
        if (  clk_10M == 1 && cpu_rw == 0 ) begin        
            
            if ( tile_ofs_cs ) begin
                curr_tile_ofs <= cpu_dout;
            end

            if ( int_en_cs & !cpu_rw ) begin
                int_en <= cpu_dout[0];
            end

            if ( sprite_ofs_cs ) begin
                // mask out valid range
                curr_sprite_ofs <= { 6'b0, cpu_dout[9:0] };
            end

            if ( scroll_ofs_x_cs ) begin
                scroll_ofs_x <= cpu_dout;
            end

            if ( scroll_ofs_y_cs ) begin
                scroll_ofs_y <= cpu_dout;
            end
            
            // x layer values are even addresses
            if ( scroll_cs ) begin
                if ( cpu_a[1] == 0 ) begin
                    scroll_x[ cpu_a[3:2] ] <= cpu_dout[15:7] ;
                end else begin
                    scroll_y[ cpu_a[3:2] ] <= cpu_dout[15:7] ;
                end
            end
            
            // offset needs to be auto-incremented
            if ( ( sprite_cs | sprite_size_cs ) & !cpu_rw ) begin
                inc_sprite_ofs <= 1;
//                curr_sprite_ofs <= curr_sprite_ofs + 1;
            end
            
        end

        // write lasts multiple cpu clocks so limit to one increment per write signal
        if ( inc_sprite_ofs == 1 && cpu_rw == 1 ) begin
            curr_sprite_ofs <= curr_sprite_ofs + 1;        
            inc_sprite_ofs <= 0;
        end
    end
end

reg [15:0] scroll_x_total [3:0];
reg [15:0] scroll_y_total [3:0];
  
wire [15:0] ram_dout;
wire [9:0]  tile_palette_addr;
wire [15:0] tile_palette_cpu_dout;
wire [15:0] tile_palette_dout;

wire [9:0]  sprite_palette_addr;
wire [15:0] sprite_palette_cpu_dout;
wire [15:0] sprite_palette_dout;

reg [15:0] curr_tile_ofs;
reg [15:0] curr_sprite_ofs;

reg [15:0] scroll_ofs_x;
reg [15:0] scroll_ofs_y;

wire [15:0] cpu_tile_dout_attr;
wire [15:0] cpu_tile_dout_num;

wire [15:0] sprite_0_dout; 
wire [15:0] sprite_1_dout;
wire [15:0] sprite_2_dout;
wire [15:0] sprite_3_dout;
wire [15:0] sprite_size_dout;
wire [15:0] sprite_size_cpu_dout;


wire [31:0] tile_attr_dout;
wire [15:0] sprite_attr_0_dout;
wire [15:0] sprite_attr_1_dout;
wire [15:0] sprite_attr_2_dout;
wire [15:0] sprite_attr_3_dout;

wire [15:0] sprite_size_buf_dout;
wire [15:0] sprite_attr_0_buf_dout ;
wire [15:0] sprite_attr_1_buf_dout ;
wire [15:0] sprite_attr_2_buf_dout ;
wire [15:0] sprite_attr_3_buf_dout ;


reg [15:0] sprite_buf_din;

reg [14:0] tile ;

reg [7:0] sprite_num;
reg [7:0] sprite_num_copy;

reg [3:0] tile_draw_state;

reg [1:0] layer;  // 4 layers

wire [14:0] tile_idx         = tile_attr[14:0] ;
wire  [3:0] tile_priority    = tile_attr[31:28] ;
wire  [5:0] tile_palette_idx = tile_attr[21:16] ;
wire        tile_hidden      = tile_attr[15] ;

reg  [15:0] fb_dout;
wire [15:0] tile_fb_out;
wire [15:0] sprite_fb_out;
reg  [15:0] fb_din;
reg  [15:0] sprite_fb_din ;

reg tile_fb_w;
reg sprite_fb_w;
reg sprite_buf_w;
reg sprite_size_buf_w;

ram1kx16dp tile_line_buffer (
    .clock_a ( clk_sys ),
    .address_a ( tile_fb_addr_w ),
    .wren_a ( tile_fb_w ),
    .data_a ( fb_din ),
    .q_a ( ),

    .clock_b ( clk_sys ),
    .address_b ( fb_addr_r ),  
    .wren_b ( 0 ),
//    .data_b ( ),
    .q_b ( tile_fb_out )
    );
    
ram1kx16dp sprite_line_buffer (
    .clock_a ( clk_sys ),
    .address_a ( sprite_fb_addr_w ),
    .wren_a ( sprite_fb_w ),
    .data_a ( sprite_fb_din ),
    .q_a ( ),

    .clock_b ( clk_sys ),
    .address_b ( fb_addr_r ),  
    .wren_b ( 0 ),
//    .data_b ( ),
    .q_b ( sprite_fb_out )
    );

reg [9:0] x_ofs;
reg [9:0] x;

reg [9:0] y_ofs;

// y needs to be one line ahaed of the visible line
// render the first line at the end of the previous frame
// this depends on the timing that the sprite list is valid
// sprites values are copied at the start of vblank (line 240)

reg [9:0] y ;


reg [3:0] draw_state ;
reg [3:0] sprite_state ;
reg [3:0] tile_copy_state ;
reg [3:0] sprite_copy_state ;


wire [9:0] curr_x = x + x_ofs;
wire [9:0] curr_y = y + y_ofs;

// pixel 4 bit colour 
wire [3:0] tile_pix ;
assign tile_pix = { tile_data[7-curr_x[2:0]], tile_data[15-curr_x[2:0]], tile_data[23-curr_x[2:0]], tile_data[31-curr_x[2:0]] };

wire [2:0] sprite_bit = sprite_x[2:0];
wire [3:0] sprite_pix ;
assign sprite_pix = { sprite_data[7-sprite_bit], sprite_data[15-sprite_bit], sprite_data[23-sprite_bit], sprite_data[31-sprite_bit] };

// two lines of buffer alternate 
reg  [9:0] tile_fb_addr_w;
wire [9:0] fb_addr_r        = {vc[0], 9'b0 } + hc;

reg [9:0] sprite_fb_addr_w ;

reg [31:0] tile_attr;


// two lines worth for 4 layers (~8k)
// [15:14] = layer.  
// [13:10] = prioity
// [9:4] = palette offset
// [3:0] = tile colour index.

reg [3:0] tile_priority_buf   [327:0];
reg [3:0] sprite_priority_buf [327:0];


reg  [9:0] sprite_x;         // offset from left side of sprite
reg  [9:0] sprite_y; 

reg  sprite_buf_active;
wire [9:0] sprite_buf_x = sprite_x + sprite_pos_x ;     // offset from left of frame

wire fetch_tile = layer == 3 || ( tile_priority_buf[x] <= tile_priority && tile_hidden == 0 );

wire [14:0] sprite_index    = sprite_attr_0_buf_dout[14:0] /* synthesis keep */;
wire       sprite_hidden    = sprite_attr_0_buf_dout[15] /* synthesis keep */;
//reg [5:0] sprite_size_addr;

wire [5:0] sprite_pal_addr  = sprite_attr_1_buf_dout[5:0] /* synthesis keep */;
wire [5:0]  sprite_size_addr = sprite_attr_1_buf_dout[11:6] /* synthesis keep */;
wire [3:0]  sprite_priority  = sprite_attr_1_buf_dout[15:12] /* synthesis keep */;

wire [9:0] sprite_pos_x  = sprite_adj_x + (( sprite_attr_2_buf_dout[15:7] < 9'h180 ) ? sprite_attr_2_buf_dout[15:7]  : ( sprite_attr_2_buf_dout[15:7] - 10'h200));
wire [9:0] sprite_pos_y  = sprite_adj_y + (( sprite_attr_3_buf_dout[15:7] < 9'h180 ) ? sprite_attr_3_buf_dout[15:7]  : ( sprite_attr_3_buf_dout[15:7] - 10'h200));  //- 16 + scroll_y_offset /* synthesis keep */; )

// valid 1 cycle after sprite attr ready
wire [8:0] sprite_height    = { sprite_size_buf_dout[7:4], 3'b0 } /* synthesis keep */;  // in pixels
wire [8:0] sprite_width     = { sprite_size_buf_dout[3:0], 3'b0 } /* synthesis keep */;

reg [7:0] sprite_buf_num;

always @ (posedge clk_sys) begin
    
    if ( reset == 1 ) begin
        sprite_state <= 0;
        draw_state <= 0;
        sprite_rom_cs <= 0;
        tile_rom_cs <= 0;
        tile_copy_state <= 0;
        sprite_copy_state <= 0;
        tile_draw_state <= 0;
    end else begin
        // render sprites 
        // triggered when the tile rendering starts
        if ( sprite_state == 0 && draw_state > 0 ) begin
            sprite_num <= 8'hff;
            sprite_buf_active <= 0;
            sprite_x <= 0;
            sprite_fb_w <= 1;
            sprite_state <= 1;
            sprite_fb_din <= 0;
            sprite_fb_addr_w <= { y[0], 9'b0 }  ;  
        end else if ( sprite_state == 1 ) begin           
            // erase line buffer
            sprite_fb_addr_w <= { y[0], 9'b0 } + sprite_x ;  
            sprite_priority_buf[sprite_x] <= 0;
            if ( sprite_x < 320 ) begin
                sprite_x <= sprite_x + 1;
            end else begin
                sprite_x <= 0;
                sprite_fb_w <= 0;
                sprite_buf_active <= 1;
                sprite_state <= 2 ;
            end
        end else if ( sprite_state == 2 ) begin     
            // sprite num is valid now
            sprite_state <= 3 ;
        end else if ( sprite_state == 3 ) begin                
            // sprite attr valid now.  
            // delay one more cycle to read sprite size
            sprite_state <= 4 ;
        end else if ( sprite_state == 4 ) begin        
            // start loop
            sprite_rom_cs <= 0;
            sprite_fb_w <= 0;

            sprite_y <= ( y - sprite_pos_y ) ;
            
            // is sprite visible and is current y in sprite y range
			// sprite pos can be negative
            if ( sprite_hidden == 0 && sprite_width > 0 && ( $signed(y) >= $signed(sprite_pos_y) ) && $signed(y) < ( $signed(sprite_pos_y) + $signed(sprite_height) ) ) begin
                sprite_state <= 5 ;
            end else if ( sprite_num > 0 ) begin 
                sprite_num <= sprite_num - 1;
                sprite_state <= 2 ;
            end else begin
                sprite_state <= 15 ;
            end

        end else if ( sprite_state == 5 ) begin        
            sprite_rom_addr <= { sprite_index, 3'b0 } + { sprite_x[8:3], 3'b0 } + ( sprite_y[8:3] * sprite_width ) + sprite_y[2:0];
            sprite_rom_cs <= 1;
            sprite_state <= 6 ;            
        end else if ( sprite_state == 6 ) begin        
            // wait for sprite bitmap ready
            if ( sprite_rom_data_valid ) begin
                // latch data and deassert cs
                sprite_data <= sprite_rom_data;
                sprite_rom_cs <= 0;
                sprite_state <= 7;
            end 
        end else if ( sprite_state == 7 ) begin                    
            sprite_fb_w <= 0;
            // draw if pixel value not zero and priority >= previous sprite data
            if ( sprite_pix > 0 && sprite_priority_buf[sprite_buf_x] == 0 ) begin  
                sprite_fb_din <= { 2'b11, sprite_priority, sprite_pal_addr, sprite_pix };   
                sprite_fb_addr_w <= { y[0], 9'b0 } + sprite_buf_x ;            
                sprite_priority_buf[sprite_buf_x] <= sprite_priority ;
                sprite_fb_w <= 1;
            end 

            if ( sprite_x < ( sprite_width - 1 ) ) begin
                sprite_x <= sprite_x + 1;

                if ( sprite_x[2:0] == 7 ) begin
                    // do recalc bitmap address
                    sprite_state <= 5 ;
                end
            end else if ( sprite_num > 0 ) begin
                sprite_num <= sprite_num - 1;
                sprite_x <= 0;
                // need to load new attributes and size
                sprite_state <= 2 ;
            end else begin
                // tile state machine will reset sprite_state when line completes.
                sprite_state <= 15; // done
            end            
        end
        
        // copy tile ram and scroll info
        // not sure if this is needed. need to check to see when tile ram is updated.
        if (  tile_copy_state == 0 && vc == 256  ) begin 
            tile_copy_state <= 1;
        end else begin
            // copy scroll registers
            scroll_x_latch[0] <= scroll_x[0] - scroll_ofs_x;
            scroll_x_latch[1] <= scroll_x[1] - scroll_ofs_x;
            scroll_x_latch[2] <= scroll_x[2] - scroll_ofs_x;
            scroll_x_latch[3] <= scroll_x[3] - scroll_ofs_x;

            scroll_y_latch[0] <= scroll_y[0] - scroll_ofs_y - scroll_y_offset;
            scroll_y_latch[1] <= scroll_y[1] - scroll_ofs_y - scroll_y_offset;
            scroll_y_latch[2] <= scroll_y[2] - scroll_ofs_y - scroll_y_offset;
            scroll_y_latch[3] <= scroll_y[3] - scroll_ofs_y - scroll_y_offset;

        end 
        
        // copy sprite attr/size to buffer
        if (  sprite_copy_state == 0 && vc == 240  ) begin 
            sprite_copy_state <= 1;
            sprite_buf_w <= 0;
            sprite_num_copy <= 8'h00;
        end else if ( sprite_copy_state == 1 ) begin 
            sprite_num_copy <= sprite_num_copy + 1;
            sprite_buf_num <= sprite_num_copy;
            sprite_buf_w <= 1;

            // wait for read from source
            if ( sprite_num_copy == 8'hff ) begin 
                sprite_copy_state <= 2 ;
            end
        end else if ( sprite_copy_state == 2 ) begin
            sprite_buf_w <= 0;
            sprite_copy_state <= 0 ;
        end

        // tile state machine
		
		 if ( draw_state == 0 && vc == 269 ) begin
            layer <= 3;
            y <= 0;
            draw_state <= 2;
            sprite_state <= 0;
        end else if ( draw_state == 2 ) begin
            x <= 0;

            x_ofs <= 495 + 6 +  scroll_x_latch[layer] - { layer, 1'b0 } ; 
            y_ofs <= 257 + 16 + scroll_y_latch[layer] ;

            // latch offset info
            draw_state <= 3;
            tile_draw_state <= 0;
        end else if ( draw_state == 3 ) begin

            if ( tile_draw_state == 0 ) begin
                tile <=  { layer[1:0], curr_y[8:3], curr_x[8:3] };  // works
                
                tile_draw_state <= 4'h1;
            end else if ( tile_draw_state == 1 ) begin
                
                
                tile_draw_state <= 2;
            end else if ( tile_draw_state == 2 ) begin            

            // latch attribute
                tile_attr <= tile_attr_dout;
                //tile_attr <= tile_buf_dout;
            
                tile_draw_state <= 3;
            end else if ( tile_draw_state == 3 ) begin
                // read bitmap info
                tile_rom_cs <= 1;
                tile_rom_addr <= { tile_idx, curr_y[2:0] }  ;  
                tile_draw_state <= 4;
            end else if ( tile_draw_state == 4 ) begin     

                // wait for bitmap ram ready
                if ( tile_rom_data_valid ) begin
                    // latch data and deassert cs
                    tile_data <= tile_rom_data;
                    tile_draw_state <= 5 ;
                    tile_rom_cs <= 0;
                end
            end else if ( tile_draw_state == 5 ) begin   
             
                tile_fb_w <= 0; 
                tile_fb_addr_w   <= { y[0], 9'b0 } + x ;
                
                // force render of first layer.
                // don't draw transparent pixels
                if ( layer == 3 ) begin            
               
                    tile_priority_buf[x] <= (tile_hidden == 1 || tile_pix == 0 ) ? 4'b0 : tile_priority;
                    
                    // if tile hidden then make the pallette index 0. ie transparent
                    fb_din <= { layer, (tile_hidden == 1 || tile_pix == 0 ) ? 4'b0 : tile_priority, tile_palette_idx,  tile_pix };
                    tile_fb_w <= 1;
                end else if (tile_hidden == 0 && tile_pix > 0 && (tile_priority_type ? tile_priority > tile_priority_buf[x] : tile_priority >= tile_priority_buf[x])) begin
                    tile_priority_buf[x] <= tile_priority;
                    
                    // if tile hidden then make the pallette index 0. ie transparent
                    fb_din <= { layer, tile_priority, tile_palette_idx,  tile_pix };
                    tile_fb_w <= 1;
                end
                
                if ( x < 320 ) begin // 319
                    // do we need to read another tile?
                    if ( curr_x[2:0] == 7 ) begin
                        draw_state <= 3;
                        tile_draw_state <= 0;
                    end 
                    x <= x + 1 ;
                end else if ( layer > 0 ) begin
                    layer <= layer - 1;
                    tile_fb_w <= 0;
                    draw_state <= 2;
                end else begin
                    // done
                    tile_draw_state <= 7 ;
                    tile_fb_w <= 0;
                end
            end else if ( tile_draw_state == 7 ) begin      
                // wait for next line or quit
                if ( y == 239 ) begin
                    draw_state <= 0;            
                end else if ( hc == 449 ) begin
                    y <= y + 1;
                    draw_state <= 2;
                    sprite_state <= 0 ;
                    layer <= 3;
                end
            end
        end
    end
end

// render 
reg draw_sprite;

// two lines worth for 4 layers (~8k)
// [15:14] = layer.  
// [13:10] = prioity
// [9:4] = palette offset
// [3:0] = tile colour index.

// there are 10 70MHz cycles per pixel. clk7_count from 0-9
// 
always @ (posedge clk_sys) begin
    if ( clk7_count == 4 ) begin
        tile_palette_addr  <= tile_fb_out[9:0] ; 
        sprite_palette_addr <= sprite_fb_out[9:0] ; 
    end else if ( clk7_count == 6 ) begin
        if ( vbl ) begin
            rgb_out <= { 8'hee, 7'h0, hc };
        end else begin  
            // if palette index is zero then it's from layer 3 and is transparent render as blank (black).
            rgb_out <= ( tile_fb_out[3:0] == 0 ) ? 0 : { tile_palette_dout[4:0], 3'b0, tile_palette_dout[9:5], 3'b0, tile_palette_dout[14:10], 3'b0 };

            // if not transparent and sprite is higher priority 
            if ( sprite_fb_out[3:0] > 0 && (sprite_fb_out[13:10] > tile_fb_out[13:10]) ) begin 
                // draw sprite
                rgb_out <= { sprite_palette_dout[4:0], 3'b0, sprite_palette_dout[9:5], 3'b0, sprite_palette_dout[14:10], 3'b0 };
            end
           
        end
    end
end


// tile data buffer

reg tile_buf_w;
reg [31:0] tile_buf_din;
reg [31:0] tile_buf_dout;
reg [13:0] tile_buf_addr;


ram16kx32dp ram_tile_buf (
    .clock_a ( clk_sys ),
    .address_a ( tile[13:0] ),
    .wren_a ( tile_buf_w ),
    .data_a ( tile_attr_dout ),

    .clock_b ( clk_sys ),
    .address_b ( tile[13:0] ),  // only read the tile # for now
    .wren_b ( 0 ),
    .q_b ( tile_buf_dout )
    ); 
    
reg [15:0] sdram_dout ;
reg [15:0] rgb_ram ;

reg  [22:0] sdram_addr;
reg  [31:0] sdram_data;
reg         sdram_we;
reg         sdram_req;

wire        sdram_ack;
wire        sdram_valid;
wire [31:0] sdram_q;

wire prog_rom_data_valid;
wire tile_rom_data_valid;
wire sprite_rom_data_valid;
wire sound_rom_1_data_valid;

wire prog_rom_oe;
wire [23:1] prog_rom_addr;
wire [15:0] prog_rom_data;
wire prog_rom_ctrl_valid;

reg tile_rom_cs;
reg tile_rom_oe;
reg [18:0] tile_rom_addr;
reg [31:0] tile_rom_data;
reg tile_rom_ctrl_valid;
reg [31:0] tile_data;

wire sprite_rom_cs;
wire sprite_rom_oe;
wire [18:0] sprite_rom_addr;
wire [31:0] sprite_rom_data;
wire sprite_rom_ctrl_valid;
reg [31:0] sprite_data;

wire sound_rom_1_oe;
wire [15:0] sound_rom_1_addr;
wire [7:0] sound_rom_1_data;
wire sound_rom_1_ctrl_valid;

// sdram priority based rom controller
// is a oe needed?
rom_controller rom_controller 
(
    .reset(reset),

    // clock
    .clk(clk_sys),

    // program ROM interface
    .prog_rom_cs(prog_rom_cs),
    .prog_rom_oe(1),
    .prog_rom_addr(cpu_a[23:1]),
    .prog_rom_data(prog_rom_data),
    .prog_rom_data_valid(prog_rom_data_valid),

    // character ROM interface
    .tile_rom_cs(tile_rom_cs),
    .tile_rom_oe(1),
    .tile_rom_addr(tile_rom_addr),
    .tile_rom_data(tile_rom_data),
    .tile_rom_data_valid(tile_rom_data_valid),

    // sprite ROM interface
    .sprite_rom_cs(sprite_rom_cs),
    .sprite_rom_oe(1),
    .sprite_rom_addr(sprite_rom_addr),
    .sprite_rom_data(sprite_rom_data),
    .sprite_rom_data_valid(sprite_rom_data_valid),

    // sound ROM #1 interface
    .sound_rom_1_cs(sound_rom_1_cs),
    .sound_rom_1_oe(1),
    .sound_rom_1_addr(z80_addr),
    .sound_rom_1_data(sound_rom_1_data),
    .sound_rom_1_data_valid(sound_rom_1_data_valid),

    // IOCTL interface
    .ioctl_addr(ioctl_addr),
    .ioctl_data(ioctl_dout),
    .ioctl_index(ioctl_index),
    .ioctl_wr(ioctl_wr),
    .ioctl_download(ioctl_download),

    // SDRAM interface
    .sdram_addr(sdram_addr),
    .sdram_data(sdram_data),
    .sdram_we(sdram_we),
    .sdram_req(sdram_req),
    .sdram_ack(sdram_ack),
    .sdram_valid(sdram_valid),
    .sdram_q(sdram_q)
  );
  

// tile attribute ram.  each tile attribute is 2 16bit words
// pppp ---- --cc cccc httt tttt tttt tttt = Tile number (0 - $7fff)
// indirect access through offset register
ram16kx16dp ram_tile_h (
    .clock_a ( clk_10M ),
    .address_a ( curr_tile_ofs ),
    .wren_a ( tile_attr_cs & !cpu_rw ),
    .data_a ( cpu_dout ),
    .q_a ( cpu_tile_dout_attr ),

    .clock_b ( clk_sys ),
    .address_b ( tile[13:0] ),  // only read the tile # for now
    .wren_b ( 0 ),
    .q_b ( tile_attr_dout[31:16] )   
    );
    
ram16kx16dp ram_tile_l (
    .clock_a ( clk_10M ),
    .address_a ( curr_tile_ofs ),
    .wren_a ( tile_num_cs & !cpu_rw ),
    .data_a ( cpu_dout ),
    .q_a ( cpu_tile_dout_num ),

    .clock_b ( clk_sys ),
    .address_b ( tile[13:0] ),  // only read the tile # for now
    .wren_b ( 0 ),
    .q_b ( tile_attr_dout[15:0] )
    );    

    
// sprite attribute ram.  each tile attribute is 4 16bit words
// indirect access through offset register
// split up so 64 bits can be read in a single clock
ram256bx16dp sprite_ram_0 (
    .clock_a ( clk_10M ),
    .address_a ( curr_sprite_ofs[9:2] ),
    .wren_a ( sprite_0_cs  & !cpu_rw),
    .data_a ( cpu_dout ),
    .q_a ( sprite_0_dout ),

    .clock_b ( clk_sys ),
    .address_b ( sprite_num_copy ),
    .wren_b ( 0 ),
    .q_b ( sprite_attr_0_dout[15:0] )
    );

ram256bx16dp sprite_ram_0_buf (
    .clock_a ( clk_sys ),
    .address_a ( sprite_buf_num ),
    .wren_a ( sprite_buf_w ),
    .data_a ( sprite_attr_0_dout[15:0] ),
    .q_a (  ),

    .clock_b ( clk_sys ),
    .address_b ( sprite_num ),
    .wren_b ( 0 ),
    .q_b ( sprite_attr_0_buf_dout[15:0] )
    );
    
ram256bx16dp sprite_ram_1 (
    .clock_a ( clk_10M ),
    .address_a ( curr_sprite_ofs[9:2] ),
    .wren_a ( sprite_1_cs  & !cpu_rw ),
    .data_a ( cpu_dout ),
    .q_a ( sprite_1_dout ),

    .clock_b ( clk_sys ),
    .address_b ( sprite_num_copy ),
    .wren_b ( 0 ),
    .q_b ( sprite_attr_1_dout[15:0] )
    );
    
ram256bx16dp sprite_ram_1_buf (
    .clock_a ( clk_sys ),
    .address_a ( sprite_buf_num ),
    .wren_a ( sprite_buf_w ),
    .data_a ( sprite_attr_1_dout[15:0] ),
    .q_a (  ),

    .clock_b ( clk_sys ),
    .address_b ( sprite_num ),
    .wren_b ( 0 ),
    .q_b ( sprite_attr_1_buf_dout[15:0] )
    );

ram256bx16dp sprite_ram_2 (
    .clock_a ( clk_10M ),
    .address_a ( curr_sprite_ofs[9:2] ),
    .wren_a ( sprite_2_cs  & !cpu_rw ),
    .data_a ( cpu_dout ),
    .q_a ( sprite_2_dout ),

    .clock_b ( clk_sys ),
    .address_b ( sprite_num_copy ),
    .wren_b ( 0 ),
    .q_b ( sprite_attr_2_dout[15:0] )
    );

ram256bx16dp sprite_ram_2_buf (
    .clock_a ( clk_sys ),
    .address_a ( sprite_buf_num ),
    .wren_a ( sprite_buf_w ),
    .data_a ( sprite_attr_2_dout[15:0] ),
    .q_a (  ),

    .clock_b ( clk_sys ),
    .address_b ( sprite_num ),
    .wren_b ( 0 ),
    .q_b ( sprite_attr_2_buf_dout[15:0] )
    );
    
ram256bx16dp sprite_ram_3 (
    .clock_a ( clk_10M ),
    .address_a ( curr_sprite_ofs[9:2] ),
    .wren_a ( sprite_3_cs  & !cpu_rw ),
    .data_a ( cpu_dout ),
    .q_a ( sprite_3_dout ),

    .clock_b ( clk_sys ),
    .address_b ( sprite_num_copy ),
    .wren_b ( 0 ),
    .q_b ( sprite_attr_3_dout[15:0] )
    );    

ram256bx16dp sprite_ram_3_buf (
    .clock_a ( clk_sys ),
    .address_a ( sprite_buf_num ),
    .wren_a ( sprite_buf_w ),
    .data_a ( sprite_attr_3_dout[15:0] ),
    .q_a (  ),

    .clock_b ( clk_sys ),
    .address_b ( sprite_num ),
    .wren_b ( 0 ),
    .q_b ( sprite_attr_3_buf_dout[15:0] )
    );       

ram256bx16dp sprite_ram_size (
    .clock_a ( clk_10M ),
    .address_a ( curr_sprite_ofs ),
    .wren_a ( sprite_size_cs  & !cpu_rw),
    .data_a ( cpu_dout ),
    .q_a ( sprite_size_cpu_dout ),

    .clock_b ( clk_sys ),
    .address_b ( sprite_num_copy ),
    .wren_b ( 0 ),
    .q_b ( sprite_size_dout )
    );    
    
ram256bx16dp sprite_ram_size_buf (
    .clock_a ( clk_sys ),
    .address_a ( sprite_buf_num ),
    .wren_a ( sprite_buf_w ),
    .data_a ( sprite_size_dout ),
    .q_a (  ),

    .clock_b ( clk_sys ),
    .address_b ( sprite_size_addr ),
    .wren_b ( 0 ),
    .q_b ( sprite_size_buf_dout )
    
    ); 

      
// tiles  1024 15 bit values.  index is ( 6 bits from tile attribute, 4 bits from bitmap )
// background palette ram low    
// does this need to be byte addressable?
ram1kx8dp tile_palram_l (
    .clock_a ( clk_10M ),
    .address_a ( cpu_a[10:1] ),
    .wren_a ( tile_palette_cs & !cpu_rw & !cpu_lds_n),
    .data_a ( cpu_dout[7:0]  ),
    .q_a ( tile_palette_cpu_dout[7:0] ),

    .clock_b ( clk_sys ),
    .address_b ( tile_palette_addr ),
    .wren_b ( 0 ),
    .q_b ( tile_palette_dout[7:0] )
    );

// background palette ram high
ram1kx8dp tile_palram_h (
    .clock_a ( clk_10M ),
    .address_a ( cpu_a[10:1] ),
    .wren_a ( tile_palette_cs & !cpu_rw & !cpu_uds_n),
    .data_a ( cpu_dout[15:8]  ),
    .q_a ( tile_palette_cpu_dout[15:8] ),

    .clock_b ( clk_sys ),
    .address_b ( tile_palette_addr ),
    .wren_b ( 0 ),
    .q_b ( tile_palette_dout[15:8] )
    );

// sprite palette ram low    
// does this need to be byte addressable?
ram1kx8dp sprite_palram_l (
    .clock_a ( clk_10M ),
    .address_a ( cpu_a[10:1] ),
    .wren_a ( sprite_palette_cs & !cpu_rw & !cpu_lds_n),
    .data_a ( cpu_dout[7:0]  ),
    .q_a ( sprite_palette_cpu_dout[7:0] ),

    .clock_b ( clk_sys ),
    .address_b ( sprite_palette_addr ),
    .wren_b ( 0 ),
    .q_b ( sprite_palette_dout[7:0] )
    );

// background palette ram high
ram1kx8dp sprite_palram_h (
    .clock_a ( clk_10M ),
    .address_a ( cpu_a[10:1] ),
    .wren_a ( sprite_palette_cs & !cpu_rw & !cpu_uds_n),
    .data_a ( cpu_dout[15:8]  ),
    .q_a ( sprite_palette_cpu_dout[15:8] ),

    .clock_b ( clk_sys ),
    .address_b ( sprite_palette_addr ),
    .wren_b ( 0 ),
    .q_b ( sprite_palette_dout[15:8] )
    );   

    
// main 68k ram low                 
ram16kx8dp    ram16kx8_L (
    .clock_a ( clk_10M ),
    .address_a ( cpu_a[14:1] ),
    .wren_a ( !cpu_rw & ram_cs & !cpu_lds_n ),
    .data_a ( cpu_dout[7:0]  ),
    .q_a (  ram_dout[7:0] ),
    );

// main 68k ram high    
ram16kx8dp    ram16kx8_H (
    .clock_a ( clk_10M ),
    .address_a ( cpu_a[14:1] ),
    .wren_a ( !cpu_rw & ram_cs & !cpu_uds_n ),
    .data_a ( cpu_dout[15:8]  ),
    .q_a (  ram_dout[15:8] ),
    );


//wire [15:0] z80_shared_addr = z80_addr - 16'h8000;
//wire [23:0] m68k_shard_addr = cpu_a    - 24'h040000  ;

// z80 and 68k shared ram   
// 4k 
ram4kx8dp shared_ram (
    .clock_a ( clk_10M ),
    .address_a ( cpu_a[12:1] ),
    .wren_a ( shared_ram_cs & !cpu_rw & !cpu_lds_n),
    .data_a ( cpu_dout[7:0]  ),
    .q_a ( cpu_shared_dout[7:0] ),

    .clock_b ( clk_7M ),  // z80 clock is 3.5M
    .address_b ( z80_addr[11:0] ),
    .data_b ( z80_dout ),
    .wren_b ( sound_ram_1_cs & ~z80_wr_n ),
    .q_b ( z80_shared_dout )
    );
    
sdram #(.CLK_FREQ(70.0)) sdram
(
  .reset(~pll_locked),
  .clk(clk_sys),

  // controller interface
  .addr(sdram_addr),
  .data(sdram_data),
  .we(sdram_we),
  .req(sdram_req),
  .ack(sdram_ack),
  .valid(sdram_valid),
  .q(sdram_q),

  // SDRAM interface
  .sdram_a(SDRAM_A),
  .sdram_ba(SDRAM_BA),
  .sdram_dq(SDRAM_DQ),
  .sdram_cke(SDRAM_CKE),
  .sdram_cs_n(SDRAM_nCS),
  .sdram_ras_n(SDRAM_nRAS),
  .sdram_cas_n(SDRAM_nCAS),
  .sdram_we_n(SDRAM_nWE),
  .sdram_dqml(SDRAM_DQML),
  .sdram_dqmh(SDRAM_DQMH)
);


endmodule

