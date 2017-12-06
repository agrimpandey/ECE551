/**
* @author: Sneha Patri
* @partner: Agrim Pandey
*/
module CommMaster(clk, 
                  rst_n, 
                  snd_cmd, 
                  cmd, 
                  data,
                  resp, 
                  resp_rdy, 
                  frm_cmplt);

input clk, rst_n; 
input snd_cmd;
input [7:0] cmd;
input [15:0] data;

output logic [7:0] resp;
output logic resp_rdy;
output logic frm_cmplt;


// if enabled flops
//input [7:0] cmd_out;
//input [15:0] data_out;
 
// some of the outputs from SM 
logic set_cmplt; 
logic clr_cmplt;
logic sel_cmd;
logic sel_data_lower8;
logic sel_data_upper8;

// an input to fsm
logic snd_frm;

// UART inputs
logic RX, trmt;		        // strt_tx tells TX section to transmit tx_data
logic clr_rx_rdy;		// rx_rdy can be cleared by this or new start bit
logic [7:0] tx_data;		// byte to transmit .. same as resp[7:0]

// UART outputs
logic TX, rx_rdy;         	// rx_rdy asserted when byte received,
logic tx_done;                  // tx_done asserted when tranmission complete
logic [7:0] rx_data;		// byte received

// instantiate 8 bit UART
UART iUART(.clk(clk),
           .rst_n(rst_n),
           .RX(RX),
           .TX(TX),
           .rx_rdy(rx_rdy),
           .clr_rx_rdy(clr_rx_rdy),
           .rx_data(rx_data),
           .trmt(trmt),
           .tx_data(tx_data),
           .tx_done(tx_done));

/////////////////////////////
// Continuous assignement //
///////////////////////////
assign snd_frm = snd_cmd;


// SM states
typedef enum reg [1:0] {IDLE, WAIT_H, WAIT_M, WAIT_L} state_t;
state_t state, next_state;

////////////////////////////
// Infer state flop next //
//////////////////////////
always @(posedge clk or negedge rst_n) begin
     if(!rst_n)
        state <= IDLE;
     else
        state <= next_state;
end

//////////////////////////
// State machine logic //
////////////////////////
always_comb begin

   // default outputs
   trmt = 0;
   set_cmplt = 0; 
   clr_cmplt = 0;
   sel_cmd = 1;
   sel_data_lower8 = 0;
   sel_data_upper8 = 0;

   case(state)
      IDLE: begin
         if(snd_frm) begin
            trmt = 1; 
            clr_cmplt = 1;
            next_state = WAIT_H;
         end 
         else 
            next_state = IDLE;
      end
 
      WAIT_H: begin
        if(tx_done) begin
           sel_data_upper8 = 1;
           trmt = 1;
           next_state = WAIT_M;
        end
        else 
           next_state = WAIT_H;
      end

      WAIT_M: begin
        if(tx_done) begin
           sel_data_lower8 = 1;
           trmt = 1;
           next_state = WAIT_L;
        end
        else 
           next_state = WAIT_M;
      end
       
      WAIT_L: begin
        if(tx_done) begin
           set_cmplt = 1;
           next_state = IDLE;
        end
        else 
           next_state = WAIT_L;
      end

      default: next_state = IDLE;

   endcase
end


////////////////////////////
// data mux logic lower8 //
//////////////////////////
always_ff @(posedge clk, negedge rst_n) begin
  if(!rst_n)
    tx_data <= 8'b0;
  else if(sel_data_lower8)
    tx_data <= data[7:0];
end 

////////////////////////////
// data mux logic upper8 //
//////////////////////////
always_ff @(posedge clk, negedge rst_n) begin
  if(!rst_n)
    tx_data <= 8'b0;
  else if(sel_data_upper8)
    tx_data <= data[15:8];
end 

////////////////////////////
// cmd mux logic  /////////
//////////////////////////
always_ff @(posedge clk, negedge rst_n) begin
  if(!rst_n)
    tx_data <= 8'b0;
  else if(sel_cmd)
    tx_data <= cmd;
end 

/////////////////////////////
// output frm_cmplt logic //
///////////////////////////
always @(posedge clk, negedge rst_n) begin
   if(!rst_n)
      frm_cmplt <= 0;
   else if(set_cmplt)
     frm_cmplt <= 1;
   else if(clr_cmplt) 
     frm_cmplt <= 1;
end

endmodule
