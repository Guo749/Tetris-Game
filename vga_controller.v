module vga_controller(iRST_n,
                      iVGA_CLK,
                      oBLANK_n,
                      oHS,
                      oVS,
                      b_data,
                      g_data,
                      r_data,
							 up,
							 down,
							 right,
							 left,
							 ps2_data,
							 key_pressed);

	
input iRST_n;
input iVGA_CLK;


output reg oBLANK_n;
output reg oHS;
output reg oVS;
output [7:0] b_data;
output [7:0] g_data;  
output [7:0] r_data;                        


reg [18:0] ADDR;
reg [23:0] bgr_data;
wire VGA_CLK_n;
wire [7:0] index;
wire [23:0] bgr_data_raw;
wire cBLANK_n,cHS,cVS,rst;


///////////////////////self-define///////////////////////////////// 
input up, down, left, right;
input [7:0] ps2_data;
input	key_pressed;

// the x,y for current falling shape, usually in the middle of the shape
reg [9:0] ref_x;
reg [9:0] ref_y;
/////////////////////score///////////////////////////////////////////
reg [4:0] score;
reg [31:0] score_x;
reg [31:0] score_y;

////////////////////////related to index //////////////////////////////
reg [7:0] change;
reg [7:0]index_changed;

///////////////////////// beat control /////////////////////////////////////
reg [30:0] count;
reg [30:0] count_1;
reg [31:0] beat;

/////////////////////////rotate /////////////////////////////////////////////
reg [4:0] rotate;

/////////////////////////reg for left,right,up /////////////////////////////////////////////
reg l_flag;
reg r_flag;
reg ro_flag;
reg key_to_left;
reg key_to_right;
reg key_to_rotate;
//integer l_flag;
//integer r_flag;
//integer ro_flag;
//integer key_to_left;
//integer key_to_right;
//integer key_to_rotate;


/////////////////////////basic parameter/////////////////////////////////////
reg[7:0] b_side;	//block side
reg[7:0] score_side;
reg[7:0] row;
reg[7:0] column;
reg[31:0] board[23:0];
integer i;	//index for board
integer i_show;
integer j_show;
integer i_1_show;
integer rmLine;
integer vga_w;			// vga_controller_width  = 640
integer vga_h;			// vag_controller_height = 480
integer shape;			//shape number 0->4squares, 1 -> mountain  2-> bar  3->leftGun, 4->rightGun

////////////////module to generate the rand number//////////////////////////
wire[15:0] randNum;
//reg[15:0] randNum;
random myRand (.clk(VGA_CLK_n), .rand_num(randNum));


initial begin
	//b_side		   <= 40;		//set block to be 40 * 40
	b_side         <= 20;
	ref_x          <= 320;		
	ref_y          <= 0;
	vga_w	   		<= 640;
	vga_h		      <= 480;
	shape          <= 0;
	score          <= 0;
	beat				<= 10000000;
	score_x			<= 600;
   score_y			<= 0;
	score_side     <= 5;
	
	l_flag			<= 1;
	r_flag			<=	1;
	ro_flag			<= 1;
	key_to_left		<= 0;
	key_to_right	<= 0;
	key_to_rotate	<= 0;
	//show score use square to show that, like seven segments
//	row            <= vga_h / b_side;
//	column         <= vga_w / b_side;
	
	//make every piece of board to be 0, to be the background color
	for(i = 0; i < 24; i = i + 1)
		board[i] = 32'b0;
				
end


/*
	this part 
	1.focus on "moving" the block using relative point
	where only one point is being moved, and to calculate the shape 
	according to shape number
	
	2. also, to perform remove function
	divide the background into 16 * 12 grid, and 1 means occupied, 0 means no square
*/
always @(posedge(VGA_CLK_n))
begin
	count <= count +1;
	
	if(ps2_data == 97 && l_flag == 1)
	begin
		key_to_left = 1;
		l_flag = 0;
	end
	
	if(ps2_data == 100 && r_flag == 1)
	begin
		key_to_right = 1;
		r_flag = 0;
	end
	
	if(ps2_data == 119 && ro_flag == 1)
	begin
		key_to_rotate = 1;
		ro_flag = 0;
	end
	
	if(ps2_data == 0)
	begin
		l_flag = 1;
		r_flag = 1;
		ro_flag = 1;
	end	
	

	if(count == beat)
	begin	
	
		
		//check to remove
		//65535 means 16'b1111 1111 1111 1111
		for(i_1_show = 0; i_1_show < 24; i_1_show = i_1_show + 1)begin
		
			if(board[i_1_show] == 4294967295)begin
				score <= (score + 1) % 5;
				if(score == 1)begin
					beat <= 5000000;
				end
				for(rmLine = i_1_show; rmLine >= 1; rmLine = rmLine - 1)begin
					board[rmLine] <= board[rmLine-1];
				end
				board[0] <= 16'b0;
			end
			
		end	
		
		//check to stop the game
		if(board[0] != 0)begin
			ref_x <= 0;
			ref_y <= 480;
			shape <= 5;
		end
		
		//shape 0 to 4 corresponding to different shapes, please refer to pic
		
//////////////////////shape 0 down////////////////////////////////////////////////////////////////////
		if(shape == 0)begin
			//if it's moveable, we move it 
			if(ref_y + b_side < vga_h  && 
			(board[ref_y / b_side + 1][ref_x / b_side]     != 1 && 
			 board[ref_y / b_side + 1][ref_x / b_side - 1] != 1))begin
				ref_y <= ref_y + b_side;
			end 
			else begin  //cannot move it anymore
				board[ref_y / b_side    ][ref_x / b_side] <= 1;
				board[ref_y / b_side - 1][ref_x / b_side] <= 1;	
				board[ref_y / b_side    ][ref_x / b_side - 1] <= 1;	
				board[ref_y / b_side - 1][ref_x / b_side - 1] <= 1;	
		
				//generate random number for next time. the falling point
				ref_x <= (randNum % 32) * b_side <= 1 * b_side ? 
								2* b_side : (randNum % 32) * b_side >= 29* b_side ?
								28 * b_side: (randNum % 32) * b_side;
				ref_y <= 0;
				shape <= (randNum % 5);
				rotate <= 0;				
			end
		end
