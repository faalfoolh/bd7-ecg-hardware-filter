// ============================================================
// FIR Filter Top Level - D7 Healthcare Technology Project
// ============================================================
// Connects switches as input and LEDs as output for demo
// SW[9:0]  → FiltIn (switch values as test input)
// LED[9:0] → FiltOut (filtered output shown on LEDs)
// KEY0 (nRst) → press to reset the filter
// ============================================================

module FIR_Top (
    input  logic        Clk,    // 50 MHz clock - PIN_AF14
    input  logic        nRst,   // KEY0 reset   - PIN_AA14
    input  logic [9:0]  SW,     // Switches     - input signal
    output logic [9:0]  LED     // Red LEDs     - output signal
);

    logic signed [15:0] FiltIn;
    logic signed [15:0] FiltOut;

    // Sign extend 10-bit switch input to 16-bit signed
    assign FiltIn = {{6{SW[9]}}, SW};

    // Show upper 10 bits of filter output on LEDs
    assign LED = FiltOut[15:6];

    // Instantiate FIR filter
    FIR inst_FIR (
        .FiltOut (FiltOut),
        .FiltIn  (FiltIn),
        .Clk     (Clk),
        .nRst    (nRst)
    );

endmodule
