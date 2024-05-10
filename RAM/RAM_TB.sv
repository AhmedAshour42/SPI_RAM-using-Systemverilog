import RAM_pkg::*;

module RAM_TB ();

logic [9:0] din;
logic clk, rst_n , rx_valid;
logic [7:0] dout;
logic tx_valid;

logic [7:0] add_read_ref;
logic [7:0] add_write_ref;
logic [7:0] dout_ref;
logic tx_valid_ref;

logic [7:0]   address_array          [];
logic [7:0]   data_to_write_array    [];
logic [7:0]   RAM_GoldenModel [logic [7:0]];

int correct_count =0;
int error_count   =0;

RAM_rand ram_class = new;

ram DUT (din,clk,rst_n,rx_valid,dout,tx_valid);

initial begin
	clk = 0;
	forever begin
		#1;  clk = ~clk;
	end
end

initial begin
	stimulus1_gen();
	Reset_task ();

	//loop for writing data
	for (int i = 0; i < TESTS; i++) begin
		addrss_write_task (address_array [i]);
		Check_task ();
		data_write_task (data_to_write_array[i]);
		Check_task ();
	end

	//loop for reading the data and checking
	for (int i = 0; i < TESTS; i++) begin
		addrss_read_task (address_array [i]);
		Check_task ();
		DataRead_Check();
	end

	//loop for randomized inputs
	for (int i = 0; i < TESTS; i++) begin
		assert (ram_class.randomize());
		din= ram_class.din;
		rst_n = ram_class.rst_n;
		rx_valid = ram_class.rx_valid;
		Sample_task ();
		Check_task ();
	end

	$display("After test, Correct cases = %d ; Wrong cases = %d", correct_count, error_count);
	#1;
	$stop;
end

always @(posedge clk or negedge rst_n) begin
	if(~rst_n) begin
		dout_ref <= 0;
		tx_valid_ref <= 0;
	end 
	else begin
		case (din[9:8])
	    2'b00: begin
	    	if (rx_valid) begin
	    		add_write_ref<=din[7:0];
	    		tx_valid_ref<=0;
	    	end
	    	else begin
	    		tx_valid_ref<=1'b0;
	    	end
	    end
	    2'b01: begin
	    	if (rx_valid) begin
	    		RAM_GoldenModel[add_write_ref] = din[7:0];;
	    		tx_valid_ref<=0;
	    	end
	    	else begin
	    		tx_valid_ref<=1'b0;
	    	end
	    end
	    2'b10: begin
	    	if (rx_valid) begin
	    		add_read_ref<=din[7:0];
	    		tx_valid_ref<=0;
	    	end
	    	else begin
	    		tx_valid_ref<=1'b0;
	    	end
	    end
	    2'b11: begin
	    	if (rx_valid) begin
	    		dout_ref<=RAM_GoldenModel[add_read_ref];
	    		tx_valid_ref<=1'b1;
	    	end
	    	else begin
	    		tx_valid_ref<=1'b0;
	    	end
	    end
	  endcase
	end
end

task stimulus1_gen();
	address_array        = new[TESTS];
	data_to_write_array  = new[TESTS];
	for (int i = 0; i < TESTS; i++) begin
		address_array[i]       = $random;
		data_to_write_array[i] = $random;
	end
endtask : stimulus1_gen

task addrss_write_task (input logic [7:0] write_address);
	@(negedge clk);
	rst_n=1; rx_valid=1;
	din = {2'b00, write_address};
	Sample_task ();
	@(negedge clk);
	rx_valid=0;
endtask : addrss_write_task 

task data_write_task (input logic [7:0] write_data);
	@(negedge clk);
	rst_n=1; rx_valid=1;
	din = {2'b01, write_data};
	Sample_task ();
	@(negedge clk);
	rx_valid=0;
endtask : data_write_task 

task addrss_read_task (input logic [7:0] read_address);
	@(negedge clk);
	rst_n=1; rx_valid=1;
	din = {2'b10, read_address};
	Sample_task ();
	@(negedge clk);
	rx_valid=0;
endtask : addrss_read_task 

task DataRead_Check();
	@(negedge clk);
	rst_n=1; rx_valid=1;
	din = {2'b11, $random()};
	Sample_task ();
	Check_task ();
	rx_valid=0;
endtask : DataRead_Check

task Sample_task ();
	ram_class.rx_valid = rx_valid;
	ram_class.rst_n = rst_n;
	ram_class.din = din;
	ram_class.dout = dout;
	ram_class.tx_valid = tx_valid;
	if ((rst_n==1) && rx_valid && (din[9:8]==2'b00)) begin
		ram_class.address = din[7:0];
	end
	ram_class.cvr_gp.sample();
endtask : Sample_task 

task Check_task ();
	@(negedge clk)
	if (dout!=dout_ref) begin
		$display("Error - dout incorrect");
		error_count=error_count+1;
	end
	else begin
		correct_count=correct_count+1;
	end

	if (tx_valid !=tx_valid_ref) begin
		$display("Error - tx_valid incorrect");
		error_count=error_count+1;
	end
	else begin
		correct_count=correct_count+1;
	end
endtask : Check_task 

task Reset_task ();
	rst_n=0;
	@(negedge clk)
	if (dout!=0) begin
		$display("Error - Reset dout incorrect");
		error_count=error_count+1;
	end
	else begin
		correct_count=correct_count+1;
	end

	if (tx_valid !=0) begin
		$display("Error - Reset tx_valid incorrect");
		error_count=error_count+1;
	end
	else begin
		correct_count=correct_count+1;
	end
	rst_n=1;
endtask : Reset_task 

endmodule : RAM_TB