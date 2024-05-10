package spi_pkg;
	parameter IDLE      = 3'b000;
    parameter READ_DATA = 3'b001;
    parameter READ_ADD  = 3'b010;
    parameter CHK_CMD   = 3'b011;
    parameter WRITE     = 3'b100;

	class spiclass;
		bit clk;
        bit read_address_occ;
        logic SS_n_cv;
        logic [2:0] slave_state_cv;
        logic [3:0] MOSI_count;
        bit old_MOSI;
        bit first_MOSI_data;
        rand logic MOSI_cv;
        rand logic rst_n;
		rand logic [10:0] MOSI_sequence;
		rand logic SS_n;
        

		constraint Input_c {
            rst_n               dist {1'b1:=98, 1'b0:=2};
            SS_n                dist {1'b0:/92, 1'b1:/8};

            if (read_address_occ) {
                MOSI_sequence[10:8] dist {3'b000:=33, 3'b001:=33, 3'b111:=33};
            }
            else if (!read_address_occ) {
                MOSI_sequence[10:8] dist {3'b000:=33, 3'b001:=33, 3'b110:=33};   
            }

            if (MOSI_count==2 && !SS_n) {
                MOSI_cv dist {old_MOSI:=100};
            }
            else if (MOSI_count==3 && !SS_n) {
                if  (first_MOSI_data==1'b1) {
                    if (read_address_occ) {
                        MOSI_cv dist {1'b1:=100};
                    }
                    else if (!read_address_occ) {
                        MOSI_cv dist {1'b0:=100};  
                    }
                }
                else {MOSI_cv dist {1'b1:=50, 1'b0:=50};}
            }
        }

        function void post_randomize();
            if (MOSI_count==1 && !SS_n) begin
                old_MOSI = MOSI_cv;
            end
            else if (MOSI_count==2 && !SS_n) begin
               first_MOSI_data = MOSI_cv;
            end
        endfunction


		covergroup cvr_gp @(posedge clk);
			cs_cp  : coverpoint slave_state_cv       {
                    bins IDLE_to_CHK_CMD       = (IDLE=>CHK_CMD);
                    bins CHK_CMD_to_WRITE      = (CHK_CMD=>WRITE);
                    bins CHK_CMD_to_READ_DATA  = (CHK_CMD=>READ_DATA);
                    bins CHK_CMD_to_READ_ADD   = (CHK_CMD=>READ_ADD);
                    bins CHK_CMD_to_IDLE   = (CHK_CMD=>IDLE);
                    bins WRITE_to_IDLE         = (WRITE=>IDLE);
                    bins READ_DATA_to_IDLE     = (READ_DATA=>IDLE);
                    bins READ_ADD_to_IDLE      = (READ_ADD=>IDLE);
                    bins IDLE_state      = {IDLE};
                    bins CHK_CMD_state   = {CHK_CMD};
                    bins WRITE_state     = {WRITE};
                    bins READ_ADD_state  = {READ_ADD};
                    bins READ_DATA_state = {READ_DATA};
                    }
			MOSI_cp   : coverpoint MOSI_cv   ;
			SS_n_cp   : coverpoint SS_n_cv; 

            MOSI_cross_cs : cross MOSI_cp, cs_cp {
                    ignore_bins cs_transition1 = binsof(cs_cp.IDLE_to_CHK_CMD);
                    ignore_bins cs_transition2 = binsof(cs_cp.CHK_CMD_to_WRITE);
                    ignore_bins cs_transition3 = binsof(cs_cp.CHK_CMD_to_READ_DATA);
                    ignore_bins cs_transition4 = binsof(cs_cp.CHK_CMD_to_READ_ADD);
                    ignore_bins cs_transition5 = binsof(cs_cp.WRITE_to_IDLE);
                    ignore_bins cs_transition6 = binsof(cs_cp.READ_DATA_to_IDLE);
                    ignore_bins cs_transition7 = binsof(cs_cp.READ_ADD_to_IDLE);
                    ignore_bins cs_transition8 = binsof(cs_cp.CHK_CMD_to_IDLE);
                    } 
            SS_n_cross_cs : cross SS_n_cp, cs_cp {
                    ignore_bins cs_transition11 = binsof(cs_cp.IDLE_to_CHK_CMD);
                    ignore_bins cs_transition22 = binsof(cs_cp.CHK_CMD_to_WRITE);
                    ignore_bins cs_transition33 = binsof(cs_cp.CHK_CMD_to_READ_DATA);
                    ignore_bins cs_transition44 = binsof(cs_cp.CHK_CMD_to_READ_ADD);
                    ignore_bins cs_transition55 = binsof(cs_cp.WRITE_to_IDLE);
                    ignore_bins cs_transition66 = binsof(cs_cp.READ_DATA_to_IDLE);
                    ignore_bins cs_transition77 = binsof(cs_cp.READ_ADD_to_IDLE);
                    ignore_bins cs_transition88 = binsof(cs_cp.CHK_CMD_to_IDLE);
                    }
            MOSI_cross_SS_n     : cross MOSI_cp, SS_n_cp;
		endgroup


		function new();
			cvr_gp = new();
            MOSI_count = 0;
            read_address_occ = 0;
		endfunction
	endclass

endpackage