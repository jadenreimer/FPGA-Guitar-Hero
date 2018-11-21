module prechorus(
				  input clk,
						  eight_beat,
						  load,
						  
				  output reg [4:0]exp_notes
				  );
							 
	reg [5:0] t = 6'd0;
	
	always@(posedge clk)
	begin
		if (load)
			if (eight_beat == 1'b1)
				t <= t+1;
			else if (t == 6'd47)
				t <= 6'd0;
		else if (~load)
			t <= 5'd0;
			
	end
	
	always@(posedge clk)
	begin
	
		case(t)
			6'd0:
				exp_notes <= 5'b10101;
			6'd8:
				exp_notes <= 5'b01110;
			6'd12:
				exp_notes <= 5'b01110;
				
			6'd16:
				exp_notes <= 5'b00001;
			6'd18:
				exp_notes <= 5'b00100;
			6'd19:
				exp_notes <= 5'b00001;
			6'd20:
				exp_notes <= 5'b00100;
			6'd21:
				exp_notes <= 5'b00010;
			6'd22:
				exp_notes <= 5'b00001;
			6'd23:
				exp_notes <= 5'b00010;
				
			6'd25:
				exp_notes <= 5'b00001;
			6'd26:
				exp_notes <= 5'b00100;
			6'd27:
				exp_notes <= 5'b00001;
			6'd28:
				exp_notes <= 5'b00100;
			6'd29:
				exp_notes <= 5'b00010;
			6'd30:
				exp_notes <= 5'b00001;
				
			6'd32:
				exp_notes <= 5'b10101;
			6'd40:
				exp_notes <= 5'b01110;
			6'd44:
				exp_notes <= 5'b01110;
				
			default: exp_notes <= 5'b00000;
			
		endcase
	end
endmodule

