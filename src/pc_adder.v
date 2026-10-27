// PC adder (adds 1 to the current PC value)

module pc_adder (
    input [11:0] pc_in,
    output [11:0] pc_next
);

    assign pc_next = pc_in + 1'b1;

endmodule