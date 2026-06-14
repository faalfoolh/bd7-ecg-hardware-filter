/////////////////////////////////////////////////////////////////////
// Design unit: fir_2
// Description: Extended work. Parameterized FIR with High Pass coeffs.
// Author     : Adi
/////////////////////////////////////////////////////////////////////

module fir_2 #(
    parameter WIDTH = 16,     // width of data
    parameter TAPS  = 17      // number of taps (must be odd for high pass)
)(
    input  logic signed [WIDTH-1:0] in,
    input  logic input_ready, ck, rst,
    output logic signed [WIDTH-1:0] out,
    output logic output_ready
);

    // arrays for data
    typedef logic signed [WIDTH-1:0] sample_array;
    sample_array samples [0:TAPS-1];

    // High pass coefficients generated from Matlab
    // round(fir1(16, 0.125, 'high') * 32768)
    // IMPORTANT: If TAPS changes, these need to be updated manually
    localparam logic signed [WIDTH-1:0] coefficients [0:TAPS-1] = '{
        -466, -429, -485, -668, -943, -1257, -1531, -1693, 
        29013, 
        -1693, -1531, -1257, -943, -668, -485, -429, -466
    };

    // figure out how many bits we need for the address
    logic unsigned [$clog2(TAPS)-1:0] address; 
    
    // accumulator needs extra bits to prevent overflow
    // formula is roughly 2*width + log2(taps)
    logic signed [(2*WIDTH)+$clog2(TAPS)-1:0] sum; 

    // state machine stuff
    typedef enum logic [1:0] {waiting, loading, processing, saving} state_type;
    state_type state, next_state;
    logic load, count, reset_accumulator;

    // --- Datapath Logic ---

    // Shift Register to hold samples
    always_ff @(posedge ck, posedge rst)
        if (rst) begin
            // clear everything on reset
            for (int i=0; i < TAPS; i++) samples[i] <= '0;
        end
        else if (load) begin
            // shift old values down
            for (int i=TAPS-1; i >= 1; i--)
                samples[i] <= samples[i-1];
            // put new value at start
            samples[0] <= in;
        end

    // The Accumulator (does the math)
    always_ff @(posedge ck, posedge rst)
        if (rst)
            sum <= '0;
        else if (reset_accumulator)
            sum <= '0;
        else
            // do the multiply and accumulate
            sum <= sum + (samples[address] * coefficients[address]);

    // Output register
    always_ff @(posedge ck, posedge rst)
        if (rst)
            out <= '0;
        else if (output_ready)
            // grab the middle bits (dropping the fractional part)
            out <= sum[WIDTH+14 : 15]; 

    // Counter for the coefficients
    always_ff @(posedge ck, posedge rst)
        if (rst)
            address <= '0;
        else if (state == waiting)
            address <= '0;
        else if (count)
            address <= address + 1;

    // State register update
    always_ff @(posedge ck, posedge rst)
        if (rst) state <= waiting;
        else state <= next_state;

    // --- Controller Logic ---
    always_comb begin
        // defaults
        load = 1'b0;
        count = 1'b0;
        reset_accumulator = 1'b0;
        output_ready = 1'b0;
        next_state = state;

        case (state)
            waiting: begin
                reset_accumulator = 1'b1;
                // if data is ready, grab it immediately 
                if (input_ready) begin
                    next_state = loading;
                    load = 1'b1;
                end
            end

            loading: begin
                reset_accumulator = 1'b1;
                load = 1'b0; // stop loading
                next_state = processing;
            end

            processing: begin
                count = 1'b1;
                // keep going until we hit the last tap
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