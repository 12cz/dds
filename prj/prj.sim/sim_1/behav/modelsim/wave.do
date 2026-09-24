onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /dds_tb/clk
add wave -noupdate /dds_tb/rst
add wave -noupdate /dds_tb/ri_start
add wave -noupdate /dds_tb/ri_fcw
add wave -noupdate /dds_tb/o_data_dds
add wave -noupdate /dds_tb/o_data_dither
add wave -noupdate /dds_tb/o_data_taylor
add wave -noupdate /dds_tb/o_vld_dds
add wave -noupdate /dds_tb/o_vld_dither
add wave -noupdate /dds_tb/o_vld_taylor
add wave -noupdate /dds_tb/fd_dds
add wave -noupdate /dds_tb/fd_dither
add wave -noupdate /dds_tb/fd_taylor
add wave -noupdate /dds_tb/cnt_dds
add wave -noupdate /dds_tb/cnt_dither
add wave -noupdate /dds_tb/cnt_taylor
add wave -noupdate /glbl/GSR
add wave -noupdate -expand -group dds /dds_tb/u_dds/P_CLK_SAMPLING
add wave -noupdate -expand -group dds /dds_tb/u_dds/P_GEN_WAVE_FRQ
add wave -noupdate -expand -group dds /dds_tb/u_dds/P_GEN_WAVE_PHASE
add wave -noupdate -expand -group dds /dds_tb/u_dds/P_FCW_WIDTH
add wave -noupdate -expand -group dds /dds_tb/u_dds/P_INIT_FILE
add wave -noupdate -expand -group dds /dds_tb/u_dds/P_LUT_ADDR_WIDTH
add wave -noupdate -expand -group dds /dds_tb/u_dds/P_DATA_WIDTH
add wave -noupdate -expand -group dds /dds_tb/u_dds/P_PEAK
add wave -noupdate -expand -group dds /dds_tb/u_dds/P_DEFAULT_FCW
add wave -noupdate -expand -group dds /dds_tb/u_dds/i_clk
add wave -noupdate -expand -group dds /dds_tb/u_dds/i_rst
add wave -noupdate -expand -group dds /dds_tb/u_dds/i_start
add wave -noupdate -expand -group dds /dds_tb/u_dds/i_phase_accumulator
add wave -noupdate -expand -group dds /dds_tb/u_dds/i_fcw
add wave -noupdate -expand -group dds /dds_tb/u_dds/o_data
add wave -noupdate -expand -group dds /dds_tb/u_dds/o_vdlid
add wave -noupdate -expand -group dds /dds_tb/u_dds/r_bram_wave
add wave -noupdate -expand -group dds /dds_tb/u_dds/r_phase
add wave -noupdate -expand -group dds /dds_tb/u_dds/r_fcw
add wave -noupdate -expand -group dds /dds_tb/u_dds/r_start_d1
add wave -noupdate -expand -group dds /dds_tb/u_dds/w_start_pulse
add wave -noupdate -expand -group dds /dds_tb/u_dds/w_quad
add wave -noupdate -expand -group dds /dds_tb/u_dds/w_addr
add wave -noupdate -expand -group dds /dds_tb/u_dds/w_addr_ref
add wave -noupdate -expand -group dds /dds_tb/u_dds/w_is_peak
add wave -noupdate -expand -group dds /dds_tb/u_dds/w_rom_addr
add wave -noupdate -expand -group dds /dds_tb/u_dds/w_use_peak
add wave -noupdate -expand -group dds /dds_tb/u_dds/r_sin_mag
add wave -noupdate -expand -group dds /dds_tb/u_dds/r_quad
add wave -noupdate -expand -group dds /dds_tb/u_dds/ro_data
add wave -noupdate -expand -group dds /dds_tb/u_dds/r_valid
add wave -noupdate -expand -group dds /dds_tb/u_dds/r_valid_d
add wave -noupdate -expand -group dds_dither /dds_tb/u_dither/P_CLK_SAMPLING
add wave -noupdate -expand -group dds_dither /dds_tb/u_dither/P_GEN_WAVE_FRQ
add wave -noupdate -expand -group dds_dither /dds_tb/u_dither/P_GEN_WAVE_PHASE
add wave -noupdate -expand -group dds_dither /dds_tb/u_dither/P_FCW_WIDTH
add wave -noupdate -expand -group dds_dither /dds_tb/u_dither/P_DITHER_EN
add wave -noupdate -expand -group dds_dither /dds_tb/u_dither/P_INIT_FILE
add wave -noupdate -expand -group dds_dither /dds_tb/u_dither/P_LUT_ADDR_WIDTH
add wave -noupdate -expand -group dds_dither /dds_tb/u_dither/P_DATA_WIDTH
add wave -noupdate -expand -group dds_dither /dds_tb/u_dither/P_LFSR_WIDTH
add wave -noupdate -expand -group dds_dither /dds_tb/u_dither/P_LFSR_TAP1
add wave -noupdate -expand -group dds_dither /dds_tb/u_dither/P_LFSR_TAP2
add wave -noupdate -expand -group dds_dither /dds_tb/u_dither/P_DITHER_WIDTH
add wave -noupdate -expand -group dds_dither /dds_tb/u_dither/P_ADDR_SHIFT
add wave -noupdate -expand -group dds_dither /dds_tb/u_dither/P_PEAK
add wave -noupdate -expand -group dds_dither /dds_tb/u_dither/P_DEFAULT_FCW
add wave -noupdate -expand -group dds_dither /dds_tb/u_dither/i_clk
add wave -noupdate -expand -group dds_dither /dds_tb/u_dither/i_rst
add wave -noupdate -expand -group dds_dither /dds_tb/u_dither/i_start
add wave -noupdate -expand -group dds_dither /dds_tb/u_dither/i_phase_accumulator
add wave -noupdate -expand -group dds_dither /dds_tb/u_dither/i_fcw
add wave -noupdate -expand -group dds_dither /dds_tb/u_dither/o_data
add wave -noupdate -expand -group dds_dither /dds_tb/u_dither/o_vdlid
add wave -noupdate -expand -group dds_dither /dds_tb/u_dither/r_bram_wave
add wave -noupdate -expand -group dds_dither /dds_tb/u_dither/r_phase
add wave -noupdate -expand -group dds_dither /dds_tb/u_dither/r_fcw
add wave -noupdate -expand -group dds_dither /dds_tb/u_dither/r_start_d1
add wave -noupdate -expand -group dds_dither /dds_tb/u_dither/w_start_pulse
add wave -noupdate -expand -group dds_dither /dds_tb/u_dither/r_lfsr
add wave -noupdate -expand -group dds_dither /dds_tb/u_dither/w_lfsr_fb
add wave -noupdate -expand -group dds_dither /dds_tb/u_dither/w_dither_byte
add wave -noupdate -expand -group dds_dither /dds_tb/u_dither/w_dither_c
add wave -noupdate -expand -group dds_dither /dds_tb/u_dither/w_dither
add wave -noupdate -expand -group dds_dither /dds_tb/u_dither/w_phase_dither
add wave -noupdate -expand -group dds_dither /dds_tb/u_dither/w_quad
add wave -noupdate -expand -group dds_dither /dds_tb/u_dither/w_addr
add wave -noupdate -expand -group dds_dither /dds_tb/u_dither/w_addr_ref
add wave -noupdate -expand -group dds_dither /dds_tb/u_dither/w_is_peak
add wave -noupdate -expand -group dds_dither /dds_tb/u_dither/w_rom_addr
add wave -noupdate -expand -group dds_dither /dds_tb/u_dither/w_use_peak
add wave -noupdate -expand -group dds_dither /dds_tb/u_dither/r_sin_mag
add wave -noupdate -expand -group dds_dither /dds_tb/u_dither/r_quad
add wave -noupdate -expand -group dds_dither /dds_tb/u_dither/ro_data
add wave -noupdate -expand -group dds_dither /dds_tb/u_dither/r_valid
add wave -noupdate -expand -group dds_dither /dds_tb/u_dither/r_valid_d
add wave -noupdate -group dds_taylor /dds_tb/u_taylor/P_CLK_SAMPLING
add wave -noupdate -group dds_taylor /dds_tb/u_taylor/P_GEN_WAVE_FRQ
add wave -noupdate -group dds_taylor /dds_tb/u_taylor/P_GEN_WAVE_PHASE
add wave -noupdate -group dds_taylor /dds_tb/u_taylor/P_FCW_WIDTH
add wave -noupdate -group dds_taylor /dds_tb/u_taylor/P_TAYLOR_EN
add wave -noupdate -group dds_taylor /dds_tb/u_taylor/P_INIT_FILE
add wave -noupdate -group dds_taylor /dds_tb/u_taylor/P_LUT_ADDR_WIDTH
add wave -noupdate -group dds_taylor /dds_tb/u_taylor/P_DATA_WIDTH
add wave -noupdate -group dds_taylor /dds_tb/u_taylor/P_EPS_WIDTH
add wave -noupdate -group dds_taylor /dds_tb/u_taylor/P_PEAK
add wave -noupdate -group dds_taylor /dds_tb/u_taylor/TAYLOR_K
add wave -noupdate -group dds_taylor /dds_tb/u_taylor/TAYLOR_SHIFT
add wave -noupdate -group dds_taylor /dds_tb/u_taylor/P_DEFAULT_FCW
add wave -noupdate -group dds_taylor /dds_tb/u_taylor/i_clk
add wave -noupdate -group dds_taylor /dds_tb/u_taylor/i_rst
add wave -noupdate -group dds_taylor /dds_tb/u_taylor/i_start
add wave -noupdate -group dds_taylor /dds_tb/u_taylor/i_phase_accumulator
add wave -noupdate -group dds_taylor /dds_tb/u_taylor/i_fcw
add wave -noupdate -group dds_taylor /dds_tb/u_taylor/o_data
add wave -noupdate -group dds_taylor /dds_tb/u_taylor/o_vdlid
add wave -noupdate -group dds_taylor /dds_tb/u_taylor/r_bram_wave
add wave -noupdate -group dds_taylor /dds_tb/u_taylor/r_phase
add wave -noupdate -group dds_taylor /dds_tb/u_taylor/r_fcw
add wave -noupdate -group dds_taylor /dds_tb/u_taylor/r_start_d1
add wave -noupdate -group dds_taylor /dds_tb/u_taylor/w_start_pulse
add wave -noupdate -group dds_taylor /dds_tb/u_taylor/w_quad
add wave -noupdate -group dds_taylor /dds_tb/u_taylor/w_addr
add wave -noupdate -group dds_taylor /dds_tb/u_taylor/w_eps
add wave -noupdate -group dds_taylor /dds_tb/u_taylor/w_addr_ref
add wave -noupdate -group dds_taylor /dds_tb/u_taylor/w_is_peak
add wave -noupdate -group dds_taylor /dds_tb/u_taylor/r_sin_mag
add wave -noupdate -group dds_taylor /dds_tb/u_taylor/r_cos_mag
add wave -noupdate -group dds_taylor /dds_tb/u_taylor/r_eps
add wave -noupdate -group dds_taylor /dds_tb/u_taylor/r_quad
add wave -noupdate -group dds_taylor /dds_tb/u_taylor/w_sin_s
add wave -noupdate -group dds_taylor /dds_tb/u_taylor/w_cos_s
add wave -noupdate -group dds_taylor /dds_tb/u_taylor/w_eps_s
add wave -noupdate -group dds_taylor /dds_tb/u_taylor/w_mul1
add wave -noupdate -group dds_taylor /dds_tb/u_taylor/w_mul2
add wave -noupdate -group dds_taylor /dds_tb/u_taylor/w_delta
add wave -noupdate -group dds_taylor /dds_tb/u_taylor/r_sin_s
add wave -noupdate -group dds_taylor /dds_tb/u_taylor/r_delta
add wave -noupdate -group dds_taylor /dds_tb/u_taylor/ro_data
add wave -noupdate -group dds_taylor /dds_tb/u_taylor/r_valid
add wave -noupdate -group dds_taylor /dds_tb/u_taylor/r_valid_d
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {5194 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 150
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {0 ps} {18478 ps}
