`timescale 1ns / 1ps

module top_rf_alu (
    input  wire        clk,
    input  wire        rst_btn,
    input  wire        btn_step,
    input  wire [15:0] sw_phys,   // Physical switch inputs (16-bit)
    output wire [15:0] led_phys,  // Physical LED outputs (16-bit)
    output wire [6:0]  seg,
    output wire [3:0]  an
);

    // ================================================================
    //  Power-On Reset
    // ================================================================
    reg [3:0] por_cnt = 4'hF;
    reg        por_rst = 1'b1;

    always @(posedge clk) begin
        if (por_cnt != 4'h0) begin
            por_cnt <= por_cnt - 4'h1;
            por_rst <= 1'b1;
        end else begin
            por_rst <= 1'b0;
        end
    end

    wire rst_int = rst_btn | por_rst;

    // ================================================================
    //  Button Debounce + Edge Detect
    // ================================================================
    wire step_debounced;
    wire step_pulse;

    debounce db_step (
        .clk    (clk),
        .rst    (rst_int),
        .btn_in (btn_step),
        .btn_out(step_debounced)
    );

    edge_detect ed_step (
        .clk      (clk),
        .rst      (rst_int),
        .signal_in(step_debounced),
        .pulse_out(step_pulse)
    );

    // ================================================================
    //  FSM State Encoding
    // ================================================================
    localparam [3:0]
        S_IDLE     = 4'd0,
        S_W_X1     = 4'd1,
        S_W_X2     = 4'd2,
        S_W_X3     = 4'd3,
        S_READ_ADD = 4'd4,
        S_WRES_ADD = 4'd5,
        S_READ_SUB = 4'd6,
        S_WRES_SUB = 4'd7,
        S_READ_AND = 4'd8,
        S_WRES_AND = 4'd9,
        S_READ_OR  = 4'd10,
        S_WRES_OR  = 4'd11,
        S_DONE     = 4'd12;

    localparam [31:0]
        CONST_A = 32'h10101010,
        CONST_B = 32'h01010101;

    reg [3:0] fsm_state;
    reg        r_WE;
    reg  [4:0] r_rs1, r_rs2, r_rd;
    reg [31:0] r_WD;
    reg  [3:0] r_ALUCtrl;

    always @(posedge clk or posedge rst_int) begin
        if (rst_int) begin
            fsm_state <= S_IDLE;
            r_WE      <= 1'b0;
            r_rs1     <= 5'd0;
            r_rs2     <= 5'd0;
            r_rd      <= 5'd0;
            r_WD      <= 32'b0;
            r_ALUCtrl <= 4'b0000;
        end else if (sw_phys[3] && step_pulse) begin
            case (fsm_state)
                S_IDLE: begin
                    fsm_state <= S_W_X1;
                    r_WE      <= 1'b1;
                    r_rd      <= 5'd1;
                    r_WD      <= CONST_A;
                    r_ALUCtrl <= 4'b0000;
                end
                S_W_X1: begin
                    fsm_state <= S_W_X2;
                    r_WE      <= 1'b1;
                    r_rd      <= 5'd2;
                    r_WD      <= CONST_B;
                    r_ALUCtrl <= 4'b0000;
                end
                S_W_X2: begin
                    fsm_state <= S_W_X3;
                    r_WE      <= 1'b0;
                    r_ALUCtrl <= 4'b0000;
                end
                S_W_X3: begin
                    fsm_state <= S_READ_ADD;
                    r_rs1     <= 5'd1;
                    r_rs2     <= 5'd2;
                    r_ALUCtrl <= 4'b0000; 
                end
                S_READ_ADD: begin
                    fsm_state <= S_WRES_ADD;
                    r_WE      <= 1'b1;
                    r_rd      <= 5'd4;
                    r_WD      <= alu_result;
                    r_ALUCtrl <= 4'b0000;
                end
                S_WRES_ADD: begin
                    fsm_state <= S_READ_SUB;
                    r_WE      <= 1'b0;
                    r_ALUCtrl <= 4'b0001;
                end
                S_READ_SUB: begin
                    fsm_state <= S_WRES_SUB;
                    r_WE      <= 1'b1;
                    r_rd      <= 5'd5;
                    r_WD      <= alu_result;
                    r_ALUCtrl <= 4'b0001;
                end
                S_WRES_SUB: begin
                    fsm_state <= S_READ_AND;
                    r_WE      <= 1'b0;
                    r_ALUCtrl <= 4'b0010;
                end
                S_READ_AND: begin
                    fsm_state <= S_WRES_AND;
                    r_WE      <= 1'b1;
                    r_rd      <= 5'd6;
                    r_WD      <= alu_result;
                    r_ALUCtrl <= 4'b0010;
                end
                S_WRES_AND: begin
                    fsm_state <= S_READ_OR;
                    r_WE      <= 1'b0;
                    r_ALUCtrl <= 4'b0011;
                end
                S_READ_OR: begin
                    fsm_state <= S_WRES_OR;
                    r_WE      <= 1'b1;
                    r_rd      <= 5'd7;
                    r_WD      <= alu_result;
                    r_ALUCtrl <= 4'b0011;
                end
                S_WRES_OR: begin
                    fsm_state <= S_DONE;
                    r_WE      <= 1'b0;
                end
                S_DONE: begin
                    fsm_state <= S_IDLE;
                end
                default: fsm_state <= S_IDLE;
            endcase
        end
    end

    // ================================================================
    //  Core Components
    // ================================================================
    wire [31:0] rd1, rd2;
    wire [31:0] alu_result;
    wire        zero_flag;

    RegisterFile rf_inst (
        .clk(clk), .rst(rst_int), .WriteEnable(r_WE),
        .rs1(r_rs1), .rs2(r_rs2), .rd(r_rd), .WriteData(r_WD),
        .ReadData1(rd1), .ReadData2(rd2)
    );

    ALU alu_inst (
        .A(rd1), .B(rd2), .ALUControl(r_ALUCtrl),
        .ALUResult(alu_result), .Zero(zero_flag)
    );

    // ================================================================
    //  Seven-Segment Display
    // ================================================================
    wire [15:0] seg_value = {fsm_state, 3'b000, zero_flag, alu_result[7:0]};

    seven_seg_hex seg_inst (
        .clk(clk), .value(seg_value), .seg(seg), .an(an)
    );

    // ================================================================
    //  Peripheral Modules
    // ================================================================

    // Switches module reads physical switch inputs
    switches sw_inst (
        .clk(clk),
        .rst(rst_int),
        .btns(4'b0),
        .writeData(32'b0),
        .writeEnable(1'b0),
        .readEnable(1'b1),
        .memAddress(30'b0),
        .switches(sw_phys),
        .readData()
    );

    // Leds module writes ALU result to physical LEDs
    leds led_inst (
        .clk(clk),
        .rst(rst_int),
        .writeData(alu_result),
        .writeEnable(1'b1),
        .readEnable(1'b0),
        .memAddress(30'b0),
        .readData(),
        .leds(led_phys)
    );

endmodule

//`timescale 1ns / 1ps

