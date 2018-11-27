module scoring(
					input clk,
					input reset_n,
					input note_hit,
					input note_miss,
					
					output [3:0]LEDR,
					output reg [19:0]score
					);
					
	reg [3:0]multiplier = 4'd1;
	
	always @(clk)
	begin
		if (~reset_n)
		begin
			if (multiplier == 4'd10)
				multiplier <= multiplier;
				
			else if (note_miss)
				multiplier <= 4'd1;
				
			else if (note_hit)
				multiplier <= multiplier+4'd1;
		end
		
		else multiplier <= 4'd1;
		
	end
	
	always @(clk)
	begin
		if (~reset_n)
		begin
			if (score == 20'd999999)
				score <= score;
				
			else if (note_hit)
				score <= score + {16'd0, multiplier};
		end
		
		else score <= 20'd0;
		
	end
	
	assign LEDR = multiplier;
endmodule
