module receiver(input clk,rst,rx,rdy_clr,clken,output reg  rdy,output reg [7:0] data_out);
   
parameter RX_STATE_START	    = 2'b00;
parameter RX_STATE_data_out		= 2'b01;
parameter RX_STATE_STOP		    = 2'b10;

reg [1:0] state = RX_STATE_START;
reg [3:0] sample = 0;
reg [3:0] index = 0;
reg [7:0] temp = 8'b0;


always @(posedge clk) begin
    if (rst) begin
        rdy      <= 0;
        data_out <= 0;
        state    <= RX_STATE_START;
        sample   <= 0;
        index    <= 0;
        temp     <= 0;
    end else begin
        if (rdy_clr)
            rdy <= 0;
	if (clken) begin
		case (state)
		RX_STATE_START: begin
			if (!rx || sample != 0)
				sample <= sample + 4'b1;

			if (sample == 15) begin
				state <= RX_STATE_data_out;
				index <= 0;
				sample <= 0;
				temp <= 0;
			end
		end
		RX_STATE_data_out: begin
			sample <= sample + 4'b1;
			if (sample == 4'h8) begin
				temp[index] <= rx;
				index <= index + 4'b1;
			end
			if (index == 8 && sample == 15)
				state <= RX_STATE_STOP;
		end
		RX_STATE_STOP: begin
			if (sample == 15 ) begin
				state <= RX_STATE_START;
				data_out <= temp;
				rdy <= 1'b1;
				sample <= 0;
			end else begin
				sample <= sample + 4'b1;
			end
		end
		default: begin
			state <= RX_STATE_START;
		end
		endcase
	end
end
end

endmodule
