module DE0_NANO(
	CLOCK_50,
	GPIO_0_D,
	GPIO_0_IN,
	GPIO_1_D,
	GPIO_1_IN,
	KEY
);

	 //=======================================================
	 //  PARAMETER declarations
	 //=======================================================
localparam ONE_SEC = 25000000; // one second in 25MHz clock cycles
localparam MAX_ADDRESS = 21119; // MAx memory address in ram
	 
//=======================================================
//  PORT declarations
//=======================================================

//////////// CLOCK //////////
input 		          		CLOCK_50;

//////////// GPIO_0, GPIO_0 connect to GPIO Default //////////
output 		    [33:0]		GPIO_0_D;
input 		     [1:0]		GPIO_0_IN;
//////////// GPIO_0, GPIO_1 connect to GPIO Default //////////
input 		    [33:0]		GPIO_1_D;
input 		     [1:0]		GPIO_1_IN;
input 		     [1:0]		KEY;

//////////// M9K Module //////////
Dual_Port_RAM_M9K mem(
	.input_data(pixel_data_RGB332),
	.w_addr(WRITE_ADDRESS),
	.r_addr(READ_ADDRESS),
	.w_en((WRITE_STATE==W_EN) ? 1'b1 : 1'b0),
	.clk_W(CLOCK_25),
	.clk_R(CLOCK_25),
	.output_data(VGA_COLOR_IN)
	);
	
//////////// VGA Module //////////
VGA_DRIVER (
	.RESET(VGA_RESET),
	.CLOCK(CLOCK_25),
	.PIXEL_COLOR_IN(VGA_COLOR_IN),
	.PIXEL_X(VGA_PIXEL_X),
	.PIXEL_Y(VGA_PIXEL_Y),
	.PIXEL_COLOR_OUT(VGA_COLOR_OUT),
	.H_SYNC_NEG(VGA_HSYNC_NEG),
	.V_SYNC_NEG(VGA_VSYNC_NEG)
);
///// PIXEL DATA /////
reg [7:0]	pixel_data_RGB332;

///// READ/WRITE ADDRESS /////
reg [14:0] WRITE_ADDRESS = 15'd21119;
reg [14:0] READ_ADDRESS	 = 15'd21119;

///// VGA INPUTS/OUTPUTS /////
wire 			VGA_RESET;
wire [7:0]	VGA_COLOR_IN;
wire [9:0]	VGA_PIXEL_X;
wire [9:0]	VGA_PIXEL_Y;
wire [7:0]	VGA_COLOR_OUT;
wire			VGA_VSYNC_NEG;
wire			VGA_HSYNC_NEG;

assign VGA_RESET = ~KEY[0];
///// INPUTS FROM OV7670 /////
wire PCLK, HSYNC, VSYNC;

assign PCLK = GPIO_1_D[10];
assign HYSNC = GPIO_1_D[9];
assign VSYNC = GPIO_1_D[8];
assign GPIO_0_D[1] = PCLK;


/* counter distinguishes between which byte is 
	being input from camera, also used as write clock */
	parameter W_1 = 2'b00;
	parameter W_2 = 2'b01;
	parameter W_EN = 2'b10;
	reg [1:0] WRITE_STATE = W_1;
	
/* Store pixel data */
always @ (posedge PCLK) begin
	if(HSYNC == 1'b1) begin
		if(WRITE_STATE == W_EN) begin
			WRITE_STATE = W_1;
		end
		if(WRITE_STATE == W_1) begin
			pixel_data_RGB332[7] <= GPIO_1_D[7];
			pixel_data_RGB332[6] <= GPIO_1_D[5];
			pixel_data_RGB332[6] <= GPIO_1_D[3];
			pixel_data_RGB332[4] <= GPIO_1_D[4];
			pixel_data_RGB332[3] <= GPIO_1_D[0];
			pixel_data_RGB332[2] <= GPIO_1_D[2];
			WRITE_STATE <= W_2;
		end
		else if(WRITE_STATE == W_2) begin 
			pixel_data_RGB332[1] = GPIO_1_D[6];
			pixel_data_RGB332[0] = GPIO_1_D[1];
			WRITE_STATE = W_EN;
			WRITE_ADDRESS = (WRITE_ADDRESS+1)%(MAX_ADDRESS+1);
		end
	end
end


/* UPDATE READ ADDRESS */
always @ (posedge CLOCK_25) begin
	READ_ADDRESS = (READ_ADDRESS +1)%(MAX_ADDRESS+1);
	if(VGA_RESET)begin
		READ_ADDRESS = 15'd21119;
	end
end
///// 25 MHZ XCLK ///////
reg CLOCK_25;
assign GPIO_0_D[0] = CLOCK_25;

always @ (posedge CLOCK_50) begin
  CLOCK_25 <= ~CLOCK_25;
end 




//
//localparam CLKDIVIDER_700 = 25000000/9000/2;
//reg square_700;
//assign GPIO_0_D[0] = square_700;
//assign GPIO_0_D[1] = 1'b1;
//reg [15:0] counter;
//
//always @ (posedge CLOCK_25) 
//begin
//  if (counter == 0 ) 
//  begin
//    counter <= CLKDIVIDER_700-1;
//	 square_700 <= ~square_700;
//  end
//  else begin
//    counter <= counter -1;
//	 square_700 <= square_700;
//  end
//end

	
endmodule 