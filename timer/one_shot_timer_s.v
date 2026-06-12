`timescale 1ns / 1ps

//================================================================
// 模块说明
//================================================================
// 秒级单次定时器。
// start 高电平时初始化定时参数，
// start 下降沿开始倒计时。
// 保持 start 高电平则反复初始化，可阻止计时。
//================================================================

module one_shot_timer_s #(
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

    // 启动一次定时，高电平时初始化，低电平开始计时，保持高电平会反复初始化
    input  wire start,
    // 定时时间，单位为 s
    input  wire [TIME_WIDTH - 1:0] time_s,

    //================================================================
    // 模块输出
    //================================================================

    // 定时结束后输出高电平，并保持到下次启动或复位
    output reg  timeout,
    // 当前剩余的秒数
    output reg  [TIME_WIDTH - 1:0] remaining_s
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

    // 定时进行中标志
    reg busy;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // 复位时
            busy        <= 1'b0;
            timeout     <= 1'b0;
            remaining_s <= {TIME_WIDTH{1'b0}};
            s_accum     <= {S_ACCUM_WIDTH{1'b0}};
        end else if (start) begin
            // 启动定时时
            s_accum <= {S_ACCUM_WIDTH{1'b0}};
            if (time_s == {TIME_WIDTH{1'b0}}) begin
                busy        <= 1'b0;
                timeout     <= 1'b1;
                remaining_s <= {TIME_WIDTH{1'b0}};
            end else begin
                busy        <= 1'b1;
                timeout     <= 1'b0;
                remaining_s <= time_s;
            end
        end else if (busy) begin
            // 定时进行时
            if (remaining_s == {TIME_WIDTH{1'b0}}) begin
                busy    <= 1'b0;
                timeout <= 1'b1;
            end else if (s_tick) begin
                // 处在秒节拍时
                s_accum     <= s_accum + S_ACCUM_INC - CLK_FREQ;
                remaining_s <= remaining_s - 1'b1;
            end else begin
                // 未达秒节拍时
                s_accum <= s_accum + S_ACCUM_INC;
            end
        end
    end

endmodule
