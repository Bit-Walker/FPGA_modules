`timescale 1ns / 1ps

module cycle_timer #(
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

    // 最大定时时间
    parameter [127:0] MAX_TIME_US   = ({128{1'b1}} >> (128 - TIME_WIDTH)),
    // 最大计数值
    parameter [127:0] MAX_CNT_VALUE = ((CLK_FREQ * MAX_TIME_US) + 999_999) / 1_000_000,
    // 定时计数器宽度
    parameter [7:0]   CNT_WIDTH     = clog2(MAX_CNT_VALUE + 1)
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
    output reg  timeout
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

    // 计算目标计数值
    function [CNT_WIDTH - 1:0] calc_cnt_target;
        input [TIME_WIDTH - 1:0] time_value_us;
        reg   [127:0] cnt_value;
        begin            
            cnt_value = ((CLK_FREQ * time_value_us) + 999_999) / 1_000_000;
            calc_cnt_target = cnt_value[CNT_WIDTH - 1:0];
        end
    endfunction

    //================================================================
    // 寄存器声明
    //================================================================

    // 目标计数值
    reg [CNT_WIDTH - 1:0] cnt_target;
    // 当前计数值
    reg [CNT_WIDTH - 1:0] cnt_current;
    // 上一次锁存的定时时间
    reg [TIME_WIDTH - 1:0] time_us_latched;

    //================================================================
    // 时序逻辑
    //================================================================

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // 复位时
            timeout <= 1'b0;
            cnt_target  <= {CNT_WIDTH{1'b0}};
            cnt_current <= {CNT_WIDTH{1'b0}};
            time_us_latched <= {TIME_WIDTH{1'b0}};
        end else if (time_us == {TIME_WIDTH{1'b0}}) begin
            // 定时时间设置为 0 时
            timeout <= 1'b1;
            cnt_target  <= {CNT_WIDTH{1'b0}};
            cnt_current <= {CNT_WIDTH{1'b0}};
            time_us_latched <= time_us;
        end else if (time_us != time_us_latched) begin
            // 定时时间变化时，从当前时钟沿重新开始计时
            timeout <= 1'b0;
            cnt_target  <= calc_cnt_target(time_us);
            cnt_current <= {CNT_WIDTH{1'b0}};
            time_us_latched <= time_us;
        end else if (cnt_current == cnt_target - 1'b1) begin
            // 计数器计数到目标计数值时
            timeout <= 1'b1;
            cnt_current <= {CNT_WIDTH{1'b0}};

        end else begin
            // 计数器正常计数时
            timeout <= 1'b0;
            cnt_current <= cnt_current + 1'b1;
        end
    end

endmodule