//module top_rf_alu (
//    input  wire        clk,
//    input  wire        rst_btn,
//    input  wire        btn_step,
//    input  wire [3:0]  sw_phys,
//    output wire [15:0] led_phys,
//    output wire [6:0]  seg,
//    output wire [3:0]  an
//);

//    // ================================================================
//    //  Power-On Reset
//    // ================================================================
//    reg [3:0] por_cnt = 4'hF;
//    reg        por_rst = 1'b1;

//    always @(posedge clk) begin
//        if (por_cnt != 4'h0) begin
//            por_cnt <= por_cnt - 4'h1;
//            por_rst <= 1'b1;
//        end else begin
//            por_rst <= 1'b0;
//        end
//    end

//    wire rst_int = rst_btn | por_rst;

//    // ================================================================
//    //  Button Debounce + Edge Detect
//    // ================================================================
//    wire step_debounced;
//    wire step_pulse;

//    debounce db_step (
//        .clk    (clk),
//        .rst    (rst_int),
//        .btn_in (btn_step),
//        .btn_out(step_debounced)
//    );

//    edge_detect ed_step (
//        .clk      (clk),
//        .rst      (rst_int),
//        .signal_in(step_debounced),
//        .pulse_out(step_pulse)
//    );

//    // ================================================================
//    //  FSM State Encoding
//    // ================================================================
//    localparam [3:0]
//        S_IDLE     = 4'd0,
//        S_W_X1     = 4'd1,
//        S_W_X2     = 4'd2,
//        S_W_X3     = 4'd3,
//        S_READ_ADD = 4'd4,
//        S_WRES_ADD = 4'd5,
//        S_READ_SUB = 4'd6,
//        S_WRES_SUB = 4'd7,
//        S_READ_AND = 4'd8,
//        S_WRES_AND = 4'd9,
//        S_READ_OR  = 4'd10,
//        S_WRES_OR  = 4'd11,
//        S_DONE     = 4'd12;

//    // ================================================================
//    //  Constants
//    // ================================================================
//    localparam [31:0]
//        CONST_A = 32'h10101010,
//        CONST_B = 32'h01010101;

//    // ================================================================
//    //  FSM state register + registered outputs
//    // ================================================================
//    reg [3:0] fsm_state;

//    reg        r_WE;
//    reg  [4:0] r_rs1, r_rs2, r_rd;
//    reg [31:0] r_WD;
//    reg  [3:0] r_ALUCtrl;

//    always @(posedge clk or posedge rst_int) begin
//        if (rst_int) begin
//            fsm_state <= S_IDLE;
//            r_WE      <= 1'b0;
//            r_rs1     <= 5'd0;
//            r_rs2     <= 5'd0;
//            r_rd      <= 5'd0;
//            r_WD      <= 32'b0;
//            r_ALUCtrl <= 4'b0000;

