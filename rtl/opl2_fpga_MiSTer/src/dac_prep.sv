/*******************************************************************************
#   +html+<pre>
#
#   FILENAME: dac_prep.sv
#   AUTHOR: Greg Taylor     CREATION DATE: 5 April 2024
#
#   DESCRIPTION: Add channels and optionally sync to host clk domain
#
#   CHANGE HISTORY:
#   5 April 2024    Greg Taylor
#       Initial version
#
#   Copyright (C) 2014 Greg Taylor <gtaylor@sonic.net>
#
#   This file is part of opl2 FPGA.
#
#   opl2 FPGA is free software: you can redistribute it and/or modify
#   it under the terms of the GNU Lesser General Public License as published by
#   the Free Software Foundation, either version 3 of the License, or
#   (at your option) any later version.
#
#   opl2 FPGA is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU Lesser General Public License for more details.
#
#   You should have received a copy of the GNU Lesser General Public License
#   along with opl2 FPGA.  If not, see <http://www.gnu.org/licenses/>.
#
#   Original Java Code:
#   Copyright (C) 2008 Robson Cozendey <robson@cozendey.com>
#
#   Original C++ Code:
#   Copyright (C) 2012  Steffen Ohrendorf <steffen.ohrendorf@gmx.de>
#
#   Some code based on forum posts in:
#   http://forums.submarine.org.uk/phpBB/viewforum.php?f=9,
#   Copyright (C) 2010-2013 by carbon14 and opl2
#
#******************************************************************************/
`timescale 1ns / 1ps
`default_nettype none

module dac_prep
    import opl2_pkg::*;
(
    input wire clk,
    input wire clk_dac,
    input wire channel_valid,
    input wire signed [SAMPLE_WIDTH-1:0] channel,
    output logic sample_valid,
    output logic signed [DAC_OUTPUT_WIDTH-1:0] sample
);
    logic sample_valid_opl2_p1 = 0;
    logic signed [DAC_OUTPUT_WIDTH-1:0] sample_opl2_p1 = 0;

    always_ff @(posedge clk) begin
        sample_valid_opl2_p1 <= channel_valid;
        sample_opl2_p1 <= channel <<< DAC_LEFT_SHIFT;
    end

    generate
    if (INSTANTIATE_SAMPLE_SYNC_TO_DAC_CLK) begin
        logic [2:0] sample_valid_opl2_pulse_extend;
        logic sample_valid_opl2_extended_pulse = 0;
        logic sample_valid_cpu_p0;
        logic sample_valid_cpu_p1 = 0;

        always_ff @(posedge clk) begin
            sample_valid_opl2_pulse_extend <= sample_valid_opl2_pulse_extend << 1;
            sample_valid_opl2_pulse_extend[0] <= sample_valid_opl2_p1;
            sample_valid_opl2_extended_pulse <= sample_valid_opl2_pulse_extend != 0;
        end

        synchronizer channel_valid_sync (
            .clk(clk_dac),
            .in(sample_valid_opl2_extended_pulse),
            .out(sample_valid_cpu_p0)
        );

        /*
        * opl2 channels are latched and held on channel_valid for a full sample period, so we only need to
        * synchronize the channel_valid bit and use to latch samples into cpu clock domain
        */
        always_ff @(posedge clk_dac) begin
            sample_valid_cpu_p1 <= sample_valid_cpu_p0;

            if (sample_valid_cpu_p0)
                sample <= sample_opl2_p1;

            sample_valid <= sample_valid_cpu_p0 && !sample_valid_cpu_p1;
        end
    end
    else
        always_comb begin
            sample_valid = sample_valid_opl2_p1;
            sample = sample_opl2_p1;
        end
    endgenerate
endmodule
`default_nettype wire
