clc
clear

data_dir = 'd:/prj/DDS/sim/FPGA';
file_names = {'dds_data.txt', 'dither_data.txt', 'taylor_data.txt'};
labels = {'DDS', 'Dither', 'Taylor'};
fs = 500e6;
expected_fout = 500e3;

data = cell(1, numel(file_names));
for k = 1:numel(file_names)
	file_id = fopen(fullfile(data_dir, file_names{k}), 'r');
	if file_id < 0
		error('无法打开文件 %s。', file_names{k});
	end
	data{k} = fscanf(file_id, '%f');
	fclose(file_id);
	data{k} = data{k}(:);
	if isempty(data{k}) || any(~isfinite(data{k}))
		error('文件 %s 为空或包含非数值数据。', file_names{k});
	end
end

n_sample = numel(data{1});
if any(cellfun(@numel, data) ~= n_sample)
	error('三个文件的采样点数不一致。');
end

freq = (0:floor(n_sample / 2)) * fs / n_sample;
sfdr_db = zeros(1, numel(data));
snr_db = zeros(1, numel(data));
sinad_db = zeros(1, numel(data));
enob = zeros(1, numel(data));
tone_freq = zeros(1, numel(data));
spur_freq = zeros(1, numel(data));
spur_dbfs = zeros(1, numel(data));
tone_dbfs = zeros(1, numel(data));

figure('Name', 'DDS 波形与频谱', 'Color', 'w', ...
	'Position', [100, 100, 1600, 850]);
for k = 1:numel(data)
	samples = double(data{k});
	spectrum = abs(fft(samples)) / n_sample;
	spectrum = spectrum(1:numel(freq));
	spectrum(2:end-1) = 2 * spectrum(2:end-1);
	spectrum_dbfs = 20 * log10(max(spectrum, realmin) / 32768);

	% 排除直流后寻找载波，并排除载波相邻 bin，避免主瓣被当作杂散。
	search_spectrum = spectrum;
	search_spectrum(1) = 0;
	[tone_amplitude, tone_bin] = max(search_spectrum);
	exclusion = max(1, tone_bin - 1):min(numel(search_spectrum), tone_bin + 1);
	search_spectrum(exclusion) = 0;
	[spur_amplitude, spur_bin] = max(search_spectrum);
	% SINAD: 载波之外的全部残余功率，包含谐波失真和噪声。
	sinad_mask = true(size(spectrum));
	sinad_mask(1) = false;
	sinad_mask(exclusion) = false;
	sinad_power = sum(spectrum(sinad_mask).^2);

	% SNR: 排除基波整数次谐波后，仅统计非谐波噪声。
	noise_mask = sinad_mask;
	tone_frequency = (tone_bin - 1) * fs / n_sample;
	max_harmonic = floor((fs / 2) / max(tone_frequency, realmin));
	for harmonic = 2:max_harmonic
		harmonic_bin = round((harmonic * tone_frequency) / (fs / n_sample)) + 1;
		harmonic_exclusion = max(1, harmonic_bin - 1):min(numel(spectrum), harmonic_bin + 1);
		noise_mask(harmonic_exclusion) = false;
	end
	noise_power = sum(spectrum(noise_mask).^2);

	tone_freq(k) = tone_frequency;
	spur_freq(k) = (spur_bin - 1) * fs / n_sample;
	tone_dbfs(k) = 20 * log10(max(tone_amplitude, realmin) / 32768);
	spur_dbfs(k) = 20 * log10(max(spur_amplitude, realmin) / 32768);
	sfdr_db(k) = 20 * log10(max(tone_amplitude, realmin) / max(spur_amplitude, realmin));
	snr_db(k) = 10 * log10(max(tone_amplitude^2, realmin) / max(noise_power, realmin));
	sinad_db(k) = 10 * log10(max(tone_amplitude^2, realmin) / max(sinad_power, realmin));
	enob(k) = (sinad_db(k) - 1.76) / 6.02;

	subplot(2, 3, k);
	plot(0:min(n_sample, 4 * fs / expected_fout) - 1, ...
		samples(1:min(n_sample, 4 * fs / expected_fout)), 'LineWidth', 1);
	grid on;
	xlabel('采样点');
	ylabel('幅度');
	title([labels{k}, ' 波形']);

	subplot(2, 3, k + 3);
	plot(freq / 1e6, spectrum_dbfs, 'LineWidth', 1);
	xlim([0, 5]);
	ylim([-160, 0]);
	grid on;
	xlabel('频率 (MHz)');
	ylabel('幅度 (dBFS)');
	title(sprintf('%s 频谱, SFDR = %.2f dBc', labels{k}, sfdr_db(k)));
end
exportgraphics(gcf, fullfile(data_dir, 'dds_sfdr_analysis.png'), 'Resolution', 220);

fprintf('\nSFDR 分析结果（矩形窗，相干采样，排除直流和载波相邻 1 个 bin）：\n');
fprintf('%-8s %-14s %-14s %-14s %-12s %-12s %-12s %-10s\n', ...
	'通道', '载波频率(Hz)', '载波(dBFS)', '最大杂散(Hz)', ...
	'SFDR(dBc)', 'SNR(dB)', 'SINAD(dB)', 'ENOB(bit)');
for k = 1:numel(data)
	fprintf('%-8s %-14.0f %-14.2f %-14.0f %-12.2f %-12.2f %-12.2f %-10.2f\n', ...
		labels{k}, tone_freq(k), tone_dbfs(k), spur_freq(k), ...
		sfdr_db(k), snr_db(k), sinad_db(k), enob(k));
end
fprintf('期望输出频率: %.0f Hz，FFT 分辨率: %.0f Hz，采样点数: %d\n', ...
	expected_fout, fs / n_sample, n_sample);
fprintf('SNR 排除基波整数次谐波，SINAD 包含噪声和谐波失真；ENOB = (SINAD - 1.76) / 6.02。\n');

