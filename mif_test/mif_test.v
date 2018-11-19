module mif_test (
	CLOCK_50,						//	On Board 50 MHz
	SW,								// On Board Switches
	KEY,							// On Board Keys
	// The ports below are for the VGA output.  Do not change.
	VGA_CLK,   						//	VGA Clock
	VGA_HS,							//	VGA H_SYNC
	VGA_VS,							//	VGA V_SYNC
	VGA_BLANK_N,						//	VGA BLANK
	VGA_SYNC_N,						//	VGA SYNC
	VGA_R,   						//	VGA Red[9:0]
	VGA_G,	 						//	VGA Green[9:0]
	VGA_B   						//	VGA Blue[9:0]
);
	
	input			CLOCK_50;				//	50 MHz
	input	[3:0]	KEY;
	input	[9:0]	SW;
	// Declare your inputs and outputs here
	// Do not change the following outputs
	output			VGA_CLK;   				//	VGA Clock
	output			VGA_HS;					//	VGA H_SYNC
	output			VGA_VS;					//	VGA V_SYNC
	output			VGA_BLANK_N;				//	VGA BLANK
	output			VGA_SYNC_N;				//	VGA SYNC
	output	[7:0]	VGA_R;   				//	VGA Red[7:0] Changed from 10 to 8-bit DAC
	output	[7:0]	VGA_G;	 				//	VGA Green[7:0]
	output	[7:0]	VGA_B;   				//	VGA Blue[7:0]
	
	
	
	wire clk = CLOCK_50;
	wire resetn, load_in;
	wire [8:0] colour_out;
	
	assign resetn = KEY[0];
	assign load_in = KEY[3];
	
	wire [7:0] x = {4'b0000, SW[3:0]};
	wire [6:0] y = {2'b00, SW[8:4]};
	
	
	
	ram_block helmet(
		,
		clk,
		9'd0,
		load_in,
		colour_out
	);
	
	
	
	vga_adapter VGA(
			.resetn(resetn),
			.clock(CLOCK_50),
			.colour(colour_out),
			.x(x),
			.y(y),
			.plot(load_in),
			/* Signals for the DAC to drive the monitor. */
			.VGA_R(VGA_R),
			.VGA_G(VGA_G),
			.VGA_B(VGA_B),
			.VGA_HS(VGA_HS),
			.VGA_VS(VGA_VS),
			.VGA_BLANK(VGA_BLANK_N),
			.VGA_SYNC(VGA_SYNC_N),
			.VGA_CLK(VGA_CLK));
		defparam VGA.RESOLUTION = "320x240";
		defparam VGA.MONOCHROME = "FALSE";
		defparam VGA.BITS_PER_COLOUR_CHANNEL = 1;
		defparam VGA.BACKGROUND_IMAGE = "head_background.mif";
	
endmodule







//	always @(posedge clk) begin
//		if (clear) begin
//			x <= counter [14:7];
//			y <= counter [6:0];
//			if (counter == 15'd32767) begin 
//				counter <= 0;
//				plotterDone <= 1;
//			end else begin 
//				counter <= counter + 1;
//				plotterDone <= 0;
//			end
//			//plotterDone <= (counter == 15'd32767) ? 1 : 0;
//			//writeEn <= 1; // override writeEn
//			colour <= 3'b000; // overwrites colour to black
//
//		end else if (plot) begin
//			//writeEn <= plot; // forward writeEn
//			plotterDone <= 0; // plotterDone is reserved for clear
//			x <= xin + counter[3:2];
//			y <= yin + counter[1:0];
//			if (counter == 15'd15) begin 
//				counter <= 0;
//			end else begin 
//				counter <= counter + 1;	
//			end
//			//plotterDone <= (counter == 15'd15) ? 1 : 0;
//			colour <= 3'b111; // Change this EDIT to allow changeable colour output
//		end
//
//		// reset registers
//		if (~resetn) begin
//			// XR <= 0;
//			// YR <= 0;
//			//colourR <= 0;
//			x <= 8'd50;
//			y <= 0;
//			colour <= 0;
//			counter <= 0;
//			//writeEn <= 0;
//			plotterDone <= 0;
//		end
//		// if (~plot & ~clear) counter <= 0; // reset counter when plot and clear is not enabled
//		// else counter <= counter + 1; // otherwise count up
//		
//	end