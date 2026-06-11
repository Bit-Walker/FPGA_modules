`timescale 1ns / 1ps

module counter_var_freq #(
    //================================================================
    // 可选参数
    //================================================================

    // 计数器位宽，范围 1 ~ 64，单位为 bit
    parameter [7:0]  CNT_WIDTH  = 32,
    // 频率值位宽，范围 1 ~ 64，单位为 bit
    parameter [7:0]  FREQ_WIDTH = 32,
    // 系统时钟频率，单位为 Hz
    parameter [31:0] CLK_FREQ   = 50_000_000,

    // 计数方向：0 = 递增，1 = 递减
    parameter COUNT_MODE = 1'b0,

    // 计数下限
    parameter [CNT_WIDTH - 1:0] CNT_MIN = {CNT_WIDTH{1'b0}},
    // 计数上限
    parameter [CNT_WIDTH - 1:0] CNT_MAX = {CNT_WIDTH{1'b1}},

    //================================================================
    // 自动计算参数
    //================================================================

    // 频率累加器宽度
    parameter [7:0] FREQ_ACCUM_WIDTH = clog2(CLK_FREQ + CLK_FREQ)

) (
    //================================================================
    // 模块输入
    //================================================================

    // 系统时钟
    input  wire clk,
    // 高电平有效异步复位
    input  wire rst,

    // 目标计数频率设置为 0 时计数器保持
    // 目标计数频率超过 CLK_FREQ 时每个时钟周期计数一次

    // 目标计数频率，单位为 Hz
    input  wire [FREQ_WIDTH - 1:0] target_freq,

    //================================================================
    // 模块输出
    //================================================================

    // 当前计数值
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

    //================================================================
    // 频率发生器
    //================================================================

    // 频率相位累加器
    reg [FREQ_ACCUM_WIDTH - 1:0] freq_accum;

    // 上次锁存的频率值
    reg [FREQ_WIDTH - 1:0] target_freq_latched;

    // 计数节拍标志
    wire   cnt_tick;
    assign cnt_tick = (target_freq_latched >= CLK_FREQ) || 
                      ((freq_accum + target_freq_latched) >= CLK_FREQ);

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // 复位时
            freq_accum          <= {FREQ_ACCUM_WIDTH{1'b0}};
            target_freq_latched <= {FREQ_WIDTH{1'b0}};
        end else if (target_freq != target_freq_latched) begin
            // 目标频率变化时
            freq_accum          <= {FREQ_ACCUM_WIDTH{1'b0}};
            target_freq_latched <= target_freq;
        end else if (target_freq_latched == {FREQ_WIDTH{1'b0}}) begin
            // 目标频率为 0 时
            freq_accum <= {FREQ_ACCUM_WIDTH{1'b0}};
        end else if (target_freq_latched >= CLK_FREQ) begin
            // 目标频率大于等于时钟频率时
            freq_accum <= {FREQ_ACCUM_WIDTH{1'b0}};
        end else if (cnt_tick) begin
            // 处在计数节拍时
            freq_accum <= freq_accum + target_freq_latched - CLK_FREQ;
        end else begin
            // 未达计数节拍时
            freq_accum <= freq_accum + target_freq_latched;
        end
    end

    //================================================================
    // 主计数器
    //================================================================

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // 复位时
            cnt_value <= (COUNT_MODE == 1'b0) ? CNT_MIN : CNT_MAX;
        end else if (cnt_tick) begin
            // 计数节拍有效时
            if (COUNT_MODE == 1'b0) begin
                //====================================================
                // 递增模式
                //====================================================
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
                //====================================================
                // 递减模式
                //====================================================
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
    end

endmodule
