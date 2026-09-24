
`timescale 1ns/1ns
module dds_tb();

    localparam P_FCW_WIDTH  = 48;
    localparam P_FRQ_CLK    = 500_000_000;       // 500MHz, 2ns 时钟
    localparam P_FRQ_GEN    = P_FRQ_CLK / 1000;  // 500kHz, 采样:输出 = 1000:1
    localparam real P_FCW_REAL = P_FRQ_GEN * (2.0**P_FCW_WIDTH) / P_FRQ_CLK;  // = 2^48/1000
    localparam P_N_CYCLE    = 10;                // 输出周期数
    localparam P_N_SAMPLE   = 1000 * P_N_CYCLE;  // 10000 个采样/通道
    localparam P_INIT_FILE  = "d:/prj/DDS/rtl/sin_data16bit.txt";

    reg                    clk, rst;
    reg                    ri_start;
    reg [P_FCW_WIDTH-1:0]  ri_fcw;

    wire [15:0] o_data_dds, o_data_dither, o_data_taylor;
    wire        o_vld_dds,  o_vld_dither,  o_vld_taylor;

    // 2ns 时钟
    initial begin
        clk = 0;
        forever #1 clk = ~clk;
    end

    // 三个输出文件
    integer fd_dds, fd_dither, fd_taylor;
    integer cnt_dds, cnt_dither, cnt_taylor;
    initial begin
        fd_dds    = $fopen("d:/prj/DDS/sim/FPGA/dds_data.txt",    "w");
        fd_dither = $fopen("d:/prj/DDS/sim/FPGA/dither_data.txt", "w");
        fd_taylor = $fopen("d:/prj/DDS/sim/FPGA/taylor_data.txt", "w");
        cnt_dds = 0; cnt_dither = 0; cnt_taylor = 0;
    end

    // 各通道独立抓取 P_N_SAMPLE 个采样(16位有符号, 符号扩展到32位写文件)
    always @(posedge clk) begin
        if (o_vld_dds && cnt_dds < P_N_SAMPLE) begin
            $fwrite(fd_dds, "%d\n", $signed({{16{o_data_dds[15]}}, o_data_dds}));
            cnt_dds <= cnt_dds + 1;
        end
        if (o_vld_dither && cnt_dither < P_N_SAMPLE) begin
            $fwrite(fd_dither, "%d\n", $signed({{16{o_data_dither[15]}}, o_data_dither}));
            cnt_dither <= cnt_dither + 1;
        end
        if (o_vld_taylor && cnt_taylor < P_N_SAMPLE) begin
            $fwrite(fd_taylor, "%d\n", $signed({{16{o_data_taylor[15]}}, o_data_taylor}));
            cnt_taylor <= cnt_taylor + 1;
        end
    end

    // 三路都采满 -> 关文件结束
    always @(posedge clk) begin
        if (cnt_dds >= P_N_SAMPLE && cnt_dither >= P_N_SAMPLE && cnt_taylor >= P_N_SAMPLE) begin
            $fclose(fd_dds); $fclose(fd_dither); $fclose(fd_taylor);
            $display("完成: 每通道 %0d 个采样(10周期)已写入 dds_data.txt/dither_data.txt/taylor_data.txt", P_N_SAMPLE);
            $finish;
        end
    end

    // 看门狗
    initial begin
        #(P_N_SAMPLE * 4);
        $display("超时");
        $finish;
    end

    // 激励: 复位 -> 释放 -> 启动脉冲加载 FCW
    initial begin
        rst = 1; ri_start = 0; ri_fcw = 0;
        #40;
        @(posedge clk); rst <= 0;
        #100;
        @(posedge clk); ri_start <= 1; ri_fcw <= P_FCW_REAL + 0.5;
        @(posedge clk); ri_start <= 0;
    end

    //---- 三个 DDS 实例 ----
    dds #(
        .P_CLK_SAMPLING(P_FRQ_CLK),
        .P_GEN_WAVE_FRQ(P_FRQ_GEN),
        .P_FCW_WIDTH   (P_FCW_WIDTH),
        .P_INIT_FILE   (P_INIT_FILE)
    ) u_dds (
        .i_clk(clk), .i_rst(rst), .i_start(ri_start),
        .i_phase_accumulator({P_FCW_WIDTH{1'b0}}), .i_fcw(ri_fcw),
        .o_data(o_data_dds), .o_vdlid(o_vld_dds)
    );

    dds_with_dither #(
        .P_CLK_SAMPLING(P_FRQ_CLK),
        .P_GEN_WAVE_FRQ(P_FRQ_GEN),
        .P_FCW_WIDTH   (P_FCW_WIDTH),
        .P_DITHER_EN   (1),
        .P_INIT_FILE   (P_INIT_FILE)
    ) u_dither (
        .i_clk(clk), .i_rst(rst), .i_start(ri_start),
        .i_phase_accumulator({P_FCW_WIDTH{1'b0}}), .i_fcw(ri_fcw),
        .o_data(o_data_dither), .o_vdlid(o_vld_dither)
    );

    dds_with_taylor #(
        .P_CLK_SAMPLING(P_FRQ_CLK),
        .P_GEN_WAVE_FRQ(P_FRQ_GEN),
        .P_FCW_WIDTH   (P_FCW_WIDTH),
        .P_TAYLOR_EN   (1),
        .P_INIT_FILE   (P_INIT_FILE)
    ) u_taylor (
        .i_clk(clk), .i_rst(rst), .i_start(ri_start),
        .i_phase_accumulator({P_FCW_WIDTH{1'b0}}), .i_fcw(ri_fcw),
        .o_data(o_data_taylor), .o_vdlid(o_vld_taylor)
    );

endmodule