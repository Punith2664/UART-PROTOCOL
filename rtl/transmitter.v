module transmitter (
  input clk,
  input rst,
  input [7:0] data_in,
  input tx_enb,
  input start,
  output reg tx,
  output reg busy
);
  parameter IDLE = 2'd0, START = 2'd1, DATA = 2'd2, STOP = 2'd3;
  reg [2:0] state;
  reg [2:0] bit_cnt;
  reg [7:0] shift_reg;
  always @(posedge clk) begin
    if(rst) begin
      tx <= 1'b1;
      busy <= 1'b0;
      bit_cnt <= 3'd0;
      shift_reg <= 8'd0;
      state <= IDLE;
    end else begin
      case (state)
        IDLE: begin
          if(start) begin
            shift_reg <= data_in;
            tx <= 1'b1;
            bit_cnt <= 3'd0;
            state <= START;
          end
        end
        START: begin
          tx <= 1'b0;
          busy <= 1'b1;
          if(tx_enb) state <= DATA;
        end
        DATA: begin
          tx <= shift_reg[bit_cnt];
          if(tx_enb && busy) begin
            bit_cnt <= bit_cnt + 3'd1;
            if(bit_cnt == 3'd7) begin
              state <= STOP;
              bit_cnt <= 3'd0;
            end
          end
        end
        STOP: begin
          tx <= 1'b1;
          if(tx_enb) begin
            busy <= 1'b0;
            state <= IDLE;
          end
        end
      endcase
    end
  end
endmodule
