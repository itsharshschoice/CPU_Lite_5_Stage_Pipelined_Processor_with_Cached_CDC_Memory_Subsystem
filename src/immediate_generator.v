module immediate_generator (
    input [31:0] instruction,
    output reg [31:0] immediate_out
);
    
    always @(*) begin
        case(instruction[31:24])
            8'h03: immediate_out = {20'b0, instruction[11:0]}; // LOAD_IMM
            8'h16: immediate_out = {{20{instruction[11]}}, instruction[11:0]}; // ADDI
            8'h17: immediate_out = {{20{instruction[11]}}, instruction[11:0]}; // SUBI
            8'h18: immediate_out = {20'b0, instruction[11:0]}; // ANDI
            8'h19: immediate_out = {20'b0, instruction[11:0]}; // ORI
            8'h1A: immediate_out = {20'b0, instruction[11:0]}; // XORI
            8'h1E: immediate_out = {instruction[11:0], 20'b0}; // LUI
            default: immediate_out = 32'b0;
        endcase
    end

endmodule