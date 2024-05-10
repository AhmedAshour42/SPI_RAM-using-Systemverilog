module slave(MOSI,SS_n,clk,rst_n,tx_valid,tx_data,rx_data,rx_valid,MISO);

	input MOSI,SS_n,clk,rst_n,tx_valid;
	input [7:0] tx_data;
	output reg [9:0] rx_data;
	output reg rx_valid;
	output reg MISO;

	parameter IDLE = 3'b000;
	parameter READ_DATA = 3'b001;
	parameter READ_ADD = 3'b010;
	parameter CHK_CMD = 3'b011;
	parameter WRITE = 3'b100;
	reg [2:0] cs,ns;
	reg start_to_give,start_to_take;
	reg [7:0] temp;
	reg rd_addr_received;
	reg [5:0] i;
	reg [5:0] j;
	always@(posedge clk or negedge rst_n)	begin
		if(~rst_n)	begin
			cs <= IDLE ;
		end
		else	begin
			cs <= ns ;
		end
	end
	//Next state logic
	always@(cs,SS_n,MOSI)	begin
		case(cs)
			IDLE:
				if(SS_n)		begin
					ns <= IDLE ;
				end
				else	begin
					ns <= CHK_CMD ;
				end
			READ_DATA:
				if(~SS_n)	begin
					ns <= READ_DATA ;
				end
				else	begin
					ns <= IDLE ;
				end
			READ_ADD:
				if(~SS_n)	begin
					ns <= READ_ADD ;
				end
				else	begin
					ns <= IDLE ;
				end
			CHK_CMD:
				if( (~SS_n) && (MOSI == 1) && rd_addr_received )	begin
					ns <= READ_DATA ;
				end
				else if( (~SS_n) && (MOSI == 1) )	begin
					ns <= READ_ADD ;
				end
				else if ( (~SS_n) && (MOSI == 0) )	begin
					ns <= WRITE ;
				end
				else if (SS_n)	begin
					ns <= IDLE ;
				end
			WRITE:
				if(~SS_n)	begin
					ns <= WRITE ;
				end
				else	begin
					ns <= IDLE ;
				end

			default: ns <= IDLE;
		endcase
	end

	always@ (posedge tx_valid or negedge rst_n)begin
		if (!rst_n) begin
			start_to_take <=0;
			temp <= 0;
		end
		else begin
			start_to_take <=1;
			temp <= tx_data;
		end
	end

	always@(posedge clk)	begin
		if (!rst_n) begin
			MISO<=0;
		    i <= 0 ;
			j <= 7;
			rx_data <= 0;
			rx_valid <= 0;
		end
		else begin 
			case (cs)
		    	IDLE:begin
		    		if (!start_to_take) begin
						MISO<=0;
						j <= 7;
					end
		    		i <= 0 ;
					rx_data <= 0;
					rx_valid <= 0;
		    	end
		    	CHK_CMD:begin
		    	    start_to_give <= 1;
		    	    i <= 0 ;
		   		end
			    WRITE:begin
			    	if (start_to_give ==1)	begin
						rx_data <= {rx_data[8:0],MOSI};
						if (i==9) begin
							i<=0;
							start_to_give <= 0;
							if ( (rx_data[8]==1'b0) && (!SS_n)) begin
								rx_valid <=1;
							end
						end
						else  begin
							i <= i + 1 ;
							rx_valid <= 0;
						end
					end
					else begin
						rx_valid <=0;
					end
		    	end
	    		READ_ADD:begin
	    			if (start_to_give ==1)	begin
						rx_data <= {rx_data[8:0],MOSI};
						if (i==9) begin
							i<=0;
							start_to_give <= 0;
							if ( (rx_data[8:7]==2'b10) && (!SS_n) ) begin
								rx_valid <=1;
								rd_addr_received<=1;
							end
						end
						else  begin
							i <= i + 1 ;
							rx_valid <= 0;
						end
					end
					else begin
						rx_valid <=0;
					end
	   	 		end
	    		READ_DATA:begin
	    			if (start_to_give ==1)	begin
						rx_data <= {rx_data[8:0],MOSI};
						if (i==9) begin
							i<=0;
							start_to_give <= 0;
							if ( (rx_data[8:7]==2'b11) && (!SS_n) ) begin
								rx_valid <=1;
								rd_addr_received<=0;
							end
						end
						else  begin
							i <= i + 1 ;
							rx_valid <= 0;
						end
					end
					else begin
						rx_valid <=0;
					end
	    		end
			endcase
		end
	end

	always @(posedge clk)	begin
		if (start_to_take==1) begin
			MISO <= temp[7];
			temp <= {temp[6:0],1'b0};
			if (j == 0)	begin
				start_to_take <= 0 ;
				j <= 7;
			end
			else begin
				j <= j - 1 ;
			end
		end
	end

endmodule
