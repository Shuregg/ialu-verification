`include "scr1_arch_description.svh"
`include "scr1_riscv_isa_decoding.svh"
`include "scr1_search_ms1.svh"

`timescale 1ns/1ps

module tb_scr1_pipe_ialu ();
    // ============ Parameters ============
    localparam PERIOD            = 20;                                                           // Clock period
    localparam RND_SEED          = 322;                                                          // Seed of random generation. Change it to test your device with different values
            
    // ============ Integers ============
    integer                 i                   = 0;                                            // Cycle iterator
    integer                 error_counter       = 0;                                            //
    longint unsigned        NUM_OF_RANDLINES    = (1000000);                                 // Nubmer of tests with random data values
   const longint unsigned   num_of_bins         = longint'($pow(2, `SCR1_XLEN));                //
    // ============ Logic signals ============
    logic                                           clk;
    logic                                           rst_n;
    logic                       [`SCR1_XLEN-1:0]    op1;              
    logic                       [`SCR1_XLEN-1:0]    op2;
    type_scr1_ialu_cmd_sel_e                        opcode;
    logic                       [`SCR1_XLEN-1:0]    result;

    logic                       [`SCR1_XLEN-1:0]    ref_result;         
    logic                                           test2_done;                                 // "Test 2 is completed" Flag

    //ALU instance
    scr1_pipe_ialu DUT(
    .clk                   (clk),                                                               // IALU clock
    .rst_n                 (rst_n),                                                             // IALU reset
    .exu2ialu_rvm_cmd_vd_i (),                                                                  // MUL/DIV command valid
    .ialu2exu_rvm_res_rdy_o(),                                                                  // MUL/DIV result ready
                                            
    .exu2ialu_main_op1_i   (op1),                                                               // main ALU 1st operand
    .exu2ialu_main_op2_i   (op2),                                                               // main ALU 2nd operand
    .exu2ialu_cmd_i        (opcode),                                                            // IALU command
    .ialu2exu_main_res_o   (result),                                                            // main ALU result
    .ialu2exu_cmp_res_o    (flag),                                                              // IALU comparison result
                                        
    .exu2ialu_addr_op1_i   (),                                                                  // Address adder 1st operand
    .exu2ialu_addr_op2_i   (),                                                                  // Address adder 2nd operand
    .ialu2exu_addr_res_o   ()                                                                   // Address adder result
    );                                      

//    // ============ Functional coverage ============
//    covergroup cg @(posedge clk);
//        op1_cp:     coverpoint op1 {
//            bins b1 [(1000000)] = {[0:32'hFFFF_FFFF]};
//        }
//        op2_cp:     coverpoint op2 {
//            bins b2 [(1000000)] = {[0:32'hFFFF_FFFF]};
//        }
//        result_cp:  coverpoint result{
//            bins b3 [(1000000)] = {[0:32'hFFFF_FFFF]};
//        }
//    endgroup : cg
    
//    cg cover_inst = new();
    
    // ============ Clock init ============ 
    // “.к. данный тестбенч провер€ет лишь операции ADD и SUB, 
    // логика которых €вл€етс€ комбинационной схемой,
    // тактовый сигнал используетс€ исключительно дл€ удобного отображени€ значений на временной диаграмме (это касалось и сигналов test1/2_done),
    // т.е формирует временные задержки между командами дл€ возможности проверки этих самых значений.
   initial begin
     clk = 1'b0;
      #(PERIOD/2);
      forever
         #(PERIOD/2) clk = ~clk;
   end
    
    // ============ Timeout ============
    initial begin
        repeat(NUM_OF_RANDLINES+100) @(posedge clk);
        $display("Simulation stopped by watchdog timer."); $stop();
    end

    // ============ Main initial block ============
    initial begin
        rst_n               = 0;
        #(PERIOD/2); rst_n  = 1;
        test2(NUM_OF_RANDLINES);
//        wait(test2_done);
        if(error_counter == 0) begin
            $display("SUCCESS! The ADD and SUB operations work correctly!");
            $finish();
        end
        else begin
            $display("FAILURE! Something is not working correctly. Check the console for more information.");
            $finish();
        end
    end
    
   // ============ Test #2: comparing the results using random operands ============
    task test2 (integer num_of_tests);
        begin
            $display("============ Test #2: comparing the results using random operands ============");
            $srandom(RND_SEED);
            for(i = 0; i < num_of_tests; i = i + 1) begin
                @(posedge clk);

                case($urandom_range(0, 1))
                    1'b0: begin
                        op1         = $urandom();
                        op2         = $urandom();
                        opcode      = SCR1_IALU_CMD_ADD;
                        ref_result  = op1 + op2;
                    end
                    1'b1: begin
                        op1         = $urandom();
                        op2         = $urandom();
                        opcode      = SCR1_IALU_CMD_SUB;
                        ref_result  = op1 - op2;
                    end
                endcase
//                #(PERIOD/2);
                @(negedge clk);
                 result_compare_handler();
            end
            @(posedge clk);
            test2_done = 1;
            $display( "\n\nTest #2 is completed! Total number of errors: %0d\n\n====================================================\nClick the button 'Run All' to continue.\n====================================================\n", error_counter); $stop();
        end
    endtask

    function void result_error_handler;
        error_counter = error_counter + 1;
        $error("Invalid result #%0d\nTime: %0t; Op.1: %0h, Op.2: %0h, Res.: %0h; Exp.: %0h; Operation: %0s\n=============================================================================", error_counter, $time(), op1, op2, result, ref_result, opcode.name());
    endfunction

    function void result_compare_handler;
            case(opcode) 
                SCR1_IALU_CMD_ADD, 
                SCR1_IALU_CMD_SUB: begin
                    if((ref_result !== result)) begin
                        result_error_handler();
                    end else  begin
                        $display("\n i: %d\nTime: %0t; Op.1: %0h, Op.2: %0h, Res.: %0h; Exp.: %0h; Operation: %0s\n=============================================================================", i, $time(), op1, op2, result, ref_result, opcode.name());
                    end
                end
                'X:         $display("\ni=%0d, t=%0t, Operation is undefined (XXX)", i, $time());
                default:    $display("\ni=%0d, t=%0t, Not ADD or SUB operation: %s", i, $time(), opcode.name());
            endcase
    endfunction
endmodule