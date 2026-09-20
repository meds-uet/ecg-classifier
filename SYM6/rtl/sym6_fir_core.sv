// SPDX-License-Identifier: Apache-2.0
// Copyright (c) Maktab-e-Digital Systems Lahore

module sym6_fir_core #(
    parameter DATA_WIDTH = 16,
    parameter FRAC_BITS  = 15,
    parameter signed [15:0] COEFFS [0:11] = '{default:0}
)(
    input  wire        clk, rst_n, valid_in,
    input  wire signed [15:0] sample_in,
    output reg  signed [15:0] filter_out,
    output reg                valid_out
);
    reg signed [15:0] hist [0:10];
    integer i;

    always @(posedge clk or negedge rst_n)
        if (!rst_n)
            for (i = 0; i < 11; i++) hist[i] <= 0;
        else if (valid_in) begin
            hist[0] <= sample_in;
            for (i = 1; i < 11; i++) hist[i] <= hist[i-1];
        end

    wire signed [31:0] products [0:11];
    wire signed [31:0] acc;

    assign products[0] = sample_in * COEFFS[0];
    genvar k;
    generate
        for (k = 1; k < 12; k++)
            assign products[k] = hist[k-1] * COEFFS[k];
    endgenerate

    assign acc = products[0]  + products[1]  + products[2]  + products[3]
               + products[4]  + products[5]  + products[6]  + products[7]
               + products[8]  + products[9]  + products[10] + products[11];

    reg [3:0] fill_cnt;
    reg       ready;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            fill_cnt   <= 0;
            ready      <= 0;
            filter_out <= 0;
            valid_out  <= 0;
        end else if (valid_in) begin
            if (!ready) begin
                ready     <= (fill_cnt == 4'd10);
                fill_cnt  <= fill_cnt + 1;
                valid_out <= 0;
            end else begin
                filter_out <= (acc + 32'sd16384) >>> 15;
                valid_out  <= 1;
            end
        end else
            valid_out <= 0;
    end
endmodule