/*******************************************************************************
#   +html+<pre>
#
#   FILENAME: channels.sv
#   AUTHOR: Greg Taylor     CREATION DATE: 7 Nov 2014
#
#   DESCRIPTION:
#
#   CHANGE HISTORY:
#   7 Nov 2014    Greg Taylor
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

module channels
    import opl2_pkg::*;
(
    input wire clk,
    input wire reset,
    input wire clk_dac,
    input var opl2_reg_wr_t opl2_reg_wr,
    input wire sample_clk_en,
    output logic sample_valid,
    output logic signed [DAC_OUTPUT_WIDTH-1:0] sample
);
    localparam CHANNEL_OUT_WIDTH = OP_OUT_WIDTH + 2;

    // + 1 because we combine 2 channels together for left and right
    localparam CHANNEL_ACCUMULATOR_WIDTH = OP_OUT_WIDTH + $clog2(NUM_OPERATORS_PER_BANK*NUM_BANKS) + 1;

    operator_out_t operator_out;
    logic signed [OP_OUT_WIDTH-1:0] operator_mem_out;
    logic signed [SAMPLE_WIDTH-1:0] channel = 0;
    logic channel_valid = 0;
    logic ops_done_pulse;
    logic ryt = 0; // rhythm mode on/off
    logic cnt; // operator connection
    logic [REG_FB_WIDTH-1:0] fb_dummy;

    enum {
        IDLE,
        LOAD_2_OP_SECOND_0,
        LOAD_2_OP_SECOND_1,
        LOAD_2_OP_FIRST_AND_ACCUMULATE,
        DONE
    } state = IDLE, next_state;

    struct packed {
        logic signed [OP_OUT_WIDTH-1:0] operator_out_second;
        logic [$clog2(NUM_OPERATORS_PER_BANK)-1:0] op_num;
        logic [$clog2(NUM_CHANNELS_PER_BANK)-1:0] channel_num;
        logic signed [CHANNEL_ACCUMULATOR_WIDTH-1:0] channel_acc_pre_clamp;
    } self = 0, next_self;

    // verilator lint_off UNOPTFLAT
    struct packed {
        logic [$clog2(NUM_OPERATORS_PER_BANK)-1:0] op_mem_op_num;
        logic op_mem_rd;
        logic [$clog2(NUM_CHANNELS_PER_BANK)-1:0] cnt_mem_channel_num;
        logic signed [CHANNEL_OUT_WIDTH-1:0] channel_out;
        logic latch_channels;
    } signals;
    // verilator lint_on UNOPTFLAT

    always_ff @(posedge clk)
        if (opl2_reg_wr.valid && opl2_reg_wr.address == 'hBD)
            ryt <= opl2_reg_wr.data[5];

    mem_single_bank #(
        .DATA_WIDTH(1),
        .DEPTH('h9),
        .OUTPUT_DELAY(0),
        .DEFAULT_VALUE(0)
    ) cnt_mem (
        .clk,
        .wea(opl2_reg_wr.valid && opl2_reg_wr.address >= 'hC0 && opl2_reg_wr.address <= 'hC8),
        .reb('1),
        .addra(opl2_reg_wr.address[$clog2('h9)-1:0]),
        .addrb(signals.cnt_mem_channel_num),
        .dia(opl2_reg_wr.data[0]),
        .dob(cnt)
    );

    control_operators control_operators (
        .*
    );

    mem_single_bank #(
        .DATA_WIDTH(OP_OUT_WIDTH),
        .DEPTH(NUM_OPERATORS_PER_BANK),
        .OUTPUT_DELAY(1),
        .DEFAULT_VALUE(0)
    ) operator_out_mem (
        .clk,
        .wea(operator_out.valid),
        .reb(signals.op_mem_rd),
        .addra(operator_out.op_num),
        .addrb(signals.op_mem_op_num),
        .dia(operator_out.op_out),
        .dob(operator_mem_out)
    );

    always_ff @(posedge clk)
        if (sample_clk_en) begin
            state <= IDLE;
            self <= 0;
        end
        else begin
            state <= next_state;
            self <= next_self;
        end

    always_comb begin
        next_state = state;
        next_self = self;
        signals = 0;

        unique case (state)
        IDLE:
            // once operators are calculated for this sample, we can begin accumulating the channels
            if (ops_done_pulse)
                next_state = LOAD_2_OP_SECOND_0;
        LOAD_2_OP_SECOND_0: begin
            next_state = LOAD_2_OP_SECOND_1;
            signals.op_mem_op_num = self.op_num + 3;
            signals.op_mem_rd = 1;
        end
        LOAD_2_OP_SECOND_1: begin
            next_state = LOAD_2_OP_FIRST_AND_ACCUMULATE;
            next_self.operator_out_second = operator_mem_out;
            signals.op_mem_op_num = self.op_num;
            signals.op_mem_rd = 1;
        end
        LOAD_2_OP_FIRST_AND_ACCUMULATE: begin
            signals.cnt_mem_channel_num = self.channel_num;
            signals.channel_out = cnt ? operator_mem_out + self.operator_out_second : self.operator_out_second;
            if (ryt)
                unique case (self.channel_num)
                6:    signals.channel_out = self.operator_out_second*2; // bass drum
                7, 8: signals.channel_out = (operator_mem_out + self.operator_out_second)*2; // hi-hat and snare drum, tom-tom and top cymbal
                default:;
                endcase

            // OPL3 combines 4 channels into 2 in the analog domain in the YAC512. OPL2 is only 1 channel;
            // do not double output.
            next_self.channel_acc_pre_clamp = self.channel_acc_pre_clamp + signals.channel_out;

            if (self.channel_num == NUM_CHANNELS_PER_BANK - 1)
                next_state = DONE;
            else begin
                next_state = LOAD_2_OP_SECOND_0;
                unique case (self.channel_num)
                2:       next_self.op_num = 6;
                5:       next_self.op_num = 12;
                default: next_self.op_num = self.op_num + 1;
                endcase
                next_self.channel_num = self.channel_num + 1;
            end
        end
        DONE: begin
            next_state = IDLE;
            next_self = 0;
            signals.latch_channels = 1;
        end
        endcase
    end

    always_ff @(posedge clk)
        channel_valid <= signals.latch_channels;

    /*
     * Clamp output channels
     */
    always_ff @(posedge clk)
        if (signals.latch_channels) begin
            if (self.channel_acc_pre_clamp > 2**(SAMPLE_WIDTH - 1) - 1)
                channel <= 2**(SAMPLE_WIDTH - 1) - 1;
            else if (self.channel_acc_pre_clamp < -2**(SAMPLE_WIDTH - 1))
                channel <= -2**(SAMPLE_WIDTH - 1);
            else
                channel <= self.channel_acc_pre_clamp;
        end

    dac_prep dac_prep (
        .*
    );

endmodule
`default_nettype wire
