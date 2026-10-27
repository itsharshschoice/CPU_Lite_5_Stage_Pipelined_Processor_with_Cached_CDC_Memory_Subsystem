// Program counter

module pc (
    input clk, rstn,
    input [11:0] pc_in,
    output reg [11:0] pc_out
);
    
    always @(posedge clk or negedge rstn) begin
        if(!rstn)
            pc_out <= 12'b0;
        else
            pc_out <= pc_in;
    end

endmodule