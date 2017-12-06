module SPI_mstr16(clk, rst_n, cmd, wrt, MISO, MOSI, SS_n, SCLK, done, rd_data);

input clk, rst_n;
input wrt;                    // to signal the start from idle state 
input [15:0] cmd;             // Data (command) being sent to inertial sensor or A2D converter
input MISO;                   // master in slave out .. sampled on rising edge

output logic SS_n;            // active low slave select
output logic SCLK;            // serial clock
output logic MOSI;            // changes on the falling edge of SCLK
output logic done;            // asserted when transition from back porch to idle
output logic [15:0] rd_data;  // data read

// SM outputs
logic rst_cnt;                
logic smpl;                   
logic shft;                   
logic set_done; 
logic clr_done;
logic set_SS_n;
logic clr_SS_n;
logic clr_bit_cnt;

logic MISO_smpl;              // to sample MISO synchronously

logic [4:0] sclk_div;         // five bit clock counter
logic [4:0] bit_cnt;          // 16 bit counter
logic [15:0] shft_reg;        // shift register

// SM STATES
typedef enum reg [1:0] {IDLE, FRONT_PORCH, BITS, BACK_PORCH} state_t;
state_t next_state; 
state_t curr_state;


/////////////////////////////
// Continuous assignement //
///////////////////////////
assign SCLK = sclk_div[4];    // MSB of sclk_div
assign MOSI = shft_reg[15];   // MSB of shft_reg
assign rd_data = shft_reg;    // data read

/////////////////////////
// Infer bit_cnt next //
///////////////////////
always @(posedge clk, negedge rst_n) begin
  if(!rst_n)
    bit_cnt = 5'b0;
  else if(clr_bit_cnt)
    bit_cnt = 5'b0;
  else if(shft)
    bit_cnt = bit_cnt + 1;
end

/////////////////////////
// Infer sclk_div     //
///////////////////////
always_ff @(posedge clk, negedge rst_n) begin 
  if(!rst_n)
    sclk_div = 5'b0;
  else if(rst_cnt)    // synch reset
    sclk_div = 5'b10111;
  else
    sclk_div = sclk_div + 1;
end

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

  //////////////////////////////////////
  // Default assign all output of SM //
  ////////////////////////////////////
  smpl = 0;
  shft = 0;
  set_done = 0;
  clr_done = 0;
  rst_cnt = 0;
  set_SS_n = 0;
  clr_SS_n = 0;
  clr_bit_cnt = 0;
  //next_state = IDLE;

  case(curr_state) 

    // initial state
    IDLE: begin                             
      if (wrt) begin
        next_state = FRONT_PORCH;
        rst_cnt = 1;
        clr_done = 1;
        clr_SS_n = 1;
        clr_bit_cnt = 1;
      end 
      else begin
        next_state = IDLE;
      end
    end
  
    FRONT_PORCH: begin                      
      if (sclk_div == 5'b11111) begin
        next_state = BITS;
      end 
      else begin
        next_state = FRONT_PORCH;
      end
    end

    BITS: begin
      // when bit count and sclk_div is 15... given priority
      if (sclk_div == 5'b01111 & bit_cnt == 5'b01111) begin 
        smpl = 1;
        next_state = BACK_PORCH;
      end
      else if (sclk_div == 5'b11111) begin
        next_state = BITS;
        shft = 1;
      end
      else if(sclk_div == 5'b01111) begin
        smpl = 1;
        next_state = BITS;
      end
      else begin
        next_state = BITS;
      end 
    end 

    BACK_PORCH: begin                             
      if(sclk_div == 5'b11111) begin
        next_state = IDLE;
        rst_cnt = 1;
        set_done = 1;
        set_SS_n = 1;
        shft = 1;
      end 
      else begin
        next_state = BACK_PORCH;
      end
    end

  default: begin // default case state should be IDLE
    next_state = IDLE;
  end
    
  endcase

 end // end of always block

/////////////////////
// MISO sampling  //
///////////////////
always_ff @(posedge clk) begin 
  if(smpl)
    MISO_smpl <= MISO;
end 

//////////////////
// MOSI write  //
////////////////
always_ff @(posedge clk, negedge rst_n) begin
  if (!rst_n)
    shft_reg = 16'b0;
  else if (wrt)
    shft_reg = cmd;
  else if(shft)  
    shft_reg = {shft_reg[14:0], MISO_smpl};
end

/////////////////////////
// Output done logic  //
///////////////////////
always_ff  @(posedge clk, negedge rst_n) begin
  if(!rst_n)
    done <= 1'b0;
  else if(set_done)
    done <= 1'b1;
  else if(clr_done)
    done <= 1'b0;
  else if (wrt)
    done <= 1'b0;
end 

/////////////////////////
// SS_n output logic  //
///////////////////////
always_ff @(posedge clk, negedge rst_n) begin
  if(!rst_n)
    SS_n <= 1'b1;
  else if(set_SS_n)
    SS_n <= 1'b1;
  else if (wrt)
    SS_n <= 1'b0;
end 

endmodule
