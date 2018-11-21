module verse(
				  input clk,
						  eight_beat,
						  load,
						  
				  output reg [4:0]exp_notes
				  );
							 
	reg [6:0] t = 7'd0;
	
	always@(posedge clk)
	begin
		if (load)
			if (eight_beat == 1'b1)
				t <= t+1;
			else if (t == 7'd127)
			t <= 7'd0;
		else if (~load)
			t <= 5'd0;
	end
	
	always@(posedge clk)
	begin
	
		case(t)
		
		//first four bars of the verse
		//let 5'b00111 be the A5 chord
		//let 5'b01011 be the G5 chord
		
			7'd0:
				exp_notes <= 5'b00111;
			7'd2:
				exp_notes <= 5'b00111;
			7'd4:
				exp_notes <= 5'b00111;
			7'd6:
				exp_notes <= 5'b00111;
			7'd8:
				exp_notes <= 5'b00111;
			7'd10:
				exp_notes <= 5'b00111;
			7'd12:
				exp_notes <= 5'b00111;
			7'd14:
				exp_notes <= 5'b00111;
			7'd16:
				exp_notes <= 5'b00111;
			7'd19:
				exp_notes <= 5'b01011;
			7'd23:
				exp_notes <= 5'b00111;
			7'd26:
				exp_notes <= 5'b00111;
			7'd28:
				exp_notes <= 5'b00111;
			7'd30:
				exp_notes <= 5'b00111;
				
			//second four bars
			7'd32:
				exp_notes <= 5'b00111;
			7'd34:
				exp_notes <= 5'b00111;
			7'd36:
				exp_notes <= 5'b00111;
			7'd38:
				exp_notes <= 5'b00111;
			7'd40:
				exp_notes <= 5'b00111;
			7'd42:
				exp_notes <= 5'b00111;
			7'd44:
				exp_notes <= 5'b00111;
			7'd46:
				exp_notes <= 5'b00111;
			7'd48:
				exp_notes <= 5'b00111;
			7'd50:
				exp_notes <= 5'b00111;
			7'd52:
				exp_notes <= 5'b01011;
			7'd54:
				exp_notes <= 5'b01011;
			7'd56:
				exp_notes <= 5'b00111;
			7'd57:
				exp_notes <= 5'b00111;
			7'd59:
				exp_notes <= 5'b10101;
				
			//third four bars
			7'd64:
				exp_notes <= 5'b00111;
			7'd66:
				exp_notes <= 5'b00111;
			7'd68:
				exp_notes <= 5'b00111;
			7'd70:
				exp_notes <= 5'b00111;
			7'd72:
				exp_notes <= 5'b00111;
			7'd74:
				exp_notes <= 5'b00111;
			7'd76:
				exp_notes <= 5'b00111;
			7'd78:
				exp_notes <= 5'b00111;
			7'd80:
				exp_notes <= 5'b00111;
			7'd84:
				exp_notes <= 5'b01011;
			7'd87:
				exp_notes <= 5'b00111;
			7'd90:
				exp_notes <= 5'b00111;
			7'd92:
				exp_notes <= 5'b00111;
			7'd94:
				exp_notes <= 5'b00111;
				
			//fourth four bars
			7'd96:
				exp_notes <= 5'b00111;
			7'd98:
				exp_notes <= 5'b00111;
			7'd100:
				exp_notes <= 5'b00111;
			7'd102:
				exp_notes <= 5'b00111;
			7'd104:
				exp_notes <= 5'b00111;
			7'd106:
				exp_notes <= 5'b00111;
			7'd108:
				exp_notes <= 5'b00111;
			7'd110:
				exp_notes <= 5'b00111;
			7'd112:
				exp_notes <= 5'b00111;
			7'd116:
				exp_notes <= 5'b01011;
			7'd119:
				exp_notes <= 5'b00111;
			7'd122:
				exp_notes <= 5'b00111;
			7'd124:
				exp_notes <= 5'b00111;
			7'd126:
				exp_notes <= 5'b00111;
				
			default: exp_notes <= 5'b00000;
			
		endcase
	end
endmodule

