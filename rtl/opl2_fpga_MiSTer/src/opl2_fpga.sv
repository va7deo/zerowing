/*******************************************************************************
#   +html+<pre>
#
#   FILENAME: opl3.sv
#   AUTHOR: Greg Taylor     CREATION DATE: 24 Feb 2015
#
#   DESCRIPTION:
#
#   CHANGE HISTORY:
#   24 Feb 2015        Greg Taylor
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

module opl2_fpga
    import opl2_pkg::*;
(
    input wire clk, // opl3 master clk
    input wire clk_host, // if different from clk, set INSTANTIATE_MASTER_HOST_CDC to 1
    input wire clk_dac, // only used if INSTANTIATE_SAMPLE_DAC_CDC is set
    input wire ic_n, // reset, clk_host domain
    input wire cs_n, // clk_host domain
    input wire rd_n, // clk_host domain
    input wire wr_n, // clk_host domain
    input wire address, // clk_host domain
    input wire [REG_FILE_DATA_WIDTH-1:0] din, // clk_host domain
    output logic [REG_FILE_DATA_WIDTH-1:0] dout, // clk_host domain
    output logic sample_valid, // clk domain: if INSTANTIATE_SAMPLE_DAC_CDC ? clk_audio : clk
    output logic signed [DAC_OUTPUT_WIDTH-1:0] sample, // clk domain: if INSTANTIATE_SAMPLE_DAC_CDC ? clk_audio : clk
    output logic [NUM_LEDS-1:0] led, // master clk domain
    output logic irq_n // clk_host domain
);
    logic reset;
    logic sample_clk_en;
    opl2_reg_wr_t opl2_reg_wr;
    logic [REG_FILE_DATA_WIDTH-1:0] status;
    logic force_timer_overflow;

    reset_sync reset_sync (
        .clk,
        .arst_n(ic_n),
        .reset
    );

    host_if host_if (
        .*
    );

    // pulse once per sample period
    clk_div #(
        .CLK_DIV_COUNT(CLK_DIV_COUNT)
    ) sample_clk_gen (
        .clk_en(sample_clk_en),
        .*
    );

    channels channels (
        .*
    );

    leds leds (
        .*
    );

    /*
     * If we don't need timers, don't instantiate to save area
     */
    generate
    if (INSTANTIATE_TIMERS)
        timers timers (
            .*
        );
    else
        always_comb
            irq_n = 1;
    endgenerate
endmodule
`default_nettype wire
