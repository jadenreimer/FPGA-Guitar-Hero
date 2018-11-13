module rate_driver(input clk, output reg pix_stb);

	reg [15:0] cnt;
	
	always @(posedge clk)
		{pix_stb, cnt} <= cnt + 16'h8000;
	
//	Use this if you need something to access this rate-driven clock
//
//	always @ (posedge CLK)
//	begin
//		 if (pix_stb)   
//		 begin
//		 // do stuff once per pixel clock tick
//		 end
//	end
	
endmodule







module square #(
    H_SIZE=80,      // half square width (for ease of co-ordinate calculations)
    IX=320,         // initial horizontal position of square centre
    IY=240,         // initial vertical position of square centre
    IX_DIR=1,       // initial horizontal direction: 1 is right, 0 is left
    IY_DIR=1,       // initial vertical direction: 1 is down, 0 is up
    D_WIDTH=640,    // width of display
    D_HEIGHT=480    // height of display
    )
    (
    input wire i_clk,         // base clock
    input wire i_ani_stb,     // animation clock: pixel clock is 1 pix/frame
    input wire i_rst,         // reset: returns animation to starting position
    input wire i_animate,     // animate when input is high
    output wire [11:0] o_x1,  // square left edge: 12-bit value: 0-4095
    output wire [11:0] o_x2,  // square right edge
    output wire [11:0] o_y1,  // square top edge
    output wire [11:0] o_y2   // square bottom edge
    );

    reg [11:0] x = IX;   // horizontal position of square centre
    reg [11:0] y = IY;   // vertical position of square centre
    reg x_dir = IX_DIR;  // horizontal animation direction
    reg y_dir = IY_DIR;  // vertical animation direction

    assign o_x1 = x - H_SIZE;  // left: centre minus half horizontal size
    assign o_x2 = x + H_SIZE;  // right
    assign o_y1 = y - H_SIZE;  // top
    assign o_y2 = y + H_SIZE;  // bottom

    always @ (posedge i_clk)
    begin
        if (i_rst)  // on reset return to starting position
        begin
            x <= IX;
            y <= IY;
            x_dir <= IX_DIR;
            y_dir <= IY_DIR;
        end
        if (i_animate && i_ani_stb)
        begin
            x <= (x_dir) ? x + 1 : x - 1;  // move left if positive x_dir
            y <= (y_dir) ? y + 1 : y - 1;  // move down if positive y_dir

            if (x <= H_SIZE + 1)  // edge of square is at left of screen
                x_dir <= 1;  // change direction to right
            if (x >= (D_WIDTH - H_SIZE - 1))  // edge of square at right
                x_dir <= 0;  // change direction to left          
            if (y <= H_SIZE + 1)  // edge of square at top of screen
                y_dir <= 1;  // change direction to down
            if (y >= (D_HEIGHT - H_SIZE - 1))  // edge of square at bottom
                y_dir <= 0;  // change direction to up              
        end
    end
endmodule








