module SPI_mstr16_tb();

logic clk, rst_n;

logic MISO, done, SS_n, SCLK, MOSI, wrt;
logic [15:0] cmd;
logic [15:0] rd_data;
reg [7:0] i;

ADC128S  iDUT_adc(.clk(clk),.rst_n(rst_n),.SS_n(SS_n), .SCLK(SCLK), .MISO(MISO), .MOSI(MOSI));
SPI_mstr16 iDUT_spi(.clk(clk), .rst_n(rst_n), .wrt(wrt), .cmd(cmd), .done(done), .rd_data(rd_data), .SS_n(SS_n), .SCLK(SCLK), .MOSI(MOSI), .MISO(MISO));


initial begin
   clk = 0;
   rst_n = 0;
   cmd = 0;
   wrt = 0;

   @(posedge clk)
   @(negedge clk)
   rst_n = 1;

	for(i = 0; i < 100 ; i = i + 1) begin

   		@(posedge clk);
   		wrt = 1;
   		@(posedge clk);
   		wrt = 0;
   		@(posedge done) 
		
		// check to send channel number
  		 wrt = 1;
  		 @(posedge clk);
  		 wrt = 0;
   		 @(posedge clk);

   		 if(done) begin
			$display("Error: Done is asserted before sending data");
			$stop;
   		 end

   		@(posedge done);  

   		if( rd_data != (16'hC00 - (i*8'h10))) begin
			$display("Error: Data sent is not matched");
			$stop;  
   		end
 	end  
 
  	$display("All Tests Passed");
  	$stop;   

end


always 
   #1 clk = ~clk;


endmodule