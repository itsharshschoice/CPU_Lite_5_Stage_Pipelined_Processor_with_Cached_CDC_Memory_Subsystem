module register_file (
    input clk, rstn,
    input [3:0] rs1, rs2,
    input [3:0] rd,
    input [31:0] write_data,
    input reg_write,
    output [31:0] read_data1, read_data2
);
    
    reg [31:0] registers [0:15];

    initial begin
        $readmemh("registers.mem", registers);
    end

    always @(posedge clk or negedge rstn) begin
        if(!rstn) begin
            // Nothing to perform
        end
        else if(reg_write) begin
            registers[rd] <= write_data;
        end
    end

    //we make the register file write through
    // the register file can perform WB->ID forwarding.
    assign read_data1 = (reg_write && (rd == rs1)) ? write_data : registers[rs1];
    assign read_data2 = (reg_write && (rd == rs2)) ? write_data : registers[rs2];

endmodule