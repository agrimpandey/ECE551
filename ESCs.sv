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
input motors_off;

output logic frnt; 
output logic bck; 
output logic lft; 
output logic rght;

localparam FRNT_OFF = 10'h220;
localparam BCK_OFF  = 10'h220;
localparam LFT_OFF  = 10'h220;
localparam RGHT_OFF = 10'h220;

logic [10:0] frnt_spd_in;
assign frnt_spd_in = frnt_spd & ~motors_off;

logic [10:0] bck_spd_in;
assign bck_spd_in  = bck_spd  & ~motors_off;

logic [10:0] lft_spd_in;
assign lft_spd_in  = lft_spd  & ~motors_off;

logic [10:0] rght_spd_in;
assign rght_spd_in = rght_spd & ~motors_off;



logic [9:0] frnt_off_in;
assign frnt_off_in = FRNT_OFF & ~motors_off;

logic [9:0] bck_off_in;
assign bck_off_in  = BCK_OFF  & ~motors_off;

logic [9:0] lft_off_in;
assign lft_off_in = LFT_OFF  & ~motors_off;

logic [9:0] rght_off_in;
assign rght_off_in = RGHT_OFF & ~motors_off;



ESC_interface #(18) inst1(.clk(clk), .rst_n(rst_n), 
                    .SPEED(frnt_spd_in), 
                    .OFF(frnt_off_in), 
                    .PWM(frnt));

ESC_interface #(18) inst2(.clk(clk), .rst_n(rst_n), 
                    .SPEED(bck_spd_in), 
                    .OFF(bck_off_in), 
                    .PWM(bck));

ESC_interface #(18) inst3(.clk(clk), .rst_n(rst_n), 
                    .SPEED(lft_spd_in), 
                    .OFF(lft_off_in), 
                    .PWM(lft));

ESC_interface #(18) inst4(.clk(clk), .rst_n(rst_n), 
                    .SPEED(rght_spd_in), 
                    .OFF(rght_off_in), 
                    .PWM(rght));


endmodule
