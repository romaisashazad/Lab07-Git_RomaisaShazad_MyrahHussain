//`timescale 1ns / 1ps
////////////////////////////////////////////////////////////////////////////////////
//// Company: 
//// Engineer: 
//// 
//// Create Date: 03/05/2026 11:18:42 AM
//// Design Name: 
//// Module Name: tb
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


//module RF_ALU_FSM_tb;

//    // ---- Clock & Reset ----
//    reg clk, rst;
//    initial clk = 0;
//    always #5 clk = ~clk;

//    // ---- Register File signals ----
//    reg         WE;
//    reg  [4:0]  rs1, rs2, rd;
//    reg  [31:0] WD;
//    wire [31:0] RD1, RD2;

//    // ---- ALU signals ----
//    reg  [3:0]  ALUCtrl;
//    wire [31:0] ALUResult;
//    wire        Zero;

//    // ---- Instantiate DUT modules ----
//    RegisterFile RF (
//        .clk        (clk),
//        .rst        (rst),
//        .WriteEnable(WE),
//        .rs1        (rs1),
//        .rs2        (rs2),
//        .rd         (rd),
//        .WriteData  (WD),
//        .ReadData1  (RD1),
//        .ReadData2  (RD2)
//    );

//    ALU alu (
//        .A         (RD1),
//        .B         (RD2),
//        .ALUControl(ALUCtrl),
//        .Result    (ALUResult),
//        .Zero      (Zero)
//    );

//    // ============================================================
//    //  FSM
//    // ============================================================
//    // States
//    localparam [3:0]
//        IDLE         = 4'd0,
//        WRITE_REGS   = 4'd1,   // load x1, x2, x3 with constants
//        READ_ALU     = 4'd2,   // set rs1/rs2, choose ALU op
//        WRITE_RESULT = 4'd3,   // store ALUResult into rd
//        BEQ_CHECK    = 4'd4,   // check Zero flag; write flag to x11
//        RAW_WRITE    = 4'd5,   // read-after-write: write x12
//        RAW_READ     = 4'd6,   // next cycle: read x12
//        DONE         = 4'd7;

//    reg [3:0] state, next_state;
//    reg [3:0] op_idx;          // which ALU operation (0-6)

//    // ALU op encodings (mirroring ALU.v)
//    localparam [3:0]
//        OP_AND = 4'b0000,
//        OP_OR  = 4'b0001,
//        OP_ADD = 4'b0010,
//        OP_XOR = 4'b0011,
//        OP_SLL = 4'b0100,
//        OP_SRL = 4'b0101,
//        OP_SUB = 4'b0110;

//    // Constants to load
//    localparam [31:0]
//        CONST_X1 = 32'h10101010,
//        CONST_X2 = 32'h01010101,
//        CONST_X3 = 32'h00000005;   // shift amount

//    // Expected results (for assertion)
//    reg [31:0] expected;

//    task check;
//        input [127:0] label;
//        input [31:0]  got, exp;
//        begin
//            if (got === exp)
//                $display("PASS  %-30s got=0x%08h", label, got);
//            else
//                $display("FAIL  %-30s got=0x%08h  exp=0x%08h",
//                         label, got, exp);
//        end
//    endtask

//    // ---- Destination registers for each op (x4..x10) ----
//    function [4:0] dest_reg;
//        input [3:0] idx;
//        dest_reg = 5'd4 + idx;   // x4, x5, x6, x7, x8, x9, x10
//    endfunction

//    // ---- FSM: state register ----
//    always @(posedge clk) begin
//        if (rst) begin
//            state  <= IDLE;
//            op_idx <= 0;
//        end else begin
//            state <= next_state;
//        end
//    end

//    // ---- op_idx advancement ----
//    always @(posedge clk) begin
//        if (state == WRITE_RESULT && op_idx < 4'd6)
//            op_idx <= op_idx + 1;
//        else if (state == BEQ_CHECK)
//            op_idx <= 0;          // reset for potential re-use
//    end

//    // ---- Decode ALU control from op_idx ----
//    always @(*) begin
//        case (op_idx)
//            4'd0: ALUCtrl = OP_ADD;
//            4'd1: ALUCtrl = OP_SUB;
//            4'd2: ALUCtrl = OP_AND;
//            4'd3: ALUCtrl = OP_OR;
//            4'd4: ALUCtrl = OP_XOR;
//            4'd5: ALUCtrl = OP_SLL;
//            4'd6: ALUCtrl = OP_SRL;
//            default: ALUCtrl = OP_ADD;
//        endcase
//    end

