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
assign PCLK = GPIO_1_D[25];
assign HYSNC = GPIO_1_D[24];
assign VSYNC = GPIO_1_D[27];
assign GPIO_0_D[33] = pixel_data_RGB332[0];

/* States for write, control which half of pixeldata is being input
	to which part of the reg. Also, when to write*/
parameter W_1 = 2'b00;
parameter W_2 = 2'b01;
parameter W_EN = 2'b10;
reg [1:0] WRITE_STATE = W_1;

///// 25 MHz Clock /////
reg CLOCK_25;
	
//////////// M9K Module //////////
Dual_Port_RAM_M9K mem(
	.input_data(pixel_data_RGB332),
	.w_addr(WRITE_ADDRESS),
	.r_addr(READ_ADDRESS),
	.w_en((WRITE_STATE==W_EN) ? 1'b1 : 1'b0),
	.clk_W(CLOCK_50),
	.clk_R(CLOCK_25),
	.output_data(VGA_COLOR_IN)
);
	
//////////// VGA Module //////////
VGA_DRIVER driver (
	.RESET(VGA_RESET),
	.CLOCK(CLOCK_25),
	.PIXEL_COLOR_IN(VGA_COLOR_IN),
	.PIXEL_X(VGA_PIXEL_X),
	.PIXEL_Y(VGA_PIXEL_Y),
	.PIXEL_COLOR_OUT({GPIO_0_D[9],GPIO_0_D[11],GPIO_0_D[13],GPIO_0_D[15],GPIO_0_D[17],GPIO_0_D[19],GPIO_0_D[21],GPIO_0_D[23]}),
   .H_SYNC_NEG(GPIO_0_D[7]),
   .V_SYNC_NEG(GPIO_0_D[5])
);


/* Store pixel data */
always @ (posedge PCLK) begin
	if(HSYNC == 1'b1) begin
		if(WRITE_STATE == W_EN) begin
			WRITE_STATE = W_1;
		end
		if(WRITE_STATE == W_1) begin
			pixel_data_RGB332[7] <= GPIO_1_D[26];
			pixel_data_RGB332[6] <= GPIO_1_D[27];
			pixel_data_RGB332[5] <= GPIO_1_D[28];
			pixel_data_RGB332[4] <= GPIO_1_D[29];
			pixel_data_RGB332[3] <= GPIO_1_D[30];
			pixel_data_RGB332[2] <= GPIO_1_D[31];
			WRITE_STATE <= W_2;
		end
		else if(WRITE_STATE == W_2) begin 
			pixel_data_RGB332[1] = GPIO_1_D[32];
			pixel_data_RGB332[0] = GPIO_1_D[33];
			WRITE_STATE = W_EN;
			WRITE_ADDRESS = (WRITE_ADDRESS+1)%(MAX_ADDRESS+1);
		end
	end
end

//reg [7:0] test_colour;
//reg [27:0]counter;
//reg[1:0] colour_state;
/* UPDATE READ ADDRESS */
always @ (posedge CLOCK_25) begin
	READ_ADDRESS = (READ_ADDRESS +1)%(MAX_ADDRESS+1);
	if(VGA_RESET)begin
		READ_ADDRESS = 15'd21119;
	end
	/*
	counter = counter + 1;
	if(counter == ONE_SEC)begin
		counter = 28'd0;
		colour_state = (colour_state + 1)%3;
	end
	case(colour_state)
		2'b00: test_colour = 8'b111_000_00;
		2'b01: test_colour = 8'b000_111_00;
		2'b10: test_colour = 8'b000_000_11;
	endcase
	*/
end
///// 25 MHZ XCLK ///////
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