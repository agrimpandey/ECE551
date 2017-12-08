module UART_wrapper( clk, rst_n, cmd_rdy, snd_resp,resp_sent, clr_cmd_rdy, cmd, data, resp, RX, TX);


input clk, rst_n, clr_cmd_rdy, snd_resp, RX;
output resp_sent;
output reg cmd_rdy;
output TX;

wire trmt;
wire [7:0] rx_data;
wire [7:0] tx_data;
wire rx_ready;
reg clr_rx_rdy;

reg data_high_set;
reg cmd_set;
reg set_cmd_rdy;
reg tx_done;

input [7:0] resp;

//outputs of UART_Wrapper
output reg [7:0] cmd;
output reg [15:0] data;

//flip flop that holds the high bits of the data
reg [7:0] data_high;

//Instantiating UART transiever
UART uart(.clk(clk),.rst_n(rst_n),.RX(RX),.TX(TX),.rx_rdy(rx_rdy),.clr_rx_rdy(clr_rx_rdy),.rx_data(rx_data),.trmt(trmt),.tx_data(tx_data),.tx_done(tx_done));

assign resp_sent = tx_done;
assign trmt = snd_resp;
assign tx_data = resp;

//low bits of data are direct output of rx_data
assign data [7:0] = rx_data;

//high bits of data are stored in the data_high flop
assign data [15:8] = data_high;

//Creating enumerated states
typedef enum reg [1:0] {IDLE,DATA1,DATA2} state_t;
state_t state,nxt_state;

//Handles state transitioning
always @(posedge clk, negedge rst_n)
	if(!rst_n) 
		state <= IDLE;
	else
		state<= nxt_state;

//Register holding data_high bits
always @(posedge clk, negedge rst_n) begin
	if(!rst_n)
		data_high <= 7'h00;
	else if(data_high_set)
		data_high <= rx_data;
	else 
		data_high <= data_high;
end

//Register holding cmd bits
always @(posedge clk, negedge rst_n) begin
	if(!rst_n)
		cmd <= 7'h00;
	else if(cmd_set)
		cmd <= rx_data;
	else 
		cmd <= cmd;
end

//State Machine
always @( state, rx_rdy ) begin

//Defaulting outputs
clr_rx_rdy = 1'b0;
data_high_set = 1'b0;
cmd_set = 1'b0;
set_cmd_rdy = 1'b0;
nxt_state = IDLE;

	case(state)
		IDLE: begin
			if(rx_rdy) begin
				clr_rx_rdy = 1'b1; //Reset rx ready value
				cmd_set = 1'b1;	//store rx_data in cmd register
				nxt_state = DATA1;
			end
			else
				nxt_state = IDLE;
		end
		DATA1: begin
			$display("IN DATA1 STATE");
			if(rx_rdy) begin
				clr_rx_rdy = 1'b1; //Reset rx ready value
				data_high_set = 1'b1; //store rx_data in data_high register
				nxt_state = DATA2;
			end
			else
				nxt_state = DATA1;
		end
		DATA2: begin
			if(rx_rdy) begin
				clr_rx_rdy = 1'b1; //Reset rx ready value
				set_cmd_rdy = 1'b1; //Since all data is available, set cmd_rdy
				nxt_state = IDLE;
			end
			else
				nxt_state = DATA2;
		end
		default: begin
			nxt_state = IDLE;
		end
	endcase
end

always_ff @(posedge clk, negedge rst_n) begin
	if(!rst_n)
		cmd_rdy <= 1'b0;
	else if(set_cmd_rdy)
		cmd_rdy <= 1'b1;
	else if(clr_cmd_rdy)
		cmd_rdy <= 1'b0; 
end

endmodule


