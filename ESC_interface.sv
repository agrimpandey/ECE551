module ESC_interface(clk, rst_n, SPEED, OFF, PWM);

input clk;
input rst_n;
input [10:0] SPEED;
input [9:0] OFF;
output logic PWM;

localparam CNST = 16'd50000;
parameter PERIOD_WIDTH = 20;

reg [PERIOD_WIDTH - 1: 0] count;

logic [11:0] compensated_speed; 
logic [15:0] promote_4_bits;
logic [16:0] setting;
logic R, S;

// adder
assign compensated_speed = SPEED + OFF;
//left shifter
assign promote_4_bits = compensated_speed << 4;
// adder
assign setting = promote_4_bits + CNST; 

// compare: greater than or equal to
assign R = (setting >= count[16:0]) ? 1:0;  

// counter
always_ff@(posedge clk, negedge rst_n) begin
   if (!rst_n)
      count <= 20'h00000;
   else
      count <= count + 1;
end

// and all bits
assign S = &count[PERIOD_WIDTH - 1:0]; 

// sr ff
always_ff @(posedge clk, negedge rst_n) begin
  if (!rst_n)
    PWM <= 1'b0;
  else if (S)
    PWM <= 1'b1;
  else if (R)
    PWM <= 1'b0;
  // else PWM retains the value
end

endmodule 
