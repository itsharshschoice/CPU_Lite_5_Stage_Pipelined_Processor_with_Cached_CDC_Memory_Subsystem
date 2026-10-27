module forwarding_unit (

    input [3:0] ex_rs1, 
    input [3:0] ex_rs2,
    input [7:0] ex_opcode,
    input mem_reg_write, 
    input mem_read,
    input [3:0] mem_rd,
    input wb_reg_write,
    input [3:0] wb_rd,
    output reg [1:0] forward_a_ex, 
    output reg [1:0] forward_b_ex
);

    wire ex_rs1_valid;
    wire ex_rs2_valid;

    assign ex_rs1_valid =
           (ex_opcode == 8'h02) || // LOAD_IND
           (ex_opcode == 8'h04) || // STORE
           (ex_opcode == 8'h05) || // STORE_IND
           (ex_opcode == 8'h06) || // ADD
           (ex_opcode == 8'h07) || // SUB
           (ex_opcode == 8'h08) || // MUL
           (ex_opcode == 8'h09) || // AND
           (ex_opcode == 8'h0A) || // OR
           (ex_opcode == 8'h0C) || // CMP
           (ex_opcode == 8'h0D) || // EQ
           (ex_opcode == 8'h0F) || // JMP_IF
           (ex_opcode == 8'h10) || // XOR
           (ex_opcode == 8'h11) || // SHL
           (ex_opcode == 8'h12) || // SHR
           (ex_opcode == 8'h13) || // SAR
           (ex_opcode == 8'h14) || // ROL
           (ex_opcode == 8'h15) || // ROR
           (ex_opcode == 8'h16) || // ADDI
           (ex_opcode == 8'h17) || // SUBI
           (ex_opcode == 8'h18) || // ANDI
           (ex_opcode == 8'h19) || // ORI
           (ex_opcode == 8'h1A) || // XORI
           (ex_opcode == 8'h1B) || // MOV
           (ex_opcode == 8'h1C) || // SLT
           (ex_opcode == 8'h1D) || // SLTU
           (ex_opcode == 8'h26);   // JMP_REG


    assign ex_rs2_valid =
           (ex_opcode == 8'h05) || // STORE_IND
           (ex_opcode == 8'h06) || // ADD
           (ex_opcode == 8'h07) || // SUB
           (ex_opcode == 8'h08) || // MUL
           (ex_opcode == 8'h09) || // AND
           (ex_opcode == 8'h0A) || // OR
           (ex_opcode == 8'h0C) || // CMP
           (ex_opcode == 8'h0D) || // EQ
           (ex_opcode == 8'h10) || // XOR
           (ex_opcode == 8'h11) || // SHL
           (ex_opcode == 8'h12) || // SHR
           (ex_opcode == 8'h13) || // SAR
           (ex_opcode == 8'h14) || // ROL
           (ex_opcode == 8'h15) || // ROR
           (ex_opcode == 8'h1C) || // SLT
           (ex_opcode == 8'h1D);   // SLTU

    // Forwarding selection:
    // 00 = Register file (no forwarding)
    // 01 = MEM/WB
    // 10 = EX/MEM

    // Forward the newest available value. EX/MEM is newer than 
    // MEM/WB, so EX/MEM gets priority.
    
    // Operand 1 of ALU
    always @(*) begin
        // EX hazard
        if(mem_reg_write && !mem_read && mem_rd == ex_rs1 && ex_rs1_valid) begin // !mem_read indicates its not LOAD
            forward_a_ex = 2'b10;
        end
        // MEM hazard
        else if(wb_reg_write && wb_rd == ex_rs1 && ex_rs1_valid) begin
            forward_a_ex = 2'b01;
        end
        else begin
            forward_a_ex = 2'b00;
        end
    end

    // Operand 2 of ALU
    always @(*) begin
        // EX hazard
        if(mem_reg_write && !mem_read && mem_rd == ex_rs2 && ex_rs2_valid) begin
            forward_b_ex = 2'b10;
        end
        // MEM hazard
        else if(wb_reg_write && wb_rd == ex_rs2 && ex_rs2_valid) begin
            forward_b_ex = 2'b01;
        end
        else begin
            forward_b_ex = 2'b00;
        end
    end
    
endmodule