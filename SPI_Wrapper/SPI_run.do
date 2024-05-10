vlib work
vlog SPI_pkg.sv ram.sv slave.v SPI_Wrapper.v SPI_SVA.sv Wrapper_tb.sv  +cover
vsim -voptargs=+acc work.Wrapper_tb -cover
add wave -position insertpoint  \
sim:/Wrapper_tb/SS_n \
sim:/Wrapper_tb/rst_n \
sim:/Wrapper_tb/MOSI \
sim:/Wrapper_tb/MISO \
sim:/Wrapper_tb/error_count \
sim:/Wrapper_tb/correct_count \
sim:/Wrapper_tb/clk
add wave /Wrapper_tb/DUT/check_asserts/toCHK_CMD_sva /Wrapper_tb/DUT/check_asserts/toWRITE_sva /Wrapper_tb/DUT/check_asserts/toREAD_sva /Wrapper_tb/DUT/check_asserts/toIDLE_sva /Wrapper_tb/DUT/check_asserts/Reset_sva
coverage save SPI.ucdb -onexit
run -all