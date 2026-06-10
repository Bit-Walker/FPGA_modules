`timescale 1ns / 1ps

module one_shot_timer_down #(
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

    // 启动一次定时，高电平初始化，低电平开始计时
    input  wire start,
    // 定时时间，单位为 us
    input  wire [TIME_WIDTH - 1:0] time_us,

    //================================================================
    // 模块输出
    //================================================================

    // 定时进行中标志，
    output reg  busy,
    // 定时结束后输出高电平，并保持到下次启动或复位
    output reg  timeout,
    // 当前倒计时数值，单位为时钟周期
    output reg  [CNT_WIDTH - 1:0] cnt_value
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
        reg   [127:0] cnt_target_value;
        begin
            cnt_target_value = ((CLK_FREQ * time_value_us) + 999_999) / 1_000_000;
            calc_cnt_target = cnt_target_value[CNT_WIDTH - 1:0];
        end
    endfunction

    //================================================================
    // 寄存器声明
    //================================================================

    // 目标计数值
    reg [CNT_WIDTH - 1:0] cnt_target;

    //================================================================
    // 时序逻辑
    //================================================================

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // 复位时
            busy       <= 1'b0;
            timeout    <= 1'b0;
            cnt_target <= {CNT_WIDTH{1'b0}};
            cnt_value  <= {CNT_WIDTH{1'b0}};
        end else if (start) begin
            // 启动定时时
            cnt_target <= calc_cnt_target(time_us);

            if (time_us == {TIME_WIDTH{1'b0}}) begin
                busy      <= 1'b0;
                timeout   <= 1'b1;
                cnt_value <= {CNT_WIDTH{1'b0}};
            end else begin
                busy    <= 1'b1;
                timeout <= 1'b0;
                cnt_value <= calc_cnt_target(time_us);
            end
        end else if (busy) begin
            // 定时进行时
            if (cnt_value == {CNT_WIDTH{1'b0}}) begin
                busy    <= 1'b0;
                timeout <= 1'b1;
            end else begin
                cnt_value <= cnt_value - 1'b1;
            end
        end
    end

endmodule
