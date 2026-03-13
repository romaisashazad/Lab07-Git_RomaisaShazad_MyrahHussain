`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/05/2026 11:13:03 AM
// Design Name: 
// Module Name: ALU_module
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
module ALU (
    input  [31:0] A,
    input  [31:0] B,
    input  [ 3:0] ALUControl,
    output reg [31:0] ALUResult,
    output            Zero
);
    wire [31:0] node_carry;    // Ripple carry between slices
    wire [31:0] chain_output;  // Result from the 32 slices
    wire [31:0] mod_b;         // Selected B input (normal or inverted)
    
    // Logic for Subtraction/Branching: Invert B and prepare carry-in
    // SUB (0001) and BEQ (0111) use A + (~B) + 1
    assign mod_b = (ALUControl == 4'b0001 || ALUControl == 4'b0111) ? ~B : B;
    wire init_c = (ALUControl == 4'b0001 || ALUControl == 4'b0111) ? 1'b1 : 1'b0;

    // Build the 32-bit chain using the bit-slices
    genvar k;
    generate
        for (k = 0; k < 32; k = k + 1) begin : gen_alu
            if (k == 0)
                ALU_1bit unit0 (
                    .bit_a(A[k]), 
                    .bit_b(mod_b[k]), 
                    .c_in(init_c), 
                    .op_sel(ALUControl), 
                    .bit_out(chain_output[k]), 
                    .c_out(node_carry[k])
                );
            else
                ALU_1bit unitN (
                    .bit_a(A[k]), 
                    .bit_b(mod_b[k]), 
                    .c_in(node_carry[k-1]), 
                    .op_sel(ALUControl), 
                    .bit_out(chain_output[k]), 
                    .c_out(node_carry[k])
                );
        end
    endgenerate

    // Final Mux for Shifting and special logic
    always @(*) begin
        case (ALUControl)
            4'b0101: ALUResult = A << B[4:0];  // Shift Left Logical
            4'b0110: ALUResult = A >> B[4:0];  // Shift Right Logical
            // BEQ: If (A-B) results in 0, set result to 1
            4'b0111: ALUResult = (chain_output == 32'b0) ? 32'd1 : 32'd0; 
            default: ALUResult = chain_output; // Logics and Arithmetic
        endcase
    end

    // Standard Zero Flag requirement
    assign Zero = (ALUResult == 32'b0);

endmodule
