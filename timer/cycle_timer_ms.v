`timescale 1ns / 1ps

module cycle_timer_ms #(
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

    // 定时时间，单位为 ms
    input  wire [TIME_WIDTH - 1:0] time_ms,

    //================================================================
    // 模块输出
    //================================================================

    // 保证 两次输出上升沿 之间的间隔为定时时间
    // 保证 复位信号下降沿 到 下次输出上升沿 之间的间隔为定时时间
    // 保证 从定时时间变化 到 下次输出上升沿 之间的间隔为定时时间
    // 如果定时时间设置为零，则保持输出高电平

    // 定时时间到时输出一个时钟周期的高电平
    output reg  timeout,
    // 当前已计时的毫秒数
    output reg  [TIME_WIDTH - 1:0] elapsed_ms
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

    // 上一次锁存的定时时间
    reg [TIME_WIDTH - 1:0] time_ms_latched;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // 复位时
            timeout         <= 1'b0;
            elapsed_ms      <= {TIME_WIDTH{1'b0}};
            ms_accum        <= {MS_ACCUM_WIDTH{1'b0}};
            time_ms_latched <= {TIME_WIDTH{1'b0}};
        end else if (time_ms == {TIME_WIDTH{1'b0}}) begin
            // 定时时间设置为零时
            timeout         <= 1'b1;
            elapsed_ms      <= {TIME_WIDTH{1'b0}};
            ms_accum        <= {MS_ACCUM_WIDTH{1'b0}};
            time_ms_latched <= time_ms;
        end else if (time_ms != time_ms_latched) begin
            // 定时时间变化时
            timeout         <= 1'b0;
            elapsed_ms      <= {TIME_WIDTH{1'b0}};
            ms_accum        <= {MS_ACCUM_WIDTH{1'b0}};
            time_ms_latched <= time_ms;
        end else if (ms_tick) begin
            // 处在毫秒节拍时
            ms_accum <= ms_accum + MS_ACCUM_INC - CLK_FREQ;
            if (elapsed_ms == time_ms_latched - 1'b1) begin
                // 计时到达目标时间
                timeout    <= 1'b1;
                elapsed_ms <= {TIME_WIDTH{1'b0}};
            end else begin
                // 计时未达目标时间
                timeout    <= 1'b0;
                elapsed_ms <= elapsed_ms + 1'b1;
            end
        end else begin
            // 未达毫秒节拍时
            timeout  <= 1'b0;
            ms_accum <= ms_accum + MS_ACCUM_INC;
        end
    end

endmodule
