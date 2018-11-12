vlib work

vlog fpga_top.v

vsim part2

log {/*}

add wave {/*}

#Recall: KEY is active low
# To start: A = 3, B = 3, C = 7, X = 7

force {clk} 0 0ns, 1 {5ns} -r 10ns 

#reset: 
force {resetn} 0
force {go} 1
force {data_in} 00000000

run 10ns

#2: First Press -> A
force {resetn} 1
force {go} 1
force {data_in} 00000011
 
run 10ns

#3
force {go} 0
force {data_in} 00000011

run 10ns

#4: Second Press -> B 
force {go} 1
force {data_in} 00000011
 
run 10ns

#5: 
force {go} 0
force {data_in} 00000011

run 10ns

#6: Third Press -> C 
force {go} 1
force {data_in} 00000111
 
run 10ns

#7: 
force {go} 0
force {data_in} 00000111

run 10ns

#8: Fourth Press -> X
force {go} 1
force {data_in} 00000111

run 10ns

#9: 
force {go} 0
force {data_in} 00000111

run 10ns

#10: 5th Press
force {go} 1
force {data_in} 00000111

run 100ns
























#reset while running: 
force {resetn} 0
force {go} 1
force {data_in} 00000000

run 10ns

#2: First Press -> A
force {resetn} 1
force {go} 1
force {data_in} 00000011
 
run 10ns

#3
force {go} 0
force {data_in} 00000011

run 10ns

#4: Second Press -> B 
force {go} 1
force {data_in} 00000011
 
run 10ns

#5: 
force {go} 0
force {data_in} 00000011

run 10ns

#6: Third Press -> C 
force {go} 1
force {data_in} 00000111
 
run 10ns

#7: 
force {go} 0
force {data_in} 00000111

run 10ns

#8: Fourth Press -> X
force {resetn} 0
force {go} 1
force {data_in} 00000111

run 100ns















#2: First Press -> A
force {resetn} 1
force {go} 1
force {data_in} 00000011
 
run 10ns

#3
force {go} 0
force {data_in} 00000011

run 10ns

#4: Second Press -> B 
force {go} 1
force {data_in} 00000011
 
run 10ns

#5: 
force {go} 0
force {data_in} 00000011

run 10ns

#6: Third Press -> C 
force {go} 1
force {data_in} 00000111
 
run 10ns

#7: 
force {go} 0
force {data_in} 00000111

run 10ns

#8: Fourth Press -> X
force {go} 1
force {data_in} 00000111

run 10ns

#9: 
force {go} 0
force {data_in} 00000111

run 10ns

#10s: 5th Press
force {go} 1
force {data_in} 00000111

run 100ns