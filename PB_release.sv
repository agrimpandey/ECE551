module PB_release(PB, clk, rst_n, released);

input PB;
input clk;
input rst_n;
output reg released;

reg w1, w2, w3;

always @ (negedge clk, negedge rst_n) begin 

  if(!rst_n) begin 
     w1 <= 0;
     w2 <= 0;  
     w3 <= 0;  
 end

  else begin
    w3 <= w2;
    w2 <= w1 ;
    w1 <= PB; 
   end
end

assign released = w2 & (~w3); 

endmodule
