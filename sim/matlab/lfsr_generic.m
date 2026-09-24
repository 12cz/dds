function [lfsr_new, dither_byte] = lfsr_generic(lfsr_old, nbits, tap1, tap2)

% LFSR_GENERIC  通用 LFSR
% 输入：
%   lfsr_old - 当前状态（uint32）
%   nbits    - 位宽（如 23）
%   tap1     - 抽头 1（如 23）
%   tap2     - 抽头 2（如 18）
% 输出：
%   lfsr_new    - 下一个状态
%   dither_byte - 高 8 位

    b1 = bitget(lfsr_old, tap1);
    b2 = bitget(lfsr_old, tap2);
    feedback = bitxor(b1, b2);

    lfsr_new = bitshift(lfsr_old, 1);
    lfsr_new = bitor(lfsr_new, feedback);

    mask = uint32(2^nbits - 1);
    lfsr_new = bitand(lfsr_new, mask);

    dither_byte = uint8(bitshift(lfsr_new, -(nbits - 8)));
end