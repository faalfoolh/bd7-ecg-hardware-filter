module D1 (input logic CLOCK_50, CLOCK2_50, input logic [0:0] KEY,
	       // I2C Audio/Video config interface 
           output logic FPGA_I2C_SCLK, inout wire FPGA_I2C_SDAT, 
           // Audio CODEC
           output logic AUD_XCK, 
		   input logic AUD_DACLRCK, AUD_ADCLRCK, AUD_BCLK, AUD_ADCDAT, 
		   output logic AUD_DACDAT);
	
	// Local wires.
	wire read_ready, write_ready, read, write;
	wire [23:0] readdata_left, readdata_right;
	wire [23:0] writedata_left, writedata_right;
	wire reset = ~KEY[0];
/////////////////////////////////
// FIR FILTER INSTANTIATION
/////////////////////////////////

    // 1. Define wires to catch the output of the filter
    logic signed [15:0] fir_out_left;
    logic fir_done;

    // 2. Instantiate your FIR Filter
    // CORRECTED: Connecting to internal wires and selecting High Bits
    fir_3 #(.WIDTH(16), .TAPS(17)) MyFilter (
        .ck(CLOCK_50),
        .rst(reset),
        .in(readdata_left[23:8]),   // <--- FIXED: Grab top 16 audio bits
        .input_ready(read_ready),
        .out(fir_out_left),         // <--- FIXED: Output to internal wire
        .output_ready(fir_done)     // <--- FIXED: Output to internal wire
    );

    // 3. Connect the output to the speakers
    // We take the 16-bit filter result and add 8 zeros to make it 24-bit again
    assign writedata_left = {fir_out_left, 8'b0};
    
    // 4. Pass the Right Channel through untouched
    assign writedata_right = readdata_right;

    // 5. Control Signals
    assign read = read_ready;
    assign write = fir_done && write_ready; // Write when Filter is done AND Codec is ready
	
/////////////////////////////////////////////////////////////////////////////////
// Audio CODEC interface. 
//
// The interface consists of the following wires:
// read_ready, write_ready - CODEC ready for read/write operation 
// readdata_left, readdata_right - left and right channel data from the CODEC
// read - send data from the CODEC (both channels)
// writedata_left, writedata_right - left and right channel data to the CODEC
// write - send data to the CODEC (both channels)
// AUD_* - should connect to top-level entity I/O of the same name.
//         These signals go directly to the Audio CODEC
// I2C_* - should connect to top-level entity I/O of the same name.
//         These signals go directly to the Audio/Video Config module
/////////////////////////////////////////////////////////////////////////////////
	clock_generator my_clock_gen(
		// inputs
		CLOCK2_50,
		reset,

		// outputs
		AUD_XCK
	);

	audio_and_video_config cfg(
		// Inputs
		CLOCK_50,
		reset,

		// Bidirectionals
		FPGA_I2C_SDAT,
		FPGA_I2C_SCLK
	);

	audio_codec codec(
		// Inputs
		CLOCK_50,
		reset,

		read,	write,
		writedata_left, writedata_right,

		AUD_ADCDAT,

		// Bidirectionals
		AUD_BCLK,
		AUD_ADCLRCK,
		AUD_DACLRCK,

		// Outputs
		read_ready, write_ready,
		readdata_left, readdata_right,
		AUD_DACDAT
	);

endmodule


