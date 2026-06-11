`timescale 1ns / 1ps

module one_shot_timer_ms #(
    //================================================================
    // 可选参数
    //================================================================

    // 定时时间位宽，范围 1 ~ 64，单位为 bit
    parameter [7:0]  TIME_WIDTH = 32,
    // 系统时钟频率，频率大于 1 KHz，单位为 Hz
    parameter [31:0] CLK_FREQ   = 50_000_000,

    //================================================================
    // 自动计算参数
    //================================================================

    // 毫秒累加器宽度
    parameter [7:0]   MS_ACCUM_WIDTH = clog2(CLK_FREQ + 999)
) (
    //================================================================
    // 模块输入
    //================================================================

    // 系统时钟
    input  wire clk,
    // 高电平有效异步复位
    input  wire rst,

    // 启动一次定时，高电平时初始化，低电平开始计时，保持高电平会反复初始化
    input  wire start,
    // 定时时间，单位为 ms
    input  wire [TIME_WIDTH - 1:0] time_ms,

    //================================================================
    // 模块输出
    //================================================================

    // 定时结束后输出高电平，并保持到下次启动或复位
    output reg  timeout,
    // 当前剩余的毫秒数
    output reg  [TIME_WIDTH - 1:0] remaining_ms
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

    //================================================================
    // 毫秒计时器
    //================================================================

    // 毫秒单位换算系数
    localparam MS_ACCUM_INC = 1_000;

    // 毫秒相位累加器
    reg [MS_ACCUM_WIDTH - 1:0] ms_accum;

    // 毫秒节拍标志
    wire   ms_tick;
    assign ms_tick = (ms_accum + MS_ACCUM_INC) >= CLK_FREQ;

    // 定时进行中标志
    reg busy;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // 复位时
            busy         <= 1'b0;
            timeout      <= 1'b0;
            remaining_ms <= {TIME_WIDTH{1'b0}};
            ms_accum     <= {MS_ACCUM_WIDTH{1'b0}};
        end else if (start) begin
            // 启动定时时
            ms_accum <= {MS_ACCUM_WIDTH{1'b0}};
            if (time_ms == {TIME_WIDTH{1'b0}}) begin
                busy         <= 1'b0;
                timeout      <= 1'b1;
                remaining_ms <= {TIME_WIDTH{1'b0}};
            end else begin
                busy         <= 1'b1;
                timeout      <= 1'b0;
                remaining_ms <= time_ms;
            end
        end else if (busy) begin
            // 定时进行时
            if (remaining_ms == {TIME_WIDTH{1'b0}}) begin
                busy    <= 1'b0;
                timeout <= 1'b1;
            end else if (ms_tick) begin
                // 处在毫秒节拍时
                ms_accum     <= ms_accum + MS_ACCUM_INC - CLK_FREQ;
                remaining_ms <= remaining_ms - 1'b1;
            end else begin
                // 未达毫秒节拍时
                ms_accum <= ms_accum + MS_ACCUM_INC;
            end
        end
    end

endmodule
