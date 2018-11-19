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
	KEY//,								// On Board Keys
	// The ports below are for the VGA output.  Do not change.
//	VGA_CLK,   						//	VGA Clock
//	VGA_HS,							//	VGA H_SYNC
//	VGA_VS,							//	VGA V_SYNC
//	VGA_BLANK_N,						//	VGA BLANK
//	VGA_SYNC_N,						//	VGA SYNC
//	VGA_R,   						//	VGA Red[9:0]
//	VGA_G,	 						//	VGA Green[9:0]
//	VGA_B   						//	VGA Blue[9:0]
);
	
	input	CLOCK_50;				//	50 MHz
	input	[3:0]	KEY;
	input	[9:0]	SW;
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
	
	
/*
 * -------------------------------------------------------------------------------------------------------------------------------
 * Wire creation
 * -------------------------------------------------------------------------------------------------------------------------------
 */
	
	// Misc wires
	wire beat;
	
	// Wires for the FSM
	wire shift;
//	wire writeEnable;
	wire FSM_clear;
	wire FSM_plot;

	// Wires for the plotter and x/y calculator
	wire enablePlotter;
	
	// Wires for the VGA adapter
	wire [8:0] x_to_VGA;
	wire [7:0] y_to_VGA;
	wire [2:0] colour_to_VGA;
	
	// Wires for the counters
	wire printed_register; // Reading from register completed
	wire row_counter_out;
	wire plotterDone;
	wire [2:0] current_column_count;
	wire [4:0] current_row_counter;
	
	// Wires for the register
	wire [4:0] register_data;
	wire incremented_register; // Writing to register completed
	
	wire [8:0] x_to_plotter;
	wire [7:0] y_to_plotter;
	
	
	
/*
 * -------------------------------------------------------------------------------------------------------------------------------
 * Module instantiation
 * -------------------------------------------------------------------------------------------------------------------------------
 */
		
	
	
	// FSM:
	control myControl (
		.reset(reset),
		.clk (CLOCK_50),
		.beat(beat),
		.start(~KEY[3]),
		.incremented_register(incremented_register), // Written through the register; make sure this is the correct signal
		.printed_register(printed_register), // Read through the register; make sure this is the correct signal
		
//		.FSM_writeEn(writeEnable),
		.FSM_clear(FSM_clear),
		.FSM_plot(FSM_plot),
		.FSM_shift(shift)
		
		// Other inputs go here:
		
	);
	
	
	find_x_and_y calculator(
	
		.clk(CLOCK_50),
	
		.from_register(register_data), // 5-bit data input from the register
		.x_location(current_column_counter), // counter from the printer, takes in "current_row_count"
		.y_location(current_row_counter), // address of the current data, takes in 

		.enablePlotter(enablePlotter),
		.x_to_plotter(x_to_plotter), // goes to plotter
		.y_to_plotter(y_to_plotter)
	);
	
	
	notes_register notes(
		
		.address_in(current_row_counter), // Might cause problems
		
		.clk(CLOCK_50),
		.reset(reset),
		.shift(shift), // Controls if the FSM is telling it to drop down
		
		.FSM_notes(SW[4:0]), // Input for the notes being loaded from the "top"
		
		.register_notes_out(register_data), // The value of the data being read (I expect this needs to be a reg but I'm not certain)
		.incremented_register(incremented_register) // High = whole register has been written to
		
	);
	
	
	printed_row_counter rows(
		
		.clk(CLOCK_50),
		.reset(reset),
		.plotted_row(plotterDone),
		
		.count_up_row(row_counter_out),
		.current_count(current_column_count)
		
	);
	
	
	address_counter big_count(
		.clk(CLOCK_50),
		.reset(reset),
		.count_up_row(row_counter_out),
		
		.printed_register(printed_register), // High = whole register has been read from
		.current_count(current_row_counter)
		
	);
	
	
	rate_driver eighth_note(
		
		.clk(CLOCK_50),
		.beat(beat)
		
	);
	
	
	plotter myPlotter (
		.clk (CLOCK_50),
		.reset (reset),
		.enablePlotter(enablePlotter),
		.plot_note (FSM_plot),
		.clear_note (FSM_clear),
		.x_in (x_to_plotter), // 9-bit
		.y_in (y_to_plotter), // 8-bit
		.x_to_VGA (x_to_VGA), // 9-bit
		.y_to_VGA (y_to_VGA), // 8-bit
		.colour_to_VGA (colour_to_VGA), // 3-bit
		.plotterDone (plotterDone)
	);


	// VGA ADAPTER
	// Create an Instance of a VGA controller - there can be only one!
	// Define the number of colours as well as the initial background
	// image file (.MIF) for the controller.
//	vga_adapter VGA(
//			.resetn(resetn),
//			.clock(CLOCK_50),
//			.colour(colour_to_VGA),
//			.x(x_to_VGA),
//			.y(y_to_VGA),
//			.plot(beat),
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
//		defparam VGA.BITS_PER_COLOUR_CHANNEL = 1;
//		defparam VGA.BACKGROUND_IMAGE = "head_background.mif";
	
