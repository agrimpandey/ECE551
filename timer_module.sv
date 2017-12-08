module timer_module(clk, rst_n, clr_tmr, tmr_full);

input clk;
input rst_n;
input clr_tmr;

output reg tmr_full;

integer x;
parameter WIDTH = 9;

reg signed [WIDTH-1:0] timer;


always_ff @(posedge clk, negedge rst_n) begin
  if(!rst_n) begin 
	timer <= {WIDTH {1'b0}};
  end
  
  else if(clr_tmr) begin
	timer <= {WIDTH {1'b0}};
  end

  else begin
	timer <= timer + 1;
  end

end


assign tmr_full = &timer;


endmodule
