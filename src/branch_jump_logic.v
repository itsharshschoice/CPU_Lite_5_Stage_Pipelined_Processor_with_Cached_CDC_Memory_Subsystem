module branch_jump_logic (
    input [7:0] opcode,
    input [11:0] instruction_addr,
    input [31:0] rs1_data,
    input Z, N, C, V,
    output reg pc_src,
    output reg [11:0] pc_target
);

always @(*) begin
    // Default: continue sequentially
    pc_src    = 1'b0;
    pc_target = instruction_addr;
    case (opcode)
        8'h0E: begin
            // JMP
            pc_src = 1'b1;
        end
        8'h0F: begin
            // JMP_IF Rs1, ADDR
            pc_src = (rs1_data != 32'b0);
        end
        8'h20: begin
            // BEQ (Branch if Z = 1)
            pc_src = Z;
        end
        8'h21: begin
            // BNE (Branch if Z != 1)
            pc_src = !Z;
        end
        8'h22: begin
            // BLT (Signed: N XOR V)
            pc_src = N ^ V;
        end
        8'h23: begin
            // BGE (Signed: NOT(N XOR V))
            pc_src = !(N ^ V);
        end
        8'h24: begin
            // BLTU (Unsigned: C = 0 after CMP)
            pc_src = !C;
        end
        8'h25: begin
            // BGEU (Unsigned: C = 1 after CMP)
            pc_src = C;
        end
        8'h26: begin
            // JMP_REG Rs1
            pc_src = 1'b1;
            pc_target = rs1_data[11:0];
        end
        default: begin
            pc_src = 1'b0;
        end

    endcase
end

endmodule