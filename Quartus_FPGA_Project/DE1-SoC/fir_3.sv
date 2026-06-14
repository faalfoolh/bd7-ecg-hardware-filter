/////////////////////////////////////////////////////////////////////
// Design unit: fir_3
// Description: Extended Work "Final Boss"
//              - Parameterized Bit Width & Taps
//              - High-Pass Coefficients
//              - SATURATION ARITHMETIC (Prevents audio popping)
// Author     : Adi
/////////////////////////////////////////////////////////////////////

module fir_3 #(
    parameter WIDTH = 16,     
    parameter TAPS  = 17      
)(
    input  logic signed [WIDTH-1:0] in,
    input  logic input_ready, ck, rst,
    output logic signed [WIDTH-1:0] out,
    output logic output_ready
);

    // --- 1. SETUP & COEFFICIENTS ---
    typedef logic signed [WIDTH-1:0] sample_array;
    sample_array samples [0:TAPS-1];

    // High-Pass Coefficients (Symmetric)
    // If you change TAPS, you must update this list manually!
    localparam logic signed [WIDTH-1:0] coefficients [0:TAPS-1] = '{
        -466, -429, -485, -668, -943, -1257, -1531, -1693, 
        29013, 
        -1693, -1531, -1257, -943, -668, -485, -429, -466
    };

    logic unsigned [$clog2(TAPS)-1:0] address; 
    
    // Accumulator: Width + Width + Headroom for adding TAPS
    localparam ACC_WIDTH = (2*WIDTH) + $clog2(TAPS);
    logic signed [ACC_WIDTH-1:0] sum; 

    // State Machine
    typedef enum logic [1:0] {waiting, loading, processing, saving} state_type;
    state_type state, next_state;
    logic load, count, reset_accumulator;

    // --- 2. DATAPATH ---

    // Shift Register
    always_ff @(posedge ck, posedge rst)
        if (rst) begin
            for (int i=0; i < TAPS; i++) samples[i] <= '0;
        end
        else if (load) begin
            for (int i=TAPS-1; i >= 1; i--)
                samples[i] <= samples[i-1];
            samples[0] <= in;
        end

    // Accumulator
    always_ff @(posedge ck, posedge rst)
        if (rst)
            sum <= '0;
        else if (reset_accumulator)
            sum <= '0;
        else
            sum <= sum + (samples[address] * coefficients[address]);

    // --- 3. SATURATION LOGIC (The Enhancement) ---
    // We want to grab the middle bits (Q15 result)
    localparam DROP_BITS = 15;
    
    // The value we *want* to output (Truncated)
    logic signed [WIDTH-1:0] truncated_val;
    assign truncated_val = sum[WIDTH+DROP_BITS-1 : DROP_BITS];

    // Overflow Detection
    logic overflow_pos, overflow_neg;
    
    always_comb begin
        // If Sum is huge positive, upper bits (that we drop) are not all 0
        if (sum > (2**(WIDTH+DROP_BITS-1) - 1)) 
            overflow_pos = 1'b1;
        else 
            overflow_pos = 1'b0;

        // If Sum is huge negative, upper bits (that we drop) are not all 1
        if (sum < -(2**(WIDTH+DROP_BITS-1))) 
            overflow_neg = 1'b1;
        else 
            overflow_neg = 1'b0;
    end

    // Output Register with Clamping
    always_ff @(posedge ck, posedge rst)
        if (rst)
            out <= '0;
        else if (output_ready) begin
            if (overflow_pos) 
                out <= {1'b0, {(WIDTH-1){1'b1}}}; // Clamp to MAX POSITIVE
            else if (overflow_neg) 
                out <= {1'b1, {(WIDTH-1){1'b0}}}; // Clamp to MAX NEGATIVE
            else 
                out <= truncated_val;             // Normal Clean Audio
        end

    // Counter
    always_ff @(posedge ck, posedge rst)
        if (rst) address <= '0;
        else if (state == waiting) address <= '0;
        else if (count) address <= address + 1;

    // State Register
    always_ff @(posedge ck, posedge rst)
        if (rst) state <= waiting;
        else state <= next_state;

    // --- 4. CONTROLLER ---
    always_comb begin
        load = 1'b0; count = 1'b0; reset_accumulator = 1'b0;
        output_ready = 1'b0; next_state = state;

        case (state)
            waiting: begin
                reset_accumulator = 1'b1;
                // Immediate Load Logic (The Fix)
                if (input_ready) begin
                    next_state = loading;
                    load = 1'b1;
                end
            end
            loading: begin
                reset_accumulator = 1'b1;
                load = 1'b0;
                next_state = processing;
            end
            processing: begin
                count = 1'b1;
                if (address == TAPS-1)
                    next_state = saving;
            end
            saving: begin
                output_ready = 1'b1;
                next_state = waiting;
            end
        endcase
    end

endmodule