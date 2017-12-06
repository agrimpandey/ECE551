module inert_intf_tb();


reg clk, rst_n;
reg [10:0]frnt_spd;
reg [10:0]bck_spd;
reg [10:0]lft_spd;
reg [10:0]rght_spd;
reg motors_off; 
reg strt_cal;

wire INT;
wire vld;
wire cal_done;
wire frnt, lft, bck, rght;
wire signed [15:0] ptch, roll, yaw;
wire SS_n;
wire MISO;
wire MOSI;
wire SCLK;

parameter MIN_RUN_SPEED = 13'h0200;


//instantiate inert_intf
inert_intf iDUTinert(.clk(clk), .rst_n(rst_n), .strt_cal(strt_cal), .INT(INT), .cal_done(cal_done), .vld(vld), .ptch(ptch), .roll(roll), .yaw(yaw), .SS_n(SS_n), .SCLK(SCLK), .MOSI(MOSI), .MISO(MISO));

//instantiate CycloneIV
CycloneIV iDUTcyclone(.SS_n(SS_n), .SCLK(SCLK), .MISO(MISO), .MOSI(MOSI), .INT(INT), .frnt_ESC(frnt), .back_ESC(bck), .left_ESC(lft), .rght_ESC(rght)); 

//instantiate ESCs
ESCs iDUTesc(.clk(clk), .rst_n(rst_n), .frnt_spd(frnt_spd), .bck_spd(bck_spd), .lft_spd(lft_spd), .rght_spd(rght_spd), .motors_off(motors_off), .frnt(frnt), .bck(bck), .lft(lft), .rght(rght));


initial begin

        //set motor speeds
	//lft_spd = MIN_RUN_SPEED;
	clk =0;
	rst_n= 0;
	frnt_spd = MIN_RUN_SPEED;
        bck_spd = MIN_RUN_SPEED;
        lft_spd = MIN_RUN_SPEED;
        rght_spd = MIN_RUN_SPEED;
	strt_cal = 0;
        motors_off = 1;

        repeat(10)
	@(negedge clk);
        motors_off = 0;
	rst_n =1;
	
        @(negedge clk);
        strt_cal = 1; 

	@(posedge clk);
	strt_cal = 0;  
       
        //repeat(10) @(posedge vld);

	@(posedge cal_done);

        if(cal_done == 1) 
           $display("Success");
           

	//assert start_cal

	//wait until cal_done 

	//repeat(5) @(posedge vld);

		//look at pitch, roll, yaw in the waveform 

	$stop;
end

always
#10 clk = ~clk;






endmodule