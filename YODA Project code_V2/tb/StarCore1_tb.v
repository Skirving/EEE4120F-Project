// =============================================================================
// EEE4120F Practical 4 — StarCore-1 Processor
// File        : StarCore1_tb.v
// Description : Integration testbench for the full StarCore-1 processor (Task 8).
//               Runs the program stored in test.prog and verifies processor
//               behaviour over multiple clock cycles using hierarchical signal
//               references.
//
//               This testbench does NOT drive the processor's datapath signals
//               directly — it only drives the clock and observes internal state
//               via hierarchical references.
//
// *** IMPORTANT — Expected compile behaviour with the skeleton ***
// When you first compile this testbench against the skeleton source files,
// iverilog will report "Unable to bind wire/reg/memory" errors for every
// hierarchical reference below (uut.DU.pc_current, uut.DU.instr, etc.).
// This is EXPECTED. Those signals do not yet exist because the Datapath
// module body is empty. The errors will disappear once you implement the
// internal signal declarations and sub-module instantiations in Datapath.v
// and StarCore1.v as required by Tasks 7 and 8.
//
// Hierarchical signal reference examples (valid after implementation):
//   uut.DU.pc_current              — Program Counter (reg in Datapath)
//   uut.DU.instr                   — Currently fetched instruction word (wire)
//   uut.DU.alu_result              — ALU output (wire)
//   uut.DU.zero_flag               — ALU zero flag (wire)
//   uut.DU.reg_file.reg_array[N]   — Register RN value (inside GPR instance)
//   uut.DU.dm.memory[N]            — Data memory word N (inside DataMemory instance)
//   uut.CU.reg_write               — ControlUnit reg_write output
//   uut.CU.alu_op                  — ControlUnit alu_op output
//
// The instance names used here (DU for Datapath, CU for ControlUnit, reg_file
// for GPR, dm for DataMemory) MUST match the names you use when instantiating
// those modules in StarCore1.v and Datapath.v respectively.
//
//I/O port test, instructions add to test.prog
//0000000100001000: LD R4 ← mem[R0+8] = 0x00FE
//0000100101000000: LD R5 ← mem[R4+0] = io_in
//0000000110001001: LD R6 ← mem[R0+9] = 0x00FF
//0001110101000000: ST R5 → mem[R6+0] = io_out


// Run:
//   iverilog -Wall -I ../src -o ../build/star_sim \
//       ../src/Parameter.v ../src/ALU.v ../src/GPR.v \
//       ../src/InstructionMemory.v ../src/DataMemory.v \
//       ../src/ALU_Control.v ../src/ControlUnit.v \
//       ../src/Datapath.v ../src/StarCore1.v StarCore1_tb.v
//   cd ../test && ../build/star_sim
//   gtkwave ../waves/star.vcd &
// =============================================================================

`timescale 1ns / 1ps
`include "../src/Parameter.v"

