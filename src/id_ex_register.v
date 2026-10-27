// ID/EX Pipeline Register (Cached Version)
//
// Change from original:
//   Added 'stall' input.
//   Priority: reset > stall > flush > normal capture.
//   When stall = 1, all outputs hold their current values.
//   This is used during cache miss to freeze the pipeline.
//

module id_ex_register (
    input clk,
    input rstn,

    input stall,   // NEW: cache stall — hold values
    input flush,

    // Data from ID stage

    input  [7:0] opcode_in,

    input [31:0] rs1_data_in,
    input [31:0] rs2_data_in,
    input [31:0] immediate_in,
    input [11:0] imm_addr_in,

    input [3:0] rd_in,
    input [3:0] rs1_in,
    input [3:0] rs2_in,

    // Control signals from ID stage

    input        reg_write_in,
    input        mem_read_in,
    input        mem_write_in,

    input        alu_src_in,
    input [3:0]  alu_control_in,

    input [1:0]  wb_sel_in,

    input        flag_we_z_in,
    input        flag_we_n_in,
    input        flag_we_c_in,
    input        flag_we_v_in,

    input        pc_src_in,
    input        halt_in,

    // Outputs to EX stage

    output reg [7:0] opcode_out,

    output reg [31:0] rs1_data_out,
    output reg [31:0] rs2_data_out,
    output reg [31:0] immediate_out,
    output reg [11:0] imm_addr_out,

    output reg [3:0] rd_out,
    output reg [3:0] rs1_out,
    output reg [3:0] rs2_out,

    // Control signals to EX stage

    output reg        reg_write_out,
    output reg        mem_read_out,
    output reg        mem_write_out,

    output reg        alu_src_out,
    output reg [3:0]  alu_control_out,

    output reg [1:0]  wb_sel_out,

    output reg        flag_we_z_out,
    output reg        flag_we_n_out,
    output reg        flag_we_c_out,
    output reg        flag_we_v_out,

    output reg        pc_src_out,
    output reg        halt_out
);

always @(posedge clk or negedge rstn) begin

    if (!rstn) begin

        // Data
        opcode_out      <= 8'b0;
        rs1_data_out    <= 32'b0;
        rs2_data_out    <= 32'b0;
        immediate_out   <= 32'b0;
        imm_addr_out    <= 12'b0;
        rd_out          <= 4'b0;
        rs1_out         <= 4'b0;
        rs2_out         <= 4'b0;

        // Control
        reg_write_out   <= 1'b0;
        mem_read_out    <= 1'b0;
        mem_write_out   <= 1'b0;
        alu_src_out     <= 1'b0;
        alu_control_out <= 4'b0;
        wb_sel_out      <= 2'b0;
        flag_we_z_out   <= 1'b0;
        flag_we_n_out   <= 1'b0;
        flag_we_c_out   <= 1'b0;
        flag_we_v_out   <= 1'b0;
        pc_src_out      <= 1'b0;
        halt_out        <= 1'b0;
    end

    // NEW: stall takes priority over flush.
    // During cache miss the entire pipeline is frozen;
    // no bubble insertion or data capture is allowed.
    else if (stall) begin
        // HOLD — do nothing, all outputs retain their values.
    end

    else if (flush) begin

        // Insert bubble into EX stage

        // Data
        opcode_out      <= 8'b0;
        rs1_data_out    <= 32'b0;
        rs2_data_out    <= 32'b0;
        immediate_out   <= 32'b0;
        imm_addr_out    <= 12'b0;
        rd_out          <= 4'b0;
        rs1_out         <= 4'b0;
        rs2_out         <= 4'b0;

        // Control
        reg_write_out   <= 1'b0;
        mem_read_out    <= 1'b0;
        mem_write_out   <= 1'b0;
        alu_src_out     <= 1'b0;
        alu_control_out <= 4'b0;
        wb_sel_out      <= 2'b0;
        flag_we_z_out   <= 1'b0;
        flag_we_n_out   <= 1'b0;
        flag_we_c_out   <= 1'b0;
        flag_we_v_out   <= 1'b0;
        pc_src_out      <= 1'b0;
        halt_out        <= 1'b0;
    end

    else begin

        // Data
        opcode_out      <= opcode_in;
        rs1_data_out    <= rs1_data_in;
        rs2_data_out    <= rs2_data_in;
        immediate_out   <= immediate_in;
        imm_addr_out    <= imm_addr_in;
        rd_out          <= rd_in;
        rs1_out         <= rs1_in;
        rs2_out         <= rs2_in;

        // Control
        reg_write_out   <= reg_write_in;
        mem_read_out    <= mem_read_in;
        mem_write_out   <= mem_write_in;
        alu_src_out     <= alu_src_in;
        alu_control_out <= alu_control_in;
        wb_sel_out      <= wb_sel_in;
        flag_we_z_out   <= flag_we_z_in;
        flag_we_n_out   <= flag_we_n_in;
        flag_we_c_out   <= flag_we_c_in;
        flag_we_v_out   <= flag_we_v_in;
        pc_src_out      <= pc_src_in;
        halt_out        <= halt_in;
    end

end

endmodule
