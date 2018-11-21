module GPIO_input(input CLOCK_50, input [35:0] GPIO_0, output reg [4:0] buttons);
		always @(posedge CLOCK_50)
		begin
			buttons[4:0] <= GPIO_0[4:0];
		end
endmodule
