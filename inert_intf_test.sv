module inert_intf_test(clk, rst_n, NEXT, LED, SS_n, SCLK, MOSI, MISO, INT);

input clk;
input rst_n;
input NEXT;
input MISO;
input INT;

output reg [7:0] LED;
output MOSI;
output SCLK;
output SS_n;

logic [1:0] sel; 
logic stat;

logic next;

logic strt_cal;
logic cal_done;

inert_intf inst1(.clk(clk), 
                 .rst_n(rst_n), 
                 .strt_cal(strt_cal), 
                 .INT(INT), 
                 .cal_done(cal_done), 
                 .vld(vld), 
                 .ptch(ptch), 
                 .roll(roll), 
                 .yaw(yaw), 
                 .SS_n(SS_n), 
                 .SCLK(SCLK), 
                 .MOSI(MOSI), 
                 .MISO(MISO);

PB_released inst2();
rst_synch inst3();


assign LED = (sel == 2'b00) ? yaw  :
             (sel == 2'b01) ? roll :
             (sel == 2'b10) ? ptch : {stat, 7'b0};








typedef enum reg [3:0] {CAL, PTCH, ROLL, YAW} state_t;
state_t state, next_state;


always_ff @(posedge clk, negedge rst_n) begin
  if (!rst_n)
    state <= CAL;
  else
    state <= next_state;
end

always_comb begin
  next = 0;
  strt_cal = 0;
  stat = 0;  
  sel = 0;
  next_state = CAL;

  case(state)

  CAL: begin 
    if(cal_done) begin 
      next_state = PTCH;
    end
    else begin
      next_state = CAL;
      strt_cal = 1; 
    end
  stat = 1'b1;
  sel = 2'b11;
  end

  PTCH: begin 
    if(next) begin 
      next_state = ROLL;
    end 
    else begin
      next_state = PTCH;
    end
  sel = 2'b10;
  end

  ROLL: begin 
    if(next) begin 
      next_state = YAW;
    end
    else begin
      next_state = ROLL;
    end
  sel = 2'b01;
  end

  YAW: begin 
    if(next) begin 
      next_state = PTCH;
    end
    else begin
      next_state = YAW;
    end
  sel = 2'b00;
  end

  endcase
                
end

endmodule
