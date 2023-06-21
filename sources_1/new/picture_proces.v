 //cb分量不受亮度的影响，亮度是独立在Y通道的
 
module picture_process(
    input	        clk              ,
	input	        rst_n            ,
	//Image data prepred to be processed
	input	        per_frame_vsync  ,
    input	        per_frame_href   ,
    input	        per_frame_clken  ,
    input  [7:0]	per_img_red      ,
    input  [7:0]    per_img_green    ,
    input  [7:0]	per_img_blue     ,
	//Image data has been processed
	output	        post_frame_vsync ,
	output	        post_frame_href  ,
	output	        post_frame_clken ,
	output  	    post_img_Bit      ,
	output [7:0]    post_img_Y      
);
 
wire	    post0_frame_vsync ;
wire	    post0_frame_href  ;
wire	    post0_frame_clken ;
wire [7:0]	post0_img_Y       ;
wire [7:0]	post0_img_Cb      ;
wire [7:0]	post0_img_Cr      ;
 
assign  post_img_Y = post0_img_Cb;
 
 
 
//彩色转灰度
picture_RGB888_YCbCr444  u_PICTURE_RGB888_YCbCr444(
    //global signal
	.clk               (clk),
	.rst_n             (rst_n),
	
	//Image data prepred to be processed
	.per_frame_vsync   (per_frame_vsync),
    .per_frame_href    (per_frame_href ),
    .per_frame_clken   (per_frame_clken),
    .per_img_red       (per_img_red    ),
    .per_img_green     (per_img_green  ),
    .per_img_blue      (per_img_blue   ),
	
    //Image data has been processed
	.post_frame_vsync  (post0_frame_vsync),
	.post_frame_href   (post0_frame_href ),
	.post_frame_clken  (post0_frame_clken),
	.post_img_Y        (post0_img_Y      ),
	.post_img_Cb       (post0_img_Cb     ),
	.post_img_Cr       (post0_img_Cr     )
);
 
//二值化
picture_binarization #(                           
    .THRESHOLD         (8'd150))  //设置二值化阈值
u_picture_binarization(
    //global signal
    .clk               (clk),
	.rst_n             (rst_n),
	
	//Image data prepred to be processed
	.per_frame_vsync   (post0_frame_vsync),
    .per_frame_href    (post0_frame_href ),
    .per_frame_clken   (post0_frame_clken),
    .per_img_Y         (post0_img_Cb     ),
	
    //Image data has been processed
	.post_frame_vsync  (post_frame_vsync),
	.post_frame_href   (post_frame_href ),
	.post_frame_clken  (post_frame_clken),
	.post_img_Bit      (post_img_Bit    )
);
endmodule