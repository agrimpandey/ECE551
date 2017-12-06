// @author: Ethan Link
// @partners: Doug Neu, Sneha Patri, Agrim Pandey
module cmd_cfg_tb();

//cmd_cfg stuff
reg clk,rst_n,cal_done,cnv_cmplt;
reg [7:0] cmd;
reg [15:0] data;
reg [7:0] batt;

wire clr_cmd_rdy, send_resp, strt_cal,inertial_cal,motors_off,strt_cnv;
wire [7:0] resp;

wire [15:0] d_ptch, d_roll, d_yaw;
wire [8:0] thrst;
wire [7:0] uw_resp;

//commMaster
reg snd_cmd;
wire resp_rdy;
wire cmd_rdy;
wire [15:0] wrapper_data_out;

wire TX_RX, RX_TX;

wire resp_sent;

reg equal_to_zero;

localparam REQ_BATT = 8'h01;
localparam SET_PTCH = 8'h02;
localparam SET_ROLL = 8'h03;
localparam SET_YAW = 8'h04;
localparam SET_THRST = 8'h05;
localparam EMER_LAND = 8'h08;
localparam MTRS_OFF = 8'h07;
localparam CALIBRATE = 8'h06;

localparam POS_ACK = 8'hA5;


//Initialize CommMaster Block
CommMaster commMaster(.clk(clk), .rst_n(rst_n), .resp_rdy(resp_rdy), .resp(resp), .data(data), .snd_cmd(snd_cmd), .cmd(cmd), .TX(TX_RX), .RX(RX_TX) );

//Initialize UART_wrapper block
UART_wrapper wrapper( .clk(clk), .rst_n(rst_n), .cmd_rdy(cmd_rdy), .snd_resp(send_resp),
	.resp_sent(resp_sent), .clr_cmd_rdy(clr_cmd_rdy), .cmd(cmd), .data(wrapper_data_out), .resp(uw_resp) , .TX(RX_TX), .RX(TX_RX));

//Initialize cmd_cfg block
cmd_cfg commandconfig( .clk(clk), .rst_n(rst_n), .cmd_rdy(cmd_rdy), .snd_rsp(send_resp),
	 .clr_cmd_rdy(clr_cmd_rdy), .cmd(cmd), .data(wrapper_data_out), .resp(uw_resp), .d_ptch(d_ptch), .d_roll(d_roll), .d_yaw(d_yaw), .thrst(thrst), .batt(batt), .strt_cal(strt_cal), .inertial_cal(inertial_cal),
	 .cal_done(cal_done), .motors_off(motors_off), .strt_cnv(strt_cnv), .cnv_cmplt(cnv_cmplt) );

//Initializing signals
initial begin
        equal_to_zero = 0;
	clk = 0;
	rst_n = 0;
	#1 rst_n = 1;

