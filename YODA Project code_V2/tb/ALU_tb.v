// =============================================================================
// EEE4120F Practical 4 — StarCore-1 Processor
// File        : ALU_tb.v
// Description : Testbench for the ALU module (Task 1).
//               Applies all 8 operations with multiple input pairs and checks
//               both the result output and the zero flag.
//               Produces automated PASS/FAIL output and a waveform dump.
//
// Run:
//   iverilog -Wall -I ../src -o ../build/alu_sim ../src/ALU.v ALU_tb.v
//   cd ../test && ../build/alu_sim
//   gtkwave ../waves/alu_tb.vcd &
// =============================================================================

`timescale 1ns / 1ps
`include "../src/Parameter.v"

module ALU_tb;

    // -------------------------------------------------------------------------
    // DUT port connections
    // Inputs to the DUT are declared as reg (so the testbench can drive them).
    // Outputs from the DUT are declared as wire (driven by the DUT).
    // -------------------------------------------------------------------------
    reg  [15:0] a;
    reg  [15:0] b;
    reg signed_mode;
    reg  [ 3:0] alu_control;   // Extended: was [2:0], now [3:0] for FPC-16
    wire [15:0] result;
    wire        zero;

    // -------------------------------------------------------------------------
    // DUT instantiation — named port connections
    // -------------------------------------------------------------------------
    ALU uut (
        .a           (a),
        .b           (b),
        .alu_control (alu_control),
        .signed_mode (signed_mode),
        .result      (result),
        .zero        (zero)
    );

    // -------------------------------------------------------------------------
    // Waveform dump — always include this block
    // -------------------------------------------------------------------------
    initial begin
        $dumpfile("../waves/alu_tb.vcd");
        $dumpvars(0, ALU_tb);
    end

    // -------------------------------------------------------------------------
    // Failure counter
    // -------------------------------------------------------------------------
    integer fail_count;
    integer test_id;

    initial begin
        fail_count = 0;
        test_id    = 1;
        signed_mode = 0;   // default unsigned
    end

    // -------------------------------------------------------------------------
    // Reusable check task
    // Compares 'got' against 'expected' and prints PASS or FAIL.
    // Increments fail_count on mismatch.
    // -------------------------------------------------------------------------
    task check_result;
        input [15:0] got;
        input [15:0] expected;
        input [63:0] id;        // test number for display
        begin
            if (got !== expected) begin
                $display("FAIL [T%0d]: result = %0d (0x%h), expected = %0d (0x%h)",
                         id, got, got, expected, expected);
                fail_count = fail_count + 1;
            end else begin
                $display("PASS [T%0d]: result = %0d (0x%h)", id, got, got);
            end
        end
    endtask

    task check_zero;
        input got;
        input expected;
        input [63:0] id;
        begin
            if (got !== expected) begin
                $display("FAIL [T%0d] zero flag: got = %b, expected = %b", id, got, expected);
                fail_count = fail_count + 1;
            end else begin
                $display("PASS [T%0d] zero flag = %b", id, got);
            end
        end
    endtask

    // =========================================================================
    // STIMULUS AND CHECKING
    // =========================================================================
    initial begin
        $display("=== ALU Testbench ===");
        $display("--- ADD (alu_control = 3'b000) ---");

        // TODO: Test ADD — apply at least three different input pairs.
                         a = 16'd10; b = 16'd5; alu_control = 3'b000; #10;
                         check_result(result, 16'd15, test_id); test_id = test_id + 1;
                         
                         a = 16'hFFFF; b = 16'd1; alu_control = 3'b000; #10;
                         check_result(result, 16'h0000, test_id); test_id = test_id + 1;

                         a = 16'd0; b = 16'd0; alu_control = 3'b000; #10;
                         check_result(result, 16'd0, test_id); test_id = test_id + 1;

        //       Suggested pairs: (10,5), (0xFFFF, 1) [overflow], (0, 0)


        $display("--- SUB (alu_control = 3'b001) ---");

        // TODO: Test SUB with at least three pairs.
        //       Include a case where result = 0 to test the zero flag.
        //       Suggested pairs: (10, 5), (7, 7) [result=0], (5, 10) [underflow wrap]
                        a = 16'd10; b = 16'd5; alu_control = 3'b001; #10;
                        check_result(result, 16'd5, test_id); test_id = test_id + 1;

                        a = 16'd7; b = 16'd7; alu_control = 3'b001; #10;
                        check_result(result, 16'd0, test_id); test_id = test_id + 1;

                        a = 16'd5; b = 16'd10; alu_control = 3'b001; #10;
                        check_result(result, 16'hFFFB, test_id); test_id = test_id + 1;


        $display("--- INV / NOT (alu_control = 3'b010) ---");

        // TODO: Test INV (bitwise NOT, b is ignored) with at least two values.
        //       Suggested values for a: 16'h0000, 16'hFFFF, 16'hA5A5
                         a = 16'h0000; b = 16'd0; alu_control = 3'b010; #10;
                         check_result(result, 16'hFFFF, test_id); test_id = test_id + 1;

                         a = 16'hFFFF; b = 16'd0; alu_control = 3'b010; #10;
                         check_result(result, 16'h0000, test_id); test_id = test_id + 1;

                         a = 16'hA5A5; b = 16'd0; alu_control = 3'b010; #10;
                         check_result(result, 16'h5A5A, test_id); test_id = test_id + 1;


        $display("--- SHL (alu_control = 3'b011) ---");

        // TODO: Test left shift. Remember only b[3:0] is used as the shift amount.
        //       Suggested pairs (a, b): (16'h0001, 4), (16'h0003, 2), (16'hFFFF, 8)
                         a = 16'h0001; b = 16'd4; alu_control = 3'b011; #10;
                         check_result(result, 16'h0010, test_id); test_id = test_id + 1;

                         a = 16'h0003; b = 16'd2; alu_control = 3'b011; #10;
                         check_result(result, 16'h000C, test_id); test_id = test_id + 1;

                         a = 16'hFFFF; b = 16'd8; alu_control = 3'b011; #10;
                         check_result(result, 16'hFF00, test_id); test_id = test_id + 1;

        $display("--- SHR (alu_control = 3'b100) ---");

        // TODO: Test right shift (logical — MSB fills with 0).
        //       Suggested pairs: (16'h0080, 4), (16'hFFFF, 8), (16'h0001, 1)
                         a = 16'h0080; b = 16'd4; alu_control = 3'b100; #10;
                         check_result(result, 16'h0008, test_id); test_id = test_id + 1;

                         a = 16'hFFFF; b = 16'd8; alu_control = 3'b100; #10;
                         check_result(result, 16'h00FF, test_id); test_id = test_id + 1;

                         a = 16'h0001; b = 16'd1; alu_control = 3'b100; #10;
                         check_result(result, 16'h0000, test_id); test_id = test_id + 1;


        $display("--- AND (alu_control = 3'b101) ---");

        // TODO: Test bitwise AND.
        //       Suggested pairs: (16'hFFFF, 16'h0F0F), (16'hAAAA, 16'h5555), (0, anything)
                         a = 16'hFFFF; b = 16'h0F0F; alu_control = 3'b101; #10;
                         check_result(result, 16'h0F0F, test_id); test_id = test_id + 1;

                         a = 16'hAAAA; b = 16'h5555; alu_control = 3'b101; #10;
                         check_result(result, 16'h0000, test_id); test_id = test_id + 1;

                         a = 16'h0000; b = 16'hFFFF; alu_control = 3'b101; #10;
                         check_result(result, 16'h0000, test_id); test_id = test_id + 1;


        $display("--- OR (alu_control = 3'b110) ---");

        // TODO: Test bitwise OR.
        //       Suggested pairs: (16'h0F0F, 16'hF0F0), (16'hAAAA, 16'h5555), (0, 16'hBEEF)
                         a = 16'h0F0F; b = 16'hF0F0; alu_control = 3'b110; #10;
                         check_result(result, 16'hFFFF, test_id); test_id = test_id + 1;

                         a = 16'hAAAA; b = 16'h5555; alu_control = 3'b110; #10;
                         check_result(result, 16'hFFFF, test_id); test_id = test_id + 1;

                         a = 16'h0000; b = 16'hBEEF; alu_control = 3'b110; #10;
                         check_result(result, 16'hBEEF, test_id); test_id = test_id + 1;


        $display("--- SLT (alu_control = 3'b111) ---");

        // TODO: Test set-less-than. Result must be 1 when a < b (unsigned), 0 otherwise.
        //       Test cases must include: a < b, a == b, a > b.
        //       Suggested pairs: (5, 10) -> 1,  (10, 10) -> 0,  (15, 3) -> 0
                         a = 16'd5; b = 16'd10; alu_control = 3'b111; #10;
                         check_result(result, 16'd1, test_id); test_id = test_id + 1;

                         a = 16'd10; b = 16'd10; alu_control = 3'b111; #10;
                         check_result(result, 16'd0, test_id); test_id = test_id + 1;

                         a = 16'd15; b = 16'd3; alu_control = 3'b111; #10;
                         check_result(result, 16'd0, test_id); test_id = test_id + 1;


        $display("--- Zero flag edge cases ---");

        // TODO: Verify the zero flag is asserted for SUB where a == b.
        //       Verify the zero flag is de-asserted for all non-zero results.
        //       Verify the zero flag for INV of 16'hFFFF (result should be 0).
                        a = 16'd7; b = 16'd7; alu_control = 3'b001; #10;
                        check_zero(zero, 1'b1, test_id); test_id = test_id + 1;

                        a = 16'd10; b = 16'd5; alu_control = 3'b000; #10;
                        check_zero(zero, 1'b0, test_id); test_id = test_id + 1;

                        a = 16'hFFFF; b = 16'd0; alu_control = 3'b010; #10;
                        check_zero(zero, 1'b1, test_id); test_id = test_id + 1;

        $display("--- FPMUL (alu_control = 4'b1000) --- Q8.8 Fixed-Point Multiply ---");

        // FPMUL Test 1: 2.0 x 3.0 = 6.0
        // 2.0 in Q8.8 = 2 x 256 = 512 = 0x0200
        // 3.0 in Q8.8 = 3 x 256 = 768 = 0x0300
        // Expected: 6.0 in Q8.8 = 6 x 256 = 1536 = 0x0600
        a = 16'h0200; b = 16'h0300; alu_control = 4'b1000; #10;
        check_result(result, 16'h0600, test_id); test_id = test_id + 1;

        // FPMUL Test 2: 1.5 x 2.0 = 3.0
        // 1.5 in Q8.8 = 1.5 x 256 = 384 = 0x0180
        // 2.0 in Q8.8 = 2 x 256 = 512 = 0x0200
        // Expected: 3.0 in Q8.8 = 3 x 256 = 768 = 0x0300
        a = 16'h0180; b = 16'h0200; alu_control = 4'b1000; #10;
        check_result(result, 16'h0300, test_id); test_id = test_id + 1;

        // FPMUL Test 3: 1.5 x 1.5 = 2.25
        // 1.5 in Q8.8 = 384 = 0x0180
        // Expected: 2.25 in Q8.8 = 2.25 x 256 = 576 = 0x0240
        a = 16'h0180; b = 16'h0180; alu_control = 4'b1000; #10;
        check_result(result, 16'h0240, test_id); test_id = test_id + 1;

        // FPMUL Test 4: 6.7 x 5.9 = 39.53 (truncated to 39.51 due to Q8.8 precision)
        // 6.7 in Q8.8 = 0x06B3 (1715), 5.9 in Q8.8 = 0x05E6 (1510)
        // 1715 x 1510 = 2,589,650 → bits[23:8] = 0x2783 = 39.51 in Q8.8
        a = 16'h06B3; b = 16'h05E6; alu_control = 4'b1000; #10;
        check_result(result, 16'h2783, test_id); test_id = test_id + 1;


        // =========================================================================
        // FPC-16 Fixed-Point Tests
        // =========================================================================

       $display("--- FPDIV (alu_control = 4'b1001) --- Q8.8 Fixed-Point Divide ---");

        // FPDIV Test 1: 6.0 / 2.0 = 3.0
        // 6.0 in Q8.8 = 6 x 256 = 1536 = 0x0600
        // 2.0 in Q8.8 = 2 x 256 = 512  = 0x0200
        // Pre-shift: {0x0600, 8'b0} = 0x060000 / 0x0200 = 0x0300
        // Expected: 3.0 in Q8.8 = 3 x 256 = 768 = 0x0300
        a = 16'h0600; b = 16'h0200; alu_control = 4'b1001; signed_mode = 0; #10;
        check_result(result, 16'h0300, test_id); test_id = test_id + 1;  // T36

        // FPDIV Test 2: 3.0 / 1.5 = 2.0
        // 3.0 in Q8.8 = 3 x 256 = 768  = 0x0300
        // 1.5 in Q8.8 = 1.5 x 256 = 384 = 0x0180
        // Pre-shift: {0x0300, 8'b0} = 0x030000 / 0x0180 = 0x0200
        // Expected: 2.0 in Q8.8 = 2 x 256 = 512 = 0x0200
        a = 16'h0300; b = 16'h0180; alu_control = 4'b1001; signed_mode = 0; #10;
        check_result(result, 16'h0200, test_id); test_id = test_id + 1;  // T37

        // FPDIV Test 3: 1.0 / 4.0 = 0.25
        // 1.0 in Q8.8 = 1 x 256 = 256  = 0x0100
        // 4.0 in Q8.8 = 4 x 256 = 1024 = 0x0400
        // Pre-shift: {0x0100, 8'b0} = 0x010000 / 0x0400 = 0x0040
        // Expected: 0.25 in Q8.8 = 0.25 x 256 = 64 = 0x0040
        a = 16'h0100; b = 16'h0400; alu_control = 4'b1001; signed_mode = 0; #10;
        check_result(result, 16'h0040, test_id); test_id = test_id + 1;  // T38

        // FPDIV Test 4: divide by zero → saturate to 0xFFFF
        // Any dividend / 0 = undefined → saturate to max unsigned = 0xFFFF
        a = 16'h0300; b = 16'h0000; alu_control = 4'b1001; signed_mode = 0; #10;
        check_result(result, 16'hFFFF, test_id); test_id = test_id + 1;  // T39

        $display("--- FPMUL Signed (alu_control = 4'b1000, signed_mode = 1) --- Q8.8 Signed Multiply ---");

        // FPMUL Signed Test 1: (-2.0) x 3.0 = -6.0
        // -2.0 in Q8.8 signed two's complement = 0xFE00
        //  3.0 in Q8.8 = 0x0300
        // Expected: -6.0 in Q8.8 signed = 0xFA00
        a = 16'hFE00; b = 16'h0300; alu_control = 4'b1000; signed_mode = 1; #10;
        check_result(result, 16'hFA00, test_id); test_id = test_id + 1;  // T40

        // FPMUL Signed Test 2: (-1.5) x (-2.0) = 3.0              <- T41 is here
        // -1.5 in Q8.8 signed two's complement = 0xFE80
        // -2.0 in Q8.8 signed two's complement = 0xFE00
        // Expected: 3.0 in Q8.8 = 0x0300
        a = 16'hFE80; b = 16'hFE00; alu_control = 4'b1000; signed_mode = 1; #10;
        check_result(result, 16'h0300, test_id); test_id = test_id + 1;  // T41

        // FPMUL Signed Test 3: 0.5 x (-0.5) = -0.25
        //  0.5  in Q8.8 = 0x0080
        // -0.5  in Q8.8 signed two's complement = 0xFF80
        // Expected: -0.25 in Q8.8 signed = 0xFFC0
        a = 16'h0080; b = 16'hFF80; alu_control = 4'b1000; signed_mode = 1; #10;
        check_result(result, 16'hFFC0, test_id); test_id = test_id + 1;  // T42

        $display("--- FPDIV Signed (alu_control = 4'b1001, signed_mode = 1) --- Q8.8 Signed Divide ---");

        // FPDIV Signed Test 1: (-6.0) / 2.0 = -3.0
        // -6.0 in Q8.8 signed two's complement = 0xFA00
        //  2.0 in Q8.8 = 0x0200
        // Pre-shift: sign-extend 0xFA00 to 24 bits then shift left 8
        // Expected: -3.0 in Q8.8 signed = 0xFD00
        a = 16'hFA00; b = 16'h0200; alu_control = 4'b1001; signed_mode = 1; #10;
        check_result(result, 16'hFD00, test_id); test_id = test_id + 1;  // T43

        // FPDIV Signed Test 2: (-4.0) / (-2.0) = 2.0
        // -4.0 in Q8.8 signed two's complement = 0xFC00
        // -2.0 in Q8.8 signed two's complement = 0xFE00
        // Expected: 2.0 in Q8.8 = 0x0200
        a = 16'hFC00; b = 16'hFE00; alu_control = 4'b1001; signed_mode = 1; #10;
        check_result(result, 16'h0200, test_id); test_id = test_id + 1;  // T44

        // FPDIV Signed Test 3: 1.0 / (-4.0) = -0.25
        //  1.0 in Q8.8 = 0x0100
        // -4.0 in Q8.8 signed two's complement = 0xFC00
        // Expected: -0.25 in Q8.8 signed = 0xFFC0
        a = 16'h0100; b = 16'hFC00; alu_control = 4'b1001; signed_mode = 1; #10;
        check_result(result, 16'hFFC0, test_id); test_id = test_id + 1;  // T45

        // FPDIV Signed Test 4: divide by zero → saturate to 0x7FFF (+MAX signed)
        // Any dividend / 0 = undefined → saturate to max positive signed = 0x7FFF
        a = 16'h0200; b = 16'h0000; alu_control = 4'b1001; signed_mode = 1; #10;
        check_result(result, 16'h7FFF, test_id); test_id = test_id + 1;  // T46

        // -------------------------------------------------------------------h----
        // Summary
        // -----------------------------------------------------------------------
        $display("");
        if (fail_count == 0)
            $display("=== ALL %0d TESTS PASSED ===", test_id - 1);
        else
            $display("=== %0d / %0d TESTS FAILED ===", fail_count, test_id - 1);

        $finish;
    end

endmodule