//    // ---- Next-state + output logic ----
//    always @(*) begin
//        // defaults
//        WE   = 0;
//        rs1  = 5'd1;
//        rs2  = 5'd2;
//        rd   = 5'd0;
//        WD   = 32'b0;
//        next_state = state;

//        case (state)
//            // --------------------------------------------------
//            IDLE: begin
//                next_state = WRITE_REGS;
//            end

//            // --------------------------------------------------
//            // Load x1=CONST_X1, x2=CONST_X2, x3=CONST_X3
//            // (three sub-phases encoded via op_idx reuse)
//            // For simplicity we use op_idx to count sub-writes
//            // --------------------------------------------------
//            WRITE_REGS: begin
//                WE = 1;
//                case (op_idx)
//                    4'd0: begin rd = 5'd1; WD = CONST_X1; end
//                    4'd1: begin rd = 5'd2; WD = CONST_X2; end
//                    4'd2: begin rd = 5'd3; WD = CONST_X3; end
//                    default: begin rd = 5'd0; WD = 0; end
//                endcase
//                // Advance op_idx handled in clocked block;
//                // move to READ_ALU after 3 writes
//                if (op_idx == 4'd2)
//                    next_state = READ_ALU;
//                else
//                    next_state = WRITE_REGS;
//            end

//            // --------------------------------------------------
//            // Present rs1=x1, rs2=x2 (or x3 for shifts)
//            // --------------------------------------------------
//            READ_ALU: begin
//                WE  = 0;
//                rs1 = 5'd1;
//                rs2 = (op_idx >= 4'd5) ? 5'd3 : 5'd2;  // use x3 as shift amt
//                next_state = WRITE_RESULT;
//            end

//            // --------------------------------------------------
//            // Write ALU result into x4..x10
//            // --------------------------------------------------
//            WRITE_RESULT: begin
//                WE = 1;
//                rs1 = 5'd1;
//                rs2 = (op_idx >= 4'd5) ? 5'd3 : 5'd2;
//                rd  = dest_reg(op_idx);
//                WD  = ALUResult;
//                if (op_idx == 4'd6)
//                    next_state = BEQ_CHECK;
//                else
//                    next_state = READ_ALU;
//            end

//            // --------------------------------------------------
//            // BEQ-style: compute x1 - x1 (should be zero)
//            // If Zero==1 write 32'h1 to x11, else write 32'h0
//            // --------------------------------------------------
//            BEQ_CHECK: begin
//                WE   = 1;
//                rs1  = 5'd1;
//                rs2  = 5'd1;   // same register ? subtract = 0
//                rd   = 5'd11;
//                WD   = Zero ? 32'h1 : 32'h0;
//                // Force ALU to SUB for this check
//                next_state = RAW_WRITE;
//            end

//            // --------------------------------------------------
//            // Read-After-Write: write x12 = 0xFACEFACE
//            // --------------------------------------------------
//            RAW_WRITE: begin
//                WE = 1;
//                rd = 5'd12;
//                WD = 32'hFACEFACE;
//                next_state = RAW_READ;
//            end

//            // --------------------------------------------------
//            // RAW_READ: read x12 in the cycle immediately after write
//            // --------------------------------------------------
//            RAW_READ: begin
//                WE  = 0;
//                rs1 = 5'd12;
//                next_state = DONE;
//            end

//            DONE: begin
//                next_state = DONE;
//            end

//            default: next_state = IDLE;
//        endcase
//    end

//    // ============================================================
//    //  Assertions (clocked, one cycle after each action completes)
//    // ============================================================
//    // We use a monitor-style block to check results as the FSM runs.

//    always @(posedge clk) begin
//        // After WRITE_RESULT latches a result, verify it
//        if (state == READ_ALU) begin
//            // The result isn't written yet; nothing to check here
//        end

//        if (state == WRITE_RESULT) begin
//            // Check the value being stored matches the expected ALU result
//            case (op_idx)
//                4'd0: check("ADD  x4 = x1+x2",   ALUResult, CONST_X1 + CONST_X2);
//                4'd1: check("SUB  x5 = x1-x2",   ALUResult, CONST_X1 - CONST_X2);
//                4'd2: check("AND  x6 = x1&x2",   ALUResult, CONST_X1 & CONST_X2);
//                4'd3: check("OR   x7 = x1|x2",   ALUResult, CONST_X1 | CONST_X2);
//                4'd4: check("XOR  x8 = x1^x2",   ALUResult, CONST_X1 ^ CONST_X2);
//                4'd5: check("SLL  x9 = x1<<x3",  ALUResult, CONST_X1 << CONST_X3[4:0]);
//                4'd6: check("SRL x10 = x1>>x3",  ALUResult, CONST_X1 >> CONST_X3[4:0]);
//            endcase
//        end

