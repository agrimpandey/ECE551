module ESCs(clk, rst_n, 
            frnt_spd, 
            bck_spd, 
            lft_spd, 
            rght_spd, 
            motors_off,
            frnt, 
            bck, 
            lft, 
            rght);

input clk; 
input rst_n; 
input [10:0] frnt_spd;
input [10:0] bck_spd;
input [10:0] lft_spd; 
input [10:0] rght_spd; 
input motors_off; // Flag to set all speeds and offsets to 0.

output logic frnt; // Speed sent to front copter motor
output logic bck; // Speed sent to back copter motor
output logic lft; // Speed sent to left copter motor
output logic rght; // Speed sent to right copter motor

localparam FRNT_OFF = 10'h220; // Offset term for front speed
localparam BCK_OFF  = 10'h220; // Offset term for back speed
localparam LFT_OFF  = 10'h220; // Offset term for left speed
localparam RGHT_OFF = 10'h220; // Offset term for right speed 

logic [10:0] frnt_spd_in; // Input to ESC_interface to calculate frnt
logic [10:0] bck_spd_in; // Input to ESC_interface to calculate bck
logic [10:0] lft_spd_in; /// Input to ESC_interface to calculate lft
logic [10:0] rght_spd_in; // Input to ESC_interface to calculate rght

logic [9:0] frnt_off_in; // Input to ESC_interface to calculate frnt
logic [9:0] bck_off_in; // Input to ESC_interface to calculate bck
logic [9:0] lft_off_in; // Input to ESC_interface to calculate lft
logic [9:0] rght_off_in; // Input to ESC_interface to calculate rght

// Set speed terms to current frnt_spd only if motors_off is NOT high
// if motors_off is high, set all speeds to 0
assign frnt_spd_in = frnt_spd & {11{~motors_off}};
assign bck_spd_in  = bck_spd  & {11{~motors_off}};
assign lft_spd_in  = lft_spd  & {11{~motors_off}};
assign rght_spd_in = rght_spd & {11{~motors_off}};

// Set offset terms to current offset only if motors_off is NOT high
// if motors_off is high, set all offsets to 0
assign frnt_off_in = FRNT_OFF & {10{~motors_off}};
assign bck_off_in  = BCK_OFF  & {10{~motors_off}};
assign lft_off_in = LFT_OFF  & {10{~motors_off}};
assign rght_off_in = RGHT_OFF & {10{~motors_off}};


// Instantiate ESC_interface with parameter of 20
ESC_interface #(20) inst1(.clk(clk), .rst_n(rst_n), 
                    .SPEED(frnt_spd_in), 
                    .OFF(frnt_off_in), 
                    .PWM(frnt));

// Instantiate ESC_interface with parameter of 20
ESC_interface #(20) inst2(.clk(clk), .rst_n(rst_n), 
                    .SPEED(bck_spd_in), 
                    .OFF(bck_off_in), 
                    .PWM(bck));

// Instantiate ESC_interface with parameter of 20
ESC_interface #(20) inst3(.clk(clk), .rst_n(rst_n), 
                    .SPEED(lft_spd_in), 
                    .OFF(lft_off_in), 
                    .PWM(lft));

// Instantiate ESC_interface with parameter of 20
ESC_interface #(20) inst4(.clk(clk), .rst_n(rst_n), 
                    .SPEED(rght_spd_in), 
                    .OFF(rght_off_in), 
                    .PWM(rght));


endmodule
