`timescale 1ns/1ps

`include "scr1_arch_description.svh"
`include "scr1_riscv_isa_decoding.svh"
`include "scr1_search_ms1.svh"

module tb_scr1_pipe_ialu ();
    

    logic                                               CLK,                // IALU clock                    
    logic                                               RST_N,              // IALU reset                
    logic                                               MDU_OPCODE_VALID,   // MUL/DIV command valid                    
    logic                                               MDU_RESULT_READY,   // MUL/DIV result ready           

    logic                       [`SCR1_XLEN-1:0]        OP1,                // main ALU 1st operand    
    logic                       [`SCR1_XLEN-1:0]        OP2,                // main ALU 2nd operand    
    type_scr1_ialu_cmd_sel_e                            OPCODE,             // IALU command            
    logic                       [`SCR1_XLEN-1:0]        RESULT,             // main ALU result        
    logic                                               FLAG,               // IALU comparison result    

    logic                       [`SCR1_XLEN-1:0]        ADDR_OP1,           // Address adder 1st operand        
    logic                       [`SCR1_XLEN-1:0]        ADDR_OP2,           // Address adder 2nd operand        
    logic                       [`SCR1_XLEN-1:0]        ADDR_RESULT         // Address adder result      

    logic                       [`SCR1_XLEN-1:0]        ref_result;         // Reference result
    type_scr1_ialu_flags_s                              ref_flags;          // Reference flags

    //ALU instance
    scr1_pipe_ialu DUT(
    .clk                   (CLK),                         // IALU clock
    .rst_n                 (RST_N),                       // IALU reset
    .exu2ialu_rvm_cmd_vd_i (MDU_OPCODE_VALID),            // MUL/DIV command valid
    .ialu2exu_rvm_res_rdy_o(MDU_RESULT_READY),            // MUL/DIV result ready
    
    .exu2ialu_main_op1_i   (OP1),                         // main ALU 1st operand
    .exu2ialu_main_op2_i   (OP2),                         // main ALU 2nd operand
    .exu2ialu_cmd_i        (OPCODE),                      // IALU command
    .ialu2exu_main_res_o   (RESULT),                      // main ALU result
    .ialu2exu_cmp_res_o    (FLAG),                        // IALU comparison result

    .exu2ialu_addr_op1_i   (ADDR_OP1),                    // Address adder 1st operand
    .exu2ialu_addr_op2_i   (ADDR_OP2),                    // Address adder 2nd operand
    .ialu2exu_addr_res_o   (ADDR_RESULT)                  // Address adder result
    );

    parameter PERIOD        = 20ns;
    parameter NUM_OF_TESTS  = 10; 

    integer i           = 0;
    integer error_cnt   = 0;

    // // Data arrays
    // logic                       [`SCR1_XLEN-1:0]    OP1_ARR [0:NUM_OF_TESTS-1];
    // logic                       [`SCR1_XLEN-1:0]    OP2_ARR [0:NUM_OF_TESTS-1];
    // logic                       [`SCR1_XLEN-1:0]    RES_ARR [0:NUM_OF_TESTS-1];
    // type_scr1_ialu_cmd_sel_e                        OPC_ARR [0:NUM_OF_TESTS-1];
    // type_scr1_ialu_flags_s                          FLG_ARR [0:NUM_OF_TESTS-1];

    // // Current data wires
    // logic                       [`SCR1_XLEN-1:0]    operand_1;          // Current operand #1
    // logic                       [`SCR1_XLEN-1:0]    operand_2;          // Current operand #2
    // logic                       [`SCR1_XLEN-1:0]    ref_result;         // Reference result
    // type_scr1_ialu_flags_s                          ref_flags;          // Reference flags
    // type_scr1_ialu_cmd_sel_e                        opcode;             // Current operation code (Command)
    
    // Clock init
    always begin
        CLK = 1'b0;
        #(PERIOD/2) CLK = 1'b1;
        #(PERIOD/2);
    end



    initial begin
        // Start reset
        RST_N = 0;
        #PERIOD * 2;
        RST_N = 1;

        wait(RST_N);
        for(i = 0; i < NUM_OF_TESTS; i = i + 1) begin
            @(posedge CLK);

        end
    end

endmodule