
module QuadCopter_tb();
			
//// Interconnects to DUT/support defined as type wire /////
wire SS_n,SCLK,MOSI,MISO,INT;
wire SS_A2D_n,SCLK_A2D,MOSI_A2D,MISO_A2D;
wire RX,TX;
wire [7:0] resp;				// response from DUT
wire cmd_sent,resp_rdy;
wire frnt_ESC, back_ESC, left_ESC, rght_ESC;

////// Stimulus is declared as type reg ///////
reg clk, RST_n;
reg [7:0] cmd_to_copter;		// command to Copter via wireless link
reg [15:0] data;				// data associated with command
reg send_cmd;					// asserted to initiate sending of command (to your CommMaster)
reg clr_resp_rdy;				// asserted to knock down resp_rdy
reg [7:0] thrst;
reg [15:0] d_ptch;
reg [15:0] d_roll;
reg [15:0] d_yaw;

/////// declare any localparams here /////

localparam REQ_BATT = 8'h01;
localparam SET_PTCH = 8'h02;
localparam SET_ROLL = 8'h03;
localparam SET_YAW = 8'h04;
localparam SET_THRST = 8'h05;
localparam EMER_LAND = 8'h08;
localparam MTRS_OFF = 8'h07;
localparam CALIBRATE = 8'h06;

localparam POS_ACK = 8'hA5;


//Arbitrary Desired values
localparam DES_PTCH = 8'h90;
localparam DES_ROLL = 8'h61;
localparam DES_YAW = 8'h3B;

//Tests if thrst, d_ptch, d_roll, d_yaw are all 0. Used in emer. landing
reg equal_to_zero;

////////////////////////////////////////////////////////////////
// Instantiate Physical Model of Copter with Inertial sensor //
//////////////////////////////////////////////////////////////	
CycloneIV iQuad(.SS_n(SS_n),.SCLK(SCLK),.MISO(MISO),.MOSI(MOSI),.INT(INT),
                .frnt_ESC(frnt_ESC),.back_ESC(back_ESC),.left_ESC(left_ESC),
				.rght_ESC(rght_ESC));				  

///////////////////////////////////////////////////
// Instantiate Model of A2D for battery voltage //
/////////////////////////////////////////////////
ADC128S iA2D(.clk(clk),.rst_n(RST_n),.SS_n(SS_A2D_n),.SCLK(SCLK_A2D),
             .MISO(MISO_A2D),.MOSI(MOSI_A2D));			
	 
////// Instantiate DUT ////////
QuadCopter iDUT(.clk(clk),.RST_n(RST_n),.SS_n(SS_n),.SCLK(SCLK),.MOSI(MOSI),.MISO(MISO),
                .INT(INT),.RX(RX),.TX(TX),.LED(),.FRNT(frnt_ESC),.BCK(back_ESC),
				.LFT(left_ESC),.RGHT(rght_ESC),.SS_A2D_n(SS_A2D_n),.SCLK_A2D(SCLK_A2D),
				.MOSI_A2D(MOSI_A2D),.MISO_A2D(MISO_A2D));


//// Instantiate Master UART (used to send commands to Copter) //////
CommMaster iMSTR(.clk(clk), .rst_n(RST_n), .RX(TX), .TX(RX),
                 .cmd(cmd_to_copter), .data(data), .send_cmd(send_cmd),
			     .cmd_sent(cmd_sent), .resp_rdy(resp_rdy),
				 .resp(resp), .clr_resp_rdy(clr_resp_rdy));

initial begin

	//Initialzing DUT by reset
	clk = 1'b0;
	RST_n = 1'b0;
	@(posedge clk) RST_n = 1'b1;

