//======================================================================
// 普通 DDS（1/4 端点采样正弦表, 无抖动无泰勒, 作为对比基准）
// 表  : 1024x16 ROM, tbl[i] = sin(i/1024*pi/2), i=0..1023 (含0, 不含90°峰值)
// 相位: P_FCW_WIDTH 位累加器 -> 高2位象限 + 10位地址
// 流水: 2 级 (ROM读 -> 符号化输出)
//======================================================================
module dds
#(
    parameter   P_CLK_SAMPLING   = 100000,             // 采样时钟(Hz)
    parameter   P_GEN_WAVE_FRQ   = 250,                // 默认输出频率(Hz)
    parameter   P_GEN_WAVE_PHASE = 0,                  // 默认初始相位
    parameter   P_FCW_WIDTH      = 48,                 // 相位累加器位宽
    parameter   P_INIT_FILE      = "sin_data16bit.txt" // ROM 初始化文件
)
(
    input                           i_clk               ,
    input                           i_rst               ,
    input                           i_start             ,
    input  [P_FCW_WIDTH - 1:0]      i_phase_accumulator ,
    input  [P_FCW_WIDTH - 1:0]      i_fcw               ,

    output [15:0]                   o_data              ,
    output                          o_vdlid             
);

    //---------------- 参数 ----------------
    localparam P_LUT_ADDR_WIDTH = 10;                 // 1/4 表地址位宽
    localparam P_DATA_WIDTH     = 16;                 // 表值位宽
    // 90° 峰值 = 2^15-1 = 16'h7FFF (端点采样表中不含峰值, 反射时特判)
    localparam [P_DATA_WIDTH-1:0] P_PEAK = {1'b0,{(P_DATA_WIDTH-1){1'b1}}};
    localparam real P_DEFAULT_FCW = P_GEN_WAVE_FRQ * (2.0**P_FCW_WIDTH) / P_CLK_SAMPLING;

    //---------------- ROM(端点采样表) ----------------
    reg [P_DATA_WIDTH-1:0] r_bram_wave[0:2**P_LUT_ADDR_WIDTH-1];
    initial $readmemh(P_INIT_FILE, r_bram_wave);

    //---------------- 相位累加器 ----------------
    reg [P_FCW_WIDTH-1:0] r_phase;
    reg [P_FCW_WIDTH-1:0] r_fcw;
    reg r_start_d1;
    always @(posedge i_clk) r_start_d1 <= i_start;
    wire w_start_pulse = i_start & ~r_start_d1;

    always @(posedge i_clk or posedge i_rst) begin
        if (i_rst) begin
            r_phase <= P_GEN_WAVE_PHASE;
            r_fcw   <= P_DEFAULT_FCW;
        end else if (w_start_pulse) begin
            r_phase <= i_phase_accumulator;
            r_fcw   <= i_fcw;
        end else begin
            r_phase <= r_phase + r_fcw;
        end
    end

    //---------------- 相位译码 ----------------
    wire [1:0]                  w_quad     = r_phase[P_FCW_WIDTH-1 : P_FCW_WIDTH-2];
    wire [P_LUT_ADDR_WIDTH-1:0] w_addr     = r_phase[P_FCW_WIDTH-3 : P_FCW_WIDTH-2-P_LUT_ADDR_WIDTH];
    wire [P_LUT_ADDR_WIDTH:0]   w_addr_ref = {1'b0, ~w_addr} + 1'b1;   // = 1024-addr
    wire                        w_is_peak  = (w_addr == {P_LUT_ADDR_WIDTH{1'b0}});
    // 象限 0/2 读正向地址, 象限 1/3 读反射地址(addr==0 特判峰值)
    wire [P_LUT_ADDR_WIDTH-1:0] w_rom_addr = w_quad[0] ? w_addr_ref[P_LUT_ADDR_WIDTH-1:0] : w_addr;
    wire                        w_use_peak = w_quad[0] & w_is_peak;

    //---------------- 第1级流水: ROM 读 ----------------
    reg signed [P_DATA_WIDTH-1:0] r_sin_mag;
    reg [1:0]                     r_quad;
    always @(posedge i_clk or posedge i_rst) begin
        if (i_rst) begin
            r_sin_mag <= 0;
            r_quad    <= 0;
        end else begin
            r_sin_mag <= w_use_peak ? P_PEAK : r_bram_wave[w_rom_addr];
            r_quad    <= w_quad;
        end
    end

    //---------------- 第2级流水: 符号化输出 ----------------
    reg signed [P_DATA_WIDTH-1:0] ro_data;
    always @(posedge i_clk or posedge i_rst) begin
        if (i_rst)      ro_data <= 0;
        else            case (r_quad)
                            2'd0, 2'd1: ro_data <=  r_sin_mag;
                            2'd2, 2'd3: ro_data <= -r_sin_mag;
                            default:    ro_data <= 0;
                        endcase
    end

    //---------------- valid(对齐 2 级流水) ----------------
    reg r_valid;
    always @(posedge i_clk or posedge i_rst) begin
        if (i_rst)          r_valid <= 1'b0;
        else if (w_start_pulse) r_valid <= 1'b1;
    end
    reg [1:0] r_valid_d;
    always @(posedge i_clk or posedge i_rst) begin
        if (i_rst)          r_valid_d <= 2'b0;
        else                r_valid_d <= {r_valid_d[0], r_valid};
    end

    assign o_data  = ro_data;
    assign o_vdlid = r_valid_d[1];

endmodule