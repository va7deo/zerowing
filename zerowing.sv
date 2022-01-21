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
    inout  [45:0] HPS_BUS,

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

assign USER_OUT  = '1;
assign AUDIO_MIX = 0;
//assign LED_USER  = ioctl_download ;
assign LED_DISK  = 0;
assign LED_POWER = 0;
assign BUTTONS = 0;

wire [1:0] aspect_ratio = status[2:1];
wire orientation = ~status[3];
wire [2:0] scan_lines = status[6:4];

wire [7:0] dipA = status[17:10];
wire [7:0] dipB = status[25:18];

assign VIDEO_ARX = (!aspect_ratio) ? (orientation  ? 8'd4 : 8'd3) : (aspect_ratio - 1'd1);
assign VIDEO_ARY = (!aspect_ratio) ? (orientation  ? 8'd3 : 8'd4) : 12'd0;

`include "build_id.v" 
localparam CONF_STR = {
    "A. zerowing;;",
    "F,rom;",
    "O12,Aspect ratio,Original,Full Screen,[ARC1],[ARC2];",
    "O3,Orientation,Horz,Vert;",
    "O46,Scandoubler Fx,None,HQ2x,CRT 25%,CRT 50%,CRT 75%;",
    "O12,Aspect ratio,Original,Full Screen,[ARC1],[ARC2];",
    "O3,Orientation,Horz,Vert;",
    "O46,Scandoubler Fx,None,HQ2x,CRT 25%,CRT 50%,CRT 75%;",
    "OA,Cocktail,Off,On;",
    "OB,Flip Screen,Off,On;",
    "OC,Test Mode,Off,On;",
    "OD,Demo Sounds,On,Off;",
    "OEF,Slot A,1c/1cr,1c/2cr,2c/1cr,2c/3cr;",
    "OGH,Slot B,1c/1cr,1c/2cr,2c/1cr,2c/3cr;",
    "OIJ,Difficulty,Normal,Easy,Hard,Extra Hard;",
    "OKL,Extend,200K/500K,500K/1000K,500K,None;",    
    "OMN,Lifes,3,5,4,2;",
    "OO,Invulnerable,Off,On;",
    "OP,Continue Play,On,Off;",
    "-;",
    "R0,Reset;",
    "J1,Fire,Capture,Start 1P,Start 2P,Coin,Pause;",
    "jn,A,Start,Select,R,L;",
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

wire [31:0] status;
wire  [1:0] buttons;
wire        forced_scandoubler;
wire        direct_video;

wire [15:0] joystick_0, joystick_1;
wire [15:0] joy = joystick_0 | joystick_1;

wire [21:0] gamma_bus;

wire b_up      = joy[3];
wire b_down    = joy[2];
wire b_left    = joy[1];
wire b_right   = joy[0];
wire b_fire    = joy[4];

wire b_up_2    = joy[3];
wire b_down_2  = joy[2];
wire b_left_2  = joy[1];
wire b_right_2 = joy[0];
wire b_fire_2  = joy[4];

wire b_start1  = joy[5];
wire b_start2  = joy[6];
wire b_coin    = joy[7];
wire b_pause   = joy[8];

// PAUSE SYSTEM
reg                pause;                                    // Pause signal (active-high)
reg                pause_toggle = 1'b0;                    // User paused (active-high)
reg [31:0]        pause_timer;                            // Time since pause
reg [31:0]        pause_timer_dim = 31'h11E1A300;    // Time until screen dim (10 seconds @ 48Mhz)
reg             dim_video = 1'b0;                        // Dim video output (active-high)

// Pause when highscore module requires access, user has pressed pause, or OSD is open and option is set
assign pause =  pause_toggle | (OSD_STATUS && ~status[7]);
assign dim_video = (pause_timer >= pause_timer_dim);

reg coin,start_1,start_2,up,down,left,right,fire,capture ;


reg [1:0] adj_layer ;
reg [15:0] prev_joy;
reg [15:0] scroll_adj_x [3:0];
reg [15:0] scroll_adj_y [3:0];
reg layer_en [3:0];

reg old_pause;

always @ ( posedge clk_sys ) begin
    right <= prev_joy[0];
    left <= prev_joy[1];
    down <= prev_joy[2];
    up <= prev_joy[3];
    fire <= prev_joy[4];
    capture <= prev_joy[5];
    start_1 <= prev_joy[6];
    start_2 <= prev_joy[7];
    coin <= prev_joy[8];
end

always @(posedge clk_sys) begin
    prev_joy <= joy;

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

hps_io #(.STRLEN($size(CONF_STR)>>3)) hps_io
(
    .clk_sys(clk_sys),
    .HPS_BUS(HPS_BUS),

    .conf_str(CONF_STR),

    .buttons(buttons),
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

    .joystick_0(joystick_0),
    .joystick_1(joystick_1)
);




reg ce_pix;

wire hbl;
wire vbl;

wire hsync;
wire vsync;

wire [8:0] hc;
wire [8:0] vc;

wire no_rotate = orientation | direct_video;
//wire rotate_ccw = 1;
//screen_rotate screen_rotate (.*);

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
assign reset = RESET | status[0] | ioctl_download | buttons[1];

wire vid_clk = clk_7M;

video_timing video_timing (
    .clk( vid_clk ),       // pixel clock
    .reset(reset),      // reset

    .hc(hc),  
    .vc(vc),  

    .hbl(hbl),
    .vbl(vbl),
    
    .hsync(hsync),     
    .vsync(vsync)   
    );
    

reg  [23:0] rgb_out;


wire pwr_up_reset_n = !reset  ;

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
reg  m68k_int_ack;

assign cpu_a[0] = 0;           // odd memory address should cause cpu exception

     
fx68k fx68k (
    // input
    .clk( clk_10M & ~ioctl_download ),
//    .clk( clk_sys & ~ioctl_download ),
    .enPhi1(fx68_phi1),
    .enPhi2(fx68_phi2),
    .extReset(!pwr_up_reset_n),
    .pwrUp(!pwr_up_reset_n),
//    .HALTn(pwr_up_reset_n),

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
    .DTACKn(dtack_n | ~ipl2_n),     // 
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
    dtack_n <= prog_rom_1_cs ? !prog_rom_1_data_valid :
        prog_rom_2_cs ? !prog_rom_2_data_valid : 
        ram_cs ? 0 : 0;  // always ack

// select cpu data input based on what is active 
    cpu_din <= prog_rom_1_cs ? prog_rom_1_data :
        prog_rom_2_cs ? prog_rom_2_data :
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
        vblank_cs ? { 16 { vbl } } : // get vblank state
        int_en_cs ? 16'hffff :
        16'd0;
        
    m68k_int_ack <= ( cpu_as_n == 0 ) && ( cpu_fc == 3'b111 );  // ack high

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
    if ( clk_7M == 1 ) begin
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
            end else if ( sound_io_00_cs ) begin
                z80_din <= { 1'b0, 1'b0, capture, fire, right, left, down, up };
            end else if ( sound_io_20_cs ) begin
                z80_din <= dipA; //dsw1;
            end else if ( sound_io_28_cs ) begin
                z80_din <= dipB; //dsw2;
            end else if ( sound_io_80_cs ) begin
                z80_din <= { 1'b0, 1'b0, start_1, start_2, coin, 1'b0, 1'b0, 1'b0 };
            end else if ( sound_io_a8_cs ) begin    
                z80_din <= opl_dout;
            end else begin
                z80_din <= 8'h00;
            end
        end
        
        sound_wr <= 0 ;
        if ( z80_wr_n == 0 ) begin 
            if ( sound_io_a8_cs | sound_io_a9_cs ) begin    
                sound_data  <= z80_dout;
                sound_addr <= { 1'b0, sound_io_a9_cs }; // opl3
//                sound_addr <= sound_io_a9_cs ;  // opl2 is single bit address
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
    .rd(sound_io_a8_cs & ~z80_rd_n ),

    .sample_l(AUDIO_L),
    .sample_r(AUDIO_R)
);

  
T80pa u_cpu(
    .RESET_n    ( pwr_up_reset_n ),
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

//    map(0x000000, 0x00ffff).rom();
//    map(0x040000, 0x07ffff).rom();
//    map(0x080000, 0x087fff).ram();
//    map(0x0c0000, 0x0c0003).w(FUNC(toaplan1_state::tile_offsets_w));
//    map(0x0c0006, 0x0c0006).w(FUNC(toaplan1_state::fcu_flipscreen_w));
//  map(0x400000, 0x400001).r(FUNC(toaplan1_state::frame_done_r));
//    map(0x400003, 0x400003).w(FUNC(toaplan1_state::intenable_w));
//    map(0x400008, 0x40000f).w(FUNC(toaplan1_state::bcu_control_w)); 
//    map(0x404000, 0x4047ff).ram().w(FUNC(toaplan1_state::bgpalette_w)).share("bgpalette");      
//    map(0x406000, 0x4067ff).ram().w(FUNC(toaplan1_state::fgpalette_w)).share("fgpalette");      // sprites
//    map(0x440000, 0x440fff).rw(FUNC(toaplan1_state::shared_r), FUNC(toaplan1_state::shared_w)).umask16(0x00ff);
//    map(0x480001, 0x480001).w(FUNC(toaplan1_state::bcu_flipscreen_w));
//    map(0x480002, 0x480003).rw(FUNC(toaplan1_state::tileram_offs_r), FUNC(toaplan1_state::tileram_offs_w));
//    map(0x480004, 0x480007).rw(FUNC(toaplan1_state::tileram_r), FUNC(toaplan1_state::tileram_w));
//    map(0x480010, 0x48001f).rw(FUNC(toaplan1_state::scroll_regs_r), FUNC(toaplan1_state::scroll_regs_w));
//    map(0x4c0000, 0x4c0001).r(FUNC(toaplan1_state::frame_done_r));
//    map(0x4c0002, 0x4c0003).rw(FUNC(toaplan1_state::spriteram_offs_r), FUNC(toaplan1_state::spriteram_offs_w));
//    map(0x4c0004, 0x4c0005).rw(FUNC(toaplan1_state::spriteram_r), FUNC(toaplan1_state::spriteram_w));
//    map(0x4c0006, 0x4c0007).rw(FUNC(toaplan1_state::spritesizeram_r), FUNC(toaplan1_state::spritesizeram_w));

// 68k address decoder

wire prog_rom_1_cs   = ( cpu_a <= 24'h00ffff ) & !cpu_as_n  ; 
wire prog_rom_2_cs   = ( cpu_a >= 24'h040000 && cpu_a <= 24'h07ffff ) & !cpu_as_n  ;  

wire scroll_ofs_x_cs = ( cpu_a >= 24'h0c0000 && cpu_a <= 24'h0c0001 ) & !cpu_as_n  ;  
wire scroll_ofs_y_cs = ( cpu_a >= 24'h0c0002 && cpu_a <= 24'h0c0003 ) & !cpu_as_n  ;  

wire ram_cs          = ( cpu_a >= 24'h080000 && cpu_a <= 24'h087fff ) & !cpu_as_n  ;  

wire frame_done_cs   = ( cpu_a >= 24'h400000 && cpu_a <= 24'h400001 ) & !cpu_as_n  ;

wire int_en_cs       = ( cpu_a >= 24'h400002 && cpu_a <= 24'h400003 ) & !cpu_as_n  ;  
wire start_cs        = ( cpu_a >= 24'h400004 && cpu_a <= 24'h400005 ) & !cpu_as_n  ;  

wire tile_ofs_cs     = ( cpu_a >= 24'h480002 && cpu_a <= 24'h480003 ) & !cpu_as_n  ;  

wire tile_attr_cs    = ( cpu_a >= 24'h480004 && cpu_a <= 24'h480005 ) & !cpu_as_n  ;  
wire tile_num_cs     = ( cpu_a >= 24'h480006 && cpu_a <= 24'h480007 ) & !cpu_as_n  ; 

wire scroll_cs       = ( cpu_a >= 24'h480010 && cpu_a <= 24'h48001f ) & !cpu_as_n  ; 

wire shared_ram_cs   = ( cpu_a >= 24'h440000 && cpu_a <= 24'h440fff ) & !cpu_as_n  ;  

wire vblank_cs       = ( cpu_a >= 24'h4c0000 && cpu_a <= 24'h4c0001 ) & !cpu_as_n  ;  // word

wire tile_palette_cs   = ( cpu_a >= 24'h404000 && cpu_a <= 24'h4047ff ) & !cpu_as_n  ;
wire sprite_palette_cs = ( cpu_a >= 24'h406000 && cpu_a <= 24'h4067ff ) & !cpu_as_n  ;

wire sprite_ofs_cs    = ( cpu_a >= 24'h4c0002 && cpu_a <= 24'h4c0003 ) & !cpu_as_n  ;
wire sprite_cs        = ( cpu_a >= 24'h4c0004 && cpu_a <= 24'h4c0005 ) & !cpu_as_n  ; // *** offset needs to be auto-incremented
wire sprite_size_cs   = ( cpu_a >= 24'h4c0006 && cpu_a <= 24'h4c0007 ) & !cpu_as_n  ; // *** offset needs to be auto-incremented

wire sprite_0_cs      = ( curr_sprite_ofs[1:0] == 2'b00 ) & sprite_cs ;
wire sprite_1_cs      = ( curr_sprite_ofs[1:0] == 2'b01 ) & sprite_cs ;
wire sprite_2_cs      = ( curr_sprite_ofs[1:0] == 2'b10 ) & sprite_cs ;
wire sprite_3_cs      = ( curr_sprite_ofs[1:0] == 2'b11 ) & sprite_cs ;

wire sound_rom_1_cs   = ( MREQ_n == 0 && z80_addr <= 16'h7fff )  ;
wire sound_ram_1_cs   = ( MREQ_n == 0 && z80_addr >= 16'h8000 && z80_addr <= 16'h87ff ) ;
 
wire sound_io_00_cs   = ( IORQ_n == 0 && z80_addr[7:0] == 8'h00 ) ; // P1
wire sound_io_08_cs   = ( IORQ_n == 0 && z80_addr[7:0] == 8'h08 ) ; // P2
wire sound_io_20_cs   = ( IORQ_n == 0 && z80_addr[7:0] == 8'h20 ) ; // DSWA
wire sound_io_28_cs   = ( IORQ_n == 0 && z80_addr[7:0] == 8'h28 ) ; // DSWB
wire sound_io_80_cs   = ( IORQ_n == 0 && z80_addr[7:0] == 8'h80 ) ; // SYSTEM
wire sound_io_88_cs   = ( IORQ_n == 0 && z80_addr[7:0] == 8'h88 ) ; // TJUMP
wire sound_io_a8_cs   = ( IORQ_n == 0 && z80_addr[7:0] == 8'ha8 ) ; // sound
wire sound_io_a9_cs   = ( IORQ_n == 0 && z80_addr[7:0] == 8'ha9 ) ; // sound
 
reg int_en ;
reg int_ack ;

reg [1:0] vbl_sr;
// vblank interrupt on rising vbl 
always @ (posedge clk_sys ) begin
    if ( reset == 1 ) begin
        ipl2_n <= 1 ;
    end else begin
        vbl_sr <= { vbl_sr[0], vbl };
        
//        if ( clk10_prev == 0 && clk_10M ) begin
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
                curr_sprite_ofs <= cpu_dout;
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
reg  [15:0] fb_din ;
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

reg [8:0] x_ofs,x;
reg [8:0] y_ofs,y;

reg [3:0] draw_state ;
reg [3:0] sprite_state ;
reg [3:0] tile_copy_state ;
reg [3:0] sprite_copy_state ;


wire [8:0] curr_x = x + x_ofs ;
wire [8:0] curr_y = y + y_ofs ;

// pixel 4 bit colour 
wire [3:0] tile_pix ;
assign tile_pix = { tile_data[7-curr_x[2:0]], tile_data[15-curr_x[2:0]], tile_data[23-curr_x[2:0]], tile_data[31-curr_x[2:0]] };

wire [2:0] sprite_bit = sprite_x[2:0];
wire [3:0] sprite_pix ;
assign sprite_pix = { sprite_data[7-sprite_bit], sprite_data[15-sprite_bit], sprite_data[23-sprite_bit], sprite_data[31-sprite_bit] };

wire [9:0] tile_fb_addr_w   = { y[0], 9'b0 } + x ;
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

wire       sprite_hidden    = sprite_attr_0_buf_dout[15] /* synthesis keep */;
wire [14:0] sprite_index    = sprite_attr_0_buf_dout[14:0] /* synthesis keep */;

wire [3:0] sprite_priority  = sprite_attr_1_buf_dout[15:12] /* synthesis keep */;
wire [5:0] sprite_size_addr = sprite_attr_1_buf_dout[11:6] /* synthesis keep */;
//reg [5:0] sprite_size_addr;

wire [5:0] sprite_pal_addr  = sprite_attr_1_buf_dout[5:0] /* synthesis keep */;

wire [8:0] sprite_pos_x  = sprite_attr_2_buf_dout[15:7]  ;
wire [8:0] sprite_pos_y  = sprite_attr_3_buf_dout[15:7] - 16/* synthesis keep */;

// valid 1 cycle after sprite attr ready
wire [8:0] sprite_height    = { sprite_size_dout[7:4], 3'b0 } /* synthesis keep */;  // in pixels
wire [8:0] sprite_width     = { sprite_size_dout[3:0], 3'b0 } /* synthesis keep */;

always @ (posedge clk_sys) begin
    
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
        if ( sprite_x < 319 ) begin
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
        if ( sprite_hidden == 0 && sprite_width > 0 && y >= sprite_pos_y && y < ( sprite_pos_y + sprite_height ) ) begin
            sprite_state <= 5 ;
        end else begin
            sprite_num <= sprite_num - 1;
            sprite_state <= 2 ;
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
        if ( sprite_pix > 0 && sprite_priority_buf[sprite_buf_x] < sprite_priority ) begin  
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

        scroll_y_latch[0] <= scroll_y[0] - scroll_ofs_y;
        scroll_y_latch[1] <= scroll_y[1] - scroll_ofs_y;
        scroll_y_latch[2] <= scroll_y[2] - scroll_ofs_y;
        scroll_y_latch[3] <= scroll_y[3] - scroll_ofs_y;
               
    end 
    
    if (  sprite_copy_state == 0 && vc == 240  ) begin 
        sprite_copy_state <= 1;
    end else if ( sprite_copy_state == 1 ) begin 
        sprite_num_copy <= 8'h00;
        sprite_copy_state <= 2 ;
    end else if ( sprite_copy_state == 2 ) begin
        sprite_buf_w <= 1;

        // wait for read from source
        sprite_copy_state <= 3 ;
    end else if ( sprite_copy_state == 3 ) begin
        sprite_buf_w <= 0;
        sprite_copy_state <= 2 ;
        
        if ( sprite_num_copy < 8'hff ) begin 
            sprite_num_copy <= sprite_num_copy + 1;
        end else begin
            sprite_copy_state <= 0; // till next time
        end
    end

    // tile state machine
    
    if ( draw_state == 0 && vc == 269 ) begin
        layer <= 3;
        y <= 0;
        draw_state <= 2;
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
            // force render of first layer.
            // don't draw transparent pixels
            if ( layer == 3 ) begin            
           
                tile_priority_buf[x] <= (tile_hidden == 1 || tile_pix == 0 ) ? 4'b0 : tile_priority;
                
                // if tile hidden then make the pallette index 0. ie transparent
                fb_din <= { layer, (tile_hidden == 1 || tile_pix == 0 ) ? 4'b0 : tile_priority, tile_palette_idx,  tile_pix };
                tile_fb_w <= 1;
            end else if (tile_hidden == 0 && tile_pix > 0 && tile_priority >= tile_priority_buf[x]) begin
                tile_priority_buf[x] <= tile_priority;
                
                // if tile hidden then make the pallette index 0. ie transparent
                fb_din <= { layer, tile_priority, tile_palette_idx,  tile_pix };
                tile_fb_w <= 1;
            end
            
            if ( x < 319 ) begin // 319
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
    if ( clk7_count == 5 ) begin
        tile_palette_addr   <= tile_fb_out[9:0] ; 
        sprite_palette_addr <= sprite_fb_out[9:0] ; 
    end else if ( clk7_count == 7 ) begin
        if ( vbl | hbl ) begin
            rgb_out <= 0;
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

wire prog_rom_1_data_valid;
wire prog_rom_2_data_valid;
wire tile_rom_data_valid;
wire sprite_rom_data_valid;
wire sound_rom_1_data_valid;

//wire prog_rom_1_cs;
wire prog_rom_1_oe;
wire [23:1] prog_rom_1_addr;
wire [15:0] prog_rom_1_data;
wire prog_rom_1_ctrl_valid;

//wire prog_rom_2_cs;
wire prog_rom_2_oe;
wire [23:1] prog_rom_2_addr;
wire [15:0] prog_rom_2_data;
wire prog_rom_2_ctrl_valid;

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

wire [23:0] rom_2_addr = cpu_a - 24'h040000  ;

// sdram priority based rom controller
// is a oe needed?
rom_controller rom_controller 
(
    .reset(reset),

    // clock
    .clk(clk_sys),

    // program ROM #1 interface
    .prog_rom_1_cs(prog_rom_1_cs),
    .prog_rom_1_oe(1),
    .prog_rom_1_addr(cpu_a[23:1]),
    .prog_rom_1_data(prog_rom_1_data),
    .prog_rom_1_data_valid(prog_rom_1_data_valid),

    // program ROM #2 interface
    .prog_rom_2_cs(prog_rom_2_cs),
    .prog_rom_2_oe(1),
    .prog_rom_2_addr( rom_2_addr[23:1] ),
    .prog_rom_2_data(prog_rom_2_data),
    .prog_rom_2_data_valid(prog_rom_2_data_valid),

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

ram256bx16dp sprite_ram_size (
    .clock_a ( clk_10M ),
    .address_a ( curr_sprite_ofs ),
    .wren_a ( sprite_size_cs  & !cpu_rw),
    .data_a ( cpu_dout ),
    .q_a ( sprite_size_cpu_dout ),

    .clock_b ( clk_sys ),
    .address_b ( sprite_size_addr ),
    .wren_b ( 0 ),
    .q_b ( sprite_size_dout )
    );    
    
  

    
// sprite attribute ram.  each tile attribute is 4 16bit words
// indirect access through offset register
// split up so 64 bits can be read in a single clock
ram256bx16dp sprite_ram_0_buf (
    .clock_a ( clk_sys ),
    .address_a ( sprite_num_copy ),
    .wren_a ( sprite_buf_w ),
    .data_a ( sprite_attr_0_dout[15:0] ),
    .q_a (  ),

    .clock_b ( clk_sys ),
    .address_b ( sprite_num ),
    .wren_b ( 0 ),
    .q_b ( sprite_attr_0_buf_dout[15:0] )
    );

ram256bx16dp sprite_ram_1_buf (
    .clock_a ( clk_sys ),
    .address_a ( sprite_num_copy ),
    .wren_a ( sprite_buf_w ),
    .data_a ( sprite_attr_1_dout[15:0] ),
    .q_a (  ),

    .clock_b ( clk_sys ),
    .address_b ( sprite_num ),
    .wren_b ( 0 ),
    .q_b ( sprite_attr_1_buf_dout[15:0] )
    );

ram256bx16dp sprite_ram_2_buf (
    .clock_a ( clk_sys ),
    .address_a ( sprite_num_copy ),
    .wren_a ( sprite_buf_w ),
    .data_a ( sprite_attr_2_dout[15:0] ),
    .q_a (  ),

    .clock_b ( clk_sys ),
    .address_b ( sprite_num ),
    .wren_b ( 0 ),
    .q_b ( sprite_attr_2_buf_dout[15:0] )
    );

ram256bx16dp sprite_ram_3_buf (
    .clock_a ( clk_sys ),
    .address_a ( sprite_num_copy ),
    .wren_a ( sprite_buf_w ),
    .data_a ( sprite_attr_3_dout[15:0] ),
    .q_a (  ),

    .clock_b ( clk_sys ),
    .address_b ( sprite_num ),
    .wren_b ( 0 ),
    .q_b ( sprite_attr_3_buf_dout[15:0] )
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

