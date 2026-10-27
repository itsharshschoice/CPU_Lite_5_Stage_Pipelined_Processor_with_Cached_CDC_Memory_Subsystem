module processor_status_register (
    input clk, rstn,
    input flag_we_z, flag_we_n, flag_we_c, flag_we_v,
    input Z,N,C,V,
    output reg [3:0] PSR // bit0:Z, bit1:N, bit2:C, bit3:V
);
    
    always @(posedge clk or negedge rstn) begin
        if(!rstn) begin
            PSR <= 4'b0;
        end
        else begin
            if(flag_we_z) begin
                PSR[0] <= Z;
            end
            if(flag_we_n) begin
                PSR[1] <= N;
            end
            if(flag_we_c) begin
                PSR[2] <= C;
            end
            if(flag_we_v) begin
                PSR[3] <= V;
            end
        end
    end

endmodule