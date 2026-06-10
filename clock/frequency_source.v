`timescale 1ns / 1ps

module frequency_source #(
    //================================================================
    // 可选参数
    //================================================================

    // 频率值位宽，范围 1 ~ 64，单位为 bit
    parameter [7:0]  FREQ_WIDTH = 32,
    // 系统时钟频率，单位为 Hz
    parameter [31:0] CLK_FREQ   = 50_000_000,

    //================================================================
    // 自动计算参数
    //================================================================

    // 最大分频系数
    parameter [127:0] MAX_DIV_VALUE = CLK_FREQ / 2,
    // 分频计数器宽度
    parameter [7:0]   DIV_WIDTH     = clog2(MAX_DIV_VALUE + 1)
) (
    //================================================================
    // 模块输入
    //================================================================

    // 系统时钟
    input  wire clk,
    // 高电平有效异步复位
    input  wire rst,

    // 目标频率设置为 0 时输出保持低电平
    // 目标频率超过 CLK_FREQ / 2 时输出保持高电平

    // 目标频率，单位为 Hz
    input  wire [FREQ_WIDTH - 1:0] target_freq,

    //================================================================
    // 模块输出
    //================================================================

    // 频率输出
    output reg  freq_out
);

    //================================================================
    // 函数声明
    //================================================================

    // 计算 log2 函数
    function integer clog2;
        input [127:0] value;
        reg   [127:0] value_minus_one;
        begin
            value_minus_one = value - 1'b1;
            for (clog2 = 0; value_minus_one > 0; clog2 = clog2 + 1) begin
                value_minus_one = value_minus_one >> 1;
            end
        end
    endfunction

    // 计算目标分频系数
    function [DIV_WIDTH - 1:0] calc_div_value;
        input [FREQ_WIDTH - 1:0] freq_value;
        reg   [127:0] double_freq;
        reg   [127:0] div_value;
        begin
            double_freq = {1'b0, freq_value} << 1;
            if (freq_value == {FREQ_WIDTH{1'b0}}) begin
                // 目标频率为 0 时
                div_value = 0;
            end else if (double_freq > CLK_FREQ) begin
                // 目标频率超过 CLK_FREQ / 2 时
                div_value = 0;
            end else begin
                div_value = CLK_FREQ / double_freq;
            end
            calc_div_value = div_value[DIV_WIDTH - 1:0];
        end
    endfunction

    //================================================================
    // 寄存器声明
    //================================================================

    // 当前分频系数
    reg [DIV_WIDTH - 1:0]  div_value;
    // 上一次锁存的频率值
    reg [FREQ_WIDTH - 1:0] target_freq_latched;
    // 当前计数值
    reg [DIV_WIDTH - 1:0]  cnt_current;

    //================================================================
    // 时序逻辑
    //================================================================

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // 复位时
            freq_out <= 1'b0;
            div_value <= {DIV_WIDTH{1'b0}};
            cnt_current <= {DIV_WIDTH{1'b0}};
            target_freq_latched <= {FREQ_WIDTH{1'b0}};
        end else if (target_freq != target_freq_latched) begin
            // 目标频率变化时
            div_value   <= calc_div_value(target_freq);
            cnt_current <= {DIV_WIDTH{1'b0}};
            target_freq_latched <= target_freq;
        end else if (div_value == {DIV_WIDTH{1'b0}}) begin
            // 分频系数设置为 0 时
            if (target_freq_latched == {FREQ_WIDTH{1'b0}}) begin
                // 目标频率为 0 时
                freq_out <= 1'b0;
            end else begin
                // 目标频率超过 CLK_FREQ / 2 时
                freq_out <= 1'b1;
            end
            cnt_current <= {DIV_WIDTH{1'b0}};
        end else if (cnt_current == div_value - 1'b1) begin
            // 计数器计数到目标计数值时
            freq_out <= ~freq_out;
            cnt_current <= {DIV_WIDTH{1'b0}};
        end else begin
            // 计数器正常计数时
            cnt_current <= cnt_current + 1'b1;
        end
    end

endmodule
