%% DDS 正弦波生成仿真
% 生成511点的1/4周期正弦波数据，输出200Hz波形
% 作者: MATLAB仿真
% 日期: 2026-08-18

clear all;
close all;
clc;

%% 参数设置
% DDS参数
N_points = 511;          % 波形数据点数（1/4周期）
fs_dds = 200 * 4 * 511;  % DDS采样频率 = 输出频率 * 4 * 点数
                         % 因为1/4周期有511个点，完整周期有2044个点
                         % 所以采样率 = 200Hz * 2044 = 408800 Hz

f_out = 200;             % 输出信号频率 (Hz)
t_total = 1;             % 仿真总时间 (秒)

% 计算参数
N_full = N_points * 4;   % 完整周期点数 (2044点)
fs = f_out * N_full;     % 采样频率 (Hz)
Ts = 1/fs;               % 采样周期 (秒)

%% 生成1/4周期的正弦波数据（0到π/2）
% 方法1：标准正弦波采样
t_quarter = linspace(0, 1/(4*f_out), N_points);
sine_quarter = sin(2*pi*f_out * t_quarter);

% 方法2：DDS查表法生成（等效方法）
% 相位步进 = (1/4周期) / N_points = π/(2*N_points)
phase_step = pi/(2*N_points);
phase = 0:phase_step:(N_points-1)*phase_step;
sine_quarter_dds = sin(phase);

% 验证两种方法是否一致
fprintf('方法1和DDS方法最大误差: %e\n', max(abs(sine_quarter - sine_quarter_dds)));

%% 使用1/4周期数据重建完整周期的正弦波
% 方法：利用对称性
% 第1象限（0-π/2）：直接使用
% 第2象限（π/2-π）：sin(π - θ) = sin(θ)
% 第3象限（π-3π/2）：-sin(θ)
% 第4象限（3π/2-2π）：-sin(θ)

% 构建完整周期的索引映射
full_wave = zeros(1, N_full);

% 第1象限（索引 1:N_points）
full_wave(1:N_points) = sine_quarter;

% 第2象限（索引 N_points+1 : 2*N_points）
% sin(π - θ) = sin(θ)，对第1象限数据倒序
full_wave(N_points+1 : 2*N_points) = fliplr(sine_quarter);

% 第3象限（索引 2*N_points+1 : 3*N_points）
% -sin(θ)，对第1象限数据取反
full_wave(2*N_points+1 : 3*N_points) = -sine_quarter;

% 第4象限（索引 3*N_points+1 : 4*N_points）
% -sin(θ)，对第1象限数据倒序取反
full_wave(3*N_points+1 : 4*N_points) = -fliplr(sine_quarter);

%% 生成时间轴
t = (0:N_full-1) * Ts;

%% 生成多个周期的波形（用于观察）
n_cycles = 5;  % 显示5个周期
t_multi = (0:n_cycles*N_full-1) * Ts;
wave_multi = repmat(full_wave, 1, n_cycles);

%% 绘制结果
figure('Position', [100, 100, 1200, 800]);

% 子图1：1/4周期正弦波数据
subplot(3,2,1);
t_quarter_us = t_quarter * 1e6;  % 转换为微秒
plot(t_quarter_us, sine_quarter, 'b-o', 'LineWidth', 2, 'MarkerSize', 4);
grid on;
xlabel('时间 (μs)');
ylabel('幅值');
title(['1/4周期正弦波数据 (', num2str(N_points), '点)']);
xlim([min(t_quarter_us), max(t_quarter_us)]);

% 子图2：完整周期重建波形
subplot(3,2,2);
t_full_us = t * 1e6;  % 转换为微秒
plot(t_full_us, full_wave, 'r-', 'LineWidth', 2);
grid on;
xlabel('时间 (μs)');
ylabel('幅值');
title(['完整周期重建波形 (', num2str(N_full), '点)']);
xlim([min(t_full_us), max(t_full_us)]);

% 子图3：多个周期波形
subplot(3,2,[3,4]);
t_multi_us = t_multi * 1e6;
plot(t_multi_us, wave_multi, 'b-', 'LineWidth', 2);
hold on;
grid on;
xlabel('时间 (μs)');
ylabel('幅值');
title(['多周期输出波形 (', num2str(n_cycles), '个周期)']);
xlim([min(t_multi_us), max(t_multi_us)]);

% 子图4：频谱分析
subplot(3,2,5);
N_fft = 2^nextpow2(N_full);
wave_fft = fft(full_wave, N_fft);
freq = (0:N_fft-1) * fs / N_fft;
plot(freq(1:N_fft/2), 20*log10(abs(wave_fft(1:N_fft/2))), 'b-', 'LineWidth', 2);
grid on;
xlabel('频率 (Hz)');
ylabel('幅度 (dB)');
title('频谱分析');
xlim([0, fs/2]);
ylim([-60, 20]);

% 子图6：相位噪声/误差分析
subplot(3,2,6);
% 理想正弦波
ideal_sine = sin(2*pi*f_out * t);
error = full_wave - ideal_sine;
plot(t_full_us, error, 'r-', 'LineWidth', 2);
grid on;
xlabel('时间 (μs)');
ylabel('幅值误差');
title(['波形误差分析 (RMS误差: ', num2str(rms(error)), ')']);
xlim([min(t_full_us), max(t_full_us)]);

%% 输出数据信息
fprintf('========== DDS参数信息 ==========\n');
fprintf('输出频率: %d Hz\n', f_out);
fprintf('1/4周期点数: %d\n', N_points);
fprintf('完整周期点数: %d\n', N_full);
fprintf('采样频率: %.2f Hz\n', fs);
fprintf('采样周期: %.3f μs\n', Ts*1e6);
fprintf('频率分辨率: %.3f Hz\n', fs/N_full);
fprintf('波形RMS误差: %e\n', rms(error));
fprintf('信噪比: %.2f dB\n', 20*log10(rms(ideal_sine)/rms(error)));
fprintf('==================================\n');

%% 导出DDS数据（可选）
% 保存为十六进制或十进制格式，用于FPGA实现
% dds_data = round(sine_quarter * 2^15);  % 转换为16位有符号整数
% save('dds_sine_data.mat', 'sine_quarter', 'dds_data');

%% 计算DDS相位累加器参数（额外分析）
fprintf('\n========== DDS相位累加器分析 ==========\n');
phase_accumulator_bits = 32;  % 假设32位相位累加器
fcw = f_out * 2^phase_accumulator_bits / fs;
fprintf('频率控制字 (FCW): %.2f (32位)\n', fcw);
fprintf('等效相位步进: %.6f rad\n', fcw * 2*pi / 2^phase_accumulator_bits);
fprintf('实际输出频率: %.6f Hz\n', fcw * fs / 2^phase_accumulator_bits);
fprintf('========================================\n');

%% 结束
disp('DDS正弦波仿真完成！');