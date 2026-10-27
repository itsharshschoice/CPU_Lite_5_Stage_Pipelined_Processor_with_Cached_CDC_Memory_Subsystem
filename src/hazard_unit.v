// Hazard Unit (Cached Version)
//
// Changes from original:
//   1. Added 'cache_stall' input (from cache_controller).
//   2. Added 'stall_ex' and 'stall_mem' outputs.
//   3. Instantiates stalling_unit_cached and flush_unit_cached
//      instead of the originals.
//   4. forwarding_unit is unchanged.
//

module hazard_unit (

    // ID stage signals
    input  [3:0] id_rs1,
    input  [3:0] id_rs2,
    input  [7:0] id_opcode,

    // EX stage signals
    input  [3:0] ex_rs1,
    input  [3:0] ex_rs2,
    input  [7:0] ex_opcode,

    input        ex_mem_read,
    input  [3:0] ex_rd,

    input        ex_final_pc_src,

    // MEM stage signals
    input        mem_reg_write,
    input        mem_read,
    input  [3:0] mem_rd,

    // WB stage signals
    input        wb_reg_write,
    input  [3:0] wb_rd,

    // Cache stall (NEW)
    input        cache_stall,

    // Hazard outputs
    output [1:0] forward_a_ex,
    output [1:0] forward_b_ex,

    output       stall_if,
    output       stall_id,
    output       stall_ex,       // NEW
    output       stall_mem,      // NEW

    output       flush_id,
    output       flush_ex
);

    // Forwarding logic — unchanged from original.
    forwarding_unit forwarding (
        .ex_rs1        (ex_rs1),
        .ex_rs2        (ex_rs2),
        .ex_opcode     (ex_opcode),

        .mem_reg_write (mem_reg_write),
        .mem_read      (mem_read),
        .mem_rd        (mem_rd),

        .wb_reg_write  (wb_reg_write),
        .wb_rd         (wb_rd),

        .forward_a_ex  (forward_a_ex),
        .forward_b_ex  (forward_b_ex)
    );

    // Stalling logic — cached version with cache_stall.
    stalling_unit stalling (
        .id_rs1        (id_rs1),
        .id_rs2        (id_rs2),
        .id_opcode     (id_opcode),

        .ex_mem_read   (ex_mem_read),
        .ex_rd         (ex_rd),

        .cache_stall   (cache_stall),

        .stall_if      (stall_if),
        .stall_id      (stall_id),
        .stall_ex      (stall_ex),
        .stall_mem     (stall_mem)
    );

    // Flush logic — cached version with cache_stall gating.
    flush_unit flushing (
        .ex_final_pc_src (ex_final_pc_src),

        .stall_if        (stall_if),
        .stall_id        (stall_id),

        .cache_stall     (cache_stall),

        .flush_id        (flush_id),
        .flush_ex        (flush_ex)
    );

endmodule
