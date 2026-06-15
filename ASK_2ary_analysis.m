%% 2ASK 调制详细分析（含频谱分析）
% 详细的2ASK调制、解调、频谱分析程序

clear all; close all; clc;

%% ===================== 参数设置 =====================
SNR = 15;               % 信噪比 (dB)
fc = 100;               % 载波频率 (Hz)
fs = 2000;              % 采样频率 (Hz)
Ts = 1/fs;              % 采样周期
Tb = 0.01;              % 比特周期 (s)
N = fs * Tb;            % 每个比特的采样点数
num_bits = 16;          % 比特数

fprintf('==================== 2ASK 调制分析 ====================\n');
fprintf('系统参数:\n');
fprintf('  载波频率 fc = %.0f Hz\n', fc);
fprintf('  采样频率 fs = %.0f Hz\n', fs);
fprintf('  比特周期 Tb = %.3f s\n', Tb);
fprintf('  比特率 = %.0f bps\n', 1/Tb);
fprintf('  SNR = %.1f dB\n', SNR);
fprintf('========================================================\n\n');

%% ===================== 生成信息序列 =====================
bit_sequence = randi([0, 1], 1, num_bits);
fprintf('信息序列: ');
fprintf('%d', bit_sequence);
fprintf('\n\n');

%% ===================== 2ASK 调制 =====================
% 幅度集: 0 -> 0V, 1 -> 1V
t_total = 0 : Ts : (num_bits * Tb) - Ts;
ask_signal = zeros(1, length(t_total));

for i = 1 : num_bits
    start_idx = (i-1) * N + 1;
    end_idx = i * N;
    amplitude = bit_sequence(i);  % 0 或 1
    carrier = amplitude * cos(2*pi*fc*t_total(start_idx:end_idx));
    ask_signal(start_idx:end_idx) = carrier;
end

%% ===================== 信道（加噪声） =====================
signal_power = mean(ask_signal.^2);
SNR_linear = 10^(SNR/10);
noise_power = signal_power / SNR_linear;
noise = sqrt(noise_power) * randn(1, length(ask_signal));
received_signal = ask_signal + noise;

%% ===================== 解调 =====================
% 方法1: 相干解调
demod_signal = received_signal .* cos(2*pi*fc*t_total);

% 低通滤波器设计（Butterworth）
cutoff_freq = 50;  % 截止频率
normalized_cutoff = cutoff_freq / (fs/2);
[b, a] = butter(4, normalized_cutoff);
filtered_signal = filter(b, a, demod_signal);

% 采样判决
decoded_bits = zeros(1, num_bits);
threshold = 0.5;

for i = 1 : num_bits
    start_idx = (i-1) * N + 1;
    end_idx = i * N;
    sample_value = mean(filtered_signal(start_idx:end_idx));
    if sample_value > threshold
        decoded_bits(i) = 1;
    else
        decoded_bits(i) = 0;
    end
end

% 计算错误率
bit_errors = sum(bit_sequence ~= decoded_bits);
BER = bit_errors / num_bits;

fprintf('解调序列: ');
fprintf('%d', decoded_bits);
fprintf('\n');
fprintf('比特错误: %d\n', bit_errors);
fprintf('BER: %.4f (%.2f%%)\n\n', BER, BER*100);

%% ===================== 绘图 =====================
figure('Position', [100, 50, 1400, 900]);

% 图1: 原始比特序列
subplot(3, 3, 1);
stem(1:num_bits, bit_sequence, 'filled', 'LineWidth', 2);
set(gca, 'XLim', [0, num_bits+1], 'YLim', [-0.2, 1.3]);
ylabel('比特值', 'FontSize', 10);
xlabel('比特号', 'FontSize', 10);
title('1. 原始二进制序列', 'FontSize', 11, 'FontWeight', 'bold');
grid on;

% 图2: 调制信号（无噪声）
subplot(3, 3, 2);
t_short = t_total(1:min(2*N, length(t_total)));
sig_short = ask_signal(1:length(t_short));
plot(t_short, sig_short, 'b-', 'LineWidth', 1.5);
xlabel('时间 (s)', 'FontSize', 10);
ylabel('幅度', 'FontSize', 10);
title('2. 2ASK 调制信号', 'FontSize', 11, 'FontWeight', 'bold');
grid on;