module StarCore1_tb;

    // -------------------------------------------------------------------------
    // Clock
    // -------------------------------------------------------------------------
    reg clk;
    initial clk = 1'b0;
    always  #5 clk = ~clk;     // 10 ns period — 100 MHz

    // -------------------------------------------------------------------------
    // DUT instantiation
    // -------------------------------------------------------------------------
    // FPC-16: I/O ports connected for memory-mapped I/O skeleton
    reg [15:0] io_in;
    initial io_in = 16'd0;  
    wire [15:0] io_out;              // observe output port
    wire        io_write;            // observe write strobe

    StarCore1 uut (
        .clk      (clk),
        .io_in    (io_in),
        .io_out   (io_out),
        .io_write (io_write)
    );

    // -------------------------------------------------------------------------
    // Waveform dump — captures ALL signals in the design hierarchy
    // -------------------------------------------------------------------------
    initial begin
        $dumpfile("../waves/star.vcd");
        $dumpvars(0, StarCore1_tb);
    end

    // -------------------------------------------------------------------------
    // Failure counter
    // -------------------------------------------------------------------------
    integer fail_count;
    integer test_id;

    initial begin
        fail_count = 0;
        test_id    = 1;
    end

    // -------------------------------------------------------------------------
    // Check tasks — compare 16-bit values observed via hierarchical reference
    // -------------------------------------------------------------------------
    task check16;
        input [15:0] got;
        input [15:0] expected;
        input [63:0] id;
        begin
            if (got !== expected) begin
                $display("FAIL [T%0d]: got = 0x%h (%0d), expected = 0x%h (%0d)",
                         id, got, got, expected, expected);
                fail_count = fail_count + 1;
            end else
                $display("PASS [T%0d]: value = 0x%h (%0d)", id, got, got);
        end
    endtask

    // -------------------------------------------------------------------------
    // Cycle-by-cycle execution trace
    // This always block fires on every rising clock edge and prints the current
    // processor state. It is your primary debugging tool.
    //
    // TODO: Uncomment this block once Datapath.v is fully implemented.
    //       Until then, it will cause "Unable to bind" errors because the
    //       internal signals (pc_current, instr, etc.) do not yet exist.
    // -------------------------------------------------------------------------
       always @(posedge clk) begin
           $display("%0t ns | PC=0x%h | instr=%b | R0=%3d R1=%3d R2=%3d R3=%3d | alu=%0d z=%b",
               $time,
               uut.DU.pc_current,
               uut.DU.instr,
               uut.DU.reg_file.reg_array[0],
               uut.DU.reg_file.reg_array[1],
               uut.DU.reg_file.reg_array[2],
               uut.DU.reg_file.reg_array[3],
               uut.DU.alu_result,
               uut.DU.zero_flag
          );
       end
    
    
       
    // =========================================================================
    // MAIN STIMULUS BLOCK
    // =========================================================================
    initial begin


        $display("=== StarCore-1 Integration Testbench ===");
        $display("=== Program loaded from ./test/test.prog ===");
        $display("=== Data memory loaded from ./test/test.data ===");
        $display("");
       
        io_in = 16'h0280; //input to the input wire

        #1; //delay for clock 

       //debugginglines (ignore)
       // $display("DEBUG im[0]=%b", uut.DU.im.memory[0]);
      //  $display("DEBUG im[12]=%b", uut.DU.im.memory[12]);
       // $display("DEBUG dm[0]=%b", uut.DU.dm.memory[0]);
        //$display("DEBUG dm[8]=%b", uut.DU.dm.memory[8]);
        // -----------------------------------------------------------------------
        // Wait for the simulation to run long enough for your program to
        // complete at least one full pass. Adjust SIM_TIME in Parameter.v
        // if your program needs more cycles.
        // -----------------------------------------------------------------------
        `SIM_TIME;

        #10  //delay for clock edge write to output

        //debugging (ignore)
        $display("--- Debug: PC and IO trace ---");
        // If DUT exposes PC:
        $display("Final PC     = %0d", uut.DU.pc_current);
        // Trace when io_write fires
        $monitor("[t=%0t] io_write=%b io_out=0x%h", $time, io_write, io_out);

        //check what is in the io ports 
        $display("--- I/O Port Verification ---");
        $display("io_in   = 0x%h", io_in);
        $display("io_out  = 0x%h", io_out);
        $display("io_write asserted = %b", io_write);

        // -------------------------------------------------------------------------
        // I/O port test
        //-------------------------------------------------------------------------

        check16(io_out, 16'h0280, test_id);
        test_id = test_id + 1;
        // -----------------------------------------------------------------------
        // POST-SIMULATION VERIFICATION
        //
        // TODO: After implementing Datapath.v and StarCore1.v, uncomment the
        //       check16() calls below and fill in the expected values for your
        //       specific test program.
        //
        //       All hierarchical references below (uut.DU.*, uut.DU.reg_file.*,
        //       uut.DU.dm.*) are commented out because they reference signals
        //       that do not exist until the Datapath is implemented.
        //       Uncomment them one section at a time as you complete each task.
        // -----------------------------------------------------------------------

        $display("");
        $display("--- Post-Simulation Verification (implement Datapath first) ---");

        // -----------------------------------------------------------------------
        // STEP 1: Verify register values after execution.
        // Uncomment and fill in expected values after implementing Datapath.v.
        // -----------------------------------------------------------------------
            $display("Checking R0 after LD (expect 0x0001):");
            check16(uut.DU.reg_file.reg_array[0], 16'h0001, test_id);
            test_id = test_id + 1;

            $display("Checking R1 after LD (expect 0x0002):");
            check16(uut.DU.reg_file.reg_array[1], 16'h0002, test_id);
            test_id = test_id + 1;

            $display("Checking R2 after FPDIV (expect 0x0001):");
            check16(uut.DU.reg_file.reg_array[2], 16'h0001, test_id);
            test_id = test_id + 1;

            $display("Checking DataMem[2] after ST (expect 0x0003) :");
            check16(uut.DU.dm.memory[2], 16'h0003, test_id);
            test_id = test_id + 1;

        // -----------------------------------------------------------------------
        // STEP 2: Verify data memory after ST instruction.
        // The example program stores R2 to Mem[R1+0] = Mem[2] (address offset 0).
        // Uncomment after implementing Datapath.v.
        // -----------------------------------------------------------------------
        // $display("Checking DataMem[2] after ST R2 -> Mem[R1+0]:");
        // check16(uut.DU.dm.memory[2], 16'h0003, test_id);
        // test_id = test_id + 1;

        // -----------------------------------------------------------------------
        // STEP 3: Verify additional R-type instruction results.
        // After SUB R2,R0,R1: R2 = 0x0001 - 0x0002 = 0xFFFF (wrap-around)
        // NOTE: SUB happens AFTER ST in the example program so R2 changes.
        // Adjust expected values to match the state at end of SIM_TIME.
        // -----------------------------------------------------------------------
        // $display("Add your R-type verification checks here...");

        // -----------------------------------------------------------------------
        // STEP 4: Add your own checks for AND, OR, SLT, branch, jump effects.
        // -----------------------------------------------------------------------

        // -----------------------------------------------------------------------
        // Print register and memory state (safe to uncomment after Task 7)
        // -----------------------------------------------------------------------
           $display("");
           $display("--- Final Register File State ---");
           $display("R0=0x%h  R1=0x%h  R2=0x%h  R3=0x%h",
               uut.DU.reg_file.reg_array[0], uut.DU.reg_file.reg_array[1],
               uut.DU.reg_file.reg_array[2], uut.DU.reg_file.reg_array[3]);
           $display("R4=0x%h  R5=0x%h  R6=0x%h  R7=0x%h",
               uut.DU.reg_file.reg_array[4], uut.DU.reg_file.reg_array[5],
               uut.DU.reg_file.reg_array[6], uut.DU.reg_file.reg_array[7]);
        
           $display("");
           $display("--- Final Data Memory State ---");
           $display("Mem[0]=0x%h  Mem[1]=0x%h  Mem[2]=0x%h  Mem[3]=0x%h",
               uut.DU.dm.memory[0], uut.DU.dm.memory[1],
               uut.DU.dm.memory[2], uut.DU.dm.memory[3]);
           $display("Mem[4]=0x%h  Mem[5]=0x%h  Mem[6]=0x%h  Mem[7]=0x%h",
               uut.DU.dm.memory[4], uut.DU.dm.memory[5],
               uut.DU.dm.memory[6], uut.DU.dm.memory[7]);

            $display("");
        if (fail_count == 0)
            $display("=== ALL %0d INTEGRATION TESTS PASSED ===", test_id - 1);
        else
            $display("=== %0d / %0d INTEGRATION TESTS FAILED ===", fail_count, test_id - 1);
        

        // debugging (ignore)
        $display("--- PC Trace ---");
        $display("Current PC = %0d", uut.DU.pc_current);
        $display("IR (last instr) = %b", uut.DU.instr);
        $finish;
    end

    //ensures that io reads and write are happening at the right trigger
    always @(posedge clk) begin
    $display("[%0t] PC=%0d IR=%b mem_write=%b alu_result=0x%h",
              $time, uut.DU.pc_current, uut.DU.instr, uut.CU.reg_write, uut.DU.alu_result);
    end

        

endmodule