module top(
    input wire CLK,             // board clock: 100 MHz on Arty/Basys3/Nexys
    input wire RST_BTN,         // reset button
    output wire VGA_HS_O,       // horizontal sync output
    output wire VGA_VS_O,       // vertical sync output
    output wire [3:0] VGA_R,    // 4-bit VGA red output
    output wire [3:0] VGA_G,    // 4-bit VGA green output
    output wire [3:0] VGA_B     // 4-bit VGA blue output
    );

    wire rst = ~RST_BTN;    // reset is active low on Arty & Nexys Video
    // wire rst = RST_BTN;  // reset is active high on Basys3 (BTNC)

    wire [9:0] x;  // current pixel x position: 10-bit value: 0-1023
    wire [8:0] y;  // current pixel y position:  9-bit value: 0-511
    wire animate;  // high when we're ready to animate at end of drawing

    // generate a 25 MHz pixel strobe
    reg [15:0] cnt = 0;
    reg pix_stb = 0;
    always @(posedge CLK)
        {pix_stb, cnt} <= cnt + 16'h4000;  // divide by 4: (2^16)/4 = 0x4000

    vga640x480 display (
        .i_clk(CLK),
        .i_pix_stb(pix_stb),
        .i_rst(rst),
        .o_hs(VGA_HS_O), 
        .o_vs(VGA_VS_O), 
        .o_x(x), 
        .o_y(y),
        .o_animate(animate)
    );

    wire sq_a, sq_b, sq_c;
    wire [11:0] sq_a_x1, sq_a_x2, sq_a_y1, sq_a_y2;  // 12-bit values: 0-4095 
    wire [11:0] sq_b_x1, sq_b_x2, sq_b_y1, sq_b_y2;
    wire [11:0] sq_c_x1, sq_c_x2, sq_c_y1, sq_c_y2;

    square #(.IX(160), .IY(120), .H_SIZE(60)) sq_a_anim (
        .i_clk(CLK), 
        .i_ani_stb(pix_stb),
        .i_rst(rst),
        .i_animate(animate),
        .o_x1(sq_a_x1),
        .o_x2(sq_a_x2),
        .o_y1(sq_a_y1),
        .o_y2(sq_a_y2)
    );

    square #(.IX(320), .IY(240), .IY_DIR(0)) sq_b_anim (
        .i_clk(CLK), 
        .i_ani_stb(pix_stb),
        .i_rst(rst),
        .i_animate(animate),
        .o_x1(sq_b_x1),
        .o_x2(sq_b_x2),
        .o_y1(sq_b_y1),
        .o_y2(sq_b_y2)
    );    

    square #(.IX(480), .IY(360), .H_SIZE(100)) sq_c_anim (
        .i_clk(CLK), 
        .i_ani_stb(pix_stb),
        .i_rst(rst),
        .i_animate(animate),
        .o_x1(sq_c_x1),
        .o_x2(sq_c_x2),
        .o_y1(sq_c_y1),
        .o_y2(sq_c_y2)
    );

    assign sq_a = ((x > sq_a_x1) & (y > sq_a_y1) &
        (x < sq_a_x2) & (y < sq_a_y2)) ? 1 : 0;
    assign sq_b = ((x > sq_b_x1) & (y > sq_b_y1) &
        (x < sq_b_x2) & (y < sq_b_y2)) ? 1 : 0;
    assign sq_c = ((x > sq_c_x1) & (y > sq_c_y1) &
        (x < sq_c_x2) & (y < sq_c_y2)) ? 1 : 0;

    assign VGA_R[3] = sq_a;  // square a is red
    assign VGA_G[3] = sq_b;  // square b is green
    assign VGA_B[3] = sq_c;  // square c is blue
endmodule







module vga640x480(
    input wire i_clk,           // base clock
    input wire i_pix_stb,       // pixel clock strobe
    input wire i_rst,           // reset: restarts frame
    output wire o_hs,           // horizontal sync
    output wire o_vs,           // vertical sync
    output wire o_blanking,     // high during blanking interval
    output wire o_active,       // high during active pixel drawing
    output wire o_screenend,    // high for one tick at the end of screen
    output wire o_animate,      // high for one tick at end of active drawing
    output wire [9:0] o_x,      // current pixel x position
    output wire [8:0] o_y       // current pixel y position
    );

    // VGA timings https://timetoexplore.net/blog/video-timings-vga-720p-1080p
    localparam HS_STA = 16;              // horizontal sync start
    localparam HS_END = 16 + 96;         // horizontal sync end
    localparam HA_STA = 16 + 96 + 48;    // horizontal active pixel start
    localparam VS_STA = 480 + 11;        // vertical sync start
    localparam VS_END = 480 + 11 + 2;    // vertical sync end
    localparam VA_END = 480;             // vertical active pixel end
    localparam LINE   = 800;             // complete line (pixels)
    localparam SCREEN = 524;             // complete screen (lines)

    reg [9:0] h_count;  // line position
    reg [9:0] v_count;  // screen position

    // generate sync signals (active low for 640x480)
    assign o_hs = ~((h_count >= HS_STA) & (h_count < HS_END));
    assign o_vs = ~((v_count >= VS_STA) & (v_count < VS_END));

    // keep x and y bound within the active pixels
    assign o_x = (h_count < HA_STA) ? 0 : (h_count - HA_STA);
    assign o_y = (v_count >= VA_END) ? (VA_END - 1) : (v_count);

    // blanking: high within the blanking period
    assign o_blanking = ((h_count < HA_STA) | (v_count > VA_END - 1));

    // active: high during active pixel drawing
    assign o_active = ~((h_count < HA_STA) | (v_count > VA_END - 1)); 

    // screenend: high for one tick at the end of the screen
    assign o_screenend = ((v_count == SCREEN - 1) & (h_count == LINE));

    // animate: high for one tick at the end of the final active pixel line
    assign o_animate = ((v_count == VA_END - 1) & (h_count == LINE));

    always @ (posedge i_clk)
    begin
        if (i_rst)  // reset to start of frame
        begin
            h_count <= 0;
            v_count <= 0;
        end
        if (i_pix_stb)  // once per pixel
        begin
            if (h_count == LINE)  // end of line
            begin
                h_count <= 0;
                v_count <= v_count + 1;
            end
            else 
                h_count <= h_count + 1;

            if (v_count == SCREEN)  // end of screen
                v_count <= 0;
        end
    end
