module dds_with_dither #(
    parameter P_PHASE_WIDTH         = 32    ,      // 相位累加器位宽
    parameter P_LUT_ADDR_WIDTH      = 10    ,   // ROM地址位宽
    parameter P_DITHER_WIDTH        = 8       // 抖动位宽
)(
    input                               clk         ,
    input                               rst         ,
    input    [P_PHASE_WIDTH -1:0]       i_fcw       ,
    input    [P_PHASE_WIDTH -1:0]       i_poff      ,
    output   [P_LUT_ADDR_WIDTH-1:0]     lut_addr
);

    // 相位累加器
    reg [P_PHASE_WIDTH-1:0] phase_acc;
    
    // LFSR伪随机序列发生器
    reg [P_DITHER_WIDTH-1:0] r_dither_data;
    reg [23:0]          lfsr;
    
    // 截断位数
    localparam P_TRUNC_BITS = P_PHASE_WIDTH - P_LUT_ADDR_WIDTH;
    
    // LFSR反馈抽头（8位用x^8+x^6+x^5+x^4+1）
    // wire lfsr_feedback = lfsr[7] ^ lfsr[5] ^ lfsr[4] ^ lfsr[3];
    wire lfsr_feedback = lfsr_data[23] ^ lsfr[18] + lfsr[0];
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            lfsr <= 24'h01;  // 非零种子
        end else begin
            lfsr <= {lfsr[22:0], lfsr_feedback};
        end
    end
    
    // 相位累加
    wire [P_PHASE_WIDTH-1:0] phase_next = phase_acc + fcw;
    
    always @(posedge clk or posedge rst_n) begin
        if (rst) begin
            phase_acc <= {P_PHASE_WIDTH{1'b0}};
        end else begin
            phase_acc <= phase_next + poff;
        end
    end
    
    // 抖动注入：将LFSR值扩展到截断位宽，叠加到相位上
    wire [P_PHASE_WIDTH-1:0] dither_extended;
    assign dither_extended = {{(P_TRUNC_BITS - P_DITHER_WIDTH){1'b0}}, lfsr};
    
    // 加抖动后取高位送入LUT
    wire [P_PHASE_WIDTH:0] phase_dithered;
    assign phase_dithered = {1'b0, phase_acc} + {1'b0, dither_extended};
    
    assign lut_addr = phase_dithered[P_PHASE_WIDTH-1 : P_TRUNC_BITS];
    
endmodule