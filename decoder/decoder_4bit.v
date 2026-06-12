`timescale 1ns / 1ps

//================================================================
// 模块说明
//================================================================
// 4 位译码器。
// 将四比特编码输入映射为参数化位宽的输出，通过纯组合逻辑实现。
// 译码表由参数固化，输出值在编译时确定，运行时不可动态改变。
//================================================================

module decoder_4bit #(
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
    parameter [CODE_OUT_WIDTH:0] OUTPUT_TABLE_7 = {CODE_OUT_WIDTH{1'b0}},
    parameter [CODE_OUT_WIDTH:0] OUTPUT_TABLE_8 = {CODE_OUT_WIDTH{1'b0}},
    parameter [CODE_OUT_WIDTH:0] OUTPUT_TABLE_9 = {CODE_OUT_WIDTH{1'b0}},
    parameter [CODE_OUT_WIDTH:0] OUTPUT_TABLE_A = {CODE_OUT_WIDTH{1'b0}},
    parameter [CODE_OUT_WIDTH:0] OUTPUT_TABLE_B = {CODE_OUT_WIDTH{1'b0}},
    parameter [CODE_OUT_WIDTH:0] OUTPUT_TABLE_C = {CODE_OUT_WIDTH{1'b0}},
    parameter [CODE_OUT_WIDTH:0] OUTPUT_TABLE_D = {CODE_OUT_WIDTH{1'b0}},
    parameter [CODE_OUT_WIDTH:0] OUTPUT_TABLE_E = {CODE_OUT_WIDTH{1'b0}},
    parameter [CODE_OUT_WIDTH:0] OUTPUT_TABLE_F = {CODE_OUT_WIDTH{1'b0}}
    
) (
    //================================================================
    // 模块输入
    //================================================================

    // 编码输入
    input  wire [3:0] code_in,

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
            4'h0:    code_out = OUTPUT_TABLE_0;
            4'h1:    code_out = OUTPUT_TABLE_1;
            4'h2:    code_out = OUTPUT_TABLE_2;
            4'h3:    code_out = OUTPUT_TABLE_3;
            4'h4:    code_out = OUTPUT_TABLE_4;
            4'h5:    code_out = OUTPUT_TABLE_5;
            4'h6:    code_out = OUTPUT_TABLE_6;
            4'h7:    code_out = OUTPUT_TABLE_7;
            4'h8:    code_out = OUTPUT_TABLE_8;
            4'h9:    code_out = OUTPUT_TABLE_9;
            4'hA:    code_out = OUTPUT_TABLE_A;
            4'hB:    code_out = OUTPUT_TABLE_B;
            4'hC:    code_out = OUTPUT_TABLE_C;
            4'hD:    code_out = OUTPUT_TABLE_D;
            4'hE:    code_out = OUTPUT_TABLE_E;
            4'hF:    code_out = OUTPUT_TABLE_F;
            default: code_out = {CODE_OUT_WIDTH{1'b0}};
        endcase
    end

endmodule
