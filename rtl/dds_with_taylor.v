//======================================================================
// 泰勒补偿 DDS（1/4 端点采样正弦表 + 一阶泰勒插值）
// 表  : 1024x16 ROM, tbl[i] = sin(i/1024*pi/2), i=0..1023 (含 0, 不含 90°峰值)
// 相位: P_FCW_WIDTH 位累加器 -> 高2位象限 + 10位地址 + 低36位(取高10位做 eps)
// 泰勒: out = s + c*eps*(pi/2)/1024 = s + (c*eps_int*3217)>>>31
// 流水: 3 级 (ROM读 -> 符号化+泰勒项 -> 求和输出)
//======================================================================
module dds_with_taylor
#(
    parameter   P_CLK_SAMPLING   = 100000,             // 采样时钟(Hz)
    parameter   P_GEN_WAVE_FRQ   = 250,                // 默认输出频率(Hz)
    parameter   P_GEN_WAVE_PHASE = 0,                  // 默认初始相位
    parameter   P_FCW_WIDTH      = 48,                 // 相位累加器位宽
    parameter   P_TAYLOR_EN      = 1,                  // 1=使能泰勒补偿
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
    localparam P_EPS_WIDTH      = 10;                 // 泰勒插值小数 eps 位宽
    // 90° 峰值 = 2^15-1 = 16'h7FFF (端点采样表中不含峰值, 反射时特判)
    localparam [P_DATA_WIDTH-1:0] P_PEAK = {1'b0,{(P_DATA_WIDTH-1){1'b1}}};
    // 泰勒常数: delta = c*eps*(pi/2)/1024 = (c*eps_int*K)>>>SHIFT
    //   eps_int 为 P_EPS_WIDTH 位, K = round(pi*2^P_EPS_WIDTH) = 3217
    //   SHIFT = 21 + P_EPS_WIDTH = 31
    localparam signed [P_EPS_WIDTH+2:0] TAYLOR_K = 3217;
    localparam TAYLOR_SHIFT = 21 + P_EPS_WIDTH;
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
    wire [1:0]                  w_quad = r_phase[P_FCW_WIDTH-1 : P_FCW_WIDTH-2];
    wire [P_LUT_ADDR_WIDTH-1:0] w_addr = r_phase[P_FCW_WIDTH-3 : P_FCW_WIDTH-2-P_LUT_ADDR_WIDTH];
    wire [P_EPS_WIDTH-1:0]      w_eps  = r_phase[P_FCW_WIDTH-3-P_LUT_ADDR_WIDTH : P_FCW_WIDTH-2-P_LUT_ADDR_WIDTH-P_EPS_WIDTH];
    // 端点采样反射地址 = 1024-addr = ~addr+1 (11位);
    // addr==0 时结果=1024(超出10位表范围), 由 w_is_peak 特判为峰值
    wire [P_LUT_ADDR_WIDTH:0]   w_addr_ref = {1'b0, ~w_addr} + 1'b1;
    wire                        w_is_peak  = (w_addr == {P_LUT_ADDR_WIDTH{1'b0}});

    //---------------- 第1级流水: ROM 双端口读 ----------------
    reg signed [P_DATA_WIDTH-1:0] r_sin_mag;
    reg signed [P_DATA_WIDTH-1:0] r_cos_mag;
    reg [P_EPS_WIDTH-1:0]         r_eps;
    reg [1:0]                     r_quad;
    always @(posedge i_clk or posedge i_rst) begin
        if (i_rst) begin
            r_sin_mag <= 0;
            r_cos_mag <= 0;
            r_eps     <= 0;
            r_quad    <= 0;
        end else begin
            r_sin_mag <= r_bram_wave[w_addr];
            r_cos_mag <= w_is_peak ? P_PEAK : r_bram_wave[w_addr_ref[P_LUT_ADDR_WIDTH-1:0]];
            r_eps     <= w_eps;
            r_quad    <= w_quad;
        end
    end

    //---------------- 第2级流水: 符号化 sin/cos + 泰勒项 ----------------
    reg signed [P_DATA_WIDTH-1:0] w_sin_s;
    reg signed [P_DATA_WIDTH-1:0] w_cos_s;
    always @(*) begin
        case (r_quad)
            2'd0: begin w_sin_s =  r_sin_mag; w_cos_s =  r_cos_mag; end
            2'd1: begin w_sin_s =  r_cos_mag; w_cos_s = -r_sin_mag; end
            2'd2: begin w_sin_s = -r_sin_mag; w_cos_s = -r_cos_mag; end
            2'd3: begin w_sin_s = -r_cos_mag; w_cos_s =  r_sin_mag; end
            default: begin w_sin_s = 0; w_cos_s = 0; end
        endcase
    end

    wire signed [P_EPS_WIDTH:0]              w_eps_s = {1'b0, r_eps};   // 11位, 非负
    wire signed [P_DATA_WIDTH+P_EPS_WIDTH:0] w_mul1  = w_cos_s * w_eps_s;   // 16x11=27位
    wire signed [P_DATA_WIDTH+2*P_EPS_WIDTH+3:0] w_mul2 = w_mul1 * TAYLOR_K; // 27x13=40位
    wire signed [P_DATA_WIDTH-1:0]           w_delta = w_mul2 >>> TAYLOR_SHIFT;

    reg signed [P_DATA_WIDTH-1:0] r_sin_s;
    reg signed [P_DATA_WIDTH-1:0] r_delta;
    always @(posedge i_clk or posedge i_rst) begin
        if (i_rst) begin
            r_sin_s <= 0;
            r_delta <= 0;
        end else begin
            r_sin_s <= w_sin_s;
            r_delta <= w_delta;
        end
    end

    //---------------- 第3级流水: 求和输出 ----------------
    reg signed [P_DATA_WIDTH-1:0] ro_data;
    always @(posedge i_clk or posedge i_rst) begin
        if (i_rst)      ro_data <= 0;
        else            ro_data <= P_TAYLOR_EN ? (r_sin_s + r_delta) : r_sin_s;
    end

    //---------------- valid(对齐 3 级流水) ----------------
    reg r_valid;
    always @(posedge i_clk or posedge i_rst) begin
        if (i_rst)          r_valid <= 1'b0;
        else if (w_start_pulse) r_valid <= 1'b1;
    end
    reg [2:0] r_valid_d;
    always @(posedge i_clk or posedge i_rst) begin
        if (i_rst)          r_valid_d <= 3'b0;
        else                r_valid_d <= {r_valid_d[1:0], r_valid};
    end

    assign o_data  = ro_data;
    assign o_vdlid = r_valid_d[2];

endmodule