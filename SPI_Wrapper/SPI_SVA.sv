module SPI_Asrts (clk, MOSI, SS_n, rst_n, slave_cs);
input clk, MOSI, SS_n, rst_n; 
input [2:0] slave_cs;

parameter IDLE = 3'b000;
parameter READ_DATA = 3'b001;
parameter READ_ADD = 3'b010;
parameter CHK_CMD = 3'b011;
parameter WRITE = 3'b100;


property CHK_CMD_transition ;
    @(posedge clk) disable iff(!rst_n) $fell(SS_n) |=> (slave_cs==CHK_CMD);
endproperty

property WRITE_transition ;
    @(posedge clk) disable iff(!rst_n) $fell(SS_n) ##1 (!MOSI && !SS_n) |=> (slave_cs==WRITE);
endproperty

property READ_transition ;
    @(posedge clk) disable iff(!rst_n) $fell(SS_n) ##1 (MOSI && !SS_n) |=> ( ( (slave_cs==READ_ADD)||(slave_cs==READ_DATA) ) );
endproperty

property IDLE_transition ;
    @(posedge clk) disable iff(!rst_n) $rose(SS_n) |=> (slave_cs==IDLE);
endproperty    

property Reset_State ;
    @(posedge clk) !rst_n |=> (slave_cs==IDLE);
endproperty      

toCHK_CMD_sva  : assert property (CHK_CMD_transition);
toWRITE_sva    : assert property (WRITE_transition);
toREAD_sva     : assert property (READ_transition);
toIDLE_sva     : assert property (IDLE_transition);
Reset_sva      : assert property (Reset_State);

toCHK_CMD_cp : cover property (CHK_CMD_transition);
toWRITE_cp   : cover property (WRITE_transition);
toREAD_cp    : cover property (READ_transition);
toIDLE_cp    : cover property (IDLE_transition);
Reset_cp     : cover property (Reset_State);

endmodule