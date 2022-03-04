
module video_timing
(
    input       clk,
    input       reset,

    input [15:0] crtc0,
    input [15:0] crtc1,
    input [15:0] crtc2,
    input [15:0] crtc3,

    input  signed [3:0] hs_offset,
    input  signed [3:0] vs_offset,

    output     [8:0] hc,
    output     [8:0] vc,

    output reg  hbl_delay,
    output reg  hsync,
    output reg  vbl,
    output reg  vsync
);

// 320x240 timings

wire [8:0] HBL_CNT = { crtc0[15:8]-1, 1'b1 };
wire [8:0] HTOTAL  = { crtc0[7:0], 1'b1 };           // horz total clocks and blank start
wire [8:0] HBSTART = HTOTAL - HBL_CNT;                     // horz blank begin

wire [8:0] HSSTART = 360 + $signed(hs_offset);             // horz sync begin
wire [8:0] HSEND   = 380 + $signed(hs_offset);             // horz sync end

wire [8:0] VBL_CNT = { crtc2[15:8], 1'b1 };
wire [8:0] VTOTAL  = { crtc2[7:0], 1'b1 };
wire [8:0] VBSTART = VTOTAL - VBL_CNT;

wire [8:0] VSSTART = 250 + $signed(vs_offset);
wire [8:0] VSEND   = 253 + $signed(vs_offset);

reg hbl;

reg [8:0] v;
reg [8:0] h;

assign hc = h;

assign vc = v;

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
            end else if ( v == VSSTART ) begin
                vsync <= 0;
            end else if ( v == VSEND ) begin
                vsync <= 1;
            end

            if (v == VTOTAL) begin
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
        end else if ( h == HSSTART ) begin
            hsync <= 0;
        end else if ( h == HSEND ) begin
            hsync <= 1;
        end
    end
end

endmodule