///////////////////////
//SENDING BATTERY CMD//
///////////////////////
	cmd_to_copter = REQ_BATT;
	data = 16'h0000; //data sent is garbage
	
	//toggle send_cmd
	@(posedge clk) send_cmd = 1;
	@(posedge clk) send_cmd = 0;

	//Once response is ready, check the response value, and check that the resulting battery voltage is non-zero
	@(posedge resp_rdy);
	if( resp != 8'h00 ) begin //checks to make sure Battery is a non-zero value (should really be 0xc0)
		$display("Battery CMD successful. BATT = %h", resp);
	end
	else begin
		$display("ERROR: Battery CMD failed. EXPECTED: Something non-zero. ACTUAL: %h.", resp);
		$stop();
	end

/////////////////////////
//SENDING CALIBRATE CMD//
/////////////////////////
	cmd_to_copter = CALIBRATE;
	data = 16'h8789; //data sent is garbage
	
	//toggle send_cmd
	@(posedge clk) send_cmd = 1;
	@(posedge clk) send_cmd = 0;
          
	//Once response is ready, check the response value
	//Just assuming if the response is correct that the calibration is correct
	@(posedge resp_rdy)
	if( resp == POS_ACK ) begin
		$display("Response from Calibration received successfully."); 
	end
	else begin
		$display("ERROR: Response incorrect. EXPECTED: 8'hA5 (POS_ACK). ACTUAL: %h.", resp);
		$stop();
	end

/////////////////////////
//SENDING SET THRST CMD//
/////////////////////////
	cmd_to_copter = SET_THRST;
	data = 16'h0080;
	
	//toggle send_cmd
	@(posedge clk) send_cmd = 1;
	@(posedge clk) send_cmd = 0;
	
	//Once response is ready, check the response value, and check the result of the command we sent
	@(posedge resp_rdy)
	if( resp == POS_ACK ) begin

		$display("SET THRST #1 Response was %h.", resp);
		if(iDUT.iCMD.thrst == data) begin
			$display("SET THRST Command Successful");
		end
		else begin
			$display("ERROR: SET THRST Command Unsuccessful. EXPECTED: %h, ACTUAL: %h", data, iDUT.iCMD.thrst);
			$stop();
		end
	end
	else begin
		$display("ERROR: Response incorrect. EXPECTED: 8'hA5 (POS_ACK). ACTUAL: %h.", resp);
		$stop();
	end

	//wait 5 ESC pulses for Copter to get off the ground, before we try to write to ptch, roll, or yaw
	repeat(5) begin
		@(negedge frnt_ESC);
	end
	
//Now that the Quadcopter is airborne, let's set some desired ptch, roll, and yaw  values, and hopefully they converge to those values
/////////////////////////
//SENDING SET PTCH CMD//
/////////////////////////
	cmd_to_copter = SET_PTCH;
	data = DES_PTCH;
	
	//sending and resetting command
	@(posedge clk) send_cmd = 1;
	@(posedge clk) send_cmd = 0;
	
	//Once response is ready, check the response value, and check the result of the command we sent
	@(posedge resp_rdy)
	if( resp == POS_ACK ) begin
		
		$display("SET PTCH Response was %h.", resp);
		if(iDUT.iCMD.d_ptch == data) begin
			$display("SET PTCH Command Successful");
		end
		else begin
			$display("ERROR: SET PTCH Command Unsuccessful. EXPECTED: %h, ACTUAL: %h", data, iDUT.iCMD.d_ptch);
			$stop();
		end

		
	end
	else begin
		$display("ERROR: Response incorrect. EXPECTED: 8'hA5 (POS_ACK). ACTUAL: %h.", resp);
		$stop();
	end
	
	
	
/////////////////////////
//SENDING SET ROLL CMD//
/////////////////////////
	cmd_to_copter = SET_ROLL;
	data = DES_ROLL;
	
	//sending and resetting command
	@(posedge clk) send_cmd = 1;
	@(posedge clk) send_cmd = 0;
	
	//Once response is ready, check the response value, and check the result of the command we sent
	@(posedge resp_rdy)
	if( resp == POS_ACK ) begin

		$display("SET ROLL Response was %h.", resp);

		if(iDUT.iCMD.d_roll == data) begin
			$display("SET ROLL Command Successful");
		end
		else begin
			$display("ERROR: SET ROLL Command Unsuccessful. EXPECTED: %h, ACTUAL: %h", data, iDUT.iCMD.d_roll);
			$stop();
		end
		
	end
	else begin
		$display("ERROR: Response incorrect. EXPECTED: 8'hA5 (POS_ACK). ACTUAL: %h.", resp);
		$stop();
	end
	
/////////////////////////
//SENDING SET YAW CMD//
/////////////////////////
	cmd_to_copter = SET_YAW;
	data = DES_YAW;
	
	//sending and resetting command
	@(posedge clk) send_cmd = 1;
	@(posedge clk) send_cmd = 0;
	
	//Once response is ready, check the response value, and check the result of the command we sent
	@(posedge resp_rdy)
	if( resp == POS_ACK ) begin

		$display("SET YAW Response was %h.", resp);
		if(iDUT.iCMD.d_yaw == data) begin
			$display("SET YAW Command Successful");
		end
		else begin
			$display("ERROR: SET YAW Command Unsuccessful. EXPECTED: %h, ACTUAL: %h", data, iDUT.iCMD.d_yaw);
			$stop();
		end
		
	end
	else begin
		$display("ERROR: Response incorrect. EXPECTED: 8'hA5 (POS_ACK). ACTUAL: %h.", resp);
		$stop();
	end
	
	//Sit in this repeat loop waiting for ESC pulses to test convergence to desired values for PTCH, ROLL, YAW 
	repeat(100) begin
		@(negedge frnt_ESC);
	end
	$display("Check wave. d_ptch should be around %h. \n d_roll should be around %h. \n d_yaw should be around %h.", DES_PTCH,DES_ROLL,DES_YAW);

	$stop();

	
//We are sending another round of setting ptch, roll, and yaw values in order to test convergence back to 0

/////////////////////////
//SENDING SET PTCH CMD//
/////////////////////////
	cmd_to_copter = SET_PTCH;
	data = 0;
	
	//sending and resetting command
	@(posedge clk) send_cmd = 1;
	@(posedge clk) send_cmd = 0;
	
	//Once response is ready, check the response value, and check the result of the command we sent
	@(posedge resp_rdy)
	if( resp == POS_ACK ) begin
		
		$display("SET PTCH Response was %h.", resp);
		if(iDUT.iCMD.d_ptch == data) begin
			$display("SET PTCH Command Successful");
		end
		else begin
			$display("ERROR: SET PTCH Command Unsuccessful. EXPECTED: %h, ACTUAL: %h", data, iDUT.iCMD.d_ptch);
			$stop();
		end

	end
	else begin
		$display("ERROR: Response incorrect. EXPECTED: 8'hA5 (POS_ACK). ACTUAL: %h.", resp);
		$stop();
	end
	
	
	
/////////////////////////
//SENDING SET ROLL CMD//
/////////////////////////
	cmd_to_copter = SET_ROLL;
	data = 0;
	
	//sending and resetting command
	@(posedge clk) send_cmd = 1;
	@(posedge clk) send_cmd = 0;
	
	//Once response is ready, check the response value, and check the result of the command we sent
	@(posedge resp_rdy)
	if( resp == POS_ACK ) begin

		$display("SET ROLL Response was %h.", resp);

		if(iDUT.iCMD.d_roll == data) begin
			$display("SET ROLL Command Successful");
		end
		else begin
			$display("ERROR: SET ROLL Command Unsuccessful. EXPECTED: %h, ACTUAL: %h", data, iDUT.iCMD.d_roll);
			$stop();
		end
		
	end
	else begin
		$display("ERROR: Response incorrect. EXPECTED: 8'hA5 (POS_ACK). ACTUAL: %h.", resp);
		$stop();
	end
	
/////////////////////////
//SENDING SET YAW CMD//
/////////////////////////
	cmd_to_copter = SET_YAW;
	data = 0;
	
	//sending and resetting command
	@(posedge clk) send_cmd = 1;
	@(posedge clk) send_cmd = 0;
	
	//Once response is ready, check the response value, and check the result of the command we sent
	@(posedge resp_rdy)
	if( resp == POS_ACK ) begin

		$display("SET YAW Response was %h.", resp);
		if(iDUT.iCMD.d_yaw == data) begin
			$display("SET YAW Command Successful");
		end
		else begin
			$display("ERROR: SET YAW Command Unsuccessful. EXPECTED: %h, ACTUAL: %h", data, iDUT.iCMD.d_yaw);
			$stop();
		end
		
	end
	else begin
		$display("ERROR: Response incorrect. EXPECTED: 8'hA5 (POS_ACK). ACTUAL: %h.", resp);
		$stop();
	end
	
	//Sit in this repeat loop waiting for ESC pulses to test convergence to desired values for PTCH, ROLL, YAW 
	repeat(100) begin
		@(negedge frnt_ESC);
	end
	$display("Check wave. d_ptch should be around %h. \n d_roll should be around %h. \n d_yaw should be around %h.", 0,0,0);

	$stop();
	
//We are sending an Emergency land command to test if the emergency land command turns off the motors
	
//////////////////////////////
//SENDING EMERGENCY LAND CMD//
//////////////////////////////
        
	cmd_to_copter = EMER_LAND;
	data = 16'h0000;
	
	//sending and resetting command
        send_cmd = 1;
	@(posedge clk) send_cmd = 0;
	
	assign equal_to_zero = ((iDUT.iCMD.thrst == 0) && (iDUT.iCMD.d_ptch == 0) && (iDUT.iCMD.d_roll == 0) && (iDUT.iCMD.d_yaw == 0));
	
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

//We are sending a motors off command to prevent the motors from turning back on until calibrated again

//////////////////////////
//SENDING MOTORS OFF CMD//
//////////////////////////
	cmd_to_copter = MTRS_OFF;
	data = 16'h5252;
	
         //sending and resetting command
	@(posedge clk) send_cmd = 1;
	@(posedge clk) send_cmd = 0;
	
	//Once response is ready, check the response value, and check the result of the command we sent
	@(posedge resp_rdy)
	if( resp == POS_ACK ) begin
		if( iDUT.iCMD.motors_off ) begin
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
	

//Here we are sending another thrust command to test how well our motors off command works. If correct, 
// the thrst should not change the ESC pulses and the quadcopter should crash.

	cmd_to_copter = SET_THRST;
	data = 16'h0FFF;
	
	//sending and resetting command
	@(posedge clk) send_cmd = 1;
	@(posedge clk) send_cmd = 0;
	
	//Once response is ready, check the response value, and check the result of the command we sent
	@(posedge resp_rdy)
	if( resp == POS_ACK ) begin
		
		$display("SET THRST #2 Response was %h.", resp);
	
		if(iDUT.iCMD.thrst == 9'h1FF) begin
			$display("SET THRST #2 Command Successful");
		end
		else begin
			$display("ERROR: SET THRST Command Unsuccessful. EXPECTED: %h, ACTUAL: %h", data, iDUT.iCMD.thrst);
			$stop();
		end
		
	end
	else begin
		$display("ERROR: Response incorrect. EXPECTED: 8'hA5 (POS_ACK). ACTUAL: %h.", resp);
		$stop();
	end

	//repeat for a long time to see if the Copter crashes
	repeat(100) begin
		@(negedge frnt_ESC);
	end

	$stop();

end


always
  #10 clk = ~clk;

//include "tb_tasks.v"	// maybe have a separate file with tasks to help with testing

endmodule

