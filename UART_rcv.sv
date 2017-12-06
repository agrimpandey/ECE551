
module UART_rcv(clk, rst_n, RX, clr_rdy, rx_data, rdy);



// all outputs of the state machine and topology

input clk, rst_n;

input clr_rdy;

input RX;



output logic [7:0] rx_data;

output logic rdy;



logic clr; // master to the flip flop

logic set_rdy;



logic start, shift, receiving;

logic [3:0] bit_cnt;

logic [11:0] baud_cnt;

logic [8:0] rx_shft_reg;



localparam half_baud = 1302;



// state machine enum: 3 states

typedef enum logic [1:0] {IDLE, RECEIVE, DONE} state_t;

state_t state;

state_t next_state;



// logic to assert shift which in turn increases bit_cnt

assign shift = (baud_cnt == 0) ? 1'b1: 1'b0;

// assert rx_shft_reg to rx_data

assign rx_data = rx_shft_reg[7:0];



// if reset is asserted, it is in idle state, else it goes to next state

always_ff @(posedge clk, negedge rst_n) begin

  if(!rst_n)

     state <= IDLE;

  else

     state <= next_state;

end



// combinatorial logic for the state machine

always_comb begin

   start = 0;

   receiving = 0;

   clr = 0;

   set_rdy = 0;



   case(state)



   IDLE: if(~RX) begin

        start = 1'b1;

        clr = 1'b1;

        next_state = RECEIVE;      

    end

    else begin

        next_state = IDLE;

        set_rdy = 1'b1;

    end



   RECEIVE: if(!shift) begin

        receiving = 1'b1;

        next_state = RECEIVE;

     end

     else begin

        receiving = 1'b1; 

        next_state = DONE;

     end

   

   DONE: if(bit_cnt != 10) begin

        receiving = 1'b1; 

        next_state = RECEIVE; 


     end

     else if (bit_cnt == 10) begin 

        set_rdy = 1'b1;

        next_state = IDLE;

     end



 default: next_state = IDLE;

  endcase

end



// shift register implementation when shift is asserted. 

always_ff @(posedge clk) begin 

   if(start)

       rx_shft_reg <= 9'h0;

   else if(shift) 

       rx_shft_reg <= {RX, rx_shft_reg[8:1]};

end



// decrease baud count when receiving is asserted

// when shift is asserted, set baud count to 2604

// start assert, load 1302

always_ff @(posedge clk) begin 

   if(start)

        baud_cnt <= half_baud;

   else if(shift)

        baud_cnt <= 2604;

   else if(receiving)

        baud_cnt <= baud_cnt - 1;

   end



// increase bit count when shift is asserted, clear when start is asserted

always_ff @(posedge clk) begin 

   if(start)

       bit_cnt <= 12'b0; 

   else if(shift)

       bit_cnt <= bit_cnt + 1;

end



// clr_rdy (output from state machine) gets preference. Flip flop based on the outputs of the FSM

always_ff @(posedge clk, negedge rst_n) begin

   if(!rst_n)
     rdy <= 1'b0;
   else if(clr_rdy)
     rdy <= 1'b0;
   else if(set_rdy)
     rdy <= 1'b1;
   else if(clr)
     rdy <= 1'b0;

end



endmodule


