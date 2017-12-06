// Sneha Patri, Doug Neu, Agrim Pandey, Ethan Link

module A2D_intf_tb();

reg clk, rst_n;
reg strt_cnv;
reg [3:0] chnnl;
wire MISO;

wire SCLK, MOSI, a2d_SS_n;
wire cnv_cmplt;
wire [11:0] res;

reg [7:0] i;

A2D_intf iDUT_mstr(.clk(clk), 
                   .rst_n(rst_n), 
                   .strt_cnv(strt_cnv), 
                   .chnnl(chnnl[2:0]), 
                   .cnv_cmplt(cnv_cmplt), 
                   .res(res), 
                   .MISO(MISO),
                   .MOSI(MOSI), 
                   .SCLK(SCLK),
                   .SS_n(a2d_SS_n));

ADC128S iDUT_slv (.clk(clk),
                  .rst_n(rst_n),
                  .SS_n(a2d_SS_n),
                  .SCLK(SCLK),
                  .MISO(MISO),
                  .MOSI(MOSI));

initial begin
   clk = 0;
   rst_n = 0;
   strt_cnv = 0;
  

   @(posedge clk)
   @(negedge clk)
   rst_n = 1;
  
   chnnl = 3'b000;	
   for(i = 0; i < 100 ; i = i + 1) begin
		
       // check to send channel number
       strt_cnv = 1;
       @(posedge clk);
       strt_cnv = 0;
       @(posedge clk);

       if(cnv_cmplt) begin
         $display("Error: cnv_cmplt is asserted before sending data");
         $stop;
       end

       @(posedge cnv_cmplt);  
 
       if( res != (12'hC00 - (i*8'h10))) begin
         $display("Error: Data sent is not matched");
         $display("i: %d, res: %h", i, res);
         $stop;  
       end

       //chnnl = chnnl + 1;  
   end

   $display("All Tests Passed");
   $stop;   

end

always 
   #1 clk = ~clk;

endmodule