//        if (state == BEQ_CHECK) begin
//            // ALUCtrl is SUB and rs1=rs2=x1, so result = 0 ? Zero = 1
//            // WD should be 1
//            check("BEQ Zero flag (x1-x1==0)", WD, 32'h1);
//        end

//        if (state == RAW_READ) begin
//            // x12 was written last cycle; read should return new value
//            check("RAW x12 read-after-write", RD1, 32'hFACEFACE);
//        end

//        if (state == DONE) begin
//            $display("\n--- Simulation complete ---");
//            #10 $finish;
//        end
//    end

//    // ============================================================
//    //  Stimulus top-level
//    // ============================================================
//    initial begin
//        $dumpfile("RF_ALU_FSM_tb.vcd");
//        $dumpvars(0, RF_ALU_FSM_tb);

//        rst = 1; #12;
//        rst = 0;

//        // Simulation runs via FSM until DONE state
//        #2000;
//        $display("Timeout - simulation did not reach DONE");
//        $finish;
//    end

//    // ---- Optional: state-name display ----
//    reg [79:0] state_name;
//    always @(*) begin
//        case (state)
//            IDLE        : state_name = "IDLE       ";
//            WRITE_REGS  : state_name = "WRITE_REGS ";
//            READ_ALU    : state_name = "READ_ALU   ";
//            WRITE_RESULT: state_name = "WRITE_RESLT";
//            BEQ_CHECK   : state_name = "BEQ_CHECK  ";
//            RAW_WRITE   : state_name = "RAW_WRITE  ";
//            RAW_READ    : state_name = "RAW_READ   ";
//            DONE        : state_name = "DONE       ";
//            default     : state_name = "UNKNOWN    ";
//        endcase
//    end

//endmodule


