module test(LEDR, CLOCK_50);
	input CLOCK_50;
	output [9:0]LEDR;
	
	wire eight_beat;
	
	chorus chr(.clk(CLOCK_50),
				  .eight_beat(eight_beat),
				  .exp_notes(LEDR[4:0])
				  );
	
	eight_beat_gen rate_driver(.clk(CLOCK_50),
						.eight_beat(eight_beat)
						);
						
endmodule

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

module eight_beat_gen(input clk, output reg eight_beat);
	
	parameter EIGHTH_NOTE = 24'd13500000;
	
	reg [23:0] t = 24'd0;
	
	always@(posedge clk)
	begin
		if (t == EIGHTH_NOTE)
		begin
			t <= 24'd0;
			eight_beat <= 1'b1;
		end
		
		else
		begin
			t <= t+1;
			eight_beat <= 1'b0;
		end
			
	end

endmodule
