%% 2ASK 快速参考 - 常用代码片段

%% ================== 基础参数配置 ==================
fc = 100;               % 载波频率 (Hz)
fs = 1000;              % 采样频率 (Hz)
Tb = 0.01;              % 比特周期 (s)
N = fs * Tb;            % 每个比特的采样点数
Ts = 1/fs;              % 采样时间间隔
SNR = 15;               % 信噪比 (dB)


%% ================== 随机比特序列 ==================
num_bits = 16;
bit_sequence = randi([0, 1], 1, num_bits);
% 或者自定义序列
bit_sequence = [1 0 1 1 0 1 0 1];


%% ================== 2ASK 调制 ==================
% 方法 1: 简单方式
t = 0:Ts:(num_bits*Tb)-Ts;
ask_signal = zeros(1, length(t));

for i = 1:num_bits
    idx = (i-1)*N + 1 : i*N;
    amplitude = bit_sequence(i);
    ask_signal(idx) = amplitude * cos(2*pi*fc*t(idx));
end

% 方法 2: 向量化方式（更快）
bit_repeated = repmat(bit_sequence, N, 1);
bit_matrix = reshape(bit_repeated, 1, []);
carrier = cos(2*pi*fc*t);
ask_signal_v2 = bit_matrix .* carrier;


%% ================== 加入噪声 ==================
signal_power = mean(ask_signal.^2);
SNR_linear = 10^(SNR/10);
noise_power = signal_power / SNR_linear;

% 添加高斯白噪声
noise = sqrt(noise_power) * randn(1, length(ask_signal));
received_signal = ask_signal + noise;

% 或一行代码
received_signal = awgn(ask_signal, SNR, 'measured');


%% ================== 相干解调 ==================
% 乘以同步的载波
demod_signal = received_signal .* cos(2*pi*fc*t);


%% ================== 低通滤波 ==================
% 方法 1: Butterworth 滤波器
cutoff_freq = 50;
normalized_cutoff = cutoff_freq / (fs/2);
[b, a] = butter(4, normalized_cutoff);
filtered_signal = filter(b, a, demod_signal);

% 方法 2: FIR 滤波器
h = fir1(50, normalized_cutoff);
filtered_signal_fir = filter(h, 1, demod_signal);

% 方法 3: 使用通信工具箱
filtered_signal_toolbox = lowpass(demod_signal, cutoff_freq, fs);


%% ================== 采样判决 ==================
threshold = 0.5;
decoded_bits = zeros(1, num_bits);

% 方法 1: 逐个判决
for i = 1:num_bits
    idx = (i-1)*N + 1 : i*N;
    sample = mean(filtered_signal(idx));
    decoded_bits(i) = (sample > threshold) ? 1 : 0;
end

% 方法 2: 向量化
sample_values = mean(reshape(filtered_signal(1:num_bits*N), N, num_bits));
decoded_bits = (sample_values > threshold);


%% ================== 错误率计算 ==================
% 比特错误数
bit_errors = sum(bit_sequence ~= decoded_bits);

% 比特错误率 (BER)
BER = bit_errors / num_bits;

% 百分比显示
fprintf('BER = %.2f%%\n', BER*100);


%% ================== 频谱分析 ==================
nfft = 2^10;
freq = linspace(0, fs, nfft);

% ASK 信号频谱
ask_spectrum = 20*log10(abs(fft(ask_signal, nfft)) + eps);

% 绘图
figure;
plot(freq(1:nfft/2), ask_spectrum(1:nfft/2));
xlabel('Frequency (Hz)');
ylabel('Magnitude (dB)');
title('2ASK Signal Spectrum');


%% ================== 时域波形绘图 ==================
% 显示前 3 个比特
t_show = t(1:3*N);

figure;
subplot(3,1,1);
plot(t_show, ask_signal(1:3*N), 'b');
title('Modulated Signal');
ylabel('Amplitude');
grid on;

subplot(3,1,2);
plot(t_show, received_signal(1:3*N), 'r');
title('Received Signal (with noise)');
ylabel('Amplitude');
grid on;

subplot(3,1,3);
plot(t_show, filtered_signal(1:3*N), 'g');
title('After Low-Pass Filter');
ylabel('Amplitude');
xlabel('Time (s)');
grid on;


%% ================== 星座图 ==================
% 2ASK 有 2 个星座点
I = [1, -1];
Q = [0, 0];

figure;
plot(I, Q, 'bo', 'MarkerSize', 12);
hold on;
text(1, 0.1, '1', 'FontSize', 12);
text(-1, 0.1, '0', 'FontSize', 12);
xlabel('In-Phase');
ylabel('Quadrature');
title('2ASK Constellation');
grid on;
axis square;


