`timescale 1ns/1ps

`include "scr1_arch_description.svh"
`include "scr1_riscv_isa_decoding.svh"
`include "scr1_search_ms1.svh"

module tb_scr1_pipe_ialu ();
    

    logic                                               clk,                // IALU clock                    
    logic                                               rst_n,              // IALU reset                
    logic                                               mdu_opcode_valid,   // MUL/DIV command valid                    
    logic                                               mdu_result_ready,   // MUL/DIV result ready           

    logic                       [`SCR1_XLEN-1:0]        op1,                // main ALU 1st operand    
    logic                       [`SCR1_XLEN-1:0]        op2,                // main ALU 2nd operand    
    type_scr1_ialu_cmd_sel_e                            opcode,             // IALU command            
    logic                       [`SCR1_XLEN-1:0]        result,             // main ALU result        
    logic                                               flag,               // IALU comparison result    

    logic                       [`SCR1_XLEN-1:0]        addr_op1,           // Address adder 1st operand        
    logic                       [`SCR1_XLEN-1:0]        addr_op2,           // Address adder 2nd operand        
    logic                       [`SCR1_XLEN-1:0]        addr_result         // Address adder result      

    logic                       [`SCR1_XLEN-1:0]        ref_result;         // Reference result
    // logic                                               ref_cmp_flag;       // Reference compare flag
    // type_scr1_ialu_flags_s                              ref_flags;          // Reference flags

    //ALU instance
    scr1_pipe_ialu DUT(
    .clk                   (clk),                         // IALU clock
    .rst_n                 (rst_n),                       // IALU reset
    .exu2ialu_rvm_cmd_vd_i (mdu_opcode_valid),            // MUL/DIV command valid
    .ialu2exu_rvm_res_rdy_o(mdu_result_ready),            // MUL/DIV result ready
    
    .exu2ialu_main_op1_i   (op1),                         // main ALU 1st operand
    .exu2ialu_main_op2_i   (op2),                         // main ALU 2nd operand
    .exu2ialu_cmd_i        (opcode),                      // IALU command
    .ialu2exu_main_res_o   (result),                      // main ALU result
    .ialu2exu_cmp_res_o    (flag),                        // IALU comparison result

    .exu2ialu_addr_op1_i   (addr_op1),                    // Address adder 1st operand
    .exu2ialu_addr_op2_i   (addr_op2),                    // Address adder 2nd operand
    .ialu2exu_addr_res_o   (addr_result)                  // Address adder result
    );

    // ============ Parameters ============
    parameter PERIOD            = 20ns;
    parameter NUM_OF_DUMPLINES  = 100; 
    parameter NUM_OF_RANDLINES  = 1000;
    // ============ Integers ============
    integer i               = 0;
    integer error_counter   = 0;
    // ============ Logic signals ============
    logic           test1_done;
    logic           all_tests_done;
    logic [127:0]   operation_type;
    // $urandom(6043);

    // Data arrays
    logic                       [`SCR1_XLEN-1:0]    op1_arr         [0:NUM_OF_TESTS-1];
    logic                       [`SCR1_XLEN-1:0]    op2_arr         [0:NUM_OF_TESTS-1];
    logic                       [`SCR1_XLEN-1:0]    ref_result_arr  [0:NUM_OF_TESTS-1];
    type_scr1_ialu_cmd_sel_e                        opcode_arr      [0:NUM_OF_TESTS-1];
    type_scr1_ialu_flags_s                          ref_flag_arr    [0:NUM_OF_TESTS-1];

    // // Current data wires

    // logic                       [`SCR1_XLEN-1:0]    ref_result;         // Reference result
    // type_scr1_ialu_flags_s                          ref_flags;          // Reference flags
    // type_scr1_ialu_cmd_sel_e                        opcode;             // Current operation code (Command)
    
    // ============ Clock init ============
   initial begin
     clk = 1'b0;
      #(PERIOD/2);
      forever
         #(PERIOD/2) clk =  clk;
   end

    // ============ Global reset ============
    initial begin
        rst_n           = 0;
        test1_done      = 0;
        all_tests_done  = 0;
        #(PERIOD);
        rst_n           = 1;
    end

    // ============ Timeout ============
    initial begin
        repeat(100000) @(posedge clk);
        $stop();
    end

    // ============ Test #1: comparing the result with reference values ============
    initial begin
        wait(rst_n);
        for(i = 0; i < NUM_OF_DUMPLINES; i = i + 1) begin
            @(posedge clk);

            case(opcode) 
                SCR1_IALU_CMD_ADD, 
                SCR1_IALU_CMD_SUB: begin
                    if((expected_res !== result_o)) begin
                        error_counter = error_counter + 1;
                        result_error_display();
                    end
                end

                default:    $display("i = %0d, %0t, Not ADD or SUB operation (%s).", i, $time(), operation_type);
            endcase
        end
        $display( "\n\nTest #1 is completed - number of errors: %0d\n\n==========================\nClick the button 'Run All' to continue other test\n==========================\n", error_counter); $stop();
        test1_done = 1;

    end
    // ============ Test #2: comparing the results using random operands ============
    initial begin
        wait(test1_done);
        for(i = 0; i < NUM_OF_RANDLINES; i = i + 1) begin

        end
    end

    function void result_error_display;
        $error("Invalid result! Time: %0t; Res.: %0h; Exp.: %0h; Operation: %s", $time(), result, ref_result, operation_type);
    endfunction

    // ============ Current operation (string to display) ============
    always@(*) begin
        case(opcode)
            SCR1_IALU_CMD_NONE:     operation_type = "NOP    "
            SCR1_IALU_CMD_AND:      operation_type = "ADD    "
            SCR1_IALU_CMD_OR:       operation_type = "OR     "
            SCR1_IALU_CMD_XOR:      operation_type = "XOR    "
            SCR1_IALU_CMD_ADD:      operation_type = "ADD    "
            SCR1_IALU_CMD_SUB:      operation_type = "SUB    "
            SCR1_IALU_CMD_SUB_LT:   operation_type = "SUB_LT " 
            SCR1_IALU_CMD_SUB_LTU:  operation_type = "SUB_LTU"  
            SCR1_IALU_CMD_SUB_EQ:   operation_type = "SUB_EQ " 
            SCR1_IALU_CMD_SUB_NE:   operation_type = "SUB_NE " 
            SCR1_IALU_CMD_SUB_GE:   operation_type = "SUB_GE " 
            SCR1_IALU_CMD_SUB_GEU:  operation_type = "SUB_GEU"  
            SCR1_IALU_CMD_SLL:      operation_type = "SLL    "
            SCR1_IALU_CMD_SRL:      operation_type = "SRL    "
            SCR1_IALU_CMD_SRA:      operation_type = "SRA    "
            SCR1_IALU_CMD_MUL:      operation_type = "MUL    "
            SCR1_IALU_CMD_MULHU:    operation_type = "MULHU  "
            SCR1_IALU_CMD_MULHSU:   operation_type = "MULHSU " 
            SCR1_IALU_CMD_MULH:     operation_type = "MULH   "
            SCR1_IALU_CMD_DIV:      operation_type = "DIV    "
            SCR1_IALU_CMD_DIVU:     operation_type = "DIVU   "
            SCR1_IALU_CMD_REM:      operation_type = "REM    "
            SCR1_IALU_CMD_REMU:     operation_type = "REMU   "
            default:                operation_type = "???????"
        endcase
    end


endmodule