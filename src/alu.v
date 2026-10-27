module alu (
    input [31:0] operand1, // RS1
    input [31:0] operand2, // RS2 or IMM value
    input [3:0] alu_control,
    output reg [31:0] result,
    output reg Z,N,C,V // flags
);
    
    reg [32:0] temp;

    always @(*) begin
        temp = 33'b0;
        result = 32'b0;
        Z = 1'b0;
        N = 1'b0;
        C = 1'b0;
        V = 1'b0;
        case (alu_control)
            4'h0: begin
                // ADD/ADDI
                temp = {1'b0, operand1} + {1'b0, operand2};
                result = temp[31:0];
                Z = (result == 32'b0);
                N = result[31];
                C = temp[32];
                V = (operand1[31] == operand2[31]) && (result[31] != operand1[31]);
            end
            4'h1: begin
                // SUB/SUBI/CMP
                temp = {1'b0, operand1} - {1'b0, operand2};
                result = temp[31:0];
                Z = (result == 32'b0);
                N = result[31];
                C = !temp[32];
                V = (operand1[31] != operand2[31]) && (result[31] != operand1[31]);
            end
            4'h2: begin
                // EQ
                result = (operand1 == operand2) ? 32'h1 : 32'h0;
                Z = (result == 32'b0);
                N = 1'b0;
                C = 1'b0;
                V = 1'b0;
            end
            4'h3: begin
                // MUL
                result = (operand1 * operand2);
                Z = (result == 32'b0);
                N = result[31];
                C = 1'b0;
                V = 1'b0;
            end
            4'h4: begin
                // AND/ANDI
                result = operand1 & operand2; 
                Z = (result == 32'b0);
                N = result[31];
                C = 1'b0;
                V = 1'b0;
            end
            4'h5: begin
                // OR/ORI
                result = operand1 | operand2;
                Z = (result == 32'b0);
                N = result[31];
                C = 1'b0;
                V = 1'b0;
            end
            4'h6: begin
                // NOT
                result = ~operand1;
                Z = (result == 32'b0);
                N = result[31];
                C = 1'b0;
                V = 1'b0;
            end
            4'h7: begin
                // SHL
                result = operand1 << operand2[4:0];
                Z = (result == 32'b0);
                N = result[31];
                C = 1'b0;
                V = 1'b0;
            end
            4'h8: begin
                // SHR
                result = operand1 >> operand2[4:0];
                Z = (result == 32'b0);
                N = result[31];
                C = 1'b0;
                V = 1'b0;
            end
            4'h9: begin
                // SAR
                result = $signed(operand1) >>> operand2[4:0];
                Z = (result == 32'b0);
                N = result[31];
                C = 1'b0;
                V = 1'b0;
            end
            4'ha: begin
                // XOR/XORI
                result = operand1 ^ operand2;
                Z = (result == 32'b0);
                N = result[31];
                C = 1'b0;
                V = 1'b0;
            end
            4'hb: begin
                // ROL
                if (operand2[4:0] == 5'd0) begin
                      result = operand1;  
                end
                else begin
                        result = (operand1 << operand2[4:0]) | (operand1 >> (32 - operand2[4:0]));
                end
                Z = (result == 32'b0);
                N = result[31];
                C = 1'b0;
                V = 1'b0;
            end
            4'hc: begin
                // ROR
                if (operand2[4:0] == 5'd0) begin
                      result = operand1;  
                end
                else begin
                        result = (operand1 >> operand2[4:0]) | (operand1 << (32 - operand2[4:0]));
                end
                Z = (result == 32'b0);
                N = result[31];
                C = 1'b0;
                V = 1'b0;
            end
            4'hd: begin
                // SLT
                result = ($signed(operand1) < $signed(operand2)) ? 32'h1: 32'h0; // SLT
                Z = (result == 32'b0);
                N = 1'b0;
                C = 1'b0;
                V = 1'b0;
            end
            4'he: begin
                // SLTU
                result = (operand1 < operand2) ? 32'h1 : 32'h0; // SLTU
                Z = (result == 32'b0);
                N = 1'b0;
                C = 1'b0;
                V = 1'b0;
            end
            default: begin
                result = 32'b0;
                {Z,N,C,V} = 4'b0;
            end
        endcase
    end

endmodule