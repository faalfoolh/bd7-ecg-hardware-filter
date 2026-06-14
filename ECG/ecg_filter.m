%% ECG Filter Design - D7 Project
% Load and plot ECG signal, then filter it

%% Step 1: Load the ECG file
load('105.mat')
fs = 1000;                          % sampling frequency = 1 KHz
t = (0:length(y)-1) / fs;          % time axis in seconds

%% Step 2: Plot the full raw signal
figure
plot(t, y)
xlabel('Time (seconds)')
ylabel('Amplitude')
title('ECG Signal - 105 (Full)')

%% Step 3: Plot first 5 seconds to see detail
figure
plot(t(1:5000), y(1:5000))
xlabel('Time (seconds)')
ylabel('Amplitude')
title('ECG Signal - 105 (first 5 seconds)')

%% Step 4: Remove baseline wandering using moving average
window = 1000;                      % 1 second window
baseline = movmean(y, window);      % estimate the slow drift
y_filtered = y - baseline;         % subtract it to remove drift

% Plot original vs baseline-removed
figure
plot(t(1:5000), y(1:5000))
hold on
plot(t(1:5000), y_filtered(1:5000))
legend('Original', 'Filtered')
title('ECG Before and After Baseline Removal')
xlabel('Time (seconds)')
ylabel('Amplitude')

%% Step 5: Remove high frequency noise using smoothing
y_clean = movmean(y_filtered, 5);  % smooth over 5 samples

% Plot baseline-removed vs fully cleaned
figure
plot(t(1:5000), y_filtered(1:5000))
hold on
plot(t(1:5000), y_clean(1:5000))
legend('After baseline removal', 'Fully cleaned')
title('ECG - Noise Removal')
xlabel('Time (seconds)')
ylabel('Amplitude')

%% Step 6: Design FIR bandpass filter coefficients for hardware
fs = 1000;
f_low  = 0.5;   % removes baseline wandering below this
f_high = 40;    % removes noise above this
N = 40;         % filter order (41 taps)

% Windowed sinc method (no toolbox needed)
wl = 2*pi*f_low/fs;
wh = 2*pi*f_high/fs;
n  = -(N/2):(N/2);

% Compute sinc coefficients
h = (sin(wh*n) - sin(wl*n)) ./ (pi*n);
h(N/2+1) = (wh - wl)/pi;           % fix n=0 case

% Apply Hamming window to improve filter quality
w = 0.54 - 0.46*cos(2*pi*(0:N)/N);
h = h .* w;

% Scale to integers for hardware (x1024 then round)
h_int = round(h * 1024);

disp('Filter coefficients (integers for hardware):')
disp(h_int)

% Save coefficients to file
fid = fopen('coefficients.txt', 'w');
for i = 1:length(h_int)
    fprintf(fid, '%d\n', h_int(i));
end
fclose(fid);
disp('Coefficients saved to coefficients.txt')

%% Step 7: Apply the FIR filter to ECG signal
y_fir = filter(h, 1, double(y));

% Plot comparison
figure
plot(t(1:5000), y_clean(1:5000))
hold on
plot(t(1:5000), y_fir(1:5000))
legend('Moving average method', 'FIR filter method')
title('ECG - Comparing Filter Methods')
xlabel('Time (seconds)')
ylabel('Amplitude')

%% Step 8: Save ECG input as integers for SystemVerilog testbench
% This file goes into the SystemVerilog_sample_code folder
y_int = round(double(y));
fid = fopen('../SystemVerilog_sample_code/InputSignal.txt', 'w');
for i = 1:length(y_int)
    fprintf(fid, '%d\n', y_int(i));
end
fclose(fid);
disp('ECG input saved to SystemVerilog_sample_code/InputSignal.txt')

%% Step 9: Save MATLAB filtered output for comparison with ModelSim output
y_fir_int = round(y_fir);
fid = fopen('../SystemVerilog_sample_code/MatlabOutput.txt', 'w');
for i = 1:length(y_fir_int)
    fprintf(fid, '%d\n', y_fir_int(i));
end
fclose(fid);
disp('MATLAB filtered output saved to SystemVerilog_sample_code/MatlabOutput.txt')
