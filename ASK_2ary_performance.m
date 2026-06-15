%% 2ASK 调制性能分析与比较
% 包括BER曲线、星座图、眼图等

clear all; close all; clc;

%% ===================== 参数设置 =====================
fc = 100;               % 载波频率
fs = 1000;              % 采样频率
Tb = 0.01;              % 比特周期
N = fs * Tb;            % 每个比特的采样点数
num_bits = 100;         % 比特数
SNR_range = 0:2:20;     % SNR范围

fprintf('===================== 2ASK 性能分析 =====================\n\n');

%% ===================== 生成测试序列 =====================
bit_sequence = randi([0, 1], 1, num_bits);

% 生成2ASK调制信号
t_total = 0 : (1/fs) : (num_bits * Tb) - (1/fs);
ask_signal = zeros(1, length(t_total));

for i = 1 : num_bits
    start_idx = (i-1) * N + 1;
    end_idx = i * N;
    amplitude = bit_sequence(i);
    carrier = amplitude * cos(2*pi*fc*t_total(start_idx:end_idx));
    ask_signal(start_idx:end_idx) = carrier;
end

signal_power = mean(ask_signal.^2);

%% ===================== 性能分析 =====================
BER_simulated = zeros(1, length(SNR_range));
BER_theoretical = zeros(1, length(SNR_range));

for snr_idx = 1 : length(SNR_range)
    SNR = SNR_range(snr_idx);
    SNR_linear = 10^(SNR/10);
    noise_power = signal_power / SNR_linear;
    
    % 多次试验取平均
    total_errors = 0;
    num_trials = 100;
    
    for trial = 1 : num_trials
        % 加噪声
        noise = sqrt(noise_power) * randn(1, length(ask_signal));
        received_signal = ask_signal + noise;
        
        % 解调
        demod_signal = received_signal .* cos(2*pi*fc*t_total);
        
        % 低通滤波
        cutoff_freq = 50;
        normalized_cutoff = cutoff_freq / (fs/2);
        [b, a] = butter(4, normalized_cutoff);
        filtered_signal = filter(b, a, demod_signal);
        
        % 判决
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
        
        total_errors = total_errors + sum(bit_sequence ~= decoded_bits);
    end
    
    BER_simulated(snr_idx) = total_errors / (num_bits * num_trials);
    
    % 理论BER (2ASK / OOK)
    % BER = Q(sqrt(2*Eb/N0)) = Q(sqrt(2*SNR))
    % Q(x) ≈ 0.5*erfc(x/sqrt(2))
    BER_theoretical(snr_idx) = 0.5 * erfc(sqrt(SNR_linear/2));
end

fprintf('SNR (dB)  | BER_Simulated | BER_Theoretical\n');
fprintf('----------|---------------|----------------\n');
for i = 1 : length(SNR_range)
    fprintf('%8.1f  | %13.2e | %15.2e\n', SNR_range(i), BER_simulated(i), BER_theoretical(i));
end

%% ===================== 绘图 =====================
figure('Position', [100, 100, 1400, 900]);

% 图1: 调制信号时域
subplot(2, 3, 1);
t_show = t_total(1:min(3*N, length(t_total)));
sig_show = ask_signal(1:length(t_show));
plot(t_show, sig_show, 'b-', 'LineWidth', 2);
xlabel('时间 (s)', 'FontSize', 11);
ylabel('幅度', 'FontSize', 11);
title('2ASK 调制信号 (时域)', 'FontSize', 12, 'FontWeight', 'bold');
grid on;

% 图2: 调制信号频域
subplot(2, 3, 2);
nfft = 2^12;
freq = linspace(0, fs, nfft);
ask_fft = 20*log10(abs(fft(ask_signal, nfft)) + eps);
plot(freq(1:nfft/2), ask_fft(1:nfft/2), 'b-', 'LineWidth', 1.5);
xlabel('频率 (Hz)', 'FontSize', 11);
ylabel('幅度 (dB)', 'FontSize', 11);
title('2ASK 频谱', 'FontSize', 12, 'FontWeight', 'bold');
grid on;
set(gca, 'XLim', [0, 300]);