endmodule







//Content from Lab 7 Part 1



//module SRAM(KEY, SW, HEX0, HEX2, HEX4, HEX5);
//	
//	input [9:0] SW;
//	input [3:0] KEY;
//	output [6:0] HEX0, HEX2, HEX4, HEX5;
//	
//	wire [3:0] RAM_out;
//	
//	hexDecoder h0(RAM_out[3:0], HEX0[6:0]);
//	hexDecoder h2(SW[3:0], HEX2[6:0]);
//	hexDecoder h4(SW[7:4], HEX4[6:0]);
//	hexDecoder h5(SW[7:4], HEX5[6:0]);
//	
//	ram32x4 SRAM(SW[8:4], KEY[0], SW[3:0], SW[9], RAM_out); // address, clock, data, wren, q
//	
//endmodule
//
//module hexDecoder(In, Out);
//
//	input [3:0] In;
//	output [6:0] Out;
//	
//	assign Out[0] = (~In[3] & ~In[2] & ~In[1] & In[0]) | (~In[3] & In[2] & ~In[1] & ~In[0]) | (In[3] & ~In[2] & In[1] & In[0]) | (In[3] & In[2] & ~In[1] & In[0]);
//	assign Out[1] = (~In[3] & In[2] & ~In[1] & In[0]) | (~In[3] & In[2] & In[1] & ~In[0]) | (In[3] & ~In[2] & In[1] & In[0]) | (In[3] & In[2] & ~In[1] & ~In[0]) | (In[3] & In[2] & In[1] & ~In[0]) | (In[3] & In[2] & In[1] & In[0]);
//	assign Out[2] = (~In[3] & ~In[2] & In[1] & ~In[0]) | (In[3] & In[2] & ~In[1] & ~In[0]) | (In[3] & In[2] & In[1] & ~In[0]) | (In[3] & In[2] & In[1] & In[0]);
//	assign Out[3] = (~In[3] & ~In[2] & ~In[1] & In[0]) | (~In[3] & In[2] & ~In[1] & ~In[0]) | (~In[3] & In[2] & In[1] & In[0]) | (In[3] & ~In[2] & In[1] & ~In[0]) | (In[3] & In[2] & In[1] & In[0]);
//	assign Out[4] = (~In[3] & ~In[2] & ~In[1] & In[0]) | (~In[3] & ~In[2] & In[1] & In[0]) | (~In[3] & In[2] & ~In[1] & ~In[0]) | (~In[3] & In[2] & ~In[1] & In[0]) | (~In[3] & In[2] & In[1] & In[0]) | (In[3] & ~In[2] & ~In[1] & In[0]);
//	assign Out[5] = (~In[3] & ~In[2] & ~In[1] & In[0]) | (~In[3] & ~In[2] & In[1] & ~In[0]) | (~In[3] & ~In[2] & In[1] & In[0]) | (~In[3] & In[2] & In[1] & In[0]) | (In[3] & In[2] & ~In[1] & In[0]);
//	assign Out[6] = (~In[3] & ~In[2] & ~In[1] & ~In[0]) | (~In[3] & ~In[2] & ~In[1] & In[0]) | (~In[3] & In[2] & In[1] & In[0]) | (In[3] & In[2] & ~In[1] & ~In[0]);
//	
//endmodule





