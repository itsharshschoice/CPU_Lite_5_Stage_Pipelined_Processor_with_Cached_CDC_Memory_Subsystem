// Main Memory (Line-Based Interface)
//
// 16K × 32-bit word-addressable memory with a line-based
// request/response interface for connection to cache.
//
// Currently operates on the CPU clock (no CDC).
// When async FIFO is added, this module will move to
// mem_clk domain and connect through the FIFO.
//
// Timing:
//   req_ready = always 1 (accepts immediately)
//   Write:  committed on the accepting posedge. No response.
//   Read:   resp_valid + resp_rdata appear 1 cycle after accept.
//

module main_memory (
    input clk,
    input rstn,

    // --------------------------------------------------------
    // Request interface (from cache controller)
    // --------------------------------------------------------

    input             req_valid,
    output            req_ready,      // Always ready (no backpressure)
    input             req_we,         // 0 = read line, 1 = write line
    input      [11:0] req_addr,       // Line address = cpu_addr[13:2]
    input     [127:0] req_wdata,      // Write data (4 words, writeback)

    // --------------------------------------------------------
    // Response interface (to cache controller, reads only)
    // --------------------------------------------------------

    output reg        resp_valid,
    output reg [127:0] resp_rdata     // Read data (4 words, allocate)
);


    // MEMORY ARRAY (same 16K × 32 as original data_memory)

    reg [31:0] data_items [0:16383];

    initial begin
        $readmemh("data_set2.mem", data_items);
    end


    // ALWAYS READY

    assign req_ready = 1'b1;


    // WORD ADDRESSES FOR THE 4 WORDS IN A LINE
    //
    // Line address [11:0] = {tag, index}
    // Word address [13:0] = {line_addr, offset}

    wire [13:0] wa0 = {req_addr, 2'd0};
    wire [13:0] wa1 = {req_addr, 2'd1};
    wire [13:0] wa2 = {req_addr, 2'd2};
    wire [13:0] wa3 = {req_addr, 2'd3};


    // REQUEST HANDLING

    always @(posedge clk or negedge rstn) begin

        if (!rstn) begin
            resp_valid <= 1'b0;
            resp_rdata <= 128'b0;
        end

        else begin

            // Default: no response this cycle
            resp_valid <= 1'b0;

            if (req_valid) begin

                if (req_we) begin

                    // ------------------------------------------
                    // WRITE — store 4 words (writeback from cache)
                    // No response generated for writes.
                    // ------------------------------------------

                    data_items[wa0] <= req_wdata[31:0];
                    data_items[wa1] <= req_wdata[63:32];
                    data_items[wa2] <= req_wdata[95:64];
                    data_items[wa3] <= req_wdata[127:96];

                end

                else begin

                    // ------------------------------------------
                    // READ — fetch 4 words (allocate for cache)
                    // Response appears on the NEXT cycle.
                    // ------------------------------------------

                    resp_rdata <= {
                        data_items[wa3],
                        data_items[wa2],
                        data_items[wa1],
                        data_items[wa0]
                    };
                    resp_valid <= 1'b1;

                end

            end

        end

    end

endmodule