% 图3: 星座图
subplot(2, 3, 3);
% 2ASK星座点: (1, 0) 和 (-1, 0)
constellation_I = [1, -1];
constellation_Q = [0, 0];
plot(constellation_I, constellation_Q, 'bo', 'MarkerSize', 12, 'MarkerFaceColor', 'b');
hold on;
text(1.1, 0.05, '1', 'FontSize', 11, 'FontWeight', 'bold');
text(-1.15, 0.05, '0', 'FontSize', 11, 'FontWeight', 'bold');
xlabel('I (同相)', 'FontSize', 11);
ylabel('Q (正交)', 'FontSize', 11);
title('2ASK 星座图', 'FontSize', 12, 'FontWeight', 'bold');
grid on;
set(gca, 'XLim', [-2, 2], 'YLim', [-1, 1]);
axis square;

% 图4: BER性能曲线
subplot(2, 3, 4);
semilogy(SNR_range, BER_simulated, 'bo-', 'LineWidth', 2, 'MarkerSize', 6, 'DisplayName', '仿真');
hold on;
semilogy(SNR_range, BER_theoretical, 'r^--', 'LineWidth', 2, 'MarkerSize', 6, 'DisplayName', '理论');
xlabel('SNR (dB)', 'FontSize', 11);
ylabel('BER', 'FontSize', 11);
title('2ASK BER性能曲线', 'FontSize', 12, 'FontWeight', 'bold');
grid on;
legend('FontSize', 10);
set(gca, 'YLim', [1e-5, 1]);

% 图5: 眼图
subplot(2, 3, 5);
SNR_eye = 15;
SNR_linear = 10^(SNR_eye/10);
noise_power = signal_power / SNR_linear;
noise = sqrt(noise_power) * randn(1, length(ask_signal));
received_signal = ask_signal + noise;

% 绘制多个比特周期的眼图
for i = 1 : 6
    start_idx = (i-1) * N + 1;
    end_idx = i * N;
    t_eye = t_total(start_idx:end_idx);
    sig_eye = received_signal(start_idx:end_idx);
    
    % 归一化时间
    t_normalized = (t_eye - t_eye(1)) / Tb;
    
    if i == 1
        plot(t_normalized, sig_eye, 'LineWidth', 1);
    else
        plot(t_normalized, sig_eye, 'LineWidth', 1);
    end
    hold on;
end

xlabel('归一化时间 (t/Tb)', 'FontSize', 11);
ylabel('幅度', 'FontSize', 11);
title(sprintf('眼图 (SNR=%.1f dB)', SNR_eye), 'FontSize', 12, 'FontWeight', 'bold');
grid on;
set(gca, 'XLim', [0, 1]);

% 图6: 信噪比与距离的关系
subplot(2, 3, 6);
% 2ASK中，两个信号点距离
distance_2ask = 2;  % |1 - (-1)| = 2
% Eb/N0 与 SNR的关系
eb_n0 = SNR_range - 10*log10(1);  % 对于2ASK，带宽利用率为1
plot(SNR_range, distance_2ask*ones(size(SNR_range)), 'b-', 'LineWidth', 2);
hold on;
xlabel('SNR (dB)', 'FontSize', 11);
ylabel('信号空间距离', 'FontSize', 11);
title('2ASK 信号特征', 'FontSize', 12, 'FontWeight', 'bold');
grid on;

sgtitle('2ASK 调制性能分析', 'FontSize', 14, 'FontWeight', 'bold');

%% ===================== 性能指标统计 =====================
fprintf('\n\n==================== 性能统计 ====================\n');
fprintf('载波频率: %.0f Hz\n', fc);
fprintf('采样频率: %.0f Hz\n', fs);
fprintf('比特周期: %.3f s\n', Tb);
fprintf('比特率: %.0f bps\n', 1/Tb);
fprintf('\n2ASK 调制特点:\n');
fprintf('  - 幅度级数: 2 (0和1)\n');
fprintf('  - 带宽: ~200 Hz (理论)\n');
fprintf('  - 功率效率: 低\n');
fprintf('  - 噪声抗性: 中等\n');
fprintf('  - 复杂度: 低\n');
fprintf('==================================================\n');
