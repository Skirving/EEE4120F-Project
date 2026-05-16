// =========================================================================
// Practical 4: StarCore-1 — Single-Cycle Processor in Verilog
// =========================================================================
//
// GROUP NUMBER: 14
//
// MEMBERS:
//   - May Yuan-Klitzner, YNKMAY001
//   - Colby Skirving, SKRCOL001
//
// File        : ALU_Control.v
// Description : ALU Control Unit — Extended for FPC-16 Fixed-Point Core.
//               Maps the 2-bit ALUOp signal (from the Main Control Unit) and
//               the 4-bit instruction opcode to the 4-bit ALUcnt signal that
//               drives the ALU's operation select input.
//               Extended from 3-bit to 4-bit ALU_Cnt to support two new
//               fixed-point instructions: FPMUL (opcode 1110) and FPDIV (1111).
//               This is a purely combinational module.
// =============================================================================

`timescale 1ns / 1ps
`include "../src/Parameter.v"

module ALU_Control (
    input  [1:0] ALUOp,         // From ControlUnit:
                                //   2'b10 = memory access (always ADD for address)
                                //   2'b01 = branch      (always SUB for comparison)
                                //   2'b00 = R-type      (decode from opcode)
    input  [3:0] Opcode,        // Instruction opcode field [15:12]
    output reg [3:0] ALU_Cnt    // Extended: was [2:0], now [3:0] for FPC-16
);

    // -------------------------------------------------------------------------
    // Concatenate ALUOp and Opcode into a single 6-bit control word
    // -------------------------------------------------------------------------
    wire [5:0] control_in;
    assign control_in = {ALUOp, Opcode};

    // -------------------------------------------------------------------------
    // casex truth table:
    //
    // control_in | ALU_Cnt | Operation   | Instruction
    // -----------+---------+-------------+------------------
    // 6'b10xxxx  |  4'b0000 | ADD        | LD, ST
    // 6'b01xxxx  |  4'b0001 | SUB        | BEQ, BNE
    // 6'b000010  |  4'b0000 | ADD        | ADD  (also FPADD — no new hardware)
    // 6'b000011  |  4'b0001 | SUB        | SUB  (also FPSUB — no new hardware)
    // 6'b000100  |  4'b0010 | INV        | INV
    // 6'b000101  |  4'b0011 | SHL        | SHL
    // 6'b000110  |  4'b0100 | SHR        | SHR
    // 6'b000111  |  4'b0101 | AND        | AND
    // 6'b001000  |  4'b0110 | OR         | OR
    // 6'b001001  |  4'b0111 | SLT        | SLT
    // 6'b001110  |  4'b1000 | FPMUL      | FPMUL (NEW — FPC-16)
    // 6'b001111  |  4'b1001 | FPDIV      | FPDIV (NEW — FPC-16)
    // default    |  4'b0000 | ADD (safe) | reserved / undefined
    // -------------------------------------------------------------------------
    always @(*) begin
        casex (control_in)
            // Existing operations — unchanged
            6'b10xxxx : ALU_Cnt = 4'b0000; // ADD — LD/ST address calculation
            6'b01xxxx : ALU_Cnt = 4'b0001; // SUB — branch comparison
            6'b000010 : ALU_Cnt = 4'b0000; // ADD (reused for FPADD)
            6'b000011 : ALU_Cnt = 4'b0001; // SUB (reused for FPSUB)
            6'b000100 : ALU_Cnt = 4'b0010; // INV
            6'b000101 : ALU_Cnt = 4'b0011; // SHL
            6'b000110 : ALU_Cnt = 4'b0100; // SHR
            6'b000111 : ALU_Cnt = 4'b0101; // AND
            6'b001000 : ALU_Cnt = 4'b0110; // OR
            6'b001001 : ALU_Cnt = 4'b0111; // SLT
            // New FPC-16 fixed-point operations
            6'b001110 : ALU_Cnt = 4'b1000; // FPMUL — Q8.8 multiply
            6'b001111 : ALU_Cnt = 4'b1001; // FPDIV — Q8.8 divide
            default   : ALU_Cnt = 4'b0000; // Safe fallback
        endcase
    end

endmodule


