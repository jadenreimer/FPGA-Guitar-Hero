module gameplay(
					 input CLOCK_50,
					 input [9:0] SW,
					 input [35:0] GPIO_0,
					 input strummer,
					 
					 output reg note_hit
					 );
	
	wire [4:0] exp_notes;
	wire [4:0] buttons;
	reg [4:0] key_in;
	
	//FSM for loading in buttons with immediate clear
	//---------------------------------------------------|
	parameter WAIT_FOR_STRUM = 3'b001;
	parameter LOAD = 3'b010;
	parameter CLEAR = 3'b100;
	
	reg [2:0] current_state;
	reg [2:0] next_state;
	
	always @(posedge CLOCK_50)
	begin
		case(current_state)
		WAIT_FOR_STRUM:
			if (strummer) next_state <= LOAD;
			
		LOAD:
			next_state <= CLEAR;
		
		CLEAR:
			if (~strummer) next_state <= WAIT_FOR_STRUM;
			
		default: next_state <= CLEAR;
		endcase
	end
	
	always @(posedge CLOCK_50)
	begin
		case(current_state)
		WAIT_FOR_STRUM: key_in <= 5'b00000;
			
		LOAD: key_in <= buttons;
		
		CLEAR: key_in <= 5'b00000;

		endcase
		
		current_state <= next_state;
	end
	//---------------------------------------------------|
	
	//Note Sender to run through our list of expected notes
	note_sender note_sender(.CLOCK_50(CLOCK_50),
									.pause(SW[0]),
									.exp_notes(exp_notes));
	//GPIO input to buttons						
	GPIO_input buttons_in(.CLOCK_50(CLOCK_50),
								 .GPIO_0(GPIO_0),
								 .buttons(buttons));
							 
	//FSM tester to see if the user hits a note
	//---------------------------------------------------|
	parameter NO_NOTES = 3'b001;
	parameter NOTES_IN = 3'b010;
	parameter CHECK = 3'b100;
	
	reg [2:0] current_state2;
	reg [2:0] next_state2;
	
	reg note_hit_hold = 1'b0;
	
	always @(posedge CLOCK_50)
	begin
		case(current_state2)
		NO_NOTES:
			if (exp_notes != 5'b00000) next_state2 <= NOTES_IN;
			
		NOTES_IN:
			if (exp_notes == 5'b00000) next_state2 <= CHECK;
		
		CHECK:
			next_state2 <= NO_NOTES;
			
		default: next_state2 <= NOTES_IN;
		endcase
	end
	
	always @(posedge CLOCK_50)
	begin
		case(current_state2)
		NOTES_IN:
			if (key_in != 5'b00000)
				if (key_in == exp_notes) note_hit_hold <= 1'b1;
				else note_hit_hold <= 1'b0;
			
		CHECK:
		begin
			note_hit <= note_hit_hold;
			note_hit_hold <= 1'b0;
		end
		
		endcase
		
		current_state2 <= next_state2;
	end
	//---------------------------------------------------|
	
endmodule
