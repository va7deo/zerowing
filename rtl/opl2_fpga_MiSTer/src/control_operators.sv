/*******************************************************************************
#   +html+<pre>
#
#   FILENAME: control_operators.sv
#   AUTHOR: Greg Taylor     CREATION DATE: 17 Nov 2014
#
#   DESCRIPTION:
#   Implement the state-machine for time-sharing operator resources across
#   all operator slots
#
#   CHANGE HISTORY:
#   17 Nov 2014    Greg Taylor
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
/* altera message_off 10958 */

module control_operators
    import opl2_pkg::*;
(
    input wire clk,
    input wire reset,
    input wire sample_clk_en,
    input var opl2_reg_wr_t opl2_reg_wr,
    input wire ryt,
    output operator_out_t operator_out,
    output logic ops_done_pulse = 0
);
    localparam PIPELINE_DELAY = 6;
    localparam MODULATION_DELAY = 1; // output of operator 0 must be ready by cycle 2 of operator 3 so it can modulate it
    localparam NUM_OPERATOR_UPDATE_STATES = NUM_BANKS*NUM_OPERATORS_PER_BANK + 1; // 36 operators + idle state
    logic [$clog2(MODULATION_DELAY)-1:0] delay_counter = 0;

    logic [$clog2(NUM_OPERATOR_UPDATE_STATES)-1:0] state = 0;
    logic [$clog2(NUM_OPERATOR_UPDATE_STATES)-1:0] next_state;

    logic [OP_NUM_WIDTH-1:0] op_num;
    logic [OP_NUM_WIDTH-1:0] op_num_p1 = 0;

    logic use_feedback_p1 = 0;
    logic signed [OP_OUT_WIDTH-1:0] modulation_p1;
    logic signed [OP_OUT_WIDTH-1:0] out_p6;
    logic signed [OP_OUT_WIDTH-1:0] modulation_out_p1;

    logic op_sample_clk_en;
    logic [PIPELINE_DELAY:1] op_sample_clk_en_p;
    logic [PIPELINE_DELAY:1] [OP_NUM_WIDTH-1:0] op_num_p;
    logic ryt_p1 = 0;

    logic am;  // amplitude modulation (tremolo on/off)
    logic vib; // vibrato on/off
    logic egt; // envelope type (select sustain/decay)
    logic ksr; // key scale rate
    logic [REG_MULT_WIDTH-1:0] mult; // frequency data multiplier
    logic [REG_KSL_WIDTH-1:0] ksl;   // key scale level
    logic [REG_TL_WIDTH-1:0] tl;     // total level (modulation, volume setting)
    logic [REG_ENV_WIDTH-1:0] ar;    // attack rate
    logic [REG_ENV_WIDTH-1:0] dr;    // decay rate
    logic [REG_ENV_WIDTH-1:0] sl;    // sustain level
    logic [REG_ENV_WIDTH-1:0] rr;    // release rate
    logic [REG_WS_WIDTH-1:0] ws;     // waveform select
    logic [$clog2('h16)-1:0] operator_mem_rd_address;

    logic [REG_FNUM_WIDTH-1:0] fnum;   // f-number (scale data within the octave)
    logic [REG_BLOCK_WIDTH-1:0] block; // octave data
    logic kon;                         // key-on (sound generation on/off)
    logic [REG_FB_WIDTH-1:0] fb_p1;       // feedback (modulation for slot 1 FM feedback)
    logic cnt_p1;                         // operator connection
    logic [$clog2('h9)-1:0] kon_block_fnum_channel_mem_rd_address;
    logic [$clog2('h9)-1:0] fb_cnt_channel_mem_rd_address;

    logic nts = 0; // keyboard split selection
    logic dvb = 0; // vibrato depth
    logic dam = 0; // depth of tremolo
    logic bd = 0;  // bass drum key-on
    logic sd = 0;  // snare drum key-on
    logic tom = 0; // tom-tom key-on
    logic tc = 0;  // top-cymbal key-on
    logic hh = 0;  // hi-hat key-on

    always_ff @(posedge clk)
        if (opl2_reg_wr.valid) begin
            if (opl2_reg_wr.address == 8)
                nts <= opl2_reg_wr.data[6];

            if (opl2_reg_wr.address == 'hBD) begin
                dam <= opl2_reg_wr.data[7];
                dvb <= opl2_reg_wr.data[6];
                bd  <= opl2_reg_wr.data[4];
                sd  <= opl2_reg_wr.data[3];
                tom <= opl2_reg_wr.data[2];
                tc  <= opl2_reg_wr.data[1];
                hh  <= opl2_reg_wr.data[0];
            end
        end

    always_comb
        if (op_num < 6)
            operator_mem_rd_address = op_num;
        else if (op_num < 12)
            operator_mem_rd_address = op_num + 2;
        else
            operator_mem_rd_address = op_num + 4;

    mem_single_bank #(
        .DATA_WIDTH(REG_FILE_DATA_WIDTH),
        .DEPTH('h16),
        .OUTPUT_DELAY(0),
        .DEFAULT_VALUE(0)
    ) am_vib_egt_ksr_mult_mem (
        .clk,
        .wea(opl2_reg_wr.valid && opl2_reg_wr.address >= 'h20 && opl2_reg_wr.address <= 'h35),
        .reb(op_sample_clk_en),
        .addra(opl2_reg_wr.address[$clog2('h16)-1:0]),
        .addrb(operator_mem_rd_address),
        .dia(opl2_reg_wr.data),
        .dob({am, vib, egt, ksr, mult})
    );

    mem_single_bank #(
        .DATA_WIDTH(REG_FILE_DATA_WIDTH),
        .DEPTH('h16),
        .OUTPUT_DELAY(0),
        .DEFAULT_VALUE(0)
    ) ksl_tl_mem (
        .clk,
        .wea(opl2_reg_wr.valid && opl2_reg_wr.address >= 'h40 && opl2_reg_wr.address <= 'h55),
        .reb(op_sample_clk_en),
        .addra(opl2_reg_wr.address[$clog2('h16)-1:0]),
        .addrb(operator_mem_rd_address),
        .dia(opl2_reg_wr.data),
        .dob({ksl, tl})
    );

    mem_single_bank #(
        .DATA_WIDTH(REG_FILE_DATA_WIDTH),
        .DEPTH('h16),
        .OUTPUT_DELAY(0),
        .DEFAULT_VALUE(0)
    ) ar_dr_mem (
        .clk,
        .wea(opl2_reg_wr.valid && opl2_reg_wr.address >= 'h60 && opl2_reg_wr.address <= 'h75),
        .reb(op_sample_clk_en),
        .addra(opl2_reg_wr.address[$clog2('h16)-1:0]),
        .addrb(operator_mem_rd_address),
        .dia(opl2_reg_wr.data),
        .dob({ar, dr})
    );

    mem_single_bank #(
        .DATA_WIDTH(REG_FILE_DATA_WIDTH),
        .DEPTH('h16),
        .OUTPUT_DELAY(0),
        .DEFAULT_VALUE(0)
    ) sl_rr_mem (
        .clk,
        .wea(opl2_reg_wr.valid && opl2_reg_wr.address >= 'h80 && opl2_reg_wr.address <= 'h95),
        .reb(op_sample_clk_en),
        .addra(opl2_reg_wr.address[$clog2('h16)-1:0]),
        .addrb(operator_mem_rd_address),
        .dia(opl2_reg_wr.data),
        .dob({sl, rr})
    );

    mem_single_bank #(
        .DATA_WIDTH(REG_WS_WIDTH),
        .DEPTH('h16),
        .OUTPUT_DELAY(0),
        .DEFAULT_VALUE(0)
    ) ws_mem (
        .clk,
        .wea(opl2_reg_wr.valid && opl2_reg_wr.address >= 'hE0 && opl2_reg_wr.address <= 'hF5),
        .reb(op_sample_clk_en),
        .addra(opl2_reg_wr.address[$clog2('h16)-1:0]),
        .addrb(operator_mem_rd_address),
        .dia(opl2_reg_wr.data[REG_WS_WIDTH-1:0]),
        .dob(ws)
    );

    always_comb begin
        unique case (op_num)
        0, 3: begin
            kon_block_fnum_channel_mem_rd_address = 0;
            fb_cnt_channel_mem_rd_address = 0;
        end
        1, 4: begin
            kon_block_fnum_channel_mem_rd_address = 1;
            fb_cnt_channel_mem_rd_address = 1;
        end
        2, 5: begin
            kon_block_fnum_channel_mem_rd_address = 2;
            fb_cnt_channel_mem_rd_address = 2;
        end
        6, 9: begin
            kon_block_fnum_channel_mem_rd_address = 3;
            fb_cnt_channel_mem_rd_address = 3;
        end
        7, 10: begin
            kon_block_fnum_channel_mem_rd_address = 4;
            fb_cnt_channel_mem_rd_address = 4;
        end
        8, 11: begin
            kon_block_fnum_channel_mem_rd_address = 5;
            fb_cnt_channel_mem_rd_address = 5;
        end
        12, 15: begin
            kon_block_fnum_channel_mem_rd_address = 6;
            fb_cnt_channel_mem_rd_address = 6;
        end
        13, 16: begin
            kon_block_fnum_channel_mem_rd_address = 7;
            fb_cnt_channel_mem_rd_address = 7;
        end
        14, 17: begin
            kon_block_fnum_channel_mem_rd_address = 8;
            fb_cnt_channel_mem_rd_address = 8;
        end
        endcase
    end

    mem_single_bank #(
        .DATA_WIDTH(REG_FILE_DATA_WIDTH),
        .DEPTH('h9),
        .OUTPUT_DELAY(0),
        .DEFAULT_VALUE(0)
    ) fnum_low_mem (
        .clk,
        .wea(opl2_reg_wr.valid && opl2_reg_wr.address >= 'hA0 && opl2_reg_wr.address <= 'hA8),
        .reb(op_sample_clk_en),
        .addra(opl2_reg_wr.address[$clog2('h9)-1:0]),
        .addrb(kon_block_fnum_channel_mem_rd_address),
        .dia(opl2_reg_wr.data),
        .dob(fnum[7:0])
    );

    // store kon in separate memory that is wrapped in reset state machine, so kon goes low on
    // reset, bringing envelope into RELEASE state
    mem_single_bank_reset #(
        .DATA_WIDTH(1),
        .DEPTH('h9),
        .OUTPUT_DELAY(0),
        .DEFAULT_VALUE(0)
    ) kon_mem (
        .clk,
        .reset('0),
        .reset_mem(reset),
        .wea(opl2_reg_wr.valid && opl2_reg_wr.address >= 'hB0 && opl2_reg_wr.address <= 'hB8),
        .reb(op_sample_clk_en),
        .addra(opl2_reg_wr.address[$clog2('h9)-1:0]),
        .addrb(kon_block_fnum_channel_mem_rd_address),
        .dia(opl2_reg_wr.data[5]),
        .dob(kon),
        .reset_mem_done_pulse()
    );

    localparam block_fnum_high_mem_width = $bits(block) + $bits(fnum[9:8]);

    mem_single_bank #(
        .DATA_WIDTH(block_fnum_high_mem_width),
        .DEPTH('h9),
        .OUTPUT_DELAY(0),
        .DEFAULT_VALUE(0)
    ) block_fnum_high_mem (
        .clk,
        .wea(opl2_reg_wr.valid && opl2_reg_wr.address >= 'hB0 && opl2_reg_wr.address <= 'hB8),
        .reb(op_sample_clk_en),
        .addra(opl2_reg_wr.address[$clog2('h9)-1:0]),
        .addrb(kon_block_fnum_channel_mem_rd_address),
        .dia(opl2_reg_wr.data[block_fnum_high_mem_width-1:0]),
        .dob({block, fnum[9:8]})
    );

    localparam fb_cnt_mem_width = $bits(fb_p1) + $bits(cnt_p1);

    mem_single_bank #(
        .DATA_WIDTH(fb_cnt_mem_width),
        .DEPTH('h9),
        .OUTPUT_DELAY(1),
        .DEFAULT_VALUE(0)
    ) fb_cnt_mem (
        .clk,
        .wea(opl2_reg_wr.valid && opl2_reg_wr.address >= 'hC0 && opl2_reg_wr.address <= 'hC8),
        .reb(op_sample_clk_en),
        .addra(opl2_reg_wr.address[$clog2('h9)-1:0]),
        .addrb(fb_cnt_channel_mem_rd_address),
        .dia(opl2_reg_wr.data[fb_cnt_mem_width-1:0]),
        .dob({fb_p1, cnt_p1})
    );

    always_ff @(posedge clk)
        unique case (op_num)
        0, 1, 2, 6, 7, 8, 12:           use_feedback_p1 <= 1;
        3, 4, 5, 9, 10, 11, 15, 16, 17: use_feedback_p1 <= 0;
        13, 14:                         use_feedback_p1 <= !ryt; // hi-hat and tom-tom do not use feedback
        endcase

    always_ff @(posedge clk) begin
        ryt_p1 <= ryt;
        op_num_p1 <= op_num;
    end

    always_comb
        unique case (op_num_p1)
        0, 1, 2, 6, 7, 8, 12, 13, 14: modulation_p1 = 0;
        3, 4, 5, 9, 10, 11, 15:       modulation_p1 = cnt_p1 ? 0 : modulation_out_p1;
        16, 17:                       modulation_p1 = cnt_p1 || ryt_p1 ? 0 : modulation_out_p1; // snare drum and top cymbal do not use modulation
        endcase

    always_ff @(posedge clk)
        state <= next_state;

    always_comb
        if (state == 0)
            next_state = sample_clk_en;
        else if (delay_counter == MODULATION_DELAY) begin
            if (state == NUM_OPERATOR_UPDATE_STATES - 1)
                next_state = 0;
            else
                next_state = state + 1;
        end
        else
            next_state = state;

    always_ff @(posedge clk)
        if (next_state != state)
            delay_counter <= 0;
        else if (delay_counter == MODULATION_DELAY)
            delay_counter <= 0;
        else
            delay_counter <= delay_counter + 1;

    always_comb
        if (state == 0)
            op_num = 0;
        else if (state > NUM_OPERATORS_PER_BANK)
            op_num = state - NUM_OPERATORS_PER_BANK - 1;
        else
            op_num = state - 1;

    always_comb op_sample_clk_en = state != 0 && delay_counter == 0;

    /*
     * The sample_clk_en input for each operator slot is pulsed in the first
     * cycle of that time slot. Operator is fully pipelined so we can issue
     * back to back.
     */
    operator operator (
        .sample_clk_en(op_sample_clk_en),
        .*
    );

    pipeline_sr #(
        .ENDING_CYCLE(PIPELINE_DELAY)
    ) sample_clk_en_sr (
        .clk,
        .in(op_sample_clk_en),
        .out(op_sample_clk_en_p)
    );

    pipeline_sr #(
        .DATA_WIDTH(OP_NUM_WIDTH),
        .ENDING_CYCLE(PIPELINE_DELAY)
    ) op_num_sr (
        .clk,
        .in(op_num),
        .out(op_num_p)
    );

    // This has to perfectly line up with the output of operator 0 and the input of operator 3, etc.
    // It's a function of the PIPELINE_DELAY of the operator, the MODULATION_DELAY parameter, and
    // modulation is required on cycle 1 of the operator.
    always_ff @(posedge clk)
        modulation_out_p1 <= out_p6;

    ERROR_operators_not_aligned_for_modulation:
    assert property (@(posedge clk)
        op_sample_clk_en && op_num == 3 |-> operator_out.valid && operator_out.op_num == 0);

    always_comb begin
        operator_out.valid = op_sample_clk_en_p[6];
        operator_out.op_num = op_num_p[6];
        operator_out.op_out = out_p6;
    end

    always_ff @(posedge clk)
        ops_done_pulse <= operator_out.valid && operator_out.op_num == 17;
endmodule
`default_nettype wire
