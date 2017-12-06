module flght_cntrl_chk_tb();

reg [107:0] stim;
wire [43:0] resp; 
reg clk;
reg [9:0] i;

reg [107:0] stim_mem[0:999];
reg [43:0]  resp_mem[0:999];

// instantiate iDUT //
flght_cntrl iDUT(.clk(clk),.rst_n(stim[107]),.vld(stim[106]),.d_ptch(stim[104:89]),.d_roll(stim[88:73]),
                  .d_yaw(stim[72:57]),.ptch(stim[56:41]),.roll(stim[40:25]),.yaw(stim[24:9]),.thrst(stim[8:0]),
                   .inertial_cal(stim[105]),.frnt_spd(resp[43:33]),.bck_spd(resp[32:22]),
				   .lft_spd(resp[21:11]),.rght_spd(resp[10:0]));


initial begin
   clk = 0;
   // read memh to add values to the memory vector
   $readmemh("flght_cntrl_stim.hex", stim_mem, 0, 999);
   $readmemh("flght_cntrl_resp.hex", resp_mem, 0, 999);

   // go over all the 1000 vectors
   for(i = 0; i < 1000; i = i + 1) begin
       stim = stim_mem[i];
      //#6;
      @ (posedge clk);
	#1;
      if(resp_mem[i] === resp)
         $display("%d: Success", i);
      else begin
         $display("%d: Error", i);
         $display("%h : Actual, %h: Expected", resp, resp_mem[i]);
      end
      
   end
$stop;
end




always
  #5 clk = ~clk;
	 
endmodule
