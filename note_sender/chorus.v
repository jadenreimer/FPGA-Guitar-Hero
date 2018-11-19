module chorus(
				  input clk,
						  eight_beat,
						  load,
						  
				  output reg [4:0]exp_notes
				  );
							 
	reg [4:0] t = 5'd0;
	
	always@(posedge clk)
	begin
		if (load)
			if (eight_beat == 1'b1)
				t <= t+1;
			else if (t == 5'd31)
				t <= 5'd0;
		else if (~load)
			t <= 5'd0;
	end
	
	always@(posedge clk)
	begin
	
		case(t)
			5'd0:
				exp_notes <= 5'b00101;
			5'd2:
				exp_notes <= 5'b01010;
			5'd4:
				exp_notes <= 5'b10100;
			5'd7:
				exp_notes <= 5'b00101;
			5'd9:
				exp_notes <= 5'b01010;
			5'd11:
				exp_notes <= 5'b11000;
			5'd12:
				exp_notes <= 5'b10100;
			5'd16:
				exp_notes <= 5'b00101;
			5'd18:
				exp_notes <= 5'b01010;
			5'd20:
				exp_notes <= 5'b10100;
			5'd23:
				exp_notes <= 5'b01010;
			5'd25:
				exp_notes <= 5'b00101;
				
			default: exp_notes <= 5'b00000;
			
		endcase
	end
endmodule

