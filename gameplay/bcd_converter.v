module bcd_converter(
						input reset_n,
						input [19:0] score_bin,
						
						output reg [23:0] score_bcd
						);
	integer i;
	
	always@(*)
	begin
		if (~reset_n)
		begin
			score_bcd = 24'd0;
			
			for (i=19; i>=0; i=i-1)
			begin
				if (score_bcd[23:20] >= 5)
					score_bcd[23:20] = score_bcd[23:20]+3;
					
				if (score_bcd[19:16] >= 5)
					score_bcd[19:16] = score_bcd[19:16]+3;
					
				if (score_bcd[15:12] >= 5)
					score_bcd[15:12] = score_bcd[15:12]+3;
					
				if (score_bcd[11:8] >= 5)
					score_bcd[11:8] = score_bcd[11:8]+3;
					
				if (score_bcd[7:4] >= 5)
					score_bcd[7:4] = score_bcd[7:4]+3;
					
				if (score_bcd[3:0] >= 5)
					score_bcd[3:0] = score_bcd[3:0]+3;
					
				score_bcd[23:20] = score_bcd[23:20] << 1;
				score_bcd[20] = score_bcd[19];
				
				score_bcd[19:16] = score_bcd[19:16] << 1;
				score_bcd[16] = score_bcd[15];
				
				score_bcd[15:12] = score_bcd[15:12] << 1;
				score_bcd[12] = score_bcd[11];
				
				score_bcd[11:8] = score_bcd[11:8] << 1;
				score_bcd[8] = score_bcd[7];
				
				score_bcd[7:4] = score_bcd[7:4] << 1;
				score_bcd[4] = score_bcd[3];
				
				score_bcd[3:0] = score_bcd[3:0] << 1;
				score_bcd[0] = score_bin[i];
				
			end
		
		end
		
		else score_bcd <= 24'd0;
		
	end
	
endmodule
