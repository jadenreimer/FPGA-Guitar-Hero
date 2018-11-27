module datapath (
	input clk,
	input reset,
	
	input [4:0] i_notes, // 
	
	// Selects
	input i_xctrl_sel, // 
	input i_yctrl_sel, // 
	
	input i_x_sel, // 
	input i_y_sel, // 
	
	input i_colour, // 
	
	// Enables
	input i_colour_en, //
		
	// Values traversing through the register
	input i_xctrl_en, // 
	input i_yctrl_en, // 
	// Values being changed by counting up; to be printed to the VGA
	input i_x_en, // 
	input i_y_en, // 
	// Values to count up to
	input i_xeq_en, // 
	input i_yeq_en, // 
	
	input i_reg_en, // 

	
	output reg [8:0] o_x_VGA, // 
	output reg [7:0] o_y_VGA, // 
	
	output reg o_xctrl_equal, // 
	output reg o_yctrl_equal, // 
	
	output reg o_x_equal, // 
	output reg o_y_equal, // 
	
	output reg [8:0] o_colour_VGA, // 
	output o_beat, // 
	
	output [4:0] o_notes_to_play, // 
	output o_current_note, // 
	
	output reg o_plotted_one // 
	
);

wire x_to_plot;// = x_location*52 + 52;
wire y_to_plot;// = y_location*28 + 8;


// Colour register
reg [8:0] colour_VGA;

always @(posedge clk)
begin
	if(reset) colour_VGA <= 9'd0;
	
	else if(i_colour_en)
	begin
		colour_VGA <= i_colour ? 9'b111111111 : 9'd0;
	end
	
	o_colour_VGA <= colour_VGA;

	
end // colour
	
	
// X control: count through the register
reg [2:0] x_ctrl;

always @(posedge clk)
begin
	if(reset) x_ctrl <= 3'd0;
	
	else if(i_xctrl_en)
		x_ctrl <= i_xctrl_sel ? (x_ctrl + 1) : 0;
		
	o_xctrl_equal <= (x_ctrl == 3'd4) ? 1 : 0;

end // x_ctrl



// Y control: count through the register
reg [2:0] y_ctrl;

always @(posedge clk)
begin
	if(reset) y_ctrl <= 3'd0;
	
	else if(i_yctrl_en)
		y_ctrl <= i_yctrl_sel ? (y_ctrl + 1) : 0;
		
	o_yctrl_equal = (y_ctrl == 3'd7) ? 1 : 0;

end // x_ctrl







/*
 * -------------------------------------------------------------------------------------------------------------------------------
 * start plotter
 * -------------------------------------------------------------------------------------------------------------------------------
 */
notes_register notes(
	.clk(clk),
	.reset(reset),
	
	.shiftEnable(i_reg_en), // Controls if the FSM is telling it to drop down
	.x_level(x_ctrl),
	.y_level(y_ctrl),
	.notes(i_notes), // Input for the notes being loaded from the "top"
	
	.notes_to_play(o_notes_to_play), // Loose end right now, disconnected
	.note_out(o_current_note) // The value of the data being read (I expect this needs to be a reg but I'm not certain)
);





reg [8:0] Xeq;
reg [7:0] Yeq;

always @(posedge clk)
begin
// Enable signal here?
if(o_current_note) // Only plot if the note is a 1
begin

	// X register: printing

		if(reset) begin
			o_x_VGA <= 9'd0;
			o_y_VGA <= 8'd0;
			Xeq <= 9'd0;
			Yeq <= 8'd0;
		end
		
		// CHECK: if we want a register to have a third condition of keeping its value, is it find to just use the enable for that?
		else if(i_x_en)
		begin
			o_x_VGA <= i_x_sel ? (o_x_VGA + 1) : (x_ctrl*52 + 52);
		end

	// Y register: printing
		
		if(i_y_en)
		begin
			o_y_VGA <= i_y_sel ? (o_y_VGA + 1) : (y_ctrl*28 + 8);
		end

	// Xeq register: value to compare against for plotting
		
		if(i_xeq_en)
		begin
			Xeq <= (x_ctrl*52 + 52 + 3);
		end


	// Yeq register: value to compare against for plotting
		
		if(i_yeq_en)
		begin
			Yeq <= (y_ctrl*28 + 8 + 3);
		end

end // if statement for note

// Is this the right location for these guys?

if(o_x_VGA == Xeq)
	o_x_equal <= 1;
else
	o_x_equal <= 0;

if(o_y_VGA == Yeq)
	o_y_equal <= 1;
else
	o_y_equal <= 0;

// Might want to change how these are controlled (declared above)
//assign o_xctrl_equal = (x_ctrl == 3'd4) ? 1 : 0;
//assign o_yctrl_equal = (y_ctrl == 3'd7) ? 1 : 0;

o_plotted_one <= o_y_equal;

end // plotter

/*
 * -------------------------------------------------------------------------------------------------------------------------------
 * end plotter
 * -------------------------------------------------------------------------------------------------------------------------------
 */



// Rate driver: new 'clock signal' for eight notes
rate_driver eighth_note(
	.clk(clk),
	.beat(o_beat)
);



endmodule
//				x_to_VGA <= x_in + counter[3:2];
//				y_to_VGA <= y_in + counter[1:0];
//				
//				counter <= (counter == 4'd15) ? 4'd0 : (counter + 1);
//				
//				plotterDone <= (counter == 4'd15) ? 1 : 0;


// Notes register: hold the values being shifted in memory
module notes_register (
		
	input clk,
	input reset,
	
	input shiftEnable, // Controls if the FSM is telling it to drop down
	input [2:0] x_level, // x-location in memory to reach when reading
	input [2:0] y_level, // y-location in memory to reach when reading
	input [4:0] notes, // Input for the notes being loaded from the "top"
	
	output [4:0] notes_to_play,
	output reg note_out // The value of the data being read

);
	
	// Naming convention of shift registers: <colour><row>
	wire [7:0] g1_out, r2_out, y3_out, b4_out, o5_out;
	//				Arguments:	clk		reset		data_in			shiftEnable			note_to_play		register_out
	shift_register green1(	clk,		reset,	notes[0],		shiftEnable,		notes_to_play[0],	g1_out);
	
	shift_register red2(		clk,		reset,	notes[1],		shiftEnable,		notes_to_play[1],	r2_out);
	
	shift_register yellow3(	clk,		reset,	notes[2],		shiftEnable,		notes_to_play[2],	y3_out);
	
	shift_register blue4(	clk,		reset,	notes[3],		shiftEnable,		notes_to_play[3],	b4_out);
	
	shift_register orange5(	clk,		reset,	notes[4],		shiftEnable,		notes_to_play[4],	o5_out);
	
	always @(*)
        case (x_level)
            3'd0: note_out = g1_out[y_level];
            3'd1: note_out = r2_out[y_level];
				3'd2: note_out = y3_out[y_level];
				3'd3: note_out = b4_out[y_level];
				3'd4: note_out = o5_out[y_level];
            default: note_out = 3'dx;
        endcase
		  
endmodule


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


// Shif Register: mini-components of 
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