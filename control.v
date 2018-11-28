/*
 * -------------------------------------------------------------------------------------------------------------------------------
 * Control path
 * -------------------------------------------------------------------------------------------------------------------------------
 */
 
module control (
	input reset, clk,
	
	input beat, // Rate-driven clock
	input start, // Controls if we should start dropping keys
	input printed_register, // Check if register has been 100% read [input from "printed_register", y_counter module
	input [8:0] check_for_background, // Avoid printing the background of sprites
	input plot_done,
	
	input done_xy,
	input [2:0] counted_rows, // The value of the y-counter
	
	input load_reg,
	
//	output reg FSM_plotEn, // Control VGA plotting
	output reg FSM_clear, // Controls if we are clearing from the register
	output reg FSM_plot, // Controls if we are drawing from the register
	output reg FSM_shift, // Controls if we are still taking in from the register
	output reg FSM_pause
);

	reg [2:0] current_state, next_state;
	
	localparam	MAIN				= 0,
					DEC_REG			= 1,
					DRAW				= 2,
					PAUSE_DRAW		= 3,
					WAIT				= 4,
					ERASE				= 5;
	
	// state table
	always @ (*)
	begin: state_table
		case (current_state)
		
			MAIN: next_state = start ? DEC_REG : MAIN;

			DEC_REG: next_state =  DRAW;
			DRAW: next_state = printed_register ? WAIT : DRAW; // Counted column is if there is a change in the column counter

			WAIT: next_state = beat ? ERASE : WAIT;
			ERASE: next_state = printed_register ? DEC_REG : ERASE;
		
			default: next_state = DEC_REG;
		endcase
	end // state table
	
	
	always @ (*)
	begin: enable_signals
	
		FSM_clear		<= 0;
		FSM_plot			<= 0;
		FSM_shift		<= 0;
		
		case (current_state)
					
			DEC_REG:
			begin
				FSM_shift		<= 1;
			end
				
			DRAW:
			begin
				FSM_plot			<= 1;
			end
			
			ERASE:
			begin
				FSM_clear		<= 1;
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
