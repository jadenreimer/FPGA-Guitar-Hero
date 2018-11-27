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

 module drop_keys (
	CLOCK_50,							//On Board 50 MHz
	SW,								// On Board Switches
	KEY,								// On Board Keys
	// The ports below are for the VGA output.  Do not change.
	VGA_CLK,   						//	VGA Clock
	VGA_HS,							//	VGA H_SYNC
	VGA_VS,							//	VGA V_SYNC
	VGA_BLANK_N,						//	VGA BLANK
	VGA_SYNC_N,						//	VGA SYNC
	VGA_R,   						//	VGA Red[9:0]
	VGA_G,	 						//	VGA Green[9:0]
	VGA_B,   						//	VGA Blue[9:0]
	HEX0//,
//	HEX1,
//	HEX2,
//	HEX3,
//	HEX4,
//	HEX5,
//	LEDR
);
	 
	input	CLOCK_50;				//	50 MHz
	input	[3:0]	KEY;
	input	[9:0]	SW;
	// Declare your inputs and outputs here
	// Do not change the following outputs
	output	VGA_CLK;   				//	VGA Clock
	output	VGA_HS;					//	VGA H_SYNC
	output	VGA_VS;					//	VGA V_SYNC
	output	VGA_BLANK_N;				//	VGA BLANK
	output	VGA_SYNC_N;				//	VGA SYNC
	output	[7:0]	VGA_R;   				//	VGA Red[7:0] Changed from 10 to 8-bit DAC
	output	[7:0]	VGA_G;	 				//	VGA Green[7:0]
	output	[7:0]	VGA_B;   				//	VGA Blue[7:0]
	
//	output	[9:0] LEDR;
	output [6:0] HEX0;//, HEX1, HEX2, HEX3, HEX4, HEX5;
	
	wire reset;
	assign reset = ~KEY[0]; // Inverting the input here means we can consider the reset as we think intuitively: resets when pressed
	
	
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
	
//	wire [4:0] note_to_play; // not going to touch this for now; game logic
	
	wire [8:0] x_to_plotter;
	wire [7:0] y_to_plotter;
	
	
	
/*
 * -------------------------------------------------------------------------------------------------------------------------------
 * Module instantiation
 * -------------------------------------------------------------------------------------------------------------------------------
 */
		
	// HEX Displays
