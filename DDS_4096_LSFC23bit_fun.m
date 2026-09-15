clc
clear all

%%参数设置
A   = 1             ; %信号幅度
f   = 1             ; %信号频率，DDS量化将其设置为1
addr_width = 12;%4096表
samp_num = 2^addr_width/4 ;%压缩成1/4表
fs  = samp_num *4         ;%采样频率，将其设置为要量化的相位个数
T   = 1/f/4;%1/f /4 ; %信号持续时间,只持续1/4周期
phi = 0             ;%初始相位

% t = 0 : 1/fs : T-1/fs; %构建的时间向量
% 中点采样：第 i 个表值放在地址区间中点 (i+0.5)/1024 * pi/2 处。
% 10 位地址 = 每象限 1024 个区间。若用 linspace(0,1/4,1024) 则是 1023 个区间，
% 与地址译码(1024 区间)错位，会在表值里引入 3/5/7 次谐波，把 SFDR 钉在 72dB。
t = ((0:samp_num-1) + 0.5) / samp_num * 0.25;   % 中点相位, 单位: 归一化周期
y = A * sin(2*pi*f*t + phi);
% 不再强制 y(samp_num)=1.0：中点采样下 sin(pi/2) 峰值点本来就不在表内，
% 反射查表天然对称；强行置 1 反而破坏首尾对称。
yint = int32(round(y*(2^18 - 1)));   % 18 位有符号表值, 范围 0~262143 (与 FPGA ROM 数据位宽一致)

%%波形可视化
% figure;
% plot(t,y);
% 
% xlabel('时间（秒）');
% ylabel('幅度');
% title('1/4正弦波');
% grid on;

file1 = fopen('./sin_datafloat.txt','w');
file2 = fopen('./sin_data18bit.txt','w');   % 18 位表值, 十六进制输出
for i = 1:length(y)
    fprintf(file1,'%.6f\n',y(i));
    fprintf(file2,'%x\n',yint(i));
end
fclose(file1);
fclose(file2);

f_s_1               = 1 * 10^6      ;%采样频率
% f_o                 = 100000        ;%输出频率
f_o = f_s_1 /1000;
phase_bits          = 48            ;%相位累加器位数
phase_accumulator   = 0                         ;%初相位
FCW                 = round(f_o/f_s_1 * 2^phase_bits); %频率控制字（整数）

% 用 1/4 正弦表 yint(1024 点, 0~90°) 通过象限映射生成完整正弦波
N_sample = round(f_s_1/f_o * 100);                    %绘制100个周期的波形
gen_wave = zeros(1, N_sample);
gen_wave_taylor = zeros(1, N_sample);
gen_wave_dither = zeros(1, N_sample);
gen_wave_dither_taylor = zeros(1, N_sample);   % dither + taylor 同时使用

tbl      = double(yint);             %查表地址 0~1023 -> 索引 1~1024

phase    = phase_accumulator;
phase_dither = phase_accumulator;

fprintf('tbl(1) = %d, tbl(%d) = %d\n', tbl(1),samp_num, tbl(samp_num));
fprintf('tbl(2) = %d, tbl(%d) = %d\n', tbl(2),samp_num -1, tbl(samp_num -1));
lfsr_data = uint32(1); 

% 48 位相位直接译码（不再先截断到 20 位）：
% 高 2 位 = 象限, 次高 10 位 = 表地址(0~1023), 低 36 位 = 插值小数 ε
addr_shift = phase_bits - addr_width;        % = 36，地址以下被截断的低位数
dither_shift = addr_shift - 8;       % = 28，把 8 位 LFSR 放到 addr LSB 下方 8 位

