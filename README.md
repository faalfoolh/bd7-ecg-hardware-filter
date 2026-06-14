# BD7 — ECG Hardware FIR Filter

**Module:** BIOM2011 & BIOM2012 — Healthcare Technology Design Project (D7)
**University of Southampton** | Dr Ernesto E. Vidal-Rosas

A complete VLSI design chain for a hardware ECG pre-processing filter — from algorithm design in MATLAB through to synthesis on a DE1-SoC FPGA.

## The Problem
ECG signals captured by wearable devices are corrupted by noise and baseline wandering. This project designs a hardware filter to recover clean ECG — implemented in silicon rather than software for power efficiency (targeting 16–18 hour battery life).

## Design Chain

```
MATLAB (Algorithm) → SystemVerilog (RTL) → FPGA (DE1-SoC)
```

### Step 1 — MATLAB (`ECG/ecg_filter.m`)
- Loads 4 real ECG recordings (1 kHz sample rate)
- Designs FIR bandpass filter: **0.5 Hz – 40 Hz** (removes baseline drift and HF noise)
- Method: Windowed sinc with Hamming window, order 40 (41 taps)
- Exports integer coefficients (×1024 scaled) for hardware implementation

### Step 2 — SystemVerilog (`SystemVerilog_sample_code/FIR.sv`)
4-block RTL architecture:
1. **Coefficient ROM** — 41 hardcoded signed values from MATLAB
2. **Delay line** — 41-tap shift register (clocked, async reset)
3. **Multiplier array** — tap × coefficient for each of 41 taps
4. **Accumulator** — sums all products, right-shifts by 10 to undo ×1024 scaling

### Step 3 — FPGA (`FIR_Top.sv`)
- Target: DE1-SoC (50 MHz clock)
- Switches `SW[9:0]` → filter input
- LEDs `LED[9:0]` → filtered output
- Simulation: ModelSim (`run_analog.do`) — shows analog ECG waveforms

## Key Design Choices
- **FIR over IIR** — guaranteed stability, linear phase
- **Integer arithmetic** — no floating point hardware needed
- **Multiplierless potential** — shift-and-add noted as lower-power alternative

## Filter Specs
| Parameter | Value |
|-----------|-------|
| Type | FIR Bandpass |
| Passband | 0.5 Hz – 40 Hz |
| Order | 40 (41 taps) |
| Window | Hamming |
| Sample rate | 1 kHz |
| Target clock | ≥ 10 kHz |

## Run Simulation
```
# In ModelSim transcript:
do run_analog.do
```

## Tech Stack
- MATLAB (filter design)
- SystemVerilog (RTL design)
- ModelSim (functional simulation)
- Intel Quartus (FPGA synthesis)
- DE1-SoC FPGA board
