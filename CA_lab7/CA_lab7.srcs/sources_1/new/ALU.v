`timescale 1ns / 1ps
`timescale 1ns / 1ps

module ALU (
    input  [31:0] A,
    input  [31:0] B,
    input  [ 3:0] ALUControl,
    output reg [31:0] ALUResult,
    output            Zero
);
    wire [31:0] carry;
    wire [31:0] structural_res;
    wire [31:0] b_input;
   
    // For SUB and BEQ, we perform A + (~B) + 1
    assign b_input = (ALUControl == 4'b0001 || ALUControl == 4'b0111) ? ~B : B;
    wire first_cin = (ALUControl == 4'b0001 || ALUControl == 4'b0111) ? 1'b1 : 1'b0;

    // Instantiate 32 1-bit ALU slices (The Structural Part)
    genvar i;
    generate
        for (i = 0; i < 32; i = i + 1) begin : alu_slice
            if (i == 0)
                ALU_1bit bit0 (.a(A[i]), .b(b_input[i]), .cin(first_cin), .op(ALUControl), .res(structural_res[i]), .cout(carry[i]));
            else
                ALU_1bit bitN (.a(A[i]), .b(b_input[i]), .cin(carry[i-1]), .op(ALUControl), .res(structural_res[i]), .cout(carry[i]));
        end
    endgenerate

    // Final Multiplexer to include Shifts and BEQ logic
    always @(*) begin
        case (ALUControl)
            4'b0101: ALUResult = A << B[4:0];         // SLL (Global Operation)
            4'b0110: ALUResult = A >> B[4:0];         // SRL (Global Operation)
            4'b0111: ALUResult = (structural_res == 32'b0) ? 32'd1 : 32'd0; // BEQ
            default: ALUResult = structural_res;      // ADD, SUB, AND, OR, XOR
        endcase
    end

    assign Zero = (ALUResult == 32'b0);
endmodule

//`timescale 1ns / 1ps

//module ALU (
//    input  [31:0] A,
//    input  [31:0] B,
//    input  [ 3:0] ALUControl,
//    output [31:0] ALUResult,
//    output        Zero
//);
//    wire [31:0] carry;
//    wire [31:0] b_mux;
   
//    // If the op is subtract, invert B for 2's complement logic
//    assign b_mux = (ALUControl == 4'b0001) ? ~B : B;
   
//    // Carry-in is 1 for subtraction (A + ~B + 1), otherwise 0
//    wire first_cin = (ALUControl == 4'b0001) ? 1'b1 : 1'b0;

//    // Loop to instantiate 32 separate 1-bit ALU slices
//    genvar i;
//    generate
//        for (i = 0; i < 32; i = i + 1) begin : alu_slice
//            if (i == 0)
//                // First bit takes the initial carry-in (first_cin)
//                ALU_1bit bit0 (.a(A[i]), .b(b_mux[i]), .cin(first_cin), .op(ALUControl), .res(ALUResult[i]), .cout(carry[i]));
//            else
//                // Remaining bits chain the carry-out from the previous bit to the next carry-in
//                ALU_1bit bitN (.a(A[i]), .b(b_mux[i]), .cin(carry[i-1]), .op(ALUControl), .res(ALUResult[i]), .cout(carry[i]));
//        end
//    endgenerate

//    // Check if the final result is zero to set the flag
//    assign Zero = (ALUResult == 32'b0);
//endmodule is this the alu i need to add