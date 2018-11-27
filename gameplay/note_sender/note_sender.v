module note_sender(input clk, input pause, input stop, output reg [4:0] exp_notes);
	//*******************************************
	//*              Rate driver                *
	//*******************************************
	
	//drives eighth notes
	
	localparam EIGHTH_NOTE = 25'd13157895;
	
	reg [24:0] CLOCK_COUNT = 25'd0;
	reg EIGHT_PULSE = 1'b0;
	
	always@(posedge clk)
	begin
		if (~pause)
			if (CLOCK_COUNT == EIGHTH_NOTE)
			begin
				CLOCK_COUNT <= 25'd0;
				EIGHT_PULSE <= 1'b1;
			end
		
			else
			begin
				CLOCK_COUNT <= CLOCK_COUNT+1;
				EIGHT_PULSE <= 1'b0;
			end
			
	end

	
	reg [4:0] t = 5'd0;
	
	always@(posedge clk)
	begin
		if (~stop)
		begin
			if (~pause)
				if (EIGHT_PULSE == 1'b1)
					t <= t+1;
				else if (t == 5'd31)
					t <= 5'd0;
			else if (pause)
				t <= t;
		end
		
		else if (stop) t <= 9'd0;
	end
	
	always@(posedge clk)
	begin
	
		case(t)
		
			9'd0:
				exp_notes <= 5'b00101;
			9'd2:
				exp_notes <= 5'b01010;
			9'd4:
				exp_notes <= 5'b10100;
			9'd7:
				exp_notes <= 5'b00101;
				
			9'd9:
				exp_notes <= 5'b01010;
			9'd11:
				exp_notes <= 5'b11000;
			9'd12:
				exp_notes <= 5'b10100;
				
			9'd16:
				exp_notes <= 5'b00101;
			9'd18:
				exp_notes <= 5'b01010;
			9'd20:
				exp_notes <= 5'b10100;
			9'd23:
				exp_notes <= 5'b01010;
				
			9'd25:
				exp_notes <= 5'b00101;
				
			default: exp_notes <= 5'b00000;
		endcase
	end
	
endmodule
