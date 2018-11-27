module gameplay(
					 input clk,
					 input pause,
					 input stop,
					 input [4:0]buttons,
					 input strum,
					 input [4:0] notes_to_play,
					 
					 output [4:0]LEDR,
					 output reg note_hit,
					 output reg note_miss
					 );
	
	reg [4:0] key_in;
	
	//FSM for loading in buttons with immediate clear
	//---------------------------------------------------|
	localparam WAIT_FOR_STRUM = 3'd0;
	localparam LOAD = 3'd1;
	localparam CLEAR = 3'd2;
	
	reg [2:0] current_state;
	reg [2:0] next_state;
	reg [8:0] count_cycles;
	
	always @(posedge clk)
	begin
		case(current_state)
		WAIT_FOR_STRUM:
			if (strum) next_state <= LOAD;
			
		LOAD:
			if (count_cycles == 9'd500) next_state <= CLEAR;
		
		CLEAR:
			if (~strum) next_state <= WAIT_FOR_STRUM;
			
		default: next_state <= CLEAR;
		endcase
	end
	
	always @(posedge clk)
	begin
		case(current_state)
		WAIT_FOR_STRUM: key_in <= 5'd0;
			
		LOAD:
		begin
			key_in <= buttons;
			count_cycles <= count_cycles+1;
		end
		
		CLEAR:
		begin
			key_in <= 5'd0;
			count_cycles<=9'd0;
		end
		
		default: key_in <= 5'd0;

		endcase
		
		current_state <= next_state;
	end
	//---------------------------------------------------|
							 
	//FSM tester to see if the user hits a note
	//---------------------------------------------------|
	localparam NO_NOTES = 3'd0;
	localparam NOTES_IN = 3'd1;
	localparam READ = 3'd2;
	localparam CHECK = 3'd3;
	
	reg [2:0] current_state2;
	reg [2:0] next_state2;
	
	always @(posedge clk)
	begin
		case(current_state2)
		NO_NOTES:
			if (notes_to_play != 5'd0) next_state2 <= NOTES_IN;
			
		NOTES_IN:
			if (key_in != 5'd0) next_state2 <= READ;
			else if (notes_to_play == 5'd0) next_state2 <= READ;
		
		READ:
			next_state2 <= CHECK;
			
		CHECK:
			if (notes_to_play == 5'd0) next_state2 <= NO_NOTES;
			
		default: next_state2 <= NO_NOTES;
		
		endcase
	end
	
	always @(posedge clk)
	begin
		case(current_state2)
		READ:
		begin
			if (notes_to_play != 5'd0)
				begin
				
				if (key_in == notes_to_play)
				
				begin
					note_hit <= 1'b1;
					note_miss <= 1'b0;
				end
				
				else if (key_in != notes_to_play)
				
				begin
					note_miss <= 1'b1;
					note_hit <= 1'b0;
				end
				
			end
			
			else if (notes_to_play == 5'd0)
			
			begin
					note_miss <= 1'b1;
					note_hit <= 1'b0;
			end
			
		end
		
		CHECK:
		begin
			note_miss <= 1'b0;
			note_hit <= 1'b0;
		end
		
		default: note_hit <= 1'b0;
		endcase
		
		current_state2 <= next_state2;
	end
	//---------------------------------------------------|
	
	assign LEDR = notes_to_play;
	
endmodule
