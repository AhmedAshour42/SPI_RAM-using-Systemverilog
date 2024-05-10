module ram (din,clk,rst_n,rx_valid,dout,tx_valid);
	parameter MEM_DEPTH = 256;
	parameter ADDR_SIZE = 8;

	input [9:0] din;
	input clk, rst_n , rx_valid;
	output reg [7:0] dout;
	output reg tx_valid;

	reg [ADDR_SIZE-1:0] write_addr, read_addr;
	
	reg [ADDR_SIZE-1:0] mem [MEM_DEPTH-1:0];

	property write_addr_SVA ;
		logic [7:0] addr_exp;
		@(posedge clk) disable iff(!rst_n || !rx_valid) (din[9:8] == 2'b00, addr_exp=din[7:0]) |=> (write_addr == addr_exp);
	endproperty

	property read_addr_SVA ;
		logic [7:0] addr_exp;
		@(posedge clk) disable iff(!rst_n || !rx_valid) (din[9:8] == 2'b10, addr_exp=din[7:0]) |=> (read_addr == addr_exp);
	endproperty

	Assrt1 : assert property (write_addr_SVA);
	Assrt2 : assert property (read_addr_SVA);


	always @(posedge clk,negedge rst_n) begin
		if(~rst_n) begin
			dout<='b0;
			tx_valid<='b0;
		end
		else if(rx_valid) begin
			case (din[9:8])
				2'b00: begin
					write_addr <= din[7:0];
					tx_valid <=0;
				end
				2'b01: begin
					mem [write_addr] <= din[7:0];
					tx_valid <=0;
				end	
				2'b10: begin
					read_addr <= din[7:0];
					tx_valid <=0;
				end
				2'b11: begin
					dout <= mem[read_addr];
					tx_valid <=1;
				end
			endcase
		end
		else 
			tx_valid =0;
	end


	
endmodule
