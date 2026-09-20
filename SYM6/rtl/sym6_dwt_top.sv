// SPDX-License-Identifier: Apache-2.0
// Copyright (c) Maktab-e-Digital Systems Lahore


module sym6_dwt_top (
    input  wire        clk, rst_n,
    input  wire        valid_in,
    input  wire        enable,
    input  wire        last_in,
    input  wire signed [15:0] data_in,
    output reg  signed [15:0] approx_out, detail_out,
    output reg                valid_out,
    output reg                last_out
);
    localparam signed [15:0] LP [0:11] = '{
         16'sd505,   16'sd114, -16'sd3866, -16'sd1583,
        16'sd16091, 16'sd25809, 16'sd11073, -16'sd2380,
        -16'sd690,  16'sd1466,   16'sd58,   -16'sd256
    };
    localparam signed [15:0] HP [0:11] = '{
         16'sd256,   16'sd58,  -16'sd1466,  -16'sd690,
        16'sd2380,  16'sd11073,-16'sd25809,  16'sd16091,
        16'sd1583,  -16'sd3866,  -16'sd114,   16'sd505
    };

    wire fir_valid = valid_in & enable;

    wire signed [15:0] lp_out, hp_out;
    wire               lp_vld;

    sym6_fir_core #(.DATA_WIDTH(16),.FRAC_BITS(15),.COEFFS(LP)) u_lp (
        .clk(clk),.rst_n(rst_n),.valid_in(fir_valid),
        .sample_in(data_in),.filter_out(lp_out),.valid_out(lp_vld));

    sym6_fir_core #(.DATA_WIDTH(16),.FRAC_BITS(15),.COEFFS(HP)) u_hp (
        .clk(clk),.rst_n(rst_n),.valid_in(fir_valid),
        .sample_in(data_in),.filter_out(hp_out),.valid_out());

    
    reg last_pending;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            last_pending <= 0;
        else if (fir_valid)
            last_pending <= last_in;
    end

    
    reg ds_flag;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ds_flag    <= 0;
            valid_out  <= 0;
            approx_out <= 0;
            detail_out <= 0;
            last_out   <= 0;
        end else if (!enable) begin
            valid_out <= 0;
            last_out  <= 0;
        end else if (lp_vld) begin
            ds_flag <= ~ds_flag;
            if (last_pending) begin
                
                valid_out  <= 1'b1;
                last_out   <= 1'b1;
                approx_out <= lp_out;
                detail_out <= hp_out;
            end else begin
                valid_out <= ds_flag;
                last_out  <= 1'b0;
                if (ds_flag) begin
                    approx_out <= lp_out;
                    detail_out <= hp_out;
                end
            end
        end else begin
            valid_out <= 0;
            last_out  <= 0;
        end
    end
endmodule