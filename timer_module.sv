module timer_module(clk, rst_n, clr_tmr, tmr_full);

input clk;
input rst_n;
input clr_tmr;

output reg tmr_full;

integer x;
parameter WIDTH = 9;

reg signed [WIDTH-1:0] timer;


always_ff @(posedge clk) begin
     if (clr_tmr)
	timer <= 0;
     else
	timer <= timer + 1;
end


assign tmr_full = &timer; 


endmodule
