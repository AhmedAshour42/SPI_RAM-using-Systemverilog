import spi_pkg::*;

localparam TESTS = 10000;

module Wrapper_tb ();

logic MOSI, clk, rst_n, SS_n;
logic MISO;

logic [7:0] MISO_saved_data;
bit rd_addr_recieved;

logic [10:0] MOSI_sequence;
int MOSI_seq_count = 0;

logic rx_valid;
logic [9:0] din_GM;
logic [7:0] dout_GM;
logic tx_valid;

logic [7:0]   address_array          [];
logic [7:0]   data_to_write_array    [];
logic [10:0]  MOSI_sequence_array    [];

int correct_count = 0;
int error_count   = 0;


SPI_Wrapper DUT (MOSI,MISO,SS_n,clk,rst_n);
ram GoldenModel_memory (din_GM,clk,rst_n,rx_valid,dout_GM,tx_valid);
bind SPI_Wrapper SPI_Asrts check_asserts (clk, MOSI, SS_n, rst_n, DUT.s1.cs);

spiclass MyInputs = new;

// clock generation
initial begin
	clk = 0;
	forever begin
		#2;  
		clk = ~clk;
		MyInputs.clk = clk;
	end
end

//Initial block for coverage sampling
initial begin
	forever begin
		@(negedge clk);
		#1;  
		MyInputs.SS_n_cv          = SS_n;
		MyInputs.rst_n            = rst_n;
		MyInputs.MOSI_cv          = MOSI;
		MyInputs.slave_state_cv   = DUT.s1.cs;
		MyInputs.read_address_occ = rd_addr_recieved;
		MyInputs.MOSI_count       = MOSI_seq_count; 
	end
end

initial begin
	$readmemh ("mem.dat",DUT.r1.mem);
	$readmemh ("mem.dat",GoldenModel_memory.mem);
	rx_valid=0 ; din_GM=0; 
	SS_n = 1;
	rst_check ();      // Checking reset
	stimulus_gen();    // Generating addresses and data to write

	// 1st loop to write data in the dut and the golden model
	for (int i = 0; i < 2*TESTS; i++) begin
		MOSI_sequence = MOSI_sequence_array[i];
		din_pass_to_GM ();
		MOSI_pass_to_DUT ();
	end

	// 2nd loop to read and check
	for (int i = 0; i < TESTS; i++) begin
		MOSI_sequence = {3'b110, address_array[i]};
		din_pass_to_GM ();
		MOSI_pass_to_DUT ();
		MOSI_sequence = {3'b111, data_to_write_array[i]}; // Least 8 bits can be anything as they are ignored 
		din_pass_to_GM ();
		MOSI_pass_to_DUT ();
		MISO_Save ();
		MISO_Check ();
	end

	// Third loop (Randomized sequence)
	for (int i = 0; i < TESTS; i++) begin
		assert (MyInputs.randomize());
		MOSI_sequence = MyInputs.MOSI_sequence;
		din_pass_to_GM ();
		MOSI_pass_to_DUT ();
		if (MOSI_sequence[10:8]==3'b111) begin
			MISO_Save ();
			MISO_Check ();
		end
	end

	// Fourth loop full randomization under constrains
	for (int i = 0; i < 10*TESTS; i++) begin
		assert (MyInputs.randomize());
		MOSI  = MyInputs.MOSI_cv;
		rst_n = MyInputs.rst_n;
		SS_n  = MyInputs.SS_n;
		if ((!SS_n) && (rst_n == 1)) begin
			MOSI_sequence ={MOSI_sequence[9:0], MOSI};
			MOSI_seq_count = MOSI_seq_count + 1;

			if (MOSI_seq_count == 12) begin
				if ((MOSI_sequence[10:8] == 3'b111)&&(rd_addr_recieved)) begin
					@(negedge clk);
					SS_n=1;
					@(negedge clk);
					MISO_Save ();
					din_pass_to_GM ();
					@(negedge clk);
					MISO_Check ();
				end
				else if ((MOSI_sequence[10:8] == 3'b110)&&(!rd_addr_recieved)) begin
					din_pass_to_GM ();
				end
				else if (MOSI_sequence[10:9] == 2'b00) begin
					din_pass_to_GM ();
				end
				SS_n = 1;
				MOSI_seq_count = 0;
				@(negedge clk);
			end
			else begin
				@(negedge clk);
			end
		end
		else begin
			MOSI_seq_count = 0;
			MOSI_sequence = 0;
			@(negedge clk);
		end
	end

	$display("After test, Correct cases = %d ; Wrong cases = %d", correct_count, error_count);
	#1;
	$stop;
end

//always block to check if read address sent
always @(negedge clk) begin
	if ( (DUT.s1.cs==READ_ADD) && (DUT.s1.rx_valid==1) ) begin
		rd_addr_recieved = 1;
	end
	else if ( (DUT.s1.cs==READ_DATA) && (DUT.s1.rx_valid==1) ) begin
		rd_addr_recieved = 0;
	end
end

// Task to ganerate writes for the first loop
task stimulus_gen();
	address_array        = new[TESTS];
	data_to_write_array  = new[TESTS];
	MOSI_sequence_array  = new[2*TESTS];
	
	for (int i = 0; i < TESTS; i++) begin
		address_array[i]       = $random;
		data_to_write_array[i] = $random;
	end

	for (int i = 0; i < 2*TESTS; i = i + 2) begin
		MOSI_sequence_array [i]   = {3'b000, address_array[(i/2)]};
		MOSI_sequence_array [i+1] = {3'b001, data_to_write_array[(i/2)]};
	end
endtask : stimulus_gen

// Reset Task
task rst_check ();
	rst_n = 0;
	@(negedge clk);

	if (MISO != 0) begin
		$display("%t : Error - Reset output incorrect", $time());
		error_count = error_count + 1;
	end
	else begin
		correct_count = correct_count + 1;
	end

	rst_n = 1;
endtask : rst_check 

// Task to send the sequence to the Wrapper
task MOSI_pass_to_DUT ();
	SS_n = 0;
	@(negedge clk);
	for (int i = 0; i < 11; i++) begin
		MOSI = MOSI_sequence[10-i];
		@(negedge clk);
	end
	SS_n = 1;
	@(negedge clk);
endtask : MOSI_pass_to_DUT

// Task to send the data to the godlenmodel
task din_pass_to_GM ();
	rx_valid = 1;
	din_GM = MOSI_sequence[9:0];
	@(negedge clk);
	rx_valid=0;
endtask : din_pass_to_GM 

// Task to save MISO serial data into register to compare with goldenmodel
task MISO_Save ();
	for (int i = 0; i < 8; i++) begin
		@(negedge clk);
		MISO_saved_data [7-i] = MISO;
	end
endtask : MISO_Save 

task MISO_Check ();
	if (MISO_saved_data != dout_GM) begin
		$display("%t : Error - MISO output incorrect", $time());
		$display("expected   : %b",dout_GM);
		$display("MISO taken : %b",MISO_saved_data);
		error_count = error_count + 1;
	end
	else begin
		correct_count = correct_count + 1;
	end
endtask : MISO_Check 

endmodule : Wrapper_tb