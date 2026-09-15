module dds_top
#(
    parameter   P_CLK_SAMPLING   =      100000  ,
    parameter   P_GEN_WAVE_FRQ   =      250     ,
    parameter   P_GEN_WAVE_PHASE =      0       ,//2**(P_FCW_WIDTH-1 -2),
    parameter   P_FCW_WIDTH      =      48      ,
    parameter   P_DITHER_WIDTH   =      8       ,
    parameter   P_DITHER_EN      =      1       
)
(
    input                           clk                 ,
    input                           rst                 ,

    input                           i_start             ,
    input  [P_FCW_WIDTH - 1:0]      i_phase_accumulator ,
    input  [P_FCW_WIDTH - 1:0]      i_fcw               ,

    output [15:0]                   o_data              ,
    output                          o_vdlid             
);


localparam real P_DEFUALT_FCW  =  P_GEN_WAVE_FRQ * (2.0**P_FCW_WIDTH) / P_CLK_SAMPLING ;
localparam P_LUT_ADDR_WIDTH = 10;
reg     [15             :0]     r_bram_wave[0:2**P_LUT_ADDR_WIDTH -1]     ;
wire    [9              :0]     w_addr                  ;
wire    [1              :0]     w_quad                  ;
wire    [P_LUT_ADDR_WIDTH+1:0]  w_lut_addr              ;
reg                             ri_start                ;
reg                             ri_start_d              ;
reg     [P_FCW_WIDTH - 1:0]     ri_phase_accumulator    ; 
reg     [P_FCW_WIDTH - 1:0]     ri_fcw                  ; 
reg     [15:0]                  ro_data                 ;
reg                             ro_vdlid                ;


initial begin
    $readmemh("d:/prj/DDS/rtl/sin_data16bit.txt",r_bram_wave );
end

assign o_data  = ro_data  ;
assign o_vdlid = ro_vdlid ;

always@(posedge clk)begin
    ri_start   <= i_start   ;           
    ri_start_d <= ri_start  ;           
end

always@(posedge clk or posedge rst)
begin   
    if(rst)begin   
        ri_phase_accumulator  <= P_GEN_WAVE_PHASE  ;           
        ri_fcw                <= P_DEFUALT_FCW     ; 
    end else if(ri_start == 1'b1 && ri_start_d == 1'b0)begin      
        ri_phase_accumulator  <= i_phase_accumulator ;           
        ri_fcw                <= i_fcw               ;
    end  
end       

assign  w_quad      = w_lut_addr[P_LUT_ADDR_WIDTH + 1:P_LUT_ADDR_WIDTH];
assign  w_addr      = w_lut_addr[P_LUT_ADDR_WIDTH - 1:0];

generate
    if (P_DITHER_EN == 1) begin : g_dither_on
        dds_with_dither #(
            .P_PHASE_WIDTH     (P_FCW_WIDTH        ),      // 相位累加器位宽
            .P_LUT_ADDR_WIDTH  (P_LUT_ADDR_WIDTH+2 ),   // ROM地址位宽
            .P_DITHER_WIDTH    (P_DITHER_WIDTH     )  // 抖动位宽
        ) dds_with_dither_u1(
            .clk        (clk                ) ,
            .rst        (rst                ) ,
            .i_fcw      (ri_fcw             ) ,
            .i_poff     (ri_phase_accumulator) ,
            .lut_addr   (w_lut_addr          )
        );
    end else begin : g_dither_off
        reg [P_FCW_WIDTH - 1:0] r_phase;
        always@(posedge clk or posedge rst)
        begin
            if(rst)
                r_phase <= {P_FCW_WIDTH{1'b0}};
            else if(i_start == 1'b1 && ri_start == 1'b0)
                r_phase <= ri_phase_accumulator;
            else 
                r_phase <= r_phase + ri_fcw;
        end
        assign w_lut_addr = r_phase[P_FCW_WIDTH - 1:P_FCW_WIDTH - (P_LUT_ADDR_WIDTH + 2)];
    end
endgenerate


always@(posedge clk or posedge rst)
begin
    if(rst)
        ro_data <= 'd0;
    else 
        case(w_quad) 
            2'b00:ro_data <= r_bram_wave[w_addr];
            2'b01:ro_data <= r_bram_wave[~w_addr];
            2'b10:ro_data <= ~r_bram_wave[w_addr];
            2'b11:ro_data <= ~r_bram_wave[~w_addr];
        endcase      
end

always@(posedge clk or posedge rst)
begin
    if(rst)
        ro_vdlid <= 'd0;
    else if(ri_start == 1'b1 && ri_start_d == 1'b0)  
        ro_vdlid <= 'd1;
end


endmodule