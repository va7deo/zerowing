/*******************************************************************************
#   +html+<pre>
#
#   FILENAME: opl3.sv
#   AUTHOR: Greg Taylor     CREATION DATE: 13 Oct 2014
#
#   DESCRIPTION:
#
#   CHANGE HISTORY:
#   13 Oct 2014    Greg Taylor
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

/******************************************************************************
#
# Converted from systemVerilog to Verilog
# Copyright (C) 2018 Magnus Karlsson <magnus@saanlima.com>
#
*******************************************************************************/

`include "opl3.vh"

module opl3(
  clk,
  clk_opl3,
  opl3_we,
  opl3_data,
  opl3_adr,
  channel_a,
  channel_b,
  channel_c,
  channel_d
  );

input         clk;
input         clk_opl3;
input         opl3_we;
input [7:0]   opl3_data;
input [8:0]   opl3_adr;
output signed [15:0] channel_a;
output signed [15:0] channel_b;
output signed [15:0] channel_c;
output signed [15:0] channel_d;

localparam OPERATOR_PIPELINE_DELAY = 7; 
localparam NUM_OPERATOR_UPDATE_STATES = `NUM_BANKS*`NUM_OPERATORS_PER_BANK + 1; // 36 operators + idle state

reg [7:0] opl3_reg[511:0];

reg [8:0] cntr;
reg sample_clk_en;

reg nts;

reg [17:0] am[1:0];
reg [17:0] vib[1:0];
reg [17:0] egt[1:0];
reg [17:0] ksr[1:0];
reg [3:0] mult[1:0][17:0];

reg [1:0] ksl[1:0][17:0];
reg [5:0] tl[1:0][17:0];

reg [3:0] ar[1:0][17:0];
reg [3:0] dr[1:0][17:0];

reg [3:0] sl[1:0][17:0];
reg [3:0] rr[1:0][17:0];

reg [9:0] fnum[1:0][8:0];

reg [8:0] kon[1:0];
reg [2:0] block[1:0][8:0];

reg dam;
reg dvb;
reg ryt;
reg bd;
reg sd;
reg tom;
reg tc;
reg hh;

reg [8:0] chd[1:0];
reg [8:0] chc[1:0];
reg [8:0] chb[1:0];
reg [8:0] cha[1:0];
reg [2:0] fb[1:0][8:0];
reg [8:0] cnt[1:0];

reg [2:0] ws[1:0][17:0];

reg [5:0] connection_sel;
reg is_new;

reg [9:0] fnum_tmp[1:0][17:0];
reg [2:0] block_tmp[1:0][17:0];
reg [2:0] fb_tmp[1:0][17:0];
reg [2:0] op_type_tmp[1:0][17:0];
reg [17:0] kon_tmp[1:0];
reg [17:0] use_feedback[1:0];
reg signed [12:0] modulation[1:0][17:0] ;

reg [$clog2(OPERATOR_PIPELINE_DELAY)-1:0] delay_counter;

reg [$clog2(NUM_OPERATOR_UPDATE_STATES)-1:0] delay_state;
reg [$clog2(NUM_OPERATOR_UPDATE_STATES)-1:0] next_delay_state;
    
wire [$clog2(`NUM_BANKS)-1:0] bank_num;
reg [$clog2(`NUM_OPERATORS_PER_BANK)-1:0] op_num;

wire signed [12:0] operator_out_tmp;
reg signed [12:0] operator_out[1:0][17:0];

wire latch_feedback_pulse;

parameter
    IDLE = 0,
    CALC_OUTPUTS = 1;
  
reg calc_state = IDLE; 
reg next_calc_state;
  
reg [3:0] channel;
reg bank = 0; 

reg signed [`SAMPLE_WIDTH-1:0] channel_2_op[1:0][8:0];
reg signed [`SAMPLE_WIDTH-1:0] channel_4_op[1:0][2:0];

    always @(posedge clk_opl3) begin
        cntr <= cntr == 9'd287 ? 9'd0 : cntr + 1'b1;
        sample_clk_en <= cntr == 9'd0;
    end

    always @ (posedge clk) begin
        if (opl3_we) begin
            opl3_reg[opl3_adr] <= opl3_data;
        end
    end
 
    localparam BANK2_OFFSET = 256;
  
  /*
   * Registers that are not specific to a particular bank
   */
    always @(posedge clk_opl3) begin
        if (sample_clk_en) begin
            connection_sel <= opl3_reg[BANK2_OFFSET+4][`REG_CONNECTION_SEL_WIDTH-1:0];
      
            is_new <= opl3_reg[BANK2_OFFSET+5][0];
            nts <= opl3_reg[8][6];
      
            dam <= opl3_reg['hBD][7];
            dvb <= opl3_reg['hBD][6];
            ryt <= opl3_reg['hBD][5];
            bd  <= opl3_reg['hBD][4];
            sd  <= opl3_reg['hBD][3];
            tom <= opl3_reg['hBD][2];
            tc  <= opl3_reg['hBD][1];
            hh  <= opl3_reg['hBD][0];                 
        end
    end
       
    genvar i, j;
    generate 
        for (i = 0; i < 2; i = i + 1) begin : i_block 
        
            for (j = 0; j < 6; j = j + 1) begin : j0_block
                always @(posedge clk_opl3) begin
                    if (sample_clk_en) begin
                        am[i][j]   <= opl3_reg['h20+j+i*BANK2_OFFSET][7];
                        vib[i][j]  <= opl3_reg['h20+j+i*BANK2_OFFSET][6];
                        egt[i][j]  <= opl3_reg['h20+j+i*BANK2_OFFSET][5];
                        ksr[i][j]  <= opl3_reg['h20+j+i*BANK2_OFFSET][4];
                        mult[i][j] <= opl3_reg['h20+j+i*BANK2_OFFSET][3:0];
                
                        ksl[i][j] <= opl3_reg['h40+j+i*BANK2_OFFSET][7:6];
                        tl[i][j]  <= opl3_reg['h40+j+i*BANK2_OFFSET][5:0];
                
                        ar[i][j] <= opl3_reg['h60+j+i*BANK2_OFFSET][7:4];
                        dr[i][j] <= opl3_reg['h60+j+i*BANK2_OFFSET][3:0]; 
                
                        sl[i][j] <= opl3_reg['h80+j+i*BANK2_OFFSET][7:4];
                        rr[i][j] <= opl3_reg['h80+j+i*BANK2_OFFSET][3:0];
                
                        ws[i][j] <= opl3_reg['hE0+j+i*BANK2_OFFSET][2:0];           
                    end
                end
            end
        
            for (j = 6; j < 12; j = j + 1) begin : j1_block 
                always @(posedge clk_opl3) begin 
                    if (sample_clk_en) begin         
                        am[i][j]   <= opl3_reg['h22+j+i*BANK2_OFFSET][7];
                        vib[i][j]  <= opl3_reg['h22+j+i*BANK2_OFFSET][6];
                        egt[i][j]  <= opl3_reg['h22+j+i*BANK2_OFFSET][5];
                        ksr[i][j]  <= opl3_reg['h22+j+i*BANK2_OFFSET][4];
                        mult[i][j] <= opl3_reg['h22+j+i*BANK2_OFFSET][3:0];
                      
                        ksl[i][j] <= opl3_reg['h42+j+i*BANK2_OFFSET][7:6];
                        tl[i][j]  <= opl3_reg['h42+j+i*BANK2_OFFSET][5:0];
                      
                        ar[i][j] <= opl3_reg['h62+j+i*BANK2_OFFSET][7:4];
                        dr[i][j] <= opl3_reg['h62+j+i*BANK2_OFFSET][3:0];
                      
                        sl[i][j] <= opl3_reg['h82+j+i*BANK2_OFFSET][7:4];
                        rr[i][j] <= opl3_reg['h82+j+i*BANK2_OFFSET][3:0];            
                      
                        ws[i][j] <= opl3_reg['hE2+j+i*BANK2_OFFSET][2:0];         
                    end
                end
            end
        
            for (j = 12; j < 18; j = j + 1) begin : j2_block 
                always @(posedge clk_opl3) begin
                    if (sample_clk_en) begin            
                        am[i][j]   <= opl3_reg['h24+j+i*BANK2_OFFSET][7];
                        vib[i][j]  <= opl3_reg['h24+j+i*BANK2_OFFSET][6];
                        egt[i][j]  <= opl3_reg['h24+j+i*BANK2_OFFSET][5];
                        ksr[i][j]  <= opl3_reg['h24+j+i*BANK2_OFFSET][4];
                        mult[i][j] <= opl3_reg['h24+j+i*BANK2_OFFSET][3:0];
                      
                        ksl[i][j] <= opl3_reg['h44+j+i*BANK2_OFFSET][7:6];
                        tl[i][j]  <= opl3_reg['h44+j+i*BANK2_OFFSET][5:0];
                      
                        ar[i][j] <= opl3_reg['h64+j+i*BANK2_OFFSET][7:4];
                        dr[i][j] <= opl3_reg['h64+j+i*BANK2_OFFSET][3:0];
                      
                        sl[i][j] <= opl3_reg['h84+j+i*BANK2_OFFSET][7:4];
                        rr[i][j] <= opl3_reg['h84+j+i*BANK2_OFFSET][3:0];
                      
                        ws[i][j] <= opl3_reg['hE4+j+i*BANK2_OFFSET][2:0];         
                    end
                end
            end
        
            for (j = 0; j < 9; j = j + 1) begin : j3_block 
                always @(posedge clk_opl3) begin
                    if (sample_clk_en) begin
                        fnum[i][j][7:0] <= opl3_reg['hA0+j+i*BANK2_OFFSET];
                        fnum[i][j][9:8] <= opl3_reg['hB0+j+i*BANK2_OFFSET][1:0];

                        kon[i][j] <= opl3_reg['hB0+j+i*BANK2_OFFSET][5];
                        block[i][j] <= opl3_reg['hB0+j+i*BANK2_OFFSET][4:2];
                  
                        chd[i][j] <= opl3_reg['hC0+j+i*BANK2_OFFSET][7];
                        chc[i][j] <= opl3_reg['hC0+j+i*BANK2_OFFSET][6];
                        chb[i][j] <= opl3_reg['hC0+j+i*BANK2_OFFSET][5];
                        cha[i][j] <= opl3_reg['hC0+j+i*BANK2_OFFSET][4];
                        fb[i][j]  <= opl3_reg['hC0+j+i*BANK2_OFFSET][3:1];
                        cnt[i][j] <= opl3_reg['hC0+j+i*BANK2_OFFSET][0];                
                    end
                end
            end
        end
    endgenerate   


  always @ * begin
    /*
     * Operator input mappings
     * 
     * The first mappings are static whether the operator is configured
     * in a 2 channel or a 4 channel mode. Next we start mapping connections
     * for operators whose input varies depending on the mode.
     */
    op_type_tmp[0][0] = `OP_NORMAL;
    op_type_tmp[0][1] = `OP_NORMAL;
    op_type_tmp[0][2] = `OP_NORMAL;
    op_type_tmp[0][3] = `OP_NORMAL;
    op_type_tmp[0][4] = `OP_NORMAL;
    op_type_tmp[0][5] = `OP_NORMAL;
    op_type_tmp[0][6] = `OP_NORMAL;
    op_type_tmp[0][7] = `OP_NORMAL;
    op_type_tmp[0][8] = `OP_NORMAL;
    op_type_tmp[0][9] = `OP_NORMAL;
    op_type_tmp[0][10] = `OP_NORMAL;
    op_type_tmp[0][11] = `OP_NORMAL;
    op_type_tmp[1][0] = `OP_NORMAL;
    op_type_tmp[1][1] = `OP_NORMAL;
    op_type_tmp[1][2] = `OP_NORMAL;
    op_type_tmp[1][3] = `OP_NORMAL;
    op_type_tmp[1][4] = `OP_NORMAL;
    op_type_tmp[1][5] = `OP_NORMAL;
    op_type_tmp[1][6] = `OP_NORMAL;
    op_type_tmp[1][7] = `OP_NORMAL;
    op_type_tmp[1][8] = `OP_NORMAL;
    op_type_tmp[1][9] = `OP_NORMAL;
    op_type_tmp[1][10] = `OP_NORMAL;
    op_type_tmp[1][11] = `OP_NORMAL;
    op_type_tmp[1][12] = `OP_NORMAL;
    op_type_tmp[1][13] = `OP_NORMAL;
    op_type_tmp[1][14] = `OP_NORMAL;
    op_type_tmp[1][15] = `OP_NORMAL;
    op_type_tmp[1][16] = `OP_NORMAL;
    op_type_tmp[1][17] = `OP_NORMAL;

    fnum_tmp[0][0] = fnum[0][0];
    block_tmp[0][0] = block[0][0];
    kon_tmp[0][0] = kon[0][0];
    fb_tmp[0][0] = fb[0][0];
    use_feedback[0][0] = 1;
    modulation[0][0] = 0;
    
    fnum_tmp[0][3] = fnum[0][0];
    block_tmp[0][3] = block[0][0];
    kon_tmp[0][3] = kon[0][0];
    fb_tmp[0][3] = 0;
    use_feedback[0][3] = 0;
    modulation[0][3] = cnt[0][0] ? 0 : operator_out[0][0];
    
    fnum_tmp[0][1] = fnum[0][1];
    block_tmp[0][1] = block[0][1];
    kon_tmp[0][1] = kon[0][1];
    fb_tmp[0][1] = fb[0][1];
    use_feedback[0][1] = 1;
    modulation[0][1] = 0;
    
    fnum_tmp[0][4] = fnum[0][1];
    block_tmp[0][4] = block[0][1];
    kon_tmp[0][4] = kon[0][1];
    fb_tmp[0][4] = 0;
    use_feedback[0][4] = 0;
    modulation[0][4] = cnt[0][1] ? 0 : operator_out[0][1];
    
    fnum_tmp[0][2] = fnum[0][2];
    block_tmp[0][2] = block[0][2];
    kon_tmp[0][2] = kon[0][2];
    fb_tmp[0][2] = fb[0][2];
    use_feedback[0][2] = 1;
    modulation[0][2] = 0;
    
    fnum_tmp[0][5] = fnum[0][2];
    block_tmp[0][5] = block[0][2];
    kon_tmp[0][5] = kon[0][2];
    fb_tmp[0][5] = 0;
    use_feedback[0][5] = 0;
    modulation[0][5] = cnt[0][2] ? 0 : operator_out[0][2];
    
    fnum_tmp[1][0] = fnum[1][0];
    block_tmp[1][0] = block[1][0];
    kon_tmp[1][0] = kon[1][0];
    fb_tmp[1][0] = fb[1][0];
    use_feedback[1][0] = 1;
    modulation[1][0] = 0;
    
    fnum_tmp[1][3] = fnum[1][0];
    block_tmp[1][3] = block[1][0];
    kon_tmp[1][3] = kon[1][0];
    fb_tmp[1][3] = 0;
    use_feedback[1][3] = 0;
    modulation[1][3] = cnt[1][0] ? 0 : operator_out[1][0];
    
    fnum_tmp[1][1] = fnum[1][1];
    block_tmp[1][1] = block[1][1];
    kon_tmp[1][1] = kon[1][1];
    fb_tmp[1][1] = fb[1][1];
    use_feedback[1][1] = 1;
    modulation[1][1] = 0;
    
    fnum_tmp[1][4] = fnum[1][1];
    block_tmp[1][4] = block[1][1];
    kon_tmp[1][4] = kon[1][1];
    fb_tmp[1][4] = 0;
    use_feedback[1][4] = 0;
    modulation[1][4] = cnt[1][1] ? 0 : operator_out[1][1];
    
    fnum_tmp[1][2] = fnum[1][2];
    block_tmp[1][2] = block[1][2];
    kon_tmp[1][2] = kon[1][2];
    fb_tmp[1][2] = fb[1][2];
    use_feedback[1][2] = 1;
    modulation[1][2] = 0;
    
    fnum_tmp[1][5] = fnum[1][2];
    block_tmp[1][5] = block[1][2];
    kon_tmp[1][5] = kon[1][2];
    fb_tmp[1][5] = 0;
    use_feedback[1][5] = 0;
    modulation[1][5] = cnt[1][2] ? 0 : operator_out[1][2];
    
    // aka bass drum operator 1
    fnum_tmp[0][12] = fnum[0][6];
    block_tmp[0][12] = block[0][6];
    kon_tmp[0][12] = kon[0][6];
    fb_tmp[0][12] = fb[0][6];
    op_type_tmp[0][12] = ryt ? `OP_BASS_DRUM : `OP_NORMAL;
    use_feedback[0][12] = 1;
    modulation[0][12] = 0;
    
    // aka bass drum operator 2
    fnum_tmp[0][15] = fnum[0][6];
    block_tmp[0][15] = block[0][6];
    kon_tmp[0][15] = kon[0][6];
    fb_tmp[0][15] = 0;
    op_type_tmp[0][15] = ryt ? `OP_BASS_DRUM : `OP_NORMAL;
    use_feedback[0][15] = 0;
    modulation[0][15] = cnt[0][6] ? 0 : operator_out[0][12];
    
    // aka hi hat operator
    fnum_tmp[0][13] = fnum[0][7];
    block_tmp[0][13] = block[0][7];
    kon_tmp[0][13] = kon[0][7];
    fb_tmp[0][13] = ryt ? 0 : fb[0][7];
    op_type_tmp[0][13] = ryt ? `OP_HI_HAT : `OP_NORMAL;
    use_feedback[0][13] = ryt ? 0 : 1;
    modulation[0][13] = 0;
    
    // aka snare drum operator
    fnum_tmp[0][16] = fnum[0][7];
    block_tmp[0][16] = block[0][7];
    kon_tmp[0][16] = kon[0][7];
    fb_tmp[0][16] = 0;
    op_type_tmp[0][16] = ryt ? `OP_SNARE_DRUM : `OP_NORMAL;        
    use_feedback[0][16] = 0;
    modulation[0][16] = cnt[0][7] || ryt ? 0 : operator_out[0][13];
    
    // aka tom tom operator
    fnum_tmp[0][14] = fnum[0][8];
    block_tmp[0][14] = block[0][8];
    kon_tmp[0][14] = kon[0][8];
    fb_tmp[0][14] = ryt ? 0 : fb[0][8];
    op_type_tmp[0][14] = ryt ? `OP_TOM_TOM : `OP_NORMAL;        
    use_feedback[0][14] = ryt ? 0 : 1;
    modulation[0][14] = 0;
    
    // aka top cymbal operator
    fnum_tmp[0][17] = fnum[0][8];
    block_tmp[0][17] = block[0][8];
    kon_tmp[0][17] = kon[0][8];
    fb_tmp[0][17] = 0;
    op_type_tmp[0][17] = ryt ? `OP_TOP_CYMBAL : `OP_NORMAL;
    use_feedback[0][17] = 0;
    modulation[0][17] = cnt[0][8] || ryt ? 0 : operator_out[0][14];
    
    fnum_tmp[1][12] = fnum[1][6];
    block_tmp[1][12] = block[1][6];
    kon_tmp[1][12] = kon[1][6];
    fb_tmp[1][12] = fb[1][6];
    use_feedback[1][12] = 1;
    modulation[1][12] = 0;
    
    fnum_tmp[1][15] = fnum[1][6];
    block_tmp[1][15] = block[1][6];
    kon_tmp[1][15] = kon[1][6];
    fb_tmp[1][15] = 0;
    use_feedback[1][15] = 0;
    modulation[1][15] = cnt[1][6] ? 0 : operator_out[1][12];
    
    fnum_tmp[1][13] = fnum[1][7];
    block_tmp[1][13] = block[1][7];
    kon_tmp[1][13] = kon[1][7];
    fb_tmp[1][13] = fb[1][7];
    use_feedback[1][13] = 1;
    modulation[1][13] = 0;
    
    fnum_tmp[1][16] = fnum[1][7];
    block_tmp[1][16] = block[1][7];
    kon_tmp[1][16] = kon[1][7];
    fb_tmp[1][16] = 0;
    use_feedback[1][16] = 0;
    modulation[1][16] = cnt[1][7] ? 0 : operator_out[1][13];
    
    fnum_tmp[1][14] = fnum[1][8];
    block_tmp[1][14] = block[1][8];
    kon_tmp[1][14] = kon[1][8];
    fb_tmp[1][14] = fb[1][8];
    use_feedback[1][14] = 1;
    modulation[1][14] = 0;
    
    fnum_tmp[1][17] = fnum[1][8];
    block_tmp[1][17] = block[1][8];
    kon_tmp[1][17] = kon[1][8];
    fb_tmp[1][17] = 0;  
    use_feedback[1][17] = 0;
    modulation[1][17] = cnt[1][8] ? 0 : operator_out[1][14];

    if (connection_sel[0]) begin
      fnum_tmp[0][6] = fnum[0][0];
      block_tmp[0][6] = block[0][0];
      kon_tmp[0][6] = kon[0][0];
      fb_tmp[0][6] = 0;
      use_feedback[0][6] = 0;
      modulation[0][6] = !cnt[0][0] && cnt[0][3] ? 0 : operator_out[0][3]; 
  
      fnum_tmp[0][9] = fnum[0][0];
      block_tmp[0][9] = block[0][0];
      kon_tmp[0][9] = kon[0][0];
      fb_tmp[0][9] = 0;
      use_feedback[0][9] = 0;
      modulation[0][9] = cnt[0][0] && cnt[0][3] ? 0 : operator_out[0][6];
    end
    else begin
      fnum_tmp[0][6] = fnum[0][3];
      block_tmp[0][6] = block[0][3];
      kon_tmp[0][6] = kon[0][3];
      fb_tmp[0][6] = fb[0][3];
      use_feedback[0][6] = 1;
      modulation[0][6] = 0;
  
      fnum_tmp[0][9] = fnum[0][3];
      block_tmp[0][9] = block[0][3];
      kon_tmp[0][9] = kon[0][3];
      fb_tmp[0][9] = 0; 
      use_feedback[0][9] = 0;
      modulation[0][9] = cnt[0][3] ? 0 : operator_out[0][6];
    end
    if (connection_sel[1]) begin
      fnum_tmp[0][7] = fnum[0][1];
      block_tmp[0][7] = block[0][1];
      kon_tmp[0][7] = kon[0][1];
      fb_tmp[0][7] = 0;
      use_feedback[0][7] = 0;
      modulation[0][7] = !cnt[0][1] && cnt[0][4] ? 0 : operator_out[0][4]; 
  
      fnum_tmp[0][10] = fnum[0][1];
      block_tmp[0][10] = block[0][1];
      kon_tmp[0][10] = kon[0][1];
      fb_tmp[0][10] = 0;
      use_feedback[0][10] = 0;
      modulation[0][10] = cnt[0][1] && cnt[0][4] ? 0 : operator_out[0][7];
    end
    else begin
      fnum_tmp[0][7] = fnum[0][4];
      block_tmp[0][7] = block[0][4];
      kon_tmp[0][7] = kon[0][4];
      fb_tmp[0][7] = fb[0][4];
      use_feedback[0][7] = 1;
      modulation[0][7] = 0;
      
      fnum_tmp[0][10] = fnum[0][4];
      block_tmp[0][10] = block[0][4];
      kon_tmp[0][10] = kon[0][4];
      fb_tmp[0][10] = 0;
      use_feedback[0][10] = 0;
      modulation[0][10] = cnt[0][4] ? 0 : operator_out[0][7];
    end
    if (connection_sel[2]) begin
      fnum_tmp[0][8] = fnum[0][2];
      block_tmp[0][8] = block[0][2];
      kon_tmp[0][8] = kon[0][2];
      fb_tmp[0][8] = 0;
      use_feedback[0][8] = 0;
      modulation[0][8] = !cnt[0][2] && cnt[0][5] ? 0 : operator_out[0][5];             
  
      fnum_tmp[0][11] = fnum[0][2];
      block_tmp[0][11] = block[0][2];
      kon_tmp[0][11] = kon[0][2];
      fb_tmp[0][11] = 0;
      use_feedback[0][11] = 0;
      modulation[0][11] = cnt[0][2] && cnt[0][5] ? 0 : operator_out[0][8];
    end
    else begin
      fnum_tmp[0][8] = fnum[0][5];
      block_tmp[0][8] = block[0][5];
      kon_tmp[0][8] = kon[0][5];
      fb_tmp[0][8] = fb[0][5];
      use_feedback[0][8] = 1;
      modulation[0][8] = 0;
  
      fnum_tmp[0][11] = fnum[0][5];
      block_tmp[0][11] = block[0][5];
      kon_tmp[0][11] = kon[0][5];
      fb_tmp[0][11] = 0;   
      use_feedback[0][11] = 0;
      modulation[0][11] = cnt[0][5] ? 0 : operator_out[0][8];
    end
    if (connection_sel[3]) begin
      fnum_tmp[1][6] = fnum[1][0];
      block_tmp[1][6] = block[1][0];
      kon_tmp[1][6] = kon[1][0];
      fb_tmp[1][6] = 0;
      use_feedback[1][6] = 0;
      modulation[1][6] = !cnt[1][0] && cnt[1][3] ? 0 : operator_out[1][3];            
  
      fnum_tmp[1][9] = fnum[1][0];
      block_tmp[1][9] = block[1][0];
      kon_tmp[1][9] = kon[1][0];
      fb_tmp[1][9] = 0;
      use_feedback[1][9] = 0;
      modulation[1][9] = cnt[1][0] && cnt[1][3] ? 0 : operator_out[1][6];           
    end
    else begin
      fnum_tmp[1][6] = fnum[1][3];
      block_tmp[1][6] = block[1][3];
      kon_tmp[1][6] = kon[1][3];
      fb_tmp[1][6] = fb[1][3];
      use_feedback[1][6] = 1;
      modulation[1][6] = 0;
  
      fnum_tmp[1][9] = fnum[1][3];
      block_tmp[1][9] = block[1][3];
      kon_tmp[1][9] = kon[1][3];
      fb_tmp[1][9] = 0; 
      use_feedback[1][9] = 0;
      modulation[1][9] = cnt[1][3] ? 0 : operator_out[1][6];
    end
    if (connection_sel[4]) begin
      fnum_tmp[1][7] = fnum[1][1];
      block_tmp[1][7] = block[1][1];
      kon_tmp[1][7] = kon[1][1];
      fb_tmp[1][7] = 0;
      use_feedback[1][7] = 0;
      modulation[1][7] = !cnt[1][1] && cnt[1][4] ? 0 : operator_out[1][4];            
  
      fnum_tmp[1][10] = fnum[1][1];
      block_tmp[1][10] = block[1][1];
      kon_tmp[1][10] = kon[1][1];
      fb_tmp[1][10] = 0;
      use_feedback[1][10] = 0;
      modulation[1][10] = cnt[1][1] && cnt[1][4] ? 0 : operator_out[1][7]; 
    end
    else begin
      fnum_tmp[1][7] = fnum[1][4];
      block_tmp[1][7] = block[1][4];
      kon_tmp[1][7] = kon[1][4];
      fb_tmp[1][7] = fb[1][4];
      use_feedback[1][7] = 1;
      modulation[1][7] = 0;
  
      fnum_tmp[1][10] = fnum[1][4];
      block_tmp[1][10] = block[1][4];
      kon_tmp[1][10] = kon[1][4];
      fb_tmp[1][10] = 0;   
      use_feedback[1][10] = 0;
      modulation[1][10] = cnt[1][4] ? 0 : operator_out[1][7];
    end
    if (connection_sel[5]) begin
      fnum_tmp[1][8] = fnum[1][2];
      block_tmp[1][8] = block[1][2];
      kon_tmp[1][8] = kon[1][2];
      fb_tmp[1][8] = 0;
      use_feedback[1][8] = 0;
      modulation[1][8] = !cnt[1][2] && cnt[1][5] ? 0 : operator_out[1][5];            
  
      fnum_tmp[1][11] = fnum[1][2];
      block_tmp[1][11] = block[1][2];
      kon_tmp[1][11] = kon[1][2];
      fb_tmp[1][11] = 0;
      use_feedback[1][11] = 0;
      modulation[1][11] = cnt[1][2] && cnt[1][5] ? 0 : operator_out[1][8]; 
    end
    else begin
      fnum_tmp[1][8] = fnum[1][5];
      block_tmp[1][8] = block[1][5];
      kon_tmp[1][8] = kon[1][5];
      fb_tmp[1][8] = fb[1][5];
      use_feedback[1][8] = 1;
      modulation[1][8] = 0;
  
      fnum_tmp[1][11] = fnum[1][5];
      block_tmp[1][11] = block[1][5];
      kon_tmp[1][11] = kon[1][5];
      fb_tmp[1][11] = 0; 
      use_feedback[1][11] = 0;
      modulation[1][11] = cnt[1][5] ? 0 : operator_out[1][8];
    end
  end

  always @(posedge clk_opl3)
      delay_state <= next_delay_state;
      
  always @ *
    if (delay_state == 0)
      next_delay_state = sample_clk_en ? 1 : 0;
    else if (delay_counter == OPERATOR_PIPELINE_DELAY - 1)
      if (delay_state == NUM_OPERATOR_UPDATE_STATES - 1)
        next_delay_state = 0;
      else
        next_delay_state = delay_state + 1;
    else
      next_delay_state = delay_state;
      
  always @(posedge clk_opl3)
    if (next_delay_state != delay_state)
      delay_counter <= 0;
    else if (delay_counter == OPERATOR_PIPELINE_DELAY - 1)
      delay_counter <= 0;
    else
      delay_counter <= delay_counter + 1;
      
  assign bank_num = delay_state > `NUM_OPERATORS_PER_BANK;

  always @ * 
    if (delay_state == 0)
      op_num = 0;
    else if (delay_state > `NUM_OPERATORS_PER_BANK)
      op_num = delay_state - `NUM_OPERATORS_PER_BANK - 1;
    else
      op_num = delay_state - 1;

  /*
   * One operator is instantiated; it replicates the necessary registers for
   * all operator slots (phase accumulation, envelope state and value, etc).
   */    
  operator operator_inst(
    .clk(clk_opl3),
    .sample_clk_en(delay_state != 0 && delay_counter == 0),
    .is_new(is_new),    
    .bank_num(bank_num),
    .op_num(op_num),              
    .fnum(fnum_tmp[bank_num][op_num]),
    .mult(mult[bank_num][op_num]),
    .block(block_tmp[bank_num][op_num]),
    .ws(ws[bank_num][op_num]),
    .vib(vib[bank_num][op_num]),
    .dvb(dvb),
    .kon_bank0(kon_tmp[0]),
    .kon_bank1(kon_tmp[1]),    
    .ar(ar[bank_num][op_num]),
    .dr(dr[bank_num][op_num]),
    .sl(sl[bank_num][op_num]),
    .rr(rr[bank_num][op_num]),
    .tl(tl[bank_num][op_num]),
    .ksr(ksr[bank_num][op_num]),
    .ksl(ksl[bank_num][op_num]),
    .egt(egt[bank_num][op_num]),
    .am(am[bank_num][op_num]),
    .dam(dam),
    .nts(nts),
    .bd(bd),
    .sd(sd),
    .tom(tom),
    .tc(tc),
    .hh(hh),        
    .use_feedback(use_feedback[bank_num][op_num]),
    .fb(fb_tmp[bank_num][op_num]),
    .modulation(modulation[bank_num][op_num]),
    .latch_feedback_pulse(latch_feedback_pulse),
    .op_type(op_type_tmp[bank_num][op_num]),
    .out(operator_out_tmp)
  );   

  generate
  for (i = 0; i < `NUM_BANKS; i = i + 1)  begin: delayi
    for (j = 0; j < `NUM_OPERATORS_PER_BANK; j = j + 1)   begin: delayj
      /*
       * Capture output from operator in the last cycle of the time slot
       */
      always @(posedge clk_opl3)
        if (i == bank_num && j == op_num &&
         delay_counter == OPERATOR_PIPELINE_DELAY - 1)
            operator_out[i][j] <= operator_out_tmp;
    end
  end
  endgenerate 

  /*
   * Signals to operator to latch output for feedback register
   */
  assign
    latch_feedback_pulse = delay_counter == OPERATOR_PIPELINE_DELAY - 1;     
  
  /*
   * Each channel is accumulated (can be up to 19 bits) and then clamped to
   * 16-bits.
   */
  reg signed [`CHANNEL_ACCUMULATOR_WIDTH-1:0] channel_a_acc_pre_clamp = 0;
  reg signed [`CHANNEL_ACCUMULATOR_WIDTH-1:0] channel_a_acc_pre_clamp_p[1:0][8:0];    
  reg signed [`CHANNEL_ACCUMULATOR_WIDTH-1:0] channel_b_acc_pre_clamp = 0;
  reg signed [`CHANNEL_ACCUMULATOR_WIDTH-1:0] channel_b_acc_pre_clamp_p[1:0][8:0];
  reg signed [`CHANNEL_ACCUMULATOR_WIDTH-1:0] channel_c_acc_pre_clamp = 0;
  reg signed [`CHANNEL_ACCUMULATOR_WIDTH-1:0] channel_c_acc_pre_clamp_p[1:0][8:0];        
  reg signed [`CHANNEL_ACCUMULATOR_WIDTH-1:0] channel_d_acc_pre_clamp = 0;
  reg signed [`CHANNEL_ACCUMULATOR_WIDTH-1:0] channel_d_acc_pre_clamp_p[1:0][8:0];

  reg signed [`SAMPLE_WIDTH-1:0] channel_a = 0;
  reg signed [`SAMPLE_WIDTH-1:0] channel_b = 0;
  reg signed [`SAMPLE_WIDTH-1:0] channel_c = 0;
  reg signed [`SAMPLE_WIDTH-1:0] channel_d = 0;
  
  always @(posedge clk_opl3)
    calc_state <= next_calc_state;
    
  always @ *
    case (calc_state)
    IDLE: next_calc_state = sample_clk_en ? CALC_OUTPUTS : IDLE;
    CALC_OUTPUTS: next_calc_state = bank == 1 && channel == 8 ? IDLE : CALC_OUTPUTS;
    endcase
      
  always @(posedge clk_opl3)
    if (calc_state == IDLE || channel == 8)
      channel <= 0;
    else
      channel <= channel + 1;
      
  always @(posedge clk_opl3)
    if (calc_state == IDLE)
      bank <= 0;
    else if (channel == 8)
      bank <= 1;     

  generate      
      for (i = 0; i < `NUM_BANKS; i = i  + 1) begin : banks
        /*
         * 2 operator channel output connections
         */
        always @ * begin
          channel_2_op[i][0] = cnt[i][0] ? operator_out[i][0] + operator_out[i][3]
           : operator_out[i][3];
          channel_2_op[i][1] = cnt[i][1] ? operator_out[i][1] + operator_out[i][4]
           : operator_out[i][4];
          channel_2_op[i][2] = cnt[i][2] ? operator_out[i][2] + operator_out[i][5]
           : operator_out[i][5];    
          channel_2_op[i][3] = cnt[i][3] ? operator_out[i][6] + operator_out[i][9]
           : operator_out[i][9];
          channel_2_op[i][4] = cnt[i][4] ? operator_out[i][7] + operator_out[i][10]
           : operator_out[i][10];
          channel_2_op[i][5] = cnt[i][5] ? operator_out[i][8] + operator_out[i][11]
           : operator_out[i][11];
          
          if (ryt && i == 0)         
            // bass drum is special (bank 0)
            channel_2_op[i][6] = cnt[i][6] ? operator_out[i][15] : operator_out[i][12];
          else
            channel_2_op[i][6] = cnt[i][6] ? operator_out[i][12] + operator_out[i][15]
             : operator_out[i][15];
          
          // aka hi hat and snare drum in bank 0
          channel_2_op[i][7] = cnt[i][7] || (ryt && i == 0) ? operator_out[i][13] + operator_out[i][16]
           : operator_out[i][16];   
          
          // aka tom tom and top cymbal in bank 0
          channel_2_op[i][8] = cnt[i][8] || (ryt && i == 0)  ? operator_out[i][14] + operator_out[i][17]
           : operator_out[i][17];
        end
      
        /*
         * 4 operator channel output connections
         */
        always @ * begin
          case ({cnt[i][0], cnt[i][3]})
          'b00: channel_4_op[i][0] = operator_out[i][9];
          'b01: channel_4_op[i][0] = operator_out[i][3] + operator_out[i][9];
          'b10: channel_4_op[i][0] = operator_out[i][0] + operator_out[i][9];
          'b11: channel_4_op[i][0] = operator_out[i][0] + operator_out[i][6] + operator_out[i][9];
          endcase
            
          case ({cnt[i][1], cnt[i][4]})
          'b00: channel_4_op[i][1] = operator_out[i][10];
          'b01: channel_4_op[i][1] = operator_out[i][4] + operator_out[i][10];
          'b10: channel_4_op[i][1] = operator_out[i][1] + operator_out[i][10];
          'b11: channel_4_op[i][1] = operator_out[i][1] + operator_out[i][7] + operator_out[i][10];
          endcase
            
          case ({cnt[i][2], cnt[i][5]})
          'b00: channel_4_op[i][2] = operator_out[i][11];
          'b01: channel_4_op[i][2] = operator_out[i][5] + operator_out[i][11];
          'b10: channel_4_op[i][2] = operator_out[i][2] + operator_out[i][11];
          'b11: channel_4_op[i][2] = operator_out[i][2] + operator_out[i][8] + operator_out[i][11];
          endcase 
        end
      end 
  endgenerate    
    
    generate
        for (i = 0; i < 3; i = i + 1) begin : block_0
            always @(posedge clk_opl3) begin
                if (cha[0][i] || !is_new) begin
                    channel_a_acc_pre_clamp_p[0][i] <= connection_sel[i] && is_new ? channel_4_op[0][i] : channel_2_op[0][i];
                end else begin
                    channel_a_acc_pre_clamp_p[0][i] <= 0;
                end
            end
        end
            
        for (i = 3; i < 6; i = i + 1) begin : block_1
            always @(posedge clk_opl3) begin
                if (cha[0][i] || !is_new) begin
                    channel_a_acc_pre_clamp_p[0][i] <= channel_2_op[0][i];
                end else begin
                    channel_a_acc_pre_clamp_p[0][i] <= 0;
                end
            end
        end
        
        for (i = 6; i < 9; i = i + 1) begin : block_2
            always @(posedge clk_opl3) begin
                if (cha[0][i] || !is_new) begin
                    channel_a_acc_pre_clamp_p[0][i] <= channel_2_op[0][i];
                end else begin
                    channel_a_acc_pre_clamp_p[0][i] <= 0;
                end
            end
        end
        
        for (i = 0; i < 3; i = i + 1) begin : block_3
            always @(posedge clk_opl3) begin
                if (cha[1][i]) begin
                    channel_a_acc_pre_clamp_p[1][i] <= connection_sel[i+3] && is_new ? channel_4_op[1][i] : channel_2_op[1][i];
                end else begin
                    channel_a_acc_pre_clamp_p[1][i] <= 0;
                end
            end
        end
          
        for (i = 3; i < 6; i = i + 1) begin : block_4
            always @(posedge clk_opl3) begin
                if (cha[1][i]) begin
                    channel_a_acc_pre_clamp_p[1][i] <= channel_2_op[1][i];
                end else begin
                    channel_a_acc_pre_clamp_p[1][i] <= 0;
                end
            end
        end
      
        for (i = 6; i < 9; i = i + 1) begin : block_5
            always @(posedge clk_opl3) begin
                if (cha[1][i]) begin
                    channel_a_acc_pre_clamp_p[1][i] <= channel_2_op[1][i];
                end else begin
                    channel_a_acc_pre_clamp_p[1][i] <= 0; 
                end
            end
        end
    endgenerate
  
    always @(posedge clk_opl3) begin
        if (sample_clk_en) begin
            channel_a_acc_pre_clamp <= 0;
        end else if (calc_state == CALC_OUTPUTS) begin
            channel_a_acc_pre_clamp <= channel_a_acc_pre_clamp + channel_a_acc_pre_clamp_p[bank][channel];
        end
    end
      
    generate
        for (i = 0; i < 3; i = i + 1) begin : block_6
            always @(posedge clk_opl3) begin
                if (chb[0][i] || !is_new) begin
                    channel_b_acc_pre_clamp_p[0][i] <= connection_sel[i] && is_new ? channel_4_op[0][i] : channel_2_op[0][i];
                end else begin
                    channel_b_acc_pre_clamp_p[0][i] <= 0;
                end
            end
        end
          
        for (i = 3; i < 6; i = i + 1) begin : block_7
            always @(posedge clk_opl3) begin
                if (chb[0][i] || !is_new) begin
                    channel_b_acc_pre_clamp_p[0][i] <= channel_2_op[0][i];
                end else begin
                    channel_b_acc_pre_clamp_p[0][i] <= 0;
                end
            end
        end
      
        for (i = 6; i < 9; i = i + 1) begin : block_8
            always @(posedge clk_opl3) begin
                if (chb[0][i] || !is_new) begin
                    channel_b_acc_pre_clamp_p[0][i] <= channel_2_op[0][i];
                end else begin
                    channel_b_acc_pre_clamp_p[0][i] <= 0;
                end
            end
        end
      
        for (i = 0; i < 3; i = i + 1) begin : block_9
            always @(posedge clk_opl3) begin
                if (chb[1][i]) begin
                    channel_b_acc_pre_clamp_p[1][i] <= connection_sel[i+3] && is_new ? channel_4_op[1][i] : channel_2_op[1][i];
                end else begin
                    channel_b_acc_pre_clamp_p[1][i] <= 0;
                end
            end
        end
        
        for (i = 3; i < 6; i = i + 1) begin : block_10
            always @(posedge clk_opl3) begin
                if (chb[1][i]) begin
                    channel_b_acc_pre_clamp_p[1][i] <= channel_2_op[1][i];
                end else begin
                    channel_b_acc_pre_clamp_p[1][i] <= 0;
                end
            end
        end

        for (i = 6; i < 9; i = i + 1) begin : block_11
            always @(posedge clk_opl3) begin
                if (chb[1][i]) begin
                    channel_b_acc_pre_clamp_p[1][i] <= channel_2_op[1][i];
                end else begin
                    channel_b_acc_pre_clamp_p[1][i] <= 0; 
                end
            end
        end
    endgenerate
  
    always @(posedge clk_opl3) begin
        if (sample_clk_en) begin
            channel_b_acc_pre_clamp <= 0;
        end else if (calc_state == CALC_OUTPUTS) begin
            channel_b_acc_pre_clamp <= channel_b_acc_pre_clamp + channel_b_acc_pre_clamp_p[bank][channel];  
        end
    end
      
    generate
        for (i = 0; i < 3; i = i + 1) begin : block_12
            always @(posedge clk_opl3) begin
                if (chc[0][i] || !is_new) begin
                    channel_c_acc_pre_clamp_p[0][i] <= connection_sel[i] && is_new ? channel_4_op[0][i] : channel_2_op[0][i];
                end else begin
                    channel_c_acc_pre_clamp_p[0][i] <= 0;
                end
            end
        end
        
        for (i = 3; i < 6; i = i + 1) begin : block_13
            always @(posedge clk_opl3) begin
                if (chc[0][i] || !is_new) begin
                    channel_c_acc_pre_clamp_p[0][i] <= channel_2_op[0][i];
                end else begin
                    channel_c_acc_pre_clamp_p[0][i] <= 0;
                end
            end
        end

        for (i = 6; i < 9; i = i + 1) begin : block_14
            always @(posedge clk_opl3) begin
                if (chc[0][i] || !is_new) begin
                    channel_c_acc_pre_clamp_p[0][i] <= channel_2_op[0][i];
                end else begin
                    channel_c_acc_pre_clamp_p[0][i] <= 0;
                end
            end
        end

        for (i = 0; i < 3; i = i + 1) begin : block_15
            always @(posedge clk_opl3) begin
                if (chc[1][i]) begin
                    channel_c_acc_pre_clamp_p[1][i] <= connection_sel[i+3] && is_new ? channel_4_op[1][i] : channel_2_op[1][i];
                end else begin
                    channel_c_acc_pre_clamp_p[1][i] <= 0;
                end
            end
        end
      
        for (i = 3; i < 6; i = i + 1) begin : block_16
            always @(posedge clk_opl3) begin
                if (chc[1][i]) begin
                    channel_c_acc_pre_clamp_p[1][i] <= channel_2_op[1][i];
                end else begin
                    channel_c_acc_pre_clamp_p[1][i] <= 0;
                end
            end
        end

        for (i = 6; i < 9; i = i + 1) begin : block_17
            always @(posedge clk_opl3) begin
                if (chc[1][i]) begin
                    channel_c_acc_pre_clamp_p[1][i] <= channel_2_op[1][i];
                end else begin
                    channel_c_acc_pre_clamp_p[1][i] <= 0; 
                end
            end
        end
    endgenerate
  
    always @(posedge clk_opl3) begin
        if (sample_clk_en) begin
            channel_c_acc_pre_clamp <= 0;
        end else if (calc_state == CALC_OUTPUTS) begin
            channel_c_acc_pre_clamp <= channel_c_acc_pre_clamp + channel_c_acc_pre_clamp_p[bank][channel];  
        end
    end
      
    generate
        for (i = 0; i < 3; i = i + 1) begin : block_18
            always @(posedge clk_opl3) begin
                if (chd[0][i] || !is_new) begin
                    channel_d_acc_pre_clamp_p[0][i] <= connection_sel[i] && is_new ? channel_4_op[0][i] : channel_2_op[0][i];
                end else begin
                    channel_d_acc_pre_clamp_p[0][i] <= 0;
                end
            end
        end
      
        for (i = 3; i < 6; i = i + 1) begin : block_19
            always @(posedge clk_opl3) begin
                if (chd[0][i] || !is_new) begin
                    channel_d_acc_pre_clamp_p[0][i] <= channel_2_op[0][i];
                end else begin
                    channel_d_acc_pre_clamp_p[0][i] <= 0;
                end
            end
        end

        for (i = 6; i < 9; i = i + 1) begin : block_20
            always @(posedge clk_opl3) begin
                if (chd[0][i] || !is_new) begin
                    channel_d_acc_pre_clamp_p[0][i] <= channel_2_op[0][i];
                end else begin
                    channel_d_acc_pre_clamp_p[0][i] <= 0;
                end
            end
        end

        for (i = 0; i < 3; i = i + 1) begin : block_21
            always @(posedge clk_opl3) begin
                if (chd[1][i]) begin
                    channel_d_acc_pre_clamp_p[1][i] <= connection_sel[i+3] && is_new ? channel_4_op[1][i] : channel_2_op[1][i];
                end else begin
                    channel_d_acc_pre_clamp_p[1][i] <= 0;
                end
            end
        end

        for (i = 3; i < 6; i = i + 1) begin : block_22
            always @(posedge clk_opl3) begin
                if (chd[1][i]) begin
                    channel_d_acc_pre_clamp_p[1][i] <= channel_2_op[1][i];
                end else begin
                    channel_d_acc_pre_clamp_p[1][i] <= 0;
                end
            end
        end

        for (i = 6; i < 9; i = i + 1) begin : block_23
            always @(posedge clk_opl3) begin
                if (chd[1][i]) begin
                    channel_d_acc_pre_clamp_p[1][i] <= channel_2_op[1][i];
                end else begin
                    channel_d_acc_pre_clamp_p[1][i] <= 0; 
                end
            end
        end
    endgenerate
  
    always @(posedge clk_opl3) begin
        if (sample_clk_en) begin
            channel_d_acc_pre_clamp <= 0;
        end else if (calc_state == CALC_OUTPUTS) begin
            channel_d_acc_pre_clamp <= channel_d_acc_pre_clamp + channel_d_acc_pre_clamp_p[bank][channel];  
        end
    end
  
    /*
    * Clamp output channels
    */
    always @(posedge clk_opl3) begin
        if (sample_clk_en) begin 
            if (channel_a_acc_pre_clamp > 2**15 - 1) begin
                channel_a <= 2**15 - 1;
            end else if (channel_a_acc_pre_clamp < -2**15) begin
                channel_a <= -2**15;
            end else begin
                channel_a <= channel_a_acc_pre_clamp;
            end
        end
  
  
        if (channel_b_acc_pre_clamp > 2**15 - 1) begin
            channel_b <= 2**15 - 1;
        end else if (channel_b_acc_pre_clamp < -2**15) begin
            channel_b <= -2**15;
        end else begin
            channel_b <= channel_b_acc_pre_clamp;        
        end
  
        if (channel_c_acc_pre_clamp > 2**15 - 1) begin
            channel_c <= 2**15 - 1;
        end else if (channel_c_acc_pre_clamp < -2**15) begin
            channel_c <= -2**15;
        end else begin
            channel_c <= channel_c_acc_pre_clamp;        
        end
  
        if (channel_d_acc_pre_clamp > 2**15 - 1) begin
            channel_d <= 2**15 - 1;
        end else if (channel_d_acc_pre_clamp < -2**15) begin
            channel_d <= -2**15;
        end else begin
            channel_d <= channel_d_acc_pre_clamp; 
        end
    end    
      
endmodule
