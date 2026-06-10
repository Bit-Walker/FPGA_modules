`timescale 1ns / 1ps

module decoder_3bit #(
    //================================================================
    // 可选参数
    //================================================================

    // 输出位宽
    parameter [7:0] CODE_OUT_WIDTH = 1,

    // 译码表
    parameter [CODE_OUT_WIDTH:0] OUTPUT_TABLE_0 = {CODE_OUT_WIDTH{1'b0}},
    parameter [CODE_OUT_WIDTH:0] OUTPUT_TABLE_1 = {CODE_OUT_WIDTH{1'b0}},
    parameter [CODE_OUT_WIDTH:0] OUTPUT_TABLE_2 = {CODE_OUT_WIDTH{1'b0}},
    parameter [CODE_OUT_WIDTH:0] OUTPUT_TABLE_3 = {CODE_OUT_WIDTH{1'b0}},
    parameter [CODE_OUT_WIDTH:0] OUTPUT_TABLE_4 = {CODE_OUT_WIDTH{1'b0}},
    parameter [CODE_OUT_WIDTH:0] OUTPUT_TABLE_5 = {CODE_OUT_WIDTH{1'b0}},
    parameter [CODE_OUT_WIDTH:0] OUTPUT_TABLE_6 = {CODE_OUT_WIDTH{1'b0}},
    parameter [CODE_OUT_WIDTH:0] OUTPUT_TABLE_7 = {CODE_OUT_WIDTH{1'b0}}
    
) (
    //================================================================
    // 模块输入
    //================================================================

    // 编码输入
    input  wire [2:0] code_in,

    //================================================================
    // 模块输出
    //================================================================

    // 译码输出
    output reg  [CODE_OUT_WIDTH - 1:0] code_out
    
);

    //================================================================
    // 组合逻辑
    //================================================================

    always @(*) begin
        case (code_in)
            3'h0:    code_out = OUTPUT_TABLE_0;
            3'h1:    code_out = OUTPUT_TABLE_1;
            3'h2:    code_out = OUTPUT_TABLE_2;
            3'h3:    code_out = OUTPUT_TABLE_3;
            3'h4:    code_out = OUTPUT_TABLE_4;
            3'h5:    code_out = OUTPUT_TABLE_5;
            3'h6:    code_out = OUTPUT_TABLE_6;
            3'h7:    code_out = OUTPUT_TABLE_7;
            default: code_out = {CODE_OUT_WIDTH{1'b0}};
        endcase
    end

endmodule
