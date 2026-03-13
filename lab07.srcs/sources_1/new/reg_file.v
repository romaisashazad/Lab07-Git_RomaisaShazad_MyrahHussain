module RegisterFile (
    input  wire        clk,
    input  wire        rst,
    input  wire        WriteEnable,
    input  wire [4:0]  rs1,
    input  wire [4:0]  rs2,
    input  wire [4:0]  rd,
    input  wire [31:0] WriteData,
    output wire [31:0] ReadData1,
    output wire [31:0] ReadData2
);
    reg [31:0] regs [1:31]; 
    integer i;

    always @(posedge clk) begin
        if (rst) begin
            for (i = 1; i < 32; i = i + 1)
                regs[i] <= 32'b0;
        end else if (WriteEnable && (rd != 5'b0)) begin
            regs[rd] <= WriteData;
        end
    end

    assign ReadData1 = (rs1 == 5'b0) ? 32'b0 : regs[rs1];
    assign ReadData2 = (rs2 == 5'b0) ? 32'b0 : regs[rs2];
endmodule

//`timescale 1ns / 1ps
////////////////////////////////////////////////////////////////////////////////////
//// Company: 
//// Engineer: 
//// 
//// Create Date: 03/05/2026 11:14:24 AM
//// Design Name: 
//// Module Name: reg_file
//// Project Name: 
//// Target Devices: 
//// Tool Versions: 
//// Description: 
//// 
//// Dependencies: 
//// 
//// Revision:
//// Revision 0.01 - File Created
//// Additional Comments:
//// 
////////////////////////////////////////////////////////////////////////////////////


//module RegisterFile (
//    input  wire        clk,
//    input  wire        rst,
//    input  wire        WriteEnable,
//    input  wire [4:0]  rs1,
//    input  wire [4:0]  rs2,
//    input  wire [4:0]  rd,
//    input  wire [31:0] WriteData,
//    output wire [31:0] ReadData1,
//    output wire [31:0] ReadData2
//);

//    // 32 registers, each 32 bits wide
//    reg [31:0] regs [1:31];   // index 0 omitted - x0 is hardwired

//    integer i;

//    // ---- Synchronous write (and reset) ----
//    always @(posedge clk) begin
//        if (rst) begin
//            for (i = 1; i < 32; i = i + 1)
//                regs[i] <= 32'b0;
//        end else if (WriteEnable && (rd != 5'b0)) begin
//            regs[rd] <= WriteData;
//        end
//    end

//    // ---- Asynchronous (combinational) reads ----
//    // x0 is always 0; all other addresses read from the array
//    assign ReadData1 = (rs1 == 5'b0) ? 32'b0 : regs[rs1];
//    assign ReadData2 = (rs2 == 5'b0) ? 32'b0 : regs[rs2];

//endmodule
