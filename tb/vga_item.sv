class vga_item #(
    parameter RESOLUTION = "640x480",
    parameter CHANNEL_SIZES = 8
);

    parameter x_in_width = ((RESOLUTION == "160x120") ? 8 : ((RESOLUTION == "320x240") ? 9 : 10));
    parameter y_in_width = ((RESOLUTION == "160x120") ? 8 : ((RESOLUTION == "320x240") ? 8 : 9));

    // inputs
    rand bit [x_in_width-1:0] xin;
    rand bit [y_in_width-1:0] yin;
    rand bit [CHANNEL_SIZES-1:0] rin;
    rand bit [CHANNEL_SIZES-1:0] gin;
    rand bit [CHANNEL_SIZES-1:0] bin;

    // outputs
    bit hs;
    bit vs;
    bit blank_n;
    bit [7:0] rout;
    bit [7:0] gout;
    bit [7:0] bout;


endclass