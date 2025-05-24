interface vga_if #(
    parameter RESOLUTION = "640x480",
    parameter CHANNEL_SIZES = 8
    )
    (input logic clk);

    parameter x_in_width = ((RESOLUTION == "160x120") ? 8 : ((RESOLUTION == "320x240") ? 9 : 10));
    parameter y_in_width = ((RESOLUTION == "160x120") ? 8 : ((RESOLUTION == "320x240") ? 8 : 9));

    logic rst_n;
    logic pll_lock;
    logic [x_in_width-1:0] x_in;
    logic [y_in_width-1:0] y_in;
    logic [CHANNEL_SIZES-1:0] r_in;
    logic [CHANNEL_SIZES-1:0] g_in;
    logic [CHANNEL_SIZES-1:0] b_in;
    logic [7:0] VGA_R;
    logic [7:0] VGA_G;
    logic [7:0] VGA_B;
    logic VGA_HS;
    logic VGA_VS;
    logic VGA_SYNC_N;
    logic VGA_CLK;
    logic VGA_BLANK_N;
endinterface