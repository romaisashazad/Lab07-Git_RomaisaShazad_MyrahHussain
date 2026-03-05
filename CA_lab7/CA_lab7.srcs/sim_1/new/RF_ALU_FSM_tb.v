`timescale 1ns / 1ps

module RF_ALU_FSM_tb;
    reg clk, rst;
    reg writeEnable;
    reg [4:0] rs1, rs2, rd;
    reg [31:0] writeData;
    wire [31:0] readData1, readData2;
    
    // FSM States [cite: 50, 56-59]
    localparam IDLE = 2'b00, READ_REGS = 2'b01, ALU_OP = 2'b10, WRITE_REGS = 2'b11;
    reg [1:0] current_state;

    // ALU Signals
    reg [3:0] alu_ctrl;
    wire [31:0] alu_out;
    wire zero_flag;

    // 1. Instantiate Register File
    RegisterFile rf (
        .clk(clk), .rst(rst), .writeEnable(writeEnable), 
        .rs1(rs1), .rs2(rs2), .rd(rd), 
        .writeData(writeData), .readData1(readData1), .readData2(readData2)
    );

    // 2. Instantiate ALU [cite: 44]
    ALU alu_instance (
        .A(readData1), .B(readData2), 
        .ALUControl(alu_ctrl), .ALUResult(alu_out), .Zero(zero_flag)
    );

    // Clock generation: 10ns period
    always #5 clk = ~clk;

    initial begin
        // --- Initialization ---
        clk = 0; rst = 1; writeEnable = 0;
        rs1 = 0; rs2 = 0; rd = 0; writeData = 0; alu_ctrl = 0;
        current_state = IDLE;

        // Hold reset for 2 clock cycles to clear 'XX' from register file 
        repeat (2) @(posedge clk);
        #1 rst = 0; // De-assert reset slightly after clock edge

        // --- i. Write constants to x1, x2, and x3 [cite: 46] ---
        @(posedge clk); current_state = WRITE_REGS;
        writeEnable = 1; rd = 5'd1; writeData = 32'h10101010; // Write x1
        @(posedge clk); rd = 5'd2; writeData = 32'h01010101; // Write x2
        @(posedge clk); rd = 5'd3; writeData = 32'h00000005; // Write x3
        
        // --- ii. Perform ALU Operation (ADD x1 + x2 -> x4) [cite: 47] ---
        @(posedge clk); current_state = READ_REGS;
        writeEnable = 0; rs1 = 5'd1; rs2 = 5'd2;
        
        @(posedge clk); current_state = ALU_OP;
        alu_ctrl = 4'b0000; // Opcode for ADD
        
        @(posedge clk); current_state = WRITE_REGS;
        writeEnable = 1; rd = 5'd4; writeData = alu_out; // Store result in x4
        
        // --- iii. BEQ-style check (Compare x1 and x1) [cite: 48] ---
        @(posedge clk); current_state = READ_REGS;
        writeEnable = 0; rs1 = 5'd1; rs2 = 5'd1;
        
        @(posedge clk); current_state = ALU_OP;
        alu_ctrl = 4'b0110; // Opcode for SUB/Compare
        
        @(posedge clk); current_state = WRITE_REGS;
        if (zero_flag) begin
            writeEnable = 1; rd = 5'd11; writeData = 32'd1; // Flag x11 = 1 if equal
        end

        // --- iv. Test Read-After-Write timing  ---
        @(posedge clk); current_state = WRITE_REGS;
        writeEnable = 1; rd = 5'd10; writeData = 32'hABCDE123;
        
        @(posedge clk); current_state = READ_REGS;
        writeEnable = 0; rs1 = 5'd10; // Should see 0xABCDE123 immediately here
        
        @(posedge clk); current_state = IDLE;
        #20 $display("Simulation Finished Successfully.");
        $finish;
    end
endmodule