// Cache Controller for Lint / Synthesis (cache_controller_lint)
//
// Direct-mapped, write-back, write-allocate cache controller FSM.
//
// In this lint-ready module, the internal simulation memory model
// (cache_memory.v) has been completely removed.
// All SRAM interface signals (tag, data, valid, dirty, we) are
// brought out as top-level ports to connect to an external SRAM
// macro or top-level pins.
//
// FSM States:
//   IDLE       -> tag compare; hit = serve, miss = start handling
//   WRITEBACK  -> send dirty evicted line to main memory
//   ALLOCATE   -> request the needed line from main memory
//   ALLOC_WAIT -> wait for main memory to return the line
//

module cache_controller_lint (
    input clk,
    input rstn,

    // --------------------------------------------------------
    // CPU interface (wired to MEM stage in cpu_lint)
    // --------------------------------------------------------
    input  [13:0] cpu_addr,         // 14-bit word address
    input  [31:0] cpu_wdata,        // Store data
    input         cpu_mem_read,     // Load request
    input         cpu_mem_write,    // Store request
    output [31:0] cpu_rdata,        // Load data (valid on hit)
    output        cache_stall,      // High = pipeline must freeze

    // --------------------------------------------------------
    // Main-memory interface (to FIFO / memory controller)
    // --------------------------------------------------------
    output reg         mem_req_valid,
    input              mem_req_ready,
    output reg         mem_req_we,       // 0 = read line, 1 = write line
    output reg  [11:0] mem_req_addr,     // Line address {tag, index}
    output reg [127:0] mem_req_wdata,    // Evicted line data (writeback)

    input              mem_resp_valid,
    input      [127:0] mem_resp_rdata,   // Fetched line data (allocate)

    // --------------------------------------------------------
    // Cache SRAM Macro Interface (Exposed for Lint / Macro Hookup)
    // --------------------------------------------------------
    output [5:0]       cm_index,         // Line select (0 - 63)
    output [1:0]       cm_offset,        // Word select (0 - 3)
    output [5:0]       cm_tag_wr,        // Tag to write on allocate
    input  [5:0]       cm_tag_rd,        // Tag read from SRAM
    input              cm_valid,         // Valid bit from SRAM
    input              cm_dirty,         // Dirty bit from SRAM

    output [31:0]      cm_word_wdata,    // Word write data to SRAM
    input  [31:0]      cm_word_rdata,    // Word read data from SRAM
    output reg         cm_word_we,       // Word write enable

    output [127:0]     cm_line_wdata,    // Line fill data to SRAM
    input  [127:0]     cm_line_rdata,    // Line read data from SRAM
    output reg         cm_line_we,       // Line write enable

    output reg         cm_set_dirty,     // Set dirty bit flag
    output reg         cm_clear_dirty    // Clear dirty bit flag
);

    // ADDRESS DECOMPOSITION
    wire [5:0] tag    = cpu_addr[13:8];
    wire [5:0] index  = cpu_addr[7:2];
    wire [1:0] offset = cpu_addr[1:0];

    // Forward address and data signals to SRAM macro ports
    assign cm_index      = index;
    assign cm_offset     = offset;
    assign cm_tag_wr     = tag;
    assign cm_word_wdata = cpu_wdata;
    assign cm_line_wdata = mem_resp_rdata;

    // FSM STATE ENCODING
    localparam IDLE       = 2'd0;
    localparam WRITEBACK  = 2'd1;
    localparam ALLOCATE   = 2'd2;
    localparam ALLOC_WAIT = 2'd3;

    reg [1:0] state, next_state;

    // HIT / MISS DETECTION
    wire access = cpu_mem_read | cpu_mem_write;
    wire hit    = cm_valid && (cm_tag_rd == tag);

    // STALL & READ DATA OUTPUTS
    assign cache_stall = (state != IDLE) || (access && !hit);
    assign cpu_rdata   = cm_word_rdata;

    // STATE REGISTER
    always @(posedge clk or negedge rstn) begin
        if (!rstn)
            state <= IDLE;
        else
            state <= next_state;
    end

    // NEXT-STATE + OUTPUT LOGIC (COMBINATIONAL)
    always @(*) begin

        next_state     = state;

        cm_word_we     = 1'b0;
        cm_line_we     = 1'b0;
        cm_set_dirty   = 1'b0;
        cm_clear_dirty = 1'b0;

        mem_req_valid  = 1'b0;
        mem_req_we     = 1'b0;
        mem_req_addr   = 12'b0;
        mem_req_wdata  = 128'b0;

        case (state)

            IDLE: begin
                if (access) begin
                    if (hit) begin
                        if (cpu_mem_write) begin
                            cm_word_we   = 1'b1;
                            cm_set_dirty = 1'b1;
                        end
                        next_state = IDLE;
                    end
                    else begin
                        if (cm_valid && cm_dirty) begin
                            next_state = WRITEBACK;
                        end
                        else begin
                            next_state = ALLOCATE;
                        end
                    end
                end
            end

            WRITEBACK: begin
                mem_req_valid = 1'b1;
                mem_req_we    = 1'b1;
                mem_req_addr  = {cm_tag_rd, index};
                mem_req_wdata = cm_line_rdata;

                if (mem_req_ready) begin
                    next_state = ALLOCATE;
                end
            end

            ALLOCATE: begin
                mem_req_valid = 1'b1;
                mem_req_we    = 1'b0;
                mem_req_addr  = {tag, index};

                if (mem_req_ready) begin
                    next_state = ALLOC_WAIT;
                end
            end

            ALLOC_WAIT: begin
                if (mem_resp_valid) begin
                    cm_line_we = 1'b1;
                    next_state = IDLE;
                end
            end

            default: begin
                next_state = IDLE;
            end

        endcase
    end

endmodule