endmodule



/*
 * -------------------------------------------------------------------------------------------------------------------------------
 * Moduel definitions:
 * notes_register, plotter, address_counter, printer_row, printed_note, rate_driver, control path, datapath [maybe]
 * -------------------------------------------------------------------------------------------------------------------------------
 */

 
/*
 * -------------------------------------------------------------------------------------------------------------------------------
 * Contains the values for all the notes on the screen and drops them down.
 * -------------------------------------------------------------------------------------------------------------------------------
 */


 
module notes_register (
	
	input [4:0]  address_in, // Specifies the location in memory being reached when reading
	
	input clk,
	input reset,
	input shift, // Controls if the FSM is telling it to drop down
	
	input [4:0] FSM_notes, // Input for the notes being loaded from the "top"
	
	output reg [4:0] register_notes_out, // The value of the data being read (I expect this needs to be a reg but I'm not certain)
	output reg incremented_register // Tells the FSM that it's done dropping down
);
	
	reg [4:0] counter;
	reg [4:0] data_in;
	reg [4:0] read_address;
	reg [4:0] write_address;
	reg writeEnable;
	
	wire [4:0] register_output;
		
	note_register notes( // Module instantiation of the memory
	
	.clock(clk),
	.data(data_in),
	.rdaddress(read_address),
	.wraddress(write_address),
	.wren(writeEnable),
	
	.q(register_output)
		
	);
	
	// Do we want to control the writeEnable inside this module?
		
	always @(posedge clk) begin
		
//		top <= 30 - counter;
//		bottom <= 31 - counter;
		
		register_notes_out <= register_output;
		
		if(reset) begin
			counter <= 5'd0;
			register_notes_out <= 0;
			incremented_register <= 0;
		end

		if (shift) // Cycle through the register and drop the values, insert user input at the start
		begin
			
			if(counter == 31)
			begin
				incremented_register	<= 1;
				counter			<= 0;
				writeEnable		<= 0;
			end
			
			else begin
			
				incremented_register <= 0;
			
				if(counter < 30)
					begin
						
						writeEnable <= 1; // We can group the writeEnables
						read_address <= (30 - counter);
						write_address <= (31 - counter);
						data_in <= register_output;
						counter <= counter + 1;
						
					end
				else if(counter == 30)
					begin
						
						writeEnable <= 1;
						write_address <= 5'd0;
						data_in <= FSM_notes;
						counter <= counter + 1;
						// writeEnable
						
					end
				
			end // increment
			
		end // shift

		else begin
			read_address <= address_in;
			writeEnable <= 0;
		end
		
	end // posedge clk
	
endmodule
 

/*
 * -------------------------------------------------------------------------------------------------------------------------------
 * Calculates the x and y location of the block to print from the register input
 * -------------------------------------------------------------------------------------------------------------------------------
 */
module find_x_and_y(
	
	input clk,
	
	input [4:0] from_register, // 5-bit data from the register
	input [2:0] x_location, // counter from the printer, takes in "current_column_count"
	input [4:0] y_location, // address of the current data, takes in "current_row_count"
	
	output reg enablePlotter,
	output reg [8:0] x_to_plotter, // goes to plotter
	output reg [7:0] y_to_plotter // goes to plotter
	
);
	
	always @ (posedge clk)
	begin

		enablePlotter	<= 0;
		x_to_plotter	<= 0;
		y_to_plotter	<= 0;

		if(from_register[x_location]) // Make sure where we are in the 5 bits is not empty
			begin
				enablePlotter	<= 1;
				x_to_plotter	<= x_location*52 + 52;
				y_to_plotter	<= y_location*17 + 8;
			end
	end
endmodule
 
/*
 * -------------------------------------------------------------------------------------------------------------------------------
 * Draws or erases a square at the location that is fed in. plotterDone goes high when complete.
 * -------------------------------------------------------------------------------------------------------------------------------
 */
