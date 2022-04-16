module PS2_Interface(inclock, resetn, ps2_clock, ps2_data, ps2_key_data, ps2_key_pressed, last_data_received);

	input 			inclock, resetn;
	inout 			ps2_clock, ps2_data;
	output 			ps2_key_pressed;
	output 	[7:0] 	ps2_key_data;
	output 	[7:0] 	last_data_received;

	// Internal Registers
	reg			[7:0]	last_data_received;	
	reg         [30:0] count;
	initial begin
		count = 0;
	end
	
	always @(posedge inclock)
	begin

//		if(ps2_key_data == 8'hE075)			//UP ARROW  == rotate
//			last_data_received <= 8'h26;
//		else if(ps2_key_data == 8'hE06B)		//LEFT ARROW
//			last_data_received <= 8'h25;
//		else if(ps2_key_data == 8'hE072)		//DOWN ARROW	== no use	
//			last_data_received <= 8'h28;
//		else if(ps2_key_data == 8'hE074)		//RIGHT ARROW
//			last_data_received <= 8'h27;
//			
//	
//	
		if (resetn == 1'b0)
			last_data_received <= 8'h00;
		else if (ps2_key_pressed == 1'b1)
			last_data_received <= ps2_key_data;
	end
	
	PS2_Controller PS2 (.CLOCK_50 			(inclock),
						.reset 				(~resetn),
						.PS2_CLK			(ps2_clock),
						.PS2_DAT			(ps2_data),		
						.received_data		(ps2_key_data),
						.received_data_en	(ps2_key_pressed)
						);

endmodule
