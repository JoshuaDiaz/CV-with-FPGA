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
input 		    [33:20]		GPIO_1_D;
input 		     [1:0]		KEY;

///// PIXEL DATA /////
reg [7:0]	pixel_data_RGB332 = 8'd0;

///// READ/WRITE ADDRESS /////
reg [14:0] X_ADDR;
reg [14:0] Y_ADDR;
wire [14:0] WRITE_ADDRESS;
reg [14:0] READ_ADDRESS; 

assign WRITE_ADDRESS = X_ADDR + Y_ADDR*(`SCREEN_WIDTH);

///// VGA INPUTS/OUTPUTS /////
wire 			VGA_RESET;
wire [7:0]	VGA_COLOR_IN;
wire [9:0]	VGA_PIXEL_X;
wire [9:0]	VGA_PIXEL_Y;
wire [7:0]	MEM_OUTPUT;
wire			VGA_VSYNC_NEG;
wire			VGA_HSYNC_NEG;
reg			VGA_READ_MEM_EN;

assign GPIO_0_D[5] = VGA_VSYNC_NEG;
assign VGA_RESET = ~KEY[0];

///// INPUTS FROM OV7670 /////
wire PCLK_CAM;
wire HREF_CAM; 
wire VSYNC_CAM;
assign PCLK_CAM = GPIO_1_D[32];
assign VSYNC_CAM = GPIO_1_D[30];
assign HREF_CAM = GPIO_1_D[33];

///// I/O for Img Proc /////
wire [8:0] RESULT;

/* WRITE ENABLE */
reg W_EN;

///// 24/25 MHz Clock Phased Locked /////
wire CLK_25_PLL;
wire CLK_24_PLL;
wire CLK_50_PLL;
assign GPIO_0_D[0] = CLK_24_PLL;
assign GPIO_0_D[1] = CLK_24_PLL;
	
PLL	PLL_inst (
	.inclk0 ( CLOCK_50 ),
	.c0 ( CLK_24_PLL ),
	.c1 ( CLK_25_PLL ),
	.c2 ( CLK_50_PLL )
	);
	
///////* M9K Module *///////
Dual_Port_RAM_M9K mem(
	.input_data(pixel_data_RGB332),
	.w_addr(WRITE_ADDRESS),
	.r_addr(READ_ADDRESS),
	.w_en(W_EN),
	.clk_W(CLK_50_PLL),
	.clk_R(CLK_25_PLL), // DO WE NEED TO READ SLOWER THAN WRITE??
	.output_data(MEM_OUTPUT)
);
	
///////* VGA Module *///////
VGA_DRIVER driver (
	.RESET(VGA_RESET),
	.CLOCK(CLK_25_PLL),
	.PIXEL_COLOR_IN(VGA_READ_MEM_EN ? MEM_OUTPUT : BLUE),
	.PIXEL_X(VGA_PIXEL_X),
	.PIXEL_Y(VGA_PIXEL_Y),
	.PIXEL_COLOR_OUT({GPIO_0_D[9],GPIO_0_D[11],GPIO_0_D[13],GPIO_0_D[15],GPIO_0_D[17],GPIO_0_D[19],GPIO_0_D[21],GPIO_0_D[23]}),
   .H_SYNC_NEG(GPIO_0_D[7]),
   .V_SYNC_NEG(VGA_VSYNC_NEG)
);

///////* Image Processor *///////
IMAGE_PROCESSOR proc(
	.PIXEL_IN(MEM_OUTPUT),
	.CLK(CLK_25_PLL),
	.VGA_PIXEL_X(VGA_PIXEL_X),
	.VGA_PIXEL_Y(VGA_PIXEL_Y),
	.VGA_VSYNC_NEG(VGA_VSYNC_NEG),
	.RESULT(RESULT)
);

//////* Storing Pixel Data *///////

wire [7:0] data;
assign data = {GPIO_1_D[27:25], GPIO_1_D[22:20], GPIO_1_D[24:23]};

reg last_href;
reg is_lsb = 1'b0;
always@( posedge PCLK_CAM )begin
		if(VSYNC_CAM == 1'b1 && HREF_CAM == 1'b0 && last_href == 1'b0)begin
				X_ADDR <= 15'd0;
				Y_ADDR <= 15'd0;
				W_EN <= 1'b0;
				is_lsb <= 1'b0;
		end
		else begin
				if(HREF_CAM == 1'b1)begin
						if(is_lsb) begin
								X_ADDR <= X_ADDR + 15'd1;
								Y_ADDR <= Y_ADDR;
								pixel_data_RGB332[7:2] <= data[7:2];
								W_EN <= 1'b1;
						end
						else begin
								X_ADDR <= X_ADDR;
								Y_ADDR <= Y_ADDR;
								pixel_data_RGB332[1:0] <= data[1:0];
								W_EN <= 1'b0;
						end
						is_lsb <= ~is_lsb;
				end
				else begin
						W_EN <= 1'b0;
						is_lsb <= 1'b0;
						
						if(last_href == 1'b1)begin
								X_ADDR <= 15'b0;
								Y_ADDR <= Y_ADDR + 15'd1;
						end
						else begin
								X_ADDR <= X_ADDR;
								Y_ADDR <= Y_ADDR;
						end
				end
		end
		last_href <= HREF_CAM;
end

///////* Update Read Address *///////
always @ (VGA_PIXEL_X, VGA_PIXEL_Y) begin
		READ_ADDRESS = (VGA_PIXEL_X + VGA_PIXEL_Y*`SCREEN_WIDTH);
		if(VGA_PIXEL_X>(`SCREEN_WIDTH-1) || VGA_PIXEL_Y>(`SCREEN_HEIGHT-1))begin
				VGA_READ_MEM_EN = 1'b0;
		end
		else begin
				VGA_READ_MEM_EN = 1'b1;
		end
