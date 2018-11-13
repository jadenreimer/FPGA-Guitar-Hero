`timescale 1ns / 1ns

//module rate_driver(clk, enable_in, enable_out);
//	
//	input clk;
//	input enable_in; // Telling it to be on or off
//	output reg enable_out; // Output to counter once value reached
//	
//	reg [25:0] rateDriver;
//	
//	always @(posedge clk) // triggered every time clk rises
//	begin
//		//no 'assign' in always blocks
//		enable_out <= (rateDriver == 26'd0) ? 1 : 0; //yo make sure you change the apostrophe
//
//		if (enable_in == 1) // when q is the maximum value for the counter
//			rateDriver <= 26'b00101111101011110000100000; // q reset to the upper value of counting (4 Hz)
//		else
//			rateDriver <= rateDriver - 1;
//	end
//	
//endmodule



module rate_driver(input clk, output reg new_clk); // Not sure if this works

	reg [15:0] count;
	
	always @(posedge clk)
		{new_clk, count} <= count + 16'h8000;
	
endmodule



module drop-keys
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
//	wire erase;
	wire [4:0] pos_in;
	wire load_in;
//	wire [2:0] rate_drive;
	
	assign resetn = KEY[2];
//	assign erase = KEY[3];
	assign pos_in = SW[4:0];
	assign load_in = KEY[0];
//	assign rate_drive = SW[9:7];
	
	// Create the colour, x, y and writeEn wires that are inputs to the controller.

	wire [2:0] vga_colour;
	wire [7:0] vga_x;
	wire [6:0] vga_y;
	wire plot_out; // = wrtieEn
	
	rate_driver(.clk(CLOCK_50), .new_clk(plot_out) ); // plot_out might need to be a reg

	
	
	FSM ctrl(
	
		// Standard I/O
		.clk(CLOCK_50),
		.resetn(resetn),
//		.erase(erase),
		
		.pos_in(pos_in),
		.load_in(load_in),
		.rate_drive(plot_out),
		.writeEn(),
		.drawEn(),
		
		// Outputs, my lad
		.x_reg(x_out),
		.y_reg(y_out),
		.colour_reg(colour_out),
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
		input resetn,
//		input erase,
		
		//Input to registers
		input [4:0] pos_in,
		input load_in,
		input rate_driver,
		input writeEn,
		input drawEn,
		
		//Outputs, my lad
		output [7:0] x_reg,
		output [6:0] y_reg,
		output [2:0] colour_reg,
);
		
		
		
		wire [3:0] add_from_data;
		wire [2:0] x, y, colour;
		
		wire [3:0] add;
		
		// output reg plot, enable, x_init, y_colour_init
		rate_driver mvEN(.clk(CLOCK_50),
							  .enable_in(1'b1),
							  .enable_out(moveEN)
							  );
		
	 	control C0(
		
		// Edit this
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
	 input [3:0] add_from_data,
	 input load_in
	 input rate_driver,
	 
	 output reg [3:0] add_from_control,
	 output reg eraseEN, drawEN, loadEn, incEn, clearRegs;
	 
);

    reg [2:0] current_state, next_state;
	 reg adder;
	 
	localparam  LOAD_IN 		= 3'd0,
               DRAW 			= 3'd1,
               WAIT 			= 3'd2,
               ERASE_NOTE 	= 3'd3,
					INC 			= 3'd4,
					ERASE 		= 3'd5;
					
	// Next state logic aka our state table
   always@(*)
   begin: state_table 
		adder = 1'd0;
	
		case (current_state)
		
			LOAD_IN: next_state = load_in ? DRAW : LOAD_IN;
			
			DRAW:
			
			begin
				if (add_from_data == 4'd15) begin
					next_state = WAIT;
				end else begin
					adder = 1'b1; // Off-by-one error?
					next_state = DRAW;
				end	
			end
			
			WAIT: next_state = rate_driver ? ERASE : WAIT;
			
			ERASE_NOTE:
			
			begin
				if (add_from_data == 4'd15) begin
					next_state = INC;
				end else begin
					adder = 1'b1; // Off-by-one error?
					next_state = ERASE_NOTE;
				end	
			end
			
			INC: next_state = DRAW; // How do we avoid propagation delays here?
			
			ERASE:
			
			begin
				if (add_from_data == 4'd15) begin
					next_state = ERASE;
				end else begin
					adder = 1'b1; // Off-by-one error?
					next_state = LOAD;
				end	
			end
				 
			default: next_state = LOAD;
						
        endcase
    end // state_table
   

	// Output logic aka all of our datapath control signals
	always @(*)
	begin: enable_signals
	
	loadEn = 1'b1;
	drawEn = 1'b0;
	eraseEn = 1'b0;
	incEn = 1'b0;
	clearRegs = 1'b0;

		case (current_state)
			
            LOAD_IN: begin
					loadEn = 1'b1;
				end
				
				DRAW: begin
					drawEn = 1'b1;
				end
				
				ERASE_NOTE: begin
					eraseEn = 1'b1;
				end
				
				INC: begin
					incEn = 1'b1;
				end
				
				ERASE: begin
					clearRegs = 1'b1;
				end
 
			endcase
    end 
   
    always@(posedge clk)
    begin: state_FFs
		if ( (current_state == DRAW) || (current_state == ERASE_NOTE) || (current_state == ERASE) ) add_from_control <= add_from_control + adder;
		else if (add_from_control == 4'd15)	add_from_control <= 4'd0;
		
		current_state <= next_state;
	 end

endmodule



module datapath(

    input clk,
	 input [3:0] add,
	 input drawEN, eraseEN, incEN,
	 input [4:0] pos_in,
	 input [2:0] colour_in,
	 input [7:0] x_curr,
	 input [6:0] y_curr,
	 
	 output reg [7:0] x_out,
	 output reg [6:0] y_out,
	 output reg [2:0] colour_out,
	 output reg plot_out
	 
    );
    
    // input registers
	 reg [9:0] green_register;
	 reg [9:0] red_register;
	 reg [9:0] yellow_register;
	 reg [9:0] blue_register;
	 reg [9:0] orange_register;
	 reg [7:0] x_pos;
//loadEn
//drawEn
//eraseEn
//incEn
//clearRegs
	 
	 always @(posedge loadEn)
	 begin
		case (pos_in)
			
			5'b10000:
			begin
				green_register <= {3'b010, 7'd0};
				x_pos[7:0] = ;
			end
			5'b01000:
			begin
				red_register <= {3'b100, 7'd0};
				x_pos[7:0] = ;
			end
			5'b00100:
			begin
				yellow_register <= {3'b110, 7'd0}; // actually red + green
				x_pos[7:0] = ;
			end
			5'b00010:
			begin
				blue_register <= {3'b001, 7'd0};
				x_pos[7:0] = ;
			end
			5'b00001:
			begin
				orange_register <= {3'b101, 7'd0}; // actually purple
				x_pos[7:0] = ;
			end
			
		endcase
	 end
	 
	 
	 
    always@(posedge drawEn) begin
		if (incEN)
			begin
					if(green_register[9:7] == 3'b010)
						green_register[6:0] <= green_register[6:0] + 1;
				
					if(red_register[9:7] == 3'b100)
						red_register[6:0] <= red_register[6:0] + 1;	
					
					if(yellow_register[9:7] == 3'b110)
						yellow_register[6:0] <= yellow_register[6:0] + 1;
				
					if(blue_register[9:7] == 3'b001)
						blue_register[6:0] <= blue_register[6:0] + 1;
						
					if(orange_register[9:7] == 3'b101)
						orange_register[6:0] <= orange_register[6:0] + 1;
			end
				
				if(drawEN) begin
				
					
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
 
	always @(posedge rate_driver) plot_out <= 1'b1;
	
	
	
	
	
	 
    // Registers a, b, c, x with respective input logic
    always@(posedge clk) begin
        if(~resetn) begin
            x_register <= 8'b0;
            y_register <= 7'b0;
            colour_register <= 3'b0;
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
 
    // Output result register
    always@(posedge clk) begin
	 
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
				// Same principal here except we're drawing normally
					x_out <= x_register + (add % 4); // X location
					y_out <= y_register + (add / 4); // Y location
					colour_out <= colour_register;
					plot_out <= 1'd1;
				end else plot_out <= 1'd0;
			end
		end
				
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
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