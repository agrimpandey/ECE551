module inert_intf(clk, rst_n, strt_cal, INT, cal_done, vld, ptch, roll, yaw, SS_n, SCLK, MOSI, MISO);

input clk, rst_n, strt_cal, INT, MISO;
output logic cal_done, vld;
output logic [15:0] ptch, roll, yaw;
output logic SCLK, SS_n, MOSI;

logic [15:0] cnt_16;
logic INT_FF1, INT_FF2;

// State machine variables
logic wrt;
logic [15:0] cmd;
logic [7:0] ptch_L, ptch_H, yaw_L, yaw_H, roll_L, roll_H, AX_H, AX_L, AY_H, AY_L;
logic done;

logic [15:0] ptch_rt, roll_rt, yaw_rt, ax, ay;
logic [15:0] rd_data;

// Flags for which register state machine will write to
logic C_P_H, C_P_L, C_R_H, C_R_L, C_Y_H, C_Y_L, C_AX_H, C_AX_L, C_AY_H, C_AY_L;

SPI_mstr16 SPI(.clk(clk), .rst_n(rst_n), .SS_n(SS_n), .SCLK(SCLK), .MOSI(MOSI), .MISO(MISO),
	       .wrt(wrt), .cmd(cmd), .done(done), .rd_data(rd_data));

inertial_integrator #(11) int1(.clk(clk), .rst_n(rst_n), .strt_cal(strt_cal), .cal_done(cal_done),
			 .vld(vld), .ptch_rt(ptch_rt), .roll_rt(roll_rt), .yaw_rt(yaw_rt),
                         .ax(ax), .ay(ay), .ptch(ptch), .roll(roll), .yaw(yaw));

// Double flopping INT for metastability
always_ff @(posedge clk, negedge rst_n) begin
  if(!rst_n) begin
    INT_FF1 <= 1'b0;
    INT_FF2 <= 1'b0;
  end
  else begin
    INT_FF1 <= INT;
    INT_FF2 <= INT_FF1;
  end
end

// 16 bit timer to account for inertial sensor reset sequence
always_ff @(posedge clk, negedge rst_n) begin
  if(!rst_n)       
    cnt_16 <= 16'h0000;
  else
    cnt_16 <= cnt_16 + 1;
end

// Get MSB of ptch
always_ff @(posedge clk, negedge rst_n) begin
  if(!rst_n)
    ptch_H <= 8'h00;
  else if (C_P_H)
    ptch_H <= rd_data[7:0];
end

// Get LSB of ptch
always_ff @(posedge clk, negedge rst_n) begin
  if(!rst_n)
    ptch_L <= 8'h00;
  else if (C_P_L)
    ptch_L <= rd_data[7:0];
end

// Get MSB of yaw
always_ff @(posedge clk, negedge rst_n) begin
  if(!rst_n)
    yaw_H <= 8'h00;
  else if (C_Y_H)
    yaw_H <= rd_data[7:0];
end

// Get LSB of yaw
always_ff @(posedge clk, negedge rst_n) begin
  if(!rst_n)
    yaw_L <= 8'h00;
  else if (C_Y_L)
    yaw_L <= rd_data[7:0];
end

// Get MSB of roll
always_ff @(posedge clk, negedge rst_n) begin
  if(!rst_n)
    roll_H <= 8'h00;
  else if (C_R_H)
    roll_H <= rd_data[7:0];
end

// Get LSB of roll
always_ff @(posedge clk, negedge rst_n) begin
  if(!rst_n)
    roll_L <= 8'h00;
  else if (C_R_L)
    roll_L <= rd_data[7:0];
end

// Get MSB of AX
always_ff @(posedge clk, negedge rst_n) begin
  if(!rst_n)
    AX_H <= 8'h00;
  else if (C_AX_H)
    AX_H <= rd_data[7:0];
end

// Get LSB of AX
always_ff @(posedge clk, negedge rst_n) begin
  if(!rst_n)
    AX_L <= 8'h00;
  else if (C_AX_L)
    AX_L <= rd_data[7:0];
end

// Get MSB of AY
always_ff @(posedge clk, negedge rst_n) begin
  if(!rst_n)
    AY_H <= 8'h00;
  else if (C_AY_H)
    AY_H <= rd_data[7:0];
end

// Get LSB of AY
always_ff @(posedge clk, negedge rst_n) begin
  if(!rst_n)
    AY_L <= 8'h00;
  else if (C_AY_L)
    AY_L <= rd_data[7:0];
end