//////////////////////shape 1 down////////////////////////////////////////////////////////////////////		
		else if(shape == 1)begin
			if(rotate == 0)begin
				if(ref_y + b_side  < vga_h && 
				(board[ref_y / b_side + 1][ref_x / b_side] != 1     && 
				 board[ref_y / b_side + 1][ref_x / b_side - 1] != 1 &&
				 board[ref_y / b_side + 1][ref_x / b_side + 1] != 1))begin
					ref_y <= ref_y + b_side;
				end
				else begin	
					board[ref_y / b_side    ][ref_x / b_side    ] <= 1;
					board[ref_y / b_side - 1][ref_x / b_side    ] <= 1;	
					board[ref_y / b_side    ][ref_x / b_side - 1] <= 1;	
					board[ref_y / b_side    ][ref_x / b_side + 1] <= 1;	
		
					ref_x <= (randNum % 32) * b_side <= 1 * b_side ? 
								2* b_side : (randNum % 32) * b_side >= 29* b_side ?
								28 * b_side: (randNum % 32) * b_side;
					ref_y <= 0;
					shape <= (randNum % 5);

					rotate <= 0;											
				end
			end
			else if(rotate == 1)begin
				if(ref_y + 2 * b_side < vga_h && (
				board[ref_y / b_side + 1][ref_x / b_side]    != 1 &&
				board[ref_y / b_side + 2][ref_x / b_side -1] != 1))begin
					ref_y <= ref_y + b_side;
				end
				else begin	
					board[ref_y / b_side    ][ref_x / b_side]     <= 1;
					board[ref_y / b_side    ][ref_x / b_side - 1] <= 1;	
					board[ref_y / b_side + 1][ref_x / b_side - 1] <= 1;	
					board[ref_y / b_side - 1][ref_x / b_side - 1] <= 1;	
		
					ref_x <= (randNum % 32) * b_side <= 1 * b_side ? 
								2* b_side : (randNum % 32) * b_side >= 29* b_side ?
								28 * b_side: (randNum % 32) * b_side;
					ref_y <= 0;
					shape <= (randNum % 5);
					rotate <= 0;											
				end				
			end
			else if(rotate == 2)begin
				if(ref_y + b_side < vga_h && (
				board[ref_y / b_side    ][ref_x / b_side]         != 1 &&
				board[ref_y / b_side + 1][ref_x / b_side - 1] != 1 &&
				board[ref_y / b_side    ][ref_x / b_side -2]      != 1))begin
					ref_y <= ref_y + b_side;
				end
				else begin	
					board[ref_y / b_side - 1][ref_x / b_side - 2]  <= 1;
					board[ref_y / b_side - 1][ref_x / b_side - 1]  <= 1;	
					board[ref_y / b_side - 1][ref_x / b_side]      <= 1;	
					board[ref_y / b_side    ][ref_x / b_side - 1]  <= 1;	
		
					ref_x <= (randNum % 32) * b_side <= 1 * b_side ? 
								2* b_side : (randNum % 32) * b_side >= 29* b_side ?
								28 * b_side: (randNum % 32) * b_side;
					ref_y <= 0;
					shape <= (randNum % 5);
					rotate <= 0;											
				end				
			end
			else if(rotate == 3)begin
				if(ref_y + b_side < vga_h && (
				board[ref_y / b_side + 1][ref_x / b_side] != 1 &&
				board[ref_y / b_side][ref_x / b_side - 1] != 1))begin
					ref_y <= ref_y + b_side;
				end
				else begin	
					board[ref_y / b_side][ref_x / b_side]         <= 1;
					board[ref_y / b_side - 1][ref_x / b_side]     <= 1;	
					board[ref_y / b_side - 2][ref_x / b_side]     <= 1;	
					board[ref_y / b_side - 1][ref_x / b_side - 1] <= 1;	
		
					ref_x <= (randNum % 32) * b_side <= 1 * b_side ? 
								2* b_side : (randNum % 32) * b_side >= 29* b_side ?
								28 * b_side: (randNum % 32) * b_side;
					ref_y <= 0;
					shape <= (randNum % 5);
					rotate <= 0;											
							
				end				
			end

		end
//////////////////////shape 2 down////////////////////////////////////////////////////////////////////		
		else if(shape == 2)begin
			if(rotate == 0)begin
				if(ref_y + b_side  < vga_h && 
				(board[ref_y / b_side + 1][ref_x / b_side]      != 1 && 
				 board[ref_y / b_side + 1][ref_x / b_side - 1]  != 1 &&
				 board[ref_y / b_side + 1][ref_x / b_side + 1]  != 1 && 
				 board[ref_y / b_side + 1][ref_x / b_side + 2]  != 1))begin
					ref_y <= ref_y + b_side;			
				end
				else begin
					board[ref_y / b_side][ref_x / b_side]         <= 1;		
					board[ref_y / b_side][ref_x / b_side - 1]     <= 1;	
					board[ref_y / b_side][ref_x / b_side + 1]     <= 1;	
					board[ref_y / b_side][ref_x / b_side + 2]     <= 1;	
					
					ref_x <= (randNum % 32) * b_side <= 1 * b_side ? 
								2* b_side : (randNum % 32) * b_side >= 29* b_side ?
								28 * b_side: (randNum % 32) * b_side;
					ref_y <= 0;
					shape <= (randNum % 5);
					rotate <= 0;											
			
				end			
			end
			else if(rotate == 1)begin
				if(ref_y + 3 * b_side < vga_h &&
					board[ref_y / b_side + 3][ref_x / b_side - 1] != 1)begin
						ref_y <= ref_y + b_side;
					end
				else begin
					board[ref_y / b_side    ][ref_x / b_side - 1] <= 1;
					board[ref_y / b_side + 2][ref_x / b_side - 1] <= 1;
					board[ref_y / b_side + 1][ref_x / b_side - 1] <= 1;
					board[ref_y / b_side - 1][ref_x / b_side - 1] <= 1;
					ref_x <= (randNum % 32) * b_side <= 1 * b_side ? 
								2* b_side : (randNum % 32) * b_side >= 29* b_side ?
								28 * b_side: (randNum % 32) * b_side;
					ref_y <= 0;
					shape <= (randNum % 5);
					rotate <= 0;											
					
				end
			end
			
			else if(rotate == 2)begin
				if(ref_y < vga_h && 
				board[ref_y / b_side    ][ref_x / b_side    ] != 1 &&
				board[ref_y / b_side    ][ref_x / b_side - 1] != 1 &&
				board[ref_y / b_side    ][ref_x / b_side - 2] != 1 &&
				board[ref_y / b_side    ][ref_x / b_side - 3] != 1)begin
					ref_y <= ref_y + b_side;
				end
				else begin
					board[ref_y / b_side - 1][ref_x / b_side]     <= 1;
					board[ref_y / b_side - 1][ref_x / b_side - 1] <= 1;
					board[ref_y / b_side - 1][ref_x / b_side - 2] <= 1;
					board[ref_y / b_side - 1][ref_x / b_side - 3] <= 1;	
					ref_x <= (randNum % 32) * b_side <= 1 * b_side ? 
								2* b_side : (randNum % 32) * b_side >= 29* b_side ?
								28 * b_side: (randNum % 32) * b_side;
					ref_y <= 0;
					shape <= (randNum % 5);
					rotate <= 0;											
					
				end
			end
			else if(rotate == 3)begin
				if(ref_y + b_side < vga_h &&
				board[ref_y / b_side + 1][ref_x / b_side] != 1)begin
					ref_y <= ref_y + b_side;
				end
				else begin
					board[ref_y / b_side    ][ref_x / b_side] <= 1;
					board[ref_y / b_side - 1][ref_x / b_side] <= 1;
					board[ref_y / b_side - 2][ref_x / b_side] <= 1;
					board[ref_y / b_side - 3][ref_x / b_side] <= 1;		
					ref_x <= (randNum % 32) * b_side <= 1 * b_side ? 
								2* b_side : (randNum % 32) * b_side >= 29* b_side ?
								28 * b_side: (randNum % 32) * b_side;
					ref_y <= 0;
					shape <= (randNum % 5);
					rotate <= 0;											
					
				end
			end

		end
