/*
 * -------------------------------------------------------------------------------------------------------------------------------
 * DROP KEYS MODULE
 * 
 * Basic dimensions:
 * X-dimension: 9-bits [320 pixels]
 * Y-dimension: 8-bits [240 pixels]
 * -------------------------------------------------------------------------------------------------------------------------------
 */

`timescale 1ns / 1ns 

 module drop_keys (
	CLOCK_50,							//On Board 50 MHz
	SW,								// On Board Switches
	KEY,								// On Board Keys
	
	notes_to_play//,
	
	// The ports below are for the VGA output.  Do not change.
//	VGA_CLK,   						//	VGA Clock
//	VGA_HS,							//	VGA H_SYNC
//	VGA_VS,							//	VGA V_SYNC
//	VGA_BLANK_N,					//	VGA BLANK
//	VGA_SYNC_N,						//	VGA SYNC
//	VGA_R,   						//	VGA Red[9:0]
//	VGA_G,	 						//	VGA Green[9:0]
//	VGA_B	   						//	VGA Blue[9:0]
);
	 
	input	CLOCK_50;				//	50 MHz
	input	[3:0]	KEY;
	input	[9:0]	SW;
	
	output [4:0] notes_to_play;
	
	// Declare your inputs and outputs here
	// Do not change the following outputs
//	output	VGA_CLK;   				//	VGA Clock
//	output	VGA_HS;					//	VGA H_SYNC
//	output	VGA_VS;					//	VGA V_SYNC
//	output	VGA_BLANK_N;				//	VGA BLANK
//	output	VGA_SYNC_N;				//	VGA SYNC
//	output	[7:0]	VGA_R;   				//	VGA Red[7:0] Changed from 10 to 8-bit DAC
//	output	[7:0]	VGA_G;	 				//	VGA Green[7:0]
//	output	[7:0]	VGA_B;   				//	VGA Blue[7:0]
	
	wire reset;
	assign reset = ~KEY[0]; // Inverting the input here means we can consider the reset as we think intuitively: resets when pressed
	
	wire i_start = ~KEY[3];
	
/* -------------------------------------------------------------------------------------------------------------------------------
 * Wire creation
 * -------------------------------------------------------------------------------------------------------------------------------*/
	
	wire xctrl_equal;
	wire yctrl_equal;
	
	wire x_equal;
	wire y_equal;
	
	wire plotted_one;
	
	wire xctrl_sel;
	wire yctrl_sel;
	
	wire colour;
	wire colour_en;
	wire [8:0] colour_VGA;
	
	wire current_note;
	wire [3:0] current_state, next_state;
	
	wire xctrl_en;
	wire yctrl_en;
	
	wire x_en;
	wire y_en;
	
	wire x_sel;
	wire y_sel;
	
	wire xeq_en;
	wire yeq_en;
	
	wire reg_en;
	wire beat;
	wire plot;
	
	wire [8:0] x_VGA;
	wire [7:0] y_VGA;
			
/* -------------------------------------------------------------------------------------------------------------------------------
 * Module instantiation
 * -------------------------------------------------------------------------------------------------------------------------------*/

control myControl (
	.clk(CLOCK_50),
	.reset(reset),
	
	.i_beat(beat), // Rate-driven clock
	.i_start(i_start), // Controls if we should start dropping keys
	
	.i_xctrl_equal(xctrl_equal),
	.i_yctrl_equal(yctrl_equal),
	
	.i_x_equal(x_equal),
	.i_y_equal(y_equal),
	
	.i_plotted_one(plotted_one),
	
	
	.o_xctrl_sel(xctrl_sel),
	.o_yctrl_sel(yctrl_sel),
	
	.o_colour(colour),
	.o_colour_en(colour_en),
	
	.o_xctrl_en(xctrl_en),
	.o_yctrl_en(yctrl_en),
	
	.o_x_en(x_en),
	.o_y_en(y_en),
	
	.o_x_sel(x_sel),
	.o_y_sel(y_sel),
	
	.o_xeq_en(xeq_en),
	.o_yeq_en(yeq_en),
	
	.o_reg_en(reg_en),
	
	// CHECK: this signal might not be working properly
	.o_plot(plot),
	
	// For debugging
	.c_state(current_state),
	.n_state(next_state)

	
);


datapath myData(
	.clk(CLOCK_50),
	.reset(reset),
	
	.i_notes(SW[4:0]),
	
	.i_xctrl_sel(xctrl_sel),
	.i_yctrl_sel(yctrl_sel),
	
	.i_x_sel(x_sel), // 
	.i_y_sel(y_sel), // 
	
	.i_colour(colour), // 
	
	.i_colour_en(colour_en), //
		
	// Values traversing through the register
	.i_xctrl_en(xctrl_en), // 
	.i_yctrl_en(yctrl_en), // 
	// Values being changed by counting up; to be printed to the VGA
	.i_x_en(x_en), // 
	.i_y_en(y_en), // 
	// Values to count up to
	.i_xeq_en(xeq_en), // 
	.i_yeq_en(yeq_en), // 
	
	.i_reg_en(reg_en), // 

	
	.o_x_VGA(x_VGA), // 
	.o_y_VGA(y_VGA), // 
	
	.o_xctrl_equal(xctrl_equal), // 
	.o_yctrl_equal(yctrl_equal), // 
	
	.o_x_equal(x_equal), // 
	.o_y_equal(y_equal), // 
	
	.o_colour_VGA(colour_VGA), // 
	.o_beat(beat), // 
	
	.o_notes_to_play(notes_to_play), // 
	.o_current_note(current_note), // 
	
	.o_plotted_one(plotted_one)
);


// VGA ADAPTER
// Create an Instance of a VGA controller - there can be only one!
// Define the number of colours as well as the initial background
// image file (.MIF) for the controller.
//	vga_adapter VGA(
//			.resetn(~reset),
//			.clock(CLOCK_50),
//			.colour(colour_VGA),
//			.x(x_VGA),
//			.y(y_VGA),
//			.plot(1),
//			/* Signals for the DAC to drive the monitor. */
//			.VGA_R(VGA_R),
//			.VGA_G(VGA_G),
//			.VGA_B(VGA_B),
//			.VGA_HS(VGA_HS),
//			.VGA_VS(VGA_VS),
//			.VGA_BLANK(VGA_BLANK_N),
//			.VGA_SYNC(VGA_SYNC_N),
//			.VGA_CLK(VGA_CLK));
//		defparam VGA.RESOLUTION = "320x240";
//		defparam VGA.MONOCHROME = "FALSE";
//		defparam VGA.BITS_PER_COLOUR_CHANNEL = 3;
//		defparam VGA.BACKGROUND_IMAGE = "guitar_hero_background.mif";

endmodule