module SPI_mstr16(clk, rst_n, wrt, cmd, done, rd_data, SS_n, SCLK, MOSI, MISO);

// declarations
input [15:0] cmd;
input MISO;
input clk, rst_n, wrt;

output reg SS_n, SCLK, MOSI;
output reg done;
output reg [15:0] rd_data;

reg [4:0] sclk_div;
reg [15:0] shft_reg;
reg [4:0] bit_cnt;
reg MISO_smpl;
reg rst_cnt;
reg smpl, shft;

reg set_ss_n, clr_ss_n, clr_done, set_done;

// State machine implementation
typedef enum reg [3:0] {IDLE, FRONT_PORCH, BACK_PORCH, BITS} state_t;
state_t state, next_state;

// SCLK based on the most sig bit
assign SCLK = sclk_div[4];
assign rd_data = shft_reg;
assign MOSI = shft_reg[15];

//bit count for number of shifts
always @(posedge clk, negedge rst_n) begin
   if(!rst_n)
       bit_cnt <= 5'h0;
   else if(rst_cnt) 
       bit_cnt <= 5'h0;
   else if(shft)
       bit_cnt <= bit_cnt + 1;
end

// Assign MISO_smpl
always @(posedge clk, negedge rst_n) begin
   if (smpl)
      MISO_smpl = MISO;
end

// counter for sclk
always @(posedge clk, negedge rst_n) begin
   if(!rst_n)
      sclk_div <= 5'b00000;
   else if (rst_cnt)
      sclk_div <= 5'b10111;
   else 
      sclk_div <= sclk_div + 1;
end

// 16 bit shift register
always @(posedge clk, negedge rst_n) begin
   if(!rst_n)
      shft_reg <= 16'h0000;
   else if (wrt)
      shft_reg <= cmd;
   else if (shft)
      shft_reg <= {shft_reg[14:0], MISO_smpl};
end

// done
always_ff @(posedge clk, negedge rst_n) begin
   if(!rst_n)
      done <= 0;
   else if (set_done)
      done <= 1;
   else if (clr_done)
      done <= 0;
end

//  SS_n
always_ff @(posedge clk, negedge rst_n) begin
   if(!rst_n)
     SS_n <= 1;
   else if (set_ss_n)
     SS_n <= 1;
   else if (clr_ss_n)
     SS_n <= 0;
end

// next state logic
always_ff @(posedge clk, negedge rst_n) begin
   if(!rst_n)
     state <= IDLE;
   else
     state <= next_state;
end

// combinational logic for the state machine
always_comb begin
 
  // default outputs for the state machine
  set_ss_n = 0;
  clr_ss_n = 0;
  set_done = 0;
  clr_done = 0; 
  shft = 0;
  smpl = 0;
  rst_cnt = 0;
  next_state = IDLE;

  case(state)
 
   IDLE: begin
    if(wrt) begin
       next_state = FRONT_PORCH; 
       clr_done = 1'b1;
       clr_ss_n = 1'b1;
       rst_cnt = 1'b1;     
    end
    else
       next_state = IDLE;
   end

   FRONT_PORCH: begin
     if(sclk_div == 5'b11111) begin
       next_state = BITS;
     end
     else begin
       next_state = FRONT_PORCH;
     end
   end

   BITS: begin
     if(bit_cnt == 5'b01111 & sclk_div == 5'b01111) begin
       next_state = BACK_PORCH;
       smpl = 1'b1;
     end
     else if(sclk_div == 5'b01111) begin
       next_state = BITS;
       smpl = 1'b1;
     end
     else if(sclk_div == 5'b11111) begin
       next_state = BITS;
       shft = 1'b1;
     end
     else begin
        next_state = BITS;
     end
   end

  BACK_PORCH: begin
     if(sclk_div == 5'b11111) begin
        next_state = IDLE;
        shft = 1'b1;
        set_done = 1'b1;
        set_ss_n = 1'b1;
        rst_cnt = 1'b1;   
     end
     else
        next_state = BACK_PORCH;
  end
   
  default: next_state = IDLE;
  
 endcase

end

endmodule