//////////////////////shape 3 down////////////////////////////////////////////////////////////////////		
		else if(shape == 3)begin
			if(rotate == 0)begin
				if(ref_y + 2 * b_side < vga_h &&
				(board[ref_y / b_side + 1][ref_x / b_side]     != 1 && 
				 board[ref_y / b_side + 1][ref_x / b_side + 1] != 1     && 
				 board[ref_y / b_side + 2][ref_x / b_side - 1] != 1))begin
					ref_y <= ref_y + b_side;			 
				 end
				 else begin
					board[ref_y / b_side][ref_x / b_side]         <= 1;
					board[ref_y / b_side][ref_x / b_side + 1]     <= 1;
					board[ref_y / b_side][ref_x / b_side - 1]     <= 1;
					board[ref_y / b_side + 1][ref_x / b_side - 1] <= 1;
				 
					ref_x <= (randNum % 32) * b_side <= 1 * b_side ? 
								2* b_side : (randNum % 32) * b_side >= 29* b_side ?
								28 * b_side: (randNum % 32) * b_side;
					ref_y <= 0;
					shape <= (randNum % 5);
					rotate <= 0;											
			 
				 end			
			end
			else if(rotate == 1)begin
					if(ref_y  + 2 * b_side < vga_h &&
						board[ref_y / b_side + 2][ref_x / b_side - 1] != 1 &&
						board[ref_y / b_side][ref_x / b_side - 2]      != 1)begin
							ref_y <= ref_y + b_side;
						end
					else begin
						board[ref_y / b_side][ref_x / b_side - 1] <= 1;
						board[ref_y / b_side - 1][ref_x / b_side - 1] <= 1;
						board[ref_y / b_side - 1][ref_x / b_side - 2] <= 1;
						board[ref_y / b_side + 1][ref_x / b_side - 1] <= 1;	
						ref_x <= (randNum % 32) * b_side <= 1 * b_side ? 
								2* b_side : (randNum % 32) * b_side >= 29* b_side ?
								28 * b_side: (randNum % 32) * b_side;
						ref_y <= 0;
						shape <= (randNum % 5);
						rotate <= 0;											
						
					end	
			end
			else if(rotate == 2)begin
				if(ref_y < vga_h && 
				board[ref_y / b_side][ref_x / b_side]     != 1 &&
				board[ref_y / b_side][ref_x / b_side - 1] != 1 &&
				board[ref_y / b_side][ref_x / b_side - 2] != 1)begin
					ref_y <= ref_y + b_side;
				end
				else begin
					board[ref_y / b_side - 1][ref_x / b_side]     <= 1;
					board[ref_y / b_side - 1][ref_x / b_side - 1] <= 1;
					board[ref_y / b_side - 1][ref_x / b_side - 2] <= 1;
					board[ref_y / b_side - 2][ref_x / b_side]     <= 1;
					
					ref_x <= (randNum % 32) * b_side <= 1 * b_side ? 
								2* b_side : (randNum % 32) * b_side >= 29* b_side ?
								28 * b_side: (randNum % 32) * b_side;
					ref_y <= 0;
					shape <= (randNum % 5);
					rotate <= 0;											

				end
			end
			else if(rotate == 3)begin
				if(ref_y + b_side < vga_h && 
				  board[ref_y / b_side + 1][ref_x / b_side] != 1     &&
				  board[ref_y / b_side + 1][ref_x / b_side + 1] != 1 )begin
						ref_y <= ref_y + b_side;
				end
				else begin
					board[ref_y / b_side    ][ref_x / b_side]     <= 1;
					board[ref_y / b_side    ][ref_x / b_side + 1] <= 1;
					board[ref_y / b_side - 1][ref_x / b_side]     <= 1;
					board[ref_y / b_side - 2][ref_x / b_side]     <= 1;		
					ref_x <= (randNum % 32) * b_side <= 1 * b_side ? 
								2* b_side : (randNum % 32) * b_side >= 29* b_side ?
								28 * b_side: (randNum % 32) * b_side;
					ref_y <= 0;
					shape <= (randNum % 5);
					rotate <= 0;											
					
				end
			end
			
		
		end
//////////////////////shape 4 down////////////////////////////////////////////////////////////////////		
		else if(shape == 4)begin
			if(rotate == 0)begin
				if(ref_y + 2 * b_side < vga_h && 
				(board[ref_y / b_side + 2][ref_x / b_side] != 1     && 
				 board[ref_y / b_side + 1][ref_x / b_side - 1] != 1 &&
				 board[ref_y / b_side + 1][ref_x / b_side - 2] != 1))begin
					ref_y <= ref_y + b_side;				 
				 end
				 else begin
					board[ref_y / b_side][ref_x / b_side]         <= 1;
					board[ref_y / b_side + 1][ref_x / b_side]     <= 1;
					board[ref_y / b_side][ref_x / b_side - 1]     <= 1;
					board[ref_y / b_side][ref_x / b_side - 2]     <= 1;

					
					ref_x <= (randNum % 32) * b_side <= 1 * b_side ? 
								2* b_side : (randNum % 32) * b_side >= 29* b_side ?
								28 * b_side: (randNum % 32) * b_side;
					ref_y <= 0;
					shape <= (randNum % 5);
					rotate <= 0;			
				 end			
			end
			else if(rotate == 1)begin
				if(ref_y + b_side < vga_h &&
				   board[ref_y / b_side + 1][ref_x / b_side - 1] != 1 &&
					board[ref_y / b_side + 1][ref_x / b_side - 2] != 1)begin
						ref_y <= ref_y + b_side;
				end
				else begin
					board[ref_y / b_side][ref_x / b_side - 1]         <= 1;
					board[ref_y / b_side][ref_x / b_side - 2]         <= 1;
					board[ref_y / b_side - 1][ref_x / b_side - 1]     <= 1;
					board[ref_y / b_side - 2][ref_x / b_side - 1]     <= 1;

					
					ref_x <= (randNum % 32) * b_side <= 1 * b_side ? 
								2* b_side : (randNum % 32) * b_side >= 29* b_side ?
								28 * b_side: (randNum % 32) * b_side;
					ref_y <= 0;
					shape <= (randNum % 5);
					rotate <= 0;				
				end
			end
			else if(rotate == 2)begin
				if(ref_y  < vga_h && 
				board[ref_y / b_side][ref_x / b_side]     != 1 &&
				board[ref_y / b_side][ref_x / b_side - 1] != 1 && 
				board[ref_y / b_side][ref_x / b_side + 1] != 1)begin
					ref_y <= ref_y + b_side;
				end
				else begin
					board[ref_y / b_side - 1][ref_x / b_side]         <= 1;
					board[ref_y / b_side - 1][ref_x / b_side - 1]     <= 1;
					board[ref_y / b_side - 1][ref_x / b_side + 1]     <= 1;
					board[ref_y / b_side - 2][ref_x / b_side - 1]     <= 1;

					
					ref_x <= (randNum % 32) * b_side <= 1 * b_side ? 
								2* b_side : (randNum % 32) * b_side >= 29* b_side ?
								28 * b_side: (randNum % 32) * b_side;
					ref_y <= 0;
					shape <= (randNum % 5);
					rotate <= 0;				
				end
			end
			else if(rotate == 3)begin
				if(ref_y + 2 * b_side < vga_h && 
				  board[ref_y / b_side + 2][ref_x / b_side]  != 1 &&
				  board[ref_y / b_side ][ref_x / b_side + 1] != 1)begin
						ref_y <= ref_y + b_side;
				end
				else begin
					board[ref_y / b_side][ref_x / b_side]         <= 1;
					board[ref_y / b_side + 1][ref_x / b_side]     <= 1;
					board[ref_y / b_side - 1][ref_x / b_side]     <= 1;
					board[ref_y / b_side - 1][ref_x / b_side + 1] <= 1;

					
					ref_x <= (randNum % 32) * b_side <= 1 * b_side ? 
								2* b_side : (randNum % 32) * b_side >= 29* b_side ?
								28 * b_side: (randNum % 32) * b_side;
					ref_y <= 0;
					shape <= (randNum % 5);
					rotate <= 0;				
				end
			end
			

		end
		
		
		
		//to move right using ps2 board
		if(!right || key_to_right == 1)begin
			key_to_right = 0;
		
			if(shape == 0)begin
				if(ref_x + b_side < vga_w && 
					board[ref_y / b_side    ][ref_x / b_side + 1] != 1 && 
					board[ref_y / b_side - 1][ref_x / b_side + 1] != 1)begin
					ref_x <= ref_x + b_side;
				end	
			end
