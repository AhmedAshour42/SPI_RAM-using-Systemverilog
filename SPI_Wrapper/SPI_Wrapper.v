module SPI_Wrapper(MOSI,MISO,SS_n,clk,rst_n);

	input MOSI,clk,rst_n,SS_n;
	output MISO;

	wire [7:0] tx_data1;
	wire tx_valid1,rx_valid1;
	wire [9:0] rx_data1;
	slave s1(.MOSI(MOSI),.SS_n(SS_n),.clk(clk),.rst_n(rst_n),.tx_valid(tx_valid1),.tx_data(tx_data1),.rx_data(rx_data1),.rx_valid(rx_valid1),.MISO(MISO));
	ram r1(.din(rx_data1),.clk(clk),.rst_n(rst_n),.rx_valid(rx_valid1),.dout(tx_data1),.tx_valid(tx_valid1));
	

endmodule
