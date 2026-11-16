module receiver (
  input clk,
  input rst,
  input rx_enb,
  input rx,
  output reg [7:0] data_out,
  output reg ready
);
  parameter IDLE = 2'd0, START = 2'd1, DATA = 2'd2, STOP = 2'd3;
  reg [1:0] state;
  reg [2:0] bit_cnt;
  reg [3:0] sample_cnt;
  always @(posedge clk) begin
    if(rst) begin
      data_out <= 8'd0;
      ready <= 1'b0;
      bit_cnt <= 3'd0;
      sample_cnt <= 4'd0;
      state <= IDLE;
    end else begin
      case (state)
        IDLE: begin
          ready <= 1'b0;
          if(!rx) begin
            sample_cnt <= 4'd0;
            state <= START;
          end
        end
        START: begin
          if(rx_enb) begin
            sample_cnt <= sample_cnt + 4'd1;
            if(sample_cnt == 4'd7) begin
              if(!rx) begin
                sample_cnt <= 4'd0;
                state <= DATA;
              end else state <= IDLE;
            end
          end
        end
        DATA: begin
          if(rx_enb) begin
            sample_cnt <= sample_cnt + 4'd1;
            if(sample_cnt == 4'd15) begin
              data_out[bit_cnt] <= rx;
              sample_cnt <= 4'd0;
              bit_cnt <= bit_cnt + 3'd1;
              if(bit_cnt == 3'd7) begin
                state <= STOP;
                bit_cnt <= 3'd0;
              end
            end
          end
        end
        STOP: begin
          if(rx_enb) begin
            sample_cnt <= sample_cnt + 4'd1;
            if(sample_cnt == 4'd15) begin
              ready <= 1'b1;
              state <= IDLE;
            end
          end
        end
      endcase
    end
  end
endmodule
