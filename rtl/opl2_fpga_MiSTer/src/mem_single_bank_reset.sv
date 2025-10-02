/*******************************************************************************
#   +html+<pre>
#
#   FILENAME: mem_single_bank_reset.sv
#   AUTHOR: Greg Taylor     CREATION DATE: 20 Sept 2025
#
#   DESCRIPTION:
#
#   CHANGE HISTORY:
#   20 Sept 2025    Greg Taylor
#       Initial version
#
#   Copyright (C) 2014 Greg Taylor <gtaylor@sonic.net>
#
#   This file is part of OPL3 FPGA.
#
#   OPL3 FPGA is free software: you can redistribute it and/or modify
#   it under the terms of the GNU Lesser General Public License as published by
#   the Free Software Foundation, either version 3 of the License, or
#   (at your option) any later version.
#
#   OPL3 FPGA is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU Lesser General Public License for more details.
#
#   You should have received a copy of the GNU Lesser General Public License
#   along with OPL3 FPGA.  If not, see <http://www.gnu.org/licenses/>.
#
#   Original Java Code:
#   Copyright (C) 2008 Robson Cozendey <robson@cozendey.com>
#
#   Original C++ Code:
#   Copyright (C) 2012  Steffen Ohrendorf <steffen.ohrendorf@gmx.de>
#
#   Some code based on forum posts in:
#   http://forums.submarine.org.uk/phpBB/viewforum.php?f=9,
#   Copyright (C) 2010-2013 by carbon14 and opl3
#
#******************************************************************************/
`timescale 1ns / 1ps
`default_nettype none
/* altera message_off 10230 */

module mem_single_bank_reset #(
    parameter DATA_WIDTH = 0,
    parameter DEPTH = 0,
    parameter OUTPUT_DELAY = 0, // 0, 1, or 2
    parameter DEFAULT_VALUE = '0
) (
    input wire clk,
    input wire reset,
    input wire reset_mem,
    input wire wea,
    input wire reb, // only used if OUTPUT_DELAY >0
    input wire [$clog2(DEPTH)-1:0] addra,
    input wire [$clog2(DEPTH)-1:0] addrb,
    input wire [DATA_WIDTH-1:0] dia,
    output logic [DATA_WIDTH-1:0] dob,
    output logic reset_mem_done_pulse
);
    enum {
        IDLE,
        RESETTING
    } state = IDLE, next_state;

    struct packed {
        logic [$clog2(DEPTH)-1:0] addr;
        logic reset_mem_done;
    } self = 0, next_self;

    always_ff @(posedge clk) begin
        state <= next_state;
        self <= next_self;

        if (reset) begin
            state <= IDLE;
            self <= 0;
        end
    end

    always_comb begin
        next_state = state;
        next_self = self;

        reset_mem_done_pulse = self.reset_mem_done;

        unique case (state)
        IDLE: begin
            if (reset_mem)
                next_state = RESETTING;
            next_self = 0;
        end
        RESETTING: begin
            if (self.addr == DEPTH - 1) begin
                next_state = IDLE;
                next_self.reset_mem_done = 1;
            end
            else
                next_self.addr = self.addr + 1;
        end
        endcase
    end

    mem_single_bank #(
        .DATA_WIDTH(DATA_WIDTH),
        .DEPTH(DEPTH),
        .OUTPUT_DELAY(OUTPUT_DELAY),
        .DEFAULT_VALUE(DEFAULT_VALUE)
    ) mem_single_bank (
        .clk,
        .wea(state == RESETTING || wea),
        .reb,
        .addra(state == RESETTING ? self.addr : addra),
        .addrb,
        .dia(state == RESETTING ? DEFAULT_VALUE : dia),
        .dob
    );
endmodule
`default_nettype wire