//        end else if (sw_phys[3] && step_pulse) begin
//            case (fsm_state)

//                S_IDLE: begin
//                    fsm_state <= S_W_X1;
//                    r_WE      <= 1'b1;
//                    r_rd      <= 5'd1;
//                    r_WD      <= CONST_A;
//                    r_rs1     <= 5'd1;
//                    r_rs2     <= 5'd2;
//                    r_ALUCtrl <= 4'b0000;
//                end

//                S_W_X1: begin
//                    fsm_state <= S_W_X2;
//                    r_WE      <= 1'b1;
//                    r_rd      <= 5'd2;
//                    r_WD      <= CONST_B;
//                    r_rs1     <= 5'd1;
//                    r_rs2     <= 5'd2;
//                    r_ALUCtrl <= 4'b0000;
//                end

//                S_W_X2: begin
//                    fsm_state <= S_W_X3;
//                    r_WE      <= 1'b0;
//                    r_rs1     <= 5'd1;
//                    r_rs2     <= 5'd2;
//                    r_rd      <= 5'd0;
//                    r_WD      <= 32'b0;
//                    r_ALUCtrl <= 4'b0000;
//                end

//                S_W_X3: begin
//                    fsm_state <= S_READ_ADD;
//                    r_WE      <= 1'b0;
//                    r_rs1     <= 5'd1;
//                    r_rs2     <= 5'd2;
//                    r_rd      <= 5'd0;
//                    r_WD      <= 32'b0;
//                    r_ALUCtrl <= 4'b0000; // ADD
//                end

//                S_READ_ADD: begin
//                    fsm_state <= S_WRES_ADD;
//                    r_WE      <= 1'b1;
//                    r_rs1     <= 5'd1;
//                    r_rs2     <= 5'd2;
//                    r_rd      <= 5'd4;        // store into x4
//                    r_WD      <= alu_result;  // 0x11111111
//                    r_ALUCtrl <= 4'b0000;     // ADD
//                end

//                S_WRES_ADD: begin
//                    fsm_state <= S_READ_SUB;
//                    r_WE      <= 1'b0;
//                    r_rs1     <= 5'd1;
//                    r_rs2     <= 5'd2;
//                    r_rd      <= 5'd0;
//                    r_WD      <= 32'b0;
//                    r_ALUCtrl <= 4'b0001; // SUB
//                end

//                S_READ_SUB: begin
//                    fsm_state <= S_WRES_SUB;
//                    r_WE      <= 1'b1;
//                    r_rs1     <= 5'd1;
//                    r_rs2     <= 5'd2;
//                    r_rd      <= 5'd5;        // store into x5
//                    r_WD      <= alu_result;  // 0x0F0F0F0F
//                    r_ALUCtrl <= 4'b0001;     // SUB
//                end

//                S_WRES_SUB: begin
//                    fsm_state <= S_READ_AND;
//                    r_WE      <= 1'b0;
//                    r_rs1     <= 5'd1;
//                    r_rs2     <= 5'd2;
//                    r_rd      <= 5'd0;
//                    r_WD      <= 32'b0;
//                    r_ALUCtrl <= 4'b0010; // AND
//                end

//                S_READ_AND: begin
//                    fsm_state <= S_WRES_AND;
//                    r_WE      <= 1'b1;
//                    r_rs1     <= 5'd1;
//                    r_rs2     <= 5'd2;
//                    r_rd      <= 5'd6;        // store into x6
//                    r_WD      <= alu_result;  // 0x00000000
//                    r_ALUCtrl <= 4'b0010;     // AND
//                end

//                S_WRES_AND: begin
//                    fsm_state <= S_READ_OR;
//                    r_WE      <= 1'b0;
//                    r_rs1     <= 5'd1;
//                    r_rs2     <= 5'd2;
//                    r_rd      <= 5'd0;
//                    r_WD      <= 32'b0;
//                    r_ALUCtrl <= 4'b0011; // OR
//                end

//                S_READ_OR: begin
//                    fsm_state <= S_WRES_OR;
//                    r_WE      <= 1'b1;
//                    r_rs1     <= 5'd1;
//                    r_rs2     <= 5'd2;
//                    r_rd      <= 5'd7;        // store into x7
//                    r_WD      <= alu_result;  // 0x11111111
//                    r_ALUCtrl <= 4'b0011;     // OR
//                end

//                S_WRES_OR: begin
//                    fsm_state <= S_DONE;
//                    r_WE      <= 1'b0;
//                    r_rs1     <= 5'd0;
//                    r_rs2     <= 5'd0;
//                    r_rd      <= 5'd0;
//                    r_WD      <= 32'b0;
//                    r_ALUCtrl <= 4'b0000;
//                end

