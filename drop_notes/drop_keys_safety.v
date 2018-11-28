// Integrated version
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

 module drop_notes (
	clk,								//On Board 50 MHz
	reset,
	switches,								// On Board Switches for debugging

//	correct_notes,
	pause,
	stop,
	
	notes_to_play,					// Notes to comparator
	
	// The ports below are for the VGA output.  Do not change.
	VGA_CLK,   						//	VGA Clock
	VGA_HS,							//	VGA H_SYNC
	VGA_VS,							//	VGA V_SYNC
	VGA_BLANK_N,						//	VGA BLANK
	VGA_SYNC_N,						//	VGA SYNC
	VGA_R,   						//	VGA Red[9:0]
	VGA_G,	 						//	VGA Green[9:0]
	VGA_B	   						//	VGA Blue[9:0]
);
	
	input	clk;				//	50 MHz
	input reset;
	input	[4:0]	switches;

//	input [4:0] correct_notes;		// Input from comparator about what notes were correctly hit
	input pause;
	input stop;

	output [4:0] notes_to_play;	// not going to touch this for now; game logic
	
	// Do not change the following outputs
	output	VGA_CLK;   				//	VGA Clock
	output	VGA_HS;					//	VGA H_SYNC
	output	VGA_VS;					//	VGA V_SYNC
	output	VGA_BLANK_N;				//	VGA BLANK
	output	VGA_SYNC_N;				//	VGA SYNC
	output	[7:0]	VGA_R;   				//	VGA Red[7:0] Changed from 10 to 8-bit DAC
	output	[7:0]	VGA_G;	 				//	VGA Green[7:0]
	output	[7:0]	VGA_B;   				//	VGA Blue[7:0]
	
/*
 * -------------------------------------------------------------------------------------------------------------------------------
 * Wire creation
 * -------------------------------------------------------------------------------------------------------------------------------
 */
	
	wire beat;
	
	// Wires for the FSM
	wire FSM_shift;
	wire FSM_clear;
	wire FSM_plot;
	wire FSM_pause;
	
	wire done_xy;
	wire done_load;
	
	// Wires for game logic
	wire [4:0] note_to_play;
	wire [4:0] chorus_notes; // Send correct notes to register

	// Wires for the plotter and x/y calculator
	wire enablePlotter;
	wire [4:0] register_data;
	
	// Wires for the VGA adapter
	wire [8:0] x_to_VGA;
	wire [7:0] y_to_VGA;
	wire [8:0] colour_to_VGA;
		
//	wire VGA_plot;
	
	// Wires for the counters
	wire printed_register; // Reading from register completed
	wire o_inc_y;
	wire plotterDone;
	wire [2:0] current_x;
	wire [2:0] current_y;
	//Wires indicate a change in location has occurred
	wire x_change;
	wire y_change;
	
	// Wires for the register
		
	wire [8:0] x_to_plotter;
	wire [7:0] y_to_plotter;
	
	
	
/*
 * -------------------------------------------------------------------------------------------------------------------------------
 * Module instantiation
 * -------------------------------------------------------------------------------------------------------------------------------
 */

//	note_sender(
//		.clk(CLOCK_50),
//		.pause(pause),
//		.stop(stop),
//		.exp_notes(chorus_notes) // 5 bits
//		);
	
	// FSM:
	control myControl (
		.reset(reset),
		.clk (CLOCK_50),
		.beat(beat),
		.start(~stop), // If pause is low, start the game
		.printed_register(printed_register), // Read through the register; make sure this is the correct signal
		.check_for_background(colour_to_VGA),
		.plot_done(plotterDone),
		
		// Wait for column change
		.done_xy(done_xy),
		.counted_rows(o_inc_y),
		
		// Wait for reg change
		.load_reg(done_load),
		
//		.FSM_plotEn(VGA_plot),
		.FSM_clear(FSM_clear), // Tells the plotter to erase
		.FSM_plot(FSM_plot), // Tells the plotter to print
		.FSM_shift(FSM_shift), // Tells the register to shift down
		.FSM_pause(FSM_pause) // Pauses the plotter
				
	);
	
	
	find_x_and_y calculator(
	
		.clk(CLOCK_50),
		
		.from_register(register_data), // 5-bit data input from the register
		.x_location(current_x), // counter from the printer, takes in "current_row_count"
		.y_location(current_y), // address of the current data, takes in
		.inc_y(o_inc_y),

		.enablePlotter(enablePlotter),
		.x_to_plotter(x_to_plotter), // goes to plotter
		.y_to_plotter(y_to_plotter),
		.done_x_and_y(done_xy)
	);
	
	
	notes_register notes(
				
		.clk(CLOCK_50),
		.reset(reset),
		
		.shiftEnable(FSM_shift), // Controls if the FSM is telling it to drop down
		.y_level(current_y),
		.FSM_notes(switches[4:0]/*chorus_notes*/), // Input for the notes being loaded from the chorus, or switches for debugging
		
		.note_to_play(notes_to_play), // Loose end right now, disconnected
		.register_notes_out(register_data) // The value of the data being read (I expect this needs to be a reg but I'm not certain)
	);
	
	
	x_counter rows(
		
		.clk(CLOCK_50),
		.reset(reset),
		.plotted_note(plotterDone),
		.y_change(y_change),
		
		.inc_y(o_inc_y),
		.current_count(current_x),
		.counted(x_change)
		
	);
	
	
	y_counter big_count(
		.clk(CLOCK_50),
		.reset(reset),
		.inc_y(o_inc_y),
		
		.printed_register(printed_register), // High = whole register has been read from
		.current_count(current_y),
		.counted(y_change)
		
	);
	
	
	rate_driver eighth_note(
		
		.clk(CLOCK_50),
		.beat(beat)
		
	);
	
	
	plotter myPlotter (
		.clk (CLOCK_50),
		.reset (reset),
		.pause(FSM_pause),
		.enablePlotter(enablePlotter),
		.plot_note (FSM_plot),
		.clear_note (FSM_clear),
		.x_in (x_to_plotter), // 9-bit
		.y_in (y_to_plotter), // 8-bit
		
		.x_to_VGA (x_to_VGA), // 9-bit
		.y_to_VGA (y_to_VGA), // 8-bit
		.colour_to_VGA (colour_to_VGA), // 9-bit
		.plotterDone (plotterDone)
	);


	// VGA ADAPTER
	// Create an Instance of a VGA controller - there can be only one!
	// Define the number of colours as well as the initial background
	// image file (.MIF) for the controller.
	vga_adapter VGA(
			.resetn(~reset),
			.clock(clk),
			.colour(colour_out_real),
			.x(x_to_VGA),
			.y(y_to_VGA),
			.plot(1),
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
		defparam VGA.BITS_PER_COLOUR_CHANNEL = 3;
		defparam VGA.BACKGROUND_IMAGE = "guitar_hero_background.mif";
	
endmodule


/*
 * -------------------------------------------------------------------------------------------------------------------------------
 * Rate driver: driven high every "beat"
 * -------------------------------------------------------------------------------------------------------------------------------
 */
 
module rate_driver (

    input clk,
	 
    output reg beat
);
	
	localparam EIGHTH_NOTE = 25'd13157895;
	
	reg [24:0] t = 25'd0;
	
	always@(posedge clk)
	begin
		if (t == EIGHTH_NOTE)
		begin
			t <= 25'd0;
			beat <= 1'b1;
		end
		
		else
		begin
			t <= t+1;
			beat <= 1'b0;
		end
			
	end

endmodule