//	hex_decoder h5(x_to_VGA[7:4], HEX5);
//	hex_decoder h4(y_to_VGA[3:0], HEX4);
//	
//	hex_decoder h3({1'b0, y_out[6:4]}, HEX3);
//	hex_decoder h2(y_out[3:0], HEX2);
//	
//	hex_decoder h1(4'd0, HEX1);
//	hex_decoder h0({5'd0, colour_out[8:0]}, HEX0);
	
	
	
	// FSM:
	control myControl (
		.reset(reset),
		.clk (CLOCK_50),
		.beat(beat),
		.start(~KEY[3]),
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
		
		// Other inputs go here:
		
	);
	
	
	find_x_and_y calculator(
	
		.clk(CLOCK_50),
		
		.from_register(register_data), // 5-bit data input from the register
		.x_location(current_x), // counter from the printer, takes in "current_row_count"
		.y_location(current_y), // address of the current data, takes in
		.inc_y(o_inc_y),
		
		.plot(FSM_plot),
		.clear(FSM_clear),
		.plotterDone(plotterDone),

		.enablePlotter(enablePlotter),
		.x_to_plotter(x_to_plotter), // goes to plotter
		.y_to_plotter(y_to_plotter),
		.done_x_and_y(done_xy)
	);
	
	
	notes_register notes(
				
		.clk(CLOCK_50),
		.reset(reset),
		.debug(HEX0),
		
		.shiftEnable(FSM_shift), // Controls if the FSM is telling it to drop down
		.y_level(current_y),
		.FSM_notes(SW[4:0]), // Input for the notes being loaded from the "top"
		
		.note_to_play(note_to_play), // Loose end right now, disconnected
		.register_notes_out(register_data) // The value of the data being read (I expect this needs to be a reg but I'm not certain)
	);
	
	
	x_counter rows(
		
		.clk(CLOCK_50),
		.reset(reset),
		.plotted_note(plotterDone),
		.y_change(y_change),
		.plot_enable(enablePlotter), // Check for the case of the last value being added to
				
		.plot(FSM_plot),
		.clear(FSM_clear),
		
		.inc_y(o_inc_y),
		.current_count(current_x),
		.counted(x_change)
		
	);
	
	
	y_counter big_count(
		.clk(CLOCK_50),
		.reset(reset),
		.inc_y(o_inc_y),
		.plotterDone(plotterDone),
		.x_pos(current_x),
		
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
		.x_change(x_change),
		.y_change(o_inc_y),
		
		.notes(SW[4:0]),
		.x_val(current_x),
		
		.x_to_VGA (x_to_VGA), // 9-bit
		.y_to_VGA (y_to_VGA), // 8-bit
		.colour_to_VGA (colour_to_VGA), // 3-bit
		.plotterDone (plotterDone)
	);


	// VGA ADAPTER
	// Create an Instance of a VGA controller - there can be only one!
	// Define the number of colours as well as the initial background
	// image file (.MIF) for the controller.
	vga_adapter VGA(
			.resetn(~reset),
			.clock(CLOCK_50),
			.colour(colour_to_VGA),
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
 * Moduel definitions:
 * notes_register, plotter, y_counter, printer_row, printed_note, rate_driver, control path, datapath [maybe]
 * -------------------------------------------------------------------------------------------------------------------------------
 */

 
/*
 * -------------------------------------------------------------------------------------------------------------------------------
 * Contains the values for all the notes on the screen and drops them down.
 * -------------------------------------------------------------------------------------------------------------------------------
 */


 
module notes_register (
		
	input clk,
	input reset,
	output [6:0] debug,
	
	input shiftEnable, // Controls if the FSM is telling it to drop down
	input [2:0]  y_level, // Specifies the location in memory to reach when reading
	input [4:0] FSM_notes, // Input for the notes being loaded from the "top"
	
	output [4:0] note_to_play,
	output [4:0] register_notes_out // The value of the data being read

);
	
	hex_decoder h0(register_notes_out[3:0], debug);
	
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
	
	input plot,
	input clear,
	input plotterDone, // Might want to remove
	
	output reg enablePlotter,
	output [8:0] x_to_plotter, // goes to plotter
	output [7:0] y_to_plotter, // goes to plotter
	output reg done_x_and_y
	
);

	always @ (posedge clk)
	begin
		
		enablePlotter	<= 0;

		if(from_register[x_location] && (x_location < 3'd5) && ~inc_y) // Make sure where we are in the 5 bits is not empty 
			enablePlotter	<= 1;
		if(~plot && ~clear)
			enablePlotter <= 0;
			
//		done_x_and_y <= 0; // More of a dummy variable now than anything; consider deleting
		
	end
	
	assign x_to_plotter = x_location*52;// + 52;
	assign y_to_plotter = y_location*28 + 8;
	
	
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
	input x_change, // Checks to see if we're changing to prevent plotting an extra pixel
	input y_change,
	
	input [4:0] notes,
	input [2:0] x_val,
	
	output reg [8:0] x_to_VGA,
	output reg [7:0] y_to_VGA,
	output reg [8:0] colour_to_VGA, // Will be constant to begin with
	output reg plotterDone // Very important to the functionality of the counter nesting
);
	
	reg [3:0] counter;
	
	always @(posedge clk) begin
		
		plotterDone <= 0;
		// Erasing half of the module
		if ( (~(plotterDone ) ) /*|| (~(plotterDone && (x_val < 5) && notes[x_val+1]) )*/ )
		begin
			if (clear_note && enablePlotter && ~plotterDone && ~x_change || (clear_note && ~enablePlotter && notes[x_val]) ) begin // Is this the right AND?
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
			
			else if ( (plot_note && enablePlotter && ~plotterDone && ~x_change) || (plot_note && ~enablePlotter && notes[x_val]) ) begin // The right AND for the job?
//				plotterDone <= 0;
				
				x_to_VGA <= x_in + counter[3:2]; // This implementation will need to change as we insert .mifs into the mix
				y_to_VGA <= y_in + counter[1:0];
				
				counter <= (counter == 4'd15) ? 4'd0 : (counter + 1); // Reset counter if full, increment if not
				
				// *** I changed the below for ModelSim, might not work for FPGA
//				plotterDone <= (counter == 4'd15) ? 1 : 0; // Signal completion if counter is all done
				if(counter == 4'd15) plotterDone <= 1;

				colour_to_VGA <= 9'b111111111; // This will need to become an inserted value from a .mif once we get that going
			end // plot half
			
			// ALERT: (x_to_VGA != 0) || (y_to_VGA != 0) is an issue when we're trying to start with zeros
			else if(~enablePlotter && (plot_note || clear_note) && ( (x_to_VGA != 0) || (y_to_VGA != 0) ) && ~plotterDone) // This is for counting when there's nothing there to print
			begin
				
				counter <= 0;
				plotterDone <= 1;
		end
	end // ~y_change
	
	if(y_change) y_to_VGA <= y_in + counter[1:0];

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
	
	input plotterDone,
	input [2:0] x_pos,
	
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
		
//		if( (x_pos == 3'd4) && plotterDone) begin
		if(plotterDone && (x_pos == 3'd4)) begin
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
	
//	assign printed_register = (current_count == 3'd7) ? 1 : 0;
//	assign current_count = reset ? 0 : ( (current_count == 3'd7) ? 0 : (inc_y ? current_count + 1 : current_count) );

	
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
	input plot_enable,
		
	// To reset the counter when we want it done
	input plot,
	input clear,
	
//	input FSM_clear,
//	input FSM_plot,
	
	output reg inc_y, // Increments y_counter, goes high when all 5 notes are done
	output reg [2:0] current_count,
	output reg counted // 
);
		
	always @(posedge clk)
	begin
		
		inc_y <= 0;
		counted <= 0;
		
		if(reset /*|| y_change*/) current_count <= 0;
		
		if(~plot && ~clear) current_count <= 0;
		
		if(current_count == 3'd4 && plotted_note) // Watch out for off-by-one errors
		begin
			inc_y <= 1;
			current_count <= 0;
		end
		else if(plotted_note && current_count < 3'd4) // Might want these to be separate if statements
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
	
//	parameter EIGHTH_NOTE = 25'd16315790;
	
	reg [24:0] t = 25'd0;
	
	always@(posedge clk)
	begin
		if (t == 25'd15000000)
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
//					LOAD_TO_REG		= X,
					DRAW				= 2,
					PAUSE_DRAW		= 3,
//					CYCLE_DRAW		= x,
					WAIT				= 4,
					ERASE				= 5;
//					CYCLE_ERASE		= x,
	
	// state table
	always @ (*)
	begin: state_table
		case (current_state)
		
			MAIN: next_state = start ? DEC_REG : MAIN;
//			LOAD_TO_REG: next_state = printed_register ? DRAW : LOAD_TO_REG;
			DEC_REG: next_state =  DRAW;//DRAW;
			DRAW: next_state = printed_register ? WAIT : DRAW; // Counted column is if there is a change in the column counter
//			PAUSE_DRAW: next_state = (x_counter == 3'd5) ? DRAW : PAUSE_DRAW; // Watch for off-by-one error
//			CYCLE_DRAW: next_state = 
			WAIT: next_state = beat ? ERASE : WAIT;
			ERASE: next_state = printed_register ? DEC_REG : ERASE;
//			CYCLE_ERASE: next_state = 
		
			default: next_state = DEC_REG;
		endcase
	end // state table
	
	
	always @ (*)
	begin: enable_signals
	
//		FSM_writeEn		<= 0;
		FSM_clear		<= 0;
		FSM_plot			<= 0;
		FSM_shift		<= 0;
//		FSM_pause		<= 0;
//		FSM_plotEn		<= 0;
		
		case (current_state)
		
//			MAIN:
			
			DEC_REG:
			begin
//				FSM_writeEn		<= 1;
				FSM_shift		<= 1;
			end
				
			DRAW:
			begin
//				FSM_plotEn		<= (check_for_background == 9'b101010101) ? 0 : 1;
				FSM_plot			<= 1;
			end
				
//			WAIT:

//			PAUSE_DRAW:
//			begin
//				FSM_pause		<= 1;
//			end
				
			ERASE:
			begin
//				FSM_plotEn		<= 1;
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




//reg [2:0] index_of_x;
//reg [4:0] index_of_y;
//index_of_x <= x_in/52 - 52;
//index_of_y <= y_in/17 - 8;


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


module hex_decoder(hex_digit, segments);
    input [3:0] hex_digit;
    output reg [6:0] segments;
   
    always @(*)
        case (hex_digit)
            4'h0: segments = 7'b100_0000;
            4'h1: segments = 7'b111_1001;
            4'h2: segments = 7'b010_0100;
            4'h3: segments = 7'b011_0000;
            4'h4: segments = 7'b001_1001;
            4'h5: segments = 7'b001_0010;
            4'h6: segments = 7'b000_0010;
            4'h7: segments = 7'b111_1000;
            4'h8: segments = 7'b000_0000;
            4'h9: segments = 7'b001_1000;
            4'hA: segments = 7'b000_1000;
            4'hB: segments = 7'b000_0011;
            4'hC: segments = 7'b100_0110;
            4'hD: segments = 7'b010_0001;
            4'hE: segments = 7'b000_0110;
            4'hF: segments = 7'b000_1110;   
            default: segments = 7'h7f;
        endcase
endmodule

/*
 * -------------------------------------------------------------------------------------------------------------------------------
 * Data path: should add this for readability
 * -------------------------------------------------------------------------------------------------------------------------------
 */
// module datapath(
//		
//		  .clk(clk),
//		  .reset()
//  );
//
//
//endmodule  