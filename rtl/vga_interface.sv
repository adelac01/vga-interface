module vga_interface(input logic clk, input logic rst_n, output logic pll_lock, 

                    // VGA Signals
                     output logic [7:0] VGA_R, output logic [7:0] VGA_G, output logic [7:0] VGA_B,
                     output logic VGA_HS, output logic VGA_VS, output logic VGA_SYNC_N,
                     output logic VGA_CLK, output logic VGA_BLANK_N
                    );
    
    parameter RESOLUTION = "640x480";
    parameter MONOCHROME = "true";

    // Horizotal count thresholds (pixel cycles)
    parameter H_VISIBLE_CYCLES = 639;
    parameter H_FRONT_PORCH_CYCLES = 655;
    parameter H_SYNC_CYCLES = 751;
    parameter H_BACK_PORCH_CYCLES = 799;

    // Vertical count thresholds (lines) 
    parameter V_VISIBLE_LINES = 479;
    parameter V_FRONT_PORCH_LINES = 489;
    parameter V_SYNC_LINES = 491;
    parameter V_BACK_PORCH_LINES = 524;

    // Pixel count and line count
    int p_count, l_count;
    logic vga_clk;

    // Use PLL to turn input clk into 25.175MHz
    vga_pll pll(.refclk(clk), .rst(~rst_n), .outclk_0(vga_clk), .locked(pll_lock));

    // temporary values of R G B for testing
    assign VGA_R = 255;
    assign VGA_G = 255;
    assign VGA_B = 255;

    assign VGA_HS = ~((p_count > H_FRONT_PORCH_CYCLES) && (p_count <= H_SYNC_CYCLES)); 
    assign VGA_VS = ~((l_count > V_FRONT_PORCH_LINES) && (l_count <= V_SYNC_LINES)); 
    assign VGA_SYNC_N = 0; // Should always be low
    assign VGA_BLANK_N = ~((p_count > H_VISIBLE_CYCLES && p_count <= H_BACK_PORCH_CYCLES) || (l_count > V_VISIBLE_LINES && l_count <= V_BACK_PORCH_LINES));
    assign VGA_CLK = vga_clk;

    // Horizontal and vertical counter
    always_ff@(posedge vga_clk) begin
        if(~rst_n || ~pll_lock) begin
            p_count <= 0;
            l_count <= 0;
        end else begin
            if(p_count == H_BACK_PORCH_CYCLES && l_count == V_BACK_PORCH_LINES) begin
                p_count <= 0;
                l_count <= 0;
            end else if (p_count == H_BACK_PORCH_CYCLES) begin
                l_count <= l_count + 1;
                p_count <= 0;
            end else begin
                p_count <= p_count + 1;
            end
        end
    end


endmodule