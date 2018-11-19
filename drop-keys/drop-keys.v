`timescale 1ns / 1ns

module drop_keys
	(
		CLOCK_50,						//	On Board 50 MHz
		// Your inputs and outputs here
		SW,
		KEY,							// On Board Keys
		// The ports below are for the VGA output.  Do not change.
		VGA_CLK,   						//	VGA Clock
		VGA_HS,							//	VGA H_SYNC
		VGA_VS,							//	VGA V_SYNC
		VGA_BLANK_N,						//	VGA BLANK
		VGA_SYNC_N,						//	VGA SYNC
		VGA_R,   						//	VGA Red[9:0]
		VGA_G,	 						//	VGA Green[9:0]
		VGA_B,   						//	VGA Blue[9:0]
		HEX0,
		HEX1,
		HEX2,
		HEX3,
		HEX4,
		HEX5
	);

	input	CLOCK_50;				//	50 MHz
	input [3:0]	KEY;
	input [9:0] SW;
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
	
	output [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5;
	
	hex_decoder xSig(x_out[7:4], HEX5);
	hex_decoder xMin(x_out[3:0], HEX4);
	
	hex_decoder ySig({1'b0, y_out[6:4]}, HEX3);
	hex_decoder yMin(y_out[3:0], HEX2);
	
	hex_decoder cSig(4'd0, HEX1);
	hex_decoder cMin({5'd0, colour_out[2:0]}, HEX0);
	
	wire resetn, black, plot_in, go;
	
	wire [3:0] add_up;
	
	assign resetn = KEY[0];
	assign black = ~KEY[2];
	assign plot_in = ~KEY[1];
	assign go = ~KEY[3];
	
	// Create the colour, x, y and writeEn wires that are inputs to the controller.

	wire [2:0] colour_out;
	wire [7:0] x_out;
	wire [6:0] y_out;
	wire plot_out; // = wrtieEn

			
	// Put your code here. Your code should produce signals x,y,colour and writeEn
	// for the VGA controller, in addition to any other functionality your design may require.
	
	FSM ctrl(
	
		// Standard I/O
		.clk(CLOCK_50),
		.resetn(resetn),
		
		// State change functionality
		.plot_in(plot_in), // Can I just make this the ~KEY[1] input?
		.black(black),
		.go(go),

		// Input to registers
		.colour_in(SW[9:7]),
		.pos_in(SW[6:0]),
		
		// Outputs, my lad
		.x_reg(x_out),
		.y_reg(y_out),
		.colour_reg(colour_out),
		.plot(plot_out),
		.add_up(add_up)
	);
	
	
	// Create an Instance of a VGA controller - there can be only one!
	// Define the number of colours as well as the initial background
	// image file (.MIF) for the controller.
	vga_adapter VGA(
	
			.resetn(resetn),
			.clock(CLOCK_50),
			.colour(colour_out),
			.x(x_out),
			.y(y_out),
			.plot(plot_out),
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
		defparam VGA.BACKGROUND_IMAGE = "black.mif";
	
endmodule



module FSM(
		
		// Standard I/O
		input clk,
		input resetn,
		input plot_in,
		input black,
		input go,
		
		//Input to registers
		input [2:0] colour_in,
		input [6:0] pos_in,
		
		//Outputs, my lad
		output [7:0] x_reg,
		output [6:0] y_reg,
		output [2:0] colour_reg,
		output plot,
		output reg [3:0] add_up
);
		
		
		wire x_init, y_init, colour_init, drawEnable;

		wire [2:0] x, y, colour;
		
		wire [3:0] add;
	
		always@(*) add_up = add;
		
		// output reg plot, enable, x_init, y_colour_init
		control C0(
		
		  .clk(clk),
		  .resetn(resetn),
		  .go(go),
		  .plot_in(plot_in), // what are each of these 'writeEn's doing?
		  .x_init(x_init),
		  .y_init(y_init),
		  .colour_init(colour_init),
		  .drawEnable(drawEnable),
		  .add(add)
		  
		);
				
		datapath D0(
		
		  .clk(clk),
		  .resetn(resetn),
		  .black(black),
		  .add(add),
		  .enable(writeEn),
		  
		  .x_init(x_init), // add stuff here
		  .y_init(y_init),
		  .colour_init(colour_init),
		  .drawEnable(drawEnable),
		  
		  .pos_in(pos_in),
		  .colour_in(colour_in),
		  
		  .x_out(x_reg),
		  .y_out(y_reg),
		  .colour_out(colour_reg),
		  .plot_out(plot)
		  
		); 
					 
endmodule        
		  


module control(
    input clk,
    input resetn,
    input go,
	 input plot_in,
	 
	 output reg x_init,
	 output reg y_init,
	 output reg colour_init,
	 output reg drawEnable,
	 output reg [3:0] add
	 
);

    reg [2:0] current_state, next_state;
	 reg adder;
	 
	localparam  S_LOAD_X				= 3'd0,
               S_LOAD_x_WAIT		= 3'd1,
               S_LOAD_Y				= 3'd2,
               S_LOAD_Y_WAIT		= 3'd3,
					S_DRAW				= 3'd4,
               S_DRAW_WAIT			= 3'd5;
					
	// Next state logic aka our state table
   always@(*)
   begin: state_table 
		adder = 1'd0;
	
		case (current_state)
			S_LOAD_X: next_state = go ? S_LOAD_x_WAIT : S_LOAD_X;
			
			S_LOAD_x_WAIT: next_state = ~go ? S_LOAD_Y : S_LOAD_x_WAIT;
			
			S_LOAD_Y: next_state = go ? S_LOAD_Y_WAIT : S_LOAD_Y;
			
			S_LOAD_Y_WAIT: next_state = plot_in ? S_DRAW : S_LOAD_Y_WAIT;
			
			S_DRAW: next_state = ~plot_in ? S_DRAW_WAIT : S_DRAW;
			
			S_DRAW_WAIT:
			
						 begin
								if (add == 4'd15) begin
									next_state = S_LOAD_X;
								end else begin
									adder = 1'b1;
									next_state = S_DRAW_WAIT;
								end
						 end
				
            default:     next_state = S_LOAD_X;
        endcase
    end // state_table
   

    // Output logic aka all of our datapath control signals
    always @(*)
    begin: enable_signals
        // By default make all our signals 0 to avoid latches.
        // This is a different style from using a default statement.
        // It makes the code easier to read.  If you add other out
        // signals be sure to assign a default value for them here.
			
		  x_init = 1'b0;
		  y_init = 1'b0;
		  colour_init = 1'b0;
		  drawEnable = 1'b0;

        case (current_state)
			
            S_LOAD_X: begin
                x_init = 1'b1;
                end
            S_LOAD_Y: begin
                y_init = 1'b1;
                end
            S_DRAW: begin
					 colour_init = 1'b1;
                end
				S_DRAW_WAIT: begin
					 drawEnable = 1'b1;
					 end
 
			endcase
    end // enable_signals
   
    // current_state registers
    always@(posedge clk)
    begin: state_FFs
        if(~resetn)
		  begin
            current_state <= S_LOAD_X; // Should this be next_state? Does it matter at all?
				add <= 4'd0;
        end else begin
			if (current_state == S_DRAW_WAIT) add <= add + adder; // Sound logic I think?
			else if (add == 4'd15) 		 add <= 4'd0;
			current_state <= next_state;
		end
	end // state_FFS
endmodule



module datapath(

    input clk, resetn, black, 
	 input [3:0] add,
	 input enable,
	 input x_init, y_init, colour_init, drawEnable,
	 input [6:0] pos_in,
	 input [2:0] colour_in,
	 
	 output reg [7:0] x_out,
	 output reg [6:0] y_out,
	 output reg [2:0] colour_out,
	 output reg plot_out
	 
    );
    
    // input registers
	 reg [7:0] x_register;
	 reg [6:0] y_register;
	 reg [2:0] colour_register;
	 reg [14:0] black_out_the_sky;
	 	
    // Registers a, b, c, x with respective input logic
    always@(posedge clk) begin
        if(~resetn) begin
            x_register <= 8'b0;
            y_register <= 7'b0;
            colour_register <= 3'b0;
				y_drop <= 0;
        end
        else 
		  begin
            if(x_init)
                x_register <= {1'b0, pos_in}; // Load x
            else if(y_init)
                y_register <= pos_in; // Load y
            else if(colour_init)
                colour_register <= colour_in; // Load colour
        end
    end
 
	reg [6:0] drop_y = 7'd0;
	
	reg eight_beat;
 
	eight_beat_gen rate(clk, eight_beat);
	
	draw_sprite draw(x_register, add, (y_register + y_drop), drawEnable, colour_register, x_out, y_out[6:0], colour_out);
	draw_sprite erase(x_register, add, (y_register + y_drop), eight_beat, 3'd0, x_out, y_out[6:0], 3'd0);
	
    // Output result register
    always@(posedge clk) begin
	 
        if(~resetn) begin
				black_out_the_sky <= 15'd0;
        end
		  
		  if(black || (black_out_the_sky != 15'd0) )
		  begin
			  if(black_out_the_sky == 19199)	black_out_the_sky <= 15'd0; // If the screen has gone through every pixel ie. 120*160-1
				else black_out_the_sky <= black_out_the_sky + 1; // Increment if we haven't blackened every pixel
				colour_out <= 3'd0; // Set pixels to black
				x_out <= black_out_the_sky / 120; // Number of whole rows denotes the x location
				y_out <= black_out_the_sky % 120; // Remainder of the rows denotes the y location
				plot_out <= 1'd1; // Call to plot every time we change a pixel
			end else begin
				
				if(drawEnable) begin
					y_drop <= y_drop + 1;
				end
			end
		end
				
    
endmodule



module eight_beat_gen(input clk, output reg eight_beat);
	
	parameter EIGHTH_NOTE = 25'd26315790;
	
	reg [24:0] t = 25'd0;
	
	always@(posedge clk)
	begin
		if (t == EIGHTH_NOTE)
		begin
			t <= 25'd0;
			eight_beat <= 1'b1;
		end
		
		else
		begin
			t <= t+1;
			eight_beat <= 1'b0;
		end
			
	end

endmodule



module draw_sprite(input [7:0] x_register, input [3:0] add, input [6:0] y_register, input enable, input [2:0] colour_register, output reg [7:0] x_out, output reg y_out[6:0], output reg [2:0] colour_out);
		
		if(enable) begin
		
		x_out <= x_register + (add % 4); // X location
			y_out <= y_register + (add / 4); // Y location
			colour_out <= colour_register;
			if(add == 4'b1111) plot_out <= 1'd1; // Risky
		end else plot_out <= 1'd0;
		
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