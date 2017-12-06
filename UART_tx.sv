module UART_tx(clk, rst_n, trmt, tx_data, tx_done, TX);



// all outputs of the state machine and topology

input clk, rst_n, trmt;

input [7:0] tx_data;



output logic TX;

output logic tx_done;



logic clr_done;

logic set_done;



logic load, shift, transmitting;

logic [3:0] bit_cnt;

logic [11:0] baud_cnt;

logic [9:0] tx_shft_reg;



// state machine enum: 3 states

typedef enum logic [1:0] {IDLE, TRANS, DONE} state_t;

state_t state;

state_t next_state;



// logic to assert shift which in turn increases bit_cnt

assign shift = (baud_cnt == 2603) ? 1:0;

//assign 0th bit of the shift register to TX

assign TX = tx_shft_reg[0]; 



// if reset is asserted, it is in idle state, else it goes to next state  

always_ff @(posedge clk, negedge rst_n) begin

  if(!rst_n)

     state <= IDLE;

  else

     state <= next_state;

end



// combinatorial logic for the state machine

always_comb begin

   transmitting = 0;

   clr_done = 0;

   set_done = 0;

   load = 0;



   case(state)



   IDLE: if(trmt) begin

        load = 1'b1;

        clr_done = 1'b1;

        next_state = TRANS;      

    end

    else begin

        next_state = IDLE;

        set_done = 1'b1;

    end

        

   TRANS: if(!shift) begin

        transmitting = 1'b1;

        next_state = TRANS;

     end

     else begin 

        transmitting = 1'b1;

        next_state = DONE;

     end

   

   DONE: if(bit_cnt != 10) begin

        transmitting = 1'b1; 

        next_state = TRANS;

     end

     else if (bit_cnt == 10) begin 

        set_done = 1'b1;

        next_state = IDLE;

     end



   default: next_state = IDLE;

  

   endcase

end



// shift register implementation when shift is asserted. 

always_ff @(posedge clk, negedge rst_n) begin 

   if(!rst_n)

       tx_shft_reg <= 0;

   else if(load)

        tx_shft_reg <= {1'b1, tx_data, 1'b0};

   else if(shift)

        tx_shft_reg <= {1'b1, tx_shft_reg[9:1]};

end



// increase baud count when transmitting is asserted, clear when load or shift are asserted

always_ff @(posedge clk) begin 

   if(load || shift)

        baud_cnt = 12'b0;

   else if(transmitting)

        baud_cnt = baud_cnt + 1; 

   end



// increase bit count when shift is asserted, clear when load is asserted

always_ff @(posedge clk) begin 

   if(load)

       bit_cnt = 12'b0; 

   else if(shift)

       bit_cnt = bit_cnt + 1;

end



// set done gets preference. Flip flop based on the outputs of the FSM 

always_ff @(posedge clk, negedge rst_n) begin

   if(set_done)

     tx_done <= 1'b1;

   else if(!rst_n)

     tx_done <= 1'b0;

   else if(clr_done)

     tx_done = 1'b0;

end



endmodule
