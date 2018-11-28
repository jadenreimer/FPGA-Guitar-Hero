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
	reg [8:0] colour_calc; // Interim colour
	
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

				colour_calc <= 9'd0; // Output black; how do we get this to potentially reprint the background? Is it as easy as getting this xy-coordinate of the background .mif memory?
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

				colour_calc <= 9'b111111111; // This will need to become an inserted value from a .mif once we get that going
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
			colour_calc <= 9'd0;
			counter <= 0;

			plotterDone <= 0;
			
		end // reset if
		
		
		
		
		// Colour select
		if(colour_calc != 9'b000000000)
		begin
			case (x_in)
				3'd1: colour_to_VGA = 9'b000111000; // green
				3'd2: colour_to_VGA = 9'b111000000; // red
				3'd3: colour_to_VGA = 9'b111111000; // yellow
				3'd4: colour_to_VGA = 9'b000000111; // blue
				3'd5: colour_to_VGA = 9'b011111000; // orange
				default: colour_to_VGA = 9'b111111111; // white
			endcase
		end
		else colour_to_VGA = 9'b000000000; // black
		
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
	