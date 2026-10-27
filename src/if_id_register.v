module if_id_register (
    input clk,
    input rstn,

    input        stall,
    input        flush,

    input  [31:0] instruction_in,
    output reg [31:0] instruction_out
);

always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
        instruction_out <= 32'b0;
    end
    else if (flush) begin
        instruction_out <= 32'b0;
    end
    else if (!stall) begin
        instruction_out <= instruction_in;
    end
end

endmodule