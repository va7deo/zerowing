
module video_timing
(
    input       clk,
    input       reset,

    input  signed [3:0] hs_offset,
    input  signed [3:0] vs_offset,

    input  signed [3:0] hb_offset,
    input  signed [3:0] vb_offset,
    
    input         [4:0] vb_size_adj,

    output     [8:0] hc,
    output     [8:0] vc,

    output reg  hbl_delay,
    output reg  hsync,
    output reg  vbl,
    output reg  vsync
);

// 320x240 timings

localparam HBSTART = 320;   // horz blank begin
localparam HSSTART = 360;   // horz sync begin
localparam HSEND   = 380;   // horz sync end
localparam HTOTAL  = 450;   // horz total clocks

localparam VBSTART = 240;
localparam VSSTART = 250;
localparam VSEND   = 253;
localparam VTOTAL  = 270;

reg hbl;

reg [8:0] v;
reg [8:0] h;

assign hc = h;

assign vc = v - vb_size_adj;

always @ (posedge clk) begin

    if (reset) begin
        h <= 0;
        v <= 0;

        hbl <= 0;
        hbl_delay <= 0;
        vbl <= 0;
        hsync <= 0;
        vsync <= 0;
    end else begin
        // counter
        hbl_delay <= hbl;
        if (h == HTOTAL) begin
            h <= 0;
            hbl <= 0;

            // v signals
            if ( v == VBSTART-1 ) begin
                vbl <= 1;
            end else if ( v == VSSTART+$signed(vs_offset) ) begin
                vsync <= 0;
            end else if ( v == VSEND+$signed(vs_offset) ) begin
                vsync <= 1;
            end

            if (v == VTOTAL+vb_size_adj-1) begin
                v <= 0;
                vbl <= 0;
            end else begin
                v <= v + 1'd1;
            end
        end else begin
            h <= h + 1'd1;
        end

        // h signals
        if ( h == HBSTART-1 ) begin
            hbl <= 1;
        end else if ( h == HSSTART+$signed(hs_offset) ) begin
            hsync <= 0;
        end else if ( h == HSEND+$signed(hs_offset) ) begin
            hsync <= 1;
        end
    end
end

endmodule