module plotter (
	input clk, reset, plot_note, clear_note,
	input enablePlotter,
	input [8:0] x_in,
	input [7:0] y_in,
	output reg [8:0] x_to_VGA,
	output reg [7:0] y_to_VGA,
	output reg [2:0] colour_to_VGA, // Will be constant to begin with
	output reg plotterDone // Very important to the functionality of the counter nesting
);

	reg [3:0] counter;
	
	always @(posedge clk) begin
		
		// Erasing half of the module
		
		if (clear_note && enablePlotter) begin // Is this the right AND?
			plotterDone <= 0;
			x_to_VGA <= x_in + counter[3:2];
			y_to_VGA <= y_in + counter[1:0];
			
			counter <= (counter == 4'd15) ? 4'd0 : (counter + 1);
			plotterDone <= (counter == 4'd15) ? 1 : 0;

			colour_to_VGA <= 3'b000; // Output black; how do we get this to potentially reprint the background? Is it as easy as getting this xy-coordinate of the background .mif memory?
		end // clear half
		
		// Plotting half of the module
		
		else if (plot_note && enablePlotter) begin // The right AND for the job?
			plotterDone <= 0;
			x_to_VGA <= x_in + counter[3:2]; // This implementation will need to change as we insert .mifs into the mix
			y_to_VGA <= y_in + counter[1:0];
			
			counter <= (counter == 4'd15) ? 4'd0 : (counter + 1); // Reset counter if full, increment if not
			plotterDone <= (counter == 4'd15) ? 1 : 0; // Signal completion if counter is all done

			colour_to_VGA <= 3'b010; // This will need to become an inserted value from a .mif once we get that going
		end // plot half

		// reset registers
		if (reset)
		begin
		
			x_to_VGA <= 0;
			y_to_VGA <= 0;
			colour_to_VGA <= 0;
			counter <= 0;

			plotterDone <= 0;
		end // reset if
	end  // always block
endmodule // plotter



/*
 * -------------------------------------------------------------------------------------------------------------------------------
 * address counter: output high when all rows of the register have been printed
 * -------------------------------------------------------------------------------------------------------------------------------
 */
 
module address_counter (
	input clk,
	input reset,
	input count_up_row, // Increments this counter (the outpute from the printed_row subcounter when it's finished)
	
	output reg printed_register, // Tells the FSM to change state from drawing or deleting from the register data
	output reg [4:0] current_count
);
//	reg [4:0] counter = 0;
//	current_counter = 0;

	always @(posedge clk)
	begin
		if(count_up_row) current_count <= current_count + count_up_row;
//		current_count <= counter;
		printed_register <= 0; // Is this bad practice in general?
		
		if(reset)
			current_count		<= 0;
		else if(current_count == 5'd31)
//		begin
			printed_register <= 1;
//		end
		
	end // counter
	
endmodule



/*
 * -------------------------------------------------------------------------------------------------------------------------------
 * printed_rows counter: output goes high for every word in the register printed
 * -------------------------------------------------------------------------------------------------------------------------------
 */
module printed_row_counter (
	input clk,
	input reset,
	input plotted_row, // Increments this counter (the output from plotter when it's finished)
	
//	input FSM_clear,
//	input FSM_plot,
	
	output reg count_up_row, // Increments address_counter
	output reg [2:0] current_count
);
	
	always @(posedge clk)
	begin
		
		count_up_row <= 0;
		
		if(reset)
			current_count		<= 0;
		else if(current_count == 3'd4)
		begin
			count_up_row <= 1;
			current_count <= 0;
		end
		else if(count_up_row) current_count <= current_count + 1;		
		
	end // counter
	
//	
//	always @(posedge clk)
//	begin
//		
//		count_up_row <= 0;
//		
//		if(reset)
//		begin
//			count_up_row	<= 0;
//			current_count	<= 0;
//		end else if(current_count == 3'd4)
//		begin
//			count_up_row	<= 1;
//			current_count	<= 0;
//		end else current_count <= current_count + plotted_row;
		
//		if(FSM_clear) clear_node <= 1;
//		if(FSM_plot_node) plot_node <= 1;
		
//	end // counter
	
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
	
	parameter EIGHTH_NOTE = 25'd26315790;
	
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
	input incremented_register, // Check if register has been 100% written to [input from "shift", register module]
	input printed_register, // Check if register has been 100% read [input from "printed_register", address_counter module
	
//	output reg FSM_writeEn, // Control the writing to the register
	output reg FSM_clear, // Controls if we are clearing from the register
	output reg FSM_plot, // Controls if we are drawing from the register
	output reg FSM_shift // Controls if we are still taking in from the register
);

	reg [2:0] current_state, next_state;
	
	localparam			MAIN			= 0,
					DEC_REG			= 1,
//					LOAD_TO_REG		= X,
					DRAW			= 2,
//					CYCLE_DRAW		= x,
					WAIT			= 3,
					ERASE			= 4;
//					CYCLE_ERASE		= x,
	
	// state table
	always @ (*)
	begin: state_table
		case (current_state)
		
			MAIN: next_state = start ? DEC_REG : MAIN;
//			LOAD_TO_REG: next_state = printed_register ? DRAW : LOAD_TO_REG;
			DEC_REG: next_state = incremented_register ? DRAW : DEC_REG;
			DRAW: next_state = printed_register ? WAIT : DRAW;
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
		FSM_plot		<= 0;
		FSM_shift		<= 0;
		
		case (current_state)
		
//			MAIN:
			
			DEC_REG:
			begin
//				FSM_writeEn	<= 1;
				FSM_shift	<= 1;
			end
				
			DRAW:
			begin
				FSM_plot		<= 1;
			end
				
//			WAIT:
				
			ERASE:
			begin
				FSM_clear	<= 1;
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