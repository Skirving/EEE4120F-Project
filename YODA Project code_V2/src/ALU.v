// =========================================================================
// FPC-16 Fixed-Point Precision Core — Extended StarCore-1 Processor
// =========================================================================
//
// GROUP NUMBER: 14
//
// MEMBERS:
//   - May Yuan-Klitzner, YNKMAY001
//   - Colby Skirving, SKRCOL001
//   -Sandakahle Bhengu, BHNSAN010
//
// File        : ALU.v
// Description : 16-bit Arithmetic and Logic Unit (ALU) — Extended for FPC-16.
//               Implements all arithmetic and logic operations required by
//               the StarCore ISA plus two new fixed-point instructions:
//               FPMUL (4'b1000) and FPDIV (4'b1001).
//
//               FPC-16 Extension:
//               alu_control extended from 3-bit to 4-bit to accommodate
//               FPMUL and FPDIV. All existing operations unchanged.
//
//               Q8.8 Fixed-Point Format:
//               - Upper 8 bits = integer part
//               - Lower 8 bits = fractional part
//               - FPMUL: full 32-bit product extracted at bits[23:8]
//               - FPDIV: dividend pre-shifted left by 8 before division

//               -signed_mode: Opcodes are already fully used
//               -if signed_mode=1, then FPMUL/FPDIV are treated as signed operations
//
//               This is a purely combinational module — no clock input.
// =============================================================================

`timescale 1ns / 1ps
`include "../src/Parameter.v"

module ALU (
    input  [15:0] a,             // Operand A — connected to GPR read data 1
    input  [15:0] b,             // Operand B — connected to ALUSrc mux output
    input  [ 3:0] alu_control,   // Extended: was [2:0], now [3:0] for FPC-16
    input         signed_mode,   //1 = FPMUL/FPDIV are signed operations
    output reg [15:0] result,    // Computed result — fed to DataMemory and write-back mux
    output         zero          // Zero flag: asserted (1) when result == 16'd0
);

    // -------------------------------------------------------------------------
    // Zero flag — asserted when result equals zero
    // -------------------------------------------------------------------------
    assign zero = (result == 16'd0);

    // -------------------------------------------------------------------------
    // Intermediate wires for fixed-point operations
    // -------------------------------------------------------------------------
    wire [31:0] fp_mul_full;     // Full 32-bit product for FPMUL
    wire [23:0] fp_div_shifted;  // Pre-shifted dividend for FPDIV

    assign fp_mul_full    = a * b;           // 16x16 multiply → 32-bit product
    assign fp_div_shifted = {a, 8'b0};     // Pre-shift dividend left by 16 bits
                                             // equivalent to a << 16 in 32 bits

    // -------------------------------------------------------------------------
    // Signed wires - interpret a and b as signed 16 -bit values
    // -------------------------------------------------------------------------
   
     wire signed [15:0] a_s;
     wire signed [15:0] b_s;
     assign a_s = $signed(a);
     assign b_s = $signed(b);


    wire signed [31:0] fp_mul_full_s;
    wire signed [23:0] fp_div_shifted_s;
    assign fp_mul_full_s    = a_s * b_s;
    assign fp_div_shifted_s = $signed(a_s) * 256;  // multiply by 256 = left shift 8, stays signed

    wire [15:0] fp_div_result_u;
    wire signed [15:0] fp_div_result_s;

    assign fp_div_result_u = (b == 16'd0) ? 16'hFFFF
                                        : fp_div_shifted / {8'b0, b};

    assign fp_div_result_s = (b_s == 16'sd0) ? 16'sh7FFF
                                          : fp_div_shifted_s / b_s;

   

    // -------------------------------------------------------------------------
    // ALU operations — purely combinational
    //
    // alu_control | Operation | Expression
    // ------------+-----------+--------------------------------
    // 4'b0000     | ADD       | result = a + b
    // 4'b0001     | SUB       | result = a - b
    // 4'b0010     | INV       | result = ~a (b ignored)
    // 4'b0011     | SHL       | result = a << b[3:0]
    // 4'b0100     | SHR       | result = a >> b[3:0]
    // 4'b0101     | AND       | result = a & b
    // 4'b0110     | OR        | result = a | b
    // 4'b0111     | SLT       | result = (a < b) ? 1 : 0
    // 4'b1000     | FPMUL     | result = (a * b)[23:8] — Q8.8 multiply
    // 4'b1001     | FPDIV     | result = (a << 8) / b  — Q8.8 divide
    // default     | ADD       | safe fallback
    // -------------------------------------------------------------------------
    always @(*) begin
        case (alu_control)
            // Existing operations — unchanged
            4'b0000: result = a + b;                          // ADD
            4'b0001: result = a - b;                          // SUB
            4'b0010: result = ~a;                             // INV (b ignored)
            4'b0011: result = a << b[3:0];                   // SHL
            4'b0100: result = a >> b[3:0];                   // SHR
            4'b0101: result = a & b;                          // AND
            4'b0110: result = a | b;                          // OR
            4'b0111: result = (a < b) ? 16'd1 : 16'd0;      // SLT (unsigned)

            // -----------------------------------------------------------------
            // FPC-16 New Fixed-Point Operations
            // FPMUL: multiply two Q8.8 numbers
            //   - Full product = a * b = 32 bits
            //   - Correct Q8.8 result = bits[23:8] of full product
            //   - bits[31:24] = overflow, bits[7:0] = sub-precision (discarded)
            // FPDIV: divide two Q8.8 numbers
            //   - Pre-shift dividend left by 8: {a, 8'b0} / b
            //   - Equivalent to (a * 256) / b in integer arithmetic
            //   - Produces correct Q8.8 quotient
            // -----------------------------------------------------------------
             // FPMUL — select signed or unsigned path
            4'b1000: result = signed_mode
                              ? fp_mul_full_s[23:8]      // signed Q8.8 multiply
                              : fp_mul_full[23:8];       // unsigned (original)

            // FPDIV — select signed or unsigned path
            4'b1001: result = signed_mode ? fp_div_result_s : fp_div_result_u;
            default: result = a + b;                          // Safe fallback
        endcase
    end

endmodule