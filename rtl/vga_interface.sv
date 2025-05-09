module vga_interface(input logic clk, input logic rst_n, output logic pll_lock, 

                     input logic [7:0] r_in, input logic [7:0] g_in, input logic [7:0] b_in, 
                     input logic [9:0] x_in, input logic [8:0] y_in,

                     // VGA Signals
                     output logic [7:0] VGA_R, output logic [7:0] VGA_G, output logic [7:0] VGA_B,
                     output logic VGA_HS, output logic VGA_VS, output logic VGA_SYNC_N,
                     output logic VGA_CLK, output logic VGA_BLANK_N);
    
    // parameter RESOLUTION = "640x480";
    parameter MONOCHROME = "true";

    // Horizotal count thresholds (pixel cycles)
    parameter H_VISIBLE_END = 639;
    parameter H_FRONT_PORCH_END = 655;
    parameter H_SYNC_END = 751;
    parameter H_BACK_PORCH_END = 799;

    // Vertical count thresholds (lines) 
    parameter V_VISIBLE_END = 479;
    parameter V_FRONT_PORCH_END = 489;
    parameter V_SYNC_END = 491;
    parameter V_BACK_PORCH_END = 524;

    // Pixel count and line count
    int p_count, l_count;
    logic vga_clk, count_en;
    logic wren, rden;

    // 640x480 resolution
    // wire [18:0] rdaddress = l_count * 640 + p_count;
    // wire [18:0] wraddress = y_in * 640 + x_in;

    // 320x240 resolution
    wire [16:0] rdaddress = (l_count >> 1) * 320 + (p_count >> 1);
    wire [16:0] wraddress = y_in * 320 + x_in;

    logic [7:0] monochrome_data;
    assign VGA_R = monochrome_data;
    assign VGA_G = monochrome_data;
    assign VGA_B = monochrome_data;
    // vga_test_rom grayscale_rom(.clock(vga_clk), .address(rdaddress), .rden(rden), .q(monochrome_data));
    vga_ram ram_buffer(.wrclock(clk), .rdclock(vga_clk), .wraddress(wraddress), .rdaddress(rdaddress), .wren(wren), .rden(rden), .data(r_in), .q(monochrome_data));
    debug_mem debug(.address(wraddress), .clock(clk), .data(r_in), .wren(wren));

    // Use PLL to turn input clk into 25.175MHz
    vga_pll pll(.refclk(clk), .rst(~rst_n), .outclk_0(vga_clk), .locked(pll_lock));

    assign VGA_SYNC_N = 0; // Should always be low
    assign VGA_CLK = vga_clk;
    // assign wren = (x_in < 640 && y_in < 480);
    assign wren = 1'b1;
    assign rden = (p_count <= H_VISIBLE_END && l_count <= V_VISIBLE_END);

    always_ff @(posedge vga_clk or negedge rst_n) begin
        if(~rst_n) begin
            count_en <= 0;
        end else begin
            if(pll_lock) begin
                count_en <= 1;
            end
        end
    end

    // VGA Out signals
    always_ff @(posedge vga_clk) begin
        VGA_HS <= ~((p_count >= H_FRONT_PORCH_END + 2) && (p_count < H_SYNC_END + 2));
        VGA_VS <= ~((l_count > V_FRONT_PORCH_END) && (l_count <= V_SYNC_END));
        VGA_BLANK_N <= (p_count <= H_VISIBLE_END && l_count <= V_VISIBLE_END);   
    end

    // Horizontal and vertical counter
    always_ff @(posedge vga_clk or negedge rst_n) begin
        if(~rst_n) begin
            p_count <= 0;
            l_count <= 0;
        end else begin
            if(count_en) begin
                if(p_count == H_BACK_PORCH_END && l_count == V_BACK_PORCH_END) begin
                    p_count <= 0;
                    l_count <= 0;
                end else if (p_count == H_BACK_PORCH_END) begin
                    l_count <= l_count + 1;
                    p_count <= 0;
                end else begin
                    p_count <= p_count + 1;
                end
            end
        end
    end


endmodule