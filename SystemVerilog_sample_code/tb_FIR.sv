// ============================================================
// Testbench for FIR Filter - D7 Healthcare Technology Project
// ============================================================
// Purpose : Feeds ECG samples into the FIR filter
//           and saves the output to a file
// Validate: Compare OutputSignal.txt with MATLAB output
// ============================================================

`timescale 1ns/100ps

`define PERIOD         10    // clock period in ns (= 100 MHz clock)
`define DATAWIDTH      16    // must match FIR.sv
`define ORDER          41    // must match FIR.sv
`define COEFFDATAWIDTH  8    // must match FIR.sv

module tb_FIR;

    // File handles
    int ptrFileWrite;
    int ptrFileRead;

    // Signals connected to the FIR filter
    logic signed [`DATAWIDTH-1:0] FiltOut;
    logic signed [`DATAWIDTH-1:0] FiltIn;
    logic Clk, nRst;

    // ----------------------------------------------------------
    // Instantiate the FIR filter
    // ----------------------------------------------------------
    FIR #(.DATAWIDTH(`DATAWIDTH),
          .ORDER(`ORDER),
          .COEFFDATAWIDTH(`COEFFDATAWIDTH))
    inst_FIR (.*);

    // ----------------------------------------------------------
    // Clock generation: toggles every half period
    // ----------------------------------------------------------
    initial begin
        Clk = '0;
        forever #(`PERIOD/2) Clk = ~Clk;
    end

    // ----------------------------------------------------------
    // Save output to file on every rising clock edge
    // ----------------------------------------------------------
    always @(posedge Clk) begin
        $fwrite(ptrFileWrite, "%d\n", FiltOut);
    end

    // ----------------------------------------------------------
    // Main test: read ECG input, feed into filter, save output
    // ----------------------------------------------------------
    initial begin
        // Open files
        ptrFileWrite = $fopen("OutputSignal.txt", "w");
        ptrFileRead  = $fopen("InputSignal.txt",  "r");

        // Apply reset
        nRst   = 1'b0;
        FiltIn = '0;
        #1;
        nRst   = 1'b1;

        // Feed ECG samples one by one into the filter
        while (!$feof(ptrFileRead)) begin
            void'($fscanf(ptrFileRead, "%d", FiltIn));
            @(negedge Clk);
        end

        // Send extra zeros to flush the last samples through the delay line
        FiltIn = '0;
        for (int i = 0; i < `ORDER; i++) @(negedge Clk);

        // Done
        $display("Simulation complete - check OutputSignal.txt");
        $fclose(ptrFileWrite);
        $fclose(ptrFileRead);
        $stop;
    end

endmodule