//////////////////////shape 1 right////////////////////////////////////////////////////////////////////		
			else if(shape == 1)begin
				if(rotate == 0)begin
					if(ref_x + 2 * b_side < vga_w && 
						board[ref_y / b_side - 1][ref_x / b_side + 1] != 1 && 
						board[ref_y / b_side    ][ref_x / b_side + 2] != 1)begin
						ref_x <= ref_x + b_side;
					end				
				end
				else if(rotate == 1)begin
					if(ref_x  + b_side < vga_w && 
					   board[ref_y / b_side + 1][ref_x / b_side    ] != 1 &&
						board[ref_y / b_side - 1][ref_x / b_side    ] != 1 && 
						board[ref_y / b_side    ][ref_x / b_side + 1] != 1)begin
							ref_x <= ref_x + b_side;
					end
				end
				else if(rotate == 2)begin
					if(ref_x + 1 * b_side < vga_w &&
					   board[ref_y / b_side    ][ref_x / b_side    ] != 1  &&
						board[ref_y / b_side - 1][ref_x / b_side + 1] != 1)begin
							ref_x <= ref_x + b_side;
						end
				end
				else if(rotate == 3)begin
					if(ref_x + 1 * b_side < vga_w &&
					   board[ref_y / b_side - 2][ref_x / b_side + 1] != 1 &&
						board[ref_y / b_side - 1][ref_x / b_side + 1] != 1 &&
						board[ref_y / b_side    ][ref_x / b_side + 1] != 1)begin
							ref_x <= ref_x + b_side;
						end
				end
			end
//////////////////////shape 2 right////////////////////////////////////////////////////////////////////		
			else if(shape == 2)begin
				if(rotate == 0)begin
					if(ref_x + 3 * b_side < vga_w &&
						board[ref_y / b_side][ref_x / b_side + 3] != 1)begin
						ref_x <= ref_x + b_side;
					end
				end
				else if(rotate == 1)begin
					if(ref_x < vga_w &&
					   board[ref_y / b_side - 1][ref_x / b_side    ] != 1 &&
						board[ref_y / b_side    ][ref_x / b_side    ] != 1 &&
						board[ref_y / b_side + 1][ref_x / b_side    ] != 1 &&
						board[ref_y / b_side + 2][ref_x / b_side    ] != 1)begin
							ref_x <= ref_x + b_side;
						end
				end
				else if(rotate == 2)begin
					if(ref_x + 1 * b_side < vga_w &&
					   board[ref_y / b_side - 1][ref_x / b_side + 1] != 1)begin
							ref_x <= ref_x + b_side;
						end
				end
				else if(rotate == 3)begin
					if(ref_x + 1 * b_side < vga_w &&
					   board[ref_y / b_side - 3][ref_x / b_side + 1] != 1 &&
				      board[ref_y / b_side - 2][ref_x / b_side + 1] != 1 &&
					   board[ref_y / b_side - 1][ref_x / b_side + 1] != 1 && 
					   board[ref_y / b_side    ][ref_x / b_side + 1] != 1)begin
							ref_x <= ref_x + b_side;
					end	
				end
			
			end
//////////////////////shape 3 right////////////////////////////////////////////////////////////////////		
			else if(shape == 3)begin
				if(rotate == 0)begin
					if(ref_x + 2 * b_side < vga_w &&
						board[ref_y / b_side + 1][ref_x / b_side] != 1 && 
						board[ref_y / b_side][ref_x / b_side + 2] != 1)begin
						ref_x <= ref_x + b_side;
					end				
				end
				else if(rotate == 1)begin
					if(ref_x  < vga_w &&
					   board[ref_y / b_side - 1][ref_x / b_side    ] != 1 &&
					   board[ref_y / b_side + 1][ref_x / b_side    ] != 1 &&
					   board[ref_y / b_side    ][ref_x / b_side    ] != 1)begin
							ref_x <= ref_x + b_side;
						end
				end
				else if(rotate == 2)begin
					if(ref_x + 1 * b_side < vga_w &&
					   board[ref_y / b_side - 1][ref_x / b_side + 1] != 1 &&
				      board[ref_y / b_side - 2][ref_x / b_side + 1] != 1)begin
							ref_x <= ref_x + b_side;
					end	
				end
				else if(rotate == 3)begin
					if(ref_x + 2 * b_side < vga_w &&
					   board[ref_y / b_side    ][ref_x / b_side + 2] != 1 &&
					   board[ref_y / b_side - 1][ref_x / b_side + 1] != 1 &&
						board[ref_y / b_side - 2][ref_x / b_side + 1] != 1)begin
							ref_x <= ref_x + b_side;
						end
				end
				
			end
			
