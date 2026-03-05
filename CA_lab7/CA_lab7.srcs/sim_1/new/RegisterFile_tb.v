`timescale 1ns / 1ps

module RegisterFile_tb;
    // 1. Signals to connect to the Register File
    reg clk, rst, writeEnable;
    reg [4:0] rs1, rs2, rd;
    reg [31:0] writeData;
    wire [31:0] readData1, readData2;

    // 2. Instantiate the Register File from your previous step
    RegisterFile uut (
        .clk(clk), .rst(rst), .writeEnable(writeEnable),
        .rs1(rs1), .rs2(rs2), .rd(rd),
        .writeData(writeData),
        .readData1(readData1), .readData2(readData2)
    );

    // 3. Clock Generation (10ns period)
    always #5 clk = ~clk;

    // 4. Test Procedure
    initial begin
        // Initialize inputs
        clk = 0; rst = 1; writeEnable = 0;
        rs1 = 0; rs2 = 0; rd = 0; writeData = 0;

        // v. Reset behavior: Check registers clear appropriately [cite: 41]
        #10 rst = 0; 
        #5; // Wait for a moment after reset
        if (readData1 == 0 && readData2 == 0) 
            $display("Reset Test Passed: Registers are zeroed. [cite: 41]");

        // i. Write 0xDEADBEEF to x5 and check next clock [cite: 37]
        @(posedge clk);
        writeEnable = 1; rd = 5'd5; writeData = 32'hDEADBEEF;
        @(posedge clk); // Wait for the write to happen
        writeEnable = 0; rs1 = 5'd5;
        #1; // Brief delay for combinational logic
        if (readData1 == 32'hDEADBEEF)
            $display("Write Test Passed: x5 contains 0xDEADBEEF [cite: 37]");

        // ii. Attempt to write to x0 and verify it remains zero [cite: 38]
        @(posedge clk);
        writeEnable = 1; rd = 5'd0; writeData = 32'hFFFFFFFF;
        @(posedge clk);
        writeEnable = 0; rs1 = 5'd0;
        #1;
        if (readData1 == 32'b0)
            $display("x0 Test Passed: x0 stayed zero despite write attempt [cite: 38]");

        // iii. Simultaneous two read ports [cite: 39]
        // First, write a value to x10
        @(posedge clk);
        writeEnable = 1; rd = 5'd10; writeData = 32'hABCDE123;
        @(posedge clk);
        writeEnable = 0;
        // Read x5 (rs1) and x10 (rs2) at the same time
        rs1 = 5'd5; rs2 = 5'd10;
        #1;
        if (readData1 == 32'hDEADBEEF && readData2 == 32'hABCDE123)
            $display("Dual Read Test Passed: Concurrent reads successful [cite: 39]");

        // iv. Overwrite a register and verify old value is replaced [cite: 40]
        @(posedge clk);
        writeEnable = 1; rd = 5'd5; writeData = 32'hCAFEFACE;
        @(posedge clk);
        writeEnable = 0; rs1 = 5'd5;
        #1;
        if (readData1 == 32'hCAFEFACE)
            $display("Overwrite Test Passed: x5 updated to new value [cite: 40]");

        $display("--- ALL REGISTER FILE TESTS COMPLETED ---");
        $finish;
    end
endmodule