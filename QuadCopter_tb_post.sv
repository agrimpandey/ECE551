`timescale 1ns/1ps
module QuadCopter_tb_post();
			
//// Interconnects to DUT/support defined as type wire /////
wire SS_n, SCLK, MOSI, MISO, INT;
wire SS_A2D_n, SCLK_A2D, MOSI_A2D, MISO_A2D;
wire RX, TX;
wire [7:0] resp;	  // response from DUT
wire cmd_sent, resp_rdy;
wire frnt_ESC, back_ESC, left_ESC, rght_ESC;

////// Stimulus is declared as type reg ///////
reg clk, RST_n;
reg [7:0] cmd_to_copter;  // command to Copter via wireless link
reg [15:0] data;	  // data associated with command
reg send_cmd;		  // asserted to initiate sending of command (to your CommMaster)
reg clr_resp_rdy;      	  // asserted to knock down resp_rdy
reg [7:0] thrst;
reg [15:0] d_ptch;
reg [15:0] d_roll;
reg [15:0] d_yaw;

/////// declare any localparams here /////

localparam REQ_BATT = 8'h01;

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

	clk = 1'b0;
	RST_n = 1'b0;

	// Ensure all inputs to DUT are either 0 or 1 before reset deaserts
	cmd_to_copter = 8'b0; data = 16'b0; send_cmd = 0; clr_resp_rdy = 0;
	thrst = 8'b0; d_ptch = 16'b0; d_roll = 16'b0; d_yaw = 16'b0;

	@(posedge clk);
	@(negedge clk);
 	RST_n = 1'b1;

	///////////////////////
	//SENDING BATTERY CMD//
	///////////////////////
	cmd_to_copter = REQ_BATT;
	data = 16'h0000;
	
	@(posedge clk) send_cmd = 1;
	@(posedge clk) send_cmd = 0;

	// Once response is ready, check the response value, and check that the resulting battery voltage is non-zero
	@(posedge resp_rdy);
	if( resp != 8'h00 ) begin
		$display("Battery CMD successful. BATT = %h", resp);
	end
	else begin
		$display("ERROR: Battery CMD failed. EXPECTED: Something non-zero. ACTUAL: %h.", resp);
		$stop();
	end
        $stop();

end

always
  #1.5 clk = ~clk;

endmodule
