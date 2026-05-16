// =========================================================================
// FPC-16 Fixed-Point Precision Core — Extended StarCore-1 Processor
// =========================================================================
//
// GROUP NUMBER: 14
//
// MEMBERS:
//   - May Yuan-Klitzner, YNKMAY001
//   - Colby Skirving, SKRCOL001
//
// File        : ControlUnit.v
// Description : Main Control Unit — Extended for FPC-16 Fixed-Point Core.
//               Decodes the 4-bit opcode from the fetched instruction and
//               asserts the full set of control signals that govern the
//               Datapath for the current clock cycle.
//               Extended to support two new fixed-point instructions:
//               FPMUL (opcode 1110) and FPDIV (opcode 1111).
//               Both use identical R-type control signals.
//               This is a purely combinational module.
// =============================================================================

`timescale 1ns / 1ps
`include "../src/Parameter.v"

module ControlUnit (
    input  [3:0] opcode,        // Instruction opcode [15:12] from Datapath

    // ALU control
    output reg [1:0] alu_op,    // Passed to ALU_Control: 10=mem, 01=branch, 00=R-type

    // PC control
    output reg       jump,      // Assert to select the jump target PC
    output reg       beq,       // Assert to enable branch-on-equal
    output reg       bne,       // Assert to enable branch-on-not-equal

    // Memory control
    output reg       mem_read,  // Assert to enable data memory read output
    output reg       mem_write, // Assert to write data memory on posedge clk

    // Datapath multiplexer selects
    output reg       alu_src,   // 0 = RS2 register value; 1 = sign-extended immediate
    output reg       reg_dst,   // 0 = instr[8:6] (I-type WS); 1 = instr[5:3] (R-type WS)
    output reg       mem_to_reg,// 0 = ALU result; 1 = data memory read data (for LD)
    output reg       reg_write  // Assert to write the register file on posedge clk
);

    // -------------------------------------------------------------------------
    // Control signal truth table (Extended for FPC-16):
    //
    // Opcode | Instr     | RegDst | ALUSrc | MemToReg | RegWrite | MemRd | MemWr | Branch | ALUOp | Jump
    // -------+-----------+--------+--------+----------+----------+-------+-------+--------+-------+-----
    // 0000   | LD        |   0    |   1    |    1     |    1     |   1   |   0   |   0    |  10   |  0
    // 0001   | ST        |   0    |   1    |    0     |    0     |   0   |   1   |   0    |  10   |  0
    // 0010–  | R-type    |   1    |   0    |    0     |    1     |   0   |   0   |   0    |  00   |  0
    // 1001   | (ADD–SLT) |        |        |          |          |       |       |        |       |
    // 1010   | Reserved  |   0    |   0    |    0     |    0     |   0   |   0   |   0    |  00   |  0
    // 1011   | BEQ       |   0    |   0    |    0     |    0     |   0   |   0   |   1    |  01   |  0
    // 1100   | BNE       |   0    |   0    |    0     |    0     |   0   |   0   |   1    |  01   |  0
    // 1101   | JMP       |   0    |   0    |    0     |    0     |   0   |   0   |   0    |  00   |  1
    // 1110   | FPMUL     |   1    |   0    |    0     |    1     |   0   |   0   |   0    |  00   |  0  <- NEW
    // 1111   | FPDIV     |   1    |   0    |    0     |    1     |   0   |   0   |   0    |  00   |  0  <- NEW
    // -------------------------------------------------------------------------

    always @(*) begin
        // Safe defaults: no writes, no branches, no jumps
        reg_dst   = 1'b0;
        alu_src   = 1'b0;
        mem_to_reg= 1'b0;
        reg_write = 1'b0;
        mem_read  = 1'b0;
        mem_write = 1'b0;
        beq       = 1'b0;
        bne       = 1'b0;
        alu_op    = 2'b00;
        jump      = 1'b0;

        case (opcode)
            4'b0000: begin  // LD
                reg_dst   = 1'b0;
                alu_src   = 1'b1;
                mem_to_reg= 1'b1;
                reg_write = 1'b1;
                mem_read  = 1'b1;
                alu_op    = 2'b10;
            end

            4'b0001: begin  // ST
                alu_src   = 1'b1;
                mem_write = 1'b1;
                alu_op    = 2'b10;
            end

            // R-type instructions — identical control signals
            4'b0010, 4'b0011, 4'b0100, 4'b0101,
            4'b0110, 4'b0111, 4'b1000, 4'b1001: begin
                reg_dst   = 1'b1;
                reg_write = 1'b1;
                alu_op    = 2'b00;
            end

            4'b1010: begin  // Reserved — NOP, no side-effects
            end

            4'b1011: begin  // BEQ
                beq    = 1'b1;
                alu_op = 2'b01;
            end

            4'b1100: begin  // BNE
                bne    = 1'b1;
                alu_op = 2'b01;
            end

            4'b1101: begin  // JMP
                jump = 1'b1;
            end

            // -----------------------------------------------------------------
            // FPC-16 New Fixed-Point Instructions
            // FPMUL and FPDIV use identical R-type control signals:
            // - RegDst=1: destination register encoded in instr[5:3]
            // - ALUSrc=0: both operands come from register file
            // - RegWrite=1: result written back to destination register
            // - ALUOp=00: ALU_Control decodes operation from opcode field
            // No memory access required for either instruction.
            // -----------------------------------------------------------------
            4'b1110: begin  // FPMUL — Q8.8 fixed-point multiply
                reg_dst   = 1'b1;
                reg_write = 1'b1;
                alu_op    = 2'b00;
            end

            4'b1111: begin  // FPDIV — Q8.8 fixed-point divide
                reg_dst   = 1'b1;
                reg_write = 1'b1;
                alu_op    = 2'b00;
            end

            default: begin
                // All signals remain at safe defaults
            end
        endcase
    end

endmodule

