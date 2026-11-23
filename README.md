# ECG Hardware FIR Filter: MATLAB to FPGA

**Module:** BIOM2011 & BIOM2012 Healthcare Technology Design Project (D7), University of Southampton
**Supervisor:** Prof. Ernesto E. Vidal-Rosas · **Result: full marks**

📄 [Read the IEEE-format report](./ECG_D7_Report.pdf)

ECG from wearable devices is corrupted by high-frequency noise (muscle activity, mains interference) and by low-frequency baseline wander (breathing, electrode movement). This project takes an ECG pre-processing filter through the full hardware design chain, because a dedicated hardware filter uses far less power than running the same maths in software on a microprocessor, which matters for a device that has to last a day on a battery.

## Design chain

```
MATLAB design  →  SystemVerilog RTL  →  ModelSim simulation  →  Quartus synthesis (DE1-SoC)
```

### 1. MATLAB (`ECG/ecg_filter.m`)
- Loads MIT-BIH Arrhythmia Database record 105 (1 kHz) and characterises the noise and baseline wander
- Removes baseline wander by subtracting a 1000-sample moving average
- Designs a **41-tap linear-phase FIR low-pass filter** with a 40 Hz cut-off (windowed sinc)
- Scales the coefficients by 1024 and rounds them to integers for fixed-point hardware

A 41-tap filter at 1 kHz is far too short to realise a 0.5 Hz edge, so the FIR acts as the 40 Hz low-pass stage and the moving average handles the baseline. A single 0.5–40 Hz band-pass FIR would need many more taps; the report discusses this trade-off.

### 2. SystemVerilog (`SystemVerilog_sample_code/FIR.sv`, `FIR_Top.sv`)
- 41-stage, 16-bit shift register as the tapped delay line
- Coefficient table holding the 41 symmetric integer coefficients (h[k] = h[40−k], so the phase response is linear)
- Multiply-accumulate into a 32-bit sum, then an arithmetic right shift by 10 to undo the ×1024 scaling
- Top level for the DE1-SoC: input from the slide switches, output to the LEDs

### 3. ModelSim (`tb_FIR.sv`, `run_analog.do`)
The testbench streams the ECG samples from `InputSignal.txt` through the RTL model. The hardware output, re-imported into MATLAB, matched the floating-point MATLAB filter **within ±2 LSB**, with every R peak within one sample.

### 4. Quartus
Compiled for the Cyclone V (5CSEMA5F31C6) on the DE1-SoC board. Timing analysis met the **10 MHz** clock constraint with positive slack.

## Filter specification

| Parameter | Value |
|---|---|
| Type | FIR low-pass, linear phase |
| Cut-off | 40 Hz |
| Taps | 41 (order 40) |
| Coefficients | Integers, scaled ×1024 |
| Baseline removal | 1000-sample moving average (MATLAB stage) |
| Sample rate | 1 kHz |
| Data width | 16-bit input and output, 32-bit accumulator |

## Run the simulation

In the ModelSim transcript, from `SystemVerilog_sample_code/`:

```
do run_analog.do
```

## Repository layout

| Folder | Contents |
|---|---|
| `ECG/` | MATLAB design script and four MIT-BIH records |
| `SystemVerilog_sample_code/` | The ECG filter RTL, top level, testbench and ModelSim script |
| `Quartus_FPGA_Project/` | A separate DE1-SoC audio-codec filter project (`D1.sv`, top level `fir_3`): a 17-tap FIR that shares one DSP multiplier across all taps under a small state machine, with fit and timing reports (Fmax 103–106 MHz) |
| `Tutorials/`, `Resources/` | ModelSim and Quartus guides, background slides |

## Tools

MATLAB · SystemVerilog · ModelSim · Intel Quartus Prime · DE1-SoC (Cyclone V)
