///----------------------------------------------------------------------------
//
//  Copyright 2022 Darren Olafson
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


// simple 256 word read-only cache 
// specificly for 68k program rom.  todo - parameterize 
module cache
(
    input reset,
    input clk,
    output hit,

    input cache_req,
    input [22:0] cache_addr,

    output reg cache_valid,
    output reg [15:0] cache_data,

    input  [15:0] rom_data,
    input  rom_valid,
    
    output reg rom_req,
    output reg [22:0] rom_addr
);

reg [15:0]  data  [255:0];
reg [22:8]  tag   [255:0];
reg [255:0] valid ;
reg [1:0]   state = 0;

reg [7:0]   idx_r;

wire [7:0] idx = cache_addr[7:0];

// if tag value matches the upper bits of the address 
// and valid then no need to pass request to sdram 
assign hit = ( tag[idx] == cache_addr[22:8] && valid[idx] == 1 && state == 1 );

always @ (posedge clk) begin
    if ( reset == 1 ) begin
        state <= 0;
        // reset bits that indicate tag is valid
        valid <= 0;
    end else begin
        // if no read request then do nothing
        if ( cache_req == 0 ) begin
            cache_valid <= 0;
            rom_req <= 0;
            state <= 1;
        end else begin
            // if there is a hit then read from cache and say we are done
            if ( hit == 1 ) begin
                rom_req <= 0;
                cache_valid <= 1;
                cache_data  <= data[idx];
            end else if ( state == 1 ) begin
                // read from memory
                cache_valid <= 0;

                idx_r <= idx;
                
                // we need to read from sdram
                rom_req <= 1;
                rom_addr <= cache_addr;

                // next state is wait for rom ready
                state <= 2;

            end else if ( state == 2 && rom_valid == 1 ) begin
                // say we are done
                cache_valid <= 1;
                // update read value
                cache_data <= rom_data;

                // write updated tag
                tag[idx_r] <= rom_addr[22:8];
                // mark tag valid
                valid[idx_r] <= 1'b1;
                // update cache
                data[rom_addr[7:0]] <= rom_data;
                state <= 0;
            end
        end
    end
end


endmodule