for i = 1:N_sample
    % ---- 无 dither 通道 ----
    % 象限、地址、ε 直接用完整 48 位相位（与有 dither 通道同一套译码口径）
    quad = floor(phase / 2^(phase_bits-2));                          % 0~3 (高2位)
    addr = floor(mod(phase, 2^(phase_bits-2)) / 2^(addr_shift));     % 0~1023 (次高10位)
    eps_phase = mod(mod(phase, 2^(phase_bits-2)), 2^addr_shift) / 2^addr_shift;   % 低36位小数
    switch quad
        case 0, s=  tbl(addr + 1);
        case 1, s =  tbl(samp_num - addr);
        case 2, s = -tbl(addr + 1);
        case 3, s = -tbl(samp_num - addr);
    end
    switch quad
        case 0, c =  tbl(samp_num - addr);       % cos(Θ) = sin(90°-Θ)
        case 1, c = -tbl(addr + 1);              % cos(90°+Θ) = -sin(Θ)
        case 2, c = -tbl(samp_num - addr);       % cos(180°+Θ) = -cos(Θ)
        case 3, c =  tbl(addr + 1);              % cos(270°+Θ) = sin(Θ)
    end
    % 一阶泰勒插值: sin(θ+εΔθ) ≈ s + c·ε·Δθ, 其中 Δθ = (π/2)/1024
    % 只补表点之间的插值误差；表值本身必须先用中点采样保证正确。
    delta = c * eps_phase * (pi/2) / samp_num;
    gen_wave(i) = s;
    gen_wave_taylor(i) = round(s + delta);
    % ---- 有 dither 通道 ----
    quad1 = floor(phase_dither / 2^(phase_bits-2));
    addr1 = floor(mod(phase_dither, 2^(phase_bits-2)) / 2^(addr_shift));
    eps_phase1 = mod(mod(phase_dither, 2^(phase_bits-2)), 2^addr_shift) / 2^addr_shift;
    switch quad1
        case 0, s1 =  tbl(addr1 + 1);
        case 1, s1 =  tbl(samp_num - addr1);
        case 2, s1 = -tbl(addr1 + 1);
        case 3, s1 = -tbl(samp_num - addr1);
    end
    switch quad1
        case 0, c1 =  tbl(samp_num - addr1);
        case 1, c1 = -tbl(addr1 + 1);
        case 2, c1 = -tbl(samp_num - addr1);
        case 3, c1 =  tbl(addr1 + 1);
    end
    gen_wave_dither(i) = s1;
    gen_wave_dither_taylor(i) = round(s1 + c1 * eps_phase1 * (pi/2) / samp_num);   % dither + taylor


    phase = mod(phase + FCW, 2^phase_bits);

    [lfsr_data, dither_byte] = lfsr_generic(lfsr_data, 23, 23, 18);
    dither_val = (double(dither_byte) - 128) / 256 * 2^addr_shift;
    phase_dither = mod(phase + dither_val, 2^phase_bits);

end


diff_cnt = sum(gen_wave ~= gen_wave_dither);
fprintf('两通道不同的采样点数 = %d / %d\n', diff_cnt, N_sample);
fprintf('max diff = %d\n', max(abs(gen_wave - gen_wave_dither)));

diff_cnt_taylor = sum(gen_wave ~= gen_wave_taylor);
fprintf('两通道不同泰勒的采样点数 = %d / %d\n', diff_cnt_taylor, N_sample);
fprintf('max diff = %d\n', max(abs(gen_wave - gen_wave_taylor)));

samp_t = (0:N_sample-1) / f_s_1;

figure;
plot(samp_t, gen_wave);

xlabel('时间（秒）');
ylabel('幅度');
title(sprintf('%.3f Hz DDS 输出波形（查表 yint 生成）', f_o));
grid on;

%% 频谱分析（FFT）—— 对比 gen_wave 与 gen_wave_dither
N_fft = N_sample;                      % 整周期采样，不补零
% w = hann(N_sample)';
% cg = sum(w) / N_sample;
% --- 无 dither ---
% Y1  = fft(gen_wave .* w, N_fft)/cg;
Y1  = fft(gen_wave, N_fft);
P2  = abs(Y1 / N_fft);
P1  = P2(1:N_fft/2+1);
P1(2:end-1) = 2*P1(2:end-1);

