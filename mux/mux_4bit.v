`timescale 1ns / 1ps

//================================================================
// 模块说明
//================================================================
// 16 选 1 多路选择器。
// 基于 4 位选择信号从十六路输入中选取一路输出。
// 支持参数化数据位宽。
//================================================================

module mux_4bit #(
    //================================================================
    // 可选参数
    //================================================================

    // 数据位宽，单位为 bit
    parameter [7:0] DATA_WIDTH = 1
    
) (
    //================================================================
    // 模块输入
    //================================================================

    // 二进制编码选择信号
    input  wire [3:0] sel,

    // 输入数据
    input  wire [DATA_WIDTH - 1:0] data_in_0,
    input  wire [DATA_WIDTH - 1:0] data_in_1,
    input  wire [DATA_WIDTH - 1:0] data_in_2,
    input  wire [DATA_WIDTH - 1:0] data_in_3,
    input  wire [DATA_WIDTH - 1:0] data_in_4,
    input  wire [DATA_WIDTH - 1:0] data_in_5,
    input  wire [DATA_WIDTH - 1:0] data_in_6,
    input  wire [DATA_WIDTH - 1:0] data_in_7,
    input  wire [DATA_WIDTH - 1:0] data_in_8,
    input  wire [DATA_WIDTH - 1:0] data_in_9,
    input  wire [DATA_WIDTH - 1:0] data_in_A,
    input  wire [DATA_WIDTH - 1:0] data_in_B,
    input  wire [DATA_WIDTH - 1:0] data_in_C,
    input  wire [DATA_WIDTH - 1:0] data_in_D,
    input  wire [DATA_WIDTH - 1:0] data_in_E,
    input  wire [DATA_WIDTH - 1:0] data_in_F,

    //================================================================
    // 模块输出
    //================================================================

    // 选中的输出数据
    output reg  [DATA_WIDTH - 1:0] data_out

);

    //================================================================
    // 组合逻辑
    //================================================================

    always @(*) begin
        case (sel)
            4'h0:    data_out = data_in_0;
            4'h1:    data_out = data_in_1;
            4'h2:    data_out = data_in_2;
            4'h3:    data_out = data_in_3;
            4'h4:    data_out = data_in_4;
            4'h5:    data_out = data_in_5;
            4'h6:    data_out = data_in_6;
            4'h7:    data_out = data_in_7;
            4'h8:    data_out = data_in_8;
            4'h9:    data_out = data_in_9;
            4'hA:    data_out = data_in_A;
            4'hB:    data_out = data_in_B;
            4'hC:    data_out = data_in_C;
            4'hD:    data_out = data_in_D;
            4'hE:    data_out = data_in_E;
            4'hF:    data_out = data_in_F;
            default: data_out = {DATA_WIDTH{1'b0}};
        endcase
    end

endmodule
