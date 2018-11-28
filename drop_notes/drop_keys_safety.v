// Integrated version
/*
 * -------------------------------------------------------------------------------------------------------------------------------
 * DROP KEYS MODULE
 * 
 * This module performs the animation for the dropping of notes down the screen corresponding to the 0s and 1s stored
 * in a 5-bit, 32-word register.
 *
 * The logic is heavily dependent on the nesting of three counters.
 * From highest level to lowest: address, printed_row, printed_note.
 *
 * Basic dimensions of important things:
 * X-dimension: 9-bits [320 pixels]
 * Y-dimension: 8-bits [240 pixels]
 * notes_register: 32 words of 5-bits, ie. reg [4:0] mem[0:31];
 * printed_note counter: 4-bit
 * printed_row counter: 3-bit
 * address counter: 5-bit
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
	
	reg [8:0] colour_out_real; // Actual output to the VGA
	
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
 
	// Colour select
	always @(*)
	begin
		if(colour_to_VGA != 9'b000000000)
		begin
			case (current_x)
				3'd1: colour_out_real = 9'b000111000; // green
				3'd2: colour_out_real = 9'b111000000; // red
				3'd3: colour_out_real = 9'b111111000; // yellow
				3'd4: colour_out_real = 9'b000000111; // blue
				3'd5: colour_out_real = 9'b011111000; // orange
				default: colour_out_real = 9'b111111111; // white
			endcase
		end
		else colour_out_real = 9'b000000000; // black
	end

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
 * Module definitions:
 * notes_register, plotter, y_counter, x_counter, rate_driver, control path
 * -------------------------------------------------------------------------------------------------------------------------------
 */

 
/*
 * -------------------------------------------------------------------------------------------------------------------------------
 * notes_register: contains the values for all the notes on the screen and drops them down.
 * -------------------------------------------------------------------------------------------------------------------------------
 */
module notes_register (
		
	input clk,
	input reset,
	
	input shiftEnable, // Controls if the FSM is telling it to drop down
	input [2:0]  y_level, // Specifies the location in memory to reach when reading
	input [4:0] FSM_notes, // Input for the notes being loaded from the "top"
	
	output [4:0] note_to_play,
	output [4:0] register_notes_out // The value of the data being read

);
	
	wire [7:0] g1_out, r2_out, y3_out, b4_out, o5_out;
	
	// Naming convention of shift registers: <colour><row>
	//				Arguments:	clk		reset		data_in				shiftEnable		note_to_play		register_out
	shift_register green1(	clk,		reset,	FSM_notes[0],		shiftEnable,			note_to_play[0],	g1_out);
	
	shift_register red2(		clk,		reset,	FSM_notes[1],		shiftEnable,			note_to_play[1],	r2_out);
	
	shift_register yellow3(	clk,		reset,	FSM_notes[2],		shiftEnable,			note_to_play[2],	y3_out);
	
	shift_register blue4(	clk,		reset,	FSM_notes[3],		shiftEnable,			note_to_play[3],	b4_out);
	
	shift_register orange5(	clk,		reset,	FSM_notes[4],		shiftEnable,			note_to_play[4],	o5_out);
	
	
	// Concatenate all shift register outputs at one level together
	// Does this work outside of an always block?
	assign register_notes_out[4:0] = {o5_out[y_level], b4_out[y_level], y3_out[y_level], r2_out[y_level], g1_out[y_level]};
	
endmodule


/*
 * -------------------------------------------------------------------------------------------------------------------------------
 * Calculates the x and y location of the block to print from the register input
 * -------------------------------------------------------------------------------------------------------------------------------
 */
 
 
