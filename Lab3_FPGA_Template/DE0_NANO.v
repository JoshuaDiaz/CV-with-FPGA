`define SCREEN_WIDTH 176
`define SCREEN_HEIGHT 144

module DE0_NANO(
	CLOCK_50,
	GPIO_0_D,
	GPIO_1_D,
	KEY
);

//=======================================================
//  PARAMETER declarations
//=======================================================
localparam RED = 8'b111_000_00;
localparam GREEN = 8'b000_111_00;
localparam BLUE = 8'b000_000_11;

//=======================================================
//  PORT declarations
//=======================================================

//////////// CLOCK //////////
input 		          		CLOCK_50;

//////////// GPIO_0, GPIO_0 connect to GPIO Default //////////
output 		    [33:0]		GPIO_0_D;
//////////// GPIO_0, GPIO_1 connect to GPIO Default //////////
input 		    [33:0]		GPIO_1_D;
input 		     [1:0]		KEY;


///// VGA INPUTS/OUTPUTS /////
wire 			VGA_RESET;
reg 			VGA_READ_MEM_EN;
wire [7:0]	VGA_COLOR_IN;
wire [9:0]	VGA_PIXEL_X;
wire [9:0]	VGA_PIXEL_Y;
wire			VGA_HSYNC_NEG;
wire			VGA_VSYNC_NEG;



///// M9K RAM INPUTS/OUTPUTS /////

reg [14:0]	MEM_WRITE_ADDRESS;
reg [14:0]	MEM_READ_ADDRESS;
wire			W_EN;
wire [7:0]	MEM_OUTPUT;


///// INPUTS FROM OV7670 ///// 
/** TODO: INPUTS FROM CAM **/



///// PLL /////
/** TODO: INSTANTIATE PLL **/
	
	
	
///////* M9K Module *///////
Dual_Port_RAM_M9K mem(
	.input_data(/**TODO**/),
	.w_addr(MEM_WRITE_ADDRESS),
	.r_addr(MEM_READ_ADDRESS),
	.w_en(W_EN),
	.clk_W(/**TODO**/),
	.clk_R(/**TODO**/),
	.output_data(MEM_OUTPUT)
);
	
///////* VGA Module *///////
VGA_DRIVER driver (
	.RESET(VGA_RESET),
	.CLOCK(/**TODO**/),
	.PIXEL_COLOR_IN(VGA_READ_MEM_EN ? VGA_COLOR_IN : BLUE),
	.PIXEL_X(VGA_PIXEL_X),
	.PIXEL_Y(VGA_PIXEL_Y),
	.PIXEL_COLOR_OUT({GPIO_0_D[9],GPIO_0_D[11],GPIO_0_D[13],GPIO_0_D[15],GPIO_0_D[17],GPIO_0_D[19],GPIO_0_D[21],GPIO_0_D[23]}),
   .H_SYNC_NEG(VGA_HSYNC_NEG),
   .V_SYNC_NEG(VGA_VSYNC_NEG)
);
assign GPIO_0_D[7] = VGA_HSYNC_NEG;
assign GPIO_0_D[5] = VGA_VSYNC_NEG;

///////* Image Processor *///////
IMAGE_PROCESSOR proc(
	
);

//////* Storing Pixel Data *///////
/* TODO: STORE PIXEL DATA INPUT */



///////* Update Read Address *///////
always @ (VGA_PIXEL_X, VGA_PIXEL_Y) begin
		MEM_READ_ADDRESS <= (VGA_PIXEL_X + VGA_PIXEL_Y*`SCREEN_WIDTH);
		if(VGA_PIXEL_X>(`SCREEN_WIDTH-1) || VGA_PIXEL_Y>(`SCREEN_HEIGHT-1))begin
				VGA_READ_MEM_EN <= 1'b0;
		end
		else begin
				VGA_READ_MEM_EN <= 1'b1;
		end
end

	
endmodule 