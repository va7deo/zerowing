
module video_timing
(
    input       clk,
    input       reset,

    input  signed [3:0] hs_offset,
    input  signed [3:0] vs_offset,

    input  signed [3:0] hb_offset,
    input  signed [3:0] vb_offset,

    output reg [8:0] hc,
    output reg [8:0] vc,

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

reg  hbl;

always @ (posedge clk) begin

    if (reset) begin
        hc <= 0;
        vc <= 0;

        hbl <= 0;
        hbl_delay <= 0;
        vbl <= 0;
        hsync <= 0;
        vsync <= 0;
    end else begin
        // counter
        hbl_delay <= hbl;
        if (hc == HTOTAL) begin
            hc <= 0;
            hbl <= 0;

            // v signals
            if ( vc == VBSTART-1 ) begin
                vbl <= 1;
            end else if ( vc == VSSTART+$signed(vs_offset) ) begin
                vsync <= 0;
            end else if ( vc == VSEND+$signed(vs_offset) ) begin
                vsync <= 1;
            end

            if (vc == VTOTAL-1) begin
                vc <= 0;
                vbl <= 0;
            end else begin
                vc <= vc + 1'd1;
            end
        end else begin
            hc <= hc + 1'd1;
        end

        // h signals
        if ( hc == HBSTART-1 ) begin
            hbl <= 1;
        end else if ( hc == HSSTART+$signed(hs_offset) ) begin
            hsync <= 0;
        end else if ( hc == HSEND+$signed(hs_offset) ) begin
            hsync <= 1;
        end
    end
end

endmodule
