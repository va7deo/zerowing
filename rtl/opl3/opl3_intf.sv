/*
 * Copyright (c) 2014, Aleksander Osman
 * All rights reserved.
 * 
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 * 
 * * Redistributions of source code must retain the above copyright notice, this
 *   list of conditions and the following disclaimer.
 * 
 * * Redistributions in binary form must reproduce the above copyright notice,
 *   this list of conditions and the following disclaimer in the documentation
 *   and/or other materials provided with the distribution.
 * 
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 * CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 * OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

module opl3_intf
(
	input                clk,
	input                clk_opl,
	input                rst_n,
	output               irq_n,

	input                addr,
	output         [7:0] dout,
	input          [7:0] din,
	input                we,
	input                rd,

	output [15:0] sample_l,
	output [15:0] sample_r
);

//------------------------------------------------------------------------------

assign dout  = { timer1_overflow | timer2_overflow, timer1_overflow, timer2_overflow, 5'd0 };
assign irq_n = ~(timer1_overflow | timer2_overflow);

//------------------------------------------------------------------------------

reg [4:0] clk_counter;
wire ce_1us = ( clk_counter == 13 );  
  
always @(posedge clk_opl) begin    
    
    // 1us ce based on 14MHz clock
    if ( clk_counter == 13 ) begin
        clk_counter <= 0;
    end else begin
        clk_counter <= clk_counter + 1;
    end

end

reg old_write;

always @(posedge clk) begin
	old_write <= we;
end

wire write = (~old_write & we);

reg [8:0] reg_num;

always @(posedge clk) begin
    if (rst_n == 0) begin 
        reg_num <= 0;
    end else if (addr == 0 && write) begin
        reg_num <= din;
    end
end

wire       io_write     = (addr && write);
wire [7:0] io_writedata = din;

//------------------------------------------------------------------------------ timer 1

reg [7:0] timer1_preset;
always @(posedge clk) begin
    if (rst_n == 0) begin
		timer1_preset <= 0;
	end else if (io_write && reg_num == 2) begin
        timer1_preset <= io_writedata;
    end
end

reg timer1_mask;
reg timer1_active;

always @(posedge clk) begin
    if (rst_n == 0) begin
        {timer1_mask, timer1_active} <= 0;
    end else if (io_write && reg_num == 4 && ~io_writedata[7]) begin
        {timer1_mask, timer1_active} <= {io_writedata[6], io_writedata[0]};
    end
end

wire timer1_pulse;
// timer 1 has 80us resolution
timer #(79) timer1( ce_1us, timer1_preset, timer1_active, timer1_pulse );

reg timer1_overflow;

always @(posedge clk) begin
	if (rst_n == 0) begin
        timer1_overflow <= 0;
	end else begin
		if (io_write && reg_num == 4 /*&& io_writedata[7]*/) begin
            timer1_overflow <= 0;
        end
		if ((timer1_pulse || force_overflow) && ~timer1_mask) begin
            timer1_overflow <= 1;
        end
	end
end


//------------------------------------------------------------------------------ timer 2

reg [7:0] timer2_preset;

always @(posedge clk) begin
    if (rst_n == 0) begin
        timer2_preset <= 0;
    end else if (io_write && reg_num == 3) begin
        timer2_preset <= io_writedata;
    end
end

reg timer2_mask;
reg timer2_active;

always @(posedge clk) begin
    if (rst_n == 0) begin
        {timer2_mask, timer2_active} <= 0;
    end else if (io_write && reg_num == 4 && ~io_writedata[7]) begin
        {timer2_mask, timer2_active} <= {io_writedata[5], io_writedata[1]};
    end
end

wire timer2_pulse;
// timer 1 has 320us resolution
timer #(319) timer2( ce_1us, timer2_preset, timer2_active, timer2_pulse );

reg timer2_overflow;

always @(posedge clk) begin
	if (rst_n == 0) begin
        timer2_overflow <= 0;
    end	else begin
		if (io_write && reg_num == 4 /*&& io_writedata[7]*/) begin
            timer2_overflow <= 0;
        end
		if ((timer2_pulse || force_overflow) && ~timer2_mask) begin
            timer2_overflow <= 1;
        end
	end
end

reg force_overflow;

//------------------------------------------------------------------------------

wire [16:0] sample_mix = {opl3_channel_a[15],opl3_channel_a} + { opl3_channel_b[15],opl3_channel_b} ;
assign sample_l = sample_mix[16:1];
assign sample_r = sample_mix[16:1];

wire signed [15:0] opl3_channel_a;
wire signed [15:0] opl3_channel_b;
wire signed [15:0] opl3_channel_c;
wire signed [15:0] opl3_channel_d;
  
opl3 opl3
(
    .clk(clk),          // sys clk 70M
    .clk_opl3(clk_opl), // 14M

    .opl3_adr(reg_num),
    .opl3_data(din),
    .opl3_we(write & addr), 

    .channel_a(opl3_channel_a),
    .channel_b(opl3_channel_b),
    .channel_c(opl3_channel_c),
    .channel_d(opl3_channel_d)
);

endmodule

module timer #(parameter RES)
(
    input         ce_1us,
	input   [7:0] preset,
	input         active,
	output reg    overflow_pulse
);

always @(posedge ce_1us) begin
    reg [7:0] counter;
	reg [8:0] sub_counter;
    
	overflow_pulse <= 0;

	if (active) begin
        sub_counter <= sub_counter - 1'd1;
        if (!sub_counter) begin
            sub_counter <= RES[8:0];
            counter <= counter + 1'd1;
            if (&counter) begin
                overflow_pulse <= 1;
                counter <= preset;
            end
        end
	end else begin
		counter <= preset;
		sub_counter <= RES[8:0];
	end
end
    
endmodule
