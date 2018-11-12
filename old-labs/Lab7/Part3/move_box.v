`timescale 1ns / 1ns

module rate_driver(clk, enable_in, enable_out);
	
	input clk;
	input enable_in; // Telling it to be on or off
	output reg enable_out; // Output to counter once value reached
	
	reg [25:0] rateDriver;
	
	always @(posedge clk) // triggered every time clk rises
	begin
		//no 'assign' in always blocks
		enable_out <= (rateDriver == 26'd0) ? 1 : 0; //yo make sure you change the apostrophe

		if (enable_in == 1) // when q is the maximum value for the counter
			rateDriver <= 26'b00101111101011110000100000; // q reset to the upper value of counting (4 Hz)
		else
			rateDriver <= rateDriver - 1;
	end
	
endmodule



module move_box
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
		VGA_B	   						//	VGA Blue[9:0]
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
	
	wire resetn;
	
	assign resetn = KEY[0];
	
	// Create the colour, x, y and writeEn wires that are inputs to the controller.

	wire [2:0] colour_out;
	wire [7:0] x_out;
	wire [6:0] y_out;
	wire plot_out; // = wrtieEn
	wire dir_x, dir_y;
	
	// Put your code here. Your code should produce signals x,y,colour and writeEn
	// for the VGA controller, in addition to any other functionality your design may require.
	
	FSM ctrl(
	
		// Standard I/O
		.clk(CLOCK_50),
		
		.colour_in(SW[9:7]),
		.pos_in(7'd0),
		
		// Outputs, my lad
		.x_reg(x_out),
		.y_reg(y_out),
		.colour_reg(colour_out),
		.plot(plot_out)
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
			
		defparam VGA.RESOLUTION = "160x120";
		defparam VGA.MONOCHROME = "FALSE";
		defparam VGA.BITS_PER_COLOUR_CHANNEL = 1;
		defparam VGA.BACKGROUND_IMAGE = "black.mif";
	
endmodule



module FSM(
		
		// Standard I/O
		input clk,
		
		//Input to registers
		input [2:0] colour_in,
		input [6:0] pos_in,
		
		//Outputs, my lad
		output [7:0] x_reg,
		output [6:0] y_reg,
		output [2:0] colour_reg,
		output plot
);
		
		
		wire eraseEN, incEN, drawEN, moveEN;

		wire [2:0] x, y, colour;
		
		wire [3:0] add;
		
		// output reg plot, enable, x_init, y_colour_init
		rate_driver mvEN(.clk(CLOCK_50),
							  .enable_in(1'b1),
							  .enable_out(moveEN)
							  );
		
	 	control C0(
		
		  .clk(clk),
		  .move_enable(moveEN),
		  .add_in(add),
		  
		  .add(add),
		  .eraseEN(eraseEN),
		  .incEN(incEN),
		  .drawEN(drawEN)
		  
		);
	 
		datapath D0(
		
		  .clk(CLOCK_50),
		  .add(add),
		  .move_enable(moveEN),
		  
		  .drawEN(drawEN),
		  .eraseEN(eraseEN),
		  .incEN(incEN),
		  
		  .pos_in(7'b0),
		  .colour_in(colour_in),
		  .x_curr(x_reg),
		  .y_curr(y_reg),
		  
		  .x_out(x_reg),
		  .y_out(y_reg),
		  .colour_out(colour_reg),
		  .plot_out(plot)
		  
		); 

endmodule



module control(
    input clk,
	 input move_enable,
	 input [3:0] add_in,
	 
	 output reg [3:0] add,
	 output reg eraseEN, incEN, drawEN
	 
);

    reg [2:0] current_state, next_state;
	 reg adder;
	 
	localparam  INIT = 3'd0,
               DRAW = 3'd1,
               WAIT = 3'd2,
               ERASE = 3'd3,
					INC = 3'd4;
					
	// Next state logic aka our state table
   always@(*)
   begin: state_table 
		adder = 1'd0;
	
		case (current_state)
			INIT: next_state = move_enable ? DRAW : INIT;
			
			DRAW:
			
			begin
				if (add_in == 4'd15) begin
					next_state = WAIT;
				end else begin
					adder = 1'b1;
					next_state = DRAW;
				end	
			end
			
			WAIT: next_state = move_enable ? ERASE : WAIT;
			
			ERASE:
			
			begin
				if (add_in == 4'd15) begin
					next_state = INC;
				end else begin
					adder = 1'b1;
					next_state = ERASE;
				end	
			end
			
			INC: next_state = DRAW;
				 
			default: next_state = WAIT;
			
        endcase
    end // state_table
   

    // Output logic aka all of our datapath control signals
    always @(*)
    begin: enable_signals
		eraseEN=1'b0;
		incEN=1'b0;
		drawEN=1'b0;
		
        case (current_state)
			
            DRAW: begin
                drawEN = 1'b1;
                end
            ERASE: begin
                eraseEN = 1'b1;
                end
            INC: begin
					 incEN = 1'b1;
                end
 
			endcase
    end 
   
    always@(posedge clk)
    begin: state_FFs
		if ((current_state == DRAW) || (current_state == ERASE)) add <= add + adder;
		else if (add == 4'd15) 		 add <= 4'd0;
		
		current_state <= next_state;
	 end

endmodule



module datapath(

    input clk, move_enable,
	 input [3:0] add,
	 input drawEN, eraseEN, incEN,
	 input [6:0] pos_in,
	 input [2:0] colour_in,
	 input [7:0] x_curr,
	 input [6:0] y_curr,
	 
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
	 
	 reg x_add;
	 reg y_add;
	 
	 always @(posedge move_enable)
	 begin
		if (x_curr==8'd156)
			x_add<=0;
		if (y_curr==7'd116)
			y_add<=0;
		if (x_curr==8'd0)
			x_add<=1;
		if (y_curr==7'd0)
			y_add<=1;
	 end
	 

    // Registers a, b, c, x with respective input logic
    always@(posedge move_enable) begin
		if (incEN)
			begin
					if(x_add)
						x_register<=x_register+1;
				
					if(~x_add)
						x_register<=x_register-1;	
					
					if(y_add)
						y_register<=y_register+1;
				
					if(~y_add)
						y_register<=y_register-1;
			end
				
				if(drawEN) begin
				
					x_out <= x_curr + (add % 4);
					y_out <= y_register + (add / 4);
					colour_out <= colour_register;
					//plot_out <= 1'd1;
					
				end
				
				//else plot_out <= 1'd0;
				
				if(eraseEN) begin
				
					x_out <= x_curr + (add % 4);
					y_out <= y_register + (add / 4);
					colour_out <= 3'b0;
					//plot_out <= 1'd1;
					
				end
				
				//else plot_out <= 1'd0;
				
   end
 
	always @(posedge clk) plot_out <= 1'b1;
	
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