// Stalling Unit (Cached Version)
//
// Changes from original:
//   1. Added 'cache_stall' input from cache_controller.
//   2. Added 'stall_ex' and 'stall_mem' outputs.
//
// When cache_stall = 1 (cache miss in progress):
//   ALL stages are stalled (IF, ID, EX, MEM).
//
// When cache_stall = 0 (normal operation):
//   Load-use hazard stalls only IF and ID (same as original).
//

module stalling_unit (

    input  [3:0] id_rs1,
    input  [3:0] id_rs2,
    input  [7:0] id_opcode,
    input        ex_mem_read,
    input  [3:0] ex_rd,

    input        cache_stall,    // NEW: from cache_controller

    output reg   stall_if,
    output reg   stall_id,
    output reg   stall_ex,       // NEW: stalls ID/EX register
    output reg   stall_mem       // NEW: stalls EX/MEM and MEM/WB registers
);

    wire id_rs1_valid;
    wire id_rs2_valid;


    // Determine whether the ID-stage instruction actually uses
    // register-read port 1 (Rs1 / effective first source).
    // STORE and STORE_IND use Rd as the first source register,
    // but the actual register address is handled outside this unit.

    assign id_rs1_valid =
           (id_opcode == 8'h02) || // LOAD_IND
           (id_opcode == 8'h04) || // STORE
           (id_opcode == 8'h05) || // STORE_IND
           (id_opcode == 8'h06) || // ADD
           (id_opcode == 8'h07) || // SUB
           (id_opcode == 8'h08) || // MUL
           (id_opcode == 8'h09) || // AND
           (id_opcode == 8'h0A) || // OR
           (id_opcode == 8'h0C) || // CMP
           (id_opcode == 8'h0D) || // EQ
           (id_opcode == 8'h0F) || // JMP_IF
           (id_opcode == 8'h10) || // XOR
           (id_opcode == 8'h11) || // SHL
           (id_opcode == 8'h12) || // SHR
           (id_opcode == 8'h13) || // SAR
           (id_opcode == 8'h14) || // ROL
           (id_opcode == 8'h15) || // ROR
           (id_opcode == 8'h16) || // ADDI
           (id_opcode == 8'h17) || // SUBI
           (id_opcode == 8'h18) || // ANDI
           (id_opcode == 8'h19) || // ORI
           (id_opcode == 8'h1A) || // XORI
           (id_opcode == 8'h1B) || // MOV
           (id_opcode == 8'h1C) || // SLT
           (id_opcode == 8'h1D) || // SLTU
           (id_opcode == 8'h26);   // JMP_REG

    // Determine whether the ID-stage instruction actually uses
    // register-read port 2 (Rs2).

    assign id_rs2_valid =
           (id_opcode == 8'h05) || // STORE_IND
           (id_opcode == 8'h06) || // ADD
           (id_opcode == 8'h07) || // SUB
           (id_opcode == 8'h08) || // MUL
           (id_opcode == 8'h09) || // AND
           (id_opcode == 8'h0A) || // OR
           (id_opcode == 8'h0C) || // CMP
           (id_opcode == 8'h0D) || // EQ
           (id_opcode == 8'h10) || // XOR
           (id_opcode == 8'h11) || // SHL
           (id_opcode == 8'h12) || // SHR
           (id_opcode == 8'h13) || // SAR
           (id_opcode == 8'h14) || // ROL
           (id_opcode == 8'h15) || // ROR
           (id_opcode == 8'h1C) || // SLT
           (id_opcode == 8'h1D);   // SLTU

    always @(*) begin

        // Default: no stall
        stall_if  = 1'b0;
        stall_id  = 1'b0;
        stall_ex  = 1'b0;
        stall_mem = 1'b0;

        // ----------------------------------------------------
        // CACHE STALL — freeze the entire pipeline.
        // Takes priority over load-use stall.
        // ----------------------------------------------------

        if (cache_stall) begin
            stall_if  = 1'b1;
            stall_id  = 1'b1;
            stall_ex  = 1'b1;
            stall_mem = 1'b1;
        end

        // ----------------------------------------------------
        // LOAD-USE HAZARD — stall IF and ID only.
        // EX gets a bubble via flush_unit (not stalled here).
        // ----------------------------------------------------

        else if( ((id_rs1 == ex_rd && id_rs1_valid) || (id_rs2 == ex_rd && id_rs2_valid)) && ex_mem_read) begin
            stall_if = 1'b1;
            stall_id = 1'b1;
        end

    end

endmodule
