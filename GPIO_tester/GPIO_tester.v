module GPIO_tester(input [35:0]GPIO_0, output [9:0]LEDR);
	assign LEDR[5:0] = GPIO_0[5:0];
endmodule