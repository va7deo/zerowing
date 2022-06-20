//

module chip_select
(
    input  [7:0] pcb,

    input [23:0] cpu_a,
    input        cpu_as_n,

    input [15:0] z80_addr,
    input        MREQ_n,
    input        IORQ_n,

    // M68K selects
    output       prog_rom_cs,
    output       ram_cs,
    output       scroll_ofs_x_cs,
    output       scroll_ofs_y_cs,
    output       frame_done_cs,
    output       int_en_cs,
    output       crtc_cs,
    output       tile_ofs_cs,
    output       tile_attr_cs,
    output       tile_num_cs,
    output       scroll_cs,
    output       shared_ram_cs,
    output       vblank_cs,
    output       tile_palette_cs,
    output       bcu_flip_cs,
    output       sprite_palette_cs,
    output       sprite_ofs_cs,
    output       sprite_cs,
    output       sprite_size_cs,
    output       sprite_ram_cs,
    output       fcu_flip_cs,
    output       reset_z80_cs,

    // Z80 selects
    output       z80_p1_cs,
    output       z80_p2_cs,
    output       z80_dswa_cs,
    output       z80_dswb_cs,
    output       z80_system_cs,
    output       z80_tjump_cs,
    output       z80_sound0_cs,
    output       z80_sound1_cs,

    // other params
    output reg [15:0] scroll_y_offset
    
);

localparam pcb_zero_wing     = 0;
localparam pcb_out_zone_conv = 1;
localparam pcb_out_zone      = 2;
localparam pcb_hellfire      = 3;
localparam pcb_truxton       = 4;
localparam pcb_fireshark     = 5;
localparam pcb_vimana        = 6;
localparam pcb_rallybike     = 7;

function m68k_cs;
        input [23:0] base_address;
        input  [7:0] width;
begin
	m68k_cs = ( cpu_a >> width == base_address >> width ) & !cpu_as_n;
end
endfunction

function z80_cs;
        input [7:0] address_lo;
begin
	z80_cs = ( IORQ_n == 0 && z80_addr[7:0] == address_lo );
end
endfunction

