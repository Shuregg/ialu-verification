`include "scr1_arch_description.svh"
`include "scr1_riscv_isa_decoding.svh"
`include "scr1_search_ms1.svh"

`timescale 1ns/1ps

module tb_scr1_pipe_ialu ();
    logic                                               clk;
    logic                                               rst_n;
    logic                                               mdu_opcode_valid;
    logic                                               mdu_result_ready;
    logic                       [`SCR1_XLEN-1:0]        op1;              
    logic                       [`SCR1_XLEN-1:0]        op2;
    type_scr1_ialu_cmd_sel_e                            opcode;
    logic                       [`SCR1_XLEN-1:0]        result;
    logic                                               flag;

    logic                       [`SCR1_XLEN-1:0]        addr_op1;      
    logic                       [`SCR1_XLEN-1:0]        addr_op2;
    logic                       [`SCR1_XLEN-1:0]        addr_result;

    logic                       [`SCR1_XLEN-1:0]        ref_result;         

    typedef struct {
        logic                       [`SCR1_XLEN-1:0]    op1;
        logic                       [`SCR1_XLEN-1:0]    op2;
        logic                       [`SCR1_XLEN-1:0]    reference_result;
        type_scr1_ialu_cmd_sel_e                        opcode;
//        type_scr1_ialu_flags_s                          reference_flags;
    } st_data_for_testing;

    st_data_for_testing data_tmp;

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
    parameter PERIOD            = 20;
    parameter NUM_OF_DUMPLINES  = 203;
    parameter NUM_OF_RANDLINES  = 15;
    // ============ Integers ============
    integer i                   = 0;
    integer error_counter       = 0;
    // ============ Logic signals ============
    logic                                           test1_done;
    logic                                           all_tests_done;
    logic                       [(7*8)-1:0]         operation_type;


    // Data arrays
    logic                       [`SCR1_XLEN-1:0]    op1_arr         [0:NUM_OF_DUMPLINES-1];
    logic                       [`SCR1_XLEN-1:0]    op2_arr         [0:NUM_OF_DUMPLINES-1];
    logic                       [`SCR1_XLEN-1:0]    ref_result_arr  [0:NUM_OF_DUMPLINES-1];
    type_scr1_ialu_cmd_sel_e                        opcode_arr      [0:NUM_OF_DUMPLINES-1];
    // type_scr1_ialu_flags_s                          ref_flags_arr   [0:NUM_OF_DUMPLINES-1];

    // ============ Clock init ============
   initial begin
     clk = 1'b0;
      #(PERIOD/2);
      forever
         #(PERIOD/2) clk = ~clk;
   end

    // ============ Global reset ============
    task greset();
        begin
            rst_n               = 0;
            mdu_opcode_valid    = 0;
            #(PERIOD/2); rst_n  = 1;
        end
    endtask
    
    // ============ Timeout ============
    initial begin
        repeat(300000) @(posedge clk);
        $display("Simulation stopped by watchdog timer."); $stop();
    end

    // ============ Test #1: comparing the result with reference values ============
    initial begin
        test1_done          <= 0;
        all_tests_done      <= 0;
        greset();
        wait(rst_n);
        $display("============ Test #1: comparing the result with reference values ============");
        for(i = 0; i < NUM_OF_DUMPLINES; i = i + 1) begin
            @(posedge clk);
            op1         <= op1_arr[i];
            op2         <= op2_arr[i];
            opcode      <= opcode_arr[i];
            ref_result  <= ref_result_arr[i];
            @(negedge clk); result_compare_handler();
        end
        @(posedge clk);
        test1_done <= 1;
        $display( "\n\nTest #1 is completed! Number of errors: %0d\n\n==========================\nClick the button 'Run All' to continue other test\n==========================\n", error_counter); $stop();
    end
    
   // ============ Test #2: comparing the results using random operands ============
    initial begin
//    greset();
//    wait(rst_n);
    wait(test1_done);
        $display("============ Test #2: comparing the results using random operands ============");
        $srandom(322);
        for(i = 0; i < NUM_OF_RANDLINES; i = i + 1) begin
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
            @(negedge clk); result_compare_handler();
        end
    end

    function void result_error_handler;
        error_counter = error_counter + 1;
        $error("Invalid result #%0d\nTime: %0t; Op.1: %0h, Op.2: %0h, Res.: %0h; Exp.: %0h; Operation: %s\n=============================================================================", error_counter, $time(), op1, op2, result, ref_result, operation_type);
    endfunction

    function void result_compare_handler;
            case(opcode) 
                SCR1_IALU_CMD_ADD, 
                SCR1_IALU_CMD_SUB: begin
                    if((ref_result !== result)) begin
                        result_error_handler();
                    end
                end
                'X:         $display("\ni=%0d, t=%0t, Operation is undefined (XXX)", i, $time());
                default:    $display("\ni=%0d, t=%0t, Not ADD or SUB operation: %s", i, $time(), operation_type);
            endcase
    endfunction


    // ============ Current operation (string to display) ============
    always@(*) begin
        case(opcode)
            SCR1_IALU_CMD_NONE:     operation_type <= "NOP    ";
            SCR1_IALU_CMD_AND:      operation_type <= "AND    ";
            SCR1_IALU_CMD_OR:       operation_type <= "OR     ";
            SCR1_IALU_CMD_XOR:      operation_type <= "XOR    ";
            SCR1_IALU_CMD_ADD:      operation_type <= "ADD    ";
            SCR1_IALU_CMD_SUB:      operation_type <= "SUB    ";
            SCR1_IALU_CMD_SUB_LT:   operation_type <= "SUB_LT ";
            SCR1_IALU_CMD_SUB_LTU:  operation_type <= "SUB_LTU";
            SCR1_IALU_CMD_SUB_EQ:   operation_type <= "SUB_EQ ";
            SCR1_IALU_CMD_SUB_NE:   operation_type <= "SUB_NE ";
            SCR1_IALU_CMD_SUB_GE:   operation_type <= "SUB_GE ";
            SCR1_IALU_CMD_SUB_GEU:  operation_type <= "SUB_GEU"; 
            SCR1_IALU_CMD_SLL:      operation_type <= "SLL    ";
            SCR1_IALU_CMD_SRL:      operation_type <= "SRL    ";
            SCR1_IALU_CMD_SRA:      operation_type <= "SRA    ";
            SCR1_IALU_CMD_MUL:      operation_type <= "MUL    ";
            SCR1_IALU_CMD_MULHU:    operation_type <= "MULHU  ";
            SCR1_IALU_CMD_MULHSU:   operation_type <= "MULHSU ";
            SCR1_IALU_CMD_MULH:     operation_type <= "MULH   ";
            SCR1_IALU_CMD_DIV:      operation_type <= "DIV    ";
            SCR1_IALU_CMD_DIVU:     operation_type <= "DIVU   ";
            SCR1_IALU_CMD_REM:      operation_type <= "REM    ";
            SCR1_IALU_CMD_REMU:     operation_type <= "REMU   ";
            default:                operation_type <= "???????";
        endcase
    end

    assign op1_arr = {
        32'hb93f376c, // additional XOR
        32'hb93f376c,
        32'h2c46cd19,
        32'h1c4c58c9,
        32'h2f0dc314,
        32'hc8e07142,
        32'he568797b,
        32'hd5a116bc,
        32'hab84adfd,
        32'h34a68f4a,
        32'h1ecdd39a,
        32'he22326fa,
        32'h4665fb70,
        32'ha345fb58,
        32'he5984777,
        32'hb58214bd,
        32'h01bb4ace,
        32'h0b928824,
        32'h98191da2,
        32'h51f80546,
        32'hc6066675,
        32'h5909badf,
        32'hbc0fbfcf,
        32'he535b7f5,
        32'h08744395,
        32'h30cc22e3,
        32'hdce6d7d2,
        32'h12dc3fa9,
        32'h440e6f06,
        32'h61386a8d,
        32'h06eddb2a,
        32'ha7652cfd,
        32'h1fbfd678,
        32'hafb09e33,
        32'h760f5b4a,
        32'h16525a70,
        32'hf9adf95d,
        32'h85e5c4a5,
        32'hc17bfc2f,
        32'h7c511444,
        32'h748c5d1e,
        32'h15ac7a21,
        32'hc01cbb82,
        32'h5239a18c,
        32'h74e0588b,
        32'he224d198,
        32'h0557fd28,
        32'he9471aba,
        32'hec047403,
        32'haabee005,
        32'h143bd42a,
        32'h722f7420,
        32'h7a6cf738,
        32'hc020988a,
        32'h5c23ab9e,
        32'h6d0cb657,
        32'h8617da9f,
        32'he479ecad,
        32'h85b0ac79,
        32'h0299c2e5,
        32'hec1a0bcb,
        32'h09161b07,
        32'h6b619c96,
        32'h33d92cc4,
        32'hd9c8d3f5,
        32'h3ca11e18,
        32'hba33417b,
        32'h394446a9,
        32'h75432cc0,
        32'h2aecb3b4,
        32'ha714f948,
        32'h60503855,
        32'he9d338d6,
        32'h83d4d9ba,
        32'ha31cb7f9,
        32'hbb446304,
        32'h5b520ba3,
        32'h4ccf251e,
        32'hfccf5928,
        32'h13387450,
        32'haddd68af,
        32'hd051f6f6,
        32'h5d447ea3,
        32'h88f76b66,
        32'h2bfd8299,
        32'h7c16ff95,
        32'h181404a1,
        32'h232972cd,
        32'h47f5453a,
        32'h1b861756,
        32'h30db5e36,
        32'hee5eeff1,
        32'h0b4185cb,
        32'h096af168,
        32'h74486e82,
        32'hd1f7296b,
        32'h40ce9c3e,
        32'ha530a939,
        32'h0500527d,
        32'h0db666b3,
        32'h8bf499ff,
        // 2nd hundread started
        32'hec777044,
        32'hda669c82,
        32'h38b990e3,
        32'h523272c8,
        32'hcf65ace7,
        32'hb5260419,
        32'hab28d298,
        32'hb0ea1d59,
        32'h053927a8,
        32'h9d9288b1,
        32'h0fe77a85,
        32'h8699d81a,
        32'h263e2049,
        32'h5068c7a3,
        32'hbb89dc66,
        32'heff84a7d,
        32'h4d6945bc,
        32'hda85f57b,
        32'h51ce97f2,
        32'hc9b09af6,
        32'h1a005488,
        32'h092d2fad,
        32'h4f6e64d8,
        32'h3c7234ef,
        32'h092efe54,
        32'hd28e24f9,
        32'he8add84b,
        32'h01f1af7f,
        32'h57deaa09,
        32'hca47210a,
        32'h64fe3951,
        32'h77dad3de,
        32'hcd790729,
        32'ha89fb9bc,
        32'h6f877d1f,
        32'h18937c02,
        32'hd05cb657,
        32'h24cb74e2,
        32'h07ff58a2,
        32'h90872fea,
        32'h3cd1abd6,
        32'h278b4f0b,
        32'hb0828a13,
        32'h8c5dc1fb,
        32'hfc71675c,
        32'h7b09678c,
        32'h26030310,
        32'hc4ec65e5,
        32'he9fbda9e,
        32'h3b1941ab,
        32'h4bf841e3,
        32'hb1a6d929,
        32'h12d4170c,
        32'h217536cc,
        32'h653cca79,
        32'hc8b3450b,
        32'hbd9f799e,
        32'h77c1d1ac,
        32'h6c644059,
        32'hc443f6f8,
        32'h6eb93d30,
        32'h746ac4ac,
        32'h94ab2b6d,
        32'hd0d2508f,
        32'h0eb45b79,
        32'h4e3bd918,
        32'hf791264e,
        32'ha526330b,
        32'h432ede8d,
        32'h2edfd143,
        32'hfd30038a,
        32'h846a3e8f,
        32'h048dac7e,
        32'h9b478a8c,
        32'h8788e7aa,
        32'h588bcb5a,
        32'h90cbcc1d,
        32'ha4374de3,
        32'ha96533a1,
        32'hc1293452,
        32'h3471d6c6,
        32'h0a4ae53e,
        32'h1e80d4b4,
        32'hf20d7b57,
        32'h26aec4fc,
        32'h6f7bd7d4,
        32'hb3dcf3b8,
        32'h00a60d11,
        32'he361d1b4,
        32'h939e6e99,
        32'h7c619c1c,
        32'hf60ae836,
        32'h63c21de6,
        32'h16aa012e,
        32'h0d1fb9ef,
        32'hc9a1f8d5,
        32'hdbd0559f,
        32'heed3e934,
        32'h72743016,
        32'h41a28951,
        32'h41a28951, // additional AND
        32'h7a57e_0f
    };

    assign op2_arr = {
        32'hd21ebc2c, // additional XOR
        32'hd21ebc2c,
        32'h7b102e19,
        32'h7bdbb80a,
        32'hba37ec2b,
        32'h68aa3bcb,
        32'hbd8e9cd9,
        32'h7d31795a,
        32'h2bb637ae,
        32'h6d590c9f,
        32'h6a21a470,
        32'he260121b,
        32'h70c2d883,
        32'h51fd0d32,
        32'h098bcdda,
        32'hc0fa9eb5,
        32'ha1f3f7e2,
        32'ha142347e,
        32'hf155ddca,
        32'h543f0fa3,
        32'h3dc7ab74,
        32'hd55e125d,
        32'h13bc856e,
        32'h563cecef,
        32'h55db016e,
        32'h6de5abde,
        32'hae211b59,
        32'hc7c992f5,
        32'h3ed1acd8,
        32'h2250ee0e,
        32'h5991c3e5,
        32'hbea8a428,
        32'h23817035,
        32'h776e4d8f,
        32'h41f8f29d,
        32'h3e019b4c,
        32'hb621e7c9,
        32'h11bbcfc5,
        32'ha30b6b29,
        32'h74d8eb6d,
        32'h8983e785,
        32'h718a67d9,
        32'hc61916d5,
        32'h28d14239,
        32'hfbd99378,
        32'hdd78687b,
        32'h4ec00078,
        32'h94e09464,
        32'hcc5ffe59,
        32'h0c3d6c17,
        32'h015f7c88,
        32'h4904c4f8,
        32'h97c599cd,
        32'h309cfb1f,
        32'h2e3f955b,
        32'h74d4cef0,
        32'h75d5864e,
        32'hac72c7a0,
        32'h326f3a9e,
        32'h7595e417,
        32'h49e31b99,
        32'h982748e3,
        32'h942bfec1,
        32'h50962e04,
        32'h039f5a78,
        32'hf8c71009,
        32'h2e0fd15f,
        32'hf2a47deb,
        32'hceee73cf,
        32'h03fd2662,
        32'he717b4ec,
        32'h6724ac43,
        32'h700fc4e9,
        32'hfdc12982,
        32'hda426191,
        32'hf7ee6b4d,
        32'h43a0e3c6,
        32'h82b7905c,
        32'h916cd051,
        32'he1e9ec68,
        32'ha583a79e,
        32'h2648d256,
        32'hca4ee488,
        32'h02c3536f,
        32'h3f6b77d9,
        32'h78a1f892,
        32'hef2587fe,
        32'h601dbb4c,
        32'h73e947db,
        32'hd9862f1a,
        32'hfb931a10,
        32'ha7cbfd4b,
        32'ha7ccb506,
        32'h4808f4b6,
        32'h2791d911,
        32'hc9f166d7,
        32'h2a54e1f5,
        32'h01058f31,
        32'h117ae570,
        32'h43c6f7a8,
        32'hddf2b9a2,
        // 2nd hundread started
        32'hf661c41a,
        32'h99e334b2,
        32'h641c137d,
        32'hb51b305f,
        32'h7ae531f2,
        32'h850896b1,
        32'hbc981307,
        32'h67ec9127,
        32'h95fd994a,
        32'h42e8ebec,
        32'h020ae180,
        32'h41d87e55,
        32'hc35a5273,
        32'hb9bc3baa,
        32'hfd124b81,
        32'h41c683de,
        32'h9e453655,
        32'h55b37df6,
        32'h921f98bd,
        32'h594c74be,
        32'h8d052673,
        32'h1ac7cf64,
        32'hb8d16ecd,
        32'hba708399,
        32'h76c3d513,
        32'hff5283c4,
        32'hf02a280e,
        32'hfb029b77,
        32'h7bef27f5,
        32'hdeaaee53,
        32'hdd708fd0,
        32'hd0523cad,
        32'h17b4a14b,
        32'h99d28f52,
        32'hdd5d322e,
        32'hd2b227b6,
        32'h7510d33d,
        32'ha22382a0,
        32'h0681df83,
        32'h1427d1e5,
        32'hd2c353df,
        32'hc937c275,
        32'h801aaec4,
        32'h2b394e09,
        32'h04bc3f44,
        32'haf993b00,
        32'hac923e2f,
        32'h7c3c3415,
        32'h7cdd8d4b,
        32'h91b2cddf,
        32'h67d3d627,
        32'h985a0952,
        32'h8bfabb9f,
        32'h919d3e9e,
        32'h1a8c3b0f,
        32'h458d89cb,
        32'ha171d78c,
        32'ha6222e69,
        32'heaeda70e,
        32'h465888e9,
        32'hfce6e688,
        32'h7e6d534d,
        32'h1f2ea712,
        32'hc9dc16fd,
        32'hbe7b7fc0,
        32'hd1e8bc36,
        32'hca2b55ef,
        32'hd86536dd,
        32'h99ee4757,
        32'h9aa5e06f,
        32'ha77f189c,
        32'h024403f8,
        32'h1561fdf4,
        32'h41495169,
        32'h84f392b0,
        32'h41b8ad7d,
        32'hc6df7753,
        32'h738fe534,
        32'h3693eff7,
        32'hc9caae61,
        32'hef3e3113,
        32'h5c92852b,
        32'h3c218db7,
        32'h42901102,
        32'hff34c727,
        32'h00402863,
        32'hc31de015,
        32'haa7bc7f2,
        32'ha95e5d6d,
        32'h534a50ef,
        32'hc0b66c27,
        32'h6fded28f,
        32'h86f724bd,
        32'h8c48c116,
        32'hc2dd3867,
        32'h78f77506,
        32'hbccd2e75,
        32'h2f7603a5,
        32'h372e50aa,
        32'hd26d9b03,
        32'hd26d9b03, // additional AND
        32'hfa15e_00
    };

    assign ref_result_arr = {
        32'hDEAD_BEEF, // additional XOR
        32'h8b5df398,
        32'ha756fb32,
        32'h982810d3,
        32'he945af3f,
        32'h318aad0d,
        32'ha2f71654,
        32'h52d29016,
        32'hd73ae5ab,
        32'ha1ff9be9,
        32'h88ef780a,
        32'hc4833915,
        32'hb728d3f3,
        32'hf543088a,
        32'hef241551,
        32'h767cb372,
        32'ha3af42b0,
        32'hacd4bca2,
        32'h896efb6c,
        32'ha63714e9,
        32'h03ce11e9,
        32'h2e67cd3c,
        32'hcfcc453d,
        32'h3b72a4e4,
        32'h5e4f4503,
        32'h9eb1cec1,
        32'h8b07f32b,
        32'hdaa5d29e,
        32'h82e01bde,
        32'h8389589b,
        32'h607f9f0f,
        32'h660dd125,
        32'h434146ad,
        32'h271eebc2,
        32'hb8084de7,
        32'h5453f5bc,
        32'hafcfe126,
        32'h97a1946a,
        32'h64876758,
        32'hf129ffb1,
        32'hfe1044a3,
        32'h8736e1fa,
        32'h8635d257,
        32'h7b0ae3c5,
        32'h70b9ec03,
        32'hbf9d3a13,
        32'h5417fda0,
        32'h7e27af1e,
        32'hb864725c,
        32'hb6fc4c1c,
        32'h159b50b2,
        32'hbb343918,
        32'h12329105,
        32'hf0bd93a9,
        32'h8a6340f9,
        32'he1e18547,
        32'hfbed60ed,
        32'h90ecb44d,
        32'hb81fe717,
        32'h782fa6fc,
        32'h35fd2764,
        32'ha13d63ea,
        32'hff8d9b57,
        32'h846f5ac8,
        32'hdd682e6d,
        32'h35682e21,
        32'he84312da,
        32'h2be8c494,
        32'h4431a08f,
        32'h2ee9da16,
        32'h8e2cae34,
        32'hc774e498,
        32'h59e2fdbf,
        32'h8196033c,
        32'h7d5f198a,
        32'hb332ce51,
        32'h9ef2ef69,
        32'hcf86b57a,
        32'h8e3c2979,
        32'hf52260b8,
        32'h5361104d,
        32'hf69ac94c,
        32'h2793632b,
        32'h8bbabed5,
        32'h6b68fa72,
        32'hf4b8f827,
        32'h07398c9f,
        32'h83472e19,
        32'hbbde8d15,
        32'hf50c4670,
        32'h2c6e7846,
        32'h962aed3c,
        32'hb30e3ad1,
        32'h5173e61e,
        32'h9bda4793,
        32'h9be89042,
        32'h6b237e33,
        32'ha636386a,
        32'h167b37ed,
        32'h517d5e5b,
        32'h69e753a1,
        // 2nd hundread started
        32'hf615ac2a,
        32'h408367d0,
        32'hd49d7d66,
        32'h9d174269,
        32'h54807af5,
        32'h301d6d68,
        32'hee90bf91,
        32'h48fd8c32,
        32'h6f3b8e5e,
        32'h5aa99cc5,
        32'hddc9905,
        32'h44c159c5,
        32'h62e3cdd6,
        32'h96ac8bf9,
        32'hbe7790e5,
        32'hae31c69f,
        32'haf240f67,
        32'h84d27785,
        32'hbfaeff35,
        32'h70642638,
        32'h8cfb2e15,
        32'hee656049,
        32'h969cf60b,
        32'h8201b156,
        32'h926b2941,
        32'hd33ba135,
        32'hf883b03d,
        32'h6ef1408,
        32'hdbef8214,
        32'heb9c32b7,
        32'h878da981,
        32'ha7889731,
        32'hb5c465de,
        32'hecd2a6a,
        32'h922a4af1,
        32'h45e1544c,
        32'h5b4be31a,
        32'h82a7f242,
        32'h17d791f,
        32'h7c5f5e05,
        32'h6a0e57f7,
        32'h5e538c96,
        32'h3067db4f,
        32'h612473f2,
        32'hf7b52818,
        32'hcb702c8c,
        32'h7970c4e1,
        32'h48b031d0,
        32'h6d1e4d53,
        32'ha96673cc,
        32'he4246bbc,
        32'h194ccfd7,
        32'h86d95b6d,
        32'h8fd7f82e,
        32'h4ab08f6a,
        32'h8325bb40,
        32'h1c2da212,
        32'hd19fa343,
        32'h8176994b,
        32'h7deb6e0f,
        32'h71d256a8,
        32'hf5fd715f,
        32'h757c845b,
        32'h6f63992,
        32'h5038dbb9,
        32'h7c531ce2,
        32'h2d65d05f,
        32'hccc0fc2e,
        32'ha9409736,
        32'h9439f0d4,
        32'h55b0eaee,
        32'h82263a97,
        32'hef2bae8a,
        32'h59fe3923,
        32'h29554fa,
        32'h16d31ddd,
        32'hc9ec54ca,
        32'h30a768af,
        32'h72d143aa,
        32'hf75e85f1,
        32'h4533a5b3,
        32'hadb86013,
        32'he25f46fd,
        32'haf7d6a55,
        32'h2779fdd5,
        32'h6f3baf71,
        32'hf0bf13a3,
        32'h562a451f,
        32'h3a037447,
        32'h40541daa,
        32'hbbab2ff5,
        32'h862c15a7,
        32'hdccaf929,
        32'h8a614018,
        32'h4a428188,
        32'h50aa83cf,
        32'h1f03272a,
        32'hbf5de58f,
        32'h3b45df6c,
        32'h6f34ee4e,
        32'h40208901, // additional AND
        32'h0
    };

    assign opcode_arr = {
        SCR1_IALU_CMD_XOR, // additional XOR
        SCR1_IALU_CMD_ADD,
        SCR1_IALU_CMD_ADD,
        SCR1_IALU_CMD_ADD,
        SCR1_IALU_CMD_ADD,
        SCR1_IALU_CMD_ADD,
        SCR1_IALU_CMD_ADD,
        SCR1_IALU_CMD_ADD,
        SCR1_IALU_CMD_ADD,
        SCR1_IALU_CMD_ADD,
        SCR1_IALU_CMD_ADD,
        SCR1_IALU_CMD_ADD,
        SCR1_IALU_CMD_ADD,
        SCR1_IALU_CMD_ADD,
        SCR1_IALU_CMD_ADD,
        SCR1_IALU_CMD_ADD,
        SCR1_IALU_CMD_ADD,
        SCR1_IALU_CMD_ADD,
        SCR1_IALU_CMD_ADD,
        SCR1_IALU_CMD_ADD,
        SCR1_IALU_CMD_ADD,
        SCR1_IALU_CMD_ADD,
        SCR1_IALU_CMD_ADD,
        SCR1_IALU_CMD_ADD,
        SCR1_IALU_CMD_ADD,
        SCR1_IALU_CMD_ADD,
        SCR1_IALU_CMD_ADD,
        SCR1_IALU_CMD_ADD,
        SCR1_IALU_CMD_ADD,
        SCR1_IALU_CMD_ADD,
        SCR1_IALU_CMD_ADD,
        SCR1_IALU_CMD_ADD,
        SCR1_IALU_CMD_ADD,
        SCR1_IALU_CMD_ADD,
        SCR1_IALU_CMD_ADD,
        SCR1_IALU_CMD_ADD,
        SCR1_IALU_CMD_ADD,
        SCR1_IALU_CMD_ADD,
        SCR1_IALU_CMD_ADD,
        SCR1_IALU_CMD_ADD,
        SCR1_IALU_CMD_ADD,
        SCR1_IALU_CMD_ADD,
        SCR1_IALU_CMD_ADD,
        SCR1_IALU_CMD_ADD,
        SCR1_IALU_CMD_ADD,
        SCR1_IALU_CMD_ADD,
        SCR1_IALU_CMD_ADD,
        SCR1_IALU_CMD_ADD,
        SCR1_IALU_CMD_ADD,
        SCR1_IALU_CMD_ADD,
        SCR1_IALU_CMD_ADD,
        SCR1_IALU_CMD_ADD,
        SCR1_IALU_CMD_ADD,
        SCR1_IALU_CMD_ADD,
        SCR1_IALU_CMD_ADD,
        SCR1_IALU_CMD_ADD,
        SCR1_IALU_CMD_ADD,
        SCR1_IALU_CMD_ADD,
        SCR1_IALU_CMD_ADD,
        SCR1_IALU_CMD_ADD,
        SCR1_IALU_CMD_ADD,
        SCR1_IALU_CMD_ADD,
        SCR1_IALU_CMD_ADD,
        SCR1_IALU_CMD_ADD,
        SCR1_IALU_CMD_ADD,
        SCR1_IALU_CMD_ADD,
        SCR1_IALU_CMD_ADD,
        SCR1_IALU_CMD_ADD,
        SCR1_IALU_CMD_ADD,
        SCR1_IALU_CMD_ADD,
        SCR1_IALU_CMD_ADD,
        SCR1_IALU_CMD_ADD,
        SCR1_IALU_CMD_ADD,
        SCR1_IALU_CMD_ADD,
        SCR1_IALU_CMD_ADD,
        SCR1_IALU_CMD_ADD,
        SCR1_IALU_CMD_ADD,
        SCR1_IALU_CMD_ADD,
        SCR1_IALU_CMD_ADD,
        SCR1_IALU_CMD_ADD,
        SCR1_IALU_CMD_ADD,
        SCR1_IALU_CMD_ADD,
        SCR1_IALU_CMD_ADD,
        SCR1_IALU_CMD_ADD,
        SCR1_IALU_CMD_ADD,
        SCR1_IALU_CMD_ADD,
        SCR1_IALU_CMD_ADD,
        SCR1_IALU_CMD_ADD,
        SCR1_IALU_CMD_ADD,
        SCR1_IALU_CMD_ADD,
        SCR1_IALU_CMD_ADD,
        SCR1_IALU_CMD_ADD,
        SCR1_IALU_CMD_ADD,
        SCR1_IALU_CMD_ADD,
        SCR1_IALU_CMD_ADD,
        SCR1_IALU_CMD_ADD,
        SCR1_IALU_CMD_ADD,
        SCR1_IALU_CMD_ADD,
        SCR1_IALU_CMD_ADD,
        SCR1_IALU_CMD_ADD,
        SCR1_IALU_CMD_ADD,
        // ============ Sub ============
        SCR1_IALU_CMD_SUB,
        SCR1_IALU_CMD_SUB,
        SCR1_IALU_CMD_SUB,
        SCR1_IALU_CMD_SUB,
        SCR1_IALU_CMD_SUB,
        SCR1_IALU_CMD_SUB,
        SCR1_IALU_CMD_SUB,
        SCR1_IALU_CMD_SUB,
        SCR1_IALU_CMD_SUB,
        SCR1_IALU_CMD_SUB,
        SCR1_IALU_CMD_SUB,
        SCR1_IALU_CMD_SUB,
        SCR1_IALU_CMD_SUB,
        SCR1_IALU_CMD_SUB,
        SCR1_IALU_CMD_SUB,
        SCR1_IALU_CMD_SUB,
        SCR1_IALU_CMD_SUB,
        SCR1_IALU_CMD_SUB,
        SCR1_IALU_CMD_SUB,
        SCR1_IALU_CMD_SUB,
        SCR1_IALU_CMD_SUB,
        SCR1_IALU_CMD_SUB,
        SCR1_IALU_CMD_SUB,
        SCR1_IALU_CMD_SUB,
        SCR1_IALU_CMD_SUB,
        SCR1_IALU_CMD_SUB,
        SCR1_IALU_CMD_SUB,
        SCR1_IALU_CMD_SUB,
        SCR1_IALU_CMD_SUB,
        SCR1_IALU_CMD_SUB,
        SCR1_IALU_CMD_SUB,
        SCR1_IALU_CMD_SUB,
        SCR1_IALU_CMD_SUB,
        SCR1_IALU_CMD_SUB,
        SCR1_IALU_CMD_SUB,
        SCR1_IALU_CMD_SUB,
        SCR1_IALU_CMD_SUB,
        SCR1_IALU_CMD_SUB,
        SCR1_IALU_CMD_SUB,
        SCR1_IALU_CMD_SUB,
        SCR1_IALU_CMD_SUB,
        SCR1_IALU_CMD_SUB,
        SCR1_IALU_CMD_SUB,
        SCR1_IALU_CMD_SUB,
        SCR1_IALU_CMD_SUB,
        SCR1_IALU_CMD_SUB,
        SCR1_IALU_CMD_SUB,
        SCR1_IALU_CMD_SUB,
        SCR1_IALU_CMD_SUB,
        SCR1_IALU_CMD_SUB,
        SCR1_IALU_CMD_SUB,
        SCR1_IALU_CMD_SUB,
        SCR1_IALU_CMD_SUB,
        SCR1_IALU_CMD_SUB,
        SCR1_IALU_CMD_SUB,
        SCR1_IALU_CMD_SUB,
        SCR1_IALU_CMD_SUB,
        SCR1_IALU_CMD_SUB,
        SCR1_IALU_CMD_SUB,
        SCR1_IALU_CMD_SUB,
        SCR1_IALU_CMD_SUB,
        SCR1_IALU_CMD_SUB,
        SCR1_IALU_CMD_SUB,
        SCR1_IALU_CMD_SUB,
        SCR1_IALU_CMD_SUB,
        SCR1_IALU_CMD_SUB,
        SCR1_IALU_CMD_SUB,
        SCR1_IALU_CMD_SUB,
        SCR1_IALU_CMD_SUB,
        SCR1_IALU_CMD_SUB,
        SCR1_IALU_CMD_SUB,
        SCR1_IALU_CMD_SUB,
        SCR1_IALU_CMD_SUB,
        SCR1_IALU_CMD_SUB,
        SCR1_IALU_CMD_SUB,
        SCR1_IALU_CMD_SUB,
        SCR1_IALU_CMD_SUB,
        SCR1_IALU_CMD_SUB,
        SCR1_IALU_CMD_SUB,
        SCR1_IALU_CMD_SUB,
        SCR1_IALU_CMD_SUB,
        SCR1_IALU_CMD_SUB,
        SCR1_IALU_CMD_SUB,
        SCR1_IALU_CMD_SUB,
        SCR1_IALU_CMD_SUB,
        SCR1_IALU_CMD_SUB,
        SCR1_IALU_CMD_SUB,
        SCR1_IALU_CMD_SUB,
        SCR1_IALU_CMD_SUB,
        SCR1_IALU_CMD_SUB,
        SCR1_IALU_CMD_SUB,
        SCR1_IALU_CMD_SUB,
        SCR1_IALU_CMD_SUB,
        SCR1_IALU_CMD_SUB,
        SCR1_IALU_CMD_SUB,
        SCR1_IALU_CMD_SUB,
        SCR1_IALU_CMD_SUB,
        SCR1_IALU_CMD_SUB,
        SCR1_IALU_CMD_SUB,
        SCR1_IALU_CMD_SUB,
        SCR1_IALU_CMD_AND, // additional AND
        SCR1_IALU_CMD_NONE
    };
endmodule