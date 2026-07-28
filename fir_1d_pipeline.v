// ============================================================
// fir_1d_pipeline.v
// 5-Tap Pipelined FIR Digital Differentiator
// Coefficients: (1/8) * [-1, -2, 0, +2, +1]
//
// PURE PIPELINE — multipliers kept exactly as in direct-form.
// Only change from original: registers inserted between stages.
//
// Pipeline Stages:
//   Stage 1: Shift register (delay line)
//   Stage 2: Multiply each tap by its coefficient
//   Stage 3: Add all products + scale by 1/8
//
// Latency   : 3 clock cycles
// Throughput: 1 output per clock cycle
// Input     : 8-bit unsigned pixel
// Output    : 8-bit unsigned edge magnitude
// ============================================================

module fir_1d_pipeline (
    input  wire        clk,
    input  wire        rst_n,      // active-low synchronous reset
    input  wire        valid_in,
    input  wire [7:0]  x_in,       // 8-bit unsigned pixel

    output reg         valid_out,
    output reg  [7:0]  y_out       // 8-bit unsigned magnitude output
);

    // ----------------------------------------------------------
    // Coefficients: h = [-1, -2, 0, +2, +1]
    // Stored as signed integers (no scaling yet, /8 at the end)
    // ----------------------------------------------------------
    localparam signed [3:0] H0 = -1;
    localparam signed [3:0] H1 = -2;
    localparam signed [3:0] H2 =  0;
    localparam signed [3:0] H3 =  2;
    localparam signed [3:0] H4 =  1;

    // ----------------------------------------------------------
    // STAGE 1: Tapped Delay Line (shift register)
    // sr[0] = x[n], sr[1] = x[n-1], ..., sr[4] = x[n-4]
    // ----------------------------------------------------------
    reg [7:0] sr [0:4];
    reg       s1_valid;

    always @(posedge clk) begin
        if (!rst_n) begin
            sr[0] <= 8'd0; sr[1] <= 8'd0;
            sr[2] <= 8'd0; sr[3] <= 8'd0;
            sr[4] <= 8'd0;
            s1_valid <= 1'b0;
        end else begin
            s1_valid <= valid_in;
            if (valid_in) begin
                sr[0] <= x_in;
                sr[1] <= sr[0];
                sr[2] <= sr[1];
                sr[3] <= sr[2];
                sr[4] <= sr[3];
            end
        end
    end

    // ----------------------------------------------------------
    // STAGE 2: Multiply each tap by its coefficient
    // Input : 8-bit unsigned × 4-bit signed = 12-bit signed
    // p0 = H0 * x[n]   = -1 * x[n]
    // p1 = H1 * x[n-1] = -2 * x[n-1]
    // p2 = H2 * x[n-2] =  0 * x[n-2]  (always zero)
    // p3 = H3 * x[n-3] = +2 * x[n-3]
    // p4 = H4 * x[n-4] = +1 * x[n-4]
    // ----------------------------------------------------------
    reg signed [11:0] p0, p1, p2, p3, p4;
    reg               s2_valid;

    always @(posedge clk) begin
        if (!rst_n) begin
            p0 <= 12'sd0; p1 <= 12'sd0;
            p2 <= 12'sd0; p3 <= 12'sd0;
            p4 <= 12'sd0;
            s2_valid <= 1'b0;
        end else begin
            s2_valid <= s1_valid;
            // Sign-extend sr to signed before multiplying
            p0 <= H0 * $signed({1'b0, sr[0]});
            p1 <= H1 * $signed({1'b0, sr[1]});
            p2 <= H2 * $signed({1'b0, sr[2]});
            p3 <= H3 * $signed({1'b0, sr[3]});
            p4 <= H4 * $signed({1'b0, sr[4]});
        end
    end

    // ----------------------------------------------------------
    // STAGE 3: Add all products, scale by 1/8 (arithmetic >>3)
    // Sum range: max = 2*255 + 255 = 765, min = -765
    // Needs 11 bits signed. After >>3: fits in 8 bits.
    // Output: absolute value clipped to [0, 255]
    // ----------------------------------------------------------
    reg signed [11:0] sum;
    reg               s3_valid;

    always @(posedge clk) begin
        if (!rst_n) begin
            sum      <= 12'sd0;
            s3_valid <= 1'b0;
            valid_out <= 1'b0;
            y_out     <= 8'd0;
        end else begin
            s3_valid  <= s2_valid;
            sum       <= p0 + p1 + p2 + p3 + p4;

            valid_out <= s3_valid;
            if (s3_valid) begin
                // Divide by 8 (arithmetic right shift)
                // Then take absolute value → magnitude
                if (sum[11]) begin
                    // negative: negate then shift
                    y_out <= (~sum + 1'b1) >>> 3;
                end else begin
                    y_out <= sum >>> 3;
                end
            end else begin
                y_out <= 8'd0;
            end
        end
    end

endmodule