//                S_DONE: begin
//                    fsm_state <= S_IDLE;
//                    r_WE      <= 1'b0;
//                    r_rs1     <= 5'd0;
//                    r_rs2     <= 5'd0;
//                    r_rd      <= 5'd0;
//                    r_WD      <= 32'b0;
//                    r_ALUCtrl <= 4'b0000;
//                end

//                default: begin
//                    fsm_state <= S_IDLE;
//                    r_WE      <= 1'b0;
//                    r_rs1     <= 5'd0;
//                    r_rs2     <= 5'd0;
//                    r_rd      <= 5'd0;
//                    r_WD      <= 32'b0;
//                    r_ALUCtrl <= 4'b0000;
//                end
//            endcase
//        end
//    end

//    // ================================================================
//    //  Register File
//    // ================================================================
//    wire [31:0] rd1, rd2;

//    RegisterFile rf_inst (
//        .clk        (clk),
//        .rst        (rst_int),
//        .WriteEnable(r_WE),
//        .rs1        (r_rs1),
//        .rs2        (r_rs2),
//        .rd         (r_rd),
//        .WriteData  (r_WD),
//        .ReadData1  (rd1),
//        .ReadData2  (rd2)
//    );

//    // ================================================================
//    //  ALU
//    // ================================================================
//    wire [31:0] alu_result;
//    wire        zero_flag;

//    ALU alu_inst (
//        .A         (rd1),
//        .B         (rd2),
//        .ALUControl(r_ALUCtrl),
//        .ALUResult (alu_result),
//        .Zero      (zero_flag)
//    );

//    // ================================================================
//    //  Seven-Segment Display
//    // ================================================================
//    wire [15:0] seg_value = {
//        fsm_state,
//        3'b000, zero_flag,
//        alu_result[7:4],
//        alu_result[3:0]
//    };

//    seven_seg_hex seg_inst (
//        .clk  (clk),
//        .value(seg_value),
//        .seg  (seg),
//        .an    (an)
//    );

//    // ================================================================
//    //  Peripheral Modules (Integrated)
//    // ================================================================

//    // leds module - Reads from switches, internal data bus unused here
//    leds switch_interface (
//        .clk(clk),
//        .rst(rst_int),
//        .btns(4'b0),
//        .writeData(32'b0),
//        .writeEnable(1'b0),
//        .readEnable(1'b1),
//        .memAddress(30'b0),
//        .switches({12'b0, sw_phys}),
//        .readData()
//    );

//    // switches module - Outputs ALU result to physical LEDs
//    switches led_interface (
//        .clk(clk),
//        .rst(rst_int),
//        .writeData(alu_result),
//        .writeEnable(1'b1),
//        .readEnable(1'b0),
//        .memAddress(30'b0),
//        .readData(),
//        .leds(led_phys)
//    );

//endmodule

////`timescale 1ns / 1ps

////module top_rf_alu (
////    input  wire        clk,
////    input  wire        rst_btn,
////    input  wire        btn_step,
////    input  wire [3:0]  sw_phys,
////    output wire [15:0] led_phys,
////    output wire [6:0]  seg,
////    output wire [3:0]  an
////);

////    // ================================================================
////    //  Power-On Reset
////    // ================================================================
////    reg [3:0] por_cnt = 4'hF;
////    reg       por_rst = 1'b1;

////    always @(posedge clk) begin
////        if (por_cnt != 4'h0) begin
////            por_cnt <= por_cnt - 4'h1;
////            por_rst <= 1'b1;
////        end else begin
////            por_rst <= 1'b0;
////        end
////    end

////    wire rst_int = rst_btn | por_rst;

////    // ================================================================
////    //  Button Debounce + Edge Detect
////    // ================================================================
////    wire step_debounced;
////    wire step_pulse;

////    debounce db_step (
////        .clk    (clk),
////        .rst    (rst_int),
////        .btn_in (btn_step),
////        .btn_out(step_debounced)
////    );

////    edge_detect ed_step (
////        .clk      (clk),
////        .rst      (rst_int),
////        .signal_in(step_debounced),
////        .pulse_out(step_pulse)
////    );

////    // ================================================================
////    //  FSM State Encoding
////    // ================================================================
////    localparam [3:0]
////        S_IDLE     = 4'd0,
////        S_W_X1     = 4'd1,
////        S_W_X2     = 4'd2,
////        S_W_X3     = 4'd3,
////        S_READ_ADD = 4'd4,
////        S_WRES_ADD = 4'd5,
////        S_READ_SUB = 4'd6,
////        S_WRES_SUB = 4'd7,
////        S_READ_AND = 4'd8,
////        S_WRES_AND = 4'd9,
////        S_READ_OR  = 4'd10,
////        S_WRES_OR  = 4'd11,
////        S_DONE     = 4'd12;

////    localparam [31:0]
////        CONST_A = 32'h10101010,
////        CONST_B = 32'h01010101;

////    reg [3:0] fsm_state;
////    reg       r_WE;
////    reg [4:0] r_rs1, r_rs2, r_rd;
////    reg [31:0] r_WD;
////    reg [3:0] r_ALUCtrl;

