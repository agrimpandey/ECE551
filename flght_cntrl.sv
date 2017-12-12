// Author: Sneha Patri
// Partner: Agrim Pandey

module flght_cntrl(clk,rst_n,vld,inertial_cal,d_ptch,d_roll,d_yaw,ptch,
roll,yaw,thrst,frnt_spd,bck_spd,lft_spd,rght_spd);

parameter D_QUEUE_DEPTH = 14; // delay for derivative term
input clk,rst_n;
input vld; // tells when a new valid inertial reading ready
// only update D_QUEUE on vld readings
input inertial_cal; // need to run motors at CAL_SPEED during inertial calibration
input signed [15:0] d_ptch,d_roll,d_yaw; // desired pitch roll and yaw (from cmd_cfg)
input signed [15:0] ptch,roll,yaw; // actual pitch roll and yaw (from inertial interface)
input [8:0] thrst; // thrust level from slider
output [10:0] frnt_spd; // 11-bit unsigned speed at which to run front motor
output [10:0] bck_spd; // 11-bit unsigned speed at which to back front motor
output [10:0] lft_spd; // 11-bit unsigned speed at which to left front motor
output [10:0] rght_spd; // 11-bit unsigned speed at which to right front motor

///////////////////////////////////////////////////
// Need integer for loop used to create D_QUEUE //
/////////////////////////////////////////////////
integer x;
//////////////////////////////
// Define needed registers //
//////////////////////////// 
reg signed [9:0] prev_ptch_err[0:D_QUEUE_DEPTH-1];
reg signed [9:0] prev_roll_err[0:D_QUEUE_DEPTH-1];
reg signed [9:0] prev_yaw_err[0:D_QUEUE_DEPTH-1]; // need previous error terms for D of PD

reg signed [16:0] ptch_err;
reg signed [16:0] roll_err;
reg signed [16:0] yaw_err;

reg signed [9:0] ptch_err_sat;
reg signed [9:0] roll_err_sat;
reg signed [9:0] yaw_err_sat;


reg signed [9:0] ptch_pterm;                   ////// change some to wires from regs
reg signed [9:0] roll_pterm;
reg signed [9:0] yaw_pterm;

reg signed [9:0] ptch_D_diff;
reg signed [9:0] roll_D_diff;
reg signed [9:0] yaw_D_diff;

reg signed [5:0] ptch_D_diff_sat;
reg signed [5:0] roll_D_diff_sat;
reg signed [5:0] yaw_D_diff_sat;

reg signed [11:0] ptch_dterm;
reg signed [11:0] roll_dterm;
reg signed [11:0] yaw_dterm;

reg signed [9:0] ptch_err_sat_pipe;
reg signed [9:0] roll_err_sat_pipe;
reg signed [9:0] yaw_err_sat_pipe;

reg signed [11:0] ptch_dterm_pipe;
reg signed [11:0] roll_dterm_pipe;
reg signed [11:0] yaw_dterm_pipe;

reg signed [9:0] ptch_pterm_pipe;
reg signed [9:0] roll_pterm_pipe;
reg signed [9:0] yaw_pterm_pipe;

reg signed [12:0] frnt_spd_unsat;
reg signed [12:0] bck_spd_unsat;
reg signed [12:0] lft_spd_unsat;
reg signed [12:0] rght_spd_unsat;

reg  [10:0] frnt_spd_sat;
reg  [10:0] bck_spd_sat;
reg  [10:0] lft_spd_sat;
reg  [10:0] rght_spd_sat;


///////////////////////////////////////////////////////////////
// some Parameters to keep things more generic and flexible //
/////////////////////////////////////////////////////////////
  
  localparam CAL_SPEED = 11'h1B0; // speed to run motors at during inertial calibration
  localparam MIN_RUN_SPEED = 13'h200; // minimum speed while running  
  localparam D_COEFF = 6'b00111; // D coefficient in PID control = +7
  
  
/// Pitch, roll, yaw error ///
assign ptch_err = ptch - d_ptch;
assign roll_err = roll - d_roll;
assign yaw_err  = yaw  - d_yaw;

