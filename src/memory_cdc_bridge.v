// Memory Clock Domain Crossing (CDC) Bridge
//
// Connects the cache_controller (on CPU clock domain) to
// the main_memory (on Memory clock domain).
//
// Uses two asynchronous FIFOs:
// 1. Request FIFO  (CPU -> Mem): Packs WE, Addr, and Write Data
// 2. Response FIFO (Mem -> CPU): Packs Read Data
//

module memory_cdc_bridge (
    input  cpu_clk,
    input  mem_clk,
    input  rstn,            // Asynchronous reset for both domains

    // --------------------------------------------------------
    // CPU Domain Interface (Connects to cache_controller)
    // --------------------------------------------------------
    input          cpu_req_valid,
    output         cpu_req_ready,
    input          cpu_req_we,
    input  [11:0]  cpu_req_addr,
    input  [127:0] cpu_req_wdata,

    output         cpu_resp_valid,
    output [127:0] cpu_resp_rdata,

    // --------------------------------------------------------
    // Memory Domain Interface (Connects to main_memory)
    // --------------------------------------------------------
    output         mem_req_valid,
    input          mem_req_ready,
    output         mem_req_we,
    output [11:0]  mem_req_addr,
    output [127:0] mem_req_wdata,

    input          mem_resp_valid,
    input  [127:0] mem_resp_rdata
);

    // REQUEST FIFO (CPU -> MEMORY)
    // Data width: 1 (WE) + 12 (Addr) + 128 (WData) = 141 bits
    
    wire         req_fifo_full;
    wire         req_fifo_empty;
    wire         req_fifo_rd_en;
    wire [140:0] req_fifo_rd_data;

    // CPU side pushes request
    wire req_fifo_wr_en = cpu_req_valid && !req_fifo_full;
    assign cpu_req_ready = !req_fifo_full;

    async_fifo #(
        .DATA_WIDTH(141),
        .ADDR_WIDTH(4)       // Depth = 16
    ) req_fifo (
        .wr_clk   (cpu_clk),
        .wr_rst_n (rstn),
        .wr_en    (req_fifo_wr_en),
        .wr_data  ({cpu_req_we, cpu_req_addr, cpu_req_wdata}),
        .full     (req_fifo_full),
        
        .rd_clk   (mem_clk),
        .rd_rst_n (rstn),
        .rd_en    (req_fifo_rd_en),
        .rd_data  (req_fifo_rd_data),
        .empty    (req_fifo_empty)
    );

    // Memory side pulls request safely
    // Because the FIFO read has a 1-cycle latency, we register the valid signal.
    reg mem_req_valid_reg;
    always @(posedge mem_clk or negedge rstn) begin
        if (!rstn) begin
            mem_req_valid_reg <= 1'b0;
        end else begin
            if (req_fifo_rd_en)
                mem_req_valid_reg <= 1'b1;
            else if (mem_req_ready)
                mem_req_valid_reg <= 1'b0;
        end
    end

    assign mem_req_valid = mem_req_valid_reg;
    assign {mem_req_we, mem_req_addr, mem_req_wdata} = req_fifo_rd_data;

    // Read the next item when the valid register is empty, 
    // or when it's going to be emptied this cycle.
    assign req_fifo_rd_en = !req_fifo_empty && (!mem_req_valid_reg || mem_req_ready);


    // RESPONSE FIFO (MEMORY -> CPU)
    // Data width: 128 (RData)
    
    wire         resp_fifo_full;
    wire         resp_fifo_empty;
    wire         resp_fifo_rd_en;
    wire [127:0] resp_fifo_rd_data;

    // Memory side pushes response
    // (We assume main_memory never generates more responses than requested,
    // so overflow won't happen since cache blocks on misses)
    wire resp_fifo_wr_en = mem_resp_valid && !resp_fifo_full;

    async_fifo #(
        .DATA_WIDTH(128),
        .ADDR_WIDTH(4)       // Depth = 16
    ) resp_fifo (
        .wr_clk   (mem_clk),
        .wr_rst_n (rstn),
        .wr_en    (resp_fifo_wr_en),
        .wr_data  (mem_resp_rdata),
        .full     (resp_fifo_full),
        
        .rd_clk   (cpu_clk),
        .rd_rst_n (rstn),
        .rd_en    (resp_fifo_rd_en),
        .rd_data  (resp_fifo_rd_data),
        .empty    (resp_fifo_empty)
    );

    // CPU side pulls response
    assign resp_fifo_rd_en = !resp_fifo_empty;
    
    // Register the valid signal to match the 1-cycle FIFO read latency
    reg cpu_resp_valid_reg;
    always @(posedge cpu_clk or negedge rstn) begin
        if (!rstn) 
            cpu_resp_valid_reg <= 1'b0;
        else 
            cpu_resp_valid_reg <= resp_fifo_rd_en;
    end

    assign cpu_resp_valid = cpu_resp_valid_reg;
    assign cpu_resp_rdata = resp_fifo_rd_data;

endmodule