module find_x_and_y(
	
	input clk,
	
	input [4:0] from_register, // 5-bit data from the register
	input [2:0] x_location, // counter from the printer, takes in "current_x"
	input [2:0] y_location, // address of the current data, takes in "current_row_count"
	input inc_y,
	
	output reg enablePlotter,
	output reg [8:0] x_to_plotter, // goes to plotter
	output reg [7:0] y_to_plotter, // goes to plotter
	output reg done_x_and_y
	
);

	always @ (posedge clk)
	begin
		
		enablePlotter	<= 0;

		//EDITED
		if(from_register[x_location] && (x_location < 3'd6) && ~inc_y) // Make sure where we are in the 5 bits is not empty
			begin
				enablePlotter	<= 1;
			end
			
//		done_x_and_y <= 0; // More of a dummy variable now than anything; consider deleting
		
	end
	
	always @(*)
	begin
		case (x_location)
			3'd1: x_to_plotter = 130 - y_location*12;
			3'd2: x_to_plotter = 145 - y_location*6;
			3'd3: x_to_plotter = 160;
			3'd4: x_to_plotter = 175 + y_location*6;
			3'd5: x_to_plotter = 190 + y_location*12;
		endcase
		
		y_to_plotter <= y_location*26 + 40;
		
	end	
	
endmodule
 
/*
 * -------------------------------------------------------------------------------------------------------------------------------
 * Draws or erases a square at the location that is fed in. plotterDone goes high when complete.
 * -------------------------------------------------------------------------------------------------------------------------------
 */
module plotter (
	input clk, reset, pause,
	input plot_note, clear_note,
	input enablePlotter,
	input [8:0] x_in,
	input [7:0] y_in,
	
	output reg [8:0] x_to_VGA,
	output reg [7:0] y_to_VGA,
	output reg [8:0] colour_to_VGA, // Will be constant to begin with
	output reg plotterDone // Very important to the functionality of the counter nesting
);
	
	reg [3:0] counter;
	
	always @(posedge clk) begin
		
		plotterDone <= 0;
		// Erasing half of the module
			if (clear_note && enablePlotter && ~plotterDone) begin // Is this the right AND?
//				plotterDone <= 0;
				
				x_to_VGA <= x_in + counter[3:2];
				y_to_VGA <= y_in + counter[1:0];
				
				counter <= (counter == 4'd15) ? 4'd0 : (counter + 1);
				
				// *** I changed the below for ModelSim, might not work for FPGA
//				plotterDone <= (counter == 4'd15) ? 1 : 0;
				if(counter == 4'd15) plotterDone <= 1;

				colour_to_VGA <= 9'd0; // Output black; how do we get this to potentially reprint the background? Is it as easy as getting this xy-coordinate of the background .mif memory?
			end // clear half
			
			// Plotting half of the module
			
			else if (plot_note && enablePlotter && ~plotterDone) begin // The right AND for the job?
//				plotterDone <= 0;
				
				x_to_VGA <= x_in + counter[3:2]; // This implementation will need to change as we insert .mifs into the mix
				y_to_VGA <= y_in + counter[1:0];
				
				counter <= (counter == 4'd15) ? 4'd0 : (counter + 1); // Reset counter if full, increment if not
				
				// *** I changed the below for ModelSim, might not work for FPGA
//				plotterDone <= (counter == 4'd15) ? 1 : 0; // Signal completion if counter is all done
				if(counter == 4'd15) plotterDone <= 1;

				colour_to_VGA <= 9'b111111111; // This will need to become an inserted value from a .mif once we get that going
			end // plot half
			
			else if(~enablePlotter && (plot_note || clear_note) && ( (x_to_VGA != 0) || (y_to_VGA != 0) ) && ~plotterDone ) // This is for counting when there's nothing there to print
			begin
				
				counter <= 0;
				plotterDone <= 1;
		end

		// reset registers
		if (reset)
		begin
		
			x_to_VGA <= 0;
			y_to_VGA <= 0;
			colour_to_VGA <= 9'd0;
			counter <= 0;

			plotterDone <= 0;
			
		end // reset if
	end  // always block
endmodule // plotter



/*
 * -------------------------------------------------------------------------------------------------------------------------------
 * y_counter: output high when all rows of the register have been printed
 * -------------------------------------------------------------------------------------------------------------------------------
 */
 
 
module y_counter (
	input clk,
	input reset,
	input inc_y, // Increments this counter (the outpute from the printed_row subcounter when it's finished)
	
	output reg printed_register, // Tells the FSM to change state from drawing or deleting from the register data
	output reg [2:0] current_count,
	output reg counted // 

);
//	reg [4:0] counter = 0;
//	current_counter = 0;

	always @(posedge clk)
	begin
		printed_register <= 0;
		counted <= 0;
		
		if(inc_y) begin
			current_count <= current_count + 1;
			counted <= 1;
		end
		
		if(reset)
			current_count		<= 0;
		else if(current_count == 3'd7)
		begin
			printed_register <= 1;
			current_count <= 0;
		end
		
	end // counter
	
endmodule



/*
 * -------------------------------------------------------------------------------------------------------------------------------
 * x_counter counter: output goes high for every word in the register printed
 * -------------------------------------------------------------------------------------------------------------------------------
 */


module x_counter (
	input clk,
	input reset,
	input plotted_note, // Increments this counter (the output from plotter when it's finished)
	input printed_register,
	input y_change,
	
	output reg inc_y, // Increments y_counter, goes high when all 5 notes are done
	output reg [2:0] current_count,
	output reg counted // 
);
		
	always @(posedge clk)
	begin
		
		inc_y <= 0;
		counted <= 0;
		
		if(reset || y_change) current_count <= 0;
		
		
		if(current_count == 3'd5) // Watch out for off-by-one errors
		begin
			inc_y <= 1;
			current_count <= 0;
		end
		else if(plotted_note) // Might want these to be separate if statements
		begin
			current_count <= current_count + 1;
			counted <= 1;
		end
		
	end // counter
		
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


/*
 * -------------------------------------------------------------------------------------------------------------------------------
 * Control path
 * -------------------------------------------------------------------------------------------------------------------------------
 */
module control (
	input reset, clk,
	
	input beat, // Rate-driven clock
	input start, // Controls if we should start dropping keys
	input printed_register, // Check if register has been 100% read [input from "printed_register", y_counter module
	input [8:0] check_for_background, // Avoid printing the background of sprites
	input plot_done,
	
	input done_xy,
	input [2:0] counted_rows, // The value of the y-counter
	
	input load_reg,
	
//	output reg FSM_plotEn, // Control VGA plotting
	output reg FSM_clear, // Controls if we are clearing from the register
	output reg FSM_plot, // Controls if we are drawing from the register
	output reg FSM_shift, // Controls if we are still taking in from the register
	output reg FSM_pause
);

	reg [2:0] current_state, next_state;
	
	localparam	MAIN				= 0,
					DEC_REG			= 1,
					DRAW				= 2,
					PAUSE_DRAW		= 3,
					WAIT				= 4,
					ERASE				= 5;
	
	// state table
	always @ (*)
	begin: state_table
		case (current_state)
		
			MAIN: next_state = start ? DEC_REG : MAIN;

			DEC_REG: next_state =  DRAW;//DRAW;
			DRAW: next_state = printed_register ? WAIT : DRAW; // Counted column is if there is a change in the column counter

			WAIT: next_state = beat ? ERASE : WAIT;
			ERASE: next_state = printed_register ? DEC_REG : ERASE;
		
			default: next_state = DEC_REG;
		endcase
	end // state table
	
	
	always @ (*)
	begin: enable_signals
	
		FSM_clear		<= 0;
		FSM_plot			<= 0;
		FSM_shift		<= 0;
		
		case (current_state)
					
			DEC_REG:
			begin
				FSM_shift		<= 1;
			end
				
			DRAW:
			begin
				FSM_plot			<= 1;
			end
			
			ERASE:
			begin
				FSM_clear		<= 1;
			end				
			
		endcase
			
	end // enable signals
	
    // current_state registers
    always@(posedge clk)
    begin: state_FFs
		if(reset)
			begin
				current_state <= MAIN;
			end
		else
//			begin
			current_state <= next_state;
//			end
	end // state_FFS
	
	
endmodule // control


module shift_register(
	input clk,
	input reset,
	input data_in,
	input shiftEnable,
	
	output note_to_play,
	output [7:0] register_out
	);

	reg [7:0] bit_shift_reg;

	always @(posedge clk)
	begin
		if(reset) bit_shift_reg <= 0;
		else
		begin
			if(shiftEnable) bit_shift_reg <= {bit_shift_reg[6:0], data_in};
		end
	end
	
	assign note_to_play = bit_shift_reg[7];
	assign register_out = bit_shift_reg;

endmodule