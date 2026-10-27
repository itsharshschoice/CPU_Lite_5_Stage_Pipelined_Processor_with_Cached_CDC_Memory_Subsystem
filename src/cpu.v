module cpu (
    input clk,
    input rstn,

    // Cache interface to Memory / CDC Bridge
    output         mem_req_valid,
    input          mem_req_ready,
    output         mem_req_we,
    output [11:0]  mem_req_addr,
    output [127:0] mem_req_wdata,

    input          mem_resp_valid,
    input  [127:0] mem_resp_rdata
);

    wire [11:0] pc_current;
    wire [11:0] pc_plus_one;
    wire [11:0] pc_next;

    wire [31:0] instruction_out;

    wire [11:0] pc_selected;

    wire [31:0] if_id_instruction;


    // ID STAGE


    wire [7:0]  id_opcode;
    wire [3:0]  id_rd;
    wire [3:0]  id_rs1;
    wire [3:0]  id_rs2;
    wire [11:0] id_instruction_imm;

    wire [3:0] register_read_addr1;

    wire [31:0] id_rs1_data;
    wire [31:0] id_rs2_data;

    wire [31:0] id_immediate;

    wire        id_reg_write;
    wire        id_mem_read;
    wire        id_mem_write;
    wire        id_alu_src;
    wire [3:0]  id_alu_control;
    wire [1:0]  id_wb_sel;

    wire id_flag_we_z;
    wire id_flag_we_n;
    wire id_flag_we_c;
    wire id_flag_we_v;

    wire id_control_pc_src;
    wire id_halt;



    // EX STAGE


    wire [7:0] ex_opcode;

    wire [31:0] ex_rs1_data;
    wire [31:0] ex_rs2_data;
    wire [31:0] ex_immediate;

    wire [11:0] ex_imm_addr;

    wire [3:0] ex_rd;
    wire [3:0] ex_rs1;
    wire [3:0] ex_rs2;

    wire ex_reg_write;
    wire ex_mem_read;
    wire ex_mem_write;

    wire ex_alu_src;
    wire [3:0] ex_alu_control;

    wire [1:0] ex_wb_sel;

    wire ex_flag_we_z;
    wire ex_flag_we_n;
    wire ex_flag_we_c;
    wire ex_flag_we_v;

    wire ex_pc_src;
    wire ex_halt;


    wire [31:0] ex_alu_operand2;

    wire [31:0] ex_alu_result;

    wire ex_alu_Z;
    wire ex_alu_N;
    wire ex_alu_C;
    wire ex_alu_V;


    wire [3:0] PSR;

    wire ex_branch_pc_src;
    wire [11:0] ex_branch_pc_target;

    wire ex_final_pc_src;


 
    // MEM STAGE


    wire [31:0] mem_alu_result;

    wire [31:0] mem_rs1_data;
    wire [31:0] mem_rs2_data;

    wire [31:0] mem_immediate;
    wire [11:0] mem_imm_addr;

    wire [7:0] mem_opcode;

    wire [3:0] mem_rd;

    wire mem_reg_write;
    wire mem_read;
    wire mem_write;

    wire [1:0] mem_wb_sel;

    wire mem_pc_src;
    wire mem_halt;


    wire [13:0] direct_address;
    wire [13:0] indirect_address;
    wire [13:0] memory_address;

    wire direct_address_select;

    wire [31:0] memory_write_data;
    wire [31:0] memory_read_data;



    // WB STAGE


    wire [31:0] wb_alu_result;
    wire [31:0] wb_memory_read_data;
    wire [31:0] wb_immediate;
    wire [31:0] wb_rs1_data;

    wire [3:0] wb_rd;

    wire wb_reg_write;
    wire [1:0] wb_sel;

    wire wb_halt;

    wire [31:0] write_back_data;



    // HAZARD UNIT SIGNALS


    wire [1:0] forward_a_ex;
    wire [1:0] forward_b_ex;

    wire stall_if;
    wire stall_id;
    wire stall_ex;
    wire stall_mem;

    wire flush_id;
    wire flush_ex;
    
    wire cache_stall;



    // FORWARDING SIGNALS


    wire [31:0] ex_forwarded_rs1_data;
    wire [31:0] ex_forwarded_rs2_data;

    wire [31:0] mem_forward_data;



    // HAZARD UNIT


    hazard_unit hazard (
        .id_rs1          (register_read_addr1),
        .id_rs2          (id_rs2),
        .id_opcode       (id_opcode),

        .ex_rs1          (ex_rs1),
        .ex_rs2          (ex_rs2),
        .ex_opcode       (ex_opcode),

        .ex_mem_read     (ex_mem_read),
        .ex_rd           (ex_rd),

        .ex_final_pc_src (ex_final_pc_src),

        .mem_reg_write   (mem_reg_write),
        .mem_read        (mem_read),
        .mem_rd          (mem_rd),

        .wb_reg_write    (wb_reg_write),
        .wb_rd           (wb_rd),

        .cache_stall     (cache_stall),

        .forward_a_ex    (forward_a_ex),
        .forward_b_ex    (forward_b_ex),

        .stall_if        (stall_if),
        .stall_id        (stall_id),
        .stall_ex        (stall_ex),
        .stall_mem       (stall_mem),

        .flush_id        (flush_id),
        .flush_ex        (flush_ex)
    );



    // IF STAGE


    pc pc_reg (
        .clk    (clk),
        .rstn   (rstn),
        .pc_in  (pc_next),
        .pc_out (pc_current)
    );


    pc_adder pc_incrementer (
        .pc_in   (pc_current),
        .pc_next (pc_plus_one)
    );


    program_memory program_mem (
        .read_address    (pc_current),
        .instruction_out (instruction_out)
    );


    if_id_register if_id (
        .clk             (clk),
        .rstn            (rstn),

        .stall           (stall_id),
        .flush           (flush_id),

        .instruction_in  (instruction_out),
        .instruction_out (if_id_instruction)
    );



    // ID STAGE


    assign id_opcode          = if_id_instruction[31:24];
    assign id_rd              = if_id_instruction[23:20];
    assign id_rs1             = if_id_instruction[19:16];
    assign id_rs2             = if_id_instruction[15:12];
    assign id_instruction_imm = if_id_instruction[11:0];


    control_unit control (
        .opcode      (id_opcode),

        .reg_write   (id_reg_write),
        .mem_read    (id_mem_read),
        .mem_write   (id_mem_write),

        .alu_src     (id_alu_src),
        .alu_control (id_alu_control),

        .wb_sel      (id_wb_sel),

        .flag_we_z   (id_flag_we_z),
        .flag_we_n   (id_flag_we_n),
        .flag_we_c   (id_flag_we_c),
        .flag_we_v   (id_flag_we_v),

        .pc_src      (id_control_pc_src),
        .halt        (id_halt)
    );


    // STORE and STORE_IND use Rd as their first source register.
    assign register_read_addr1 =
        (id_opcode == 8'h04 || id_opcode == 8'h05) ?
        id_rd :
        id_rs1;


    // WB -> ID write-through is handled inside register_file.
    register_file registers (
        .clk        (clk),
        .rstn       (rstn),

        .rs1        (register_read_addr1),
        .rs2        (id_rs2),

        .rd         (wb_rd),
        .write_data (write_back_data),
        .reg_write  (wb_reg_write),

        .read_data1 (id_rs1_data),
        .read_data2 (id_rs2_data)
    );


    immediate_generator imm_gen (
        .instruction   (if_id_instruction),
        .immediate_out (id_immediate)
    );



    // ID -> EX PIPELINE REGISTER


    id_ex_register id_ex (
        .clk               (clk),
        .rstn              (rstn),

        .stall             (stall_ex),
        .flush             (flush_ex),

        .opcode_in         (id_opcode),

        .rs1_data_in       (id_rs1_data),
        .rs2_data_in       (id_rs2_data),

        .immediate_in      (id_immediate),
        .imm_addr_in       (id_instruction_imm),

        .rd_in             (id_rd),
        .rs1_in            (register_read_addr1),
        .rs2_in            (id_rs2),

        .reg_write_in      (id_reg_write),
        .mem_read_in       (id_mem_read),
        .mem_write_in      (id_mem_write),

        .alu_src_in        (id_alu_src),
        .alu_control_in    (id_alu_control),

        .wb_sel_in         (id_wb_sel),

        .flag_we_z_in      (id_flag_we_z),
        .flag_we_n_in      (id_flag_we_n),
        .flag_we_c_in      (id_flag_we_c),
        .flag_we_v_in      (id_flag_we_v),

        .pc_src_in         (id_control_pc_src),
        .halt_in           (id_halt),

        .opcode_out        (ex_opcode),

        .rs1_data_out      (ex_rs1_data),
        .rs2_data_out      (ex_rs2_data),

        .immediate_out     (ex_immediate),
        .imm_addr_out      (ex_imm_addr),

        .rd_out            (ex_rd),
        .rs1_out           (ex_rs1),
        .rs2_out           (ex_rs2),

        .reg_write_out     (ex_reg_write),
        .mem_read_out      (ex_mem_read),
        .mem_write_out     (ex_mem_write),

        .alu_src_out       (ex_alu_src),
        .alu_control_out   (ex_alu_control),

        .wb_sel_out        (ex_wb_sel),

        .flag_we_z_out     (ex_flag_we_z),
        .flag_we_n_out     (ex_flag_we_n),
        .flag_we_c_out     (ex_flag_we_c),
        .flag_we_v_out     (ex_flag_we_v),

        .pc_src_out        (ex_pc_src),
        .halt_out          (ex_halt)
    );



    // EX STAGE


    // Data available from EX/MEM for forwarding.
    // LOAD cannot be forwarded from EX/MEM because its data
    // is only available after the MEM stage.
    assign mem_forward_data =
        (mem_wb_sel == 2'b00) ? mem_alu_result :
        (mem_wb_sel == 2'b10) ? mem_immediate :
        (mem_wb_sel == 2'b11) ? mem_rs1_data :
                                32'b0;


    // Forwarded operand 1.
    assign ex_forwarded_rs1_data =
        (forward_a_ex == 2'b10) ? mem_forward_data :
        (forward_a_ex == 2'b01) ? write_back_data :
                                  ex_rs1_data;


    // Forwarded operand 2.
    assign ex_forwarded_rs2_data =
        (forward_b_ex == 2'b10) ? mem_forward_data :
        (forward_b_ex == 2'b01) ? write_back_data :
                                  ex_rs2_data;


    // ALU operand 2.
    assign ex_alu_operand2 =
        ex_alu_src ?
        ex_immediate :
        ex_forwarded_rs2_data;


    alu alu_unit (
        .operand1    (ex_forwarded_rs1_data),
        .operand2    (ex_alu_operand2),
        .alu_control (ex_alu_control),

        .result      (ex_alu_result),

        .Z           (ex_alu_Z),
        .N           (ex_alu_N),
        .C           (ex_alu_C),
        .V           (ex_alu_V)
    );


    processor_status_register psr (
        .clk       (clk),
        .rstn      (rstn),

        .flag_we_z (ex_flag_we_z),
        .flag_we_n (ex_flag_we_n),
        .flag_we_c (ex_flag_we_c),
        .flag_we_v (ex_flag_we_v),

        .Z         (ex_alu_Z),
        .N         (ex_alu_N),
        .C         (ex_alu_C),
        .V         (ex_alu_V),

        .PSR       (PSR)
    );


    branch_jump_logic branch_jump (
        .opcode           (ex_opcode),

        .instruction_addr (ex_imm_addr),

        .rs1_data         (ex_forwarded_rs1_data),

        .Z                (PSR[0]),
        .N                (PSR[1]),
        .C                (PSR[2]),
        .V                (PSR[3]),

        .pc_src           (ex_branch_pc_src),
        .pc_target        (ex_branch_pc_target)
    );


    assign ex_final_pc_src =
        ex_pc_src & ex_branch_pc_src;


    assign pc_selected =
        ex_final_pc_src ?
        ex_branch_pc_target :
        pc_plus_one;


    // PC priority:
    // 1. HALT - hold PC
    // 2. STALL - hold PC
    // 3. Otherwise use normal/branch-selected PC
    assign pc_next =
        ex_halt ?
        pc_current :
        stall_if ?
        pc_current :
        pc_selected;



    // EX -> MEM PIPELINE REGISTER


    ex_mem_register ex_mem (
        .clk              (clk),
        .rstn             (rstn),

        .stall            (stall_mem),

        .alu_result_in    (ex_alu_result),

        // Store/address data must also use forwarded values.
        .rs1_data_in      (ex_forwarded_rs1_data),
        .rs2_data_in      (ex_forwarded_rs2_data),

        .immediate_in     (ex_immediate),
        .imm_addr_in      (ex_imm_addr),

        .opcode_in        (ex_opcode),

        .rd_in            (ex_rd),

        .reg_write_in     (ex_reg_write),

        .mem_read_in      (ex_mem_read),
        .mem_write_in     (ex_mem_write),

        .wb_sel_in        (ex_wb_sel),

        .pc_src_in        (ex_pc_src),
        .halt_in          (ex_halt),

        .alu_result_out   (mem_alu_result),

        .rs1_data_out     (mem_rs1_data),
        .rs2_data_out     (mem_rs2_data),

        .immediate_out    (mem_immediate),
        .imm_addr_out     (mem_imm_addr),

        .opcode_out       (mem_opcode),

        .rd_out           (mem_rd),

        .reg_write_out    (mem_reg_write),

        .mem_read_out     (mem_read),
        .mem_write_out    (mem_write),

        .wb_sel_out        (mem_wb_sel),

        .pc_src_out       (mem_pc_src),
        .halt_out         (mem_halt)
    );



    // MEM STAGE


    assign direct_address =
        {2'b00, mem_imm_addr};


    assign indirect_address =
        (mem_opcode == 8'h02) ?
        mem_rs1_data[13:0] :
        mem_rs2_data[13:0];


    assign direct_address_select =
        (mem_opcode == 8'h01) ||
        (mem_opcode == 8'h04);


    assign memory_address =
        direct_address_select ?
        direct_address :
        indirect_address;


    assign memory_write_data =
        mem_rs1_data;


    // Cache controller connects CPU to the external Memory / CDC bridge
    cache_controller cache_ctrl (
        .clk            (clk),
        .rstn           (rstn),

        .cpu_addr       (memory_address),
        .cpu_wdata      (memory_write_data),
        .cpu_mem_read   (mem_read),
        .cpu_mem_write  (mem_write),
        .cpu_rdata      (memory_read_data),
        .cache_stall    (cache_stall),

        .mem_req_valid  (mem_req_valid),
        .mem_req_ready  (mem_req_ready),
        .mem_req_we     (mem_req_we),
        .mem_req_addr   (mem_req_addr),
        .mem_req_wdata  (mem_req_wdata),

        .mem_resp_valid (mem_resp_valid),
        .mem_resp_rdata (mem_resp_rdata)
    );



    // MEM -> WB PIPELINE REGISTER


    mem_wb_register mem_wb (
        .clk                   (clk),
        .rstn                  (rstn),

        .stall                 (stall_mem),

        .alu_result_in         (mem_alu_result),
        .memory_read_data_in   (memory_read_data),
        .immediate_in          (mem_immediate),
        .rs1_data_in           (mem_rs1_data),

        .rd_in                 (mem_rd),

        .reg_write_in          (mem_reg_write),
        .wb_sel_in             (mem_wb_sel),

        .halt_in               (mem_halt),

        .alu_result_out        (wb_alu_result),
        .memory_read_data_out  (wb_memory_read_data),
        .immediate_out         (wb_immediate),
        .rs1_data_out          (wb_rs1_data),

        .rd_out                (wb_rd),

        .reg_write_out         (wb_reg_write),
        .wb_sel_out            (wb_sel),

        .halt_out              (wb_halt)
    );



    // WB STAGE


    assign write_back_data =
        (wb_sel == 2'b00) ? wb_alu_result :
        (wb_sel == 2'b01) ? wb_memory_read_data :
        (wb_sel == 2'b10) ? wb_immediate :
                            wb_rs1_data; // MOV

endmodule