`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name: RF_ALU_FSM_tb
// Description: Integrated testbench - Register File + ALU driven by FSM
//              Opcodes matched exactly to ALU.v implementation:
//                ADD=0000, SUB=0001, AND=0010, OR=0011, XOR=0100,
//                SLL=0101, SRL=0110, BEQ=0111
//////////////////////////////////////////////////////////////////////////////////
module RF_ALU_FSM_tb;

    // ----------------------------------------------------------
    //  Clock & Reset
    // ----------------------------------------------------------
    reg clk, rst;
    initial clk = 0;
    always #5 clk = ~clk;   // 10 ns period = 100 MHz

    // ----------------------------------------------------------
    //  Register File ports
    // ----------------------------------------------------------
    reg         WE;
    reg  [4:0]  rs1, rs2, rd;
    reg  [31:0] WD;
    wire [31:0] RD1, RD2;

    // ----------------------------------------------------------
    //  ALU ports
    // ----------------------------------------------------------
    reg  [3:0]  ALUCtrl;
    wire [31:0] ALUResult;
    wire        Zero;

    // ----------------------------------------------------------
    //  Instantiate DUT modules
    // ----------------------------------------------------------
    RegisterFile RF (
        .clk        (clk),
        .rst        (rst),
        .WriteEnable(WE),
        .rs1        (rs1),
        .rs2        (rs2),
        .rd         (rd),
        .WriteData  (WD),
        .ReadData1  (RD1),
        .ReadData2  (RD2)
    );

    ALU alu (
        .A         (RD1),
        .B         (RD2),
        .ALUControl(ALUCtrl),   // port name matches ALU.v
        .ALUResult (ALUResult), // port name matches ALU.v
        .Zero      (Zero)
    );

    // ==========================================================
    //  FSM State Encoding
    //  Separate states for each register write avoids the
    //  op_idx aliasing bug present in the original version.
    // ==========================================================
    localparam [3:0]
        IDLE         = 4'd0,
        WRITE_REG1   = 4'd1,   // x1 = CONST_X1
        WRITE_REG2   = 4'd2,   // x2 = CONST_X2
        WRITE_REG3   = 4'd3,   // x3 = CONST_X3 (shift amount)
        READ_ALU     = 4'd4,   // present operands, wait 1 cycle
        WRITE_RESULT = 4'd5,   // store ALUResult -> x(4+op_idx)
        BEQ_CHECK    = 4'd6,   // x1-x1, write Zero flag to x11
        RAW_WRITE    = 4'd7,   // write x12 = 0xFACEFACE
        RAW_READ     = 4'd8,   // read x12 next cycle (RAW test)
        DONE         = 4'd9;

    // ----------------------------------------------------------
    //  ALU opcode constants - matched EXACTLY to ALU.v
    //    ADD = 0000
    //    SUB = 0001
    //    AND = 0010
    //    OR  = 0011
    //    XOR = 0100
    //    SLL = 0101
    //    SRL = 0110
    //    BEQ = 0111
    // ----------------------------------------------------------
    localparam [3:0]
        OP_ADD = 4'b0000,
        OP_SUB = 4'b0001,
        OP_AND = 4'b0010,
        OP_OR  = 4'b0011,
        OP_XOR = 4'b0100,
        OP_SLL = 4'b0101,
        OP_SRL = 4'b0110,
        OP_BEQ = 4'b0111;   // used in BEQ_CHECK state

    // ----------------------------------------------------------
    //  Constants written into the register file
    // ----------------------------------------------------------
    localparam [31:0]
        CONST_X1 = 32'h10101010,
        CONST_X2 = 32'h01010101,
        CONST_X3 = 32'h00000005;   // shift amount

    // ----------------------------------------------------------
    //  State and operation index registers
    // ----------------------------------------------------------
    reg [3:0] state;
    reg [2:0] op_idx;   // 0..6 selects one of 7 ALU operations

    // ----------------------------------------------------------
    //  ALU control decode
    //  BEQ_CHECK forces OP_BEQ so x1-x1 is evaluated correctly.
    //  All other states use op_idx.
    // ----------------------------------------------------------
    always @(*) begin
        if (state == BEQ_CHECK)
            ALUCtrl = OP_BEQ;       // force BEQ (uses SUB path internally)
        else begin
            case (op_idx)
                3'd0: ALUCtrl = OP_ADD;
                3'd1: ALUCtrl = OP_SUB;
                3'd2: ALUCtrl = OP_AND;
                3'd3: ALUCtrl = OP_OR;
                3'd4: ALUCtrl = OP_XOR;
                3'd5: ALUCtrl = OP_SLL;
                3'd6: ALUCtrl = OP_SRL;
                default: ALUCtrl = OP_ADD;
            endcase
        end
    end

    // Convenience flag: ops 5 and 6 use x3 as the shift amount (B input)
    wire use_shift = (op_idx >= 3'd5);

    // Map op_idx -> destination register x4..x10
    function [4:0] dest_reg;
        input [2:0] idx;
        dest_reg = 5'd4 + {2'b00, idx};
    endfunction

    // ==========================================================
    //  Clocked FSM - state and op_idx transitions
    // ==========================================================
    always @(posedge clk) begin
        if (rst) begin
            state  <= IDLE;
            op_idx <= 3'd0;
        end else begin
            case (state)
                IDLE:        state <= WRITE_REG1;

                // Three dedicated write states - no counter aliasing
                WRITE_REG1:  state <= WRITE_REG2;
                WRITE_REG2:  state <= WRITE_REG3;
                WRITE_REG3: begin
                    op_idx <= 3'd0;     // reset op index before ALU loop
                    state  <= READ_ALU;
                end

                // READ then WRITE loop for each of 7 ALU ops
                READ_ALU:    state <= WRITE_RESULT;

                WRITE_RESULT: begin
                    if (op_idx == 3'd6) begin
                        state <= BEQ_CHECK;     // all 7 ops done
                    end else begin
                        op_idx <= op_idx + 3'd1;
                        state  <= READ_ALU;
                    end
                end

                BEQ_CHECK:   state <= RAW_WRITE;
                RAW_WRITE:   state <= RAW_READ;
                RAW_READ:    state <= DONE;
                DONE:        state <= DONE;     // hold until $finish
                default:     state <= IDLE;
            endcase
        end
    end

    // ==========================================================
    //  Combinational output logic (Mealy outputs)
    // ==========================================================
    always @(*) begin
        // Safe defaults
        WE  = 1'b0;
        rs1 = 5'd0;
        rs2 = 5'd0;
        rd  = 5'd0;
        WD  = 32'b0;

        case (state)
            IDLE: ;     // nothing to drive

            // ---- Write constants into x1, x2, x3 ----
            WRITE_REG1: begin
                WE = 1'b1;
                rd = 5'd1;
                WD = CONST_X1;
            end

            WRITE_REG2: begin
                WE = 1'b1;
                rd = 5'd2;
                WD = CONST_X2;
            end

            WRITE_REG3: begin
                WE = 1'b1;
                rd = 5'd3;
                WD = CONST_X3;
            end

            // ---- Present operands to ALU ----
            READ_ALU: begin
                rs1 = 5'd1;
                rs2 = use_shift ? 5'd3 : 5'd2;
            end

            // ---- Store ALUResult into x4..x10 ----
            WRITE_RESULT: begin
                WE  = 1'b1;
                rs1 = 5'd1;
                rs2 = use_shift ? 5'd3 : 5'd2;
                rd  = dest_reg(op_idx);
                WD  = ALUResult;
            end

            // ---- BEQ: x1 - x1 should be 0; write flag to x11 ----
            BEQ_CHECK: begin
                WE  = 1'b1;
                rs1 = 5'd1;
                rs2 = 5'd1;         // same register -> result = 0
                rd  = 5'd11;
                WD  = Zero ? 32'h0000_0001 : 32'h0000_0000;
            end

            // ---- Read-After-Write test ----
            RAW_WRITE: begin
                WE = 1'b1;
                rd = 5'd12;
                WD = 32'hFACE_FACE;
            end

            RAW_READ: begin
                rs1 = 5'd12;    // read x12 in the cycle immediately after write
            end

            DONE: ;
        endcase
    end

    // ==========================================================
    //  Assertion / check task
    // ==========================================================
    task check;
        input [239:0] label;
        input [31:0]  got, exp;
        begin
            if (got === exp)
                $display("PASS %-35s got=0x%08h", label, got);
            else
                $display("FAIL %-35s got=0x%08h  exp=0x%08h", label, got, exp);
        end
    endtask

    // ==========================================================
    //  Clocked assertions - checked one cycle after each action
    // ==========================================================
    always @(posedge clk) begin

        // Check ALU result while it is being written to the reg file
        if (state == WRITE_RESULT) begin
            case (op_idx)
                3'd0: check("ADD  x4 = x1 + x2",
                            ALUResult, CONST_X1 + CONST_X2);
                3'd1: check("SUB  x5 = x1 - x2",
                            ALUResult, CONST_X1 - CONST_X2);
                3'd2: check("AND  x6 = x1 & x2",
                            ALUResult, CONST_X1 & CONST_X2);
                3'd3: check("OR   x7 = x1 | x2",
                            ALUResult, CONST_X1 | CONST_X2);
                3'd4: check("XOR  x8 = x1 ^ x2",
                            ALUResult, CONST_X1 ^ CONST_X2);
                3'd5: check("SLL  x9  = x1 << x3[4:0]",
                            ALUResult, CONST_X1 << CONST_X3[4:0]);
                3'd6: check("SRL  x10 = x1 >> x3[4:0]",
                            ALUResult, CONST_X1 >> CONST_X3[4:0]);
            endcase
        end

        // BEQ: Zero flag must be 1 (x1 - x1 = 0), so WD must be 1
        if (state == BEQ_CHECK)
            check("BEQ  Zero flag (x1-x1==0) -> x11",
                  WD, 32'h0000_0001);

        // RAW: x12 written previous cycle must be readable now
        if (state == RAW_READ)
            check("RAW  x12 read-after-write",
                  RD1, 32'hFACE_FACE);

        // Simulation ends one cycle after DONE is entered
        if (state == DONE) begin
            $display("\n--- All checks complete. Simulation done. ---");
            #10 $finish;
        end
    end

    // ==========================================================
    //  Waveform dump & timeout guard
    // ==========================================================
    initial begin
        $dumpfile("RF_ALU_FSM_tb.vcd");
        $dumpvars(0, RF_ALU_FSM_tb);

        rst = 1;
        @(posedge clk); #1;
        @(posedge clk); #1;
        rst = 0;

        // Timeout safety net (FSM should finish well within 500 ns)
        #3000;
        $display("TIMEOUT - simulation did not reach DONE state");
        $finish;
    end

    // ==========================================================
    //  State name string for waveform readability
    // ==========================================================
    reg [87:0] state_name;
    always @(*) begin
        case (state)
            IDLE        : state_name = "IDLE       ";
            WRITE_REG1  : state_name = "WRITE_REG1 ";
            WRITE_REG2  : state_name = "WRITE_REG2 ";
            WRITE_REG3  : state_name = "WRITE_REG3 ";
            READ_ALU    : state_name = "READ_ALU   ";
            WRITE_RESULT: state_name = "WRITE_RESLT";
            BEQ_CHECK   : state_name = "BEQ_CHECK  ";
            RAW_WRITE   : state_name = "RAW_WRITE  ";
            RAW_READ    : state_name = "RAW_READ   ";
            DONE        : state_name = "DONE       ";
            default     : state_name = "UNKNOWN    ";
        endcase
    end

endmodule
