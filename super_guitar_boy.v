module super_guitar_boy(
								input CLOCK_50,
								input [9:0]SW,
								input [3:0] KEY,
								input [35:0]GPIO_0,
								
								output [6:0]HEX0,
								output [6:0]HEX1,
								output [6:0]HEX2,
								output [6:0]HEX3,
								output [6:0]HEX4,
								output [6:0]HEX5,
								
								output [9:0]LEDR,
								
								output VGA_CLK,
								output VGA_HS,
								output VGA_VS,
								output VGA_BLANK_N,
								output VGA_SYNC_N,
								output [7:0] VGA_R,
								output [7:0] VGA_G,
								output [7:0] VGA_B
								);
								
	//assigning GPIO from guitar to internal wires
	wire [4:0] buttons;
	assign buttons = GPIO_0[5:1];
	
	wire strum;
	assign strum = GPIO_0[0];
	
	//assigning pause and stop buttons
	wire stop;
	assign stop = SW[0];
	
	wire pause;
	assign pause = SW[1];
	
	wire reset;
	assign reset = ~KEY[0];
	
	//internal wires
	
	wire note_hit;
	wire note_miss;
	
	wire [20:0]score;
	wire [24:0]score_bcd;
	wire [4:0] notes_to_play;
	
	play_song smoke_on_the_water(.clk(CLOCK_50),
										  .pause(pause),
										  .stop(stop),

										  .AUD_ADCDAT(AUD_ADCDAT),

										  .AUD_BCLK(AUD_BCLK),
										  .AUD_ADCLRCK(AUD_ADCLRCK),
										  .AUD_DACLRCK(AUD_DACLRCK),

										  .FPGA_I2C_SDAT(FPGA_I2C_SDAT),

										  .AUD_XCK(AUD_XCK),
										  .AUD_DACDAT(AUD_DACDAT),

										  .FPGA_I2C_SCLK(FPGA_I2C_SCLK)
										  );
										  
	gameplay play_game(
							 .clk(CLOCK_50),
							 .pause(pause),
							 .stop(stop),
							 .buttons(buttons),
							 .strum(strum),
							 .notes_to_play(notes_to_play),
							
							 .LEDR(LEDR[4:0]),
							 .note_hit(note_hit),
							 .note_miss(note_miss)
							 );
	
	drop_notes display(
							.clk(CLOCK_50),							//On Board 50 MHz
							.reset(0),							// On Board Keys
							.switches(SW[9:5]),
							
							.pause(pause),
							.stop(~KEY[3]),
//							.correct_notes(),					// Input to determine if the row should be blacked out or set to white
							
							.notes_to_play(notes_to_play),				// Notes to comparator
							
							.VGA_CLK(VGA_CLK),   						//	VGA Clock
							.VGA_HS(VGA_HS),							//	VGA H_SYNC
							.VGA_VS(VGA_VS),							//	VGA V_SYNC
							.VGA_BLANK_N(VGA_BLANK_N),						//	VGA BLANK
							.VGA_SYNC_N(VGA_SYNC_N),						//	VGA SYNC
							.VGA_R(VGA_R),   						//	VGA Red[9:0]
							.VGA_G(VGA_G),	 						//	VGA Green[9:0]
							.VGA_B(VGA_B)
							);
							 
	scoring player_score(
								.clk(CLOCK_50),
							   .reset_n(stop),
							   .note_hit(note_hit),
							   .note_miss(note_miss),
								
								.LEDR(LEDR[9:6]),
							   .score(score)
								);
			  
	bcd_converter bcd_score(
									.reset_n(),
									.score_bin(score),
									
									.score_bcd(score_bcd)
									);
										  
	HEX_Display hex0(
						  .num(score_bcd[3:0]),
						  .hex_display(HEX0)
						  );
						  
	HEX_Display hex1(
						  .num(score_bcd[7:4]),
						  .hex_display(HEX1)
						  );
						  
	HEX_Display hex2(
						  .num(score_bcd[11:8]),
						  .hex_display(HEX2)
						  );
						  
	HEX_Display hex3(
						  .num(score_bcd[15:12]),
						  .hex_display(HEX3)
						  );
						  
	HEX_Display hex4(
						  .num(score_bcd[19:16]),
						  .hex_display(HEX4)
						  );
						  
	HEX_Display hex5(
						  .num(score_bcd[23:20]),
						  .hex_display(HEX5)
						  );
	
endmodule
