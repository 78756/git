%% 2ASK (2-ary Amplitude Shift Keying) 调制与解调
% 本程序演示2ASK调制信号的生成、传输、接收和解调
% 2ASK: 二进制幅度移键调制

clear all; close all; clc;

%% 参数设置
SNR = 10;               % 信噪比 (dB)
fc = 10;                % 载波频率 (Hz)
fs = 1000;              % 采样频率 (Hz)
Ts = 1/fs;              % 采样周期
Tb = 0.1;               % 比特周期 (s)
N = fs * Tb;            % 每个比特的采样点数

%% 生成随机二进制序列
num_bits = 8;           % 信息比特数
bit_sequence = randi([0, 1], 1, num_bits);
fprintf('原始二进制序列: ');
disp(bit_sequence);

%% 2ASK 调制
% 0 对应幅度 0, 1 对应幅度 1
modulation_amplitude = [0, 1];  % 两个幅度级别

% 生成2ASK调制信号
t_mod = 0 : Ts : (num_bits * Tb) - Ts;  % 调制信号时间轴
ask_signal = zeros(1, length(t_mod));

for i = 1 : num_bits
    start_idx = (i-1) * N + 1;
    end_idx = i * N;
    amplitude = modulation_amplitude(bit_sequence(i) + 1);
    % 载波信号
    carrier = amplitude * cos(2*pi*fc*t_mod(start_idx:end_idx));
    ask_signal(start_idx:end_idx) = carrier;
end

%% 加入高斯白噪声
signal_power = mean(ask_signal.^2);
SNR_linear = 10^(SNR/10);
noise_power = signal_power / SNR_linear;
noise = sqrt(noise_power) * randn(1, length(ask_signal));
received_signal = ask_signal + noise;

%% 2ASK 解调
% 相干解调：与载波相乘，然后低通滤波
demod_signal = received_signal .* cos(2*pi*fc*t_mod);

% 低通滤波
% 设计简单的低通滤波器
cutoff_freq = 2/Tb;     % 截止频率
normalized_cutoff = cutoff_freq / (fs/2);
[b, a] = butter(4, normalized_cutoff);
filtered_signal = filter(b, a, demod_signal);

% 采样判决
decoded_bits = zeros(1, num_bits);
threshold = 0.5;        % 判决阈值

for i = 1 : num_bits
    start_idx = (i-1) * N + 1;
    end_idx = i * N;
    % 取每个比特周期的平均值
    sample_value = mean(filtered_signal(start_idx:end_idx));
    if sample_value > threshold
        decoded_bits(i) = 1;
    else
        decoded_bits(i) = 0;
    end
end

fprintf('解调二进制序列: ');
disp(decoded_bits);

% 计算错误率
bit_errors = sum(bit_sequence ~= decoded_bits);
BER = bit_errors / num_bits;
fprintf('比特错误数: %d\n', bit_errors);
fprintf('比特错误率(BER): %.2f%%\n', BER*100);

%% 绘图
figure('Position', [100, 100, 1200, 800]);

% 1. 原始比特序列
subplot(3, 2, 1);
stem(bit_sequence, 'filled', 'LineWidth', 1.5);
set(gca, 'XLim', [0.5, num_bits+0.5]);
ylabel('比特值');
xlabel('比特序列号');
title('原始二进制序列');
grid on;

% 2. 调制信号（无噪声）
subplot(3, 2, 2);
t_plot = 0 : Ts : 0.5;  % 显示前0.5秒
idx_plot = t_plot < max(t_mod);
plot(t_mod(idx_plot), ask_signal(idx_plot), 'b', 'LineWidth', 1.5);
xlabel('时间 (s)');
ylabel('幅度');
title('2ASK 调制信号 (无噪声)');
grid on;
axis tight;

% 3. 接收信号（含噪声）
subplot(3, 2, 3);
plot(t_mod(idx_plot), received_signal(idx_plot), 'LineWidth', 0.8);
xlabel('时间 (s)');
ylabel('幅度');
title(sprintf('接收信号 (SNR=%.1f dB)', SNR));
grid on;
axis tight;

% 4. 解调信号
subplot(3, 2, 4);
plot(t_mod(idx_plot), demod_signal(idx_plot), 'g', 'LineWidth', 0.8);
xlabel('时间 (s)');
ylabel('幅度');
title('解调信号 (乘以载波)');
grid on;
axis tight;

% 5. 低通滤波后信号与判决点
subplot(3, 2, 5);
plot(t_mod(idx_plot), filtered_signal(idx_plot), 'r', 'LineWidth', 1.5);
hold on;
% 显示每个比特的判决点
decision_points_t = [];
decision_points_v = [];
for i = 1 : num_bits
    start_idx = (i-1) * N + 1;
    end_idx = i * N;
    mid_idx = round((start_idx + end_idx) / 2);
    if mid_idx <= length(filtered_signal) && t_mod(mid_idx) <= max(t_plot)
        decision_points_t = [decision_points_t, t_mod(mid_idx)];
        decision_points_v = [decision_points_v, mean(filtered_signal(start_idx:end_idx))];
    end
end
plot(decision_points_t, decision_points_v, 'ko', 'MarkerSize', 8, 'MarkerFaceColor', 'k');
yline(threshold, '--k', 'LineWidth', 1, 'Label', '判决阈值');
xlabel('时间 (s)');
ylabel('幅度');
title('滤波信号与判决点');
grid on;
axis tight;

% 6. 解调序列vs原始序列
subplot(3, 2, 6);
x = 1 : num_bits;
width = 0.35;
bar(x - width/2, bit_sequence, width, 'b', 'alpha', 0.7);
bar(x + width/2, decoded_bits, width, 'r', 'alpha', 0.7);
set(gca, 'XLim', [0.5, num_bits+0.5]);
set(gca, 'YLim', [-0.2, 1.3]);
ylabel('比特值');
xlabel('比特号');
title(sprintf('原始序列 vs 解调序列 (BER=%.2f%%)', BER*100));
legend('原始', '解调', 'Location', 'best');
grid on;

%% 打印调制信息
fprintf('\n========== 2ASK 调制参数 ==========\n');
fprintf('载波频率: %.1f Hz\n', fc);
fprintf('采样频率: %.0f Hz\n', fs);
fprintf('比特周期: %.3f s\n', Tb);
fprintf('信噪比(SNR): %.1f dB\n', SNR);
fprintf('信号电源: %.4f\n', signal_power);
fprintf('噪声电源: %.4f\n', noise_power);
fprintf('总信息比特数: %d\n', num_bits);
fprintf('=====================================\n\n');
