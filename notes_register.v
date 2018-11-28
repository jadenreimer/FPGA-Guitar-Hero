
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
