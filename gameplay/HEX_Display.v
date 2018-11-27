`timescale 1ns / 1ns // `timescale time_unit/time_precision

//define module HEX_Display
module HEX_Display(num, hex_display);

	//Define input and output buses, which allows us to use ModelSim and the FPGA
	input [3:0]num;
	output [6:0] hex_display;
	
	//Product of Maxterms
	//We will define every instance of where display bar 0 is NOT Logic 1
	//as a product of sums
	assign hex_display[0] = ~((num[3] | num[2] | num[1] | ~num[0])
						& (num[3] | ~num[2] | num[1] | num[0])
						& (~num[3] | num[2] | ~num[1] | ~num[0])
						& (~num[3] | ~num[2] | num[1] | ~num[0]));
	
	//Product of Maxterms
	//We will define every instance of where display bar 1 is NOT Logic 1
	//as a product of sums	
	assign hex_display[1] = ~((num[3] | ~num[2] | num[1] | ~num[0])
						& (num[3] | ~num[2] | ~num[1] | num[0])
						& (~num[3] | num[2] | ~num[1] | ~num[0]) 
						& (~num[3] | ~num[2] | num[1] | num[0]) 
						& (~num[3] | ~num[2] | ~num[1] | num[0])  
						& (~num[3] | ~num[2] | ~num[1] | ~num[0]));
	
	//Product of Maxterms
	//We will define every instance of where display bar 2 is NOT Logic 1
	//as a product of sums
	assign hex_display[2] = ~((num[3] | num[2] | ~num[1] | num[0]) 
						& (~num[3] | ~num[2] | num[1] | num[0]) 
						& (~num[3] | ~num[2] | ~num[1] | num[0]) 
						& (~num[3] | ~num[2] | ~num[1] | ~num[0]));
						
	//Product of Maxterms
	//We will define every instance of where display bar 3 is NOT Logic 1
	//as a product of sums
	assign hex_display[3] = ~((num[3] | num[2] | num[1] | ~num[0]) 
						& (num[3] | ~num[2] | num[1] | num[0]) 
						& (num[3] | ~num[2] | ~num[1] | ~num[0]) 
						& (~num[3] | num[2] | ~num[1] | num[0]) 
						& (~num[3] | ~num[2] | ~num[1] | ~num[0]));
						
	//Product of Maxterms
	//We will define every instance of where display bar 4 is NOT Logic 1
	//as a product of sums
	assign hex_display[4] = ~((num[3] | num[2] | num[1] | ~num[0]) 
						& (num[3] | num[2] | ~num[1] | ~num[0]) 
						& (num[3] | ~num[2] | num[1] | num[0]) 
						& (num[3] | ~num[2] | num[1] | ~num[0]) 
						& (num[3] | ~num[2] | ~num[1] | ~num[0])  
						& (~num[3] | num[2] | num[1] | ~num[0]));
	
	//Product of Maxterms
	//We will define every instance of where display bar 5 is NOT Logic 1
	//as a product of sums
	assign hex_display[5] = ~((num[3] | num[2] | num[1] | ~num[0])
						& (num[3] | num[2] | ~num[1] | num[0]) 
						& (num[3] | num[2] | ~num[1] | ~num[0]) 
						& (num[3] | ~num[2] | ~num[1] | ~num[0]) 
						& (~num[3] | ~num[2] | num[1] | ~num[0]));
						
	//Product of Maxterms
	//We will define every instance of where display bar 6 is NOT Logic 1
	//as a product of sums
	assign hex_display[6] = ~((num[3] | num[2] | num[1] | num[0])
						& (num[3] | num[2] | num[1] | ~num[0]) 
						& (num[3] | ~num[2] | ~num[1] | ~num[0]) 
						& (~num[3] | ~num[2] | num[1] | num[0]));
						
endmodule
						