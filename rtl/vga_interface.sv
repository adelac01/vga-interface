module vga_interface(
    clk, rst_n, pll_lock,
    r_in, g_in, b_in,
    x_in, y_in,
    VGA_R, VGA_G, VGA_B,
    VGA_HS, VGA_VS, VGA_SYNC_N,
    VGA_CLK, VGA_BLANK_N,
);
    
    parameter RESOLUTION = "320x240";
    parameter CHANNEL_SIZES = 8;
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

    parameter x_in_width = ((RESOLUTION == "160x120") ? 8 : ((RESOLUTION == "320x240") ? 9 : 10));
    parameter y_in_width = ((RESOLUTION == "160x120") ? 8 : ((RESOLUTION == "320x240") ? 8 : 9));
    parameter num_words = ((RESOLUTION == "160x120") ? 19200 : ((RESOLUTION == "320x240") ? 76800 : 307200)); 
    parameter address_size = ((RESOLUTION == "160x120") ? 15 : ((RESOLUTION == "320x240") ? 17 : 19)); 
    parameter screen_width = ((RESOLUTION == "160x120") ? 160 : ((RESOLUTION == "320x240") ? 320 : 640));
    parameter screen_height = ((RESOLUTION == "160x120") ? 120 : ((RESOLUTION == "320x240") ? 240 : 480));
    parameter shift_amount = ((RESOLUTION == "160x120") ? 2 : ((RESOLUTION == "320x240") ? 1 : 0));

    input logic clk;
    input logic rst_n;
    output logic pll_lock;

    // TODO: Change bus width depending on user desired channel widths
    input logic [7:0] r_in;
    input logic [7:0] g_in;
    input logic [7:0] b_in;

    input logic [x_in_width-1:0] x_in;
    input logic [y_in_width-1:0] y_in;

    // VGA Signals
    output logic [7:0] VGA_R;
    output logic [7:0] VGA_G;
    output logic [7:0] VGA_B;
    output logic VGA_HS;
    output logic VGA_VS;
    output logic VGA_SYNC_N;
    output logic VGA_CLK;
    output logic VGA_BLANK_N;

    logic [9:0] p_count;
    logic [9:0] l_count;
    logic vga_clk, count_en;
    logic wren, rden;

    logic [address_size-1:0] buffer_read_address;
    assign buffer_read_address = (l_count >> shift_amount) * screen_width + (p_count >> shift_amount);
    logic [address_size-1:0] buffer_write_address;
    assign buffer_write_address = y_in * screen_width + x_in;

    // logic [7:0] color_data;
    // assign VGA_R = MONOCHROME == "true" ? color_data;
    // assign VGA_G = MONOCHROME == "true" ? color_data;
    // assign VGA_B = MONOCHROME == "true" ? color_data;

    logic [7:0] color_output;
    assign VGA_R = color_output;
    assign VGA_G = color_output;
    assign VGA_B = color_output;

    altsyncram pixel_buffer(
        .address_a(buffer_write_address),
        .address_b(buffer_read_address),
        .clock0(clk),
        .clock1(vga_clk),
        .data_a(r_in),
        .data_b (8'b1111_1111),
        .rden_a(1'b1),
        .rden_b(rden),
        .wren_a(wren),
        .wren_b(1'b0),
        .q_a(),
        .q_b(color_output),
        .aclr0(1'b0),
        .aclr1(1'b0),
        .addressstall_a(1'b0),
        .addressstall_b(1'b0),
        .byteena_a(1'b1),
        .byteena_b(1'b1),
        .clocken0(1'b1),
        .clocken1(1'b1),
        .clocken2(1'b1),
        .clocken3(1'b1),
        .eccstatus(),  
    );
    defparam
        pixel_buffer.address_aclr_b = "NONE",
        pixel_buffer.address_reg_b = "CLOCK1",
        pixel_buffer.clock_enable_input_a = "BYPASS",
        pixel_buffer.clock_enable_input_b = "BYPASS",
        pixel_buffer.clock_enable_output_b = "BYPASS",
        pixel_buffer.init_file = "",
        pixel_buffer.intended_device_family = "Cyclone V",
        pixel_buffer.lpm_type = "altsyncram",
        pixel_buffer.numwords_a = num_words,
        pixel_buffer.numwords_b = num_words,
        pixel_buffer.operation_mode = "DUAL_PORT",
        pixel_buffer.outdata_aclr_b = "NONE",
        pixel_buffer.outdata_reg_b = "UNREGISTERED",
        pixel_buffer.power_up_uninitialized = "FALSE",
        pixel_buffer.ram_block_type = "M10K",
        pixel_buffer.rdcontrol_reg_b = "CLOCK1",
        pixel_buffer.widthad_a = address_size,
        pixel_buffer.widthad_b = address_size,
        pixel_buffer.width_a = 8,
        pixel_buffer.width_b = 8,
        pixel_buffer.width_byteena_a = 1;

    // debug_mem debug(.address(wraddress), .clock(clk), .data(r_in), .wren(wren));

    // Use PLL to turn input clk into 25.175MHz
    vga_pll pll(.refclk(clk), .rst(~rst_n), .outclk_0(vga_clk), .locked(pll_lock));

    assign VGA_SYNC_N = 0; // Should always be low
    assign VGA_CLK = vga_clk;
    assign wren = (x_in < screen_width && y_in < screen_height);
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