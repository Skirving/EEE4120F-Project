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
// File        : StarCore1.v
// Description : Top-level StarCore-1 processor module — Extended for FPC-16.
//               Connects the Datapath and ControlUnit together.
//               Extended with memory-mapped I/O ports to allow the processor
//               to interact with the outside world.
//
//               Memory-Mapped I/O Map:
//               Address 0x00FE — Input port:  processor reads external data
//               Address 0x00FF — Output port: processor writes results out
//
//               I/O is implemented by monitoring the ALU result (memory
//               address) and mem_write/mem_read control signals:
//               - ST to address 0x00FF: io_out captures the write data
//               - LD from address 0x00FE: io_in is injected as read data
//               This allows standard LD/ST instructions to perform I/O
//               without requiring new opcodes or hardware modifications.
// =============================================================================

`timescale 1ns / 1ps
`include "../src/Parameter.v"

module StarCore1 (
    input        clk,        // System clock

    // -------------------------------------------------------------------------
    // Memory-Mapped I/O Ports — FPC-16 Extension
    // -------------------------------------------------------------------------
    input  [15:0] io_in,     // External input data (mapped to address 0x00FE)
    output [15:0] io_out,    // External output data (mapped to address 0x00FF)
    output        io_write   // Asserted when processor writes to output port

);

    // =========================================================================
    // INTERNAL CONTROL WIRES
    // These signals connect the ControlUnit outputs to the Datapath inputs,
    // and the Datapath opcode output back to the ControlUnit input.
    // =========================================================================
    wire        jump;
    wire        beq;
    wire        bne;
    wire        mem_read;
    wire        mem_write;
    wire        alu_src;
    wire        reg_dst;
    wire        mem_to_reg;
    wire        reg_write;
    wire [1:0]  alu_op;
    wire [3:0]  opcode;

    // =========================================================================
    // MEMORY-MAPPED I/O DECODE
    // Uses hierarchical references to monitor internal Datapath signals:
    // - DU.alu_result: the computed memory address (from ALU)
    // - DU.reg_read_data_2: the data to be written (RS2, used by ST)
    //
    // Output port (0x00FF):
    //   Triggered when ST instruction targets address 0x00FF.
    //   io_write is asserted and io_out_reg captures the write data.
    //
    // Input port (0x00FE):
    //   When LD targets address 0x00FE, io_in provides the read data.
    //   Full input mux integration pending in Datapath.v (planned task).
    // =========================================================================
     

        
    

    // Input port decode — inject io_in when LD reads from address 0x00FE
    wire io_read;
    assign io_read = mem_read && (DU.alu_result == 16'h0008);

    // Output port decode
    assign io_write = mem_write && (DU.alu_result == 16'h0009);

    // Output register — captures data when ST targets 0x00FF
    reg [15:0] io_out_reg;
    initial io_out_reg = 16'd0; 
    assign io_out = io_out_reg;

   

    always @(posedge clk) begin
        if (io_write)
            io_out_reg <= DU.reg_read_data_2; // capture RS2 data on ST
    end

    // =========================================================================
    // DATAPATH INSTANTIATION
    // =========================================================================
    Datapath DU (
        .clk        (clk),
        .jump       (jump),
        .beq        (beq),
        .bne        (bne),
        .mem_read   (mem_read),
        .mem_write  (mem_write),
        .alu_src    (alu_src),
        .reg_dst    (reg_dst),
        .mem_to_reg (mem_to_reg),
        .reg_write  (reg_write),
        .alu_op     (alu_op),
        .opcode     (opcode),
        .io_in      (io_in),       
        .io_read    (io_read) 
    );

    // =========================================================================
    // CONTROL UNIT INSTANTIATION
    // =========================================================================
    ControlUnit CU (
        .opcode     (opcode),
        .alu_op     (alu_op),
        .jump       (jump),
        .beq        (beq),
        .bne        (bne),
        .mem_read   (mem_read),
        .mem_write  (mem_write),
        .alu_src    (alu_src),
        .reg_dst    (reg_dst),
        .mem_to_reg (mem_to_reg),
        .reg_write  (reg_write)
    );

endmodule