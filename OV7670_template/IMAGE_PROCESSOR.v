`define SCREEN_WIDTH 176
`define NUMBER_BARS 20
`define BAR_HEIGHT 6

module IMAGE_PROCESSOR (
	PIXEL_IN,
	VAL,
	RESULT,
	READ_ADDRESS_NEXT
);


//=======================================================
//  PARAMETER declarations
//=======================================================
localparam square_thresh = 1056;

//=======================================================
//  PORT declarations
//=======================================================
input	[7:0]	PIXEL_IN;
input VAL;
output reg [14:0] READ_ADDRESS_NEXT;
output [8:0] RESULT;
reg [10:0] RGB_pixel_count [2:0][(`NUMBER_BARS-1):0];
reg [10:0] pixel_counter = 11'b0;
reg [4:0]  bar_counter = 5'b0;

reg [2:0] triangle_detect = 3'b111;
reg [2:0] square_detect = 3'b111;
reg [2:0] circle_detect = 3'b111;

wire[2:0] r_val,
			 g_val,
			 b_val;
assign r_val = PIXEL_IN[7:5];
assign g_val = PIXEL_IN[4:2];
assign b_val = {1'b0, PIXEL_IN[1:0]};
assign RESULT = {triangle_detect[2:0], square_detect[2:0], circle_detect[2:0]};

//=======================================================
//  UPDATE PIXEL COUNT
//=======================================================
always @ (posedge VAL) begin
	if(r_val>b_val && r_val>g_val)begin
		RGB_pixel_count[2][bar_counter] <= RGB_pixel_count[2][bar_counter] + 1;
	end
	else if(g_val>r_val && g_val>b_val)begin
		RGB_pixel_count[1][bar_counter] <= RGB_pixel_count[1][bar_counter] + 1;
	end
	else if(b_val>r_val && b_val>g_val)begin
		RGB_pixel_count[0][bar_counter] <= RGB_pixel_count[2][bar_counter] + 1;
	end
	
	pixel_counter <= pixel_counter +1;
end

//=======================================================
//  UPDATE READ ADDRESS
//=======================================================
always@(pixel_counter, bar_counter)begin
	if(pixel_counter == `SCREEN_WIDTH*`BAR_HEIGHT) begin
		pixel_counter = 11'b0;
		bar_counter = bar_counter+1;
	end
	if( bar_counter == `NUMBER_BARS)begin
		bar_counter = 5'b0;
	end
	READ_ADDRESS_NEXT = pixel_counter+bar_counter*(`SCREEN_WIDTH*`BAR_HEIGHT);
end

//=======================================================
//  UPDATE DETECTION ARRAY
//=======================================================
reg [4:0] idx;
always @ (RGB_pixel_count[2][19] or RGB_pixel_count[1][19] or RGB_pixel_count[0][19] )begin
	for(idx=1 ; idx<`NUMBER_BARS ; idx=idx+1) begin
		triangle_detect[2] = triangle_detect[2] && (RGB_pixel_count [2][idx] > RGB_pixel_count [2][idx-1]); 
		triangle_detect[1] = triangle_detect[1] && (RGB_pixel_count [1][idx] > RGB_pixel_count [1][idx-1]);
		triangle_detect[0] = triangle_detect[0] && (RGB_pixel_count [0][idx] > RGB_pixel_count [0][idx-1]);
		square_detect[2] = square_detect[2] && (RGB_pixel_count [2][idx]-RGB_pixel_count [2][idx-1] < square_thresh);
		square_detect[1] = square_detect[1] && (RGB_pixel_count [1][idx]-RGB_pixel_count [1][idx-1] < square_thresh);
		square_detect[0] = square_detect[0] && (RGB_pixel_count [0][idx]-RGB_pixel_count [0][idx-1] < square_thresh);
	end
end	



endmodule