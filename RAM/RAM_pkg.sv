package RAM_pkg;
	parameter TESTS = 10000;

	class RAM_rand;
		rand logic rst_n;
        rand logic [9:0] din;
        rand logic [7:0] address;
		rand logic rx_valid;
		rand logic [7:0] dout;
		rand logic tx_valid;

		constraint Reset {rst_n      dist {1'b1:/98, 1'b0:/2};}


		covergroup cvr_gp ();
			adrdess_cp     : coverpoint address ;
			rx_valid_cp    : coverpoint rx_valid;
			tx_valid_cp    : coverpoint tx_valid;
            rx_tx_cross : cross rx_valid_cp, tx_valid_cp ;
		endgroup


		function new();
			cvr_gp = new();
		endfunction
	endclass

endpackage