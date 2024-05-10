vlib work
vlog RAM_pkg.sv ram.sv RAM_TB.sv  +cover
vsim -voptargs=+acc work.RAM_TB -cover
add wave -position insertpoint  \
sim:/RAM_TB/tx_valid_ref \
sim:/RAM_TB/tx_valid \
sim:/RAM_TB/rx_valid \
sim:/RAM_TB/rst_n \
sim:/RAM_TB/error_count \
sim:/RAM_TB/dout_ref \
sim:/RAM_TB/dout \
sim:/RAM_TB/din \
sim:/RAM_TB/correct_count \
sim:/RAM_TB/clk \
sim:/RAM_TB/add_write_ref \
sim:/RAM_TB/add_read_ref
add wave /RAM_TB/DUT/Assrt1 /RAM_TB/DUT/Assrt2
coverage save RAM.ucdb -onexit
run -all