///////////////////////
//SENDING BATTERY CMD//
///////////////////////
	cmd = REQ_BATT;
	data = 16'h0000;
	batt = 8'h48; //arbitrary battery value
	@(posedge clk);
	snd_cmd = 1;
	@(posedge clk) snd_cmd = 0;


	@(posedge strt_cnv);
           cnv_cmplt = 1;

	//Once response is ready, check the response value, and check the result of the command we sent
	@(posedge resp_rdy);
	if( resp == 8'h48 ) begin
		$display("Battery CMD successful.");
	end
	else begin
		$display("ERROR: Battery CMD failed. EXPECTED: 8'h48. ACTUAL: %h.", resp);
		$stop();
	end

////////////////////////
//SENDING SET PTCH CMD//
////////////////////////
	cmd = SET_PTCH;
	data = 16'h4321;
	
	//sending and resetting command
	snd_cmd = 1;
	@(posedge clk) snd_cmd = 0;
	
	//Once response is ready, check the response value, and check the result of the command we sent
	@(posedge resp_rdy)
	if( resp == POS_ACK ) begin
		if( d_ptch == 16'h4321 ) begin
			$display("Response and Set_Ptch successful.");
		end
		else begin
			$display("ERROR: Response sucessful, Set_Ptch incorrect. EXPECTED: 16'h4321. ACTUAL: %h.", d_ptch);
			$stop();	
		end
	end
	else begin
		$display("ERROR: Response incorrect. EXPECTED: 8'hA5 (POS_ACK). ACTUAL: %h.", resp);
		$stop();
	end

////////////////////////
//SENDING SET ROLL CMD//
////////////////////////
	cmd = SET_ROLL;
	data = 16'h6543;
	
	//sending and resetting command
	snd_cmd = 1;
	@(posedge clk) snd_cmd = 0;

	//Once response is ready, check the response value, and check the result of the command we sent
	@(posedge resp_rdy)
	if( resp == POS_ACK ) begin
		if( d_roll == 16'h6543 ) begin
			$display("Response and Set_Roll successful.");
		end
		else begin
			$display("ERROR: Response sucessful, Set_Roll incorrect. EXPECTED: 16'h6543. ACTUAL: %h.", d_roll);
			$stop();	
		end
	end
	else begin
		$display("ERROR: Response incorrect. EXPECTED: 8'hA5 (POS_ACK). ACTUAL: %h.", resp);
		$stop();
	end

///////////////////////
//SENDING SET YAW CMD//
///////////////////////
	cmd = SET_YAW;
	data = 16'h9876;
	
	//sending and resetting command
	snd_cmd = 1;
	@(posedge clk) snd_cmd = 0;
	
	//Once response is ready, check the response value, and check the result of the command we sent
	@(posedge resp_rdy)
	if( resp == POS_ACK ) begin
		if( d_yaw == 16'h9876 ) begin
			$display("Response and Set_Yaw successful.");
		end
		else begin
			$display("ERROR: Response sucessful, Set_Yaw incorrect. EXPECTED: 16'h9876. ACTUAL: %h.", d_yaw);
			$stop();	
		end
	end
	else begin
		$display("ERROR: Response incorrect. EXPECTED: 8'hA5 (POS_ACK). ACTUAL: %h.", resp);
		$stop();
	end

/////////////////////////
//SENDING SET THRST CMD//
/////////////////////////
	cmd = SET_THRST;
	data = 16'h0013;
	
	//sending and resetting command
	snd_cmd = 1;
	@(posedge clk) snd_cmd = 0;
	
	//Once response is ready, check the response value, and check the result of the command we sent
	@(posedge resp_rdy)
	if( resp == POS_ACK ) begin
		if( thrst == 9'h013 ) begin
			$display("Response and THRST successful.");
		end
		else begin
			$display("ERROR: Response sucessful, THRST incorrect. EXPECTED: 9'h013. ACTUAL: %h.", thrst);
			$stop();	
		end
	end
	else begin
		$display("ERROR: Response incorrect. EXPECTED: 8'hA5 (POS_ACK). ACTUAL: %h.", resp);
		$stop();
	end

//////////////////////////////
//SENDING EMERGENCY LAND CMD//
//////////////////////////////
	cmd = EMER_LAND;
	data = 16'h0013;
	
	//sending and resetting command
	snd_cmd = 1;
	@(posedge clk) snd_cmd = 0;
	
	//for the Emergency land: thrst, ptch, roll, and yaw should all be set to 0
	assign equal_to_zero = ((thrst == 0) && (d_ptch == 0) && (d_roll == 0) && (d_yaw == 0));
	
	//Once response is ready, check the response value, and check the result of the command we sent
	@(posedge resp_rdy)
	if( resp == POS_ACK ) begin
		if( equal_to_zero ) begin
			$display("Response and EMER_LAND successful.");
		end
		else begin
			$display("ERROR: Response sucessful, EMER_LAND incorrect. D_PTCH: %h, D_ROLL: %h, D_YAW: %h, THRST: %h", d_ptch, d_roll, d_yaw, thrst);
			$stop();	
		end
	end
	else begin
		$display("ERROR: Response incorrect. EXPECTED: 8'hA5 (POS_ACK). ACTUAL: %h.", resp);
		$stop();
	end

//////////////////////////
//SENDING MOTORS OFF CMD//
//////////////////////////
	cmd = MTRS_OFF;
	data = 16'h5252;
	
	//sending and resetting command
	snd_cmd = 1;
	@(posedge clk) snd_cmd = 0;
	
	//Once response is ready, check the response value, and check the result of the command we sent
	@(posedge resp_rdy)
	if( resp == POS_ACK ) begin
		if( motors_off ) begin
			$display("Response and MOTORS_OFF successful.");
		end
		else begin
			$display("ERROR: Response sucessful, MOTORS_OFF incorrect.");
			$stop();	
		end
	end
	else begin
		$display("ERROR: Response incorrect. EXPECTED: 8'hA5 (POS_ACK). ACTUAL: %h.", resp);
		$stop();
	end

/////////////////////////
//SENDING CALIBRATE CMD//
/////////////////////////
	cmd = CALIBRATE;
	data = 16'h8789;
	
	//sending and resetting command
	snd_cmd = 1;
	@(posedge clk) snd_cmd = 0;

	@(negedge motors_off) $display("Motors on.");

	@(posedge strt_cal) $display("Start Cal.");

        /*while(strt_cal) begin
		if(!inertial_cal) begin
			$display( "Inertial_cal not asserted during strt_cal." );
		end
        end */	
		
	@(posedge clk); 
          cal_done = 1;

        @(posedge clk);
         // cal_done = 0;
          
	//Once response is ready, check the response value, and check the result of the command we sent
	@(posedge resp_rdy)
	if( resp == POS_ACK ) begin
		if( cal_done ) begin
			$display("Response and Calibration completed.");
		end
		else begin
			$display("ERROR: Response sucessful, Calibration incomplete.");
			$stop();	
		end
	end
	else begin
		$display("ERROR: Response incorrect. EXPECTED: 8'hA5 (POS_ACK). ACTUAL: %h.", resp);
		$stop();
	end

	$stop();

end

//////////////////
//Toggling clock//
//////////////////
always begin
	#5 clk = ~clk;
end

endmodule