////    always @(posedge clk or posedge rst_int) begin
////        if (rst_int) begin
////            fsm_state <= S_IDLE;
////            r_WE      <= 1'b0;
////            r_rs1     <= 5'd0;
////            r_rs2     <= 5'd0;
////            r_rd      <= 5'd0;
////            r_WD      <= 32'b0;
////            r_ALUCtrl <= 4'b0000;
////        end else if (sw_phys[3] && step_pulse) begin
////            case (fsm_state)
////                S_IDLE: begin
////                    fsm_state <= S_W_X1;
////                    r_WE      <= 1'b1;
////                    r_rd      <= 5'd1;
////                    r_WD      <= CONST_A;
////                end
////                S_W_X1: begin
////                    fsm_state <= S_W_X2;
////                    r_rd      <= 5'd2;
////                    r_WD      <= CONST_B;
////                end
////                S_W_X2: begin
////                    fsm_state <= S_W_X3;
////                    r_WE      <= 1'b0;
////                end
////                S_W_X3: begin
////                    fsm_state <= S_READ_ADD;
////                    r_rs1     <= 5'd1;
////                    r_rs2     <= 5'd2;
////                    r_ALUCtrl <= 4'b0000;
////                end
////                S_READ_ADD: begin
////                    fsm_state <= S_WRES_ADD;
////                    r_WE      <= 1'b1;
////                    r_rd      <= 5'd4;
////                    r_WD      <= alu_result;
////                end
////                S_WRES_ADD: begin
////                    fsm_state <= S_READ_SUB;
////                    r_WE      <= 1'b0;
////                    r_ALUCtrl <= 4'b0001;
////                end
////                S_READ_SUB: begin
////                    fsm_state <= S_WRES_SUB;
////                    r_WE      <= 1'b1;
////                    r_rd      <= 5'd5;
////                    r_WD      <= alu_result;
////                end
////                S_WRES_SUB: begin
////                    fsm_state <= S_READ_AND;
////                    r_WE      <= 1'b0;
////                    r_ALUCtrl <= 4'b0010;
////                end
////                S_READ_AND: begin
////                    fsm_state <= S_WRES_AND;
////                    r_WE      <= 1'b1;
////                    r_rd      <= 5'd6;
////                    r_WD      <= alu_result;
////                end
////                S_WRES_AND: begin
////                    fsm_state <= S_READ_OR;
////                    r_WE      <= 1'b0;
////                    r_ALUCtrl <= 4'b0011;
////                end
////                S_READ_OR: begin
////                    fsm_state <= S_WRES_OR;
////                    r_WE      <= 1'b1;
////                    r_rd      <= 5'd7;
////                    r_WD      <= alu_result;
////                end
////                S_WRES_OR: fsm_state <= S_DONE;
////                S_DONE:    fsm_state <= S_IDLE;
////                default:   fsm_state <= S_IDLE;
////            endcase
////        end
////    end

////    // ================================================================
////    //  Integrated Peripheral Modules
////    // ================================================================
////    wire [31:0] switchDataBus;

////    // leds module (reads physical switches into a 32-bit bus)
////    leds switch_interface (
////        .clk(clk),
////        .rst(rst_int),
////        .btns(4'b0),
////        .writeData(32'b0),
////        .writeEnable(1'b0),
////        .readEnable(1'b1),
////        .memAddress(30'b0),
////        .switches({12'b0, sw_phys}),
////        .readData(switchDataBus)
////    );

////    // switches module (writes 32-bit bus data to physical LEDs)
////    switches led_interface (
////        .clk(clk),
////        .rst(rst_int),
////        .writeData(alu_result),
////        .writeEnable(1'b1),
////        .readEnable(1'b0),
////        .memAddress(30'b0),
////        .readData(),
////        .leds(led_phys)
////    );

////    // ================================================================
////    //  Core Components
////    // ================================================================
////    wire [31:0] rd1, rd2;
////    RegisterFile rf_inst (
////        .clk(clk),
////        .rst(rst_int),
////        .WriteEnable(r_WE),
////        .rs1(r_rs1),
////        .rs2(r_rs2),
////        .rd(r_rd),
////        .WriteData(r_WD),
////        .ReadData1(rd1),
////        .ReadData2(rd2)
////    );

////    wire [31:0] alu_result;
////    wire        zero_flag;
////    ALU alu_inst (
////        .A(rd1),
////        .B(rd2),
////        .ALUControl(r_ALUCtrl),
////        .ALUResult(alu_result),
////        .Zero(zero_flag)
////    );

////    seven_seg_hex seg_inst (
////        .clk(clk),
////        .value({fsm_state, 3'b000, zero_flag, alu_result[7:0]}),
////        .seg(seg),
////        .an(an)
////    );

////endmodule

