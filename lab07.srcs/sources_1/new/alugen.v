`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/09/2026 11:43:54 AM
// Design Name: 
// Module Name: alugen
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


`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/05/2026 09:55:05 AM
// Design Name: 
// Module Name: ALU_one_bit
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


module ALU_1bit (
    input bit_a,
    input bit_b,
    input c_in,
    input [3:0] op_sel,
    output reg bit_out,
    output c_out
);
    wire arith_out;
    
    // Full Adder Logic for Addition/Subtraction
    assign {c_out, arith_out} = bit_a + bit_b + c_in;

    always @(*) begin
        case (op_sel)
            4'b0000: bit_out = arith_out; // ADD
            4'b0001: bit_out = arith_out; // SUB
            4'b0010: bit_out = bit_a & bit_b; // AND
            4'b0011: bit_out = bit_a | bit_b; // OR
            4'b0100: bit_out = bit_a ^ bit_b; // XOR
            4'b0111: bit_out = arith_out; // BEQ Helper
            default: bit_out = 1'b0;
        endcase
    end
endmodule
