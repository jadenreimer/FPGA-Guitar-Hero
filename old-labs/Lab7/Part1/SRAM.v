module SRAM(KEY, SW, HEX0, HEX2, HEX4, HEX5);
	
	input [9:0] SW;
	input [3:0] KEY;
	output [6:0] HEX0, HEX2, HEX4, HEX5;
	
	wire [3:0] RAM_out;
	
	hexDecoder h0(RAM_out[3:0], HEX0[6:0]);
	hexDecoder h2(SW[3:0], HEX2[6:0]);
	hexDecoder h4(SW[7:4], HEX4[6:0]);
	hexDecoder h5(SW[7:4], HEX5[6:0]);
	
	ram32x4 SRAM(SW[8:4], KEY[0], SW[3:0], SW[9], RAM_out); // address, clock, data, wren, q
	
endmodule

module hexDecoder(In, Out);

	input [3:0] In;
	output [6:0] Out;
	
	assign Out[0] = (~In[3] & ~In[2] & ~In[1] & In[0]) | (~In[3] & In[2] & ~In[1] & ~In[0]) | (In[3] & ~In[2] & In[1] & In[0]) | (In[3] & In[2] & ~In[1] & In[0]);
	assign Out[1] = (~In[3] & In[2] & ~In[1] & In[0]) | (~In[3] & In[2] & In[1] & ~In[0]) | (In[3] & ~In[2] & In[1] & In[0]) | (In[3] & In[2] & ~In[1] & ~In[0]) | (In[3] & In[2] & In[1] & ~In[0]) | (In[3] & In[2] & In[1] & In[0]);
	assign Out[2] = (~In[3] & ~In[2] & In[1] & ~In[0]) | (In[3] & In[2] & ~In[1] & ~In[0]) | (In[3] & In[2] & In[1] & ~In[0]) | (In[3] & In[2] & In[1] & In[0]);
	assign Out[3] = (~In[3] & ~In[2] & ~In[1] & In[0]) | (~In[3] & In[2] & ~In[1] & ~In[0]) | (~In[3] & In[2] & In[1] & In[0]) | (In[3] & ~In[2] & In[1] & ~In[0]) | (In[3] & In[2] & In[1] & In[0]);
	assign Out[4] = (~In[3] & ~In[2] & ~In[1] & In[0]) | (~In[3] & ~In[2] & In[1] & In[0]) | (~In[3] & In[2] & ~In[1] & ~In[0]) | (~In[3] & In[2] & ~In[1] & In[0]) | (~In[3] & In[2] & In[1] & In[0]) | (In[3] & ~In[2] & ~In[1] & In[0]);
	assign Out[5] = (~In[3] & ~In[2] & ~In[1] & In[0]) | (~In[3] & ~In[2] & In[1] & ~In[0]) | (~In[3] & ~In[2] & In[1] & In[0]) | (~In[3] & In[2] & In[1] & In[0]) | (In[3] & In[2] & ~In[1] & In[0]);
	assign Out[6] = (~In[3] & ~In[2] & ~In[1] & ~In[0]) | (~In[3] & ~In[2] & ~In[1] & In[0]) | (~In[3] & In[2] & In[1] & In[0]) | (In[3] & In[2] & ~In[1] & ~In[0]);
	
endmodule