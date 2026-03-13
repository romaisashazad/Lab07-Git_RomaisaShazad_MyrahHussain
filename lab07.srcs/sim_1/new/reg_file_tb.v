`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/05/2026 11:16:03 AM
// Design Name: 
// Module Name: reg_file_tb
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

module RegisterFile_tb;

    // ---- DUT signals ----
    reg         clk, rst, WriteEnable;
    reg  [4:0]  rs1, rs2, rd;
    reg  [31:0] WriteData;
    wire [31:0] ReadData1, ReadData2;

    // ---- Instantiate DUT ----
    RegisterFile dut (
        .clk        (clk),
        .rst        (rst),
        .WriteEnable(WriteEnable),
        .rs1        (rs1),
        .rs2        (rs2),
        .rd         (rd),
        .WriteData  (WriteData),
        .ReadData1  (ReadData1),
        .ReadData2  (ReadData2)
    );

    // ---- Clock: 10 ns period ----
    initial clk = 0;
    always #5 clk = ~clk;

    task check;
        input [127:0] test_name;
        input [31:0]  got, expected;
        begin
            if (got === expected)
                $display("PASS  %s | got=0x%08h", test_name, got);
            else
                $display("FAIL  %s | got=0x%08h expected=0x%08h",
                         test_name, got, expected);
        end
    endtask

    // ---- Stimulus ----
    initial begin
        $dumpfile("RegisterFile_tb.vcd");
        $dumpvars(0, RegisterFile_tb);

        // ---------- Initialise ----------
        rst = 1; WriteEnable = 0;
        rs1 = 0; rs2 = 0; rd = 0; WriteData = 0;
        @(posedge clk); #1;
        rst = 0;

        // ==========================================================
        // TC1 - Write 0xDEADBEEF to x5, then read back on rs1 & rs2
        // ==========================================================
        $display("\n--- TC1: Basic write / read ---");
        WriteEnable = 1;
        rd          = 5'd5;
        WriteData   = 32'hDEADBEEF;
        @(posedge clk); #1;          // latch on this rising edge
        WriteEnable = 0;

        rs1 = 5'd5; rs2 = 5'd0;
        #1;                          // combinational read settles
        check("TC1_rs1", ReadData1, 32'hDEADBEEF);
        check("TC1_rs2_x0", ReadData2, 32'h0);   // rs2=x0 ? always 0

        // ==========================================================
        // TC2 - Attempt to write to x0; x0 must stay 0
        // ==========================================================
        $display("\n--- TC2: Write to x0 (should be ignored) ---");
        WriteEnable = 1;
        rd          = 5'd0;
        WriteData   = 32'hCAFEBABE;
        @(posedge clk); #1;
        WriteEnable = 0;

        rs1 = 5'd0;
        #1;
        check("TC2_x0_unchanged", ReadData1, 32'h0);

        // ==========================================================
        // TC3 - Simultaneous dual-port read (x5 and x5 ? same value)
        //        Also load a second register first
        // ==========================================================
        $display("\n--- TC3: Simultaneous dual-port read ---");
        WriteEnable = 1;
        rd = 5'd7; WriteData = 32'hA5A5A5A5;
        @(posedge clk); #1;
        WriteEnable = 0;

        rs1 = 5'd5; rs2 = 5'd7;   // x5=0xDEADBEEF, x7=0xA5A5A5A5
        #1;
        check("TC3_port1_x5", ReadData1, 32'hDEADBEEF);
        check("TC3_port2_x7", ReadData2, 32'hA5A5A5A5);

        // ==========================================================
        // TC4 - Overwrite x5 and verify old value is replaced
        // ==========================================================
        $display("\n--- TC4: Overwrite register ---");
        WriteEnable = 1;
        rd = 5'd5; WriteData = 32'h12345678;
        @(posedge clk); #1;
        WriteEnable = 0;

        rs1 = 5'd5;
        #1;
        check("TC4_overwrite", ReadData1, 32'h12345678);

        // ==========================================================
        // TC5 - Synchronous reset clears all registers
        // ==========================================================
        $display("\n--- TC5: Synchronous reset ---");
        rst = 1;
        @(posedge clk); #1;
        rst = 0;

        rs1 = 5'd5; rs2 = 5'd7;
        #1;
        check("TC5_x5_after_rst", ReadData1, 32'h0);
        check("TC5_x7_after_rst", ReadData2, 32'h0);

        $display("\n--- Simulation complete ---");
        $finish;
    end

endmodule

