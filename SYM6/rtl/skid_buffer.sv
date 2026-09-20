// SPDX-License-Identifier: Apache-2.0
// Copyright (c) Maktab-e-Digital Systems Lahore


module skid_buffer #(
    parameter DATA_WIDTH = 16
)(
    input  wire        clk, rst_n,
    input  wire         pad_ready,
    input  wire         in_valid,
    input  wire signed [DATA_WIDTH-1:0] in_data,
    input  wire         in_last,
    output wire         out_valid,
    output wire signed [DATA_WIDTH-1:0] out_data,
    output wire         out_last,
    output wire         stall_upstream
);
    reg full;
    reg signed [DATA_WIDTH-1:0] data_r;
    reg last_r;

    
    assign out_valid      = full | in_valid;
    assign out_data       = full ? data_r : in_data;
    assign out_last       = full ? last_r : in_last;
    assign stall_upstream = full;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            full   <= 1'b0;
            data_r <= '0;
            last_r <= 1'b0;
        end else if (full) begin
           
            if (pad_ready) full <= 1'b0;
        end else begin
            
            if (in_valid && !pad_ready) begin
                full   <= 1'b1;
                data_r <= in_data;
                last_r <= in_last;
            end
        end
    end
endmodule