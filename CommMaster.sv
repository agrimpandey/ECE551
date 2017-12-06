module CommMaster(clk, rst_n, resp_rdy, resp, data, snd_cmd, cmd, TX, RX);

// Coded by: Doug Neu //

input snd_cmd, clk, rst_n, RX;
input [7:0] cmd;
input [15:0] data;
output logic TX, resp_rdy;
output logic [7:0] resp;

logic trmt; // From comm SM
logic [1:0] sel; // From comm SM
logic tx_done; // From UART tranveiver
logic [7:0] tx_data;
logic snd_frm;
logic frm_snt;

logic clr_rx_rdy;

logic clr_cmplt, set_cmplt;

logic [7:0] FF1, FF2;

UART UART1(.clk(clk), .rst_n(rst_n), .TX(TX), .RX(RX), .rx_rdy(resp_rdy), .clr_rx_rdy(clr_rx_rdy),
		      .rx_data(resp), .trmt(trmt), .tx_data(tx_data), .tx_done(tx_done));


//assign resp_rdy = trmt;
assign snd_frm = snd_cmd;
assign tx_data = (sel == 2'b00) ? FF2 : // Last 8 bits of data
		 (sel == 2'b01) ? FF1 : // First 8 bits of data
	 	  cmd; // If neither high or low byte selected, use cmd
 

// FF logic for input 1 to mux
always_ff @(posedge clk, negedge rst_n) begin
  if (!rst_n)
    FF1 <= 8'h0;
  else if (snd_cmd)
    FF1 <= data[15:8];
end

// FF logic for input 0 to mux
always_ff @(posedge clk, negedge rst_n) begin
  if (!rst_n)
    FF2 <= 8'h0;
  else if (snd_cmd)
    FF2 <= data[7:0];
end

// SR Flip Flop to set frm_snt
always @(posedge clk, negedge rst_n) begin
  if(!rst_n)
    frm_snt = 1'b0;
  else if(set_cmplt)
    frm_snt = 1'b1;
  else if(clr_cmplt)
    frm_snt = 1'b0;
end


// STATE MACHINE IMPLEMENTATION
typedef enum reg [3:0] {IDLE, WaitH, WaitM, WaitL} state_t;
state_t state, next_state;

always_ff @(posedge clk, negedge rst_n) begin
  if (!rst_n)
    state <= IDLE;
  else
    state <= next_state;
end

always_comb begin
  trmt = 1'b0;
  set_cmplt = 1'b0;
  clr_cmplt = 1'b0;
  sel = 2'b10;
  clr_rx_rdy = 1'b0;
  next_state = IDLE;

  case(state)
    IDLE : begin
      if (snd_frm) begin
	trmt = 1'b1;
	clr_cmplt = 1'b1;
	clr_rx_rdy = 1'b1;
	next_state = WaitH;
      end
      else
	next_state = IDLE;
	set_cmplt = 1'b1;
    end

    WaitH : begin
      if(tx_done) begin
        next_state = WaitM;
        trmt = 1'b1;
	sel = 2'b01;
      end
      else begin
        next_state = WaitH;
      	sel = 2'b10;
	clr_cmplt = 1'b1;
      end
    end

    WaitM : begin
      if(tx_done) begin
	next_state = WaitL;
	sel = 2'b00;
	trmt = 1'b1;
      end
      else begin
	next_state = WaitM;
	clr_cmplt = 1'b1;
	sel = 2'b01;
      end
    end

    WaitL : begin
      if (tx_done) begin
        set_cmplt = 1'b1;
	next_state = IDLE;
      end
      else begin
	next_state = WaitL;
	clr_cmplt = 1'b1;
	sel = 2'b00;
      end
    end

  endcase
end

endmodule