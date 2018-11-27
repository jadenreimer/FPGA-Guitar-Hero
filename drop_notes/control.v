module control (
	input clk, reset,
	
	input i_beat, // Rate-driven clock
	input i_start, // Controls if we should start dropping keys
	
	input i_xctrl_equal,
	input i_yctrl_equal,
	
	input i_x_equal,
	input i_y_equal,
	
	input i_plotted_one,
	
	output reg o_xctrl_sel,
	output reg o_yctrl_sel,
	
	output reg o_colour,
	output reg o_colour_en,
	
	output reg o_xctrl_en,
	output reg o_yctrl_en,
	
	output reg o_x_en,
	output reg o_y_en,
	
	output reg o_x_sel,
	output reg o_y_sel,
	
	output reg o_xeq_en,
	output reg o_yeq_en,
	
	output reg o_reg_en,
	output reg o_plot,
	
	output reg [3:0] c_state, n_state
	
);

	reg [3:0] current_state, next_state;
	
	localparam	MAIN				= 4'd0,
					DEC_REG			= 4'd1,
					D_INC_X			= 4'd2,
					D_INC_Y			= 4'd3,
					D_INC_X_CTRL	= 4'd4,
					D_INC_Y_CTRL	= 4'd5,
					WAIT				= 4'd6,
					C_INC_X			= 4'd7,
					C_INC_Y			= 4'd8,
					C_INC_X_CTRL	= 4'd9,
					C_INC_Y_CTRL	= 4'd10,
					ERASE				= 4'd11;
	
	// state table
	always @ (*)
	begin: state_table
		case (current_state)
		
			MAIN:				next_state = i_start ? DEC_REG : MAIN;
			DEC_REG:			next_state = D_INC_X;
			
			D_INC_X:			next_state = i_x_equal ? D_INC_Y : D_INC_X;
			D_INC_Y:			next_state = i_y_equal ? D_INC_X_CTRL : D_INC_X;
			D_INC_X_CTRL:	next_state = i_xctrl_equal ? D_INC_Y_CTRL : D_INC_X;
			D_INC_Y_CTRL:	next_state = i_yctrl_equal ? WAIT : D_INC_X;
			
			WAIT:				next_state = i_beat ? C_INC_X : WAIT;
			
			C_INC_X:			next_state = i_x_equal ? C_INC_Y : C_INC_X;
			C_INC_Y:			next_state = i_y_equal ? C_INC_X_CTRL : C_INC_X;
			C_INC_X_CTRL:	next_state = i_xctrl_equal ? C_INC_Y_CTRL : C_INC_X;
			C_INC_Y_CTRL:	next_state = i_yctrl_equal ? DEC_REG : C_INC_X;
		
			default: next_state = DEC_REG;
		endcase
	end // state table
	
	
	always @ (*)
	begin: enable_signals
	
		c_state <= current_state;
		n_state <= next_state;
		
		o_reg_en <= 0;
		o_plot <= 0;
		o_xctrl_sel <= 0;
		o_xctrl_en <= 0;
		o_yctrl_sel <= 0;
		o_yctrl_en <= 0;
		o_colour <= 0;
		o_colour_en <= 0;
		o_x_sel <= 0;
		o_x_en <= 0;
		o_y_sel <= 0;
		o_y_en <= 0;
		o_xeq_en <= 0;
		o_yeq_en <= 0;
		
		case (current_state)
		
//			MAIN:
			
//			MAIN:
//			begin
//				
//			end
			
			DEC_REG:
			begin
			
				// enable register, don't plot
				o_reg_en <= 1;
				o_plot <= 0;
				
				// Set to 0
				o_xctrl_sel <= 0;
				o_xctrl_en <= 1;
				
				// Set to 0
				o_yctrl_sel <= 0;
				o_yctrl_en <= 1;
				
				// Colour: white
				o_colour <= 1;
				o_colour_en <= 1;
				
				// Set to initial
				o_x_sel <= 0;
				o_x_en <= 1;
				
				// Set to initial
				o_y_sel <= 0;
				o_y_en <= 1;
				
				// Set to initial
				o_xeq_en <= 1;
				o_yeq_en <= 1;
			end
			
			D_INC_X:
			begin
			
				// disable register, plot
