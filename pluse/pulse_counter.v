`timescale 1ns / 1ps

module pulse_counter #(
    //================================================================
    // 可选参数
    //================================================================

    // 计数器位宽，范围 1 ~ 64，单位为 bit
    parameter [7:0] CNT_WIDTH = 32,

    //================================================================
    // 自动计算参数
    //================================================================

    // 计数上限
    parameter [CNT_WIDTH - 1:0] CNT_MAX = {CNT_WIDTH{1'b1}}

) (
    //================================================================
    // 模块输入
    //================================================================

    // 系统时钟
    input  wire clk,
    // 高电平有效异步复位
    input  wire rst,

    // 待计数的脉冲信号
    input  wire pulse_in,

    //================================================================
    // 模块输出
    //================================================================

    // 当前脉冲计数值
    output reg  [CNT_WIDTH - 1:0] pulse_count,
    // 计数溢出标志，高电平有效，持续一个时钟周期
    output reg  overflow
);

    //================================================================
    // 寄存器声明
    //================================================================

    // 脉冲输入同步寄存器
    reg pulse_in_sync0;
    reg pulse_in_sync1;

    // 脉冲输入前一状态寄存器
    reg pulse_in_prev;

    //================================================================
    // 脉冲输入同步与边沿检测
    //================================================================

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // 复位时
            pulse_in_sync0 <= 1'b0;
            pulse_in_sync1 <= 1'b0;
            pulse_in_prev  <= 1'b0;
        end else begin
            // 两级同步消除亚稳态
            pulse_in_sync0 <= pulse_in;
            pulse_in_sync1 <= pulse_in_sync0;
            // 保存前一状态用于边沿检测
            pulse_in_prev  <= pulse_in_sync1;
        end
    end

    //================================================================
    // 脉冲计数逻辑
    //================================================================

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // 复位时
            pulse_count <= {CNT_WIDTH{1'b0}};
            overflow    <= 1'b0;
        end else if (pulse_in_sync1 && !pulse_in_prev) begin
            // 检测到脉冲上升沿时
            if (pulse_count >= CNT_MAX) begin
                // 计数到上限值时
                pulse_count <= {CNT_WIDTH{1'b0}};
                overflow    <= 1'b1;
            end else begin
                // 正常计数时
                pulse_count <= pulse_count + 1'b1;
                overflow    <= 1'b0;
            end
        end else begin
            // 无脉冲上升沿时
            overflow <= 1'b0;
        end
    end

endmodule
