`timescale 1ns / 1ps

module ALU_1bit (
    input a,
    input b,
    input cin,
    input [3:0] op,
    output reg res,
    output cout
);
    wire w_sum;
   
    // Full Adder Logic (Used for ADD and SUB)
    assign {cout, w_sum} = a + b + cin;

    always @(*) begin
        case (op)
            4'b0000: res = w_sum; // ADD
            4'b0001: res = w_sum; // SUB
            4'b0010: res = a & b; // AND
            4'b0011: res = a | b; // OR
            4'b0100: res = a ^ b; // XOR
            4'b0111: res = w_sum; // BEQ/SUB Helper
            default: res = 1'b0;
        endcase
    end
endmodule

//`timescale 1ns / 1ps

//module ALU_1bit (
//    input a,
//    input b,
//    input cin,
//    input [3:0] op,
//    output reg res,
//    output cout
//);
//    wire w_sum;
//    // Arithmetic logic (Full Adder)
//    assign {cout, w_sum} = a + b + cin;

//    always @(*) begin
//        case (op)
//            4'b0000: res = w_sum; // ADD
//            4'b0001: res = w_sum; // SUB
//            4'b0010: res = a & b; // AND
//            4'b0011: res = a | b; // OR
//            4'b0100: res = a ^ b; // XOR
//            default: res = 1'b0;
//        endcase
//    end
//endmodule
//`timescale 1ns / 1ps

//module ALU_1bit (
//    input a,
//    input b,
//    input cin,
//    input [3:0] op,
//    output reg res,
//    output cout
//);
//    wire w_and, w_or, w_xor, w_sum;

//    assign w_and = a & b;
//    assign w_or  = a | b;
//    assign w_xor = a ^ b;
   
//    // Full Adder for ADD and SUB
//    assign {cout, w_sum} = a + b + cin;

//    // The Multiplexer
//    always @(*) begin
//        case (op)
//            4'b0000: res = w_sum; // ADD
//            4'b0001: res = w_sum; // SUB
//            4'b0010: res = w_and; // AND
//            4'b0011: res = w_or;  // OR
//            4'b0100: res = w_xor; // XOR
//            4'b0111: res = w_sum; // BEQ/SLT helper
//            default: res = 1'b0;
//        endcase
//    end
//endmodule