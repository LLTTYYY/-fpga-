
module picture_binarization #(                           
  parameter  THRESHOLD  = 8'd80)  //���ö�ֵ����ֵ
(
    //global signal
    input			clk              ,
	input			rst_n            ,
	//Image data prepred to be processed   Ԥ�����ͼ������
	input			per_frame_vsync  ,
    input			per_frame_href   ,
    input			per_frame_clken  ,
    input  [7:0]	per_img_Y        ,
	//Image data has been processed   ������ͼ������
	output			post_frame_vsync ,
	output			post_frame_href  ,
	output			post_frame_clken ,
	output   	    post_img_Bit        
);
//reg define
reg    post_frame_vsync_r;
reg    post_frame_href_r;
reg    post_frame_clken_r;
reg    post_img_Bit_r;
assign  post_frame_vsync    = post_frame_vsync_r  ;
assign  post_frame_href     = post_frame_href_r   ;
assign  post_frame_clken    = post_frame_clken_r  ;
assign  post_img_Bit        = post_img_Bit_r      ;
//��ֵ��
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        post_img_Bit_r <= 1'b0;
    else if(per_img_Y < THRESHOLD)   //��ֵ
        post_img_Bit_r <= 1'b1; //��
    else
        post_img_Bit_r <= 1'b0; //��
end
 
//��ʱ1����ͬ��ʱ���ź�
always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        post_frame_vsync_r <= 1'd0;
        post_frame_href_r <= 1'd0;
        post_frame_clken_r <= 1'd0;
    end
    else begin
        post_frame_vsync_r <= per_frame_vsync;
		post_frame_href_r  <= per_frame_href;
        post_frame_clken_r <= per_frame_clken;
    end
end
endmodule