assign ptch_rt = {ptch_H, ptch_L};
assign roll_rt = {roll_H, roll_L};
assign yaw_rt = {yaw_H, yaw_L};
assign ax = {AX_H, AX_L};
assign ay = {AY_H, AY_L};


// STATE MACHINE IMPLEMENTATION //
typedef enum reg [5:0] {SETUP1, SETUP2, SETUP3, SETUP4, SETUP5, WAIT, ptchL, ptchH, 
			rollL, rollH, yawL, yawH, AXL, AXH, AYL, AYH} state_t;
state_t state, next_state;

always_ff @(posedge clk, negedge rst_n) begin
  if (!rst_n)
    state <= SETUP1;
  else
    state <= next_state;
end

always_comb begin
  // Default values
  vld = 0;
  wrt = 0;
  cmd = 16'h0000;
  C_P_H = 1'b0;
  C_P_L = 1'b0;
  C_R_H = 1'b0;
  C_R_L = 1'b0;
  C_Y_H = 1'b0;
  C_Y_L = 1'b0;
  C_AX_H = 1'b0;
  C_AX_L = 1'b0;
  C_AY_H = 1'b0;
  C_AY_L = 1'b0;
  next_state = SETUP1;

  case(state)
    SETUP1: begin
      if(&cnt_16) begin
	next_state = SETUP2;
	cmd = 16'h0D02;
	wrt = 1'b1;
      end
      else
	next_state = SETUP1;
    end

    SETUP2: begin
      if(done) begin
	next_state = SETUP3;
	cmd = 16'h1062;
	wrt = 1'b1;
      end
      else
	next_state = SETUP2;
    end

    SETUP3: begin
      if(done) begin
	next_state = SETUP4;
	cmd = 16'h1162;
	wrt = 1'b1;
      end
      else
	next_state = SETUP3;
    end

    SETUP4: begin
      if(done) begin
	next_state = SETUP5;
	cmd = 16'h1460;
	wrt = 1'b1;
      end
      else
	next_state = SETUP4;
    end

    SETUP5: begin
      if(done) begin
        next_state = WAIT;
      end
      else 
        next_state = SETUP5;  
    end

    WAIT : begin
      if(INT_FF2) begin
	next_state = ptchL;
	cmd = 16'hA2xx;
	wrt = 1'b1;
      end
      else
	next_state = WAIT;
    end

    ptchL: begin
      if(done) begin
	next_state = ptchH;
	cmd = 16'hA3xx;
	wrt = 1'b1;
	C_P_L = 1'b1;
      end
      else
	next_state = ptchL;
    end

    ptchH: begin
      if(done) begin
	next_state = rollL;
	cmd = 16'hA4xx;
	wrt = 1'b1;
	C_P_H = 1'b1;
      end
      else
	next_state = ptchH;
    end

    rollL: begin
      if(done) begin
	next_state = rollH;
	cmd = 16'hA5xx;
	wrt = 1'b1;
	C_R_L = 1'b1;
      end
      else
	next_state = rollL;
    end

    rollH: begin
      if(done) begin
	next_state = yawL;
	cmd = 16'hA6xx;
	wrt = 1'b1;
	C_R_H = 1'b1;
      end
      else
	next_state = rollH;
    end

    yawL: begin
      if(done) begin
	next_state = yawH;
	cmd = 16'hA7xx;
	wrt = 1'b1;
	C_Y_L = 1'b1;
      end
      else
	next_state = yawL;
    end

    yawH: begin
      if(done) begin
	next_state = AXL;
	cmd = 16'hA8xx;
	wrt = 1'b1;
	C_Y_H = 1'b1;
      end
      else
	next_state = yawH;
    end

    AXL: begin
      if(done) begin
	next_state = AXH;
	cmd = 16'hA9xx;
	wrt = 1'b1;
	C_AX_L = 1'b1;
      end
      else
	next_state = AXL;
    end

    AXH: begin
      if(done) begin
	next_state = AYL;
	cmd = 16'hAAxx;
	wrt = 1'b1;
	C_AX_H = 1'b1;
      end
      else
	next_state = AXH;
    end

    AYL: begin
      if(done) begin
	next_state = AYH;
	cmd = 16'hABxx;
	wrt = 1'b1;
	C_AY_L = 1'b1;
      end
      else
	next_state = AYL;
    end

    AYH: begin
      if(done) begin
	next_state = WAIT;
	vld = 1'b1;
	C_AY_H = 1'b1;
      end
      else
	next_state = AYH;
    end

  endcase

end

endmodule
