// Cache Controller (FSM)
//
// Direct-mapped, write-back, write-allocate cache controller.
//
// Instantiates cache_memory (datapath) internally.
//
// CPU-side interface:
//   Single-cycle hit for both reads and writes.
//   Asserts cache_stall on miss until line fill completes.
//
// Memory-side interface:
//   Request/response handshake for line-granularity access.
//   Designed to connect to async FIFO (CDC) later;
//   for now connects directly to main_memory.
//
// FSM States:
//   IDLE       → tag compare; hit = serve, miss = start handling
//   WRITEBACK  → send dirty evicted line to main memory
//   ALLOCATE   → request the needed line from main memory
//   ALLOC_WAIT → wait for main memory to return the line
//
// Miss penalty (same clock, req_ready = 1):
//   Clean miss : 3 stall cycles  (ALLOCATE → ALLOC_WAIT → IDLE hit)
//   Dirty miss : 4 stall cycles  (WRITEBACK → ALLOCATE → ALLOC_WAIT → IDLE hit)
//

module cache_controller (
    input clk,
    input rstn,

    // --------------------------------------------------------
    // CPU interface (directly wired to MEM stage in cpu.v)
    // --------------------------------------------------------

    input  [13:0] cpu_addr,         // 14-bit word address
    input  [31:0] cpu_wdata,        // Store data
    input         cpu_mem_read,     // Load request
    input         cpu_mem_write,    // Store request
    output [31:0] cpu_rdata,        // Load data (valid on hit)
    output        cache_stall,      // High = pipeline must freeze

    // --------------------------------------------------------
    // Main-memory interface (to FIFO / main_memory)
    //
    // Request channel  (cache → memory)
    // Response channel (memory → cache, reads only)
    // --------------------------------------------------------

    output reg         mem_req_valid,
    input              mem_req_ready,
    output reg         mem_req_we,       // 0 = read line, 1 = write line
    output reg  [11:0] mem_req_addr,     // Line address {tag, index}
    output reg [127:0] mem_req_wdata,    // Evicted line data (writeback)

    input              mem_resp_valid,
    input      [127:0] mem_resp_rdata    // Fetched line data (allocate)
);


    // ADDRESS DECOMPOSITION

    wire [5:0] tag    = cpu_addr[13:8];
    wire [5:0] index  = cpu_addr[7:2];
    wire [1:0] offset = cpu_addr[1:0];


    // FSM STATE ENCODING

    localparam IDLE       = 2'd0;
    localparam WRITEBACK  = 2'd1;
    localparam ALLOCATE   = 2'd2;
    localparam ALLOC_WAIT = 2'd3;

    reg [1:0] state, next_state;


    // CACHE MEMORY INTERFACE SIGNALS

    wire [5:0]   cm_tag_rd;
    wire         cm_valid;
    wire         cm_dirty;
    wire [31:0]  cm_word_rdata;
    wire [127:0] cm_line_rdata;

    reg          cm_word_we;
    reg          cm_line_we;
    reg          cm_set_dirty;
    reg          cm_clear_dirty;


    // CACHE MEMORY INSTANCE (DATAPATH)

    cache_memory cache_mem (
        .clk         (clk),
        .rstn        (rstn),

        .index       (index),
        .offset      (offset),

        .tag_wr      (tag),
        .tag_rd      (cm_tag_rd),

        .valid       (cm_valid),
        .dirty       (cm_dirty),

        .word_rdata  (cm_word_rdata),
        .word_wdata  (cpu_wdata),
        .word_we     (cm_word_we),

        .line_rdata  (cm_line_rdata),
        .line_wdata  (mem_resp_rdata),
        .line_we     (cm_line_we),

        .set_dirty   (cm_set_dirty),
        .clear_dirty (cm_clear_dirty)
    );


    // HIT / MISS DETECTION

    wire access = cpu_mem_read | cpu_mem_write;
    wire hit    = cm_valid && (cm_tag_rd == tag);


    // STALL & READ DATA OUTPUTS

    // Stall the pipeline whenever:
    //   - We are handling a miss  (state != IDLE)
    //   - A new access is a miss  (IDLE + access + !hit)
    assign cache_stall = (state != IDLE) || (access && !hit);

    // CPU read data comes directly from the cache SRAM.
    // Only meaningful when hit && cpu_mem_read; on miss the
    // pipeline is stalled and does not capture this value.
    assign cpu_rdata = cm_word_rdata;


    // STATE REGISTER

    always @(posedge clk or negedge rstn) begin
        if (!rstn)
            state <= IDLE;
        else
            state <= next_state;
    end


    // NEXT-STATE + OUTPUT LOGIC (COMBINATIONAL)

    always @(*) begin

        // DEFAULTS — no writes, no memory requests

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

            // IDLE — Tag compare on every access

            IDLE: begin

                if (access) begin

                    if (hit) begin

                        // ---- HIT ----

                        if (cpu_mem_write) begin
                            cm_word_we   = 1'b1;   // Write the word
                            cm_set_dirty = 1'b1;   // Mark line dirty
                        end

                        // Read hit: cpu_rdata = cm_word_rdata
                        // (always connected, valid this cycle)

                        next_state = IDLE;

                    end

                    else begin

                        // ---- MISS ----

                        if (cm_valid && cm_dirty) begin
                            // Must evict the dirty line first
                            next_state = WRITEBACK;
                        end
                        else begin
                            // Line is clean/invalid — go straight to allocate
                            next_state = ALLOCATE;
                        end

                    end

                end
                // No access: stay idle, cache_stall = 0.

            end


            // WRITEBACK — Send dirty line to main memory

            WRITEBACK: begin

                mem_req_valid = 1'b1;
                mem_req_we    = 1'b1;

                // Address of the EVICTED line (old tag + current index)
                mem_req_addr  = {cm_tag_rd, index};

                // Data of the evicted line
                mem_req_wdata = cm_line_rdata;

                if (mem_req_ready) begin
                    next_state = ALLOCATE;
                end

            end


            // ALLOCATE — Request the needed line from memory

            ALLOCATE: begin

                mem_req_valid = 1'b1;
                mem_req_we    = 1'b0;

                // Address of the REQUESTED line (new tag + current index)
                mem_req_addr  = {tag, index};

                if (mem_req_ready) begin
                    next_state = ALLOC_WAIT;
                end

            end


            // ALLOC_WAIT — Wait for memory read response

            ALLOC_WAIT: begin

                if (mem_resp_valid) begin
                    // Fill the cache line with fetched data.
                    // cache_memory writes line + tag, sets valid,
                    // clears dirty on the next posedge.
                    cm_line_we = 1'b1;
                    next_state = IDLE;
                end

                // While waiting: cache_stall remains high,
                // pipeline stays frozen.

            end


            // DEFAULT (should never be reached)

            default: begin
                next_state = IDLE;
            end

        endcase

    end

endmodule