%% ================== BER 曲线（多 SNR 点） ==================
SNR_range = 0:2:20;
BER_curve = zeros(1, length(SNR_range));

for snr_idx = 1:length(SNR_range)
    SNR = SNR_range(snr_idx);
    SNR_lin = 10^(SNR/10);
    noise_p = signal_power / SNR_lin;
    
    % 单次试验 BER
    noise_n = sqrt(noise_p) * randn(1, length(ask_signal));
    received = ask_signal + noise_n;
    demod = received .* cos(2*pi*fc*t);
    filt = filter(b, a, demod);
    
    decoded = zeros(1, num_bits);
    for i = 1:num_bits
        idx = (i-1)*N + 1 : i*N;
        decoded(i) = mean(filt(idx)) > threshold;
    end
    
    BER_curve(snr_idx) = sum(bit_sequence ~= decoded) / num_bits;
end

% 绘图
figure;
semilogy(SNR_range, BER_curve, 'b-o');
xlabel('SNR (dB)');
ylabel('BER');
title('2ASK BER vs SNR');
grid on;


%% ================== 理论 BER 公式 ==================
% 2ASK (OOK) 理论 BER
% BER = Q(sqrt(2*Eb/N0)) = Q(sqrt(2*SNR))
% Q(x) = 0.5*erfc(x/sqrt(2))

SNR_theory = 0:2:20;
SNR_linear_theory = 10.^(SNR_theory/10);

% Q 函数计算
BER_theory = 0.5 * erfc(sqrt(SNR_linear_theory/2));

% 绘图对比
figure;
semilogy(SNR_range, BER_curve, 'bo-', 'DisplayName', 'Simulated');
hold on;
semilogy(SNR_theory, BER_theory, 'r^--', 'DisplayName', 'Theoretical');
xlabel('SNR (dB)');
ylabel('BER');
title('BER: Simulated vs Theoretical');
legend;
grid on;


%% ================== 眼图 ==================
% 显示多个比特周期的接收信号
figure;
for i = 1:8
    idx = (i-1)*N + 1 : i*N;
    t_norm = linspace(0, 1, length(idx));
    plot(t_norm, filtered_signal(idx), 'LineWidth', 1);
    hold on;
end
xlabel('Normalized Time (t/Tb)');
ylabel('Amplitude');
title('Eye Diagram');
grid on;
xlim([0, 1]);


%% ================== 匹配滤波解调 ==================
% 生成匹配滤波器
match_filter = cos(2*pi*fc*t(1:N));

% 应用匹配滤波
matched_output = zeros(1, num_bits);
for i = 1:num_bits
    idx = (i-1)*N + 1 : i*N;
    matched_output(i) = sum(filtered_signal(idx) .* match_filter);
end

% 判决
decoded_matched = (matched_output > threshold);


%% ================== 时间同步 ==================
% 简单的同步：找最大能量位置
[~, sync_pos] = max(abs(filtered_signal));
offset = mod(sync_pos - 1, N);

% 调整采样点
corrected_bits = zeros(1, num_bits);
for i = 1:num_bits
    sample_idx = (i-1)*N + offset + N/2;
    if sample_idx <= length(filtered_signal)
        corrected_bits(i) = (filtered_signal(sample_idx) > threshold);
    end
end


%% ================== 频率同步 ==================
% 估计频率偏差（粗同步）
freq_step = 1;  % Hz
freq_range = fc - 10 : freq_step : fc + 10;
energy = zeros(size(freq_range));

for f_idx = 1:length(freq_range)
    f_test = freq_range(f_idx);
    demod_test = received_signal .* cos(2*pi*f_test*t);
    filt_test = filter(b, a, demod_test);
    energy(f_idx) = sum(filt_test.^2);
end

[~, best_f_idx] = max(energy);
fc_estimated = freq_range(best_f_idx);
fprintf('Estimated carrier freq: %.1f Hz\n', fc_estimated);


%% ================== 快速总结 ==================
% 2ASK 调制-解调完整流程：
%
% 1. 生成比特序列:  bit_sequence
% 2. ASK 调制:      ask_signal = bit * cos(2πfct)
% 3. 加信道噪声:    received = ask_signal + noise
% 4. 相干解调:      demod = received * cos(2πfct)
% 5. 低通滤波:      filtered = lpf(demod)
% 6. 采样判决:      if filtered > 0.5 then 1 else 0
% 7. 计算 BER:      BER = sum(错误) / 总比特数
%
% 关键参数: fc, fs, Tb, SNR, threshold
% 关键时间: 采样率 fs 必须 > 2*fc (Nyquist)
