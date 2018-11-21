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
