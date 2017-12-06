module CommTB();


reg clk, rst_n;
reg snd_cmd;
wire resp_rdy, TX, RX;
wire clr_cmd_rdy, cmd_rdy, resp_sent;
reg snd_resp;

reg [7:0] cmd_in;
reg [15:0] data_in;
wire [7:0] resp;
wire [15:0] data_out;
wire [7:0] cmd_out;
reg [7:0] uw_resp;

CommMaster comm1(.clk(clk), .rst_n(rst_n), .resp_rdy(resp_rdy), .resp(resp), .data(data_in),
                 .snd_cmd(snd_cmd), .cmd(cmd_in), .TX(TX), .RX(RX));

UART_wrapper wrap1(.clk(clk), .rst_n(rst_n), .cmd_rdy(cmd_rdy), .snd_resp(snd_resp), .resp_sent(resp_sent),
		   .clr_cmd_rdy(clr_cmd_rdy), .cmd(cmd_out), .data(data_out), .resp(uw_resp), .TX(RX),.RX(TX));


initial begin
  clk = 0;
  rst_n = 0;
  #1 rst_n = 1;
  
  cmd_in = 8'h2A;
  data_in = 16'h1234;

  @(posedge clk);
  snd_cmd = 0;
  
  @(posedge clk);
  snd_cmd = 1;

  @(posedge clk);
  snd_cmd=0;

  @(posedge cmd_rdy);
  if(data_out == data_in && cmd_out == cmd_in) begin
	  $display("Data/cmd out equals data/cmd in");
	  //$stop();
  end


	// set uw_resp to a value
       uw_resp = 8'h10;
	// assert snd_resp
       snd_resp = 1;
	//wait until resp_rdy
      @(posedge resp_rdy);
	// check if resp == uw_resp
      if(uw_resp == resp)
         $display("success");
         $stop;

end




always begin
  #5 clk = ~clk;
  //if (cmd_rdy) begin
//	if(data_out == data_in) begin
//	  $display("Data out equals data in");
//	  $stop();
//	end
//  end
end

endmodule