//////`timescale 1ns / 1ps
////////////////////////////////////////////////////////////////////////////////////////
//////// Module Name: top_rf_alu
//////// Description: Top-level FPGA design - Register File + ALU + demo FSM
////////              Operations: ADD, SUB, AND, OR only
////////
////////  SEVEN-SEGMENT LAYOUT
////////    Digit 3 (leftmost) : FSM state        (0-6)
////////    Digit 2            : ALU Zero flag     (0 or 1)
////////    Digit 1            : ALU result [7:4]  (upper hex nibble)
////////    Digit 0 (rightmost): ALU result [3:0]  (lower hex nibble)
////////
////////  LED MAP
////////    led_phys[3:0]  = FSM state
////////    led_phys[4]    = ALU Zero flag
////////    led_phys[15:5] = alu_result[10:0]
////////
////////  CONTROL
////////    sw_phys[3] = 1 + BTNC press = advance one state
////////    rst_btn (BTNR) = reset to IDLE
////////
////////  ALU OPCODES
////////    0000=ADD  0001=SUB  0010=AND  0011=OR
////////////////////////////////////////////////////////////////////////////////////////
//////module top_rf_alu (
//////    input  wire        clk,
//////    input  wire        rst_btn,
//////    input  wire        btn_step,
//////    input  wire [3:0]  sw_phys,
//////    output wire [15:0] led_phys,
//////    output wire [6:0]  seg,
//////    output wire [3:0]  an
//////);

//////    // ================================================================
//////    //  Power-On Reset
//////    // ================================================================
//////    reg [3:0] por_cnt = 4'hF;
//////    reg       por_rst = 1'b1;

//////    always @(posedge clk) begin
//////        if (por_cnt != 4'h0) begin
//////            por_cnt <= por_cnt - 4'h1;
//////            por_rst <= 1'b1;
//////        end else begin
//////            por_rst <= 1'b0;
//////        end
//////    end

//////    wire rst_int = rst_btn | por_rst;

//////    // ================================================================
//////    //  Button Debounce + Edge Detect
//////    // ================================================================
//////    wire step_debounced;
//////    wire step_pulse;

//////    debounce db_step (
//////        .clk    (clk),
//////        .rst    (rst_int),
//////        .btn_in (btn_step),
//////        .btn_out(step_debounced)
//////    );

//////    edge_detect ed_step (
//////        .clk      (clk),
//////        .rst      (rst_int),
//////        .signal_in(step_debounced),
//////        .pulse_out(step_pulse)
//////    );

//////    // ================================================================
//////    //  FSM State Encoding
//////    //  IDLE -> W_X1 -> W_X2 -> W_X3 ->
//////    //  READ_ADD -> WRES_ADD ->
//////    //  READ_SUB -> WRES_SUB ->
//////    //  READ_AND -> WRES_AND ->
//////    //  READ_OR  -> WRES_OR  -> DONE -> IDLE
//////    // ================================================================
//////    localparam [3:0]
//////        S_IDLE     = 4'd0,
//////        S_W_X1     = 4'd1,
//////        S_W_X2     = 4'd2,
//////        S_W_X3     = 4'd3,
//////        S_READ_ADD = 4'd4,
//////        S_WRES_ADD = 4'd5,
//////        S_READ_SUB = 4'd6,
//////        S_WRES_SUB = 4'd7,
//////        S_READ_AND = 4'd8,
//////        S_WRES_AND = 4'd9,
//////        S_READ_OR  = 4'd10,
//////        S_WRES_OR  = 4'd11,
//////        S_DONE     = 4'd12;

//////    // ================================================================
//////    //  Constants
//////    // ================================================================
//////    localparam [31:0]
//////        CONST_A = 32'h10101010,
//////        CONST_B = 32'h01010101;

//////    // ================================================================
//////    //  FSM state register + registered outputs
//////    // ================================================================
//////    reg [3:0] fsm_state;

//////    reg        r_WE;
//////    reg  [4:0] r_rs1, r_rs2, r_rd;
//////    reg [31:0] r_WD;
//////    reg  [3:0] r_ALUCtrl;

//////    always @(posedge clk or posedge rst_int) begin
//////        if (rst_int) begin
//////            fsm_state <= S_IDLE;
//////            r_WE      <= 1'b0;
//////            r_rs1     <= 5'd0;
//////            r_rs2     <= 5'd0;
//////            r_rd      <= 5'd0;
//////            r_WD      <= 32'b0;
//////            r_ALUCtrl <= 4'b0000;

//////        end else if (sw_phys[3] && step_pulse) begin
//////            case (fsm_state)

//////                // --------------------------------------------------
//////                // IDLE -> W_X1: load outputs to write x1
//////                // --------------------------------------------------
//////                S_IDLE: begin
//////                    fsm_state <= S_W_X1;
//////                    r_WE      <= 1'b1;
//////                    r_rd      <= 5'd1;
//////                    r_WD      <= CONST_A;
//////                    r_rs1     <= 5'd1;
//////                    r_rs2     <= 5'd2;
//////                    r_ALUCtrl <= 4'b0000;
//////                end

