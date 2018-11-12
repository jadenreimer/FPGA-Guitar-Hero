# File Name: squareAnimation
# Author: Shi Jie (Barney) Wei
# Date: November 3, 2018

# set the working dir, where all compiled verilog goes
vlib work

# compile all verilog modules in mux.v to working dir
# could also have multiple veril
vlog squareAnimation.v
vlog vga_adapter.v
vlog vga_address_translator.v
vlog vga_pll.v
vlog vga_controller.v

#load simulation using mux as the top level simulation module
vsim bounce
vsim -L altera_mf_ver vga_adapter
vsim -L altera_mf_ver vga_address_translator
vsim -L altera_mf_ver vga_pll
vsim -L altera_mf_ver vga_controller
vsim -L altera_mf_ver altsyncram
vsim -L altera_mf_ver altpll

#log all signals and add some signals to waveform window
log {/*}
# add wave {/*} would add all items in top level simulation module
add wave {/*}



# INPUT
# 	A. KEY
#		A.1 	KEY[0]		active low synchronous reset (reset FSM and registers but not clear the screen)
#	B. SW
#		B.1 	SW[8:0]		colour (3-bit RGB)
#	C. CLOCK
#		C.1	CLOCK_50
# OUTPUT
#	A. VGA_ADAPTER
#		A.1	VGA_R[7:0]	red colour value
#		A.2	VGA_G[7:0]	green colour value
#		A.3	VGA_B[7:0]	blue colour value
#		A.4	VGA_HS		horizontal sync signals for the VGA monitor
#		A.5	VGA_vs		vertical sync signals for the VGA monitor
#		A.6	VGA_BLANK	signal is always 1 and is necessary for the VGA adapter to function correctly
#		A.7	VGA_SYNC		syncronization signal for the monitor
#		A.8	VGA_CLK		output clock signal operates at the frequency of 25 MHz and is derived from the clock input of the VGA Adapter


		
# TRIAL
#	A Trial 1
#		Input:
#			SW[8:0] = 9'b1_1111_1111 (white)
#		Output:
#		A.1.1 Reset
force {CLOCK_50} 0 0ns, 1 {5ns} -r 10ns
force {KEY[0]} 0 0ns, 1 {10ns}
force {SW[8]} 1 0ns
force {SW[7]} 1 0ns
force {SW[6]} 1 0ns
force {SW[5]} 1 0ns
force {SW[4]} 1 0ns
force {SW[3]} 1 0ns
force {SW[2]} 1 0ns
force {SW[1]} 1 0ns
force {SW[0]} 1 0ns
run 20ns
#		A.1.2 Input (white)
#			CLOCK
force {CLOCK_50} 0 0ns, 1 {5ns} -r 10ns
run 1000ns