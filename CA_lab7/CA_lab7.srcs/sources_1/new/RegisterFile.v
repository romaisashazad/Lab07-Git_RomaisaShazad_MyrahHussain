`timescale 1ns / 1ps

module RegisterFile(
    input wire clk,
    input wire rst,
    input wire writeEnable,
    input wire [4:0] rs1,      // Source Register 1 [cite: 13]
    input wire [4:0] rs2,      // Source Register 2 [cite: 13]
    input wire [4:0] rd,       // Destination Register [cite: 13]
    input wire [31:0] writeData,
    output wire [31:0] readData1,
    output wire [31:0] readData2
);

    // Renamed internal register array
    reg [31:0] rf_mem [31:0]; 
    integer idx;

    // Asynchronous Read Logic [cite: 7, 18]
    // Specifically ensuring x0 always returns 0 [cite: 15, 33]
    assign readData1 = (rs1 != 5'b0) ? rf_mem[rs1] : 32'h0;
    assign readData2 = (rs2 != 5'b0) ? rf_mem[rs2] : 32'h0;

    // Synchronous Write Logic [cite: 7, 17]
    always @(posedge clk) begin
        if (rst) begin
            // Reset all registers to zero [cite: 41]
            for (idx = 0; idx < 32; idx = idx + 1) begin
                rf_mem[idx] <= 32'h0;
            end
        end 
        else if (writeEnable && (rd != 5'b0)) begin
            // Write data only if Enable is high and target isn't x0 [cite: 15, 33]
            rf_mem[rd] <= writeData;
        end
    end

endmodule
