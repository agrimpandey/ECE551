/**
* @author: Agrim Pandey
* @partner: Sneha Patri
*/
module UART_wrapper(clk,
                    rst_n, 
                    snd_resp, 
                    resp, 
                    clr_cmd_rdy, 
                    cmd_rdy, 
                    resp_sent, 
                    cmd, 
                    data,
		    RX,
		    TX);

input clk, rst_n;		
input snd_resp;
input [7:0] resp;
input clr_cmd_rdy;

output logic cmd_rdy;
output logic resp_sent;
output logic [15:0] data;
output logic [7:0] cmd;    

// UART inputs
input logic RX;
logic trmt;
//logic RX, trmt;		        // strt_tx tells TX section to transmit tx_data

logic clr_rx_rdy;		// rx_rdy can be cleared by this or new start bit
logic [7:0] tx_data;		// byte to transmit .. same as resp[7:0]

// UART outputs
output logic TX;
logic rx_rdy;

//logic TX, rx_rdy;         	// rx_rdy asserted when byte received,
logic tx_done;                  // tx_done asserted when tranmission complete
logic [7:0] rx_data;		// byte received

// some of the SM outputs
logic clr_cmd_rdy_i;
logic set_cmd_rdy;
logic sel_mux_upper8;     
logic sel_mux_middle8; 

// instantiate 8 bit UART
UART iUART(.clk(clk),
           .rst_n(rst_n),
           .RX(RX),
           .TX(TX),
           .rx_rdy(rx_rdy),
           .clr_rx_rdy(clr_rx_rdy),
           .rx_data(rx_data),
           .trmt(snd_resp),
           .tx_data(resp),
           .tx_done(resp_sent));


/////////////////////////////
// Continuous assignement //
///////////////////////////
//assign trmt = snd_resp;
//assign resp_sent = tx_done;
assign data[7:0] = rx_data;


// SM states
typedef enum reg [1:0] {IDLE, BYTE_ONE, BYTE_TWO} state_t;
state_t curr_state;
state_t next_state;

////////////////////////////
// Infer state flop next //
//////////////////////////
always_ff @(posedge clk, negedge rst_n) begin
  if(!rst_n)
    curr_state <= IDLE;
  else 
    curr_state <= next_state;
end

//////////////////////////
// State machine logic //
////////////////////////
always_comb begin 

  // default outputs
  clr_rx_rdy = 0;
  clr_cmd_rdy_i = 0;
  set_cmd_rdy = 0;
  sel_mux_upper8 = 0;     
  sel_mux_middle8 = 0; 

  case(curr_state) // should this be casex
    IDLE: begin
      if(rx_rdy) begin
        next_state = BYTE_ONE;
        //trmt = 1;
        clr_rx_rdy = 1;
        sel_mux_upper8 = 1;
        clr_cmd_rdy_i = 1;
      end
      else begin
        next_state = IDLE;
      end 
    end

    BYTE_ONE: begin
      if(rx_rdy) begin
        next_state = BYTE_TWO;
        //trmt = 1;
        clr_rx_rdy = 1;
        sel_mux_middle8 = 1;
      end
      else begin
        next_state = BYTE_ONE;
      end 
    end

    BYTE_TWO: begin
      if(rx_rdy) begin
        next_state = IDLE;
        clr_rx_rdy = 1;
        set_cmd_rdy = 1;
      end
      else begin
        next_state = BYTE_TWO;
      end 
    end

    default: begin 
      next_state = IDLE;
    end
  endcase
end

////////////////////////////
// data mux logic  /////////
//////////////////////////
always_ff @(posedge clk, negedge rst_n) begin
  if(!rst_n)
    data[15:8] <= 8'b0;
  else if(sel_mux_middle8)
    data[15:8] <= rx_data;
end 

////////////////////////////
// cmd mux logic  //////////
////////////////////////////
always_ff @(posedge clk, negedge rst_n) begin
  if(!rst_n)
    cmd <= 8'b0;
  else if(sel_mux_upper8)
    cmd <= rx_data;
end 

////////////////////////////
// cmd_rdy output logic ///
//////////////////////////
always_ff @(posedge clk, negedge rst_n) begin
  if(!rst_n)
    cmd_rdy <= 1'b0;
  else if(set_cmd_rdy)
    cmd_rdy <= 1'b1;
  else if(clr_cmd_rdy)
    cmd_rdy <= 1'b0;
  else if(clr_cmd_rdy_i)
    cmd_rdy <= 1'b0;
end 


endmodule
