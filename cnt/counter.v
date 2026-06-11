`timescale 1ns / 1ps

module counter #(
    //================================================================
    // 可选参数
    //================================================================

    // 计数器位宽，范围 1 ~ 64，单位为 bit
    parameter [7:0] CNT_WIDTH = 32,

    // 计数方向：0 = 递增，1 = 递减
    parameter COUNT_MODE = 1'b0,

    // 计数下限
    parameter [CNT_WIDTH - 1:0] CNT_MIN = {CNT_WIDTH{1'b0}},
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

    //================================================================
    // 模块输出
    //================================================================

    // 当前计数值
    output reg  [CNT_WIDTH - 1:0] cnt_value

);

    //================================================================
    // 时序逻辑
    //================================================================

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // 复位时
            cnt_value <= (COUNT_MODE == 1'b0) ? CNT_MIN : CNT_MAX;
        end else if (COUNT_MODE == 1'b0) begin
            //========================================================
            // 递增模式
            //========================================================
            if (cnt_value >= CNT_MAX) begin
                // 计数到上限值时
                cnt_value <= CNT_MIN;
            end else if (cnt_value < CNT_MIN) begin
                // 当前计数值小于下限值时
                cnt_value <= CNT_MIN;
            end else begin
                // 正常递增计数
                cnt_value <= cnt_value + 1'b1;
            end
        end else begin
            //========================================================
            // 递减模式
            //========================================================
            if (cnt_value <= CNT_MIN) begin
                // 计数到下限值时
                cnt_value <= CNT_MAX;
            end else if (cnt_value > CNT_MAX) begin
                // 当前计数值大于上限值时
                cnt_value <= CNT_MAX;
            end else begin
                // 正常递减计数
                cnt_value <= cnt_value - 1'b1;
            end
        end
    end

endmodule
