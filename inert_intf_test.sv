module inert_intf_test(clk, 
                      RST_n, 
                      NEXT, 
                      LED, 
                      SS_n, 
                      SCLK, 
                      MOSI, 
                      MISO, 
                      INT);

input clk;
input RST_n;
input NEXT;
input MISO;
input INT;

output reg [7:0] LED;
output MOSI;
output SCLK;
output SS_n;

// input to fsm
logic rst_n;
logic next;
logic cal_done;

// output fsm
logic stat;
logic [1:0] sel; 
logic strt_cal;

// output from inert_intf
logic [15:0] ptch, roll, yaw;

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
                 .MISO(MISO));

PB_release inst2(.PB(NEXT), 
                  .clk(clk), 
                  .rst_n(rst_n), 
                  .released(next));

reset_synch inst3(.RST_n(RST_n), 
                .clk(clk), 
                .rst_n(rst_n));

assign LED = (sel == 2'b00) ? yaw[8:1]  :
             (sel == 2'b01) ? roll[8:1] :
             (sel == 2'b10) ? ptch[8:1] : {stat, 7'b0};


//////////
// SM  //
////////
typedef enum reg [1:0] {CAL, PTCH, ROLL, YAW} state_t;
state_t state, next_state;

always_ff @(posedge clk, negedge rst_n) begin
  if (!rst_n)
    state <= CAL;
  else
    state <= next_state;
end

always_comb begin
  strt_cal = 0;
  stat = 0;  
  sel = 0;
  //next_state = CAL;

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
	sel = 2'b01;
    end 
    else begin
      next_state = PTCH;
    end
  sel = 2'b10;
  end

  ROLL: begin 
    if(next) begin 
      	next_state = YAW;
	sel = 2'b00;
    end
    else begin
      next_state = ROLL;
    end
  sel = 2'b01;
  end

  YAW: begin 
    if(next) begin 
      	next_state = PTCH;
	sel = 2'b10;
    end
    else begin
      next_state = YAW;
    end
  sel = 2'b00;
  end

  default: begin
    next_state = CAL;
  end

  endcase
                
end

endmodule
