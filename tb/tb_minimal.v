`timescale 1ns/1ps

// Module: tb_minimal
// Description: Minimal, interactive testbench for CPULite V2 Pipelined Processor.
//              Features:
//              1. Stage-by-stage pipeline table printing (IF, ID, EX, MEM, WB).
//              2. Clear hazard detection (Cache Stall, Load-Use Stall, Forwarding, Flush).
//              3. ALU operation logging with explicit PSR flags.
//              4. Cache Read/Write and Hit/Miss reporting.
//              5. Register File dump in pure hexadecimal (no decimal).
//              6. Accessed memory locations dump with their final values.

module tb_minimal;

    // Clock and Reset signals
    reg cpu_clk;
    reg mem_clk;
    reg rstn;

    // Instantiate Top-Level SoC
    system_top dut (
        .cpu_clk (cpu_clk),
        .mem_clk (mem_clk),
        .rstn    (rstn)
    );

    // -------------------------------------------------------------------------
    // Clock Generation
    // cpu_clk: ~150 MHz reference (period ~6.667 ns, toggled every 3.333 ns)
    // mem_clk: ~70 MHz reference (period ~14.286 ns, toggled every 7.143 ns)
    // -------------------------------------------------------------------------
    always #3.333 cpu_clk = ~cpu_clk;
    always #7.143 mem_clk = ~mem_clk;

    // Cycle Counter
    integer cycle;
    always @(posedge cpu_clk or negedge rstn) begin
        if (!rstn)
            cycle <= 0;
        else
            cycle <= cycle + 1;
    end

    // -------------------------------------------------------------------------
    // Instruction Disassembler (Formatted short assembly string)
    // -------------------------------------------------------------------------
    function [159:0] format_inst(input [31:0] inst);
        reg [7:0]   op;
        reg [3:0]   rd, rs1, rs2;
        reg [11:0]  imm;
        reg [159:0] tmp;
        begin
            op  = inst[31:24];
            rd  = inst[23:20];
            rs1 = inst[19:16];
            rs2 = inst[15:12];
            imm = inst[11:0];
            case (op)
                8'h00: $sformat(tmp, "NOP");
                8'h01: $sformat(tmp, "LOAD R%0d,0x%03h", rd, imm);
                8'h02: $sformat(tmp, "LOAD_IND R%0d,[R%0d]", rd, rs1);
                8'h03: $sformat(tmp, "LDI R%0d,0x%03h", rd, imm);
                8'h04: $sformat(tmp, "STORE R%0d,0x%03h", rd, imm);
                8'h05: $sformat(tmp, "STORE_IND R%0d,[R%0d]", rd, rs2);
                8'h06: $sformat(tmp, "ADD R%0d,R%0d,R%0d", rd, rs1, rs2);
                8'h07: $sformat(tmp, "SUB R%0d,R%0d,R%0d", rd, rs1, rs2);
                8'h08: $sformat(tmp, "MUL R%0d,R%0d,R%0d", rd, rs1, rs2);
                8'h09: $sformat(tmp, "AND R%0d,R%0d,R%0d", rd, rs1, rs2);
                8'h0A: $sformat(tmp, "OR  R%0d,R%0d,R%0d", rd, rs1, rs2);
                8'h0B: $sformat(tmp, "NOT R%0d,R%0d", rd, rs1);
                8'h0C: $sformat(tmp, "CMP R%0d,R%0d", rs1, rs2);
                8'h0D: $sformat(tmp, "EQ  R%0d,R%0d,R%0d", rd, rs1, rs2);
                8'h0E: $sformat(tmp, "JMP 0x%03h", imm);
                8'h0F: $sformat(tmp, "JMP_IF R%0d,0x%03h", rs1, imm);
                8'h10: $sformat(tmp, "XOR R%0d,R%0d,R%0d", rd, rs1, rs2);
                8'h11: $sformat(tmp, "SHL R%0d,R%0d,R%0d", rd, rs1, rs2);
                8'h12: $sformat(tmp, "SHR R%0d,R%0d,R%0d", rd, rs1, rs2);
                8'h13: $sformat(tmp, "SAR R%0d,R%0d,R%0d", rd, rs1, rs2);
                8'h14: $sformat(tmp, "ROL R%0d,R%0d,R%0d", rd, rs1, rs2);
                8'h15: $sformat(tmp, "ROR R%0d,R%0d,R%0d", rd, rs1, rs2);
                8'h16: $sformat(tmp, "ADDI R%0d,R%0d,0x%03h", rd, rs1, imm);
                8'h17: $sformat(tmp, "SUBI R%0d,R%0d,0x%03h", rd, rs1, imm);
                8'h18: $sformat(tmp, "ANDI R%0d,R%0d,0x%03h", rd, rs1, imm);
                8'h19: $sformat(tmp, "ORI  R%0d,R%0d,0x%03h", rd, rs1, imm);
                8'h1A: $sformat(tmp, "XORI R%0d,R%0d,0x%03h", rd, rs1, imm);
                8'h1B: $sformat(tmp, "MOV R%0d,R%0d", rd, rs1);
                8'h1C: $sformat(tmp, "SLT R%0d,R%0d,R%0d", rd, rs1, rs2);
                8'h1D: $sformat(tmp, "SLTU R%0d,R%0d,R%0d", rd, rs1, rs2);
                8'h1E: $sformat(tmp, "LUI R%0d,0x%03h", rd, imm);
                8'h20: $sformat(tmp, "BEQ 0x%03h", imm);
                8'h21: $sformat(tmp, "BNE 0x%03h", imm);
                8'h22: $sformat(tmp, "BLT 0x%03h", imm);
                8'h23: $sformat(tmp, "BGE 0x%03h", imm);
                8'h24: $sformat(tmp, "BLTU 0x%03h", imm);
                8'h25: $sformat(tmp, "BGEU 0x%03h", imm);
                8'h26: $sformat(tmp, "JMP_REG R%0d", rs1);
                8'hFF: $sformat(tmp, "HALT");
                default: $sformat(tmp, "0x%08h", inst);
            endcase
            format_inst = tmp;
        end
    endfunction

    // -------------------------------------------------------------------------
    // Program Memory Loading & Instruction Tagging
    // -------------------------------------------------------------------------
    reg [159:0] inst_tag [0:4095];
    reg [255:0] mem_filename;
    integer i_init, i_scan, inst_num, f_check;
    reg [159:0] tmp_tag;

    initial begin
        // Pre-initialize program memory with 0 (NOP)
        for (i_init = 0; i_init < 4096; i_init = i_init + 1) begin
            dut.processor.program_mem.instructions[i_init] = 32'h00000000;
        end

        // Load instruction file
        if ($value$plusargs("MEM=%s", mem_filename)) begin
            $display("[TB] Loading program from: %0s", mem_filename);
            $readmemh(mem_filename, dut.processor.program_mem.instructions);
        end
        else begin
            f_check = $fopen("instructions.mem", "r");
            if (f_check != 0) begin
                $fclose(f_check);
                $display("[TB] Found 'instructions.mem'. Loading into Program Memory...");
                $readmemh("instructions.mem", dut.processor.program_mem.instructions);
            end
            else begin
                $display("[TB] 'instructions.mem' not found. Loading fallback: 'instructions_set4.mem'...");
                $readmemh("instructions_set4.mem", dut.processor.program_mem.instructions);
            end
        end

        // Pre-scan and tag each non-zero instruction: I1, I2, I3...
        inst_num = 1;
        for (i_scan = 0; i_scan < 4096; i_scan = i_scan + 1) begin
            if (dut.processor.program_mem.instructions[i_scan] != 32'h00000000) begin
                $sformat(tmp_tag, "I%0d:%0s", inst_num, format_inst(dut.processor.program_mem.instructions[i_scan]));
                inst_tag[i_scan] = tmp_tag;
                inst_num = inst_num + 1;
            end
            else begin
                inst_tag[i_scan] = "NOP";
            end
        end
    end

    // -------------------------------------------------------------------------
    // Pipeline Stages Shadow Tracking (IF, ID, EX, MEM, WB)
    // -------------------------------------------------------------------------
    reg [159:0] if_str, id_str, ex_str, mem_str, wb_str;
    reg prev_cache_stall;

    // Track accessed memory locations for final dump
    reg [13:0] accessed_addrs [0:255];
    integer num_accessed;
    integer a_idx;
    reg addr_found;

    always @(posedge cpu_clk or negedge rstn) begin
        if (!rstn) begin
            id_str           <= "---";
            ex_str           <= "---";
            mem_str          <= "---";
            wb_str           <= "---";
            prev_cache_stall <= 1'b0;
            num_accessed     <= 0;
        end
        else begin
            prev_cache_stall <= dut.processor.cache_stall;

            // Record memory locations accessed in MEM stage
            if (!dut.processor.cache_stall && (dut.processor.mem_read || dut.processor.mem_write)) begin
                addr_found = 1'b0;
                for (a_idx = 0; a_idx < num_accessed; a_idx = a_idx + 1) begin
                    if (accessed_addrs[a_idx] == dut.processor.memory_address)
                        addr_found = 1'b1;
                end
                if (!addr_found && num_accessed < 256) begin
                    accessed_addrs[num_accessed] = dut.processor.memory_address;
                    num_accessed = num_accessed + 1;
                end
            end

            // Pipeline register progression
            if (dut.processor.cache_stall) begin
                // Cache stall freezes entire pipeline: all stages hold
            end
            else begin
                // WB stage update
                if (dut.processor.mem_wb.stall) begin
                    // hold
                end else begin
                    if (mem_str == "[FLUSH]")
                        wb_str <= "NOP";
                    else
                        wb_str <= mem_str;
                end

                // MEM stage update
                if (dut.processor.ex_mem.stall) begin
                    // hold
                end else begin
                    if (ex_str == "[FLUSH]")
                        mem_str <= "NOP";
                    else
                        mem_str <= ex_str;
                end

                // EX stage update
                if (dut.processor.flush_ex) begin
                    if (dut.processor.ex_final_pc_src)
                        ex_str <= "[FLUSH]";
                    else
                        ex_str <= "[BUBBLE]";
                end else if (dut.processor.id_ex.stall) begin
                    // hold
                end else begin
                    if (id_str == "[FLUSH]")
                        ex_str <= "NOP";
                    else
                        ex_str <= id_str;
                end

                // ID stage update
                if (dut.processor.flush_id) begin
                    id_str <= "[FLUSH]";
                end else if (dut.processor.stall_id) begin
                    // hold
                end else begin
                    if (dut.processor.pc_current < 4096)
                        id_str <= inst_tag[dut.processor.pc_current];
                    else
                        id_str <= "NOP";
                end
            end
        end
    end

    // -------------------------------------------------------------------------
    // Combinational evaluation of IF stage label for current cycle
    // -------------------------------------------------------------------------
    always @(*) begin
        if (!rstn) begin
            if_str = "---";
        end
        else if (dut.processor.cache_stall || dut.processor.stall_if) begin
            if_str = "[STALL]";
        end
        else if (dut.processor.pc_current < 4096) begin
            if_str = inst_tag[dut.processor.pc_current];
        end
        else begin
            if_str = "NOP";
        end
    end

    // -------------------------------------------------------------------------
    // Cycle-by-Cycle Pipeline Table & Execution Log
    // -------------------------------------------------------------------------
    always @(posedge cpu_clk) begin
        if (rstn) begin

            // Print Pipeline Stage Table Row
            $display("  %4d | 0x%03h | %-17s | %-17s | %-17s | %-17s | %-17s",
                     cycle, dut.processor.pc_current, if_str, id_str, ex_str, mem_str, wb_str);

            // 1. Hazards & Stalls
            if (dut.processor.cache_stall && !prev_cache_stall) begin
                $display("       >>> (STALL) DUE TO CACHE MISS: Addr 0x%04h -> Pipeline Frozen for DRAM line refill",
                         dut.processor.memory_address);
            end

            if (!dut.processor.cache_stall && prev_cache_stall) begin
                $display("       >>> (CACHE REFILL) 128-bit line loaded from DRAM into L1 Cache | Stall Released");
            end

            if (dut.processor.stall_if && !dut.processor.cache_stall) begin
                $display("       >>> (STALL) DUE TO LOAD-USE HAZARD: Dependent operand needed -> 1-cycle bubble injected into EX");
            end

            if (dut.processor.flush_id && !dut.processor.cache_stall) begin
                $display("       >>> (FLUSH) DUE TO BRANCH TAKEN: Branch target=0x%03h -> Flushing speculative instructions from IF and ID",
                         dut.processor.pc_selected);
            end

            // 2. Data Forwarding
            if ((dut.processor.forward_a_ex != 2'b00 || dut.processor.forward_b_ex != 2'b00) && !dut.processor.cache_stall) begin
                if (dut.processor.forward_a_ex == 2'b10)
                    $display("       >>> (FORWARDING) Operand 1 (R%0d) forwarded from EX/MEM stage = 0x%08h",
                             dut.processor.ex_rs1, dut.processor.mem_forward_data);
                else if (dut.processor.forward_a_ex == 2'b01)
                    $display("       >>> (FORWARDING) Operand 1 (R%0d) forwarded from MEM/WB stage = 0x%08h",
                             dut.processor.ex_rs1, dut.processor.write_back_data);

                if (dut.processor.forward_b_ex == 2'b10)
                    $display("       >>> (FORWARDING) Operand 2 (R%0d) forwarded from EX/MEM stage = 0x%08h",
                             dut.processor.ex_rs2, dut.processor.mem_forward_data);
                else if (dut.processor.forward_b_ex == 2'b01)
                    $display("       >>> (FORWARDING) Operand 2 (R%0d) forwarded from MEM/WB stage = 0x%08h",
                             dut.processor.ex_rs2, dut.processor.write_back_data);
            end

            // 3. ALU Operation Execution & Flag Updates
            if ((dut.processor.ex_flag_we_z || dut.processor.ex_flag_we_n ||
                 dut.processor.ex_flag_we_c || dut.processor.ex_flag_we_v) &&
                !dut.processor.cache_stall && !dut.processor.flush_ex) begin
                $display("       >>> (ALU EX) %0s | Op1=0x%08h, Op2=0x%08h -> Result=0x%08h | Flags: [Z=%b, N=%b, C=%b, V=%b]",
                         ex_str,
                         dut.processor.ex_forwarded_rs1_data,
                         dut.processor.ex_alu_operand2,
                         dut.processor.ex_alu_result,
                         dut.processor.ex_alu_Z,
                         dut.processor.ex_alu_N,
                         dut.processor.ex_alu_C,
                         dut.processor.ex_alu_V);
            end

            // 4. Memory / Cache Access (Reads & Writes)
            if (!dut.processor.cache_stall && (dut.processor.mem_read || dut.processor.mem_write)) begin
                if (dut.processor.mem_read) begin
                    if (dut.processor.cache_ctrl.hit)
                        $display("       * CACHE READ HIT  : Addr=0x%04h -> Data=0x%08h (Hit in L1 Cache)",
                                 dut.processor.memory_address, dut.processor.memory_read_data);
                    else
                        $display("       * CACHE READ MISS : Addr=0x%04h -> Requesting line from DRAM",
                                 dut.processor.memory_address);
                end
                if (dut.processor.mem_write) begin
                    if (dut.processor.cache_ctrl.hit)
                        $display("       * CACHE WRITE HIT : Addr=0x%04h <- Data=0x%08h (L1 Cache updated, marked DIRTY)",
                                 dut.processor.memory_address, dut.processor.memory_write_data);
                    else
                        $display("       * CACHE WRITE MISS: Addr=0x%04h <- Data=0x%08h -> Allocating line from DRAM",
                                 dut.processor.memory_address, dut.processor.memory_write_data);
                end
            end

            // 5. Write-Back Retirement
            if (dut.processor.wb_reg_write && !dut.processor.cache_stall) begin
                $display("       * WB RETIRE: R%-2d <= 0x%08h",
                         dut.processor.wb_rd,
                         dut.processor.write_back_data);
            end

        end
    end

    // -------------------------------------------------------------------------
    // Task: Print Final Architectural State & Memory Dump
    // -------------------------------------------------------------------------
    task print_register_dump;
        reg [13:0] addr;
        reg [5:0]  tag, index;
        reg [1:0]  offset;
        reg [31:0] final_val;
        reg [159:0] mem_location_str;
        integer    k;
        begin
            $display("\n====================================================================================================");
            $display("                                FINAL PROCESSOR ARCHITECTURAL STATE                                 ");
            $display("====================================================================================================");
            $display("  Simulation Time : %0.2f ns", $time);
            $display("  Total CPU Cycles: %0d", cycle);
            $display("  Final PC        : 0x%03h", dut.processor.pc_current);
            $display("  PSR Flags       : Z (Zero)=%b | N (Negative)=%b | C (Carry)=%b | V (Overflow)=%b",
                     dut.processor.PSR[0], dut.processor.PSR[1], dut.processor.PSR[2], dut.processor.PSR[3]);
            $display("----------------------------------------------------------------------------------------------------");
            $display("  General-Purpose Registers (R0 - R15 in Hex):");
            $display("    R0  = 0x%08h    R4  = 0x%08h    R8  = 0x%08h    R12 = 0x%08h",
                     dut.processor.registers.registers[0],
                     dut.processor.registers.registers[4],
                     dut.processor.registers.registers[8],
                     dut.processor.registers.registers[12]);
            $display("    R1  = 0x%08h    R5  = 0x%08h    R9  = 0x%08h    R13 = 0x%08h",
                     dut.processor.registers.registers[1],
                     dut.processor.registers.registers[5],
                     dut.processor.registers.registers[9],
                     dut.processor.registers.registers[13]);
            $display("    R2  = 0x%08h    R6  = 0x%08h    R10 = 0x%08h    R14 = 0x%08h",
                     dut.processor.registers.registers[2],
                     dut.processor.registers.registers[6],
                     dut.processor.registers.registers[10],
                     dut.processor.registers.registers[14]);
            $display("    R3  = 0x%08h    R7  = 0x%08h    R11 = 0x%08h    R15 = 0x%08h",
                     dut.processor.registers.registers[3],
                     dut.processor.registers.registers[7],
                     dut.processor.registers.registers[11],
                     dut.processor.registers.registers[15]);
            $display("----------------------------------------------------------------------------------------------------");
            $display("  Accessed Memory Locations (Final Memory Hierarchy State):");
            if (num_accessed == 0) begin
                $display("    (No data memory locations were accessed during this execution)");
            end
            else begin
                for (k = 0; k < num_accessed; k = k + 1) begin
                    addr   = accessed_addrs[k];
                    tag    = addr[13:8];
                    index  = addr[7:2];
                    offset = addr[1:0];

                    final_val = dut.dram.data_items[addr];

                    $display("    Memory Address 0x%04h:", addr);

                    // Check if line is present in L1 Cache
                    if (dut.processor.cache_ctrl.cache_mem.valid_array[index] &&
                        dut.processor.cache_ctrl.cache_mem.tag_array[index] == tag) begin
                        if (dut.processor.cache_ctrl.cache_mem.dirty_array[index]) begin
                            $display("      -> L1 Data Cache : 0x%08h  [Valid=1, DIRTY=1] (Newest CPU Value)",
                                     dut.processor.cache_ctrl.cache_mem.data_array[index][offset]);
                            $display("      -> Main Memory   : 0x%08h  [STALE: Not yet evicted/written back to DRAM]",
                                     final_val);
                        end
                        else begin
                            $display("      -> L1 Data Cache : 0x%08h  [Valid=1, CLEAN=1] (Matches DRAM)",
                                     dut.processor.cache_ctrl.cache_mem.data_array[index][offset]);
                            $display("      -> Main Memory   : 0x%08h  [COHERENT: In sync with Cache]",
                                     final_val);
                        end
                    end
                    else begin
                        $display("      -> L1 Data Cache : [Not Cached / Line Valid=0]");
                        $display("      -> Main Memory   : 0x%08h", final_val);
                    end
                end
            end
            $display("====================================================================================================\n");
        end
    endtask

    // -------------------------------------------------------------------------
    // Main Simulation Routine
    // -------------------------------------------------------------------------
    initial begin
        $dumpfile("waveform.vcd");
        $dumpvars(0, tb_minimal);

        $display("\n============================================================================================================");
        $display("                               CPULite V2 PIPELINED PROCESSOR - EXECUTION TRACE                             ");
        $display("============================================================================================================");
        $display("  Cycle | PC    | IF                | ID                | EX                | MEM               | WB         ");
        $display("  ------+-------+-------------------+-------------------+-------------------+-------------------+-------------------");

        // Reset Sequence
        cpu_clk = 0;
        mem_clk = 0;
        rstn    = 0;
        #20;
        rstn    = 1;
        @(posedge cpu_clk);

        // Wait for HALT instruction to reach Write-Back stage, or timeout
        fork : sim_watchdog
            begin
                wait (dut.processor.wb_halt == 1'b1);
                #10; // Drain final clock cycle
                $display("\n[TB] *** HALT INSTRUCTION (0xFF) REACHED WRITE-BACK STAGE ***");
                disable sim_watchdog;
            end
            begin
                #20000; // 20 us watchdog timeout
                $display("\n[TB] WARNING: Simulation timeout reached (no HALT encountered within 20us).");
                disable sim_watchdog;
            end
        join

        // Print final architectural state
        print_register_dump;

        $finish;
    end

endmodule
