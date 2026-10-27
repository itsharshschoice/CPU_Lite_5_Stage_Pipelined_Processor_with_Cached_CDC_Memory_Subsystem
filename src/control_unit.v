module control_unit (
    input [7:0] opcode,
    output reg reg_write,
    output reg mem_read,
    output reg mem_write,
    output reg alu_src,
    output reg [3:0] alu_control,
    output reg [1:0] wb_sel,
    output reg flag_we_z,
    output reg flag_we_n,
    output reg flag_we_c,
    output reg flag_we_v,
    output reg pc_src,
    output reg halt
);

always @(*) begin
    // Default values
    reg_write = 1'b0;
    mem_read = 1'b0;
    mem_write = 1'b0;
    alu_src = 1'b0;
    alu_control = 4'h0;
    wb_sel = 2'b00;
    flag_we_z = 1'b0;
    flag_we_n = 1'b0;
    flag_we_c = 1'b0;
    flag_we_v = 1'b0;
    pc_src = 1'b0;
    halt = 1'b0;
    case (opcode)
        8'h00: begin
            // NOP
        end
        8'h01: begin
            // LOAD
            reg_write = 1'b1;
            mem_read = 1'b1;
            wb_sel = 2'b01;
        end
        8'h02: begin
            // LOAD_IND
            reg_write = 1'b1;
            mem_read  = 1'b1;
            wb_sel    = 2'b01;
        end
        8'h03: begin
            // LOAD_IMM
            reg_write = 1'b1;
            wb_sel    = 2'b10;
        end
        8'h04: begin
            // STORE
            mem_write = 1'b1;
        end
        8'h05: begin
            // STORE_IND
            mem_write = 1'b1;
        end
        8'h06: begin
            // ADD
            reg_write   = 1'b1;
            alu_control = 4'h0;
            flag_we_z = 1'b1;
            flag_we_n = 1'b1;
            flag_we_c = 1'b1;
            flag_we_v = 1'b1;
        end
        8'h07: begin
            // SUB
            reg_write   = 1'b1;
            alu_control = 4'h1;
            flag_we_z = 1'b1;
            flag_we_n = 1'b1;
            flag_we_c = 1'b1;
            flag_we_v = 1'b1;
        end
        8'h08: begin
            // MUL
            reg_write   = 1'b1;
            alu_control = 4'h3;
            flag_we_z = 1'b1;
            flag_we_n = 1'b1;
        end
        8'h09: begin
            // AND
            reg_write   = 1'b1;
            alu_control = 4'h4;
            flag_we_z = 1'b1;
            flag_we_n = 1'b1;
        end
        8'h0A: begin
            // OR
            reg_write   = 1'b1;
            alu_control = 4'h5;
            flag_we_z = 1'b1;
            flag_we_n = 1'b1;
        end
        8'h0B: begin
            // NOT
            reg_write   = 1'b1;
            alu_control = 4'h6;
            flag_we_z = 1'b1;
            flag_we_n = 1'b1;
        end
        8'h0C: begin
            // CMP
            alu_control = 4'h1;
            flag_we_z = 1'b1;
            flag_we_n = 1'b1;
            flag_we_c = 1'b1;
            flag_we_v = 1'b1;
        end
        8'h0D: begin
            // EQ
            reg_write   = 1'b1;
            alu_control = 4'h2;
            flag_we_z = 1'b1;
        end

        8'h0E: begin
            // JMP
            pc_src = 1'b1;
        end
        8'h0F: begin
            // JMP_IF
            pc_src = 1'b1;
        end
        8'h10: begin
            // XOR
            reg_write = 1'b1;
            alu_control = 4'hA;
            flag_we_z = 1'b1;
            flag_we_n = 1'b1;
        end
        8'h11: begin
            // SHL
            reg_write   = 1'b1;
            alu_control = 4'h7;
            flag_we_z = 1'b1;
            flag_we_n = 1'b1;
        end
        8'h12: begin
            // SHR
            reg_write   = 1'b1;
            alu_control = 4'h8;
            flag_we_z = 1'b1;
            flag_we_n = 1'b1;
        end

        8'h13: begin
            // SAR
            reg_write   = 1'b1;
            alu_control = 4'h9;
            flag_we_z = 1'b1;
            flag_we_n = 1'b1;
        end
        8'h14: begin
            // ROL
            reg_write   = 1'b1;
            alu_control = 4'hB;
            flag_we_z = 1'b1;
            flag_we_n = 1'b1;
        end
        8'h15: begin
            // ROR
            reg_write   = 1'b1;
            alu_control = 4'hC;
            flag_we_z = 1'b1;
            flag_we_n = 1'b1;
        end
        8'h16: begin
            // ADDI
            reg_write   = 1'b1;
            alu_src     = 1'b1;
            alu_control = 4'h0;
            flag_we_z = 1'b1;
            flag_we_n = 1'b1;
            flag_we_c = 1'b1;
            flag_we_v = 1'b1;
        end
        8'h17: begin
            // SUBI
            reg_write   = 1'b1;
            alu_src     = 1'b1;
            alu_control = 4'h1;
            flag_we_z = 1'b1;
            flag_we_n = 1'b1;
            flag_we_c = 1'b1;
            flag_we_v = 1'b1;
        end
        8'h18: begin
            // ANDI
            reg_write   = 1'b1;
            alu_src     = 1'b1;
            alu_control = 4'h4;
            flag_we_z = 1'b1;
            flag_we_n = 1'b1;
        end
        8'h19: begin
            // ORI
            reg_write   = 1'b1;
            alu_src     = 1'b1;
            alu_control = 4'h5;
            flag_we_z = 1'b1;
            flag_we_n = 1'b1;
        end
        8'h1A: begin
            // XORI
            reg_write   = 1'b1;
            alu_src     = 1'b1;
            alu_control = 4'hA;
            flag_we_z = 1'b1;
            flag_we_n = 1'b1;
        end
        8'h1B: begin
            // MOV
            reg_write = 1'b1;
            wb_sel    = 2'b11;
        end
        8'h1C: begin
            // SLT
            reg_write   = 1'b1;
            alu_control = 4'hD;
            flag_we_z = 1'b1;
        end
        8'h1D: begin
            // SLTU
            reg_write   = 1'b1;
            alu_control = 4'hE;
            flag_we_z = 1'b1;
        end
        8'h1E: begin
            // LUI
            reg_write = 1'b1;
            wb_sel    = 2'b10;
        end
        8'h20: begin
            // BEQ
            pc_src = 1'b1;
        end
        8'h21: begin
            // BNE
            pc_src = 1'b1;
        end
        8'h22: begin
            // BLT
            pc_src = 1'b1;
        end
        8'h23: begin
            // BGE
            pc_src = 1'b1;
        end
        8'h24: begin
            // BLTU
            pc_src = 1'b1;
        end
        8'h25: begin
            // BGEU
            pc_src = 1'b1;
        end
        8'h26: begin
            // JMP_REG
            pc_src = 1'b1;
        end
        8'hFF: begin
            // HALT
            halt = 1'b1;
        end
        default: begin
            // Treat undefined opcode as NOP
        end
    endcase
end

endmodule