module top_uart (
    input clk,
    input rst,
    input [7:0] data_in,
    input rx,
    input start,
    output busy,
    output tx,
    output ready,
    output [7:0] data_out
);
    wire baud_tick_tx, baud_tick_rx;
    baud_rate br(
      .clk(clk), .rst(rst),
      .tx_enb(baud_tick_tx), .rx_enb(baud_tick_rx)
    );
    transmitter tr(
      .clk(clk), .rst(rst), .data_in(data_in),
      .tx_enb(baud_tick_tx), .start(start),
      .tx(tx), .busy(busy)
    );
    receiver rc(
      .clk(clk), .rst(rst), .rx_enb(baud_tick_rx),
      .rx(rx), .data_out(data_out), .ready(ready)
    );
endmodule