end


///////* Different implementations that DO NOT WORK *///////

//reg HSYNC_PREV;
//always @ (posedge PCLK) begin
//
//	if(VSYNC) begin
//		Y_ADDR <= 15'd0;
//	end
//	if(~HSYNC && (HSYNC!=HSYNC_PREV) || VSYNC) begin
//		X_ADDR <= 15'd0;
//		
//	end
//	else if(HSYNC && ~VSYNC) begin
//		if(HSYNC_PREV != HSYNC) Y_ADDR <= Y_ADDR + 15'd1;
//		case(WRITE_STATE)
//			W_1: begin
//				W_EN <= 1'b0;
//				X_ADDR <= X_ADDR +15'd1;
//				pixel_data_RGB332[7:5] <= GPIO_1_D[27:25];
//				pixel_data_RGB332[4:2] <= GPIO_1_D[22:20];
//				WRITE_STATE = W_2;
//			end
//			W_2: begin
//				pixel_data_RGB332[1:0] <= GPIO_1_D[24:23];
//				W_EN <= 1'b1;
//				WRITE_STATE <= W_1;
//			end
//		endcase
//	end
//	HSYNC_PREV <= HSYNC;
//end



//always @ (posedge PCLK) begin
//	if(HSYNC && ~VSYNC) begin
//		case(WRITE_STATE)
//			W_1: begin
//				W_EN = 1'b0;
//				pixel_data_RGB332[7:5] = GPIO_1_D[27:25];
//				pixel_data_RGB332[4:2] = GPIO_1_D[22:20];
//				WRITE_STATE = W_2;
//			end
//			W_2: begin
//				pixel_data_RGB332[1:0] = GPIO_1_D[24:23];
//				W_EN = 1'b1;
//				WRITE_STATE = W_1;
//				if((WRITE_ADDRESS == MAX_ADDRESS-1))WRITE_ADDRESS = 15'b0;
//				else WRITE_ADDRESS = WRITE_ADDRESS + 15'd1; 
//			end
//		endcase
//	end
//end


//always @ (posedge PCLK) begin
//	if(HSYNC && ~VSYNC) begin
//		WRITE_STATE<= NEXT_STATE;
//	end
//end
//always @ (WRITE_STATE) begin
//	case(WRITE_STATE)
//				W_1: begin
//				W_EN = 1'b0;
//				pixel_data_RGB332[7:5] = GPIO_1_D[27:25];
//				pixel_data_RGB332[4:2] = GPIO_1_D[22:20];
//				NEXT_STATE = W_2;
//			end
//			W_2:begin
//				pixel_data_RGB332[1:0] = GPIO_1_D[24:23];
//				W_EN = 1'b1;
//				NEXT_STATE <= W_1;
//				WRITE_ADDRESS = WRITE_ADDRESS + 1; 
//				if(WRITE_ADDRESS == MAX_ADDRESS) WRITE_ADDRESS = 15'b0;
//			end
//	endcase
//end

/** MEMORY TO VGA TEST **/
//reg [7:0] test_colour = 8'b111_111_11;
//reg [7:0] pattern_counter = 8'd0;
//always @ (posedge CLK_50_PLL)begin
//	W_EN = 1'b1;
//	if(WRITE_ADDRESS == MAX_ADDRESS-1) WRITE_ADDRESS = 15'd0;
//	else WRITE_ADDRESS = (WRITE_ADDRESS+15'd1);
//	if(pattern_counter == (`SCREEN_WIDTH-1)) pattern_counter = 8'd0; 
//	else pattern_counter = (pattern_counter+8'd1);
//	
//	if((pattern_counter<8'd90) && (pattern_counter>8'd86)) test_colour = RED;
//	else if((WRITE_ADDRESS <(61*`SCREEN_WIDTH)) && (WRITE_ADDRESS> 58*`SCREEN_WIDTH - 1)) test_colour = GREEN;
//	else test_colour = 8'b111_111_11;
//end

///** vga driver test **/
//reg [7:0] test_colour;
//reg [27:0]t_counter;
//reg[1:0] colour_state;
//always@(posedge PCLK)begin	
//	if(HSYNC == 1'b1)begin
//		t_counter = t_counter + 28'd1;
//		if(t_counter == ONE_SEC)begin
//			t_counter = 28'd0;
//			colour_state = (colour_state + 2'd1)%(2'd3);
//		end
//		case(colour_state)
//			2'b00: test_colour = 8'b111_000_00;
//			2'b01: test_colour = 8'b000_111_00;
//			2'b10: test_colour = 8'b000_000_11;
//		endcase
//	end
//end


	
endmodule 