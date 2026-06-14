// ============================================================
// FIR Bandpass Filter - D7 Healthcare Technology Project
// ============================================================
// Purpose : Removes baseline wandering (below 0.5 Hz)
//           and high frequency noise (above 40 Hz) from ECG
// Filter  : FIR, Order 40 (41 taps)
// Method  : Windowed sinc, coefficients designed in MATLAB
// Sampling: 1 KHz
// ============================================================

module FIR #(parameter DATAWIDTH     = 16,   // width of input/output samples
                       ORDER         = 41,   // number of filter taps
                       COEFFDATAWIDTH = 8)   // width of each coefficient
            (output logic signed [DATAWIDTH-1:0] FiltOut,
             input  logic signed [DATAWIDTH-1:0] FiltIn,
             input  logic Clk, nRst
            );

    // ----------------------------------------------------------
    // BLOCK 1: Coefficient storage
    // These values come from MATLAB (scaled x1024 for integers)
    // They define which frequencies pass through and which are blocked
    // ----------------------------------------------------------
    logic signed [COEFFDATAWIDTH-1:0] Coefficients [0:ORDER-1];

    always_comb begin
        Coefficients[0]  = -1;  Coefficients[1]  = -2;  Coefficients[2]  = -2;
        Coefficients[3]  = -2;  Coefficients[4]  = -3;  Coefficients[5]  = -3;
        Coefficients[6]  = -3;  Coefficients[7]  = -1;  Coefficients[8]  =  1;
        Coefficients[9]  =  5;  Coefficients[10] = 10;  Coefficients[11] = 16;
        Coefficients[12] = 24;  Coefficients[13] = 33;  Coefficients[14] = 43;
        Coefficients[15] = 53;  Coefficients[16] = 62;  Coefficients[17] = 70;
        Coefficients[18] = 76;  Coefficients[19] = 80;  Coefficients[20] = 81;
        Coefficients[21] = 80;  Coefficients[22] = 76;  Coefficients[23] = 70;
        Coefficients[24] = 62;  Coefficients[25] = 53;  Coefficients[26] = 43;
        Coefficients[27] = 33;  Coefficients[28] = 24;  Coefficients[29] = 16;
        Coefficients[30] = 10;  Coefficients[31] =  5;  Coefficients[32] =  1;
        Coefficients[33] = -1;  Coefficients[34] = -3;  Coefficients[35] = -3;
        Coefficients[36] = -3;  Coefficients[37] = -2;  Coefficients[38] = -2;
        Coefficients[39] = -2;  Coefficients[40] = -1;
    end

    // ----------------------------------------------------------
    // BLOCK 2: Delay line (shift register / conveyor belt)
    // Stores the last 41 input ECG samples
    // On every clock tick, samples shift along by one position
    // ----------------------------------------------------------
    logic signed [DATAWIDTH-1:0] Taps [0:ORDER-1];

    always_ff @(posedge Clk, negedge nRst) begin
        if (!nRst) begin
            // Reset: clear all stored samples
            for (int i = 0; i < ORDER; i++)
                Taps[i] <= '0;
        end else begin
            // Shift: new sample goes in at Tap[0]
            // all others move one position along
            Taps[0] <= FiltIn;
            for (int i = 1; i < ORDER; i++)
                Taps[i] <= Taps[i-1];
        end
    end

    // ----------------------------------------------------------
    // BLOCK 3: Multiply each tap by its coefficient
    // Each product is stored separately before summing
    // Note: For lower power, this can be replaced with
    //       shift-and-add (no hardware multiplier needed)
    // ----------------------------------------------------------
    logic signed [DATAWIDTH+COEFFDATAWIDTH-1:0] Products [0:ORDER-1];

    always_comb begin
        for (int j = 0; j < ORDER; j++)
            Products[j] = Taps[j] * Coefficients[j];
    end

    // ----------------------------------------------------------
    // BLOCK 4: Accumulate - add all products together
    // ----------------------------------------------------------
    logic signed [31:0] Sum;

    always_comb begin
        Sum = 32'(signed'(Products[0]));
        for (int k = 1; k < ORDER; k++)
            Sum = Sum + 32'(signed'(Products[k]));
    end

    // ----------------------------------------------------------
    // OUTPUT: Divide by 1024 (undo the x1024 scaling from MATLAB)
    // Arithmetic right shift by 10 = divide by 2^10 = divide by 1024
    // ----------------------------------------------------------
    assign FiltOut = 16'(Sum >>> 10);

endmodule
