// System Top Level (Cached CPU + CDC + Main Memory)
//
// Wraps the entire CPU, crossing the clock boundary into
// the main memory domain using the async FIFO bridge.
//
// Clock Domains:
//  - cpu_clk : Drives the entire CPU (IF/ID/EX/MEM/WB) and Cache
//  - mem_clk : Drives the Main Memory array
//

module system_top (
    input cpu_clk,
    input mem_clk,
    input rstn
);

    // Wires: CPU <---> CDC Bridge
    wire         cpu_mem_req_valid;
    wire         cpu_mem_req_ready;
    wire         cpu_mem_req_we;
    wire [11:0]  cpu_mem_req_addr;
    wire [127:0] cpu_mem_req_wdata;

    wire         cpu_mem_resp_valid;
    wire [127:0] cpu_mem_resp_rdata;


    // Wires: CDC Bridge <---> Main Memory
    wire         mem_req_valid;
    wire         mem_req_ready;
    wire         mem_req_we;
    wire [11:0]  mem_req_addr;
    wire [127:0] mem_req_wdata;

    wire         mem_resp_valid;
    wire [127:0] mem_resp_rdata;


    // CPU Instantiation (Runs entirely on cpu_clk)
    cpu processor (
        .clk              (cpu_clk),
        .rstn             (rstn),

        .mem_req_valid    (cpu_mem_req_valid),
        .mem_req_ready    (cpu_mem_req_ready),
        .mem_req_we       (cpu_mem_req_we),
        .mem_req_addr     (cpu_mem_req_addr),
        .mem_req_wdata    (cpu_mem_req_wdata),

        .mem_resp_valid   (cpu_mem_resp_valid),
        .mem_resp_rdata   (cpu_mem_resp_rdata)
    );


    // CDC Bridge (Crosses from cpu_clk to mem_clk)
    memory_cdc_bridge bridge (
        .cpu_clk          (cpu_clk),
        .mem_clk          (mem_clk),
        .rstn             (rstn),

        // CPU side
        .cpu_req_valid    (cpu_mem_req_valid),
        .cpu_req_ready    (cpu_mem_req_ready),
        .cpu_req_we       (cpu_mem_req_we),
        .cpu_req_addr     (cpu_mem_req_addr),
        .cpu_req_wdata    (cpu_mem_req_wdata),

        .cpu_resp_valid   (cpu_mem_resp_valid),
        .cpu_resp_rdata   (cpu_mem_resp_rdata),

        // Memory side
        .mem_req_valid    (mem_req_valid),
        .mem_req_ready    (mem_req_ready),
        .mem_req_we       (mem_req_we),
        .mem_req_addr     (mem_req_addr),
        .mem_req_wdata    (mem_req_wdata),

        .mem_resp_valid   (mem_resp_valid),
        .mem_resp_rdata   (mem_resp_rdata)
    );


    // Main Memory (Runs entirely on mem_clk)
    main_memory dram (
        .clk              (mem_clk),
        .rstn             (rstn),

        .req_valid        (mem_req_valid),
        .req_ready        (mem_req_ready),
        .req_we           (mem_req_we),
        .req_addr         (mem_req_addr),
        .req_wdata        (mem_req_wdata),

        .resp_valid       (mem_resp_valid),
        .resp_rdata       (mem_resp_rdata)
    );

endmodule
