module chorus(
				  input clk,
						  eight_beat,
						  
				  output reg [4:0]exp_notes
				  );
							 
	reg [4:0] t = 5'd0;
	
	always@(posedge clk)
	begin
		if (eight_beat == 1'b1)
			t <= t+1;
		else
			t <= t;
		endcase
	end
	
	always@(posedge clk)
	begin
	
		case(t)
			5'd1:
				exp_notes <= 5'b00101;
			5'd3:
				exp_notes <= 5'b01010;
			5'd5:
				exp_notes <= 5'b10100;
			5'd8:
				exp_notes <= 5'b00101;
			5'd10:
				exp_notes <= 5'b01010;
			5'd12:
				exp_notes <= 5'b11000;
			5'd13:
				exp_notes <= 5'b10100;
			5'd17:
				exp_notes <= 5'b00101;
			5'd19:
				exp_notes <= 5'b01010;
			5'd21:
				exp_notes <= 5'b10100;
			5'd24:
				exp_notes <= 5'b01010;
			5'd26:
				exp_notes <= 5'b00101;
				
			default: exp_notes <= 5'b00000;
			
		endcase
	end
endmodule

