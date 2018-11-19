module vga_animation (
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
	
	wire resetn;
	assign resetn = KEY[0];
	
	// Create the colour, x, y and writeEn wires that are inputs to the controller.

	wire [2:0] colour;
	wire [7:0] x;
	wire [6:0] y;
	wire [7:0] x_raw; // connects to VGA
	wire [6:0] y_raw;
	wire clk_4fps;
	wire writeEn;
	wire plot, clear;
	wire plotterDone;

	assign writeEn = 1; // writeEn is constant on
	// Instantiate the delay counter
	counter_4fps myDelay (
		.Clock (CLOCK_50),
		.resetn (resetn),
		.clock_4fps (clk_4fps)
	);

	// Instantiate the FSM
	control myControl (
		.clk (CLOCK_50),
		.clk_4fps (clk_4fps),
		.clear (clear),
		.plot (plot),
		.clearDone (plotterDone)
	);

	// Instantiate the xy counter

	xy_counter my_xy_counter (
		.clk_4fps (clk_4fps),
		.resetn (resetn),
		.x (x),
		.y (y)
	);

	// Instantiate the plotter
	plotter myPlotter (
		.clk (CLOCK_50),
		.resetn (resetn),
		.plot (plot),
		.clear (clear),
		.xin (x),
		.yin (y),
		.cin (SW[2:0]),
		.x (x_raw),
		.y (y_raw),
		.colour (colour),
		.plotterDone (plotterDone)
	);




	// Create an Instance of a VGA controller - there can be only one!
	// Define the number of colours as well as the initial background
	// image file (.MIF) for the controller.
	vga_adapter VGA(
			.resetn(resetn),
			.clock(CLOCK_50),
			.colour(colour),
			.x(x_raw),
			.y(y_raw),
			.plot(writeEn),
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
module plotter (
	input clk, resetn, plot, clear,
	input [7:0] xin,
	input [6:0] yin,
	input [2:0] cin,
	output reg [7:0] x,
	output reg [6:0] y,
	output reg [2:0] colour,
	output reg plotterDone
	//output reg writeEn
);

	reg [14:0] counter;
	//reg [7:0] XR;
	//reg [6:0] YR;
	//reg [2:0] colourR;

	
	always @(posedge clk) begin
		if (clear) begin
			x <= counter [14:7];
			y <= counter [6:0];
			if (counter == 15'd32767) begin 
				counter <= 0;
				plotterDone <= 1;
			end else begin 
				counter <= counter + 1;
				plotterDone <= 0;
			end
			//plotterDone <= (counter == 15'd32767) ? 1 : 0;
			//writeEn <= 1; // override writeEn
			colour <= 3'b000; // overwrites colour to black

		end else if (plot) begin
			//writeEn <= plot; // forward writeEn
			plotterDone <= 0; // plotterDone is reserved for clear
			x <= xin + counter[3:2];
			y <= yin + counter[1:0];
			if (counter == 15'd15) begin 
				counter <= 0;
			end else begin 
				counter <= counter + 1;	
			end
			//plotterDone <= (counter == 15'd15) ? 1 : 0;
			colour <= cin;
		end

		// reset registers
		if (~resetn) begin
			// XR <= 0;
			// YR <= 0;
			//colourR <= 0;
			x <= 0;
			y <= 0;
			colour <= 0;
			counter <= 0;
			//writeEn <= 0;
			plotterDone <= 0;
		end
		// if (~plot & ~clear) counter <= 0; // reset counter when plot and clear is not enabled
		// else counter <= counter + 1; // otherwise count up
		
	end 
endmodule // plotter

module xy_counter (
	input resetn, clk_4fps,
	output reg [7:0] x,
	output reg [6:0] y
);
	reg x_dir;
	reg y_dir;

	always @ (posedge clk_4fps, negedge resetn) begin
		if (~resetn) begin
		x_dir <= 0; // left
		y_dir <= 1; // Down
		x <= 8'd154;
		y <= 1;
		end
		else begin 
			if ((x == 8'd155) | (x == 8'd0) | (y == 7'd115) | (y == 7'd0)) begin 
				if (x == 8'd155) begin 
					x_dir <= ~x_dir;
					x <= x - 1;
				end 
				if (x == 8'd0) begin
					x_dir <= ~x_dir;
					x <= x + 1;
				end
				if (y == 7'd115) begin 
					y_dir <= ~y_dir;
					y <= y - 1;
				end 
				if (y == 7'd0) begin
					y_dir <= ~y_dir;
					y <= y + 1;
				end
			end
			else begin
				if (x_dir) x <= x + 1;
				else x <= x - 1;
				if (y_dir) y <= y + 1;
				else y <= y - 1;
			end
		end
	end
endmodule
module counter_4fps (
    input Clock, resetn, 
    output reg clock_4fps
);

	reg [23:0] counter;
    always @ (posedge Clock) 
        begin	
            if (~resetn) counter <= 0;
            else if (counter == 24'd12499999) begin 
				clock_4fps <= 1;
				counter <= 0;
			end
            else begin 
				counter <= counter + 1;
				clock_4fps <= 0;
			end
        end
endmodule

module control (
	input clk, clk_4fps, clearDone,
	output reg clear, plot
);

	reg current_state, next_state;
	
	localparam	S_CLEAR = 0,
				S_PLOT = 1;
	
	// state table
	always @ (*)
	begin: state_table
		case (current_state)
			S_CLEAR: next_state = clearDone ? S_PLOT : S_CLEAR; 
			S_PLOT: next_state = S_PLOT; // stay in plot until next 4fps clock edge
			default: next_state = S_CLEAR;
		endcase
	end // state table
	
	always @(posedge clk)
	begin
		if (clk_4fps) current_state = S_CLEAR; // start cycle at rising edge of 15hz clock
		else current_state = next_state;
	end // next_state
	
	always @(*)
	begin: enable_signals
		clear = 0;
		plot = 0;
		case (current_state)
			S_CLEAR: begin
				clear = 1;
			end
			S_PLOT: begin
				plot = 1;
			end
		endcase
			
	end // enable signals
	
	
endmodule // control