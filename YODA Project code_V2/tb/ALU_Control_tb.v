// =============================================================================
// EEE4120F Practical 4 — StarCore-1 Processor
// File        : ALU_Control_tb.v
// Description : Testbench for the ALU Control Unit — Extended for FPC-16.
//               Drives every row of the ALU control truth table and verifies
//               the 4-bit ALUcnt output (extended from 3-bit for FPC-16).
//               New test cases added for FPMUL (opcode 1110) and FPDIV (1111).
//
// Run:
//   iverilog -Wall -I ../src -o ../build/ac_sim ../src/ALU_Control.v ALU_Control_tb.v
//   cd ../test && ../build/ac_sim
//   gtkwave ../waves/ac_tb.vcd &
// =============================================================================

`timescale 1ns / 1ps
`include "../src/Parameter.v"

module ALU_Control_tb;

    reg  [1:0] ALUOp;
    reg  [3:0] Opcode;
    wire [3:0] ALU_Cnt;   // Extended: was [2:0], now [3:0] for FPC-16

    ALU_Control uut (
        .ALUOp   (ALUOp),
        .Opcode  (Opcode),
        .ALU_Cnt (ALU_Cnt)
    );

    initial begin
        $dumpfile("../waves/ac_tb.vcd");
        $dumpvars(0, ALU_Control_tb);
    end

    integer fail_count;
    integer test_id;

    // -------------------------------------------------------------------------
    // check_cnt task — extended to 4-bit for FPC-16
    // -------------------------------------------------------------------------
    task check_cnt;
        input [3:0] got;       // Extended: was [2:0], now [3:0]
        input [3:0] expected;  // Extended: was [2:0], now [3:0]
        input [63:0] id;
        begin
            if (got !== expected) begin
                $display("FAIL [T%0d]: ALU_Cnt = %b, expected = %b", id, got, expected);
                fail_count = fail_count + 1;
            end else
                $display("PASS [T%0d]: ALU_Cnt = %b", id, got);
        end
    endtask

    initial begin
        fail_count = 0;
        test_id    = 1;
        $display("=== ALU_Control Testbench ===");

        // ------------------------------------------------------------------
        // ALUOp = 10 (memory access) — always ADD regardless of opcode
        // ------------------------------------------------------------------
        $display("--- ALUOp=10: all opcodes should map to ADD (0000) ---");

        ALUOp = 2'b10; Opcode = 4'h0; #10;
        check_cnt(ALU_Cnt, 4'b0000, test_id); test_id = test_id + 1;

        ALUOp = 2'b10; Opcode = 4'h5; #10;
        check_cnt(ALU_Cnt, 4'b0000, test_id); test_id = test_id + 1;

        ALUOp = 2'b10; Opcode = 4'hF; #10;
        check_cnt(ALU_Cnt, 4'b0000, test_id); test_id = test_id + 1;

        // ------------------------------------------------------------------
        // ALUOp = 01 (branch) — always SUB regardless of opcode
        // ------------------------------------------------------------------
        $display("--- ALUOp=01: all opcodes should map to SUB (0001) ---");

        ALUOp = 2'b01; Opcode = 4'h0; #10;
        check_cnt(ALU_Cnt, 4'b0001, test_id); test_id = test_id + 1;

        ALUOp = 2'b01; Opcode = 4'hB; #10;
        check_cnt(ALU_Cnt, 4'b0001, test_id); test_id = test_id + 1;

        ALUOp = 2'b01; Opcode = 4'hF; #10;
        check_cnt(ALU_Cnt, 4'b0001, test_id); test_id = test_id + 1;

        // ------------------------------------------------------------------
        // ALUOp = 00 (R-type) — decode from opcode
        // ------------------------------------------------------------------
        $display("--- ALUOp=00: decode per opcode ---");

        ALUOp = 2'b00; Opcode = 4'h2; #10;  // ADD
        check_cnt(ALU_Cnt, 4'b0000, test_id); test_id = test_id + 1;

        ALUOp = 2'b00; Opcode = 4'h3; #10;  // SUB
        check_cnt(ALU_Cnt, 4'b0001, test_id); test_id = test_id + 1;

        ALUOp = 2'b00; Opcode = 4'h4; #10;  // INV
        check_cnt(ALU_Cnt, 4'b0010, test_id); test_id = test_id + 1;

        ALUOp = 2'b00; Opcode = 4'h5; #10;  // SHL
        check_cnt(ALU_Cnt, 4'b0011, test_id); test_id = test_id + 1;

        ALUOp = 2'b00; Opcode = 4'h6; #10;  // SHR
        check_cnt(ALU_Cnt, 4'b0100, test_id); test_id = test_id + 1;

        ALUOp = 2'b00; Opcode = 4'h7; #10;  // AND
        check_cnt(ALU_Cnt, 4'b0101, test_id); test_id = test_id + 1;

        ALUOp = 2'b00; Opcode = 4'h8; #10;  // OR
        check_cnt(ALU_Cnt, 4'b0110, test_id); test_id = test_id + 1;

        ALUOp = 2'b00; Opcode = 4'h9; #10;  // SLT
        check_cnt(ALU_Cnt, 4'b0111, test_id); test_id = test_id + 1;

        // ------------------------------------------------------------------
        // Default case — undefined opcodes should default to ADD (0000)
        // Note: opcode 4'hF is now FPDIV, so use 4'hA as undefined
        // ------------------------------------------------------------------
        $display("--- Default (ALUOp=00, undefined opcode) -> ADD (0000) ---");

        ALUOp = 2'b00; Opcode = 4'hA; #10;  // reserved NOP — defaults to ADD
        check_cnt(ALU_Cnt, 4'b0000, test_id); test_id = test_id + 1;

        ALUOp = 2'b00; Opcode = 4'hD; #10;  // JMP opcode — defaults to ADD
        check_cnt(ALU_Cnt, 4'b0000, test_id); test_id = test_id + 1;

        // ------------------------------------------------------------------
        // FPC-16 New Fixed-Point Instructions
        // FPMUL (opcode 1110 = 4'hE) -> ALU_Cnt = 4'b1000
        // FPDIV (opcode 1111 = 4'hF) -> ALU_Cnt = 4'b1001
        // ------------------------------------------------------------------
        $display("--- FPC-16: FPMUL and FPDIV opcodes ---");

        ALUOp = 2'b00; Opcode = 4'hE; #10;  // FPMUL — Q8.8 multiply
        check_cnt(ALU_Cnt, 4'b1000, test_id); test_id = test_id + 1;

        ALUOp = 2'b00; Opcode = 4'hF; #10;  // FPDIV — Q8.8 divide
        check_cnt(ALU_Cnt, 4'b1001, test_id); test_id = test_id + 1;

        // ------------------------------------------------------------------
        // Summary
        // ------------------------------------------------------------------
        $display("");
        if (fail_count == 0)
            $display("=== ALL %0d TESTS PASSED ===", test_id - 1);
        else
            $display("=== %0d / %0d TESTS FAILED ===", fail_count, test_id - 1);
        $finish;
    end

endmodule