//				o_reg_en <= 0;
				o_plot <= 1;
				
				// xctrl: disable
//				o_xctrl_sel <= 0;
//				o_xctrl_en <= 0;
				
				// yctrl: disable
//				o_yctrl_sel <= ;
//				o_yctrl_en <= ;
				
				// Colour: white
				o_colour <= 1;
				o_colour_en <= 1;
				
				// x: set to initial
				o_x_sel <= 1;
				o_x_en <= 1;
				
				// y: hold value
//				o_y_sel <= 1'bx;
//				o_y_en <= 0;
				
				// == values: hold value
				// CHECK: do these need to be set here or later is fine?
//				o_xeq_en <= 0;
//				o_yeq_en <= 0;
			end
			
			D_INC_Y:
			begin
				
				// disable register, disable plot
//				o_reg_en <= 0;
//				o_plot <= 0;
				
				// xctrl: disable
//				o_xctrl_sel <= ;
//				o_xctrl_en <= ;
				
				// yctrl: disable
//				o_yctrl_sel <= ;
//				o_yctrl_en <= ;
				
				// Don't care about colour: already done
//				o_colour <= 1;
//				o_colour_en <= 1;
				
				// x: reset
				// CHECK: will this change to the NEW ones or back to old?
				// CHECK: will we get off-by-one errors if we reset here and then immediately start counting at INC_X?
				o_x_sel <= 0;
				o_x_en <= 1;
				
				// y: set to initial
				o_y_sel <= 1;
				o_y_en <= 1;
				
				// == values: set to new values
				// CHECK: will this go to new or old?
				o_xeq_en <= 1;
				o_yeq_en <= 1;
			end
			
			D_INC_X_CTRL:
			begin
				
				// disable register, don't plot
//				o_reg_en <= 0;
//				o_plot <= 0;
				
				// xctrl: increment by 1
				o_xctrl_sel <= 1;
				o_xctrl_en <= 1;
				
				// yctrl: disable
//				o_yctrl_sel <= ;
//				o_yctrl_en <= 0;
				
				// Colour: white
				o_colour <= 1;
				o_colour_en <= 1;
				
				// x: disable
//				o_x_sel <= ;
//				o_x_en <= 0;
				
				// y: reset to start; one note plotted
				// CHECK: I'm suspicious of the y-value involved in this resetting
				o_y_sel <= 0;
				o_y_en <= 1;
				
				// == values: set to new values
				// CHECK: same thing about new or old values
				o_xeq_en <= 1;
				// CHECK: when should the y be changing? When should the x be changing?
				o_yeq_en <= 1;
			end
			
			D_INC_Y_CTRL:
			begin
				
				// disable register, don't plot
//				o_reg_en <= 0;
//				o_plot <= 0;
				
				// xctrl: reset
				o_xctrl_sel <= 0;
				o_xctrl_en <= 1;
				
				// yctrl: increment
				o_yctrl_sel <= 1;
				o_yctrl_en <= 1;
				
				// Don't care about colour: already done
//				o_colour <= 1;
//				o_colour_en <= 1;
				
				// x: disable
//				o_x_sel <= ;
//				o_x_en <= 0;
				
				// y: disable
				// CHECK: do we actually need to modify x or y at this point?
//				o_y_sel <= ;
//				o_y_en <= 0;
				
				// == values: set to new values
				// CHECK: will this go to new or old?
				o_xeq_en <= 1;
				o_yeq_en <= 1;
			end
			
//			WAIT:
//			begin

				// disable register, don't plot
//				o_reg_en <= 0;
//				o_plot <= 0;
				
				// xctrl: disable
//				o_xctrl_sel <= ;
//				o_xctrl_en <= 0;
				
				// yctrl: disable
//				o_yctrl_sel <= ;
//				o_yctrl_en <= 0;
				
				// Don't care about colour: already done
//				o_colour <= 1;
//				o_colour_en <= 1;
				
				// x: disable