//////////////////////shape 4 right////////////////////////////////////////////////////////////////////		
			else if(shape == 4)begin
				if(rotate == 0)begin
					if(ref_x + b_side < vga_w &&
						board[ref_y / b_side][ref_x / b_side + 1] != 1 && 
						board[ref_y / b_side + 1][ref_x / b_side + 1] != 1)begin
						ref_x <= ref_x + b_side;
					end				
				end
				else if(rotate == 1)begin
					if(ref_x  < vga_w &&
					   board[ref_y / b_side    ][ref_x / b_side] != 1 && 
					   board[ref_y / b_side - 1][ref_x / b_side] != 1 &&
						board[ref_y / b_side - 2][ref_x / b_side] != 1)begin
							ref_x <= ref_x + b_side;
						end
				end
				else if(rotate == 2)begin
					if(ref_x + 2 * b_side < vga_w &&
					   board[ref_y / b_side - 1][ref_x / b_side + 2] != 1 && 
						board[ref_y / b_side - 2][ref_x / b_side]     != 1)begin
							ref_x <= ref_x + b_side;
					end
				end
				else if(rotate == 3)begin
					if(ref_x + 2 * b_side < vga_w &&
					   board[ref_y / b_side][ref_x / b_side + 1]     != 1 && 
					   board[ref_y / b_side - 1][ref_x / b_side + 2] != 1 && 
						board[ref_y / b_side + 1][ref_x / b_side + 1] != 1)begin
							ref_x <= ref_x + b_side;
					end
				end
			
			end
		end
		
		//to move left using ps2 board,
		//todo: bug to fix
		if(!left || key_to_left == 1)begin
			key_to_left = 0;
			
			if(shape == 0)begin
				if(ref_x  >= 2 * b_side && 
					board[ref_y / b_side - 1][ref_x / b_side - 2] != 1 && 
					board[ref_y / b_side][ref_x / b_side - 2] != 1)begin
					ref_x <= ref_x - b_side;
				end			
			end
	//////////////////////shape 1 left////////////////////////////////////////////////////////////////////		
			if(shape == 1)begin
				if(rotate == 0)begin
					if(ref_x  >= 2 * b_side && 
						board[ref_y / b_side][ref_x / b_side - 2] != 1 && 
						board[ref_y / b_side - 1][ref_x / b_side - 1] != 1)begin
						ref_x <= ref_x - b_side;				
					end
				end
				else if(rotate == 1)begin
					if(ref_x  >= 2 * b_side && 
					   board[ref_y / b_side - 1][ref_x / b_side - 2] != 1 && 
						board[ref_y / b_side    ][ref_x / b_side - 2] != 1 && 
						board[ref_y / b_side + 1][ref_x / b_side - 2] != 1)begin
							ref_x <= ref_x - b_side;
						end
				end
				else if(rotate == 2)begin
					if(ref_x >= 3 * b_side && 
					   board[ref_y / b_side - 1][ref_x / b_side - 3] != 1 && 
						board[ref_y / b_side    ][ref_x / b_side - 2] != 1)begin
							ref_x <= ref_x - b_side;
					end
				end
				else if(rotate == 3)begin
					if(ref_x >=  2 * b_side &&
					   board[ref_y / b_side - 2][ref_x / b_side - 1] != 1 &&
					   board[ref_y / b_side - 1][ref_x / b_side - 2] != 1 && 
					   board[ref_y / b_side    ][ref_x / b_side - 1] != 1)begin
							ref_x <= ref_x - b_side;
						end
				end

			
			end
	//////////////////////shape 2 left////////////////////////////////////////////////////////////////////	
			if(shape == 2)begin
				if(rotate == 0)begin
					if(ref_x  >= 2 * b_side && 
						board[ref_y / b_side][ref_x / b_side - 2] != 1)begin
							ref_x <= ref_x - b_side;
					end					
				end
				else if(rotate == 1)begin
					if(ref_x  >= 2 * b_side && 
					   board[ref_y / b_side + 1][ref_x / b_side - 2] != 1 && 
					   board[ref_y / b_side    ][ref_x / b_side - 2] != 1 &&
						board[ref_y / b_side - 1][ref_x / b_side - 2] != 1 &&
						board[ref_y / b_side + 2][ref_x / b_side - 2] != 1)begin
							ref_x <= ref_x - b_side;
						end
				end
				else if(rotate == 2)begin
					if(ref_x  >= 4 * b_side && 
					   board[ref_y / b_side - 1][ref_x / b_side - 4] != 1)begin
						ref_x <= ref_x - b_side;
					end
				end
				else if(rotate == 3)begin
					if(ref_x  >=  b_side   && 
					   board[ref_y / b_side - 3][ref_x / b_side - 1] != 1 &&
				      board[ref_y / b_side - 2][ref_x / b_side - 1] != 1 &&
					   board[ref_y / b_side - 1][ref_x / b_side - 1] != 1 &&
					   board[ref_y / b_side    ][ref_x / b_side - 1] != 1	)begin
						ref_x <= ref_x - b_side;
					end
				end
		
			end
	//////////////////////shape 3 left////////////////////////////////////////////////////////////////////	
			if(shape == 3)begin
				if(rotate == 0)begin
					if(ref_x  >= 2 * b_side && 
						board[ref_y / b_side    ][ref_x / b_side - 2] != 1 && 
						board[ref_y / b_side + 1][ref_x / b_side - 2] != 1)begin
						ref_x <= ref_x - b_side;
					end				
				end
				else if(rotate == 1)begin
					if(ref_x  >= 3 * b_side && 
					   board[ref_y / b_side - 1][ref_x / b_side - 3] != 1 &&
					   board[ref_y / b_side    ][ref_x / b_side - 2] != 1 &&
						board[ref_y / b_side + 1][ref_x / b_side - 2] != 1)begin
							ref_x <= ref_x - b_side;
						end
				end
				else if(rotate == 2)begin
					if(ref_x  >= 3 * b_side && 
					   board[ref_y / b_side - 2][ref_x / b_side - 1] != 1 &&
					   board[ref_y / b_side - 1][ref_x / b_side - 3] != 1)begin
							ref_x <= ref_x - b_side;						
					end
				end
				else if(rotate == 3)begin
					if(ref_x  >= b_side && 
					   board[ref_y / b_side - 2][ref_x / b_side - 1] != 1 && 
					   board[ref_y / b_side - 1][ref_x / b_side - 1] != 1 && 
						board[ref_y / b_side    ][ref_x / b_side - 1] != 1)begin
							ref_x <= ref_x - b_side;
					end
				end
			
			end
	//////////////////////shape 4 left////////////////////////////////////////////////////////////////////	
			if(shape == 4)begin
				if(rotate == 0)begin
					if(ref_x  >= 3 * b_side && 
						board[ref_y / b_side + 1][ref_x / b_side - 1] != 1 && 
						board[ref_y / b_side    ][ref_x / b_side - 3] != 1)begin
						ref_x <= ref_x - b_side;
					end				
				end
				else if(rotate == 1)begin
					if(ref_x  >= 3 * b_side && 
					   board[ref_y / b_side    ][ref_x / b_side - 3] != 1 &&
					   board[ref_y / b_side - 1][ref_x / b_side - 2] != 1 &&
						board[ref_y / b_side - 2][ref_x / b_side - 2] != 1 )begin
							ref_x <= ref_x - b_side;							
						end
				end	
				else if(rotate == 2)begin
					if(ref_x  >= 2 * b_side && 
					   board[ref_y / b_side - 1][ref_x / b_side - 2] != 1 &&
						board[ref_y / b_side - 2][ref_x / b_side - 2] != 1 )begin
							ref_x <= ref_x - b_side;								
						end				
				end
				else if(rotate == 3)begin
					if(ref_x  >= b_side && 
					   board[ref_y / b_side - 1][ref_x / b_side - 1] != 1 &&
					   board[ref_y / b_side    ][ref_x / b_side - 1] != 1 &&
						board[ref_y / b_side + 1][ref_x / b_side - 1] != 1 )begin
							ref_x <= ref_x - b_side;							
						end				
				end
			
			end
		end	
		
