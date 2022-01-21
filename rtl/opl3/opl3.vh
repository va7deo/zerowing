/*******************************************************************************
#   +html+<pre>
#
#   FILENAME: opl3_pkg.sv
#   AUTHOR: Greg Taylor     CREATION DATE: 13 Oct 2014
#
#   DESCRIPTION:
#   Generates a clk enable pulse based on the frequency specified by
#   OUTPUT_CLK_EN_FREQ.
#
#   CHANGE HISTORY:
#   13 Oct 2014        Greg Taylor
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
#   but WITHOUT ANY WARRANTY without even the implied warranty of
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

/******************************************************************************
# converted from systemVerilog to Verilog by Magnus Karlsson
*******************************************************************************/

`define REG_TIMER_WIDTH 8
`define REG_CONNECTION_SEL_WIDTH 6
`define REG_MULT_WIDTH 4
`define REG_FNUM_WIDTH 10
`define REG_BLOCK_WIDTH 3
`define REG_WS_WIDTH 3
`define REG_ENV_WIDTH 4
`define REG_TL_WIDTH 6
`define REG_KSL_WIDTH 2
`define REG_FB_WIDTH 3
    
`define SAMPLE_WIDTH 16
`define DAC_OUTPUT_WIDTH 24
`define ENV_WIDTH 9
`define OP_OUT_WIDTH 13
`define PHASE_ACC_WIDTH 20
`define AM_VAL_WIDTH 5
`define ENV_RATE_COUNTER_OVERFLOW_WIDTH 8
`define CHANNEL_ACCUMULATOR_WIDTH 19    
    
`define NUM_BANKS 2
`define NUM_OPERATORS_PER_BANK 18
`define NUM_CHANNELS_PER_BANK 9
`define BANK_NUM_WIDTH 1
`define OP_NUM_WIDTH 5

`define OP_NORMAL 0
`define OP_BASS_DRUM 1
`define OP_HI_HAT 2
`define OP_TOM_TOM 3
`define OP_SNARE_DRUM 4
`define OP_TOP_CYMBAL 5


