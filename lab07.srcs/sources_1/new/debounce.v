`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/13/2026 10:39:38 PM
// Design Name: 
// Module Name: debounce
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

module debounce #(parameter DB_CNT = 20) (
    input  wire clk,
    input  wire rst,
    input  wire btn_in,
    output reg  btn_out
);
    reg [DB_CNT-1:0] shift;
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            shift   <= 0;
            btn_out <= 0;
        end else begin
            shift   <= {shift[DB_CNT-2:0], btn_in};
            btn_out <= &shift;
        end
    end
endmodule