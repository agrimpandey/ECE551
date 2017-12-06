// Sneha Patri, Doug Neu, Agrim Pandey, Ethan Link

module A2D_intf (clk, 
                 rst_n, 
                 strt_cnv, 
                 chnnl,
                 MISO,  
                 cnv_cmplt, 
                 res, 
                 SS_n,
                 SCLK, 
                 MOSI);

input clk, rst_n;
input strt_cnv;
input [2:0] chnnl;
// SPI interface input
input MISO;

output logic cnv_cmplt;
output logic [11:0] res;

// SPI interface output
output logic SS_n;
output logic SCLK;
output logic MOSI;

logic wrt;
logic set_ready;
logic clr_ready;

// spi output
logic [15:0] rd_data;

SPI_mstr16 spi(.clk(clk), 
               .rst_n(rst_n), 
               .cmd({2'b00,chnnl,11'h000}), 
               .wrt(wrt), 
               .MISO(MISO), 
               .MOSI(MOSI), 
               .SS_n(SS_n), 
               .SCLK(SCLK), 
               .done(done), 
               .rd_data(rd_data));

assign res = rd_data[11:0];

// SM STATES
typedef enum reg [1:0] {IDLE, TRN_ONE, WAIT, TRN_TWO} state_t;
state_t next_state; 
state_t curr_state;

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
    wrt = 0;
    set_ready = 0;
    clr_ready = 0;

  case(curr_state)

    IDLE: begin
      if(strt_cnv) begin
        wrt = 1;
        clr_ready = 1;
        next_state = TRN_ONE;
      end
      else begin
        next_state = IDLE;
      end
    end

    // transaction number 1
    TRN_ONE: begin
      if(done) begin
        next_state = WAIT;
      end
      else begin
        next_state = TRN_ONE;
      end
    end

    // wait one clock cycle
    WAIT: begin
      next_state = TRN_TWO;
      wrt = 1;
    end
    
    // transaction number 2
    TRN_TWO: begin
      if(done) begin
        next_state = IDLE;
        set_ready = 1;
      end
      else begin
        next_state = TRN_TWO;
      end
    end

    default: begin 
      next_state = IDLE;  
    end

  endcase
end

//////////////////////////////
// cnv_cmplt output logic ///
////////////////////////////
always_ff @(posedge clk, negedge rst_n) begin
  if(!rst_n)
    cnv_cmplt <= 1'b0;
  else if(set_ready)
    cnv_cmplt <= 1'b1;
  else if(clr_ready)
    cnv_cmplt <= 1'b0;
end 


endmodule