//				o_x_sel <= ;
//				o_x_en <= 0;
				
				// y: disable
				// CHECK: do we actually need to modify x or y at this point?
//				o_y_sel <= ;
//				o_y_en <= 0;
				
				// == values: set to new values
				// CHECK: will this go to new or old?
//				o_xeq_en <= 1;
//				o_yeq_en <= 1;
//			end
			
			C_INC_X:
			begin
			
				// disable register, plot
//				o_reg_en <= 0;
				o_plot <= 1;
				
				// xctrl: disable
//				o_xctrl_sel <= 0;
//				o_xctrl_en <= 0;
				
				// yctrl: disable
//				o_yctrl_sel <= ;
//				o_yctrl_en <= ;
				
				// Colour: black
				o_colour <= 9'd0;
				o_colour_en <= 1;
				
				// x: set to initial
				o_x_sel <= 1;
				o_x_en <= 1;
				
				// y: hold value
//				o_y_sel <= 1'bx;
//				o_y_en <= 0;
				
				// == values: hold value
				// CHECK: do these need to be set here or later is fine?
//				o_xeq_en <= 0;
//				o_yeq_en <= 0;
			end
			
			C_INC_Y:
			begin
				
				// disable register, disable plot
//				o_reg_en <= 0;
//				o_plot <= 0;
				
				// xctrl: disable
//				o_xctrl_sel <= ;
//				o_xctrl_en <= ;
				
				// yctrl: disable
//				o_yctrl_sel <= ;
//				o_yctrl_en <= ;
				
				// Don't care about colour: already done
//				o_colour <= 1;
//				o_colour_en <= 1;
				
				// x: reset
				// CHECK: will this change to the NEW ones or back to old?
				// CHECK: will we get off-by-one errors if we reset here and then immediately start counting at INC_X?
				o_x_sel <= 0;
				o_x_en <= 1;
				
				// y: set to initial
				o_y_sel <= 1;
				o_y_en <= 1;
				
				// == values: set to new values
				// CHECK: will this go to new or old?
				o_xeq_en <= 1;
				o_yeq_en <= 1;
			end
			
			C_INC_X_CTRL:
			begin
				
				// disable register, don't plot
//				o_reg_en <= 0;
//				o_plot <= 0;
				
				// xctrl: increment by 1
				o_xctrl_sel <= 1;
				o_xctrl_en <= 1;
				
				// yctrl: disable
//				o_yctrl_sel <= ;
//				o_yctrl_en <= 0;
				
				// Colour: disable
//				o_colour <= ;
//				o_colour_en <= 0;
				
				// x: disable
//				o_x_sel <= ;
//				o_x_en <= 0;
				
				// y: reset to start; one note plotted
				// CHECK: I'm suspicious of the y-value involved in this resetting
				o_y_sel <= 0;
				o_y_en <= 1;
				
				// == values: set to new values
				// CHECK: same thing about new or old values
				o_xeq_en <= 1;
				// CHECK: when should the y be changing? When should the x be changing?
				o_yeq_en <= 1;
			end
			
			C_INC_Y_CTRL:
			begin
				
				// disable register, don't plot
//				o_reg_en <= 0;
//				o_plot <= 0;
				
				// xctrl: reset
				o_xctrl_sel <= 0;
				o_xctrl_en <= 1;
				
				// yctrl: increment
				o_yctrl_sel <= 1;
				o_yctrl_en <= 1;
				
				// Don't care about colour: already done
//				o_colour <= 1;
//				o_colour_en <= 1;
				
				// x: disable
//				o_x_sel <= ;
//				o_x_en <= 0;
				
				// y: disable
				// CHECK: do we actually need to modify x or y at this point?
//				o_y_sel <= ;
//				o_y_en <= 0;
				
				// == values: set to new values
				// CHECK: will this go to new or old?
				o_xeq_en <= 1;
				o_yeq_en <= 1;
			end
			
		endcase
			
	end // enable signals
	
    // current_state registers
    always@(posedge clk)
    begin: state_FFs
		if(reset)
			begin
				current_state <= MAIN;
			end
		else
//			begin
			current_state <= next_state;
//			end
	end // state_FFS
	
	
endmodule // control