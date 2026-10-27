// MEM/WB Pipeline Register (Cached Version)
//
// Change from original:
//   Added 'stall' input.
//   When stall = 1, all outputs hold their current values.
//   This is used during cache miss to freeze the pipeline.
//

module mem_wb_register (
    input clk,
    input rstn,

    input stall,   // NEW: cache stall — hold values

    input [31:0] alu_result_in,
    input [31:0] memory_read_data_in,
    input [31:0] immediate_in,
    input [31:0] rs1_data_in,

    input [3:0] rd_in,

    input        reg_write_in,
    input [1:0]  wb_sel_in,

    input        halt_in,

    output reg [31:0] alu_result_out,
    output reg [31:0] memory_read_data_out,
    output reg [31:0] immediate_out,
    output reg [31:0] rs1_data_out,

    output reg [3:0] rd_out,

    output reg        reg_write_out,
    output reg [1:0]  wb_sel_out,

    output reg        halt_out
);

always @(posedge clk or negedge rstn) begin

    if (!rstn) begin

        alu_result_out       <= 32'b0;
        memory_read_data_out <= 32'b0;
        immediate_out        <= 32'b0;
        rs1_data_out         <= 32'b0;

        rd_out               <= 4'b0;

        reg_write_out        <= 1'b0;
        wb_sel_out           <= 2'b0;

        halt_out             <= 1'b0;

    end

    // NEW: when stall = 1, hold all outputs.
    else if (!stall) begin

        alu_result_out       <= alu_result_in;
        memory_read_data_out <= memory_read_data_in;
        immediate_out        <= immediate_in;
        rs1_data_out         <= rs1_data_in;

        rd_out               <= rd_in;

        reg_write_out        <= reg_write_in;
        wb_sel_out           <= wb_sel_in;

        halt_out             <= halt_in;

    end
    // else: stall = 1 → hold (do nothing)

end

endmodule
