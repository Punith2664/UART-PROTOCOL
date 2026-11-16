module baud_rate #(
  parameter CLK_FREQ = 10000000,
  parameter BAUD = 9600
)(
  input clk,
  input rst,
  output reg tx_enb,
  output reg rx_enb
);
  localparam divisor_tx = (CLK_FREQ/BAUD);
  localparam divisor_rx = CLK_FREQ/(16*BAUD);
  reg [15:0] count_tx;
  reg [15:0] count_rx;
  always @(posedge clk) begin
    if(rst) begin
      tx_enb <= 0;
      count_tx <= 16'b0;
    end else begin
      if(count_tx == divisor_tx-1) begin
        tx_enb <= 1'b1;
        count_tx <= 16'd0;
      end else begin
        count_tx <= count_tx + 1'b1;
        tx_enb <= 1'b0;
      end
    end
  end
  always @(posedge clk) begin
    if(rst) begin
      rx_enb <= 1'b0;
      count_rx <= 16'b0;
    end else begin
      if(count_rx == divisor_rx-1) begin
        rx_enb <= 1'b1;
        count_rx <= 16'd0;
      end else begin
        count_rx <= count_rx + 1'b1;
        rx_enb <= 1'b0;
      end
    end
  end
endmodule
