// Cache Memory (Datapath / Storage Arrays)
//
// Direct-mapped cache storage:
//   64 lines × 4 words/line × 32 bits/word = 1 KB data
//
// Per-line metadata:
//   Valid (1 bit), Dirty (1 bit), Tag (6 bits)
//
// Address mapping (14-bit word address):
//   [13:8] Tag  |  [7:2] Index  |  [1:0] Offset
//    6 bits        6 bits          2 bits
//
// All reads are COMBINATIONAL.
// All writes are SYNCHRONOUS (posedge clk).
//

module cache_memory (
    input clk,
    input rstn,

    // --------------------------------------------------------
    // Address inputs (directly from CPU address decomposition)
    // --------------------------------------------------------

    input  [5:0] index,        // Line select   (0 – 63)
    input  [1:0] offset,       // Word select   (0 – 3)

    // --------------------------------------------------------
    // Tag port
    // --------------------------------------------------------

    input  [5:0] tag_wr,       // Tag to write on line fill
    output [5:0] tag_rd,       // Tag stored in the addressed line

    // --------------------------------------------------------
    // Status bits (combinational read)
    // --------------------------------------------------------

    output       valid,
    output       dirty,

    // --------------------------------------------------------
    // Word-level access (CPU read/write on hit)
    // --------------------------------------------------------

    output reg [31:0] word_rdata,   // Combinational read
    input      [31:0] word_wdata,   // Write data from CPU
    input             word_we,      // Write one word at [index][offset]

    // --------------------------------------------------------
    // Line-level access (writeback / allocate)
    // --------------------------------------------------------

    output [127:0] line_rdata,      // Full line read  (writeback)
    input  [127:0] line_wdata,      // Full line write  (allocate)
    input          line_we,         // Write full line + tag + valid

    // --------------------------------------------------------
    // Dirty bit control
    // --------------------------------------------------------

    input         set_dirty,        // Assert on store hit
    input         clear_dirty       // Reserved for future use
);


    // STORAGE ARRAYS

    reg        valid_array [0:63];
    reg        dirty_array [0:63];
    reg  [5:0] tag_array   [0:63];
    reg [31:0] data_array  [0:63][0:3];   // 64 lines × 4 words

    integer i;


    // COMBINATIONAL READS

    // Tag & status
    assign tag_rd = tag_array[index];
    assign valid  = valid_array[index];
    assign dirty  = dirty_array[index];

    // Full 128-bit line read (for writeback to main memory)
    assign line_rdata = {
        data_array[index][3],
        data_array[index][2],
        data_array[index][1],
        data_array[index][0]
    };

    // Single-word read (for CPU load hit)
    always @(*) begin
        case (offset)
            2'd0:    word_rdata = data_array[index][0];
            2'd1:    word_rdata = data_array[index][1];
            2'd2:    word_rdata = data_array[index][2];
            2'd3:    word_rdata = data_array[index][3];
            default: word_rdata = 32'b0;
        endcase
    end


    // SYNCHRONOUS WRITES

    always @(posedge clk or negedge rstn) begin

        if (!rstn) begin

            for (i = 0; i < 64; i = i + 1) begin
                valid_array[i]   <= 1'b0;
                dirty_array[i]   <= 1'b0;
                tag_array[i]     <= 6'b0;
                data_array[i][0] <= 32'b0;
                data_array[i][1] <= 32'b0;
                data_array[i][2] <= 32'b0;
                data_array[i][3] <= 32'b0;
            end

        end

        else begin

            // ------------------------------------------------
            // LINE WRITE (allocate / line fill)
            //
            // Writes all 4 words + updates tag.
            // Sets valid = 1, dirty = 0 (freshly fetched).
            // ------------------------------------------------

            if (line_we) begin

                data_array[index][0] <= line_wdata[31:0];
                data_array[index][1] <= line_wdata[63:32];
                data_array[index][2] <= line_wdata[95:64];
                data_array[index][3] <= line_wdata[127:96];

                tag_array[index]     <= tag_wr;
                valid_array[index]   <= 1'b1;
                dirty_array[index]   <= 1'b0;

            end

            // ------------------------------------------------
            // WORD WRITE (CPU store hit)
            //
            // Writes a single word at [index][offset].
            // Dirty bit is set separately via set_dirty.
            // ------------------------------------------------

            else if (word_we) begin

                case (offset)
                    2'd0: data_array[index][0] <= word_wdata;
                    2'd1: data_array[index][1] <= word_wdata;
                    2'd2: data_array[index][2] <= word_wdata;
                    2'd3: data_array[index][3] <= word_wdata;
                endcase

            end

            // ------------------------------------------------
            // DIRTY BIT CONTROL
            //
            // line_we clears dirty (handled above).
            // set_dirty / clear_dirty only apply when line_we
            // is NOT asserted.
            // ------------------------------------------------

            if (!line_we) begin

                if (set_dirty)
                    dirty_array[index] <= 1'b1;
                else if (clear_dirty)
                    dirty_array[index] <= 1'b0;

            end

        end

    end

endmodule
