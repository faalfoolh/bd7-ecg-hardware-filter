# ============================================================
# ModelSim DO file - Run FIR Filter and show analog ECG waves
# ============================================================
# How to use: In ModelSim transcript type:
#   do run_analog.do
# ============================================================

# Step 1: Compile
vlib work
vlog FIR.sv tb_FIR.sv

# Step 2: Start simulation
vsim tb_FIR

# Step 3: Add signals as analog waves
add wave -analog -height 100 -signed /tb_FIR/FiltIn
add wave -analog -height 100 -signed /tb_FIR/FiltOut

# Step 4: Run 5 seconds of ECG data
run 5000000ns

# Step 5: Zoom to fit
wave zoom full