//Math for pitch, roll, yaw err sat ////
assign ptch_err_sat = ptch_err[16] ? (~(&ptch_err[15:9]) ? (10'h200): (ptch_err[9:0])) :
     ((|ptch_err[15:9]) ? (10'h1FF): (ptch_err[9:0]));  
assign roll_err_sat = roll_err[16] ? (~(&roll_err[15:9]) ? (10'h200): (roll_err[9:0])) :
     ((|roll_err[15:9]) ? (10'h1FF): (roll_err[9:0]));  
assign yaw_err_sat = yaw_err[16]   ? (~(&yaw_err[15:9]) ? (10'h200): (yaw_err[9:0])) :
     ((|yaw_err[15:9]) ? (10'h1FF): (yaw_err[9:0])); 


//Pipeline all err_stat to shorten path
always_ff @(posedge clk, negedge rst_n) begin
  if (!rst_n)
    ptch_err_sat_pipe <= 0;
  else
    ptch_err_sat_pipe <= ptch_err_sat;
end

always_ff @(posedge clk, negedge rst_n) begin
  if (!rst_n)
    roll_err_sat_pipe <= 0;
  else
    roll_err_sat_pipe <= roll_err_sat;
end

always_ff @(posedge clk, negedge rst_n) begin
  if (!rst_n)
    yaw_err_sat_pipe <= 0;
  else
    yaw_err_sat_pipe <= yaw_err_sat;
end

//right shift 
assign ptch_pterm = {{ptch_err_sat_pipe[9]}, ptch_err_sat_pipe[9:1]} + {{3{ptch_err_sat_pipe[9]}}, ptch_err_sat_pipe[9:3]};
assign roll_pterm = (roll_err_sat_pipe >>> 1) + (roll_err_sat_pipe >>> 3);
assign yaw_pterm = (yaw_err_sat_pipe >>> 1)   +  (yaw_err_sat_pipe >>> 3);

// valid and shift
always_ff @(posedge clk, negedge rst_n) begin
  if(!rst_n) begin 
    for(x=0; x<D_QUEUE_DEPTH; x=x+1) begin
      prev_ptch_err[x] <= 10'h000;
      prev_roll_err[x] <= 10'h000;
      prev_yaw_err[x]  <= 10'h000; 
    end  
  end 
  else if (vld) begin
    for(x=D_QUEUE_DEPTH-1; x>0; x= x-1) begin
      prev_ptch_err[x] <= prev_ptch_err[x-1];
      prev_roll_err[x] <= prev_roll_err[x-1];
      prev_yaw_err[x]  <= prev_yaw_err[x-1]; 
    end 
  prev_ptch_err[0] <= ptch_err_sat_pipe;
  prev_roll_err[0] <= roll_err_sat_pipe;
  prev_yaw_err[0]  <= yaw_err_sat_pipe; 
  end
end

// pitch_D_diff, roll_D_diff and yaw_d_diff 
assign ptch_D_diff = ptch_err_sat_pipe - prev_ptch_err[D_QUEUE_DEPTH-1];
assign roll_D_diff = roll_err_sat_pipe - prev_roll_err[D_QUEUE_DEPTH-1];
assign yaw_D_diff = yaw_err_sat_pipe   - prev_yaw_err[D_QUEUE_DEPTH-1];

// saturate 
assign ptch_D_diff_sat =  ptch_D_diff[9] ? ((&ptch_D_diff[8:6]) ? (ptch_D_diff[5:0]):(6'h20)) : 
           ((|ptch_D_diff[8:6]) ? (6'h1f) : (ptch_D_diff[5:0]));
assign roll_D_diff_sat =  roll_D_diff[9] ? ((&roll_D_diff[8:6]) ? (roll_D_diff[5:0]):(6'h20)) : 
           ((|roll_D_diff[8:6]) ? (6'h1f) : (roll_D_diff[5:0]));
assign yaw_D_diff_sat  =  yaw_D_diff[9] ? ((&yaw_D_diff[8:6]) ? (yaw_D_diff[5:0]):(6'h20)) : 
           ((|yaw_D_diff[8:6]) ? (6'h1f) : (yaw_D_diff[5:0]));

// multiplication
assign ptch_dterm = ptch_D_diff_sat*$signed(D_COEFF);
assign roll_dterm = roll_D_diff_sat*$signed(D_COEFF);
assign yaw_dterm  = yaw_D_diff_sat*$signed(D_COEFF);

// Pipeline all dterms to shorten path
always_ff @(posedge clk, negedge rst_n) begin
  if (!rst_n)
    ptch_dterm_pipe <= 0;
  else
    ptch_dterm_pipe <= ptch_dterm;
end

always_ff @(posedge clk, negedge rst_n) begin
  if (!rst_n)
    roll_dterm_pipe <= 0;
  else
    roll_dterm_pipe <= roll_dterm;
end

always_ff @(posedge clk, negedge rst_n) begin
  if (!rst_n)
    yaw_dterm_pipe <= 0;
  else
    yaw_dterm_pipe <= yaw_dterm;
end

//Pipeline all pterms to shorten path
always_ff @(posedge clk, negedge rst_n) begin
  if (!rst_n)
    ptch_pterm_pipe <= 0;
  else
    ptch_pterm_pipe <= ptch_pterm;
end

always_ff @(posedge clk, negedge rst_n) begin
  if (!rst_n)
    roll_pterm_pipe <= 0;
  else
    roll_pterm_pipe <= roll_pterm;
end

always_ff @(posedge clk, negedge rst_n) begin
  if (!rst_n)
    yaw_pterm_pipe <= 0;
  else
    yaw_pterm_pipe <= yaw_pterm;
end

// unsat speeds
assign frnt_spd_unsat = thrst + 13'h200 - {{3{ptch_pterm_pipe[9]}}, ptch_pterm_pipe} - {{ptch_dterm_pipe[11]}, ptch_dterm_pipe} - {{3{yaw_pterm_pipe[9]}}, yaw_pterm_pipe} - {{yaw_dterm_pipe[11]}, yaw_dterm_pipe};
assign bck_spd_unsat  = thrst + 13'h200 + {{3{ptch_pterm_pipe[9]}}, ptch_pterm_pipe} + {{ptch_dterm_pipe[11]}, ptch_dterm_pipe} - {{3{yaw_pterm_pipe[9]}}, yaw_pterm_pipe} - {{yaw_dterm_pipe[11]}, yaw_dterm_pipe};
assign lft_spd_unsat  = thrst + 13'h200 - {{3{roll_pterm_pipe[9]}}, roll_pterm_pipe} - {{roll_dterm_pipe[11]}, roll_dterm_pipe} + {{3{yaw_pterm_pipe[9]}}, yaw_pterm_pipe} + {{yaw_dterm_pipe[11]}, yaw_dterm_pipe};
assign rght_spd_unsat = thrst + 13'h200 + {{3{roll_pterm_pipe[9]}}, roll_pterm_pipe} + {{roll_dterm_pipe[11]}, roll_dterm_pipe} + {{3{yaw_pterm_pipe[9]}}, yaw_pterm_pipe} + {{yaw_dterm_pipe[11]}, yaw_dterm_pipe};


// sat speeds
assign frnt_spd_sat = (frnt_spd_unsat[12]) ? 11'h0 : 
                      (frnt_spd_unsat[11]) ? 11'h7FF : 
                                             frnt_spd_unsat[10:0];

assign bck_spd_sat = (bck_spd_unsat[12]) ? 11'h0 : 
                      (bck_spd_unsat[11]) ? 11'h7FF : 
                                             bck_spd_unsat[10:0];
assign lft_spd_sat = (lft_spd_unsat[12]) ? 11'h0 : 
                      (lft_spd_unsat[11]) ? 11'h7FF : 
                                             lft_spd_unsat[10:0];

assign rght_spd_sat = (rght_spd_unsat[12]) ? 11'h0 : 
                      (rght_spd_unsat[11]) ? 11'h7FF : 
                                             rght_spd_unsat[10:0];

// outputs
assign frnt_spd = inertial_cal ? CAL_SPEED : frnt_spd_sat;
assign bck_spd  = inertial_cal ? CAL_SPEED : bck_spd_sat;
assign lft_spd  = inertial_cal ? CAL_SPEED : lft_spd_sat;
assign rght_spd = inertial_cal ? CAL_SPEED : rght_spd_sat;

endmodule 
