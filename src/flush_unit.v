// Flush Unit (Cached Version)
//
// Change from original:
//   Added 'cache_stall' input.
//   All flush signals are gated with !cache_stall.
//   During cache miss, the pipeline is frozen — no flushes
//   are allowed (they would corrupt the frozen state).
//
// When cache_stall releases, any pending branch/stall
// flushes will naturally take effect on the next cycle.
//

module flush_unit (
    input ex_final_pc_src,
    input stall_if, stall_id,
    input cache_stall,           // NEW: inhibit flushes during cache miss
    output flush_id, flush_ex
);

    assign flush_id = ex_final_pc_src && !cache_stall;

    assign flush_ex = !cache_stall && (ex_final_pc_src || (stall_if && stall_id));

endmodule
