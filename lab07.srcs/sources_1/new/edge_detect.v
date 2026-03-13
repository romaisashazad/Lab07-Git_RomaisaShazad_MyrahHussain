`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/13/2026 10:40:02 PM
// Design Name: 
// Module Name: edge_detect
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module edge_detect (
    input  wire clk,
    input  wire rst,
    input  wire signal_in,
    output wire pulse_out
);
    reg prev;
    always @(posedge clk or posedge rst)
        if (rst) prev <= 1'b0;
        else      prev <= signal_in;
    assign pulse_out = signal_in & ~prev;
endmodule
