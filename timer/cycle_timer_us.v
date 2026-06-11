`timescale 1ns / 1ps

module cycle_timer_us #(
    //================================================================
    // 可选参数
    //================================================================

    // 定时时间位宽，范围 1 ~ 64，单位为 bit
    parameter [7:0]  TIME_WIDTH = 32,
    // 系统时钟频率，频率大于 1 MHz，单位为 Hz
    parameter [31:0] CLK_FREQ   = 50_000_000,

    //================================================================
    // 自动计算参数
    //================================================================

    // 微秒累加器宽度
    parameter [7:0]   US_ACCUM_WIDTH = clog2(CLK_FREQ + 999_999)
) (
    //================================================================
    // 模块输入
    //================================================================

    // 系统时钟
    input  wire clk,
    // 高电平有效异步复位
    input  wire rst,

    // 定时时间，单位为 us
    input  wire [TIME_WIDTH - 1:0] time_us,

    //================================================================
    // 模块输出
    //================================================================

    // 保证 两次输出上升沿 之间的间隔为定时时间
    // 保证 复位信号下降沿 到 下次输出上升沿 之间的间隔为定时时间
    // 保证 从定时时间变化 到 下次输出上升沿 之间的间隔为定时时间
    // 如果定时时间设置为零，则保持输出高电平

    // 定时时间到时输出一个时钟周期的高电平
    output reg  timeout,
    // 当前已计时的微秒数
    output reg  [TIME_WIDTH - 1:0] elapsed_us
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
    // 微秒计时器
    //================================================================

    // 微秒单位换算系数
    localparam US_ACCUM_INC = 1_000_000;

    // 微秒相位累加器
    reg [US_ACCUM_WIDTH - 1:0] us_accum;

    // 微秒节拍标志
    wire   us_tick;
    assign us_tick = (us_accum + US_ACCUM_INC) >= CLK_FREQ;

    // 上一次锁存的定时时间
    reg [TIME_WIDTH - 1:0] time_us_latched;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // 复位时
            timeout         <= 1'b0;
            elapsed_us      <= {TIME_WIDTH{1'b0}};
            us_accum        <= {US_ACCUM_WIDTH{1'b0}};
            time_us_latched <= {TIME_WIDTH{1'b0}};
        end else if (time_us == {TIME_WIDTH{1'b0}}) begin
            // 定时时间设置为零时
            timeout         <= 1'b1;
            elapsed_us      <= {TIME_WIDTH{1'b0}};
            us_accum        <= {US_ACCUM_WIDTH{1'b0}};
            time_us_latched <= time_us;
        end else if (time_us != time_us_latched) begin
            // 定时时间变化时
            timeout         <= 1'b0;
            elapsed_us      <= {TIME_WIDTH{1'b0}};
            us_accum        <= {US_ACCUM_WIDTH{1'b0}};
            time_us_latched <= time_us;
        end else if (us_tick) begin
            // 处在微秒节拍时
            us_accum <= us_accum + US_ACCUM_INC - CLK_FREQ;
            if (elapsed_us == time_us_latched - 1'b1) begin
                // 计时到达目标时间
                timeout    <= 1'b1;
                elapsed_us <= {TIME_WIDTH{1'b0}};
            end else begin
                // 计时未达目标时间
                timeout    <= 1'b0;
                elapsed_us <= elapsed_us + 1'b1;
            end
        end else begin
            // 未达微秒节拍时
            timeout  <= 1'b0;
            us_accum <= us_accum + US_ACCUM_INC;
        end
    end

endmodule
