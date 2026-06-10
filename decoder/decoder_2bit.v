`timescale 1ns / 1ps

module decoder_2bit #(
    //================================================================
    // 可选参数
    //================================================================

    // 输出位宽
    parameter [7:0] CODE_OUT_WIDTH = 1,

    // 译码表
    parameter [CODE_OUT_WIDTH:0] OUTPUT_TABLE_0 = {CODE_OUT_WIDTH{1'b0}},
    parameter [CODE_OUT_WIDTH:0] OUTPUT_TABLE_1 = {CODE_OUT_WIDTH{1'b0}},
    parameter [CODE_OUT_WIDTH:0] OUTPUT_TABLE_2 = {CODE_OUT_WIDTH{1'b0}},
    parameter [CODE_OUT_WIDTH:0] OUTPUT_TABLE_3 = {CODE_OUT_WIDTH{1'b0}}
    
) (
    //================================================================
    // 模块输入
    //================================================================

    // 编码输入
    input  wire [1:0] code_in,

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
            2'h0:    code_out = OUTPUT_TABLE_0;
            2'h1:    code_out = OUTPUT_TABLE_1;
            2'h2:    code_out = OUTPUT_TABLE_2;
            2'h3:    code_out = OUTPUT_TABLE_3;
            default: code_out = {CODE_OUT_WIDTH{1'b0}};
        endcase
    end

endmodule
