
task send_cmd(input [7:0] cmd_in, input [15:0] data_in);
	cmd = cmd_in;
	data = data_in;

	@(posedge clk) wrt = 1;
	@(posedge clk) wrt = 0;

endtask

task check_resp(input [7:0] resp, input [7:0] resp_ideal, output reg correct);

	if(resp == resp_ideal)
		$display("Correct Response Recieved.")
	else begin
		$display("ERROR: Incorrect Response Recieved.")
		$stop();
	end

endtask

task initialize();
	
	rst_n = 1'b1;
	@(posedge clk) rst_n = 1'b0;
	@(posedge clk) rst_n = 1'b1;

endtask