% 图3: 接收信号（含噪声）
subplot(3, 3, 3);
rec_short = received_signal(1:length(t_short));
plot(t_short, rec_short, 'LineWidth', 0.8);
xlabel('时间 (s)', 'FontSize', 10);
ylabel('幅度', 'FontSize', 10);
title(sprintf('3. 接收信号 (SNR=%.1f dB)', SNR), 'FontSize', 11, 'FontWeight', 'bold');
grid on;

% 图4: 调制信号的频谱
subplot(3, 3, 4);
nfft = 2^12;
freq = linspace(0, fs, nfft);
ask_fft = 20*log10(abs(fft(ask_signal, nfft)) + eps);
plot(freq(1:nfft/2), ask_fft(1:nfft/2), 'b-', 'LineWidth', 1.5);
xlabel('频率 (Hz)', 'FontSize', 10);
ylabel('幅度 (dB)', 'FontSize', 10);
title('4. 2ASK 信号频谱', 'FontSize', 11, 'FontWeight', 'bold');
grid on;
set(gca, 'XLim', [0, fs/2]);

% 图5: 接收信号的频谱
subplot(3, 3, 5);
rec_fft = 20*log10(abs(fft(received_signal, nfft)) + eps);
plot(freq(1:nfft/2), rec_fft(1:nfft/2), 'LineWidth', 1.5);
xlabel('频率 (Hz)', 'FontSize', 10);
ylabel('幅度 (dB)', 'FontSize', 10);
title('5. 接收信号频谱', 'FontSize', 11, 'FontWeight', 'bold');
grid on;
set(gca, 'XLim', [0, fs/2]);

% 图6: 解调信号
subplot(3, 3, 6);
demod_short = demod_signal(1:length(t_short));
plot(t_short, demod_short, 'g-', 'LineWidth', 0.8);
xlabel('时间 (s)', 'FontSize', 10);
ylabel('幅度', 'FontSize', 10);
title('6. 解调信号（下变频）', 'FontSize', 11, 'FontWeight', 'bold');
grid on;

% 图7: 低通滤波后信号
subplot(3, 3, 7);
filt_short = filtered_signal(1:length(t_short));
plot(t_short, filt_short, 'r-', 'LineWidth', 1.5);
xlabel('时间 (s)', 'FontSize', 10);
ylabel('幅度', 'FontSize', 10);
title('7. 低通滤波后信号', 'FontSize', 11, 'FontWeight', 'bold');
grid on;

% 图8: 采样判决点
subplot(3, 3, 8);
t_eye = t_total(1:2*N);
sig_eye = filtered_signal(1:2*N);
plot(t_eye, sig_eye, 'b-', 'LineWidth', 1);
hold on;

% 画出采样点
for i = 1:2
    idx = (i-1)*N + round(N/2);
    if idx <= length(filtered_signal)
        plot(t_total(idx), filtered_signal(idx), 'ro', 'MarkerSize', 8, 'MarkerFaceColor', 'r');
    end
end

yline(threshold, '--k', 'LineWidth', 1.5, 'Alpha', 0.7);
ylabel('幅度', 'FontSize', 10);
xlabel('时间 (s)', 'FontSize', 10);
title('8. 采样判决', 'FontSize', 11, 'FontWeight', 'bold');
grid on;

% 图9: 序列对比
subplot(3, 3, 9);
comparison = [bit_sequence; decoded_bits];
bar([1:num_bits]' - 0.2, comparison(1, :)', 0.4, 'b', 'alpha', 0.7);
hold on;
bar([1:num_bits]' + 0.2, comparison(2, :)', 0.4, 'r', 'alpha', 0.7);
set(gca, 'XLim', [0.5, num_bits+0.5], 'YLim', [-0.2, 1.3]);
ylabel('比特值', 'FontSize', 10);
xlabel('比特号', 'FontSize', 10);
title(sprintf('9. 解调结果对比 (BER=%.2f%%)', BER*100), 'FontSize', 11, 'FontWeight', 'bold');
legend('原始', '解调', 'Location', 'best', 'FontSize', 9);
grid on;

sgtitle(['2ASK 调制与解调分析 - fc=', num2str(fc), 'Hz, SNR=', num2str(SNR), 'dB'], ...
    'FontSize', 13, 'FontWeight', 'bold');
