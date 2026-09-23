module uart_top (input rst,input [7:0] data_in,input wr_en,clk,input rdy_clr,output rdy,busy,output [7:0] data_out);

wire rx_clk_en; //collecting output of baud rate generator rx_enb signal
wire tx_clk_en; //connectiong output of baud rate generator tx_enb signal

wire tx_temp; //connecting the output of tx module

baudrate_generator bg(clk,rst,tx_clk_en,rx_clk_en);

transmitter us(clk,wr_en,tx_clk_en,rst,data_in,tx_temp,busy);

receiver ur(clk,rst,tx_temp,rdy_clr,rx_clk_en,rdy,data_out);

endmodule
