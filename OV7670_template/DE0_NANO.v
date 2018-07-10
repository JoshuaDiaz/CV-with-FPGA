module DE0_NANO(
	CLOCK_50,
	GPIO_0_D,
	GPIO_0_IN,
	GPIO_1_D,
	GPIO_1_IN,
);

	 //=======================================================
	 //  PARAMETER declarations
	 //=======================================================
localparam ONE_SEC = 25000000; // one second in 25MHz clock cycles
	 
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


///// PIXEL DATA /////
reg [7:0] pixel_data_input;
wire PCLK, HSYNC, VSYNC;

reg VSYNC_REG;

assign PCLK = GPIO_1_D[10];
assign HYSNC = GPIO_1_D[9];
assign VSYNC = GPIO_1_D[8];
assign GPIO_0_D[1] = VSYNC;

always @ (posedge PCLK) begin
	if(HSYNC == 1'b1) begin
		pixel_data_input[0] <= GPIO_1_D[2];
		pixel_data_input[1] <= GPIO_1_D[0];
		pixel_data_input[2] <= GPIO_1_D[4];
		pixel_data_input[3] <= GPIO_1_D[1];
		pixel_data_input[4] <= GPIO_1_D[6];
		pixel_data_input[5] <= GPIO_1_D[3];
		pixel_data_input[6] <= GPIO_1_D[5];
		pixel_data_input[7] <= GPIO_1_D[7];
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