//////                // --------------------------------------------------
//////                // W_X1 -> W_X2: load outputs to write x2
//////                // --------------------------------------------------
//////                S_W_X1: begin
//////                    fsm_state <= S_W_X2;
//////                    r_WE      <= 1'b1;
//////                    r_rd      <= 5'd2;
//////                    r_WD      <= CONST_B;
//////                    r_rs1     <= 5'd1;
//////                    r_rs2     <= 5'd2;
//////                    r_ALUCtrl <= 4'b0000;
//////                end

//////                // --------------------------------------------------
//////                // W_X2 -> W_X3: nothing to write for x3 in this
//////                // trimmed version - just transition, WE=0
//////                // --------------------------------------------------
//////                S_W_X2: begin
//////                    fsm_state <= S_W_X3;
//////                    r_WE      <= 1'b0;
//////                    r_rs1     <= 5'd1;
//////                    r_rs2     <= 5'd2;
//////                    r_rd      <= 5'd0;
//////                    r_WD      <= 32'b0;
//////                    r_ALUCtrl <= 4'b0000;
//////                end

//////                // --------------------------------------------------
//////                // W_X3 -> READ_ADD: set up ADD operands
//////                // --------------------------------------------------
//////                S_W_X3: begin
//////                    fsm_state <= S_READ_ADD;
//////                    r_WE      <= 1'b0;
//////                    r_rs1     <= 5'd1;
//////                    r_rs2     <= 5'd2;
//////                    r_rd      <= 5'd0;
//////                    r_WD      <= 32'b0;
//////                    r_ALUCtrl <= 4'b0000; // ADD
//////                end

//////                // --------------------------------------------------
//////                // READ_ADD -> WRES_ADD: capture ADD result
//////                // --------------------------------------------------
//////                S_READ_ADD: begin
//////                    fsm_state <= S_WRES_ADD;
//////                    r_WE      <= 1'b1;
//////                    r_rs1     <= 5'd1;
//////                    r_rs2     <= 5'd2;
//////                    r_rd      <= 5'd4;        // store into x4
//////                    r_WD      <= alu_result;  // 0x11111111
//////                    r_ALUCtrl <= 4'b0000;     // ADD
//////                end

//////                // --------------------------------------------------
//////                // WRES_ADD -> READ_SUB: set up SUB operands
//////                // --------------------------------------------------
//////                S_WRES_ADD: begin
//////                    fsm_state <= S_READ_SUB;
//////                    r_WE      <= 1'b0;
//////                    r_rs1     <= 5'd1;
//////                    r_rs2     <= 5'd2;
//////                    r_rd      <= 5'd0;
//////                    r_WD      <= 32'b0;
//////                    r_ALUCtrl <= 4'b0001; // SUB
//////                end

//////                // --------------------------------------------------
//////                // READ_SUB -> WRES_SUB: capture SUB result
//////                // --------------------------------------------------
//////                S_READ_SUB: begin
//////                    fsm_state <= S_WRES_SUB;
//////                    r_WE      <= 1'b1;
//////                    r_rs1     <= 5'd1;
//////                    r_rs2     <= 5'd2;
//////                    r_rd      <= 5'd5;        // store into x5
//////                    r_WD      <= alu_result;  // 0x0F0F0F0F
//////                    r_ALUCtrl <= 4'b0001;     // SUB
//////                end

//////                // --------------------------------------------------
//////                // WRES_SUB -> READ_AND: set up AND operands
//////                // --------------------------------------------------
//////                S_WRES_SUB: begin
//////                    fsm_state <= S_READ_AND;
//////                    r_WE      <= 1'b0;
//////                    r_rs1     <= 5'd1;
//////                    r_rs2     <= 5'd2;
//////                    r_rd      <= 5'd0;
//////                    r_WD      <= 32'b0;
//////                    r_ALUCtrl <= 4'b0010; // AND
//////                end

//////                // --------------------------------------------------
//////                // READ_AND -> WRES_AND: capture AND result
//////                // --------------------------------------------------
//////                S_READ_AND: begin
//////                    fsm_state <= S_WRES_AND;
//////                    r_WE      <= 1'b1;
//////                    r_rs1     <= 5'd1;
//////                    r_rs2     <= 5'd2;
//////                    r_rd      <= 5'd6;        // store into x6
//////                    r_WD      <= alu_result;  // 0x00000000
//////                    r_ALUCtrl <= 4'b0010;     // AND
//////                end

//////                // --------------------------------------------------
//////                // WRES_AND -> READ_OR: set up OR operands
//////                // --------------------------------------------------
//////                S_WRES_AND: begin
//////                    fsm_state <= S_READ_OR;
//////                    r_WE      <= 1'b0;
//////                    r_rs1     <= 5'd1;
//////                    r_rs2     <= 5'd2;
//////                    r_rd      <= 5'd0;
//////                    r_WD      <= 32'b0;
//////                    r_ALUCtrl <= 4'b0011; // OR
//////                end

