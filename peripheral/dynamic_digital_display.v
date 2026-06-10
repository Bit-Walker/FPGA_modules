`timescale 1ns / 1ps

module dynamic_digital_display #(
    //================================================================
    // 可选参数
    //================================================================

    // 二进制输入位宽，范围 1 ~ 64，单位为 bit
    parameter [7:0]  BIN_WIDTH  = 32,
    // 数码管位数，范围 1 ~ 20
    parameter [7:0]  DIGITS_NUM = 4,

    // 系统时钟频率，单位为 Hz
    parameter [31:0] CLK_FREQ   = 50_000_000,
    // 位扫描频率，单位为 Hz
    parameter [31:0] SCAN_FREQ  = 5000,

    //================================================================
    // 自动计算参数
    //================================================================

    // BCD 转换所需的总位数
    parameter [7:0] BCD_DIGITS_TOTAL = calc_bcd_digits(BIN_WIDTH),
    // 扫描频率源位宽
    parameter [7:0] FREQ_WIDTH_SCAN  = (SCAN_FREQ <= 1) ? 1 : clog2(SCAN_FREQ + 1),
    // 位选计数器宽度
    parameter [7:0] DIG_SEL_WIDTH    = (DIGITS_NUM == 1) ? 1 : clog2(DIGITS_NUM)
) (
    //================================================================
    // 模块输入
    //================================================================

    // 系统时钟
    input  wire clk,
    // 高电平有效异步复位
    input  wire rst,

    // 待显示的二进制数值
    input  wire [BIN_WIDTH - 1:0] data_in,

    //================================================================
    // 模块输出
    //================================================================

    // 共阴极段选输出
    output wire [6:0] seg_out,
    // 低有效位使能输出
    output wire [DIGITS_NUM - 1:0] dig_out
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

    // 计算 BCD 转换所需位数
    function [7:0] calc_bcd_digits;
        input [7:0] bin_width;
        reg [127:0] max_val;
        reg [127:0] limit;
        begin
            max_val = (128'd1 << bin_width) - 128'd1;
            limit = 10;
            calc_bcd_digits = 1;
            while (limit <= max_val && calc_bcd_digits < 20) begin
                limit = limit * 10;
                calc_bcd_digits = calc_bcd_digits + 1;
            end
        end
    endfunction

    //================================================================
    // 扫描时钟生成
    //================================================================

    // 扫描频率源目标频率
    wire [FREQ_WIDTH_SCAN - 1:0] scan_target_freq;
    assign scan_target_freq = SCAN_FREQ[FREQ_WIDTH_SCAN - 1:0];

    // 扫描频率源输出
    wire scan_freq_out;

    frequency_source #(
        .FREQ_WIDTH  ( FREQ_WIDTH_SCAN ),
        .CLK_FREQ    ( CLK_FREQ        )
    ) u_scan_clk (
        .clk         ( clk ),
        .rst         ( rst ),
        .target_freq ( scan_target_freq ),
        .freq_out    ( scan_freq_out    )
    );

    //================================================================
    // 位选计数器
    //================================================================

    // 当前位选序号
    wire [DIG_SEL_WIDTH - 1:0] dig_sel;

    counter_up #(
        .CNT_WIDTH ( DIG_SEL_WIDTH         ),
        .CNT_MIN   ( {DIG_SEL_WIDTH{1'b0}} ),
        .CNT_MAX   ( DIGITS_NUM - 1'b1     )
    ) u_dig_counter (
        .clk       ( scan_freq_out ),
        .rst       ( rst           ),
        .cnt_value ( dig_sel       )
    );

    //================================================================
    // BCD 转换
    //================================================================

    // BCD 转换结果
    wire [BCD_DIGITS_TOTAL * 4 - 1:0] bcd_value;
    // 实际显示的 BCD 数码
    wire [DIGITS_NUM * 4 - 1:0] display_bcd;

    // BCD 转换子模块
    bin_to_bcd #(
        .BIN_WIDTH  ( BIN_WIDTH        ),
        .BCD_DIGITS ( BCD_DIGITS_TOTAL )
    ) u_bin_to_bcd (
        .bin_value  ( data_in   ),
        .bcd_value  ( bcd_value )
    );

    // 为实际显示的 BCD 数码高位补零
    generate
        if (BCD_DIGITS_TOTAL >= DIGITS_NUM) begin : gen_bcd_display
            assign display_bcd = bcd_value[DIGITS_NUM * 4 - 1:0];
        end else begin : gen_bcd_display_pad
            assign display_bcd = {{(DIGITS_NUM - BCD_DIGITS_TOTAL) * 4{1'b0}}, bcd_value};
        end
    endgenerate

    //================================================================
    // 溢出检测
    //================================================================

    // 溢出标志
    wire overflow;

    generate
        if (BCD_DIGITS_TOTAL > DIGITS_NUM) begin : gen_overflow_detect
            assign overflow = |bcd_value[BCD_DIGITS_TOTAL * 4 - 1 : DIGITS_NUM * 4];
        end else begin : gen_overflow_none
            assign overflow = 1'b0;
        end
    endgenerate

    //================================================================
    // 静态数码管显示
    //================================================================

    // 当前位选对应的 BCD 数码
    wire [3:0] current_bcd;
    assign current_bcd = (overflow && (dig_sel == {DIG_SEL_WIDTH{1'b0}})) ? 
                        4'hE : display_bcd[dig_sel * 4 +: 4];

    // 段选输出
    wire [6:0] display_seg_out;
    // 位使能输出
    wire [DIGITS_NUM - 1:0] display_dig_out;

    static_digital_display #(
        .DIGITS_NUM ( DIGITS_NUM )
    ) u_display (
        .data_in ( current_bcd     ),
        .dig_sel ( dig_sel         ),
        .seg_out ( display_seg_out ),
        .dig_out ( display_dig_out )
    );

    //================================================================
    // 隐藏高位零
    //================================================================

    // 每位的前导零标志
    reg  [DIGITS_NUM - 1:0] leading_zero;
    // 每位的抑制显示标志
    wire [DIGITS_NUM - 1:0] suppress_digit;

    // 循环变量
    integer i;

    // 前导零标志计算
    always @(*) begin
        leading_zero[DIGITS_NUM - 1] = ~overflow;
        for (i = DIGITS_NUM - 2; i >= 0; i = i - 1) begin
            leading_zero[i] = leading_zero[i + 1] && 
                              (display_bcd[(i + 1) * 4 +: 4] == 4'd0);
        end
    end

    // 抑制显示信号
    generate
        genvar gi;
        for (gi = 0; gi < DIGITS_NUM; gi = gi + 1) begin : gen_suppress
            assign suppress_digit[gi] = (gi != 0) && 
                                        (display_bcd[gi * 4 +: 4] == 4'd0) && 
                                        leading_zero[gi];
        end
    endgenerate

    //================================================================
    // 最终输出
    //================================================================

    // 段选输出，抑制显示标志有效时输出空白显示
    assign seg_out = (suppress_digit[dig_sel]) ? 7'b0000000 : display_seg_out;

    // 位使能输出
    assign dig_out = display_dig_out;

endmodule
