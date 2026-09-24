clear

%%参数设置
A   = 1             ; %信号幅度
f   = 1             ; %信号频率，DDS量化将其设置为1
fs  = 4096          ;%采样频率，将其设置为要量化的相位个数
T   = 1/f/4;%1/f /4 ; %信号持续时间,只持续1/4周期
phi = 0             ;%初始相位

t = 0 : 1/fs : T-1/fs; %构建的时间向量
y = A * sin(2*pi*f*t +phi);
yint = int16(y*(2^15));

%%波形可视化
% figure;
% plot(t,y);
% 
% xlabel('时间（秒）');
% ylabel('幅度');
% title('1/4正弦波');
% grid on;

file1 = fopen('./sin_datafloat.txt','w');
file2 = fopen('./sin_data16bit.txt','w');
for i = 1:length(y)
    fprintf(file1,'%.6f\n',y(i));
    fprintf(file2,'%x\n',yint(i));
end
fclose(file1);
fclose(file2);

f_s_1               = 100 * 10^3                ;%采样频率
f_o                 = 250                       ;%输出频率
phase_bits          = 48                        ;%相位累加器位数
phase_accumulator   = 0                         ;%初相位
FCW                 = round(f_o/f_s_1 * 2^phase_bits); %频率控制字（整数）

% 用 1/4 正弦表 yint(4096 点, 0~90°) 通过象限映射生成完整正弦波
N_sample = f_s_1/f_o * 10;                    %绘制2个周期的波形
gen_wave = zeros(1, N_sample);

tbl      = double(yint);             %查表地址 0~4095 -> 索引 1~4096
phase    = phase_accumulator;

gen_wave_dither = zeros(1, N_sample);
phase_dither = phase_accumulator;
phase_lookup = phase_accumulator;
lfsr_data = uint8(1);

addr_shift = phase_bits - 12;        % = 36，被截断的低位数
dither_shift = addr_shift - 8;       % = 28，把 8 位 LFSR 放到 addr LSB 下方 8 位

for i = 1:N_sample
    % ---- 无 dither 通道 ----
    quad = floor(phase / 2^(phase_bits-2));
    addr = floor(mod(phase, 2^(phase_bits-2)) / 2^(phase_bits-12));
    switch quad
        case 0, gen_wave(i) =  tbl(addr + 1);
        case 1, gen_wave(i) =  tbl(1024 - addr);
        case 2, gen_wave(i) = -tbl(addr + 1);
        case 3, gen_wave(i) = -tbl(1024 - addr);
    end
    

    % ---- 有 dither 通道 ----


    quad1 = floor(phase_dither / 2^(phase_bits-2));
    addr1 = floor(mod(phase_dither, 2^(phase_bits-2)) / 2^(phase_bits-12));
    switch quad1
        case 0, gen_wave_dither(i) =  tbl(addr1 + 1);
        case 1, gen_wave_dither(i) =  tbl(1024 - addr1);
        case 2, gen_wave_dither(i) = -tbl(addr1 + 1);
        case 3, gen_wave_dither(i) = -tbl(1024 - addr1);
    end


    phase = mod(phase + FCW, 2^phase_bits);
    dither_val = double(lfsr_data - 128) * 2^dither_shift;      % 关键：量纲对齐
    phase_dither = mod(phase + dither_val, 2^phase_bits);
    % ---- LFSR 更新 ----

    b8 = bitget(lfsr_data, 8);
    b6 = bitget(lfsr_data, 6);
    b5 = bitget(lfsr_data, 5);
    b4 = bitget(lfsr_data, 4);
    feedback = bitxor(bitxor(bitxor(b8, b6), b5), b4);   % uint8 的 0 或 1
    lfsr_data = bitshift(lfsr_data, 1);                   % uint8 左移，自动截断
    lfsr_data = bitor(lfsr_data, feedback);  
end




samp_t = (0:N_sample-1) / f_s_1;

figure;
plot(samp_t, gen_wave);

xlabel('时间（秒）');
ylabel('幅度');
title('250 Hz DDS 输出波形（查表 yint 生成）');
grid on;

%% 频谱分析（FFT）—— 对比 gen_wave 与 gen_wave_dither
N_fft = N_sample;                      % 整周期采样，不补零

% --- 无 dither ---
Y1  = fft(gen_wave, N_fft);
P2  = abs(Y1 / N_fft);
P1  = P2(1:N_fft/2+1);
P1(2:end-1) = 2*P1(2:end-1);

% --- 有 dither ---
Y2  = fft(gen_wave_dither, N_fft);
P2d = abs(Y2 / N_fft);
P1d = P2d(1:N_fft/2+1);
P1d(2:end-1) = 2*P1d(2:end-1);

f_axis = f_s_1 * (0:(N_fft/2)) / N_fft;

figure(1);
%subplot(2,1,1);
plot(f_axis, 20*log10(P1  + eps), 'b', 'LineWidth', 1.2); hold on;
%subplot(2,1,2);
plot(f_axis, 20*log10(P1d + eps), 'r', 'LineWidth', 1.2);hold off;
xlim([0 500]);
ylim([-120 0]);                        % 只显示 -120~0 dB
xlabel('频率 (Hz)');
ylabel('幅度 (dB)');
title('250 Hz DDS 输出频谱（dB）');
legend('无 dither', '有 dither');
grid on;



% 找到基波 bin（250 Hz 附近）
[~, k0] = min(abs(f_axis - f_o));
% 基波功率之外的最大杂散
P1_wo = P1; P1_wo(k0) = 0;
SFDR_wo = 20*log10(P1(k0) / max(P1_wo));

P1d_wo = P1d; P1d_wo(k0) = 0;
SFDR_d = 20*log10(P1d(k0) / max(P1d_wo));

fprintf('无 dither SFDR = %.2f dB\n', SFDR_wo);
fprintf('有 dither SFDR = %.2f dB\n', SFDR_d);