//////////////////////////////////////////rotate///////////////////////////////////////////
		if(!up || key_to_rotate == 1)begin
			key_to_rotate = 0;
			
			if(shape == 1)begin
				if(rotate == 0)begin
					if(					
					board[ref_y / b_side    ][ref_x / b_side]     != 1 &&
					board[ref_y / b_side    ][ref_x / b_side - 1] != 1 &&	
					board[ref_y / b_side + 1][ref_x / b_side - 1] != 1 &&	
					board[ref_y / b_side - 1][ref_x / b_side - 1] != 1 &&
					ref_y + 2 * b_side < vga_h &&
					ref_x > 1 * b_side/*for security concern*/
					)begin
						rotate <= (rotate + 1) % 4;
					end
				end
				else if(rotate == 1)begin
					if(
					board[ref_y / b_side - 1][ref_x / b_side - 2]  != 1 &&
					board[ref_y / b_side - 1][ref_x / b_side - 1]  != 1 &&
					board[ref_y / b_side - 1][ref_x / b_side]      != 1 &&	
					board[ref_y / b_side    ][ref_x / b_side - 1]  != 1 &&
					ref_x - 2 * b_side > 0 &&
					ref_x > 1 * b_side/*for security concern*/)begin
						rotate <= (rotate + 1) % 4;
					end
				end
				else if(rotate == 2)begin
					if(					
					board[ref_y / b_side][ref_x / b_side]         != 1 &&
					board[ref_y / b_side - 1][ref_x / b_side]     != 1 &&	
					board[ref_y / b_side - 2][ref_x / b_side]     != 1 &&	
					board[ref_y / b_side - 1][ref_x / b_side - 1] != 1 &&
					ref_x > 1 * b_side/*for security concern*/)begin
						rotate <= (rotate + 1) % 4;
					end
				end
				else if(rotate == 3)begin
					if(					
					board[ref_y / b_side    ][ref_x / b_side    ] != 1 &&
					board[ref_y / b_side - 1][ref_x / b_side    ] != 1 &&	
					board[ref_y / b_side    ][ref_x / b_side - 1] != 1 &&	
					board[ref_y / b_side    ][ref_x / b_side + 1] != 1 &&
					ref_x + 2 * b_side < vga_w &&
					ref_x > 1 * b_side/*for security concern*/)begin
						rotate <= (rotate + 1) % 4;
					end
				end
			end
			else if(shape == 2)begin
				if(rotate == 0)begin
					if(					
					board[ref_y / b_side    ][ref_x / b_side - 1] != 1 &&
					board[ref_y / b_side + 2][ref_x / b_side - 1] != 1 &&
					board[ref_y / b_side + 1][ref_x / b_side - 1] != 1 &&
					board[ref_y / b_side - 1][ref_x / b_side - 1] != 1 && 
					ref_y + 3 * b_side < vga_h &&
					ref_x > 1 * b_side/*for security concern*/)begin
						rotate <= (rotate + 1) % 4;
					end
				end
				else if(rotate == 1)begin
					if(
					board[ref_y / b_side - 1][ref_x / b_side]     != 1 &&
					board[ref_y / b_side - 1][ref_x / b_side - 1] != 1 &&
					board[ref_y / b_side - 1][ref_x / b_side - 2] != 1 &&
					board[ref_y / b_side - 1][ref_x / b_side - 3] != 1 &&
					ref_x + b_side < vga_w && ref_x - 3 * b_side  > 0 &&
					ref_x > 1 * b_side/*for security concern*/)begin
						rotate <= (rotate + 1) % 4;				
					end
				end
				else if(rotate == 2)begin
					if(
					board[ref_y / b_side    ][ref_x / b_side] != 1 &&
					board[ref_y / b_side - 1][ref_x / b_side] != 1 &&
					board[ref_y / b_side - 2][ref_x / b_side] != 1 &&
					board[ref_y / b_side - 3][ref_x / b_side] != 1 &&
					ref_y - 3 * b_side > 0 && ref_y + b_side < vga_h &&
					ref_x > 1 * b_side/*for security concern*/)begin
						rotate <= (rotate + 1) % 4;					
					end
				end
				else if(rotate == 3)begin
					if(					
					board[ref_y / b_side][ref_x / b_side]         != 1 &&		
					board[ref_y / b_side][ref_x / b_side - 1]     != 1 &&	
					board[ref_y / b_side][ref_x / b_side + 1]     != 1 &&	
					board[ref_y / b_side][ref_x / b_side + 2]     != 1 && 
					ref_x + 3 * b_side < vga_w && ref_x - b_side > 0 &&
					ref_x > 1 * b_side/*for security concern*/)begin
						rotate <= (rotate + 1) % 4;					
					end
				end			
			end
			else if(shape == 3)begin
				if(rotate == 0)begin
					if(						
					   board[ref_y / b_side][ref_x / b_side - 1]     != 1 &&
						board[ref_y / b_side - 1][ref_x / b_side - 1] != 1 &&
						board[ref_y / b_side - 1][ref_x / b_side - 2] != 1 &&
						board[ref_y / b_side + 1][ref_x / b_side - 1] != 1 &&
						ref_x - 2 * b_side > 0 &&
						ref_x > 1 * b_side/*for security concern*/)begin
							rotate <= (rotate + 1) % 4;
					end
				end
				else if(rotate == 1)begin
					if(					
					board[ref_y / b_side - 1][ref_x / b_side]     != 1 &&
					board[ref_y / b_side - 1][ref_x / b_side - 1] != 1 &&
					board[ref_y / b_side - 1][ref_x / b_side - 2] != 1 &&
					board[ref_y / b_side - 2][ref_x / b_side]     != 1 && 
					ref_x + b_side < vga_w &&
					ref_x > 1 * b_side/*for security concern*/)begin
							rotate <= (rotate + 1) % 4;					
					end
				end
				else if(rotate == 2)begin
						if(					
						board[ref_y / b_side    ][ref_x / b_side]     != 1 &&
						board[ref_y / b_side    ][ref_x / b_side + 1] != 1 &&
						board[ref_y / b_side - 1][ref_x / b_side]     != 1 &&
						board[ref_y / b_side - 2][ref_x / b_side]     != 1 &&
						ref_x + 2 * b_side < vga_w && ref_y + b_side < vga_h &&
						ref_x > 1 * b_side/*for security concern*/)begin
							rotate <= (rotate + 1) % 4;							
						end
				end
				else if(rotate == 3)begin
						if(board[ref_y / b_side][ref_x / b_side]         != 1 &&
							board[ref_y / b_side][ref_x / b_side + 1]     != 1 &&
							board[ref_y / b_side][ref_x / b_side - 1]     != 1 &&
							board[ref_y / b_side + 1][ref_x / b_side - 1] != 1 && 
							ref_x - b_side >  0                                && 
							ref_y + b_side < vga_h                             &&
							ref_x > 1 * b_side/*for security concern*/)begin
								rotate <= (rotate + 1) % 4;						
						end
				end			
			end
			else if(shape == 4)begin
				if(rotate == 0)begin
					if(					
					board[ref_y / b_side][ref_x / b_side - 1]         != 1 &&
					board[ref_y / b_side][ref_x / b_side - 2]         != 1 &&
					board[ref_y / b_side - 1][ref_x / b_side - 1]     != 1 &&
					board[ref_y / b_side - 2][ref_x / b_side - 1]     != 1 && 
					ref_y - 2 * b_side > 0 &&
					ref_x > 1 * b_side/*for security concern*/)begin
								rotate <= (rotate + 1) % 4;							
					end
				end
				else if(rotate == 1)begin
					if(					
					board[ref_y / b_side - 1][ref_x / b_side]         != 1 &&
					board[ref_y / b_side - 1][ref_x / b_side - 1]     != 1 &&
					board[ref_y / b_side - 1][ref_x / b_side + 1]     != 1 &&
					board[ref_y / b_side - 2][ref_x / b_side - 1]     != 1 && 
					ref_x + 2 * b_side < vga_w &&
					ref_x > 1 * b_side/*for security concern*/)begin
								rotate <= (rotate + 1) % 4;				
					end
				end
				else if(rotate == 2)begin
					if(					
					board[ref_y / b_side][ref_x / b_side]         != 1 &&
					board[ref_y / b_side + 1][ref_x / b_side]     != 1 &&
					board[ref_y / b_side - 1][ref_x / b_side]     != 1 &&
					board[ref_y / b_side - 1][ref_x / b_side + 1] != 1 && 
					ref_y + 2 * b_side < vga_h &&
					ref_x > 1 * b_side/*for security concern*/)begin
								rotate <= (rotate + 1) % 4;			
					end
				end
				else if(rotate == 3)begin
					if(					
					board[ref_y / b_side][ref_x / b_side]         != 1 &&
					board[ref_y / b_side + 1][ref_x / b_side]     != 1 &&
					board[ref_y / b_side][ref_x / b_side - 1]     != 1 &&
					board[ref_y / b_side][ref_x / b_side - 2]     != 1 &&
					ref_x - 2 * b_side > 0 &&
					ref_x > 1 * b_side/*for security concern*/)begin
							rotate <= (rotate + 1) % 4;	
					end
				end			
			end

		end
		
				
		
		count <= 0;
		
		
	end
