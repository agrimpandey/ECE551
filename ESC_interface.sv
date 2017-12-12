module ESC_interface(clk, rst_n, SPEED, OFF, PWM);

input clk;
input rst_n;
input [10:0] SPEED;
input [9:0] OFF;
output logic PWM;

localparam CNST = 16'd50000; // Ensure 1ms pulse
parameter PERIOD_WIDTH = 20; 

reg [PERIOD_WIDTH - 1: 0] count; // Variable bit counter

logic [11:0] compensated_speed; 
logic [15:0] promote_4_bits;
logic [16:0] setting;
logic R, S; // Reset, set flags used in SR FF

logic [10:0] PIPE_SPEED; // Pipelined speed
logic [9:0] PIPE_OFF; // Pipelined offset

// Flop OFFset term to improve timing in synthesis
always_ff @(posedge clk, negedge rst_n) begin
  if (!rst_n)
    PIPE_OFF <= 0;
  else
    PIPE_OFF <= OFF;
end

// Flop SPEED term to improve timing in synthesis
always_ff @(posedge clk, negedge rst_n) begin
  if (!rst_n)
    PIPE_SPEED <= 0;
  else
    PIPE_SPEED <= SPEED;
end

// Calculate compensated speed taking offset into account.
assign compensated_speed = PIPE_SPEED + PIPE_OFF;

// Shift left 4 bits to promote them
assign promote_4_bits = compensated_speed << 4;

// Calculate "setting" by adding our constant to the promoted bits
assign setting = promote_4_bits + CNST; 

// If our counter is greater than or equal to setting, R(eset) set high
assign R = (count[16:0] >= setting);  

// Counter for parametrized number of bits
always_ff@(posedge clk, negedge rst_n) begin
   if (!rst_n)
      count <= {PERIOD_WIDTH{1'b0}};
   else
      count <= count + 1;
end

// Set term determined by having a full counter
assign S = &count[PERIOD_WIDTH - 1:0]; 

// SR FF
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
