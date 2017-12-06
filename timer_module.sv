module timer_module(clk, rst_n, clr_tmr, tmr_full);

input clk;
input rst_n;
input clr_tmr;

output reg tmr_full;

integer x;
parameter WIDTH = 9;

reg signed [8:0] timer[0:WIDTH-1];


always_ff @(posedge clk, negedge rst_n) begin
  if(!rst_n) begin 
    for(x=0; x<WIDTH; x=x+1) begin
       timer[x] = 1'b0; 
    end  
  end
  else if(clr_tmr) begin
    for(x=0; x<WIDTH; x=x+1) begin
       timer[x] = 1'b0; 
    end 
  end

  else begin
     for(x=0; x<WIDTH; x=x+1) begin
       timer[x] = 1'b1; 
    end
  end

end


assign tmr_full = timer[0:WIDTH-1] ? 1 : 0;

endmodule
