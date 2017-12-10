/**
@author: Agrim Pandey
@partners: Doug Neu, Ethan Link, Sneha Patri
*/

module cmd_cfg(clk, 
               rst_n,
               cmd_rdy,
               cmd, 
               data,
               batt,
               cal_done, 
               cnv_cmplt,
               clr_cmd_rdy,
               resp,
               send_resp, 
               d_ptch, 
               d_roll,
               d_yaw,
               thrst,
               strt_cal,
               inertial_cal,
               motors_off, 
               strt_cnv);

input clk; 
input rst_n;
input cmd_rdy;
input [7:0] cmd; 
input [15:0] data;
input [7:0] batt;
input cal_done; 
input cnv_cmplt;

output reg clr_cmd_rdy;
output reg [7:0] resp;
output reg send_resp; 
output logic [15:0] d_ptch; 
output logic [15:0] d_roll;
output logic [15:0] d_yaw;
output reg [8:0] thrst;
output reg strt_cal;
output reg inertial_cal;
output logic motors_off; 
output reg strt_cnv;

logic motors_off_fsm;
logic en_mtrs;

logic wptch;
logic wyaw;
logic wroll;
logic wthrst;
logic clr_tmr,emergency;
logic tmr_full;

parameter WIDTH = 9;

localparam REQ_BATT = 8'h01;
localparam SET_PTCH = 8'h02;
localparam SET_ROLL = 8'h03;
localparam SET_YAW = 8'h04;
localparam SET_THRST = 8'h05;
localparam EMER_LAND = 8'h08;
localparam MTRS_OFF = 8'h07;
localparam CALIBRATE = 8'h06;

timer_module #(WIDTH) iDUTtimer(.clk(clk), .rst_n(rst_n), .clr_tmr(clr_tmr), .tmr_full(tmr_full));

//////////////////////////////
// d_ptch output logic     //
////////////////////////////
always_ff @(posedge clk, negedge rst_n) begin
  if(!rst_n)
    d_ptch <= 16'b0;
  else if(wptch)
    d_ptch <= data;
end

//////////////////////////////
// d_roll output logic     //
////////////////////////////
always_ff @(posedge clk, negedge rst_n) begin
  if(!rst_n)
    d_roll <= 16'b0;
  else if(wroll)
    d_roll <= data;
end

//////////////////////////////
// d_yaw output logic      //
////////////////////////////
always_ff @(posedge clk, negedge rst_n) begin
  if(!rst_n)
    d_yaw <= 16'b0;
  else if(wyaw)
    d_yaw <= data;
end

always_ff @(posedge clk, negedge rst_n) begin
  if(!rst_n)
    thrst <= 16'b0;
  else if(wthrst)
    thrst <= data;
end

//////////////////////////////
// motors_off output logic //
////////////////////////////
always_ff @(posedge clk, negedge rst_n) begin
  if(!rst_n)
    motors_off <= 1'b0;
  else if(motors_off_fsm)
    motors_off <= 1'b1;
  else if(en_mtrs)
    motors_off <= 1'b0;
end

//////////////////////////////
//emergency///////////////////
//////////////////////////////
always_ff @(posedge clk, negedge rst_n) begin
  if(emergency) begin
    d_ptch <= 1'b0;
    d_roll <= 1'b0;
    d_yaw <= 1'b0;
    thrst <= 1'b0;
  end
end

typedef enum reg [3:0] {IDLE, SEND_ACK, BATT, CAL1, CAL2} state_t;
state_t state, nxt_state;

always_ff @(posedge clk, negedge rst_n) begin
   if(!rst_n)
     state <= IDLE;
   else
     state <= nxt_state;
end

always_comb begin 

 wptch = 0;
 wroll = 0;
 wyaw = 0;
 wthrst = 0;
 motors_off_fsm = 0; 
 en_mtrs = 0;
 clr_tmr = 0;
 strt_cnv = 0;
 inertial_cal = 0;
 clr_cmd_rdy = 0;
 send_resp  = 0;
 emergency = 0;
 resp = 0;
 strt_cal = 0;

 case (state)

    IDLE:begin

      nxt_state = IDLE;
       
        if(cmd_rdy) begin

            clr_cmd_rdy = 1;

             case(cmd) 

                SET_PTCH: begin
                   wptch = 1;
                   nxt_state = SEND_ACK;
                end

                SET_ROLL: begin
                   wroll = 1;
                   nxt_state = SEND_ACK;
                end

                SET_YAW: begin
                   wyaw = 1;
                   nxt_state = SEND_ACK;
                end

                SET_THRST: begin
                   wthrst = 1;
                   nxt_state = SEND_ACK;
                end

                EMER_LAND: begin
                   emergency = 1;
                   nxt_state = SEND_ACK;
                end
 
                MTRS_OFF: begin 
                   motors_off_fsm = 1;
                   nxt_state = SEND_ACK;
                end

                REQ_BATT: begin 
                   strt_cnv = 1; 
                   nxt_state = BATT;
                end
          
                CALIBRATE: begin
                   en_mtrs = 1;
                   clr_tmr = 1;
                   nxt_state = CAL1;
                end
            endcase
        end
    end

    BATT: begin
       if(cnv_cmplt) begin
          resp = batt[7:0];
          send_resp = 1;
	  nxt_state = IDLE;
       end
       else
          nxt_state = BATT;
    end

    CAL1: begin
       if(tmr_full) begin
         strt_cal = 1;
         inertial_cal = 1;
         nxt_state = CAL2;
       end
       else begin
         inertial_cal = 1;
         nxt_state = CAL1;
	end
    end

    CAL2: begin
       if(cal_done) begin
         nxt_state = IDLE;
         inertial_cal = 1;
         send_resp = 1;
         resp = 8'hA5;
       end
       else begin
         inertial_cal = 1;
         nxt_state = CAL2;
       end
    end

    SEND_ACK: begin
	resp = 8'hA5;
	send_resp=1;
	nxt_state = IDLE;
    end
  
  default: nxt_state = IDLE;

  endcase

end



endmodule