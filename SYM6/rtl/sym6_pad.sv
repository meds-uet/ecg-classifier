// SPDX-License-Identifier: Apache-2.0
// Copyright (c) Maktab-e-Digital Systems Lahore

module sym_pad #(
    parameter DATA_WIDTH = 16,
    parameter PAD_LEN    = 11
)(
    input  wire        clk, rst_n,
    input  wire        enable,
    input  wire signed [DATA_WIDTH-1:0] data_in,
    input  wire        valid_in,
    input  wire        last,
    output reg  signed [DATA_WIDTH-1:0] data_out,
    output reg         valid_out,
    output reg         last_out,
    output wire        ready
);
    localparam FILL   = 3'd0;
    localparam FLUSH  = 3'd1;
    localparam REPLAY = 3'd2;
    localparam PASS   = 3'd3;
    localparam TAIL   = 3'd4;

    reg [2:0] state;
    reg [3:0] idx;
    reg signed [DATA_WIDTH-1:0] pad_buf [0:PAD_LEN-1];
    reg signed [DATA_WIDTH-1:0] hist    [0:PAD_LEN-1];
    integer i;

    assign ready = enable & ((state == FILL) | (state == PASS));

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state     <= FILL;
            idx       <= 0;
            valid_out <= 0;
            last_out  <= 0;
            data_out  <= 0;
            for (i = 0; i < PAD_LEN; i++) begin
                pad_buf[i] <= 0;
                hist[i]    <= 0;
            end
        end else if (!enable) begin
            valid_out <= 0;
            last_out  <= 0;
        end else case (state)

            FILL: begin
                valid_out <= 0;
                last_out  <= 0;
                if (valid_in) begin
                    pad_buf[idx] <= data_in;
                    hist[idx]    <= data_in;
                    if (idx == PAD_LEN - 1) begin
                        idx   <= PAD_LEN - 1;
                        state <= FLUSH;
                    end else
                        idx <= idx + 1;
                end
            end

            FLUSH: begin
                valid_out <= 1;
                last_out  <= 0;
                data_out  <= pad_buf[idx];
                if (idx == 0) begin
                    state <= REPLAY;
                    idx   <= 4'd0;
                end else
                    idx <= idx - 1;
            end

            REPLAY: begin
                valid_out <= 1;
                last_out  <= 0;
                data_out  <= pad_buf[idx];
                if (idx == PAD_LEN - 1) begin
                    state <= PASS;
                end else
                    idx <= idx + 1;
            end

            PASS: begin
                valid_out <= valid_in;
                last_out  <= 0;
                data_out  <= data_in;
                if (valid_in) begin
                    hist[0] <= data_in;
                    for (i = 1; i < PAD_LEN; i++) hist[i] <= hist[i-1];
                    if (last) begin
                        state <= TAIL;
                        idx   <= 4'd0;
                    end
                end
            end

            TAIL: begin
                valid_out <= 1;
                data_out  <= hist[idx];
                if (idx == PAD_LEN - 1) begin
                    last_out <= 1;
                    state    <= FILL;
                    idx      <= 4'd0;
                end else begin
                    last_out <= 0;
                    idx      <= idx + 1;
                end
            end

            default: state <= FILL;
        endcase
    end
endmodule