end 






/*
		this block focus on displaying different shapes
		the trick is to calculate the ADDR, if it is in the 
		place where it should display, then it will change the index to be 
		different from the background
		
		
*/
always @(negedge(VGA_CLK_n))
begin

		change <= 0;
		//show current shape
		//4 squares 
		if(shape == 0)begin
			if(ADDR / vga_w >= ref_y - b_side && ADDR / vga_w <= ref_y + b_side &&
				ADDR % vga_w >= ref_x - b_side && ADDR % vga_w <  ref_x + b_side)
				change <= 1;
		end
		else if(shape == 1)begin
			if(rotate == 0)begin
				if((ADDR / vga_w >= ref_y - b_side && ADDR / vga_w <= ref_y + b_side &&
					ADDR %  vga_w >= ref_x          && ADDR % vga_w < ref_x + b_side) || 
					(ADDR / vga_w >= ref_y          && ADDR / vga_w <= ref_y + b_side && 
					ADDR %  vga_w >= ref_x - b_side && ADDR % vga_w <= ref_x + 2 * b_side))
					change <= 1;			
			end
			else if(rotate == 1)begin
				if((ADDR / vga_w >= ref_y          && ADDR / vga_w <= ref_y + b_side    && 
				   ADDR % vga_w >= ref_x           && ADDR % vga_w < ref_x + b_side)    || (
					ADDR / vga_w >= ref_y - b_side  && ADDR / vga_w < ref_y + 2 * b_side &&
					ADDR % vga_w >= ref_x - b_side  && ADDR % vga_w < ref_x ))
						change <= 1;
			end
			else if(rotate == 2)begin
				if((ADDR / vga_w >= ref_y              && ADDR / vga_w <ref_y + b_side &&
				    ADDR % vga_w >= ref_x - b_side     && ADDR % vga_w < ref_x)        || 
					 (ADDR / vga_w >= ref_y - b_side    && ADDR / vga_w <ref_y          &&
					 ADDR % vga_w >= ref_x - 2 * b_side && ADDR % vga_w < ref_x + b_side))
					 change <= 1;
			
			end
			else if(rotate == 3)begin
				if((ADDR / vga_w >= ref_y - b_side     && ADDR / vga_w < ref_y &&
					 ADDR % vga_w >= ref_x - b_side     && ADDR % vga_w < ref_x)   || (
					 ADDR / vga_w >= ref_y - 2 * b_side && ADDR / vga_w < ref_y + b_side && 
					 ADDR % vga_w >= ref_x              && ADDR % vga_w < ref_x + b_side))
					change <= 1; 
			end
			
		end
		else if(shape == 2)begin
			if(rotate == 0)begin
				if(ADDR / vga_w >= ref_y          && ADDR / vga_w < ref_y + b_side      &&
					ADDR % vga_w >= ref_x - b_side && ADDR % vga_w <= ref_x + 3 * b_side)
					change <= 1;			
			end
			if(rotate == 1)begin
				if( ADDR / vga_w >= ref_y - b_side  && ADDR / vga_w < ref_y + 3 * b_side && 
					 ADDR % vga_w >= ref_x - b_side &&  ADDR % vga_w < ref_x)
					 change <= 1;
					
			end
			if(rotate == 2)begin
				if(ADDR / vga_w >= ref_y - b_side     && ADDR / vga_w < ref_y            && 
				   ADDR % vga_w >= ref_x - 3 * b_side && ADDR % vga_w < ref_x + b_side)
					change <= 1;
			end
			if(rotate == 3)begin
				if(ADDR / vga_w >= ref_y - 3 * b_side && ADDR / vga_w < ref_y + b_side  && 
					ADDR % vga_w >= ref_x              && ADDR % vga_w < ref_x + b_side)
					change <= 1;
			end			

		end
		else if(shape == 3)begin
			if(rotate == 0)begin
				if((ADDR / vga_w >= ref_y          && ADDR / vga_w < ref_y + b_side      &&
					ADDR  % vga_w >= ref_x          && ADDR % vga_w < ref_x + 2 * b_side) || 
					(ADDR / vga_w >= ref_y          && ADDR / vga_w <ref_y + 2 * b_side   && 
					ADDR  % vga_w >= ref_x - b_side && ADDR % vga_w < ref_x))
					change <= 1;			
			end
			else if(rotate == 1)begin
				if((ADDR / vga_w >= ref_y - b_side    && ADDR / vga_w < ref_y              &&
				   ADDR % vga_w >= ref_x - 2 * b_side && ADDR % vga_w < ref_x)             || 
					(ADDR / vga_w >= ref_y 				  && ADDR / vga_w < ref_y + 2 * b_side &&
					ADDR % vga_w >= ref_x - b_side     && ADDR % vga_w < ref_x ))
					change <= 1;
			end
			else if(rotate == 2)begin
				if((ADDR / vga_w >= ref_y - b_side      && ADDR / vga_w < ref_y   &&  
				    ADDR % vga_w >= ref_x - 2 * b_side  && ADDR % vga_w < ref_x)  || 
					(ADDR / vga_w >= ref_y - 2 * b_side  && ADDR / vga_w < ref_y   && 
					 ADDR % vga_w >= ref_x               && ADDR % vga_w < ref_x + b_side))
					 change <= 1;
			end
			else if(rotate == 3)begin
				if((ADDR / vga_w >= ref_y               && ADDR / vga_w < ref_y + b_side      && 
					 ADDR % vga_w >= ref_x 					 && ADDR % vga_w < ref_x + 2 * b_side) ||
					(ADDR / vga_w >= ref_y - 2 * b_side  && ADDR / vga_w < ref_y               && 
					 ADDR % vga_w >= ref_x 					 && ADDR % vga_w < ref_x + b_side))
					 change <= 1;
			end

		end
		else if(shape == 4)begin
			if(rotate == 0)begin
				if((ADDR / vga_w >= ref_y              && ADDR / vga_w < ref_y + 2 * b_side &&
					ADDR  % vga_w >= ref_x              && ADDR % vga_w < ref_x + b_side)    || 
					(ADDR / vga_w >= ref_y              && ADDR / vga_w < ref_y + b_side     && 
					ADDR  % vga_w >= ref_x - 2 * b_side && ADDR % vga_w < ref_x))
					change <= 1;			
				end
			else if(rotate == 1)begin
				if((ADDR / vga_w >= ref_y - 2 * b_side  && ADDR / vga_w < ref_y             &&
				    ADDR % vga_w >= ref_x - 1 * b_side  && ADDR % vga_w < ref_x)            ||
					(ADDR / vga_w >= ref_y               && ADDR / vga_w < ref_y + b_side    &&
					 ADDR % vga_w >= ref_x - 2 * b_side  && ADDR % vga_w < ref_x ))
					 change <= 1;
			end
			else if(rotate == 2)begin
				if((ADDR / vga_w >= ref_y - 2 * b_side && ADDR / vga_w < ref_y              &&
				    ADDR % vga_w >= ref_x - b_side     && ADDR % vga_w < ref_x)             || 
					(ADDR / vga_w >= ref_y - b_side     && ADDR / vga_w < ref_y              &&
					 ADDR % vga_w >= ref_x              && ADDR % vga_w < ref_x + 2 * b_side))
					 change <= 1;
			end
			else if(rotate == 3)begin
				if((ADDR / vga_w >= ref_y - 1 * b_side && ADDR / vga_w < ref_y               &&
				    ADDR % vga_w >= ref_x              && ADDR % vga_w < ref_x + 2 * b_side) || 
					(ADDR / vga_w >= ref_y              && ADDR / vga_w < ref_y + 2 * b_side  &&
					 ADDR % vga_w >= ref_x              && ADDR % vga_w < ref_x + 1 * b_side))
					 change <= 1;				
			end

		end
		
		
		//show existing squares
		for(i_show = 0; i_show < 24; i_show = i_show + 1)begin
			for(j_show = 0; j_show < 32; j_show = j_show + 1)begin
				if(board[ADDR / vga_w / b_side][ADDR % vga_w / b_side] == 1)begin
					change <= 1;
				end
			end
		end
		
		//show score part
		if(score == 0)begin
			if((ADDR / vga_w  >= score_y                  && ADDR / vga_w  < score_y +     score_side && ADDR % vga_w  >= score_x                  && ADDR % vga_w < score_x + 3 * score_side) ||
			   (ADDR / vga_w  >= score_y                  && ADDR / vga_w  < score_y + 5 * score_side && ADDR % vga_w  >= score_x                  && ADDR % vga_w < score_x +     score_side) ||
				(ADDR / vga_w  >= score_y                  && ADDR / vga_w  < score_y + 5 * score_side && ADDR % vga_w  >= score_x + 2 * score_side && ADDR % vga_w < score_x + 3 * score_side) ||
				(ADDR / vga_w  >= score_y + 4 * score_side && ADDR / vga_w  < score_y + 5 * score_side && ADDR % vga_w  >= score_x                  && ADDR % vga_w < score_x + 3 * score_side)
				)begin
					change <= 2;
				end
				
		end
		else if(score == 1)begin
			if (ADDR / vga_w  >= score_y                  && ADDR / vga_w  < score_y + 5 * score_side && ADDR % vga_w  >= score_x                  && ADDR % vga_w < score_x + 1 * score_side)begin
					change <= 2;
				end	
		end
		else if(score == 2)begin
			if((ADDR / vga_w  >= score_y                  && ADDR / vga_w  < score_y +     score_side && ADDR % vga_w  >= score_x                  && ADDR % vga_w < score_x + 3 * score_side) ||
			   (ADDR / vga_w  >= score_y                  && ADDR / vga_w  < score_y + 3 * score_side && ADDR % vga_w  >= score_x + 2 * score_side && ADDR % vga_w < score_x + 3 * score_side) ||
				(ADDR / vga_w  >= score_y + 2 * score_side && ADDR / vga_w  < score_y + 3 * score_side && ADDR % vga_w  >= score_x + 0 * score_side && ADDR % vga_w < score_x + 3 * score_side) ||
				(ADDR / vga_w  >= score_y + 2 * score_side && ADDR / vga_w  < score_y + 5 * score_side && ADDR % vga_w  >= score_x                  && ADDR % vga_w < score_x + 1 * score_side) ||
				(ADDR / vga_w  >= score_y + 4 * score_side && ADDR / vga_w  < score_y + 5 * score_side && ADDR % vga_w  >= score_x                  && ADDR % vga_w < score_x + 3 * score_side) 		
				)begin
					change <= 2;
				end		
		end
		else if(score == 3)begin
			if((ADDR / vga_w >= score_y                  && ADDR / vga_w  < score_y +     score_side && ADDR % vga_w  >= score_x + 0 * score_side && ADDR % vga_w < score_x + 3 * score_side) ||
			   (ADDR / vga_w >= score_y                  && ADDR / vga_w  < score_y + 5 * score_side && ADDR % vga_w  >= score_x + 2 * score_side && ADDR % vga_w < score_x + 3 * score_side) ||
				(ADDR / vga_w >= score_y + 2 * score_side && ADDR / vga_w  < score_y + 3 * score_side && ADDR % vga_w  >= score_x + 0 * score_side && ADDR % vga_w < score_x + 3 * score_side) ||
				(ADDR / vga_w >= score_y + 4 * score_side && ADDR / vga_w  < score_y + 5 * score_side && ADDR % vga_w  >= score_x                  && ADDR % vga_w < score_x + 3 * score_side)
				)begin
					change <= 2;
				end	
		end
		else if(score == 4)begin
			if((ADDR / vga_w  >= score_y                  && ADDR / vga_w  < score_y + 2 * score_side && ADDR % vga_w  >= score_x                  && ADDR % vga_w < score_x + 1 * score_side) ||
			   (ADDR / vga_w  >= score_y + 1 * score_side && ADDR / vga_w  < score_y + 2 * score_side && ADDR % vga_w  >= score_x                  && ADDR % vga_w < score_x + 3 * score_side) ||
				(ADDR / vga_w  >= score_y                  && ADDR / vga_w  < score_y + 5 * score_side && ADDR % vga_w  >= score_x + 2 * score_side && ADDR % vga_w < score_x + 3 * score_side) 
			  )begin
					change <= 2;
				end		
		end
		
		///////change color//////////////////////////////////////////////////////////////////////////////////
		index_changed <= (change == 1 ? 8'h03 : change == 2 ? 8'h04 : index);
	
