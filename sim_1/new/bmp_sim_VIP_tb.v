`timescale 1ns / 1ns
 
module bmp_sim_VIP_tb();
 
integer  iBmpFileId ;      //输入BMP图片
integer  oBmpFileId_1;     //输出BMP图片
integer  oTxtFiled   ;    //输入文本
 
integer  iIndex = 0;      //输入BMP数据索引
integer  pixel_index = 0; //输入像素数据索引
 
integer  iCode;
 
integer  iBmpWidth;        //输入BMP宽度
integer  iBmpHight;        //输入BMP高度
integer  iBmpSize;         //输入BMP字节数
integer  iDataStartIndex;  //输入BMP像素数据偏移量
reg  [7:0] rBmpData [0:2000000] ;       //用于寄存输入BMP图片中的字节数据（包括54字节的文件头）
 
reg  [7:0] Vip_BmpData_1 [0:2000000] ;  //用于寄存图像处理输出BMP图片
reg  [7:0] rBmpWord ;                  //输出BMP图片时用于寄存数据（以word为单位，即4Byte）
reg  [7:0] pixel_data ;                 //输出视频流时的像素数据
 
reg  clk;
reg rst_n;
 
reg [7:0] vip_pixel_data_1[0:921600];  //680*480*3  
 
initial begin
 
    //打开输入BMP图片
	iBmpFileId = $fopen("C:\\fpga_project\\1_\\project\\picture_sim\\LB325DE.bmp","rb");
	
	//将输入图片加载到数组中
	iCode = $fread(rBmpData,iBmpFileId);
	
	//根据BMP图片文件头的格式，分别计算出图片的宽度/高度/像素数据偏移量/图片字节数
	iBmpWidth       = {rBmpData[21],rBmpData[20],rBmpData[19],rBmpData[18]};
	iBmpHight       = {rBmpData[25],rBmpData[24],rBmpData[23],rBmpData[22]};
	iBmpSize        = {rBmpData[5],rBmpData[4],rBmpData[3],rBmpData[2]};
	iDataStartIndex = {rBmpData[13],rBmpData[12],rBmpData[11],rBmpData[10]};
	
	//关闭输入图片
	$fclose(iBmpFileId);
	
	//打开输出BMP图片
	oBmpFileId_1 = $fopen("C:\\fpga_project\\1_\\project\\picture_sim\\LB325DE_output_cr.bmp","wb+");
	
	//延迟13ms，等待第一帧图像处理结束
	#13000000
	
    
    //加载图像处理后，BMP图片的文件头和像素数据
    //输出第一张
    for (iIndex = 0; iIndex < iBmpSize; iIndex = iIndex + 1) begin
		if(iIndex < 54) begin
			Vip_BmpData_1[iIndex] = rBmpData[iIndex];
			//$display("data %h",rBmpData[iIndex]);
		end
	    else begin
			Vip_BmpData_1[iIndex] = vip_pixel_data_1[iIndex-54];
		end
	end
	
	//将数组中的数据写到输出的BMP图片中
	 for (iIndex = 0; iIndex < iBmpSize; iIndex = iIndex + 1) begin
		rBmpWord = Vip_BmpData_1[iIndex];
		$fwrite(oBmpFileId_1,"%c",rBmpWord);
    end	
	
	//关闭输出BMP图片
	$fclose(oBmpFileId_1);
end  
 
 
//初始化时钟和复位信号
initial begin
	clk = 1;
	rst_n = 0;
	#110
	rst_n = 1;
 
end
 
always #10 clk = ~clk;
 
//在时钟驱动下，从数组中读取像素数据，用于在仿真中查看BMP数据
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		pixel_data <= 8'd0;
		pixel_index <= 0;
	end
	else begin
		pixel_data <= rBmpData[pixel_index];
		pixel_index <= pixel_index +1;
	end
end
//产生摄像头时序
wire  cmos_vsync ;
reg   cmos_href;
wire  cmos_clken;
reg [23:0] cmos_data;
reg  cmos_clken_r;
reg  [31:0] cmos_index;
parameter [10:0] IMG_HDISP = 11'd640;
parameter [10:0] IMG_VDISP = 11'd480;
localparam H_SYNC  = 11'd5;
localparam H_BACK  = 11'd5;
localparam H_DISP  = IMG_HDISP;
localparam H_FRONT = 11'd5;
localparam H_TOTAL = H_SYNC + H_BACK + H_DISP + H_FRONT;
 
localparam V_SYNC  = 11'd1;
localparam V_BACK  = 11'd0;
localparam V_DISP  = IMG_VDISP;
localparam V_FRONT = 11'd1;
localparam V_TOTAL = V_SYNC + V_BACK + V_DISP + V_FRONT;
//模拟OV7725/OV5640 驱动模块输出的时钟使能
always@(posedge clk or negedge rst_n) begin
	if(!rst_n)
		cmos_clken_r <= 0;
	else 
		cmos_clken_r <= ~cmos_clken_r;		
end
//水平寄存器
reg [10:0] hcnt;
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) 
		hcnt <= 11'd0;
	else if(cmos_clken_r)
		hcnt <= (hcnt < H_TOTAL - 1'b1)? hcnt + 1'b1 : 11'd0;		
end
//竖直寄存器
reg [10:0] vcnt;
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) 
		vcnt <= 11'd0;
	else if(cmos_clken_r) begin
		if(hcnt == H_TOTAL - 1'b1)
			vcnt <= (vcnt < V_TOTAL - 1'b1)? vcnt + 1'b1 : 11'd0;	
		else
			vcnt <= vcnt;	
	end		
end
 
//场同步
reg cmos_vsync_r;
 
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) 
		cmos_vsync_r <= 1'b0;
	else begin
		if(vcnt <= V_SYNC - 1'b1)
			cmos_vsync_r <= 1'b0;
		else
			cmos_vsync_r <= 1'b1;
	end	
end
 
assign cmos_vsync = cmos_vsync_r;
 
 
//行有效
wire  frame_valid_ahead = (vcnt >= V_SYNC + V_BACK && vcnt < V_SYNC + V_BACK + V_DISP
						   && hcnt >= H_SYNC + H_BACK && hcnt < H_SYNC + H_BACK + H_DISP) 
						   ? 1'b1 : 1'b0;
 
reg  cmos_href_r;
 
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) 
		cmos_href_r <= 1'b0;
	else begin
		if(frame_valid_ahead)
			cmos_href_r <= 1'b1;	
		else
			cmos_href_r <= 1'b0;	
	end		
end
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) 
		cmos_href <= 1'b0;
	else begin
		cmos_href <= cmos_href_r;	
	end		
end
 
assign cmos_clken = cmos_href & cmos_clken_r;
 
 
//从数组中以视频格式输出像素数据
wire  [10:0] x_pos;
wire  [10:0] y_pos;
 
assign x_pos = frame_valid_ahead ? (hcnt - (H_SYNC + H_BACK)): 0;
assign y_pos = frame_valid_ahead ? (vcnt - (V_SYNC + V_BACK)): 0;
 
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		cmos_index <= 0;
		cmos_data <= 24'd0;
	end	
	else begin
		cmos_index <= y_pos * 1920 + x_pos * 3 + 54;
		cmos_data <= {rBmpData[cmos_index],rBmpData[cmos_index+1],rBmpData[cmos_index+2]};//按照BGR888存放  
	end		
end
//--------------------------图像处理算法实现----------------------------//
wire 	   per_frame_vsync = cmos_vsync;
wire       per_frame_href  = cmos_href;
wire       per_frame_clken = cmos_clken;
wire [7:0] per_img_red     = cmos_data[7:0];
wire [7:0] per_img_green   = cmos_data[15:8];
wire [7:0] per_img_blue    = cmos_data[23:16];
wire 	   post0_frame_vsync ;
wire       post0_frame_href  ;
wire       post0_frame_clken ;
wire [7:0] post0_img_Y       ;
wire [7:0] post0_img_Cb      ;
wire [7:0] post0_img_Cr      ;
//最后经过图像处理算法处理完的结果
wire 	   post_frame_vsync ;
wire       post_frame_href  ;
wire       post_frame_clken ;
wire       post_img_Bit     ;
wire [7:0] post_img_Y       ;

picture_process  u_picture_process(
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
	.post_frame_vsync (post_frame_vsync),
	.post_frame_href  (post_frame_href ),
	.post_frame_clken (post_frame_clken),
	.post_img_Bit     (post_img_Bit    ),
	.post_img_Y       (post_img_Y      )
);
//输出图片
wire 	   PCI1_vip_out_frame_vsync ;
wire       PCI1_vip_out_frame_href  ;
wire       PCI1_vip_out_frame_clken ;
wire [7:0] PCI1_vip_out_img_R       ;
wire [7:0] PCI1_vip_out_img_G       ;
wire [7:0] PCI1_vip_out_img_B       ;
assign  PCI1_vip_out_frame_vsync = post_frame_vsync;
assign  PCI1_vip_out_frame_href  = post_frame_href;
assign  PCI1_vip_out_frame_clken = post_frame_clken;
assign  PCI1_vip_out_img_R   = {8{post_img_Bit}};
assign  PCI1_vip_out_img_G   = {8{post_img_Bit}};
assign  PCI1_vip_out_img_B   = {8{post_img_Bit}};
//assign  PCI1_vip_out_img_R  = post_img_Y;
//assign  PCI1_vip_out_img_G  = post_img_Y;
//assign  PCI1_vip_out_img_B  = post_img_Y;
reg [31:0] PCI1_vip_cnt ; 
reg        PCI1_vip_vsync_r ;     //寄存VIP输出的场同步
reg        PCI1_vip_out_en  ;     //寄存VIP处理图像的使能信号，仅维持一帧的时间
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) 
		PCI1_vip_vsync_r <= 1'b0;
	else begin
		PCI1_vip_vsync_r <= PCI1_vip_out_frame_vsync;	
	end		
end
 
 
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) 
		PCI1_vip_out_en <= 1'b1;
	else if(PCI1_vip_vsync_r & (!PCI1_vip_out_frame_vsync)) begin
		PCI1_vip_out_en <= 1'b0;	
	end		
end
 
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) 
		PCI1_vip_cnt <= 32'd0;
	else if(PCI1_vip_out_en) begin
		if(PCI1_vip_out_frame_href & PCI1_vip_out_frame_clken) begin
		    //$display("output picture22222");
			PCI1_vip_cnt <= PCI1_vip_cnt + 3;
			vip_pixel_data_1[PCI1_vip_cnt+0] <= PCI1_vip_out_img_R;
			vip_pixel_data_1[PCI1_vip_cnt+1] <= PCI1_vip_out_img_G;
			vip_pixel_data_1[PCI1_vip_cnt+2] <= PCI1_vip_out_img_B;
		end		
	end		
end
endmodule