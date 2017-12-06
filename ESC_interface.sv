module esc(clk, rst_n, speed, off, pwm);


input clk;
input rst_n;

input [10:0] speed;

input [9:0] off;

output reg pwm;

reg [19:0] count;

wire [3:0] promotion;


wire [11:0] compensated_speed;

wire [16:0] setting; 


assign compensated_speed = speed + off; 

assign promotion = compensated_speed << 4; 

assign setting = compensated_speed + 16'd50000;

wire [16:0] reset = setting >= count[16:0] ? 1 : 0;

always @(posedge clk, negedge rst_n) begin
  if(!rst_n)
      count <= 20'h00000;
  else 
     count <= count + 1;
end

wire set = &count[19:0];

always_ff @(posedge clk, negedge rst_n)
 if (!rst_n)
 pwm <= 1'b0;
 else if (reset)
 pwm <= 1'b0;
 else if (set)
 pwm <= 1'b1;

 

endmodule