end

	
////////////Addresss generator////////////////////////////////////////////////////
////////////helper function provided by professors no need to modify that/////////
always@(posedge iVGA_CLK,negedge iRST_n)
begin
  if (!iRST_n)
     ADDR<=19'd0;
  else if (cHS==1'b0 && cVS==1'b0)
     ADDR<=19'd0;
  else if (cBLANK_n==1'b1)
     ADDR<=ADDR+1;
end
//////////////////////////
//////INDEX addr.
assign VGA_CLK_n = ~iVGA_CLK;
img_data	img_data_inst (
	.address ( ADDR ),
	.clock ( VGA_CLK_n ),
	.q ( index )
	);
	
	
	
	
	
//////Color table output//////////////////////////////////////////////////////////////
img_index	img_index_inst (
	.address ( index_changed ),
	.clock ( iVGA_CLK ),
	.q ( bgr_data_raw)
	);	
	

//////
//////latch valid data at falling edge;
always@(posedge VGA_CLK_n) bgr_data <= bgr_data_raw;
assign b_data = bgr_data[23:16];
assign g_data = bgr_data[15:8];
assign r_data = bgr_data[7:0]; 
///////////////////
//////Delay the iHD, iVD,iDEN for one clock cycle;
always@(negedge iVGA_CLK)
begin
  oHS<=cHS;
  oVS<=cVS;
  oBLANK_n<=cBLANK_n;
end


////
assign rst = ~iRST_n;
video_sync_generator LTM_ins (.vga_clk(iVGA_CLK),
                              .reset(rst),
                              .blank_n(cBLANK_n),
                              .HS(cHS),
                              .VS(cVS));
////

endmodule