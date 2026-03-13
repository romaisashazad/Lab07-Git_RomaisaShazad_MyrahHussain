`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name: seven_seg_hex
// Description: 4-digit multiplexed seven-segment display driver.
//              Displays a 16-bit value as four HEX digits (0-F).
//              Uses the 100 MHz system clock directly for refresh timing.
//              Active-low segments and anodes (standard Basys 3).
//
//  Display layout (left to right):
//    an[3] = bits [15:12]   an[2] = bits [11:8]
//    an[1] = bits  [7:4]    an[0] = bits  [3:0]
//////////////////////////////////////////////////////////////////////////////////
module seven_seg_hex (
    input  wire        clk,        // 100 MHz system clock
    input  wire [15:0] value,      // 16-bit value shown as 4 hex digits
    output reg  [6:0]  seg,        // Segments a-g (active low)
    output reg  [3:0]  an          // Anode selects (active low)
);
    // ----------------------------------------------------------------
    //  Refresh counter - bits [17:16] give ~381 Hz scan rate
    //  (100 MHz / 2^18 = ~381 Hz per digit, ~95 Hz full refresh)
    // ----------------------------------------------------------------
    reg [17:0] refresh;
    always @(posedge clk)
        refresh <= refresh + 1;

    // ----------------------------------------------------------------
    //  Digit mux - select which nibble and which anode to drive
    // ----------------------------------------------------------------
    reg [3:0] nibble;

    always @(*) begin
        case (refresh[17:16])
            2'b00: begin nibble = value[ 3: 0]; an = 4'b1110; end  // digit 0 (rightmost)
            2'b01: begin nibble = value[ 7: 4]; an = 4'b1101; end  // digit 1
            2'b10: begin nibble = value[11: 8]; an = 4'b1011; end  // digit 2
            2'b11: begin nibble = value[15:12]; an = 4'b0111; end  // digit 3 (leftmost)
        endcase
    end

    // ----------------------------------------------------------------
    //  Hex to 7-segment decoder (active low, segments a-g)
    //  Segment order: seg[6:0] = {g, f, e, d, c, b, a}
    //
    //       aaa
    //      f   b
    //      f   b
    //       ggg
    //      e   c
    //      e   c
    //       ddd
    // ----------------------------------------------------------------
    always @(*) begin
        case (nibble)
            4'h0: seg = 7'b1000000; // 0
            4'h1: seg = 7'b1111001; // 1
            4'h2: seg = 7'b0100100; // 2
            4'h3: seg = 7'b0110000; // 3
            4'h4: seg = 7'b0011001; // 4
            4'h5: seg = 7'b0010010; // 5
            4'h6: seg = 7'b0000010; // 6
            4'h7: seg = 7'b1111000; // 7
            4'h8: seg = 7'b0000000; // 8
            4'h9: seg = 7'b0010000; // 9
            4'hA: seg = 7'b0001000; // A
            4'hB: seg = 7'b0000011; // B
            4'hC: seg = 7'b1000110; // C
            4'hD: seg = 7'b0100001; // D
            4'hE: seg = 7'b0000110; // E
            4'hF: seg = 7'b0001110; // F
            default: seg = 7'b1111111; // blank
        endcase
    end

endmodule