always @(*) begin

    if (pcb == pcb_zero_wing || pcb == pcb_hellfire) begin
        scroll_y_offset = 16;
    end else begin
        scroll_y_offset = 0;
    end


    // Setup lines depending on pcb
    case (pcb)
        pcb_out_zone_conv, pcb_zero_wing: begin
            prog_rom_cs       = m68k_cs( 'h000000, 19 );
            
            ram_cs            = m68k_cs( 'h080000, 15 );
            
            scroll_ofs_x_cs   = m68k_cs( 'h0c0000,  1 );
            scroll_ofs_y_cs   = m68k_cs( 'h0c0002,  1 );
            fcu_flip_cs       = m68k_cs( 'h0c0006,  1 );
            
            vblank_cs         = m68k_cs( 'h400000,  1 );
            int_en_cs         = m68k_cs( 'h400002,  1 );
            crtc_cs           = m68k_cs( 'h400008,  3 );
            
            tile_palette_cs   = m68k_cs( 'h404000, 11 );
            sprite_palette_cs = m68k_cs( 'h406000, 11 );
            
            shared_ram_cs     = m68k_cs( 'h440000, 12 );

            bcu_flip_cs       = m68k_cs( 'h480000,  1 );
            tile_ofs_cs       = m68k_cs( 'h480002,  1 );
            tile_attr_cs      = m68k_cs( 'h480004,  1 );
            tile_num_cs       = m68k_cs( 'h480006,  1 );
            scroll_cs         = m68k_cs( 'h480010,  4 );
            
            frame_done_cs     = m68k_cs( 'h4c0000,  1 );
            sprite_ofs_cs     = m68k_cs( 'h4c0002,  1 );
            sprite_cs         = m68k_cs( 'h4c0004,  1 );
            sprite_size_cs    = m68k_cs( 'h4c0006,  1 );

            reset_z80_cs      = 0;

            z80_p1_cs         = z80_cs( 8'h00 );
            z80_p2_cs         = z80_cs( 8'h08 );
            z80_dswa_cs       = z80_cs( 8'h20 );
            z80_dswb_cs       = z80_cs( 8'h28 );
            z80_system_cs     = z80_cs( 8'h80 );
            z80_tjump_cs      = z80_cs( 8'h88 );
            z80_sound0_cs     = z80_cs( 8'ha8 );
            z80_sound1_cs     = z80_cs( 8'ha9 );
        end

        pcb_out_zone: begin
            prog_rom_cs       = m68k_cs( 'h000000, 18 );

            frame_done_cs     = m68k_cs( 'h100000,  1 );
            sprite_ofs_cs     = m68k_cs( 'h100002,  1 );
            sprite_cs         = m68k_cs( 'h100004,  1 );
            sprite_size_cs    = m68k_cs( 'h100006,  1 );

            shared_ram_cs     = m68k_cs( 'h140000, 12 );
            
            tile_ofs_cs       = m68k_cs( 'h200002,  1 );
            tile_attr_cs      = m68k_cs( 'h200004,  1 );
            tile_num_cs       = m68k_cs( 'h200006,  1 );
            bcu_flip_cs       = m68k_cs( 'h200000,  1 );
            scroll_cs         = m68k_cs( 'h200010,  4 );

            ram_cs            = m68k_cs( 'h240000, 14 );
            
            vblank_cs         = m68k_cs( 'h300000,  1 );
            int_en_cs         = m68k_cs( 'h300002,  1 );
            crtc_cs           = m68k_cs( 'h300008,  3 );

            tile_palette_cs   = m68k_cs( 'h304000, 11 );
            sprite_palette_cs = m68k_cs( 'h306000, 11 );
            
            scroll_ofs_x_cs   = m68k_cs( 'h340000,  1 );
            scroll_ofs_y_cs   = m68k_cs( 'h340002,  1 );
            fcu_flip_cs       = m68k_cs( 'h340006,  1 );

            z80_p1_cs         = z80_cs( 8'h14 );
            z80_p2_cs         = z80_cs( 8'h18 );
            z80_dswa_cs       = z80_cs( 8'h08 );
            z80_dswb_cs       = z80_cs( 8'h0c );
            z80_system_cs     = z80_cs( 8'h10 );
            z80_tjump_cs      = z80_cs( 8'h1c );
            z80_sound0_cs     = z80_cs( 8'h00 );
            z80_sound1_cs     = z80_cs( 8'h01 );
        end

        pcb_hellfire: begin
            prog_rom_cs       = m68k_cs( 'h000000, 18 );
            
            ram_cs            = m68k_cs( 'h040000, 15 );
            
            shared_ram_cs     = m68k_cs( 'h0c0000, 12 );
            
            vblank_cs         = m68k_cs( 'h080000,  1 );
            int_en_cs         = m68k_cs( 'h080002,  1 );
            crtc_cs           = m68k_cs( 'h080008,  3 );
            
            tile_palette_cs   = m68k_cs( 'h084000, 11 );
            sprite_palette_cs = m68k_cs( 'h086000, 11 );

            bcu_flip_cs       = m68k_cs( 'h100000,  1 );
            tile_ofs_cs       = m68k_cs( 'h100002,  1 );
            tile_attr_cs      = m68k_cs( 'h100004,  1 );
            tile_num_cs       = m68k_cs( 'h100006,  1 );
            scroll_cs         = m68k_cs( 'h100010,  4 );
            
            scroll_ofs_x_cs   = m68k_cs( 'h180000,  1 );
            scroll_ofs_y_cs   = m68k_cs( 'h180002,  1 );
            fcu_flip_cs       = m68k_cs( 'h180006,  1 );
            reset_z80_cs      = m68k_cs( 'h180008,  1 );
            
            frame_done_cs     = m68k_cs( 'h140000,  1 );
            sprite_ofs_cs     = m68k_cs( 'h140002,  1 );
            sprite_cs         = m68k_cs( 'h140004,  1 );
            sprite_size_cs    = m68k_cs( 'h140006,  1 );

            z80_p1_cs         = z80_cs( 8'h40 );
            z80_p2_cs         = z80_cs( 8'h50 );
            z80_dswa_cs       = z80_cs( 8'h00 );
            z80_dswb_cs       = z80_cs( 8'h10 );
            z80_system_cs     = z80_cs( 8'h60 );
            z80_tjump_cs      = z80_cs( 8'h20 );
            z80_sound0_cs     = z80_cs( 8'h70 );
            z80_sound1_cs     = z80_cs( 8'h71 );
        end

        pcb_truxton: begin
            prog_rom_cs       = m68k_cs( 'h000000, 18 );
            ram_cs            = m68k_cs( 'h080000, 14 );
            
            frame_done_cs     = m68k_cs( 'h0c0000,  1 );
            sprite_ofs_cs     = m68k_cs( 'h0c0002,  1 );
            sprite_cs         = m68k_cs( 'h0c0004,  1 );
            sprite_size_cs    = m68k_cs( 'h0c0006,  1 );

            shared_ram_cs     = m68k_cs( 'h180000, 12 );
            vblank_cs         = m68k_cs( 'h140000,  1 );
            int_en_cs         = m68k_cs( 'h140002,  1 );
            crtc_cs           = m68k_cs( 'h140008,  3 );
            tile_palette_cs   = m68k_cs( 'h144000, 11 );
            sprite_palette_cs = m68k_cs( 'h146000, 11 );
            
            bcu_flip_cs       = m68k_cs( 'h100000,  1 );
            tile_ofs_cs       = m68k_cs( 'h100002,  1 );
            tile_attr_cs      = m68k_cs( 'h100004,  1 );
            tile_num_cs       = m68k_cs( 'h100006,  1 );
            scroll_cs         = m68k_cs( 'h100010,  4 );
            
            scroll_ofs_x_cs   = m68k_cs( 'h1c0000,  1 );
            scroll_ofs_y_cs   = m68k_cs( 'h1c0002,  1 );
            fcu_flip_cs       = m68k_cs( 'h1c0006,  1 );
            
            reset_z80_cs      = m68k_cs( 'h1d0000,  1 );

            z80_p1_cs         = z80_cs( 8'h00 );
            z80_p2_cs         = z80_cs( 8'h10 );
            z80_dswa_cs       = z80_cs( 8'h40 );
            z80_dswb_cs       = z80_cs( 8'h50 );
            z80_system_cs     = z80_cs( 8'h20 );
            z80_tjump_cs      = z80_cs( 8'h70 );
            z80_sound0_cs     = z80_cs( 8'h60 );
            z80_sound1_cs     = z80_cs( 8'h61 );
        end

        pcb_vimana: begin
            prog_rom_cs       = m68k_cs( 'h000000, 19 );
            
            scroll_ofs_x_cs   = m68k_cs( 'h1c0000,  1 );
            scroll_ofs_y_cs   = m68k_cs( 'h1c0002,  1 );
            fcu_flip_cs       = m68k_cs( 'h1c0006,  1 );
            
            frame_done_cs     = m68k_cs( 'h0c0000,  1 );
            sprite_ofs_cs     = m68k_cs( 'h0c0002,  1 );
            sprite_cs         = m68k_cs( 'h0c0004,  1 );
            sprite_size_cs    = m68k_cs( 'h0c0006,  1 );
            
            vblank_cs         = m68k_cs( 'h400000,  1 );
            int_en_cs         = m68k_cs( 'h400002,  1 );
            crtc_cs           = m68k_cs( 'h400008,  3 );
            
            tile_palette_cs   = m68k_cs( 'h404000, 11 );
            sprite_palette_cs = m68k_cs( 'h406000, 11 );
            
            shared_ram_cs     = m68k_cs( 'h440000, 12 );
            
            ram_cs            = m68k_cs( 'h480000, 15 );

            bcu_flip_cs       = m68k_cs( 'h4c0000,  1 );
            tile_ofs_cs       = m68k_cs( 'h4c0002,  1 );
            tile_attr_cs      = m68k_cs( 'h4c0004,  1 );
            tile_num_cs       = m68k_cs( 'h4c0006,  1 );
            scroll_cs         = m68k_cs( 'h4c0010,  4 );

            z80_p1_cs         = z80_cs( 8'h80 );
            z80_p2_cs         = z80_cs( 8'h81 );
            z80_dswa_cs       = z80_cs( 8'h82 );
            z80_system_cs     = z80_cs( 8'h83 );
            z80_dswb_cs       = z80_cs( 8'h84 );
            z80_sound0_cs     = z80_cs( 8'h87 );
            z80_sound1_cs     = z80_cs( 8'h8f );
        end

        pcb_rallybike: begin
            prog_rom_cs       = m68k_cs( 'h000000, 19 );
            ram_cs            = m68k_cs( 'h080000, 14 );
            sprite_ram_cs     = m68k_cs( 'h0c0000, 12 );

            bcu_flip_cs       = m68k_cs( 'h100000,  1 );
            tile_ofs_cs       = m68k_cs( 'h100002,  1 );
            tile_attr_cs      = m68k_cs( 'h100004,  1 );
            tile_num_cs       = m68k_cs( 'h100006,  1 );
            scroll_cs         = m68k_cs( 'h100010,  4 );

            vblank_cs         = m68k_cs( 'h140000,  1 );
            frame_done_cs     = 1'b0;
            int_en_cs         = m68k_cs( 'h140002,  1 );
            crtc_cs           = m68k_cs( 'h140008,  3 );
            
            tile_palette_cs   = m68k_cs( 'h144000, 11 );
            sprite_palette_cs = m68k_cs( 'h146000, 11 );

            
            shared_ram_cs     = m68k_cs( 'h180000, 12 );
            
            scroll_ofs_x_cs   = m68k_cs( 'h1c0000,  1 );
            scroll_ofs_y_cs   = m68k_cs( 'h1c0002,  1 );
            
            reset_z80_cs      = m68k_cs( 'h1c8000,  1 );
            
            fcu_flip_cs       = 1'b0;  // no fcu
            sprite_ofs_cs     = 1'b0;
            sprite_cs         = 1'b0;
            sprite_size_cs    = 1'b0;

            z80_p1_cs         = z80_cs( 8'h00 );
            z80_p2_cs         = z80_cs( 8'h10 );
            z80_system_cs     = z80_cs( 8'h20 );
            z80_dswa_cs       = z80_cs( 8'h40 );
            z80_dswb_cs       = z80_cs( 8'h50 );
            z80_tjump_cs      = 1'b0;
            z80_sound0_cs     = z80_cs( 8'h60 );
            z80_sound1_cs     = z80_cs( 8'h61 );
            
//	map(0x00, 0x00).portr("P1");
//	map(0x10, 0x10).portr("P2");
//	map(0x20, 0x20).portr("SYSTEM");
//	map(0x30, 0x30).w("coinlatch", FUNC(ls259_device::write_nibble_d0));  /* Coin counter/lockout */
//	map(0x40, 0x40).portr("DSWA");
//	map(0x50, 0x50).portr("DSWB");
//	map(0x60, 0x61).rw("ymsnd", FUNC(ym3812_device::read), FUNC(ym3812_device::write));            
    
        end

        default:;
    endcase
end

endmodule