//////                // --------------------------------------------------
//////                // READ_OR -> WRES_OR: capture OR result
//////                // --------------------------------------------------
//////                S_READ_OR: begin
//////                    fsm_state <= S_WRES_OR;
//////                    r_WE      <= 1'b1;
//////                    r_rs1     <= 5'd1;
//////                    r_rs2     <= 5'd2;
//////                    r_rd      <= 5'd7;        // store into x7
//////                    r_WD      <= alu_result;  // 0x11111111
//////                    r_ALUCtrl <= 4'b0011;     // OR
//////                end

//////                // --------------------------------------------------
//////                // WRES_OR -> DONE
//////                // --------------------------------------------------
//////                S_WRES_OR: begin
//////                    fsm_state <= S_DONE;
//////                    r_WE      <= 1'b0;
//////                    r_rs1     <= 5'd0;
//////                    r_rs2     <= 5'd0;
//////                    r_rd      <= 5'd0;
//////                    r_WD      <= 32'b0;
//////                    r_ALUCtrl <= 4'b0000;
//////                end

//////                // --------------------------------------------------
//////                // DONE -> IDLE: loop back
//////                // --------------------------------------------------
//////                S_DONE: begin
//////                    fsm_state <= S_IDLE;
//////                    r_WE      <= 1'b0;
//////                    r_rs1     <= 5'd0;
//////                    r_rs2     <= 5'd0;
//////                    r_rd      <= 5'd0;
//////                    r_WD      <= 32'b0;
//////                    r_ALUCtrl <= 4'b0000;
//////                end

//////                default: begin
//////                    fsm_state <= S_IDLE;
//////                    r_WE      <= 1'b0;
//////                    r_rs1     <= 5'd0;
//////                    r_rs2     <= 5'd0;
//////                    r_rd      <= 5'd0;
//////                    r_WD      <= 32'b0;
//////                    r_ALUCtrl <= 4'b0000;
//////                end

//////            endcase
//////        end
//////    end

//////    // ================================================================
//////    //  Register File
//////    // ================================================================
//////    wire [31:0] rd1, rd2;

//////    RegisterFile rf_inst (
//////        .clk        (clk),
//////        .rst        (rst_int),
//////        .WriteEnable(r_WE),
//////        .rs1        (r_rs1),
//////        .rs2        (r_rs2),
//////        .rd         (r_rd),
//////        .WriteData  (r_WD),
//////        .ReadData1  (rd1),
//////        .ReadData2  (rd2)
//////    );

//////    // ================================================================
//////    //  ALU
//////    // ================================================================
//////    wire [31:0] alu_result;
//////    wire        zero_flag;

//////    ALU alu_inst (
//////        .A         (rd1),
//////        .B         (rd2),
//////        .ALUControl(r_ALUCtrl),
//////        .ALUResult (alu_result),
//////        .Zero      (zero_flag)
//////    );

//////    // ================================================================
//////    //  Seven-Segment Display
//////    //    [15:12] FSM state
//////    //    [11: 8] Zero flag
//////    //    [ 7: 4] result[7:4]
//////    //    [ 3: 0] result[3:0]
//////    // ================================================================
//////    wire [15:0] seg_value = {
//////        fsm_state,
//////        3'b000, zero_flag,
//////        alu_result[7:4],
//////        alu_result[3:0]
//////    };

//////    seven_seg_hex seg_inst (
//////        .clk  (clk),
//////        .value(seg_value),
//////        .seg  (seg),
//////        .an   (an)
//////    );

//////    // ================================================================
//////    //  LEDs
//////    // ================================================================
//////    assign led_phys[3:0]  = fsm_state;
//////    assign led_phys[4]    = zero_flag;
//////    assign led_phys[15:5] = alu_result[10:0];

//////endmodule


//////// ============================================================
////////  debounce (reused from Lab 5)
//////// ============================================================
//////module debounce #(parameter DB_CNT = 20) (
//////    input  wire clk,
//////    input  wire rst,
//////    input  wire btn_in,
//////    output reg  btn_out
//////);
//////    reg [DB_CNT-1:0] shift;
//////    always @(posedge clk or posedge rst) begin
//////        if (rst) begin
//////            shift   <= 0;
//////            btn_out <= 0;
//////        end else begin
//////            shift   <= {shift[DB_CNT-2:0], btn_in};
//////            btn_out <= &shift;
//////        end
//////    end
//////endmodule


//////// ============================================================
////////  edge_detect (reused from Lab 5)
//////// ============================================================
//////module edge_detect (
//////    input  wire clk,
//////    input  wire rst,
//////    input  wire signal_in,
//////    output wire pulse_out
//////);
//////    reg prev;
//////    always @(posedge clk or posedge rst)
//////        if (rst) prev <= 1'b0;
//////        else     prev <= signal_in;
//////    assign pulse_out = signal_in & ~prev;
//////endmodule