`timescale 1ns / 1ps

//================================================================
// 模块说明
//================================================================
// 秒级循环定时器。
// 以固定周期自动循环输出 timeout 脉冲，每次脉冲持续一个时钟周期。
//================================================================

module cycle_timer_s #(
    //================================================================
    // 可选参数
    //================================================================

    // 定时时间位宽，范围 1 ~ 64，单位为 bit
    parameter [7:0]  TIME_WIDTH = 32,
    // 系统时钟频率，单位为 Hz
    parameter [31:0] CLK_FREQ   = 50_000_000,

    //================================================================
    // 自动计算参数
    //================================================================

    // 秒累加器宽度
    parameter [7:0]   S_ACCUM_WIDTH  = clog2(CLK_FREQ)
) (
    //================================================================
    // 模块输入
    //================================================================

    // 系统时钟
    input  wire clk,
    // 高电平有效异步复位
    input  wire rst,

    // 定时时间，单位为 s
    input  wire [TIME_WIDTH - 1:0] time_s,

    //================================================================
    // 模块输出
    //================================================================

    // 保证 两次输出上升沿 之间的间隔为定时时间
    // 保证 复位信号下降沿 到 下次输出上升沿 之间的间隔为定时时间
    // 保证 从定时时间变化 到 下次输出上升沿 之间的间隔为定时时间
    // 如果定时时间设置为零，则保持输出高电平

    // 定时时间到时输出一个时钟周期的高电平
    output reg  timeout,
    // 当前已计时的秒数
    output reg  [TIME_WIDTH - 1:0] elapsed_s
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
    // 秒计时器
    //================================================================

    // 秒单位换算系数
    localparam S_ACCUM_INC = 1;

    // 秒相位累加器
    reg [S_ACCUM_WIDTH - 1:0] s_accum;

    // 秒节拍标志
    wire   s_tick;
    assign s_tick = (s_accum + S_ACCUM_INC) >= CLK_FREQ;

    // 上一次锁存的定时时间
    reg [TIME_WIDTH - 1:0] time_s_latched;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // 复位时
            timeout         <= 1'b0;
            elapsed_s       <= {TIME_WIDTH{1'b0}};
            s_accum         <= {S_ACCUM_WIDTH{1'b0}};
            time_s_latched  <= {TIME_WIDTH{1'b0}};
        end else if (time_s == {TIME_WIDTH{1'b0}}) begin
            // 定时时间设置为零时
            timeout         <= 1'b1;
            elapsed_s       <= {TIME_WIDTH{1'b0}};
            s_accum         <= {S_ACCUM_WIDTH{1'b0}};
            time_s_latched  <= time_s;
        end else if (time_s != time_s_latched) begin
            // 定时时间变化时
            timeout         <= 1'b0;
            elapsed_s       <= {TIME_WIDTH{1'b0}};
            s_accum         <= {S_ACCUM_WIDTH{1'b0}};
            time_s_latched  <= time_s;
        end else if (s_tick) begin
            // 处在秒节拍时
            s_accum <= s_accum + S_ACCUM_INC - CLK_FREQ;
            if (elapsed_s == time_s_latched - 1'b1) begin
                // 计时到达目标时间
                timeout    <= 1'b1;
                elapsed_s  <= {TIME_WIDTH{1'b0}};
            end else begin
                // 计时未达目标时间
                timeout    <= 1'b0;
                elapsed_s  <= elapsed_s + 1'b1;
            end
        end else begin
            // 未达秒节拍时
            timeout  <= 1'b0;
            s_accum <= s_accum + S_ACCUM_INC;
        end
    end

endmodule
