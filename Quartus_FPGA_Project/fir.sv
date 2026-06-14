/////////////////////////////////////////////////////////////////////
// Design unit: fir
// File name  : fir.sv
// Description: FIR 16 stages; 16 bit samples.
// System     : SystemVerilog IEEE 1800-2005

/////////////////////////////////////////////////////////////////////

module fir (input logic signed [15:0] in,
       input logic input_ready, ck, rst,
       output logic signed [15:0] out,
       output logic output_ready);

typedef logic signed [15:0] sample_array;
sample_array samples [0:15];

const sample_array coefficients [0:15] =
    '{30,136,457,1119,2116,3278,4317,4932,4932,4317,3278,2116,1119,457,136,30};

logic unsigned [3:0] address;
logic signed [31:0] sum;

typedef enum logic [1:0] {waiting, loading, processing, saving} state_type;
state_type state, next_state;
logic load, count, reset_accumulator;

// 1. Shift Register
always_ff @(posedge ck, posedge rst)
  if (rst) begin
    for (int i=0; i<=15; i++) samples[i] <= '0;
  end
  else if (load) begin
    for (int i=15; i >= 1; i--)
      samples[i] <= samples[i-1];
    samples[0] <= in;
  end

// 2. Accumulator
always_ff @(posedge ck, posedge rst)
begin
  if (rst)
    sum <= '0;
  else if (reset_accumulator)
    sum <= '0;
  else
    sum <= sum + samples[address] * coefficients[address];
end

// 3. Output Register
always_ff @(posedge ck, posedge rst)
  if (rst)
    out <= '0;
  else if (output_ready)
    out <= sum[30:15];

// 4. Address Counter
always_ff @(posedge ck, posedge rst)
begin
  if (rst)
     address <= '0;
  else if (state == waiting)
     address <= '0;
  else if (count)
     address <= address + 1;
end

// 5. State Register
always_ff @(posedge ck, posedge rst)
  if (rst) state <= waiting;
  else state <= next_state;

// 6. Controller Logic
always_comb
begin
    load = 1'b0;
    count = 1'b0;
    reset_accumulator = 1'b0;
    output_ready = 1'b0;
    next_state = state;

    case (state)
        waiting: begin
            reset_accumulator = 1'b1;
            if (input_ready) begin
                next_state = loading;
                load = 1'b1;         // 
            end
        end

        loading: begin
            reset_accumulator = 1'b1;
            load = 1'b0;             //
            next_state = processing;
        end

        processing: begin
            count = 1'b1;
            if (address == 15)
                next_state = saving;
        end

        saving: begin
            output_ready = 1'b1;
            next_state = waiting;
        end
    endcase
end

endmodule