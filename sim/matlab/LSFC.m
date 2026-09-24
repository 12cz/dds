lfsr_data = uint32(1);
seed = lfsr_data;
count = 0;
while true
    b23 = bitget(lfsr_data, 23);
    b18 = bitget(lfsr_data, 18);
    feedback = bitxor(b23, b18);
    lfsr_data = bitshift(lfsr_data, 1);
    lfsr_data = bitor(lfsr_data, feedback);
    lfsr_data = bitand(lfsr_data, uint32(8388607));
    count = count + 1;
    if lfsr_data == seed
        break;
    end
end
fprintf('LFSR 周期 = %d\n', count);


lfsr = uint32(1);
seed = lfsr;
count = 0;
while true
    [lfsr, ~] = lfsr_generic(lfsr, 23, 23, 18);
    count = count + 1;
    if lfsr == seed
        break;
    end
end
fprintf('LFSR 周期 = %d\n', count);