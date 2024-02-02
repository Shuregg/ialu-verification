`include "scr1_arch_description.svh"
`include "scr1_riscv_isa_decoding.svh"
`include "scr1_search_ms1.svh"

module tb_scr1_pipe_ialu.sv ();
    

    logic                           CLK_i,                  // IALU clock                    
    logic                           RST_i,                  // IALU reset                
    logic                           MUL_DIV_OPCODE_VALID_i, // MUL/DIV command valid                    
    logic                           MUL_DIV_RESULT_READY_o, // MUL/DIV result ready           

    logic [`SCR1_XLEN-1:0]          OP1_i,                  // main ALU 1st operand    
    logic [`SCR1_XLEN-1:0]          OP2_i,                  // main ALU 2nd operand    
    type_scr1_ialu_cmd_sel_e        OPCODE_i,               // IALU command            
    logic [`SCR1_XLEN-1:0]          RESULT_o,               // main ALU result        
    logic                           FLAG_o,                 // IALU comparison result    

    logic [`SCR1_XLEN-1:0]          ADDR_OP1_i,             // Address adder 1st operand        
    logic [`SCR1_XLEN-1:0]          ADDR_OP2_i,             // Address adder 2nd operand        
    logic [`SCR1_XLEN-1:0]          ADDR_RESULT_o           // Address adder result            

    //ALU instance
    scr1_pipe_ialu DUT(
    .clk                   (CLK_i),                         // IALU clock
    .rst_n                 (~RST_i),                        // IALU reset
    .exu2ialu_rvm_cmd_vd_i (MUL_DIV_OPCODE_VALID_i),        // MUL/DIV command valid
    .ialu2exu_rvm_res_rdy_o(MUL_DIV_RESULT_READY_o),        // MUL/DIV result ready
    
    .exu2ialu_main_op1_i   (OP1_i),                         // main ALU 1st operand
    .exu2ialu_main_op2_i   (OP2_i),                         // main ALU 2nd operand
    .exu2ialu_cmd_i        (OPCODE_i),                      // IALU command
    .ialu2exu_main_res_o   (RESULT_o),                      // main ALU result
    .ialu2exu_cmp_res_o    (FLAG_o),                        // IALU comparison result

    .exu2ialu_addr_op1_i   (ADDR_OP1_i),                    // Address adder 1st operand
    .exu2ialu_addr_op2_i   (ADDR_OP2_i),                    // Address adder 2nd operand
    .ialu2exu_addr_res_o   (ADDR_RESULT_o)                  // Address adder result
    );

    integer i           = 0;
    integer error_cnt   = 0;

    
endmodule