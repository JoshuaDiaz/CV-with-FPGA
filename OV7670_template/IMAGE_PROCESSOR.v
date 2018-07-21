`define SCREEN_WIDTH 176
`define NUMBER_BARS 20
`define BAR_HEIGHT 6

module IMAGE_PROCESSOR (
	PIXEL_IN,
	READ_ADDRESS_NEXT
);

input	[7:0]	PIXEL_IN;
output reg [14:0] READ_ADDRESS_NEXT;

reg [10:0] RGB_pixel_count [2:0][(`NUMBER_BARS-1):0];
reg [10:0] pixel_counter = 11'b0;
reg [4:0]  bar_counter = 5'b0;

always @ (PIXEL_IN) begin
	/* PROCESSING */
	// Update RGB pixel count matrix
	if(PIXEL_IN[7:5] > PIXEL_IN[4:2] && PIXEL_IN[7:5] > PIXEL_IN[1:0])begin
		RGB_pixel_count[2][bar_counter] = RGB_pixel_count[2][bar_counter] + 1;
	end
	else if(PIXEL_IN[4:2] > PIXEL_IN[7:5] && PIXEL_IN[4:2] > PIXEL_IN[1:0])begin
		RGB_pixel_count[1][bar_counter] = RGB_pixel_count[1][bar_counter] + 1;
	end
	else if(PIXEL_IN[1:0] > PIXEL_IN[7:5] && PIXEL_IN[1:0] > PIXEL_IN[4:2])begin
		RGB_pixel_count[0][bar_counter] = RGB_pixel_count[2][bar_counter] + 1;
	end
	
	//SHAPE DETECTION
	
	
	// Update index of pixel
	pixel_counter = pixel_counter +1;
	if(pixel_counter == `SCREEN_WIDTH*`BAR_HEIGHT) begin
		pixel_counter = 11'b0;
		bar_counter = bar_counter+1;
	end
	if( bar_counter == `NUMBER_BARS)begin
		bar_counter = 5'b0;
	end
	READ_ADDRESS_NEXT = pixel_counter+bar_counter*(`SCREEN_WIDTH*`BAR_HEIGHT);
end

endmodule