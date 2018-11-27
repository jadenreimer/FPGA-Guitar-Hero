//module plotter(
//	input [8:0] i_xo,
//	input [7:0] i_yo,
//	input i_plot_enable,
//	input i_plot_select,
//	
//	output o_x_VGA,
//	output o_y_VGA
//	
//);
//
//
//// X register: printing
//reg [8:0] x;
//assign o_colour_VGA = colour_VGA;
//
//always @(posedge clk)
//begin
//	if(reset) colour_VGA <= 9'd0;
//	
//	else if(i_colour_en)
//	begin
//		colour_VGA <= i_colour ? 9'b111111111 : 9'd0;
//	end
//end // colour
//
//
//
//// Y register: printing
//reg [8:0] y;
//assign o_colour_VGA = colour_VGA;
//
//always @(posedge clk)
//begin
//	if(reset) colour_VGA <= 9'd0;
//	
//	else if(i_colour_en)
//	begin
//		colour_VGA <= i_colour ? 9'b111111111 : 9'd0;
//	end
//end // colour
//
//
//
//// Xeq register: value to compare against
//reg [8:0] Xeq;
//
//always @(posedge clk)
//begin
//	if(reset) colour_VGA <= 9'd0;
//	
//	else if(i_colour_en)
//	begin
//		Xeq <= ;
//	end
//end // colour
//
//
//
//// Yeq register: value to compare against
//reg [8:0] Yeq;
//
//always @(posedge clk)
//begin
//	if(reset) colour_VGA <= 9'd0;
//	
//	else if(i_colour_en)
//	begin
//		colour_VGA <= i_colour ? 9'b111111111 : 9'd0;
//	end
//end // colour
//
//
//endmodule