% --- 有 dither ---
% Y2  = fft(gen_wave_dither .* w, N_fft)/cg;
Y2  = fft(gen_wave_dither, N_fft);
P2d = abs(Y2 / N_fft);
P1d = P2d(1:N_fft/2+1);
P1d(2:end-1) = 2*P1d(2:end-1);


Y3  = fft(gen_wave_taylor, N_fft);
P2t = abs(Y3 / N_fft);
P1t = P2t(1:N_fft/2+1);
P1t(2:end-1) = 2*P1t(2:end-1);

% --- 有 dither + taylor ---
Y4  = fft(gen_wave_dither_taylor, N_fft);
P2dt = abs(Y4 / N_fft);
P1dt = P2dt(1:N_fft/2+1);
P1dt(2:end-1) = 2*P1dt(2:end-1);

f_axis = f_s_1 * (0:(N_fft/2)) / N_fft;

figure;
%subplot(2,1,1);
plot(f_axis, 20*log10(P1  + eps), 'b', 'LineWidth', 1.2); 
hold on;
%subplot(2,1,2);
plot(f_axis, 20*log10(P1d + eps), 'r', 'LineWidth', 1.2);
plot(f_axis, 20*log10(P1t + eps), 'g', 'LineWidth', 1.2);
plot(f_axis, 20*log10(P1dt + eps), 'm', 'LineWidth', 1.2);
hold off;
xlim([0 2.5*10^4]);
ylim([-120 100]);                        % 只显示 -120~0 dB
xlabel('频率 (Hz)');
ylabel('幅度 (dB)');
title(sprintf('%.3f DDS 输出频谱（dB）',f_o));
legend('无 dither', '有 dither', '有 taylor', '有 taylor+dither');
grid on;



% 找到基波 bin（250 Hz 附近）
[~, k0] = min(abs(f_axis - f_o));
k0 = round(k0);
% 基波功率之外的最大杂散
P1_wo = P1; P1_wo(k0) = 0;
SFDR_wo = 20*log10(P1(k0) / max(P1_wo));

P1d_wo = P1d; P1d_wo(k0) = 0;
SFDR_d = 20*log10(P1d(k0) / max(P1d_wo));

P1t_wo = P1t; P1t_wo(k0) = 0;
SFDR_t = 20*log10(P1t(k0) / max(P1t_wo));

P1dt_wo = P1dt; P1dt_wo(k0) = 0;
SFDR_dt = 20*log10(P1dt(k0) / max(P1dt_wo));

[spur_val, spur_idx] = max(P1_wo);
fprintf('无 dither 最大杂散在 %.1f Hz，幅度 %.2f dB\n', f_axis(spur_idx), 20*log10(spur_val+eps));
[spur_val_d, spur_idx_d] = max(P1d_wo);
fprintf('有 dither 最大杂散在 %.1f Hz，幅度 %.2f dB\n', ...
        f_axis(spur_idx_d), 20*log10(spur_val_d+eps));

[spur_val_t, spur_idx_t] = max(P1t_wo);
fprintf('有taylor 最大杂散在 %.1f Hz，幅度 %.2f dB\n', ...
        f_axis(spur_idx_t), 20*log10(spur_val_t+eps));

[spur_val_dt, spur_idx_dt] = max(P1dt_wo);
fprintf('有taylor+dither 最大杂散在 %.1f Hz，幅度 %.2f dB\n', ...
        f_axis(spur_idx_dt), 20*log10(spur_val_dt+eps));

fprintf('无dither SFDR = %.2f dB\n', SFDR_wo);
fprintf('有dither SFDR = %.2f dB\n', SFDR_d);
fprintf('有taylor SFDR = %.2f dB\n', SFDR_t);
fprintf('有taylor+dither SFDR = %.2f dB\n', SFDR_dt);
fprintf('基波附近谱线：\n');
for k = k0-3:k0+3
    if k >= 1 && k <= length(f_axis)
        fprintf('  %.1f Hz: %.2f dB\n', f_axis(k), 20*log10(P1(k)+eps));
    end
end