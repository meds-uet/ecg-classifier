// SPDX-License-Identifier: Apache-2.0
// Copyright (c) Maktab-e-Digital Systems Lahore

module dwt_3_level_top (
    input  wire        clk, rst_n, valid_in,
    input  wire        last_in,
    input  wire signed [15:0] data_in,

    output wire signed [15:0] l1_detail, l2_detail, l3_detail, l3_approx,
    output wire               l1_valid,  l2_valid,  l3_valid,
    output wire               l3_last,
    output wire signed [15:0] l1_approx_out, l2_approx_out,
    output wire               pad1_ready, pad2_ready, pad3_ready
);
    wire signed [15:0] pad1_data, pad2_data, pad3_data;
    wire               pad1_valid, pad2_valid, pad3_valid;
    wire               pad1_last,  pad2_last,  pad3_last;
    wire signed [15:0] approx1, approx2;
    wire               valid1, valid2;
    wire               last1,  last2;

    assign l1_approx_out = approx1;
    assign l2_approx_out = approx2;

   
    wire skid1_valid, skid1_last, skid1_stall;
    wire signed [15:0] skid1_data;

    wire skid2_valid, skid2_last, skid2_stall;
    wire signed [15:0] skid2_data;

    wire u1_en = ~skid1_stall;
    wire u2_en = ~skid2_stall;

    // Level 1
    sym_pad #(.DATA_WIDTH(16),.PAD_LEN(11)) u_pad1 (
        .clk(clk),.rst_n(rst_n),.enable(u1_en),
        .data_in(data_in),.valid_in(valid_in & pad1_ready),
        .last(last_in),
        .data_out(pad1_data),.valid_out(pad1_valid),
        .last_out(pad1_last),.ready(pad1_ready));

    sym6_dwt_top u1 (
        .clk(clk),.rst_n(rst_n),
        .valid_in(pad1_valid),.enable(u1_en),.last_in(pad1_last),
        .data_in(pad1_data),
        .approx_out(approx1),.detail_out(l1_detail),
        .valid_out(valid1),.last_out(last1));

    skid_buffer #(.DATA_WIDTH(16)) u_skid1 (
        .clk(clk),.rst_n(rst_n),
        .pad_ready(pad2_ready),
        .in_valid(valid1),.in_data(approx1),.in_last(last1),
        .out_valid(skid1_valid),.out_data(skid1_data),.out_last(skid1_last),
        .stall_upstream(skid1_stall));

    // Level 2
    sym_pad #(.DATA_WIDTH(16),.PAD_LEN(11)) u_pad2 (
        .clk(clk),.rst_n(rst_n),.enable(u2_en),
        .data_in(skid1_data),.valid_in(skid1_valid & pad2_ready),
        .last(skid1_last),
        .data_out(pad2_data),.valid_out(pad2_valid),
        .last_out(pad2_last),.ready(pad2_ready));

    sym6_dwt_top u2 (
        .clk(clk),.rst_n(rst_n),
        .valid_in(pad2_valid),.enable(u2_en),.last_in(pad2_last),
        .data_in(pad2_data),
        .approx_out(approx2),.detail_out(l2_detail),
        .valid_out(valid2),.last_out(last2));

    skid_buffer #(.DATA_WIDTH(16)) u_skid2 (
        .clk(clk),.rst_n(rst_n),
        .pad_ready(pad3_ready),
        .in_valid(valid2),.in_data(approx2),.in_last(last2),
        .out_valid(skid2_valid),.out_data(skid2_data),.out_last(skid2_last),
        .stall_upstream(skid2_stall));

    // Level 3 
    sym_pad #(.DATA_WIDTH(16),.PAD_LEN(11)) u_pad3 (
        .clk(clk),.rst_n(rst_n),.enable(1'b1),
        .data_in(skid2_data),.valid_in(skid2_valid & pad3_ready),
        .last(skid2_last),
        .data_out(pad3_data),.valid_out(pad3_valid),
        .last_out(pad3_last),.ready(pad3_ready));

    sym6_dwt_top u3 (
        .clk(clk),.rst_n(rst_n),
        .valid_in(pad3_valid),.enable(1'b1),.last_in(pad3_last),
        .data_in(pad3_data),
        .approx_out(l3_approx),.detail_out(l3_detail),
        .valid_out(l3_valid),.last_out(l3_last));

    assign l1_valid = valid1;
    assign l2_valid = valid2;
endmodule