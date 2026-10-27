// Read-only program memory (4k x 32)

module program_memory (
    input [11:0] read_address,
    output [31:0] instruction_out
);
    
    reg [31:0] instructions [0:4095];

    initial begin
        $readmemh("instructions.mem", instructions);
        // $readmemh("instructions_set2.mem", instructions);
    end

    assign instruction_out = instructions[read_address];

endmodule