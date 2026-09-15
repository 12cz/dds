
`timescale 1ns/1ns
module dds_tb();


localparam      P_FRQ_GEN    = 100*(10**3);//100K
localparam      P_FRQ_GEN1   = 1*(10**3);//100K
localparam      P_FRQ_CLK    = 500*(10**6);//2ns
localparam      P_FCW_WIDTH  = 48;
localparam real  P_FCW_FLOAT  = P_FRQ_GEN  * (2.0**P_FCW_WIDTH) / P_FRQ_CLK;
localparam real  P_FCW_FLOAT1 = P_FRQ_GEN1 * (2.0**P_FCW_WIDTH) / P_FRQ_CLK;


reg                     clk ,rst    ;
reg                     ri_start    ;
reg  [P_FCW_WIDTH -1:0] ri_fcw      ;

wire  [15:0]            o_data      ;
wire                    o_vdlid     ;

initial begin
    clk = 0;
    forever clk = #1 ~clk;
end

initial begin
    rst = 1;
    ri_start <= 1'b0;
    ri_fcw <= 64'd0;
    #40;
    @(posedge clk)rst = 0;
    #100;
    @(posedge clk)  ri_start <= 1'b1;
                    ri_fcw <= P_FCW_FLOAT;
    @(posedge clk) ri_start <= 1'b0;
    #(10000*2);
    @(posedge clk) ri_start <= 1'b1;  
        ri_fcw <= P_FCW_FLOAT / 100;//1K
    @(posedge clk) ri_start <= 1'b0;
    #(1000000*2);
    $stop();
end



dds_top
#(
    .P_CLK_SAMPLING         (P_FRQ_CLK      ),
    .P_GEN_WAVE_FRQ         (P_FRQ_GEN      ),
    .P_FCW_WIDTH            (P_FCW_WIDTH    )
)dds_top_u1
(
    .clk                    (clk        ),
    .rst                    (rst        ),
    .i_start                ( ri_start  ),
    .i_phase_accumulator    ({P_FCW_WIDTH{1'b0}}      ),
    .i_fcw                  (ri_fcw     ),
    .o_data                 (o_data     ),
    .o_vdlid                (o_vdlid    )
);

dds_top
#(
    .P_CLK_SAMPLING         (P_FRQ_CLK      ),
    .P_GEN_WAVE_FRQ         (P_FRQ_GEN      ),
    .P_GEN_WAVE_PHASE       (0              ),
    .P_FCW_WIDTH            (P_FCW_WIDTH    ),
    .P_DITHER_WIDTH         (8              ),
    .P_DITHER_EN            (1              )
)dds_top_u2
(
    .clk                    (clk                    ),
    .rst                    (rst                    ),
    .i_start                (1'b0),
    .i_phase_accumulator    ({P_FCW_WIDTH{1'b0}}    ),
    .i_fcw                  (),
    .o_data                 (),
    .o_vdlid                ()
);


dds_top
#(
    .P_CLK_SAMPLING         (P_FRQ_CLK      ),
    .P_GEN_WAVE_FRQ         (P_FRQ_GEN      ),
    .P_GEN_WAVE_PHASE       (0              ),
    .P_FCW_WIDTH            (P_FCW_WIDTH    ),
    .P_DITHER_WIDTH         (8              ),
    .P_DITHER_EN            (0              )
)dds_top_u3
(
    .clk                    (clk                    ),
    .rst                    (rst                    ),
    .i_start                (1'b0),
    .i_phase_accumulator    ({P_FCW_WIDTH{1'b0}}    ),
    .i_fcw                  (),
    .o_data                 (),
    .o_vdlid                ()
);

endmodule