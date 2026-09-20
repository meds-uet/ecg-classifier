// SPDX-License-Identifier: Apache-2.0
// Copyright (c) Maktab-e-Digital Systems Lahore


`timescale 1ns / 1ps

module tb_dwt_simple;

    logic        clk, rst_n;// SPDX-License-Identifier: Apache-2.0
// Copyright (c) Maktab-e-Digital Systems Lahore

    logic signed [15:0] data_in;
    logic                valid_in;
    logic                last_in;
    logic signed [15:0] l1_detail, l2_detail, l3_detail, l3_approx;
    logic                l1_valid, l2_valid, l3_valid;
    logic                l3_last;
    logic signed [15:0] l1_approx_out, l2_approx_out;
    logic                pad1_ready, pad2_ready, pad3_ready;

    dwt_3_level_top dut (.*);

    always #5 clk = ~clk;

    wire all_ready = pad1_ready & pad2_ready & pad3_ready;

    localparam signed [15:0] ECG_PASS [0:199] = '{
         16'sd10803,  16'sd10154,  16'sd8515,  16'sd6302,  16'sd3953,
         16'sd1889,  16'sd326, -16'sd668, -16'sd1104, -16'sd1070,
        -16'sd732, -16'sd261,  16'sd215,  16'sd612,  16'sd888,
         16'sd1047,  16'sd1135,  16'sd1193,  16'sd1231,  16'sd1262,
         16'sd1294,  16'sd1334,  16'sd1382,  16'sd1438,  16'sd1502,
         16'sd1576,  16'sd1661,  16'sd1756,  16'sd1864,  16'sd1983,
         16'sd2114,  16'sd2256,  16'sd2410,  16'sd2574,  16'sd2748,
         16'sd2932,  16'sd3124,  16'sd3319,  16'sd3514,  16'sd3706,
         16'sd3892,  16'sd4070,  16'sd4236,  16'sd4389,  16'sd4525,
         16'sd4642,  16'sd4739,  16'sd4814,  16'sd4864,  16'sd4890,
         16'sd4888,  16'sd4857,  16'sd4794,  16'sd4703,  16'sd4588,
         16'sd4451,  16'sd4297,  16'sd4129,  16'sd3951,  16'sd3765,
         16'sd3574,  16'sd3381,  16'sd3188,  16'sd2997,  16'sd2810,
         16'sd2630,  16'sd2457,  16'sd2293,  16'sd2139,  16'sd1996,
         16'sd1865,  16'sd1746,  16'sd1640,  16'sd1546,  16'sd1466,
         16'sd1397,  16'sd1339,  16'sd1290,  16'sd1251,  16'sd1219,
         16'sd1194,  16'sd1175,  16'sd1162,  16'sd1153,  16'sd1148,
         16'sd1147,  16'sd1148,  16'sd1152,  16'sd1158,  16'sd1166,
         16'sd1175,  16'sd1184,  16'sd1195,  16'sd1206,  16'sd1218,
         16'sd1231,  16'sd1244,  16'sd1257,  16'sd1271,  16'sd1284,
         16'sd1298,  16'sd1311,  16'sd1324,  16'sd1338,  16'sd1350,
         16'sd1364,  16'sd1377,  16'sd1390,  16'sd1404,  16'sd1419,
         16'sd1435,  16'sd1453,  16'sd1471,  16'sd1492,  16'sd1516,
         16'sd1541,  16'sd1572,  16'sd1609,  16'sd1656,  16'sd1714,
         16'sd1785,  16'sd1871,  16'sd1973,  16'sd2091,  16'sd2226,
         16'sd2379,  16'sd2549,  16'sd2738,  16'sd2939,  16'sd3142,
         16'sd3341,  16'sd3527,  16'sd3693,  16'sd3833,  16'sd3943,
         16'sd4018,  16'sd4053,  16'sd4047,  16'sd3997,  16'sd3902,
         16'sd3768,  16'sd3607,  16'sd3426,  16'sd3234,  16'sd3039,
         16'sd2846,  16'sd2661,  16'sd2488,  16'sd2331,  16'sd2192,
         16'sd2074,  16'sd1976,  16'sd1898,  16'sd1836,  16'sd1781,
         16'sd1724,  16'sd1653,  16'sd1552,  16'sd1404,  16'sd1190,
         16'sd897,  16'sd592,  16'sd382,  16'sd377,  16'sd692,
         16'sd1445,  16'sd2734,  16'sd4517,  16'sd6618,  16'sd8745,
         16'sd10486,  16'sd11315,  16'sd10931,  16'sd9562,  16'sd7531,
         16'sd5209,  16'sd3016,  16'sd1335,  16'sd235, -16'sd299,
        -16'sd343, -16'sd36,  16'sd435,  16'sd920,  16'sd1337,
         16'sd1641,  16'sd1827,  16'sd1929,  16'sd1997,  16'sd2044,
         16'sd2083,  16'sd2122,  16'sd2168,  16'sd2221,  16'sd2280,
         16'sd2348,  16'sd2424,  16'sd2511,  16'sd2609,  16'sd2717
    };

    integer i;
    integer l1_count, l2_count, l3_count;

    
    initial begin
        clk      = 0;
        rst_n    = 0;
        valid_in = 0;
        last_in  = 0;
        data_in  = 0;
        l1_count = 0;
        l2_count = 0;
        l3_count = 0;

        repeat (6) @(posedge clk);
        #1; rst_n = 1;

        for (i = 0; i < 200; i++) begin
            @(posedge clk);
            while (!all_ready) @(posedge clk);
            #1;
            valid_in = 1;
            data_in  = ECG_PASS[i];
            last_in  = (i == 199) ? 1'b1 : 1'b0;
            @(posedge clk);
            #1;
            valid_in = 0;
            last_in  = 0;
        end

        repeat (2000) @(posedge clk);

        $display("Simulation complete. L1=%0d L2=%0d L3=%0d",
                  l1_count, l2_count, l3_count);
        $finish;
    end

    always @(posedge clk) begin
        if (l1_valid) begin
            $display("L1,%0d,DETAIL=%0d,APPROX=%0d", l1_count, l1_detail, l1_approx_out);
            l1_count = l1_count + 1;
        end
        if (l2_valid) begin
            $display("L2,%0d,DETAIL=%0d,APPROX=%0d", l2_count, l2_detail, l2_approx_out);
            l2_count = l2_count + 1;
        end
        if (l3_valid) begin
            $display("L3,%0d,DETAIL=%0d,APPROX=%0d", l3_count, l3_detail, l3_approx);
            l3_count = l3_count + 1;
        end
    end

endmodule